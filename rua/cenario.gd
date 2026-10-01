extends Node2D
## Greybox do mundo: desenha o chao no _draw() e gera no _ready() a colisao e os
## moveis, tudo a partir do `rua/mapa.gd`. Poligono e retangulo de cor chapada,
## sem imagem nenhuma e sem nada de binario para versionar.
##
## O layout NAO esta aqui - esta no mapa.gd, que le o tracado do desenho
## (`rua/mapa_tracado.json`) e diz o que cada coisa e. Aqui mora so a regra de
## como aquilo virou pixel e corpo solido.
##
## ## O que o mapa tracado muda aqui (30/09/2026)
##
## O chao deixou de ser lista de retangulos (rua, calcada, estrada de terra,
## lavoura) e virou **poligono por classe** - grama, mata, pavimento, asfalto,
## milho, terra, agua - pintado do maior para o menor, para o furo de um (a
## praca dentro do pavimento, o patio dentro da prisao) sair por cima dele.
## Arvore nasce dentro do poligono de mata, nao de um retangulo. O resto -
## predio, parede, movel, zumbi por perto, navegacao - e o de sempre.
##
## Tres coisas que funcionavam no bairro pequeno nao escalam, e continuam
## resolvidas assim:
##
##  - **zumbi** nao existe no mapa inteiro, so num raio em volta do jogador;
##  - **arvore e mato** tem orcamento por area de bosque, nao por no;
##  - **navegacao** nao cobre o mundo. Ver navegacao.gd.
##
## Descartavel de proposito: existe para a mecanica de vasculhar ter onde ser
## testada. O TileSet e o level design de verdade entram quando o layout parar
## de mudar.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const CENA_DO_MOVEL := preload("res://rua/vasculhavel.tscn")
const CENA_DO_ZUMBI := preload("res://rua/zumbi.tscn")
const Navegacao := preload("res://rua/navegacao.gd")
## So para ler o TAMANHO dela na hora de registrar o obstaculo: a porta e irma
## do cenario na cena, e nao nasce aqui dentro como os outros corpos solidos.
const EntradaDeCasa := preload("res://rua/entrada_de_casa.gd")

const ESPESSURA_DO_MURO := 400.0

## A pilha do que o jogador largou no chao, pela tela da mochila.
##
## **E um vasculhavel como outro qualquer** - so que pequena, sem colisao e
## barata de abrir. E por isso que pegar de volta funciona sem inventar um
## segundo tipo de objeto: o mesmo E, a mesma barra, a mesma mochila do outro
## lado.
##
## Ela **nao entra na conta dos moveis gerados**: o indice do movel e o nome
## dele entre os dias e sai de uma semente fixa, e enfiar uma pilha no meio
## embaralharia o conteudo de todo o resto do mapa. Por isso ela tambem nao e
## anotada como vasculhada - e por isso ela **nao sobrevive ao dia**: a rua e
## montada de novo todo dia, e o que voce largou na calcada fica na calcada.
const ROTULO_DO_CHAO := "Coisas no chão"
const DURACAO_DO_CHAO := 0.8
const TAMANHO_DO_CHAO := Vector2(40.0, 40.0)
const COR_DO_CHAO := Color("6a6152")

## Ate onde uma coisa largada cai numa pilha que ja existe em vez de comecar
## outra. Sem isto, esvaziar a mochila deixaria doze quadradinhos empilhados no
## mesmo pixel.
const PERTO_DA_PILHA := 90.0

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
## 5.200 px sao 130 m, umas quatro telas - longe o bastante para nunca se ver um
## aparecer do nada, e perto o bastante para nao haver dezenas de zumbis
## processando raycast ao mesmo tempo. Era 7.000 no mapa de 1 km (30/09/2026):
## este tem metade do tamanho e os pontos de zumbi ficaram mais densos, e com
## 7.000 metade do mapa estaria sempre acordada.
##
## O preco: ir longe e voltar repovoa o lugar. Guardar zumbi por lugar entre as
## idas e vindas e o que o PZ faz de verdade, e nao vale o custo enquanto o mapa
## e greybox.
const RAIO_VIVO := 5200.0
## Com folga para descarregar, senao um zumbi na fronteira nasce e morre todo
## quadro.
const RAIO_MORTO := 7400.0

