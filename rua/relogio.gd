extends Node
## O relogio do dia na rua - a segunda pressao em cima de vasculhar.
##
## O dia tem luz contada, e **vasculhar gasta luz mais rapido que andar**. As
## 19:00 anoitece, e a noite **nao te tira da rua: ela aperta**. O bairro comeca
## a encher de zumbi, eles enxergam de mais longe, e a rua escurece. Voltar pra
## casa deixa de ser um botao e passa a ser uma travessia.
##
## As 05:00 amanhece e o dia vira a forca. E o teto, e foi decisao de direcao
## (09/09/2026): da para aguentar a noite inteira e perder o dia sem morrer.
##
## **Nao existe "sistema de noite".** A noite e um numero - noite(), de 0 a 1 -
## e cada um le e reage por conta: o cenario traz mais zumbi, o zumbi enxerga
## mais longe, a HUD avisa e escurece a tela. Um lugar so decide que horas sao;
## ninguem precisa combinar com ninguem.
##
## Isto e o relogio de UM dia, e e coisa da rua: nasce cheio a cada vez que a
## cena da rua carrega. A contagem de dias e o prazo da cura atravessam os dois
## modos e moram no Travessia.
##
## Esta no grupo "relogio", que e como quem precisa dele o acha - mesmo arranjo
## da navegacao do zumbi.

## As 19:00. A rua nao muda de cena: comeca a apertar.
signal anoiteceu

## As 05:00. O dia acaba com voce na rua, e sem passar pela porta do porao.
signal amanheceu

## Segundos reais de luz num dia - 07:00 as 19:00. **Numero de feel, e
## proposta.**
##
## **420 s desde 09/09/2026, e o motivo e o mapa.** Eram 180 quando o mundo era
## o bairro sozinho: 144 x 90 m, atravessavel em 20 s. Agora o mundo tem 1,44 km
## de ponta a ponta, que a pe sao 206 s - mais do que o dia inteiro tinha.
##
## Um mapa que nao da para atravessar num dia nao e mapa grande, e mapa
## inacessivel. **Quando o carro existir este numero volta a cair**: o ponto de
## ter carro e justamente o dia nao precisar ser tao longo.
##
## O conferir_relogio.tscn refaz a conta do vasculho e reclama se o dia crescer
## o bastante para o mapa todo caber nele. Se ficar apertado ou frouxo, e este
## numero que se mexe primeiro.
const DURACAO_DO_DIA := 420.0

## Segundos reais de noite - 19:00 as 05:00. **Proposta.**
##
## E o tempo que voce tem para atravessar o bairro de volta com a rua enchendo,
## e o teto de quem nao voltar. Menos que isso e a noite nao chega a apertar;
## muito mais e ficar fora vira uma segunda partida, e nao um erro.
const DURACAO_DA_NOITE := 350.0

## Quanto de luz EXTRA cada segundo de vasculho gasta. 1.0 = vasculhar gasta o
## dia em dobro: o segundo que passa mais o segundo que custa.
##
## E o parametro que liga o relogio na core mechanic. Em 0.0 o relogio continua
## existindo mas nao pressiona vasculhar - vira so um limite de tempo de sessao,
## que e o que ele NAO deve ser.
const CUSTO_DO_VASCULHO := 1.0

## As horas do relogio da HUD. O amanhecer e 29 = 05:00 do dia seguinte; quem
## mostra resolve o modulo de 24.
const HORA_DE_ACORDAR := 7.0
const HORA_DE_ANOITECER := 19.0
const HORA_DE_AMANHECER := 29.0

## Segundos corridos desde que voce acordou. E o unico estado daqui; luz, noite
## e hora saem todos deste numero.
var decorrido := 0.0

## A ferramenta de conferencia desliga isto. Encerrar o dia troca de cena, e
## troca de cena no meio de um teste leva a cena do teste embora.
var encerra_o_dia := true

var _anoiteceu := false
var _amanheceu := false

func _process(delta: float) -> void:
	gastar(delta)

## Gasta tempo do dia. O _process gasta o tempo passando; o vasculho gasta a
## mais, por ao_vasculhar(). Chamar depois de amanhecer nao faz nada.
func gastar(segundos: float) -> void:
	if _amanheceu:
		return
	decorrido += segundos

	if not _anoiteceu and decorrido >= DURACAO_DO_DIA:
		_anoiteceu = true
		anoiteceu.emit()
		print("Anoiteceu - a rua vai encher. Volte pra casa.")

	if decorrido < DURACAO_DO_DIA + DURACAO_DA_NOITE:
		return

	_amanheceu = true
	amanheceu.emit()
	if not encerra_o_dia:
		return
	# O dia acaba, e acaba do jeito ruim: sem passar pela porta do porao. Hoje
	# a diferenca e so o texto que a casa mostra - com a mochila do passo 4,
	# passa a ser o que voce deixou de entregar.
	print("Amanheceu na rua - o dia %d acabou sem voce chegar em casa" % Travessia.dia)
	Travessia.entrar_em_casa(Travessia.FimDoDia.AMANHECEU_NA_RUA)

## Ligado pelo cenario no sinal `vasculhando` de cada movel.
func ao_vasculhar(segundos: float) -> void:
	gastar(segundos * CUSTO_DO_VASCULHO)

## 1.0 ao amanhecer o dia, 0.0 as 19:00 e daí em diante.
func fracao_de_luz() -> float:
	return clampf(1.0 - decorrido / DURACAO_DO_DIA, 0.0, 1.0)

## **O numero que a noite inteira usa:** 0.0 enquanto e dia, subindo para 1.0
## as 05:00. Quem quiser ficar mais dificil de noite multiplica por isto.
func noite() -> float:
	return clampf((decorrido - DURACAO_DO_DIA) / DURACAO_DA_NOITE, 0.0, 1.0)

func e_noite() -> bool:
	return decorrido > DURACAO_DO_DIA

## Se o dia acabou - o que hoje quer dizer "amanheceu com voce na rua".
func acabou() -> bool:
	return _amanheceu

func hora() -> float:
	if decorrido <= DURACAO_DO_DIA:
		var do_dia := decorrido / DURACAO_DO_DIA
		return HORA_DE_ACORDAR + (HORA_DE_ANOITECER - HORA_DE_ACORDAR) * do_dia
	return HORA_DE_ANOITECER + (HORA_DE_AMANHECER - HORA_DE_ANOITECER) * noite()

func hora_texto() -> String:
	var minutos := int(round(hora() * 60.0))
	return "%02d:%02d" % [(minutos / 60) % 24, minutos % 60]
