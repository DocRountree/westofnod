shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The figure's cloth (CharacterParts: its shirt, its sleeves, its pants, its
// hats): a weave of its colour, and on a shirt a pattern worked into it in
// two more (CharacterLook: "pattern"). UV.x goes round the garment (front:
// where its front's middle is), UV.y up it in metres; girth: how far round
// it is, m.
//
// The patterns are counted out in stitches (STITCH m square), as weaving,
// beadwork and basketry count theirs, so their edges step: geometric
// designs after Native American work (Dine weaving's bands, serrated
// diamonds and eye dazzlers, the Plains' morning star quilts and beaded
// mountains, basketry's stepped diagonals, a ribbon shirt's ribbons), not
// copies of any one piece. Some run in a band across the chest and back
// (band: its middle's height, m; its half height in stitches), some all
// over, the star once on the chest and once on the back.

#include "res://shaders/render/aerial.gdshaderinc"

uniform vec3 base : source_color = vec3(0.6, 0.2, 0.15);
uniform vec3 accent : source_color = vec3(0.95, 0.9, 0.8);
uniform vec3 accent2 : source_color = vec3(0.15, 0.13, 0.12);
uniform int pattern = 0; // (CharacterLook.PATTERN_IDS; 100: a trim, two lines round it at band.x)
uniform float girth = 1.0;
uniform float front = 0.75; // (UV.x at the garment's front's middle: a tube's, CharacterMesh)
uniform vec2 band = vec2(0.3, 8.0);
uniform float rough = 0.92;
global uniform float night;

const float STITCH = 0.0075;

varying vec3 world_pos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

int imod(int a, int m) {
	return a - m * int(floor(float(a) / float(m)));
}

// (how far a is from the nearest multiple of m, in stitches: a motif's own
// column counted from its middle)
int fold(int a, int m) {
	return abs(imod(a + m / 2, m) - m / 2);
}

