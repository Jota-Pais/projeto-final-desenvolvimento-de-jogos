extends CanvasLayer
## A mochila aberta: a tela onde o jogador ve os documentos que carrega e
## decide se larga algum.
##
## **Tab abre e fecha. W/S escolhem a linha, E larga no chao.**
##
## Nasceu em 15/09/2026 como a tela da escolha de carga, com 12 vagas e loot
## de todo tipo. Desde 30/09/2026 a mochila so carrega documento (ver
## rua/mochila.gd): a tela ficou menor, e continua existindo pelo que ela faz
## de unico - largar um documento no chao e pegar de volta depois - e pelo
## cinto, que e onde a Beretta e as balas aparecem.
##
## ## O mundo nao para
##
## **Nao existe pausa aqui, e e a decisao de desenho desta tela.** O relogio do
## dia corre, o zumbi anda, a noite chega. O jogador fica parado enquanto
## escolhe - nao anda, nao vascula, nao atira - e o toque do zumbi fecha a tela
## na hora, igual ao vasculho que se interrompe.
##
## ## Quem sabe que ela esta aberta
##
## O `aberta` e estatico, e os tres que precisam dele leem direto da classe: o
## jogador (para nao andar), o vasculhavel (para o mesmo E nao vasculhar junto)
## e a pistola (para nao atirar). Nenhum dos tres precisa conhecer esta cena, e
## ninguem procura node em grupo a cada quadro.
##
## **Versao beta**: funciona de ponta a ponta e ainda e texto puro, como o resto
## da rua.

const Mochila := preload("res://rua/mochila.gd")

## O ambar do documento, o mesmo do movel e da HUD. Em hexadecimal porque a
## lista e BBCode.
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
	if quantos == 0:
		return "MOCHILA   vazia"
	return "MOCHILA   %d documento%s" % [quantos, "" if quantos == 1 else "s"]

## Um documento por linha, em ambar; a escolhida em claro.
func _texto_da_lista() -> String:
	var tudo := _mochila.tudo()
	if tudo.is_empty():
		return "[color=#%s]vazia — você não está carregando documento nenhum[/color]" % HEX_APAGADO

	var linhas := PackedStringArray()
	for i in tudo.size():
		var linha := ("›  " if i == _escolhida else "    ") + tudo[i]
		var cor := HEX_ESCOLHIDA if i == _escolhida else HEX_DOCUMENTO
		linhas.append("[color=#%s]%s[/color]" % [cor, linha])
	return "\n".join(linhas)

func _texto_do_rodape() -> String:
	var linhas := PackedStringArray()

	if not _ultimo_largado.is_empty():
		linhas.append("largou: %s — está no chão, aos seus pés" % _ultimo_largado)

	# O cinto existe para explicar por que a arma nao aparece na lista: ela e
	# as balas nao ocupam vaga e nao se perdem no dia que deu errado.
	linhas.append("no cinto: Beretta 9mm · %d bala%s — não ocupa vaga" % [
		Travessia.municao, "" if Travessia.municao == 1 else "s"])

	linhas.append("W/S escolher   ·   E largar no chão   ·   Tab fechar")
	linhas.append("o dia continua correndo enquanto você escolhe")
	return "\n".join(linhas)
