extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no zumbi, na navegacao ou
## no layout do bairro.**
##
## Confere as seis coisas que fazem o zumbi servir a core mechanic:
##
##  1. nenhum zumbi nasce dentro de parede;
##  2. a navegacao acha caminho da rua ate dentro de casa, do galpao e do
##     mercadinho - e de um canto do mapa ao outro;
##  3. parede corta a linha de visao, e ele nao ve pelas costas;
##  4. ele persegue, toca, e o toque **interrompe o vasculho**;
##  5. ele **entra na casa** atras de voce;
##  6. quem enxerga chama a horda.
##
## Existe porque essa classe de bug nao aparece lendo o codigo. Na primeira
## rodada achou tres, todos de comportamento e nao de erro em tela:
##
##  - desistencia por tempo fixo (4 s) fazia ele parar no meio do caminho, e
##    entrar em casa virava abrigo garantido;
##  - desistencia por distancia em linha reta era pior: contornando a casa para
##    chegar na porta a linha reta AUMENTA, e ele desistia justamente quando
##    estava fazendo a coisa certa;
##  - no fim do caminho ele devolvia direcao zero e ficava parado ate o proximo
##    recalculo, andando a menos da metade da velocidade dele.
##
## Conta quadro de FISICA, nao de laco: em headless o laco roda muito mais
## rapido que a fisica, e orcamento em quadro de laco nao quer dizer nada.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")

# Os estados do zumbi, na ordem do enum dele.
const VAGANDO := 0
const PERSEGUINDO := 1
const PROCURANDO := 2

var _bairro: Node
var _jogador: Node2D
var _zumbis: Array = []
var _nav: Node

var _fase := 0
var _quadros := 0
var _falhas := 0
## Separado do _quadros, que zera em toda troca de fase: um guard de partida em
## cima do _quadros engolia o primeiro quadro de cada fase, e as fases que
## posicionam no quadro 1 passavam por vazio.
var _partida := 0

## Se o zumbi encostou. **Vem do sinal, e nao da vida**: desde 16/09/2026 o
## jogador nao tem vida, e o toque nao deixa marca nenhuma em variavel - o que
## ele faz e empurrar e emitir `atingido`. Era por "a vida caiu de 100" que esta
## ferramenta sabia que o toque tinha acontecido.
var _foi_tocado := false

## O que a fase 6 viu acontecer ao longo dos 240 quadros, e nao no ultimo deles.
## Ver _conferir_horda().
var _horda_enxergou := false
var _horda_acordados := {}

func _ready() -> void:
	_bairro = CENA_DA_RUA.instantiate()
	add_child(_bairro)
	_jogador = _bairro.get_node("Jogador")
	_nav = _bairro.get_node("Cenario/Navegacao")
	# Desliga o povoamento por proximidade: esta ferramenta teleporta o jogador
	# para montar cada cena, e o cenario liberaria justamente os zumbis que ela
	# esta medindo. Os que nasceram no _ready ficam.
	_bairro.get_node("Cenario").povoa_por_proximidade = false
	for filho in _bairro.get_node("Cenario").get_children():
		if filho.is_in_group("zumbi"):
			_zumbis.append(filho)

func _physics_process(_delta: float) -> void:
	if _partida < 4:
		_partida += 1
		return
	_quadros += 1

	match _fase:
		0: _spawn(); _passar()
		1: _navegacao(); _passar()
		2: _linha_de_visao()
		3: _preparar_perseguicao()
		4: _conferir_perseguicao()
		5: _preparar_dentro_de_casa()
		6: _conferir_dentro_de_casa()
		7: _preparar_horda()
		8: _conferir_horda()
		9:
			print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
			get_tree().quit(0 if _falhas == 0 else 1)

