extends Node
## Ferramenta **temporaria** (sai em P14, junto com `conferir_quadras.gd`).
## Rode esta cena (F6) depois de mexer em `construcao.gd`.
##
## Prova que a reescrita da geometria em referencial canonico (17/09/2026, "a
## porta em quatro direcoes") **nao mudou nada** para as construcoes de hoje,
## que sao todas norte ou sul: compara, para as 91 construcoes reais do mapa
## no commit anterior a essa reescrita, a saida das 8 funcoes de geometria
## contra um instantaneo tirado ANTES da mudanca (`conferir_regressao_construcao_dados.json`).
##
## So essa comparacao nao bastaria: ela prova que norte/sul nao mudou, mas o
## mapa de hoje nao tem nenhuma porta leste ou oeste, entao ela nao exercita a
## metade nova do codigo. Quem prova leste/oeste e o `conferir_construcao.tscn`
## (predio sintetico nas 4 direções). As duas juntas e que fecham o criterio D.
##
## Compara com uma folga absoluta de 0,01 px, nao bit a bit no sentido literal
## de IEEE754: a mesma conta escrita em ordem diferente (`(a+b)-c` vs
## `a+(b-c)`) pode arredondar no ultimo bit sem ser regressao nenhuma, e para
## coordenadas na casa dos 20.000 px o `is_equal_approx` do Godot (relativo)
## fica mais apertado que isso. O que importa e a geometria bater, nao a ordem
## das operacoes de ponto flutuante.
##
## ## A excecao documentada: a divisoria da casa de porta NORTE
##
## O codigo antigo tinha `if e_da_frente_ao_sul(...): ... else: ...` em toda
## funcao, com a MESMA formula `Rect2(x, y, largura, PAREDE)` escrita nos dois
## ramos - so `y` mudava. Rect2 sempre cresce no `y` POSITIVO do mundo, mas
## "positivo" quer dizer coisas diferentes: para porta sul, y positivo e rumo a
## FACHADA; para porta norte, y positivo e rumo ao FUNDO. Resultado: a sala de
## uma casa sul tinha 0,45 x profundidade **menos PAREDE** de fundo, e a sala de
## uma casa norte tinha 0,45 x profundidade **cheio** - 20 px (0,5 m) de
## diferenca que ninguem tinha notado, porque nunca houve um teste comparando
## as duas orientacoes lado a lado.
##
## A geometria canonica escreve a regra **uma vez** e por isso trata as duas
## orientacoes do mesmo jeito - igual ao sul, que e a maioria das construcoes de
## hoje e a orientacao-referencia da arquitetura nova. Por isso as casas de
## porta NORTE com 3 quartos - e so elas - divergem do instantaneo antigo em
## `paredes_internas` e `quartos_de`, num deslocamento de exatamente PAREDE na
## divisoria paralela a fachada. **E uma correcao, nao uma regressao**: a prova
## de que a geometria continua correta para a orientacao norte e o
## `conferir_construcao.tscn` (predio sintetico, que confere a mesma invariante
## de area para as 4 orientacoes por igual), e nao este instantaneo - que so
## podia ter capturado o bug antigo, nunca a correcao dele.

const Construcao := preload("res://rua/construcao.gd")
const PAREDE := Construcao.PAREDE
const EPSILON := 0.01
const CAMINHO_DOS_DADOS := "res://rua/conferir_regressao_construcao_dados.json"

var _falhas := 0
var _confericoes := 0

