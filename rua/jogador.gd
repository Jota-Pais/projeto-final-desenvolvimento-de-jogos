extends CharacterBody2D
## Jogador da rua. Anda em 8 direcoes com WASD ou setas e corre com Shift.
## A camera e filha dele, entao quem se mexe na tela e o cenario.
##
## Ele nao vasculha nada: quem cuida do vasculho e o proprio Vasculhavel, que
## le a acao enquanto o jogador estiver encostado nele. Assim nao existe
## referencia do jogador para os itens do cenario, nem o contrario - e da para
## acrescentar coisa vasculhavel na cena sem tocar neste arquivo.
##
## Ele tambem nao sabe que zumbi existe. Quem toca chama levar_dano(), e daqui
## sai o sinal `atingido` - e o Vasculhavel que escuta esse sinal para
## interromper o vasculho. O jogador e a coisa que os dois lados conhecem, e a
## regra fica sendo "ser atingido interrompe o que voce estava fazendo".

## Subiu junto com a ampliacao do bairro de 08/09, mas so ~1,3x e nao 1,8x:
## parte do ponto e o mundo passar a parecer grande. Se ficar arrastado, este e
## o numero a mexer.
const VELOCIDADE := 280.0
const VELOCIDADE_CORRENDO := 460.0

## Emitido ao levar dano. O Vasculhavel escuta para interromper o vasculho.
signal atingido(dano: float)

const VIDA_CHEIA := 100.0

## Empurrao do toque do zumbi: some em ESPERA_DO_EMPURRAO segundos. Existe para
## o dano ser legivel - e, de bonus, costuma te tirar da zona de alcance do
## movel, que ja interrompe o vasculho por si.
const FORCA_DO_EMPURRAO := 260.0
const ESPERA_DO_EMPURRAO := 0.25

const COR_DA_VIDA := Color("c0463c")
const COR_FUNDO_DA_VIDA := Color("241d1c")

var vida := VIDA_CHEIA

var _empurrao := Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector(
		"andar_esquerda", "andar_direita", "andar_cima", "andar_baixo"
	)
	var velocidade := VELOCIDADE_CORRENDO if Input.is_action_pressed("correr") else VELOCIDADE
	velocity = direcao * velocidade + _empurrao
	move_and_slide()

	_empurrao = _empurrao.move_toward(
		Vector2.ZERO, FORCA_DO_EMPURRAO / ESPERA_DO_EMPURRAO * delta)

## Chamado pelo zumbi que tocou nele.
func levar_dano(quanto: float, de_onde: Vector2) -> void:
	vida = maxf(0.0, vida - quanto)
	_empurrao = de_onde.normalized() * FORCA_DO_EMPURRAO
	atingido.emit(quanto)
	queue_redraw()

	if vida > 0.0:
		return
	# Provisorio: sem vida, o dia acaba e voce volta para casa. Morte e tela de
	# fim de jogo sao o passo 5 - isto existe para o dano ter consequencia sem
	# inventar interface.
	print("Sem vida - o dia acaba na forca")
	vida = VIDA_CHEIA
	Travessia.entrar_em_casa(Travessia.FimDoDia.SEM_VIDA)

## Barra de vida em cima da cabeca. Nao e a HUD (que e o passo 3): e o minimo
## para o dano ser visivel enquanto ela nao existe.
func _draw() -> void:
	if is_equal_approx(vida, VIDA_CHEIA):
		return
	var barra := Rect2(-16.0, -34.0, 32.0, 5.0)
	draw_rect(barra, COR_FUNDO_DA_VIDA)
	var cheio := barra
	cheio.size.x = barra.size.x * (vida / VIDA_CHEIA)
	draw_rect(cheio, COR_DA_VIDA)
