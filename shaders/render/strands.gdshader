shader_type spatial;
render_mode cull_disabled;
// Strands (Strands: a porcupine's quills and guard hairs, an armadillo's
// bristles): each coloured root to tip by its vertex colour (as seen, sRGB);
// keratin, a sheen along it; a little light through its thin tip.

varying float t_;

void vertex() {
	t_ = UV.x;
}

void fragment() {
	vec3 c = COLOR.rgb;
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	ROUGHNESS = mix(0.5, 0.65, t_);
	SPECULAR = 0.35;
	BACKLIGHT = ALBEDO * 0.35 * t_;
	RIM = 0.1;
	RIM_TINT = 0.6;
}
