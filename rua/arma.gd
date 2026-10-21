extends Node2D
## A arma na mao do jogador. **Ela existe para comprar tempo para o vasculho**,
## e nao para virar um jogo de tiro.
##
## Tres regras a mantem dentro da core mechanic em vez de competindo com ela:
##
##  1. **voce comeca armado** (30/09/2026, regra do Joao - ate aqui a arma
##     estava na armaria da delegacia e achar a arma era recompensa de
##     vasculhar). A Beretta nao e loot: e o que voce tem desde o primeiro dia,
##     com um pente;
##  2. **as balas vem do vasculho**, e so delas. Toda gaveta, caixa e geladeira
##     do mapa pode render uma caixinha de balas, e nao ha outra fonte. Atirar
##     gasta o que voce vasculhou;
##  3. **o tiro chama a horda**, e num raio muito maior que o chamado de um
##     zumbi que enxergou voce (900 contra 350 px na Beretta). O tiro resolve
##     um problema e cria um maior - e a regra do PZ, e e o que faz a arma
##     continuar sendo pressao sobre a mesma acao.
##
## Ela **nao** mata de um tiro desde 03/10/2026: o Joao pediu que o zumbi tenha
## vida ("sofrendo dano e morrendo"). Cada projetil tira `dano` da vida dele
## (zumbi.gd, VIDA_CHEIA). **Vida e dano se contam em unidade de vida, nao em
## balas** (regra dele, 05/10/2026): a vida e 100 e a Beretta tira 20, o que
## da cinco tiros "por enquanto" - cada arma tem o seu dano. Ate 03/10 a regra
## era matar de uma vez, com o argumento de que um zumbi que aguenta varios
## tiros so multiplica o estrondo; o argumento continua valendo como custo:
## cinco tiros sao cinco estrondos e cinco balas, e o pente de 15 derruba tres.
##
## O High Concept declara que "o jogador luta ou esquiva dos zumbis" - esta e a
## parte da luta. A esquiva nao e mecanica: e andar evitando, que sempre deu
## para fazer porque o zumbi e mais lento que voce.
##
## ## As oito armas (05/10/2026)
##
## O Joao fechou a lista: curtas **Revolver 38** e **Beretta 9mm**; escopetas
## **Doze 2 canos** e **Benelli semiauto**; submetralhadoras **CTT40** e
## **Fireagle 9mm**; fuzis **Fall** e **M4**. Por isso este no e generico: a
## ficha de cada uma esta em ARMAS, e qual esta na mao e `Travessia.arma`.
## **So a lista e dele - os numeros das fichas sao proposta minha**, para as
## oito existirem e darem para sentir; ele calibra. **A municao e por calibre**
## (05/10: "faz um tipo de municao pra cada"): `municao` na ficha e o calibre,
## os nomes estao em Construcao.MUNICOES, e `Travessia.municao` le e gasta as
## balas do calibre da arma na mao. O que ainda nao foi decidido: como se
## consegue outra arma (hoje `Q` troca, auxilio de prototipo) e a raridade de
## cada calibre no vasculho (hoje peso igual).
##
## ## A arma na mao (05/10/2026)
##
## O Joao pediu "uma versao dele com a arma na mao", sem gerar nada. A arma nao
## esta desenhada no boneco: e o `Sprite2D` filho deste no (`Desenho`), com o
## PNG de `rua/arte/armas/<desenho>.png` da ficha - desenhados em pixel, a mao
## (design/desenhar_armas.js). Este script o poe na mao e aponta para
## onde o jogador olha (`apontar`). Apontada para a esquerda, a arma e
## espelhada no eixo y para o cabo continuar para baixo; apontada para longe da
## camera, o jogador a poe atras do corpo. Trocar de arma e trocar a ficha; o
## boneco nao muda e nao custa geracao.

## So para a guarda do `aberta`: nao se atira com a mochila aberta.
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")

