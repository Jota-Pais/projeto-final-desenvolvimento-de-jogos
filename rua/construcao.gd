## Uma construcao: a geometria dela por dentro, e o que tem dentro dela.
##
## **Nao e o mapa.** Onde cada coisa fica, e o que cada coisa e, esta no
## `rua/mapa.gd`. Aqui moram as regras que valem para qualquer predio do mapa -
## onde ficam as paredes, onde fica o vao da porta, como o interior se parte em
## quartos, que movel vai em cada quarto - e o que sai de um movel.
##
## Ate 09/09/2026 este arquivo era o `bairro.gd` e era o mapa inteiro. O mapa
## cresceu 100x em area e ganhou seis tipos de lugar; o que sobrou aqui e o que
## nao dependia de ser um bairro.
##
## ## A escala, e por que ela e essa
##
## **A referencia de tudo aqui era o corpo do jogador: 28 x 40 px**
## (`rua/jogador.tscn`), ou seja 40 px = 1 metro. Toda medida existe em relacao
## a ele. **Em 20/10/2026 o corpo caiu para 14 x 20 e o mundo ficou como
## estava** (Joao: "o mundo ta muito pequeno"): em corpos novos, tudo na tabela
## abaixo dobra. O metro continua sendo 40 px, que e o que o mapa e as
## ferramentas contam.
##
## Em 08/09/2026 a arquitetura cresceu ~1,8x e o jogador ficou do mesmo tamanho,
## que e o que da a sensacao de escala. O **movel cresceu bem menos** (~1,35x),
## de proposito: crescendo junto, o quarto continuaria igualmente cheio.
##
## | O que | Em corpos de jogador |
## |---|---|
## | quarto do fundo de uma casa | 9,8 x 6,6 |
## | vao de porta | 3,6 |
## | largura da rodovia | 10 |
##
## Descartavel: e greybox. O TileSet e o level design de verdade entram quando o
## layout parar de mudar. **Depois de mexer em qualquer numero daqui, rode o
## `rua/conferir_mapa.tscn` (F6)** - numero errado fecha caminho sem avisar.
##
## ## A porta em quatro direcoes (17/09/2026)
##
## Ate esta data toda a geometria vivia dentro de um booleano
## (`e_da_frente_ao_sul`): cada funcao tinha um `if` para o caso sul e outro
## para o caso norte, escritos a mao duas vezes. Isso nunca deu erro nenhum
## quando alguem esquecia o segundo `if` - so produzia casa virada para o mato
## em silencio, porque toda casa do mapa era norte ou sul.
##
## Agora a geometria e escrita **uma vez so**, num referencial canonico com a
## fachada sempre ao SUL (`_ao_mundo`/`_rect_mundo` fazem a volta para o
## mundo), e o caso `sul` e literalmente a identidade dessa volta. Provado em
## P1 por dois conferidores: uma regressao bit a bit contra as 91 construcoes
## do mapa de entao (provou que norte/sul nao se mexeu) e o `conferir_
## construcao.tscn` que continua aqui (prova leste/oeste nas 4 orientacoes). A
## regressao cumpriu o papel dela e saiu do repositorio em P14 - o resultado
## dela (zero divergencia) e permanente, o teste era so a prova pontual.
##
## **Uma correcao saiu dessa reescrita, e nao so refatoracao**: o codigo antigo
## media a divisoria interna com a mesma formula `Rect2(x, y, largura, PAREDE)`
## nos dois ramos de `if e_da_frente_ao_sul`, mas "crescer no y positivo" e rumo
## a fachada para porta sul e rumo ao fundo para porta norte - entao a sala de
## uma casa norte saia PAREDE (20 px) mais funda que a de uma casa sul com a
## mesma planta, sem ninguem ter notado. Escrita uma vez so, a formula trata as
## duas orientacoes do mesmo jeito - como o sul sempre tratou, que e a maioria
## das construcoes de hoje.

const PAREDE := 20.0
## Vao de porta: 3,6 corpos de largura. Generoso de proposito - porta apertada
## com zumbi atras e frustracao, nao tensao.
const VAO := 100.0

## As quatro direcoes que uma porta pode encarar, com o vetor unitario que sai
## por ela (a "normal" da fachada, apontando para fora do predio).
const LADOS := {
	"norte": Vector2(0.0, -1.0),
	"sul":   Vector2(0.0, 1.0),
	"leste": Vector2(1.0, 0.0),
	"oeste": Vector2(-1.0, 0.0),
}

## A entrada de carro: largura, e quanto ela avanca da fachada para fora.
##
## Antes ela ia da fachada ate a calcada da rua principal, o que so fazia
## sentido quando existia uma rua principal so. Agora e comprimento fixo, e
## serve em qualquer lugar do mapa.
const ENTRADA_DE_CARRO := 180.0
const ENTRADA_DE_CARRO_COMPRIMENTO := 220.0

## O tamanho de cada tipo de predio, **em metros de gente** (40 px = 1 m).
##
## Existe desde 09/09/2026 a noite, porque os predios grandes estavam absurdos:
## o mercado tinha 105 x 55 m e a delegacia 90 x 65 m - um hipermercado e um
## forum, e nao um mercadinho e uma delegacia de cidade pequena. Cada um era um
## numero escrito na mao dentro do gerador do lugar, sem ninguem comparando.
##
## | tipo | px | metros |
## |---|---|---|
## | casa | 520 x 420 | 13 x 10,5 |
## | comercio | 560 x 440 | 14 x 11 |
## | galpao | 420 x 340 | 10,5 x 8,5 |
## | posto | 720 x 480 | 18 x 12 |
## | mercado | 1360 x 660 | 34 x 16,5 |
## | delegacia | 1040 x 700 | 26 x 17,5 |
## | mansao | 880 x 640 | 22 x 16 |
## | garagem | 460 x 380 | 11,5 x 9,5 |
##
## As casas do bairro nao saem daqui: sao as de 650 x 520 tunadas a mao em
## 08/09, e mexer nelas seria re-errar o que o conferir ja validou.
const TAMANHOS := {
	"casa": Vector2(520.0, 420.0),
	"comercio": Vector2(560.0, 440.0),
	"galpao": Vector2(420.0, 340.0),
	"posto": Vector2(720.0, 480.0),
	"mercado": Vector2(1360.0, 660.0),
	"delegacia": Vector2(1040.0, 700.0),
	"mansao": Vector2(880.0, 640.0),
	"garagem": Vector2(460.0, 380.0),
	# A ponta oeste da fita comercial da cidade (17/09/2026, P8) - um deposito
	# de estoque, mais raso que uma loja e sem vitrine.
	"armazem": Vector2(900.0, 560.0),
	# Predios publicos novos (17/09/2026, P16 - pedido do dono: "hospital,
	# bombeiro e etc"). Hospital entre a loja e a delegacia em porte (15 x
	# 17,5 m - profundidade 700, nao 850: o lote dele (QC-hospital) tem
	# 1000 px de folga ate o cotovelo da Avenida Central, e 850 estourava
	# essa folga por 10 px); bombeiros do porte de um posto pequeno
	# (17 x 11,5 m).
	"hospital": Vector2(600.0, 700.0),
	"bombeiros": Vector2(680.0, 460.0),
}

