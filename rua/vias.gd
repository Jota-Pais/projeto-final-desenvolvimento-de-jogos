## Vias: o que uma rua e por fora.
##
## `rua/construcao.gd` diz o que e um predio por dentro; este arquivo diz o
## que e uma rua por fora - largura, calcada, faixa central, e como ela se
## liga as outras. Biblioteca estatica, sem estado: so `mapa.gd`, `lugares.gd`
## e `conferir_mapa.gd` a carregam.
##
## ## Por que existe (17/09/2026, arquitetura nova do mapa)
##
## Ate esta data uma rua era um `Rect2` solto numa lista (`mundo()["ruas"]`),
## sem nome, sem classe e sem ponta: nao dava para perguntar "essa rua termina
## em algum lugar de verdade?" nem "que faixa de calcada essa classe de via
## tem?" sem reescrever a pergunta a mao toda vez. Agora uma via e um registro
## com **nome** (a identidade - ferramenta acha por nome, nunca por indice nem
## por coordenada), **classe** (de onde saem largura e regra de desenho) e
## **eixo** (2 pontos para via reta, 3+ para polilinha fora da cidade).
##
## ## As classes finais da arquitetura nova (17/09/2026 - P7). Ate P6 esta
## tabela usava os numeros de HOJE (o mapa antigo, 400 px de rua uniforme,
## sem distincao); a partir daqui os numeros sao os do PZ de verdade (1 tile
## = 40 px): rodovia 16 t (KY-60/Dixie); Main Street 15 t no trecho comercial,
## 8 t no resto; residencial 8 t e SEM calcada nem faixa central - nenhuma
## das quatro cidades de spawn do PZ tem; beco 4 t; laco de fim de rua 5 t.
##
## `recuo` (Vector2 minimo/maximo, P5) e `grama` (faixa verde entre calcada e
## pista, so onde ha calcada) alimentam `quadras.gd`.
## `clareira` (P10): a folga sem arvore ao lado da faixa, ALEM da propria
## faixa/calcada/grama - o anel de verdade do criterio G, maior na rodovia
## (onde uma arvore bem na beira esconderia o proprio asfalto de longe) que
## no beco (que e pra sentir apertado). So vale para via RETA - `aberto_de`
## usa 0 para via poligonal, que ja usa a fila pintada como area livre.
const CLASSES := {
	"rodovia": {
		"largura": 640.0, "minima": 560.0, "maxima": 800.0,
		"calcada": 0.0, "grama": 0.0, "faixa": true, "sujeira": true, "lote": false,
		"recuo": Vector2(400.0, 800.0), "clareira": 240.0,
	},
	# O trecho alargado da Avenida Central, com a fita comercial - unica
	# classe de rua da cidade com calcada, porque e a unica com loja.
	"comercial": {
		"largura": 600.0, "minima": 520.0, "maxima": 720.0,
		"calcada": 120.0, "grama": 80.0, "faixa": true, "sujeira": false, "lote": true,
		"recuo": Vector2(240.0, 720.0), "clareira": 160.0,
	},
	# O resto da Avenida Central e a Rua do Bairro (a unica do loteamento com
	# calcada - ela carrega o comercio de esquina, e no PZ e assim que se
	# decide qual rua de bairro merece passeio).
	"principal": {
		"largura": 320.0, "minima": 280.0, "maxima": 400.0,
		"calcada": 120.0, "grama": 80.0, "faixa": true, "sujeira": false, "lote": true,
		"recuo": Vector2(240.0, 520.0), "clareira": 160.0,
	},
	# Toda rua residencial comum, de bairro ou de cidade - o PZ nao poe
	# calcada nem faixa central nelas fora da rua principal.
	"residencial": {
		"largura": 320.0, "minima": 240.0, "maxima": 400.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(240.0, 520.0), "clareira": 120.0,
	},
	"beco": {
		"largura": 160.0, "minima": 120.0, "maxima": 200.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(120.0, 360.0), "clareira": 60.0,
	},
	# O anel de fim de rua (loop + ilha). A largura do CLASS e so o piso; a
	# largura de verdade de cada laco sai da via que ele fecha e fica
	# gravada em `largura` (ver `Vias.laco`) - por isso minima/maxima cobrem
	# residencial e principal, as duas classes que hoje terminam em laco.
	"laco": {
		"largura": 200.0, "minima": 160.0, "maxima": 400.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(200.0, 400.0), "clareira": 120.0,
	},
	"rural": {
		"largura": 640.0, "minima": 400.0, "maxima": 800.0,
		"calcada": 0.0, "grama": 0.0, "faixa": true, "sujeira": false, "lote": false,
		"recuo": Vector2(0.0, 0.0), "clareira": 200.0,
	},
	"terra": {
		"largura": 260.0, "minima": 200.0, "maxima": 320.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(160.0, 620.0), "clareira": 80.0,
	},
	# As duas que fecham os criterios A e B sem clausula de excecao: a loja
	# encara o estacionamento, o galpao do sitio encara o patio, e a estrada
	# de terra termina numa INTERSECCAO com o patio em vez de morrer no
	# talhao. Largura livre (vem do `rect` declarado), sem faixa e sem
	# calcada.
	"estacionamento": {
		"largura": 0.0, "minima": 0.0, "maxima": 0.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(0.0, 240.0), "piso": false, "clareira": 0.0,
	},
	"patio": {
		"largura": 0.0, "minima": 0.0, "maxima": 0.0,
		"calcada": 0.0, "grama": 0.0, "faixa": false, "sujeira": false, "lote": true,
		"recuo": Vector2(0.0, 240.0), "piso": true, "clareira": 0.0,
	},
}

