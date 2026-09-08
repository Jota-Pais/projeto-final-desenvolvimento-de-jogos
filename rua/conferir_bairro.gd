extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no layout do bairro.**
##
## Varre o mundo inteiro com o corpo do jogador numa grade, faz flood fill a
## partir de onde ele nasce e confere se da para chegar a pe em todo movel e em
## todo quarto de toda construcao.
##
## Existe porque essa classe de bug nao aparece lendo o codigo e nao aparece
## rodando o jogo por dois minutos. Na primeira vez que rodou, achou tres:
##
##  - movel encostado sempre na parede de cima, o que em casa de fachada ao
##    norte punha a geladeira em cima do vao da porta e trancava o quarto;
##  - arvore solida sorteada no mundo inteiro, tapando o beco entre duas casas;
##  - cerca de fundo a 40 px da porta do galpao - o jogador tem 40 de altura e
##    nao cabia na frente dela.
##
## Trinta e oito dos 41 moveis estavam inalcancaveis e ninguem tinha percebido.

const Bairro := preload("res://rua/bairro.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")

## Lado da celula da grade, em pixels. Menor = mais preciso e mais lento. Com
## 20 sao ~52 mil celulas no bairro ampliado, o que ja e fino para um corpo de
## 28 x 40.
const PASSO := 20.0
## O corpo do jogador, que e o que tem que caber. Ver rua/jogador.tscn.
const CORPO := Vector2(28.0, 40.0)

var _bairro: Node
var _quadros := 0
var _feito := false

func _ready() -> void:
	_bairro = CENA_DA_RUA.instantiate()
	add_child(_bairro)

func _process(_delta: float) -> void:
	# Espera a fisica assentar antes de consultar o espaco.
	_quadros += 1
	if _feito or _quadros < 4:
		return
	_feito = true
	var problemas := _conferir()
	print("\n%s" % ("SEM PROBLEMAS" if problemas == 0 else "%d PROBLEMA(S)" % problemas))
	if not Engine.is_editor_hint():
		get_tree().quit(0 if problemas == 0 else 1)

func _conferir() -> int:
	var jogador: Node2D = _bairro.get_node("Jogador")
	var espaco := get_viewport().find_world_2d().direct_space_state

	var forma := RectangleShape2D.new()
	forma.size = CORPO
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	# Sem isto, o corpo do proprio jogador conta como parede.
	consulta.exclude = [jogador.get_rid()]

	# 1. Onde cabe ficar de pe.
	var colunas := int(Bairro.MUNDO.size.x / PASSO)
	var linhas := int(Bairro.MUNDO.size.y / PASSO)
	var livre := {}
	for c in colunas:
		for l in linhas:
			consulta.transform = Transform2D(0.0, _centro(Vector2i(c, l)))
			if espaco.intersect_shape(consulta, 1).is_empty():
				livre[Vector2i(c, l)] = true

	# 2. Flood fill de onde o jogador nasce.
	var inicio := Vector2i(jogador.global_position / PASSO)
	if not livre.has(inicio):
		print("o jogador nasce sem lugar para ficar de pe, em %s" % jogador.global_position)
		return 1

	var alcancavel := {inicio: true}
	var fila: Array[Vector2i] = [inicio]
	while not fila.is_empty():
		var atual: Vector2i = fila.pop_back()
		for lado in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var vizinho: Vector2i = atual + lado
			if alcancavel.has(vizinho) or not livre.has(vizinho):
				continue
			alcancavel[vizinho] = true
			fila.append(vizinho)

	print("cabe ficar de pe em %d celulas de %d" % [livre.size(), colunas * linhas])
	print("da para chegar a pe em %d delas (%.0f%%)" % [
		alcancavel.size(), 100.0 * alcancavel.size() / float(livre.size())])

	var problemas := 0
	problemas += _conferir_moveis(alcancavel)
	problemas += _conferir_quartos(alcancavel)
	return problemas

## Todo movel tem onde ficar de pe dentro da zona de alcance dele?
func _conferir_moveis(alcancavel: Dictionary) -> int:
	var moveis: Array[Node2D] = []
	for filho in _bairro.get_node("Cenario").get_children():
		if filho is Area2D:
			moveis.append(filho)
	moveis.append(_bairro.get_node("EntradaDeCasa"))

	var ruins: Array[String] = []
	for movel in moveis:
		var tamanho := (movel.get_node("Deteccao").shape as RectangleShape2D).size
		var zona := Rect2(movel.position - tamanho / 2.0, tamanho)
		if not _tem_celula_em(alcancavel, zona):
			ruins.append("%s (%s) em %s" % [movel.name, movel.get("rotulo"), movel.position])

	print("\n%d moveis conferidos" % moveis.size())
	if ruins.is_empty():
		print("  todos alcancaveis a pe")
		return 0
	print("  INALCANCAVEIS (%d):" % ruins.size())
	for qual in ruins:
		print("    " + qual)
	return ruins.size()

## Todo quarto de toda construcao tem passagem?
func _conferir_quartos(alcancavel: Dictionary) -> int:
	var ruins: Array[String] = []
	for i in Bairro.CONSTRUCOES.size():
		var construcao: Dictionary = Bairro.CONSTRUCOES[i]
		var quartos := Bairro.quartos_de(construcao)
		for j in quartos.size():
			if not _tem_celula_em(alcancavel, quartos[j]):
				ruins.append("construcao %d (%s), quarto %d" % [i, construcao["tipo"], j])

	if ruins.is_empty():
		print("  todos os quartos de todas as construcoes tem passagem")
		return 0
	print("  QUARTOS SEM PASSAGEM (%d):" % ruins.size())
	for qual in ruins:
		print("    " + qual)
	return ruins.size()

func _tem_celula_em(alcancavel: Dictionary, area: Rect2) -> bool:
	var de := Vector2i((area.position / PASSO).floor())
	var ate := Vector2i((area.end / PASSO).ceil())
	for c in range(de.x, ate.x + 1):
		for l in range(de.y, ate.y + 1):
			var celula := Vector2i(c, l)
			if alcancavel.has(celula) and area.has_point(_centro(celula)):
				return true
	return false

func _centro(celula: Vector2i) -> Vector2:
	return Vector2(celula) * PASSO + Vector2.ONE * PASSO / 2.0
