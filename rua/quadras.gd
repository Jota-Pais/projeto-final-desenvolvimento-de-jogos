## Quadra -> lote -> predio.
##
## `rua/vias.gd` diz o que uma rua e por fora; este arquivo diz como o chao
## entre as vias vira quadra, a quadra vira lote, e o lote recebe um predio
## virado para a via que o serve. Nasce em 17/09/2026 (P5 da arquitetura
## nova); `lugares.gd` gera a cidade e o bairro inteiros em cima disto desde
## P8/P9 (`_construir_quadra`).
##
## ## Por que a quadra nao e um Rect2 escrito a mao
##
## Um retangulo escrito a mao e uma tabela que discorda de outra tabela (a das
## vias) sem ninguem perceber - foi o furo mais caro achado nos tres desenhos
## julgados: lote por cima de rua, faixa orfa de 160 px entre quadra e rua,
## quadras se sobrepondo 560 px. Aqui a quadra **declara so quais vias a
## limitam** (`entre`) e, para o lado que nao tem via, uma profundidade
## (`fundo`); o retangulo e sempre CALCULADO (`rect_da_quadra`), nunca
## escrito duas vezes.
##
## ## Uma quadra
##
## ```gdscript
## {
##   "id": "QB-A", "lugar": "bairro", "uso": "casa",
##   "entre": {"norte": "Rodovia", "sul": "Rua do Bairro"},
##   "fundo": {},                  # lado sem via: profundidade declarada, em px
##   "frentes": ["sul"],           # onde nascem lotes; e o lado da PORTA
##   "passo": 880.0,               # frente-alvo do lote; a real varia +-22%
##   "plantas": "suburbio",        # chave de Construcao.CONJUNTOS_DE_PLANTA
##   "pula": [2],                  # terreno baldio declarado, por indice
## }
## ```
##
## Um lado tem que ter `entre` OU `fundo` - nao os dois, nao nenhum. (A prova
## disso e tarefa de quem consumir isto contra `conferir_mapa`, em P7; aqui a
## quadra mal formada so produz geometria sem sentido, nao trava.)

const Construcao := preload("res://rua/construcao.gd")
const Vias := preload("res://rua/vias.gd")

const OPOSTO := { "norte": "sul", "sul": "norte", "leste": "oeste", "oeste": "leste" }
const PERPENDICULAR := {
	"norte": ["leste", "oeste"], "sul": ["leste", "oeste"],
	"leste": ["norte", "sul"], "oeste": ["norte", "sul"],
}

## Quem serve primeiro no canto, quando duas frentes perpendiculares disputam
## a mesma esquina: quem tem posto maior. Comercio nao existe nesta escala
## ainda (chega em P7), mas a tabela ja inclui as classes finais para nao
## precisar mexer aqui de novo.
const POSTO := {
	"comercial": 5, "principal": 4, "residencial": 3, "laco": 3,
	"beco": 2, "terra": 1, "estacionamento": 2, "patio": 2, "rodovia": 4, "rural": 1,
}

## Quintal minimo atras do predio, e folga lateral dentro do lote - abaixo
## disso o lote e descartado (com aviso), em vez de colar o predio no
## asfalto ou na divisa em silencio.
const QUINTAL_MIN := 160.0
const FOLGA_LATERAL := 80.0

## O retangulo da quadra, DERIVADO das vias que a limitam (mais `fundo`, para
## o lado que nao tem via). Nunca escrito a mao.
static func rect_da_quadra(quadra: Dictionary, vias: Dictionary) -> Rect2:
	var norte := _coordenada(quadra, vias, "norte")
	var sul := _coordenada(quadra, vias, "sul")
	var oeste := _coordenada(quadra, vias, "oeste")
	var leste := _coordenada(quadra, vias, "leste")
	return Rect2(oeste, norte, leste - oeste, sul - norte)

## A coordenada de UM lado: se ha via `entre[lado]`, a borda util dela virada
## para DENTRO da quadra (o lado oposto ao nome, porque a via fica do lado de
## FORA). Senao, `fundo[lado]` e uma profundidade somada/subtraida da
## coordenada do lado OPOSTO - que por isso tem que ter via.
static func _coordenada(quadra: Dictionary, vias: Dictionary, lado: String) -> float:
	var entre: Dictionary = quadra.get("entre", {})
	if entre.has(lado):
		var via: Dictionary = vias[entre[lado]]
		return Vias.borda_util_de(via, OPOSTO[lado])
	var fundo: Dictionary = quadra.get("fundo", {})
	var oposta := _coordenada(quadra, vias, OPOSTO[lado])
	var profundidade: float = fundo.get(lado, 0.0)
	return oposta + profundidade if (lado == "sul" or lado == "leste") else oposta - profundidade

