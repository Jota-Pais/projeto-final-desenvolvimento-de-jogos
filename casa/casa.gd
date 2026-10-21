extends Control
## O modo Casa, versao beta: ponto e clique em primeira pessoa, no molde de
## *No, I'm Not a Human* (Trioskaz, 2025).
##
## O que veio de la, e por que:
##
##  - **comodos fixos, e os objetos acendem sob o mouse.** Nao se anda: se clica
##    no que se quer usar, e numa porta para ir ao comodo dela;
##  - **energia por noite** (as bolinhas do canto). Cada exame e cada documento
##    estudado gasta uma; dormir encerra a noite com o que sobrou;
##  - **o exame por parte do corpo**, com close recortado - la, para saber se a
##    visita e gente; aqui, para ver quanto dela ainda sobra (ver ela.gd);
##  - **a televisao, o radio e o olho magico** da porta da rua;
##  - **caixa de fala preta, letra de maquina, escolha que acende** - e a tela
##    toda em baixa resolucao.
##
## **As fotos entram como sao, sem filtro** (21/10/2026, Joao: "retire o filtro
## azul na parte interna da casa, deixa as imagens assim como estao"). Ate
## entao um shader (filtro.gdshader) lavava a tela num verde-azulado de noite,
## com grao e vinheta; saiu inteiro.
##
## **E beta, e quase tudo aqui e proposta**: os 3 pontos de energia, o que
## custa energia e o que nao custa. A planta e das fotos da equipe e foi
## decidida em 16/10/2026 (ver comodos.gd): ela fica presa no quarto e ele
## dorme no sofa da sala. O que e da narrativa (o que o noticiario diz, o que
## cada documento conta, quem e o casal da foto) aparece na tela entre
## colchetes, para ninguem confundir placeholder com texto.
##
## **As regras que fecham a partida continuam no Travessia, sem mudar**: a cura
## fica pronta com DOCUMENTOS_PARA_A_CURA entregues, e o prazo acaba no ultimo
## dia. Estudar um documento nao e exigido para a cura - se a equipe quiser que
## seja, e uma linha em Travessia.a_cura_esta_pronta().

const Comodos := preload("res://casa/comodos.gd")
const Ela := preload("res://casa/ela.gd")
const Desenho := preload("res://casa/desenho.gd")

## **Proposta.** Tres coisas por noite: da para examinar ela e estudar, mas nao
## tudo - e a mesma pressao de escolha das vagas da mochila, do lado de dentro.
const ENERGIA_POR_NOITE := 3

const COR_TEXTO := Color("e3ebe7")
const COR_APAGADA := Color("5f6b67")
const COR_ESCOLHA := Color("4fd8c4")
const COR_CAIXA := Color(0.0, 0.0, 0.0, 0.9)

var comodo := "entrada"
var energia := ENERGIA_POR_NOITE

var _desenho: Node2D
var _tela: TextureRect
var _escuro: ColorRect
var _caixa: PanelContainer
var _fala: Label
var _escolhas: VBoxContainer
var _legenda: Label
var _topo: Label
var _pips: Pips
var _fonte: SystemFont
## O que acontece quando uma fala SEM escolhas e fechada com um clique.
var _ao_fechar := Callable()

## As bolinhas de energia, no canto de cima.
class Pips extends Control:
	var energia := 3
	var total := 3
	func _draw() -> void:
		for i in total:
			var c := Vector2(10 + i * 24, 10)
			draw_arc(c, 8.0, 0, TAU, 24, Color(0.9, 0.95, 0.93, 0.9), 1.5)
			if i < energia:
				draw_circle(c, 5.0, Color(0.9, 0.95, 0.93, 0.95))

## O som da casa (20/10/2026, sons do Drive): o ambiente de dentro de fundo -
## o mesmo dos lugares da rua -, o som do botao ao passar o mouse num objeto
## ou numa escolha, a porta ao trocar de comodo e ao sair de manha, e a
## geladeira.
const SOM_DE_PASSAR := "menu/mouse_passar_botao"
const COMODOS_COM_PORTA := ["cozinha", "quarto"]

func _ready() -> void:
	Som.musica("")
	Som.ambiente("ambiente_dentro_lugares")
	_montar()
	_desenho.estagio = Ela.estagio(Travessia.dia, Travessia.PRAZO_DA_CURA)
	_desenho.zumbis_na_rua = _zumbis_na_rua()
	_atualizar()
	_falar(_linha_do_dia() + "\n\n" + o_que_voltou())

# ------------------------------------------------------------------ a tela

