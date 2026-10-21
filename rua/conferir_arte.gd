extends Node
## Ferramenta. **Rode esta cena para ver sprites sobre o greybox, na escala do
## jogo.**
##
## Serve ao padrao de arte: antes de aprovar um sprite
## gerado - e antes de gastar geracoes animando ele - a pergunta e "como fica
## em cima da rua que existe, no tamanho que o jogo mostra?". Esta cena monta a
## rua de verdade, poe cada PNG pedido ao lado do jogador na escala do mundo
## (1 px de mundo por pixel de desenho, filtro nearest, pe na borda de baixo da
## caixa de colisao), escreve o nome do arquivo embaixo e salva um PNG da tela,
## com o zoom do jogo. O jogador fica no meio, de regua: a caixa dele e 14 x 20
## e o boneco do PixelLab entra em escala 0,5 desde 20/10/2026 (rua/boneco.gd) -
## um personagem novo se confere com `@0.5` no caminho; movel, carro e o resto
## do mundo continuam em escala 1.
##
## **Nao roda em headless** (capturar a tela precisa de renderizador), igual ao
## retratar_mapa. No editor e F6; na linha de comando:
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --position -4000,-4000 res://rua/conferir_arte.tscn -- --sprites=C:/a.png;C:/b.png --saida=C:/teste.png
##
## O `--position -4000,-4000` poe a janela fora da tela, e o _ready tira dela
## o foco: a figura sai igual e nada aparece por cima do que se esta fazendo
## (pedido do Joao, 14/10/2026).
##
## Caminhos absolutos ou res://. Sem `--sprites`, mostra so a rua com o jogador.
## Sem `--saida`, salva em user://conferir_arte.png. `--escala=2` mostra em
## outra escala que a do padrao. `--zumbis` deixa os zumbis na figura (por
## padrao eles somem, para a figura ser do sprite que se esta conferindo).
## `--tiros` (com `--zumbis`) poe um zumbi ferido a esquerda do jogador e um
## morto a direita, para ver o dano e a morte como o codigo mostra enquanto a
## folha nao tem `dano` e `morrer` (03/10/2026). Sem `--zoom` a camera fica no
## zoom do jogo (2, jogador.gd) - a fileira cabe ate dois sprites; com mais, a
## figura cai para o maior zoom inteiro em que todos cabem. `--zoom=6` aproxima
## no jogador para ver detalhe de pixel (a arma na mao tem de 12 x 7 a 30 x 9 de
## desenho); sprite ao lado sai da figura.
## `--arma=M4` poe outra arma na mao dele (os nomes estao em rua/arma.gd).
## `--onde=x,y` leva o jogador para outro ponto do mundo, para ver o chao
## longe de casa (mata, lavoura, rio); `--zoom=0.06` mostra o mapa quase
## inteiro. Os PNG sao lidos do disco (Image.load_from_file), sem passar pelo importador:
## nada precisa estar dentro do projeto, e nao nasce .import nenhum.

##
## O canvas do PixelLab e maior que o boneco (em `standard`, `size=64` e a
## altura do boneco, e o canvas vem com 92 e uns 17 px vazios embaixo). Por
## isso o alinhamento usa o retangulo **ocupado** da imagem, nao o canvas: e o
## pe desenhado que encosta na caixa de colisao.

const CENA_DA_RUA := preload("res://rua/rua.tscn")
const Jogador := preload("res://rua/jogador.gd")

## A escala do mundo: 1 pixel de desenho = 1 px de mundo (decidido 30/09/2026
## no teste 0; desde 20/10/2026 vale para o mundo, e o boneco e 0,5).
## `--escala=` troca para todos, `@escala` para um.
const ESCALA_DA_ARTE := 1.0

## Distancia entre um sprite e o seguinte, em px de mundo. Um canvas do PixelLab
## tem 112; com 200 sobra lugar para o jogador no meio.
const ESPACO := 200.0


## Onde fica a borda de baixo da caixa de colisao do jogador (14 x 20, centrada).
const PE_DO_JOGADOR := 10.0

var _rua: Node
var _caminhos: PackedStringArray
var _saida := "user://conferir_arte.png"
var _escala := ESCALA_DA_ARTE
var _com_zumbis := false
var _com_tiros := false
var _zoom := Jogador.ZOOM_DA_CAMERA
## O --zoom veio na linha de comando: a figura nao mexe nele para caber.
var _zoom_pedido := false
## Onde o jogador fica na figura; zero = onde ele nasce.
var _onde := Vector2.ZERO
var _quadros := 0
var _salvou := false

