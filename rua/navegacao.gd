extends Node2D
## Navegacao do zumbi: uma grade A* montada a partir dos retangulos de
## obstaculo que o cenario gerou.
##
## O zumbi precisa disto para **achar o vao da porta e entrar atras de voce**.
## Sem caminho ele perseguiria em linha reta, encalharia na primeira parede, e
## o interior das casas seria abrigo seguro por acidente - o contrario do que a
## mecanica pede.
##
## ## Por que a grade e uma JANELA e nao o mundo (09/09/2026)
##
## Com o mapa de 57.600 x 36.000, uma grade de 32 px sobre o mundo inteiro teria
## **2 milhoes de celulas**. Nao e lento, e inviavel: memoria e o `update()` da
## AStarGrid2D crescem com a area, e nada disso serve para nada - o zumbi ve a
## 520 px e o caminho mais longo que ele precisa e atravessar uma casa.
##
## Entao a grade cobre so uma janela em volta do jogador, e e remontada quando
## ele sai dela. Sao ~62 mil celulas em vez de 2 milhoes, e o custo passou a
## depender do alcance do zumbi e nao do tamanho do mapa.
##
## Quem esta fora da janela nao tem caminho - e nao precisa: fora dela nao
## existe zumbi (ver RAIO_VIVO no cenario).
##
## ## Por que nao a malha de navegacao do Godot
##
## Foi a primeira tentativa e nao serviu: `bake_navigation_polygon()` sobre o
## bairro antigo (umas 250 colisoes num mundo de 5.760 x 3.600) travou o
## processo - cinco minutos sem sair uma linha. Aqui os obstaculos ja sao
## retangulos conhecidos, entao rasterizar direto numa `AStarGrid2D` e mais
## rapido, deterministico e da para depurar olhando.

## Lado da celula. Menor = caminho mais fino e grade mais cara de montar.
const CELULA := 32.0

## Lado da janela coberta pela grade. 8.000 px sao 200 m, umas seis telas -
## folgado para qualquer perseguicao, e 250 x 250 celulas.
const JANELA := 8000.0

## Quanto o jogador pode se afastar do centro da janela antes de ela ser
## remontada. Um quarto da janela: remonta a cada ~7 s de caminhada, e sempre
## sobra meia janela de folga na direcao em que ele estava indo.
const FOLGA_ANTES_DE_REMONTAR := 2000.0

## Quanto o obstaculo cresce antes de virar celula bloqueada, para o caminho
## nao passar raspando na parede. E menor que a meia largura do zumbi de
## proposito: o resto quem resolve e o move_and_slide.
const MARGEM := 16.0

## Quantos aneis de celula procurar quando o ponto pedido cai em cima de
## obstaculo - acontece sempre que o jogador esta encostado numa parede.
const ANEIS_DE_BUSCA := 6

const FORA := Vector2i(-1, -1)

var _grade := AStarGrid2D.new()
var _regiao: Rect2i
var _mundo: Rect2
var _obstaculos: Array[Rect2] = []
## Onde a janela atual esta centrada. NAN enquanto nao houver janela.
var _centro := Vector2(NAN, NAN)
var _jogador: Node2D

## Chamado pelo cenario depois de gerar toda a colisao. Guarda os obstaculos e
## nao monta nada ainda: a janela so existe quando se sabe onde o jogador esta.
func montar(mundo: Rect2, obstaculos: Array[Rect2]) -> void:
	_mundo = mundo
	_obstaculos = obstaculos
	_grade.cell_size = Vector2.ONE * CELULA
	_grade.offset = Vector2.ONE * CELULA / 2.0
	# Sem cortar canto de parede na diagonal.
	_grade.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grade.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE

func _process(_delta: float) -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
		if _jogador == null:
			return
	var onde := _jogador.global_position
	if is_nan(_centro.x) or onde.distance_to(_centro) > FOLGA_ANTES_DE_REMONTAR:
		remontar_em(onde)

## Remonta a grade em volta de um ponto. Publico porque a ferramenta de
## conferencia precisa pedir uma janela num lugar escolhido, sem depender de
## onde o jogador esta.
func remontar_em(centro: Vector2) -> void:
	_centro = centro
	var janela := Rect2(centro - Vector2.ONE * JANELA / 2.0, Vector2.ONE * JANELA)
	# Presa ao mundo: janela para fora da borda so gastaria celula.
	janela = janela.intersection(_mundo)

	_regiao = Rect2i(
		Vector2i((janela.position / CELULA).floor()),
		Vector2i((janela.size / CELULA).ceil())
	)
	_grade.region = _regiao
	_grade.update()

	for obstaculo in _obstaculos:
		# So o que encosta na janela: o mapa tem milhares de retangulos e a
		# janela cobre alguns por cento deles.
		if obstaculo.grow(MARGEM).intersects(janela):
			_bloquear(obstaculo)

## Se um ponto esta dentro da janela montada.
func alcanca(ponto: Vector2) -> bool:
	if is_nan(_centro.x):
		return false
	return _regiao.has_point(Vector2i((ponto / CELULA).floor()))

## O caminho entre dois pontos do mundo, ja em coordenada de mundo. Vazio se
## nao houver caminho **ou se algum dos dois estiver fora da janela**.
func caminho(de: Vector2, ate: Vector2) -> PackedVector2Array:
	if not alcanca(de) or not alcanca(ate):
		return PackedVector2Array()
	var inicio := _celula_livre_perto(de)
	var fim := _celula_livre_perto(ate)
	if inicio == FORA or fim == FORA:
		return PackedVector2Array()
	return _grade.get_point_path(inicio, fim)

func _bloquear(obstaculo: Rect2) -> void:
	var crescido := obstaculo.grow(MARGEM)
	var de := Vector2i((crescido.position / CELULA).floor())
	var ate := Vector2i((crescido.end / CELULA).ceil())
	for x in range(maxi(de.x, _regiao.position.x), mini(ate.x + 1, _regiao.end.x)):
		for y in range(maxi(de.y, _regiao.position.y), mini(ate.y + 1, _regiao.end.y)):
			var celula := Vector2i(x, y)
			# Bloqueia pelo CENTRO da celula, e nao por interseccao: por
			# interseccao, um vao de porta com 60 px livres entre duas paredes
			# fecharia inteiro e o zumbi nunca entraria em casa.
			if crescido.has_point(centro_de(celula)):
				_grade.set_point_solid(celula, true)

func centro_de(celula: Vector2i) -> Vector2:
	return Vector2(celula) * CELULA + Vector2.ONE * CELULA / 2.0

## A celula do ponto, ou a livre mais proxima. O jogador encostado numa parede
## cai em celula bloqueada, porque o obstaculo foi crescido pela MARGEM.
func _celula_livre_perto(ponto: Vector2) -> Vector2i:
	var celula := Vector2i((ponto / CELULA).floor()).clamp(
		_regiao.position, _regiao.end - Vector2i.ONE)
	if not _grade.is_point_solid(celula):
		return celula

	for anel in range(1, ANEIS_DE_BUSCA + 1):
		for dx in range(-anel, anel + 1):
			for dy in range(-anel, anel + 1):
				# So a borda do anel; o interior ja foi visto.
				if absi(dx) != anel and absi(dy) != anel:
					continue
				var perto := celula + Vector2i(dx, dy)
				if not _regiao.has_point(perto):
					continue
				if not _grade.is_point_solid(perto):
					return perto
	return FORA