## Quanto da area de cada bosque fica coberto por copa de arvore. Arvore e
## solida: 0,22 deixa a mata fechada o bastante para nao se ver o outro lado,
## e aberta o bastante para dar para atravessar com paciencia.
const COBERTURA_DE_ARVORE := 0.22
## Lado da copa, em px. A media (80) e o que a conta de cobertura usa.
const COPA_MINIMA := 62.0
const COPA_MAXIMA := 98.0
## Orcamento de tufos de mato para o mapa inteiro, repartido pelos bosques por
## area. Mato e so desenho.
const TUFOS_DE_MATO := 5000

## Teto de nos da cena inteira: so um sino de alarme, nao trava nada. Se
## este numero disparar, e sinal de que algum gerador voltou a criar um no por
## peca em vez de agrupar.
const ORCAMENTO_DE_NOS := 2000

# Paleta fria e dessaturada, que e a direcao de arte da rua: concreto,
# ferrugem, verde-acinzentado, ceu lavado. As cores do desenho de origem sao
# vivas de proposito (e um mapa para ler); aqui cada classe recebe o tom da
# paleta do jogo.
const COR_GRAMA := Color("3b4438")
const COR_POR_CLASSE := {
	"gramado": Color("41503c"),
	"mata": Color("33412f"),
	"horta": Color("4c5b38"),
	"pavimento": Color("4d5154"),
	"asfalto": Color("34383b"),
	"milho": Color("5f5634"),
	"terra": Color("55503f"),
	# O rio e a unica coisa fria de verdade do mapa - todo o resto e concreto e
	# mato.
	"agua": Color("2b3a44"),
}
const COR_MATO := Color("44513f")
const COR_ARVORE := Color("323e2c")
const COR_PISO := Color("46403a")
const COR_PISO_SEU := Color("463a2e")
const COR_PAREDE := Color("6b6154")
const COR_CERCA := Color("5a5347")
const COR_OBSTACULO := Color("5a5347")

var _sorteio := RandomNumberGenerator.new()
var _moveis_gerados := 0

## A identidade de cada movel gerado hoje, na ORDEM em que nasceram.
##
## A chave e derivada de ONDE o movel esta (o predio dono, pela posicao dele,
## mais o quarto e a vaga) - estavel mesmo que outro predio nasca ou suma em
## outro lugar do mapa.
var _chaves_dos_moveis: PackedStringArray = []
var _indice_da_chave: Dictionary = {}

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
## E a partir desta lista que a navegacao do zumbi e montada.
var _obstaculos: Array[Rect2] = []

## Toda arvore plantada, so para o `_draw()` pintar - a colisao dela mora no
## StaticBody2D do proprio bosque, nao aqui.
var _arvores: Array[Rect2] = []

## Os pontos de povoamento que ainda nao tem zumbi na arvore, e os que tem.
var _pontos_de_zumbi: Array[Vector2] = []
var _zumbis_vivos := {}
## Os pontos cujo zumbi levou tiro hoje. Sem isto, o povoamento por
## proximidade faria nascer outro no mesmo lugar dois segundos depois e atirar
## nao serviria para nada. Zera com o dia, porque a cena da rua recarrega.
var _pontos_limpos := {}

var _navegacao: Node
var _jogador: Node2D

## A ferramenta de conferencia do zumbi desliga isto.
##
## Ela teleporta o jogador para montar cada cena de teste, e com o povoamento
## ligado os zumbis que ela esta medindo sao liberados no meio da medicao.
## Desligado, o que nasceu no _ready fica onde esta.
var povoa_por_proximidade := true

