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

## Qual dia esta correndo. A contagem regressiva do prazo da cura e o relogio
## do dia sao o passo 3 e nao moram aqui - por enquanto isto so incrementa a
## cada volta para a rua.
var dia := 1

## O que o jogador trouxe da rua. Fica vazio ate o passo 4 (mochila e itens):
## hoje isto e so o contrato, para o lado da casa ja ter o que ler.
##
## A rua so acrescenta. **Quem constroi a casa decide o que e consumido** e
## esvazia o que gastou - por isso nada aqui se limpa sozinho.
var mochila: Array[String] = []
var documentos: Array[String] = []

## Chamado pela porta da sua casa, na rua.
func entrar_em_casa() -> void:
	chegou_em_casa.emit()
	get_tree().change_scene_to_file(CENA_DA_CASA)

## Chamado pela casa quando o jogador sai para o dia seguinte.
func sair_para_a_rua() -> void:
	dia += 1
	saiu_para_a_rua.emit()
	get_tree().change_scene_to_file(CENA_DA_RUA)
