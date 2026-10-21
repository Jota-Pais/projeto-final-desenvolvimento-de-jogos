extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no mapa: no desenho, no
## tracado ou nos ROTULOS.**
##
## Confere o dado do mapa (fase 0, sem fisica) e depois varre o mundo inteiro
## com o corpo do jogador numa grade, faz flood fill e confere se o mapa e
## **um lugar so** - se da para chegar a pe, da porta de casa, em todo lugar
## com nome, todo movel e todo quarto de todo predio.
##
## Existe porque essa classe de bug nao aparece lendo o codigo e nao aparece
## rodando o jogo por dois minutos. Na primeira vez que rodou, no bairro
## pequeno, **38 dos 41 moveis estavam inalcancaveis** sem ninguem ter
## percebido.
##
## ## Uma grade so, fina (30/09/2026)
##
## O mapa tracado do desenho tem 550 x 318 m: varrer tudo a 24 px (o corpo do
## jogador tinha 28 x 40) eram ~490 mil consultas de fisica, uns 20 s. O mapa de
## 1 km precisava de duas passadas (grossa no mundo, fina por lugar); este cabe
## numa so, e uma passada so nao tem o furo de "o lugar e alcancavel na grossa
## mas a porta dele nao e na fina".
##
## Desde 20/10/2026 o corpo tem metade (14 x 20) e a grade e de 16 px, ~1,1
## milhao de consultas. A 24 ela pulava a faixa onde o corpo novo cabe na
## frente de um movel encostado na parede (20 px, com o ALCANCE de 30), e o
## movel saia inalcancavel sem ser.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const Jogador := preload("res://rua/jogador.gd")

## Celula da grade: 16 px, menor que a faixa de alcance de um movel (ver acima)
## e com os corpos de duas celulas vizinhas a 2 px um do outro - barreira
## mais grossa que isso nao passa despercebida entre elas.
const PASSO := 16.0
## O corpo do jogador, que e o que tem que caber. Ver rua/jogador.tscn.
const CORPO := Vector2(14.0, 20.0)

## Velocidade de caminhada, para traduzir distancia em segundos de dia - lida
## do jogador: a copia a mao ficou para tras quando ele passou a andar na
## metade (20/10/2026).
const VELOCIDADE := Jogador.VELOCIDADE

## O menor predio em que o vao da porta (100 px, a 35% da fachada) e um movel
## cabem: frente de 200 px; fundo de 170 - paredes (40) mais o movel mais fundo
## encostado no fundo (geladeira, 54 + 8) mais o corpo (40) com folga de grade
## (24).
const FRENTE_MINIMA := 200.0
const FUNDO_MINIMO := 170.0

var _rua: Node
var _jogador: Node2D
var _espaco: PhysicsDirectSpaceState2D
var _consulta: PhysicsShapeQueryParameters2D

var _quadros := 0
var _feito := false
var _falhas := 0

func _ready() -> void:
	# A fase 0 le so o dicionario (Mapa.mundo()), antes de qualquer coisa
	# instanciar - custa milissegundos.
	_o_dado_fecha()

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

	_da_para_chegar_em_tudo()
	_os_documentos()
	_a_identidade_bate()

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	if not Engine.is_editor_hint():
		get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

# --- 0. o dado do mapa -------------------------------------------------------
#
# Le so `Mapa.mundo()` - nenhuma fisica, nenhuma cena. Doutrina da borda:
# sobreposicao se testa com `grow(-1)` (dois retangulos so encostando na borda
# um do outro NAO sao sobreposicao), porque `Rect2.intersects()` do Godot conta
# a borda como colisao.