## A construcao de teste do tipo pedido: a mais perto de onde o jogador nasce
## com a frente da porta livre - sem carro, bloco, predio ou arvore a ate
## 340 px do vao, e dentro do mundo (30/09/2026). Ate aqui era "a primeira da
## lista", e no mapa tracado do desenho a primeira casa tinha um carro parado
## na porta e a segunda dava de costas para a borda do mundo: a fase 2 media o
## estacionamento, e a 5 mandava o zumbi para fora do mapa.
##
## Pula a sua casa: ela nao se vasculha e nao tem movel.
func _uma_construcao(tipo: String) -> Dictionary:
	var arvores: Array = _bairro.get_node("Cenario")._arvores
	var achada := Mapa.construcao_com_a_frente_livre(tipo, Mapa.onde_o_jogador_nasce(), 340.0, 0.0, arvores)
	if achada.is_empty():
		_erro("nao ha %s nenhum(a) com a frente da porta livre para o teste" % tipo)
	return achada

## A construcao do tipo pedido mais PERTO de um ponto, e nao so a primeira do
## mapa inteiro (17/09/2026, P12) - use quando o teste depende de dois
## predios estarem na mesma janela de navegacao. Sem isto, "mercadinho" ou
## "galpao" podiam apontar para o outro lado do mapa toda vez que um lugar
## novo passasse a ter um predio daquele tipo antes na lista.
func _uma_construcao_perto(tipo: String, perto: Vector2) -> Dictionary:
	var melhor := {}
	var menor := INF
	for construcao in Mapa.mundo()["construcoes"]:
		if construcao["tipo"] != tipo or construcao.get("sua", false):
			continue
		var d: float = (construcao["rect"] as Rect2).get_center().distance_to(perto)
		if d < menor:
			menor = d
			melhor = construcao
	return melhor

func _passar() -> void:
	_fase += 1
	_quadros = 0

func _ao_ser_tocado() -> void:
	_foi_tocado = true

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Tira do caminho os zumbis que a fase atual nao esta medindo. Vao para o canto
## noroeste do mundo, que sai do mapa e nao de uma coordenada escrita a mao -
## quando o mundo mudou de tamanho, a coordenada antiga virou o meio da mata.
func _longe_do_teste(menos: int) -> void:
	var canto := Mapa.MUNDO.position + Vector2(300.0, 300.0)
	for i in range(menos, _zumbis.size()):
		_zumbis[i].global_position = canto + Vector2(0.0, 60.0 * i)
		_zumbis[i]._estado = VAGANDO

# --- 1. nenhum zumbi nasce dentro de parede ---------------------------------

func _spawn() -> void:
	print("\n1. onde os %d zumbis nascem" % _zumbis.size())
	var espaco := get_viewport().find_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(30.0, 44.0)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	var fora: Array[RID] = [_jogador.get_rid()]
	for z in _zumbis:
		fora.append(z.get_rid())
	consulta.exclude = fora

	var ruins := 0
	for onde in Mapa.mundo()["zumbis"]:
		consulta.transform = Transform2D(0.0, onde)
		if not espaco.intersect_shape(consulta, 1).is_empty():
			_erro("zumbi nasce em cima de colisao, em %s" % onde)
			ruins += 1
	if ruins == 0:
		print("  todos em lugar livre")

# --- 2. a navegacao acha o caminho para dentro das construcoes --------------

