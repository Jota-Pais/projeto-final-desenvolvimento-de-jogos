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
##  - **pressao sobre a mesma acao** - o toque dele interrompe o vasculho, te
##    empurra e tira vida (DANO por toque; a vida voltou em 30/09/2026). Nao
##    existe atacar de volta; a resposta e sair de perto.
##
## Ele e **mais lento que voce andando** (82,5 contra 140, e 230 correndo). Da
## para sempre fugir, de proposito: o que ele tira nao e vida, e o tempo que
## voce precisava para terminar de vasculhar.
##
## Nao reaproveita nada do `inimigo.gd` da cena de teste, que perseguia em
## linha reta a partir de qualquer distancia e atravessava o mapa inteiro.
##
## ## Ele nao te perde por ter te tocado (30/09/2026)
##
## Queixa do Joao: "quando eles me batem eles estao me perdendo". Era
## verdade, e por tres motivos que se somavam:
##
##  - a cara dele seguia a velocidade. No toque os dois corpos se empurram, a
##    velocidade dele vira para o lado, e voce saia do cone de 110 graus;
##  - fora do cone ele passava a PROCURANDO, e como "onde viu por ultimo" era
##    a 40 px dele, desistia no mesmo quadro - voltava a vagar com voce ao
##    lado;
##  - o empurrao te tira 65 px dele, o bastante para o cone sideways nao te
##    pegar de novo.
##
## Agora quem persegue **olha para voce**, e nao para onde esta andando (o cone
## so decide quem ainda nao te viu); quem acabou de te tocar continua sabendo
## onde voce esta por MEMORIA_DO_TOQUE segundos, parede ou nao; e quem chega
## onde te viu por ultimo e nao te acha **fica olhando em volta** por
## SEGUNDOS_OLHANDO_EM_VOLTA antes de desistir. Perder ele continua possivel:
## parede no meio e distancia. E o que o High Concept pede - entrar numa casa
## quebra a perseguicao -, so que agora e a casa que quebra, nao o tapa.
##
## ## A vida dele (03/10/2026)
##
## Pedido do Joao: "zumbi sofrendo dano e morrendo, eles devem ter uma vida".
## Ate aqui o tiro derrubava de uma vez (ver arma.gd). Agora ele tem
## VIDA_CHEIA, cada projetil tira o `dano` da arma (a Beretta, 20: cinco tiros
## "por enquanto", Joao, 05/10/2026 - vida e dano em unidade de vida, nao em
## balas), o tiro que nao mata o faz recuar e mostrar o dano, e o que mata o
## derruba. O corpo fica no chao SEGUNDOS_NO_CHAO e some - **a nao ser que ele
## carregue algo** (`inventario`): ai fica ate o fim do dia (regra dele,
## 05/10). **O corpo se vasculha** como um movel (segure E): o inventario dele
## e o `achados` de um vasculhavel que nasce em cima do corpo - hoje vazio,
## porque o que um zumbi carrega e decisao de mesa. As animacoes `dano`,
## `morrer` e `toque` entram pela folha (rua/boneco.gd, `tocar()`); enquanto
## nao existem, o codigo mostra um clarao vermelho, a queda de lado (parado na
## pose, nao andando - Joao, 05/10: "nao so ficar caminhando de lado no chao")
## e uma investida de INVESTIDA px no toque. Em 05/10 ele pediu as animacoes
## de ataque e de morto de verdade, geradas no PixelLab (rua/arte/zumbi/).
##
## ## Metade do tamanho e da velocidade (20/10/2026)
##
## Pedido do Joao: "o mundo ta muito pequeno, deixa o personagem e zumbis com
## metade do tamanho e metade da velocidade", com a camera mais perto (zoom 2,
## em jogador.gd). O corpo foi de 30 x 44 para 15 x 22, o desenho para escala
## 0,5 (rua/boneco.gd), as velocidades de 70/165 para 35/82,5, o toque de 48
## para 24 px. A vista (520), o chamado (700) e as distancias do vaguear e da
## chegada cairam pela metade junto, por decisao dele: na tela o zumbi ve, chama
## e anda como antes - so o mundo ficou duas vezes maior em volta dele.

const TAMANHO := Vector2(15.0, 22.0)

const VELOCIDADE_VAGANDO := 35.0
const VELOCIDADE_PERSEGUINDO := 82.5

