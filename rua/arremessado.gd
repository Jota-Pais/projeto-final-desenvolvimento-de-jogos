extends Node2D
## A pedra ou a garrafa no ar, e o barulho onde ela cai (21/10/2026). Voa num
## arco da mao ate o alvo (rua/mao.gd), e ao cair faz barulho: todo zumbi a ate
## BARULHO px vai ver o que foi (`foi_chamado`, o mesmo do tiro e do zumbi que
## chama o outro) - quem ja esta atras de voce nao larga. A garrafa quebra e
## chama de mais longe; a pedra e mais discreta. Os cacos e a pedra ficam um
## tempo no chao, e o anel do barulho mostra ate onde ele foi.

## Ate onde o barulho chama (px de mundo). **Proposta**.
const BARULHO := { "pedra": 260.0, "garrafa": 420.0 }
## Quanto o barulho se ouve (o som, nao o chamado).
const ALCANCE_DO_SOM := 900.0
const TEMPO_DO_ANEL := 0.7
const TEMPO_NO_CHAO := 25.0

var qual := "pedra"
var _de := Vector2.ZERO
var _ate := Vector2.ZERO
var _duracao := 0.5
var _t := 0.0
var _caiu := false
var _depois := 0.0

func montar(o_que: String, de: Vector2, ate: Vector2) -> void:
	qual = o_que
	_de = de
	_ate = ate
	_duracao = 0.3 + de.distance_to(ate) / 900.0
	position = de
	# No ar, por cima de tudo; no chao, no chao.
	z_index = 2

func _process(delta: float) -> void:
	if _caiu:
		_depois += delta
		if _depois > TEMPO_NO_CHAO:
			queue_free()
		elif _depois < TEMPO_DO_ANEL + 0.1:
			queue_redraw()
		return
	_t += delta
	var f := minf(_t / _duracao, 1.0)
	var altura := (_de.distance_to(_ate) * 0.3 + 16.0) * 4.0 * f * (1.0 - f)
	position = _de.lerp(_ate, f) - Vector2(0.0, altura)
	rotation += delta * 14.0
	queue_redraw()
	if f >= 1.0:
		_cair()

func _cair() -> void:
	_caiu = true
	position = _ate
	rotation = 0.0
	z_index = 0
	Som.tocar_em("arremesso/" + qual, _ate, ALCANCE_DO_SOM, randf_range(0.92, 1.08))
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if (zumbi as Node2D).global_position.distance_to(_ate) <= float(BARULHO[qual]):
			zumbi.foi_chamado(_ate)
	queue_redraw()

func _draw() -> void:
	if not _caiu:
		if qual == "garrafa":
			draw_rect(Rect2(-2, -4, 4, 8), Color("4f7a4a"))
			draw_rect(Rect2(-1, -7, 2, 3), Color("3f6a3a"))
			draw_rect(Rect2(-2, -7, 4, 11), Color(0.07, 0.06, 0.05, 0.9), false, 1.0)
		else:
			draw_circle(Vector2.ZERO, 3.0, Color("8a867e"))
			draw_arc(Vector2.ZERO, 3.0, 0.0, TAU, 8, Color(0.07, 0.06, 0.05, 0.9), 1.0)
		return
	# O anel do barulho, abrindo e sumindo.
	if _depois < TEMPO_DO_ANEL:
		var f := _depois / TEMPO_DO_ANEL
		draw_arc(Vector2.ZERO, float(BARULHO[qual]) * (0.3 + 0.7 * f), 0.0, TAU, 64,
			Color(1.0, 0.92, 0.65, 0.5 * (1.0 - f)), 2.0)
	if qual == "garrafa":
		for k in 7:
			var a := TAU * k / 7.0 + 0.4
			var p := Vector2(cos(a), sin(a) * 0.6) * (4.0 + float(k % 3) * 3.0)
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(3, 1), p + Vector2(1, 3)]), Color(0.45, 0.65, 0.42, 0.9))
	else:
		draw_circle(Vector2.ZERO, 3.0, Color("8a867e"))
		draw_arc(Vector2.ZERO, 3.0, 0.0, TAU, 8, Color(0.07, 0.06, 0.05, 0.9), 1.0)
