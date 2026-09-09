## O mundo: onde fica cada coisa. **Fonte unica do mapa.**
##
## Este arquivo diz ONDE; o `rua/lugares.gd` diz DO QUE cada lugar e feito, e o
## `rua/construcao.gd` diz como uma construcao qualquer se desenha por dentro.
## Quem quiser mudar o mapa mexe aqui.
##
## ## A escala, e por que ela e essa
##
## **40 px = 1 metro** - o jogador tem 40 px de altura. O mundo tem
## 57.600 x 36.000 px, ou seja **1,44 km x 900 m**.
##
## Ate 09/09/2026 o mapa era o bairro sozinho: 5.760 x 3.600, ou 144 x 90 m -
## uma quadra e meia, atravessavel em 20 segundos. Agora o bairro e 1/100 da
## area, e atravessar o mapa a pe leva 206 s, mais do que um dia inteiro de luz
## tinha. **Foi por isso que o dia subiu de 180 para 420 s**: ate o carro
## existir, o mapa tem que ser andavel.
##
## ## A forma do mapa e a do Project Zomboid
##
## Nao e uma grade de quadras: e uma **rodovia leste-oeste** com um punhado de
## lugares pendurados nela, e mata no meio. Muldraugh e exatamente isso, esticada
## ao longo da US-31W. O que faz distancia existir e o vazio entre os lugares.
##
## De oeste para leste: mata, o **bairro** (onde fica a sua casa), o **posto**,
## a **delegacia** afastada da pista, o **mercado**, a mata central, o **rio** -
## que corta o mapa de cima a baixo e so se cruza pela **ponte** - e, do outro
## lado, a **mansao murada**. Mais mata nas bordas.
##
## O rio e de proposito: ele parte o mapa em dois e a ponte e o unico
## atravessadouro. A mansao fica atras dele, e e o lugar mais longe do mapa.
##
## ## Um documento por lugar
##
## Cada um dos seis lugares com predio guarda **um documento**, sempre no quarto
## mais fundo. Nao e sorteio: os seis documentos que existem estao em seis
## lugares diferentes, dois deles no bairro e quatro exigindo viagem. E o que
## faz a variedade do mapa valer algo mecanicamente, e nao so visualmente.

const Lugares := preload("res://rua/lugares.gd")

const MUNDO := Rect2(0.0, 0.0, 57600.0, 36000.0)

## A rodovia leste-oeste, que e a espinha do mapa. Tem a mesma largura da rua
## principal que o bairro sempre teve, e no trecho do bairro **e** ela.
const RODOVIA := Rect2(0.0, 17100.0, 57600.0, 400.0)

## O rio, de cima a baixo. Agua e solida aqui - nao se nada.
const RIO := Rect2(38400.0, 0.0, 2400.0, 36000.0)

## A ponte, onde a rodovia cruza o rio. Um pouco mais alta que o asfalto, para
## sobrar guarda-corpo dos dois lados.
const PONTE := Rect2(38400.0, 16800.0, 2400.0, 1000.0)

## Onde cada lugar fica. A ordem nao importa; os retangulos nao se encostam de
## proposito - o que sobra entre eles e grama, e e ela que faz a caminhada.
const LUGARES := [
	{ "nome": "mata do oeste", "tipo": "floresta", "rect": Rect2(0.0, 0.0, 5600.0, 36000.0) },
	# A florestinha: pequena e **fechada**, entre o bairro e o posto, do lado sul
	# da rodovia. As outras matas sao campo com arvore espalhada; esta e a unica
	# em que nao se ve o outro lado, e e o que faz atalho pela mata ser aposta.
	{
		"nome": "florestinha", "tipo": "floresta", "densidade": 1.0,
		"rect": Rect2(12200.0, 19400.0, 3400.0, 2900.0),
	},
	{ "nome": "bairro", "tipo": "bairro", "rect": Rect2(6000.0, 15480.0, 5760.0, 3600.0) },
	{ "nome": "posto", "tipo": "posto", "rect": Rect2(15600.0, 17500.0, 4200.0, 2600.0) },
	{ "nome": "delegacia", "tipo": "delegacia", "rect": Rect2(22000.0, 12600.0, 6000.0, 4300.0) },
	{ "nome": "mercado", "tipo": "mercado", "rect": Rect2(29000.0, 17500.0, 5600.0, 3800.0) },
	{ "nome": "mata do norte", "tipo": "floresta", "rect": Rect2(6400.0, 0.0, 30000.0, 11400.0) },
	{ "nome": "mata central", "tipo": "floresta", "rect": Rect2(20000.0, 22400.0, 17000.0, 12000.0) },
	{ "nome": "mansao murada", "tipo": "mansao", "rect": Rect2(45000.0, 9000.0, 8600.0, 7000.0) },
	{ "nome": "mata do leste", "tipo": "floresta", "rect": Rect2(41600.0, 19600.0, 15600.0, 15000.0) },
]

