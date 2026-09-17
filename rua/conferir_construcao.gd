extends Node
## Ferramenta. Rode esta cena (F6) depois de mexer em `construcao.gd`.
##
## Prova que a porta em quatro direcoes (17/09/2026) esta certa para
## leste/oeste - o que a regressao bit a bit contra o mapa de entao (P1,
## removida em P14) nao alcancava, porque nenhuma construcao do mapa usa
## essas duas portas ainda hoje. Monta o MESMO predio sintetico nas 4
## orientacoes e exige:
##
##  a) a uniao das 5 paredes externas mais o vao da porta preenche exatamente o
##     anel do retangulo (sem buraco e sem sobra), amostrado numa grade fina;
##  b) o vao mede exatamente VAO;
##  c) os 3 quartos sao disjuntos e completam o interior, descontadas as
##     divisorias - nenhuma area sobra e nenhuma se sobrepoe;
##  d) a entrada de carro sai encostada na fachada, na direcao do normal;
##  e) girar a geometria da orientacao `sul` 90 graus da a orientacao `oeste`,
##     ponto a ponto - e o mesmo entre `norte` e `leste`. `sul` e `norte` (e
##     `leste` e `oeste`) NAO sao rotacao uma da outra - sao espelho (o
##     determinante da transformacao e -1) -, entao so estes dois pares se
##     provam por rotacao; os outros dois se provam pelas invariantes de
##     area em d).

const Construcao := preload("res://rua/construcao.gd")

const PAREDE := Construcao.PAREDE
const VAO := Construcao.VAO
const PASSO := 7.0  ## nao e divisor exato de nada aqui, de proposito - evita
                     ## amostrar sempre em cima de uma borda.

var _falhas := 0

func _ready() -> void:
	var pivot := Vector2(2000.0, 2000.0)
	var casas := {
		"sul": _casa(pivot, Vector2(600.0, 500.0), "sul"),
		"norte": _casa(pivot, Vector2(600.0, 500.0), "norte"),
		"oeste": _casa(pivot, Vector2(500.0, 600.0), "oeste"),
		"leste": _casa(pivot, Vector2(500.0, 600.0), "leste"),
	}

	for porta in casas:
		_a_uniao_das_paredes_fecha_o_anel(casas[porta], porta)
		_o_vao_mede_vao(casas[porta], porta)
		_os_quartos_completam_o_interior(casas[porta], porta)
		_a_entrada_sai_pela_normal(casas[porta], porta)

	_girar_90_da_a_outra(casas["sul"], casas["oeste"], pivot, "sul -> oeste")
	_girar_90_da_a_outra(casas["norte"], casas["leste"], pivot, "norte -> leste")

	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	get_tree().quit(0 if _falhas == 0 else 1)

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Um predio sintetico de 3 quartos ("casa"), centrado em `pivot`, com o
## tamanho e a porta dados. Nao usa `TAMANHOS`: o tamanho e escolhido para o
## teste (600x500), de proposito assimetrico, para um bug de frente/profundidade
## trocada aparecer como retangulo errado em vez de acidentalmente certo.
func _casa(pivot: Vector2, tamanho: Vector2, porta: String) -> Dictionary:
	return {
		"rect": Rect2(pivot - tamanho / 2.0, tamanho),
		"porta": porta,
		"tipo": "casa",
	}

# --- a) a uniao das paredes fecha o anel ------------------------------------

