extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na pistola, na municao ou
## no loot da delegacia.**
##
## Confere as seis coisas que fazem a arma **servir** a core mechanic em vez de
## competir com ela:
##
##  1. voce **nao comeca com ela** - a pistola esta na armaria da delegacia, e e
##     a unica do mapa;
##  2. pistola e municao sao **equipamento e nao loot**: nao ocupam vaga na
##     mochila e nao se perdem no dia que deu errado;
##  3. **sem municao nao atira**, e atirar gasta;
##  4. o tiro mata de uma vez, e **parede corta o tiro**;
##  5. o tiro **chama a horda** num raio maior que o chamado de um zumbi;
##  6. o zumbi baleado **nao renasce hoje** - senao atirar nao serviria de nada.
##
## A 6 e a que quebra sem dar erro: o povoamento por proximidade faz nascer
## zumbi perto de voce, e sem a anotacao ele repunha o que voce acabou de
## matar, dois segundos depois, para sempre.

const Construcao := preload("res://rua/construcao.gd")
const Mapa := preload("res://rua/mapa.gd")
const Pistola := preload("res://rua/pistola.gd")
const Mochila := preload("res://rua/mochila.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const CENA_DA_HUD := preload("res://rua/hud.tscn")

var _falhas := 0
var _quadros := 0
var _feito := false

var _rua: Node
var _jogador: Node2D
var _pistola: Pistola
var _mochila: Mochila
var _cenario: Node

func _ready() -> void:
	_limpar()
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	_jogador = _rua.get_node("Jogador")
	_pistola = _rua.get_node("Jogador/Pistola")
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
## primeira versao desta ferramenta media exatamente isso e acusava a pistola de
## nao matar. E o mesmo motivo pelo qual o conferir_zumbi posiciona num quadro e
## consulta tres depois.
var _fase := 0

func _physics_process(_delta: float) -> void:
	_quadros += 1
	if _feito or _quadros < 4:
		return

	match _fase:
		0:
			_nao_se_comeca_com_ela()
			_e_equipamento_nao_loot()
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
		9:
			_o_tiro_chama_a_horda()
			_o_baleado_nao_renasce()
			_feito = true
			_limpar()
			print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
			get_tree().quit(0 if _falhas == 0 else 1)
	if _fase in [2, 3, 6, 7]:
		_passar()

func _passar() -> void:
	_fase += 1

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _limpar() -> void:
	Travessia.tem_pistola = false
	Travessia.municao = 0
	Travessia.mochila.clear()
	Travessia.documentos.clear()
	Travessia.moveis_vazios.clear()
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA

func _moveis() -> Array[Node]:
	var lista: Array[Node] = []
	for filho in _cenario.get_children():
		if filho is Area2D and "achados" in filho:
			lista.append(filho)
	return lista

# --- 1. voce nao comeca com ela ---------------------------------------------

func _nao_se_comeca_com_ela() -> void:
	print("\n1. onde esta a pistola")
	if Travessia.tem_pistola:
		_erro("o jogo comeca com a pistola na mao")

	var onde: Array[String] = []
	var quantas := 0
	for movel in _moveis():
		for achado in movel.achados:
			if achado != Construcao.PISTOLA:
				continue
			quantas += 1
			onde.append("%s, na %s" % [Mapa.lugar_em(movel.position), movel.rotulo])

	if quantas == 0:
		_erro("nao ha pistola nenhuma no mapa - a promessa de luta do High Concept nao existe")
	elif quantas > 1:
		_erro("ha %d pistolas no mapa; devia ser uma so" % quantas)
	else:
		print("  uma pistola, em %s" % onde[0])
		var longe := (_rua.get_node("EntradaDeCasa") as Node2D).position
		for movel in _moveis():
			if movel.achados.has(Construcao.PISTOLA):
				print("  a %.0f m de casa - achar a arma e recompensa de vasculhar"
					% (longe.distance_to(movel.position) / 40.0))

	# E municao em mais de um lugar: com a armaria como fonte unica, um dia
	# perdido deixaria a arma inutil para sempre.
	var com_municao := 0
	for movel in _moveis():
		if movel.achados.has(Construcao.MUNICAO):
			com_municao += 1
	print("  municao em %d moveis do mapa" % com_municao)
	if com_municao < 2:
		_erro("a municao tem menos de duas fontes no mapa")

# --- 2. equipamento e nao loot ----------------------------------------------

func _e_equipamento_nao_loot() -> void:
	print("\n2. equipamento e nao loot")
	var armaria: Node = null
	for movel in _moveis():
		if movel.achados.has(Construcao.PISTOLA):
			armaria = movel
			break
	if armaria == null:
		return

	var vagas_antes := _mochila.quantos()
	armaria._esvaziar()

	if not Travessia.tem_pistola:
		_erro("vasculhar a armaria nao deu a pistola")
	elif _mochila.itens.has(Construcao.PISTOLA):
		_erro("a pistola foi para a mochila e ocupou vaga")
	else:
		print("  a pistola foi para o cinto, e a mochila continua em %d/%d"
			% [_mochila.quantos(), _mochila.CAPACIDADE])

	# A mochila pode ter recebido o documento da armaria, que ocupa vaga - o que
	# nao pode e a pistola ou a municao ocuparem.
	if _mochila.quantos() > vagas_antes + 1:
		_erro("a armaria ocupou %d vagas na mochila" % (_mochila.quantos() - vagas_antes))

	# E o dia que deu errado nao tira a arma.
	Travessia.municao = 12
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	Travessia.entrar_em_casa(Travessia.FimDoDia.SEM_VIDA)
	get_tree().current_scene = cena_atual
	for filho in get_tree().root.get_children():
		if filho.name == "Casa":
			filho.free()

	if not Travessia.tem_pistola or Travessia.municao != 12:
		_erro("morrer na rua tirou a arma - o mapa nao repoe, isso e beco sem saida")
	else:
		print("  morrer na rua perdeu a mochila e **nao** a arma")

# --- 3. sem municao nao atira -----------------------------------------------

func _sem_municao_nao_atira() -> void:
	print("\n3. a municao")
	Travessia.tem_pistola = true
	Travessia.municao = 0
	_pistola._espera = 0.0
	_pistola._atirar()
	if Travessia.municao != 0:
		_erro("atirar com 0 balas mexeu na municao: %d" % Travessia.municao)
	else:
		print("  com 0 balas, atirar nao faz nada")

	Travessia.municao = 3
	_pistola._espera = 0.0
	_pistola._atirar()
	if Travessia.municao != 2:
		_erro("um tiro gastou %d balas" % (3 - Travessia.municao))
	else:
		print("  um tiro gasta uma bala; %d balas por achado de municao"
			% Construcao.MUNICAO_POR_ACHADO)

# --- 4. o tiro mata, e a parede corta ---------------------------------------

var _alvo: Node2D

## Os dois **no mesmo quarto**, separados na horizontal: o quarto tem 610 px de
## largura e uns 230 de altura, e afastar na vertical punha o jogador do outro
## lado da parede.
func _preparar_o_tiro() -> void:
	print("\n4. o tiro")
	Travessia.tem_pistola = true
	Travessia.municao = 9
	var casa := _uma_casa()
	if casa.is_empty():
		_erro("nao achei casa para conferir o tiro")
		return
	var alvo := Construcao.quartos_de(casa)[0].get_center()
	_alvo = _um_zumbi_em(alvo)
	_jogador.global_position = alvo + Vector2(-220.0, 0.0)

func _conferir_o_tiro() -> void:
	if _alvo == null:
		return
	_apontar_para(_alvo.global_position)
	_pistola._espera = 0.0
	_pistola._atirar()
	# `is_queued_for_deletion` e nao `is_instance_valid`: o zumbi morre com
	# queue_free(), que so libera no fim do quadro - dentro do mesmo quadro ele
	# continua valido. A primeira versao deste teste conferia is_instance_valid e
	# acusava a pistola de nao matar quando ela matava.
	if not _alvo.is_queued_for_deletion():
		_erro("o tiro na mira, a 220 px e sem parede, nao matou")
		_alvo.queue_free()
	else:
		print("  no mesmo quarto e na mira: morreu a 220 px")

## Da rua, com a parede da fachada e a divisoria interna no meio.
func _preparar_a_parede() -> void:
	var casa := _uma_casa()
	if casa.is_empty():
		return
	_alvo = _um_zumbi_em(Construcao.quartos_de(casa)[1].get_center())
	_jogador.global_position = Construcao.porta_de(casa) + Vector2(0.0, 300.0)

func _conferir_a_parede() -> void:
	if _alvo == null:
		return
	_apontar_para(_alvo.global_position)
	_pistola._espera = 0.0
	_pistola._atirar()
	if _alvo.is_queued_for_deletion():
		_erro("o tiro atravessou duas paredes e matou quem estava no quarto do fundo")
	else:
		print("  atras de duas paredes: o tiro para na primeira")
		_alvo.queue_free()

func _uma_casa() -> Dictionary:
	for construcao in Mapa.mundo()["construcoes"]:
		if construcao["tipo"] == "casa" and not construcao.get("sua", false):
			return construcao
	return {}

func _um_zumbi_em(onde: Vector2) -> Node2D:
	var zumbi = _cenario._criar_zumbi(onde)
	# set_physics_process(false): sem isto ele anda entre o posicionamento e o
	# tiro, e o teste passa a medir sorte.
	zumbi.set_physics_process(false)
	zumbi.velocity = Vector2.ZERO
	return zumbi

func _apontar_para(onde: Vector2) -> void:
	_pistola._mira = (onde - _pistola.global_position).normalized()

# --- 5. o tiro chama a horda ------------------------------------------------

## **O custo do tiro.** Ele resolve um problema e cria um maior, e e o que faz a
## arma continuar sendo pressao sobre a mesma acao em vez de aliviar a pressao.
func _o_tiro_chama_a_horda() -> void:
	print("\n5. o estrondo")
	if Pistola.ALCANCE_DO_ESTRONDO <= 700.0:
		_erro("o estrondo (%.0f) nao alcanca mais longe que o chamado de um zumbi (700)"
			% Pistola.ALCANCE_DO_ESTRONDO)

	_jogador.global_position = Mapa.RODOVIA.get_center() + Vector2(20000.0, 0.0)
	var perto := _um_zumbi_em(_jogador.global_position + Vector2(0.0, 1200.0))
	var longe := _um_zumbi_em(_jogador.global_position
		+ Vector2(0.0, Pistola.ALCANCE_DO_ESTRONDO + 900.0))
	perto._estado = 0
	longe._estado = 0

	Travessia.municao = 5
	_pistola._espera = 0.0
	_apontar_para(_jogador.global_position + Vector2(1000.0, 0.0))
	_pistola._atirar()

	if perto._estado == 0:
		_erro("o zumbi a 1.200 px nao ouviu o tiro")
	elif longe._estado != 0:
		_erro("o zumbi a %.0f px ouviu um tiro que nao devia alcancar"
			% Pistola.ALCANCE_DO_ESTRONDO)
	else:
		print("  a 1.200 px veio; a %.0f px nao ouviu"
			% (Pistola.ALCANCE_DO_ESTRONDO + 900.0))
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

	(_cenario._zumbis_vivos[0] as Node).levar_tiro()
	_cenario._povoar_em_volta()
	_cenario._povoar_em_volta()

	if _cenario._zumbis_vivos.has(0) and not (_cenario._zumbis_vivos[0] as Node).is_queued_for_deletion():
		_erro("o zumbi baleado renasceu no mesmo ponto - atirar nao serve de nada")
	else:
		print("  o ponto ficou limpo pelo resto do dia (%d vivos antes)" % vivos_antes)
	_cenario.povoa_por_proximidade = false
