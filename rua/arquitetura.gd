extends RefCounted
## A arquitetura de cada predio (21/10/2026): a planta (os recortes de canto),
## o telhado, a fachada e o que fica em cima e em volta. Pedido do Joao: "que o
## restaurante realmente se pareca com um restaurante, que as casas nao sejam so
## quadrados iguais, olhe pra cada estrutura com atencao" - e "pode mudar a
## planta tambem".
##
## Duas camadas:
##
##  - **PREDIOS**: cada construcao da regiao do tutorial olhada uma por uma,
##    apontada por um ponto do PNG do desenho (como os ROTULOS do mapa.gd);
##  - **o estilo padrao** (`estilo_padrao`): o resto do mapa sai por regra do
##    tipo do predio, com variacao sorteada pela chave - casa nenhuma igual a
##    vizinha, e nada escrito a mao.
##
## Quem desenha e o rua/telhado.gd; quem tira o canto da planta e o
## rua/construcao.gd (`recortes_de`). Os moveis de enfeite (mesa, forno, varal)
## estao em DECORACAO, e quem cria e o rua/cenario.gd.
##
## **O telhado segue o tipo do predio, e nao mais so a cor do desenho**: a
## regra de 14/10 (vermelho = telha das casas, marrom = zinco do comercio,
## cinza = laje) virou "casa e telha, comercio e galpao e zinco ou
## fibrocimento, predio publico e laje ou telha" - as casas da regiao rosa sao
## marrons no desenho e saiam de zinco.

const Construcao := preload("res://rua/construcao.gd")

## As tintas das paredes: cores de verdade, desbotadas (questionario de
## 20/10/2026). O reboco e claro e quase neutro; a tinta e o modulate dele.
const TINTAS := {
	"branco": Color("e3ddd0"),
	"creme": Color("e2d2a8"),
	"amarelo": Color("dcc27a"),
	"rosa": Color("d9a8a0"),
	"verde_agua": Color("a9cbbb"),
	"azul": Color("9fb4c8"),
	"salmao": Color("d9a184"),
	"lilas": Color("b4a6c2"),
	"verde": Color("a3b88c"),
	"cinza": Color("b2afa7"),
	"terracota": Color("c7876a"),
	"ocre": Color("cfa267"),
}

## O tom de cada material de telhado: o que a textura vira na tela. Telha
## nova, desbotada, velha (escura de limo), e o fibrocimento sujo.
const TONS := {
	"nova": Color(0.94, 0.9, 0.86),
	"desbotada": Color(0.9, 0.88, 0.86),
	"velha": Color(0.76, 0.74, 0.7),
	"queimada": Color(0.62, 0.6, 0.58),
	"clara": Color(1.0, 1.0, 1.0),
	"suja": Color(0.9, 0.88, 0.84),
}

## As alturas da fachada (px de tela inclinada, na regua do boneco: o muro de
## 2 m tem 41 px de face, rua/barreira.gd). Um andar de casa tem ~2,7 m.
const ALTURA_DE_ANDAR := 52.0

