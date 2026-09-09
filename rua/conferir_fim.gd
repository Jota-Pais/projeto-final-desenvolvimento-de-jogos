extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no fim de jogo, no prazo,
## na condicao de vitoria ou na escalada dos dias.**
##
## Confere as seis coisas que fazem o ciclo fechar:
##
##  1. **a partida da para ganhar** - o bairro tem documento bastante, com folga
##     para dias perdidos;
##  2. juntar os documentos leva a vitoria, e ela vem ANTES do prazo (cura
##     pronta no ultimo dia e vitoria, nao derrota);
##  3. passar do ultimo dia sem a cura leva a derrota, e a tela dela e a parodia
##     de final feliz - com o game over so na letra miuda;
##  4. **morrer custa o dia e nao a partida** - nao existe terceiro desfecho;
##  5. **a rua piora com os dias**: mais zumbi a cada dia que passa;
##  6. recomecar zera tudo, inclusive os moveis vazios - senao a segunda
##     partida comeca num bairro ja saqueado.
##
## O item 1 e o unico que pode reprovar o DESENHO e nao o codigo: se o bairro
## nao tiver documento bastante, a partida e inganhavel e nada aqui avisaria.

const Construcao := preload("res://rua/construcao.gd")
const Cenario := preload("res://rua/cenario.gd")
const Relogio := preload("res://rua/relogio.gd")

## Velocidade de caminhada, para traduzir distancia em segundos de dia. Tem que
## bater com a VELOCIDADE do rua/jogador.gd.
const VELOCIDADE := 280.0
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const CENA_DA_CASA := preload("res://casa/casa.tscn")
const CENA_DO_FIM := preload("res://fim_de_jogo.tscn")

var _falhas := 0

## Problema de DESENHO, nao de codigo. Nao reprova a rodada - o codigo esta
## certo -, mas aparece no fim em corpo proprio, porque e o tipo de coisa que
## ninguem descobre jogando dois minutos.
var _atencoes := 0

var _rodou := false

func _process(_delta: float) -> void:
	if _rodou:
		return
	_rodou = true

	_a_partida_da_para_ganhar()
	_a_cura_e_a_vitoria()
	_o_prazo_e_a_derrota()
	_morrer_custa_o_dia()
	_a_rua_piora_com_os_dias()
	_recomecar_zera_tudo()

	_limpar()
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	if _atencoes > 0:
		print("%d ponto(s) de ATENCAO - desenho, nao codigo" % _atencoes)
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _atencao(texto: String) -> void:
	_atencoes += 1
	print("  ATENCAO: " + texto)

func _limpar() -> void:
	Travessia.dia = 1
	Travessia.mochila.clear()
	Travessia.documentos.clear()
	Travessia.moveis_vazios.clear()
	Travessia.itens_perdidos = 0
	Travessia.documentos_perdidos = 0
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA
	Travessia.desfecho = Travessia.Desfecho.VITORIA

## A troca de cena arranca a cena atual da arvore na hora, e levaria esta
## ferramenta embora - o get_tree() seguinte viria nulo e o quit() nunca
## aconteceria. Sair de "cena atual" pelo tempo da chamada resolve.
func _sem_ser_a_cena_atual(alvo: Node, evento: InputEvent) -> void:
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	alvo._unhandled_input(evento)
	get_tree().current_scene = cena_atual
	_limpar_a_raiz()

## A troca de cena pode ter posto a cena nova na raiz, do lado da ferramenta.
func _limpar_a_raiz() -> void:
	for filho in get_tree().root.get_children():
		if filho.name in ["Rua", "Casa", "FimDeJogo"]:
			filho.free()

func _tecla() -> InputEventAction:
	var evento := InputEventAction.new()
	evento.action = "vasculhar"
	evento.pressed = true
	return evento

# --- 1. a partida da para ganhar --------------------------------------------