func _o_dado_fecha() -> void:
	print("0. o dado do mapa")
	var antes := _falhas
	var mundo := Mapa.mundo()
	var construcoes: Array = mundo["construcoes"]

	_todo_tipo_existe(construcoes)
	_predio_cabe_no_mundo_e_em_si(construcoes)
	_predio_nao_cruza_predio(construcoes)
	_a_porta_da_em_chao(mundo)
	_uma_casa_e_seis_documentos(construcoes)
	_todo_rotulo_nomeou_algo(construcoes)

	print("  %d construcoes (%d com nome), %d lugares, %d veiculos, %d blocos solidos, %d pontos de zumbi, %d poligonos de chao" % [
		construcoes.size(), _quantos_com_nome(construcoes), Mapa.lugares().size(),
		(mundo["moveis_de_rua"] as Array).size(), (mundo["obstaculos"] as Array).size(),
		(mundo["zumbis"] as Array).size(), (mundo["poligonos"] as Array).size()])
	print("  %d achado(s) nesta fase" % (_falhas - antes))

func _quantos_com_nome(construcoes: Array) -> int:
	var n := 0
	for c in construcoes:
		if c.get("nome", "") != "":
			n += 1
	return n

## Todo tipo de predio tem quarto e movel declarados em construcao.gd - um
## tipo novo em ROTULOS sem tabela estouraria so na hora de gerar o movel.
func _todo_tipo_existe(construcoes: Array) -> void:
	for c in construcoes:
		var tipo: String = c["tipo"]
		if not Construcao.QUARTOS_POR_TIPO.has(tipo) or not Construcao.MOVEIS_POR_QUARTO.has(tipo):
			_erro("'%s' tem tipo '%s', que nao existe em Construcao.QUARTOS_POR_TIPO/MOVEIS_POR_QUARTO"
				% [_nome_de(c), tipo])

func _nome_de(c: Dictionary) -> String:
	var nome: String = c.get("nome", "")
	return nome if nome != "" else "%s em %s" % [c["tipo"], c["rect"]]

## Dentro do MUNDO, e grande o bastante para ter vao de porta e movel.
func _predio_cabe_no_mundo_e_em_si(construcoes: Array) -> void:
	for c in construcoes:
		var r: Rect2 = c["rect"]
		if not Mapa.MUNDO.encloses(r):
			_erro("%s sai dos limites do MUNDO" % _nome_de(c))
		var frente := Construcao.frente_de(c)
		var fundo := Construcao.profundidade_de(c)
		if frente < FRENTE_MINIMA or fundo < FUNDO_MINIMO:
			_erro("%s e pequeno demais (%.0f de frente x %.0f de fundo; minimo %.0f x %.0f)"
				% [_nome_de(c), frente, fundo, FRENTE_MINIMA, FUNDO_MINIMO])
		if Construcao.QUARTOS_POR_TIPO[c["tipo"]] >= 3 and (frente < Mapa.FRENTE_MINIMA_PARA_TRES_QUARTOS
				or fundo < Mapa.FUNDO_MINIMO_PARA_TRES_QUARTOS):
			_erro("%s tem tres quartos num predio de %.0f x %.0f - nao cabe" % [_nome_de(c), frente, fundo])

## Sobreposicao de verdade: os dois cresceram -1, para dois retangulos so se
## tocando na borda nao contarem.
func _sobrepoe(a: Rect2, b: Rect2) -> bool:
	return a.grow(-1.0).intersects(b.grow(-1.0))

func _predio_nao_cruza_predio(construcoes: Array) -> void:
	for i in construcoes.size():
		for j in range(i + 1, construcoes.size()):
			var a: Rect2 = construcoes[i]["rect"]
			var b: Rect2 = construcoes[j]["rect"]
			if _sobrepoe(a, b):
				_erro("%s se sobrepoe a %s" % [_nome_de(construcoes[i]), _nome_de(construcoes[j])])

