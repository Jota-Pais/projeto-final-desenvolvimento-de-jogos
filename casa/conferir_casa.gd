extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na casa** - comodos,
## pontos de clique, energia ou o exame.
##
## Confere:
##
##  1. todo ponto de clique cabe na tela, e todo "vai" leva a um comodo que
##     existe;
##  2. **da para chegar em todo comodo** partindo da entrada, e voltar;
##  3. todo ponto que nao e porta tem resposta - clicar nele abre uma fala;
##  4. a energia: exame e estudo gastam uma cada, nunca passa de zero, e sem
##     energia as opcoes apagam;
##  5. estudar atravessa a noite (o Travessia lembra) e nao conta para a cura;
##  6. o estagio dela anda do primeiro ao ultimo dia do prazo, e todo estagio
##     tem laudo para toda parte;
##  7. todo comodo tem a sua foto (casa/arte/<comodo>.png, 1280 x 720) - sem
##     ela a tela fica preta (16/10/2026);
##  8. o contorno de cada objeto (21/10/2026): cabe na tela, nao entra na
##     faixa de voltar, o `rect` e a caixa dele, e o miolo dele responde por
##     ele (nenhum ponto de antes na lista o tampa) - o dela tambem, que o
##     desenho calcula.
##
## As regras de fim de partida (cura, prazo) sao conferidas no
## rua/conferir_fim.tscn, que ja usa esta casa.

const Comodos := preload("res://casa/comodos.gd")
const Ela := preload("res://casa/ela.gd")
const CENA_DA_CASA := preload("res://casa/casa.tscn")

var _falhas := 0
var _rodou := false

func _process(_delta: float) -> void:
	if _rodou:
		return
	_rodou = true
	_limpar()
	_os_pontos_cabem()
	_todo_comodo_se_alcanca()
	_todo_ponto_responde()
	_a_energia()
	_estudar()
	_o_estagio_dela()
	_toda_tela_tem_foto()
	_os_contornos()
	_limpar()
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

func _limpar() -> void:
	Travessia.dia = 1
	Travessia.documentos.clear()
	Travessia.documentos_lidos.clear()
	Travessia.documentos_perdidos = 0
	Travessia.fim_do_dia = Travessia.FimDoDia.PELA_PORTA

func _uma_casa() -> Control:
	var casa: Control = CENA_DA_CASA.instantiate()
	add_child(casa)
	# Se o casa.gd (ou o desenho.gd) nao compila, a cena vem sem script e todo
	# o resto compara Nil com Nil e "passa" - aconteceu em 16/10/2026.
	if not casa.has_method("_clicar"):
		_erro("a casa nao compilou (casa.gd ou desenho.gd) - ver os erros acima")
	return casa

func _os_pontos_cabem() -> void:
	print("\n1. os pontos cabem na tela")
	var tela := Rect2(Vector2.ZERO, Comodos.TELA)
	var quantos := 0
	for comodo in Comodos.COMODOS:
		for ponto in Comodos.COMODOS[comodo]["pontos"]:
			quantos += 1
			if not tela.encloses(ponto["rect"]):
				_erro("%s/%s sai da tela: %s" % [comodo, ponto["id"], ponto["rect"]])
			if ponto.has("vai") and not Comodos.COMODOS.has(ponto["vai"]):
				_erro("%s/%s leva a um comodo que nao existe: %s" % [comodo, ponto["id"], ponto["vai"]])
	print("  %d pontos em %d comodos" % [quantos, Comodos.COMODOS.size()])

