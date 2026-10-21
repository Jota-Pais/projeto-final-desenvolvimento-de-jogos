extends Area2D
## Um ponto que da para vasculhar: encoste nele e segure E ate a barra encher.
##
## Este arquivo e a core mechanic do jogo - "vasculhar sob pressao". Tudo o que
## vai pressionar o jogador mais adiante (o zumbi chegando, o prazo do dia, a
## escuridao) pressiona esta mesma acao, e nada disso precisa aparecer
## aqui: quem interrompe chama interromper().
##
## O que diferencia uma lata de lixo de uma porta de casa e so a "duracao" e o
## que sai de dentro - e desde 30/09/2026 o que sai e sempre a mesma coisa,
## balas para a arma (mais o documento, onde o mapa pos um). Mesmo verbo,
## custos diferentes - e isso que a Alfa cobra como "aplicabilidade da core
## mechanic". Desde 05/10/2026 o corpo de um zumbi tambem e um destes
## (zumbi.gd): sem caixa desenhada, com o inventario dele como `achados`.

## Le so a tabela de documentos, para saber qual achado desenhar com destaque.
const Construcao := preload("res://rua/construcao.gd")
## So para a guarda do `aberta`: com a tela da mochila na frente, o E que larga
## uma coisa nao pode vasculhar o movel encostado ao mesmo tempo.
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")

## Emitido quando o vasculho termina. Quem escuta e a mochila da rua, e e ela
## quem separa documento de balas.
signal vasculhado(rotulo: String, achados: Array[String])

## Emitido enquanto o vasculho avanca, com quanto ele avancou neste quadro.
##
## Quem escuta hoje e o relogio do dia: vasculhar gasta luz. Este arquivo
## continua sem saber que existe relogio - quem liga os dois e o cenario, que e
## quem cria o movel. Mesmo arranjo do zumbi: a pressao chega de fora.
signal vasculhando(segundos: float)

## Nome no aviso que aparece em cima ("E  vasculhar Carro").
@export var rotulo := "Caixa"
## Segundos de vasculho ininterrupto para esvaziar.
@export var duracao := 3.0
## O que sai daqui: balas (Construcao.MUNICAO, uma entrada por caixinha) e o
## documento, onde o mapa declarou um.
@export var achados: Array[String] = []
## Se ele ja foi vasculhado num dia anterior. O mundo nao repoe, entao um
## movel esvaziado ontem nasce vazio hoje - quem sabe disso e o cenario, que le
## o Travessia.
@export var nasce_vazio := false
@export var tamanho := Vector2(64.0, 64.0)
@export var cor := Color("59504a")
## Se bloqueia a passagem. Carro e porta bloqueiam; lata de lixo nao precisa.
@export var solido := true
## Se desenha a caixa do greybox. O corpo de zumbi nao desenha: o boneco caido
## ja e o desenho, e aqui ficam so a barra, o aviso e o que saiu.
@export var desenhar_caixa := true
## O desenho do movel, quando existe um gerado (rua/arte/objetos/<tipo>.png,
## 14/10/2026). Sem ele, a caixa do greybox. O
## sprite e visto de cima com a frente para baixo e sai do tamanho que veio: o
## pe dele na borda de baixo da pegada (`tamanho`), e o que sobra de altura
## sobe pela parede atras - e assim que a vista de cima inclinada mostra uma
## coisa alta.
@export var desenho: Texture2D
## Giro do desenho, em radianos: 0 e como veio (frente para baixo); -PI/2 e
## PI/2 poem a frente para leste e para oeste, para o movel encostado numa
## parede de lado. Quem decide e o cenario, que sabe onde esta a parede.
@export var giro := 0.0
## Espelha o desenho, para dois carros iguais na mesma rua nao serem o mesmo
## carro.
@export var espelhado := false
## Tinta multiplicada sobre o desenho: e o que distingue os quatro armarios
## especiais, que partilham um sprite de armario de metal (a cor da ficha,
## normalizada pelo cenario).
@export var tinta := Color.WHITE

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
## Tem que ser maior que a meia altura do jogador (10, num corpo de 14x20),
## senao nao existe lugar onde ele esteja ao mesmo tempo fora do corpo solido e
## dentro da zona - foi assim que a porta encostada na parede da casa ficou
## impossivel de vasculhar por uma janela de 2 px. Se o tamanho do jogador
## mudar, este numero muda junto: era 60 com o corpo de 28x40, e caiu para 30
## com ele em 20/10/2026.
const ALCANCE := 30.0

## Os avisos escritos no mundo - a barra, o "E vasculhar" e o que saiu - sao
## desenhados nesta escala desde 20/10/2026: com o zoom 2 da camera
## (jogador.gd) ficam do tamanho de antes na tela, e a letra continua nitida
## (fonte 14 sob 0,5 e zoom 2 sai 1:1).
const ESCALA_DO_AVISO := 0.5

