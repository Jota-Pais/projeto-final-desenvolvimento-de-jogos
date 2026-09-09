## Os lugares do mapa, e como cada um se monta.
##
## O `rua/mapa.gd` diz **onde** cada lugar fica; este arquivo diz **do que ele e
## feito**. Cada gerador recebe o retangulo do lugar e devolve as mesmas pecas
## que o cenario ja sabia consumir - construcoes, cercas, bosques, moveis de
## rua, zumbis e chao - so que agora sao varias fontes em vez de uma lista fixa.
##
## E o que o Project Zomboid faz: o mapa nao e "casas iguais em fileira", e um
## punhado de lugares com regra propria - fita comercial, posto na rodovia,
## predio publico com estacionamento, condominio murado - costurados pela
## estrada. Cada tipo de predio tem a sua tabela de loot, e e isso que faz
## valer a pena ir longe.
##
## Escala: 40 px = 1 metro (o jogador tem 40 px de altura). O bairro inteiro que
## existia antes de 09/09/2026 cabe num canto deste mapa.

const Construcao := preload("res://rua/construcao.gd")

# ---------------------------------------------------------------- o bairro
#
# Layout tunado a mao entre 07 e 08/09/2026, com o conferir_bairro achando
# 38 moveis inalcancaveis na primeira rodada. **Nao foi reescrito para o mapa
# grande**: e o mesmo bairro, deslocado inteiro para o lugar dele. Numero
# tunado que se reescreve e numero que se re-erra.
#
# Sao coordenadas LOCAIS - o mapa soma a origem do lugar.

const BAIRRO_TAMANHO := Vector2(5760.0, 3600.0)

## A rua principal do bairro local. O mapa alinha ela com a rodovia: e o mesmo
## asfalto, como Muldraugh esticada ao longo da US-31W.
const BAIRRO_RUA_PRINCIPAL := Rect2(0.0, 1620.0, 5760.0, 400.0)
const BAIRRO_RUA_TRANSVERSAL := Rect2(2700.0, 0.0, 400.0, 3600.0)

