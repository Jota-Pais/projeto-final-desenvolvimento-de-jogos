extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no relogio, na noite, na
## HUD ou no prazo.**
##
## Confere as seis coisas que fazem o relogio pressionar a core mechanic:
##
##  1. o dia e a noite duram o que as constantes dizem, e cada virada avisa uma
##     vez so;
##  2. **vasculhar gasta luz mais rapido que andar** - e o proposito do
##     relogio, e mora numa ligacao (cenario -> movel -> relogio) que quebra
##     sem dar erro em tela;
##  3. **a noite aperta**: o zumbi enxerga mais longe, o bairro enche, a HUD
##     avisa e a tela escurece - sem passar do limite, que foi decisao de
##     direcao;
##  4. anoitecer NAO tira voce da rua; amanhecer tira, e diz que foi na forca;
##  5. a HUD le os numeros certos, e nao estoura sem relogio nem sem jogador;
##  6. o prazo se esgota: no ultimo dia a casa nao devolve para a rua.
##
## Mede por chamada direta com delta fixo, e nao contando quadro: em headless o
## laco roda muito mais rapido que a fisica, e o relogio vive no _process.
## Medir a regra com delta controlado da o mesmo resultado toda vez, em
## qualquer maquina.

const Relogio := preload("res://rua/relogio.gd")
const Zumbi := preload("res://rua/zumbi.gd")
const Cenario := preload("res://rua/cenario.gd")
const Hud := preload("res://rua/hud.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const CENA_DA_HUD := preload("res://rua/hud.tscn")
const CENA_DA_CASA := preload("res://casa/casa.tscn")

const PASSO := 1.0 / 60.0

var _falhas := 0

## O dia em que o teste comeca, para devolver o autoload no fim: ele sobrevive
## a troca de cena, e teste nao deve deixar sujeira.
var _dia_no_comeco := 0

## Contadores dos sinais. **Tem que ser membro, nao local:** lambda em GDScript
## captura variavel local por VALOR, entao `func(): avisou = true` escreve numa
## copia e o teste passa a nunca ver o sinal - foi o primeiro resultado desta
## ferramenta, e era falha do teste, nao do relogio.
var _anoiteceres := 0
var _amanheceres := 0

var _rodou := false

## No _process, e nao no _ready: as conferencias 4 e 6 chamam a Travessia de
## verdade, que pede troca de cena. Pedir isso durante o _ready da propria cena
## e ilegal - "Parent node is busy adding/removing children".
func _process(_delta: float) -> void:
	if _rodou:
		return
	_rodou = true
	_dia_no_comeco = Travessia.dia

	_duracao_do_dia_e_da_noite()
	_vasculhar_gasta_luz()
	_a_noite_aperta()
	_quem_tira_voce_da_rua()
	_a_hud_le_os_numeros()
	_o_prazo_se_esgota()

	Travessia.dia = _dia_no_comeco
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _contar_anoitecer() -> void:
	_anoiteceres += 1

func _contar_amanhecer() -> void:
	_amanheceres += 1

## Um relogio de bancada: fora da cena da rua e sem encerrar o dia.
##
## set_process(false) porque quem avanca o tempo aqui e a chamada direta a
## gastar() - com o _process ligado ele gastaria tempo por conta e toda medida
## sairia errada.
func _relogio_de_bancada() -> Relogio:
	var relogio := Relogio.new()
	relogio.encerra_o_dia = false
	relogio.set_process(false)
	add_child(relogio)
	return relogio

# --- 1. o dia e a noite duram o que dizem durar -----------------------------

func _duracao_do_dia_e_da_noite() -> void:
	print("\n1. duracao do dia e da noite")
	var relogio := _relogio_de_bancada()
	_anoiteceres = 0
	_amanheceres = 0
	relogio.anoiteceu.connect(_contar_anoitecer)
	relogio.amanheceu.connect(_contar_amanhecer)

	var quadros_do_dia := int(ceil(Relogio.DURACAO_DO_DIA / PASSO))
	for _quadro in quadros_do_dia:
		relogio.gastar(PASSO)

	if _anoiteceres != 1:
		_erro("as 19:00 anoiteceu %d vez(es), esperado 1" % _anoiteceres)
	elif _amanheceres != 0:
		_erro("amanheceu junto com o anoitecer")
	elif relogio.hora_texto() != "19:00":
		_erro("no fim da luz a hora e %s, esperado 19:00" % relogio.hora_texto())
	elif not relogio.e_noite():
		_erro("a luz acabou e e_noite() e falso")
	else:
		print("  %.0f s de luz -> 19:00, anoiteceu uma vez" % Relogio.DURACAO_DO_DIA)

	# Um quadro a mais do que a conta pede, para conferir que o sinal do
	# amanhecer nao sai duas vezes e que gastar() depois disso nao faz nada.
	var quadros_da_noite := int(ceil(Relogio.DURACAO_DA_NOITE / PASSO)) + 1
	for _quadro in quadros_da_noite:
		relogio.gastar(PASSO)

	if _amanheceres != 1:
		_erro("as 05:00 amanheceu %d vez(es), esperado 1" % _amanheceres)
	elif relogio.hora_texto() != "05:00":
		_erro("no fim da noite a hora e %s, esperado 05:00" % relogio.hora_texto())
	elif not relogio.acabou():
		_erro("amanheceu mas acabou() e falso")
	else:
		print("  %.0f s de noite -> 05:00, amanheceu uma vez" % Relogio.DURACAO_DA_NOITE)
	relogio.free()

	# O meio-dia e o unico ponto em que a conta da para conferir de cabeca:
	# 7h + 12h/2 = 13h.
	var meio := _relogio_de_bancada()
	meio.gastar(Relogio.DURACAO_DO_DIA / 2.0)
	if meio.hora_texto() != "13:00":
		_erro("na metade do dia a hora e %s, esperado 13:00" % meio.hora_texto())
	elif meio.e_noite():
		_erro("meio-dia sendo tratado como noite")
	else:
		print("  metade da luz -> %s, e ainda e dia" % meio.hora_texto())
	meio.free()

# --- 2. vasculhar gasta luz mais rapido que andar ---------------------------

## A conferencia que importa. Mede o tempo de dia gasto num segundo de vasculho
## de verdade, com a cena da rua de pe, e compara com a mesma janela sem
## vasculhar. A diferenca tem que ser CUSTO_DO_VASCULHO por segundo.
func _vasculhar_gasta_luz() -> void:
	print("\n2. vasculhar gasta luz")
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)

	var relogio := rua.get_node("Relogio") as Relogio
	relogio.encerra_o_dia = false
	relogio.set_process(false)

	var movel := _achar_movel(rua, "Carro abandonado")
	if movel == null:
		_erro("nao achei o carro abandonado na cena da rua")
		rua.free()
		return

	if movel.get_signal_connection_list("vasculhando").is_empty():
		_erro("o sinal `vasculhando` do movel nao esta ligado em nada - o cenario nao achou o relogio")
		rua.free()
		return

	var antes := relogio.decorrido
	relogio.gastar(1.0)
	var so_o_tempo := relogio.decorrido - antes

	antes = relogio.decorrido
	# Um segundo de vasculho, quadro por quadro, como o _process do movel faz.
	var quadros := int(round(1.0 / PASSO))
	for _quadro in quadros:
		relogio.gastar(PASSO)
		movel.emit_signal("vasculhando", PASSO)
	var vasculhando := relogio.decorrido - antes

	var esperado := 1.0 + Relogio.CUSTO_DO_VASCULHO
	if absf(vasculhando - esperado) > 0.05:
		_erro("1 s de vasculho gastou %.2f s de dia, esperado %.2f" % [vasculhando, esperado])
	elif vasculhando <= so_o_tempo:
		_erro("vasculhar nao gasta mais dia que andar (%.2f contra %.2f)"
			% [vasculhando, so_o_tempo])
	else:
		print("  1 s andando gasta %.2f s de dia; 1 s vasculhando gasta %.2f s"
			% [so_o_tempo, vasculhando])
		print("  o dia inteiro da %.0f s de vasculho ininterrupto"
			% (Relogio.DURACAO_DO_DIA / (1.0 + Relogio.CUSTO_DO_VASCULHO)))

	_quanto_do_bairro_cabe_num_dia(rua)
	rua.free()

