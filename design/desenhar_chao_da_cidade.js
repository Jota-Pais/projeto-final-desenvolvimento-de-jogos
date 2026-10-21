#!/usr/bin/env node
'use strict';
/**
 * Os ladrilhos do chão da cidade (21/10/2026), por regra: o asfalto, a
 * calçada, o cimentado do pátio, o quintal e o terreno baldio que o
 * design/tracar_ruas.js separa. Escreve rua/arte/chao/cidade-<nome>.png, 256 x
 * 256, que repetem sem emenda (todo ruído aqui é periódico em 256), 1 pixel
 * por px de mundo, nas cores da paleta do chão (paleta.json: grama oliva
 * morto, calçada cinza sujo, asfalto cinza-escuro neutro).
 *
 * O asfalto de antes (cheio-asfalto.png) era feito de blocos de 32 px de
 * cinzas diferentes - na tela, um tabuleiro de xadrez (João, 21/10). Este tem
 * o grão do agregado e uma variação larga e fraca, sem bloco.
 *
 *   node design/desenhar_chao_da_cidade.js [pasta]
 */
const fs = require('fs');
const path = require('path');
const { escreverPng } = require('./tracar_desenho.js');

const PASTA = process.argv[2] || path.join(__dirname, '..', 'rua', 'arte', 'chao');
const L = 256;

// Sorteio com semente (o mesmo PNG toda vez).
function sorteio(semente) {
  let s = semente >>> 0;
  return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}

/** Ruído de valor periódico: grade de `celulas` por lado, suave, em [0, 1). */
function ruido(celulas, semente) {
  const r = sorteio(semente);
  const g = Array.from({ length: celulas * celulas }, r);
  const at = (i, j) => g[((j % celulas + celulas) % celulas) * celulas + ((i % celulas + celulas) % celulas)];
  const s = (t) => t * t * (3 - 2 * t);
  return (x, y) => {
    const fx = x / L * celulas, fy = y / L * celulas;
    const i = Math.floor(fx), j = Math.floor(fy), u = s(fx - i), v = s(fy - j);
    const a = at(i, j), b = at(i + 1, j), c = at(i, j + 1), d = at(i + 1, j + 1);
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  };
}

const hex = (h) => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const somar = (c, d) => c.map((v) => Math.max(0, Math.min(255, Math.round(v + d))));
const misturar = (a, b, t) => a.map((v, k) => Math.round(v + (b[k] - v) * t));

function ladrilho(nome, pixel) {
  const rgb = Buffer.alloc(L * L * 3);
  for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) {
    const c = pixel(x, y);
    rgb[(y * L + x) * 3] = c[0]; rgb[(y * L + x) * 3 + 1] = c[1]; rgb[(y * L + x) * 3 + 2] = c[2];
  }
  const arquivo = path.join(PASTA, `cidade-${nome}.png`);
  escreverPng(arquivo, L, L, rgb);
  console.log(arquivo);
}

// O asfalto: grão do agregado (pixel a pixel), mancha larga e fraca, pedrinha
// clara e escura espalhada.
{
  const r = sorteio(11), largo = ruido(4, 12), medio = ruido(16, 13);
  const base = hex('#454547');
  const grao = Array.from({ length: L * L }, () => r());
  ladrilho('asfalto', (x, y) => {
    const g = grao[y * L + x];
    let d = (largo(x, y) - 0.5) * 7 + (medio(x, y) - 0.5) * 4 + (g - 0.5) * 6;
    if (g > 0.975) d += 12; else if (g < 0.04) d -= 8;
    return somar(base, d);
  });
}

