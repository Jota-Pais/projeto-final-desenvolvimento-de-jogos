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

const Bairro := preload("res://rua/bairro.gd")

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
func ao_vasculhar(_rotulo: String, achados: Array[String]) -> void:
	for achado in achados:
		var documento := Bairro.e_documento(achado)
		if documento:
			documentos.append(achado)
		else:
			itens.append(achado)
		guardou.emit(achado, documento)

func quantos() -> int:
	return itens.size() + documentos.size()

## Nao ha limite de espaco, e **isso e decisao pendente**, nao esquecimento: o
## one-pager declara "mochila, com o espaco ja ocupado visivel", o que supoe um
## teto. Um teto cria viagem - enche, volta, sai de novo -, e como ele conversa
## com o vasculho (o movel nao esvazia? sobra dentro dele?) tem varias
## respostas. Fica para o grupo.
func esta_cheia() -> bool:
	return false

## O dia acabou. So entrega quem voltou pela porta do porao.
func _ao_acabar_o_dia() -> void:
	if Travessia.fim_do_dia == Travessia.FimDoDia.PELA_PORTA:
		Travessia.receber(itens, documentos)
		return
	print("Ficou na rua: %d itens e %d documento(s)" % [itens.size(), documentos.size()])
	Travessia.perder_na_rua(itens.size(), documentos.size())
