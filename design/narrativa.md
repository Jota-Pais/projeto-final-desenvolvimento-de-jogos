# Narrativa — Você me amaria se eu fosse um zumbi?

Onde a história do jogo é escrita e mantida. Aberto em **16/09/2026**, no dia da
aula de narrativa.

Este arquivo é a **fonte da seção 2 do GDD** (*Narrativa*). O professor cobra
seis itens ali, e são as seis seções abaixo.

O High Concept, que foi a fonte do one-pager entregue em 09/09, **saiu da árvore
em 16/09/2026** — ele registrava uma entrega feita e ficava pedindo manutenção a
cada mudança do jogo. Continua no git, e o README diz como trazer de volta.

## Como escrever aqui — não precisa saber git

1. Abra este arquivo no GitHub:
   <https://github.com/Jota-Pais/projeto-final-desenvolvimento-de-jogos/blob/main/design/narrativa.md>
2. Clique no **lápis** (✏️, canto superior direito). Funciona no navegador do
   celular também.
3. Escreva e clique em **Commit changes** — é só isso, está salvo para todo
   mundo.

Escreva como você falaria. Formatação não importa; conteúdo importa. Apague o ⬜
da seção quando ela deixar de estar vazia.

**O que for decidido no WhatsApp só está decidido quando estiver aqui** — uma
linha, no mesmo dia. O resto vira scroll e ninguém acha em outubro.

**Quem cuida disto é a equipe de narrativa** — Renan Floriano e João Otávio
Benedet Zanette são os narrative designers. O que está escrito aqui é ponto de
partida para eles, não texto fechado.

> ⬜ **Nada neste arquivo foi decidido em grupo até agora.** O que está marcado
> como *proposta do João* saiu de conversa dele fora da mesa e precisa passar
> pela equipe. O que veio do High Concept de 03/09 está marcado como tal.
>
> Em 15/09/2026 o repositório foi limpo de uma invenção que estava registrada
> como se fosse decisão: seis documentos com título, conteúdo e lugar certo no
> mapa. Não escrever nada aqui com essa confiança sem a mesa ter passado por
> cima.

## 1. Plot

⬜ Uma frase: protagonista, desejo e problema.

O que já existe é a premissa do High Concept (03/09/2026, decidida em grupo):
apocalipse zumbi, a namorada do protagonista foi mordida e se transformou, ele a
trancou no porão em vez de abandoná-la e sai todo dia à rua atrás do que precisa
para desenvolver uma cura — com prazo.

**16/10/2026, decisão do João:** a casa das fotos da equipe não tem porão —
ela fica presa **no quarto**, acorrentada à cabeceira da cama, e ele dorme no
sofá da sala.

⬜ Nem ele nem ela têm nome. Nenhum dos dois tem profissão, e não se sabe por
que ele saberia trabalhar numa cura.

## 2. Ideia controle

⬜ A moral: carga inicial, carga final, e como o personagem termina transformado.

O material está nos dois finais, que já são decisão de 03/09 e estão
implementados: a cura a tempo, ou o prazo esgotado com a derrota apresentada em
paródia de final feliz de casal. O que ainda não existe é a frase que diz o que
o jogo pensa sobre isso.

## 3. Ambiente do jogo

Decidido em 03/09 e já implementado: os mesmos lugares todos os dias — a
geografia é fixa e o que muda é o estado do mundo, que vai ficando mais
apocalíptico. O tempo é contado em dias, com prazo (hoje 30 no protótipo).

O mapa existe e é 550 × 318 m, traçado do desenho do João (`urussanga.png`,
30/09/2026): floresta, milharal e fazenda a oeste; hospital, posto, hotel,
bar e parque industrial no meio; praça, igreja, escola, prefeitura, lojas e
mercado no centro; prisão, delegacia e campo ao sul. Descrito em
`../README.md`.

⬜ Época, país, o que aconteceu no mundo, e há quanto tempo.

## 4. Incidente incitante

⬜ O que tira o protagonista da zona de conforto. Na prática: como, onde e
quando ela foi mordida — e por que ele ficou.

