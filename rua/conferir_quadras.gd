extends Node
## Ferramenta **temporaria** (sai em P14). Rode esta cena (F6) depois de
## mexer em `quadras.gd`.
##
## Testa `quadras.gd` com quadras SINTETICAS, sem tocar no mapa de verdade -
## `quadras.gd` ainda nao tem consumidor (chega em P7). Prova as 8 garantias
## que o contrato promete: 1 frente reparte o vao sem sobra nem
## sobreposicao; 2 frentes opostas nao se cruzam no meio; 3 e 4 frentes nao
## sobrepoem lote de esquina; via que so cobre metade da aresta so gera lote
## na metade coberta; quadra sem frente nenhuma nao gera lote (e nao quebra);
## lote raso demais descarta o predio em vez de colar no asfalto; a mesma
## quadra montada duas vezes da o mesmo resultado; e `pula` tira so o lote
## pedido, sem mover os vizinhos.

const Quadras := preload("res://rua/quadras.gd")
const Vias := preload("res://rua/vias.gd")

var _falhas := 0

func _ready() -> void:
	_um_frente()
	_duas_frentes_opostas()
	_tres_e_quatro_frentes()
	_via_cobre_so_metade()
	_sem_frente_nenhuma()
	_lote_raso_descarta()
	_predio_cabe_no_lote_normal()
	_determinismo()
	_pula_nao_move_vizinhos()

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

# ------------------------------------------------------------- infraestrutura

func _via(nome: String, classe: String, eixo: Array) -> Dictionary:
	return { "nome": nome, "classe": classe, "eixo": eixo, "pontas": ["", ""] }

## Uma caixa de 4 vias residenciais em volta do retangulo dado, para servir
## de `entre` em todos os lados - poupa repetir a mesma armacao em cada teste.
## O deslocamento e a METADE da largura da classe "residencial" - nao um
## numero cravado -, para a borda util da via encostar exatamente na borda
## do `r` dado. Cravado em 200 ate 17/09/2026 (P7), quebrou quando a classe
## foi de 400 para 320 px: a conta dos testes passou a sobrar 40 px por
## lado, e "vao 4080" onde devia dar "4000" - o proprio numero apontou o
## motivo.
func _caixa(r: Rect2) -> Dictionary:
	var meio: float = Vias.CLASSES["residencial"]["largura"] / 2.0
	return {
		"norte": _via("norte", "residencial", [Vector2(r.position.x, r.position.y - meio),
			Vector2(r.end.x, r.position.y - meio)]),
		"sul": _via("sul", "residencial", [Vector2(r.position.x, r.end.y + meio),
			Vector2(r.end.x, r.end.y + meio)]),
		"leste": _via("leste", "residencial", [Vector2(r.end.x + meio, r.position.y),
			Vector2(r.end.x + meio, r.end.y)]),
		"oeste": _via("oeste", "residencial", [Vector2(r.position.x - meio, r.position.y),
			Vector2(r.position.x - meio, r.end.y)]),
	}

func _sobrepoe(a: Rect2, b: Rect2) -> bool:
	return a.grow(-1.0).intersects(b.grow(-1.0))

# --- 1. uma frente -----------------------------------------------------------

func _um_frente() -> void:
	print("1. uma frente")
	# A caixa fica a 200 px de fora do miolo (0,0,4000,1200): a aresta "sul"
	# do miolo cai exatamente na faixa da via "sul" da caixa.
	var miolo := Rect2(0.0, 0.0, 4000.0, 1200.0)
	var vias := _caixa(miolo)
	var quadra := {
		"id": "Q1", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["sul"], "passo": 800.0,
	}
	var rect := Quadras.rect_da_quadra(quadra, vias)
	var lotes := Quadras.lotes_da_quadra(quadra, vias)

	var esperados := int(floor(rect.size.x / 800.0))
	if lotes.size() != esperados:
		_erro("1 frente: %d lotes, esperava %d" % [lotes.size(), esperados])
	var soma := 0.0
	for lote in lotes:
		soma += (lote["rect"] as Rect2).size.x
	if absf(soma - rect.size.x) > 1.0:
		_erro("1 frente: soma das larguras %.1f != vao %.1f" % [soma, rect.size.x])
	for i in lotes.size():
		for j in range(i + 1, lotes.size()):
			if _sobrepoe(lotes[i]["rect"], lotes[j]["rect"]):
				_erro("1 frente: lote %d se sobrepoe ao %d" % [i, j])
	print("  %d lotes, soma %.0f de %.0f de vao" % [lotes.size(), soma, rect.size.x])

# --- 2. duas frentes opostas --------------------------------------------------

