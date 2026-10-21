extends Node
## O tutorial (21/10/2026, para a entrega do Joao): o roteiro de
## design/narrativa.md virando jogo, em dois dias, dentro do cerco da regiao
## rosa. **As falas nao moram aqui** - estao em rua/falas_do_tutorial.gd, com o
## texto do Joao; aqui e so quando cada uma toca.
##
## Dia 1:
##
##  1. **abertura** - cena com a camera mais aberta e o jogador sob roteiro: ele
##     anda sem rumo pela rua de cima, perto da casa do Antonio; um zumbi o pega
##     desprevenido e o Antonio, do posto de sacos da quina da casa, o mata;
##     ele vai direto ao portao, e a conversa da o radio e o favor;
##  2. **favor** - buscar o item no Restaurante. O radio ensina a correr, a
##     agachar e se esconder (cobertura baixa, rua/camadas.gd) e a vasculhar;
##     o item esta num movel do Restaurante;
##  3. **voltar_ao_portao** - com o item, de volta ao portao: a entrega e a
##     **9mm** (o dia 1 comeca desarmado - Travessia.armado);
##  4. **ir_para_casa** - voltar antes de escurecer; o dia acaba pela porta.
##
## Dia 2 (**dia_2**): explorar e usar a arma. O primeiro zumbi abatido fecha o
## tutorial (**fim**).
##
## A etapa mora em Travessia.tutorial e atravessa os dias: se o dia 1 acabar
## no meio (caiu, amanheceu na rua), o dia seguinte retoma de onde parou. So a
## partida que comeca pelo titulo tem tutorial (Travessia.comecar_partida).

const Mapa := preload("res://rua/mapa.gd")
const Falas := preload("res://rua/falas_do_tutorial.gd")
const Antonio := preload("res://rua/antonio.gd")
const Jogador := preload("res://rua/jogador.gd")

const RETRATO_DO_ANTONIO := preload("res://rua/arte/antonio/retrato.png")

## Os lugares do roteiro, em px do PNG do desenho (como os ROTULOS do mapa).
## O jogador comeca a cena na rua de cima, na frente da casa dele, e anda para
## leste, para a casa do Antonio; o Antonio fica atras dos sacos de areia da
## quina noroeste da casa dele, que olham para essa rua.
const INICIO := Vector2(1190.0, 619.5)
const SEM_RUMO := [Vector2(1196.0, 618.5), Vector2(1200.0, 621.0), Vector2(1203.5, 619.6)]
const DE_ONDE_VEM_O_ZUMBI := Vector2(1191.0, 618.0)
const ONDE_ESTA_O_ANTONIO := Vector2(1205.2, 634.2)
## O ponto livre da calcada, 74 px de mundo ao norte da linha do portao, onde
## o boneco aparece inteiro (marca "conversa_portao_antonio" do desenho).
const CONVERSA_NO_PORTAO := Vector2(1211.25, 627.4)
## O beco entre a sua casa e a do Antonio: onde o radio ensina a agachar.
const BECO := Vector2(1197.0, 645.0)
const PORTA_DO_RESTAURANTE := Vector2(1187.5, 737.4)

## A camera da cena, mais aberta que a do jogo, para o Antonio caber na tela
## junto com o jogador. Inteira, como a do jogo (ver Jogador.ZOOM_DA_CAMERA).
const ZOOM_DA_CENA := 1.0
## Andar "meio sem rumo": devagar.
const VELOCIDADE_SEM_RUMO := 45.0
## Quanto perto do ponto conta como chegou (px de mundo).
const PERTO := 60.0
const PERTO_DO_BECO := 140.0
const PERTO_DO_RESTAURANTE := 360.0
## Quanto tempo depois do favor o radio ensina a agachar, se ele nao passou
## pelo beco.
const AGACHAR_DEPOIS_DE := 25.0
## Quanto o objetivo fica na tela depois do fim.
const FIM_NA_TELA := 6.0

