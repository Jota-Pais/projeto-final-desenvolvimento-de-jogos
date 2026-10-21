## Uma barreira: muro, cerca ou barricada ao longo de uma linha (21/10/2026).
##
## Pedido do Joao (20/10): o tutorial se passa so na regiao rosa em volta da
## casa nova, e o cerco dela fica sempre, por enquanto; no mapa todo, ninguem
## mais corta terreno - "faz muros, barricadas e coisas varias, quero
## criatividade, entao nao faz tudo num padrao so... seja coerente". O cerco
## nao e oficial: "carros jogados, onibus, entulhos... e so por consequencias
## do caos mesmo".
##
## **Nao e o mapa.** Por onde cada barreira passa esta em rua/mapa.gd
## (BARREIRAS e BARRICADAS); aqui moram as regras de cada tipo - o que ele
## segura, a espessura da colisao, a altura da face - e a geometria: os trechos
## que sobram depois de cortar os vaos e a forma de colisao de cada trecho.
##
## **Cada material, uma regra so** de ver e atirar (decisao do Joao: "alguns
## sim alguns nao, seja variado e criativo"; as camadas estao em
## rua/camadas.gd):
##
##  - muro de reboco, muro de bloco, faixa de entulho: nada passa;
##  - tapume de zinco, cerca de tabuas, portao de chapa: tapam a vista do
##    zumbi, mas a bala atravessa a chapa e a tabua;
##  - grade sobre mureta, alambrado, arame farpado, sacos de areia baixos com
##    concertina em cima: seguram so o corpo - da para ver e atirar atraves.
##
## A `altura` e a da face, em px de mundo, na regua do boneco (Joao, 20/10:
## muro de 2 m com ~41 px, perto do boneco de ~37). Hoje so desenha; e o que o
## agachar do tutorial vai usar para dizer o que esconde. A `espessura` e a da
## colisao e a do topo desenhado (a regua aprovada tem topo de 6 px): no
## minimo PASSO - corpo + 2 do conferir_mapa (hoje 4 px), senao uma barreira
## fina passa entre duas celulas da varredura.
##
## **Enquanto a arte nao vem, cada peca e desenhada em cinza** (a Peca, la
## embaixo): face e topo na vista inclinada, a face em grade quando o material
## e vazado. Os sprites do PixelLab entram por cima disto sem mudar o dado.

const Camadas := preload("res://rua/camadas.gd")

## Os materiais em linha. `cor` e so a do desenho provisorio.
const TIPOS := {
	"muro_reboco": { "camada": Camadas.SOLIDO, "espessura": 6.0, "altura": 41.0, "vazada": false, "cor": Color("b9b1a2") },
	"muro_bloco": { "camada": Camadas.SOLIDO, "espessura": 8.0, "altura": 41.0, "vazada": false, "cor": Color("8c8c86") },
	"entulho_linha": { "camada": Camadas.SOLIDO, "espessura": 24.0, "altura": 30.0, "vazada": false, "cor": Color("6f655a") },
	"tapume_zinco": { "camada": Camadas.CORPO_E_VISAO, "espessura": 6.0, "altura": 45.0, "vazada": false, "cor": Color("8a6a52") },
	"cerca_tabuas": { "camada": Camadas.CORPO_E_VISAO, "espessura": 8.0, "altura": 37.0, "vazada": false, "cor": Color("7a5f45") },
	"portao_chapa": { "camada": Camadas.CORPO_E_VISAO, "espessura": 8.0, "altura": 45.0, "vazada": false, "cor": Color("6e5848") },
	"mureta_grade": { "camada": Camadas.SO_CORPO, "espessura": 8.0, "altura": 37.0, "vazada": true, "cor": Color("5c5f60") },
	"alambrado": { "camada": Camadas.SO_CORPO, "espessura": 6.0, "altura": 41.0, "vazada": true, "cor": Color("9da3a3") },
	"arame_farpado": { "camada": Camadas.SO_CORPO, "espessura": 6.0, "altura": 30.0, "vazada": true, "cor": Color("6b6660") },
	"sacos_areia": { "camada": Camadas.SO_CORPO, "espessura": 20.0, "altura": 20.0, "vazada": false, "cor": Color("a39274") },
}

