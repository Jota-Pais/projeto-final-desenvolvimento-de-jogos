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
const Vias := preload("res://rua/vias.gd")
const Quadras := preload("res://rua/quadras.gd")

# ---------------------------------------------------------------- o bairro
#
# Layout tunado a mao entre 07 e 08/09/2026, com o conferir_bairro achando
# 38 moveis inalcancaveis na primeira rodada. **Nao foi reescrito para o mapa
# grande**: e o mesmo bairro, deslocado inteiro para o lugar dele. Numero
# tunado que se reescreve e numero que se re-erra.
#
# Sao coordenadas LOCAIS - o mapa soma a origem do lugar.

## O bairro cresceu para o sul em 16/09/2026, de 3.600 para 6.800 (90 m para
## 170 m). Ele era uma fita de casas dos dois lados da rodovia, e o mapa inteiro
## se passava nela; agora e um **loteamento**, com rede de ruas propria. O espaco
## saiu do vazio que havia ao sul, que nao servia para nada.
const BAIRRO_TAMANHO := Vector2(5760.0, 6800.0)

# **Nem a porta de casa nem o nascimento do jogador tem constante aqui.** Os
# dois ja tiveram: a porta era a BAIRRO_PORTA_DO_PORAO, escrita a mao dentro de
# um quarto do fundo, e o jogador era a BAIRRO_JOGADOR, escrita a mao na sala.
# Cada vez que o mapa mudou, as duas ficaram para tras sem dar erro nenhum -
# so apareciam no lugar errado.
#
# Agora os dois saem da propria construcao marcada como "sua": ver sua_casa()
# abaixo, Mapa.onde_fica_a_porta_de_casa() e Mapa.onde_o_jogador_nasce().

## A rede do loteamento (17/09/2026, P7 - arquitetura nova). Substitui as seis
## de 16/09 (rua oeste/meio/leste + rua do fundo + saida sul + retorno): eram
## um quarteirao fechado que nascia por cima da rodovia; agora o bairro fica
## 100% ao sul dela, e a rede e a do PZ de verdade - rua principal com
## calcada e comercio de esquina, laco de um lado, rua de baixo com um
## retorno em U do outro, um beco de servico no meio, e uma segunda estrada
## saindo para a cidade (a "Estrada Velha") que nao passa pela rodovia.
##
## Coordenadas em MUNDO, nao mais locais: como o bairro tem posicao fixa
## agora (ao contrario do design antigo, pensado para "boiar" em qualquer
## `origem`), escrever direto evita a volta de traduzir e destraduzir.
## `_bairro()` NAO desloca isto por `origem` - so as construcoes/cercas/
## bosques antigos continuam precisando disso.
##
## As construcoes de `BAIRRO_CONSTRUCOES` continuam nascendo no lugar velho
## (dentro do retangulo do lugar, que so moveu de posicao) - **de proposito**:
## reescrever onde a casa fica e trabalho de P8/P9, sobre esta rede. Ate la,
## a rua bate certo e a casa nao - e o esperado, nao um bug.
static func _bairro_rede() -> Array[Dictionary]:
	var fora: Array[Dictionary] = []

	# A espinha do bairro: sai da rodovia (y 10520) e desce ate a Rua de
	# Baixo. O T com a Rua do Bairro (y 13800) e por sobreposicao - nasce sem
	# precisar declarar dois segmentos.
	fora.append({ "nome": "estrada do bairro", "classe": "residencial", "lugar": "bairro",
		"eixo": [Vector2(7000.0, 10520.0), Vector2(7000.0, 15600.0)],
		"pontas": ["emenda:rodovia", "T:rua de baixo"] })

	# A Rua do Bairro: a UNICA do loteamento com calcada - ela carrega o
	# comercio de esquina, e no PZ e assim que se decide qual rua de bairro
	# merece passeio. Termina a oeste no Laco do Poente.
	fora.append({ "nome": "rua do bairro", "classe": "principal", "lugar": "bairro",
		"eixo": [Vector2(5210.0, 13800.0), Vector2(7000.0, 13800.0)], "calcada": "norte",
		"pontas": ["laco:laco do poente", "T:estrada do bairro"] })
	fora.append_array(Vias.laco(Vector2(4700.0, 13800.0), Vector2(700.0, 900.0), 320.0,
		"laco do poente"))

	# Rua de Baixo, com o retorno em U na ponta oeste - o cul-de-sac que o PZ
	# usa (nunca bulbo asfaltado solto). Vai ate x=9800, nao 8600 (17/09/2026,
	# P9): QB-leste precisa da faixa dela para ter lote - encurtada em 8600,
	# a quadra a leste do Beco dos Fundos nao tinha via suficiente para nem
	# um lote (achado rodando o conferir_mapa: "QB-leste: 0 lotes").
	fora.append({ "nome": "rua de baixo", "classe": "residencial", "lugar": "bairro",
		"eixo": [Vector2(5600.0, 15600.0), Vector2(9800.0, 15600.0)],
		"pontas": ["u:retorno de baixo", "emenda:estrada velha"] })
	fora.append_array(Vias.u(fora[-1], Vector2(5600.0, 15600.0), Vector2(6400.0, 15600.0),
		Vector2(0.0, 16800.0), "retorno de baixo"))

	# Beco dos Fundos: o corte de servico entre a Rua do Bairro e a Rua de
	# Baixo - onde ficam as lixeiras, e o que quebra a leitura de quarteirao
	# macico.
	fora.append({ "nome": "beco dos fundos", "classe": "beco", "lugar": "bairro",
		"eixo": [Vector2(7900.0, 13800.0), Vector2(7900.0, 15600.0)],
		"pontas": ["T:rua do bairro", "T:rua de baixo"] })

	# A Estrada Velha: a SEGUNDA rota ate a cidade, que nao usa a rodovia -
	# critério F. Sobe e encontra a Rua do Correio da cidade exatamente no
	# mesmo ponto (13000, 10520), dentro da propria rodovia.
	fora.append({ "nome": "estrada velha", "classe": "residencial", "lugar": "bairro",
		"eixo": [Vector2(9800.0, 15600.0), Vector2(13000.0, 15600.0)],
		"pontas": ["emenda:rua de baixo", "emenda:estrada velha (subida)"] })
	fora.append({ "nome": "estrada velha (subida)", "classe": "residencial", "lugar": "bairro",
		"eixo": [Vector2(13000.0, 15600.0), Vector2(13000.0, 10520.0)],
		"pontas": ["emenda:estrada velha", "emenda:rodovia"] })

	return fora

