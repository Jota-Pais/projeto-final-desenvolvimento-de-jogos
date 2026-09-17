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
##
## Cresceu de novo para o leste em 17/09/2026 (P16, 5.760 -> 6.800 px): a
## Estrada Velha entra no bairro so 160 px antes do limite antigo (x 9800 a
## 9960) - de menos para QUALQUER casa encarar ela sem sair do MUNDO
## (achado rodando o conferir_mapa: casa "nao cabe em nenhum lugar").
const BAIRRO_TAMANHO := Vector2(6800.0, 6800.0)

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
##
## As construcoes do bairro nascem em cima desta rede desde P9
## (`_quadras_do_bairro`/`_construir_quadra`) - o loteamento antigo
## (`BAIRRO_CONSTRUCOES` e as constantes irmas) foi removido nesse passo.
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

	# Rua do Bairro (leste): continuacao a leste da Estrada do Bairro
	# (17/09/2026, P18 - pedido do dono: uma quadra de esquina de verdade,
	# com DUAS frentes perpendiculares na mesma quadra). O quarteirao entre
	# a rodovia e esta rua, a leste da Estrada do Bairro, e o UNICO pedaco
	# do bairro com folga de sobra nos dois eixos (~3000 px) para o
	# RESERVA_DE_CANTO_MAXIMA de P16 nao zerar nenhuma das duas frentes -
	# em todo o resto do bairro/da cidade, um dos dois eixos e raso demais
	# (testado e descartado: ao sul da Rua do Norte cruzava QC-fita-centro,
	# ao norte dela a via de apoio nem chegava la). Termina num laco, nunca
	# bulbo solto.
	fora.append({ "nome": "rua do bairro (leste)", "classe": "residencial", "lugar": "bairro",
		"eixo": [Vector2(7000.0, 13800.0), Vector2(10140.0, 13800.0)],
		"pontas": ["T:estrada do bairro", "laco:laço do bairro leste"] })
	fora.append_array(Vias.laco(Vector2(10500.0, 13800.0), Vector2(400.0, 600.0), 320.0,
		"laço do bairro leste"))

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
	# criterio F. Sobe e encontra a Rua do Correio da cidade exatamente no
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
		"mata": _mata(lugar, pecas)
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

