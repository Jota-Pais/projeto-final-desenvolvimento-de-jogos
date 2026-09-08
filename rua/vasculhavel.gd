extends Area2D
## Um ponto que da para vasculhar: encoste nele e segure E ate a barra encher.
##
## Este arquivo e a core mechanic do jogo - "vasculhar sob pressao". Tudo o que
## vai pressionar o jogador mais adiante (o zumbi chegando, o prazo do dia, a
## fome, a escuridao) pressiona esta mesma acao, e nada disso precisa aparecer
## aqui: quem interrompe chama interromper().
##
## O que diferencia uma lata de lixo de uma porta de casa e so a "duracao" e o
## que sai dentro. Mesmo verbo, custos e recompensas diferentes - e isso que a
## Alfa cobra como "aplicabilidade da core mechanic".

## Emitido quando o vasculho termina. O passo 4 (mochila, itens e documentos)
## se pendura aqui.
signal vasculhado(rotulo: String, achados: Array[String])

## Nome no aviso que aparece em cima ("E  vasculhar Carro").
@export var rotulo := "Caixa"
## Segundos de vasculho ininterrupto para esvaziar.
@export var duracao := 3.0
## O que sai daqui. Provisorio - texto solto so para o teste ter retorno.
@export var achados: Array[String] = []
@export var tamanho := Vector2(64.0, 64.0)
@export var cor := Color("59504a")
## Se bloqueia a passagem. Carro e porta bloqueiam; lata de lixo nao precisa.
@export var solido := true

## Quanto progresso se perde por segundo quando ninguem esta vasculhando.
##
## 0.0 = o progresso fica onde parou, e da para vasculhar em mordidas: chega,
## avanca um pouco, recua quando o zumbi aparece, volta e termina. Um valor
## alto faz cada interrupcao custar tudo.
##
## E a decisao de feel mais importante deste passo. Com 0.0 a pressao vira
## ritmo de avanca-e-recua; com valor alto vira aposta de tudo ou nada. Testar
## os dois antes de escolher.
const DECAIMENTO := 0.0

## Folga em volta do objeto onde o jogador ja alcanca. E ela que obriga a ficar
## parado: sair desta zona interrompe o vasculho sem precisar de regra nenhuma.
##
## Tem que ser maior que a meia altura do jogador (20, num corpo de 28x40),
## senao nao existe lugar onde ele esteja ao mesmo tempo fora do corpo solido e
## dentro da zona - foi assim que a porta encostada na parede da casa ficou
## impossivel de vasculhar por uma janela de 2 px. Se o tamanho do jogador
## mudar, este numero muda junto.
##
## Subiu de 48 para 60 na ampliacao do bairro: com quarto maior da para ser mais
## folgado, e a faixa onde o jogador consegue ficar de pe passou de 28 para
## 40 px.
const ALCANCE := 60.0

const COR_VAZIO := Color("34302d")
const COR_BARRA := Color("c8b78a")
const COR_FUNDO_DA_BARRA := Color("22201e")
const COR_DO_AVISO := Color("e8e2d6")

var _progresso := 0.0
var _jogador_dentro := false
var _vazio := false

func _ready() -> void:
	_montar_formas()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _process(delta: float) -> void:
	if _vazio:
		return

	var antes := _progresso
	if _jogador_dentro and Input.is_action_pressed("vasculhar"):
		_progresso += delta
		if _progresso >= duracao:
			_esvaziar()
			return
	elif _progresso > 0.0:
		_progresso = maxf(0.0, _progresso - DECAIMENTO * delta)

	if _progresso != antes:
		queue_redraw()

## Zera o vasculho em andamento. Quem pressiona o jogador chama isto - o zumbi
## do passo 2 e o primeiro cliente.
func interromper() -> void:
	if _progresso == 0.0:
		return
	_progresso = 0.0
	queue_redraw()

func _esvaziar() -> void:
	_vazio = true
	_progresso = duracao
	vasculhado.emit(rotulo, achados)
	print("%s: %s" % [rotulo, "nada" if achados.is_empty() else ", ".join(achados)])
	queue_redraw()

## As formas saem do "tamanho" em vez de estarem gravadas na cena, para cada
## instancia se ajustar sozinha quando alguem mudar o tamanho no Inspetor.
## Sao formas novas, nao as do .tscn - sub-recurso de cena e compartilhado
## entre as instancias, e mexer nele mexeria em todas.
func _montar_formas() -> void:
	var deteccao := RectangleShape2D.new()
	deteccao.size = tamanho + Vector2.ONE * ALCANCE * 2.0
	($Deteccao as CollisionShape2D).shape = deteccao

	if not solido:
		$Corpo.queue_free()
		return

	var corpo := RectangleShape2D.new()
	corpo.size = tamanho
	($Corpo/Colisao as CollisionShape2D).shape = corpo

func _ao_entrar(corpo: Node2D) -> void:
	# Pelo grupo, e nao por caminho de node: o Corpo solido aqui dentro tambem
	# dispara este sinal, e o jogador pode estar em qualquer lugar da arvore.
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = true
	# Enquanto ele estiver aqui, levar dano interrompe o vasculho. Este arquivo
	# nao sabe que zumbi existe: escuta o jogador, que e quem apanha.
	if corpo.has_signal("atingido") and not corpo.atingido.is_connected(_ao_ser_atingido):
		corpo.atingido.connect(_ao_ser_atingido)
	queue_redraw()

func _ao_sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = false
	if corpo.has_signal("atingido") and corpo.atingido.is_connected(_ao_ser_atingido):
		corpo.atingido.disconnect(_ao_ser_atingido)
	queue_redraw()

func _ao_ser_atingido(_dano: float) -> void:
	interromper()

func _draw() -> void:
	var caixa := Rect2(-tamanho / 2.0, tamanho)
	draw_rect(caixa, COR_VAZIO if _vazio else cor)
	draw_rect(caixa, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)

	var fonte := ThemeDB.fallback_font
	var topo := -tamanho.y / 2.0
	var esquerda := -tamanho.x / 2.0

	if _vazio:
		var saldo := "vazio" if achados.is_empty() else ", ".join(achados)
		draw_string(fonte, Vector2(esquerda, topo - 8.0), saldo,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(COR_DO_AVISO, 0.5))
		return

	if _progresso > 0.0:
		var largura := maxf(tamanho.x, 76.0)
		var barra := Rect2(Vector2(-largura / 2.0, topo - 18.0), Vector2(largura, 8.0))
		draw_rect(barra, COR_FUNDO_DA_BARRA)
		var cheio := barra
		cheio.size.x = largura * (_progresso / duracao)
		draw_rect(cheio, COR_BARRA)
		draw_rect(barra, Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	if _jogador_dentro:
		draw_string(fonte, Vector2(esquerda, topo - 26.0),
			"E  vasculhar %s (%.1fs)" % [rotulo, duracao],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DO_AVISO)
