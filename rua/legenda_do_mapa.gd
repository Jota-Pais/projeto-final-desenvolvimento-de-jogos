extends Control
## A legenda do retrato do mapa: o nome de cada lugar em cima dele, o titulo, a
## escala e a distancia de casa. Ver `rua/retratar_mapa.gd`.
##
## Desenha em **coordenada de tela** e nao de mundo. Com a camera afastada umas
## 20 vezes para o mundo caber, texto desenhado no mundo sairia com meio pixel
## de altura - entao aqui se converte a posicao de cada lugar pela transformada
## do canvas e escreve por cima, em tamanho de leitura.

const Mapa := preload("res://rua/mapa.gd")

const COR_DO_NOME := Color("f0e8d8")
const COR_DA_SOMBRA := Color(0.0, 0.0, 0.0, 0.75)
const COR_DA_ZONA := Color("9db28f")
const COR_DO_TITULO := Color("e8b061")
const COR_DA_ESCALA := Color("d8cbb6")

## Onde fica a porta de casa, para medir a distancia de cada lugar.
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

	# Zonas primeiro e predios depois, para o nome do predio ficar por cima.
	for passada in ["zona", "predio"]:
		for lugar in Mapa.lugares():
			var e_zona: bool = lugar["tipo"] == "zona"
			if (passada == "zona") != e_zona:
				continue
			var r: Rect2 = lugar["rect"]
			var na_tela: Vector2 = transformada * r.get_center()
			var corpo := 15 if e_zona else 11
			var cor := COR_DA_ZONA if e_zona else COR_DO_NOME
			_escrever_centrado(fonte, lugar["nome"], na_tela, corpo, cor)
			if not e_zona:
				var longe := _de_casa.distance_to(r.get_center()) / 40.0
				_escrever_centrado(fonte, "%.0f m" % longe,
					na_tela + Vector2(0.0, 12.0), 9, Color(cor, 0.7))

	_desenhar_escala(fonte, transformada)

func _desenhar_titulo(fonte: Font) -> void:
	var titulo := "Você me amaria se eu fosse um zumbi?  —  mapa da rua"
	draw_string(fonte, Vector2(23.0, 35.0), titulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COR_DA_SOMBRA)
	draw_string(fonte, Vector2(22.0, 34.0), titulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COR_DO_TITULO)

	var abaixo := "%.0f m x %.0f m  ·  greybox traçado de design/urussanga.png  ·  distâncias a pé desde a porta de casa" % [
		Mapa.MUNDO.size.x / 40.0, Mapa.MUNDO.size.y / 40.0]
	draw_string(fonte, Vector2(23.0, 58.0), abaixo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DA_SOMBRA)
	draw_string(fonte, Vector2(22.0, 57.0), abaixo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(COR_DA_ESCALA, 0.85))

## Barra de escala de 100 m, no canto. Sem ela a figura nao diz nada sobre
## tamanho, e tamanho e justamente o assunto deste mapa.
func _desenhar_escala(fonte: Font, transformada: Transform2D) -> void:
	var metros := 100.0
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
