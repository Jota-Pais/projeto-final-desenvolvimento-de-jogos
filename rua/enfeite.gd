extends Node2D
## Um enfeite (21/10/2026): o que da vida a rua e as casas sem ser vasculho -
## mesa de plastico, guarda-sol, botijao, varal, poste, o forno da pizzaria.
## Desenhado por regra (Joao: "por regra, custo 0"), na vista inclinada dos
## muros: o tampo de cima e a frente de pe, com contorno preto fino e cor
## desbotada. Irmao do jogador no Y-sort, com a origem no pe.
##
## Quem diz onde cada um fica e o rua/arquitetura.gd (DECORACAO) e o
## rua/detalhes_da_rua.gd (postes); quem cria e o rua/cenario.gd, que tambem
## poe o corpo do que e `solido` na navegacao do zumbi.

const Telhado := preload("res://rua/telhado.gd")

## A origem do no fica PE px acima do pe (rua/cenario.gd); o desenho e feito
## a partir do pe.
const PE := 10.0
const CONTORNO := Color(0.07, 0.06, 0.05, 0.9)
const SOMBRA := Color(0.0, 0.0, 0.0, 0.22)
const PLASTICO := Color("dcd8cc")
const MADEIRA := Color("7a5636")
const FERRO := Color("4a4c4e")

## A pegada (px de mundo) de quem tem corpo; quem nao esta aqui nao barra.
const PEGADAS := {
	"mesa_plastico": Vector2(30, 22),
	"mesa_toalha": Vector2(40, 28),
	"balcao": Vector2(150, 30),
	"forno_pizza": Vector2(84, 60),
	"bancada": Vector2(96, 30),
	"fogao_industrial": Vector2(70, 32),
	"engradado": Vector2(26, 20),
	"botijao": Vector2(16, 14),
	"lenha": Vector2(60, 24),
	"lixeira": Vector2(30, 24),
	"churrasqueira": Vector2(46, 26),
	"tanque": Vector2(40, 24),
	"casinha_cachorro": Vector2(40, 32),
	"sacos_farinha": Vector2(50, 30),
	"freezer": Vector2(64, 32),
	"orelhao": Vector2(14, 14),
}

var tipo := ""
var variante := 0
## Para que lado o enfeite olha (cadeira, moto): um dos quatro LADOS.
var olhando := "sul"

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func solido(qual: String) -> bool:
	return PEGADAS.has(qual)

func _draw() -> void:
	draw_set_transform(Vector2(0.0, PE))
	match tipo:
		"mesa_plastico": _mesa_plastico()
		"cadeira_plastico": _cadeira(PLASTICO)
		"cadeira": _cadeira(MADEIRA.lightened(0.1))
		"guarda_sol": _guarda_sol()
		"cavalete": _cavalete()
		"engradado": _engradado()
		"botijao": _botijao()
		"lenha": _lenha()
		"lixeira": _lixeira()
		"saco_de_lixo": _saco_de_lixo()
		"moto": _moto()
		"varal": _varal()
		"churrasqueira": _churrasqueira()
		"tanque": _tanque()
		"casinha_cachorro": _casinha_cachorro()
		"vaso": _vaso()
		"bicicleta": _bicicleta()
		"pneu": _pneu(Vector2.ZERO)
		"poste": _poste()
		"orelhao": _orelhao()
		"mastro": _mastro()
		"mesa_toalha": _mesa_toalha()
		"balcao": _balcao()
		"forno_pizza": _forno_pizza()
		"bancada": _bancada()
		"fogao_industrial": _fogao_industrial()
		"sacos_farinha": _sacos_farinha()
		"freezer": _freezer()
		"placa_pare": _placa_pare()

# --- ajudas ---------------------------------------------------------------------

func _caixa(base: Rect2, altura: float, cima: Color, frente: Color) -> void:
	## Uma caixa na vista inclinada: `base` e a pegada no chao (coordenada
	## local); o tampo sobe `altura` e a frente desce do tampo ate o chao.
	var tampo := Rect2(base.position - Vector2(0, altura), base.size)
	var face := Rect2(Vector2(base.position.x, base.end.y - altura), Vector2(base.size.x, altura))
	draw_rect(Rect2(base.position + Vector2(4, base.size.y - 2), Vector2(base.size.x, 5)), SOMBRA)
	draw_rect(face, frente)
	draw_rect(tampo, cima)
	draw_rect(face, CONTORNO, false, 1.0)
	draw_rect(tampo, CONTORNO, false, 1.0)

