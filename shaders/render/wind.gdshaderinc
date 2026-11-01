// The wind in the trees: the thin outer wood and the leaves on it sway
// together (the same motion for the same place, so a twig and its leaves
// move as one), slowly, in gusts. weight: 0 on the stout wood, 1 at the
// twig tips (bark: UV2.y from TreeBuilder; leaf cards: 1).

uniform float sway = 0.09; // m at the tips, in a full gust

vec3 wind_sway(vec3 world, float t) {
	float ph = dot(world.xz, vec2(0.13, 0.09)) + world.y * 0.05;
	float gust = 0.55 + 0.45 * sin(t * 0.31 + dot(world.xz, vec2(0.011, 0.007)));
	return vec3(sin(t * 1.3 + ph), 0.25 * sin(t * 1.7 + ph * 1.9), cos(t * 1.05 + ph * 1.3)) * sway * gust;
}

// The sway as an offset in the model's own space (for VERTEX).
vec3 wind_local(mat4 model, vec3 local, float weight, float t) {
	if (weight <= 0.0) return vec3(0.0);
	vec3 w = wind_sway((model * vec4(local, 1.0)).xyz, t) * weight;
	return inverse(mat3(model)) * w;
}