## **Casa nao e um tamanho so** (16/09/2026). Ate aqui toda casa do mapa media
## 520 x 420, e fileira de casa identica le como conjunto habitacional - no
## Project Zomboid duas vizinhas quase nunca tem a mesma planta.
##
## Sao **plantas**, e nao sorteio livre: cada uma e uma casa plausivel de
## suburbio - a rasa e larga, a estreita e funda, a pequena de esquina.
##
## **Provisorio** (ate P7): sera substituida por `CONJUNTOS_DE_PLANTA` quando
## `lugares.gd` passar a gerar sobre `quadras.gd`. Ate la, o mapa de hoje ainda
## usa `planta_de_casa`/`recuo_de_casa` por indice, e essas duas funcoes nao
## podem quebrar.
##
## Duas regras que as amarram:
##
##  - **nenhuma passa de 520 de frente**, que e a vaga de lote da cidade. Lote
##    tem largura igual no mundo real; o que varia e a casa em cima dele, e
##    respeitar isso e o que deixa a geometria da quadra valida;
##  - **nenhuma e menor que o galpao** (420 x 340), que e o menor predio que
##    ainda cabe movel alcancavel dentro. Menor que isso o conferir_mapa acusa.
const PLANTAS_DE_CASA := [
	Vector2(520.0, 420.0),
	Vector2(480.0, 460.0),
	Vector2(520.0, 380.0),
	Vector2(460.0, 430.0),
	Vector2(500.0, 500.0),
	Vector2(440.0, 400.0),
	Vector2(520.0, 460.0),
]

## Quanto a fachada pode recuar a mais da rua, em cima do recuo do lote.
##
## **Fachada alinhada na regua e o que faz uma quadra parecer desenhada e nao
## construida.** Casa de verdade nao nasce toda na mesma linha: uma tem garagem
## na frente, outra tem jardim maior. Tres degraus de 60 (1,5 m) ja quebram a
## linha sem baguncar o lote.
const RECUOS_DE_CASA := [0.0, 60.0, 120.0]

## A planta e o recuo de um lote, sempre os mesmos para o mesmo lote.
##
## **Embaralha antes do resto.** `indice % n` puro devolve as plantas em ciclo
## (1,2,3,1,2,3) e a fileira volta a parecer conjunto habitacional, so que com
## sete modelos em vez de um. O embaralho e uma multiplicacao por numero primo
## grande - barato, deterministico, e sem estado nenhum para carregar.
##
## Provisorio (ver `PLANTAS_DE_CASA`) - o sucessor e `embaralhar(chave)` mais
## `planta_de(tipo, chave)`, indexados por chave e nao por indice de geracao.
static func _embaralhar_indice(indice: int) -> int:
	return absi(indice * 2654435761) % 1000003

static func planta_de_casa(indice: int) -> Vector2:
	return PLANTAS_DE_CASA[_embaralhar_indice(indice) % PLANTAS_DE_CASA.size()]

static func recuo_de_casa(indice: int) -> float:
	return RECUOS_DE_CASA[_embaralhar_indice(indice + 7919) % RECUOS_DE_CASA.size()]

## **Os conjuntos de planta por zona** (17/09/2026, arquitetura nova do mapa,
## secao 3.6). Substitui `PLANTAS_DE_CASA` a partir de P7, quando `lugares.gd`
## passar a gerar sobre `rua/quadras.gd` e a identidade vira chave de texto em
## vez de indice de geracao.
##
## Frente x fundo, **em relacao a fachada** (frente = o lado que da para a rua,
## fundo = a profundidade) - nao em x/y de mundo. Quem poe o predio no lote
## transpoe quando a porta e leste/oeste (ver `predio_no_lote`, `rua/lotes.gd`).
##
## `suburbio`: 9 plantas de 12-18 x 12-16 tiles (480-720 x 480-640 px), a faixa
## medida em Rosewood/Riverside. `cidade`: 7 plantas de lote de grade, um pouco
## mais estreitas e mais fundas (a quadra da grade e mais raza). `fita`: 5
## plantas de comercio de rua, sempre com a frente menor que o fundo - loja de
## fita e funda, nao larga.
const CONJUNTOS_DE_PLANTA := {
	"suburbio": [
		Vector2(560.0, 480.0), Vector2(640.0, 560.0), Vector2(480.0, 600.0),
		Vector2(600.0, 520.0), Vector2(520.0, 640.0), Vector2(720.0, 560.0),
		Vector2(600.0, 600.0), Vector2(560.0, 560.0), Vector2(680.0, 480.0),
	],
	"cidade": [
		Vector2(520.0, 420.0), Vector2(480.0, 460.0), Vector2(520.0, 380.0),
		Vector2(460.0, 430.0), Vector2(500.0, 500.0), Vector2(440.0, 400.0),
		Vector2(520.0, 460.0),
	],
	"fita": [
		Vector2(480.0, 640.0), Vector2(440.0, 720.0), Vector2(520.0, 680.0),
		Vector2(460.0, 760.0), Vector2(500.0, 700.0),
	],
}

## A planta de um predio, pela sua chave estavel - nao pelo indice de geracao
## (`chave` sobrevive a inserir ou mover outro predio; indice, nao). `tipo` e a
## chave de `CONJUNTOS_DE_PLANTA` (nao o tipo de construcao) - "suburbio",
## "cidade" ou "fita".
static func planta_de(conjunto: String, chave: String) -> Vector2:
	var plantas: Array = CONJUNTOS_DE_PLANTA[conjunto]
	return plantas[embaralhar(chave) % plantas.size()]

