extends Node2D
## Desenha o comodo atual na tela baixa da casa: a foto da equipe
## (`res://casa/arte/<comodo>.png`, 1280 x 720, cortada em 16:9 por
## design/casa_fotos.js) e, por cima, o que a foto nao tem ou o que muda
## durante a noite - o olho magico, o radio, a TV ligada, os papeis da
## pesquisa, ela no quarto -, o destaque sob o mouse e o close do exame. A foto
## entra em cor normal; o filtro.gdshader e quem leva para a noite.
##
## Ate 16/10/2026 havia aqui um greybox de poligono e traco para cada comodo;
## com as seis fotos no lugar ele saiu. Sem a foto de um comodo a tela fica
## preta, e o clique continua funcionando.
##
## O traco e tremido de proposito (`_traco`): e a mao que desenhou, e e o que
## aproxima o desenho do traco torto de *No, I'm Not a Human*. Ela, no quarto,
## "ferve" - o traco muda algumas vezes por segundo, como animacao feita a mao.
##
## Coordenadas na grade de 320 x 180 (comodos.gd). O no e escalado 4x dentro de
## um SubViewport de 1280 x 720: a foto entra 1:1, e o traco tem na tela a
## mesma grossura de quando era 2x em 640 x 360, esticado 2x.

const Comodos := preload("res://casa/comodos.gd")

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
## As fotos ja carregadas, por comodo. Precisa segurar a textura: o _draw so
## registra o comando, e uma textura que ninguem segura e liberada no fim dele
## - e a foto sai branca.
var _fotos := {}

const PRETO := Color("050706")
const TRACO := Color(0.05, 0.05, 0.04, 0.85)

const PELE := [Color("c7a58c"), Color("b59f8a"), Color("98a08a"), Color("7d8f80")]

## Nearest: as fotos entram 1:1, mas ela (um boneco de 36 x 52) e ampliada ate a
## grade de blocos das fotos e tem que sair em bloco, nao borrada.
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if olho_magico:
		_olho_magico()
		return
	if not _fotos.has(comodo):
		var arte := "res://casa/arte/%s.png" % comodo
		_fotos[comodo] = load(arte) if ResourceLoader.exists(arte) else null
	if _fotos[comodo]:
		draw_texture_rect(_fotos[comodo], Rect2(Vector2.ZERO, Comodos.TELA), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Comodos.TELA), PRETO)
	match comodo:
		"entrada": _na_entrada()
		"sala_tv": _na_sala()
		"cozinha": _na_cozinha()
		"quarto": _no_quarto()
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

# ------------------------------------------------- por cima das fotos

## O olho magico na porta da rua. A foto nao tem: e um ponto de metal no meio
## da folha, na altura do olho.
func _na_entrada() -> void:
	var c := Comodos.OLHO_MAGICO
	draw_circle(c, 1.9, Color("15120f"))
	draw_circle(c, 1.2, Color("7d7867"))
	draw_circle(c, 0.6, Color("0d0c0a"))
	draw_circle(c + Vector2(-0.5, -0.5), 0.35, Color("d8d3bb"))

## A sala vista da TV: o radio no rack (a foto nao tem radio) e, com a TV
## ligada, a estatica na tela.
func _na_sala() -> void:
	var r := Comodos.RADIO
	_bloco(r, Color("3b3027"), 30)
	for i in 5:
		for j in 2:
			draw_rect(Rect2(r.position.x + 3 + i * 2.5, r.position.y + 3 + j * 3, 1, 1), Color("15110d"))
	draw_circle(r.position + Vector2(r.size.x - 5, r.size.y * 0.5), 2.4, Color("8a7a58"))
	_traco(r.position + Vector2(r.size.x - 3, 0), r.position + Vector2(r.size.x + 7, -16), Color("7a7a70"), 1.0, 31, 0.2)
	if not tv_ligada:
		return
	var tela := Comodos.TELA_DA_TV
	draw_rect(tela, Color("6f7c78"))
	for i in 400:
		draw_rect(Rect2(tela.position.x + randf() * tela.size.x,
			tela.position.y + randf() * tela.size.y, 1, 1), Color(0, 0, 0, 0.7))
	var faixa := fposmod(_t * 18.0, tela.size.y)
	draw_rect(Rect2(tela.position.x, tela.position.y + faixa, tela.size.x, 2), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(tela.position.x + 6, tela.position.y + 7, 30, 4), Color("d8e0d8"))
	_brilho(tela.get_center(), 70.0, Color(0.8, 1.0, 0.95, 0.2))