const COR_VAZIO := Color("34302d")
## O desenho de um movel ja vasculhado escurece: nao da para abrir gaveta num
## sprite, e o jogador precisa ler de longe o que ja rendeu.
const TINTA_DO_VAZIO := Color(0.5, 0.5, 0.5)
## Quanto o desenho pode subir alem da pegada, para tras: a espessura de uma
## parede (Construcao.PAREDE) - o movel encosta nela e o tampo fica por cima
## dela, nao fora dela.
const FOLGA_SOBRE_A_PAREDE := 20.0
const COR_BARRA := Color("c8b78a")
const COR_FUNDO_DA_BARRA := Color("22201e")
const COR_DO_AVISO := Color("e8e2d6")
## O documento tem cor propria, e a mesma do modo Casa. O one-pager pede que
## ele seja "visualmente distinto dos outros itens, com brilho": e o que a cura
## conta, e tem que dar para ver de longe qual movel valeu a pena.
const COR_DO_DOCUMENTO := Color("e8b061")

var _progresso := 0.0
var _jogador_dentro := false

## Sem nada dentro.
var _vazio := false

## Os vasculhaveis com o jogador dentro e alguma coisa para render, por id de
## instancia (20/10/2026). A porta de casa pergunta antes de encher: E numa
## zona que cruza a de um movel fica com o movel, e entrar em casa - que acaba
## o dia - pede um E novo, longe dele. Sem isto, segurar E no carro parado ao
## lado da porta da casa nova entrava em casa no meio do vasculho.
static var _com_o_jogador := {}

## Se o E agora vasculha alguma coisa (ver _com_o_jogador).
static func ha_o_que_vasculhar_aqui() -> bool:
	return not _com_o_jogador.is_empty()

func _atualizar_presenca() -> void:
	if _jogador_dentro and not _vazio:
		_com_o_jogador[get_instance_id()] = true
	else:
		_com_o_jogador.erase(get_instance_id())

func _exit_tree() -> void:
	_com_o_jogador.erase(get_instance_id())

## O que saiu daqui quando foi vasculhado - para o movel vazio dizer o que
## rendeu. E uma copia: `achados` e esvaziado por quem escuta o sinal.
var _saiu: Array[String] = []

func _ready() -> void:
	if nasce_vazio:
		# Vasculhado num dia anterior. Nao se recusa o vasculho por regra: ele
		# ja esta vazio, e a barra nem comeca.
		achados = []
		_vazio = true
		_progresso = duracao
	# Pixel art: nada de borrar o desenho quando a camera aproxima.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_montar_formas()
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _process(delta: float) -> void:
	if _vazio:
		return
	# Com a tela da mochila aberta o jogador esta escolhendo o que carrega, e
	# nao vasculhando. Sem esta guarda o mesmo E faria as duas coisas.
	if TelaDaMochila.aberta:
		return

	var antes := _progresso
	if _jogador_dentro and Input.is_action_pressed("vasculhar"):
		_progresso += delta
		vasculhando.emit(delta)
		if _progresso >= duracao:
			_esvaziar()
			return
	elif _progresso > 0.0:
		_progresso = maxf(0.0, _progresso - DECAIMENTO * delta)

	if _progresso != antes:
		queue_redraw()

## Zera o vasculho em andamento. Quem pressiona o jogador chama isto - o zumbi
## e o primeiro cliente.
func interromper() -> void:
	if _progresso == 0.0:
		return
	_progresso = 0.0
	queue_redraw()

## Fim do vasculho: quem escuta leva tudo - balas para o cinto, documento para
## a mochila -, e o movel fica vazio. Para o dia seguinte ele conta como
## vasculhado: quem anota e o cenario, no sinal, e o mundo nao repoe.
##
## Ate 30/09/2026 existia "sobra": o que nao cabia na mochila de 12 vagas
## ficava aqui e dava para voltar buscar. Sem vaga que falte (so documento
## entra, e balas vao para o cinto), nao ha o que sobrar.
func _esvaziar() -> void:
	_saiu = achados.duplicate()
	vasculhado.emit(rotulo, achados)
	print("%s: %s" % [rotulo, "nada" if _saiu.is_empty() else ", ".join(_saiu)])
	achados.clear()
	_vazio = true
	_atualizar_presenca()
	_progresso = duracao
	queue_redraw()

## Poe uma coisa dentro deste ponto depois de ele ja existir na cena.
##
## Quem chama e o cenario, quando o jogador larga um documento no chao: a pilha
## do chao e um vasculhavel como outro qualquer, e e assim que pegar de volta
## funciona sem inventar um segundo tipo de objeto.
func receber(achado: String) -> void:
	achados.append(achado)
	_saiu = []
	_vazio = false
	_atualizar_presenca()
	_progresso = 0.0
	queue_redraw()

