# High Concept — Você me amaria se eu fosse um zumbi?

Registro do que a equipe fechou em conversa, escrito em **03/09/2026**.

> **Isto não é a entrega.** O professor zera o High Concept entregue como
> documento de texto formal — é item eliminatório. A entrega tem que ser um
> one-pager visual. Este arquivo é a **fonte** de onde esse visual sai, e depois
> vira a base do GDD.

Organizado nos 14 tópicos que o professor cobra. ⬜ é o que ainda não foi
decidido; onde há sugestão minha, está dito que é sugestão.

> **O `.pdf` e o `.html` desta pasta são a peça entregue em 09/09/2026, e ficam
> como foram entregues.** Eles ainda dizem que os documentos da rua *revelam a
> origem do apocalipse e trazem pistas sobre a cura* — isso **nunca foi decidido
> pela equipe**, foi escrito por engano e saiu daqui em 15/09/2026. Onde os dois
> discordarem, **vale este arquivo**, não o que foi entregue.

## Premissa

Apocalipse zumbi. A namorada do protagonista foi mordida e se transformou. Em
vez de abandoná-la, ele a tranca no porão de casa e passa a sair diariamente às
ruas em busca dos recursos e do conhecimento necessários para desenvolver uma
cura. O processo é lento e imperfeito, e cada tentativa exige mais do mundo lá
fora.

## Estrutura de jogo

O jogo se divide em **dois modos que se alternam a cada dia**.

### Rua — o gameplay

Top-down pixelado. Mundo e exploração de casas no espírito de *Project Zomboid*,
mas com campo de visão e ritmo de horda mais próximos de *Vampire Survivors*. O
jogador luta ou esquiva dos zumbis enquanto vasculha o cenário atrás de comida,
água, suprimentos e **documentos** — o item que a pesquisa da cura consome. ⬜ O
que esses documentos são, o que contam e onde ficam **não foi decidido**: no
protótipo são placeholders numerados. É onde o jogador passa a maior parte do
tempo.

### Casa — a narrativa

Visual mais detalhado e bem desenhado, contrastando de propósito com a
simplicidade da rua. Interação **ponto e clique**, de tom mais enigmático. Aqui
o jogador cuida da namorada e trabalha na pesquisa da cura, montando o que
trouxe de fora.

### O eixo do design

A relação entre os dois modos é o coração do projeto: **a rua é o gameplay, mas
é ela que destrava o avanço da história dentro de casa**. Quanto mais o jogador
arrisca lá fora, mais narrativa e mais progresso na cura ele libera.

### Dois jogos de propósito

**Decidido em 03/09/2026.** A distância entre a rua e a casa é intencional —
controle, arte e ritmo diferentes de propósito, quase como dois jogos dentro de
um. A equipe se divide **por frente**, e é assim que o trabalho cabe no prazo:
duas frentes em paralelo, não uma fila.

Isso responde o tópico 8 (modos de jogabilidade) e é metade da resposta do
tópico 12 (equipe e funções).

## Equipe e funções

**Fechado em 09/09/2026.** A intenção de 03/09 era metade em cada frente; o que
as pessoas escolheram foi outra coisa, e a tabela registra o que é, não o que
estava planejado.

| Integrante | Frente | Função |
|---|---|---|
| João Carlos Pais | rua e casa | Programador · game designer |
| Renan Floriano | rua | Artista · game designer · narrative designer |
| João Otávio Benedet Zanette | rua | Game designer · narrative designer |
| Lorraini Vieira Costa | casa | Artista — e o que mais a frente pedir, menos programar |

Duas consequências, e as duas são conversa de mesa:

- **Sound designer não tem dono.** É uma das cinco funções que o professor
  lista, e ninguém reivindicou.
- **A casa tem uma artista e nenhum programador.** Por isso a linha do João
  Carlos diz *rua e casa*: enquanto ninguém mais programar, a costura entre os
  dois modos e a lógica da casa saem da mesma mão que fez a rua. A frente da
  casa começa em 23/09 pelo cronograma — é até lá que isso precisa de resposta.

