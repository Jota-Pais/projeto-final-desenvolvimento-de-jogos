extends CanvasLayer
## A HUD da rua, nos tres cantos que o one-pager do High Concept declara:
## topo = o dia e quanto falta para o prazo da cura; inferior esquerdo = vida,
## fome e agua; inferior direito = a mochila. Nao inventei layout - a peca de
## entrega ja disse onde cada coisa fica.
##
## E texto puro, e e de proposito. O que a Alfa cobra e a tela ser coerente com
## a que o documento declarou; barra, icone e moldura sao polimento e ficam para
## o passo 5. A vida tem barra em cima da cabeca do jogador, que e onde ela
## importa na hora do aperto.
##
## **Fome, agua e mochila aparecem como "—" porque ainda nao existem** (passo
## 4). Deixar o campo vazio na tela e melhor que esconder: e o mapa do que
## falta, e quem for fazer o passo 4 acha o lugar pronto.
##
## Ela nao guarda estado: le o relogio, o jogador e o Travessia todo quadro. Se
## algum deles nao estiver na cena, o campo apaga em vez de estourar - assim a
## HUD pode entrar em qualquer cena de teste sem arrastar o resto.

const Relogio := preload("res://rua/relogio.gd")

## O escurecer do fim de tarde. Comeca quando sobra menos de COMECA_A_ESCURECER
## da luz e chega a ESCURO_MAXIMO de opacidade no anoitecer.
##
## Auxilio de leitura, como o cone de visao do zumbi: sem isso o relogio existe
## so no texto da HUD, e ninguem joga olhando o canto da tela. Nao e a arte de
## fim de tarde - a paleta por hora do dia e assunto de quem fizer arte.
const COMECA_A_ESCURECER := 0.45
const ESCURO_MAXIMO := 0.55


@onready var _anoitecer := $Anoitecer as ColorRect
@onready var _topo := $Topo as Label
@onready var _esquerda := $Esquerda as Label
@onready var _direita := $Direita as Label

func _process(_delta: float) -> void:
	var relogio := get_tree().get_first_node_in_group("relogio") as Relogio
	var jogador := get_tree().get_first_node_in_group("jogador")

	_topo.text = _linha_do_topo(relogio)
	_esquerda.text = _linha_da_esquerda(jogador)
	_direita.text = _linha_da_direita()
	_anoitecer.color.a = _quanto_escuro(relogio)

## "Dia 3 de 10  ·  faltam 7 dias  ·  13:42"
func _linha_do_topo(relogio: Relogio) -> String:
	var pedacos := ["Dia %d de %d" % [Travessia.dia, Travessia.PRAZO_DA_CURA]]

	var faltam := Travessia.dias_restantes()
	if faltam == 0:
		pedacos.append("ultimo dia")
	elif faltam == 1:
		pedacos.append("falta 1 dia")
	else:
		pedacos.append("faltam %d dias" % faltam)

	if relogio != null:
		pedacos.append(relogio.hora_texto())
	return "   ·   ".join(pedacos)

func _linha_da_esquerda(jogador: Node) -> String:
	var vida := "—"
	if jogador != null and "vida" in jogador:
		vida = "%d%%" % roundi(jogador.get("vida"))
	# Alinhado com espaco em vez de tabulacao: fonte de fallback nao tem tab.
	return "vida    %s\nfome    —\nágua    —" % vida

func _linha_da_direita() -> String:
	var quanto := Travessia.mochila.size() + Travessia.documentos.size()
	if quanto == 0:
		return "mochila   vazia"
	return "mochila   %d" % quanto

func _quanto_escuro(relogio: Relogio) -> float:
	if relogio == null:
		return 0.0
	var fracao: float = relogio.fracao_de_luz()
	if fracao >= COMECA_A_ESCURECER:
		return 0.0
	return (1.0 - fracao / COMECA_A_ESCURECER) * ESCURO_MAXIMO
