extends AnimatedSprite2D
## O boneco da rua: a folha de sprites do PixelLab virando `AnimatedSprite2D`.
##
## O PixelLab exporta um personagem como uma folha PNG mais um JSON de layout:
## celulas iguais em grade, a linha 0 com as 8 rotacoes paradas e uma linha por
## direcao de cada animacao. Este no le o JSON (`folha`), carrega o PNG que
## esta ao lado dele e monta um `SpriteFrames` com uma animacao por acao e
## direcao - `parado_sul`, `andar_sudoeste`, `vagar_norte`... Quem usa so chama
## `mostrar(acao, direcao)` a cada quadro de fisica; a direcao e um vetor
## qualquer, e aqui vira um dos oito setores de 45 graus. Para uma acao que
## acontece uma vez (`atirar`, `dano`, `morrer`), `tocar(acao, direcao)` toca a
## animacao ate o fim e devolve `false` se a folha nao a tem - e quem chama faz
## a versao de codigo (03/10/2026). Assim a animacao entra na folha e o jogo a
## usa sem mudar uma linha.
##
## As regras vem de `design/arte-rua.md` ("Como entra no Godot"):
##
##  - **escala 1**: 1 pixel de desenho = 1 px de mundo (40 px = 1 m), com filtro
##    nearest para o pixel nao borrar;
##  - **pivo fixo no centro da celula**, como o PixelLab recomenda, com o pe da
##    rotacao sul na borda de baixo da caixa de colisao (`pe`). Alinhar cada
##    direcao pelo proprio pe desenhado faria o boneco pular ate 6 px ao virar,
##    porque nas vistas de lado o pe da frente e desenhado mais embaixo - isso
##    e perspectiva, nao desalinhamento;
##  - o nome da animacao no Godot e o nome dela no PixelLab **sem o sufixo de
##    versao** (`andar-v3` vira `andar`): a versao e coisa de producao;
##  - uma folha e lida uma vez por processo e compartilhada: vinte zumbis sao
##    vinte nos e um `SpriteFrames`.

## O JSON de layout exportado pelo PixelLab. O PNG e o `spritesheet.path` dele,
## na mesma pasta.
@export_file("*.json") var folha := ""

## Onde fica a borda de baixo da caixa de colisao do pai, em y local: e onde o
## pe da rotacao sul encosta. 20 para o jogador (28 x 40), 22 para o zumbi.
@export var pe := 20.0

## Ritmo das animacoes a velocidade normal. `mostrar()` multiplica pelo
## `ritmo` para correr ou perseguir com a mesma animacao, de graca.
@export var quadros_por_segundo := 10.0

## Os nomes de direcao do PixelLab e os nomes em portugues que entram no nome
## da animacao.
const NOME_DA_DIRECAO := {
	"south": "sul", "south-east": "sudeste", "east": "leste",
	"north-east": "nordeste", "north": "norte", "north-west": "noroeste",
	"west": "oeste", "south-west": "sudoeste",
}

## Setores de 45 graus a partir do angulo do vetor, no sentido do Godot (y para
## baixo): 0 grau e leste, 90 graus e sul.
const SETORES := ["leste", "sudeste", "sul", "sudoeste", "oeste", "noroeste", "norte", "nordeste"]

## Folhas ja montadas neste processo: caminho do JSON -> { "frames", "offset" }.
static var _folhas := {}

## Emitido quando uma animacao comecada por `tocar()` chega ao ultimo quadro.
signal terminou(acao: String)

var _direcao := "sul"
var _acao := ""
## Uma animacao de `tocar()` esta no meio: `mostrar()` espera ela acabar.
var _uma_vez := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	animation_finished.connect(_ao_terminar)
	var montada := _montar(folha, quadros_por_segundo)
	if montada.is_empty():
		return
	sprite_frames = montada["frames"]
	offset = (montada["offset"] as Vector2) + Vector2(0.0, pe)
	mostrar("parado", Vector2.DOWN)

## Mostra `acao` olhando para `direcao`. Vetor nulo mantem a direcao de antes
## (parado continua olhando para onde andava). `ritmo` multiplica a velocidade
## da animacao: 1 e o passo normal.
##
## Trocar de direcao no meio do passo **nao reinicia** a animacao: o quadro e o
## progresso passam para a direcao nova, senao andar em curva da um soluco a
## cada 45 graus. Enquanto uma animacao de `tocar()` roda, so a direcao e
## guardada - e usada quando ela acabar.
func mostrar(acao: String, direcao: Vector2, ritmo := 1.0) -> void:
	if sprite_frames == null:
		return
	if direcao.length_squared() > 0.0001:
		_direcao = setor(direcao)
	if _uma_vez:
		return
	var nome := "%s_%s" % [acao, _direcao]
	if not sprite_frames.has_animation(nome):
		nome = "parado_%s" % _direcao
	speed_scale = ritmo
	if animation == nome and is_playing():
		return
	var quadro := frame
	var progresso := frame_progress
	var mesma_acao := acao == _acao
	_acao = acao
	play(nome)
	var quantos := sprite_frames.get_frame_count(nome)
	if mesma_acao and quantos > 0:
		set_frame_and_progress(quadro % quantos, progresso)

