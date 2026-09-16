## Uma construcao: a geometria dela por dentro, e o que tem dentro dela.
##
## **Nao e o mapa.** Onde cada coisa fica esta no `rua/mapa.gd`, e do que cada
## lugar e feito esta no `rua/lugares.gd`. Aqui moram as regras que valem para
## qualquer predio do mapa - onde ficam as paredes, onde fica o vao da porta,
## como o interior se parte em quartos - e as tabelas de loot.
##
## Ate 09/09/2026 este arquivo era o `bairro.gd` e era o mapa inteiro. O mapa
## cresceu 100x em area e ganhou seis tipos de lugar; o que sobrou aqui e o que
## nao dependia de ser um bairro.
##
## ## A escala, e por que ela e essa
##
## **A referencia de tudo aqui e o corpo do jogador: 28 x 40 px**
## (`rua/jogador.tscn`), ou seja 40 px = 1 metro. Toda medida existe em relacao
## a ele.
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

const PAREDE := 20.0
## Vao de porta: 3,6 corpos de largura. Generoso de proposito - porta apertada
## com zumbi atras e frustracao, nao tensao.
const VAO := 100.0

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
}

## **Casa nao e um tamanho so** (16/09/2026). Ate aqui toda casa do mapa media
## 520 x 420, e fileira de casa identica le como conjunto habitacional - no
## Project Zomboid duas vizinhas quase nunca tem a mesma planta.
##
## Sao **plantas**, e nao sorteio livre: cada uma e uma casa plausivel de
## suburbio - a rasa e larga, a estreita e funda, a pequena de esquina.
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
static func _embaralhar(indice: int) -> int:
	return absi(indice * 2654435761) % 1000003

static func planta_de_casa(indice: int) -> Vector2:
	return PLANTAS_DE_CASA[_embaralhar(indice) % PLANTAS_DE_CASA.size()]

static func recuo_de_casa(indice: int) -> float:
	return RECUOS_DE_CASA[_embaralhar(indice + 7919) % RECUOS_DE_CASA.size()]

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
}

## Que movel entra em cada quarto, por tipo de construcao.
##
## A ordem importa: o primeiro quarto e a sala, onde a porta da rua da, e o
## **ultimo e o mais fundo** - o que custa mais para chegar. E onde vai o
## documento, quando o lugar tem um.
##
## E aqui que a variedade do mapa vira variedade de mecanica: a delegacia paga
## melhor que uma casa porque o quarto do fundo dela tem o armario de armas, que
## e o movel mais caro de vasculhar que existe.
const MOVEIS_POR_QUARTO := {
	"casa": [["estante"], ["comoda"], ["geladeira"]],
	"comercio": [["armario", "armario", "geladeira", "caixa", "caixa"]],
	"galpao": [["caixa"]],
	"posto": [["prateleira", "prateleira", "geladeira", "caixa"]],
	"mercado": [["prateleira", "prateleira", "prateleira", "geladeira", "geladeira", "caixa"]],
	"delegacia": [["arquivo"], ["caixa"], ["armario_de_armas"]],
	"mansao": [["comoda"], ["armario"], ["estante"]],
	"garagem": [["caixa"]],
}
const MOVEIS := {
	"geladeira": { "rotulo": "Geladeira", "duracao": 3.5, "tamanho": Vector2(72.0, 54.0), "cor": Color("6e7a76") },
	"armario": { "rotulo": "Armário", "duracao": 3.0, "tamanho": Vector2(102.0, 46.0), "cor": Color("6b5b3f") },
	"comoda": { "rotulo": "Cômoda", "duracao": 2.5, "tamanho": Vector2(84.0, 48.0), "cor": Color("5e4c38") },
	"estante": { "rotulo": "Estante", "duracao": 4.0, "tamanho": Vector2(112.0, 38.0), "cor": Color("57452f") },
	"caixa": { "rotulo": "Caixa", "duracao": 1.8, "tamanho": Vector2(56.0, 56.0), "cor": Color("6d5b45") },
	"carro": { "rotulo": "Carro abandonado", "duracao": 3.0, "tamanho": Vector2(180.0, 80.0), "cor": Color("5c4a44") },
	"lata": { "rotulo": "Lata de lixo", "duracao": 1.5, "tamanho": Vector2(48.0, 48.0), "cor": Color("4a4f45") },
	# Os quatro que chegaram com os lugares novos de 09/09/2026. O armario de
	# armas da delegacia e o movel mais caro do mapa: 5,5 s de vasculho
	# ininterrupto, com a delegacia sendo o lugar mais povoado.
	"prateleira": { "rotulo": "Prateleira", "duracao": 3.2, "tamanho": Vector2(156.0, 42.0), "cor": Color("6b6152") },
	"bomba": { "rotulo": "Bomba de combustível", "duracao": 4.0, "tamanho": Vector2(56.0, 86.0), "cor": Color("7a5a4a") },
	"arquivo": { "rotulo": "Arquivo", "duracao": 4.2, "tamanho": Vector2(88.0, 52.0), "cor": Color("5a5f63") },
	"armario_de_armas": { "rotulo": "Armário de armas", "duracao": 5.5, "tamanho": Vector2(108.0, 50.0), "cor": Color("4e5a55") },
}

