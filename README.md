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

Dos cinco passos que levam à Alfa, **três estão de pé**: a mecânica de
vasculhar (1), o zumbi (2) e o relógio do dia com a HUD (3). Faltam a mochila
com os documentos (4) e o fechamento do ciclo com a tela de fim de jogo (5).

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
- [ ] **O prazo da cura — 10 dias** (`Travessia.PRAZO_DA_CURA`). Não é só feel:
      é a contagem de fases que a leitura de escopo reivindica junto ao
      professor, então essa conversa e essa decisão são a mesma
- [ ] Os números de feel do relógio: **180 s de luz por dia** e **vasculhar
      gastando o dobro** (`DURACAO_DO_DIA` e `CUSTO_DO_VASCULHO`). Provisórios,
      e o único jeito de decidir é jogando
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
- `relogio.gd` — o relógio do dia: a luz que acaba, e o vasculho gastando ela
  mais rápido. Ver a seção própria abaixo
- `hud.gd` e `hud.tscn` — a HUD nos três cantos que o one-pager declarou, e o
  escurecer do fim de tarde
- `conferir_bairro.tscn`, `conferir_zumbi.tscn` e `conferir_relogio.tscn` —
  **ferramentas, rodam com F6.** Ver abaixo

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

São treze, espalhados pelo bairro — alguns na rua, alguns no quintal e **dois
dentro de construção**, que é o que faz entrar numa casa não ser abrigo
garantido. Não há sistema de onda; é povoamento, como no PZ.

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

### O relógio do dia e a HUD (`relogio.gd`, `hud.gd`)

**08/09/2026.** É o passo 3: a segunda pressão em cima de vasculhar, e a
primeira que não se resolve fugindo.

O dia tem **180 s de luz** — 07:00 às 19:00 na HUD — e **vasculhar gasta luz em
dobro**: o segundo que passa mais o segundo que custa. Andar gasta 1 s de luz
por segundo; vasculhar gasta 2. Não existe punição por anoitecer na rua: o
custo é o dia acabar onde você estiver, e cada dia gasto encosta no prazo da
cura. O zumbi cobra em vida; o relógio cobra em **dia**, que é a moeda que não
volta.

Os 40 móveis do bairro somam 116 s de vasculho, que dão **233 s de luz** — mais
do que um dia inteiro, e isso sem andar um passo. É o que torna verdadeira a
promessa do mapa lá em cima: um dia não dá para limpar o bairro, então escolher
onde gastar o dia é o jogo.

**O prazo da cura são 10 dias** (`Travessia.PRAZO_DA_CURA`). É proposta, e não é
só número de feel: é a leitura de escopo que o High Concept reivindica junto ao
professor — *jogo arcade que acaba no game over, cerca de 10 níveis, ondas ou
estágios* —, e nessa leitura cada dia é uma fase. Então o prazo **é** a
contagem de fases, e mexer nele mexe no escopo declarado. No dia 10 a casa não
deixa mais sair.

#### A HUD está nos cantos que o one-pager declarou

Topo, o dia e quanto falta para o prazo; inferior esquerdo, vida/fome/água;
inferior direito, a mochila. Não inventei layout — a peça de entrega já disse
onde cada coisa fica, e é essa tela que vale 2 na Alfa.

É **texto puro**, de propósito: o critério é a tela ser coerente com a que o
documento declarou, não ser bonita. **Fome, água e mochila aparecem como "—"
porque ainda não existem** (passo 4). Deixar o campo vazio na tela é melhor que
escondê-lo: é o mapa do que falta, e quem for fazer o passo 4 acha o lugar
pronto.

O que faz o relógio ser **sentido** não é o texto, é a tela escurecendo no fim
da tarde. Auxílio de leitura, como o cone de visão do zumbi — ninguém joga
olhando o canto da tela. Não é a arte de fim de tarde: paleta por hora do dia é
assunto de quem fizer arte.

#### Onde cada peça mora, e por quê

O relógio de **dentro** de um dia é coisa da rua, e nasce cheio cada vez que a
cena da rua carrega. A **contagem de dias e o prazo** atravessam os dois modos
e moram no `Travessia`, porque a casa também precisa deles.

Vasculhar gastar luz passa por um sinal: o `vasculhavel.gd` emite `vasculhando`
e não sabe que existe relógio, o `relogio.gd` não sabe que existe móvel, e
**quem liga os dois é o `cenario.gd`** — que é quem cria o móvel. Mesmo arranjo
do zumbi com o vasculho: a pressão chega de fora, e o arquivo da core mechanic
continua sem conhecer ninguém.

### Mexeu no relógio, na HUD ou no prazo? Rode o `conferir_relogio.tscn` (F6)

Confere cinco coisas: o dia dura o que a constante diz que dura e anoitece uma
vez só; **vasculhar gasta luz mais rápido que andar**; a HUD lê os números
certos e não estoura sem relógio nem sem jogador; o anoitecer encerra o dia; e
no último dia a casa não devolve para a rua. Ele também refaz a conta dos 233 s
e reclama se o dia crescer o bastante para o bairro caber nele.

Mede por chamada direta com delta fixo, e não contando quadro: em headless o
laço roda muito mais rápido que a física, e o relógio vive no `_process`.

As duas coisas que a primeira rodada ensinou eram do teste, não do jogo — e as
duas custariam horas de caça ao bug errado:

- **Lambda em GDScript captura variável local por valor.** `func(): avisou =
  true` escreve numa cópia, então o teste nunca via o sinal `anoiteceu` sair e
  acusava o relógio. Contador de sinal tem que ser membro.
- **`change_scene_to_file()` arranca a cena atual da árvore na hora**, não no
  fim do quadro. A conferência que faz a casa deixar sair levava a própria
  ferramenta embora: o `get_tree()` seguinte vinha nulo, o `quit()` nunca
  acontecia e o processo ficava rodando para sempre com a rua carregada.

### O que ainda não tem

Fome, água, mochila e morte — os passos 4 e 5. Nada disso precisa existir para
a mecânica ser avaliada, e a ordem é essa de propósito: em qualquer corte já
tem coisa demonstrável.

A vida aparece na HUD e numa barrinha em cima da cabeça. Zerar a vida encerra o
dia e te manda para casa — provisório, porque morte e tela de fim de jogo são o
passo 5. O prazo se esgotar é igual: a casa mostra o texto no lugar da tela de
derrota que o High Concept já descreveu, a paródia de final feliz.

Também não tem **estado que atravesse o dia**: ao voltar para o bairro, todo o
loot reaparece. O PZ gera o loot no primeiro acesso e não repõe, e o nosso High
Concept diz o mesmo — *a geografia é fixa e o que muda é o estado do mundo*.
Guardar o que já foi vasculhado é o passo 4 — e é o que vai dar peso ao
relógio: hoje gastar o dia numa casa não te custa aquela casa amanhã.

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
| `Travessia.mochila` | o que voltou da rua — vazio até o passo 4 |
| `Travessia.documentos` | idem |
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
