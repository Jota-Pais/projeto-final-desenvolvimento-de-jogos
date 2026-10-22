extends Control
## A cena inicial (21/10/2026, Joao: "uma cutscene no comeco do jogo, sem ser
## na arte do jogo, fazendo algo mais detalhado"): o que aconteceu antes do dia
## 1, em seis quadros - a fuga pelo tunel, a mordida, a volta para casa com ela
## no colo e a promessa na cama. E o que explica ela acorrentada no quarto da
## casa. Toca so na partida nova: o titulo chama Travessia.comecar_partida, que
## abre esta cena, e ela acaba na rua, na abertura do tutorial (rua/tutorial.gd).
##
## **A arte e do Renan** (21/10/2026, aprovada pelo Joao: "aprovado, pode subir
## tudo pro jogo agora"), feita a partir do storyboard do Joao, que era so o
## conceito - "nao quero que use a mesma arte, ele e apenas um conceito, sua
## producao deve ser de um nivel muito maior". Cada quadro e uma imagem em
## `cena_inicial/arte/<n>.jpg` (ou .png), de 1 a 6, 16:9, de 1280 x 720 para
## cima e sem legenda: o texto e desta cena. As do Renan tem 1376 x 768 e na
## janela do jogo saem praticamente 1:1. O quadro cobre a tela inteira e as
## tarjas tapam ALTURA_DA_TARJA em cima e embaixo, entao o que importa fica no
## meio. Sem a imagem o quadro fica escuro e so o texto conta.
##
## O texto e o que o Joao aprovou em 21/10/2026: em terceira pessoa, com os
## nomes que ele deu - Fabiano e Leticia -, contando o que esta no storyboard e
## fechando na frase dele, numa caixa embaixo ("faz tudo em uma caixa de texto
## explicando exatamente o que aconteceu"). A cena anda sozinha - cada
## texto fica o tempo de ler, pela regra das falas do radio
## (rua/caixa_de_fala.gd) -, o E adianta e o Esc pula tudo.

const CaixaDeFala := preload("res://rua/caixa_de_fala.gd")

const PASTA_DA_ARTE := "res://cena_inicial/arte/"

