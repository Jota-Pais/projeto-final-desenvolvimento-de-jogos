# Você me amaria se eu fosse um zumbi?

MVP de um jogo digital em **Godot 4**, feito em equipe para a disciplina de
Desenvolvimento de Jogos — Engenharia de Software, SATC 2026.2.
Prof. Me. Fabiano Naspolini de Oliveira.

Apocalipse zumbi. A namorada do protagonista foi mordida e está trancada no
porão; ele tem um prazo em dias para desenvolver a cura. O jogo alterna dois
modos a cada dia — a **rua**, top-down, onde está o gameplay, e a **casa**,
ponto e clique, onde está a narrativa.

## Como rodar

1. Baixe o **Godot 4.7.2 stable**, build padrão (não a .NET/C# — o projeto é em
   GDScript): <https://godotengine.org/download>. É portátil, não tem instalador.
2. Abra o `project.godot` desta pasta.
3. **F5** roda o jogo. **F6** roda a cena aberta.

O código se escreve no editor de script do próprio Godot. Quem preferir VS Code
pode ligar o editor externo com a extensão `godot-tools`, mas cena continua
sendo editada no Godot.

## Como se joga

| tecla | o quê |
|---|---|
| `WASD` / setas | andar |
| `Shift` | correr |
| `E` (segurar) | vasculhar um móvel, entrar em casa |
| mouse | mirar |
| botão esquerdo | atirar |
| `Tab` | abrir a mochila |

O dia começa com você na calçada, em frente à sua casa. O dia tem 420 s de luz
(07:00 às 19:00) e **vasculhar gasta luz em dobro**. Volte à porta de casa antes
de anoitecer e segure `E` nela: só entra em casa o que passou por ali. A cura
precisa de 4 documentos e o prazo é de 30 dias.

Você começa armado, com uma **Beretta 9mm** e um pente. O que o vasculho rende
são **balas** para ela e os **documentos** da cura; não existe outro item no
jogo (30/09/2026).

Dentro de casa é **só mouse**: o que dá para usar acende quando o mouse passa, e
clicar numa porta leva ao cômodo dela. As bolinhas do canto são a energia da
noite — examinar ela ou estudar um documento gasta uma. A cama encerra a noite.

## O que existe hoje

- **A rua** é jogável de ponta a ponta: mapa de 550 × 318 m traçado do desenho
  do João (`design/urussanga.png` — a cidade inteira, da floresta à prisão, com
  cada prédio nomeado), vasculhar, zumbi, relógio, mochila, pistola, e o dia
  fechando pela porta de casa. É uma **beta em blocos lisos** (30/09/2026):
  cada mancha do desenho virou polígono de chão ou retângulo de prédio, e o
  detalhe entra lugar por lugar a partir daqui.
- **A casa** (`casa/casa.tscn`) é uma **beta**: ponto e clique em primeira
  pessoa no molde de *No, I'm Not a Human* — cinco cômodos fixos (entrada, sala,
  cozinha, quarto, porão), energia por noite, a TV, o rádio e o olho mágico da
  porta, o quadro da pesquisa e o exame dela no porão, parte por parte, com o
  close recortado. Tela em baixa resolução, com grão e a noite esverdeada.
  **Quase tudo nela é proposta** (a planta, os 3 de energia, o que custa
  energia), e o que é texto da narrativa aparece entre colchetes.
- **Sem arte e sem áudio**: a rua é polígono e retângulo de cor chapada, e a
  casa é greybox de polígono e traço. A arte da casa entra por `casa/arte/<cômodo>.png`
  (640 × 360, em cor normal — o filtro leva para a noite) e substitui o greybox
  sozinha.

## As regras que o código implementa

- **Cada dia é uma fase.** A partida acaba na vitória (a cura fica pronta) ou na
  derrota (o prazo se esgota) — ver `fim_de_jogo.gd`.
- **A core mechanic é vasculhar sob pressão**, e a pressão vem de três lugares
  em cima da mesma ação: o zumbi cobra tempo, o relógio cobra luz e o prazo
  cobra dia. (A quarta, as 12 vagas da mochila cobrando escolha, saiu em
  30/09/2026 junto com o loot genérico: a mochila só carrega documento, e vaga
  que nunca falta não é regra.)
- **Há vida; não há fome nem água.** A camada de sobrevivência saiu do jogo em
  16/09/2026, por decisão de mesa, e a vida voltou em 30/09/2026 a pedido do
  João, como era: 100 pontos, cada toque de zumbi tira 12, e zerar acaba o dia
  na força — você acorda em casa de vida cheia, e a mochila fica na rua. O toque
  também empurra e interrompe o vasculho. Fome e água continuam fora.
