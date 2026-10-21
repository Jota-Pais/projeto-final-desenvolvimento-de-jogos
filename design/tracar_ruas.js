#!/usr/bin/env node
'use strict';
/**
 * As ruas e o chão da cidade refeitos por regra a partir do desenho
 * (21/10/2026). Escreve rua/chao_da_cidade.json, que o rua/ruas.gd pinta.
 *
 * Pedido do João: "as ruas precisam de um olhar mais detalhado, algumas tão
 * meio tortas e sem sentido, calçadas não tão seguindo uma proporção".
 * Questionário: o cinza claro vira calçada de largura fixa e o resto por
 * lugar; as ruas seguem o desenho (borda reta, largura constante, esquina com
 * raio, rotatória redonda); asfalto sem xadrez, meio-fio de concreto, calçada
 * gasta e o fim do mundo coberto; vale para o mapa inteiro.
 *
 * Por que daqui: o desenho (design/urussanga.png) é no estilo de mapa de
 * celular, e nele o cinza claro NÃO é calçada - é a cidade em volta, com lote,
 * quintal e terreno vazio dentro. O traçado (design/tracar_desenho.js) o
 * entrega inteiro como "pavimento", e o jogo o pintava inteiro de lajota: casa
 * no meio de um mar de calçada, calçada de 1,5 m num lado da rua e de 30 m no
 * outro. E a rua, que no desenho é uma faixa reta de largura certa, saía do
 * polígono traçado com dente, degrau e rotatória de oito lados.
 *
 * Então, em três passos:
 *
 *  1. as ruas: o eixo de cada uma (o esqueleto do asfalto do desenho) com a
 *     largura dela (a mediana da distância até a borda), cada trecho reto; a
 *     rotatória é o anel em volta da ilha redonda;
 *  2. a rua refeita numa grade fina (GRADE px de mundo por célula), com o raio
 *     de meio-fio nas esquinas (fechamento morfológico de RAIO_DA_ESQUINA);
 *  3. o cinza claro (e o asfalto do desenho que a rua refeita não cobriu)
 *     vira calçada até LARGURA_DA_CALCADA da rua, e o que sobra é dividido
 *     pelo prédio mais perto (até ALCANCE_DO_PREDIO): quintal, pátio ou
 *     terreno baldio - qual é cada um decide o jogo, que sabe o tipo do
 *     prédio (rua/ruas.gd).
 *
 * Cada camada sai como triângulos (o polígono com furo já resolvido), em px
 * do recorte do desenho, como o mapa_tracado.json.
 *
 *   node design/tracar_ruas.js [entrada.png] [saida.json] [pasta-de-depuracao]
 */
const fs = require('fs');
const path = require('path');
const T = require('./tracar_desenho.js');
const { earcut } = require('./earcut.js');

const ENTRADA = process.argv[2] || path.join(__dirname, 'urussanga.png');
const SAIDA = process.argv[3] || path.join(__dirname, '..', 'rua', 'chao_da_cidade.json');
const DEPURACAO = process.argv[4] || '';

// ------------------------------------------------------------ distância

/** Distância euclidiana exata (Felzenszwalb) de cada célula até a mais perto
 *  em que `alvo` é verdade. */
function distancia(alvo, W, H) {
  const INF = 1e12;
  const f = new Float64Array(Math.max(W, H));
  const d = new Float64Array(Math.max(W, H));
  const v = new Int32Array(Math.max(W, H));
  const z = new Float64Array(Math.max(W, H) + 1);
  const g = new Float64Array(W * H);
  for (let i = 0; i < W * H; i++) g[i] = alvo[i] ? 0 : INF;
  const passar = (n) => {
    let k = 0; v[0] = 0; z[0] = -INF; z[1] = INF;
    for (let q = 1; q < n; q++) {
      let s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
      while (s <= z[k]) { k--; s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]); }
      k++; v[k] = q; z[k] = s; z[k + 1] = INF;
    }
    k = 0;
    for (let q = 0; q < n; q++) {
      while (z[k + 1] < q) k++;
      d[q] = (q - v[k]) * (q - v[k]) + f[v[k]];
    }
  };
  for (let x = 0; x < W; x++) {
    for (let y = 0; y < H; y++) f[y] = g[y * W + x];
    passar(H);
    for (let y = 0; y < H; y++) g[y * W + x] = d[y];
  }
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) f[x] = g[y * W + x];
    passar(W);
    for (let x = 0; x < W; x++) g[y * W + x] = Math.sqrt(d[x]);
  }
  return g;
}

// ----------------------------------------------------------- esqueleto

/** Afinamento de Zhang-Suen: a máscara vira linha de 1 px no meio. */
function afinar(m, W, H) {
  const s = Uint8Array.from(m);
  let mudou = true;
  const vizinhos = (i) => {
    const x = i % W, y = (i - x) / W;
    const g = (dx, dy) => {
      const nx = x + dx, ny = y + dy;
      return nx < 0 || ny < 0 || nx >= W || ny >= H ? 0 : s[ny * W + nx];
    };
    return [g(0, -1), g(1, -1), g(1, 0), g(1, 1), g(0, 1), g(-1, 1), g(-1, 0), g(-1, -1)];
  };
  while (mudou) {
    mudou = false;
    for (const passo of [0, 1]) {
      const tirar = [];
      for (let i = 0; i < W * H; i++) {
        if (!s[i]) continue;
        const p = vizinhos(i);
        const b = p.reduce((a, c) => a + c, 0);
        if (b < 2 || b > 6) continue;
        let a = 0;
        for (let k = 0; k < 8; k++) if (p[k] === 0 && p[(k + 1) % 8] === 1) a++;
        if (a !== 1) continue;
        if (passo === 0 && (p[0] * p[2] * p[4] !== 0 || p[2] * p[4] * p[6] !== 0)) continue;
        if (passo === 1 && (p[0] * p[2] * p[6] !== 0 || p[0] * p[4] * p[6] !== 0)) continue;
        tirar.push(i);
      }
      for (const i of tirar) s[i] = 0;
      if (tirar.length) mudou = true;
    }
  }
  return s;
}

