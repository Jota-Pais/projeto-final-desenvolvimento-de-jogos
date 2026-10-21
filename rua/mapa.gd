## O mundo: onde fica cada coisa. **Fonte única do mapa.**
##
## ## De onde o mapa vem (30/09/2026)
##
## Do desenho do João, `design/urussanga.png`. O `design/tracar_desenho.js`
## lê o PNG, separa cada cor numa classe de chão ou de prédio, apaga texto e
## linha fina, e escreve `rua/mapa_tracado.json`: polígonos de chão,
## retângulos de prédio, blocos sólidos e veículos, tudo em px do desenho.
## Este arquivo diz o que cada coisa **é** (ROTULOS: nome, tipo, documento, a
## sua casa), em que escala o desenho vira mundo (ESCALA) e monta o dicionário
## que o cenário, os telhados e as ferramentas consomem.
##
##  - mudou o desenho: `node design/tracar_desenho.js`, e pronto;
##  - mudou o que uma coisa é: ROTULOS, aqui.
##
## O mapa anterior (bairro e cidade em grade, gerados por via, quadra e lote,
## até 23/09/2026) saiu inteiro. `rua/vias.gd`, `rua/quadras.gd` e
## `rua/lugares.gd` ficam no git, no commit anterior a este.
##
## ## A escala
##
## **40 px = 1 metro**, como sempre - era a altura do corpo do jogador ate
## 20/10/2026, quando ele e o zumbi passaram a ter metade: o mundo ficou como
## estava, e duas vezes maior em volta deles, de proposito. O desenho
## entra com ESCALA px de mundo por px dele: a 24, um pixel do desenho é 0,6 m
## e o mapa inteiro (917 x 530 px) tem 550 x 318 m. É o número que faz uma
## rua de 13 px do desenho ter 7,8 m, um carro de 7 px ter 4,2 m e a praça
## ter 48 x 66 m. **Proposta** - é uma constante só, e tudo escala junto.
##
## ## O que é prédio e o que é chão
##
## Vermelho, marrom e cinza do desenho são prédio: cada mancha vira um ou
## mais retângulos axiais (o jogo só sabe prédio axial - parede, quarto,
## móvel e telhado contam com isso), e a mancha inteira continua pintada por
## baixo como "lote". Prédio torto no desenho vira um reto do mesmo tamanho no
## mesmo centro. O resto (grama, mata, pavimento, asfalto, milho, terra, água)
## é polígono pintado; mata ganha árvore sólida, água ganha colisão.

const Construcao := preload("res://rua/construcao.gd")
const Barreira := preload("res://rua/barreira.gd")

const ARQUIVO_DO_TRACADO := "res://rua/mapa_tracado.json"

## px de mundo por px do desenho.
const ESCALA := 24.0

## O mundo: o recorte do desenho (917 x 530 px) vezes ESCALA. Const porque
## meio jogo lê `Mapa.MUNDO`; `_montar` confere que bate com o JSON.
const MUNDO := Rect2(0.0, 0.0, 22008.0, 12720.0)

## A versão do mapa - sobe toda vez que a IDENTIDADE dos móveis (a lista de
## chaves, na ordem de geração) muda de propósito. Carimbo do relatório do
## conferir_mapa; quem prova é IMPRESSAO_ESPERADA.
## Versão 3 (15/10/2026): os rótulos lidos nos prints do Canva mudaram o
## tipo de dois prédios (Conveniência virou comércio, Casa abandonada) e um
## veículo virou trator - a lista de móveis mudou de propósito.
## Versão 4 (15/10/2026, mais tarde): o traçador passou a achar os veículos
## miúdos (duas caminhonetes e mais cinco carros) e as manchas pequenas e
## tortas (a segunda casa abandonada e o vendedor de melancia viraram prédio).
## Versão 5 (20/10/2026): a sua casa mudou de prédio, a pedido do João - a
## antiga ganhou os móveis de casa e a nova, selada, perdeu os dela.
## Versão 6 (21/10/2026): a casa do Antônio, vizinha da sua, ficou selada para
## o roteiro do tutorial e perdeu os móveis dela.
const VERSAO_DO_MAPA := 6

## Hash (8 dígitos hex) da lista de chaves de todo móvel gerado num dia comum,
## na ordem em que nascem - comparada pelo conferir_mapa. Recalcula rodando
## `conferir_mapa.tscn` e copiando o valor de "IMPRESSAO DIGITAL DOS MOVEIS",
## depois de conferir que a mudança foi de propósito.
const IMPRESSAO_ESPERADA := "b79463ac"

