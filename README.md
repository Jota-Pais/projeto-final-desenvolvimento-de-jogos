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
para a narrativa — e um prazo em dias para desenvolver a cura.

O conteúdo e o layout da **peça de entrega** — o one-pager visual que o professor
exige no lugar de um documento de texto — estão em
[`design/high-concept-one-pager.md`](design/high-concept-one-pager.md), pronto
para entregar a quem for diagramar.

O título de trabalho é **Você me amaria se eu fosse um zumbi?**. O grupo foi
consultado em 03/09/2026 e pode propor outro — a tagline ainda não existe.

A primeira cena de verdade existe desde 07/09/2026: é a `rua/`, descrita abaixo,
e é ela que roda no F5. A cena de teste em `teste-movimento/` foi **apagada em
08/09/2026** — o zumbi foi escrito do zero, sem reaproveitar nada dela.

**Os cinco passos que levam à Alfa estão de pé**: a mecânica de vasculhar (1),
o zumbi (2), o relógio do dia com a noite e a HUD (3), a mochila com os
documentos (4) e o ciclo fechado, com os dois desfechos (5). O que sobrou de
declarado e não construído é **fome e água** — ver *O que ainda não tem*.

Pendentes de decisão da equipe:

- [ ] **Fechar o título e escrever a tagline** — hoje o título é de trabalho.
      Quando fechar, o repositório pode ser renomeado (`projeto-final-...` →
      um slug do título) e o `config/name` do `project.godot` acompanha. O
      GitHub mantém redirect da URL antiga, ninguém reclona
- [ ] Aprovar ou trocar o que foi proposto no High Concept sem passar pelo grupo:
      gênero, plataformas, nº de jogadores, classificação etária, objetivos
      secundários, controles e público-alvo
- [ ] Quem fica na rua e quem fica na casa — a divisão é metade da equipe em
      cada frente, mas os nomes não estão amarrados
- [ ] **Estrutura de pastas** — `rua/` e `casa/` nasceram como pasta por
      frente, e são provisórias. Renomear é barato enquanto cada frente couber
      numa pasta
- [ ] Convenções de código e de cena — inclusive **em que idioma** nomear node,
      variável e arquivo. Está tudo em português, seguindo o que já existia,
      **inclusive os nomes das ações do Input Map**; não é decisão tomada
- [ ] **A costura entre os dois modos** — o autoload `Travessia` é proposta
      (`dia`, `mochila`, `documentos` e as duas funções de troca de cena). É a
      única decisão de arquitetura que as duas frentes tocam
- [ ] **O prazo virou 30 dias em 09/09/2026, e isso reabre a leitura de
      escopo.** O argumento levado ao professor era *cada dia é uma fase* + a
      terceira opção dele, *cerca de 10 níveis, ondas ou estágios* — com 30 dias
      essa conta não fecha mais. Ou "fase" deixa de ser o dia, ou a leitura
      passa a ser outra. É conversa de mesa, e é a mesma conversa da calibragem
      de escopo
- [ ] **Com 30 dias o prazo sobra.** A cura pede 4 documentos e o bairro tem 6 —
      dá para fechar na primeira semana, e os outros 23 dias não cobram nada. Um
      prazo que ninguém alcança não é pressão, é enfeite. As três saídas estão
      em *Quantos documentos a cura pede*, e o `conferir_fim.tscn` mede isso e
      avisa a cada rodada
- [ ] Os números de feel do relógio e da noite: **180 s de luz**, **150 s de
      noite**, **vasculhar gastando o dobro**, **+14 zumbis pela noite** e
      **+35% de vista** (`DURACAO_DO_DIA`, `DURACAO_DA_NOITE`,
      `CUSTO_DO_VASCULHO`, `ZUMBIS_DA_NOITE`, `VISTA_A_MAIS_DE_NOITE`).
      Provisórios, e o único jeito de decidir é jogando — o que a direção
      fechou em 09/09 foi a **forma** da noite, não os números
- [ ] **A mochila tem limite de espaço?** O one-pager declara *"mochila, com o
      espaço já ocupado visível"*, o que supõe um teto — e teto cria viagem:
      enche, volta, sai de novo. Não implementei porque como ele conversa com
      o vasculho (o móvel não esvazia? sobra dentro dele?) tem várias respostas
- [ ] **Quantos documentos a cura pede, e o que mais ela consome.** Hoje são 4
      dos 6 que o bairro tem, e é número provisório segurando uma decisão que é
      do modo Casa. Ver *Quantos documentos a cura pede*
- [ ] **Morrer devia acabar a partida?** Hoje custa o dia. O High Concept só
      declara dois desfechos e nenhum é morrer, mas é decisão de mesa
- [ ] **A escalada por dia** — um zumbi a mais a cada dois dias
      (`UM_ZUMBI_A_MAIS_A_CADA`), que leva o dia 30 a 27 de dia e 41 de noite.
      Provisório, e calibrado no prazo: se o prazo mudar, este muda junto
- [ ] Divisão de tarefas

