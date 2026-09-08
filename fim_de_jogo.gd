extends Control
## A tela de fim de jogo, nos dois desfechos que o High Concept declara.
##
## **A derrota e o diferencial do projeto**, e por isso ela nao e uma tela de
## game over: e uma **parodia de final feliz de casal**. O quadro diz que
## viveram felizes para sempre; a letra pequena diz que o prazo acabou, ela saiu
## do porao e agora os dois estao do mesmo lado da porta. O jogo nunca fala a
## palavra "derrota" em cima - ela vem embaixo, em corpo pequeno, como um aviso
## legal.
##
## Isso e material direto para o pitch de investimentos, que pergunta pelo
## diferencial: o game over vestido de final feliz e a coisa mais vendavel que
## o jogo tem, e e de graca.
##
## E uma tela SO de texto, como a casa: quem fizer arte troca isto por uma de
## verdade. O que precisa sobreviver a essa troca e o tom - o final feliz por
## fora, o game over por dentro.

const COR_FELIZ := Color("e8b061")
const COR_CURA := Color("8fc08a")
const COR_CORPO := Color("d8cbb6")
const COR_LETRA_MIUDA := Color("8a7f70")
const COR_GAME_OVER := Color("c0463c")

func _ready() -> void:
	if Travessia.desfecho == Travessia.Desfecho.VITORIA:
		_vitoria()
	else:
		_derrota_em_parodia()
	($Conteudo/Numeros as Label).text = _os_numeros()

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("vasculhar") or evento.is_action_pressed("ui_accept"):
		Travessia.recomecar()

func _vitoria() -> void:
	var titulo := $Conteudo/Titulo as Label
	titulo.text = "A CURA FICOU PRONTA"
	titulo.add_theme_color_override("font_color", COR_CURA)

	($Conteudo/Corpo as Label).text = (
		"Ela abriu os olhos e chamou você pelo nome.\n\n"
		+ "Lá fora o bairro continua sendo o que é. Aqui dentro, não."
	)

	var rodape := $Conteudo/Rodape as Label
	rodape.text = "você ganhou — a cura ficou pronta antes do prazo"
	rodape.add_theme_color_override("font_color", COR_LETRA_MIUDA)

## O quadro e de final feliz e o texto tambem - o que aconteceu de verdade so
## aparece se voce ler. E a piada, e ela e a peca inteira: nao escrever
## "derrota" em lugar nenhum grande e o que faz ela funcionar.
func _derrota_em_parodia() -> void:
	var titulo := $Conteudo/Titulo as Label
	titulo.text = "E FORAM FELIZES PARA SEMPRE"
	titulo.add_theme_color_override("font_color", COR_FELIZ)

	($Conteudo/Corpo as Label).text = (
		"O prazo acabou. Ela saiu do porão, e você não correu.\n\n"
		+ "Agora vocês têm todo o tempo do mundo e nada mais para curar.\n"
		+ "Os dois seguem juntos — do mesmo lado da porta."
	)

	var rodape := $Conteudo/Rodape as Label
	rodape.text = "game over — o prazo da cura se esgotou"
	rodape.add_theme_color_override("font_color", COR_GAME_OVER)

func _os_numeros() -> String:
	return "%d dias   ·   %d de %d documentos   ·   %d itens" % [
		Travessia.dia,
		Travessia.documentos.size(),
		Travessia.DOCUMENTOS_PARA_A_CURA,
		Travessia.mochila.size(),
	]
