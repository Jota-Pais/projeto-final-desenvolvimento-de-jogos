// Monta um grupo de rua/arte/chao/paleta.json a partir de um tileset BRUTO do
// PixelLab, para uma classe que a regra geral deixa com a cor errada
// (15/10/2026): a agua veio verde-escura com faixa preta e virava lodo; a
// mata v2 veio roxa. Toda cor do tile cheio do lado pedido (lower/upper),
// mais qualquer cor fora das outras tabelas cujo matiz caia na faixa dada e
// seja escura (v < 0,3 - a sombra do barranco), vira a cor pedida: matiz e
// saturacao fixos, valor = base + ganho x valor original (clareia a faixa
// preta sem achatar o desenho). O que sobra (barranco de areia, por exemplo)
// fica para a regra geral. Sem dependencia.
//
// Uso: node design/paleta_de_classe.js <bruto.png> <tileset.json> <paleta.json> <grupo> <lower|upper> <matiz> <saturacao> <valor_base> <valor_ganho> <matiz_min> <matiz_max>
//   agua: ... agua lower 200 0.28 0.24 0.5 60 170
//   mata: ... mata_v2 upper 28 0.22 0.12 0.6 240 310
const fs = require('fs'), zlib = require('zlib');
function lerPng(arquivo) {
  const b = fs.readFileSync(arquivo); let p = 8, w, h, ct, idat = [];
  while (p < b.length) { const n = b.readUInt32BE(p), t = b.toString('ascii', p + 4, p + 8);
    if (t === 'IHDR') { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); ct = b[p + 17]; }
    if (t === 'IDAT') idat.push(b.subarray(p + 8, p + 8 + n)); p += 12 + n; }
  const bpp = ct === 6 ? 4 : ct === 2 ? 3 : ct === 4 ? 2 : 1;
  const raw = zlib.inflateSync(Buffer.concat(idat)); const stride = w * bpp;
  const out = Buffer.alloc(w * h * 4); let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)]; const line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)); const cur = Buffer.alloc(stride);
    for (let i = 0; i < stride; i++) { const a = i >= bpp ? cur[i - bpp] : 0, up = prev[i], c = i >= bpp ? prev[i - bpp] : 0; let v = line[i];
      if (f === 1) v += a; else if (f === 2) v += up; else if (f === 3) v += (a + up) >> 1;
      else if (f === 4) { const pp = a + up - c, pa = Math.abs(pp - a), pb = Math.abs(pp - up), pc = Math.abs(pp - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? up : c); }
      cur[i] = v & 255; }
    for (let x = 0; x < w; x++) { const o = (y * w + x) * 4, s = x * bpp; out[o] = cur[s]; out[o + 1] = bpp >= 3 ? cur[s + 1] : cur[s]; out[o + 2] = bpp >= 3 ? cur[s + 2] : cur[s]; out[o + 3] = bpp === 4 ? cur[s + 3] : bpp === 2 ? cur[s + 1] : 255; }
    prev = cur; }
  return { w, h, px: out };
}
const rgb2hsv = (r, g, b) => { r /= 255; g /= 255; b /= 255; const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min; let h = 0; if (d > 0) { if (max === r) h = ((g - b) / d) % 6; else if (max === g) h = (b - r) / d + 2; else h = (r - g) / d + 4; h *= 60; if (h < 0) h += 360; } return [h, max > 0 ? d / max : 0, max]; };
const hsv2hex = (h, s, v) => { const c = v * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = v - c; let r = 0, g = 0, b = 0; if (h < 60) [r, g, b] = [c, x, 0]; else if (h < 120) [r, g, b] = [x, c, 0]; else if (h < 180) [r, g, b] = [0, c, x]; else if (h < 240) [r, g, b] = [0, x, c]; else if (h < 300) [r, g, b] = [x, 0, c]; else [r, g, b] = [c, 0, x]; return '#' + [r, g, b].map((q) => Math.round((q + m) * 255).toString(16).padStart(2, '0')).join(''); };
const hex = (r, g, b) => '#' + [r, g, b].map((q) => q.toString(16).padStart(2, '0')).join('');

const [bruto, tilesetJson, paletaJson, grupo, lado, matizS, saturacaoS, baseS, ganhoS, matizMinS, matizMaxS] = process.argv.slice(2);
if (!matizMaxS) throw new Error("faltam argumentos: ver o cabecalho");
const MATIZ = +matizS, SATURACAO = +saturacaoS, BASE = +baseS, GANHO = +ganhoS, MATIZ_MIN = +matizMinS, MATIZ_MAX = +matizMaxS;
const img = lerPng(bruto);
const meta = JSON.parse(fs.readFileSync(tilesetJson, 'utf8'));
const paleta = JSON.parse(fs.readFileSync(paletaJson, 'utf8'));
const conhecidas = new Set();
for (const g of Object.keys(paleta)) if (paleta[g] && typeof paleta[g] === 'object' && g !== 'regra_geral' && g !== grupo) for (const de of Object.keys(paleta[g])) conhecidas.add(de.toLowerCase());
const cheioDeBaixo = meta.tileset_data.tiles.find((t) => ['NW', 'NE', 'SW', 'SE'].every((k) => t.corners[k] === lado));
const cb = cheioDeBaixo.bounding_box;
const doCheio = new Set();
for (let y = cb.y; y < cb.y + cb.height; y++) for (let x = cb.x; x < cb.x + cb.width; x++) { const o = (y * img.w + x) * 4; doCheio.add(hex(img.px[o], img.px[o + 1], img.px[o + 2])); }
const agua = {}; let n = 0;
const todas = new Map();
for (let i = 0; i < img.w * img.h; i++) { const o = i * 4; if (img.px[o + 3] === 0) continue; const k = hex(img.px[o], img.px[o + 1], img.px[o + 2]); todas.set(k, (todas.get(k) || 0) + 1); }
for (const [k, quantos] of todas) {
  if (conhecidas.has(k)) continue;
  const r = parseInt(k.slice(1, 3), 16), g = parseInt(k.slice(3, 5), 16), b = parseInt(k.slice(5, 7), 16);
  const [h, s, v] = rgb2hsv(r, g, b);
  const verde = h >= MATIZ_MIN && h <= MATIZ_MAX;
  const eAgua = doCheio.has(k) || (verde && v < 0.3);
  if (!eAgua) continue;
  // Agua parada e suja: azul-cinza, pouca saturacao; a faixa preta sobe para
  // nao ser buraco, e o resto fica abaixo da grama retocada (v ~ 0,5).
  agua[k] = hsv2hex(MATIZ, SATURACAO, BASE + v * GANHO);
  n++;
}
paleta[grupo] = Object.assign({ nota: 'Gerado por design/paleta_de_classe.js a partir do bruto do tileset ' + meta.id + ' (lado ' + lado + '): matiz ' + MATIZ + ', saturacao ' + SATURACAO + ', valor ' + BASE + ' + ' + GANHO + ' x original. Refazer se o tileset mudar.' }, agua);
fs.writeFileSync(paletaJson, JSON.stringify(paleta, null, 2) + '\n');
console.log(n + ' cores de ' + grupo + ' mapeadas (' + doCheio.size + ' no tile cheio ' + lado + '); ' + todas.size + ' cores no bruto; paleta gravada em ' + paletaJson);