## A ficha de cada arma. `dano` e por projetil, em unidade de vida;
## `projeteis` e quantos saem por tiro (a escopeta espalha os dela em
## `abertura` graus; com um projetil so, `abertura` e o quanto o tiro pode
## desviar); `espera` e o intervalo entre tiros; `automatica` e segurar para
## atirar (senao, um tiro por clique); `alcance` e ate onde o tiro vai e
## `estrondo` ate onde se ouve (so os fuzis sao automaticos: a CTT40 e a
## Fire Eagle sao carabinas semiautomaticas na vida real - a metralhadora da
## Taurus e a SMT40 -, e o Joao mandou seguir o real, 05/10/2026); `municao` e
## o calibre (Construcao.MUNICOES);
## `desenho` e o PNG em rua/arte/armas/, `mao` o pixel do cabo que fica na
## mao, `cano` a distancia da mao a boca do cano, e `coice` quanto ela recua
## no tiro. **Numeros: proposta de 05/10/2026.** `alcance` e `estrondo` cairam
## pela metade em 20/10/2026, junto com o boneco e o zoom 2 da camera (decisao
## do Joao): na tela o tiro vai e se ouve ate onde ia antes.
const ARMAS := {
	"Revólver 38": {
		"classe": "curta", "dano": 25.0, "projeteis": 1, "abertura": 0.0,
		"espera": 0.6, "automatica": false, "alcance": 400.0, "estrondo": 850.0,
		"municao": ".38", "desenho": "revolver-38", "mao": Vector2(1.0, 5.0), "cano": 10.0, "coice": 3.0,
	},
	"Beretta 9mm": {
		"classe": "curta", "dano": 20.0, "projeteis": 1, "abertura": 0.0,
		"espera": 0.45, "automatica": false, "alcance": 450.0, "estrondo": 900.0,
		"municao": "9mm", "desenho": "beretta-9mm", "mao": Vector2(2.0, 4.0), "cano": 10.0, "coice": 3.0,
	},
	"Doze 2 canos": {
		"classe": "escopeta", "dano": 12.0, "projeteis": 6, "abertura": 16.0,
		"espera": 1.2, "automatica": false, "alcance": 225.0, "estrondo": 1100.0,
		"municao": "12", "desenho": "doze-2-canos", "mao": Vector2(9.0, 4.0), "cano": 16.0, "coice": 6.0,
	},
	"Benelli semiauto": {
		"classe": "escopeta", "dano": 10.0, "projeteis": 6, "abertura": 14.0,
		"espera": 0.6, "automatica": false, "alcance": 225.0, "estrondo": 1100.0,
		"municao": "12", "desenho": "benelli-semiauto", "mao": Vector2(9.0, 4.0), "cano": 16.0, "coice": 5.0,
	},
	"CTT40": {
		"classe": "submetralhadora", "dano": 14.0, "projeteis": 1, "abertura": 4.0,
		"espera": 0.09, "automatica": false, "alcance": 375.0, "estrondo": 950.0,
		"municao": ".40", "desenho": "ctt40", "mao": Vector2(1.0, 5.0), "cano": 14.0, "coice": 2.0,
	},
	"Fireagle 9mm": {
		"classe": "submetralhadora", "dano": 12.0, "projeteis": 1, "abertura": 5.0,
		"espera": 0.07, "automatica": false, "alcance": 375.0, "estrondo": 950.0,
		"municao": "9mm", "desenho": "fireagle-9mm", "mao": Vector2(1.0, 5.0), "cano": 16.0, "coice": 2.0,
	},
	"Fall": {
		"classe": "fuzil", "dano": 45.0, "projeteis": 1, "abertura": 1.5,
		"espera": 0.3, "automatica": true, "alcance": 700.0, "estrondo": 1300.0,
		"municao": "7,62", "desenho": "fall", "mao": Vector2(9.0, 4.0), "cano": 20.0, "coice": 4.0,
	},
	"M4": {
		"classe": "fuzil", "dano": 30.0, "projeteis": 1, "abertura": 2.0,
		"espera": 0.11, "automatica": true, "alcance": 650.0, "estrondo": 1250.0,
		"municao": "5,56", "desenho": "m4", "mao": Vector2(8.0, 4.0), "cano": 19.0, "coice": 3.0,
	},
}

## A ordem em que `Q` passa pelas armas (auxilio de prototipo): a da lista do
## Joao.
const ORDEM := ["Revólver 38", "Beretta 9mm", "Doze 2 canos", "Benelli semiauto",
	"CTT40", "Fireagle 9mm", "Fall", "M4"]