## Os rótulos do desenho: o que cada mancha é.
##
## `ponto` é em px do PNG original (1920 x 1080), do jeito que um editor de
## imagem mostra - a conversão para o recorte e para o mundo é daqui. O rótulo
## cai no prédio (retângulo traçado) que contém o ponto. Se não cai em prédio
## nenhum, é um **lugar** (zona): usa `rect` (também em px do PNG) ou o
## polígono de chão que contém o ponto.
##
## `tipo` é a chave de `Construcao.QUARTOS_POR_TIPO` (quantos quartos, que
## móvel) para prédio, e "zona" para lugar. `documento` 1..6 põe um dos seis
## placeholders no quarto mais fundo; `sua` marca a sua casa (uma só). A arma
## não mora em lugar nenhum do mapa: você começa com ela (30/09/2026).
##
## ⬜ **Três decisões aqui são provisórias, à espera do João/da equipe**
## (respostas dele em 15/10/2026 entre parênteses):
##
##  - ~~qual casa é a sua~~ **trocada pelo João em 20/10/2026**, marcada no
##    retrato do mapa: a casa marrom ao sul da avenida diagonal, entre as
##    Lojas e a Delegacia, a oeste da rotatória. Até então era a casa sem nome
##    do miolo, entre a Prefeitura, a Praça e as Lojas (confirmada em 15/10);
##  - **onde ficam os seis documentos** (Hospital, Prefeitura, Escola,
##    Delegacia, Mansão, Casa do fazendeiro) - espalhados, como antes, só para
##    a partida ter como ser ganha ("os documentos não são mecânica oficial do
##    jogo ainda": a cura por documentos continua provisória, não é decisão);
##  - ~~os rótulos miúdos do desenho não dão para ler~~ **resolvido em
##    15/10/2026** com prints do Canva: Conveniência e Oficina (anexos do
##    posto), Galpão dele, Casa afastada do velho louco e Casa abandonada
##    (estrada de terra), Trator (fazenda). A caminhonete da fazenda e a do
##    galpão dele eram pequenas demais no desenho e o traçador não as
##    achou; o "Vendedor de melancia" perto do Hotel virou bloco sólido.
const ROTULOS := [
	# --- prédios ---------------------------------------------------------
	{ "nome": "Hospital", "ponto": Vector2(760.0, 440.0), "tipo": "hospital", "documento": 1 },
	{ "nome": "Escola", "ponto": Vector2(1350.0, 300.0), "tipo": "escola", "documento": 3 },
	{ "nome": "Prefeitura / Biblioteca", "ponto": Vector2(1115.0, 470.0), "tipo": "prefeitura", "documento": 2 },
	{ "nome": "Delegacia", "ponto": Vector2(1122.0, 712.0), "tipo": "delegacia", "documento": 4 },
	{ "nome": "Mansão", "ponto": Vector2(888.0, 290.0), "tipo": "mansao", "documento": 5 },
	{ "nome": "Casa do fazendeiro", "ponto": Vector2(742.0, 254.0), "tipo": "casa", "documento": 6 },
	{ "nome": "sua casa", "ponto": Vector2(1181.0, 645.0), "tipo": "casa", "sua": true },
	# O vizinho do bunker do roteiro do tutorial (design/narrativa.md): a casa
	# colada a leste da sua, a mais fortificada do bairro (Joao, 20/10/2026).
	# Selada como a sua - ninguem entra; fala-se com ele no portao. Sem movel e
	# sem zumbi na porta.
	{ "nome": "Casa do Antônio", "ponto": Vector2(1214.0, 647.0), "tipo": "casa", "selada": true },
	{ "nome": "Campo ANEV (norte)", "ponto": Vector2(950.0, 455.0), "tipo": "campo" },
	{ "nome": "Campo ANEV (sul)", "ponto": Vector2(1376.0, 700.0), "tipo": "campo" },
	{ "nome": "Prisão", "ponto": Vector2(1005.0, 670.0), "tipo": "prisao" },
	{ "nome": "Igreja", "ponto": Vector2(1330.0, 455.0), "tipo": "igreja" },
	{ "nome": "Mercado", "ponto": Vector2(1330.0, 548.0), "tipo": "mercado" },
	{ "nome": "Lojas", "ponto": Vector2(1208.0, 543.0), "tipo": "lojas" },
	{ "nome": "Mercadinho", "ponto": Vector2(1068.0, 400.0), "tipo": "comercio" },
	{ "nome": "Loja", "ponto": Vector2(611.0, 413.0), "tipo": "comercio" },
	{ "nome": "Farmácia", "ponto": Vector2(872.0, 540.0), "tipo": "farmacia" },
	{ "nome": "Academia", "ponto": Vector2(1045.0, 540.0), "tipo": "academia" },
	{ "nome": "Banco", "ponto": Vector2(1038.0, 588.0), "tipo": "banco" },
	{ "nome": "ETA", "ponto": Vector2(1082.0, 598.0), "tipo": "eta" },
	{ "nome": "Rádio", "ponto": Vector2(1252.0, 252.0), "tipo": "radio" },
	{ "nome": "Hotel", "ponto": Vector2(632.0, 545.0), "tipo": "hotel" },
	{ "nome": "Bar do Zé", "ponto": Vector2(724.0, 563.0), "tipo": "bar" },
	{ "nome": "Casa do Zé", "ponto": Vector2(727.0, 592.0), "tipo": "casa" },
	# Retangulo a mao: a mancha e torta e o nome escrito em cima dela, em fonte
	# miuda, parte a mancha ao meio para o tracador. A porta olha para a rua.
	{ "nome": "Restaurante", "ponto": Vector2(1200.0, 740.0), "tipo": "restaurante",
		"rect": Rect2(1170.0, 737.0, 50.0, 16.0), "porta": "norte" },
	{ "nome": "Posto", "ponto": Vector2(715.0, 508.0), "tipo": "posto" },
	# Os dois anexos do posto, lidos nos prints do desenho em 15/10/2026: a
	# conveniencia e a mancha de baixo, a esquerda; a oficina a da direita.
	{ "nome": "Conveniência", "ponto": Vector2(712.0, 528.0), "tipo": "comercio" },
	{ "nome": "Oficina", "ponto": Vector2(735.0, 525.0), "tipo": "galpao" },
	{ "nome": "Prédio em construção", "ponto": Vector2(785.0, 560.0), "tipo": "predio_em_construcao" },
	{ "nome": "Prédio abandonado", "ponto": Vector2(1293.0, 640.0), "tipo": "predio_abandonado" },
	{ "nome": "Parque industrial (galpão 1)", "ponto": Vector2(727.0, 633.0), "tipo": "armazem" },
	{ "nome": "Parque industrial (galpão 2)", "ponto": Vector2(727.0, 690.0), "tipo": "armazem" },
	{ "nome": "Parque industrial (galpão 3)", "ponto": Vector2(727.0, 727.0), "tipo": "armazem" },
	{ "nome": "Galpão da fazenda", "ponto": Vector2(768.0, 296.0), "tipo": "galpao" },
	# A estrada de terra do sudoeste, lida nos prints do desenho em 15/10/2026:
	# a casa afastada do velho louco e o galpao dele logo acima, a direita; e
	# as casas abandonadas perto da rua ("queimadas melhor ainda", escreveu o
	# Joao - a arte da queimada fica para depois). Das duas abandonadas so
	# uma virou predio; a outra e bloco solido, pequena demais no desenho.
	{ "nome": "Galpão dele", "ponto": Vector2(556.0, 707.0), "tipo": "galpao" },
	{ "nome": "Casa afastada do velho louco", "ponto": Vector2(529.0, 720.0), "tipo": "casa" },
	{ "nome": "Casa abandonada", "ponto": Vector2(640.0, 740.0), "tipo": "predio_abandonado", "queimada": true },
	{ "nome": "Casa abandonada", "ponto": Vector2(624.0, 743.0), "tipo": "predio_abandonado", "queimada": true },
	# A barraca do vendedor de melancia, na beira da rua ao sul do Hotel: a
	# mancha e inclinada e o tracador a aceita pela caixa (prints de 15/10).
	{ "nome": "Vendedor de melancia", "ponto": Vector2(664.0, 657.0), "tipo": "comercio" },
	# --- lugares (zonas sem prédio próprio) --------------------------------
	{ "nome": "Floresta", "ponto": Vector2(560.0, 500.0), "tipo": "zona" },
	{ "nome": "Milho", "ponto": Vector2(650.0, 275.0), "tipo": "zona" },
	{ "nome": "Fazenda", "rect": Rect2(700.0, 236.0, 95.0, 105.0), "tipo": "zona" },
	{ "nome": "Horta", "ponto": Vector2(748.0, 323.0), "tipo": "zona" },
	{ "nome": "Praça", "ponto": Vector2(1262.0, 440.0), "tipo": "zona" },
	{ "nome": "Cemitério", "ponto": Vector2(1150.0, 410.0), "tipo": "zona" },
	{ "nome": "Campinho", "rect": Rect2(1054.0, 310.0, 30.0, 40.0), "tipo": "zona" },
	{ "nome": "Estacionamento", "rect": Rect2(1075.0, 520.0, 40.0, 45.0), "tipo": "zona" },
	{ "nome": "Camping Motorhomes", "rect": Rect2(812.0, 600.0, 105.0, 145.0), "tipo": "zona" },
	{ "nome": "Parque industrial", "rect": Rect2(688.0, 605.0, 85.0, 152.0), "tipo": "zona" },
]