## As barricadas soltas (onibus, carro, cacamba, entulho): um retangulo girado,
## em px de mundo, que segura tudo. O `tamanho` e (comprimento, largura): o
## eixo comprido em x, que o `giro_graus` do dado aponta - horario a partir do
## leste, a convencao do desenho (ate 21/10/2026 era o contrario, e toda
## barricada ficava atravessada 90 graus). O carro reaproveita o sprite dos
## carros da rua, que e em pe, sem vasculho - e outro objeto, nao um movel; a
## tinta e, no tombado, a faixa escura do chassi o separam dos carros que se
## vasculham. A `altura`, como a das barreiras, e a da regua do boneco
## (~20,5 px por metro): hoje so desenha; e o que o agachar vai usar para
## dizer que cacamba de 1 m esconde quem esta agachado e nao quem esta de pe.
const OBJETOS := {
	"onibus": { "tamanho": Vector2(380.0, 110.0), "altura": 60.0, "cor": Color("8a7a4e") },
	"carro_tombado": { "tamanho": Vector2(180.0, 80.0), "altura": 37.0, "cor": Color("6b6e70"),
		"desenho": "res://rua/arte/objetos/carro-em-pe.png", "tinta": Color(0.7, 0.72, 0.78), "chassi": true },
	"carro_queimado": { "tamanho": Vector2(180.0, 80.0), "altura": 30.0, "cor": Color("3a3533"),
		"desenho": "res://rua/arte/objetos/carro-em-pe.png", "tinta": Color(0.32, 0.29, 0.27) },
	"cacamba": { "tamanho": Vector2(170.0, 90.0), "altura": 20.0, "cor": Color("8a5a3c") },
	"monte_entulho": { "tamanho": Vector2(120.0, 120.0), "altura": 23.0, "cor": Color("6f655a") },
}

## Vao padrao, igual ao da porta de predio (Construcao.VAO), e o minimo que a
## navegacao do zumbi ainda atravessa: com raio de meia celula em cada ponta,
## vao menor que 64 fecha a grade.
const VAO := 100.0
const VAO_MINIMO := 64.0

## O Y-sort compara a origem de cada peca com o pe de quem passa; numa peca
## inclinada, o y muda ao longo dela. Corta-se a peca para o y variar no
## maximo isto dentro de uma, com a origem no meio: o erro fica em 12 px para
## cada lado, menos que os ~13 que separam do muro o pe de quem encosta nele
## (meio corpo mais meia espessura) - entao quem encosta, na frente ou atras,
## e desenhado do lado certo em qualquer ponto da peca.
const VARIACAO_MAXIMA_DE_Y := 24.0

## Os trechos continuos de uma polilinha (mundo) depois de cortar os vaos. Cada
## vao e { "ponto": Vector2, "largura": float }, centrado no ponto da linha
## mais perto de "ponto".
static func trechos(pontos: PackedVector2Array, vaos: Array) -> Array[PackedVector2Array]:
	var acum := PackedFloat32Array([0.0])
	for i in range(1, pontos.size()):
		acum.append(acum[i - 1] + pontos[i - 1].distance_to(pontos[i]))
	var total := acum[acum.size() - 1]
	var cortes: Array[Vector2] = []
	for vao in vaos:
		var s := _posicao_na_linha(pontos, acum, vao["ponto"])
		var meia := float(vao.get("largura", VAO)) / 2.0
		cortes.append(Vector2(maxf(0.0, s - meia), minf(total, s + meia)))
	cortes.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
	var fora: Array[PackedVector2Array] = []
	var de := 0.0
	for corte in cortes:
		if corte.x > de:
			fora.append(_recorte(pontos, acum, de, corte.x))
		de = maxf(de, corte.y)
	if de < total:
		fora.append(_recorte(pontos, acum, de, total))
	return fora

## O ponto do vao na linha e o segmento em que ele cai: e onde nasce o portao.
static func vao_na_linha(pontos: PackedVector2Array, vao: Dictionary) -> PackedVector2Array:
	var acum := PackedFloat32Array([0.0])
	for i in range(1, pontos.size()):
		acum.append(acum[i - 1] + pontos[i - 1].distance_to(pontos[i]))
	var s := _posicao_na_linha(pontos, acum, vao["ponto"])
	var meia := float(vao.get("largura", VAO)) / 2.0
	return _recorte(pontos, acum, maxf(0.0, s - meia), minf(acum[acum.size() - 1], s + meia))