## As construcoes do bairro, **uma fileira por rua**.
##
## Duas coisas mudaram em 16/09/2026, e sao as duas queixas de olhar o mapa:
##
##  - **nenhuma casa tem a planta da vizinha.** Eram treze predios de 650 x 520,
##    um atras do outro. Agora cada lote tem a sua medida, e a **fachada nao fica
##    na regua**: dentro da mesma fileira o recuo da rua varia de 60 em 60, que
##    e o que faz o olho ver casas e nao um pente;
##  - **elas nao olham todas para a mesma rua.** Antes o bairro era uma fita: seis
##    casas de um lado da rodovia e quatro do outro, e acabou. Agora sao quatro
##    fileiras, cada uma virada para uma via diferente da rede, mais tres em
##    volta do retorno.
##
## As bandas de x existem porque as tres verticais cortam o lote: 760-1160,
## 2680-3080 e 4600-5000 sao rua, e predio nenhum entra nelas.
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
		"vias": [],
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

## Recuo generico da rua ate a fachada, para o patio/estacionamento de um
## predio publico (ver `_o_que_vem_com_o_predio`).
const CIDADE_RECUO := 220.0

## A sua casa: a unica construcao do bairro marcada com "sua" - em
## coordenada de MUNDO (17/09/2026, P9: o bairro deixou de ser gerado em
## coordenada local e ja nasce direto no lugar certo). E a unica que nao se
## vasculha, e e a fachada dela que tem a porta por onde o dia acaba.
## Preenchida por `_bairro()`, que roda antes de qualquer coisa perguntar.
static var _sua_casa_cache: Dictionary = {}

static func sua_casa() -> Dictionary:
	return _sua_casa_cache

# --- o bairro residencial ---------------------------------------------------

