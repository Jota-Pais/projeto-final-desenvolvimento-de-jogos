extends Node2D
## O telhado e a fachada de UMA construcao (21/10/2026), na vista inclinada dos
## muros (rua/barreira.gd): de cima se ve o telhado, e da fachada que olha para
## o sul se ve a parede de frente - com janela, porta, letreiro. As outras tres
## fachadas ficam atras do telhado, como na vida.
##
## A planta vem em volumes (Construcao.volumes_de): o retangulo inteiro, ou as
## colunas de uma planta em L ou T. O volume maior e o principal, com o
## telhado de `telhado`; os outros sao o puxado, mais baixo, com o de
## `puxado`. A fachada de cada volume fica DENTRO da planta, na faixa de baixo
## dele, e o telhado em cima dela - comprimido, e nao levantado: levantado ele
## cobriria quem esta na calcada do outro lado, e a porta norte ficaria
## escondida.
##
## E um no por construcao, irmao do jogador no Y-sort, com a origem na borda
## sul: quem esta na frente (ao sul) desenha por cima da fachada, quem esta
## dentro ou atras fica embaixo do telhado. Quem esconde o telhado de quem
## entrou e o rua/telhados.gd.
##
## Tudo e desenhado por regra (Joao, 21/10/2026: "por regra, custo 0"): as
## texturas em rua/arte/predios (design/desenhar_arquitetura.js), o resto em
## primitivas, com contorno preto fino e cor desbotada, como o molde dos muros.

const Construcao := preload("res://rua/construcao.gd")
const Arquitetura := preload("res://rua/arquitetura.gd")

const MATERIAIS := {
	"romana": preload("res://rua/arte/predios/telha-romana.png"),
	"colonial": preload("res://rua/arte/predios/telha-colonial.png"),
	"fibrocimento": preload("res://rua/arte/predios/fibrocimento.png"),
	"zinco": preload("res://rua/arte/predios/zinco.png"),
	"laje": preload("res://rua/arte/predios/laje.png"),
	"queimada": preload("res://rua/arte/predios/telha-queimada.png"),
}
const PAREDES := {
	"reboco": preload("res://rua/arte/predios/reboco.png"),
	"tijolo": preload("res://rua/arte/predios/tijolo.png"),
	"bloco": preload("res://rua/arte/predios/bloco.png"),
}
const PORTA_DE_CIMA := preload("res://rua/arte/predios/porta.png")

## A luz de cada agua, pela direcao para onde ela cai: o sol vem do sudoeste,
## e a agua norte e a leste ficam na sombra.
const LUZ := { "sul": 1.0, "oeste": 0.93, "norte": 0.8, "leste": 0.74, "plano": 0.95 }
## Quanto o beiral passa da parede.
const BEIRAL := 7.0
const CONTORNO := Color(0.07, 0.06, 0.05, 0.9)
const SOMBRA := Color(0.0, 0.0, 0.0, 0.22)
## A origem fica a PE px acima da borda sul, como a dos bonecos (cenario.gd).
const PE := 10.0
## A cor da cumeeira e dos espigoes por material.
const CUMEEIRA := {
	"romana": Color("7d3f2a"), "colonial": Color("84462c"), "queimada": Color("2a2522"),
	"fibrocimento": Color("b7b5ad"), "zinco": Color("8a8e8c"),
}
const VIDRO := Color("2f3b45")
const CAIXILHO := Color("d6d2c8")
const MADEIRA := Color("6e4a30")
const ESCURO := Color("17130f")

var construcao: Dictionary
var _estilo: Dictionary
var _volumes: Array[Rect2] = []
var _principal := 0
var _sorteio := 0

func montar(qual: Dictionary) -> void:
	construcao = qual
	_estilo = Arquitetura.estilo_de(qual)
	_volumes = Construcao.volumes_de(qual)
	for i in _volumes.size():
		if _volumes[i].get_area() > _volumes[_principal].get_area():
			_principal = i
	var r: Rect2 = qual["rect"]
	_sorteio = Construcao.embaralhar("telhado@%.0f,%.0f" % [r.position.x, r.position.y])
	position = Vector2(0.0, r.end.y - PE)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## O telhado e a fachada de um volume: o principal ou o puxado.
func _telhado_de(i: int) -> Dictionary:
	if i != _principal and _estilo.has("puxado"):
		return _estilo["puxado"]
	return _estilo["telhado"]

func _altura_de(i: int) -> float:
	var fachada: Dictionary = _estilo["fachada"]
	if i != _principal:
		return float(_estilo.get("puxado", {}).get("altura", float(fachada["altura"]) * 0.85))
	return float(fachada["altura"])

func _draw() -> void:
	# Tudo em coordenada de mundo.
	draw_set_transform(Vector2(0.0, -position.y))
	for v in _volumes:
		draw_rect(Rect2(v.end.x, v.position.y + 8.0, 9.0, v.size.y - 8.0), SOMBRA)
	# Os puxados primeiro: o beiral do principal passa por cima deles.
	var ordem: Array[int] = []
	for i in _volumes.size():
		if i != _principal:
			ordem.append(i)
	ordem.append(_principal)
	for i in ordem:
		_desenhar_volume(i)
	var topo := _topo(_principal)
	for extra in _estilo.get("extras", []):
		_extra(extra["tipo"], topo.position + topo.size * (extra["em"] as Vector2), topo)
	_porta_de_cima()
	_nome(topo)

