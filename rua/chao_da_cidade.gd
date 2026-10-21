extends RefCounted
## O chão da cidade refeito por regra (21/10/2026): lê rua/chao_da_cidade.json,
## que o design/tracar_ruas.js escreve a partir do desenho, e entrega cada
## camada em mundo - a rua, a calçada, o resto de cada prédio e o cinza claro
## que não é de ninguém -, os eixos das ruas e o meio-fio. Quem pinta é o
## rua/ruas.gd; o rua/detalhes_da_rua.gd pergunta `classe_em` para pôr a
## faixa, o poste e a sujeira no chão certo.
##
## Pedido do João (21/10): "as ruas precisam de um olhar mais detalhado,
## algumas tão meio tortas e sem sentido, calçadas não tão seguindo uma
## proporção". Questionário: calçada de largura fixa e o resto por lugar
## (quintal perto de casa, pátio perto de comércio, terreno baldio no resto),
## rua seguindo o desenho, mapa inteiro.

const Mapa := preload("res://rua/mapa.gd")

const ARQUIVO := "res://rua/chao_da_cidade.json"

## O chão do resto de cada prédio, pelo tipo dele: quintal na casa, terreno
## baldio no que está largado, pátio cimentado no resto (loja, delegacia,
## pizzaria, posto...). Prédio que o mapa não achou: baldio.
const DE_QUINTAL := ["casa", "casa_pequena", "mansao"]
const DE_BALDIO := ["predio_abandonado", "predio_em_construcao", "campo"]

## O lado da célula do índice de `classe_em`, em px de mundo.
const CELULA_DO_INDICE := 256.0

static var _dado := {}
static var _camadas := {}
static var _indice := {}

static func _ler() -> Dictionary:
	if _dado.is_empty():
		var texto := FileAccess.get_file_as_string(ARQUIVO)
		assert(texto != "", "nao achei %s - rode node design/tracar_ruas.js" % ARQUIVO)
		_dado = JSON.parse_string(texto)
	return _dado

static func _escala() -> float:
	return float(_ler()["escala"])

static func _pontos(lista: Array) -> PackedVector2Array:
	var e := _escala()
	var fora := PackedVector2Array()
	for p in lista:
		fora.append(Vector2(float(p[0]), float(p[1])) * e)
	return fora

static func _triangulos(c: Dictionary) -> Dictionary:
	var e := _escala()
	var v: Array = c["v"]
	var vertices := PackedVector2Array()
	vertices.resize(v.size() / 2)
	for i in vertices.size():
		vertices[i] = Vector2(float(v[2 * i]), float(v[2 * i + 1])) * e
	return { "v": vertices, "t": PackedInt32Array(c["t"]) }

## As camadas prontas, em mundo, cada uma { "v": vertices, "t": indices de
## tres em tres }: "asfalto", "calcada", "cidade" (o cinza claro inteiro, que
## fica de baldio por baixo) e "quintal", "patio", "baldio" (o resto dos
## predios, juntos por chão).
static func camadas() -> Dictionary:
	if not _camadas.is_empty():
		return _camadas
	var d := _ler()
	for nome in ["asfalto", "calcada", "cidade"]:
		_camadas[nome] = _triangulos(d["camadas"][nome])
	var juntos := { "quintal": [], "patio": [], "baldio": [] }
	for lote in d["lotes"]:
		(juntos[chao_do_lote(lote)] as Array).append(_triangulos(lote))
	for nome in juntos:
		var v := PackedVector2Array()
		var t := PackedInt32Array()
		for parte in juntos[nome]:
			var base := v.size()
			v.append_array(parte["v"])
			for k in parte["t"]:
				t.append(base + k)
		_camadas[nome] = { "v": v, "t": t }
	return _camadas

