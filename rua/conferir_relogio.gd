extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer no relogio, na HUD ou no
## prazo.**
##
## Confere as cinco coisas que fazem o relogio pressionar a core mechanic:
##
##  1. o dia dura o que a constante diz que dura, e anoitece uma vez so;
##  2. **vasculhar gasta luz mais rapido que andar** - e o proposito do
##     relogio, e mora numa ligacao (cenario -> movel -> relogio) que quebra
##     sem dar erro em tela;
##  3. a HUD le os numeros certos, e nao estoura sem relogio nem sem jogador;
##  4. o anoitecer encerra o dia;
##  5. o prazo se esgota: no ultimo dia a casa nao devolve para a rua.
##
## Mede por chamada direta com delta fixo, e nao contando quadro: em headless o
## laco roda muito mais rapido que a fisica, e o relogio vive no _process.
## Medir a regra com delta controlado da o mesmo resultado toda vez, em
## qualquer maquina.
##
## O item 2 e o unico que precisa da cena inteira de pe, porque o que ele mede
## e a ligacao, nao a conta.

const Relogio := preload("res://rua/relogio.gd")
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
var _avisou := false

var _rodou := false

## No _process, e nao no _ready: a conferencia 5 chama a Travessia de verdade,
## que pede troca de cena. Pedir isso durante o _ready da propria cena e
## ilegal - "Parent node is busy adding/removing children" -, e no _process a
## troca fica deferida e nunca chega a acontecer, porque o quit() vem antes.
func _process(_delta: float) -> void:
	if _rodou:
		return
	_rodou = true
	_dia_no_comeco = Travessia.dia

	_duracao_do_dia()
	_vasculhar_gasta_luz()
	_a_hud_le_os_numeros()
	_o_anoitecer_encerra_o_dia()
	_o_prazo_se_esgota()

	Travessia.dia = _dia_no_comeco
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _contar_anoitecer() -> void:
	_anoiteceres += 1

func _marcar_anoitecer() -> void:
	_avisou = true

## Um relogio de bancada: fora da cena da rua e sem encerrar o dia.
##
## set_process(false) porque quem avanca o tempo aqui e a chamada direta a
## gastar() - com o _process ligado ele gastaria luz por conta e toda medida
## sairia errada.
func _relogio_de_bancada() -> Relogio:
	var relogio := Relogio.new()
	relogio.encerra_o_dia = false
	relogio.set_process(false)
	add_child(relogio)
	return relogio

# --- 1. o dia dura o que diz durar ------------------------------------------

func _duracao_do_dia() -> void:
	print("\n1. duracao do dia")
	var relogio := _relogio_de_bancada()
	_anoiteceres = 0
	relogio.anoiteceu.connect(_contar_anoitecer)

	# Um quadro a mais do que a conta pede, para conferir que o sinal nao sai
	# duas vezes e que gastar() depois de acabar nao faz nada.
	var teto := int(ceil(Relogio.DURACAO_DO_DIA / PASSO)) + 1
	var vezes := 0
	while vezes < teto:
		relogio.gastar(PASSO)
		vezes += 1

	var gastou := float(vezes) * PASSO
	if _anoiteceres != 1:
		_erro("anoiteceu %d vez(es), esperado 1" % _anoiteceres)
	elif absf(gastou - Relogio.DURACAO_DO_DIA) > PASSO * 2.0:
		_erro("o dia acabou em %.2f s, esperado %.0f s" % [gastou, Relogio.DURACAO_DO_DIA])
	else:
		print("  %.0f s de luz, anoiteceu uma vez, hora final %s"
			% [Relogio.DURACAO_DO_DIA, relogio.hora_texto()])

	if relogio.hora_texto() != "19:00":
		_erro("no fim do dia a hora e %s, esperado 19:00" % relogio.hora_texto())
	relogio.free()

	# O meio-dia e o unico ponto em que a conta da para conferir de cabeca:
	# 7h + 12h/2 = 13h.
	var meio := _relogio_de_bancada()
	meio.gastar(Relogio.DURACAO_DO_DIA / 2.0)
	if meio.hora_texto() != "13:00":
		_erro("na metade do dia a hora e %s, esperado 13:00" % meio.hora_texto())
	else:
		print("  metade da luz -> %s" % meio.hora_texto())
	meio.free()