## Zumbis soltos na rua, em px do PNG - cruzamentos, o camping, a mata. Todo
## prédio ainda ganha um na frente da porta (ver `_zumbis`). **Proposta**,
## como sempre foi: onde zumbi nasce não foi decidido pela equipe.
const ZUMBIS_NA_RUA := [
	Vector2(640.0, 480.0), Vector2(690.0, 700.0), Vector2(560.0, 600.0), Vector2(598.0, 300.0),
	Vector2(900.0, 512.0), Vector2(1150.0, 512.0), Vector2(1300.0, 512.0), Vector2(1250.0, 650.0),
	Vector2(870.0, 690.0), Vector2(1012.0, 606.0), Vector2(1250.0, 420.0), Vector2(1255.0, 600.0),
	Vector2(1040.0, 330.0), Vector2(960.0, 300.0), Vector2(640.0, 250.0), Vector2(1200.0, 330.0),
]

## As barreiras: muros, cercas e barricadas em linha (21/10/2026; as regras de
## cada tipo estao em rua/barreira.gd). Cada uma e uma polilinha em px do PNG,
## como os ROTULOS: `tipo` (Barreira.TIPOS), `pontos`, `vaos` - cada um
## { "ponto", "largura_mundo", "portao" }, com o portao (um tipo) fechando o
## vao ou null deixando-o aberto -, `grupo` ("cerco_do_tutorial" ou "") e,
## opcionais, `fechada`, `topo`, `estado`, `cor` e `porque`. O cerco do tutorial
## e o grupo "cerco_do_tutorial": a regiao rosa do Joao, fechada sempre, por
## enquanto (ver `cerco_ligado`).
const BARREIRAS := []

## As barricadas soltas (Barreira.OBJETOS): `tipo`, `ponto` (px do PNG),
## `giro_graus`, `grupo`.
const BARRICADAS := []

## A regiao do tutorial, em px do PNG: o contorno rosa do Joao (20/10/2026),
## encaixado nas linhas e predios do desenho. E o que o conferir_mapa usa para
## provar que o cerco fecha, e onde a horda da noite nasce quando o jogador
## esta dentro.
const REGIAO_DO_TUTORIAL := []

## O cerco do tutorial existe. **Fica sempre, por enquanto** (Joao, 20/10:
## como o resto do mapa abre se decide depois); as ferramentas desligam para
## conferir o mapa inteiro. Mude antes de o mapa montar.
static var cerco_ligado := true

## Esquece o mundo montado, e a proxima leitura monta de novo. So para as
## ferramentas: o conferir_mapa confere com o cerco ligado e desligado.
static func remontar() -> void:
	_montado = {}

## Quanto o jogador nasce afastado da porta, para fora. Maior que a meia
## altura da zona de detecção da porta (50 px desde 20/10/2026, eram 80) mais
## a dele, senão o dia começaria com você já dentro dela.
const RECUO_DO_NASCIMENTO := 110.0