## Os dois achados que sao **equipamento e nao loot**: nao ocupam vaga na
## mochila e nao se perdem no dia que deu errado. Ver rua/mochila.gd.
##
## A pistola nao esta em tabela nenhuma: ela e colocada em UM movel declarado -
## a armaria da delegacia -, do mesmo jeito que o documento. Arma sorteada nao
## serve: ou o jogador acha na primeira gaveta, ou nao acha nunca.
const PISTOLA := "pistola"
const MUNICAO := "munição"

## Quantas balas vem em cada achado de municao. E uma caixinha, nao uma bala.
const MUNICAO_POR_ACHADO := 6

## O que sai de cada movel. PZ tira o loot de uma tabela por tipo de movel, e o
## conteudo combina com o quarto - mesma ideia aqui. Continua sendo texto solto:
## item com peso, uso e valor e assunto de quem fizer o modo Casa, que e quem
## consome.
const CONTEUDO := {
	"geladeira": ["lata de comida", "garrafa de água", "comida estragada"],
	"armario": ["lata de comida", "fósforos", "pano limpo"],
	"comoda": ["roupa", "remédio", "chave velha", MUNICAO],
	"estante": ["livro de química", "pilha", "fita isolante"],
	"caixa": ["ferramenta", "prego", "corda", MUNICAO],
	"carro": ["chave de roda", "fita isolante", "gasolina"],
	"lata": ["pano sujo", "garrafa vazia"],
	"prateleira": ["lata de comida", "garrafa de água", "biscoito", "sabão"],
	"bomba": ["gasolina", "mangueira", "galão vazio"],
	"arquivo": ["papelada", "pasta com fichas", "grampeador"],
	"armario_de_armas": ["algemas", "colete", "cassetete", MUNICAO],
}



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


static func e_da_frente_ao_sul(construcao: Dictionary) -> bool:
	return construcao["porta"] == "sul"

## O centro do vao da porta, na fachada.
static func porta_de(construcao: Dictionary) -> Vector2:
	var r: Rect2 = construcao["rect"]
	var x := r.position.x + r.size.x * 0.35
	if e_da_frente_ao_sul(construcao):
		return Vector2(x, r.end.y - PAREDE / 2.0)
	return Vector2(x, r.position.y + PAREDE / 2.0)

## As quatro paredes externas, com a da fachada partida em duas pelo vao.
static func paredes_externas(construcao: Dictionary) -> Array[Rect2]:
	var r: Rect2 = construcao["rect"]
	var ao_sul := e_da_frente_ao_sul(construcao)
	var y_frente := r.end.y - PAREDE if ao_sul else r.position.y
	var y_fundo := r.position.y if ao_sul else r.end.y - PAREDE

	var lista: Array[Rect2] = []
	lista.append(Rect2(r.position.x, y_fundo, r.size.x, PAREDE))
	lista.append(Rect2(r.position.x, r.position.y, PAREDE, r.size.y))
	lista.append(Rect2(r.end.x - PAREDE, r.position.y, PAREDE, r.size.y))

	var meio := porta_de(construcao).x
	lista.append(Rect2(r.position.x, y_frente, meio - VAO / 2.0 - r.position.x, PAREDE))
	lista.append(Rect2(meio + VAO / 2.0, y_frente, r.end.x - meio - VAO / 2.0, PAREDE))
	return lista

