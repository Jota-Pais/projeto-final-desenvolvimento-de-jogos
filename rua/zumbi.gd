extends CharacterBody2D
## O zumbi. Escrito para servir a core mechanic: ele **existe para atrapalhar o
## vasculho**, e nao para ser um combate.
##
## O High Concept define tres coisas que estao implementadas aqui:
##
##  - **campo de visao** - ele nao sabe onde voce esta. Ve num cone, e parede
##    corta a linha de visao. Entrar numa casa quebra a perseguicao; ficar
##    dentro dela com ele tambem te encurrala;
##  - **horda** - quem enxerga voce chama quem esta perto. Um zumbi nao e
##    ameaca, tres sao;
##  - **pressao sobre a mesma acao** - o toque dele interrompe o vasculho e
##    tira vida. Nao existe atacar de volta; a resposta e sair de perto.
##
## Ele e **mais lento que voce andando** (165 contra 280, e 460 correndo). Da
## para sempre fugir, de proposito: o que ele tira nao e vida, e o tempo que
## voce precisava para terminar de vasculhar.
##
## Nao reaproveita nada do `inimigo.gd` da cena de teste, que perseguia em
## linha reta a partir de qualquer distancia e atravessava o mapa inteiro.

const TAMANHO := Vector2(30.0, 44.0)

const VELOCIDADE_VAGANDO := 70.0
const VELOCIDADE_PERSEGUINDO := 165.0

## Ate onde ele ve, e a abertura do cone. Parede corta a linha de visao.
const ALCANCE_DA_VISTA := 520.0
const ABERTURA_DA_VISTA := 110.0

## Quanto o alcance da vista cresce na noite fechada: 0.35 leva os 520 px a
## 702 px as 05:00, subindo aos poucos a partir das 19:00.
##
## **Nao e realismo** - zumbi nao ve melhor no escuro. E a mesma razao de a rua
## encher: a noite existe para te empurrar pra casa, e ficar invisivel andando
## a noite toda tiraria o aperto dela. Quem le o quanto de noite e o relogio.
const VISTA_A_MAIS_DE_NOITE := 0.35

## Quem enxerga o jogador avisa os zumbis vagando dentro deste raio. E o que
## faz horda se formar sem sistema de onda nenhum.
const ALCANCE_DO_CHAMADO := 700.0

## Quantos segundos ele aceita ficar **travado** antes de desistir e voltar a
## vagar. Travado = nao saiu do lugar, nao = nao chegou mais perto.
##
## Duas versoes anteriores estavam erradas e o teste pegou as duas:
##
##  - limite de tempo fixo (4 s) fazia ele desistir no meio do caminho, porque
##    atravessar a casa da calcada ate o quarto do fundo da 1085 px e leva 6,6 s
##    a 165 px/s. Entrar em casa virava abrigo garantido;
##  - distancia em linha reta ate o alvo tambem nao serve: contornando a casa
##    para chegar na porta, a linha reta AUMENTA, e ele desistia exatamente
##    quando estava fazendo a coisa certa.
##
## Distancia andada nao tem esses dois furos.
const SEGUNDOS_SEM_PROGRESSO := 3.0

## Quanto ele tem que andar nesse tempo para nao ser considerado travado.
const PASSO_MINIMO := 24.0

const DISTANCIA_DO_TOQUE := 48.0
const DANO := 12.0
const ESPERA_ENTRE_TOQUES := 1.1

const SEGUNDOS_ENTRE_RECALCULOS := 0.4
const TOLERANCIA_DO_PASSO := 26.0

## Desenha o cone de visao na tela. **Auxilio de prototipo**, nao decisao de
## design: sem ver o cone nao da para entender por que ele te viu ou nao.
const MOSTRAR_A_VISTA := true

# Verde doente parado, ambar aceso perseguindo. O ambar ja foi marrom e ficava
# quase igual ao carro abandonado: no meio da rua nao dava para saber o que era
# zumbi e o que era cenario.
const COR := Color("4c5c44")
const COR_PERSEGUINDO := Color("8a7a3e")
const COR_DA_CARA := Color("9aa88f")
const COR_DA_VISTA := Color(0.85, 0.75, 0.45, 0.07)

enum Estado { VAGANDO, PERSEGUINDO, PROCURANDO }

var _estado := Estado.VAGANDO
var _olhando := Vector2.RIGHT
var _jogador: Node2D
var _navegacao: Node
## O relogio, achado pelo grupo igual a navegacao. Pode ser nulo: numa cena de
## teste sem relogio ele so nao enxerga melhor, e nada mais muda.
var _relogio: Node

