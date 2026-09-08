## Os dados do bairro: onde ficam as ruas, as construcoes, os quartos, as
## cercas e os moveis. Fonte unica - o cenario desenha o chao e gera a colisao
## a partir daqui, e os telhados leem as mesmas construcoes para saber qual
## esconder.
##
## Estilo Project Zomboid, na parte que serve a nossa mecanica:
##
##  - nao e uma rua, e um bairro em quadras, com quintal e fundo de lote;
##  - **toda construcao se entra**, e o interior esta na mesma cena, sem tela
##    de carregamento - e o que faz vasculhar valer a pena, porque entrar te
##    fecha num lugar de onde nao da para fugir em linha reta;
##  - o loot esta em **movel dentro de quarto**, e o que tem dentro combina com
##    o tipo do movel (geladeira e comida, comoda e roupa e remedio), em vez de
##    estar espalhado na calcada.
##
## O que NAO copiamos e a camera: PZ e isometrico e o High Concept declara
## top-down. Copiamos a planta do bairro, nao a projecao.
##
## ## Escala
##
## **A referencia de tudo aqui e o corpo do jogador: 28 x 40 px**
## (`rua/jogador.tscn`). Toda medida abaixo existe em relacao a ele.
##
## O bairro foi **ampliado em 08/09/2026**: a primeira versao usava um mundo de
## 3200 x 2000 e casa de 360 x 290, e no zoom de jogo tudo ficava em cima do
## personagem - quarto de 3,6 corpos de altura, beco de 1,4 corpo de largura.
## A arquitetura cresceu cerca de 1,8x e o jogador ficou do mesmo tamanho, que
## e o que da a sensacao de escala. O **movel cresceu bem menos** (~1,35x), de
## proposito: crescendo junto, o quarto continuaria cheio.
##
## Referencias uteis, em corpos de jogador (28 de largura, 40 de altura):
##
## | O que | Antes | Agora |
## |---|---|---|
## | quarto do fundo | 5,4 x 3,6 | 9,8 x 6,6 |
## | beco entre duas casas | 1,4 | 3,9 |
## | vao de porta | 2,5 | 3,6 |
## | largura da rua principal | 5,5 | 10 |
##
## Descartavel: e greybox. O TileSet e o level design de verdade entram quando
## o layout parar de mudar. **Depois de mexer em qualquer numero daqui, rode o
## `rua/conferir_bairro.tscn` (F6)** - numero errado fecha caminho sem avisar.

const MUNDO := Rect2(0.0, 0.0, 5760.0, 3600.0)

# Duas ruas cruzando, que e o que separa bairro de "uma rua so". As quadras sao
# os quatro cantos que sobram.
const RUA_PRINCIPAL := Rect2(0.0, 1620.0, 5760.0, 400.0)
const RUA_TRANSVERSAL := Rect2(2700.0, 0.0, 400.0, 3600.0)

const CALCADA := 120.0
const PAREDE := 20.0
## Vao de porta: 3,6 corpos de largura. Generoso de proposito - porta apertada
## com zumbi atras e frustracao, nao tensao.
const VAO := 100.0
## Largura da entrada de carro, da fachada ate a calcada.
const ENTRADA_DE_CARRO := 180.0

