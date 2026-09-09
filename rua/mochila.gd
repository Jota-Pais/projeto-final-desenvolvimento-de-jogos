extends Node
## A mochila do dia: o que voce esta **carregando agora**, na rua.
##
## Nao e a mochila que a casa le, e a diferenca entre as duas e o preco da
## noite: **so entra em casa o que passou pela porta do porao.** Ser pego pelo
## amanhecer ou cair sem vida deixa tudo na calcada - e e isso que faz o aviso
## das 19:00 valer algo em vez de ser enfeite.
##
## Ela nao sabe quem a enche: o movel emite `vasculhado`, e quem liga os dois e
## o cenario, igual ao relogio. E nao sabe quem a esvazia: quando o dia acaba
## ela le o Travessia.fim_do_dia e decide sozinha entregar ou perder.
##
## Esta no grupo "mochila", que e como a HUD a acha.

const Construcao := preload("res://rua/construcao.gd")

## Quantas coisas cabem. **Proposta.**
##
## E a QUARTA pressao sobre vasculhar, e a que o one-pager sempre declarou -
## "mochila, com o espaco ja ocupado visivel". As outras tres cobram em vida
## (zumbi), em dia (relogio) e em prazo; esta cobra em **escolha**: com o espaco
## acabando, vasculhar deixa de ser "pego tudo" e passa a ser "levo o que?".
##
## 12 e pouco de proposito. Um movel da de 0 a 3 coisas, entao a mochila enche
## em umas seis gavetas - e voltar pra casa entregar passa a ser parte do dia, e
## nao so o fim dele.
const CAPACIDADE := 12

## Emitido a cada achado que entra. A HUD nao precisa disto - le direto -, mas
## o som e o "+1" na tela sao passo 5 e se penduram aqui.
signal guardou(achado: String, documento: bool)

## O que entrou hoje. **Documento conta separado** porque e a moeda do eixo
## rua -> casa: a comida te mantem vivo, o documento avanca a pesquisa da cura.
## Sao as duas recompensas do vasculho, e elas nao valem o mesmo.
var itens: Array[String] = []
var documentos: Array[String] = []

func _ready() -> void:
	Travessia.chegou_em_casa.connect(_ao_acabar_o_dia)

## Ligado pelo cenario no sinal `vasculhado` de cada movel.
##
## **Tira da lista o que levou, e o que nao couber fica nela** - e a lista e o
## proprio `achados` do movel, o mesmo objeto e nao uma copia. E assim que "o
## que nao cabe fica no movel" acontece sem o movel saber que existe mochila, e
## sem inventar uma tela de troca: voce volta depois, e voltar gasta dia.
##
## Duas passadas, **documento primeiro**: e a recompensa que importa, e ninguem
## quer descobrir que deixou o documento para tras porque uma lata de comida
## entrou na frente.
func ao_vasculhar(_rotulo: String, achados: Array[String]) -> void:
	_guardar_o_que_couber(achados, true)
	_guardar_o_que_couber(achados, false)

func _guardar_o_que_couber(achados: Array[String], documentos_agora: bool) -> void:
	var i := 0
	while i < achados.size():
		var achado: String = achados[i]
		var documento := Construcao.e_documento(achado)
		if documento != documentos_agora or esta_cheia():
			i += 1
			continue
		achados.remove_at(i)
		if documento:
			documentos.append(achado)
		else:
			itens.append(achado)
		guardou.emit(achado, documento)

func quantos() -> int:
	return itens.size() + documentos.size()

func esta_cheia() -> bool:
	return quantos() >= CAPACIDADE

## O dia acabou. So entrega quem voltou pela porta do porao.
func _ao_acabar_o_dia() -> void:
	if Travessia.fim_do_dia == Travessia.FimDoDia.PELA_PORTA:
		Travessia.receber(itens, documentos)
		return
	print("Ficou na rua: %d itens e %d documento(s)" % [itens.size(), documentos.size()])
	Travessia.perder_na_rua(itens.size(), documentos.size())