// Which colour a stitch is: 0 the cloth's, 1 the pattern's, 2 its second.
// c: the stitch (x from the front's middle, y from the band's); h: the
// band's half height; half_round: stitches from the front's middle to the
// back's.
int stitch(ivec2 c, int h, int half_round) {
	int ay = abs(c.y);
	bool in_band = ay <= h;
	int edge = ay == h + 2 ? 1 : (ay == h + 4 ? 2 : 0); // (a band's borders)
	if (pattern == 1) { // chief bands: broad stripes, blocks set in them
		int r = imod(c.y + 4, 26);
		if (r < 8) {
			if (fold(c.x, 28) < 4 && r >= 1 && r < 7) return 2;
			return (r == 3 || r == 4) ? 2 : 1;
		}
		return (r == 13 || r == 21) ? 2 : 0;
	}
	if (pattern == 2) { // stepped diamonds, one in another
		if (!in_band) return edge;
		int k = fold(c.x, 22) + ay;
		if (k > h + 1) return 0;
		int ring = k / 3;
		return ring == 0 ? 2 : (imod(ring, 2) == 1 ? 1 : (imod(ring, 4) == 0 ? 2 : 0));
	}
	if (pattern == 3) { // eye dazzler: serrated zigzags, all over
		int k = imod(c.y + fold(c.x, 16), 10);
		return k < 3 ? 1 : (k < 5 ? 2 : (k == 7 ? 1 : 0));
	}
	if (pattern == 4) { // morning star: eight points (a square on a square, turned), in rings
		int cx = abs(c.x) > half_round / 2 ? abs(c.x) - half_round : c.x; // (and on the back)
		int ax = abs(cx);
		float k = min(float(max(ax, ay)), float(ax + ay) / 1.4142);
		if (k > float(h + 3)) return 0;
		int ring = int(k / 2.5);
		return ring == 0 ? 2 : (imod(ring, 3) == 1 ? 1 : (imod(ring, 3) == 2 ? 2 : 0));
	}
	if (pattern == 5) { // arrow chevrons
		if (!in_band) return edge;
		int k = imod(c.y + fold(c.x, 14) + 60, 7);
		return k < 2 ? 1 : (k == 4 ? 2 : 0);
	}
	if (pattern == 6) { // mountains: stepped triangles, point to point
		if (!in_band) return edge;
		int dx = fold(c.x, 16);
		int reach = ((h - ay) * 7) / h; // (widest at the band's edges: two rows of peaks meeting)
		reach = 7 - reach;
		if (dx <= reach - 4) return 2;
		return dx <= reach ? 1 : 0;
	}
	if (pattern == 7) { // basket steps: stairs across it
		int k = imod(int(floor(float(c.x) / 3.0)) + int(floor(float(c.y) / 3.0)), 7);
		return k == 0 ? 1 : (k == 1 ? 2 : (k == 4 ? 1 : 0));
	}
	if (pattern == 8) { // ribbons: three across the chest and back, two hanging at the front
		if (c.y >= 5 && c.y <= 8) return 1;
		if (c.y >= 0 && c.y <= 2) return 2;
		if (c.y >= -6 && c.y <= -4) return 1;
		if (abs(c.x) < half_round / 2 && c.y < -6 && c.y > -34) {
			int dx = abs(abs(c.x) - 15);
			if (dx <= 1) return c.x > 0 ? 1 : 2;
			if (abs(abs(c.x) - 19) <= 1) return c.x > 0 ? 2 : 1;
		}
		return 0;
	}
	if (pattern == 9) { // four directions: stepped crosses
		if (!in_band) return edge;
		int lx = fold(c.x, 20);
		if (lx == 0 && ay == 0) return 0;
		if ((lx <= 1 && ay <= h - 1) || (ay <= 1 && lx <= h - 1)) return 1;
		if ((lx <= 3 && ay <= h - 4) || (ay <= 3 && lx <= h - 4)) return 2;
		return 0;
	}
	if (pattern == 10) { // lightning: three zigzags
		if (!in_band) return edge;
		int k = c.y - fold(c.x, 12) + 3;
		if (k == 5 || k == 4 || k == -4 || k == -5) return 1;
		return (k == 0 || k == 1) ? 2 : 0;
	}
	if (pattern == 100) // a trim (a cuff, a hem)
		return (ay == 0 || ay == 1) ? 1 : (ay == 3 ? 2 : 0);
	return 0;
}

vec3 dye(int k) {
	return k == 0 ? base : (k == 1 ? accent : accent2);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vec2((fract(UV.x - front + 0.5) - 0.5) * girth, UV.y - band.x) / STITCH;
	vec3 col = base;
	if (pattern != 0) {
		// (four stitches' worth a pixel, a little apart: the steps don't
		// crawl far off)
		vec2 dx = dFdx(p) * 0.35, dy = dFdy(p) * 0.35;
		int h = int(band.y);
		int half_round = int(girth * 0.5 / STITCH);
		col = vec3(0.0);
		for (int k = 0; k < 4; k++) {
			vec2 o = (k == 0 ? dx + dy * 0.4 : (k == 1 ? -dx - dy * 0.4 : (k == 2 ? dy - dx * 0.4 : -dy + dx * 0.4)));
			col += dye(stitch(ivec2(floor(p + o)), h, half_round));
		}
		col *= 0.25;
	}
	// the weave: each stitch a little its own shade, its threads' furrows,
	// near (gone where a stitch is under a pixel)
	float px = max(length(fwidth(p)), 1e-4);
	float near = 1.0 - smoothstep(0.25, 1.2, px);
	vec2 t = p * 2.0;
	float thread = 0.5 + 0.5 * sin(t.x * 6.2832) * sin(t.y * 6.2832);
	col *= mix(1.0, 0.9 + 0.1 * hash2(floor(p)) + 0.06 * (thread - 0.5), near);
	ALBEDO = col * (1.0 - 0.35 * night);
	ROUGHNESS = rough;
	SPECULAR = 0.2;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