func _a_partida_da_para_ganhar() -> void:
	print("\n1. a partida da para ganhar")
	_limpar()
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)

	# Onde estao os documentos, e quanto custa buscar cada um.
	#
	# Ate o mapa grande a conta era so a luz do vasculho, varrendo os moveis na
	# ordem de geracao. **Num mapa de 1,44 km o caminho a pe e o custo, nao o
	# vasculho** - o documento da mansao esta a 1.070 m de casa. Entao a conta e
	# por viagem: ida e volta ate o documento, mais a luz de esvaziar o movel.
	var no_mapa := 0
	var custos: Array[float] = []
	var casa := (rua.get_node("EntradaDeCasa") as Node2D).position
	for filho in rua.get_node("Cenario").get_children():
		if not (filho is Area2D and "achados" in filho):
			continue
		for achado in filho.achados:
			if not Construcao.e_documento(achado):
				continue
			no_mapa += 1
			var ida_e_volta: float = casa.distance_to((filho as Node2D).position) * 2.0 / VELOCIDADE
			custos.append(ida_e_volta + filho.duracao * (1.0 + Relogio.CUSTO_DO_VASCULHO))
	custos.sort()
	rua.free()

	# Os mais baratos primeiro: e um piso, e quem joga bem faz melhor que isso
	# juntando dois documentos na mesma viagem.
	var luz_ate_a_cura := 0.0
	for i in mini(Travessia.DOCUMENTOS_PARA_A_CURA, custos.size()):
		luz_ate_a_cura += custos[i]

	var precisa := Travessia.DOCUMENTOS_PARA_A_CURA
	var no_bairro := no_mapa
	print("  a cura pede %d documentos e o mapa tem %d" % [precisa, no_mapa])
	if no_bairro < precisa:
		_erro("a partida e inganhavel: faltam %d documentos no mapa" % (precisa - no_bairro))
	elif no_bairro == precisa:
		_erro("sem folga nenhuma: perder um documento na rua deixa a partida"
			+ " inganhavel sem avisar o jogador")
	else:
		print("  folga de %d documento(s) - da para errar %d dia(s) carregando documento"
			% [no_bairro - precisa, no_bairro - precisa])

	_o_prazo_cobra_algo(luz_ate_a_cura)

## Em quantos dias, no piso, a cura pode fechar - e como isso se compara com o
## prazo.
##
## **Prazo que ninguem alcanca nao e pressao, e enfeite.** Se a cura fecha na
## primeira semana de um prazo de 30 dias, os outros 23 nao cobram nada, e o
## relogio, a noite e a escalada estao empurrando o jogador para um lugar onde
## nao ha ninguem esperando.
##
## Nao e FALHA: o codigo esta certo. E ATENCAO, que e o que se usa quando o
## problema e de desenho - e desenho e decisao de mesa.
func _o_prazo_cobra_algo(luz_ate_a_cura: float) -> void:
	if luz_ate_a_cura <= 0.0:
		return
	var dias := luz_ate_a_cura / Relogio.DURACAO_DO_DIA
	print("  no piso, a cura fecha em %.1f dia(s) - viagem mais vasculho - e o prazo sao %d"
		% [dias, Travessia.PRAZO_DA_CURA])
	# Metade do prazo e a fronteira: com a cura fechando depois disso, os
	# ultimos dias ainda estao em jogo.
	if dias * 2.0 < float(Travessia.PRAZO_DA_CURA):
		_atencao("o prazo sobra - a cura fecha em ~%.0f%% dele, e o resto nao cobra nada."
			% (dias / float(Travessia.PRAZO_DA_CURA) * 100.0)
			+ " Ou a cura pede mais, ou o bairro da menos, ou o prazo e menor")

# --- 2. a cura e a vitoria --------------------------------------------------

