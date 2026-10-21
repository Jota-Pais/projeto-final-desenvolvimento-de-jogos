extends Node2D
## O que cobre o lado de fora de uma construcao (21/10/2026): a varanda, a
## garagem, a area de servico ou a lona em cima de um recorte da planta
## (rua/construcao.gd), o pergolado do deck e o toldo listrado da fachada da
## pizzaria. Irmao do jogador no Y-sort, como o telhado; quando o jogador esta
## embaixo, fica transparente - senao ele sumiria debaixo da varanda.
##
## A agua cai para fora da casa (`queda`): para o norte nos recortes de canto
## norte, para o sul nos de canto sul. Os pilares ficam no canto livre, o que
## nao encosta em parede nenhuma.

const Telhado := preload("res://rua/telhado.gd")

## Quanto a cobertura fica da altura da parede (px de tela inclinada): o que
## sobra embaixo dela, na frente, e o vao aberto da varanda.
const ALTURA := 34.0
const PE := 10.0
const TRANSPARENTE := 0.3
const POSTE := Color("8a7d6a")
const VIGA := Color("6b5640")

var tipo := ""
var area := Rect2()
var queda := "sul"
## O material da varanda (o mesmo do telhado da casa) e as listras do toldo.
var telha := "fibrocimento"
var listras: Array = []
var texto := ""
## O canto livre, onde vai o pilar.
var canto_livre := Vector2.ZERO

var _jogador: Node2D
var _transparente := false

func montar(qual: String, onde: Rect2, para: String) -> void:
	tipo = qual
	area = onde
	queda = para
	# Um px depois do telhado da casa, para empatar a favor da cobertura.
	position = Vector2(0.0, area.end.y - PE + 1.0)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta: float) -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
		if _jogador == null:
			return
	var embaixo := area.grow(6.0).has_point(_jogador.global_position)
	if embaixo != _transparente:
		_transparente = embaixo
		modulate.a = TRANSPARENTE if embaixo else 1.0

func _draw() -> void:
	draw_set_transform(Vector2(0.0, -position.y))
	match tipo:
		"toldo":
			_toldo()
		"pergolado":
			_pergolado()
		"lona":
			_lona()
		_:
			_telhadinho()

## O telhado de varanda, garagem ou area de servico: meia-agua caindo para
## fora, a viga na beira baixa e o pilar no canto livre.
func _telhadinho() -> void:
	var textura: Texture2D = Telhado.MATERIAIS.get(telha, Telhado.MATERIAIS["fibrocimento"])
	var cima := area
	var frente_aberta := queda == "sul"
	if frente_aberta:
		cima = Rect2(area.position.x, area.position.y - 8.0, area.size.x, area.size.y - ALTURA + 8.0)
	var pontos := Telhado._cantos(cima)
	var tamanho := textura.get_size()
	var uvs := PackedVector2Array()
	for p in pontos:
		uvs.append((Vector2(p.x, -p.y) if queda == "norte" else p) / tamanho)
	var luz := 0.92 if queda == "sul" else 0.8
	draw_polygon(pontos, PackedColorArray([Color(luz, luz, luz * 0.97)]), uvs, textura)
	# A viga na beira baixa.
	var beira := Rect2(cima.position.x, cima.end.y - 4.0, cima.size.x, 4.0) if frente_aberta \
		else Rect2(cima.position.x, cima.position.y, cima.size.x, 4.0)
	draw_rect(beira, VIGA)
	draw_rect(Rect2(cima.position, cima.size), Telhado.CONTORNO, false, 1.0)
	_pilares(cima, frente_aberta)

func _pilares(cima: Rect2, frente_aberta: bool) -> void:
	var xs: Array[float] = [canto_livre.x]
	# Um pilar a mais no meio quando o vao e largo.
	if cima.size.x > 200.0:
		xs.append(cima.get_center().x)
	for x in xs:
		x = clampf(x, cima.position.x + 4.0, cima.end.x - 4.0)
		if frente_aberta:
			var r := Rect2(x - 3.0, cima.end.y, 6.0, area.end.y - cima.end.y)
			draw_rect(r, POSTE)
			draw_rect(Rect2(r.position.x + 4.0, r.position.y, 2.0, r.size.y), POSTE.darkened(0.3))
			draw_rect(r, Telhado.CONTORNO, false, 1.0)
		else:
			var r := Rect2(x - 4.0, cima.position.y - 2.0, 8.0, 8.0)
			draw_rect(r, POSTE.lightened(0.1))
			draw_rect(r, Telhado.CONTORNO, false, 1.0)

