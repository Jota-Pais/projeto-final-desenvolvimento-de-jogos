## O mundo: onde fica cada coisa. **Fonte unica do mapa.**
##
## Este arquivo diz ONDE; o `rua/lugares.gd` diz DO QUE cada lugar e feito, e o
## `rua/construcao.gd` diz como uma construcao qualquer se desenha por dentro.
## Quem quiser mudar o mapa mexe aqui.
##
## ## A escala, e por que ela e essa
##
## **40 px = 1 metro** - o jogador tem 40 px de altura. O mundo tem
## 40.000 x 22.000 px, ou seja **1 km x 550 m** - e o numero sai do MUNDO
## abaixo, que e quem manda.
##
## Ele ja foi de 144 x 90 m (o bairro sozinho, ate 09/09/2026) e de 1,44 km x
## 900 m (a primeira versao do mapa grande, no mesmo dia). **Encolheu para 1 km
## x 550 m em 09/09 a noite**, e por um motivo: era campo vazio demais para
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
## Os seis documentos placeholder saem em seis predios declarados em vez de
## sorteados, para o mapa espalhar a progressao em vez de amontoa-la. **Quais
## lugares, e o que cada documento e, nao foi decidido pela equipe** - a divisao
## de hoje existe so para a partida ter como ser ganha.

const Lugares := preload("res://rua/lugares.gd")
## So para a porta de casa: a fachada de uma construcao e regra do Construcao,
## e o mapa nao tem por que saber onde fica o vao.
const Construcao := preload("res://rua/construcao.gd")
## O que uma via e por fora - largura, calcada, grafo. Ver a docstring de
## `vias.gd` para o porque desta entidade existir.
const Vias := preload("res://rua/vias.gd")

const MUNDO := Rect2(0.0, 0.0, 40000.0, 22000.0)

## A versao do mapa - sobe toda vez que a IDENTIDADE dos moveis (a lista de
## chaves, na ordem de geracao) muda de proposito. So serve de carimbo no
## relatorio do conferir_mapa; quem prova de verdade e IMPRESSAO_ESPERADA.
const VERSAO_DO_MAPA := 1

## Hash (8 digitos hex) da lista de chaves de todo movel gerado num dia
## comum, na ordem em que nascem - commitada aqui e COMPARADA pelo
## conferir_mapa (17/09/2026, P6), nao so impressa. Imprimir nao e
## checagem: um numero que so aparece no console e que ninguem confere
## nunca falha, e a identidade podia embaralhar em silencio de novo.
##
## Recalcula rodando `conferir_mapa.tscn` e copiando o valor que ele imprime
## em "IMPRESSAO DIGITAL DOS MOVEIS" - so depois de conferir que a mudanca
## que moveu o numero foi de proposito.
const IMPRESSAO_ESPERADA := "d7dc64ff"

## A rodovia leste-oeste, que e a espinha do mapa - a costura entre a cidade
## (100% ao norte dela, a partir de 17/09/2026) e o bairro (100% ao sul).
## O trecho **reto**: o que atravessa a faixa onde ficam os dois.
##
## Reto de proposito, e so aqui: cidade e bairro nascem em trecho reto de
## estrada. O resto da rodovia e torto - ver ESTRADAS.
##
## **14 tiles (640 px), nao mais 10** (17/09/2026, P7 - arquitetura nova):
## a largura de hoje media a mesma coisa que uma rua de bairro, e era metade
## da queixa "o mapa inteiro se passa numa rua so". 640 e a Dixie Highway do
## PZ. So a altura muda aqui - x e y continuam os mesmos.
const RODOVIA := Rect2(3600.0, 10200.0, 24000.0, 640.0)

## O rio, de cima a baixo. Agua e solida aqui - nao se nada.
const RIO := Rect2(30000.0, 0.0, 1600.0, 22000.0)

## A ponte, onde a rodovia cruza o rio - centralizada na rodovia mais alta.
const PONTE := Rect2(30000.0, 10100.0, 1600.0, 840.0)

