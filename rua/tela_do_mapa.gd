extends CanvasLayer
## O mapa do M (21/10/2026). Joao: "quero que crie um mapa, que quando o cara
## apertar M aparece, e no mapa vai aparecer so as regioes do mapa que o
## personagem ja viu". Questionario:
##
##  - **desenho simples**: as cores chapadas do desenho do mapa - rua
##    cinza-escuro, calcada clara, grama verde, predio marrom, agua azul;
##  - **visto e o que passou na tela** (rua/mapa_visto.gd): este no marca, a
##    cada quadro, o retangulo que a camera mostra - mapa aberto ou nao;
##  - **o jogo nao para** com o mapa aberto, como na mochila: o relogio corre
##    e o zumbi anda enquanto voce olha;
##  - marca **voce** (a seta para onde ele olha), **a sua casa**, **o nome dos
##    lugares ja vistos** e **o objetivo** do tutorial.
##
## O que nunca se viu fica debaixo da neblina. O mapa abre enquadrando o que
## ja se viu (o bairro do tutorial nao fica um ponto no meio do mapa
## inteiro); o scroll aproxima e afasta - com o mapa aberto ele e do mapa, nao
## da mao. Fecha no M, no Esc, ao abrir a mochila e na cena de roteiro.

const Mapa := preload("res://rua/mapa.gd")
const Chao := preload("res://rua/chao_da_cidade.gd")
const Construcao := preload("res://rua/construcao.gd")
const MapaVisto := preload("res://rua/mapa_visto.gd")
const TelaDaMochila := preload("res://rua/tela_da_mochila.gd")

const COR_DO_FUNDO := Color(0.0, 0.0, 0.0, 0.62)
const COR_DA_GRAMA := Color("3e4a2f")
const COR_POR_CLASSE := {
	"mata": Color("2f3b25"), "milho": Color("7d6e3c"), "terra": Color("6a543a"), "agua": Color("3f6b84"),
	"horta": Color("50633a"), "gramado": Color("4a5a36"), "grama": Color("3e4a2f"),
}
## As camadas do chao da cidade (rua/chao_da_cidade.gd), na ordem em que se
## pintam.
const COR_POR_CAMADA := [
	["cidade", Color("5b4f40")], ["baldio", Color("5b4f40")], ["quintal", Color("4d5836")],
	["patio", Color("6f6c66")], ["calcada", Color("8b8880")], ["asfalto", Color("38393c")],
]
const COR_DO_PREDIO := Color("7b5b45")
const COR_DA_SUA_CASA := Color("b0743c")
const COR_DA_BEIRA := Color("2a211b")
const COR_DO_MURO := Color(0.12, 0.1, 0.08, 0.85)
const COR_DA_NEBLINA := Color("16181b")
const COR_DA_MOLDURA := Color(0.82, 0.76, 0.6, 0.7)
const COR_DO_TEXTO := Color("e8e2d0")
const COR_DA_SETA := Color("f2d16b")
const COR_DO_OBJETIVO := Color(0.91, 0.69, 0.38, 0.95)

## A distancia da borda da tela ate o mapa, e o espaco do rodape.
const MARGEM := 36.0
const RODAPE := 26.0
## O menor pedaco de mundo que o mapa mostra (px de mundo de largura): mais
## perto que isto o bairro vira borrao.
const MENOR_VISTA := 3600.0
## Quanto alem do que ja se viu o enquadramento abre.
const FOLGA := 900.0
## O passo do scroll no zoom.
const PASSO_DO_ZOOM := 1.25
## De quanto em quanto tempo o mapa aberto se refaz (a seta anda, a neblina
## abre).
const REDESENHO := 0.15

## Se o mapa esta aberto (estatica, como a da mochila: quem anda olha).
static var aberto := false

## O desfoque da borda da neblina: a media da opacidade em volta (5 x 5
## amostras de 3/4 de celula), na cor da neblina.
const NEBLINA_DESFIADA := """
shader_type canvas_item;
uniform vec4 cor : source_color;
void fragment() {
	float a = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			a += texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * 0.75).a;
		}
	}
	COLOR = vec4(cor.rgb, a / 25.0);
}
"""

var _quadro: Control
var _janela: Control
var _nevoa: Control
var _marcas_no: Control
## Do mundo para a janela, no ultimo desenho (a neblina e as marcas usam).
var _para_a_tela := Transform2D()
var _malhas := {}
var _naturais: Array = []
var _neblina: ImageTexture
var _tempo := 0.0
var _ultima_vista := Rect2()
## O retangulo (mundo) que contem tudo que ja se viu.
var _caixa_vista := Rect2()
## O zoom do scroll: 1 e o enquadramento do que ja se viu.
var _zoom := 1.0