## A porta de todo predio abre para chao livre: o ponto a 70 px para fora do
## vao nao esta dentro de outro predio, de bloco solido, de agua nem de
## veiculo. (Se da para CHEGAR nela, e a passada fisica abaixo que prova.)
func _a_porta_da_em_chao(mundo: Dictionary) -> void:
	var construcoes: Array = mundo["construcoes"]
	for c in construcoes:
		var fora := Construcao.porta_de(c) + Construcao.normal_de(c) * 70.0
		var corpo := Rect2(fora - CORPO / 2.0, CORPO)
		if not Mapa.MUNDO.encloses(corpo):
			_erro("a porta de %s abre para fora do MUNDO" % _nome_de(c))
			continue
		for outra in construcoes:
			if outra != c and (outra["rect"] as Rect2).intersects(corpo):
				_erro("a porta de %s abre para dentro de %s" % [_nome_de(c), _nome_de(outra)])
		for obstaculo in mundo["obstaculos"]:
			if (obstaculo["rect"] as Rect2).intersects(corpo):
				_erro("a porta de %s abre para dentro de um bloco solido" % _nome_de(c))
		for solido in mundo["solidos"]:
			if (solido as Rect2).intersects(corpo):
				_erro("a porta de %s abre para dentro da agua" % _nome_de(c))
		for movel in mundo["moveis_de_rua"]:
			var r := Rect2((movel["pos"] as Vector2) - (movel["tamanho"] as Vector2) / 2.0, movel["tamanho"])
			if r.intersects(corpo):
				_erro("a porta de %s abre para dentro de um %s" % [_nome_de(c), movel["tipo"]])

## Uma sua casa so, e os seis documentos cada um uma vez.
func _uma_casa_e_seis_documentos(construcoes: Array) -> void:
	var suas := 0
	var documentos := {}
	for c in construcoes:
		if c.get("sua", false):
			suas += 1
		var d: int = c.get("documento", 0)
		if d > 0:
			if documentos.has(d):
				_erro("o documento %d esta declarado em %s e em %s" % [d, documentos[d], _nome_de(c)])
			documentos[d] = _nome_de(c)
	if suas != 1:
		_erro("%d construcoes marcadas como a sua casa; tem que ser exatamente 1" % suas)
	for d in range(1, Construcao.DOCUMENTOS.size() + 1):
		if not documentos.has(d):
			_erro("o documento %d nao esta declarado em predio nenhum" % d)

## Todo rotulo de ROTULOS virou um predio com nome ou um lugar - rotulo cujo
## ponto caiu fora da mancha dele some em silencio, e e isso que se pega aqui.
func _todo_rotulo_nomeou_algo(construcoes: Array) -> void:
	for rotulo in Mapa.ROTULOS:
		var nome: String = rotulo["nome"]
		if Mapa.lugar(nome).is_empty():
			_erro("o rotulo '%s' nao virou lugar nenhum" % nome)
		if rotulo["tipo"] == "zona":
			continue
		var achou := false
		for c in construcoes:
			if c.get("nome", "") == nome:
				achou = true
				break
		if not achou:
			_erro("o rotulo '%s' nao caiu em predio nenhum (ponto %s do PNG)" % [nome, rotulo.get("ponto", "?")])
			for c in construcoes:
				if (c["rect"] as Rect2).has_point(Mapa.ponto_do_png(rotulo.get("ponto", Vector2.ZERO))):
					print("    (o ponto cai em '%s', tipo %s, lote %d, anexo %s)" % [
						c.get("nome", ""), c["tipo"], c["lote"], c["anexo"]])

# --- 1. da para chegar a pe em tudo -----------------------------------------

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