## Quantos quartos cada tipo de construcao tem. Tres quartos ganham divisoria
## interna; um quarto e salao unico.
const QUARTOS_POR_TIPO := {
	"casa": 3,
	"comercio": 1,
	"galpao": 1,
	"posto": 1,
	"mercado": 1,
	"delegacia": 3,
	"mansao": 3,
	"garagem": 1,
	"armazem": 1,
	"hospital": 3,
	"bombeiros": 1,
	# Os tipos do desenho de 30/09/2026 (ver mapa.gd, ROTULOS). Quantos
	# quartos cada um tem e **proposta**: tres onde o predio e grande e tem
	# fundo que vale a caminhada, um salao onde e loja ou galpao.
	"escola": 3,
	"igreja": 1,
	"prefeitura": 3,
	"prisao": 3,
	"campo": 1,
	"farmacia": 1,
	"academia": 1,
	"banco": 3,
	"eta": 1,
	"radio": 1,
	"hotel": 3,
	"bar": 1,
	"restaurante": 1,
	# A Cover Pizzaria (21/10/2026): salao na frente, cozinha e deposito no
	# fundo.
	"pizzaria": 3,
	"lojas": 1,
	"predio_em_construcao": 1,
	"predio_abandonado": 3,
	# O pedaco secundario de um predio que o tracador partiu em dois (uma
	# asa, um puxado): um salao com uma caixa.
	"anexo": 1,
	# A casa rasa demais para a divisoria interna (ver UM_QUARTO_SO): um
	# comodo so, com a comoda e a geladeira na parede do fundo.
	"casa_pequena": 1,
}

## O tipo de um quarto so que substitui cada tipo de tres quartos quando o
## predio e pequeno demais para a divisoria interna (ver
## `Mapa._encolher_quem_nao_cabe`). Quem nao esta aqui vira "galpao".
const UM_QUARTO_SO := {
	"casa": "casa_pequena",
	"delegacia": "comercio",
	"mansao": "comercio",
	"hospital": "farmacia",
	"escola": "comercio",
	"prefeitura": "radio",
	"prisao": "anexo",
	"banco": "anexo",
	"hotel": "bar",
	"predio_abandonado": "anexo",
	"pizzaria": "restaurante",
}

## Que movel entra em cada quarto, por tipo de construcao.
##
## A ordem importa: o primeiro quarto e a sala, onde a porta da rua da, e o
## **ultimo e o mais fundo** - o que custa mais para chegar. E onde vai o
## documento, quando o lugar tem um.
##
## Desde 30/09/2026 todo movel rende a mesma coisa (balas), entao o que
## diferencia um lugar do outro e quantos moveis ele tem e quanto cada um
## custa de vasculho (`MOVEIS[tipo].duracao`) - nao mais o que sai deles.
const MOVEIS_POR_QUARTO := {
	"casa": [["estante"], ["comoda"], ["geladeira"]],
	"comercio": [["armario", "armario", "geladeira", "caixa", "caixa"]],
	"galpao": [["caixa"]],
	"posto": [["prateleira", "prateleira", "geladeira", "caixa"]],
	"mercado": [["prateleira", "prateleira", "prateleira", "geladeira", "geladeira", "caixa"]],
	"delegacia": [["arquivo"], ["caixa"], ["armario_de_armas"]],
	"mansao": [["comoda"], ["armario"], ["estante"]],
	"garagem": [["caixa"]],
	"armazem": [["caixa", "prateleira", "prateleira", "caixa"]],
	# Hospital: recepcao (maca comum) -> farmacia (remedio de prateleira) ->
	# sala de curativos no fundo, com a seringa - o quarto mais fundo custa
	# mais para chegar, mesma regra da delegacia com o armario de armas.
	"hospital": [["maca", "maca"], ["armario_de_remedios"], ["armario_de_seringas"]],
	"bombeiros": [["armario_de_bombeiro", "armario_de_bombeiro"]],
	# Os tipos do desenho de 30/09/2026, com os moveis que ja existem. O que
	# cada lugar da e **proposta** - loot por lugar e assunto de mesa.
	"escola": [["estante", "estante"], ["armario"], ["caixa", "estante"]],
	"igreja": [["armario", "caixa"]],
	"prefeitura": [["arquivo"], ["estante", "estante"], ["arquivo", "caixa"]],
	"prisao": [["arquivo"], ["caixa", "caixa"], ["armario_de_armas"]],
	"campo": [["armario", "caixa", "geladeira"]],
	"farmacia": [["armario_de_remedios", "armario_de_remedios", "prateleira"]],
	"academia": [["armario", "armario", "geladeira"]],
	"banco": [["caixa"], ["arquivo"], ["armario"]],
	"eta": [["caixa", "caixa", "prateleira"]],
	"radio": [["estante", "arquivo"]],
	"hotel": [["comoda"], ["comoda", "armario"], ["geladeira", "estante"]],
	"bar": [["geladeira", "geladeira", "caixa", "armario"]],
	"restaurante": [["geladeira", "geladeira", "prateleira", "caixa"]],
	# Os mesmos quatro moveis do restaurante, so que cada um no comodo dele: a
	# geladeira de bebida e a caixa (de pizza) no salao, a outra geladeira na
	# cozinha, a prateleira no deposito - um por parede, que dois juntos se
	# encavalam (`posicoes_de_movel`). Mesa, balcao e forno sao enfeite (rua/arquitetura.gd), nao
	# vasculho - o loot nao muda.
	"pizzaria": [["geladeira", "caixa"], ["geladeira"], ["prateleira"]],
	"lojas": [["armario", "prateleira", "caixa", "armario", "prateleira"]],
	"predio_em_construcao": [["caixa", "caixa"]],
	"predio_abandonado": [["caixa"], ["comoda"], ["estante"]],
	"anexo": [["caixa"]],
	"casa_pequena": [["comoda", "geladeira"]],
}
const MOVEIS := {
	"geladeira": { "rotulo": "Geladeira", "duracao": 3.5, "tamanho": Vector2(72.0, 54.0), "cor": Color("6e7a76") },
	"armario": { "rotulo": "Armário", "duracao": 3.0, "tamanho": Vector2(102.0, 46.0), "cor": Color("6b5b3f") },
	"comoda": { "rotulo": "Cômoda", "duracao": 2.5, "tamanho": Vector2(84.0, 48.0), "cor": Color("5e4c38") },
	"estante": { "rotulo": "Estante", "duracao": 4.0, "tamanho": Vector2(112.0, 38.0), "cor": Color("57452f") },
	"caixa": { "rotulo": "Caixa", "duracao": 1.8, "tamanho": Vector2(56.0, 56.0), "cor": Color("6d5b45") },
	"carro": { "rotulo": "Carro abandonado", "duracao": 3.0, "tamanho": Vector2(180.0, 80.0), "cor": Color("5c4a44") },
	# O veiculo comprido do desenho (30/09/2026): os do camping de motorhomes
	# e os onibus parados na rua. Mesmo loot de carro, mais comida.
	"motorhome": { "rotulo": "Motorhome", "duracao": 3.5, "tamanho": Vector2(400.0, 170.0), "cor": Color("5c4a44") },
	# O trator da fazenda (rotulo lido no desenho em 15/10/2026; ver
	# Mapa.VEICULOS_ROTULADOS). Numeros proposta; sprite trator-em-pe.png.
	"trator": { "rotulo": "Trator", "duracao": 2.5, "tamanho": Vector2(110.0, 70.0), "cor": Color("5a5444") },
	# As caminhonetes (fazenda e galpao do velho louco), idem.
	"caminhonete": { "rotulo": "Caminhonete", "duracao": 3.0, "tamanho": Vector2(200.0, 84.0), "cor": Color("4f5560") },
	"lata": { "rotulo": "Lata de lixo", "duracao": 1.5, "tamanho": Vector2(48.0, 48.0), "cor": Color("4a4f45") },
	# As pedras soltas no chao (21/10/2026, Joao: "pega pedras no chao"):
	# um vasculho rapido que so rende pedra, para arremessar.
	"pedras": { "rotulo": "Pedras", "duracao": 0.6, "tamanho": Vector2(34.0, 22.0), "cor": Color("77736b") },
	# Os quatro que chegaram com os lugares novos de 09/09/2026. O armario de
	# armas da delegacia e o movel mais caro do mapa: 5,5 s de vasculho
	# ininterrupto, com a delegacia sendo o lugar mais povoado.
	"prateleira": { "rotulo": "Prateleira", "duracao": 3.2, "tamanho": Vector2(156.0, 42.0), "cor": Color("6b6152") },
	"bomba": { "rotulo": "Bomba de combustível", "duracao": 4.0, "tamanho": Vector2(56.0, 86.0), "cor": Color("7a5a4a") },
	"arquivo": { "rotulo": "Arquivo", "duracao": 4.2, "tamanho": Vector2(88.0, 52.0), "cor": Color("5a5f63") },
	# Os quatro armarios especiais partilham o sprite do armario de metal
	# (`"desenho"`, rua/arte/objetos/armario-de-metal.png) tingido pela `cor`
	# (14/10/2026).
	"armario_de_armas": { "rotulo": "Armário de armas", "duracao": 5.5, "tamanho": Vector2(108.0, 50.0), "cor": Color("4e5a55"), "desenho": "armario-de-metal" },
	# Hospital e corpo de bombeiros (17/09/2026, P16).
	"maca": { "rotulo": "Maca", "duracao": 2.8, "tamanho": Vector2(90.0, 42.0), "cor": Color("8a9a94") },
	"armario_de_remedios": { "rotulo": "Armário de remédios", "duracao": 3.2, "tamanho": Vector2(84.0, 44.0), "cor": Color("7d8a84"), "desenho": "armario-de-metal" },
	"armario_de_seringas": { "rotulo": "Armário de seringas", "duracao": 4.5, "tamanho": Vector2(70.0, 40.0), "cor": Color("6f7d76"), "desenho": "armario-de-metal" },
	"armario_de_bombeiro": { "rotulo": "Armário de bombeiro", "duracao": 4.0, "tamanho": Vector2(104.0, 48.0), "cor": Color("6b3f3a"), "desenho": "armario-de-metal" },
}

