## O mundo: onde fica cada coisa. **Fonte unica do mapa.**
##
## Este arquivo diz ONDE; o `rua/lugares.gd` diz DO QUE cada lugar e feito, e o
## `rua/construcao.gd` diz como uma construcao qualquer se desenha por dentro.
## Quem quiser mudar o mapa mexe aqui.
##
## ## A escala, e por que ela e essa
##
## **40 px = 1 metro** - o jogador tem 40 px de altura. O mundo tem
## 40.000 x 26.000 px, ou seja **1 km x 650 m**.
##
## Ele ja foi de 144 x 90 m (o bairro sozinho, ate 09/09/2026) e de 1,44 km x
## 900 m (a primeira versao do mapa grande, no mesmo dia). **Encolheu para 1 km
## x 650 m em 09/09 a noite**, e por um motivo: era campo vazio demais para
## caminhada demais. Mapa grande nao e mapa bom - o que faz distancia valer algo
## e ter coisa nas duas pontas.
##
## ## A forma e a de Rosewood, no Project Zomboid
##
## O que a referencia mostra e o que faltava aqui: **um nucleo denso com grade de
## ruas**, com dezenas de predios pequenos encostados na calcada, e campo em
## volta. Nao lugares isolados pendurados numa rodovia.
##
## De oeste para leste: mata, o **bairro** (onde fica a sua casa), a **cidade** -
## oito quadras, a delegacia e o mercado dentro dela -, o **posto** na beira da
## pista, a **lavoura**, o **rio** que corta o mapa e so se cruza pela **ponte**,
## e a **mansao murada** do outro lado. Mata nas bordas.
##
## ## Os tamanhos sao de gente
##
## Em 09/09 a noite todo predio grande foi remedido, porque estavam absurdos: o
## mercado tinha 105 x 55 m e a delegacia 90 x 65 m - um hipermercado e um forum,
## nao um mercadinho e uma delegacia de cidade pequena. Agora saem da tabela
## TAMANHOS do construcao.gd, em metros de gente.
##
## ## Um documento por lugar
##
## Os seis documentos que existem estao em seis predios declarados - dois no
## bairro, dois na cidade, um no posto e um na mansao. Nao e sorteio, e e o que
## faz a variedade do mapa valer algo mecanicamente e nao so visualmente.

const Lugares := preload("res://rua/lugares.gd")

const MUNDO := Rect2(0.0, 0.0, 40000.0, 22000.0)

## A rodovia leste-oeste, que e a espinha do mapa. No trecho do bairro e a rua
## principal dele, e no trecho da cidade e a rua do meio da grade.
const RODOVIA := Rect2(0.0, 10200.0, 40000.0, 400.0)

## O rio, de cima a baixo. Agua e solida aqui - nao se nada.
const RIO := Rect2(30000.0, 0.0, 1600.0, 22000.0)

## A ponte, onde a rodovia cruza o rio. Um pouco mais alta que o asfalto, para
## sobrar guarda-corpo dos dois lados.
const PONTE := Rect2(30000.0, 9980.0, 1600.0, 840.0)

