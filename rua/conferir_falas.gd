extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na caixa de fala**
## (rua/caixa_de_fala.gd). Roda headless e sai com 0 (passou) ou 1.
##
## Confere os dois jeitos de falar e a fila: de perto, o jogo para, o E
## completa a linha e depois avanca, e o jogo so volta com o E solto; pelo
## radio, o jogo segue e as linhas passam sozinhas; uma fala de perto que chega
## durante a do radio espera a vez.

const CENA_DA_CAIXA := preload("res://rua/caixa_de_fala.tscn")
const CaixaDeFala := preload("res://rua/caixa_de_fala.gd")

var _caixa: CanvasLayer
var _falhas := 0
var _acabaram := 0

func _ready() -> void:
	# A ferramenta continua rodando com o jogo parado pela fala de perto.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caixa = CENA_DA_CAIXA.instantiate()
	add_child(_caixa)
	_caixa.acabou.connect(func() -> void: _acabaram += 1)
	_conferir()

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame

## Espera a condicao valer, por no maximo `segundos` de relogio. Headless os
## quadros correm sem limite (cada um dura milissegundos), entao esperar "N
## quadros" nao mede tempo de leitura nenhum.
func _esperar(condicao: Callable, segundos: float) -> bool:
	var ate := Time.get_ticks_msec() + int(segundos * 1000.0)
	while not condicao.call():
		if Time.get_ticks_msec() > ate:
			return false
		await get_tree().process_frame
	return true

## Aperta E no comeco de um quadro (antes do _process da caixa) e solta no
## seguinte.
func _apertar_e() -> void:
	await get_tree().process_frame
	Input.action_press("vasculhar")
	await get_tree().process_frame
	Input.action_release("vasculhar")

func _conferir() -> void:
	await _quadros(2)
	var texto := _caixa.get_node("Caixa/Linha/Coluna/Texto") as Label
	var caixa := _caixa.get_node("Caixa") as Control

	print("1. de perto")
	_caixa.falar("Teste", PackedStringArray(["uma linha bem comprida para ainda estar sendo escrita", "duas"]))
	await _quadros(2)
	if not get_tree().paused or not CaixaDeFala.aberta:
		_erro("a fala de perto nao parou o jogo")
	if not caixa.visible:
		_erro("a caixa nao apareceu")
	if texto.visible_characters >= texto.text.length() or texto.visible_characters < 0:
		_erro("a linha ja apareceu inteira, sem ser escrita")
	await _apertar_e()
	if texto.visible_characters != texto.text.length() and texto.visible_characters != -1:
		_erro("o E nao completou a linha (%d de %d)" % [texto.visible_characters, texto.text.length()])
	await _apertar_e()
	if texto.text != "duas":
		_erro("o E nao passou para a segunda linha (\"%s\")" % texto.text)
	if not await _esperar(func() -> bool: return texto.visible_characters >= texto.text.length(), 2.0):
		_erro("a segunda linha nao terminou de ser escrita")
	# Ultima linha: um E fecha, mas o jogo so volta com ele solto.
	await get_tree().process_frame
	Input.action_press("vasculhar")
	await _quadros(3)
	if caixa.visible:
		_erro("a caixa nao fechou depois da ultima linha")
	if not get_tree().paused:
		_erro("o jogo voltou com o E ainda apertado")
	Input.action_release("vasculhar")
	await _quadros(2)
	if get_tree().paused or CaixaDeFala.aberta:
		_erro("o jogo nao voltou depois de soltar o E")
	if _acabaram != 1:
		_erro("'acabou' saiu %d vezes, e nao 1" % _acabaram)
	print("  para o jogo, o E completa e avanca, volta com o E solto")

	print("2. pelo radio")
	_caixa.pelo_radio("Teste", PackedStringArray(["curta", "outra"]))
	await _quadros(2)
	if get_tree().paused or CaixaDeFala.aberta:
		_erro("a fala pelo radio parou o jogo")
	if not caixa.visible:
		_erro("a caixa do radio nao apareceu")
	var nome := (_caixa.get_node("Caixa/Linha/Coluna/Nome") as Label).text
	if not "rádio" in nome:
		_erro("o nome nao diz que e pelo radio (\"%s\")" % nome)
	# As duas linhas passam sozinhas, ~1,7 s cada, sem nenhum E.
	var comeco := Time.get_ticks_msec()
	if not await _esperar(func() -> bool: return not caixa.visible, 6.0):
		_erro("as linhas do radio nao passaram sozinhas")
	elif _acabaram != 2:
		_erro("'acabou' do radio nao saiu")
	else:
		print("  o jogo segue e as duas linhas passaram sozinhas em %.1f s" % ((Time.get_ticks_msec() - comeco) / 1000.0))

	print("3. a fila")
	_caixa.pelo_radio("Radio", PackedStringArray(["antes"]))
	_caixa.falar("Perto", PackedStringArray(["depois"]))
	await _quadros(2)
	if get_tree().paused:
		_erro("a fala de perto passou na frente da do radio")
	if not await _esperar(func() -> bool: return get_tree().paused, 6.0) or texto.text != "depois":
		_erro("a fala de perto da fila nao entrou depois da do radio")
	else:
		print("  a de perto esperou a do radio e entrou depois")
	# Fecha a de perto para nao deixar o jogo parado.
	await _apertar_e()
	await _esperar(func() -> bool: return texto.visible_characters >= texto.text.length(), 2.0)
	await _apertar_e()
	await _quadros(3)
	if get_tree().paused:
		_erro("o jogo ficou parado no fim da fila")

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)
