extends Node
## A mochila do dia: os documentos que voce esta **carregando agora**, na rua.
##
## Nao e o que a casa le, e a diferenca entre as duas e o preco da noite: **so
## entra em casa o que passou pela porta de casa.** Ser pego pelo amanhecer na
## rua deixa tudo na calcada - e e isso que faz o aviso das 19:00 valer algo em
## vez de ser enfeite.
##
## Ela nao sabe quem a enche: o movel emite `vasculhado`, e quem liga os dois e
## o cenario, igual ao relogio. E nao sabe quem a esvazia: quando o dia acaba
## ela le o Travessia.fim_do_dia e decide sozinha entregar ou perder.
##
## ## So documento entra (30/09/2026)
##
## Ate esta data a mochila tinha 12 vagas e carregava lata de comida, pilha e
## pano sujo junto com o documento - a capacidade era "a quarta pressao sobre
## vasculhar". O Joao tirou o loot generico do jogo para enxugar: o que o
## vasculho rende agora sao **balas**, que vao para o cinto (Travessia.municao)
## e nao ocupam vaga, e os **documentos**, que sao a unica coisa que a mochila
## carrega. Sem capacidade: sao seis documentos no mapa inteiro, e vaga que
## nunca falta nao e regra.
##
## Esta no grupo "mochila", que e como a HUD a acha.

const Construcao := preload("res://rua/construcao.gd")

## Emitido a cada coisa que o vasculho rendeu - documento ou balas. A HUD nao
## precisa disto (le direto), mas o som e o "+1" na tela sao polimento e se
## penduram aqui.
signal guardou(achado: String)

## Emitido quando o jogador tira um documento da mochila pela tela dela.
##
## **Ela nao sabe onde a coisa cai.** Quem escuta e o cenario, que poe uma
## pilha no chao aos pes do jogador - mesmo arranjo do `vasculhado` do movel:
## a mochila nao conhece o mundo, e o mundo nao mexe na mochila.
signal largou(achado: String)

## O que entrou hoje: so documento, a moeda do eixo rua -> casa.
var documentos: Array[String] = []

func _ready() -> void:
	Travessia.chegou_em_casa.connect(_ao_acabar_o_dia)

## Ligado pelo cenario no sinal `vasculhado` de cada movel.
##
## **Tira da lista o que levou** - e a lista e o proprio `achados` do movel, o
## mesmo objeto e nao uma copia. Balas vao para o cinto, documento vai para a
## mochila; qualquer outra coisa (nao existe mais nenhuma no jogo) fica onde
## estava.
func ao_vasculhar(_rotulo: String, achados: Array[String]) -> void:
	_pegar_as_balas(achados)
	_pegar_os_arremessaveis(achados)
	_guardar_os_documentos(achados)

## A pedra e a garrafa vao para a mao, como as balas para o cinto: sao
## equipamento contado (Travessia.arremessaveis, 21/10/2026).
func _pegar_os_arremessaveis(achados: Array[String]) -> void:
	var i := 0
	while i < achados.size():
		var achado: String = achados[i]
		if achado in Travessia.ARREMESSAVEIS:
			Travessia.guardar_arremessavel(achado)
			achados.remove_at(i)
			guardou.emit(achado)
		else:
			i += 1

## As balas saem da lista e **nao vao para a mochila**: sao equipamento, ficam
## no cinto, nao ocupam vaga e nao se perdem no dia que deu errado. Cada
## caixinha vai para o calibre dela (Travessia.balas; 05/10/2026).
func _pegar_as_balas(achados: Array[String]) -> void:
	var i := 0
	while i < achados.size():
		var achado: String = achados[i]
		if Construcao.e_municao(achado):
			Travessia.guardar_balas(Construcao.calibre_de(achado), Construcao.MUNICAO_POR_ACHADO)
			achados.remove_at(i)
			guardou.emit(achado)
		else:
			i += 1

func _guardar_os_documentos(achados: Array[String]) -> void:
	var i := 0
	while i < achados.size():
		var achado: String = achados[i]
		if not Construcao.e_documento(achado):
			i += 1
			continue
		achados.remove_at(i)
		documentos.append(achado)
		guardou.emit(achado)

func quantos() -> int:
	return documentos.size()

## Tudo o que esta dentro, na ordem em que a tela mostra - e a mesma ordem que
## largar() indexa, de proposito.
func tudo() -> Array[String]:
	return documentos.duplicate()

## Tira da mochila o documento da linha `qual` de tudo(), e avisa quem escuta.
##
## **Largar documento e permitido.** Ele e o que ganha a partida, entao a
## tentacao e proibir - mas o que cai, cai no chao e da para pegar de volta.
## Proibir aqui seria proteger o jogador de uma escolha que o jogo inteiro e
## feito de cobrar.
func largar(qual: int) -> String:
	if qual < 0 or qual >= documentos.size():
		return ""
	var achado := documentos[qual]
	documentos.remove_at(qual)
	largou.emit(achado)
	return achado

## O dia acabou. So entrega quem voltou pela porta de casa.
func _ao_acabar_o_dia() -> void:
	if Travessia.fim_do_dia == Travessia.FimDoDia.PELA_PORTA:
		Travessia.receber(documentos)
		return
	print("Ficou na rua: %d documento(s)" % documentos.size())
	Travessia.perder_na_rua(documentos.size())