## O que sai de um movel, desde 30/09/2026: **balas, e so balas** - mais o
## documento, onde o mapa declarou um. O Joao tirou o loot generico do jogo
## (lata de comida, pilha, pano sujo, as tabelas por tipo de movel) para
## enxugar: voce comeca com a Beretta, e o que o vasculho rende e municao. A
## tabela CONTEUDO que vivia aqui esta no git.
##
## As balas sao **equipamento e nao loot**: nao ocupam vaga na mochila e nao se
## perdem no dia que deu errado. Ver rua/mochila.gd.
##
## **Um tipo de municao por calibre** (05/10/2026, Joao: "faz um tipo de
## municao pra cada"): calibre -> o nome do achado que sai do movel. Cada arma
## usa a municao do calibre dela (`municao` na ficha, rua/arma.gd): a Beretta
## e a Fireagle dividem o 9mm, a Doze e a Benelli o calibre 12. Cada caixinha
## do vasculho sai de um calibre sorteado com peso igual (rua/cenario.gd) -
## raridade por calibre e decisao de mesa.
const MUNICOES := {
	".38": "balas .38",
	"9mm": "balas 9mm",
	"12": "cartuchos calibre 12",
	".40": "balas .40",
	"7,62": "balas 7,62",
	"5,56": "balas 5,56",
}

## Quantas balas vem em cada achado, de qualquer calibre. E uma caixinha, nao
## uma bala. **Proposta** - calibragem, junto com Travessia.BALAS_DE_COMECO.
const MUNICAO_POR_ACHADO := 6

## O que cada movel rende, por tipo (21/10/2026, Joao: "nao quero mais que
## qualquer que ele vasculhar ache balas, vou criar alguns outros tipos de
## itens pra serem encontrados"): a chance de uma caixinha de balas e a de uma
## garrafa, e as pedras do monte de pedras. Garrafa na geladeira e na
## prateleira, bala no armario e no carro. **Proposta** - a tabela e da mesa,
## e e aqui que os itens novos da equipe entram.
const RENDE := {
	"geladeira": { "balas": 0.1, "garrafa": 0.7 },
	"prateleira": { "balas": 0.35, "garrafa": 0.45 },
	"armario": { "balas": 0.55, "garrafa": 0.15 },
	"comoda": { "balas": 0.45, "garrafa": 0.1 },
	"estante": { "balas": 0.4, "garrafa": 0.2 },
	"caixa": { "balas": 0.45, "garrafa": 0.15 },
	"arquivo": { "balas": 0.4, "garrafa": 0.0 },
	"carro": { "balas": 0.45, "garrafa": 0.3 },
	"caminhonete": { "balas": 0.5, "garrafa": 0.3 },
	"motorhome": { "balas": 0.5, "garrafa": 0.4 },
	"trator": { "balas": 0.3, "garrafa": 0.2 },
	"lata": { "balas": 0.05, "garrafa": 0.6 },
	"armario_de_armas": { "balas": 1.0, "balas_a_mais": 1, "garrafa": 0.0 },
	"pedras": { "balas": 0.0, "garrafa": 0.0, "pedras": 3 },
}
const RENDE_PADRAO := { "balas": 0.5, "garrafa": 0.15 }

