extends Node2D
## Os telhados, desenhados por cima de tudo - e o que faz cada construcao ser
## opaca de fora. O telhado da construcao onde o jogador esta **sai**, e a
## planta, os moveis e o que tem dentro aparecem.
##
## E o truque do Project Zomboid: entrar numa casa e descobrir o que tem
## dentro, nao ler de fora e escolher. Sem isso, o mapa inteiro se le da rua e
## vasculhar deixa de ser exploracao.
##
## Precisa ser um no separado, e o ULTIMO irmao que desenha no mundo: o Godot
## desenha na ordem da arvore, e o telhado tem que vir depois do cenario, dos
## moveis e do jogador.
##
## A HUD vem depois dele no rua.tscn e nao atrapalha - ela e CanvasLayer, tem
## camada propria e nao entra nessa ordem.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")

const COR_TELHADO := Color("2a2e31")
const COR_TELHADO_SEU := Color("3a2f26")
const COR_BEIRAL := Color(0.0, 0.0, 0.0, 0.45)
const COR_AGUA := Color(0.0, 0.0, 0.0, 0.10)
const COR_DA_PORTA := Color("6b5b3f")
const COR_DA_PORTA_SUA := Color("8a5a2b")

var _dentro_de := -1

## Ja no _ready, e nao so no _process: o jogador nasce DENTRO da sua casa, e
## esperar o primeiro _process fazia o telhado dela piscar por um quadro.
func _ready() -> void:
	_conferir()

func _process(_delta: float) -> void:
	_conferir()

func _conferir() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var onde := Mapa.construcao_em(jogador.global_position)
	if onde == _dentro_de:
		return
	_dentro_de = onde
	queue_redraw()

func _draw() -> void:
	for i in Mapa.mundo()["construcoes"].size():
		if i == _dentro_de:
			continue
		_desenhar(Mapa.mundo()["construcoes"][i])

func _desenhar(construcao: Dictionary) -> void:
	var r: Rect2 = construcao["rect"]
	var sua: bool = construcao.get("sua", false)
	draw_rect(r, COR_TELHADO_SEU if sua else COR_TELHADO)

	# Duas aguas, so para o telhado nao ser um retangulo chapado e dar para
	# distinguir uma construcao da outra de longe.
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y / 2.0), COR_AGUA)
	draw_line(r.position, Vector2(r.end.x, r.position.y + r.size.y / 2.0), COR_BEIRAL, 2.0)
	draw_rect(r, COR_BEIRAL, false, 3.0)

	# A marca da porta fica POR CIMA do telhado: de fora nao se ve nada da
	# planta, mas tem que dar para achar por onde entrar.
	var porta := Construcao.porta_de(construcao)
	var marca := Rect2(porta.x - Construcao.VAO / 2.0, porta.y - 7.0, Construcao.VAO, 14.0)
	draw_rect(marca, COR_DA_PORTA_SUA if sua else COR_DA_PORTA)

	if sua:
		var fonte := ThemeDB.fallback_font
		draw_string(fonte, Vector2(r.position.x + 10.0, r.get_center().y), "sua casa",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.82, 0.6, 0.55))
