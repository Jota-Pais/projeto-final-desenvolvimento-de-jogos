# Brief de design — one-pager do High Concept

**Você me amaria se eu fosse um zumbi?** · Projeto Final da disciplina de
Desenvolvimento de Jogos · Engenharia de Software, SATC 2026.2 · Turma de quarta

Este documento é autossuficiente: tudo o que você precisa para produzir a peça
está aqui — o texto final, o layout, a direção de arte e os critérios pelos
quais ela vai ser avaliada. Quatro campos ainda não chegaram e estão marcados
como ⬜; eles são enviados depois e não bloqueiam o resto.

---

## 1. O que você vai produzir

Um **one-pager visual** que apresenta um jogo digital. É a primeira entrega
avaliada de um projeto de faculdade e vale 10% da nota final da disciplina.

- **Peça:** uma página, formato paisagem
- **Entrega:** PDF, ou link de Figma/Canva/Drive
- **Prazo:** 09/09/2026, 23h59

O público da peça é o professor da disciplina, que vai avaliá-la segundo
critérios fixos, e uma banca imaginária de investidores — o mesmo material
alimenta um pitch mais adiante no semestre.

## 2. A regra que zera o trabalho

> **A peça não pode parecer um documento de texto formal.**

Este é um critério **eliminatório** no gabarito do professor: High Concept
entregue em formato de documento de texto **zera o trabalho**, por melhor que
seja o conteúdo. Nada de Word, Docs, relatório, capa com título centralizado ou
parágrafos empilhados.

O que ele pede é um **mural visual**: blocos, ícones, tabelas curtas, nuvens de
tags, linha do tempo, imagens.

## 3. Especificação da peça

| Item | Valor |
|---|---|
| Orientação | Paisagem |
| Proporção | ≈ 16:10 |
| Referência de tamanho | 5125 × 3195 pt — as medidas da peça que o professor deu como exemplo aprovado |
| Páginas | 1 |
| Formato final | PDF (ou link editável) |

A peça precisa trazer, em algum canto legível: **os nomes completos dos quatro
integrantes**, a **turma (quarta)** e o **curso (Engenharia de Software)**.

## 4. Como a peça é avaliada

| Critério | Peso |
|---|---|
| Formato visual, não documento de texto | **eliminatório** |
| Cumpre todos os tópicos exigidos | 2 |
| Linguagem clara e objetiva | 4 |
| Apresentação organizada | 2 |
| Compreensível por perfis diferentes — artista, programador, game designer, narrative designer, produtor | 2 |

**O peso maior é clareza, não beleza.** Uma peça bonita e confusa perde para uma
peça simples e legível. Isso deve guiar toda decisão de tipografia, densidade e
hierarquia.

## 5. Referência de estrutura

O exemplo que o professor deu como formato correto é um mural denso, dividido em
blocos pequenos, com pouquíssimo texto em cada um. Ele usa:

título e ficha rápida · descrição de duas linhas · lore · equipe com funções ·
barras de progresso do desenvolvimento · cronograma em linha do tempo · custos ·
público-alvo · diferenciais · **mecânicas como lista de verbos** ·
características · **referências e gêneros como nuvem de tags**

Nenhum parágrafo dele passa de quatro linhas. Vale seguir essa disciplina.

---

## 6. O jogo — para você entender o que está desenhando

**Apocalipse zumbi.** A namorada do protagonista foi mordida e se transformou.
Em vez de abandoná-la, ele a trancou no porão de casa e passou a sair todo dia
às ruas atrás dos recursos e do conhecimento necessários para desenvolver uma
cura. O processo é lento e imperfeito, e cada tentativa exige mais do mundo lá
fora.

O jogo se divide em **dois modos que se alternam a cada dia**, e a distância
entre eles é proposital:

- **Rua** — top-down pixelado, ação, hordas de zumbis, vasculhar casas atrás de
  suprimentos e documentos. Frio, sujo, simples. É onde o jogador passa a maior
  parte do tempo.
- **Casa** — ponto e clique, arte detalhada, tom enigmático. Cuidar dela e
  trabalhar na cura com o que foi trazido de fora. Quente, íntimo, denso.

**A rua é o gameplay. A casa é a história.** O que o jogador arrisca lá fora é o
que destrava o que acontece dentro de casa.