## O trecho da quadra que serve de fronteira com a via de uma frente, no eixo
## certo (x para norte/sul, y para leste/oeste).
static func _aresta(rect: Rect2, frente: String) -> Vector2:
	if frente == "sul" or frente == "norte":
		return Vector2(rect.position.x, rect.end.x)
	return Vector2(rect.position.y, rect.end.y)

static func _projecao(faixa: Rect2, frente: String) -> Vector2:
	if frente == "sul" or frente == "norte":
		return Vector2(faixa.position.x, faixa.end.x)
	return Vector2(faixa.position.y, faixa.end.y)

## Intersecao de dois intervalos 1D. Vazio (nada em comum) vira `(0,0)` com
## `y <= x` - quem chama confere `resultado.y > resultado.x` antes de usar.
static func _interseccao_1d(a: Vector2, b: Vector2) -> Vector2:
	var de := maxf(a.x, b.x)
	var ate := minf(a.y, b.y)
	return Vector2(de, ate)

static func _subtrair_um(a: Vector2, b: Vector2) -> Array[Vector2]:
	if b.y <= a.x or b.x >= a.y:
		var igual: Array[Vector2] = [a]
		return igual
	var fora: Array[Vector2] = []
	if b.x > a.x:
		fora.append(Vector2(a.x, b.x))
	if b.y < a.y:
		fora.append(Vector2(b.y, a.y))
	return fora

## `intervalo` menos cada reservado em `reservados`, como 0 a N pedacos.
static func _subtrair(intervalo: Vector2, reservados: Array) -> Array[Vector2]:
	var pedacos: Array[Vector2] = [intervalo]
	for r in reservados:
		var novos: Array[Vector2] = []
		for pedaco in pedacos:
			novos.append_array(_subtrair_um(pedaco, r as Vector2))
		pedacos = novos
	var validos: Array[Vector2] = []
	for p in pedacos:
		if p.y - p.x > 1.0:
			validos.append(p)
	return validos

## Quanto uma esquina de F reserva na aresta de G, perto do canto comum -
## sempre a extremidade de G do lado de F. Por isso so depende de F: os dois
## lados perpendiculares a F (leste e oeste, se F for norte/sul; norte e sul,
## se F for leste/oeste) reservam a MESMA extremidade, cada um na sua propria
## aresta.
static func _trecho_do_canto(rect: Rect2, f: String, p: float) -> Vector2:
	match f:
		"norte": return Vector2(rect.position.y, rect.position.y + p)
		"sul": return Vector2(rect.end.y - p, rect.end.y)
		"leste": return Vector2(rect.end.x - p, rect.end.x)
		_: return Vector2(rect.position.x, rect.position.x + p)  # oeste

## Os trechos reservados em cada aresta pelas esquinas com as frentes
## perpendiculares, por posto de classe. Sem isto, duas frentes perpendiculares
## geram lote de esquina sobreposto - o caso que so aparece com 3 ou 4 frentes.
static func cantos_reservados(quadra: Dictionary, vias: Dictionary, rect: Rect2) -> Dictionary:
	var reservado := { "norte": [], "sul": [], "leste": [], "oeste": [] }
	var entre: Dictionary = quadra.get("entre", {})
	var frentes: Array = (quadra["frentes"] as Array).duplicate()
	frentes.sort_custom(func(a, b) -> bool:
		var pa: int = POSTO.get((vias[entre[a]] as Dictionary)["classe"], 0) if entre.has(a) else 0
		var pb: int = POSTO.get((vias[entre[b]] as Dictionary)["classe"], 0) if entre.has(b) else 0
		if pa != pb:
			return pa > pb
		return (a as String) < (b as String))

	for f in frentes:
		var p := _profundidade_da_frente(quadra, rect, f)
		for g in PERPENDICULAR[f]:
			if not frentes.has(g):
				continue
			(reservado[g] as Array).append(_trecho_do_canto(rect, f, p))
	return reservado

## A profundidade dos lotes de uma frente: metade da quadra se ha frente
## OPOSTA tambem (duas fileiras costas-com-costas, cerca no meio - a cerca e
## quem gerar o lugar poe, nao quadras.gd); a quadra inteira, senao.
##
## **Nao e "distancia a borda util"** - foi essa definicao que zerava o
## clamp do recuo num dos tres desenhos julgados. E a folga real que o
## predio tem para crescer a partir da via.
static func _profundidade_da_frente(quadra: Dictionary, rect: Rect2, frente: String) -> float:
	var frentes: Array = quadra["frentes"]
	var tem_oposta: bool = frentes.has(OPOSTO[frente])
	var total: float = rect.size.y if (frente == "norte" or frente == "sul") else rect.size.x
	return total / 2.0 if tem_oposta else total