- **O mundo esvazia e não repõe.** Móvel vasculhado ontem nasce vazio hoje.
- **A porta da fachada é a única entrada da sua casa.** Ela é sólida e fecha o
  vão inteiro: não se atravessa a pé. O único jeito de entrar é segurar `E`
  nela — e o que se entra é a cena da casa, não o interior do prédio. É por isso
  que o jogador nasce na calçada, e é a única construção do mapa assim.
- **Só entra em casa o que passou por essa porta.** Amanhecer na rua ou cair
  sem vida deixa a mochila na calçada e custa o dia — são os três únicos jeitos
  de um dia acabar.
- **Você começa armado, com uma Beretta 9mm e um pente** (30/09/2026). O
  vasculho rende balas, e só balas, além dos documentos; balas são equipamento:
  não ocupam vaga e não se perdem no dia que deu errado. O tiro mata de uma vez
  e chama a horda.
- **Os documentos são placeholders numerados.** Existem seis no mapa, a cura pede
  quatro, e é o que fecha a partida. ⬜ O que eles são, o que contam e onde ficam
  **não foi decidido pela equipe** — ver `design/narrativa.md`.

## Os arquivos

O layout do mapa é **dado, não cena**: não existe `mapa.tscn`.

| arquivo | o quê |
|---|---|
| `travessia.gd` | autoload. O dia, o prazo, o que chegou em casa — o **único** lugar onde a rua e a casa se encontram |
| `design/urussanga.png` | **o desenho do mapa**, feito pelo João — a fonte de tudo o que está na rua |
| `design/tracar_desenho.js` | lê o desenho, separa cada cor numa classe (grama, mata, pavimento, asfalto, milho, terra, água; vermelho, marrom e cinza são prédio), apaga texto e linha fina e escreve o traçado. `node design/tracar_desenho.js`, sem dependência |
| `rua/mapa_tracado.json` | o traçado: polígonos de chão, retângulos de prédio, blocos sólidos e veículos, em px do desenho. **Gerado — não editar à mão** |
| `rua/mapa.gd` | **o que cada coisa é**: os ROTULOS (nome, tipo, documento, a sua casa) apontados por coordenada do desenho, a ESCALA (24 px de mundo por px do desenho) e a montagem do mundo |
| `rua/construcao.gd` | as regras de uma construção qualquer (parede, vão de porta, quarto), que móvel vai em cada quarto e o que sai de um móvel (balas) |
| `rua/cenario.gd` | desenha o chão e gera colisão, móveis e árvores a partir do mapa |
| `rua/vasculhavel.gd` | **a core mechanic**: barra que enche enquanto `E` estiver segurado |
| `rua/jogador.gd` | andar e correr, e nada mais — quem lê a tecla de vasculhar é o próprio móvel |
| `rua/zumbi.gd` | visão em cone cortada por parede, chamado de horda, toque que interrompe |
| `rua/navegacao.gd` | grade A* — é o que faz o zumbi achar o vão da porta |
| `rua/relogio.gd` | a luz do dia, o custo do vasculho e a noite |
| `rua/mochila.gd` | os documentos que você carrega, as balas indo para o cinto, e o que atravessa o fim do dia |
| `rua/tela_da_mochila.gd` | a tela do `Tab`, com o mundo rodando atrás |
| `rua/pistola.gd` | a Beretta, as balas e o tiro chamando a horda |
| `rua/hud.gd` | a HUD nos três cantos |
| `rua/telhados.gd` | telhados por cima de tudo; some o da construção em que você está |
| `rua/entrada_de_casa.gd` | a porta da fachada da sua casa: sólida, e a única entrada. Segure `E` e o dia encerra |
| `casa/casa.gd` | o modo Casa: a fala, o clique, a energia e as regras da noite (cura, prazo) |
| `casa/comodos.gd` | **onde** fica cada coisa clicável em cada cômodo — dado, não cena, como o mapa da rua |
| `casa/desenho.gd` | o greybox de cada cômodo, o olho mágico e os closes do exame; sai do caminho quando há arte |
| `casa/ela.gd` | o estágio da transformação dela ao longo do prazo, e o laudo de cada parte do corpo |
| `casa/filtro.gdshader` | a noite esverdeada, o grão e a vinheta por cima da casa |
| `fim_de_jogo.gd` | as duas telas de fim de partida |

