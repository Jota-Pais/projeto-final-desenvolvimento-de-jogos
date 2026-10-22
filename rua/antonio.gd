extends Node2D
## O Antonio na rua (21/10/2026, tutorial): parado no posto de sacos de areia
## da quina noroeste da casa dele, olhando a rua de cima. Nao anda nem fala por
## aqui - a conversa e a caixa de fala (rua/caixa_de_fala.gd), com o retrato.
## O tiro da cena de abertura sai daqui: ele vira para o alvo, o cano clareia e
## a arma soa. Quem decide quando e o roteiro (rua/tutorial.gd).
##
## **Mirar e atirar com animacao** (21/10/2026, Joao: "o antonio atirando";
## questionario: "so a da cena"): a folha tem o `atirar` so para noroeste, a
## direcao do tiro da abertura (PixelLab, v3 personalizado, 8 quadros: ele
## levanta a pistola com as duas maos ate mirar). `mirar` toca ele e para no
## ultimo quadro, mirando; `atirar_em` repete o coice (do quadro QUADRO_DO_COICE
## ao fim) com o clarao saindo da boca do cano desenhada. Mirando, ele continua
## de arma apontada mesmo virando para o jogador - e o "por favor, nao me
## mate" do roteiro - ate `baixar_a_arma`. Para outra direcao, a de codigo.

const Boneco := preload("res://rua/boneco.gd")
const FOLHA := "res://rua/arte/antonio/Antonio_rua-Idle.json"

## Quanto o clarao do cano fica na tela, e onde ele sai: na frente do corpo,
## na altura do peito (px de mundo, com o boneco em escala 0,5).
const CLARAO := 0.15
const ALTURA_DO_CANO := 14.0
const FRENTE_DO_CANO := 9.0
## Na pose de mira para noroeste (o ultimo quadro do `atirar`), a boca do cano
## desenhada, em px de mundo a partir do pe dele (medida na folha).
const CANO_MIRANDO_NOROESTE := Vector2(-15.5, -19.5)
## O quadro do `atirar` em que a pistola ja esta erguida: o coice do tiro
## repete dele ate o fim.
const QUADRO_DO_COICE := 3

var _boneco: AnimatedSprite2D
var _olhando := Vector2.LEFT
var _clarao := 0.0
var _no_do_clarao: Node2D
## Esta com a arma erguida (o `atirar` da folha, parado no ultimo quadro).
var _mirando := false

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

## Vira para um ponto do mundo, parado. Mirando, so guarda a direcao: a arma
## continua erguida.
func olhar_para(ponto: Vector2) -> void:
	var para := ponto - global_position
	if para.length() > 1.0:
		_olhando = para.normalized()
		if not _mirando:
			_boneco.mostrar("parado", _olhando)

## Ergue a arma para `ponto`, se a folha tem o `atirar` naquela direcao.
func mirar(ponto: Vector2) -> void:
	var para := ponto - global_position
	if para.length() > 1.0:
		_olhando = para.normalized()
	if _boneco.tocar("atirar", _direcao_da_mira()):
		_mirando = true

## A direcao em que a folha tem o `atirar`: a do alvo, ou noroeste quando o
## alvo esta para aquele quadrante (a unica que a folha tem hoje) - o zumbi
## da abertura corre de oeste para norte dele.
func _direcao_da_mira() -> Vector2:
	if _boneco.sprite_frames != null and _boneco.sprite_frames.has_animation("atirar_%s" % Boneco.setor(_olhando)):
		return _olhando
	if _olhando.x < 0.0 and _olhando.y < 0.0:
		return Vector2(-1.0, -1.0)
	return _olhando

func baixar_a_arma() -> void:
	_mirando = false
	_boneco.mostrar("parado", _olhando)

## O tiro: mira (se ainda nao), o coice, o clarao e o som. Quem cai e decisao
## de quem chamou.
func atirar_em(ponto: Vector2) -> void:
	if not _mirando:
		mirar(ponto)
	if _mirando and _boneco.tocar("atirar", _direcao_da_mira()):
		_boneco.set_frame_and_progress(QUADRO_DO_COICE, 0.0)
	else:
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
	var para := _olhando
	if _mirando:
		cano = CANO_MIRANDO_NOROESTE
		para = Vector2(-1.0, -0.35).normalized()
	_no_do_clarao.draw_circle(cano + para * 4.0, 4.5, Color(1.0, 0.86, 0.45, 0.95))
	_no_do_clarao.draw_line(cano, cano + para * 14.0, Color(1.0, 0.96, 0.75, 0.9), 2.0)