## As quadras do bairro (17/09/2026, P9 - arquitetura nova), em cima de
## `_bairro_rede()`. Substitui o loteamento de 16/09/2026
## (`BAIRRO_CONSTRUCOES`/`BAIRRO_CERCAS`/`BAIRRO_MOVEIS_DE_RUA`/
## `BAIRRO_ZUMBIS`/`BAIRRO_BOSQUES`, tudo removido) - quatro quadras, cada
## uma sabendo so quais vias a limitam.
static func _quadras_do_bairro() -> Array[Dictionary]:
	return [
		# Ao norte da Rua do Bairro - a UNICA via do loteamento com calcada,
		# entao e aqui que fica o comercio de esquina, exatamente como no PZ
		# (a rua com passeio e a que carrega a loja).
		{ "id": "QB-norte", "lugar": "bairro", "uso": "casa",
			"entre": { "sul": "rua do bairro", "leste": "estrada do bairro",
				"oeste": "laco do poente leste" },
			"fundo": { "norte": 1100.0 }, "frentes": ["sul"], "passo": 850.0 },
		# Entre a Rua do Bairro e a Rua de Baixo, a oeste da Estrada do
		# Bairro. SO fileira norte (17/09/2026, P9 - achado gerando a
		# primeira leva: as duas fileiras "costas com costas" dividiam a
		# profundidade ao meio - 740 px -, curta demais para QUALQUER planta
		# de casa (a mais rasa precisa de pelo menos 880 com recuo minimo).
		# Uma fileira so, com a profundidade INTEIRA (1480), sobra quintal
		# em vez de faltar parede.
		{ "id": "QB-meio", "lugar": "bairro", "uso": "casa",
			"entre": { "norte": "rua do bairro", "sul": "rua de baixo",
				"leste": "estrada do bairro" },
			"fundo": { "oeste": 1600.0 }, "frentes": ["norte"], "passo": 800.0 },
		# Ao sul da Rua de Baixo, a oeste da Estrada do Bairro. Fundo 1200,
		# nao 1000 (17/09/2026, P9): 1000 deixava a planta mais funda sem
		# folga (recuo minimo 240 + planta funda 640 + quintal 160 = 1040 >
		# 1000) - o lote nascia e o predio era descartado.
		{ "id": "QB-baixo", "lugar": "bairro", "uso": "casa",
			"entre": { "norte": "rua de baixo", "leste": "estrada do bairro" },
			"fundo": { "sul": 1200.0, "oeste": 1600.0 },
			"frentes": ["norte"], "passo": 800.0 },
		# A leste do Beco dos Fundos, virada para a Rua de Baixo (que agora
		# chega ate aqui - ver a rede acima). Fundo 1600, nao 700
		# (17/09/2026, P9): 700 nao cabia nem UM lote de passo 800.
		{ "id": "QB-leste", "lugar": "bairro", "uso": "casa",
			"entre": { "sul": "rua de baixo", "oeste": "beco dos fundos" },
			"fundo": { "norte": 1600.0, "leste": 1600.0 },
			"frentes": ["sul"], "passo": 800.0 },
	]