func _quanto_do_bairro_cabe_num_dia(rua: Node) -> void:
	var total := 0
	var segundos := 0.0
	for filho in rua.get_node("Cenario").get_children():
		if filho is Area2D and "duracao" in filho:
			total += 1
			segundos += filho.duracao
	var luz := segundos * (1.0 + Relogio.CUSTO_DO_VASCULHO)
	print("  %d moveis, %.0f s de vasculho = %.0f s de luz = %.1f dias (sem contar o caminho)"
		% [total, segundos, luz, luz / Relogio.DURACAO_DO_DIA])
	# O bairro nao pode caber num dia. Sem isso o relogio existe mas nao aperta,
	# e a promessa do README - "40 moveis, mais do que da para vasculhar num
	# dia" - passa a ser mentira sem ninguem perceber. E a conta ignora o
	# caminho a pe, entao o limite de verdade e bem antes deste.
	if luz <= Relogio.DURACAO_DO_DIA:
		_erro("um dia da para vasculhar o bairro inteiro (%.0f s de luz num dia de %.0f s)"
			% [luz, Relogio.DURACAO_DO_DIA])

func _achar_movel(rua: Node, rotulo: String) -> Area2D:
	for filho in rua.get_node("Cenario").get_children():
		if filho is Area2D and "rotulo" in filho and filho.rotulo == rotulo:
			return filho
	return null

