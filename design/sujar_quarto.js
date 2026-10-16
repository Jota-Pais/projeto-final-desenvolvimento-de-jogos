// Suja o quarto dela - a segunda camada do quarto macabro (16/10/2026). A
// primeira camada e o gerador: a foto da
// equipe reduzida a grade real (207 x 156, blocos de ~7 px), as correntes e a
// cama destruida do PixelLab coladas por cima so onde mudou. O resultado dela
// e casa-equipe/quarto_colado.png; este script escurece, poe mofo, manchas,
// respingos com escorrido, arranhoes e marcas de mao, e amplia de volta bloco
// a bloco com as mesmas fronteiras da foto original -> casa-equipe/
// quarto_macabro.png (1448 x 1086), que o casa_fotos.js corta para o jogo.
// Semente fixa: rodar de novo da o mesmo quarto. Sem dependencia.
//
// Uso: node design/sujar_quarto.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const PASTA = path.join(__dirname, 'casa-equipe');
const ENTRADA = path.join(PASTA, 'quarto_colado.png');
const FRONTEIRAS = path.join(PASTA, 'pixel', 'quarto_sujo.png');
const SAIDA = path.join(PASTA, 'quarto_macabro.png');

function lerPng(arquivo) {
  const b = fs.readFileSync(arquivo); let p = 8, w, h, ct, idat = [];
  while (p < b.length) { const n = b.readUInt32BE(p), t = b.toString('ascii', p + 4, p + 8);
    if (t === 'IHDR') { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); ct = b[p + 17]; }
    if (t === 'IDAT') idat.push(b.subarray(p + 8, p + 8 + n)); p += 12 + n; }
  const bpp = ct === 6 ? 4 : ct === 2 ? 3 : ct === 4 ? 2 : 1;
  const raw = zlib.inflateSync(Buffer.concat(idat)); const stride = w * bpp;
  const out = Buffer.alloc(w * h * 4); let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)]; const linha = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)); const cur = Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) { const a = i >= bpp ? cur[i - bpp] : 0, up = prev[i], c = i >= bpp ? prev[i - bpp] : 0; let v = linha[i];
      if (f === 1) v += a; else if (f === 2) v += up; else if (f === 3) v += (a + up) >> 1;
      else if (f === 4) { const pp = a + up - c, pa = Math.abs(pp - a), pb = Math.abs(pp - up), pc = Math.abs(pp - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? up : c); }
      cur[i] = v & 255; }
    for (let x = 0; x < w; x++) { const o = (y * w + x) * 4, s = x * bpp; out[o] = cur[s]; out[o + 1] = bpp >= 3 ? cur[s + 1] : cur[s]; out[o + 2] = bpp >= 3 ? cur[s + 2] : cur[s]; out[o + 3] = 255; }
    prev = cur; }
  return { w, h, px: out };
}

function gravarPng(arquivo, w, h, px) {
  const crc32 = (buf) => { let c = 0xffffffff; for (let i = 0; i < buf.length; i++) { c ^= buf[i]; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1)); } return (~c) >>> 0; };
  const pedaco = (tipo, dados) => { const t = Buffer.alloc(4); t.writeUInt32BE(dados.length); const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(corpo)); return Buffer.concat([t, corpo, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
  const linhas = []; for (let y = 0; y < h; y++) { linhas.push(Buffer.from([0])); for (let x = 0; x < w; x++) linhas.push(px.subarray((y * w + x) * 4, (y * w + x) * 4 + 3)); }
  fs.writeFileSync(arquivo, Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), pedaco('IHDR', ihdr), pedaco('IDAT', zlib.deflateSync(Buffer.concat(linhas), { level: 9 })), pedaco('IEND', Buffer.alloc(0))]));
}

// As fronteiras dos blocos da foto original: onde o pixel muda em mais de 30 %
// das linhas (ou colunas). Ampliar a grade com elas devolve a foto byte a byte.
function fronteiras(im) {
  const { w, h, px } = im;
  const dif = (a, b) => px[a] !== px[b] || px[a + 1] !== px[b + 1] || px[a + 2] !== px[b + 2];
  const col = new Array(w).fill(0), lin = new Array(h).fill(0);
  for (let y = 0; y < h; y++) for (let x = 1; x < w; x++) if (dif((y * w + x) * 4, (y * w + x - 1) * 4)) col[x]++;
  for (let y = 1; y < h; y++) for (let x = 0; x < w; x++) if (dif((y * w + x) * 4, ((y - 1) * w + x) * 4)) lin[y]++;
  const bordas = (arr, n, tam) => [0, ...arr.map((v, i) => [i, v]).filter(([, v]) => v > n * 0.3).map(([i]) => i), tam];
  return { bx: bordas(col, h, w), by: bordas(lin, w, h) };
}

