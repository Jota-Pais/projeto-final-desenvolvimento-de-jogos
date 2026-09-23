extends Node2D
## Desenha o comodo atual na tela baixa da casa - greybox, feito de poligono e
## traco, ate a arte existir.
##
## **Quando a arte chegar, este arquivo sai do caminho sozinho:** se existir
## `res://casa/arte/<comodo>.png` (sala.png, cozinha.png...), ela e desenhada no
## lugar do greybox, esticada para a tela inteira. Pintar em 640 x 360, em cor
## normal - o filtro.gdshader e quem leva para a noite. Os retangulos de clique
## continuam vindo de comodos.gd, entao o objeto pintado tem que cair onde o
## retangulo dele esta.
##
## O traco e tremido de proposito (`_traco`): e a mao que desenhou, e e o que
## aproxima o greybox do desenho torto de *No, I'm Not a Human*. Ela, no porao,
## "ferve" - o traco muda algumas vezes por segundo, como animacao feita a mao.
##
## Coordenadas na grade de 320 x 180 (comodos.gd). O no e escalado 2x dentro de
## um SubViewport de 640 x 360: o desenho fica chunky e a arte pintada ganha o
## dobro de definicao.

const Comodos := preload("res://casa/comodos.gd")
const F := Comodos.FUNDO

var comodo := "entrada"
## O id do ponto sob o mouse, para acender.
var destaque := ""
## A parte do corpo dela em close, ou vazio.
var close_up := ""
var estagio := 0
var olho_magico := false
var zumbis_na_rua := 1
var documentos := 0
var lidos := 0
var tv_ligada := false

var _t := 0.0

const PRETO := Color("050706")
const TRACO := Color(0.05, 0.05, 0.04, 0.85)

const PELE := [Color("c7a58c"), Color("b59f8a"), Color("98a08a"), Color("7d8f80")]

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if olho_magico:
		_olho_magico()
		return
	var arte := "res://casa/arte/%s.png" % comodo
	if ResourceLoader.exists(arte):
		draw_texture_rect(load(arte), Rect2(Vector2.ZERO, Comodos.TELA), false)
	else:
		match comodo:
			"entrada": _entrada()
			"sala": _sala()
			"cozinha": _cozinha()
			"quarto": _quarto()
			"porao": _porao()
	_destaque()
	if close_up != "":
		_close_up()

# --------------------------------------------------------------- utilitarios

## Ruido deterministico: o mesmo ponto sempre da o mesmo numero.
func _h(x: float, y: float, s := 0) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + float(s) * 37.719) * 43758.5453, 1.0)

func _poli(pts: Array, cor: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), cor)

## Um traco a mao: a reta quebrada em pedacos e cada emenda deslocada um
## pouco para o lado.
func _traco(a: Vector2, b: Vector2, cor := TRACO, largura := 1.0, semente := 0, tremor := 0.6) -> void:
	var n := maxi(1, int(a.distance_to(b) / 5.0))
	var normal := (b - a).orthogonal().normalized()
	var pts := PackedVector2Array()
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if i > 0 and i < n:
			p += normal * (_h(p.x, p.y, semente) - 0.5) * 2.0 * tremor
		pts.append(p)
	draw_polyline(pts, cor, largura)

func _contorno_de(pts: Array, cor := TRACO, largura := 1.0, semente := 0, tremor := 0.6) -> void:
	for i in pts.size():
		_traco(pts[i], pts[(i + 1) % pts.size()], cor, largura, semente + i, tremor)

func _contorno(r: Rect2, cor := TRACO, largura := 1.0, semente := 0) -> void:
	_contorno_de([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)],
		cor, largura, semente)

func _bloco(r: Rect2, cor: Color, semente := 0) -> void:
	draw_rect(r, cor)
	_contorno(r, TRACO, 1.0, semente)

## Sujeira: pontos e manchas espalhados, sempre nos mesmos lugares.
func _manchas(r: Rect2, cor: Color, quantas: int, semente: int) -> void:
	for i in quantas:
		var x := r.position.x + _h(i, 1.3, semente) * r.size.x
		var y := r.position.y + _h(i, 7.1, semente) * r.size.y
		var t := 1.0 + floorf(_h(i, 3.7, semente) * 2.6)
		draw_rect(Rect2(x, y, t, t), cor)

