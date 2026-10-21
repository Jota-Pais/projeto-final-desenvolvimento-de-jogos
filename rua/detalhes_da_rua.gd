extends Node2D
## O chao com detalhe (21/10/2026), por cima do asfalto e da calcada pintados
## (rua/ruas.gd) e por baixo de tudo que se ordena: a faixa amarela, a faixa de
## pedestre, o bueiro, a mancha de oleo e de sangue, a rachadura com mato, o
## buraco com agua, o lixo - e o piso de cada recorte coberto (a lajota da
## varanda, o deck da pizzaria, o cimento da garagem, o entulho da quina que
## desabou). Pedido do Joao: "as casas, construcoes e ruas mais detalhadas,
## principalmente dentro do tutorial".
##
## Os postes sao enfeites (rua/enfeite.gd) e os fios sao do rua/fiacao.gd; os
## dois leem POSTES daqui. Tudo em px do PNG do desenho, como os ROTULOS.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const Telhado := preload("res://rua/telhado.gd")

## A faixa amarela tracejada no meio das ruas de mao dupla da regiao.
const FAIXAS_DO_MEIO := [
	# A rua de cima, da beira do cerco a rotatoria.
	[Vector2(1083.0, 620.0), Vector2(1219.0, 620.0)],
	# A que desce da rotatoria para o sudeste.
	[Vector2(1238.0, 628.0), Vector2(1251.0, 657.0), Vector2(1264.0, 688.0), Vector2(1280.0, 726.0), Vector2(1289.0, 746.0)],
	# A avenida em diagonal, do oeste ate a pizzaria.
	[Vector2(1072.0, 652.0), Vector2(1115.0, 678.0), Vector2(1135.0, 689.0), Vector2(1180.0, 708.0), Vector2(1218.0, 725.0), Vector2(1272.0, 738.0)],
]

## As faixas de pedestre: o meio, para onde a rua corre (graus, 0 = leste) e
## a largura da rua (px de mundo).
const FAIXAS_DE_PEDESTRE := [
	{ "ponto": Vector2(1212.0, 620.0), "rumo": 0.0, "largura": 240.0 },
	{ "ponto": Vector2(1166.0, 620.0), "rumo": 0.0, "largura": 240.0 },
	{ "ponto": Vector2(1244.0, 645.0), "rumo": 66.0, "largura": 250.0 },
	{ "ponto": Vector2(1158.0, 699.0), "rumo": 23.0, "largura": 280.0 },
]

## Os postes, cada rua uma fileira (os fios correm de um para o proximo). O
## ponto e o guia: o poste vai para a calcada mais perto dele, na beira do
## meio-fio (`postes()`).
const FILEIRAS_DE_POSTES := [
	[Vector2(1092.0, 614.0), Vector2(1140.0, 614.0), Vector2(1188.0, 614.0), Vector2(1222.0, 611.0)],
	[Vector2(1230.0, 640.0), Vector2(1242.0, 668.0), Vector2(1254.0, 697.0), Vector2(1268.0, 728.0)],
	[Vector2(1095.0, 662.0), Vector2(1140.0, 684.0), Vector2(1184.0, 702.0), Vector2(1230.0, 718.0)],
]

## Os fios que descem do poste para uma casa (o "gato" de cada uma): indice
## da fileira, do poste, e o ponto do telhado (PNG).
const LIGACOES := [
	[0, 2, Vector2(1180.0, 635.0)],
	[0, 3, Vector2(1206.0, 637.0)],
	[0, 1, Vector2(1126.0, 634.0)],
]

## Coisas soltas na calcada: lixeira, orelhao, placa, saco de lixo.
const NA_RUA := [
	{ "tipo": "orelhao", "png": Vector2(1160.0, 612.0) },
	{ "tipo": "lixeira", "png": Vector2(1118.0, 612.5), "variante": 2 },
	{ "tipo": "saco_de_lixo", "png": Vector2(1121.0, 612.5), "variante": 1 },
	{ "tipo": "placa_pare", "png": Vector2(1224.5, 626.0) },
	{ "tipo": "lixeira", "png": Vector2(1250.0, 700.0), "variante": 1 },
	{ "tipo": "saco_de_lixo", "png": Vector2(1252.0, 701.0) },
	{ "tipo": "saco_de_lixo", "png": Vector2(1176.0, 734.0), "variante": 1 },
	{ "tipo": "pneu", "png": Vector2(1232.0, 735.0) },
	{ "tipo": "placa_pare", "png": Vector2(1150.0, 697.5) },
]

