extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na mochila, no que sai
## dos moveis ou no que atravessa o dia.**
##
## Confere seis coisas:
##
##  1. vasculhar manda **documento para a mochila e balas para o cinto** - e
##     nada mais existe para sair de um movel (30/09/2026);
##  2. **so entra em casa o que passou pela porta de casa** - amanhecer na rua
##     deixa os documentos na calcada, a casa mostra o prejuizo, e as balas
##     ficam no cinto;
##  3. **o mundo esvazia e nao repoe**: movel vasculhado ontem nasce vazio hoje,
##     e so ele;
##  4. quanto o mapa inteiro rende - leitura de escopo, com um unico erro
##     possivel: mapa sem documento;
##  5. a HUD mostra a Beretta e o documento carregado;
##  6. **a tela da mochila**: o que sai dela cai no chao e o chao devolve.
##
## O item 2 e o que precisa de conferencia de verdade: a regra vive numa
## ligacao indireta (a mochila escuta o `chegou_em_casa` do Travessia e le o
## `fim_do_dia` para decidir), e quebra sem dar erro em tela.
##
## Ate 30/09/2026 havia mais duas (a mochila enche em 12 vagas; o que nao coube
## fica no movel e da para voltar): sairam junto com o loot generico e a
## capacidade.

const Construcao := preload("res://rua/construcao.gd")
const Mochila := preload("res://rua/mochila.gd")
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")
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

	_vasculhar_rende_documento_e_balas()
	_so_entra_o_que_passou_pela_porta()
	_o_mundo_nao_repoe()
	_quanto_o_mapa_rende()
	_a_hud()
	_a_tela_da_mochila()

	_limpar_o_autoload()
	Travessia.dia = _dia_no_comeco
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _limpar_o_autoload() -> void:
	Travessia.municao = Travessia.BALAS_DE_COMECO
	Travessia.documentos.clear()
	Travessia.moveis_vazios.clear()
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

## Os moveis cujo conteudo tem documento, na ordem de geracao.
func _moveis_com_documento(rua: Node) -> Array[Node]:
	var lista: Array[Node] = []
	for movel in _moveis_de(rua):
		for achado in movel.achados:
			if Construcao.e_documento(achado):
				lista.append(movel)
				break
	return lista

func _caixinhas_em(movel: Node) -> int:
	var n := 0
	for achado in movel.achados:
		if achado == Construcao.MUNICAO:
			n += 1
	return n

# --- 1. vasculhar rende documento e balas -----------------------------------

