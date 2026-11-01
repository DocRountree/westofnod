// Stippled hand-over between levels of detail. Near a switch Population
// draws both levels; a 4x4 ordered dither picks, pixel by pixel, which one
// shows, with complementary thresholds so every pixel shows exactly one of
// the two, and the share moves from the one to the other over lod_range.z
// either side of the switch. Each level's materials carry its span; the
// distance is to the middle of the tree's chunk (found from where the tree
// stands: chunks are a fixed grid), so a chunk's trees hand over together,
// dissolving into the next level rather than popping.
//
// (Plain material uniforms, not per-node instance uniforms: there are far
// more chunk nodes than Godot's instance-uniform buffer holds.)

uniform vec3 lod_range = vec3(0.0, 1e9, 0.0); // begin, end, fade (m either side); fade 0: off
uniform float lod_chunk = 64.0;               // Population.CHUNK
uniform float lod_mid_height = 6.0;           // m above the foot: about the middle of the chunk's box

float bayer4(vec2 frag) {
	ivec2 q = ivec2(mod(frag, 4.0));
	int i = q.x + q.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

// True where this level isn't drawn (discard). Not in the (orthographic)
// directional shadow pass, where the camera is the light.
bool lod_hidden(vec2 frag, vec3 cam, mat4 proj, mat4 model) {
	if (lod_range.z <= 0.0 || proj[3][3] > 0.5) return false;
	vec3 o = model[3].xyz;
	vec3 centre = vec3((floor(o.x / lod_chunk) + 0.5) * lod_chunk, o.y + lod_mid_height, (floor(o.z / lod_chunk) + 0.5) * lod_chunk);
	float d = distance(cam, centre);
	float b = bayer4(frag);
	float fade_in = lod_range.x > 0.0 ? smoothstep(lod_range.x - lod_range.z, lod_range.x + lod_range.z, d) : 1.0;
	float fade_out = 1.0 - smoothstep(lod_range.y - lod_range.z, lod_range.y + lod_range.z, d);
	return fade_in <= 1.0 - b || fade_out <= b;
}
