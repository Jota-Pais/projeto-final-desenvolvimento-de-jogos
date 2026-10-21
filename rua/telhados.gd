extends Node2D
## Os telhados - o que faz cada construcao ser opaca de fora. O telhado da
## construcao onde o jogador esta **sai**, e a planta, os moveis e o que tem
## dentro aparecem.
##
## E o truque do Project Zomboid: entrar numa casa e descobrir o que tem
## dentro, nao ler de fora e escolher. Sem isso, o mapa inteiro se le da rua e
## vasculhar deixa de ser exploracao.
##
## **Desde 21/10/2026 cada construcao e um no** (rua/telhado.gd), com telhado
## de verdade e a fachada sul de frente, filho deste no e irmao do jogador no
## Y-sort: quem passa na frente de uma casa aparece na frente da fachada dela,
## e quem esta atras fica atras. Este no so cria os telhados e as coberturas
## (rua/cobertura.gd: varanda, garagem, toldo) e esconde o telhado de quem
## entrou. Antes era um no so, desenhando tudo por cima de tudo (`z_index = 1`).
##
## A EntradaDeCasa continua vindo depois com `z_index = 2` no rua.tscn: a barra
## de E e o aviso da porta de casa nao podem sumir atras da varanda.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")
const Arquitetura := preload("res://rua/arquitetura.gd")
const Telhado := preload("res://rua/telhado.gd")
const Cobertura := preload("res://rua/cobertura.gd")
const DetalhesDaRua := preload("res://rua/detalhes_da_rua.gd")
const Fiacao := preload("res://rua/fiacao.gd")

var _dentro_de := -1
var _telhados: Array[Node2D] = []

## Ja no _ready, e nao so no _process: o jogador nasce DENTRO da sua casa, e
## esperar o primeiro _process fazia o telhado dela piscar por um quadro.
func _ready() -> void:
	z_index = 0
	y_sort_enabled = true
	# O chao com detalhe primeiro, na origem: no Y-sort ele fica depois do
	# piso do cenario e antes de tudo que fica de pe. Os fios, no alto.
	add_child(DetalhesDaRua.new())
	add_child(Fiacao.new())
	for construcao in Mapa.mundo()["construcoes"]:
		var telhado := Telhado.new()
		telhado.montar(construcao)
		add_child(telhado)
		_telhados.append(telhado)
		_cobrir(construcao)
	_conferir()

## As coberturas de uma construcao: uma por recorte que pediu uma, e o toldo
## da fachada.
func _cobrir(construcao: Dictionary) -> void:
	var estilo := Arquitetura.estilo_de(construcao)
	var recortes := Construcao.recortes_de(construcao)
	for i in recortes.size():
		var pedido: Dictionary = construcao["recortes"][i]
		var tipo: String = pedido.get("cobertura", "")
		if tipo == "" or tipo == "desabou":
			continue
		var canto: String = pedido["canto"]
		var cobertura := Cobertura.new()
		cobertura.montar(tipo, recortes[i], "norte" if canto.begins_with("nor") else "sul")
		cobertura.telha = estilo["telhado"].get("material", "fibrocimento") if tipo == "varanda" else "fibrocimento"
		if cobertura.telha == "laje":
			cobertura.telha = "fibrocimento"
		cobertura.canto_livre = recortes[i].position + recortes[i].size * (Construcao.CANTOS[canto] as Vector2)
		add_child(cobertura)
	if estilo.has("toldo"):
		# O toldo vai na fachada da porta, que na pizzaria e a norte.
		var toldo: Dictionary = estilo["toldo"]
		var r: Rect2 = construcao["rect"]
		var fundo := float(toldo.get("fundo", 44.0))
		var cobertura := Cobertura.new()
		cobertura.montar("toldo", Rect2(r.position.x + float(toldo["de"]), r.position.y - fundo,
			float(toldo["ate"]) - float(toldo["de"]), fundo), "norte")
		cobertura.listras = toldo.get("listras", [])
		cobertura.texto = toldo.get("texto", "")
		add_child(cobertura)

func _process(_delta: float) -> void:
	_conferir()

func _conferir() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var onde := Mapa.construcao_em(jogador.global_position)
	if onde == _dentro_de:
		return
	if _dentro_de >= 0 and _dentro_de < _telhados.size():
		_telhados[_dentro_de].visible = true
	_dentro_de = onde
	if _dentro_de >= 0 and _dentro_de < _telhados.size():
		_telhados[_dentro_de].visible = false