## O registro de uma via, no dicionario do mundo (`mundo()["vias"]`):
##
##  - `nome` (String): a identidade - por ela ferramenta, quadra e legenda
##    acham a via, nunca por indice nem por coordenada;
##  - `classe` (String): chave de CLASSES;
##  - `eixo` (Array[Vector2]): 2 pontos axiais (mesmo x ou mesmo y) para via
##    reta; 3+ pontos para polilinha (`rural`/`terra`, fora da cidade);
##  - `largura` (float, opcional): sobrescreve a da classe;
##  - `rect` (Rect2, opcional): so para vias sem eixo (hoje: `laco`);
##  - `pontas` (Array[String], 2): o TIPO da ponta - "borda", "T:<nome>",
##    "emenda:<nome>", "laco", "u:<nome>" - nao a prova; a prova e o grafo;
##  - `lugar` (String): quem gerou a via (vazio para as de `mapa.gd`).

static func largura_de(via: Dictionary) -> float:
	return via.get("largura", CLASSES[via["classe"]]["largura"])

## O retangulo de asfalto de uma via. Para via de eixo reto (2 pontos): um
## retangulo axial. Para via com `rect` declarado (hoje, so `laco`): o proprio
## rect. Polilinha (3+ pontos) nao tem UM retangulo - `faixa_pintada` devolve a
## fila de quadrados dela.
static func faixa_de(via: Dictionary) -> Rect2:
	if via.has("rect"):
		return via["rect"]
	var eixo: Array = via["eixo"]
	var a: Vector2 = eixo[0]
	var b: Vector2 = eixo[eixo.size() - 1]
	var largura := largura_de(via)
	if eixo.size() == 2 and is_equal_approx(a.y, b.y):
		return Rect2(minf(a.x, b.x), a.y - largura / 2.0, absf(b.x - a.x), largura)
	if eixo.size() == 2 and is_equal_approx(a.x, b.x):
		return Rect2(a.x - largura / 2.0, minf(a.y, b.y), largura, absf(b.y - a.y))
	# Polilinha: o retangulo que envolve todos os pontos, inflado pela
	# largura - serve para checagem grosseira (ex.: "essa ponta esta perto
	# dali?"), nao para desenho nem colisao.
	var envelope := Rect2(a, Vector2.ZERO)
	for p in eixo:
		envelope = envelope.expand(p)
	return envelope.grow(largura / 2.0)