## A parte de cima de um volume: o volume menos a faixa da fachada.
func _topo(i: int) -> Rect2:
	var v := _volumes[i]
	return Rect2(v.position, Vector2(v.size.x, v.size.y - _altura_de(i)))

# --- o volume: telhado e fachada ------------------------------------------------

func _desenhar_volume(i: int) -> void:
	var v := _volumes[i]
	var t := _telhado_de(i)
	var altura := _altura_de(i)
	var topo := _topo(i)
	var forma: String = t.get("forma", "duas_aguas")
	var material: String = t.get("material", "romana")
	var textura: Texture2D = MATERIAIS.get(material, MATERIAIS["romana"])
	var tom: Color = Arquitetura.TONS.get(t.get("tom", "nova"), Color.WHITE)
	var oitao := 0.0
	if forma == "laje":
		_laje(topo, textura, tom)
	else:
		# O beiral: passa da parede a oeste, leste e norte, e cai um pouco por
		# cima da fachada.
		var e := Rect2(topo.position - Vector2(BEIRAL, BEIRAL), topo.size + Vector2(BEIRAL * 2.0, BEIRAL + 3.0))
		var cor_da_cumeeira: Color = CUMEEIRA.get(material, Color("7d3f2a")) * tom
		match forma:
			"quatro_aguas":
				_quatro_aguas(e, textura, tom, cor_da_cumeeira)
			"meia_agua":
				_meia_agua(e, textura, tom, t.get("queda", "sul"), cor_da_cumeeira)
			_:
				var eixo: String = t.get("cumeeira", "")
				if eixo == "":
					eixo = "x" if topo.size.x >= topo.size.y else "y"
				_duas_aguas(e, textura, tom, eixo, cor_da_cumeeira)
				if eixo == "y":
					oitao = minf(v.size.x * 0.26, 64.0)
		_contorno(_cantos(e))
	_fachada(i, Rect2(v.position.x, v.end.y - altura, v.size.x, altura), oitao, forma == "laje")

static func _cantos(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])

func _contorno(pontos: PackedVector2Array) -> void:
	var fechado := PackedVector2Array(pontos)
	fechado.append(pontos[0])
	draw_polyline(fechado, CONTORNO, 1.0)

## Uma agua do telhado: o poligono com a textura girada para a queda apontar
## para `queda`, e a luz daquele lado.
func _agua(pontos: PackedVector2Array, queda: String, textura: Texture2D, tom: Color) -> void:
	var tamanho := textura.get_size()
	var uvs := PackedVector2Array()
	for p in pontos:
		var uv := p
		match queda:
			"norte":
				uv = Vector2(p.x, -p.y)
			"leste":
				uv = Vector2(-p.y, p.x)
			"oeste":
				uv = Vector2(p.y, -p.x)
		uvs.append(uv / tamanho)
	var cor := tom * float(LUZ.get(queda, 1.0))
	cor.a = 1.0
	draw_polygon(pontos, PackedColorArray([cor]), uvs, textura)

func _linha_de_cumeeira(a: Vector2, b: Vector2, cor: Color, largura := 4.0) -> void:
	draw_line(a, b, cor.darkened(0.25), largura + 2.0)
	draw_line(a, b, cor, largura)
	draw_line(a + Vector2(0.0, -1.0), b + Vector2(0.0, -1.0), cor.lightened(0.25), 1.0)

func _duas_aguas(e: Rect2, textura: Texture2D, tom: Color, eixo: String, cumeeira: Color) -> void:
	if eixo == "x":
		# Cumeeira leste-oeste, um pouco ao norte do meio: a agua sul e a que
		# olha para a camera.
		var y := roundf(e.position.y + e.size.y * 0.42)
		_agua(PackedVector2Array([e.position, Vector2(e.end.x, e.position.y), Vector2(e.end.x, y), Vector2(e.position.x, y)]),
			"norte", textura, tom)
		_agua(PackedVector2Array([Vector2(e.position.x, y), Vector2(e.end.x, y), e.end, Vector2(e.position.x, e.end.y)]),
			"sul", textura, tom)
		_linha_de_cumeeira(Vector2(e.position.x, y), Vector2(e.end.x, y), cumeeira)
	else:
		var x := roundf(e.get_center().x)
		_agua(PackedVector2Array([e.position, Vector2(x, e.position.y), Vector2(x, e.end.y), Vector2(e.position.x, e.end.y)]),
			"oeste", textura, tom)
		_agua(PackedVector2Array([Vector2(x, e.position.y), Vector2(e.end.x, e.position.y), e.end, Vector2(x, e.end.y)]),
			"leste", textura, tom)
		_linha_de_cumeeira(Vector2(x, e.position.y), Vector2(x, e.end.y), cumeeira)

