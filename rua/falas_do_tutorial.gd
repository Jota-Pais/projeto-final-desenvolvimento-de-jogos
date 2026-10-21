## As falas do tutorial (21/10/2026). **O texto e do Joao e da equipe de
## narrativa** - aqui so mora o lugar de cada fala no roteiro (rua/tutorial.gd
## diz quando cada uma toca). O que esta entre colchetes e provisorio: diz o
## que a fala precisa fazer (e, nas aulas do radio, o que ela ensina, para o
## tutorial ja funcionar com o marcador), esperando o texto.
##
## Conversa (`PORTAO`, `PORTAO_VOLTA`, `O_TIRO`) e uma lista de [quem, linha];
## linhas seguidas do mesmo personagem saem na mesma caixa. Fala de radio e so
## a lista de linhas (quem fala e sempre o Antonio). Lista vazia nao toca.
##
## O roteiro (Joao, 21/10/2026): a cena de abertura sem o jogador no controle -
## ele anda devagar e apreensivo pela rua, da de cara com um zumbi, e o tiro do
## Antonio o salva e comeca a conversa; o Antonio da a missao e o radio, e no
## caminho ate a pizzaria vai ensinando como o zumbi funciona: nao fazer
## barulho perto, nao entrar na vista dele, agachar, e jogar pedra ou garrafa
## para chamar a atencao dele para outro lugar.

## O que o Antonio pede para buscar na pizzaria.
const ITEM_DO_FAVOR := "[o que o Antônio pediu]"

const QUEM_E_VOCE := "Você"
const QUEM_E_O_ANTONIO := "Antônio"

## 1. A cena de abertura: o que ele pensa andando apreensivo (opcional).
const ABERTURA: Array = []

## 2. Logo depois do tiro: o Antonio grita da casa (opcional).
const O_TIRO: Array = [
	["Antônio", "[grita da casa depois do tiro — fala do João]"],
]

## 3. No portao: o pedido de ajuda, a recusa, a bronca por andar desarmado, o
## favor (a missao) e o radio - a caixa de fala avisa que o radio foi entregue.
const PORTAO: Array = [
	["Você", "[pede ajuda no portão — fala do João]"],
	["Antônio", "[recusa: não deixa infectado nenhum chegar perto — fala do João]"],
	["Antônio", "[bronca: andar desarmado num apocalipse — fala do João]"],
	["Antônio", "[a missão: buscar o item na Cover Pizzaria — fala do João]"],
	["Antônio", "[joga o rádio por cima do muro: vai te guiando por ele — fala do João]"],
]

## 4. Saindo do portao, as aulas do radio, uma por vez, na ordem em que o
## caminho as pede.

## 4a. Logo depois do portao: o caminho e correr.
const RADIO_CORRER: Array = [
	"[rádio: a Cover Pizzaria fica ao sul, depois da avenida — fala do João]",
	"[rádio: segure Shift para correr, mas longe deles — fala do João]",
]

## 4b. Como eles veem: o cone na frente.
const RADIO_COMO_VEEM: Array = [
	"[rádio: eles enxergam só na frente, naquele cone claro; fora dele você passa — fala do João]",
	"[rádio: entrou na vista, ele vem atrás até te perder — fala do João]",
]

## 4c. Perto da primeira pedra no chao: pegar.
const RADIO_PEDRAS: Array = [
	"[rádio: pega essas pedras do chão (segure E) — fala do João]",
	"[rádio: pedra e garrafa servem pra chamar a atenção deles pra longe — fala do João]",
]

## 4d. O primeiro zumbi perto: o barulho.
const RADIO_BARULHO: Array = [
	"[rádio: devagar: correr perto deles faz barulho, e andar colado também — fala do João]",
	"[rádio: agachado (C) você não faz barulho nenhum, só fica mais lento — fala do João]",
]

## 4e. Chegando no beco ou perto da primeira cobertura: agachar e se esconder.
const RADIO_AGACHAR: Array = [
	"[rádio: agachado atrás de carro, caçamba ou entulho, eles não te veem — fala do João]",
]

## 4f. Perto da pizzaria, com um zumbi na porta: arremessar.
const RADIO_ARREMESSO: Array = [
	"[rádio: tem um parado na porta da pizzaria — fala do João]",
	"[rádio: role o scroll até a pedra, segure o botão esquerdo para mirar longe dele e solte — fala do João]",
	"[rádio: ele vai atrás do barulho e a porta fica livre — fala do João]",
]

## 4g. Logo depois do primeiro arremesso.
const RADIO_ARREMESSO_BOM: Array = [
	"[rádio: isso, ele foi ver o barulho; entra agora — fala do João]",
]

## 4h. A primeira garrafa achada.
const RADIO_GARRAFA: Array = [
	"[rádio: garrafa quebra e faz mais barulho que pedra, chama de mais longe — fala do João]",
]

## 4i. A primeira vez que um zumbi te ve e vem atras (opcional).
const RADIO_FOI_VISTO: Array = [
	"[rádio: ele te viu! sai da vista dele e se esconda — fala do João]",
]

## 5. Chegando na pizzaria: vasculhar.
const RADIO_PIZZARIA: Array = [
	"[rádio: segure E num móvel para vasculhar — fala do João]",
]

## 6. Com o item na mao: voltar.
const RADIO_PEGOU: Array = [
	"[rádio: achou, agora volta pro portão — fala do João]",
]

## 7. De volta ao portao: a entrega e a 9mm.
const PORTAO_VOLTA: Array = [
	["Antônio", "[recebe o item — fala do João]"],
	["Antônio", "[dá a 9mm — fala do João]"],
]

## 7b. Depois da 9mm: voltar para casa antes de escurecer.
const RADIO_IR_PARA_CASA: Array = [
	"[rádio: volta pra casa antes de escurecer; segure E na porta — fala do João]",
]

## 8. Dia 2, de manha: explorar e usar a arma.
const DIA_2_MANHA: Array = [
	"[rádio: bom dia; hoje explore a região — fala do João]",
	"[rádio: role o scroll até a arma, mire com o mouse e clique para atirar; o tiro chama os outros — fala do João]",
]

## 9. Dia 2: o primeiro zumbi abatido - o fim do tutorial.
const DIA_2_PRIMEIRO_ZUMBI: Array = [
	"[rádio: boa! o tutorial acaba aqui — fala do João]",
]