func _elipse(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _brilho(c: Vector2, raio: float, cor: Color, camadas := 6) -> void:
	for k in camadas:
		draw_circle(c, raio * (1.0 - float(k) / camadas), Color(cor, cor.a / camadas * 1.6))

# -------------------------------------------------------------------- a caixa

## As quatro paredes, o teto e o chao. `tabuas` = chao de madeira; sem elas o
## chao e liso (cimento, azulejo).
func _caixa(parede: Color, teto: Color, chao: Color, semente: int, tabuas := true) -> void:
	var tl := F.position
	var tr := Vector2(F.end.x, F.position.y)
	var bl := Vector2(F.position.x, F.end.y)
	var br := F.end
	_poli([Vector2(0, 0), Vector2(320, 0), tr, tl], teto)
	_poli([Vector2(0, 0), tl, bl, Vector2(0, 180)], parede.darkened(0.22))
	_poli([Vector2(320, 0), Vector2(320, 180), br, tr], parede.darkened(0.3))
	draw_rect(F, parede)
	_poli([bl, br, Vector2(320, 180), Vector2(0, 180)], chao)

	# Papel de parede.
	for x in range(int(F.position.x) + 5, int(F.end.x), 9):
		draw_line(Vector2(x, F.position.y), Vector2(x, F.end.y), parede.lightened(0.07), 1.0)
	for i in 9:
		var x := 4.0 + i * 9.0
		var yt := 36.0 * x / 80.0
		var yb := 180.0 - 48.0 * x / 80.0
		draw_line(Vector2(x, yt), Vector2(x, yb), parede.darkened(0.32), 1.0)
		draw_line(Vector2(320.0 - x, yt), Vector2(320.0 - x, yb), parede.darkened(0.4), 1.0)

	# Chao convergindo para o ponto de fuga.
	var linhas := 13 if tabuas else 9
	for i in linhas:
		var p := Vector2(-80.0 + i * 480.0 / (linhas - 1), 180)
		var q := p.lerp(Comodos.PONTO_DE_FUGA, 0.5)
		draw_line(p, q, chao.darkened(0.4), 1.0)
	if not tabuas:
		for y in [138.0, 147.0, 160.0]:
			draw_line(Vector2(0, y), Vector2(320, y), chao.darkened(0.3), 1.0)

	# Rodape e cantos.
	draw_line(bl + Vector2(0, -2), br + Vector2(0, -2), parede.darkened(0.5), 2.0)
	_traco(Vector2(0, 0), tl, TRACO, 1.0, semente)
	_traco(Vector2(320, 0), tr, TRACO, 1.0, semente + 1)
	_traco(Vector2(0, 180), bl, TRACO, 1.0, semente + 2)
	_traco(Vector2(320, 180), br, TRACO, 1.0, semente + 3)
	_contorno(F, TRACO, 1.0, semente + 4)

	_manchas(F, parede.darkened(0.35), 70, semente)
	_manchas(Rect2(0, 132, 320, 48), chao.darkened(0.45), 60, semente + 9)
	_manchas(Rect2(0, 0, 80, 170), parede.darkened(0.5), 35, semente + 17)

## A luz do teto: uma lampada so no meio da casa.
func _luz_do_teto(c := Vector2(160, 14), forca := 0.22) -> void:
	_brilho(c, 110.0, Color(1.0, 0.95, 0.8, forca), 5)

## O vao da parede do fundo, para outro comodo.
func _vao(r: Rect2, semente: int) -> void:
	draw_rect(r, Color("0c0f0d"))
	_poli([Vector2(r.position.x, r.end.y), r.end,
		Vector2(r.end.x - 4, r.end.y - 10), Vector2(r.position.x + 4, r.end.y - 10)], Color("1a1c18"))
	draw_rect(r.grow(1.5), Color("3b2c1f"), false, 2.0)
	_contorno(r.grow(2.5), TRACO, 1.0, semente)

## A porta na parede da esquerda: aberta (um vao escuro) ou fechada.
func _porta_da_esquerda(cor: Color, aberta: bool, semente: int) -> void:
	var x0 := 16.0
	var x1 := 62.0
	var yb0 := 180.0 - 48.0 * x0 / 80.0
	var yt0 := 36.0 * x0 / 80.0
	var yb1 := 180.0 - 48.0 * x1 / 80.0
	var yt1 := 36.0 * x1 / 80.0
	var a := Vector2(x0, yb0 - (yb0 - yt0) * 0.72)
	var b := Vector2(x1, yb1 - (yb1 - yt1) * 0.72)
	var c := Vector2(x1, yb1)
	var d := Vector2(x0, yb0)
	_poli([a, b, c, d], Color("0b0d0b") if aberta else cor)
	if not aberta:
		# Tabuas pregadas na diagonal.
		for k in 3:
			var y := 0.25 + k * 0.25
			var e := a.lerp(d, y)
			var f := b.lerp(c, y - 0.08)
			_traco(e, f, cor.darkened(0.55), 3.0, semente + k, 0.4)
	_contorno_de([a, b, c, d], TRACO, 1.5, semente)

# ----------------------------------------------------------------- os comodos

func _entrada() -> void:
	_caixa(Color("6e6a52"), Color("34332b"), Color("4b3b2c"), 11)
	_luz_do_teto()
	_porta_da_esquerda(Color("4a3a2a"), true, 12)

	var porta := Rect2(136, 52, 48, 80)
	draw_rect(porta.grow(3), Color("2f241a"))
	_bloco(porta, Color("5b4632"), 13)
	_contorno(Rect2(142, 60, 36, 28), TRACO, 1.0, 14)
	_contorno(Rect2(142, 94, 36, 32), TRACO, 1.0, 15)
	draw_circle(Vector2(177, 96), 1.6, Color("b8a060"))
	# Trancas e corrente: a casa se fecha por dentro.
	draw_rect(Rect2(173, 78, 6, 3), Color("8a8676"))
	draw_rect(Rect2(173, 86, 6, 3), Color("8a8676"))
	for i in 5:
		draw_circle(Vector2(166 + i * 2.2, 72 + i * 1.0), 0.9, Color("9a9686"))
	# O olho magico.
	draw_circle(Vector2(160, 75), 2.6, Color("1a1a18"))
	draw_circle(Vector2(160, 75), 1.1, Color("c9c6a8"))

	_poli([Vector2(130, 134), Vector2(190, 134), Vector2(200, 146), Vector2(120, 146)], Color("3c3a30"))
	# Cabideiro, com um casaco.
	_traco(Vector2(226, 58), Vector2(226, 134), Color("2a2018"), 2.0, 16)
	_poli([Vector2(220, 64), Vector2(233, 64), Vector2(236, 104), Vector2(217, 104)], Color("3e4638"))
	_contorno_de([Vector2(220, 64), Vector2(233, 64), Vector2(236, 104), Vector2(217, 104)], TRACO, 1.0, 17)

func _sala() -> void:
	_caixa(Color("6a5f4e"), Color("302c26"), Color("46382a"), 21)
	_luz_do_teto()
	_vao(Rect2(92, 58, 30, 74), 22)
	_vao(Rect2(198, 58, 30, 74), 23)
	_porta_da_esquerda(Color("4a3a2a"), false, 24)
	draw_circle(Vector2(56, 112), 2.2, Color("9a9070"))  # o cadeado do porao

	# Janela tapada com tabua.
	var janela := Rect2(138, 50, 44, 34)
	_bloco(janela, Color("10201c"), 25)
	for k in 3:
		_traco(Vector2(janela.position.x - 3, janela.position.y + 6 + k * 11),
			Vector2(janela.end.x + 3, janela.position.y + 10 + k * 10), Color("4f3b28"), 4.0, 26 + k, 0.4)

	# Mesinha e radio.
	_bloco(Rect2(140, 112, 40, 6), Color("4a3826"), 27)
	_traco(Vector2(143, 118), Vector2(143, 132), Color("3a2a1c"), 2.0, 28)
	_traco(Vector2(177, 118), Vector2(177, 132), Color("3a2a1c"), 2.0, 29)
	_bloco(Rect2(148, 100, 26, 12), Color("3b3027"), 30)
	for i in 4:
		for j in 2:
			draw_rect(Rect2(151 + i * 3, 103 + j * 3, 1, 1), Color("15110d"))
	draw_circle(Vector2(168, 106), 2.5, Color("8a7a58"))
	_traco(Vector2(172, 100), Vector2(182, 86), Color("7a7a70"), 1.0, 31, 0.2)

	# A televisao de tubo.
	_bloco(Rect2(244, 126, 52, 16), Color("5a4630"), 32)
	var tv := Rect2(240, 90, 60, 38)
	_bloco(tv, Color("5a5c54"), 33)
	var tela := Rect2(246, 95, 40, 28)
	draw_rect(tela, Color("121614"))
	if tv_ligada:
		draw_rect(tela, Color("6f7c78"))
		for i in 90:
			draw_rect(Rect2(tela.position.x + randf() * tela.size.x,
				tela.position.y + randf() * tela.size.y, 1, 1), Color(0, 0, 0, 0.7))
		var faixa := fposmod(_t * 18.0, tela.size.y)
		draw_rect(Rect2(tela.position.x, tela.position.y + faixa, tela.size.x, 2), Color(1, 1, 1, 0.25))
		draw_rect(Rect2(tela.position.x + 4, tela.position.y + 5, 18, 3), Color("d8e0d8"))
		_brilho(tela.get_center(), 34.0, Color(0.8, 1.0, 0.95, 0.2))
	else:
		_traco(Vector2(249, 99), Vector2(260, 97), Color(1, 1, 1, 0.18), 1.0, 34)
	_contorno(tela, TRACO, 1.0, 35)
	draw_circle(Vector2(293, 100), 1.8, Color("15130f"))
	draw_circle(Vector2(293, 108), 1.8, Color("15130f"))
	_traco(Vector2(262, 90), Vector2(252, 76), Color("5a5a52"), 1.0, 36, 0.2)
	_traco(Vector2(268, 90), Vector2(280, 78), Color("5a5a52"), 1.0, 37, 0.2)

	# Tapete e sofa.
	_poli([Vector2(96, 142), Vector2(226, 142), Vector2(250, 166), Vector2(70, 166)], Color("4d2f2a"))
	_manchas(Rect2(80, 142, 160, 24), Color("2a1a18"), 25, 38)
	var encosto := Rect2(70, 118, 100, 20)
	_bloco(encosto, Color("4c5646"), 39)
	_bloco(Rect2(70, 136, 100, 22), Color("566250"), 40)
	_bloco(Rect2(62, 124, 12, 34), Color("48523f"), 41)
	_bloco(Rect2(166, 124, 12, 34), Color("48523f"), 42)
	_traco(Vector2(120, 138), Vector2(120, 156), TRACO, 1.0, 43)
	_manchas(Rect2(74, 120, 92, 36), Color("39402f"), 30, 44)

func _cozinha() -> void:
	_caixa(Color("7a7560"), Color("35352c"), Color("5a5a52"), 51, false)
	_luz_do_teto(Vector2(150, 14), 0.2)
	# Azulejo na metade de baixo do fundo.
	for y in range(100, 132, 6):
		draw_line(Vector2(F.position.x, y), Vector2(F.end.x, y), Color("5f5c4c"), 1.0)
	for x in range(int(F.position.x), int(F.end.x), 7):
		draw_line(Vector2(x, 100), Vector2(x, 132), Color("5f5c4c"), 1.0)

	# Geladeira velha.
	var geladeira := Rect2(86, 46, 36, 86)
	_bloco(geladeira, Color("b3b2a2"), 52)
	_traco(Vector2(86, 72), Vector2(122, 72), TRACO, 1.0, 53)
	_traco(Vector2(117, 56), Vector2(117, 66), Color("5a5a50"), 2.0, 54, 0.2)
	_traco(Vector2(117, 80), Vector2(117, 100), Color("5a5a50"), 2.0, 55, 0.2)
	draw_rect(Rect2(92, 78, 5, 4), Color("a84a3a"))
	draw_rect(Rect2(100, 84, 4, 5), Color("4a6a8a"))
	_manchas(geladeira, Color("7a6a4a"), 22, 56)

	# O quadro da pesquisa: um papel por documento que chegou em casa.
	var quadro := Rect2(130, 50, 40, 34)
	draw_rect(quadro.grow(2), Color("3a2a1a"))
	_bloco(quadro, Color("7a5a38"), 57)
	_manchas(quadro, Color("5a4028"), 30, 58)
	var papeis: Array[Vector2] = []
	for i in documentos:
		var p := Vector2(133 + (i % 3) * 12.5, 53 + int(i / 3) * 15)
		papeis.append(p + Vector2(4, 5))
		_bloco(Rect2(p, Vector2(9, 11)), Color("d8d2bc"), 59 + i)
		for k in 3:
			draw_line(p + Vector2(2, 3 + k * 2.5), p + Vector2(7, 3 + k * 2.5), Color("8a8474"), 1.0)
		if i < lidos:
			_traco(p + Vector2(1, 9), p + Vector2(8, 2), Color("9a2a22"), 1.0, 70 + i, 0.2)
		draw_circle(p + Vector2(4.5, 1), 1.0, Color("b02a22"))
	for i in papeis.size() - 1:
		_traco(papeis[i], papeis[i + 1], Color("a02a22"), 1.0, 80 + i, 0.3)

	# Janela com fita em X, pia e bancada.
	var janela := Rect2(184, 54, 40, 32)
	_bloco(janela, Color("10201c"), 60)
	_traco(janela.position, janela.end, Color("b8b090"), 2.0, 61, 0.3)
	_traco(Vector2(janela.end.x, janela.position.y), Vector2(janela.position.x, janela.end.y), Color("b8b090"), 2.0, 62, 0.3)
	_bloco(Rect2(176, 102, 64, 30), Color("4d4234"), 63)
	_bloco(Rect2(174, 98, 68, 5), Color("8a8676"), 64)
	_traco(Vector2(208, 102), Vector2(208, 132), TRACO, 1.0, 65)
	_traco(Vector2(200, 98), Vector2(200, 90), Color("9a9a90"), 2.0, 66, 0.2)
	_traco(Vector2(200, 90), Vector2(206, 90), Color("9a9a90"), 2.0, 67, 0.2)

	# A mesa, com os papeis e os vidros da pesquisa.
	var mesa := Rect2(104, 134, 112, 12)
	_bloco(mesa, Color("5a4430"), 68)
	_traco(Vector2(110, 146), Vector2(106, 176), Color("3a2a1c"), 3.0, 69, 0.3)
	_traco(Vector2(210, 146), Vector2(214, 176), Color("3a2a1c"), 3.0, 71, 0.3)
	for i in mini(documentos, 6):
		var p := Vector2(112 + i * 11, 134 + (i % 2) * 2)
		_poli([p, p + Vector2(9, -1), p + Vector2(10, 5), p + Vector2(1, 6)], Color("cfc8b0"))
	for i in 3:
		var base := Vector2(180 + i * 9, 134)
		_poli([base + Vector2(-3, 0), base + Vector2(3, 0), base + Vector2(1.5, -7), base + Vector2(1.5, -11),
			base + Vector2(-1.5, -11), base + Vector2(-1.5, -7)], Color("7aa89a"))
		_contorno_de([base + Vector2(-3, 0), base + Vector2(3, 0), base + Vector2(1.5, -11), base + Vector2(-1.5, -11)],
			TRACO, 1.0, 72 + i, 0.2)

func _quarto() -> void:
	_caixa(Color("686252"), Color("2e2b25"), Color("463829"), 81)
	_luz_do_teto(Vector2(240, 104), 0.25)

	# A foto na parede.
	var foto := Rect2(196, 58, 20, 26)
	draw_rect(foto.grow(2), Color("3a2a1a"))
	_bloco(foto, Color("8a8270"), 82)
	draw_circle(Vector2(202, 68), 3.0, Color("4a4234"))
	draw_circle(Vector2(210, 67), 3.0, Color("4a4234"))
	_poli([Vector2(197, 84), Vector2(215, 84), Vector2(213, 74), Vector2(199, 74)], Color("4a4234"))

	# Criado-mudo e abajur aceso.
	_bloco(Rect2(232, 112, 22, 20), Color("4a3826"), 83)
	_poli([Vector2(236, 100), Vector2(250, 100), Vector2(253, 110), Vector2(233, 110)], Color("c8b48a"))
	_traco(Vector2(243, 110), Vector2(243, 112), Color("2a2018"), 2.0, 84)
	_brilho(Vector2(243, 106), 30.0, Color(1.0, 0.9, 0.7, 0.35))

	# A cama de casal. Um lado dela arrumado demais.
	_bloco(Rect2(84, 94, 112, 26), Color("4a3524"), 85)
	var colchao := [Vector2(72, 116), Vector2(208, 116), Vector2(224, 160), Vector2(56, 160)]
	_poli(colchao, Color("6d6a5e"))
	_contorno_de(colchao, TRACO, 1.0, 86)
	_bloco(Rect2(92, 110, 42, 12), Color("a8a494"), 87)
	_bloco(Rect2(146, 108, 42, 12), Color("b2ae9e"), 88)
	for k in 4:
		_traco(Vector2(70 + k * 10, 128 + k * 7), Vector2(150 + k * 14, 124 + k * 9), Color("55524a"), 1.0, 89 + k, 0.8)
	_manchas(Rect2(64, 118, 150, 40), Color("54524a"), 30, 93)

	# Janela tapada na parede da esquerda.
	var janela := [Vector2(26, 50), Vector2(54, 58), Vector2(54, 100), Vector2(26, 104)]
	_poli(janela, Color("0f1c18"))
	_contorno_de(janela, TRACO, 1.0, 94)
	for k in 3:
		_traco(Vector2(22, 60 + k * 14), Vector2(58, 66 + k * 12), Color("4f3b28"), 4.0, 95 + k, 0.4)

func _porao() -> void:
	_caixa(Color("4c4f4a"), Color("262824"), Color("3a3b36"), 101, false)
	# A lampada pelada, pendurada no fio.
	_traco(Vector2(160, 0), Vector2(160, 18), Color("1a1a18"), 1.0, 102, 0.3)
	_brilho(Vector2(160, 21), 130.0, Color(1.0, 0.95, 0.75, 0.3))
	draw_circle(Vector2(160, 21), 3.0, Color("f0e8c0"))
	# Infiltracao e rachadura.
	_manchas(Rect2(84, 36, 60, 40), Color("343832"), 40, 103)
	_traco(Vector2(200, 36), Vector2(214, 70), TRACO, 1.0, 104, 1.2)
	_traco(Vector2(214, 70), Vector2(208, 96), TRACO, 1.0, 105, 1.2)

	# A escada que desce da sala, na esquerda.
	for k in 8:
		var y := 40.0 + k * 14.0
		var x := k * 7.0
		_bloco(Rect2(x, y, 58 - x * 0.4, 5), Color("4a3a2a"), 106 + k)

	# Do lado de dentro da grade, ela. A grade vem depois, por cima.
	_poli(_elipse(Vector2(160, 136), 26, 5), Color(0, 0, 0, 0.45))
	draw_circle(Vector2(146, 134), 2.0, Color("555a55"))  # a tigela
	# Desenhada 1,35x em volta dos pes: ela e o centro do quadro, como as
	# visitas na porta da referencia. O retangulo de clique (comodos.gd) e este
	# mesmo, ja escalado.
	var pes := Vector2(160, 134)
	draw_set_transform(pes * (1.0 - ESCALA_DELA), 0.0, Vector2.ONE * ESCALA_DELA)
	_ela(Rect2(136, 56, 48, 78))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# A corrente, do chao ate o tornozelo.
	var elo := Vector2(118, 138)
	for i in 10:
		var p := elo.lerp(Vector2(152, 132), float(i) / 9.0) + Vector2(0, sin(i * 1.3) * 1.2)
		draw_arc(p, 1.4, 0, TAU, 8, Color("8a8a80"), 1.0)

	var grade := Rect2(96, 38, 128, 94)
	draw_rect(Rect2(grade.position.x, grade.position.y, grade.size.x, 3), Color("1c1c1a"))
	draw_rect(Rect2(grade.position.x, grade.end.y - 3, grade.size.x, 3), Color("1c1c1a"))
	var x := grade.position.x
	while x <= grade.end.x:
		draw_line(Vector2(x, grade.position.y), Vector2(x, grade.end.y), Color("161614"), 2.0)
		draw_line(Vector2(x - 1, grade.position.y), Vector2(x - 1, grade.end.y), Color(1, 1, 1, 0.08), 1.0)
		x += 9.0
	draw_rect(Rect2(186, 82, 6, 7), Color("8a8060"))  # cadeado

const ESCALA_DELA := 1.35

## Ela, desenhada a traco que ferve. Quanto mais adiante no estagio, mais
## curvada, mais cinza, e os olhos acendem.
func _ela(r: Rect2) -> void:
	var s := estagio
	var ferve := int(_t * 5.0)
	var pele: Color = PELE[s]
	var cx := r.get_center().x
	var curva := s * 3.0
	var topo := r.position.y + curva

	var ombro := topo + 22.0
	var corpo := [
		Vector2(cx - 13, ombro), Vector2(cx + 13, ombro + 1),
		Vector2(cx + 10, ombro + 28), Vector2(cx + 13, r.end.y - 14),
		Vector2(cx - 13, r.end.y - 14), Vector2(cx - 10, ombro + 28),
	]
	# Pernas e bracos antes do vestido, para o vestido cobrir a emenda.
	_traco(Vector2(cx - 5, r.end.y - 16), Vector2(cx - 6, r.end.y - 2), pele.darkened(0.2), 3.0, ferve, 0.8)
	_traco(Vector2(cx + 5, r.end.y - 16), Vector2(cx + 7, r.end.y - 2), pele.darkened(0.2), 3.0, ferve + 1, 0.8)
	_poli(corpo, Color("3c3434"))
	_manchas(Rect2(cx - 12, ombro, 24, 40), Color("241e1e"), 18, ferve)
	_contorno_de(corpo, TRACO, 1.0, ferve + 2, 0.9)
	var mao_e := Vector2(cx - 17 - s, ombro + 34 + s * 2)
	var mao_d := Vector2(cx + 17 + s, ombro + 33 + s * 2)
	_traco(Vector2(cx - 12, ombro + 2), mao_e, pele, 3.0, ferve + 3, 0.9)
	_traco(Vector2(cx + 12, ombro + 2), mao_d, pele, 3.0, ferve + 4, 0.9)
	draw_circle(mao_e, 2.2, pele)
	draw_circle(mao_d, 2.2, pele)

	var cabeca := Vector2(cx + s * 1.5, topo + 11)
	var rosto := _elipse(cabeca, 7.0, 9.0, 16)
	for i in rosto.size():
		rosto[i] += Vector2(_h(i, ferve, 5) - 0.5, _h(i, ferve, 6) - 0.5) * 0.8
	_poli(Array(rosto), pele)
	_contorno_de(Array(rosto), TRACO, 1.0, ferve + 5, 0.4)
	# Cabelo caindo na cara.
	for k in 11:
		var de := cabeca + Vector2(-8 + k * 1.6, -8 + abs(k - 5) * 0.4)
		var ate := de + Vector2((k - 5) * 0.8, 20 + _h(k, 2, ferve) * 8)
		_traco(de, ate, Color("241e18"), 1.0, ferve + 10 + k, 0.9)
	# Olheira funda: e o que faz o rosto ler de longe, atras da grade.
	_poli(Array(_elipse(cabeca + Vector2(-3, -0.5), 2.4, 1.8, 8)), pele.darkened(0.55))
	_poli(Array(_elipse(cabeca + Vector2(3, -0.5), 2.4, 1.8, 8)), pele.darkened(0.55))
	var olho := Color("1a1614") if s < 2 else Color("e0e4cc")
	draw_rect(Rect2(cabeca + Vector2(-4, -1), Vector2(2, 1)), olho)
	draw_rect(Rect2(cabeca + Vector2(2, -1), Vector2(2, 1)), olho)
	if s >= 2:
		_brilho(cabeca + Vector2(-3, -0.5), 3.0, Color(0.9, 1.0, 0.85, 0.5))
		_brilho(cabeca + Vector2(3, -0.5), 3.0, Color(0.9, 1.0, 0.85, 0.5))
	if s >= 3:
		draw_rect(Rect2(cabeca + Vector2(-2, 4), Vector2(4, 2)), Color("140808"))
	else:
		draw_line(cabeca + Vector2(-2, 5), cabeca + Vector2(2, 5), Color("4a2a24"), 1.0)

# -------------------------------------------------------------- destaque

## O que acende sob o mouse. O vao de voltar vira uma seta; o resto ganha
## contorno claro, tremido como o resto do desenho.
func _destaque() -> void:
	for ponto in Comodos.COMODOS[comodo]["pontos"]:
		var r: Rect2 = ponto["rect"]
		var aceso: bool = ponto["id"] == destaque
		if r == Comodos.VOLTAR:
			var c := r.get_center() + Vector2(0, 2)
			var cor := Color(0.92, 1.0, 0.96, 0.9 if aceso else 0.28)
			draw_polyline(PackedVector2Array([c + Vector2(-9, -3), c + Vector2(0, 2), c + Vector2(9, -3)]), cor, 1.5)
			continue
		if not aceso:
			continue
		draw_rect(r.grow(1), Color(0.9, 1.0, 0.95, 0.07))
		_contorno(r.grow(1.5), Color(0.92, 1.0, 0.96, 0.85), 1.0, 99)

# ------------------------------------------------------------- olho magico

## A rua pela lente do olho magico: o bairro de noite e quantos deles estao
## la fora. Nao e a rua de verdade - e so o que da para ver da porta.
func _olho_magico() -> void:
	draw_rect(Rect2(Vector2.ZERO, Comodos.TELA), PRETO)
	var c := Vector2(160, 90)
	var raio := 70.0
	draw_circle(c, raio, Color("15231f"))
	# Casas do outro lado da rua.
	for i in 7:
		var x := 84.0 + i * 24.0
		var alto := 16.0 + _h(i, 1, 3) * 14.0
		_poli([Vector2(x, 104 - alto), Vector2(x + 11, 94 - alto), Vector2(x + 22, 104 - alto),
			Vector2(x + 22, 104), Vector2(x, 104)], Color("0c1411"))
		if _h(i, 2, 3) > 0.6:
			draw_rect(Rect2(x + 7, 104 - alto * 0.6, 4, 4), Color("2c3a30"))
	# A rua e a calcada.
	_poli([Vector2(40, 180), Vector2(280, 180), Vector2(196, 104), Vector2(124, 104)], Color("262a24"))
	_poli([Vector2(60, 104), Vector2(260, 104), Vector2(270, 112), Vector2(50, 112)], Color("30342c"))
	# O poste.
	_traco(Vector2(214, 110), Vector2(214, 50), Color("0a0e0c"), 2.0, 3, 0.3)
	_poli([Vector2(211, 52), Vector2(217, 52), Vector2(246, 120), Vector2(182, 120)], Color(0.85, 0.95, 0.75, 0.08))
	draw_circle(Vector2(214, 52), 2.0, Color("e0e8c0"))
	# Eles.
	for i in zumbis_na_rua:
		var fundo := _h(i, 4, 9)
		var p := Vector2(96.0 + _h(i, 5, 9) * 128.0, 106.0 + fundo * 42.0)
		var e := lerpf(0.45, 1.25, fundo)
		var cor := Color("070a08")
		_poli([p + Vector2(-3, 0) * e, p + Vector2(3, 0) * e, p + Vector2(2.5, -11) * e, p + Vector2(-2.5, -11) * e], cor)
		draw_circle(p + Vector2(0.8, -13) * e, 2.2 * e, cor)
		_traco(p + Vector2(-2.5, -10) * e, p + Vector2(-4.5, -3) * e, cor, maxf(1.0, e), i, 0.3)
		_traco(p + Vector2(2.5, -10) * e, p + Vector2(5, -4) * e, cor, maxf(1.0, e), i + 50, 0.3)
	# A varanda, em primeiro plano.
	for k in 5:
		draw_line(Vector2(0, 150 + k * 7), Vector2(320, 150 + k * 7), Color("3a3228"), 2.0)
	# A lente: borda escura que fecha em circulo, e o resto preto.
	for k in 10:
		draw_arc(c, raio - k * 2.5, 0, TAU, 64, Color(0, 0, 0, 0.13), 3.0)
	draw_arc(c, raio + 60.0, 0, TAU, 96, PRETO, 120.0)

# --------------------------------------------------------------- close-up

## O quadro recortado do exame, como o de *No, I'm Not a Human*: a parte do
## corpo em close, com borda branca, ao lado dela.
const QUADRO_DO_CLOSE := Rect2(186, 24, 126, 76)

func _close_up() -> void:
	var r := QUADRO_DO_CLOSE
	draw_rect(r.grow(3), Color(0, 0, 0, 0.6))
	draw_rect(r, Color("0a0c0b"))
	match close_up:
		"olhos": _close_olhos(r)
		"dentes": _close_dentes(r)
		"pele": _close_pele(r)
		"maos": _close_maos(r)
	draw_rect(r, Color(0.92, 0.96, 0.93), false, 1.0)

func _close_olhos(r: Rect2) -> void:
	var s := estagio
	var c := r.get_center()
	draw_rect(r, PELE[s])
	_manchas(r, PELE[s].darkened(0.15), 60, 200)
	var esclera := [Color("e8e2d6"), Color("e6cfc4"), Color("d8cf8a"), Color("dcdcd0")][s] as Color
	_poli(Array(_elipse(c, 42, 17)), esclera)
	for i in 2 + s * 5:
		var a := TAU * _h(i, 1, 201)
		var de := c + Vector2(cos(a) * 41, sin(a) * 16)
		var meio := de.lerp(c, 0.4) + Vector2(_h(i, 2, 201) - 0.5, _h(i, 3, 201) - 0.5) * 8.0
		draw_polyline(PackedVector2Array([de, meio, meio.lerp(c, 0.4)]), Color(0.62, 0.16, 0.12, 0.8), 1.0)
	var iris := [Color("5a4636"), Color("54402f"), Color("7a7240"), Color("c9c9bd")][s] as Color
	draw_circle(c, 12.0, iris)
	var pupila := [4.0, 7.5, 5.5, 0.0][s] as float
	if pupila > 0.0:
		draw_circle(c, pupila, Color("0a0806"))
	draw_circle(c + Vector2(-4, -4), 1.6, Color(1, 1, 1, 0.8 if s < 3 else 0.3))
	# Palpebras.
	_poli([Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, c.y - 6),
		c + Vector2(42, -2), c + Vector2(0, -19), c + Vector2(-42, -2), Vector2(r.position.x, c.y - 6)], PELE[s])
	_traco(c + Vector2(-43, 0), c + Vector2(0, -18), TRACO, 2.0, 202, 0.4)
	_traco(c + Vector2(0, -18), c + Vector2(43, 0), TRACO, 2.0, 203, 0.4)
	_traco(c + Vector2(-42, 1), c + Vector2(0, 17), TRACO, 1.0, 204, 0.4)
	_traco(c + Vector2(0, 17), c + Vector2(42, 1), TRACO, 1.0, 205, 0.4)
	for i in 9:
		var p := c + Vector2(-32 + i * 8, -14 + abs(i - 4) * 1.5)
		_traco(p, p + Vector2(-1, -5), TRACO, 1.0, 206 + i, 0.2)

