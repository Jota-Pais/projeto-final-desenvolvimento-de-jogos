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
##
## **Metade desde 20/10/2026** (eram 280 e 460), junto com o tamanho. Joao: "o
## mundo ta muito pequeno, deixa o personagem e zumbis com metade do tamanho e
## metade da velocidade". O corpo foi de 28 x 40 para 14 x 20 (jogador.tscn) e
## o desenho para escala 0,5 (rua/boneco.gd); com o zoom da camera em dobro, na
## tela ele anda e aparece como antes, e o mundo fica duas vezes maior.
const VELOCIDADE := 140.0
const VELOCIDADE_CORRENDO := 230.0

## Quanto a camera aproxima (20/10/2026, "diminui o enquadramento da tela"): a
## tela de 1280 x 720 mostra 640 x 360 px de mundo. **So inteiro**: com o boneco
## em escala 0,5 o zoom 2 da 1 pixel de desenho por pixel de tela, e o chao em
## escala 1 fica com 2 x 2; um zoom quebrado (1,5) faria o pixel desigual e a
## arte tremer andando. Os limites da camera (cenario.gd) ja descontam o zoom.
const ZOOM_DA_CAMERA := 2.0

## So para a guarda do `aberta`: com a tela da mochila na frente, WASD escolhe
## linha em vez de andar.
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")

## O boneco e o no que desenha o jogador (rua/boneco.gd); ver _animar().
const Boneco := preload("res://rua/boneco.gd")

## Por quanto tempo, depois de apertar o tiro, ele continua olhando para o
## mouse em vez de para onde anda.
const SEGUNDOS_DE_MIRA := 0.5

## A arma e filha dele (rua/arma.gd): o sinal `atirou` dela e o que faz o
## boneco reagir ao disparo (ver _ao_atirar), e e ela que desenha a arma na
## mao - este script so diz para onde ele olha e se a arma fica na frente ou
## atras do corpo.
const Arma := preload("res://rua/arma.gd")

## Olhando mais para cima que isto (y negativo e para longe da camera), a arma
## passa para tras do corpo.
const OLHANDO_PARA_LONGE := -0.3

## O recuo de codigo do disparo: o boneco da um passo contra o tiro e volta
## em SEGUNDOS_DO_RECUO. O passo e RECUO px mais o `coice` da arma (a ficha
## em rua/arma.gd: pistola 2-3, escopeta 5-6), para a Doze sacudir mais que
## a Beretta - em px do desenho, vezes a escala do boneco no mundo. **E o definitivo** (Joao, 15/10/2026, "faz o recuo em codigo"):
## a animacao `atirar` na folha foi tentada duas vezes no PixelLab e
## reprovada - na vista de cima, "bracos para a frente" e para a camera e o
## modelo nao encurta o braco. O `tocar("atirar")` fica
## so por garantia, se um dia a folha tiver.
const RECUO := 2.0
const SEGUNDOS_DO_RECUO := 0.1

## Para saber se ele esta dentro de uma construcao: e o que troca o passo e o
## som de fundo (ver _soar).
const Mapa := preload("res://rua/mapa.gd")

## Os passos, por onde ele pisa (sons do Drive, 20/10/2026). Cada um e um loop
## de varios passos, nao um passo so: toca enquanto ele anda e para quando ele
## para. Dentro e o piso de madeira, que nao tem versao correndo - correr
## acelera o loop.
const PASSO_NA_RUA := "andar_previa"
const PASSO_NA_RUA_CORRENDO := "andar_previa_2"
const PASSO_DENTRO := "andar_madeira_previa"
const TOM_DO_PASSO_CORRENDO := 1.3


## Emitido ao ser tocado. O Vasculhavel escuta para interromper o vasculho, e a
## tela da mochila para se fechar - quem apanha para de arrumar a mochila.
signal atingido()

const VIDA_CHEIA := 100.0

