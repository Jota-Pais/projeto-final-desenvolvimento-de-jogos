# Brief — one-pager do High Concept

Instruções para quem for **desenhar a peça de entrega**. O que está escrito aqui
pode ser diagramado como está; o que está marcado com ⬜ **a equipe precisa
preencher antes de entregar**.

A fonte completa do projeto é [`high-concept.md`](high-concept.md). Este arquivo
é só o recorte que vai para a peça.

## Regras que não se negociam

- **Prazo: 09/09/2026, 23h59.** A tarefa no AVA (*High Concept do Jogo
  Completo*, aberta desde 12/08) tem duas questões: a primeira, peso 1%, é só
  **os nomes dos integrantes com sobrenome** — o professor pede sobrenome porque
  há nomes iguais na turma. A segunda, peso **99%**, é a peça.
- **Formato visual é eliminatório.** O professor zera o High Concept entregue
  como documento de texto formal. O campo do AVA aceita DOC, mas isso é só o
  formato do upload — não é licença para entregar texto corrido.
- **Como enviar:** arquivo, ou **link** de Drive, Figma ou similar. Se for link,
  ele tem que ir **dentro de um arquivo `.txt`**. Se precisar compactar, usar
  **RAR** — o professor avisa que zip costuma dar problema no AVA.
- **Uma página só.** PDF é o formato seguro.
- **Paisagem, larga.** O exemplo que o professor deu como formato certo
  (`exemplo-high-concept-sunny-fox.pdf`) tem 5125 × 3195 pt — proporção ≈ 16:10.
  É um mural, não um A4.
- A peça tem que trazer **o nome de todos**, a turma (**quarta**) e o curso.

## Como a peça é avaliada

| Critério | Peso |
|---|---|
| Formato visual | **eliminatório** |
| Cumpre os tópicos | 2 |
| Linguagem clara e objetiva | 4 |
| Apresentação organizada | 2 |
| Compreensível por artista, programador, game designer, narrative designer e produtor | 2 |

O peso maior é **clareza**, não beleza. Texto curto, blocos bem separados, nada
de parágrafo corrido.

## Referência de estrutura

O exemplo aprovado pelo professor é um mural denso, dividido em blocos pequenos,
com pouquíssimo texto em cada um. Ele usa: título e ficha rápida, descrição de
duas linhas, lore, equipe com funções, barras de progresso do desenvolvimento,
cronograma em linha do tempo, custos, público-alvo, diferenciais, mecânicas como
**lista de verbos**, características, referências e gêneros como **nuvem de
tags**. Nenhum parágrafo passa de quatro linhas.

## Layout proposto

Bandas horizontais, e no meio o coração da peça: os dois modos lado a lado. A
divisão visual **é** o conceito do jogo — quem bater o olho tem que entender na
hora que são dois jogos que se alternam.

```
+---------------------------------------------------------------------------+
|  [TITULO GRANDE]                        |                                  |
|  tagline de uma linha                   |   KEY ART                        |
|  1 jogador . PC e navegador . 16 anos   |   (rua a esquerda, casa a        |
|  -------------------------------------  |    direita, no mesmo quadro)     |
|  pitch de duas linhas                   |                                  |
+--------------------------+--------------+----------------------------------+
|                          |                        |                        |
|   RUA - o gameplay       |   (ciclo)              |   CASA - a narrativa   |
|   frio, pixel art        |   cada dia alterna     |   quente, detalhado    |
|                          |   os dois modos        |                        |
|   . top-down pixelado    |                        |   . ponto e clique     |
|   . hordas e esquiva     |   o que voce arrisca   |   . cuidar dela        |
|   . vasculhar casas      |   na RUA destrava a    |   . montar a pesquisa  |
|   . comida, agua,        |   historia na CASA     |   . a historia avanca  |
|     suprimentos,         |                        |     com o que voce     |
|     documentos           |                        |     trouxe             |
+--------------------------+------------------------+------------------------+
|  PROGRESSAO - linha do tempo em dias, com o prazo e dois desfechos          |
|  -- dia 1 ----------- dia N ------+-- VITORIA: a cura fica pronta           |
|                                   +-- DERROTA: o "final feliz" em parodia   |
+------------+------------+------------+------------+------------+-----------+
| CORE       | MECANICAS  | DIFEREN-   | GENEROS +  | PUBLICO    | EQUIPE    |
| MECHANIC   | (verbos)   | CIAIS      | REFERENCIAS| ALVO       | + FUNCOES |
|            |            |            | (tags)     |            |           |
+------------+------------+------------+------------+------------+-----------+
| CRONOGRAMA (marcos em linha)          | ORCAMENTO (numero grande)          |
+---------------------------------------+------------------------------------+
```

