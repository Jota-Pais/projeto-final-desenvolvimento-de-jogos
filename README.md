# Você me amaria se eu fosse um zumbi?

MVP de um jogo digital em **Godot 4**, feito em equipe para a disciplina de
Desenvolvimento de Jogos — Engenharia de Software, SATC 2026.2.
Prof. Me. Fabiano Naspolini de Oliveira.

Apocalipse zumbi. A namorada do protagonista foi mordida e está presa no
quarto; ele tem um prazo em dias para desenvolver a cura. O jogo alterna dois
modos a cada dia — a **rua**, top-down, onde está o gameplay, e a **casa**,
ponto e clique, onde está a narrativa.

## Como rodar

1. Baixe o **Godot 4.7.2 stable**, build padrão (não a .NET/C# — o projeto é em
   GDScript): <https://godotengine.org/download>. É portátil, não tem instalador.
2. Abra o `project.godot` desta pasta.
3. **F5** roda o jogo: abre na tela de título, onde se escolhe o modo. **F6**
   roda a cena aberta (`rua/rua.tscn` pula o título e começa na campanha).

O código se escreve no editor de script do próprio Godot. Quem preferir VS Code
pode ligar o editor externo com a extensão `godot-tools`, mas cena continua
sendo editada no Godot.

## Como se joga

| tecla | o quê |
|---|---|
| `WASD` / setas | andar |
| `Shift` | correr |
| `C` | agachar e levantar — agachado você não faz barulho, e atrás de cobertura baixa (carro, entulho, sacos) o zumbi não te vê; anda mais devagar |
| `E` (segurar) | vasculhar um móvel, pegar pedra do chão, entrar em casa |
| scroll do mouse | trocar o que está na mão: a arma, a pedra, a garrafa |
| mouse | mirar |
| botão esquerdo | usar o que está na mão: com a arma, atirar; com a pedra ou a garrafa, segurar para mirar mais longe e soltar para jogar |
| `Tab` | abrir a mochila |
| `M` | abrir o mapa: só o que você já viu, o resto debaixo da neblina; o scroll aproxima, `M` ou `Esc` fecha. O jogo não para |
| `E` / `Esc` na cena inicial | `E` completa o texto que está sendo escrito, ou passa para o próximo; `Esc` pula a cena e vai direto para a rua |

O dia começa com você na calçada, em frente à sua casa. O dia tem 420 s de luz
(07:00 às 19:00) e **vasculhar gasta luz em dobro**. Volte à porta de casa antes
de anoitecer e segure `E` nela: só entra em casa o que passou por ali. A cura
precisa de 4 documentos e o prazo é de 30 dias.

Você começa armado, com uma **Beretta 9mm** e um pente — menos na partida que
começa pelo título, em que o **tutorial** dá a arma no fim do dia 1. O que o
vasculho rende são **balas** para ela, os **documentos** da cura e, desde
21/10/2026, **garrafas** — e no chão há **pedras** para pegar. Pedra e garrafa
se jogam para chamar o zumbi para longe: onde cai faz barulho, e o zumbi perto
vai ver. O que cada móvel rende está em `Construcao.RENDE` (proposta; a
equipe vai criar outros itens). **O barulho:** correr perto de um zumbi o
chama, andar colado também; agachado, nunca.

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
  pessoa no molde de *No, I'm Not a Human*, **em cima das fotos que a equipe
  tirou e pixelou** (16/10/2026) — entrada, sala (vista da TV e vista do sofá,
  virando entre elas), corredor, cozinha e quarto; sem porão. Ela fica presa no
  quarto, acorrentada à cabeceira, e ele dorme no sofá. Energia por noite, a TV,
  o rádio e o olho mágico da porta, os papéis da pesquisa na bancada e o exame
  dela, parte por parte, com o close recortado. Grão e noite esverdeada por
  cima. **Os 3 de energia e o que custa energia são proposta**, e o que é texto
  da narrativa aparece entre colchetes.
- **O áudio entrou** (20/10/2026), com os sons da pasta `sons` do Drive da
  equipe: música no menu, tiro de cada arma, estojo, impacto, clique sem bala,
  engatilhar ao trocar (`Q`), passos (na rua e no piso de dentro), ambiente
  dentro dos lugares e na casa, gemido do zumbi (de onde ele está), dano,
  porta, geladeira, botão sob o mouse e o game over. Ficaram de fora
  `NAO_USAR_MOMENTANEAMENTE` e as falas de `personagens/` (`.m4a`, que o Godot
  não abre, e o jogo ainda não tem NPC). **Volumes são proposta** — estão todos
  em `Som.VOLUME`. As fotos da casa ficam em `casa/arte/<cômodo>.png`
  (1280 × 720, cortadas em 16:9 de `design/casa-equipe/` por
  `design/casa_fotos.js`); o quarto é a foto da equipe refeita macabra
  (gerador + `design/sujar_quarto.js`).
