extends Node2D
## Greybox do mundo: desenha o chao no _draw() e gera no _ready() a colisao e os
## moveis, tudo a partir do `rua/mapa.gd`. Retangulo de cor chapada, sem imagem
## nenhuma e sem nada de binario para versionar.
##
## O layout NAO esta aqui - esta no mapa.gd (onde as coisas ficam) e no
## lugares.gd (do que cada lugar e feito). Aqui mora so a regra de como aquilo
## virou pixel e corpo solido.
##
## ## O que mudou com o mapa grande (09/09/2026)
##
## O mundo passou de 5.760 x 3.600 para 57.600 x 36.000 - **100x a area**. Tres
## coisas que funcionavam no bairro nao escalam, e estao resolvidas assim:
##
##  - **zumbi** nao existe no mapa inteiro, so num raio em volta do jogador.
##    Sao 13 vivos por perto em vez de centenas espalhadas, e e o que o PZ faz;
##  - **arvore e mato** tem orcamento fixo, distribuido pelos bosques por area.
##    Densidade constante num mapa 100x maior seria 100x o numero de nos;
##  - **navegacao** nao cobre o mundo (2 milhoes de celulas). Ver navegacao.gd.
##
## Descartavel de proposito: existe para a mecanica de vasculhar ter onde ser
## testada. O TileSet e o level design de verdade entram quando o layout parar
## de mudar.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const CENA_DO_MOVEL := preload("res://rua/vasculhavel.tscn")
const CENA_DO_ZUMBI := preload("res://rua/zumbi.tscn")
const Navegacao := preload("res://rua/navegacao.gd")

const ESPESSURA_DO_MURO := 400.0

## Quantos zumbis a noite traz, ao todo, das 19:00 as 05:00. **Proposta.**
##
## Em cima do povoamento por perto, a rua mais que dobra ao longo da noite - e e
## isso que faz voltar pra casa ser uma travessia em vez de uma caminhada. Nao e
## sistema de onda: e o povoamento continuando a acontecer, no ritmo do relogio.
const ZUMBIS_DA_NOITE := 14

## De quantos em quantos dias o bairro ganha um zumbi a mais. **Proposta.**
##
## E o "a rua vai ficando mais apocaliptica conforme os dias passam" do High
## Concept, na parte que muda o jogo e nao so a foto. E calibrado no
## PRAZO_DA_CURA: se o prazo mudar, este muda junto.
const UM_ZUMBI_A_MAIS_A_CADA := 2

## Tufos de mato a mais por dia. So estetica, e a metade barata da mesma frase:
## o terreno vai sendo tomado.
const MATO_A_MAIS_POR_DIA := 30

## **Zumbi so existe perto de voce.** Fora deste raio ele nem esta na arvore.
##
## 7.000 px sao 175 m, umas cinco telas e meia - longe o bastante para nunca se
## ver um aparecer do nada, e perto o bastante para nao haver centena de zumbi
## processando raycast num mapa de 1,44 km.
##
## O preco: ir longe e voltar repovoa o lugar. Guardar zumbi por lugar entre as
## idas e vindas e o que o PZ faz de verdade, e nao vale o custo enquanto o mapa
## e greybox.
const RAIO_VIVO := 7000.0
## Com folga para descarregar, senao um zumbi na fronteira nasce e morre todo
## quadro.
const RAIO_MORTO := 9800.0

## Orcamento de arvore e de mato para o mapa inteiro, distribuido pelos bosques
## por area. Numero de no, nao de densidade: 1.200 arvores sao 2.400 nos.
const ARVORES := 3000
const TUFOS_DE_MATO := 5000

# Paleta fria e dessaturada, que e a direcao de arte da rua: concreto,
# ferrugem, verde-acinzentado, ceu lavado.
const COR_GRAMA := Color("3b4438")
const COR_ASFALTO := Color("34383b")
const COR_CALCADA := Color("4d5154")
const COR_ENTRADA_DE_CARRO := Color("474b4d")
const COR_FAIXA := Color("6d6a55")
const COR_SUJEIRA := Color("3f4346")
const COR_MATO := Color("44513f")
const COR_ARVORE := Color("323e2c")
const COR_JUNTA := Color(0.0, 0.0, 0.0, 0.18)
const COR_PISO := Color("46403a")
const COR_PISO_SEU := Color("463a2e")
const COR_PAREDE := Color("6b6154")
const COR_CERCA := Color("5a5347")
## O rio e a unica coisa fria de verdade do mapa - todo o resto e concreto e
## mato. E o que faz a ponte se achar de longe.
const COR_AGUA := Color("2b3a44")
const COR_MARGEM := Color("3a4038")
const COR_CONCRETO := Color("53565a")