func _quatro_aguas(e: Rect2, textura: Texture2D, tom: Color, cumeeira: Color) -> void:
	var a := e.position
	var b := Vector2(e.end.x, e.position.y)
	var c := e.end
	var d := Vector2(e.position.x, e.end.y)
	if e.size.x >= e.size.y:
		var y := roundf(e.position.y + e.size.y * 0.45)
		var recuo := minf(e.size.y * 0.5, e.size.x * 0.5 - 2.0)
		var p := Vector2(e.position.x + recuo, y)
		var q := Vector2(e.end.x - recuo, y)
		_agua(PackedVector2Array([a, b, q, p]), "norte", textura, tom)
		_agua(PackedVector2Array([p, q, c, d]), "sul", textura, tom)
		_agua(PackedVector2Array([a, p, d]), "oeste", textura, tom)
		_agua(PackedVector2Array([b, c, q]), "leste", textura, tom)
		for canto in [[a, p], [d, p], [b, q], [c, q]]:
			_linha_de_cumeeira(canto[0], canto[1], cumeeira, 2.0)
		_linha_de_cumeeira(p, q, cumeeira)
	else:
		var x := roundf(e.get_center().x)
		var recuo := minf(e.size.x * 0.5, e.size.y * 0.5 - 2.0)
		var p := Vector2(x, e.position.y + recuo)
		var q := Vector2(x, e.end.y - recuo)
		_agua(PackedVector2Array([a, b, p]), "norte", textura, tom)
		_agua(PackedVector2Array([q, c, d]), "sul", textura, tom)
		_agua(PackedVector2Array([a, p, q, d]), "oeste", textura, tom)
		_agua(PackedVector2Array([b, c, q, p]), "leste", textura, tom)
		for canto in [[a, p], [b, p], [c, q], [d, q]]:
			_linha_de_cumeeira(canto[0], canto[1], cumeeira, 2.0)
		_linha_de_cumeeira(p, q, cumeeira)

func _meia_agua(e: Rect2, textura: Texture2D, tom: Color, queda: String, cumeeira: Color) -> void:
	_agua(_cantos(e), queda, textura, tom)
	# O rufo na borda alta, e a calha na baixa.
	var alto := { "sul": [e.position, Vector2(e.end.x, e.position.y)], "norte": [Vector2(e.position.x, e.end.y), e.end],
		"leste": [e.position, Vector2(e.position.x, e.end.y)], "oeste": [Vector2(e.end.x, e.position.y), e.end] }
	var baixo := { "sul": [Vector2(e.position.x, e.end.y), e.end], "norte": [e.position, Vector2(e.end.x, e.position.y)],
		"leste": [Vector2(e.end.x, e.position.y), e.end], "oeste": [e.position, Vector2(e.position.x, e.end.y)] }
	var linha: Array = alto.get(queda, alto["sul"])
	draw_line(linha[0], linha[1], cumeeira.lightened(0.15), 3.0)
	linha = baixo.get(queda, baixo["sul"])
	draw_line(linha[0], linha[1], Color(0.0, 0.0, 0.0, 0.35), 3.0)

## Laje: a placa de concreto com a platibanda em volta (a mureta do alto da
## fachada), as manchas de agua parada e o ralo.
func _laje(topo: Rect2, textura: Texture2D, tom: Color) -> void:
	# O concreto da laje e mais claro que o da textura: ela e o piso de
	# dentro, e a laje de cima pega sol.
	var cor := tom * Color(1.3, 1.28, 1.24)
	cor.a = 1.0
	draw_texture_rect(textura, topo, true, cor)
	var r := _sorteio
	# As juntas de dilatacao, a cada 96 px.
	var x := topo.position.x + 96.0
	while x < topo.end.x - 20.0:
		draw_line(Vector2(x, topo.position.y + 6.0), Vector2(x, topo.end.y - 6.0), Color(0, 0, 0, 0.14), 1.0)
		x += 96.0
	var y := topo.position.y + 96.0
	while y < topo.end.y - 20.0:
		draw_line(Vector2(topo.position.x + 6.0, y), Vector2(topo.end.x - 6.0, y), Color(0, 0, 0, 0.14), 1.0)
		y += 96.0
	# Agua parada e o remendo de manta asfaltica.
	for k in 4:
		var p := topo.position + Vector2(float((r >> (k * 5)) % 97) / 97.0, float((r >> (k * 5 + 2)) % 89) / 89.0) * topo.size
		draw_circle(p, 12.0 + float(k) * 7.0, Color(0.12, 0.14, 0.14, 0.14))
	for k in 2:
		var p := topo.position + Vector2(float((r >> (k * 7 + 3)) % 83) / 83.0, float((r >> (k * 7 + 1)) % 79) / 79.0) * (topo.size - Vector2(60, 40))
		draw_rect(Rect2(p + Vector2(10, 10), Vector2(38 + k * 14, 24)), Color(0.2, 0.17, 0.14, 0.38))
		draw_rect(Rect2(p + Vector2(10, 10), Vector2(38 + k * 14, 24)), Color(0.1, 0.08, 0.06, 0.3), false, 1.0)
	# O ralo, no canto que a agua procura.
	var ralo := Vector2(topo.end.x - 16.0, topo.end.y - 16.0)
	draw_rect(Rect2(ralo - Vector2(5, 5), Vector2(10, 10)), Color("3a3a38"))
	for k in 3:
		draw_line(ralo + Vector2(-4, -3 + k * 3), ralo + Vector2(4, -3 + k * 3), Color("6a6a66"), 1.0)
	# O limo verde no pe da mureta, por dentro.
	draw_rect(Rect2(topo.position.x + 6.0, topo.end.y - 12.0, topo.size.x - 12.0, 6.0), Color(0.3, 0.4, 0.2, 0.18))
	draw_rect(Rect2(topo.position.x + 6.0, topo.position.y + 6.0, 6.0, topo.size.y - 12.0), Color(0.3, 0.4, 0.2, 0.14))
	var mureta := 6.0
	var clara := (tom * Color("c9c5bb")).lightened(0.05)
	clara.a = 1.0
	draw_rect(Rect2(topo.position, Vector2(topo.size.x, mureta)), clara)
	draw_rect(Rect2(topo.position, Vector2(mureta, topo.size.y)), clara)
	draw_rect(Rect2(topo.end.x - mureta, topo.position.y, mureta, topo.size.y), clara)
	draw_rect(Rect2(topo.position.x, topo.end.y - mureta, topo.size.x, mureta), clara)
	# A sombra da mureta por dentro, do lado do sol.
	draw_rect(Rect2(topo.position + Vector2(mureta, mureta), Vector2(topo.size.x - mureta * 2.0, 3.0)), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(topo.end.x - mureta - 3.0, topo.position.y + mureta, 3.0, topo.size.y - mureta * 2.0), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(topo.position + Vector2(mureta, mureta), topo.size - Vector2(mureta * 2.0, mureta * 2.0)), Color(0, 0, 0, 0.35), false, 1.0)
	_contorno(_cantos(topo))