func _navegacao() -> void:
	print("\n2. navegacao")
	var casa := _uma_construcao("casa")
	# `normal_de`, e nao Vector2(0, N): antes disto (P2, 17/09/2026) supunha
	# fachada norte/sul; com a porta em 4 direcoes, a casa que `_uma_construcao`
	# achar pode ter fachada leste ou oeste.
	var rua := Construcao.porta_de(casa) + Construcao.normal_de(casa) * 300.0
	# A grade cobre so uma janela em volta do jogador e e remontada quando ele
	# anda. Pedir a janela aqui, em vez de contar com o _process ja ter rodado,
	# e o que faz esta conferencia medir a navegacao e nao o relogio de quadros.
	_nav.remontar_em(rua)
	# `_uma_construcao_perto`, e nao `_uma_construcao` (17/09/2026, P12): o
	# comercio mais perto DESTA rua, e nao so o primeiro do mapa - o bairro
	# tem um so, mas nada garante que continue sendo o primeiro da lista se
	# um lugar novo nascer antes dele.
	var alvos := {
		"sala": Construcao.quartos_de(casa)[0].get_center(),
		"quarto do fundo": Construcao.quartos_de(casa)[1].get_center(),
	}
	for nome in alvos:
		var caminho: PackedVector2Array = _nav.caminho(rua, alvos[nome])
		if caminho.is_empty():
			_erro("sem caminho da rua ate %s" % nome)
			continue
		var erro: float = caminho[-1].distance_to(alvos[nome])
		if erro > 60.0:
			_erro("caminho ate %s para a %.0f px do alvo" % [nome, erro])
			continue
		print("  rua -> %-18s %3d pontos, %.0f px" % [nome, caminho.size(), _tamanho(caminho)])

	# Um comercio, da frente da propria porta ate o salao - o mesmo criterio de
	# frente livre da casa (30/09/2026): o mercadinho mais perto da casa de
	# teste podia ter carro na porta ou estar fora da janela de navegacao.
	var comercio := _uma_construcao("comercio")
	var frente_do_comercio := Construcao.porta_de(comercio) + Construcao.normal_de(comercio) * 300.0
	_nav.remontar_em(frente_do_comercio)
	var alvo_do_comercio := Construcao.quartos_de(comercio)[0].get_center()
	var caminho_do_comercio: PackedVector2Array = _nav.caminho(frente_do_comercio, alvo_do_comercio)
	if caminho_do_comercio.is_empty():
		_erro("sem caminho da frente do comercio ate dentro dele")
	elif caminho_do_comercio[-1].distance_to(alvo_do_comercio) > 60.0:
		_erro("caminho ate o comercio para a %.0f px do alvo" % caminho_do_comercio[-1].distance_to(alvo_do_comercio))
	else:
		print("  frente -> %-17s %3d pontos, %.0f px"
			% ["comercio", caminho_do_comercio.size(), _tamanho(caminho_do_comercio)])
	_nav.remontar_em(rua)

	# O galpao, a partir da frente da PROPRIA porta dele (30/09/2026): o mapa
	# tracado tem galpao na fazenda, no posto e na estrada de terra, e nenhum
	# deles fica perto da casa de cima - testar a partir da mesma `rua` cairia
	# fora da janela de navegacao e "sem caminho" viraria falha permanente.
	var galpao := _uma_construcao("galpao")
	var frente_do_galpao := Construcao.porta_de(galpao) + Construcao.normal_de(galpao) * 300.0
	_nav.remontar_em(frente_do_galpao)
	var alvo_do_galpao := Construcao.quartos_de(galpao)[0].get_center()
	var caminho_do_galpao: PackedVector2Array = _nav.caminho(frente_do_galpao, alvo_do_galpao)
	if caminho_do_galpao.is_empty():
		_erro("sem caminho da frente do galpao ate dentro dele")
	else:
		var erro_do_galpao: float = caminho_do_galpao[-1].distance_to(alvo_do_galpao)
		if erro_do_galpao > 60.0:
			_erro("caminho ate o galpao para a %.0f px do alvo" % erro_do_galpao)
		else:
			print("  frente -> %-17s %3d pontos, %.0f px"
				% ["galpao", caminho_do_galpao.size(), _tamanho(caminho_do_galpao)])
	_nav.remontar_em(rua)

	# Da praca ate a porta de casa: um caminho longo, atravessando o miolo da
	# cidade. O alvo e a **soleira**, e nao a porta: desde 16/09/2026 a porta e
	# um corpo solido, e o zumbi que persegue voce ate em casa para na calcada.
	var soleira := Mapa.onde_o_jogador_nasce()
	var praca := (Mapa.lugar("Praça")["rect"] as Rect2).get_center()
	_nav.remontar_em((praca + soleira) / 2.0)
	var longe: PackedVector2Array = _nav.caminho(praca, soleira)
	if longe.is_empty():
		_erro("sem caminho da praca ate a porta de casa")
	else:
		print("  praca -> casa             %3d pontos, %.0f px" % [longe.size(), _tamanho(longe)])
	# Devolve a janela para onde o jogador esta, senao as fases seguintes medem
	# perseguicao com a grade montada no lugar errado.
	_nav.remontar_em(_jogador.global_position)

