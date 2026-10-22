extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no tutorial, nas falas
## dele ou na regiao rosa.**
##
## Roda o tutorial de ponta a ponta sem ninguem no teclado - as falas de perto
## avancam com o E apertado aqui - e confere cada etapa (rua/tutorial.gd):
##
##  1. a abertura: o jogador anda sob roteiro, o zumbi o pega e o Antonio o
##     mata, e a conversa no portao acaba no favor, com o jogador de volta no
##     controle, a camera do jogo e um objetivo que nao entrega a piada;
##  2. os obstaculos do caminho: os zumbis de posto e as aulas, uma de cada
##     vez;
##  3. a chegada na pizzaria, e o vasculho do movel entrega o item e manda
##     voltar ao portao;
##  4. no portao, a entrega da a 9mm (armado, a Beretta na mao, um pente), o
##     Antonio agradece pela beta e o tutorial acaba.
##
## Espera por condicao com limite de tempo real, e nao por quadro: em headless
## o quadro e muito mais rapido que no jogo.

const CENA_DA_RUA := preload("res://rua/rua.tscn")
const Mapa := preload("res://rua/mapa.gd")
const Falas := preload("res://rua/falas_do_tutorial.gd")
const CaixaDeFala := preload("res://rua/caixa_de_fala.gd")

var _rua: Node
var _falhas := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Travessia.dia = 1
	Travessia.tutorial = "abertura"
	Travessia.tutorial_avisos.clear()
	Travessia.armado = false
	Travessia.moveis_vazios.clear()
	_montar_a_rua()
	await _conferir()
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	Travessia.tutorial = ""
	Travessia.armado = true
	get_tree().paused = false
	get_tree().quit(0 if _falhas == 0 else 1)

func _montar_a_rua() -> void:
	if _rua != null:
		remove_child(_rua)
		_rua.queue_free()
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Espera `condicao` virar verdade, ou `segundos` de relogio de verdade.
func _esperar(condicao: Callable, segundos: float) -> bool:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while not condicao.call():
		if Time.get_ticks_msec() > fim:
			return false
		await get_tree().process_frame
	return true