## Os papeis da pesquisa na bancada da cozinha: um por documento que chegou em
## casa, riscado de vermelho o que ja foi estudado. Era o quadro do greybox.
func _na_cozinha() -> void:
	var b := Comodos.BANCADA
	for i in mini(documentos, 8):
		var linha := floori(i / 4.0)
		var p := b.position + Vector2((i % 4) * 30.0 + linha * 8.0, linha * 12.0 + (i % 2) * 2.0)
		var folha := [p, p + Vector2(15, -1), p + Vector2(17, 8), p + Vector2(2, 9)]
		_poli(folha, Color("cfc8b0"))
		_contorno_de(folha, TRACO, 1.0, 59 + i, 0.2)
		for k in 3:
			draw_line(p + Vector2(3, 2.5 + k * 2), p + Vector2(13, 2 + k * 2), Color("8a8474"), 1.0)
		if i < lidos:
			_traco(p + Vector2(2, 8), p + Vector2(15, 0), Color("9a2a22"), 1.0, 70 + i, 0.2)

## Ela, no quarto: ajoelhada na cama, entre as pontas das correntes da foto, um
## pulso preso em cada uma.
##
## **PROVISORIO (16/10/2026): o desenho dela e da equipe e ainda vai ser
## feito.** Ate la ela e este boneco de pixel montado em codigo, na mesma grade
## de blocos das fotos (Comodos.BLOCO_DA_FOTO), para nao destoar delas - o
## traco liso do greybox, em pe na cama, brigava com a foto. Quando o desenho
## chegar, ele entra no lugar de `_desenhar_ela` (ou de uma folha de quadros)
## e o resto - o lugar, o clique, as correntes - continua.
##
## "Ferve" como o traco do greybox: 4 quadros que se alternam 5 vezes por
## segundo, mexendo as pontas do cabelo e a barra da camisola. Com o estagio,
## a pele acinzenta, ela se curva, a camisola mancha e os olhos acendem.
func _no_quarto() -> void:
	var b := Comodos.BLOCO_DA_FOTO
	var origem := Comodos.PES_DELA - Vector2(ELA_LARGURA * 0.5, ELA_ALTURA) * b
	_poli(Array(_elipse(Comodos.PES_DELA + Vector2(0, 1), 26, 4)), Color(0, 0, 0, 0.35))
	var quadro := int(_t * 5.0) % 4
	var chave := estagio * 4 + quadro
	if not _quadros_dela.has(chave):
		_quadros_dela[chave] = ImageTexture.create_from_image(_desenhar_ela(estagio, quadro))
	draw_texture_rect(_quadros_dela[chave], Rect2(origem, Vector2(ELA_LARGURA, ELA_ALTURA) * b), false)
	for i in 2:
		var pulso: Vector2i = PULSOS_DELA[i]
		_corrente(origem + (Vector2(pulso) + Vector2(0.5, 0.5)) * b, Comodos.PONTAS_DAS_CORRENTES[i])

## Uma corrente de elos de `de` ate `ate`, caida um pouco no meio, em blocos do
## tamanho do pixel da foto.
func _corrente(de: Vector2, ate: Vector2) -> void:
	var b := Comodos.BLOCO_DA_FOTO
	var n := maxi(2, int(de.distance_to(ate) / b))
	for i in n + 1:
		var t := float(i) / n
		var p := de.lerp(ate, t) + Vector2(0, sin(t * PI) * 2.0)
		draw_rect(Rect2(p - Vector2(b, b) * 0.5, Vector2(b, b)), Color("5a3426") if i % 2 == 0 else Color("8a5a40"))