var _sorteio := RandomNumberGenerator.new()
var _moveis_gerados := 0
## Quantos documentos ja foram colocados. Decide qual dos seis sai no proximo
## lugar: cada um sai uma vez so.
var _documentos_colocados := 0

## O relogio do dia, achado pelo grupo. E aqui que ele se liga em cada movel:
## vasculhar gasta luz, e nem o movel nem o relogio precisam se conhecer para
## isso. Pode ser nulo - a cena da rua tem relogio, uma cena de teste com um
## movel solto nao precisa ter.
var _relogio: Node

## A mochila do dia, achada pelo grupo. Mesmo arranjo do relogio.
var _mochila: Node

## Quantos zumbis a noite ja trouxe hoje.
var _zumbis_da_noite := 0

## Quantos moveis nasceram vazios hoje porque foram vasculhados antes. Nao muda
## nada no jogo - e o numero que diz o quanto do mapa ja acabou.
var _moveis_ja_vazios := 0

## Todo retangulo que bloqueia passagem, juntado enquanto a colisao e criada.
## E a partir desta lista que a navegacao do zumbi e montada: os obstaculos
## aqui ja sao retangulos conhecidos, entao nao ha o que descobrir depois.
var _obstaculos: Array[Rect2] = []

## Os pontos de povoamento que ainda nao tem zumbi na arvore, e os que tem.
var _pontos_de_zumbi: Array[Vector2] = []
var _zumbis_vivos := {}

var _navegacao: Node
var _jogador: Node2D

## A ferramenta de conferencia do zumbi desliga isto.
##
## Ela teleporta o jogador para montar cada cena de teste, e com o povoamento
## ligado os zumbis que ela esta medindo sao liberados no meio da medicao - a
## primeira rodada depois do mapa grande deu "Invalid access to property
## '_estado' on a previously freed object" em loop. Desligado, o que nasceu no
## _ready fica onde esta.
var povoa_por_proximidade := true

func _ready() -> void:
	_sorteio.seed = 20260907
	# Antes de criar movel: e o _criar_movel que pendura os sinais nele. Os
	# grupos vem declarados no rua.tscn, entao ja existem mesmo que o _ready
	# deles ainda nao tenha rodado.
	_relogio = get_tree().get_first_node_in_group("relogio")
	_mochila = get_tree().get_first_node_in_group("mochila")

	var mundo := Mapa.mundo()

	for construcao in mundo["construcoes"]:
		for parede in Construcao.paredes_externas(construcao):
			_criar_corpo(parede)
		for parede in Construcao.paredes_internas(construcao):
			_criar_corpo(parede)
		_povoar(construcao)

	for cerca in mundo["cercas"]:
		_criar_corpo(cerca)
	# Solido e nao desenhado: o rio dos dois lados da ponte.
	for solido in mundo["solidos"]:
		_criar_corpo(solido)

	for movel in mundo["moveis_de_rua"]:
		_criar_movel(movel["tipo"], movel["pos"])

	_plantar_arvores()
	_criar_muros_do_mundo()
	# Depois de tudo: a navegacao le a lista de obstaculos que acabou de encher.
	_montar_navegacao()
	_preparar_povoamento()
	# Povoa ja aqui, e nao so no primeiro _process: as ferramentas de
	# conferencia leem a cena logo depois de montar, e um mapa sem zumbi nenhum
	# passaria por engano. O jogador ja esta na arvore mesmo que o _ready dele
	# ainda nao tenha rodado, porque o grupo vem do rua.tscn.
	_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
	if _jogador != null:
		_povoar_em_volta()
	# A camera do jogador so fica corrente depois que a cena inteira entra na
	# arvore, por isso o deferido.
	_limitar_camera.call_deferred()