var _ultima_posicao := Vector2.ZERO
var _sem_progresso := 0.0
var _marca_do_progresso := Vector2.ZERO
## Os corpos que a linha de visao ignora: ele mesmo e os outros zumbis. Sem
## isto, um zumbi na frente do outro corta a visao do de tras e a horda para de
## funcionar justamente quando se junta.
var _ignorados: Array[RID] = []
var _espera_do_toque := 0.0

var _caminho: PackedVector2Array
var _passo := 0
var _recalcular := 0.0
var _alvo_de_vaguear := Vector2.ZERO
var _tempo_vagando := 0.0

func _ready() -> void:
	add_to_group("zumbi")
	var forma := RectangleShape2D.new()
	forma.size = TAMANHO
	($Colisao as CollisionShape2D).shape = forma
	_olhando = Vector2.from_angle(randf_range(0.0, TAU))
	_alvo_de_vaguear = global_position

func _physics_process(delta: float) -> void:
	if _jogador == null:
		# Pelo grupo, para nao depender de onde o jogador esta na arvore.
		_jogador = get_tree().get_first_node_in_group("jogador") as Node2D
		if _jogador == null:
			return
	if _navegacao == null:
		_navegacao = get_tree().get_first_node_in_group("navegacao")
	if _ignorados.is_empty():
		# Preenchido aqui e nao no _ready por dois motivos: no _ready do
		# primeiro zumbi os outros ainda nao existem, e a noite traz mais - o
		# cenario zera esta lista a cada um que chega.
		_ignorados.append(get_rid())
		for outro in get_tree().get_nodes_in_group("zumbi"):
			if outro != self:
				_ignorados.append((outro as CollisionObject2D).get_rid())

	_espera_do_toque = maxf(0.0, _espera_do_toque - delta)
	_decidir(delta)

	var direcao := _direcao_do_estado(delta)
	var velocidade := VELOCIDADE_VAGANDO if _estado == Estado.VAGANDO else VELOCIDADE_PERSEGUINDO
	velocity = direcao * velocidade
	move_and_slide()

	if velocity.length() > 4.0:
		_olhando = velocity.normalized()
	_tocar_no_jogador()
	queue_redraw()

# --------------------------------------------------------------------- decisao

func _decidir(delta: float) -> void:
	if _ve_o_jogador():
		if _estado != Estado.PERSEGUINDO:
			_chamar_a_horda()
		_estado = Estado.PERSEGUINDO
		_ultima_posicao = _jogador.global_position
		return

	if _estado == Estado.PERSEGUINDO:
		# Perdeu de vista: continua indo para onde viu por ultimo.
		_comecar_a_procurar()
		return

	if _estado != Estado.PROCURANDO:
		return

	if global_position.distance_to(_ultima_posicao) < 40.0:
		# Chegou onde viu por ultimo e nao achou ninguem.
		_desistir()
		return
	if global_position.distance_to(_marca_do_progresso) > PASSO_MINIMO:
		_marca_do_progresso = global_position
		_sem_progresso = 0.0
		return
	_sem_progresso += delta
	if _sem_progresso > SEGUNDOS_SEM_PROGRESSO:
		_desistir()

func _comecar_a_procurar() -> void:
	_estado = Estado.PROCURANDO
	_sem_progresso = 0.0
	_marca_do_progresso = global_position

func _desistir() -> void:
	_estado = Estado.VAGANDO
	_caminho = PackedVector2Array()

## Ve num cone, e **parede corta**. E o que faz entrar numa casa quebrar a
## perseguicao - e o que faz ficar dentro dela com ele nao quebrar.
## Ate onde ele ve agora, contando a noite.
##
## O relogio e procurado aqui, e nao no _physics_process, porque isto e
## publico: a ferramenta de conferencia pergunta antes de o primeiro quadro de
## fisica rodar, e antes desta mudanca a resposta vinha como se fosse dia. Foi
## a unica falha de verdade que a conferencia da noite achou.
func alcance_da_vista() -> float:
	if _relogio == null:
		_relogio = get_tree().get_first_node_in_group("relogio")
	if _relogio == null:
		return ALCANCE_DA_VISTA
	return ALCANCE_DA_VISTA * (1.0 + VISTA_A_MAIS_DE_NOITE * _relogio.noite())

func _ve_o_jogador() -> bool:
	var para := _jogador.global_position - global_position
	if para.length() > alcance_da_vista():
		return false
	if absf(rad_to_deg(para.angle_to(_olhando))) > ABERTURA_DA_VISTA / 2.0:
		return false

	var consulta := PhysicsRayQueryParameters2D.create(
		global_position, _jogador.global_position)
	consulta.exclude = _ignorados
	var batida := get_world_2d().direct_space_state.intersect_ray(consulta)
	# Se a primeira coisa no caminho nao e o jogador, tem parede (ou movel) no
	# meio.
	return not batida.is_empty() and batida["collider"] == _jogador