func _ready() -> void:
	_sorteio.seed = 20260907
	# Antes de criar movel: e o _criar_movel que pendura os sinais nele. Os
	# grupos vem declarados no rua.tscn, entao ja existem mesmo que o _ready
	# deles ainda nao tenha rodado.
	_relogio = get_tree().get_first_node_in_group("relogio")
	_mochila = get_tree().get_first_node_in_group("mochila")
	# A mochila avisa o que saiu dela; quem sabe onde a coisa cai e daqui.
	if _mochila != null:
		_mochila.largou.connect(_ao_largar)

	var mundo := Mapa.mundo()

	# Antes de qualquer coisa: o jogador e a porta de casa vao para onde o mapa
	# diz, e nao para onde o rua.tscn tinha escrito na mao. Tem que ser antes do
	# povoamento, que depende de onde o jogador esta.
	_por_no_lugar()

	# Um StaticBody2D por PREDIO, nao por parede - ate 9 paredes (5 externas
	# + 4 internas da casa de 3 quartos) todas no mesmo corpo, via shape_owner.
	for construcao in mundo["construcoes"]:
		var corpo_do_predio := StaticBody2D.new()
		for parede in Construcao.paredes_externas(construcao):
			_adicionar_forma(corpo_do_predio, parede)
		for parede in Construcao.paredes_internas(construcao):
			_adicionar_forma(corpo_do_predio, parede)
		add_child(corpo_do_predio)
		_povoar(construcao)

	# Mesma ideia para cerca, bloco solido e agua: um corpo so para cada lista
	# inteira - nenhum deles precisa ser distinguivel do vizinho, so solido.
	_corpo_de(mundo["cercas"])
	var blocos: Array[Rect2] = []
	for obstaculo in mundo["obstaculos"]:
		blocos.append(obstaculo["rect"])
	_corpo_de(blocos)
	_corpo_de(mundo["solidos"])

	for movel in mundo["moveis_de_rua"]:
		var chave := "rua/%s@%.0f,%.0f" % [movel["tipo"], (movel["pos"] as Vector2).x,
			(movel["pos"] as Vector2).y]
		_criar_movel(movel["tipo"], movel["pos"], chave, 0, movel.get("tamanho", Vector2.ZERO))

	_plantar_arvores()
	_criar_muros_do_mundo()
	# Depois de tudo: a navegacao le a lista de obstaculos que acabou de encher.
	_montar_navegacao()
	_preparar_povoamento()
	# Povoa ja aqui, e nao so no primeiro _process: as ferramentas de
	# conferencia leem a cena logo depois de montar, e um mapa sem zumbi nenhum
	# passaria por engano.
	_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
	if _jogador != null:
		_povoar_em_volta()
	# A camera do jogador so fica corrente depois que a cena inteira entra na
	# arvore, por isso o deferido.
	_limitar_camera.call_deferred()

	_conferir_orcamento_de_nos()

## Um corpo solido com uma forma por retangulo da lista. Lista vazia nao cria
## corpo nenhum.
func _corpo_de(retangulos: Array) -> void:
	if retangulos.is_empty():
		return
	var corpo := StaticBody2D.new()
	for r in retangulos:
		_adicionar_forma(corpo, r)
	add_child(corpo)

## So um alarme: imprime quantos nos o cenario criou GERANDO O MAPA e avisa se
## passar do teto. Nao trava nada.
func _conferir_orcamento_de_nos() -> void:
	var nos := _contar_nos(self)
	print("cenario: %d nos, %d obstaculos, %d arvores (teto de no %d)" % [
		nos, _obstaculos.size(), _arvores.size(), ORCAMENTO_DE_NOS])
	if nos > ORCAMENTO_DE_NOS:
		push_warning("cenario: %d nos passa do teto de %d" % [nos, ORCAMENTO_DE_NOS])

func _contar_nos(no: Node) -> int:
	var total := 1
	for filho in no.get_children():
		total += _contar_nos(filho)
	return total

