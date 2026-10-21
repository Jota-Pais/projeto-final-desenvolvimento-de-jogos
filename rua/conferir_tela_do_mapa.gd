extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no mapa do M ou no que
## conta como visto.**
##
## Confere o que o Joao decidiu em 21/10/2026 (rua/tela_do_mapa.gd,
## rua/mapa_visto.gd):
##
##  1. o que passa na tela fica visto, e o longe nao;
##  2. andar descobre o caminho;
##  3. o M abre e fecha o mapa, e o mapa aberto nao para o jogo;
##  4. sob roteiro (a cena de abertura) o mapa nao abre;
##  5. o visto atravessa a cena e a partida nova esquece.

const CENA_DA_RUA := preload("res://rua/rua.tscn")
const MapaVisto := preload("res://rua/mapa_visto.gd")
const TelaDoMapa := preload("res://rua/tela_do_mapa.gd")

var _rua: Node
var _falhas := 0

func _ready() -> void:
	Travessia.tutorial = ""
	Travessia.mapa_visto = PackedByteArray()
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	await get_tree().process_frame
	await get_tree().process_frame
	await _conferir()

## O resultado e a saida. A partida nova (o ultimo passo) troca de cena e tira
## esta da arvore na hora: a arvore vem guardada de antes.
func _terminar(arvore: SceneTree) -> void:
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	Travessia.mapa_visto = PackedByteArray()
	arvore.quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Aperta e solta o M (a acao "mapa"), um quadro cada.
func _apertar_o_m() -> void:
	var evento := InputEventAction.new()
	evento.action = "mapa"
	evento.pressed = true
	Input.parse_input_event(evento)
	await get_tree().process_frame
	var solto := InputEventAction.new()
	solto.action = "mapa"
	solto.pressed = false
	Input.parse_input_event(solto)
	await get_tree().process_frame

func _conferir() -> void:
	var jogador := _rua.get_node("Jogador") as Node2D
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		zumbi.queue_free()
	await get_tree().process_frame

	print("1. o que passa na tela")
	var onde := jogador.global_position
	if not MapaVisto.visto(onde):
		_erro("o lugar do jogador nao ficou visto")
	var longe := onde + Vector2(3000.0, 0.0) if onde.x < 15000.0 else onde - Vector2(3000.0, 0.0)
	if MapaVisto.visto(longe):
		_erro("um ponto a 3000 px ja esta visto sem ninguem ter passado")
	print("  %d celulas vistas ao abrir a rua" % MapaVisto.quantas_vistas())

	print("2. andar descobre")
	var antes := MapaVisto.quantas_vistas()
	for passo in 20:
		jogador.global_position = onde.lerp(longe, (passo + 1) / 20.0)
		await get_tree().process_frame
	if not MapaVisto.visto(longe):
		_erro("andou ate o ponto longe e ele nao ficou visto")
	if MapaVisto.quantas_vistas() <= antes:
		_erro("andar nao descobriu nada")
	else:
		print("  de %d para %d celulas" % [antes, MapaVisto.quantas_vistas()])

	print("3. o M")
	var minutos_antes: float = Travessia.minutos if "minutos" in Travessia else 0.0
	await _apertar_o_m()
	if not TelaDoMapa.aberto:
		_erro("o M nao abriu o mapa")
	await get_tree().create_timer(0.3).timeout
	if get_tree().paused:
		_erro("o mapa aberto parou o jogo")
	await _apertar_o_m()
	if TelaDoMapa.aberto:
		_erro("o M de novo nao fechou o mapa")
	else:
		print("  abre e fecha; o jogo segue (pausado: %s)" % get_tree().paused)

	print("4. sob roteiro")
	jogador.no_roteiro = true
	await _apertar_o_m()
	if TelaDoMapa.aberto:
		_erro("o mapa abriu na cena de roteiro")
	jogador.no_roteiro = false

	print("5. atravessa e esquece")
	var guardado := MapaVisto.quantas_vistas()
	_rua.queue_free()
	await get_tree().process_frame
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	await get_tree().process_frame
	await get_tree().process_frame
	if MapaVisto.quantas_vistas() < guardado:
		_erro("a rua nova (o dia seguinte) esqueceu o que ja se tinha visto")
	var arvore := get_tree()
	Travessia.recomecar()
	if not Travessia.mapa_visto.is_empty():
		_erro("a partida nova lembrou o mapa da anterior")
	else:
		print("  o dia seguinte lembra; a partida nova esquece")
	_terminar(arvore)
