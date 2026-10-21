extends Control
## O menu do jogo (Joao, 15/10/2026: "o jogo merecia um menu tambem"). E a
## cena principal do projeto: nome do jogo, Jogar, Como se joga e Sair. Jogar
## abre a escolha do modo (Travessia.Modo: campanha ou hardcore) e so entao a
## rua comeca. Recomecar, no fim de jogo, volta para ca.
##
## E uma tela SO de texto, como a casa e o fim de jogo: quem fizer arte troca
## isto por uma de verdade. O que precisa sobreviver a troca e o caminho -
## Jogar, modo, rua - e o preco de cair na rua dito em cada modo.
##
## Tres paineis no mesmo VBox, um visivel por vez: Principal, Modos e
## ComoSeJoga. Esc volta ao principal; o foco nasce no primeiro botao de cada
## painel, entao setas e Enter bastam. Nada aqui e tipado com Travessia de
## proposito: a ferramenta que captura a tela roda sem os autoloads.

## Onde a faixa escura de baixo comeca (fracao da altura): a de sempre deixa
## a capa aparecer; a alta e para o painel de como se joga, que e comprido.
const FAIXA_BAIXA := 0.56
const FAIXA_ALTA := 0.27

@onready var _principal: VBoxContainer = $Conteudo/Principal
@onready var _modos: VBoxContainer = $Conteudo/Modos
@onready var _como_se_joga: VBoxContainer = $Conteudo/ComoSeJoga

func _ready() -> void:
	($Conteudo/Principal/Jogar as Button).pressed.connect(_mostrar.bind(_modos))
	($Conteudo/Principal/ComoSeJoga as Button).pressed.connect(_mostrar.bind(_como_se_joga))
	($Conteudo/Principal/Sair as Button).pressed.connect(get_tree().quit)
	($Conteudo/Modos/Botoes/Campanha as Button).pressed.connect(_comecar.bind(0))
	($Conteudo/Modos/Botoes/Hardcore as Button).pressed.connect(_comecar.bind(1))
	($Conteudo/Modos/Voltar as Button).pressed.connect(_mostrar.bind(_principal))
	($Conteudo/ComoSeJoga/Voltar as Button).pressed.connect(_mostrar.bind(_principal))
	_mostrar(_principal)
	_ligar_o_som()

## A musica do menu e o som de passar pelo botao - de mouse ou de seta, que
## e o foco andando. O Som e buscado pelo caminho, como o Travessia (ver o
## cabecalho): sem os autoloads a tela fica muda em vez de nao abrir.
func _ligar_o_som() -> void:
	var som := get_node_or_null("/root/Som")
	if som == null:
		return
	som.musica("menu/menu")
	som.ambiente("")
	for botao in find_children("*", "Button", true, false):
		var passar: Callable = som.tocar.bind("menu/mouse_passar_botao", 1.0, 1)
		(botao as Button).mouse_entered.connect(passar)
		(botao as Button).focus_entered.connect(passar)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and not _principal.visible:
		_mostrar(_principal)

## Mostra um painel e esconde os outros; o foco vai para o primeiro botao
## dele, para o teclado ja funcionar.
func _mostrar(painel: VBoxContainer) -> void:
	for p in [_principal, _modos, _como_se_joga]:
		p.visible = p == painel
	# O "como se joga" e mais alto que a faixa escura de baixo: a faixa e o
	# conteudo sobem juntos, senao o texto cai em cima da capa e some.
	var topo := FAIXA_ALTA if painel == _como_se_joga else FAIXA_BAIXA
	($Faixa as ColorRect).anchor_top = topo
	($Conteudo as VBoxContainer).anchor_top = topo
	var primeiro := _primeiro_botao(painel)
	if primeiro != null:
		primeiro.grab_focus()

## O primeiro Button dentro de `no`, em profundidade - ou null.
func _primeiro_botao(no: Node) -> Button:
	for filho in no.get_children():
		if filho is Button:
			return filho
		var dentro := _primeiro_botao(filho)
		if dentro != null:
			return dentro
	return null

## `modo` e o valor de Travessia.Modo (0 campanha, 1 hardcore) - inteiro
## cru, e o autoload buscado pelo caminho, para esta cena compilar sem ele
## (ver o cabecalho).
func _comecar(modo: int) -> void:
	var travessia := get_node("/root/Travessia")
	travessia.modo = modo
	get_tree().change_scene_to_file(travessia.CENA_DA_RUA)
