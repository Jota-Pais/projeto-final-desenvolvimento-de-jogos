extends Node2D
## As maos que seguram o que esta na mao (21/10/2026, Joao: "faz as animacoes
## de segurando e usando cada arma, animacao do tiro e coisas assim";
## questionario: "Por codigo agora").
##
## O boneco do PixelLab tem os bracos caidos do lado do corpo em toda a folha,
## e um braco desenhado por cima, do quadril ate a arma no peito, sai um
## bastao - e um par de punhos na arma sem tirar as maos desenhadas da quatro
## maos na tela, o defeito que o Joao achou no morto do zumbi ("ficando com 3
## bracos"). Entao **a arma vai na mao que o desenho ja tem**: porte baixo, na
## altura do quadril, apontada para onde ele olha, e balancando com o braco
## quando ele anda. Onde a mao esta em cada quadro da folha vem de
## rua/arte/jogador/maos.json (design/achar_as_maos.js); no quadro em que ela
## some atras do corpo, vale a da rotacao parada.
##
## A mao da arma e a direita de quem olha (de lado, a que aparece). A curta vai
## numa mao so; a longa, com a outra mao no guarda-mao **so quando a outra mao
## nao aparece no desenho** (de lado, atras do corpo) - de frente as duas maos
## estao na folha, e um terceiro punho no guarda-mao seria a mao sobrando. O
## punho e desenhado por cima da arma (o no `Punhos`, filho dela); olhando para
## longe da camera a arma passa para tras do corpo (rua/jogador.gd) e a mao do
## desenho fica na frente dela.
##
## A pedra e a garrafa ficam na mao. Mirando o arremesso, a mao sobe para tras
## do ombro com ela (a mao desenhada some debaixo da manga) e, ao soltar, passa
## para a frente e volta.
##
## Filho do boneco: herda a escala, o agachar e o passo do recuo do tiro, e
## desenha logo depois dele. Coordenadas em px do desenho, como as do boneco.

const MAOS := "res://rua/arte/jogador/maos.json"

## As cores, tiradas da folha do jogador: o contorno, a manga do casaco e a
## pele da mao.
const CONTORNO := Color("050403")
const MANGA := Color("2d3946")
const PELE := Color("d09781")
const PELE_CLARA := Color("e6b9a1")
const PEDRA := Color("8a8478")
const PEDRA_CLARA := Color("b3ada0")
const GARRAFA := Color("3f6b3a")
const GARRAFA_CLARA := Color("6f9a5f")

## O meio do peito e a altura do ombro, em px do desenho a partir da origem do
## boneco (o pe esta em +20, o alto do capuz em -52).
const PEITO := Vector2(0.0, -14.0)
const OMBRO := Vector2(0.0, -24.0)
## O guarda-mao das armas longas: que fracao do cano, a partir do cabo.
const GUARDA_MAO := 0.55
## Quanto a mao leva para passar para a frente ao soltar o arremesso.
const BALANCO := 0.2

static var _tabela := {}

var _jogador: Node2D
var _boneco: AnimatedSprite2D
var _arma: Node2D
var _desenho: Sprite2D
var _mao: Node2D
var _punhos: Node2D
var _celula := Vector2(116.0, 116.0)
## As maos do quadro de agora (ver _maos_do_quadro), refeitas a cada quadro.
var _maos: Array[Vector2] = []
var _desenhadas := true
## Contagem regressiva do balanco do arremesso, e de onde a mao saiu.
var _balanco := 0.0
var _saiu_de := Vector2.ZERO

