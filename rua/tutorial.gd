extends Node
## O tutorial (21/10/2026, para a entrega do Joao): o roteiro de
## design/narrativa.md virando jogo, no dia 1, dentro do cerco da regiao
## rosa. **As falas nao moram aqui** - estao em rua/falas_do_tutorial.gd, com o
## texto do Joao; aqui e so quando cada uma toca.
##
## Dia 1:
##
##  1. **abertura** - a cena, na arte do jogo e sem o jogador no controle: ele
##     anda devagar e apreensivo pela calcada, um zumbi sai correndo do terreno
##     ao lado, ele foge para a rua e o Antonio abre o portao e o mata; depois,
##     a conversa do roteiro do Joao (o susto, o portao fechando, o radio
##     jogado por cima do muro, o favor em troca de uma arma);
##  2. **favor** - buscar "uma... uma coisa" num lugar que o Antonio nao diz:
##     a Cover Pizzaria (o Restaurante do desenho), e a coisa e pepperoni. A
##     conversa passa para o radio (a apresentacao) e, no caminho, cada aula
##     vem de um obstaculo de zumbis de posto (OBSTACULOS): como o zumbi ve (o
##     cone), o barulho dos passos e agachar (rua/jogador.gd), pegar pedra,
##     arremessar para tirar o zumbi da porta (rua/mao.gd) e cobertura baixa
##     (rua/camadas.gd). Entrando na pizzaria, a piada do pepperoni e o
##     vasculho; o item esta num movel de la;
##  3. **voltar_ao_portao** - com o item, de volta ao portao: a entrega, a
##     **9mm** (o dia 1 comeca desarmado - Travessia.armado) e o fim da beta:
##     o Antonio agradece por jogar e diz que por enquanto e isso (Joao,
##     21/10/2026: "depois que o personagem terminar a primeira missao ... faz o
##     antonio agradecer ele por jogar a beta do jogo e que e isso por
##     enquanto, mas ele pode se sentir livre pra jogar e explorar"). Dai o
##     tutorial acaba (**fim**) e o jogo segue livre. Ate entao vinham o
##     "voltar para casa antes de escurecer" e um dia 2 de atirar num zumbi.
##
## A etapa mora em Travessia.tutorial e atravessa os dias: se o dia 1 acabar
## no meio (caiu, amanheceu na rua), o dia seguinte retoma de onde parou. So a
## partida que comeca pelo titulo tem tutorial (Travessia.comecar_partida).

const Mapa := preload("res://rua/mapa.gd")
const Falas := preload("res://rua/falas_do_tutorial.gd")
const Antonio := preload("res://rua/antonio.gd")
const Jogador := preload("res://rua/jogador.gd")

const RETRATO_DO_ANTONIO := preload("res://rua/arte/antonio/retrato.png")
const RETRATO_DO_JOGADOR := preload("res://rua/arte/jogador/retrato.png")

