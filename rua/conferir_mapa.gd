extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no mapa.**
##
## Varre o mundo com o corpo do jogador numa grade, faz flood fill e confere se
## o mapa e **um lugar so** - se da para chegar a pe, da sua casa, em todo lugar
## do mapa, e dentro de cada lugar em todo movel e todo quarto.
##
## Existe porque essa classe de bug nao aparece lendo o codigo e nao aparece
## rodando o jogo por dois minutos. Na primeira vez que rodou, no bairro
## pequeno, achou tres - e **38 dos 41 moveis estavam inalcancaveis** sem
## ninguem ter percebido:
##
##  - movel encostado sempre na parede de cima, o que em casa de fachada ao
##    norte punha a geladeira em cima do vao da porta e trancava o quarto;
##  - arvore solida sorteada no mundo inteiro, tapando o beco entre duas casas;
##  - cerca de fundo a 40 px da porta do galpao - o jogador tem 40 de altura e
##    nao cabia na frente dela.
##
## ## Duas grades, porque o mapa cresceu 100x (09/09/2026)
##
## Varrer 57.600 x 36.000 com celula de 20 px seriam **5,2 milhoes de consultas
## de fisica** - minutos de espera. Entao sao duas passadas:
##
##  - **grossa** (120 px) no mundo inteiro, para conferir que cada lugar se
##    alcanca a pe e medir quanto tempo de caminhada custa chegar nele;
##  - **fina** (24 px) dentro de cada lugar que tem predio, que e onde vao de
##    porta e beco de 90 px precisam de precisao.
##
## A grossa nao serve para vao de porta e a fina nao serve para o mundo. Juntas
## dao ~380 mil consultas, que e o preco de rodar isto: uns 15 segundos.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")

## Celula da passada grossa: 3 metros. Serve para "da para ir de la ate ca",
## nao para vao de porta.
const PASSO_GROSSO := 120.0
## Celula da passada fina: 24 px, com o corpo do jogador tendo 28 x 40.
const PASSO_FINO := 24.0
## O corpo do jogador, que e o que tem que caber. Ver rua/jogador.tscn.
const CORPO := Vector2(28.0, 40.0)

## Velocidade de caminhada, para traduzir distancia em segundos de dia. Tem que
## bater com a VELOCIDADE do rua/jogador.gd.
const VELOCIDADE := 280.0

## Folga em volta do lugar na passada fina, para a via de acesso e a calcada
## entrarem na conta - senao o lugar seria conferido como se fosse ilha.
const FOLGA_DO_LUGAR := 500.0

var _rua: Node
var _jogador: Node2D
var _espaco: PhysicsDirectSpaceState2D
var _consulta: PhysicsShapeQueryParameters2D

var _quadros := 0
var _feito := false
var _falhas := 0

func _ready() -> void:
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)

func _process(_delta: float) -> void:
	# Espera a fisica assentar antes de consultar o espaco.
	_quadros += 1
	if _feito or _quadros < 4:
		return
	_feito = true

	_jogador = _rua.get_node("Jogador")
	_espaco = get_viewport().find_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = CORPO
	_consulta = PhysicsShapeQueryParameters2D.new()
	_consulta.shape = forma
	_consulta.collide_with_bodies = true
	_consulta.collide_with_areas = false
	# Sem isto, o corpo do proprio jogador conta como parede.
	_consulta.exclude = [_jogador.get_rid()]

	_o_mapa_e_um_lugar_so()
	_dentro_de_cada_lugar()
	_os_documentos()

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	if not Engine.is_editor_hint():
		get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _cabe(onde: Vector2) -> bool:
	_consulta.transform = Transform2D(0.0, onde)
	return _espaco.intersect_shape(_consulta, 1).is_empty()

## Onde cabe ficar de pe dentro de uma area, numa grade de lado `passo`.
func _onde_cabe(area: Rect2, passo: float) -> Dictionary:
	var livre := {}
	var de := Vector2i((area.position / passo).floor())
	var ate := Vector2i((area.end / passo).ceil())
	for c in range(de.x, ate.x):
		for l in range(de.y, ate.y):
			var celula := Vector2i(c, l)
			if _cabe(_centro(celula, passo)):
				livre[celula] = true
	return livre

## Flood fill de quatro vizinhos a partir de uma celula.
func _espalhar(livre: Dictionary, inicio: Vector2i) -> Dictionary:
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
	return alcancavel

