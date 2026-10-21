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
##
## **A mobilia gerada** (21/10/2026, Joao: "o mesmo nivel de detalhamento nos
## moveis que voce teve nas casas, cada um pra sua situacao"): os tipos de
## MOBILIA tem desenho do PixelLab em rua/arte/objetos/mobilia/, de frente,
## como os moveis de vasculho - encostados numa parede norte. Com `olhando`
## para outro lado, aparecem as costas ou o lado, desenhados por regra na cor
## do proprio desenho (o mesmo do rua/vasculhavel.gd). Nada gira.

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
	"fogao_industrial": Vector2(70, 32),
	"engradado": Vector2(26, 20),
	"botijao": Vector2(10, 6),
	"lenha": Vector2(60, 24),
	"lixeira": Vector2(18, 10),
	"churrasqueira": Vector2(46, 26),
	"tanque": Vector2(40, 24),
	"casinha_cachorro": Vector2(40, 32),
	"sacos_farinha": Vector2(50, 30),
	"freezer": Vector2(64, 32),
	"orelhao": Vector2(14, 14),
	# A mobilia gerada: a pegada do que e opaco no desenho, de frente.
	"mesa_toalha": Vector2(60, 30),
	"balcao": Vector2(128, 30),
	"forno_pizza": Vector2(66, 44),
	"bancada": Vector2(90, 28),
	"cama": Vector2(60, 74),
	"sofa": Vector2(86, 30),
	"rack_tv": Vector2(56, 22),
	"mesa_jantar": Vector2(56, 40),
	"pia_fogao": Vector2(86, 26),
	"mesa_bar": Vector2(58, 34),
	"mesa_escritorio": Vector2(60, 34),
	# Por regra, sob medida (o `tamanho` do pedido manda quando vem).
	"bancada_cozinha": Vector2(110, 26),
	"box_chuveiro": Vector2(44, 44),
	"vaso_sanitario": Vector2(18, 22),
	"pia_banheiro": Vector2(22, 14),
	"criado_mudo": Vector2(22, 16),
	"guarda_roupa": Vector2(70, 26),
	"cadeiras_espera": Vector2(66, 16),
	"grade_cela": Vector2(120, 6),
	"fogareiro": Vector2(18, 14),
	"bebedouro": Vector2(16, 14),
}

## Os tipos com desenho gerado (rua/arte/objetos/mobilia/<tipo>.png).
const MOBILIA := ["mesa_toalha", "balcao", "forno_pizza", "bancada", "cama", "sofa", "rack_tv",
	"mesa_jantar", "pia_fogao", "mesa_bar", "guarda_sol", "mesa_escritorio"]
const PASTA_DA_MOBILIA := "res://rua/arte/objetos/mobilia/"
## Os enfeites soltos com desenho do PixelLab (21/10/2026, noite; Joao: "3
## objetos no PixelLab", questionario: cadeira "Vermelha", lixeira "Conteiner
## verde"): rua/arte/objetos/<nome>.png, aparados no opaco, desenhados a meia
## escala - a do boneco, 1 pixel de desenho por pixel de tela com o zoom 2. A
## cadeira foi pedida com as quatro vistas numa imagem e vieram a de frente e a
## de lado (a do outro lado e ela espelhada); a de costas continua por regra.
const PASTA_DOS_SOLTOS := "res://rua/arte/objetos/"
const ESCALA_DOS_SOLTOS := 0.5
## As cores do botijao e da lixeira alem da que veio desenhada: o desenho e
## tingido (ver _tingido); alfa 0 e sem tinta - o azul e o verde do desenho.
const CORES_DO_BOTIJAO := [Color(0, 0, 0, 0), Color("7a7c7e"), Color("4f7f4f"), Color("a0503e")]
const LARANJA_DA_LIXEIRA := Color("b86a2a")
## As linhas do encosto no desenho da cadeira de frente (o resto e assento e
## pernas).
const ENCOSTO_DA_CADEIRA := 13.0

## Quanto um desenho pode subir alem da pegada: a espessura da parede atras
## (o mesmo do rua/vasculhavel.gd).
const FOLGA_SOBRE_A_PAREDE := 20.0

