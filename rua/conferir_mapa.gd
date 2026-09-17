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
const Vias := preload("res://rua/vias.gd")
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
	# A fase 0 le so o dicionario (Mapa.mundo()), antes de qualquer coisa
	# instanciar - custa milissegundos, e roda ANTES das duas passadas
	# fisicas de baixo, que continuam intactas.
	_a_geometria_fecha()

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
	_a_identidade_bate()

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	if not Engine.is_editor_hint():
		get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

# --- 0. a geometria do dado --------------------------------------------------
#
# A FASE 0 (17/09/2026, P4 do plano da arquitetura nova). Le so
# `Mapa.mundo()` - nenhuma fisica, nenhuma cena -, e por isso roda ANTES de
# instanciar `rua.tscn` e custa milissegundos. As duas passadas fisicas
# abaixo (1 e 2) continuam intactas.
#
# Doutrina da borda, valendo para toda checagem daqui para baixo:
# sobreposicao se testa com `grow(-1)` (dois retangulos so encostando na
# borda um do outro NAO sao sobreposicao), porque `Rect2.intersects()` do
# Godot conta a borda como colisao.
#
# **Este e o portao que tem que ACUSAR o mapa quebrado.** Um validador que
# aprova o mapa quebrado aprovaria o bom tambem - por isso ele entra ANTES do
# layout ser reescrito (P4), contra o mapa de entao. Naquele dia (17/09/2026,
# antes de qualquer coisa de P5 em diante) ele acusou **64 problemas reais**:
# a rua do fundo do bairro morrendo num toco, ~40 entradas de carro que nao
# alcancavam via nenhuma, ~14 portas encarando o mato, o mercado invadindo a
# rua vizinha, e tres lugares "mata" com densidade de bosque raro.
#
# **P7 trocou a rede de vias inteira** (bairro 100% ao sul da rodovia, cidade
# 100% ao norte, as duas com layout novo) **sem tocar nas construcoes** - de
# proposito: o objetivo de P7 e provar que a REDE fecha, nao que ela already
# bate com o predio. Por isso boa parte dos 64 originais mudou de forma (a
# maioria das casas antigas passa a nao encarar via nenhuma da rede nova, ja
# que a rede mudou de posicao debaixo delas) - **isso e esperado**, e e
# trabalho de P8/P9 fechar, nao deste comentario.
#
# Corrigir os achados de cada dia e o trabalho do PROXIMO passo do plano;
# aqui so se prova que o validador ENXERGA.
func _a_geometria_fecha() -> void:
	print("0. a geometria do dado")
	var antes := _falhas
	_a_rede_de_vias_fecha()
	_a_largura_bate_com_a_classe()
	_o_predio_encara_uma_via()
	_a_entrada_de_carro_chega_na_via()
	_predio_nao_cruza_via_nem_calcada_nem_piso()
	_predio_nao_cruza_predio()
	_predio_dentro_do_lugar_e_do_mundo()
	_mata_tem_nome_de_mata()
	_ha_segunda_rota_bairro_cidade()
	print("  %d achado(s) nesta fase" % (_falhas - antes))

## Critério F: existe uma rota entre o bairro e a cidade que NAO depende da
## rodovia - a "segunda rota" (17/09/2026, P7). Tira toda via de classe
## `rodovia` do grafo e confere que o `acesso` do bairro ainda alcanca o da
## cidade pelas vias que sobraram (BFS). Bem mais simples que provar 2
## caminhos aresta-disjuntos de verdade (precisaria partir a rodovia em
## arestas finas nos cruzamentos, o que o grafo de hoje nao faz), mas prova
## a mesma coisa que importa: o bairro nao fica isolado se a rodovia sumir.
func _ha_segunda_rota_bairro_cidade() -> void:
	var vias: Array = Mapa.mundo()["vias"]
	var sem_rodovia := []
	for via in vias:
		if (via as Dictionary)["classe"] != "rodovia":
			sem_rodovia.append(via)

	var bairro: Dictionary = Mapa.lugar("bairro")
	var cidade: Dictionary = Mapa.lugar("cidade")
	if not (bairro.has("acesso") and cidade.has("acesso")):
		_erro("bairro ou cidade sem 'acesso' declarado - a segunda rota nao tem de onde partir")
		return

	if not _alcancavel_no_grafo(sem_rodovia, bairro["acesso"], cidade["acesso"]):
		_erro("sem a rodovia, o bairro (acesso %s) nao alcanca a cidade (acesso %s) por via nenhuma - so ha uma rota"
			% [bairro["acesso"], cidade["acesso"]])