## A seta do objetivo: a cor e o tamanho.
const COR_DO_OBJETIVO := Color("e8d6a8")
const COR_DA_SETA := Color(0.91, 0.69, 0.38, 0.9)

var _jogador: Node2D
var _cenario: Node
var _caixa: Node
var _antonio: Node2D
var _camada: CanvasLayer
var _objetivo: Label
var _seta: Control
## Para onde a seta aponta (mundo), ou NAN sem alvo.
var _alvo := Vector2(NAN, NAN)
var _no_roteiro := false
var _tempo_no_favor := 0.0
var _movel_do_favor: Node

func _ready() -> void:
	if Travessia.tutorial == "" or Travessia.tutorial == "fim":
		queue_free()
		return
	# A caixa de fala de perto para o jogo; o tutorial espera por ela.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_a_tela()
	# A rua inteira montada (cenario, jogador no lugar) antes do roteiro.
	await get_tree().process_frame
	await get_tree().process_frame
	_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
	_cenario = get_parent().get_node_or_null("Cenario")
	_caixa = get_parent().get_node_or_null("CaixaDeFala")
	if _jogador == null or _cenario == null or _caixa == null:
		push_warning("tutorial: falta jogador, cenario ou caixa de fala na cena")
		return
	_por_o_antonio()
	_cenario.zumbi_morreu.connect(_ao_morrer_um_zumbi)

	# O dia 1 acabou depois da 9mm: hoje e o dia 2.
	if Travessia.tutorial == "ir_para_casa" and Travessia.dia >= 2:
		Travessia.tutorial = "dia_2"
	match Travessia.tutorial:
		"abertura":
			await _abertura()
		"favor":
			_comecar_o_favor()
		"voltar_ao_portao":
			_voltar_ao_portao()
		"ir_para_casa":
			_ir_para_casa()
		"dia_2":
			_dia_2()

func _p(ponto_do_png: Vector2) -> Vector2:
	return Mapa.ponto_do_png(ponto_do_png)

func _process(delta: float) -> void:
	if _jogador == null or _no_roteiro:
		_seta.queue_redraw()
		return
	var onde := _jogador.global_position
	match Travessia.tutorial:
		"favor":
			_tempo_no_favor += delta
			if onde.distance_to(_p(BECO)) < PERTO_DO_BECO or _tempo_no_favor > AGACHAR_DEPOIS_DE:
				_radio_uma_vez("agachar", Falas.RADIO_AGACHAR)
			if onde.distance_to(_p(PORTA_DO_RESTAURANTE)) < PERTO_DO_RESTAURANTE:
				_radio_uma_vez("restaurante", Falas.RADIO_RESTAURANTE)
			_avisar_se_foi_visto()
		"voltar_ao_portao":
			_avisar_se_foi_visto()
			if onde.distance_to(_p(CONVERSA_NO_PORTAO)) < PERTO:
				_entregar()
	_seta.queue_redraw()

# --- a tela: o objetivo e a seta -------------------------------------------

func _montar_a_tela() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 2
	add_child(_camada)
	_objetivo = Label.new()
	_objetivo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_objetivo.offset_top = 40.0
	_objetivo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_objetivo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objetivo.add_theme_font_size_override("font_size", 17)
	_objetivo.add_theme_color_override("font_color", COR_DO_OBJETIVO)
	_objetivo.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	_objetivo.add_theme_constant_override("outline_size", 5)
	_camada.add_child(_objetivo)
	_seta = Control.new()
	_seta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seta.draw.connect(_desenhar_a_seta)
	_camada.add_child(_seta)

func _mostrar_objetivo(texto: String, alvo := Vector2(NAN, NAN)) -> void:
	_objetivo.text = texto
	_alvo = alvo

