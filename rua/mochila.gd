extends Node
## A mochila do dia: o que voce esta **carregando agora**, na rua.
##
## Nao e a mochila que a casa le, e a diferenca entre as duas e o preco da
## noite: **so entra em casa o que passou pela porta de casa.** Ser pego pelo
## amanhecer na rua deixa tudo na calcada - e e isso que faz o aviso
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
## "mochila, com o espaco ja ocupado visivel". As outras tres cobram em tempo
## (zumbi), em luz (relogio) e em dia (prazo); esta cobra em **escolha**: com o
## espaco acabando, vasculhar deixa de ser "pego tudo" e passa a ser "levo o
## que?".
##
## 12 e pouco de proposito. Um movel da de 0 a 3 coisas, entao a mochila enche
## em umas seis gavetas - e voltar pra casa entregar passa a ser parte do dia, e
## nao so o fim dele.
const CAPACIDADE := 12

## Emitido a cada achado que entra. A HUD nao precisa disto - le direto -, mas
## o som e o "+1" na tela sao passo 5 e se penduram aqui.
signal guardou(achado: String, documento: bool)

## Emitido quando o jogador tira uma coisa da mochila pela tela dela.
##
## **Ela nao sabe onde a coisa cai.** Quem escuta e o cenario, que poe uma
## pilha no chao aos pes do jogador - mesmo arranjo do `vasculhado` do movel:
## a mochila nao conhece o mundo, e o mundo nao mexe na mochila.
signal largou(achado: String, documento: bool)

## O que entrou hoje. **Documento conta separado** porque e a moeda do eixo
## rua -> casa: o documento avanca a pesquisa da cura, e o resto ainda espera o
## modo Casa decidir o que consome. Sao as duas recompensas, e nao valem o mesmo.
var itens: Array[String] = []
var documentos: Array[String] = []

func _ready() -> void:
	Travessia.chegou_em_casa.connect(_ao_acabar_o_dia)

## Ligado pelo cenario no sinal `vasculhado` de cada movel.
##
## **Tira da lista o que levou, e o que nao couber fica nela** - e a lista e o
## proprio `achados` do movel, o mesmo objeto e nao uma copia. E assim que "o
## que nao cabe fica no movel" acontece sem o movel saber que existe mochila.
##
## O movel com sobra continua aceitando vasculho, mais barato (ver
## DURACAO_DA_SOBRA, em rua/vasculhavel.gd): abrir vaga pela tela da mochila e
## voltar nele e o ciclo que faz a capacidade ser escolha e nao teto.
##
## Duas passadas, **documento primeiro**: e a recompensa que importa, e ninguem
## quer descobrir que deixou o documento para tras porque uma lata de comida
## entrou na frente.
func ao_vasculhar(_rotulo: String, achados: Array[String]) -> void:
	_pegar_o_equipamento(achados)
	_guardar_o_que_couber(achados, true)
	_guardar_o_que_couber(achados, false)

## Pistola e municao saem da lista antes de tudo e **nao vao para a mochila**:
## sao equipamento, ficam no cinto, nao ocupam vaga e nao se perdem no dia que
## deu errado. Ver o Travessia.tem_pistola.
##
## Passam por aqui e nao pelo cenario porque este e o arquivo que ja separa o
## que e o que: quem sabe distinguir documento de comida sabe distinguir arma.
func _pegar_o_equipamento(achados: Array[String]) -> void:
	var i := 0
	while i < achados.size():
		match achados[i]:
			Construcao.PISTOLA:
				Travessia.tem_pistola = true
				achados.remove_at(i)
				guardou.emit(Construcao.PISTOLA, false)
			Construcao.MUNICAO:
				Travessia.municao += Construcao.MUNICAO_POR_ACHADO
				achados.remove_at(i)
				guardou.emit(Construcao.MUNICAO, false)
			_:
				i += 1

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

## Tudo o que esta dentro, **na ordem em que a tela mostra**: documento em cima,
## na cor dele, e o resto embaixo.
##
## E a mesma ordem que largar() indexa, de proposito: a tela desenha esta lista
## e devolve o indice da linha escolhida, sem precisar saber que por baixo sao
## duas listas separadas.
func tudo() -> Array[String]:
	var lista: Array[String] = []
	lista.append_array(documentos)
	lista.append_array(itens)
	return lista

## Tira da mochila a coisa da linha `qual` de tudo(), e avisa quem escuta.
##
## **Largar documento e permitido.** Ele e o que ganha a partida, entao a
## tentacao e proibir - mas a mochila e 12 vagas e os documentos do mapa sao 6:
## nao existe mochila travada de documento. E o que cai, cai no chao e da para
## pegar de volta. Proibir aqui seria proteger o jogador de uma escolha que o
## jogo inteiro e feito de cobrar.
func largar(qual: int) -> String:
	var lista := tudo()
	if qual < 0 or qual >= lista.size():
		return ""

	var achado := lista[qual]
	var documento := qual < documentos.size()
	if documento:
		documentos.remove_at(qual)
	else:
		itens.remove_at(qual - documentos.size())

	largou.emit(achado, documento)
	return achado

## O dia acabou. So entrega quem voltou pela porta de casa.
func _ao_acabar_o_dia() -> void:
	if Travessia.fim_do_dia == Travessia.FimDoDia.PELA_PORTA:
		Travessia.receber(itens, documentos)
		return
	print("Ficou na rua: %d itens e %d documento(s)" % [itens.size(), documentos.size()])
	Travessia.perder_na_rua(itens.size(), documentos.size())
