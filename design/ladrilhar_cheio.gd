extends SceneTree
# Monta, para cada classe de chao, um ladrilho de CELULAS x CELULAS tiles com
# o tile cheio da classe repetido com as variacoes de rua/chao.gd (espelho e
# tom por hash da celula), para rua/ruas.gd desenhar calcada, rua e os lotes
# de dentro delas como poligonos com textura sem a grade aparecer: o ladrilho
# so se repete a cada 256 px (15/10/2026).
#
# Le rua/arte/chao/tilesets.json e os tilesets do PixelLab (bounding_box e
# corners de cada tile) e grava rua/arte/chao/cheio-<classe>.png. O tile
# cheio e o de quatro cantos iguais, como em chao.gd. Rodar de novo sempre
# que um tileset mudar.
#
# Uso: Godot --headless --path . --script design/ladrilhar_cheio.gd
const TILE := 32
const CELULAS := 8
const PASTA := "res://rua/arte/chao/"

# As mesmas listas de rua/chao.gd: [espelha_x, espelha_y, tom].
const VARIACOES_NATURAIS := [
	[false, false, 1.0], [true, false, 1.0], [false, true, 0.985], [true, true, 0.985],
	[false, false, 0.97], [true, false, 0.99], [false, true, 1.0], [true, true, 0.975],
]
const VARIACOES_DURAS := [
	[false, false, 1.0], [false, false, 0.985], [false, false, 0.97], [false, false, 0.99],
]
const PISOS_DUROS := ["pavimento", "asfalto"]

func _init() -> void:
	var indice = JSON.parse_string(FileAccess.get_file_as_string(PASTA + "tilesets.json"))
	var cheios := {}
	for entrada in indice["tilesets"]:
		var arquivo: String = entrada["arquivo"]
		var meta = JSON.parse_string(FileAccess.get_file_as_string(PASTA + arquivo + ".json"))
		var png := Image.load_from_file(ProjectSettings.globalize_path(PASTA + arquivo + ".png"))
		if meta == null or png == null:
			push_error("ladrilhar: tileset %s sem PNG ou sem JSON" % arquivo)
			continue
		png.convert(Image.FORMAT_RGBA8)
		for tile in meta["tileset_data"]["tiles"]:
			var cantos: Dictionary = tile["corners"]
			var de_cima := 0
			for canto in ["NW", "NE", "SW", "SE"]:
				if cantos[canto] != "lower":
					de_cima += 1
			var classe := ""
			if de_cima == 0:
				classe = entrada["baixo"]
			elif de_cima == 4:
				classe = entrada["cima"]
			else:
				continue
			if cheios.has(classe):
				continue
			var caixa: Dictionary = tile["bounding_box"]
			cheios[classe] = png.get_region(Rect2i(int(caixa["x"]), int(caixa["y"]), TILE, TILE))

	for classe in cheios:
		var tile: Image = cheios[classe]
		var lado := TILE * CELULAS
		var ladrilho := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
		var variacoes: Array = VARIACOES_DURAS if classe in PISOS_DUROS else VARIACOES_NATURAIS
		for r in CELULAS:
			for c in CELULAS:
				var v: Array = variacoes[hash(Vector2i(c, r)) % variacoes.size()]
				var copia: Image = tile.duplicate()
				if v[0]:
					copia.flip_x()
				if v[1]:
					copia.flip_y()
				var tom: float = v[2]
				if tom != 1.0:
					for y in TILE:
						for x in TILE:
							var cor := copia.get_pixel(x, y)
							copia.set_pixel(x, y, Color(cor.r * tom, cor.g * tom, cor.b * tom, cor.a))
				ladrilho.blit_rect(copia, Rect2i(0, 0, TILE, TILE), Vector2i(c * TILE, r * TILE))
		var saida: String = PASTA + "cheio-" + str(classe) + ".png"
		ladrilho.save_png(ProjectSettings.globalize_path(saida))
		print("%s: %d x %d" % [saida, lado, lado])
	quit(0)
