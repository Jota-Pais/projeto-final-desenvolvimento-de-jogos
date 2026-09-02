extends CharacterBody2D
## Inimigo de teste: anda devagar na direcao do jogador, so isso.
## Nao ataca, nao morre, nao desvia de nada - e so para ver perseguicao na tela.

const VELOCIDADE := 110.0

var _jogador: Node2D

func _physics_process(_delta: float) -> void:
	# Procurado pelo grupo, e nao por caminho de node, para o inimigo nao
	# depender de onde ele foi colocado na cena.
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("jogador")
		if _jogador == null:
			return

	velocity = global_position.direction_to(_jogador.global_position) * VELOCIDADE
	move_and_slide()