func _ready() -> void:
	layer = 5
	aberto = false
	_quadro = Control.new()
	_quadro.name = "Quadro"
	_quadro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quadro.visible = false
	_quadro.draw.connect(_desenhar_o_quadro)
	add_child(_quadro)
	_janela = Control.new()
	_janela.name = "Janela"
	_janela.clip_contents = true
	_janela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_janela.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_janela.draw.connect(_desenhar_o_mapa)
	_quadro.add_child(_janela)
	# A neblina numa camada propria, com o desfoque do NEBLINA_DESFIADA (a
	# grade e de celula: sem ele a borda do que se viu sai em degrau), e as
	# marcas numa camada por cima dela.
	_nevoa = Control.new()
	_nevoa.name = "Neblina"
	_nevoa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nevoa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nevoa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shader := Shader.new()
	shader.code = NEBLINA_DESFIADA
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("cor", COR_DA_NEBLINA)
	_nevoa.material = material
	_nevoa.draw.connect(_desenhar_a_neblina)
	_janela.add_child(_nevoa)
	_marcas_no = Control.new()
	_marcas_no.name = "Marcas"
	_marcas_no.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_marcas_no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marcas_no.draw.connect(_desenhar_as_marcas)
	_janela.add_child(_marcas_no)
	_caixa_vista = _caixa_do_que_se_viu()

func _exit_tree() -> void:
	aberto = false

func _jogador() -> Node2D:
	return get_tree().get_first_node_in_group("jogador") as Node2D

func _sob_roteiro() -> bool:
	var jogador := _jogador()
	return jogador != null and bool(jogador.get("no_roteiro"))

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("mapa"):
		if aberto:
			_fechar()
		elif not TelaDaMochila.aberta and not _sob_roteiro():
			_abrir()
		get_viewport().set_input_as_handled()
		return
	if not aberto:
		return
	if evento.is_action_pressed("ui_cancel"):
		_fechar()
		get_viewport().set_input_as_handled()
		return
	var botao := evento as InputEventMouseButton
	if botao != null and botao.pressed and botao.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_zoom *= PASSO_DO_ZOOM if botao.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / PASSO_DO_ZOOM
		_zoom = clampf(_zoom, 0.05, 4.0)
		_janela.queue_redraw()
		get_viewport().set_input_as_handled()

func _abrir() -> void:
	if _malhas.is_empty():
		_montar()
	aberto = true
	_zoom = 1.0
	_neblina = MapaVisto.neblina()
	_tempo = REDESENHO
	_quadro.visible = true
	_quadro.queue_redraw()
	_janela.queue_redraw()

func _fechar() -> void:
	aberto = false
	_quadro.visible = false

func _process(delta: float) -> void:
	_marcar_o_que_a_camera_ve()
	if not aberto:
		return
	if TelaDaMochila.aberta or _sob_roteiro():
		_fechar()
		return
	_tempo -= delta
	if _tempo <= 0.0:
		_tempo = REDESENHO
		_neblina = MapaVisto.neblina()
		_janela.queue_redraw()

## O que a camera mostra agora fica visto. So conta de novo quando a vista
## andou um pouco.
func _marcar_o_que_a_camera_ve() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var tamanho := get_viewport().get_visible_rect().size / camera.zoom
	var vista := Rect2(camera.get_screen_center_position() - tamanho / 2.0, tamanho)
	if vista.position.distance_to(_ultima_vista.position) < 16.0 and vista.size.is_equal_approx(_ultima_vista.size):
		return
	_ultima_vista = vista
	MapaVisto.marcar(vista)
	_caixa_vista = vista if _caixa_vista.size == Vector2.ZERO else _caixa_vista.merge(vista)

## O retangulo do que ja se viu, lido da grade (uma vez, ao abrir a rua: o
## que os dias de antes descobriram).
func _caixa_do_que_se_viu() -> Rect2:
	var t := MapaVisto.tamanho()
	var grade: PackedByteArray = Travessia.mapa_visto
	if grade.size() != t.x * t.y * 2:
		return Rect2()
	var de := t
	var ate := Vector2i(-1, -1)
	for y in t.y:
		for x in t.x:
			if grade[(y * t.x + x) * 2 + 1] == 0:
				de = Vector2i(mini(de.x, x), mini(de.y, y))
				ate = Vector2i(maxi(ate.x, x), maxi(ate.y, y))
	if ate.x < 0:
		return Rect2()
	return Rect2(Vector2(de) * MapaVisto.CELULA, Vector2(ate - de + Vector2i.ONE) * MapaVisto.CELULA)