static func _posicao_na_linha(pontos: PackedVector2Array, acum: PackedFloat32Array, p: Vector2) -> float:
	var melhor := INF
	var s := 0.0
	for i in range(1, pontos.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, pontos[i - 1], pontos[i])
		if q.distance_to(p) < melhor:
			melhor = q.distance_to(p)
			s = acum[i - 1] + pontos[i - 1].distance_to(q)
	return s

static func _no_comprimento(pontos: PackedVector2Array, acum: PackedFloat32Array, s: float) -> Vector2:
	for i in range(1, pontos.size()):
		if s <= acum[i] or i == pontos.size() - 1:
			var trecho := acum[i] - acum[i - 1]
			var t := 0.0 if trecho <= 0.0 else clampf((s - acum[i - 1]) / trecho, 0.0, 1.0)
			return pontos[i - 1].lerp(pontos[i], t)
	return pontos[pontos.size() - 1]

static func _recorte(pontos: PackedVector2Array, acum: PackedFloat32Array, de: float, ate: float) -> PackedVector2Array:
	var linha := PackedVector2Array([_no_comprimento(pontos, acum, de)])
	for i in range(1, pontos.size() - 1):
		if acum[i] > de and acum[i] < ate:
			linha.append(pontos[i])
	linha.append(_no_comprimento(pontos, acum, ate))
	return linha

## A forma de colisao de um segmento: um retangulo girado ao longo dele, mais
## comprido que o segmento por uma espessura - e o que fecha a quina onde dois
## segmentos da mesma linha se encontram.
static func forma(a: Vector2, b: Vector2, espessura: float) -> Dictionary:
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(a.distance_to(b) + espessura, espessura)
	return { "forma": retangulo, "transform": Transform2D((b - a).angle(), (a + b) / 2.0) }

## Um segmento cortado em pecas para o Y-sort (ver VARIACAO_MAXIMA_DE_Y).
static func pecas(a: Vector2, b: Vector2) -> Array[PackedVector2Array]:
	var n := maxi(1, ceili(absf(b.y - a.y) / VARIACAO_MAXIMA_DE_Y))
	var fora: Array[PackedVector2Array] = []
	for i in n:
		fora.append(PackedVector2Array([a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n)]))
	return fora

## A arte de um tipo, quando existe (21/10/2026, o teste do muro de reboco),
## em PASTA_DA_ARTE: `<tipo>-face.png` e um periodo de pilar a pilar, eixo a
## eixo, so a face; `<tipo>-topo.png`, o mesmo periodo, so a faixa do topo; e
## `<tipo>-pilar.png`, o pilar inteiro, com o pe 1 px abaixo do pe da face. A
## largura do periodo e a distancia entre os pilares. Sem arte, cinza.
const PASTA_DA_ARTE := "res://rua/arte/barreiras/"

static func arte_de(tipo: String) -> Dictionary:
	var arte := {}
	for parte in ["face", "topo", "pilar"]:
		var caminho := "%s%s-%s.png" % [PASTA_DA_ARTE, tipo, parte]
		if ResourceLoader.exists(caminho):
			arte[parte] = load(caminho)
	return arte

## Onde vao os pilares de um segmento de comprimento `comprimento`, em
## distancia desde o comeco dele: um a cada `periodo`, o ultimo so se nao
## ficar colado no fim, e o do fim quando o segmento e o ultimo da barreira -
## na quina, quem poe o pilar e o segmento seguinte.
static func pilares_do_segmento(comprimento: float, periodo: float, ultimo: bool) -> PackedFloat32Array:
	var fora := PackedFloat32Array()
	var s := 0.0
	while s <= comprimento - periodo / 4.0:
		fora.append(s)
		s += periodo
	if ultimo:
		fora.append(comprimento)
	return fora

