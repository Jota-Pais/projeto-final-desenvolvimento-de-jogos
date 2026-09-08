extends Node
## O relogio do dia na rua - a segunda pressao em cima de vasculhar.
##
## O dia tem luz contada, e **vasculhar gasta luz mais rapido que andar**. Nao
## existe punicao por anoitecer na rua: o custo e o dia acabar onde voce
## estiver, e cada dia gasto encosta no prazo da cura. E dai que sai a escolha
## "vasculho mais um movel ou volto pra casa?" - a mesma decisao da core
## mechanic vista pelo outro lado. O zumbi cobra em vida; o relogio cobra em
## dia, que e a moeda mais cara que existe, porque o prazo nao volta.
##
## Isto e o relogio de UM dia, e e coisa da rua: nasce cheio a cada vez que a
## cena da rua carrega. A contagem de dias e o prazo da cura atravessam os dois
## modos e moram no Travessia.
##
## Esta no grupo "relogio", que e como quem precisa dele o acha - mesmo arranjo
## da navegacao do zumbi. Quem gasta luz nao guarda referencia para ca: o movel
## nao sabe que existe relogio, quem liga os dois e o cenario.

## Emitido quando a luz acaba. Sai uma vez por dia.
signal anoiteceu

## Segundos reais de luz num dia. **Numero de feel, e proposta.**
##
## O bairro tem 40 moveis, que somam 116 s de vasculho - 233 s de luz com o
## custo abaixo. Com 180 s, **um dia nao da para limpar o bairro nem que voce
## nao ande um passo**, e isso antes de contar o caminho a pe. E de proposito:
## se um dia bastasse, nao haveria o que escolher, e escolher onde gastar o dia
## e o jogo.
##
## O conferir_relogio.tscn refaz essa conta e reclama se o dia crescer o
## bastante para o bairro caber nele. Se ficar apertado ou frouxo, e este
## numero que se mexe primeiro.
const DURACAO_DO_DIA := 180.0

## Quanto de luz EXTRA cada segundo de vasculho gasta. 1.0 = vasculhar gasta o
## dia em dobro: o segundo que passa mais o segundo que custa.
##
## E o parametro que liga o relogio na core mechanic. Em 0.0 o relogio continua
## existindo mas nao pressiona vasculhar - vira so um limite de tempo de sessao,
## que e o que ele NAO deve ser.
const CUSTO_DO_VASCULHO := 1.0

## A que horas o dia comeca e acaba. Existe so para a HUD dizer "13:42" em vez
## de "148 s restantes": hora do dia se le sem aprender nada.
const HORA_DE_ACORDAR := 7.0
const HORA_DE_ANOITECER := 19.0

## Luz que sobra, em segundos.
var luz := DURACAO_DO_DIA

## A ferramenta de conferencia desliga isto. Encerrar o dia troca de cena, e
## troca de cena no meio de um teste leva a cena do teste embora.
var encerra_o_dia := true

var _acabou := false

func _process(delta: float) -> void:
	gastar(delta)

## Gasta luz. O _process gasta o tempo passando; o vasculho gasta a mais, por
## ao_vasculhar(). Chamar depois de acabar nao faz nada.
func gastar(segundos: float) -> void:
	if _acabou:
		return
	luz = maxf(0.0, luz - segundos)
	if luz > 0.0:
		return

	_acabou = true
	anoiteceu.emit()
	if not encerra_o_dia:
		return

	# Provisorio, do mesmo jeito que ficar sem vida: o dia acaba onde voce
	# estiver e voce aparece em casa. Noite na rua como fase propria - ter que
	# voltar a pe no escuro - e decisao de design que ninguem tomou, e e cara:
	# pede visao curta, zumbi diferente e arte de noite.
	print("Anoiteceu - o dia %d acaba na rua" % Travessia.dia)
	Travessia.entrar_em_casa()

## Ligado pelo cenario no sinal `vasculhando` de cada movel.
func ao_vasculhar(segundos: float) -> void:
	gastar(segundos * CUSTO_DO_VASCULHO)

## 1.0 ao amanhecer, 0.0 ao anoitecer.
func fracao_de_luz() -> float:
	return luz / DURACAO_DO_DIA

func hora() -> float:
	return HORA_DE_ACORDAR + (HORA_DE_ANOITECER - HORA_DE_ACORDAR) * (1.0 - fracao_de_luz())

func hora_texto() -> String:
	var minutos := int(round(hora() * 60.0))
	return "%02d:%02d" % [(minutos / 60) % 24, minutos % 60]

func acabou() -> bool:
	return _acabou