func _tamanho(caminho: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, caminho.size()):
		total += caminho[i - 1].distance_to(caminho[i])
	return total

# --- 3. parede corta a linha de visao ---------------------------------------

var _caso_da_visao := 0

## Posiciona num quadro e consulta tres quadros depois: a linha de visao e
## raycast, e a fisica so ve a posicao nova no passo seguinte. O zumbi fica
## congelado, senao ele anda e sobrescreve o _olhando com a propria velocidade.
func _linha_de_visao() -> void:
	if _caso_da_visao == 0 and _quadros == 1:
		print("\n3. linha de visao")

	var casa := _uma_construcao("casa")
	var zumbi = _zumbis[0]
	var porta := Construcao.porta_de(casa)

	if _quadros == 1:
		zumbi.set_physics_process(false)
		zumbi.velocity = Vector2.ZERO
		var para_fora := Construcao.normal_de(casa)
		zumbi.global_position = porta + para_fora * 260.0
		# Olhando para DENTRO da casa (o contrario do normal, que sai por ela) -
		# antes escrito como Vector2.UP porque toda casa de teste era ao sul.
		zumbi._olhando = -para_fora
		match _caso_da_visao:
			0: _jogador.global_position = Construcao.quartos_de(casa)[1].get_center()
			1: _jogador.global_position = porta + para_fora * 90.0
			2:
				_jogador.global_position = porta + para_fora * 90.0
				zumbi._olhando = para_fora
		return
	if _quadros < 4:
		return

	var ve: bool = zumbi._ve_o_jogador()
	match _caso_da_visao:
		0:
			if ve: _erro("ve o jogador atraves de duas paredes")
			else: print("  atras de duas paredes: nao ve")
		1:
			if not ve: _erro("nao ve o jogador na frente da porta, a 90 px e na mira")
			else: print("  na frente da porta: ve")
		2:
			if ve: _erro("ve o jogador estando de costas")
			else: print("  de costas: nao ve")

	_caso_da_visao += 1
	_quadros = 0
	if _caso_da_visao > 2:
		zumbi.set_physics_process(true)
		_passar()

# --- 4. persegue, toca, e o toque interrompe o vasculho ---------------------

var _movel: Area2D
var _distancia_inicial := 0.0
var _progresso_antes := 0.0
var _chegou_a_perseguir := false

func _preparar_perseguicao() -> void:
	print("\n4. perseguicao, toque e interrupcao do vasculho")
	# O carro mais PERTO de onde o jogador nasce, e nao o primeiro da lista: com
	# o mapa grande ha carro abandonado no posto, no patio da delegacia e no
	# estacionamento do mercado, e o primeiro da lista podia estar a 600 m de
	# qualquer zumbi que esta ferramenta tem em mao.
	var perto := INF
	for filho in _bairro.get_node("Cenario").get_children():
		if not (filho is Area2D and filho.rotulo == "Carro abandonado"):
			continue
		var d: float = (filho as Node2D).position.distance_to(_jogador.global_position)
		if d < perto:
			perto = d
			_movel = filho
	_jogador.global_position = _movel.position + Vector2(0.0, _movel.tamanho.y / 2.0 + 34.0)
	_foi_tocado = false
	if not _jogador.atingido.is_connected(_ao_ser_tocado):
		_jogador.atingido.connect(_ao_ser_tocado)
	_longe_do_teste(1)

	var zumbi = _zumbis[0]
	zumbi.global_position = _jogador.global_position + Vector2(0.0, 420.0)
	# Chamado, ele vem. A perseguicao de verdade so comeca se ele ENXERGAR, que
	# e o que se confere adiante - sem o chamado o teste era sorteio, porque o
	# _olhando dele e sobrescrito pela propria velocidade todo quadro.
	zumbi._estado = VAGANDO
	zumbi.foi_chamado(_jogador.global_position)
	_distancia_inicial = zumbi.global_position.distance_to(_jogador.global_position)

	Input.action_press("vasculhar")
	_passar()

