extends Node
## Ferramenta. **Rode esta cena (F6) depois de mexer na cena inicial, no texto
## dela ou na arte.**
##
## Comeca a partida nova como o titulo comeca (Travessia.comecar_partida) e
## confere:
##
##  1. a arte: cada imagem em cena_inicial/arte/ e 16:9 e tem 1280 x 720 (a
##     janela do jogo) ou mais. Quadro sem arte e aviso, e nao falha - fica
##     escuro, com o texto;
##  2. a partida nova abre a cena inicial, e nao a rua direto, com o tutorial
##     na abertura e desarmado;
##  3. o E completa o texto que esta sendo escrito, e o segundo E passa adiante;
##  4. o Esc para a cena ali mesmo e a rua abre;
##  5. sem ninguem no teclado, os seis quadros passam na ordem, cada texto fica
##     inteiro na tela antes do seguinte, e no fim a rua abre na abertura do
##     tutorial.
##
## No passo 5 o relogio do jogo corre RAPIDO vezes mais rapido: no ritmo de
## leitura a cena leva uns 40 s. Os limites de espera sao em relogio de
## verdade, como nas outras ferramentas.

const CenaInicial := preload("res://cena_inicial/cena_inicial.gd")
const CENA_INICIAL := "res://cena_inicial/cena_inicial.tscn"

const RAPIDO := 8.0
## Quanto esperar, em segundos de relogio, a cena tocar inteira ou a rua abrir.
const LIMITE := 60.0

var _falhas := 0
## O relogio do jogo (com o RAPIDO), para medir quanto a cena dura.
var _relogio := 0.0

func _ready() -> void:
	await get_tree().process_frame
	# A cena inicial troca de cena para a rua, e a troca levaria esta
	# ferramenta junto se ela fosse a cena atual.
	get_tree().current_scene = null
	_a_arte()
	await _o_e_e_o_esc()
	await _inteira()
	print("\n%s" % ("SEM PROBLEMAS" if _falhas == 0 else "%d PROBLEMA(S)" % _falhas))
	Engine.time_scale = 1.0
	Travessia.tutorial = ""
	Travessia.armado = true
	get_tree().quit(0 if _falhas == 0 else 1)

func _process(delta: float) -> void:
	_relogio += delta

func _erro(texto: String) -> void:
	_falhas += 1
	print("  FALHA: " + texto)

## Espera `condicao` virar verdade, ou `segundos` de relogio de verdade.
func _esperar(condicao: Callable, segundos: float) -> bool:
	var ate := Time.get_ticks_msec() + int(segundos * 1000.0)
	while not condicao.call():
		if Time.get_ticks_msec() > ate:
			return false
		await get_tree().process_frame
	return true

## A cena atual, quando ela for a de `caminho` - ou null depois do LIMITE.
func _esperar_a_cena(caminho: String) -> Node:
	var e_ela := func() -> bool:
		return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == caminho
	if not await _esperar(e_ela, LIMITE):
		return null
	return get_tree().current_scene

## Aperta no comeco de um quadro (antes do _process da cena) e solta no
## seguinte.
func _apertar(acao: String) -> void:
	await get_tree().process_frame
	Input.action_press(acao)
	await get_tree().process_frame
	Input.action_release(acao)

func _inteiro(cena: Node) -> bool:
	var texto := cena._texto as RichTextLabel
	return texto.visible_characters < 0 or texto.visible_characters >= texto.get_parsed_text().length()

## A partida nova, como o titulo a comeca: a cena inicial, ou null.
func _partida_nova() -> Node:
	Travessia.comecar_partida(Travessia.Modo.CAMPANHA)
	var cena := await _esperar_a_cena(CENA_INICIAL)
	if cena == null:
		_erro("a partida nova nao abriu a cena inicial")
	return cena

func _a_arte() -> void:
	print("1. a arte")
	var sem_arte: Array[String] = []
	for n in range(1, CenaInicial.QUADROS.size() + 1):
		var caminho := CenaInicial.arte_do_quadro(n)
		if caminho == "":
			sem_arte.append(str(n))
			continue
		var tamanho := (load(caminho) as Texture2D).get_size()
		if tamanho.x < 1280 or tamanho.y < 720:
			_erro("o quadro %d tem %d x %d, menos que a janela, 1280 x 720" % [n, tamanho.x, tamanho.y])
		elif absf(tamanho.x / tamanho.y - 16.0 / 9.0) > 0.02:
			_erro("o quadro %d tem %d x %d, que nao e 16:9" % [n, tamanho.x, tamanho.y])
		else:
			print("  quadro %d: %s, %d x %d" % [n, caminho.get_file(), tamanho.x, tamanho.y])
	if not sem_arte.is_empty():
		print("  aviso: sem arte ainda no(s) quadro(s) %s - fica(m) escuro(s), so com o texto" % ", ".join(sem_arte))

