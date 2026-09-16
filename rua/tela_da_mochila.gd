extends CanvasLayer
## A mochila aberta: a tela onde o jogador escolhe o que continua carregando.
##
## **Tab abre e fecha. W/S escolhem a linha, E larga no chao.**
##
## Ate 15/09/2026 a mochila era so um numero na HUD - "7/12" - e um teto: com
## ela cheia, o que voce achasse ficava no movel e acabou. A quarta pressao
## sobre vasculhar e a que **cobra escolha**, e escolha que nao se desfaz nao e
## escolha: era um limite, nao uma decisao. Esta tela e o que faz a vaga virar
## moeda - largo a comida estragada e levo o remedio, ou nao.
##
## ## O mundo nao para
##
## **Nao existe pausa aqui, e e a decisao de desenho desta tela.** O relogio do
## dia corre, o zumbi anda, a noite chega. O jogador fica parado enquanto
## escolhe - nao anda, nao vascula, nao atira - e o toque do zumbi fecha a tela
## na hora, igual ao vasculho que se interrompe.
##
## Com pausa, largar sairia de graca: abrir, esvaziar o saco no chao, fechar, e
## a mochila de 12 vagas nunca mais custaria nada a ninguem. A pressao nao esta
## no limite de 12; esta em decidir com o dia correndo.
##
## ## Quem sabe que ela esta aberta
##
## O `aberta` e estatico, e os tres que precisam dele leem direto da classe: o
## jogador (para nao andar), o vasculhavel (para o mesmo E nao vasculhar junto)
## e a pistola (para nao atirar). Nenhum dos tres precisa conhecer esta cena, e
## ninguem procura node em grupo a cada quadro.
##
## **Versao beta**: funciona de ponta a ponta e ainda e texto puro, como o resto
## da rua. Icone, arrastar com o mouse e ordenar por tipo sao polimento, e
## polimento so depois de a equipe jogar isto e dizer se a escolha esta no lugar
## certo.

const Mochila := preload("res://rua/mochila.gd")

## O ambar do documento, o mesmo do movel e da HUD. Em hexadecimal porque a
## lista e BBCode: e o unico jeito de ter duas cores no mesmo bloco de texto.
const HEX_DOCUMENTO := "e8b061"
const HEX_ESCOLHIDA := "f2ede2"
const HEX_APAGADO := "8a857c"

@onready var _painel := $Painel as Control
@onready var _titulo := $Painel/Caixa/Titulo as Label
@onready var _lista := $Painel/Caixa/Lista as RichTextLabel
@onready var _rodape := $Painel/Caixa/Rodape as Label

## Se a tela esta aberta agora. Ver o cabecalho: e estatica de proposito.
static var aberta := false

## Qual linha esta escolhida, no indice de `Mochila.tudo()`.
var _escolhida := 0

## O que saiu na ultima vez, so para o rodape poder dizer o que caiu no chao.
## Sem isso, largar e a tela mudando sozinha sem ninguem explicar o que houve.
var _ultimo_largado := ""

var _mochila: Mochila

func _ready() -> void:
	# Estatica sobrevive a troca de cena, e a cena anterior pode ter morrido com
	# a tela aberta - ao amanhecer na rua, por exemplo.
	aberta = false
	_painel.visible = false
	_mochila = get_tree().get_first_node_in_group("mochila") as Mochila

	# Quem apanha para de arrumar a mochila. Mesma regra do vasculho, e pelo
	# mesmo sinal: o jogador e a coisa que os dois lados conhecem.
	var jogador := get_tree().get_first_node_in_group("jogador")
	if jogador != null and jogador.has_signal("atingido"):
		jogador.atingido.connect(_ao_ser_atingido)

func _exit_tree() -> void:
	aberta = false

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("mochila"):
		_virar()
		return
	if not aberta:
		return

	if evento.is_action_pressed("ui_cancel"):
		_fechar()
	elif evento.is_action_pressed("andar_cima"):
		_mover(-1)
	elif evento.is_action_pressed("andar_baixo"):
		_mover(1)
	elif evento.is_action_pressed("vasculhar") or evento.is_action_pressed("ui_accept"):
		_largar()

func _virar() -> void:
	if aberta:
		_fechar()
	else:
		_abrir()

func _abrir() -> void:
	if _mochila == null:
		return
	aberta = true
	_escolhida = 0
	_ultimo_largado = ""
	_painel.visible = true
	_escrever()

func _fechar() -> void:
	aberta = false
	_painel.visible = false

func _ao_ser_atingido() -> void:
	if aberta:
		_fechar()

func _mover(passo: int) -> void:
	var quantas := _mochila.tudo().size()
	if quantas == 0:
		return
	# Da volta nas duas pontas: com 12 linhas, subir da primeira e mais curto
	# que descer onze vezes.
	_escolhida = wrapi(_escolhida + passo, 0, quantas)
	_escrever()

## Tira da mochila o que esta na linha escolhida. **Quem poe no chao e o
## cenario**, que escuta o sinal `largou` - esta tela nao conhece o mundo.
func _largar() -> void:
	if _mochila == null:
		return
	var achado := _mochila.largar(_escolhida)
	if achado.is_empty():
		return

	_ultimo_largado = achado
	var quantas := _mochila.tudo().size()
	_escolhida = clampi(_escolhida, 0, maxi(0, quantas - 1))
	_escrever()

# ------------------------------------------------------------------- a tela

func _escrever() -> void:
	_titulo.text = _linha_do_titulo()
	_lista.text = _texto_da_lista()
	_rodape.text = _texto_do_rodape()

func _linha_do_titulo() -> String:
	var quantos := _mochila.quantos()
	var titulo := "MOCHILA   %d/%d" % [quantos, _mochila.CAPACIDADE]
	if _mochila.esta_cheia():
		titulo += "   CHEIA"
	return titulo

## Documento em cima e em ambar, o resto embaixo. E a mesma ordem do
## `Mochila.tudo()`, que e a que o indice da linha escolhida usa.
func _texto_da_lista() -> String:
	var tudo := _mochila.tudo()
	if tudo.is_empty():
		return "[color=#%s]vazia — você não está carregando nada[/color]" % HEX_APAGADO

	var quantos_documentos := _mochila.documentos.size()
	var linhas := PackedStringArray()
	for i in tudo.size():
		var linha := ("›  " if i == _escolhida else "    ") + tudo[i]
		if i < quantos_documentos:
			linha = "[color=#%s]%s[/color]" % [HEX_DOCUMENTO, linha]
		elif i == _escolhida:
			linha = "[color=#%s]%s[/color]" % [HEX_ESCOLHIDA, linha]
		else:
			linha = "[color=#%s]%s[/color]" % [HEX_APAGADO, linha]
		linhas.append(linha)
	return "\n".join(linhas)

func _texto_do_rodape() -> String:
	var linhas := PackedStringArray()

	if not _ultimo_largado.is_empty():
		linhas.append("largou: %s — está no chão, aos seus pés" % _ultimo_largado)

	# O cinto existe para explicar por que a pistola nao aparece na lista: ela
	# nao ocupa vaga e nao se perde no dia que deu errado.
	if Travessia.tem_pistola:
		linhas.append("no cinto: pistola · %d bala(s) — não ocupa vaga" % Travessia.municao)

	linhas.append("W/S escolher   ·   E largar no chão   ·   Tab fechar")
	linhas.append("o dia continua correndo enquanto você escolhe")
	return "\n".join(linhas)
