extends Control
## Lugar reservado para o modo Casa - o ponto e clique, a namorada no porao e a
## pesquisa da cura.
##
## Isto NAO e a casa. E o espaco onde ela vai ser feita, e o que aparece hoje
## ao voltar da rua, para a travessia funcionar de ponta a ponta enquanto a
## outra metade da equipe nao comeca. Quem for fazer esta frente troca esta
## cena por uma de verdade e nao precisa mexer em nada da rua.

func _ready() -> void:
	($Conteudo/Dia as Label).text = "Anoiteceu — fim do dia %d" % Travessia.dia
	($Conteudo/Trouxe as Label).text = _o_que_voltou()

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("vasculhar") or evento.is_action_pressed("ui_accept"):
		Travessia.sair_para_a_rua()

func _o_que_voltou() -> String:
	if Travessia.mochila.is_empty() and Travessia.documentos.is_empty():
		return "Da rua não veio nada — a mochila só passa a ser preenchida no passo 4."

	var linhas := []
	if not Travessia.mochila.is_empty():
		linhas.append("Mochila: " + ", ".join(Travessia.mochila))
	if not Travessia.documentos.is_empty():
		linhas.append("Documentos: " + ", ".join(Travessia.documentos))
	return "\n".join(linhas)