## BFS sobre o grafo de `vias`, achando o no mais perto de `de` e de `ate` e
## conferindo que estao no mesmo componente.
func _alcancavel_no_grafo(vias: Array, de: Vector2, ate: Vector2) -> bool:
	var grafo := Vias.grafo(vias)
	var nos: Dictionary = grafo["nos"]
	if nos.is_empty():
		return false
	var no_de := ""
	var no_ate := ""
	var perto_de := INF
	var perto_ate := INF
	for nome in nos:
		var p: Vector2 = nos[nome]
		var d1 := p.distance_to(de)
		if d1 < perto_de:
			perto_de = d1
			no_de = nome
		var d2 := p.distance_to(ate)
		if d2 < perto_ate:
			perto_ate = d2
			no_ate = nome

	var incidencias: Dictionary = grafo["incidencias"]
	# Vizinhanca no->no, por via em comum.
	var vizinhos := {}
	for nome in nos:
		vizinhos[nome] = []
	for i in vias.size():
		var nome_via: String = (vias[i] as Dictionary)["nome"]
		var quem := []
		for nome in nos:
			if (incidencias[nome] as Array).has(nome_via):
				quem.append(nome)
		for a in quem:
			for b in quem:
				if a != b and not (vizinhos[a] as Array).has(b):
					(vizinhos[a] as Array).append(b)

	var visitados := { no_de: true }
	var fila: Array = [no_de]
	while not fila.is_empty():
		var atual: String = fila.pop_back()
		if atual == no_ate:
			return true
		for vizinho in (vizinhos[atual] as Array):
			if not visitados.has(vizinho):
				visitados[vizinho] = true
				fila.append(vizinho)
	return no_ate in visitados

## Sobreposicao de verdade: os dois cresceram -1, para dois retangulos so se
## tocando na borda nao contarem.
func _sobrepoe(a: Rect2, b: Rect2) -> bool:
	return a.grow(-1.0).intersects(b.grow(-1.0))

## Toda via tem que terminar em outra via (grau >= 2), na borda do MUNDO, ou
## ter uma ponta declarada que o proprio nome ja diz o tipo ("borda",
## "T:...", "emenda:...", "laco:...", "u:..."). `pontas` so declara o TIPO da
## excecao - quem prova e o grafo (`Vias.grafo`), que acha os nos por
## geometria e nao por declaracao.
func _a_rede_de_vias_fecha() -> void:
	var vias: Array = Mapa.mundo()["vias"]
	var grafo := Vias.grafo(vias)
	var nos: Dictionary = grafo["nos"]
	var grau: Dictionary = grafo["grau"]
	var incidencias: Dictionary = grafo["incidencias"]
	var pontas_por_via := {}
	for via in vias:
		pontas_por_via[(via as Dictionary)["nome"]] = (via as Dictionary).get("pontas", [])

	for nome in nos:
		if int(grau[nome]) >= 2:
			continue
		var p: Vector2 = nos[nome]
		if not Mapa.MUNDO.grow(-200.0).has_point(p):
			continue  # perto da borda do mundo: fim legitimo
		# So uma via incide neste no (grau 1) - ela declarou um tipo de ponta
		# legitimo para ESTA ponta especifica?
		var via_incidente: String = (incidencias[nome] as Array)[0]
		var declarada := false
		for tipo in (pontas_por_via.get(via_incidente, []) as Array):
			if (tipo as String) != "":
				declarada = true
				break
		if declarada:
			continue
		_erro("a via '%s' morre sem ligar a nada, em %s (grau %d, sem ponta declarada)"
			% [via_incidente, p, grau[nome]])

## A largura de cada via reta bate com a faixa `[minima, maxima]` da propria
## classe - a checagem le a MESMA fonte que o dado (`Vias.CLASSES`), entao
## uma classe nova sem faixa reprova em vez de passar em silencio.
func _a_largura_bate_com_a_classe() -> void:
	for via in Mapa.mundo()["vias"]:
		var classe: String = (via as Dictionary)["classe"]
		var faixa: Dictionary = Vias.CLASSES[classe]
		if faixa["minima"] <= 0.0 and faixa["maxima"] <= 0.0:
			continue  # classe sem largura de verdade (hoje: laco em bulbo)
		var largura := Vias.largura_de(via)
		if largura < faixa["minima"] or largura > faixa["maxima"]:
			_erro("a via '%s' (classe %s) tem %.0f px de largura, fora de [%.0f, %.0f]"
				% [(via as Dictionary)["nome"], classe, largura, faixa["minima"], faixa["maxima"]])