## A conferencia que justifica a ferramenta. **Um lugar inalcancavel nao da
## erro nenhum** - ele simplesmente nunca e visitado, e o documento que mora
## nele nunca entra na conta da cura.
func _da_para_chegar_em_tudo() -> void:
	print("\n1. da para chegar a pe em tudo")
	var livre := _onde_cabe(Mapa.MUNDO, PASSO)
	var inicio := Vector2i((_jogador.global_position / PASSO).floor())
	if not livre.has(inicio):
		_erro("o jogador nasce sem lugar para ficar de pe, em %s" % _jogador.global_position)
		return

	var alcancavel := _espalhar(livre, inicio)
	print("  o mundo tem %.0f m x %.0f m; cabe ficar de pe em %d celulas de %.1f m," % [
		Mapa.MUNDO.size.x / 40.0, Mapa.MUNDO.size.y / 40.0, livre.size(), PASSO / 40.0])
	print("  e da para chegar a pe em %d delas (%.0f%%)" % [
		alcancavel.size(), 100.0 * alcancavel.size() / float(livre.size())])

	# Os lugares com nome, com a distancia de casa.
	var inalcancaveis := 0
	for lugar in Mapa.lugares():
		var r: Rect2 = lugar["rect"]
		if not _tem_celula_em(alcancavel, r, PASSO):
			_erro("nao da para chegar a pe em %s" % lugar["nome"])
			inalcancaveis += 1
			continue
		var longe := _jogador.global_position.distance_to(r.get_center())
		print("  %-30s a %4.0f m da sua casa, %3.0f s de caminhada" % [
			lugar["nome"], longe / 40.0, longe / VELOCIDADE])
	if inalcancaveis == 0:
		print("  todo lugar com nome se alcanca a pe")

	# Todo movel, e a porta de casa.
	var ruins := 0
	var quantos := 0
	for movel in _moveis():
		quantos += 1
		var tamanho := ((movel as Node2D).get_node("Deteccao").shape as RectangleShape2D).size
		var zona := Rect2((movel as Node2D).position - tamanho / 2.0, tamanho)
		if not _tem_celula_em(alcancavel, zona, PASSO):
			_erro("%s em %s (%s) e inalcancavel" % [
				(movel as Node2D).get("rotulo"), (movel as Node2D).position,
				Mapa.lugar_em((movel as Node2D).position)])
			ruins += 1
	# A zona da porta lida da forma de verdade (era 220 x 160 escrito a mao,
	# que so valia para a porta deitada e com o ALCANCE antigo).
	var porta := _rua.get_node("EntradaDeCasa") as Node2D
	var tamanho_da_porta := ((porta.get_node("Deteccao") as CollisionShape2D).shape as RectangleShape2D).size
	var zona_da_porta := Rect2(porta.position - tamanho_da_porta / 2.0, tamanho_da_porta)
	if not _tem_celula_em(alcancavel, zona_da_porta, PASSO):
		_erro("a porta de casa e inalcancavel")
	print("  %d moveis, %d inalcancaveis" % [quantos, ruins])

	# Todo quarto de todo predio - menos a sua casa, que tem que estar selada.
	var quartos_ruins := 0
	var predios := 0
	for construcao in Mapa.mundo()["construcoes"]:
		var quartos := Construcao.quartos_de(construcao)
		if construcao.get("sua", false):
			quartos_ruins += _a_sua_casa_esta_selada(alcancavel, quartos)
			continue
		predios += 1
		for j in quartos.size():
			if not _tem_celula_em(alcancavel, quartos[j], PASSO):
				_erro("quarto %d de %s sem passagem" % [j, _nome_de(construcao)])
				quartos_ruins += 1
				_explicar_o_quarto(construcao, quartos[j], livre, alcancavel)
	print("  %d predios, %d quartos sem passagem" % [predios, quartos_ruins])

## O que esta em volta de um quarto sem passagem: as paredes, os moveis do
## predio e quantas celulas do quarto sao livres (cabe ficar de pe) contra
## quantas se alcancam. E o que diz se o problema e geometria (nenhuma celula
## livre) ou passagem (livres, mas isoladas).
func _explicar_o_quarto(construcao: Dictionary, quarto: Rect2, livre: Dictionary,
		alcancavel: Dictionary) -> void:
	var livres := 0
	var alcancadas := 0
	var de := Vector2i((quarto.position / PASSO).floor())
	var ate := Vector2i((quarto.end / PASSO).ceil())
	for c in range(de.x, ate.x + 1):
		for l in range(de.y, ate.y + 1):
			var celula := Vector2i(c, l)
			if not quarto.has_point(_centro(celula, PASSO)):
				continue
			if livre.has(celula):
				livres += 1
			if alcancavel.has(celula):
				alcancadas += 1
	print("    quarto %s, porta %s: %d celulas livres, %d alcancadas" % [
		quarto, construcao["porta"], livres, alcancadas])
	for parede in Construcao.paredes_internas(construcao):
		print("    divisoria %s" % parede)
	for movel in _moveis():
		if (construcao["rect"] as Rect2).has_point((movel as Node2D).position):
			print("    movel %s em %s, %s" % [(movel as Node2D).get("rotulo"),
				(movel as Node2D).position, (movel as Node2D).get("tamanho")])