func _elipse(centro: Vector2, raios: Vector2, cor: Color, contorno := true) -> void:
	var pontos := PackedVector2Array()
	for k in 18:
		var a := TAU * k / 18.0
		pontos.append(centro + Vector2(cos(a) * raios.x, sin(a) * raios.y))
	draw_colored_polygon(pontos, cor)
	if contorno:
		pontos.append(pontos[0])
		draw_polyline(pontos, CONTORNO, 1.0)

func _sombra_redonda(raio: float) -> void:
	_elipse(Vector2(3, 2), Vector2(raio, raio * 0.45), SOMBRA, false)

# --- rua e quintal -----------------------------------------------------------------

func _mesa_plastico() -> void:
	if variante % 4 == 3:
		# Tombada de lado.
		draw_rect(Rect2(-16, -16, 32, 14), PLASTICO.darkened(0.05))
		draw_rect(Rect2(-16, -16, 32, 14), CONTORNO, false, 1.0)
		for x in [-12.0, 10.0]:
			draw_rect(Rect2(x, -2, 3, 8), PLASTICO.darkened(0.15))
		return
	_sombra_redonda(18.0)
	for x in [-13.0, 11.0]:
		draw_rect(Rect2(x, -14, 3, 14), PLASTICO.darkened(0.2))
		draw_rect(Rect2(x, -14, 3, 14), CONTORNO, false, 1.0)
	var tampo := Rect2(-16, -26, 32, 18)
	draw_rect(Rect2(tampo.position.x, tampo.end.y, tampo.size.x, 3), PLASTICO.darkened(0.12))
	draw_rect(tampo, PLASTICO)
	draw_rect(tampo.grow(-4), PLASTICO.darkened(0.05), false, 1.0)
	if variante % 3 == 1:
		draw_circle(Vector2(5, -19), 3.0, Color("6b3a1e"))
		draw_circle(Vector2(5, -19), 2.0, Color("c9a03a"))
	draw_rect(tampo, CONTORNO, false, 1.0)

func _cadeira(cor: Color) -> void:
	if variante % 5 == 4:
		draw_rect(Rect2(-9, -8, 18, 9), cor.darkened(0.08))
		draw_rect(Rect2(-9, -8, 18, 9), CONTORNO, false, 1.0)
		draw_rect(Rect2(-9, -12, 18, 4), cor.darkened(0.2))
		return
	_sombra_redonda(9.0)
	var assento := Rect2(-8, -14, 16, 10)
	for x in [-7.0, 5.0]:
		draw_rect(Rect2(x, -6, 2, 6), cor.darkened(0.25))
	draw_rect(assento, cor)
	draw_rect(assento, CONTORNO, false, 1.0)
	# O encosto do lado oposto ao que ela olha.
	match olhando:
		"norte":
			draw_rect(Rect2(-8, -8, 16, 4), cor.darkened(0.1))
			draw_rect(Rect2(-8, -8, 16, 4), CONTORNO, false, 1.0)
		"leste":
			draw_rect(Rect2(-9, -24, 4, 18), cor.darkened(0.1))
			draw_rect(Rect2(-9, -24, 4, 18), CONTORNO, false, 1.0)
		"oeste":
			draw_rect(Rect2(5, -24, 4, 18), cor.darkened(0.1))
			draw_rect(Rect2(5, -24, 4, 18), CONTORNO, false, 1.0)
		_:
			draw_rect(Rect2(-8, -26, 16, 13), cor.darkened(0.05))
			draw_rect(Rect2(-6, -24, 12, 3), cor.darkened(0.15))
			draw_rect(Rect2(-8, -26, 16, 13), CONTORNO, false, 1.0)

