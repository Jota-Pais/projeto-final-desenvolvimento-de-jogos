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
## seguinte...'". Sao as RADIO_ de 4a a 4j e a RADIO_PIZZARIA - para ele
## reescrever. Elas tocam uma de cada vez (rua/tutorial.gd, AULAS).

## O que o Antonio pede para buscar na pizzaria (o roteiro: "eu esqueci de
## reabastecer meu estoque de pepperoni").
const ITEM_DO_FAVOR := "pepperoni"

const QUEM_E_VOCE := "Você"
const QUEM_E_O_ANTONIO := "Antônio"

## A voz de cada um enquanto a fala e escrita (rua/caixa_de_fala.gd): as
## gravacoes da pasta "personagens" dos sons do Drive, em som/personagens/. O
## "vizinho" e o Antonio, o vizinho do roteiro; o "pp" (PP), o protagonista.
## Sobram "mulher", "velho" e "veterano", para quando houver quem fale.
const VOZES := { QUEM_E_O_ANTONIO: "vizinho", QUEM_E_VOCE: "pp" }

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

## 4c. Obstaculo: dois zumbis de costas para o onibus, na avenida. Aula: o
## barulho dos passos e agachar.
const RADIO_BARULHO: Array = [
	["Antônio", "Opa, tem dois ali na avenida, de costas pro ônibus, bem no caminho."],
	["Antônio", "Faz o seguinte: aperta C e passa agachado entre eles e o ônibus. Andando colado eles te ouvem, e correndo então, de longe."],
	["Antônio", "Agachado você não faz barulho nenhum, só fica mais lento."],
]

## As aulas da porta da pizzaria, uma de cada vez (Joao, 21/10/2026: "ele tem
## que ensinar o cara a pegar a pedra, e arremessar tambem, um de cada vez").

## 4d. Chegando perto do zumbi parado na porta: o aviso e a cobertura baixa.
const RADIO_PORTA: Array = [
	["Antônio", "Ah, não... tem um zumbi parado bem na porta de onde você vai entrar. A gente tem que tirar ele de lá."],
	["Antônio", "Fica agachado atrás desses carros: agachado atrás de carro, caçamba ou entulho, eles não te veem."],
]

## 4e. Logo depois, se ele nao tem pedra: pegar.
const RADIO_PEDRAS: Array = [
	["Antônio", "Faz o seguinte: tá vendo aquelas pedras ali no chão? Segura E em cima delas pra pegar."],
]

## 4f. Com pedra na mochila: arremessar.
const RADIO_ARREMESSO: Array = [
	["Antônio", "Agora rola o scroll até a pedra e segura o botão esquerdo pra mirar."],
	["Antônio", "Mira perto dele, mas longe da porta, e solta. Ele vai atrás do barulho."],
]

## 4g. O arremesso caiu longe e ele continua na porta.
const RADIO_ARREMESSO_ERROU: Array = [
	["Antônio", "Hm, ele nem ouviu. Joga mais perto dele."],
]

## 4h. O arremesso tirou ele da porta.
const RADIO_ARREMESSO_BOM: Array = [
	["Antônio", "Isso, ele foi ver o barulho! Entra agora."],
]

## 4i. A primeira garrafa achada.
const RADIO_GARRAFA: Array = [
	["Antônio", "Achou uma garrafa? Ela quebra e faz mais barulho que pedra, chama eles de mais longe."],
]

## 4j. A primeira vez que um zumbi te ve e vem atras.
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

## 8. Logo depois da 9mm: o fim da beta (Joao, 21/10/2026: "faz o antonio
## agradecer ele por jogar a beta do jogo e que e isso por enquanto, mas ele
## pode se sentir livre pra jogar e explorar o espaco quanto quiser" - o
## conteudo e dele, as palavras sao proposta).
const FIM_DA_BETA: Array = [
	["Antônio", "Ah, e valeu por jogar a beta do jogo, viu?"],
	["Antônio", "Por enquanto é isso. Mas fica à vontade pra jogar e explorar o bairro o quanto quiser."],
]
