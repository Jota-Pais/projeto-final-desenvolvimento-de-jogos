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

## Onde o jogador nasce e onde fica a porta do porao, em coordenada LOCAL do
## bairro. Sao a sala e o quarto do fundo da sua casa.
##
## **Estavam escritas na mao no rua.tscn** ate 09/09/2026 a noite, e quando o
## bairro mudou de lugar no mapa o jogador passou a nascer no meio do campo, a
## 89 m da propria casa. Nao dava erro nenhum: ele so aparecia no lugar errado.
## Agora saem daqui, somadas a origem do bairro.
const BAIRRO_JOGADOR := Vector2(700.0, 1240.0)
const BAIRRO_PORTA_DO_PORAO := Vector2(390.0, 905.0)

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
		"lavoura": [],
	}
	match lugar["tipo"]:
		"bairro": _bairro(lugar, pecas)
		"cidade": _cidade(lugar, pecas)
		"posto": _posto(lugar, pecas)
		"mansao": _mansao(lugar, pecas)
		"sitio": _sitio(lugar, pecas)
		"lavoura": _lavoura(lugar, pecas)
		"floresta": _floresta(lugar, pecas)
	return pecas

# ---------------------------------------------------------------- a cidade
#
# **O nucleo denso, e o que faltava no mapa.** Antes o mundo era um punhado de
# lugares isolados pendurados na rodovia, com campo vazio no meio - e campo vazio
# nao e mapa, e caminhada. Rosewood, no PZ, e o contrario: dezenas de predios
# pequenos numa grade de ruas, encostados na calcada, e o campo em volta.
#
# A grade sai destas constantes, e nao de retangulo escrito a mao: acrescentar
# uma coluna de quadra e mudar um numero, e todo predio nasce virado para a rua
# certa com recuo de calcada.

## Largura de rua da cidade: 10 m. Bate com a rodovia de proposito, porque a rua
## do meio da grade **e** a rodovia.
const CIDADE_RUA := 400.0
## A altura de uma quadra: 60 m. A largura varia por coluna - ver
## CIDADE_LARGURAS.
const CIDADE_QUADRA := Vector2(2600.0, 2400.0)

## A largura de cada coluna de quadra. **Nao sao iguais de proposito:** grade
## com quadra do mesmo tamanho em toda parte le como planilha, e nao como
## cidade. Rosewood tem quadra curta no centro e comprida na borda, e o numero
## de lotes por quadra sai da largura dela.
const CIDADE_LARGURAS := [2600.0, 3400.0, 2200.0, 3000.0]
const CIDADE_LINHAS := 2
## O passo entre uma vaga de lote e a seguinte. Com predio de 520 e passo de 800
## sobram 7 m entre um lote e outro, que e o que faz parecer lote. Quantas vagas
## cabem sai da largura da quadra.
const CIDADE_PASSO := 800.0
## Recuo da rua ate a fachada. E o que sobra de quintal na frente.
const CIDADE_RECUO := 220.0

## Os predios que nao sao casa nem loja, na chave `x da quadra, linha, fileira,
## vaga`.
##
## A chave usa o **x da quadra** e nao o indice da coluna porque as quadras tem
## larguras diferentes: com indice, mexer numa largura movia o predio especial
## para outra quadra sem avisar.
##
## A delegacia e o mercado moram **dentro da cidade**, e nao soltos no campo:
## era o que a referencia mostrava e o que o mapa nao tinha. A delegacia fica na
## quadra mais larga, virada para a rodovia; o mercado na fileira comercial da
## quadra seguinte. Os dois sao mais largos que uma vaga e comem a seguinte.
const CIDADE_ESPECIAIS := {
	"14600,1,0,0": "delegacia",
	"18400,0,1,0": "mercado",
}

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
		pecas["bosques"].append({
			"rect": Rect2((bosque as Rect2).position + origem, (bosque as Rect2).size),
			"densidade": 0.35,
		})
	for movel in BAIRRO_MOVEIS_DE_RUA:
		pecas["moveis_de_rua"].append({ "tipo": movel["tipo"], "pos": movel["pos"] + origem })
	for onde in BAIRRO_ZUMBIS:
		pecas["zumbis"].append(onde + origem)

	# A rua principal do bairro E a rodovia; so a transversal e rua de bairro.
	pecas["ruas"].append(Rect2(BAIRRO_RUA_TRANSVERSAL.position + origem,
		BAIRRO_RUA_TRANSVERSAL.size))