## 5. Fluxo narrativo

⬜ História resumida marcando incidente incitante, pontos de virada, cargas,
clímax e fechamento, mais o **gráfico de tensão** por fase. Nada disso existe.

Complicador conhecido: no jogo cada **dia é uma fase**, e são 30. Um gráfico de
tensão por fase não vai ser trinta colunas — é assunto da equipe decidir se o
gráfico é por dia, por semana ou por ato.

## 6. Personagens e design de elenco

### O protagonista

⬜ Sem nome e sem descrição. É quem o jogador controla na rua.

### Ela

⬜ Sem nome. Mordida, transformada, presa no quarto (era o porão até 16/10/2026). É o prazo do jogo em
forma de pessoa, e não aparece na rua.

### O sobrevivente do búnquer — **proposta do João, 16/09/2026**

O primeiro NPC que o jogador encontra, e quem dá o tutorial.

- Sobrevivente **preparado demais**: o tipo que tinha búnquer em casa porque
  jurava que o apocalipse vinha. E veio.
- **Evita ao máximo o contato direto.** Ranzinza, extremamente desconfiado — e
  ajudando o jogador o tempo todo por baixo disso.
- Ajuda com **dicas de lugar e do que fazer**, e eventualmente com algum item.
- **Primeiro contato pela porta do búnquer**; depois ele entrega um **rádio**, e
  é por rádio que fala o resto do jogo. O item que ele dá é a personalidade
  dele: o jeito de ajudar sem abrir a porta.
- **Não quer nada em troca** — por enquanto. Se ele passa a cobrar, é decisão da
  equipe e muda o balanço do jogo.
- O peso dele é no **tutorial e no começo**. O jogo vai ter mais NPCs, e ele não
  precisa carregar o resto.
- **Em algum momento o protagonista pode contar a ele sobre a namorada.**

#### O roteiro do tutorial — conceito do João, 20/10/2026 (ainda não aplicado)

Texto para guiar o desenvolvimento quando o tutorial entrar; nada disto está
no jogo. Do jeito que o João escreveu, só com a digitação corrigida:

> o personagem vai ter vizinho antonio, ele vai ser que vai dar o tutorial do
> jogo via um radio.
>
> no primeiro do dia o personagem principal vai estar completamente perdido,
> sem saber pra onde ir ou o que fazer, e aí entra o antonio, antonio é um
> homem ranzinza, lunático e antissocial, ele sempre achou que ia acontecer um
> apocalipse zumbi, ele tinha um bunker, estoques de comida e agua, sempre se
> preparando e adivinha? ele estava certo! agora ele está completamente seguro
> e preparado para o apocalipse, mas não o seu vizinho.
>
> o personagem principal em uma cinematic (com a mesma arte do jogo) vai sair
> de casa meio assustado com a situação, mas sendo obrigado a fazer isso pra
> tentar encontrar uma solução pra infecção de sua namorada. ele vai estar
> andando e vai ser atacado por um zumbi, mas de repente o zumbi cai morto no
> chão, foi o vizinho esquisito. o personagem principal vai direto pra porta
> dele pedir ajuda. ele recusa. diz que nunca vai correr o risco de um
> infectado entrar na casa dele, e diz que o personagem principal não deveria
> andar por ai num apocalipse zumbi sem uma arma.
> mesmo sendo ranzinza o vizinho se comove com a situação, ele entrega um radio
> para o personagem principal e pronto, agora temos uma maneira imersiva de dar
> o tutorial do jogo.
>
> o vizinho vai pedir um favor para o personagem, ele vai ir até o mercado
> buscar alguma coisa pro antonio e isso vai servir como um tutorial, ele vai
> aprender a correr, agachar e se esconder de zumbis e quando o protagonista
> voltar ele vai ganhar uma 9mm de recompensa

Em passos, para quando virar código:

1. **Dia 1, cena de abertura** (cinematic com a arte do jogo): ele sai de casa
   assustado, por causa dela.