## Os lugares do roteiro, em px do PNG do desenho (como os ROTULOS do mapa).
##
## **A cena de abertura de 21/10/2026, noite** - o Joao riscou por cima da tela
## do jogo: o jogador "esteja caminhando onde coloquei a linha azul" (a calcada
## sul da rua de cima, na frente da casa dele, para o leste), "o zumbi vai vir
## correndo da direcao vermelha" (do terreno entre a casa dele e a do Antonio),
## "o personagem vai correr pra rua na frente da casa do Antonio e ele vai abrir
## a porta e disparar pra salvar o personagem". A porta e o portao de chapa do
## muro da frente do Antonio: ele corre para tras do muro e o Antonio atira do
## vao. Ate entao o zumbi saia na frente dele na rua e o Antonio atirava do
## quintal.
const INICIO := Vector2(1177.0, 625.0)
## A caminhada apreensiva (Joao, 21/10/2026: "vai caminhar devagar pelas ruas
## apreensivo"): cada passo e um ponto e, la, os olhares em volta - [para
## onde, quantos segundos]. Pela calcada, olhando a propria casa e a rua; o
## ultimo passo ja passou do vao de onde o zumbi sai.
const CAMINHADA := [
	{ "ponto": Vector2(1181.5, 625.0), "olhares": [[Vector2.DOWN, 0.9], [Vector2.LEFT, 0.7]] },
	{ "ponto": Vector2(1187.0, 625.1), "olhares": [[Vector2.UP, 0.8]] },
	{ "ponto": Vector2(1193.0, 625.0), "olhares": [[Vector2(1.0, -1.0), 0.5]] },
	{ "ponto": Vector2(1199.0, 625.0) },
]
## De onde o zumbi sai correndo: o terreno no vao entre a cerca da casa dele
## e o muro do Antonio (a seta vermelha).
const SAIDA_DO_ZUMBI := Vector2(1196.5, 637.0)
## Quanto o jogador fica olhando o zumbi vir antes de correr (s).
const SUSTO := 0.6
## A fuga: da calcada para a rua, na frente do portao do Antonio.
const FUGA := [Vector2(1204.5, 622.0), Vector2(1209.0, 620.6)]
## O portao de chapa do muro da frente do Antonio (rua/mapa.gd, BARREIRAS), e
## onde ele aparece quando o portao corre: no vao, do lado de dentro.
const PORTAO_DO_ANTONIO := Vector2(1211.3, 630.5)
const ANTONIO_NO_VAO := Vector2(1211.3, 631.2)
const SEGUNDOS_DO_PORTAO := 0.7
## Depois do tiro ele chega na calcada, na frente do portao aberto - era para
## la que corria -, e da de cara com a arma do Antonio ("meu deus! por favor
## nao me mate"). Da rua, onde a fuga acaba, os dois nao cabem na tela acima
## da caixa de fala, no zoom do jogo.
const DEPOIS_DO_TIRO := Vector2(1210.8, 625.2)
## Quanto a camera desce numa conversa com os dois na tela (px de mundo): poe
## o par no meio do vao entre a tarja de cima e a caixa de fala, que e alta.
const DESCE_NA_CONVERSA := 21.0
## O tiro sai quando o zumbi chega a PERTO_DO_TIRO px de mundo do jogador - ou,
## se ele encalhar, depois de PERSEGUICAO_MAXIMA segundos assim mesmo.
const PERTO_DO_TIRO := 110.0
const PERSEGUICAO_MAXIMA := 6.0
const TEMPO_DO_RADIO_NO_AR := 0.8
const ONDE_ESTA_O_ANTONIO := Vector2(1205.2, 634.2)
## O ponto livre da calcada, 74 px de mundo ao norte da linha do portao, onde
## o boneco aparece inteiro (marca "conversa_portao_antonio" do desenho).
const CONVERSA_NO_PORTAO := Vector2(1211.25, 627.4)
const PORTA_DA_PIZZARIA := Vector2(1187.5, 737.4)
const NOME_DA_PIZZARIA := "Cover Pizzaria"
## Onde o item do favor vai, se a pizzaria tiver (o rotulo do movel); entre
## eles, o mais perto da porta.
const MOVEIS_DO_ITEM := ["Geladeira", "Freezer"]

