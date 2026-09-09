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

## O escurecer da tarde e da noite. **Contido de proposito** (decisao de
## direcao, 09/09/2026): a rua tem que ficar noturna sem virar tela preta - da
## para continuar lendo o bairro e achar o caminho de casa. O que aperta a
## noite e a rua encher, nao voce nao ver.
##
## COMECA_A_ESCURECER e a fracao de luz em que a tarde comeca a cair.
const COMECA_A_ESCURECER := 0.45
const ESCURO_AO_ANOITECER := 0.30
const ESCURO_NA_NOITE_FECHADA := 0.60

## Em que ponto da noite ela para de escurecer. Depois disso o escuro fica
## parado - o resto do aperto vem dos zumbis.
const NOITE_MAIS_ESCURA := 0.7

## O aviso da noite, que foi pedido junto com ela: o jogo tem que **dizer** que
## e hora de voltar, e nao so ficar dificil e esperar voce descobrir.
const AVISO_DE_ANOITECER := "Anoiteceu — melhor voltar pra casa"
const AVISO_DE_RUA_CHEIA := "A rua está enchendo — volte pra casa"
const AVISO_DE_NOITE_FECHADA := "Você não vai aguentar a noite"

const COR_DO_AVISO := Color("d8a13c")
const COR_DO_AVISO_GRAVE := Color("c0463c")

@onready var _anoitecer := $Anoitecer as ColorRect
@onready var _topo := $Topo as Label
@onready var _aviso := $Aviso as Label
@onready var _esquerda := $Esquerda as Label
@onready var _direita := $Direita as Label
@onready var _documentos := $Documentos as Label

func _process(_delta: float) -> void:
	var relogio := get_tree().get_first_node_in_group("relogio") as Relogio
	var jogador := get_tree().get_first_node_in_group("jogador")
	var mochila := get_tree().get_first_node_in_group("mochila")

	_topo.text = _linha_do_topo(relogio)
	_esquerda.text = _linha_da_esquerda(jogador)
	_direita.text = _linha_da_direita(mochila)
	_documentos.text = _linha_dos_documentos(mochila)
	_anoitecer.color.a = _quanto_escuro(relogio)
	_avisar(relogio)

## "Dia 3 de 10  ·  faltam 7 dias  ·  21:30"
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

	# O objetivo principal, no lugar mais lido da tela. Sao os documentos que
	# JA CHEGARAM em casa - o que esta na mochila ainda nao conta, e essa
	# diferenca e o jogo inteiro.
	pedacos.append("cura %d/%d" % [
		Travessia.documentos.size(), Travessia.DOCUMENTOS_PARA_A_CURA
	])
	return "   ·   ".join(pedacos)

func _linha_da_esquerda(jogador: Node) -> String:
	var vida := "—"
	if jogador != null and "vida" in jogador:
		vida = "%d%%" % roundi(jogador.get("vida"))
	# Alinhado com espaco em vez de tabulacao: fonte de fallback nao tem tab.
	# A pistola so aparece depois de achada, na armaria da delegacia. Antes
	# disso a linha nao existe, porque ela nao existe.
	var arma := ""
	if Travessia.tem_pistola:
		arma = "\npistola %d" % Travessia.municao
		if Travessia.municao == 0:
			arma = "\npistola sem munição"
	return "vida    %s\nfome    —\nágua    —%s" % [vida, arma]

## A mochila e a do DIA - o que voce esta carregando, e nao o que ja entregou.
## Some tudo se voce nao voltar pela porta do porao.
## "mochila 7/12" - o **espaco ja ocupado visivel** que o one-pager declara. O
## numero conta documento junto, porque documento ocupa espaco igual: e nisso
## que a escolha existe.
func _linha_da_direita(mochila: Node) -> String:
	if mochila == null:
		return "mochila   —"
	var quantos: int = mochila.quantos()
	var cabe: int = mochila.CAPACIDADE
	if quantos >= cabe:
		return "mochila   %d/%d   CHEIA" % [quantos, cabe]
	return "mochila   %d/%d" % [quantos, cabe]

## O documento tem linha propria, acima da mochila e na cor dele. E o que o
## one-pager pede - "conta separado" - e o que prova o eixo rua -> casa mesmo
## sem a casa existir: e a unica coisa que voce traz que faz a historia andar.
func _linha_dos_documentos(mochila: Node) -> String:
	if mochila == null:
		return ""
	var quantos: int = mochila.documentos.size()
	if quantos == 0:
		return ""
	if quantos == 1:
		return "1 documento"
	return "%d documentos" % quantos

## O aviso vai piorando com a noite, e e ele que responde "e agora, o que eu
## faco?". Sem isso a noite so fica dificil e o jogador nao sabe por que.
func _avisar(relogio: Relogio) -> void:
	if relogio == null or not relogio.e_noite():
		_aviso.text = ""
		return

	var quanto := relogio.noite()
	if quanto < 0.35:
		_aviso.text = AVISO_DE_ANOITECER
		_aviso.add_theme_color_override("font_color", COR_DO_AVISO)
	elif quanto < NOITE_MAIS_ESCURA:
		_aviso.text = AVISO_DE_RUA_CHEIA
		_aviso.add_theme_color_override("font_color", COR_DO_AVISO)
	else:
		_aviso.text = AVISO_DE_NOITE_FECHADA
		_aviso.add_theme_color_override("font_color", COR_DO_AVISO_GRAVE)

func _quanto_escuro(relogio: Relogio) -> float:
	if relogio == null:
		return 0.0

	if relogio.e_noite():
		var quanto := minf(1.0, relogio.noite() / NOITE_MAIS_ESCURA)
		return lerpf(ESCURO_AO_ANOITECER, ESCURO_NA_NOITE_FECHADA, quanto)

	var fracao := relogio.fracao_de_luz()
	if fracao >= COMECA_A_ESCURECER:
		return 0.0
	return (1.0 - fracao / COMECA_A_ESCURECER) * ESCURO_AO_ANOITECER