O tempo é contado em dias, com um prazo. Cada dia é uma fase, sempre nos mesmos
lugares — a geografia é fixa e o que muda é o estado do mundo, que vai ficando
mais apocalíptico. No fim, ou a cura fica pronta a tempo, ou o prazo se esgota e
os dois viram zumbis, num final apresentado como paródia de final feliz de
casal.

**Essa dualidade é o conceito da peça.** Se alguém bater o olho no mural e
entender na hora que são dois jogos que se alternam, o design funcionou.

---

## 7. Layout

Bandas horizontais. No meio, o coração da peça: os dois modos lado a lado, com a
divisão visual servindo de argumento.

```
+---------------------------------------------------------------------------+
|  [TITULO GRANDE]                        |                                  |
|  tagline                                |   KEY ART                        |
|  1 jogador . PC e navegador . 14 anos   |   (rua a esquerda, casa a        |
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
|  PROGRESSAO - linha do tempo em dias, com o prazo e os dois desfechos       |
|  -- dia 1 ----------- dia N ------+-- VITORIA: a cura fica pronta           |
|                                   +-- DERROTA: o "final feliz" em parodia   |
+------------+------------+------------+------------+------------+-----------+
| CORE       | MECANICAS  | DIFEREN-   | GENEROS +  | PUBLICO    | EQUIPE    |
| MECHANIC   | (verbos)   | CIAIS      | CONCORRENT.| ALVO       | + FUNCOES |
+------------+------------+------------+------------+------------+-----------+
| CRONOGRAMA (marcos em linha)          | ORCAMENTO (numero grande)          |
+---------------------------------------+------------------------------------+
| TELA DE GAMEPLAY (desenho anotado, ocupando bloco proprio)                 |
+----------------------------------------------------------------------------+
```

**Hierarquia de leitura**, em ordem: título → key art → a divisão rua/casa →
progressão e finais → os blocos pequenos. Se o leitor parar no terceiro nível,
ele já entendeu o jogo.

---

## 8. O conteúdo, bloco a bloco

Todo o texto abaixo é final e pode ser diagramado como está, salvo os ⬜.

### Título

# Você me amaria se eu fosse um zumbi?

⬜ **Pode mudar** — o título definitivo chega depois. O que ele precisa manter,
caso mude: ser uma pergunta, entregar o tom e antecipar a piada do final.

Trate o título **como imagem, não como texto**. É o elemento que ocupa o maior
espaço do mural e é o que vende a peça sozinho.

### Tagline

⬜ **Chega depois.** É a linha curta embaixo do título, no espírito de cartaz de
cinema: dá o tom em uma frase, sem explicar o jogo. Entre 8 e 12 palavras.
Reserve o espaço.

### Pitch — texto de entrada, duas linhas

> Sobrevivência zumbi em dois modos que se alternam a cada dia: você vasculha a
> rua atrás de recursos e respostas, e volta para casa para trabalhar na cura da
> namorada — que está trancada no porão, e já não é mais ela.

### Ficha rápida — linha embaixo do título

| Campo | Conteúdo |
|---|---|
| Jogadores | 1 jogador, offline |
| Plataformas | PC (Windows) e navegador |
| Classificação | 14 anos |
| Gêneros | survival horror narrativo · ação top-down · aventura ponto e clique · pixel art |

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

### O ciclo — texto entre as duas colunas

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

- O tempo é contado em **dias**, e há um **prazo** para completar a cura
- Cada dia é uma **fase**, sempre nos mesmos lugares — a geografia é fixa e o
  que muda é o estado do mundo, que vai ficando mais apocalíptico
- **Vitória:** a cura fica pronta a tempo, ela volta a ser humana, e os dois
  seguem sobrevivendo juntos
- **Derrota:** o prazo se esgota, ela escapa do porão, morde o protagonista, e
  os dois viram zumbis. A tela de fim mostra isso **em tom de paródia**, como o
  final feliz de um casal — mas é o game over

O bloco da derrota é o melhor momento da peça e merece tratamento próprio: o
"final feliz" com moldura de retrato de casal, e o deboche na entrelinha. É a
resposta da pergunta do título.

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

### Concorrentes e benchmarking

Dados do SteamSpy em 03/09/2026. Preços em dólar, com desconto vigente na data;
os donos são estimativa do SteamSpy.

**Concorrentes — porte comparável, time pequeno**