var tipo := ""
var variante := 0
## Para que lado o enfeite olha (cadeira, moto, a mobilia): um dos quatro
## LADOS. "sul" e de frente para a camera.
var olhando := "sul"
## O tamanho, para o que e sob medida (bancada, tapete, grade): em mundo, ja
## na orientacao dele. Zero = a pegada da tabela.
var tamanho := Vector2.ZERO

static var _texturas := {}
static var _medidas := {}
static var _soltos := {}

static func _textura(qual: String) -> Texture2D:
	if not qual in MOBILIA:
		return null
	if not _texturas.has(qual):
		var caminho: String = PASTA_DA_MOBILIA + qual + ".png"
		_texturas[qual] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _texturas[qual]

## A pegada em mundo: a da tabela (ou o `tamanho` pedido), deitada quando o
## enfeite olha para um lado.
static func pegada_de(qual: String, para: String, pedido: Vector2) -> Vector2:
	if pedido != Vector2.ZERO:
		return pedido
	var p: Vector2 = PEGADAS.get(qual, Vector2.ZERO)
	return Vector2(p.y, p.x) if para == "leste" or para == "oeste" else p

## A cor media, a primeira e a ultima linha opaca do desenho, uma vez so.
static func _medir(textura: Texture2D) -> Dictionary:
	var chave := textura.resource_path
	if _medidas.has(chave):
		return _medidas[chave]
	var imagem := textura.get_image()
	var soma := Color(0, 0, 0, 0)
	var n := 0
	var topo := imagem.get_height()
	var fundo := 0
	for y in imagem.get_height():
		for x in imagem.get_width():
			var c := imagem.get_pixel(x, y)
			if c.a > 0.5:
				soma += c
				n += 1
				topo = mini(topo, y)
				fundo = maxi(fundo, y)
	var medida := { "cor": Color(soma.r / n, soma.g / n, soma.b / n) if n > 0 else MADEIRA,
		"topo": topo, "fundo": fundo }
	_medidas[chave] = medida
	return medida

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func solido(qual: String) -> bool:
	return PEGADAS.has(qual)

func _draw() -> void:
	draw_set_transform(Vector2(0.0, PE))
	var textura := _textura(tipo)
	if textura != null:
		_mobilia(textura)
		return
	match tipo:
		"bancada_cozinha": _bancada_cozinha()
		"box_chuveiro": _box_chuveiro()
		"vaso_sanitario": _vaso_sanitario()
		"pia_banheiro": _pia_banheiro()
		"criado_mudo": _criado_mudo()
		"guarda_roupa": _guarda_roupa()
		"tapete": _tapete()
		"roupas": _roupas()
		"colchao": _colchao()
		"grade_cela": _grade_cela()
		"cadeiras_espera": _cadeiras_espera()
		"papeis": _papeis()
		"fogareiro": _fogareiro()
		"bebedouro": _bebedouro()
		"latas": _latas()
		"mesa_plastico": _mesa_plastico()
		"cadeira_plastico": _cadeira_plastico()
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

## A cadeira de plastico do desenho: de frente olhando para o sul, de lado
## para leste e oeste (espelhada), tombada e a de lado deitada. De costas
## (olhando para o norte) e montada da de frente: o assento e as pernas no
## lugar e o encosto (as ENCOSTO_DA_CADEIRA linhas de cima do desenho) descido
## para a frente do assento, que e onde ele fica visto por tras.
func _cadeira_plastico() -> void:
	var frente := _solto("cadeira_plastico")
	if variante % 5 == 4:
		_deitado(_solto("cadeira_plastico_lado"), PI / 2.0)
		return
	if olhando == "norte":
		var k := ESCALA_DOS_SOLTOS
		var tam := frente.get_size()
		var e := ENCOSTO_DA_CADEIRA
		_sombra_redonda(tam.x * k * 0.5)
		draw_texture_rect_region(frente, Rect2(-tam.x * k / 2.0, (-tam.y + e) * k, tam.x * k, (tam.y - e) * k),
			Rect2(0.0, e, tam.x, tam.y - e))
		draw_texture_rect_region(frente, Rect2(-tam.x * k / 2.0, (-tam.y + e + 4.0) * k, tam.x * k, e * k),
			Rect2(0.0, 0.0, tam.x, e))
		return
	if olhando == "leste" or olhando == "oeste":
		_em_pe(_solto("cadeira_plastico_lado"), olhando == "oeste")
		return
	_em_pe(frente)