## Quanto um zumbi nasce afastado da porta de cada prédio.
const RECUO_DO_ZUMBI := 260.0

## O tamanho (em px de mundo) do lugar de uma zona sem `rect` próprio: uma
## janela em volta do ponto do rótulo, cortada pela mancha de chão que o
## contém. 100 x 60 px do desenho.
const ZONA_EM_VOLTA_DO_ROTULO := Vector2(2400.0, 1440.0)

## Prédio com menos do que isto de frente ou de fundo (em px de mundo) não
## cabe três quartos com móvel dentro: vira o tipo de um quarto só.
##
## O fundo sai da conta da sala: ela tem 45% do interior menos a divisória
## (20), e o móvel dela encosta na divisória ocupando 46 px; o que sobra até
## a fachada tem que caber o corpo do jogador (40) com folga para a grade de
## 24 px do conferir_mapa achar uma fileira (e a de 32 px da navegação do
## zumbi também): 0,45 x (fundo - 40) - 20 - 46 >= 64 dá fundo >= 329.
## Com 312 (13 px do desenho) a estante da sala fechava a casa inteira.
const FRENTE_MINIMA_PARA_TRES_QUARTOS := 300.0
const FUNDO_MINIMO_PARA_TRES_QUARTOS := 340.0

## Tons de telhado e de lote por classe do desenho - o cenário e os telhados
## leem daqui para o vermelho do desenho continuar lendo como "importante".
const CLASSE_DO_PREDIO := {
	"vermelho": { "telhado": Color("3a2c2c"), "lote": Color("4a3b3b") },
	"marrom": { "telhado": Color("2a2e31"), "lote": Color("463f36") },
	"cinza": { "telhado": Color("30343a"), "lote": Color("474a4e") },
}

static var _montado: Dictionary = {}
static var _sua_casa: Dictionary = {}
static var _lugares: Array = []
static var _recorte := Rect2()

## O mundo montado, em coordenada de mundo. Montado uma vez e guardado: o
## cenário, os telhados e as ferramentas leem todos daqui, e todos têm que ver
## o mesmo mapa.
static func mundo() -> Dictionary:
	if _montado.is_empty():
		_montado = _montar()
	return _montado

## Os lugares com nome, cada um com `nome`, `tipo` e `rect` (mundo). É o que
## a legenda escreve e o que o conferir_mapa cobra que se alcance a pé.
static func lugares() -> Array:
	mundo()
	return _lugares

## Um lugar pelo nome. Use isto, e não um índice: a lista muda de ordem a cada
## rótulo novo.
static func lugar(nome: String) -> Dictionary:
	for qual in lugares():
		if qual["nome"] == nome:
			return qual
	return {}

## O lugar em que o ponto está - o **menor** que o contém, para um prédio
## dentro de uma zona responder o prédio. "" se não está em nenhum.
static func lugar_em(ponto: Vector2) -> String:
	var melhor := ""
	var menor := INF
	for qual in lugares():
		var r: Rect2 = qual["rect"]
		if r.has_point(ponto) and r.get_area() < menor:
			menor = r.get_area()
			melhor = qual["nome"]
	return melhor

## Em qual construção está o ponto, ou -1. Os telhados usam para esconder o
## telhado de quem está dentro.
static func construcao_em(ponto: Vector2) -> int:
	var construcoes: Array = mundo()["construcoes"]
	for i in construcoes.size():
		if (construcoes[i]["rect"] as Rect2).has_point(ponto):
			return i
	return -1

## A sua casa: a única construção marcada com "sua". Não se vasculha, e é a
## fachada dela que tem a porta por onde o dia acaba.
static func sua_casa() -> Dictionary:
	mundo()
	return _sua_casa

## Onde o jogador nasce: na calçada, em frente à porta de casa.
static func onde_o_jogador_nasce() -> Vector2:
	var casa := sua_casa()
	return onde_fica_a_porta_de_casa() + Construcao.normal_de(casa) * RECUO_DO_NASCIMENTO

## A porta de casa, que é por onde o dia acaba: o vão da fachada, pelo mesmo
## `porta_de()` de qualquer prédio.
static func onde_fica_a_porta_de_casa() -> Vector2:
	return Construcao.porta_de(sua_casa())

## Para que lado a porta da sua casa olha - "norte", "sul", "leste" ou "oeste".
static func lado_da_porta_de_casa() -> String:
	return sua_casa()["porta"]

## Uma construcao do tipo pedido, a mais perto de `de`, com a frente da porta
## livre: nada solido (outro predio, bloco, agua, veiculo, nem os retangulos
## extras que quem chama passar - arvores, por exemplo) a ate `alcance` px do
## vao, e com pelo menos `frente_minima` de fachada. `{}` se nao houver.
##
## E o que as ferramentas de conferencia usam para escolher a casa de teste
## (30/09/2026): o desenho tem carro parado na porta de meia cidade e casa de
## costas para a borda do mundo, e "a primeira casa da lista" media o
## estacionamento em vez do zumbi.
static func construcao_com_a_frente_livre(tipo: String, de: Vector2, alcance: float,
		frente_minima: float, extras: Array = []) -> Dictionary:
	var candidatas: Array = []
	for c in mundo()["construcoes"]:
		if c["tipo"] == tipo and not c.get("sua", false) and not c.get("selada", false):
			candidatas.append(c)
	candidatas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["rect"] as Rect2).get_center().distance_to(de) \
			< (b["rect"] as Rect2).get_center().distance_to(de))
	for c in candidatas:
		if Construcao.frente_de(c) < frente_minima:
			continue
		var porta := Construcao.porta_de(c)
		var frente := Rect2(porta, Vector2.ZERO).expand(porta + Construcao.normal_de(c) * alcance).grow(60.0)
		if not MUNDO.encloses(frente):
			continue
		if _tem_algo_solido_em(frente, c, extras):
			continue
		return c
	return {}

