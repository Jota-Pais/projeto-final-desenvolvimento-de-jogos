extends Node2D
## Greybox do bairro: desenha o chao no _draw() e gera no _ready() a colisao e
## os moveis, tudo a partir do rua/bairro.gd. Retangulo de cor chapada, sem
## imagem nenhuma e sem nada de binario para versionar.
##
## O layout NAO esta aqui - esta no bairro.gd, que e o unico arquivo a mexer
## para mudar o mapa. Aqui so mora a regra de como aquilo virou pixel e corpo
## solido.
##
## Descartavel de proposito: existe para a mecanica de vasculhar ter onde ser
## testada. O TileSet e o level design de verdade entram quando o layout parar
## de mudar.

const Bairro := preload("res://rua/bairro.gd")
const CENA_DO_MOVEL := preload("res://rua/vasculhavel.tscn")

const ESPESSURA_DO_MURO := 400.0

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

var _sorteio := RandomNumberGenerator.new()
var _moveis_gerados := 0

func _ready() -> void:
	_sorteio.seed = 20260907

	for construcao in Bairro.CONSTRUCOES:
		for parede in Bairro.paredes_externas(construcao):
			_criar_corpo(parede)
		for parede in Bairro.paredes_internas(construcao):
			_criar_corpo(parede)
		_povoar(construcao)

	for cerca in Bairro.CERCAS:
		_criar_corpo(cerca)

	for movel in Bairro.MOVEIS_DE_RUA:
		_criar_movel(movel["tipo"], movel["pos"])

	_plantar_arvores()
	_criar_muros_do_mundo()
	# A camera do jogador so fica corrente depois que a cena inteira entra na
	# arvore, por isso o deferido.
	_limitar_camera.call_deferred()

# ------------------------------------------------------------------- desenho

func _draw() -> void:
	# A grama e o fundo de tudo: o que nao e rua, calcada nem construcao e
	# quintal e terreno.
	draw_rect(Bairro.MUNDO, COR_GRAMA)
	_desenhar_mato()

	for construcao in Bairro.CONSTRUCOES:
		draw_rect(Bairro.entrada_de_carro(construcao), COR_ENTRADA_DE_CARRO)

	for rua in [Bairro.RUA_PRINCIPAL, Bairro.RUA_TRANSVERSAL]:
		draw_rect(rua, COR_ASFALTO)
	_desenhar_sujeira()
	_desenhar_faixas()

	for calcada in Bairro.calcadas():
		draw_rect(calcada, COR_CALCADA)
		_desenhar_juntas(calcada)

	# O piso e as paredes ficam escondidos pelo telhado enquanto o jogador
	# estiver fora - ver rua/telhados.gd.
	for construcao in Bairro.CONSTRUCOES:
		var piso := COR_PISO_SEU if construcao.get("sua", false) else COR_PISO
		draw_rect(Bairro.interior_de(construcao), piso)
		for parede in Bairro.paredes_externas(construcao):
			draw_rect(parede, COR_PAREDE)
		for parede in Bairro.paredes_internas(construcao):
			draw_rect(parede, COR_PAREDE)

	for cerca in Bairro.CERCAS:
		draw_rect(cerca, COR_CERCA)

## Faixa central tracejada nas duas ruas. Nao e enfeite: num asfalto liso o
## jogador parece parado, porque quem se mexe na tela e o cenario.
func _desenhar_faixas() -> void:
	var principal := Bairro.RUA_PRINCIPAL
	var y := principal.get_center().y - 7.0
	var x := 60.0
	while x < principal.size.x:
		draw_rect(Rect2(x, y, 100.0, 14.0), COR_FAIXA)
		x += 180.0

	var transversal := Bairro.RUA_TRANSVERSAL
	var cx := transversal.get_center().x - 7.0
	var cy := 60.0
	while cy < transversal.size.y:
		# Sem tracejado por cima do cruzamento.
		if not principal.has_point(Vector2(cx, cy)):
			draw_rect(Rect2(cx, cy, 14.0, 100.0), COR_FAIXA)
		cy += 180.0

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
	for rua in [Bairro.RUA_PRINCIPAL, Bairro.RUA_TRANSVERSAL]:
		for _pedaco in 150:
			var lado := sorteio.randf_range(8.0, 30.0)
			var posicao := Vector2(
				sorteio.randf_range(rua.position.x, rua.end.x - lado),
				sorteio.randf_range(rua.position.y, rua.end.y - lado)
			)
			draw_rect(Rect2(posicao, Vector2(lado, lado * sorteio.randf_range(0.4, 1.0))), COR_SUJEIRA)

## Mato tomando o terreno - o High Concept pede que a rua va ficando mais
## apocaliptica com os dias, e este e o gancho barato para isso.
func _desenhar_mato() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260908
	for _tufo in 700:
		var lado := sorteio.randf_range(14.0, 46.0)
		var posicao := Vector2(
			sorteio.randf_range(0.0, Bairro.MUNDO.size.x - lado),
			sorteio.randf_range(0.0, Bairro.MUNDO.size.y - lado)
		)
		if not _e_terreno(Rect2(posicao, Vector2(lado, lado))):
			continue
		draw_rect(Rect2(posicao, Vector2(lado, lado * 0.55)), COR_MATO)

# -------------------------------------------------------------------- geracao

