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
e é ela que roda no F5. A **cena de teste** em `teste-movimento/` continua no
repositório só porque o `inimigo.gd` dela vai ser reaproveitado no passo
seguinte — não tem relação nenhuma com o jogo e sai depois disso.

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
- `rua.tscn` — a cena, e é minúscula: `Cenario`, `Jogador`, `EntradaDeCasa` e
  `Telhados`. Tudo o mais é gerado
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
- `conferir_bairro.tscn` — **ferramenta, roda com F6.** Ver abaixo

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

### O que ainda não tem

Zumbi, prazo, fome, mochila e HUD — os passos 2 a 5. Nada disso precisa existir
para a mecânica ser avaliada, e a ordem é essa de propósito: em qualquer corte
já tem coisa demonstrável.

O `interromper()` do vasculhável já existe e não tem quem chame: é o gancho do
passo 2, quando o zumbi encostar.

Também não tem **estado que atravesse o dia**: ao voltar para o bairro, todo o
loot reaparece. O PZ gera o loot no primeiro acesso e não repõe, e o nosso High
Concept diz o mesmo — *a geografia é fixa e o que muda é o estado do mundo*.
Guardar o que já foi vasculhado é o passo 3/4.

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

## Cena de teste (`teste-movimento/`)

Serviu **só para confirmar que o Godot abre e roda o projeto**. Não é o jogo e
não tem relação com o que vier a ser o jogo. **Já não é mais a cena principal** —
o F5 abre a `rua/`. Continua aqui só porque o `inimigo.gd` vai ser reaproveitado
no passo 2, e sai depois disso.

Para ver rodando, abrir `teste-movimento/teste.tscn` e apertar **F6**.
Setas ou WASD movem um quadrado vermelho de 64 px por um chão xadrez cinza com
blocos espalhados. O quadrado fica **fixo no meio da tela**: a `Camera2D` é
filha dele, então quem se mexe é o cenário. O xadrez e os blocos existem por
isso — num chão liso e uniforme não dá para perceber movimento nenhum.

Quatro **inimigos** — retângulos verde-acinzentados de 44×80 — nascem nos cantos
e andam devagar (110 contra os 420 do jogador) na direção dele, o tempo todo.
Não atacam, não morrem e não desviam de nada.

Tudo é forma geométrica de cor chapada, sem nenhuma imagem: a cena não depende
de asset nenhum e por isso não tem o que baixar nem o que versionar em binário.

- `teste.tscn` — a cena: `Chao`, `Jogador` (`CharacterBody2D` com `Polygon2D`,
  colisão e câmera) e quatro `Inimigo`
- `inimigo.tscn` — o inimigo, instanciado quatro vezes na cena
- `inimigo.gd` — anda na direção do jogador e nada mais. Acha o jogador pelo
  **grupo** `jogador`, não por caminho de node, para não depender de onde ele
  está na árvore
- `chao.gd` — desenha o xadrez, os blocos e a borda do mundo (3200×1800) com
  `_draw()`, sem precisar de nenhuma imagem
- `jogador.gd` — movimento em 8 direções com `move_and_slide()` e trava nas
  bordas do mundo

O `run/main_scene` do `project.godot` já aponta para a `rua/`, então apagar esta
pasta não quebra nada.

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