## Se a via resolve para UM retangulo (`rect` declarado, como laco/patio, ou
## `eixo` de 2 pontos) - as que viram `Rect2` de verdade em `mundo()["ruas"]`.
## Polilinha (`eixo` de 3+ pontos, sem `rect`) nao: essa vira fila de
## quadrados (`faixa_pintada`), porque nao ha UM retangulo que a represente.
static func e_reta(via: Dictionary) -> bool:
	return via.has("rect") or (via["eixo"] as Array).size() == 2

## A faixa pintada de uma via poligonal (`rural`/`terra`, fora da cidade):
## uma fila de quadrados que se sobrepoem ao longo da polilinha - o desenho
## fica continuo em qualquer angulo, sem serrilha e sem buraco na curva.
##
## O lado do quadrado sai do angulo de CADA segmento, para o envelope da faixa
## ser `largura` em qualquer angulo: um quadrado de lado fixo cobre uma faixa
## perpendicular de `lado * (|cos t| + |sin t|)`, que a 45 graus engorda 41%.
## Antes disto a estrada torta mudava de largura na curva, e essa era metade
## da queixa "o mapa ta muito reto" - a curva ficava mais larga que a reta.
static func faixa_pintada(via: Dictionary) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	var pontos: Array = via["eixo"]
	var largura := largura_de(via)
	for i in range(1, pontos.size()):
		var de: Vector2 = pontos[i - 1]
		var ate: Vector2 = pontos[i]
		var dir := (ate - de).normalized()
		if dir == Vector2.ZERO:
			continue
		var lado := largura / (absf(dir.x) + absf(dir.y))
		var passo := lado * 0.45
		var quantos := maxi(1, int(ceil(de.distance_to(ate) / passo)))
		for k in quantos + 1:
			var onde := de.lerp(ate, float(k) / float(quantos))
			fora.append(Rect2(onde - Vector2.ONE * lado * 0.5, Vector2.ONE * lado))
	return fora

## A calcada de uma via, de UM lado so - o que `via["calcada"]` declara
## ("norte"/"sul"/"leste"/"oeste") -, so para via reta cuja classe tem
## calcada (`CLASSES[classe].calcada > 0`). Via poligonal e sem calcada por
## definicao (estrada de campo nao tem passeio); via reta de classe com
## calcada mas sem o lado declarado tambem fica sem - a via e que tem que
## dizer de que lado.
##
## **So um lado, nunca dois** (17/09/2026, P7): antes desta correcao a
## funcao dava calcada dos dois lados sempre que a classe tinha `calcada`,
## ignorando o campo `via["calcada"]" por completo - o mesmo bug de sempre,
## "toda entrada de uma lista ganha o mesmo tratamento sem olhar o dado".
static func calcadas_de(via: Dictionary) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	if not e_reta(via):
		return fora
	var calcada: float = CLASSES[via["classe"]]["calcada"]
	var lado: String = via.get("calcada", "")
	if calcada <= 0.0 or lado == "":
		return fora
	var r := faixa_de(via)
	match lado:
		"norte": fora.append(Rect2(r.position.x, r.position.y - calcada, r.size.x, calcada))
		"sul": fora.append(Rect2(r.position.x, r.end.y, r.size.x, calcada))
		"leste": fora.append(Rect2(r.end.x, r.position.y, calcada, r.size.y))
		_: fora.append(Rect2(r.position.x - calcada, r.position.y, calcada, r.size.y))  # oeste
	return fora