## Ate onde ele ve, e a abertura do cone. Parede corta a linha de visao.
const ALCANCE_DA_VISTA := 260.0
const ABERTURA_DA_VISTA := 110.0

## Quanto o alcance da vista cresce na noite fechada: 0.35 leva os 260 px a
## 351 px as 05:00, subindo aos poucos a partir das 19:00.
##
## **Nao e realismo** - zumbi nao ve melhor no escuro. E a mesma razao de a rua
## encher: a noite existe para te empurrar pra casa, e ficar invisivel andando
## a noite toda tiraria o aperto dela. Quem le o quanto de noite e o relogio.
const VISTA_A_MAIS_DE_NOITE := 0.35

## Quem enxerga o jogador avisa os zumbis vagando dentro deste raio. E o que
## faz horda se formar sem sistema de onda nenhum.
const ALCANCE_DO_CHAMADO := 350.0

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
const PASSO_MINIMO := 12.0

## Quanto tempo ele fica parado olhando em volta quando chega onde te viu por
## ultimo e nao te acha, antes de voltar a vagar (30/09/2026). Antes desistia
## no mesmo quadro em que chegava - e como "onde viu por ultimo" ficava a
## 40 px dele depois de um toque, desistia com voce do lado. Uma volta inteira
## da cara neste tempo: quem estiver no alcance e sem parede no meio e visto.
const SEGUNDOS_OLHANDO_EM_VOLTA := 2.0

## Por quanto tempo quem acabou de te tocar continua sabendo onde voce esta,
## mesmo sem te ver (30/09/2026). Quem encostou em voce nao precisa de olho:
## e o empurrao, o carro no meio ou a quina da casa nao fazem ele esquecer
## de uma vez.
const MEMORIA_DO_TOQUE := 2.0

const DISTANCIA_DO_TOQUE := 24.0
## O golpe: ele para SEGUNDOS_DO_GOLPE para bater (e a animacao `toque`, ou a
## investida de codigo: o boneco avanca INVESTIDA px do desenho - metade disso
## no mundo, com a escala do boneco - e volta em SEGUNDOS_DA_INVESTIDA).
## Proposta de 05/10/2026 - a parada e o que faz o golpe se ler como golpe, e e
## uma brecha de 0,3 s para sair de perto.
const SEGUNDOS_DO_GOLPE := 0.3
const INVESTIDA := 8.0
const SEGUNDOS_DA_INVESTIDA := 0.25
## Quanto de vida cada toque tira. 12 em 100: nove toques derrubam, e com a
## espera de 1,1 s entre toques um zumbi sozinho leva dez segundos para isso -
## tempo de sobra para sair de perto. Tres zumbis, nao.
const DANO := 12.0
## A espera continua existindo depois que a vida saiu (16/09/2026): sem ela o
## toque interromperia o vasculho todo quadro, e ficar encostado num zumbi seria
## indistinguivel de ficar longe dele - nos dois casos a barra nunca anda.
const ESPERA_ENTRE_TOQUES := 1.1

## A vida dele (03/10/2026), em unidade de vida. Ver o cabecalho; o dano de
## cada arma esta na ficha dela, em arma.gd.
const VIDA_CHEIA := 100.0
## O corpo como vasculhavel: quanto tempo leva para vasculhar (proposta) e o
## tamanho da zona em volta dele, mais ou menos o boneco deitado.
const SEGUNDOS_PARA_VASCULHAR_O_CORPO := 2.0
const TAMANHO_DO_CORPO := Vector2(35.0, 15.0)
const CENA_DO_VASCULHAVEL := preload("res://rua/vasculhavel.tscn")
## O tiro que nao mata: o quanto ele e jogado para tras (some em
## ESPERA_DO_RECUO s) e por quanto tempo fica vermelho.
const FORCA_DO_RECUO := 80.0
const ESPERA_DO_RECUO := 0.2
const SEGUNDOS_DO_DANO := 0.15
const COR_DO_DANO := Color(1.0, 0.35, 0.35)
## A morte: quanto demora a tombar, quanto tempo o corpo fica no chao (Joao,
## 05/10/2026: 60 s; com algo no `inventario`, ate o fim do dia) e quanto
## demora a sumir.
const SEGUNDOS_CAINDO := 0.3
const SEGUNDOS_NO_CHAO := 60.0
const SEGUNDOS_SUMINDO := 1.0
const COR_NO_CHAO := Color(0.55, 0.55, 0.55)
## A barra de vida: as mesmas cores da do jogador (jogador.gd), para ler igual.
const COR_DA_VIDA := Color("c0463c")
const COR_FUNDO_DA_VIDA := Color("241d1c")

