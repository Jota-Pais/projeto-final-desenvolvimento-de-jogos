#!/usr/bin/env node
'use strict';
/**
 * Traça o desenho do mapa (design/urussanga.png) e escreve rua/mapa_tracado.json.
 *
 * Cada cor do desenho é uma classe de chão ou de prédio. O texto e as linhas
 * finas são apagados, cada região de chão vira um polígono e cada prédio vira
 * um ou mais retângulos axiais (o jogo só sabe prédio axial). O que cada coisa
 * É — nome, tipo, documento, a sua casa — NÃO mora aqui: mora em rua/mapa.gd
 * (ROTULOS), apontado por coordenada do desenho.
 *
 *   node design/tracar_desenho.js [entrada.png] [saida.json] [pasta-de-depuracao]
 *
 * Sem dependência nenhuma além do Node (>= 22).
 */
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const ENTRADA = process.argv[2] || path.join(__dirname, 'urussanga.png');
const SAIDA = process.argv[3] || path.join(__dirname, '..', 'rua', 'mapa_tracado.json');
const DEPURACAO = process.argv[4] || '';

// ------------------------------------------------------------------- PNG

function lerPng(arquivo) {
  const b = fs.readFileSync(arquivo);
  const assinatura = [137, 80, 78, 71, 13, 10, 26, 10];
  for (let i = 0; i < 8; i++) if (b[i] !== assinatura[i]) throw new Error(`${arquivo} não é PNG`);
  let p = 8, w = 0, h = 0, profundidade = 0, tipoDeCor = 0, entrelacado = 0;
  const idat = [];
  while (p + 8 <= b.length) {
    const tamanho = b.readUInt32BE(p);
    const tipo = b.toString('ascii', p + 4, p + 8);
    const dados = b.subarray(p + 8, p + 8 + tamanho);
    if (tipo === 'IHDR') {
      w = dados.readUInt32BE(0); h = dados.readUInt32BE(4);
      profundidade = dados[8]; tipoDeCor = dados[9]; entrelacado = dados[12];
    } else if (tipo === 'IDAT') idat.push(dados);
    else if (tipo === 'IEND') break;
    p += 12 + tamanho;
  }
  if (profundidade !== 8 || entrelacado !== 0) throw new Error('PNG: só 8 bits por canal, sem entrelaçamento');
  if (tipoDeCor === 3) throw new Error('PNG: paleta indexada não suportada');
  const canais = { 0: 1, 2: 3, 4: 2, 6: 4 }[tipoDeCor];
  const bruto = zlib.inflateSync(Buffer.concat(idat));
  const passo = w * canais;
  const rgb = Buffer.alloc(w * h * 3);
  let anterior = Buffer.alloc(passo), atual = Buffer.alloc(passo);
  let r = 0;
  for (let y = 0; y < h; y++) {
    const filtro = bruto[r++];
    bruto.copy(atual, 0, r, r + passo);
    r += passo;
    for (let i = 0; i < passo; i++) {
      const a = i >= canais ? atual[i - canais] : 0;
      const b2 = anterior[i];
      const c = i >= canais ? anterior[i - canais] : 0;
      let v = atual[i];
      switch (filtro) {
        case 1: v += a; break;
        case 2: v += b2; break;
        case 3: v += (a + b2) >> 1; break;
        case 4: {
          const pp = a + b2 - c;
          const pa = Math.abs(pp - a), pb = Math.abs(pp - b2), pc = Math.abs(pp - c);
          v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b2 : c);
          break;
        }
      }
      atual[i] = v & 255;
    }
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 3, i = x * canais;
      if (canais >= 3) { rgb[o] = atual[i]; rgb[o + 1] = atual[i + 1]; rgb[o + 2] = atual[i + 2]; }
      else { rgb[o] = rgb[o + 1] = rgb[o + 2] = atual[i]; }
    }
    [anterior, atual] = [atual, anterior];
  }
  return { w, h, rgb };
}