func _close_dentes(r: Rect2) -> void:
	var s := estagio
	var c := r.get_center()
	draw_rect(r, PELE[s])
	_poli(Array(_elipse(c, 50, 24)), Color("6a2a2a"))
	_poli(Array(_elipse(c, 44, 18)), Color("140606"))
	var gengiva := [Color("c77b7b"), Color("a0605e"), Color("6e4a48"), Color("4a3a38")][s] as Color
	var dente := [Color("f2eee2"), Color("e8dfc0"), Color("d4c89a"), Color("bdb591")][s] as Color
	draw_rect(Rect2(c.x - 40, c.y - 17, 80, 6), gengiva)
	draw_rect(Rect2(c.x - 40, c.y + 11, 80, 6), gengiva)
	for i in 8:
		if s >= 3 and i in [2, 5]:
			continue
		var x := c.x - 36 + i * 9
		var comprido := 11.0 + (s * 1.5 if s >= 3 else 0.0)
		_bloco(Rect2(x, c.y - 12, 8, comprido - abs(i - 3.5) * 0.8), dente, 210 + i)
		_bloco(Rect2(x + 1, c.y + 11 - (9.0 - abs(i - 3.5) * 0.6), 7, 9.0 - abs(i - 3.5) * 0.6), dente, 220 + i)
	if s >= 2:
		for i in 4:
			var x := c.x - 28 + i * 17
			_traco(Vector2(x, c.y - 11), Vector2(x + 1, c.y - 4 + _h(i, 1, 230) * 5), Color("5a0e0a"), 1.0, 231 + i, 0.3)
	_contorno_de(Array(_elipse(c, 50, 24, 20)), TRACO, 1.0, 240, 0.5)