# --- a cidade ---------------------------------------------------------------

## A grade de ruas e as quadras, com predio virado para a rua em cada vaga.
##
## A regra que da o desenho de rua principal do PZ e uma so: **a fileira que da
## na rodovia e comercio, o resto e casa.** Nao e lista - e regra, entao ela
## continua valendo se a cidade crescer.
static func _cidade(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]

	# As ruas verticais: uma a mais que o numero de quadras, porque ha rua nas
	# duas bordas tambem. A posicao de cada uma sai da soma das larguras a
	# esquerda dela - e por isso que quadra de largura diferente nao quebra nada.
	var x := r.position.x
	for coluna in CIDADE_LARGURAS.size() + 1:
		pecas["ruas"].append(Rect2(x, r.position.y, CIDADE_RUA, r.size.y))
		if coluna < CIDADE_LARGURAS.size():
			x += CIDADE_RUA + CIDADE_LARGURAS[coluna]

	for linha in CIDADE_LINHAS + 1:
		pecas["ruas"].append(Rect2(
			r.position.x, r.position.y + float(linha) * (CIDADE_QUADRA.y + CIDADE_RUA),
			r.size.x, CIDADE_RUA))

	x = r.position.x + CIDADE_RUA
	for coluna in CIDADE_LARGURAS.size():
		var largura: float = CIDADE_LARGURAS[coluna]
		for linha in CIDADE_LINHAS:
			_uma_quadra(r, x, largura, linha, pecas)
		# Zumbi na rua, nas esquinas de cima e de baixo da quadra.
		pecas["zumbis"].append(Vector2(x + largura * 0.5, r.position.y + CIDADE_RUA * 0.5))
		pecas["zumbis"].append(Vector2(x + largura * 0.5, r.end.y - CIDADE_RUA * 0.5))
		x += largura + CIDADE_RUA

## Uma quadra: duas fileiras de lote, uma virada para a rua de cima e outra para
## a de baixo, com o quintal se encontrando no meio.
##
## **Quantos lotes cabem sai da largura da quadra**, e nao de uma constante: a
## quadra de 3.400 tem quatro e a de 2.200 tem tres. E o que faz a grade nao
## parecer planilha.
static func _uma_quadra(cidade: Rect2, esquerda: float, largura: float,
		linha: int, pecas: Dictionary) -> void:
	var canto := Vector2(esquerda,
		cidade.position.y + CIDADE_RUA + float(linha) * (CIDADE_QUADRA.y + CIDADE_RUA))
	var casa: Vector2 = Construcao.TAMANHOS["casa"]
	var vagas := maxi(1, int(floor((largura - casa.x) / CIDADE_PASSO)) + 1)

	# Qual fileira da na rodovia: a de baixo da primeira linha de quadras, e a
	# de cima da segunda. E nelas que fica o comercio.
	var fileira_da_rodovia := 1 if linha == 0 else 0

	var vaga := 0
	while vaga < vagas:
		for fileira in 2:
			var chave := "%d,%d,%d,%d" % [int(esquerda), linha, fileira, vaga]
			var tipo: String = CIDADE_ESPECIAIS.get(chave,
				"comercio" if fileira == fileira_da_rodovia else "casa")
			var tamanho: Vector2 = Construcao.TAMANHOS[tipo]

			var margem := (largura - float(vagas - 1) * CIDADE_PASSO - casa.x) * 0.5
			var px := canto.x + margem + float(vaga) * CIDADE_PASSO
			var py := canto.y + CIDADE_RECUO
			if fileira == 1:
				py = canto.y + CIDADE_QUADRA.y - CIDADE_RECUO - tamanho.y

			var predio := {
				"rect": Rect2(px, py, tamanho.x, tamanho.y),
				"porta": "norte" if fileira == 0 else "sul",
				"tipo": tipo,
			}
			# Ha uma delegacia e um mercado so na cidade, e cada um guarda um
			# documento no quarto mais fundo. A pistola fica na armaria, que e o
			# quarto mais fundo da delegacia.
			if tipo == "delegacia":
				predio["documento"] = true
				predio["arma"] = true
			elif tipo == "mercado":
				predio["documento"] = true
			pecas["construcoes"].append(predio)
			_o_que_vem_com_o_predio(predio, pecas)

		# Predio mais largo que uma vaga come a vaga seguinte.
		var mais_largo := 1
		for fileira in 2:
			var chave := "%d,%d,%d,%d" % [int(esquerda), linha, fileira, vaga]
			if CIDADE_ESPECIAIS.has(chave):
				var tamanho: Vector2 = Construcao.TAMANHOS[CIDADE_ESPECIAIS[chave]]
				mais_largo = maxi(mais_largo, int(ceil(tamanho.x / CIDADE_PASSO)))
		vaga += mais_largo

	pecas["zumbis"].append(canto + Vector2(largura, CIDADE_QUADRA.y) * 0.5)