func _centro(celula: Vector2i, passo: float) -> Vector2:
	return Vector2(celula) * passo + Vector2.ONE * passo / 2.0

func _tem_celula_em(alcancavel: Dictionary, area: Rect2, passo: float) -> bool:
	var de := Vector2i((area.position / passo).floor())
	var ate := Vector2i((area.end / passo).ceil())
	for c in range(de.x, ate.x + 1):
		for l in range(de.y, ate.y + 1):
			var celula := Vector2i(c, l)
			if alcancavel.has(celula) and area.has_point(_centro(celula, passo)):
				return true
	return false

# --- 1. o mapa e um lugar so ------------------------------------------------

## A conferencia que so passou a existir com o mapa grande. Antes o mundo era
## uma quadra e "da para chegar" era obvio; agora ha rio, ponte, muro e mata no
## caminho, e **um lugar inalcancavel nao da erro nenhum** - ele simplesmente
## nunca e visitado, e o documento que mora nele nunca entra na conta da cura.
func _o_mapa_e_um_lugar_so() -> void:
	print("\n1. o mapa e um lugar so")
	var livre := _onde_cabe(Mapa.MUNDO, PASSO_GROSSO)
	var inicio := Vector2i((_jogador.global_position / PASSO_GROSSO).floor())
	if not livre.has(inicio):
		_erro("o jogador nasce sem lugar para ficar de pe, em %s" % _jogador.global_position)
		return

	var alcancavel := _espalhar(livre, inicio)
	print("  o mundo tem %.0f m² (%.2f km²); cabe ficar de pe em %d celulas de 3 m," % [
		Mapa.MUNDO.get_area() / 1600.0, Mapa.MUNDO.get_area() / 1600000000.0, livre.size()])
	print("  e da para chegar a pe em %d delas (%.0f%%)" % [
		alcancavel.size(), 100.0 * alcancavel.size() / float(livre.size())])

	for lugar in Mapa.LUGARES:
		var r: Rect2 = lugar["rect"]
		var alvo := r.get_center()
		var longe := _jogador.global_position.distance_to(alvo)
		if not _tem_celula_em(alcancavel, r, PASSO_GROSSO):
			_erro("nao da para chegar a pe em %s" % lugar["nome"])
			continue
		print("  %-16s a %5.0f m da sua casa, %3.0f s de caminhada" % [
			lugar["nome"], longe / 40.0, longe / VELOCIDADE])

	# A conferencia da ponte: o rio tem que barrar e a ponte tem que passar.
	var no_rio := Mapa.RIO.get_center() + Vector2(0.0, 6000.0)
	if _cabe(no_rio):
		_erro("da para ficar de pe dentro do rio, em %s" % no_rio)
	var na_ponte := Mapa.PONTE.get_center()
	if not _tem_celula_em(alcancavel, Mapa.PONTE, PASSO_GROSSO):
		_erro("a ponte nao e alcancavel - o mapa esta partido em dois")
	else:
		print("  a ponte em %s e o unico atravessadouro, e passa" % na_ponte)

# --- 2. dentro de cada lugar ------------------------------------------------