## Onde cada lugar fica.
##
## A cidade e alinhada com a rodovia de proposito: a rua do meio da grade **e** a
## rodovia (7.400 + 400 de rua + 2.400 de quadra = 10.200). Mexer na altura da
## cidade sem mexer nisso descola a grade da estrada, e o conferir_mapa acusa.
const LUGARES := [
	{ "nome": "mata do oeste", "tipo": "floresta", "rect": Rect2(0.0, 0.0, 3800.0, 22000.0) },
	{ "nome": "bairro", "tipo": "bairro", "rect": Rect2(4200.0, 8580.0, 5760.0, 3600.0) },
	# A florestinha: pequena e **fechada**. As outras matas sao campo com arvore
	# espalhada; esta e a unica em que nao se ve o outro lado.
	{
		"nome": "florestinha", "tipo": "floresta", "densidade": 1.0,
		"rect": Rect2(9600.0, 14780.0, 2600.0, 2200.0),
	},
	{ "nome": "cidade", "tipo": "cidade", "rect": Rect2(11200.0, 7400.0, 12400.0, 6000.0) },
	{ "nome": "posto", "tipo": "posto", "rect": Rect2(24600.0, 10600.0, 2200.0, 1500.0) },
	{ "nome": "lavoura", "tipo": "lavoura", "rect": Rect2(13000.0, 14380.0, 9000.0, 4600.0) },
	# Os dois sitios existem porque o norte e o nordeste eram campo com nada -
	# e campo com nada nao e mapa, e caminhada. No PZ o que enche o entorno da
	# cidade sao exatamente casas de campo penduradas em estrada de terra.
	{ "nome": "sítio do norte", "tipo": "sitio", "rect": Rect2(8200.0, 2000.0, 2400.0, 1900.0) },
	{ "nome": "sítio do leste", "tipo": "sitio", "rect": Rect2(26200.0, 3400.0, 2400.0, 1900.0) },
	{ "nome": "mata do norte", "tipo": "floresta", "rect": Rect2(4200.0, 0.0, 24000.0, 6900.0) },
	{ "nome": "mata do sul", "tipo": "floresta", "rect": Rect2(23200.0, 14200.0, 5800.0, 7000.0) },
	{ "nome": "mansão murada", "tipo": "mansao", "rect": Rect2(32800.0, 5780.0, 4600.0, 4200.0) },
	{ "nome": "mata do leste", "tipo": "floresta", "rect": Rect2(32000.0, 12380.0, 7800.0, 9400.0) },
]

## As vias que ligam a rodovia aos lugares que nao encostam nela. No PZ e a via
## de acesso que diz "aqui tem algo" muito antes de voce ver o predio.
const ACESSOS := [
	# Da rodovia ate o portao da mansao, do outro lado do rio.
	Rect2(34950.0, 9980.0, 300.0, 260.0),
	# Da rua de baixo da cidade ate a lavoura.
	Rect2(17000.0, 13400.0, 300.0, 1000.0),
	# Estrada de terra da rodovia ate o sitio do norte, cortando a mata. E ela
	# que faz o norte deixar de ser campo com nada.
	Rect2(9250.0, 3900.0, 300.0, 6300.0),
	# E a do sitio do leste, saindo da rodovia depois do posto.
	Rect2(27250.0, 5300.0, 300.0, 4900.0),
]

const CALCADA := 120.0

static var _montado: Dictionary = {}

## O mundo montado, em coordenada de mundo. Montado uma vez e guardado: o
## cenario, os telhados e as ferramentas leem todos daqui, e todos tem que ver o
## mesmo mapa.
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
		# Terra arada: so chao pintado, sem colisao. E a textura de campo do PZ.
		"lavoura": [],
		# Solido mas nao desenhado: o desenho e a agua, a colisao e isto.
		"solidos": [],
	}

	for acesso in ACESSOS:
		tudo["ruas"].append(acesso)

	# O rio e solido dos dois lados da ponte. Nao ha como nadar, e nao ha outro
	# atravessadouro - e o que faz a mansao ser longe de verdade.
	tudo["solidos"].append(Rect2(RIO.position,
		Vector2(RIO.size.x, PONTE.position.y - RIO.position.y)))
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

static func onde_o_bairro_comeca() -> Vector2:
	for lugar in LUGARES:
		if lugar["tipo"] == "bairro":
			return (lugar["rect"] as Rect2).position
	return Vector2.ZERO

## Onde o jogador nasce, dentro da sua casa. **O cenario posiciona ele por aqui**
## em vez de a posicao estar escrita no rua.tscn: quando o bairro mudou de lugar
## no mapa, a posicao escrita a mao deixou o jogador nascendo no meio do campo, a
## 89 m da propria casa - e isso nao da erro nenhum, so aparece no lugar errado.
static func onde_o_jogador_nasce() -> Vector2:
	return onde_o_bairro_comeca() + Lugares.BAIRRO_JOGADOR

## A porta do porao, que e por onde o dia acaba.
static func onde_fica_a_porta_do_porao() -> Vector2:
	return onde_o_bairro_comeca() + Lugares.BAIRRO_PORTA_DO_PORAO