# ------------------------------------------------------------------- desenho

func _draw() -> void:
	var mundo := Mapa.mundo()

	# A grama e o fundo de tudo: o que nao e rua, calcada nem construcao e
	# quintal, terreno e campo.
	draw_rect(Mapa.MUNDO, COR_GRAMA)
	_desenhar_mato(mundo)

	# O rio por baixo de tudo o que e feito de concreto, para a ponte aparecer
	# em cima dele.
	for agua in mundo["agua"]:
		var r: Rect2 = agua
		draw_rect(r.grow(40.0), COR_MARGEM)
		draw_rect(r, COR_AGUA)

	for construcao in mundo["construcoes"]:
		draw_rect(Construcao.entrada_de_carro(construcao), COR_ENTRADA_DE_CARRO)

	# Piso de concreto: pista de posto, patio de delegacia, estacionamento de
	# mercado, alameda da mansao e a ponte.
	for piso in mundo["piso"]:
		draw_rect(piso, COR_CONCRETO)

	for rua in mundo["ruas"]:
		draw_rect(rua, COR_ASFALTO)
	_desenhar_sujeira()
	_desenhar_faixas(mundo)

	for calcada in Mapa.calcadas():
		draw_rect(calcada, COR_CALCADA)
		_desenhar_juntas(calcada)

	# O piso e as paredes ficam escondidos pelo telhado enquanto o jogador
	# estiver fora - ver rua/telhados.gd.
	for construcao in mundo["construcoes"]:
		var piso := COR_PISO_SEU if construcao.get("sua", false) else COR_PISO
		draw_rect(Construcao.interior_de(construcao), piso)
		for parede in Construcao.paredes_externas(construcao):
			draw_rect(parede, COR_PAREDE)
		for parede in Construcao.paredes_internas(construcao):
			draw_rect(parede, COR_PAREDE)

	for cerca in mundo["cercas"]:
		draw_rect(cerca, COR_CERCA)

## Faixa central tracejada em cada rua. Nao e enfeite: num asfalto liso o
## jogador parece parado, porque quem se mexe na tela e o cenario.
func _desenhar_faixas(mundo: Dictionary) -> void:
	for rua in mundo["ruas"]:
		var r: Rect2 = rua
		if r.size.x > r.size.y:
			var y := r.get_center().y - 7.0
			var x := r.position.x + 60.0
			while x < r.end.x:
				# Sem tracejado por cima do rio nem de outro cruzamento.
				if not _sobre_agua(mundo, Vector2(x, y)):
					draw_rect(Rect2(x, y, 100.0, 14.0), COR_FAIXA)
				x += 180.0
			continue
		var cx := r.get_center().x - 7.0
		var cy := r.position.y + 60.0
		while cy < r.end.y:
			if not Mapa.RODOVIA.has_point(Vector2(cx, cy)):
				draw_rect(Rect2(cx, cy, 14.0, 100.0), COR_FAIXA)
			cy += 180.0

func _sobre_agua(mundo: Dictionary, ponto: Vector2) -> bool:
	for agua in mundo["agua"]:
		if (agua as Rect2).has_point(ponto):
			return true
	return false

## Juntas do concreto, pelo mesmo motivo da faixa: referencia de movimento.
func _desenhar_juntas(calcada: Rect2) -> void:
	if calcada.size.x > calcada.size.y:
		var x := calcada.position.x
		while x <= calcada.end.x:
			draw_line(Vector2(x, calcada.position.y), Vector2(x, calcada.end.y), COR_JUNTA, 2.0)
			x += 130.0
		return
	var y := calcada.position.y
	while y <= calcada.end.y:
		draw_line(Vector2(calcada.position.x, y), Vector2(calcada.end.x, y), COR_JUNTA, 2.0)
		y += 130.0

## Semente fixa para o desenho ser o mesmo em toda execucao - sujeira que muda
## de lugar a cada redraw pisca e atrapalha em vez de ajudar.
func _desenhar_sujeira() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260907
	var rua := Mapa.RODOVIA
	for _pedaco in 900:
		var lado := sorteio.randf_range(8.0, 30.0)
		var posicao := Vector2(
			sorteio.randf_range(rua.position.x, rua.end.x - lado),
			sorteio.randf_range(rua.position.y, rua.end.y - lado)
		)
		draw_rect(Rect2(posicao, Vector2(lado, lado * sorteio.randf_range(0.4, 1.0))), COR_SUJEIRA)

