extends SceneTree
# Tira o fundo de um PNG gerado que veio com fundo apesar do `no_background`
# (o motorhome de 14/10/2026 veio num cinza chapado, com sombra). Inunda a
# partir das bordas: todo pixel ligado a borda cuja cor fica a menos de
# TOLERANCIA da cor do canto vira transparente - o que inclui a sombra, que e
# o mesmo cinza escurecido, e para no contorno preto do objeto. O que esta
# dentro do contorno (vidro, roda) nao e alcancado e fica.
# Uso: Godot --headless --path . --script design/recortar_fundo.gd -- <entrada.png> <saida.png> [tolerancia=0.35]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var imagem := Image.load_from_file(args[0])
	var tolerancia := float(args[2]) if args.size() > 2 else 0.35
	var fundo := imagem.get_pixel(0, 0)
	var largura := imagem.get_width()
	var altura := imagem.get_height()
	var visto := PackedByteArray()
	visto.resize(largura * altura)
	var fila: Array[Vector2i] = []
	for x in largura:
		fila.append(Vector2i(x, 0))
		fila.append(Vector2i(x, altura - 1))
	for y in altura:
		fila.append(Vector2i(0, y))
		fila.append(Vector2i(largura - 1, y))
	var apagados := 0
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= largura or p.y >= altura:
			continue
		var i := p.y * largura + p.x
		if visto[i] == 1:
			continue
		visto[i] = 1
		var cor := imagem.get_pixelv(p)
		var longe := Vector3(cor.r - fundo.r, cor.g - fundo.g, cor.b - fundo.b).length()
		if cor.a > 0.0 and longe > tolerancia:
			continue
		if cor.a > 0.0:
			imagem.set_pixelv(p, Color(0, 0, 0, 0))
			apagados += 1
		fila.append(p + Vector2i.LEFT)
		fila.append(p + Vector2i.RIGHT)
		fila.append(p + Vector2i.UP)
		fila.append(p + Vector2i.DOWN)
	imagem.save_png(args[1])
	print("fundo #%s: %d px apagados; salvo %s" % [fundo.to_html(false), apagados, args[1]])
	quit(0)
