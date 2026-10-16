// Junta numa folha do PixelLab (PNG + JSON de layout, a que rua/boneco.gd le)
// as linhas de animacao de OUTRA folha do mesmo boneco. Serve para o boneco
// que mudou de conta (15/10/2026): as animacoes antigas (vagar, toque, morrer)
// ficaram na folha da conta antiga e as novas (dano...) saem da conta nova.
// As duas folhas precisam ter a mesma celula; copia so as animacoes pedidas
// (ou todas as linhas de animacao da nova, se nenhuma for pedida), apagando
// antes da antiga qualquer linha com o mesmo nome de animacao. Sem dependencia.
//
// Uso: node design/juntar_folha.js <antiga.json> <nova.json> <saida.json> [animacao...]
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function lerPng(arquivo) {
  const b = fs.readFileSync(arquivo); let p = 8, w, h, ct, idat = [];
  while (p < b.length) { const n = b.readUInt32BE(p), t = b.toString('ascii', p + 4, p + 8);
    if (t === 'IHDR') { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); if (b[p + 16] !== 8) throw new Error('so PNG de 8 bits'); ct = b[p + 17]; }
    if (t === 'IDAT') idat.push(b.subarray(p + 8, p + 8 + n)); p += 12 + n; }
  const bpp = ct === 6 ? 4 : ct === 2 ? 3 : ct === 4 ? 2 : 1;
  if (bpp === 1) throw new Error('PNG com paleta ou cinza nao e suportado: ' + arquivo);
  const raw = zlib.inflateSync(Buffer.concat(idat)); const stride = w * bpp;
  const out = Buffer.alloc(w * h * 4); let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)]; const line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)); const cur = Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) { const a = i >= bpp ? cur[i - bpp] : 0, up = prev[i], c = i >= bpp ? prev[i - bpp] : 0; let v = line[i];
      if (f === 1) v += a; else if (f === 2) v += up; else if (f === 3) v += (a + up) >> 1;
      else if (f === 4) { const pp = a + up - c, pa = Math.abs(pp - a), pb = Math.abs(pp - up), pc = Math.abs(pp - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? up : c); }
      cur[i] = v & 255; }
    for (let x = 0; x < w; x++) { const o = (y * w + x) * 4, s = x * bpp;
      out[o] = cur[s]; out[o + 1] = cur[s + 1]; out[o + 2] = cur[s + 2]; out[o + 3] = bpp === 4 ? cur[s + 3] : (bpp === 2 ? cur[s + 1] : 255);
      if (bpp === 2) { out[o + 1] = cur[s]; out[o + 2] = cur[s]; } }
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

const [antigaJson, novaJson, saidaJson, ...pedidas] = process.argv.slice(2);
if (!saidaJson) throw new Error('uso: juntar_folha.js <antiga.json> <nova.json> <saida.json> [animacao...]');
const antiga = JSON.parse(fs.readFileSync(antigaJson, 'utf8'));
const nova = JSON.parse(fs.readFileSync(novaJson, 'utf8'));
const semVersao = (n) => n.replace(/-v\d+$/, '');
const celA = antiga.spritesheet.cell_size, celN = nova.spritesheet.cell_size;
if (celA.width !== celN.width || celA.height !== celN.height) throw new Error('celulas diferentes: ' + JSON.stringify(celA) + ' x ' + JSON.stringify(celN));
const cw = celA.width, ch = celA.height;
const pngA = lerPng(path.join(path.dirname(antigaJson), antiga.spritesheet.path));
const pngN = lerPng(path.join(path.dirname(novaJson), nova.spritesheet.path));
const linhasNovas = nova.spritesheet.rows.filter((r) => r.type === 'animation' && (pedidas.length === 0 || pedidas.includes(semVersao(r.animation))));
if (linhasNovas.length === 0) throw new Error('nenhuma linha de animacao para copiar da folha nova');
const nomesNovos = new Set(linhasNovas.map((r) => semVersao(r.animation)));
const linhasAntigas = antiga.spritesheet.rows.filter((r) => r.type !== 'animation' || !nomesNovos.has(semVersao(r.animation)));
const colunas = Math.max(antiga.spritesheet.columns, nova.spritesheet.columns, ...linhasNovas.map((r) => r.frame_count));
const w = colunas * cw, h = (linhasAntigas.length + linhasNovas.length) * ch;
const px = Buffer.alloc(w * h * 4);
const blit = (src, linhaSrc, linhaDst, quantas) => {
  for (let y = 0; y < ch; y++) for (let x = 0; x < quantas * cw; x++) {
    const s = ((linhaSrc * ch + y) * src.w + x) * 4, d = ((linhaDst * ch + y) * w + x) * 4;
    px[d] = src.px[s]; px[d + 1] = src.px[s + 1]; px[d + 2] = src.px[s + 2]; px[d + 3] = src.px[s + 3]; }
};
const rows = [];
linhasAntigas.forEach((r) => { blit(pngA, r.row, rows.length, r.frame_count); rows.push({ ...r, row: rows.length }); });
linhasNovas.forEach((r) => { blit(pngN, r.row, rows.length, r.frame_count); rows.push({ ...r, row: rows.length }); });
const saidaPng = path.basename(saidaJson, '.json') + '.png';
gravarPng(path.join(path.dirname(saidaJson), saidaPng), w, h, px);
const saida = { ...antiga, spritesheet: { ...antiga.spritesheet, path: saidaPng, columns: colunas, sheet_size: { width: w, height: h }, rows }, export_date: new Date().toISOString(), juntado_de: [path.basename(antigaJson), path.basename(novaJson)] };
fs.writeFileSync(saidaJson, JSON.stringify(saida, null, 2) + '\n');
console.log(`${saidaPng}: ${w} x ${h}, ${rows.length} linhas (${linhasAntigas.length} da antiga + ${linhasNovas.length} da nova: ${[...nomesNovos].join(', ')})`);
