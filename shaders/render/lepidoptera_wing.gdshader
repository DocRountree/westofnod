shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

// A butterfly's or a moth's wing (Lepidoptera): its outline is the mesh's
// (Lepidoptera._wing_mesh, from scripts/creatures/lepidoptera_wings.gd),
// its pattern painted on data/creatures/lepidoptera_wings.png by
// tools/creatures/bake_lepidoptera_wings.py: the upper side the front face,
// the underside the back, read from the cell `under` along (a monarch's
// underside is paler; a clearwing's the same both sides). Alpha: 1 scaled,
// ~0.1 a clearwing's glassy cells. Thin: lit from behind, the light comes
// through its scales.
//
// blur: the stroke of wings beating too fast to see (the hummingbird
// moth's, ~40 a second): a fan round the hinge, UV.x out from it, UV.y round
// the stroke; faint, a little more at its two ends.

uniform sampler2D wings : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 under = vec2(0.0);
uniform int pattern = 0; // 0 a monarch, 1 a clearwing (the blur's colour)
uniform bool blur = false;
uniform float opacity = 1.0;

void fragment() {
	if (blur) {
		float ends = pow(abs(UV.y * 2.0 - 1.0), 4.0);
		float a = mix(0.07, 0.2, ends) * smoothstep(1.0, 0.85, UV.x) * smoothstep(0.05, 0.2, UV.x);
		// (a clearwing's: mostly its brown border and olive base, smeared)
		ALBEDO = pattern == 1 ? mix(vec3(0.17, 0.06, 0.03), vec3(0.4, 0.38, 0.16), smoothstep(0.5, 0.15, UV.x)) : vec3(0.85, 0.42, 0.08);
		ALPHA = a * opacity;
	} else {
		vec4 t = texture(wings, UV + (FRONT_FACING ? vec2(0.0) : under));
		if (t.a < 0.03)
			discard;
		ALBEDO = t.rgb;
		float glass = 1.0 - smoothstep(0.15, 0.6, t.a);
		ROUGHNESS = mix(0.62, 0.12, glass); // (the clear cells glassy; the scales a soft sheen)
		SPECULAR = mix(0.3, 0.75, glass);
		BACKLIGHT = t.rgb * 0.45 * (1.0 - glass);
		ALPHA = t.a * opacity;
	}
}