## **As estradas tortas, e por que elas existem.**
##
## Ate 09/09/2026 a noite o mapa inteiro passava por uma linha reta so, de ponta
## a ponta - e cidade nao e assim. Estrada de verdade contorna, sobe e desce.
##
## Dava para consertar barato porque **estrada nao tem colisao**: e chao
## pintado, e o custo de fazer ela torta e desenho, nao fisica nem navegacao.
## Cada polilinha aqui vira uma VIA de classe `rural`/`terra` (17/09/2026: antes
## virava direto uma fila de retangulos; `Vias.faixa_pintada` desenha agora).
##
## O trecho reto do meio continua reto, e e onde ficam o bairro e a cidade. O
## que era estrada de terra em linha vertical virou uma estrada que serpenteia
## o norte inteiro ligando os dois sitios - e e ela que faz o norte deixar de
## ser campo com nada.
## Recentralizadas em y 10520 (17/09/2026): o centro da rodovia subiu de
## 10400 para 10520 quando ela engordou de 400 para 640 - a ponta de cada
## estrada torta tem que continuar caindo dentro da faixa dela.
const ESTRADAS := [
	# A rodovia chegando do noroeste, antes do trecho reto.
	[Vector2(0.0, 6800.0), Vector2(1200.0, 7600.0), Vector2(2200.0, 9000.0),
		Vector2(3100.0, 10220.0), Vector2(3900.0, 10520.0)],
	# E saindo do trecho reto para a ponte, com uma lombada.
	[Vector2(27400.0, 10520.0), Vector2(28400.0, 9880.0), Vector2(29300.0, 9980.0),
		Vector2(30100.0, 10520.0)],
	# Depois da ponte, subindo para o nordeste.
	[Vector2(31500.0, 10520.0), Vector2(33000.0, 10860.0), Vector2(34900.0, 10300.0),
		Vector2(36800.0, 9420.0), Vector2(38400.0, 8620.0), Vector2(40000.0, 8220.0)],
	# A entrada da mansao, saindo da estrada acima.
	[Vector2(35100.0, 10320.0), Vector2(35100.0, 10020.0)],
]

## As estradas de terra: sem asfalto e sem calcada, e as mais tortas de todas.
const ESTRADAS_DE_TERRA := [
	# Da rodovia ate o sitio do norte, serpenteando.
	[Vector2(9400.0, 10520.0), Vector2(9000.0, 8600.0), Vector2(9600.0, 7000.0),
		Vector2(8900.0, 5400.0), Vector2(8680.0, 3800.0)],
	# E o ramal que corta o norte inteiro ate o sitio do leste.
	[Vector2(9600.0, 7000.0), Vector2(13000.0, 6200.0), Vector2(17000.0, 5600.0),
		Vector2(21000.0, 5000.0), Vector2(24500.0, 4800.0), Vector2(26680.0, 5300.0)],
	# Da rodovia ate a lavoura. Ate 17/09/2026 saia da cidade, que agora
	# mudou de lugar (100% ao norte da rodovia) e deixou de estar perto -
	# a estrada passou a sair da propria rodovia, mais a leste.
	[Vector2(17400.0, 10520.0), Vector2(17500.0, 12500.0), Vector2(17200.0, 13800.0),
		Vector2(17400.0, 14380.0)],
]