## Se um achado e municao (de qualquer calibre).
static func e_municao(achado: String) -> bool:
	return MUNICOES.values().has(achado)

## O calibre de um achado de municao; "" se nao for municao.
static func calibre_de(achado: String) -> String:
	for calibre in MUNICOES:
		if MUNICOES[calibre] == achado:
			return calibre
	return ""



## Os documentos - o item que o vasculho entrega para a pesquisa da cura.
##
## **Sao placeholders, e nada neles foi decidido pela equipe**: nem o nome, nem
## o que cada um diz, nem que lugar do mapa guarda qual. O que existe aqui e a
## quantidade de itens distintos que o mapa precisa distribuir para a partida ter
## como ser ganha - a historia que eles eventualmente contem e conversa da mesa,
## e ate la nao ha nenhuma pendurada neles.
##
## Sao seis porque seis predios estao marcados com "documento": true no
## `rua/lugares.gd`. Sao distintos entre si so para o conferir_mapa conseguir
## acusar documento repetido.
const DOCUMENTOS := [
	"documento 1",
	"documento 2",
	"documento 3",
	"documento 4",
	"documento 5",
	"documento 6",
]

# ------------------------------------------------------------------ geometria

## Se um achado e documento e nao comida.
##
## Documento conta separado da comida e e o que a casa soma na pesquisa - entao
## alguem precisa saber distinguir os dois. Fica aqui, e pela propria lista,
## para nao existir uma segunda fonte de verdade sobre o que e documento.
static func e_documento(achado: String) -> bool:
	return DOCUMENTOS.has(achado)

## Casca de compatibilidade: `porta == "sul"`. A geometria de verdade nao
## pergunta mais isso a ninguem - ela pergunta `construcao["porta"]` direto -,
## mas o resto do codigo (P2 em diante substitui) ainda faz essa pergunta em
## alguns lugares.
static func e_da_frente_ao_sul(construcao: Dictionary) -> bool:
	return construcao["porta"] == "sul"

## O vetor unitario que sai da fachada para fora - "para onde a porta olha".
static func normal_de(construcao: Dictionary) -> Vector2:
	return LADOS[construcao["porta"]]

## O vetor unitario AO LONGO da fachada (perpendicular ao normal). Fachada
## norte/sul: ao longo de x. Fachada leste/oeste: ao longo de y.
static func eixo_da_fachada(construcao: Dictionary) -> Vector2:
	var normal := normal_de(construcao)
	return Vector2(absf(normal.y), absf(normal.x))

## `frente` (o quanto o predio mede ao longo da propria fachada) e
## `profundidade` (o quanto ele mede da fachada ate o fundo), em px - nao em
## x/y de mundo. Para fachada norte/sul isso e (size.x, size.y); para
## leste/oeste e transposto, porque a fachada passou a ser o lado vertical.
static func _frente(rect: Rect2, porta: String) -> float:
	return rect.size.y if (porta == "leste" or porta == "oeste") else rect.size.x

static func _profundidade(rect: Rect2, porta: String) -> float:
	return rect.size.x if (porta == "leste" or porta == "oeste") else rect.size.y

## A frente e o fundo de uma construcao inteira, para quem esta fora deste
## arquivo (o mapa decide por elas se o predio cabe tres quartos).
static func frente_de(construcao: Dictionary) -> float:
	return _frente(construcao["rect"], construcao["porta"])

static func profundidade_de(construcao: Dictionary) -> float:
	return _profundidade(construcao["rect"], construcao["porta"])

## Leva um ponto do referencial CANONICO (fachada sempre ao SUL, origem no
## canto onde fachada e fundo se encontram do lado "esquerdo") para o mundo.
## `p.x` anda ao longo da fachada; `p.y` anda do fundo (p.y=0) ate a fachada
## (p.y=profundidade).
##
##   sul   -> identidade (e por isso a regressao bit a bit prova tanto faz
##            escrever a geometria contra o rect direto ou passar por aqui)
##   norte -> espelho em y
##   leste, oeste -> transposicao (com espelho no caso oeste)
##
## Como as quatro sao isometrias de 90 graus, todo retangulo canonico convertido
## por `_rect_mundo` continua axial - fisica, navegacao e `draw_rect` nao
## percebem a diferenca.
static func _ao_mundo(rect: Rect2, porta: String, p: Vector2) -> Vector2:
	match porta:
		"sul":
			return rect.position + p
		"leste":
			return Vector2(rect.position.x + p.y, rect.position.y + p.x)
		"oeste":
			return Vector2(rect.end.x - p.y, rect.position.y + p.x)
		_:  # norte
			return Vector2(rect.position.x + p.x, rect.end.y - p.y)

## Um retangulo canonico (posicao `p`, tamanho `tamanho`) convertido para o
## mundo. Calcula os dois cantos e monta o retangulo pelo min/max, em vez de
## tentar adivinhar formula por orientacao - assim funciona para as quatro sem
## repetir logica.
static func _rect_mundo(rect: Rect2, porta: String, p: Vector2, tamanho: Vector2) -> Rect2:
	var a := _ao_mundo(rect, porta, p)
	var b := _ao_mundo(rect, porta, p + tamanho)
	return Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(b.x - a.x), absf(b.y - a.y))

## O centro do vao da porta, na fachada - a 35% do comprimento dela.
static func porta_de(construcao: Dictionary) -> Vector2:
	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	var profundidade := _profundidade(rect, porta)
	return _ao_mundo(rect, porta, Vector2(frente * 0.35, profundidade - PAREDE / 2.0))