const VIZ8 = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]];

/**
 * O esqueleto como grafo: nós (ponta ou cruzamento, os pixels de cruzamento
 * vizinhos juntos num nó só) e trechos (a fila de pixels entre dois nós).
 */
function grafo(s, W, H) {
  const grau = new Uint8Array(W * H);
  const viz = (i) => {
    const x = i % W, y = (i - x) / W, fora = [];
    for (const [dx, dy] of VIZ8) {
      const nx = x + dx, ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < W && ny < H && s[ny * W + nx]) fora.push(ny * W + nx);
    }
    return fora;
  };
  for (let i = 0; i < W * H; i++) if (s[i]) grau[i] = viz(i).length;
  // Nós: grau diferente de 2; vizinhos de cruzamento viram um nó só.
  const no = new Int32Array(W * H).fill(-1);
  const nos = [];
  for (let i = 0; i < W * H; i++) {
    if (!s[i] || grau[i] === 2 || no[i] >= 0) continue;
    const id = nos.length, pixels = [], pilha = [i];
    no[i] = id;
    while (pilha.length) {
      const j = pilha.pop();
      pixels.push(j);
      for (const k of viz(j)) if (grau[k] !== 2 && no[k] < 0) { no[k] = id; pilha.push(k); }
    }
    let sx = 0, sy = 0;
    for (const j of pixels) { sx += j % W; sy += (j - (j % W)) / W; }
    nos.push({ id, pixels, x: sx / pixels.length, y: sy / pixels.length });
  }
  // Trechos: de cada pixel de nó, cada vizinho de grau 2 abre uma fila.
  const visto = new Uint8Array(W * H);
  const trechos = [];
  for (const n of nos) {
    for (const p of n.pixels) for (const v of viz(p)) {
      if (no[v] >= 0 || visto[v]) continue;
      const fila = [p, v];
      visto[v] = 1;
      let atual = v, antes = p, fim = -1;
      for (;;) {
        const prox = viz(atual).filter((k) => k !== antes && !(no[k] < 0 && visto[k]));
        const chegou = prox.find((k) => no[k] >= 0 && !n.pixels.includes(k) || (no[k] >= 0 && fila.length > 3));
        if (chegou !== undefined) { fila.push(chegou); fim = no[chegou]; break; }
        const segue = prox.find((k) => no[k] < 0);
        if (segue === undefined) break;
        visto[segue] = 1; fila.push(segue); antes = atual; atual = segue;
      }
      if (fim < 0) continue;
      trechos.push({ de: n.id, ate: fim, pixels: fila });
    }
  }
  // O mesmo trecho achado dos dois lados: fica um.
  const unicos = [], chaves = new Set();
  for (const t of trechos) {
    const meio = t.pixels[t.pixels.length >> 1];
    const chave = [Math.min(t.de, t.ate), Math.max(t.de, t.ate), meio].join(':');
    const outra = [Math.min(t.de, t.ate), Math.max(t.de, t.ate), t.pixels[(t.pixels.length - 1) >> 1]].join(':');
    if (chaves.has(chave) || chaves.has(outra)) continue;
    chaves.add(chave);
    unicos.push(t);
  }
  return { nos, trechos: unicos };
}

// ------------------------------------------------------------- traço

function simplificar(pontos, tolerancia) {
  if (pontos.length < 3) return pontos.slice();
  const [a, b] = [pontos[0], pontos[pontos.length - 1]];
  let pior = -1, longe = 0;
  const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy) || 1e-9;
  for (let i = 1; i < pontos.length - 1; i++) {
    const d = Math.abs((pontos[i][0] - a[0]) * dy - (pontos[i][1] - a[1]) * dx) / L;
    if (d > longe) { longe = d; pior = i; }
  }
  if (longe <= tolerancia) return [a, b];
  return simplificar(pontos.slice(0, pior + 1), tolerancia).slice(0, -1).concat(simplificar(pontos.slice(pior), tolerancia));
}

const mediana = (v) => { const s = v.slice().sort((a, b) => a - b); return s.length ? s[s.length >> 1] : 0; };

/** A reta que melhor passa pelos pontos (mínimos quadrados total): um ponto
 *  dela e a direção. */
function retaPor(pontos) {
  let mx = 0, my = 0;
  for (const p of pontos) { mx += p[0]; my += p[1]; }
  mx /= pontos.length; my /= pontos.length;
  let sxx = 0, syy = 0, sxy = 0;
  for (const p of pontos) { const dx = p[0] - mx, dy = p[1] - my; sxx += dx * dx; syy += dy * dy; sxy += dx * dy; }
  const a = 0.5 * Math.atan2(2 * sxy, sxx - syy);
  return { p: [mx, my], d: [Math.cos(a), Math.sin(a)] };
}

function cruzar(r1, r2) {
  const det = r1.d[0] * r2.d[1] - r1.d[1] * r2.d[0];
  if (Math.abs(det) < 1e-6) return null;
  const t = ((r2.p[0] - r1.p[0]) * r2.d[1] - (r2.p[1] - r1.p[1]) * r2.d[0]) / det;
  return [r1.p[0] + r1.d[0] * t, r1.p[1] + r1.d[1] * t];
}

function projetar(r, q) {
  const t = (q[0] - r.p[0]) * r.d[0] + (q[1] - r.p[1]) * r.d[1];
  return [r.p[0] + r.d[0] * t, r.p[1] + r.d[1] * t];
}

/**
 * O eixo reto de um trecho: a escada de pixels vira poucos segmentos (corda
 * com TOLERANCIA_DO_EIXO), e cada segmento é a reta que melhor passa pelos
 * pixels dele - no desenho a rua é reta, e 1 px do desenho são 24 px de
 * mundo: um degrau de pixel viraria um dente na rua. Os vértices são o
 * cruzamento das retas vizinhas; as pontas ficam onde estavam (o nó).
 */