# --- a fachada ---------------------------------------------------------------

## A faixa de parede de um volume: textura com a tinta, barrado, a sombra do
## beiral, as janelas por andar, a porta se a fachada dela olha para o sul, e
## o oitao (o triangulo da empena) quando a cumeeira corre norte-sul.
func _fachada(i: int, faixa: Rect2, oitao: float, de_laje: bool) -> void:
	var f: Dictionary = _estilo["fachada"]
	var parede: Texture2D = PAREDES.get(f.get("parede", "reboco"), PAREDES["reboco"])
	var tinta: Color = Color.WHITE
	if f.get("parede", "reboco") == "reboco":
		tinta = Arquitetura.TINTAS.get(f.get("tinta", "branco"), Color.WHITE) * Color(1.12, 1.12, 1.14)
	elif f.get("parede", "reboco") == "bloco":
		tinta = Color(0.92, 0.92, 0.9)
	if construcao.get("queimada", false):
		tinta = tinta * Color(0.45, 0.42, 0.4)
	tinta.a = 1.0
	draw_texture_rect(parede, faixa, true, tinta)
	if oitao > 0.0:
		var triangulo := PackedVector2Array([Vector2(faixa.position.x, faixa.position.y),
			Vector2(faixa.get_center().x, faixa.position.y - oitao), Vector2(faixa.end.x, faixa.position.y)])
		var uvs := PackedVector2Array()
		for p in triangulo:
			uvs.append(p / parede.get_size())
		draw_polygon(triangulo, PackedColorArray([tinta * Color(0.94, 0.94, 0.94)]), uvs, parede)
		# O respiro do sotao e a testeira (a tabua da beira do telhado).
		var meio := Vector2(faixa.get_center().x, faixa.position.y - oitao * 0.38)
		draw_rect(Rect2(meio - Vector2(7.0, 4.0), Vector2(14.0, 8.0)), ESCURO)
		for k in 3:
			draw_line(meio + Vector2(-6.0, -2.0 + k * 2.5), meio + Vector2(6.0, -2.0 + k * 2.5), Color("4a4038"), 1.0)
		var t := _telhado_de(i)
		var testeira: Color = CUMEEIRA.get(t.get("material", "romana"), MADEIRA)
		var a := Vector2(faixa.position.x - BEIRAL, faixa.position.y + 3.0)
		var topo_do_oitao := Vector2(faixa.get_center().x, faixa.position.y - oitao - 3.0)
		var b := Vector2(faixa.end.x + BEIRAL, faixa.position.y + 3.0)
		for lado in [[a, topo_do_oitao], [topo_do_oitao, b]]:
			draw_line(lado[0], lado[1], CONTORNO, 6.0)
			draw_line(lado[0], lado[1], testeira, 4.0)
	# Barrado e a sujeira do pe da parede.
	var barrado = f.get("barrado", null)
	if barrado is Color:
		draw_rect(Rect2(faixa.position.x, faixa.end.y - 11.0, faixa.size.x, 11.0), barrado)
	draw_rect(Rect2(faixa.position.x, faixa.end.y - 4.0, faixa.size.x, 4.0), Color(0.1, 0.08, 0.06, 0.3))
	# A sombra do beiral (ou a mureta da laje, que e a propria parede).
	if de_laje:
		draw_rect(Rect2(faixa.position.x, faixa.position.y, faixa.size.x, 5.0), Color(1, 1, 1, 0.12))
		draw_line(Vector2(faixa.position.x, faixa.position.y + 6.0), Vector2(faixa.end.x, faixa.position.y + 6.0), Color(0, 0, 0, 0.25), 1.0)
	else:
		draw_rect(Rect2(faixa.position.x, faixa.position.y, faixa.size.x, 6.0), Color(0, 0, 0, 0.3))
	if f.get("pichacao", false):
		_pichacao(faixa)
	_janelas_e_porta(i, faixa, f)
	draw_rect(faixa, CONTORNO, false, 1.0)