## O bairro e a mecânica de vasculhar (`rua/`)

**07/09/2026.** A primeira cena de verdade, e o que roda no F5. É o passo 1 dos
cinco que levam à Alfa: **a core mechanic sozinha**, sem zumbi, sem prazo e sem
arte, só para descobrir como o vasculho tem que se sentir.

Encoste num móvel — geladeira, armário, cômoda, estante, caixa, carro
abandonado, lata de lixo — e **segure `E`** até a barra encher. O que sair
aparece em cima do móvel e no console.

| Tecla | O que faz |
|---|---|
| `WASD` ou setas | andar |
| `Shift` | correr |
| `E` | vasculhar (segurar) |

As ações estão no **Input Map** do `project.godot`, por `physical_keycode` — o
WASD fica no mesmo lugar em teclado que não seja QWERTY. Os controles são os que
o High Concept declara.

**Não escreva comentário no `project.godot`.** O editor do Godot reescreve o
arquivo a cada save: apaga todo comentário e infla cada tecla numa linha longa.
Já aconteceu — a explicação do `physical_keycode` e a do autoload `Travessia`
moravam lá e sumiram no primeiro save. O que precisar ser dito sobre aquele
arquivo se diz aqui.

### O mapa é um bairro, no estilo Project Zomboid

**Refeito em 07/09/2026, ampliado em 08/09.** Antes era uma rua reta com casas
maciças. Agora são **duas ruas se cruzando** e quatro quadras, com lote,
quintal, entrada de carro, cerca de divisa e galpão no fundo. Nove casas, um
mercadinho de esquina e três galpões — 40 móveis, mais do que dá para vasculhar
num dia, que é o ponto.

Três coisas foram copiadas do PZ, e são as que mudam a mecânica:

1. **Toda construção se entra, e o interior está na mesma cena** — sem tela de
   carregamento. Isso responde uma pergunta que estava aberta aqui: interior é
   cena própria ou a mesma? É a mesma. Entrar te fecha num lugar de onde não dá
   para fugir em linha reta, e é isso que faz vasculhar custar algo.
2. **O telhado sai quando você entra.** De fora, a construção é opaca: só a
   marca da porta aparece. A planta, os móveis e o que tem dentro só se veem
   entrando. Sem isso o mapa inteiro se lê da calçada e vasculhar deixa de ser
   exploração.
3. **O loot está em móvel dentro de quarto**, e o conteúdo combina com o móvel —
   geladeira dá comida, cômoda dá roupa e remédio, estante dá livro e pilha.
   Não é item solto na calçada.

**O que não foi copiado é a câmera.** PZ é isométrico; o nosso High Concept
declara top-down. Foi copiada a planta do bairro, não a projeção.

### A escala tem uma referência: o corpo do jogador

**28 x 40 px** (`rua/jogador.tscn`). Toda medida do `bairro.gd` existe em
relação a ele, e o cabeçalho do arquivo traz a tabela de conversão.

O bairro **foi ampliado em 08/09/2026** porque, no zoom de jogo, tudo ficava em
cima do personagem — quarto de 3,6 corpos de altura, beco de 1,4 corpo de
largura. A arquitetura cresceu ~1,8x e **o jogador ficou do mesmo tamanho**, que
é o que dá a sensação de escala.

| O que | Antes | Agora |
|---|---|---|
| quarto do fundo | 5,4 x 3,6 corpos | 9,8 x 6,6 |
| beco entre duas casas | 1,4 corpo | 3,9 |
| vão de porta | 2,5 corpos | 3,6 |
| largura da rua principal | 5,5 corpos | 10 |

Duas coisas **não** cresceram 1,8x, de propósito:

- **O móvel cresceu ~1,35x.** Crescendo junto com o quarto, o quarto
  continuaria igualmente cheio — o que se queria era sobrar cômodo. O carro é a
  exceção e cresceu junto, porque carro do lado de uma pessoa é grande mesmo.
- **A velocidade subiu ~1,3x** (280 andando, 460 correndo). Parte do ponto é o
  mundo passar a parecer grande; se ficar arrastado, é esse o número a mexer.

Se for ampliar ou reduzir de novo: são números do `bairro.gd`, mais o tamanho do
móvel e a velocidade — e **rode o `conferir_bairro.tscn` depois**.

### Os arquivos

- `bairro.tscn`… não existe: o layout é **dado**, não cena. Está todo em
  `bairro.gd`, e é o único arquivo a mexer para mudar o mapa
- `rua.tscn` — a cena, e é minúscula: `Relogio`, `Cenario`, `Jogador`,
  `EntradaDeCasa`, `Telhados` e `Hud`. Tudo o mais é gerado
- `mochila.gd` — o que você está carregando hoje, e a regra de que **só entra
  em casa o que passou pela porta do porão**. Ver a seção própria abaixo
- `vasculhavel.gd` — **é a core mechanic**. `Area2D` que enche uma barra
  enquanto a ação `vasculhar` estiver segurada e o jogador estiver dentro do
  alcance. O que separa uma lata de lixo (1,5 s) de uma porta (5 s) é só a
  `duracao` e o que tem dentro: mesmo verbo, custos diferentes — que é o que a
  Alfa cobra como *aplicabilidade da core mechanic*