## Empurrao do toque do zumbi: some em ESPERA_DO_EMPURRAO segundos.
##
## E o feedback do toque junto com a barra - e, de bonus, costuma te tirar da
## zona de alcance do movel, que ja interrompe o vasculho por si. Metade desde
## 20/10/2026 (era 260), junto com a velocidade: uns 16 px.
const FORCA_DO_EMPURRAO := 130.0
const ESPERA_DO_EMPURRAO := 0.25

const COR_DA_VIDA := Color("c0463c")
const COR_FUNDO_DA_VIDA := Color("241d1c")

var vida := VIDA_CHEIA

var _empurrao := Vector2.ZERO

@onready var _boneco: Boneco = $Boneco
@onready var _arma: Arma = $Arma
## Para onde ele esta olhando: comeca de frente para a tela.
var _olhando := Vector2.DOWN
var _mirando := 0.0
var _passos: AudioStreamPlayer


func _ready() -> void:
	_arma.atirou.connect(_ao_atirar)
	_passos = AudioStreamPlayer.new()
	add_child(_passos)
	# A rua nao tem musica: o que se ouve e passo, tiro e zumbi.
	Som.musica("")
	# A arma na mao encolhe com o boneco: o sprite, a mao, o braco e o clarao
	# vivem no espaco dela. O tiro sai de coordenada global e nao muda.
	_arma.scale = Vector2.ONE * Boneco.ESCALA
	($Camera as Camera2D).zoom = Vector2.ONE * ZOOM_DA_CAMERA

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

	_animar(direcao, velocidade, delta)
	_soar(direcao, velocidade == VELOCIDADE_CORRENDO)

## Os passos e o fundo. Dentro de uma construcao o passo e no piso e o fundo
## e o ambiente de dentro; na rua, passo na rua e silencio em volta - e la
## fora que o zumbi tem que se ouvir.
func _soar(direcao: Vector2, correndo: bool) -> void:
	var dentro := Mapa.construcao_em(global_position) >= 0
	Som.ambiente("ambiente_dentro_lugares" if dentro else "")
	if direcao == Vector2.ZERO or Som.mudo:
		_passos.stop()
		return
	var nome := PASSO_DENTRO if dentro else (PASSO_NA_RUA_CORRENDO if correndo else PASSO_NA_RUA)
	if _passos.get_meta("nome", "") != nome:
		_passos.set_meta("nome", nome)
		var stream := Som.carregar(nome)
		if stream != null:
			stream.loop = true
		_passos.stream = stream
		_passos.volume_db = Som.VOLUME.get(nome, 0.0)
		_passos.stop()
	_passos.pitch_scale = TOM_DO_PASSO_CORRENDO if correndo and dentro else 1.0
	if not _passos.playing and _passos.stream != null:
		_passos.play()

## Para onde ele olha, e o que o boneco mostra. **Olha para onde anda, e para o
## mouse so com a arma na mao** (decidido 30/09/2026). "Na mao" aqui e
## enquanto o tiro esta apertado e por SEGUNDOS_DE_MIRA depois: nao existe
## sacar e guardar a arma, voce comeca com ela. **Proposta** - se a equipe
## quiser um botao de mirar, e um estado a mais aqui.
##
## O boneco segue a direcao das teclas, nao a velocidade: empurrado por um
## zumbi ele fica parado olhando para onde olhava, em vez de "andar" para tras.
## Correr e o mesmo andar mais rapido (decidido 30/09; animacao de corrida so
## com assinatura).
func _animar(direcao: Vector2, velocidade: float, delta: float) -> void:
	if Input.is_action_pressed("atirar") and not TelaDaMochila.aberta:
		_mirando = SEGUNDOS_DE_MIRA
	else:
		_mirando = maxf(0.0, _mirando - delta)
	if _mirando > 0.0:
		var para_o_mouse := get_global_mouse_position() - global_position
		if para_o_mouse.length() > 1.0:
			_olhando = para_o_mouse.normalized()
	elif direcao != Vector2.ZERO:
		_olhando = direcao
	var acao := "parado" if direcao == Vector2.ZERO else "andar"
	_boneco.mostrar(acao, _olhando, velocidade / VELOCIDADE)
	_segurar_a_arma()

