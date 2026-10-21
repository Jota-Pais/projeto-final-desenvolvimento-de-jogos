extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no tutorial, nas falas
## dele ou na regiao rosa.**
##
## Roda o tutorial de ponta a ponta sem ninguem no teclado - as falas de perto
## avancam com o E apertado aqui - e confere cada etapa (rua/tutorial.gd):
##
##  1. a abertura: o jogador anda sob roteiro, o zumbi o pega e o Antonio o
##     mata, e a conversa no portao acaba no favor, com o jogador de volta no
##     controle, a camera do jogo e o item num movel do Restaurante;
##  2. o vasculho do movel entrega o item e manda voltar ao portao;
##  3. no portao, a entrega da a 9mm: armado, a Beretta na mao, um pente;
##  4. o dia 2 pede para atirar, e o primeiro zumbi abatido fecha o tutorial.
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
	if not await _esperar(func() -> bool: return jogador.no_roteiro, 5.0):
		_erro("a cena nao pos o jogador sob roteiro")
	# As falas da cena (o grito depois do tiro, o portao) vao sendo passadas;
	# a cena acaba no favor.
	var fim := Time.get_ticks_msec() + 40000
	while Travessia.tutorial == "abertura" and Time.get_ticks_msec() < fim:
		await _passar_as_falas(2.0)
		await get_tree().process_frame
	if Travessia.tutorial != "favor":
		_erro("a abertura nao chegou ao favor (etapa '%s')" % Travessia.tutorial)
		return
	if _mortos() <= mortos_antes:
		_erro("nenhum zumbi caiu na cena - o tiro do Antonio nao matou")
	else:
		print("  o zumbi pegou o jogador (vida %d) e o Antonio o matou" % jogador.vida)
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

	print("\n2. o favor no Restaurante")
	var movel: Node = tutorial._movel_do_favor
	if movel == null or not Falas.ITEM_DO_FAVOR in movel.achados:
		_erro("o item do favor nao esta em movel nenhum do Restaurante")
		return
	print("  o item esta em '%s', em %s (%s)" % [movel.rotulo, movel.position, Mapa.lugar_em(movel.position)])
	movel._esvaziar()
	if Travessia.tutorial != "voltar_ao_portao":
		_erro("vasculhar o movel nao entregou o item (etapa '%s')" % Travessia.tutorial)
		return
	print("  vasculhado: '%s'" % tutorial._objetivo.text)

	print("\n3. a volta e a 9mm")
	jogador.global_position = Mapa.ponto_do_png(tutorial.CONVERSA_NO_PORTAO) + Vector2(0.0, -20.0)
	# A conversa corta o radio: abre na hora.
	if not await _esperar(func() -> bool: return CaixaDeFala.aberta, 3.0):
		_erro("chegar ao portao com o item nao abriu a conversa")
	fim = Time.get_ticks_msec() + 20000
	while Travessia.tutorial == "voltar_ao_portao" and Time.get_ticks_msec() < fim:
		await _passar_as_falas(2.0)
		await get_tree().process_frame
	if Travessia.tutorial != "ir_para_casa":
		_erro("a entrega nao acabou em 'ir_para_casa' (etapa '%s')" % Travessia.tutorial)
	elif not Travessia.armado or Travessia.arma != Travessia.ARMA_DE_COMECO \
			or Travessia.balas.get(Travessia.CALIBRE_DE_COMECO, 0) < Travessia.BALAS_DE_COMECO:
		_erro("a recompensa nao deu a Beretta com um pente (armado %s, %s, %d balas)" % [
			Travessia.armado, Travessia.arma, Travessia.balas.get(Travessia.CALIBRE_DE_COMECO, 0)])
	else:
		print("  armado: %s com %d balas; '%s'" % [Travessia.arma,
			Travessia.balas[Travessia.CALIBRE_DE_COMECO], tutorial._objetivo.text])

	print("\n4. o dia 2")
	Travessia.dia = 2
	_montar_a_rua()
	tutorial = _rua.get_node("Tutorial")
	if not await _esperar(func() -> bool: return Travessia.tutorial == "dia_2", 5.0):
		_erro("o dia 2 nao comecou a etapa dia_2 (etapa '%s')" % Travessia.tutorial)
		return
	await get_tree().process_frame
	print("  '%s'" % tutorial._objetivo.text)
	var zumbis := get_tree().get_nodes_in_group("zumbi")
	if zumbis.is_empty():
		_erro("nao ha zumbi por perto no dia 2 para atirar")
		return
	(zumbis[0] as Node).levar_tiro(1000.0, Vector2.RIGHT)
	if not await _esperar(func() -> bool: return Travessia.tutorial == "fim", 3.0):
		_erro("o primeiro zumbi abatido nao fechou o tutorial (etapa '%s')" % Travessia.tutorial)
	else:
		print("  o primeiro zumbi abatido fechou o tutorial")

func _mortos() -> int:
	var n := 0
	for filho in _rua.get_node("Cenario").get_children():
		if filho.get("morto") == true:
			n += 1
	return n
