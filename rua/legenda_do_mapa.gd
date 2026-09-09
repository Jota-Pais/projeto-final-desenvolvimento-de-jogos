extends Control
## A legenda do retrato do mapa: o nome de cada lugar em cima dele, o titulo, a
## escala e a distancia de casa. Ver `rua/retratar_mapa.gd`.
##
## Desenha em **coordenada de tela** e nao de mundo. Com a camera afastada umas
## 30 vezes para o mundo caber, texto desenhado no mundo sairia com meio pixel
## de altura - entao aqui se converte a posicao de cada lugar pela transformada
## do canvas e escreve por cima, em tamanho de leitura.

const Mapa := preload("res://rua/mapa.gd")

const COR_DO_NOME := Color("f0e8d8")
const COR_DA_SOMBRA := Color(0.0, 0.0, 0.0, 0.75)
const COR_DA_MATA := Color("9db28f")
const COR_DO_TITULO := Color("e8b061")
const COR_DA_ESCALA := Color("d8cbb6")

## Onde fica a porta do porao, para medir a distancia de cada lugar. Sai do
## mapa, e nao do node: a legenda nao depende da cena estar montada.
var _de_casa := Vector2.ZERO

func _ready() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador != null:
		_de_casa = jogador.global_position

func _process(_delta: float) -> void:
	# A camera se afasta um quadro depois desta legenda existir, entao ela
	# redesenha sempre: e uma ferramenta, e um redraw por quadro nao custa nada.
	queue_redraw()

func _draw() -> void:
	var fonte := ThemeDB.fallback_font
	var transformada := get_viewport().get_canvas_transform()

	_desenhar_titulo(fonte)

	for lugar in Mapa.LUGARES:
		var r: Rect2 = lugar["rect"]
		var na_tela: Vector2 = transformada * r.get_center()
		var e_mata: bool = lugar["tipo"] == "floresta"
		var corpo := 15 if e_mata else 18
		var cor := COR_DA_MATA if e_mata else COR_DO_NOME
		var nome: String = lugar["nome"]

		# Retangulo do lugar, para o nome nao ficar solto no verde.
		if not e_mata:
			var caixa := Rect2(transformada * r.position, r.size * transformada.get_scale())
			draw_rect(caixa, Color(COR_DO_NOME, 0.14), false, 1.0)

		_escrever_centrado(fonte, nome, na_tela, corpo, cor)
		if not e_mata:
			var longe := _de_casa.distance_to(r.get_center()) / 40.0
			_escrever_centrado(fonte, "%.0f m" % longe,
				na_tela + Vector2(0.0, 17.0), 13, Color(cor, 0.7))

	# O rio e a ponte nao sao lugares, mas sao o que parte o mapa em dois.
	_escrever_centrado(fonte, "rio", transformada * (Mapa.RIO.get_center()
		+ Vector2(0.0, -9000.0)), 16, COR_DA_MATA)
	_escrever_centrado(fonte, "ponte", transformada * Mapa.PONTE.get_center()
		+ Vector2(0.0, -22.0), 15, COR_DO_TITULO)
	_escrever_centrado(fonte, "rodovia", transformada * (Mapa.RODOVIA.get_center()
		+ Vector2(-20000.0, 0.0)) + Vector2(0.0, -20.0), 14, Color(COR_DA_ESCALA, 0.75))

	_desenhar_escala(fonte, transformada)

func _desenhar_titulo(fonte: Font) -> void:
	var titulo := "Você me amaria se eu fosse um zumbi?  —  mapa da rua"
	draw_string(fonte, Vector2(23.0, 35.0), titulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COR_DA_SOMBRA)
	draw_string(fonte, Vector2(22.0, 34.0), titulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COR_DO_TITULO)

	var abaixo := "%.2f km x %.2f km  ·  greybox  ·  distâncias a pé desde a porta do porão" % [
		Mapa.MUNDO.size.x / 40000.0, Mapa.MUNDO.size.y / 40000.0]
	draw_string(fonte, Vector2(23.0, 58.0), abaixo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DA_SOMBRA)
	draw_string(fonte, Vector2(22.0, 57.0), abaixo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(COR_DA_ESCALA, 0.85))

## Barra de escala de 200 m, no canto. Sem ela a figura nao diz nada sobre
## tamanho, e tamanho e justamente o assunto deste mapa.
func _desenhar_escala(fonte: Font, transformada: Transform2D) -> void:
	var metros := 200.0
	var largura := metros * 40.0 * transformada.get_scale().x
	var canto := Vector2(24.0, size.y - 34.0)

	draw_line(canto, canto + Vector2(largura, 0.0), COR_DA_SOMBRA, 5.0)
	draw_line(canto, canto + Vector2(largura, 0.0), COR_DA_ESCALA, 3.0)
	for x in [0.0, largura]:
		draw_line(canto + Vector2(x, -6.0), canto + Vector2(x, 6.0), COR_DA_ESCALA, 3.0)
	draw_string(fonte, canto + Vector2(0.0, -13.0), "%.0f m" % metros,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COR_DA_ESCALA)

func _escrever_centrado(fonte: Font, texto: String, onde: Vector2,
		corpo: int, cor: Color) -> void:
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	var canto := onde - Vector2(largura / 2.0, 0.0)
	draw_string(fonte, canto + Vector2.ONE, texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, COR_DA_SOMBRA)
	draw_string(fonte, canto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, cor)
