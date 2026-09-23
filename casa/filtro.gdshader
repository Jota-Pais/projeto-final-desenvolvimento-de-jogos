// O filtro da casa: a noite esverdeada, o grao e a vinheta.
//
// E o que faz a tela ler como *No, I'm Not a Human* antes de existir uma arte
// so: la, a noite lava tudo num verde-azulado doente, a imagem tem grao de
// camera velha e as bordas afundam no preto. O desenho do comodo e feito em
// cores "de dia" e e este filtro que as leva para a noite - entao a arte que
// entrar depois (casa/arte/) pode ser pintada em cor normal.
shader_type canvas_item;

uniform vec3 matiz : source_color = vec3(0.32, 0.92, 0.80);
// 0 = cor original, 1 = tudo no verde da noite.
uniform float noite : hint_range(0.0, 1.0) = 0.74;
uniform float grao : hint_range(0.0, 0.3) = 0.085;
uniform float vinheta : hint_range(0.0, 1.0) = 0.85;
uniform vec2 resolucao = vec2(640.0, 360.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// Um fio de aberracao cromatica: lente barata, nao efeito especial.
	float ab = 0.0012;
	vec3 c;
	c.r = texture(TEXTURE, UV + vec2(ab, 0.0)).r;
	c.g = texture(TEXTURE, UV).g;
	c.b = texture(TEXTURE, UV - vec2(ab, 0.0)).b;

	// Curva de contraste antes de tingir: o que e meio-tom afunda, o que e
	// claro estoura. E o que da o preto fundo e o brilho doente da referencia.
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float curva = smoothstep(0.12, 0.78, l);
	vec3 de_noite = matiz * pow(curva, 1.15) * 1.25;
	vec3 cor = mix(c * curva / max(l, 0.001), de_noite, noite);
	// A sombra nunca e preto puro: afunda num verde muito escuro.
	cor = cor + vec3(0.0, 0.018, 0.015);

	vec2 px = floor(UV * resolucao);
	cor += (hash(px + floor(TIME * 18.0) * 17.0) - 0.5) * grao;

	vec2 d = (UV - 0.5) * vec2(1.0, 0.8);
	float borda = smoothstep(0.62, 0.22, length(d));
	cor *= mix(1.0, borda, vinheta);

	// A lampada nao e estavel.
	cor *= 0.975 + 0.025 * sin(TIME * 9.0 + sin(TIME * 2.3) * 3.0);

	COLOR = vec4(clamp(cor, 0.0, 1.0), 1.0);
}