## O que saiu do movel, escrito em cima dele depois de vasculhado. Documento em
## cima, na cor dele e com uma marca ao lado; as balas embaixo, contadas por
## calibre.
func _desenhar_o_que_saiu(fonte: Font, esquerda: float, base: float) -> void:
	var por_calibre := {}
	var achou_documento := false
	for achado in _saiu:
		if Construcao.e_documento(achado):
			achou_documento = true
			draw_string(fonte, Vector2(esquerda + 16.0, base - 18.0), achado,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DO_DOCUMENTO)
		elif Construcao.e_municao(achado):
			por_calibre[achado] = por_calibre.get(achado, 0) + Construcao.MUNICAO_POR_ACHADO

	if achou_documento:
		# A "marca com brilho" do one-pager, na medida do greybox: um quadrado
		# na cor do documento com um halo em volta.
		var marca := Rect2(esquerda, base - 28.0, 11.0, 11.0)
		draw_rect(marca.grow(4.0), Color(COR_DO_DOCUMENTO, 0.22))
		draw_rect(marca, COR_DO_DOCUMENTO)

	var saldo := "vazio"
	if not por_calibre.is_empty():
		var partes := PackedStringArray()
		for achado in por_calibre:
			partes.append("%d %s" % [por_calibre[achado], achado])
		saldo = " · ".join(partes)
	draw_string(fonte, Vector2(esquerda, base), saldo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(COR_DO_AVISO, 0.5))

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
	_atualizar_presenca()
	# Enquanto ele estiver aqui, o toque do zumbi interrompe o vasculho. Este
	# arquivo nao sabe que zumbi existe: escuta o jogador, que e quem apanha.
	if corpo.has_signal("atingido") and not corpo.atingido.is_connected(_ao_ser_atingido):
		corpo.atingido.connect(_ao_ser_atingido)
	queue_redraw()

func _ao_sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_jogador_dentro = false
	_atualizar_presenca()
	if corpo.has_signal("atingido") and corpo.atingido.is_connected(_ao_ser_atingido):
		corpo.atingido.disconnect(_ao_ser_atingido)
	queue_redraw()

func _ao_ser_atingido() -> void:
	interromper()

## O sprite com o pe na borda de baixo da pegada, no quadro girado: com giro
## de 90 graus a pegada que ele ve e a transposta, porque o `tamanho` ja veio
## transposto do cenario (Construcao.tamanho_do_movel, mapa.gd "deitado").
func _desenhar_o_desenho() -> void:
	var pegada := tamanho if absf(sin(giro)) < 0.5 else Vector2(tamanho.y, tamanho.x)
	var tam := desenho.get_size()
	# O pe do desenho na borda de baixo da pegada - mas um desenho mais alto
	# que a pegada (tampo + frente, na vista inclinada) nao pode atravessar a
	# parede atras dele e aparecer do lado de fora do predio: no maximo cobre
	# a parede (FOLGA_SOBRE_A_PAREDE), e o que sobra desce para dentro da
	# sala, onde e so a frente dele pintada no chao.
	var topo := maxf(pegada.y / 2.0 - tam.y, -pegada.y / 2.0 - FOLGA_SOBRE_A_PAREDE)
	draw_set_transform(Vector2.ZERO, giro, Vector2(-1.0 if espelhado else 1.0, 1.0))
	draw_texture_rect(desenho, Rect2(Vector2(-tam.x / 2.0, topo), tam), false,
		tinta * (TINTA_DO_VAZIO if _vazio else Color.WHITE))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var caixa := Rect2(-tamanho / 2.0, tamanho)
	if desenho != null:
		_desenhar_o_desenho()
	elif desenhar_caixa:
		draw_rect(caixa, COR_VAZIO if _vazio else cor)
		draw_rect(caixa, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)

	var fonte := ThemeDB.fallback_font
	# Daqui para baixo e aviso: a origem vai para o topo do movel e cada unidade
	# vale ESCALA_DO_AVISO px de mundo (ver a constante).
	var k := ESCALA_DO_AVISO
	draw_set_transform(Vector2(0.0, -tamanho.y / 2.0), 0.0, Vector2.ONE * k)
	var esquerda := -tamanho.x / 2.0 / k

	if _vazio:
		_desenhar_o_que_saiu(fonte, esquerda, -8.0)
		draw_set_transform(Vector2.ZERO)
		return

	if _progresso > 0.0:
		var largura := maxf(tamanho.x / k, 76.0)
		var barra := Rect2(Vector2(-largura / 2.0, -18.0), Vector2(largura, 8.0))
		draw_rect(barra, COR_FUNDO_DA_BARRA)
		var cheio := barra
		cheio.size.x = largura * (_progresso / duracao)
		draw_rect(cheio, COR_BARRA)
		draw_rect(barra, Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	if _jogador_dentro:
		draw_string(fonte, Vector2(esquerda, -26.0), "E  vasculhar %s (%.1fs)" % [rotulo, duracao],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_DO_AVISO)
	draw_set_transform(Vector2.ZERO)
