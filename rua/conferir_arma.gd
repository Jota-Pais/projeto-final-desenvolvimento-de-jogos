extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer nas armas, nas balas ou
## no que sai dos moveis.**
##
## Confere as sete coisas que fazem a arma **servir** a core mechanic em vez de
## competir com ela:
##
##  1. voce **comeca com ela** (30/09/2026): a Beretta nao esta em movel nenhum
##     do mapa, a partida abre com um pente, e as balas estao espalhadas por
##     muitos moveis;
##  2. balas sao **equipamento e nao loot**: vao para o cinto, nao ocupam vaga
##     na mochila e nao se perdem no dia que deu errado;
##  3. **sem municao nao atira**, e atirar gasta;
##  4. o tiro **tira vida e nao mata de uma vez** (03/10/2026: o zumbi tem
##     vida; o 1o tiro fere, o ultimo derruba), e **parede corta o tiro**;
##  5. o tiro **chama a horda** num raio maior que o chamado de um zumbi;
##  6. o zumbi baleado **nao renasce hoje** - senao atirar nao serviria de nada;
##  7. **as oito armas** da lista do Joao (05/10/2026) existem na ficha, tem
##     desenho e ferem; e o corpo do zumbi **se vasculha** (item 4).
##
## A 6 e a que quebra sem dar erro: o povoamento por proximidade faz nascer
## zumbi perto de voce, e sem a anotacao ele repunha o que voce acabou de
## matar, dois segundos depois, para sempre.