## O bairro (17/09/2026, P9 - arquitetura nova): quadra -> lote -> predio,
## sobre `rua/quadras.gd` e a rede de `_bairro_rede`. A sua casa mora em
## QB-meio, virada para a Rua do Bairro (porta norte) - a primeira rua que
## se ve saindo da porta.
static func _bairro(lugar: Dictionary, pecas: Dictionary) -> void:
	pecas["vias"].append_array(_bairro_rede())

	var vias := {}
	for via in pecas["vias"]:
		vias[via["nome"]] = via

	for quadra in _quadras_do_bairro():
		match quadra["id"]:
			"QB-norte":
				# O comercio de esquina, no primeiro lote perto do laco -
				# o documento 2. Documento 1 fica com uma casa qualquer,
				# em QB-meio.
				_construir_quadra(quadra, vias, pecas, "casa", {
					"sul:0": { "tipo": "comercio", "extras": { "documento": 2 } },
				})
			"QB-meio":
				# "norte:1", nao "norte:0" (17/09/2026, P9 - achado rodando o
				# conferir_mapa): o lote 0 nasce raso demais em largura para
				# qualquer planta de casa caber (achado real do ruido de
				# +-22% do passo, nao falta de sorte) - marcar ele de "sua"
				# descartava a casa inteira em silencio. O 1 sempre cabe.
				_construir_quadra(quadra, vias, pecas, "casa", {
					"norte:1": { "tipo": "casa", "extras": { "sua": true } },
				})
			"QB-leste":
				_construir_quadra(quadra, vias, pecas, "casa", {
					"sul:0": { "tipo": "casa", "extras": { "documento": 1 } },
				})
			_:
				_construir_quadra(quadra, vias, pecas, "casa")

	for construcao in pecas["construcoes"]:
		if (construcao as Dictionary).get("sua", false):
			_sua_casa_cache = construcao
			break

	# Bosque nos dois cantos que sobraram sem lote - o mesmo canto que tinha
	# mato antes de 17/09, so que agora nos limites da rede nova.
	var r: Rect2 = lugar["rect"]
	pecas["bosques"].append({ "rect": Rect2(r.position.x, r.end.y - 900.0, 1400.0, 900.0),
		"densidade": 0.35 })
	pecas["bosques"].append({ "rect": Rect2(r.end.x - 1300.0, r.end.y - 900.0, 1300.0, 900.0),
		"densidade": 0.35 })

	# Um carro e uma lata espalhados pela rede, para a rua nao ficar vazia
	# de movel de rua - os predios ja trazem carro proprio (ver
	# `_o_que_vem_com_o_predio` nao chama para "casa", entao isto e o unico
	# movel de rua do bairro).
	pecas["moveis_de_rua"].append({ "tipo": "carro", "pos": Vector2(6700.0, 13500.0) })
	pecas["moveis_de_rua"].append({ "tipo": "carro", "pos": Vector2(6300.0, 16100.0) })
	pecas["moveis_de_rua"].append({ "tipo": "lata", "pos": Vector2(7900.0, 14700.0) })

	pecas["zumbis"].append(Vector2(7000.0, 13800.0))
	pecas["zumbis"].append(Vector2(6000.0, 15600.0))

# --- a cidade ---------------------------------------------------------------