## As pedras soltas no chao, que se pegam com E para arremessar (21/10/2026):
## perto do entulho e no caminho do portao do Antonio ate a pizzaria, que e
## onde o radio ensina a jogar.
const PEDRAS_NO_CHAO := [
	Vector2(1219.0, 626.5), Vector2(1196.0, 662.0), Vector2(1178.0, 700.0), Vector2(1192.0, 731.0),
	Vector2(1148.0, 668.0), Vector2(1262.0, 702.0), Vector2(1238.0, 748.0), Vector2(1112.0, 662.0),
]

## Quantos detalhes soltos (mancha, rachadura, lixo) espalhar na regiao.
const ESPALHADOS := 260
const AMARELO := Color(0.86, 0.72, 0.28, 0.85)
const BRANCO := Color(0.86, 0.85, 0.8, 0.8)

static var _postes_prontos: Array = []

## Os postes ja no lugar: uma lista por fileira, em mundo.
static func postes() -> Array:
	if not _postes_prontos.is_empty():
		return _postes_prontos
	for fileira in FILEIRAS_DE_POSTES:
		var lista: Array[Vector2] = []
		for guia in fileira:
			lista.append(_na_calcada(Mapa.ponto_do_png(guia)))
		_postes_prontos.append(lista)
	return _postes_prontos

## A classe de chao num ponto: a do menor poligono que o contem (e a ordem em
## que o rua/ruas.gd pinta: o menor por cima).
static func classe_em(ponto: Vector2) -> String:
	var melhor := ""
	var menor := INF
	for p in Mapa.mundo()["poligonos"]:
		if not (p["rect"] as Rect2).has_point(ponto) or float(p["area"]) >= menor:
			continue
		if not Geometry2D.is_point_in_polygon(ponto, p["pontos"]):
			continue
		var no_furo := false
		for furo in p["furos"]:
			if Geometry2D.is_point_in_polygon(ponto, furo):
				no_furo = true
				break
		if no_furo:
			continue
		menor = float(p["area"])
		melhor = p["classe"]
	return melhor

## O ponto de calcada mais perto do guia que tem asfalto a ate 40 px: a beira
## do meio-fio. Sem nenhum num raio de 300 px, fica o guia.
static func _na_calcada(guia: Vector2) -> Vector2:
	var melhor := guia
	var menor := INF
	for raio in range(0, 301, 12):
		for k in 24:
			var a := TAU * k / 24.0
			var p := guia + Vector2(cos(a), sin(a)) * float(raio)
			if classe_em(p) != "pavimento" or Mapa.construcao_em(p) >= 0:
				continue
			var beira := false
			for j in 8:
				var b := TAU * j / 8.0
				if classe_em(p + Vector2(cos(b), sin(b)) * 40.0) == "asfalto":
					beira = true
					break
			if beira and guia.distance_to(p) < menor:
				menor = guia.distance_to(p)
				melhor = p
		if menor < INF:
			break
	return melhor.round()

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	for construcao in Mapa.mundo()["construcoes"]:
		_pisos_dos_recortes(construcao)
		for piso in construcao.get("pisos_extras", []):
			_piso_de_dentro(piso["tipo"], piso["rect"])
	for linha in FAIXAS_DO_MEIO:
		_faixa_do_meio(linha)
	for faixa in FAIXAS_DE_PEDESTRE:
		_faixa_de_pedestre(Mapa.ponto_do_png(faixa["ponto"]), deg_to_rad(faixa["rumo"]), faixa["largura"])
	_espalhar()

# --- o piso dos recortes ----------------------------------------------------------

func _pisos_dos_recortes(construcao: Dictionary) -> void:
	if not construcao.has("recortes"):
		return
	var recortes := Construcao.recortes_de(construcao)
	for i in recortes.size():
		var r := recortes[i]
		match construcao["recortes"][i].get("cobertura", ""):
			"varanda":
				_lajota(r)
			"pergolado":
				_deck(r)
			"garagem", "area":
				_cimento(r)
			"lona":
				draw_rect(r, Color(0.36, 0.3, 0.22, 0.55))
			"desabou":
				_desabou(r)