## Os obstaculos do caminho (Joao, 21/10/2026: o jogador aprende as mecanicas
## "todas elas com o objetivo de passar por alguma parte, na maioria delas por
## obstrucao dos zumbis em algum lugar, e o Antonio deve falar explicitamente:
## 'ah, tem zumbis ali bloqueando o caminho, faz o seguinte...'"). Cada um e um
## ou mais zumbis de posto (rua/zumbi.gd, `guardar`: parados, olhando para um
## lado, ate te verem ou ouvirem) no caminho a pe do portao a pizzaria, que
## desce pela rua da rotatoria, corta o gramado ao longo da cerca e atravessa
## a avenida do lado do onibus. A aula toca quando o jogador chega a
## AVISO_DO_OBSTACULO do primeiro zumbi do obstaculo, se ele ainda esta de
## posto. Em px do PNG; o segundo vetor de cada zumbi e para onde ele olha.
## Todos fora dos 1300 px da porta de casa (Mapa.SEM_ZUMBI_PERTO_DE_CASA) e a
## mais de ALCANCE_DO_CHAMADO um do outro, para um nao chamar o outro.
const OBSTACULOS := [
	# Como eles veem: no fim da cerca, olhando para quem desce o gramado - a
	# luz dele fecha o caminho, e a volta e por fora dela.
	{ "aula": "como_veem", "zumbis": [[Vector2(1215.0, 695.0), Vector2.UP]] },
	# O barulho: dois de costas para o onibus (Joao, 21/10/2026), olhando para
	# o meio da avenida. Andando no vao entre eles e o onibus, passa colado
	# neles; agachado, nao. Vindo do fim da cerca, chega por tras deles.
	{ "aula": "barulho", "zumbis": [
		[Vector2(1203.5, 710.0), Vector2.RIGHT], [Vector2(1203.5, 717.5), Vector2.RIGHT]] },
]
## O zumbi de posto na porta da pizzaria, olhando para a avenida: o obstaculo
## da pedra e do arremesso. Em px do PNG.
const ZUMBI_DA_PORTA := Vector2(1190.0, 733.6)
## As aulas do caminho, na ordem: uma de cada vez (ver `_seguir_as_aulas`).
## "porta" avisa do zumbi da porta e da cobertura, "pedras" manda pegar,
## "arremesso" manda jogar, "arremesso_bom" e o "isso!" quando ele sai.
const AULAS := ["como_veem", "barulho", "porta", "pedras", "arremesso", "arremesso_bom"]
const FALAS_DAS_AULAS := {
	"como_veem": Falas.RADIO_COMO_VEEM,
	"barulho": Falas.RADIO_BARULHO,
	"porta": Falas.RADIO_PORTA,
	"pedras": Falas.RADIO_PEDRAS,
	"arremesso": Falas.RADIO_ARREMESSO,
	"arremesso_bom": Falas.RADIO_ARREMESSO_BOM,
}
## Em volta de cada zumbi de posto, os pontos de zumbi do mapa nao povoam no
## favor (rua/cenario.gd, `ceder_pontos_perto`): o obstaculo e so ele.
const CEDIDO_EM_VOLTA := 480.0
## A quantos px de mundo do obstaculo a aula dele comeca. O zumbi enxerga a
## 260: sobra o tempo de ler o "para ai!" antes de entrar na luz dele.
const AVISO_DO_OBSTACULO := 520.0
## Quantos px ao sul do zumbi mais ao sul do obstaculo o jogador ja passou
## dele (a aula acaba).
const PASSOU_DO_OBSTACULO := 60.0
## Quanto depois do arremesso se confere se o zumbi da porta saiu (s).
const ESPERA_DO_ARREMESSO := 2.0

## A camera da cena: a mesma visao do jogo desde 21/10/2026 (Joao: "o zoom
## ta muito grande, deixa na mesma visao do jogo mais ou menos" - era 1, a
## metade). Inteira, como a do jogo (ver Jogador.ZOOM_DA_CAMERA): zoom
## quebrado faz o pixel do boneco cintilar. Com a vista mais fechada, a camera
## segue o que importa na hora (`_no_quadro`), e nao so o jogador.
const ZOOM_DA_CENA := 2.0
## Quao depressa a camera da cena vai para o meio do que importa (por segundo).
const RAPIDEZ_DO_QUADRO := 4.0
## Andar apreensivo: devagar.
const VELOCIDADE_SEM_RUMO := 36.0
## Quanto perto do ponto conta como chegou (px de mundo).
const PERTO := 60.0
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
var _movel_do_favor: Node
## A planta da Cover Pizzaria (mundo): entrar nela e "chegar no lugar".
var _pizzaria := Rect2()
## Os zumbis de cada obstaculo do caminho, na ordem de OBSTACULOS.
var _obstaculos: Array = []
## O zumbi de posto na porta da pizzaria, que a aula do arremesso tira de la.
var _zumbi_da_porta: Node2D
var _aviso: Label
var _tempo_do_aviso := 0.0
## As tarjas pretas da cena (em cima e embaixo da tela).
var _tarjas: Array[ColorRect] = []
## O que a camera da cena mantem na tela: nos (o jogador, o zumbi, o
## Antonio) e pontos do mundo; ela vai para o meio deles. Vazio, ela fica
## onde o roteiro a pos.
var _no_quadro: Array = []
## O portao de chapa do Antonio, depois de achado (_portao_do_antonio).
var _portao: Node2D