## Progressão e finais

O tempo é contado em **dias**, e existe um **limite de dias** para completar a
cura.

- **Vitória** — a cura fica pronta a tempo, ela volta a ser humana, e os dois
  seguem sobrevivendo juntos.
- **Derrota** — o prazo se esgota, ela escapa do porão, morde o protagonista, e
  os dois viram zumbis. A tela de fim apresenta isso **em tom de paródia**, como
  se fosse o final feliz de um casal, mas mecanicamente é o game over.

### O mundo é o mesmo; o que muda é o estado

**Decidido em 03/09/2026.** Todos os dias se passam nos **mesmos lugares** — a
geografia é fixa, não há mapa novo a cada fase. O que muda é o estado do mundo:
a rua vai ficando mais apocalíptica conforme os dias passam.

Além de sustentar a passagem do tempo pela estética, é a decisão de escopo mais
econômica do projeto: um mapa só, vestido de várias maneiras. E já entrega dois
itens que o GDD cobra — a virada de estilo visual por fase no gráfico de ritmo,
e o conceito de arte de cada fase na seção de estética.

## Os 14 tópicos

| # | Tópico | Situação |
|---|---|---|
| 1 | Título do jogo | ✅ **Você me amaria se eu fosse um zumbi?** — mantido em 09/09/2026. Deixou de ser título de trabalho: ninguém propôs alternativa. **Tagline dispensada** — não é exigida por nenhum dos 14 tópicos |
| 2 | Plataformas | PC (Windows) e navegador — *proposta, não discutida em grupo* |
| 3 | Jogadores e interação | 1 jogador, offline — *proposta, não discutida em grupo* |
| 4 | Gênero e subgêneros | Survival horror narrativo; ação top-down e aventura ponto e clique como subgêneros — *proposta* |
| 5 | Classificação etária | 14 anos — decidido pela equipe em 03/09/2026: tem sangue, mas não é jogo violento |
| 6 | Resumo da história | ✅ — a *Premissa* acima. A história em si (elenco, lore, fluxo narrativo) é mantida em [`narrativa.md`](narrativa.md), que é a fonte da seção 2 do GDD |
| 7 | Objetivo principal e secundários | Principal: **completar a cura antes do prazo**. Secundários logo abaixo, em *Os tópicos que pedem mais que uma linha* — *proposta* |
| 8 | Modos de jogabilidade e controles | Os dois modos estão definidos e a separação é proposital. Controles logo abaixo — *proposta* |
| 9 | Diferenciais e concorrentes | ✅ — diferenciais escritos e benchmarking levantado no SteamSpy em 03/09/2026 (*Darkwood*, *60 Seconds!*, *Vampire Survivors*, *Papers, Please* como concorrentes de porte; *Project Zomboid*, *This War of Mine* e *Inscryption* como referência). Tabelas abaixo |
| 10 | Público-alvo | ✅ — demografia, psicografia e a proto-persona (Rafael, 24) estão abaixo |
| 11 | Cronograma | Marcos conhecidos montados. ⬜ o encaixe exato depende do `prazosAtividades(turma)` |
| 12 | Equipe e funções | ✅ — fechado em 09/09/2026. Quatro pessoas: **dois na rua** (Renan Floriano, João Otávio Benedet Zanette), **uma na casa** (Lorraini Vieira Costa) e a programação atravessando as duas (João Carlos Pais). Ver *Equipe e funções* |
| 13 | Orçamento | **R$ 3.600** — 12 encontros (09/09 a 25/11) × 3h × R$ 100/hora. Simulado, pela fórmula literal do modelo |
| 14 | Protótipo | A alfa é outra entrega. O **desenho de uma tela de gameplay** está descrito abaixo, e foi entregue dentro da peça |

## Os tópicos que pedem mais que uma linha

Estavam no brief do one-pager, que foi apagado em 16/09/2026 depois que a peça
foi entregue. Vieram para cá para o High Concept ficar de pé sozinho.

