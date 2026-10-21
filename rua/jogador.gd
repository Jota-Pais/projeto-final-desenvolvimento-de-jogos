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

## Agachar (21/10/2026, para o tutorial): C liga e desliga. Agachado ele anda
## devagar e nao corre, e a cobertura baixa - cacamba, carro, entulho, sacos -
## o esconde da vista do zumbi (rua/camadas.gd; Joao: "eu me escondo, quem eu
## vejo nao"). O desenho e o boneco achatado, com o pe no chao, ate vir uma
## animacao. **Numeros: proposta.**
const VELOCIDADE_AGACHADO := 70.0
const ALTURA_AGACHADO := 0.72

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

## As camadas de colisao (rua/camadas.gd): ele bate em toda barreira, ate na
## que se ve e atira atraves.
const Camadas := preload("res://rua/camadas.gd")

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

## O barulho dos passos (21/10/2026, Joao: "correr perto chama e andar muito
## perto tambem chama, so agachado nao chamaria de maneira nenhuma, em troca de
## ser mais lento"): correndo, todo zumbi a ate RAIO_CORRENDO vem ver o que
## foi; andando, so o que esta colado (RAIO_ANDANDO). Agachado e silencio.
## **Proposta** (40 px = 1 m).
const RAIO_CORRENDO := 160.0
const RAIO_ANDANDO := 56.0
const BARULHO_A_CADA := 0.3

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

## Se ele esta agachado (ver VELOCIDADE_AGACHADO). O zumbi e a arma leem.
var agachado := false

## Sob roteiro - a cena de abertura do tutorial (rua/tutorial.gd): quem anda e
## o roteiro, por `direcao_do_roteiro` e `velocidade_do_roteiro`; as teclas de
## andar, agachar e atirar nao contam.
var no_roteiro := false
var direcao_do_roteiro := Vector2.ZERO
var velocidade_do_roteiro := VELOCIDADE

var _empurrao := Vector2.ZERO
var _barulho := 0.0
var _mao: Node2D
## O deslocamento do desenho de pe, para devolver o pe ao chao agachado.
var _offset_de_pe := Vector2.ZERO

@onready var _boneco: Boneco = $Boneco
@onready var _arma: Arma = $Arma
## Para onde ele esta olhando: comeca de frente para a tela.
var _olhando := Vector2.DOWN
var _mirando := 0.0
var _passos: AudioStreamPlayer


func _ready() -> void:
	collision_mask = Camadas.ANDAR
	_arma.atirou.connect(_ao_atirar)
	_passos = AudioStreamPlayer.new()
	add_child(_passos)
	# A rua nao tem musica: o que se ouve e passo, tiro e zumbi.
	Som.musica("")
	# A arma na mao encolhe com o boneco: o sprite, a mao, o braco e o clarao
	# vivem no espaco dela. O tiro sai de coordenada global e nao muda.
	_arma.scale = Vector2.ONE * Boneco.ESCALA
	($Camera as Camera2D).zoom = Vector2.ONE * ZOOM_DA_CAMERA
	_offset_de_pe = _boneco.offset
	# A mao: o scroll e o arremesso (rua/mao.gd).
	_mao = Node2D.new()
	_mao.set_script(load("res://rua/mao.gd"))
	_mao.name = "Mao"
	add_child(_mao)
	# Os bracos que seguram a arma, a pedra e a garrafa (rua/bracos.gd): filhos
	# do boneco, para agachar e recuar junto com ele.
	var bracos := Node2D.new()
	bracos.set_script(load("res://rua/bracos.gd"))
	bracos.name = "Bracos"
	_boneco.add_child(bracos)
	bracos.montar(self, _boneco, _arma, _mao)

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector(
		"andar_esquerda", "andar_direita", "andar_cima", "andar_baixo"
	)
	# Com a mochila aberta ele para: as mesmas teclas de andar sao as que
	# escolhem a linha na tela. **O mundo nao para junto** - o relogio corre e o
	# zumbi anda, e e isso que faz escolher o que largar custar alguma coisa.
	if TelaDaMochila.aberta:
		direcao = Vector2.ZERO
	elif not no_roteiro and Input.is_action_just_pressed("agachar"):
		agachar(not agachado)
	var velocidade := VELOCIDADE_CORRENDO if Input.is_action_pressed("correr") else VELOCIDADE
	if agachado:
		velocidade = VELOCIDADE_AGACHADO
	if no_roteiro:
		direcao = direcao_do_roteiro
		velocidade = velocidade_do_roteiro
	velocity = direcao * velocidade + _empurrao
	move_and_slide()

	_empurrao = _empurrao.move_toward(
		Vector2.ZERO, FORCA_DO_EMPURRAO / ESPERA_DO_EMPURRAO * delta)

	_animar(direcao, velocidade, delta)
	_soar(direcao, velocidade == VELOCIDADE_CORRENDO)
	_fazer_barulho(direcao, velocidade == VELOCIDADE_CORRENDO, delta)

## Os passos chamam o zumbi perto (ver RAIO_CORRENDO): de tempos em tempos,
## e nao a cada quadro, como o chamado do tiro.
func _fazer_barulho(direcao: Vector2, correndo: bool, delta: float) -> void:
	_barulho -= delta
	if direcao == Vector2.ZERO or agachado or no_roteiro or _barulho > 0.0:
		return
	_barulho = BARULHO_A_CADA
	var raio := RAIO_CORRENDO if correndo else RAIO_ANDANDO
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if (zumbi as Node2D).global_position.distance_to(global_position) <= raio:
			zumbi.foi_chamado(global_position)

## Agacha ou levanta. O boneco achata em volta do centro do corpo, e o
## deslocamento do desenho devolve o pe ao lugar (o pe esta `pe` px do desenho
## abaixo do centro).
func agachar(sim: bool) -> void:
	agachado = sim
	var fator := ALTURA_AGACHADO if sim else 1.0
	_boneco.scale.y = Boneco.ESCALA * fator
	_boneco.offset.y = _offset_de_pe.y + _boneco.pe * (1.0 - fator) / fator

## Para onde ele olha agora (os bracos leem, para saber qual e a mao direita).
func para_onde_olha() -> Vector2:
	return _olhando

## O roteiro manda ele olhar para algum lugar, parado.
func olhar_para(direcao: Vector2) -> void:
	if direcao.length() > 0.01:
		_olhando = direcao.normalized()

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
	var com_a_arma := Input.is_action_pressed("atirar") and Travessia.armado and Travessia.na_mao == "arma"
	if (com_a_arma or (_mao != null and _mao.mirando())) and not TelaDaMochila.aberta and not no_roteiro:
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
