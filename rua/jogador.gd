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
## sai o sinal `atingido` - quem escuta e o Vasculhavel, que interrompe o
## vasculho, e a tela da mochila, que se fecha. O jogador e a coisa que os dois
## lados conhecem, e a regra fica sendo "ser atingido interrompe o que voce
## estava fazendo".
##
## ## A vida (de volta em 30/09/2026)
##
## Tinha: 100 pontos, o toque do zumbi tirava 12, e zerar acabava o dia pela
## forca. **Saiu em 16/09/2026 por decisao de mesa**, junto com a fome e a
## agua, e **voltou em 30/09/2026 a pedido do Joao** ("volta a barra de
## vida"), do jeito que era. Fome e agua continuam fora.
##
## O toque continua empurrando e interrompendo o vasculho - essa pressao sobre
## a core mechanic nunca dependeu da barra. O que a barra acrescenta e o preco
## de ficar: aguentar toque atras de toque para terminar um vasculho tem um
## fim, e o fim custa o dia.

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

const VIDA_CHEIA := 100.0

## Empurrao do toque do zumbi: some em ESPERA_DO_EMPURRAO segundos.
##
## E o feedback do toque junto com a barra - e, de bonus, costuma te tirar da
## zona de alcance do movel, que ja interrompe o vasculho por si.
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

## Chamado pelo zumbi que tocou nele: tira `quanto` de vida, empurra e
## interrompe o que ele estava fazendo.
##
## Nao existe atacar de volta. A resposta e sair de perto, e o preco de nao
## sair e o vasculho que nao termina - e, agora, a vida que acaba.
func levar_dano(quanto: float, de_onde: Vector2) -> void:
	vida = maxf(0.0, vida - quanto)
	_empurrao = de_onde.normalized() * FORCA_DO_EMPURRAO
	atingido.emit()
	queue_redraw()

	if vida > 0.0:
		return
	# **Cair custa o dia, e nao a partida.** O High Concept declara dois
	# desfechos, a cura a tempo e o prazo esgotado, e cair na rua nao e nenhum
	# dos dois. Voce acorda em casa sem nada do que carregava, e o preco e um
	# dia do prazo - que e o recurso caro do jogo.
	#
	# Se a equipe quiser que cair acabe a partida, e uma linha: trocar por
	# Travessia.acabar_o_jogo(). Mas ai o jogo passa a ter um game over que o
	# documento nao previu.
	print("Sem vida - o dia acaba na forca")
	vida = VIDA_CHEIA
	Travessia.entrar_em_casa(Travessia.FimDoDia.SEM_VIDA)

## Barra de vida em cima da cabeca, so quando falta alguma: e onde ela importa
## na hora do aperto. A HUD mostra o numero no canto.
func _draw() -> void:
	if is_equal_approx(vida, VIDA_CHEIA):
		return
	var barra := Rect2(-16.0, -34.0, 32.0, 5.0)
	draw_rect(barra, COR_FUNDO_DA_VIDA)
	var cheio := barra
	cheio.size.x = barra.size.x * (vida / VIDA_CHEIA)
	draw_rect(cheio, COR_DA_VIDA)
