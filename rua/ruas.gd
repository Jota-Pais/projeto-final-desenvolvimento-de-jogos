extends Node2D
## As calcadas, as ruas e o que fica dentro delas, desenhados por cima do
## TileMap do chao (15/10/2026; refeito em 21/10/2026).
##
## Em tile de 32 px toda diagonal vira escada: o Wang de quatro cantos so
## sabe reta e quina, e as ruas em diagonal do desenho saiam "todas tortas"
## (Joao, 15/10). O chao feito pelo homem sai daqui; o TileMap continua com o
## que e natural (grama, mata, terra, milho, agua, horta), onde a borda em
## curva do tile cai bem.
##
## **Desde 21/10/2026 a rua e a calcada vem do rua/chao_da_cidade.gd** (o
## design/tracar_ruas.js as refaz do desenho): Joao, "algumas tao meio tortas
## e sem sentido, calcadas nao tao seguindo uma proporcao". A rua tem borda
## reta, largura constante, raio de meio-fio na esquina e rotatoria redonda; a
## calcada tem 2,5 m ao longo de toda rua; e o resto do cinza claro do
## desenho - que la e a cidade em volta, nao calcada - e quintal perto de
## casa, patio cimentado perto de loja e delegacia, terreno baldio no resto.
##
## Ordem de pintura: o chao fora do mapa (a grama que continua depois da
## borda), o cinza claro inteiro de baldio, o resto de cada predio, os
## poligonos de dentro da cidade (o lote de grama, o jardim da praca, com o
## ladrilho da classe), a calcada, a rua e o meio-fio. Fica antes do Cenario
## no rua.tscn, fora do Y-sort, como o Chao.

const Mapa := preload("res://rua/mapa.gd")
const Chao := preload("res://rua/chao_da_cidade.gd")

const PASTA := "res://rua/arte/chao/"
## As classes do desenho que viraram o chao da cidade (a mesma lista do
## design/rasterizar_chao.js, que as tira do TileMap): os poligonos delas nao
## se pintam mais, so dizem quem e poligono de dentro.
const DE_POLIGONO := ["pavimento", "asfalto"]
## O gramado usa o tile da grama (proposta aceita em 14/10/2026).
const LADRILHO_DA_CLASSE := { "gramado": "grama" }
## Os ladrilhos do chao da cidade (design/desenhar_chao_da_cidade.js).
const LADRILHO_DA_CAMADA := {
	"cidade": "cidade-baldio", "baldio": "cidade-baldio", "quintal": "cidade-quintal",
	"patio": "cidade-cimentado", "calcada": "cidade-calcada", "asfalto": "cidade-asfalto",
}
## O meio-fio: a pedra clara do lado da calcada e a sarjeta escura do lado da
## rua.
const COR_DO_MEIO_FIO := Color("8d8a82")
const LARGURA_DO_MEIO_FIO := 5.0
const COR_DA_SARJETA := Color(0.0, 0.0, 0.0, 0.32)
const LARGURA_DA_SARJETA := 3.0
## Quanto o chao continua depois da borda do mapa (a camera da beira nao ve o
## vazio): a mesma margem do design/tracar_ruas.js.
const MARGEM_FORA := 960.0

