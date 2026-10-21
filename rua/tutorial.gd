extends Node
## O tutorial (21/10/2026, para a entrega do Joao): o roteiro de
## design/narrativa.md virando jogo, em dois dias, dentro do cerco da regiao
## rosa. **As falas nao moram aqui** - estao em rua/falas_do_tutorial.gd, com o
## texto do Joao; aqui e so quando cada uma toca.
##
## Dia 1:
##
##  1. **abertura** - a cena, na arte do jogo e sem o jogador no controle: ele
##     anda devagar e apreensivo pela rua de cima, parando para olhar em volta;
##     da de cara com um zumbi, que o ataca, e o tiro do Antonio, do quintal
##     dele, o mata; ele vai ao portao, e a conversa da a missao e o radio, que
##     o Antonio joga por cima do muro;
##  2. **favor** - buscar o item na Cover Pizzaria (o Restaurante do desenho,
##     pizzaria desde 21/10/2026). No caminho o radio da as aulas, cada uma
##     quando o caminho a pede: como o zumbi ve (o cone), pegar pedra do chao,
##     o barulho dos passos (rua/jogador.gd), agachar atras de cobertura baixa
##     (rua/camadas.gd), arremessar pedra ou garrafa para tirar o zumbi parado
##     na porta da pizzaria (rua/mao.gd), e vasculhar; o item esta num movel
##     da pizzaria;
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
const DetalhesDaRua := preload("res://rua/detalhes_da_rua.gd")

const RETRATO_DO_ANTONIO := preload("res://rua/arte/antonio/retrato.png")
const RETRATO_DO_JOGADOR := preload("res://rua/arte/jogador/retrato.png")

## Os lugares do roteiro, em px do PNG do desenho (como os ROTULOS do mapa).
## O jogador comeca a cena na rua de cima, a oeste da casa dele, e anda para
## leste, para a casa do Antonio; o Antonio fica no quintal dele, que olha
## para essa rua.
const INICIO := Vector2(1156.0, 619.0)
## A caminhada apreensiva (Joao, 21/10/2026: "vai caminhar devagar pelas ruas
## apreensivo e vai dar de cara com um zumbi"): cada passo e um ponto e, la,
## os olhares em volta - [para onde, quantos segundos].
const CAMINHADA := [
	{ "ponto": Vector2(1163.0, 618.6), "olhares": [[Vector2.UP, 0.9], [Vector2.DOWN, 0.7]] },
	{ "ponto": Vector2(1170.0, 620.4), "olhares": [[Vector2.LEFT, 0.8]] },
	{ "ponto": Vector2(1177.0, 619.4), "olhares": [[Vector2(1.0, -1.0), 0.5]] },
	{ "ponto": Vector2(1183.0, 619.8) },
]
## Onde o zumbi aparece, em relacao ao jogador: na frente dele (a leste), na
## rua, perto o bastante para ja o ver.
const ZUMBI_NA_FRENTE := Vector2(230.0, -8.0)
## O passo para tras quando da de cara com ele.
const VELOCIDADE_DO_RECUO := 30.0
const TEMPO_DO_RADIO_NO_AR := 0.8
const ONDE_ESTA_O_ANTONIO := Vector2(1205.2, 634.2)
## O ponto livre da calcada, 74 px de mundo ao norte da linha do portao, onde
## o boneco aparece inteiro (marca "conversa_portao_antonio" do desenho).
const CONVERSA_NO_PORTAO := Vector2(1211.25, 627.4)
## O beco entre a sua casa e a do Antonio: onde o radio ensina a agachar.
const BECO := Vector2(1197.0, 645.0)
const PORTA_DA_PIZZARIA := Vector2(1187.5, 737.4)
const NOME_DA_PIZZARIA := "Cover Pizzaria"