## O pergolado do deck: vigas de madeira abertas (a mesa embaixo aparece) e
## a trepadeira que tomou conta.
func _pergolado() -> void:
	var x := area.position.x + 6.0
	while x < area.end.x:
		draw_rect(Rect2(x - 2.0, area.position.y, 4.0, area.size.y), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(x - 3.0, area.position.y - 6.0, 4.0, area.size.y), VIGA.lightened(0.1))
		x += 22.0
	for y in [area.position.y + 4.0, area.end.y - 10.0]:
		draw_rect(Rect2(area.position.x, y - 6.0, area.size.x, 6.0), VIGA)
		draw_rect(Rect2(area.position.x, y - 6.0, area.size.x, 6.0), Telhado.CONTORNO, false, 1.0)
	var semente := int(area.position.x * 7.0 + area.position.y)
	for k in 26:
		var p := area.position + Vector2(float((semente * (k + 3) * 37) % 997) / 997.0 * area.size.x,
			float((semente * (k + 5) * 53) % 991) / 991.0 * area.size.y * 0.7)
		draw_circle(p, 4.0 + float(k % 3), Color(0.29, 0.42, 0.2, 0.75))
	draw_rect(Rect2(area.position.x + 2.0, area.position.y - 8.0, 6.0, 8.0), POSTE)
	draw_rect(Rect2(area.position.x + 2.0, area.end.y - 16.0, 6.0, 16.0), POSTE)

## A lona azul esticada em quatro paus.
func _lona() -> void:
	var pontos := PackedVector2Array([area.position + Vector2(4, 2), Vector2(area.end.x - 6, area.position.y + 6),
		area.end - Vector2(4, 8), Vector2(area.position.x + 8, area.end.y - 4)])
	draw_colored_polygon(pontos, Color("2f5d9a"))
	for k in 4:
		var a := pontos[0].lerp(pontos[1], (k + 1) / 5.0)
		var b := pontos[3].lerp(pontos[2], (k + 1) / 5.0)
		draw_line(a, b, Color("456fae"), 2.0)
	var fechado := PackedVector2Array(pontos)
	fechado.append(pontos[0])
	draw_polyline(fechado, Telhado.CONTORNO, 1.0)
	for p in pontos:
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), POSTE.darkened(0.2))

## O toldo da fachada: listras ao longo da queda, o babado recortado na beira
## e o nome numa faixa clara no meio.
func _toldo() -> void:
	var largura := 14.0
	var x := area.position.x
	var k := 0
	while x < area.end.x:
		var cor: Color = listras[k % listras.size()] if not listras.is_empty() else Color("a83a32")
		var r := Rect2(x, area.position.y, minf(largura, area.end.x - x), area.size.y)
		draw_rect(r, cor)
		# A queda para fora: a ponta de fora mais escura.
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y * 0.35), Color(0, 0, 0, 0.14))
		# O babado: meia-lua na beira de fora.
		draw_circle(Vector2(r.get_center().x, area.position.y), largura / 2.0, cor.darkened(0.12))
		x += largura
		k += 1
	draw_rect(Rect2(area.position.x, area.end.y - 3.0, area.size.x, 3.0), Color(0, 0, 0, 0.3))
	draw_rect(area, Telhado.CONTORNO, false, 1.0)
	# Os bracos de ferro que seguram o toldo.
	var b := area.position.x + 40.0
	while b < area.end.x - 20.0:
		draw_line(Vector2(b, area.end.y), Vector2(b, area.position.y + 4.0), Color(0.15, 0.15, 0.15, 0.6), 1.0)
		b += 130.0
	if texto != "":
		var fonte := ThemeDB.fallback_font
		var corpo := 22
		var escala := 0.5
		var w := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x * escala
		var centro := Vector2(area.position.x + minf(area.size.x * 0.32, 300.0), area.get_center().y + 2.0)
		var placa := Rect2(centro - Vector2(w / 2.0 + 8.0, 10.0), Vector2(w + 16.0, 20.0))
		draw_rect(Rect2(placa.position + Vector2(2, 2), placa.size), Color(0, 0, 0, 0.3))
		draw_rect(placa, Color("ebe4d0"))
		draw_rect(placa, Telhado.CONTORNO, false, 1.0)
		draw_set_transform(Vector2(placa.position.x + 8.0, placa.position.y + 15.0 - position.y), 0.0, Vector2.ONE * escala)
		draw_string(fonte, Vector2(1.0, 1.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, Color(0, 0, 0, 0.25))
		draw_string(fonte, Vector2.ZERO, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, Color("8f2a24"))
		draw_set_transform(Vector2(0.0, -position.y))