static func _tem_algo_solido_em(area: Rect2, menos: Dictionary, extras: Array) -> bool:
	var tudo := mundo()
	for outra in tudo["construcoes"]:
		if outra != menos and (outra["rect"] as Rect2).intersects(area):
			return true
	for obstaculo in tudo["obstaculos"]:
		if (obstaculo["rect"] as Rect2).intersects(area):
			return true
	for solido in tudo["solidos"]:
		if (solido as Rect2).intersects(area):
			return true
	for movel in tudo["moveis_de_rua"]:
		var r := Rect2((movel["pos"] as Vector2) - (movel["tamanho"] as Vector2) / 2.0, movel["tamanho"])
		if r.intersects(area):
			return true
	for extra in extras:
		if (extra as Rect2).intersects(area):
			return true
	return _tem_barreira_em(tudo, area)

## Um ponto do PNG original (px, como um editor de imagem mostra) em
## coordenada de mundo - para ferramenta que quer apontar um lugar do desenho.
static func ponto_do_png(ponto: Vector2) -> Vector2:
	mundo()
	return _do_png(ponto, _recorte)

## Calçada não existe mais como peça própria: o pavimento do desenho é chão
## pintado. Fica pela compatibilidade de quem perguntava.
static func calcadas() -> Array[Rect2]:
	var nada: Array[Rect2] = []
	return nada

# ------------------------------------------------------------------ montagem

## Um ponto do PNG original para o mundo.
static func _do_png(ponto: Vector2, recorte: Rect2) -> Vector2:
	return (ponto - recorte.position) * ESCALA

static func _rect_do_png(rect: Rect2, recorte: Rect2) -> Rect2:
	return Rect2(_do_png(rect.position, recorte), rect.size * ESCALA)

## Um retângulo do JSON (px do recorte) para o mundo.
static func _rect_do_tracado(lista: Array) -> Rect2:
	return Rect2(float(lista[0]) * ESCALA, float(lista[1]) * ESCALA,
		float(lista[2]) * ESCALA, float(lista[3]) * ESCALA)

static func _pontos_do_tracado(lista: Array) -> PackedVector2Array:
	var fora := PackedVector2Array()
	for p in lista:
		fora.append(Vector2(float(p[0]) * ESCALA, float(p[1]) * ESCALA))
	return fora

static func _ler_tracado() -> Dictionary:
	var texto := FileAccess.get_file_as_string(ARQUIVO_DO_TRACADO)
	assert(texto != "", "nao achei %s - rode node design/tracar_desenho.js" % ARQUIVO_DO_TRACADO)
	var dado = JSON.parse_string(texto)
	assert(dado is Dictionary, "%s nao e JSON valido" % ARQUIVO_DO_TRACADO)
	return dado

static func _montar() -> Dictionary:
	var tracado := _ler_tracado()
	var recorte_lista: Array = tracado["recorte"]
	var recorte := Rect2(float(recorte_lista[0]), float(recorte_lista[1]),
		float(recorte_lista[2]), float(recorte_lista[3]))
	_recorte = recorte
	assert(is_equal_approx(recorte.size.x * ESCALA, MUNDO.size.x)
		and is_equal_approx(recorte.size.y * ESCALA, MUNDO.size.y),
		"MUNDO (%s) nao bate com o recorte do desenho (%s x %s) vezes ESCALA - o desenho mudou de tamanho?"
		% [MUNDO.size, recorte.size.x, recorte.size.y])

	var tudo := {
		"construcoes": [],
		"lotes": [],
		"poligonos": [],
		"bosques": [],
		"obstaculos": [],
		"moveis_de_rua": [],
		"zumbis": [],
		"agua": [],
		"solidos": [],
		# As barreiras (21/10/2026): trechos já cortados nos vãos, em mundo.
		"barreiras": [],
		"barricadas": [],
		# Peças que o mapa anterior tinha e o cenário ainda sabe ler. Vazias.
		"cercas": [],
		"piso": [],
		"lavoura": [],
	}

	# O chão: todo polígono, com os furos, em ordem de área (quem pinta
	# pinta nesta ordem, então o furo de um sai por cima dele).
	for p in tracado["poligonos"]:
		var poligono := {
			"classe": p["classe"],
			"pontos": _pontos_do_tracado(p["pontos"]),
			"furos": [],
			"area": float(p["area"]) * ESCALA * ESCALA,
			"rect": _rect_do_tracado(p["bbox"]),
		}
		for furo in p["furos"]:
			(poligono["furos"] as Array).append(_pontos_do_tracado(furo))
		tudo["poligonos"].append(poligono)
		if p["classe"] == "mata":
			tudo["bosques"].append(poligono)
		elif p["classe"] == "agua":
			tudo["agua"].append(poligono)
			tudo["solidos"].append(poligono["rect"])

	# Os prédios: cada mancha vira um lote pintado e um ou mais retângulos.
	for i in (tracado["predios"] as Array).size():
		var predio: Dictionary = tracado["predios"][i]
		tudo["lotes"].append({
			"classe": predio["classe"],
			"pontos": _pontos_do_tracado(predio["pontos"]),
			"rect": _rect_do_tracado(predio["bbox"]),
		})
		var rects: Array = predio["rects"]
		for j in rects.size():
			var rect := _rect_do_tracado(rects[j]["rect"])
			var construcao := {
				"rect": rect, "porta": rects[j]["porta"], "classe": predio["classe"],
				"lote": i, "anexo": j > 0,
				"tipo": _tipo_padrao(predio["classe"], rect, j > 0),
				"nome": "",
			}
			tudo["construcoes"].append(construcao)

	for o in tracado["obstaculos"]:
		tudo["obstaculos"].append({ "classe": o["classe"], "rect": _rect_do_tracado(o["rect"]) })

	for v in tracado["veiculos"]:
		var deitado: bool = v.get("deitado", true)
		var tipo := _tipo_do_veiculo(v, recorte)
		var tamanho: Vector2 = Construcao.MOVEIS[tipo]["tamanho"]
		if not deitado:
			tamanho = Vector2(tamanho.y, tamanho.x)
		tudo["moveis_de_rua"].append({
			"tipo": tipo, "tamanho": tamanho,
			"pos": Vector2(float(v["pos"][0]) * ESCALA, float(v["pos"][1]) * ESCALA),
		})

	_rotular(tudo, tracado, recorte)
	_encolher_quem_nao_cabe(tudo)
	# Antes dos zumbis: ponto de zumbi em cima de muro e pulado.
	_barreiras(tudo, recorte)
	_zumbis(tudo, recorte)
	return tudo

