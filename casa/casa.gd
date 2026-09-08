extends Control
## Lugar reservado para o modo Casa - o ponto e clique, a namorada no porao e a
## pesquisa da cura.
##
## Isto NAO e a casa. E o espaco onde ela vai ser feita, e o que aparece hoje
## ao voltar da rua, para a travessia funcionar de ponta a ponta enquanto a
## outra metade da equipe nao comeca. Quem for fazer esta frente troca esta
## cena por uma de verdade e nao precisa mexer em nada da rua.
##
## Ela e quem segura o prazo: sair para a rua depois do ultimo dia seria depois
## do prazo, e o prazo se esgotar e a derrota. A regra e do Travessia
## (e_o_ultimo_dia), a tela e daqui.

## Cor do texto quando o prazo esta perto, e quando ele venceu.
const COR_APERTO := Color("d8a13c")
const COR_DERROTA := Color("c0463c")

var _acabou := false

func _ready() -> void:
	($Conteudo/Dia as Label).text = _linha_do_dia()
	($Conteudo/Trouxe as Label).text = _o_que_voltou()
	if Travessia.e_o_ultimo_dia():
		var saida := $Conteudo/Saida as Label
		saida.text = "E  —  sair para a rua no ÚLTIMO dia antes do prazo"
		saida.add_theme_color_override("font_color", COR_APERTO)

func _unhandled_input(evento: InputEvent) -> void:
	if _acabou:
		return
	if not (evento.is_action_pressed("vasculhar") or evento.is_action_pressed("ui_accept")):
		return
	# O ultimo dia e o dia PRAZO_DA_CURA. Sair dele levaria para um dia que nao
	# existe mais, e e ai que o prazo se esgota.
	if Travessia.e_o_ultimo_dia():
		_derrota()
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

## Provisorio. A tela de fim de jogo e o passo 5, e o High Concept ja disse o
## que ela mostra: a derrota apresentada em tom de parodia, como se fosse o
## final feliz de um casal. Isto aqui e so o texto no lugar dela - o prazo
## precisava ter consequencia para o relogio da rua querer dizer algo.
func _derrota() -> void:
	_acabou = true
	var titulo := $Conteudo/Titulo as Label
	titulo.text = "O PRAZO SE ESGOTOU"
	titulo.add_theme_color_override("font_color", COR_DERROTA)
	($Conteudo/Dia as Label).text = "Foram os %d dias. A cura não ficou pronta." % Travessia.PRAZO_DA_CURA
	($Conteudo/Trouxe as Label).text = "Ela escapa do porão."
	var saida := $Conteudo/Saida as Label
	saida.text = "Aqui entra a tela de fim de jogo — a derrota em tom de paródia (passo 5)."
	saida.add_theme_color_override("font_color", COR_DERROTA)

## O que chegou, ou o que ficou na calcada. Sao as duas metades da mesma regra:
## so entra em casa o que passou pela porta do porao.
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