func _janelas_e_porta(i: int, faixa: Rect2, f: Dictionary) -> void:
	var tipo_de_janela: String = f.get("janelas", "normal")
	var andares := maxi(1, roundi(faixa.size.y / Arquitetura.ALTURA_DE_ANDAR))
	var altura_do_andar := faixa.size.y / float(andares)
	# A porta, se a fachada da porta e esta.
	var porta_x := NAN
	if construcao["porta"] == "sul":
		var porta := Construcao.porta_de(construcao)
		if porta.x > faixa.position.x and porta.x < faixa.end.x and absf(porta.y - faixa.end.y) < Construcao.PAREDE * 2.0:
			porta_x = porta.x
	var largura := 30.0 if tipo_de_janela != "basculante" else 24.0
	var alto := minf(22.0, altura_do_andar * 0.42) if tipo_de_janela != "basculante" else 11.0
	var passo := 92.0
	var quantas := maxi(0, int((faixa.size.x - 40.0) / passo))
	if faixa.size.x >= 120.0:
		quantas = maxi(quantas, 1)
	for andar in andares:
		var y := faixa.end.y - altura_do_andar * (float(andar) + 0.62)
		if tipo_de_janela == "basculante":
			y = faixa.end.y - altura_do_andar * (float(andar) + 0.75)
		for k in quantas:
			var x := faixa.position.x + faixa.size.x * (float(k) + 0.5) / float(quantas)
			if andar == 0 and not is_nan(porta_x) and absf(x - porta_x) < 46.0:
				continue
			var variante := (_sorteio >> ((k * 3 + andar * 7 + i * 11) % 24)) % 7
			_janela(Vector2(roundf(x), roundf(y)), Vector2(largura, alto), tipo_de_janela, variante)
	if not is_nan(porta_x):
		_porta_de_frente(Vector2(roundf(porta_x), faixa.end.y), minf(faixa.size.y - 10.0, 42.0), f)
	var letreiro: String = f.get("letreiro", "")
	if letreiro != "" and i == _principal:
		var centro := Vector2(porta_x if not is_nan(porta_x) else faixa.get_center().x, faixa.position.y + 13.0)
		_placa(centro, letreiro, Color("e9e4d6"), Color("23324a"))

## Uma janela vista de frente, do tipo da casa e com a variante dela (uma de
## cada tanto aberta, quebrada, com cortina): casa de verdade nao tem todas
## as janelas iguais.
func _janela(centro: Vector2, tamanho: Vector2, tipo: String, variante: int) -> void:
	var r := Rect2(centro - tamanho / 2.0, tamanho)
	# A moldura e o peitoril com a sombra dele.
	draw_rect(r.grow(2.0), CAIXILHO.darkened(0.15))
	draw_rect(Rect2(r.position.x - 4.0, r.end.y + 2.0, r.size.x + 8.0, 3.0), Color("cfcbc2"))
	draw_rect(Rect2(r.position.x - 4.0, r.end.y + 5.0, r.size.x + 8.0, 2.0), Color(0, 0, 0, 0.3))
	var vidro := VIDRO
	if tipo == "quebradas" or (tipo != "chapa" and variante == 6):
		draw_rect(r, ESCURO)
		for canto in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y)]:
			var para: Vector2 = (r.get_center() - canto).normalized()
			draw_colored_polygon(PackedVector2Array([canto, canto + Vector2(para.x * 9.0, 0.0), canto + Vector2(0.0, para.y * 7.0)]), VIDRO.lightened(0.2))
		draw_rect(r, CONTORNO, false, 1.0)
		return
	if tipo == "chapa":
		draw_rect(r, Color("6d7072"))
		draw_line(r.position + Vector2(2, r.size.y * 0.5), Vector2(r.end.x - 2, r.position.y + r.size.y * 0.5), Color("55585a"), 1.0)
		for p in [r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3), r.end - Vector2(3, 3), Vector2(r.position.x + 3, r.end.y - 3)]:
			draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), Color("9a9d9e"))
		draw_line(Vector2(r.position.x + 5, r.end.y), Vector2(r.position.x + 7, r.end.y + 8), Color(0.45, 0.25, 0.12, 0.6), 1.0)
		draw_rect(r, CONTORNO, false, 1.0)
		return
	draw_rect(r, vidro)
	# O reflexo do ceu, na diagonal.
	draw_line(r.position + Vector2(3, r.size.y - 3), r.position + Vector2(r.size.y - 3, 3), Color(1, 1, 1, 0.18), 2.0)
	if tipo == "basculante":
		for k in 3:
			draw_line(Vector2(r.position.x, r.position.y + 3 + k * 3), Vector2(r.end.x, r.position.y + 3 + k * 3), CAIXILHO, 1.0)
	else:
		draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), CAIXILHO, 1.0)
	if tipo == "cortina" or variante == 1:
		var pano := Color("a8645a") if variante % 2 == 0 else Color("5f7c9e")
		draw_rect(Rect2(r.position, Vector2(r.size.x * 0.38, r.size.y)), pano)
		draw_rect(Rect2(Vector2(r.end.x - r.size.x * 0.3, r.position.y), Vector2(r.size.x * 0.3, r.size.y)), pano.darkened(0.1))
	if tipo == "tabuas" or variante == 4:
		for k in 2:
			var a := Vector2(r.position.x - 3.0, r.position.y + 4.0 + k * 9.0)
			var b := Vector2(r.end.x + 3.0, r.position.y + 2.0 + k * 9.0 + (4.0 if k == 0 else -2.0))
			draw_line(a, b, CONTORNO, 6.0)
			draw_line(a, b, Color("8a6a46"), 4.0)
			draw_rect(Rect2(a + Vector2(3, -1), Vector2(1, 1)), ESCURO)
			draw_rect(Rect2(b - Vector2(4, 1), Vector2(1, 1)), ESCURO)
	if tipo == "grade" or variante == 3:
		var x := r.position.x + 2.0
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y - 2.0), Vector2(x, r.end.y + 2.0), Color("2b2b2b"), 1.0)
			x += 5.0
		draw_line(Vector2(r.position.x - 2.0, r.get_center().y), Vector2(r.end.x + 2.0, r.get_center().y), Color("2b2b2b"), 1.0)
	draw_rect(r.grow(2.0), CONTORNO, false, 1.0)