## As malhas do chao da cidade e os poligonos naturais, uma vez.
func _montar() -> void:
	var camadas := Chao.camadas()
	for par in COR_POR_CAMADA:
		var camada: Dictionary = camadas[par[0]]
		var v: PackedVector2Array = camada["v"]
		if v.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_INDEX] = camada["t"]
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_malhas[par[0]] = malha
	for p in Mapa.mundo()["poligonos"]:
		if COR_POR_CLASSE.has(p["classe"]):
			_naturais.append(p)
	_naturais.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["area"]) > float(b["area"]))

## A janela do mapa na tela (o quadro inteiro menos a margem e o rodape).
func _retangulo_da_janela() -> Rect2:
	var tela := _quadro.get_viewport_rect().size
	return Rect2(Vector2.ONE * MARGEM, tela - Vector2.ONE * MARGEM * 2.0 - Vector2(0.0, RODAPE))

## O pedaco de mundo que a janela mostra: o que ja se viu com folga, na
## proporcao da janela, vezes o zoom do scroll, sem passar do mapa inteiro.
func _vista(janela: Vector2) -> Rect2:
	var caixa := _caixa_vista.grow(FOLGA) if _caixa_vista.size != Vector2.ZERO else Mapa.MUNDO
	var largura := maxf(caixa.size.x, caixa.size.y * janela.x / janela.y)
	largura = clampf(largura / _zoom, MENOR_VISTA, Mapa.MUNDO.size.x * 1.1)
	var tamanho := Vector2(largura, largura * janela.y / janela.x)
	return Rect2(caixa.get_center() - tamanho / 2.0, tamanho)

func _desenhar_o_quadro() -> void:
	var tela := _quadro.get_viewport_rect().size
	_quadro.draw_rect(Rect2(Vector2.ZERO, tela), COR_DO_FUNDO)
	var janela := _retangulo_da_janela()
	_janela.position = janela.position
	_janela.size = janela.size
	_quadro.draw_rect(janela.grow(3.0), COR_DA_MOLDURA, false, 2.0)
	var fonte := ThemeDB.fallback_font
	var rodape := "MAPA  —  o que você já viu          [scroll] aproximar          [M] fechar"
	# O rodape numa faixa escura propria: por baixo dele passa a HUD.
	_quadro.draw_rect(Rect2(Vector2(janela.position.x - 3.0, janela.end.y + 3.0), Vector2(janela.size.x + 6.0, RODAPE)), Color(0.05, 0.05, 0.06, 0.95))
	_quadro.draw_string(fonte, Vector2(janela.position.x + 6.0, janela.end.y + 21.0), rodape,
		HORIZONTAL_ALIGNMENT_LEFT, janela.size.x, 14, COR_DO_TEXTO)

func _desenhar_o_mapa() -> void:
	var tamanho := _janela.size
	if tamanho.x < 10.0 or tamanho.y < 10.0:
		return
	var vista := _vista(tamanho)
	var k := tamanho.x / vista.size.x
	var para_a_tela := Transform2D(0.0, Vector2(k, k), 0.0, -vista.position * k)
	_para_a_tela = para_a_tela
	_nevoa.queue_redraw()
	_marcas_no.queue_redraw()
	_janela.draw_rect(Rect2(Vector2.ZERO, tamanho), COR_DA_NEBLINA)

	_janela.draw_set_transform_matrix(para_a_tela)
	_janela.draw_rect(Mapa.MUNDO, COR_DA_GRAMA)
	for p in _naturais:
		var pontos: PackedVector2Array = p["pontos"]
		if pontos.size() >= 3:
			_janela.draw_colored_polygon(pontos, COR_POR_CLASSE[p["classe"]])
		for furo in p["furos"]:
			if (furo as PackedVector2Array).size() >= 3:
				_janela.draw_colored_polygon(furo, COR_DA_GRAMA)
	for par in COR_POR_CAMADA:
		var malha: ArrayMesh = _malhas.get(par[0])
		if malha != null:
			_janela.draw_mesh(malha, null, Transform2D(), par[1])
	for construcao in Mapa.mundo()["construcoes"]:
		var cor := COR_DA_SUA_CASA if construcao.get("sua", false) else COR_DO_PREDIO
		for piso in Construcao.pisos_de(construcao):
			_janela.draw_rect(piso, cor)
			_janela.draw_rect(piso, COR_DA_BEIRA, false, 1.0 / k)
	for barreira in Mapa.mundo()["barreiras"]:
		var pontos := PackedVector2Array(barreira["pontos"])
		if pontos.size() >= 2:
			_janela.draw_polyline(pontos, COR_DO_MURO, 1.5 / k)
	_janela.draw_set_transform_matrix(Transform2D())