## Mato **dentro dos bosques**, e nao no mundo inteiro.
##
## Com 100x a area, densidade constante daria dezenas de milhares de retangulos
## num unico canvas item, que o Godot desenha inteiro todo quadro. O orcamento e
## fixo e se reparte pelos bosques por area: mata fechada, campo limpo - que
## tambem le melhor do que tufo espalhado por igual.
func _desenhar_mato(mundo: Dictionary) -> void:
	var bosques: Array = mundo["bosques"]
	if bosques.is_empty():
		return
	var peso_total := _peso_dos_bosques(bosques)
	if peso_total <= 0.0:
		return

	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260908
	# Cresce com o dia: mesma semente, mais tufos - entao o mato de ontem
	# continua onde estava e o de hoje aparece em volta.
	var orcamento := TUFOS_DE_MATO + (Travessia.dia - 1) * MATO_A_MAIS_POR_DIA

	for bosque in bosques:
		var r: Rect2 = bosque["rect"]
		var quantos := int(float(orcamento) * (_peso_de(bosque) / peso_total))
		for _tufo in quantos:
			var lado := sorteio.randf_range(14.0, 46.0)
			if r.size.x <= lado or r.size.y <= lado:
				continue
			var posicao := Vector2(
				sorteio.randf_range(r.position.x, r.end.x - lado),
				sorteio.randf_range(r.position.y, r.end.y - lado)
			)
			draw_rect(Rect2(posicao, Vector2(lado, lado * 0.55)), COR_MATO)

# -------------------------------------------------------------------- geracao

## Um movel por vaga de cada quarto, distribuidos pela parede do fundo do
## quarto. E o jeito do PZ: o loot esta dentro, em movel, e nao na calcada.
func _povoar(construcao: Dictionary) -> void:
	# A sua casa nao se vasculha - o que tem lá dentro e o porao.
	if construcao.get("sua", false):
		return

	var quartos := Construcao.quartos_de(construcao)
	var vagas: Array = Construcao.MOVEIS_POR_QUARTO[construcao["tipo"]]

	var ao_sul: bool = Construcao.e_da_frente_ao_sul(construcao)
	# O documento do lugar fica no **ultimo** quarto, que e o mais fundo: o que
	# custa mais para chegar paga o que vale mais.
	var quarto_do_documento := -1
	if construcao.get("documento", false):
		quarto_do_documento = mini(quartos.size(), vagas.size()) - 1

	for i in quartos.size():
		if i >= vagas.size():
			break
		var quarto: Rect2 = quartos[i]
		var tipos: Array = vagas[i]
		for j in tipos.size():
			var tamanho: Vector2 = Construcao.MOVEIS[tipos[j]]["tamanho"]

			# Encostado na parede OPOSTA a fachada. Encostar sempre na de cima
			# punha a geladeira em cima do vao da porta em toda casa de
			# fachada ao norte, e o quarto ficava sem entrada.
			var y := quarto.end.y - tamanho.y / 2.0 - 8.0
			if ao_sul:
				y = quarto.position.y + tamanho.y / 2.0 + 8.0

			# E na METADE da parede longe do vao: a divisoria interna abre a
			# passagem a 78% da largura, entao movel nenhum passa de 50%.
			var fracao := 0.15 + 0.35 * (float(j) + 1.0) / (float(tipos.size()) + 1.0)
			var com_documento := i == quarto_do_documento and j == 0
			_criar_movel(tipos[j], Vector2(quarto.position.x + quarto.size.x * fracao, y),
				com_documento)

## A navegacao do zumbi, montada da lista de obstaculos. Fica num no proprio,
## no grupo "navegacao", que e como o zumbi acha ela.
func _montar_navegacao() -> void:
	_navegacao = Navegacao.new()
	_navegacao.name = "Navegacao"
	_navegacao.add_to_group("navegacao")
	add_child(_navegacao)
	_navegacao.montar(Mapa.MUNDO, _obstaculos)

