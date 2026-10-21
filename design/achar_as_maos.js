// Acha as maos do jogador em cada quadro da folha do PixelLab e grava
// rua/arte/jogador/maos.json, que rua/bracos.gd le para desenhar os bracos
// segurando a arma (21/10/2026, Joao: "faz as animacoes de segurando e usando
// cada arma"; questionario: "Por codigo agora").
//
// O boneco tem os bracos desenhados caidos do lado do corpo. Para ele segurar
// a arma sem ficar com quatro bracos (o defeito que o Joao achou no morto do
// zumbi), o codigo cobre a mao desenhada com a manga e leva o antebraco dali
// ate o cabo - e para isso precisa saber onde a mao esta em cada quadro.
//
// A mao e a mancha de pele abaixo do pescoco: so os tres tons claros da pele
// (o marrom do rosto e o mesmo da mochila, entao fica de fora). Grava, por
// animacao e direcao, a lista de maos de cada quadro em px da celula.
//
// Uso: node design/achar_as_maos.js rua/arte/jogador/Jogador_rua-Idle.json
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const PELE = ['e6b9a1', 'd09781', 'b27560'];
const MENOR_MANCHA = 3;

function lerPng(arquivo) {
  const buf = fs.readFileSync(arquivo);
  let i = 8, w = 0, h = 0, tipo = 0, idat = [];
  while (i < buf.length) {
    const n = buf.readUInt32BE(i), t = buf.toString('ascii', i + 4, i + 8);
    const d = buf.subarray(i + 8, i + 8 + n);
    if (t === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); tipo = d[9]; }
    if (t === 'IDAT') idat.push(d);
    i += n + 12;
  }
  if (tipo !== 6) throw new Error('so RGBA de 8 bits');
  const cru = zlib.inflateSync(Buffer.concat(idat));
  const rgba = Buffer.alloc(w * h * 4);
  const linha = w * 4;
  for (let y = 0; y < h; y++) {
    const f = cru[y * (linha + 1)];
    for (let x = 0; x < linha; x++) {
      const v = cru[y * (linha + 1) + 1 + x];
      const a = x >= 4 ? rgba[y * linha + x - 4] : 0;
      const b = y > 0 ? rgba[(y - 1) * linha + x] : 0;
      const c = x >= 4 && y > 0 ? rgba[(y - 1) * linha + x - 4] : 0;
      let p = 0;
      if (f === 0) p = 0; else if (f === 1) p = a; else if (f === 2) p = b;
      else if (f === 3) p = (a + b) >> 1;
      else { const q = a + b - c; const pa = Math.abs(q - a), pb = Math.abs(q - b), pc = Math.abs(q - c); p = pa <= pb && pa <= pc ? a : pb <= pc ? b : c; }
      rgba[y * linha + x] = (v + p) & 255;
    }
  }
  return { w, h, rgba };
}

const json = process.argv[2];
const layout = JSON.parse(fs.readFileSync(json, 'utf8')).spritesheet;
const img = lerPng(path.join(path.dirname(json), layout.path));
const cw = layout.cell_size.width, ch = layout.cell_size.height;
const nomes = { south: 'sul', 'south-east': 'sudeste', east: 'leste', 'north-east': 'nordeste', north: 'norte', 'north-west': 'noroeste', west: 'oeste', 'south-west': 'sudoeste' };

function cor(x, y) {
  const i = (y * img.w + x) * 4;
  if (img.rgba[i + 3] < 128) return '';
  return [0, 1, 2].map((c) => img.rgba[i + c].toString(16).padStart(2, '0')).join('');
}

// O pescoco: a linha de baixo da pele do rosto na rotacao sul, mais uma folga.
// Abaixo dela, pele e mao.
function maosDaCelula(cx, cy, pescoco) {
  const visto = new Set();
  const maos = [];
  for (let y = pescoco; y < ch; y++) for (let x = 0; x < cw; x++) {
    const k = y * cw + x;
    if (visto.has(k) || !PELE.includes(cor(cx + x, cy + y))) continue;
    const fila = [[x, y]]; visto.add(k);
    let sx = 0, sy = 0, n = 0;
    while (fila.length) {
      const [px, py] = fila.pop();
      sx += px; sy += py; n++;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = px + dx, ny = py + dy;
        if (nx < 0 || ny < pescoco || nx >= cw || ny >= ch) continue;
        const nk = ny * cw + nx;
        if (visto.has(nk) || !PELE.includes(cor(cx + nx, cy + ny))) continue;
        visto.add(nk); fila.push([nx, ny]);
      }
    }
    if (n >= MENOR_MANCHA) maos.push([Math.round(sx / n * 10) / 10, Math.round(sy / n * 10) / 10]);
  }
  return maos.sort((a, b) => a[0] - b[0]);
}

// O rosto da rotacao sul: a pele mais baixa acima do meio da celula.
let fimDoRosto = 0;
for (let y = 0; y < ch / 2; y++) for (let x = 0; x < cw; x++) if (PELE.includes(cor(x, y))) fimDoRosto = y;
const pescoco = fimDoRosto + 4;

const saida = { celula: [cw, ch], pescoco, maos: {} };
for (const linha of layout.rows) {
  const y0 = linha.row * ch;
  if (linha.type === 'rotations') {
    linha.directions.forEach((d, i) => { saida.maos['parado_' + nomes[d]] = [maosDaCelula(i * cw, y0, pescoco)]; });
    continue;
  }
  const acao = linha.animation.replace(/-v\d+$/, '');
  const quadros = [];
  for (let i = 0; i < linha.frame_count; i++) quadros.push(maosDaCelula(i * cw, y0, pescoco));
  saida.maos[acao + '_' + nomes[linha.direction]] = quadros;
}
const destino = path.join(path.dirname(json), 'maos.json');
fs.writeFileSync(destino, JSON.stringify(saida, null, '\t').replace(/\n/g, '\r\n') + '\r\n');
for (const [nome, q] of Object.entries(saida.maos)) console.log(nome.padEnd(18), q.map((m) => m.length).join(' '), JSON.stringify(q[0]));
console.log('pescoco', pescoco, '->', destino);