## Em todo predio do mapa, quarto sem passagem e bug. **Na sua casa e o
## desenho** (16/09/2026): o unico jeito de entrar nela e segurar E na porta, e
## isso troca para a cena da casa em vez de te por dentro do predio. Entao aqui
## a conferencia inverte: se der para chegar a pe em algum quarto dela, a porta
## parou de ser a unica entrada.
func _a_sua_casa_esta_selada(alcancavel: Dictionary, quartos: Array[Rect2]) -> int:
	var abertos := 0
	for j in quartos.size():
		if _tem_celula_em(alcancavel, quartos[j], PASSO):
			abertos += 1
	if abertos > 0:
		_erro("da para entrar na sua casa a pe: %d dos %d quartos se alcancam"
			% [abertos, quartos.size()] + " pela rua, e a porta devia ser a unica entrada")
	else:
		print("  a sua casa esta selada: so se entra pela porta")
	return abertos

## Cada movel gerado.
func _moveis() -> Array[Node]:
	var lista: Array[Node] = []
	for filho in _rua.get_node("Cenario").get_children():
		if filho is Area2D and "rotulo" in filho:
			lista.append(filho)
	return lista

# --- 2. os documentos ---------------------------------------------------------

## Os seis documentos placeholder tem que estar em seis lugares diferentes, e
## cada um sair uma vez so. E nenhum lugar sozinho pode fechar a cura: se um
## fechasse, o resto do mapa seria cenario bonito sem funcao mecanica nenhuma.
func _os_documentos() -> void:
	print("\n2. os documentos")
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

	var por_lugar := {}
	for achado in onde_estao:
		print("  %-22s em %s" % [achado, onde_estao[achado]])
		por_lugar[onde_estao[achado]] = por_lugar.get(onde_estao[achado], 0) + 1
	for lugar in por_lugar:
		if por_lugar[lugar] >= Travessia.DOCUMENTOS_PARA_A_CURA:
			_erro("'%s' sozinho fecha a cura (%d documentos) - o resto do mapa nao serve para nada"
				% [lugar, por_lugar[lugar]])
	print("  a cura pede %d; o lugar mais rico tem %d" % [
		Travessia.DOCUMENTOS_PARA_A_CURA, por_lugar.values().max() if not por_lugar.is_empty() else 0])

# --- 3. a identidade dos moveis ----------------------------------------------

## **Imprimir nao e checagem.** Compara a impressao digital das chaves contra
## `Mapa.IMPRESSAO_ESPERADA`, commitada: mudou sem ninguem atualizar a
## constante de proposito, o build cai.
func _a_identidade_bate() -> void:
	print("\n3. a identidade dos moveis")
	var cenario := _rua.get_node("Cenario")
	var chaves: PackedStringArray = cenario.chaves_dos_moveis()
	var impressao := _hash_das_chaves(chaves)
	print("  VERSAO DO MAPA: %d" % Mapa.VERSAO_DO_MAPA)
	print("  IMPRESSAO DIGITAL DOS MOVEIS: %s (%d moveis)" % [impressao, chaves.size()])
	if impressao != Mapa.IMPRESSAO_ESPERADA:
		_erro(("a identidade dos moveis mudou (esperava %s, veio %s); se foi de " +
			"proposito, atualize Mapa.IMPRESSAO_ESPERADA para o valor de cima")
			% [Mapa.IMPRESSAO_ESPERADA, impressao])

func _hash_das_chaves(chaves: PackedStringArray) -> String:
	return "%08x" % Construcao.embaralhar(",".join(chaves))
