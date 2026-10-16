// As texturas dos predios, desenhadas por regra (design/arte-rua.md, fase 3):
// parede, piso, telha, zinco e laje, 64 x 64 px, emendaveis por construcao
// (ruido por pixel e riscos que dao a volta na borda), e os sprites de porta e
// janela. Contraste baixo de proposito: e fundo, nao objeto. Sem dependencia.
//
// Uso: node design/desenhar_texturas.js rua/arte/predios
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const pasta = process.argv[2];
if (!pasta) throw new Error('passe a pasta de saida');
fs.mkdirSync(pasta, { recursive: true });

// Gerador com semente, para a textura ser a mesma a cada rodada.
function rng(semente) {
  let s = semente >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const hex = (h) => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));

class Tela {
  constructor(l, a, fundo) {
    this.l = l; this.a = a; this.px = new Uint8Array(l * a * 4);
    for (let i = 0; i < l * a; i++) this.set(i % l, Math.floor(i / l), fundo, 255);
  }
  set(x, y, cor, alfa = 255) {
    x = ((x % this.l) + this.l) % this.l; y = ((y % this.a) + this.a) % this.a; // da a volta: emenda
    const o = (y * this.l + x) * 4;
    this.px[o] = clamp(cor[0]); this.px[o + 1] = clamp(cor[1]); this.px[o + 2] = clamp(cor[2]); this.px[o + 3] = alfa;
  }
  get(x, y) {
    x = ((x % this.l) + this.l) % this.l; y = ((y % this.a) + this.a) % this.a;
    const o = (y * this.l + x) * 4;
    return [this.px[o], this.px[o + 1], this.px[o + 2]];
  }
  // Ruido por pixel: cada canal anda ate +-n niveis.
  ruido(r, n) { for (let y = 0; y < this.a; y++) for (let x = 0; x < this.l; x++) { const c = this.get(x, y); const d = Math.round((r() * 2 - 1) * n); this.set(x, y, [c[0] + d, c[1] + d, c[2] + d]); } }
  // Mancha macia: escurece em volta de um ponto, com queda ate o raio.
  mancha(cx, cy, raio, forca) { for (let y = -raio; y <= raio; y++) for (let x = -raio; x <= raio; x++) { const d = Math.hypot(x, y) / raio; if (d > 1) continue; const c = this.get(cx + x, cy + y); const f = 1 - forca * (1 - d) * (1 - d); this.set(cx + x, cy + y, [c[0] * f, c[1] * f, c[2] * f]); } }
  // Risco (rachadura): passeio aleatorio que da a volta na borda.
  risco(r, x, y, passos, cor) { let dx = r() < 0.5 ? 1 : -1, dy = r() < 0.5 ? 1 : -1; for (let i = 0; i < passos; i++) { this.set(x, y, cor); if (r() < 0.6) x += dx; else y += dy; if (r() < 0.1) dx = -dx; if (r() < 0.1) dy = -dy; } }
  png(caminho) {
    const crc32 = (buf) => { let c = 0xffffffff; for (let i = 0; i < buf.length; i++) { c ^= buf[i]; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1)); } return (~c) >>> 0; };
    const chunk = (tipo, dados) => { const t = Buffer.alloc(4); t.writeUInt32BE(dados.length); const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(corpo)); return Buffer.concat([t, corpo, c]); };
    const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(this.l, 0); ihdr.writeUInt32BE(this.a, 4); ihdr[8] = 8; ihdr[9] = 6;
    const linhas = []; for (let y = 0; y < this.a; y++) { linhas.push(Buffer.from([0])); linhas.push(Buffer.from(this.px.subarray(y * this.l * 4, (y + 1) * this.l * 4))); }
    fs.writeFileSync(caminho, Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(Buffer.concat(linhas))), chunk('IEND', Buffer.alloc(0))]));
    console.log(path.basename(caminho) + ': ' + this.l + ' x ' + this.a);
  }
}