func _ready() -> void:
	if Travessia.tutorial == "" or Travessia.tutorial == "fim":
		# Sem o _process do quadro em que ainda existe: a tela dele nem foi
		# montada.
		set_process(false)
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

	match Travessia.tutorial:
		"abertura":
			await _abertura()
		"favor":
			_comecar_o_favor()
		"voltar_ao_portao":
			_voltar_ao_portao()

func _p(ponto_do_png: Vector2) -> Vector2:
	return Mapa.ponto_do_png(ponto_do_png)

func _process(delta: float) -> void:
	if _jogador != null and _no_roteiro:
		_enquadrar(delta)
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
			_seguir_as_aulas(onde)
			if int(Travessia.arremessaveis.get("garrafa", 0)) > 0:
				_radio_uma_vez("garrafa", Falas.RADIO_GARRAFA)
			if _pizzaria.has_point(onde) and not Travessia.tutorial_avisos.has("chegada"):
				_chegar_na_pizzaria()
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

## Para onde o objetivo aponta agora (mundo), ou NAN sem alvo: o mapa do M
## marca (rua/tela_do_mapa.gd).
func alvo_do_objetivo() -> Vector2:
	return _alvo

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
	_jogador.olhar_para(Vector2.RIGHT)
	# O Antonio esta atras do portao fechado: so aparece quando o portao corre.
	_antonio.global_position = _p(ANTONIO_NO_VAO)
	_antonio.visible = false
	_mostrar_objetivo("")
	_cena(true, 0.0)
	await _conversa(Falas.ABERTURA)

	# A caminhada apreensiva pela calcada: devagar, parando para olhar em volta.
	for passo in CAMINHADA:
		await _andar_ate(_p(passo["ponto"]), VELOCIDADE_SEM_RUMO)
		for olhar in passo.get("olhares", []):
			await _parar_olhando(olhar[0], olhar[1])

	# O zumbi sai correndo do terreno, atras dele. A memoria do toque
	# (rua/zumbi.gd) faz ele perseguir de longe, sem ter precisado ver.
	var zumbi: Node2D = _cenario._criar_zumbi(_p(SAIDA_DO_ZUMBI))
	zumbi._memoria_do_toque = PERSEGUICAO_MAXIMA + 2.0
	# A camera pega os dois.
	_no_quadro = [_jogador, zumbi]
	await get_tree().create_timer(0.35).timeout
	_jogador.olhar_para(zumbi.global_position - _jogador.global_position)
	await get_tree().create_timer(SUSTO).timeout

	# A fuga para a rua, e o portao do Antonio correndo enquanto isso; a
	# camera pega o portao tambem.
	_no_quadro = [_jogador, zumbi, _p(PORTAO_DO_ANTONIO)]
	_correr_o_portao(true)
	# Ele aparece no vao ja erguendo a arma para o zumbi.
	_antonio.mirar(zumbi.global_position)
	for ponto in FUGA:
		await _andar_ate(_p(ponto), Jogador.VELOCIDADE_CORRENDO, 3.0)
	_jogador.direcao_do_roteiro = Vector2.ZERO

	# O tiro do Antonio, do vao: quando o zumbi chega perto (ou encalhou).
	var tempo := 0.0
	while is_instance_valid(zumbi) and tempo < PERSEGUICAO_MAXIMA \
			and zumbi.global_position.distance_to(_jogador.global_position) > PERTO_DO_TIRO:
		_jogador.olhar_para(zumbi.global_position - _jogador.global_position)
		_antonio.olhar_para(zumbi.global_position)
		await get_tree().physics_frame
		tempo += get_physics_process_delta_time()
	if is_instance_valid(zumbi):
		_antonio.atirar_em(zumbi.global_position)
		zumbi.levar_tiro(1000.0, (zumbi.global_position - _antonio.global_position).normalized())
	# Depois do tiro, com o portao ainda aberto e a arma virada para ele, o
	# susto (o roteiro do Joao, 21/10/2026: "meu deus! por favor nao me
	# mate" / "te matar? eu acabei de te salvar" / *fecha o portao*). Dai o
	# Antonio fecha o portao (Joao, 21/10: "faz o antonio fechar o portao
	# depois do tiro") e o resto e com ele fechado.
	_no_quadro = [_jogador, _antonio]
	await get_tree().create_timer(0.6).timeout
	await _andar_ate(_p(DEPOIS_DO_TIRO), Jogador.VELOCIDADE)
	_jogador.olhar_para(_antonio.global_position - _jogador.global_position)
	_antonio.olhar_para(_jogador.global_position)
	_no_quadro.clear()
	create_tween().tween_property(camera, "offset", _meio_da_conversa(), 0.4)
	await _conversa(Falas.O_TIRO)
	await _correr_o_portao(false)
	_antonio.baixar_a_arma()
	await _conversa(Falas.PORTAO_FECHADO)

	# "Nao, espera!": ele corre ate o portao fechado.
	_no_quadro.clear()
	await _andar_ate(_p(CONVERSA_NO_PORTAO), Jogador.VELOCIDADE_CORRENDO)
	_jogador.olhar_para(Vector2.DOWN)
	_antonio.olhar_para(_jogador.global_position)
	create_tween().tween_property(camera, "offset", _meio_da_conversa(), 0.6)
	await _conversa(Falas.PORTAO)
	# "Quer saber? Pega isso.": o radio por cima do muro, e o favor.
	await _jogar_o_radio()
	await _conversa(Falas.PORTAO_DEPOIS_DO_RADIO)

	_cena(false)
	camera.zoom = Vector2.ONE * Jogador.ZOOM_DA_CAMERA
	camera.offset = Vector2.ZERO
	_jogador.no_roteiro = false
	_no_roteiro = false
	Travessia.tutorial = "favor"
	_comecar_o_favor()

