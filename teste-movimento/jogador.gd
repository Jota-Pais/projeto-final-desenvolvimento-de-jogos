extends CharacterBody2D
## Boneco de teste (um quadrado com a foto). A camera e filha dele, entao quem
## anda na tela e o chao: o jogador fica fixo no meio. Setas ou WASD.

const Chao := preload("res://teste-movimento/chao.gd")

const VELOCIDADE := 420.0
const METADE_DO_CORPO := 32.0

func _physics_process(_delta: float) -> void:
	velocity = _direcao() * VELOCIDADE
	move_and_slide()

	# Trava nas bordas do chao desenhado, senao da para sair do mundo e ficar
	# olhando para o vazio.
	var limite := Chao.TAMANHO_DO_MUNDO / 2.0 - Vector2.ONE * METADE_DO_CORPO
	position = position.clamp(-limite, limite)

## As setas ja vem no Input Map padrao do Godot. O WASD esta na mao so enquanto
## o Input Map do projeto nao existe - quando existir, isto vira uma linha so.
func _direcao() -> Vector2:
	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direcao != Vector2.ZERO:
		return direcao

	var wasd := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	return wasd.normalized()
