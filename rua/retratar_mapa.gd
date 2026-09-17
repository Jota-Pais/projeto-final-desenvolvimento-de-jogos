extends Node
## Ferramenta. **Rode esta cena (F6) para gerar a imagem do mapa inteiro.**
##
## Ela monta a rua de verdade, afasta a camera ate o mundo caber na tela, escreve
## o nome de cada lugar em cima dele e salva um PNG. Nao e um desenho a parte que
## precisa ser mantido em sincronia: **e o mapa que esta no jogo, retratado**.
## Mexeu no mapa, roda de novo e a figura esta atualizada.
##
## Serve para tres coisas, e a terceira e a que paga:
##
##  - ver de uma vez o que so se ve andando 1,4 km;
##  - conferir a olho o que o `conferir_mapa.tscn` confere por numero;
##  - **o GDD.** O criterio de maior peso dele (4 de 10) e "tem ilustracoes,
##    diagramas, desenhos, tabelas e recursos visuais que ajudam a explicar e a
##    consultar". Um mapa legendado e exatamente isso, e sai daqui de graca.
##
## **Nao roda em headless**: capturar a tela precisa de renderizador de verdade.
## No editor e F6 e pronto.

const Mapa := preload("res://rua/mapa.gd")
const CENA_DA_RUA := preload("res://rua/rua.tscn")

## Onde o PNG e salvo, dentro do projeto. Fica junto dos outros documentos de
## design de proposito - e um deles.
##
## O `design/` tem um **`.gdignore`**, e ele nao e opcional: sem isso o Godot
## importa o PNG como textura, cria um `.import` do lado, e a partir da **o
## proximo save falha** com "Can't save PNG at path". Nada na pasta design e
## usado pelo jogo, entao ignorar a pasta inteira e o certo de qualquer jeito.
const ARQUIVO := "res://design/mapa.png"

## Folga em volta do mundo (ou do recorte) na moldura, para nao ficar encostado
## na borda.
const FOLGA := 1.06

## Recorte por argumento (17/09/2026, P13): sem "--regiao=X" na linha de
## comando (depois do "--" do Godot), retrata o MUNDO inteiro, como sempre -
## e o que a revisao visual pede: `design/mapa.png` (mundo), mais tres perto
## (`design/mapa-bairro.png`, `mapa-centro.png`, `mapa-transicao.png`), sem
## precisar de tres ferramentas. Nomes validos: ver `_rect_da_regiao`.
##
## Cada regiao e um Rect2 **derivado** de `Mapa` (lugar ou coordenada ja
## nomeada em `mapa.gd`/`lugares.gd`), nunca um numero solto sem fonte.
var _regiao := ""
var _rect_do_retrato: Rect2
var _arquivo := ARQUIVO

var _rua: Node
var _legenda: Control
var _quadros := 0
var _salvou := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if (arg as String).begins_with("--regiao="):
			_regiao = (arg as String).trim_prefix("--regiao=")

	_rua = CENA_DA_RUA.instantiate()
	add_child(_rua)
	_rect_do_retrato = _rect_da_regiao(_regiao)
	if _regiao != "":
		_arquivo = "res://design/mapa-%s.png" % _regiao

	# A figura e do mapa, nao do jogo rodando: sem HUD por cima, sem o dia
	# passando e sem zumbi com cone de visao poluindo a geografia.
	(_rua.get_node("Hud") as CanvasLayer).visible = false
	_rua.get_node("Relogio").set_process(false)
	_rua.get_node("Cenario").povoa_por_proximidade = false
	for zumbi in get_tree().get_nodes_in_group("zumbi"):
		(zumbi as Node2D).visible = false

	_montar_legenda()

func _process(_delta: float) -> void:
	_quadros += 1
	# Um quadro para a camera assentar, outro para o cenario desenhar.
	if _quadros == 2:
		_afastar_a_camera()
		return
	if _salvou or _quadros < 6:
		return
	_salvou = true
	_salvar()

## O retangulo de uma regiao nomeada, **derivado** de `Mapa` - nunca um
## numero solto. "" (sem argumento) e o mundo inteiro, de sempre.
func _rect_da_regiao(nome: String) -> Rect2:
	match nome:
		"bairro":
			# O loteamento inteiro (laco, U, beco, quadras) com folga de
			# contexto - mostra a rede toda de uma vez.
			return (Mapa.lugar("bairro")["rect"] as Rect2).grow(500.0)
		"centro":
			# O miolo comercial da cidade: cotovelo da Avenida Central
			# (x 19600), a fita comercial ao norte dela e a delegacia/o
			# mercado ao sul e a leste.
			return Rect2(15800.0, 5900.0, 8200.0, 4800.0)
		"transicao":
			# Do sitio do norte (aberto, dentro do que e nominalmente "mata
			# do norte") ate o anel fechado dela, mais ao norte - a mesma
			# mata que P10 restringiu a uma faixa perto da borda do MUNDO.
			return Rect2(6800.0, 0.0, 5200.0, 4200.0)
		_:
			return Mapa.MUNDO

## Afasta a camera ate a regiao pedida caber, seja qual for a resolucao da
## janela. O zoom sai da conta, e nao de um numero escrito na mao: mudar o
## tamanho do mundo (ou do recorte) ou da janela nao quebra a figura.
func _afastar_a_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var tela := Vector2(get_viewport().get_visible_rect().size)
	var alvo := _rect_do_retrato.size * FOLGA
	var zoom := minf(tela.x / alvo.x, tela.y / alvo.y)

	# Os limites da camera sao os do mundo, e com o zoom afastado eles a
	# empurrariam de volta para dentro. Fora com eles, so para o retrato.
	camera.limit_left = -1000000
	camera.limit_top = -1000000
	camera.limit_right = 1000000
	camera.limit_bottom = 1000000
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2.ONE * zoom
	# A camera e filha do jogador, entao quem se move e ele.
	(_rua.get_node("Jogador") as Node2D).global_position = _rect_do_retrato.get_center()

func _salvar() -> void:
	var imagem := get_viewport().get_texture().get_image()
	var erro := imagem.save_png(_arquivo)
	if erro != OK:
		# Uma segunda tentativa: rodando o retrato logo depois de outra rodada
		# do Godot, o arquivo as vezes ainda esta preso pelo processo anterior e
		# o save falha com "Can't save PNG at path". Na segunda vez passa.
		erro = imagem.save_png(_arquivo)
	if erro != OK:
		push_error("nao deu para salvar %s (erro %d) - tente de novo" % [_arquivo, erro])
	else:
		print("mapa salvo em %s" % ProjectSettings.globalize_path(_arquivo))
		print("%d x %d px, para uma area de %.2f km x %.2f km" % [
			imagem.get_width(), imagem.get_height(),
			_rect_do_retrato.size.x / 40000.0, _rect_do_retrato.size.y / 40000.0])
	if not Engine.is_editor_hint():
		get_tree().quit(0 if erro == OK else 1)

## A legenda vive numa CanvasLayer porque ela e desenhada em **coordenada de
## tela**, e nao de mundo: com a camera afastada 30x, uma fonte de 14 px viraria
## meio pixel. Ela converte a posicao de cada lugar pela transformada do canvas.
func _montar_legenda() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 2
	add_child(camada)
	_legenda = Control.new()
	_legenda.set_anchors_preset(Control.PRESET_FULL_RECT)
	_legenda.set_script(preload("res://rua/legenda_do_mapa.gd"))
	camada.add_child(_legenda)