## Ruido determinista em [-1, 1], pela CHAVE (lugar/quadra/frente/indice) -
## nunca por indice de geracao cru, que re-sorteia tudo quando um lote e
## inserido antes.
static func _ruido(lugar: String, quadra_id: String, frente: String, i: int) -> float:
	var chave := "%s/%s/%s/%d" % [lugar, quadra_id, frente, i]
	return float(Construcao.embaralhar(chave) % 2001) / 1000.0 - 1.0

## Um lote, dado onde ele comeca ao longo da aresta (`x`), sua largura, a
## profundidade da frente e a borda (onde o lote encosta na via).
static func _lote(quadra: Dictionary, frente: String, x: float, largura: float,
		profundidade: float, borda: float, indice: int) -> Dictionary:
	var rect: Rect2
	match frente:
		"sul": rect = Rect2(x, borda - profundidade, largura, profundidade)
		"norte": rect = Rect2(x, borda, largura, profundidade)
		"leste": rect = Rect2(borda - profundidade, x, profundidade, largura)
		_: rect = Rect2(borda, x, profundidade, largura)  # oeste
	return {
		"rect": rect, "frente": frente, "profundidade": profundidade,
		"chave": "%s/%s/%s/%d" % [quadra["lugar"], quadra["id"], frente, indice],
		"quadra": quadra["id"],
	}

## Os lotes de uma quadra, em TODAS as frentes declaradas. Um lote so nasce
## onde ha via encarando aquele lado E onde o trecho dela cobre a frente -
## "casa com entrada pro nada" deixa de existir aqui, e nao em teste depois.
##
## Tres alavancas de irregularidade, as tres com que o desenho vencedor do
## painel nao tinha: **frente variavel +-22%** por ruido determinista, o
## **deslocamento lateral do predio** (dentro de `predio_no_lote`) e o
## **`pula: [i]`** (terreno baldio declarado).
static func lotes_da_quadra(quadra: Dictionary, vias: Dictionary) -> Array[Dictionary]:
	var fora: Array[Dictionary] = []
	var rect := rect_da_quadra(quadra, vias)
	var reservado := cantos_reservados(quadra, vias, rect)
	var entre: Dictionary = quadra.get("entre", {})
	var pula: Array = quadra.get("pula", [])
	var passo: float = quadra["passo"]

	for frente in (quadra["frentes"] as Array):
		if not entre.has(frente):
			continue  # frente sem via: nao gera lote (quadra mal formada)
		var via: Dictionary = vias[entre[frente]]
		var borda := Vias.borda_util_de(via, OPOSTO[frente])
		var projecao := _interseccao_1d(_aresta(rect, frente), _projecao(Vias.faixa_de(via), frente))
		if projecao.y <= projecao.x:
			continue
		var trechos := _subtrair(projecao, reservado.get(frente, []))
		var profundidade := _profundidade_da_frente(quadra, rect, frente)

		var indice := 0
		for t in trechos:
			var tamanho: float = t.y - t.x
			var quantos := int(floor(tamanho / passo))
			if quantos <= 0:
				indice += quantos
				continue
			var pesos: Array[float] = []
			var soma := 0.0
			for i in quantos:
				var peso := 1.0 + 0.22 * _ruido(quadra["lugar"], quadra["id"], frente, indice + i)
				pesos.append(peso)
				soma += peso
			# A largura normaliza contra `quantos * passo` (o alvo), NAO contra
			# `tamanho` (o trecho inteiro): sao os mesmos px que a margem
			# abaixo deixa de fora. Normalizar contra o trecho inteiro faz a
			# soma das larguras exceder `quantos * passo` pela margem
			# inteira, e o ultimo lote estoura o trecho coberto pela via -
			# achado testando isto em P5/P6, antes de lugares.gd consumir.
			var alvo: float = float(quantos) * passo
			var x: float = t.x + (tamanho - alvo) / 2.0
			for i in quantos:
				var largura: float = alvo * pesos[i] / soma
				if not pula.has(indice):
					fora.append(_lote(quadra, frente, x, largura, profundidade, borda, indice))
				x += largura
				indice += 1
	return fora

