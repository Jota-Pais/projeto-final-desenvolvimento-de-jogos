extends Node2D
## A pistola. **Ela existe para comprar tempo para o vasculho**, e nao para
## virar um jogo de tiro.
##
## Tres regras a mantem dentro da core mechanic em vez de competindo com ela:
##
##  1. **voce nao comeca com ela.** A pistola esta na armaria da delegacia - o
##     quarto mais fundo do lugar mais povoado do mapa. Achar a arma e
##     recompensa de vasculhar;
##  2. **a municao vem do vasculho.** Sai da armaria, das caixas e das comodas,
##     e nao ha outra fonte. Atirar gasta o que voce vasculhou;
##  3. **o tiro chama a horda**, e num raio muito maior que o chamado de um
##     zumbi que enxergou voce (1.800 contra 700 px). O tiro resolve um problema
##     e cria um maior - e a regra do PZ, e e o que faz a arma continuar sendo
##     pressao sobre a mesma acao.
##
## Ela mata de um tiro. Nao existe estado de ferido: o recurso caro e a
## municao, e um zumbi que aguenta tres tiros so multiplicaria o estrondo.
##
## O High Concept declara que "o jogador luta ou esquiva dos zumbis" - esta e a
## parte da luta. A esquiva nao e mecanica: e andar evitando, que sempre deu
## para fazer porque o zumbi e mais lento que voce.

## Ate onde o tiro alcanca. Parede corta, porque e raycast: atirar de dentro de
## casa nao acerta quem esta na rua.
const ALCANCE := 900.0

## Em que raio o estrondo e ouvido. **E o custo do tiro**, e e de proposito
## maior que o mundo que voce ve: voce nao sabe quem escutou.
const ALCANCE_DO_ESTRONDO := 1800.0

## Segundos entre dois tiros.
const ESPERA := 0.45

## Quanto tempo o cano fica aceso na tela depois do tiro.
const CLARAO := 0.09

const COR_DA_MIRA := Color(0.85, 0.35, 0.3, 0.22)
const COR_DO_CLARAO := Color(1.0, 0.92, 0.62, 0.85)

var _espera := 0.0
var _clarao := 0.0
var _mira := Vector2.RIGHT

func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	if _clarao > 0.0:
		_clarao = maxf(0.0, _clarao - delta)
		queue_redraw()

	if not Travessia.tem_pistola:
		return

	var para_o_mouse := get_global_mouse_position() - global_position
	if para_o_mouse.length() > 1.0:
		_mira = para_o_mouse.normalized()
	queue_redraw()

	if Input.is_action_pressed("atirar") and _espera <= 0.0 and Travessia.municao > 0:
		_atirar()

func _atirar() -> void:
	# A guarda mora aqui, e nao so no _process: a ferramenta de conferencia
	# chama isto direto, e sem a guarda a municao ia para negativo. Regra que
	# vive so em quem chama e regra que um chamador novo esquece.
	if not Travessia.tem_pistola or Travessia.municao <= 0:
		return

	_espera = ESPERA
	_clarao = CLARAO
	Travessia.municao -= 1

	var de := global_position
	var ate := de + _mira * ALCANCE
	var consulta := PhysicsRayQueryParameters2D.create(de, ate)
	# So o jogador sai da conta. Parede, movel e zumbi entram - e o primeiro
	# que aparecer e o que leva.
	var jogador := get_parent() as CollisionObject2D
	if jogador != null:
		consulta.exclude = [jogador.get_rid()]

	var batida := get_world_2d().direct_space_state.intersect_ray(consulta)
	if not batida.is_empty() and (batida["collider"] as Node).is_in_group("zumbi"):
		(batida["collider"] as Node).levar_tiro()

	# O estrondo sai de qualquer jeito, acertando ou nao. Errar o tiro e o pior
	# resultado possivel: gastou municao e chamou todo mundo.
	_o_estrondo_chama()

func _o_estrondo_chama() -> void:
	# A pistola conhece o grupo "zumbi" de proposito: o trabalho dela e sobre
	# eles. O que ela NAO faz e saber onde eles estao - ela grita, e quem estiver
	# perto vem, pelo mesmo `foi_chamado` que um zumbi usa para chamar outro.
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if global_position.distance_to((zumbi as Node2D).global_position) > ALCANCE_DO_ESTRONDO:
			continue
		zumbi.foi_chamado(global_position)

## A linha de mira e o clarao do cano. **Auxilio de prototipo**, como o cone de
## visao do zumbi: sem ver para onde a arma aponta nao da para entender por que
## o tiro pegou na parede.
func _draw() -> void:
	if not Travessia.tem_pistola:
		return
	if Travessia.municao > 0:
		draw_line(Vector2.ZERO, _mira * ALCANCE, COR_DA_MIRA, 2.0)
	if _clarao > 0.0:
		draw_circle(_mira * 26.0, 9.0, COR_DO_CLARAO)
