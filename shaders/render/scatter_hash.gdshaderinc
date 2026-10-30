// The hash that places scattered props. Shared by the prop shaders and the
// terrain (which redraws far trees as flat crowns in exactly their places).

uint phash(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	return v.x ^ v.y ^ v.z;
}

float prnd(uint h, uint k, uint salt) {
	return float(phash(uvec3(h, k, salt)) & 0xFFFFFFu) / 16777216.0;
}

// One prop per world cell c (cells `cell` metres wide): its position, a number
// r to test against a density, and a seed for size and colour.
void cell_prop(ivec2 c, float cell, uint salt, out vec2 p, out float r, out float seed, out float turn) {
	uint h = phash(uvec3(uvec2(c), 7u));
	p = (vec2(c) + vec2(prnd(h, 1u, salt), prnd(h, 2u, salt))) * cell;
	r = prnd(h, 3u, salt);
	seed = prnd(h, 4u, salt);
	turn = prnd(h, 5u, salt) * TAU;
}