# --- 3. a noite aperta ------------------------------------------------------

## O que a direcao pediu em 09/09/2026: a noite nao acaba o dia, ela aperta - e
## avisa. Aqui se confere que as tres pressoes crescem de verdade e que o
## escuro para onde foi combinado parar.
func _a_noite_aperta() -> void:
	print("\n3. a noite aperta")
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)
	var relogio := rua.get_node("Relogio") as Relogio
	relogio.encerra_o_dia = false
	relogio.set_process(false)
	var cenario := rua.get_node("Cenario") as Cenario
	var hud := CENA_DA_HUD.instantiate()
	add_child(hud)

	var zumbis_de_dia := get_tree().get_nodes_in_group("zumbi").size()
	var vista_de_dia := _um_zumbi().alcance_da_vista()
	hud._process(0.0)
	if hud._quanto_escuro(relogio) != 0.0:
		_erro("de manha a tela ja esta escurecendo")
	if not hud._aviso.text.is_empty():
		_erro("de manha a HUD ja esta avisando: \"%s\"" % hud._aviso.text)

	# Anoitece, e daqui em diante tudo tem que crescer.
	relogio.gastar(Relogio.DURACAO_DO_DIA)
	var escuro_antes: float = hud._quanto_escuro(relogio)
	var avisos := {}

	for _parte in 10:
		relogio.gastar(Relogio.DURACAO_DA_NOITE / 10.0)
		cenario._process(0.0)
		hud._process(0.0)

		var escuro: float = hud._quanto_escuro(relogio)
		if escuro < escuro_antes - 0.001:
			_erro("a noite clareou em %.0f%%: %.2f -> %.2f"
				% [relogio.noite() * 100.0, escuro_antes, escuro])
		if escuro > Hud.ESCURO_NA_NOITE_FECHADA + 0.001:
			_erro("a tela passou do escuro combinado: %.2f > %.2f"
				% [escuro, Hud.ESCURO_NA_NOITE_FECHADA])
		escuro_antes = escuro

		if hud._aviso.text.is_empty():
			_erro("em %.0f%% da noite a HUD nao avisa nada" % (relogio.noite() * 100.0))
		else:
			avisos[hud._aviso.text] = true

	var zumbis_de_noite := get_tree().get_nodes_in_group("zumbi").size()
	var chegaram := zumbis_de_noite - zumbis_de_dia
	if chegaram != Cenario.ZUMBIS_DA_NOITE:
		_erro("a noite trouxe %d zumbis, esperado %d" % [chegaram, Cenario.ZUMBIS_DA_NOITE])
	else:
		print("  a rua foi de %d para %d zumbis" % [zumbis_de_dia, zumbis_de_noite])

	var vista_de_noite := _um_zumbi().alcance_da_vista()
	if vista_de_noite <= vista_de_dia:
		_erro("o zumbi nao enxerga mais longe de noite (%.0f contra %.0f)"
			% [vista_de_noite, vista_de_dia])
	else:
		print("  o zumbi enxergava %.0f px, agora enxerga %.0f" % [vista_de_dia, vista_de_noite])

	if avisos.size() < 3:
		_erro("o aviso da noite nao mudou de texto: %s" % ", ".join(avisos.keys()))
	else:
		print("  %d avisos diferentes ao longo da noite" % avisos.size())
	print("  escuro no fim da noite: %.0f%%, e o limite combinado e %.0f%%"
		% [escuro_antes * 100.0, Hud.ESCURO_NA_NOITE_FECHADA * 100.0])

	_onde_a_noite_faz_nascer(rua, cenario)
	_ninguem_ficou_de_fora_da_linha_de_visao()

	hud.free()
	rua.free()