- **O tutorial se passa na região rosa** em volta da sua casa (21/10/2026, a
  pedido do João). Ela é cercada pelo caos, não por bloqueio oficial — carros
  jogados, ônibus tombado, caçamba, entulho —, e o cerco **fica sempre, por
  enquanto**. Lá dentro ninguém corta terreno: cada lote tem muro, grade,
  alambrado, tábua ou tapume, e cada material diz se deixa ver e atirar através
  (`rua/camadas.gd`). Com você dentro, a noite traz a horda para dentro do
  cerco. **A peça sem arte do PixelLab ainda sai cinza.** A casa colada a
  leste da sua é a do Antônio, o vizinho do roteiro do tutorial
  (`design/narrativa.md`): selada, ninguém entra.
- **A cena inicial** (21/10/2026, a pedido do João: "uma cutscene no começo do
  jogo, sem ser na arte do jogo") vem entre a escolha do modo e a rua: seis
  quadros — a fuga pelo túnel, o zumbi rastejante, a mordida, você a levando no
  colo, a chegada em casa e a promessa na cama —, contados numa caixa de texto
  em segunda pessoa, com o texto aprovado por ele. **A arte ainda não existe**:
  o storyboard do João é só o conceito, e cada quadro espera um PNG da equipe
  em `cena_inicial/arte/`. Sem ele, o quadro fica escuro e só o texto conta.
- **O tutorial** (21/10/2026, entrega de 22/10) é a partida que começa pelo
  título, em dois dias. Dia 1, desarmado: a cena de abertura (você anda pela
  calçada na frente da sua casa, um zumbi sai correndo do terreno ao lado, você
  foge para a rua e o Antônio abre o portão e o mata), a
  conversa no portão (o roteiro do João: o susto, o portão fechando, o rádio
  por cima do muro e o favor em troca de uma arma), a apresentação pelo rádio
  (você é o Fabiano; ele, o "Rei do Apocalipse"), o caminho até a Cover
  Pizzaria, em que cada aula vem de um obstáculo de zumbis de posto (como eles
  veem, o barulho e agachar, a pedra e o arremesso para tirar o da porta), a
  piada do pepperoni na chegada, o vasculho, e a volta ao portão, que dá a
  9mm. Dia 2: explorar e atirar; o primeiro zumbi abatido fecha o tutorial.
  **Ainda são marcadores** (`[... — fala do João]`) as falas da volta ao
  portão em diante; as aulas do caminho são proposta, no estilo que ele pediu.
- **A arquitetura** (21/10/2026, a pedido do João: "que o restaurante realmente
  se pareça com um restaurante, que as casas não sejam só quadrados iguais").
  Todo prédio tem telhado de verdade e a fachada sul de frente, na vista
  inclinada dos muros. Os da região do tutorial foram feitos um por um
  (`rua/arquitetura.gd`): casas em L com varanda, garagem e área de serviço,
  oitão com a porta, a casa-búnquer do Antônio, a Delegacia em L com bandeira, o
  Prédio abandonado de quatro andares com a quina desabada, e a **Cover
  Pizzaria** (era o Restaurante) com toldo, deck, salão de toalha xadrez e
  forno a lenha. As ruas de lá ganharam faixa, poste com fiação, bueiro,
  mancha e lixo. Tudo por regra, sem custo de geração.

## As regras que o código implementa

- **Cada dia é uma fase.** A partida acaba na vitória (a cura fica pronta) ou na
  derrota (o prazo se esgota) — ver `fim_de_jogo.gd`.
- **Dois modos, escolhidos na tela de título** (15/10/2026): na **campanha**,
  cair sem vida na rua custa o dia — você acorda em casa sem o que carregava;
  no **hardcore**, cair acaba a partida, com uma terceira tela de fim no mesmo
  tom de paródia. É a única diferença entre os dois (`Travessia.modo`).
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
  de um dia acabar (no hardcore, cair acaba a partida em vez do dia).
- **Você começa armado, com uma Beretta 9mm e um pente** (30/09/2026). O
  vasculho rende balas, e só balas, além dos documentos; balas são equipamento:
  não ocupam vaga e não se perdem no dia que deu errado. O zumbi tem 100 de
  vida e o tiro da Beretta tira 20 — cinco tiros (05/10/2026: vida e dano se
  contam em unidade de vida, não em balas; até 03/10 um tiro matava) — e o
  tiro chama a horda. O corpo fica 60 s no chão, ou até o fim do dia se
  carregar algo, e se vasculha como um móvel — sai vazio por enquanto, porque
  o que o zumbi carrega não foi decidido. **As armas são oito** (lista do
  João, 05/10/2026): Revólver 38, Beretta 9mm, Doze 2 canos, Benelli semiauto,
  CTT40, Fireagle 9mm, Fall e M4, sempre na mão como sprite à parte; os
  números de cada uma são proposta, e `Q` troca de arma (protótipo — como se
  consegue outra arma não foi decidido). **A munição é por calibre** (05/10):
  .38, 9mm, calibre 12, .40, 7,62 e 5,56; cada caixinha do vasculho é de um
  calibre sorteado, a HUD mostra as balas da arma na mão e a tela da mochila
  lista o cinto inteiro. **Para os testes, o cinto nasce com 15 de cada
  calibre** (05/10/2026, a pedido do João); a regra de design continua "começa
  com a Beretta e um pente", e voltar é uma função em `travessia.gd`.
- **Os documentos são placeholders numerados.** Existem seis no mapa, a cura pede
  quatro, e é o que fecha a partida. ⬜ O que eles são, o que contam e onde ficam
  **não foi decidido pela equipe** — ver `design/narrativa.md`.

## Os arquivos

O layout do mapa é **dado, não cena**: não existe `mapa.tscn`.

| arquivo | o quê |
|---|---|
| `travessia.gd` | autoload. O dia, o prazo, o que chegou em casa — o **único** lugar onde a rua e a casa se encontram |
| `som.gd` | autoload. **O áudio**: `Som.tocar("armas/Beretta")` para efeito, `Som.tocar_em(nome, ponto)` para o que sai de um lugar do mundo, `Som.musica` e `Som.ambiente` para os loops (com fade, atravessando a troca de cena), e o volume de cada som. Headless fica mudo |
| `som/` | os sons, na mesma árvore da pasta `sons` do Drive (raiz, `armas/`, `menu/`), com os nomes sem acento. Som novo = largar o arquivo aqui e chamar pelo caminho sem extensão; o som do tiro de cada arma é o `som` da ficha em `rua/arma.gd` |
| `design/urussanga.png` | **o desenho do mapa**, feito pelo João — a fonte de tudo o que está na rua |
| `design/tracar_desenho.js` | lê o desenho, separa cada cor numa classe (grama, mata, pavimento, asfalto, milho, terra, água; vermelho, marrom e cinza são prédio), apaga texto e linha fina e escreve o traçado. `node design/tracar_desenho.js`, sem dependência |
| `rua/mapa_tracado.json` | o traçado: polígonos de chão, retângulos de prédio, blocos sólidos e veículos, em px do desenho. **Gerado — não editar à mão** |
| `rua/mapa.gd` | **o que cada coisa é**: os ROTULOS (nome, tipo, documento, a sua casa) apontados por coordenada do desenho, a ESCALA (24 px de mundo por px do desenho) e a montagem do mundo |
| `rua/construcao.gd` | as regras de uma construção qualquer (parede, vão de porta, quarto), que móvel vai em cada quarto e o que sai de um móvel (balas). Desde 21/10/2026, a **planta com recortes**: cantos tirados do retângulo, e a casa vira L ou T — parede, piso, quarto e "estar dentro" seguem a forma (`recortes_de`, `contem`, `volumes_de`) |
| `rua/cenario.gd` | desenha o chão e gera colisão, móveis e árvores a partir do mapa |
| `rua/vasculhavel.gd` | **a core mechanic**: barra que enche enquanto `E` estiver segurado. Desde 21/10/2026 o móvel sabe para onde olha (`olhando`): de frente é o desenho gerado (encostado na parede norte); de costas ou de lado, uma caixa na cor do desenho — nada mais gira |
| `rua/jogador.gd` | andar e correr, e para onde ele olha (para onde anda; para o mouse enquanto atira) — quem lê a tecla de vasculhar é o próprio móvel |
| `rua/zumbi.gd` | visão em cone cortada por parede, chamado de horda, toque que interrompe; a vida dele, o tiro que fere e o que derruba (corpo no chão); o **posto** (`guardar`): o zumbi que o tutorial põe parado olhando para um lado, até te ver ou ouvir |
| `rua/boneco.gd` | **a arte entrando**: lê a folha PNG + JSON que o PixelLab exporta e vira `AnimatedSprite2D`, uma animação por ação e direção (`andar_sul`, `vagar_noroeste`…), pé na caixa de colisão, escala 0,5 (20/10/2026: jogador e zumbi com metade do tamanho e da velocidade, câmera com zoom 2 — na tela o boneco fica como antes e o mundo, duas vezes maior). `mostrar()` para o que repete, `tocar()` para o que acontece uma vez (`atirar`, `dano`, `morrer`) — e devolve `false` se a folha não tem, para o código mostrar uma versão de graça. O jogador e o zumbi têm um |
| `rua/arte/<quem>/` | a folha de sprites de cada personagem, como o PixelLab exporta (PNG + JSON de layout): jogador com `andar`; zumbi com `vagar`, `toque` (ataque, 8 direções) e `morrer` (só no sul — o último quadro serve de morto no chão para as outras). **Gerada — não editar à mão**: retoque é no servidor |
| `rua/arte/armas/` | um PNG por arma (de 12 × 7 a 30 × 9 px), desenhado à mão em texto por `design/desenhar_armas.js`; trocável, mantendo o pixel do cabo da ficha |
| `rua/chao.gd` | **o chão em tiles** (14/10): lê o raster dos vértices (`rua/chao_tracado.png` + `.json`) e os tilesets Wang de `rua/arte/chao/`, escolhe o tile de cada célula pelos quatro cantos e pinta o TileMap inteiro ao abrir, em menos de um segundo. Vem antes do Cenario na cena, que por isso não pinta mais os polígonos do chão |
| `rua/chao_tracado.png` + `.json` | a classe de chão de cada vértice da grade de 32 px, gerada por `design/rasterizar_chao.js` a partir do mapa traçado. **Gerado — rodar de novo quando o desenho do mapa mudar** |
| `rua/arte/chao/` | os oito tilesets do chão, gerados no PixelLab (PNG 4×4 + JSON com `bounding_box` e `corners`) e retocados na paleta de fim do mundo, listados em `tilesets.json`; `paleta.json` é o retoque (tabelas por terreno mais a regra geral), para o próximo tileset sair igual |
| `design/rasterizar_chao.js` | rasteriza o mapa traçado na grade de tiles: `node design/rasterizar_chao.js`, sem dependência, ~20 s |
| `rua/ruas.gd` | **o chão da cidade** por cima do TileMap: desde 21/10/2026 pinta as camadas do `chao_da_cidade.gd` — o cinza claro de baldio por baixo, o quintal, o pátio e o baldio de cada prédio, o lote de grama do desenho, a calçada, a rua e o meio-fio de concreto com sarjeta — e a grama em volta do mapa, para a câmera da beira não ver o vazio |
| `design/tracar_ruas.js` | **refaz as ruas e a calçada a partir do desenho** (21/10/2026): o eixo de cada rua (esqueleto do asfalto) com a largura dela e trecho reto, a rua de largura constante com raio de meio-fio na esquina e rotatória redonda, a calçada de 2,5 m ao longo de toda rua, e o resto do cinza claro dividido pelo prédio mais perto (até 10 m). No desenho o cinza claro é a cidade em volta, não calçada — antes ele virava um mar de lajota. Escreve `rua/chao_da_cidade.json`. `node design/tracar_ruas.js`, ~10 s, depois do `tracar_desenho.js` |
| `rua/chao_da_cidade.json` | as camadas do chão da cidade em triângulos (o furo já resolvido), os eixos das ruas, as rotatórias e o meio-fio, em px do desenho. **Gerado — rodar `tracar_ruas.js` de novo quando o desenho mudar** |
| `rua/chao_da_cidade.gd` | lê o JSON e entrega as camadas em mundo; diz qual é o chão de cada resto de prédio pelo tipo da construção mais perto (quintal na casa, baldio no abandonado, pátio no resto) e responde `classe_em` para a faixa, o poste e a sujeira irem ao chão certo |
| `design/earcut.js` | triangula polígono com furo (o algoritmo do earcut): o Godot só triangula polígono simples |
| `design/desenhar_chao_da_cidade.js` | os ladrilhos `rua/arte/chao/cidade-*.png` por regra, sem emenda: o asfalto sem o xadrez de antes, a lajota da calçada, o cimentado do pátio, o quintal (grama rala e terra) e o terreno baldio (terra, mato, caco) |
| `rua/arte/chao/cheio-<classe>.png` | o ladrilho de 256 × 256 do tile cheio de cada classe, com as variações do chao.gd, que `ruas.gd` usa como textura; gerado por `design/ladrilhar_cheio.gd` (`Godot --headless --path . --script design/ladrilhar_cheio.gd`) |
| `design/paleta_de_classe.js` | gera um grupo de `paleta.json` a partir do tileset bruto de uma classe que a regra geral deixa com a cor errada (a água veio lodo verde, a mata v2 veio roxa): matiz e saturação fixos, valor por regra; os argumentos estão no cabeçalho do script. Depois, `retocar_chao.gd` |
| `rua/arte/barreiras/` | a arte dos muros, cercas e barricadas (21/10/2026), gerada no PixelLab a partir de um molde pintado: por tipo, `<tipo>-face.png` (um período de pilar a pilar, repetido ao longo do muro), `<tipo>-topo.png` e, se tem, `<tipo>-pilar.png`; e um sprite em pé por objeto solto (`onibus.png`, `cacamba.png`, `monte_entulho.png`), desenhado no tamanho dele. Gerados: muro de reboco, muro de bloco, tapume de zinco, cerca de tábuas, portão de chapa, grade sobre mureta, sacos de areia, o poste do alambrado e o ônibus; **por regra** (o próprio molde pintado, porque o gerado não prestou): a faixa de entulho, a tela do alambrado, a caçamba e o monte de entulho. Tipo sem arquivo aqui sai cinza (hoje só o arame farpado, que o mapa não usa). O muro de reboco é um só e ganha a cor de cada lote (`cor` no dado: branco, amarelo, rosa, verde-água); o ônibus queimado sai escurecido. Cada geração está registrada em `projeto-final/arte-rua.md` |
| `rua/arte/objetos/` | os sprites dos objetos da rua e dos móveis (árvores, carro, motorhome, mato, bomba, móveis), um PNG por tipo, que `vasculhavel.gd` e `cenario.gd` procuram pelo nome; a caixa de papelão sai de `desenhar_texturas.js` |
| `design/recortar_fundo.gd` | tira o fundo chapado de um sprite gerado que veio com fundo apesar do pedido (inunda a partir das bordas): `Godot --headless --path . --script design/recortar_fundo.gd -- <entrada.png> <saida.png> [tolerância]` |
| `design/juntar_folha.js` | junta linhas de animação de uma folha nova do PixelLab (outra conta) na folha antiga do mesmo boneco: `node design/juntar_folha.js <antiga.json> <nova.json> <saida.json> [animação...]` |
| `design/desenhar_texturas.js` | desenha por regra as texturas dos prédios (parede, piso, telha, zinco, laje, 64 × 64, emendáveis) e os sprites de porta e janela: `node design/desenhar_texturas.js rua/arte/predios` |
| `design/desenhar_arquitetura.js` | desenha por regra as texturas da arquitetura de 21/10/2026: telha romana, telha colonial, fibrocimento, reboco (claro, para a tinta de cada casa), tijolo à vista e bloco. Na textura de telhado a água cai para baixo; o `telhado.gd` gira para cada lado: `node design/desenhar_arquitetura.js rua/arte/predios` |
| `rua/arte/predios/` | as texturas e sprites acima; o cenário repete piso e parede nos retângulos de cada prédio, e os telhados (`rua/telhado.gd`) usam telha, fibrocimento, zinco ou laje conforme o estilo de cada um |
| `design/retocar_chao.gd` | aplica `rua/arte/chao/paleta.json` a um tileset recém-gerado e lista as cores que não conhece: `Godot --headless --script design/retocar_chao.gd -- entrada.png rua/arte/chao/paleta.json saida.png` |
| `design/desenhar_armas.js` | desenha as oito armas em pixel a partir de um texto e grava os PNG: `node design/desenhar_armas.js rua/arte/armas`, sem dependência |

| `rua/navegacao.gd` | grade A* — é o que faz o zumbi achar o vão da porta. Muro e cerca entram como segmento, e não como o retângulo que os envolve (21/10/2026) |
| `rua/barreira.gd` | **muros, cercas e barricadas** (21/10/2026): as regras de cada material — o que segura, a espessura da colisão, a altura da face —, o corte dos vãos e o desenho provisório de cada peça, em cinza, na vista inclinada. Por onde cada uma passa está em `mapa.gd` (`BARREIRAS`, `BARRICADAS` e a `REGIAO_DO_TUTORIAL`) |
| `rua/camadas.gd` | as camadas de colisão: o que barra o corpo, o que barra a vista do zumbi e o que barra o tiro — grade e alambrado seguram só o corpo; tábua e zinco tapam a vista, mas a bala atravessa. A **cobertura baixa** (carro, entulho, sacos de areia) só esconde quem está agachado atrás dela: eu me escondo, quem eu vejo não |
| `rua/relogio.gd` | a luz do dia, o custo do vasculho e a noite |
| `rua/mochila.gd` | os documentos que você carrega, as balas indo para o cinto, e o que atravessa o fim do dia |
| `rua/tela_da_mochila.gd` | a tela do `Tab`, com o mundo rodando atrás |
| `rua/tela_do_mapa.gd` | **o mapa do `M`** (21/10/2026): o desenho simples da cidade (rua, calçada, grama, prédio, muro) com neblina no que nunca passou na tela, enquadrando o que já se viu; marca você, a sua casa, os nomes dos lugares vistos e o objetivo do tutorial. O mundo roda atrás, como na mochila. É também quem marca o visto, a cada quadro, pelo que a câmera mostra |
| `rua/mapa_visto.gd` | a grade do que já se viu (célula de 32 px), guardada em `Travessia.mapa_visto`: atravessa os dias e zera na partida nova; já no formato da textura da neblina |
| `rua/mao.gd` | **a mão** (21/10/2026): o scroll troca o que está na mão (`Travessia.na_mao`) e o botão esquerdo usa; com a pedra ou a garrafa, segurar carrega a distância até o limite e desenha a mira (o arco, o alvo e até onde o barulho chama), e soltar joga |
| `rua/arremessado.gd` | a pedra ou a garrafa no ar e onde ela cai: o barulho chama todo zumbi perto (`foi_chamado`, o mesmo do tiro); a garrafa chama de mais longe e deixa cacos |
| `rua/bracos.gd` | **as mãos** (21/10/2026): a arma vai na mão que o desenho do boneco já tem — porte baixo, apontada para onde ele olha, balançando com o braço quando ele anda —, com o punho por cima do cabo e, nas armas longas, a outra mão no guarda-mão quando ela não aparece no desenho; segura a pedra e a garrafa, e ergue a mão para trás do ombro mirando o arremesso. Nada de braço desenhado do quadril até a arma: com as mãos do desenho na tela, viraria mão sobrando |
| `design/achar_as_maos.js` | acha a mão do jogador em cada quadro da folha (a mancha de pele abaixo do pescoço) e grava `rua/arte/jogador/maos.json`, que o `bracos.gd` lê: `node design/achar_as_maos.js rua/arte/jogador/Jogador_rua-Idle.json`. Rodar de novo quando a folha mudar |
| `design/sintetizar_arremesso.js` | os sons do arremesso (o assobio, a pedra no chão, a garrafa quebrando) sintetizados por regra em `som/arremesso/` — marcadores até a equipe de som trocar pelo arquivo de verdade |
| `rua/arma.gd` | a arma na mão: a ficha das oito (dano em unidade de vida, projéteis, espera, automática ou não, alcance, estrondo, desenho), o sprite apontado para onde ele olha, o tiro, o coice e o estrondo chamando a horda; `Q` troca (protótipo) |
| `rua/hud.gd` | a HUD nos três cantos |
| `rua/caixa_de_fala.gd` | **a caixa de fala** (20/10/2026): toda fala sai numa caixa embaixo da tela, com nome, retrato e o texto sendo escrito. `falar()` é de perto — o jogo para e o E avança —; `pelo_radio()` não para o jogo, e as linhas passam sozinhas. O texto das falas é da narrativa: quem chama manda as linhas. Está na rua, escondida até alguém falar |
| `rua/tutorial.gd` | **o tutorial** (21/10/2026): quando cada etapa e cada fala acontece — a cena de abertura sob roteiro, o objetivo no alto da tela com a seta, os obstáculos do caminho (`OBSTACULOS`, zumbis de posto que puxam cada aula do rádio), o item do favor na geladeira da Cover Pizzaria, a chegada, a 9mm, o dia 2. A etapa mora em `Travessia.tutorial` e atravessa os dias |
| `rua/falas_do_tutorial.gd` | **o texto das falas do tutorial**, e só ele — e o nome do item do favor (pepperoni). É aqui que o texto do João entra: o roteiro da conversa dele já está, as aulas do caminho são proposta |
| `rua/antonio.gd` | o Antônio na rua: parado no quintal dele, vira para o alvo e atira (clarão e som); quem decide quando é o roteiro |
| `rua/arte/antonio/` | a folha do Antônio na rua (`Antonio_rua-Idle`, parado em 8 direções, gerada no PixelLab) e o retrato de 64 px da caixa de fala |
| `rua/arte/jogador/retrato.png` | o retrato do protagonista na caixa de fala (21/10/2026, assustado), gerado no PixelLab a partir do busto da rotação sul; a íris saiu cinza e foi pintada do verde da folha |
| `rua/telhados.gd` | cria um telhado por construção e as coberturas, e esconde o telhado da construção em que você está |
| `rua/telhado.gd` | **o telhado e a fachada de uma construção** (21/10/2026), na vista inclinada dos muros: telhado de duas águas, quatro águas, meia-água ou laje, com cumeeira, beiral e oitão; a fachada sul de frente, com a tinta, o barrado, as janelas por andar (grade, cortina, tábua, quebrada, chapa), a porta e o letreiro; e o que fica em cima (caixa d'água, antena, placa solar, chaminé, lona, buraco, mato). É um nó do Y-sort: quem passa na frente aparece na frente |
| `rua/cobertura.gd` | a varanda, a garagem, a área de serviço, a lona e o pergolado em cima de um recorte da planta, e o toldo listrado da fachada; fica transparente com você embaixo |
| `rua/arquitetura.gd` | **o estilo de cada prédio**: os da região do tutorial um por um (planta, telhado, fachada, extras, enfeites — a Cover Pizzaria com salão, cozinha e forno a lenha), e o resto do mapa por regra do tipo, com variação sorteada. **A mobília** dos prédios da região também mora aqui (21/10/2026): cada móvel no cômodo e na parede que fazem sentido (sala com sofá e TV, cozinha com geladeira e bancada, quarto com cama e cômoda, banheiro com parede e porta, as celas da Delegacia), com o piso de cada cômodo. Fora da região, os móveis ainda nascem pela regra antiga (`posicoes_de_movel`) |
| `rua/arte/objetos/` (`cadeira_plastico`, `cadeira_plastico_lado`, `botijao`, `lixeira`) | os enfeites soltos gerados no PixelLab em 21/10/2026, aparados no opaco e desenhados a meia escala pelo `enfeite.gd`; o botijão e a lixeira ganham as outras cores tingidas no código, e a cadeira de costas e a tombada são montadas das duas vistas que vieram |
| `rua/arte/objetos/mobilia/` | os móveis gerados no PixelLab em 21/10/2026 (cama, sofá, rack com TV, mesa de jantar, pia com fogão, mesa da pizzaria, balcão, forno a lenha, bancada de massa, mesa de bar, guarda-sol, mesa da delegacia), de frente, como os móveis de vasculho; a chamada de cada um está no `arte-rua.md` |
| `rua/enfeite.gd` | os enfeites desenhados por regra: mesa e cadeira de plástico, guarda-sol, cavalete, botijão, lenha, lixeira, varal, churrasqueira, poste, orelhão, mastro, e por dentro da pizzaria mesa de toalha xadrez, balcão, forno, bancada. Os que têm pegada são cobertura baixa e entram na navegação |
| `rua/detalhes_da_rua.gd` | o chão com detalhe: no mapa inteiro, a faixa amarela no eixo de toda rua de mão dupla, o remendo, a rachadura, a mancha e o bueiro do asfalto, a lajota que falta e o mato na junta da calçada (mais perto do baldio) e o rebaixo do meio-fio na frente de cada portão; na região do tutorial, a faixa de pedestre, o lixo espalhado, o piso de cada recorte (lajota, deck, cimento, entulho) e onde ficam os postes (na calçada, a um palmo do meio-fio) |
| `rua/fiacao.gd` | os fios de poste em poste e os que descem para as casas, por cima de tudo |
| `rua/entrada_de_casa.gd` | a porta da fachada da sua casa: sólida, e a única entrada. Segure `E` e o dia encerra |
| `casa/casa.gd` | o modo Casa: a fala, o clique, a energia e as regras da noite (cura, prazo) |
| `casa/comodos.gd` | **onde** fica cada coisa clicável em cada cômodo — dado, não cena, como o mapa da rua. Desde 21/10/2026 cada objeto tem o **contorno** da silhueta dele na foto (traçado em cima da foto e conferido com zoom), e é nele que o clique pega e o destaque acende; o porta-retratos tem duas partes, uma por moldura |
| `casa/desenho.gd` | a foto de cada cômodo, como ela é, sem filtro, e o que vai por cima dela (olho mágico, rádio, TV ligada na tela medida da foto, papéis da pesquisa, ela no quarto), o destaque sob o mouse no contorno do objeto, a vista do olho mágico e os closes do exame. O contorno dela sai do próprio desenho (o alfa) |
| `casa/arte/<cômodo>.png` | as fotos da casa, 1280 × 720. **Geradas — não editar à mão**: `node design/casa_fotos.js` corta de `design/casa-equipe/` (a altura do corte de cada uma está no script) |
| `design/sujar_quarto.js` | a segunda camada do quarto macabro: escurece, mofo, sangue, arranhões e marcas de mão sobre `design/casa-equipe/quarto_colado.png` (a foto com as correntes e a cama do gerador já coladas) e amplia de volta para `quarto_macabro.png`. `node design/sujar_quarto.js`, depois `casa_fotos.js` |
| `casa/ela.gd` | o estágio da transformação dela ao longo do prazo, e o laudo de cada parte do corpo |
| `titulo.tscn` + `titulo.gd` | **a cena principal, o menu**: Jogar (que abre a escolha entre campanha e hardcore), Como se joga e Sair, sobre a capa |
| `arte/titulo/` | a capa do menu (`capa.png`, 320 × 180 gerada no PixelLab, mostrada ×4) e a fonte do título, Creepster, com a licença OFL ao lado |
| `cena_inicial/cena_inicial.tscn` + `.gd` | **a cena inicial** (21/10/2026), entre o título e a rua: seis quadros com a câmera andando devagar, troca com fade, tarjas e a caixa de texto embaixo. O texto de cada quadro (aprovado pelo João) e os sons, que são os de `som/`, estão em `QUADROS`. Anda sozinha, no tempo de leitura das falas do rádio; `E` adianta, `Esc` pula. `Travessia.comecar_partida` abre ela, e ela abre a rua |
| `cena_inicial/arte/<n>.png` | a arte de cada quadro, de 1 a 6. **Ainda não existe — é da equipe**: 16:9, de 1920 × 1080 para cima, sem texto nenhum (o texto é da cena). As tarjas tapam 12 % em cima e embaixo, então o que importa fica no meio |
| `fim_de_jogo.gd` | as três telas de fim de partida: a cura pronta, o prazo esgotado e, no hardcore, a queda na rua |

Mudar o mapa = mexer no **desenho** e rodar `node design/tracar_desenho.js` e
`node design/tracar_ruas.js`;
mudar o que uma coisa **é** (nome, tipo, documento, a sua casa) = `ROTULOS` em
`mapa.gd`. Mudar o que sai dos móveis = `construcao.gd`. Mudar um muro, uma
cerca ou uma barricada = `BARREIRAS` e `BARRICADAS` em `mapa.gd`, e rodar o
`conferir_mapa`, que prova que o cerco do tutorial continua fechado.

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
  mão, para a mancha que o traçador não cortou bem (o Restaurante do desenho,
  hoje a Cover Pizzaria).
- **Ponto de teste é por nome, nunca por coordenada.** `Mapa.lugar(nome)`,
  `Mapa.ponto_do_png(ponto)`, `Mapa.construcao_com_a_frente_livre(...)` — uma
  coordenada escrita à mão silenciosamente passa a medir mato quando o desenho
  muda.
- **Árvore desenhada é árvore sólida.** Nada é só decoração: o que aparece no
  `_draw()` tem o obstáculo correspondente.

**A sua casa** é a casa marrom ao sul da avenida diagonal, entre as Lojas e a
Delegacia, a oeste da rotatória — o João a marcou no retrato do mapa em
20/10/2026. ⬜ **Uma coisa do mapa de hoje é provisória**, à espera da
equipe: onde ficam os seis documentos. Está marcada em `mapa.gd`.

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
| `rua/conferir_arma.tscn` | você começa com a Beretta, balas são equipamento, o tiro fere e o quinto derruba, o corpo se vasculha, a parede corta, o estrondo chama a horda, o baleado não renasce, as oito armas existem e ferem |
| `rua/conferir_fim.tscn` | a partida dá para ganhar, a vitória, a derrota e a escalada de zumbis |
| `cena_inicial/conferir_cena_inicial.tscn` | a partida nova abre a cena inicial, com o tutorial na abertura e desarmado; o `E` completa o texto e o segundo passa adiante; o `Esc` para a cena ali e abre a rua; sem ninguém no teclado, os oito textos dos seis quadros aparecem inteiros e na ordem, e no fim a rua abre na abertura do tutorial; a arte que existir é 16:9 e tem 1920 × 1080 ou mais | ~15 s |
| `rua/conferir_tutorial.tscn` | o tutorial de ponta a ponta, sem ninguém no teclado: o zumbi da abertura corre atrás do jogador e o Antônio o mata do portão, o objetivo não entrega a piada antes da chegada, os zumbis de posto estão no lugar (longe de casa, longe um do outro, parados) e cada um puxa a sua aula, o da porta larga o posto com o barulho, entrar na pizzaria toca a chegada, o item está na Cover Pizzaria, a entrega dá a Beretta com um pente, o dia 2 acaba no primeiro zumbi abatido | ~30 s |
| `rua/conferir_tela_do_mapa.tscn` | o que passa na tela fica visto e o longe não; andar descobre o caminho; o `M` abre e fecha sem parar o jogo; sob roteiro o mapa não abre; o dia seguinte lembra e a partida nova esquece | segundos |
| `rua/conferir_arremesso.tscn` | o scroll passa pelo que dá para ter na mão; a pedra gasta e chama o zumbi perto, e só ele; o passo chama (correndo de mais longe, andando só colado, agachado nunca); o monte de pedras rende pedra | segundos |
| `rua/conferir_falas.tscn` | os dois jeitos de falar (de perto o jogo para, o E completa e avança, e o jogo só volta com o E solto; pelo rádio o jogo segue e as linhas passam sozinhas) e a fila | segundos |
| `casa/conferir_casa.tscn` | os pontos de clique cabem na tela, todo cômodo se alcança, todo objeto responde, a energia gasta e apaga, o estudado atravessa a noite sem mexer na cura, o estágio dela anda com o prazo, todo cômodo tem foto, e o contorno de cada objeto cabe na tela, fica fora da faixa de voltar e responde por ele | segundos |
| `rua/retratar_mapa.tscn` | **gera** a imagem legendada do mapa em `design/mapa.png` — com `-- --regiao=oeste` (ou `centro`/`leste`, ou o nome de um lugar) na linha de comando, gera só aquele recorte em `design/mapa-<regiao>.png`. Para comparar com o desenho de origem |
| `rua/conferir_arte.tscn` (abre janela — rodar com `--position -4000,-4000` para ela ficar fora da tela e sem foco) | **mostra** PNGs de sprite sobre o greybox, na escala do jogo e ao lado do jogador, e salva a tela — `-- --sprites=a.png;b.png --saida=x.png`; `--zumbis` deixa os zumbis na figura. É o passo "olhar antes de aprovar" da arte; aceita `@escala` por sprite para mock de tamanho. Não roda em headless | segundos |
| `rua/recolorir_arte.gd` | **troca cores exatas** em todos os PNG de uma pasta, em cima do arquivo — `--headless -s res://rua/recolorir_arte.gd -- --pasta=... --trocas=DE:PARA;... [--faixa=y0:y1] [--ensaio]`. É o retoque de paleta (o olho verde do jogador), que se roda depois de cada download porque o servidor não sabe dele | segundos |

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