func _ready() -> void:
	# Fora da tela e sem foco (ver o cabecalho): a janela continua renderizando,
	# que e o que a captura precisa, mas nao aparece nem rouba o teclado.
	# Testado em 14/10/2026: headless nao serve (sem renderizador a textura da
	# viewport e nula, com vulkan e com opengl3), e janela MINIMIZADA tambem nao
	# (a figura sai em branco) - fora da tela e o que sobra.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-4000, -4000))
	for arg in OS.get_cmdline_user_args():
		var a := arg as String
		if a.begins_with("--sprites="):
			_caminhos = a.trim_prefix("--sprites=").split(";", false)
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--escala="):
			_escala = float(a.trim_prefix("--escala="))
		elif a == "--zumbis":
			_com_zumbis = true
		elif a == "--tiros":
			_com_tiros = true
		elif a.begins_with("--zoom="):
			_zoom = float(a.trim_prefix("--zoom="))
			_zoom_pedido = true
		elif a.begins_with("--arma="):
			# Antes de a rua nascer: a arma le o Travessia no _ready.
			Travessia.arma = a.trim_prefix("--arma=")
		elif a.begins_with("--onde="):
			# Leva o jogador para outro ponto do mundo (x,y em px), para
			# conferir o chao longe de casa: mata, lavoura, rio.
			var xy := a.trim_prefix("--onde=").split(",")
			_onde = Vector2(float(xy[0]), float(xy[1]))

	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	# A figura e do sprite sobre o chao: sem HUD, sem o dia passando e, a nao
	# ser que se peca, sem zumbi.
	(_rua.get_node("Hud") as CanvasLayer).visible = false
	_rua.get_node("Relogio").set_process(false)
	# A linha de mira da arma e auxilio de prototipo e riscaria a figura; a
	# arma na mao fica, que ela e parte do que se confere.
	var arma := _rua.get_node_or_null("Jogador/Arma")
	if arma != null:
		arma.mostrar_a_mira = false
	if _com_zumbis:
		return
	_rua.get_node("Cenario").povoa_por_proximidade = false
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		(zumbi as Node2D).visible = false


func _process(_delta: float) -> void:
	_quadros += 1
	# Um quadro para o cenario por o jogador no lugar, outro para a camera.
	if _quadros == 2:
		_colocar_os_sprites()
		return
	# Os zumbis nascem pelo povoamento nos primeiros quadros; o tiro espera
	# eles - e espera a fisica saber onde foram postos, que e no passo
	# seguinte -, e a figura espera a queda (0,3 s) acabar.
	if _com_tiros and _quadros == 10:
		_posicionar_os_zumbis()
		return
	if _com_tiros and _quadros == 14:
		_atirar_nos_zumbis()
		return
	# Com tiros, espera a animacao `morrer` inteira (7 quadros a 8 por segundo)
	# e a queda de codigo (0,3 s) acabarem.
	if _salvou or _quadros < (110 if _com_tiros else 8):
		return
	_salvou = true
	_salvar()

var _ferido: CharacterBody2D
var _morto: CharacterBody2D
## Um terceiro, abaixo do jogador, para a queda de codigo (olhando para o
## leste, sem `morrer` na folha nessa direcao): tomba e vira o quadro do morto.
var _deitado: CharacterBody2D

## Um zumbi a esquerda do jogador, outro a direita e, se houver, um abaixo,
## com a fisica parada para ficarem onde foram postos.
func _posicionar_os_zumbis() -> void:
	var jogador := _rua.get_node("Jogador") as Node2D
	var zumbis := get_tree().get_nodes_in_group("zumbi")
	if zumbis.size() < 2:
		push_error("conferir_arte: --tiros precisa de dois zumbis vivos (use --zumbis)")
		return
	_ferido = zumbis[0] as CharacterBody2D
	_morto = zumbis[1] as CharacterBody2D
	if zumbis.size() >= 3:
		_deitado = zumbis[2] as CharacterBody2D
	for zumbi in [_ferido, _morto, _deitado]:
		if zumbi == null:
			continue
		zumbi.set_physics_process(false)
		zumbi.velocity = Vector2.ZERO
	# O ferido fica um pouco ATRAS do jogador (pe mais acima) e encostado, e o
	# deitado cai POR CIMA dos pes dele: e a prova do Y-sort (14/10/2026) -
	# quem tem o pe mais embaixo na tela desenha na frente.
	_ferido.global_position = jogador.global_position + Vector2(-17.0, -23.0)
	_morto.global_position = jogador.global_position + Vector2(55.0, 0.0)
	# Olhando para o sul: e a direcao em que a folha tem o `morrer` de verdade.
	_morto._olhando = Vector2.DOWN
	if _deitado != null:
		_deitado.global_position = jogador.global_position + Vector2(5.0, 22.0)
		_deitado._olhando = Vector2.RIGHT

## O da esquerda leva um tiro **da arma** (ferido, com a barra de vida; e o
## jogador vira para la, com a arma na mao apontada para a esquerda, que e o
## lado espelhado). O da direita cai de uma vez com a animacao `morrer` (olha
## para o sul); o de baixo cai de uma vez pela queda de codigo.
func _atirar_nos_zumbis() -> void:
	if _ferido == null:
		return
	var arma := _rua.get_node("Jogador/Arma")
	arma._mira = arma.global_position.direction_to(_ferido.global_position)
	arma._espera = 0.0
	arma._atirar()
	_morto.levar_tiro(_morto.VIDA_CHEIA, Vector2.RIGHT)
	if _deitado != null:
		_deitado.levar_tiro(_deitado.VIDA_CHEIA, Vector2.RIGHT)
	# A figura nao pode depender de onde o mouse do sistema esta: depois do
	# tiro ele continua olhando para o zumbi que acabou de acertar, e nao para
	# o mouse pelos 0,5 s de mira.
	var jogador := _rua.get_node("Jogador")
	jogador._mirando = 0.0
	jogador._olhando = arma._mira

