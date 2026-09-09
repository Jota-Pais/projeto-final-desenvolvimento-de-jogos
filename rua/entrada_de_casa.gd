extends Area2D
## A porta da sua casa: a unica porta do mapa que nao se vasculha. Encoste e
## segure E para entrar e encerrar o dia na rua.
##
## E aqui que a rua acaba e a casa comeca. Esta porta nao sabe nada do que tem
## do outro lado - so chama Travessia.entrar_em_casa(). Quem for fazer o modo
## Casa nao precisa tocar neste arquivo.
##
## Segurar em vez de apertar e de proposito: e a chave na fechadura com zumbi
## chegando, e de graca evita entrar em casa sem querer ao vasculhar por perto.
## Se atrapalhar, e so baixar a DURACAO.

## Segundos de E segurado para entrar. Bem menor que o de vasculhar uma porta
## alheia (5 s) - a sua chave voce tem.
const DURACAO := 1.2

## Mesmo motivo do ALCANCE do vasculhavel: tem que ser maior que a meia altura
## do jogador, senao nao existe lugar onde ele esteja fora da porta e dentro da
## zona ao mesmo tempo.
const ALCANCE := 60.0

## Na escala do vao de porta do bairro (Construcao.VAO).
const TAMANHO := Vector2(100.0, 40.0)

# Tom quente, que e a cor do modo Casa na direcao de arte. Numa rua inteira
# cinza e a pista mais barata de "e aqui que voce volta".
const COR_DA_PORTA := Color("8a5a2b")
const COR_DA_LUZ := Color(0.95, 0.72, 0.38, 0.16)
const COR_DA_BARRA := Color("e8b061")
const COR_FUNDO_DA_BARRA := Color("2a211a")
const COR_DO_AVISO := Color("f2ddba")

var _progresso := 0.0
var _jogador_dentro := false
var _entrando := false

func _ready() -> void:
	_montar_formas()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _process(delta: float) -> void:
	if _entrando:
		return

	var antes := _progresso
	if _jogador_dentro and Input.is_action_pressed("vasculhar"):
		_progresso += delta
		if _progresso >= DURACAO:
			_entrar()
			return
	elif _progresso > 0.0:
		# A porta de casa zera ao soltar, ao contrario do vasculhavel: nao ha
		# nada a acumular numa fechadura.
		_progresso = 0.0

	if _progresso != antes:
		queue_redraw()

func _entrar() -> void:
	_entrando = true
	print("Entrou em casa - fim do dia %d" % Travessia.dia)
	# O unico jeito bom de acabar o dia, e o unico que passa por aqui.
	Travessia.entrar_em_casa(Travessia.FimDoDia.PELA_PORTA)

func _montar_formas() -> void:
	var deteccao := RectangleShape2D.new()
	deteccao.size = TAMANHO + Vector2.ONE * ALCANCE * 2.0
	($Deteccao as CollisionShape2D).shape = deteccao

	var corpo := RectangleShape2D.new()
	corpo.size = TAMANHO
	($Corpo/Colisao as CollisionShape2D).shape = corpo

func _ao_entrar(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = true
	queue_redraw()

func _ao_sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = false
	queue_redraw()

func _draw() -> void:
	# Luz vazando da porta para a calcada. Marca o lugar de longe, que e o que
	# uma porta de casa precisa fazer num mapa cinza.
	draw_rect(Rect2(-TAMANHO.x, TAMANHO.y / 2.0 - 4.0, TAMANHO.x * 2.0, 90.0), COR_DA_LUZ)

	var caixa := Rect2(-TAMANHO / 2.0, TAMANHO)
	draw_rect(caixa, COR_DA_PORTA)
	draw_rect(caixa, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)

	var fonte := ThemeDB.fallback_font
	var topo := -TAMANHO.y / 2.0
	var esquerda := -TAMANHO.x / 2.0

	if _progresso > 0.0:
		var barra := Rect2(Vector2(-TAMANHO.x / 2.0, topo - 18.0), Vector2(TAMANHO.x, 8.0))
		draw_rect(barra, COR_FUNDO_DA_BARRA)
		var cheio := barra
		cheio.size.x = TAMANHO.x * (_progresso / DURACAO)
		draw_rect(cheio, COR_DA_BARRA)
		draw_rect(barra, Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	if _jogador_dentro:
		draw_string(fonte, Vector2(esquerda, topo - 26.0), "E  entrar em casa",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DO_AVISO)
	else:
		draw_string(fonte, Vector2(esquerda, topo - 12.0), "sua casa",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(COR_DO_AVISO, 0.45))