## Aperta e solta o E ate a fala de perto fechar e o jogo voltar.
func _passar_as_falas(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		if not CaixaDeFala.aberta and not get_tree().paused:
			return
		Input.action_press("vasculhar")
		await get_tree().process_frame
		await get_tree().process_frame
		Input.action_release("vasculhar")
		await get_tree().process_frame
		await get_tree().process_frame

func _conferir() -> void:
	var jogador := _rua.get_node("Jogador")
	var tutorial := _rua.get_node("Tutorial")

	print("1. a abertura")
	var mortos_antes := _mortos()
	# 20 s e nao 5 (21/10/2026): o tempo e de relogio, e a rua leva uns 5 s
	# para abrir nesta maquina quando ela esta carregada - o que se confere aqui
	# e a cena comecar, nao a pressa.
	if not await _esperar(func() -> bool: return jogador.no_roteiro, 20.0):
		_erro("a cena nao pos o jogador sob roteiro")
	# As falas da cena (o grito depois do tiro, o portao) vao sendo passadas;
	# a cena acaba no favor.
	var fim := Time.get_ticks_msec() + 90000
	while Travessia.tutorial == "abertura" and Time.get_ticks_msec() < fim:
		await _passar_as_falas(2.0)
		await get_tree().process_frame
	if Travessia.tutorial != "favor":
		_erro("a abertura nao chegou ao favor (etapa '%s')" % Travessia.tutorial)
		return
	if _mortos() <= mortos_antes:
		_erro("nenhum zumbi caiu na cena - o tiro do Antonio nao matou")
	else:
		print("  o zumbi correu atras do jogador (vida %d) e o Antonio o matou do portao" % jogador.vida)
	if jogador.no_roteiro:
		_erro("depois da conversa o jogador continua sob roteiro")
	var zoom: Vector2 = (jogador.get_node("Camera") as Camera2D).zoom
	if not zoom.is_equal_approx(Vector2.ONE * jogador.ZOOM_DA_CAMERA):
		_erro("a camera nao voltou ao zoom do jogo (%s)" % zoom)
	if jogador.global_position.distance_to(Mapa.ponto_do_png(tutorial.CONVERSA_NO_PORTAO)) > 80.0:
		_erro("a conversa nao foi no portao do Antonio")
	if Travessia.armado:
		_erro("o dia 1 devia comecar desarmado")
	print("  conversa no portao; o favor: %s" % tutorial._objetivo.text)

	if not Falas.ITEM_DO_FAVOR in tutorial._objetivo.text and not "pizzaria" in tutorial._objetivo.text.to_lower():
		print("  o objetivo nao entrega aonde nem o que antes da chegada")
	else:
		_erro("o objetivo do favor entrega a piada antes da chegada: '%s'" % tutorial._objetivo.text)

	print("\n2. os obstaculos do caminho")
	await _conferir_os_obstaculos(tutorial)

	print("\n3. o favor na Cover Pizzaria")
	var movel: Node = tutorial._movel_do_favor
	if movel == null or not Falas.ITEM_DO_FAVOR in movel.achados:
		_erro("o item do favor nao esta em movel nenhum da Cover Pizzaria")
		return
	print("  o item esta em '%s', em %s (%s)" % [movel.rotulo, movel.position, Mapa.lugar_em(movel.position)])
	# Entrar na pizzaria e a chegada: a piada do pepperoni e o objetivo que
	# agora diz o que e onde.
	jogador.global_position = (movel as Node2D).global_position + Vector2(0.0, 30.0)
	if not await _esperar(func() -> bool: return Travessia.tutorial_avisos.has("chegada"), 3.0):
		_erro("entrar na pizzaria nao tocou a chegada (o planta e %s, o jogador em %s)" % [
			tutorial._pizzaria, jogador.global_position])
	elif not Falas.ITEM_DO_FAVOR in tutorial._objetivo.text:
		_erro("depois da chegada o objetivo devia dizer o que buscar: '%s'" % tutorial._objetivo.text)
	else:
		print("  a chegada tocou; '%s'" % tutorial._objetivo.text)
	movel._esvaziar()
	if Travessia.tutorial != "voltar_ao_portao":
		_erro("vasculhar o movel nao entregou o item (etapa '%s')" % Travessia.tutorial)
		return
	print("  vasculhado: '%s'" % tutorial._objetivo.text)

	print("\n4. a volta e a 9mm")
	jogador.global_position = Mapa.ponto_do_png(tutorial.CONVERSA_NO_PORTAO) + Vector2(0.0, -20.0)
	# A conversa corta o radio: abre na hora.
	if not await _esperar(func() -> bool: return CaixaDeFala.aberta, 3.0):
		_erro("chegar ao portao com o item nao abriu a conversa")
	fim = Time.get_ticks_msec() + 20000
	while Travessia.tutorial == "voltar_ao_portao" and Time.get_ticks_msec() < fim:
		await _passar_as_falas(2.0)
		await get_tree().process_frame
	if Travessia.tutorial != "fim":
		_erro("a entrega e o fim da beta nao fecharam o tutorial (etapa '%s')" % Travessia.tutorial)
	elif not Travessia.armado or Travessia.arma != Travessia.ARMA_DE_COMECO \
			or Travessia.balas.get(Travessia.CALIBRE_DE_COMECO, 0) < Travessia.BALAS_DE_COMECO:
		_erro("a recompensa nao deu a Beretta com um pente (armado %s, %s, %d balas)" % [
			Travessia.armado, Travessia.arma, Travessia.balas.get(Travessia.CALIBRE_DE_COMECO, 0)])
	else:
		print("  armado: %s com %d balas; o fim da beta fechou o tutorial: '%s'" % [Travessia.arma,
			Travessia.balas[Travessia.CALIBRE_DE_COMECO], tutorial._objetivo.text])
	if jogador.no_roteiro:
		_erro("depois do fim da beta o jogador continua sob roteiro")
	# O dia seguinte nao tem mais tutorial.
	Travessia.dia = 2
	_montar_a_rua()
	await get_tree().process_frame
	var seguinte := _rua.get_node_or_null("Tutorial")
	if seguinte != null and not seguinte.is_queued_for_deletion():
		_erro("o dia seguinte ao fim da beta ainda tem tutorial")
	else:
		print("  o dia seguinte e livre")

## Os zumbis de posto (rua/tutorial.gd, OBSTACULOS e o da porta): cada um no
## lugar, longe da porta de casa, longe dos outros obstaculos (para um nao
## chamar o outro), parado ali; chegar perto toca a aula do obstaculo; e o da
## porta larga o posto quando ouve alguma coisa.
func _conferir_os_obstaculos(tutorial: Node) -> void:
	var jogador := _rua.get_node("Jogador") as Node2D
	var casa := Mapa.onde_fica_a_porta_de_casa()
	var todos: Array = []
	for i in tutorial._obstaculos.size():
		for z in tutorial._obstaculos[i]:
			todos.append([i, z])
	todos.append([tutorial._obstaculos.size(), tutorial._zumbi_da_porta])
	for par in todos:
		var z: Node2D = par[1]
		if not is_instance_valid(z) or not z.de_posto():
			_erro("um zumbi de obstaculo (%d) nao esta de posto" % par[0])
			return
		if z.global_position.distance_to(casa) < Mapa.SEM_ZUMBI_PERTO_DE_CASA:
			_erro("zumbi de obstaculo a %.0f px da porta de casa" % z.global_position.distance_to(casa))
		for outro in todos:
			if outro[0] != par[0] and z.global_position.distance_to((outro[1] as Node2D).global_position) <= z.ALCANCE_DO_CHAMADO:
				_erro("os obstaculos %d e %d estao perto o bastante para um chamar o outro" % [par[0], outro[0]])
	var antes: Array = []
	for par in todos:
		antes.append((par[1] as Node2D).global_position)
	await get_tree().create_timer(1.0).timeout
	for k in todos.size():
		if (todos[k][1] as Node2D).global_position.distance_to(antes[k]) > 2.0:
			_erro("o zumbi de posto do obstaculo %d saiu do lugar sem ver nem ouvir nada" % todos[k][0])
	print("  %d zumbis de posto em %d obstaculos e na porta, parados" % [todos.size(), tutorial._obstaculos.size()])
	# As aulas, uma de cada vez (rua/tutorial.gd, AULAS): cada uma so comeca
	# com a de antes feita e o radio livre. O radio e cortado entre uma e
	# outra - as linhas levariam segundos de relogio para passar.
	var caixa := _rua.get_node("CaixaDeFala")
	var porta: Node2D = tutorial._zumbi_da_porta
	Travessia.arremessaveis["pedra"] = 0
	Travessia.arremessaveis["garrafa"] = 0
	caixa.calar_o_radio()
	# Perto do primeiro, olhando para quem desce: como eles veem. Perto do
	# segundo tambem, mas a dele espera.
	var primeiro: Node2D = tutorial._obstaculos[0][0]
	jogador.global_position = primeiro.global_position + Vector2(0.0, -tutorial.AVISO_DO_OBSTACULO + 40.0)
	await _aula("como_veem", "chegar perto do zumbi que olha para quem desce")
	caixa.calar_o_radio()
	await get_tree().create_timer(0.3).timeout
	if Travessia.tutorial_avisos.has("barulho"):
		_erro("a aula do barulho comecou antes de o jogador passar do primeiro obstaculo")
	# No fim da cerca, ja ao sul do primeiro: os dois do onibus.
	jogador.global_position = Mapa.ponto_do_png(Vector2(1206.0, 699.0))
	await _aula("barulho", "passar do primeiro e chegar perto dos do onibus")
	caixa.calar_o_radio()
	# Do outro lado do onibus, perto da porta: o aviso; sem pedra, pegar.
	jogador.global_position = Mapa.ponto_do_png(Vector2(1201.5, 721.5))
	await _aula("porta", "passar do onibus e chegar perto da porta")
	caixa.calar_o_radio()
	await _aula("pedras", "o aviso da porta, sem pedra na mochila")
	caixa.calar_o_radio()
	await get_tree().create_timer(0.3).timeout
	if Travessia.tutorial_avisos.has("arremesso"):
		_erro("a aula do arremesso comecou antes de o jogador pegar pedra")
	Travessia.arremessaveis["pedra"] = 1
	await _aula("arremesso", "pegar a pedra")
	caixa.calar_o_radio()
	# O arremesso que tira ele da porta.
	var onde_caiu := porta.global_position + Vector2(150.0, 0.0)
	tutorial._ao_arremessar("pedra", onde_caiu)
	porta.foi_chamado(onde_caiu)
	if porta.de_posto():
		_erro("o zumbi da porta ouviu o barulho e continuou de posto")
	await _aula("arremesso_bom", "a pedra tirar o zumbi da porta")
	print("  as aulas tocaram uma de cada vez: %s" % ", ".join(PackedStringArray(Travessia.tutorial_avisos.keys())))
	# O jogador volta para longe de tudo, e o radio para.
	caixa.calar_o_radio()
	jogador.global_position = Mapa.ponto_do_png(tutorial.CONVERSA_NO_PORTAO)
	Travessia.arremessaveis["pedra"] = 0

## Espera a aula `chave` comecar, ou acusa o que devia te-la comecado.
func _aula(chave: String, depois_de: String) -> void:
	if not await _esperar(func() -> bool: return Travessia.tutorial_avisos.has(chave), 3.0):
		_erro("%s nao tocou a aula '%s'" % [depois_de, chave])

func _mortos() -> int:
	var n := 0
	for filho in _rua.get_node("Cenario").get_children():
		if filho.get("morto") == true:
			n += 1
	return n
