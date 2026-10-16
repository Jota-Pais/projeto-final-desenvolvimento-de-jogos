extends SceneTree
## Ferramenta headless. **Troca cores exatas em todos os PNG de uma pasta**, em
## cima do proprio arquivo, recursivamente.
##
## Para que serve: o PixelLab gera as rotacoes e as animacoes no servidor, e
## um retoque de paleta feito a mao aqui (o olho verde do jogador, decidido em
## 30/09/2026) nao volta para la - todo frame novo chega com a cor antiga. Em
## vez de regenerar o personagem (e perder o que foi aprovado), a troca e um
## passo da importacao: baixou, rodou isto na pasta, pronto. As trocas de cada
## personagem estao em `design/arte-rua.md`.
##
## So troca cor **exatamente igual** (RGB; o alfa do pixel e preservado). Pixel
## art tem paleta pequena, entao isso basta - e e por isso que o `--faixa` existe:
## se a mesma cor aparece em outro lugar do boneco, limita-se as linhas do canvas
## onde ela e o que se quer trocar.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://rua/recolorir_arte.gd -- --pasta=C:/arte/jogador --trocas=30699B:2E6B3C;374A63:1F4A2B --faixa=0:50
##
##  - `--pasta=`  pasta com os PNG (entra nas subpastas). Absoluta ou res://.
##  - `--trocas=` pares DE:PARA em hex RGB, separados por `;`.
##  - `--faixa=`  opcional, `y0:y1` em px do canvas: so troca nessas linhas.
##  - `--ensaio`  opcional: so conta, nao grava.
##
## Sai com 0 se gravou (ou ensaiou) sem erro; 1 se faltou argumento ou algum
## arquivo nao abriu.

func _init() -> void:
	var pasta := ""
	var trocas := {}
	var faixa := Vector2i(0, 1 << 20)
	var ensaio := false
	for arg in OS.get_cmdline_user_args():
		var a := arg as String
		if a.begins_with("--pasta="):
			pasta = a.trim_prefix("--pasta=")
		elif a.begins_with("--trocas="):
			for par in a.trim_prefix("--trocas=").split(";", false):
				var lados := (par as String).split(":")
				if lados.size() != 2:
					push_error("recolorir_arte: troca invalida '%s' (use DE:PARA)" % par)
					quit(1)
					return
				trocas[lados[0].to_upper()] = Color.html(lados[1])
		elif a.begins_with("--faixa="):
			var l := a.trim_prefix("--faixa=").split(":")
			faixa = Vector2i(int(l[0]), int(l[1]))
		elif a == "--ensaio":
			ensaio = true

	if pasta == "" or trocas.is_empty():
		push_error("recolorir_arte: preciso de --pasta= e --trocas=")
		quit(1)
		return
	if pasta.begins_with("res://") or pasta.begins_with("user://"):
		pasta = ProjectSettings.globalize_path(pasta)

	var arquivos: PackedStringArray = []
	_listar_pngs(pasta, arquivos)
	if arquivos.is_empty():
		push_error("recolorir_arte: nenhum PNG em %s" % pasta)
		quit(1)
		return

	var erro := false
	var total := 0
	for caminho in arquivos:
		var imagem := Image.load_from_file(caminho)
		if imagem == null:
			push_error("recolorir_arte: nao li %s" % caminho)
			erro = true
			continue
		var trocados := _trocar(imagem, trocas, faixa)
		total += trocados
		if trocados > 0 and not ensaio:
			if imagem.save_png(caminho) != OK:
				push_error("recolorir_arte: nao gravei %s" % caminho)
				erro = true
		print("recolorir_arte: %s - %d pixel(s)%s" % [
			caminho.get_file(), trocados, " (ensaio)" if ensaio else ""])
	print("recolorir_arte: %d arquivo(s), %d pixel(s) trocado(s)" % [arquivos.size(), total])
	quit(1 if erro else 0)

func _trocar(imagem: Image, trocas: Dictionary, faixa: Vector2i) -> int:
	var trocados := 0
	var y0 := maxi(0, faixa.x)
	var y1 := mini(imagem.get_height() - 1, faixa.y)
	for y in range(y0, y1 + 1):
		for x in imagem.get_width():
			var c := imagem.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			# Comparar pelo hex e nao pelo Color: evita a conta de float em
			# ambos os lados e e o formato em que a troca foi escrita.
			var hex := c.to_html(false).to_upper()
			if trocas.has(hex):
				var nova: Color = trocas[hex]
				imagem.set_pixel(x, y, Color(nova.r, nova.g, nova.b, c.a))
				trocados += 1
	return trocados

func _listar_pngs(pasta: String, saida: PackedStringArray) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		var caminho := pasta.path_join(nome)
		if dir.current_is_dir():
			if not nome.begins_with("."):
				_listar_pngs(caminho, saida)
		elif nome.to_lower().ends_with(".png"):
			saida.append(caminho)
		nome = dir.get_next()
	dir.list_dir_end()
