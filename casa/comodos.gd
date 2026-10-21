extends RefCounted
## Os comodos da casa e o que se clica em cada um. **Dado, nao cena** - o mesmo
## principio do mapa da rua: mudar a casa e mexer aqui, e o desenho e o clique
## leem do mesmo lugar, entao nao ha como o objeto aparecer num canto e o clique
## responder em outro.
##
## Coordenadas na grade de TELA (320 x 180), por cima das fotos da equipe
## (casa/arte/<comodo>.png, 1280 x 720 - 4 px por unidade). Molde de *No, I'm
## Not a Human*: comodos fixos, e o que importa sao os objetos que acendem
## quando o mouse passa.
##
## **A planta (16/10/2026).** Decidido pelo Joao, a partir das fotos: entrada,
## sala, corredor, cozinha e quarto, **sem porao**; o corredor e o centro;
## **ela fica presa no quarto**, acorrentada a cabeceira; **ele dorme no sofa
## da sala**; a sala tem as duas vistas da equipe (a da TV e a do sofa) e se
## vira entre elas. Os retangulos foram medidos em pixel em cima das fotos,
## no gabarito de 16/10.
##
## **Por onde se vai de um comodo ao outro foi decidido por mim**, a pedido do
## Joao ("coerente com o desenho de uma casa, no futuro eu vejo se gosto"), e
## e leitura das fotos: a porta escura da direita na vista da TV e a mesma
## porta da rua da entrada, e a parede listrada ao lado da TV e a mesma da
## entrada - entao, de costas para a porta, ve-se o sofa. Da porta: virar ->
## sofa -> virar -> TV; a porta da rua, na vista da TV, volta a entrada, e a
## passagem da esquerda leva ao corredor; no corredor, o fundo (a sala de
## jantar) leva a cozinha e a porta de madeira da esquerda ao quarto; o batente
## da direita e so cenario.
##
## Ordem dentro de `pontos` importa: o primeiro que contem o mouse ganha,
## entao o que e pequeno e fica em cima de outro vem antes.
##
## **O contorno (21/10/2026).** Joao: "faz essas selecoes de interacao ficarem
## no contorno correto do objeto". Cada ponto que e um objeto da foto tem
## `contorno`: o poligono da silhueta dele, tracado em cima da foto (grade de
## 320 x 180), e e nele que o clique pega e o destaque acende. O `rect` fica
## sendo a caixa do contorno (e o vao de voltar, que e faixa e nao objeto). O
## que o codigo desenha por cima da foto tem o contorno do proprio desenho: o
## olho magico, o radio e ela - o dela muda com o estagio, e o desenho.gd o
## poe em `contornos_vivos`. O objeto em mais de um pedaco (as duas molduras
## do porta-retratos) tem `partes`, uma lista de contornos: a estante entre
## eles nao acende.

const TELA := Vector2(320, 180)

## A faixa de baixo da tela: virar, ou voltar para o comodo de onde se veio.
const VOLTAR := Rect2(120, 164, 80, 16)

# ---------------------------------------------- o que se desenha por cima

