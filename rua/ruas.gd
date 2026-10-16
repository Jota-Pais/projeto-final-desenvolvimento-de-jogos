extends Node2D
## As calcadas, as ruas e o que fica dentro delas, desenhados como POLIGONOS
## com textura por cima do TileMap do chao (15/10/2026).
##
## Em tile de 32 px toda diagonal vira escada: o Wang de quatro cantos so
## sabe reta e quina, e as ruas em diagonal do desenho saiam "todas tortas"
## (Joao, 15/10). O chao feito pelo homem - calcada, rua e os lotes de grama
## de dentro delas - tem borda reta na vida real, entao sai daqui como
## poligono de traco reto (o tracador alisa essas classes com tolerancia
## maior) pintado com o ladrilho do tile cheio (design/ladrilhar_cheio.gd),
## e com um meio-fio escuro na borda. O TileMap continua com o que e natural
## (grama, mata, terra, milho, agua, horta), onde a borda em curva do tile
## cai bem; por baixo das ruas ele tem grama, que nao aparece.
##
## Ordem de pintura, do maior para o menor: primeiro as ruas e calcadas,
## depois qualquer outro poligono de chao cujo centro caia dentro de uma
## delas (o lote de grama no meio do bairro, o jardim da praca), com o
## ladrilho da classe dele. Os furos nao sao recortados: o que esta num furo
## ou e um desses poligonos de dentro (pintado por cima), ou e predio (o piso
## e o telhado cobrem), ou era um carro, que o tracador ja tampou. Fica antes
## do Cenario no rua.tscn, fora do Y-sort, como o Chao.

const Mapa := preload("res://rua/mapa.gd")

const PASTA := "res://rua/arte/chao/"
## As classes que saem como poligono em vez de tile (a mesma lista do
## design/rasterizar_chao.js, que as tira do TileMap).
const DE_POLIGONO := ["pavimento", "asfalto"]
## O gramado usa o tile da grama (proposta aceita em 14/10/2026).
const LADRILHO_DA_CLASSE := { "gramado": "grama" }
const COR_DO_MEIO_FIO := Color(0.0, 0.0, 0.0, 0.35)
const LARGURA_DO_MEIO_FIO := 2.0

var _ladrilhos := {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _draw() -> void:
	var poligonos: Array = Mapa.mundo()["poligonos"]
	var ruas: Array = []
	for p in poligonos:
		if p["classe"] in DE_POLIGONO:
			ruas.append(p)
	var de_dentro: Array = []
	for p in poligonos:
		if p["classe"] in DE_POLIGONO:
			continue
		var centro := _centro(p["pontos"])
		for rua in ruas:
			if Geometry2D.is_point_in_polygon(centro, rua["pontos"]):
				de_dentro.append(p)
				break
	ruas.sort_custom(_maior_primeiro)
	de_dentro.sort_custom(_maior_primeiro)
	for p in ruas + de_dentro:
		_pintar(p)

func _pintar(poligono: Dictionary) -> void:
	var pontos: PackedVector2Array = poligono["pontos"]
	if pontos.size() < 3:
		return
	var ladrilho := _ladrilho_de(poligono["classe"])
	if ladrilho != null:
		var uvs := PackedVector2Array()
		var tamanho := ladrilho.get_size()
		for q in pontos:
			uvs.append(q / tamanho)
		draw_polygon(pontos, PackedColorArray([Color.WHITE]), uvs, ladrilho)
	var fechado := PackedVector2Array(pontos)
	fechado.append(pontos[0])
	draw_polyline(fechado, COR_DO_MEIO_FIO, LARGURA_DO_MEIO_FIO)

## O ladrilho da classe (cheio-<classe>.png), carregado uma vez; null, com
## aviso, se nao existir - ai o poligono fica so com o meio-fio.
func _ladrilho_de(classe: String) -> Texture2D:
	var nome: String = LADRILHO_DA_CLASSE.get(classe, classe)
	if not _ladrilhos.has(nome):
		var caminho := PASTA + "cheio-" + nome + ".png"
		if ResourceLoader.exists(caminho):
			_ladrilhos[nome] = load(caminho)
		else:
			push_warning("ruas: sem ladrilho para %s (%s)" % [classe, caminho])
			_ladrilhos[nome] = null
	return _ladrilhos[nome]

static func _maior_primeiro(a: Dictionary, b: Dictionary) -> bool:
	return _area(a["pontos"]) > _area(b["pontos"])

static func _area(pontos: PackedVector2Array) -> float:
	var soma := 0.0
	for i in pontos.size():
		var p := pontos[i]
		var q := pontos[(i + 1) % pontos.size()]
		soma += p.x * q.y - q.x * p.y
	return absf(soma) / 2.0

static func _centro(pontos: PackedVector2Array) -> Vector2:
	var soma := Vector2.ZERO
	for p in pontos:
		soma += p
	return soma / float(pontos.size())