## A grade de ruas e as quadras, com predio virado para a rua em cada vaga.
##
## A regra que da o desenho de rua principal do PZ e uma so: **a fileira que da
## na rodovia e comercio, o resto e casa.** Nao e lista - e regra, entao ela
## continua valendo se a cidade crescer.
## A rede da cidade (17/09/2026, P7 - arquitetura nova): a Avenida Central,
## a espinha comercial com um cotovelo no meio (estreita depois do trecho de
## loja, como a Main de Rosewood faz), quatro verticais residenciais descendo
## ate a rodovia (a que fica em x=13000 e a mesma "Rua do Correio" que a
## Estrada Velha do bairro encontra - a segunda rota), uma rua transversal
## mais ao norte terminando num laco, um beco de servico atras da fita
## comercial, e um laco em cada ponta solta da avenida.
##
## Coordenadas em MUNDO. As construcoes ainda nao usam esta rede - continuam
## nascendo pela grade antiga (`_uma_quadra`), e por isso o layout vai
## parecer errado ate P8/P9: e o esperado neste passo (P7 e so o esqueleto).
static func _cidade_rede() -> Array[Dictionary]:
	var fora: Array[Dictionary] = []

	# A espinha: comercial ate o cotovelo em x=19600, principal dali para
	# leste - mais estreita, como a Main de Rosewood faz depois do comercio.
	fora.append({ "nome": "avenida central (oeste)", "classe": "comercial", "lugar": "cidade",
		"eixo": [Vector2(11710.0, 6900.0), Vector2(19600.0, 6900.0)], "calcada": "sul",
		"pontas": ["laco:laco do oeste", "emenda:avenida central (cotovelo)"] })
	fora.append({ "nome": "avenida central (cotovelo)", "classe": "principal", "lugar": "cidade",
		"eixo": [Vector2(19600.0, 6900.0), Vector2(19600.0, 7200.0)],
		"pontas": ["emenda:avenida central (oeste)", "emenda:avenida central (leste)"] })
	fora.append({ "nome": "avenida central (leste)", "classe": "principal", "lugar": "cidade",
		"eixo": [Vector2(19600.0, 7200.0), Vector2(24000.0, 7200.0)], "calcada": "sul",
		"pontas": ["emenda:avenida central (cotovelo)", "laco:laco leste"] })
	fora.append_array(Vias.laco(Vector2(11200.0, 6900.0), Vector2(700.0, 900.0), 320.0,
		"laco do oeste"))
	fora.append_array(Vias.laco(Vector2(24460.0, 7200.0), Vector2(600.0, 800.0), 320.0,
		"laco leste"))

	# Quatro verticais descendo da avenida ate a rodovia - Rua do Correio e
	# a que a Estrada Velha do bairro encontra em (13000, 10520), a segunda
	# rota da critério F. Rua da Delegacia sobe mais, ate o Laco do Norte.
	fora.append({ "nome": "rua do poente", "classe": "residencial", "lugar": "cidade",
		"eixo": [Vector2(12800.0, 6900.0), Vector2(12800.0, 10520.0)],
		"pontas": ["T:avenida central (oeste)", "emenda:rodovia"] })
	fora.append({ "nome": "rua do correio", "classe": "residencial", "lugar": "cidade",
		"eixo": [Vector2(13000.0, 4500.0), Vector2(13000.0, 10520.0)],
		"pontas": ["T:rua do norte", "emenda:estrada velha (subida)/rodovia"] })
	fora.append({ "nome": "rua do mercado", "classe": "residencial", "lugar": "cidade",
		"eixo": [Vector2(17000.0, 6900.0), Vector2(17000.0, 10520.0)],
		"pontas": ["T:avenida central (oeste)", "emenda:rodovia"] })
	fora.append({ "nome": "rua da delegacia", "classe": "residencial", "lugar": "cidade",
		"eixo": [Vector2(21000.0, 4110.0), Vector2(21000.0, 10520.0)],
		"pontas": ["laco:laco do norte", "emenda:rodovia"] })

	fora.append({ "nome": "rua do norte", "classe": "residencial", "lugar": "cidade",
		"eixo": [Vector2(13000.0, 4500.0), Vector2(21000.0, 4500.0)],
		"pontas": ["emenda:rua do correio", "T:rua da delegacia"] })
	fora.append_array(Vias.laco(Vector2(21000.0, 3500.0), Vector2(700.0, 900.0), 320.0,
		"laco do norte"))

	# O beco atras da fita comercial - onde ficam as lixeiras das lojas.
	fora.append({ "nome": "beco do mercado", "classe": "beco", "lugar": "cidade",
		"eixo": [Vector2(12800.0, 8000.0), Vector2(17000.0, 8000.0)],
		"pontas": ["T:rua do poente", "T:rua do mercado"] })

	return fora