| Jogo | Estúdio | Ano | Preço | Donos (est.) | Nota |
|---|---|---|---|---|---|
| *Darkwood* | Acid Wizard Studio | 2017 | US$ 3,99 | 1–2 mi | 94% |
| *60 Seconds!* | Robot Gentleman | 2015 | US$ 8,99 | 0,5–1 mi | 84% |
| *Vampire Survivors* | poncle | 2022 | US$ 3,74 | 5–10 mi | 98% |
| *Papers, Please* | Lucas Pope | 2013 | US$ 9,99 | 2–5 mi | 97% |

**Referências de estrutura e público — escopo maior**

| Jogo | Estúdio | Ano | Preço | Donos (est.) | Nota |
|---|---|---|---|---|---|
| *Project Zomboid* | The Indie Stone | 2013 | US$ 16,74 | 10–20 mi | 94% |
| *This War of Mine* | 11 bit studios | 2014 | US$ 19,99 | 2–5 mi | 92% |
| *Inscryption* | Daniel Mullins Games | 2021 | US$ 19,99 | 2–5 mi | 96% |

**A leitura desses números — vale um bloco de texto curto na peça:**

- A estrutura de dois modos é fórmula testada de time pequeno. A descrição do
  *Darkwood* na própria Steam é *"scavenge and explore by day, then hunker down
  in your hideout"* — vasculhar de dia, se recolher no abrigo depois. Feito por
  três pessoas, 94% de aprovação, mais de um milhão de donos.
- Escopo pequeno não limita alcance: *Vampire Survivors* foi feito
  essencialmente por uma pessoa e tem de 5 a 10 milhões de donos.
- O público continua comprando: *Project Zomboid* saiu em 2013 e tem de 10 a 20
  milhões de donos.
- Faixa de preço dos comparáveis: **US$ 4 a US$ 10**.

### Público-alvo

**Demografia** — 18 a 30 anos, joga em PC, compra na Steam, não precisa de
máquina forte. Renda média, brasileiro e internacional.

**Psicografia** — perfil **explorador**: joga para entender o sistema, não para
vencer os outros. Gosta de descobrir a regra escondida, testar o limite da
mecânica e otimizar — mas o que faz terminar o jogo é a história. **Não é
try-hard:** não liga para ranking, dificuldade máxima nem platinar.

**Proto-persona**

> **Rafael, 24 anos, estudante de design e estagiário.**
> Joga de 4 a 6 horas por semana, quase sempre à noite, sozinho, no notebook.
> A biblioteca dele é quase toda indie, e o último jogo que comprou foi na
> promoção, depois de ver um vídeo-ensaio no YouTube.
>
> **Como aprende:** lendo a mecânica jogando. Odeia tutorial longo — prefere
> descobrir errando.
> **Como joga:** sessões de 45 min a 1h30. Jogo ideal termina em 8 a 12 horas.
> **O que ele quer:** um sistema que dê para entender e otimizar, dentro de uma
> história que tenha algo a dizer. Adorou *Inscryption* exatamente por isso.
> **O que o afasta:** grind, tutorial arrastado e jogo que promete história e
> entrega só sistema — ou o contrário.
> **Onde descobre jogo:** YouTube, Steam Next Fest e indicação de amigo.

### Equipe e funções

| Integrante | Frente | Função |
|---|---|---|
| João Carlos Pais | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |
| ⬜ | ⬜ | ⬜ |

⬜ **Três nomes e todas as funções chegam depois.** São quatro pessoas, metade
em cada frente — dois na rua, dois na casa. As funções possíveis são artista,
programador, game designer, sound designer e narrative designer; uma pessoa pode
acumular mais de uma. Reserve o espaço para quatro linhas.

### Cronograma — linha do tempo horizontal

`09/09 High Concept` · `30/09 Alfa + prévia do GDD` · `11/11 Beta + GDD final` ·
`02/12 Gold + pitch`

### Orçamento — número grande, com a conta visível

**R$ 3.600**

12 encontros × 3h × R$ 100/hora

É orçamento simulado — precifica o trabalho da equipe como se fosse pago. **A
conta precisa aparecer junto do total**, não só o número: é o que torna a cifra
defensável na avaliação.

---

## 9. A tela de gameplay — bloco obrigatório

O gabarito exige **um desenho de uma tela de gameplay que ajude a explicar o
jogo**. A barra é *explicar*, não impressionar: mockup anotado vale tanto quanto
ilustração; anotado, vale mais.

