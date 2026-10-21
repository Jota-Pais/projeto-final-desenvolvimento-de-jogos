extends Area2D
## A porta da sua casa: a unica porta do mapa que nao se vasculha. Encoste e
## segure E para entrar e encerrar o dia na rua.
##
## E aqui que a rua acaba e a casa comeca. Esta porta nao sabe nada do que tem
## do outro lado - so chama Travessia.entrar_em_casa(). Quem for fazer o modo
## Casa nao precisa tocar neste arquivo.
##
## ## Ela fica na fachada, e nao la dentro (15/09/2026)
##
## Ate esta data a porta ficava num quarto do fundo - era a porta do porao, e
## para chegar nela voce entrava em casa, atravessava a sala e o corredor. A
## fantasia era boa e o ritmo era ruim: **chegar em casa e o alivio do ciclo**,
## e a travessia de comodo so adiava o alivio. Com zumbi atras, adiava dentro
## de casa, que e o pior lugar para descobrir que a porta ainda esta longe.
##
## Agora ela e o vao da fachada, pelo `Construcao.porta_de()` - a mesma porta
## que todo predio do mapa tem, so que nesta se entra em vez de se vasculhar. O
## lugar dela continua onde estava na historia (era o porao; desde 16/10/2026
## e o quarto): ele e do modo Casa, e e o que voce ve do outro lado.
##
## ## Ela e solida, e e por isso que ela e a unica entrada (16/09/2026)
##
## **Ela fecha o vao inteiro** (TAMANHO.x e o Construcao.VAO), e a sua casa nao
## tem outra abertura. Nao da para atravessar a porta a pe: o unico jeito de
## entrar e segurar E nela, e o que entra e a **cena da casa**, nao o interior
## do predio.
##
## Isso importa mais do que parece. Entrar em casa **encerra o dia na rua** - e
## a travessia entre os dois modos do jogo, e nao uma passagem de comodo. Se
## desse para atravessar o vao andando, o predio teria dois significados ao
## mesmo tempo: um lugar onde se anda e o gesto que acaba o dia. Como bloco
## solido, so sobra o gesto.
##
## Por isso tambem **o jogador nasce na calcada**, e nao la dentro: com a porta
## fechada, nascer dentro seria nascer trancado. Ver
## Mapa.onde_o_jogador_nasce().
##
## O interior da sua casa continua desenhado e continua embaixo do telhado -
## nunca se ve, e nao precisa: quem entra vai para o modo Casa, que e outra
## cena e outra arte.
##
## Segurar em vez de apertar e de proposito: e a chave na fechadura com zumbi
## chegando. Se atrapalhar, e so baixar a DURACAO.

## Segundos de E segurado para entrar. Bem menor que o de vasculhar uma porta
## alheia (5 s) - a sua chave voce tem.
const DURACAO := 1.2

## Mesmo motivo do ALCANCE do vasculhavel: tem que ser maior que a meia altura
## do jogador, senao nao existe lugar onde ele esteja fora da porta e dentro da
## zona ao mesmo tempo. Caiu de 60 para 30 com o corpo, em 20/10/2026.
const ALCANCE := 30.0

## Os avisos escritos no mundo, na mesma escala dos do vasculhavel: com o zoom 2
## da camera ficam do tamanho de antes na tela (20/10/2026).
const ESCALA_DO_AVISO := 0.5

## Na escala do vao de porta do bairro (Construcao.VAO): ela preenche o vao
## inteiro, e e por isso que a largura (a medida ao longo da fachada) e
## exatamente a de la.
##
## **Deixou de ser const em 17/09/2026** (porta em 4 direcoes): deitada
## (100 x 40) quando a fachada da sua casa e norte ou sul, em pe (40 x 100)
## quando e leste ou oeste. `orientar()` decide, chamada por
## `cenario._por_no_lugar` antes de montar as formas.
var TAMANHO := Vector2(100.0, 40.0)

# Tom quente, que e a cor do modo Casa na direcao de arte. Numa rua inteira
# cinza e a pista mais barata de "e aqui que voce volta".
const PORTA := preload("res://rua/arte/predios/porta.png")
const ESCALA_DA_PORTA := 2.0
const TINTA_DA_PORTA := Color(1.25, 1.05, 0.8)
const COR_DA_SOLEIRA := Color(0.0, 0.0, 0.0, 0.25)
const COR_DA_LUZ := Color(0.95, 0.72, 0.38, 0.16)
const COR_DA_BARRA := Color("e8b061")
const COR_FUNDO_DA_BARRA := Color("2a211a")
const COR_DO_AVISO := Color("f2ddba")

## So para perguntar se o E agora e de um movel (20/10/2026): zona de E que
## cruza a de um movel fica com o movel. Ver Vasculhavel._com_o_jogador.
const Vasculhavel := preload("res://rua/vasculhavel.gd")

var _progresso := 0.0
var _jogador_dentro := false
var _entrando := false
## O E que enche a porta tem que ter sido apertado aqui, com a porta livre:
## quem vinha segurando E num movel e acabou de esvaziar ele nao entra em casa
## sem querer, 1,2 s depois.
var _segurando := false
## A porta livre: o jogador na zona e nenhum movel com o E dele.
var _livre := false
## Para que lado a fachada olha - e para la que a luz vaza, e o aviso vai para
## o outro lado, o de dentro, que e onde o boneco nao fica.
var _lado := "sul"

func _ready() -> void:
	_montar_formas()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