## As quadras da cidade (17/09/2026, P8 - arquitetura nova): quadra -> lote
## -> predio, em cima de `rua/quadras.gd` e da rede de `_cidade_rede`. Cada
## quadra declara so quais vias a limitam - o retangulo dela e CALCULADO
## (`Quadras.rect_da_quadra`), nunca escrito a mao.
##
## Substitui a grade uniforme de 16/09/2026 (`CIDADE_LARGURAS`/`CIDADE_QUADRA`/
## `CIDADE_ESPECIAIS`): a fita comercial ao norte da Avenida (armazem numa
## ponta, mercado no meio, mais loja do outro lado da Rua da Delegacia) e o
## residencial ao sul dela, virado para a mesma Avenida.
static func _quadras_da_cidade() -> Array[Dictionary]:
	return [
		{ "id": "QC-fita-oeste", "lugar": "cidade", "uso": "comercio",
			"entre": { "sul": "avenida central (oeste)", "leste": "rua do poente" },
			"fundo": { "norte": 1200.0, "oeste": 1100.0 },
			"frentes": ["sul"], "passo": 1000.0 },
		{ "id": "QC-fita-centro", "lugar": "cidade", "uso": "comercio",
			"entre": { "sul": "avenida central (oeste)", "oeste": "rua do correio" },
			"fundo": { "norte": 1200.0, "leste": 6300.0 },
			"frentes": ["sul"], "passo": 1050.0 },
		{ "id": "QC-fita-leste", "lugar": "cidade", "uso": "comercio",
			"entre": { "sul": "avenida central (leste)", "oeste": "rua da delegacia" },
			"fundo": { "norte": 1200.0, "leste": 2700.0 },
			"frentes": ["sul"], "passo": 1000.0 },
		# Ao sul, quatro quadras - nao tres: sem parar em CADA vertical (Poente,
		# Correio, Mercado, Delegacia), a que ficasse "por baixo" de uma
		# vertical do meio pisaria nela sem ninguem perceber (achado rodando
		# o conferir_mapa: "casa pisa na via 'rua do mercado'"). Rasa (900,
		# nao 1000): funda demais e a quadra descia ate a linha do Beco do
		# Mercado (y 8000) e pisava nele tambem.
		{ "id": "QC-sul-oeste", "lugar": "cidade", "uso": "casa",
			"entre": { "norte": "avenida central (oeste)", "leste": "rua do poente" },
			"fundo": { "sul": 900.0, "oeste": 1100.0 },
			"frentes": ["norte"], "passo": 900.0 },
		{ "id": "QC-sul-centro-oeste", "lugar": "cidade", "uso": "casa",
			"entre": { "norte": "avenida central (oeste)", "oeste": "rua do correio",
				"leste": "rua do mercado" },
			"fundo": { "sul": 900.0 },
			"frentes": ["norte"], "passo": 900.0 },
		{ "id": "QC-sul-centro-leste", "lugar": "cidade", "uso": "casa",
			"entre": { "norte": "avenida central (oeste)", "oeste": "rua do mercado" },
			"fundo": { "sul": 900.0, "leste": 2600.0 },
			"frentes": ["norte"], "passo": 900.0 },
		{ "id": "QC-sul-leste", "lugar": "cidade", "uso": "casa",
			"entre": { "norte": "avenida central (leste)", "oeste": "rua da delegacia" },
			"fundo": { "sul": 900.0, "leste": 2700.0 },
			"frentes": ["norte"], "passo": 900.0 },
	]

## Constroi uma quadra inteira: cada lote vira predio de `tipo_padrao`, exceto
## os citados em `especiais` (chave `"<frente>:<indice>"`, valor `{tipo,
## extras, juntar_ate}`) - a chave leva a FRENTE junto porque o indice
## reinicia em 0 a cada frente da quadra (`Quadras.lotes_da_quadra`), e
## "indice 0" sozinho seria ambiguo numa quadra com duas frentes. E o
## sucessor do velho `CIDADE_ESPECIAIS`: mesma ideia (alguns lotes tem tipo
## fixo), por chave em vez de "x absoluto, linha, fileira, vaga". `juntar_ate`
## funde este lote com os seguintes DA MESMA FRENTE ate aquele indice
## (`Quadras.juntar`) - o mercado e a delegacia precisam de mais de uma vaga.
static func _construir_quadra(quadra: Dictionary, vias: Dictionary, pecas: Dictionary,
		tipo_padrao: String, especiais := {}) -> void:
	var lotes := Quadras.lotes_da_quadra(quadra, vias)
	var pular := {}
	for chave in especiais:
		var partes: PackedStringArray = (chave as String).split(":")
		var indice_base := int(partes[1])
		var ate: int = especiais[chave].get("juntar_ate", -1)
		if ate <= indice_base:
			continue
		for i in range(indice_base + 1, ate + 1):
			pular["%s:%d" % [partes[0], i]] = true

	for i in lotes.size():
		var lote: Dictionary = lotes[i]
		var indice := int((lote["chave"] as String).get_slice("/", 3))
		var chave := "%s:%d" % [lote["frente"], indice]
		if pular.has(chave):
			continue
		var tipo: String = tipo_padrao
		var extras := {}
		if especiais.has(chave):
			var ate: int = especiais[chave].get("juntar_ate", -1)
			if ate > indice:
				# Acha o indice ATE no array (nao e "i + delta": pode haver
				# lote pulado - "pula" - no meio, embora nao neste uso).
				for j in range(i + 1, lotes.size()):
					if int((lotes[j]["chave"] as String).get_slice("/", 3)) == ate \
							and (lotes[j] as Dictionary)["frente"] == lote["frente"]:
						lote = Quadras.juntar(lotes, i, j)
						break
			tipo = especiais[chave]["tipo"]
			extras = especiais[chave].get("extras", {})
		var via: Dictionary = vias[quadra["entre"][lote["frente"]]]
		var predio := Quadras.predio_no_lote(lote, tipo, via, extras)
		if predio.is_empty():
			continue
		pecas["construcoes"].append(predio)
		_o_que_vem_com_o_predio(predio, pecas)
		pecas["zumbis"].append(Construcao.em_frente(predio, 0.5, 260.0))

