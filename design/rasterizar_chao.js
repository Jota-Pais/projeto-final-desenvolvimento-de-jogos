// O chao do mapa como grade de vertices, para o TileMap da rua (rua/chao.gd).
//
// Le o mapa tracado (rua/mapa_tracado.json) e, para cada vertice da grade de
// tiles de 32 px de mundo, decide que classe de chao esta ali: a do MENOR
// poligono que contem o ponto (o gramado dentro da grama, a horta dentro do
// gramado), respeitando os furos; fora de todo poligono e grama - a mesma
// regra com que rua/cenario.gd pinta. Grava:
//
//   rua/chao_tracado.png   689 x 399 px em cinza, um pixel por vertice, o
//                          valor e o indice da classe em CLASSES
//   rua/chao_tracado.json  as classes na ordem dos indices, e o tamanho
//
// Uso: node design/rasterizar_chao.js   (da pasta do jogo). Sem dependencia.
// Rodar de novo sempre que o desenho do mapa mudar (depois do tracar_desenho).
const fs = require('fs');
const zlib = require('zlib');

const ESCALA = 24;      // px de mundo por px do desenho (rua/mapa.gd, ESCALA)
const TILE = 32;        // px de mundo por tile (rua/chao.gd)
const CLASSES = ['grama', 'gramado', 'mata', 'horta', 'pavimento', 'asfalto', 'milho', 'terra', 'agua'];

const tracado = JSON.parse(fs.readFileSync('rua/mapa_tracado.json', 'utf8'));
const [, , larguraDesenho, alturaDesenho] = tracado.recorte;
const colunas = Math.ceil(larguraDesenho * ESCALA / TILE) + 1;
const linhas = Math.ceil(alturaDesenho * ESCALA / TILE) + 1;

function dentro(p, pontos) {
  let d = false;
  for (let i = 0, k = pontos.length - 1; i < pontos.length; k = i++) {
    const [xi, yi] = pontos[i], [xk, yk] = pontos[k];
    if ((yi > p[1]) !== (yk > p[1]) && p[0] < (xk - xi) * (p[1] - yi) / (yk - yi) + xi) d = !d;
  }
  return d;
}

// Calçada e rua NÃO entram no tile (15/10/2026): o chão feito pelo homem é
// desenhado como polígono de traço reto por cima do TileMap (rua/ruas.gd),
// porque em tile de 32 px toda diagonal vira escada. Por baixo dele fica o
// que o envolve - grama, em geral.
const SO_POLIGONO = new Set(['pavimento', 'asfalto']);
const poligonos = tracado.poligonos
  .filter((p) => CLASSES.includes(p.classe) && !SO_POLIGONO.has(p.classe))
  .slice()
  .sort((a, b) => a.area - b.area);

const grade = Buffer.alloc(colunas * linhas, 0);
const contagem = {};
for (let r = 0; r < linhas; r++) {
  for (let c = 0; c < colunas; c++) {
    // O vertice (c, r) esta em (c * TILE, r * TILE) no mundo; no desenho,
    // dividido pela escala.
    const p = [c * TILE / ESCALA, r * TILE / ESCALA];
    let classe = 'grama';
    for (const pol of poligonos) {
      const [bx, by, bw, bh] = pol.bbox;
      if (p[0] < bx || p[0] > bx + bw || p[1] < by || p[1] > by + bh) continue;
      if (!dentro(p, pol.pontos)) continue;
      if ((pol.furos || []).some((furo) => dentro(p, furo))) continue;
      classe = pol.classe;
      break;
    }
    grade[r * colunas + c] = CLASSES.indexOf(classe);
    contagem[classe] = (contagem[classe] || 0) + 1;
  }
}

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
// PNG em cinza de 8 bits (tipo de cor 0): um byte por vertice, sem perda.
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(colunas, 0);
ihdr.writeUInt32BE(linhas, 4);
ihdr[8] = 8; ihdr[9] = 0; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
const varreduras = [];
for (let r = 0; r < linhas; r++) {
  varreduras.push(Buffer.from([0]));
  varreduras.push(grade.subarray(r * colunas, (r + 1) * colunas));
}
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(Buffer.concat(varreduras))),
  chunk('IEND', Buffer.alloc(0)),
]);
fs.writeFileSync('rua/chao_tracado.png', png);
fs.writeFileSync('rua/chao_tracado.json', JSON.stringify({
  origem: 'rua/mapa_tracado.json',
  tile: TILE,
  escala: ESCALA,
  colunas,
  linhas,
  classes: CLASSES,
  vertices_por_classe: contagem,
}, null, 2) + '\n');
console.log('chao_tracado: ' + colunas + ' x ' + linhas + ' vertices, tile ' + TILE + ' px');
console.log(JSON.stringify(contagem));