## Toda construcao encara uma via que realmente passa na frente da porta - o
## vao nao pode abrir para o mato. "Encarar" quer dizer: existe alguma via
## reta cuja faixa cobre a projecao do vao no eixo da fachada, dentro de
## `RECUO_MAXIMO` da porta.
##
## **950, nao 400** (17/09/2026, P8): 400 vinha do recuo fixo de antes de
## quadras.gd (no maximo ~340 com o degrau de 120). O maior recuo de
## verdade hoje e o da classe `comercial` - 720 de recuo mais 120 de calcada
## mais 80 de grama = 920 -, e o cheque tem que caber isso com folga, senao
## ele proprio acusa um predio comercial corretamente recuado como se a
## porta encarasse o mato.
const RECUO_MAXIMO_DA_VIA := 950.0

func _o_predio_encara_uma_via() -> void:
	var vias: Array = Mapa.mundo()["vias"]
	for construcao in Mapa.mundo()["construcoes"]:
		var porta := Construcao.porta_de(construcao)
		var normal := Construcao.normal_de(construcao)
		# O RAIO inteiro da porta ate RECUO_MAXIMO_DA_VIA, nao so dois pontos
		# amostrados (achado em P8: um recuo de verdade cai em qualquer lugar
		# entre a porta e o maximo, e amostrar so `40` e o maximo passava
		# batido sempre que o recuo real caia no meio - por acaso quase todo
		# recuo de comercial/principal). Vira um retangulo fino (a largura de
		# uma pessoa) e confere INTERSECAO com a faixa da via, nao ponto.
		var perpendicular := Vector2(-normal.y, normal.x)
		var raio := Rect2(porta - perpendicular * 2.0, perpendicular * 4.0)
		raio = raio.abs().expand(porta + normal * RECUO_MAXIMO_DA_VIA)
		var achou := false
		for via in vias:
			if not Vias.e_reta(via):
				continue
			if Vias.faixa_de(via).grow(1.0).intersects(raio):
				achou = true
				break
		if not achou:
			_erro("%s em %s: a porta (%s, olhando %s) nao encara via nenhuma a ate %.0f px"
				% [construcao["tipo"], construcao["rect"], porta, normal, RECUO_MAXIMO_DA_VIA])

## A entrada de carro tem que chegar em asfalto de verdade - nao pode acabar
## na grama. Criterio A: `entrada_de_carro(c)` cresce 1 px e tem que
## interceptar alguma via reta.
func _a_entrada_de_carro_chega_na_via() -> void:
	var vias: Array = Mapa.mundo()["vias"]
	for construcao in Mapa.mundo()["construcoes"]:
		var entrada := Construcao.entrada_de_carro(construcao).grow(1.0)
		var achou := false
		for via in vias:
			if Vias.e_reta(via) and Vias.faixa_de(via).intersects(entrada):
				achou = true
				break
		if not achou:
			_erro("%s em %s: a entrada de carro (%s) nao chega em via nenhuma"
				% [construcao["tipo"], construcao["rect"], entrada])

## Nenhum predio pisa em via, calcada ou piso de concreto.
func _predio_nao_cruza_via_nem_calcada_nem_piso() -> void:
	var mundo := Mapa.mundo()
	for construcao in mundo["construcoes"]:
		var r: Rect2 = construcao["rect"]
		for via in mundo["vias"]:
			if not Vias.e_reta(via):
				continue
			if _sobrepoe(r, Vias.faixa_de(via)):
				_erro("%s em %s pisa na via '%s'" % [construcao["tipo"], r, (via as Dictionary)["nome"]])
		for calcada in mundo["calcadas"]:
			if _sobrepoe(r, calcada):
				_erro("%s em %s pisa na calcada" % [construcao["tipo"], r])
		for piso in mundo["piso"]:
			if _sobrepoe(r, piso):
				_erro("%s em %s pisa no piso de concreto" % [construcao["tipo"], r])

## Nenhum par de predios se sobrepoe.
func _predio_nao_cruza_predio() -> void:
	var construcoes: Array = Mapa.mundo()["construcoes"]
	for i in construcoes.size():
		for j in range(i + 1, construcoes.size()):
			var a: Rect2 = construcoes[i]["rect"]
			var b: Rect2 = construcoes[j]["rect"]
			if _sobrepoe(a, b):
				_erro("%s em %s se sobrepoe a %s em %s"
					% [construcoes[i]["tipo"], a, construcoes[j]["tipo"], b])

