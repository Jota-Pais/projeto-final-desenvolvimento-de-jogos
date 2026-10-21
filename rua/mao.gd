extends Node2D
## A mao (21/10/2026, Joao: "ele poderia usar o scroll pra ver o que tem na
## mao, armas, pedras, equipamentos medicos e etc, e com o botao esquerdo ele
## usa"). O scroll passa de uma coisa para a outra (Travessia.na_mao); a arma
## atira (rua/arma.gd), e a pedra e a garrafa se arremessam: **segurar o botao
## aumenta a distancia ate o limite, e dali em diante segurar e so mira**;
## soltar joga. Onde cai faz barulho, e o zumbi que ouve vai ver
## (rua/arremessado.gd) - e o jeito de tirar um da frente sem tiro.
##
## Filho do jogador (rua/jogador.gd cria): a mira e desenhada daqui, por cima
## de tudo.

const Arremessado := preload("res://rua/arremessado.gd")
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")
const Camadas := preload("res://rua/camadas.gd")
const TelaDoMapa := preload("res://rua/tela_do_mapa.gd")

## O arremesso jogou `qual` para `onde` (o tutorial escuta).
signal arremessou(qual: String, onde: Vector2)

## Quanto o arremesso cresce por segundo de botao segurado, de onde comeca e
## ate onde vai. **Proposta** (40 px = 1 m: a pedra vai a 9 m, a garrafa,
## mais pesada, a 7,5).
const CARGA_POR_SEGUNDO := 400.0
const MINIMO := 40.0
const ALCANCE := { "pedra": 360.0, "garrafa": 300.0 }
## A espera entre um arremesso e outro.
const ESPERA := 0.5
## De onde sai: a mao, na altura do peito do boneco.
const DA_MAO := Vector2(0.0, -12.0)
const COR_DA_MIRA := Color(0.95, 0.88, 0.6, 0.85)

var _carga := 0.0
var _carregando := false
var _espera := 0.0
var _jogador: Node2D

func _ready() -> void:
	_jogador = get_parent() as Node2D
	# A mira por cima de tudo, ate dos telhados.
	z_index = 3

## Se ele esta mirando um arremesso - o jogador olha para o mouse enquanto isso.
func mirando() -> bool:
	return _carregando

func _unhandled_input(evento: InputEvent) -> void:
	var botao := evento as InputEventMouseButton
	if botao == null or not botao.pressed:
		return
	if botao.button_index != MOUSE_BUTTON_WHEEL_UP and botao.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return
	# Com o mapa aberto o scroll aproxima o mapa (rua/tela_do_mapa.gd).
	if TelaDaMochila.aberta or _jogador.get("no_roteiro") or TelaDoMapa.aberto:
		return
	Travessia.passar_a_mao(-1 if botao.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	_carregando = false
	queue_redraw()
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	Travessia.conferir_a_mao()
	var qual := Travessia.na_mao
	if not qual in Travessia.ARREMESSAVEIS or TelaDaMochila.aberta or _jogador.get("no_roteiro"):
		if _carregando:
			_carregando = false
			queue_redraw()
		return
	if Input.is_action_pressed("atirar") and _espera <= 0.0:
		if not _carregando:
			_carregando = true
			_carga = MINIMO
		_carga = minf(_carga + CARGA_POR_SEGUNDO * delta, float(ALCANCE[qual]))
		queue_redraw()
	elif _carregando:
		_carregando = false
		queue_redraw()
		arremessar(qual, _alvo())

## Onde cai, mirando no mouse: a direcao e a do cursor, a distancia e a carga.
func _alvo() -> Vector2:
	var para := get_global_mouse_position() - _jogador.global_position
	var direcao := para.normalized() if para.length() > 1.0 else Vector2.DOWN
	return _jogador.global_position + direcao * _carga

## Joga `qual` em `ate` (mundo). Parede no caminho segura: a coisa cai no pe
## dela, do lado de ca. Publico para as ferramentas de conferencia.
func arremessar(qual: String, ate: Vector2) -> void:
	if int(Travessia.arremessaveis.get(qual, 0)) <= 0:
		return
	var de := _jogador.global_position
	var consulta := PhysicsRayQueryParameters2D.create(de, ate, Camadas.SOLIDO)
	consulta.exclude = [(_jogador as CollisionObject2D).get_rid()]
	var batida := get_world_2d().direct_space_state.intersect_ray(consulta)
	if not batida.is_empty():
		ate = (batida["position"] as Vector2) - (ate - de).normalized() * 8.0
	Travessia.arremessaveis[qual] = int(Travessia.arremessaveis[qual]) - 1
	_espera = ESPERA
	var coisa := Arremessado.new()
	coisa.montar(qual, de + DA_MAO, ate)
	_jogador.get_parent().add_child(coisa)
	Som.tocar("arremesso/arremessar", randf_range(0.9, 1.1), 2)
	arremessou.emit(qual, ate)
	Travessia.conferir_a_mao()

## A mira: o arco pontilhado da mao ate onde cai, o alvo e, em volta dele, ate
## onde o barulho chama - e o que o jogador precisa ver para tirar o zumbi do
## lugar certo.
func _draw() -> void:
	if not _carregando:
		return
	var alvo := to_local(_alvo())
	var altura := clampf(alvo.length() * 0.3, 16.0, 80.0)
	var pontos := PackedVector2Array()
	for k in 17:
		var t := k / 16.0
		pontos.append(DA_MAO.lerp(alvo, t) - Vector2(0.0, 4.0 * altura * t * (1.0 - t)))
	for k in range(0, pontos.size() - 1, 2):
		draw_line(pontos[k], pontos[k + 1], COR_DA_MIRA, 1.5)
	var cheio := is_equal_approx(_carga, float(ALCANCE[Travessia.na_mao]))
	draw_arc(alvo, 7.0, 0.0, TAU, 16, COR_DA_MIRA if cheio else COR_DA_MIRA * Color(1, 1, 1, 0.6), 1.5)
	draw_line(alvo - Vector2(4, 0), alvo + Vector2(4, 0), COR_DA_MIRA, 1.0)
	draw_line(alvo - Vector2(0, 4), alvo + Vector2(0, 4), COR_DA_MIRA, 1.0)
	var raio: float = Arremessado.BARULHO[Travessia.na_mao]
	draw_arc(alvo, raio, 0.0, TAU, 64, Color(0.95, 0.88, 0.6, 0.22), 1.0)