func _vasculhar_rende_documento_e_balas() -> void:
	print("\n1. vasculhar rende documento e balas")
	_limpar_o_autoload()
	var rua := _uma_rua()
	var mochila := rua.get_node("Mochila") as Mochila

	var com_documento := _moveis_com_documento(rua)
	if com_documento.is_empty():
		_erro("nenhum movel do mapa tem documento")
		rua.free()
		return
	var movel: Node = com_documento[0]

	if movel.get_signal_connection_list("vasculhado").is_empty():
		_erro("o sinal `vasculhado` do movel nao esta ligado em nada - o cenario nao achou a mochila")
		rua.free()
		return

	var caixinhas := _caixinhas_em(movel)
	var balas_antes := Travessia.municao
	movel._esvaziar()

	if mochila.documentos.size() != 1:
		_erro("o movel tinha 1 documento e a mochila ficou com %d" % mochila.documentos.size())
	elif Travessia.municao != balas_antes + caixinhas * Construcao.MUNICAO_POR_ACHADO:
		_erro("o movel tinha %d caixinha(s) e o cinto foi de %d para %d balas"
			% [caixinhas, balas_antes, Travessia.municao])
	else:
		print("  %s: 1 documento para a mochila, %d caixinha(s) para o cinto"
			% [movel.rotulo, caixinhas])

	# O mapa inteiro: so documento entra na mochila, e todo movel esvazia.
	for outro in _moveis_de(rua):
		if not outro._vazio:
			outro._esvaziar()
	for achado in mochila.tudo():
		if not Construcao.e_documento(achado):
			_erro("\"%s\" entrou na mochila, e so documento entra" % achado)
			break
	var cheios := 0
	for outro in _moveis_de(rua):
		if not outro._vazio or not outro.achados.is_empty():
			cheios += 1
	if cheios > 0:
		_erro("%d moveis ficaram com coisa dentro depois de vasculhados" % cheios)
	if mochila.quantos() != Construcao.DOCUMENTOS.size():
		_erro("vasculhando o mapa inteiro a mochila ficou com %d documentos, e o mapa tem %d"
			% [mochila.quantos(), Construcao.DOCUMENTOS.size()])
	else:
		print("  o mapa inteiro deixou %d documentos na mochila e %d balas no cinto"
			% [mochila.quantos(), Travessia.municao])
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
	var com_documento := _moveis_com_documento(rua)
	if com_documento.size() < 2:
		_erro("o mapa tem %d movel(is) com documento; o teste precisa de dois" % com_documento.size())
		rua.free()
		return
	com_documento[0]._esvaziar()
	com_documento[1]._esvaziar()

	var carregava := mochila.documentos.size()
	var balas := Travessia.municao
	if carregava != 2:
		_erro("o teste comecou com %d documentos na mochila, esperado 2" % carregava)
		rua.free()
		return

	# A ferramenta sai de "cena atual" pelo tempo da chamada: a troca de cena
	# arranca a cena atual da arvore na hora, e levaria a ferramenta embora.
	var cena_atual := get_tree().current_scene
	get_tree().current_scene = null
	Travessia.entrar_em_casa(motivo)
	get_tree().current_scene = cena_atual

	var nome: String = ["pela porta", "amanheceu na rua", "sem vida"][motivo]
	if motivo == Travessia.FimDoDia.PELA_PORTA:
		if Travessia.documentos.size() != carregava:
			_erro("voltando %s, chegaram %d de %d documentos"
				% [nome, Travessia.documentos.size(), carregava])
		else:
			print("  %-18s entregou %d documentos" % [nome, carregava])
	else:
		if not Travessia.documentos.is_empty():
			_erro("acabando %s, %d documento(s) entraram em casa mesmo assim"
				% [nome, Travessia.documentos.size()])
		elif Travessia.documentos_perdidos != carregava:
			_erro("acabando %s, a casa nao registrou os %d documentos perdidos"
				% [nome, carregava])
		elif Travessia.municao != balas:
			_erro("acabando %s, as balas foram de %d para %d - balas nao se perdem"
				% [nome, balas, Travessia.municao])
		else:
			print("  %-18s perdeu %d documentos na rua e ficou com as %d balas"
				% [nome, Travessia.documentos_perdidos, balas])
		_a_casa_mostra_o_prejuizo(carregava)

	rua.free()

func _a_casa_mostra_o_prejuizo(quantos_documentos: int) -> void:
	var casa := CENA_DA_CASA.instantiate()
	add_child(casa)
	var texto: String = casa.o_que_voltou()
	if not texto.contains("Ficou na rua"):
		_erro("a casa nao mostrou o prejuizo: \"%s\"" % texto)
	elif not texto.contains(str(quantos_documentos)):
		_erro("a casa nao disse quantos documentos ficaram: \"%s\"" % texto)
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

	# Tres moveis pelo meio da lista, guardados pela posicao - o mapa nasce
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

# --- 4. quanto o mapa rende ---------------------------------------------------

## Leitura de escopo, nao falha - com uma excecao: se o mapa tiver menos
## documento do que o jogo precisa, a progressao nao fecha e isso e problema
## de verdade.
func _quanto_o_mapa_rende() -> void:
	print("\n4. quanto o mapa inteiro rende")
	_limpar_o_autoload()
	var rua := _uma_rua()

	var caixinhas := 0
	var documentos := 0
	var vazios := 0
	for movel in _moveis_de(rua):
		var n := _caixinhas_em(movel)
		caixinhas += n
		if n == 0 and not movel.achados.is_empty():
			pass
		if movel.achados.is_empty():
			vazios += 1
		for achado in movel.achados:
			if Construcao.e_documento(achado):
				documentos += 1

	print("  %d moveis: %d documentos, %d caixinhas (%d balas), %d moveis vazios"
		% [_moveis_de(rua).size(), documentos, caixinhas,
			caixinhas * Construcao.MUNICAO_POR_ACHADO, vazios])
	print("  a partida comeca com %d balas, e o prazo sao %d dias"
		% [Travessia.BALAS_DE_COMECO, Travessia.PRAZO_DA_CURA])

	if documentos < Travessia.DOCUMENTOS_PARA_A_CURA:
		_erro("o mapa tem %d documentos e a cura pede %d - a historia nao anda"
			% [documentos, Travessia.DOCUMENTOS_PARA_A_CURA])
	rua.free()

# --- 5. a HUD -----------------------------------------------------------------