## Onde um lote pode comecar, medido a partir do eixo: metade da largura mais
## a calcada, se houver. Ainda nao tem consumidor (chega em P4, com os
## lotes) - existe aqui porque e uma pergunta sobre a VIA, nao sobre o lote.
static func borda_util_de(via: Dictionary, lado: String) -> float:
	var r := faixa_de(via)
	# So soma calcada+grama se ESTE lado e o lado declarado em via["calcada"]
	# - **so um lado tem passeio** (17/09/2026, P8: achado gerando os
	# primeiros predios de fachada norte sobre a Avenida - toda borda_util
	# ganhava a folga da calcada, mesmo do lado sem passeio nenhum, e o
	# recuo do predio somava mais ~120 px do que devia. Mesma familia do bug
	# que `calcadas_de` teve).
	var c := 0.0
	if via.get("calcada", "") == lado:
		var classe: Dictionary = CLASSES[via["classe"]]
		c = classe["calcada"] + classe["grama"]
	match lado:
		"norte": return r.position.y - c
		"sul": return r.end.y + c
		"oeste": return r.position.x - c
		_: return r.end.x + c

## O retangulo da via mais a calcada - so a faixa de asfalto/calcada, sem
## acostamento. Ver `aberto_de` para a faixa que a vegetacao respeita.
static func envelope_de(via: Dictionary) -> Rect2:
	var r := faixa_de(via)
	for c in calcadas_de(via):
		r = r.merge(c)
	return r

## A faixa aberta ao lado de uma via, sem arvore: a FAIXA crua (nao o
## envelope com calcada, que dobraria a folga na rodovia) inflada pela
## `clareira` da classe - maior na rodovia, quase nenhuma no beco (criterio
## G). Via poligonal devolve a propria faixa, sem folga: quem chama ja varre
## a fila de quadrados pintada por fora, que e a area livre de verdade dela.
##
## **Ate 17/09/2026 (P10) a folga era um `120` fixo para toda via reta**,
## a mesma desde a migracao de P3 - a rodovia (16 tiles) e o beco (4 tiles)
## abriam a mesma faixa sem arvore, o que nao fazia sentido lado a lado.
static func aberto_de(via: Dictionary) -> Rect2:
	if not e_reta(via):
		return faixa_de(via)
	var clareira: float = CLASSES[via["classe"]].get("clareira", 120.0)
	return faixa_de(via).grow(clareira)

## Se o trecho `[de, ate]` no eixo dado (0 = x, 1 = y) esta coberto pela via -
## para o criterio "a porta encara uma via que realmente passa ali". So faz
## sentido para via reta.
static func cobre(via: Dictionary, de: float, ate: float, eixo: int) -> bool:
	if not e_reta(via):
		return false
	var r := faixa_de(via)
	if eixo == 0:
		return r.position.x <= de and r.end.x >= ate
	return r.position.y <= de and r.end.y >= ate

## Calcada cortada nos cruzamentos: tira de cada pedaco de calcada o que
## qualquer OUTRA via (o asfalto dela) esconderia por baixo. Sem isto, toda
## esquina ganha um retangulo claro de calcada por cima do asfalto da rua
## transversal.
static func recortar(calcada: Rect2, vias: Array) -> Array[Rect2]:
	var pedacos: Array[Rect2] = [calcada]
	for outra in vias:
		if not (outra as Dictionary).has("eixo") and not (outra as Dictionary).has("rect"):
			continue
		var r := faixa_de(outra)
		if not r.intersects(calcada):
			continue
		var novos: Array[Rect2] = []
		for pedaco in pedacos:
			novos.append_array(_subtrair_rect(pedaco, r))
		pedacos = novos
	return pedacos