func _o_e_e_o_esc() -> void:
	print("2. a partida nova")
	var cena := await _partida_nova()
	if cena == null:
		return
	if Travessia.tutorial != "abertura" or Travessia.armado:
		_erro("a partida nova nao esta no comeco do tutorial e desarmada")
	else:
		print("  abriu a cena inicial, com o tutorial na abertura e desarmado")
	# A rua que o Esc abre vem sem tutorial: a partida nova do passo 5 a tira da
	# arvore logo depois, e o tutorial no meio do roteiro acusaria a falta dela.
	Travessia.tutorial = ""

	print("3. o E")
	var escrevendo := func() -> bool:
		return cena._fase == CenaInicial.Fase.FALANDO and (cena._texto as RichTextLabel).visible_characters > 0
	if not await _esperar(escrevendo, 10.0):
		_erro("o primeiro texto nao comecou a ser escrito")
		return
	if _inteiro(cena):
		_erro("o primeiro texto ja estava inteiro antes do E")
	await _apertar("vasculhar")
	if not _inteiro(cena):
		_erro("o E nao completou o texto")
	elif cena._quadro != 0 or cena._fala != 0 or cena._fase != CenaInicial.Fase.FALANDO:
		_erro("o E passou adiante em vez de completar o texto")
	else:
		print("  o primeiro E completou o texto")
	await _apertar("vasculhar")
	if cena._quadro != 0 or cena._fase != CenaInicial.Fase.SAINDO:
		_erro("o segundo E nao passou para o quadro seguinte")
	else:
		print("  o segundo E passou para o quadro seguinte")

	print("4. o Esc")
	if not await _esperar(func() -> bool: return cena._quadro == 1 and cena._fase == CenaInicial.Fase.FALANDO, 10.0):
		_erro("o segundo quadro nao comecou")
		return
	var apertou := _relogio
	await _apertar("ui_cancel")
	if cena._fase != CenaInicial.Fase.FIM:
		_erro("o Esc nao parou a cena")
	var maior_quadro := [1]
	var saiu := func() -> bool:
		if not is_instance_valid(cena) or not cena.is_inside_tree():
			return true
		maior_quadro[0] = maxi(maior_quadro[0], cena._quadro)
		return false
	await _esperar(saiu, 5.0)
	var demorou := _relogio - apertou
	if maior_quadro[0] != 1:
		_erro("depois do Esc a cena ainda foi ate o quadro %d" % (maior_quadro[0] + 1))
	elif demorou > CenaInicial.SEGUNDOS_DO_PULO + 0.5:
		_erro("depois do Esc a cena ainda ficou %.1f s" % demorou)
	if await _esperar_a_cena(Travessia.CENA_DA_RUA) == null:
		_erro("depois do Esc, a rua nao abriu")
	else:
		print("  o Esc no quadro 2 escureceu em %.1f s e abriu a rua" % demorou)

func _inteira() -> void:
	print("5. inteira, sem ninguem no teclado")
	var cena := await _partida_nova()
	if cena == null:
		return
	Engine.time_scale = RAPIDO
	var comeco := _relogio
	# Cada texto, "quadro.fala", na ordem em que ficou inteiro na tela.
	var vistos: Array[String] = []
	var acabou := func() -> bool:
		if not is_instance_valid(cena) or not cena.is_inside_tree():
			return true
		if cena._fase == CenaInicial.Fase.FALANDO and _inteiro(cena):
			var chave := "%d.%d" % [cena._quadro, cena._fala]
			if not chave in vistos:
				vistos.append(chave)
				var fala: Array = CenaInicial.QUADROS[cena._quadro]["falas"][cena._fala]
				var na_tela := (cena._texto as RichTextLabel).get_parsed_text()
				if not na_tela.contains(fala[1]) or (fala[0] != "" and not na_tela.contains(fala[0])):
					_erro("o texto %s saiu \"%s\"" % [chave, na_tela])
		return false
	var a_tempo: bool = await _esperar(acabou, LIMITE)
	var segundos := _relogio - comeco
	Engine.time_scale = 1.0
	if not a_tempo:
		_erro("a cena nao acabou em %.0f s de relogio" % LIMITE)
		return
	var esperados: Array[String] = []
	for q in CenaInicial.QUADROS.size():
		for f in CenaInicial.QUADROS[q]["falas"].size():
			esperados.append("%d.%d" % [q, f])
	if vistos != esperados:
		_erro("os textos inteiros na tela foram %s, e nao %s" % [vistos, esperados])
	else:
		print("  os %d textos dos %d quadros, na ordem e inteiros; a cena durou %.0f s"
			% [esperados.size(), CenaInicial.QUADROS.size(), segundos])
	if await _esperar_a_cena(Travessia.CENA_DA_RUA) == null:
		_erro("no fim, a rua nao abriu")
	elif Travessia.tutorial != "abertura":
		_erro("a rua abriu com o tutorial em \"%s\", e nao na abertura" % Travessia.tutorial)
	else:
		print("  no fim, a rua, na abertura do tutorial")