## Um enfeite solto deitado no chao: o desenho de pe girado de `angulo`, com o
## lado de baixo no chao.
func _deitado(desenho: Texture2D, angulo: float) -> void:
	var k := ESCALA_DOS_SOLTOS
	_elipse(Vector2(2.0, 0.0), Vector2(desenho.get_height() * k * 0.5, 3.0), SOMBRA, false)
	draw_set_transform(Vector2(0.0, PE - desenho.get_width() * k / 2.0), angulo, Vector2.ONE * k)
	draw_texture(desenho, -desenho.get_size() / 2.0)
	draw_set_transform(Vector2(0.0, PE))

## Um enfeite solto desenhado de pe: o pe do desenho no chao, centrado, com a
## sombra embaixo; `espelhar` vira para o outro lado.
func _em_pe(desenho: Texture2D, espelhar := false) -> void:
	var tamanho_no_mundo := desenho.get_size() * ESCALA_DOS_SOLTOS
	_sombra_redonda(tamanho_no_mundo.x * 0.5)
	var caixa := Rect2(Vector2(-tamanho_no_mundo.x / 2.0, -tamanho_no_mundo.y), tamanho_no_mundo)
	if espelhar:
		caixa = Rect2(Vector2(caixa.end.x, caixa.position.y), Vector2(-caixa.size.x, caixa.size.y))
	draw_texture_rect(desenho, caixa, false)

## O desenho solto `nome`, tingido de `cor` quando ela vem (alfa > 0): cada
## pixel guarda o claro e escuro dele e ganha a cor nova, e o contorno preto
## fica. Feito uma vez por cor.
static func _solto(nome: String, cor := Color(0, 0, 0, 0)) -> Texture2D:
	var chave := "%s#%s" % [nome, cor.to_html()]
	if _soltos.has(chave):
		return _soltos[chave]
	var caminho := PASTA_DOS_SOLTOS + nome + ".png"
	var textura: Texture2D = load(caminho)
	if cor.a > 0.0:
		textura = _tingido(textura, cor)
	_soltos[chave] = textura
	return textura

static func _tingido(textura: Texture2D, cor: Color) -> Texture2D:
	var imagem := textura.get_image()
	imagem.decompress()
	# O claro medio do desenho vira a cor pedida; o resto acompanha.
	var soma := 0.0
	var n := 0
	for y in imagem.get_height():
		for x in imagem.get_width():
			var c := imagem.get_pixel(x, y)
			if c.a > 0.5 and c.get_luminance() > 0.12:
				soma += c.get_luminance()
				n += 1
	var media := soma / maxf(1.0, float(n))
	for y in imagem.get_height():
		for x in imagem.get_width():
			var c := imagem.get_pixel(x, y)
			if c.a <= 0.0 or c.get_luminance() <= 0.12:
				continue
			var k := c.get_luminance() / media
			imagem.set_pixel(x, y, Color(minf(1.0, cor.r * k), minf(1.0, cor.g * k), minf(1.0, cor.b * k), c.a))
	return ImageTexture.create_from_image(imagem)

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
	var desenho := _solto("botijao", CORES_DO_BOTIJAO[variante % 4])
	if variante % 5 == 4:
		# Deitado: o desenho de pe, girado.
		_elipse(Vector2(2, 0), Vector2(10, 3), SOMBRA, false)
		_deitado(desenho, -PI / 2.0)
		return
	_em_pe(desenho)

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
	_em_pe(_solto("lixeira", LARANJA_DA_LIXEIRA if variante % 2 == 1 else Color(0, 0, 0, 0)))
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

# --- a mobilia (21/10/2026) ----------------------------------------------------

## A pegada deste enfeite em mundo, com o pe no meio da borda de baixo.
func _base() -> Rect2:
	var p := pegada_de(tipo, olhando, tamanho)
	return Rect2(-p.x / 2.0, -p.y, p.x, p.y)

