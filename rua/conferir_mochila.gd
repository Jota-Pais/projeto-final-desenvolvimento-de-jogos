extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na mochila, no loot ou no
## que atravessa o dia.**
##
## Confere as cinco coisas do passo 4:
##
##  1. vasculhar enche a mochila, e **documento conta separado** de comida;
##  2. **so entra em casa o que passou pela porta do porao** - amanhecer na rua
##     e cair sem vida deixam tudo na calcada, e a casa mostra o prejuizo;
##  3. **o mundo esvazia e nao repoe**: movel vasculhado ontem nasce vazio hoje,
##     e so ele;
##  4. o bairro inteiro tem loot suficiente para o prazo - e a leitura de escopo
##     do passo 4;
##  5. a HUD mostra o documento na linha propria dele.
##
## O item 2 e o que precisa de conferencia de verdade: a regra vive numa
## ligacao indireta (a mochila escuta o `chegou_em_casa` do Travessia e le o
## `fim_do_dia` para decidir), e quebra sem dar erro em tela.

const Construcao := preload("res://rua/construcao.gd")
const Mochila := preload("res://rua/mochila.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")
const CENA_DA_HUD := preload("res://rua/hud.tscn")
const CENA_DA_CASA := preload("res://casa/casa.tscn")

var _falhas := 0
var _rodou := false

## O estado do autoload no comeco, para devolver no fim: ele sobrevive a troca
## de cena, e teste nao deve deixar sujeira.
var _dia_no_comeco := 0

## No _process, e nao no _ready: a conferencia 2 chama a Travessia de verdade,
## que pede troca de cena, e pedir isso durante o _ready da propria cena e
## ilegal.
func _process(_delta: float) -> void:
	if _rodou:
		return
	_rodou = true
	_dia_no_comeco = Travessia.dia

	_vasculhar_enche_a_mochila()
	_so_entra_o_que_passou_pela_porta()
	_o_mundo_nao_repoe()
	_quanto_loot_o_bairro_tem()
	_a_hud_mostra_o_documento()

	_limpar_o_autoload()
	Travessia.dia = _dia_no_comeco
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _limpar_o_autoload() -> void:
	Travessia.mochila.clear()
	Travessia.documentos.clear()
	Travessia.moveis_vazios.clear()
	Travessia.itens_perdidos = 0
	Travessia.documentos_perdidos = 0
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA

## A rua de pe, com relogio e zumbis parados: aqui nao se mede tempo.
func _uma_rua() -> Node:
	var rua := CENA_DA_RUA.instantiate()
	add_child(rua)
	var relogio := rua.get_node("Relogio")
	relogio.encerra_o_dia = false
	relogio.set_process(false)
	return rua

func _moveis_de(rua: Node) -> Array[Node]:
	var moveis: Array[Node] = []
	for filho in rua.get_node("Cenario").get_children():
		if filho is Area2D and "achados" in filho:
			moveis.append(filho)
	return moveis

## O primeiro movel cujo conteudo tem documento. Sao os moveis 6, 12, 18... na
## ordem de geracao, mas achar pelo conteudo nao depende dessa conta.
func _um_movel_com_documento(rua: Node) -> Node:
	for movel in _moveis_de(rua):
		for achado in movel.achados:
			if Construcao.e_documento(achado):
				return movel
	return null

# --- 1. vasculhar enche a mochila -------------------------------------------