## A camera da cena, mais aberta que a do jogo, para o Antonio caber na tela
## junto com o jogador. Inteira, como a do jogo (ver Jogador.ZOOM_DA_CAMERA).
const ZOOM_DA_CENA := 1.0
## Andar apreensivo: devagar.
const VELOCIDADE_SEM_RUMO := 36.0
## Quanto perto do ponto conta como chegou (px de mundo).
const PERTO := 60.0
const PERTO_DO_BECO := 140.0
const PERTO_DA_PIZZARIA := 360.0
## Quanto tempo depois do favor o radio ensina a agachar, se ele nao passou
## pelo beco.
const AGACHAR_DEPOIS_DE := 40.0
## Quando o radio explica como eles veem, depois do portao.
const COMO_VEEM_DEPOIS_DE := 9.0
## Quanto perto de uma pedra no chao o radio manda pegar, de um zumbi ele
## fala do barulho, e da pizzaria ele ensina a arremessar.
const PERTO_DAS_PEDRAS := 200.0
const PERTO_DO_ZUMBI := 320.0
const PERTO_PARA_ARREMESSAR := 560.0
const AVISO_NA_TELA := 3.0
## A altura de cada tarja da cena, em fracao da tela.
const ALTURA_DA_TARJA := 0.1
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
## O zumbi parado na porta da pizzaria, que a aula do arremesso tira de la.
var _zumbi_da_porta: Node2D
var _aviso: Label
var _tempo_do_aviso := 0.0
## As tarjas pretas da cena (em cima e embaixo da tela).
var _tarjas: Array[ColorRect] = []

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
	if _tempo_do_aviso > 0.0:
		_tempo_do_aviso -= delta
		if _tempo_do_aviso <= 0.0:
			_aviso.text = ""
	match Travessia.tutorial:
		"favor":
			# As aulas do radio no caminho ate a pizzaria, cada uma quando o
			# caminho a pede (Joao, 21/10/2026).
			_tempo_no_favor += delta
			if _tempo_no_favor > COMO_VEEM_DEPOIS_DE:
				_radio_uma_vez("como_veem", Falas.RADIO_COMO_VEEM)
			for pedras in DetalhesDaRua.PEDRAS_NO_CHAO:
				if onde.distance_to(_p(pedras)) < PERTO_DAS_PEDRAS:
					_radio_uma_vez("pedras", Falas.RADIO_PEDRAS)
			if _zumbi_perto(PERTO_DO_ZUMBI) and not _jogador.agachado:
				_radio_uma_vez("barulho", Falas.RADIO_BARULHO)
			if onde.distance_to(_p(BECO)) < PERTO_DO_BECO or _tempo_no_favor > AGACHAR_DEPOIS_DE:
				_radio_uma_vez("agachar", Falas.RADIO_AGACHAR)
			var porta := _p(PORTA_DA_PIZZARIA)
			if onde.distance_to(porta) < PERTO_PARA_ARREMESSAR and is_instance_valid(_zumbi_da_porta) \
					and not _zumbi_da_porta.get("morto"):
				_radio_uma_vez("arremesso", Falas.RADIO_ARREMESSO)
			if int(Travessia.arremessaveis.get("garrafa", 0)) > 0:
				_radio_uma_vez("garrafa", Falas.RADIO_GARRAFA)
			if onde.distance_to(porta) < PERTO_DA_PIZZARIA:
				_radio_uma_vez("pizzaria", Falas.RADIO_PIZZARIA)
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
	_aviso = _objetivo.duplicate() as Label
	_aviso.offset_top = 66.0
	_aviso.add_theme_font_size_override("font_size", 14)
	_aviso.add_theme_color_override("font_color", Color("d8e0c8"))
	_camada.add_child(_aviso)
	_seta = Control.new()
	_seta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seta.draw.connect(_desenhar_a_seta)
	_camada.add_child(_seta)
	for de_cima in [true, false]:
		var tarja := ColorRect.new()
		tarja.color = Color.BLACK
		tarja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tarja.anchor_right = 1.0
		tarja.anchor_top = 0.0 if de_cima else 1.0
		tarja.anchor_bottom = 0.0 if de_cima else 1.0
		tarja.set_meta("de_cima", de_cima)
		_camada.add_child(tarja)
		_tarjas.append(tarja)