## A lajota vermelha da varanda, de 20 px, com a junta clara.
func _lajota(r: Rect2) -> void:
	draw_rect(r, Color("8a4a3a"))
	var x := r.position.x
	while x <= r.end.x:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color("b08a74"), 1.0)
		x += 20.0
	var y := r.position.y
	while y <= r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("b08a74"), 1.0)
		y += 20.0
	draw_rect(r, Telhado.CONTORNO, false, 1.0)

func _deck(r: Rect2) -> void:
	draw_rect(r, Color("7a5a3c"))
	var y := r.position.y
	var k := 0
	while y < r.end.y:
		draw_rect(Rect2(r.position.x, y, r.size.x, 9.0), Color("86643f") if k % 2 == 0 else Color("74563a"))
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("4a3424"), 1.0)
		var emenda := r.position.x + float((k * 53) % 90) + 20.0
		while emenda < r.end.x:
			draw_line(Vector2(emenda, y), Vector2(emenda, y + 9.0), Color("4a3424"), 1.0)
			emenda += 90.0
		y += 10.0
		k += 1
	draw_rect(r, Telhado.CONTORNO, false, 1.0)

func _cimento(r: Rect2) -> void:
	draw_rect(r, Color("8d8a82"))
	draw_rect(r.grow(-6.0), Color("96938a"))
	draw_circle(r.get_center() + Vector2(10, 6), 14.0, Color(0.15, 0.12, 0.1, 0.18))
	draw_rect(r, Telhado.CONTORNO, false, 1.0)

## A quina que desabou: o monte de tijolo, bloco e ferro que caiu.
func _desabou(r: Rect2) -> void:
	draw_rect(r, Color(0.32, 0.3, 0.27, 0.5))
	var semente := int(r.position.x) * 7 + int(r.position.y)
	for k in 70:
		var p := r.position + Vector2(float((semente * (k + 1) * 31) % 1009) / 1009.0 * r.size.x,
			float((semente * (k + 7) * 17) % 997) / 997.0 * r.size.y)
		var tamanho := Vector2(6 + k % 9, 4 + k % 6)
		var cor := Color("8a857b") if k % 3 else Color("9a5a3e")
		if k % 7 == 0:
			cor = Color("b9b5aa")
		draw_rect(Rect2(p, tamanho), cor)
		draw_rect(Rect2(p, tamanho), Telhado.CONTORNO, false, 1.0)
	for k in 5:
		var p := r.position + Vector2(r.size.x * (0.2 + k * 0.15), r.size.y * (0.3 + (k % 2) * 0.3))
		draw_line(p, p + Vector2(30, -14 + k * 5), Color("5a3a2a"), 2.0)

## O piso de um comodo (rua/arquitetura.gd, 21/10/2026): taco na sala e no
## quarto, lajota na cozinha, azulejo no banheiro, granilite na Delegacia, o
## xadrez preto e branco da pizzaria. Por cima, a sujeira de quem saqueou.
func _piso_de_dentro(tipo: String, r: Rect2) -> void:
	match tipo:
		"taco":
			draw_rect(r, Color("6e5238"))
			var y := r.position.y
			var k := 0
			while y < r.end.y:
				var alto := minf(8.0, r.end.y - y)
				draw_rect(Rect2(r.position.x, y, r.size.x, alto), Color("735740") if k % 2 == 0 else Color("684c34"))
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("4e3826"), 1.0)
				var x := r.position.x + float((k * 23) % 40)
				while x < r.end.x:
					draw_line(Vector2(x, y), Vector2(x, y + alto), Color("4e3826"), 1.0)
					x += 40.0
				y += 8.0
				k += 1
		"lajota":
			_ladrilho(r, 20.0, Color("a3957d"), Color("9b8d76"), Color("6f6555"))
		"azulejo":
			_ladrilho(r, 10.0, Color("c4c8c2"), Color("bcc0ba"), Color("8e9490"))
		"xadrez":
			_ladrilho(r, 20.0, Color("cfc9bb"), Color("393530"), Color("2a2622"))
		"granilite":
			draw_rect(r, Color("8f8b82"))
			var semente := int(r.position.x) * 13 + int(r.position.y)
			for k in int(r.get_area() / 60.0):
				var p := r.position + Vector2(float((semente * (k + 3) * 31) % 1009) / 1009.0 * r.size.x,
					float((semente * (k + 7) * 17) % 997) / 997.0 * r.size.y)
				draw_rect(Rect2(p, Vector2(1, 1)), [Color("b8b3a8"), Color("5e5a54"), Color("a07a5a")][k % 3] as Color)
			var y := r.position.y + 60.0
			while y < r.end.y:
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("6e6a62"), 1.0)
				y += 60.0
		_:
			_cimento(r)
			return
	# A sujeira do saque e da chuva que entrou: manchas e marca de pe.
	var s := int(r.position.x * 7.0 + r.position.y * 3.0)
	for k in 3:
		var p := r.position + Vector2(float((s * (k + 2) * 37) % 997) / 997.0, float((s * (k + 5) * 53) % 991) / 991.0) * r.size
		draw_circle(p, 8.0 + float(k) * 5.0, Color(0.12, 0.09, 0.06, 0.18))