## Uma marca em cima do alvo, quando ele esta na tela; senao, uma seta na beira
## da tela apontando para ele.
func _desenhar_a_seta() -> void:
	if is_nan(_alvo.x) or _jogador == null:
		return
	var tela := _seta.get_viewport_rect().size
	var margem := 46.0
	# Sem janela (as ferramentas em headless) a tela nao tem tamanho.
	if tela.x < margem * 3.0 or tela.y < margem * 3.0:
		return
	var no_ecra: Vector2 = _seta.get_viewport().get_canvas_transform() * _alvo
	var dentro := Rect2(Vector2.ONE * margem, tela - Vector2.ONE * margem * 2.0)
	if dentro.has_point(no_ecra):
		var p := no_ecra + Vector2(0.0, -30.0)
		_seta.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -10), p + Vector2(8, -10), p]), COR_DA_SETA)
		return
	var centro := tela / 2.0
	var para := (no_ecra - centro).normalized()
	# Onde a reta do centro ao alvo sai do retangulo de dentro.
	var t := INF
	if absf(para.x) > 0.001:
		t = minf(t, (dentro.size.x / 2.0) / absf(para.x))
	if absf(para.y) > 0.001:
		t = minf(t, (dentro.size.y / 2.0) / absf(para.y))
	var ponta := centro + para * t
	var lado := Vector2(-para.y, para.x)
	_seta.draw_colored_polygon(PackedVector2Array([
		ponta, ponta - para * 18.0 + lado * 10.0, ponta - para * 18.0 - lado * 10.0]), COR_DA_SETA)

# --- o Antonio --------------------------------------------------------------

func _por_o_antonio() -> void:
	_antonio = Antonio.new()
	_antonio.name = "Antonio"
	_antonio.position = _p(ONDE_ESTA_O_ANTONIO)
	# No cenario, que e onde o Y-sort junta ele com os muros e os sacos.
	_cenario.add_child(_antonio)
	_antonio.olhar_para(_p(SEM_RUMO[1]))

# --- dia 1: a abertura -------------------------------------------------------

func _abertura() -> void:
	_no_roteiro = true
	_jogador.no_roteiro = true
	var camera := _jogador.get_node("Camera") as Camera2D
	camera.zoom = Vector2.ONE * ZOOM_DA_CENA
	_jogador.global_position = _p(INICIO)
	# A camera desce ate o meio do caminho para o Antonio: com ela no jogador,
	# o posto dele ficava cortado na beira de baixo da tela.
	camera.offset = Vector2(0.0, (_antonio.global_position.y - _jogador.global_position.y) / 2.0)
	_mostrar_objetivo("")
	await _conversa(Falas.ABERTURA)

	await _andar_ate(_p(SEM_RUMO[0]), VELOCIDADE_SEM_RUMO)
	await _parar_olhando(Vector2.UP, 0.7)
	await _andar_ate(_p(SEM_RUMO[1]), VELOCIDADE_SEM_RUMO)
	await _parar_olhando(Vector2.DOWN + Vector2.RIGHT, 0.5)

	# O zumbi vem por tras, ja vendo ele.
	var zumbi: Node2D = _cenario._criar_zumbi(_p(DE_ONDE_VEM_O_ZUMBI))
	zumbi._olhando = (_jogador.global_position - zumbi.global_position).normalized()
	var pegou := [false]
	var ao_ser_pego := func() -> void: pegou[0] = true
	_jogador.atingido.connect(ao_ser_pego)
	_jogador.velocidade_do_roteiro = VELOCIDADE_SEM_RUMO
	var tempo := 0.0
	while not pegou[0] and tempo < 7.0:
		_jogador.direcao_do_roteiro = (_p(SEM_RUMO[2]) - _jogador.global_position).normalized() \
			if _jogador.global_position.distance_to(_p(SEM_RUMO[2])) > 4.0 else Vector2.ZERO
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
		# Se o zumbi encalhou, ele chega de qualquer jeito: a cena nao espera.
		if tempo > 5.0 and is_instance_valid(zumbi):
			zumbi.global_position = zumbi.global_position.move_toward(_jogador.global_position, 6.0)
	_jogador.direcao_do_roteiro = Vector2.ZERO
	_jogador.atingido.disconnect(ao_ser_pego)

	# O tiro do Antonio.
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(zumbi):
		_antonio.atirar_em(zumbi.global_position)
		zumbi.levar_tiro(1000.0, (zumbi.global_position - _antonio.global_position).normalized())
	await get_tree().create_timer(0.9).timeout
	_jogador.olhar_para(_antonio.global_position - _jogador.global_position)
	await _conversa(Falas.O_TIRO)

	# Direto ao portao.
	await _andar_ate(_p(CONVERSA_NO_PORTAO), Jogador.VELOCIDADE)
	_jogador.olhar_para(Vector2.DOWN)
	_antonio.olhar_para(_jogador.global_position)
	await _conversa(Falas.PORTAO)

	camera.zoom = Vector2.ONE * Jogador.ZOOM_DA_CAMERA
	camera.offset = Vector2.ZERO
	_jogador.no_roteiro = false
	_no_roteiro = false
	Travessia.tutorial = "favor"
	_comecar_o_favor()

