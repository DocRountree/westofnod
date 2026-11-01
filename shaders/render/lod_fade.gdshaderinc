// Stippled hand-over between levels of detail (Population sets these on
// each level's node). Near a switch both levels are drawn; a 4x4 ordered
// dither picks, pixel by pixel, which one shows, with complementary
// thresholds so every pixel shows exactly one of the two, and the share
// moves from the one to the other over lod_range.z either side of the
// switch. The whole chunk hands over together (lod_centre), so its trees
// dissolve into the next level rather than pop.

instance uniform vec3 lod_range = vec3(0.0, 1e9, 0.0); // begin, end, fade (m either side); fade 0: off
instance uniform vec3 lod_centre = vec3(0.0);           // the chunk's middle (world)

float bayer4(vec2 frag) {
	ivec2 q = ivec2(mod(frag, 4.0));
	int i = q.x + q.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

// True where this level isn't drawn (discard). Not in the (orthographic)
// directional shadow pass, where the camera is the light.
bool lod_hidden(vec2 frag, vec3 cam, mat4 proj) {
	if (lod_range.z <= 0.0 || proj[3][3] > 0.5) return false;
	float d = distance(cam, lod_centre);
	float b = bayer4(frag);
	float fade_in = lod_range.x > 0.0 ? smoothstep(lod_range.x - lod_range.z, lod_range.x + lod_range.z, d) : 1.0;
	float fade_out = 1.0 - smoothstep(lod_range.y - lod_range.z, lod_range.y + lod_range.z, d);
	return fade_in <= 1.0 - b || fade_out <= b;
}