function escreverPng(arquivo, w, h, rgb) {
  const linha = w * 3 + 1;
  const bruto = Buffer.alloc(linha * h);
  for (let y = 0; y < h; y++) {
    bruto[y * linha] = 0;
    rgb.copy(bruto, y * linha + 1, y * w * 3, (y + 1) * w * 3);
  }
  const pedaco = (tipo, dados) => {
    const tamanho = Buffer.alloc(4); tamanho.writeUInt32BE(dados.length);
    const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(zlib.crc32(corpo) >>> 0);
    return Buffer.concat([tamanho, corpo, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  fs.writeFileSync(arquivo, Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    pedaco('IHDR', ihdr), pedaco('IDAT', zlib.deflateSync(bruto)), pedaco('IEND', Buffer.alloc(0)),
  ]));
}

// ---------------------------------------------------------------- paleta
//
// As cores do desenho, como foram pintadas: cada uma é uma classe. A tolerância
// separa cor de verdade de mistura de borda (anti-aliasing) e de texto.

const PALETA = [
  ['grama', 0x27, 0x55, 0x3F],
  ['mata', 0x6A, 0xAA, 0x50], ['mata', 0x8C, 0xD5, 0x59], ['mata', 0x9D, 0xEA, 0x5D],
  ['mata', 0xD6, 0xFF, 0xB0], ['mata', 0xA5, 0xF5, 0x5F], ['mata', 0x7B, 0xC0, 0x54],
  ['pavimento', 0xD7, 0xD5, 0xD5],
  ['asfalto', 0x54, 0x54, 0x54],
  ['vermelho', 0xFF, 0x00, 0x00],
  ['marrom', 0x75, 0x38, 0x00],
  ['cinza', 0x8E, 0x8D, 0x8D],
  ['milho', 0xFF, 0xCD, 0x5D],
  ['terra', 0xF5, 0xAF, 0x12],
  ['veiculo', 0x51, 0x70, 0xFF], ['veiculo', 0x01, 0x27, 0xD5],
  ['agua', 0x00, 0xF7, 0xFF],
];
const CLASSES = [...new Set(PALETA.map((p) => p[0]))];
const INDICE = Object.fromEntries(CLASSES.map((c, i) => [c, i]));
const TOLERANCIA = 30;
const INCERTO = -1;

const DE_PREDIO = new Set(['vermelho', 'marrom', 'cinza']);
const ABERTO = new Set(['asfalto', 'pavimento', 'terra']);

// Cor de depuração por classe (só para os PNGs de conferência).
const COR_DEPURACAO = {
  grama: [0x27, 0x55, 0x3F], gramado: [0x3a, 0x7a, 0x4a], mata: [0x6A, 0xAA, 0x50], horta: [0xa0, 0xe0, 0x70],
  pavimento: [0xD7, 0xD5, 0xD5], asfalto: [0x54, 0x54, 0x54], vermelho: [0xFF, 0, 0],
  marrom: [0x75, 0x38, 0], cinza: [0x8E, 0x8D, 0x8D], milho: [0xFF, 0xCD, 0x5D],
  terra: [0xF5, 0xAF, 0x12], veiculo: [0x51, 0x70, 0xFF], agua: [0, 0xF7, 0xFF],
};

// ---------------------------------------------------------------- recorte

/** O retângulo da imagem que não é branco: o desenho em si. */
function recorteNaoBranco(png) {
  let x0 = png.w, y0 = png.h, x1 = -1, y1 = -1;
  for (let y = 0; y < png.h; y++) for (let x = 0; x < png.w; x++) {
    const o = (y * png.w + x) * 3;
    if (png.rgb[o] > 245 && png.rgb[o + 1] > 245 && png.rgb[o + 2] > 245) continue;
    if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  return { x: x0, y: y0, w: x1 - x0 + 1, h: y1 - y0 + 1 };
}

// ------------------------------------------------------------ classificar

function classificar(png, rec) {
  const { w: W, h: H } = rec;
  const classe = new Int8Array(W * H).fill(INCERTO);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const o = ((y + rec.y) * png.w + (x + rec.x)) * 3;
    const r = png.rgb[o], g = png.rgb[o + 1], b = png.rgb[o + 2];
    let melhor = -1, perto = Infinity;
    for (let i = 0; i < PALETA.length; i++) {
      const p = PALETA[i];
      const d = Math.hypot(r - p[1], g - p[2], b - p[3]);
      if (d < perto) { perto = d; melhor = i; }
    }
    if (perto <= TOLERANCIA) classe[y * W + x] = INDICE[PALETA[melhor][0]];
  }
  return classe;
}

/** Componentes 4-conexos de pixels que passam em `aceita`, com a mesma classe. */
function rotular(classe, W, H, aceita) {
  const rotulo = new Int32Array(W * H).fill(-1);
  const componentes = [];
  const pilha = new Int32Array(W * H);
  for (let inicio = 0; inicio < W * H; inicio++) {
    if (rotulo[inicio] >= 0 || !aceita(inicio)) continue;
    const c = classe[inicio];
    const id = componentes.length;
    const pixels = [];
    let topo = 0;
    pilha[topo++] = inicio; rotulo[inicio] = id;
    while (topo > 0) {
      const i = pilha[--topo];
      pixels.push(i);
      const x = i % W, y = (i - x) / W;
      const vizinhos = [x > 0 ? i - 1 : -1, x < W - 1 ? i + 1 : -1, y > 0 ? i - W : -1, y < H - 1 ? i + W : -1];
      for (const j of vizinhos) {
        if (j < 0 || rotulo[j] >= 0 || classe[j] !== c || !aceita(j)) continue;
        rotulo[j] = id; pilha[topo++] = j;
      }
    }
    componentes.push({ id, classe: CLASSES[c], pixels });
  }
  return { rotulo, componentes };
}

/**
 * O chão continua por baixo dos veículos (15/10/2026, João: "sempre onde tem
 * um carro parado tem grama em volta mesmo que não faça sentido"): o azul do
 * carro no desenho abria um furo no pavimento, e o furo virava grama. Devolve
 * uma cópia em que cada pixel de veículo recebe a classe mais comum entre os
 * vizinhos que não são veículo, de fora para dentro, até não sobrar nenhum.
 */
function preencherVeiculos(classe, W, H) {
  const chao = Int8Array.from(classe);
  const veiculo = INDICE.veiculo;
  for (let rodada = 0; rodada < 64; rodada++) {
    const trocas = [];
    for (let i = 0; i < W * H; i++) {
      if (chao[i] !== veiculo) continue;
      const x = i % W, y = (i - x) / W;
      const votos = new Map();
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const c = chao[ny * W + nx];
        if (c < 0 || c === veiculo || DE_PREDIO.has(CLASSES[c])) continue;
        votos.set(c, (votos.get(c) || 0) + 1);
      }
      let melhor = -1, mais = 0;
      for (const [c, n] of votos) if (n > mais) { mais = n; melhor = c; }
      if (melhor >= 0) trocas.push([i, melhor]);
    }
    if (trocas.length === 0) break;
    for (const [i, c] of trocas) chao[i] = c;
  }
  return chao;
}

/** Onde o 3x3 centrado no pixel é inteiro da classe dele. */
function nucleoDe(classe, W, H) {
  const nucleo = new Uint8Array(W * H);
  for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++) {
    const i = y * W + x, c = classe[i];
    if (c < 0) continue;
    let ok = true;
    for (let dy = -1; dy <= 1 && ok; dy++) for (let dx = -1; dx <= 1; dx++) {
      if (classe[i + dy * W + dx] !== c) { ok = false; break; }
    }
    if (ok) nucleo[i] = 1;
  }
  return nucleo;
}

/**
 * Abertura morfológica (3x3) de uma classe: só fica o pixel que cabe em algum
 * 3x3 inteiro da classe. Tira traço de 1-2 px grudado numa região de verdade —
 * a borda clara de uma letra branca escrita em cima de um prédio cinza vira
 * "pavimento" e, encostada no pavimento de fora, sobreviveria à regra de
 * componente abaixo e morderia o prédio.
 */
