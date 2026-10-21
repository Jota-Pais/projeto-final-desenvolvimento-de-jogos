extends CanvasLayer
## A HUD da rua, nos tres cantos que o one-pager do High Concept declara:
## topo = o dia e quanto falta para o prazo da cura; inferior esquerdo = o que
## voce leva no corpo; inferior direito = a mochila. Nao inventei layout - a
## peca de entrega ja disse onde cada coisa fica.
##
## ⬜ **O canto inferior esquerdo divergiu da peca em 16/09/2026.** Ela declara
## vida, fome e agua ali, e as tres sairam do jogo - hoje so a pistola aparece.
## E divergencia conhecida, e quem retomar a camada de sobrevivencia acha o
## lugar dela aqui.
##
## E texto puro, e e de proposito. O que a Alfa cobra e a tela ser coerente com
## a que o documento declarou; barra, icone e moldura sao polimento.
##
## Ela nao guarda estado: le o relogio, a mochila e o Travessia todo quadro. Se
## algum deles nao estiver na cena, o campo apaga em vez de estourar - assim a
## HUD pode entrar em qualquer cena de teste sem arrastar o resto.

const Relogio := preload("res://rua/relogio.gd")
## So para o nome da municao do calibre da arma na mao.
const Construcao := preload("res://rua/construcao.gd")

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
	var mochila := get_tree().get_first_node_in_group("mochila")

	_topo.text = _linha_do_topo(relogio)
	_esquerda.text = _linha_da_esquerda(get_tree().get_first_node_in_group("jogador"))
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

## O canto inferior esquerdo: o que voce leva no corpo. **A vida** (saiu em
## 16/09/2026 por decisao de mesa e voltou em 30/09/2026 a pedido do Joao;
## fome e agua continuam fora) e **a arma na mao** (`Travessia.arma`; a Beretta
## no comeco) com a conta de balas, que e o que o vasculho rende. A barra de
## verdade fica em cima da cabeca do jogador, que e onde ela importa na hora
## do aperto; aqui e o numero.
func _linha_da_esquerda(jogador: Node) -> String:
	var linhas := PackedStringArray()
	if jogador != null and "vida" in jogador:
		linhas.append("vida   %d/%d" % [roundi(jogador.get("vida")), roundi(jogador.VIDA_CHEIA)])
	# As balas do calibre da arma na mao, com o nome da municao ("15 balas
	# 9mm", "8 cartuchos calibre 12"); os outros calibres estao na tela da
	# mochila.
	# O que esta na mao (rua/mao.gd, 21/10/2026): a arma com as balas do
	# calibre dela, ou a pedra e a garrafa contadas; e o resto, para lembrar
	# que o scroll troca.
	var municao: String = Construcao.MUNICOES[Travessia.calibre_da_arma()]
	match Travessia.na_mao:
		"arma":
			if Travessia.municao == 0:
				linhas.append("%s   sem %s" % [Travessia.arma, municao])
			else:
				linhas.append("%s   %d %s" % [Travessia.arma, Travessia.municao, municao])
		"pedra", "garrafa":
			linhas.append("%s x%d   segure e solte para jogar" % [Travessia.na_mao, int(Travessia.arremessaveis[Travessia.na_mao])])
		_:
			linhas.append("maos vazias")
	var outras := PackedStringArray()
	for qual in Travessia.opcoes_na_mao():
		if qual != Travessia.na_mao:
			_nome_na_mao(outras, qual)
	if not outras.is_empty():
		linhas.append("[scroll] " + "  ".join(outras))
	if jogador != null and jogador.get("agachado"):
		linhas.append("agachado   [C]")
	return "\n".join(linhas)

## Como cada coisa da mao aparece na lista do scroll.
func _nome_na_mao(lista: PackedStringArray, qual: String) -> void:
	if qual == "arma":
		lista.append(Travessia.arma)
	else:
		lista.append("%s x%d" % [qual, int(Travessia.arremessaveis[qual])])

## A mochila e a do DIA - o que voce esta carregando, e nao o que ja entregou.
## Some tudo se voce nao voltar pela porta de casa. Desde 30/09/2026 ela so
## carrega documento, entao a linha da mochila e a linha dos documentos viraram
## uma so: e a unica coisa que voce traz que faz a historia andar.
##
## O "[Tab]" fica sempre na linha: e a unica pista de que existe uma tela para
## abrir, e o jogo nao tem tutorial.
func _linha_da_direita(mochila: Node) -> String:
	if mochila == null:
		return "mochila   —"
	var quantos: int = mochila.quantos()
	if quantos == 0:
		return "mochila   vazia   [Tab]"
	return "mochila   %d documento%s   [Tab]" % [quantos, "" if quantos == 1 else "s"]

## A linha propria do documento, acima da mochila, ficou vazia desde que a
## mochila so carrega documento (30/09/2026): dizer duas vezes a mesma conta
## nao e "conta separado". O Label continua na cena para quem quiser por outra
## coisa nele.
func _linha_dos_documentos(_mochila: Node) -> String:
	return ""

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