## Chamado por `cenario._por_no_lugar` antes de posicionar a porta: decide se
## o vao e deitado ou em pe, e remonta as formas de colisao com o tamanho novo.
func orientar(porta_da_casa: String) -> void:
	_lado = porta_da_casa
	TAMANHO = Vector2(40.0, 100.0) if (porta_da_casa == "leste" or porta_da_casa == "oeste") \
		else Vector2(100.0, 40.0)
	_montar_formas()
	queue_redraw()

func _process(delta: float) -> void:
	if _entrando:
		return

	var antes := _progresso
	var estava_livre := _livre
	_livre = _jogador_dentro and not Vasculhavel.ha_o_que_vasculhar_aqui()
	if _livre and Input.is_action_just_pressed("vasculhar"):
		_segurando = true
	if not _livre or not Input.is_action_pressed("vasculhar"):
		_segurando = false
	if _segurando:
		_progresso += delta
		if _progresso >= DURACAO:
			_entrar()
			return
	elif _progresso > 0.0:
		# A porta de casa zera ao soltar, ao contrario do vasculhavel: nao ha
		# nada a acumular numa fechadura.
		_progresso = 0.0

	if _progresso != antes or _livre != estava_livre:
		queue_redraw()

func _entrar() -> void:
	_entrando = true
	print("Entrou em casa - fim do dia %d" % Travessia.dia)
	# O unico jeito bom de acabar o dia, e o unico que passa por aqui.
	Travessia.entrar_em_casa(Travessia.FimDoDia.PELA_PORTA)

## A zona de deteccao e o corpo solido. O corpo tem o tamanho do vao inteiro:
## e ele que faz a porta ser a unica entrada, em vez de um enfeite no meio de
## uma passagem aberta.
func _montar_formas() -> void:
	var deteccao := RectangleShape2D.new()
	deteccao.size = TAMANHO + Vector2.ONE * ALCANCE * 2.0
	($Deteccao as CollisionShape2D).shape = deteccao

	var corpo := RectangleShape2D.new()
	corpo.size = TAMANHO
	($Corpo/Colisao as CollisionShape2D).shape = corpo

func _ao_entrar(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = true
	queue_redraw()

func _ao_sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = false
	queue_redraw()

func _draw() -> void:
	# Luz vazando da porta para a calcada, ao longo da fachada - deitada
	# quando o vao e deitado, em pe quando o vao e em pe (17/09/2026) -, do
	# lado de fora. Ate 20/10/2026 ia sempre para +y ou +x, e a casa nova, de
	# porta norte, ficava com a luz dentro dela, por cima do telhado.
	match _lado:
		"norte":
			draw_rect(Rect2(-TAMANHO.x, -TAMANHO.y / 2.0 - 86.0, TAMANHO.x * 2.0, 90.0), COR_DA_LUZ)
		"leste":
			draw_rect(Rect2(TAMANHO.x / 2.0 - 4.0, -TAMANHO.y, 90.0, TAMANHO.y * 2.0), COR_DA_LUZ)
		"oeste":
			draw_rect(Rect2(-TAMANHO.x / 2.0 - 86.0, -TAMANHO.y, 90.0, TAMANHO.y * 2.0), COR_DA_LUZ)
		_:
			draw_rect(Rect2(-TAMANHO.x, TAMANHO.y / 2.0 - 4.0, TAMANHO.x * 2.0, 90.0), COR_DA_LUZ)

	# A soleira e uma sombra sobre o vao, e a porta e a mesma dos outros
	# predios (rua/arte/predios/porta.png, a do telhado), so que maior e
	# tingida de quente - o retangulo laranja chapado saiu em 14/10/2026.
	var caixa := Rect2(-TAMANHO / 2.0, TAMANHO)
	draw_rect(caixa, COR_DA_SOLEIRA)
	draw_rect(caixa, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)
	var porta := PORTA.get_size() * ESCALA_DA_PORTA
	draw_set_transform(Vector2.ZERO, 0.0 if TAMANHO.x > TAMANHO.y else PI / 2.0)
	draw_texture_rect(PORTA, Rect2(-porta / 2.0, porta), false, TINTA_DA_PORTA)
	draw_set_transform(Vector2.ZERO)

	var fonte := ThemeDB.fallback_font
	# Daqui para baixo e aviso: origem na borda da porta do lado de dentro
	# (a de cima, menos na porta norte, que e a de baixo), cada unidade vale
	# ESCALA_DO_AVISO px de mundo. Do lado de fora ele cairia em cima do boneco.
	var k := ESCALA_DO_AVISO
	var desce := _lado == "norte"
	draw_set_transform(Vector2(0.0, TAMANHO.y / 2.0 if desce else -TAMANHO.y / 2.0), 0.0, Vector2.ONE * k)
	var largura := TAMANHO.x / k
	var esquerda := -largura / 2.0

	if _progresso > 0.0:
		var barra := Rect2(Vector2(esquerda, 10.0 if desce else -18.0), Vector2(largura, 8.0))
		draw_rect(barra, COR_FUNDO_DA_BARRA)
		var cheio := barra
		cheio.size.x = largura * (_progresso / DURACAO)
		draw_rect(cheio, COR_DA_BARRA)
		draw_rect(barra, Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	if _livre:
		draw_string(fonte, Vector2(esquerda, 34.0 if desce else -26.0), "E  entrar em casa",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DO_AVISO)
	else:
		draw_string(fonte, Vector2(esquerda, 20.0 if desce else -12.0), "sua casa",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(COR_DO_AVISO, 0.45))
	draw_set_transform(Vector2.ZERO)