function abrir(classe, W, H, nomeDaClasse) {
  const alvo = INDICE[nomeDaClasse];
  const nucleo = nucleoDe(classe, W, H);
  let tirados = 0;
  const fica = new Uint8Array(W * H);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const i = y * W + x;
    if (classe[i] !== alvo) continue;
    for (let dy = -1; dy <= 1 && !fica[i]; dy++) for (let dx = -1; dx <= 1; dx++) {
      const px = x + dx, py = y + dy;
      if (px < 0 || py < 0 || px >= W || py >= H) continue;
      const j = py * W + px;
      if (nucleo[j] && classe[j] === alvo) { fica[i] = 1; break; }
    }
  }
  for (let i = 0; i < W * H; i++) if (classe[i] === alvo && !fica[i]) { classe[i] = INCERTO; tirados++; }
  return tirados;
}

/**
 * Apaga texto e linha fina: todo componente confiante que não tem nenhum
 * pixel de "núcleo" (3x3 inteiro da mesma classe) é fragmento de letra ou
 * traço de 1-2 px, não região. Vira incerto e é preenchido pelo vizinho.
 */
function apagarFinos(classe, W, H) {
  const nucleo = nucleoDe(classe, W, H);
  const { componentes } = rotular(classe, W, H, (i) => classe[i] >= 0);
  let apagados = 0;
  for (const comp of componentes) {
    if (comp.pixels.some((i) => nucleo[i])) continue;
    // Veiculo nao e traco fino: a caminhonete da fazenda tem 4 px no desenho
    // e nao cabe um nucleo 3x3 nela (15/10/2026).
    if (comp.classe === 'veiculo') continue;
    for (const i of comp.pixels) classe[i] = INCERTO;
    apagados++;
  }
  return apagados;
}

/**
 * O texto branco recebe a classe do que está EM VOLTA dele, antes do
 * preenchimento genérico: "Restaurante" escrito na beira do prédio ficaria
 * com a parte de baixo das letras mais perto do pavimento de fora do que do
 * marrom de dentro, e o preenchimento pelo vizinho mais perto comeria um terço
 * do prédio. Cada letra (componente de pixel quase branco) olha um anel de 3
 * px em volta: se um prédio ocupa pelo menos 35% do anel, é dele; senão, a
 * maioria. O halo da letra (incertos a até 2 px) vai junto.
 */
function preencherTexto(png, rec, classe) {
  const { w: W, h: H } = rec;
  const branco = new Uint8Array(W * H);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const i = y * W + x;
    if (classe[i] !== INCERTO) continue;
    const o = ((y + rec.y) * png.w + (x + rec.x)) * 3;
    const r = png.rgb[o], g = png.rgb[o + 1], b = png.rgb[o + 2];
    const menor = Math.min(r, g, b), maior = Math.max(r, g, b);
    if (menor >= 205 && maior - menor <= 30) branco[i] = 1;
  }
  const visto = new Uint8Array(W * H);
  const pilha = new Int32Array(W * H);
  let letras = 0;
  for (let inicio = 0; inicio < W * H; inicio++) {
    if (!branco[inicio] || visto[inicio]) continue;
    const pixels = [];
    let topo = 0;
    pilha[topo++] = inicio; visto[inicio] = 1;
    while (topo > 0) {
      const i = pilha[--topo];
      pixels.push(i);
      const x = i % W, y = (i - x) / W;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const px = x + dx, py = y + dy;
        if (px < 0 || py < 0 || px >= W || py >= H) continue;
        const j = py * W + px;
        if (!branco[j] || visto[j]) continue;
        visto[j] = 1; pilha[topo++] = j;
      }
    }
    // o anel de 3 px em volta da letra
    const contagem = new Map();
    let total = 0;
    const halo = [];
    const vistoAnel = new Set();
    for (const i of pixels) {
      const x = i % W, y = (i - x) / W;
      for (let dy = -3; dy <= 3; dy++) for (let dx = -3; dx <= 3; dx++) {
        const px = x + dx, py = y + dy;
        if (px < 0 || py < 0 || px >= W || py >= H) continue;
        const j = py * W + px;
        if (vistoAnel.has(j)) continue;
        vistoAnel.add(j);
        if (classe[j] >= 0) { contagem.set(classe[j], (contagem.get(classe[j]) || 0) + 1); total++; }
        else if (Math.abs(dx) <= 2 && Math.abs(dy) <= 2 && !branco[j]) halo.push(j);
      }
    }
    if (total === 0) continue;
    let escolhida = -1, maior = 0, predio = -1, maiorPredio = 0;
    for (const [c, n] of contagem) {
      if (n > maior) { maior = n; escolhida = c; }
      if (DE_PREDIO.has(CLASSES[c]) && n > maiorPredio) { maiorPredio = n; predio = c; }
    }
    if (predio >= 0 && maiorPredio / total >= 0.35) escolhida = predio;
    for (const i of pixels) classe[i] = escolhida;
    for (const j of halo) classe[j] = escolhida;
    letras++;
  }
  return letras;
}

/** Todo pixel incerto recebe a classe do confiante mais perto (BFS multi-fonte). */
function preencherIncertos(classe, W, H) {
  const fila = new Int32Array(W * H);
  let cabeca = 0, cauda = 0;
  for (let i = 0; i < W * H; i++) if (classe[i] >= 0) fila[cauda++] = i;
  while (cabeca < cauda) {
    const i = fila[cabeca++];
    const x = i % W, y = (i - x) / W;
    const vizinhos = [x > 0 ? i - 1 : -1, x < W - 1 ? i + 1 : -1, y > 0 ? i - W : -1, y < H - 1 ? i + W : -1];
    for (const j of vizinhos) {
      if (j < 0 || classe[j] >= 0) continue;
      classe[j] = classe[i];
      fila[cauda++] = j;
    }
  }
}

/**
 * Componente miúdo (< 60 px) de chão ou de prédio cercado por uma classe só
 * é resto de letra (uma fonte pequena deixa pedaço de 3x3 claro dentro de um
 * prédio cinza, que sobrevive à abertura). Vira a classe que o cerca. Veículo
 * e água não entram: um carro no pavimento É miúdo e cercado.
 */
