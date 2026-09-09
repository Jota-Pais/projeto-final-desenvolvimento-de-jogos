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

signal chegou_em_casa
signal saiu_para_a_rua

const CENA_DA_RUA := "res://rua/rua.tscn"
const CENA_DA_CASA := "res://casa/casa.tscn"
const CENA_DO_FIM := "res://fim_de_jogo.tscn"

## Quantos documentos a pesquisa precisa para a cura ficar pronta.
##
## **Numero provisorio, e o que ele esta segurando e um buraco de papel.** A
## pesquisa da cura e do modo Casa: quem fizer aquela frente decide o que ela
## consome, em que ordem e o que mais entra na conta (remedio? ferramenta?
## tempo dentro de casa?). Isto existe para o ciclo do jogo fechar de ponta a
## ponta enquanto essa decisao nao for tomada.
##
## Sao 4 dos 6 que o bairro tem, e a folga e de proposito: com 6 um unico dia
## perdido carregando documento deixaria a partida impossivel de ganhar sem
## avisar. Com 4 da para errar dois dias.
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
## Uma nao mudou, e e a que importa: **quantos documentos a cura pede.** O
## bairro tem 6 e nao repoe, entao com 30 dias o prazo sobra - da para fechar a
## cura na primeira semana e os outros 23 dias nao cobram nada. O
## conferir_fim.tscn mede isso e avisa.
const PRAZO_DA_CURA := 30

## Qual dia esta correndo.
##
## O dia e o prazo atravessam os dois modos: a rua mostra na HUD quanto falta e
## gasta o dia vasculhando, a casa e quem gasta o dia pesquisando. O relogio de
## DENTRO de um dia - a luz que acaba - e coisa so da rua, e mora em
## rua/relogio.gd.
var dia := 1

## O que o jogador **entregou** em casa, acumulado de todos os dias.
##
## Nao e o que ele carrega: isso e a mochila da rua (rua/mochila.gd), e so vira
## isto aqui quando o dia acaba pela porta do porao. Quem for pego pelo
## amanhecer ou cair sem vida chega de mao vazia.
##
## A rua so acrescenta. **Quem constroi a casa decide o que e consumido** e
## esvazia o que gastou - por isso nada aqui se limpa sozinho.
var mochila: Array[String] = []
var documentos: Array[String] = []

## O que ficou na rua no dia que deu errado. A casa mostra no lugar do que
## teria chegado: sem isso, nao voltar pela porta seria indistinguivel de ter
## voltado com a mochila vazia.
var itens_perdidos := 0
var documentos_perdidos := 0

## Quais moveis do bairro ja foram vasculhados, por indice.
##
## **O mundo esvazia e nao repoe** - e o que o PZ faz e o que o High Concept
## declara: "a geografia e fixa e o que muda e o estado do mundo". O bairro e
## gerado sempre igual, de semente fixa, entao o indice de um movel e o mesmo
## todo dia e serve de nome.
##
## Vale mesmo no dia que deu errado: se voce tirou o loot do movel, ele saiu do
## mundo, tenha voce chegado em casa ou nao. Gastar o dia numa casa custa
## aquela casa amanha.
var moveis_vazios := {}

## Chamado pela mochila da rua quando o dia acaba pela porta do porao.
func receber(itens: Array[String], docs: Array[String]) -> void:
	mochila.append_array(itens)
	documentos.append_array(docs)

## Chamado pela mochila da rua quando o dia acaba de qualquer outro jeito.
func perder_na_rua(quantos_itens: int, quantos_documentos: int) -> void:
	itens_perdidos = quantos_itens
	documentos_perdidos = quantos_documentos

## Como o dia na rua acabou. Sao tres jeitos, e eles NAO valem o mesmo:
##
##  - PELA_PORTA - voce trancou o porao por vontade propria. E o unico bom;
##  - AMANHECEU_NA_RUA - a noite passou por cima de voce e o dia virou a forca;
##  - SEM_VIDA - voce nao aguentou.
##
## Hoje a diferenca e so o texto que a casa mostra. **Com a mochila do passo 4
## e aqui que ela vira consequencia:** quem entra pela porta entrega o que
## achou, quem nao entra volta de mao vazia. Por isso o motivo mora aqui, e nao
## dentro da rua.
enum FimDoDia { PELA_PORTA, AMANHECEU_NA_RUA, SEM_VIDA }

var fim_do_dia := FimDoDia.PELA_PORTA

## Chamado pela porta da sua casa, na rua - e tambem pelo relogio, quando
## amanhece, e pelo jogador, quando a vida acaba.
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
	itens_perdidos = 0
	documentos_perdidos = 0
	saiu_para_a_rua.emit()
	get_tree().change_scene_to_file(CENA_DA_RUA)

## Como a PARTIDA acabou - nao confundir com FimDoDia, que e como o dia acabou.
##
## Sao os dois desfechos que o High Concept declara, e so eles: ou a cura fica
## pronta a tempo, ou o prazo se esgota. **Morrer na rua nao e desfecho** - ver
## rua/jogador.gd.
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
## moveis vazios, senao a segunda partida comecaria num bairro ja saqueado.
func recomecar() -> void:
	dia = 1
	mochila.clear()
	documentos.clear()
	moveis_vazios.clear()
	itens_perdidos = 0
	documentos_perdidos = 0
	fim_do_dia = FimDoDia.PELA_PORTA
	get_tree().change_scene_to_file(CENA_DA_RUA)