## A arma na mao aponta para onde ele olha. Olhando para longe da camera
## (norte), ela fica atras do corpo: o no da arma passa para antes do boneco
## na arvore, que e a ordem de desenho. Sempre na mao - nao existe guardar a
## arma (ver _animar).
func _segurar_a_arma() -> void:
	_arma.apontar(_olhando)
	var atras := _olhando.y < OLHANDO_PARA_LONGE
	var esta_atras := _arma.get_index() < _boneco.get_index()
	if atras != esta_atras:
		move_child(_arma, 0 if atras else get_child_count() - 1)

## A arma disparou para `direcao`. Ele olha para la e o boneco mostra o tiro
## com o recuo de codigo (ver RECUO); o clarao do cano e o coice da arma na
## mao e a arma quem desenha (rua/arma.gd), entao o tiro le em tres partes:
## clarao, arma que pula para tras, corpo que da o passo.
func _ao_atirar(direcao: Vector2) -> void:
	_olhando = direcao
	_mirando = SEGUNDOS_DE_MIRA
	if _boneco.tocar("atirar", direcao):
		return
	var passo := (RECUO + float(_arma.ficha()["coice"])) * Boneco.ESCALA
	_boneco.position = -direcao * passo
	create_tween().tween_property(_boneco, "position", Vector2.ZERO, SEGUNDOS_DO_RECUO) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## Chamado pelo zumbi que tocou nele: tira `quanto` de vida, empurra e
## interrompe o que ele estava fazendo.
##
## Nao existe atacar de volta. A resposta e sair de perto, e o preco de nao
## sair e o vasculho que nao termina - e, agora, a vida que acaba.
func levar_dano(quanto: float, de_onde: Vector2) -> void:
	vida = maxf(0.0, vida - quanto)
	_empurrao = de_onde.normalized() * FORCA_DO_EMPURRAO
	Som.tocar("dano_personagem", randf_range(0.95, 1.05), 1)
	atingido.emit()
	queue_redraw()

	if vida > 0.0:
		return
	# O que cair custa depende do modo (Joao, 15/10/2026 - ver Travessia.Modo):
	# no **hardcore**, a partida; na **campanha**, o dia - voce acorda em casa
	# sem nada do que carregava, e o preco e um dia do prazo, que e o recurso
	# caro do jogo.
	if Travessia.modo == Travessia.Modo.HARDCORE:
		print("Sem vida - modo hardcore, a partida acaba")
		Travessia.acabar_o_jogo(Travessia.Desfecho.CAIU_NA_RUA)
		return
	print("Sem vida - o dia acaba na forca")
	vida = VIDA_CHEIA
	Travessia.entrar_em_casa(Travessia.FimDoDia.SEM_VIDA)

## Barra de vida em cima da cabeca, so quando falta alguma: e onde ela importa
## na hora do aperto. A HUD mostra o numero no canto. Fica acima do boneco (o
## pe esta em +10 e ele tem uns 37 px de altura no mundo), porque o corpo
## desenha antes dos filhos: em cima do sprite ela sumiria atras dele. Metade
## desde 20/10/2026, junto com o boneco - com o zoom 2, do tamanho de antes.
func _draw() -> void:
	if is_equal_approx(vida, VIDA_CHEIA):
		return
	var barra := Rect2(-8.0, -33.0, 16.0, 2.5)

	draw_rect(barra, COR_FUNDO_DA_VIDA)
	var cheio := barra
	cheio.size.x = barra.size.x * (vida / VIDA_CHEIA)
	draw_rect(cheio, COR_DA_VIDA)