func _a_cura_e_a_vitoria() -> void:
	print("\n2. a cura e a vitoria")
	_limpar()

	# Um documento a menos do que a cura pede: ainda nao.
	for i in Travessia.DOCUMENTOS_PARA_A_CURA - 1:
		Travessia.documentos.append(Construcao.DOCUMENTOS[i])
	if Travessia.a_cura_esta_pronta():
		_erro("a cura ficou pronta com %d de %d documentos"
			% [Travessia.documentos.size(), Travessia.DOCUMENTOS_PARA_A_CURA])

	var casa := CENA_DA_CASA.instantiate()
	add_child(casa)
	if (casa.get_node("Conteudo/Saida") as Label).text.contains("TERMINAR"):
		_erro("a casa ofereceu terminar a cura faltando documento")
	casa.free()

	# O que falta.
	Travessia.documentos.append(Construcao.DOCUMENTOS[Travessia.DOCUMENTOS_PARA_A_CURA - 1])
	if not Travessia.a_cura_esta_pronta():
		_erro("a cura nao ficou pronta com os %d documentos" % Travessia.documentos.size())

	# E no ULTIMO dia, de proposito: pronta no ultimo dia e pronta a tempo, e a
	# ordem das duas regras na casa e o que decide isso.
	Travessia.dia = Travessia.PRAZO_DA_CURA
	casa = CENA_DA_CASA.instantiate()
	add_child(casa)
	if not (casa.get_node("Conteudo/Saida") as Label).text.contains("TERMINAR"):
		_erro("com a cura pronta a casa nao ofereceu terminar: \"%s\""
			% (casa.get_node("Conteudo/Saida") as Label).text)
	_sem_ser_a_cena_atual(casa, _tecla())
	casa.free()

	if Travessia.desfecho != Travessia.Desfecho.VITORIA:
		_erro("cura pronta no ultimo dia deu derrota")
	else:
		print("  %d documentos no dia %d de %d: vitoria"
			% [Travessia.documentos.size(), Travessia.dia, Travessia.PRAZO_DA_CURA])

	_a_tela_do_fim("A CURA", "você ganhou")

# --- 3. o prazo e a derrota -------------------------------------------------

func _o_prazo_e_a_derrota() -> void:
	print("\n3. o prazo e a derrota")
	_limpar()
	Travessia.dia = Travessia.PRAZO_DA_CURA

	var casa := CENA_DA_CASA.instantiate()
	add_child(casa)
	var dia_antes := Travessia.dia
	_sem_ser_a_cena_atual(casa, _tecla())
	casa.free()

	if Travessia.dia != dia_antes:
		_erro("a casa deixou sair no ultimo dia - o dia virou %d" % Travessia.dia)
	elif Travessia.desfecho != Travessia.Desfecho.PRAZO_ESGOTADO:
		_erro("passar do ultimo dia sem a cura nao deu derrota")
	else:
		print("  dia %d de %d sem a cura: derrota" % [dia_antes, Travessia.PRAZO_DA_CURA])

	# A parodia: o titulo e de final feliz, e "game over" so aparece na letra
	# miuda. Se alguem trocar o titulo por "VOCE PERDEU", o diferencial do
	# projeto morre - e essa e a unica coisa que esta tela nao pode perder.
	var fim := _a_tela_do_fim("FELIZES", "game over")
	if fim == null:
		return
	var titulo: String = (fim.get_node("Conteudo/Titulo") as Label).text
	if titulo.to_lower().contains("derrota") or titulo.to_lower().contains("perdeu"):
		_erro("o titulo da derrota entregou o jogo: \"%s\"" % titulo)
	if (fim.get_node("Conteudo/Titulo") as Label).get_theme_font_size("font_size") \
			<= (fim.get_node("Conteudo/Rodape") as Label).get_theme_font_size("font_size"):
		_erro("o \"game over\" nao esta menor que o final feliz")
	fim.free()

## Monta a tela do fim e confere que ela diz o que devia. Devolve a tela ainda
## na arvore quando quem chamou quiser olhar mais - senao ja libera.
func _a_tela_do_fim(no_titulo: String, no_rodape: String) -> Node:
	var fim := CENA_DO_FIM.instantiate()
	add_child(fim)
	var titulo: String = (fim.get_node("Conteudo/Titulo") as Label).text
	var rodape: String = (fim.get_node("Conteudo/Rodape") as Label).text
	var numeros: String = (fim.get_node("Conteudo/Numeros") as Label).text

	var bom := true
	if not titulo.contains(no_titulo):
		_erro("o titulo do fim nao fala de \"%s\": \"%s\"" % [no_titulo, titulo])
		bom = false
	if not rodape.contains(no_rodape):
		_erro("o rodape do fim nao fala de \"%s\": \"%s\"" % [no_rodape, rodape])
		bom = false
	if not numeros.contains("%d dias" % Travessia.dia):
		_erro("os numeros do fim nao dizem os dias: \"%s\"" % numeros)
		bom = false
	if bom:
		print("  \"%s\" / %s / \"%s\"" % [titulo, numeros, rodape])
	return fim