function absorverMiudos(classe, W, H) {
  const { componentes } = rotular(classe, W, H, () => true);
  let absorvidos = 0;
  for (const comp of componentes) {
    if (comp.pixels.length >= 60 || comp.classe === 'veiculo' || comp.classe === 'agua') continue;
    const dentro = new Set(comp.pixels);
    const contagem = new Map();
    let total = 0;
    for (const i of comp.pixels) {
      const x = i % W, y = (i - x) / W;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const px = x + dx, py = y + dy;
        if (px < 0 || py < 0 || px >= W || py >= H) continue;
        const j = py * W + px;
        if (dentro.has(j)) continue;
        contagem.set(classe[j], (contagem.get(classe[j]) || 0) + 1);
        total++;
      }
    }
    let melhor = -1, n = 0;
    for (const [c, k] of contagem) if (k > n) { n = k; melhor = c; }
    if (melhor < 0 || n / total < 0.8) continue;
    for (const i of comp.pixels) classe[i] = melhor;
    absorvidos++;
  }
  return absorvidos;
}

/** Distância (em passos de 4 vizinhos) de cada pixel até a classe pedida. */
function distanciaAte(classe, W, H, nomeDaClasse) {
  const alvo = INDICE[nomeDaClasse];
  const dist = new Int32Array(W * H).fill(-1);
  const fila = new Int32Array(W * H);
  let cabeca = 0, cauda = 0;
  for (let i = 0; i < W * H; i++) if (classe[i] === alvo) { dist[i] = 0; fila[cauda++] = i; }
  while (cabeca < cauda) {
    const i = fila[cabeca++];
    const x = i % W, y = (i - x) / W;
    const vizinhos = [x > 0 ? i - 1 : -1, x < W - 1 ? i + 1 : -1, y > 0 ? i - W : -1, y < H - 1 ? i + W : -1];
    for (const j of vizinhos) {
      if (j < 0 || dist[j] >= 0) continue;
      dist[j] = dist[i] + 1;
      fila[cauda++] = j;
    }
  }
  return dist;
}

// ------------------------------------------------------------- geometria

/**
 * Os laços de borda de um componente, como polígonos de canto de pixel. O
 * pixel (x, y) ocupa o quadrado [x, x+1] x [y, y+1]; cada lado sem vizinho
 * vira uma aresta orientada em sentido horário (na tela), e as arestas se
 * emendam em laços. Em vértice com duas saídas (dois pixels só se tocando na
 * diagonal) vira à direita, para cada laço ficar simples.
 */
function lacosDoComponente(pixels, W) {
  const dentro = new Set(pixels);
  const tem = (x, y) => x >= 0 && y >= 0 && x < W && dentro.has(y * W + x);
  const L = W + 1;
  const saidas = new Map(); // vértice -> [{ate, dir, usada}]
  const aresta = (de, ate, dir) => {
    if (!saidas.has(de)) saidas.set(de, []);
    saidas.get(de).push({ ate, dir, usada: false });
  };
  for (const i of pixels) {
    const x = i % W, y = (i - x) / W;
    const v = (px, py) => py * L + px;
    if (!tem(x, y - 1)) aresta(v(x, y), v(x + 1, y), 0);          // topo, para a direita
    if (!tem(x + 1, y)) aresta(v(x + 1, y), v(x + 1, y + 1), 1);  // direita, para baixo
    if (!tem(x, y + 1)) aresta(v(x + 1, y + 1), v(x, y + 1), 2);  // fundo, para a esquerda
    if (!tem(x - 1, y)) aresta(v(x, y + 1), v(x, y), 3);          // esquerda, para cima
  }
  const lacos = [];
  for (const [inicio, lista] of saidas) {
    for (const primeira of lista) {
      if (primeira.usada) continue;
      const pontos = [];
      let v = inicio, a = primeira;
      for (;;) {
        a.usada = true;
        pontos.push([v % L, Math.floor(v / L), a.dir]);
        v = a.ate;
        if (v === inicio) break;
        const candidatas = (saidas.get(v) || []).filter((c) => !c.usada);
        if (candidatas.length === 0) break;
        // vira à direita, senão segue reto, senão vira à esquerda
        const pref = [(a.dir + 1) % 4, a.dir, (a.dir + 3) % 4];
        a = candidatas.sort((p, q) => pref.indexOf(p.dir) - pref.indexOf(q.dir))[0];
      }
      // tira os vértices colineares (mesma direção antes e depois)
      const cantos = [];
      for (let k = 0; k < pontos.length; k++) {
        const antes = pontos[(k - 1 + pontos.length) % pontos.length];
        if (antes[2] !== pontos[k][2]) cantos.push([pontos[k][0], pontos[k][1]]);
      }
      if (cantos.length >= 3) lacos.push(cantos);
    }
  }
  return lacos;
}

function areaAssinada(pontos) {
  let s = 0;
  for (let i = 0; i < pontos.length; i++) {
    const a = pontos[i], b = pontos[(i + 1) % pontos.length];
    s += a[0] * b[1] - b[0] * a[1];
  }
  return s / 2;
}

/** Douglas-Peucker para polilinha aberta. */
function simplificarAberta(pontos, tolerancia) {
  if (pontos.length <= 2) return pontos;
  const a = pontos[0], b = pontos[pontos.length - 1];
  let longe = -1, indice = -1;
  const dx = b[0] - a[0], dy = b[1] - a[1];
  const comprimento = Math.hypot(dx, dy);
  for (let i = 1; i < pontos.length - 1; i++) {
    const p = pontos[i];
    const d = comprimento === 0 ? Math.hypot(p[0] - a[0], p[1] - a[1])
      : Math.abs(dy * p[0] - dx * p[1] + b[0] * a[1] - b[1] * a[0]) / comprimento;
    if (d > longe) { longe = d; indice = i; }
  }
  if (longe <= tolerancia) return [a, b];
  const esquerda = simplificarAberta(pontos.slice(0, indice + 1), tolerancia);
  const direita = simplificarAberta(pontos.slice(indice), tolerancia);
  return esquerda.slice(0, -1).concat(direita);
}