**Desenhe uma tela do modo Rua, num dia intermediário da partida.**

*Enquadramento*

- Vista **top-down**, câmera de cima
- O **protagonista no centro exato** da tela — a câmera segue ele, então quem se
  move é o cenário
- Proporção 16:9, para encaixar no bloco

*Cenário*

- Rua de bairro residencial: asfalto rachado, calçada, casas dos dois lados, um
  ou dois carros abandonados, lixo espalhado
- Já se vê degradação — não é o primeiro dia. Vegetação tomando a calçada,
  janelas quebradas, vidro no chão
- Paleta fria e dessaturada: concreto, ferrugem, verde-acinzentado, céu lavado.
  Pixel art

*Elementos obrigatórios, porque é o que explica o jogo*

- **Três ou quatro zumbis** chegando de direções e distâncias diferentes — um
  perto o bastante para ser ameaça imediata, os outros ainda longe. É isso que
  comunica pressão
- **Uma casa com a porta destacada ou aberta**, sinalizando que dá para entrar e
  vasculhar
- **Um documento no chão, com brilho**, visualmente distinto dos outros itens —
  é o que destrava a história, precisa parecer especial
- Dois ou três itens comuns espalhados (lata de comida, garrafa de água), para
  contrastar com o documento

*HUD, nos cantos*

- **Topo:** o dia atual e quantos faltam para o prazo da cura
- **Inferior esquerdo:** vida, fome e água
- **Inferior direito:** mochila, com o espaço já ocupado visível

*O que faz o desenho cumprir o critério*

Legendas com seta apontando cada elemento — *"documento: destrava a pesquisa em
casa"*, *"porta: entra e vasculha"*, *"prazo: quantos dias restam"*. É a legenda
que transforma o desenho em explicação.

## 10. Direção de arte

O conceito visual é um só: **frio contra quente, simples contra detalhado**. A
peça deve transmitir isso antes de qualquer texto ser lido.

- **Rua** — cinza-esverdeado dessaturado, concreto, ferrugem, céu lavado. Pixel
  art, poucos pixels, sombra dura.
- **Casa** — âmbar de vela, madeira, um vermelho contido. Ilustração detalhada,
  luz suave, textura.
- **A costura entre as duas** — o elemento de ciclo (seta, engrenagem, relógio
  de dia) fica exatamente na divisa e usa as duas cores.
- **Tipografia** — título com peso e presença; corpo em sans de alta
  legibilidade. **Nada de fonte de terror pingando sangue:** o critério de maior
  peso é linguagem clara, e fonte decorativa derruba isso.
- **Densidade** — muitos blocos pequenos, cada um com título curto e no máximo
  quatro linhas de conteúdo.
- **Limite de gore** — a classificação declarada é **14 anos**. Sangue e morte
  podem aparecer; mutilação, crueldade e violência gratuita, não. Se a arte
  passar disso, a classificação na peça fica incoerente com o que está desenhado.

## 11. Os quatro campos que chegam depois

Reserve espaço para eles e siga com o resto:

1. **Título definitivo** — se mudar, mantém o espírito de pergunta
2. **Tagline** — 8 a 12 palavras, embaixo do título
3. **Três nomes completos** dos integrantes
4. **Frente e função de cada um** dos quatro

## 12. O que não fazer

- Nada que pareça documento de texto — é o item que zera.
- Nada de parágrafo longo. Se um bloco passa de quatro linhas, vira bullet ou
  tag.
- Nada de fonte decorativa ilegível "porque é jogo de terror".
- Não inventar conteúdo para preencher os ⬜ — bloco reservado e vazio é melhor
  que bloco preenchido com informação falsa.

## 13. Checklist antes de fechar

- [ ] Todos os blocos das seções 8 e 9 estão na peça
- [ ] Nenhum bloco em branco, exceto os quatro campos da seção 11
- [ ] Nomes dos integrantes, turma (quarta) e curso (Engenharia de Software)
- [ ] Uma página, paisagem, ≈16:10, PDF
- [ ] Não parece documento de texto
- [ ] O desenho da tela de gameplay está incluído **e legendado**
- [ ] A conta do orçamento aparece junto do total
- [ ] Dá para entender o jogo lendo só o título, a key art e o bloco rua/casa