## O deslocamento da camera (a partir do jogador) que poe ele e o Antonio no
## meio do vao entre a tarja de cima e a caixa de fala.
func _meio_da_conversa() -> Vector2:
	return (_antonio.global_position - _jogador.global_position) / 2.0 + Vector2(0.0, DESCE_NA_CONVERSA)

## A camera da cena vai, devagar, para o meio do que esta em `_no_quadro`.
func _enquadrar(delta: float) -> void:
	if _no_quadro.is_empty():
		return
	var soma := Vector2.ZERO
	var quantos := 0
	for coisa in _no_quadro:
		if coisa is Vector2:
			soma += coisa
			quantos += 1
		elif is_instance_valid(coisa):
			soma += (coisa as Node2D).global_position
			quantos += 1
	if quantos == 0:
		return
	var camera := _jogador.get_node("Camera") as Camera2D
	camera.offset = camera.offset.lerp(soma / quantos - _jogador.global_position, minf(1.0, delta * RAPIDEZ_DO_QUADRO))

## O portao de chapa do Antonio: a peca do cenario que o desenha
## (rua/barreira.gd), achada pelo lugar dele fechado - e guardada, porque
## aberto ele esta uma largura para o lado.
func _portao_do_antonio() -> Node2D:
	if is_instance_valid(_portao):
		return _portao
	var onde := _p(PORTAO_DO_ANTONIO)
	for filho in _cenario.get_children():
		if filho.get("tipo") == "portao_chapa" and (filho as Node2D).global_position.distance_to(onde) < 40.0:
			_portao = filho
			return _portao
	return null

