## As falas do tutorial (21/10/2026). **O texto e do Joao e da equipe de
## narrativa** - aqui so mora o lugar de cada fala no roteiro (rua/tutorial.gd
## diz quando cada uma toca). O que esta entre colchetes e provisorio: diz o
## que a fala precisa fazer, esperando o texto.
##
## Toda fala e uma lista de [quem, linha]; linhas seguidas do mesmo personagem
## saem na mesma caixa. De perto (a conversa no portao) o jogo para; pelo
## radio (as constantes RADIO_ e a CHEGADA), nao. Lista vazia nao toca.
##
## **O roteiro da conversa e do Joao (21/10/2026, noite)**, passado para ca
## com acento, maiuscula e pontuacao, sem mexer nas palavras (ficaram o "pra",
## o "ta", o "muleque"): da abertura ate a apresentacao pelo radio, e a piada
## da chegada na pizzaria. O protagonista e o **Fabiano**; a caixa ainda diz
## "Voce" para ele (QUEM_E_VOCE).
##
## **As aulas do radio no caminho sao proposta minha**, no estilo que ele
## pediu: cada uma vem de um obstaculo de zumbis no caminho, e o Antonio fala
## "explicitamente, 'ah, tem zumbis ali bloqueando o caminho, faz o
## seguinte...'". Sao as RADIO_ de 4a a 4g e a RADIO_PIZZARIA - para ele
## reescrever.

## O que o Antonio pede para buscar na pizzaria (o roteiro: "eu esqueci de
## reabastecer meu estoque de pepperoni").
const ITEM_DO_FAVOR := "pepperoni"

const QUEM_E_VOCE := "Você"
const QUEM_E_O_ANTONIO := "Antônio"

## 1. A cena de abertura: o que ele pensa andando apreensivo (opcional).
const ABERTURA: Array = []

## 2. Logo depois do tiro, com o portao ainda aberto e o Antonio de arma na
## mao. Depois disto o Antonio fecha o portao.
const O_TIRO: Array = [
	["Você", "Meu Deus! Por favor, não me mate!"],
	["Antônio", "Te matar? Eu acabei de te salvar."],
]

## 2b. O portao acabou de fechar.
const PORTAO_FECHADO: Array = [
	["Você", "Não, espera!"],
]

## 3. No portao fechado, ate o Antonio jogar o radio por cima do muro.
const PORTAO: Array = [
	["Você", "Muito obrigado, você salvou minha vida."],
	["Antônio", "Hm, de nada..."],
	["Antônio", "Melhor tomar cuidado. Não se sai por aí num apocalipse zumbi sem uma arma."],
	["Você", "Arma? Mas por que eu teria uma arma em casa?"],
	["Antônio", "Ai, muleque, você tá muito ferrado..."],
	["Antônio", "Quer saber? Pega isso."],
]

## 3b. Com o radio na mao: o favor.
const PORTAO_DEPOIS_DO_RADIO: Array = [
	["Você", "Ahn? Que isso?"],
	["Antônio", "É um rádio."],
	["Você", "Eu sei, mas por quê?"],
	["Antônio", "Você vai fazer um favor pra mim, e em troca, eu te dou uma arma."],
	["Você", "Um favor? O que você quer?"],
	["Antônio", "Preciso que vá a um lugar pra mim, buscar uma... uma coisa. Vai ser tranquilo."],
	["Você", "Tá bom, então. Acho que não tenho muita escolha."],
]

## 4. A conversa passa para o radio: a apresentacao, logo que o jogador volta
## ao controle.
const RADIO_APRESENTACAO: Array = [
	["Antônio", "A propósito, meu nome é Antônio, mas pode me chamar de Rei do Apocalipse."],
	["Você", "Tá bom, Antônio... Meu nome é Fabiano."],
]

## 4a. Logo depois da apresentacao: o caminho e correr.
const RADIO_CORRER: Array = [
	["Antônio", "Esse tiro deve ter chamado atenção. Segura Shift pra correr enquanto não tem nenhum por perto."],
	["Antônio", "O lugar fica pro sul, depois da avenida. Vou te guiando por aqui."],
]