## O desenho gerado: de frente, o opaco de baixo no pe e no maximo a folga da
## parede acima da pegada; de costas ou de lado, a caixa na cor dele.
func _mobilia(textura: Texture2D) -> void:
	var medida := _medir(textura)
	var base := _base()
	if tipo == "rack_tv" and olhando == "norte":
		_tv_de_costas(base)
		return
	if olhando != "sul" and solido(tipo):
		_caixa_de_costas_ou_de_lado(base, medida["cor"], float(medida["fundo"] - medida["topo"] + 1) - base.size.y)
		return
	var tam := textura.get_size()
	var fundo := float(medida["fundo"]) + 1.0
	var topo := float(medida["topo"])
	var y := -fundo
	# Desenho mais alto que pegada + parede desce para dentro da sala.
	y = maxf(y, base.position.y - FOLGA_SOBRE_A_PAREDE - topo)
	draw_rect(Rect2(base.position.x + 3.0, -3.0, base.size.x, 5.0), SOMBRA)
	draw_texture(textura, Vector2(roundf(-tam.x / 2.0), roundf(y)))

## A TV de tubo vista de tras, virada para o sofa: o rack baixo de madeira e,
## em cima, o fundo da TV - a caixa cinza que afina, com a grade de ventilacao
## e o fio caindo.
func _tv_de_costas(base: Rect2) -> void:
	var rack := Rect2(base.position.x, base.end.y - 14.0, base.size.x, 14.0)
	draw_rect(Rect2(base.position.x + 3.0, -2.0, base.size.x, 4.0), SOMBRA)
	draw_rect(Rect2(base.position - Vector2(0, 14), base.size), MADEIRA.lightened(0.05))
	draw_rect(rack, MADEIRA.darkened(0.25))
	draw_rect(rack, CONTORNO, false, 1.0)
	draw_rect(Rect2(base.position - Vector2(0, 14), base.size), CONTORNO, false, 1.0)
	var meio := Vector2(0.0, base.position.y - 14.0 + base.size.y * 0.5)
	var fundo := PackedVector2Array([meio + Vector2(-20, 4), meio + Vector2(20, 4), meio + Vector2(14, -30), meio + Vector2(-14, -30)])
	draw_colored_polygon(fundo, Color("4a4c4a"))
	draw_colored_polygon(PackedVector2Array([meio + Vector2(-14, -30), meio + Vector2(14, -30), meio + Vector2(10, -36), meio + Vector2(-10, -36)]), Color("5e605e"))
	for k in 4:
		draw_line(meio + Vector2(-8, -24 + k * 5), meio + Vector2(8, -24 + k * 5), Color("2e302e"), 1.0)
	fundo.append(fundo[0])
	draw_polyline(fundo, CONTORNO, 1.0)
	draw_line(meio + Vector2(6, 4), meio + Vector2(12, 14), Color("1e1e1e"), 1.0)

func _caixa_de_costas_ou_de_lado(base: Rect2, cor: Color, altura: float) -> void:
	altura = clampf(altura, 10.0, 56.0)
	var cima := Rect2(base.position - Vector2(0.0, altura), base.size)
	var face := Rect2(Vector2(base.position.x, base.end.y - altura), Vector2(base.size.x, altura))
	draw_rect(Rect2(base.position.x + 3.0, -2.0, base.size.x, 4.0), SOMBRA)
	draw_rect(face, cor.darkened(0.28))
	draw_rect(cima, cor.lightened(0.08))
	draw_rect(cima.grow(-3.0), cor, false, 1.0)
	if olhando == "norte":
		for k in 2:
			var x := face.position.x + face.size.x * float(k + 1) / 3.0
			draw_line(Vector2(x, face.position.y + 2.0), Vector2(x, face.end.y - 2.0), cor.darkened(0.45), 1.0)
	else:
		draw_rect(Rect2(face.position.x, face.end.y - 4.0, face.size.x, 4.0), cor.darkened(0.45))
		var frente := cima.position.x + (cima.size.x - 2.0 if olhando == "leste" else 0.0)
		draw_rect(Rect2(frente, cima.position.y, 2.0, cima.size.y), cor.lightened(0.3))
	draw_rect(face, CONTORNO, false, 1.0)
	draw_rect(cima, CONTORNO, false, 1.0)