## O chão do resto de um prédio: pelo tipo da construção mais perto do centro
## dele (o mapa endireita, recorta e às vezes move o prédio do desenho - o
## centro nem sempre cai dentro). Nenhuma a até PERTO_DO_LOTE: baldio.
const PERTO_DO_LOTE := 160.0
static func chao_do_lote(lote: Dictionary) -> String:
	var centro := Vector2(float(lote["centro"][0]), float(lote["centro"][1])) * _escala()
	var tipo := ""
	var menor := PERTO_DO_LOTE
	for construcao in Mapa.mundo()["construcoes"]:
		var r: Rect2 = construcao["rect"]
		var d := (centro - centro.clamp(r.position, r.end)).length()
		if d < menor:
			menor = d
			tipo = construcao["tipo"]
	if tipo == "":
		return "baldio"
	if tipo in DE_QUINTAL:
		return "quintal"
	if tipo in DE_BALDIO:
		return "baldio"
	return "patio"

## Os eixos das ruas, em mundo: { "pontos", "largura", "borda" } - `borda` diz
## se cada ponta sai pela beira do mapa (e nao num cruzamento).
static func eixos() -> Array:
	var fora: Array = []
	for r in _ler()["eixos"]:
		fora.append({ "pontos": _pontos(r["pontos"]), "largura": float(r["largura"]) * _escala(), "borda": r["borda"] })
	return fora

static func rotatorias() -> Array:
	var fora: Array = []
	for r in _ler()["rotatorias"]:
		fora.append({ "centro": Vector2(float(r["centro"][0]), float(r["centro"][1])) * _escala(),
			"ilha": float(r["ilha"]) * _escala(), "fora": float(r["fora"]) * _escala() })
	return fora

## As bordas da rua (anéis fechados, em mundo). A rua fica à esquerda de
## quem anda pelo anel (o (-dy, dx) de cada trecho aponta para ela).
static func meio_fio() -> Array:
	var fora: Array = []
	for anel in _ler()["meio_fio"]:
		fora.append(_pontos(anel))
	return fora

## A largura da calçada, em px de mundo.
static func largura_da_calcada() -> float:
	return float(_ler()["largura_da_calcada"]) * _escala()

## O chão novo num ponto: "asfalto", "calcada", "quintal", "patio" ou
## "baldio" - a camada de cima, na ordem em que o ruas.gd pinta. Fora delas
## (a grama, a mata, o gramado de lote por cima), "".
static func classe_em(ponto: Vector2) -> String:
	if _indice.is_empty():
		_indexar()
	var chave := Vector2i((ponto / CELULA_DO_INDICE).floor())
	for nome in ["asfalto", "calcada", "quintal", "patio", "baldio", "cidade"]:
		var lista: Array = (_indice[nome] as Dictionary).get(chave, [])
		if lista.is_empty():
			continue
		var c: Dictionary = camadas()[nome]
		var v: PackedVector2Array = c["v"]
		var t: PackedInt32Array = c["t"]
		for k in lista:
			if Geometry2D.point_is_inside_triangle(ponto, v[t[k]], v[t[k + 1]], v[t[k + 2]]):
				return "baldio" if nome == "cidade" else nome
	return ""

static func _indexar() -> void:
	for nome in ["asfalto", "calcada", "quintal", "patio", "baldio", "cidade"]:
		var porcelula := {}
		var c: Dictionary = camadas()[nome]
		var v: PackedVector2Array = c["v"]
		var t: PackedInt32Array = c["t"]
		for k in range(0, t.size(), 3):
			var caixa := Rect2(v[t[k]], Vector2.ZERO).expand(v[t[k + 1]]).expand(v[t[k + 2]])
			var de := Vector2i((caixa.position / CELULA_DO_INDICE).floor())
			var ate := Vector2i((caixa.end / CELULA_DO_INDICE).floor())
			for y in range(de.y, ate.y + 1):
				for x in range(de.x, ate.x + 1):
					var chave := Vector2i(x, y)
					if not porcelula.has(chave):
						porcelula[chave] = []
					(porcelula[chave] as Array).append(k)
		_indice[nome] = porcelula