## O conteúdo, bloco a bloco

Tudo que não está marcado com ⬜ pode ser diagramado como está.

### Título e tagline

# Você me amaria se eu fosse um zumbi?

⚠️ Título **provisório** — a equipe pode trocar, e aí a peça muda junto.

Tagline, embaixo do título:

> *Ela perguntou antes. Agora você tem dias para responder.*

O título é uma pergunta, e é o melhor ativo da peça: já entrega tom, premissa e
o deboche do final, tudo em uma linha. O designer deve tratá-lo como imagem, não
como texto — é ele que ocupa o maior espaço do mural.

### Pitch — o texto de entrada da peça, duas linhas

> Sobrevivência zumbi em dois modos que se alternam a cada dia: você vasculha a
> rua atrás de recursos e respostas, e volta para casa para trabalhar na cura da
> namorada — que está trancada no porão, e já não é mais ela.

### Lore — quatro linhas no máximo

> Ela foi mordida. Em vez de abandoná-la, ele a trancou no porão e passou a sair
> todo dia às ruas atrás dos recursos e do conhecimento necessários para
> desenvolver uma cura. O processo é lento e imperfeito, e cada tentativa exige
> mais do mundo lá fora.

### Rua — o gameplay

Top-down pixelado. Hordas e esquiva, com exploração no espírito de *Project
Zomboid* e campo de visão e ritmo mais próximos de *Vampire Survivors*.
Vasculhar casas atrás de comida, água, suprimentos e **documentos** — que
revelam a origem do apocalipse e dão pistas da cura. É onde o jogador passa a
maior parte do tempo.

**Controles:** `WASD` ou setas para andar · mouse para mirar e interagir ·
`E` para vasculhar · `Shift` para correr.

### Casa — a narrativa

Ponto e clique, arte detalhada, tom enigmático — contraste proposital com a
simplicidade da rua. Cuidar dela e montar a pesquisa com o que foi trazido de
fora.

**Controles:** mouse, só. Clique para andar, examinar e combinar itens.

### O ciclo — o texto que fica entre as duas colunas

> A rua é o gameplay. A casa é a história. **O que você arrisca lá fora é o que
> destrava o que acontece aqui dentro.**

### Objetivos

**Principal** — completar a cura antes do prazo.

**Secundários:**

- Descobrir a origem do apocalipse pelos documentos espalhados na rua
- Manter ela estável: quanto pior o estado dela, menos tempo sobra
- Equipar a casa e o laboratório para acelerar as tentativas de cura
- Sobreviver mais um dia com menos dano do que no anterior

### Progressão e finais

- O tempo é contado em **dias**, e há um **prazo** para completar a cura.
- Cada dia é uma **fase**, sempre nos mesmos lugares — a geografia é fixa e o
  que muda é o estado do mundo, que vai ficando mais apocalíptico.
- **Vitória:** a cura fica pronta a tempo, ela volta a ser humana, e os dois
  seguem sobrevivendo juntos.
- **Derrota:** o prazo se esgota, ela escapa do porão, morde o protagonista, e
  os dois viram zumbis. A tela de fim mostra isso **em tom de paródia**, como o
  final feliz de um casal — mas é o game over.

O bloco da derrota é o melhor momento da peça e merece tratamento visual
próprio: o "final feliz" com moldura de retrato de casal, e o deboche na
entrelinha. É a resposta da pergunta do título.

### Core mechanic — bloco destacado, uma frase

> **Vasculhar sob pressão.** Combate, fome, tempo e escuridão são variações de
> pressão em cima da mesma ação.

### Mecânicas — lista de verbos, sem frase