## As quadras do bairro (17/09/2026, P9 - arquitetura nova; densificado em
## P16), em cima de `_bairro_rede()`. Substitui o loteamento de 16/09/2026
## (`BAIRRO_CONSTRUCOES`/`BAIRRO_CERCAS`/`BAIRRO_MOVEIS_DE_RUA`/
## `BAIRRO_ZUMBIS`/`BAIRRO_BOSQUES`, tudo removido) - cada quadra sabendo so
## quais vias a limitam.
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
		# QB-baixo (o quarteirao a sul da Rua de Baixo, a oeste da Estrada do
		# Bairro) foi REMOVIDA em P16: o retorno de baixo (o "U" que fecha a
		# Rua de Baixo) atravessa bem no meio do retangulo dela - x 5600 a
		# 6400, dentro do x 5240-6840 que a quadra reclamava -, e nenhuma
		# das duas sabia da outra. Enquanto a quadra so descartava o unico
		# lote (por falta de espaco), o conflito ficava escondido; ao
		# consertar o descarte (achado acima, testando densidade) a casa
		# nascia EM CIMA do proprio retorno. A area dela virou as casas de
		# `_casas_junto_a_via` em volta do retorno, mais abaixo em `_bairro`.
		#
		# A leste do Beco dos Fundos, virada para a Rua de Baixo (que agora
		# chega ate aqui - ver a rede acima). Fundo 1600, nao 700
		# (17/09/2026, P9): 700 nao cabia nem UM lote de passo 800.
		{ "id": "QB-leste", "lugar": "bairro", "uso": "casa",
			"entre": { "sul": "rua de baixo", "oeste": "beco dos fundos" },
			"fundo": { "norte": 1600.0, "leste": 1600.0 },
			"frentes": ["sul"], "passo": 800.0 },
		# A Estrada Velha nao vira quadra (17/09/2026, P16): ancorar o lado
		# leste dela precisaria da Estrada Velha (subida), a 3.200 px dali -
		# bem alem do proprio limite do bairro (x 9960), que so cobre 160 px
		# depois de onde a Estrada Velha comeca (x 9800). Uma casa ali
		# nasceria fora de qualquer lugar do MUNDO (achado rodando o
		# conferir_mapa). Ganha UMA casa a mao em `_bairro`, com o bairro
		# alargado o suficiente pra ela caber - ver `_casas_junto_a_via`.
		#
		# QB-canto (17/09/2026, P18): a primeira quadra do mapa com DUAS
		# frentes perpendiculares de verdade - "sul" encara a Rua do Bairro
		# (leste), "oeste" encara a Estrada do Bairro. Fundo generoso nos
		# dois eixos (2600/2700 px) de proposito: e exatamente o caso que
		# RESERVA_DE_CANTO_MAXIMA (P16) existe para proteger, e so funciona
		# com folga real sobrando dos dois lados depois da reserva - por
		# isso o quarteirao entre a rodovia e a Rua do Bairro (leste) foi
		# escolhido (ver a rede acima).
		{ "id": "QB-canto", "lugar": "bairro", "uso": "casa",
			"entre": { "sul": "rua do bairro (leste)", "oeste": "estrada do bairro" },
			"fundo": { "norte": 2600.0, "leste": 2700.0 },
			"frentes": ["sul", "oeste"], "passo": 900.0 },
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

	# Casas viradas PRA DENTRO do laco do poente e do retorno de baixo
	# (17/09/2026, P16 - pedido do dono: "esses lacos nao fazem sentido,
	# eles nao tao levando pra lugar algum"). Os dois eram geometria pura -
	# nenhum lote da quadra os usava como frente, porque um laco/retorno so
	# tem ~1000 px de reta por lado, curto demais para ancorar uma quadra
	# nos dois eixos. `_casas_junto_a_via` reusa `Quadras.predio_no_lote`
	# direto, sem passar pela quadra inteira.
	#
	# So um lado de cada (norte/sul do laco; oeste do retorno): o lado
	# oeste do laco esbarra na mata do oeste (a via nasce a 10 px da borda
	# do proprio lugar), e o leste do retorno esbarra na Estrada do Bairro -
	# nenhum dos dois sobra espaco de verdade.
	_casas_junto_a_via(vias["laco do poente norte"], "sul", 4230.0,
		[950.0], 1250.0, "bairro/laco-norte", pecas)
	_casas_junto_a_via(vias["laco do poente sul"], "norte", 4230.0,
		[950.0], 1250.0, "bairro/laco-sul", pecas)
	_casas_junto_a_via(vias["retorno de baixo (a)"], "leste", 15650.0,
		[1100.0], 1350.0, "bairro/retorno-oeste", pecas)
	# O fundo do retorno e raso demais (so ~740 px ate a borda do lugar) para
	# uma casa de verdade - um galpao de quintal cabe, e sobra a mesma
	# variedade que o sitio/a lavoura ja usam.
	var via_fundo: Dictionary = vias["retorno de baixo (fundo)"]
	var borda_fundo: float = Vias.borda_util_de(via_fundo, Quadras.OPOSTO["norte"])
	var lote_do_fundo := { "rect": Rect2(5620.0, borda_fundo, 650.0, 740.0), "frente": "norte",
		"profundidade": 740.0, "chave": "bairro/retorno-fundo/0" }
	var galpao_do_fundo := Quadras.predio_no_lote(lote_do_fundo, "galpao", via_fundo, {})
	if not galpao_do_fundo.is_empty():
		pecas["construcoes"].append(galpao_do_fundo)
		_o_que_vem_com_o_predio(galpao_do_fundo, pecas)
		pecas["zumbis"].append(Construcao.em_frente(galpao_do_fundo, 0.5, 200.0))

	# Uma casa na Estrada Velha (17/09/2026, P16): a segunda rota ate a
	# cidade tinha 3.200 px de via residencial sem NENHUM predio encarando
	# ela. O bairro alargou (ver BAIRRO_TAMANHO/mapa.gd) so o suficiente
	# para esta casa caber com folga.
	_casas_junto_a_via(vias["estrada velha"], "norte", 9820.0,
		[950.0], 1350.0, "bairro/estrada-velha", pecas)

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
## Coordenadas em MUNDO. As construcoes da cidade nascem em cima desta rede
## desde P8 (`_quadras_da_cidade`/`_construir_quadra`) - a grade antiga
## (`_uma_quadra`) foi removida nesse passo.
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
	# rota do criterio F. Rua da Delegacia sobe mais, ate o Laco do Norte.
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
		# Passo 880, nao 1000 (17/09/2026, P16 - achado reproduzindo a
		# matematica de rect_da_quadra: a testada real contra a Avenida mede
		# so 930 px, menor que o proprio passo de 1000 - "sul:0" nunca
		# nascia, nem o armazem que o comentario antigo prometia. Agora e o
		# Corpo de Bombeiros, no unico lote que sobra.
		{ "id": "QC-fita-oeste", "lugar": "cidade", "uso": "comercio",
			"entre": { "sul": "avenida central (oeste)", "leste": "rua do poente" },
			"fundo": { "norte": 1200.0, "oeste": 1100.0 },
			"frentes": ["sul"], "passo": 880.0 },
		# O Hospital (17/09/2026, P16): o bolso de terra entre a fita
		# comercial e a Rua da Delegacia, apoiado nas duas vias reais que ja
		# o limitam por fora. So "leste" como frente - a Avenida
		# ("sul"/"norte") fica perto demais do cotovelo (x 19600) para
		# reservar canto sem sobrepor ele.
		{ "id": "QC-hospital", "lugar": "cidade", "uso": "publico",
			"entre": { "sul": "avenida central (leste)", "leste": "rua da delegacia" },
			"fundo": { "norte": 1400.0, "oeste": 1000.0 },
			"frentes": ["leste"], "passo": 1300.0 },
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
		# A primeira quadra do mapa com frente a OESTE (17/09/2026, P17 -
		# pedido do dono: "arruma esses bugs" sobre a lacuna de leste/oeste
		# deixada em P16). No bolso aberto entre a Rua do Norte e a fita
		# comercial (QC-fita-leste comeca so em y 5840 - 1.180 px de folga),
		# a leste da Rua da Delegacia - unica frente, entao nem passa pelo
		# `cantos_reservados`/`RESERVA_DE_CANTO_MAXIMA` de P16 (esses so
		# entram em jogo com DUAS frentes perpendiculares na mesma quadra).
		{ "id": "QC-poente-norte", "lugar": "cidade", "uso": "casa",
			"entre": { "norte": "rua do norte", "oeste": "rua da delegacia" },
			"fundo": { "sul": 1000.0, "leste": 1200.0 },
			"frentes": ["oeste"], "passo": 900.0 },
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