const im = lerPng(ENTRADA); const W = im.w, H = im.h, px = Buffer.from(im.px);
let s = 16100;
const rnd = () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const entre = (a, b) => a + rnd() * (b - a);
const hash = (x, y, k) => { let h = Math.imul(x, 374761393) ^ Math.imul(y, 668265263) ^ Math.imul(k, 2147483647); h = Math.imul(h ^ (h >>> 13), 1274126177); return ((h ^ (h >>> 16)) >>> 0) / 4294967296; };
const suave = (t) => t * t * (3 - 2 * t);
function ruido(x, y, k) { const x0 = Math.floor(x), y0 = Math.floor(y), fx = suave(x - x0), fy = suave(y - y0);
  const a = hash(x0, y0, k), b = hash(x0 + 1, y0, k), c = hash(x0, y0 + 1, k), d = hash(x0 + 1, y0 + 1, k);
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy; }
const fbm = (x, y, k) => 0.55 * ruido(x / 9, y / 9, k) + 0.3 * ruido(x / 4, y / 4, k + 1) + 0.15 * ruido(x / 2, y / 2, k + 2);
const pega = (x, y) => { const o = (y * W + x) * 4; return [px[o], px[o + 1], px[o + 2]]; };
const poe = (x, y, c, a = 1) => { x = Math.round(x); y = Math.round(y); if (x < 0 || y < 0 || x >= W || y >= H) return; const o = (y * W + x) * 4;
  for (let i = 0; i < 3; i++) px[o + i] = Math.max(0, Math.min(255, Math.round(px[o + i] * (1 - a) + c[i] * a))); };
const lum = (x, y) => { const [r, g, b] = pega(x, y); return (0.299 * r + 0.587 * g + 0.114 * b) / 255; };
const dentro = (x, y, r) => x >= r[0] && x < r[0] + r[2] && y >= r[1] && y < r[1] + r[3];

// As superficies, na grade. Retangulos a mao sobre a foto.
const PAREDE_DIR = [112, 0, 50, 104];  // parede branca entre o painel e a janela
const PAREDE_ESQ = [0, 0, 44, 86];     // parede da esquerda
const JANELA = [162, 18, 45, 62];
const SANGUE = [[70, 20, 16], [56, 15, 12], [84, 28, 19], [46, 17, 13]];
const MOFO = [[44, 42, 34], [32, 31, 26], [54, 50, 40]];

// 1. Escurecer e tirar cor. O filtro da casa escurece de novo no jogo, entao
// aqui e pouco: 14 % no meio, 30 % nos cantos, 25 % menos cor.
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const [r, g, b] = pega(x, y); const l = 0.299 * r + 0.587 * g + 0.114 * b;
  const v = 0.86 - 0.16 * Math.min(1, Math.hypot((x - W / 2) / (W / 2), (y - H * 0.55) / (H * 0.6)) ** 2);
  const o = (y * W + x) * 4; px[o] = (l + (r - l) * 0.75) * v; px[o + 1] = (l + (g - l) * 0.75) * v; px[o + 2] = (l + (b - l) * 0.75) * v; }

// 2. Mofo: desce do teto e sobe dos cantos, so nas paredes claras.
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const dir = dentro(x, y, PAREDE_DIR), esq = dentro(x, y, PAREDE_ESQ);
  if (!(dir || esq) || dentro(x, y, JANELA)) continue;
  const perto = Math.max(1 - y / 34, dir ? 1 - Math.abs(x - 161) / 12 : 0, esq ? 1 - x / 14 : 0, esq ? 1 - Math.abs(x - 43) / 8 : 0);
  const n = fbm(x, y, 10) + perto * 0.45 - 0.66;
  if (n > 0) poe(x, y, MOFO[Math.floor(ruido(x / 3, y / 3, 13) * 2.99)], Math.min(0.6, n * 2.2)); }

// 3. Manchas grandes: sangue velho na cama e no chao, infiltracao no teto.
function mancha(cx, cy, rx, ry, cor, forca, k) {
  for (let y = Math.floor(cy - ry); y <= cy + ry; y++) for (let x = Math.floor(cx - rx); x <= cx + rx; x++) {
    const d = Math.hypot((x - cx) / rx, (y - cy) / ry); const n = d - fbm(x, y, k) * 0.9;
    if (n < 0.35) poe(x, y, cor, forca * Math.min(1, (0.35 - n) * 3)); } }