# --------------------------------------------------- povoamento por proximidade

## Os pontos onde ha zumbi declarado. Eles nao viram no ainda: quem esta longe
## do jogador nao existe.
func _preparar_povoamento() -> void:
	_pontos_de_zumbi.assign(Mapa.mundo()["zumbis"])
	# E os que os dias trouxeram, espalhados pelos mesmos pontos - a rua fica
	# mais cheia, e nao mais larga.
	var a_mais := (Travessia.dia - 1) / UM_ZUMBI_A_MAIS_A_CADA
	for i in a_mais:
		if _pontos_de_zumbi.is_empty():
			break
		var base: Vector2 = _pontos_de_zumbi[i % _pontos_de_zumbi.size()]
		_pontos_de_zumbi.append(base + Vector2(
			_sorteio.randf_range(-320.0, 320.0), _sorteio.randf_range(-320.0, 320.0)))

func _process(_delta: float) -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
		if _jogador == null:
			return
	if povoa_por_proximidade:
		_povoar_em_volta()
	_a_noite_traz_mais()

## Faz existir zumbi perto e deixa de fazer longe. E o que segura o custo num
## mapa deste tamanho: sao ~13 zumbis vivos, como sempre foram, so que agora
## eles sao os 13 que estao perto de voce.
func _povoar_em_volta() -> void:
	var onde := _jogador.global_position
	for i in _pontos_de_zumbi.size():
		var ponto: Vector2 = _pontos_de_zumbi[i]
		var distancia := onde.distance_to(ponto)
		var vivo: bool = _zumbis_vivos.has(i) and is_instance_valid(_zumbis_vivos[i])

		if distancia <= RAIO_VIVO and not vivo:
			_zumbis_vivos[i] = _criar_zumbi(ponto)
		elif distancia > RAIO_MORTO and vivo:
			(_zumbis_vivos[i] as Node).queue_free()
			_zumbis_vivos.erase(i)

## A noite trazendo mais zumbi. Aqui nao se sabe que horas sao - le-se o
## noite() do relogio, que vai de 0 a 1 entre as 19:00 e as 05:00.
##
## Eles nascem **num anel em volta do jogador**, e nao nas bordas do mapa: num
## mundo de 1,44 km a borda esta a quilometros, e zumbi que nasce longe nunca
## chega. O anel e maior que a tela, entao ninguem aparece do nada.
func _a_noite_traz_mais() -> void:
	if _relogio == null:
		return
	var devidos := int(floor(_relogio.noite() * float(ZUMBIS_DA_NOITE)))
	while _zumbis_da_noite < devidos:
		_zumbis_da_noite += 1
		_criar_zumbi(_um_lugar_livre_no_anel())

## Um ponto livre num anel em volta do jogador.
##
## Tenta varios: no anel cru, um em cada tres cai dentro de parede, de carro ou
## do rio - e zumbi preso dentro de parede nao pressiona ninguem, so gasta
## quadro. O anel e maior que a tela, entao ninguem aparece do nada.
func _um_lugar_livre_no_anel() -> Vector2:
	var espaco := get_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(30.0, 44.0)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collide_with_areas = false

	var ultimo := _jogador.global_position
	for _tentativa in 14:
		var angulo := _sorteio.randf_range(0.0, TAU)
		var raio := _sorteio.randf_range(1400.0, 2600.0)
		ultimo = (_jogador.global_position + Vector2.from_angle(angulo) * raio).clamp(
			Mapa.MUNDO.position + Vector2.ONE * 300.0,
			Mapa.MUNDO.end - Vector2.ONE * 300.0)
		consulta.transform = Transform2D(0.0, ultimo)
		if espaco.intersect_shape(consulta, 1).is_empty():
			return ultimo
	return ultimo

func _criar_zumbi(onde: Vector2) -> Node:
	var zumbi := CENA_DO_ZUMBI.instantiate()
	zumbi.position = onde
	add_child(zumbi)
	# Cada zumbi guarda a lista de corpos que a linha de visao dele ignora, e
	# ela tem os outros zumbis dentro. Chegou um novo, todas as listas estao
	# velhas - e um zumbi fora da lista corta a visao de quem esta atras dele,
	# que e justamente a horda parando de funcionar quando se junta.
	for outro in get_tree().get_nodes_in_group("zumbi"):
		if outro != zumbi:
			outro.esquecer_quem_ignorar()
	return zumbi