## `a` menos `b`, como 0 a 4 retangulos (so funciona bem para cortes axiais,
## que e o unico caso que acontece aqui - calcada e rua sao sempre axiais).
static func _subtrair_rect(a: Rect2, b: Rect2) -> Array[Rect2]:
	if not a.intersects(b):
		var fora: Array[Rect2] = [a]
		return fora
	var pedacos: Array[Rect2] = []
	if b.position.y > a.position.y:
		pedacos.append(Rect2(a.position.x, a.position.y, a.size.x, b.position.y - a.position.y))
	if b.end.y < a.end.y:
		pedacos.append(Rect2(a.position.x, b.end.y, a.size.x, a.end.y - b.end.y))
	var meio_de := maxf(a.position.y, b.position.y)
	var meio_ate := minf(a.end.y, b.end.y)
	if meio_ate > meio_de:
		if b.position.x > a.position.x:
			pedacos.append(Rect2(a.position.x, meio_de, b.position.x - a.position.x, meio_ate - meio_de))
		if b.end.x < a.end.x:
			pedacos.append(Rect2(b.end.x, meio_de, a.end.x - b.end.x, meio_ate - meio_de))
	return pedacos

## Um laco (anel de retorno com ilha) de verdade: 4 vias retas em volta de uma
## ilha central, encostando exatamente nos 4 cantos - cada segmento e axial
## (a v0.1 daqui tinha 8 cantos ligados em diagonal, o que violava a propria
## regra de que via reta e sempre mesmo x ou mesmo y; o `conferir_construcao`
## nao pegaria porque isso e geometria de VIA, nao de predio - achado na
## revisao antes do primeiro uso real, em P7).
##
## A largura de CADA segmento e a `largura` dada (gravada como override, nao
## a da classe "laco" generica) - e essa largura vem da via que o laco fecha
## (residencial ou principal), nunca um numero fixo.
static func laco(centro: Vector2, ilha: Vector2, largura: float, nome: String) -> Array[Dictionary]:
	var meio_ilha := ilha / 2.0
	var y_norte := centro.y - meio_ilha.y - largura / 2.0
	var y_sul := centro.y + meio_ilha.y + largura / 2.0
	var x_oeste := centro.x - meio_ilha.x - largura / 2.0
	var x_leste := centro.x + meio_ilha.x + largura / 2.0
	var ponta := "laco:%s" % nome

	var fora: Array[Dictionary] = []
	fora.append({ "nome": "%s norte" % nome, "classe": "laco", "lugar": nome, "largura": largura,
		"eixo": [Vector2(x_oeste, y_norte), Vector2(x_leste, y_norte)], "pontas": [ponta, ponta] })
	fora.append({ "nome": "%s sul" % nome, "classe": "laco", "lugar": nome, "largura": largura,
		"eixo": [Vector2(x_oeste, y_sul), Vector2(x_leste, y_sul)], "pontas": [ponta, ponta] })
	fora.append({ "nome": "%s leste" % nome, "classe": "laco", "lugar": nome, "largura": largura,
		"eixo": [Vector2(x_leste, y_norte), Vector2(x_leste, y_sul)], "pontas": [ponta, ponta] })
	fora.append({ "nome": "%s oeste" % nome, "classe": "laco", "lugar": nome, "largura": largura,
		"eixo": [Vector2(x_oeste, y_norte), Vector2(x_oeste, y_sul)], "pontas": [ponta, ponta] })
	return fora

## Uma volta em U: liga dois pontos de uma via mae por um terceiro lado, no
## fundo. Ainda sem consumidor - mesmo caso do laco.
static func u(mae: Dictionary, a: Vector2, b: Vector2, fundo: Vector2, nome: String) -> Array[Dictionary]:
	var classe: String = mae["classe"]
	return [
		{ "nome": "%s (a)" % nome, "classe": classe, "eixo": [a, Vector2(a.x, fundo.y)],
			"pontas": ["T:%s" % mae["nome"], "u:%s" % nome] },
		{ "nome": "%s (fundo)" % nome, "classe": classe, "eixo": [Vector2(a.x, fundo.y), Vector2(b.x, fundo.y)],
			"pontas": ["u:%s" % nome, "u:%s" % nome] },
		{ "nome": "%s (b)" % nome, "classe": classe, "eixo": [Vector2(b.x, fundo.y), b],
			"pontas": ["u:%s" % nome, "T:%s" % mae["nome"]] },
	]

