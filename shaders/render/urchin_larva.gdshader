shader_type spatial;
render_mode cull_disabled, depth_draw_always;
// A sea urchin's eggs and larvae (scripts/creatures/urchin_larvae.gd).
// INSTANCE_CUSTOM: x a phase, y 0 an egg / 1 a pluteus. COLOR (a pluteus):
// g 0 its body, 0.5 its gut, 1 an arm (r along it).

varying float v_kind;
varying float v_larva;
varying float v_t;

void vertex() {
	v_larva = INSTANCE_CUSTOM.y;
	v_kind = v_larva > 0.5 ? COLOR.g : 0.0;
	v_t = COLOR.r;
	if (v_larva > 0.5 && COLOR.g > 0.9) { // (an arm: the ciliated band's beat, sweeping its food in: the arms flexing in and out)
		float side = COLOR.b * 2.0 - 1.0;
		float beat = sin(TIME * 5.0 + INSTANCE_CUSTOM.x * 6.2831) * 0.5 + 0.5;
		VERTEX.x -= side * v_t * v_t * 0.0009 * beat;
		VERTEX.z += v_t * v_t * 0.0005 * sin(TIME * 3.1 + INSTANCE_CUSTOM.x * 9.0);
	}
}

void fragment() {
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	if (v_larva < 0.5) { // an egg: cream orange, a clear jelly coat about it
		ALBEDO = vec3(0.95, 0.66, 0.36);
		ALPHA = 0.85;
		EMISSION = vec3(0.12, 0.06, 0.02);
	} else if (v_kind > 0.9) { // an arm: glassy, its skeletal rod bright
		ALBEDO = vec3(0.7, 0.75, 0.8);
		ALPHA = 0.25 + 0.5 * rim;
	} else if (v_kind > 0.4) { // its gut: green brown with what it's eaten
		ALBEDO = vec3(0.45, 0.42, 0.2);
		ALPHA = 0.9;
	} else { // its body: glassy, faintly orange
		ALBEDO = vec3(0.75, 0.68, 0.6);
		ALPHA = 0.12 + 0.5 * rim;
	}
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}
