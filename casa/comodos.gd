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
## Ordem dentro de `pontos` importa: o primeiro retangulo que contem o mouse
## ganha, entao o que e pequeno e fica em cima de outro vem antes.

const TELA := Vector2(320, 180)

## A faixa de baixo da tela: virar, ou voltar para o comodo de onde se veio.
const VOLTAR := Rect2(120, 164, 80, 16)

# ---------------------------------------------- o que se desenha por cima

## O olho magico: a foto da porta nao tem, entao e desenhado no meio da folha,
## na altura do olho (a porta vai de ~-22 a ~190 nesta tela: ~1 unidade por cm).
const OLHO_MAGICO := Vector2(164, 35)
## A tela da TV da sala, medida na foto (onde a estatica aparece).
const TELA_DA_TV := Rect2(100, 74, 84, 60)
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
			{ "id": "olho_magico", "nome": "olho mágico", "rect": Rect2(158, 29, 12, 12) },
			{ "id": "porta_da_rua", "nome": "porta da rua", "rect": Rect2(114, 2, 100, 158) },
			{ "id": "ir_sala", "nome": "virar para a sala", "rect": VOLTAR, "vai": "sala_sofa" },
		],
	},
	"sala_sofa": {
		"nome": "sala",
		"pontos": [
			{ "id": "sofa", "nome": "sofá", "rect": Rect2(180, 88, 140, 74) },
			{ "id": "virar", "nome": "virar para a televisão", "rect": VOLTAR, "vai": "sala_tv" },
		],
	},
	"sala_tv": {
		"nome": "sala",
		"pontos": [
			{ "id": "foto", "nome": "porta-retratos", "rect": Rect2(60, 36, 38, 76) },
			{ "id": "radio", "nome": "rádio", "rect": Rect2(60, 112, 32, 30) },
			{ "id": "tv", "nome": "televisão", "rect": Rect2(98, 72, 88, 68) },
			{ "id": "ir_entrada", "nome": "porta da rua", "rect": Rect2(248, 40, 72, 122), "vai": "entrada" },
			{ "id": "ir_corredor", "nome": "corredor", "rect": Rect2(0, 24, 48, 138), "vai": "corredor" },
			{ "id": "virar", "nome": "virar para o sofá", "rect": VOLTAR, "vai": "sala_sofa" },
		],
	},
	"corredor": {
		"nome": "corredor",
		"pontos": [
			{ "id": "ir_cozinha", "nome": "cozinha", "rect": Rect2(88, 16, 98, 146), "vai": "cozinha" },
			{ "id": "ir_quarto", "nome": "quarto", "rect": Rect2(4, 0, 74, 162), "vai": "quarto" },
			{ "id": "ir_sala", "nome": "voltar para a sala", "rect": VOLTAR, "vai": "sala_tv" },
		],
	},
	"cozinha": {
		"nome": "cozinha",
		"pontos": [
			{ "id": "geladeira", "nome": "geladeira", "rect": Rect2(68, 28, 50, 80) },
			{ "id": "pesquisa", "nome": "a pesquisa", "rect": Rect2(120, 98, 180, 64) },
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

## O ponto da tela sob `pos`, ou vazio.
static func ponto_em(comodo: String, pos: Vector2) -> Dictionary:
	for ponto in COMODOS[comodo]["pontos"]:
		if (ponto["rect"] as Rect2).has_point(pos):
			return ponto
	return {}
