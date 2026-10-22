extends CanvasLayer
## A caixa de fala (20/10/2026): toda fala do jogo sai numa caixa embaixo da
## tela, estilo RPG, com o nome de quem fala e o retrato dele. Decisao do Joao,
## que preferiu isto a balao em cima da cabeca. Vale para a fala de perto (a
## porta do bunker do Antonio, uma cena) e para a fala pelo radio.
##
## Dois jeitos de falar:
##
##  - `falar()`: de perto. **O jogo para** enquanto a caixa esta aberta - o
##    relogio, os zumbis, o jogador - e o E avanca: completa a linha que esta
##    sendo escrita, ou passa para a proxima; na ultima, fecha. O jogo so volta
##    quando o E e solto, para o mesmo aperto nao cair no vasculho nem na porta
##    de casa;
##  - `pelo_radio()`: **o jogo nao para** e o E continua sendo do vasculho.
##    Cada linha fica o tempo de ler e a proxima entra sozinha.
##
## Fala que chega com a caixa aberta entra na fila. **O texto das falas nao
## mora aqui**: e da equipe de narrativa (design/narrativa.md); quem chama
## manda as linhas, e o retrato de quem fala.
##
## A caixa fica no meio de baixo e deixa livres os dois cantos da HUD (vida e
## balas a esquerda, mochila a direita): pelo radio o jogo segue, e o jogador
## precisa ver a vida enquanto ouve. Maior desde 21/10/2026 (Joao: "aumenta a
## caixa de texto e a fonte"): ocupa todo o vao entre os cantos, mais alta, com
## letra e retrato maiores.
##
## **A voz** (21/10/2026): enquanto a linha e escrita, a voz de quem fala toca
## (Som.falar, as gravacoes da pasta "personagens" do Drive) e cala quando a
## linha fica inteira. Quem chama diz a voz; sem voz, a caixa fala muda.

## Emitido no fim de cada fala - quem chamou espera com `await`.
signal acabou

## A caixa aberta numa fala de perto: o jogo esta parado e o E e dela.
static var aberta := false

const LETRAS_POR_SEGUNDO := 45.0
## Pelo radio, quanto cada linha fica na tela depois de escrita: um minimo,
## mais um tanto por letra.
const LEITURA_MINIMA := 1.4
const LEITURA_POR_LETRA := 0.045

@onready var _caixa: Control = $Caixa
@onready var _retrato: TextureRect = $Caixa/Linha/Retrato
@onready var _nome: Label = $Caixa/Linha/Coluna/Nome
@onready var _texto: Label = $Caixa/Linha/Coluna/Texto
@onready var _dica: Label = $Caixa/Linha/Coluna/Dica

var _fila: Array[Dictionary] = []
var _atual: Dictionary = {}
var _linha := 0
var _letras := 0.0
var _lendo := 0.0
## A ultima linha de uma fala de perto acabou e o E ainda esta apertado: a
## caixa fecha quando ele for solto.
var _esperando_soltar := false

func _ready() -> void:
	# Ela e quem continua rodando com o jogo parado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caixa.visible = false

func _exit_tree() -> void:
	# A cena trocou com uma fala de perto aberta: o jogo nao pode ficar parado.
	if aberta:
		_parar_o_jogo(false)

## Fala de perto: o jogo para e o E avanca.
func falar(nome: String, linhas: PackedStringArray, retrato: Texture2D = null, voz := "") -> void:
	_entrar({ "nome": nome, "linhas": linhas, "retrato": retrato, "radio": false, "voz": voz })

## Fala pelo radio: o jogo segue e as linhas passam sozinhas.
func pelo_radio(nome: String, linhas: PackedStringArray, retrato: Texture2D = null, voz := "") -> void:
	_entrar({ "nome": nome, "linhas": linhas, "retrato": retrato, "radio": true, "voz": voz })

## Se ainda ha fala na tela, na fila, ou o E de uma fala de perto ainda nao foi
## solto. Quem encadeia falas (o tutorial) espera isto, e nao o `acabou`: o
## `acabou` de uma fala de radio que estava na frente chegaria primeiro.
func ocupada() -> bool:
	return not _atual.is_empty() or not _fila.is_empty() or _esperando_soltar

## Tira da fila as falas de radio e corta a que esta tocando: quem vai falar de
## perto (o Antonio, no portao) nao deixa o jogador parado esperando o radio.
func calar_o_radio() -> void:
	var sem_radio: Array[Dictionary] = []
	for fala in _fila:
		if not fala["radio"]:
			sem_radio.append(fala)
	_fila = sem_radio
	if not _atual.is_empty() and _atual["radio"]:
		_atual = {}
		_caixa.visible = false
		Som.calar_a_voz()
		acabou.emit()

func _entrar(fala: Dictionary) -> void:
	if (fala["linhas"] as PackedStringArray).is_empty():
		return
	_fila.append(fala)
	if _atual.is_empty() and not _esperando_soltar:
		_proxima_fala()

func _process(delta: float) -> void:
	if _esperando_soltar:
		if not Input.is_action_pressed("vasculhar"):
			_esperando_soltar = false
			_proxima_fala()
		return
	if _atual.is_empty():
		return

	var linha: String = (_atual["linhas"] as PackedStringArray)[_linha]
	var de_perto: bool = not _atual["radio"]
	if _letras < linha.length():
		_letras = minf(linha.length(), _letras + LETRAS_POR_SEGUNDO * delta)
		if de_perto and Input.is_action_just_pressed("vasculhar"):
			_letras = linha.length()
		_texto.visible_characters = int(_letras)
		if _letras >= linha.length():
			Som.calar_a_voz()
		return

	if de_perto:
		if Input.is_action_just_pressed("vasculhar"):
			_avancar()
	else:
		_lendo += delta
		if _lendo >= LEITURA_MINIMA + LEITURA_POR_LETRA * linha.length():
			_avancar()

func _avancar() -> void:
	_linha += 1
	if _linha < (_atual["linhas"] as PackedStringArray).size():
		_mostrar_linha()
		return
	var de_perto: bool = not _atual["radio"]
	_atual = {}
	acabou.emit()
	if de_perto:
		# A caixa some ja; o jogo volta quando o E for solto (ver _process).
		_caixa.visible = false
		_esperando_soltar = true
	else:
		_proxima_fala()

func _proxima_fala() -> void:
	if _fila.is_empty():
		Som.calar_a_voz()
		_caixa.visible = false
		_parar_o_jogo(false)
		return
	_atual = _fila.pop_front()
	_linha = 0
	var radio: bool = _atual["radio"]
	_parar_o_jogo(not radio)
	_nome.text = ("%s  (rádio)" % _atual["nome"]) if radio else String(_atual["nome"])
	_retrato.texture = _atual["retrato"]
	_retrato.visible = _atual["retrato"] != null
	_dica.visible = not radio
	_caixa.visible = true
	_mostrar_linha()

func _mostrar_linha() -> void:
	_texto.text = (_atual["linhas"] as PackedStringArray)[_linha]
	_texto.visible_characters = 0
	_letras = 0.0
	_lendo = 0.0
	Som.falar(_atual.get("voz", ""))

func _parar_o_jogo(sim: bool) -> void:
	aberta = sim
	if is_inside_tree():
		get_tree().paused = sim