## Chamado pelo jogador (rua/jogador.gd), que cria este no dentro do boneco.
func montar(jogador: Node2D, boneco: AnimatedSprite2D, arma: Node2D, mao: Node2D) -> void:
	_jogador = jogador
	_boneco = boneco
	_arma = arma
	_desenho = arma.get_node("Desenho") as Sprite2D
	_mao = mao
	_mao.arremessou.connect(_ao_arremessar)
	_punhos = Node2D.new()
	_punhos.name = "Punhos"
	_arma.add_child(_punhos)
	_punhos.draw.connect(_desenhar_os_punhos)
	if _tabela.is_empty() and FileAccess.file_exists(MAOS):
		var lido = JSON.parse_string(FileAccess.get_file_as_string(MAOS))
		if lido is Dictionary:
			_tabela = lido
	if _tabela.has("celula"):
		_celula = Vector2(float(_tabela["celula"][0]), float(_tabela["celula"][1]))

func _process(delta: float) -> void:
	_balanco = maxf(0.0, _balanco - delta)
	if _boneco == null:
		return
	_ler_as_maos()
	# A arma na mao da arma: o jogador a aponta no proximo quadro de fisica.
	if not _maos.is_empty():
		var mao := _mao_direita(_jogador.para_onde_olha())
		_arma.mao_na_folha = _arma.get_global_transform().affine_inverse() * (get_global_transform() * mao)
	queue_redraw()
	_punhos.queue_redraw()

func _ao_arremessar(_qual: String, _onde: Vector2) -> void:
	_balanco = BALANCO
	_saiu_de = _atras_do_ombro(_jogador.para_onde_olha())

func _com_a_arma() -> bool:
	return Travessia.armado and Travessia.na_mao == "arma" and _arma.visible

## As maos do quadro que o boneco mostra agora, em px do desenho, e se elas
## estao desenhadas na folha ou e a da rotacao parada (atras do corpo).
func _ler_as_maos() -> void:
	var tabela: Dictionary = _tabela.get("maos", {})
	var nome := String(_boneco.animation)
	var quadros: Array = tabela.get(nome, [])
	var lista: Array = quadros[_boneco.frame] if _boneco.frame < quadros.size() else []
	_desenhadas = not lista.is_empty()
	if lista.is_empty():
		var parado: Array = tabela.get("parado_" + nome.substr(nome.rfind("_") + 1), [[]])
		lista = parado[0]
	_maos.clear()
	for m in lista:
		var p := Vector2(float(m[0]), float(m[1])) - _celula / 2.0 + _boneco.offset
		if _boneco.flip_h:
			p.x = -p.x
		_maos.append(p)

## A mao direita de quem olha para `olhando` (y para baixo: a direita de quem
## olha para o sul fica a esquerda da tela). De lado so uma mao aparece, e e
## ela.
func _mao_direita(olhando: Vector2) -> Vector2:
	var direita := olhando.rotated(PI / 2.0)
	var melhor := _maos[0]
	for m in _maos:
		if (m - PEITO).dot(direita) > (melhor - PEITO).dot(direita):
			melhor = m
	return melhor

# --- a arma ---------------------------------------------------------------------

func _desenhar_os_punhos() -> void:
	if _boneco == null or not _com_a_arma():
		return
	var ficha: Dictionary = _arma.ficha()
	var cabo := _punhos.get_global_transform().affine_inverse() * _desenho.global_position
	_punho(_punhos, cabo)
	# A outra mao no guarda-mao, so se ela nao aparece no desenho.
	if ficha["classe"] != "curta" and _maos.size() < 2:
		var p := _desenho.get_global_transform() * Vector2(float(ficha["cano"]) * GUARDA_MAO, 0.0)
		_punho(_punhos, _punhos.get_global_transform().affine_inverse() * p)

# --- o arremesso ---------------------------------------------------------------

func _ombro_direito(olhando: Vector2) -> Vector2:
	var direita := olhando.rotated(PI / 2.0)
	return OMBRO + Vector2(direita.x * 8.0, direita.y * 4.0)

