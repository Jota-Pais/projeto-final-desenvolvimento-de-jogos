extends CharacterBody2D
## Jogador da rua. Anda em 8 direcoes com WASD ou setas e corre com Shift.
## A camera e filha dele, entao quem se mexe na tela e o cenario.
##
## Ele nao vasculha nada: quem cuida do vasculho e o proprio Vasculhavel, que
## le a acao enquanto o jogador estiver encostado nele. Assim nao existe
## referencia do jogador para os itens do cenario, nem o contrario - e da para
## acrescentar coisa vasculhavel na cena sem tocar neste arquivo.

## Subiu junto com a ampliacao do bairro de 08/09, mas so ~1,3x e nao 1,8x:
## parte do ponto e o mundo passar a parecer grande. Se ficar arrastado, este e
## o numero a mexer.
const VELOCIDADE := 280.0
const VELOCIDADE_CORRENDO := 460.0

func _physics_process(_delta: float) -> void:
	var direcao := Input.get_vector(
		"andar_esquerda", "andar_direita", "andar_cima", "andar_baixo"
	)
	var velocidade := VELOCIDADE_CORRENDO if Input.is_action_pressed("correr") else VELOCIDADE
	velocity = direcao * velocidade
	move_and_slide()