## O olho magico: a foto da porta nao tem, entao e desenhado no meio da folha,
## na altura do olho (a porta vai de ~-22 a ~190 nesta tela: ~1 unidade por cm).
const OLHO_MAGICO := Vector2(164, 35)
## A tela da TV da sala, medida na foto (onde a estatica aparece): o
## quadrilatero do escuro dela, de cima a esquerda no sentido do relogio -
## remedido em 21/10/2026 junto com os contornos (o retangulo antigo, de 100,74
## a 184,134, cortava a TV: ela desce ate 128 na esquerda e 140 na direita).
const TELA_DA_TV := [Vector2(98.6, 75.8), Vector2(183.1, 74), Vector2(184.4, 139.9), Vector2(100.4, 127.3)]
## O radio, desenhado em cima do rack, a esquerda da TV - a foto nao tem radio.
const RADIO := Rect2(64, 129, 24, 11)
## Onde os papeis da pesquisa ficam: a frente da bancada da cozinha, onde o
## granito esta livre (as coisas da foto ficam atras, acima de y 140). Um papel
## por documento.
const BANCADA := Rect2(128, 140, 120, 22)
## O tamanho do pixel das fotos na tela: 207 colunas de bloco em 320 unidades.
## O que o codigo desenha em pixel (ela) usa este bloco, para casar com a foto.
const BLOCO_DA_FOTO := 320.0 / 207.0
## Ela, no quarto: o meio da base do desenho dela (ajoelhada na cama). O
## desenho tem 36 x 52 blocos (desenho.gd), e o clique (`ponto "ela"`) e o
## retangulo dele.
const PES_DELA := Vector2(150, 128)
## Onde as correntes da foto (geradas no PixelLab) chegam na cama:
## o desenho liga as maos dela a estas duas pontas.
const PONTAS_DAS_CORRENTES := [Vector2(131, 113), Vector2(170, 113)]