func _montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fonte = SystemFont.new()
	_fonte.font_names = PackedStringArray(["Consolas", "Lucida Console", "Courier New", "Monospace"])

	# 1280 x 720, o tamanho da janela: as fotos (casa/arte/) entram 1:1, e o
	# desenho a 4x tem na tela a mesma grossura de traco de antes.
	var quadro := SubViewport.new()
	quadro.size = Vector2i(Comodos.TELA * 4.0)
	quadro.disable_3d = true
	quadro.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(quadro)
	_desenho = Desenho.new()
	_desenho.scale = Vector2(4, 4)
	quadro.add_child(_desenho)

	_tela = TextureRect.new()
	_tela.texture = quadro.get_texture()
	_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tela.stretch_mode = TextureRect.STRETCH_SCALE
	_tela.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tela)

	_escuro = ColorRect.new()
	_escuro.color = Color.BLACK
	_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escuro.modulate.a = 0.0
	add_child(_escuro)

	_pips = Pips.new()
	_pips.total = ENERGIA_POR_NOITE
	_pips.position = Vector2(22, 22)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pips)

	_topo = _rotulo(14, Color(COR_TEXTO, 0.7))
	_topo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_topo.position = Vector2(-340, 18)
	_topo.size = Vector2(320, 20)
	_topo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_topo)

	_legenda = _rotulo(17, COR_TEXTO)
	_legenda.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_legenda.position = Vector2(-300, -54)
	_legenda.size = Vector2(600, 24)
	_legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legenda.add_theme_color_override("font_shadow_color", Color.BLACK)
	_legenda.add_theme_constant_override("shadow_offset_x", 2)
	_legenda.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_legenda)

	_caixa = PanelContainer.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa.position = Vector2(756, 414)
	_caixa.custom_minimum_size = Vector2(484, 0)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = COR_CAIXA
	fundo.set_content_margin_all(16)
	_caixa.add_theme_stylebox_override("panel", fundo)
	add_child(_caixa)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 12)
	_caixa.add_child(coluna)
	_fala = _rotulo(17, COR_TEXTO)
	_fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fala.custom_minimum_size = Vector2(452, 0)
	coluna.add_child(_fala)
	_escolhas = VBoxContainer.new()
	_escolhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escolhas.add_theme_constant_override("separation", 6)
	coluna.add_child(_escolhas)