# --- 4. morrer custa o dia, e nao a partida ---------------------------------

## O High Concept declara dois desfechos, e morrer na rua nao e nenhum deles.
## Quem morre acorda em casa sem nada do que carregava, e paga um dia do prazo.
func _morrer_custa_o_dia() -> void:
	print("\n4. morrer custa o dia")
	_limpar()
	Travessia.dia = 4
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)
	var jogador := rua.get_node("Jogador") as Node2D
	var mochila := rua.get_node("Mochila")

	# Enche a mochila e mata.
	for filho in rua.get_node("Cenario").get_children():
		if filho is Area2D and "achados" in filho and not filho._vazio:
			filho._esvaziar()
			if mochila.quantos() > 0:
				break
	var carregava: int = mochila.quantos()

	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	jogador.levar_dano(999.0, Vector2.UP)
	get_tree().current_scene = cena_atual
	_limpar_a_raiz()

	if Travessia.fim_do_dia != Travessia.FimDoDia.SEM_VIDA:
		_erro("morrer nao registrou SEM_VIDA")
	elif Travessia.mochila.size() + Travessia.documentos.size() != 0:
		_erro("morrer entregou coisa em casa")
	elif Travessia.itens_perdidos + Travessia.documentos_perdidos != carregava:
		_erro("morrer perdeu %d de %d coisas"
			% [Travessia.itens_perdidos + Travessia.documentos_perdidos, carregava])
	else:
		print("  morreu carregando %d coisa(s): perdeu tudo e o dia continua %d"
			% [carregava, Travessia.dia])
	rua.free()

# --- 5. a rua piora com os dias ---------------------------------------------

func _a_rua_piora_com_os_dias() -> void:
	print("\n5. a rua piora com os dias")
	_limpar()
	var antes := 0
	for dia in [1, 5, Travessia.PRAZO_DA_CURA]:
		Travessia.dia = dia
		var rua := CENA_DA_RUA.instantiate()
		add_child(rua)
		var quantos := get_tree().get_nodes_in_group("zumbi").size()
		rua.free()

		if quantos <= antes:
			_erro("no dia %d a rua tem %d zumbis, e no dia anterior tinha %d"
				% [dia, quantos, antes])
		else:
			print("  dia %-2d: %d zumbis de dia, %d na noite fechada"
				% [dia, quantos, quantos + Cenario.ZUMBIS_DA_NOITE])
		antes = quantos

# --- 6. recomecar zera tudo -------------------------------------------------

func _recomecar_zera_tudo() -> void:
	print("\n6. recomecar zera tudo")
	Travessia.dia = 7
	Travessia.mochila.append("lata de comida")
	Travessia.documentos.append(Construcao.DOCUMENTOS[0])
	Travessia.moveis_vazios[3] = true
	Travessia.itens_perdidos = 5
	Travessia.fim_do_dia = Travessia.FimDoDia.SEM_VIDA

	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	Travessia.recomecar()
	get_tree().current_scene = cena_atual
	_limpar_a_raiz()

	var sujo := []
	if Travessia.dia != 1:
		sujo.append("dia %d" % Travessia.dia)
	if not Travessia.mochila.is_empty():
		sujo.append("%d itens" % Travessia.mochila.size())
	if not Travessia.documentos.is_empty():
		sujo.append("%d documentos" % Travessia.documentos.size())
	if not Travessia.moveis_vazios.is_empty():
		sujo.append("%d moveis vazios" % Travessia.moveis_vazios.size())
	if Travessia.itens_perdidos != 0:
		sujo.append("%d itens perdidos" % Travessia.itens_perdidos)
	if Travessia.fim_do_dia != Travessia.FimDoDia.PELA_PORTA:
		sujo.append("fim do dia %d" % Travessia.fim_do_dia)

	if sujo.is_empty():
		print("  a partida nova comeca no dia 1, de mochila vazia e bairro cheio")
	else:
		_erro("sobrou da partida anterior: " + ", ".join(sujo))