const COMODOS := {
	"entrada": {
		"nome": "entrada",
		"pontos": [
			{ "id": "olho_magico", "nome": "olho mágico", "rect": Rect2(159.5, 30.5, 9, 9),
				"contorno": [Vector2(168.5, 35), Vector2(168.16, 36.72), Vector2(167.18, 38.18), Vector2(165.72, 39.16), Vector2(164, 39.5), Vector2(162.28, 39.16), Vector2(160.82, 38.18), Vector2(159.84, 36.72), Vector2(159.5, 35), Vector2(159.84, 33.28), Vector2(160.82, 31.82), Vector2(162.28, 30.84), Vector2(164, 30.5), Vector2(165.72, 30.84), Vector2(167.18, 31.82), Vector2(168.16, 33.28)] },
			{ "id": "porta_da_rua", "nome": "porta da rua", "rect": Rect2(119.7, 0, 95.3, 180),
				"contorno": [Vector2(119.7, 0), Vector2(215, 0), Vector2(215, 180), Vector2(201, 180), Vector2(201, 162), Vector2(122.6, 162), Vector2(121.2, 82)] },
			{ "id": "ir_sala", "nome": "virar para a sala", "rect": VOLTAR, "vai": "sala_sofa" },
		],
	},
	"sala_sofa": {
		"nome": "sala",
		"pontos": [
			{ "id": "sofa", "nome": "sofá", "rect": Rect2(168.5, 81, 151.5, 99),
				"contorno": [Vector2(168.5, 91.5), Vector2(175, 91.5), Vector2(176, 90), Vector2(182.5, 90), Vector2(183, 88.5), Vector2(188.75, 88.5), Vector2(189, 81), Vector2(226, 81), Vector2(231, 83), Vector2(239, 84.5), Vector2(245, 86), Vector2(250, 87.75), Vector2(262, 89.5), Vector2(270, 91.25), Vector2(285, 93), Vector2(298, 94.25), Vector2(320, 96), Vector2(320, 168), Vector2(281.5, 168.5), Vector2(281, 180), Vector2(266.5, 180), Vector2(265.5, 176), Vector2(263.5, 172.5), Vector2(258, 169.6), Vector2(252, 166.1), Vector2(240, 159.7), Vector2(222, 149.3), Vector2(204, 139.1), Vector2(192, 131.5), Vector2(186, 128), Vector2(182, 126.5), Vector2(180.5, 123.75), Vector2(177, 122.25), Vector2(175, 120.75), Vector2(173, 119), Vector2(173, 112.5), Vector2(168.5, 111.5)] },
			{ "id": "virar", "nome": "virar para a televisão", "rect": VOLTAR, "vai": "sala_tv" },
		],
	},
	"sala_tv": {
		"nome": "sala",
		"pontos": [
			{ "id": "foto", "nome": "porta-retratos", "rect": Rect2(63.4, 38.8, 32.6, 72.7),
				"partes": [[Vector2(63.4, 41), Vector2(70.5, 40.6), Vector2(72.6, 39.2), Vector2(94.4, 38.8), Vector2(94.4, 68.8), Vector2(63.4, 68.8)], [Vector2(63.4, 82.3), Vector2(94.6, 82.3), Vector2(94.6, 89.5), Vector2(96, 89.5), Vector2(96, 110.2), Vector2(92.6, 110.2), Vector2(92.6, 111.5), Vector2(77, 111.5), Vector2(72, 110.5), Vector2(65, 110), Vector2(65, 94.6), Vector2(63.4, 94.6)]] },
			{ "id": "radio", "nome": "rádio", "rect": Rect2(63, 112, 34, 29),
				"contorno": [Vector2(63, 128), Vector2(84, 128), Vector2(93.5, 112), Vector2(97, 113.5), Vector2(89, 128.5), Vector2(89, 141), Vector2(63, 141)] },
			{ "id": "tv", "nome": "televisão", "rect": Rect2(97.5, 73, 87.9, 68),
				"contorno": [Vector2(97.5, 74.8), Vector2(111.7, 74.8), Vector2(112.1, 73), Vector2(184, 73), Vector2(184, 112.8), Vector2(185.4, 113.2), Vector2(185.4, 141), Vector2(182, 141), Vector2(174, 139.5), Vector2(163.5, 137.75), Vector2(152.5, 136.25), Vector2(142.5, 134.75), Vector2(132.5, 133.25), Vector2(121.5, 131.75), Vector2(110.5, 130), Vector2(101.75, 128.5), Vector2(99.25, 128.5), Vector2(99.25, 93.7), Vector2(97.5, 93.3)] },
			{ "id": "ir_entrada", "nome": "porta da rua", "rect": Rect2(248, 33, 72, 147),
				"contorno": [Vector2(248, 40.2), Vector2(266, 38.6), Vector2(283, 37.2), Vector2(300, 35.6), Vector2(316.5, 34.8), Vector2(317, 33), Vector2(320, 33), Vector2(320, 180), Vector2(254.5, 180), Vector2(248, 171)], "vai": "entrada" },
			{ "id": "ir_corredor", "nome": "corredor", "rect": Rect2(0, 48, 10, 93.5),
				"contorno": [Vector2(0, 48), Vector2(6, 48), Vector2(6.5, 51.8), Vector2(8, 51.8), Vector2(8, 108.6), Vector2(10, 109.2), Vector2(10, 131.5), Vector2(9, 136), Vector2(8, 141.5), Vector2(0, 141.5)], "vai": "corredor" },
			{ "id": "virar", "nome": "virar para o sofá", "rect": VOLTAR, "vai": "sala_sofa" },
		],
	},
	"corredor": {
		"nome": "corredor",
		"pontos": [
			{ "id": "ir_cozinha", "nome": "cozinha", "rect": Rect2(88.3, 0, 139.7, 180),
				"contorno": [Vector2(88.3, 0), Vector2(228, 0), Vector2(228, 56), Vector2(226.5, 61), Vector2(226.5, 124), Vector2(225, 126), Vector2(224.7, 180), Vector2(201, 180), Vector2(201, 162), Vector2(119, 162), Vector2(119, 180), Vector2(97, 180), Vector2(97, 166), Vector2(95.8, 162), Vector2(95.5, 135), Vector2(94, 129), Vector2(94, 103.5), Vector2(93, 99.5), Vector2(92, 96.5), Vector2(92, 66), Vector2(90.5, 61), Vector2(90.2, 33), Vector2(88.5, 29)], "vai": "cozinha" },
			{ "id": "ir_quarto", "nome": "quarto", "rect": Rect2(0, 0, 76, 180),
				"contorno": [Vector2(0, 0), Vector2(69, 0), Vector2(69, 29), Vector2(70.7, 31), Vector2(70.7, 57), Vector2(72.4, 61), Vector2(72.4, 135), Vector2(74.3, 141), Vector2(74.4, 162), Vector2(76, 167), Vector2(76, 180), Vector2(0, 180)], "vai": "quarto" },
			{ "id": "ir_sala", "nome": "voltar para a sala", "rect": VOLTAR, "vai": "sala_tv" },
		],
	},
	"cozinha": {
		"nome": "cozinha",
		"pontos": [
			{ "id": "geladeira", "nome": "geladeira", "rect": Rect2(68.3, 31, 50.2, 133),
				"contorno": [Vector2(68.3, 31), Vector2(118.5, 32), Vector2(118.5, 98), Vector2(115.6, 97.5), Vector2(115.3, 94.8), Vector2(115, 89.5), Vector2(111.5, 89.3), Vector2(111, 85.5), Vector2(108.7, 85.5), Vector2(108, 86.3), Vector2(105.5, 87.5), Vector2(105.5, 94), Vector2(102.5, 94.8), Vector2(100.5, 96.5), Vector2(99.5, 100.5), Vector2(84, 103.7), Vector2(84.8, 164), Vector2(73.3, 164), Vector2(72.4, 130), Vector2(71, 100), Vector2(69.6, 60)] },
			{ "id": "pesquisa", "nome": "a pesquisa", "rect": Rect2(84, 85.5, 236, 94.5),
				"contorno": [Vector2(84, 103.7), Vector2(99.5, 100.5), Vector2(100.5, 96.5), Vector2(102.5, 94.8), Vector2(105.5, 94), Vector2(105.5, 87.5), Vector2(108, 86.3), Vector2(108.7, 85.5), Vector2(111, 85.5), Vector2(111.5, 89.3), Vector2(115, 89.5), Vector2(115.3, 94.8), Vector2(115.6, 97.5), Vector2(118.5, 98), Vector2(121, 98), Vector2(123.5, 97), Vector2(131, 97), Vector2(132.2, 98.3), Vector2(132.2, 101), Vector2(210, 101), Vector2(320, 102), Vector2(320, 180), Vector2(200.5, 180), Vector2(200.5, 162), Vector2(120, 162), Vector2(120, 180), Vector2(85.2, 180), Vector2(84.8, 164)] },
			{ "id": "ir_corredor", "nome": "voltar para o corredor", "rect": VOLTAR, "vai": "corredor" },
		],
	},
	"quarto": {
		"nome": "quarto",
		"pontos": [
			# = o desenho dela: 36 x 52 blocos com a base no meio em PES_DELA.
			{ "id": "ela", "nome": "ela", "rect": Rect2(122, 48, 56, 80) },
			{ "id": "ir_corredor", "nome": "voltar para o corredor", "rect": VOLTAR, "vai": "corredor" },
		],
	},
}

