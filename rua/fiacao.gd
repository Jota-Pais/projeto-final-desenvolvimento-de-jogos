extends Node2D
## Os fios dos postes (21/10/2026): de poste em poste ao longo de cada rua, e
## os "gatos" que descem para as casas - a bagunca de fio de rua de bairro.
## Ficam no alto, entao desenham por cima de tudo (`z_index = 1`), como o
## telhado fazia antes de cada casa virar um no do Y-sort.
##
## Os postes estao em rua/detalhes_da_rua.gd; a altura deles, no
## rua/enfeite.gd.

const Mapa := preload("res://rua/mapa.gd")
const DetalhesDaRua := preload("res://rua/detalhes_da_rua.gd")
const Enfeite := preload("res://rua/enfeite.gd")

const COR := Color(0.08, 0.08, 0.08, 0.8)
## Os tres fios de cada vao: a altura de cada um abaixo do topo do poste.
const ALTURAS := [6.0, 12.0, 30.0]
## Quanto o fio cai no meio do vao, por px de vao.
const BARRIGA := 0.06

func _ready() -> void:
	z_index = 1

func _draw() -> void:
	var fileiras := DetalhesDaRua.postes()
	for fileira in fileiras:
		for i in fileira.size() - 1:
			var a: Vector2 = fileira[i]
			var b: Vector2 = fileira[i + 1]
			for k in ALTURAS.size():
				var dx := -22.0 + 22.0 * k if k < 2 else 0.0
				_fio(_topo(a) + Vector2(dx, float(ALTURAS[k])), _topo(b) + Vector2(dx, float(ALTURAS[k])))
	for ligacao in DetalhesDaRua.LIGACOES:
		var fileira: Array = fileiras[ligacao[0]]
		if ligacao[1] >= fileira.size():
			continue
		var casa := Mapa.ponto_do_png(ligacao[2]) + Vector2(0.0, -40.0)
		_fio(_topo(fileira[ligacao[1]]) + Vector2(0.0, 30.0), casa)

func _topo(base: Vector2) -> Vector2:
	return base + Vector2(0.0, -Enfeite.ALTURA_DO_POSTE + 10.0)

## Um fio caido entre dois pontos: a curva de uma corrente, aproximada.
func _fio(a: Vector2, b: Vector2) -> void:
	var pontos := PackedVector2Array()
	var barriga := a.distance_to(b) * BARRIGA
	for k in 13:
		var t := k / 12.0
		pontos.append(a.lerp(b, t) + Vector2(0.0, 4.0 * barriga * t * (1.0 - t)))
	draw_polyline(pontos, COR, 1.0)