vasculhar · esquivar · lutar · coletar · investigar · cuidar · combinar ·
sobreviver

### Diferenciais — três bullets curtos

1. **Dois jogos em um** — ação top-down e aventura ponto e clique se alternando
   a cada dia, com arte e ritmo propositalmente diferentes.
2. **O game over vestido de final feliz** — a derrota é apresentada em paródia,
   como o desfecho romântico de um casal.
3. **Risco compra história** — o quanto se arrisca na rua é literalmente quanta
   narrativa se destrava em casa.

### Ficha rápida — a linha embaixo do título

| Campo | Conteúdo |
|---|---|
| Jogadores | 1 jogador, offline |
| Plataformas | PC (Windows) e navegador — o Godot exporta para web |
| Classificação | 16 anos — violência e tema |
| Gêneros | survival horror narrativo · ação top-down · aventura ponto e clique · pixel art |

Tudo nesta tabela é **proposta minha**, coerente com o que já foi decidido, e a
equipe pode trocar qualquer linha. Nenhuma delas foi discutida em grupo.

### Concorrentes e referências — nuvem de tags, em dois grupos

O tópico 9 pede concorrentes **de escopo similar ao do projeto**, então vale
separar quem é comparável de quem é só inspiração.

**Concorrentes — escopo parecido, time pequeno:**

`Papers, Please` — loop mecânico simples carregando peso narrativo, feito
praticamente por uma pessoa · `60 Seconds!` — vasculhar sob pressão e depois
administrar o abrigo, que é literalmente a nossa estrutura de dois modos ·
`Darkwood` — top-down de horror com dia de exploração e noite de sobrevivência

**Referências de estrutura e de público, escopo maior:**

`This War of Mine` — o parente mais próximo: sai para vasculhar, volta para
administrar a casa · `Inscryption` — a referência de **público**, não de gênero ·
`Project Zomboid` — a sensação de exploração · `Vampire Survivors` — o ritmo de
horda

⬜ **Falta o benchmarking numérico.** O professor indica
<https://steamdb.info/sales/>, <https://steamspy.com/> e
<https://games-stats.com/> para levantar preço, número de avaliações e vendas.
Isso é pesquisa de meia hora que ninguém fez ainda.

### Público-alvo

**Demografia** — 18 a 30 anos, joga em PC, compra na Steam, não precisa de
máquina forte. Renda média, brasileiro e internacional.

**Psicografia** — na taxonomia que o professor usa no exemplo, é o perfil
**explorador**: joga para entender o sistema, não para vencer os outros. Gosta
de descobrir a regra escondida, testar o limite da mecânica e otimizar — mas o
que faz terminar o jogo é a história. **Não é try-hard:** não liga para
ranking, dificuldade máxima nem platinar.

**Proto-persona**

> **Marina, 24 anos, estudante de design e estagiária.**
> Joga de 4 a 6 horas por semana, quase sempre à noite, sozinha, no notebook.
> A biblioteca dela é quase toda indie, e o último jogo que comprou foi na
> promoção, depois de ver um vídeo-ensaio no YouTube.
>
> **Como aprende:** lendo a mecânica jogando. Odeia tutorial longo — prefere
> descobrir errando.
> **Como joga:** sessões de 45 min a 1h30. Jogo ideal termina em 8 a 12 horas.
> **O que ela quer:** um sistema que dê para entender e otimizar, dentro de uma
> história que tenha algo a dizer. Adorou *Inscryption* exatamente por isso.
> **O que a afasta:** grind, tutorial arrastado e jogo que promete história e
> entrega só sistema — ou o contrário.
> **Onde descobre jogo:** YouTube, Steam Next Fest e indicação de amigo.

### Equipe e funções

| Integrante | Frente | Função |
|---|---|---|
| João Carlos Pais | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |

Quatro pessoas, **metade em cada frente** — dois na rua, dois na casa.
⬜ Faltam três nomes **com sobrenome** (o professor pede por causa de nomes
repetidos na turma) e as funções de cada um: artista, programador, game
designer, sound designer, narrative designer. Uma pessoa pode acumular.

Estes mesmos nomes são a **questão 1 da tarefa no AVA**.