func _close_pele(r: Rect2) -> void:
	var s := estagio
	draw_rect(r, PELE[s])
	_manchas(r, PELE[s].darkened(0.12), 120, 250)
	var veia := [Color("8a6f6a"), Color("5f5a70"), Color("3f4a5a"), Color("22303a")][s] as Color
	for k in 1 + s * 4:
		var p := Vector2(r.position.x + _h(k, 1, 251) * r.size.x, r.end.y)
		var pts := PackedVector2Array([p])
		for passo in 7:
			p += Vector2((_h(k, passo, 252) - 0.5) * 18.0, -8.0 - _h(k, passo, 253) * 6.0)
			pts.append(p)
		draw_polyline(pts, veia, 1.0 + (1.0 if s >= 2 and k % 2 == 0 else 0.0))
	if s >= 2:
		for k in 3 + s:
			var p := r.position + Vector2(_h(k, 4, 254) * r.size.x, _h(k, 5, 254) * r.size.y)
			_brilho(p, 7.0 + _h(k, 6, 254) * 8.0, Color(0.1, 0.15, 0.12, 0.45), 4)
	# A mordida, embaixo, no canto.
	var mordida := r.position + Vector2(24, r.size.y - 16)
	for i in 6:
		var a := PI + PI * i / 5.0
		draw_rect(Rect2(mordida + Vector2(cos(a) * 10, sin(a) * 5), Vector2(2, 2)), Color("5a1a14"))
	_brilho(mordida, 12.0, Color(0.5, 0.1, 0.08, 0.4 - s * 0.08), 4)