## O jogador e a porta de casa, no lugar que o mapa diz. Sao irmaos do cenario
## na cena, e e o cenario que sabe ler o mapa.
func _por_no_lugar() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador != null:
		jogador.global_position = Mapa.onde_o_jogador_nasce()

	var porta := get_parent().get_node_or_null("EntradaDeCasa") as EntradaDeCasa
	if porta == null:
		return
	# Antes de posicionar: o tamanho do vao (deitado ou em pe) depende de para
	# que lado a fachada da sua casa olha.
	porta.orientar(Mapa.lado_da_porta_de_casa())
	porta.global_position = Mapa.onde_fica_a_porta_de_casa()
	# A porta e solida e nao nasce aqui dentro, entao nao passa pelo
	# _adicionar_forma() - mas o zumbi tem que desviar dela igual, senao a
	# navegacao acha que o vao da sua casa e passagem.
	_obstaculos.append(Rect2(
		porta.global_position - porta.TAMANHO / 2.0, porta.TAMANHO))

# ------------------------------------------------------------------- desenho

func _draw() -> void:
	var mundo := Mapa.mundo()

	# A grama e o fundo de tudo: o que nao e outra classe de chao e campo.
	draw_rect(Mapa.MUNDO, COR_GRAMA)

	# O chao, do maior poligono para o menor (o mapa ja entrega nessa ordem):
	# o furo de um e outro poligono menor, e sai por cima. Furo que nao e
	# poligono nenhum (a grama do fundo cercada de mata, como o camping) e
	# repintado de grama logo em seguida.
	for poligono in mundo["poligonos"]:
		var cor: Color = COR_POR_CLASSE.get(poligono["classe"], COR_GRAMA)
		_desenhar_poligono(poligono["pontos"], cor)
		for furo in poligono["furos"]:
			_desenhar_poligono(furo, COR_GRAMA)
	_desenhar_mato(mundo)

	# O lote de cada predio: a mancha inteira que ele era no desenho, por
	# baixo dos retangulos - o que sobrou do corte continua sendo patio dele.
	for lote in mundo["lotes"]:
		_desenhar_poligono(lote["pontos"], Mapa.CLASSE_DO_PREDIO[lote["classe"]]["lote"])

	for obstaculo in mundo["obstaculos"]:
		draw_rect(obstaculo["rect"], COR_OBSTACULO)

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

	# Por cima de tudo, como as arvores sempre estiveram.
	_desenhar_arvores()

## Um poligono de chao, concavo ou nao. O que nao triangula (poligono que se
## cruza - nao deveria sair do tracador) vira o retangulo que o envolve, com
## aviso, em vez de sumir em silencio.
func _desenhar_poligono(pontos: PackedVector2Array, cor: Color) -> void:
	if pontos.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pontos).is_empty():
		push_warning("cenario: poligono de %d pontos nao triangula, pintando o envelope" % pontos.size())
		var envelope := Rect2(pontos[0], Vector2.ZERO)
		for p in pontos:
			envelope = envelope.expand(p)
		draw_rect(envelope, cor)
		return
	draw_colored_polygon(pontos, cor)

func _desenhar_arvores() -> void:
	for area in _arvores:
		draw_rect(area, COR_ARVORE)

## Mato **dentro dos bosques**, e nao no mundo inteiro. O orcamento e fixo e se
## reparte pelos bosques por area: mata fechada, campo limpo.
func _desenhar_mato(mundo: Dictionary) -> void:
	var bosques: Array = mundo["bosques"]
	if bosques.is_empty():
		return
	var area_total := 0.0
	for bosque in bosques:
		area_total += bosque["area"]
	if area_total <= 0.0:
		return

	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260908
	# Cresce com o dia: mesma semente, mais tufos - entao o mato de ontem
	# continua onde estava e o de hoje aparece em volta.
	var orcamento := TUFOS_DE_MATO + (Travessia.dia - 1) * MATO_A_MAIS_POR_DIA

	for bosque in bosques:
		var r: Rect2 = bosque["rect"]
		var quantos := int(float(orcamento) * (bosque["area"] / area_total))
		var tentativas := 0
		var feitos := 0
		while feitos < quantos and tentativas < quantos * 4:
			tentativas += 1
			var lado := sorteio.randf_range(14.0, 46.0)
			var posicao := Vector2(
				sorteio.randf_range(r.position.x, r.end.x - lado),
				sorteio.randf_range(r.position.y, r.end.y - lado)
			)
			if not _dentro_do_bosque(bosque, posicao + Vector2(lado, lado * 0.55) / 2.0):
				continue
			draw_rect(Rect2(posicao, Vector2(lado, lado * 0.55)), COR_MATO)
			feitos += 1

