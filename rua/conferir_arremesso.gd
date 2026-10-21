extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na mao, no arremesso, no
## barulho dos passos ou no que o vasculho rende.**
##
## Confere o que o Joao decidiu em 21/10/2026:
##
##  1. o scroll passa pelo que da para ter na mao (a arma, a pedra, a garrafa)
##     e pula o que acabou;
##  2. o arremesso gasta o que foi jogado, e onde cai chama o zumbi perto - e
##     so ele, o de longe nao ouve;
##  3. o passo chama: correndo de mais longe, andando so colado, agachado nunca;
##  4. o monte de pedras do chao rende pedra, que vai para a mao.

const CENA_DA_RUA := preload("res://rua/rua.tscn")
const Jogador := preload("res://rua/jogador.gd")
const Arremessado := preload("res://rua/arremessado.gd")

var _rua: Node
var _falhas := 0

func _ready() -> void:
	Travessia.tutorial = ""
	Travessia.armado = true
	Travessia.na_mao = "arma"
	Travessia.arremessaveis = { "pedra": 0, "garrafa": 0 }
	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	await get_tree().process_frame
	await get_tree().process_frame
	await _conferir()
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	Travessia.arremessaveis = { "pedra": 0, "garrafa": 0 }
	Travessia.na_mao = "arma"
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Um zumbi novo, parado, longe de todo mundo, num ponto livre perto do
## jogador.
func _zumbi_em(onde: Vector2) -> Node2D:
	var zumbi: Node2D = _rua.get_node("Cenario")._criar_zumbi(onde)
	zumbi.set_physics_process(false)
	zumbi._estado = zumbi.Estado.VAGANDO
	zumbi._ultima_posicao = Vector2.ZERO
	return zumbi

func _conferir() -> void:
	var jogador := _rua.get_node("Jogador") as Node2D
	var mao := jogador.get_node("Mao")
	# Longe de casa e de zumbi nenhum: os zumbis do mapa saem do caminho.
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		zumbi.queue_free()
	await get_tree().process_frame

	print("1. o scroll")
	Travessia.guardar_arremessavel("pedra", 2)
	Travessia.passar_a_mao(1)
	if Travessia.na_mao != "pedra":
		_erro("da arma, o scroll devia ir para a pedra (foi para '%s')" % Travessia.na_mao)
	Travessia.passar_a_mao(1)
	if Travessia.na_mao != "arma":
		_erro("sem garrafa, o scroll devia voltar para a arma (foi para '%s')" % Travessia.na_mao)
	print("  arma -> pedra -> arma (sem garrafa no meio)")

	print("\n2. o arremesso")
	Travessia.na_mao = "pedra"
	var de := jogador.global_position
	var alvo := de + Vector2(200.0, 0.0)
	var perto := _zumbi_em(alvo + Vector2(Arremessado.BARULHO["pedra"] * 0.6, 0.0))
	var longe := _zumbi_em(alvo + Vector2(0.0, Arremessado.BARULHO["pedra"] * 1.6))
	mao.arremessar("pedra", alvo)
	if int(Travessia.arremessaveis["pedra"]) != 1:
		_erro("jogar uma pedra devia deixar 1 (ficaram %d)" % Travessia.arremessaveis["pedra"])
	var fim := Time.get_ticks_msec() + 3000
	while perto._ultima_posicao == Vector2.ZERO and Time.get_ticks_msec() < fim:
		await get_tree().process_frame
	if perto._ultima_posicao == Vector2.ZERO:
		_erro("a pedra caiu a %.0f px do zumbi e ele nao ouviu" % (Arremessado.BARULHO["pedra"] * 0.6))
	elif perto._ultima_posicao.distance_to(alvo) > 20.0:
		_erro("o zumbi foi chamado para %s, e nao para onde a pedra caiu (%s)" % [perto._ultima_posicao, alvo])
	else:
		print("  a pedra caiu e o zumbi a %.0f px foi ver" % (Arremessado.BARULHO["pedra"] * 0.6))
	if longe._ultima_posicao != Vector2.ZERO:
		_erro("o zumbi longe do barulho tambem foi chamado")
	mao.arremessar("pedra", alvo)
	if Travessia.na_mao != "arma":
		_erro("sem pedra, a mao devia voltar para a arma (esta em '%s')" % Travessia.na_mao)
	perto.queue_free()
	longe.queue_free()
	await get_tree().process_frame

	print("\n3. o barulho dos passos")
	var casos := [
		["andando colado", false, false, Jogador.RAIO_ANDANDO * 0.7, true],
		["andando a 3 m", false, false, 120.0, false],
		["correndo a 3 m", true, false, 120.0, true],
		["agachado colado", false, true, Jogador.RAIO_ANDANDO * 0.7, false],
	]
	for caso in casos:
		var zumbi := _zumbi_em(jogador.global_position + Vector2(float(caso[3]), 0.0))
		jogador.agachar(caso[2])
		jogador._barulho = 0.0
		jogador._fazer_barulho(Vector2.RIGHT, caso[1], 0.1)
		var chamou: bool = zumbi._ultima_posicao != Vector2.ZERO
		if chamou != caso[4]:
			_erro("%s: o zumbi %s" % [caso[0], "foi chamado e nao devia" if chamou else "nao ouviu e devia"])
		else:
			print("  %-16s %s" % [caso[0], "chama" if chamou else "silencio"])
		zumbi.queue_free()
		await get_tree().process_frame
	jogador.agachar(false)

	print("\n4. o monte de pedras")
	var monte: Node = null
	for filho in _rua.get_node("Cenario").get_children():
		if filho is Area2D and filho.get("rotulo") == "Pedras":
			monte = filho
			break
	if monte == null:
		_erro("nao ha monte de pedras no mapa")
		return
	var antes := int(Travessia.arremessaveis["pedra"])
	monte._esvaziar()
	var depois := int(Travessia.arremessaveis["pedra"])
	if depois <= antes:
		_erro("vasculhar o monte de pedras nao deu pedra (%d -> %d)" % [antes, depois])
	else:
		print("  o monte deu %d pedras" % (depois - antes))