/** Douglas-Peucker para laço fechado: parte no ponto mais longe do primeiro. */
function simplificarLaco(pontos, tolerancia) {
  if (pontos.length <= 4) return pontos;
  let longe = -1, k = 0;
  for (let i = 1; i < pontos.length; i++) {
    const d = Math.hypot(pontos[i][0] - pontos[0][0], pontos[i][1] - pontos[0][1]);
    if (d > longe) { longe = d; k = i; }
  }
  const a = simplificarAberta(pontos.slice(0, k + 1), tolerancia);
  const b = simplificarAberta(pontos.slice(k).concat([pontos[0]]), tolerancia);
  const fora = a.slice(0, -1).concat(b.slice(0, -1));
  return fora.length >= 3 ? fora : pontos;
}

function bboxDe(pixels, W) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const i of pixels) {
    const x = i % W, y = (i - x) / W;
    if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  return { x: x0, y: y0, w: x1 - x0 + 1, h: y1 - y0 + 1 };
}

function centroide(pixels, W) {
  let sx = 0, sy = 0;
  for (const i of pixels) { const x = i % W; sx += x + 0.5; sy += (i - x) / W + 0.5; }
  return [sx / pixels.length, sy / pixels.length];
}

/** Envoltória convexa (Andrew). */
function envoltoria(pontos) {
  const p = pontos.slice().sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  if (p.length < 3) return p;
  const cruz = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  const baixo = [];
  for (const q of p) { while (baixo.length >= 2 && cruz(baixo[baixo.length - 2], baixo[baixo.length - 1], q) <= 0) baixo.pop(); baixo.push(q); }
  const cima = [];
  for (let i = p.length - 1; i >= 0; i--) { const q = p[i]; while (cima.length >= 2 && cruz(cima[cima.length - 2], cima[cima.length - 1], q) <= 0) cima.pop(); cima.push(q); }
  return baixo.slice(0, -1).concat(cima.slice(0, -1));
}

/** O retângulo de menor área que envolve os pontos (rotating calipers por aresta da envoltória). */
function menorRetangulo(pontos) {
  const env = envoltoria(pontos);
  let melhor = { area: 0, largura: 0, altura: 0, angulo: 0 };
  if (env.length < 3) return melhor;
  for (let i = 0; i < env.length; i++) {
    const a = env[i], b = env[(i + 1) % env.length];
    const ang = Math.atan2(b[1] - a[1], b[0] - a[0]);
    const c = Math.cos(ang), s = Math.sin(ang);
    let u0 = Infinity, u1 = -Infinity, v0 = Infinity, v1 = -Infinity;
    for (const p of env) {
      const u = p[0] * c + p[1] * s, v = -p[0] * s + p[1] * c;
      if (u < u0) u0 = u; if (u > u1) u1 = u; if (v < v0) v0 = v; if (v > v1) v1 = v;
    }
    const area = (u1 - u0) * (v1 - v0);
    if (melhor.area === 0 || area < melhor.area) melhor = { area, largura: u1 - u0, altura: v1 - v0, angulo: ang };
  }
  return melhor;
}

/** O maior retângulo axial só de 1s numa máscara local (método do histograma). */
function maiorRetangulo(mascara, w, h) {
  const altura = new Int32Array(w);
  let melhor = { area: 0 };
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) altura[x] = mascara[y * w + x] ? altura[x] + 1 : 0;
    const pilha = [];
    for (let x = 0; x <= w; x++) {
      const hx = x < w ? altura[x] : 0;
      let inicio = x;
      while (pilha.length && pilha[pilha.length - 1][1] > hx) {
        const [xi, hi] = pilha.pop();
        const area = hi * (x - xi);
        if (area > melhor.area) melhor = { area, x: xi, y: y - hi + 1, w: x - xi, h: hi };
        inicio = xi;
      }
      pilha.push([inicio, hx]);
    }
  }
  return melhor.area > 0 ? melhor : null;
}

/**
 * Um prédio como um ou mais retângulos axiais. Três jeitos de cortar, e o
 * que cobre mais da mancha (menos o que sobra para fora dela) ganha:
 *  - axial: os maiores retângulos inscritos, um atrás do outro;
 *  - girado: a mancha é um retângulo torto - vira um reto do mesmo tamanho,
 *    centrado no mesmo lugar (sobra um pouco para fora, de propósito);
 *  - girado em L: corta no referencial torto e desgira cada pedaço.
 */