## Anda sob roteiro ate um ponto (mundo), ou ate desistir.
func _andar_ate(alvo: Vector2, velocidade: float, limite := 10.0) -> void:
	_jogador.velocidade_do_roteiro = velocidade
	var tempo := 0.0
	while _jogador.global_position.distance_to(alvo) > 4.0 and tempo < limite:
		_jogador.direcao_do_roteiro = (alvo - _jogador.global_position).normalized()
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
	_jogador.direcao_do_roteiro = Vector2.ZERO

func _parar_olhando(direcao: Vector2, segundos: float) -> void:
	_jogador.olhar_para(direcao)
	await get_tree().create_timer(segundos).timeout

## Uma conversa de perto: cada bloco de linhas seguidas do mesmo personagem
## numa caixa, com o retrato do Antonio quando e ele. Espera o jogo voltar
## (a caixa so solta quando o E e solto).
func _conversa(falas: Array) -> void:
	var i := 0
	while i < falas.size():
		var quem: String = falas[i][0]
		var linhas := PackedStringArray()
		while i < falas.size() and falas[i][0] == quem:
			linhas.append(falas[i][1])
			i += 1
		var retrato: Texture2D = RETRATO_DO_ANTONIO if quem == Falas.QUEM_E_O_ANTONIO else null
		_caixa.calar_o_radio()
		while _caixa.ocupada():
			await get_tree().process_frame
		_caixa.falar(quem, linhas, retrato)
		while _caixa.ocupada() or get_tree().paused:
			await get_tree().process_frame

func _radio(linhas: Array) -> void:
	_caixa.pelo_radio(Falas.QUEM_E_O_ANTONIO, PackedStringArray(linhas), RETRATO_DO_ANTONIO)

## A fala de radio que so toca uma vez na partida.
func _radio_uma_vez(chave: String, linhas: Array) -> void:
	if Travessia.tutorial_avisos.has(chave):
		return
	Travessia.tutorial_avisos[chave] = true
	_radio(linhas)

## A primeira vez que um zumbi te ve e vem atras.
func _avisar_se_foi_visto() -> void:
	if Travessia.tutorial_avisos.has("foi_visto"):
		return
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if zumbi.get("_estado") == 1 and (zumbi as Node2D).global_position.distance_to(_jogador.global_position) < 500.0:
			_radio_uma_vez("foi_visto", Falas.RADIO_FOI_VISTO)
			return

# --- dia 1: o favor e a volta ------------------------------------------------

func _comecar_o_favor() -> void:
	_mostrar_objetivo("Buscar %s no Restaurante" % Falas.ITEM_DO_FAVOR, _p(PORTA_DO_RESTAURANTE))
	_por_o_item_no_restaurante()
	_radio_uma_vez("correr", Falas.RADIO_CORRER)