## As barreiras e as barricadas em coordenada de mundo. Cada trecho continuo de
## uma barreira, depois de cortados os vaos, vira uma entrada { nome, tipo,
## grupo, pontos }; o vao com portao vira um trecho do tipo do portao. Quem
## consome nunca ve vao. O cerco do tutorial so entra com `cerco_ligado`.
static func _barreiras(tudo: Dictionary, recorte: Rect2) -> void:
	for barreira in BARREIRAS:
		var grupo: String = barreira.get("grupo", "")
		if grupo == "cerco_do_tutorial" and not cerco_ligado:
			continue
		var pontos := PackedVector2Array()
		for p in barreira["pontos"]:
			pontos.append(_do_png(p, recorte))
		if barreira.get("fechada", false) and pontos.size() > 2:
			pontos.append(pontos[0])
		var vaos: Array = []
		for vao in barreira.get("vaos", []):
			vaos.append({ "ponto": _do_png(vao["ponto"], recorte),
				"largura": float(vao.get("largura_mundo", Barreira.VAO)), "portao": vao.get("portao") })
		var nome: String = barreira.get("nome", "")
		for trecho in Barreira.trechos(pontos, vaos):
			tudo["barreiras"].append({ "nome": nome, "tipo": barreira["tipo"], "grupo": grupo, "pontos": trecho })
		for vao in vaos:
			if vao["portao"] != null:
				tudo["barreiras"].append({ "nome": "%s (portão)" % nome, "tipo": vao["portao"],
					"grupo": grupo, "pontos": Barreira.vao_na_linha(pontos, vao) })
	for objeto in BARRICADAS:
		var grupo: String = objeto.get("grupo", "")
		if grupo == "cerco_do_tutorial" and not cerco_ligado:
			continue
		tudo["barricadas"].append({ "nome": objeto.get("nome", ""), "tipo": objeto["tipo"], "grupo": grupo,
			"pos": _do_png(objeto["ponto"], recorte), "giro": float(objeto.get("giro_graus", 0.0)) })
	# A caixa de todas: quem pergunta longe dela (a arvore do outro lado do
	# mapa) nao precisa olhar barreira por barreira.
	var caixa := Rect2()
	var primeira := true
	for barreira in tudo["barreiras"]:
		for p in barreira["pontos"]:
			caixa = Rect2(p, Vector2.ZERO) if primeira else caixa.expand(p)
			primeira = false
	for barricada in tudo["barricadas"]:
		for p in cantos_da_barricada(barricada):
			caixa = Rect2(p, Vector2.ZERO) if primeira else caixa.expand(p)
			primeira = false
	if not primeira:
		tudo["caixa_das_barreiras"] = caixa.grow(32.0)

## Os quatro cantos de uma barricada girada, em mundo.
static func cantos_da_barricada(barricada: Dictionary) -> PackedVector2Array:
	var meio: Vector2 = Barreira.OBJETOS[barricada["tipo"]]["tamanho"] / 2.0
	var giro := deg_to_rad(barricada["giro"])
	var cantos := PackedVector2Array()
	for c in [Vector2(-meio.x, -meio.y), Vector2(meio.x, -meio.y), Vector2(meio.x, meio.y), Vector2(-meio.x, meio.y)]:
		cantos.append((barricada["pos"] as Vector2) + c.rotated(giro))
	return cantos

## Se alguma barreira ou barricada passa dentro de `area` (mundo).
static func tem_barreira_em(area: Rect2) -> bool:
	return _tem_barreira_em(mundo(), area)

## A mesma pergunta sobre um mundo dado - a montagem chama isto antes de o
## mundo existir (mundo() ali entraria em laco).
static func _tem_barreira_em(tudo: Dictionary, area: Rect2) -> bool:
	if not tudo.has("caixa_das_barreiras") or not (tudo["caixa_das_barreiras"] as Rect2).intersects(area):
		return false
	for barreira in tudo["barreiras"]:
		var pontos: PackedVector2Array = barreira["pontos"]
		for i in range(1, pontos.size()):
			if _segmento_cruza(pontos[i - 1], pontos[i], area):
				return true
	for barricada in tudo["barricadas"]:
		var cantos := cantos_da_barricada(barricada)
		var caixa := Rect2(cantos[0], Vector2.ZERO)
		for c in cantos:
			caixa = caixa.expand(c)
		if caixa.intersects(area):
			return true
	return false

static func _segmento_cruza(a: Vector2, b: Vector2, area: Rect2) -> bool:
	if area.has_point(a) or area.has_point(b):
		return true
	var c := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, c[i], c[(i + 1) % 4]) != null:
			return true
	return false

