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
## O trecho **reto** da rodovia: o que atravessa o bairro e a cidade.
##
## Reto de proposito, e so aqui: cidade nasce em trecho reto de estrada, e a
## grade da cidade tem que se alinhar com ele. O resto da rodovia e torto - ver
## ESTRADAS.
const RODOVIA := Rect2(3600.0, 10200.0, 24000.0, 400.0)

## O rio, de cima a baixo. Agua e solida aqui - nao se nada.
const RIO := Rect2(30000.0, 0.0, 1600.0, 22000.0)

## A ponte, onde a rodovia cruza o rio.
const PONTE := Rect2(30000.0, 9980.0, 1600.0, 840.0)

const LARGURA_DA_RODOVIA := 400.0
const LARGURA_DA_ESTRADA_DE_TERRA := 260.0

## **As estradas tortas, e por que elas existem.**
##
## Ate 09/09/2026 a noite o mapa inteiro passava por uma linha reta so, de ponta
## a ponta - e cidade nao e assim. Estrada de verdade contorna, sobe e desce.
##
## Dava para consertar barato porque **estrada nao tem colisao**: e chao
## pintado, e o custo de fazer ela torta e desenho, nao fisica nem navegacao.
## Cada polilinha aqui vira uma fila de retangulos sobrepostos (ver _faixa).
##
## O trecho reto do meio continua reto, e e onde ficam o bairro e a cidade. O
## que era estrada de terra em linha vertical virou uma estrada que serpenteia
## o norte inteiro ligando os dois sitios - e e ela que faz o norte deixar de
## ser campo com nada.
const ESTRADAS := [
	# A rodovia chegando do noroeste, antes do trecho reto.
	[Vector2(0.0, 6800.0), Vector2(1200.0, 7600.0), Vector2(2200.0, 9000.0),
		Vector2(3100.0, 10100.0), Vector2(3900.0, 10400.0)],
	# E saindo do trecho reto para a ponte, com uma lombada.
	[Vector2(27400.0, 10400.0), Vector2(28400.0, 9760.0), Vector2(29300.0, 9860.0),
		Vector2(30100.0, 10400.0)],
	# Depois da ponte, subindo para o nordeste.
	[Vector2(31500.0, 10400.0), Vector2(33000.0, 10740.0), Vector2(34900.0, 10180.0),
		Vector2(36800.0, 9300.0), Vector2(38400.0, 8500.0), Vector2(40000.0, 8100.0)],
	# A entrada da mansao, saindo da estrada acima.
	[Vector2(35100.0, 10200.0), Vector2(35100.0, 9900.0)],
]

## As estradas de terra: sem asfalto e sem calcada, e as mais tortas de todas.
const ESTRADAS_DE_TERRA := [
	# Da rodovia ate o sitio do norte, serpenteando.
	[Vector2(9400.0, 10300.0), Vector2(9000.0, 8600.0), Vector2(9600.0, 7000.0),
		Vector2(8900.0, 5400.0), Vector2(8680.0, 3800.0)],
	# E o ramal que corta o norte inteiro ate o sitio do leste.
	[Vector2(9600.0, 7000.0), Vector2(13000.0, 6200.0), Vector2(17000.0, 5600.0),
		Vector2(21000.0, 5000.0), Vector2(24500.0, 4800.0), Vector2(26680.0, 5300.0)],
	# Da cidade ate a lavoura.
	[Vector2(17150.0, 13200.0), Vector2(17600.0, 14000.0), Vector2(17200.0, 14600.0),
		Vector2(17400.0, 15200.0)],
]