# --- os predios da regiao do tutorial ----------------------------------------
#
# `ponto`: um px do PNG do desenho dentro do predio. `recortes`: os cantos
# tirados (rua/construcao.gd), com a `cobertura` que vai por cima deles
# (varanda, garagem, area de servico, deck) ou nenhuma. `telhado`, `fachada`,
# `puxado` (o telhado e a fachada dos volumes menores, quando a planta e L) e
# `extras` (o que fica em cima do telhado, em fracao do volume principal).
const PREDIOS := [
	# A sua casa: a casinha de telha romana com o oitao para o quintal, a
	# varanda do lado da porta, de frente para a rua de cima.
	{ "ponto": Vector2(1181.0, 645.0),
		"recortes": [{ "canto": "nordeste", "tamanho": Vector2(120.0, 110.0), "cobertura": "varanda" }],
		"telhado": { "forma": "duas_aguas", "cumeeira": "y", "material": "romana", "tom": "nova" },
		"puxado": { "forma": "meia_agua", "queda": "leste", "material": "romana", "tom": "desbotada", "altura": 46.0 },
		"fachada": { "parede": "reboco", "tinta": "creme", "barrado": Color("9c8c6a"), "janelas": "grade", "altura": 52.0 },
		"extras": [{ "tipo": "antena", "em": Vector2(0.62, 0.3) }, { "tipo": "musgo", "em": Vector2(0.3, 0.75) }],
		"enfeites": [
			{ "tipo": "cadeira_plastico", "em": Vector2(232.0, 62.0), "olhando": "norte" },
			{ "tipo": "vaso", "em": Vector2(300.0, 16.0) }, { "tipo": "vaso", "em": Vector2(205.0, 14.0), "variante": 1 },
			{ "tipo": "varal", "em": Vector2(-120.0, 300.0) },
			{ "tipo": "tanque", "em": Vector2(-36.0, 470.0) },
			{ "tipo": "bicicleta", "em": Vector2(-90.0, 40.0) },
		] },

	# A casa do Antonio, a mais fortificada do bairro: bloco sem reboco, laje
	# com platibanda, chapa nas janelas, caixa d'agua dupla, placa solar e o
	# arame em volta. Selada.
	{ "ponto": Vector2(1214.0, 647.0),
		"telhado": { "forma": "laje", "material": "laje", "tom": "suja" },
		"fachada": { "parede": "bloco", "tinta": "cinza", "janelas": "chapa", "altura": 58.0 },
		"extras": [
			{ "tipo": "casa_de_escada", "em": Vector2(0.78, 0.22) },
			{ "tipo": "caixa_dagua", "em": Vector2(0.22, 0.2) },
			{ "tipo": "caixa_dagua", "em": Vector2(0.36, 0.2) },
			{ "tipo": "placa_solar", "em": Vector2(0.4, 0.62) },
			{ "tipo": "antena", "em": Vector2(0.84, 0.6) },
			{ "tipo": "sacos", "em": Vector2(0.14, 0.78) },
			{ "tipo": "concertina", "em": Vector2.ZERO },
		],
		"enfeites": [{ "tipo": "botijao", "em": Vector2(-30.0, 470.0) }, { "tipo": "botijao", "em": Vector2(-13.0, 478.0), "variante": 1 }] },

	# A casa ao sul da sua: porta para o sul, entao a fachada de verdade
	# aparece - oitao de telha colonial em cima da porta e a varanda do lado.
	{ "ponto": Vector2(1192.0, 685.0),
		"recortes": [{ "canto": "sudeste", "tamanho": Vector2(130.0, 120.0), "cobertura": "varanda" }],
		"telhado": { "forma": "duas_aguas", "cumeeira": "y", "material": "colonial", "tom": "desbotada" },
		"puxado": { "forma": "meia_agua", "queda": "sul", "material": "colonial", "tom": "velha", "altura": 44.0 },
		"fachada": { "parede": "reboco", "tinta": "amarelo", "barrado": Color("8f7d4e"), "janelas": "cortina", "altura": 52.0 },
		"extras": [{ "tipo": "parabolica", "em": Vector2(0.7, 0.35) }],
		"enfeites": [
			{ "tipo": "cadeira_plastico", "em": Vector2(240.0, 540.0) },
			{ "tipo": "bicicleta", "em": Vector2(290.0, 536.0) },
			{ "tipo": "vaso", "em": Vector2(324.0, 545.0) },
			{ "tipo": "varal", "em": Vector2(430.0, 110.0), "variante": 2 },
			{ "tipo": "casinha_cachorro", "em": Vector2(390.0, 470.0) },
		] },

	# A casa do leste, perto do Predio abandonado: telha velha de limo, com o
	# puxado de fibrocimento da area de servico no fundo e uma lona azul
	# tapando o que a chuva abriu. O recorte e a varanda do nordeste: os do
	# fundo fechavam a passagem do quarto do fundo (conferir_mapa).
	{ "ponto": Vector2(1237.0, 676.0),
		"recortes": [{ "canto": "nordeste", "tamanho": Vector2(130.0, 110.0), "cobertura": "varanda" }],
		"telhado": { "forma": "quatro_aguas", "material": "romana", "tom": "velha" },
		"puxado": { "forma": "meia_agua", "queda": "leste", "material": "fibrocimento", "tom": "suja", "altura": 44.0 },
		"fachada": { "parede": "reboco", "tinta": "verde_agua", "barrado": Color("6f8a7e"), "janelas": "tabuas", "altura": 52.0 },
		"extras": [{ "tipo": "lona", "em": Vector2(0.4, 0.32) }, { "tipo": "musgo", "em": Vector2(0.7, 0.7) },
			{ "tipo": "musgo", "em": Vector2(0.25, 0.8) }],
		"enfeites": [
			{ "tipo": "cadeira_plastico", "em": Vector2(290.0, 62.0), "olhando": "norte" },
			{ "tipo": "vaso", "em": Vector2(322.0, 16.0), "variante": 2 },
			{ "tipo": "tanque", "em": Vector2(262.0, 600.0) },
			{ "tipo": "botijao", "em": Vector2(300.0, 606.0), "variante": 3 },
			{ "tipo": "churrasqueira", "em": Vector2(-72.0, 220.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(-112.0, 262.0), "olhando": "leste" },
			{ "tipo": "cadeira_plastico", "em": Vector2(-40.0, 264.0), "variante": 4 },
			{ "tipo": "pneu", "em": Vector2(-110.0, 420.0) },
		] },

	# A casinha do oeste, na beira do cerco: tijolo a vista, meia-agua de
	# fibrocimento com pneu segurando a telha, varanda de lona.
	{ "ponto": Vector2(1130.0, 640.0),
		"recortes": [{ "canto": "nordeste", "tamanho": Vector2(160.0, 110.0), "cobertura": "lona" }],
		"telhado": { "forma": "meia_agua", "queda": "sul", "material": "fibrocimento", "tom": "suja" },
		"puxado": { "forma": "meia_agua", "queda": "sul", "material": "fibrocimento", "tom": "suja", "altura": 46.0 },
		"fachada": { "parede": "tijolo", "tinta": "branco", "janelas": "quebradas", "altura": 48.0 },
		"extras": [{ "tipo": "pneu", "em": Vector2(0.3, 0.4) }, { "tipo": "pneu", "em": Vector2(0.62, 0.55) },
			{ "tipo": "pneu", "em": Vector2(0.45, 0.25) }, { "tipo": "antena", "em": Vector2(0.15, 0.3) }],
		"enfeites": [
			{ "tipo": "pneu", "em": Vector2(380.0, 40.0) }, { "tipo": "bicicleta", "em": Vector2(445.0, 72.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(475.0, 30.0), "variante": 4 },
			{ "tipo": "varal", "em": Vector2(250.0, 430.0), "variante": 1 },
			{ "tipo": "tanque", "em": Vector2(60.0, 400.0) },
			{ "tipo": "pneu", "em": Vector2(440.0, 420.0) }, { "tipo": "pneu", "em": Vector2(452.0, 428.0) },
		] },

	# A casa de porta para o leste, ao lado da pizzaria: telha romana nova, a
	# garagem coberta no canto da frente.
	{ "ponto": Vector2(1266.0, 721.0),
		"recortes": [{ "canto": "sudeste", "tamanho": Vector2(150.0, 130.0), "cobertura": "garagem" }],
		"telhado": { "forma": "quatro_aguas", "material": "romana", "tom": "desbotada" },
		"puxado": { "forma": "duas_aguas", "cumeeira": "y", "material": "romana", "tom": "desbotada", "altura": 48.0 },
		"fachada": { "parede": "reboco", "tinta": "azul", "barrado": Color("5f7186"), "janelas": "grade", "altura": 52.0 },
		"extras": [{ "tipo": "aquecedor_solar", "em": Vector2(0.55, 0.3) }],
		"enfeites": [
			{ "tipo": "bicicleta", "em": Vector2(420.0, 322.0) }, { "tipo": "pneu", "em": Vector2(470.0, 326.0) },
			{ "tipo": "engradado", "em": Vector2(506.0, 324.0), "variante": 2 },
			{ "tipo": "vaso", "em": Vector2(552.0, 40.0) }, { "tipo": "vaso", "em": Vector2(552.0, 196.0), "variante": 2 },
			{ "tipo": "mesa_plastico", "em": Vector2(-70.0, 160.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(-102.0, 166.0), "olhando": "leste" },
		] },

	# A Cover Pizzaria (era o Restaurante; Joao, 21/10/2026). Telha colonial,
	# o deck de mesas no canto da frente, o toldo verde-branco-vermelho com o
	# nome, a chamine do forno a lenha em cima da cozinha e a area de servico
	# no fundo (botijao, lenha, lixo).
	{ "ponto": Vector2(1200.0, 745.0),
		"recortes": [
			{ "canto": "noroeste", "tamanho": Vector2(280.0, 120.0), "cobertura": "pergolado" },
			{ "canto": "sudeste", "tamanho": Vector2(300.0, 140.0), "cobertura": "area" },
		],
		"telhado": { "forma": "duas_aguas", "cumeeira": "x", "material": "colonial", "tom": "nova" },
		"puxado": { "forma": "duas_aguas", "cumeeira": "x", "material": "colonial", "tom": "desbotada", "altura": 50.0 },
		"fachada": { "parede": "reboco", "tinta": "ocre", "barrado": Color("7b5a3a"), "janelas": "basculante", "altura": 60.0 },
		"toldo": { "texto": "COVER PIZZARIA", "listras": [Color("3f7a4a"), Color("e8e2d2"), Color("a83a32")],
			"de": 280.0, "ate": 1200.0, "fundo": 46.0 },
		"extras": [{ "tipo": "chamine", "em": Vector2(0.22, 0.7) }, { "tipo": "exaustor", "em": Vector2(0.4, 0.72) },
			{ "tipo": "caixa_dagua", "em": Vector2(0.8, 0.3) }],
		# Por dentro: o salao (na frente) com as mesas de toalha xadrez e o
		# balcao, a cozinha (fundo oeste) com o forno a lenha, a bancada e o
		# fogao, o deposito (fundo leste) com freezer e farinha. Fora: o deck, a
		# calcada com guarda-sol e cavalete, a moto de entrega caida e a area de
		# servico. Em px a partir do canto noroeste; o caminho da porta aos
		# moveis e os vaos das divisorias ficam livres (conferir_mapa).
		"enfeites": [
			{ "tipo": "mesa_toalha", "em": Vector2(770.0, 52.0) }, { "tipo": "mesa_toalha", "em": Vector2(890.0, 52.0), "variante": 1 },
			{ "tipo": "mesa_toalha", "em": Vector2(1010.0, 52.0), "variante": 2 }, { "tipo": "mesa_toalha", "em": Vector2(1130.0, 52.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(340.0, 112.0), "variante": 2 },
			{ "tipo": "balcao", "em": Vector2(1090.0, 148.0) },
			{ "tipo": "forno_pizza", "em": Vector2(85.0, 282.0) },
			{ "tipo": "bancada", "em": Vector2(330.0, 222.0) },
			{ "tipo": "fogao_industrial", "em": Vector2(450.0, 222.0) },
			{ "tipo": "lenha", "em": Vector2(75.0, 352.0) },
			{ "tipo": "sacos_farinha", "em": Vector2(300.0, 350.0) },
			{ "tipo": "freezer", "em": Vector2(640.0, 216.0) },
			{ "tipo": "sacos_farinha", "em": Vector2(830.0, 350.0) },
			{ "tipo": "engradado", "em": Vector2(1100.0, 214.0), "variante": 1 },
			{ "tipo": "mesa_plastico", "em": Vector2(75.0, 72.0) }, { "tipo": "mesa_plastico", "em": Vector2(195.0, 72.0), "variante": 1 },
			{ "tipo": "cadeira_plastico", "em": Vector2(45.0, 76.0), "olhando": "leste" },
			{ "tipo": "cadeira_plastico", "em": Vector2(105.0, 76.0), "olhando": "oeste" },
			{ "tipo": "cadeira_plastico", "em": Vector2(165.0, 76.0), "olhando": "leste" },
			{ "tipo": "cadeira_plastico", "em": Vector2(232.0, 96.0), "variante": 4 },
			{ "tipo": "vaso", "em": Vector2(14.0, 112.0) }, { "tipo": "vaso", "em": Vector2(266.0, 16.0), "variante": 1 },
			{ "tipo": "mesa_plastico", "em": Vector2(560.0, -112.0), "variante": 1 },
			{ "tipo": "guarda_sol", "em": Vector2(560.0, -111.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(528.0, -106.0), "olhando": "leste" },
			{ "tipo": "cadeira_plastico", "em": Vector2(592.0, -106.0), "olhando": "oeste" },
			{ "tipo": "cavalete", "em": Vector2(340.0, -70.0) },
			{ "tipo": "mesa_plastico", "em": Vector2(1140.0, -72.0), "variante": 3 },
			{ "tipo": "moto", "em": Vector2(1150.0, -150.0) },
			{ "tipo": "lixeira", "em": Vector2(262.0, -30.0) },
			{ "tipo": "botijao", "em": Vector2(950.0, 372.0) }, { "tipo": "botijao", "em": Vector2(968.0, 377.0), "variante": 1 },
			{ "tipo": "botijao", "em": Vector2(986.0, 372.0), "variante": 2 },
			{ "tipo": "lenha", "em": Vector2(1100.0, 376.0) },
			{ "tipo": "lixeira", "em": Vector2(1168.0, 372.0), "variante": 2 },
			{ "tipo": "saco_de_lixo", "em": Vector2(1060.0, 378.0), "variante": 1 },
			{ "tipo": "engradado", "em": Vector2(1022.0, 376.0), "variante": 4 },
		] },

	# A Delegacia: predio publico em L, telha colonial de quatro aguas, branco
	# com barrado azul, grade em toda janela e o letreiro em cima da porta. So o
	# canto sudeste sai: a parede oeste dela e parte do cerco do tutorial, e o
	# recorte sudoeste abria um furo nele (conferir_mapa).
	{ "ponto": Vector2(1122.0, 712.0),
		"recortes": [{ "canto": "sudeste", "tamanho": Vector2(420.0, 210.0), "cobertura": "" }],
		"telhado": { "forma": "quatro_aguas", "material": "colonial", "tom": "desbotada" },
		"puxado": { "forma": "quatro_aguas", "material": "colonial", "tom": "velha", "altura": 58.0 },
		"fachada": { "parede": "reboco", "tinta": "branco", "barrado": Color("4f6a8c"), "janelas": "grade", "altura": 64.0,
			"letreiro": "DELEGACIA DE POLÍCIA" },
		"extras": [{ "tipo": "antena_de_radio", "em": Vector2(0.8, 0.25) }, { "tipo": "ar_condicionado", "em": Vector2(0.3, 0.4) }],
		"enfeites": [
			{ "tipo": "mastro", "em": Vector2(690.0, 1050.0) },
			{ "tipo": "orelhao", "em": Vector2(300.0, 1046.0) },
			{ "tipo": "lixeira", "em": Vector2(1500.0, 980.0), "variante": 1 },
			{ "tipo": "bicicleta", "em": Vector2(1210.0, 985.0) },
			{ "tipo": "vaso", "em": Vector2(1160.0, 830.0) },
		] },
	{ "ponto": Vector2(1100.0, 695.0),
		"telhado": { "forma": "laje", "material": "laje", "tom": "suja" },
		"fachada": { "parede": "bloco", "tinta": "branco", "janelas": "grade", "altura": 56.0 },
		"extras": [{ "tipo": "caixa_dagua", "em": Vector2(0.15, 0.5) }, { "tipo": "ar_condicionado", "em": Vector2(0.6, 0.5) }] },

	# O Predio abandonado: quatro andares de laje, a quina sudeste desabada
	# (o recorte, com o entulho dela no chao), janelas quebradas e mato na
	# laje. O anexo, dois andares, do mesmo jeito.
	{ "ponto": Vector2(1293.0, 640.0),
		"recortes": [{ "canto": "sudeste", "tamanho": Vector2(260.0, 300.0), "cobertura": "desabou" }],
		"telhado": { "forma": "laje", "material": "laje", "tom": "velha" },
		"puxado": { "forma": "laje", "material": "laje", "tom": "velha", "altura": 170.0 },
		"fachada": { "parede": "reboco", "tinta": "cinza", "janelas": "quebradas", "altura": 170.0, "pichacao": true },
		"extras": [{ "tipo": "mato", "em": Vector2(0.3, 0.2) }, { "tipo": "mato", "em": Vector2(0.7, 0.55) },
			{ "tipo": "mato", "em": Vector2(0.2, 0.8) }, { "tipo": "entulho", "em": Vector2(0.55, 0.35) },
			{ "tipo": "caixa_dagua_tombada", "em": Vector2(0.75, 0.15) }, { "tipo": "buraco", "em": Vector2(0.45, 0.7) }],
		"enfeites": [{ "tipo": "saco_de_lixo", "em": Vector2(520.0, 1470.0), "variante": 1 }, { "tipo": "pneu", "em": Vector2(700.0, 1300.0) }] },
	{ "ponto": Vector2(1280.0, 630.0),
		"telhado": { "forma": "laje", "material": "laje", "tom": "velha" },
		"fachada": { "parede": "reboco", "tinta": "rosa", "janelas": "quebradas", "altura": 100.0, "pichacao": true },
		"extras": [{ "tipo": "mato", "em": Vector2(0.5, 0.4) }, { "tipo": "entulho", "em": Vector2(0.3, 0.7) }] },
]

# --- o estilo padrao ---------------------------------------------------------

const _CASAS := ["casa", "casa_pequena", "mansao"]
const _GALPOES := ["galpao", "armazem", "garagem", "anexo", "eta", "predio_em_construcao"]
const _PREDIOS_ALTOS := ["predio_abandonado", "hotel", "hospital", "prisao"]
const _PUBLICOS := ["delegacia", "prefeitura", "escola", "igreja", "bombeiros", "radio", "banco"]

## O estilo de uma construcao: o escrito a mao em PREDIOS, por cima do padrao.
static func estilo_de(construcao: Dictionary) -> Dictionary:
	return construcao.get("estilo", estilo_padrao(construcao))

## O estilo que sai por regra do tipo, com a variacao sorteada pela chave da
## construcao (a mesma a cada partida).
static func estilo_padrao(construcao: Dictionary) -> Dictionary:
	var r: Rect2 = construcao["rect"]
	var sorteio := Construcao.embaralhar("%s@%.0f,%.0f" % [construcao["tipo"], r.position.x, r.position.y])
	var tipo: String = construcao["tipo"]
	var tintas := TINTAS.keys()
	var tinta: String = tintas[sorteio % tintas.size()]
	var janelas: String = ["normal", "grade", "cortina", "tabuas", "quebradas"][(sorteio >> 4) % 5]
	var estilo := {}
	if tipo in _CASAS or construcao.get("sua", false):
		var forma: String = ["duas_aguas", "quatro_aguas", "duas_aguas", "meia_agua"][(sorteio >> 8) % 4]
		var material: String = ["romana", "colonial", "romana", "fibrocimento"][(sorteio >> 10) % 4]
		if forma == "meia_agua":
			material = "fibrocimento"
		estilo = {
			"telhado": { "forma": forma, "material": material, "tom": ["nova", "desbotada", "velha"][(sorteio >> 12) % 3],
				"cumeeira": "y" if (sorteio >> 14) % 2 == 0 else "", "queda": "sul" },
			"fachada": { "parede": "tijolo" if (sorteio >> 16) % 7 == 0 else "reboco", "tinta": tinta,
				"janelas": janelas, "altura": ALTURA_DE_ANDAR },
			"extras": [],
		}
		if (sorteio >> 18) % 3 == 0:
			estilo["extras"].append({ "tipo": "antena", "em": Vector2(0.6, 0.3) })
		if (sorteio >> 20) % 4 == 0:
			estilo["extras"].append({ "tipo": "musgo", "em": Vector2(0.35, 0.7) })
	elif tipo in _GALPOES:
		estilo = {
			"telhado": { "forma": "duas_aguas", "material": "zinco" if sorteio % 2 == 0 else "fibrocimento", "tom": "suja" },
			"fachada": { "parede": "bloco", "tinta": "cinza", "janelas": "basculante", "altura": 70.0 },
			"extras": [],
		}
	elif tipo in _PREDIOS_ALTOS:
		estilo = {
			"telhado": { "forma": "laje", "material": "laje", "tom": "suja" },
			"fachada": { "parede": "reboco", "tinta": tinta, "janelas": janelas, "altura": ALTURA_DE_ANDAR * 3.0 },
			"extras": [{ "tipo": "caixa_dagua", "em": Vector2(0.3, 0.3) }],
		}
	elif tipo in _PUBLICOS:
		var de_telha: bool = construcao.get("classe", "") == "vermelho"
		estilo = {
			"telhado": { "forma": "quatro_aguas" if de_telha else "laje",
				"material": "colonial" if de_telha else "laje", "tom": "desbotada" },
			"fachada": { "parede": "reboco", "tinta": "branco", "janelas": "grade", "altura": 62.0 },
			"extras": [{ "tipo": "caixa_dagua", "em": Vector2(0.25, 0.3) }],
		}
	else:
		# O comercio: laje com platibanda ou fibrocimento, porta de enrolar.
		var de_laje := sorteio % 2 == 0
		estilo = {
			"telhado": { "forma": "laje" if de_laje else "duas_aguas",
				"material": "laje" if de_laje else "fibrocimento", "tom": "suja" },
			"fachada": { "parede": "reboco", "tinta": tinta, "janelas": "normal", "altura": 60.0 },
			"extras": [{ "tipo": "ar_condicionado", "em": Vector2(0.7, 0.4) }] if de_laje else [],
		}
	if construcao.get("queimada", false):
		estilo["telhado"]["material"] = "queimada"
		estilo["fachada"]["janelas"] = "quebradas"
		estilo["extras"].append({ "tipo": "buraco", "em": Vector2(0.4, 0.4) })
	return estilo

# --- a montagem --------------------------------------------------------------

## Pendura em cada construcao da lista o estilo dela e, nas de PREDIOS, os
## recortes. Chamado pelo Mapa._montar, depois dos rotulos (o tipo ja esta
## decidido) e antes dos zumbis.
static func aplicar(construcoes: Array, recorte_do_desenho: Rect2, escala: float) -> void:
	for construcao in construcoes:
		construcao["estilo"] = estilo_padrao(construcao)
	for predio in PREDIOS:
		var ponto: Vector2 = (predio["ponto"] - recorte_do_desenho.position) * escala
		var alvo := {}
		for construcao in construcoes:
			if (construcao["rect"] as Rect2).has_point(ponto):
				alvo = construcao
				break
		assert(not alvo.is_empty(), "arquitetura: o ponto %s nao cai em predio nenhum" % predio["ponto"])
		var estilo: Dictionary = alvo["estilo"]
		for chave in ["telhado", "puxado", "fachada", "extras", "toldo"]:
			if predio.has(chave):
				estilo[chave] = predio[chave]
		if predio.has("enfeites"):
			alvo["enfeites"] = predio["enfeites"]
		if predio.has("recortes"):
			alvo["recortes"] = predio["recortes"]
			_conferir_recortes(alvo)

## O recorte nao pode comer a porta nem partir a casa: cada um num canto, sem
## encostar no vao, e longe um do outro.
static func _conferir_recortes(construcao: Dictionary) -> void:
	var porta := Construcao.porta_de(construcao)
	var eixo := Construcao.eixo_da_fachada(construcao)
	var normal := Construcao.normal_de(construcao).abs()
	var vao := Rect2(porta - eixo * (Construcao.VAO / 2.0) - normal * (Construcao.PAREDE / 2.0),
		eixo * Construcao.VAO + normal * Construcao.PAREDE)
	var recortes := Construcao.recortes_de(construcao)
	for i in recortes.size():
		assert(not recortes[i].grow(Construcao.PAREDE).intersects(vao), "arquitetura: o recorte %s de '%s' come a porta"
			% [construcao["recortes"][i]["canto"], construcao.get("nome", construcao["tipo"])])
		for j in range(i + 1, recortes.size()):
			assert(not recortes[i].grow(Construcao.PAREDE * 2.0).intersects(recortes[j]),
				"arquitetura: dois recortes de '%s' se encostam" % construcao.get("nome", construcao["tipo"]))