## Toca `acao` uma vez, olhando para `direcao`, e emite `terminou` no fim; ate
## la `mostrar()` nao troca de animacao. Devolve `false`, sem mexer em nada, se
## a folha nao tem essa acao nessa direcao - e o chamador mostra o que der no
## codigo (clarao, recuo, queda). A animacao fica no ultimo quadro ao acabar:
## e o que um `morrer` precisa.
func tocar(acao: String, direcao: Vector2) -> bool:
	if sprite_frames == null:
		return false
	if direcao.length_squared() > 0.0001:
		_direcao = setor(direcao)
	var nome := "%s_%s" % [acao, _direcao]
	if not sprite_frames.has_animation(nome):
		return false
	sprite_frames.set_animation_loop(nome, false)
	speed_scale = 1.0
	_acao = acao
	_uma_vez = true
	play(nome)
	return true

func _ao_terminar() -> void:
	if not _uma_vez:
		return
	_uma_vez = false
	terminou.emit(_acao)

## Mostra, parado, o ultimo quadro de `acao` na direcao dada - a pose final de
## uma animacao, como o morto no chao do `morrer`. Devolve `false`, sem mexer
## em nada, se a folha nao a tem. Nao emite `terminou`. (`stop()` voltaria ao
## quadro 0; por isso `pause()`.)
func ultimo_quadro(acao: String, direcao: Vector2) -> bool:
	if sprite_frames == null:
		return false
	var nome := "%s_%s" % [acao, setor(direcao)]
	if not sprite_frames.has_animation(nome):
		return false
	_uma_vez = false
	_acao = acao
	animation = nome
	pause()
	set_frame_and_progress(sprite_frames.get_frame_count(nome) - 1, 0.0)
	return true

## O setor de 45 graus em que o vetor cai. `south` do PixelLab e "de frente
## para quem olha" = +Y no Godot.
static func setor(direcao: Vector2) -> String:
	var fatia := int(roundf(direcao.angle() / (TAU / 8.0)))
	return SETORES[posmod(fatia, 8)]

## Le o JSON e o PNG uma vez e monta o SpriteFrames. Devolve vazio se nao deu.
static func _montar(caminho: String, fps: float) -> Dictionary:
	if caminho in _folhas:
		return _folhas[caminho]
	if caminho.is_empty() or not FileAccess.file_exists(caminho):
		push_error("boneco: folha nao encontrada: %s" % caminho)
		return {}
	var layout = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not layout is Dictionary or not "spritesheet" in layout:
		push_error("boneco: %s nao e um layout do PixelLab" % caminho)
		return {}
	var folha_png: Dictionary = layout["spritesheet"]
	var png := load(caminho.get_base_dir().path_join(folha_png["path"])) as Texture2D
	if png == null:
		push_error("boneco: nao carreguei o PNG de %s" % caminho)
		return {}
	var celula := Vector2i(int(folha_png["cell_size"]["width"]), int(folha_png["cell_size"]["height"]))

	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var fundo_do_sul := float(celula.y)
	for linha in folha_png["rows"]:
		var y := int(linha["row"]) * celula.y
		if linha["type"] == "rotations":
			var direcoes: Array = linha["directions"]
			for i in direcoes.size():
				var parado := "parado_%s" % NOME_DA_DIRECAO[direcoes[i]]
				frames.add_animation(parado)
				frames.set_animation_loop(parado, true)
				frames.add_frame(parado, _celula(png, Rect2i(i * celula.x, y, celula.x, celula.y)))
				if direcoes[i] == "south":
					fundo_do_sul = _fundo(png, Rect2i(i * celula.x, y, celula.x, celula.y))
			continue
		var acao := _sem_versao(linha["animation"])
		var nome := "%s_%s" % [acao, NOME_DA_DIRECAO[linha["direction"]]]
		frames.add_animation(nome)
		frames.set_animation_loop(nome, true)
		frames.set_animation_speed(nome, fps)
		for i in int(linha["frame_count"]):
			frames.add_frame(nome, _celula(png, Rect2i(i * celula.x, y, celula.x, celula.y)))

	# Pivo no centro da celula; o deslocamento poe o pe do sul em y = 0 do pai,
	# e quem chama soma o `pe`.
	var montada := {
		"frames": frames,
		"offset": Vector2(0.0, -(fundo_do_sul - float(celula.y) / 2.0)),
	}
	_folhas[caminho] = montada
	return montada

static func _celula(png: Texture2D, regiao: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = png
	atlas.region = Rect2(regiao)
	return atlas

## A linha de baixo do desenho dentro da celula (o pe), em px a partir do topo
## da celula. Le a imagem da textura, uma vez por folha.
static func _fundo(png: Texture2D, regiao: Rect2i) -> float:
	var imagem := png.get_image()
	if imagem == null:
		return float(regiao.size.y)
	var ocupado := imagem.get_region(regiao).get_used_rect()
	return float(ocupado.end.y)

## `andar-v3` -> `andar`. O sufixo de versao e do PixelLab; o jogo pede a acao.
static func _sem_versao(nome: String) -> String:
	var i := nome.rfind("-v")
	if i > 0 and nome.substr(i + 2).is_valid_int():
		return nome.left(i)
	return nome