## Um lote que e a UNIAO de lotes vizinhos (mesma frente), para o predio que
## come mais de uma vaga - o mercado, na fita comercial. Fica com o `rect`
## somado, e a `chave`/`frente`/`quadra` do primeiro (`profundidade` e igual
## nos dois, ja que sao da mesma frente).
static func juntar(lotes: Array[Dictionary], de: int, ate: int) -> Dictionary:
	var rect: Rect2 = lotes[de]["rect"]
	for i in range(de + 1, ate + 1):
		rect = rect.merge(lotes[i]["rect"])
	var fundido := (lotes[de] as Dictionary).duplicate()
	fundido["rect"] = rect
	return fundido

## O predio dentro do lote, virado para a via que o serve, nas 4 direcoes.
##
## Devolve `{}` (lote descartado) se o predio nao couber com folga lateral e
## de fundo - **a regra que faltava**: sem ela, um recuo grande demais para o
## lote raso vira negativo em silencio e a casa nasce em cima do asfalto.
static func predio_no_lote(lote: Dictionary, tipo: String, via: Dictionary,
		extras: Dictionary) -> Dictionary:
	var porta: String = lote["frente"]
	# So "casa" varia de planta (17/09/2026, P8 - achado ao usar isto pela
	# primeira vez para um tipo que nao e casa): os outros tipos tem
	# tamanho fixo em `Construcao.TAMANHOS`, e sortear uma planta de casa
	# para um mercado ou uma delegacia daria um predio do tamanho errado -
	# a funcao nunca tinha sido chamada com outro tipo ate agora, entao o
	# gap nao aparecia em teste nenhum.
	var planta: Vector2 = Construcao.planta_de(lote.get("plantas", "suburbio"), lote["chave"]) \
		if tipo == "casa" else Construcao.TAMANHOS[tipo]
	var tamanho := planta
	if porta == "leste" or porta == "oeste":
		tamanho = Vector2(planta.y, planta.x)

	var classe: Dictionary = Vias.CLASSES[via["classe"]]
	var faixa_de_recuo: Vector2 = classe["recuo"]
	var recuo := faixa_de_recuo.x + 40.0 * float(Construcao.embaralhar(lote["chave"]) % 7)
	recuo = clampf(recuo, faixa_de_recuo.x, faixa_de_recuo.y)

	var profundidade: float = lote["profundidade"]
	if recuo + tamanho.y + QUINTAL_MIN > profundidade:
		recuo = profundidade - tamanho.y - QUINTAL_MIN
	if recuo < faixa_de_recuo.x or tamanho.x + 2.0 * FOLGA_LATERAL > (lote["rect"] as Rect2).size.x:
		return {}

	var desloca := 80.0 * float(Construcao.embaralhar(lote["chave"] + "!") % 3 - 1)
	var rect := _encostar(lote, porta, recuo, tamanho, desloca)
	# A entrada de carro tem que atravessar a grama e a calcada tambem, nao
	# so o recuo - senao ela para na beira do proprio quintal, curta da
	# calcada pelo tanto que a calcada mede (achado gerando os primeiros
	# predios coma calcada de verdade, em P8: a Rua do Bairro e a Avenida
	# sao as primeiras vias com calcada que ganham predio).
	# O lado da via que da para o predio e o OPOSTO da porta (a via fica do
	# lado de fora do lote, entao "porta sul" quer dizer "a via encara o
	# norte dela mesma").
	var ate_o_asfalto := recuo
	if via.get("calcada", "") == OPOSTO[porta]:
		ate_o_asfalto += classe["calcada"] + classe["grama"]
	var construcao := {
		"rect": rect, "porta": porta, "tipo": tipo, "recuo_ate_a_via": ate_o_asfalto,
		"via": via["nome"], "chave": lote["chave"],
	}
	construcao.merge(extras)
	return construcao

## O predio dentro do lote: fachada a `recuo` da borda que encara a via,
## centrado ao longo do lote (mais o deslocamento lateral).
static func _encostar(lote: Dictionary, porta: String, recuo: float, tamanho: Vector2,
		desloca: float) -> Rect2:
	var l: Rect2 = lote["rect"]
	match porta:
		"sul":
			return Rect2(l.get_center().x - tamanho.x / 2.0 + desloca, l.end.y - recuo - tamanho.y,
				tamanho.x, tamanho.y)
		"norte":
			return Rect2(l.get_center().x - tamanho.x / 2.0 + desloca, l.position.y + recuo,
				tamanho.x, tamanho.y)
		"leste":
			return Rect2(l.end.x - recuo - tamanho.x, l.get_center().y - tamanho.y / 2.0 + desloca,
				tamanho.x, tamanho.y)
		_:
			return Rect2(l.position.x + recuo, l.get_center().y - tamanho.y / 2.0 + desloca,
				tamanho.x, tamanho.y)  # oeste