const SEGUNDOS_ENTRE_RECALCULOS := 0.4
const TOLERANCIA_DO_PASSO := 26.0

## O gemido (som do Drive, 20/10/2026). Ele geme ao te ver - e o aviso de que
## a perseguicao comecou, antes de voce olhar para ele - e, vagando ou
## procurando, de vez em quando, entre GEMIDO_MINIMO e GEMIDO_MAXIMO segundos.
## Sai do ponto onde ele esta: alem de ALCANCE_DO_GEMIDO px nao se ouve, e e
## o que faz o som dizer de que lado ele vem. **Numeros: proposta.**
const GEMIDO_MINIMO := 6.0
const GEMIDO_MAXIMO := 16.0
const ALCANCE_DO_GEMIDO := 450.0

## Desenha o cone de visao na tela. **Auxilio de prototipo**, nao decisao de
## design: sem ver o cone nao da para entender por que ele te viu ou nao.
const MOSTRAR_A_VISTA := true

const COR_DA_VISTA := Color(0.85, 0.75, 0.45, 0.07)

## O boneco (rua/boneco.gd) desenha o zumbi desde 02/10/2026; ate entao era um
## retangulo verde que ficava ambar perseguindo. A cor saiu junto com ele:
## perseguir agora se ve no passo, que e o mesmo arrastar acelerado (ver
## _animar).
const Boneco := preload("res://rua/boneco.gd")


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
## Quanto ainda dura a memoria do ultimo toque (ver MEMORIA_DO_TOQUE).
var _memoria_do_toque := 0.0
## Quanto falta do golpe em andamento (ver SEGUNDOS_DO_GOLPE): parado batendo.
var _golpeando := 0.0
## Ha quanto tempo ele esta parado olhando em volta onde te viu por ultimo.
var _olhando_em_volta := 0.0

var _caminho: PackedVector2Array
var _passo := 0
var _recalcular := 0.0
var _alvo_de_vaguear := Vector2.ZERO
var _tempo_vagando := 0.0
## Quanto falta para o proximo gemido a toa. Comeca sorteado, para a horda
## nao gemer em coro no primeiro segundo.
var _proximo_gemido := randf_range(0.0, GEMIDO_MAXIMO)

var vida := VIDA_CHEIA
## Levou o tiro que mata: e um corpo no chao, fora do grupo "zumbi" e da fisica.
var morto := false
## O que ele carrega. Um corpo com algo aqui fica ate o fim do dia em vez de
## sumir em SEGUNDOS_NO_CHAO (Joao, 05/10/2026), e e isto que sai quando se
## vascula o corpo. **Nada enche isto ainda**: o que um zumbi carrega e
## decisao de mesa.
var inventario: Array[String] = []
var _recuo := Vector2.ZERO
var _clarao_do_dano: Tween

@onready var _boneco: Boneco = $Boneco


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
	_memoria_do_toque = maxf(0.0, _memoria_do_toque - delta)
	_golpeando = maxf(0.0, _golpeando - delta)
	_decidir(delta)

	var direcao := _direcao_do_estado(delta)
	var velocidade := VELOCIDADE_VAGANDO if _estado == Estado.VAGANDO else VELOCIDADE_PERSEGUINDO
	velocity = direcao * velocidade + _recuo
	move_and_slide()
	_recuo = _recuo.move_toward(Vector2.ZERO, FORCA_DO_RECUO / ESPERA_DO_RECUO * delta)

	_virar(delta)
	_animar()
	_tocar_no_jogador()
	_proximo_gemido -= delta
	if _proximo_gemido <= 0.0 and _estado != Estado.PERSEGUINDO:
		_gemer()
	queue_redraw()

func _gemer() -> void:
	_proximo_gemido = randf_range(GEMIDO_MINIMO, GEMIDO_MAXIMO)
	# Longe demais para se ouvir, nem cria o som (21/10/2026): com dezenas de
	# zumbis vivos em volta, cada gemido sem ninguem para ouvir era um no
	# tocando no vazio. Quem ouve e a camera, que esta no jogador.
	if _jogador == null or global_position.distance_to(_jogador.global_position) > ALCANCE_DO_GEMIDO:
		return
	Som.tocar_em("zumbi", global_position, ALCANCE_DO_GEMIDO, randf_range(0.85, 1.15))

