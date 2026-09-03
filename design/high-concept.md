# High Concept — Você me amaria se eu fosse um zumbi?

Registro do que a equipe fechou em conversa, escrito em **03/09/2026**. O título
é **provisório**.

> **Isto não é a entrega.** O professor zera o High Concept entregue como
> documento de texto formal — é item eliminatório. A entrega tem que ser um
> one-pager visual. Este arquivo é a **fonte** de onde esse visual sai, e depois
> vira a base do GDD.

Organizado nos 14 tópicos que o professor cobra. ⬜ é o que ainda não foi
decidido; onde há sugestão minha, está dito que é sugestão.

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
água, suprimentos e **documentos** que revelam a origem do apocalipse e trazem
pistas sobre a cura. É onde o jogador passa a maior parte do tempo.

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
um. A equipe se divide **metade em cada modo**, e é assim que o trabalho cabe no
prazo: duas frentes em paralelo, não uma fila.

Isso responde o tópico 8 (modos de jogabilidade) e é metade da resposta do
tópico 12 (equipe e funções) — falta dizer quem fica em qual frente.

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
| 1 | Título do jogo | **Você me amaria se eu fosse um zumbi?** — provisório (03/09/2026), a equipe pode trocar |
| 2 | Plataformas | PC (Windows) e navegador — *proposta, não discutida em grupo* |
| 3 | Jogadores e interação | 1 jogador, offline — *proposta, não discutida em grupo* |
| 4 | Gênero e subgêneros | Survival horror narrativo; ação top-down e aventura ponto e clique como subgêneros — *proposta* |
| 5 | Classificação etária | 16 anos, por violência e tema — *proposta* |
| 6 | Resumo da história | ✅ — a *Premissa* acima |
| 7 | Objetivo principal e secundários | Principal: **completar a cura antes do prazo**. Secundários redigidos no brief — *proposta* |
| 8 | Modos de jogabilidade e controles | Os dois modos estão definidos e a separação é proposital. Controles redigidos no brief — *proposta* |
| 9 | Diferenciais e concorrentes | Diferenciais escritos. Concorrentes de escopo parecido levantados (*Papers, Please*, *60 Seconds!*, *Darkwood*). ⬜ falta o benchmarking numérico na Steam |
| 10 | Público-alvo | ✅ — demografia, psicografia e a proto-persona (Marina, 24) estão no brief |
| 11 | Cronograma | Marcos conhecidos montados. ⬜ o encaixe exato depende do `prazosAtividades(turma)` |
| 12 | Equipe e funções | Quatro pessoas, metade em cada modo. João Carlos Pais confirmado. ⬜ os outros três nomes com sobrenome e as funções |
| 13 | Orçamento | **R$ 6.000** por uma leitura da fórmula (5 encontros × 3h × R$ 100 × 4 pessoas). ⬜ confirmar com o professor |
| 14 | Protótipo | ⬜ — a alfa é outra entrega; falta o **desenho de uma tela de gameplay**, especificado no brief |

## O que ficou resolvido

### A core mechanic — "vasculhar sob pressão"

O professor exige **uma mecânica principal só**, usada de várias maneiras pelos
obstáculos e inimigos. A resposta da equipe, em 03/09/2026, é **vasculhar sob
pressão**: é o que o jogador faz o tempo todo na rua, é o que destrava a
história dentro de casa, e o zumbi existe justamente para atrapalhar isso.
Combate, fome, tempo e escuridão são variações de pressão em cima da mesma ação.

O nome é **nominal**: serve para responder o que o professor cobra e para dar um
eixo ao documento. O jogo continua sendo exatamente o que está descrito aqui —
nada foi cortado nem redesenhado para caber na frase.

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

- **Os três nomes que faltam**, com sobrenome — o professor pede por causa de
  nomes repetidos na turma. São também a questão 1 da tarefa no AVA.
- **Quem fica na rua e quem fica na casa**, e as funções formais de cada um
  (artista, programador, game designer, sound designer, narrative designer;
  uma pessoa pode acumular).
- **A leitura do orçamento**, que é pergunta para o professor.
- **O título**, que hoje está como *Você me amaria se eu fosse um zumbi?* em
  caráter provisório.

## Pontos de atenção

Não são objeções ao desenho do jogo, que está decidido. São coisas que só
aparecem lá na frente e saem mais barato agora.

- **A arte da casa é a parte cara.** "Visual mais detalhado e bem desenhado" é o
  tipo de item que estoura prazo, e ainda não se sabe quem na equipe faz arte.
- **As referências são gigantes.** *Project Zomboid* tem mais de dez anos de
  desenvolvimento. Serve de referência de sensação, não de escopo — e o tópico 9
  pede concorrentes **de escopo similar ao do projeto**, o que vai exigir uma
  segunda lista, de jogos pequenos.
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
