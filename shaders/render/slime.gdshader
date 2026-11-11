shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// A snail's slime trail (Snails): dabs on the ground, each a quad (its
// instance: laid along the way it went; INSTANCE_CUSTOM.x when it was laid,
// on the colony's clock, now), a thin wet film: glistening, a little
// silvery, ragged at its edges, drying away over a few minutes.

uniform float now = 0.0;
uniform float dries = 240.0; // s till it's gone

varying float age;
varying float rnd;

void vertex() {
	age = now - INSTANCE_CUSTOM.x;
	rnd = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	// (an oval, its edges wavering)
	float edge = 1.0 - smoothstep(0.55, 1.0, length(vec2(q.x * (1.0 + 0.15 * sin(q.y * 7.0 + rnd * 30.0)), q.y * 0.7)));
	float fresh = 1.0 - smoothstep(dries * 0.3, dries, age);
	ALBEDO = vec3(0.75, 0.78, 0.8);
	ROUGHNESS = mix(0.35, 0.04, fresh);
	SPECULAR = 0.9;
	METALLIC = 0.15;
	ALPHA = edge * (0.12 + 0.16 * fresh) * step(0.0, age) * step(age, dries);
}
