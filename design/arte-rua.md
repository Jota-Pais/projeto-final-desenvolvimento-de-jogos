# Arte da rua — o padrão de uso do PixelLab

Como a arte top-down da rua é gerada, para ela sair **coerente e padronizada**
entre jogador, zumbi e o que vier depois. Aberto em **30/09/2026**. Quem usa:
Renan (artista da rua) e João (programador, que é quem tem a ferramenta ligada).

**Estado (02/10/2026):** o João decidiu manter a ferramenta, respondeu o
questionário que fecha os números fixos (marcados *decidido 30/09*) e aprovou,
sobre o greybox, o **jogador v1 com o `andar` completo nas 8 direções** (olho
verde já gravado no servidor) e o **zumbi v1 com o `vagar` completo nas 8
direções**. **O Renan aprovou o zumbi v1 em 02/10** e vai criar variantes dele
(ver "Variantes"); o jogador ele ainda não comentou. Os pacotes baixados estão
com o João, a caminho do Drive da equipe, e **em 02/10 à noite a arte entrou no
jogo** (`rua/arte/`, `rua/boneco.gd`, jogador e zumbi com sprite — ver "Como
entra no Godot"), sem commit. **Em 03/10 o João pediu três animações** — o
jogador usando a arma, o zumbi sofrendo dano e morrendo — **e vida para o
zumbi**; a vida e as versões de código das três entraram, de graça, e as
animações em si esperam decisão de gasto (ver "O que ainda não está decidido").
**Em 05/10 ele fechou os números** (vida 100, tiro tira 20, em unidade de vida)
e pediu **a arma na mão sem gerar nada**: virou um sprite à parte que a pistola
desenha sobre o boneco — e ele adiantou que haverá mais tipos de arma.
 A conta é
de teste (**40 gerações, uma por vez**; sobram 10 das 40, **mais um bônus
diário à parte** — ver "O que custa").
Um frame do `vagar` norte tinha um "texto" fantasma embaixo dos pés —
**apagado no servidor em 02/10**, de graça. **Em 02/10 o João mandou seguir a
produção em modo econômico** (ver "Modo econômico"): o zumbi v1 é a base, nada
pago sem decisão dele, e crédito só depois de gastar o grátis de cada conta da
equipe.
 O que continua com ⬜ é
decisão de mesa.

Hoje a rua é greybox: o jogador é um retângulo vermelho de 28 × 40 e o zumbi um
de 30 × 44 (`rua/jogador.tscn`, `rua/zumbi.gd`). A arte entra **por cima**, sem
mexer em regra: as caixas de colisão continuam as mesmas e o sprite é desenho.

## A ferramenta

**PixelLab** (<https://pixellab.ai>) gera pixel art de personagem em 4 ou 8
direções, animação por modelo de esqueleto e tileset top-down. Está ligado ao
Claude Code do João por **MCP** — as chamadas abaixo (`create_character`,
`animate_character`...) são as ferramentas desse MCP, e o pedido é em linguagem
natural: "gera o zumbi pelo padrão". A mesma conta aparece no site (Character
Creator), então o que o MCP gera o Renan vê e baixa lá.

O token da API fica na configuração do Claude Code na máquina do João. **Não
entra no repositório.**

### O que custa

A moeda é a **geração**. Conta de teste: 40, **uma por vez** — um pedido com 8
direções não roda em paralelo; é uma direção por chamada.

| chamada | custa |
|---|---|
| `create_character`, modo `standard` | 1 — e vem com as 8 direções paradas |
| `animate_character` com modelo (`template_animation_id`) | 1 **por direção** — 8 direções = 8 |
| `create_character`, modo `v3` (a partir de uma imagem de referência) | 2 a 9, conforme o tamanho |
| qualquer coisa `pro` (personagem, animação, objeto) | 20 a 40 — **fora do alcance** da conta de teste |
| `create_topdown_tileset`, `standard` | 3 a 4 por tileset |
| `reduce_colors`, `correct_pixelart`, `unzoom_image` | 0,1 |
| `pixelart_workbench`, `get_*`, `list_*`, `wait_for_jobs`, `update_character_tags` | grátis |

Saldo: `get_balance`, no começo de cada sessão. A documentação diz que trabalho
que falha não é cobrado; conferir no saldo mesmo assim.

**As 40 não renovam, mas há um bônus diário à parte.** A documentação do
PixelLab diz que a conta de teste pinga 5 gerações por dia (acumulando até 20
guardadas). Até 02/10 achei que o pingo não existia, porque o saldo principal
(`generations_remaining`) nunca subia — e reportei como bug. **Estava errado**:
em 05/10 o `get_balance` passou a mostrar o campo `generations_today` (15
naquele dia), que é o bônus. **Ele só é gastado quando as 40 zeram**, e
recarrega +5 por noite até 20. Enquanto as 40 duram, o contador do bônus
também desce a cada cobrança — a própria ferramenta diz que é a mesma
cobrança mostrada duas vezes, não uma segunda (foi isso que confundiu em
05/10). Na prática: 10 das 40 + até 20 de bônus, e 5 novas por noite depois
disso, desde que se gaste antes do teto. Acabando tudo, duas saídas:


- **Crédito**: US$ 1 = 1 crédito, cobrado por operação e não por geração —
  personagem `standard` ≈ US$ 0,012, uma direção de animação por modelo ≈
  US$ 0,032, tileset ≈ US$ 0,008, imagem `pixflux` ≈ US$ 0,008. Crédito não
  vence. Pela estimativa abaixo, **a rua inteira sai por menos de US$ 10**.
- **Assinatura**: Tier 1 US$ 12/mês = 2.000 gerações, Tier 2 US$ 24 = 5.000,
  Tier 3 US$ 48 = 10.000. O que sobra no mês não acumula. Um mês do Tier 1
  cobre o projeto inteiro com folga — só vale se o pingo e o crédito
  incomodarem.

Preços de 30/09/2026, do site (<https://www.pixellab.ai/pixellab-api>) e do
assistente do próprio PixelLab; o pingo diário e os tiers **não aparecem na
página pública**. **A conta é o e-mail** com que se entrou em pixellab.ai: é
nela que se compra crédito ou assinatura (pixellab.ai/account, logado), e o
token do MCP que está na configuração do Claude Code do João continua valendo
depois de pagar — não se troca nada. Não existe plano de equipe: a assinatura
é pessoal, uma por login. Hoje só o João usa a conta, pelo MCP; o Renan recebe
pelo Drive e não precisa de login.


### A rua inteira, estimativa

| o quê | gerações |
|---|---|
| jogador: criar + 4 animações × 8 direções | 33 |
| zumbi: criar + 4 animações × 8 direções | 33 |
| 2 variantes de zumbi (a horda não ser clone) | 0 recolorindo no `pixelart_workbench`; 66 se refeitas |
| NPC do búnquer (só parado; fala por porta e rádio) | 1 |
| tilesets (asfalto, calçada, grama, terra, mata, água, lavoura) ≈ 7 × 4 | ~28 |
| props (carro, móveis, documentos) por `create_image_pixflux`, 1 cada | ~20 |
| **total** | **~115 a ~180**, e 170 a 270 contando refazer o que sair ruim |

Só com o pingo: de 05/10 à Gold seriam ~50 dias × 5 = ~250, mais as 40 e o
bônus guardado — **dá para a rua inteira sem pagar**, desde que se gaste o
bônus antes de ele bater no teto de 20 (o que passa do teto se perde). Com
crédito, menos de US$ 10.


## Os números fixos

Tudo da rua sai com **a mesma chamada**, mudando só nome e descrição. É isso que
faz o elenco parecer do mesmo jogo: o modo `standard` desenha todo mundo sobre o
mesmo esqueleto humanoide, e tamanho, câmera, contorno e sombra iguais fazem o
resto.

```
create_character(
  name         = "Jogador (rua)",              # "<quem> (rua)"; a versão vai na tag
  description  = "<PREFIXO> <o personagem>",   # ver "A descrição"
  mode         = "standard",
  body_type    = "humanoid",
  n_directions = 8,
  size         = 80,                           # decidido 30/09 pelo teste 0 — ver "A escala"
  view         = "high top-down",              # decidido 30/09 pelo teste 0 — ver "A câmera"
  outline      = "single color black outline", # decidido 30/09
  shading      = "basic shading",              # decidido 30/09
  detail       = "medium detail",
  proportions  = '{"type": "preset", "name": "default"}',   # decidido 30/09
  text_guidance_scale = 8
)
```

Depois, de graça: `update_character_tags(character_id, ["rua", "jogador", "v1"])`.
A tag de versão é o que separa a primeira tentativa da refeita.

**Sempre 8 direções na criação**, mesmo que a equipe decida animar só 4: custa o
mesmo 1 e as oito poses paradas vêm junto.

### A escala — decidido 30/09

No mundo da rua **40 px = 1 m** (`rua/mapa.gd`). **1 pixel de desenho = 1 px
de mundo**: o sprite entra no Godot em escala 1, filtro *nearest*, e o boneco
tem **80 px de altura, 2 m** — um pouco mais alto que a régua do metro, como
todo sprite em 3/4, e ainda menor que a porta de casa (2,5 m de largura).

O que o teste 0 ensinou, e que derruba a conta que estava aqui antes: em modo
`standard`, **`size` é a altura do boneco, não do canvas**. `size=64` deu um
boneco de 61 a 65 px num canvas de 92 × 92, com 13 a 17 px vazios embaixo. Em
escala 2 ele ficava com 3 m, maior que a porta; em escala 1, com 1,5 m, pequeno
na tela. O meio-termo foi gerar maior (80) e manter a escala 1. A ideia de
"pixel grosso" em escala 2, igual à arte da casa, **saiu**: os dois modos já são
separados de propósito, e a rua fica com arte fina em 1:1.

A caixa de colisão (28 × 40) é o pé no chão e não muda: o sprite sobe a partir
dela — e é o **pé desenhado** que encosta nela, não a borda do canvas
(`rua/conferir_arte.gd` mostra como).

Trocar o tamanho depois é refazer o personagem — 1 geração. Trocar depois de
animado é refazer as animações também. **Por isso o teste 0 vem antes de
qualquer animação.**

### A câmera — decidido 30/09: `high top-down`

O PixelLab oferece `low top-down` (~20°, o 3/4 clássico de RPG, Zelda/Stardew) e
`high top-down` (~35°, mais visto de cima). O teste 0 gerou o jogador nas duas,
com tudo o mais igual, e **a diferença foi quase nula**: 4 px de altura e um
pouco mais de topo de cabeça no `high`. Ficou o `high`, que é a câmera padrão
dos tilesets da ferramenta — e **personagem, objeto e tile têm que sair na mesma
câmera**.

### A descrição

`description` = **um prefixo fixo**, igual em todo personagem, mais o que esse
personagem é. Em **inglês**, que é a língua dos exemplos da documentação e em
que o modelo responde melhor; a tradução fica aqui.

**Prefixo (decidido 30/09 — paleta dessaturada e sombria, tom Zomboid):**
`zombie apocalypse survivor game, desaturated gloomy colors, grey-green and brown tones; `

O prefixo não diz país nem década: isso é da narrativa (`narrativa.md`, seção
3) e entra quando ela fechar. ⬜ O Renan pode mexer no prefixo depois de ver o
teste 0 — mas mudar o prefixo é refazer o elenco, então é agora ou nunca.

| quem | descrição (depois do prefixo) | em português |
|---|---|---|
| jogador | `man in his thirties, tired face with stubble, dark hooded jacket with the hood up, worn jeans, sneakers, backpack on his back` | homem de 30 e poucos, cara cansada e barba por fazer, casaco escuro com capuz levantado, jeans gasto, tênis, mochila nas costas |
| zumbi v1 (**reprovado 30/09: "muito humanizado"**) | `classic movie zombie, rotting grey-green skin, slack jaw with open mouth, arms hanging limp, hunched shambling posture, torn dirty civilian clothes` | zumbi clássico de filme, pele podre cinza-esverdeada, boca aberta e queixo caído, braços caídos, postura curvada e arrastada, roupa civil rasgada e suja |
| zumbi v2 (**reprovado 30/09: "muito esqueleto e pouco zumbi"**) | `grotesque monstrous zombie, emaciated and gaunt, rotting grey-green skin peeling off, exposed ribs and exposed jawbone with bared teeth, sunken glowing pale eyes, deep gashes and dried blood, long clawed bony hands, hunched shambling posture, shredded filthy clothes` | zumbi grotesco e monstruoso, esquelético, pele podre cinza-esverdeada descascando, costelas e mandíbula expostas com dentes à mostra, olhos fundos e pálidos acesos, cortes profundos e sangue seco, mãos ossudas com garras, postura curvada e arrastada, roupa em tiras e imunda |

Regra que não é de gosto: a descrição fala **do personagem**, não da cena (sem
"na rua", "ao lado de um carro") — o modelo tenta desenhar o cenário junto.

## O elenco e as animações

O que o código precisa, pelo estado de cada um. O modelo (`template_animation_id`)
é sugestão: o Renan escolhe no teste.

| quem | estado no código | animação (nome no Godot) | modelos candidatos |
|---|---|---|---|
| jogador | parado | `parado` | **modo econômico (02/10): a rotação parada da direção, 0 gerações** — `breathing-idle` (8) só se sobrar |
| jogador | andando (`VELOCIDADE`) | `andar` | **`v3`, "walking forward at a steady pace", 8 frames, `keep_first_frame=false`** — decidido 30/09 depois de o `template` `walk` borrar o rosto; 2 gerações por direção |
| jogador | correndo (Shift) | `correr` | **feito 02/10: o `andar` a 1,64× no código, de graça**; `running-6-frames` (8) se um dia sobrar |
| jogador | vasculhando (E segurado) | `vasculhar` | `crouching` — ou `parado`, de graça |
| jogador | atirando (sinal `atirou` da pistola) | `atirar` | **pedido do João em 03/10.** Não há modelo de pistola na biblioteca; é `v3` com `action_description` ("aiming a pistol forward with both arms and firing", 4–8 frames), 2 a 3 por direção — e a ferramenta avisa que arma que **não está no desenho base pisca** de frame em frame. **Decidido 05/10: a arma na mão é um sprite à parte** (`rua/arte/jogador/pistola.png`, 12 × 7 px, desenhado por mim, 0 gerações), que a pistola põe na mão e aponta para onde ele olha; a pose de tiro é o recuo de 2 px no código, mais o coice da arma. Se o `atirar` for gerado um dia, é sem arma no desenho — ela já está no sprite |
| jogador | levou toque | — | o empurrão já é o feedback; sem animação |
| zumbi | VAGANDO | `vagar` | `sad-walk` em `template` (lento, arrastado) — 1 por direção; num zumbi, cara borrada não incomoda |
| zumbi | PERSEGUINDO / PROCURANDO | o mesmo `vagar`, acelerado (`speed_scale`) — **decidido 30/09** | `scary-walk` fica como opção (+8) se acelerar não convencer |
| zumbi | toque no jogador | `toque` | **feito 05/10: `cross-punch` em `template`, 8 direções, 6 frames** (pedido do João: "uma animação de ataque pro zumbi"). Ele para 0,3 s para bater e a animação toca; a investida de código fica de reserva para folha sem `toque` |
| zumbi | levou tiro e ficou de pé (`levar_tiro`, vida > 0) | `dano` | **pedido do João em 03/10.** `taking-punch` em `template`, 1 por direção. **Enquanto não vem: clarão vermelho e recuo de 16 px no código**, feito 03/10 |
| zumbi | levou o tiro que mata (`levar_tiro`, vida 0) | `morrer` | **feito: `falling-back-death` em `template`, 7 frames, 8 direções** — o sul em 05/10 (pedido do João: "uma animação de morto, e não só ficar caminhando de lado no chão") e as outras sete em 14/10, com o bônus diário. Custa 2 por direção, não 1. A queda de código (tombar a pose parada e trocar pelo quadro do sul) ficou de reserva para folha sem `morrer` |

**Ordem de prioridade**, porque o saldo acaba: jogador criado → `andar` → zumbi
criado → `vagar` — **feito**. O `parado` saiu da fila: em modo econômico é a
rotação parada. O que vem depois é decisão do João, com a reserva de 10 (ver
"Modo econômico"); o resto vem com os truques "de graça" da tabela, com o grátis
das outras contas da equipe ou com assinatura.


**O modelo `template` borra o rosto** (visto em 30/09 no `andar` do jogador: a
boca virou um borrão de 2–3 px e os olhos saíram do lugar, em vários frames).
Ele redesenha o boneco a cada frame sobre um esqueleto rígido; a 1:1 quase não
se vê andando, mas ao parar a rotação limpa entra e a cara "pula". A escada de
qualidade da própria ferramenta é `template` (1/direção) → `v3`
(`action_description`, `frame_count` 4–16, 2–3/direção neste boneco de canvas
112) → `pro` (20–40/direção, fora da conta). Saída de graça, se o v3 também
borrar: **transplante de cabeça** — colar a cabeça da rotação limpa em cada
frame, alinhada pelo topo do capuz; vale para andar, que não vira a cabeça.
Em `v3`, passar `keep_first_frame=false`, senão a pose parada entra como
frame 0 e o ciclo engasga.

### O orçamento das 40 — decidido 30/09: 8 direções

| plano | o que compra | gerações |
|---|---|---|
| **8 direções** | jogador e zumbi criados (2) + `andar`/`vagar` (16) + `parado` (16) | 34, sobram 6 de reserva |
| **8 direções, 5 geradas + 3 espelhadas** — leste, nordeste e sudeste são o espelho de oeste, noroeste e sudoeste no Godot (`flip_h`) | o de cima por 22, mais `correr` e `toque` (10) | 32, sobram 8 |
| **4 direções** | criados (2) + 4 animações cada, com 4 direções (32) | 34, sobram 6 |

Decisão do João (30/09): **8 direções**. O jogador já anda em 8
(`Input.get_vector`) e o zumbi olha para qualquer ângulo — com 4, a diagonal anda
de lado. Já correr, vasculhar e morrer têm versão de graça no código até vir
assinatura. Espelhar era o meio-termo e custava uma coisa só: detalhe assimétrico
(arma na mão direita, mochila num ombro) troca de lado.

**O que se gastou em 30/09: 22.** Teste 0 (2) + jogador refeito em 80 px (1) +
`andar` em template só no sul, descartado (1) + `andar` em `v3` nas 8 direções
(16) + zumbi v1 (1) + zumbi v2, reprovado (1). **Sobram 18**, mais o pingo
diário. O `vagar` do zumbi (8, template) e os dois `parado` (16, template)
ficaram para depois de o Renan ver. A conta do dia subiu por causa do rosto: a
tabela dos planos acima foi feita com `template` a 1 por direção, e o jogador
precisou de `v3` a 2 — para o zumbi o template deve bastar.

**O que se gastou em 02/10: 8** — o `vagar` do zumbi em template nas 8
direções. **Sobram 10**, e sem pingo isso compra uma coisa só: ou mais uma
forma de zumbi animada (1 + 8), ou o `parado` de um dos dois (8). Variante de
cor continua de graça. O resto espera o pingo, crédito ou assinatura.

### Modo econômico — decidido 02/10

O João mandou seguir a produção **gastando o mínimo**: a equipe dificilmente
paga crédito, e antes disso vale **gastar o grátis de cada um**. As regras:

1. **Nada pago sem o João dizer** o que a geração compra, e cada uma entra no
   "Registro de gerações" antes de rodar. Vale também para colegas com conta.
2. **`parado` é a rotação parada** da direção (já existe, 0 gerações) — para o
   jogador e para o zumbi. `breathing-idle` (8 cada) só se sobrar no fim.
3. **A horda varia por cor**, de graça, com a receita da seção "Variantes".
   Forma nova (por descrição ou desenhada) custa 9 e espera o João decidir.
4. **As 10 que sobram são reserva**: ⬜ o João decide o que compram. Candidatos:
   o NPC do búnquer (1), refazer o que sair com defeito, ou uma forma de zumbi
   animada (9). Tilesets (3–4 cada) e props (1 cada) ficam para as contas dos
   colegas — ou para o Renan desenhar, se ele preferir.
5. **O grátis de cada um.** O PixelLab dá 40 gerações por conta, e a conta é
   pessoal (um e-mail, um login — ver "O que custa"). Quem da equipe quiser
   contribuir cria a própria conta em pixellab.ai e tira o token em
   pixellab.ai/account; a configuração do MCP no Claude Code tem **um token**,
   então trocar de conta é trocar o token e reiniciar. O que já foi gerado
   **não muda de conta**: para animar o jogador ou o zumbi a partir de outra
   conta, cria-se o personagem lá com a chamada fixa (1 geração) e
   substituem-se as 8 rotações pelas do v1 com `save_to_asset` (grátis) — aí o
   servidor anima em cima dos pixels certos. As animações já baixadas não
   precisam ser refeitas. Com N contas, N × 40 gerações: pela estimativa de "A
   rua inteira", 4 ou 5 contas cobrem tudo sem pagar nada.


## O ritual — como gerar

1. **`get_balance`.** Anotar.
2. **Teste 0 — feito em 30/09** (ver o registro no fim): o jogador duas vezes,
   com a chamada fixa, mudando só `view`, os dois sobre o greybox pelo
   `rua/conferir_arte.tscn`. Decidiu a câmera e, com um mock de tamanhos,
   derrubou a escala 2 — custou as 2 gerações previstas mais 1 para refazer o
   jogador em 80 px. O que ele ensinou está em "A escala" e "A câmera".
3. **Criar** com a chamada fixa. `wait_for_jobs` → `get_character` → olhar a
   prévia (sul) **e as 8 direções**.
4. **Aprovar antes de animar.** Renan vê e diz sim. Animar um personagem que vai
   ser refeito joga 8 gerações fora. Reprovado: `delete_character`, mexer na
   descrição, 1 geração de novo.
5. **Animar uma direção por chamada** (limite da conta):
   ```
   animate_character(character_id, template_animation_id="walk",
                     directions=["south"], animation_name="andar")
   ```
   A primeira chamada cria o grupo; `get_character` mostra o id `[group: ...]`.
   As sete seguintes passam `animation_group_id=<esse id>` **e o mesmo
   `animation_name`** — sem o nome, o grupo aparece renomeado. `wait_for_jobs`
   entre uma e outra. Ordem das direções, a da ferramenta: `south, south-west,
   west, north-west, north, north-east, east, south-east`.
6. **Baixar.** O link de download sai do `get_character` e **não pede login** (o
   UUID é a chave; `curl -L` serve — o `Invoke-WebRequest` do PowerShell trava
   num prompt). Devolve HTTP 423 enquanto houver job pendente. Extrair em
   `rua/arte/<quem>/` como vier. A árvore (vista em 01/10, `export_version` 3.1):

   ```
   metadata.json                                            # ids, prompt, tamanho, view e a lista de todo arquivo abaixo
   <estado>/rotations/<direção>.png                         # estado = nome do state ("Idle"); 8 PNG de 112 × 112
   <estado>/animations/<animação>/<direção>/frame_NNN.png   # NNN desde 000; animação = o animation_name
   ```

   Direções sempre com os nomes da ferramenta: `south, south-east, east,
   north-east, north, north-west, west, south-west`. O **spritesheet**
   (`/spritesheet`, só do estado) é outro ZIP com `<Nome>-<estado>.png` e um
   `.json`: grade de `columns` (8) colunas, células de `cell_size` (116 × 116 —
   o canvas de 112 mais 2 px de margem), pivô no centro da célula; `rows[0]` são
   as rotações na ordem acima e cada `rows[n]` seguinte é uma animação numa
   direção, na mesma ordem. O carregador do Godot vai ler o `metadata.json` do
   ZIP, não o spritesheet: um PNG por frame é o que o `SpriteFrames` quer.
7. **Retocar a paleta no servidor, uma vez.** O que foi decidido à mão depois
   da geração (hoje: o olho verde do jogador) é aplicado **dentro do PixelLab**,
   de graça, em duas chamadas por direção: `pixelart_workbench` com
   `edit character:<id>:<direção>[:<grupo>] --changes '[{"operation":"map_colors","layer":"image","frames":[…],"region":[x0,y0,x1,y1],"colors":{"#de":"#para"},"reason":"…"}]'`
   devolve um id de imagem; `save_to_asset(image=<id>, target=character:<id>:<direção>[:<grupo>])`
   grava por cima e devolve o undo. Feito nas 8 rotações, **toda animação
   gerada depois já nasce com a cor nova**; as já geradas se retocam pelo mesmo
   caminho, uma direção por vez (frames são 1-based; a região é inclusiva).
   Assim o download já vem certo e o Renan vê a cor certa no site. **Não mandar
   PNG em base64 pela conversa**: acima de ~3 KB o cliente trunca e a gravação
   falha — sempre pelo id do workbench ou por `character:<id>:<direção>` como
   fonte. `rua/recolorir_arte.gd` fica como reserva local e para variantes de
   cor que não viram personagem no servidor.
8. **Registrar** na tabela do fim deste arquivo: data, o quê, id, gerações,
   aprovado por quem.

Se a paleta do zumbi fugir da do jogador: `reduce_colors` (0,1 geração) com a
imagem do jogador como `palette_image_url` encaixa um na paleta do outro.
Retoque pixel a pixel, de graça e local, é o `pixelart_workbench`. Zumbi que não
casar nem assim: `create_character(mode="v3", reference_image_url=<o sul do
jogador>, description=<o zumbi>)` — 2 a 9 gerações, e a referência **tem que
estar de frente**: o que ela encara vira sul, e um 3/4 desloca as oito direções.

### Retoques de paleta

Trocas de cor exata aplicadas por `rua/recolorir_arte.gd` em cima do que o
PixelLab entrega. Cada linha é uma decisão; o `--faixa` existe porque pixel art
reaproveita cor — no jogador, as duas sombras do olho são **também a calça**, de
y 51 para baixo.

| quem | de | para | o quê | faixa | decidido |
|---|---|---|---|---|---|
| jogador | `30699B` | `2E6B3C` | íris (azul → verde escuro) | `0:45` | João, 30/09 |
| jogador | `374A63` | `1F4A2B` | sombra do olho | `0:45` | João, 30/09 |
| jogador | `141E37` | `10281A` | canto do olho | `0:45` | João, 30/09 |

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://rua/recolorir_arte.gd -- --pasta=res://rua/arte/jogador --trocas=30699B:2E6B3C;374A63:1F4A2B;141E37:10281A --faixa=0:45
```

A faixa vale para o canvas de 112 px do jogador parado (olhos em y 34–38); em
animação a cabeça balança uns pixels, e a calça começa em y 51 — a margem é
essa. Se um frame cair fora, a conferência (`conferir_arte`) mostra.

**Aplicado no servidor em 02/10** (passo 7 do ritual): as 8 rotações (30 px) e
as 8 direções do `andar` (123 px; norte e noroeste não tinham o que trocar). O
que o PixelLab entrega para o jogador a partir daí já vem com o olho verde.

### Variantes — como o Renan faz mais de um zumbi sem refazer tudo

Combinado em 02/10: o zumbi v1 é a base, e **o Renan cria variantes** para a
horda não ser clone. Como a variante é feita decide o que ela custa:

| tipo de variante | como | custa | anima como |
|---|---|---|---|
| **cor** (pele, roupa, cabelo, sangue) | o Renan diz as trocas DE → PARA (hex exato, como na tabela "Retoques de paleta"); `recolorir_arte.gd` aplica numa cópia dos frames baixados do v1. Se a variante merecer personagem próprio no servidor (para o Renan ver no site), é 1 geração de "vaga" + `edit`/`save_to_asset` nela | **0** (ou 1) | já vem animada: são os mesmos 64 frames do v1, recoloridos. No Godot é só outro `SpriteFrames` |
| **forma, desenhada por ele** (outra roupa, membro faltando, cabeça diferente) | ele edita as **8 rotações paradas** do v1 (112 × 112, mesma pose); eu crio um personagem novo com a chamada fixa (1) e **substituo as 8 rotações pelas dele** com `save_to_asset` (grátis); daí o servidor anima a partir dos pixels dele | 1 + 8 por animação (template) | `vagar` em template, 8 |
| **forma, por descrição** | muda só a descrição na chamada fixa; eu gero | 1 + 8 por animação | idem |

O que **não** funciona: desenhar em cima de um frame animado — são 64 por
animação, e o próximo download apaga o retoque. Retoque à mão é nas
**rotações paradas**, e vai para o servidor com `save_to_asset` (ver o passo 7
do ritual); a animação se gera depois dele.

Para a horda, a conta recomendada é **1 forma + N cores**: o v1 animado uma
vez (8) e três ou quatro trocas de paleta do Renan por cima, de graça.
`transfer_outfit` (trocar a roupa de uma animação inteira por referência) existe,
mas é tier pago, 20–40 por chamada — fora.

#### A paleta do zumbi v1 — para a variante de cor

Levantada em 02/10 das 8 rotações e dos 64 frames do `vagar` (19 cores nas
rotações; a animação acrescenta 8, que entram na receita). Hex RGB exato; a
**faixa** é de linhas do canvas de 112 (y 0 em cima) e existe porque alguns hex
se repetem em partes diferentes do boneco.

| parte | hex nas rotações | hex só nos frames | `--faixa` |
|---|---|---|---|
| pele (rosto, braços, pés) | `989B87` clara, `919483` sombra | `A5A497` | toda |
| cabelo | `2D2E2E` topo, `1F1E1D` laterais, `1A191E` sombra (nuca) | `353537` | `0:40` — `1A191E` e `2D2E2E` também são sombra da calça |
| regata | `CDC4C0`; `787776` e `49494B` sombras | `EAE7E1` (norte), `F6F6F5` (leste), `C5BFC5` | `38:68` — `F6F6F5` também é olho e sapato no leste |
| calça | `3C3A44`, `1E1D28` sombra, mais `1A191E` | `353537` | `64:112` |
| sangue (ferida, mancha, boca) | `893420`, `AC554C` claro | `93442E` | toda |
| olhos | `9C97B9` | — | `0:40` |
| **não mexer** | contorno `050403` `0A0909` `11100E` `191814`; `E9EAEA` dentes e gola; `5C5B5C` | `776562` | — |

A receita é uma rodada do `recolorir_arte.gd` por parte, numa **cópia** da
pasta `Idle/` do pacote (nunca no original):

    --trocas=CDC4C0:<nova>;EAE7E1:<nova>;F6F6F5:<nova>;C5BFC5:<nova>;787776:<sombra>;49494B:<sombra escura> --faixa=38:68
    --trocas=2D2E2E:<nova>;1F1E1D:<sombra>;1A191E:<sombra>;353537:<sombra> --faixa=0:40

**Testada em 02/10** com regata vinho e cabelo castanho: 72 arquivos, olhos,
sapatos e sangue intactos nas 8 direções e nos frames — a comparação está em
`teste-0-pixellab/zumbi-v1-receita-de-cor.png`, na Área de Trabalho do João.
O Renan só manda a tabela DE → PARA; não precisa rodar nada.


## Como entra no Godot — feito em 02/10

Em 02/10 à noite o João pediu para aplicar no jogo "para ver como vai ficar", e
a arte entrou. O que existe:

- **Pasta:** `rua/arte/jogador/` e `rua/arte/zumbi/`, cada uma com a **folha de
  sprites** que o PixelLab exporta (`<Nome>-Idle.png` + `<Nome>-Idle.json`), e
  não o ZIP de 72 PNG: dois arquivos em vez de 72 mais 72 `.import`. A folha é
  uma grade de células iguais (112 no zumbi, 116 no jogador, porque o leste do
  `andar` saiu maior): a linha 0 são as 8 rotações paradas, e cada linha
  seguinte é uma direção de uma animação. Nada é renomeado à mão; o carregador
  lê o JSON. **Sem Git LFS** (134 KB + 111 KB).
- **O nó:** `rua/boneco.gd`, um `AnimatedSprite2D` com `folha`, `pe` e
  `quadros_por_segundo` exportados. Monta um `SpriteFrames` com uma animação
  por ação e direção — `parado_sul`, `andar_sudoeste`, `vagar_norte` — e uma
  folha vira um `SpriteFrames` só, compartilhado por todos os zumbis. Quem usa
  chama `mostrar(acao, direcao, ritmo)` a cada quadro de física.
- **Escala 1**, filtro nearest no próprio nó (o padrão do projeto ficou como
  estava: mudá-lo afetaria a HUD).
- **Pivô fixo no centro da célula**, como o PixelLab recomenda, e o pé da
  rotação **sul** na borda de baixo da caixa de colisão (`pe` = 20 no jogador,
  22 no zumbi). O contrato anterior dizia "alinhar cada direção pelo próprio pé
  desenhado"; isso faria o boneco pular até 6 px ao virar, porque nas vistas de
  lado o pé da frente é desenhado mais embaixo — é perspectiva, não
  desalinhamento. Decisão técnica, registrada no cabeçalho do script.
- **Nome da animação** = nome no PixelLab sem o sufixo de versão: `andar-v3`
  vira `andar`. A versão é coisa de produção; o jogo pede a ação.
- **Direção a partir de um vetor:** oito setores de 45°; `south` do PixelLab é
  +Y no Godot. Trocar de direção no meio do passo não reinicia a animação.
- **O que a arte substituiu no código:** o retângulo vermelho do jogador
  (`Polygon2D`) e o retângulo verde/âmbar do zumbi com a bolinha da cara. O cone
  de visão continua (auxílio de protótipo). A barra de vida subiu para cima da
  cabeça.
- **Ritmo:** jogador a 12 quadros/s andando, com `ritmo` = velocidade / 280 —
  correr é o mesmo `andar` a 1,64×. Zumbi a 8 quadros/s vagando, `ritmo` =
  velocidade / 70 — perseguir é o mesmo `vagar` a 2,36× (decidido 30/09).
  Parado é a rotação parada (modo econômico); o zumbi olhando em volta gira
  pelas 8.
- **Para onde o jogador olha:** para onde anda; para o mouse enquanto o tiro
  está apertado e por 0,5 s depois (`SEGUNDOS_DE_MIRA`). ⬜ **Proposta**: não
  existe sacar/guardar a arma; se a equipe quiser um botão de mirar, é um
  estado a mais em `jogador.gd`.
- **Conferir:** `rua/conferir_arte.tscn` agora é escala 1 e aceita `--zumbis`;
  a figura de 02/10 está em `teste-0-pixellab/rua-com-arte.png`, na Área de
  Trabalho do João.

**Feito em 03/10 — a vida do zumbi e os ganchos das animações que faltam.** O
João pediu "o personagem usando a arma, e o zumbi sofrendo dano e morrendo,
eles devem ter uma vida". O zumbi passou a ter vida (100; a Beretta tira 20,
cinco tiros — **João, 05/10: vida e dano em unidade de vida, não em balas**,
para outra arma ter outro dano; em `pistola.gd`/`zumbi.gd`), e `rua/boneco.gd` ganhou
`tocar(acao, direcao)`: toca uma animação de uma vez só (`atirar`, `dano`,
`morrer`), segura o `mostrar()` até ela acabar e devolve `false` se a folha não
a tem. Enquanto a folha não tem, o código mostra uma versão de graça: recuo de
2 px no jogador ao disparar; clarão vermelho e recuo de 16 px no zumbi ferido;
o zumbi morto tomba de lado (o boneco gira 90° para onde a bala ia e
escurece), fica 60 s no chão e some em 1 s — **ou fica até o fim do dia se
carregar algo** (`inventario`; João, 05/10 — o que um zumbi carrega ainda é ⬜,
hoje nada enche isso). O corpo sai do grupo "zumbi" e da colisão: não é
chamado, contado nem acertado, e o jogador anda por cima. Barra de vida do
zumbi igual à do jogador, só depois do primeiro tiro. **Quando a animação
entrar na folha, nada no código muda** — basta o nome na folha ser `atirar`,
`dano` ou `morrer` (com ou sem `-vN`). Zero gerações.

**Feito em 05/10 — a arma na mão, sem gerar.** O João pediu "uma versão dele
com a arma na mão" e fechou a lista das armas do jogo (oito, abaixo). Gerar o
boneco com a arma desenhada custaria 1 + 16 do `andar` **por arma**, então a
arma é um `Sprite2D` filho do nó da arma (`rua/arma.gd`, que era o
`pistola.gd`), com um PNG por arma em `rua/arte/armas/`, de lado apontando
para a direita, nas cores da arte (contorno `050403`, metal `2D2E2E`, destaque
`5C5B5C`, escuro `1A191E`, madeira `776562`, polímero `3C3A44`), desenhados
por mim em pixel — o Renan pode redesenhar; é só trocar o PNG, mantendo o
pixel do cabo (`mao` na ficha). O nó a põe na mão (cintura, 18 px acima do
centro), avançada 12 px para onde o jogador olha (avanço vertical achatado à
metade pela perspectiva), girada no ângulo exato da mira, espelhada no eixo y
quando aponta para a esquerda (o cabo fica para baixo) e **atrás do corpo
quando aponta para longe da câmera** (norte: o nó passa para antes do boneco
na árvore). O clarão do tiro sai da boca do cano do sprite, e a arma dá um
coice.

#### As armas — a lista do João (05/10), desenhadas à mão

| arma | classe | sprite (px) | dano × projéteis | espera | automática | alcance / estrondo |
|---|---|---|---|---|---|---|
| Revólver 38 | curta | 12 × 8 | 25 × 1 | 0,6 s | não | 800 / 1700 |
| Beretta 9mm | curta | 12 × 7 | 20 × 1 | 0,45 s | não | 900 / 1800 |
| Doze 2 canos | escopeta | 26 × 7 | 12 × 6, abertura 16° | 1,2 s | não | 450 / 2200 |
| Benelli semiauto | escopeta | 26 × 7 | 10 × 6, abertura 14° | 0,6 s | não | 450 / 2200 |
| CTT40 | submetralhadora | 16 × 9 | 14 × 1, desvio até 4° | 0,09 s | não | 750 / 1900 |
| Fireagle 9mm | submetralhadora | 18 × 9 | 12 × 1, desvio até 5° | 0,07 s | não | 750 / 1900 |
| Fall | fuzil | 30 × 9 | 45 × 1, desvio até 1,5° | 0,3 s | sim | 1400 / 2600 |
| M4 | fuzil | 28 × 9 | 30 × 1, desvio até 2° | 0,11 s | sim | 1300 / 2500 |

**Só a lista é dele; os números são proposta minha** (05/10), para as oito
existirem e darem para sentir — a ficha é `ARMAS` em `rua/arma.gd`, e `Q`
troca de arma (auxílio de protótipo, porque como se consegue uma arma é ⬜).
Semiautomática é um tiro por clique; automática atira enquanto o botão está
apertado — só os fuzis. A CTT40 e a Fire Eagle são carabinas semiautomáticas
na vida real (a metralhadora da Taurus é a SMT40), e em 05/10 o João mandou
seguir o real; os calibres foram conferidos na mesma data (Taurus CTT40 .40
S&W; Fire Eagle Armory 9×19; Benelli M4/M2 calibre 12; FAL IMBEL 7,62×51).
Dano em unidade de vida, por projétil: a escopeta solta 6 de uma vez,
espalhados na abertura. **A munição é por calibre** (João, 05/10: "faz um
tipo de munição pra cada"): .38, 9mm (Beretta e Fireagle), calibre 12 (Doze e
Benelli), .40, 7,62 e 5,56 — `MUNICOES` em `rua/construcao.gd`, o cinto em
`Travessia.balas`, e cada caixinha do vasculho sai de um calibre sorteado com
peso igual (⬜ raridade por calibre). A HUD mostra a arma na mão com as balas
do calibre dela; a tela da mochila lista todos os calibres no cinto. Os
sprites saem de um desenho em texto, `design/desenhar_armas.js` (`node
design/desenhar_armas.js rua/arte/armas`), sem dependência; a escala é a do
boneco — um fuzil de 30 px num corpo de 78, exagerado de propósito, como se
faz em pixel art para a arma se ler.

**05/10 à noite — as gerações que o João autorizou.** "Gera o ataque primeiro
e aproveita os 2 de sobra pra … o frame dele morto no chão": `toque` em
`cross-punch` nas 8 direções (8), e `morrer` em `falling-back-death` **só no
sul** (1). O sul rende duas coisas: a queda animada quando o zumbi morre
olhando para o sul, e **o último quadro — o morto no chão — para as oito
direções**: nas outras sete o código faz a queda de antes (a pose parada
tomba de lado) e, no chão, troca o boneco por esse quadro girado para o lado
em que tombou (`Boneco.ultimo_quadro`, `Zumbi._deitar`). Um corpo deitado
vale para as oito direções, porque no chão não há perspectiva nova. O quadro
saiu deitado **com a cabeça para a esquerda**, então o código zera a rotação
da queda e espelha quando tombou para a direita. O `dano` continua o clarão
de código. **Resultado**: as 8 do `toque` limpas; o `morrer` com um quadro
virado de costas, trocado no servidor de graça. A folha nova está em
`rua/arte/zumbi/` e no pacote da Área de Trabalho; as conferências passam.

**14/10 — `morrer` completo.** Com o bônus diário de volta ao teto (20), o
João mandou seguir ("consegue fazer agora?") e as outras sete direções da
queda entraram: 13 do bônus (2 por direção, como a ferramenta avisa agora),
sobraram 7. Todas boas. A troca pelo quadro do sul (`_deitar`) ficou de
reserva.

**Ainda não feito:** `dano` do zumbi (8) e `atirar` do jogador (16–24), que
esperam crédito ou decisão de gasto (ver "O que ainda não está decidido").
O Y-sort entrou em 14/10 (ver "Fase 5 feita").

## O mapa inteiro — proposta de 14/10, a decidir

O João perguntou "como a gente vai desenhar esses detalhes do mapa inteiro? vai
ser tudo no PixelLab?" e quer isso definido antes de começar, para o mapa sair
definitivo. A proposta abaixo é minha; o que leva ⬜ é resposta dele.

**O que o mapa é hoje: dado, não desenho.** O traçado do desenho dele vira
polígonos por classe (grama, gramado, mata, horta, pavimento, asfalto, milho,
terra, água) e retângulos de prédio (casa, comércio, galpão, delegacia,
hospital, posto, bombeiros), com portas, cômodos, 17 tipos de móvel
(`Construcao.MOVEIS`), carros, bosques de árvores sorteadas, praça. O cenário
pinta tudo em cinza por código. Isso **decide o caminho**: o mapa tem uns
20.000 × 12.000 px — uma pintura única é inviável, e qualquer mudança no
desenho a jogaria fora. **A arte do mapa tem que ser um conjunto de peças**,
tiles e sprites, que o código já sabe onde pôr. Mudar o desenho depois não
custa arte nova; custa só repintar, que é automático.

**As camadas, de baixo para cima**

| camada | o quê | como | gerações |
|---|---|---|---|
| 1. chão | um tileset Wang por terreno | `create_topdown_tileset`, 32 px (0,8 m em escala 1), encadeados pelo `base_tile_id` para as bordas casarem (asfalto → pavimento → grama); pintados num `TileMapLayer` a partir dos mesmos polígonos. Guia de importação: `pixellab://docs/godot/wang-tilesets` | 3–4 cada, ~28 |
| 2. ruas | faixa da pista, meio-fio | parte do tileset do asfalto, ou `create_path_tiles` | 0–4 |
| 3. prédios | parede (frente, lados, fundo), telhado, piso interno, porta, janela | **texturas repetidas sobre os retângulos que já existem** (`create_image_pixflux` "seamless …", 1 cada) mais porta e janela desenhadas à mão como as armas; o kit de prédio da ferramenta é `pro` (20–40 na conta de teste) | ~6–10 |
| 4. objetos | árvore (2–3 copas), carro (2–3), motorhome, lata, poste, cerca, bomba; os 17 móveis de dentro | `create_image_pixflux` com fundo transparente, 1 cada; os pequenos à mão | ~25 |
| 5. gente | jogador, zumbis, corpos | feito; passa a Y-sort junto com os objetos | 0 |
| 6. telhados | por cima de tudo, somem na construção em que você está (`telhados.gd`) | a textura de telha da camada 3 | 0 |
| 7. noite | o escurecer da HUD, como hoje | — | 0 |

Total: **~60 a 70 gerações** — 12 a 14 noites de bônus, ou crédito: a
ferramenta cobra por operação em dólar e um tileset sai a centavos, **menos de
US$ 10 para o mapa inteiro**, e com crédito o que é `pro` também entra. Mesma
`view` dos personagens em tudo.

**Ordem**: (1) **congelar o desenho do mapa** — nenhum tile antes disso; o
cronograma marca 21/10; (2) chão; (3) prédios; (4) objetos; (5) retoque de
paleta no servidor para tudo casar com os personagens (`reduce_colors`,
`pixelart_workbench`). Cada etapa entra no jogo e passa pelo `conferir_arte`
antes da seguinte.

**Respostas do João, 14/10**

- **Tile de 32 px.**
- **Os nove terrenos** (ver a nota sobre gramado abaixo).
- **Prédios como textura** sobre os retângulos.
- **Clima: fim do mundo, arte no estilo Project Zomboid** — "coisas meio
  escuras, sujas, abandonadas". Correção dele sobre "cidade urbana de hoje":
  a cidade é de hoje, mas largada. Pesquisar o Zomboid antes de qualquer
  desenho (feito, abaixo).
- **Créditos**: contas grátis com os e-mails da equipe, que ele mesmo vai
  pegar; nada de crédito pago por ora.
- **Regra de reaproveitamento** (dele): tile só do chão, sem variante "com
  sujeira em cima"; objeto (lata de lixo, entulho) é sprite separado, nunca
  desenhado junto com o chão. Assim uma peça serve em todo lugar e gasta-se
  menos.
- ⬜ Quando o desenho do mapa fica definitivo: não respondeu. Os tilesets
  não dependem disso (são paleta, não pintura); só a pintura final e os
  objetos no lugar dependem.

**O que o Zomboid faz, e o que a gente tira dele** (pesquisa de 14/10):

- Paleta **apagada e dessaturada**, "retrô e sombria": verdes puxados para o
  oliva, cinzas sujos, nada vivo. Jogadores reclamam que até as roupas são
  apagadas de propósito.
- O abandono é **camada, não textura**: a "erosão" do jogo põe rachaduras
  nas ruas e calçadas e mato alto sobre terra e grama **por cima** do chão,
  ao longo do tempo, como sobreposições separadas. É exatamente a regra do
  João: chão limpo, sujeira à parte.
- Ele é isométrico; o nosso é `high top-down`. O que se importa é a paleta e
  o clima, não a projeção.

**Estratégia de chão v2 — 14/10, depois de o João reprovar o primeiro
resultado** ("tá tudo muito igual, muito padronizado… chamando muita
atenção"). Pesquisa nos guias de tile (SLYNYRD "Top Down Tiles" 20 e 43,
OpenGameArt "A world of tiles", FreePixel) e no Zomboid; o que todos dizem:

1. **Contraste baixo dentro do tile.** Chão é fundo: quanto menos contraste
   entre os pixels do tile, mais chapado e mais quieto. Contraste alto é para
   objeto, usado de vez em quando. Nosso erro: juntas de lajota 45 níveis mais
   escuras que a lajota, a cada 32 px — uma grade.
2. **Nenhum detalhe dominante.** Um detalhe marcante no meio do tile (um
   tufo, uma flor) vira padrão visível quando repete. Detalhe, se houver, vai
   nas bordas, onde o vizinho quebra.
3. **Três ou quatro variações do mesmo tile, espalhadas ao acaso.** É assim
   que grama de jogo não vira xadrez; o Zomboid tem variantes de piso com
   nomes próprios para isso.
4. **Julgar o tile numa grade de 10 × 10**, nunca sozinho: a repetição só
   aparece em período.
5. O Zomboid põe rachadura, mato e sujeira em **camadas por cima** do chão
   (`0_FloorOverlay`), não no tile — a regra de reaproveitar do João.

O que mudou com isso, tudo de graça: (a) o **retoque de paleta v2** leva
juntas e asfalto a um cinza uns 23 níveis abaixo da lajota, escurece os
realces da lajota e amansa os fios amarelos da grama; (b) `rua/chao.gd`
registra **oito variações do tile cheio** de cada terreno (espelhado em x,
em y, nos dois, e tons entre 0,97 e 1) e sorteia uma por célula pelo hash da
posição; (c) o próximo passo, se ainda chamar atenção, é **regerar A e B com
"flat plain concrete, faint seams, low detail, flat shading"** (7
gerações) em vez de lajota, e aí o retoque segura o resto.

**Prefixo dos tiles e objetos do mapa** (vai em toda chamada, como o dos
personagens): `post-apocalyptic abandoned town, dirty, weathered, muted
desaturated palette, dull olive greens and grimy greys, pixel art, high
top-down, plain texture with no objects`. Fontes: discussões sobre a paleta
do jogo no Steam e a página de erosão da wiki (links no chat de 14/10).

**Quem encosta em quem** (contagem sobre o mapa traçado, em px do desenho;
×24 = px de mundo). É isto que decide quais transições existem — gerar
transição que o mapa não usa é gasto jogado fora:

| borda | px | | borda | px |
|---|---|---|---|---|
| asfalto · pavimento | 4958 | | grama · gramado | 727 |
| gramado · pavimento | 4695 | | grama · terra | 717 |
| grama · mata | 2177 | | grama · milho | 396 |
| grama · pavimento | 2109 | | mata · pavimento | 239 |
| gramado · mata | 2033 | | mata · milho | 130 |
| asfalto · grama | 1876 | | água · grama/gramado/pavimento | 112 / 96 / 68 |
| asfalto · gramado | 1410 | | asfalto · terra | 101 |
| gramado · terra | 822 | | grama · horta | 100 |

**A cadeia de tilesets** (cada um liga dois terrenos; o `base_tile_id` faz o
seguinte reaproveitar o chão do anterior, para tudo casar):

| # | de → para | para quê | gerações |
|---|---|---|---|
| A | grama → pavimento | calçada no gramado; define a grama e o pavimento base | 3–4 |
| B | pavimento → asfalto | a rua inteira, a borda mais longa do mapa | 3–4 |
| C | grama → asfalto | rua direto na grama (3.300 px de borda) | 3–4 |
| D | grama → mata | bosques | 3–4 |
| E | grama → terra | terra batida | 3–4 |
| F | grama → milho | a lavoura | 3–4 |
| G | grama → água | o rio e as lagoas | 3–4 |
| H | grama → horta | a horta (100 px de borda — pode ser só objeto) | 3–4 |

**Gramado**: nas bordas ele se comporta igual à grama (encosta em pavimento,
mata, terra, asfalto). Tratá-lo como terreno separado custaria mais cinco
tilesets (~17 gerações) só para repetir as transições. ⬜ **Proposta: gramado
= a mesma grama no tileset**, e a diferença de tom (grama cuidada × mato)
vira uma sobreposição de mato alto, à la erosão do Zomboid, que é objeto e
reaproveita. Se o João quiser os dois tons de verdade, são os ~17 a mais.
Mata · pavimento, mata · milho, asfalto · terra e asfalto · mata são bordas
curtas: ficam sem transição própria (o Godot escolhe o tile mais próximo).

Total sem gramado: **8 tilesets, ~25 a 32 gerações**.

**O caminho no Godot — feito em 14/10, com tiles provisórios.** O tileset A
falhou por falta de crédito (o bônus diário não valeu para tileset — bug
reportado), então o lado do jogo foi montado antes, com oito tilesets de cor
chapada feitos à mão no mesmo formato do PixelLab, para o gerado entrar sem
retrabalho:

- `design/rasterizar_chao.js` lê o mapa traçado e grava a classe de chão de
  cada **vértice** da grade de 32 px (`rua/chao_tracado.png`, 689 × 399, um
  pixel por vértice; índice das classes em `rua/chao_tracado.json`), com a
  mesma regra do cenário: o menor polígono que contém o ponto ganha, furos
  são grama, fora de tudo é grama. ~20 s, roda de novo quando o desenho
  mudar.
- `rua/chao.gd` (um `TileMapLayer`, nó `Chao` antes do `Cenario` em
  `rua.tscn`) lê `rua/arte/chao/tilesets.json`, monta um `TileSet` com uma
  fonte por tileset usando o `bounding_box` e os `corners` do JSON do
  PixelLab, e escolhe o tile de cada célula pelos quatro cantos (índice Wang
  NW·8 + NE·4 + SW·2 + SE, "de cima" = 1). Cantos iguais: tile cheio. Duas
  classes: a transição delas, em qualquer ordem. Três ou par sem transição:
  o tile cheio da classe mais frequente. **274 mil células em 0,6 a 0,85 s**
  ao abrir a rua — não precisou de pintura por pedaços. Não usa os
  "terrains" do Godot.
- O `Cenario` deixou de pintar os polígonos do chão quando o `Chao` existe;
  lotes, prédios, cercas, mato e árvores continuam como estavam (são as
  camadas seguintes).
- `gramado` usa o tileset da grama (`MESMA_CLASSE` em `chao.gd`) — a
  proposta acima; é uma linha para desfazer.
- Conferido: `conferir_zumbi` passa, e a captura `rua-chao.png` mostra a
  calçada, a rua e a grama no lugar dos polígonos de antes.

Quando um tileset gerado chegar: baixar `/mcp/tilesets/<id>/metadata` como
`<baixo>-<cima>.json` e `/image` como `<baixo>-<cima>.png` em
`rua/arte/chao/`, tirar o `provisorio` do `tilesets.json`, importar, olhar
no `conferir_arte`.

**14/10 à noite — o chão está completo.** Os oito tilesets foram gerados na
conta 2 (21 das 40), retocados e instalados; nenhum provisório sobrou. O
retoque passou a ser **local**: `design/retocar_chao.gd` (Godot headless)
aplica `rua/arte/chao/paleta.json` — tabelas
DE → PARA por terreno e uma **regra geral** para cor desconhecida (perde 65 %
da saturação e 20 % do valor), que foi o que deu conta de milho, água e
horta sem tabela à mão. Lição: o PixelLab ignora "muted desaturated" no
prompt; o clima vem sempre do retoque. O que ficou aquém e é candidato a
regerar quando houver crédito sobrando: a **mata** (xadrez de blocos, hoje
escondido pelas árvores) e a **água** (lodo verde com sombra preta na margem).
Pistas de câmera para olhar cada terreno: `--onde=5184,4481` mata,
`3665,1342` milho, `8592,10284` terra, `8234,1980` água, `11004,6360
--zoom=0.06` o mapa quase inteiro.

**Próximas camadas** (ver a tabela do plano): 3. prédios como textura sobre
os retângulos (parede, telhado, piso, porta, janela); 4. objetos (árvore,
carro, lata, poste, móveis); 5. Y-sort. O chão não precisa mais de geração.

### Fases 3 a 5 — prédios, objetos e Y-sort: plano de 14/10, a decidir

O João perguntou se a próxima fase "está bem planejada e estruturada". Não
estava: havia o "o quê" em três linhas e nenhum "como". Isto é o como, com
o que leva ⬜ sendo resposta dele.

**O que o jogo desenha hoje, e onde cada coisa mora.** Tudo o que não é
boneco sai de um único `_draw`: o `Cenario` pinta lote (polígono da mancha do
prédio, cor por classe do desenho — vermelho, marrom, cinza), piso interno,
paredes externas e internas (retângulos de `Construcao`), cercas, mato,
obstáculos e as 1.763 árvores (retângulos sorteados nos bosques); `Telhados`
pinta o telhado (retângulo com meia-água mais clara, beiral e a marca da
porta) e some na construção em que você está; cada móvel é um `Vasculhavel`
(Area2D) que pinta o próprio retângulo, com tamanho em `Construcao.MOVEIS`
(17 tipos, de 48 × 48 a 400 × 170 px); os carros e motorhomes são móveis
também (89 veículos, com a orientação vinda do desenho). **Consequência:**
nada disso pode ficar na frente ou atrás do jogador, porque tudo é um
desenho só, pintado antes dos bonecos. O Y-sort exige que o que é alto vire
nó.

**Ordem proposta: 5 → 3 → 4.** O Y-sort primeiro, porque é código, não
gasta nada, e define a âncora (o pé) de todo sprite que vier depois; os
prédios em seguida, porque são poucas texturas e cobrem a maior área; os
objetos por último, um a um, no que se vê mais.

**Fase 5 — Y-sort, código, 0 gerações.** Godot 4 soma os filhos de um nó com
`y_sort_enabled` aos irmãos do pai se o pai também tiver. Então: `Rua` e
`Cenario` com Y-sort ligado; o jogador (filho de `Rua`), os zumbis e os
objetos altos (filhos de `Cenario`) passam a ordenar pelo `y` do pé, todos
juntos, sem mover ninguém de lugar na árvore — os caminhos `Jogador`,
`Cenario`, `Telhados` que as ferramentas usam continuam valendo. O chão
(`Chao`, y = 0) fica embaixo por si; `Telhados` ganha `z_index = 1`, senão
cai para o fundo por estar em y = 0. O que é **plano** (lote, piso, cerca
baixa, mato, trilha) continua no `_draw` do `Cenario`; o que é **alto**
(árvore, carro, motorhome, bomba, lata, poste, cada móvel) vira um nó
`Sprite2D` com a origem no pé — os móveis já são nós (`Vasculhavel`), é só
trocar o `_draw` deles por sprite. Uns 2.200 nós, nada para o Godot.
Paredes ficam planas por ora: com o telhado cobrindo o interior de fora, a
ordem delas quase não aparece.

**Fase 3 — prédios como textura.** Texturas emendáveis de 32 px, pintadas
com `draw_texture_rect(…, tile = true)` nos mesmos retângulos de hoje —
o layout dos prédios continua vindo do desenho:

| textura | onde | proposta de pedido (com o prefixo do mapa) | gerações |
|---|---|---|---|
| parede | paredes externas e internas | "dirty cracked plaster wall seen from above, grey-beige" | 1 |
| piso | interior | "worn concrete floor, dusty, stained" | 1 |
| telhado de telha | prédios **vermelhos** do desenho (casas) | "old clay roof tiles, faded terracotta, moss" | 1 |
| telhado de zinco | **marrons** (galpão, comércio, posto) | "rusty corrugated metal roof, faded" | 1 |
| laje | **cinzas** (delegacia, hospital, bombeiros) | "flat concrete roof slab, stained, puddles" | 1 |
| pátio do lote | o polígono do lote | a `terra` do chão já serve — 0 | 0 |
| porta e janela | marca da porta; janelas a cada N px da fachada, pulando a porta | **desenhadas à mão** como as armas, 0 | 0 |

Textura emendável: conferido em 14/10 — o `create_image_pixflux` **não tem
opção de emenda**, e o tile cheio de um tileset Wang custaria 3–4 por
textura. **Decisão (14/10, ao começar a fase): as cinco texturas são
desenhadas por regra, 0 gerações** — `design/desenhar_texturas.js` gera
parede, piso, telha, zinco e laje em 64 × 64 com ruído por pixel, manchas e
riscos que dão a volta na borda (emenda garantida), e mais a porta (24 × 14)
e a janela (16 × 10) à mão. É o que os guias pedem para fundo (contraste
baixo, nenhum detalhe dominante) e o que a lição do chão ensinou: o gerador
entrega vivo e repetitivo, e o clima vem do controle fino. Os créditos
ficam para os objetos, que precisam do gerador de verdade.

**Fase 3 feita em 14/10, 0 gerações.** `rua/arte/predios/` tem as cinco
texturas e os dois sprites; `cenario.gd` repete piso (tingido de quente na
sua casa) e parede nos retângulos de sempre; `telhados.gd` repete telha,
zinco ou laje pela cor do prédio no desenho (a sua casa é telha), mantém
beiral e cumeeira (a laje não tem cumeeira) e desenha **a porta no centro
do vão, girada para a orientação da fachada, e janelas a cada 72 px dos dois
lados**, sem invadir 44 px em volta da porta nem 24 px dos cantos. As
texturas repetem a cada 64 px: nas paredes (20 px de espessura) não se nota;
nos telhados grandes a telha e o zinco são padrão mesmo, e a laje e a
parede mostram as manchas repetindo de longe — se incomodar, é aumentar a
textura para 128 ou pôr as variações de tom do chão também aqui. Figura
`predios.png` na Área de Trabalho (frente da sua casa, uma quadra da rua,
dentro da sua casa, e as texturas ladrilhadas 4 × 4). A fachada
(a face sul da parede, que no `high top-down` aparece como uma faixa sob o
beiral) é código: uma banda mais escura, sem desenho novo.

**Fase 4 — objetos.** Um sprite por tipo, fundo transparente, `high
top-down`, o pé no chão; o tamanho no mundo é o `tamanho` da ficha (a
pegada) mais a altura visível. Separado do chão, na regra do João. Em
ordem de quanto aparece:

| objeto | pegada (px) | quantos no mapa | como | gerações |
|---|---|---|---|---|
| árvore | copa 80–120 | 1.763 | 2–3 copas por geração, giradas e espelhadas no código | 2–3 |
| carro | 180 × 80 | 89 (com motorhomes) | 1 sprite de lado; **girado 90° no código** para os de pé, como o corpo do zumbi; 2–3 cores pelo retoque | 1–2 |
| motorhome / ônibus | 400 × 170 | poucos | 1 | 1 |
| lata de lixo, caixa, poste, cerca | 48–56 | muitos | **à mão**, como as armas | 0 |
| bomba de combustível | 56 × 86 | 1 posto | 1 | 1 |
| geladeira, armário, cômoda, estante, prateleira, arquivo, maca, 4 armários especiais | 70–156 × 38–54 | 284 móveis | 1 cada, 11 tipos | ~11 |

~17 gerações. Com as 19 que sobram e 5 por noite, **as fases 3 e 4 cabem na
conta 2 sem terceira conta**, em dois ou três dias.

**Respostas do João, 14/10**

- **Janelas: sim**, "tem que ter janelas nos prédios" — postas a cada N px
  da fachada, pulando a porta, desenhadas à mão.
- **Telhado por cor do desenho: ok** (vermelho = telha, marrom = zinco,
  cinza = laje).
- **Ordem 5 → 3 → 4**: ele não tinha entendido a numeração (são as fases da
  tabela); explicado, e o Y-sort foi feito em seguida (abaixo).
- **Carro: precisa de vários ângulos**, "temos ruas em diversas direções" —
  então `create_8_direction_object` (8 rotações numa chamada) em vez de um
  desenho girado; o código escolhe a rotação mais perto do ângulo da rua.
- **Objetos: rua primeiro** (árvore, carro, lata), móveis de dentro depois.

**Fase 4 — andamento (14/10, à noite).** O `create_8_direction_object` que
a resposta do carro pedia custa **10 a 25 gerações** por objeto (conferido
no esquema da ferramenta), e o de 1 direção também: fora do alcance das 19.
Saída: `create_image_pixflux`, **1 geração por imagem**, e a vista resolve
as direções — pedindo `direction=south` com "seen from directly above /
bird's-eye" o carro e o motorhome saem em **vista pura de cima**, que gira
no código para qualquer rua sem perder nada (pedir `east` deu um carro DE
LADO, inútil: 1 geração perdida). Feito e no jogo, 5 gerações (sobram 14):

- `rua/arte/objetos/arvore-a.png` (viva) e `arvore-b.png` (seca):
  `cenario._criar_arvore` virou `Sprite2D` escalado pela copa sorteada, pé
  do tronco na borda de baixo (`ARVORES`, com a linha do pé medida no PNG);
  uma seca a cada três (`UMA_SECA_A_CADA`), espelho por sorteio. A caixa de
  colisão continua sendo a copa inteira (greybox) — afinar para o tronco é
  outra conversa.
- `carro-em-pe.png` (96 × 200, 79 × 178 opacos na pegada de 80 × 180) e
  `motorhome-em-pe.png` (176 × 400): `vasculhavel.gd` ganhou `desenho`,
  `giro` e `espelhado` e desenha o sprite com o pé na borda de baixo da
  pegada (`_desenhar_o_desenho`); vazio = escurecido (`TINTA_DO_VAZIO`).
  `cenario._desenho_de(tipo, em_pe)` carrega `rua/arte/objetos/<tipo>.png`
  ou `<tipo>-em-pe.png` se existir — senão o móvel fica na caixa do greybox,
  como antes. Veículo "deitado" no desenho sem sprite deitado usa o em pé
  girado ±90° (lado e espelho por sorteio da chave). Móvel de dentro com
  pegada transposta gira pelo `GIRO_POR_PORTA` (frente para a sala; porta ao
  norte fica sem giro).
- O motorhome veio **com fundo cinza e sombra** apesar do `no_background`:
  `design/recortar_fundo.gd` inunda a partir das bordas (tolerância 0,35
  na cor do canto) e tira fundo e sombra, parando no contorno preto. Rodar
  em todo sprite que vier assim, e **reimportar** (`--headless --import`)
  depois de trocar um PNG, senão o jogo usa o antigo.
- Figura `objetos-rua.png` na Área de Trabalho (bosque, carro em pé na
  fazenda, carro deitado numa rua, motorhome no camping).

Em aberto para o João (nada gerado até responder):

1. O motorhome saiu com **129 × 257 px opacos num vão de 170 × 400** (o
   gerador deixou margem e fez um furgão curto, não um ônibus): regerar
   pedindo "fills the frame edge to edge, long bus-shaped" (1 geração, sem
   garantia), escalar 1,56× (pixel irregular ao lado do carro nítido), ou
   encolher a pegada dos compridos para ~260 × 130 (muda colisão e o
   desenho do mapa).
2. **Vista dos móveis de dentro** (12 tipos, 1 geração cada): pura de cima
   como o carro (o armário vira um retângulo de tampo, lê pouco) ou
   inclinada como o boneco (tampo + face da frente para baixo, estilo
   Zomboid, lê bem encostado na parede). O código já espera a segunda (pé
   na borda de baixo, sobra sobe pela parede). Os armários especiais (armas,
   remédios, seringas, bombeiro) podem ser **um só armário de metal tingido
   pela cor da ficha** — 9 gerações em vez de 12.
3. ~~Mato dos bosques ainda é retângulo~~ — feito abaixo.

**Fase 4 — o resto do externo (14/10, mais tarde).** João: "está
planejado? … se for isso então pode seguir". 2 gerações (sobram 12):

- **Mato**: `mato.png` (64 × 40, tufo oliva e marrom) no lugar dos
  retângulos verdes; `_desenhar_mato` estica ao tamanho sorteado e espelha
  por sorteio, ainda no `_draw` do cenário (rasteiro, por baixo de quem
  anda).
- **Pátio dos prédios**: a mancha chapada do lote virou **tinta a 30 %**
  por cima dos tiles (`ALFA_DO_LOTE`): o pátio continua lendo como do
  prédio, mas é grama ou calçada por baixo.
- **Blocos sólidos** (6 manchas marrons do desenho pequenas demais para
  prédio): zinco dos galpões com beiral (`TEXTURA_BLOCO`), em vez do
  retângulo chapado.
- **Porta da sua casa**: o retângulo laranja saiu; `entrada_de_casa.gd`
  desenha uma soleira escura translúcida e a mesma `porta.png` dos outros
  prédios em 2× tingida de quente. **Regressão achada e corrigida**: desde
  o Y-sort a EntradaDeCasa estava POR BAIXO do telhado (o `z_index = 1` dos
  Telhados passava na frente dela e escondia a barra de E) — agora ela tem
  `z_index = 2` no `rua.tscn`.
- **Bomba**: gerada (`bomba.png`, vista inclinada), mas sem lugar no mapa
  (ver tabela). Proposta: uma bomba na frente do posto, a ~120 px da porta
  (porta leste), como `movel_de_rua` posto pelo rótulo em `mapa.gd` — é
  posição de mapa, decisão do João.
- O que resta chapado de fora: a luz da porta da sua casa (retângulo bege
  translúcido, de propósito, é aviso) e as cercas e postes, que o traçado
  não tem.
- Figura `externo.png` na Área de Trabalho (bosque com mato, bloco de
  zinco ao lado de um galpão, porta da sua casa, pátio) e
  `bomba-nao-colocada.png` ao lado. `conferir_zumbi` e `conferir_fim`
  passam.

**14/10, mais tarde — João: "ok, pode fazer os dois".** Decisão minha
dentro do que ele liberou: motorhome **regerado** pedindo para encher o
quadro (1 geração; se vier pequeno de novo, cai para a escala 1,56×), e
móveis na **vista inclinada** (tampo + frente para baixo, como a bomba),
8 gerações: geladeira, armário, cômoda, estante, prateleira, arquivo, maca
e **um armário de metal** (88 px) que serve aos quatro especiais tingido
pela cor da ficha (`"desenho"` na ficha aponta o PNG partilhado; a tinta é
a cor da ficha normalizada ao brilho 1, para não escurecer o sprite). Caixa
à mão em `desenhar_texturas.js`. Canvas = largura da pegada arredondada a
8, altura = fundo da pegada + face da frente (72–96 px). Pedido fixo:
"seen from above at a high angle, top and front face visible, front face
at the bottom, the whole object fills the frame" + prefixo de fim do mundo.

**Resultado (14/10, noite).** As 10 gerações saíram todas boas de primeira
(tabela); **sobram 3 na conta 2**. Motorhome v2 em 1:1 (118 × 344 opacos
no vão de 170 × 400, ônibus de verdade). Os 8 sprites de móvel estão em
`rua/arte/objetos/` com o nome do tipo; os quatro armários especiais
apontam `armario-de-metal.png` pela chave `"desenho"` da ficha e saem
tingidos. A caixa é desenhada por regra (`desenhar_texturas.js`, segundo
argumento = pasta dos objetos). Lição da primeira captura: na vista
inclinada o sprite é mais alto que a pegada, e encostado numa parede
lateral (porta leste/oeste) ele **atravessava a parede e aparecia do lado
de fora** do prédio — agora `vasculhavel.gd` deixa o desenho subir no
máximo uma parede (`FOLGA_SOBRE_A_PAREDE` = 20) e o resto desce para dentro
da sala (a frente pintada no chão, por onde se anda; a colisão continua a
pegada). A sua casa continua vazia de propósito: não se vasculha. Figura
`moveis.png` na Área de Trabalho (farmácia com armários de remédios
tingidos e prateleira girados para leste, hospital com macas, delegacia e
prefeitura com arquivo).

**Fase 4 está inteira.** O que ainda é caixa/cor chapada: nada de móvel.
Restam a bomba sem lugar no mapa (proposta acima), lata (sem lugar), a
luz da porta da sua casa (de propósito), e os dois tiles fracos do chão
(mata, água) — 3 gerações não regeram um tileset (4 cada). Próximo
crédito: outra conta da equipe ou assinatura.

**João, 14/10, depois de ver tudo:** "o mapa tá vazio porque ele era só
um conceitual até então, depois vamos adicionar várias coisas a mais, nas
ruas e dentro dos ambientes". Então bomba e lata sem lugar não são
problema: entram quando o mapa for povoado, e cada objeto novo custa 1
geração neste mesmo pedido (vista inclinada para o que fica encostado,
pura de cima para o que fica no chão da rua). Ele vai passar uma conta
com mais créditos.

**Fase 5 feita em 14/10 — Y-sort.** `Rua` e `Cenario` com `y_sort_enabled`;
`Telhados` com `z_index = 1` para continuar por cima. As 1.763 árvores
deixaram de ser `draw_rect` e viraram um `Polygon2D` cada, com a origem a
20 px acima da borda de baixo da copa (o mesmo recuo do pé do jogador, cuja
caixa é centrada: pé em +20), para o sort comparar pé com pé. Os móveis já
eram nós (`Vasculhavel`) e entram pelo centro; quando virarem sprite, a
origem desce para o pé. O teto de nós do cenário subiu de 2.000 para 4.000
(3.069 hoje), documentado. Prova: `conferir_arte --tiros` põe um zumbi
ferido um pouco atrás do jogador e o corpo caído por cima dos pés dele
(`ysort.png` na Área de Trabalho). `conferir_zumbi` e `conferir_arma` passam.

## O que ainda não está decidido

Fechado pelo João em 30/09 (questionário e teste 0): manter a ferramenta,
`high top-down`, boneco de 80 px em escala 1, 8 direções, proporção `default`,
contorno preto e sombra básica, paleta dessaturada, os dois personagens, o zumbi
perseguindo com o mesmo andar acelerado, e para onde o jogador olha. **Em
05/10:** vida e dano em unidade de vida (zumbi 100, Beretta 20 — "5 tiros por
enquanto"); corpo 60 s no chão, ou até o fim do dia se carregar algo, e o
corpo se vasculha (inventário vazio por enquanto); a arma na mão como sprite
à parte, sem gerar; **a lista das oito armas** e **munição por calibre**; e
**nada gerado até ele decidir** ("faz sem gerar nada primeiro e eu decido
depois"). Continua aberto:

- ⬜ **O Renan.** A equipe tem dois artistas e ele é o da rua. Ele vê o jogador
  e diz se a arte dele convive com isso — e se quer mexer no prefixo (é agora,
  antes do elenco crescer).
- ⬜ Os modelos de animação: `walk` para o jogador e `sad-walk` para o zumbi são
  a primeira escolha; trocar depois custa 8 cada.
- ⬜ Depois das 40: **o pingo diário existe** (bônus `generations_today`, +5 por
  noite até 20, gasto só quando as 40 zeram — visto em 05/10). Com ele, 5 por
  dia de graça; crédito (menos de US$ 10 para a rua inteira) ou um mês do Tier
  1 (US$ 12) só se a equipe quiser ir mais rápido — e quem paga, já que a
  conta é pessoal. Números em "O que custa".
- ⬜ **O que as 10 gerações da reserva compram** (ver "Modo econômico"). Em
  03/10 o João pediu três animações, e as 10 não pagam as três: `dano` do
  zumbi (`taking-punch`, 8), `morrer` do zumbi (`falling-back-death`, 8) e
  `atirar` do jogador (`v3`, 16 a 24 — não há modelo de pistola). As 10 pagam
  **uma** das do zumbi, sobrando 2. As três juntas (24 a 32) mais os dois
  personagens refeitos (2) cabem numa conta grátis de um colega (40). Em
  05/10 o João viu as versões de código e disse "faz sem gerar nada primeiro
  e eu decido depois". **Mais tarde em 05/10 ele pediu duas: o ataque
  (`toque`) e a morte (`morrer`) do zumbi**, e decidiu: "gera o ataque
  primeiro e aproveita os 2 de sobra pra … o frame dele morto no chão".
  **Feito**: `toque` nas 8 direções e `morrer` no sul em 05/10 — as 40
  acabaram —, e `morrer` nas outras 7 em 14/10, com o bônus diário (+5 por
  noite até 20; sobraram 7). ⬜ **O que o bônus compra agora**: o `dano` do
  zumbi (`taking-punch`, 8), o `atirar` do jogador (16–24)… Gastar antes de
  bater no teto de 20, senão a noite não rende.
- ⬜ **O que o zumbi carrega.** A regra dele (05/10): corpo com algo no
  inventário fica até o fim do dia, e **o corpo se vasculha** como um móvel
  (segure E em cima dele; feito 05/10, "deixa nada no zumbi por enquanto mas
  faz com que tenha como acessar o inventário dele"). Hoje o inventário existe
  e está vazio — o que ele carrega (balas? documento?) é decisão de mesa.
- ⬜ **As armas: a lista fechou em 05/10** — Revólver 38, Beretta 9mm, Doze 2
  canos, Benelli semiauto, CTT40, Fireagle 9mm, Fall e M4 (ver "As armas").
  Munição por calibre também fechou (05/10). Continua aberto: os números de
  cada uma (hoje proposta minha), como se consegue outra arma além da Beretta
  (hoje `Q` troca, protótipo) e a raridade de cada calibre no vasculho (hoje
  peso igual, e o mapa rende munição de fuzil antes de haver fuzil).
- ⬜ **Mirar.** Hoje o jogador olha para o mouse só enquanto atira e por 0,5 s
  depois. Botão de mirar, ou a arma sempre na mão?
- ⬜ **Quem da equipe abre conta** no PixelLab para somar o grátis — e se os
  tiles são desenhados pelo Renan ou gerados. **Em 14/10 o João avisou que
  não dá para depender muito da equipe** ("somos nós por nós"; ele pede algo
  aos colegas de vez em quando): o caminho principal passa a ser o bônus
  diário (+5 por noite até 20) e, se ele quiser ir mais rápido, crédito pago.
  Conta de colega e tile do Renan são bônus, não plano.

- ⬜ Época e lugar (`narrativa.md`) — quando fechar, entra no prefixo dos
  personagens novos e nos tiles, não nos que já existem.

## A casa — arte da equipe, decidida em 16/10

A casa não é PixelLab: **a equipe fotografou cômodos de verdade e pixelou**
(fotos escurecidas, com sujeira e sangue), no molde de *No, I'm Not a Human*.
Baixado da pasta "casa principal" do Drive da equipe em 16/10/2026, com
autorização explícita do João e só essa pasta. Inventário:

| arquivo (pasta "pixel", 1448 × 1086, 4:3) | o que mostra |
|---|---|
| `porta_entrada_suja.png` (duas versões) | a porta de entrada por dentro, sacos de lixo, sangue na parede |
| `sala_de_estar_suja.png` | a sala vista da TV (painel, rack) |
| `sala_de_estar_suja_back_view.png` | a sala vista do sofá (portas de madeira ao fundo) |
| `cozinha_suja.png` | a cozinha, bancada de granito, geladeira |
| `quarto_sujo.png` | o quarto, cama de casal com crucifixo em cima, guarda-roupa |
| `corredor_cozinha_quarto_porao_sujos.png` | o corredor, portas dos dois lados, mesa de jantar ao fundo |

A pasta "primeira versão" tem as mesmas seis cenas em JPG, **limpas**, sem
sujeira. Não há foto de porão nem de nada que sirva de cela.

**Decisões do João (16/10):**

- **O corredor fica** e vira o centro da casa, com portas para a cozinha e
  para o quarto. **Não há porão.**
- **O quarto é onde ela está presa.** O jogador **dorme no sofá da sala**.
- A casa inteira com **energia pesada**, como *No, I'm Not a Human*; o
  quarto, além disso, **macabro, destruído e sujo** — "um zumbi mora nele".
  A foto atual do quarto (cama arrumada) **não serve**: refazer.
- Planta nova: entrada → sala → corredor → cozinha / quarto.

**Quarto macabro — refeito por nós, sem pedir à equipe (João, 16/10).** O
brief abaixo ficou só de registro: o João decidiu editar a própria foto
("no fim são pixels"). Duas camadas: o **gerador** muda a cena (só a região
da cama, do painel da cabeceira e do criado-mudo da esquerda) e o **código**
suja (manchas, respingos, arranhões, marcas de mão, mofo, escurecer).
Decidido por ele no questionário de 16/10: **corrente grossa chumbada no
painel da cabeceira**, caindo sobre a cama (ela fica acorrentada ali); o
**criado-mudo branco da esquerda** é a "cômoda virada"; o **crucifixo fica**
como está. A foto limpa do quarto é a `IMG_6354`.

**A grade real das fotos não é de 8 px.** Medida pelas fronteiras de bloco
(`reduzir.js` no scratchpad; ampliar de volta com as mesmas fronteiras dá
0 pixel diferente): quarto, sala, sala de costas e `porta_entrada_suja-1`
são **207 × 156** (blocos de 6–7 px); o corredor é 181 × 136 (8 px); a
cozinha, 242 × 181 (6 px); `porta_entrada_suja.png` (2,2 MB) **não está
pixelada**. Toda edição é feita na grade e volta à foto bloco a bloco.

**Ferramenta: `edit_image_pixen`, 1 geração por tentativa** — é a única de
edição que custa 1 (`inpaint_image` 10–25; `inpaint_image_pro_flash` e
`edit_image_pro_flash` 6 neste tamanho). Ela reescreve a imagem inteira
(entrada até 256 px por lado, múltiplo de 4: a grade vai a 208 × 156 com
uma coluna repetida), então do resultado **só a região marcada é colada**
sobre o original, e o resto da foto fica idêntico.

**O que pedir à equipe (brief do quarto):** refotografar o MESMO quarto, do
MESMO ponto e enquadramento da foto atual (os retângulos de clique vão ser
desenhados em cima dela, então a cama, o criado-mudo e o guarda-roupa têm
que ficar onde estão), e sujar de verdade antes de pixelar: cama destruída
e manchada, lençol rasgado no chão, arranhões e marcas de mão na parede,
cômoda virada, cortina rasgada, lixo e restos no chão, e um canto onde se
veja onde ela fica (corrente, corda ou grade na porta, à escolha deles). Sem
mostrar ela — ela é o `ela.gd`, por cima. Mesmo processo de pixelar e
escurecer das outras, e entregar em 4:3 como as demais, 1448 × 1086.

**Integrado no jogo em 16/10.** Decidido pelo João no questionário: o
jogo fica em **16:9** (é o formato normal de jogo de PC; a janela é 1280 × 720)
e as fotos são **cortadas**, não com faixa preta; a porta que entra é a
**pixelada** (`porta_entrada_suja-1.png`); a sala entra com **as duas
vistas**, virando entre elas; o **olho mágico** e o **rádio** não existem nas
fotos e são **desenhados em código** por cima (na porta, na altura do olho; no
rack, à esquerda da TV); a **foto do casal** fica nos **porta-retratos da
sala**. **A planta — por onde se vai de um cômodo ao outro — ele deixou para
mim** ("pode decidir, coerente com o desenho de uma casa, no futuro eu vejo se
gosto"): a porta escura da direita na vista da TV é a mesma porta da rua da
entrada, e a parede listrada ao lado da TV é a mesma da entrada, então de
costas para a porta vê-se o sofá. Entrada —virar→ sofá —virar→ TV; na vista da
TV a porta da rua volta à entrada e a passagem da esquerda vai ao corredor; no
corredor o fundo (sala de jantar) vai à cozinha e a porta de madeira da
esquerda ao quarto; o batente da direita é só cenário. Corredor e cozinha
entram como a equipe entregou.

Como ficou:

- `design/casa_fotos.js` corta cada foto em 16:9 e grava
  `casa/arte/<cômodo>.png` em **1280 × 720** (vizinho mais próximo: os blocos de
  ~7 px viram 6–7 px, sem borrar). Altura do corte, em unidades da tela (a
  foto inteira tem 240; 30 = meio): entrada 30, sala/TV 30, sala/sofá 36,
  corredor 30, cozinha 40 (mais bancada, menos teto), quarto 26 (para o
  crucifixo não cortar).
- O SubViewport da casa passou de 640 × 360 a **1280 × 720**, com o desenho em
  escala 4: a foto entra 1:1 e o traço tem na tela a mesma grossura de antes.
  O greybox dos cômodos saiu do `desenho.gd`; sem foto, a tela fica preta.
- `casa/comodos.gd` refeito em cima das fotos (retângulos medidos em pixel,
  não a olho — o primeiro gabarito, lido a olho, tinha os retângulos
  deslocados ~25 unidades). Cômodos: `entrada`, `sala_sofa`, `sala_tv`,
  `corredor`, `cozinha`, `quarto`. Figura `teste-0-pixellab/casa-gabarito.png`.
- O que o código desenha por cima: olho mágico, rádio, a estática da TV
  ligada, **os papéis da pesquisa na frente da bancada** (um por documento,
  riscado o estudado — era o quadro do greybox) e **ela no quarto**, 1,35x,
  em pé na cama entre as pontas das correntes geradas, com um pedaço de
  corrente de cada pulso até a ponta.
- Porão → quarto nos textos e na lógica (`casa.gd`, `ela.gd`,
  `fim_de_jogo.gd`, README, `narrativa.md` com nota datada); dormir = sofá.
- `conferir_casa` (agora confere também que todo cômodo tem foto de 1280 ×
  720) e `conferir_fim` passam. Figura do jogo rodando:
  `teste-0-pixellab/casa-no-jogo.png`.

**Filtro e ela — João, 16/10: "arruma o filtro, e redesenha ela se
necessário, mas saiba que vai ser provisório, o desenho da namorada vai ser
feito ainda".** Nada gerado.

- **O filtro engolia as fotos**: feito para o greybox em "cor de dia", a curva
  jogava no preto tudo abaixo de 0,12 de luminância — ~36 % de cada foto da
  equipe e ~50 % do quarto — e tingia 74 % de verde; no jogo as correntes, as
  mãos e o sangue sumiam. Quatro variantes comparadas numa emulação em JS do
  shader (atual; sem corte no preto; + menos verde e vinheta menor; claro). Ficou
  a terceira, um pouco mais escura: a curva virou três parâmetros com nome no
  `filtro.gdshader` — `sombra` 0 (não corta mais a sombra), `luz` 0,58, `gama`
  0,8 (abre as sombras) —, `noite` 0,74 → 0,55 (o sangue segue vermelho-escuro
  por baixo do verde) e `vinheta` 0,85 → 0,72. Grão, aberração e a lâmpada
  piscando não mudaram. Afinável no editor, no material da tela.
- **Ela, provisória**: o traço liso do greybox, em pé na cama, brigava com a
  foto. Virou um **boneco de pixel montado em código** (`desenho.gd`,
  `_desenhar_ela`), 36 × 52 pixels **no mesmo bloco das fotos**
  (`Comodos.BLOCO_DA_FOTO` = 320/207 unidade): ajoelhada na cama, camisola clara
  e suja, cabelo escuro na cara com duas mechas, braços caídos e as mãos nas
  coxas, uma algema em cada pulso ligada à ponta da corrente gerada, contorno
  escuro de 1 pixel. "Ferve" em 4 quadros; com o estágio a pele acinzenta, ela
  se curva, o sangue cresce no peito e na barra, os olhos ficam brancos e, no
  último, a boca abre. Quando o desenho da equipe chegar, entra no lugar de
  `_desenhar_ela` (lugar, clique e correntes ficam). **Os closes do exame**
  (olho, dentes, braço, mãos) continuam no traço antigo — são parte do desenho
  dela, ficam para o da equipe.
- O `conferir_casa` dizia "SEM PROBLEMAS" com o `casa.gd` sem compilar (tudo
  virava Nil e as comparações passavam): agora falha se a casa não compila.
- Figuras: `teste-0-pixellab/casa-no-jogo.png` (as seis telas com o filtro novo)
  e `ela-provisoria.png` (os quatro estágios, sem e com o filtro).

## Registro de gerações

| data | o quê | id no PixelLab | gerações | saldo | aprovado por |
|---|---|---|---|---|---|
| 30/09 | teste 0 — jogador, `high top-down`, size 64 (boneco 61 px, canvas 92) | `573c4dc5-fcac-4c02-837f-43774a721176` | 1 | 39 | João: câmera sim, tamanho não. Apagar quando o v1 estiver aprovado |
| 30/09 | teste 0 — jogador, `low top-down`, size 64 (boneco 65 px) | `df230181-b9e4-4bf2-afa4-f466cc8dbc52` | 1 | 38 | João: sem diferença visível para o `high`. **Apagado** |
| 30/09 | jogador v1 — `high top-down`, size 80 (boneco 75–79 px, canvas 112), escala 1 | `47a4b495-cdf1-46ec-a342-1a40f0cac238` | 1 | 37 | João, 30/09, visto sobre o greybox em 4 direções — com o olho trocado para verde por script (ver "Retoques de paleta") |
| 30/09 | jogador — `andar` em `template` (`walk`), só o sul, 6 frames | grupo `d950d09d-5500-4116-b633-a2b6ad2b6be6` | 1 | 36 | João: **rosto borrado** nos frames. O sudoeste travou 14 min em "100%" e foi cancelado — não cobrou |
| 30/09 | jogador — `andar-v3` (`v3`, "walking forward at a steady pace", 8 frames, sem frame 0), só o sul, para comparar | grupo `56674f9d-0bbc-429d-9dc1-559076473358` | 2 | 34 | João: **v3 fica** — rosto estável nos 8 frames, passada mais contida, camiseta um tom mais escura. O grupo template foi apagado |
| 30/09 | jogador — `andar-v3`, as outras 7 direções, uma por chamada, no mesmo grupo | grupo `56674f9d-…` | 0 de 14 | 34 | ⬜ **não rodou**: a partir de ~23h o PixelLab passou a recusar a camada gratuita por alta demanda ("high demand, temporarily limit free tier"). O v3 devolvia "Generation failed" na hora, sem cobrar; o motivo real só apareceu no erro do zumbi. Retomar quando o servidor liberar |
| 30/09 | zumbi v1 — `high top-down`, size 80, descrição da tabela | `6b2d703c-80c6-48a4-abd3-cd8f630dd60e` (falhou) | 0 | 34 | **falhou pelo limite da camada gratuita**, não cobrou |
| 30/09 | zumbi v1 — mesma chamada, 10 min depois (servidor liberou) | `6dad99f8-6a01-448a-ab0a-bcf388498f64` | 1 | 33 | gerado: boneco 76–80 px, canvas 112. João achou "muito humanizado", pediu um v2 mais monstruoso, reprovou o v2 e ficou com o v1. **Renan aprovou o v1 em 02/10** ("podemos fazer a v1") e vai fazer variantes dele — ver "Variantes" |
| 02/10 | zumbi — `vagar` (template `sad-walk`), 8 direções, uma por chamada | grupo `2040b631-f8d6-4f4d-b1c4-56de825949a6` | 8 | 10 | **completo nas 8 direções, 8 frames cada.** O pingo diário **não apareceu**: o saldo amanheceu em 18, não em 20 — a regra "5/dia até 20" veio do assistente da ferramenta e pode estar errada |
| 02/10 | zumbi — frame 5 do `vagar` norte: apagado um "texto" fantasma de 70 px nas linhas 103–107, abaixo dos pés (`pixelart_workbench edit` com `patch_pixels` + `save_to_asset`) | imagem `9736db5b-a3b4-44f4-ac01-cca7dcbb8cc8`; desfazer com `bef65821-c1c8-4728-ae5a-625c6ed9c078` | 0 | 10 | gravado no servidor e baixado de novo; os outros 63 frames do zumbi e os 64 do jogador foram varridos e estão limpos |
| 02/10 | jogador — olho verde **gravado no servidor**: 8 rotações (30 px) e 8 direções do `andar` (123 px), por `pixelart_workbench edit` + `save_to_asset` | — | 0 | — | João (decisão de 30/09). Norte e noroeste não tinham o que trocar; o leste do `andar` tem canvas 116, as outras 112 |
| 30/09 | jogador — `andar-v3`, sudoeste (retomada após o servidor liberar) | grupo `56674f9d-…` | 2 | 31 | feito |
| 30/09 | jogador — `andar-v3`, oeste | grupo `56674f9d-…` | 2 | 29 | feito |
| 30/09 | zumbi v2 — mesma chamada fixa, descrição "grotesque monstrous zombie…" | `75310404-46ab-4f7b-ad03-1177a254aa07` | 1 | 28 | **João reprovou**: "muito esqueleto e pouco zumbi"; preferiu o v1. **Apagado** |
| 30/09 | jogador — `andar-v3`, noroeste | grupo `56674f9d-…` | 2 | 26 | feito |
| 30/09 | jogador — `andar-v3`, norte | grupo `56674f9d-…` | 2 | 24 | feito |
| 30/09 | jogador — `andar-v3`, nordeste | grupo `56674f9d-…` | 2 | 22 | feito |
| 30/09 | jogador — `andar-v3`, leste | grupo `56674f9d-…` | 2 | 20 | feito |
| 30/09 | jogador — `andar-v3`, sudeste (a última) | grupo `56674f9d-…` | 2 | 18 | feito — **`andar` completo nas 8 direções, 8 frames cada** |
| 01/10 | download: ZIP do jogador (72 PNG + `metadata.json`), spritesheet dele e ZIP do zumbi v1; olho verde aplicado na cópia (153 px em 72 arquivos) | — | 0 | 18 | pacotes na Área de Trabalho do João (`teste-0-pixellab/`); `rua/arte/` ainda não existe |
| 03/10 | vida do zumbi (100, tiro tira 40), `tocar()` no boneco e as versões de código de `atirar`, `dano` e `morrer` — nada gerado | — | 0 | 10 | pedido do João ("usando a arma", "sofrendo dano e morrendo", "devem ter uma vida"); os números são proposta. `conferir_arma` e `conferir_zumbi` passando |
| 05/10 | tiro passa a tirar 20 (cinco tiros, em unidade de vida); corpo com inventário fica até o fim do dia; **a arma na mão** como sprite à parte (12 × 7, desenhado em pixel por mim) — nada gerado | — | 0 | 10 | João ("pode ser 5 tiros por enquanto", "faz versão dele com a arma na mão", "faz sem gerar nada primeiro"). Conferências passando; figura em `teste-0-pixellab/rua-com-tiros.png` |
| 05/10 | **as oito armas** da lista do João desenhadas à mão (`rua/arte/armas/`, de 12 × 7 a 30 × 9, por `design/desenhar_armas.js`), `pistola.gd` vira `arma.gd` com a ficha das oito; o corpo do zumbi vira vasculhável (vazio) — nada gerado | — | 0 | 10 | João (a lista; "deixa nada no zumbi por enquanto mas faz com que tenha como acessar o inventário dele"). Os números das fichas são proposta; `conferir_arma` passa pelas oito. Figuras `rua-arma-fall.png` e `rua-arma-doze.png` |
| 05/10 | **munição por calibre** (.38, 9mm, 12, .40, 7,62, 5,56): `Construcao.MUNICOES`, `Travessia.balas`, caixinha do vasculho com calibre sorteado — nada gerado | — | 0 | 10 | João ("faz um tipo de munição pra cada"; li como por calibre, porque ele nomeou as armas pelo calibre e duas são 9mm). Raridade por calibre é ⬜ |
| 05/10 | zumbi: o corpo para na pose parada antes de tombar; o toque vira golpe (para 0,3 s, investe 8 px) com gancho para `toque`; cinto nasce com 15 de cada calibre, para testes — nada gerado | — | 0 | 10 | João ("animação de ataque", "animação de morto, e não só ficar caminhando de lado no chão", "nascer com as balas de cada arma"). As duas animações de verdade (16) esperam ele dizer qual vai com as 10 |
| 05/10 | zumbi — `toque` (template `cross-punch`), 8 direções, uma por chamada, 6 frames cada | grupo `c9f731db-d49e-47d9-abc8-3c5be3ea09eb` | 8 | 2 | **João: "gera o ataque primeiro"**. **As 8 saíram limpas** (vistas na folha a 3×): soco com o braço estendido, rosto estável, sem fantasma. Já na folha do jogo |
| 05/10 | zumbi — `morrer` (template `falling-back-death`), só o sul, 7 frames: a queda no sul e **o frame do morto no chão**, que o código usa nas outras direções (um corpo deitado vale para as oito) | grupo `9c89639d-6ede-402b-93fc-d22409d8afa6` | **2** | 0 | João: "aproveita os 2 de sobra pra … o frame dele morto no chão". **Cobrou 2, não 1** (o saldo das 40 foi de 2 a 0 com esta chamada). O quadro 3 virava de costas por um frame — **trocado por uma cópia do quadro 2** no servidor, de graça |
| 05/10 | zumbi — `morrer` sul, quadro 3: `pixelart_workbench edit` com `copy_region` do quadro 2 + `save_to_asset` | imagem `a42ffb84-dcbf-4953-a32d-f141f22df386`; desfazer com `8d25c8bf-71ee-43f7-883a-efcf8ca3bd57` | 0 | 0 | gravado no servidor e baixado de novo. O morto no chão deita **com a cabeça para a esquerda**, não para cima — o código espelha quando a queda tomba para a direita |
| 14/10 | zumbi — `morrer` (`falling-back-death`), as outras 7 direções, uma por chamada, no mesmo grupo, 7 frames cada | grupo `9c89639d-…` | **13** (a ferramenta avisa: "2 por direção, em 2 lotes"; um lote saiu a 1) | bônus: 20 → **7** | João, 14/10 ("consegue fazer agora?"), com o bônus diário no teto de 20. **As 7 saíram boas** (vistas na folha a 3×): queda para trás e corpo deitado no fim, nenhuma virou de costas. **`morrer` completo nas 8 direções**; a troca pelo quadro do sul (`_deitar`) virou reserva. Folha no jogo e no pacote da Área de Trabalho |
| 14/10 | **tileset A — grama → pavimento**, 32 px, `high top-down`, sombra básica, transição 0,25 ("crumbling concrete curb edge with dirt and weeds"), prefixo de fim do mundo | tileset `a89bbdaf-97b0-4797-8309-444e7265d3b1`; base grama `83f97716-2513-4914-bb92-b4729ebd39c7`, base pavimento `079ee020-0864-4f46-add4-5273375ce8ff` | 0 | bônus: 7 | João, 14/10 ("vamos fazer"), depois da pesquisa do Zomboid. **Falhou sem cobrar: "Insufficient generations and credits. Generations: 53.0/40.0, Credits: 0.0"** — o tileset não aceita o bônus diário, só as 40 do plano ou crédito (as animações do zumbi aceitaram). Bug reportado pelo `agent_feedback`. Chamada guardada para repetir numa conta nova |
| 14/10 | o chão em tiles no Godot com 8 tilesets **provisórios** de cor chapada (`rua/chao.gd`, `rua/chao_tracado.*`, `rua/arte/chao/`) — nada gerado | — | 0 | bônus: 7 | caminho provado: 274 mil células em 0,6 s, `conferir_zumbi` passa, captura `rua-chao.png` na Área de Trabalho |
| 14/10 | **conta 2** (token de um colega, registrado pelo João no `claude mcp add`): 40 de 40. Os personagens continuam na conta 1 | — | — | conta 2: 40 | a partir daqui o saldo é o da conta 2 |
| 14/10 | **tileset A — grama → pavimento**, mesma chamada de antes, na conta 2 | tileset `c66154b1-813d-47be-8d6c-43ec6924f50a`; base grama `c5fdebd0-6082-44c0-81f7-20d82f356726`, base pavimento `4be01009-c50b-4820-90c2-3dab26f4ea8d` | **4** | conta 2: 36 | **Saiu, 16 tiles certos, mas vivo demais**: grama verde-saturada com fios amarelos e calçada de lajotas azuladas com meio-fio escuro — o "muted desaturated" do prompt não segurou. Caminho: **retoque de paleta de graça** (`pixelart_workbench map_colors`), não regerar; o mesmo mapa de cores vale para os próximos, que herdam a grama pelo `base_tile_id`. Entrou no jogo para teste (captura `rua-chao.png`) |
| 14/10 | tileset A — **retoque de paleta** (`pixelart_workbench map_colors`, 41 cores DE → PARA: grama ao oliva morto, lajotas ao cinza neutro, juntas ao cinza-escuro) | imagem `5029096a-7b7c-4520-b1fa-59b7787ded9b` | 0 | conta 2: 36 | o mapa de cores ficou em `rua/arte/chao/paleta.json`, para os próximos tilesets; o PNG retocado é o que está em `rua/arte/chao/grama-pavimento.png` (o servidor guarda o vivo). Capturas `rua-chao.png` e `rua-chao-zoom.png` na Área de Trabalho; o tileset cru em `tileset-a-vivo-4x.png` |
| 14/10 | **tileset B — pavimento → asfalto**, `lower_base_tile_id` = pavimento do A, "worn dark asphalt road, cracked and faded, dusty, no road markings", transição "low concrete curb edge" 0,25 | tileset `9656dd10-fddc-4eba-aa26-0508db339245`; base asfalto `4821e993-746c-4502-9987-adca331d4f49`; retoque imagem `53c38ccf-661a-492b-89be-b1b7dce3e282` | **3** | conta 2: **33** |
| 14/10 | **João reprovou o chão** ("muito padronizado, chamando muita atenção"). Retoque de paleta **v2** em A e B (contraste baixo: juntas e asfalto a ~23 níveis da lajota) e **variações do tile cheio** no `chao.gd` | imagens `09705604-585b-42d0-bfe8-472b698af95c` (A) e `d0a62082-a142-4134-9a92-24ab469bd0a3` (B) | 0 | conta 2: 33 | ver "Estratégia de chão v2". Figura `chao-v2.png` na Área de Trabalho: antes e depois. **João: "melhorou… tá bem melhor"**; o "risco escuro a cada dois tiles" era o espelho vertical na lajota — piso duro passou a variar só no tom. **"ok, agora dá pra seguir"** |
| 14/10 | **tilesets C a H**, um por chamada, todos com a grama do A como base (`c5fdebd0-…`): C grama → asfalto (asfalto do B como base de cima), D grama → mata, E grama → terra, F grama → milho, G água → grama (água é o terreno de baixo), H grama → horta. Prefixo de fim do mundo, "plain texture with no objects", retoque v2 em cada um | ver linhas abaixo | 3–4 cada | conta 2: 33 antes | autorizado pelo João em 14/10. Resultado por tileset abaixo |
| 14/10 | **C — grama → asfalto**, bases do A e do B, transição "crumbling asphalt edge with dirt and weeds" 0,25 | tileset `67cfdddf-8931-4ac8-b857-441c1125cac9` | 4 | conta 2: 29 | 16 tiles certos, grama e asfalto idênticos aos de A e B. A borda veio malva (15 cores novas, mapeadas para cinza em `paleta.json`, grupo `borda_do_asfalto_na_grama`). Retoque **local** agora (`retocar.gd` no scratchpad, mesma tabela), instalado |
| 14/10 | **D — grama → mata**, base do A, "dark forest floor, packed dead leaves and bare dark soil", transição 0 | tileset `b15b07e7-ace2-4258-9913-de933000fb8e`; base mata `d9b7c9d4-bbd8-4ab8-b629-9d7365f1c376` | 3–4 (o saldo ainda marcava 29 ao registrar) | conta 2: ver abaixo | 16 tiles certos, grama idêntica. O chão de mata veio como **xadrez de blocos marrons sobre roxo** — detalhe dominante, o que os guias mandam evitar. O retoque (grupo `mata`, 18 cores) baixou o contraste dos blocos quase ao do fundo; sobra um mosqueado que as árvores por cima escondem. **Candidato a regerar** com "flat dark soil, scattered dead leaves, low detail, flat shading" se incomodar |
| 14/10 | **E — grama → terra**, base do A, "bare dry dirt, packed dusty brown earth with small cracks", transição 0 | tileset `ea3dc6f1-4d5c-4773-b97a-537452344ab4`; base terra `a508d181-8cb6-4905-9a59-000256502af6` | 3–4 | conta 2: ver abaixo | 16 tiles certos. Veio laranja-saturada com um motivo de rachadura repetido; o retoque (grupo `terra`, 14 cores) leva a marrom empoeirado perto da claridade da grama. Instalado |
| 14/10 | **F — grama → milho**, base do A, "abandoned corn field seen from above, dense withered dry stalks", transição 0,25 | tileset `290fc8c2-35d0-4bb4-8298-733953f33a56`; base milho `0a425c91-4dd7-4d8e-8d82-f919f8285599` | 3–4 | conta 2: ver abaixo | 16 tiles certos: fileiras de pés dourados com sombra roxa entre elas, listrado. 40 e tantas cores novas — aqui entrou a **regra geral** do `paleta.json` (cor desconhecida perde 65 % da saturação e 20 % do valor), que vale para o resto. Instalado |
| 14/10 | **G — água → grama** (a água é o terreno de baixo; a grama do A é a base de cima), "murky stagnant dark water, still and muddy", transição "muddy bank with dead reeds" 0,25 | tileset `a86fb64a-0b44-4a8f-9de8-ad047f381c66`; base água `c943f1db-bd17-4da4-995d-8c29a2caaee3` | 3–4 | conta 2: ver abaixo | 16 tiles certos, grama idêntica. Água pela regra geral (12 mil px). Entrou em `tilesets.json` como `agua-grama` no lugar do provisório `grama-agua` — o `chao.gd` aceita o par nas duas ordens. **A água veio verde-escura mosqueada, mais lago de lodo que água, com uma faixa preta de sombra na margem sul** (a transição 0,25 fez um barranco). Serve para os 950 px² de água do mapa; candidata a regerar com transição 0 e "flat dark water" se o rio ganhar destaque |
| 14/10 | **H — grama → horta**, base do A, "neglected vegetable garden, dry soil furrows in rows with wilted plants", transição 0 | tileset `9c0154ce-3e1f-4511-9c96-ff0d25082011`; base horta `e0350cc9-1501-4dce-8bc6-31aafed23bfe` | — | conta 2: **19** | 16 tiles certos: sulcos de terra cinza-parda com mato, pela regra geral. **Chão completo: os 8 tilesets gerados e no jogo, zero provisórios.** D a H custaram 10 juntos (A 4, B 3, C 4; total 21 das 40). `conferir_zumbi` e `conferir_arma` passam. Figuras `chao-mapa.png` (seis lugares) e `chao-mapa-inteiro.png` na Área de Trabalho |
| 14/10 | **Y-sort** (fase 5) e **prédios como textura** (fase 3): `rua.tscn`, `cenario.gd`, `telhados.gd`, `design/desenhar_texturas.js`, `rua/arte/predios/` — nada gerado | — | 0 | conta 2: 19 | ver "Fase 5 feita" e "Fase 3 feita". `conferir_zumbi` e `conferir_arma` passam. Figuras `ysort.png` e `predios.png` |
| 14/10 | **fase 4, objetos — plano de gasto** (João: "segue"). Os geradores de objeto em 8 e em 1 direção custam **10 a 25 cada** (conferido no esquema), fora de alcance; tudo sai pelo `create_image_pixflux` a **1 por imagem**, fundo transparente, `high top-down`, prefixo de fim do mundo: árvore ×2 (96 px), carro, motorhome, bomba (64 × 112), móveis (pegada + altura). Lata e caixa à mão. | ver linhas abaixo | — | conta 2: 19 antes | resultado por objeto abaixo |
| 14/10 | árvore A (viva): pixflux 96 × 96, seed 14101 → `rua/arte/objetos/arvore-a.png` | `0ccb54a9…` | 1 | conta 2: 18 | boa: copa redonda, tronco e sombra, 64 px de copa; vista inclinada (mostra o tronco), combina com o boneco. Pé do tronco na linha 88 do PNG |
| 14/10 | árvore B (seca): seed 14102 → `arvore-b.png` | `9465d885…` | 1 | conta 2: 17 | boa: galhos nus, 45 px de copa; sai em 1 de cada 3 árvores (`UMA_SECA_A_CADA`). Pé na linha 81 |
| 14/10 | carro com `direction=east`, 192 × 96, seed 14103 | `cd46fe13…` | 1 | conta 2: 16 | **perdida**: veio de LADO (vista lateral em 3/4, só uma tira de teto) — girada 90° numa rua vista de cima fica um carro tombado. Guardada fora do repo (scratchpad `brutos/carro-de-lado.png`) |
| 14/10 | carro com `direction=south` + "seen from above… roof and hood visible", 96 × 200, seed 14104 → `carro-em-pe.png` | `1282f981…` | 1 | conta 2: 15 | **vista pura de cima**, 79 × 178 px opacos na pegada de 80 × 180. Gira ±90° para as ruas leste-oeste e espelha por sorteio da chave: **um sprite serve às 8 direções**. Lição: pedir **sul + "seen from directly above / bird's-eye"**; `east` dá vista lateral |
| 14/10 | motorhome sul, "bird's-eye", 176 × 400, seed 14105 → `motorhome-em-pe.png` | `aebbe3ea…` | 1 | conta 2: 14 | vista pura de cima, teto comprido com escotilha e ar-condicionado, ferrugem; mesmo giro do carro. **Veio com fundo cinza e sombra** apesar do `no_background` → `design/recortar_fundo.gd`. Só 129 × 257 opacos no vão de 170 × 400 (decisão em aberto) |
| 14/10 | mato: "clump of dry overgrown bushes and tall weeds… bird's-eye", 64 × 40, seed 14106 → `mato.png` (João: "pode seguir" com o resto do externo) | `5a2056ad…` | 1 | conta 2: 13 | bom: tufo oliva e marrom com galhos secos, 58 × 35 opacos; `cenario._desenhar_mato` estica ao tamanho sorteado e espelha |
| 14/10 | bomba de combustível: "seen from above at a high angle, top and front face visible, front face at the bottom", 64 × 112, seed 14107 → `bomba.png` | `72078e1a…` | 1 | conta 2: 12 | boa: bomba vermelha desbotada numa ilha de concreto, mangueira pendurada, **vista inclinada** (o estilo que os móveis de dentro teriam). **Mas o mapa não coloca bomba nenhuma**: a ficha existe em `MOVEIS`, e o posto só recebe prateleira, geladeira e caixa dentro — o sprite espera alguém pôr a bomba na frente do posto (proposta abaixo) |
| 14/10 | motorhome v2: "long bus-shaped class A motorhome… fills the entire frame from the top edge to the bottom edge", 176 × 400, seed 14108 → `motorhome-em-pe.png` (João: "pode fazer os dois") | `018ea987…` | 1 | conta 2: 11 | **melhor**: 118 × 344 opacos (v1 tinha 129 × 257), ônibus comprido com escotilhas e ar-condicionado; fundo cinza de novo → `recortar_fundo.gd`. Fica em 1:1 — a pegada de 170 de largura é generosa (um ônibus real tem ~100 px) |
| 14/10 | geladeira: "old kitchen refrigerator with the door closed… top and front face visible, front face at the bottom… fills the frame", 72 × 96, seed 14109 → `geladeira.png` | `8127b7d5…` | 1 | conta 2: 10 | geladeira amarelada com ferrugem, de frente com um pouco de tampo; 46 × 89 opacos |
| 14/10 | armário: "old wooden wardrobe with two doors, one door slightly ajar", 104 × 96, seed 14110 → `armario.png` | `6152b090…` | 1 | conta 2: 9 | guarda-roupa escuro de frente, 60 × 96 opacos (mais estreito que a pegada de 102, folga dos lados) |
| 14/10 | cômoda: "low wooden dresser with three drawers, one drawer half open", 88 × 72, seed 14111 → `comoda.png` | `71f72235…` | 1 | conta 2: 8 | boa, 64 × 51 opacos, tampo visível |
| 14/10 | estante: "tall wooden bookshelf with a few old books and junk", 112 × 96, seed 14112 → `estante.png` | `0725700d…` | 1 | conta 2: 7 | boa, livros e um vidro no chão; 57 × 83 opacos (metade da pegada de 112 — o gerador faz estante alta, não larga) |
| 14/10 | prateleira: "long metal store shelving unit, mostly empty, a few dusty cans and boxes", 160 × 96, seed 14113 → `prateleira.png` | `64ab14cf…` | 1 | conta 2: 6 | boa, latas e caixas nas prateleiras; 108 × 84 opacos |
| 14/10 | arquivo: "grey metal filing cabinet with four drawers, one drawer open with papers", 88 × 88, seed 14114 → `arquivo.png` | `0fa21eb5…` | 1 | conta 2: 5 | bom, gaveta aberta com papéis; 49 × 66 opacos |
| 14/10 | maca: "hospital gurney stretcher with a dirty stained mattress and metal side rails", 96 × 64, seed 14115 → `maca.png` | `2d7fa170…` | 1 | conta 2: 4 | boa, em 3/4; 51 × 42 opacos |
| 14/10 | armário de metal: "plain grey steel locker cabinet with two doors and a hanging padlock… neutral light grey", 88 × 96, seed 14116 → `armario-de-metal.png` (partilhado por armas, remédios, seringas e bombeiro, tingido pela cor da ficha) | `b1dc251c…` | 1 | conta 2: **3** (o servidor diz 37 de 40 usadas) | cinza neutro, bom de tingir |
| 15/10 | **mata v2, conta 2** (3 gerações lá; o `pixellab` do `~/.claude.json` apontado para o token da conta 2 só para isto — o `/mcp` reconecta, servidor novo não aparece sem reiniciar): `create_topdown_tileset` 32 px, grama = `lower_base_tile_id` c5fdebd0… (a mesma de A–H), mata = "soft uneven carpet of dead brown leaves, pine needles, twigs and patches of bare dark soil, irregular organic mottling with no repeating pattern, no grid, no blocks", guidance 10 | `72e153ab-49ef-464d-8f1f-baa5857ce35c` (tile cheio da mata: `baaa77fd…`) | **2** | conta 2: **1** | **boa**: manchas orgânicas sem xadrez, borda com tufos de capim. Veio ROXA (o gerador pinta "forest floor" de violeta); `design/paleta_de_classe.js` (o antigo `paleta_da_agua.js`, generalizado) gravou o grupo `mata_v2` na paleta — matiz 28°, saturação 0,22, valor 0,12 + 0,6 × original — e o retoque a deixou marrom-cinza escuro. Entrou no lugar de D: `grama-mata.png/.json` trocados, `tilesets.json` guarda o id antigo em `pixellab_v1`, `cheio-mata.png` refeito. Os bosques (`_plantar_arvores`) e o mato não mudam |
| 15/10 | **Capa do menu** (João: "tira essa chamada, deixa só o título, cria uma capa com uma arte mais estilizada, mais bonita, que nem um jogo mesmo, procura menus de jogos de zumbi pra pegar inspiração"). Referência levantada: fundo pintado simples e misterioso, faixa escura atrás dos botões, sem fonte de sangue, uma só luz quente. Cena proposta: rua da cidade à noite, a casa escura com UMA janela de porão acesa e a silhueta dela olhando, ele de capuz e mochila de costas indo para a rua com a pistola, zumbis ao longe sob um poste quebrado. `create_image_pixflux` 320 × 180 (×4 = 1280 × 720, pixel inteiro), vista lateral, sem contorno, fundo cheio. Fonte do título: Creepster (OFL, Google Fonts) em `arte/titulo/` | `5b25c2c9…`, seed 14120 → `arte/titulo/capa.png` | 1 | conta 3: 27,5 | **boa de primeira**: rua à noite azul-cinza, a casa com janelas acesas (várias, não só a do porão — o pedido de "uma janela" não pegou, mas a casa acesa lê como "a casa dele"), a silhueta dela numa janela, ele de capuz e mochila de costas com a pistola, zumbis ao longe sob o poste. Entra ×4 (nearest) cobrindo a tela; faixa escura a 72 % atrás dos botões; título em Creepster 68 com contorno e sombra. Chamada removida. **João aprovou** ("top, ficou ótima a capa") |
| 15/10 | **Trator da fazenda** (João: "sim" ao sprite; o veículo ganhou nome pelos prints do Canva): pixflux 80 × 120, vista pura de cima como o carro, `direction=south`, "old farm tractor… big rear wheels, small front wheels, faded red paint with rust", para a pegada em pé de 70 × 110 → `rua/arte/objetos/trator-em-pe.png` | `c4a0b80f…`, seed 14121 | 1 | conta 3: 26,5 | bom de primeira: vista pura de cima, rodas grandes atrás e pequenas na frente (frente para baixo = sul), vermelho desbotado com ferrugem, 63 × 98 opacos. Entra pelo mesmo mecanismo do carro (gira ±90° se deitado). Figura `trator.png` no Desktop |
| 15/10 | **Caminhonete** (João: "segue, e com o 2 também"): as duas do desenho (fazenda e galpão do velho louco) eram pequenas demais para o traçador; o mínimo baixa e elas ganham tipo próprio. Sprite pixflux 96 × 208, vista pura de cima, `direction=south`, "old pickup truck… open cargo bed" → `rua/arte/objetos/caminhonete-em-pe.png`; ficha `caminhonete` 200 × 84 (proposta) | `2eaa9007…`, seed 14122 | 1 | conta 3: 25,5 | boa de primeira: picape azul desbotada de cima, caçamba aberta com tralha e lona, 80 × 186 opacos. O traçador passou a poupar veículo do filtro de traço fino (`apagarFinos`) — as duas caminhonetes apareceram, e mais cinco carros pequenos que o filtro comia (96 veículos) |
| 15/10 | **Conta 3** (token novo do João, 14/10 à noite; o da conta 2 guardado em `~/.pixellab.json`): 40 + 10 de bônus, sem personagem. Plano aprovado ("pode seguir"): importar jogador e zumbi (v3 com as 8 rotações dos pacotes do Desktop = 0,25 cada), `dano` do zumbi (`taking-punch`, 8 direções, 8–16), `atirar` do jogador (v3, 4–6 quadros, sul primeiro, 16–24). Mata na conta 2 se couber em 3 | — | — | conta 3: 40 + 10 | linhas abaixo |
| 15/10 | importação do **jogador v1** na conta 3: `create_character` v3 com as 8 rotações do pacote do Desktop (`Idle/rotations/*.png`, 112 × 112, subidas por `get_upload_url` + curl) | `546ba83f-6223-48df-b488-78903f96d58f` | 0,25 | conta 3: 39,75 | as 8 direções entraram iguais às nossas; nada gerado. Os uploads valem 3 dias |
| 15/10 | importação do **zumbi v1** na conta 3, mesmo jeito | `beee89fc-7c05-491e-9057-d4ade71a958b` | 0,25 | conta 3: 39,5 | as 8 direções iguais às nossas |
| 15/10 | **`dano` do zumbi** = template `taking-punch`, **uma direção por chamada** (a conta grátis só roda 1 job; pedir 8 de uma vez é recusado), grupo `3287d698…`, nome `dano`; sul, leste, norte, oeste, depois as diagonais | jobs `45461bbc…` (S), `423de9a9…` (L), `84773866…` (N)… | 1 por direção (cobrou 1, não 2) | conta 3: 31,5 | **8 direções prontas** (sul conferido na tira: recua, cabeça vai para trás e volta, 6 quadros, cara igual; 2 a 5 min cada, o servidor oscila). Folha nova só tem rotações + dano; `design/juntar_folha.js` juntou as 8 linhas na folha antiga de `rua/arte/zumbi/` (vagar, toque, morrer continuam da conta 1). O `zumbi._sofrer` já pedia `tocar("dano")` — entrou sem mexer em código |
| 15/10 | **`atirar` do jogador, teste no sul**: v3 custom, 6 quadros sem o quadro de referência, "both arms raised and extended straight forward at chest height with the hands together, a quick sharp recoil jolt back toward the shoulders, then the arms return forward" (sem arma no desenho: a arma na mão é sprite à parte), grupo `b9399029…` | `379b3b7d…` | 2 | conta 3: 29,5 | **reprovado**: no sul, "braços para a frente" virou braços abertos para os lados (pose de polichinelo), porque para a frente na vista de cima é para a câmera e o modelo não encurta o braço. 2 gerações perdidas; grupo apagado. Lição: para pose de braço na vista de cima, template antes de v3 |
| 15/10 | `atirar` teste 2 no sul: template **`lead-jab`** (soco direto com um braço, vai e volta = recuo do tiro; a arma fica na mão da frente pelo `rua/arma.gd`) | `3bacb472…`, grupo `ef9669f0…` | 1 | conta 3: 28,5 | **reprovado**: 3 quadros de guarda de boxe com o corpo virado de lado e um pé à frente; o braço que soca vai para a câmera e some. Entraria no jogo como um pulo de pose por 3 quadros, pior que o recuo de código. Grupo apagado. **Parei o `atirar` aqui**: 3 gerações nos dois testes, nenhum serve, e o problema é da vista (para a frente = para a câmera no sul). O recuo de código fica. Figuras no Desktop: `jogador-atirar-teste-v3-reprovado.png`, `jogador-atirar-teste-jab-reprovado.png` |
| 16/10 | **quarto macabro, tentativa 1** — `edit_image_pixen` sobre `quarto_sujo.png` reduzido à grade (208 × 156), seed 16101: "Make this dark bedroom macabre and wrecked, as if a zombie lives here. Destroy the bed: mattress torn open and sagging, sheets ripped and dragged half onto the floor, pillows shredded. A heavy rusty iron chain bolted to the dark wooden headboard panel, hanging down onto the bed. The small white nightstand left of the bed knocked over on its side. Keep the headboard panel and the small crucifix on it. Keep the camera angle, walls, window, lighting and colors the same." Do resultado, só cama + painel entram (máscara local) | job `63d432dc-09d1-499e-b03e-7fb41b79fabc`, asset `d7a9d28a…` | 1 | conta 3: 24,5 | **Saiu**: duas correntes grossas do alto do painel até a cama, crucifixo mantido (mais legível), colchão rasgado com buracos, lençol arrastado até o chão, papéis no chão. **O criado-mudo da esquerda não virou.** O gerado vem mais claro e "limpo" (traço de pixel art, sem grão): `compor.js` acerta o tom pelo que não mudou (O ≈ 0,87–0,96 × G + 8–11), cola só o pixel que difere e devolve o grão da foto. O criado-mudo da direita fica fora (o gerador comeu o ventilador) |
| 16/10 | **quarto macabro, tentativa 2 — só o criado-mudo da esquerda**: `edit_image_pixen` num recorte de 72 × 64 (x 4–76, y 64–128 da grade) da composição da tentativa 1, seed 16102: "Knock the small white bedside nightstand over: it lies tipped on its side on the floor, its drawer fallen out and open, small objects spilled on the floor. Keep everything else exactly the same: the wall, the edge of the bed and sheets, the floor, the lighting and the colors." | job `d6537450-d3d5-415d-9d67-15f7442486ba`, asset `62f78f0a…` | 1 | conta 3: **23,5** | **Descartada**: o móvel saiu inclinado (não deitado), com a gaveta caída, mas o recorte inteiro foi redesenhado — parede chapada, o rack escuro e a planta sumiram — e o móvel veio limpo e claro, em traço de desenho; colado na foto vira adesivo. O criado-mudo fica de pé na versão mostrada ao João. Na foto ele é uma caixa de baixo contraste, meio coberta pelo rack e pelo lençol, e no filtro da casa quase some |
| 16/10 | **sujeira do quarto em código** (`sujar.js` no scratchpad, semente 16100, sobre a composição da tentativa 1): escurece 14 % no meio e 30 % nos cantos com 25 % menos cor; mofo cinza do teto e dos cantos (ruído); manchas de sangue velho na cama e no chão e de infiltração no teto; respingos com escorrido; arranhões de unha (claros no painel, fora das correntes e do crucifixo; escuros na parede); quatro marcas de mão de ~8 × 10 da grade, duas arrastadas. Ampliado ×7 bloco a bloco com as fronteiras da foto → 1448 × 1086 | — | 0 | conta 3: 23,5 | **João aprovou, 16/10** ("aprovado, criado-mudo de pé"), depois de ver `teste-0-pixellab/quarto-macabro.png` e `quarto-macabro-comparar.png`. No repo: `design/casa-equipe/quarto_colado.png` (a grade com o gerado colado), `design/sujar_quarto.js` → `quarto_macabro.png` (refaz byte a byte), e no jogo `casa/arte/quarto.png` |

**`atirar`, o que ainda dá para tentar (decisão do João, nada gerado):** v3
com um pedido diferente por direção — no leste/oeste "arms straight out to
the side he faces" (de perfil o braço aparece inteiro, deve sair bem), no
norte "arms forward, away from the viewer" (some atrás do corpo, tanto faz),
no sul "arms low in front, hands together at the belt" (para a câmera, o
braço encurta). 2 por direção, 16 nas oito, com risco de o sul reprovar de
novo. Ou aceitar o recuo de código, que já existe e lê bem porque a arma
na mão é sprite à parte e aponta para onde ele olha.

**15/10, João: "arruma a mata e a água; as ruas na diagonal estão todas
tortas; tem grama em lugares que não deveria — sempre onde tem um carro
parado tem grama em volta; o chão virou uma mistura aleatória de calçada e
grama".** Diagnóstico e o que mudou:

- **Grama embaixo de todo carro.** O azul do carro no desenho abria um furo
  no polígono de pavimento, e furo sem classe vira grama: 71 dos 89 veículos
  estavam num furo. `design/tracar_desenho.js` ganhou `preencherVeiculos`:
  o chão é traçado numa cópia em que o pixel de veículo recebe a classe
  mais comum em volta (de fora para dentro). Veículos e prédios continuam
  saindo da classificação como está — mesmos 89 veículos, mesmos 60
  prédios, byte a byte.
- **Diagonais em escada.** Dois motivos somados: o desenho é pixel a pixel
  (1 px = 24 px de mundo) e a tolerância de 0,75 px não alisava a escada
  (os polígonos de rua tinham 4.292 segmentos de 3,8 px em média, quase
  todos a 0° e 90°); e em tile de 32 px o Wang de quatro cantos só sabe
  reta e quina, então toda diagonal vira escada com bolinha. Saída em duas
  partes: (1) `TOLERANCIA_DO_TRACO_RETO` = 1,6 px para pavimento, asfalto
  e gramado (352 segmentos de 40 px; a diagonal mais longa tem 98 px do
  desenho = 2.350 px de mundo); mata, terra, milho, água e horta continuam
  no traço fino. (2) **Calçada e rua saem do TileMap** (`rasterizar_chao.js`
  não as rasteriza mais; por baixo fica grama) e viram **polígonos com
  textura** em `rua/ruas.gd`, um nó novo antes do Cenario: cada polígono é
  pintado com o ladrilho do tile cheio (`design/ladrilhar_cheio.gd` →
  `rua/arte/chao/cheio-<classe>.png`, 256 × 256 com as mesmas variações do
  chao.gd, para a grade não aparecer) e um meio-fio escuro de 2 px na
  borda. Do maior para o menor: as ruas, depois qualquer polígono de chão
  cujo centro caia dentro de uma rua (o lote de grama no meio do bairro),
  com o ladrilho da classe dele. Furos não se recortam: o que está num furo
  é lote (pintado por cima), prédio (coberto) ou carro (tampado no traço).
- **Consequência honesta:** os tilesets A (grama→pavimento), B
  (pavimento→asfalto) e C (grama→asfalto) — 11 gerações — não aparecem
  mais; só o tile cheio deles vive, no ladrilho. A borda da rua é reta com
  meio-fio, como na vida real; a borda em curva do tile fica para o que é
  natural.
- **Tinta do lote** baixou de 30 % para 15 %: sobre a calçada em textura
  virava mancha escura.
- `conferir_mapa`, `conferir_construcao`, `conferir_fim` e `conferir_zumbi`
  passam. Figuras `ruas.png` (diagonal, bairro a 0,5×, carro na rua,
  camping) e `ruas-mapa-inteiro.png` na Área de Trabalho.
- **Água, feita sem gerar.** O bruto do PixelLab (baixado da conta 2 por
  curl, `/mcp/tilesets/a86fb64a…/image?inline=true`) já era verde-escuro
  com uma faixa quase preta sob o barranco — o gerador entendeu "água
  parada" como lodo —, e a regra geral piorava. `design/paleta_da_agua.js`
  lê o bruto e grava o grupo `agua` em `paleta.json`: toda cor do tile
  cheio de baixo e todo verde escuro fora das tabelas vira azul-cinza
  parado (matiz 200°, saturação 0,28, valor 0,24 + 0,5 × original — a
  faixa preta clareia); o barranco areia fica para a regra geral e vira
  lama. Retoque refeito do bruto; figura `agua.png` no Desktop. A mata (xadrez de blocos) precisa de
  tileset novo: **conta 2 registrada como segundo servidor
  (`pixellab-conta2`)** no `~/.claude.json`, para gerar com a grama de
  referência de lá sem trocar token; 3 gerações, um tileset custa 1 a 4.

**João, 15/10: "ok, faz o recuo em código então."** Decidido: `atirar` é
código, definitivo. O recuo já existia (passo de 2 px em 0,08 s); ficou
`RECUO + coice da arma` (Beretta 5 px, Doze 8 px) voltando em 0,1 s com
ease-out, em `rua/jogador.gd`. O clarão do cano e o coice da arma na mão
continuam em `rua/arma.gd`. Nada gerado. **Saiu, 16 tiles certos, calçada idêntica à do A** (o `base_tile_id` funciona). O asfalto veio **chapado, violeta-escuro, sem textura**, e o meio-fio esverdeado; o mesmo retoque de paleta (mais 4 cores novas em `paleta.json`) leva o asfalto a cinza-escuro neutro — lê como asfalto gasto, no estilo chapado do Zomboid |

**Lição de 30/09:** a conta de teste **não tem vaga garantida** — em hora de
pico o servidor recusa a camada gratuita, e o `v3` recusa com uma mensagem
enganosa ("try a lower frame_count"). Quando uma chamada falha na hora e sem
cobrar, olhar o `get_character` de um personagem recém-criado, que é onde o
motivo aparece por extenso. Crédito pago (US$ 1 = 1) é o que furaria a fila
nesses horários — decisão de mesa, ver "O que custa".