func _os_contornos() -> void:
	print("\n8. os contornos")
	# O dela sai do desenho: um quadro do quarto o calcula.
	var casa := _uma_casa()
	casa._desenho.preparar_o_contorno_dela()
	var tela := Rect2(Vector2.ZERO, Comodos.TELA)
	var com_contorno := 0
	for comodo in Comodos.COMODOS:
		for ponto in Comodos.COMODOS[comodo]["pontos"]:
			if ponto["rect"] == Comodos.VOLTAR:
				continue
			var partes := Comodos.contorno_de(ponto)
			if partes.is_empty():
				_erro("%s/%s nao tem contorno" % [comodo, ponto["id"]])
				continue
			com_contorno += 1
			var caixa := Rect2((partes[0] as PackedVector2Array)[0], Vector2.ZERO)
			for parte in partes:
				if (parte as PackedVector2Array).size() < 3:
					_erro("%s/%s tem contorno com menos de 3 vertices" % [comodo, ponto["id"]])
				for p in parte:
					caixa = caixa.expand(p)
					if not tela.grow(0.01).has_point(p):
						_erro("%s/%s: vertice %s fora da tela" % [comodo, ponto["id"], p])
					if Comodos.VOLTAR.has_point(p):
						_erro("%s/%s: vertice %s na faixa de voltar" % [comodo, ponto["id"], p])
			# O rect e a caixa do contorno (o dela muda com o estagio: so ela fica
			# de fora desta conta).
			if ponto.has("contorno") and not (ponto["rect"] as Rect2).grow(0.6).encloses(caixa):
				_erro("%s/%s: o rect %s nao e a caixa do contorno %s" % [comodo, ponto["id"], ponto["rect"], caixa])
			# O miolo responde pelo ponto: o centro de um triangulo do contorno.
			var maior: PackedVector2Array = partes[0]
			for parte in partes:
				if (parte as PackedVector2Array).size() > maior.size():
					maior = parte
			var tri := Geometry2D.triangulate_polygon(maior)
			if tri.is_empty():
				_erro("%s/%s: o contorno nao se triangula (cruza a si mesmo?)" % [comodo, ponto["id"]])
				continue
			var miolo := (maior[tri[0]] + maior[tri[1]] + maior[tri[2]]) / 3.0
			var achado := Comodos.ponto_em(comodo, miolo)
			if achado.get("id", "") != ponto["id"]:
				_erro("%s/%s: o miolo %s responde por '%s'" % [comodo, ponto["id"], miolo, achado.get("id", "")])
	casa.queue_free()
	print("  %d objetos com contorno" % com_contorno)

func _todo_comodo_se_alcanca() -> void:
	print("\n2. todo comodo se alcanca")
	var visto := { "entrada": true }
	var fila := ["entrada"]
	while not fila.is_empty():
		var aqui: String = fila.pop_front()
		for ponto in Comodos.COMODOS[aqui]["pontos"]:
			if ponto.has("vai") and not visto.has(ponto["vai"]):
				visto[ponto["vai"]] = true
				fila.append(ponto["vai"])
	for comodo in Comodos.COMODOS:
		if not visto.has(comodo):
			_erro("nao se chega em %s partindo da entrada" % comodo)
		var volta := false
		for ponto in Comodos.COMODOS[comodo]["pontos"]:
			volta = volta or ponto.has("vai")
		if not volta:
			_erro("%s nao tem saida" % comodo)
	print("  %d de %d alcancaveis" % [visto.size(), Comodos.COMODOS.size()])

func _todo_ponto_responde() -> void:
	print("\n3. todo ponto responde")
	Travessia.documentos.append("documento 1")
	var casa := _uma_casa()
	for comodo in Comodos.COMODOS:
		casa.comodo = comodo
		for ponto in Comodos.COMODOS[comodo]["pontos"]:
			if ponto.has("vai"):
				continue
			casa._fechar_fala()
			casa._clicar(ponto)
			if not casa._caixa.visible or casa._fala.text.is_empty():
				_erro("%s/%s nao abriu fala nenhuma" % [comodo, ponto["id"]])
	casa.free()
	_limpar()
	print("  feito")

