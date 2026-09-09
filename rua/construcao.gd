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



## Os documentos - o item que destrava a historia dentro de casa.
##
## Sao seis, e desde 09/09/2026 **cada um mora num lugar declarado do mapa**, no
## quarto mais fundo do predio: dois no bairro e quatro exigindo viagem. Antes
## era um a cada seis moveis, o que num mapa 100x maior daria documento repetido
## - e documento repetido como moeda de progressao nao quer dizer nada.
##
## Quem marca o predio e o `rua/lugares.gd`, com "documento": true.
const DOCUMENTOS := [
	"documento: relatório de laboratório",
	"documento: recorte de jornal",
	"documento: carta manuscrita",
	"documento: prontuário rasgado",
	"documento: memorando interno",
	"documento: página de diário",
]

# ------------------------------------------------------------------ geometria

## Se um achado e documento e nao comida.
##
## Documento conta separado, aparece com destaque e e o que destrava a historia
## dentro de casa - entao alguem precisa saber distinguir os dois. Fica aqui, e
## pela propria lista, para nao existir uma segunda fonte de verdade sobre o
## que e documento.
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
