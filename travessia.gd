extends Node
## O que atravessa entre os dois modos do jogo. E o unico lugar onde a rua e a
## casa se encontram.
##
## A ideia e as duas frentes se desenvolverem sem se ver: quem trabalha na casa
## le daqui o que voltou da rua, e quem trabalha na rua nao precisa saber o que
## a casa faz com isso. Nenhuma cena da rua conhece uma cena da casa, e vice
## versa - as duas conhecem so este arquivo.
##
## E uma proposta de costura, nao decisao tomada. Se a equipe quiser outra, e
## este o unico arquivo que muda.
##
## Registrado como autoload em project.godot, entao se chama "Travessia" de
## qualquer lugar.
##
## ## O que a rua produz, desde 30/09/2026
##
## Duas coisas, e so duas: **documentos** (vao na mochila e para o quadro da
## pesquisa) e **balas** (vao para o cinto). Lata de comida, pilha, pano sujo e
## o resto do loot generico sairam do jogo a pedido do Joao, para enxugar: o
## que se vascula rende balas para a Beretta, e o que a cura precisa sao os
## documentos.

signal chegou_em_casa
signal saiu_para_a_rua

const CENA_DA_RUA := "res://rua/rua.tscn"
const CENA_DA_CASA := "res://casa/casa.tscn"
const CENA_DO_FIM := "res://fim_de_jogo.tscn"

## Quantos documentos a pesquisa precisa para a cura ficar pronta.
##
## **Numero provisorio, e o que ele esta segurando e um buraco de papel.** A
## pesquisa da cura e do modo Casa: quem fizer aquela frente decide o que ela
## consome, em que ordem e o que mais entra na conta. Isto existe para o ciclo
## do jogo fechar de ponta a ponta enquanto essa decisao nao for tomada.
##
## Sao 4 dos 6 placeholders que o mapa distribui, e a folga e de proposito: com
## 6 um unico dia perdido carregando documento deixaria a partida impossivel de
## ganhar sem avisar. Com 4 da para errar dois dias.
const DOCUMENTOS_PARA_A_CURA := 4

## Quantos dias existem para a cura ficar pronta.
##
## **30, decidido em 09/09/2026.** Antes eram 10, que era o numero da leitura de
## escopo do High Concept - "cerca de 10 niveis, ondas ou estagios", com cada
## dia sendo uma fase. Com 30 essa conta muda, e e assunto para a conversa de
## calibragem com o professor: ou "fase" deixa de ser o dia, ou a leitura passa
## a ser outra.
##
## Duas coisas sao calibradas em cima deste numero e mudaram junto: a escalada
## de zumbis por dia (rua/cenario.gd) e o mato tomando o terreno.
##
## Uma nao mudou, e e a que importa: **quantos documentos a cura pede.** O mapa
## tem 6 e nao repoe, entao com 30 dias o prazo sobra - da para fechar a cura na
## primeira semana e os outros 23 dias nao cobram nada. O conferir_fim.tscn mede
## isso e avisa.
const PRAZO_DA_CURA := 30

## Qual dia esta correndo.
##
## O dia e o prazo atravessam os dois modos: a rua mostra na HUD quanto falta e
## gasta o dia vasculhando, a casa e quem gasta o dia pesquisando. O relogio de
## DENTRO de um dia - a luz que acaba - e coisa so da rua, e mora em
## rua/relogio.gd.
var dia := 1

## Os documentos que o jogador **entregou** em casa, acumulados de todos os
## dias.
##
## Nao e o que ele carrega: isso e a mochila da rua (rua/mochila.gd), e so vira
## isto aqui quando o dia acaba pela porta de casa. Quem for pego pelo
## amanhecer na rua chega de mao vazia.
##
## A rua so acrescenta. **Quem constroi a casa decide o que e consumido** e
## esvazia o que gastou - por isso nada aqui se limpa sozinho.
var documentos: Array[String] = []

## Quais dos documentos entregues ja foram estudados na casa. Atravessa as
## noites porque estudar gasta energia - estudar de novo amanha seria pagar
## duas vezes. **Nao entra na conta da cura** (ver a_cura_esta_pronta).
var documentos_lidos: Array[String] = []

## As balas da Beretta 9mm. **Voce comeca armado** (30/09/2026, regra do Joao):
## a arma nao e loot nem recompensa, e o que voce tem desde o primeiro dia. O
## que o vasculho rende sao as balas, e so elas - ver rua/pistola.gd para as
## tres regras que mantem a arma servindo o vasculho em vez de virar um jogo de
## tiro.
##
## As balas sao **equipamento, nao loot**: nao ocupam vaga na mochila (estao no
## cinto) e **nao se perdem no dia que deu errado** - o mapa nao repoe, e
## perder a municao inteira seria beco sem saida sem aviso.
var municao := BALAS_DE_COMECO