const BAIRRO_CONSTRUCOES := [
	{ "rect": Rect2(240.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa", "sua": true },
	{ "rect": Rect2(1000.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(1760.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa", "documento": true },
	{ "rect": Rect2(3340.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(4100.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(4860.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(240.0, 2300.0, 940.0, 540.0), "porta": "norte", "tipo": "comercio", "documento": true },
	{ "rect": Rect2(1300.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	{ "rect": Rect2(3340.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	{ "rect": Rect2(4360.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	{ "rect": Rect2(420.0, 480.0, 280.0, 240.0), "porta": "sul", "tipo": "galpao" },
	{ "rect": Rect2(4200.0, 480.0, 280.0, 240.0), "porta": "sul", "tipo": "galpao" },
	{ "rect": Rect2(1400.0, 2960.0, 280.0, 240.0), "porta": "norte", "tipo": "galpao" },
]

const BAIRRO_CERCAS := [
	Rect2(200.0, 370.0, 720.0, 18.0),
	Rect2(1010.0, 370.0, 670.0, 18.0),
	Rect2(1790.0, 370.0, 620.0, 18.0),
	Rect2(3350.0, 370.0, 610.0, 18.0),
	Rect2(4130.0, 370.0, 590.0, 18.0),
	Rect2(4890.0, 370.0, 590.0, 18.0),
	Rect2(200.0, 3270.0, 970.0, 18.0),
	Rect2(1290.0, 3270.0, 680.0, 18.0),
	Rect2(3350.0, 3270.0, 620.0, 18.0),
	Rect2(4350.0, 3270.0, 680.0, 18.0),
	Rect2(958.0, 388.0, 14.0, 220.0),
	Rect2(1718.0, 388.0, 14.0, 220.0),
	Rect2(4048.0, 388.0, 14.0, 220.0),
	Rect2(1240.0, 3050.0, 14.0, 220.0),
]

const BAIRRO_MOVEIS_DE_RUA := [
	{ "tipo": "carro", "pos": Vector2(1200.0, 1720.0) },
	{ "tipo": "carro", "pos": Vector2(3600.0, 1920.0) },
	{ "tipo": "carro", "pos": Vector2(2900.0, 3100.0) },
	{ "tipo": "carro", "pos": Vector2(620.0, 1900.0) },
	{ "tipo": "lata", "pos": Vector2(1560.0, 1560.0) },
	{ "tipo": "lata", "pos": Vector2(3900.0, 1560.0) },
	{ "tipo": "lata", "pos": Vector2(2300.0, 2080.0) },
	{ "tipo": "lata", "pos": Vector2(4600.0, 2080.0) },
]

const BAIRRO_ZUMBIS := [
	Vector2(900.0, 1820.0),
	Vector2(1700.0, 1780.0),
	Vector2(2350.0, 1900.0),
	Vector2(3300.0, 1820.0),
	Vector2(4200.0, 1880.0),
	Vector2(5100.0, 1800.0),
	Vector2(2900.0, 700.0),
	Vector2(2900.0, 2600.0),
	Vector2(1300.0, 620.0),
	Vector2(4600.0, 640.0),
	Vector2(600.0, 3000.0),
	Vector2(2085.0, 1222.0),
	Vector2(710.0, 2450.0),
]

## Bosque nas bordas do lote, longe de beco, porta e vao de cerca: arvore e
## solida, e arvore solida em area de circulacao fecha caminho sem avisar.
const BAIRRO_BOSQUES := [
	Rect2(0.0, 0.0, 5760.0, 300.0),
	Rect2(0.0, 3350.0, 5760.0, 250.0),
]

# ------------------------------------------------------------------ montagem

## Devolve as pecas de um lugar, ja em coordenada de mundo.
##
## O formato e sempre o mesmo, e e o que o cenario consome: quem acrescentar um
## tipo de lugar novo so precisa devolver este dicionario.
static func montar(lugar: Dictionary) -> Dictionary:
	var pecas := {
		"construcoes": [],
		"cercas": [],
		"bosques": [],
		"moveis_de_rua": [],
		"zumbis": [],
		"ruas": [],
		"piso": [],
	}
	match lugar["tipo"]:
		"bairro": _bairro(lugar, pecas)
		"posto": _posto(lugar, pecas)
		"delegacia": _delegacia(lugar, pecas)
		"mercado": _mercado(lugar, pecas)
		"mansao": _mansao(lugar, pecas)
		"floresta": _floresta(lugar, pecas)
	return pecas

static func _somar(construcao: Dictionary, origem: Vector2) -> Dictionary:
	var copia := construcao.duplicate()
	copia["rect"] = (construcao["rect"] as Rect2).grow(0.0)
	copia["rect"] = Rect2((construcao["rect"] as Rect2).position + origem,
		(construcao["rect"] as Rect2).size)
	return copia

# --- o bairro residencial ---------------------------------------------------

## O bairro de antes de 09/09, inteiro, deslocado para a origem do lugar.
static func _bairro(lugar: Dictionary, pecas: Dictionary) -> void:
	var origem: Vector2 = (lugar["rect"] as Rect2).position

	for construcao in BAIRRO_CONSTRUCOES:
		pecas["construcoes"].append(_somar(construcao, origem))
	for cerca in BAIRRO_CERCAS:
		pecas["cercas"].append(Rect2((cerca as Rect2).position + origem, (cerca as Rect2).size))
	for bosque in BAIRRO_BOSQUES:
		pecas["bosques"].append({ "rect": Rect2((bosque as Rect2).position + origem, (bosque as Rect2).size), "densidade": 0.35 })
	for movel in BAIRRO_MOVEIS_DE_RUA:
		pecas["moveis_de_rua"].append({ "tipo": movel["tipo"], "pos": movel["pos"] + origem })
	for onde in BAIRRO_ZUMBIS:
		pecas["zumbis"].append(onde + origem)

	# A rua principal do bairro E a rodovia; so a transversal e rua de bairro.
	pecas["ruas"].append(Rect2(BAIRRO_RUA_TRANSVERSAL.position + origem,
		BAIRRO_RUA_TRANSVERSAL.size))

# --- o posto de gasolina ----------------------------------------------------

## Posto na beira da rodovia: pista de concreto encostada no asfalto, quatro
## bombas em fila e a loja de conveniencia no fundo.
##
## A pista aberta e o oposto de uma casa - nao tem onde se esconder, e voce ve
## o zumbi vindo de longe. E o unico lugar do mapa com bomba de combustivel, o
## que vai importar quando o carro existir.
static func _posto(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]

	# A pista toda de concreto, encostada na rodovia (que fica em cima).
	pecas["piso"].append(r)

	# A loja no fundo, virada para a rodovia.
	var loja := Rect2(r.position.x + r.size.x * 0.5, r.end.y - 640.0, 900.0, 560.0)
	pecas["construcoes"].append({
		"rect": loja, "porta": "norte", "tipo": "posto", "documento": true,
	})

	# Quatro bombas em duas ilhas, entre a rodovia e a loja.
	var y := r.position.y + 380.0
	for i in 4:
		var x := r.position.x + 420.0 + float(i) * 520.0
		pecas["moveis_de_rua"].append({ "tipo": "bomba", "pos": Vector2(x, y) })

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(r.position.x + 340.0, r.end.y - 320.0),
	})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(loja.position.x - 140.0, loja.position.y - 120.0),
	})

	pecas["zumbis"].append(Vector2(r.position.x + 700.0, r.position.y + 700.0))
	# Na pista, na frente da loja - e nao no r.end.y - 260, que caia em cima da
	# parede oeste dela. O conferir_zumbi pegou.
	pecas["zumbis"].append(Vector2(loja.get_center().x, loja.position.y - 260.0))
	pecas["zumbis"].append(loja.get_center() + Vector2(0.0, 120.0))

# --- a delegacia ------------------------------------------------------------

## Predio publico afastado da rodovia, com estacionamento na frente e uma via
## de acesso ligando os dois.
##
## E o lugar mais caro de vasculhar do mapa: tres quartos, e o do fundo e a
## armaria - o movel de maior duracao que existe. Tambem e o mais povoado, que
## e como o PZ paga o melhor loot: com mais zumbi, e nao com porta trancada.
static func _delegacia(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]

	var predio := Rect2(r.position.x + 900.0, r.position.y, 3600.0, 2600.0)
	pecas["construcoes"].append({
		"rect": predio, "porta": "sul", "tipo": "delegacia", "documento": true, "arma": true,
	})

	# Estacionamento entre o predio e a rodovia.
	var patio := Rect2(r.position.x, predio.end.y, r.size.x, r.end.y - predio.end.y)
	pecas["piso"].append(patio)

	# Muro dos fundos e das laterais, com o patio aberto para a via de acesso:
	# predio publico e cercado, mas nao e prisao.
	pecas["cercas"].append(Rect2(r.position.x, r.position.y - 20.0, r.size.x, 20.0))
	pecas["cercas"].append(Rect2(r.position.x - 20.0, r.position.y, 20.0, r.size.y * 0.72))
	pecas["cercas"].append(Rect2(r.end.x, r.position.y, 20.0, r.size.y * 0.72))

	for i in 3:
		pecas["moveis_de_rua"].append({
			"tipo": "carro",
			"pos": Vector2(patio.position.x + 460.0 + float(i) * 620.0, patio.get_center().y),
		})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(predio.position.x - 160.0, predio.end.y - 200.0),
	})

	pecas["zumbis"].append(patio.get_center() + Vector2(-800.0, 200.0))
	pecas["zumbis"].append(patio.get_center() + Vector2(900.0, -140.0))
	pecas["zumbis"].append(Vector2(predio.get_center().x, predio.end.y - 300.0))
	pecas["zumbis"].append(predio.get_center())
	pecas["zumbis"].append(Vector2(predio.get_center().x + 700.0, predio.position.y + 500.0))

# --- o mercado --------------------------------------------------------------

## Mercado de beira de estrada: um salao grande com fileira de prateleira e
## geladeira, mais estacionamento. E o mercadinho de esquina do bairro em outra
## escala - muito loot comum, quase nenhum documento.
static func _mercado(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]

	var salao := Rect2(r.position.x + 500.0, r.position.y + 900.0, 4200.0, 2200.0)
	pecas["construcoes"].append({
		"rect": salao, "porta": "norte", "tipo": "mercado", "documento": true,
	})

	# Estacionamento entre a rodovia e a porta.
	pecas["piso"].append(Rect2(r.position.x, r.position.y, r.size.x, 900.0))

	for i in 4:
		pecas["moveis_de_rua"].append({
			"tipo": "carro",
			"pos": Vector2(r.position.x + 500.0 + float(i) * 700.0, r.position.y + 450.0),
		})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(salao.position.x - 180.0, salao.position.y + 300.0),
	})
	pecas["zumbis"].append(Vector2(r.position.x + 900.0, r.position.y + 460.0))
	pecas["zumbis"].append(salao.get_center())
	pecas["zumbis"].append(salao.get_center() + Vector2(1200.0, 400.0))

# --- a mansao murada --------------------------------------------------------

## Condominio murado abandonado, do outro lado do rio - o lugar mais longe do
## mapa, e o que so vale a pena com o dia inteiro na frente.
##
## O muro e o que o PZ chama de gated community: perimetro fechado com **um
## portao so**. Ele nao protege voce, ele te encurrala: entrar e facil, sair
## com horda atras e um problema, porque so existe uma saida.
static func _mansao(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]
	var muro := 24.0
	# O portao fica no muro do sul, alinhado com a via de acesso.
	var portao_x := r.position.x + r.size.x * 0.5
	var meio_portao := 200.0

	# Muro norte, leste e oeste inteiros; o sul com o vao do portao.
	pecas["cercas"].append(Rect2(r.position.x, r.position.y, r.size.x, muro))
	pecas["cercas"].append(Rect2(r.position.x, r.position.y, muro, r.size.y))
	pecas["cercas"].append(Rect2(r.end.x - muro, r.position.y, muro, r.size.y))
	pecas["cercas"].append(Rect2(r.position.x, r.end.y - muro,
		portao_x - meio_portao - r.position.x, muro))
	pecas["cercas"].append(Rect2(portao_x + meio_portao, r.end.y - muro,
		r.end.x - portao_x - meio_portao, muro))

	# A casa grande no fundo do terreno, virada para o portao.
	var casa := Rect2(r.position.x + r.size.x * 0.28, r.position.y + 700.0, 3400.0, 2400.0)
	pecas["construcoes"].append({
		"rect": casa, "porta": "sul", "tipo": "mansao", "documento": true,
	})

	# Garagem separada, do lado.
	pecas["construcoes"].append({
		"rect": Rect2(casa.end.x + 600.0, casa.position.y + 400.0, 1100.0, 900.0),
		"porta": "sul", "tipo": "garagem",
	})

	# Alameda de concreto do portao ate a porta da casa.
	pecas["piso"].append(Rect2(portao_x - 220.0, casa.end.y, 440.0, r.end.y - casa.end.y))

	# Jardim tomado: bosque nos cantos que sobram, longe da alameda.
	# Jardim abandonado: mata fechada, que e o que faz o terreno parecer largado
	# e nao apenas vazio.
	pecas["bosques"].append({
		"rect": Rect2(r.position.x + muro, r.position.y + muro,
			r.size.x * 0.24, r.size.y - muro * 2.0),
		"densidade": 0.8,
	})
	pecas["bosques"].append({
		"rect": Rect2(r.end.x - r.size.x * 0.2 - muro, r.end.y - 1900.0,
			r.size.x * 0.2, 1700.0),
		"densidade": 0.8,
	})

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(portao_x + 700.0, r.end.y - 500.0),
	})
	pecas["zumbis"].append(Vector2(portao_x, r.end.y - 700.0))
	pecas["zumbis"].append(casa.get_center())
	pecas["zumbis"].append(casa.get_center() + Vector2(-900.0, 500.0))
	pecas["zumbis"].append(Vector2(r.position.x + r.size.x * 0.8, r.position.y + 900.0))

# --- floresta ---------------------------------------------------------------

## Mata. Nao tem loot e nao tem construcao: e o vazio entre os lugares, e e ele
## que faz a distancia existir. No PZ e a floresta entre as cidades que
## transforma "ir ate lá" numa decisao.
##
## O bosque nao ocupa o retangulo inteiro - fica uma faixa livre na borda, para
## a mata nunca fechar a passagem ao lado da estrada.
static func _floresta(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]
	# A densidade viaja com o bosque, e nao e detalhe: sem ela o orcamento de
	# arvore se reparte por area, e a florestinha - pequena - recebia tao pouca
	# arvore que ficava indistinguivel de campo aberto. Mata que nao se ve nao e
	# mata, e uma cor de fundo.
	pecas["bosques"].append({
		"rect": r.grow(-160.0),
		"densidade": lugar.get("densidade", 0.03),
	})
	# Um ou dois arrastando entre as arvores, para a mata nao ser passeio.
	pecas["zumbis"].append(r.get_center())
	if r.get_area() > 60000000.0:
		pecas["zumbis"].append(r.get_center() + r.size * 0.28)