## O que cada tipo de predio traz junto: patio, carro na frente, lata na
## calcada. E o que separa "predio numa grade" de lugar.
static func _o_que_vem_com_o_predio(predio: Dictionary, pecas: Dictionary) -> void:
	var tipo: String = predio["tipo"]
	var onde: Rect2 = predio["rect"]
	# O centro do predio NAO serve para pôr zumbi: num predio de tres quartos a
	# divisoria interna passa quase no meio, e o zumbi nascia dentro da parede.
	# O centro da sala serve. O conferir_zumbi pegou.
	var sala: Vector2 = Construcao.quartos_de(predio)[0].get_center()
	match tipo:
		"delegacia":
			# Patio de concreto entre a fachada e a rua, com viatura.
			pecas["piso"].append(Rect2(onde.position.x - 80.0, onde.end.y,
				onde.size.x + 160.0, CIDADE_RECUO))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Vector2(onde.get_center().x - 300.0, onde.end.y + 110.0),
			})
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Vector2(onde.get_center().x + 300.0, onde.end.y + 110.0),
			})
			pecas["zumbis"].append(sala)
			pecas["zumbis"].append(Vector2(onde.get_center().x, onde.end.y + 120.0))
		"mercado":
			pecas["piso"].append(Rect2(onde.position.x - 100.0,
				onde.position.y - CIDADE_RECUO, onde.size.x + 200.0, CIDADE_RECUO))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Vector2(onde.get_center().x - 420.0,
					onde.position.y - 110.0),
			})
			pecas["zumbis"].append(sala)
		"comercio":
			pecas["moveis_de_rua"].append({
				"tipo": "lata", "pos": Vector2(onde.position.x - 90.0, onde.get_center().y),
			})

# --- o sitio ----------------------------------------------------------------

## Casa de campo com galpao, na beira de uma estrada de terra.
##
## Existe para o entorno da cidade ter algo. Uma casa sozinha no meio do campo e
## uma decisao de verdade - vale a caminhada de 200 m por tres gavetas? - e e
## isso que o PZ tem espalhado por toda a volta de Rosewood.
static func _sitio(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]
	var casa: Vector2 = Construcao.TAMANHOS["casa"]
	var galpao: Vector2 = Construcao.TAMANHOS["galpao"]

	# A casa virada para a estrada, que vem de baixo.
	pecas["construcoes"].append({
		"rect": Rect2(r.position.x + 200.0, r.position.y + 300.0, casa.x, casa.y),
		"porta": "sul", "tipo": "casa",
	})
	# O galpao no fundo do terreno, virado para a casa.
	pecas["construcoes"].append({
		"rect": Rect2(r.end.x - galpao.x - 300.0, r.position.y + 260.0, galpao.x, galpao.y),
		"porta": "sul", "tipo": "galpao",
	})

	# Cerca de frente com o vao onde a estrada entra.
	var vao := 400.0
	var entrada := r.position.x + 480.0
	pecas["cercas"].append(Rect2(r.position.x, r.end.y - 16.0,
		entrada - vao * 0.5 - r.position.x, 16.0))
	pecas["cercas"].append(Rect2(entrada + vao * 0.5, r.end.y - 16.0,
		r.end.x - entrada - vao * 0.5, 16.0))

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(r.position.x + 340.0, r.end.y - 300.0),
	})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(r.end.x - 220.0, r.end.y - 260.0),
	})
	pecas["zumbis"].append(Vector2(r.get_center().x, r.end.y - 500.0))

# --- a lavoura --------------------------------------------------------------