const PASTA_DOS_DESENHOS := "res://rua/arte/armas/"

## Quanto tempo o cano fica aceso na tela depois do tiro.
const CLARAO := 0.09

## Onde fica a mao que segura a arma, em px a partir do centro do jogador (o
## pe esta em +20 e a cabeca em -58): altura da cintura. Em px do desenho: este
## no tem a escala do boneco (jogador.gd), entao no mundo tudo aqui e metade.
const MAO := Vector2(0.0, -18.0)
## Quanto a arma avanca da mao na direcao em que ele olha, e quanto o avanco
## vertical se achata pela perspectiva do high top-down.
const BRACO := 12.0
const ACHATAMENTO := 0.5
## O coice volta em ESPERA_DO_COICE segundos.
const ESPERA_DO_COICE := 0.08

const COR_DA_MIRA := Color(0.85, 0.35, 0.3, 0.22)
const COR_DO_CLARAO := Color(1.0, 0.92, 0.62, 0.85)

## Emitido a cada disparo, com a direcao do tiro. O jogador escuta para o
## boneco reagir (pose de tiro ou recuo).
signal atirou(direcao: Vector2)

## Emitido ao trocar de arma, com o nome da nova.
signal trocou(nome: String)

## A linha de mira e auxilio de prototipo; a conferencia de arte desliga so
## ela, para a figura sair limpa e com a arma.
var mostrar_a_mira := true

var _espera := 0.0
var _clarao := 0.0
var _coice := 0.0
var _mira := Vector2.RIGHT
## Para onde a arma esta apontada (ver `apontar`).
var _apontada := Vector2.DOWN

@onready var _desenho: Sprite2D = $Desenho

func _ready() -> void:
	trocar(Travessia.arma)

func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	if _clarao > 0.0:
		_clarao = maxf(0.0, _clarao - delta)
		queue_redraw()
	if _coice > 0.0:
		_coice = maxf(0.0, _coice - float(ficha()["coice"]) / ESPERA_DO_COICE * delta)
		apontar(_apontada)

	var para_o_mouse := get_global_mouse_position() - global_position
	if para_o_mouse.length() > 1.0:
		_mira = para_o_mouse.normalized()
	queue_redraw()

	# Com a mochila aberta ele esta com as duas maos no saco, nao no gatilho.
	if TelaDaMochila.aberta:
		return

	# Automatica atira enquanto o botao esta apertado; as outras, um tiro por
	# clique - a espera entre tiros vale para as duas.
	var quer_atirar: bool = Input.is_action_pressed("atirar") if ficha()["automatica"] \
		else Input.is_action_just_pressed("atirar")
	if quer_atirar and _espera <= 0.0 and Travessia.municao > 0:
		_atirar()

## `Q` passa para a proxima arma da lista. **Auxilio de prototipo**: como se
## consegue uma arma no jogo ainda nao foi decidido, e sem isto nao da para
## sentir as oito.
func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo or tecla.keycode != KEY_Q:
		return
	if TelaDaMochila.aberta:
		return
	var i := ORDEM.find(Travessia.arma)
	trocar(ORDEM[(i + 1) % ORDEM.size()])

## A ficha da arma na mao.
func ficha() -> Dictionary:
	return ARMAS[Travessia.arma]

## Poe `nome` na mao: muda o `Travessia.arma`, carrega o desenho e poe o pixel
## do cabo (`mao`) no pivo, que e em volta do que o sprite gira.
func trocar(nome: String) -> void:
	if not nome in ARMAS:
		push_error("arma: nao existe \"%s\"; fica a %s" % [nome, Travessia.ARMA_DE_COMECO])
		nome = Travessia.ARMA_DE_COMECO
	Travessia.arma = nome
	var f: Dictionary = ARMAS[nome]
	_desenho.texture = load(PASTA_DOS_DESENHOS + f["desenho"] + ".png") as Texture2D
	if _desenho.texture == null:
		push_error("arma: nao achei o desenho de %s em %s" % [nome, PASTA_DOS_DESENHOS])
	_desenho.centered = false
	_desenho.offset = -(f["mao"] as Vector2)
	apontar(_apontada)
	queue_redraw()
	trocou.emit(nome)

