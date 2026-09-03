# High Concept

Registro do que a equipe fechou em conversa, escrito em **03/09/2026**.

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

## Progressão e finais

O tempo é contado em **dias**, e existe um **limite de dias** para completar a
cura.

- **Vitória** — a cura fica pronta a tempo, ela volta a ser humana, e os dois
  seguem sobrevivendo juntos.
- **Derrota** — o prazo se esgota, ela escapa do porão, morde o protagonista, e
  os dois viram zumbis. A tela de fim apresenta isso **em tom de paródia**, como
  se fosse o final feliz de um casal, mas mecanicamente é o game over.

## Os 14 tópicos

| # | Tópico | Situação |
|---|---|---|
| 1 | Título do jogo | ⬜ — trava também o nome do repositório e o `config/name` |
| 2 | Plataformas | ⬜ — a escolha do Godot com export web aponta para PC e navegador; falta bater o martelo |
| 3 | Jogadores e interação | ⬜ — a premissa é de um jogador só, offline, mas isso nunca foi dito em voz alta |
| 4 | Gênero e subgêneros | ⬜ — ver *O gênero precisa de nome* abaixo |
| 5 | Classificação etária | ⬜ — zumbi, mordida e violência puxam para 16 ou 18 |
| 6 | Resumo da história | ✅ — a *Premissa* acima |
| 7 | Objetivo principal e secundários | Principal: **completar a cura antes do prazo**. ⬜ os secundários |
| 8 | Modos de jogabilidade e controles | Os dois modos estão definidos. ⬜ os controles de cada um |
| 9 | Diferenciais e concorrentes | *Project Zomboid* e *Vampire Survivors* são as referências citadas. ⬜ o benchmarking e o diferencial escrito |
| 10 | Público-alvo | ⬜ — demografia, psicografia e proto-persona |
| 11 | Cronograma | ⬜ — depende do `prazosAtividades(turma)`, que ainda não foi baixado do AVA |
| 12 | Equipe e funções | Quatro pessoas. ⬜ quem faz o quê |
| 13 | Orçamento | Fórmula do professor: dias de aula no projeto × R$ 100 × 3. São 5 encontros marcados como projeto (23/09, 30/09, 04/11, 11/11, 25/11) → **R$ 1.500**. ⬜ confirmar a leitura |
| 14 | Protótipo | ⬜ — versão alfa mais um desenho de tela de gameplay |

## O que precisa de decisão antes do High Concept

### O gênero precisa de nome

O tópico 4 pede gênero principal e subgêneros, e hoje não há uma resposta. O que
existe descreve duas coisas diferentes: a rua é ação/sobrevivência top-down, a
casa é aventura ponto e clique. *Sugestão:* **survival horror narrativo**, com
ação top-down e aventura ponto e clique como subgêneros — mas quem decide é a
equipe.

### A core mechanic precisa ser uma só

Esta é a exigência mais dura do professor: **uma mecânica principal, usada de
várias maneiras** pelos obstáculos e inimigos. O design de hoje tem combate,
exploração, coleta, gestão de recurso, ciclo de dias e enigma — não dá para
entregar tudo isso como "a core mechanic".

*Sugestão:* **vasculhar sob pressão**. É o que o jogador faz o tempo todo na
rua, é o que move a história dentro de casa, e o zumbi existe justamente para
atrapalhar isso. Combate, fome, tempo e escuridão viram variações de pressão em
cima da mesma ação. De novo: sugestão, não decisão.

### O que é uma "fase" neste jogo

A Beta exige *uma fase grande terminada* e a Gold exige *fase(s) terminada(s)*.
Um jogo de ciclo de dias não tem fase óbvia. *Leitura possível:* **cada dia é
uma fase**, o que encaixa na terceira opção de escopo do documento do
professor — jogo arcade que acaba no game over, com cerca de 10 níveis, ondas
ou estágios. Vale levar essa leitura pronta para a conversa de calibragem de
escopo com ele.

## Riscos de escopo

Registrados para a conversa com o professor, não para travar o projeto.

1. **São dois jogos.** Rua e casa têm arte diferente, controle diferente e
   sistemas diferentes. São dois pipelines de arte e duas engenharias dentro de
   um MVP de três meses. É o maior risco do projeto e é o primeiro assunto a
   levar para a calibragem de escopo.
2. **A arte da casa é a parte cara.** "Visual mais detalhado e bem desenhado" é
   exatamente o tipo de item que estoura prazo. A equipe ainda não definiu
   funções nem se tem alguém de arte.
3. **As referências são gigantes.** *Project Zomboid* tem mais de dez anos de
   desenvolvimento. Serve como referência de sensação, não de escopo — e o
   tópico 9 pede concorrentes **de escopo similar ao do projeto**, o que vai
   exigir procurar jogos menores.
4. **A direção anterior morreu.** Em 02/09 estava registrado que o grupo ia de
   roguelite de arena, no estilo *Vampire Survivors*/*Brotato*. Este documento
   substitui aquilo.

## O que já está a favor

- O **final em paródia** é um diferencial de verdade, do tipo que se vende em
  pitch: o final feliz de casal que na prática é a derrota. Isso é material
  pronto para o tópico 9 e para o vídeo do pitch.
- O eixo rua → casa dá uma **razão narrativa para o gameplay**, que é
  precisamente o que o professor cobra ao exigir mecânica, narrativa e estética
  trabalhando juntas.
- Cada dia ser uma rodada fechada casa bem com a exigência de MVP jogável: dá
  para entregar um dia inteiro funcionando na Alfa e crescer dali.