func _a_hud() -> void:
	print("\n5. a HUD")
	_limpar_o_autoload()
	var rua := _uma_rua()
	var hud := CENA_DA_HUD.instantiate()
	add_child(hud)

	hud._process(0.0)
	var direita: String = (hud.get_node("Direita") as Label).text
	var esquerda: String = (hud.get_node("Esquerda") as Label).text
	if not direita.contains("vazia"):
		_erro("com a mochila vazia a HUD diz \"%s\"" % direita)
	if not esquerda.contains("Beretta") or not esquerda.contains(str(Travessia.BALAS_DE_COMECO)):
		_erro("no comeco a HUD devia mostrar a Beretta com %d balas, e diz \"%s\""
			% [Travessia.BALAS_DE_COMECO, esquerda])

	var com_documento := _moveis_com_documento(rua)
	if not com_documento.is_empty():
		com_documento[0]._esvaziar()
	hud._process(0.0)

	direita = (hud.get_node("Direita") as Label).text
	if not direita.contains("1 documento"):
		_erro("com um documento na mochila a HUD diz \"%s\"" % direita)
	else:
		print("  \"%s\"   e   \"%s\"" % [(hud.get_node("Esquerda") as Label).text, direita])

	hud.free()
	rua.free()

# --- 6. a tela da mochila ---------------------------------------------------

## O caminho inteiro - tirar da mochila, cair no chao, e o chao devolver -
## passa por tres arquivos que nao se conhecem (tela -> mochila -> cenario) e
## quebra sem dar erro em tela.
func _a_tela_da_mochila() -> void:
	print("\n6. a tela da mochila")
	_limpar_o_autoload()
	var rua := _uma_rua()
	var mochila := rua.get_node("Mochila") as Mochila
	var tela := rua.get_node("TelaDaMochila")

	var com_documento := _moveis_com_documento(rua)
	if com_documento.size() < 2:
		_erro("o mapa tem %d movel(is) com documento; o teste precisa de dois" % com_documento.size())
		rua.free()
		return
	com_documento[0]._esvaziar()
	com_documento[1]._esvaziar()

	# tudo() e a ordem que a tela desenha e a ordem que largar() indexa. Se as
	# duas se separarem, largar tira a linha errada - e nada avisa.
	var tudo := mochila.tudo()
	if tudo.size() != 2:
		_erro("tudo() tem %d linhas e a mochila carrega 2 documentos" % tudo.size())
	else:
		print("  %d linhas, as duas documento" % tudo.size())

	tela._abrir()
	if not TelaDaMochila.aberta:
		_erro("a tela nao abriu")

	# Largar a linha 0. A tela nao protege ninguem disso de proposito - o que
	# protege e o chao devolver.
	var o_documento: String = mochila.documentos[0]
	tela._escolhida = 0
	tela._largar()

	if mochila.quantos() != 1:
		_erro("largar deixou a mochila com %d documento(s), esperado 1" % mochila.quantos())
	elif mochila.documentos.has(o_documento):
		_erro("largou o documento e ele continua na mochila")

	var pilhas := get_tree().get_nodes_in_group("largado")
	if pilhas.size() != 1:
		_erro("largar uma coisa deixou %d pilha(s) no chao" % pilhas.size())
		rua.free()
		TelaDaMochila.aberta = false
		return

	var pilha: Node2D = pilhas[0]
	var jogador := rua.get_node("Jogador") as Node2D
	if not pilha.achados.has(o_documento):
		_erro("a pilha do chao nao tem o que foi largado")
	elif pilha.global_position.distance_to(jogador.global_position) > 1.0:
		_erro("a pilha caiu a %.0f px do jogador"
			% pilha.global_position.distance_to(jogador.global_position))
	else:
		print("  \"%s\" caiu aos pes do jogador" % o_documento)

	# Largar outra coisa no mesmo lugar nao pode criar uma segunda pilha.
	tela._escolhida = 0
	tela._largar()
	if get_tree().get_nodes_in_group("largado").size() != 1:
		_erro("a segunda coisa largada no mesmo lugar criou outra pilha")
	elif pilha.achados.size() != 2:
		_erro("a pilha ficou com %d coisa(s), esperado 2" % pilha.achados.size())
	else:
		print("  o segundo documento caiu na mesma pilha")

	# E o chao devolve: a pilha e um vasculhavel como outro qualquer.
	pilha._esvaziar()
	if not mochila.documentos.has(o_documento):
		_erro("pegar a pilha de volta nao devolveu o documento")
	elif mochila.quantos() != 2:
		_erro("pegar a pilha devolveu %d documento(s), esperado 2" % mochila.quantos())
	else:
		print("  pegar a pilha devolveu os dois")

	tela._fechar()
	if TelaDaMochila.aberta:
		_erro("a tela continuou aberta depois de fechar")
	rua.free()