### 7 · Objetivos

**Principal** — completar a cura antes do prazo.

**Secundários:**

- ⬜ *(a decidir)* — o que os documentos da rua contam ainda é conversa de
  equipe; até lá não há objetivo secundário escrito em cima deles
- Manter ela estável: quanto pior o estado dela, menos tempo sobra
- Equipar a casa e o laboratório para acelerar as tentativas de cura
- ⬜ *(caiu)* — havia aqui **"sobreviver mais um dia com menos dano do que no
  anterior"**, e ele não existe mais: a vida do jogador saiu do jogo em
  16/09/2026, junto com a fome e a água. Enquanto a camada de sobrevivência não
  voltar, não há dano para comparar. A peça entregue em 09/09 ainda traz a
  linha, e fica como foi entregue

### 8 · Controles

- **Rua:** `WASD` ou setas para andar · mouse para mirar e interagir · `E` para
  vasculhar · `Shift` para correr.
- **Casa:** mouse, só. Clique para andar, examinar e combinar itens.

### 9 · Diferenciais e benchmarking

1. **Dois jogos em um** — ação top-down e aventura ponto e clique se alternando
   a cada dia, com arte e ritmo propositalmente diferentes.
2. **O game over vestido de final feliz** — a derrota é apresentada em paródia,
   como o desfecho romântico de um casal.
3. **Risco compra história** — o quanto se arrisca na rua é literalmente quanta
   narrativa se destrava em casa.

Dados do SteamSpy em 03/09/2026; preços em dólar na data, donos estimados.

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

A leitura desses números:

- A estrutura de dois modos é fórmula testada de time pequeno — a própria Steam
  descreve o *Darkwood* como *"scavenge and explore by day, then hunker down in
  your hideout"*. Feito por três pessoas, 94% de aprovação, mais de um milhão de
  donos.
- Escopo pequeno não limita alcance: *Vampire Survivors* foi feito
  essencialmente por uma pessoa e tem de 5 a 10 milhões de donos.
- O público continua comprando: *Project Zomboid* saiu em 2013 e tem de 10 a 20
  milhões de donos.
- Faixa de preço dos comparáveis: **US$ 4 a US$ 10**.

### 10 · Público-alvo

**Demografia** — 18 a 30 anos, maioria masculina mas sem recorte rígido de sexo,
renda média, brasileiro e internacional. Joga em PC e compra na Steam; não
precisa de máquina forte.

**Psicografia** — perfil **explorador**: joga para entender o sistema, não para
vencer os outros. Gosta de descobrir a regra escondida, testar o limite da
mecânica e otimizar — mas o que faz terminar o jogo é a história. **Não é
try-hard:** não liga para ranking, dificuldade máxima nem platinar.

**Proto-persona**

> **Rafael, 24 anos, estudante de design e estagiário.**
> Joga de 4 a 6 horas por semana, quase sempre à noite, sozinho, no notebook. A
> biblioteca dele é quase toda indie, e o último jogo que comprou foi na
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

### 14 · O desenho da tela de gameplay

Entregue dentro da peça de 09/09/2026. É uma tela do modo Rua num dia
intermediário: vista top-down com o protagonista no centro, três ou quatro
zumbis chegando de distâncias diferentes, uma casa com a porta destacada, um
documento no chão com brilho, itens comuns espalhados, a HUD nos cantos e
legendas com seta apontando cada elemento — porque a barra do professor é
*explicar* o jogo, não impressionar.

## O que ficou resolvido

### A core mechanic — "vasculhar sob pressão"

O professor exige **uma mecânica principal só**, usada de várias maneiras pelos
obstáculos e inimigos. A resposta da equipe, em 03/09/2026, é **vasculhar sob
pressão**: é o que o jogador faz o tempo todo na rua, é o que destrava a
história dentro de casa, e o zumbi existe justamente para atrapalhar isso.
Tempo, escuridão, combate e espaço na mochila são variações de pressão em cima
da mesma ação.