func _vasculhar_enche_a_mochila() -> void:
	print("\n1. vasculhar enche a mochila")
	_limpar_o_autoload()
	var rua := _uma_rua()
	var mochila := rua.get_node("Mochila") as Mochila

	var com_documento := _um_movel_com_documento(rua)
	if com_documento == null:
		_erro("nenhum movel do bairro tem documento")
		rua.free()
		return

	if com_documento.get_signal_connection_list("vasculhado").is_empty():
		_erro("o sinal `vasculhado` do movel nao esta ligado em nada - o cenario nao achou a mochila")
		rua.free()
		return

	var esperados_documentos := 0
	var esperados_itens := 0
	for achado in com_documento.achados:
		if Construcao.e_documento(achado):
			esperados_documentos += 1
		else:
			esperados_itens += 1

	com_documento._esvaziar()

	if mochila.documentos.size() != esperados_documentos:
		_erro("o movel tinha %d documento(s) e a mochila ficou com %d"
			% [esperados_documentos, mochila.documentos.size()])
	elif mochila.itens.size() != esperados_itens:
		_erro("o movel tinha %d item(ns) comum(ns) e a mochila ficou com %d"
			% [esperados_itens, mochila.itens.size()])
	else:
		print("  %s: %d item(ns) e %d documento(s), separados"
			% [com_documento.rotulo, esperados_itens, esperados_documentos])

	# Um movel comum nao pode virar documento no caminho.
	var antes := mochila.documentos.size()
	for movel in _moveis_de(rua):
		if movel == com_documento or movel._vazio:
			continue
		movel._esvaziar()
	for achado in mochila.itens:
		if Construcao.e_documento(achado):
			_erro("\"%s\" entrou como item comum" % achado)
			break
	for achado in mochila.documentos:
		if not Construcao.e_documento(achado):
			_erro("\"%s\" entrou como documento" % achado)
			break
	print("  o bairro inteiro na mochila: %d itens e %d documentos"
		% [mochila.itens.size(), mochila.documentos.size()])
	if mochila.documentos.size() <= antes:
		_erro("vasculhar o resto do bairro nao trouxe mais nenhum documento")

	rua.free()

# --- 2. so entra o que passou pela porta ------------------------------------

func _so_entra_o_que_passou_pela_porta() -> void:
	print("\n2. so entra o que passou pela porta")
	for caso in [
		Travessia.FimDoDia.PELA_PORTA,
		Travessia.FimDoDia.AMANHECEU_NA_RUA,
		Travessia.FimDoDia.SEM_VIDA,
	]:
		_um_fim_de_dia(caso)

func _um_fim_de_dia(motivo: int) -> void:
	_limpar_o_autoload()
	var rua := _uma_rua()
	var mochila := rua.get_node("Mochila") as Mochila
	var com_documento := _um_movel_com_documento(rua)
	if com_documento == null:
		_erro("nenhum movel do bairro tem documento")
		rua.free()
		return
	com_documento._esvaziar()
	# E comida junto, senao o prejuizo do dia perdido seria "0 itens" e a
	# conferencia da tela da casa passaria sem provar nada.
	for movel in _moveis_de(rua):
		if mochila.itens.size() >= 3:
			break
		if not movel._vazio:
			movel._esvaziar()

	var carregava_itens := mochila.itens.size()
	var carregava_documentos := mochila.documentos.size()
	if carregava_documentos == 0 or carregava_itens == 0:
		_erro("o teste comecou com %d itens e %d documentos - precisa dos dois"
			% [carregava_itens, carregava_documentos])
		rua.free()
		return

	# A ferramenta sai de "cena atual" pelo tempo da chamada: a troca de cena
	# arranca a cena atual da arvore na hora, e levaria a ferramenta embora.
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	Travessia.entrar_em_casa(motivo)
	get_tree().current_scene = cena_atual

	var entregou := Travessia.mochila.size() + Travessia.documentos.size()
	var nome: String = ["pela porta", "amanheceu na rua", "sem vida"][motivo]

	if motivo == Travessia.FimDoDia.PELA_PORTA:
		if Travessia.documentos.size() != carregava_documentos:
			_erro("voltando %s, chegaram %d de %d documentos"
				% [nome, Travessia.documentos.size(), carregava_documentos])
		elif Travessia.mochila.size() != carregava_itens:
			_erro("voltando %s, chegaram %d de %d itens"
				% [nome, Travessia.mochila.size(), carregava_itens])
		else:
			print("  %-18s entregou %d itens e %d documento(s)"
				% [nome, carregava_itens, carregava_documentos])
	else:
		if entregou != 0:
			_erro("acabando %s, %d coisa(s) entraram em casa mesmo assim" % [nome, entregou])
		elif Travessia.documentos_perdidos != carregava_documentos:
			_erro("acabando %s, a casa nao registrou os %d documentos perdidos"
				% [nome, carregava_documentos])
		else:
			print("  %-18s perdeu %d itens e %d documento(s) na rua"
				% [nome, Travessia.itens_perdidos, Travessia.documentos_perdidos])
		_a_casa_mostra_o_prejuizo(carregava_itens)

	rua.free()

func _a_casa_mostra_o_prejuizo(quantos_itens: int) -> void:
	var casa := CENA_DA_CASA.instantiate()
	add_child(casa)
	var texto: String = (casa.get_node("Conteudo/Trouxe") as Label).text
	if not texto.contains("Ficou na rua"):
		_erro("a casa nao mostrou o prejuizo: \"%s\"" % texto)
	elif not texto.contains(str(quantos_itens)):
		_erro("a casa nao disse quantos itens ficaram: \"%s\"" % texto)
	casa.free()