# --------------------------------------------------------------------- grafo

## As pontas de uma via: 1 para `rect` (nao tem direcao), 2 para `eixo`
## (primeiro e ultimo ponto - numa polilinha, so as pontas contam para o
## grafo, os pontos do meio sao so desenho).
static func _pontas(via: Dictionary) -> Array[Vector2]:
	if via.has("rect"):
		var r: Rect2 = via["rect"]
		var fora: Array[Vector2] = [r.get_center()]
		return fora
	var eixo: Array = via["eixo"]
	var fora: Array[Vector2] = [eixo[0], eixo[eixo.size() - 1]]
	return fora

const _PERTO := 2.0

## O grafo da rede: `{"nos": {nome_do_no: Vector2}, "grau": {nome_do_no: int},
## "incidencias": {nome_do_no: Array[String]}}`. Nos sao descobertos por
## GEOMETRIA, nao por declaracao: duas pontas a menos de `_PERTO` px sao o
## mesmo no. Uma ponta que cai dentro da `faixa_de` de OUTRA via tambem conta
## como incidente aquela via (a via e um cruzamento em T, mesmo sem a outra
## via "saber" disso) - e o que faz o grau de um no bater com o que se ve no
## mapa, e nao so com o que foi escrito a mao.
static func grafo(vias: Array) -> Dictionary:
	var nos := {}  # nome -> Vector2
	var incidencias := {}  # nome -> Array[String] (nomes de via)

	var pontas_de_cada: Array = []
	for via in vias:
		pontas_de_cada.append(_pontas(via))

	var no_de_ponta := {}  # "%d:%d" (indice da via, indice da ponta) -> nome do no
	var proximo := 0

	for i in vias.size():
		for j in pontas_de_cada[i].size():
			var chave := "%d:%d" % [i, j]
			if no_de_ponta.has(chave):
				continue
			var p: Vector2 = pontas_de_cada[i][j]
			var nome := "no%d" % proximo
			proximo += 1
			nos[nome] = p
			no_de_ponta[chave] = nome
			incidencias[nome] = [(vias[i] as Dictionary)["nome"]]
			# Junta toda outra ponta a menos de _PERTO px - o mesmo no.
			for k in vias.size():
				for l in pontas_de_cada[k].size():
					var outra_chave := "%d:%d" % [k, l]
					if no_de_ponta.has(outra_chave):
						continue
					var q: Vector2 = pontas_de_cada[k][l]
					if q.distance_to(p) <= _PERTO:
						no_de_ponta[outra_chave] = nome
						(incidencias[nome] as Array).append((vias[k] as Dictionary)["nome"])

	# Segunda passada: ponta que caiu dentro da faixa de outra via, OU so
	# encostou na borda dela - a outra via tambem fica incidente aquele no
	# (cruzamento em T, como o mapa de hoje desenha: uma rua que TERMINA
	# exatamente na borda de outra e uma ligacao legitima, nao uma
	# sobreposicao). Por isso `grow(1)`, a doutrina da ADJACENCIA - `grow(-1)`
	# e para sobreposicao, e rejeitaria como "solta" toda rua que so encosta
	# certinho na outra, que e o caso mais comum do mapa de hoje.
	for nome in nos:
		var p: Vector2 = nos[nome]
		for via in vias:
			var nome_via: String = via["nome"]
			if (incidencias[nome] as Array).has(nome_via):
				continue
			if not (via.has("eixo") or via.has("rect")):
				continue
			if faixa_de(via).grow(1.0).has_point(p):
				(incidencias[nome] as Array).append(nome_via)

	# Terceira passada: duas vias retas que se CRUZAM (uma horizontal, uma
	# vertical, feito um "+"), continuando as duas para os dois lados - a
	# Rua do Correio atravessando a Avenida Central, por exemplo. A segunda
	# passada so pega quando a PONTA de uma cai dentro da outra; um
	# cruzamento onde nenhuma das duas termina ali (as duas sao ponto
	# interior para a outra) nao cria no nenhum nas duas primeiras passadas,
	# e passava batido - achado ao ligar a rede da cidade em P7, quando a
	# Avenida Central passou a ser atravessada por quatro verticais no meio
	# do proprio trecho, nao nas pontas.
	for i in vias.size():
		if not e_reta(vias[i]):
			continue
		for j in range(i + 1, vias.size()):
			if not e_reta(vias[j]):
				continue
			var a := faixa_de(vias[i]).grow(1.0)
			var b := faixa_de(vias[j]).grow(1.0)
			if not a.intersects(b):
				continue
			var nome_a: String = (vias[i] as Dictionary)["nome"]
			var nome_b: String = (vias[j] as Dictionary)["nome"]
			var ja_ligadas := false
			for nome in nos:
				if (incidencias[nome] as Array).has(nome_a) and (incidencias[nome] as Array).has(nome_b):
					ja_ligadas = true
					break
			if ja_ligadas:
				continue
			var nome_no := "no%d" % proximo
			proximo += 1
			nos[nome_no] = a.intersection(b).get_center()
			incidencias[nome_no] = [nome_a, nome_b]

	var grau := {}
	for nome in incidencias:
		grau[nome] = (incidencias[nome] as Array).size()

	return { "nos": nos, "grau": grau, "incidencias": incidencias }

