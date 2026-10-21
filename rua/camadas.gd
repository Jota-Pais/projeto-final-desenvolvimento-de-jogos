## As camadas de colisao da rua (21/10/2026).
##
## Ate aqui tudo era a camada 1, e "segurar" era uma coisa so: o que barrava o
## corpo barrava a vista do zumbi e a bala. As barreiras do Joao precisam de
## mais: "alguns [deixam ver e atirar] sim, alguns nao, seja variado e
## criativo". Entao cada material diz o que segura, e a camada em que o corpo
## dele mora e essa resposta.
##
## A camada 1 continua sendo tudo o que ja existia (predio, bloco, agua,
## tronco, movel, porta de casa, borda do mundo, o jogador e o zumbi) - nada
## disso mudou. As outras so existem para barreira:
##
##  - **SO_CORPO** (camada 2): grade, alambrado, arame farpado, sacos baixos com
##    concertina - da para ver e atirar atraves;
##  - **CORPO_E_VISAO** (camada 3): tapume de zinco, tabua, portao de chapa -
##    o zumbi nao ve atraves, mas a bala atravessa a chapa fina;
##  - **CORPO_E_TIRO** (camada 4): reservada - segura a bala e deixa ver.
##
## Quem anda (jogador, zumbi) bate em todas; o raio da vista do zumbi para no
## SOLIDO e no CORPO_E_VISAO; o raio do tiro para no SOLIDO e no CORPO_E_TIRO.
## O jogador ve tudo de cima (o jogo nao tem nevoa): "vista" aqui e do zumbi.

const SOLIDO := 1
const SO_CORPO := 2
const CORPO_E_VISAO := 4
const CORPO_E_TIRO := 8

## A mascara de quem anda: barra em toda barreira.
const ANDAR := SOLIDO | SO_CORPO | CORPO_E_VISAO | CORPO_E_TIRO
## A mascara do raio da vista do zumbi.
const VISTA := SOLIDO | CORPO_E_VISAO
## A mascara do raio do tiro.
const TIRO := SOLIDO | CORPO_E_TIRO
