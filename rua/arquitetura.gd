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

## A pegada de cada movel de vasculho na mobilia escrita a mao: a do que e
## opaco no desenho, e nao a da ficha (rua/construcao.gd, MOVEIS), que e de
## antes do corpo do jogador cair pela metade e nao deixava caber dois moveis
## num quarto. Largura x fundo, com a frente para o sul.
const PEGADA_JUSTA := {
	"geladeira": Vector2(46, 30),
	"estante": Vector2(58, 26),
	"comoda": Vector2(62, 32),
	"armario": Vector2(60, 30),
	"prateleira": Vector2(108, 34),
	"caixa": Vector2(48, 40),
	"arquivo": Vector2(50, 32),
	"armario_de_armas": Vector2(50, 30),
	"maca": Vector2(52, 30),
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
		"mobilia": [
			# Sala (na frente): sofa de costas para a divisoria, a TV de frente para ele, a estante.
			{ "tipo": "sofa", "em": Vector2(70.0, 351.0) },
			{ "tipo": "estante", "em": Vector2(160.0, 349.0) },
			{ "tipo": "tapete", "em": Vector2(70.0, 392.0), "tamanho": Vector2(80.0, 30.0) },
			{ "tipo": "rack_tv", "em": Vector2(70.0, 425.0), "olhando": "norte" },
			{ "tipo": "vaso", "em": Vector2(176.0, 525.0) },
			# Cozinha (fundo leste, entra pela sala): geladeira e bancada na parede norte, a mesa no meio.
			{ "tipo": "geladeira", "em": Vector2(198.0, 50.0) },
			{ "tipo": "bancada_cozinha", "em": Vector2(268.0, 46.0), "tamanho": Vector2(90.0, 26.0) },
			{ "tipo": "botijao", "em": Vector2(300.0, 72.0) },
			{ "tipo": "mesa_jantar", "em": Vector2(245.0, 200.0) },
			# Quarto (fundo oeste, entra pela cozinha): cama e comoda na parede norte.
			{ "tipo": "cama", "em": Vector2(56.0, 96.0) },
			{ "tipo": "comoda", "em": Vector2(122.0, 52.0) },
			{ "tipo": "tapete", "em": Vector2(56.0, 140.0), "variante": 1, "tamanho": Vector2(50.0, 26.0) },
			{ "tipo": "roupas", "em": Vector2(110.0, 160.0), "variante": 1 },
			# Banheiro (no fundo do quarto): vaso, pia com espelho e box.
			{ "tipo": "vaso_sanitario", "em": Vector2(40.0, 245.0) },
			{ "tipo": "pia_banheiro", "em": Vector2(75.0, 237.0) },
			{ "tipo": "box_chuveiro", "em": Vector2(131.0, 300.0) },
		],
		"paredes": [Rect2(20.0, 201.0, 80.0, 20.0), Rect2(145.0, 201.0, 8.2, 20.0)],
		"pisos": [["taco", Rect2(20.0, 321.6, 296.0, 90.4)], ["taco", Rect2(20.0, 412.0, 166.0, 120.0)], ["lajota", Rect2(173.2, 20.0, 142.8, 281.6)], ["taco", Rect2(20.0, 20.0, 133.2, 181.0)], ["azulejo", Rect2(20.0, 221.0, 133.2, 80.6)]],
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
		"mobilia": [
			# Sala de jantar (frente): a mesa no canto da porta, a estante na parede norte.
			{ "tipo": "mesa_jantar", "em": Vector2(80.0, 150.0) },
			{ "tipo": "estante", "em": Vector2(240.0, 156.0) },
			{ "tipo": "vaso", "em": Vector2(300.0, 150.0) },
			# Cozinha (fundo leste): bancada e geladeira encostadas na parede leste, de lado.
			{ "tipo": "bancada_cozinha", "em": Vector2(303.0, 440.0), "olhando": "oeste", "tamanho": Vector2(26.0, 160.0) },
			{ "tipo": "geladeira", "em": Vector2(301.0, 500.0), "olhando": "oeste" },
			{ "tipo": "lixeira", "em": Vector2(190.0, 520.0) },
			# Quarto (fundo oeste): cama na parede do banheiro, comoda de lado na parede oeste.
			{ "tipo": "cama", "em": Vector2(56.0, 426.0) },
			{ "tipo": "comoda", "em": Vector2(36.0, 520.0), "olhando": "leste" },
			{ "tipo": "tapete", "em": Vector2(100.0, 470.0), "tamanho": Vector2(44.0, 30.0) },
			{ "tipo": "roupas", "em": Vector2(120.0, 500.0) },
			# Banheiro (na ponta norte do quarto).
			{ "tipo": "vaso_sanitario", "em": Vector2(90.0, 274.0) },
			{ "tipo": "pia_banheiro", "em": Vector2(125.0, 266.0) },
			{ "tipo": "box_chuveiro", "em": Vector2(44.0, 330.0) },
		],
		"paredes": [Rect2(20.0, 330.0, 80.0, 20.0), Rect2(145.0, 330.0, 8.2, 20.0)],
		"pisos": [["taco", Rect2(20.0, 20.0, 166.0, 110.0)], ["taco", Rect2(20.0, 130.0, 296.0, 100.4)], ["lajota", Rect2(173.2, 250.4, 142.8, 281.6)], ["azulejo", Rect2(20.0, 250.4, 133.2, 79.6)], ["taco", Rect2(20.0, 350.0, 133.2, 182.0)]],
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
		"mobilia": [
			# O canto de dormir (oeste): cama na parede da frente, a TV de frente para ela, a comoda de lado.
			{ "tipo": "cama", "em": Vector2(60.0, 96.0) },
			{ "tipo": "rack_tv", "em": Vector2(100.0, 160.0), "olhando": "norte" },
			{ "tipo": "comoda", "em": Vector2(36.0, 230.0), "olhando": "leste" },
			{ "tipo": "roupas", "em": Vector2(150.0, 120.0) },
			# O canto da cozinha (leste): geladeira na parede da frente, pia com fogao na parede da varanda, a mesa.
			{ "tipo": "geladeira", "em": Vector2(300.0, 50.0) },
			{ "tipo": "pia_fogao", "em": Vector2(414.0, 156.0) },
			{ "tipo": "mesa_jantar", "em": Vector2(290.0, 230.0) },
			{ "tipo": "latas", "em": Vector2(200.0, 290.0) },
			# O banheiro no canto sudeste.
			{ "tipo": "vaso_sanitario", "em": Vector2(420.0, 260.0) },
			{ "tipo": "pia_banheiro", "em": Vector2(455.0, 252.0) },
			{ "tipo": "box_chuveiro", "em": Vector2(462.0, 316.0) },
		],
		"paredes": [Rect2(384.0, 216.0, 20.0, 40.0), Rect2(384.0, 300.0, 20.0, 16.0), Rect2(404.0, 216.0, 80.0, 20.0)],
		"pisos": [["taco", Rect2(20.0, 20.0, 304.0, 110.0)], ["taco", Rect2(20.0, 130.0, 364.0, 186.0)], ["taco", Rect2(384.0, 130.0, 100.0, 86.0)], ["azulejo", Rect2(404.0, 236.0, 80.0, 80.0)]],
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
		"mobilia": [
			# Sala (leste, a da porta): sofa na parede norte, a TV de frente, a estante.
			{ "tipo": "sofa", "em": Vector2(380.0, 51.0) },
			{ "tipo": "estante", "em": Vector2(470.0, 47.0) },
			{ "tipo": "tapete", "em": Vector2(380.0, 118.0), "tamanho": Vector2(70.0, 28.0) },
			{ "tipo": "rack_tv", "em": Vector2(380.0, 150.0), "olhando": "norte" },
			# Cozinha (sudoeste, entra pela sala): geladeira e bancada na divisoria, a mesa.
			{ "tipo": "geladeira", "em": Vector2(45.0, 203.0) },
			{ "tipo": "botijao", "em": Vector2(80.0, 199.0) },
			{ "tipo": "bancada_cozinha", "em": Vector2(246.0, 199.0), "tamanho": Vector2(82.0, 26.0) },
			{ "tipo": "mesa_jantar", "em": Vector2(150.0, 290.0) },
			# Quarto (noroeste): cama, criado-mudo e comoda na parede norte.
			{ "tipo": "cama", "em": Vector2(160.0, 96.0) },
			{ "tipo": "criado_mudo", "em": Vector2(205.0, 36.0) },
			{ "tipo": "comoda", "em": Vector2(252.0, 52.0) },
			{ "tipo": "roupas", "em": Vector2(230.0, 125.0) },
			# Banheiro (na ponta oeste do quarto).
			{ "tipo": "vaso_sanitario", "em": Vector2(36.0, 44.0) },
			{ "tipo": "pia_banheiro", "em": Vector2(70.0, 36.0) },
			{ "tipo": "box_chuveiro", "em": Vector2(44.0, 153.0) },
		],
		"paredes": [Rect2(100.0, 20.0, 20.0, 70.0), Rect2(100.0, 135.0, 20.0, 18.2)],
		"pisos": [["taco", Rect2(308.4, 20.0, 199.6, 166.0)], ["taco", Rect2(308.4, 186.0, 49.6, 130.0)], ["lajota", Rect2(20.0, 173.2, 268.4, 142.8)], ["azulejo", Rect2(20.0, 20.0, 80.0, 133.2)], ["taco", Rect2(120.0, 20.0, 168.4, 133.2)]],
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
			{ "tipo": "mesa_bar", "em": Vector2(80.0, 96.0) },
			{ "tipo": "mesa_bar", "em": Vector2(200.0, 96.0), "variante": 1 },
			{ "tipo": "vaso", "em": Vector2(14.0, 112.0) },
			{ "tipo": "vaso", "em": Vector2(266.0, 16.0), "variante": 1 },
			{ "tipo": "mesa_bar", "em": Vector2(560.0, -106.0), "variante": 1 },
			{ "tipo": "guarda_sol", "em": Vector2(560.0, -105.0) },
			{ "tipo": "cavalete", "em": Vector2(340.0, -70.0) },
			{ "tipo": "mesa_plastico", "em": Vector2(1140.0, -72.0), "variante": 3 },
			{ "tipo": "moto", "em": Vector2(1150.0, -150.0) },
			{ "tipo": "lixeira", "em": Vector2(262.0, -30.0) },
			{ "tipo": "botijao", "em": Vector2(950.0, 372.0) },
			{ "tipo": "botijao", "em": Vector2(968.0, 377.0), "variante": 1 },
			{ "tipo": "botijao", "em": Vector2(986.0, 372.0), "variante": 2 },
			{ "tipo": "lenha", "em": Vector2(1100.0, 376.0) },
			{ "tipo": "lixeira", "em": Vector2(1168.0, 372.0), "variante": 2 },
			{ "tipo": "saco_de_lixo", "em": Vector2(1060.0, 378.0), "variante": 1 },
			{ "tipo": "engradado", "em": Vector2(1022.0, 376.0), "variante": 4 },
		],
		"mobilia": [
			# Salao: o balcao e a geladeira de bebida na parede da porta, a caixa de pizza do lado, as mesas de toalha xadrez.
			{ "tipo": "caixa", "em": Vector2(330.0, 60.0) },
			{ "tipo": "balcao", "em": Vector2(560.0, 50.0) },
			{ "tipo": "geladeira", "em": Vector2(668.0, 50.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(760.0, 62.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(880.0, 62.0), "variante": 1 },
			{ "tipo": "mesa_toalha", "em": Vector2(1000.0, 62.0), "variante": 2 },
			{ "tipo": "mesa_toalha", "em": Vector2(1120.0, 62.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(540.0, 136.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(660.0, 136.0), "variante": 1 },
			{ "tipo": "mesa_toalha", "em": Vector2(780.0, 136.0), "variante": 2 },
			{ "tipo": "mesa_toalha", "em": Vector2(1050.0, 136.0) },
			{ "tipo": "mesa_toalha", "em": Vector2(1150.0, 136.0), "variante": 1 },
			# Cozinha: o forno a lenha, a bancada de massa, a geladeira, o fogao e a pia na parede norte; a lenha no canto.
			{ "tipo": "forno_pizza", "em": Vector2(70.0, 219.0) },
			{ "tipo": "bancada", "em": Vector2(170.0, 203.0) },
			{ "tipo": "geladeira", "em": Vector2(245.0, 205.0) },
			{ "tipo": "fogao_industrial", "em": Vector2(310.0, 207.0) },
			{ "tipo": "bancada_cozinha", "em": Vector2(400.0, 201.0), "tamanho": Vector2(80.0, 26.0) },
			{ "tipo": "sacos_farinha", "em": Vector2(495.0, 205.0) },
			{ "tipo": "lenha", "em": Vector2(52.0, 352.0) },
			# Deposito: a prateleira, o freezer, farinha e engradados.
			{ "tipo": "prateleira", "em": Vector2(630.0, 209.0) },
			{ "tipo": "freezer", "em": Vector2(740.0, 207.0) },
			{ "tipo": "sacos_farinha", "em": Vector2(830.0, 205.0) },
			{ "tipo": "engradado", "em": Vector2(1010.0, 200.0), "variante": 1 },
			{ "tipo": "engradado", "em": Vector2(1040.0, 202.0), "variante": 2 },
			{ "tipo": "engradado", "em": Vector2(1150.0, 200.0) },
			{ "tipo": "latas", "em": Vector2(700.0, 340.0) },
		],
		"pisos": [["xadrez", Rect2(300.0, 20.0, 880.0, 135.0)], ["lajota", Rect2(20.0, 174.8, 522.0, 189.2)], ["cimento", Rect2(562.0, 174.8, 618.0, 49.2)], ["cimento", Rect2(562.0, 224.0, 318.0, 140.0)]],
	},

	# A Delegacia: predio publico em L, telha colonial de quatro aguas, branco
	# com barrado azul, grade em toda janela e o letreiro em cima da porta. So o
	# canto sudeste sai: a parede oeste dela e parte do cerco do tutorial, e o
	# recorte sudoeste abria um furo nele (conferir_mapa).
	{ "ponto": Vector2(1122.0, 712.0),
		"mobilia": [
			# Atendimento (frente): as mesas e o arquivo na divisoria, as cadeiras de espera, papel no chao.
			{ "tipo": "mesa_escritorio", "em": Vector2(300.0, 606.0) },
			{ "tipo": "mesa_escritorio", "em": Vector2(480.0, 606.0), "variante": 1 },
			{ "tipo": "mesa_escritorio", "em": Vector2(660.0, 606.0) },
			{ "tipo": "arquivo", "em": Vector2(800.0, 604.0) },
			{ "tipo": "cadeiras_espera", "em": Vector2(1000.0, 588.0) },
			{ "tipo": "cadeiras_espera", "em": Vector2(1080.0, 588.0) },
			{ "tipo": "mesa_escritorio", "em": Vector2(1340.0, 606.0), "variante": 1 },
			{ "tipo": "mesa_escritorio", "em": Vector2(1460.0, 606.0) },
			{ "tipo": "papeis", "em": Vector2(420.0, 690.0) },
			{ "tipo": "papeis", "em": Vector2(700.0, 730.0), "variante": 1 },
			{ "tipo": "papeis", "em": Vector2(950.0, 900.0) },
			# Carceragem e armas (fundo leste): duas celas com a porta aberta, o armario de armas com o documento.
			{ "tipo": "grade_cela", "em": Vector2(822.0, 200.0), "variante": 1, "tamanho": Vector2(196.0, 6.0) },
			{ "tipo": "grade_cela", "em": Vector2(1010.0, 200.0), "variante": 1, "tamanho": Vector2(180.0, 6.0) },
			{ "tipo": "grade_cela", "em": Vector2(920.0, 194.0), "tamanho": Vector2(6.0, 174.0) },
			{ "tipo": "colchao", "em": Vector2(790.0, 130.0), "tamanho": Vector2(40.0, 70.0) },
			{ "tipo": "vaso_sanitario", "em": Vector2(880.0, 44.0) },
			{ "tipo": "colchao", "em": Vector2(990.0, 130.0), "tamanho": Vector2(40.0, 70.0) },
			{ "tipo": "vaso_sanitario", "em": Vector2(1070.0, 44.0) },
			{ "tipo": "armario_de_armas", "em": Vector2(1300.0, 50.0), "documento": true },
			{ "tipo": "mesa_escritorio", "em": Vector2(1450.0, 56.0) },
			# Escritorio do delegado (fundo oeste): mesas, caixas de arquivo morto, papelada.
			{ "tipo": "mesa_escritorio", "em": Vector2(150.0, 56.0), "variante": 1 },
			{ "tipo": "mesa_escritorio", "em": Vector2(300.0, 56.0) },
			{ "tipo": "caixa", "em": Vector2(500.0, 60.0) },
			{ "tipo": "papeis", "em": Vector2(200.0, 300.0) },
			{ "tipo": "papeis", "em": Vector2(400.0, 420.0), "variante": 1 },
		],
		"pisos": [["granilite", Rect2(20.0, 572.4, 1520.0, 205.6)], ["granilite", Rect2(20.0, 778.0, 1100.0, 210.0)], ["granilite", Rect2(20.0, 20.0, 684.0, 532.4)], ["cimento", Rect2(724.0, 20.0, 816.0, 532.4)]],
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
		"mobilia": [
			# Deposito de apreensoes: moto, bicicletas, pneus e engradados.
			{ "tipo": "caixa", "em": Vector2(440.0, 60.0) },
			{ "tipo": "moto", "em": Vector2(200.0, 200.0) },
			{ "tipo": "bicicleta", "em": Vector2(320.0, 220.0) },
			{ "tipo": "bicicleta", "em": Vector2(360.0, 228.0) },
			{ "tipo": "pneu", "em": Vector2(600.0, 200.0) },
			{ "tipo": "pneu", "em": Vector2(614.0, 206.0) },
			{ "tipo": "engradado", "em": Vector2(700.0, 60.0), "variante": 1 },
			{ "tipo": "engradado", "em": Vector2(730.0, 62.0), "variante": 2 },
			{ "tipo": "papeis", "em": Vector2(500.0, 180.0) },
		],
		"pisos": [["cimento", Rect2(20.0, 20.0, 848.0, 224.0)]],
		"telhado": { "forma": "laje", "material": "laje", "tom": "suja" },
		"fachada": { "parede": "bloco", "tinta": "branco", "janelas": "grade", "altura": 56.0 },
		"extras": [{ "tipo": "caixa_dagua", "em": Vector2(0.15, 0.5) }, { "tipo": "ar_condicionado", "em": Vector2(0.6, 0.5) }] },

	# O Predio abandonado: quatro andares de laje, a quina sudeste desabada
	# (o recorte, com o entulho dela no chao), janelas quebradas e mato na
	# laje. O anexo, dois andares, do mesmo jeito.
	{ "ponto": Vector2(1293.0, 640.0),
		"mobilia": [
			# Saguao: a caixa na parede da frente e o acampamento de quem passou por aqui.
			{ "tipo": "caixa", "em": Vector2(100.0, 60.0) },
			{ "tipo": "colchao", "em": Vector2(600.0, 160.0), "tamanho": Vector2(50.0, 80.0) },
			{ "tipo": "fogareiro", "em": Vector2(560.0, 230.0) },
			{ "tipo": "latas", "em": Vector2(600.0, 250.0) },
			{ "tipo": "saco_de_lixo", "em": Vector2(660.0, 300.0), "variante": 1 },
			{ "tipo": "papeis", "em": Vector2(300.0, 400.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(450.0, 300.0), "variante": 4 },
			{ "tipo": "roupas", "em": Vector2(640.0, 190.0) },
			# Fundo oeste: a comoda e outro colchao.
			{ "tipo": "comoda", "em": Vector2(100.0, 704.0) },
			{ "tipo": "colchao", "em": Vector2(200.0, 900.0), "tamanho": Vector2(50.0, 80.0) },
			{ "tipo": "roupas", "em": Vector2(240.0, 960.0) },
			{ "tipo": "latas", "em": Vector2(120.0, 1100.0) },
			# Fundo leste: a estante e o que sobrou.
			{ "tipo": "estante", "em": Vector2(430.0, 698.0) },
			{ "tipo": "pneu", "em": Vector2(600.0, 900.0) },
			{ "tipo": "saco_de_lixo", "em": Vector2(650.0, 1000.0) },
			{ "tipo": "cadeira_plastico", "em": Vector2(500.0, 1100.0), "variante": 4 },
		],
		"recortes": [{ "canto": "sudeste", "tamanho": Vector2(260.0, 300.0), "cobertura": "desabou" }],
		"telhado": { "forma": "laje", "material": "laje", "tom": "velha" },
		"puxado": { "forma": "laje", "material": "laje", "tom": "velha", "altura": 170.0 },
		"fachada": { "parede": "reboco", "tinta": "cinza", "janelas": "quebradas", "altura": 170.0, "pichacao": true },
		"extras": [{ "tipo": "mato", "em": Vector2(0.3, 0.2) }, { "tipo": "mato", "em": Vector2(0.7, 0.55) },
			{ "tipo": "mato", "em": Vector2(0.2, 0.8) }, { "tipo": "entulho", "em": Vector2(0.55, 0.35) },
			{ "tipo": "caixa_dagua_tombada", "em": Vector2(0.75, 0.15) }, { "tipo": "buraco", "em": Vector2(0.45, 0.7) }],
		"enfeites": [{ "tipo": "saco_de_lixo", "em": Vector2(520.0, 1470.0), "variante": 1 }, { "tipo": "pneu", "em": Vector2(700.0, 1300.0) }] },
	{ "ponto": Vector2(1280.0, 630.0),
		"mobilia": [
			{ "tipo": "caixa", "em": Vector2(280.0, 60.0) },
			{ "tipo": "colchao", "em": Vector2(100.0, 400.0), "tamanho": Vector2(50.0, 80.0) },
			{ "tipo": "latas", "em": Vector2(200.0, 420.0) },
			{ "tipo": "saco_de_lixo", "em": Vector2(260.0, 600.0) },
		],
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
		# A mobilia fica em coordenada do predio (o cenario soma o canto); as
		# paredes do banheiro e os pisos vao para o mundo.
		if predio.has("mobilia"):
			alvo["mobilia"] = predio["mobilia"]
		var canto: Vector2 = (alvo["rect"] as Rect2).position
		if predio.has("paredes"):
			var paredes: Array = []
			for r in predio["paredes"]:
				paredes.append(Rect2((r as Rect2).position + canto, (r as Rect2).size))
			alvo["paredes_extras"] = paredes
		if predio.has("pisos"):
			var pisos: Array = []
			for piso in predio["pisos"]:
				pisos.append({ "tipo": piso[0], "rect": Rect2((piso[1] as Rect2).position + canto, (piso[1] as Rect2).size) })
			alvo["pisos_extras"] = pisos
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
