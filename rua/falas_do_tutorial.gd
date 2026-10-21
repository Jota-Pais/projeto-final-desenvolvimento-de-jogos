## As falas do tutorial (21/10/2026). **O texto e do Joao e da equipe de
## narrativa** - aqui so mora o lugar de cada fala no roteiro (rua/tutorial.gd
## diz quando cada uma toca). O que esta entre colchetes e provisorio: diz o
## que a fala precisa fazer, esperando o texto.
##
## Conversa (`PORTAO`, `PORTAO_VOLTA`, `O_TIRO`) e uma lista de [quem, linha];
## linhas seguidas do mesmo personagem saem na mesma caixa. Fala de radio e so
## a lista de linhas (quem fala e sempre o Antonio). Lista vazia nao toca.

## O que o Antonio pede para buscar no Restaurante.
const ITEM_DO_FAVOR := "[o que o Antônio pediu]"

const QUEM_E_VOCE := "Você"
const QUEM_E_O_ANTONIO := "Antônio"

## 1. A cena de abertura: o que ele pensa andando sem rumo (opcional).
const ABERTURA: Array = []

## 2. Logo depois do tiro: o Antonio grita da casa (opcional).
const O_TIRO: Array = [
	["Antônio", "[grita da casa depois do tiro — fala do João]"],
]

## 3. No portao: o pedido de ajuda, a recusa, a bronca por andar desarmado, o
## radio e o favor - o que buscar no Restaurante.
const PORTAO: Array = [
	["Você", "[pede ajuda no portão — fala do João]"],
	["Antônio", "[recusa: não deixa infectado nenhum chegar perto — fala do João]"],
	["Antônio", "[bronca: andar desarmado num apocalipse — fala do João]"],
	["Antônio", "[entrega o rádio — fala do João]"],
	["Antônio", "[o favor: buscar o item no Restaurante — fala do João]"],
]

## 4. Saindo do portao: correr.
const RADIO_CORRER: Array = [
	"[rádio: o Restaurante fica ao sul, depois da avenida — fala do João]",
	"[rádio: segure Shift para correr — fala do João]",
]

## 5. Chegando no beco ou perto da primeira cobertura: agachar e se esconder.
const RADIO_AGACHAR: Array = [
	"[rádio: aperte C para agachar — fala do João]",
	"[rádio: agachado atrás de caçamba, carro ou entulho, eles não te veem — fala do João]",
]

## 5b. A primeira vez que um zumbi te ve e vem atras (opcional).
const RADIO_FOI_VISTO: Array = [
	"[rádio: ele te viu! sai da vista dele e se esconda — fala do João]",
]

## 6. Chegando no Restaurante: vasculhar.
const RADIO_RESTAURANTE: Array = [
	"[rádio: segure E num móvel para vasculhar — fala do João]",
]

## 7. Com o item na mao: voltar.
const RADIO_PEGOU: Array = [
	"[rádio: achou, agora volta pro portão — fala do João]",
]

## 8. De volta ao portao: a entrega e a 9mm.
const PORTAO_VOLTA: Array = [
	["Antônio", "[recebe o item — fala do João]"],
	["Antônio", "[dá a 9mm — fala do João]"],
]

## 8b. Depois da 9mm: voltar para casa antes de escurecer.
const RADIO_IR_PARA_CASA: Array = [
	"[rádio: volta pra casa antes de escurecer; segure E na porta — fala do João]",
]

## 9. Dia 2, de manha: explorar e usar a arma.
const DIA_2_MANHA: Array = [
	"[rádio: bom dia; hoje explore a região — fala do João]",
	"[rádio: mire com o mouse e clique para atirar; o tiro chama os outros — fala do João]",
]

## 10. Dia 2: o primeiro zumbi abatido - o fim do tutorial.
const DIA_2_PRIMEIRO_ZUMBI: Array = [
	"[rádio: boa! o tutorial acaba aqui — fala do João]",
]