## Onde cada lugar fica.
##
## **A cidade fica 100% ao norte da rodovia, e o bairro 100% ao sul**
## (17/09/2026, P7 - arquitetura nova; decisao de dono, default aplicado).
## Ate aqui o bairro crescia por cima da rodovia (ela cortava o loteamento ao
## meio) - a rodovia virava fronteira invisivel, nao costura. Agora atravessar
## a pista para ir da sua casa a cidade e um trecho de verdade do trajeto, e
## nao um detalhe que a rua ja resolvia sozinha.
const LUGARES := [
	{
		"nome": "mata do oeste", "tipo": "mata", "rect": Rect2(0.0, 0.0, 3800.0, 22000.0),
		"densidade": 0.45, "lado_da_mata": "oeste",
	},
	# Ao SUL da rodovia (y >= 10840). O retangulo e o de Lugares.BAIRRO_TAMANHO,
	# os dois tem que bater. Cresceu 1040 px para o leste em P16, para a
	# Estrada Velha ganhar uma casa sem sair do MUNDO (ver a docstring de
	# BAIRRO_TAMANHO).
	{
		"nome": "bairro", "tipo": "bairro", "rect": Rect2(4200.0, 10840.0, 6800.0, 6800.0),
		"acesso": Vector2(7000.0, 10520.0),
	},
	# Ao NORTE da rodovia, encostada nela (y ate 10200). Cresceu 1000 px pra
	# leste (de 24400 para 24600) pra caber o laco do fim da Avenida.
	{
		"nome": "cidade", "tipo": "cidade", "rect": Rect2(11200.0, 3200.0, 13400.0, 7000.0),
		"acesso": Vector2(17000.0, 10520.0),
	},
	{
		"nome": "posto", "tipo": "posto", "rect": Rect2(24800.0, 10840.0, 2200.0, 1500.0),
		"acesso": Vector2(24800.0, 10840.0),
	},
	{
		"nome": "lavoura", "tipo": "lavoura", "rect": Rect2(13000.0, 14380.0, 9000.0, 4600.0),
		"acesso": Vector2(17400.0, 14380.0),
	},
	# Os dois sitios existem porque o norte era campo com nada - e campo com
	# nada nao e mapa, e caminhada. No PZ o que enche o entorno da cidade sao
	# exatamente casas de campo penduradas em estrada de terra.
	{
		"nome": "sítio do norte", "tipo": "sitio", "rect": Rect2(8200.0, 1900.0, 2400.0, 1900.0),
		"acesso": Vector2(8680.0, 3800.0),
	},
	{
		"nome": "sítio do leste", "tipo": "sitio", "rect": Rect2(26200.0, 3400.0, 2400.0, 1900.0),
		"acesso": Vector2(26680.0, 5300.0),
	},
	# Encolheu de 6900 para 3200 de altura: a cidade subiu para caber toda ao
	# norte da rodovia, e passou a nascer onde a mata do norte terminava.
	{
		"nome": "mata do norte", "tipo": "mata", "rect": Rect2(3600.0, 0.0, 24000.0, 3200.0),
		"densidade": 0.45, "lado_da_mata": "norte",
	},
	# A mata do sul e a **fechada**: e nela que nao se ve o outro lado. Era um
	# lugar proprio chamado "florestinha" ate 09/09 a noite, e virou redundante
	# quando o mapa ganhou quatro matas - agora e uma densidade, e nao um lugar.
	# Sem "lado_da_mata": e a unica cujo retangulo inteiro e fechado, nao so
	# uma faixa de borda - ela nao encosta no limite do MUNDO dos dois lados
	# como as outras tres, entao nao ha "fora" para deixar aberto.
	{
		"nome": "mata do sul", "tipo": "mata", "densidade": 0.55,
		"rect": Rect2(23200.0, 14200.0, 5800.0, 7000.0),
	},
	{ "nome": "mansão murada", "tipo": "mansao", "rect": Rect2(32800.0, 5780.0, 4600.0, 4200.0) },
	{
		"nome": "mata do leste", "tipo": "mata", "rect": Rect2(32000.0, 12380.0, 7800.0, 9400.0),
		"densidade": 0.45, "lado_da_mata": "leste",
	},
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
		# "vias" e a rede inteira, com nome e classe (17/09/2026) - a fonte.
		# "ruas", "estradas", "terra", "calcadas" e "abertos" viram DERIVADAS
		# dela mais abaixo; nenhum consumidor delas muda de comportamento.
		"vias": [
			{
				"nome": "rodovia", "classe": "rodovia", "lugar": "",
				"eixo": [Vector2(RODOVIA.position.x, RODOVIA.get_center().y),
					Vector2(RODOVIA.end.x, RODOVIA.get_center().y)],
				"pontas": ["emenda:estrada do noroeste", "emenda:estrada do nordeste"],
			},
		],
		"piso": [PONTE],
		"agua": [RIO],
		# Terra arada: so chao pintado, sem colisao. E a textura de campo do PZ.
		"lavoura": [],
		# Solido mas nao desenhado: o desenho e a agua, a colisao e isto.
		"solidos": [],
	}

	for i in ESTRADAS.size():
		tudo["vias"].append({
			"nome": "estrada rural %d" % i, "classe": "rural", "lugar": "",
			"eixo": ESTRADAS[i], "pontas": ["borda", "borda"],
		})
	# Pontas declaradas por indice: as duas pontas que caem dentro da propria
	# rodovia nao precisam - o grafo ja acha esse encontro por sobreposicao -,
	# mas as que terminam num predio (sitio, ainda sem `patio` de verdade -
	# isso e P10) nao tem outra via para se ligar, e sem a ponta declarada
	# o grafo as acusaria como soltas.
	const PONTAS_DA_TERRA := [
		["", "declarado:sitio do norte"],
		["", "declarado:sitio do leste"],
		["", "declarado:lavoura"],
	]
	for i in ESTRADAS_DE_TERRA.size():
		tudo["vias"].append({
			"nome": "estrada de terra %d" % i, "classe": "terra", "lugar": "",
			"eixo": ESTRADAS_DE_TERRA[i], "pontas": PONTAS_DA_TERRA[i],
		})

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

	# Derivadas, todas a partir de "vias" - e por isso que so existe UMA fonte
	# de verdade sobre largura, classe e calcada de cada rua (17/09/2026).
	tudo["ruas"] = _ruas_de(tudo["vias"])
	tudo["estradas"] = _pintadas_de(tudo["vias"], "rural")
	tudo["terra"] = _pintadas_de(tudo["vias"], "terra")
	tudo["calcadas"] = _calcadas_de(tudo["vias"])
	tudo["abertos"] = _abertos_de(tudo["vias"], tudo["piso"])

	return tudo