## Se um ponto esta dentro do poligono do bosque e fora dos furos dele.
func _dentro_do_bosque(bosque: Dictionary, ponto: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(ponto, bosque["pontos"]):
		return false
	for furo in bosque["furos"]:
		if Geometry2D.is_point_in_polygon(ponto, furo):
			return false
	return true

# -------------------------------------------------------------------- geracao

## Um movel por vaga de cada quarto, distribuidos pela parede do fundo do
## quarto. E o jeito do PZ: o loot esta dentro, em movel, e nao na calcada.
func _povoar(construcao: Dictionary) -> void:
	# A sua casa nao se vasculha - o que tem la dentro e o porao.
	if construcao.get("sua", false):
		return

	var quartos := Construcao.quartos_de(construcao)
	var vagas: Array = Construcao.MOVEIS_POR_QUARTO[construcao["tipo"]]
	var chave_do_predio := _chave_da_construcao(construcao)

	# O documento e um NUMERO (1..6). Cai no **ultimo** quarto, que e o mais
	# fundo, para o que custa mais chegar pagar mais. **Posicao provisoria**:
	# onde documento fica nao foi decidido, e isto e so o lugar que existe para
	# ele nascer.
	var numero_do_documento: int = construcao.get("documento", 0)
	var quarto_do_documento := -1
	if numero_do_documento > 0:
		quarto_do_documento = mini(quartos.size(), vagas.size()) - 1

	for i in quartos.size():
		if i >= vagas.size():
			break
		var quarto: Rect2 = quartos[i]
		var tipos: Array = vagas[i]
		var posicoes := Construcao.posicoes_de_movel(construcao, quarto, tipos)
		for j in tipos.size():
			var documento := numero_do_documento if (i == quarto_do_documento and j == 0) else 0
			var chave := "%s#%d/%d" % [chave_do_predio, i, j]
			_criar_movel(tipos[j], posicoes[j], chave, documento,
				Construcao.tamanho_do_movel(construcao, tipos[j]))

## A chave estavel de uma construcao: tipo + a posicao dela, que nao muda a
## menos que a propria construcao se mova.
func _chave_da_construcao(construcao: Dictionary) -> String:
	var r: Rect2 = construcao["rect"]
	return "%s@%.0f,%.0f" % [construcao["tipo"], r.position.x, r.position.y]

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
	if _pontos_de_zumbi.is_empty() or a_mais <= 0:
		return
	# Perto de casa primeiro (30/09/2026): os pontos nascem na ordem dos
	# predios do tracado, e os primeiros da lista sao os predios grandes do
	# outro lado do mapa - a escalada existia no numero e nao na rua em volta
	# de voce, que e onde ela tem que apertar.
	var perto_de_casa := _pontos_de_zumbi.duplicate()
	var casa := Mapa.onde_o_jogador_nasce()
	perto_de_casa.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_to(casa) < b.distance_to(casa))
	for i in a_mais:
		var base: Vector2 = perto_de_casa[i % perto_de_casa.size()]
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
## mapa deste tamanho.
func _povoar_em_volta() -> void:
	var onde := _jogador.global_position
	for i in _pontos_de_zumbi.size():
		var ponto: Vector2 = _pontos_de_zumbi[i]
		var distancia := onde.distance_to(ponto)
		var vivo: bool = _zumbis_vivos.has(i) and is_instance_valid(_zumbis_vivos[i])

		if _pontos_limpos.has(i):
			continue
		if distancia <= RAIO_VIVO and not vivo:
			_zumbis_vivos[i] = _criar_zumbi(ponto, i)
		elif distancia > RAIO_MORTO and vivo:
			(_zumbis_vivos[i] as Node).queue_free()
			_zumbis_vivos.erase(i)

