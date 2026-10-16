extends TileMapLayer
## O chao da rua em tiles - a primeira camada da arte do mapa (design/arte-rua.md,
## "O mapa inteiro"; decidido pelo Joao em 14/10/2026: tile de 32 px).
##
## O mapa e dado, nao desenho: o tracado do desenho dele vira poligonos por
## classe de chao (grama, pavimento, asfalto, mata...). Ate 14/10 o cenario
## pintava esses poligonos em cinza. Agora `design/rasterizar_chao.js` grava
## a classe de cada VERTICE da grade de 32 px em `rua/chao_tracado.png` (um
## pixel por vertice, o valor e o indice da classe em `rua/chao_tracado.json`),
## e este no escolhe o tile de cada celula pelos quatro cantos dela - o
## sistema Wang do PixelLab: um tileset por par de terrenos, 16 tiles, um para
## cada combinacao de cantos "de baixo"/"de cima".
##
## Os tilesets ficam em `rua/arte/chao/`, listados em `tilesets.json`: cada um
## e o PNG 4x4 mais o JSON de metadados que o PixelLab entrega
## (`/mcp/tilesets/<id>/metadata` e `/image`), com `bounding_box` e `corners`
## por tile. Os provisorios de cor chapada, feitos a mao, provam o caminho ate
## os gerados chegarem - trocar e substituir os dois arquivos.
##
## Nao usa os "terrains" do Godot: com um tileset por par e o raster pronto,
## escolher o tile e uma conta de quatro cantos, e o Godot so desenha.

const RASTER := "res://rua/chao_tracado.png"
const INDICE_DO_RASTER := "res://rua/chao_tracado.json"
const PASTA := "res://rua/arte/chao/"
const INDICE_DOS_TILESETS := PASTA + "tilesets.json"
const TILE := 32

## Classes que, no chao, sao a mesma coisa. **Proposta de 14/10**: o gramado
## (grama cuidada) usa o tileset da grama; tratar como terreno proprio custaria
## mais cinco tilesets so para repetir as transicoes dele. Se a equipe quiser
## os dois tons, tira-se daqui e gera-se o tileset dele.
const MESMA_CLASSE := {"gramado": "grama"}

var _classes: PackedStringArray
var _colunas := 0
var _linhas := 0
var _vertices: PackedByteArray
## "baixo|cima" -> {"fonte": id da fonte no TileSet, "tiles": {indice Wang: coords}}
var _transicoes := {}
## classe -> [fonte, coords] do tile cheio (os quatro cantos iguais)
var _cheios := {}
## classe -> os ids dos tiles alternativos do tile cheio (ver VARIACOES).
var _variantes := {}

## Variacoes do tile cheio, para o chao nao virar grade (regra dos guias de
## tile, 14/10/2026: 3 ou 4 versoes do mesmo tile espalhadas ao acaso; o
## Zomboid faz o mesmo com a grama). Cada entrada e [espelha_x, espelha_y,
## tom]: o tom escurece um pouco para quebrar a uniformidade, e o espelho
## muda o desenho. A escolha por celula e um hash da posicao, entao e a mesma
## a cada abertura.
##
## Espelho so em terreno natural (grama, mata, terra...): a lajota e o asfalto
## tem a junta desenhada numa borda, e virados de cabeca para baixo a junta
## cai do outro lado e dobra com a do vizinho - o "risco escuro embaixo, um
## tile sim, um nao" que o Joao viu em 14/10. Piso duro varia so no tom.
const VARIACOES_NATURAIS := [
	[false, false, 1.0], [true, false, 1.0], [false, true, 0.985], [true, true, 0.985],
	[false, false, 0.97], [true, false, 0.99], [false, true, 1.0], [true, true, 0.975],
]
const VARIACOES_DURAS := [
	[false, false, 1.0], [false, false, 0.985], [false, false, 0.97], [false, false, 0.99],
]
const PISOS_DUROS := ["pavimento", "asfalto"]

func _ready() -> void:
	add_to_group("chao")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _ler_raster():
		return
	tile_set = _montar_tileset()
	var comeco := Time.get_ticks_msec()
	var pintadas := _pintar()
	print("chao: %d celulas pintadas em %d ms" % [pintadas, Time.get_ticks_msec() - comeco])

## Le o raster dos vertices e o indice das classes.
func _ler_raster() -> bool:
	if not FileAccess.file_exists(RASTER) or not FileAccess.file_exists(INDICE_DO_RASTER):
		push_error("chao: falta %s ou %s - rode node design/rasterizar_chao.js" % [RASTER, INDICE_DO_RASTER])
		return false
	var indice = JSON.parse_string(FileAccess.get_file_as_string(INDICE_DO_RASTER))
	_classes = PackedStringArray(indice["classes"])
	_colunas = int(indice["colunas"])
	_linhas = int(indice["linhas"])
	var textura := load(RASTER) as Texture2D
	var imagem := textura.get_image()
	if imagem == null or imagem.get_width() != _colunas or imagem.get_height() != _linhas:
		push_error("chao: o raster nao bate com o indice (%s x %s)" % [_colunas, _linhas])
		return false
	if imagem.get_format() != Image.FORMAT_L8:
		imagem.convert(Image.FORMAT_L8)
	_vertices = imagem.get_data()
	return true

## A classe do vertice (coluna, linha), ja com os apelidos.
func _classe(c: int, r: int) -> String:
	var nome := _classes[_vertices[r * _colunas + c]]
	return MESMA_CLASSE.get(nome, nome)