## Com quantas balas a partida comeca: um pente de Beretta 92. **Proposta** -
## o Joao pediu que se comece armado, e a quantidade e calibragem.
const BALAS_DE_COMECO := 15

## O que ficou na rua no dia que deu errado. A casa mostra no lugar do que
## teria chegado: sem isso, nao voltar pela porta seria indistinguivel de ter
## voltado com a mochila vazia.
var documentos_perdidos := 0

## Quais moveis do mapa ja foram vasculhados, pela chave de cada um.
##
## **O mundo esvazia e nao repoe** - e o que o PZ faz e o que o High Concept
## declara: "a geografia e fixa e o que muda e o estado do mundo". O mapa e
## gerado sempre igual, de semente fixa, entao a chave de um movel e a mesma
## todo dia e serve de nome.
##
## Vale mesmo no dia que deu errado: se voce tirou o que tinha do movel, ele
## saiu do mundo, tenha voce chegado em casa ou nao.
var moveis_vazios := {}

## Chamado pela mochila da rua quando o dia acaba pela porta de casa.
func receber(docs: Array[String]) -> void:
	documentos.append_array(docs)

## Chamado pela mochila da rua quando o dia acaba de qualquer outro jeito.
func perder_na_rua(quantos_documentos: int) -> void:
	documentos_perdidos = quantos_documentos

## Como o dia na rua acabou. Sao tres jeitos, e eles NAO valem o mesmo:
##
##  - PELA_PORTA - voce trancou a porta por vontade propria. E o unico bom;
##  - AMANHECEU_NA_RUA - a noite passou por cima de voce e o dia virou a forca;
##  - SEM_VIDA - voce nao aguentou. Saiu em 16/09/2026 com a vida, e voltou
##    com ela em 30/09/2026.
##
## A diferenca vira consequencia na mochila: quem entra pela porta entrega os
## documentos, quem nao entra volta de mao vazia. Por isso o motivo mora aqui,
## e nao dentro da rua.
enum FimDoDia { PELA_PORTA, AMANHECEU_NA_RUA, SEM_VIDA }

var fim_do_dia := FimDoDia.PELA_PORTA

## Chamado pela porta da sua casa, na rua - e tambem pelo relogio, quando o dia
## acaba na forca ao amanhecer, e pelo jogador, quando a vida acaba.
func entrar_em_casa(motivo := FimDoDia.PELA_PORTA) -> void:
	fim_do_dia = motivo
	chegou_em_casa.emit()
	get_tree().change_scene_to_file(CENA_DA_CASA)

## Quantos dias sobram depois de hoje.
func dias_restantes() -> int:
	return maxi(0, PRAZO_DA_CURA - dia)

## Se hoje e o ultimo dia. Quem chama e a casa, antes de deixar sair: sair de
## novo seria depois do prazo, e o prazo se esgotar e a derrota. A regra fica
## aqui porque o prazo mora aqui; quem mostra a tela e a casa.
func e_o_ultimo_dia() -> bool:
	return dia >= PRAZO_DA_CURA

## Chamado pela casa quando o jogador sai para o dia seguinte. Nao confere o
## prazo - quem confere e quem chama, por e_o_ultimo_dia().
func sair_para_a_rua() -> void:
	dia += 1
	# O prejuizo de ontem ja foi mostrado; a mochila do dia novo nasce vazia.
	documentos_perdidos = 0
	saiu_para_a_rua.emit()
	get_tree().change_scene_to_file(CENA_DA_RUA)

## Como a PARTIDA acabou - nao confundir com FimDoDia, que e como o dia acabou.
##
## Sao os dois desfechos que o High Concept declara, e so eles: ou a cura fica
## pronta a tempo, ou o prazo se esgota. Nao ha terceiro: desde 16/09/2026 nao
## ha como cair na rua - ver rua/jogador.gd.
enum Desfecho { VITORIA, PRAZO_ESGOTADO }

var desfecho := Desfecho.VITORIA

## Se a pesquisa juntou documento bastante. Quem pergunta e a casa, que e quem
## faz a pesquisa.
func a_cura_esta_pronta() -> bool:
	return documentos.size() >= DOCUMENTOS_PARA_A_CURA

## Fim de partida. Chamado pela casa nos dois casos: ela e quem sabe se a cura
## ficou pronta e ela e quem segura o prazo.
func acabar_o_jogo(qual: Desfecho) -> void:
	desfecho = qual
	get_tree().change_scene_to_file(CENA_DO_FIM)

## Comeca outra partida do zero. Zera tudo o que atravessa o dia - inclusive os
## moveis vazios, senao a segunda partida comecaria num mapa ja saqueado.
func recomecar() -> void:
	dia = 1
	municao = BALAS_DE_COMECO
	documentos.clear()
	documentos_lidos.clear()
	moveis_vazios.clear()
	documentos_perdidos = 0
	fim_do_dia = FimDoDia.PELA_PORTA
	get_tree().change_scene_to_file(CENA_DA_RUA)