const TOLERANCIA_DO_EIXO = 2.5;
function eixoReto(pontos) {
  const marcos = [];
  const corda = (i, j) => {
    const [a, b] = [pontos[i], pontos[j]];
    const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy) || 1e-9;
    let pior = -1, longe = 0;
    for (let k = i + 1; k < j; k++) {
      const d = Math.abs((pontos[k][0] - a[0]) * dy - (pontos[k][1] - a[1]) * dx) / L;
      if (d > longe) { longe = d; pior = k; }
    }
    if (longe > TOLERANCIA_DO_EIXO) { corda(i, pior); corda(pior, j); } else marcos.push([i, j]);
  };
  corda(0, pontos.length - 1);
  const retas = marcos.map(([i, j]) => retaPor(pontos.slice(i, j + 1)));
  const fora = [projetar(retas[0], pontos[0])];
  for (let k = 0; k + 1 < retas.length; k++) {
    const x = cruzar(retas[k], retas[k + 1]);
    const ref = pontos[marcos[k][1]];
    // Retas quase paralelas cruzam longe: fica o ponto do meio.
    fora.push(x && Math.hypot(x[0] - ref[0], x[1] - ref[1]) < 6 ? x : ref);
  }
  fora.push(projetar(retas[retas.length - 1], pontos[pontos.length - 1]));
  // As pontas voltam para o nó (o cruzamento é onde as ruas se encontram).
  fora[0] = pontos[0].slice();
  fora[fora.length - 1] = pontos[pontos.length - 1].slice();
  return fora;
}

// ---------------------------------------------------------------- ruas

function eixosDasRuas(classe, W, H) {
  const ASF = T.INDICE.asfalto;
  const m = new Uint8Array(W * H);
  for (let i = 0; i < W * H; i++) m[i] = classe[i] === ASF ? 1 : 0;
  const dentro = distancia(m.map((v) => 1 - v), W, H); // distância até o que não é asfalto

  // As ilhas: o que não é asfalto, fechado por asfalto, pequeno e redondo.
  const rotulo = new Int32Array(W * H).fill(-1);
  const ilhas = [];
  for (let i = 0; i < W * H; i++) {
    if (m[i] || rotulo[i] >= 0) continue;
    const pix = [], pilha = [i];
    rotulo[i] = i;
    let borda = false;
    while (pilha.length) {
      const j = pilha.pop();
      pix.push(j);
      const x = j % W, y = (j - x) / W;
      if (x === 0 || y === 0 || x === W - 1 || y === H - 1) borda = true;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const k = ny * W + nx;
        if (!m[k] && rotulo[k] < 0) { rotulo[k] = i; pilha.push(k); }
      }
    }
    if (borda || pix.length > 600) continue;
    let sx = 0, sy = 0, x0 = W, x1 = 0, y0 = H, y1 = 0;
    for (const j of pix) { const x = j % W, y = (j - x) / W; sx += x; sy += y; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    const raio = Math.sqrt(pix.length / Math.PI);
    const redonda = pix.length / (Math.PI * ((x1 - x0 + 1) / 2) * ((y1 - y0 + 1) / 2));
    if (redonda < 0.7 || Math.abs((x1 - x0) - (y1 - y0)) > 3) continue;
    ilhas.push({ x: sx / pix.length + 0.5, y: sy / pix.length + 0.5, raio });
  }

  const s = afinar(m, W, H);
  let { nos, trechos } = grafo(s, W, H);
  for (const t of trechos) {
    t.pontos = t.pixels.map((i) => [i % W + 0.5, (i - (i % W)) / W + 0.5]);
    t.larguras = t.pixels.map((i) => 2 * dentro[i]);
  }

  // A rotatória: o anel é o asfalto em volta da ilha. Os trechos do anel saem;
  // os que chegam nele param na beira dele.
  const rotatorias = [];
  for (const ilha of ilhas) {
    let soma = 0, n = 0;
    for (const t of trechos) t.pontos.forEach((p, k) => {
      const r = Math.hypot(p[0] - ilha.x, p[1] - ilha.y);
      if (r < ilha.raio + 8) { soma += t.larguras[k]; n++; }
    });
    const largura = n ? soma / n : 8;
    const meio = ilha.raio + largura / 2;
    rotatorias.push({ centro: [ilha.x, ilha.y], ilha: ilha.raio, fora: ilha.raio + largura });
    trechos = trechos.filter((t) => t.pontos.some((p) => Math.hypot(p[0] - ilha.x, p[1] - ilha.y) > meio + largura * 0.6));
    for (const t of trechos) {
      for (const lado of [0, 1]) {
        const ponta = lado === 0 ? 0 : t.pontos.length - 1;
        const p = t.pontos[ponta];
        const r = Math.hypot(p[0] - ilha.x, p[1] - ilha.y);
        if (r < meio + largura) {
          // Corta o trecho onde ele entra no anel e o leva até o meio do anel.
          const fora = ponta === 0 ? t.pontos.findIndex((q) => Math.hypot(q[0] - ilha.x, q[1] - ilha.y) > meio + largura * 0.6)
            : t.pontos.length - 1 - t.pontos.slice().reverse().findIndex((q) => Math.hypot(q[0] - ilha.x, q[1] - ilha.y) > meio + largura * 0.6);
          const q = t.pontos[fora];
          const a = Math.atan2(q[1] - ilha.y, q[0] - ilha.x);
          const novo = [ilha.x + Math.cos(a) * meio, ilha.y + Math.sin(a) * meio];
          if (ponta === 0) { t.pontos = [novo].concat(t.pontos.slice(fora)); t.larguras = [t.larguras[fora]].concat(t.larguras.slice(fora)); }
          else { t.pontos = t.pontos.slice(0, fora + 1).concat([novo]); t.larguras = t.larguras.slice(0, fora + 1).concat([t.larguras[fora]]); }
          t.naRotatoria = true;
        }
      }
    }
  }

  // Poda: o galho que sai de um cruzamento e morre logo (lasca da borda do
  // desenho) não é rua. Repete até parar de cair galho.
  const grauDo = () => {
    const g = new Map();
    for (const t of trechos) { g.set(t.de, (g.get(t.de) || 0) + 1); g.set(t.ate, (g.get(t.ate) || 0) + 1); }
    return g;
  };
  const naBorda = (p) => p[0] < 3 || p[1] < 3 || p[0] > W - 3 || p[1] > H - 3;
  for (let rodada = 0; rodada < 10; rodada++) {
    const g = grauDo();
    const antes = trechos.length;
    trechos = trechos.filter((t) => {
      const comprimento = t.pontos.length;
      const largura = mediana(t.larguras);
      const pontaSolta = (g.get(t.de) === 1 && !naBorda(t.pontos[0])) || (g.get(t.ate) === 1 && !naBorda(t.pontos[t.pontos.length - 1]));
      return !(pontaSolta && !t.naRotatoria && comprimento < largura * 1.2 + 3);
    });
    if (trechos.length === antes) break;
  }

  // A poda deixa nó de grau 2 no meio da rua (onde saía o galho): os dois
  // trechos viram um só, senão cada pedaço ganha largura e reta próprias e a
  // avenida sai ondulada.
  for (let rodada = 0; rodada < 200; rodada++) {
    const g = grauDo();
    let juntou = false;
    for (const [n, grau] of g) {
      if (grau !== 2) continue;
      const dois = trechos.filter((t) => t.de === n || t.ate === n);
      if (dois.length !== 2 || dois[0] === dois[1]) continue;
      let [a, b] = dois;
      // a termina em n, b começa em n.
      if (a.de === n) { a.pontos.reverse(); a.larguras.reverse(); [a.de, a.ate] = [a.ate, a.de]; }
      if (b.ate === n) { b.pontos.reverse(); b.larguras.reverse(); [b.de, b.ate] = [b.ate, b.de]; }
      if (a.de === b.ate) continue; // anel fechado
      a.pontos = a.pontos.concat(b.pontos.slice(1));
      a.larguras = a.larguras.concat(b.larguras.slice(1));
      a.ate = b.ate;
      a.naRotatoria = a.naRotatoria || b.naRotatoria;
      trechos = trechos.filter((t) => t !== b);
      juntou = true;
      break;
    }
    if (!juntou) break;
  }

  // Cada trecho: a largura (a mediana longe das pontas, onde o cruzamento
  // engorda a conta) e o eixo reto.
  const ruas = [];
  for (const t of trechos) {
    const n = t.larguras.length;
    const corte = Math.min(Math.floor(n / 3), 6);
    const largura = Math.round(mediana(t.larguras.slice(corte, n - corte).length ? t.larguras.slice(corte, n - corte) : t.larguras) * 2) / 2;
    const pontos = eixoReto(t.pontos).map((p) => [Math.round(p[0] * 100) / 100, Math.round(p[1] * 100) / 100]);
    if (pontos.length < 2) continue;
    // O esqueleto encolhe meia largura na ponta: a rua que sai do mapa acaba
    // a meia largura da borda.
    const saiDoMapa = (p) => p[0] < largura / 2 + 3 || p[1] < largura / 2 + 3 || p[0] > W - largura / 2 - 3 || p[1] > H - largura / 2 - 3;
    ruas.push({ pontos, largura, borda: [saiDoMapa(pontos[0]), saiDoMapa(pontos[pontos.length - 1])] });
  }
  return { ruas, rotatorias, mascara: m, esqueleto: s };
}

