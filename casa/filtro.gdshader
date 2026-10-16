// O filtro da casa: a noite esverdeada, o grao e a vinheta.
//
// E o que faz a tela ler como *No, I'm Not a Human*: la, a noite lava tudo num
// verde-azulado doente, a imagem tem grao de camera velha e as bordas afundam
// no preto.
//
// **Afinado para as fotos em 16/10/2026.** O filtro nasceu para o greybox,
// pintado em cores "de dia": uma curva que jogava no preto tudo abaixo de 0,12
// de luminancia e tingia 74 % de verde. As fotos da equipe ja vem escurecidas
// e sujas, e com aquela curva ~36 % de cada uma (e ~50 % do quarto) virava
// preto - as correntes, as maos e o sangue do quarto sumiam. Agora a curva nao
// corta a sombra (`sombra` = 0) e a abre um pouco (`gama` < 1), o verde fica em
// 55 % (o sangue continua vermelho-escuro) e a vinheta afunda menos.
shader_type canvas_item;

uniform vec3 matiz : source_color = vec3(0.32, 0.92, 0.80);
// 0 = cor original, 1 = tudo no verde da noite.
uniform float noite : hint_range(0.0, 1.0) = 0.55;
// A curva de luz: luminancia `sombra` ou menos vira preto, `luz` ou mais vira o
// mais claro, e `gama` abaixo de 1 abre as sombras (acima de 1, fecha).
uniform float sombra : hint_range(0.0, 0.5) = 0.0;
uniform float luz : hint_range(0.2, 1.0) = 0.58;
uniform float gama : hint_range(0.3, 2.0) = 0.8;
uniform float grao : hint_range(0.0, 0.3) = 0.085;
uniform float vinheta : hint_range(0.0, 1.0) = 0.72;
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

	// A curva antes de tingir, e o verde por cima so em parte: a cor da foto
	// segue embaixo, com a luz que a curva deu.
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float curva = pow(max(clamp((l - sombra) / (luz - sombra), 0.0, 1.0), 0.00001), gama);
	vec3 de_noite = matiz * curva * 1.25;
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