## O tamanho dela, em pixels da foto, e onde ficam os pulsos (as algemas): e de
## la que as correntes saem.
const ELA_LARGURA := 36
const ELA_ALTURA := 52
const PULSOS_DELA := [Vector2i(9, 41), Vector2i(27, 41)]
const CAMISOLA := Color("8f877a")
const CABELO := Color("1d1713")
const SANGUE := Color("4a1410")
const CONTORNO := Color(0.05, 0.04, 0.035)

## Os quadros dela ja montados, por estagio e quadro da fervura.
var _quadros_dela := {}

func _desenhar_ela(s: int, quadro: int) -> Image:
	var im := Image.create(ELA_LARGURA, ELA_ALTURA, false, Image.FORMAT_RGBA8)
	var pele: Color = PELE[s]
	var cx := 18.0
	var base := ELA_ALTURA - 1
	# Quanto mais adiante, mais curvada: cabeca e ombros descem.
	var ombro := 21 + s
	var cintura := ombro + 11
	var cabeca := Vector2(cx + s * 0.5, 10.0 + s)
	var hx := int(cabeca.x)
	var hy := int(cabeca.y)

	# O corpo: ombro, tronco fino ate a cintura e, ajoelhada, a camisola
	# espalhada na cama ate a barra rasgada. O lado direito fica na sombra.
	for y in range(ombro, base + 1):
		var meia: float
		if y == ombro:
			meia = 6.0
		elif y < cintura:
			meia = lerpf(8.0, 7.0, float(y - ombro) / float(cintura - ombro))
		else:
			meia = lerpf(7.0, 15.5, pow(float(y - cintura) / float(base - cintura), 0.6))
		for x in ELA_LARGURA:
			var dx := x + 0.5 - cx
			if absf(dx) > meia:
				continue
			if y > base - 3 and _h(x, quadro, 40) < 0.3 * (y - (base - 3)):
				continue
			var cor := CAMISOLA.darkened(0.2 if dx > 3.0 else 0.0)
			if y - ombro < 3 and absf(dx) < 3.5 - (y - ombro):
				cor = pele.darkened(0.1)  # o decote
			else:
				if y > cintura + 1 and int(absf(dx) + 0.5) % 5 == 2:
					cor = cor.darkened(0.16)  # as pregas na cama
				# Sangue em manchas de 2 x 2, mais a cada estagio, e uma no peito.
				var peito := Vector2(x + 0.5 - (cx + 2.0), y + 0.5 - (ombro + 6.0)).length() < 1.0 + s * 1.2
				if (s >= 1 and peito) or _h(floori(x / 2.0), floori(y / 2.0), 41) < 0.02 + s * 0.035:
					cor = SANGUE if _h(x, y, 42) < 0.75 else SANGUE.darkened(0.4)
			im.set_pixel(x, y, cor)

	# O pescoco.
	for y in range(hy + 5, ombro):
		for x in range(int(cx) - 2, int(cx) + 2):
			im.set_pixel(x, y, pele.darkened(0.2))

	# Os bracos: do ombro ao cotovelo, que sai do corpo, e dai ao pulso, com a
	# mao apoiada na coxa. A algema no pulso, e uma linha escura do lado de
	# dentro para o braco nao sumir na camisola.
	for i in 2:
		var lado := -1 if i == 0 else 1
		var pulso: Vector2i = PULSOS_DELA[i]
		var cotovelo := Vector2(cx + lado * 10.0, cintura - 1)
		for trecho in [[Vector2(cx + lado * 8.0, ombro + 1), cotovelo], [cotovelo, Vector2(pulso)]]:
			var de: Vector2 = trecho[0]
			var ate: Vector2 = trecho[1]
			for k in 25:
				var p := de.lerp(ate, k / 24.0)
				var x := int(p.x)
				var y := int(p.y)
				im.set_pixel(clampi(x - lado, 0, ELA_LARGURA - 1), y, Color("2a2420"))
				im.set_pixel(x, y, pele)
				im.set_pixel(clampi(x + lado, 0, ELA_LARGURA - 1), y, pele.darkened(0.25))
		for y in range(pulso.y + 1, pulso.y + 3):
			for x in range(pulso.x - 1, pulso.x + 2):
				im.set_pixel(x, y, pele.darkened(0.08))
		if s >= 2:
			for x in [pulso.x - 1, pulso.x + 1]:
				im.set_pixel(x, pulso.y + 3, Color("1a1410"))  # as unhas
		for x in range(pulso.x - 1, pulso.x + 2):
			im.set_pixel(x, pulso.y, Color("3a3936"))
		im.set_pixel(pulso.x, pulso.y, Color("6d6a63"))

	# A cabeca.
	for y in range(hy - 7, hy + 7):
		for x in range(hx - 6, hx + 6):
			var d := Vector2((x + 0.5 - cabeca.x) / 5.0, (y + 0.5 - cabeca.y) / 6.5)
			if d.length_squared() <= 1.0:
				im.set_pixel(x, y, pele)
	# Olhos fundos (a sombra da sobrancelha e a olheira); a partir do terceiro
	# estagio, claros e sem pupila.
	var olho := Color("16110f") if s < 2 else Color("e8ecd4")
	for lado: int in [-1, 1]:
		var o := hx + lado * 2 - (1 if lado < 0 else 0)
		im.set_pixel(o, hy - 1, pele.darkened(0.45))
		im.set_pixel(o + lado, hy - 1, pele.darkened(0.45))
		im.set_pixel(o, hy, olho)
		im.set_pixel(o + lado, hy, pele.darkened(0.6))
		im.set_pixel(o, hy + 1, pele.darkened(0.3))
	if s >= 3:
		for x in range(hx - 1, hx + 2):
			im.set_pixel(x, hy + 3, Color("140808"))
			im.set_pixel(x, hy + 4, Color("140808"))
		im.set_pixel(hx, hy + 5, SANGUE)
	else:
		for x in range(hx - 1, hx + 2):
			im.set_pixel(x, hy + 3, Color("4a2a24"))

	# O cabelo: franja ate a sobrancelha, duas mechas na cara (uma no meio,
	# uma na bochecha) e o resto caindo pela frente dos ombros.
	for x in range(hx - 7, hx + 8):
		var dx := x + 0.5 - cabeca.x
		var topo := int(cabeca.y - 6.5 * sqrt(maxf(0.0, 1.0 - (dx / 6.0) * (dx / 6.0)))) - 1
		var ate: int
		if absf(dx) >= 4.5:
			ate = ombro + 6 + int(_h(x, quadro, 44) * 3.0)
		elif x == hx or x == hx + 4:
			ate = hy + 4 + int(_h(x, quadro, 45) * 3.0)
		else:
			ate = hy - 2 + int(_h(x, quadro, 46) * 1.6)
		for y in range(maxi(0, topo), ate):
			im.set_pixel(x, y, CABELO.lightened(0.1) if _h(x, y, 47) < 0.15 else CABELO)

	# Contorno escuro de 1 pixel: e o que separa ela da foto.
	var borda := im.duplicate() as Image
	for y in ELA_ALTURA:
		for x in ELA_LARGURA:
			if im.get_pixel(x, y).a > 0.0:
				continue
			for v: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + v
				if q.x >= 0 and q.y >= 0 and q.x < ELA_LARGURA and q.y < ELA_ALTURA and im.get_pixelv(q).a > 0.0:
					borda.set_pixel(x, y, CONTORNO)
					break
	return borda

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