# --- 3. o mundo esvazia e nao repoe -----------------------------------------

func _o_mundo_nao_repoe() -> void:
	print("\n3. o mundo esvazia e nao repoe")
	_limpar_o_autoload()

	var rua := _uma_rua()
	var moveis := _moveis_de(rua)
	if moveis.size() < 3:
		_erro("achei so %d moveis na rua" % moveis.size())
		rua.free()
		return

	# Tres moveis pelo meio da lista, guardados pela posicao - o bairro nasce
	# igual todo dia, entao a posicao serve de nome.
	var escolhidos := [moveis[0], moveis[moveis.size() / 2], moveis[-1]]
	var onde := []
	for movel in escolhidos:
		onde.append(movel.position)
		movel._esvaziar()
	var quantos_no_mundo := moveis.size()
	rua.free()

	if Travessia.moveis_vazios.size() != escolhidos.size():
		_erro("vasculhei %d moveis e o Travessia anotou %d"
			% [escolhidos.size(), Travessia.moveis_vazios.size()])

	# O dia seguinte: a mesma rua, carregada de novo.
	var amanha := _uma_rua()
	var vazios := 0
	var cheios := 0
	for movel in _moveis_de(amanha):
		if movel.position in onde:
			if not movel.nasce_vazio:
				_erro("o movel em %s foi vasculhado e voltou cheio" % movel.position)
			elif not movel.achados.is_empty():
				_erro("o movel em %s nasceu vazio mas com conteudo" % movel.position)
			else:
				vazios += 1
		elif movel.nasce_vazio:
			_erro("o movel em %s nasceu vazio sem ter sido vasculhado" % movel.position)
		else:
			cheios += 1

	if vazios == escolhidos.size():
		print("  %d de %d moveis vasculhados nasceram vazios; os outros %d, cheios"
			% [vazios, quantos_no_mundo, cheios])
	amanha.free()

# --- 4. quanto loot o bairro tem --------------------------------------------

## Leitura de escopo, nao falha - com uma excecao: se o bairro tiver menos
## documento do que o jogo precisa, a progressao nao fecha e isso e problema
## de verdade.
func _quanto_loot_o_bairro_tem() -> void:
	print("\n4. o loot do bairro inteiro")
	_limpar_o_autoload()
	var rua := _uma_rua()

	var itens := 0
	var documentos := 0
	for movel in _moveis_de(rua):
		for achado in movel.achados:
			if Construcao.e_documento(achado):
				documentos += 1
			else:
				itens += 1

	print("  %d itens comuns e %d documentos, em %d moveis"
		% [itens, documentos, _moveis_de(rua).size()])
	print("  %d documentos declarados no mapa, e o prazo sao %d dias"
		% [documentos, Travessia.PRAZO_DA_CURA])

	if documentos == 0:
		_erro("o mapa nao tem documento nenhum - a historia nao anda")
	rua.free()

# --- 5. a HUD mostra o documento --------------------------------------------

func _a_hud_mostra_o_documento() -> void:
	print("\n5. a HUD")
	_limpar_o_autoload()
	var rua := _uma_rua()
	var hud := CENA_DA_HUD.instantiate()
	add_child(hud)

	hud._process(0.0)
	if not (hud.get_node("Direita") as Label).text.contains("vazia"):
		_erro("com a mochila vazia a HUD diz \"%s\"" % (hud.get_node("Direita") as Label).text)
	if not (hud.get_node("Documentos") as Label).text.is_empty():
		_erro("sem documento a linha de documento nao esta vazia")

	var com_documento := _um_movel_com_documento(rua)
	if com_documento != null:
		com_documento._esvaziar()
	hud._process(0.0)

	var direita: String = (hud.get_node("Direita") as Label).text
	var docs: String = (hud.get_node("Documentos") as Label).text
	if not docs.contains("documento"):
		_erro("com documento na mochila a linha de documento diz \"%s\"" % docs)
	elif direita.contains("documento"):
		_erro("o documento apareceu na linha da mochila tambem: \"%s\"" % direita)
	else:
		print("  \"%s\" em cima de \"%s\"" % [docs, direita])

	hud.free()
	rua.free()