## Um movel por vaga de cada quarto, distribuidos pela parede do fundo do
## quarto. E o jeito do PZ: o loot esta dentro, em movel, e nao na calcada.
func _povoar(construcao: Dictionary) -> void:
	# A sua casa nao se vasculha - o que tem lá dentro e o porao.
	if construcao.get("sua", false):
		return

	var quartos := Bairro.quartos_de(construcao)
	var vagas: Array = Bairro.MOVEIS_POR_QUARTO[construcao["tipo"]]

	var ao_sul: bool = Bairro.e_da_frente_ao_sul(construcao)

	for i in quartos.size():
		if i >= vagas.size():
			break
		var quarto: Rect2 = quartos[i]
		var tipos: Array = vagas[i]
		for j in tipos.size():
			var tamanho: Vector2 = Bairro.MOVEIS[tipos[j]]["tamanho"]

			# Encostado na parede OPOSTA a fachada. Encostar sempre na de cima
			# punha a geladeira em cima do vao da porta em toda casa de
			# fachada ao norte, e o quarto ficava sem entrada.
			var y := quarto.end.y - tamanho.y / 2.0 - 8.0
			if ao_sul:
				y = quarto.position.y + tamanho.y / 2.0 + 8.0

			# E na METADE da parede longe do vao: a divisoria interna abre a
			# passagem a 78% da largura, entao movel nenhum passa de 50%.
			var fracao := 0.15 + 0.35 * (float(j) + 1.0) / (float(tipos.size()) + 1.0)
			_criar_movel(tipos[j], Vector2(quarto.position.x + quarto.size.x * fracao, y))

func _criar_movel(tipo: String, posicao: Vector2) -> void:
	var ficha: Dictionary = Bairro.MOVEIS[tipo]
	var movel := CENA_DO_MOVEL.instantiate()
	# Antes do add_child: o _ready() do vasculhavel monta as formas de colisao
	# a partir do tamanho.
	movel.position = posicao
	movel.rotulo = ficha["rotulo"]
	movel.duracao = ficha["duracao"]
	movel.tamanho = ficha["tamanho"]
	movel.cor = ficha["cor"]
	movel.solido = tipo != "lata"
	movel.achados = _sortear_achados(tipo)
	add_child(movel)

## O que sai do movel. Cada tipo tem a sua tabela, e de tantos em tantos
## moveis entra um documento - o item que destrava a historia dentro de casa.
func _sortear_achados(tipo: String) -> Array[String]:
	var achados: Array[String] = []
	var tabela: Array = Bairro.CONTEUDO[tipo]

	_moveis_gerados += 1
	if _moveis_gerados % Bairro.CADA_QUANTOS_MOVEIS_UM_DOCUMENTO == 0:
		var quais: Array = Bairro.DOCUMENTOS
		var indice := (_moveis_gerados / Bairro.CADA_QUANTOS_MOVEIS_UM_DOCUMENTO - 1) % quais.size()
		achados.append(quais[indice])

	# Movel vazio existe de proposito: se todo movel desse algo, vasculhar
	# deixaria de ser aposta.
	for _vez in _sorteio.randi_range(0, 2):
		achados.append(tabela[_sorteio.randi_range(0, tabela.size() - 1)])
	return achados

## Arvores solidas, sorteadas **so dentro dos bosques** declarados no bairro.
##
## Antes eram sorteadas no mundo inteiro recusando o que caia em rua, calcada
## ou construcao - e mesmo assim uma tapou o beco entre duas casas e outra a
## porta do galpao, deixando meio mapa inalcancavel. Arvore solida em area de
## circulacao e armadilha silenciosa: o bosque e uma lista, nao um sorteio.
func _plantar_arvores() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260909
	var plantadas := 0
	var tentativas := 0
	while plantadas < 95 and tentativas < 2000:
		tentativas += 1
		var bosque: Rect2 = Bairro.BOSQUES[sorteio.randi_range(0, Bairro.BOSQUES.size() - 1)]
		var lado := sorteio.randf_range(62.0, 98.0)
		if bosque.size.x <= lado or bosque.size.y <= lado:
			continue
		var posicao := Vector2(
			sorteio.randf_range(bosque.position.x, bosque.end.x - lado),
			sorteio.randf_range(bosque.position.y, bosque.end.y - lado)
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

## Se o retangulo esta em terreno livre - fora de rua, calcada, construcao e
## entrada de carro.
func _e_terreno(area: Rect2) -> bool:
	for rua in [Bairro.RUA_PRINCIPAL, Bairro.RUA_TRANSVERSAL]:
		if rua.intersects(area):
			return false
	for calcada in Bairro.calcadas():
		if calcada.intersects(area):
			return false
	for construcao in Bairro.CONSTRUCOES:
		if (construcao["rect"] as Rect2).grow(36.0).intersects(area):
			return false
		if Bairro.entrada_de_carro(construcao).intersects(area):
			return false
	for cerca in Bairro.CERCAS:
		if cerca.intersects(area):
			return false
	return true

# --------------------------------------------------------------------- colisao

func _criar_corpo(area: Rect2) -> void:
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
	var mundo := Bairro.MUNDO
	var e := ESPESSURA_DO_MURO
	_criar_corpo(Rect2(mundo.position.x - e, mundo.position.y - e, mundo.size.x + e * 2.0, e))
	_criar_corpo(Rect2(mundo.position.x - e, mundo.end.y, mundo.size.x + e * 2.0, e))
	_criar_corpo(Rect2(mundo.position.x - e, mundo.position.y, e, mundo.size.y))
	_criar_corpo(Rect2(mundo.end.x, mundo.position.y, e, mundo.size.y))

func _limitar_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	camera.limit_left = int(Bairro.MUNDO.position.x)
	camera.limit_top = int(Bairro.MUNDO.position.y)
	camera.limit_right = int(Bairro.MUNDO.end.x)
	camera.limit_bottom = int(Bairro.MUNDO.end.y)
