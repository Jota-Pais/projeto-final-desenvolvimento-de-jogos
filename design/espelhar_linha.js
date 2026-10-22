// Acrescenta numa folha do PixelLab uma linha de animacao espelhada na
// horizontal de outra (22/10/2026): o agachado de nordeste gerado saiu em
// guarda de luta, e o de noroeste espelhado e o curvado que o Joao escolheu
// ("Curvado, como os de lado") - a rotacao parada de noroeste espelhada bate
// quase pixel a pixel com a de nordeste. Cada quadro espelha dentro da propria
// celula, entao o pivo (o centro da celula) nao sai do lugar. Reescreve o PNG
// e o JSON no lugar.
//
// Uso: node design/espelhar_linha.js <folha.json> <animacao> <direcao_de> <animacao_nova> <direcao_nova>
// (direcoes do PixelLab: north-west, north-east...)
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

const [folhaJson, anim, dirDe, animNova, dirNova] = process.argv.slice(2);
if (!dirNova) throw new Error('uso: espelhar_linha.js <folha.json> <animacao> <direcao_de> <animacao_nova> <direcao_nova>');
const texto = fs.readFileSync(folhaJson, 'utf8');
const crlf = texto.includes('\r\n');
const folha = JSON.parse(texto);
const arqPng = path.join(path.dirname(folhaJson), folha.spritesheet.path);
const png = lerPng(arqPng);
const cw = folha.spritesheet.cell_size.width, ch = folha.spritesheet.cell_size.height;
const origem = folha.spritesheet.rows.find((r) => r.type === 'animation' && r.animation === anim && r.direction === dirDe);
if (!origem) throw new Error(`a folha nao tem ${anim} ${dirDe}`);
// A folha ganha uma linha embaixo.
const linhaNova = folha.spritesheet.rows.length;
const h = (linhaNova + 1) * ch;
const px = Buffer.alloc(png.w * h * 4);
png.px.copy(px, 0, 0, png.w * png.h * 4);
for (let c = 0; c < origem.frame_count; c++) for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) {
  const s = ((origem.row * ch + y) * png.w + c * cw + (cw - 1 - x)) * 4;
  const d = ((linhaNova * ch + y) * png.w + c * cw + x) * 4;
  png.px.copy(px, d, s, s + 4);
}
gravarPng(arqPng, png.w, h, px);
folha.spritesheet.rows.push({ ...origem, row: linhaNova, animation: animNova, direction: dirNova, espelhado_de: `${anim} ${dirDe}` });
folha.spritesheet.sheet_size = { width: png.w, height: h };
const saida = JSON.stringify(folha, null, 2) + '\n';
fs.writeFileSync(folhaJson, crlf ? saida.replace(/\n/g, '\r\n') : saida);
console.log(`${animNova} ${dirNova}: ${origem.frame_count} quadros espelhados de ${anim} ${dirDe} (linha ${linhaNova})`);