## O portao corre para tras do muro do lado leste, que e mais largo que ele:
## a peca sobe meio px (o Y-sort a poe atras do muro) e anda a propria
## largura. Abrindo, o Antonio aparece no vao. So o desenho corre - a colisao
## e do muro inteiro, e ninguem entra na casa dele.
func _correr_o_portao(abrir: bool) -> void:
	var portao := _portao_do_antonio()
	if abrir:
		_antonio.visible = true
	if portao == null:
		return
	if not portao.has_meta("fechado"):
		portao.set_meta("fechado", portao.position)
	var fechado: Vector2 = portao.get_meta("fechado")
	var largura: float = (portao.get("b") - portao.get("a")).length()
	var aberto := fechado + Vector2(largura, -0.5)
	Som.tocar_em("porta", portao.global_position, 1600.0, 0.8 if abrir else 0.7)
	var passo := create_tween()
	passo.tween_property(portao, "position", aberto if abrir else fechado, SEGUNDOS_DO_PORTAO) \
		.set_trans(Tween.TRANS_SINE)
	await passo.finished

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
		var retrato := _retrato_de(quem)
		_caixa.calar_o_radio()
		while _caixa.ocupada():
			await get_tree().process_frame
		_caixa.falar(quem, linhas, retrato, Falas.VOZES.get(quem, ""))
		while _caixa.ocupada() or get_tree().paused:
			await get_tree().process_frame

## Uma fala pelo radio: como a conversa, uma caixa por bloco de linhas do
## mesmo personagem, com o retrato dele - desde o roteiro do Joao o Fabiano
## tambem fala pelo radio (a apresentacao, a chegada). Entram na fila da caixa
## e o jogo segue.
func _radio(falas: Array) -> void:
	var i := 0
	while i < falas.size():
		var quem: String = falas[i][0]
		var linhas := PackedStringArray()
		while i < falas.size() and falas[i][0] == quem:
			linhas.append(falas[i][1])
			i += 1
		_caixa.pelo_radio(quem, linhas, _retrato_de(quem), Falas.VOZES.get(quem, ""))

func _retrato_de(quem: String) -> Texture2D:
	return RETRATO_DO_ANTONIO if quem == Falas.QUEM_E_O_ANTONIO else RETRATO_DO_JOGADOR

## A fala de radio que so toca uma vez na partida.
func _radio_uma_vez(chave: String, falas: Array) -> void:
	if Travessia.tutorial_avisos.has(chave):
		return
	Travessia.tutorial_avisos[chave] = true
	_radio(falas)

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
	_por_o_item_na_pizzaria()
	_mostrar_objetivo_do_favor()
	_por_os_obstaculos()
	var mao := _jogador.get_node_or_null("Mao")
	if mao != null and not mao.arremessou.is_connected(_ao_arremessar):
		mao.arremessou.connect(_ao_arremessar)
	# "** comunicacao passa para o radio" (o roteiro): a apresentacao, e o
	# caminho.
	_radio_uma_vez("apresentacao", Falas.RADIO_APRESENTACAO)
	_radio_uma_vez("correr", Falas.RADIO_CORRER)

## O objetivo nao diz aonde nem o que antes da chegada: o Antonio so disse "um
## lugar" e "uma... uma coisa", e a piada da chegada e descobrir que e um
## restaurante. A seta aponta a pizzaria assim mesmo.
func _mostrar_objetivo_do_favor() -> void:
	if Travessia.tutorial_avisos.has("chegada"):
		_mostrar_objetivo("Achar o %s na %s" % [Falas.ITEM_DO_FAVOR, NOME_DA_PIZZARIA], _alvo_do_favor())
	else:
		_mostrar_objetivo("Buscar o que o Antônio pediu", _alvo_do_favor())

func _alvo_do_favor() -> Vector2:
	if is_instance_valid(_movel_do_favor):
		return (_movel_do_favor as Node2D).global_position
	return _p(PORTA_DA_PIZZARIA)