Mudar o mapa = mexer no **desenho** e rodar `node design/tracar_desenho.js`;
mudar o que uma coisa **é** (nome, tipo, documento, a sua casa) = `ROTULOS` em
`mapa.gd`. Mudar o que sai dos móveis = `construcao.gd`.

### Como o desenho vira mapa

- **Cada cor é uma classe.** Verde-escuro é grama, verde-claro é mata (com
  árvore sólida), cinza-claro é pavimento, cinza-escuro é asfalto, amarelo é
  milho, laranja é terra, ciano é água (sólida). Vermelho, marrom e cinza são
  prédio. Texto branco e linha fina são apagados.
- **Prédio é retângulo axial.** O jogo só sabe prédio reto (parede, quarto,
  móvel, telhado contam com isso), então cada mancha vira um ou mais
  retângulos — prédio torto vira um reto do mesmo tamanho no mesmo centro, L
  vira dois — e a mancha inteira continua pintada por baixo como lote. A porta
  fica do lado com mais chão aberto na frente; empate decide pelo asfalto mais
  perto.
- **Prédio pequeno demais para três quartos vira um quarto só**
  (`Mapa.FUNDO_MINIMO_PARA_TRES_QUARTOS`): abaixo de 340 px de fundo a estante
  da sala fechava a casa inteira.
- **O rótulo cai na mancha mais justa que contém o ponto.** Se o ponto do
  rótulo não cai em prédio nenhum, ele é um lugar (zona), com `rect` próprio ou
  o polígono de chão que o contém. Um rótulo pode trazer `rect` e `porta` à
  mão, para a mancha que o traçador não cortou bem (o Restaurante).
- **Ponto de teste é por nome, nunca por coordenada.** `Mapa.lugar(nome)`,
  `Mapa.ponto_do_png(ponto)`, `Mapa.construcao_com_a_frente_livre(...)` — uma
  coordenada escrita à mão silenciosamente passa a medir mato quando o desenho
  muda.
- **Árvore desenhada é árvore sólida.** Nada é só decoração: o que aparece no
  `_draw()` tem o obstáculo correspondente.

⬜ **Três coisas do mapa de hoje são provisórias**, à espera do João e da
equipe: qual casa é a sua (está numa casa sem nome do miolo, entre a
Prefeitura, a Praça e as Lojas), onde ficam os seis documentos, e os rótulos
miúdos do desenho que não dão para ler (três casas na estrada de terra do
sudoeste, os dois anexos do posto, os dois veículos da fazenda). Está tudo
marcado em `mapa.gd`.

## As ferramentas (F6)

Cenas que não são o jogo: rodam, imprimem um relatório e saem. **Rode a que
corresponde ao que você mexeu** — elas pegam a classe de bug que não aparece
jogando dois minutos.

| cena | confere | ~tempo |
|---|---|---|
| `rua/conferir_mapa.tscn` | a fase 0 (o dado: todo tipo existe, prédio cabe no mundo e em si, prédio não pisa em prédio, porta abre para chão livre, uma sua casa, uma armaria, seis documentos, todo rótulo nomeou algo) mais dá para chegar a pé em todo lugar com nome, todo móvel e todo quarto; a sua casa é a exceção e tem que estar selada; nenhum lugar sozinho fecha a cura; a identidade dos móveis bate com `Mapa.IMPRESSAO_ESPERADA` | ~60 s |
| `rua/conferir_construcao.tscn` | o mesmo prédio sintético nas 4 orientações — paredes fecham o anel do retângulo, os 3 quartos são disjuntos, a entrada de carro sai pela normal | segundos |
| `rua/conferir_zumbi.tscn` | visão, parede cortando a visão, chamado de horda e toque |
| `rua/conferir_relogio.tscn` | a luz do dia, o vasculho gastando em dobro, a noite e o aviso |
| `rua/conferir_mochila.tscn` | documento para a mochila e balas para o cinto, o que atravessa o fim do dia, o mundo não repondo, quanto o mapa rende, a HUD e a tela da mochila |
| `rua/conferir_arma.tscn` | você começa com a Beretta, balas são equipamento, o tiro mata, a parede corta, o estrondo chama a horda, o baleado não renasce |
| `rua/conferir_fim.tscn` | a partida dá para ganhar, a vitória, a derrota e a escalada de zumbis |
| `casa/conferir_casa.tscn` | os pontos de clique cabem na tela, todo cômodo se alcança, todo objeto responde, a energia gasta e apaga, o estudado atravessa a noite sem mexer na cura, o estágio dela anda com o prazo | segundos |
| `rua/retratar_mapa.tscn` | **gera** a imagem legendada do mapa em `design/mapa.png` — com `-- --regiao=oeste` (ou `centro`/`leste`, ou o nome de um lugar) na linha de comando, gera só aquele recorte em `design/mapa-<regiao>.png`. Para comparar com o desenho de origem |
| `rua/conferir_arte.tscn` | **mostra** PNGs de sprite sobre o greybox, na escala do jogo e ao lado da caixa do jogador, e salva a tela — `-- --sprites=a.png;b.png --saida=x.png`. É o passo "olhar antes de aprovar" de `design/arte-rua.md`; aceita `@escala` por sprite para mock de tamanho. Não roda em headless | segundos |
| `rua/recolorir_arte.gd` | **troca cores exatas** em todos os PNG de uma pasta, em cima do arquivo — `--headless -s res://rua/recolorir_arte.gd -- --pasta=... --trocas=DE:PARA;... [--faixa=y0:y1] [--ensaio]`. É o retoque de paleta de `design/arte-rua.md` (o olho verde do jogador), que se roda depois de cada download porque o servidor não sabe dele | segundos |