## A passada fina, so onde ha predio. E aqui que aparece vao de porta tapado,
## quarto sem passagem e movel encostado no lugar errado.
func _dentro_de_cada_lugar() -> void:
	print("\n2. dentro de cada lugar")
	var moveis := _moveis_por_lugar()
	var construcoes: Array = Mapa.mundo()["construcoes"]

	for lugar in Mapa.LUGARES:
		if lugar["tipo"] == "floresta":
			continue
		var r: Rect2 = (lugar["rect"] as Rect2).grow(FOLGA_DO_LUGAR)
		var livre := _onde_cabe(r, PASSO_FINO)

		# Comeca da rodovia, que e por onde se chega em tudo neste mapa.
		var na_estrada := Vector2(clampf(r.get_center().x,
			Mapa.RODOVIA.position.x, Mapa.RODOVIA.end.x), Mapa.RODOVIA.get_center().y)
		var inicio := Vector2i((na_estrada / PASSO_FINO).floor())
		if not livre.has(inicio):
			# Lugar longe da rodovia: comeca do proprio centro dele.
			inicio = Vector2i((r.get_center() / PASSO_FINO).floor())
			if not livre.has(inicio):
				_erro("%s: nao achei de onde comecar" % lugar["nome"])
				continue
		var alcancavel := _espalhar(livre, inicio)

		var ruins := 0
		var quantos := 0
		for movel in moveis.get(lugar["nome"], []):
			quantos += 1
			var tamanho := ((movel as Node2D).get_node("Deteccao").shape as RectangleShape2D).size
			var zona := Rect2((movel as Node2D).position - tamanho / 2.0, tamanho)
			if not _tem_celula_em(alcancavel, zona, PASSO_FINO):
				_erro("%s: %s em %s e inalcancavel" % [
					lugar["nome"], (movel as Node2D).get("rotulo"), (movel as Node2D).position])
				ruins += 1

		var quartos_ruins := 0
		for construcao in construcoes:
			if not (lugar["rect"] as Rect2).intersects(construcao["rect"]):
				continue
			var quartos := Construcao.quartos_de(construcao)
			for j in quartos.size():
				if not _tem_celula_em(alcancavel, quartos[j], PASSO_FINO):
					_erro("%s: quarto %d da %s sem passagem" % [
						lugar["nome"], j, construcao["tipo"]])
					quartos_ruins += 1

		if ruins == 0 and quartos_ruins == 0:
			print("  %-16s %2d moveis e todos os quartos, tudo alcancavel"
				% [lugar["nome"], quantos])

## Cada movel gerado, agrupado pelo lugar em que caiu.
func _moveis_por_lugar() -> Dictionary:
	var por_lugar := {}
	for filho in _rua.get_node("Cenario").get_children():
		if not (filho is Area2D and "rotulo" in filho):
			continue
		var nome := Mapa.lugar_em((filho as Node2D).position)
		if not por_lugar.has(nome):
			por_lugar[nome] = []
		(por_lugar[nome] as Array).append(filho)
	# A porta do porao nao e movel gerado, mas tem que ser alcancavel igual.
	var porta := _rua.get_node("EntradaDeCasa") as Node2D
	var onde := Mapa.lugar_em(porta.position)
	if not por_lugar.has(onde):
		por_lugar[onde] = []
	(por_lugar[onde] as Array).append(porta)
	return por_lugar

# --- 3. um documento por lugar ----------------------------------------------

## Os seis documentos que existem tem que estar em seis lugares diferentes, e
## cada um sair uma vez so. Documento repetido como moeda de progressao nao quer
## dizer nada, e documento num lugar inalcancavel trava a partida.
func _os_documentos() -> void:
	print("\n3. os documentos")
	var onde_estao := {}
	var repetidos := 0
	for filho in _rua.get_node("Cenario").get_children():
		if not (filho is Area2D and "achados" in filho):
			continue
		for achado in (filho as Node2D).get("achados"):
			if not Construcao.e_documento(achado):
				continue
			if onde_estao.has(achado):
				repetidos += 1
			onde_estao[achado] = Mapa.lugar_em((filho as Node2D).position)

	if repetidos > 0:
		_erro("%d documento(s) apareceram mais de uma vez no mapa" % repetidos)
	if onde_estao.size() != Construcao.DOCUMENTOS.size():
		_erro("o mapa tem %d dos %d documentos" % [
			onde_estao.size(), Construcao.DOCUMENTOS.size()])

	var no_bairro := 0
	for achado in onde_estao:
		print("  %-22s em %s" % [achado.replace("documento: ", ""), onde_estao[achado]])
		if onde_estao[achado] == "bairro":
			no_bairro += 1

	# **A conferencia que justifica o mapa grande.** Se o bairro sozinho fechasse
	# a cura, todo o resto - o posto, a delegacia, o mercado, a ponte, a mansao -
	# seria cenario bonito sem funcao mecanica nenhuma, e ninguem sairia de casa.
	var fora := onde_estao.size() - no_bairro
	print("  %d no bairro e %d fora dele; a cura pede %d" % [
		no_bairro, fora, Travessia.DOCUMENTOS_PARA_A_CURA])
	if no_bairro >= Travessia.DOCUMENTOS_PARA_A_CURA:
		_erro("o bairro sozinho fecha a cura - o resto do mapa nao serve para nada")
	else:
		print("  o bairro sozinho nao fecha a cura: falta ir a %d lugar(es)"
			% (Travessia.DOCUMENTOS_PARA_A_CURA - no_bairro))
