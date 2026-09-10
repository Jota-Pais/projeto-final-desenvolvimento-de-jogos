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

## A primeira construcao do tipo pedido, e nao a de um indice fixo.
##
## Ate 09/09/2026 estas conferencias apontavam para CONSTRUCOES[1], [6] e [10],
## que eram a segunda casa, o mercadinho e um galpao do bairro. Com o mapa
## grande a lista mudou de tamanho e de ordem, e indice fixo passou a apontar
## para outro predio - buscar por tipo nao quebra quando o mapa cresce.
##
## Pula a sua casa: ela nao se vasculha e nao tem movel.
func _uma_construcao(tipo: String) -> Dictionary:
	for construcao in Mapa.mundo()["construcoes"]:
		if construcao["tipo"] == tipo and not construcao.get("sua", false):
			return construcao
	return {}

func _passar() -> void:
	_fase += 1
	_quadros = 0

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
	var rua := Construcao.porta_de(casa) + Vector2(0.0, 300.0)
	# A grade cobre so uma janela em volta do jogador e e remontada quando ele
	# anda. Pedir a janela aqui, em vez de contar com o _process ja ter rodado,
	# e o que faz esta conferencia medir a navegacao e nao o relogio de quadros.
	_nav.remontar_em(rua)
	var alvos := {
		"sala": Construcao.quartos_de(casa)[0].get_center(),
		"quarto do fundo": Construcao.quartos_de(casa)[1].get_center(),
		"galpao do quintal": Construcao.quartos_de(_uma_construcao("galpao"))[0].get_center(),
		"mercadinho": Construcao.quartos_de(_uma_construcao("comercio"))[0].get_center(),
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

	# De uma ponta a outra do bairro. Eram coordenadas do bairro pequeno ate
	# 09/09/2026, e com o mapa novo elas cairam na mata do oeste - fora da
	# janela, e o teste passou a medir nada. Agora saem do proprio bairro.
	var porao := (_bairro.get_node("EntradaDeCasa") as Node2D).position
	var bairro := Mapa.lugar("bairro")["rect"] as Rect2
	var canto := bairro.end - Vector2(400.0, 400.0)
	_nav.remontar_em(bairro.get_center())
	var longe: PackedVector2Array = _nav.caminho(canto, porao)
	if longe.is_empty():
		_erro("sem caminho do canto sudeste do bairro ate o porao")
	else:
		print("  canto do bairro -> porao  %3d pontos, %.0f px" % [longe.size(), _tamanho(longe)])
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
		zumbi.global_position = porta + Vector2(0.0, 260.0)
		zumbi._olhando = Vector2.UP
		match _caso_da_visao:
			0: _jogador.global_position = Construcao.quartos_de(casa)[1].get_center()
			1: _jogador.global_position = porta + Vector2(0.0, 90.0)
			2:
				_jogador.global_position = porta + Vector2(0.0, 90.0)
				zumbi._olhando = Vector2.DOWN
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
	_jogador.vida = 100.0
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

	if _jogador.vida < 100.0:
		if _chegou_a_perseguir:
			print("  enxergou e passou a perseguir")
		else:
			_erro("chegou em voce sem nunca enxergar (nao passou por PERSEGUINDO)")
		print("  tocou: vida %.0f, aproximou %.0f px em %d quadros de fisica" % [
			_jogador.vida,
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
		_passar()
		return

	if _quadros > 900:
		_erro("nao chegou em 900 quadros (dist %.0f, estado %d)" % [
			zumbi.global_position.distance_to(_jogador.global_position), zumbi._estado])
		Input.action_release("vasculhar")
		_passar()

# --- 5. ele entra na casa atras de voce -------------------------------------

func _preparar_dentro_de_casa() -> void:
	print("\n5. o zumbi entra na casa atras de voce")
	var casa := _uma_construcao("casa")
	_jogador.global_position = Construcao.quartos_de(casa)[1].get_center()
	_jogador.vida = 100.0
	var zumbi = _zumbis[0]
	zumbi.global_position = Construcao.porta_de(casa) + Vector2(0.0, 240.0)
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
	# Num trecho aberto da rodovia, entre o bairro e a cidade: linha de visao
	# limpa e sem arvore no meio.
	#
	# Era Vector2(2900, 1300), coordenada do bairro pequeno - que no mapa de
	# 09/09 caiu dentro da mata do oeste, onde a arvore corta a visao. O teste
	# passou a medir a mata em vez da horda, e acusou o zumbi de nao ver.
	_jogador.global_position = Vector2(10500.0, Mapa.RODOVIA.get_center().y)
	_jogador.vida = 100.0
	_longe_do_teste(4)
	_zumbis[0].global_position = _jogador.global_position + Vector2(0.0, 300.0)
	_zumbis[0]._estado = VAGANDO
	for i in range(1, 4):
		_zumbis[i].global_position = _jogador.global_position + Vector2(160.0 * i, 460.0)
		_zumbis[i]._estado = VAGANDO
	_zumbis[0].foi_chamado(_jogador.global_position)
	_passar()

func _conferir_horda() -> void:
	if _quadros < 240:
		return
	var acordados := 0
	for i in range(1, 4):
		if _zumbis[i]._estado != VAGANDO:
			acordados += 1
	if _zumbis[0]._estado != PERSEGUINDO:
		_erro("o primeiro zumbi nao chegou a enxergar o jogador")
	elif acordados == 0:
		_erro("nenhum dos 3 vizinhos foi chamado")
	else:
		print("  1 enxergou e %d de 3 vizinhos vieram atras" % acordados)
	_passar()