func _criar_movel(tipo: String, posicao: Vector2, com_documento := false) -> void:
	var ficha: Dictionary = Construcao.MOVEIS[tipo]
	var movel := CENA_DO_MOVEL.instantiate()
	# Antes do add_child: o _ready() do vasculhavel monta as formas de colisao
	# a partir do tamanho.
	movel.position = posicao
	movel.rotulo = ficha["rotulo"]
	movel.duracao = ficha["duracao"]
	movel.tamanho = ficha["tamanho"]
	movel.cor = ficha["cor"]
	movel.solido = tipo != "lata"

	# O sorteio roda para TODO movel, inclusive os que ja foram vasculhados: e
	# a mesma semente todo dia, e pular um sorteio embaralharia o conteudo dos
	# outros. O indice tambem sai daqui, e e o nome do movel entre os dias.
	movel.achados = _sortear_achados(tipo, com_documento)
	var indice := _moveis_gerados
	movel.nasce_vazio = Travessia.moveis_vazios.has(indice)
	if movel.nasce_vazio:
		_moveis_ja_vazios += 1

	add_child(movel)
	if _relogio != null:
		movel.vasculhando.connect(_relogio.ao_vasculhar)
	if _mochila != null:
		movel.vasculhado.connect(_mochila.ao_vasculhar)
	# O movel nao sabe que existe dia seguinte; quem anota e quem conhece o
	# indice. bind() pendura o indice no fim dos argumentos do sinal.
	movel.vasculhado.connect(_anotar_movel_vazio.bind(indice))

	# O corpo solido do movel nasce dentro do vasculhavel, entao nao passa pelo
	# _criar_corpo() - mas o zumbi tem que desviar dele igual.
	if movel.solido:
		_obstaculos.append(Rect2(posicao - ficha["tamanho"] / 2.0, ficha["tamanho"]))

func _anotar_movel_vazio(_rotulo: String, _achados: Array[String], indice: int) -> void:
	Travessia.moveis_vazios[indice] = true

## O que sai do movel. Cada tipo tem a sua tabela, e o documento entra so onde o
## mapa declarou que ha um.
func _sortear_achados(tipo: String, com_documento: bool) -> Array[String]:
	var achados: Array[String] = []
	var tabela: Array = Construcao.CONTEUDO[tipo]

	_moveis_gerados += 1
	if com_documento:
		# Qual documento, pela ordem em que os lugares aparecem no mapa: os seis
		# sao seis, e cada um sai uma vez so.
		var quais: Array = Construcao.DOCUMENTOS
		achados.append(quais[_documentos_colocados % quais.size()])
		_documentos_colocados += 1

	# Movel vazio existe de proposito: se todo movel desse algo, vasculhar
	# deixaria de ser aposta.
	for _vez in _sorteio.randi_range(0, 2):
		achados.append(tabela[_sorteio.randi_range(0, tabela.size() - 1)])
	return achados


## Arvores solidas, sorteadas **so dentro dos bosques** declarados no mapa.
##
## Antes eram sorteadas no mundo inteiro recusando o que caia em rua, calcada ou
## construcao - e mesmo assim uma tapou o beco entre duas casas e outra a porta
## do galpao, deixando meio mapa inalcancavel. Arvore solida em area de
## circulacao e armadilha silenciosa: o bosque e uma lista, nao um sorteio.
##
## O orcamento e fixo e se reparte pelos bosques por area, pelo mesmo motivo do
## mato: densidade constante num mapa 100x maior seria 100x os nos.
func _plantar_arvores() -> void:
	var bosques: Array = Mapa.mundo()["bosques"]
	if bosques.is_empty():
		return
	var peso_total := _peso_dos_bosques(bosques)
	if peso_total <= 0.0:
		return

	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260909
	for bosque in bosques:
		var r: Rect2 = bosque["rect"]
		var quantas := int(float(ARVORES) * (_peso_de(bosque) / peso_total))
		var plantadas := 0
		var tentativas := 0
		while plantadas < quantas and tentativas < quantas * 6 + 40:
			tentativas += 1
			var lado := sorteio.randf_range(62.0, 98.0)
			if r.size.x <= lado or r.size.y <= lado:
				break
			var posicao := Vector2(
				sorteio.randf_range(r.position.x, r.end.x - lado),
				sorteio.randf_range(r.position.y, r.end.y - lado)
			)
			var area := Rect2(posicao, Vector2(lado, lado))
			if not _e_terreno(area.grow(50.0)):
				continue
			_criar_corpo(area)
			var tronco := Polygon2D.new()
			tronco.color = COR_ARVORE
			tronco.polygon = PackedVector2Array([
				area.position, Vector2(area.end.x, area.position.y), area.end,
				Vector2(area.position.x, area.end.y)
			])
			add_child(tronco)
			plantadas += 1