static func _cidade(lugar: Dictionary, pecas: Dictionary) -> void:
	pecas["vias"].append_array(_cidade_rede())

	var vias := {}
	for via in pecas["vias"]:
		vias[via["nome"]] = via
	# A rodovia nao esta em pecas["vias"] (nasce em mapa.gd) - as quadras da
	# cidade nao encaram ela diretamente, entao nao falta nenhuma referencia.

	for quadra in _quadras_da_cidade():
		match quadra["id"]:
			"QC-fita-oeste":
				# O armazem fica no primeiro lote da ponta oeste da fita -
				# a "entrada norte" que Rosewood tem.
				_construir_quadra(quadra, vias, pecas, "comercio", { "sul:0": { "tipo": "armazem" } })
			"QC-fita-centro":
				# O mercado no meio da fita, comendo dois lotes (1 e 2) -
				# 1360 px de largura nao cabe numa vaga so -, com o
				# documento 4. A pistola e o documento 3 ficam com a
				# delegacia, na fita leste.
				_construir_quadra(quadra, vias, pecas, "comercio", {
					"sul:1": { "tipo": "mercado", "extras": { "documento": 4 }, "juntar_ate": 2 },
				})
			"QC-fita-leste":
				# Tambem comendo 2 vagas - 1040 px de delegacia nao cabe
				# numa vaga so de 1000 (achado rodando o conferir_mapa: o
				# lote saia raso demais e o predio era descartado).
				_construir_quadra(quadra, vias, pecas, "comercio", {
					"sul:0": { "tipo": "delegacia", "extras": { "documento": 3, "arma": true }, "juntar_ate": 1 },
				})
			_:
				_construir_quadra(quadra, vias, pecas, "casa")

## O que cada tipo de predio traz junto: patio, carro na frente, lata na
## calcada. E o que separa "predio numa grade" de lugar.
static func _o_que_vem_com_o_predio(predio: Dictionary, pecas: Dictionary) -> void:
	var tipo: String = predio["tipo"]
	# O centro do predio NAO serve para pôr zumbi: num predio de tres quartos a
	# divisoria interna passa quase no meio, e o zumbi nascia dentro da parede.
	# O centro da sala serve. O conferir_zumbi pegou.
	var sala: Vector2 = Construcao.quartos_de(predio)[0].get_center()
	# Tudo NA FRENTE da fachada, seja ela para onde for (17/09/2026, P8):
	# antes usava `onde.end.y`/`onde.position.y` direto, supondo fachada ao
	# norte ou ao sul - um predio de porta leste/oeste (a rede nova ja tem
	# alguns) poria o patio dentro do proprio predio ou do lado errado.
	match tipo:
		"delegacia":
			# Patio de concreto entre a fachada e a rua, com viatura.
			pecas["piso"].append(Construcao.na_frente(predio, 80.0, 220.0))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.22, 130.0),
			})
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.78, 130.0),
			})
			pecas["zumbis"].append(sala)
			pecas["zumbis"].append(Construcao.em_frente(predio, 0.5, 140.0))
		"mercado":
			pecas["piso"].append(Construcao.na_frente(predio, 100.0, CIDADE_RECUO))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.2, 130.0),
			})
			pecas["zumbis"].append(sala)
		"armazem":
			pecas["piso"].append(Construcao.na_frente(predio, 40.0, 160.0))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.7, 140.0),
			})
			pecas["zumbis"].append(sala)
		"comercio":
			pecas["moveis_de_rua"].append({
				"tipo": "lata", "pos": Construcao.em_frente(predio, 0.05, 60.0),
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
		"rect": loja, "porta": "norte", "tipo": "posto", "documento": 5,
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
		"rect": casa, "porta": "sul", "tipo": "mansao", "documento": 6,
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