func _duas_frentes_opostas() -> void:
	print("2. duas frentes opostas")
	var miolo := Rect2(0.0, 0.0, 3200.0, 2400.0)
	var vias := _caixa(miolo)
	var quadra := {
		"id": "Q2", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["norte", "sul"], "passo": 800.0,
	}
	var lotes := Quadras.lotes_da_quadra(quadra, vias)
	var do_norte := lotes.filter(func(l): return l["frente"] == "norte")
	var do_sul := lotes.filter(func(l): return l["frente"] == "sul")
	if do_norte.is_empty() or do_sul.is_empty():
		_erro("2 frentes: uma das duas fileiras ficou vazia")
		return
	for norte_lote in do_norte:
		for sul_lote in do_sul:
			if _sobrepoe(norte_lote["rect"], sul_lote["rect"]):
				_erro("2 frentes: lote do norte se sobrepoe a lote do sul")
	var profundidade: float = do_norte[0]["profundidade"]
	if not is_equal_approx(profundidade, miolo.size.y / 2.0):
		_erro("2 frentes: profundidade %.1f, esperava metade (%.1f)" % [profundidade, miolo.size.y / 2.0])
	print("  %d lotes ao norte, %d ao sul, profundidade %.0f cada (metade da quadra)"
		% [do_norte.size(), do_sul.size(), profundidade])

# --- 3. tres e quatro frentes -------------------------------------------------

func _tres_e_quatro_frentes() -> void:
	print("3. tres e quatro frentes")
	for n in [3, 4]:
		var miolo := Rect2(0.0, 0.0, 2400.0, 2400.0)
		var vias := _caixa(miolo)
		var todas := ["norte", "sul", "leste", "oeste"]
		var quadra := {
			"id": "Q3-%d" % n, "lugar": "teste",
			"entre": { "norte": "norte", "sul": "sul", "leste": "leste", "oeste": "oeste" },
			"frentes": todas.slice(0, n), "passo": 700.0,
		}
		var lotes := Quadras.lotes_da_quadra(quadra, vias)
		var ruins := 0
		for i in lotes.size():
			for j in range(i + 1, lotes.size()):
				if _sobrepoe(lotes[i]["rect"], lotes[j]["rect"]):
					ruins += 1
		if ruins > 0:
			_erro("%d frentes: %d par(es) de lote se sobrepondo (provavel lote de esquina)"
				% [n, ruins])
		else:
			print("  %d frentes: %d lotes, nenhum se sobrepoe" % [n, lotes.size()])

# --- 4. via que so cobre metade da aresta -------------------------------------

func _via_cobre_so_metade() -> void:
	print("4. via cobrindo so metade da aresta")
	var miolo := Rect2(0.0, 0.0, 4000.0, 1200.0)
	var vias := _caixa(miolo)
	# A via "sul" agora so cobre a metade OESTE da aresta (x 0..2000, nao
	# 0..4000) - simula uma rua que comeca no meio do quarteirao.
	vias["sul"] = _via("sul", "residencial",
		[Vector2(miolo.position.x, miolo.end.y + 200.0), Vector2(miolo.position.x + 2000.0, miolo.end.y + 200.0)])
	var quadra := {
		"id": "Q4", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["sul"], "passo": 800.0,
	}
	var lotes := Quadras.lotes_da_quadra(quadra, vias)
	var alem := 0
	for lote in lotes:
		if (lote["rect"] as Rect2).end.x > miolo.position.x + 2000.0 + 1.0:
			alem += 1
	if alem > 0:
		_erro("via cobrindo metade: %d lote(s) nasceram alem do trecho coberto" % alem)
	elif lotes.is_empty():
		_erro("via cobrindo metade: nenhum lote nasceu na metade que TEM via")
	else:
		print("  %d lotes, todos dentro do trecho coberto pela via" % lotes.size())

# --- 5. quadra sem frente nenhuma ---------------------------------------------

func _sem_frente_nenhuma() -> void:
	print("5. quadra sem frente nenhuma")
	var miolo := Rect2(0.0, 0.0, 2000.0, 1000.0)
	var vias := _caixa(miolo)
	var quadra := {
		"id": "Q5", "lugar": "teste",
		"entre": { "norte": "norte", "sul": "sul", "leste": "leste", "oeste": "oeste" },
		"frentes": [], "passo": 800.0,
	}
	var lotes := Quadras.lotes_da_quadra(quadra, vias)
	if not lotes.is_empty():
		_erro("sem frente: gerou %d lote(s), esperava 0" % lotes.size())
	else:
		print("  0 lotes, sem erro")

# --- 6. lote raso demais -------------------------------------------------------