## A bancada da cozinha, sob medida e encostada na parede: tampo de granito
## com a cuba de inox (louca suja dentro) e o fogao de quatro bocas com a
## panela; a frente de armario so aparece quando ela olha para o sul.
func _bancada_cozinha() -> void:
	var base := _base()
	var altura := 20.0
	var cima := Rect2(base.position - Vector2(0.0, altura), base.size)
	var face := Rect2(Vector2(base.position.x, base.end.y - altura), Vector2(base.size.x, altura))
	draw_rect(Rect2(base.position.x + 3.0, -2.0, base.size.x, 4.0), SOMBRA)
	var armario := Color("cfc7b4")
	draw_rect(face, armario.darkened(0.12))
	if olhando == "sul":
		var portas := maxi(2, int(face.size.x / 22.0))
		for k in portas:
			var r := Rect2(face.position.x + 2.0 + k * (face.size.x - 4.0) / portas, face.position.y + 3.0,
				(face.size.x - 4.0) / portas - 2.0, face.size.y - 6.0)
			draw_rect(r, armario.darkened(0.04))
			draw_rect(r, armario.darkened(0.3), false, 1.0)
			draw_rect(Rect2(r.get_center() + Vector2(-2, -6), Vector2(4, 1)), Color("6a6a66"))
			if k == portas - 1 and variante % 2 == 0:
				# A porta que ficou aberta: o escuro de dentro.
				draw_rect(r.grow(-1.0), Color("2a241e"))
	draw_rect(Rect2(face.position.x, face.end.y - 3.0, face.size.x, 3.0), Color("3a332c"))
	draw_rect(cima, Color("7f7b74"))
	var semente := int(absf(base.position.x) * 3.0 + base.size.y * 7.0)
	for k in 30:
		var p := cima.position + Vector2(float((semente * (k + 3)) % 97) / 97.0, float((semente * (k + 11)) % 89) / 89.0) * cima.size
		draw_rect(Rect2(p, Vector2(1, 1)), Color("a29e96") if k % 2 else Color("5e5a54"))
	var deitada := cima.size.x >= cima.size.y
	var ao_longo := cima.size.x if deitada else cima.size.y
	var de_lado := cima.size.y if deitada else cima.size.x
	var onde := func(t: float) -> Vector2:
		return cima.position + (Vector2(ao_longo * t, de_lado * 0.5) if deitada else Vector2(de_lado * 0.5, ao_longo * t))
	# A cuba, com a louca.
	var cuba: Vector2 = onde.call(0.28)
	var tam_cuba := Vector2(24, 14) if deitada else Vector2(14, 24)
	draw_rect(Rect2(cuba - tam_cuba / 2.0, tam_cuba), Color("b7bcbf"))
	draw_rect(Rect2(cuba - tam_cuba / 2.0 + Vector2(2, 2), tam_cuba - Vector2(4, 4)), Color("8c9296"))
	draw_circle(cuba + Vector2(-3, 1), 3.0, Color("d8d4c8"))
	draw_circle(cuba + Vector2(3, -1), 3.0, Color("c9b38a"))
	draw_rect(Rect2(cuba - tam_cuba / 2.0, tam_cuba), CONTORNO, false, 1.0)
	# O fogao, com a panela esquecida.
	var fogao: Vector2 = onde.call(0.72)
	var tam_fogao := Vector2(26, 18) if deitada else Vector2(18, 26)
	draw_rect(Rect2(fogao - tam_fogao / 2.0, tam_fogao), Color("e3dfd4"))
	draw_rect(Rect2(fogao - tam_fogao / 2.0 + Vector2(2, 2), tam_fogao - Vector2(4, 4)), Color("2e2e2c"))
	for dx in [-1.0, 1.0]:
		for dy in [-1.0, 1.0]:
			var b := fogao + Vector2(dx * tam_fogao.x / 4.5, dy * tam_fogao.y / 4.5)
			draw_arc(b, 3.0, 0.0, TAU, 8, Color("6a6a66"), 1.0)
	draw_circle(fogao + Vector2(tam_fogao.x / 4.5, -tam_fogao.y / 4.5), 4.0, Color("4a4c4e"))
	draw_rect(Rect2(fogao - tam_fogao / 2.0, tam_fogao), CONTORNO, false, 1.0)
	draw_rect(cima, CONTORNO, false, 1.0)
	draw_rect(face, CONTORNO, false, 1.0)