func _um_zumbi() -> Zumbi:
	return get_tree().get_first_node_in_group("zumbi") as Zumbi

## Zumbi que nasce dentro de parede fica preso e nao pressiona ninguem - foi a
## primeira falha que o conferir_zumbi achou no povoamento, e a noite faz
## nascer mais 14 sem ninguem olhar.
func _onde_a_noite_faz_nascer(rua: Node, cenario: Cenario) -> void:
	var espaco := get_viewport().find_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(30.0, 44.0)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	var fora: Array[RID] = [(rua.get_node("Jogador") as CollisionObject2D).get_rid()]
	for z in get_tree().get_nodes_in_group("zumbi"):
		fora.append((z as CollisionObject2D).get_rid())
	consulta.exclude = fora

	var bocas := cenario._bocas_de_rua()
	var ruins := 0
	for onde in bocas:
		consulta.transform = Transform2D(0.0, onde)
		if not espaco.intersect_shape(consulta, 1).is_empty():
			_erro("a noite faz zumbi nascer em cima de colisao, em %s" % onde)
			ruins += 1
	if ruins == 0:
		print("  as %d bocas de rua estao livres" % bocas.size())

## Cada zumbi ignora os outros na linha de visao, senao um na frente do outro
## corta a visao de quem esta atras e a horda para de funcionar justamente
## quando se junta. A lista e montada uma vez - com a noite trazendo mais, ela
## precisa ser refeita, e e o cenario que manda refazer.
##
## O quadro de fisica nao rodou desde o ultimo nascimento, entao a lista de
## quem chegou antes esta zerada esperando ser refeita. O que se confere e que
## ela FOI zerada.
func _ninguem_ficou_de_fora_da_linha_de_visao() -> void:
	var zumbis := get_tree().get_nodes_in_group("zumbi")
	var velhos := 0
	for z in zumbis:
		if not (z as Zumbi)._ignorados.is_empty():
			velhos += 1
	if velhos > 0:
		_erro("%d zumbis ficaram com a lista de linha de visao velha depois da noite" % velhos)
	else:
		print("  as %d listas de linha de visao foram mandadas refazer" % zumbis.size())

# --- 4. quem tira voce da rua ----------------------------------------------

## Antes de 09/09 o relogio te mandava pra casa as 19:00. A direcao trocou
## isso: anoitecer nao tira voce da rua, so o amanhecer tira - e a casa tem que
## saber que foi na forca.
func _quem_tira_voce_da_rua() -> void:
	print("\n4. quem tira voce da rua")
	Travessia.dia = 3
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA

	var relogio := Relogio.new()
	relogio.set_process(false)
	add_child(relogio)

	# encerra_o_dia LIGADO: e a troca de cena que se quer conferir. A ferramenta
	# sai de "cena atual" pelo tempo da chamada, senao a troca a arranca da
	# arvore e o quit() nunca acontece.
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null

	relogio.gastar(Relogio.DURACAO_DO_DIA + 1.0)
	if Travessia.fim_do_dia != Travessia.FimDoDia.PELA_PORTA:
		_erro("anoitecer mexeu no fim do dia - devia so apertar a rua")
	else:
		print("  anoiteceu e voce continua na rua")

	relogio.gastar(Relogio.DURACAO_DA_NOITE)
	if Travessia.fim_do_dia != Travessia.FimDoDia.AMANHECEU_NA_RUA:
		_erro("amanheceu e o dia nao acabou como AMANHECEU_NA_RUA")
	else:
		print("  amanheceu e o dia acabou na forca, e a casa vai saber")

	get_tree().current_scene = cena_atual
	relogio.free()
	# A troca de cena pode ter posto a casa na raiz, do lado da ferramenta.
	for filho in get_tree().root.get_children():
		if filho.name == "Casa":
			filho.free()

# --- 5. a HUD le os numeros certos ------------------------------------------