## As vias que resolvem para UM retangulo (reta ou `rect` declarado) - o que
## `cenario._draw` pinta na camada de asfalto comum, e o que sempre teve
## calcada nos dois lados ate esta reescrita.
static func _ruas_de(vias: Array) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for via in vias:
		if Vias.e_reta(via):
			fora.append(Vias.faixa_de(via))
	return fora

## As vias poligonais (3+ pontos, sem `rect`) de uma classe, ja como fila de
## quadrados pintados - o que era `ESTRADAS`/`ESTRADAS_DE_TERRA` viravam direto
## antes desta reescrita.
static func _pintadas_de(vias: Array, classe: String) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for via in vias:
		if via["classe"] == classe and not Vias.e_reta(via):
			fora.append_array(Vias.faixa_pintada(via))
	return fora

## Calcada de toda via cuja classe tem (`CLASSES[classe].calcada > 0`) -
## **so a rodovia, por enquanto** (17/09/2026): antes toda entrada de "ruas"
## ganhava calcada dos dois lados, residencial e beco inclusive; a fita
## comercial do bairro que vai merecer calcada de verdade so nasce em P7 em
## diante, quando o layout for reescrito.
static func _calcadas_de(vias: Array) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for via in vias:
		for calcada in Vias.calcadas_de(via):
			fora.append_array(Vias.recortar(calcada, vias))
	return fora

## A faixa aberta ao lado de toda via, mais o piso crescido - onde
## `cenario._e_terreno` recusa arvore. Substitui varrer `ruas`, `estradas`,
## `terra` e `piso` como quatro listas separadas: com o mapa 100x maior isso
## economiza consulta, e o resultado e o mesmo (17/09/2026).
##
## Via poligonal (rural/terra) usa a fila de quadrados pintados, sem grow -
## `aberto_de` sozinha devolveria o envelope (retangulo que cobre TODOS os
## pontos da curva), que para uma estrada serpenteando e muito maior que a
## faixa real e fecharia a arvore fora de area que deveria estar livre.
static func _abertos_de(vias: Array, pisos: Array) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for via in vias:
		if Vias.e_reta(via):
			fora.append(Vias.aberto_de(via))
		else:
			fora.append_array(Vias.faixa_pintada(via))
	for piso in pisos:
		fora.append((piso as Rect2).grow(80.0))
	return fora