// ------------------------------------------------------------ a grade fina

/** Células por px do desenho: 4 dá 6 px de mundo por célula. */
const K = 4;
/** Quanto a grade passa do recorte, em px do desenho: a rua continua para
 *  fora do mapa, e a câmera na beira não vê o vazio. */
const MARGEM = 40;
const PX_DE_MUNDO = 24;
/** 2,5 m (40 px de mundo = 1 m), em px do desenho. */
const LARGURA_DA_CALCADA = 100 / PX_DE_MUNDO;
const RAIO_DA_ESQUINA = 100 / PX_DE_MUNDO;
/** Até onde o resto do cinza claro é do prédio (quintal, pátio): 10 m. */
const ALCANCE_DO_PREDIO = 400 / PX_DE_MUNDO;
/** O traço do contorno: até quanto ele pode sair da curva (px do desenho). */
const TOLERANCIA_DO_CONTORNO = 0.08;

function grade(W, H) {
  const GW = (W + 2 * MARGEM) * K, GH = (H + 2 * MARGEM) * K;
  return {
    GW, GH,
    // Centro da célula, em px do recorte.
    x: (cx) => (cx + 0.5) / K - MARGEM,
    y: (cy) => (cy + 0.5) / K - MARGEM,
    cx: (x) => Math.floor((x + MARGEM) * K - 0.5),
    cy: (y) => Math.floor((y + MARGEM) * K - 0.5),
  };
}

/** Distância do ponto ao segmento. */
function aoSegmento(px, py, ax, ay, bx, by) {
  const dx = bx - ax, dy = by - ay, L2 = dx * dx + dy * dy;
  let t = L2 > 0 ? ((px - ax) * dx + (py - ay) * dy) / L2 : 0;
  t = t < 0 ? 0 : t > 1 ? 1 : t;
  return Math.hypot(px - ax - dx * t, py - ay - dy * t);
}

/**
 * O campo da rua: em cada célula, quanto falta para chegar na rua (negativo
 * dentro), em px do desenho. Cada trecho é uma faixa de largura constante em
 * volta do eixo, de ponta redonda (é o que junta as ruas no cruzamento); a
 * rotatória é o anel. Só se calcula até ALCANCE em volta da rua - longe, o
 * campo fica 1e9.
 */
