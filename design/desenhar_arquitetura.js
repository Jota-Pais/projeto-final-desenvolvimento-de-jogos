// As texturas da arquitetura de 21/10/2026, desenhadas por regra como as de
// design/desenhar_texturas.js: telhado (telha romana, telha colonial,
// fibrocimento) e fachada (reboco, tijolo a vista, bloco de concreto), 64 x 64
// px, emendaveis por construcao.
//
// **Telhado: a agua cai para baixo na textura** (para o sul, com a cumeeira
// leste-oeste): a fileira de telha tem a borda de baixo escura, onde a de cima
// sobrepoe. O rua/telhado.gd gira e espelha a textura em cada agua do
// telhado para a queda apontar para o lado certo. O reboco sai claro e quase
// neutro: a cor de cada casa vem da tinta (rua/arquitetura.gd).
//
// Uso: node design/desenhar_arquitetura.js rua/arte/predios
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const pasta = process.argv[2];
if (!pasta) throw new Error('passe a pasta de saida');
fs.mkdirSync(pasta, { recursive: true });

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
const mistura = (a, b, f) => [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f];
const vezes = (c, f) => [c[0] * f, c[1] * f, c[2] * f];

class Tela {
  constructor(l, a, fundo) {
    this.l = l; this.a = a; this.px = new Uint8Array(l * a * 4);
    for (let i = 0; i < l * a; i++) this.set(i % l, Math.floor(i / l), fundo, 255);
  }
  set(x, y, cor, alfa = 255) {
    x = ((x % this.l) + this.l) % this.l; y = ((y % this.a) + this.a) % this.a;
    const o = (y * this.l + x) * 4;
    this.px[o] = clamp(cor[0]); this.px[o + 1] = clamp(cor[1]); this.px[o + 2] = clamp(cor[2]); this.px[o + 3] = alfa;
  }
  get(x, y) {
    x = ((x % this.l) + this.l) % this.l; y = ((y % this.a) + this.a) % this.a;
    const o = (y * this.l + x) * 4;
    return [this.px[o], this.px[o + 1], this.px[o + 2]];
  }
  ruido(r, n) { for (let y = 0; y < this.a; y++) for (let x = 0; x < this.l; x++) { const c = this.get(x, y); const d = Math.round((r() * 2 - 1) * n); this.set(x, y, [c[0] + d, c[1] + d, c[2] + d]); } }
  mancha(cx, cy, raio, forca, cor = null) { for (let y = -raio; y <= raio; y++) for (let x = -raio; x <= raio; x++) { const d = Math.hypot(x, y) / raio; if (d > 1) continue; const c = this.get(cx + x, cy + y); const f = forca * (1 - d) * (1 - d); this.set(cx + x, cy + y, cor ? mistura(c, cor, f) : vezes(c, 1 - f)); } }
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

// --- telha romana: fileiras de 8 px, cada telha com a onda (capa clara,
// canal escuro) e a borda de baixo na sombra da fileira de cima; as fileiras
// desencontradas meia telha. Cada telha um tom: telhado velho e remendado.
{
  const r = rng(11); const base = hex('#96604c'); const t = new Tela(64, 64, base);
  const largura = 8;
  for (let fila = 0; fila < 8; fila++) {
    const desloca = (fila % 2) * (largura / 2);
    for (let k = 0; k < 64 / largura; k++) {
      const tom = 0.88 + r() * 0.16 + (r() < 0.12 ? -0.14 : 0);
      const cor = vezes(base, tom);
      for (let dy = 0; dy < 8; dy++) for (let dx = 0; dx < largura; dx++) {
        const x = k * largura + dx + desloca, y = fila * 8 + dy;
        // A onda: o meio da telha e a capa (clara), as beiradas o canal.
        const onda = Math.cos(((dx + 0.5) / largura) * Math.PI * 2);
        let c = vezes(cor, 1 + 0.12 * onda);
        if (dy === 0) c = vezes(c, 1.12);
        if (dy >= 6) c = vezes(c, 0.78 - (dy - 6) * 0.1);
        t.set(x, y, c);
      }
    }
  }
  t.ruido(r, 4);
  // Limo e sujeira escorrida: manchas verdes e escuras, poucas.
  for (let i = 0; i < 3; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 5 + Math.floor(r() * 5), 0.35, hex('#4d5a34'));
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6 + Math.floor(r() * 6), 0.12);
  t.png(path.join(pasta, 'telha-romana.png'));
}

