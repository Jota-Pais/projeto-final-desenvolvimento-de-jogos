extends Node2D
## Navegacao do bairro: uma grade A* montada a partir dos retangulos de
## obstaculo que o cenario acabou de gerar.
##
## O zumbi precisa disto para **achar o vao da porta e entrar atras de voce**.
## Sem caminho ele perseguiria em linha reta, encalharia na primeira parede, e
## o interior das casas seria abrigo seguro por acidente - o contrario do que a
## mecanica pede.
##
## ## Por que nao a malha de navegacao do Godot
##
## Foi a primeira tentativa e nao serviu: `bake_navigation_polygon()` sobre este
## bairro (umas 250 colisoes num mundo de 5760 x 3600) travou o processo - cinco
## minutos sem sair uma linha. Aqui os obstaculos ja sao retangulos conhecidos,
## num arquivo so, entao rasterizar direto numa `AStarGrid2D` e mais rapido,
## deterministico e da para depurar olhando.

## Lado da celula. Menor = caminho mais fino e grade mais caras de montar.
const CELULA := 32.0

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

## Chamado pelo cenario depois de gerar toda a colisao.
func montar(mundo: Rect2, obstaculos: Array[Rect2]) -> void:
	_regiao = Rect2i(Vector2i.ZERO, Vector2i((mundo.size / CELULA).ceil()))
	_grade.region = _regiao
	_grade.cell_size = Vector2.ONE * CELULA
	_grade.offset = Vector2.ONE * CELULA / 2.0
	# Sem cortar canto de parede na diagonal.
	_grade.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grade.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grade.update()

	for obstaculo in obstaculos:
		_bloquear(obstaculo)

## O caminho entre dois pontos do mundo, ja em coordenada de mundo. Vazio se
## nao houver caminho.
func caminho(de: Vector2, ate: Vector2) -> PackedVector2Array:
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
