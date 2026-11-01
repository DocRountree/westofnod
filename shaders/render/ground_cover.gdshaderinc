// Shared by ground_cover_bake.gdshader (works out each cell) and
// ground_cover.gdshader (draws it): where a cell's clump stands, and how a
// cell's data is packed into two RGBA8 texels side by side:
//   texel 2x:     height of the ground as drawn (16 bits, from base_h - 512 m,
//                 1/64 m steps),
//                 size (8 bits, of SIZE_MAX m; 0: nothing grows here),
//                 how blonde (the prairie's grass)
//   texel 2x + 1: the ground's colour (sRGB), how much prairie (0: all
//                 forest)

uniform float cell = 0.4;  // m: the grid the clumps stand on
uniform int seed = 0;

const float SIZE_MAX = 3.2; // m

float gc_hash(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

// The k-th random number of cell c, 0..1.
float h2(ivec2 c, int k) {
	return gc_hash(c * 3 + ivec2(seed * 7919 + k * 131, k * 977 - seed));
}

// Where cell c's clump stands (world xz): somewhere in the cell.
vec2 cell_pos(ivec2 c) {
	return vec2(c) * cell + vec2(h2(c, 1), h2(c, 2)) * cell;
}
