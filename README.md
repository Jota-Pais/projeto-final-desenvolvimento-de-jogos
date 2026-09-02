# Projeto Final — Desenvolvimento de Jogos

MVP de um jogo digital em **Godot 4**, feito em equipe para a disciplina de
Desenvolvimento de Jogos — Engenharia de Software, SATC 2026.2.
Prof. Me. Fabiano Naspolini de Oliveira.

O professor recomendou o Construct 2, mas deixou a ferramenta livre. A escolha
pelo Godot 4 é por não ter teto de eventos na versão gratuita, ter 2D e editor
de tilemap nativos, GDScript próximo do Python e export para web — que é como as
versões alfa, beta e gold vão ser entregues para o professor rodar.

## Como abrir

**Godot 4.7.2 stable**, build padrão (não a .NET/C# — o projeto é em GDScript).
O editor é portátil, não tem instalador: baixar em
<https://godotengine.org/download>, extrair e abrir o `project.godot` desta pasta.

O código se escreve **no editor de script do próprio Godot** (02/09/2026) — é lá
que a cena, o node e o debugger já estão. Quem preferir VS Code pode ligar o
editor externo com a extensão `godot-tools`, mas cena continua sendo editada no
Godot.

## Estado

Esqueleto. **O jogo ainda não foi definido** — gênero, core mechanic e título
saem do High Concept, a primeira entrega do projeto final. Por isso não há
estrutura de pastas de verdade nem cenas do jogo: `entities/`, `levels/` e o
resto dependem de saber o que o jogo é.

A única coisa que roda é a **cena de teste** em `teste-movimento/`, descrita
abaixo.

Pendentes de decisão da equipe:

- [ ] Título do jogo — o nome deste repositório e o `config/name` do
      `project.godot` são provisórios. O Godot apaga comentário do
      `project.godot` toda vez que salva as configurações, então o lembrete
      mora aqui
- [ ] Estrutura de pastas
- [ ] Convenções de código e de cena — inclusive **em que idioma** nomear node,
      variável e arquivo. O teste está em português só para combinar com a
      documentação; não é decisão tomada
- [ ] Divisão de tarefas

## Cena de teste (`teste-movimento/`)

Serve **só para confirmar que o Godot abre e roda o projeto**. Não é o jogo, não
tem relação com o que vier a ser o jogo, e some assim que a primeira cena de
verdade existir.

Abrir o `project.godot` no Godot e apertar **F5** — ela já é a cena principal.
Setas ou WASD movem um quadrado de 64 px com a foto por um chão xadrez cinza
com blocos espalhados. O quadrado fica **fixo no meio da tela**: a `Camera2D`
é filha dele, então quem se mexe é o cenário. O xadrez e os blocos existem por
isso — num chão liso e uniforme não dá para perceber movimento nenhum.

- `teste.tscn` — a cena: `Chao`, `Jogador` (`CharacterBody2D` com `Sprite2D`,
  colisão e câmera)
- `jogador.png` — a foto usada de sprite. O `Sprite2D` recorta um quadrado
  central dela por `region_rect`, para não distorcer, e reduz para 64 px
- `chao.gd` — desenha o xadrez, os blocos e a borda do mundo (3200×1800) com
  `_draw()`, sem precisar de nenhuma imagem
- `jogador.gd` — movimento em 8 direções com `move_and_slide()` e trava nas
  bordas do mundo

Ao apagar, lembrar de trocar o `run/main_scene` no `project.godot`.

## Combinados de Git

Enquanto não houver outra decisão, dois acordos que evitam a maior dor de
trabalhar em Godot a várias mãos:

1. **Uma cena, um dono por vez.** `.tscn` e `.tres` são texto e até mergeiam,
   mas conflito em cena grande custa mais tempo do que combinar antes.
2. **Cada fase em arquivo separado**, para duas pessoas nunca editarem o mesmo
   arquivo de nível.

O cache do Godot (`.godot/`) e os builds exportados estão no `.gitignore` — não
commitar.

## Entregas

O escopo, os pesos e os critérios de cada entrega (High Concept, Alfa, Beta,
GDD, Gold e apresentações) estão no documento do professor no AVA. Prazo perdido
nas Etapas 1 e 2 é nota zerada, sem entrega atrasada.