## O retangulo de piso, ja descontadas as paredes externas.
static func interior_de(construcao: Dictionary) -> Rect2:
	var r: Rect2 = construcao["rect"]
	return Rect2(r.position + Vector2.ONE * PAREDE, r.size - Vector2.ONE * PAREDE * 2.0)

static func _y_da_divisoria(construcao: Dictionary) -> float:
	var dentro := interior_de(construcao)
	if e_da_frente_ao_sul(construcao):
		return dentro.end.y - dentro.size.y * 0.45
	return dentro.position.y + dentro.size.y * 0.45

## A metade de tras da casa, que a segunda divisoria parte em dois quartos.
static func _fundo_de(construcao: Dictionary) -> Rect2:
	var dentro := interior_de(construcao)
	var y := _y_da_divisoria(construcao)
	if e_da_frente_ao_sul(construcao):
		return Rect2(dentro.position.x, dentro.position.y, dentro.size.x, y - dentro.position.y)
	return Rect2(dentro.position.x, y + PAREDE, dentro.size.x, dentro.end.y - y - PAREDE)

## A sala, que e o quarto onde a porta da rua da.
static func _sala_de(construcao: Dictionary) -> Rect2:
	var dentro := interior_de(construcao)
	var y := _y_da_divisoria(construcao)
	if e_da_frente_ao_sul(construcao):
		return Rect2(dentro.position.x, y + PAREDE, dentro.size.x, dentro.end.y - y - PAREDE)
	return Rect2(dentro.position.x, dentro.position.y, dentro.size.x, y - dentro.position.y)

## As divisorias internas, cada uma com o seu vao de passagem. Casa de tres
## quartos: uma divisoria paralela a fachada separa a sala do fundo, e uma
## perpendicular parte o fundo em dois. O vao fica longe da porta da rua, para
## nao se enxergar a casa toda de fora.
static func paredes_internas(construcao: Dictionary) -> Array[Rect2]:
	var lista: Array[Rect2] = []
	if QUARTOS_POR_TIPO[construcao["tipo"]] < 3:
		return lista

	var dentro := interior_de(construcao)
	var y := _y_da_divisoria(construcao)
	var vao_x := dentro.position.x + dentro.size.x * 0.78
	lista.append(Rect2(dentro.position.x, y, vao_x - VAO / 2.0 - dentro.position.x, PAREDE))
	lista.append(Rect2(vao_x + VAO / 2.0, y, dentro.end.x - vao_x - VAO / 2.0, PAREDE))

	var fundo := _fundo_de(construcao)
	var x := dentro.position.x + dentro.size.x * 0.45
	var vao_y := fundo.get_center().y
	lista.append(Rect2(x, fundo.position.y, PAREDE, vao_y - VAO / 2.0 - fundo.position.y))
	lista.append(Rect2(x, vao_y + VAO / 2.0, PAREDE, fundo.end.y - vao_y - VAO / 2.0))
	return lista

## Os quartos, como retangulos de piso livre. E onde o movel vai.
static func quartos_de(construcao: Dictionary) -> Array[Rect2]:
	var dentro := interior_de(construcao)
	if QUARTOS_POR_TIPO[construcao["tipo"]] < 3:
		var unico: Array[Rect2] = [dentro]
		return unico

	var fundo := _fundo_de(construcao)
	var x := dentro.position.x + dentro.size.x * 0.45
	var lista: Array[Rect2] = [_sala_de(construcao)]
	lista.append(Rect2(fundo.position.x, fundo.position.y, x - fundo.position.x, fundo.size.y))
	lista.append(Rect2(x + PAREDE, fundo.position.y, fundo.end.x - x - PAREDE, fundo.size.y))
	return lista

## A entrada de carro: uma faixa que sai da fachada para fora. E o que faz o
## lote parecer lote, e nao um bloco solto na grama.
static func entrada_de_carro(construcao: Dictionary) -> Rect2:
	var r: Rect2 = construcao["rect"]
	var x := porta_de(construcao).x - ENTRADA_DE_CARRO / 2.0
	if e_da_frente_ao_sul(construcao):
		return Rect2(x, r.end.y, ENTRADA_DE_CARRO, ENTRADA_DE_CARRO_COMPRIMENTO)
	return Rect2(x, r.position.y - ENTRADA_DE_CARRO_COMPRIMENTO,
		ENTRADA_DE_CARRO, ENTRADA_DE_CARRO_COMPRIMENTO)