## Os seis quadros, na ordem. Cada fala e [quem, texto, sons]: quem "" e a
## narracao, em italico; quem fala tem o nome na frente. Os sons sao [segundos
## depois de a fala comecar, nome em som/, tom, dB a mais] - os de som/ que
## cabem em cada quadro (Joao, 21/10/2026): a horda na fuga, o zumbi no
## agarrao, a porta na chegada e, no fim, os grunhidos do storyboard, que sao o
## zumbi baixo por baixo da ultima frase (o texto deles saiu, o som ficou). A
## mordida fica sem som proprio: o dano_personagem e a voz dele.
## `correndo` poe os passos de corrida por baixo do quadro inteiro.
##
## `zoom` e `centro` sao o movimento lento da camera no quadro: o zoom de/para
## e o ponto da imagem no meio da tela de/para, em fracao da imagem. Sem eles,
## ZOOM e o meio. A borda da imagem nunca entra na tela, entao quanto maior o
## zoom, mais longe do meio o centro pode ir. `funde` troca do quadro anterior
## para este sem escurecer, um por cima do outro: o 1 e o 2 do Renan sao o
## mesmo enquadramento, e o zumbi rastejante aparece na mesma cena - por isso
## o 2 comeca na camera em que o 1 acaba.
const QUADROS: Array = [
	{
		"correndo": true,
		"zoom": [1.0, 1.1],
		"centro": [Vector2(0.5, 0.5), Vector2(0.52, 0.52)],
		"falas": [
			["", "Fabiano e Letícia fugiam pelo túnel, com a horda logo atrás.",
				[[0.0, "zumbi", 0.85, 0.0], [1.6, "zumbi", 1.05, -4.0], [3.1, "zumbi", 0.75, -2.0]]],
		],
	},
	{
		"funde": true,
		"zoom": [1.1, 1.16],
		"centro": [Vector2(0.52, 0.52), Vector2(0.565, 0.56)],
		"falas": [
			["", "Um zumbi, rastejando no chão, agarrou a perna dela.",
				[[0.2, "zumbi", 0.7, 0.0]]],
		],
	},
	{
		"zoom": [1.0, 1.12],
		"centro": [Vector2(0.5, 0.5), Vector2(0.45, 0.55)],
		"falas": [
			["", "Letícia caiu, e o zumbi a mordeu na perna.", []],
		],
	},
	{
		"correndo": true,
		"zoom": [1.0, 1.1],
		"centro": [Vector2(0.5, 0.5), Vector2(0.5, 0.47)],
		"falas": [
			["", "Fabiano a pegou no colo e fugiu com ela.",
				[[0.6, "zumbi", 0.9, -4.0], [2.4, "zumbi", 0.8, -6.0]]],
		],
	},
	{
		"zoom": [1.12, 1.0],
		"centro": [Vector2(0.47, 0.5), Vector2(0.5, 0.5)],
		"falas": [
			["", "Chegou em casa com ela nos braços.",
				[[0.4, "porta", 1.0, 0.0]]],
		],
	},
	{
		"zoom": [1.0, 1.12],
		"centro": [Vector2(0.5, 0.5), Vector2(0.48, 0.54)],
		"falas": [
			["", "Deitou-a na cama.", []],
			["Fabiano", "Eu vou dar um jeito em você, meu amor... Eu prometo!", []],
			["", "E então Fabiano foi atrás de conseguir uma cura para a sua namorada.",
				[[0.0, "zumbi", 0.8, -10.0], [1.5, "zumbi", 0.72, -12.0]]],
		],
	},
]

## A voz de quem fala, enquanto a fala e escrita (Som.falar): a do Fabiano e a
## mesma do "Voce" nas falas do jogo (VOZES em rua/falas_do_tutorial.gd).
const VOZES := { "Fabiano": "pp" }

## Os passos de corrida dos quadros `correndo` (o mesmo loop do jogador
## correndo na rua, rua/jogador.gd).
const PASSOS := "andar_previa_2"

## A altura de cada tarja, em fracao da tela. A de baixo e onde fica a caixa.
const ALTURA_DA_TARJA := 0.12
## A troca de quadro: escurece e clareia, em segundos cada metade.
const SEGUNDOS_DO_FADE := 0.8
## A troca sem escurecer (`funde`): quanto o quadro anterior leva para sumir.
const SEGUNDOS_DA_FUSAO := 1.2
## O Esc escurece mais rapido.
const SEGUNDOS_DO_PULO := 0.3
## O ultimo texto fica mais um tanto antes da rua: os grunhidos ficam no ar.
const PAUSA_NO_FIM := 1.5
## O movimento padrao da camera, do comeco ao fim do quadro.
const ZOOM := [1.0, 1.08]

const COR_DO_TEXTO := Color(0.909804, 0.886275, 0.839216)
const COR_DO_NOME := "e8b061"

enum Fase { ENTRANDO, FALANDO, SAINDO, FIM }

var _fase := Fase.ENTRANDO
var _quadro := -1
var _fala := 0
## Quanto do texto ja foi escrito, em letras.
var _letras := 0.0
## Quanto falta de leitura depois de o texto estar inteiro.
var _lendo := 0.0
## Desde o comeco do quadro e desde o comeco da fala.
var _tempo := 0.0
var _tempo_da_fala := 0.0
## Quanto o quadro deve durar, para a camera chegar no fim junto com ele.
var _duracao := 1.0
var _sons_tocados := 0
## Segurar a textura: carregada so dentro do _draw, ela sai branca.
var _textura: Texture2D
## Onde o quadro foi desenhado por ultimo: e de onde o seguinte funde.
var _onde := Rect2()
## Na troca sem escurecer: o quadro anterior, parado onde estava, e o quanto
## dele ainda aparece por cima (1 a 0).
var _anterior: Texture2D
var _onde_anterior := Rect2()
var _fusao := 0.0
var _transicao: Tween