## Uma copia da via, deslocada por `origem` - para o lugar que gera em
## coordenada LOCAL (hoje, so o bairro) somar a propria origem, do mesmo jeito
## que ja faz com construcao, cerca e movel.
static func deslocar(via: Dictionary, origem: Vector2) -> Dictionary:
	var copia := via.duplicate(true)
	if copia.has("rect"):
		var r: Rect2 = copia["rect"]
		copia["rect"] = Rect2(r.position + origem, r.size)
	if copia.has("eixo"):
		var novo: Array[Vector2] = []
		for p in (copia["eixo"] as Array):
			novo.append((p as Vector2) + origem)
		copia["eixo"] = novo
	return copia

## Uma via reta a partir de um retangulo axial ja existente (a forma como toda
## rua de bairro/cidade nasceu ate 17/09/2026) - migracao 1:1 para P3: o eixo
## sai do meio do retangulo, e a largura dele vira a da classe (se bater) ou
## fica sobrescrita. Nao serve para `rural`/`terra` (essas ja nascem com o
## eixo poligonal certo) nem para `laco` (que usa `rect`, nao eixo).
static func via_do_rect(nome: String, classe: String, rect: Rect2, lugar: String) -> Dictionary:
	var eixo: Array[Vector2]
	if rect.size.x >= rect.size.y:
		eixo = [Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y)]
	else:
		eixo = [Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y)]
	var largura: float = rect.size.y if rect.size.x >= rect.size.y else rect.size.x
	var via := { "nome": nome, "classe": classe, "eixo": eixo, "lugar": lugar, "pontas": ["", ""] }
	if not is_equal_approx(largura, CLASSES[classe]["largura"]):
		via["largura"] = largura
	return via

## Um ponto sobre o eixo da via, por fracao `t` em [0, 1] do comprimento
## (do primeiro ao ultimo ponto do eixo). Existe para ponto de teste por
## NOME em vez de coordenada crua - chega em P7 com consumidor de verdade.
static func ponto_em(via: Dictionary, t: float) -> Vector2:
	if via.has("rect"):
		return (via["rect"] as Rect2).get_center()
	var eixo: Array = via["eixo"]
	return (eixo[0] as Vector2).lerp(eixo[eixo.size() - 1] as Vector2, clampf(t, 0.0, 1.0))