## Onde cada lugar fica.
##
## A cidade e alinhada com o trecho reto da rodovia de proposito: a rua do meio
## da grade **e** a rodovia (7.400 + 400 de rua + 2.400 de quadra = 10.200).
## Mexer na altura da cidade sem mexer nisso descola a grade da estrada, e o
## conferir_mapa acusa.
const LUGARES := [
	{ "nome": "mata do oeste", "tipo": "floresta", "rect": Rect2(0.0, 0.0, 3800.0, 22000.0) },
	{ "nome": "bairro", "tipo": "bairro", "rect": Rect2(4200.0, 8580.0, 5760.0, 3600.0) },
	{ "nome": "cidade", "tipo": "cidade", "rect": Rect2(11200.0, 7400.0, 13200.0, 6000.0) },
	{ "nome": "posto", "tipo": "posto", "rect": Rect2(24800.0, 10600.0, 2200.0, 1500.0) },
	{ "nome": "lavoura", "tipo": "lavoura", "rect": Rect2(13000.0, 14380.0, 9000.0, 4600.0) },
	# Os dois sitios existem porque o norte era campo com nada - e campo com
	# nada nao e mapa, e caminhada. No PZ o que enche o entorno da cidade sao
	# exatamente casas de campo penduradas em estrada de terra.
	{ "nome": "sítio do norte", "tipo": "sitio", "rect": Rect2(8200.0, 1900.0, 2400.0, 1900.0) },
	{ "nome": "sítio do leste", "tipo": "sitio", "rect": Rect2(26200.0, 3400.0, 2400.0, 1900.0) },
	{ "nome": "mata do norte", "tipo": "floresta", "rect": Rect2(4200.0, 0.0, 24000.0, 6900.0) },
	# A mata do sul e a **fechada**: e nela que nao se ve o outro lado. Era um
	# lugar proprio chamado "florestinha" ate 09/09 a noite, e virou redundante
	# quando o mapa ganhou quatro matas - agora e uma densidade, e nao um lugar.
	{
		"nome": "mata do sul", "tipo": "floresta", "densidade": 0.55,
		"rect": Rect2(23200.0, 14200.0, 5800.0, 7000.0),
	},
	{ "nome": "mansão murada", "tipo": "mansao", "rect": Rect2(32800.0, 5780.0, 4600.0, 4200.0) },
	{ "nome": "mata do leste", "tipo": "floresta", "rect": Rect2(32000.0, 12380.0, 7800.0, 9400.0) },
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
		# "ruas" sao os trechos retos, e sao os unicos que ganham calcada.
		"ruas": [RODOVIA],
		# "estradas" e "terra" sao as tortas: fila de retangulos ao longo de uma
		# polilinha, sem calcada. Estrada de rodagem no meio do campo nao tem.
		"estradas": [],
		"terra": [],
		"piso": [PONTE],
		"agua": [RIO],
		# Terra arada: so chao pintado, sem colisao. E a textura de campo do PZ.
		"lavoura": [],
		# Solido mas nao desenhado: o desenho e a agua, a colisao e isto.
		"solidos": [],
	}

	for pontos in ESTRADAS:
		tudo["estradas"].append_array(_faixa(pontos, LARGURA_DA_RODOVIA))
	for pontos in ESTRADAS_DE_TERRA:
		tudo["terra"].append_array(_faixa(pontos, LARGURA_DA_ESTRADA_DE_TERRA))

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

## Uma faixa de estrada ao longo de uma polilinha, feita de quadrados que se
## sobrepoem.
##
## **Estrada nao tem colisao** - e chao pintado -, entao ela pode ser tao torta
## quanto se queira: o custo de fazer curva e desenho, e nao fisica nem
## navegacao. Foi isso que permitiu tirar o mapa da linha reta sem mexer em nada
## mais.
##
## Quadrado e nao retangulo orientado, e com sobreposicao de 55%: assim a faixa
## fica continua em qualquer angulo, sem serrilha e sem buraco na curva.
static func _faixa(pontos: Array, largura: float) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	var passo := largura * 0.45
	for i in range(1, pontos.size()):
		var de: Vector2 = pontos[i - 1]
		var ate: Vector2 = pontos[i]
		var quantos := maxi(1, int(ceil(de.distance_to(ate) / passo)))
		for k in quantos + 1:
			var onde := de.lerp(ate, float(k) / float(quantos))
			fora.append(Rect2(onde - Vector2.ONE * largura * 0.5, Vector2.ONE * largura))
	return fora

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