## Calcada dos dois lados de cada rua. **Derivada de `vias`** (17/09/2026) -
## antes calculava direto de `mundo()["ruas"]`, sem olhar a classe.
static func calcadas() -> Array[Rect2]:
	return mundo()["calcadas"]

## Uma via pelo nome. Mesma regra de `lugar()`: por nome, nunca por indice.
static func via(nome: String) -> Dictionary:
	for qual in mundo()["vias"]:
		if qual["nome"] == nome:
			return qual
	return {}

## As vias que um lugar gerou.
static func vias_do_lugar(nome_do_lugar: String) -> Array:
	var fora := []
	for qual in mundo()["vias"]:
		if qual.get("lugar", "") == nome_do_lugar:
			fora.append(qual)
	return fora

## Um ponto sobre uma via, por nome - para ponto de teste que nao quebra
## quando o layout muda de numero. Ainda sem consumidor (chega em P7).
static func ponto_na_via(nome: String, t: float) -> Vector2:
	return Vias.ponto_em(via(nome), t)

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

## Quanto o jogador nasce afastado da porta, para fora.
##
## Tem que ser maior que a meia altura da zona de deteccao da porta (80 px),
## senao o dia comecaria com voce ja dentro dela: quem sai de casa segurando E
## para vasculhar a primeira lata voltaria para dentro sem entender por que.
const RECUO_DO_NASCIMENTO := 110.0

## Onde o jogador nasce: **na calcada, em frente a porta de casa** - ele acabou
## de sair. Antes ele nascia na sala, e nascer la dentro deixou de ser possivel
## em 16/09/2026, quando a porta virou a unica entrada da casa e passou a ser
## solida: seria nascer trancado.
##
## Sai da porta, que sai do proprio predio - ninguem precisa lembrar de mexer
## aqui se a casa mudar de lugar. A posicao ja esteve escrita a mao no rua.tscn
## e ja esteve escrita a mao no lugares.gd, e as duas vezes ela ficou para tras
## quando o mapa mudou. Nao da erro nenhum: o jogador so aparece no lugar
## errado.
##
## **O cenario posiciona ele por aqui**, e nao o rua.tscn.
static func onde_o_jogador_nasce() -> Vector2:
	var casa := Lugares.sua_casa()
	# `normal_de`, e nao um sinal em y (17/09/2026): a porta em 4 direcoes
	# manda a direcao "para fora" certa, seja a fachada norte, sul, leste ou
	# oeste.
	return onde_fica_a_porta_de_casa() + Construcao.normal_de(casa) * RECUO_DO_NASCIMENTO

## A porta de casa, que e por onde o dia acaba.
##
## **E a porta da fachada, e nao uma posicao escrita a mao** (15/09/2026). Ate
## entao ela ficava num quarto do fundo: voce voltava da rua, atravessava a
## sala e o corredor e so entao acabava o dia. Chegar em casa e o momento de
## alivio do ciclo, e cobrar uma travessia de comodo depois dele so adiava o
## alivio - com zumbi atras, adiava dentro de casa.
##
## Sai do proprio predio, pelo mesmo `porta_de()` que abre o vao na fachada de
## qualquer construcao do mapa. Se a sua casa mudar de lugar ou de tamanho, a
## porta vai junto e ninguem precisa lembrar de mexer aqui.
##
## Sem soma de origem (17/09/2026, P9): `Lugares.sua_casa()` ja nasce em
## coordenada de MUNDO, porque o bairro inteiro passou a nascer assim.
static func onde_fica_a_porta_de_casa() -> Vector2:
	return Construcao.porta_de(Lugares.sua_casa())

## Para que lado a porta da sua casa olha - "norte", "sul", "leste" ou
## "oeste". E o que `rua/entrada_de_casa.gd` usa para saber se o vao dela e
## deitado ou em pe.
static func lado_da_porta_de_casa() -> String:
	return Lugares.sua_casa()["porta"]