## As tarjas de cinema entram (ou saem) na cena de abertura (21/10/2026,
## Joao: "Mao e tarjas"), e o texto da HUD sai junto - quem esta vendo uma
## cena nao precisa de relogio nem de municao. O escurecer da noite fica.
func _cena(entrando: bool, segundos := 0.6) -> void:
	var hud := get_parent().get_node_or_null("Hud")
	if hud != null:
		for filho in hud.get_children():
			if filho is Label:
				create_tween().tween_property(filho, "modulate:a", 0.0 if entrando else 1.0, segundos)
	for tarja in _tarjas:
		var de_cima: bool = tarja.get_meta("de_cima")
		var ate := ALTURA_DA_TARJA if entrando else 0.0
		create_tween().tween_property(tarja, "anchor_bottom" if de_cima else "anchor_top",
			ate if de_cima else 1.0 - ate, segundos).set_trans(Tween.TRANS_SINE)

## Um aviso curto embaixo do objetivo ("Voce recebeu: radio"), que some
## sozinho.
func _avisar(texto: String) -> void:
	_aviso.text = texto
	_tempo_do_aviso = AVISO_NA_TELA

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
	_antonio.olhar_para(_p(INICIO))

# --- dia 1: a abertura -------------------------------------------------------

func _abertura() -> void:
	_no_roteiro = true
	_jogador.no_roteiro = true
	var camera := _jogador.get_node("Camera") as Camera2D
	camera.zoom = Vector2.ONE * ZOOM_DA_CENA
	camera.offset = Vector2.ZERO
	_jogador.global_position = _p(INICIO)
	_mostrar_objetivo("")
	_cena(true, 0.0)
	await _conversa(Falas.ABERTURA)

	# A caminhada apreensiva: devagar, parando para olhar em volta.
	for passo in CAMINHADA:
		await _andar_ate(_p(passo["ponto"]), VELOCIDADE_SEM_RUMO)
		for olhar in passo.get("olhares", []):
			await _parar_olhando(olhar[0], olhar[1])

	# De cara com o zumbi: ele sai na frente, ja vendo o jogador, que para,
	# olha e recua.
	var zumbi: Node2D = _cenario._criar_zumbi(_jogador.global_position + ZUMBI_NA_FRENTE)
	zumbi._olhando = (_jogador.global_position - zumbi.global_position).normalized()
	_jogador.olhar_para(zumbi.global_position - _jogador.global_position)
	# A camera abre para pegar o zumbi, o jogador e o Antonio.
	var no_meio := (_antonio.global_position - _jogador.global_position) / 2.0
	create_tween().tween_property(camera, "offset", no_meio, 0.9).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.6).timeout
	var pegou := [false]
	var ao_ser_pego := func() -> void: pegou[0] = true
	_jogador.atingido.connect(ao_ser_pego)
	_jogador.velocidade_do_roteiro = VELOCIDADE_DO_RECUO
	var recuo := _jogador.global_position - Vector2(ZUMBI_NA_FRENTE.x, 0.0).normalized() * 40.0
	var tempo := 0.0
	while not pegou[0] and tempo < 7.0:
		var falta := recuo - _jogador.global_position
		_jogador.direcao_do_roteiro = falta.normalized() if falta.length() > 4.0 else Vector2.ZERO
		if is_instance_valid(zumbi):
			_jogador.olhar_para(zumbi.global_position - _jogador.global_position)
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
		# Se o zumbi encalhou, ele chega de qualquer jeito: a cena nao espera.
		if tempo > 4.0 and is_instance_valid(zumbi):
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
	create_tween().tween_property(camera, "offset", Vector2(0.0, (_antonio.global_position.y - _jogador.global_position.y) / 2.0), 0.6)
	await _conversa(Falas.PORTAO)
	# A missao e o radio: ele joga o radio por cima do muro.
	await _jogar_o_radio()

	_cena(false)
	camera.zoom = Vector2.ONE * Jogador.ZOOM_DA_CAMERA
	camera.offset = Vector2.ZERO
	_jogador.no_roteiro = false
	_no_roteiro = false
	Travessia.tutorial = "favor"
	_comecar_o_favor()