2. **O ataque:** um zumbi o pega na rua e cai morto — tiro do Antônio.
3. **A porta do búnquer:** ele pede ajuda; o Antônio recusa (não deixa
   infectado nenhum chegar perto), reclama que ele anda desarmado e, comovido,
   entrega o **rádio**. Daqui em diante o tutorial fala pelo rádio.
4. **O favor:** buscar alguma coisa no mercado - o Restaurante, ver abaixo -
   para o Antônio. No caminho, o rádio ensina **correr, agachar e se
   esconder** de zumbis.
5. **A volta:** entregar o que buscou e ganhar a **9mm**.

O que isso pede que o jogo ainda não tem: cena roteirizada na rua, conversa
na porta (o "sistema só de conversa" de "Os outros NPCs"), falas de rádio na
tela, missão de buscar e entregar, **agachar** (não existe) e uma regra de
**se esconder** (hoje só existe a visão em cone cortada por parede). Já
existe: correr (Shift), a visão do zumbi, o tiro e a Beretta 9mm.

**Decidido pelo João em 21/10/2026, para a entrega do tutorial:**

- **A cena de abertura** é na rua perto da casa do Antônio: o protagonista
  anda meio sem rumo, um zumbi o pega desprevenido e o Antônio o mata,
  salvando o protagonista.
- **O tutorial tem dois dias.** O dia 1 é o do roteiro acima (portão,
  rádio, o favor no Restaurante, a 9mm); o **dia 2** é para explorar um pouco
  e ter a chance de usar a arma.
- **Agachar:** *"eu me escondo, quem eu vejo não"* — agachado atrás de
  cobertura, o zumbi não te vê; você continua vendo ele.
- **O dia 1 começa desarmado**: a 9mm é a recompensa do favor.
- **As falas** (o portão, o rádio, o que o Antônio pede no Restaurante) são
  do João, a escrever.
- Nenhum zumbi colado na sua casa no começo.
- **A casa do Antônio** é a mais fortificada do bairro e fica ao lado da sua
  (João, 20/10/2026): a vizinha colada a leste, na mesma calçada (prédio 36
  do traçado, no ponto (1214, 647) do desenho). Ainda sem rótulo no mapa.
- **O "mercado" do favor é o Restaurante** (João, 20/10/2026), que fica dentro
  da região do tutorial; o Mercado do mapa fica fora dela.

⬜ **A personalidade aprofundada é trabalho da equipe de narrativa** — fala,
história dele, o que ele sabe. O nome (Antônio) e o tipo (ranzinza, lunático,
antissocial, búnquer com estoque) são do João, 20/10/2026.

⬜ **Ele sai de cena em algum momento?** Morre, vira zumbi, fecha a porta de
vez, ou simplesmente continua no rádio até o fim? Em aberto.

⬜ **Contar da namorada é escolha do jogador ou cena marcada?** A diferença não
é de texto, é de código: escolha exige diálogo com opções e um estado que lembra
o que foi dito; cena marcada é um roteiro que dispara num dia e sai barato. A
equipe decide o que quer, e daí sai o que eu programo.

### Os outros NPCs

⬜ Vão existir — ainda não se sabe quem, quantos, nem onde. **Consequência
técnica:** se são vários, a conversa vira um sistema só, usado por todos (porta,
rádio, o que vier), e não um caso especial por personagem.

### Design de elenco

⬜ Como eles se relacionam para a história acontecer. É item do GDD, e hoje só
dá para dizer que o elenco é pequeno.

*Leitura do João, ainda não levada à mesa:* o sobrevivente do búnquer é o
contraste do protagonista — um se preparou e sobreviveu sozinho, o outro não se
preparou e se recusa a ficar sozinho. Um escolheu a porta fechada; o outro
trancou alguém atrás de uma e não vai embora.

## O que a narrativa ainda não tem, e é bom não esquecer

- **Os documentos da rua estão vazios de propósito.** São placeholders numerados
  no jogo, e o que eles são — se é que continuam sendo documentos — está em
  aberto desde 15/09/2026. É o espaço mais óbvio para lore que existe hoje.
- **A casa é onde a narrativa acontece** pelo High Concept, e ainda é uma tela
  de texto reservada. A frente começa em 23/09.