## A porta vista de frente, no pe da fachada, com a soleira para fora.
func _porta_de_frente(pe: Vector2, alto: float, f: Dictionary) -> void:
	var largura := 32.0
	var r := Rect2(pe.x - largura / 2.0, pe.y - alto, largura, alto)
	draw_rect(r.grow(2.0), CAIXILHO.darkened(0.2))
	var comercio: bool = construcao["tipo"] not in ["casa", "casa_pequena", "mansao"]
	if comercio:
		# Porta de aco de enrolar, meio levantada: o escuro de dentro embaixo.
		r = Rect2(pe.x - 28.0, pe.y - alto, 56.0, alto)
		draw_rect(r.grow(2.0), Color("5b5e60"))
		draw_rect(r, Color("8b8f90"))
		var y := r.position.y + 2.0
		while y < r.end.y - alto * 0.35:
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("6c7072"), 1.0)
			y += 3.0
		draw_rect(Rect2(r.position.x, r.end.y - alto * 0.35, r.size.x, alto * 0.35), ESCURO)
	else:
		draw_rect(r, MADEIRA)
		draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(largura - 8.0, alto * 0.4)), MADEIRA.darkened(0.2), false, 1.0)
		draw_rect(Rect2(r.position + Vector2(4, alto * 0.52), Vector2(largura - 8.0, alto * 0.4)), MADEIRA.darkened(0.2), false, 1.0)
		draw_rect(Rect2(Vector2(r.end.x - 7.0, r.get_center().y), Vector2(2, 2)), Color("c9b26a"))
	draw_rect(r.grow(2.0), CONTORNO, false, 1.0)
	draw_rect(Rect2(pe.x - largura * 0.8, pe.y, largura * 1.6, 4.0), Color("a9a59c"))
	draw_rect(Rect2(pe.x - largura * 0.8, pe.y, largura * 1.6, 4.0), CONTORNO, false, 1.0)

## Uma placa de letreiro: fundo, borda e o texto centrado.
func _placa(centro: Vector2, texto: String, fundo: Color, letra: Color) -> void:
	var fonte := ThemeDB.fallback_font
	var corpo := 16
	var escala := 0.5
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x * escala + 12.0
	var r := Rect2(centro - Vector2(largura / 2.0, 8.0), Vector2(largura, 16.0))
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, fundo)
	draw_rect(r, CONTORNO, false, 1.0)
	draw_set_transform(Vector2(r.position.x + 6.0, r.position.y + 12.0 - position.y), 0.0, Vector2.ONE * escala)
	draw_string(fonte, Vector2.ZERO, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, letra)
	draw_set_transform(Vector2(0.0, -position.y))

## Pichacao: rabiscos de spray, sem palavra - so a marca de que passou gente.
func _pichacao(faixa: Rect2) -> void:
	var r := _sorteio
	var cores := [Color("1c1c1c"), Color("7a2a2a"), Color("2a4a7a")]
	for k in 4:
		var x := faixa.position.x + 20.0 + float((r >> (k * 4)) % 1000) / 1000.0 * (faixa.size.x - 80.0)
		var y := faixa.end.y - 14.0 - float((r >> (k * 3 + 1)) % 7) * 2.0
		var cor: Color = cores[k % 3]
		var pontos := PackedVector2Array()
		for j in 7:
			pontos.append(Vector2(x + j * 6.0, y - float(((r >> (j + k)) % 5)) * 2.5 - (8.0 if j % 2 == 0 else 0.0)))
		draw_polyline(pontos, cor, 2.0)

# --- o que fica em cima ---------------------------------------------------------