var _ladrilhos := {}
var _malhas := {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var camadas := Chao.camadas()
	for nome in camadas:
		_malhas[nome] = _malha(camadas[nome])

## Os triangulos de uma camada viram uma malha, com o ladrilho repetido em
## coordenada de mundo (a mesma lajota continua de um triangulo para o outro).
func _malha(camada: Dictionary) -> ArrayMesh:
	var v: PackedVector2Array = camada["v"]
	if v.is_empty():
		return null
	var uvs := PackedVector2Array()
	uvs.resize(v.size())
	for i in v.size():
		uvs[i] = v[i] / 256.0
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = camada["t"]
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha

func _draw() -> void:
	_fora_do_mapa()
	for nome in ["cidade", "baldio", "quintal", "patio"]:
		_pintar_camada(nome)
	_poligonos_de_dentro()
	_pintar_camada("calcada")
	_pintar_camada("asfalto")
	_meio_fio()

func _pintar_camada(nome: String) -> void:
	var malha: ArrayMesh = _malhas.get(nome)
	if malha != null:
		draw_mesh(malha, _ladrilho(LADRILHO_DA_CAMADA[nome]))

## A grama em volta do mapa: a rua que sai pela borda continua por cima dela
## (a malha da rua passa da borda).
func _fora_do_mapa() -> void:
	var grama := _ladrilho("cheio-grama")
	var m := Mapa.MUNDO
	var fora := m.grow(MARGEM_FORA)
	for r in [Rect2(fora.position, Vector2(fora.size.x, MARGEM_FORA)),
			Rect2(Vector2(fora.position.x, m.end.y), Vector2(fora.size.x, MARGEM_FORA)),
			Rect2(Vector2(fora.position.x, m.position.y), Vector2(MARGEM_FORA, m.size.y)),
			Rect2(Vector2(m.end.x, m.position.y), Vector2(MARGEM_FORA, m.size.y))]:
		draw_texture_rect(grama, r, true)

## Os poligonos de chao do desenho que ficam dentro da cidade (o lote de
## grama, o jardim da praca), com o ladrilho da classe, do maior para o menor.
func _poligonos_de_dentro() -> void:
	var poligonos: Array = Mapa.mundo()["poligonos"]
	var cidade: Array = []
	for p in poligonos:
		if p["classe"] in DE_POLIGONO:
			cidade.append(p)
	var de_dentro: Array = []
	for p in poligonos:
		if p["classe"] in DE_POLIGONO:
			continue
		var centro := _centro(p["pontos"])
		for c in cidade:
			if Geometry2D.is_point_in_polygon(centro, c["pontos"]):
				de_dentro.append(p)
				break
	de_dentro.sort_custom(_maior_primeiro)
	for p in de_dentro:
		var pontos: PackedVector2Array = p["pontos"]
		if pontos.size() < 3:
			continue
		var ladrilho := _ladrilho("cheio-" + LADRILHO_DA_CLASSE.get(p["classe"], p["classe"]))
		var uvs := PackedVector2Array()
		for q in pontos:
			uvs.append(q / 256.0)
		draw_polygon(pontos, PackedColorArray([Color.WHITE]), uvs, ladrilho)

## O meio-fio em toda a borda da rua: a sarjeta escura do lado da rua e a
## pedra clara do lado de fora.
func _meio_fio() -> void:
	for anel in Chao.meio_fio():
		var pedra := _deslocado(anel, -(LARGURA_DO_MEIO_FIO / 2.0))
		var sarjeta := _deslocado(anel, LARGURA_DA_SARJETA / 2.0)
		pedra.append(pedra[0])
		sarjeta.append(sarjeta[0])
		draw_polyline(sarjeta, COR_DA_SARJETA, LARGURA_DA_SARJETA)
		draw_polyline(pedra, COR_DO_MEIO_FIO, LARGURA_DO_MEIO_FIO)

## O anel deslocado `quanto` px para o lado da rua (negativo: para fora).
static func _deslocado(anel: PackedVector2Array, quanto: float) -> PackedVector2Array:
	var fora := PackedVector2Array()
	var n := anel.size()
	for i in n:
		var a := anel[(i - 1 + n) % n]
		var b := anel[i]
		var c := anel[(i + 1) % n]
		var n1 := Vector2(-(b - a).y, (b - a).x).normalized()
		var n2 := Vector2(-(c - b).y, (c - b).x).normalized()
		var normal := (n1 + n2).normalized() if (n1 + n2).length() > 0.01 else n1
		fora.append(b + normal * quanto)
	return fora

## O ladrilho pelo nome do arquivo (sem .png), carregado uma vez; null, com
## aviso, se nao existir.
func _ladrilho(nome: String) -> Texture2D:
	if not _ladrilhos.has(nome):
		var caminho := PASTA + nome + ".png"
		if ResourceLoader.exists(caminho):
			_ladrilhos[nome] = load(caminho)
		else:
			push_warning("ruas: sem ladrilho %s" % caminho)
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