- `jogador.gd` — andar e correr, e nada mais. Ele não sabe vasculhar: quem lê a
  tecla é o próprio vasculhável, então dá para espalhar coisa vasculhável pela
  cena sem tocar no jogador
- `entrada_de_casa.gd` — a porta do **porão**, dentro da sua casa. Segure `E`
  por 1,2 s e o dia na rua encerra. Ver a seção da travessia abaixo
- `bairro.gd` — **os dados do mapa**: ruas, construções, quartos, cercas,
  bosques, móveis e as tabelas de loot, mais a geometria que calcula parede,
  divisória, quarto e vão de porta. Fonte única
- `cenario.gd` — desenha o chão no `_draw()` e gera no `_ready()` a colisão, os
  móveis e as árvores a partir do `bairro.gd`. Retângulo de cor chapada, sem
  imagem nenhuma
- `telhados.gd` — desenha os telhados por cima de tudo e esconde o da
  construção onde o jogador está. Tem que ser o **último irmão** da cena: o
  Godot desenha na ordem da árvore
- `zumbi.gd` — o zumbi. Campo de visão com parede cortando, chamado de horda e
  toque que interrompe o vasculho. Ver a seção própria abaixo
- `navegacao.gd` — grade A* montada dos retângulos de obstáculo que o cenário
  gerou. É o que faz o zumbi **achar o vão da porta** em vez de encalhar na
  parede
- `relogio.gd` — o relógio: a luz que acaba, o vasculho gastando ela mais
  rápido, e o `noite()` que todo mundo lê para apertar. Ver a seção própria
  abaixo
- `hud.gd` e `hud.tscn` — a HUD nos três cantos que o one-pager declarou, o
  aviso da noite e o escurecer
- `conferir_bairro.tscn`, `conferir_zumbi.tscn`, `conferir_relogio.tscn`,
  `conferir_mochila.tscn` e `conferir_fim.tscn` — **ferramentas, rodam com
  F6.** Ver abaixo

### Duas coisas de propósito

**A zona de alcance é que obriga a ficar parado.** Sair de perto interrompe o
vasculho, e isso não é regra escrita em lugar nenhum — é consequência de o
`Area2D` deixar de detectar o jogador. É de graça, e é onde a pressão vai
morder.

**O progresso parcial fica onde parou** (`DECAIMENTO = 0.0` no
`vasculhavel.gd`). Dá para vasculhar em mordidas: avança um pouco, recua quando
o zumbi chega, volta e termina. Com um valor alto, cada interrupção custa tudo e
o vasculho vira aposta. **É a decisão de feel mais importante do projeto e ainda
não foi tomada** — é uma constante justamente para testar os dois antes de
escolher.

Com o relógio do passo 3 no lugar, o `0.0` **deixou de ser de graça**: voltar e
terminar depois gasta luz do dia de novo, e luz é dia. A interrupção já custa
algo mesmo com decaimento zero, e é isso que muda a pergunta — não é mais "o
progresso volta ou não?", é "quanto do dia essa mordida a mais vale?".

### Mexeu no layout? Rode o `conferir_bairro.tscn` (F6)

Ele varre o mundo com o corpo do jogador numa grade, faz flood fill de onde
você nasce e confere se dá para **chegar a pé em todo móvel e em todo quarto de
toda construção**. Imprime o resultado e sai.

Não é zelo: na primeira vez que rodou, **38 dos 41 móveis estavam
inalcançáveis** e nada disso aparecia lendo o código nem jogando dois minutos.

- Móvel encostado sempre na parede de cima — em casa de fachada ao norte isso
  punha a geladeira em cima do vão da porta e trancava o quarto
- Árvore sólida sorteada no mundo inteiro, tapando o beco entre duas casas e a
  porta do galpão. Por isso árvore agora só nasce nos `BOSQUES` declarados
- Cerca de fundo a 40 px da porta do galpão — o jogador tem 40 de altura e não
  cabia na frente dela

Layout de greybox se mexe por número, e número errado fecha caminho sem avisar.
Rodar isso custa dois segundos.

### O zumbi (`zumbi.gd`)

**08/09/2026.** Escrito do zero para servir a core mechanic: ele **existe para
atrapalhar o vasculho**, não para ser um combate. Nada foi reaproveitado do
`inimigo.gd` da cena de teste, que perseguia em linha reta de qualquer distância
e atravessava o mapa.

São treze de dia, espalhados pelo bairro — alguns na rua, alguns no quintal e
**dois dentro de construção**, que é o que faz entrar numa casa não ser abrigo
garantido. Não há sistema de onda; é povoamento, como no PZ.

**À noite chegam mais catorze**, e a vista dele cresce de 520 px para 702. Quem
manda nisso é o relógio, e está na seção da noite abaixo — aqui o zumbi só lê
um número.