func _atirar() -> void:
	# A guarda mora aqui, e nao so no _process: a ferramenta de conferencia
	# chama isto direto, e sem a guarda a municao ia para negativo. Regra que
	# vive so em quem chama e regra que um chamador novo esquece.
	if Travessia.municao <= 0:
		return

	var f := ficha()
	_espera = f["espera"]
	_clarao = CLARAO
	_coice = f["coice"]
	Travessia.municao -= 1
	# A arma ja aponta para onde a bala vai, para o clarao sair do cano certo.
	apontar(_mira)

	var de := global_position
	# So o jogador sai da conta. Parede, movel e zumbi entram - e o primeiro
	# que aparecer e o que leva.
	var excluir: Array[RID] = []
	var jogador := get_parent() as CollisionObject2D
	if jogador != null:
		excluir.append(jogador.get_rid())

	# Cada projetil e um raio. A escopeta espalha os dela por igual dentro da
	# abertura; uma arma de um projetil com abertura desvia ao acaso.
	var quantos: int = f["projeteis"]
	var abertura := deg_to_rad(float(f["abertura"]))
	for i in quantos:
		var desvio := 0.0
		if quantos > 1:
			desvio = -abertura / 2.0 + abertura * (float(i) + 0.5) / float(quantos)
		elif abertura > 0.0:
			desvio = randf_range(-abertura / 2.0, abertura / 2.0)
		var direcao := _mira.rotated(desvio)
		var consulta := PhysicsRayQueryParameters2D.create(de, de + direcao * float(f["alcance"]))
		consulta.exclude = excluir
		var batida := get_world_2d().direct_space_state.intersect_ray(consulta)
		if not batida.is_empty() and (batida["collider"] as Node).is_in_group("zumbi"):
			(batida["collider"] as Node).levar_tiro(float(f["dano"]), direcao)

	# O estrondo sai de qualquer jeito, acertando ou nao. Errar o tiro e o pior
	# resultado possivel: gastou municao e chamou todo mundo.
	_o_estrondo_chama()
	atirou.emit(_mira)

func _o_estrondo_chama() -> void:
	# A arma conhece o grupo "zumbi" de proposito: o trabalho dela e sobre
	# eles. O que ela NAO faz e saber onde eles estao - ela grita, e quem estiver
	# perto vem, pelo mesmo `foi_chamado` que um zumbi usa para chamar outro.
	var estrondo := float(ficha()["estrondo"])
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		if global_position.distance_to((zumbi as Node2D).global_position) > estrondo:
			continue
		zumbi.foi_chamado(global_position)

## Poe a arma na mao, apontada para `direcao` - chamado pelo jogador a cada
## quadro de fisica com a direcao em que ele olha, e pelo tiro com a mira. O
## sprite gira em volta da mao (o pivo e o cabo) e, virado para a esquerda, e
## espelhado no eixo y para o cabo continuar para baixo. O coice a puxa de
## volta pelo cano.
func apontar(direcao: Vector2) -> void:
	if direcao.length_squared() < 0.0001:
		return
	_apontada = direcao.normalized()
	_desenho.position = MAO + Vector2(_apontada.x, _apontada.y * ACHATAMENTO) * BRACO - _apontada * _coice
	_desenho.rotation = _apontada.angle()
	_desenho.scale = Vector2(1.0, -1.0 if _apontada.x < 0.0 else 1.0)

## A linha de mira e o clarao do cano. A linha e **auxilio de prototipo**, como
## o cone de visao do zumbi: sem ver para onde a arma aponta nao da para
## entender por que o tiro pegou na parede. O clarao sai da boca do cano do
## sprite. O comprimento divide pela escala do no: o raio do tiro e em px de
## mundo, e a linha tem que parar onde ele para.
func _draw() -> void:
	if mostrar_a_mira and Travessia.municao > 0:
		draw_line(Vector2.ZERO, _mira * float(ficha()["alcance"]) / scale.x, COR_DA_MIRA, 2.0)
	if _clarao > 0.0:
		draw_circle(_desenho.position + _apontada * (float(ficha()["cano"]) + 3.0), 6.0, COR_DO_CLARAO)
