extends Control
## Lugar reservado para o modo Casa - o ponto e clique, a namorada no porao e a
## pesquisa da cura.
##
## Isto NAO e a casa. E o espaco onde ela vai ser feita, e o que aparece hoje
## ao voltar da rua, para a travessia funcionar de ponta a ponta enquanto a
## outra metade da equipe nao comeca. Quem for fazer esta frente troca esta
## cena por uma de verdade e nao precisa mexer em nada da rua.
##
## **E ela quem fecha o ciclo do jogo**, dos dois lados, porque e ela quem faz
## a pesquisa e quem segura o prazo:
##
##  - juntou documento bastante -> a cura fica pronta, e e a vitoria;
##  - passou do ultimo dia sem isso -> o prazo se esgota, e e a derrota.
##
## As regras sao do Travessia (a_cura_esta_pronta, e_o_ultimo_dia); as telas
## sao daqui e do fim_de_jogo.tscn.

## Cor do texto quando o prazo esta perto, e quando a cura esta pronta.
const COR_APERTO := Color("d8a13c")
const COR_CURA := Color("8fc08a")

func _ready() -> void:
	($Conteudo/Dia as Label).text = _linha_do_dia()
	($Conteudo/Trouxe as Label).text = _o_que_voltou()
	_escrever_a_saida()

## O que a tecla E faz agora - e sao tres coisas diferentes, na ordem em que a
## regra decide.
func _escrever_a_saida() -> void:
	var saida := $Conteudo/Saida as Label
	if Travessia.a_cura_esta_pronta():
		saida.text = "E  —  TERMINAR A CURA (%d de %d documentos)" % [
			Travessia.documentos.size(), Travessia.DOCUMENTOS_PARA_A_CURA
		]
		saida.add_theme_color_override("font_color", COR_CURA)
		return
	if Travessia.e_o_ultimo_dia():
		saida.text = "E  —  o prazo acabou (%d de %d documentos)" % [
			Travessia.documentos.size(), Travessia.DOCUMENTOS_PARA_A_CURA
		]
		saida.add_theme_color_override("font_color", COR_APERTO)
		return
	saida.text = "E  —  sair para a rua no dia seguinte  (pesquisa: %d de %d documentos)" % [
		Travessia.documentos.size(), Travessia.DOCUMENTOS_PARA_A_CURA
	]

func _unhandled_input(evento: InputEvent) -> void:
	if not (evento.is_action_pressed("vasculhar") or evento.is_action_pressed("ui_accept")):
		return

	# A vitoria vem antes do prazo: se a cura ficou pronta no ultimo dia, ela
	# ficou pronta a tempo.
	if Travessia.a_cura_esta_pronta():
		Travessia.acabar_o_jogo(Travessia.Desfecho.VITORIA)
		return
	# O ultimo dia e o dia PRAZO_DA_CURA. Sair dele levaria para um dia que nao
	# existe mais, e e ai que o prazo se esgota.
	if Travessia.e_o_ultimo_dia():
		Travessia.acabar_o_jogo(Travessia.Desfecho.PRAZO_ESGOTADO)
		return
	Travessia.sair_para_a_rua()

## Os tres jeitos de o dia ter acabado nao valem o mesmo, e a tela tem que
## dizer qual foi. Hoje a diferenca e so o texto; com a mochila do passo 4,
## quem nao entrou pela porta volta de mao vazia.
func _linha_do_dia() -> String:
	var faltam := Travessia.dias_restantes()
	var quanto := "hoje era o último dia"
	if faltam == 1:
		quanto = "falta 1 dia para o prazo"
	elif faltam > 1:
		quanto = "faltam %d dias para o prazo" % faltam

	var como := "Você trancou o porão"
	match Travessia.fim_do_dia:
		Travessia.FimDoDia.AMANHECEU_NA_RUA:
			como = "Amanheceu com você na rua"
		Travessia.FimDoDia.SEM_VIDA:
			como = "Você não aguentou o dia"

	return "%s — dia %d de %d, %s" % [
		como, Travessia.dia, Travessia.PRAZO_DA_CURA, quanto
	]


func _o_que_voltou() -> String:
	if Travessia.fim_do_dia != Travessia.FimDoDia.PELA_PORTA:
		var perdeu := Travessia.itens_perdidos + Travessia.documentos_perdidos
		if perdeu == 0:
			return "Você não estava carregando nada — não havia o que perder."
		var linha := "Ficou na rua: %d %s" % [
			Travessia.itens_perdidos,
			"item" if Travessia.itens_perdidos == 1 else "itens"
		]
		if Travessia.documentos_perdidos > 0:
			linha += " e %d documento%s" % [
				Travessia.documentos_perdidos,
				"" if Travessia.documentos_perdidos == 1 else "s"
			]
		return linha + ". Nada disso entrou em casa."

	if Travessia.mochila.is_empty() and Travessia.documentos.is_empty():
		return "Da rua não veio nada — você voltou de mochila vazia."

	var linhas := []
	if not Travessia.mochila.is_empty():
		linhas.append("Mochila: " + ", ".join(Travessia.mochila))
	if not Travessia.documentos.is_empty():
		linhas.append("Documentos: " + ", ".join(Travessia.documentos))
	return "\n".join(linhas)