## Toda construcao cabe dentro do lugar que a gerou (com folga) e dentro do
## MUNDO. Nao ha "predio orfao", pisando fora de tudo.
func _predio_dentro_do_lugar_e_do_mundo() -> void:
	for construcao in Mapa.mundo()["construcoes"]:
		var r: Rect2 = construcao["rect"]
		if not Mapa.MUNDO.encloses(r):
			_erro("%s em %s sai dos limites do MUNDO" % [construcao["tipo"], r])
			continue
		var achou := false
		for lugar in Mapa.LUGARES:
			if (lugar["rect"] as Rect2).grow(600.0).encloses(r):
				achou = true
				break
		if not achou:
			_erro("%s em %s nao cabe (nem com folga) em nenhum lugar do MUNDO" % [construcao["tipo"], r])

## Lugar cujo nome comeca com "mata" tem que ter densidade de mata (>= 0,4) -
## senao o rotulo mente. **Nao corrige nada** (o rename floresta -> bosque /
## mata / campo e P9): so acusa o que ja esta errado hoje.
func _mata_tem_nome_de_mata() -> void:
	for lugar in Mapa.LUGARES:
		if not (lugar["nome"] as String).begins_with("mata"):
			continue
		var densidade: float = lugar.get("densidade", 0.03)
		if densidade < 0.4:
			_erro("'%s' tem nome de mata fechada mas densidade %.2f (esperado >= 0,40)"
				% [lugar["nome"], densidade])

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
			# **A sua casa e a excecao, e ela e conferida ao contrario.**
			if construcao.get("sua", false):
				quartos_ruins += _a_sua_casa_esta_selada(alcancavel, quartos)
				continue
			for j in quartos.size():
				if not _tem_celula_em(alcancavel, quartos[j], PASSO_FINO):
					_erro("%s: quarto %d da %s sem passagem" % [
						lugar["nome"], j, construcao["tipo"]])
					quartos_ruins += 1

		if ruins == 0 and quartos_ruins == 0:
			print("  %-16s %2d moveis e todos os quartos, tudo alcancavel"
				% [lugar["nome"], quantos])

## A identidade dos moveis (17/09/2026, P6). Diferente da fase 0: essa
## precisa do Cenario JA INSTANCIADO (a chave nasce em `_criar_movel`, e nao
## esta em `Mapa.mundo()`), entao roda aqui, depois das duas passadas fisicas.
##
## **Imprimir nao e checagem.** Antes desta funcao, "IMPRESSAO DIGITAL DOS
## MOVEIS" so aparecia no console - se a identidade embaralhasse de novo (um
## gerador reordenado, um indice que virou outro movel), nada acusava. Agora
## compara contra `Mapa.IMPRESSAO_ESPERADA`, commitada: mudou sem ninguem
## atualizar a constante de proposito, o build cai.
func _a_identidade_bate() -> void:
	print("\n4. a identidade dos moveis")
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

## Em todo predio do mapa, quarto sem passagem e bug. **Na sua casa e o
## desenho** (16/09/2026): o unico jeito de entrar nela e segurar E na porta, e
## isso troca para a cena da casa em vez de te por dentro do predio.
##
## Entao aqui a conferencia inverte: se der para chegar a pe em algum quarto
## dela, a porta parou de ser a unica entrada - e ninguem descobre isso lendo o
## codigo, porque basta a colisao da porta sumir para o vao virar corredor.
## Ja aconteceu uma vez, em 15/09, e foi assim que este teste nasceu.
func _a_sua_casa_esta_selada(alcancavel: Dictionary, quartos: Array[Rect2]) -> int:
	var abertos := 0
	for j in quartos.size():
		if _tem_celula_em(alcancavel, quartos[j], PASSO_FINO):
			abertos += 1
	if abertos > 0:
		_erro("da para entrar na sua casa a pe: %d dos %d quartos se alcancam"
			% [abertos, quartos.size()] + " pela rua, e a porta devia ser a unica entrada")
	else:
		print("  %-16s a sua casa esta selada: so se entra pela porta" % "bairro")
	return abertos

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
	# A porta de casa nao e movel gerado, mas tem que ser alcancavel igual.
	var porta := _rua.get_node("EntradaDeCasa") as Node2D
	var onde := Mapa.lugar_em(porta.position)
	if not por_lugar.has(onde):
		por_lugar[onde] = []
	(por_lugar[onde] as Array).append(porta)
	return por_lugar

# --- 3. um documento por lugar ----------------------------------------------

## Os seis documentos placeholder tem que estar em seis lugares diferentes, e
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
		print("  %-22s em %s" % [achado, onde_estao[achado]])
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