## As quatro paredes externas, com a da fachada partida em duas pelo vao.
static func paredes_externas(construcao: Dictionary) -> Array[Rect2]:
	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	var profundidade := _profundidade(rect, porta)
	var meio := frente * 0.35

	var lista: Array[Rect2] = []
	lista.append(_rect_mundo(rect, porta, Vector2(0.0, 0.0), Vector2(frente, PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(0.0, 0.0), Vector2(PAREDE, profundidade)))
	lista.append(_rect_mundo(rect, porta, Vector2(frente - PAREDE, 0.0), Vector2(PAREDE, profundidade)))
	lista.append(_rect_mundo(rect, porta, Vector2(0.0, profundidade - PAREDE),
		Vector2(meio - VAO / 2.0, PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(meio + VAO / 2.0, profundidade - PAREDE),
		Vector2(frente - meio - VAO / 2.0, PAREDE)))
	var recortes := recortes_de(construcao)
	if recortes.is_empty():
		return lista
	# Com recorte, a parede do retangulo sai onde o canto foi tirado, e as duas
	# bordas do recorte que ficam dentro do retangulo viram parede.
	var cortada := menos_todos(lista, recortes)
	for recorte in recortes:
		cortada.append_array(_paredes_do_recorte(rect, recorte))
	return cortada

## O retangulo de piso, ja descontadas as paredes externas. Nao depende da
## porta: e um recuo simetrico de PAREDE nas quatro bordas do mundo, e isso vale
## para as quatro orientacoes sem precisar do referencial canonico. Com
## recorte, e a caixa do piso - o piso de verdade e `pisos_de`.
static func interior_de(construcao: Dictionary) -> Rect2:
	var r: Rect2 = construcao["rect"]
	return Rect2(r.position + Vector2.ONE * PAREDE, r.size - Vector2.ONE * PAREDE * 2.0)

## O piso como retangulos: o interior menos os recortes (e a parede deles).
static func pisos_de(construcao: Dictionary) -> Array[Rect2]:
	var interior: Array[Rect2] = [interior_de(construcao)]
	return menos_todos(interior, _recortes_com_parede(construcao))

# --- a planta com recortes (21/10/2026) ---------------------------------------

## Os recortes da planta (Joao, 21/10/2026: "pode mudar a planta"): cantos
## tirados do retangulo, que viram quintal, varanda ou garagem - a casa vira L
## (um recorte), T ou degrau (dois). Cada recorte e { "canto", "tamanho" }, em
## px de mundo, e o canto e o do MUNDO (noroeste, nordeste, sudoeste,
## sudeste), nao o da fachada: quem escreve esta olhando o mapa. O dado mora
## em rua/arquitetura.gd. Fora dos recortes tudo e como sempre foi - e
## construcao sem recorte da exatamente o que dava antes.
const CANTOS := {
	"noroeste": Vector2(0.0, 0.0),
	"nordeste": Vector2(1.0, 0.0),
	"sudoeste": Vector2(0.0, 1.0),
	"sudeste": Vector2(1.0, 1.0),
}

## Os recortes da construcao em mundo.
static func recortes_de(construcao: Dictionary) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	var r: Rect2 = construcao["rect"]
	for recorte in construcao.get("recortes", []):
		var canto: Vector2 = CANTOS[recorte["canto"]]
		var tamanho: Vector2 = recorte["tamanho"]
		lista.append(Rect2(r.position + (r.size - tamanho) * canto, tamanho))
	return lista

static func _recortes_com_parede(construcao: Dictionary) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	for recorte in recortes_de(construcao):
		lista.append(recorte.grow(PAREDE).intersection(construcao["rect"]))
	return lista

## Se o ponto esta dentro da construcao: no retangulo e fora dos recortes. E o
## que decide "estar dentro" (o telhado que sai, Mapa.construcao_em).
static func contem(construcao: Dictionary, ponto: Vector2) -> bool:
	if not (construcao["rect"] as Rect2).has_point(ponto):
		return false
	for recorte in recortes_de(construcao):
		if recorte.has_point(ponto):
			return false
	return true

## As duas paredes de um recorte de canto: as bordas dele que ficam dentro do
## retangulo, com a parede do lado de dentro da casa. A vertical cobre a
## quina; a horizontal encosta nela.
static func _paredes_do_recorte(rect: Rect2, n: Rect2) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	var em_cima := n.position.y > rect.position.y + 0.5
	var embaixo := n.end.y < rect.end.y - 0.5
	var y0 := n.position.y - (PAREDE if em_cima else 0.0)
	var y1 := n.end.y + (PAREDE if embaixo else 0.0)
	if n.position.x > rect.position.x + 0.5:
		lista.append(Rect2(n.position.x - PAREDE, y0, PAREDE, y1 - y0))
	if n.end.x < rect.end.x - 0.5:
		lista.append(Rect2(n.end.x, y0, PAREDE, y1 - y0))
	if em_cima:
		lista.append(Rect2(n.position.x, n.position.y - PAREDE, n.size.x, PAREDE))
	if embaixo:
		lista.append(Rect2(n.position.x, n.end.y, n.size.x, PAREDE))
	return lista

## `a` menos `b`: ate quatro retangulos (faixa de cima, de baixo e os dois
## lados da faixa do meio). O que sobra fino demais e jogado fora.
static func menos(a: Rect2, b: Rect2) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	var corte := a.intersection(b)
	if corte.get_area() < 0.5:
		lista.append(a)
		return lista
	var pedacos := [
		Rect2(a.position.x, a.position.y, a.size.x, corte.position.y - a.position.y),
		Rect2(a.position.x, corte.end.y, a.size.x, a.end.y - corte.end.y),
		Rect2(a.position.x, corte.position.y, corte.position.x - a.position.x, corte.size.y),
		Rect2(corte.end.x, corte.position.y, a.end.x - corte.end.x, corte.size.y),
	]
	for p in pedacos:
		if p.size.x > 0.5 and p.size.y > 0.5:
			lista.append(p)
	return lista

static func menos_todos(lista: Array[Rect2], buracos: Array[Rect2]) -> Array[Rect2]:
	var fora: Array[Rect2] = lista.duplicate()
	for b in buracos:
		var proxima: Array[Rect2] = []
		for a in fora:
			proxima.append_array(menos(a, b))
		fora = proxima
	return fora

static func _maior(lista: Array[Rect2]) -> Rect2:
	var melhor := Rect2()
	for r in lista:
		if r.get_area() > melhor.get_area():
			melhor = r
	return melhor

## A planta em volumes para o telhado: colunas norte-sul, cortadas onde um
## recorte comeca ou acaba, e coladas de volta quando duas vizinhas tem o
## mesmo comeco e fim. Cada coluna e um retangulo com a borda de baixo (sul)
## na borda da planta - e ali que a fachada aparece. Sem recorte, e o
## retangulo inteiro.
static func volumes_de(construcao: Dictionary) -> Array[Rect2]:
	var r: Rect2 = construcao["rect"]
	var recortes := recortes_de(construcao)
	var lista: Array[Rect2] = []
	if recortes.is_empty():
		lista.append(r)
		return lista
	var xs: Array[float] = [r.position.x, r.end.x]
	for n in recortes:
		for x in [n.position.x, n.end.x]:
			if x > r.position.x + 0.5 and x < r.end.x - 0.5 and not xs.has(x):
				xs.append(x)
	xs.sort()
	for i in xs.size() - 1:
		var xa := xs[i]
		var xb := xs[i + 1]
		var ya := r.position.y
		var yb := r.end.y
		for n in recortes:
			if n.position.x <= xa + 0.5 and n.end.x >= xb - 0.5:
				if n.position.y <= r.position.y + 0.5:
					ya = maxf(ya, n.end.y)
				else:
					yb = minf(yb, n.position.y)
		if yb - ya < 1.0:
			continue
		var coluna := Rect2(xa, ya, xb - xa, yb - ya)
		if not lista.is_empty():
			var anterior: Rect2 = lista.back()
			if is_equal_approx(anterior.position.y, ya) and is_equal_approx(anterior.end.y, yb) \
					and is_equal_approx(anterior.end.x, xa):
				lista[lista.size() - 1] = anterior.merge(coluna)
				continue
		lista.append(coluna)
	return lista

## A linha (canonica, medida do fundo) onde fica a divisoria que separa a sala
## do fundo da casa: a 45% da profundidade **interior**, contando da fachada.
static func _v_da_divisoria(rect: Rect2, porta: String) -> float:
	var profundidade := _profundidade(rect, porta)
	return profundidade - PAREDE - (profundidade - 2.0 * PAREDE) * 0.45

## As divisorias internas, cada uma com o seu vao de passagem. Casa de tres
## quartos: uma divisoria paralela a fachada separa a sala do fundo, e uma
## perpendicular parte o fundo em dois. O vao fica longe da porta da rua, para
## nao se enxergar a casa toda de fora.
static func paredes_internas(construcao: Dictionary) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	# As paredes que a arquitetura pediu a mais (o banheiro, 21/10/2026),
	# ja em mundo e com o vao da porta cortado (rua/arquitetura.gd).
	for extra in construcao.get("paredes_extras", []):
		lista.append(extra)
	if QUARTOS_POR_TIPO[construcao["tipo"]] < 3:
		return lista

	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	var v_div := _v_da_divisoria(rect, porta)
	var u_vao := PAREDE + (frente - 2.0 * PAREDE) * 0.78
	var u_perp := PAREDE + (frente - 2.0 * PAREDE) * 0.45
	# O meio da zona do fundo (entre a parede de tras e a divisoria): e ali que
	# fica o vao da divisoria perpendicular.
	var v_vao := (PAREDE + v_div) / 2.0

	lista.append(_rect_mundo(rect, porta, Vector2(PAREDE, v_div),
		Vector2(u_vao - VAO / 2.0 - PAREDE, PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(u_vao + VAO / 2.0, v_div),
		Vector2(frente - PAREDE - (u_vao + VAO / 2.0), PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(u_perp, PAREDE),
		Vector2(PAREDE, v_vao - VAO / 2.0 - PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(u_perp, v_vao + VAO / 2.0),
		Vector2(PAREDE, v_div - (v_vao + VAO / 2.0))))
	return menos_todos(lista, recortes_de(construcao))

## Os quartos, como retangulos de piso livre. E onde o movel vai. O primeiro e
## sempre a sala (onde a porta da rua da); o segundo e o terceiro sao o fundo,
## partido ao meio pela divisoria perpendicular.
static func quartos_de(construcao: Dictionary) -> Array[Rect2]:
	var quartos := _quartos_do_retangulo(construcao)
	if not construcao.has("recortes"):
		return quartos
	# Com recorte, cada quarto perde o canto tirado e fica com o maior pedaco
	# que sobrou - o recorte e desenhado para nao partir quarto ao meio.
	var buracos := _recortes_com_parede(construcao)
	var lista: Array[Rect2] = []
	for quarto in quartos:
		var sobra: Array[Rect2] = [quarto]
		lista.append(_maior(menos_todos(sobra, buracos)))
	return lista

static func _quartos_do_retangulo(construcao: Dictionary) -> Array[Rect2]:
	if QUARTOS_POR_TIPO[construcao["tipo"]] < 3:
		var unico: Array[Rect2] = [interior_de(construcao)]
		return unico

	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	var profundidade := _profundidade(rect, porta)
	var v_div := _v_da_divisoria(rect, porta)
	var u_perp := PAREDE + (frente - 2.0 * PAREDE) * 0.45

	var lista: Array[Rect2] = []
	lista.append(_rect_mundo(rect, porta, Vector2(PAREDE, v_div + PAREDE),
		Vector2(frente - 2.0 * PAREDE, profundidade - 2.0 * PAREDE - v_div)))
	lista.append(_rect_mundo(rect, porta, Vector2(PAREDE, PAREDE),
		Vector2(u_perp - PAREDE, v_div - PAREDE)))
	lista.append(_rect_mundo(rect, porta, Vector2(u_perp + PAREDE, PAREDE),
		Vector2(frente - 2.0 * PAREDE - u_perp, v_div - PAREDE)))
	return lista

## Uma marca retangular sobre o vao da porta (o traco do telhado que indica a
## entrada) - comprida ao longo da fachada, fina na perpendicular. Antes era
## escrita direto em `telhados.gd` supondo fachada horizontal; com porta em 4
## direcoes a marca tem que girar junto.
static func marca_da_porta(construcao: Dictionary) -> Rect2:
	var centro := porta_de(construcao)
	var eixo := eixo_da_fachada(construcao)
	var perpendicular := Vector2(eixo.y, eixo.x)
	var a := centro - eixo * (VAO / 2.0) - perpendicular * 7.0
	var b := centro + eixo * (VAO / 2.0) + perpendicular * 7.0
	return Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(b.x - a.x), absf(b.y - a.y))

## O tamanho de um movel, pronto para desenhar dentro desta construcao:
## transposto quando a fachada e vertical (leste/oeste) - senao o movel "deitado"
## nasceria de lado dentro da parede.
static func tamanho_do_movel(construcao: Dictionary, tipo: String) -> Vector2:
	var tamanho: Vector2 = MOVEIS[tipo]["tamanho"]
	var porta: String = construcao["porta"]
	if porta == "leste" or porta == "oeste":
		return Vector2(tamanho.y, tamanho.x)
	return tamanho

## As posicoes de uma fileira de moveis dentro de UM quarto: encostados na
## parede OPOSTA a fachada (a que fica longe da porta - encostar sempre do
## mesmo lado poria o movel em cima do vao em toda casa de fachada ao norte) e
## espalhados ao longo da parede. Escrita uma vez em termos do normal e do
## comprimento ao longo da fachada; antes so existia para fachada norte/sul,
## embutida dentro de `cenario._povoar`.
static func posicoes_de_movel(construcao: Dictionary, quarto: Rect2, tipos: Array) -> Array[Vector2]:
	var normal := normal_de(construcao)
	var um_quarto_so: bool = QUARTOS_POR_TIPO[construcao["tipo"]] < 3
	# Fachada norte/sul: espalha ao longo de x, encosta em y. Fachada
	# leste/oeste: o oposto.
	var horizontal := normal.y != 0.0

	var origem_ao_longo := quarto.position.x if horizontal else quarto.position.y
	var comprimento := quarto.size.x if horizontal else quarto.size.y

	var posicoes: Array[Vector2] = []
	for j in tipos.size():
		var tamanho := tamanho_do_movel(construcao, tipos[j])
		var meia_profundidade := (tamanho.y if horizontal else tamanho.x) / 2.0 + 8.0

		var ao_longo: float
		if um_quarto_so:
			# Salao sem divisoria: da para espalhar pela largura toda, com
			# folga entre um movel e outro.
			var vao := (comprimento - 160.0) / float(tipos.size())
			ao_longo = origem_ao_longo + 80.0 + vao * (float(j) + 0.5)
		else:
			# Na METADE da parede longe do vao: a divisoria interna abre a
			# passagem a 78% da largura, entao movel nenhum passa de 50%.
			var fracao := 0.15 + 0.35 * (float(j) + 1.0) / (float(tipos.size()) + 1.0)
			ao_longo = origem_ao_longo + comprimento * fracao

		if horizontal:
			var y := quarto.position.y + meia_profundidade if normal.y > 0.0 \
				else quarto.end.y - meia_profundidade
			posicoes.append(Vector2(ao_longo, y))
		else:
			var x := quarto.position.x + meia_profundidade if normal.x > 0.0 \
				else quarto.end.x - meia_profundidade
			posicoes.append(Vector2(x, ao_longo))
	return posicoes

## A entrada de carro: uma faixa perpendicular a fachada, saindo dela para
## fora. E o que faz o lote parecer lote, e nao um bloco solto na grama.
##
## Primitiva de baixo nivel: so precisa do retangulo, da porta e do
## comprimento - nao da construcao inteira - porque quem gera lote (P4 em
## diante) monta a entrada ANTES de decidir se o lote serve, e grava o
## resultado (ver `rua/lotes.gd`, campo `entrada`).
static func entrada_de_carro_para(rect: Rect2, porta: String, comprimento: float) -> Rect2:
	var frente := _frente(rect, porta)
	var x := frente * 0.35 - ENTRADA_DE_CARRO / 2.0
	return _rect_mundo(rect, porta, Vector2(x, _profundidade(rect, porta)),
		Vector2(ENTRADA_DE_CARRO, comprimento))

## Casca de compatibilidade sobre `entrada_de_carro_para`: usa o comprimento
## fixo de sempre, a menos que a construcao ja tenha um `recuo_ate_a_via`
## gravado (o campo que `rua/quadras.gd` grava desde P5).
static func entrada_de_carro(construcao: Dictionary) -> Rect2:
	var comprimento: float = construcao.get("recuo_ate_a_via", ENTRADA_DE_CARRO_COMPRIMENTO)
	return entrada_de_carro_para(construcao["rect"], construcao["porta"], comprimento)

## Um retangulo na FRENTE da fachada (na direcao do normal): a largura da
## fachada mais `folga` de cada lado, por `profundidade` para fora. E o
## patio/estacionamento generico de um predio publico - escrito uma vez para
## as 4 orientacoes (17/09/2026, P8): antes cada gerador de lugar escrevia
## `onde.end.y` a mao, supondo fachada ao norte ou ao sul.
static func na_frente(construcao: Dictionary, folga: float, profundidade: float) -> Rect2:
	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	return _rect_mundo(rect, porta, Vector2(-folga, _profundidade(rect, porta)),
		Vector2(frente + 2.0 * folga, profundidade))

## Um ponto na frente da fachada: a `ao_longo` (0..1) do comprimento dela,
## `distancia` px para fora, na direcao do normal.
static func em_frente(construcao: Dictionary, ao_longo: float, distancia: float) -> Vector2:
	var rect: Rect2 = construcao["rect"]
	var porta: String = construcao["porta"]
	var frente := _frente(rect, porta)
	var profundidade := _profundidade(rect, porta)
	return _ao_mundo(rect, porta, Vector2(frente * ao_longo, profundidade)) \
		+ normal_de(construcao) * distancia

## Hash FNV-1a de 32 bits sobre uma chave de texto. Determinismo pela CHAVE, e
## nao pelo indice de geracao: mover ou inserir um predio deixa de re-sortear
## planta e recuo de todo o resto do mapa - o problema que `_embaralhar_indice`
## tem e que um lugar novo desloca o indice de todo mundo depois dele.
##
## FNV-1a de **32 bits**, e nao de 64: um desenho anterior usava hash de 64 bits
## com `frac(s * 0.618)`, e em `double` isso da exatamente 0,0 para boa parte
## das chaves - todo recuo colapsava no mesmo valor, "todas as casas iguais"
## reintroduzido por ponto flutuante, em silencio. Foi o bug de determinismo
## que a revisao achou; `% tamanho_da_lista` sobre um inteiro nao tem esse
## problema, mas o hash em si continua de 32 bits por seguranca.
static func embaralhar(chave: String) -> int:
	var hash: int = 2166136261
	for byte in chave.to_utf8_buffer():
		hash = (hash ^ byte) & 0xFFFFFFFF
		hash = (hash * 16777619) & 0xFFFFFFFF
	return hash
