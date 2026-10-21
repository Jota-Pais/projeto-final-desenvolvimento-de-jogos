// Os sons do arremesso (21/10/2026), sintetizados por regra: o assobio da mao,
// a pedra batendo no chao e a garrafa quebrando. **Sao marcadores** ate a
// equipe de som (o Renan) trocar por gravacao - o nome do arquivo e o que o
// jogo chama, entao trocar e so substituir o .wav.
//
// Uso: node design/sintetizar_arremesso.js som/arremesso
const fs = require('fs');
const path = require('path');

const pasta = process.argv[2];
if (!pasta) throw new Error('passe a pasta de saida');
fs.mkdirSync(pasta, { recursive: true });

const TAXA = 22050;
let semente = 21;
const aleatorio = () => { semente = (semente * 1103515245 + 12345) & 0x7fffffff; return semente / 0x7fffffff; };
const ruido = () => aleatorio() * 2 - 1;

function wav(nome, amostras) {
  let pico = 0;
  for (const a of amostras) pico = Math.max(pico, Math.abs(a));
  const ganho = pico > 0 ? 0.85 / pico : 1;
  const dados = Buffer.alloc(amostras.length * 2);
  amostras.forEach((a, i) => dados.writeInt16LE(Math.round(Math.max(-1, Math.min(1, a * ganho)) * 32767), i * 2));
  const cab = Buffer.alloc(44);
  cab.write('RIFF', 0); cab.writeUInt32LE(36 + dados.length, 4); cab.write('WAVE', 8);
  cab.write('fmt ', 12); cab.writeUInt32LE(16, 16); cab.writeUInt16LE(1, 20); cab.writeUInt16LE(1, 22);
  cab.writeUInt32LE(TAXA, 24); cab.writeUInt32LE(TAXA * 2, 28); cab.writeUInt16LE(2, 32); cab.writeUInt16LE(16, 34);
  cab.write('data', 36); cab.writeUInt32LE(dados.length, 40);
  fs.writeFileSync(path.join(pasta, nome + '.wav'), Buffer.concat([cab, dados]));
  console.log(nome + '.wav: ' + (amostras.length / TAXA).toFixed(2) + ' s');
}

// O assobio: ruido filtrado que sobe e desce, como algo passando rapido.
{
  const n = Math.round(TAXA * 0.28); const s = new Float32Array(n); let lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / n; const corte = 0.05 + 0.25 * Math.sin(Math.PI * t);
    lp += corte * (ruido() - lp);
    s[i] = lp * Math.sin(Math.PI * t) ** 2;
  }
  wav('arremessar', s);
}

// A pedra: o toque seco no chao e um quique menor logo depois.
{
  const n = Math.round(TAXA * 0.35); const s = new Float32Array(n);
  const batida = (inicio, forca, tom) => {
    for (let i = 0; i < TAXA * 0.06; i++) {
      const k = Math.round(TAXA * inicio) + i; if (k >= n) break;
      const t = i / TAXA; const env = Math.exp(-t * 90);
      s[k] += forca * env * (0.6 * Math.sin(2 * Math.PI * tom * t) + 0.5 * ruido() * Math.exp(-t * 200));
    }
  };
  batida(0, 1.0, 620); batida(0.12, 0.45, 700); batida(0.2, 0.2, 760);
  wav('pedra', s);
}

// A garrafa: o estalo do vidro e uma chuva de cacos agudos que vai sumindo.
{
  const n = Math.round(TAXA * 0.7); const s = new Float32Array(n);
  for (let i = 0; i < TAXA * 0.03; i++) s[i] += ruido() * Math.exp(-i / TAXA * 120);
  for (let c = 0; c < 40; c++) {
    const inicio = Math.round(TAXA * (aleatorio() ** 2) * 0.55); const tom = 2200 + aleatorio() * 4200;
    const forca = 0.15 + aleatorio() * 0.5;
    for (let i = 0; i < TAXA * 0.05; i++) {
      const k = inicio + i; if (k >= n) break;
      const t = i / TAXA;
      s[k] += forca * Math.exp(-t * 70) * Math.sin(2 * Math.PI * tom * t) * Math.exp(-inicio / TAXA * 3);
    }
  }
  let hp = 0, ant = 0;
  for (let i = 0; i < n; i++) { const r = ruido(); hp = 0.9 * (hp + r - ant); ant = r; s[i] += 0.25 * hp * Math.exp(-i / TAXA * 9); }
  wav('garrafa', s);
}