const Construcao := preload("res://rua/construcao.gd")
const Mapa := preload("res://rua/mapa.gd")
const Arma := preload("res://rua/arma.gd")
const Mochila := preload("res://rua/mochila.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const CENA_DA_HUD := preload("res://rua/hud.tscn")

var _falhas := 0

var _quadros := 0
var _feito := false

var _rua: Node
var _jogador: Node2D
var _arma: Arma
var _mochila: Mochila
var _cenario: Node

func _ready() -> void:
	_limpar()
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	_jogador = _rua.get_node("Jogador")
	_arma = _rua.get_node("Jogador/Arma")
	_mochila = _rua.get_node("Mochila")
	_cenario = _rua.get_node("Cenario")
	# Esta ferramenta teleporta o jogador para montar cada cena; com o
	# povoamento ligado o cenario liberaria os zumbis que ela esta medindo.
	_cenario.povoa_por_proximidade = false
	_rua.get_node("Relogio").set_process(false)

## Em fases e em quadro de FISICA, e nao tudo de uma vez.
##
## O tiro e raycast, e **zumbi criado e baleado no mesmo quadro nao existe ainda
## para a fisica** - o servidor so conhece a posicao nova no passo seguinte. A
## primeira versao desta ferramenta media exatamente isso e acusava a arma de
## nao matar. E o mesmo motivo pelo qual o conferir_zumbi posiciona num quadro e
## consulta tres depois.
var _fase := 0

func _physics_process(_delta: float) -> void:
	_quadros += 1
	if _feito or _quadros < 4:
		return

	match _fase:
		0:
			_comeca_com_ela()
			_balas_sao_equipamento()
			_sem_municao_nao_atira()
			_passar()
		1: _preparar_o_tiro(); _passar()
		2: pass
		3: pass
		4: _conferir_o_tiro(); _passar()
		5: _preparar_a_parede(); _passar()
		6: pass
		7: pass
		8: _conferir_a_parede(); _passar()
		9: _preparar_as_armas(); _passar()
		10: pass
		11: pass
		12:
			_conferir_as_armas()
			_o_tiro_chama_a_horda()
			_o_baleado_nao_renasce()
			_feito = true
			_limpar()
			print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
			get_tree().quit(0 if _falhas == 0 else 1)
	if _fase in [2, 3, 6, 7, 10, 11]:
		_passar()

func _passar() -> void:
	_fase += 1

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## O estado de comeco de partida, que e o que o Travessia tem ao nascer.
func _limpar() -> void:
	Travessia.arma = Travessia.ARMA_DE_COMECO
	Travessia.balas = Travessia.balas_de_comeco()
	Travessia.documentos.clear()
	Travessia.moveis_vazios.clear()
	Travessia.documentos_perdidos = 0
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA

func _moveis() -> Array[Node]:
	var lista: Array[Node] = []
	for filho in _cenario.get_children():
		if filho is Area2D and "achados" in filho:
			lista.append(filho)
	return lista

func _caixinhas_em(movel: Node) -> int:
	var n := 0
	for achado in movel.achados:
		if Construcao.e_municao(achado):
			n += 1
	return n

## Quantas caixinhas de cada calibre ha no movel.
func _caixinhas_por_calibre(movel: Node) -> Dictionary:
	var contagem := {}
	for achado in movel.achados:
		if Construcao.e_municao(achado):
			var calibre := Construcao.calibre_de(achado)
			contagem[calibre] = contagem.get(calibre, 0) + 1
	return contagem

# --- 1. voce comeca com ela -------------------------------------------------

func _comeca_com_ela() -> void:
	print("\n1. voce comeca com ela")
	if Travessia.BALAS_DE_COMECO <= 0:
		_erro("a partida comeca com %d balas - a arma nasce inutil" % Travessia.BALAS_DE_COMECO)
	else:
		print("  a partida abre com a Beretta e %d balas" % Travessia.BALAS_DE_COMECO)

	# A HUD mostra a arma desde o primeiro quadro, sem precisar achar nada.
	var hud := CENA_DA_HUD.instantiate()
	add_child(hud)
	hud._process(0.0)
	var esquerda: String = (hud.get_node("Esquerda") as Label).text
	if not esquerda.contains("Beretta"):
		_erro("a HUD nao mostra a Beretta desde o comeco: \"%s\"" % esquerda)
	else:
		print("  a HUD diz \"%s\"" % esquerda)
	hud.free()

	# Nenhum movel tem a arma, nem nada que nao seja bala ou documento - o loot
	# generico saiu do jogo em 30/09/2026.
	var com_balas := 0
	var estranhos := {}
	for movel in _moveis():
		if _caixinhas_em(movel) > 0:
			com_balas += 1
		for achado in movel.achados:
			if not Construcao.e_municao(achado) and not Construcao.e_documento(achado):
				estranhos[achado] = true
	if not estranhos.is_empty():
		_erro("ha item que nao e bala nem documento no mapa: %s" % ", ".join(estranhos.keys()))
	print("  balas em %d de %d moveis" % [com_balas, _moveis().size()])
	if com_balas < 2:
		_erro("as balas tem menos de duas fontes no mapa")

# --- 2. balas sao equipamento, nao loot ------------------------------------

func _balas_sao_equipamento() -> void:
	print("\n2. balas sao equipamento, nao loot")
	var com_balas: Node = null
	for movel in _moveis():
		if _caixinhas_em(movel) > 0:
			com_balas = movel
			break
	if com_balas == null:
		return

	var caixinhas := _caixinhas_em(com_balas)
	var por_calibre := _caixinhas_por_calibre(com_balas)
	var balas_antes := Travessia.total_de_balas()
	var antes_por_calibre: Dictionary = Travessia.balas.duplicate()
	var vagas_antes := _mochila.quantos()
	com_balas._esvaziar()

	# Cada caixinha vai para o calibre dela (05/10/2026), e a soma bate.
	var calibre_errado := ""
	for calibre in por_calibre:
		var esperado_no_calibre: int = antes_por_calibre.get(calibre, 0) + por_calibre[calibre] * Construcao.MUNICAO_POR_ACHADO
		if Travessia.balas.get(calibre, 0) != esperado_no_calibre:
			calibre_errado = calibre
	var esperado := balas_antes + caixinhas * Construcao.MUNICAO_POR_ACHADO
	if Travessia.total_de_balas() != esperado:
		_erro("vasculhar %d caixinha(s) levou as balas de %d para %d, esperado %d"
			% [caixinhas, balas_antes, Travessia.total_de_balas(), esperado])
	elif not calibre_errado.is_empty():
		_erro("as balas %s nao foram para o calibre delas (cinto: %s)" % [calibre_errado, Travessia.balas])
	elif _mochila.quantos() != vagas_antes:
		_erro("as balas foram para a mochila")
	elif not com_balas.achados.is_empty():
		_erro("ficou coisa no movel depois do vasculho: %s" % ", ".join(com_balas.achados))
	else:
		print("  %s: %d caixinha(s) %s viraram %d balas no cinto, cada uma no seu calibre; a mochila continua com %d"
			% [com_balas.rotulo, caixinhas, por_calibre, caixinhas * Construcao.MUNICAO_POR_ACHADO, _mochila.quantos()])

	# E o dia que deu errado nao tira as balas.
	Travessia.municao = 12
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	Travessia.entrar_em_casa(Travessia.FimDoDia.AMANHECEU_NA_RUA)
	get_tree().current_scene = cena_atual
	for filho in get_tree().root.get_children():
		if filho.name == "Casa":
			filho.free()

	if Travessia.municao != 12:
		_erro("o dia que deu errado mexeu nas balas (%d) - o mapa nao repoe, isso e beco sem saida"
			% Travessia.municao)
	else:
		print("  amanhecer na rua perdeu a mochila e **nao** as balas")

# --- 3. sem municao nao atira -----------------------------------------------

func _sem_municao_nao_atira() -> void:
	print("\n3. a municao")
	Travessia.municao = 0
	_arma._espera = 0.0
	_arma._atirar()
	if Travessia.municao != 0:
		_erro("atirar com 0 balas mexeu na municao: %d" % Travessia.municao)
	else:
		print("  com 0 balas, atirar nao faz nada")

	Travessia.municao = 3
	_arma._espera = 0.0
	_arma._atirar()
	if Travessia.municao != 2:
		_erro("um tiro gastou %d balas" % (3 - Travessia.municao))
	else:
		print("  um tiro gasta uma bala; %d balas por caixinha achada"
			% Construcao.MUNICAO_POR_ACHADO)

# --- 4. o tiro mata, e a parede corta ---------------------------------------

var _alvo: Node2D

## Os dois **no mesmo quarto**, separados na horizontal: afastar na vertical
## poria o jogador do outro lado da parede.
func _preparar_o_tiro() -> void:
	print("\n4. o tiro")
	Travessia.municao = 9
	var casa := _uma_casa()
	if casa.is_empty():
		_erro("nao achei casa para conferir o tiro")
		return
	var alvo := Construcao.quartos_de(casa)[0].get_center()
	_alvo = _um_zumbi_em(alvo)
	# Ao longo da FACHADA, e nao sempre em x: numa casa de porta leste/oeste a
	# largura do quarto corre em y, nao em x.
	_jogador.global_position = alvo + Construcao.eixo_da_fachada(casa) * -220.0

## O 1o tiro tira o dano da arma e deixa de pe; os seguintes, ate a vida
## acabar, derrubam. O morto nao some na hora (fica no chao como corpo), entao
## o que se le e `morto`, e nao `is_queued_for_deletion`. E o corpo tem que
## ser vasculhavel (05/10/2026): sem caixa de movel e sem bloquear a passagem.
func _conferir_o_tiro() -> void:
	if _alvo == null:
		return
	_apontar_para(_alvo.global_position)
	var vida_cheia: float = _alvo.VIDA_CHEIA
	var dano: float = _arma.ficha()["dano"]
	var tiros := int(ceilf(vida_cheia / dano))
	_arma._espera = 0.0
	_arma._atirar()
	if _alvo.morto:
		_erro("um tiro so derrubou - a vida do zumbi (%.0f) nao esta valendo" % vida_cheia)
	elif not is_equal_approx(_alvo.vida, vida_cheia - dano):
		_erro("o tiro na mira, a 220 px e sem parede, nao tirou vida (%.0f de %.0f)"
			% [_alvo.vida, vida_cheia])
	else:
		for i in tiros - 1:
			_arma._espera = 0.0
			_arma._atirar()
		if not _alvo.morto:
			_erro("%d tiros na mira nao derrubaram (vida %.0f de %.0f)"
				% [tiros, _alvo.vida, vida_cheia])
		else:
			print("  no mesmo quarto e na mira: o 1o tiro tirou %.0f de %.0f, o %do derrubou"
				% [dano, vida_cheia, tiros])
			_conferir_o_corpo()
	_alvo.queue_free()

func _conferir_o_corpo() -> void:
	var corpo := _alvo.get_node_or_null("Corpo")
	if corpo == null:
		_erro("o morto nao virou vasculhavel - nao da para acessar o inventario dele")
	elif corpo.solido or corpo.desenhar_caixa:
		_erro("o corpo do zumbi bloqueia a passagem ou desenha caixa de movel")
	elif corpo.achados != _alvo.inventario:
		_erro("o que sai do corpo nao e o inventario do zumbi")
	else:
		print("  o corpo se vasculha (\"%s\", %.1f s) e esta %s" % [corpo.rotulo, corpo.duracao,
			"vazio - nada no zumbi por enquanto" if corpo.achados.is_empty() else str(corpo.achados)])

## Da rua, com a parede da fachada e a divisoria interna no meio.
func _preparar_a_parede() -> void:
	var casa := _uma_casa()
	if casa.is_empty():
		return
	_alvo = _um_zumbi_em(Construcao.quartos_de(casa)[1].get_center())
	_jogador.global_position = Construcao.porta_de(casa) + Construcao.normal_de(casa) * 300.0

func _conferir_a_parede() -> void:
	if _alvo == null:
		return
	_apontar_para(_alvo.global_position)
	_arma._espera = 0.0
	_arma._atirar()
	if _alvo.vida < _alvo.VIDA_CHEIA:
		_erro("o tiro atravessou duas paredes e feriu quem estava no quarto do fundo")
	else:
		print("  atras de duas paredes: o tiro para na primeira")
	_alvo.queue_free()

## A casa de teste: a mais perto de onde o jogador nasce com a frente livre e
## com pelo menos 560 px de fachada - o tiro da fase 4 e dado de 220 px de
## lado dentro da sala, e numa casa estreita o jogador nasceria dentro da
## parede.
func _uma_casa() -> Dictionary:
	var arvores: Array = _cenario._arvores
	return Mapa.construcao_com_a_frente_livre("casa", Mapa.onde_o_jogador_nasce(), 340.0, 560.0, arvores)

func _um_zumbi_em(onde: Vector2) -> Node2D:
	var zumbi = _cenario._criar_zumbi(onde)
	# set_physics_process(false): sem isto ele anda entre o posicionamento e o
	# tiro, e o teste passa a medir sorte.
	zumbi.set_physics_process(false)
	zumbi.velocity = Vector2.ZERO
	return zumbi

func _apontar_para(onde: Vector2) -> void:
	_arma._mira = (onde - _arma.global_position).normalized()

# --- 7. as oito armas -------------------------------------------------------

var _alvo_das_armas: Node2D

## Um zumbi a 220 px do jogador, na praca, para cada arma atirar nele.
func _preparar_as_armas() -> void:
	_jogador.global_position = (Mapa.lugar("Praça")["rect"] as Rect2).get_center()
	_alvo_das_armas = _um_zumbi_em(_jogador.global_position + Vector2(0.0, 220.0))

## A lista do Joao (05/10/2026). Cada arma existe na ficha, tem desenho em
## rua/arte/armas/ e, na mao, fere o zumbi a 220 px - a escopeta com pelo menos
## um dos projeteis. A vida do alvo volta a cada tiro, para cada arma medir do
## zero; no fim a Beretta volta para a mao.
func _conferir_as_armas() -> void:
	print("\n7. as oito armas")
	var lista := ["Revólver 38", "Beretta 9mm", "Doze 2 canos", "Benelli semiauto",
		"CTT40", "Fireagle 9mm", "Fall", "M4"]
	for nome in lista:
		if not Arma.ARMAS.has(nome):
			_erro("a arma \"%s\" da lista nao esta na ficha" % nome)
	if Arma.ARMAS.size() != lista.size():
		_erro("a ficha tem %d armas; a lista do Joao tem %d" % [Arma.ARMAS.size(), lista.size()])
	if _alvo_das_armas == null:
		return

	var desenho := _arma.get_node("Desenho") as Sprite2D
	# Cada arma atira com a municao do calibre dela, entao todos levam balas.
	for calibre in Construcao.MUNICOES:
		Travessia.balas[calibre] = 99
	_apontar_para(_alvo_das_armas.global_position)
	for nome in Arma.ORDEM:
		if not Arma.ARMAS.has(nome):
			continue
		_arma.trocar(nome)
		var ficha: Dictionary = Arma.ARMAS[nome]
		if desenho.texture == null:
			_erro("%s: sem desenho em rua/arte/armas/%s.png" % [nome, ficha["desenho"]])
			continue
		var antes: float = _alvo_das_armas.vida
		var calibre: String = ficha["municao"]
		var balas_antes: int = Travessia.balas[calibre]
		_arma._espera = 0.0
		_arma._atirar()
		var tirou: float = antes - _alvo_das_armas.vida
		var maximo := float(ficha["dano"]) * int(ficha["projeteis"])
		if not Construcao.MUNICOES.has(calibre):
			_erro("%s: o calibre \"%s\" nao tem municao em Construcao.MUNICOES" % [nome, calibre])
		elif Travessia.balas[calibre] != balas_antes - 1:
			_erro("%s: o tiro nao gastou uma bala %s (%d -> %d)" % [nome, calibre, balas_antes, Travessia.balas[calibre]])
		elif tirou <= 0.0:
			_erro("%s: o tiro a 220 px nao feriu" % nome)
		elif tirou > maximo + 0.01:
			_erro("%s: tirou %.0f, mais que %d x %.0f" % [nome, tirou, ficha["projeteis"], ficha["dano"]])
		else:
			print("  %s (%s, %s): %d x %.0f de dano, %s, tirou %.0f; desenho %d x %d" % [
				nome, ficha["classe"], Construcao.MUNICOES[calibre], ficha["projeteis"], ficha["dano"],
				"automatica" if ficha["automatica"] else "um tiro por clique", tirou,
				desenho.texture.get_width(), desenho.texture.get_height()])
		_alvo_das_armas.vida = _alvo_das_armas.VIDA_CHEIA
	_arma.trocar(Travessia.ARMA_DE_COMECO)
	if Travessia.arma != Travessia.ARMA_DE_COMECO:
		_erro("a Beretta nao voltou para a mao depois da troca")
	_alvo_das_armas.queue_free()

# --- 5. o tiro chama a horda ------------------------------------------------

## **O custo do tiro.** Ele resolve um problema e cria um maior, e e o que faz a
## arma continuar sendo pressao sobre a mesma acao em vez de aliviar a pressao.
func _o_tiro_chama_a_horda() -> void:
	print("\n5. o estrondo")
	var estrondo: float = _arma.ficha()["estrondo"]
	if estrondo <= 700.0:
		_erro("o estrondo (%.0f) nao alcanca mais longe que o chamado de um zumbi (700)"
			% estrondo)

	# No meio da praca: o estrondo e so um raio, nao precisa de linha de visao,
	# mas o jogador e os dois zumbis tem que nascer em chao livre, e a praca e
	# o maior gramado aberto do mapa.
	_jogador.global_position = (Mapa.lugar("Praça")["rect"] as Rect2).get_center()
	var perto := _um_zumbi_em(_jogador.global_position + Vector2(0.0, 1200.0))
	var longe := _um_zumbi_em(_jogador.global_position
		+ Vector2(0.0, estrondo + 900.0))
	perto._estado = 0
	longe._estado = 0

	Travessia.municao = 5
	_arma._espera = 0.0
	_apontar_para(_jogador.global_position + Vector2(1000.0, 0.0))
	_arma._atirar()

	if perto._estado == 0:
		_erro("o zumbi a 1.200 px nao ouviu o tiro")
	elif longe._estado != 0:
		_erro("o zumbi a %.0f px ouviu um tiro que nao devia alcancar"
			% estrondo)
	else:
		print("  a 1.200 px veio; a %.0f px nao ouviu"
			% (estrondo + 900.0))
	perto.queue_free()
	longe.queue_free()

# --- 6. o baleado nao renasce hoje ------------------------------------------

func _o_baleado_nao_renasce() -> void:
	print("\n6. o baleado nao renasce hoje")
	_cenario.povoa_por_proximidade = true
	var pontos: Array = _cenario._pontos_de_zumbi
	if pontos.is_empty():
		_erro("o mapa nao tem ponto de povoamento")
		return

	# Leva o jogador para o primeiro ponto e deixa o cenario povoar.
	_jogador.global_position = pontos[0] + Vector2(300.0, 0.0)
	_cenario._povoar_em_volta()
	var vivos_antes := get_tree().get_nodes_in_group("zumbi").size()
	if not _cenario._zumbis_vivos.has(0):
		_erro("o cenario nao fez nascer zumbi no ponto 0 com o jogador do lado")
		return

	# Um tiro com a vida inteira: o que importa aqui e o ponto, nao a conta.
	var baleado: Node = _cenario._zumbis_vivos[0]
	baleado.levar_tiro(baleado.VIDA_CHEIA, Vector2.RIGHT)
	_cenario._povoar_em_volta()
	_cenario._povoar_em_volta()

	if _cenario._zumbis_vivos.has(0) and not (_cenario._zumbis_vivos[0] as Node).morto:
		_erro("o zumbi baleado renasceu no mesmo ponto - atirar nao serve de nada")
	else:
		print("  o ponto ficou limpo pelo resto do dia (%d vivos antes)" % vivos_antes)
	baleado.queue_free()
	_cenario.povoa_por_proximidade = false