var _tela: Control
var _cortina: ColorRect
var _texto: RichTextLabel
var _passos: AudioStreamPlayer

## A imagem do quadro `n` (de 1 a 6), ou "" se ainda nao tem.
static func arte_do_quadro(n: int) -> String:
	for extensao in [".png", ".jpg"]:
		if ResourceLoader.exists(PASTA_DA_ARTE + str(n) + extensao):
			return PASTA_DA_ARTE + str(n) + extensao
	return ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar_a_tela()
	_passos = AudioStreamPlayer.new()
	add_child(_passos)
	# A musica do menu sai: daqui ate a rua, so o que acontece nos quadros.
	Som.musica("")
	Som.ambiente("")
	_comecar_o_quadro(0)

func _process(delta: float) -> void:
	if _fase == Fase.FIM:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		_pular()
		return
	_tempo += delta
	if _textura != null or _fusao > 0.0:
		_tela.queue_redraw()
	if _fase == Fase.FALANDO:
		_falando(delta)

func _montar_a_tela() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	_tela = Control.new()
	_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_tela.draw.connect(_desenhar_o_quadro)
	add_child(_tela)

	_cortina = ColorRect.new()
	_cortina.color = Color.BLACK
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cortina)

	for de_cima in [true, false]:
		var tarja := ColorRect.new()
		tarja.color = Color.BLACK
		tarja.anchor_right = 1.0
		tarja.anchor_top = 0.0 if de_cima else 1.0 - ALTURA_DA_TARJA
		tarja.anchor_bottom = ALTURA_DA_TARJA if de_cima else 1.0
		add_child(tarja)

	# A caixa: o mesmo desenho da caixa de fala do jogo, dentro da tarja de
	# baixo.
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.06, 0.05)
	estilo.set_border_width_all(2)
	estilo.border_color = Color(0.909804, 0.886275, 0.839216, 0.45)
	estilo.set_content_margin_all(12)
	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", estilo)
	caixa.anchor_left = 0.5
	caixa.anchor_right = 0.5
	caixa.anchor_top = 1.0 - ALTURA_DA_TARJA
	caixa.anchor_bottom = 1.0
	caixa.offset_left = -440.0
	caixa.offset_right = 440.0
	caixa.offset_top = 10.0
	caixa.offset_bottom = -10.0
	add_child(caixa)

	# A narracao sai em italico: a fonte do jogo inclinada.
	var italico := FontVariation.new()
	italico.base_font = ThemeDB.fallback_font
	italico.variation_transform = Transform2D(Vector2(1.0, 0.2), Vector2(0.0, 1.0), Vector2.ZERO)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.scroll_active = false
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.add_theme_color_override("default_color", COR_DO_TEXTO)
	_texto.add_theme_font_override("italics_font", italico)
	_texto.add_theme_font_size_override("normal_font_size", 19)
	_texto.add_theme_font_size_override("italics_font_size", 19)
	caixa.add_child(_texto)

	var dica := Label.new()
	dica.text = "Esc: pular"
	dica.add_theme_font_size_override("font_size", 13)
	dica.add_theme_color_override("font_color", Color(COR_DO_TEXTO, 0.6))
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dica.anchor_left = 1.0
	dica.anchor_right = 1.0
	dica.offset_left = -200.0
	dica.offset_right = -24.0
	dica.offset_top = 16.0
	dica.offset_bottom = 40.0
	add_child(dica)