Todos rodam por F6 no editor **e** headless, com código de saída (0 = passou,
1 = achou problema) — dá para rodar sem abrir o editor:

```
Godot_v4.7.2-stable_win64_console.exe --path . --headless res://rua/conferir_mapa.tscn
```

`conferir_regressao_construcao.tscn` e `conferir_quadras.tscn` existiram até
P14: provaram, respectivamente, que a reescrita da construção em 4 direções
não mexeu em norte/sul (regressão bit a bit contra as 91 construções de
então) e que quadra → lote → prédio fecha sem sobreposição antes de
`lugares.gd` passar a consumir. Cumpriram o papel pontual e saíram do
repositório — o resultado ficou nos conferidores que continuam.

## O design

| arquivo | o quê |
|---|---|
| [`design/narrativa.md`](design/narrativa.md) | a história: elenco, lore, fluxo narrativo. É a fonte da seção 2 do GDD |
| `design/urussanga.png` | o desenho do mapa, do João (30/09/2026). É o que a rua tem que parecer; `design/mapa.png` é o que ela parece hoje |
| [`design/arte-rua.md`](design/arte-rua.md) | como a arte top-down da rua é gerada no PixelLab: a chamada fixa, o elenco e as animações, o orçamento e como entra no Godot. **Proposta** até a equipe decidir |
| `design/high-concept.pdf` e `design/high-concept-one-pager.html` | a peça entregue em 09/09/2026 — ficam como foram entregues |
| [`../README.md`](../README.md) | a disciplina: prazos, critérios e o que cada entrega cobra |

### O High Concept saiu daqui, e está no git

O `.md` que serviu de fonte para a peça acima **saiu da árvore em 16/09/2026**.
Ele era o registro de uma entrega já feita tentando viver como especificação: o
jogo mudava, ele ficava para trás, e toda mudança cobrava manutenção num
documento que ninguém ia reentregar.

**Nada se perdeu** — ele volta em um comando, e é de lá que saem público-alvo e
proto-persona, benchmarking, orçamento, cronograma, equipe e funções,
classificação etária, gênero e plataformas. O GDD cobra todos esses, e o pitch
puxa público e orçamento prontos de lá:

```
git show 0fcdbc1:design/high-concept.md > design/high-concept.md
```

Quando o GDD começar, é esse o ponto de partida — **lendo com data na mão**: o
que estiver lá vale como o que foi declarado em setembro, não como o que o jogo
faz hoje. Para o que o jogo faz hoje, vale este README e o código.

## Combinados de Git

1. **Uma cena, um dono por vez.** `.tscn` é texto e até mergeia, mas conflito em
   cena grande custa mais tempo do que combinar antes.
2. **Cada fase em arquivo separado**, para duas pessoas nunca editarem o mesmo
   arquivo de nível.
3. O cache do Godot (`.godot/`) e os builds exportados estão no `.gitignore` —
   não commitar.

## Sobre este arquivo

Ele descreve **como o projeto está e como mexer nele** — não o histórico de como
chegou aqui. Por que uma decisão foi tomada e o que havia antes está no
`git log` e nos comentários do próprio código, que é onde não envelhece sozinho.