## Uma peca de barreira na vista inclinada (projecao obliqua: subir h no mundo
## e subir h na tela). A pegada no chao e um retangulo da espessura ao longo do
## segmento; aparece o topo - a pegada subida da altura - e toda face que olha
## para o sul, para a camera. Por isso o muro norte-sul nao vira faixa solta no
## ar: e o topo mais a cabeceira. Com arte, a face e o topo repetem o periodo
## ao longo do muro - a diagonal sai coluna por coluna, sem girar pixel - e os
## pilares vao por cima; sem arte, cinza.
## A origem e o meio da peca (ver VARIACAO_MAXIMA_DE_Y).
class Peca extends Node2D:
	var tipo := ""
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	## A cabeceira so aparece na ponta do trecho: entre duas pecas do mesmo
	## muro, a face do corte ficaria riscada no meio dele.
	var cabeceira_em_a := false
	var cabeceira_em_b := false
	## A arte do tipo (Barreira.arte_de), a distancia de `a` desde o comeco do
	## segmento - e o que emenda a textura de uma peca na outra - e os pilares
	## que caem nesta peca.
	var arte := {}
	var s_em_a := 0.0
	var pilares := PackedVector2Array()
	## A altura da face desta barreira, quando o dado traz uma (o muro alto do
	## Antonio); 0 e a do tipo.
	var altura := 0.0

	func montar(tipo_da_peca: String, de: Vector2, ate: Vector2,
			ponta_em_de := false, ponta_em_ate := false, arte_do_tipo := {},
			s_de := 0.0, pilares_no_mundo := PackedVector2Array(), altura_da_barreira := 0.0) -> void:
		tipo = tipo_da_peca
		altura = altura_da_barreira
		position = (de + ate) / 2.0
		a = de - position
		b = ate - position
		cabeceira_em_a = ponta_em_de
		cabeceira_em_b = ponta_em_ate
		arte = arte_do_tipo
		s_em_a = s_de
		for p in pilares_no_mundo:
			pilares.append(p - position)
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		var t: Dictionary = TIPOS[tipo]
		var cor: Color = t["cor"]
		var vazada: bool = t["vazada"]
		var cima := Vector2(0.0, -(altura if altura > 0.0 else float(t["altura"])))
		var espessura := float(t["espessura"])
		var meia := (b - a).orthogonal().normalized() * espessura / 2.0
		var pe := PackedVector2Array([a - meia, b - meia, b + meia, a + meia])
		var centro := (a + b) / 2.0
		var s_em_b := s_em_a + a.distance_to(b)
		# A distancia ao longo do muro de cada ponta de cada lado (os lados 1 e
		# 3, as cabeceiras, seguem a textura pela espessura).
		var s_dos_lados := [[s_em_a, s_em_b], [s_em_b, s_em_b + espessura],
			[s_em_b, s_em_a], [s_em_a, s_em_a + espessura]]
		for i in 4:
			var p := pe[i]
			var q := pe[(i + 1) % 4]
			# Os lados 1 e 3 sao as cabeceiras, em b e em a.
			if (i == 1 and not cabeceira_em_b) or (i == 3 and not cabeceira_em_a):
				continue
			if ((p + q) / 2.0 - centro).y <= 0.0:
				continue
			var face := PackedVector2Array([p, q, q + cima, p + cima])
			if arte.has("face"):
				_com_textura(face, arte["face"], s_dos_lados[i][0], s_dos_lados[i][1], 1.0, 0.0,
					Color(0.72, 0.72, 0.72) if i % 2 == 1 else Color.WHITE)
			else:
				_face(face, cor.darkened(0.5 if i % 2 == 1 else 0.35), vazada)
		var topo := PackedVector2Array([pe[0] + cima, pe[1] + cima, pe[2] + cima, pe[3] + cima])
		if arte.has("topo"):
			# O lado de tras do topo (o do norte) e a linha de cima da textura.
			var v_menos := 0.0 if meia.y >= 0.0 else 1.0
			_com_textura(topo, arte["topo"], s_em_a, s_em_b, v_menos, 1.0 - v_menos, Color.WHITE)
		elif vazada:
			# O topo de grade e alambrado e so o arremate, nao uma laje.
			draw_line(a + cima, b + cima, cor, 2.0)
		else:
			draw_colored_polygon(topo, cor)
			topo.append(topo[0])
			draw_polyline(topo, Color(0.0, 0.0, 0.0, 0.8), 1.0)
		if arte.has("pilar"):
			var pilar: Texture2D = arte["pilar"]
			for p in pilares:
				draw_texture(pilar, p + Vector2(-pilar.get_width() / 2.0,
					espessura / 2.0 + 1.0 - pilar.get_height()))

	## Um quadrilatero com a textura repetida ao longo do muro: `s` (distancia
	## ao longo dele) vira a coluna da textura, e os dois primeiros pontos sao a
	## linha `v_dos_dois_primeiros` dela.
	func _com_textura(pontos: PackedVector2Array, textura: Texture2D, s_ini: float, s_fim: float,
			v_dos_dois_primeiros: float, v_dos_outros: float, tom: Color) -> void:
		var largura := float(textura.get_width())
		var uv := PackedVector2Array([
			Vector2(s_ini / largura, v_dos_dois_primeiros), Vector2(s_fim / largura, v_dos_dois_primeiros),
			Vector2(s_fim / largura, v_dos_outros), Vector2(s_ini / largura, v_dos_outros)])
		draw_polygon(pontos, PackedColorArray([tom, tom, tom, tom]), uv, textura)

	## Uma face: cheia, ou, vazada, transparente e riscada a cada 4 px.
	func _face(face: PackedVector2Array, cor: Color, vazada: bool) -> void:
		if vazada:
			draw_colored_polygon(face, Color(cor, 0.18))
			var n := maxi(1, int(face[0].distance_to(face[1]) / 4.0))
			for i in n + 1:
				var p := face[0].lerp(face[1], float(i) / n)
				draw_line(p, p + face[3] - face[0], cor, 1.0)
		else:
			draw_colored_polygon(face, cor)
		var contorno := face.duplicate()
		contorno.append(face[0])
		draw_polyline(contorno, Color(0.0, 0.0, 0.0, 0.8), 1.0)

