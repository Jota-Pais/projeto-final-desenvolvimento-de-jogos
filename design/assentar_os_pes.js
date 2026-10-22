// Assenta no chao os pes das animacoes de uma folha do PixelLab (21/10/2026).
//
// Os modelos de animacao do PixelLab (crouching, crouched-walking) redesenham
// o boneco numa altura propria: no jogador, os pes dos quadros agachados
// ficavam 5 a 12 px acima do pe da rotacao parada da mesma direcao, e como o
// rua/boneco.gd usa um deslocamento so para a folha toda (o do pe do sul), o
// boneco agachado aparecia menor e flutuando (Joao: "quando ele ta de frente
// parece ter ficado meio amassado"). Aqui cada linha pedida desce ate o pe
// bater no da rotacao parada daquela direcao:
//
//  - por QUADRO (`--por-quadro`), para animacao com os dois pes no chao o
//    tempo todo (o agachar: de pe ate abaixado);
//  - pela LINHA, para passo (o pe mais baixo da linha vai ao chao e o resto
//    desce junto - um pe no ar continua no ar).
//
// O pe e o pixel opaco mais baixo da celula. Reescreve o PNG no lugar.
// Uso: node design/assentar_os_pes.js <folha.json> <animacao>[:por-quadro] ...
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function lerPng(arquivo) {
  const b = fs.readFileSync(arquivo); let p = 8, w, h, ct, idat = [];
  while (p < b.length) { const n = b.readUInt32BE(p), t = b.toString('ascii', p + 4, p + 8);
    if (t === 'IHDR') { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); ct = b[p + 17]; }
    if (t === 'IDAT') idat.push(b.subarray(p + 8, p + 8 + n)); p += 12 + n; }
  const bpp = ct === 6 ? 4 : ct === 2 ? 3 : 0;
  if (!bpp) throw new Error('so PNG RGB ou RGBA de 8 bits: ' + arquivo);
  const raw = zlib.inflateSync(Buffer.concat(idat)); const stride = w * bpp;
  const out = Buffer.alloc(w * h * 4); let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)]; const line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)); const cur = Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) { const a = i >= bpp ? cur[i - bpp] : 0, up = prev[i], c = i >= bpp ? prev[i - bpp] : 0; let v = line[i];
      if (f === 1) v += a; else if (f === 2) v += up; else if (f === 3) v += (a + up) >> 1;
      else if (f === 4) { const pp = a + up - c, pa = Math.abs(pp - a), pb = Math.abs(pp - up), pc = Math.abs(pp - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? up : c); }
      cur[i] = v & 255; }
    for (let x = 0; x < w; x++) { const o = (y * w + x) * 4, s = x * bpp;
      out[o] = cur[s]; out[o + 1] = cur[s + 1]; out[o + 2] = cur[s + 2]; out[o + 3] = bpp === 4 ? cur[s + 3] : 255; }
    prev = cur; }
  return { w, h, px: out };
}

function gravarPng(arquivo, w, h, px) {
  const crc32 = (buf) => { let c = 0xffffffff; for (let i = 0; i < buf.length; i++) { c ^= buf[i]; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1)); } return (~c) >>> 0; };
  const chunk = (tipo, dados) => { const t = Buffer.alloc(4); t.writeUInt32BE(dados.length); const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(corpo)); return Buffer.concat([t, corpo, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  const linhas = []; for (let y = 0; y < h; y++) { linhas.push(Buffer.from([0])); linhas.push(px.subarray(y * w * 4, (y + 1) * w * 4)); }
  fs.writeFileSync(arquivo, Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(Buffer.concat(linhas))), chunk('IEND', Buffer.alloc(0))]));
}

const [folhaJson, ...pedidos] = process.argv.slice(2);
if (!pedidos.length) throw new Error('uso: assentar_os_pes.js <folha.json> <animacao>[:por-quadro] ...');
const folha = JSON.parse(fs.readFileSync(folhaJson, 'utf8'));
const arqPng = path.join(path.dirname(folhaJson), folha.spritesheet.path);
const png = lerPng(arqPng);
const cw = folha.spritesheet.cell_size.width, ch = folha.spritesheet.cell_size.height;

// O pe (linha do pixel opaco mais baixo) da celula (coluna, linha), ou -1.
function pe(col, lin) {
  for (let y = ch - 1; y >= 0; y--) for (let x = 0; x < cw; x++) {
    if (png.px[((lin * ch + y) * png.w + col * cw + x) * 4 + 3] > 0) return y;
  }
  return -1;
}
// Desce a celula `dy` px (dy >= 0).
function descer(col, lin, dy) {
  if (dy <= 0) return;
  for (let y = ch - 1; y >= 0; y--) for (let x = 0; x < cw; x++) {
    const d = ((lin * ch + y) * png.w + col * cw + x) * 4;
    const sy = y - dy;
    if (sy < 0) { png.px.fill(0, d, d + 4); continue; }
    const s = ((lin * ch + sy) * png.w + col * cw + x) * 4;
    png.px.copy(png.px, d, s, s + 4);
  }
}

const rotacoes = folha.spritesheet.rows.find((r) => r.type === 'rotations');
const peParado = {};
rotacoes.directions.forEach((dir, i) => { peParado[dir] = pe(i, rotacoes.row); });
for (const pedido of pedidos) {
  const [anim, modo] = pedido.split(':');
  const linhas = folha.spritesheet.rows.filter((r) => r.type === 'animation' && r.animation === anim);
  if (!linhas.length) throw new Error('a folha nao tem a animacao ' + anim);
  for (const r of linhas) {
    const pes = [];
    for (let c = 0; c < r.frame_count; c++) pes.push(pe(c, r.row));
    const alvo = peParado[r.direction];
    const desce = modo === 'por-quadro' ? pes.map((p) => alvo - p) : pes.map(() => alvo - Math.max(...pes));
    desce.forEach((dy, c) => descer(c, r.row, dy));
    console.log(`${anim} ${r.direction.padEnd(10)} pe parado ${alvo}, pes ${pes.join(' ')} -> desce ${desce.join(' ')}`);
  }
}
gravarPng(arqPng, png.w, png.h, png.px);
