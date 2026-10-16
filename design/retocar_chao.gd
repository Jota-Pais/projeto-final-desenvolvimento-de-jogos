extends SceneTree
# Aplica o mapa de cores DE -> PARA de rua/arte/chao/paleta.json a um PNG de
# tileset, localmente. Cor que o mapa nao conhece recebe a regra geral do
# clima (paleta.json, "regra_geral"): tira saturacao e escurece um pouco, para
# qualquer terreno novo sair apagado e sujo sem precisar de tabela a mao.
# Lista as cores desconhecidas (com contagem) para quem quiser afinar.
# Uso: retocar.gd <entrada.png> <paleta.json> <saida.png>
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var imagem := Image.load_from_file(args[0])
	var paleta = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var mapa := {}
	var regra: Dictionary = paleta.get("regra_geral", {"saturacao": 0.35, "valor": 0.8})
	for grupo in paleta:
		if paleta[grupo] is Dictionary and grupo != "regra_geral":
			for de in paleta[grupo]:
				mapa[Color(de).to_html(false)] = Color(paleta[grupo][de])
	var desconhecidas := {}
	var trocadas := 0
	var apagadas := 0
	for y in imagem.get_height():
		for x in imagem.get_width():
			var cor := imagem.get_pixel(x, y)
			if cor.a == 0.0:
				continue
			var chave := cor.to_html(false)
			if mapa.has(chave):
				var nova: Color = mapa[chave]
				nova.a = cor.a
				imagem.set_pixel(x, y, nova)
				trocadas += 1
			else:
				var apagada := Color.from_hsv(cor.h, cor.s * float(regra["saturacao"]), cor.v * float(regra["valor"]), cor.a)
				imagem.set_pixel(x, y, apagada)
				apagadas += 1
				desconhecidas[chave] = desconhecidas.get(chave, 0) + 1
	imagem.save_png(args[2])
	print("trocados pela tabela %d px; apagados pela regra geral %d px; salvo %s" % [trocadas, apagadas, args[2]])
	var lista := desconhecidas.keys()
	lista.sort_custom(func(a, b): return desconhecidas[a] > desconhecidas[b])
	for chave in lista:
		print("desconhecida #%s x%d" % [chave, desconhecidas[chave]])
	quit(0)