## O quadro cobrindo a tela, com a camera andando devagar do comeco ao fim
## dele, e o anterior sumindo por cima na troca sem escurecer. A borda da
## imagem nunca entra na tela.
func _desenhar_o_quadro() -> void:
	if _textura != null:
		var q: Dictionary = QUADROS[_quadro]
		var zoom: Array = q.get("zoom", ZOOM)
		var centro: Array = q.get("centro", [Vector2(0.5, 0.5), Vector2(0.5, 0.5)])
		var andou := smoothstep(0.0, 1.0, _tempo / _duracao)
		var tela := _tela.size
		var imagem := Vector2(_textura.get_size())
		var tamanho := imagem * maxf(tela.x / imagem.x, tela.y / imagem.y) * lerpf(zoom[0], zoom[1], andou)
		var canto := tela / 2.0 - (centro[0] as Vector2).lerp(centro[1], andou) * tamanho
		_onde = Rect2(canto.clamp(tela - tamanho, Vector2.ZERO), tamanho)
		_tela.draw_texture_rect(_textura, _onde, false)
	if _anterior != null and _fusao > 0.0:
		_tela.draw_texture_rect(_anterior, _onde_anterior, false, Color(1.0, 1.0, 1.0, _fusao))

func _comecar_o_quadro(qual: int) -> void:
	var fundindo: bool = QUADROS[qual].get("funde", false) and _textura != null
	if fundindo:
		_anterior = _textura
		_onde_anterior = _onde
		_fusao = 1.0
	_quadro = qual
	_tempo = 0.0
	_fase = Fase.ENTRANDO
	_texto.text = ""
	var caminho := arte_do_quadro(qual + 1)
	_textura = load(caminho) as Texture2D if caminho != "" else null
	_duracao = _duracao_do_quadro(qual)
	_tela.queue_redraw()
	if QUADROS[qual].get("correndo", false):
		_correr()
	_transicao = create_tween()
	if fundindo:
		_transicao.tween_property(self, "_fusao", 0.0, SEGUNDOS_DA_FUSAO)
		_transicao.tween_callback(func() -> void: _anterior = null)
	else:
		_transicao.tween_property(_cortina, "modulate:a", 0.0, SEGUNDOS_DO_FADE)
	_transicao.tween_callback(_comecar_a_fala.bind(0))

## Da entrada a saida do quadro, se ninguem apertar nada.
func _duracao_do_quadro(qual: int) -> float:
	var funde_no_seguinte: bool = qual + 1 < QUADROS.size() and QUADROS[qual + 1].get("funde", false)
	var segundos: float = SEGUNDOS_DA_FUSAO if QUADROS[qual].get("funde", false) else SEGUNDOS_DO_FADE
	segundos += SEGUNDOS_DO_FADE / 2.0 if funde_no_seguinte else SEGUNDOS_DO_FADE
	for fala in QUADROS[qual]["falas"]:
		var letras := (fala[1] as String).length()
		segundos += letras / CaixaDeFala.LETRAS_POR_SEGUNDO + _leitura(letras)
	if qual == QUADROS.size() - 1:
		segundos += PAUSA_NO_FIM
	return segundos

func _leitura(letras: int) -> float:
	return CaixaDeFala.LEITURA_MINIMA + letras * CaixaDeFala.LEITURA_POR_LETRA

func _comecar_a_fala(qual: int) -> void:
	_fala = qual
	_fase = Fase.FALANDO
	_tempo_da_fala = 0.0
	_sons_tocados = 0
	_letras = 0.0
	var fala: Array = QUADROS[_quadro]["falas"][qual]
	var quem: String = fala[0]
	if quem == "":
		_texto.text = "[center][i]%s[/i][/center]" % fala[1]
	else:
		_texto.text = "[center][color=#%s]%s:[/color] \"%s\"[/center]" % [COR_DO_NOME, quem, fala[1]]
	_texto.visible_characters = 0
	_texto.modulate.a = 1.0
	_lendo = _leitura((fala[1] as String).length())
	if _quadro == QUADROS.size() - 1 and qual == QUADROS[_quadro]["falas"].size() - 1:
		_lendo += PAUSA_NO_FIM
	Som.falar(VOZES.get(quem, ""))