mancha(112, 104, 22, 9, SANGUE[1], 0.7, 20);
mancha(84, 118, 12, 6, SANGUE[3], 0.65, 21);
mancha(134, 126, 20, 6, SANGUE[3], 0.5, 22);
mancha(70, 140, 18, 5, [40, 26, 18], 0.55, 23);
mancha(150, 5, 30, 7, [56, 48, 32], 0.55, 24);
mancha(18, 4, 22, 6, [56, 48, 32], 0.5, 25);
mancha(186, 120, 16, 8, [30, 22, 16], 0.5, 26);

// 4. Respingos com escorrido.
function respingo(cx, cy, n, raio, escorre) {
  for (let i = 0; i < n; i++) { const a = entre(0, Math.PI * 2), r = raio * Math.sqrt(rnd()); const x = Math.round(cx + Math.cos(a) * r * 1.4), y = Math.round(cy + Math.sin(a) * r);
    poe(x, y, SANGUE[i % 4], entre(0.5, 0.9));
    if (escorre && rnd() < 0.3 && lum(x, y) > 0.16) { const L = Math.floor(entre(2, 8)); for (let k = 1; k <= L; k++) poe(x, y + k, SANGUE[1], 0.8 - k * 0.08); } } }
respingo(130, 44, 22, 7, true);
respingo(148, 28, 12, 5, true);
respingo(88, 46, 14, 8, false);
respingo(24, 54, 14, 6, true);
respingo(104, 142, 18, 9, false);

// 5. Arranhoes de unha: tres ou quatro riscos de 1 px, a 3 px um do outro,
// levemente curvos. Na parede clara, escuros (reboco arrancado); no painel
// escuro, claros com sombra do lado (a madeira por baixo).
function arranhao(x0, y0, comp, incl, n, claro) {
  for (let j = 0; j < n; j++) { const L = comp - Math.floor(entre(0, 4)), y1 = y0 + j * 0.6 + entre(-1, 1);
    for (let k = 0; k < L; k++) { const t = k / L, x = x0 + j * 3 + incl * k + 1.2 * Math.sin(t * Math.PI), y = y1 + k, a = 0.55 * (1 - 0.6 * Math.abs(t - 0.4));
      if (claro) { poe(x, y, [112, 92, 72], a); poe(x + 1, y, [14, 10, 8], a * 0.6); } else poe(x, y, [30, 24, 18], a + 0.1); } } }
// no painel, fora das duas correntes (x ~60-85 e ~100-110) e do crucifixo (x 78-84, y 18-38)
arranhao(46, 18, 18, 0.15, 3, true);
arranhao(87, 42, 14, -0.1, 3, true);
arranhao(116, 60, 14, 0.2, 4, false);
arranhao(8, 34, 12, 0.3, 3, false);

// 6. Marcas de mao, do tamanho de uma mao naquela parede (~8 x 10 da grade),
// com falhas, e algumas arrastadas para baixo.
const MAO = [
  '.#.#....',
  '.#.#.#..',
  '##.#.#.#',
  '##.#.#.#',
  '######.#',
  '########',
  '.#######',
  '.######.',
  '..#####.',
  '..####..'];
function mao(x0, y0, arrasta, espelho, forca) {
  for (let j = 0; j < MAO.length; j++) for (let i = 0; i < 8; i++) { if (MAO[j][espelho ? 7 - i : i] !== '#' || rnd() < 0.18) continue;
    poe(x0 + i, y0 + j, SANGUE[rnd() < 0.7 ? 0 : 2], forca * entre(0.75, 1)); }
  for (let k = 1; k <= arrasta; k++) for (let i = 2; i < 7; i++) if (rnd() > 0.25 + k / (arrasta * 2)) poe(x0 + i, y0 + 9 + k, SANGUE[1], forca * (0.8 - k / (arrasta + 3))); }
mao(118, 18, 0, false, 0.8); mao(132, 30, 10, true, 0.75); mao(148, 46, 6, false, 0.7); mao(22, 44, 5, true, 0.7);

// De volta ao tamanho da foto, bloco a bloco.
const { bx, by } = fronteiras(lerPng(FRONTEIRAS));
if (bx.length - 1 !== W || by.length - 1 !== H) throw new Error(`a grade da foto (${bx.length - 1} x ${by.length - 1}) nao bate com ${W} x ${H}`);
const LW = bx[bx.length - 1], LH = by[by.length - 1], grande = Buffer.alloc(LW * LH * 4);
for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) { const o = (j * W + i) * 4;
  for (let y = by[j]; y < by[j + 1]; y++) for (let x = bx[i]; x < bx[i + 1]; x++) px.copy(grande, (y * LW + x) * 4, o, o + 4); }
gravarPng(SAIDA, LW, LH, grande);
console.log(`casa-equipe/quarto_macabro.png ${LW} x ${LH}`);