## A neblina por cima do que nunca se viu: a textura tem uma celula por pixel
## e o shader desfia a borda. Fora do mapa (a rua que continua depois da
## borda) e neblina sempre.
func _desenhar_a_neblina() -> void:
	var tamanho := _janela.size
	var k := _para_a_tela.get_scale().x
	var mundo_na_tela := Rect2(_para_a_tela * Mapa.MUNDO.position, Mapa.MUNDO.size * k)
	if _neblina != null:
		_nevoa.draw_texture_rect(_neblina, mundo_na_tela, false)
	var fora := Rect2(Vector2.ZERO, tamanho).grow(4.0)
	for r in [Rect2(fora.position, Vector2(fora.size.x, mundo_na_tela.position.y - fora.position.y)),
			Rect2(Vector2(fora.position.x, mundo_na_tela.end.y), Vector2(fora.size.x, fora.end.y - mundo_na_tela.end.y)),
			Rect2(Vector2(fora.position.x, mundo_na_tela.position.y), Vector2(mundo_na_tela.position.x - fora.position.x, mundo_na_tela.size.y)),
			Rect2(Vector2(mundo_na_tela.end.x, mundo_na_tela.position.y), Vector2(fora.end.x - mundo_na_tela.end.x, mundo_na_tela.size.y))]:
		if r.size.x > 0.0 and r.size.y > 0.0:
			_nevoa.draw_rect(r, COR_DA_NEBLINA)

## Os nomes dos lugares ja vistos, a sua casa, o objetivo e voce.
func _desenhar_as_marcas() -> void:
	var para_a_tela := _para_a_tela
	var fonte := ThemeDB.fallback_font
	for lugar in Mapa.lugares():
		var rect: Rect2 = lugar["rect"]
		var centro := rect.get_center()
		# Visto se qualquer pedaco do lugar ja passou na tela: o meio ou um
		# dos quatro cantos de dentro.
		var meio := rect.grow_individual(-rect.size.x * 0.25, -rect.size.y * 0.25, -rect.size.x * 0.25, -rect.size.y * 0.25)
		var algum := false
		for p in [centro, meio.position, meio.end, Vector2(meio.position.x, meio.end.y), Vector2(meio.end.x, meio.position.y)]:
			if MapaVisto.visto(p):
				algum = true
				break
		if not algum:
			continue
		var nome: String = lugar["nome"]
		if nome == "sua casa":
			nome = "Sua casa"
		_nome(fonte, para_a_tela * centro, nome, COR_DA_SUA_CASA.lightened(0.4) if nome == "Sua casa" else COR_DO_TEXTO)
	var objetivo := _objetivo()
	if not is_nan(objetivo.x):
		var p := para_a_tela * objetivo
		var pulso := 6.0 + 2.0 * sin(Time.get_ticks_msec() / 200.0)
		_marcas_no.draw_arc(p, pulso, 0.0, TAU, 20, COR_DO_OBJETIVO, 2.0)
		_marcas_no.draw_circle(p, 2.5, COR_DO_OBJETIVO)
	var jogador := _jogador()
	if jogador != null:
		var p := para_a_tela * jogador.global_position
		var olhando: Vector2 = jogador.call("para_onde_olha") if jogador.has_method("para_onde_olha") else Vector2.DOWN
		var seta := PackedVector2Array([Vector2(9, 0), Vector2(-6, -6), Vector2(-3, 0), Vector2(-6, 6)])
		var girada := PackedVector2Array()
		for q in seta:
			girada.append(p + q.rotated(olhando.angle()))
		_marcas_no.draw_colored_polygon(girada, COR_DA_SETA)
		girada.append(girada[0])
		_marcas_no.draw_polyline(girada, Color(0, 0, 0, 0.8), 1.5)

func _nome(fonte: Font, p: Vector2, texto: String, cor: Color) -> void:
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var em := p + Vector2(-largura / 2.0, 4.0)
	_marcas_no.draw_string_outline(fonte, em, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, 0.85))
	_marcas_no.draw_string(fonte, em, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cor)

## Para onde o objetivo do tutorial aponta (mundo), ou NAN sem objetivo.
func _objetivo() -> Vector2:
	var tutorial := get_parent().get_node_or_null("Tutorial")
	if tutorial == null or not is_instance_valid(tutorial) or not tutorial.has_method("alvo_do_objetivo"):
		return Vector2(NAN, NAN)
	return tutorial.alvo_do_objetivo()