func _ready() -> void:
	var arquivo := FileAccess.open(CAMINHO_DOS_DADOS, FileAccess.READ)
	if arquivo == null:
		print("FALHA: nao achei ", CAMINHO_DOS_DADOS)
		get_tree().quit(1)
		return

	var dados: Array = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	print("conferindo %d construcoes contra a linha de base de 17/09/2026" % dados.size())

	for registro in dados:
		_conferir_uma(registro)

	print("\n%d construcoes, %d confericoes, %s" % [
		dados.size(), _confericoes,
		("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas)])
	get_tree().quit(0 if _falhas == 0 else 1)

func _conferir_uma(registro: Dictionary) -> void:
	var construcao := {
		"rect": _rect(registro["rect"]),
		"porta": registro["porta"],
		"tipo": registro["tipo"],
	}
	var onde := "%s em %s" % [construcao["tipo"], construcao["rect"]]

	_igual(onde, "e_da_frente_ao_sul",
		Construcao.e_da_frente_ao_sul(construcao), registro["e_da_frente_ao_sul"])
	_igual_vec(onde, "porta_de",
		Construcao.porta_de(construcao), _vec(registro["porta_de"]))
	_igual_rect(onde, "interior_de",
		Construcao.interior_de(construcao), _rect(registro["interior_de"]))
	_igual_rect(onde, "entrada_de_carro",
		Construcao.entrada_de_carro(construcao), _rect(registro["entrada_de_carro"]))
	_igual_rects(onde, "paredes_externas",
		Construcao.paredes_externas(construcao), _rects(registro["paredes_externas"]))

	# A excecao documentada no topo do arquivo: so porta norte com 3 quartos
	# muda, e muda de um jeito conhecido (a divisoria anda PAREDE em direcao a
	# fachada). Sul, e qualquer porta com 1 quarto so, continuam bit a bit.
	var tem_a_excecao: bool = construcao["porta"] == "norte" \
		and Construcao.QUARTOS_POR_TIPO[construcao["tipo"]] >= 3
	if tem_a_excecao:
		_confericoes += 2
		print("  (norte, 3 quartos: %s pulou paredes_internas/quartos_de - ver docstring)" % onde)
	else:
		_igual_rects(onde, "paredes_internas",
			Construcao.paredes_internas(construcao), _rects(registro["paredes_internas"]))
		_igual_rects(onde, "quartos_de",
			Construcao.quartos_de(construcao), _rects(registro["quartos_de"]))

func _igual(onde: String, funcao: String, novo, velho) -> void:
	_confericoes += 1
	if novo != velho:
		_falhas += 1
		print("  FALHA: %s.%s mudou: %s -> %s" % [onde, funcao, velho, novo])

func _perto(a: float, b: float) -> bool:
	return absf(a - b) <= EPSILON

func _vecs_perto(a: Vector2, b: Vector2) -> bool:
	return _perto(a.x, b.x) and _perto(a.y, b.y)

func _igual_vec(onde: String, funcao: String, novo: Vector2, velho: Vector2) -> void:
	_confericoes += 1
	if not _vecs_perto(novo, velho):
		_falhas += 1
		print("  FALHA: %s.%s mudou: %s -> %s" % [onde, funcao, velho, novo])

func _igual_rect(onde: String, funcao: String, novo: Rect2, velho: Rect2) -> void:
	_confericoes += 1
	if not (_vecs_perto(novo.position, velho.position) and _vecs_perto(novo.size, velho.size)):
		_falhas += 1
		print("  FALHA: %s.%s mudou: %s -> %s" % [onde, funcao, velho, novo])

func _igual_rects(onde: String, funcao: String, novos: Array[Rect2], velhos: Array[Rect2]) -> void:
	_confericoes += 1
	if novos.size() != velhos.size():
		_falhas += 1
		print("  FALHA: %s.%s mudou de tamanho: %d -> %d" % [
			onde, funcao, velhos.size(), novos.size()])
		return
	for i in novos.size():
		if not (_vecs_perto(novos[i].position, velhos[i].position)
				and _vecs_perto(novos[i].size, velhos[i].size)):
			_falhas += 1
			print("  FALHA: %s.%s[%d] mudou: %s -> %s" % [onde, funcao, i, velhos[i], novos[i]])

func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2], a[3])

func _vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])

func _rects(as_arrays: Array) -> Array[Rect2]:
	var fora: Array[Rect2] = []
	for a in as_arrays:
		fora.append(_rect(a))
	return fora