### Cronograma

`09/09 High Concept` · `30/09 Alfa + prévia do GDD` · `11/11 Beta + GDD final` ·
`02/12 Gold + pitch`

⬜ O encaixe de Alfa, Beta, GDD e Gold nas duas etapas de andamento é dedução
minha a partir do plano de ensino. O `prazosAtividades(turma)` do AVA tem as
datas reais e resolveria isso — continua sem baixar.

### Orçamento

**R$ 1.500** — 5 encontros dedicados ao projeto × 3h × R$ 100/hora.

É orçamento **simulado**: o High Concept é documento de pitch, e pitch tem linha
de custo. O que se precifica é o trabalho da equipe como se fosse pago. O texto
do modelo é este:

> *"Qual o orçamento previsto para o projeto? Quanto vai custar o jogo?
> Simplifiquem aqui, considerando os dias de aula dedicados ao projeto final ×
> R$ 100,00 × 3 (cada aula tem 3 horas de duração)"*

**A conta tem que aparecer na peça**, não só o total — é o que torna o número
defensável. Os 5 encontros são os marcados como projeto no plano de ensino:
23/09, 30/09, 04/11, 11/11 e 25/11.

⬜ A única dúvida que sobra é **quais dias contam**. Se a equipe entender que
todos os encontros do High Concept até a Gold são dedicados ao projeto, são 12
aulas e o número vira R$ 3.600. A fórmula não multiplica por número de
integrantes — o professor pede simplificação, então não vale inventar fator que
ele não escreveu. O exemplo dele chega a R$ 18.000 por outra conta (100 horas ×
R$ 150 + R$ 3.000 de assets), que é o custo real de produção e não a fórmula
simplificada.

### Protótipo — desenho de uma tela de gameplay

⬜ **Falta desenhar.** O tópico 14 pede a versão alfa mais um desenho de tela.
A alfa é outra entrega; o desenho é desta. O que a tela precisa mostrar:

- Vista **top-down**, personagem no centro, rua com casas dos dois lados
- Alguns zumbis se aproximando de direções diferentes
- **HUD:** dia atual e quanto falta para o prazo · vida · fome/água ·
  espaço da mochila
- Uma casa com a porta destacada, indicando que dá para entrar e vasculhar
- Um documento no chão, com brilho, diferente dos outros itens

Rabisco serve — o professor aceita desenho de conceito. O que não pode é o bloco
ficar vazio.

## Direção de arte

O conceito visual da peça é um só: **frio contra quente, simples contra
detalhado**. A peça tem que passar essa sensação antes de qualquer texto ser
lido.

- **Rua** — cinza-esverdeado dessaturado, concreto, ferrugem, céu lavado. Pixel
  art, poucos pixels, sombra dura.
- **Casa** — âmbar de vela, madeira, um vermelho contido. Ilustração detalhada,
  luz suave, textura.
- **A costura entre as duas** — o elemento de ciclo (seta, engrenagem, relógio
  de dia) fica exatamente na divisa e usa as duas cores.
- **Tipografia** — título com peso e presença; corpo em sans de alta
  legibilidade. **Nada de fonte de terror pingando sangue**: o critério de maior
  peso é linguagem clara, e fonte decorativa derruba isso.
- **Densidade** — como no exemplo do professor: muitos blocos pequenos, cada um
  com título curto e no máximo quatro linhas de conteúdo.

## O que não fazer

- Nada que pareça documento de texto — é o item que zera.
- Nada de parágrafo longo. Se um bloco passa de quatro linhas, vira bullet ou
  tag.
- Nada de fonte decorativa ilegível "porque é jogo de terror".
- Não inventar conteúdo para preencher os ⬜. Bloco vazio é problema da equipe
  resolver, não do designer preencher.

## Checklist antes de entregar

- [x] Título definido e no topo da peça — provisório, mas serve
- [ ] Os 14 tópicos aparecem — nenhum bloco em branco
- [ ] Nome de todos os integrantes, turma (quarta) e curso na peça
- [ ] Uma página, PDF, paisagem
- [ ] Não parece documento de texto
- [ ] Um desenho de tela de gameplay incluído (tópico 14)