## Terra arada, em talhoes. Nao tem loot e nao tem colisao: e chao pintado.
##
## Existe porque o campo em volta da cidade precisava parecer campo de alguem,
## e nao grama infinita - no PZ os talhoes marrons ao sul da cidade sao metade
## do que faz o mapa parecer um lugar habitado antes do apocalipse.
static func _lavoura(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = lugar["rect"]
	var colunas := 3
	var linhas := 2
	var carreador := 240.0
	var talhao := Vector2(
		(r.size.x - carreador * float(colunas + 1)) / float(colunas),
		(r.size.y - carreador * float(linhas + 1)) / float(linhas))

	for coluna in colunas:
		for linha in linhas:
			pecas["lavoura"].append(Rect2(
				r.position.x + carreador + float(coluna) * (talhao.x + carreador),
				r.position.y + carreador + float(linha) * (talhao.y + carreador),
				talhao.x, talhao.y))

	# Um galpao de fazenda no canto, que e o unico loot daqui.
	var galpao := Construcao.TAMANHOS["galpao"]
	pecas["construcoes"].append({
		"rect": Rect2(r.end.x - galpao.x - 300.0, r.position.y + 300.0, galpao.x, galpao.y),
		"porta": "norte", "tipo": "galpao",
	})
	pecas["zumbis"].append(r.get_center())

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

	# A loja no fundo, virada para a rodovia. 18 x 12 m - tamanho de loja de
	# conveniencia, e nao os 22 x 14 escritos na mao que tinha antes.
	var tamanho: Vector2 = Construcao.TAMANHOS["posto"]
	var loja := Rect2(r.end.x - tamanho.x - 260.0, r.end.y - tamanho.y - 120.0,
		tamanho.x, tamanho.y)
	pecas["construcoes"].append({
		"rect": loja, "porta": "norte", "tipo": "posto", "documento": true,
	})

	# Duas bombas em ilha, entre a rodovia e a loja. A pista aberta e o oposto de
	# uma casa: nao ha onde se esconder, e voce ve o zumbi vindo de longe.
	for i in 2:
		pecas["moveis_de_rua"].append({
			"tipo": "bomba",
			"pos": Vector2(r.position.x + 420.0 + float(i) * 460.0, r.position.y + 380.0),
		})

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(r.position.x + 300.0, r.end.y - 260.0),
	})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(loja.position.x - 120.0, loja.position.y + 90.0),
	})

	pecas["zumbis"].append(Vector2(r.position.x + 700.0, r.position.y + 700.0))
	pecas["zumbis"].append(loja.get_center())

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

	# A casa no fundo do terreno, virada para o portao. 22 x 16 m - casa grande
	# de verdade, e nao os 85 x 60 m escritos na mao que tinha antes, que eram
	# um quarteirao.
	var tamanho: Vector2 = Construcao.TAMANHOS["mansao"]
	var casa := Rect2(portao_x - tamanho.x * 0.5, r.position.y + 700.0,
		tamanho.x, tamanho.y)
	pecas["construcoes"].append({
		"rect": casa, "porta": "sul", "tipo": "mansao", "documento": true,
	})

	# Garagem separada, do lado.
	var garagem: Vector2 = Construcao.TAMANHOS["garagem"]
	pecas["construcoes"].append({
		"rect": Rect2(casa.end.x + 500.0, casa.position.y + 200.0, garagem.x, garagem.y),
		"porta": "sul", "tipo": "garagem",
	})

	# Alameda de concreto do portao ate a porta da casa.
	pecas["piso"].append(Rect2(portao_x - 200.0, casa.end.y, 400.0, r.end.y - casa.end.y))

	# Jardim abandonado: mata fechada, que e o que faz o terreno parecer largado
	# e nao apenas vazio.
	pecas["bosques"].append({
		"rect": Rect2(r.position.x + muro, r.position.y + muro,
			r.size.x * 0.22, r.size.y - muro * 2.0),
		"densidade": 0.8,
	})
	pecas["bosques"].append({
		"rect": Rect2(r.end.x - r.size.x * 0.22 - muro, r.position.y + muro,
			r.size.x * 0.22, r.size.y - muro * 2.0),
		"densidade": 0.8,
	})

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(portao_x + 620.0, r.end.y - 420.0),
	})
	pecas["zumbis"].append(Vector2(portao_x, r.end.y - 600.0))
	pecas["zumbis"].append(casa.get_center())
	pecas["zumbis"].append(Vector2(casa.position.x - 500.0, casa.end.y + 400.0))

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
