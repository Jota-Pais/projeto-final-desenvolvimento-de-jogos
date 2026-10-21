extends RefCounted
## O que o jogador ja viu da cidade (21/10/2026), para o mapa do M
## (rua/tela_do_mapa.gd). Joao: "no mapa vai aparecer so as regioes do mapa que
## o personagem ja viu"; questionario: conta como visto **o que passou na
## tela**.
##
## E uma grade de CELULA px de mundo sobre o mapa inteiro. A grade mora em
## `Travessia.mapa_visto` - atravessa os dias da partida e zera na partida nova
## (`comecar_partida`, `recomecar`) -, ja no formato da neblina do mapa: dois
## bytes por celula (LA8), o branco e a opacidade da neblina; 255 e nunca
## visto, 0 e visto. Assim a textura da neblina sai dos bytes sem conta.

const Mapa := preload("res://rua/mapa.gd")

## O lado da celula, em px de mundo: com 64 a borda da neblina saia em degrau
## grande no mapa aproximado.
const CELULA := 32.0

static func tamanho() -> Vector2i:
	return Vector2i(ceili(Mapa.MUNDO.size.x / CELULA), ceili(Mapa.MUNDO.size.y / CELULA))

## A grade, criada inteira por ver na primeira vez.
static func _grade() -> PackedByteArray:
	var t := tamanho()
	if Travessia.mapa_visto.size() != t.x * t.y * 2:
		var nova := PackedByteArray()
		nova.resize(t.x * t.y * 2)
		nova.fill(255)
		Travessia.mapa_visto = nova
	return Travessia.mapa_visto

## Marca como visto tudo que encosta em `area` (mundo). A grade e copiada uma
## vez, mexida e devolvida: mexer celula a celula no Travessia copiaria o
## array inteiro a cada uma.
static func marcar(area: Rect2) -> void:
	var t := tamanho()
	var grade := _grade()
	var de := Vector2i((area.position / CELULA).floor()).clamp(Vector2i.ZERO, t - Vector2i.ONE)
	var ate := Vector2i((area.end / CELULA).floor()).clamp(Vector2i.ZERO, t - Vector2i.ONE)
	var mudou := false
	for y in range(de.y, ate.y + 1):
		for x in range(de.x, ate.x + 1):
			var i := (y * t.x + x) * 2 + 1
			if grade[i] != 0:
				grade[i] = 0
				mudou = true
	if mudou:
		Travessia.mapa_visto = grade

## Se o ponto (mundo) ja foi visto.
static func visto(ponto: Vector2) -> bool:
	var t := tamanho()
	var c := Vector2i((ponto / CELULA).floor())
	if c.x < 0 or c.y < 0 or c.x >= t.x or c.y >= t.y:
		return false
	return _grade()[(c.y * t.x + c.x) * 2 + 1] == 0

## Quantas celulas ja foram vistas (o conferidor le).
static func quantas_vistas() -> int:
	var grade := _grade()
	var n := 0
	for i in range(1, grade.size(), 2):
		if grade[i] == 0:
			n += 1
	return n

## A neblina como textura: uma celula por pixel, transparente onde ja se viu.
static func neblina() -> ImageTexture:
	var t := tamanho()
	return ImageTexture.create_from_image(Image.create_from_data(t.x, t.y, false, Image.FORMAT_LA8, _grade()))