## O box: o piso de azulejo pequeno, o ralo, o vidro e o chuveiro na parede.
func _box_chuveiro() -> void:
	var base := _base()
	draw_rect(base, Color("c9cfd0"))
	var x := base.position.x
	while x < base.end.x:
		draw_line(Vector2(x, base.position.y), Vector2(x, base.end.y), Color("9aa2a4"), 1.0)
		x += 6.0
	var y := base.position.y
	while y < base.end.y:
		draw_line(Vector2(base.position.x, y), Vector2(base.end.x, y), Color("9aa2a4"), 1.0)
		y += 6.0
	draw_circle(base.get_center(), 3.0, Color("5a6266"))
	draw_circle(base.get_center() + Vector2(6, -8), 6.0, Color(0.2, 0.1, 0.05, 0.25))
	# O chuveiro na parede de tras e o cano.
	draw_line(Vector2(0, base.position.y - 26.0), Vector2(0, base.position.y - 6.0), Color("8a8e90"), 2.0)
	draw_circle(Vector2(0, base.position.y - 6.0), 4.0, Color("b0b4b6"))
	# O vidro da frente, de pe: um quadro com reflexo.
	var vidro := Rect2(base.position.x, base.end.y - 46.0, base.size.x, 46.0)
	draw_rect(vidro, Color(0.75, 0.88, 0.92, 0.18))
	draw_line(vidro.position + Vector2(6, 40), vidro.position + Vector2(20, 6), Color(1, 1, 1, 0.3), 2.0)
	draw_rect(vidro, Color("9aa0a2"), false, 1.0)
	draw_rect(base, CONTORNO, false, 1.0)

func _vaso_sanitario() -> void:
	var base := _base()
	var branco := Color("e6e3da")
	draw_rect(Rect2(base.position.x + 1, base.position.y - 12, base.size.x - 2, 10), branco.darkened(0.06))
	draw_rect(Rect2(base.position.x + 1, base.position.y - 16, base.size.x - 2, 5), branco)
	draw_rect(Rect2(base.position.x + 1, base.position.y - 16, base.size.x - 2, 14), CONTORNO, false, 1.0)
	_elipse(Vector2(0, base.position.y + 10), Vector2(8, 9), branco)
	_elipse(Vector2(0, base.position.y + 11), Vector2(5, 6), Color("8fa3a8"))
	draw_rect(Rect2(-4, -6, 8, 6), branco.darkened(0.15))

func _pia_banheiro() -> void:
	var base := _base()
	# O espelho na parede, por cima da pia.
	var espelho := Rect2(-9, base.position.y - 40.0, 18, 16)
	draw_rect(espelho, Color("7f97a0"))
	draw_line(espelho.position + Vector2(3, 13), espelho.position + Vector2(12, 3), Color(1, 1, 1, 0.35), 1.0)
	draw_line(espelho.position + Vector2(10, 2), espelho.position + Vector2(16, 12), Color("2a2a2a"), 1.0)
	draw_rect(espelho, CONTORNO, false, 1.0)
	draw_rect(Rect2(-3, -14, 6, 14), Color("d8d4ca"))
	draw_rect(Rect2(-3, -14, 6, 14), CONTORNO, false, 1.0)
	_elipse(Vector2(0, -16), Vector2(11, 6), Color("e6e3da"))
	_elipse(Vector2(0, -16), Vector2(7, 3), Color("a8b4b8"))

func _criado_mudo() -> void:
	var base := _base()
	_caixa(base, 16.0, MADEIRA.lightened(0.08), MADEIRA)
	draw_rect(Rect2(base.position.x + 3, base.end.y - 11, base.size.x - 6, 6), MADEIRA.darkened(0.2), false, 1.0)
	# O abajur, de cupula torta.
	draw_line(Vector2(-4, base.position.y - 14), Vector2(-4, base.position.y - 24), Color("3a3a38"), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, base.position.y - 24), Vector2(2, base.position.y - 26),
		Vector2(0, base.position.y - 34), Vector2(-8, base.position.y - 33)]), Color("c9b98a"))