## Os zumbis de posto do caminho (OBSTACULOS) e o da porta da pizzaria. Nascem
## de novo a cada dia em que o favor (re)comeca: sao o caminho, nao o
## povoamento.
func _por_os_obstaculos() -> void:
	_obstaculos.clear()
	for obstaculo in OBSTACULOS:
		var zumbis: Array = []
		for z in obstaculo["zumbis"]:
			zumbis.append(_zumbi_de_posto(z[0], z[1]))
		_obstaculos.append(zumbis)
	_zumbi_da_porta = _zumbi_de_posto(ZUMBI_DA_PORTA, Vector2.UP)

func _zumbi_de_posto(onde_no_png: Vector2, olhando: Vector2) -> Node2D:
	_cenario.ceder_pontos_perto(_p(onde_no_png), CEDIDO_EM_VOLTA)
	var zumbi: Node2D = _cenario._criar_zumbi(_p(onde_no_png))
	zumbi.guardar(_p(onde_no_png), olhando)
	return zumbi

func _de_posto(zumbi: Node2D) -> bool:
	return is_instance_valid(zumbi) and not zumbi.get("morto") and zumbi.de_posto()

## As aulas do caminho, uma de cada vez e na ordem de AULAS (Joao, 21/10/2026:
## "o dialogo nao ta tendo um gatilho com as coisas que vao acontecendo muito
## bom, ele so sai falando, ele tem que ensinar o cara a pegar a pedra, e
## arremessar tambem, um de cada vez"). Ate entao cada obstaculo avisava a
## 640 px, os avisos se sobrepunham e o radio emendava aula com aula. Agora a
## aula seguinte so comeca quando a de antes acabou, o radio esta livre e o
## jogador esta onde ela e pedida (`_aula_comeca`); e acaba quando ele fez o
## que ela pede ou ja passou dela (`_aula_acaba`). A que acabou antes de
## comecar (ja tinha pedra, o zumbi largou o posto) passa calada.
func _seguir_as_aulas(onde: Vector2) -> void:
	for aula in AULAS:
		if Travessia.tutorial_avisos.has("feita:" + aula):
			continue
		if _aula_acaba(aula, onde):
			Travessia.tutorial_avisos["feita:" + aula] = true
			continue
		if not Travessia.tutorial_avisos.has(aula) and not _caixa.ocupada() and _aula_comeca(aula, onde):
			Travessia.tutorial_avisos[aula] = true
			_radio(FALAS_DAS_AULAS[aula])
		return

func _aula_comeca(aula: String, onde: Vector2) -> bool:
	match aula:
		"como_veem", "barulho":
			var primeiro: Node2D = _obstaculos[_obstaculo_da_aula(aula)][0]
			return is_instance_valid(primeiro) and onde.distance_to(primeiro.global_position) < AVISO_DO_OBSTACULO
		"porta":
			return onde.distance_to(_zumbi_da_porta.global_position) < AVISO_DO_OBSTACULO
	# Pedra, arremesso e o "isso!": logo depois da de antes.
	return true

func _aula_acaba(aula: String, onde: Vector2) -> bool:
	var porta_livre := not _de_posto(_zumbi_da_porta)
	match aula:
		"como_veem", "barulho":
			# Passou deles, ou eles largaram o posto (viram, ouviram, tiro).
			var zumbis: Array = _obstaculos[_obstaculo_da_aula(aula)]
			if not _de_posto(zumbis[0]):
				return true
			var mais_ao_sul := -INF
			for zumbi in zumbis:
				if is_instance_valid(zumbi):
					mais_ao_sul = maxf(mais_ao_sul, (zumbi as Node2D).global_position.y)
			return onde.y > mais_ao_sul + PASSOU_DO_OBSTACULO
		"porta":
			return Travessia.tutorial_avisos.has("porta") or porta_livre
		"pedras":
			return _tem_o_que_jogar() or porta_livre
		"arremesso":
			return porta_livre
		"arremesso_bom":
			# So quando foi o arremesso que tirou ele dali.
			return Travessia.tutorial_avisos.has("arremesso_bom") or not Travessia.tutorial_avisos.has("arremessou")
	return true