## A mao erguida para jogar: para fora do ombro, acima e um pouco para tras -
## de frente, ao lado do capuz (em cima dele, escuro no escuro, nao se ve).
func _atras_do_ombro(olhando: Vector2) -> Vector2:
	var direita := olhando.rotated(PI / 2.0)
	return OMBRO + Vector2(direita.x * 15.0, direita.y * 6.0) - Vector2(olhando.x * 7.0, olhando.y * 3.5) + Vector2(0.0, -6.0)

func _draw() -> void:
	if _boneco == null or _maos.is_empty() or _com_a_arma():
		return
	var qual := Travessia.na_mao if Travessia.na_mao in Travessia.ARREMESSAVEIS else ""
	var olhando: Vector2 = _jogador.para_onde_olha()
	var mao := _mao_direita(olhando)
	var ombro := _ombro_direito(olhando)
	if _balanco > 0.0:
		# Soltou: a mao vai de tras do ombro para a frente e volta para baixo.
		var frente := ombro + Vector2(olhando.x * 12.0, olhando.y * 6.0)
		var s := 1.0 - _balanco / BALANCO
		var onde := _saiu_de.lerp(frente, s * 2.0) if s < 0.5 else frente.lerp(mao, (s - 0.5) * 2.0)
		_braco_erguido(mao, ombro, onde)
		return
	if qual == "":
		return
	if _mao.mirando():
		var atras := _atras_do_ombro(olhando)
		_braco_erguido(mao, ombro, atras)
		_coisa(qual, atras + Vector2(0.0, -2.0))
		_punho(self, atras)
		return
	# Parado com ela na mao.
	_coisa(qual, mao + Vector2(0.0, 1.0))

# --- o desenho -------------------------------------------------------------------

## A mao fora do lugar: a mao desenhada some debaixo da manga, e um braco curto
## vai do ombro ate `onde`, com o punho na ponta.
func _braco_erguido(mao_da_folha: Vector2, ombro: Vector2, onde: Vector2) -> void:
	if _desenhadas:
		var c := mao_da_folha.round()
		draw_rect(Rect2(c - Vector2(2.0, 2.0), Vector2(5.0, 4.0)), MANGA)
	var a := ombro.round()
	var b := onde.round()
	var passos := maxi(1, int(a.distance_to(b)))
	for k in passos + 1:
		draw_rect(Rect2(a.lerp(b, float(k) / passos).round() - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), CONTORNO)
	for k in passos + 1:
		draw_rect(Rect2(a.lerp(b, float(k) / passos).round() - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), MANGA)
	_punho(self, onde)

func _punho(no: CanvasItem, p: Vector2) -> void:
	var c := p.round()
	no.draw_rect(Rect2(c - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), CONTORNO)
	no.draw_rect(Rect2(c - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), PELE)
	no.draw_rect(Rect2(c - Vector2(1.0, 1.0), Vector2(1.0, 1.0)), PELE_CLARA)

## A pedra ou a garrafa na mao, em `p`.
func _coisa(qual: String, p: Vector2) -> void:
	var c := p.round()
	if qual == "pedra":
		draw_rect(Rect2(c + Vector2(-2.0, -1.0), Vector2(5.0, 4.0)), CONTORNO)
		draw_rect(Rect2(c + Vector2(-1.0, 0.0), Vector2(3.0, 2.0)), PEDRA)
		draw_rect(Rect2(c + Vector2(-1.0, 0.0), Vector2(1.0, 1.0)), PEDRA_CLARA)
	elif qual == "garrafa":
		draw_rect(Rect2(c + Vector2(-2.0, -5.0), Vector2(4.0, 9.0)), CONTORNO)
		draw_rect(Rect2(c + Vector2(-1.0, -1.0), Vector2(2.0, 4.0)), GARRAFA)
		draw_rect(Rect2(c + Vector2(-1.0, -1.0), Vector2(1.0, 3.0)), GARRAFA_CLARA)
		draw_rect(Rect2(c + Vector2(-1.0, -4.0), Vector2(1.0, 3.0)), GARRAFA)