func _lote_raso_descarta() -> void:
	print("6. lote raso demais")
	var via := _via("via", "residencial", [Vector2(0.0, 1000.0), Vector2(2000.0, 1000.0)])
	# Profundidade de 200 - menor que QUINTAL_MIN(160) + a planta mais rasa
	# (perto de 380) + o menor recuo da classe (240): nenhuma planta cabe.
	var lote := {
		"rect": Rect2(500.0, 600.0, 900.0, 200.0), "frente": "sul",
		"profundidade": 200.0, "chave": "teste/raso/sul/0", "quadra": "raso",
	}
	var predio := Quadras.predio_no_lote(lote, "casa", via, {})
	if not predio.is_empty():
		_erro("lote raso: devolveu predio (%s) em vez de descartar" % predio)
	else:
		print("  descartado (dicionario vazio), como esperado")

# --- o caminho feliz: lote normal vira predio de verdade ---------------------

## O teste 6 so prova o descarte; sem este, "toda entrada devolve {}" passaria
## no 6 e ninguem notaria.
func _predio_cabe_no_lote_normal() -> void:
	print("- o caminho feliz: lote normal vira predio")
	var miolo := Rect2(0.0, 0.0, 4000.0, 1400.0)
	var vias := _caixa(miolo)
	var quadra := {
		"id": "Qn", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["sul"], "passo": 800.0,
	}
	var lotes := Quadras.lotes_da_quadra(quadra, vias)
	if lotes.is_empty():
		_erro("caminho feliz: nenhum lote gerado para testar")
		return
	var validos := 0
	for lote in lotes:
		var predio := Quadras.predio_no_lote(lote, "casa", vias["sul"], {})
		if predio.is_empty():
			continue
		validos += 1
		var l: Rect2 = lote["rect"]
		var r: Rect2 = predio["rect"]
		if not l.grow(1.0).encloses(r):
			_erro("caminho feliz: o predio %s saiu do lote %s" % [r, l])
		if predio["porta"] != "sul" or predio["via"] != "sul":
			_erro("caminho feliz: porta/via do predio nao batem com o lote")
	if validos == 0:
		_erro("caminho feliz: NENHUM lote normal virou predio - predio_no_lote descarta tudo?")
	else:
		print("  %d de %d lotes viraram predio, todos dentro do lote" % [validos, lotes.size()])

# --- 7. determinismo -----------------------------------------------------------

func _determinismo() -> void:
	print("7. determinismo")
	var miolo := Rect2(0.0, 0.0, 3600.0, 1400.0)
	var vias := _caixa(miolo)
	var quadra := {
		"id": "Q7", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["sul"], "passo": 750.0,
	}
	var a := Quadras.lotes_da_quadra(quadra, vias)
	var b := Quadras.lotes_da_quadra(quadra, vias)
	if a.size() != b.size():
		_erro("determinismo: tamanhos diferentes (%d vs %d)" % [a.size(), b.size()])
	else:
		var ruins := 0
		for i in a.size():
			var ra: Rect2 = a[i]["rect"]
			var rb: Rect2 = b[i]["rect"]
			if not (ra.position.is_equal_approx(rb.position) and ra.size.is_equal_approx(rb.size)):
				ruins += 1
		if ruins > 0:
			_erro("determinismo: %d lote(s) vieram diferentes na segunda rodada" % ruins)
		else:
			print("  duas rodadas, %d lotes, identicos" % a.size())

# --- 8. pula nao move os vizinhos ---------------------------------------------

func _pula_nao_move_vizinhos() -> void:
	print("8. pula nao move os vizinhos")
	var miolo := Rect2(0.0, 0.0, 4000.0, 1400.0)
	var vias := _caixa(miolo)
	var base := {
		"id": "Q8", "lugar": "teste", "entre": { "norte": "norte", "sul": "sul",
			"leste": "leste", "oeste": "oeste" },
		"frentes": ["sul"], "passo": 800.0,
	}
	var sem_pula := Quadras.lotes_da_quadra(base, vias)
	var com_pula: Dictionary = base.duplicate(true)
	com_pula["pula"] = [2]
	var pulado := Quadras.lotes_da_quadra(com_pula, vias)

	if sem_pula.size() - pulado.size() != 1:
		_erro("pula: esperava exatamente 1 lote a menos (%d -> %d)" % [sem_pula.size(), pulado.size()])
		return
	var ruins := 0
	for lote in pulado:
		var chave: String = lote["chave"]
		var indice := int(chave.get_slice("/", 3))
		var original: Rect2 = sem_pula[indice]["rect"]
		if not (original.position.is_equal_approx((lote["rect"] as Rect2).position)):
			ruins += 1
	if ruins > 0:
		_erro("pula: %d lote(s) vizinho(s) mudaram de posicao" % ruins)
	else:
		print("  o lote 2 sumiu e os outros %d ficaram exatamente onde estavam" % pulado.size())
