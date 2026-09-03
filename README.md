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

**A premissa e a estrutura do jogo já foram decididas** pela equipe e estão em
[`design/high-concept.md`](design/high-concept.md): apocalipse zumbi, dois modos
que se alternam a cada dia — rua top-down para o gameplay, casa ponto e clique

O conteúdo e o layout da **peça de entrega** — o one-pager visual que o professor
exige no lugar de um documento de texto — estão em
[`design/high-concept-one-pager.md`](design/high-concept-one-pager.md), pronto
para entregar a quem for diagramar.
para a narrativa — e um prazo em dias para desenvolver a cura.

O título é **Você me amaria se eu fosse um zumbi?**, confirmado em 03/09/2026.

O que ainda não existe é código do jogo, e é a decisão de estrutura de pastas e
as primeiras cenas de verdade que dependem disso. A única coisa que roda é a
**cena de teste** em `teste-movimento/`, descrita abaixo, que não tem relação
nenhuma com o jogo.

Pendentes de decisão da equipe:

- [ ] **Renomear o repositório** — o título está fechado, então o nome
      `projeto-final-desenvolvimento-de-jogos` já pode virar
      `voce-me-amaria-se-eu-fosse-um-zumbi`. O GitHub mantém redirect da URL
      antiga, ninguém precisa reclonar
- [ ] Aprovar ou trocar o que foi proposto no High Concept sem passar pelo grupo:
      gênero, plataformas, nº de jogadores, classificação etária, objetivos
      secundários, controles e público-alvo
- [ ] Quem fica na rua e quem fica na casa — a divisão é metade da equipe em
      cada frente, mas os nomes não estão amarrados
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

Quatro **inimigos** nascem nos cantos e andam devagar (110 contra os 420 do
jogador) na direção dele, o tempo todo. Não atacam, não morrem e não desviam de
nada — dá para ficar dando a volta neles à vontade.

- `teste.tscn` — a cena: `Chao`, `Jogador` (`CharacterBody2D` com `Sprite2D`,
  colisão e câmera) e quatro `Inimigo`
- `jogador.png` — a foto usada de sprite. O `Sprite2D` recorta um quadrado
  central dela por `region_rect`, para não distorcer, e reduz para 64 px
- `inimigo.tscn` e `inimigo.png` — o inimigo, instanciado quatro vezes na cena.
  A foto é retrato (240×432), então entra inteira, sem recorte, reduzida para
  80 px de altura
- `inimigo.gd` — anda na direção do jogador e nada mais. Acha o jogador pelo
  **grupo** `jogador`, não por caminho de node, para não depender de onde ele
  está na árvore
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