// A calçada: lajota quadrada de 16 px (40 cm) com junta de 1 px; cada lajota
// com o tom dela, umas mais gastas.
{
  const r = sorteio(21), grao = Array.from({ length: L * L }, () => r());
  const LADO = 16, n = L / LADO;
  const tons = Array.from({ length: n * n }, () => (r() - 0.5) * 9);
  const tons2 = Array.from({ length: n * n }, () => r());
  const base = hex('#67655f'), junta = hex('#4e4d4a');
  ladrilho('calcada', (x, y) => {
    if (x % LADO === 0 || y % LADO === 0) return somar(junta, (grao[y * L + x] - 0.5) * 4);
    const t = Math.floor(y / LADO) * n + Math.floor(x / LADO);
    let d = tons[t] + (grao[y * L + x] - 0.5) * 6;
    // A beira de cima e da esquerda da lajota pega mais luz.
    if (x % LADO === 1 || y % LADO === 1) d += 4;
    // Lajota gasta: o meio escurecido.
    if (tons2[t] > 0.88) d -= 6 * (1 - Math.hypot(x % LADO - 8, y % LADO - 8) / 11);
    return somar(base, d);
  });
}

// O cimentado do pátio: placa de 64 px (1,6 m) com junta serrada, mancha.
{
  const r = sorteio(31), grao = Array.from({ length: L * L }, () => r());
  const mancha = ruido(8, 32), fino = ruido(32, 33);
  const LADO = 64, n = L / LADO;
  const tons = Array.from({ length: n * n }, () => (r() - 0.5) * 6);
  const base = hex('#6d6b65'), junta = hex('#525150');
  ladrilho('cimentado', (x, y) => {
    if (x % LADO === 0 || y % LADO === 0) return junta;
    const t = Math.floor(y / LADO) * n + Math.floor(x / LADO);
    let d = tons[t] + (grao[y * L + x] - 0.5) * 5 + (fino(x, y) - 0.5) * 4;
    const m = mancha(x, y);
    if (m > 0.72) d -= (m - 0.72) * 16;
    return somar(base, d);
  });
}

// O quintal: grama rala (os tons da grama da paleta) com terra aparecendo.
{
  const r = sorteio(41), grao = Array.from({ length: L * L }, () => r());
  const terra = ruido(6, 42), fino = ruido(24, 43);
  const gramas = ['#3d4229', '#46502c', '#4b5631', '#525c33', '#3a3f27'].map(hex);
  const terras = ['#5a4a38', '#514233', '#5f4f3c'].map(hex);
  ladrilho('quintal', (x, y) => {
    const g = grao[y * L + x];
    const t = terra(x, y) * 0.75 + fino(x, y) * 0.25;
    // Na beira da terra, salpicado: tufo de grama no meio do chão.
    const corte = 0.56 + (g - 0.5) * 0.12;
    if (t > corte) return somar(terras[Math.floor(g * terras.length)], (fino(x, y) - 0.5) * 6);
    const c = gramas[Math.floor(g * gramas.length)];
    return somar(c, (terra(x, y) - 0.5) * 5);
  });
}

// O terreno baldio: terra batida, tufo de mato, pedrinha e caco de tijolo.
{
  const r = sorteio(51), grao = Array.from({ length: L * L }, () => r());
  const largo = ruido(5, 52), fino = ruido(20, 53), mato = ruido(12, 54);
  const terras = ['#56483a', '#4e4134', '#5f5040', '#53463a'].map(hex);
  const matos = ['#46502c', '#525c33', '#3d4229'].map(hex);
  const cacos = Array.from({ length: 70 }, () => [Math.floor(r() * L), Math.floor(r() * L), r()]);
  ladrilho('baldio', (x, y) => {
    const g = grao[y * L + x];
    for (const [cx, cy, k] of cacos) {
      const dx = Math.min(Math.abs(x - cx), L - Math.abs(x - cx)), dy = Math.min(Math.abs(y - cy), L - Math.abs(y - cy));
      if (dx <= 1 && dy <= 0) return k > 0.6 ? hex('#7d5a48') : k > 0.3 ? hex('#7a7468') : hex('#5d5a52');
    }
    const m = mato(x, y) * 0.7 + fino(x, y) * 0.3;
    if (m > 0.62 + (g - 0.5) * 0.18) return somar(matos[Math.floor(g * matos.length)], (largo(x, y) - 0.5) * 6);
    return somar(terras[Math.floor(g * terras.length)], (largo(x, y) - 0.5) * 8);
  });
}
