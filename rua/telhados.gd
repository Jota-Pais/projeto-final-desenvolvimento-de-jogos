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
## so que agora com a porta de verdade. Desde o Y-sort (14/10/2026) a ordem da
## arvore nao basta: este no tem `z_index = 1` para ficar por cima do que se
## ordena, e a EntradaDeCasa tem `z_index = 2` no rua.tscn pelo mesmo motivo.
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

## As texturas do telhado por cor do predio no desenho (decidido pelo Joao em
## 14/10/2026): vermelho = telha (casas), marrom = zinco (galpao, comercio,
## posto), cinza = laje (delegacia, hospital, bombeiros). A sua casa e telha.
## Desenhadas por regra em design/desenhar_texturas.js, como piso e parede.
const TEXTURA_POR_CLASSE := {
	"vermelho": preload("res://rua/arte/predios/telha.png"),
	"marrom": preload("res://rua/arte/predios/zinco.png"),
	"cinza": preload("res://rua/arte/predios/laje.png"),
}
const TEXTURA_SUA := preload("res://rua/arte/predios/telha.png")
## Porta e janela, vistas de cima, na linha da fachada: a porta onde a marca
## sempre esteve, e as janelas a cada ESPACO_DAS_JANELAS px ao longo da
## fachada, pulando a porta (Joao, 14/10: "tem que ter janelas nos predios").
## O desenho do mapa nao marca janela, entao a posicao e regra.
const PORTA := preload("res://rua/arte/predios/porta.png")
const JANELA := preload("res://rua/arte/predios/janela.png")
const ESPACO_DAS_JANELAS := 72.0
## Nada de janela a menos que isto da porta, nem do canto do predio.
const FOLGA_DA_PORTA := 44.0
const FOLGA_DO_CANTO := 24.0
## A sua casa tinge a porta de quente, como a marca antiga fazia.
const TINTA_DA_PORTA_SUA := Color(1.25, 1.05, 0.8)
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
	var classe: String = construcao.get("classe", "")
	var textura: Texture2D = TEXTURA_SUA if sua else TEXTURA_POR_CLASSE.get(classe, TEXTURA_POR_CLASSE["marrom"])
	draw_texture_rect(textura, r, true)

	# Duas aguas e beiral, para o telhado nao ser um retangulo chapado e dar
	# para distinguir uma construcao da outra de longe. A laje nao tem
	# cumeeira.
	if classe != "cinza" or sua:
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y / 2.0), COR_AGUA)
		draw_line(Vector2(r.position.x, r.position.y + r.size.y / 2.0),
			Vector2(r.end.x, r.position.y + r.size.y / 2.0), COR_BEIRAL, 2.0)
	draw_rect(r, COR_BEIRAL, false, 3.0)

	# A porta e as janelas ficam POR CIMA do telhado, na linha da fachada: de
	# fora nao se ve nada da planta, mas tem que dar para achar por onde
	# entrar, e a fachada e o que diz que ali mora gente.
	_desenhar_a_fachada(construcao, sua)

	var nome: String = construcao.get("nome", "")
	if nome == "" or r.size.x < LARGURA_MINIMA_PARA_O_NOME:
		return
	_desenhar_o_nome(r, nome)

## A porta no centro do vao, girada para a orientacao da fachada, e as
## janelas dos dois lados dela, a cada ESPACO_DAS_JANELAS px, sem invadir a
## folga da porta nem os cantos. `porta_de` e `eixo_da_fachada` ja sabem a
## orientacao; o resto e andar ao longo do eixo.
func _desenhar_a_fachada(construcao: Dictionary, sua: bool) -> void:
	var centro := Construcao.porta_de(construcao)
	var eixo := Construcao.eixo_da_fachada(construcao)
	var angulo := eixo.angle()
	var frente := Construcao.frente_de(construcao)
	# A porta esta a 35 % da frente (ver Construcao.paredes_externas): dali
	# ate os dois cantos.
	var ate_o_comeco := frente * 0.35
	var ate_o_fim := frente - ate_o_comeco

	draw_set_transform(centro, angulo, Vector2.ONE)
	draw_texture(PORTA, -PORTA.get_size() / 2.0, TINTA_DA_PORTA_SUA if sua else Color.WHITE)
	var t := FOLGA_DA_PORTA + JANELA.get_width() / 2.0
	while t < ate_o_fim - FOLGA_DO_CANTO:
		draw_texture(JANELA, Vector2(t, 0.0) - JANELA.get_size() / 2.0)
		t += ESPACO_DAS_JANELAS
	t = -(FOLGA_DA_PORTA + JANELA.get_width() / 2.0)
	while t > -(ate_o_comeco - FOLGA_DO_CANTO):
		draw_texture(JANELA, Vector2(t, 0.0) - JANELA.get_size() / 2.0)
		t -= ESPACO_DAS_JANELAS
	draw_set_transform(Vector2.ZERO)

func _desenhar_o_nome(r: Rect2, nome: String) -> void:
	var fonte := ThemeDB.fallback_font
	var corpo := 13
	# Nome maior que o telhado e cortado, nao estourado para fora dele.
	var largura := fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	while largura > r.size.x - 16.0 and nome.length() > 4:
		nome = nome.substr(0, nome.length() - 2) + "…"
		largura = fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	draw_string(fonte, Vector2(r.position.x + 8.0, r.position.y + 18.0), nome,
		HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, COR_DO_NOME)