## O guarda-roupa de MDF branco, tres portas e o espelho do meio: alto, de
## frente, encostado na parede norte do quarto.
func _guarda_roupa() -> void:
	var base := _base()
	var altura := 64.0
	var cima := Rect2(base.position - Vector2(0.0, altura), base.size)
	var face := Rect2(Vector2(base.position.x, base.end.y - altura), Vector2(base.size.x, altura))
	draw_rect(Rect2(base.position.x + 3.0, -2.0, base.size.x, 4.0), SOMBRA)
	var mdf := Color("d6d0c2")
	draw_rect(face, mdf.darkened(0.08))
	var terco := face.size.x / 3.0
	for k in 3:
		var r := Rect2(face.position.x + k * terco + 1.0, face.position.y + 2.0, terco - 2.0, face.size.y - 6.0)
		draw_rect(r, Color("8fa0a6") if k == 1 else mdf)
		if k == 1:
			draw_line(r.position + Vector2(3, r.size.y - 6), r.position + Vector2(r.size.x - 4, 8), Color(1, 1, 1, 0.3), 2.0)
		draw_rect(r, mdf.darkened(0.3), false, 1.0)
		draw_rect(Rect2(r.position.x + (r.size.x - 3.0 if k == 0 else 1.0), r.get_center().y - 4.0, 2, 8), Color("6a6a66"))
	if variante % 2 == 0:
		# Uma porta aberta e a roupa caindo.
		var aberta := Rect2(face.position.x + 1.0, face.position.y + 2.0, terco - 2.0, face.size.y - 6.0)
		draw_rect(aberta, Color("2a241e"))
		draw_rect(Rect2(aberta.position.x + 3, aberta.position.y + 6, 8, 20), Color("6a7a9a"))
		draw_rect(Rect2(aberta.position.x + 12, aberta.position.y + 8, 7, 16), Color("9a5a4a"))
	draw_rect(cima, mdf.lightened(0.05))
	draw_rect(face, CONTORNO, false, 1.0)
	draw_rect(cima, CONTORNO, false, 1.0)

func _tapete() -> void:
	var base := _base()
	var cores := [Color("7a4a3a"), Color("4a5a6a"), Color("6a6a4a")]
	var cor: Color = cores[variante % cores.size()]
	draw_rect(base, cor)
	draw_rect(base.grow(-4.0), cor.lightened(0.15), false, 2.0)
	draw_rect(base.grow(-8.0), cor.darkened(0.15), false, 1.0)
	for k in 3:
		draw_circle(base.get_center() + Vector2(-10 + k * 10, 0), 3.0, cor.lightened(0.25))
	draw_circle(base.get_center() + Vector2(8, 4), 6.0, Color(0.15, 0.1, 0.06, 0.25))
	draw_rect(base, CONTORNO, false, 1.0)

func _roupas() -> void:
	var cores := [Color("6a7a9a"), Color("9a5a4a"), Color("d8d4c8"), Color("4a5a3a")]
	for k in 4:
		var p := Vector2(-14 + k * 9, -4 - (k % 2) * 6)
		var cor: Color = cores[(k + variante) % cores.size()]
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(10, -2), p + Vector2(12, 6), p + Vector2(1, 8)]), cor)
		draw_polyline(PackedVector2Array([p, p + Vector2(10, -2), p + Vector2(12, 6), p + Vector2(1, 8), p]), CONTORNO, 1.0)

func _colchao() -> void:
	var base := _base()
	var r := Rect2(base.position - Vector2(0, 6), base.size)
	draw_rect(Rect2(r.position.x, r.end.y, r.size.x, 6), Color("8a8270"))
	draw_rect(r, Color("b8b09a"))
	var y := r.position.y + 4.0
	while y < r.end.y:
		draw_line(Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), Color("a39b84"), 1.0)
		y += 8.0
	draw_circle(r.get_center() + Vector2(-6, 8), 9.0, Color(0.35, 0.25, 0.12, 0.35))
	# O cobertor embolado.
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(4, r.size.y * 0.45), r.position + Vector2(r.size.x - 2, r.size.y * 0.38),
		r.end - Vector2(6, 10), Vector2(r.position.x + 8, r.end.y - 4)]), Color("5a6a4a"))
	draw_rect(r, CONTORNO, false, 1.0)

## A grade da cela: barras de pe ao longo da pegada, com a porta aberta no
## meio (variante 1) para ninguem ficar preso sem querer.
func _grade_cela() -> void:
	var base := _base()
	var altura := 52.0
	var ao_longo_x := base.size.x >= base.size.y
	var comprimento := base.size.x if ao_longo_x else base.size.y
	var t := 0.0
	while t <= comprimento:
		var porta := variante % 2 == 1 and absf(t - comprimento / 2.0) < 16.0
		if not porta:
			var p := base.position + (Vector2(t, base.size.y) if ao_longo_x else Vector2(base.size.x / 2.0, t))
			draw_line(p, p - Vector2(0, altura), Color("3a3c3e"), 2.0)
		t += 6.0
	var a := base.position + (Vector2(0, base.size.y) if ao_longo_x else Vector2(base.size.x / 2.0, 0))
	var b := a + (Vector2(comprimento, 0) if ao_longo_x else Vector2(0, comprimento))
	for h in [altura, altura * 0.5, 2.0]:
		draw_line(a - Vector2(0, h), b - Vector2(0, h), Color("4a4c4e"), 2.0)