func _guarda_sol() -> void:
	_sombra_redonda(30.0)
	draw_line(Vector2(0, 0), Vector2(0, -46), FERRO, 2.0)
	var centro := Vector2(0, -50)
	var cores := [Color("b8473c"), Color("e3ddcf")] if variante % 2 == 0 else [Color("d1a83c"), Color("e3ddcf")]
	for k in 8:
		var a := TAU * k / 8.0
		var b := TAU * (k + 1) / 8.0
		var pontos := PackedVector2Array([centro, centro + Vector2(cos(a) * 34.0, sin(a) * 22.0),
			centro + Vector2(cos(b) * 34.0, sin(b) * 22.0)])
		var cor: Color = cores[k % 2]
		if sin((a + b) / 2.0) < 0.0:
			cor = cor.darkened(0.12)
		draw_colored_polygon(pontos, cor)
	var borda := PackedVector2Array()
	for k in 9:
		var a := TAU * k / 8.0
		borda.append(centro + Vector2(cos(a) * 34.0, sin(a) * 22.0))
	draw_polyline(borda, CONTORNO, 1.0)
	draw_circle(centro, 2.0, FERRO)

func _cavalete() -> void:
	_sombra_redonda(10.0)
	draw_line(Vector2(-9, 0), Vector2(-6, -26), MADEIRA, 2.0)
	draw_line(Vector2(9, 0), Vector2(6, -26), MADEIRA, 2.0)
	var quadro := Rect2(-10, -30, 20, 22)
	draw_rect(quadro, Color("2a3328"))
	draw_rect(quadro, MADEIRA, false, 2.0)
	draw_rect(quadro.grow(1.0), CONTORNO, false, 1.0)
	var fonte := ThemeDB.fallback_font
	draw_set_transform(Vector2(-8, -22 + PE), 0.0, Vector2(0.3, 0.3))
	draw_string(fonte, Vector2.ZERO, "PIZZA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8e2d0"))
	draw_set_transform(Vector2(0.0, PE))
	for k in 3:
		draw_line(Vector2(-7, -16 + k * 3), Vector2(4 - k * 2, -16 + k * 3), Color(0.9, 0.88, 0.8, 0.7), 1.0)

func _engradado() -> void:
	var cores := [Color("c9a032"), Color("b8473c"), Color("3f6f8f")]
	var cor: Color = cores[variante % 3]
	var pilha := 1 + variante % 3
	for k in pilha:
		var base := Rect2(-13, -10 - k * 12, 26, 20)
		var face := Rect2(base.position.x, base.end.y - 12, base.size.x, 12)
		draw_rect(face, cor.darkened(0.1))
		for j in 4:
			draw_rect(Rect2(face.position.x + 3 + j * 6, face.position.y + 3, 3, 6), cor.darkened(0.45))
		draw_rect(face, CONTORNO, false, 1.0)
	var topo := Rect2(-13, -10 - pilha * 12 - 8 + 12, 26, 8)
	draw_rect(topo, cor)
	for j in 4:
		draw_circle(topo.position + Vector2(4 + j * 6, 4), 2.0, Color("3d2a18"))
	draw_rect(topo, CONTORNO, false, 1.0)

func _botijao() -> void:
	_sombra_redonda(8.0)
	var cores := [Color("3e6fa0"), Color("7a7c7e"), Color("4f7f4f"), Color("a0503e")]
	var cor: Color = cores[variante % 4]
	if variante % 5 == 4:
		# Deitado.
		draw_rect(Rect2(-12, -9, 24, 12), cor)
		_elipse(Vector2(12, -3), Vector2(3, 6), cor.darkened(0.2))
		draw_rect(Rect2(-12, -9, 24, 12), CONTORNO, false, 1.0)
		return
	draw_rect(Rect2(-7, -20, 14, 20), cor)
	draw_rect(Rect2(-7, -20, 3, 20), cor.lightened(0.18))
	_elipse(Vector2(0, -20), Vector2(7, 3), cor.lightened(0.1))
	draw_rect(Rect2(-2, -26, 4, 5), Color("8a8c8e"))
	draw_rect(Rect2(-7, -20, 14, 20), CONTORNO, false, 1.0)
	draw_rect(Rect2(-7, -9, 14, 2), cor.darkened(0.3))

func _lenha() -> void:
	draw_rect(Rect2(-28, -4, 60, 6), SOMBRA)
	var face := Rect2(-30, -20, 60, 20)
	draw_rect(face, Color("4a3424"))
	for fila in 3:
		for k in 8:
			var c := Vector2(face.position.x + 4 + k * 7.4 + (fila % 2) * 3.5, face.position.y + 4 + fila * 6.4)
			draw_circle(c, 3.4, Color("9a7450"))
			draw_circle(c, 1.4, Color("6e4e32"))
	draw_rect(Rect2(-30, -30, 60, 10), Color("6a4a30"))
	for k in 6:
		draw_line(Vector2(-30, -28 + k * 1.6), Vector2(30, -28 + k * 1.6), Color("5a3e28"), 1.0)
	draw_rect(Rect2(-30, -30, 60, 30), CONTORNO, false, 1.0)