function campoDaRua(ruas, rotatorias, W, H, g) {
  const F = new Float32Array(g.GW * g.GH).fill(1e9);
  const ALCANCE = Math.max(LARGURA_DA_CALCADA, RAIO_DA_ESQUINA) * 2 + 2;
  const trechos = [];
  for (const r of ruas) {
    const p = r.pontos.map((q) => q.slice());
    // A rua que sai do mapa continua até o fim da margem.
    const esticar = (a, b) => {
      const dx = a[0] - b[0], dy = a[1] - b[1], L = Math.hypot(dx, dy) || 1;
      a[0] += dx / L * (MARGEM + 4); a[1] += dy / L * (MARGEM + 4);
    };
    if (r.borda[0]) esticar(p[0], p[1]);
    if (r.borda[1]) esticar(p[p.length - 1], p[p.length - 2]);
    for (let k = 0; k + 1 < p.length; k++) trechos.push([p[k], p[k + 1], r.largura / 2]);
  }
  for (const [a, b, raio] of trechos) {
    const m = raio + ALCANCE;
    const x0 = Math.max(0, g.cx(Math.min(a[0], b[0]) - m)), x1 = Math.min(g.GW - 1, g.cx(Math.max(a[0], b[0]) + m) + 1);
    const y0 = Math.max(0, g.cy(Math.min(a[1], b[1]) - m)), y1 = Math.min(g.GH - 1, g.cy(Math.max(a[1], b[1]) + m) + 1);
    for (let cy = y0; cy <= y1; cy++) {
      const py = g.y(cy);
      for (let cx = x0; cx <= x1; cx++) {
        const d = aoSegmento(g.x(cx), py, a[0], a[1], b[0], b[1]) - raio;
        const i = cy * g.GW + cx;
        if (d < F[i]) F[i] = d;
      }
    }
  }
  for (const r of rotatorias) {
    const m = r.fora + ALCANCE;
    for (let cy = Math.max(0, g.cy(r.centro[1] - m)); cy <= Math.min(g.GH - 1, g.cy(r.centro[1] + m)); cy++) {
      for (let cx = Math.max(0, g.cx(r.centro[0] - m)); cx <= Math.min(g.GW - 1, g.cx(r.centro[0] + m)); cx++) {
        const d = Math.hypot(g.x(cx) - r.centro[0], g.y(cy) - r.centro[1]);
        const i = cy * g.GW + cx;
        const anel = Math.max(d - r.fora, r.ilha - d);
        if (anel < F[i]) F[i] = anel;
      }
    }
  }
  return F;
}

/**
 * O raio de meio-fio na esquina: fechamento morfológico. Engorda a rua
 * RAIO_DA_ESQUINA e emagrece de volta - o canto de dentro do cruzamento fica
 * redondo, o resto volta ao lugar. O campo da rua continua mandando onde a
 * borda é reta (ele é exato; o da grade erra meia célula).
 */
function arredondarEsquinas(F, rotatorias, g) {
  const N = g.GW * g.GH;
  const fora = new Uint8Array(N);
  for (let i = 0; i < N; i++) fora[i] = F[i] > RAIO_DA_ESQUINA ? 1 : 0;
  const e = distancia(fora, g.GW, g.GH);
  const C = new Float32Array(N);
  const meia = 0.5 / K;
  for (let i = 0; i < N; i++) {
    const fechado = RAIO_DA_ESQUINA - (e[i] / K - meia) + 0.6 / K;
    C[i] = Math.min(F[i], fechado);
  }
  // A ilha da rotatória fica de fora mesmo se o fechamento a comer.
  for (const r of rotatorias) {
    const m = r.ilha + 2;
    for (let cy = g.cy(r.centro[1] - m); cy <= g.cy(r.centro[1] + m); cy++) {
      for (let cx = g.cx(r.centro[0] - m); cx <= g.cx(r.centro[0] + m); cx++) {
        const i = cy * g.GW + cx;
        const d = Math.hypot(g.x(cx) - r.centro[0], g.y(cy) - r.centro[1]);
        C[i] = Math.max(C[i], r.ilha - d);
      }
    }
  }
  return C;
}

/** Pinta na máscara as células cujo centro cai dentro do polígono (regra
 *  par-ímpar: o furo fica de fora). Anéis em px do recorte. */
function rasterizar(aneis, mascara, g, valor = 1) {
  let y0 = Infinity, y1 = -Infinity;
  for (const anel of aneis) for (const p of anel) { y0 = Math.min(y0, p[1]); y1 = Math.max(y1, p[1]); }
  for (let cy = Math.max(0, g.cy(y0)); cy <= Math.min(g.GH - 1, g.cy(y1) + 1); cy++) {
    const py = g.y(cy), xs = [];
    for (const anel of aneis) for (let k = 0; k < anel.length; k++) {
      const a = anel[k], b = anel[(k + 1) % anel.length];
      if ((a[1] > py) === (b[1] > py)) continue;
      xs.push(a[0] + (py - a[1]) * (b[0] - a[0]) / (b[1] - a[1]));
    }
    xs.sort((p, q) => p - q);
    for (let k = 0; k + 1 < xs.length; k += 2) {
      const c0 = Math.max(0, Math.ceil((xs[k] + MARGEM) * K - 0.5)), c1 = Math.min(g.GW - 1, Math.floor((xs[k + 1] + MARGEM) * K - 0.5));
      for (let cx = c0; cx <= c1; cx++) mascara[cy * g.GW + cx] = valor;
    }
  }
}

/** Distância com sinal até a borda da máscara: negativa dentro (px do
 *  desenho). */
function comSinal(m, g) {
  const N = g.GW * g.GH;
  const ate = distancia(m, g.GW, g.GH);
  const nao = new Uint8Array(N);
  for (let i = 0; i < N; i++) nao[i] = m[i] ? 0 : 1;
  const ateFora = distancia(nao, g.GW, g.GH);
  const s = new Float32Array(N);
  for (let i = 0; i < N; i++) s[i] = m[i] ? -(ateFora[i] - 0.5) / K : (ate[i] - 0.5) / K;
  return s;
}

// ------------------------------------------------------------ contorno

/**
 * Os anéis onde o campo cruza zero (quadrados marchantes, com a borda
 * interpolada), em px do recorte. Dentro é o campo <= 0; fora da grade conta
 * como fora. O lado de dentro fica sempre do mesmo lado do caminho, então o
 * anel de fora e o furo saem com sinais de área opostos.
 */
