extends Node2D
## Chao de teste: xadrez cinza com marcos espalhados. Existe so para dar
## referencia visual de movimento - num chao liso o personagem parece parado.
## Descartavel: sai quando o jogo de verdade comecar.

const TAMANHO_DO_MUNDO := Vector2(3200.0, 1800.0)
const LADO_DO_QUADRADO := 64.0

const CINZA_CLARO := Color("4b5054")
const CINZA_ESCURO := Color("3f4448")
const CINZA_DO_MARCO := Color("6e7478")
const COR_DA_BORDA := Color("8a9298")

func _draw() -> void:
	var canto := -TAMANHO_DO_MUNDO / 2.0
	var colunas := int(TAMANHO_DO_MUNDO.x / LADO_DO_QUADRADO)
	var linhas := int(TAMANHO_DO_MUNDO.y / LADO_DO_QUADRADO)

	for coluna in colunas:
		for linha in linhas:
			var cor := CINZA_CLARO if (coluna + linha) % 2 == 0 else CINZA_ESCURO
			var posicao := canto + Vector2(coluna, linha) * LADO_DO_QUADRADO
			draw_rect(Rect2(posicao, Vector2.ONE * LADO_DO_QUADRADO), cor)

	# Sem os marcos o xadrez se repete igual e voce perde a nocao de onde esta.
	# Semente fixa para o desenho ser sempre o mesmo a cada execucao.
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 20260902
	for _marco in 45:
		var posicao := Vector2(
			sorteio.randf_range(canto.x, canto.x + TAMANHO_DO_MUNDO.x),
			sorteio.randf_range(canto.y, canto.y + TAMANHO_DO_MUNDO.y)
		)
		var lado := sorteio.randf_range(40.0, 110.0)
		draw_rect(Rect2(posicao, Vector2(lado, lado)), CINZA_DO_MARCO)

	draw_rect(Rect2(canto, TAMANHO_DO_MUNDO), COR_DA_BORDA, false, 6.0)