func _a_energia() -> void:
	print("\n4. a energia")
	var casa := _uma_casa()
	if casa.energia != casa.ENERGIA_POR_NOITE:
		_erro("a noite comecou com %d de energia" % casa.energia)
	for i in casa.ENERGIA_POR_NOITE:
		casa._examinar(Ela.PARTES[i % Ela.PARTES.size()])
	if casa.energia != 0:
		_erro("%d exames deixaram %d de energia" % [casa.ENERGIA_POR_NOITE, casa.energia])
	if casa._desenho.close_up.is_empty():
		_erro("o exame nao mostrou o close")
	casa._ela()
	var acesas := 0
	for botao in casa._escolhas.get_children():
		if not (botao as Button).disabled:
			acesas += 1
	# So "deixar ela em paz" continua clicavel.
	if acesas != 1:
		_erro("sem energia, %d opcoes do exame continuaram clicaveis" % acesas)
	var total: int = casa.ENERGIA_POR_NOITE
	casa.free()
	print("  %d exames gastaram tudo, e sem energia o exame apaga" % total)

func _estudar() -> void:
	print("\n5. estudar")
	for i in Travessia.DOCUMENTOS_PARA_A_CURA - 1:
		Travessia.documentos.append("documento %d" % (i + 1))
	var casa := _uma_casa()
	casa._estudar("documento 1")
	if casa.energia != casa.ENERGIA_POR_NOITE - 1:
		_erro("estudar nao gastou energia")
	casa.free()
	if not "documento 1" in Travessia.documentos_lidos:
		_erro("o Travessia esqueceu o documento estudado")
	# Numa noite nova, o estudado nao aparece de novo para estudar.
	casa = _uma_casa()
	casa._pesquisa()
	for botao in casa._escolhas.get_children():
		if (botao as Button).text.contains("documento 1 "):
			_erro("o documento estudado ontem voltou a ser oferecido")
	casa.free()
	if Travessia.a_cura_esta_pronta():
		_erro("estudar mudou a conta da cura")
	_limpar()
	print("  estudado fica estudado, e a cura segue contando documentos entregues")

func _o_estagio_dela() -> void:
	print("\n6. o estagio dela")
	var primeiro := Ela.estagio(1, Travessia.PRAZO_DA_CURA)
	var ultimo := Ela.estagio(Travessia.PRAZO_DA_CURA, Travessia.PRAZO_DA_CURA)
	if primeiro != 0:
		_erro("no dia 1 ela ja esta no estagio %d" % primeiro)
	if ultimo != Ela.ESTAGIOS - 1:
		_erro("no ultimo dia ela esta no estagio %d, e nao no ultimo" % ultimo)
	var anterior := 0
	for dia in range(1, Travessia.PRAZO_DA_CURA + 1):
		var e := Ela.estagio(dia, Travessia.PRAZO_DA_CURA)
		if e < anterior:
			_erro("o estagio voltou no dia %d" % dia)
		anterior = e
	for parte in Ela.PARTES:
		if (Ela.LAUDO[parte] as Array).size() != Ela.ESTAGIOS:
			_erro("%s tem %d laudos para %d estagios" % [parte, Ela.LAUDO[parte].size(), Ela.ESTAGIOS])
	print("  estagio 0 no dia 1, %d no dia %d" % [ultimo, Travessia.PRAZO_DA_CURA])

func _toda_tela_tem_foto() -> void:
	print("\n7. toda tela tem foto")
	var tamanho := Vector2i(Comodos.TELA * 4.0)
	for comodo in Comodos.COMODOS:
		var arte := "res://casa/arte/%s.png" % comodo
		if not ResourceLoader.exists(arte):
			_erro("%s nao tem foto (%s)" % [comodo, arte])
			continue
		var foto: Texture2D = load(arte)
		if Vector2i(foto.get_size()) != tamanho:
			_erro("%s tem %s, e a tela e %s" % [arte, foto.get_size(), tamanho])
	print("  %d comodos" % Comodos.COMODOS.size())
