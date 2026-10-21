extends Node2D
## O Antonio na rua (21/10/2026, tutorial): parado no posto de sacos de areia
## da quina noroeste da casa dele, olhando a rua de cima. Nao anda nem fala por
## aqui - a conversa e a caixa de fala (rua/caixa_de_fala.gd), com o retrato.
## O tiro da cena de abertura sai daqui: ele vira para o alvo, o cano clareia e
## a arma soa. Quem decide quando e o roteiro (rua/tutorial.gd).

const Boneco := preload("res://rua/boneco.gd")
const FOLHA := "res://rua/arte/antonio/Antonio_rua-Idle.json"

## Quanto o clarao do cano fica na tela, e onde ele sai: na frente do corpo,
## na altura do peito (px de mundo, com o boneco em escala 0,5).
const CLARAO := 0.15
const ALTURA_DO_CANO := 14.0
const FRENTE_DO_CANO := 9.0

var _boneco: AnimatedSprite2D
var _olhando := Vector2.LEFT
var _clarao := 0.0
var _no_do_clarao: Node2D

func _ready() -> void:
	_boneco = AnimatedSprite2D.new()
	_boneco.set_script(Boneco)
	_boneco.folha = FOLHA
	_boneco.pe = 20.0
	add_child(_boneco)
	# O clarao num filho depois do boneco: o _draw deste no sairia por baixo
	# do desenho dele.
	_no_do_clarao = Node2D.new()
	_no_do_clarao.draw.connect(_desenhar_o_clarao)
	add_child(_no_do_clarao)
	_boneco.mostrar("parado", _olhando)

## Vira para um ponto do mundo, parado.
func olhar_para(ponto: Vector2) -> void:
	var para := ponto - global_position
	if para.length() > 1.0:
		_olhando = para.normalized()
		_boneco.mostrar("parado", _olhando)

## O tiro: vira, clareia o cano e soa. Quem cai e decisao de quem chamou.
func atirar_em(ponto: Vector2) -> void:
	olhar_para(ponto)
	_clarao = CLARAO
	_no_do_clarao.queue_redraw()
	Som.tocar_em("armas/Beretta", global_position, 2000.0, 0.9)

func _process(delta: float) -> void:
	if _clarao > 0.0:
		_clarao = maxf(0.0, _clarao - delta)
		_no_do_clarao.queue_redraw()

func _desenhar_o_clarao() -> void:
	if _clarao <= 0.0:
		return
	var cano := _olhando * FRENTE_DO_CANO + Vector2(0.0, -ALTURA_DO_CANO)
	_no_do_clarao.draw_circle(cano + _olhando * 4.0, 4.5, Color(1.0, 0.86, 0.45, 0.95))
	_no_do_clarao.draw_line(cano, cano + _olhando * 14.0, Color(1.0, 0.96, 0.75, 0.9), 2.0)