Os três comportamentos vêm direto do High Concept:

1. **Campo de visão.** Ele não sabe onde você está: vê num cone de 110° até
   520 px, e **parede corta a linha de visão**. Entrar numa casa quebra a
   perseguição — e ficar dentro dela com ele te encurrala.
2. **Horda.** Quem enxerga você chama quem está vagando num raio de 700 px. Um
   zumbi não é ameaça, três são. O *ritmo de horda* que o High Concept pede sai
   daí, não da quantidade.
3. **Pressão sobre a mesma ação.** O toque interrompe o vasculho e tira vida.
   Não existe atacar de volta: a resposta é sair de perto.

**Ele é mais lento que você andando** — 165 contra 280, e 460 correndo. Dá para
sempre fugir, de propósito: o que ele tira não é vida, é o tempo que você
precisava para terminar de vasculhar.

O `interromper()` do vasculhável, que estava sem cliente desde 07/09, agora tem
um. E a ligação é indireta: o zumbi chama `levar_dano()` no jogador, o jogador
emite `atingido`, e é o **vasculhável** que escuta esse sinal. O zumbi não sabe
que móvel existe e o móvel não sabe que zumbi existe.

Ele acha o caminho por uma **grade A*** (`navegacao.gd`), montada dos retângulos
de obstáculo que o cenário acabou de gerar. A malha de navegação do Godot foi a
primeira tentativa e não serviu: `bake_navigation_polygon()` sobre este bairro
(umas 250 colisões num mundo de 5760 × 3600) travou o processo, cinco minutos
sem sair uma linha.

O cone de visão aparece desenhado na tela (`MOSTRAR_A_VISTA` no `zumbi.gd`).
É **auxílio de protótipo**, não decisão de design: sem ver o cone não dá para
entender por que ele te viu ou não.

### Mexeu no zumbi? Rode o `conferir_zumbi.tscn` (F6)

Confere seis coisas: ninguém nasce dentro de parede, a navegação acha caminho
para dentro de casa, parede corta a visão, ele persegue e o toque interrompe o
vasculho, ele entra na casa atrás de você, e o chamado da horda funciona.

Achou três bugs na primeira rodada, todos de comportamento — nenhum dava erro
em tela:

- **Desistência por tempo fixo** (4 s) fazia ele parar no meio do caminho:
  atravessar a casa da calçada até o quarto do fundo dá 1085 px, que a 165 px/s
  leva 6,6 s. Entrar em casa virava abrigo garantido.
- **Desistência por distância em linha reta** era pior: contornando a casa para
  chegar na porta a linha reta *aumenta*, e ele desistia justamente quando
  estava fazendo a coisa certa. Hoje é por distância andada.
- **No fim do caminho** ele devolvia direção zero e ficava parado até o
  recalculo, andando a menos da metade da velocidade dele.

### O relógio, a noite e a HUD (`relogio.gd`, `hud.gd`)

**08/09/2026, e a noite refeita em 09/09.** É o passo 3: a segunda pressão em
cima de vasculhar, e a primeira que não se resolve fugindo.

O dia tem **180 s de luz** — 07:00 às 19:00 na HUD — e **vasculhar gasta luz em
dobro**: o segundo que passa mais o segundo que custa. Andar gasta 1 s de dia
por segundo; vasculhar gasta 2. O zumbi cobra em vida; o relógio cobra em
**dia**, que é a moeda que não volta, porque o prazo da cura não espera.

Os 40 móveis do bairro somam 116 s de vasculho, que dão **233 s de luz** — mais
do que um dia inteiro, e isso sem andar um passo. É o que torna verdadeira a
promessa do mapa lá em cima: um dia não dá para limpar o bairro, então escolher
onde gastar o dia é o jogo.

**O prazo da cura são 30 dias** (`Travessia.PRAZO_DA_CURA`), decididos em
09/09/2026. No dia 30 a casa não deixa mais sair.

Eram 10 até então, e o número não era só feel: era a leitura de escopo levada ao
professor — *jogo arcade que acaba no game over, cerca de 10 níveis, ondas ou
estágios*, com cada dia sendo uma fase. **Com 30 dias essa conta não fecha
mais**, e isso está anotado nas pendências: ou "fase" deixa de ser o dia, ou a
leitura passa a ser outra.

Duas coisas eram calibradas em cima do prazo e mudaram junto: a escalada de
zumbis por dia e o mato tomando o terreno. Uma não mudou e é a que importa —
**quantos documentos a cura pede**, ver a seção do fim do jogo.

#### Às 19:00 a noite não te tira da rua — ela aperta

**Decisão de direção, 09/09/2026.** A primeira versão fazia o dia acabar às
19:00: a tela trocava e você aparecia em casa. Estava errado, e o motivo é
simples — **o jogo te resgatava**. Ficar até tarde não custava a volta pra
casa, custava um corte de cena. Voltar tem que ser uma travessia, não um botão.

Agora anoitecer não muda de cena. O que muda é a rua:

- **A rua enche.** Mais 14 zumbis ao longo da noite, chegando **pelas quatro
  bocas de rua nas bordas do mundo** — de fora do bairro, e não brotando do seu
  lado. São 13 no começo do dia e 27 às 05:00: mais que o dobro. Nascer longe é
  de propósito, e é o que dá o tempo entre um aparecer e ele te achar; zumbi
  que brota do seu lado não é aperto, é sorteio.
- **Eles enxergam mais longe** — de 520 px para 702 na noite fechada. Não é
  realismo, zumbi não vê melhor no escuro: é que ficar invisível andando a
  noite toda tiraria o aperto dela.
- **A tela escurece, mas sem virar tela preta.** O escuro para em 60% e fica
  lá — dá para continuar lendo o bairro e achar o caminho de casa. Isso foi
  pedido explicitamente: o que aperta a noite é a rua encher, não você não ver.

E **o jogo avisa**, em vez de só ficar difícil e esperar que você descubra: um
aviso aparece embaixo do relógio às 19:00 e vai piorando — *"Anoiteceu — melhor
voltar pra casa"*, *"A rua está enchendo — volte pra casa"*, *"Você não vai
aguentar a noite"*.

**Às 05:00 amanhece, e aí sim o dia vira à força.** É o teto: dá para aguentar
a noite inteira e perder o dia sem morrer. Mas os três jeitos de o dia acabar
não valem o mesmo, e a casa diz qual foi — `Travessia.fim_do_dia`:

| | |
|---|---|
| `PELA_PORTA` | você trancou o porão. O único bom |
| `AMANHECEU_NA_RUA` | a noite passou por cima de você |
| `SEM_VIDA` | você não aguentou |

Hoje a diferença é só o texto na tela da casa. **É no passo 4 que ela vira
consequência:** com a mochila existindo, quem não entra pela porta volta de mão
vazia — e é isso que faz o aviso das 19:00 valer algo.

#### A HUD está nos cantos que o one-pager declarou

Topo, o dia e quanto falta para o prazo, mais a hora; inferior esquerdo,
vida/fome/água; inferior direito, a mochila. Não inventei layout — a peça de
entrega já disse onde cada coisa fica, e é essa tela que vale 2 na Alfa.

É **texto puro**, de propósito: o critério é a tela ser coerente com a que o
documento declarou, não ser bonita. **Fome, água e mochila aparecem como "—"
porque ainda não existem** (passo 4). Deixar o campo vazio na tela é melhor que
escondê-lo: é o mapa do que falta, e quem for fazer o passo 4 acha o lugar
pronto.

#### Onde cada peça mora, e por quê

**Não existe "sistema de noite".** A noite é um número — `relogio.noite()`, de
0 a 1 entre as 19:00 e as 05:00 — e cada um lê e reage por conta: o cenário
traz mais zumbi, o zumbi enxerga mais longe, a HUD avisa e escurece a tela. Um
lugar só decide que horas são, e ninguém precisa combinar com ninguém. Mexer no
aperto da noite é mexer numa constante de quem sente o aperto.

O relógio de **dentro** de um dia é coisa da rua, e nasce cheio cada vez que a
cena da rua carrega. A **contagem de dias, o prazo e como o dia acabou**
atravessam os dois modos e moram no `Travessia`, porque a casa também precisa
deles.

Vasculhar gastar luz passa por um sinal: o `vasculhavel.gd` emite `vasculhando`
e não sabe que existe relógio, o `relogio.gd` não sabe que existe móvel, e
**quem liga os dois é o `cenario.gd`** — que é quem cria o móvel. Mesmo arranjo
do zumbi com o vasculho: a pressão chega de fora, e o arquivo da core mechanic
continua sem conhecer ninguém.

### Mexeu no relógio, na noite, na HUD ou no prazo? Rode o `conferir_relogio.tscn` (F6)

Confere seis coisas: o dia e a noite duram o que as constantes dizem e cada
virada avisa uma vez só; **vasculhar gasta luz mais rápido que andar**; **a
noite aperta** — o zumbi enxerga mais longe, a rua enche, a HUD avisa e o
escuro para onde foi combinado parar; anoitecer *não* te tira da rua e
amanhecer tira, dizendo que foi na força; a HUD lê os números certos e não
estoura sem relógio nem sem jogador; e no último dia a casa não devolve para a
rua. Ele também refaz a conta dos 233 s e reclama se o dia crescer o bastante
para o bairro caber nele.

Mede por chamada direta com delta fixo, e não contando quadro: em headless o
laço roda muito mais rápido que a física, e o relógio vive no `_process`.

Três coisas que ele ensinou, em duas rodadas:

- **O zumbi só procurava o relógio no quadro de física.** Como
  `alcance_da_vista()` é pública, quem perguntasse antes do primeiro quadro
  recebia a resposta de dia — e a noite não crescia. Foi a única falha de
  verdade, e agora a busca mora dentro da função.
- **Lambda em GDScript captura variável local por valor.** `func(): avisou =
  true` escreve numa cópia, então o teste nunca via o sinal `anoiteceu` sair e
  acusava o relógio. Contador de sinal tem que ser membro.