func _obstaculo_da_aula(aula: String) -> int:
	for i in OBSTACULOS.size():
		if OBSTACULOS[i]["aula"] == aula:
			return i
	return -1

func _tem_o_que_jogar() -> bool:
	return int(Travessia.arremessaveis.get("pedra", 0)) > 0 or int(Travessia.arremessaveis.get("garrafa", 0)) > 0

## Cada arremesso durante a aula: se o zumbi da porta continua de posto um
## tempo depois, o barulho caiu longe dele, e o radio manda jogar mais perto.
## O "isso!" e a aula `arremesso_bom`, quando ele sai.
func _ao_arremessar(_qual: String, _onde: Vector2) -> void:
	if Travessia.tutorial != "favor":
		return
	if not Travessia.tutorial_avisos.has("arremesso"):
		return
	Travessia.tutorial_avisos["arremessou"] = true
	await get_tree().create_timer(ESPERA_DO_ARREMESSO).timeout
	if Travessia.tutorial_avisos.has("arremesso") and _de_posto(_zumbi_da_porta) and not _caixa.ocupada():
		_radio(Falas.RADIO_ARREMESSO_ERROU)

## Entrou na pizzaria: a piada do pepperoni pelo radio (o roteiro do Joao), o
## objetivo agora diz o que e onde, e o vasculho.
func _chegar_na_pizzaria() -> void:
	_radio_uma_vez("chegada", Falas.CHEGADA)
	_radio_uma_vez("pizzaria", Falas.RADIO_PIZZARIA)
	_mostrar_objetivo_do_favor()

## O item vai para o movel da pizzaria mais perto da porta - e um vasculho
## como qualquer outro, e e assim que o tutorial ensina a vasculhar.
func _por_o_item_na_pizzaria() -> void:
	var pizzaria := Rect2()
	for c in Mapa.mundo()["construcoes"]:
		if c.get("nome", "") == NOME_DA_PIZZARIA:
			pizzaria = c["rect"]
	_pizzaria = pizzaria
	var porta := _p(PORTA_DA_PIZZARIA)
	var melhor: Node2D = null
	for filho in _cenario.get_children():
		if filho is Area2D and "achados" in filho and pizzaria.has_point((filho as Node2D).position):
			# Pepperoni fica no frio: geladeira ou freezer antes de qualquer
			# outro movel (era a caixa registradora, a mais perto da porta).
			var frio: bool = filho.rotulo in MOVEIS_DO_ITEM
			var melhor_frio: bool = melhor != null and melhor.rotulo in MOVEIS_DO_ITEM
			if melhor == null or (frio and not melhor_frio) or (frio == melhor_frio \
					and (filho as Node2D).position.distance_to(porta) < melhor.position.distance_to(porta)):
				melhor = filho
	if melhor == null:
		push_warning("tutorial: nenhum movel na pizzaria para o item do favor")
		return
	_movel_do_favor = melhor
	melhor.receber(Falas.ITEM_DO_FAVOR)
	melhor.vasculhado.connect(_ao_vasculhar_o_favor)

func _ao_vasculhar_o_favor(_rotulo: String, achados: Array[String]) -> void:
	if not Falas.ITEM_DO_FAVOR in achados:
		return
	achados.erase(Falas.ITEM_DO_FAVOR)
	Travessia.tutorial = "voltar_ao_portao"
	_radio_uma_vez("pegou", Falas.RADIO_PEGOU)
	_voltar_ao_portao()

func _voltar_ao_portao() -> void:
	_mostrar_objetivo("Levar o %s ao portão do Antônio" % Falas.ITEM_DO_FAVOR, _p(CONVERSA_NO_PORTAO))

## No portao com o item: a entrega, a 9mm e o fim da beta.
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
	await _conversa(Falas.FIM_DA_BETA)
	_jogador.no_roteiro = false
	_no_roteiro = false
	Travessia.tutorial = "fim"
	_mostrar_objetivo("Fim da beta — explore à vontade")
	await get_tree().create_timer(FIM_NA_TELA).timeout
	_mostrar_objetivo("")

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