function retangulosDoPredio(comp, W, lacoExterno, opcoes) {
  const bb = comp.bbox;
  const area = comp.pixels.length;
  const mascara = new Uint8Array(bb.w * bb.h);
  for (const i of comp.pixels) { const x = i % W, y = (i - x) / W; mascara[(y - bb.y) * bb.w + (x - bb.x)] = 1; }
  const dentroDaMancha = (x, y) => x >= bb.x && y >= bb.y && x < bb.x + bb.w && y < bb.y + bb.h && mascara[(y - bb.y) * bb.w + (x - bb.x)] === 1;
  // quanto dos retângulos cai dentro da mancha, menos o que cai fora
  const pontuar = (rects) => {
    let dentro = 0, fora = 0;
    for (const r of rects) {
      for (let y = Math.floor(r.y); y < Math.ceil(r.y + r.h); y++) for (let x = Math.floor(r.x); x < Math.ceil(r.x + r.w); x++) {
        if (dentroDaMancha(x, y)) dentro++; else fora++;
      }
    }
    return dentro - fora;
  };
  const candidatos = [];

  // axial
  {
    const m = mascara.slice();
    const rects = [];
    let coberto = 0;
    while (rects.length < opcoes.maximo) {
      const r = maiorRetangulo(m, bb.w, bb.h);
      const minimo = rects.length === 0 ? opcoes.ladoMinimo : opcoes.ladoMinimoDoAnexo;
      if (!r || r.w < minimo || r.h < minimo) break;
      rects.push({ x: bb.x + r.x, y: bb.y + r.y, w: r.w, h: r.h });
      for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) m[y * bb.w + x] = 0;
      coberto += r.area;
      if (coberto / area >= opcoes.cobertura) break;
    }
    if (rects.length) candidatos.push({ modo: rects.length > 1 ? 'partido' : 'axial', graus: 0, rects });
  }

  const mr = menorRetangulo(lacoExterno);
  const grau = ((mr.angulo * 180 / Math.PI) % 90 + 90) % 90;
  const torto = grau > 7 && grau < 83 && mr.area > 0;
  if (torto) {
    // girado: um só, do tamanho do menor retângulo, no centroide
    const c = comp.centroide;
    const la = Math.max(mr.largura, mr.altura), lb = Math.min(mr.largura, mr.altura);
    const [w, h] = bb.w >= bb.h ? [la, lb] : [lb, la];
    candidatos.push({ modo: 'girado', graus: +grau.toFixed(1), rects: [{ x: c[0] - w / 2, y: c[1] - h / 2, w, h }] });

    // girado em L: corta no referencial torto e desgira cada pedaço
    const cs = Math.cos(-mr.angulo), sn = Math.sin(-mr.angulo);
    const gira = (x, y) => [x * cs - y * sn, x * sn + y * cs];
    const desgira = (u, v) => [u * Math.cos(mr.angulo) - v * Math.sin(mr.angulo), u * Math.sin(mr.angulo) + v * Math.cos(mr.angulo)];
    let u0 = Infinity, v0 = Infinity, u1 = -Infinity, v1 = -Infinity;
    const amostras = [];
    for (const i of comp.pixels) {
      const x = i % W, y = (i - x) / W;
      for (const [dx, dy] of [[0.25, 0.25], [0.75, 0.25], [0.25, 0.75], [0.75, 0.75]]) {
        const [u, v] = gira(x + dx, y + dy);
        amostras.push([u, v]);
        if (u < u0) u0 = u; if (u > u1) u1 = u; if (v < v0) v0 = v; if (v > v1) v1 = v;
      }
    }
    const gw = Math.ceil(u1 - u0) + 1, gh = Math.ceil(v1 - v0) + 1;
    const m = new Uint8Array(gw * gh);
    for (const [u, v] of amostras) m[Math.floor(v - v0) * gw + Math.floor(u - u0)] = 1;
    const rects = [];
    let coberto = 0;
    const deitado = Math.abs(((mr.angulo * 180 / Math.PI) % 180 + 180) % 180 - 90) > 45;
    while (rects.length < 2) {
      const r = maiorRetangulo(m, gw, gh);
      const minimo = rects.length === 0 ? opcoes.ladoMinimo : opcoes.ladoMinimoDoAnexo;
      if (!r || r.w < minimo || r.h < minimo) break;
      for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) m[y * gw + x] = 0;
      const centro = desgira(u0 + r.x + r.w / 2, v0 + r.y + r.h / 2);
      const [w, h] = deitado ? [r.w, r.h] : [r.h, r.w];
      const novo = { x: centro[0] - w / 2, y: centro[1] - h / 2, w, h };
      const pisa = rects.some((q) => novo.x < q.x + q.w && q.x < novo.x + novo.w && novo.y < q.y + q.h && q.y < novo.y + novo.h);
      if (pisa) break;
      rects.push(novo);
      coberto += r.area;
      if (coberto / area >= opcoes.cobertura) break;
    }
    if (rects.length) candidatos.push({ modo: 'girado em L', graus: +grau.toFixed(1), rects });
  }

  if (candidatos.length === 0) return { modo: 'nenhum', graus: 0, rects: [] };
  for (const c of candidatos) c.nota = pontuar(c.rects);
  candidatos.sort((a, b) => b.nota - a.nota);
  return candidatos[0];
}

/** Para que lado a porta olha: o lado com mais chão aberto logo na frente; empate decide pelo asfalto mais perto. */
function ladoDaPorta(rect, classe, distAsfalto, W, H) {
  const lados = { norte: [], sul: [], leste: [], oeste: [] };
  const x0 = Math.round(rect.x), y0 = Math.round(rect.y);
  const x1 = Math.round(rect.x + rect.w) - 1, y1 = Math.round(rect.y + rect.h) - 1;
  const FAIXA = 10;
  for (let k = 1; k <= FAIXA; k++) {
    for (let x = x0; x <= x1; x++) { lados.norte.push([x, y0 - k]); lados.sul.push([x, y1 + k]); }
    for (let y = y0; y <= y1; y++) { lados.oeste.push([x0 - k, y]); lados.leste.push([x1 + k, y]); }
  }
  let melhor = null;
  for (const [lado, celulas] of Object.entries(lados)) {
    let abertos = 0, bloqueados = 0, perto = Infinity, validas = 0;
    for (const [x, y] of celulas) {
      // fora do desenho conta como bloqueado: porta virada para a borda do
      // mundo e porta para o nada
      if (x < 0 || y < 0 || x >= W || y >= H) { validas++; bloqueados++; continue; }
      validas++;
      const c = CLASSES[classe[y * W + x]];
      if (ABERTO.has(c)) abertos++;
      if (DE_PREDIO.has(c) || c === 'agua') bloqueados++;
      const d = distAsfalto[y * W + x];
      if (d >= 0 && d < perto) perto = d;
    }
    if (validas === 0) continue;
    const nota = abertos / validas - 2 * (bloqueados / validas) - perto / 400;
    if (!melhor || nota > melhor.nota) melhor = { lado, nota };
  }
  return melhor ? melhor.lado : 'sul';
}

// ------------------------------------------------------------------ main