## Para onde a cara aponta, por estado. **Quem persegue olha para voce**, e
## nao para onde esta andando: ate 30/09/2026 a cara seguia a velocidade, e no
## toque os dois corpos se empurram, a velocidade vira para o lado e voce saia
## do cone - ele te perdia por ter te alcancado. Quem procura olha para onde
## vai, e parado no lugar da volta na cara. Quem vaga olha para onde anda.
func _virar(delta: float) -> void:
	match _estado:
		Estado.PERSEGUINDO:
			_olhando = global_position.direction_to(_jogador.global_position)
		Estado.PROCURANDO:
			if _chegou_onde_viu():
				_olhando = _olhando.rotated(TAU * delta / SEGUNDOS_OLHANDO_EM_VOLTA)
			else:
				_olhando = global_position.direction_to(_ultima_posicao)
		_:
			if velocity.length() > 4.0:
				_olhando = velocity.normalized()

## O que o boneco mostra: o `vagar` olhando para `_olhando`, no ritmo da
## velocidade - perseguir e o mesmo arrastar acelerado (decidido 30/09/2026;
## se nao bastar, `scary-walk` custa 8 geracoes). Parado, olhando em volta onde
## te viu por ultimo, e a rotacao parada, que gira junto com a cara.
func _animar() -> void:
	var rapidez := velocity.length()
	if rapidez < 4.0:
		_boneco.mostrar("parado", _olhando)
		return
	_boneco.mostrar("vagar", _olhando, rapidez / VELOCIDADE_VAGANDO)

func _chegou_onde_viu() -> bool:

	return global_position.distance_to(_ultima_posicao) < 20.0

# --------------------------------------------------------------------- decisao

func _decidir(delta: float) -> void:
	# Quem acabou de te tocar sabe onde voce esta, parede ou nao.
	if _ve_o_jogador() or _memoria_do_toque > 0.0:
		if _estado != Estado.PERSEGUINDO:
			_chamar_a_horda()
			_gemer()
		_estado = Estado.PERSEGUINDO
		_ultima_posicao = _jogador.global_position
		return

	if _estado == Estado.PERSEGUINDO:
		# Perdeu de vista: continua indo para onde viu por ultimo.
		_comecar_a_procurar()
		return

	if _estado != Estado.PROCURANDO:
		return

	if _chegou_onde_viu():
		# Chegou onde viu por ultimo e nao achou ninguem: olha em volta um
		# pouco antes de desistir. A cara gira em `_virar`; aqui so se conta
		# o tempo.
		_olhando_em_volta += delta
		if _olhando_em_volta > SEGUNDOS_OLHANDO_EM_VOLTA:
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
	_olhando_em_volta = 0.0
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

## Emitido quando o tiro que mata acerta. O cenario escuta para nao fazer
## nascer outro no mesmo lugar hoje - senao atirar seria inutil.
signal morreu

## Levou um tiro: tira `quanto` da vida. `direcao_do_tiro` e para onde a bala
## ia, e e para la que ele recua ou tomba. O tiro que nao mata mostra o dano, o
## que mata derruba (ver "A vida dele" no cabecalho). Um corpo no chao nao leva
## tiro: saiu do grupo "zumbi" e da fisica.
func levar_tiro(quanto: float, direcao_do_tiro := Vector2.ZERO) -> void:
	if morto:
		return
	vida = maxf(0.0, vida - quanto)
	if vida > 0.0:
		_sofrer(direcao_do_tiro)
	else:
		_morrer(direcao_do_tiro)

## O tiro que nao mata: recua um pouco e mostra o dano - a animacao `dano` se
## a folha tiver, senao o clarao vermelho que volta ao normal em
## SEGUNDOS_DO_DANO (proposta de 03/10/2026). Ele nao precisa "saber" que foi
## baleado: o estrondo ja chama todo mundo, ele incluido.
func _sofrer(direcao_do_tiro: Vector2) -> void:
	_recuo = direcao_do_tiro * FORCA_DO_RECUO
	queue_redraw()
	if _boneco.tocar("dano", _olhando):
		return
	if _clarao_do_dano != null:
		_clarao_do_dano.kill()
	_boneco.modulate = COR_DO_DANO
	_clarao_do_dano = create_tween()
	_clarao_do_dano.tween_property(_boneco, "modulate", Color.WHITE, SEGUNDOS_DO_DANO)