- **`change_scene_to_file()` arranca a cena atual da árvore na hora**, não no
  fim do quadro. As conferências que trocam de cena de verdade levavam a
  própria ferramenta embora: o `get_tree()` seguinte vinha nulo, o `quit()`
  nunca acontecia e o processo ficava rodando para sempre.

### A mochila e o documento (`mochila.gd`)

**09/09/2026.** É o passo 4, e é o que faz o vasculho ter para que servir. Até
aqui o loot era texto no console; agora ele entra numa mochila, atravessa para
a casa — ou fica na calçada.

**A mochila do dia não é a mochila da casa**, e a diferença entre as duas é o
preço da noite: **só entra em casa o que passou pela porta do porão.** Ser pego
pelo amanhecer ou cair sem vida deixa tudo na rua, e a casa te diz quanto ficou
lá. É isso que faz o aviso das 19:00 valer algo em vez de ser enfeite — antes
disso, ficar até tarde não custava nada de concreto.

#### Documento conta separado, e aparece diferente

As duas recompensas do vasculho não valem o mesmo. **A comida te mantém vivo; o
documento faz a pesquisa da cura andar** — é a moeda do eixo rua → casa, e é
por isso que ela tem linha própria na HUD, em âmbar, acima da mochila. Mesmo
sem a casa existir, esse contador já prova o eixo, que é exatamente o que o
passo 4 tinha que provar.

No móvel vasculhado o documento sai na cor da casa, com uma marca ao lado, e a
comida sai apagada embaixo — o one-pager pede que ele seja *"visualmente
distinto dos outros itens, com brilho"*, e no meio de lata de comida e pano
sujo tem que dar para ver de longe qual móvel valeu a pena.

Quem separa os dois é a mochila, e quem sabe o que é documento é o
`bairro.gd` (`e_documento()`) — pela própria lista de documentos, para não
existir uma segunda fonte de verdade.

#### O mundo esvazia e não repõe

**Móvel vasculhado ontem nasce vazio hoje.** É o que o PZ faz e o que o High
Concept declara — *a geografia é fixa e o que muda é o estado do mundo* — e é o
que finalmente dá peso ao relógio: **gastar o dia numa casa te custa aquela
casa amanhã.**

Vale mesmo no dia que deu errado. Se você tirou o loot do móvel, ele saiu do
mundo, tenha você chegado em casa ou não: ser pego pelo amanhecer queima o loot
*e* o dia.

O bairro é gerado sempre igual, de semente fixa, então o índice de um móvel é o
mesmo todo dia e serve de nome — `Travessia.moveis_vazios` guarda os índices, e
o `cenario.gd` consulta na hora de criar cada um. O sorteio roda para todo
móvel, inclusive os já vazios: pular um sorteio embaralharia o conteúdo dos
outros.

#### O que o bairro tem, ao todo

**33 itens comuns e 6 documentos** — e como não repõe, é isso que existe no
jogo inteiro. O `conferir_mochila.tscn` imprime essa conta.

⬜ **Seis documentos para trinta dias não fecha**, e é a pergunta mais aberta do
projeto. O bairro não repõe, então esses 6 são tudo o que existe na partida: a
cura pede 4 e dá para fechar na primeira semana. Ver *Quantos documentos a cura
pede*, na seção do fim do jogo, e as pendências no começo deste arquivo.

### Mexeu na mochila, no loot ou no que atravessa o dia? Rode o `conferir_mochila.tscn` (F6)

Confere cinco coisas: vasculhar enche a mochila e documento conta separado de
comida; **só entra em casa o que passou pela porta do porão** — nos três jeitos
de o dia acabar; o mundo esvazia e não repõe, e só o móvel vasculhado nasce
vazio; o bairro tem documento suficiente para a história andar; e a HUD mostra
o documento na linha dele.

O segundo é o que precisa de conferência de verdade: a regra vive numa ligação
indireta — a mochila escuta o `chegou_em_casa` do `Travessia` e lê o
`fim_do_dia` para decidir entregar ou perder — e quebra sem dar erro em tela.

### A rua piora com os dias

**09/09/2026, parte do passo 5.** O High Concept diz que *a rua vai ficando
mais apocalíptica conforme os dias passam*. A metade barata disso é estética —
o mato vai tomando o terreno, 30 tufos a mais por dia. A metade que muda o jogo
são os zumbis: **um a mais a cada dois dias.**

| | dia 1 | dia 5 | dia 15 | dia 30 |
|---|---|---|---|---|
| de dia | 13 | 15 | 20 | 27 |
| na noite fechada | 27 | 29 | 34 | 41 |

Eles entram pelas bocas de rua, como os da noite. O efeito é o prazo apertar de
dois lados ao mesmo tempo: quanto menos dias sobram, mais caro fica cada dia —
e amanhecer na rua no dia 28 não é a mesma coisa que no dia 2.