func _lixeira() -> void:
	var cor := Color("3f6a3f") if variante % 2 == 0 else Color("b86a2a")
	_caixa(Rect2(-15, -12, 30, 24), 22.0, cor.lightened(0.1), cor)
	draw_rect(Rect2(-15, -36, 30, 4), cor.darkened(0.25))
	if variante % 3 == 2:
		_saco_de_lixo_em(Vector2(14, 6))

func _saco_de_lixo() -> void:
	_saco_de_lixo_em(Vector2.ZERO)
	if variante % 2 == 1:
		_saco_de_lixo_em(Vector2(11, 3))

func _saco_de_lixo_em(p: Vector2) -> void:
	_elipse(p + Vector2(3, 1), Vector2(9, 4), SOMBRA, false)
	_elipse(p + Vector2(0, -7), Vector2(9, 8), Color("232527"))
	draw_line(p + Vector2(-4, -12), p + Vector2(1, -9), Color("4a4d50"), 1.0)
	draw_line(p + Vector2(-1, -15), p + Vector2(1, -18), Color("3a3c3e"), 2.0)

func _moto() -> void:
	# A moto de entrega caida, com o bau vermelho.
	draw_rect(Rect2(-22, -3, 46, 6), SOMBRA)
	_pneu(Vector2(-18, -6))
	_pneu(Vector2(18, -6))
	draw_line(Vector2(-18, -6), Vector2(18, -8), Color("8a1f1a"), 5.0)
	draw_line(Vector2(-18, -6), Vector2(18, -8), CONTORNO, 1.0)
	draw_line(Vector2(14, -10), Vector2(22, -18), Color("2a2a2a"), 2.0)
	var bau := Rect2(-30, -24, 20, 16)
	draw_rect(bau, Color("b8312a"))
	draw_rect(Rect2(bau.position.x + 3, bau.position.y + 4, 14, 3), Color("e9e2d0"))
	draw_rect(bau, CONTORNO, false, 1.0)

func _varal() -> void:
	draw_line(Vector2(-60, 0), Vector2(-60, -40), MADEIRA, 3.0)
	draw_line(Vector2(60, 0), Vector2(60, -40), MADEIRA, 3.0)
	var pontos := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		pontos.append(Vector2(-60 + 120 * t, -38 + sin(t * PI) * 5.0))
	draw_polyline(pontos, Color("d8d4c8"), 1.0)
	var roupas := [Color("b8473c"), Color("3e6fa0"), Color("e3ddcf"), Color("c9a032"), Color("4f7f4f")]
	for k in 5:
		var t := (k + 1) / 7.0 + (variante % 3) * 0.02
		var topo := Vector2(-60 + 120 * t, -38 + sin(t * PI) * 5.0)
		var cor: Color = roupas[(k + variante) % roupas.size()]
		var r := Rect2(topo + Vector2(-6, 0), Vector2(12, 14 if k % 2 == 0 else 18))
		draw_rect(r, cor)
		draw_rect(r, CONTORNO, false, 1.0)
	draw_line(Vector2(-58, 2), Vector2(62, 2), SOMBRA, 3.0)

func _churrasqueira() -> void:
	_caixa(Rect2(-23, -13, 46, 26), 24.0, Color("6a5a4c"), Color("9a5a3e"))
	draw_texture_rect(Telhado.PAREDES["tijolo"], Rect2(-23, -11, 46, 24), true, Color(0.85, 0.8, 0.78))
	draw_rect(Rect2(-17, -6, 34, 10), Color("1a1512"))
	for k in 5:
		draw_line(Vector2(-16 + k * 8, -5), Vector2(-16 + k * 8, 3), Color("6a6a6a"), 1.0)
	draw_rect(Rect2(-23, -11, 46, 24), CONTORNO, false, 1.0)
	draw_rect(Rect2(10, -52, 10, 16), Color("9a5a3e"))
	draw_rect(Rect2(10, -52, 10, 16), CONTORNO, false, 1.0)