func _a_hud_le_os_numeros() -> void:
	print("\n5. a HUD")
	Travessia.dia = 1
	var hud := CENA_DA_HUD.instantiate()
	add_child(hud)

	# Primeiro sem relogio e sem jogador na cena: ela tem que se desenhar
	# igual, so com os campos apagados. E o caso de entrar numa cena de teste.
	hud._process(0.0)
	var topo: String = (hud.get_node("Topo") as Label).text
	if not topo.begins_with("Dia %d de %d" % [Travessia.dia, Travessia.PRAZO_DA_CURA]):
		_erro("sem relogio na cena, o topo da HUD diz \"%s\"" % topo)
	elif not (hud.get_node("Esquerda") as Label).text.contains("vida    —"):
		_erro("sem jogador na cena, a vida na HUD nao apagou")
	else:
		print("  sem relogio nem jogador: \"%s\"" % topo)

	# Agora com a cena da rua de pe, que e o caso de verdade.
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)
	var relogio := rua.get_node("Relogio") as Relogio
	relogio.encerra_o_dia = false
	relogio.set_process(false)
	relogio.gastar(Relogio.DURACAO_DO_DIA / 2.0)
	var jogador := rua.get_node("Jogador") as Node2D
	jogador.vida = 60.0

	hud._process(0.0)
	topo = (hud.get_node("Topo") as Label).text
	var esquerda: String = (hud.get_node("Esquerda") as Label).text
	var direita: String = (hud.get_node("Direita") as Label).text

	if not topo.contains("13:00"):
		_erro("na metade do dia o topo da HUD diz \"%s\"" % topo)
	if not esquerda.contains("60%"):
		_erro("com 60 de vida a HUD diz \"%s\"" % esquerda.replace("\n", " / "))
	if not direita.contains("vazia"):
		_erro("com a mochila vazia a HUD diz \"%s\"" % direita)

	print("  na rua: \"%s\" | %s | %s" % [topo, esquerda.replace("\n", " / "), direita])
	hud.free()
	rua.free()

# --- 6. o prazo se esgota ---------------------------------------------------

func _o_prazo_se_esgota() -> void:
	print("\n6. o prazo")
	Travessia.dia = 1
	if Travessia.dias_restantes() != Travessia.PRAZO_DA_CURA - 1:
		_erro("no dia 1, dias_restantes() = %d" % Travessia.dias_restantes())

	Travessia.dia = Travessia.PRAZO_DA_CURA - 1
	if Travessia.e_o_ultimo_dia():
		_erro("o dia %d ja e tratado como ultimo" % Travessia.dia)
	if Travessia.dias_restantes() != 1:
		_erro("faltando um dia, dias_restantes() = %d" % Travessia.dias_restantes())

	Travessia.dia = Travessia.PRAZO_DA_CURA
	if not Travessia.e_o_ultimo_dia():
		_erro("o dia %d devia ser o ultimo" % Travessia.dia)
	if Travessia.dias_restantes() != 0:
		_erro("no ultimo dia, dias_restantes() = %d" % Travessia.dias_restantes())

	# A casa e quem obedece a regra. No ultimo dia, apertar E nao devolve para
	# a rua: mostra a derrota e trava.
	var casa := CENA_DA_CASA.instantiate()
	add_child(casa)
	var dia_antes := Travessia.dia
	var evento := InputEventAction.new()
	evento.action = "vasculhar"
	evento.pressed = true
	casa._unhandled_input(evento)

	if Travessia.dia != dia_antes:
		_erro("a casa deixou sair no ultimo dia - o dia virou %d" % Travessia.dia)
	elif not (casa.get_node("Conteudo/Titulo") as Label).text.contains("PRAZO"):
		_erro("a casa travou mas nao mostrou a derrota")
	else:
		print("  dia %d de %d: a casa segura e mostra a derrota" % [
			Travessia.dia, Travessia.PRAZO_DA_CURA])

	# E antes do ultimo dia ela deixa sair, senao a conferencia acima passaria
	# com a casa quebrada de qualquer jeito - uma casa que nunca deixa sair
	# tambem "segura no ultimo dia". Mesmo remendo da conferencia 4.
	Travessia.dia = 2
	casa._acabou = false
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	casa._unhandled_input(evento)
	get_tree().current_scene = cena_atual

	if Travessia.dia != 3:
		_erro("no dia 2 a casa nao deixou sair para a rua")
	else:
		print("  dia 2 de %d: a casa deixa sair" % Travessia.PRAZO_DA_CURA)
	casa.free()
	for filho in get_tree().root.get_children():
		if filho.name == "Rua":
			filho.free()