function contornos(campo, gw, gh, ox, oy) {
  const v = (x, y) => (x < 0 || y < 0 || x >= gw || y >= gh) ? 1 : campo[y * gw + x];
  const chaveH = (x, y) => ((y + 1) * (gw + 2) + (x + 1)) * 2;
  const chaveV = (x, y) => ((y + 1) * (gw + 2) + (x + 1)) * 2 + 1;
  const ponto = (chave) => {
    const vertical = chave & 1, base = chave >> 1;
    const x = base % (gw + 2) - 1, y = Math.floor(base / (gw + 2)) - 1;
    const a = v(x, y), b = vertical ? v(x, y + 1) : v(x + 1, y);
    const t = a === b ? 0.5 : Math.min(1, Math.max(0, a / (a - b)));
    const px = vertical ? x : x + t, py = vertical ? y + t : y;
    return [(ox + px + 0.5) / K - MARGEM, (oy + py + 0.5) / K - MARGEM];
  };
  const seguinte = new Map();
  for (let y = -1; y < gh; y++) for (let x = -1; x < gw; x++) {
    const tl = v(x, y) <= 0, tr = v(x + 1, y) <= 0, br = v(x + 1, y + 1) <= 0, bl = v(x, y + 1) <= 0;
    const caso = (tl ? 8 : 0) | (tr ? 4 : 0) | (br ? 2 : 0) | (bl ? 1 : 0);
    if (caso === 0 || caso === 15) continue;
    const T = chaveH(x, y), B = chaveH(x, y + 1), L = chaveV(x, y), R = chaveV(x + 1, y);
    const centro = (v(x, y) + v(x + 1, y) + v(x + 1, y + 1) + v(x, y + 1)) / 4 <= 0;
    // Cada par: as duas arestas e o canto que o segmento corta (ou, entre
    // arestas opostas, um canto de um lado), para orientar.
    let pares;
    switch (caso) {
      case 1: pares = [[L, B, 'bl']]; break;
      case 2: pares = [[B, R, 'br']]; break;
      case 3: pares = [[L, R, 'bl']]; break;
      case 4: pares = [[T, R, 'tr']]; break;
      case 5: pares = centro ? [[L, T, 'tl'], [B, R, 'br']] : [[L, B, 'bl'], [T, R, 'tr']]; break;
      case 6: pares = [[T, B, 'tr']]; break;
      case 7: pares = [[T, L, 'tl']]; break;
      case 8: pares = [[T, L, 'tl']]; break;
      case 9: pares = [[T, B, 'tl']]; break;
      case 10: pares = centro ? [[T, R, 'tr'], [L, B, 'bl']] : [[T, L, 'tl'], [B, R, 'br']]; break;
      case 11: pares = [[T, R, 'tr']]; break;
      case 12: pares = [[L, R, 'tl']]; break;
      case 13: pares = [[B, R, 'br']]; break;
      case 14: pares = [[L, B, 'bl']]; break;
    }
    const cantos = { tl: [x, y, tl], tr: [x + 1, y, tr], br: [x + 1, y + 1, br], bl: [x, y + 1, bl] };
    for (const [e1, e2, nome] of pares) {
      const p1 = ponto(e1), p2 = ponto(e2);
      const [cxx, cyy, dentro] = cantos[nome];
      const c = [(ox + cxx + 0.5) / K - MARGEM, (oy + cyy + 0.5) / K - MARGEM];
      const cruz = (p2[0] - p1[0]) * (c[1] - p1[1]) - (p2[1] - p1[1]) * (c[0] - p1[0]);
      // Dentro sempre à esquerda do caminho (cruz > 0).
      if ((cruz > 0) === dentro) seguinte.set(e1, e2); else seguinte.set(e2, e1);
    }
  }
  const aneis = [];
  const visto = new Set();
  for (const inicio of seguinte.keys()) {
    if (visto.has(inicio)) continue;
    const anel = [];
    let k = inicio;
    while (k !== undefined && !visto.has(k)) {
      visto.add(k);
      anel.push(ponto(k));
      k = seguinte.get(k);
    }
    if (anel.length >= 3) aneis.push(anel);
  }
  return aneis;
}

function areaDoAnel(a) {
  let s = 0;
  for (let i = 0; i < a.length; i++) { const p = a[i], q = a[(i + 1) % a.length]; s += p[0] * q[1] - q[0] * p[1]; }
  return s / 2;
}

function simplificarAnel(anel, tolerancia) {
  if (anel.length < 8) return anel;
  // Corta no ponto mais longe do primeiro e simplifica as duas metades.
  let longe = 0, k = 0;
  for (let i = 1; i < anel.length; i++) {
    const d = Math.hypot(anel[i][0] - anel[0][0], anel[i][1] - anel[0][1]);
    if (d > longe) { longe = d; k = i; }
  }
  const a = simplificar(anel.slice(0, k + 1), tolerancia);
  const b = simplificar(anel.slice(k).concat([anel[0]]), tolerancia);
  return a.slice(0, -1).concat(b.slice(0, -1));
}

function dentroDoAnel(p, anel) {
  let dentro = false;
  for (let i = 0, j = anel.length - 1; i < anel.length; j = i++) {
    const a = anel[i], b = anel[j];
    if ((a[1] > p[1]) !== (b[1] > p[1]) && p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]) dentro = !dentro;
  }
  return dentro;
}

const R2 = (n) => Math.round(n * 100) / 100;