func _tanque() -> void:
	draw_rect(Rect2(-16, -10, 4, 10), Color("8a8780"))
	draw_rect(Rect2(12, -10, 4, 10), Color("8a8780"))
	_caixa(Rect2(-20, -22, 40, 14), 10.0, Color("c9c5bb"), Color("a9a59c"))
	draw_rect(Rect2(-16, -30, 32, 8), Color("8fa0a8"))
	draw_line(Vector2(-12, -28), Vector2(12, -28), Color("b0c2ca"), 1.0)
	draw_rect(Rect2(-16, -30, 32, 8), CONTORNO, false, 1.0)

func _casinha_cachorro() -> void:
	_caixa(Rect2(-20, -16, 40, 32), 20.0, MADEIRA, MADEIRA.darkened(0.15))
	var telhado := PackedVector2Array([Vector2(-23, -36), Vector2(0, -52), Vector2(23, -36)])
	draw_colored_polygon(telhado, Color("8a4a32"))
	telhado.append(telhado[0])
	draw_polyline(telhado, CONTORNO, 1.0)
	draw_rect(Rect2(-7, -12, 14, 12), Color("1a1512"))
	draw_line(Vector2(20, -6), Vector2(42, 4), Color("8a8c8e"), 1.0)
	draw_circle(Vector2(40, 6), 5.0, Color("5a5c5e"))

func _vaso() -> void:
	_sombra_redonda(9.0)
	draw_rect(Rect2(-8, -12, 16, 12), Color("a4583c"))
	draw_rect(Rect2(-9, -14, 18, 3), Color("b8684a"))
	draw_rect(Rect2(-8, -14, 16, 14), CONTORNO, false, 1.0)
	var verde := Color("4f6b32") if variante % 3 else Color("6b5a32")
	for k in 7:
		var a := -PI * 0.9 + PI * 0.8 * k / 6.0
		draw_line(Vector2(0, -14), Vector2(cos(a) * 12.0, -14 + sin(a) * 14.0), verde, 2.0)

func _bicicleta() -> void:
	draw_arc(Vector2(-12, -6), 8.0, 0.0, TAU, 14, Color("2a2a2a"), 2.0)
	draw_arc(Vector2(12, -6), 8.0, 0.0, TAU, 14, Color("2a2a2a"), 2.0)
	draw_line(Vector2(-12, -6), Vector2(0, -14), Color("3e6fa0"), 2.0)
	draw_line(Vector2(0, -14), Vector2(12, -6), Color("3e6fa0"), 2.0)
	draw_line(Vector2(-12, -6), Vector2(2, -6), Color("3e6fa0"), 2.0)
	draw_line(Vector2(10, -16), Vector2(14, -18), Color("2a2a2a"), 2.0)

func _pneu(p: Vector2) -> void:
	draw_circle(p, 8.0, Color("1e1d1c"))
	draw_circle(p, 3.5, Color("4a4846"))
	draw_arc(p, 8.0, 0.0, TAU, 16, CONTORNO, 1.0)

## O poste de concreto da rua: alto (9 m, na regua do boneco), com a cruzeta,
## os isoladores e, em alguns, o transformador e o braco da luz. Os fios sao
## do rua/detalhes_da_rua.gd, por cima de tudo.
const ALTURA_DO_POSTE := 170.0

func _poste() -> void:
	_elipse(Vector2(10, 2), Vector2(14, 4), SOMBRA, false)
	var concreto := Color("a8a59c")
	draw_rect(Rect2(-4, -ALTURA_DO_POSTE, 8, ALTURA_DO_POSTE), concreto)
	draw_rect(Rect2(1, -ALTURA_DO_POSTE, 3, ALTURA_DO_POSTE), concreto.darkened(0.15))
	draw_rect(Rect2(-4, -ALTURA_DO_POSTE, 8, ALTURA_DO_POSTE), CONTORNO, false, 1.0)
	# A cruzeta e os isoladores.
	var y := -ALTURA_DO_POSTE + 10.0
	draw_rect(Rect2(-26, y, 52, 4), Color("5e4e3a"))
	draw_rect(Rect2(-26, y, 52, 4), CONTORNO, false, 1.0)
	for x in [-22.0, 0.0, 22.0]:
		draw_rect(Rect2(x - 2, y - 5, 4, 5), Color("6a8a6a"))
	if variante % 3 == 0:
		# O transformador.
		var t := Rect2(5, -ALTURA_DO_POSTE + 30.0, 16, 22)
		draw_rect(t, Color("6f7476"))
		draw_rect(Rect2(t.position.x, t.position.y, 4, t.size.y), Color("858a8c"))
		draw_rect(t, CONTORNO, false, 1.0)
	if variante % 2 == 0:
		# O braco da luz, para a rua.
		draw_line(Vector2(0, -ALTURA_DO_POSTE + 40.0), Vector2(-30, -ALTURA_DO_POSTE + 30.0), Color("5a5c5e"), 2.0)
		draw_rect(Rect2(-38, -ALTURA_DO_POSTE + 27.0, 12, 5), Color("3a3c3e"))
		draw_rect(Rect2(-37, -ALTURA_DO_POSTE + 31.0, 10, 2), Color("d8d2b0"))
	# Cartaz velho colado e a placa do numero.
	draw_rect(Rect2(-4, -60, 8, 10), Color("c9b98a"))
	draw_rect(Rect2(-3, -36, 6, 5), Color("2a3a5a"))