// --- telha colonial (capa e canal): canais ao longo da queda (verticais),
// 8 px cada, alternando capa (cilindro claro por cima) e canal (fundo
// escuro); a emenda de uma telha na outra a cada 12-16 px, desencontrada.
{
  const r = rng(12); const base = hex('#9c6a52'); const t = new Tela(64, 64, base);
  for (let canal = 0; canal < 8; canal++) {
    const capa = canal % 2 === 0;
    let y = Math.floor(r() * 14);
    const passo = capa ? 14 : 12;
    // Cada telha do canal com um tom.
    const tons = [];
    for (let k = 0; k < 8; k++) tons.push(0.87 + r() * 0.18 + (r() < 0.1 ? -0.15 : 0));
    for (let yy = 0; yy < 64; yy++) {
      const qual = Math.floor(((yy - y + 64) % 64) / passo);
      const dentro = ((yy - y + 64) % 64) % passo;
      for (let dx = 0; dx < 8; dx++) {
        const x = canal * 8 + dx;
        const perfil = Math.sin(((dx + 0.5) / 8) * Math.PI);
        let c = vezes(base, tons[qual % tons.length] * (capa ? 0.9 + 0.24 * perfil : 0.7 + 0.1 * perfil));
        // A ponta de baixo de cada telha sobre a seguinte: uma linha de
        // sombra e, logo acima, a borda clara.
        if (dentro === passo - 1) c = vezes(c, capa ? 0.62 : 0.7);
        if (dentro === 0 && capa) c = vezes(c, 1.1);
        if (dx === 0 || dx === 7) c = vezes(c, capa ? 0.85 : 0.92);
        t.set(x, yy, c);
      }
    }
  }
  t.ruido(r, 3);
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 4 + Math.floor(r() * 6), 0.4, hex('#55603a'));
  for (let i = 0; i < 3; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 7, 0.14);
  t.png(path.join(pasta, 'telha-colonial.png'));
}

// --- fibrocimento: ondas largas (16 px) ao longo da queda, a emenda da chapa
// a cada 64 px no comprido, e o mofo preto escorrendo na direcao da agua.
{
  const r = rng(13); const base = hex('#9a9a92'); const t = new Tela(64, 64, base);
  for (let y = 0; y < 64; y++) for (let x = 0; x < 64; x++) {
    const onda = Math.cos(((x + 0.5) / 16) * Math.PI * 2);
    let c = vezes(base, 1 + 0.12 * onda);
    if (y === 63) c = vezes(c, 0.72);
    if (y === 0) c = vezes(c, 1.08);
    t.set(x, y, c);
  }
  t.ruido(r, 3);
  // Mofo: riscos verticais escuros no fundo das ondas.
  for (let i = 0; i < 7; i++) {
    const x = Math.floor(r() * 4) * 16 + 8 + Math.floor(r() * 3) - 1;
    const y0 = Math.floor(r() * 64), comp = 10 + Math.floor(r() * 30);
    for (let k = 0; k < comp; k++) { const c = t.get(x, y0 + k); t.set(x, y0 + k, vezes(c, 0.72 + 0.2 * (k / comp))); }
  }
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6 + Math.floor(r() * 6), 0.18);
  for (let i = 0; i < 2; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 5, 0.3, hex('#59603f'));
  t.png(path.join(pasta, 'fibrocimento.png'));
}

// --- reboco: claro e quase neutro (a tinta da casa colore), poroso, com
// fissura fina e a sujeira que a chuva deixa.
{
  const r = rng(14); const t = new Tela(64, 64, hex('#d8d4ca'));
  t.ruido(r, 6);
  for (let i = 0; i < 5; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6 + Math.floor(r() * 8), 0.1);
  for (let i = 0; i < 2; i++) t.risco(r, Math.floor(r() * 64), Math.floor(r() * 64), 10 + Math.floor(r() * 8), hex('#a8a49a'));
  t.png(path.join(pasta, 'reboco.png'));
}

// --- tijolo a vista: o tijolo baiano de 16 x 8, laranja queimado, juntas de
// massa cinza e cada tijolo um tom - a casa que parou no meio da obra.
{
  const r = rng(15); const massa = hex('#8a8178'); const t = new Tela(64, 64, massa);
  // Tijolo desbotado: o laranja de obra, mas com poeira.
  for (let fila = 0; fila < 8; fila++) {
    const desloca = (fila % 2) * 8;
    for (let k = 0; k < 4; k++) {
      const cor = vezes(hex('#a2664c'), 0.86 + r() * 0.22);
      for (let dy = 1; dy < 8; dy++) for (let dx = 1; dx < 16; dx++) {
        let c = cor;
        if (dy === 1) c = vezes(c, 1.1);
        if (dy === 7) c = vezes(c, 0.85);
        t.set(k * 16 + dx + desloca, fila * 8 + dy, c);
      }
    }
  }
  t.ruido(r, 5);
  for (let i = 0; i < 3; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 6, 0.15);
  t.png(path.join(pasta, 'tijolo.png'));
}

// --- bloco de concreto: 32 x 16, cinza, juntas finas.
{
  const r = rng(16); const t = new Tela(64, 64, hex('#77756f'));
  for (let fila = 0; fila < 4; fila++) {
    const desloca = (fila % 2) * 16;
    for (let k = 0; k < 2; k++) {
      const cor = vezes(hex('#a3a199'), 0.9 + r() * 0.16);
      for (let dy = 1; dy < 16; dy++) for (let dx = 1; dx < 32; dx++) t.set(k * 32 + dx + desloca, fila * 16 + dy, cor);
    }
  }
  t.ruido(r, 6);
  for (let i = 0; i < 4; i++) t.mancha(Math.floor(r() * 64), Math.floor(r() * 64), 7, 0.14);
  t.png(path.join(pasta, 'bloco.png'));
}