## O item vai para o movel do Restaurante mais perto da porta - e um vasculho
## como qualquer outro, e e assim que o tutorial ensina a vasculhar.
func _por_o_item_no_restaurante() -> void:
	var restaurante := Rect2()
	for c in Mapa.mundo()["construcoes"]:
		if c.get("nome", "") == "Restaurante":
			restaurante = c["rect"]
	var porta := _p(PORTA_DO_RESTAURANTE)
	var melhor: Node2D = null
	for filho in _cenario.get_children():
		if filho is Area2D and "achados" in filho and restaurante.has_point((filho as Node2D).position):
			if melhor == null or (filho as Node2D).position.distance_to(porta) < melhor.position.distance_to(porta):
				melhor = filho
	if melhor == null:
		push_warning("tutorial: nenhum movel no Restaurante para o item do favor")
		return
	_movel_do_favor = melhor
	melhor.receber(Falas.ITEM_DO_FAVOR)
	melhor.vasculhado.connect(_ao_vasculhar_o_favor)
	_alvo = melhor.global_position

func _ao_vasculhar_o_favor(_rotulo: String, achados: Array[String]) -> void:
	if not Falas.ITEM_DO_FAVOR in achados:
		return
	achados.erase(Falas.ITEM_DO_FAVOR)
	Travessia.tutorial = "voltar_ao_portao"
	_radio_uma_vez("pegou", Falas.RADIO_PEGOU)
	_voltar_ao_portao()

func _voltar_ao_portao() -> void:
	_mostrar_objetivo("Levar %s ao portão do Antônio" % Falas.ITEM_DO_FAVOR, _p(CONVERSA_NO_PORTAO))

## No portao com o item: a entrega e a 9mm.
func _entregar() -> void:
	if _no_roteiro:
		return
	_no_roteiro = true
	_jogador.no_roteiro = true
	_jogador.direcao_do_roteiro = Vector2.ZERO
	_jogador.olhar_para(Vector2.DOWN)
	_antonio.olhar_para(_jogador.global_position)
	await _conversa(Falas.PORTAO_VOLTA)
	_dar_a_9mm()
	_jogador.no_roteiro = false
	_no_roteiro = false
	Travessia.tutorial = "ir_para_casa"
	_ir_para_casa()
	_radio(Falas.RADIO_IR_PARA_CASA)

## A recompensa: a Beretta 9mm na mao, com um pente.
func _dar_a_9mm() -> void:
	Travessia.armado = true
	var arma := _jogador.get_node_or_null("Arma")
	if arma != null:
		arma.trocar(Travessia.ARMA_DE_COMECO)
	Travessia.balas[Travessia.CALIBRE_DE_COMECO] = maxi(
		Travessia.balas.get(Travessia.CALIBRE_DE_COMECO, 0), Travessia.BALAS_DE_COMECO)
	Som.tocar("armas/engatilhando_pistola", 1.0, 1)

func _ir_para_casa() -> void:
	_mostrar_objetivo("Voltar para casa antes de escurecer — segure E na porta",
		Mapa.onde_fica_a_porta_de_casa())

# --- dia 2 -------------------------------------------------------------------

func _dia_2() -> void:
	_mostrar_objetivo("Explore o bairro — mire com o mouse e atire num zumbi")
	_radio_uma_vez("dia_2", Falas.DIA_2_MANHA)

func _ao_morrer_um_zumbi(_zumbi: Node) -> void:
	if Travessia.tutorial != "dia_2":
		return
	Travessia.tutorial = "fim"
	_radio_uma_vez("primeiro_zumbi", Falas.DIA_2_PRIMEIRO_ZUMBI)
	_mostrar_objetivo("Tutorial concluído")
	await get_tree().create_timer(FIM_NA_TELA).timeout
	_mostrar_objetivo("")