func _rotulo(tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_override("font", _fonte)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	return rotulo

func _atualizar() -> void:
	_desenho.comodo = comodo
	_desenho.documentos = Travessia.documentos.size()
	_desenho.lidos = Travessia.documentos_lidos.size()
	_pips.energia = energia
	_pips.queue_redraw()
	var faltam := Travessia.dias_restantes()
	_topo.text = "noite do dia %d   ·   %s" % [
		Travessia.dia,
		"último dia" if faltam == 0 else ("falta 1 dia" if faltam == 1 else "faltam %d dias" % faltam),
	]

# ------------------------------------------------------------------ a fala

## Abre a caixa de fala. Sem `opcoes`, um clique em qualquer lugar fecha e
## chama `ao_fechar`. Cada opcao e { texto, acao: Callable, apagada: bool }.
func _falar(texto: String, opcoes: Array = [], ao_fechar := Callable()) -> void:
	_fala.text = texto
	for velho in _escolhas.get_children():
		_escolhas.remove_child(velho)
		velho.queue_free()
	for opcao in opcoes:
		_escolhas.add_child(_botao(opcao))
	_ao_fechar = ao_fechar
	_caixa.visible = true
	_caixa.reset_size()
	_legenda.text = ""
	_desenho.destaque = ""

func _botao(opcao: Dictionary) -> Button:
	var botao := Button.new()
	botao.text = opcao["texto"]
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.disabled = opcao.get("apagada", false)
	botao.focus_mode = Control.FOCUS_NONE
	botao.add_theme_font_override("font", _fonte)
	botao.add_theme_font_size_override("font_size", 16)
	botao.add_theme_color_override("font_color", COR_TEXTO)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_disabled_color", COR_APAGADA)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.06, 1.0)
	normal.border_color = Color(COR_TEXTO, 0.35)
	normal.set_border_width_all(1)
	normal.set_content_margin_all(8)
	var aceso := normal.duplicate() as StyleBoxFlat
	aceso.bg_color = COR_ESCOLHA
	aceso.border_color = COR_ESCOLHA
	var apagado := normal.duplicate() as StyleBoxFlat
	apagado.border_color = Color(COR_APAGADA, 0.4)
	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", aceso)
	botao.add_theme_stylebox_override("pressed", aceso)
	botao.add_theme_stylebox_override("disabled", apagado)
	botao.mouse_entered.connect(func() -> void:
		if not botao.disabled:
			Som.tocar(SOM_DE_PASSAR, 1.0, 1))
	var acao: Callable = opcao["acao"]
	botao.pressed.connect(func() -> void:
		_fechar_fala()
		acao.call())
	return botao

func _fechar_fala() -> void:
	_caixa.visible = false
	_desenho.close_up = ""
	_desenho.olho_magico = false

func _nada() -> void:
	pass

# ---------------------------------------------------------------- o mouse

func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_passar(evento.position)
	elif evento is InputEventMouseButton and evento.pressed \
			and evento.button_index == MOUSE_BUTTON_LEFT:
		if _caixa.visible:
			if _escolhas.get_child_count() == 0:
				var depois := _ao_fechar
				_fechar_fala()
				if depois.is_valid():
					depois.call()
			return
		var ponto := Comodos.ponto_em(comodo, _na_tela(evento.position))
		if not ponto.is_empty():
			_clicar(ponto)

## De pixel da janela para a grade de 320 x 180.
func _na_tela(pos: Vector2) -> Vector2:
	return pos / size * Comodos.TELA

func _passar(pos: Vector2) -> void:
	if _caixa.visible:
		return
	var ponto := Comodos.ponto_em(comodo, _na_tela(pos))
	# Soa so ao acender um objeto novo, nao a cada pixel em cima dele.
	if not ponto.is_empty() and ponto["id"] != _desenho.destaque:
		Som.tocar(SOM_DE_PASSAR, 1.0, 1)
	_desenho.destaque = ponto.get("id", "")
	_legenda.text = ponto.get("nome", "")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not ponto.is_empty() else Control.CURSOR_ARROW

func _clicar(ponto: Dictionary) -> void:
	if ponto.has("vai"):
		_ir(ponto["vai"])
		return
	match ponto["id"]:
		"porta_da_rua": _porta_da_rua()
		"olho_magico": _olho_magico()
		"tv": _televisao()
		"radio": _falar("Só estática.")
		"geladeira": _geladeira()
		"pesquisa": _pesquisa()
		"foto": _falar("Uma foto de vocês dois.\n\n[Quem são os dois é da equipe de narrativa.]")
		"sofa": _sofa()
		"ela": _ela()

## Troca de comodo com um piscar de preto, como porta que abre.
func _ir(destino: String) -> void:
	# Virar na sala ou ir ao corredor nao passa por porta; entrar e sair da
	# cozinha e do quarto, sim.
	if destino in COMODOS_COM_PORTA or comodo in COMODOS_COM_PORTA:
		Som.tocar("porta", randf_range(0.95, 1.05), 1)
	comodo = destino
	_desenho.destaque = ""
	_legenda.text = ""
	_atualizar()
	_escuro.modulate.a = 1.0
	create_tween().tween_property(_escuro, "modulate:a", 0.0, 0.3)

# ------------------------------------------------------------ os objetos

func _porta_da_rua() -> void:
	_falar("A porta da rua, trancada por dentro. Só se abre de manhã, para sair.")

## Quantos se ve pelo olho magico. So o que da para ver da porta, e nao a
## contagem da rua - a casa nao conhece a rua, conhece o Travessia.
func _zumbis_na_rua() -> int:
	return clampi(2 + Travessia.dia / 2, 2, 16)

func _olho_magico() -> void:
	_desenho.olho_magico = true
	var n := _zumbis_na_rua()
	_falar("Pelo olho mágico, a rua. Dá para contar %d deles daqui." % n)

func _televisao() -> void:
	_desenho.tv_ligada = true
	_falar("O boletim da noite, dia %d.\n\n[O que o noticiário diz é da equipe de narrativa.]" % Travessia.dia)

## A geladeira. Ate 30/09/2026 listava o que veio da rua e ficou guardado;
## desde que a rua so rende balas e documentos, nao chega nada para guardar
## aqui. Fica clicavel porque a casa e ponto e clique, e o que ela diz e
## [texto da narrativa].
## O som da geladeira e o mesmo ao abrir e ao fechar: fecha quando a fala
## fecha.
func _geladeira() -> void:
	Som.tocar("geladeira")
	_falar("Vazia.", [], Som.tocar.bind("geladeira"))

func _pesquisa() -> void:
	var tem := Travessia.documentos.size()
	var texto := "A pesquisa. %d de %d documentos na bancada." % [tem, Travessia.DOCUMENTOS_PARA_A_CURA]
	if tem == 0:
		texto += "\n\nNada para estudar ainda. Os documentos estão na rua."
	var opcoes := []
	if oferece_terminar_a_cura():
		opcoes.append({ "texto": "Terminar a cura", "acao": _terminar_a_cura })
	for documento in Travessia.documentos:
		if documento in Travessia.documentos_lidos:
			continue
		opcoes.append({
			"texto": "Estudar o %s  (1 de energia)" % documento,
			"acao": _estudar.bind(documento),
			"apagada": energia <= 0,
		})
	if not opcoes.is_empty():
		opcoes.append({ "texto": "Deixar para depois", "acao": _nada })
	_falar(texto, opcoes)

func _estudar(documento: String) -> void:
	energia -= 1
	Travessia.documentos_lidos.append(documento)
	_atualizar()
	_falar("Você estuda o %s de ponta a ponta.\n\n[O que ele diz é da equipe de narrativa.]" % documento,
		[], _pesquisa)

func _terminar_a_cura() -> void:
	Travessia.acabar_o_jogo(Travessia.Desfecho.VITORIA)

## O sofa da sala, onde ele dorme (16/10/2026: o quarto e dela).
func _sofa() -> void:
	var sobra := ""
	if energia > 0:
		sobra = "\n\nAinda daria para fazer %d coisa%s hoje." % [energia, "" if energia == 1 else "s"]
	if oferece_terminar_a_cura():
		_falar("A cura está pronta na bancada da cozinha.", [
			{ "texto": "Terminar a cura", "acao": _terminar_a_cura },
			{ "texto": "Ainda não", "acao": _nada },
		])
		return
	if Travessia.e_o_ultimo_dia():
		_falar("Hoje era o último dia do prazo. Se dormir, acabou." + sobra, [
			{ "texto": "Dormir", "acao": encerrar_a_noite },
			{ "texto": "Ainda não", "acao": _nada },
		])
		return
	_falar("Dormir até de manhã?" + sobra, [
		{ "texto": "Dormir", "acao": encerrar_a_noite },
		{ "texto": "Ainda não", "acao": _nada },
	])

func _ela() -> void:
	var texto := "Ela, acorrentada à cabeceira."
	if energia <= 0:
		texto += "\n\nSem energia para mais nada hoje."
	var opcoes := []
	for parte in Ela.PARTES:
		opcoes.append({
			"texto": "Examinar %s  (1 de energia)" % Ela.NOME_DA_PARTE[parte],
			"acao": _examinar.bind(parte),
			"apagada": energia <= 0,
		})
	opcoes.append({ "texto": "Deixar ela em paz", "acao": _nada })
	_falar(texto, opcoes)

func _examinar(parte: String) -> void:
	energia -= 1
	_atualizar()
	_falar(Ela.LAUDO[parte][_desenho.estagio], [], _ela)
	_desenho.close_up = parte

# ------------------------------------------------------ as regras da noite

## Se a casa oferece terminar a cura agora. A regra e do Travessia.
func oferece_terminar_a_cura() -> bool:
	return Travessia.a_cura_esta_pronta()

## Fim da noite. **A ordem das tres regras e o que decide a partida**, e e a
## mesma desde o lugar reservado: a vitoria vem antes do prazo (cura pronta no
## ultimo dia e cura a tempo), e so depois o prazo se esgota.
func encerrar_a_noite() -> void:
	if Travessia.a_cura_esta_pronta():
		Travessia.acabar_o_jogo(Travessia.Desfecho.VITORIA)
		return
	if Travessia.e_o_ultimo_dia():
		Travessia.acabar_o_jogo(Travessia.Desfecho.PRAZO_ESGOTADO)
		return
	Som.tocar("porta")
	Travessia.sair_para_a_rua()

## A linha que abre a noite: como o dia acabou e quanto falta.
func _linha_do_dia() -> String:
	var faltam := Travessia.dias_restantes()
	var quanto := "Hoje era o último dia."
	if faltam == 1:
		quanto = "Falta 1 dia para o prazo."
	elif faltam > 1:
		quanto = "Faltam %d dias para o prazo." % faltam
	var como := "Você trancou a porta."
	match Travessia.fim_do_dia:
		Travessia.FimDoDia.AMANHECEU_NA_RUA:
			como = "Amanheceu com você na rua."
		Travessia.FimDoDia.SEM_VIDA:
			como = "Você não aguentou o dia."
	return "Dia %d. %s %s" % [Travessia.dia, como, quanto]

## O que entrou em casa hoje - ou o que ficou na rua, se o dia acabou mal.
func o_que_voltou() -> String:
	if Travessia.fim_do_dia != Travessia.FimDoDia.PELA_PORTA:
		if Travessia.documentos_perdidos == 0:
			return "Você não estava carregando documento nenhum. Não havia o que perder."
		return "Ficou na rua: %d documento%s. Nada disso entrou em casa." % [
			Travessia.documentos_perdidos,
			"" if Travessia.documentos_perdidos == 1 else "s",
		]
	if Travessia.documentos.is_empty():
		return "Da rua não veio nada."
	return "%d documento%s na bancada da pesquisa." % [
		Travessia.documentos.size(), "" if Travessia.documentos.size() == 1 else "s"
	]
