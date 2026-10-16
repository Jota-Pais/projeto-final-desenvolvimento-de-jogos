// Desenha as oito armas de lado, apontando para a direita, e grava um PNG de
// cada em <pasta>/<nome>.png. Sem dependencia: PNG montado na mao (zlib do Node).
// Uso: node armas-png.js <pasta>
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

// Cores da arte do jogador/zumbi: contorno, destaque,
// metal, escuro, madeira, polimero.
const PALETA = {
  '#': [0x05, 0x04, 0x03, 255],
  'h': [0x5c, 0x5b, 0x5c, 255],
  'g': [0x2d, 0x2e, 0x2e, 255],
  'd': [0x1a, 0x19, 0x1e, 255],
  'w': [0x77, 0x65, 0x62, 255],
  'k': [0x3c, 0x3a, 0x44, 255],
  '.': [0, 0, 0, 0],
};

// O pixel da mao (o cabo) de cada uma esta na ficha em rua/arma.gd (`mao`).
const ARMAS = {
  'revolver-38': [
    '....###.....',
    '...#ggg#####',
    '..#hgggghhh#',
    '..#ggggggg##',
    '.##gg##d#...',
    '#ww###.###..',
    '#ww#........',
    '.##.........',
  ],
  'beretta-9mm': [
    '..##########',
    '.#hhhhhhhhh#',
    '.#ggggggggg#',
    '##gg########',
    '#gg#..#d#...',
    '#gg#..###...',
    '.##.........',
  ],
  'doze-2-canos': [
    '.......###################',
    '......#hhhhhhhhhhhhhhhhhh#',
    '.....#ggggggggggggggggggg#',
    '####wwwww#################',
    '#wwwwwwww##.#d#...........',
    '#wwwww###...###...........',
    '.####.....................',
  ],
  'benelli-semiauto': [
    '........##################',
    '.......#hhhhhhhhhhhhhhhhh#',
    '....###ggggggggggggggggg##',
    '###kkkk##ddddddddddddddd#.',
    '#kkkkkkk##.#d#............',
    '#kkkkk##...###............',
    '.####.....................',
  ],
  'ctt40': [
    '....############',
    '...#hhhhhhhhhhh#',
    '..##ggggggggggg#',
    '###gggggg#######',
    '#kk###gg#d#.....',
    '#kk#.#gg#.##....',
    '.##..#gg#.......',
    '.....#gg#.......',
    '.....####.......',
  ],
  'fireagle-9mm': [
    '...#############..',
    '..#hhhhhhhhhhhhh##',
    '.##ggggggggggggg#.',
    '###ggggg#####gg##.',
    '#kk##gg#d#..#gg#..',
    '#kk#.#gg#.##.#gg#.',
    '.##..#gg#....####.',
    '.....#gg#.........',
    '.....####.........',
  ],
  'fall': [
    '...........#######............',
    '........###hhhhhhh############',
    '....#####ggggggggggggwwwwwwgg#',
    '#####wwwwggggggggg##wwwwww####',
    '#wwwwwwwww#d#.#gg#............',
    '#wwwwww##.##..#gg#............',
    '.######.......#gg#............',
    '..............#gg#............',
    '...............##.............',
  ],
  'm4': [
    '..........#######...........',
    '.......###hhhhhhh###########',
    '..#####gggggggggggkkkkkkkgg#',
    '###kkkkggggggggg##kkkkkkk###',
    '#kkkkkkkk#d#.#gg#...........',
    '#kkkkk###.##..#gg#..........',
    '.#####........#gg#..........',
    '..............#gg#..........',
    '...............##...........',
  ],
};

function crc32(buf) {
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let k = 0; k < 8; k++) crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
  }
  return (~crc) >>> 0;
}

function chunk(tipo, dados) {
  const tamanho = Buffer.alloc(4);
  tamanho.writeUInt32BE(dados.length);
  const corpo = Buffer.concat([Buffer.from(tipo, 'ascii'), dados]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(corpo));
  return Buffer.concat([tamanho, corpo, crc]);
}

function png(desenho, nome) {
  const largura = desenho[0].length;
  const altura = desenho.length;
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(largura, 0);
  ihdr.writeUInt32BE(altura, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const linhas = [];
  for (const linha of desenho) {
    if (linha.length !== largura) throw new Error(nome + ': linha com largura errada: ' + linha);
    const bytes = [0];
    for (const c of linha) {
      const cor = PALETA[c];
      if (!cor) throw new Error(nome + ': cor desconhecida: ' + c);
      bytes.push(...cor);
    }
    linhas.push(Buffer.from(bytes));
  }
  return {
    largura, altura,
    bytes: Buffer.concat([
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      chunk('IHDR', ihdr),
      chunk('IDAT', zlib.deflateSync(Buffer.concat(linhas))),
      chunk('IEND', Buffer.alloc(0)),
    ]),
  };
}

const pasta = process.argv[2];
if (!pasta) throw new Error('passe a pasta de saida');
fs.mkdirSync(pasta, { recursive: true });
for (const [nome, desenho] of Object.entries(ARMAS)) {
  const feito = png(desenho, nome);
  fs.writeFileSync(path.join(pasta, nome + '.png'), feito.bytes);
  console.log(nome + ': ' + feito.largura + ' x ' + feito.altura + ' px');
}