## A regiao do tutorial em mundo (ver REGIAO_DO_TUTORIAL).
static func regiao_do_tutorial() -> PackedVector2Array:
	mundo()
	var fora := PackedVector2Array()
	for p in REGIAO_DO_TUTORIAL:
		fora.append(_do_png(p, _recorte))
	return fora

## Se o ponto esta dentro da regiao do tutorial. Sem regiao, ninguem esta.
static func dentro_do_cerco(ponto: Vector2) -> bool:
	var regiao := regiao_do_tutorial()
	return regiao.size() >= 3 and Geometry2D.is_point_in_polygon(ponto, regiao)

## Veículos do desenho com nome próprio (15/10/2026, lidos nos prints do
## Canva): o azul perto do ponto vira o tipo dito, em vez de "carro". Ponto em
## px do PNG, como os ROTULOS; o veículo precisa estar a menos de
## RAIO_DO_VEICULO_ROTULADO px dele.
const VEICULOS_ROTULADOS := [
	{ "ponto": Vector2(712.0, 258.0), "tipo": "trator" },  # fazenda, à esquerda da casa
	{ "ponto": Vector2(748.0, 271.0), "tipo": "caminhonete" },  # fazenda, abaixo da casa
	{ "ponto": Vector2(570.0, 712.0), "tipo": "caminhonete" },  # ao lado do galpão do velho louco
]
const RAIO_DO_VEICULO_ROTULADO := 8.0

## O tipo de um veículo do traçado: o rotulado se houver um perto, senão
## "motorhome" para o comprido e "carro" para o resto.
static func _tipo_do_veiculo(v: Dictionary, recorte: Rect2) -> String:
	var pos := Vector2(float(v["pos"][0]), float(v["pos"][1]))
	for rotulo in VEICULOS_ROTULADOS:
		if pos.distance_to(rotulo["ponto"] - recorte.position) <= RAIO_DO_VEICULO_ROTULADO:
			return rotulo["tipo"]
	return "motorhome" if v.get("comprido", false) else "carro"

## O tipo de um prédio que o desenho não nomeou, pela cor e pelo tamanho.
static func _tipo_padrao(classe: String, rect: Rect2, anexo: bool) -> String:
	if anexo:
		return "anexo"
	match classe:
		"marrom":
			return "casa" if minf(rect.size.x, rect.size.y) >= FRENTE_MINIMA_PARA_TRES_QUARTOS else "galpao"
		"cinza":
			return "comercio"
		_:
			return "comercio"

## Casa os ROTULOS com o traçado: prédio ganha nome, tipo e extras; o que não
## cai em prédio vira lugar. Todo prédio nomeado também vira um lugar (o
## retângulo da mancha inteira), para a legenda e o conferir.
static func _rotular(tudo: Dictionary, tracado: Dictionary, recorte: Rect2) -> void:
	_lugares = []
	_sua_casa = {}
	var predios: Array = tracado["predios"]
	for rotulo in ROTULOS:
		var nome: String = rotulo["nome"]
		if rotulo["tipo"] == "zona" and rotulo.has("rect"):
			_lugares.append({ "nome": nome, "tipo": "zona",
				"rect": _rect_do_png(rotulo["rect"], recorte) })
			continue
		var ponto: Vector2 = rotulo["ponto"] - recorte.position  # px do recorte
		# A mancha MAIS JUSTA que contem o ponto - a caixa de uma mancha grande
		# (a Escola) cobre a caixa de uma vizinha pequena (a Radio), e o
		# primeiro que aparecesse levaria o nome errado. Mancha cujo retangulo
		# cortado contem o ponto ganha de mancha que so o contem na caixa.
		var achou := -1
		var melhor_nota := -INF
		for i in predios.size():
			var b: Array = predios[i]["bbox"]
			var caixa := Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
			if not caixa.has_point(ponto):
				continue
			var nota := -caixa.get_area()
			for r in predios[i]["rects"]:
				var lista: Array = r["rect"]
				if Rect2(float(lista[0]), float(lista[1]), float(lista[2]), float(lista[3])).has_point(ponto):
					nota += 1000000.0
					break
			if nota > melhor_nota:
				melhor_nota = nota
				achou = i
		if achou < 0:
			# Zona: o polígono de chão que contém o ponto.
			var no_mundo := ponto * ESCALA
			var dono := {}
			for poligono in tudo["poligonos"]:
				if Geometry2D.is_point_in_polygon(no_mundo, poligono["pontos"]):
					if dono.is_empty() or poligono["area"] < dono["area"]:
						dono = poligono
			assert(not dono.is_empty(), "o rotulo '%s' nao cai em predio nem em chao nenhum" % nome)
			# O lugar e uma janela em volta do PONTO do rotulo, dentro da caixa
			# do poligono - nao a caixa inteira: a da Floresta cobre meio mapa
			# (as manchas de mata se tocam), e "Floresta" cairia no meio da
			# cidade, com meia cidade respondendo "Floresta" em `lugar_em`.
			var caixa: Rect2 = dono["rect"]
			var janela := Rect2(no_mundo - ZONA_EM_VOLTA_DO_ROTULO / 2.0, ZONA_EM_VOLTA_DO_ROTULO)
			_lugares.append({ "nome": nome, "tipo": rotulo["tipo"], "rect": janela.intersection(caixa) })
			continue
		# Prédio: o retângulo da mancha que contém o ponto, senão o principal.
		var alvo := {}
		for construcao in tudo["construcoes"]:
			if construcao["lote"] != achou:
				continue
			if alvo.is_empty() or (construcao["rect"] as Rect2).has_point(ponto * ESCALA):
				alvo = construcao
				if (construcao["rect"] as Rect2).has_point(ponto * ESCALA):
					break
		assert(not alvo.is_empty(), "o rotulo '%s' caiu numa mancha sem retangulo" % nome)
		if alvo["nome"] != "":
			push_warning("o rotulo '%s' caiu no mesmo predio que '%s' - dois nomes para uma mancha so"
				% [nome, alvo["nome"]])
		alvo["nome"] = nome
		alvo["tipo"] = rotulo["tipo"]
		if rotulo.has("rect"):
			# Retangulo escrito a mao (px do PNG), para a mancha que o tracador
			# nao corta bem - o Restaurante, torto e com o nome escrito em cima.
			alvo["rect"] = _rect_do_png(rotulo["rect"], recorte)
		if rotulo.has("porta"):
			alvo["porta"] = rotulo["porta"]
		if rotulo.has("documento"):
			alvo["documento"] = rotulo["documento"]
		if rotulo.get("sua", false):
			alvo["sua"] = true
			_sua_casa = alvo
		if rotulo.get("selada", false):
			# Selada como a sua: sem movel, sem zumbi na porta, e o
			# conferir_mapa cobra que nenhum quarto dela se alcance a pe.
			alvo["selada"] = true
		if rotulo.get("queimada", false):
			# Casa queimada (15/10/2026): telhado, parede e piso carbonizados
			# (rua/telhados.gd e rua/cenario.gd); o anexo herda abaixo.
			alvo["queimada"] = true
		var rect_do_lugar := _rect_do_tracado(predios[achou]["bbox"])
		if rotulo.has("rect"):
			rect_do_lugar = alvo["rect"]
		_lugares.append({ "nome": nome, "tipo": rotulo["tipo"],
			"rect": rect_do_lugar.grow(ESCALA * 2.0) })
	# Os anexos herdam o nome do dono.
	for construcao in tudo["construcoes"]:
		if not construcao["anexo"]:
			continue
		for outra in tudo["construcoes"]:
			if outra["lote"] == construcao["lote"] and not outra["anexo"] and outra["nome"] != "":
				construcao["nome"] = "%s (anexo)" % outra["nome"]
				if outra.get("queimada", false):
					construcao["queimada"] = true
				break
	assert(not _sua_casa.is_empty(), "nenhum rotulo tem \"sua\": true - o jogador nao tem onde nascer")