func _orelhao() -> void:
	_sombra_redonda(12.0)
	draw_line(Vector2(0, 0), Vector2(0, -26), Color("6a6c6e"), 3.0)
	var casco := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		casco.append(Vector2(cos(a) * 14.0, -40.0 + sin(a) * 18.0))
	casco.append(Vector2(14, -26))
	casco.append(Vector2(-14, -26))
	draw_colored_polygon(casco, Color("d07a2a"))
	_elipse(Vector2(0, -34), Vector2(9, 8), Color("4a3a2a"))
	draw_rect(Rect2(-4, -36, 8, 8), Color("5a6a7a"))
	casco.append(casco[0])
	draw_polyline(casco, CONTORNO, 1.0)

func _mastro() -> void:
	_sombra_redonda(8.0)
	draw_rect(Rect2(-8, -6, 16, 6), Color("b9b5aa"))
	draw_line(Vector2(0, -4), Vector2(0, -130), Color("9a9c9e"), 2.0)
	var b := Rect2(1, -128, 40, 26)
	draw_rect(b, Color("3f8a4a"))
	draw_colored_polygon(PackedVector2Array([b.position + Vector2(20, 3), b.position + Vector2(37, 13),
		b.position + Vector2(20, 23), b.position + Vector2(3, 13)]), Color("e0c23a"))
	draw_circle(b.get_center(), 6.0, Color("2f4a8a"))
	draw_rect(b, CONTORNO, false, 1.0)

func _placa_pare() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -50), Color("8a8c8e"), 2.0)
	var oito := PackedVector2Array()
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		oito.append(Vector2(cos(a) * 11.0, -58.0 + sin(a) * 11.0))
	draw_colored_polygon(oito, Color("b8312a"))
	oito.append(oito[0])
	draw_polyline(oito, CONTORNO, 1.0)
	draw_line(Vector2(-6, -58), Vector2(6, -58), Color("e8e2d0"), 2.0)

# --- a pizzaria por dentro --------------------------------------------------------

func _mesa_toalha() -> void:
	var cadeira := MADEIRA.lightened(0.1)
	for p in [Vector2(-26, -4), Vector2(26, -4)]:
		draw_rect(Rect2(p.x - 6, p.y - 12, 12, 12), cadeira)
		draw_rect(Rect2(p.x - 6, p.y - 12, 12, 12), CONTORNO, false, 1.0)
	draw_rect(Rect2(-6, -38, 12, 6), cadeira.darkened(0.1))
	draw_rect(Rect2(-22, -12, 44, 14), SOMBRA)
	var tampo := Rect2(-20, -32, 40, 26)
	draw_rect(tampo, Color("e8e2d2"))
	for x in 5:
		for y in 4:
			if (x + y) % 2 == 0:
				draw_rect(Rect2(tampo.position.x + x * 8, tampo.position.y + y * 6.5, 8, 6.5), Color("b23a30"))
	draw_rect(Rect2(tampo.position.x, tampo.end.y, tampo.size.x, 5), Color("a23028"))
	draw_rect(tampo, CONTORNO, false, 1.0)
	if variante % 3 == 0:
		draw_circle(tampo.get_center() + Vector2(-4, 0), 6.0, Color("d9b067"))
		draw_circle(tampo.get_center() + Vector2(-4, 0), 4.5, Color("c0452c"))
	draw_rect(Rect2(-6, 2, 12, 8), cadeira.darkened(0.1))
	draw_rect(Rect2(-6, 2, 12, 8), CONTORNO, false, 1.0)