## O peso de um bosque no orcamento: **area vezes densidade**, e nao area.
##
## Sem a densidade, uma mata de 200 milhoes de px² levava quase tudo e a
## florestinha - que tem 9 milhoes - recebia arvore de menos para se ver. O
## resultado era um mapa em que nenhuma mata parecia mata. Com o peso, a
## florestinha e fechada e as matas de borda sao campo com arvore espalhada,
## que e a diferenca que se queria.
func _peso_de(bosque: Dictionary) -> float:
	return (bosque["rect"] as Rect2).get_area() * float(bosque.get("densidade", 0.03))

func _peso_dos_bosques(bosques: Array) -> float:
	var total := 0.0
	for bosque in bosques:
		total += _peso_de(bosque)
	return total

## Se o retangulo esta em terreno livre - fora de rua, calcada, construcao,
## entrada de carro, piso de concreto e agua.
func _e_terreno(area: Rect2) -> bool:
	var mundo := Mapa.mundo()
	for rua in mundo["ruas"]:
		if (rua as Rect2).grow(Mapa.CALCADA).intersects(area):
			return false
	for piso in mundo["piso"]:
		if (piso as Rect2).intersects(area):
			return false
	for agua in mundo["agua"]:
		if (agua as Rect2).grow(60.0).intersects(area):
			return false
	for construcao in mundo["construcoes"]:
		if (construcao["rect"] as Rect2).grow(36.0).intersects(area):
			return false
		if Construcao.entrada_de_carro(construcao).intersects(area):
			return false
	for cerca in mundo["cercas"]:
		if (cerca as Rect2).intersects(area):
			return false
	# E nao em cima de onde nasce zumbi. Sem isto, arvore na mata fechada
	# enterrava o zumbi da florestinha - e zumbi dentro de arvore fica preso, o
	# que o conferir_zumbi pegou na primeira rodada com a mata densa.
	for onde in mundo["zumbis"]:
		if area.grow(30.0).has_point(onde):
			return false
	return true

# --------------------------------------------------------------------- colisao

func _criar_corpo(area: Rect2) -> void:
	_obstaculos.append(area)

	var forma := RectangleShape2D.new()
	forma.size = area.size

	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	colisao.position = area.get_center()

	var corpo := StaticBody2D.new()
	corpo.add_child(colisao)
	add_child(corpo)

## Muros invisiveis na borda, para nao dar de sair do mundo e ficar olhando o
## vazio.
func _criar_muros_do_mundo() -> void:
	var mundo := Mapa.MUNDO
	var e := ESPESSURA_DO_MURO
	_criar_corpo(Rect2(mundo.position.x - e, mundo.position.y - e, mundo.size.x + e * 2.0, e))
	_criar_corpo(Rect2(mundo.position.x - e, mundo.end.y, mundo.size.x + e * 2.0, e))
	_criar_corpo(Rect2(mundo.position.x - e, mundo.position.y, e, mundo.size.y))
	_criar_corpo(Rect2(mundo.end.x, mundo.position.y, e, mundo.size.y))

func _limitar_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	camera.limit_left = int(Mapa.MUNDO.position.x)
	camera.limit_top = int(Mapa.MUNDO.position.y)
	camera.limit_right = int(Mapa.MUNDO.end.x)
	camera.limit_bottom = int(Mapa.MUNDO.end.y)