func _cadeiras_espera() -> void:
	var base := _base()
	if olhando == "norte":
		# De costas, viradas para as mesas: o assento em cima e o encosto
		# embaixo, de costas para a camera.
		draw_rect(Rect2(base.position.x, -4, base.size.x, 3), Color("5a5c5e"))
		for k in 3:
			var x := base.position.x + 2.0 + k * (base.size.x - 4.0) / 3.0
			var w := (base.size.x - 4.0) / 3.0 - 2.0
			draw_rect(Rect2(x, -26, w, 10), Color("3f6a8f"))
			draw_rect(Rect2(x, -18, w, 14), Color("2f4f6a"))
			draw_line(Vector2(x + 2, -15), Vector2(x + w - 2, -15), Color("25405a"), 1.0)
			draw_rect(Rect2(x, -26, w, 22), CONTORNO, false, 1.0)
		return
	draw_rect(Rect2(base.position.x, -4, base.size.x, 3), Color("5a5c5e"))
	for k in 3:
		var x := base.position.x + 2.0 + k * (base.size.x - 4.0) / 3.0
		var w := (base.size.x - 4.0) / 3.0 - 2.0
		draw_rect(Rect2(x, -18, w, 10), Color("3f6a8f"))
		draw_rect(Rect2(x, -30, w, 12), Color("355a7a"))
		draw_rect(Rect2(x, -30, w, 22), CONTORNO, false, 1.0)

func _papeis() -> void:
	for k in 7:
		var p := Vector2(-20 + (k * 13) % 40, -6 - (k * 7) % 14)
		var dir := Vector2(cos(k * 1.7), sin(k * 1.7))
		var lado := Vector2(-dir.y, dir.x)
		var folha := PackedVector2Array([p, p + dir * 9.0, p + dir * 9.0 + lado * 7.0, p + lado * 7.0])
		draw_colored_polygon(folha, Color(0.88, 0.86, 0.8, 0.95))
		draw_line(p + lado * 2.0, p + dir * 7.0 + lado * 2.0, Color(0.3, 0.3, 0.35, 0.6), 1.0)

## O bebedouro de galao: o corpo branco e o galao azul, meio vazio.
func _bebedouro() -> void:
	var base := _base()
	_caixa(base, 26.0, Color("d8d4ca"), Color("c2beb4"))
	draw_rect(Rect2(base.position.x + 2, base.end.y - 18, 4, 3), Color("3e6fa0"))
	draw_rect(Rect2(base.end.x - 6, base.end.y - 18, 4, 3), Color("b8473c"))
	var galao := Rect2(base.position.x + 1, base.position.y - 46, base.size.x - 2, 20)
	draw_rect(galao, Color(0.55, 0.72, 0.85, 0.85))
	draw_rect(Rect2(galao.position.x, galao.position.y, galao.size.x, 8), Color(0.75, 0.85, 0.9, 0.6))
	draw_rect(galao, CONTORNO, false, 1.0)

func _fogareiro() -> void:
	_sombra_redonda(9.0)
	draw_rect(Rect2(-8, -10, 16, 10), Color("4a4c4e"))
	draw_arc(Vector2(0, -12), 6.0, 0.0, TAU, 10, Color("8a8c8e"), 2.0)
	draw_rect(Rect2(10, -14, 8, 14), Color("3e6fa0"))
	draw_rect(Rect2(-8, -10, 16, 10), CONTORNO, false, 1.0)

func _latas() -> void:
	for k in 5:
		var p := Vector2(-12 + k * 6, -2 - (k % 2) * 5)
		draw_rect(Rect2(p - Vector2(2, 5), Vector2(5, 6)), [Color("a83a32"), Color("c9a032"), Color("8a8c8e")][k % 3] as Color)
		draw_rect(Rect2(p - Vector2(2, 5), Vector2(5, 6)), CONTORNO, false, 1.0)