## As construcoes. "porta" e a fachada onde fica a entrada; "tipo" define
## quantos quartos e quantos moveis; "sua" e a sua casa, a unica que nao se
## vasculha e a unica com o porao.
##
## As casas tem 650 x 520. O lado norte tem a fachada virada para o sul e o
## lado sul para o norte, os dois dando na rua principal.
const CONSTRUCOES := [
	# Quadra noroeste e nordeste, fachada ao sul.
	{ "rect": Rect2(240.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa", "sua": true },
	{ "rect": Rect2(1000.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(1760.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(3340.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(4100.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	{ "rect": Rect2(4860.0, 820.0, 650.0, 520.0), "porta": "sul", "tipo": "casa" },
	# Quadra sudoeste e sudeste, fachada ao norte. O mercadinho e a "pequena
	# loja na esquina" que PZ poe na fita comercial: salao unico com muito mais
	# movel, e o lugar mais caro de vasculhar do mapa.
	{ "rect": Rect2(240.0, 2300.0, 940.0, 540.0), "porta": "norte", "tipo": "comercio" },
	{ "rect": Rect2(1300.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	{ "rect": Rect2(3340.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	{ "rect": Rect2(4360.0, 2300.0, 650.0, 520.0), "porta": "norte", "tipo": "casa" },
	# Galpao no fundo do quintal, virado para a casa. Fica DENTRO do lote, com
	# folga dos dois lados: encostado na cerca de fundo, a porta ficava a 40 px
	# dela, e o jogador (40 de altura) simplesmente nao cabia na frente.
	{ "rect": Rect2(420.0, 480.0, 280.0, 240.0), "porta": "sul", "tipo": "galpao" },
	{ "rect": Rect2(4200.0, 480.0, 280.0, 240.0), "porta": "sul", "tipo": "galpao" },
	{ "rect": Rect2(1400.0, 2960.0, 280.0, 240.0), "porta": "norte", "tipo": "galpao" },
]

const QUARTOS_POR_TIPO := { "casa": 3, "comercio": 1, "galpao": 1 }

## Que movel entra em cada quarto, por tipo de construcao. A casa tem tres
## quartos com um movel em cada; o mercadinho tem um salao com cinco.
const MOVEIS_POR_QUARTO := {
	"casa": [["estante"], ["comoda"], ["geladeira"]],
	"comercio": [["armario", "armario", "geladeira", "caixa", "caixa"]],
	"galpao": [["caixa"]],
}

## Cerca de divisa e de fundo de lote. Sao solidas e tem vao largo: existem
## para desviar o caminho, nao para prender ninguem.
const CERCAS := [
	# Fundo de lote do lado norte. Os vaos entre os trechos tem de 90 a 280,
	# de 3 a 10 corpos de largura.
	Rect2(200.0, 370.0, 720.0, 18.0),
	Rect2(1010.0, 370.0, 670.0, 18.0),
	Rect2(1790.0, 370.0, 620.0, 18.0),
	Rect2(3350.0, 370.0, 610.0, 18.0),
	Rect2(4130.0, 370.0, 590.0, 18.0),
	Rect2(4890.0, 370.0, 590.0, 18.0),
	# Fundo de lote do lado sul.
	Rect2(200.0, 3270.0, 970.0, 18.0),
	Rect2(1290.0, 3270.0, 680.0, 18.0),
	Rect2(3350.0, 3270.0, 620.0, 18.0),
	Rect2(4350.0, 3270.0, 680.0, 18.0),
	# Divisa entre dois lotes. Sao tocos que saem da cerca de fundo e param no
	# meio do quintal: divisa que atravessa o quintal inteiro fecha o unico
	# caminho para o fundo do lote e ninguem percebe.
	Rect2(958.0, 388.0, 14.0, 220.0),
	Rect2(1718.0, 388.0, 14.0, 220.0),
	Rect2(4048.0, 388.0, 14.0, 220.0),
	Rect2(1240.0, 3050.0, 14.0, 220.0),
]

## Onde pode nascer arvore. Sao as bordas do mapa, longe de qualquer beco,
## porta ou vao de cerca: arvore e solida, e arvore solida em area de
## circulacao fecha caminho sem ninguem perceber.
const BOSQUES := [
	Rect2(0.0, 0.0, 5760.0, 300.0),
	Rect2(0.0, 3350.0, 5760.0, 250.0),
	Rect2(5540.0, 2250.0, 220.0, 950.0),
]

## Movel que fica fora, no asfalto e na calcada. O de dentro e gerado a partir
## dos quartos.
const MOVEIS_DE_RUA := [
	{ "tipo": "carro", "pos": Vector2(1200.0, 1720.0) },
	{ "tipo": "carro", "pos": Vector2(3600.0, 1920.0) },
	{ "tipo": "carro", "pos": Vector2(2900.0, 3100.0) },
	{ "tipo": "carro", "pos": Vector2(620.0, 1900.0) },
	{ "tipo": "lata", "pos": Vector2(1560.0, 1560.0) },
	{ "tipo": "lata", "pos": Vector2(3900.0, 1560.0) },
	{ "tipo": "lata", "pos": Vector2(2300.0, 2080.0) },
	{ "tipo": "lata", "pos": Vector2(4600.0, 2080.0) },
]

## Onde os zumbis comecam o dia. Nao e sistema de onda - e povoamento, do jeito
## do PZ: alguns arrastando na rua, alguns no quintal, e **dois dentro de
## construcao**, que e o que faz entrar numa casa nao ser abrigo garantido.
##
## O ritmo de horda que o High Concept pede sai do chamado entre eles (ver
## rua/zumbi.gd), nao da quantidade.
const ZUMBIS := [
	# Rua principal.
	Vector2(900.0, 1820.0),
	Vector2(1700.0, 1780.0),
	Vector2(2350.0, 1900.0),
	Vector2(3300.0, 1820.0),
	Vector2(4200.0, 1880.0),
	Vector2(5100.0, 1800.0),
	# Rua transversal.
	Vector2(2900.0, 700.0),
	Vector2(2900.0, 2600.0),
	# Quintais.
	Vector2(1300.0, 620.0),
	Vector2(4600.0, 640.0),
	Vector2(600.0, 3000.0),
	# Dentro da terceira casa do lado norte, na sala.
	Vector2(2085.0, 1222.0),
	# Dentro do mercadinho.
	Vector2(710.0, 2450.0),
]

## Cada movel: quanto custa vasculhar, o tamanho e a cor. A duracao e o unico
## numero que separa uma lata de lixo de uma estante - mesmo verbo, custos
## diferentes.
##
## O tamanho cresceu ~1,35x na ampliacao de 08/09, e nao 1,8x como a
## arquitetura: movel que cresce junto com o quarto deixa o quarto igualmente
## cheio. O carro e a excecao, porque carro do lado de uma pessoa e grande
## mesmo.
const MOVEIS := {
	"geladeira": { "rotulo": "Geladeira", "duracao": 3.5, "tamanho": Vector2(72.0, 54.0), "cor": Color("6e7a76") },
	"armario": { "rotulo": "Armário", "duracao": 3.0, "tamanho": Vector2(102.0, 46.0), "cor": Color("6b5b3f") },
	"comoda": { "rotulo": "Cômoda", "duracao": 2.5, "tamanho": Vector2(84.0, 48.0), "cor": Color("5e4c38") },
	"estante": { "rotulo": "Estante", "duracao": 4.0, "tamanho": Vector2(112.0, 38.0), "cor": Color("57452f") },
	"caixa": { "rotulo": "Caixa", "duracao": 1.8, "tamanho": Vector2(56.0, 56.0), "cor": Color("6d5b45") },
	"carro": { "rotulo": "Carro abandonado", "duracao": 3.0, "tamanho": Vector2(180.0, 80.0), "cor": Color("5c4a44") },
	"lata": { "rotulo": "Lata de lixo", "duracao": 1.5, "tamanho": Vector2(48.0, 48.0), "cor": Color("4a4f45") },
}

## O que sai de cada movel. PZ tira o loot de uma tabela por tipo de movel, e o
## conteudo combina com o quarto - mesma ideia aqui. Continua sendo texto solto:
## item com peso, uso e valor e assunto de quem fizer o modo Casa, que e quem
## consome.
const CONTEUDO := {
	"geladeira": ["lata de comida", "garrafa de água", "comida estragada"],
	"armario": ["lata de comida", "fósforos", "pano limpo"],
	"comoda": ["roupa", "remédio", "chave velha"],
	"estante": ["livro de química", "pilha", "fita isolante"],
	"caixa": ["ferramenta", "prego", "corda"],
	"carro": ["chave de roda", "fita isolante", "gasolina"],
	"lata": ["pano sujo", "garrafa vazia"],
}

## De quantos em quantos moveis aparece um documento - o item que destrava a
## historia dentro de casa. Precisa ser raro o bastante para valer arriscar.
const CADA_QUANTOS_MOVEIS_UM_DOCUMENTO := 6

const DOCUMENTOS := [
	"documento: relatório de laboratório",
	"documento: recorte de jornal",
	"documento: carta manuscrita",
	"documento: prontuário rasgado",
	"documento: memorando interno",
	"documento: página de diário",
]

# ------------------------------------------------------------------ geometria

## As calcadas: uma faixa de cada lado de cada rua.
## Se um achado e documento e nao comida.
##
## Documento conta separado, aparece com destaque e e o que destrava a historia
## dentro de casa - entao alguem precisa saber distinguir os dois. Fica aqui, e
## pela propria lista, para nao existir uma segunda fonte de verdade sobre o
## que e documento.
static func e_documento(achado: String) -> bool:
	return DOCUMENTOS.has(achado)

static func calcadas() -> Array[Rect2]:
	var lista: Array[Rect2] = []
	for rua in [RUA_PRINCIPAL, RUA_TRANSVERSAL]:
		if rua.size.x > rua.size.y:
			lista.append(Rect2(rua.position.x, rua.position.y - CALCADA, rua.size.x, CALCADA))
			lista.append(Rect2(rua.position.x, rua.end.y, rua.size.x, CALCADA))
		else:
			lista.append(Rect2(rua.position.x - CALCADA, rua.position.y, CALCADA, rua.size.y))
			lista.append(Rect2(rua.end.x, rua.position.y, CALCADA, rua.size.y))
	return lista

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

## A entrada de carro, da fachada ate a calcada. E o que faz o lote parecer
## lote, e nao um bloco solto na grama.
static func entrada_de_carro(construcao: Dictionary) -> Rect2:
	var r: Rect2 = construcao["rect"]
	var x := porta_de(construcao).x - ENTRADA_DE_CARRO / 2.0
	if e_da_frente_ao_sul(construcao):
		return Rect2(x, r.end.y, ENTRADA_DE_CARRO, RUA_PRINCIPAL.position.y - CALCADA - r.end.y)
	var base := RUA_PRINCIPAL.end.y + CALCADA
	return Rect2(x, base, ENTRADA_DE_CARRO, r.position.y - base)

## Em qual construcao esta o ponto, ou -1. E o que decide qual telhado
## esconder: em PZ o teto sai quando voce entra, e e isso que faz entrar numa
## casa ser descobrir o que tem dentro, em vez de ler tudo de fora.
static func construcao_em(ponto: Vector2) -> int:
	for i in CONSTRUCOES.size():
		if (CONSTRUCOES[i]["rect"] as Rect2).has_point(ponto):
			return i
	return -1