O nome é **nominal**: serve para responder o que o professor cobra e para dar um
eixo ao documento. O jogo continua sendo exatamente o que está descrito aqui —
nada foi cortado nem redesenhado para caber na frase.

⬜ **A lista de pressões mudou em 16/09/2026.** Em 03/09 ela era *"combate,
fome, tempo e escuridão"*, e é assim que a peça entregue em 09/09 ainda diz. A
**fome saiu** junto com a vida e a água — a camada de sobrevivência ficou para
depois de as regras da rua e da casa fecharem — e o **espaço da mochila** entrou
no lugar, que é uma pressão que o protótipo aplica de verdade: 12 vagas, e o que
não cabe fica para trás.

As quatro que o jogo aplica hoje são o **zumbi** (que interrompe o vasculho e
cobra o tempo que faltava), o **relógio do dia**, o **prazo da cura** e as
**vagas da mochila**. A peça fica como foi entregue; onde os dois discordarem,
vale este arquivo.

### A "fase" é o dia

**Decidido em 03/09/2026.** Cada dia é uma fase. Isso encaixa na terceira opção
de escopo do documento do professor — jogo arcade que acaba no game over, com
cerca de 10 níveis, ondas ou estágios — e resolve o que a Beta cobra como *uma
fase grande terminada* e a Gold como *fase(s) terminada(s)*. Vale levar essa
leitura pronta para a conversa de calibragem de escopo com ele.

## O que ainda falta decidir

Tudo o que aparece como *proposta* na tabela acima foi escrito por mim para a
peça não sair com bloco vazio, e **nenhuma dessas linhas passou pelo grupo**:
gênero, plataformas, número de jogadores, classificação etária, objetivos
secundários, controles e o público-alvo. Aprovar ou rasgar é decisão da equipe.

O que ninguém além do grupo pode resolver:

- **Quem assume sound designer**, e **quem programa a casa** — ver *Equipe e
  funções*. São as duas que sobraram: título, tagline, nomes e funções fecharam
  em 09/09/2026.

## Pontos de atenção

Não são objeções ao desenho do jogo, que está decidido. São coisas que só
aparecem lá na frente e saem mais barato agora.

- **A arte da casa é a parte cara.** "Visual mais detalhado e bem desenhado" é o
  tipo de item que estoura prazo, e ainda não se sabe quem na equipe faz arte.
- **A estrutura de dois modos tem precedente de time pequeno.** O benchmarking
  de 03/09/2026 mostrou que *Darkwood* (três pessoas) e *60 Seconds!* fazem
  exatamente vasculhar-depois-abrigo, com boa recepção. Isso é argumento a favor
  na conversa de escopo, não contra.
- **O professor calibra o escopo caso a caso.** Essa conversa continua pendente.
  As duas frentes em paralelo são o assunto a levar — não para pedir licença,
  mas para ele conhecer o desenho antes de avaliar as entregas.

## O que já está a favor

- O **final em paródia** é um diferencial de verdade, do tipo que se vende em
  pitch: o final feliz de casal que na prática é a derrota. Material pronto para
  o tópico 9 e para o vídeo do pitch.
- **A geografia fixa é a decisão mais econômica do projeto.** Um mapa só,
  vestido de várias maneiras, entrega dez fases pelo custo de uma.
- O eixo rua → casa dá uma **razão narrativa para o gameplay**, que é
  precisamente o que o professor cobra ao exigir mecânica, narrativa e estética
  trabalhando juntas.
- Cada dia ser uma rodada fechada casa bem com a exigência de MVP jogável: dá
  para entregar um dia inteiro funcionando na Alfa e crescer dali.

## Futuro do jogo

O GDD cobra *futuro do jogo* como item próprio, e já há resposta: a intenção da
equipe é **continuar o projeto depois da disciplina**, com um jogo comercial no
horizonte. Isso não muda o escopo do semestre — a entrega continua sendo o MVP
pedido — mas é material direto para o pitch de investimentos, que pergunta pela
oportunidade de negócio e pela timeline de desenvolvimento depois da entrega.