## Uma barricada solta (onibus, carro, cacamba, entulho), girada. O carro usa o
## sprite dos carros da rua, escurecido no queimado.
class Barricada extends Node2D:
	var tipo := ""
	var giro := 0.0
	var _desenho: Texture2D

	func montar(tipo_do_objeto: String, onde: Vector2, giro_em_graus: float) -> void:
		tipo = tipo_do_objeto
		position = onde
		giro = deg_to_rad(giro_em_graus)
		var caminho: String = OBJETOS[tipo].get("desenho", "")
		if caminho != "" and ResourceLoader.exists(caminho):
			_desenho = load(caminho)

	func _draw() -> void:
		var o: Dictionary = OBJETOS[tipo]
		var tam: Vector2 = o["tamanho"]
		if _desenho != null:
			# O sprite e em pe (comprido em y): gira um quarto de volta a menos.
			draw_set_transform(Vector2.ZERO, giro - PI / 2.0)
			var em_pe := Vector2(tam.y, tam.x)
			draw_texture_rect(_desenho, Rect2(-em_pe / 2.0, em_pe), false, o.get("tinta", Color.WHITE))
			if o.get("chassi", false):
				# Tombado de lado: o chassi escuro aparece num dos lados compridos.
				draw_rect(Rect2(em_pe.x / 2.0 - 14.0, -em_pe.y / 2.0 + 10.0, 10.0, em_pe.y - 20.0),
					Color(0.12, 0.11, 0.1, 0.85))
			draw_set_transform(Vector2.ZERO)
			return
		# Cinza, como as pecas de muro: a pegada girada no chao, o topo subido
		# da altura e as faces que olham para a camera.
		var cima := Vector2(0.0, -float(o["altura"]))
		var meio := tam / 2.0
		var pe := PackedVector2Array()
		for c in [Vector2(-meio.x, -meio.y), Vector2(meio.x, -meio.y), meio, Vector2(-meio.x, meio.y)]:
			pe.append((c as Vector2).rotated(giro))
		var cor: Color = o["cor"]
		var contorno := Color(0.0, 0.0, 0.0, 0.8)
		for i in 4:
			var p := pe[i]
			var q := pe[(i + 1) % 4]
			if ((p + q) / 2.0).y <= 0.0:
				continue
			var face := PackedVector2Array([p, q, q + cima, p + cima])
			draw_colored_polygon(face, cor.darkened(0.35 if i % 2 == 0 else 0.5))
			face.append(p)
			draw_polyline(face, contorno, 1.0)
		var topo := PackedVector2Array()
		for p in pe:
			topo.append(p + cima)
		draw_colored_polygon(topo, cor)
		topo.append(topo[0])
		draw_polyline(topo, contorno, 1.0)