## A noite trazendo mais zumbi. Aqui nao se sabe que horas sao - le-se o
## noite() do relogio, que vai de 0 a 1 entre as 19:00 e as 05:00.
##
## Eles nascem **num anel em volta do jogador**, e nao nas bordas do mapa. O
## anel e maior que a tela, entao ninguem aparece do nada.
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
## de arvore - e zumbi preso dentro de parede nao pressiona ninguem, so gasta
## quadro.
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

## O indice e o ponto de povoamento de onde ele saiu, ou -1 para quem a noite
## trouxe. E o que permite anotar que aquele ponto foi limpo a tiro.
func _criar_zumbi(onde: Vector2, indice := -1) -> Node:
	var zumbi := CENA_DO_ZUMBI.instantiate()
	zumbi.position = onde
	add_child(zumbi)
	if indice >= 0:
		zumbi.morreu.connect(_anotar_ponto_limpo.bind(indice))
	# Cada zumbi guarda a lista de corpos que a linha de visao dele ignora, e
	# ela tem os outros zumbis dentro. Chegou um novo, todas as listas estao
	# velhas.
	for outro in get_tree().get_nodes_in_group("zumbi"):
		if outro != zumbi:
			outro.esquecer_quem_ignorar()
	return zumbi

## `chave` e a identidade estavel do movel - ela quem decide se ele nasce
## vazio hoje (`Travessia.moveis_vazios`). `documento` e 0 (nenhum) ou 1..6
## (qual dos seis placeholders).
##
## `tamanho_override` existe para o movel de dentro de uma casa de fachada
## leste/oeste, que nasce transposto, e para o veiculo da rua, que vem com o
## tamanho e a orientacao que o mapa deu. Deixado em zero, usa o tamanho da
## tabela direto.
func _criar_movel(tipo: String, posicao: Vector2, chave: String, documento := 0,
		tamanho_override := Vector2.ZERO) -> void:
	var ficha: Dictionary = Construcao.MOVEIS[tipo]
	var tamanho: Vector2 = tamanho_override if tamanho_override != Vector2.ZERO else ficha["tamanho"]
	var movel := CENA_DO_MOVEL.instantiate()
	# Antes do add_child: o _ready() do vasculhavel monta as formas de colisao
	# a partir do tamanho.
	movel.position = posicao
	movel.rotulo = ficha["rotulo"]
	movel.duracao = ficha["duracao"]
	movel.tamanho = tamanho
	movel.cor = ficha["cor"]
	movel.solido = tipo != "lata"

	# O sorteio roda para TODO movel, inclusive os que ja foram vasculhados: e
	# a mesma semente todo dia, e pular um sorteio embaralharia o conteudo dos
	# outros.
	movel.achados = _sortear_achados(documento)
	_indice_da_chave[chave] = _chaves_dos_moveis.size()
	_chaves_dos_moveis.append(chave)
	movel.nasce_vazio = Travessia.moveis_vazios.has(chave)
	if movel.nasce_vazio:
		_moveis_ja_vazios += 1

	add_child(movel)
	if _relogio != null:
		movel.vasculhando.connect(_relogio.ao_vasculhar)
	if _mochila != null:
		movel.vasculhado.connect(_mochila.ao_vasculhar)
	# O movel nao sabe que existe dia seguinte; quem anota e quem conhece a
	# chave. bind() pendura a chave no fim dos argumentos do sinal.
	movel.vasculhado.connect(_anotar_movel_vazio.bind(chave))

	# O corpo solido do movel nasce dentro do vasculhavel, entao nao passa pelo
	# _adicionar_forma() - mas o zumbi tem que desviar dele igual.
	if movel.solido:
		_obstaculos.append(Rect2(posicao - tamanho / 2.0, tamanho))