function formatar(obj) {
  const linhas = ['{'];
  linhas.push(`"origem": ${JSON.stringify(obj.origem)},`);
  linhas.push(`"recorte": ${JSON.stringify(obj.recorte)},`);
  linhas.push(`"classes": ${JSON.stringify(obj.classes)},`);
  const chaves = ['poligonos', 'predios', 'obstaculos', 'veiculos'];
  chaves.forEach((chave, k) => {
    linhas.push(`"${chave}": [`);
    obj[chave].forEach((e, i) => linhas.push(JSON.stringify(e) + (i < obj[chave].length - 1 ? ',' : '')));
    linhas.push(`]${k < chaves.length - 1 ? ',' : ''}`);
  });
  linhas.push('}');
  return linhas.join('\n') + '\n';
}

function principal() {
  const png = lerPng(ENTRADA);
  const rec = recorteNaoBranco(png);
  const { w: W, h: H } = rec;
  console.error(`desenho: ${png.w}x${png.h}, recorte ${rec.w}x${rec.h} em (${rec.x}, ${rec.y})`);

  const classe = classificar(png, rec);
  let incertos = 0;
  for (let i = 0; i < W * H; i++) if (classe[i] < 0) incertos++;
  console.error(`classificados: ${W * H - incertos} confiantes, ${incertos} incertos (texto, borda, linha)`);
  const abertos = abrir(classe, W, H, 'pavimento');
  const apagados = apagarFinos(classe, W, H);
  console.error(`apagados ${abertos} px de traço fino de pavimento e ${apagados} fragmentos finos (texto e linha)`);
  const letras = preencherTexto(png, rec, classe);
  console.error(`${letras} letras e traços brancos preenchidos pelo que está em volta`);
  preencherIncertos(classe, W, H);
  const absorvidos = absorverMiudos(classe, W, H);
  console.error(`${absorvidos} componentes miúdos absorvidos pela classe em volta`);

  const distAsfalto = distanciaAte(classe, W, H, 'asfalto');

  // Veículos e prédios saem da classificação como está; o chão sai de uma
  // cópia em que o veículo não existe (ver preencherVeiculos), para o
  // pavimento passar inteiro por baixo do carro.
  const { componentes: componentesComoEsta } = rotular(classe, W, H, () => true);
  const classeChao = preencherVeiculos(classe, W, H);
  const { componentes: componentesDoChao } = rotular(classeChao, W, H, () => true);
  const eDeCima = (c) => c.classe === 'veiculo' || DE_PREDIO.has(c.classe);
  const componentes = componentesComoEsta.filter(eDeCima).concat(componentesDoChao.filter((c) => !eDeCima(c)));
  console.error(`${componentes.length} componentes (${componentesComoEsta.length} como está, chão sem veículo: ${componentesDoChao.length})`);

  const poligonos = [], predios = [], obstaculos = [], veiculos = [];
  let maiorGrama = null;
  for (const comp of componentes) {
    comp.bbox = bboxDe(comp.pixels, W);
    comp.centroide = centroide(comp.pixels, W);
    if (comp.classe === 'grama' && (!maiorGrama || comp.pixels.length > maiorGrama.pixels.length)) maiorGrama = comp;
  }

  const TOLERANCIA_DO_TRACO = 0.75;
  // O chão feito pelo homem (calçada, rua, gramado de lote) sai com traço
  // reto: o desenho é pixel a pixel e a diagonal vira escada de 1 px, que a
  // tolerância de 0,75 não alisa (15/10/2026, João: "as ruas na diagonal
  // estão todas tortas"). A tolerância maior come só a escada e as
  // lasquinhas; esquinas de verdade ficam, porque se afastam muito da corda.
  // Mata, terra, milho, água e horta continuam no traço fino: são
  // naturais, e no jogo viram tile, não polígono.
  const TOLERANCIA_DO_TRACO_RETO = 1.6;
  const TRACO_RETO = new Set(['pavimento', 'asfalto', 'grama']);
  const LADO_MINIMO_DE_PREDIO = 9;      // px do desenho: abaixo disso é bloco sólido, não prédio
  const AREA_MINIMA_DE_PREDIO = 110;

  for (const comp of componentes) {
    const area = comp.pixels.length;
    if (area < 3) continue;
    const lacos = lacosDoComponente(comp.pixels, W)
      .map((l) => ({ pontos: l, area: Math.abs(areaAssinada(l)) }))
      .sort((a, b) => b.area - a.area);
    if (lacos.length === 0) continue;
    const externo = lacos[0].pontos;
    const tolerancia = TRACO_RETO.has(comp.classe) ? TOLERANCIA_DO_TRACO_RETO : TOLERANCIA_DO_TRACO;
    const furos = lacos.slice(1).filter((l) => l.area >= 6).map((l) => simplificarLaco(l.pontos, tolerancia));
    const pontos = simplificarLaco(externo, tolerancia);
    const registro = {
      classe: comp.classe, area, bbox: [comp.bbox.x, comp.bbox.y, comp.bbox.w, comp.bbox.h],
      centro: comp.centroide.map((v) => +v.toFixed(1)), pontos, furos,
    };

    if (comp.classe === 'veiculo') {
      // 3 px bastam (15/10/2026): as caminhonetes da fazenda e do galpao do
      // velho louco tem 4 ou 5 px no desenho e nao passavam em 6.
      if (area < 3) continue;
      const comprido = Math.max(comp.bbox.w, comp.bbox.h) >= 15;
      veiculos.push({ pos: registro.centro, bbox: registro.bbox, deitado: comp.bbox.w >= comp.bbox.h, comprido });
      continue;
    }
    if (DE_PREDIO.has(comp.classe)) {
      const ondeNoPng = Math.round(comp.centroide[0] + rec.x) + ',' + Math.round(comp.centroide[1] + rec.y);
      if (Math.min(comp.bbox.w, comp.bbox.h) < LADO_MINIMO_DE_PREDIO || area < AREA_MINIMA_DE_PREDIO) {
        console.error('bloco solido em ' + ondeNoPng + ' (' + comp.bbox.w + 'x' + comp.bbox.h + ', ' + area + ' px): pequeno demais para predio');
        obstaculos.push({ classe: comp.classe, rect: registro.bbox, centro: registro.centro });
        continue;
      }
      // Mancha pequena e torta (a barraca do vendedor de melancia, a segunda
      // casa abandonada) aceita um retangulo que cubra menos: e um comodo so,
      // e o erro de um canto nao aparece (15/10/2026).
      // O lado minimo nao afrouxa nem para a mancha pequena: 9 px sao os 200
      // de frente que o jogo exige de um predio (conferir_mapa reprova menos).
      const pequena = area < 200;
      let partes = retangulosDoPredio(comp, W, externo, {
        ladoMinimo: LADO_MINIMO_DE_PREDIO, ladoMinimoDoAnexo: 11, cobertura: pequena ? 0.6 : 0.85, maximo: 4,
      });
      if (partes.rects.length === 0 && pequena && area / (comp.bbox.w * comp.bbox.h) >= 0.6) {
        // Mancha pequena e torta que enche a propria caixa (a barraca do
        // vendedor de melancia, desenhada inclinada): a caixa serve de predio
        // de um comodo so - melhor que virar bloco sem nome (15/10/2026).
        partes = { modo: 'caixa', graus: 0, rects: [{ x: comp.bbox.x, y: comp.bbox.y, w: comp.bbox.w, h: comp.bbox.h }] };
      }
      if (partes.rects.length === 0) {
        console.error('bloco solido em ' + ondeNoPng + ' (' + comp.bbox.w + 'x' + comp.bbox.h + ', ' + area + ' px): nenhum retangulo cobre a mancha');
        obstaculos.push({ classe: comp.classe, rect: registro.bbox, centro: registro.centro });
        continue;
      }
      registro.modo = partes.modo;
      registro.graus = partes.graus;
      registro.rects = partes.rects.map((r) => ({
        rect: [+r.x.toFixed(1), +r.y.toFixed(1), +r.w.toFixed(1), +r.h.toFixed(1)],
        porta: ladoDaPorta(r, classe, distAsfalto, W, H),
      }));
      predios.push(registro);
      continue;
    }
    if (comp.classe === 'grama') {
      if (comp === maiorGrama) continue;  // o fundo do mundo: a grama é pintada inteira por baixo
      registro.classe = 'gramado';
    }
    if (comp.classe === 'mata') {
      const mr = menorRetangulo(externo);
      if (area < 1500 && mr.area > 0 && area / mr.area >= 0.85) registro.classe = 'horta';
    }
    poligonos.push(registro);
  }

  poligonos.sort((a, b) => b.area - a.area);
  predios.sort((a, b) => b.area - a.area);

  const saida = {
    origem: path.basename(ENTRADA),
    recorte: [rec.x, rec.y, rec.w, rec.h],
    classes: CLASSES.concat(['gramado', 'horta']),
    poligonos, predios, obstaculos, veiculos,
  };
  fs.mkdirSync(path.dirname(SAIDA), { recursive: true });
  fs.writeFileSync(SAIDA, formatar(saida));
  const rects = predios.reduce((s, p) => s + p.rects.length, 0);
  console.error(`${poligonos.length} polígonos de chão, ${predios.length} prédios (${rects} retângulos), ${obstaculos.length} blocos sólidos, ${veiculos.length} veículos`);
  console.error(`escrito ${SAIDA}`);

  if (DEPURACAO) depurar(classe, W, H, poligonos, predios, obstaculos, veiculos);
}

