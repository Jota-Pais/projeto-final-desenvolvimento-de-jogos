extends RefCounted
## Os comodos da casa e o que se clica em cada um. **Dado, nao cena** - o mesmo
## principio do mapa da rua: mudar a casa e mexer aqui, e o desenho e o clique
## leem do mesmo lugar, entao nao ha como o objeto aparecer num canto e o clique
## responder em outro.
##
## Coordenadas na grade de TELA (320 x 180). A casa roda em baixa resolucao de
## proposito - e o molde de *No, I'm Not a Human*: tela granulada, pouca
## definicao, e o que importa sao os objetos que acendem quando o mouse passa.
##
## **A planta da casa e proposta, nao decisao.** Cinco comodos porque sao os
## cinco que a premissa pede (entrar, descansar, guardar o que veio, pesquisar,
## e o porao dela) - nenhum a mais.
##
## **Decidido pelo Joao em 16/10/2026, a partir da arte da equipe** (fotos
## pixeladas em design/arte-rua.md, "A casa"): a planta nova tem entrada,
## sala, corredor, cozinha e quarto - **sem porao**. O corredor e o centro,
## com portas para cozinha e quarto. **O quarto e onde ela esta presa** (o
## papel que o porao tinha) e **o jogador dorme no sofa da sala**. A casa
## inteira pesada como *No, I'm Not a Human*; o quarto, alem de pesado,
## macabro e sujo - um zumbi mora nele. Ainda nao implementado aqui: entra
## com a arte, na proxima sessao.
##
## Ordem dentro de `pontos` importa: o primeiro retangulo que contem o mouse
## ganha, entao o que e pequeno e fica em cima de outro (o olho magico em cima
## da porta) vem antes.

const TELA := Vector2(320, 180)

## A parede do fundo. Tudo na casa e uma caixa em perspectiva de um ponto so:
## o fundo e este retangulo, e teto, chao e paredes laterais ligam os cantos
## dele aos cantos da tela.
const FUNDO := Rect2(80, 36, 160, 96)
const PONTO_DE_FUGA := Vector2(160, 84)

## A faixa de baixo da tela, que volta para o comodo anterior.
const VOLTAR := Rect2(120, 164, 80, 16)

## O vao na parede da esquerda. Mesmo lugar em todo comodo que tem um.
const PORTA_DA_ESQUERDA := Rect2(16, 52, 46, 118)

const COMODOS := {
	"entrada": {
		"nome": "entrada",
		"pontos": [
			{ "id": "olho_magico", "nome": "olho mágico", "rect": Rect2(154, 69, 12, 12) },
			{ "id": "porta_da_rua", "nome": "porta da rua", "rect": Rect2(136, 52, 48, 80) },
			{ "id": "ir_sala", "nome": "sala", "rect": PORTA_DA_ESQUERDA, "vai": "sala" },
		],
	},
	"sala": {
		"nome": "sala",
		"pontos": [
			{ "id": "radio", "nome": "rádio", "rect": Rect2(148, 100, 26, 12) },
			{ "id": "tv", "nome": "televisão", "rect": Rect2(240, 90, 60, 52) },
			{ "id": "ir_cozinha", "nome": "cozinha", "rect": Rect2(92, 58, 30, 74), "vai": "cozinha" },
			{ "id": "ir_quarto", "nome": "quarto", "rect": Rect2(198, 58, 30, 74), "vai": "quarto" },
			{ "id": "ir_porao", "nome": "porta do porão", "rect": PORTA_DA_ESQUERDA, "vai": "porao" },
			{ "id": "ir_entrada", "nome": "voltar para a entrada", "rect": VOLTAR, "vai": "entrada" },
		],
	},
	"cozinha": {
		"nome": "cozinha",
		"pontos": [
			{ "id": "pesquisa", "nome": "a pesquisa", "rect": Rect2(130, 50, 40, 34) },
			{ "id": "pesquisa", "nome": "a pesquisa", "rect": Rect2(104, 134, 112, 28) },
			{ "id": "geladeira", "nome": "geladeira", "rect": Rect2(86, 46, 36, 86) },
			{ "id": "ir_sala", "nome": "voltar para a sala", "rect": VOLTAR, "vai": "sala" },
		],
	},
	"quarto": {
		"nome": "quarto",
		"pontos": [
			{ "id": "foto", "nome": "foto", "rect": Rect2(196, 58, 20, 26) },
			{ "id": "cama", "nome": "cama", "rect": Rect2(60, 104, 164, 58) },
			{ "id": "ir_sala", "nome": "voltar para a sala", "rect": VOLTAR, "vai": "sala" },
		],
	},
	"porao": {
		"nome": "porão",
		"pontos": [
			{ "id": "ela", "nome": "ela", "rect": Rect2(128, 29, 65, 105) },
			{ "id": "ir_sala", "nome": "subir para a sala", "rect": VOLTAR, "vai": "sala" },
		],
	},
}

## O ponto da tela sob `pos`, ou vazio.
static func ponto_em(comodo: String, pos: Vector2) -> Dictionary:
	for ponto in COMODOS[comodo]["pontos"]:
		if (ponto["rect"] as Rect2).has_point(pos):
			return ponto
	return {}
