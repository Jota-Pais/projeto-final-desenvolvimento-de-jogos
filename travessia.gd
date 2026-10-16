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

const CENA_DO_TITULO := "res://titulo.tscn"
const CENA_DA_RUA := "res://rua/rua.tscn"
const CENA_DA_CASA := "res://casa/casa.tscn"
const CENA_DO_FIM := "res://fim_de_jogo.tscn"

## Os dois modos de jogo (Joao, 15/10/2026: "cria dois modos, um hardcore e
## um campanha, o hardcore morreu = perdeu, o campanha morreu = o personagem
## volta pra casa mas perde o dia"). A unica diferenca e o que acontece quando
## a vida zera na rua (rua/jogador.gd, levar_dano): na campanha o dia acaba
## na forca e ele acorda em casa sem o que carregava; no hardcore a partida
## acaba. Escolhido na tela de titulo; recomecar volta para la.
enum Modo { CAMPANHA, HARDCORE }

var modo := Modo.CAMPANHA

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

## As balas. **Voce comeca armado** (30/09/2026, regra do Joao): a arma nao e
## loot nem recompensa, e o que voce tem desde o primeiro dia. O que o
## vasculho rende sao as balas, e so elas - ver rua/arma.gd para as tres
## regras que mantem a arma servindo o vasculho em vez de virar um jogo de
## tiro.
##
## As balas sao **equipamento, nao loot**: nao ocupam vaga na mochila (estao no
## cinto) e **nao se perdem no dia que deu errado** - o mapa nao repoe, e
## perder a municao inteira seria beco sem saida sem aviso.
##
## **Por calibre** (05/10/2026, Joao: "faz um tipo de municao pra cada"):
## calibre -> quantas. A arma usa a municao do calibre dela (`municao` na
## ficha, rua/arma.gd); os nomes estao em Construcao.MUNICOES.
var balas := balas_de_comeco()

## As balas **da arma na mao**: e o que a HUD mostra e o que o tiro gasta. Ler
## e escrever aqui mexe so no calibre dela; os outros ficam em `balas`.
var municao: int:
	get:
		return balas.get(calibre_da_arma(), 0)
	set(quantas):
		balas[calibre_da_arma()] = quantas

## Com quantas balas a partida comeca: um pente de Beretta 92. **Proposta** -
## o Joao pediu que se comece armado, e a quantidade e calibragem.
const BALAS_DE_COMECO := 15
const CALIBRE_DE_COMECO := "9mm"

const Arma := preload("res://rua/arma.gd")
const Construcao := preload("res://rua/construcao.gd")

## Com o que o cinto nasce. **Para os testes, 15 de cada calibre** (Joao,
## 05/10/2026: "por questao de pratica pros testes faz eu nascer com as balas
## de cada arma no inventario ja, que nem a de 9mm"). A regra de design
## continua "comeca com a Beretta e um pente": quando for para valer, isto
## volta a ser so {CALIBRE_DE_COMECO: BALAS_DE_COMECO}.
static func balas_de_comeco() -> Dictionary:
	var cinto := {}
	for calibre in Construcao.MUNICOES:
		cinto[calibre] = BALAS_DE_COMECO
	return cinto

## O calibre da arma na mao.
func calibre_da_arma() -> String:
	return Arma.ARMAS[arma]["municao"]

## Uma caixinha achada vai para o calibre dela.
func guardar_balas(calibre: String, quantas: int) -> void:
	balas[calibre] = balas.get(calibre, 0) + quantas

## Todas as balas no cinto, de todos os calibres.
func total_de_balas() -> int:
	var total := 0
	for calibre in balas:
		total += balas[calibre]
	return total

## A arma na mao, pelo nome da ficha em rua/arma.gd (`ARMAS`). Atravessa o dia
## como as balas. Comeca com a Beretta (regra de 30/09/2026); como se consegue
## outra e ⬜ - hoje `Q` troca, auxilio de prototipo.
var arma := ARMA_DE_COMECO
const ARMA_DE_COMECO := "Beretta 9mm"

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
## Os dois desfechos que o High Concept declara - ou a cura fica pronta a
## tempo, ou o prazo se esgota - e, desde 15/10/2026, o terceiro, so no modo
## hardcore: cair na rua. Na campanha cair custa o dia, nao a partida (ver
## rua/jogador.gd e `Modo`).
enum Desfecho { VITORIA, PRAZO_ESGOTADO, CAIU_NA_RUA }

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
	arma = ARMA_DE_COMECO
	balas = balas_de_comeco()
	documentos.clear()
	documentos_lidos.clear()
	moveis_vazios.clear()
	documentos_perdidos = 0
	fim_do_dia = FimDoDia.PELA_PORTA
	desfecho = Desfecho.VITORIA
	# De volta ao titulo, e nao direto a rua: a partida nova escolhe o modo.
	get_tree().change_scene_to_file(CENA_DO_TITULO)