## Avisa quem esta vagando por perto. Um zumbi vira tres sem sistema de onda.
func _chamar_a_horda() -> void:
	for outro in get_tree().get_nodes_in_group("zumbi"):
		if outro == self or not outro is Node2D:
			continue
		if global_position.distance_to((outro as Node2D).global_position) > ALCANCE_DO_CHAMADO:
			continue
		outro.foi_chamado(_jogador.global_position)

## Chamado pelo cenario quando nasce zumbi novo - a noite traz mais. A lista se
## refaz no proximo quadro de fisica.
func esquecer_quem_ignorar() -> void:
	_ignorados.clear()

## Chamado por outro zumbi que enxergou o jogador.
func foi_chamado(onde: Vector2) -> void:
	if _estado == Estado.PERSEGUINDO:
		return
	_ultima_posicao = onde
	_caminho = PackedVector2Array()
	_comecar_a_procurar()

# ------------------------------------------------------------------ movimento

func _direcao_do_estado(delta: float) -> Vector2:
	if _estado == Estado.VAGANDO:
		return _vaguear(delta)
	return _seguir(delta, _ultima_posicao)

## Arrasta-se sem rumo, mudando de alvo de vez em quando ou quando trava. Sem
## caminho: zumbi vagando esbarrar na parede e virar e o comportamento certo.
func _vaguear(delta: float) -> Vector2:
	_tempo_vagando -= delta
	var chegou := global_position.distance_to(_alvo_de_vaguear) < 40.0
	if _tempo_vagando <= 0.0 or chegou or (velocity.length() < 8.0 and _tempo_vagando < 2.2):
		_tempo_vagando = randf_range(2.5, 6.0)
		_alvo_de_vaguear = global_position + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(120.0, 420.0)
	return global_position.direction_to(_alvo_de_vaguear)

## Segue o caminho da grade A*. E isto que faz ele achar o vao da porta em vez
## de encalhar na parede da frente.
func _seguir(delta: float, destino: Vector2) -> Vector2:
	if _navegacao == null:
		return global_position.direction_to(destino)

	_recalcular -= delta
	if _recalcular <= 0.0 or _caminho.is_empty():
		_recalcular = SEGUNDOS_ENTRE_RECALCULOS
		_caminho = _navegacao.caminho(global_position, destino)
		_passo = 0

	while _passo < _caminho.size() and global_position.distance_to(_caminho[_passo]) < TOLERANCIA_DO_PASSO:
		_passo += 1
	if _passo >= _caminho.size():
		# Acabou o caminho: vai reto no destino. Devolver ZERO aqui fazia ele
		# parar por ate SEGUNDOS_ENTRE_RECALCULOS a cada vez que chegava na
		# ponta, e ele andava a menos da metade da velocidade dele.
		return global_position.direction_to(destino)
	return global_position.direction_to(_caminho[_passo])

# --------------------------------------------------------------------- toque

## Nao existe atacar de volta. O toque interrompe o vasculho e tira vida, e a
## resposta e sair de perto.
func _tocar_no_jogador() -> void:
	if _espera_do_toque > 0.0:
		return
	if global_position.distance_to(_jogador.global_position) > DISTANCIA_DO_TOQUE:
		return
	_espera_do_toque = ESPERA_ENTRE_TOQUES
	_jogador.levar_dano(DANO, global_position.direction_to(_jogador.global_position))

# -------------------------------------------------------------------- desenho

func _draw() -> void:
	if MOSTRAR_A_VISTA and _estado != Estado.PERSEGUINDO:
		_desenhar_o_cone()

	var caixa := Rect2(-TAMANHO / 2.0, TAMANHO)
	draw_rect(caixa, COR_PERSEGUINDO if _estado == Estado.PERSEGUINDO else COR)
	draw_rect(caixa, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)

	# A cara, para dar para ver para onde ele esta olhando.
	var frente := _olhando.rotated(-rotation) * (TAMANHO.y / 2.0 - 6.0)
	draw_circle(frente, 5.0, COR_DA_CARA)

func _desenhar_o_cone() -> void:
	var meio := _olhando.rotated(-rotation).angle()
	var metade := deg_to_rad(ABERTURA_DA_VISTA / 2.0)
	var pontos := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		var angulo := meio - metade + (metade * 2.0) * (float(i) / 12.0)
		pontos.append(Vector2.from_angle(angulo) * alcance_da_vista())
	draw_colored_polygon(pontos, COR_DA_VISTA)