## As vias que ligam cada lugar afastado a rodovia. Sem elas o lugar existe mas
## nao se chega nele por asfalto - e no PZ e a via de acesso que diz "aqui tem
## algo", muito antes de voce ver o predio.
const ACESSOS := [
	# Da rodovia ate o patio da delegacia.
	Rect2(24700.0, 16900.0, 300.0, 300.0),
	# Da rodovia ate o portao da mansao, do outro lado do rio.
	Rect2(49150.0, 16000.0, 300.0, 1200.0),
]

const CALCADA := 120.0

static var _montado: Dictionary = {}

## O mundo montado, em coordenada de mundo. Montado uma vez e guardado: o
## cenario, os telhados e as ferramentas leem todos daqui, e todos tem que ver
## o mesmo mapa.
static func mundo() -> Dictionary:
	if _montado.is_empty():
		_montado = _montar()
	return _montado

static func _montar() -> Dictionary:
	var tudo := {
		"construcoes": [],
		"cercas": [],
		"bosques": [],
		"moveis_de_rua": [],
		"zumbis": [],
		"ruas": [RODOVIA],
		"piso": [PONTE],
		"agua": [RIO],
		# Solido mas nao desenhado: o desenho e a agua, a colisao e isto.
		"solidos": [],
	}

	for acesso in ACESSOS:
		tudo["ruas"].append(acesso)

	# O rio e solido dos dois lados da ponte. Nao ha como nadar, e nao ha outro
	# atravessadouro - e o que faz a mansao ser longe de verdade.
	tudo["solidos"].append(Rect2(RIO.position, Vector2(RIO.size.x, PONTE.position.y - RIO.position.y)))
	tudo["solidos"].append(Rect2(Vector2(RIO.position.x, PONTE.end.y),
		Vector2(RIO.size.x, RIO.end.y - PONTE.end.y)))

	for lugar in LUGARES:
		var pecas := Lugares.montar(lugar)
		for chave in pecas:
			(tudo[chave] as Array).append_array(pecas[chave])

	return tudo

## Calcada dos dois lados de cada rua. Sai da lista de ruas em vez de estar
## escrita: rua nova ja nasce com calcada.
static func calcadas() -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for rua in mundo()["ruas"]:
		var r: Rect2 = rua
		if r.size.x > r.size.y:
			fora.append(Rect2(r.position.x, r.position.y - CALCADA, r.size.x, CALCADA))
			fora.append(Rect2(r.position.x, r.end.y, r.size.x, CALCADA))
		else:
			fora.append(Rect2(r.position.x - CALCADA, r.position.y, CALCADA, r.size.y))
			fora.append(Rect2(r.end.x, r.position.y, CALCADA, r.size.y))
	return fora

## Em qual construcao esta o ponto, ou -1. Os telhados usam para esconder o
## telhado de quem esta dentro.
static func construcao_em(ponto: Vector2) -> int:
	var construcoes: Array = mundo()["construcoes"]
	for i in construcoes.size():
		if (construcoes[i]["rect"] as Rect2).has_point(ponto):
			return i
	return -1

## O lugar em que o ponto esta, ou uma string vazia. E o que a HUD usa para
## dizer onde voce esta num mapa em que "a rua" nao quer mais dizer nada.
static func lugar_em(ponto: Vector2) -> String:
	for lugar in LUGARES:
		if (lugar["rect"] as Rect2).has_point(ponto):
			return lugar["nome"]
	if RODOVIA.grow(CALCADA).has_point(ponto):
		return "rodovia"
	return "estrada de terra"

## Um lugar pelo nome. **Use isto, e nao LUGARES[n]:** a lista muda de ordem a
## cada lugar novo, e indice fixo passa a apontar para outro lugar sem avisar -
## foi o que aconteceu com as conferencias do zumbi quando o mapa cresceu.
static func lugar(nome: String) -> Dictionary:
	for qual in LUGARES:
		if qual["nome"] == nome:
			return qual
	return {}

## Onde o jogador nasce: a porta do porao da sua casa, no bairro.
static func onde_o_bairro_comeca() -> Vector2:
	for lugar in LUGARES:
		if lugar["tipo"] == "bairro":
			return (lugar["rect"] as Rect2).position
	return Vector2.ZERO