func _close_maos(r: Rect2) -> void:
	var s := estagio
	var pele: Color = PELE[s]
	draw_rect(r, Color("15120f"))
	var base := Vector2(r.get_center().x, r.end.y + 4)
	var palma := [base + Vector2(-26, 0), base + Vector2(26, 0), base + Vector2(24, -26), base + Vector2(-24, -26)]
	_poli(palma, pele)
	_contorno_de(palma, TRACO, 1.0, 260)
	var unha := [Color("e8c9b8"), Color("c9a89a"), Color("6a5a50"), Color("2e2a26")][s] as Color
	for i in 4:
		var x := base.x - 22 + i * 12
		var alto := [34.0, 40.0, 38.0, 30.0][i] as float
		var dedo := Rect2(x, base.y - 26 - alto, 10, alto + 2)
		_bloco(dedo, pele, 261 + i)
		draw_line(Vector2(x + 1, base.y - 26 - alto * 0.45), Vector2(x + 9, base.y - 26 - alto * 0.45), pele.darkened(0.3), 1.0)
		var comprimento := 5.0 + s * 2.5
		_bloco(Rect2(x + 1.5, dedo.position.y - comprimento + 5, 7, comprimento), unha, 270 + i)
		if s >= 2:
			draw_rect(Rect2(x + 1.5, dedo.position.y + 4, 7, 1.5), Color("1a1008"))
		if s >= 1:
			draw_rect(Rect2(x, dedo.position.y + 5, 10, 5), Color(0.2, 0.18, 0.2, 0.25 * s))
	_traco(base + Vector2(-26, -12), base + Vector2(-40, -34), pele, 8.0, 280, 0.5)