## 4b. Obstaculo: um zumbi parado no fim da cerca, olhando para quem desce.
## Aula: como eles veem.
const RADIO_COMO_VEEM: Array = [
	["Antônio", "Opa, para aí! Tem um zumbi parado no caminho, olhando pra cá."],
	["Antônio", "Tá vendo aquela luz no chão na frente dele? É só até ali que ele enxerga."],
	["Antônio", "Faz o seguinte: dá a volta por fora da luz e passa por trás dele. Se ele te vir, vem atrás até te perder de vista."],
]

## 4c. Obstaculo: dois zumbis de costas do lado do onibus, na avenida. Aula:
## o barulho dos passos e agachar.
const RADIO_BARULHO: Array = [
	["Antônio", "Opa, tem dois ali do lado do ônibus, bem no caminho. Ainda bem que tão de costas."],
	["Antônio", "Faz o seguinte: aperta C e passa agachado. Andando colado eles te ouvem, e correndo então, de longe."],
	["Antônio", "Agachado você não faz barulho nenhum, só fica mais lento."],
]

## 4d. Obstaculo: o zumbi parado na porta da pizzaria, e o jogador sem pedra.
## Aula: pegar pedra do chao.
const RADIO_PEDRAS: Array = [
	["Antônio", "Ah, não... tem um zumbi parado bem na porta de onde você vai entrar. A gente tem que tirar ele de lá."],
	["Antônio", "Faz o seguinte: tá vendo aquelas pedras no chão? Segura E em cima delas pra pegar."],
]

## 4e. O mesmo obstaculo, com pedra na mochila. Aula: arremessar e se esconder
## atras de cobertura baixa.
const RADIO_ARREMESSO: Array = [
	["Antônio", "Agora rola o scroll até a pedra, segura o botão esquerdo pra mirar perto dele, longe da porta, e solta."],
	["Antônio", "Ele vai atrás do barulho e a porta fica livre."],
	["Antônio", "Se precisar chegar mais perto, agacha atrás de um carro: agachado atrás de carro, caçamba ou entulho, eles não te veem."],
]

## 4f. Logo depois do primeiro arremesso.
const RADIO_ARREMESSO_BOM: Array = [
	["Antônio", "Isso, ele foi ver o barulho! Entra agora."],
]

## 4g. A primeira garrafa achada.
const RADIO_GARRAFA: Array = [
	["Antônio", "Achou uma garrafa? Ela quebra e faz mais barulho que pedra, chama eles de mais longe."],
]

## 4h. A primeira vez que um zumbi te ve e vem atras.
const RADIO_FOI_VISTO: Array = [
	["Antônio", "Ele te viu! Sai da vista dele, entra num lugar fechado. Eles são mais lentos que você."],
]

## 5. Entrando na pizzaria (o roteiro: "quando o personagem chegar no lugar").
const CHEGADA: Array = [
	["Você", "Pera, você me fez passar tudo isso pra ir num restaurante?"],
	["Antônio", "É, eu esqueci de reabastecer meu estoque de pepperoni. Como eu vou viver sem meu pepperoni?"],
	["Você", "Uhhhh..."],
]

## 5b. Logo depois da chegada: vasculhar.
const RADIO_PIZZARIA: Array = [
	["Antônio", "Procura aí dentro. Segura E num móvel pra vasculhar."],
]

## 6. Com o item na mao: voltar.
const RADIO_PEGOU: Array = [
	["Antônio", "[rádio: achou, agora volta pro portão — fala do João]"],
]

## 7. De volta ao portao: a entrega e a 9mm.
const PORTAO_VOLTA: Array = [
	["Antônio", "[recebe o item — fala do João]"],
	["Antônio", "[dá a 9mm — fala do João]"],
]

## 7b. Depois da 9mm: voltar para casa antes de escurecer.
const RADIO_IR_PARA_CASA: Array = [
	["Antônio", "[rádio: volta pra casa antes de escurecer; segure E na porta — fala do João]"],
]

## 8. Dia 2, de manha: explorar e usar a arma.
const DIA_2_MANHA: Array = [
	["Antônio", "[rádio: bom dia; hoje explore a região — fala do João]"],
	["Antônio", "[rádio: role o scroll até a arma, mire com o mouse e clique para atirar; o tiro chama os outros — fala do João]"],
]

## 9. Dia 2: o primeiro zumbi abatido - o fim do tutorial.
const DIA_2_PRIMEIRO_ZUMBI: Array = [
	["Antônio", "[rádio: boa! o tutorial acaba aqui — fala do João]"],
]