O ritmo **é calibrado no prazo**. Era um zumbi a mais por dia quando o prazo era
de 10 dias; com 30, o mesmo ritmo levaria o último dia a 71 zumbis, que não é
dificuldade, é sopa de zumbi. Se o prazo mudar de novo, este número muda junto.

### O que ainda não tem

**Fome e água.** São os dois campos que a HUD mostra como "—", e são o que
sobrou de declarado e não construído. Não estavam nos cinco passos: o High
Concept as lista como *variações de pressão sobre a mesma ação*, junto com o
tempo e a escuridão, e essas duas já existem. Fome é a terceira, e o mais
provável é que ela apareça consumindo o que a mochila trouxe — o que amarra ela
no modo Casa, que é quem decide o consumo.

A mochila **não tem limite de espaço**, e isso é decisão pendente e não
esquecimento — ver as pendências no começo deste arquivo.

Um detalhe de edição: os scripts não são `@tool`, então no editor os móveis
aparecem só como o contorno da colisão, e o bairro só se vê rodando.

## A travessia e o modo Casa (`travessia.gd`, `casa/`)

**07/09/2026.** O jogador **nasce dentro da sua própria casa**, que é a primeira
do lado norte e a única desenhada em tom quente — seguindo a separação por
temperatura da direção de arte: rua fria, casa quente. Como toda construção do
bairro, ela se entra: o telhado dela já está fora quando o jogo começa.

A porta do **porão** fica num dos quartos do fundo, não na fachada: para chegar
nela você atravessa a sala e o corredor. Encoste e segure `E` por 1,2 s — o dia
na rua encerra e o jogo troca para a cena da casa. Lá, `E` sai para a rua no dia
seguinte.

É **casa, não bunker** — o High Concept fechou em 03/09 que ela está trancada no
**porão** de casa. A sua casa é a única construção do mapa que não se vasculha.

Segurar em vez de apertar é de propósito: é a chave na fechadura com zumbi
chegando, e de graça evita entrar em casa sem querer ao vasculhar por perto.

### O que as duas frentes compartilham

Um autoload só, o `travessia.gd`, e é **proposta, não decisão tomada**:

| | |
|---|---|
| `Travessia.dia` | qual dia está correndo |
| `Travessia.PRAZO_DA_CURA` | quantos dias existem para a cura — 10, e é proposta |
| `Travessia.dias_restantes()` | quantos sobram depois de hoje |
| `Travessia.e_o_ultimo_dia()` | a casa consulta antes de deixar sair |
| `Travessia.fim_do_dia` | como o dia acabou: pela porta, amanheceu na rua ou sem vida |
| `Travessia.mochila` | os itens que **chegaram em casa**, de todos os dias |
| `Travessia.documentos` | os documentos que chegaram — contam separado |
| `Travessia.receber()` / `perder_na_rua()` | a mochila da rua chama um dos dois quando o dia acaba |
| `Travessia.moveis_vazios` | quais móveis já foram vasculhados; o mundo não repõe |
| `Travessia.DOCUMENTOS_PARA_A_CURA` | quantos documentos a pesquisa pede — 4, e é provisório |
| `Travessia.a_cura_esta_pronta()` | a casa pergunta antes de oferecer terminar |
| `Travessia.acabar_o_jogo()` / `recomecar()` | fim de partida e partida nova |
| `Travessia.entrar_em_casa()` | chamado pela porta, na rua |
| `Travessia.sair_para_a_rua()` | chamado pela casa; incrementa o dia |

**Nenhuma cena da rua conhece uma cena da casa, e vice-versa.** As duas conhecem
só esse arquivo. É o que permite as duas frentes andarem em paralelo e se
colarem em 04/11, que é o que o cronograma já reserva — e se a equipe quiser
outra costura, esse é o único arquivo que muda.

A rua **só acrescenta** na mochila. Quem constrói a casa decide o que é
consumido e esvazia o que gastou; por isso nada ali se limpa sozinho.

### `casa/casa.tscn` é lugar reservado

Não é a casa: é uma tela com o recado de quem chega nela, para a travessia
funcionar de ponta a ponta enquanto a outra metade da equipe não começa. Quem
for fazer essa frente **troca essa cena por uma de verdade e não precisa tocar
em nada da rua.**

Ainda sem dono: **onde fica o laboratório.** Os objetivos do High Concept falam
em *equipar a casa e o laboratório* — se é o porão junto com ela ou outro canto
da casa, é decisão de quem fizer essa frente.

## O fim do jogo (`fim_de_jogo.gd`)

**09/09/2026.** É o passo 5, e é o que faz "fase = dia" ficar legível: o jogo
passa a ter começo, meio e fim, que é o *jogo arcade que acaba no game over*
reivindicado como escopo.

São **dois desfechos, e só os dois que o High Concept declara** — a cura fica
pronta a tempo, ou o prazo se esgota. Quem decide os dois é a casa, porque é
ela quem faz a pesquisa e é ela quem segura o prazo; a tecla `E` na casa faz
três coisas diferentes, na ordem em que as regras decidem:

