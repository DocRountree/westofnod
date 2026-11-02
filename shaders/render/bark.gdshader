shader_type spatial;

// Bark: the texture's colour, its alpha the height, turned into bumps with
// screen-space derivatives (no tangents needed: Mikkelsen's surface
// gradient), and darker down in the furrows. Vertex colour tints it.
// Far off (detail_far) the texture and the bumps are dropped for the
// bark's average colour, dissolving (stippled) between the two. The thin
// outer wood sways in the wind with its leaves (wind.gdshaderinc).
// Over it lichen and, on stumps and logs, moss (lichen.gdshaderinc).

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"
#include "res://shaders/render/wind.gdshaderinc"
#include "res://shaders/render/lichen.gdshaderinc"

uniform sampler2D bark_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float bump = 0.012; // m of relief at full height
uniform float shadow_strength = 0.6;
uniform vec2 detail_far = vec2(60.0, 90.0); // m: the texture fades out between these

varying vec3 world_pos;
varying vec3 obj; // the tree's own space, offset per tree across (the lichen's and moss's patterns)
varying vec2 growth; // how much lichen and moss grow here (growth_at)
varying float near;   // 1 the tree's up close (lichen, moss patterns), 0 not
varying vec2 lichen_uv;

void vertex() {
	lod_f = lod_vertex(CAMERA_POSITION_WORLD, MODEL_MATRIX, PROJECTION_MATRIX);
	if (lod_gone(lod_f)) {
		VERTEX = vec3(0.0); // (not this level here: no pixels)
	}
	obj = VERTEX + vec3(fract(MODEL_MATRIX[3].x * 0.0137), 0.0, fract(MODEL_MATRIX[3].z * 0.0137)) * 61.0;
	growth = growth_at(MODEL_MATRIX[3].xz);
	// (whole trees, by their distance: a big one's nearest bark may be a
	// dozen metres nearer than its foot)
	near = distance(MODEL_MATRIX[3].xyz, CAMERA_POSITION_WORLD) < LICHEN_NEAR + 15.0 ? 1.0 : 0.0;
	// (lichen.png: 0.6 m round, as the bark's texture, and 2.4 m along;
	// each tree reads it from its own place, and every other one mirrored.
	// Any shift keeps the seam round the trunk seamless: a trunk is a whole
	// number of repeats round.)
	vec2 o = fract(MODEL_MATRIX[3].xz * vec2(0.0137, 0.0191) + MODEL_MATRIX[3].zx * vec2(0.0071, 0.0113));
	lichen_uv = vec2(o.x < 0.5 ? UV.x : -UV.x, UV.y * 0.25) + o * vec2(1.0, 7.0);
	VERTEX += wind_local(MODEL_MATRIX, VERTEX, UV2.y, TIME);
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
	if (lod_hidden(FRAGCOORD.xy, lod_f)) discard;
	vec3 geo_n = NORMAL; // (before the bark's bumps: lichen and moss cover them)
	if (UV2.x > 0.5) {
		ALBEDO = end_grain(UV) * COLOR.rgb;
		AO = 1.0;
		ROUGHNESS = 0.9;
		SPECULAR = 0.2;
	} else if (smoothstep(detail_far.x, detail_far.y, distance(world_pos, CAMERA_POSITION_WORLD)) > bayer4(FRAGCOORD.xy + 1.0)) {
		// far: the bark's average colour (the texture's smallest mip), flat
		ALBEDO = textureLod(bark_tex, vec2(0.5), 12.0).rgb * COLOR.rgb;
		AO = 0.75;
		AO_LIGHT_AFFECT = 0.25;
		ROUGHNESS = 0.92;
		SPECULAR = 0.25;
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
	// lichen, then moss over it (not on the end grain's face, save moss on
	// a stump's top)
	float d = distance(world_pos, CAMERA_POSITION_WORLD);
	float fade = near * (1.0 - smoothstep(LICHEN_NEAR * 0.5, LICHEN_NEAR, d));
	float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
	vec3 lc;
	float lh;
	float lichen = UV2.x > 0.5 || growth.x * lichen_amount <= 0.0 || fade <= 0.0 ? 0.0 : lichen_cover(lichen_uv, obj, lichen_amount * growth.x, fade, lc, lh);
	if (lichen > 0.0) {
		// it lies over the bark's furrows, its lobes domed (bumps from
		// their height, as the bark's)
		vec3 n = normalize(mix(NORMAL, geo_n, lichen * 0.85));
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, n), r2 = cross(n, dpdx);
		float det = dot(dpdx, r1);
		NORMAL = normalize(abs(det) * n - sign(det) * (dFdx(lh) * r1 + dFdy(lh) * r2));
		ALBEDO = mix(ALBEDO, lc, lichen);
		AO = mix(AO, 1.0, lichen * 0.7);
		ROUGHNESS = mix(ROUGHNESS, 1.0, lichen);
		SPECULAR = mix(SPECULAR, 0.05, lichen);
	}
	float ml;
	float moss = 0.0;
	if (growth.y > 0.0 && moss_amount > 0.0) {
		float fuzz = near > 0.0 ? texture(bark_tex, (UV2.x > 0.5 ? obj.xz * 1.7 : UV) * 2.3).a : 0.5; // (the bark's relief, finer)
		moss = moss_cover(obj, up, near, fuzz, ml) * (UV2.x > 0.5 ? moss_end : 1.0);
	}
	if (moss > 0.0) {
		ALBEDO = mix(ALBEDO, mix(moss_color, moss_light, ml), moss);
		NORMAL = normalize(mix(NORMAL, geo_n, moss * 0.7));
		AO = mix(AO, mix(0.7, 1.0, ml), moss);
		ROUGHNESS = mix(ROUGHNESS, 1.0, moss);
		SPECULAR = mix(SPECULAR, 0.1, moss);
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
	// (a dull sheen, none on the matte lichen and moss: ROUGHNESS 1)
	SPECULAR_LIGHT += pow(max(dot(NORMAL, h), 0.0), 8.0) * 0.04 * a * LIGHT_COLOR * clamp(ndl, 0.0, 1.0) * smoothstep(1.0, 0.9, ROUGHNESS);
}