func _colocar_os_sprites() -> void:
	var jogador := _rua.get_node("Jogador") as Node2D
	if _onde != Vector2.ZERO:
		jogador.global_position = _onde
	var n := _caminhos.size()
	# A fileira tem que caber na figura (20/10/2026): no zoom do jogo cabem dois
	# sprites lado a lado; com mais, o maior zoom inteiro em que todos cabem.
	if not _zoom_pedido and n > 0:
		var cabe := floorf(get_viewport().get_visible_rect().size.x / ((float(n) + 1.0) * ESPACO))
		if cabe < _zoom:
			_zoom = maxf(1.0, cabe)
			print("conferir_arte: %d sprites nao cabem no zoom do jogo; figura em zoom %.0f" % [n, _zoom])
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2.ONE * _zoom
	for i in n:
		# Distribuidos em volta do jogador; com dois, um de cada lado dele.
		var deslocamento := (float(i) - (float(n) - 1.0) / 2.0) * ESPACO
		if n % 2 == 1:
			# Impar: o do meio cairia em cima do jogador. Todo mundo meio
			# passo para a direita.
			deslocamento += ESPACO / 2.0
		_colocar(_caminhos[i], jogador.global_position + Vector2(deslocamento, 0.0))

## `caminho` aceita um sufixo `@escala` (ex.: `boneco.png@1.31`) para aquele
## sprite entrar em outra escala que a geral. **E mock**: escala fracionaria
## deixa o pixel desigual e nao serve para o jogo - serve para comparar
## tamanhos antes de gastar uma geracao refazendo o boneco maior ou menor.
func _colocar(caminho: String, onde: Vector2) -> void:
	var escala := _escala
	if "@" in caminho:
		escala = float(caminho.get_slice("@", 1))
		caminho = caminho.get_slice("@", 0)
	var no_disco := caminho
	if caminho.begins_with("res://") or caminho.begins_with("user://"):
		no_disco = ProjectSettings.globalize_path(caminho)
	var imagem := Image.load_from_file(no_disco)
	if imagem == null:
		push_error("conferir_arte: nao consegui ler %s" % caminho)
		return

	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(imagem)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * escala
	# O pe **desenhado** na borda de baixo da caixa de colisao, e o boneco
	# centrado em x: o sprite e centrado no canvas, entao o centro do canvas
	# vai para onde o retangulo ocupado pede.
	var canvas := Vector2(imagem.get_size())
	var ocupado := imagem.get_used_rect()
	var ajuste := Vector2(
		canvas.x / 2.0 - ocupado.get_center().x,
		canvas.y / 2.0 - float(ocupado.end.y)) * escala
	sprite.global_position = onde + Vector2(0.0, PE_DO_JOGADOR) + ajuste
	# Filho da rua, depois de tudo: desenha por cima, ate dos telhados. O
	# jogador nasce na calcada, sem telhado em cima, entao nao muda nada aqui.
	_rua.add_child(sprite)
	var altura_no_mundo := ocupado.size.y * escala
	print("conferir_arte: %s boneco %d x %d px de desenho, %.0f x %.0f de mundo (x%.2f)" % [
		caminho.get_file(), ocupado.size.x, ocupado.size.y,
		ocupado.size.x * escala, altura_no_mundo, escala])

	var rotulo := Label.new()
	# A altura no mundo e o que se compara; a escala vai junto para nao
	# confundir mock esticado com boneco gerado naquele tamanho.
	rotulo.text = "%s  %.0f px  (x%.2f)" % [caminho.get_file().get_basename(), altura_no_mundo, escala]
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_color_override("font_color", Color.WHITE)
	rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo.add_theme_constant_override("outline_size", 4)
	# O rotulo e do mundo, mas tem que ler do mesmo tamanho na tela com qualquer
	# zoom: escala 1/zoom, e o tamanho dele em unidades dessa escala.
	var k := 1.0 / maxf(_zoom, 0.01)
	rotulo.scale = Vector2.ONE * k
	rotulo.size = Vector2(ESPACO / k, 24.0)
	rotulo.position = Vector2(onde.x - ESPACO / 2.0, onde.y + PE_DO_JOGADOR + 8.0 * k)
	_rua.add_child(rotulo)

func _salvar() -> void:
	var imagem := get_viewport().get_texture().get_image()
	var erro := imagem.save_png(_saida)
	if erro != OK:
		push_error("conferir_arte: nao salvei %s (erro %d)" % [_saida, erro])
	else:
		print("conferir_arte: salvo em %s" % _saida)
	get_tree().quit(0 if erro == OK else 1)
