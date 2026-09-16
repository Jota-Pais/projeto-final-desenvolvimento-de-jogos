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

## O que existe hoje

- **A rua** é jogável de ponta a ponta: mapa de 1 km × 550 m, vasculhar, zumbi,
  relógio, mochila, pistola, e o dia fechando pela porta de casa.
- **A casa** (`casa/casa.tscn`) é um **lugar reservado** — uma tela de texto que
  fecha o ciclo enquanto a outra frente da equipe não começa. Quem for fazer essa
  frente troca a cena e não precisa tocar em nada da rua.
- **Sem arte e sem áudio**: tudo é retângulo de cor chapada.

## As regras que o código implementa

- **Cada dia é uma fase.** A partida acaba na vitória (a cura fica pronta) ou na
  derrota (o prazo se esgota) — ver `fim_de_jogo.gd`.
- **A core mechanic é vasculhar sob pressão**, e a pressão vem de quatro lugares
  em cima da mesma ação: o zumbi cobra tempo, o relógio cobra luz, o prazo cobra
  dia e as 12 vagas da mochila cobram escolha.
- **Não há vida, fome nem água.** A camada de sobrevivência saiu do jogo em
  16/09/2026, por decisão de mesa, e volta — se voltar — depois de as regras da
  rua e da casa fecharem. O toque do zumbi continua existindo: ele empurra e
  interrompe o vasculho, e o que se perde é o tempo que faltava para terminá-lo.
- **O mundo esvazia e não repõe.** Móvel vasculhado ontem nasce vazio hoje.
- **A porta da fachada é a única entrada da sua casa.** Ela é sólida e fecha o
  vão inteiro: não se atravessa a pé. O único jeito de entrar é segurar `E`
  nela — e o que se entra é a cena da casa, não o interior do prédio. É por isso
  que o jogador nasce na calçada, e é a única construção do mapa assim.
- **Só entra em casa o que passou por essa porta.** Amanhecer na rua deixa a
  mochila na calçada e custa o dia — são os dois únicos jeitos de um dia acabar.
- **A arma não é loot, é equipamento**: não ocupa vaga e não se perde. Está na
  armaria da delegacia, e o tiro chama a horda.
- **Os documentos são placeholders numerados.** Existem seis no mapa, a cura pede
  quatro, e é o que fecha a partida. ⬜ O que eles são, o que contam e onde ficam
  **não foi decidido pela equipe** — ver `design/narrativa.md`.

## Os arquivos

O layout do mapa é **dado, não cena**: não existe `mapa.tscn`.

| arquivo | o quê |
|---|---|
| `travessia.gd` | autoload. O dia, o prazo, o que chegou em casa — o **único** lugar onde a rua e a casa se encontram |
| `rua/mapa.gd` | **onde** fica cada coisa: mundo, rodovia, rio, ponte, lista de lugares |
| `rua/lugares.gd` | **do que** cada lugar é feito — um gerador por tipo (bairro, cidade, posto, mansão, sítio, lavoura, floresta) |
| `rua/construcao.gd` | as regras de uma construção qualquer (parede, vão de porta, quarto) e as tabelas de loot |
| `rua/cenario.gd` | desenha o chão e gera colisão, móveis e árvores a partir do mapa |
| `rua/vasculhavel.gd` | **a core mechanic**: barra que enche enquanto `E` estiver segurado |
| `rua/jogador.gd` | andar e correr, e nada mais — quem lê a tecla de vasculhar é o próprio móvel |
| `rua/zumbi.gd` | visão em cone cortada por parede, chamado de horda, toque que interrompe |
| `rua/navegacao.gd` | grade A* — é o que faz o zumbi achar o vão da porta |
| `rua/relogio.gd` | a luz do dia, o custo do vasculho e a noite |
| `rua/mochila.gd` | as 12 vagas e o que atravessa o fim do dia |
| `rua/tela_da_mochila.gd` | a tela do `Tab`, com o mundo rodando atrás |
| `rua/pistola.gd` | a arma, a munição e o tiro chamando a horda |
| `rua/hud.gd` | a HUD nos três cantos |
| `rua/telhados.gd` | telhados por cima de tudo; some o da construção em que você está |
| `rua/entrada_de_casa.gd` | a porta da fachada da sua casa: sólida, e a única entrada. Segure `E` e o dia encerra |
| `casa/casa.gd` | o lugar reservado do modo Casa |
| `fim_de_jogo.gd` | as duas telas de fim de partida |

Mudar o mapa = mexer em `mapa.gd` e `lugares.gd`. Mudar o que sai dos móveis =
`construcao.gd`.

## As ferramentas (F6)

Cenas que não são o jogo: rodam, imprimem um relatório e saem. **Rode a que
corresponde ao que você mexeu** — elas pegam a classe de bug que não aparece
jogando dois minutos.

| cena | confere |
|---|---|
| `rua/conferir_mapa.tscn` | dá para chegar a pé em todo lugar, todo quarto e todo móvel; a sua casa é a exceção e tem que estar selada; a ponte é o único atravessadouro; um documento por lugar |
| `rua/conferir_zumbi.tscn` | visão, parede cortando a visão, chamado de horda e toque |
| `rua/conferir_relogio.tscn` | a luz do dia, o vasculho gastando em dobro, a noite e o aviso |
| `rua/conferir_mochila.tscn` | as vagas, o que atravessa o fim do dia, o mundo não repondo, o loot total e a HUD |
| `rua/conferir_arma.tscn` | a pistola, a munição, o tiro chamando a horda |
| `rua/conferir_fim.tscn` | a partida dá para ganhar, a vitória, a derrota e a escalada de zumbis |
| `rua/retratar_mapa.tscn` | **gera** a imagem legendada do mapa em `design/mapa.png` |

Dá para rodar sem abrir o editor:

```
Godot_v4.7.2-stable_win64_console.exe --path . --headless res://rua/conferir_mapa.tscn
```

## O design

| arquivo | o quê |
|---|---|
| [`design/narrativa.md`](design/narrativa.md) | a história: elenco, lore, fluxo narrativo. É a fonte da seção 2 do GDD |
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