func _ladrilho(r: Rect2, lado: float, a: Color, b: Color, junta: Color) -> void:
	var y := r.position.y
	var fila := 0
	while y < r.end.y:
		var x := r.position.x
		var coluna := 0
		while x < r.end.x:
			var q := Rect2(x, y, minf(lado, r.end.x - x), minf(lado, r.end.y - y))
			draw_rect(q, a if (fila + coluna) % 2 == 0 else b)
			x += lado
			coluna += 1
		y += lado
		fila += 1
	var gx := r.position.x
	while gx <= r.end.x:
		draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), junta, 1.0)
		gx += lado
	var gy := r.position.y
	while gy <= r.end.y:
		draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), junta, 1.0)
		gy += lado

# --- a rua ---------------------------------------------------------------------------

func _faixa_do_meio(linha: Array) -> void:
	for i in linha.size() - 1:
		var a := Mapa.ponto_do_png(linha[i])
		var b := Mapa.ponto_do_png(linha[i + 1])
		var comprimento := a.distance_to(b)
		var dir := (b - a) / comprimento
		var t := 0.0
		while t < comprimento:
			var fim := minf(t + 48.0, comprimento)
			draw_line(a + dir * t, a + dir * fim, AMARELO, 5.0)
			t += 96.0

func _faixa_de_pedestre(centro: Vector2, rumo: float, largura: float) -> void:
	var ao_longo := Vector2(cos(rumo), sin(rumo))
	var atravessa := Vector2(-ao_longo.y, ao_longo.x)
	var d := -largura / 2.0 + 14.0
	while d < largura / 2.0 - 10.0:
		var meio := centro + atravessa * d
		var pontos := PackedVector2Array([meio - ao_longo * 26.0 - atravessa * 7.0, meio + ao_longo * 26.0 - atravessa * 7.0,
			meio + ao_longo * 26.0 + atravessa * 7.0, meio - ao_longo * 26.0 + atravessa * 7.0])
		draw_colored_polygon(pontos, BRANCO)
		d += 26.0

## O que se espalha pela regiao: no asfalto, bueiro, mancha de oleo, buraco
## com agua, marca de freada e sangue; na calcada, rachadura com mato, folha e
## papel. O sorteio e fixo: a rua e a mesma todo dia.
func _espalhar() -> void:
	var regiao := Mapa.regiao_do_tutorial()
	if regiao.size() < 3:
		return
	var caixa := Rect2(regiao[0], Vector2.ZERO)
	for p in regiao:
		caixa = caixa.expand(p)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20261021
	for k in ESPALHADOS:
		var p := caixa.position + Vector2(sorteio.randf(), sorteio.randf()) * caixa.size
		var qual := sorteio.randi() % 100
		var giro := sorteio.randf() * TAU
		if not Geometry2D.is_point_in_polygon(p, regiao) or Mapa.construcao_em(p) >= 0:
			continue
		match classe_em(p):
			"asfalto":
				if qual < 12:
					_bueiro(p)
				elif qual < 40:
					_mancha(p, Color(0.05, 0.05, 0.06, 0.32), 14.0 + float(qual % 7) * 3.0)
				elif qual < 52:
					_buraco(p)
				elif qual < 64:
					_freada(p, giro)
				elif qual < 72:
					_mancha(p, Color(0.35, 0.05, 0.04, 0.45), 10.0 + float(qual % 5) * 2.0)
				else:
					_rachadura(p, giro, sorteio)
			"pavimento":
				if qual < 40:
					_rachadura(p, giro, sorteio)
				elif qual < 62:
					_folhas(p, sorteio)
				elif qual < 78:
					_papel(p, giro)
				elif qual < 88:
					_mancha(p, Color(0.1, 0.08, 0.06, 0.2), 12.0)
				else:
					_mato_na_junta(p, sorteio)
			"gramado", "grama":
				if qual < 30:
					_papel(p, giro)