# --- 2. vasculhar gasta luz mais rapido que andar ---------------------------

## O teste que importa. Mede a luz gasta num segundo de vasculho de verdade,
## com a cena da rua de pe, e compara com a mesma janela de tempo sem
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

	var antes := relogio.luz
	relogio.gastar(1.0)
	var so_o_tempo := antes - relogio.luz

	antes = relogio.luz
	# Um segundo de vasculho, quadro por quadro, como o _process do movel faz.
	var quadros := int(round(1.0 / PASSO))
	for _quadro in quadros:
		relogio.gastar(PASSO)
		movel.emit_signal("vasculhando", PASSO)
	var vasculhando := antes - relogio.luz

	var esperado := 1.0 + Relogio.CUSTO_DO_VASCULHO
	if absf(vasculhando - esperado) > 0.05:
		_erro("1 s de vasculho gastou %.2f s de luz, esperado %.2f" % [vasculhando, esperado])
	elif vasculhando <= so_o_tempo:
		_erro("vasculhar nao gasta mais luz que andar (%.2f contra %.2f)"
			% [vasculhando, so_o_tempo])
	else:
		print("  1 s andando gasta %.2f s de luz; 1 s vasculhando gasta %.2f s"
			% [so_o_tempo, vasculhando])
		print("  o dia inteiro da %.0f s de vasculho ininterrupto"
			% (Relogio.DURACAO_DO_DIA / (1.0 + Relogio.CUSTO_DO_VASCULHO)))

	# Quanto do bairro cabe num dia. Nao e falha: e a leitura de escopo que diz
	# se o relogio esta apertado ou frouxo, e o numero a olhar ao mexer na
	# DURACAO_DO_DIA.
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

# --- 3. a HUD le os numeros certos ------------------------------------------

func _a_hud_le_os_numeros() -> void:
	print("\n3. a HUD")
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

	if hud._quanto_escuro(relogio) != 0.0:
		_erro("na metade do dia a tela ja esta escurecendo")
	relogio.gastar(Relogio.DURACAO_DO_DIA)
	if hud._quanto_escuro(relogio) <= 0.0:
		_erro("no anoitecer a tela nao escureceu")

	print("  na rua: \"%s\" | %s | %s" % [topo, esquerda.replace("\n", " / "), direita])
	hud.free()
	rua.free()

# --- 4. o anoitecer encerra o dia -------------------------------------------

## Com encerra_o_dia ligado, anoitecer chama Travessia.entrar_em_casa(), que
## troca a cena da arvore inteira e levaria esta ferramenta embora. Entao o que
## se confere aqui e o sinal, e que ele sai exatamente quando a luz zera.
func _o_anoitecer_encerra_o_dia() -> void:
	print("\n4. o anoitecer encerra o dia")
	var relogio := _relogio_de_bancada()
	_avisou = false
	relogio.anoiteceu.connect(_marcar_anoitecer)

	relogio.gastar(Relogio.DURACAO_DO_DIA - 1.0)
	if _avisou:
		_erro("anoiteceu faltando 1 s de luz")
	if relogio.acabou():
		_erro("acabou() antes da luz acabar")

	relogio.gastar(1.0)
	if not _avisou:
		_erro("a luz zerou e nao anoiteceu")
	elif not relogio.acabou():
		_erro("anoiteceu mas acabou() e falso")
	else:
		print("  luz zerada -> anoiteceu, e o dia acaba pela Travessia")
	relogio.free()

# --- 5. o prazo se esgota ---------------------------------------------------

func _o_prazo_se_esgota() -> void:
	print("\n5. o prazo")
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
	# a rua: mostra a derrota e trava. E o unico lugar onde o prazo tem
	# consequencia hoje.
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
	# tambem "segura no ultimo dia".
	#
	# Deixar sair chama a Travessia de verdade, e a troca de cena ARRANCA a
	# cena atual da arvore na hora - esta ferramenta inclusive. Sem o remendo
	# abaixo, o get_tree() do fim vem nulo, o quit() nunca acontece e o
	# processo fica rodando para sempre com a rua carregada. Tirar a ferramenta
	# de "cena atual" pelo tempo da chamada resolve: a troca nao tem o que
	# arrancar e a cena nova entra na raiz do lado dela.
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