func _a_uniao_das_paredes_fecha_o_anel(c: Dictionary, porta: String) -> void:
	var rect: Rect2 = c["rect"]
	var interior := Construcao.interior_de(c)
	var paredes := Construcao.paredes_externas(c)
	var vao := _vao_retangulo(c)

	var ruins := 0
	var x := rect.position.x + PASSO / 2.0
	while x < rect.end.x:
		var y := rect.position.y + PASSO / 2.0
		while y < rect.end.y:
			var ponto := Vector2(x, y)
			if not interior.has_point(ponto):
				var cobertas := 0
				for parede in paredes:
					if (parede as Rect2).has_point(ponto):
						cobertas += 1
				var no_vao := vao.has_point(ponto)
				# No vao: NENHUMA parede pode cobrir (senao a porta nao abre).
				# Fora do vao: pelo menos uma parede cobre - o anel nao pode ter
				# buraco. Cobertura dupla existe DE PROPOSITO nos dois cantos
				# do fundo (a parede do fundo e a lateral se encostam ali, e
				# sempre se encostaram, ja no codigo antigo) e nao e falha: a
				# parede continua solida, so teria custo fisico duplicado.
				if no_vao and cobertas > 0:
					ruins += 1
				elif not no_vao and cobertas == 0:
					ruins += 1
			y += PASSO
		x += PASSO

	if ruins > 0:
		_erro("%s: %d ponto(s) do anel cobertos errado (nem parede, nem vao, ou os dois)"
			% [porta, ruins])

## O retangulo do vao da porta, independente de `paredes_externas`: centrado em
## `porta_de`, largura VAO ao longo da fachada, espessura PAREDE na
## perpendicular. Serve de prova cruzada porque usa tres primitivas
## (`porta_de`, `eixo_da_fachada`, `normal_de`) que `paredes_externas` nao chama
## na mesma combinacao.
func _vao_retangulo(c: Dictionary) -> Rect2:
	var centro := Construcao.porta_de(c)
	var eixo := Construcao.eixo_da_fachada(c)
	var normal := Construcao.normal_de(c).abs()
	var meio_ao_longo := eixo * (VAO / 2.0)
	var meio_perp := normal * (PAREDE / 2.0)
	var a := centro - meio_ao_longo - meio_perp
	var b := centro + meio_ao_longo + meio_perp
	return Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(b.x - a.x), absf(b.y - a.y))

# --- b) o vao mede VAO -------------------------------------------------------

func _o_vao_mede_vao(c: Dictionary, porta: String) -> void:
	var eixo := Construcao.eixo_da_fachada(c)
	var vao := _vao_retangulo(c)
	var medida := vao.size.x if eixo.x != 0.0 else vao.size.y
	if not is_equal_approx(medida, VAO):
		_erro("%s: o vao mede %.2f, devia medir %.2f" % [porta, medida, VAO])

# --- c) os quartos completam o interior --------------------------------------

func _os_quartos_completam_o_interior(c: Dictionary, porta: String) -> void:
	var interior := Construcao.interior_de(c)
	var quartos := Construcao.quartos_de(c)
	var divisorias := Construcao.paredes_internas(c)

	if quartos.size() != 3:
		_erro("%s: 3 quartos esperados, %d encontrados" % [porta, quartos.size()])
		return

	for i in quartos.size():
		if not interior.encloses(quartos[i]):
			_erro("%s: quarto %d sai do interior" % [porta, i])
		for j in range(i + 1, quartos.size()):
			if quartos[i].intersects(quartos[j], true):
				# Encostar na divisoria e esperado (a divisoria fica ENTRE os
				# dois); so a AREA de sobreposicao importa.
				var comum := quartos[i].intersection(quartos[j])
				if comum.get_area() > 1.0:
					_erro("%s: quarto %d e %d se sobrepoem em %.0f px²"
						% [porta, i, j, comum.get_area()])

	var area_quartos := 0.0
	for quarto in quartos:
		area_quartos += quarto.get_area()
	var area_divisorias := 0.0
	for divisoria in divisorias:
		area_divisorias += (divisoria as Rect2).get_area()

	# Os quartos mais as divisorias fecham o interior, a MENOS dos dois vaos de
	# passagem (o da divisoria paralela e o da perpendicular) - area de
	# passagem, e nao de parede nem de quarto: e por ali que se anda de um
	# quarto a outro. A diferenca esperada e exatamente 2 x VAO x PAREDE; sobra
	# alem disso e buraco (quarto que nao chega na parede), falta e
	# sobreposicao (quarto por cima de divisoria).
	var esperada := 2.0 * VAO * PAREDE
	var diferenca := absf((area_quartos + area_divisorias) - interior.get_area())
	if absf(diferenca - esperada) > 4.0:  # px², folga so por ponto flutuante
		_erro("%s: quartos (%.0f) + divisorias (%.0f) + 2 vaos (%.0f) != interior (%.0f)"
			% [porta, area_quartos, area_divisorias, esperada, interior.get_area()])