## O texto sendo escrito e depois lido. O E completa o que esta sendo escrito
## ou, ja inteiro, passa adiante. A voz cala quando o texto fica inteiro.
func _falando(delta: float) -> void:
	_tempo_da_fala += delta
	var sons: Array = QUADROS[_quadro]["falas"][_fala][2]
	while _sons_tocados < sons.size() and _tempo_da_fala >= sons[_sons_tocados][0]:
		var som: Array = sons[_sons_tocados]
		_tocar(som[1], som[2], som[3])
		_sons_tocados += 1
	var adiantou := Input.is_action_just_pressed("vasculhar") or Input.is_action_just_pressed("ui_accept")
	var total := _texto.get_parsed_text().length()
	if _letras < total:
		_letras = total if adiantou else minf(total, _letras + delta * CaixaDeFala.LETRAS_POR_SEGUNDO)
		_texto.visible_characters = int(_letras)
		if _letras >= total:
			Som.calar_a_voz()
		return
	_lendo -= delta
	if _lendo <= 0.0 or adiantou:
		if _fala + 1 < QUADROS[_quadro]["falas"].size():
			_comecar_a_fala(_fala + 1)
		else:
			_acabar_o_quadro()

func _acabar_o_quadro() -> void:
	_fase = Fase.SAINDO
	_parar_de_correr(SEGUNDOS_DO_FADE)
	_transicao = create_tween()
	var seguinte := _quadro + 1
	if seguinte < QUADROS.size() and QUADROS[seguinte].get("funde", false):
		# Sem escurecer: so o texto sai, e o quadro seguinte entra por baixo
		# deste.
		_transicao.tween_property(_texto, "modulate:a", 0.0, SEGUNDOS_DO_FADE / 2.0)
		_transicao.tween_callback(_comecar_o_quadro.bind(seguinte))
		return
	_transicao.tween_property(_cortina, "modulate:a", 1.0, SEGUNDOS_DO_FADE)
	_transicao.parallel().tween_property(_texto, "modulate:a", 0.0, SEGUNDOS_DO_FADE)
	if seguinte < QUADROS.size():
		_transicao.tween_callback(_comecar_o_quadro.bind(seguinte))
	else:
		_transicao.tween_callback(_ir_para_a_rua)

func _pular() -> void:
	_fase = Fase.FIM
	if _transicao != null:
		_transicao.kill()
	Som.calar_a_voz()
	_parar_de_correr(SEGUNDOS_DO_PULO)
	_transicao = create_tween()
	_transicao.tween_property(_cortina, "modulate:a", 1.0, SEGUNDOS_DO_PULO)
	_transicao.parallel().tween_property(_texto, "modulate:a", 0.0, SEGUNDOS_DO_PULO)
	_transicao.tween_callback(_ir_para_a_rua)

func _ir_para_a_rua() -> void:
	_fase = Fase.FIM
	get_tree().change_scene_to_file(Travessia.CENA_DA_RUA)

## Um som de som/ que acaba sozinho. Os players sao desta cena, e nao do Som:
## o Esc corta tudo com ela.
func _tocar(nome: String, tom: float, a_mais_db: float) -> void:
	if Som.mudo:
		return
	var stream := Som.carregar(nome)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = tom
	player.volume_db = Som.VOLUME.get(nome, 0.0) + a_mais_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _correr() -> void:
	if Som.mudo or _passos.playing:
		return
	var stream := Som.carregar(PASSOS)
	if stream == null:
		return
	stream.loop = true
	_passos.stream = stream
	_passos.volume_db = Som.VOLUME.get(PASSOS, 0.0)
	_passos.play()

func _parar_de_correr(segundos: float) -> void:
	if not _passos.playing:
		return
	var fade := create_tween()
	fade.tween_property(_passos, "volume_db", -60.0, segundos)
	fade.tween_callback(_passos.stop)