## Prédio pequeno demais para três quartos com móvel dentro vira o tipo de um
## quarto só do mesmo gênero. Sem isto a divisória interna nasceria em cima do
## móvel e o quarto do fundo ficaria sem passagem - o conferir_mapa pega, mas
## a regra é melhor que o achado.
static func _encolher_quem_nao_cabe(tudo: Dictionary) -> void:
	for construcao in tudo["construcoes"]:
		if Construcao.QUARTOS_POR_TIPO[construcao["tipo"]] < 3:
			continue
		var r: Rect2 = construcao["rect"]
		var frente := Construcao.frente_de(construcao)
		var fundo := Construcao.profundidade_de(construcao)
		if frente < FRENTE_MINIMA_PARA_TRES_QUARTOS or fundo < FUNDO_MINIMO_PARA_TRES_QUARTOS:
			construcao["tipo"] = Construcao.UM_QUARTO_SO.get(construcao["tipo"], "galpao")
			if construcao.get("sua", false):
				push_warning("a sua casa (%s) e pequena demais para tres quartos" % r)

## Onde zumbi nasce: um na frente de cada prédio que não é anexo, mais um na
## sala dos prédios importantes (vermelho), mais os soltos de ZUMBIS_NA_RUA.
## Ponto que cai dentro de parede, água ou outro prédio é pulado.
static func _zumbis(tudo: Dictionary, recorte: Rect2) -> void:
	for construcao in tudo["construcoes"]:
		if construcao["anexo"] or construcao.get("sua", false) or construcao.get("selada", false):
			continue
		var achou := false
		for distancia in [RECUO_DO_ZUMBI, RECUO_DO_ZUMBI * 0.6, RECUO_DO_ZUMBI * 1.5]:
			var onde := Construcao.em_frente(construcao, 0.5, distancia)
			if _da_para_nascer(tudo, onde):
				tudo["zumbis"].append(onde)
				achou = true
				break
		if construcao["classe"] == "vermelho":
			tudo["zumbis"].append(Construcao.quartos_de(construcao)[0].get_center())
	for ponto in ZUMBIS_NA_RUA:
		var onde := _do_png(ponto, recorte)
		if _da_para_nascer(tudo, onde):
			tudo["zumbis"].append(onde)
		else:
			push_warning("zumbi solto em %s (png) nasceria em cima de algo - pulado" % ponto)

static func _da_para_nascer(tudo: Dictionary, onde: Vector2) -> bool:
	if not MUNDO.grow(-200.0).has_point(onde):
		return false
	var corpo := Rect2(onde - Vector2(40.0, 40.0), Vector2(80.0, 80.0))
	for construcao in tudo["construcoes"]:
		if (construcao["rect"] as Rect2).grow(20.0).intersects(corpo):
			return false
	for obstaculo in tudo["obstaculos"]:
		if (obstaculo["rect"] as Rect2).grow(20.0).intersects(corpo):
			return false
	for solido in tudo["solidos"]:
		if (solido as Rect2).grow(20.0).intersects(corpo):
			return false
	for movel in tudo["moveis_de_rua"]:
		var r := Rect2((movel["pos"] as Vector2) - (movel["tamanho"] as Vector2) / 2.0, movel["tamanho"])
		if r.grow(20.0).intersects(corpo):
			return false
	return not _tem_barreira_em(tudo, corpo.grow(20.0))
