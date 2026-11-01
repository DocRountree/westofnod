shader_type spatial;

// Bark: the texture's colour, its alpha the height, turned into bumps with
// screen-space derivatives (no tangents needed: Mikkelsen's surface
// gradient), and darker down in the furrows. Vertex colour tints it.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"

uniform sampler2D bark_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float bump = 0.012; // m of relief at full height
uniform float shadow_strength = 0.6;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// End grain on cut and broken ends (UV2.x = 1; UV across the end, -1..1):
// growth rings, weathered grey, the bark round the rim.
vec3 end_grain(vec2 p) {
	float r = length(p);
	float a = atan(p.y, p.x);
	float wob = 0.03 * sin(a * 3.0 + 1.7) + 0.02 * sin(a * 7.0);
	float ring = fract((r + wob) * 16.0);
	vec3 light = vec3(0.56, 0.47, 0.36), dark = vec3(0.4, 0.31, 0.22);
	vec3 c = mix(light, dark, smoothstep(0.55, 0.9, ring));
	c *= 0.8 + 0.2 * smoothstep(0.0, 0.25, r); // the heart, darker
	c = mix(c, vec3(0.23, 0.18, 0.14), smoothstep(0.88, 0.95, r)); // the bark round the rim
	float crack = smoothstep(0.035, 0.0, abs(fract(a / 6.2832 * 5.0 + 0.3 * r) - 0.5) * r * 2.0) * step(0.15, r);
	return pow(mix(c, c * 0.35, crack * 0.8), vec3(2.2)); // (to linear)
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, CAMERA_POSITION_WORLD, PROJECTION_MATRIX)) discard;
	if (UV2.x > 0.5) {
		ALBEDO = end_grain(UV) * COLOR.rgb;
		ROUGHNESS = 0.9;
		SPECULAR = 0.2;
	} else {
		vec4 t = texture(bark_tex, UV);
		float h = t.a * bump;
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
		float det = dot(dpdx, r1);
		vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
		NORMAL = normalize(abs(det) * NORMAL - grad);
		ALBEDO = t.rgb * COLOR.rgb;
		AO = mix(0.45, 1.0, t.a);
		AO_LIGHT_AFFECT = 0.25;
		ROUGHNESS = 0.92;
		SPECULAR = 0.25;
	}
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}

// Lit by hand so a shadow only dims it part way (shadow_strength): trees
// take their shadows from one stand-in (a dome on a stalk) that wraps their
// own crown, which would otherwise black out the whole tree. The ground
// under it still gets the full shadow.
void light() {
	float a = mix(1.0, ATTENUATION, shadow_strength);
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += (clamp(ndl * 0.8 + 0.2, 0.0, 1.0)) * a * LIGHT_COLOR / PI;
	vec3 h = normalize(VIEW + LIGHT);
	SPECULAR_LIGHT += pow(max(dot(NORMAL, h), 0.0), 8.0) * 0.04 * a * LIGHT_COLOR * clamp(ndl, 0.0, 1.0);
}
