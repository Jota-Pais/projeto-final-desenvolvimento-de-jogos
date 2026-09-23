extends RefCounted
## Ela, no porao: em que ponto a transformacao esta, e o que o exame mostra.
##
## E o exame de *No, I'm Not a Human* virado do avesso. La, cada parte do corpo
## examinada custa energia e responde se a visita e gente; aqui, responde
## **quanto dela ainda sobra**. E o prazo da cura em forma de pessoa: a HUD da
## rua diz em numero quantos dias faltam, o porao diz com o corpo dela.
##
## **Proposta, nao decisao.** O que a equipe de narrativa decidir sobre ela
## (nome, como foi mordida, o que ela ainda lembra) nao esta aqui, e nada daqui
## pre-decide isso: os laudos descrevem so o corpo, e sao placeholder de texto
## que existe para o exame ter o que mostrar.

const PARTES := ["olhos", "dentes", "pele", "maos"]

const NOME_DA_PARTE := {
	"olhos": "os olhos",
	"dentes": "os dentes",
	"pele": "o braço",
	"maos": "as mãos",
}

## Quantos degraus a transformacao tem. O dia 1 e o primeiro, o ultimo dia do
## prazo e o ultimo.
const ESTAGIOS := 4

## O estagio de hoje. Linear no prazo: sem regra escondida, o corpo dela e um
## relogio que anda no mesmo ritmo do calendario.
static func estagio(dia: int, prazo: int) -> int:
	if prazo <= 1:
		return ESTAGIOS - 1
	var fracao := float(dia - 1) / float(prazo - 1)
	return clampi(int(fracao * ESTAGIOS), 0, ESTAGIOS - 1)

## O que se ve em cada parte, estagio a estagio.
const LAUDO := {
	"olhos": [
		"Vermelhos nos cantos, como de quem não dorme. Ela ainda aperta os olhos contra a luz.",
		"As veias tomaram o branco do olho. A pupila não fecha mais com a luz.",
		"Amarelados e secos. Ela não pisca.",
		"Brancos, leitosos. Não dá para saber para onde ela está olhando.",
	],
	"dentes": [
		"A gengiva sangra um pouco. Os dentes ainda são os dela.",
		"Gengiva escura, recuada. Um dente mole na frente.",
		"Os dentes amarelaram. Tem sangue seco entre eles.",
		"Faltam dois dentes. Os que sobraram parecem mais compridos.",
	],
	"pele": [
		"Pálida e fria, mas com pulso. A mordida ainda está inchada.",
		"Veias escuras subindo pelo braço, a partir da mordida.",
		"Acinzentada. Aperta e a marca não volta.",
		"Verde-acinzentada, fina como papel. As veias estão pretas.",
	],
	"maos": [
		"Unhas roídas. As mãos tremem.",
		"As pontas dos dedos escureceram. As unhas estão quebradiças.",
		"As unhas cresceram e escureceram. Ela arranha a grade quando você chega perto.",
		"Unhas pretas e compridas. Os dedos não dobram mais direito.",
	],
}