func _conferir_perseguicao() -> void:
	var zumbi = _zumbis[0]
	if zumbi._estado == PERSEGUINDO:
		_chegou_a_perseguir = true

	if _quadros == 30:
		_progresso_antes = _movel._progresso
		if _progresso_antes <= 0.0:
			_erro("o vasculho nem comecou")
		else:
			print("  vasculho em andamento: %.2f s" % _progresso_antes)

	if _foi_tocado:
		if _chegou_a_perseguir:
			print("  enxergou e passou a perseguir")
		else:
			_erro("chegou em voce sem nunca enxergar (nao passou por PERSEGUINDO)")
		print("  tocou: aproximou %.0f px em %d quadros de fisica" % [
			_distancia_inicial - zumbi.global_position.distance_to(_jogador.global_position),
			_quadros])
		# Nao tem que ser zero: o jogador continua com o E segurado, entao o
		# vasculho reinicia no quadro seguinte. O que se confere e que voltou
		# para o comeco.
		if _movel._progresso > 0.15:
			_erro("o toque nao interrompeu o vasculho (%.2f -> %.2f)" % [
				_progresso_antes, _movel._progresso])
		else:
			print("  o toque zerou o vasculho (%.2f -> %.2f)" % [
				_progresso_antes, _movel._progresso])
		Input.action_release("vasculhar")
		_o_toque_tira_vida_e_zerar_acaba_o_dia(zumbi)
		_passar()
		return

	if _quadros > 900:
		_erro("nao chegou em 900 quadros (dist %.0f, estado %d)" % [
			zumbi.global_position.distance_to(_jogador.global_position), zumbi._estado])
		Input.action_release("vasculhar")
		_passar()

## A vida (de volta em 30/09/2026): o toque que acabou de acontecer tirou
## DANO, e zerar a vida acaba o dia na forca, com o jogador acordando em casa
## de vida cheia e a mochila ficando na rua.
func _o_toque_tira_vida_e_zerar_acaba_o_dia(zumbi: Node) -> void:
	var esperada: float = _jogador.VIDA_CHEIA - zumbi.DANO
	if not is_equal_approx(_jogador.vida, esperada):
		_erro("um toque deixou a vida em %.0f, esperado %.0f" % [_jogador.vida, esperada])
	else:
		print("  o toque tirou %.0f de vida (%.0f/%.0f)" % [zumbi.DANO, _jogador.vida, _jogador.VIDA_CHEIA])

	# Zerar: a Travessia troca de cena de verdade, entao a ferramenta sai de
	# "cena atual" pelo tempo da chamada e desmonta a casa que nasceu na raiz.
	_jogador.vida = zumbi.DANO
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	_jogador.levar_dano(zumbi.DANO, Vector2.RIGHT)
	get_tree().current_scene = cena_atual
	for filho in get_tree().root.get_children():
		if filho.name == "Casa":
			filho.free()

	if Travessia.fim_do_dia != Travessia.FimDoDia.SEM_VIDA:
		_erro("zerar a vida nao acabou o dia como SEM_VIDA (fim_do_dia = %d)" % Travessia.fim_do_dia)
	elif not is_equal_approx(_jogador.vida, _jogador.VIDA_CHEIA):
		_erro("depois de cair a vida devia voltar cheia, e esta em %.0f" % _jogador.vida)
	else:
		print("  zerar a vida acabou o dia na forca, e a vida voltou cheia")
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA
	Travessia.documentos_perdidos = 0