1. a cura está pronta → **terminar a cura** (vitória)
2. é o último dia → **o prazo acabou** (derrota)
3. o resto → sair para a rua no dia seguinte

A vitória vem antes do prazo de propósito: cura pronta no último dia é cura
pronta **a tempo**.

### A derrota é o diferencial, e por isso não parece uma derrota

A tela de derrota **não é uma tela de game over**: é uma paródia de final feliz
de casal. O quadro diz *"E FORAM FELIZES PARA SEMPRE"* em âmbar grande; o corpo
conta que o prazo acabou, ela saiu do porão e os dois seguem juntos — do mesmo
lado da porta. A palavra "game over" aparece **embaixo, em corpo 13, como aviso
legal**.

Isso não é enfeite: é o diferencial que o High Concept vende e é material
direto para o pitch de investimentos, que pergunta justamente por isso. O
`conferir_fim.tscn` **defende o tom**: reprova se o título entregar o jogo
(falar "derrota" ou "perdeu") ou se o "game over" não estiver menor que o final
feliz. É a única coisa que essa tela não pode perder quando alguém trocar o
texto por arte.

### Quantos documentos a cura pede

**Quatro** (`Travessia.DOCUMENTOS_PARA_A_CURA`) — e este número está segurando
um buraco de papel, não uma decisão.

⬜ **A pesquisa da cura é do modo Casa.** Quem fizer aquela frente decide o que
ela consome, em que ordem, e o que mais entra na conta: remédio? ferramenta?
tempo dentro de casa? O número existe para o ciclo fechar de ponta a ponta
enquanto isso não for decidido.

São 4 dos 6 que o bairro tem, e **a folga é de propósito**: com 6 um único dia
perdido carregando documento deixaria a partida impossível de ganhar sem
avisar. Com 4 dá para errar dois dias. O `conferir_fim.tscn` reprova as duas
situações — bairro com documento de menos, e bairro sem folga nenhuma.

#### E com 30 dias esse número deixou de fechar

Com o prazo em 10 dias, 4 documentos era apertado o bastante. **Com 30, o prazo
sobra:** o `conferir_fim.tscn` mede que a cura fecha em **0,9 dia de vasculho**
— 3% do prazo —, e os outros 29 dias não cobram nada. Um prazo que ninguém
alcança não é pressão; é enfeite, e o relógio, a noite e a escalada passam a
empurrar o jogador para um lugar onde não tem ninguém esperando.

A ferramenta avisa isso a cada rodada, como **ATENÇÃO** e não como falha: o
código está certo, o desenho é que tem o buraco. E as três saídas são todas de
mesa, nenhuma minha:

1. **A cura pede mais** — mas o bairro só tem 6, então isso só funciona junto
   com a saída 2 ou 3.
2. **O bairro dá mais documento** — mais móveis, ou um documento a cada menos
   móveis (`Bairro.CADA_QUANTOS_MOVEIS_UM_DOCUMENTO`). Custa escrever mais
   documentos, que é conteúdo de narrativa: hoje são 6 nomes, e repetir
   documento como moeda de progressão é esquisito.
3. **O mapa muda com os dias** — é o que o High Concept sugere ao dizer que a
   rua vai ficando mais apocalíptica. É a mais caro das três e a mais
   interessante: novos lugares reabrindo dá para que servir aos 30 dias sem
   inventar documento nem apertar a cura.

Enquanto nenhuma for decidida, **os 30 dias são um teto e não um aperto** — o
jogo funciona de ponta a ponta, e a partida acaba quando você quer que acabe.

### Morrer custa o dia, e não a partida

**Não é provisório, é decisão.** O High Concept declara dois desfechos, e
morrer na rua não é nenhum dos dois. Quem zera a vida acorda em casa sem nada
do que carregava, e paga **um dia do prazo** — que é o recurso caro do jogo.

⬜ Se a equipe quiser que morrer acabe a partida, é uma linha no `jogador.gd`
(`Travessia.acabar_o_jogo()`). Mas aí o jogo passa a ter um game over que o
documento não previu, e a paródia deixa de ser o único fim.

### Mexeu no fim, no prazo ou na escalada? Rode o `conferir_fim.tscn` (F6)

Confere seis coisas: **a partida dá para ganhar** — o bairro tem documento
bastante, com folga; juntar os documentos leva à vitória, e ela vem antes do
prazo; passar do último dia sem a cura leva à derrota, e a tela dela mantém a
paródia; morrer custa o dia e não a partida; a rua piora com os dias; e
recomeçar zera tudo, inclusive os móveis vazios — senão a segunda partida
começaria num bairro já saqueado.

A primeira é a única que fala do **desenho** e não do código, e por isso tem
categoria própria: além de reprovar bairro com documento de menos (que torna a
partida inganhável), ela mede em quantos dias a cura fecha no piso e levanta um
**ATENÇÃO** se isso for menos da metade do prazo. ATENÇÃO não reprova a rodada —
o código está certo —, mas aparece no fim, porque é o tipo de coisa que ninguém
descobre jogando dois minutos.

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
