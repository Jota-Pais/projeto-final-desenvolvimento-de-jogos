extends CharacterBody2D
## Jogador da rua. Anda em 8 direcoes com WASD ou setas e corre com Shift.
## A camera e filha dele, entao quem se mexe na tela e o cenario.
##
## Ele nao vasculha nada: quem cuida do vasculho e o proprio Vasculhavel, que
## le a acao enquanto o jogador estiver encostado nele. Assim nao existe
## referencia do jogador para os itens do cenario, nem o contrario - e da para
## acrescentar coisa vasculhavel na cena sem tocar neste arquivo.
##
## Ele tambem nao sabe que zumbi existe. Quem toca chama foi_tocado(), e daqui
## sai o sinal `atingido` - quem escuta e o Vasculhavel, que interrompe o
## vasculho, e a tela da mochila, que se fecha. O jogador e a coisa que os dois
## lados conhecem, e a regra fica sendo "ser atingido interrompe o que voce
## estava fazendo".
##
## ## Ele nao tem vida (16/09/2026)
##
## Tinha: uma barra de 100, o toque do zumbi tirava 12, e zerar acabava o dia
## pela forca. **Saiu por decisao de mesa**, junto com a fome e a agua - as tres
## eram a camada de sobrevivencia do jogo, e ela fica para depois de as regras
## da rua e da casa fecharem.
##
## **O toque continua existindo e continua cobrando.** Ele empurra e interrompe
## o vasculho; o que o zumbi tira agora e tempo, e tempo e o recurso caro do
## jogo. A pressao do zumbi sobre a core mechanic nao dependia da barra.
##
## Quem for reimplementar a vida comeca por aqui: e este arquivo que o zumbi
## chama e de onde o sinal sai. O que sumiu junto esta no `git log`.

## Subiu junto com a ampliacao do bairro de 08/09, mas so ~1,3x e nao 1,8x:
## parte do ponto e o mundo passar a parecer grande. Se ficar arrastado, este e
## o numero a mexer.
const VELOCIDADE := 280.0
const VELOCIDADE_CORRENDO := 460.0

## So para a guarda do `aberta`: com a tela da mochila na frente, WASD escolhe
## linha em vez de andar.
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")

## Emitido ao ser tocado. O Vasculhavel escuta para interromper o vasculho, e a
## tela da mochila para se fechar - quem apanha para de arrumar a mochila.
signal atingido()

## Empurrao do toque do zumbi: some em ESPERA_DO_EMPURRAO segundos.
##
## Desde que a vida saiu, **ele e o feedback do toque** - e o unico jeito de a
## tela dizer que voce foi alcancado. E, de bonus, costuma te tirar da zona de
## alcance do movel, que ja interrompe o vasculho por si.
const FORCA_DO_EMPURRAO := 260.0
const ESPERA_DO_EMPURRAO := 0.25

var _empurrao := Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector(
		"andar_esquerda", "andar_direita", "andar_cima", "andar_baixo"
	)
	# Com a mochila aberta ele para: as mesmas teclas de andar sao as que
	# escolhem a linha na tela. **O mundo nao para junto** - o relogio corre e o
	# zumbi anda, e e isso que faz escolher o que largar custar alguma coisa.
	if TelaDaMochila.aberta:
		direcao = Vector2.ZERO
	var velocidade := VELOCIDADE_CORRENDO if Input.is_action_pressed("correr") else VELOCIDADE
	velocity = direcao * velocidade + _empurrao
	move_and_slide()

	_empurrao = _empurrao.move_toward(
		Vector2.ZERO, FORCA_DO_EMPURRAO / ESPERA_DO_EMPURRAO * delta)

## Chamado pelo zumbi que tocou nele.
##
## Nao existe atacar de volta, e **nao existe mais apanhar ate cair**: o toque
## empurra e interrompe. A resposta continua sendo sair de perto, e o preco de
## nao sair e o vasculho que nao termina.
func foi_tocado(de_onde: Vector2) -> void:
	_empurrao = de_onde.normalized() * FORCA_DO_EMPURRAO
	atingido.emit()