func _balcao() -> void:
	_caixa(Rect2(-75, -15, 150, 30), 26.0, Color("8a6a4a"), Color("6a4a30"))
	for k in 5:
		draw_line(Vector2(-75 + k * 30, -11), Vector2(-75 + k * 30, 15), Color("5a3e28"), 1.0)
	# A caixa registradora e a vitrine.
	draw_rect(Rect2(40, -52, 22, 14), Color("3a3c3e"))
	draw_rect(Rect2(42, -50, 10, 5), Color("6a8a6a"))
	draw_rect(Rect2(40, -52, 22, 14), CONTORNO, false, 1.0)
	draw_rect(Rect2(-60, -48, 60, 10), Color(0.7, 0.85, 0.9, 0.5))
	draw_rect(Rect2(-60, -48, 60, 10), CONTORNO, false, 1.0)

func _forno_pizza() -> void:
	# A base de tijolo e a cupula, com a boca escura virada para o salao.
	var base := Rect2(-42, -30, 84, 30)
	draw_rect(Rect2(base.position + Vector2(5, base.size.y - 2), Vector2(base.size.x, 6)), SOMBRA)
	draw_texture_rect(Telhado.PAREDES["tijolo"], base, true, Color(0.9, 0.82, 0.78))
	draw_rect(base, CONTORNO, false, 1.0)
	_elipse(Vector2(0, -42), Vector2(38, 26), Color("a4583c"))
	_elipse(Vector2(-4, -46), Vector2(28, 18), Color("b8684a"), false)
	for k in 6:
		var a := PI + PI * k / 5.0
		draw_line(Vector2(cos(a) * 30.0, -42 + sin(a) * 20.0), Vector2(cos(a) * 38.0, -42 + sin(a) * 26.0), Color("7a3a24"), 1.0)
	var boca := PackedVector2Array()
	for k in 9:
		var a := PI + PI * k / 8.0
		boca.append(Vector2(cos(a) * 12.0, -24 + sin(a) * 12.0))
	draw_colored_polygon(boca, Color("120c08"))
	draw_circle(Vector2(0, -26), 4.0, Color(0.9, 0.45, 0.15, 0.35))
	draw_rect(Rect2(18, -76, 8, 18), Color("5a5c5e"))
	draw_rect(Rect2(18, -76, 8, 18), CONTORNO, false, 1.0)

func _bancada() -> void:
	_caixa(Rect2(-48, -15, 96, 30), 22.0, Color("b9bcbd"), Color("8f9293"))
	for k in 4:
		draw_circle(Vector2(-30 + k * 16, -27), 5.0, Color("e6dcc4"))
	_elipse(Vector2(28, -28), Vector2(14, 6), Color(0.95, 0.93, 0.88, 0.7), false)
	draw_line(Vector2(-40, -33), Vector2(-20, -24), Color("8a6a4a"), 3.0)

func _fogao_industrial() -> void:
	_caixa(Rect2(-35, -16, 70, 32), 20.0, Color("3a3c3e"), Color("8f9293"))
	for k in 4:
		draw_arc(Vector2(-24 + k * 16, -28), 5.0, 0.0, TAU, 10, Color("6a6c6e"), 2.0)
	draw_rect(Rect2(-30, -2, 60, 10), Color("6f7273"))

func _sacos_farinha() -> void:
	for k in 4:
		var p := Vector2(-16 + (k % 2) * 22, -6 - (k / 2) * 10)
		var r := Rect2(p - Vector2(12, 8), Vector2(24, 14))
		draw_rect(r, Color("e6e0d0"))
		draw_rect(Rect2(r.position.x + 4, r.position.y + 4, 14, 3), Color("b23a30"))
		draw_rect(r, CONTORNO, false, 1.0)

func _freezer() -> void:
	_caixa(Rect2(-32, -16, 64, 32), 26.0, Color("dcdcd6"), Color("c2c2bc"))
	draw_rect(Rect2(-28, -40, 56, 12), Color(0.6, 0.75, 0.82, 0.6))
	draw_rect(Rect2(-28, -40, 56, 12), CONTORNO, false, 1.0)