/** Anéis -> triângulos: cada furo no anel de fora menor que o contém. */
function triangular(aneis) {
  aneis = aneis.map((a) => simplificarAnel(a, TOLERANCIA_DO_CONTORNO)).filter((a) => a.length >= 3 && Math.abs(areaDoAnel(a)) > 0.05);
  if (!aneis.length) return { v: [], t: [] };
  let maior = aneis[0];
  for (const a of aneis) if (Math.abs(areaDoAnel(a)) > Math.abs(areaDoAnel(maior))) maior = a;
  const sinal = Math.sign(areaDoAnel(maior));
  const fora = aneis.filter((a) => Math.sign(areaDoAnel(a)) === sinal).map((a) => ({ anel: a, area: Math.abs(areaDoAnel(a)), furos: [] }));
  for (const furo of aneis.filter((a) => Math.sign(areaDoAnel(a)) !== sinal)) {
    let dono = null;
    for (const f of fora) if (dentroDoAnel(furo[0], f.anel) && (!dono || f.area < dono.area)) dono = f;
    if (dono) dono.furos.push(furo);
  }
  const v = [], t = [];
  for (const f of fora) {
    const coords = [], furos = [];
    for (const p of f.anel) coords.push(R2(p[0]), R2(p[1]));
    for (const furo of f.furos) { furos.push(coords.length / 2); for (const p of furo) coords.push(R2(p[0]), R2(p[1])); }
    const base = v.length / 2;
    for (const k of earcut(coords, furos)) t.push(base + k);
    v.push(...coords);
  }
  return { v, t };
}

// --------------------------------------------------------------- o chão

function chaoDaCidade(ruas, rotatorias, W, H) {
  const g = grade(W, H);
  const N = g.GW * g.GH;
  const t0 = Date.now ? 0 : 0;
  const F = campoDaRua(ruas, rotatorias, W, H, g);
  const C = arredondarEsquinas(F, rotatorias, g);
  console.error(`grade ${g.GW}x${g.GH}: rua pronta`);

  // O cinza claro: o pavimento do traçado, a mancha de cada prédio (o lote
  // dele) e o asfalto do desenho que a rua refeita não cobriu. Fora do
  // recorte, só a calçada da rua que continua.
  const tracado = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'rua', 'mapa_tracado.json'), 'utf8'));
  const P = new Uint8Array(N);
  for (const p of tracado.poligonos) {
    if (p.classe === 'pavimento' || p.classe === 'asfalto') rasterizar([p.pontos].concat(p.furos), P, g);
  }
  // A mancha do prédio vem pixel a pixel (o prédio torto é uma escada): sai
  // com traço reto.
  for (const p of tracado.predios) rasterizar([simplificarAnel(p.pontos, 1.0)].concat((p.furos || []).map((f) => simplificarAnel(f, 1.0))), P, g);
  for (let cy = 0; cy < g.GH; cy++) for (let cx = 0; cx < g.GW; cx++) {
    const i = cy * g.GW + cx, x = g.x(cx), y = g.y(cy);
    if (x < 0 || y < 0 || x >= W || y >= H) P[i] = C[i] <= LARGURA_DA_CALCADA ? 1 : 0;
  }
  // A ilha da rotatória é canteiro de grama, não calçada nem quintal.
  const semIlha = (m) => {
    for (const r of rotatorias) {
      for (let cy = g.cy(r.centro[1] - r.ilha - 1); cy <= g.cy(r.centro[1] + r.ilha + 1); cy++) {
        for (let cx = g.cx(r.centro[0] - r.ilha - 1); cx <= g.cx(r.centro[0] + r.ilha + 1); cx++) {
          if (Math.hypot(g.x(cx) - r.centro[0], g.y(cy) - r.centro[1]) <= r.ilha + 0.5) m[cy * g.GW + cx] = 0;
        }
      }
    }
  };
  semIlha(P);
  // A fresta entre dois polígonos traçados separados (a mancha do prédio e o
  // pavimento em volta) fecha: até FRESTA px do desenho.
  const FRESTA = 0.75;
  const sP = comSinal(P, g);
  const largo = new Uint8Array(N);
  for (let i = 0; i < N; i++) largo[i] = sP[i] > FRESTA ? 1 : 0;
  const ateLargo = distancia(largo, g.GW, g.GH);
  for (let i = 0; i < N; i++) sP[i] = Math.min(sP[i], FRESTA - (ateLargo[i] / K - 0.5 / K) + 0.3 / K);
  console.error('cinza claro pronto');

  const camadas = {};
  camadas.asfalto = triangular(contornos(C, g.GW, g.GH, 0, 0));
  const meioFio = contornos(C, g.GW, g.GH, 0, 0).map((a) => simplificarAnel(a, TOLERANCIA_DO_CONTORNO).map((p) => [R2(p[0]), R2(p[1])]));
  // A calçada passa também na frente do lote de grama (o gramado do
  // desenho): "ao longo de toda rua". Na mata, na água e na roça, não.
  const Q = Uint8Array.from(P);
  for (const p of tracado.poligonos) if (p.classe === 'gramado') rasterizar([p.pontos].concat(p.furos), Q, g);
  semIlha(Q);
  const sQ = comSinal(Q, g);
  const calcada = new Float32Array(N);
  for (let i = 0; i < N; i++) calcada[i] = Math.max(C[i] - LARGURA_DA_CALCADA, Math.min(sP[i], sQ[i]));
  camadas.calcada = triangular(contornos(calcada, g.GW, g.GH, 0, 0));
  camadas.cidade = triangular(contornos(sP, g.GW, g.GH, 0, 0));
  console.error('asfalto, calçada e cidade triangulados');

  // O resto de cada prédio: as células do cinza claro mais perto dele que de
  // qualquer outro, até ALCANCE_DO_PREDIO.
  const melhor = new Float32Array(N).fill(1e9), segundo = new Float32Array(N).fill(1e9);
  const dono = new Int16Array(N).fill(-1);
  const caixas = [];
  const aoPredio = (p, x, y) => {
    let d = Infinity;
    for (const r of p.rects) {
      const [rx, ry, rw, rh] = r.rect;
      const dx = Math.max(rx - x, 0, x - (rx + rw)), dy = Math.max(ry - y, 0, y - (ry + rh));
      d = Math.min(d, Math.hypot(dx, dy));
    }
    return d;
  };
  tracado.predios.forEach((p, n) => {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const r of p.rects) { const [rx, ry, rw, rh] = r.rect; x0 = Math.min(x0, rx); y0 = Math.min(y0, ry); x1 = Math.max(x1, rx + rw); y1 = Math.max(y1, ry + rh); }
    const m = ALCANCE_DO_PREDIO + 2;
    const caixa = [Math.max(0, g.cx(x0 - m)), Math.max(0, g.cy(y0 - m)), Math.min(g.GW - 1, g.cx(x1 + m) + 1), Math.min(g.GH - 1, g.cy(y1 + m) + 1)];
    caixas.push(caixa);
    for (let cy = caixa[1]; cy <= caixa[3]; cy++) for (let cx = caixa[0]; cx <= caixa[2]; cx++) {
      const i = cy * g.GW + cx, d = aoPredio(p, g.x(cx), g.y(cy));
      if (d < melhor[i]) { segundo[i] = melhor[i]; melhor[i] = d; dono[i] = n; } else if (d < segundo[i]) segundo[i] = d;
    }
  });
  const lotes = [];
  tracado.predios.forEach((p, n) => {
    const [x0, y0, x1, y1] = caixas[n];
    const gw = x1 - x0 + 1, gh = y1 - y0 + 1;
    const campo = new Float32Array(gw * gh);
    for (let cy = y0; cy <= y1; cy++) for (let cx = x0; cx <= x1; cx++) {
      const i = cy * g.GW + cx;
      const d = aoPredio(p, g.x(cx), g.y(cy));
      const outro = dono[i] === n ? segundo[i] : melhor[i];
      campo[(cy - y0) * gw + (cx - x0)] = Math.max(d - ALCANCE_DO_PREDIO, d - outro, sP[i]);
    }
    const tri = triangular(contornos(campo, gw, gh, x0, y0));
    // O centro do maior retângulo: o jogo acha o prédio por ele e escolhe o
    // chão pelo tipo.
    const maior = p.rects.reduce((a, b) => (a.rect[2] * a.rect[3] >= b.rect[2] * b.rect[3] ? a : b)).rect;
    if (tri.t.length) lotes.push({ predio: n, centro: [maior[0] + maior[2] / 2, maior[1] + maior[3] / 2], ...tri });
  });
  console.error(`${lotes.length} lotes de prédio triangulados`);
  return { camadas, meioFio, lotes };
}