## O radio voando do Antonio para a mao do jogador, e o aviso de que chegou.
func _jogar_o_radio() -> void:
	var radio := Node2D.new()
	radio.z_index = 2
	radio.draw.connect(func() -> void:
		radio.draw_rect(Rect2(-4, -6, 8, 12), Color("2a2c2e"))
		radio.draw_rect(Rect2(-3, -4, 6, 4), Color("6a8a6a"))
		radio.draw_line(Vector2(2, -6), Vector2(4, -13), Color("3a3a3a"), 1.0)
		radio.draw_rect(Rect2(-4, -6, 8, 12), Color(0.07, 0.06, 0.05, 0.9), false, 1.0))
	_cenario.add_child(radio)
	var de := _antonio.global_position + Vector2(0.0, -24.0)
	var ate := _jogador.global_position + Vector2(0.0, -14.0)
	var t := 0.0
	while t < TEMPO_DO_RADIO_NO_AR:
		t += get_process_delta_time()
		var f := minf(t / TEMPO_DO_RADIO_NO_AR, 1.0)
		radio.global_position = de.lerp(ate, f) - Vector2(0.0, 4.0 * 70.0 * f * (1.0 - f))
		radio.rotation = f * TAU
		await get_tree().process_frame
	radio.queue_free()
	_avisar("Você recebeu: rádio")

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
## numa caixa, com o retrato de quem fala. Espera o jogo voltar
## (a caixa so solta quando o E e solto).
func _conversa(falas: Array) -> void:
	var i := 0
	while i < falas.size():
		var quem: String = falas[i][0]
		var linhas := PackedStringArray()
		while i < falas.size() and falas[i][0] == quem:
			linhas.append(falas[i][1])
			i += 1
		var retrato: Texture2D = RETRATO_DO_ANTONIO if quem == Falas.QUEM_E_O_ANTONIO else RETRATO_DO_JOGADOR
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
	_mostrar_objetivo("Buscar %s na Cover Pizzaria" % Falas.ITEM_DO_FAVOR, _p(PORTA_DA_PIZZARIA))
	_por_o_item_na_pizzaria()
	_por_o_zumbi_na_porta()
	var mao := _jogador.get_node_or_null("Mao")
	if mao != null and not mao.arremessou.is_connected(_ao_arremessar):
		mao.arremessou.connect(_ao_arremessar)
	_radio_uma_vez("correr", Falas.RADIO_CORRER)

## O zumbi parado na porta da pizzaria, para a aula do arremesso: o que ja
## estiver ali, ou um novo.
func _por_o_zumbi_na_porta() -> void:
	var porta := _p(PORTA_DA_PIZZARIA)
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if not zumbi.get("morto") and (zumbi as Node2D).global_position.distance_to(porta) < 260.0:
			_zumbi_da_porta = zumbi
			return
	_zumbi_da_porta = _cenario._criar_zumbi(porta + Vector2(60.0, -90.0))

## O primeiro arremesso durante o favor: o radio confirma.
func _ao_arremessar(_qual: String, _onde: Vector2) -> void:
	if Travessia.tutorial != "favor":
		return
	await get_tree().create_timer(1.5).timeout
	_radio_uma_vez("arremesso_bom", Falas.RADIO_ARREMESSO_BOM)

## Um zumbi vivo a menos de `raio` do jogador.
func _zumbi_perto(raio: float) -> bool:
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if not zumbi.get("morto") and (zumbi as Node2D).global_position.distance_to(_jogador.global_position) < raio:
			return true
	return false

## O item vai para o movel da pizzaria mais perto da porta - e um vasculho
## como qualquer outro, e e assim que o tutorial ensina a vasculhar.
func _por_o_item_na_pizzaria() -> void:
	var pizzaria := Rect2()
	for c in Mapa.mundo()["construcoes"]:
		if c.get("nome", "") == NOME_DA_PIZZARIA:
			pizzaria = c["rect"]
	var porta := _p(PORTA_DA_PIZZARIA)
	var melhor: Node2D = null
	for filho in _cenario.get_children():
		if filho is Area2D and "achados" in filho and pizzaria.has_point((filho as Node2D).position):
			if melhor == null or (filho as Node2D).position.distance_to(porta) < melhor.position.distance_to(porta):
				melhor = filho
	if melhor == null:
		push_warning("tutorial: nenhum movel na pizzaria para o item do favor")
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
	Travessia.na_mao = "arma"
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