## A chave do movel de indice `i`, na ordem em que nasceu hoje - ou "" se `i`
## for invalido. `indice_do_movel` faz o caminho contrario.
func chave_do_movel(i: int) -> String:
	if i < 0 or i >= _chaves_dos_moveis.size():
		return ""
	return _chaves_dos_moveis[i]

func indice_do_movel(chave: String) -> int:
	return _indice_da_chave.get(chave, -1)

## Todas as chaves, na ordem de geracao - a impressao digital do mapa
## (`Mapa.IMPRESSAO_ESPERADA`) e um hash desta lista. Ver conferir_mapa.gd.
func chaves_dos_moveis() -> PackedStringArray:
	return _chaves_dos_moveis

## O jogador tirou uma coisa da mochila: ela cai no chao onde ele esta.
##
## **Largar nao destroi.** Cair no chao mantem a regra do mapa de pe - o mundo
## nao repoe, mas tambem nao engole o que ja saiu de um movel.
func _ao_largar(achado: String) -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
	if _jogador == null:
		return

	var onde := _jogador.global_position
	var pilha := _pilha_perto_de(onde)
	if pilha != null:
		pilha.receber(achado)
		return
	_criar_pilha(onde, achado)

func _pilha_perto_de(onde: Vector2) -> Node2D:
	for no in get_tree().get_nodes_in_group("largado"):
		var pilha := no as Node2D
		if pilha != null and pilha.global_position.distance_to(onde) <= PERTO_DA_PILHA:
			return pilha
	return null

func _criar_pilha(onde: Vector2, achado: String) -> void:
	var pilha := CENA_DO_MOVEL.instantiate()
	pilha.position = onde
	pilha.rotulo = ROTULO_DO_CHAO
	pilha.duracao = DURACAO_DO_CHAO
	pilha.tamanho = TAMANHO_DO_CHAO
	pilha.cor = COR_DO_CHAO
	pilha.solido = false
	pilha.achados = [achado] as Array[String]
	pilha.add_to_group("largado")

	add_child(pilha)
	if _relogio != null:
		pilha.vasculhando.connect(_relogio.ao_vasculhar)
	if _mochila != null:
		pilha.vasculhado.connect(_mochila.ao_vasculhar)

func _anotar_ponto_limpo(indice: int) -> void:
	_pontos_limpos[indice] = true
	_zumbis_vivos.erase(indice)

func _anotar_movel_vazio(_rotulo: String, _achados: Array[String], chave: String) -> void:
	Travessia.moveis_vazios[chave] = true

## O que sai do movel: o documento, onde o mapa declarou um, e **balas** -
## zero, uma ou duas caixinhas (30/09/2026: era loot sorteado de uma tabela por
## tipo de movel; o Joao tirou o loot generico do jogo). `documento` e 0
## (nenhum) ou o NUMERO (1..6) do placeholder.
##
## Movel vazio existe de proposito: se todo movel desse algo, vasculhar
## deixaria de ser aposta. A mesma semente todo dia, entao o mesmo movel rende
## o mesmo sempre.
func _sortear_achados(documento: int) -> Array[String]:
	var achados: Array[String] = []
	_moveis_gerados += 1
	if documento > 0:
		achados.append(Construcao.DOCUMENTOS[documento - 1])
	for _vez in _sorteio.randi_range(0, 2):
		achados.append(Construcao.MUNICAO)
	return achados


