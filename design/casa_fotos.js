// Leva as fotos da casa (design/casa-equipe/, 1448 x 1086, 4:3, pixeladas em
// blocos pela equipe) para a tela do modo Casa: corta em 16:9 na altura
// escolhida para cada comodo e grava casa/arte/<comodo>.png em 1280 x 720, o
// tamanho da janela, para a foto entrar 1:1. A reducao e por vizinho mais
// proximo: os blocos de ~7 px viram blocos de 6-7 px, sem borrar.
//
// `corte` e o topo do corte em unidades da tela da casa (casa/comodos.gd):
// a foto inteira, com 320 de largura, tem 240 de altura; o corte mostra 180.
// 0 = do alto da foto, 30 = o meio, 60 = ate o pe da foto. Decidido em cima
// do gabarito de 16/10/2026, para nao cortar o que se clica. Sem
// dependencia.
//
// Uso: node design/casa_fotos.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const FOTOS = {
  entrada: { foto: 'pixel/porta_entrada_suja-1.png', corte: 30 },
  sala_tv: { foto: 'pixel/sala_de_estar_suja.png', corte: 30 },
  sala_sofa: { foto: 'pixel/sala_de_estar_suja_back_view.png', corte: 36 },
  corredor: { foto: 'pixel/corredor_cozinha_quarto_porao_sujos.png', corte: 30 },
  cozinha: { foto: 'pixel/cozinha_suja.png', corte: 40 },
  // A foto do quarto refeita macabra (gerador + sujar_quarto.js), nao a da equipe.
  quarto: { foto: 'quarto_macabro.png', corte: 26 },
};
const LARGURA = 1280, ALTURA = 720, TELA_LARGURA = 320;

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

const raiz = path.join(__dirname, '..');
fs.mkdirSync(path.join(raiz, 'casa', 'arte'), { recursive: true });
for (const [comodo, { foto, corte }] of Object.entries(FOTOS)) {
  const im = lerPng(path.join(__dirname, 'casa-equipe', foto));
  const escala = im.w / TELA_LARGURA; // px da foto por unidade da tela
  const px = Buffer.alloc(LARGURA * ALTURA * 4);
  for (let y = 0; y < ALTURA; y++) {
    const sy = Math.min(im.h - 1, Math.floor((corte + y * TELA_LARGURA / LARGURA) * escala));
    for (let x = 0; x < LARGURA; x++) {
      const sx = Math.floor(x * im.w / LARGURA);
      im.px.copy(px, (y * LARGURA + x) * 4, (sy * im.w + sx) * 4, (sy * im.w + sx) * 4 + 4);
    }
  }
  const saida = path.join(raiz, 'casa', 'arte', comodo + '.png');
  gravarPng(saida, LARGURA, ALTURA, px);
  console.log(`${comodo}: ${foto} corte ${corte} -> casa/arte/${comodo}.png`);
}
