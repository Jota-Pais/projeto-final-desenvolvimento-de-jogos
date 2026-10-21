extends Node
## O audio do jogo. Autoload, como o Travessia: chama-se "Som" de qualquer
## lugar, e e o unico arquivo que sabe onde os sons moram e como tocam.
##
## Os arquivos estao em `res://som/`, na mesma arvore da pasta "sons" do Drive
## da equipe (20/10/2026): a raiz, `armas/` e `menu/`. Quem chama pede pelo
## caminho sem extensao - `Som.tocar("armas/Beretta")`. Ficaram de fora o
## `NAO_USAR_MOMENTANEAMENTE` (o nome diz) e `personagens/`, que e fala de NPC
## em .m4a (o Godot nao abre m4a, e o jogo ainda nao tem NPC).
##
## Tres canais, e nenhum deles e de cena - por isso o som atravessa a troca de
## cena (a porta de casa bate na rua e se ouve ja na casa):
##
##  - **efeitos** (`tocar`): um player por som, com polifonia, entao o mesmo
##    som pode se sobrepor ate `vozes` vezes sem criar no a cada tiro;
##  - **efeitos no mundo** (`tocar_em`): um AudioStreamPlayer2D solto na cena
##    atual, que some quando termina - longe da camera, baixo ou mudo;
##  - **musica** e **ambiente** (`musica`, `ambiente`): um loop cada, trocado
##    com fade. Cada cena diz o que quer no _ready, e "" e silencio.
##
## **Volumes: proposta**, de ouvido nenhum - os arquivos chegaram sem mixagem,
## e quem calibra e quem ouvir. Estao todos em VOLUME, num lugar so.

const PASTA := "res://som/"

## Quanto dura a troca de um loop por outro (metade saindo, metade entrando).
## O mp3 importa sem loop: e `musica` e `ambiente` que ligam.
const SEGUNDOS_DO_FADE := 0.8

## Volume de cada som, em dB. O que nao esta aqui toca a 0.
const VOLUME := {
	"menu/menu": -8.0,
	"menu/mouse_passar_botao": -10.0,
	"possivel_game_over": -6.0,
	"ambiente_dentro_lugares": -10.0,
	"andar_previa": -10.0,
	"andar_previa_2": -10.0,
	"andar_madeira_previa": -8.0,
	"armas/estojo_caindo": -12.0,
	"armas/impacto_bala": -6.0,
	"armas/click_arma_sem_municao": -4.0,
	"zumbi": -4.0,
	"geladeira": -4.0,
	"porta": -2.0,
}

## Sem tela nao ha som: os conferidores rodam headless e saem no meio de um
## tiro, e o servidor de audio fica segurando o que tocava - o Godot acusa
## vazamento na saida. Headless, o Som fica mudo e o resto do jogo nao nota.
var mudo := DisplayServer.get_name() == "headless"

var _efeitos := {}
var _musica: AudioStreamPlayer
var _ambiente: AudioStreamPlayer

func _ready() -> void:
	# O som nao para quando a arvore pausa (nada pausa hoje, mas um menu de
	# pausa futuro nao deveria calar a musica dele).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = _novo_player()
	_ambiente = _novo_player()

## O stream de `nome`, ou null (com erro) se o arquivo nao existe.
func carregar(nome: String) -> AudioStream:
	for extensao in [".mp3", ".wav", ".ogg"]:
		if ResourceLoader.exists(PASTA + nome + extensao):
			return load(PASTA + nome + extensao) as AudioStream
	push_error("som: nao achei \"%s\" em %s" % [nome, PASTA])
	return null

## Toca um efeito que nao tem lugar no mundo - a interface, ou o que sai do
## proprio jogador, que e sempre o centro da tela. `vozes` e quantos deste som
## tocam juntos: 1 recomeca o som em vez de sobrepor (o gemido de dano, o
## mouse passando de botao em botao). `tom` muda a altura e a velocidade.
func tocar(nome: String, tom := 1.0, vozes := 4) -> void:
	if mudo:
		return
	var player: AudioStreamPlayer = _efeitos.get(nome)
	if player == null:
		var stream := carregar(nome)
		if stream == null:
			return
		player = _novo_player()
		player.stream = stream
		player.volume_db = VOLUME.get(nome, 0.0)
		_efeitos[nome] = player
	player.max_polyphony = vozes
	player.pitch_scale = tom
	if vozes == 1:
		player.stop()
	player.play()

## Toca um efeito num ponto do mundo da cena atual: se ouve mais baixo quanto
## mais longe da camera, e nada alem de `alcance` px.
func tocar_em(nome: String, onde: Vector2, alcance := 700.0, tom := 1.0) -> void:
	if mudo:
		return
	var cena := get_tree().current_scene
	if cena == null:
		return
	var stream := carregar(nome)
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = VOLUME.get(nome, 0.0)
	player.pitch_scale = tom
	player.max_distance = alcance
	player.finished.connect(player.queue_free)
	cena.add_child(player)
	player.global_position = onde
	player.play()

## A musica, em loop a menos que `repetir` seja false (o game over toca uma
## vez); "" para. Pedir a que ja toca nao a recomeca.
func musica(nome: String, repetir := true) -> void:
	_trocar_loop(_musica, nome, repetir)

## O som de fundo em loop (dentro dos lugares, a casa); "" para.
func ambiente(nome: String) -> void:
	_trocar_loop(_ambiente, nome, true)

func _trocar_loop(player: AudioStreamPlayer, nome: String, repetir: bool) -> void:
	if mudo:
		return
	var atual := player.get_meta("nome", "") as String
	if atual == nome:
		return
	player.set_meta("nome", nome)
	var stream: AudioStream = null
	if nome != "":
		stream = carregar(nome)
	if not player.playing and stream == null:
		return
	var fade := create_tween()
	if player.playing:
		fade.tween_property(player, "volume_db", -60.0, SEGUNDOS_DO_FADE / 2.0)
		fade.tween_callback(player.stop)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = repetir
	fade.tween_callback(func() -> void:
		player.stream = stream
		player.volume_db = -60.0
		player.play())
	fade.tween_property(player, "volume_db", VOLUME.get(nome, 0.0), SEGUNDOS_DO_FADE / 2.0)

func _novo_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	return player