# --- d) a entrada sai pela normal --------------------------------------------

func _a_entrada_sai_pela_normal(c: Dictionary, porta: String) -> void:
	var rect: Rect2 = c["rect"]
	var entrada := Construcao.entrada_de_carro(c)
	var normal := Construcao.normal_de(c)

	if rect.intersects(entrada, true) and rect.intersection(entrada).get_area() > 1.0:
		_erro("%s: a entrada de carro invade o predio" % porta)

	# A entrada tem que encostar exatamente na fachada (o lado para onde o
	# normal aponta), nao noutro lado do predio.
	var encosta: bool
	match porta:
		"sul":   encosta = is_equal_approx(entrada.position.y, rect.end.y)
		"norte": encosta = is_equal_approx(entrada.end.y, rect.position.y)
		"leste": encosta = is_equal_approx(entrada.position.x, rect.end.x)
		_:       encosta = is_equal_approx(entrada.end.x, rect.position.x)
	if not encosta:
		_erro("%s: a entrada de carro nao encosta na fachada do lado do normal %s"
			% [porta, normal])

# --- e) girar 90 graus da a outra orientacao ---------------------------------

func _rotacionar_ponto(p: Vector2, pivot: Vector2) -> Vector2:
	var d := p - pivot
	return pivot + Vector2(-d.y, d.x)

func _rotacionar_rect(r: Rect2, pivot: Vector2) -> Rect2:
	var a := _rotacionar_ponto(r.position, pivot)
	var b := _rotacionar_ponto(r.end, pivot)
	return Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(b.x - a.x), absf(b.y - a.y))

func _girar_90_da_a_outra(de: Dictionary, para: Dictionary, pivot: Vector2, rotulo: String) -> void:
	_comparar_rect_girado(Construcao.interior_de(de), Construcao.interior_de(para),
		pivot, rotulo, "interior_de")
	_comparar_rect_girado(Construcao.entrada_de_carro(de), Construcao.entrada_de_carro(para),
		pivot, rotulo, "entrada_de_carro")

	var paredes_de := Construcao.paredes_externas(de)
	var paredes_para := Construcao.paredes_externas(para)
	if paredes_de.size() != paredes_para.size():
		_erro("%s: paredes_externas mudou de tamanho (%d -> %d)"
			% [rotulo, paredes_de.size(), paredes_para.size()])
	else:
		for i in paredes_de.size():
			_comparar_rect_girado(paredes_de[i], paredes_para[i], pivot, rotulo,
				"paredes_externas[%d]" % i)

	var quartos_de_ := Construcao.quartos_de(de)
	var quartos_para := Construcao.quartos_de(para)
	for i in mini(quartos_de_.size(), quartos_para.size()):
		_comparar_rect_girado(quartos_de_[i], quartos_para[i], pivot, rotulo,
			"quartos_de[%d]" % i)

func _comparar_rect_girado(original: Rect2, esperado: Rect2, pivot: Vector2,
		rotulo: String, funcao: String) -> void:
	var girado := _rotacionar_rect(original, pivot)
	if not (girado.position.is_equal_approx(esperado.position)
			and girado.size.is_equal_approx(esperado.size)):
		_erro("%s: %s girado 90° deu %s, esperava %s" % [rotulo, funcao, girado, esperado])