func _bueiro(p: Vector2) -> void:
	draw_circle(p, 13.0, Color("3a3a38"))
	draw_circle(p, 11.0, Color("55524c"))
	for k in 4:
		draw_line(p + Vector2(-8, -6 + k * 4), p + Vector2(8, -6 + k * 4), Color("3a3a38"), 1.0)
	draw_arc(p, 13.0, 0.0, TAU, 16, Color(0, 0, 0, 0.5), 1.0)

func _mancha(p: Vector2, cor: Color, raio: float) -> void:
	draw_circle(p, raio, cor)
	draw_circle(p + Vector2(raio * 0.6, raio * 0.3), raio * 0.55, cor)
	draw_circle(p + Vector2(-raio * 0.5, raio * 0.4), raio * 0.4, cor)

func _buraco(p: Vector2) -> void:
	var pontos := PackedVector2Array()
	for k in 9:
		var a := TAU * k / 9.0
		pontos.append(p + Vector2(cos(a) * (16.0 + float(k % 3) * 4.0), sin(a) * (11.0 + float(k % 2) * 3.0)))
	draw_colored_polygon(pontos, Color("2a2824"))
	draw_colored_polygon(Geometry2D.offset_polygon(pontos, -4.0)[0] if not Geometry2D.offset_polygon(pontos, -4.0).is_empty() else pontos,
		Color(0.25, 0.32, 0.36, 0.8))
	pontos.append(pontos[0])
	draw_polyline(pontos, Color(0.05, 0.05, 0.05, 0.6), 1.0)

func _freada(p: Vector2, giro: float) -> void:
	var dir := Vector2(cos(giro), sin(giro))
	var lado := Vector2(-dir.y, dir.x) * 14.0
	for s in [-1.0, 1.0]:
		draw_line(p + lado * s, p + lado * s + dir * 120.0, Color(0.03, 0.03, 0.03, 0.3), 5.0)

func _rachadura(p: Vector2, giro: float, sorteio: RandomNumberGenerator) -> void:
	var pontos := PackedVector2Array([p])
	var dir := Vector2(cos(giro), sin(giro))
	for k in 6:
		dir = dir.rotated(sorteio.randf_range(-0.7, 0.7))
		pontos.append(pontos[pontos.size() - 1] + dir * sorteio.randf_range(6.0, 14.0))
	draw_polyline(pontos, Color(0.08, 0.07, 0.06, 0.5), 1.0)
	if sorteio.randf() < 0.5:
		var q := pontos[pontos.size() / 2]
		draw_line(q, q + Vector2(-2, -5), Color("5a7a36"), 1.0)
		draw_line(q, q + Vector2(2, -4), Color("6a8a3e"), 1.0)

func _folhas(p: Vector2, sorteio: RandomNumberGenerator) -> void:
	for k in 5:
		var q := p + Vector2(sorteio.randf_range(-14, 14), sorteio.randf_range(-8, 8))
		var cor := [Color("8a6a2e"), Color("6e5a28"), Color("9a7a3a")][k % 3] as Color
		draw_rect(Rect2(q, Vector2(4, 2)), cor)

func _papel(p: Vector2, giro: float) -> void:
	var dir := Vector2(cos(giro), sin(giro))
	var lado := Vector2(-dir.y, dir.x)
	var pontos := PackedVector2Array([p, p + dir * 9.0, p + dir * 9.0 + lado * 6.0, p + lado * 6.0])
	draw_colored_polygon(pontos, Color(0.85, 0.83, 0.76, 0.85))
	draw_line(p + lado * 2.0, p + dir * 7.0 + lado * 2.0, Color(0.4, 0.4, 0.45, 0.5), 1.0)

func _mato_na_junta(p: Vector2, sorteio: RandomNumberGenerator) -> void:
	for k in 4:
		var q := p + Vector2(sorteio.randf_range(-6, 6), 0)
		draw_line(q, q + Vector2(sorteio.randf_range(-3, 3), -sorteio.randf_range(4, 8)), Color("5a7a36"), 1.0)
