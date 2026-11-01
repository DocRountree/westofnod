// Stippled hand-over between levels of detail, decided per tree. Each
// level's materials carry its span (lod_range: begin, end, fade m either
// side); the distance is the camera's to the tree (its origin, lifted to
// about the middle of its height). Near a switch both levels draw the tree
// and a 4x4 ordered dither picks, pixel by pixel, which one shows, with
// complementary thresholds so every pixel shows exactly one of the two;
// the share moves smoothly from one to the other across the band, so a
// tree dissolves into its next level instead of popping. Outside its span
// a level collapses the whole tree to a point in the vertex shader (no
// pixels), so Population can keep its nodes drawn well past their span.

uniform vec3 lod_range = vec3(0.0, 1e9, 0.0); // fade 0: off
uniform float lod_mid_height = 6.0;           // m above the foot (at scale 1)

float bayer4(vec2 frag) {
	ivec2 q = ivec2(mod(frag, 4.0));
	int i = q.x + q.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

// (fade in, fade out) of this level for the tree at `model`, 0..1 each.
vec2 lod_fades(vec3 cam, mat4 model) {
	vec3 o = model[3].xyz + model[1].xyz * lod_mid_height;
	float d = distance(cam, o);
	float fade_in = lod_range.x > 0.0 ? smoothstep(lod_range.x - lod_range.z, lod_range.x + lod_range.z, d) : 1.0;
	float fade_out = 1.0 - smoothstep(lod_range.y - lod_range.z, lod_range.y + lod_range.z, d);
	return vec2(fade_in, fade_out);
}

// Vertex: true when this level doesn't show this tree at all. Not in the
// (orthographic) directional shadow pass, where the camera is the light.
bool lod_gone(vec3 cam, mat4 model, mat4 proj) {
	if (lod_range.z <= 0.0 || proj[3][3] > 0.5) return false;
	vec2 f = lod_fades(cam, model);
	return f.x <= 0.0 || f.y <= 0.0;
}

// Fragment: true where this level isn't drawn (discard).
bool lod_hidden(vec2 frag, vec3 cam, mat4 proj, mat4 model) {
	if (lod_range.z <= 0.0 || proj[3][3] > 0.5) return false;
	vec2 f = lod_fades(cam, model);
	float b = bayer4(frag);
	return f.x <= 1.0 - b || f.y <= b;
}