func _extra(tipo: String, p: Vector2, topo: Rect2) -> void:
	p = p.round()
	match tipo:
		"caixa_dagua":
			# A de 1000 litros: 1,4 m de boca, 1 m de altura.
			draw_rect(Rect2(p + Vector2(4, 12), Vector2(30, 8)), Color(0, 0, 0, 0.25))
			draw_rect(Rect2(p + Vector2(-24, -4), Vector2(48, 20)), Color("2c5279"))
			draw_rect(Rect2(p + Vector2(-24, -4), Vector2(10, 20)), Color("3a6694"))
			draw_rect(Rect2(p + Vector2(-24, -4), Vector2(48, 20)), CONTORNO, false, 1.0)
			_elipse(p + Vector2(0, -4), Vector2(24, 13), Color("4479ad"))
			_elipse(p + Vector2(0, -5), Vector2(15, 8), Color("5a8fc2"))
			draw_circle(p + Vector2(0, -5), 3.0, Color("2c5279"))
		"caixa_dagua_tombada":
			draw_rect(Rect2(p + Vector2(-20, -8), Vector2(40, 18)), Color("2c4a68"))
			_elipse(p + Vector2(-20, 1), Vector2(5, 9), Color("4a7aa8"))
			draw_rect(Rect2(p + Vector2(-20, -8), Vector2(40, 18)), CONTORNO, false, 1.0)
		"antena":
			draw_line(p, p + Vector2(0, -34), Color("3a3a3a"), 1.0)
			for k in 4:
				var y := -34.0 + k * 6.0
				draw_line(p + Vector2(-8 + k, y), p + Vector2(8 - k, y), Color("4a4a4a"), 1.0)
			draw_line(p, p + Vector2(10, 4), Color(0, 0, 0, 0.3), 2.0)
		"antena_de_radio":
			for k in 9:
				var y := -k * 11.0
				var cor := Color("b83c32") if k % 2 == 0 else Color("e2dcd0")
				draw_line(p + Vector2(-3, y), p + Vector2(-3, y - 11), cor, 2.0)
				draw_line(p + Vector2(3, y), p + Vector2(3, y - 11), cor, 2.0)
				draw_line(p + Vector2(-3, y), p + Vector2(3, y - 11), Color("777777"), 1.0)
			for estai in [Vector2(-40, 18), Vector2(40, 18), Vector2(0, -20)]:
				draw_line(p + Vector2(0, -70), p + estai, Color(0.2, 0.2, 0.2, 0.5), 1.0)
		"parabolica":
			draw_line(p, p + Vector2(0, -8), Color("444444"), 2.0)
			_elipse(p + Vector2(0, -14), Vector2(11, 8), Color("cfcac0"))
			_elipse(p + Vector2(1, -13), Vector2(7, 5), Color("b3aea4"))
			draw_line(p + Vector2(0, -14), p + Vector2(8, -22), Color("555555"), 1.0)
		"placa_solar", "aquecedor_solar":
			for k in 3:
				var r := Rect2(p + Vector2(-42 + k * 29, -12), Vector2(26, 22))
				draw_rect(r, Color("21324e"))
				for j in range(1, 3):
					draw_line(Vector2(r.position.x + j * 8.6, r.position.y), Vector2(r.position.x + j * 8.6, r.end.y), Color("3a5580"), 1.0)
				draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color("3a5580"), 1.0)
				draw_line(r.position, Vector2(r.end.x, r.position.y), Color(1, 1, 1, 0.25), 1.0)
				draw_rect(r, CONTORNO, false, 1.0)
			if tipo == "aquecedor_solar":
				draw_rect(Rect2(p + Vector2(-40, -22), Vector2(80, 9)), Color("dcd8ce"))
				draw_rect(Rect2(p + Vector2(-40, -22), Vector2(80, 9)), CONTORNO, false, 1.0)
		"chamine":
			draw_circle(p + Vector2(4, 10), 22.0, Color(0.05, 0.04, 0.03, 0.3))
			var frente := Rect2(p + Vector2(-10, -6), Vector2(20, 22))
			draw_texture_rect(PAREDES["tijolo"], frente, true, Color(0.85, 0.8, 0.78))
			draw_rect(Rect2(p + Vector2(-11, -14), Vector2(22, 9)), Color("9a5a3e"))
			draw_rect(Rect2(p + Vector2(-7, -12), Vector2(14, 5)), ESCURO)
			draw_rect(Rect2(p + Vector2(-11, -14), Vector2(22, 30)), CONTORNO, false, 1.0)
		"exaustor":
			draw_rect(Rect2(p + Vector2(-6, 0), Vector2(12, 8)), Color("8d9092"))
			_elipse(p, Vector2(9, 7), Color("c2c5c6"))
			for k in 6:
				var a := TAU * k / 6.0
				draw_line(p, p + Vector2(cos(a) * 8.0, sin(a) * 6.0), Color("7d8183"), 1.0)
		"ar_condicionado":
			draw_rect(Rect2(p + Vector2(-14, -8), Vector2(28, 12)), Color("cfccc4"))
			draw_rect(Rect2(p + Vector2(-14, 4), Vector2(28, 8)), Color("a9a69e"))
			draw_circle(p + Vector2(0, -2), 5.0, Color("4a4a48"))
			draw_rect(Rect2(p + Vector2(-14, -8), Vector2(28, 20)), CONTORNO, false, 1.0)
		"lona":
			var pontos := PackedVector2Array([p + Vector2(-34, -22), p + Vector2(30, -26), p + Vector2(36, 20), p + Vector2(-30, 24)])
			draw_colored_polygon(pontos, Color("2f5d9a"))
			for k in 3:
				draw_line(p + Vector2(-30 + k * 22, -22), p + Vector2(-26 + k * 22, 22), Color("4a78b5"), 2.0)
			_contorno(pontos)
			for k in 4:
				draw_line(pontos[k], pontos[k] + (pontos[k] - p).normalized() * 10.0, Color("c9c2a8"), 1.0)
			_pneu(p + Vector2(-12, -6))
			draw_rect(Rect2(p + Vector2(14, 4), Vector2(10, 6)), Color("9a5a3e"))
		"buraco":
			var pontos := PackedVector2Array([p + Vector2(-22, -10), p + Vector2(-4, -18), p + Vector2(20, -12), p + Vector2(24, 8), p + Vector2(4, 16), p + Vector2(-18, 12)])
			draw_colored_polygon(pontos, ESCURO)
			draw_line(p + Vector2(-20, -2), p + Vector2(22, 0), Color("4a3524"), 3.0)
			draw_line(p + Vector2(-8, -16), p + Vector2(-4, 15), Color("4a3524"), 3.0)
			_contorno(pontos)
			for k in 5:
				draw_rect(Rect2(p + Vector2(-26 + k * 11, 18 - (k % 2) * 34), Vector2(5, 3)), Color("8a4a32"))
		"musgo":
			for k in 6:
				var q := p + Vector2(float((_sorteio >> k) % 31) - 15.0, float((_sorteio >> (k + 3)) % 23) - 11.0)
				draw_circle(q, 5.0 + float(k % 3) * 2.0, Color(0.27, 0.36, 0.18, 0.32))
		"mato":
			for k in 9:
				var q := p + Vector2(float((_sorteio >> k) % 41) - 20.0, float((_sorteio >> (k + 2)) % 25) - 12.0)
				draw_line(q, q + Vector2(-2, -7), Color("4f6b32"), 1.0)
				draw_line(q, q + Vector2(2, -6), Color("62803d"), 1.0)
				draw_line(q, q + Vector2(0, -9), Color("3f5a28"), 1.0)
		"entulho":
			for k in 10:
				var q := p + Vector2(float((_sorteio >> k) % 37) - 18.0, float((_sorteio >> (k + 4)) % 21) - 10.0)
				var cor := Color("8a857b") if k % 3 else Color("9a5a3e")
				draw_rect(Rect2(q, Vector2(5 + k % 4, 3 + k % 3)), cor)
				draw_rect(Rect2(q, Vector2(5 + k % 4, 3 + k % 3)), CONTORNO, false, 1.0)
		"pneu":
			_pneu(p)
		"sacos":
			# O posto de vigia em cima da laje: sacos em U.
			for k in 7:
				var q := p + Vector2(-30.0 + k * 10.0, -14.0)
				_saco(q)
			for k in 3:
				_saco(p + Vector2(-34.0, -4.0 + k * 9.0))
				_saco(p + Vector2(34.0, -4.0 + k * 9.0))
		"concertina":
			# O arame em volta da platibanda inteira.
			var r := topo.grow(-3.0)
			var x := r.position.x
			while x < r.end.x:
				draw_arc(Vector2(x, r.position.y), 4.0, 0.0, TAU, 8, Color(0.78, 0.78, 0.76, 0.8), 1.0)
				draw_arc(Vector2(x, r.end.y), 4.0, 0.0, TAU, 8, Color(0.78, 0.78, 0.76, 0.8), 1.0)
				x += 7.0
			var y := r.position.y
			while y < r.end.y:
				draw_arc(Vector2(r.position.x, y), 4.0, 0.0, TAU, 8, Color(0.78, 0.78, 0.76, 0.8), 1.0)
				draw_arc(Vector2(r.end.x, y), 4.0, 0.0, TAU, 8, Color(0.78, 0.78, 0.76, 0.8), 1.0)
				y += 7.0
		"casa_de_escada":
			var cima := Rect2(p + Vector2(-36, -40), Vector2(72, 44))
			draw_rect(Rect2(cima.end.x, cima.position.y + 6, 6, cima.size.y + 20), SOMBRA)
			draw_texture_rect(MATERIAIS["laje"], cima, true, Color(0.95, 0.95, 0.93))
			var frente := Rect2(cima.position.x, cima.end.y, cima.size.x, 24.0)
			draw_texture_rect(PAREDES["bloco"], frente, true, Color(0.9, 0.9, 0.88))
			draw_rect(Rect2(frente.get_center().x - 9.0, frente.position.y + 4.0, 18.0, 20.0), Color("5b5e60"))
			draw_rect(cima, CONTORNO, false, 1.0)
			draw_rect(frente, CONTORNO, false, 1.0)