## O tiro que mata. Ele vira corpo: sai do grupo "zumbi" (ninguem mais o chama,
## conta ou acerta), a colisao some (o raio da arma e a linha de visao dos
## outros passam por cima, e o jogador anda por cima dele) e a fisica para. A
## animacao `morrer` toca se a folha tiver; senao ele tomba (`_cair`). Depois
## de SEGUNDOS_NO_CHAO o corpo some em SEGUNDOS_SUMINDO - se nao carrega nada;
## com algo no `inventario` fica ate a cena da rua acabar com o dia. O tween e
## do no: morre com ele se a cena trocar antes.
##
## O corpo e vasculhavel (05/10/2026, Joao: "faz com que tenha como acessar o
## inventario dele"): nasce um `Vasculhavel` em cima dele com `achados` sendo
## o proprio `inventario` - o mesmo objeto, nao copia -, sem caixa desenhada
## (o desenho e o boneco caido) e sem corpo solido (anda-se por cima). Quem o
## liga a mochila e ao relogio e o cenario, no sinal `morreu`, como faz com os
## moveis - por isso o corpo nasce antes do sinal.
func _morrer(direcao_do_tiro: Vector2) -> void:
	morto = true
	remove_from_group("zumbi")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	set_physics_process(false)
	queue_redraw()
	var corpo := CENA_DO_VASCULHAVEL.instantiate()
	corpo.name = "Corpo"
	corpo.rotulo = "corpo"
	corpo.duracao = SEGUNDOS_PARA_VASCULHAR_O_CORPO
	corpo.tamanho = TAMANHO_DO_CORPO
	corpo.solido = false
	corpo.desenhar_caixa = false
	corpo.achados = inventario
	add_child(corpo)
	morreu.emit()
	if _clarao_do_dano != null:
		_clarao_do_dano.kill()
	var queda := create_tween()
	if not _boneco.tocar("morrer", _olhando):
		# Sem `morrer` na folha, o corpo para na pose parada antes de tombar:
		# tombar com o `vagar` rodando deixava o morto "caminhando de lado no
		# chao" (Joao, 05/10/2026).
		_boneco.mostrar("parado", _olhando)
		_cair(queda, direcao_do_tiro)
		queda.tween_callback(_deitar)
	if not inventario.is_empty():
		return
	queda.tween_interval(SEGUNDOS_NO_CHAO)
	queda.tween_property(_boneco, "modulate:a", 0.0, SEGUNDOS_SUMINDO)
	queda.tween_callback(queue_free)

## A queda de codigo, enquanto nao ha `morrer` na folha: o boneco tomba de lado
## em SEGUNDOS_CAINDO (a cabeca vai para onde a bala ia) e escurece. Boneco em
## pe deitado a 90 graus e o truque de sempre do top-down; de frente ou de
## costas nao ha como deitar sem desenho novo, entao tiro vindo do norte ou do
## sul tomba para um lado qualquer.
func _cair(queda: Tween, direcao_do_tiro: Vector2) -> void:
	var lado := signf(direcao_do_tiro.x)
	if absf(direcao_do_tiro.x) < 0.3:
		lado = 1.0 if randf() < 0.5 else -1.0
	_lado_da_queda = lado
	queda.tween_property(_boneco, "rotation", lado * TAU / 4.0, SEGUNDOS_CAINDO).set_ease(Tween.EASE_IN)
	queda.parallel().tween_property(_boneco, "modulate", COR_NO_CHAO, SEGUNDOS_CAINDO)

## Para que lado a queda de codigo tombou: +1 cabeca para a direita, -1 para a
## esquerda.
var _lado_da_queda := 1.0

