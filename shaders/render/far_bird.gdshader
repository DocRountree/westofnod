shader_type spatial;
render_mode cull_disabled;
// A bird on the wing, far off (FarFauna): a spindle of a body and two
// wings, beating. COLOR.r: 0 the body, 1 a wing (g: how far out along it,
// b: its side, -1 / 1). INSTANCE_CUSTOM.x its own beat's phase.

uniform vec3 tone : source_color = vec3(0.35, 0.33, 0.3);
uniform float beat_hz = 4.0;

void vertex() {
	if (COLOR.r > 0.5) {
		float flap = sin(TIME * beat_hz * 6.2832 + INSTANCE_CUSTOM.x * 6.2832);
		float out_ = COLOR.g;
		VERTEX.y += flap * out_ * abs(VERTEX.x) * 0.9;
		VERTEX.x *= 1.0 - 0.25 * out_ * abs(flap);
	}
}

void fragment() {
	ALBEDO = tone * (0.75 + 0.25 * COLOR.a);
	ROUGHNESS = 0.8;
}