# --- 5. ele entra na casa atras de voce -------------------------------------

func _preparar_dentro_de_casa() -> void:
	print("\n5. o zumbi entra na casa atras de voce")
	var casa := _uma_construcao("casa")
	_jogador.global_position = Construcao.quartos_de(casa)[1].get_center()
	var zumbi = _zumbis[0]
	zumbi.global_position = Construcao.porta_de(casa) + Construcao.normal_de(casa) * 240.0
	# Zerar antes: foi_chamado() recusa quem ja esta perseguindo, e com razao -
	# quem esta em cima de voce nao troca de alvo por causa de um grito.
	zumbi._estado = VAGANDO
	zumbi.foi_chamado(_jogador.global_position)
	_passar()

func _conferir_dentro_de_casa() -> void:
	var zumbi = _zumbis[0]
	var casa: Rect2 = _uma_construcao("casa")["rect"]
	if casa.has_point(zumbi.global_position):
		print("  entrou pelo vao da porta em %d quadros de fisica, ate %s" % [
			_quadros, zumbi.global_position.round()])
		_passar()
		return
	if _quadros > 1200:
		_erro("nao entrou em 1200 quadros (esta em %s, estado %d, alvo %s)" % [
			zumbi.global_position.round(), zumbi._estado, zumbi._ultima_posicao.round()])
		_passar()

# --- 6. quem enxerga chama a horda ------------------------------------------

func _preparar_horda() -> void:
	print("\n6. chamado da horda")
	# Um que vai enxergar o jogador, e tres vagando dentro do alcance do
	# chamado.
	# No meio da praca (30/09/2026): gramado aberto de 48 x 66 m, sem arvore,
	# sem predio e sem carro - linha de visao limpa para os quatro.
	_jogador.global_position = (Mapa.lugar("Praça")["rect"] as Rect2).get_center()
	_longe_do_teste(4)
	_zumbis[0].global_position = _jogador.global_position + Vector2(0.0, 300.0)
	_zumbis[0]._estado = VAGANDO
	for i in range(1, 4):
		_zumbis[i].global_position = _jogador.global_position + Vector2(160.0 * i, 460.0)
		_zumbis[i]._estado = VAGANDO
	_zumbis[0].foi_chamado(_jogador.global_position)
	_passar()

## **Marca a cada quadro, e so julga no fim.** Ate 16/09/2026 esta conferencia
## lia o estado dos quatro zumbis uma vez so, no quadro 240 - e reprovava em
## cerca de metade das rodadas, dizendo "o primeiro zumbi nao chegou a enxergar
## o jogador".
##
## Ele enxergava, e no **quadro 2**. O que acontecia depois e que ele chegava em
## cima do jogador: a 43 px os dois corpos se empurram, a velocidade dele vira
## para o lado, e o `_olhando` sai da propria velocidade - o jogador sai do cone
## de 110 graus e ele cai para PROCURANDO. No quadro 240 o estado dele era
## legitimamente "procurando", e a pergunta que a ferramenta faz nao e essa:
## e se ele **chegou a** enxergar.
##
## Estado instantaneo nao responde pergunta sobre o que aconteceu. A fase 4 ja
## marcava assim (`_chegou_a_perseguir`); esta nao.
func _conferir_horda() -> void:
	if _zumbis[0]._estado == PERSEGUINDO:
		_horda_enxergou = true
	for i in range(1, 4):
		if _zumbis[i]._estado != VAGANDO:
			_horda_acordados[i] = true

	if _quadros < 240:
		return

	if not _horda_enxergou:
		_erro("o primeiro zumbi nao chegou a enxergar o jogador")
	elif _horda_acordados.is_empty():
		_erro("nenhum dos 3 vizinhos foi chamado")
	else:
		print("  1 enxergou e %d de 3 vizinhos vieram atras" % _horda_acordados.size())
	_passar()