// ------------------------------------------------------------- principal

function principal() {
  const { rec, W, H, classe } = T.classesDoChao(ENTRADA);
  console.error(`recorte ${W}x${H} em (${rec.x}, ${rec.y})`);
  const { ruas, rotatorias, mascara, esqueleto } = eixosDasRuas(classe, W, H);
  const { camadas, meioFio, lotes } = chaoDaCidade(ruas, rotatorias, W, H);
  const saida = {
    origem: path.basename(ENTRADA),
    escala: PX_DE_MUNDO,
    largura_da_calcada: LARGURA_DA_CALCADA,
    camadas, meio_fio: meioFio, lotes,
    eixos: ruas, rotatorias,
  };
  fs.writeFileSync(SAIDA, JSON.stringify(saida));
  const n = (c) => c.t.length / 3;
  console.error(`escrito ${SAIDA}: asfalto ${n(camadas.asfalto)}, calçada ${n(camadas.calcada)}, cidade ${n(camadas.cidade)} triângulos, ${meioFio.length} anéis de meio-fio, ${lotes.length} lotes; ${(fs.statSync(SAIDA).size / 1024).toFixed(0)} KB`);
  console.error(`${ruas.length} trechos de rua, ${rotatorias.length} rotatória(s)`);
  for (const r of rotatorias) console.error(`  rotatória em (${(r.centro[0] + rec.x).toFixed(1)}, ${(r.centro[1] + rec.y).toFixed(1)}) do desenho, ilha ${r.ilha.toFixed(1)}, fora ${r.fora.toFixed(1)}`);
  const larguras = {};
  for (const r of ruas) larguras[r.largura] = (larguras[r.largura] || 0) + 1;
  console.error('larguras (px do desenho):', JSON.stringify(larguras));

  if (DEPURACAO) {
    fs.mkdirSync(DEPURACAO, { recursive: true });
    const K = 3, rgb = Buffer.alloc(W * K * H * K * 3, 30);
    const pinta = (x, y, c) => {
      if (x < 0 || y < 0 || x >= W * K || y >= H * K) return;
      const o = (y * W * K + x) * 3; rgb[o] = c[0]; rgb[o + 1] = c[1]; rgb[o + 2] = c[2];
    };
    for (let y = 0; y < H * K; y++) for (let x = 0; x < W * K; x++) {
      const i = Math.floor(y / K) * W + Math.floor(x / K);
      if (mascara[i]) pinta(x, y, [90, 90, 90]);
      if (esqueleto[i]) pinta(x, y, [140, 60, 60]);
    }
    for (const r of ruas) for (let k = 0; k + 1 < r.pontos.length; k++) {
      const [a, b] = [r.pontos[k], r.pontos[k + 1]];
      const n = Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) * K * 2);
      for (let j = 0; j <= n; j++) {
        const t = j / n;
        pinta(Math.round((a[0] + (b[0] - a[0]) * t) * K), Math.round((a[1] + (b[1] - a[1]) * t) * K), [80, 200, 255]);
      }
      pinta(Math.round(a[0] * K), Math.round(a[1] * K), [255, 255, 0]);
    }
    for (const r of rotatorias) for (let a = 0; a < 360; a += 1) for (const raio of [r.ilha, r.fora]) {
      pinta(Math.round((r.centro[0] + Math.cos(a * Math.PI / 180) * raio) * K), Math.round((r.centro[1] + Math.sin(a * Math.PI / 180) * raio) * K), [255, 120, 0]);
    }
    T.escreverPng(path.join(DEPURACAO, 'eixos.png'), W * K, H * K, rgb);
    fs.writeFileSync(path.join(DEPURACAO, 'eixos.json'), JSON.stringify({ ruas, rotatorias }));
    console.error(`depuração em ${DEPURACAO}`);
  }
}

if (require.main === module) principal();