## Os contornos que o desenho calcula na hora (o dela, que muda com o
## estagio): id -> lista de poligonos.
static var contornos_vivos := {}

## O ponto da tela sob `pos`, ou vazio.
static func ponto_em(comodo: String, pos: Vector2) -> Dictionary:
	for ponto in COMODOS[comodo]["pontos"]:
		if contem(ponto, pos):
			return ponto
	return {}

## Se `pos` cai no ponto: dentro do contorno, quando ele tem; senao, no
## retangulo.
static func contem(ponto: Dictionary, pos: Vector2) -> bool:
	var partes := contorno_de(ponto)
	if partes.is_empty():
		return (ponto["rect"] as Rect2).has_point(pos)
	for parte in partes:
		if Geometry2D.is_point_in_polygon(pos, parte):
			return true
	return false

## O contorno do ponto como lista de poligonos (o vivo, do desenho, antes do
## escrito aqui), ou vazio se ele so tem retangulo.
static func contorno_de(ponto: Dictionary) -> Array:
	if contornos_vivos.has(ponto["id"]):
		return contornos_vivos[ponto["id"]]
	if ponto.has("contorno"):
		return [PackedVector2Array(ponto["contorno"])]
	if ponto.has("partes"):
		var partes: Array = []
		for parte in ponto["partes"]:
			partes.append(PackedVector2Array(parte))
		return partes
	return []