function depurar(classe, W, H, poligonos, predios, obstaculos, veiculos) {
  fs.mkdirSync(DEPURACAO, { recursive: true });
  const rgb = Buffer.alloc(W * H * 3);
  for (let i = 0; i < W * H; i++) {
    const c = COR_DEPURACAO[CLASSES[classe[i]]] || [255, 0, 255];
    rgb[i * 3] = c[0]; rgb[i * 3 + 1] = c[1]; rgb[i * 3 + 2] = c[2];
  }
  escreverPng(path.join(DEPURACAO, 'classes.png'), W, H, rgb);

  // Os retângulos de prédio por cima, com a porta marcada em magenta.
  const ponto = (x, y, cor) => {
    const px = Math.round(x), py = Math.round(y);
    if (px < 0 || py < 0 || px >= W || py >= H) return;
    const o = (py * W + px) * 3; rgb[o] = cor[0]; rgb[o + 1] = cor[1]; rgb[o + 2] = cor[2];
  };
  const linha = (a, b, cor) => {
    const n = Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1])) * 2 + 1;
    for (let k = 0; k <= n; k++) ponto(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n, cor);
  };
  const caixa = (r, cor) => {
    linha([r[0], r[1]], [r[0] + r[2], r[1]], cor); linha([r[0] + r[2], r[1]], [r[0] + r[2], r[1] + r[3]], cor);
    linha([r[0] + r[2], r[1] + r[3]], [r[0], r[1] + r[3]], cor); linha([r[0], r[1] + r[3]], [r[0], r[1]], cor);
  };
  for (const p of poligonos) {
    const cor = p.classe === 'gramado' ? [120, 220, 140] : p.classe === 'horta' ? [230, 255, 120] : [255, 255, 255];
    for (let i = 0; i < p.pontos.length; i++) linha(p.pontos[i], p.pontos[(i + 1) % p.pontos.length], cor);
    for (const f of p.furos) for (let i = 0; i < f.length; i++) linha(f[i], f[(i + 1) % f.length], [255, 128, 255]);
  }
  for (const p of predios) for (const r of p.rects) {
    caixa(r.rect, [255, 255, 0]);
    const [x, y, w, h] = r.rect;
    const marca = { norte: [x + w * 0.35, y], sul: [x + w * 0.35, y + h], leste: [x + w, y + h * 0.35], oeste: [x, y + h * 0.35] }[r.porta];
    for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) ponto(marca[0] + dx, marca[1] + dy, [255, 0, 255]);
  }
  for (const o of obstaculos) caixa(o.rect, [255, 120, 0]);
  for (const v of veiculos) caixa(v.bbox, [0, 255, 255]);
  escreverPng(path.join(DEPURACAO, 'tracado.png'), W, H, rgb);
  console.error(`depuração em ${DEPURACAO}`);
}

principal();
