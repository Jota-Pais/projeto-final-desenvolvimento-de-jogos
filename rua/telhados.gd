extends Node2D
## Os telhados, desenhados por cima de tudo - e o que faz cada construcao ser
## opaca de fora. O telhado da construcao onde o jogador esta **sai**, e a
## planta, os moveis e o que tem dentro aparecem.
##
## E o truque do Project Zomboid: entrar numa casa e descobrir o que tem
## dentro, nao ler de fora e escolher. Sem isso, o mapa inteiro se le da rua e
## vasculhar deixa de ser exploracao.
##
## Precisa ser um no separado e desenhar depois do cenario, dos moveis e do
## jogador: o Godot desenha na ordem da arvore.
##
## **Uma coisa so vem depois dele, a EntradaDeCasa** (15/09/2026). Desde que a
## porta de casa passou para a fachada, ela e uma coisa que se opera de fora - e
## um telhado por cima dela esconderia a barra de E e o aviso justamente de quem
## esta chegando da rua. E a mesma excecao que a marca da porta abaixo ja fazia,
## so que agora com a porta de verdade.
##
## A HUD vem depois dele no rua.tscn e nao atrapalha - ela e CanvasLayer, tem
## camada propria e nao entra nessa ordem.
##
## **O nome do predio vai escrito no telhado** (30/09/2026): o mapa veio de um
## desenho com rotulo em cada coisa, e num greybox sem arte o nome e a unica
## pista de que aquele bloco cinza e a farmacia e nao o banco. Sai de
## `construcao["nome"]`, que o mapa.gd preenche pelos ROTULOS.

const Mapa := preload("res://rua/mapa.gd")
const Construcao := preload("res://rua/construcao.gd")

const COR_TELHADO := Color("2a2e31")
const COR_TELHADO_SEU := Color("3a2f26")
const COR_BEIRAL := Color(0.0, 0.0, 0.0, 0.45)
const COR_AGUA := Color(0.0, 0.0, 0.0, 0.10)
const COR_DA_PORTA := Color("6b5b3f")
const COR_DA_PORTA_SUA := Color("8a5a2b")
const COR_DO_NOME := Color(0.95, 0.9, 0.8, 0.55)

## Predio mais estreito que isto nao ganha nome escrito: nao caberia.
const LARGURA_MINIMA_PARA_O_NOME := 220.0

var _dentro_de := -1

## Ja no _ready, e nao so no _process: o jogador nasce DENTRO da sua casa, e
## esperar o primeiro _process fazia o telhado dela piscar por um quadro.
func _ready() -> void:
	_conferir()

func _process(_delta: float) -> void:
	_conferir()

func _conferir() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var onde := Mapa.construcao_em(jogador.global_position)
	if onde == _dentro_de:
		return
	_dentro_de = onde
	queue_redraw()

func _draw() -> void:
	for i in Mapa.mundo()["construcoes"].size():
		if i == _dentro_de:
			continue
		_desenhar(Mapa.mundo()["construcoes"][i])

func _desenhar(construcao: Dictionary) -> void:
	var r: Rect2 = construcao["rect"]
	var sua: bool = construcao.get("sua", false)
	# O tom vem da cor que o predio tinha no desenho: o vermelho do desenho
	# (hospital, escola, prisao...) continua lendo como "importante" de longe.
	var tom: Color = COR_TELHADO
	if sua:
		tom = COR_TELHADO_SEU
	elif Mapa.CLASSE_DO_PREDIO.has(construcao.get("classe", "")):
		tom = Mapa.CLASSE_DO_PREDIO[construcao["classe"]]["telhado"]
	draw_rect(r, tom)

	# Duas aguas, so para o telhado nao ser um retangulo chapado e dar para
	# distinguir uma construcao da outra de longe.
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y / 2.0), COR_AGUA)
	draw_line(r.position, Vector2(r.end.x, r.position.y + r.size.y / 2.0), COR_BEIRAL, 2.0)
	draw_rect(r, COR_BEIRAL, false, 3.0)

	# A marca da porta fica POR CIMA do telhado: de fora nao se ve nada da
	# planta, mas tem que dar para achar por onde entrar. `marca_da_porta` ja
	# gira sozinha conforme a orientacao (17/09/2026).
	draw_rect(Construcao.marca_da_porta(construcao), COR_DA_PORTA_SUA if sua else COR_DA_PORTA)

	var nome: String = construcao.get("nome", "")
	if nome == "" or r.size.x < LARGURA_MINIMA_PARA_O_NOME:
		return
	var fonte := ThemeDB.fallback_font
	var corpo := 13
	# Nome maior que o telhado e cortado, nao estourado para fora dele.
	var largura := fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	while largura > r.size.x - 16.0 and nome.length() > 4:
		nome = nome.substr(0, nome.length() - 2) + "…"
		largura = fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	draw_string(fonte, Vector2(r.position.x + 8.0, r.position.y + 18.0), nome,
		HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, COR_DO_NOME)