func _elipse(centro: Vector2, raios: Vector2, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		pontos.append(centro + Vector2(cos(a) * raios.x, sin(a) * raios.y))
	draw_colored_polygon(pontos, cor)
	_contorno(pontos)

func _pneu(p: Vector2) -> void:
	draw_circle(p, 9.0, Color("1e1d1c"))
	draw_circle(p, 4.0, Color("4a4846"))
	draw_arc(p, 9.0, 0.0, TAU, 16, CONTORNO, 1.0)

func _saco(p: Vector2) -> void:
	var r := Rect2(p - Vector2(5, 4), Vector2(10, 8))
	draw_rect(r, Color("a69a74"))
	draw_line(r.position + Vector2(1, 1), Vector2(r.end.x - 1, r.position.y + 1), Color("c2b78f"), 1.0)
	draw_rect(r, CONTORNO, false, 1.0)

# --- a porta de cima e o nome ----------------------------------------------------

## A porta que nao olha para o sul fica atras do telhado: a marca dela vai na
## beira do beiral, como sempre foi, para dar para achar a entrada.
func _porta_de_cima() -> void:
	if construcao["porta"] == "sul":
		return
	var centro := Construcao.porta_de(construcao)
	var eixo := Construcao.eixo_da_fachada(construcao)
	draw_set_transform(centro - Vector2(0.0, position.y), eixo.angle(), Vector2.ONE)
	draw_texture(PORTA_DE_CIMA, -PORTA_DE_CIMA.get_size() / 2.0)
	draw_set_transform(Vector2(0.0, -position.y))

## O nome do predio no telhado (30/09/2026): o mapa veio de um desenho com
## rotulo em cada coisa. Predio com letreiro de verdade (o toldo da pizzaria)
## nao precisa.
func _nome(topo: Rect2) -> void:
	var nome: String = construcao.get("nome", "")
	if nome == "" or nome.ends_with("(anexo)") or _estilo.has("toldo") or topo.size.x < 200.0:
		return
	var fonte := ThemeDB.fallback_font
	var corpo := 13
	var k := 0.5
	draw_set_transform(topo.position + Vector2(8.0, 6.0 - position.y), 0.0, Vector2.ONE * k)
	draw_string(fonte, Vector2(1.0, 19.0), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, Color(0, 0, 0, 0.5))
	draw_string(fonte, Vector2(0.0, 18.0), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, Color(0.95, 0.9, 0.8, 0.7))
	draw_set_transform(Vector2(0.0, -position.y))