## Um TileSet com uma fonte por tileset do PixelLab, e as tabelas de busca.
func _montar_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var indice = JSON.parse_string(FileAccess.get_file_as_string(INDICE_DOS_TILESETS))
	for entrada in indice["tilesets"]:
		var arquivo: String = entrada["arquivo"]
		var meta = JSON.parse_string(FileAccess.get_file_as_string(PASTA + arquivo + ".json"))
		var png := load(PASTA + arquivo + ".png") as Texture2D
		if meta == null or png == null:
			push_error("chao: tileset %s sem PNG ou sem JSON" % arquivo)
			continue
		var fonte := TileSetAtlasSource.new()
		fonte.texture = png
		fonte.texture_region_size = Vector2i(TILE, TILE)
		var id := ts.add_source(fonte)
		var tiles := {}
		for tile in meta["tileset_data"]["tiles"]:
			var caixa: Dictionary = tile["bounding_box"]
			var coords := Vector2i(int(caixa["x"]) / TILE, int(caixa["y"]) / TILE)
			if not fonte.has_tile(coords):
				fonte.create_tile(coords)
			var cantos: Dictionary = tile["corners"]
			var wang := _de_cima(cantos["NW"]) * 8 + _de_cima(cantos["NE"]) * 4 \
				+ _de_cima(cantos["SW"]) * 2 + _de_cima(cantos["SE"])
			tiles[wang] = coords
		var baixo: String = entrada["baixo"]
		var cima: String = entrada["cima"]
		_transicoes["%s|%s" % [baixo, cima]] = {"fonte": id, "tiles": tiles}
		if tiles.has(0) and not _cheios.has(baixo):
			_cheios[baixo] = [id, tiles[0]]
			_variantes[baixo] = _criar_variantes(fonte, tiles[0], baixo)
		if tiles.has(15) and not _cheios.has(cima):
			_cheios[cima] = [id, tiles[15]]
			_variantes[cima] = _criar_variantes(fonte, tiles[15], cima)
	return ts

## Os tiles alternativos de um tile cheio, um por entrada da lista de
## variacoes da classe. O primeiro (sem espelho, tom 1) e o proprio tile, id 0.
static func _criar_variantes(fonte: TileSetAtlasSource, coords: Vector2i, classe: String) -> Array[int]:
	var variacoes: Array = VARIACOES_DURAS if classe in PISOS_DUROS else VARIACOES_NATURAIS
	var ids: Array[int] = [0]
	for i in range(1, variacoes.size()):
		var variacao: Array = variacoes[i]
		var alternativo := fonte.create_alternative_tile(coords)
		var dados := fonte.get_tile_data(coords, alternativo)
		dados.flip_h = variacao[0]
		dados.flip_v = variacao[1]
		var tom: float = variacao[2]
		dados.modulate = Color(tom, tom, tom)
		ids.append(alternativo)
	return ids

static func _de_cima(canto: String) -> int:
	return 0 if canto == "lower" else 1

## Pinta todas as celulas: a (c, r) tem os vertices (c, r), (c+1, r), (c, r+1)
## e (c+1, r+1) nos cantos. Devolve quantas pintou.
func _pintar() -> int:
	var pintadas := 0
	for r in _linhas - 1:
		for c in _colunas - 1:
			var escolha := _tile_para(_classe(c, r), _classe(c + 1, r), _classe(c, r + 1), _classe(c + 1, r + 1))
			if escolha.is_empty():
				continue
			# escolha[2], quando existe, e a classe de um tile cheio: sorteia a
			# variacao pelo hash da celula.
			var alternativo := 0
			if escolha.size() > 2:
				var ids: Array = _variantes.get(escolha[2], [0])
				alternativo = ids[posmod(c * 73856093 ^ r * 19349663, ids.size())]
			set_cell(Vector2i(c, r), escolha[0], escolha[1], alternativo)
			pintadas += 1
	return pintadas

## [fonte, coords] do tile para estes quatro cantos, ou vazio se nao ha tile.
## Cantos iguais: o tile cheio. Duas classes: a transicao delas, em qualquer
## ordem. Tres ou mais, ou par sem transicao gerada: o tile cheio da classe
## mais frequente - fica reto, mas nao fica buraco.
func _tile_para(nw: String, ne: String, sw: String, se: String) -> Array:
	if nw == ne and ne == sw and sw == se:
		return _cheio(nw)
	var contagem := {}
	for classe in [nw, ne, sw, se]:
		contagem[classe] = contagem.get(classe, 0) + 1
	if contagem.size() == 2:
		var a: String = contagem.keys()[0]
		var b: String = contagem.keys()[1]
		for par in [[a, b], [b, a]]:
			var chave := "%s|%s" % par
			if not _transicoes.has(chave):
				continue
			var transicao: Dictionary = _transicoes[chave]
			var cima: String = par[1]
			var wang := (8 if nw == cima else 0) + (4 if ne == cima else 0) \
				+ (2 if sw == cima else 0) + (1 if se == cima else 0)
			if transicao["tiles"].has(wang):
				return [transicao["fonte"], transicao["tiles"][wang]]
	var melhor := nw
	var mais := 0
	for classe in contagem:
		if contagem[classe] > mais:
			mais = contagem[classe]
			melhor = classe
	return _cheio(melhor)

## [fonte, coords, classe] do tile cheio da classe, ou vazio. A classe vai
## junto para `_pintar` sortear a variacao.
func _cheio(classe: String) -> Array:
	if not _cheios.has(classe):
		return []
	var cheio: Array = _cheios[classe]
	return [cheio[0], cheio[1], classe]