## Casas encostadas a mao numa via que `Quadras` nao cobre sozinha - um laco
## ou um retorno em U so tem uns 1000 px de frente por lado, curto demais
## para valer uma quadra inteira (que precisa de ancora nos DOIS eixos, e um
## laco so oferece via no proprio perimetro). Reusa
## `Quadras.predio_no_lote` direto, montando o "lote" a mao: mesma logica de
## recuo, entrada de carro e descarte por falta de espaco que qualquer
## quadra de verdade usa - so o retangulo do lote nao vem de
## `rect_da_quadra`.
##
## `larguras` e a frente de cada casa em fila, começando em `x_inicio` ao
## longo do eixo da via (x se a via for horizontal, y se for vertical).
static func _casas_junto_a_via(via: Dictionary, frente: String, x_inicio: float,
		larguras: Array, profundidade: float, chave_base: String, pecas: Dictionary) -> void:
	var borda: float = Vias.borda_util_de(via, Quadras.OPOSTO[frente])
	var x := x_inicio
	for i in larguras.size():
		var largura: float = larguras[i]
		var rect: Rect2
		match frente:
			"sul": rect = Rect2(x, borda - profundidade, largura, profundidade)
			"norte": rect = Rect2(x, borda, largura, profundidade)
			"leste": rect = Rect2(borda - profundidade, x, profundidade, largura)
			_: rect = Rect2(borda, x, profundidade, largura)  # oeste
		var lote := {
			"rect": rect, "frente": frente, "profundidade": profundidade,
			"chave": "%s/%d" % [chave_base, i],
		}
		var predio := Quadras.predio_no_lote(lote, "casa", via, {})
		if not predio.is_empty():
			pecas["construcoes"].append(predio)
			_o_que_vem_com_o_predio(predio, pecas)
			pecas["zumbis"].append(Construcao.em_frente(predio, 0.5, 260.0))
		x += largura

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
				# O corpo de bombeiros no unico lote da ponta oeste da fita
				# (17/09/2026, P16 - substitui o "armazem" do comentario
				# antigo, que nunca chegava a nascer: a testada real so
				# cobre 930 px, curta demais para o passo de 1000 que a
				# quadra tinha).
				_construir_quadra(quadra, vias, pecas, "comercio", { "sul:0": { "tipo": "bombeiros" } })
			"QC-hospital":
				_construir_quadra(quadra, vias, pecas, "hospital", { "leste:0": { "tipo": "hospital" } })
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
	# O centro do predio NAO serve para por zumbi: num predio de tres quartos a
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
		"hospital":
			# Uma ambulancia na frente - o mesmo movel "carro", que ja serve
			# de viatura na delegacia. Longe de 0.35 (17/09/2026, P16 -
			# achado rodando o conferir_mapa: a porta fica a 0,35 da
			# fachada - `Construcao.paredes_externas` - e o carro em 0,3
			# caia bem em cima do vao, tapando a UNICA entrada do predio.
			# Todo movel de rua encostado em fachada usa fracao bem longe
			# de 0,35 - a delegacia usa 0,22/0,78, o armazem usa 0,7).
			pecas["piso"].append(Construcao.na_frente(predio, 60.0, 200.0))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.75, 130.0),
			})
			pecas["zumbis"].append(sala)
		"bombeiros":
			pecas["piso"].append(Construcao.na_frente(predio, 60.0, 200.0))
			pecas["moveis_de_rua"].append({
				"tipo": "carro", "pos": Construcao.em_frente(predio, 0.75, 140.0),
			})
			pecas["zumbis"].append(sala)

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

	# As duas viradas para a estrada, que vem de baixo (r.end.y) - e por
	# isso que ficam encostadas no fundo do terreno, e nao perto da frente
	# (17/09/2026, P10 - achado rodando o conferir_mapa): a porta ja olhava
	# para o sul certo, mas a casa nascia perto do TOPO do terreno - quase
	# 1200 px de patio vazio ate a propria estrada de terra, bem alem dos
	# 950 px que RECUO_MAXIMO_DA_VIA aceita. A casa e o galpao nao tem por
	# que morar longe do proprio portao.
	var casa_x := r.position.x + 200.0
	var casa_rect := Rect2(casa_x, r.end.y - casa.y - 300.0, casa.x, casa.y)
	pecas["construcoes"].append({ "rect": casa_rect, "porta": "sul", "tipo": "casa" })
	# O galpao no fundo do terreno, virado para a casa.
	var galpao_x := r.end.x - galpao.x - 300.0
	var galpao_rect := Rect2(galpao_x, r.end.y - galpao.y - 260.0, galpao.x, galpao.y)
	pecas["construcoes"].append({ "rect": galpao_rect, "porta": "sul", "tipo": "galpao" })

	# O patio de terra batida na frente das duas, encostado na estrada de
	# terra que chega em `lugar["acesso"]` (17/09/2026, P10 - novo): sem
	# ele nenhuma das duas "encarava via" de verdade - a estrada de terra e
	# poligonal (`Vias.e_reta` recusa), entao so um retangulo de verdade na
	# ponta dela resolve, o mesmo padrao que o patio da delegacia/mercado
	# ja usa. So um retangulo (classe sem largura minima/maxima, ver
	# `Vias.CLASSES.patio`) - nao entra na conta de largura nem de arvore.
	var frente_min := casa_x - 80.0
	var frente_max := galpao_rect.end.x + 80.0
	var patio_y := maxf(casa_rect.end.y, galpao_rect.end.y) + 10.0
	pecas["vias"].append({
		"nome": "patio de %s" % lugar["nome"], "classe": "patio", "lugar": lugar["nome"],
		"rect": Rect2(frente_min, patio_y, frente_max - frente_min, 300.0),
		"pontas": ["declarado:patio"],
	})

	# Cerca de frente com o vao do patio.
	pecas["cercas"].append(Rect2(r.position.x, r.end.y - 16.0, frente_min - r.position.x, 16.0))
	pecas["cercas"].append(Rect2(frente_max, r.end.y - 16.0, r.end.x - frente_max, 16.0))

	# Os dois mais perto do portao agora (17/09/2026, P10): a casa e o
	# galpao andaram para o fundo do terreno, e o carro/a lata na frente
	# deles ficariam por baixo da propria parede se ficassem parados.
	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(r.position.x + 340.0, r.end.y - 80.0),
	})
	pecas["moveis_de_rua"].append({
		"tipo": "lata", "pos": Vector2(r.end.x - 220.0, r.end.y - 80.0),
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

	# Um galpao de fazenda perto de onde a estrada de terra chega, que e o
	# unico loot daqui. **Centrado no `acesso` do lugar, nao no canto**
	# (17/09/2026, P10 - achado rodando o conferir_mapa): morava no canto
	# leste, a 3.880 px de onde a estrada realmente entra (x 17400) - a
	# porta nunca ia encarar via nenhuma daquele jeito, por mais perto que
	# o recuo fosse.
	var acesso: Vector2 = lugar.get("acesso", r.position + Vector2(r.size.x * 0.5, 0.0))
	var galpao := Construcao.TAMANHOS["galpao"]
	var galpao_rect := Rect2(acesso.x - galpao.x * 0.5, r.position.y + 300.0, galpao.x, galpao.y)
	pecas["construcoes"].append({
		"rect": galpao_rect, "porta": "norte", "tipo": "galpao",
	})
	# O patio de terra entre o galpao e a propria estrada (mesmo padrao do
	# sitio: a estrada de terra e poligonal, `Vias.e_reta` a recusa, entao
	# so um retangulo de verdade na ponta dela faz o galpao encarar via).
	var patio := Rect2(galpao_rect.position.x - 80.0, r.position.y - 300.0,
		galpao_rect.size.x + 160.0, galpao_rect.position.y - r.position.y + 300.0 - 10.0)
	pecas["vias"].append({
		"nome": "patio da lavoura", "classe": "patio", "lugar": lugar["nome"],
		"rect": patio, "pontas": ["declarado:patio"],
	})

	var colunas := 3
	var linhas := 2
	var carreador := 240.0
	var talhao := Vector2(
		(r.size.x - carreador * float(colunas + 1)) / float(colunas),
		(r.size.y - carreador * float(linhas + 1)) / float(linhas))

	# Pula o talhao que cairia em cima do galpao/patio novo - a lavoura e so
	# chao pintado, sem colisao, mas plantacao por baixo do galpao ficaria
	# esquisita de ver.
	for coluna in colunas:
		for linha in linhas:
			var pedaco := Rect2(
				r.position.x + carreador + float(coluna) * (talhao.x + carreador),
				r.position.y + carreador + float(linha) * (talhao.y + carreador),
				talhao.x, talhao.y)
			if pedaco.intersects(galpao_rect) or pedaco.intersects(patio):
				continue
			pecas["lavoura"].append(pedaco)

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

	# A loja no fundo, virada para a rodovia. 18 x 12 m - tamanho de loja de
	# conveniencia, e nao os 22 x 14 escritos na mao que tinha antes.
	var tamanho: Vector2 = Construcao.TAMANHOS["posto"]
	var loja := Rect2(r.end.x - tamanho.x - 260.0, r.end.y - tamanho.y - 120.0,
		tamanho.x, tamanho.y)
	pecas["construcoes"].append({
		"rect": loja, "porta": "norte", "tipo": "posto", "documento": 5,
	})

	# A pista de concreto vai ate a LOJA, nao o lugar inteiro (17/09/2026, P10
	# - achado rodando o conferir_mapa: "posto pisa no piso de concreto" - a
	# loja nascia dentro do proprio retangulo de piso, porque ele cobria o
	# lugar inteiro por baixo dela tambem).
	pecas["piso"].append(Rect2(r.position, Vector2(r.size.x, loja.position.y - r.position.y - 40.0)))

	# Duas bombas em ilha, entre a rodovia e a loja. A pista aberta e o oposto de
	# uma casa: nao ha onde se esconder, e voce ve o zumbi vindo de longe.
	for i in 2:
		pecas["moveis_de_rua"].append({
			"tipo": "bomba",
			"pos": Vector2(r.position.x + 420.0 + float(i) * 460.0, r.position.y + 380.0),
		})

	pecas["moveis_de_rua"].append({
		"tipo": "carro", "pos": Vector2(r.position.x + 300.0, r.position.y + 700.0),
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
	var garagem_tamanho: Vector2 = Construcao.TAMANHOS["garagem"]
	var garagem := Rect2(casa.end.x + 500.0, casa.position.y + 200.0,
		garagem_tamanho.x, garagem_tamanho.y)
	pecas["construcoes"].append({
		"rect": garagem, "porta": "sul", "tipo": "garagem",
	})

	# Alameda de concreto do portao ate a porta da casa - larga o bastante
	# para cobrir a garagem tambem (17/09/2026, P10 - achado rodando o
	# conferir_mapa): a faixa media so 400 px, centrada na casa, e a
	# garagem fica bem mais a leste - a porta dela nao encarava nada.
	pecas["piso"].append(Rect2(portao_x - 200.0, casa.end.y,
		garagem.end.x + 100.0 - (portao_x - 200.0), r.end.y - casa.end.y))

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

# --- mata ---------------------------------------------------------------

## Mata. Nao tem loot e nao tem construcao: e o vazio entre os lugares, e e ele
## que faz a distancia existir. No PZ e a floresta entre as cidades que
## transforma "ir ate la" numa decisao.
##
## **Tipo "mata", nao mais "floresta"** (17/09/2026, P10): o proprio nome de
## cada lugar ja dizia "mata do X", e o conferir_mapa cobra que "mata" no nome
## va junto com densidade >= 0,40 (mata fechada de verdade) - renomear o tipo
## e so acertar o codigo com o que o dado ja afirmava.
##
## O bosque nao ocupa o retangulo inteiro do mesmo jeito em toda parte - so a
## faixa mais perto do limite do MUNDO (`lado_da_mata`) e mata FECHADA de
## verdade; o resto e bosque **ralo** (a transicao). **O ralo vai ate a outra
## borda do lugar, nao uma faixa fixa** (17/09/2026, P19 - queixa do dono: "tem
## poucas casas, o mapa tem poucos detalhes... esses lacos n fazem sentido" -
## a mesma reclamação valia para a mata. Ate aqui o ralo tinha profundidade
## fixa (900 px) e o que sobrava do retangulo ficava em aberto, sem bosque
## nenhum - na mata do leste isso era 5.180 px (130 m!) de capim raso, maior
## que a propria cidade. Dar essa folga ao ralo em vez de deixar aberto custa
## arvore nenhuma a mais no orcamento fixo do mapa alem do que ja se pagava
## por decisao anterior - so muda ATE ONDE o ralo se estende).
const PROFUNDIDADE_DA_MATA_FECHADA := 1400.0
const DENSIDADE_DO_BOSQUE_RALO := 0.15

static func _mata(lugar: Dictionary, pecas: Dictionary) -> void:
	var r: Rect2 = (lugar["rect"] as Rect2).grow(-160.0)
	var densidade: float = lugar.get("densidade", 0.03)
	var lado: String = lugar.get("lado_da_mata", "")
	if lado == "":
		pecas["bosques"].append({ "rect": r, "densidade": densidade })
		_zumbis_da_mata(r, pecas)
		return

	var fechada := r
	var ralo := r
	match lado:
		"oeste":
			fechada = Rect2(r.position.x, r.position.y, PROFUNDIDADE_DA_MATA_FECHADA, r.size.y)
			ralo = Rect2(fechada.end.x, r.position.y, r.size.x - PROFUNDIDADE_DA_MATA_FECHADA,
				r.size.y)
		"norte":
			fechada = Rect2(r.position.x, r.position.y, r.size.x, PROFUNDIDADE_DA_MATA_FECHADA)
			ralo = Rect2(r.position.x, fechada.end.y, r.size.x,
				r.size.y - PROFUNDIDADE_DA_MATA_FECHADA)
		"leste":
			fechada = Rect2(r.end.x - PROFUNDIDADE_DA_MATA_FECHADA, r.position.y,
				PROFUNDIDADE_DA_MATA_FECHADA, r.size.y)
			ralo = Rect2(r.position.x, r.position.y, r.size.x - PROFUNDIDADE_DA_MATA_FECHADA,
				r.size.y)
		"sul":
			fechada = Rect2(r.position.x, r.end.y - PROFUNDIDADE_DA_MATA_FECHADA,
				r.size.x, PROFUNDIDADE_DA_MATA_FECHADA)
			ralo = Rect2(r.position.x, r.position.y, r.size.x,
				r.size.y - PROFUNDIDADE_DA_MATA_FECHADA)
		_:
			# Nenhum lugar de hoje usa outro valor - falha alto em vez de
			# silenciosamente dobrar "fechada" e "ralo" no retangulo inteiro
			# (dois bosques cheios sobrepostos, achado na revisao de P15).
			assert(false, "lado_da_mata desconhecido: '%s'" % lado)
	pecas["bosques"].append({ "rect": fechada, "densidade": densidade })
	pecas["bosques"].append({ "rect": ralo, "densidade": DENSIDADE_DO_BOSQUE_RALO })
	_zumbis_da_mata(r, pecas)

## Um ou dois arrastando entre as arvores, para a mata nao ser passeio.
static func _zumbis_da_mata(r: Rect2, pecas: Dictionary) -> void:
	pecas["zumbis"].append(r.get_center())
	if r.get_area() > 60000000.0:
		pecas["zumbis"].append(r.get_center() + r.size * 0.28)