## Arvores solidas, sorteadas **so dentro dos poligonos de mata** do mapa.
##
## Arvore solida em area de circulacao e armadilha silenciosa: o bosque e o
## que o desenho pintou de mata, e so ele. Quantas sai da area de cada
## bosque e de COBERTURA_DE_ARVORE; um StaticBody2D por bosque, uma forma por
## arvore, e o desenho e `draw_rect` em `_desenhar_arvores`.
func _plantar_arvores() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260909
	var copa_media := (COPA_MINIMA + COPA_MAXIMA) / 2.0
	for bosque in Mapa.mundo()["bosques"]:
		var r: Rect2 = bosque["rect"]
		var quantas := int(bosque["area"] * COBERTURA_DE_ARVORE / (copa_media * copa_media))
		var plantadas := 0
		var tentativas := 0
		var corpo := StaticBody2D.new()
		while plantadas < quantas and tentativas < quantas * 8 + 40:
			tentativas += 1
			var lado := sorteio.randf_range(COPA_MINIMA, COPA_MAXIMA)
			if r.size.x <= lado or r.size.y <= lado:
				break
			var posicao := Vector2(
				sorteio.randf_range(r.position.x, r.end.x - lado),
				sorteio.randf_range(r.position.y, r.end.y - lado)
			)
			var area := Rect2(posicao, Vector2(lado, lado))
			if not _dentro_do_bosque(bosque, area.get_center()):
				continue
			if not _livre_para_arvore(area.grow(30.0)):
				continue
			_adicionar_forma(corpo, area)
			_arvores.append(area)
			plantadas += 1
		if plantadas > 0:
			add_child(corpo)
		else:
			corpo.free()

## Se o retangulo nao pisa em predio, bloco, agua, veiculo nem em ponto de
## nascimento de zumbi. Mata nao se sobrepoe a rua nem a pavimento por
## construcao (sao classes diferentes do desenho), entao isso nao se confere.
func _livre_para_arvore(area: Rect2) -> bool:
	var mundo := Mapa.mundo()
	for construcao in mundo["construcoes"]:
		if (construcao["rect"] as Rect2).grow(36.0).intersects(area):
			return false
	for obstaculo in mundo["obstaculos"]:
		if (obstaculo["rect"] as Rect2).grow(20.0).intersects(area):
			return false
	for solido in mundo["solidos"]:
		if (solido as Rect2).grow(40.0).intersects(area):
			return false
	for movel in mundo["moveis_de_rua"]:
		var r := Rect2((movel["pos"] as Vector2) - (movel["tamanho"] as Vector2) / 2.0, movel["tamanho"])
		if r.grow(30.0).intersects(area):
			return false
	# E nao em cima de onde nasce zumbi: zumbi dentro de arvore fica preso.
	for onde in mundo["zumbis"]:
		if area.grow(30.0).has_point(onde):
			return false
	return true

# --------------------------------------------------------------------- colisao

## Acrescenta UMA forma retangular a um corpo que **ja existe**, via
## shape_owner - sem CollisionShape2D filho, que seria outro no por forma.
## Registra o retangulo em `_obstaculos`, para a navegacao continuar vendo
## tudo sem saber que a colisao mudou de forma por baixo.
func _adicionar_forma(corpo: StaticBody2D, area: Rect2) -> void:
	_obstaculos.append(area)
	var forma := RectangleShape2D.new()
	forma.size = area.size
	var dono := corpo.create_shape_owner(corpo)
	corpo.shape_owner_add_shape(dono, forma)
	corpo.shape_owner_set_transform(dono, Transform2D(0.0, area.get_center()))

## Muros invisiveis na borda, para nao dar de sair do mundo e ficar olhando o
## vazio. Um corpo so, quatro formas.
func _criar_muros_do_mundo() -> void:
	var mundo := Mapa.MUNDO
	var e := ESPESSURA_DO_MURO
	var corpo := StaticBody2D.new()
	_adicionar_forma(corpo, Rect2(mundo.position.x - e, mundo.position.y - e, mundo.size.x + e * 2.0, e))
	_adicionar_forma(corpo, Rect2(mundo.position.x - e, mundo.end.y, mundo.size.x + e * 2.0, e))
	_adicionar_forma(corpo, Rect2(mundo.position.x - e, mundo.position.y, e, mundo.size.y))
	_adicionar_forma(corpo, Rect2(mundo.end.x, mundo.position.y, e, mundo.size.y))
	add_child(corpo)

func _limitar_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	camera.limit_left = int(Mapa.MUNDO.position.x)
	camera.limit_top = int(Mapa.MUNDO.position.y)
	camera.limit_right = int(Mapa.MUNDO.end.x)
	camera.limit_bottom = int(Mapa.MUNDO.end.y)
