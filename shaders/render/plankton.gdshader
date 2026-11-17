shader_type spatial;
render_mode cull_disabled, depth_draw_always;
// Young in the plankton (scripts/creatures/plankton.gd). INSTANCE_CUSTOM: x
// a phase, y 1 an octopus's paralarva (its mantle pulsing). COLOR.g: 0 the
// body, glassy; 0.5 its gut, its eyes; 0.75 a chromatophore; 1 an arm or
// a lobe's ciliated band (beating); 0.25 a veliger's shell.

varying float v_kind;

void vertex() {
	v_kind = COLOR.g;
	float ph = INSTANCE_CUSTOM.x * 6.2831853;
	if (INSTANCE_CUSTOM.y > 0.5 && COLOR.g < 0.9) { // (its mantle: a pulse, its jet)
		float pulse = 1.0 - 0.12 * max(sin(TIME * 8.0 + ph), 0.0);
		VERTEX.xz *= pulse;
	} else if (COLOR.g > 0.9) { // (its arms, its band: beating)
		VERTEX += NORMAL * 0.00025 * sin(TIME * 6.0 + ph + VERTEX.y * 3000.0);
	}
}

void fragment() {
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	if (v_kind > 0.9) {
		ALBEDO = vec3(0.75, 0.78, 0.8);
		ALPHA = 0.3 + 0.5 * rim;
	} else if (v_kind > 0.6) {
		ALBEDO = vec3(0.7, 0.35, 0.12);
		ALPHA = 0.95;
	} else if (v_kind > 0.4) {
		ALBEDO = vec3(0.25, 0.2, 0.12);
		ALPHA = 0.9;
	} else if (v_kind > 0.15) { // a veliger's shell: thin, amber, clear
		ALBEDO = vec3(0.82, 0.72, 0.52);
		ALPHA = 0.45 + 0.4 * rim;
	} else {
		ALBEDO = vec3(0.78, 0.74, 0.7);
		ALPHA = 0.1 + 0.5 * rim;
	}
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}