// --- parede: reboco sujo, cinza-bege, riscos finos e manchas ---------------
{
  const r = rng(1); const t = new Tela(64, 64, hex('#5e5a52'));
  t.ruido(r, 4);
  for (let i = 0; i < 6; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6 + Math.floor(r() * 8), 0.08);
  for (let i = 0; i < 3; i++) t.risco(r, Math.floor(r() * 64), Math.floor(r() * 64), 14 + Math.floor(r() * 10), hex('#4c4842'));
  t.png(path.join(pasta, 'parede.png'));
}
// --- piso: concreto gasto, mais escuro que a parede, juntas a cada 32 px ---
{
  const r = rng(2); const t = new Tela(64, 64, hex('#4b4741'));
  t.ruido(r, 3);
  for (let i = 0; i < 5; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 8 + Math.floor(r() * 8), 0.07);
  for (let k = 0; k < 64; k++) { t.set(k, 0, hex('#433f3a')); t.set(k, 32, hex('#433f3a')); t.set(0, k, hex('#433f3a')); t.set(32, k, hex('#433f3a')); }
  t.png(path.join(pasta, 'piso.png'));
}
// --- telha: telha ceramica desbotada, fileiras de 8 px, alternadas ---------
{
  const r = rng(3); const t = new Tela(64, 64, hex('#6a4c42'));
  for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
    const fila = Math.floor(y / 8); const dentro = y % 8;
    const desloc = fila % 2 === 0 ? 0 : 8; const col = ((x + desloc) % 16);
    let cor = hex('#6a4c42');
    if (dentro === 0) cor = hex('#54403a');          // sombra da telha de cima
    else if (dentro === 1) cor = hex('#73544a');     // borda clara
    else if (dentro >= 6) cor = hex('#614640');      // base mais escura
    if (col === 0) cor = [cor[0] - 10, cor[1] - 8, cor[2] - 8]; // junta entre telhas
    t.set(x, y, cor);
  }
  t.ruido(r, 3);
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6 + Math.floor(r() * 6), 0.1); // musgo/sujeira
  t.png(path.join(pasta, 'telha.png'));
}
// --- zinco: chapa ondulada enferrujada, ondas verticais de 8 px ----------
{
  const r = rng(4); const t = new Tela(64, 64, hex('#5a5c5a'));
  const onda = ['#525453', '#585a59', '#5f6160', '#646665', '#5f6160', '#585a59', '#525453', '#4c4e4d'];
  for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) t.set(x, y, hex(onda[x % 8]));
  t.ruido(r, 2);
  for (let i = 0; i < 7; i++) { // ferrugem escorrida
    const x = Math.floor(r() * 64), y = Math.floor(r() * 64), alt = 4 + Math.floor(r() * 10);
    for (let k = 0; k < alt; k++) { const c = t.get(x, y + k); const f = 1 - (k / alt); t.set(x, y + k, [c[0] * (1 - 0.1 * f) + 20 * f, c[1] * (1 - 0.2 * f), c[2] * (1 - 0.3 * f)]); }
  }
  t.png(path.join(pasta, 'zinco.png'));
}
// --- laje: concreto chapado com manchas de agua e uma rachadura -----------
{
  const r = rng(5); const t = new Tela(64, 64, hex('#56544f'));
  t.ruido(r, 3);
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 10 + Math.floor(r() * 10), 0.12);
  t.risco(r, 20, 10, 30, hex('#45433f'));
  t.png(path.join(pasta, 'laje.png'));
}
// --- porta (24 x 14) e janela (16 x 10), vistas de cima, na fachada --------
{
  const desenhar = (nome, linhas, paleta) => {
    const l = linhas[0].length, a = linhas.length; const t = new Tela(l, a, [0, 0, 0]);
    for (let y = 0; y < a; y++) for (let x = 0; x < l; x++) { const c = linhas[y][x]; if (c === '.') t.set(x, y, [0, 0, 0], 0); else t.set(x, y, hex(paleta[c])); }
    t.png(path.join(pasta, nome + '.png'));
  };
  desenhar('porta', [
    '########################',
    '#wwwwwwwwwww#wwwwwwwwww#',
    '#wWWWWWWWWWw#wWWWWWWWWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWwk#wWwwwwwwWw#'.slice(0, 24),
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWwwwwwwwWw#wWwwwwwwWw#',
    '#wWWWWWWWWWw#wWWWWWWWWw#',
    '#wwwwwwwwwww#wwwwwwwwww#',
    '########################',
  ], { '#': '#2f2a25', 'w': '#5a4332', 'W': '#4a3729', 'k': '#8a8a80' });
  desenhar('janela', [
    '################',
    '#vvvvvvv#vvvvvv#',
    '#vVVVVvv#vvVVVv#',
    '#vvvvvvv#vvvvvv#',
    '#vvvvvvv#vvvvvv#',
    '################',
    '#vvvvvvv#vvvvvv#',
    '#vvvvvvv#vvvvvv#',
    '#vvvvvvv#vvvvvv#',
    '################',
  ], { '#': '#3b3a36', 'v': '#4e5a60', 'V': '#5e6c73' });
}

// --- caixa de papelao (56 x 64): tampo de 34 px e frente de 30, vista ------
// inclinada como os moveis gerados (design/arte-rua.md, fase 4, 14/10/2026).
// Sai em rua/arte/objetos (segundo argumento), onde o cenario procura o
// desenho de cada tipo de movel.
{
  const pastaObjetos = process.argv[3] || path.join(pasta, '..', 'objetos');
  fs.mkdirSync(pastaObjetos, { recursive: true });
  const l = 56, a = 64, topo = 34;
  const t = new Tela(l, a, hex('#8a7352'));
  const r = rng(14);
  const cheio = (x0, y0, x1, y1, cor) => { for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) t.set(x, y, cor); };
  cheio(1, topo, l - 1, a - 1, hex('#6d5b45'));
  cheio(1, Math.floor(topo / 2) - 2, l - 1, Math.floor(topo / 2) + 2, hex('#9a8a6a'));
  cheio(Math.floor(l / 2) - 1, 1, Math.floor(l / 2) + 1, topo, hex('#7a6448'));
  for (let y = 1; y < a - 1; y++) for (let x = 1; x < l - 1; x++) { const c = t.get(x, y); const d = Math.round((r() * 2 - 1) * 6); t.set(x, y, [c[0] + d, c[1] + d, c[2] + d]); }
  t.mancha(44, 50, 9, 0.25);
  for (let x = 0; x < l; x++) { t.set(x, 0, hex('#2f2a25')); t.set(x, a - 1, hex('#2f2a25')); t.set(x, topo, hex('#4a3d2e')); }
  for (let y = 0; y < a; y++) { t.set(0, y, hex('#2f2a25')); t.set(l - 1, y, hex('#2f2a25')); }
  t.png(path.join(pastaObjetos, 'caixa.png'));
}