## No fim da queda de codigo, se a folha tem o morto no chao - o ultimo quadro
## do `morrer` no sul (gerado em 05/10/2026) -, o boneco passa a ser esse
## quadro: um corpo deitado vale para as oito direcoes, porque no chao nao ha
## perspectiva nova. Esse quadro deita com a cabeca para a esquerda; se a
## queda tombou para a direita, espelha. A rotacao da queda volta a zero,
## porque o quadro ja esta deitado. Sem ele, fica a pose parada deitada.
## Desde 14/10/2026 o `morrer` existe nas oito direcoes, entao isto so roda
## com uma folha que nao o tenha (uma variante do Renan ainda sem a queda).
func _deitar() -> void:
	if not _boneco.ultimo_quadro("morrer", Vector2.DOWN):
		return
	_boneco.rotation = 0.0
	_boneco.flip_h = _lado_da_queda > 0.0

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
	if _golpeando > 0.0:
		# Parado batendo (ver SEGUNDOS_DO_GOLPE).
		return Vector2.ZERO
	if _estado == Estado.VAGANDO:
		return _vaguear(delta)
	if _estado == Estado.PROCURANDO and _chegou_onde_viu():
		# Parado, olhando em volta.
		return Vector2.ZERO
	return _seguir(delta, _ultima_posicao)

## Arrasta-se sem rumo, mudando de alvo de vez em quando ou quando trava. Sem
## caminho: zumbi vagando esbarrar na parede e virar e o comportamento certo.
func _vaguear(delta: float) -> Vector2:
	_tempo_vagando -= delta
	var chegou := global_position.distance_to(_alvo_de_vaguear) < 20.0
	if _tempo_vagando <= 0.0 or chegou or (velocity.length() < 4.0 and _tempo_vagando < 2.2):
		_tempo_vagando = randf_range(2.5, 6.0)
		_alvo_de_vaguear = global_position + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(60.0, 210.0)
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

## Nao existe atacar de volta. O toque tira vida, empurra e interrompe o
## vasculho, e a resposta e sair de perto.
func _tocar_no_jogador() -> void:
	if _espera_do_toque > 0.0:
		return
	if global_position.distance_to(_jogador.global_position) > DISTANCIA_DO_TOQUE:
		return
	_espera_do_toque = ESPERA_ENTRE_TOQUES
	_memoria_do_toque = MEMORIA_DO_TOQUE
	_jogador.levar_dano(DANO, global_position.direction_to(_jogador.global_position))
	_golpear()

## O golpe que se ve: ele para por SEGUNDOS_DO_GOLPE e toca a animacao
## `toque` se a folha tiver (pedida pelo Joao em 05/10/2026: "uma animacao de
## ataque pro zumbi"); senao, a investida de codigo - o boneco avanca INVESTIDA
## px na direcao da cara e volta.
func _golpear() -> void:
	_golpeando = SEGUNDOS_DO_GOLPE
	if _boneco.tocar("toque", _olhando):
		return
	var investida := create_tween()
	investida.tween_property(_boneco, "position", _olhando * INVESTIDA * Boneco.ESCALA, SEGUNDOS_DA_INVESTIDA / 2.0) \
		.set_ease(Tween.EASE_OUT)
	investida.tween_property(_boneco, "position", Vector2.ZERO, SEGUNDOS_DA_INVESTIDA / 2.0)

# -------------------------------------------------------------------- desenho

## O cone de visao e a barra de vida: o corpo e a cara sao o boneco. O cone
## continua sendo auxilio de prototipo (MOSTRAR_A_VISTA). Um corpo no chao nao
## desenha nada.
func _draw() -> void:
	if morto:
		return
	if MOSTRAR_A_VISTA and _estado != Estado.PERSEGUINDO:
		_desenhar_o_cone()
	if vida < VIDA_CHEIA:
		_desenhar_a_vida()

## Barra de vida em cima da cabeca, so depois do primeiro tiro - a mesma do
## jogador, no mesmo lugar e do mesmo tamanho (proposta de 03/10/2026; metade
## em 20/10, junto com o boneco: com o zoom 2 fica do tamanho de antes na tela).
func _desenhar_a_vida() -> void:
	var barra := Rect2(-8.0, -33.0, 16.0, 2.5)
	draw_rect(barra, COR_FUNDO_DA_VIDA)
	var cheio := barra
	cheio.size.x = barra.size.x * (vida / VIDA_CHEIA)
	draw_rect(cheio, COR_DA_VIDA)


func _desenhar_o_cone() -> void:
	var meio := _olhando.rotated(-rotation).angle()
	var metade := deg_to_rad(ABERTURA_DA_VISTA / 2.0)
	var pontos := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		var angulo := meio - metade + (metade * 2.0) * (float(i) / 12.0)
		pontos.append(Vector2.from_angle(angulo) * alcance_da_vista())
	draw_colored_polygon(pontos, COR_DA_VISTA)
