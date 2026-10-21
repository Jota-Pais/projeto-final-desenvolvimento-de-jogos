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
##
## ## Duas passadas: com o cerco e sem (21/10/2026)
##
## O tutorial se passa na regiao rosa, cercada (Mapa.BARREIRAS). Com o cerco
## ligado, que e o jogo de hoje, a passada 1a prova que **ele fecha** - o flood
## fill a partir de casa nao sai da regiao - e que la dentro tudo se alcanca.
## Depois a rua e montada de novo com o cerco desligado, e a passada 1 de
## sempre prova que o resto do mapa continua um lugar so: os muros de lote de
## dentro nao podem fechar porta de predio nenhum.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const Barreira := preload("res://rua/barreira.gd")
const Navegacao := preload("res://rua/navegacao.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const Jogador := preload("res://rua/jogador.gd")

## Quanto uma celula alcancada pode ficar para fora do contorno da regiao sem
## contar como furo no cerco: o contorno segue as barreiras por cima, a mao, e
## a barreira de borda pode correr um pouco do lado de fora dele.
const FOLGA_DO_CERCO := 96.0

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
	# instanciar - custa milissegundos. O dado do mapa e conferido com o cerco
	# ligado, como o jogo monta.
	Mapa.cerco_ligado = true
	Mapa.remontar()
	_o_dado_fecha()
	_as_barreiras_fecham()
	# Sem regiao declarada nao ha cerco para provar: vai direto a passada sem.
	_montar_a_rua(not Mapa.REGIAO_DO_TUTORIAL.is_empty())

## Uma rua nova, com o cerco ligado ou nao. A anterior sai da arvore antes de
## a nova entrar: duas ruas juntas sao dois jogadores no grupo "jogador".
func _montar_a_rua(com_cerco: bool) -> void:
	if _rua != null:
		remove_child(_rua)
		_rua.queue_free()
	Mapa.cerco_ligado = com_cerco
	Mapa.remontar()
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	_quadros = 0

func _process(_delta: float) -> void:
	# Espera a fisica assentar antes de consultar o espaco.
	_quadros += 1
	if _feito or _quadros < 4:
		return

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

	if Mapa.cerco_ligado:
		_o_cerco_fecha()
		_os_documentos()
		_a_identidade_bate()
		# E de novo, sem o cerco: o mapa inteiro.
		_montar_a_rua(false)
		return
	_feito = true

	_da_para_chegar_em_tudo()
	if Mapa.REGIAO_DO_TUTORIAL.is_empty():
		_os_documentos()
		_a_identidade_bate()
	# O cerco volta a ser o de sempre, para quem rodar depois na mesma sessao.
	Mapa.cerco_ligado = true
	Mapa.remontar()

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

	# Todo quarto de todo predio - menos a sua casa e a do Antonio, que tem que
	# estar seladas.
	var quartos_ruins := 0
	var predios := 0
	for construcao in Mapa.mundo()["construcoes"]:
		var quartos := Construcao.quartos_de(construcao)
		if construcao.get("sua", false) or construcao.get("selada", false):
			quartos_ruins += _esta_selada(construcao, alcancavel, quartos)
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
## parou de ser a unica entrada. A casa do Antonio (21/10/2026) e selada de
## vez: nem pela porta.
func _esta_selada(construcao: Dictionary, alcancavel: Dictionary, quartos: Array[Rect2]) -> int:
	var abertos := 0
	for j in quartos.size():
		if _tem_celula_em(alcancavel, quartos[j], PASSO):
			abertos += 1
	if abertos > 0:
		_erro("da para entrar em %s a pe: %d dos %d quartos se alcancam pela rua"
			% [_nome_de(construcao), abertos, quartos.size()])
	else:
		print("  %s esta selada" % _nome_de(construcao))
	return abertos

# --- 0b. o dado das barreiras (21/10/2026) -----------------------------------

## Cada barreira e de um tipo que existe, todo vao cabe o zumbi (a navegacao
## bloqueia um raio em volta de cada ponta) e nenhuma passa por dentro de
## predio. O cerco tem regiao, e a sua casa e a do Antonio estao nela.
func _as_barreiras_fecham() -> void:
	print("\n0b. o dado das barreiras")
	var antes := _falhas
	for barreira in Mapa.BARREIRAS:
		var nome: String = barreira.get("nome", "?")
		var tipo: String = barreira.get("tipo", "")
		if not Barreira.TIPOS.has(tipo):
			_erro("a barreira '%s' tem tipo '%s', que nao existe em Barreira.TIPOS" % [nome, tipo])
			continue
		if (barreira.get("pontos", []) as Array).size() < 2:
			_erro("a barreira '%s' tem menos de dois pontos" % nome)
		var minimo := _vao_minimo(tipo)
		for vao in barreira.get("vaos", []):
			var largura := float(vao.get("largura_mundo", Barreira.VAO))
			var portao = vao.get("portao")
			if portao != null and not Barreira.TIPOS.has(portao):
				_erro("o portao '%s' da barreira '%s' nao existe em Barreira.TIPOS" % [portao, nome])
			if portao == null and largura < minimo:
				_erro("um vao da barreira '%s' tem %.0f px; o zumbi so passa com %.0f" % [nome, largura, minimo])
	for objeto in Mapa.BARRICADAS:
		if not Barreira.OBJETOS.has(objeto.get("tipo", "")):
			_erro("a barricada '%s' tem tipo '%s', que nao existe em Barreira.OBJETOS"
				% [objeto.get("nome", "?"), objeto.get("tipo", "")])

	var mundo := Mapa.mundo()
	var segmentos := 0
	for barreira in mundo["barreiras"]:
		var pontos: PackedVector2Array = barreira["pontos"]
		segmentos += pontos.size() - 1
		for i in range(1, pontos.size()):
			for c in mundo["construcoes"]:
				if Mapa._segmento_cruza(pontos[i - 1], pontos[i], Construcao.interior_de(c).grow(-2.0)):
					_erro("a barreira '%s' passa por dentro de %s, em %s (png)"
						% [barreira["nome"], _nome_de(c), _no_png(pontos[i - 1].lerp(pontos[i], 0.5))])
	for barricada in mundo["barricadas"]:
		var cantos := Mapa.cantos_da_barricada(barricada)
		for c in mundo["construcoes"]:
			var dentro := Construcao.interior_de(c).grow(-2.0)
			for i in 4:
				if Mapa._segmento_cruza(cantos[i], cantos[(i + 1) % 4], dentro):
					_erro("a barricada '%s' entra em %s" % [barricada["nome"], _nome_de(c)])
					break

	var cercadas := 0
	for barreira in Mapa.BARREIRAS:
		if barreira.get("grupo", "") == "cerco_do_tutorial":
			cercadas += 1
	if cercadas > 0 and Mapa.REGIAO_DO_TUTORIAL.size() < 3:
		_erro("o cerco do tutorial tem barreira mas nao tem regiao (Mapa.REGIAO_DO_TUTORIAL)")
	if Mapa.REGIAO_DO_TUTORIAL.size() >= 3:
		for c in mundo["construcoes"]:
			if (c.get("sua", false) or c.get("selada", false)) \
					and not Mapa.dentro_do_cerco((c["rect"] as Rect2).get_center()):
				_erro("%s fica fora da regiao do tutorial" % _nome_de(c))
	print("  %d barreiras (%d do cerco) em %d segmentos, %d barricadas" % [
		Mapa.BARREIRAS.size(), cercadas, segmentos, (mundo["barricadas"] as Array).size()])
	print("  %d achado(s) nesta fase" % (_falhas - antes))

## O menor vao aberto que a grade do zumbi ainda atravessa: a navegacao
## bloqueia, em volta de cada ponta, a meia espessura mais a margem (nunca
## menos de meia celula), e no meio tem que sobrar uma celula inteira.
func _vao_minimo(tipo: String) -> float:
	var raio := maxf(float(Barreira.TIPOS[tipo]["espessura"]) / 2.0 + Navegacao.MARGEM,
		Navegacao.CELULA / 2.0)
	return maxf(Barreira.VAO_MINIMO, raio * 2.0 + Navegacao.CELULA)

## Um ponto do mundo em px do PNG, que e como o dado do mapa e escrito.
func _no_png(ponto: Vector2) -> Vector2:
	return ((ponto - Mapa.ponto_do_png(Vector2.ZERO)) / Mapa.ESCALA).round()

# --- 1a. o cerco do tutorial fecha (21/10/2026) ------------------------------

## Com o cerco ligado, o flood fill a partir de casa so roda numa caixa em
## volta da regiao (bem mais barato que o mundo inteiro): se ele encosta na
## borda da caixa, ou alcanca celula mais longe que FOLGA_DO_CERCO do lado de
## fora do contorno, o cerco tem furo - e as primeiras celulas de fora dizem
## onde. La dentro, todo movel, todo quarto (menos os selados), todo lugar com
## nome e a porta de casa tem que se alcancar.
func _o_cerco_fecha() -> void:
	print("\n1a. o cerco do tutorial fecha")
	var regiao := Mapa.regiao_do_tutorial()
	var caixa := Rect2(regiao[0], Vector2.ZERO)
	for p in regiao:
		caixa = caixa.expand(p)
	caixa = caixa.grow(FOLGA_DO_CERCO + PASSO * 4.0).intersection(Mapa.MUNDO)

	if not Mapa.dentro_do_cerco(_jogador.global_position):
		_erro("o jogador nasce fora da regiao do tutorial, em %s (png)" % _no_png(_jogador.global_position))
		return
	var livre := _onde_cabe(caixa, PASSO)
	var inicio := Vector2i((_jogador.global_position / PASSO).floor())
	if not livre.has(inicio):
		_erro("o jogador nasce sem lugar para ficar de pe, em %s" % _jogador.global_position)
		return
	var alcancavel := _espalhar(livre, inicio)

	var fora: Array[Vector2] = []
	var dentro := 0
	for celula in alcancavel:
		var centro := _centro(celula, PASSO)
		if Geometry2D.is_point_in_polygon(centro, regiao):
			dentro += 1
		elif _distancia_ao_contorno(centro, regiao) > FOLGA_DO_CERCO:
			fora.append(centro)
	var livres_dentro := 0
	for celula in livre:
		if Geometry2D.is_point_in_polygon(_centro(celula, PASSO), regiao):
			livres_dentro += 1
	print("  dentro da regiao cabe ficar de pe em %d celulas; da para chegar em %d" % [livres_dentro, dentro])
	if not fora.is_empty():
		_erro("o cerco tem furo: %d celulas alcancadas do lado de fora" % fora.size())
		_mostrar_o_furo(fora, regiao)
	else:
		print("  o cerco fecha: ninguem sai da regiao a pe")
		_a_navegacao_tambem_fecha(regiao, livre, alcancavel)

	var ruins := 0
	var quantos := 0
	for movel in _moveis():
		var onde := (movel as Node2D).position
		if not Mapa.dentro_do_cerco(onde):
			continue
		quantos += 1
		var tamanho := ((movel as Node2D).get_node("Deteccao").shape as RectangleShape2D).size
		if not _tem_celula_em(alcancavel, Rect2(onde - tamanho / 2.0, tamanho), PASSO):
			_erro("%s em %s (png %s) e inalcancavel dentro do cerco" % [
				(movel as Node2D).get("rotulo"), onde, _no_png(onde)])
			ruins += 1
	var porta := _rua.get_node("EntradaDeCasa") as Node2D
	var tamanho_da_porta := ((porta.get_node("Deteccao") as CollisionShape2D).shape as RectangleShape2D).size
	if not _tem_celula_em(alcancavel, Rect2(porta.position - tamanho_da_porta / 2.0, tamanho_da_porta), PASSO):
		_erro("a porta de casa e inalcancavel dentro do cerco")
	print("  %d moveis dentro, %d inalcancaveis" % [quantos, ruins])

	var predios := 0
	for construcao in Mapa.mundo()["construcoes"]:
		if not Mapa.dentro_do_cerco((construcao["rect"] as Rect2).get_center()):
			continue
		var quartos := Construcao.quartos_de(construcao)
		if construcao.get("sua", false) or construcao.get("selada", false):
			_esta_selada(construcao, alcancavel, quartos)
			continue
		predios += 1
		for j in quartos.size():
			if not _tem_celula_em(alcancavel, quartos[j], PASSO):
				_erro("quarto %d de %s sem passagem dentro do cerco" % [j, _nome_de(construcao)])
	for lugar in Mapa.lugares():
		var r: Rect2 = lugar["rect"]
		if Mapa.dentro_do_cerco(r.get_center()) and not _tem_celula_em(alcancavel, r, PASSO):
			_erro("nao da para chegar a pe em %s dentro do cerco" % lugar["nome"])
	print("  %d predios dentro do cerco" % predios)

## A navegacao do zumbi tem grade propria (rua/navegacao.gd), que bloqueia as
## barreiras por raio e nao pela forma: a fisica fechar nao prova que ela
## fecha. Do lado de fora, onde cabe ficar de pe mas o flood fill nao chegou,
## escolhe-se uma celula por oitavo em volta da regiao; de casa ate ela nao
## pode haver caminho - senao o zumbi tenta passar por onde o corpo nao passa,
## e encalha na barreira.
func _a_navegacao_tambem_fecha(regiao: PackedVector2Array, livre: Dictionary, alcancavel: Dictionary) -> void:
	var navegacao := get_tree().get_first_node_in_group("navegacao")
	navegacao.remontar_em(_jogador.global_position)
	var meio := Vector2.ZERO
	for p in regiao:
		meio += p
	meio /= float(regiao.size())
	var por_oitavo := {}
	for celula in livre:
		# Uma em cada 4 x 4 basta para achar um ponto por oitavo, e poupa a
		# distancia ao contorno de dezenas de milhares de celulas.
		if alcancavel.has(celula) or celula.x % 4 != 0 or celula.y % 4 != 0:
			continue
		var centro := _centro(celula, PASSO)
		if Geometry2D.is_point_in_polygon(centro, regiao) or _distancia_ao_contorno(centro, regiao) < FOLGA_DO_CERCO * 2.0:
			continue
		var oitavo := posmod(roundi((centro - meio).angle() / (TAU / 8.0)), 8)
		if not por_oitavo.has(oitavo) or centro.distance_to(meio) < (por_oitavo[oitavo] as Vector2).distance_to(meio):
			por_oitavo[oitavo] = centro
	var vazou := 0
	for oitavo in por_oitavo:
		var caminho: PackedVector2Array = navegacao.caminho(_jogador.global_position, por_oitavo[oitavo])
		if caminho.is_empty():
			continue
		vazou += 1
		for p in caminho:
			if not Geometry2D.is_point_in_polygon(p, regiao):
				_erro("a navegacao do zumbi sai do cerco perto de %s (png), a caminho de %s (png)"
					% [_no_png(p), _no_png(por_oitavo[oitavo])])
				break
	if vazou == 0:
		print("  a navegacao do zumbi tambem fecha: de casa, nenhum caminho para fora (%d pontos)"
			% por_oitavo.size())

func _distancia_ao_contorno(ponto: Vector2, regiao: PackedVector2Array) -> float:
	var menor := INF
	for i in regiao.size():
		var perto := Geometry2D.get_closest_point_to_segment(ponto, regiao[i], regiao[(i + 1) % regiao.size()])
		menor = minf(menor, ponto.distance_to(perto))
	return menor

## Onde o cerco vaza: das celulas alcancadas do lado de fora, as que estao
## mais perto do contorno - e por ali que o flood fill saiu.
func _mostrar_o_furo(fora: Array[Vector2], regiao: PackedVector2Array) -> void:
	var ordem := []
	for centro in fora:
		ordem.append([_distancia_ao_contorno(centro, regiao), centro])
	ordem.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var mostrados: Array[Vector2] = []
	for par in ordem:
		var centro: Vector2 = par[1]
		var perto := false
		for m in mostrados:
			if m.distance_to(centro) < 200.0:
				perto = true
				break
		if perto:
			continue
		mostrados.append(centro)
		print("    sai perto de %s (png), %s" % [_no_png(centro), Mapa.lugar_em(centro)])
		if mostrados.size() >= 5:
			break

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
