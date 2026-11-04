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
uniform vec3 far_color = vec3(-1.0); // the bark's colour far off, if set (the sycamore's white: its patchwork's mean is grey); else its texture's mean

varying vec3 world_pos;
varying vec3 obj; // the tree's own space, offset per tree across (the lichen's and moss's patterns)
varying vec2 growth; // how much lichen and moss grow here (growth_at)
varying float near;   // 1 the tree's up close (lichen, moss patterns), 0 not
varying vec2 lichen_uv;
varying vec2 bark_off; // where each tree reads the bark texture from
// An axe's notch (Felling; Population.set_notch): INSTANCE_CUSTOM = (its
// direction round the trunk, rad; its depth; its height; the trunk's radius
// there), in the tree's own units; depth 0 none (and none at all but on a
// tree being felled). A V cut into the trunk from the side the axe comes
// from, as wide at the bark as it is deep: there the bark gives way to
// fresh-cut wood, shaded as the cut's two faces.
varying flat vec4 notch;
#ifdef BARK_CUT
// (A felled tree isn't drawn by this: its meshes are cut at the cut and
// closed there, MeshCut, Felling; nothing below it is left to hide.)
// The cut variant (OakTree.cut_meshes: trees being felled, and felled;
// both faces drawn): the bark cut away (the notch's wedge, the trunk below
// the cut) isn't drawn, and the inside seen through the gap is drawn as the
// cut wood it would be: the line of sight met with the notch's two faces,
// or the cut across the foot, there shaded as fresh end grain, so the
// notch is a real hollow in the trunk.
varying flat vec3 cam_obj; // the camera in the tree's own space
varying flat vec4 mm0;     // the tree's own model matrix (in the fragment
varying flat vec4 mm1;     // shader MODEL_MATRIX is a MultiMesh node's)
varying flat vec4 mm2;
varying flat vec4 mm3;
#endif
uniform bool fresh_end = false; // cut ends fresh-sawn (an axed tree's stump: OakTree.fresh_stump), not weathered
varying vec3 notch_p; // the tree's own space, unoffset
varying flat vec3 notch_up_n; // world: the upper face's normal (out of the wood)
varying flat vec3 notch_lo_n; // world: the lower face's

void vertex() {
	lod_f = lod_vertex(CAMERA_POSITION_WORLD, MODEL_MATRIX, PROJECTION_MATRIX);
	if (lod_gone(lod_f)) {
		VERTEX = vec3(0.0); // (not this level here: no pixels)
	}
	vec3 tree = MODEL_MATRIX[3].xyz + world_origin; // (on the map: the patterns go by it)
	obj = VERTEX + vec3(fract(tree.x * 0.0137), 0.0, fract(tree.z * 0.0137)) * 61.0;
	growth = growth_at(tree.xz);
	if (moss_any_biome)
		growth.y = max(growth.y, 1.0);
	// (whole trees, by their distance: a big one's nearest bark may be a
	// dozen metres nearer than its foot)
	near = distance(MODEL_MATRIX[3].xyz, CAMERA_POSITION_WORLD) < LICHEN_NEAR + 15.0 ? 1.0 : 0.0;
	// (lichen.png: 0.6 m round, as the bark's texture, and 2.4 m along;
	// each tree reads it from its own place, and every other one mirrored.
	// Any shift keeps the seam round the trunk seamless: a trunk is a whole
	// number of repeats round.)
	vec2 o = fract(tree.xz * vec2(0.0137, 0.0191) + tree.zx * vec2(0.0071, 0.0113));
	lichen_uv = vec2(o.x < 0.5 ? UV.x : -UV.x, UV.y * 0.25) + o * vec2(1.0, 7.0);
	bark_off = fract(tree.xz * vec2(0.0419, 0.0283) + tree.zx * vec2(0.0157, 0.0233)) * vec2(1.0, 5.0);
	notch = INSTANCE_CUSTOM;
	notch_p = VERTEX;
#ifdef BARK_CUT
	cam_obj = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	mm0 = MODEL_MATRIX[0];
	mm1 = MODEL_MATRIX[1];
	mm2 = MODEL_MATRIX[2];
	mm3 = MODEL_MATRIX[3];
#endif
	if (notch.y > 0.0) {
		vec2 d = vec2(cos(notch.x), sin(notch.x));
		float k = 0.5; // half the opening / the depth
		notch_up_n = normalize(mat3(MODEL_MATRIX) * vec3(d.x * k, -1.0, d.y * k));
		notch_lo_n = normalize(mat3(MODEL_MATRIX) * vec3(d.x * k, 1.0, d.y * k));
	}
	VERTEX += wind_local(MODEL_MATRIX, VERTEX, UV2.y, TIME);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// The bark, not to be seen repeating: two readings of the texture (the
// second mirrored round and stretched along), each patch of bark (a metre
// or so: a noise in the tree's own space) showing the one or the other,
// the higher one winning at the borders (one ridge running over the other,
// not a smear of both); and a little lighter and darker here and there.
vec4 bark_at(vec2 uv, vec3 p) {
	vec4 a = texture(bark_tex, uv + bark_off);
	vec4 b = texture(bark_tex, vec2(-uv.x, uv.y * 0.71) + bark_off.yx + vec2(0.37, 2.9));
	float n = lc_noise(p * vec3(1.3, 0.55, 1.3));
	float k = clamp((b.a - a.a) * 3.0 + (n - 0.5) * 9.0 + 0.5, 0.0, 1.0);
	vec4 t = mix(a, b, k);
	t.rgb *= 0.86 + 0.28 * lc_noise(p * vec3(0.7, 0.25, 0.7) + 17.0);
	return t;
}

// End grain on cut and broken ends (UV2.x = 1; UV across the end, -1..1):
// growth rings, weathered grey, the bark round the rim.
vec3 end_grain(vec2 p, bool fresh) {
	float r = length(p);
	float a = atan(p.y, p.x);
	float wob = 0.03 * sin(a * 3.0 + 1.7) + 0.02 * sin(a * 7.0);
	float ring = fract((r + wob) * 16.0);
	vec3 light = vec3(0.56, 0.47, 0.36), dark = vec3(0.4, 0.31, 0.22);
	if (fresh) { // (pale, warm, no checks yet)
		light = vec3(0.8, 0.66, 0.46);
		dark = vec3(0.68, 0.53, 0.34);
	}
	vec3 c = mix(light, dark, smoothstep(0.55, 0.9, ring));
	c *= 0.8 + 0.2 * smoothstep(0.0, 0.25, r); // the heart, darker
	c = mix(c, vec3(0.23, 0.18, 0.14), smoothstep(0.88, 0.95, r)); // the bark round the rim
	float crack = fresh ? 0.0 : smoothstep(0.035, 0.0, abs(fract(a / 6.2832 * 5.0 + 0.3 * r) - 0.5) * r * 2.0) * step(0.15, r);
	return pow(mix(c, c * 0.35, crack * 0.8), vec3(2.2)); // (to linear)
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, lod_f)) discard;
	bool cut_face = false; // (the cut wood drawn: none of the bark's)
#ifdef BARK_CUT
	bool in_notch = false;
	if (notch.y > 0.0) {
		vec2 d = vec2(cos(notch.x), sin(notch.x));
		float q = notch.w - dot(notch_p.xz, d);
		in_notch = q < notch.y && abs(notch_p.y - notch.z) < 0.5 * (notch.y - q);
	}
	// the bark in the notch's mouth is cut away: there (and on the inside,
	// seen through the gap) the line of sight goes on to where it meets the
	// cut wood
	if (!FRONT_FACING || in_notch) {
		vec3 o = cam_obj;
		vec3 dir = normalize(notch_p - cam_obj);
		float best = 1e9;
		vec3 hit = vec3(0.0);
		vec3 hn = vec3(0.0, 1.0, 0.0); // (out of the wood, the tree's own)
		float rr = 1.0;
		float dark = 0.0;
		// (only for the trunk's own bark round the notch or the cut: a
		// branch's inside, behind, met the planes too, and drew them over it)
		if (notch.y > 0.0 && abs(notch_p.y - notch.z) < notch.y * 2.0 + 0.3 && length(notch_p.xz) < notch.w * 1.6) {
			vec2 d = vec2(cos(notch.x), sin(notch.x));
			float D = notch.y, R = notch.w, hc = notch.z;
			for (int f = 0; f < 2; f++) {
				float sg = f == 0 ? 1.0 : -1.0; // the upper face, the lower
				// face: y - sg * 0.5 * (d . xz) = hc + sg * 0.5 * (D - R)
				vec3 n = vec3(-sg * 0.5 * d.x, 1.0, -sg * 0.5 * d.y);
				float c = hc + sg * 0.5 * (D - R);
				float den = dot(n, dir);
				if (abs(den) < 1e-5)
					continue;
				float t = (c - dot(n, o)) / den;
				vec3 p = o + dir * t;
				float q = R - dot(p.xz, d);
				vec3 out_n = normalize(vec3(0.5 * d.x, -sg, 0.5 * d.y)); // (out of the wood, into the cut)
				// (only met going into the wood: a face seen from its open side)
				if (t > 0.0 && t < best && dot(dir, out_n) < 0.0 && q >= 0.0 && q <= D && length(p.xz) <= R * 1.35) { // (out to the roots' lobes)
					best = t;
					hit = p;
					hn = out_n;
					rr = R;
					dark = q / D;
				}
			}
		}
		if (best > 1e8)
			discard; // (cut away, and nothing cut behind it: through the notch)
		mat4 M = mat4(mm0, mm1, mm2, mm3);
		vec4 w = M * vec4(hit, 1.0);
		// (its depth left the surface's own: written at the cut, nearer, it
		// drew over the trunk's bark in front of it, past its outline)
		vec3 wood = end_grain(hit.xz / rr, true) * (0.9 + 0.2 * lc_noise(hit * vec3(40.0, 4.0, 40.0)));
		ALBEDO = wood * mix(1.0, 0.75, dark * dark); // (a little darker deep in the cut)
		NORMAL = normalize((VIEW_MATRIX * vec4(normalize(mat3(M) * hn), 0.0)).xyz);
		AO = 1.0;
		ROUGHNESS = 0.8;
		SPECULAR = 0.3;
		FOG = aerial_fog(w.xyz, CAMERA_POSITION_WORLD);
		cut_face = true;
	}
#endif
	if (!cut_face) {
	vec3 geo_n = NORMAL; // (before the bark's bumps: lichen and moss cover them)
	if (UV2.x > 0.5) {
		ALBEDO = end_grain(UV, fresh_end) * COLOR.rgb;
		AO = 1.0;
		ROUGHNESS = 0.9;
		SPECULAR = 0.2;
		if (fresh_end) {
			// an axe's top: chopped flat across in strokes, a band a stroke,
			// each its own tilt (facets lying across the top, not standing
			// up off it); shaded from the facets' slopes. The strokes follow
			// one another along the stump's own x, which Felling turns to
			// the way the axe came from (the notch's side)
			float band = notch_p.x * 7.0 + 0.35 * sin(notch_p.z * 4.6 + 1.1);
			ivec2 bi = ivec2(int(floor(band)), 17);
			vec2 s0 = (vec2(lc_hash(vec3(vec2(bi), 3.0)), lc_hash(vec3(vec2(bi), 7.0))) - 0.5) * vec2(0.35, 0.55);
			vec2 s1 = (vec2(lc_hash(vec3(vec2(bi + ivec2(1, 0)), 3.0)), lc_hash(vec3(vec2(bi + ivec2(1, 0)), 7.0))) - 0.5) * vec2(0.35, 0.55);
			vec2 slope = mix(s0, s1, smoothstep(0.8, 1.0, fract(band))); // (a stroke rounds over into the next)
			float fh = dot(UV, slope) * 0.45; // (m)
			vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
			vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
			float det = dot(dpdx, r1);
			NORMAL = normalize(abs(det) * NORMAL - sign(det) * (dFdx(fh) * r1 + dFdy(fh) * r2));
			ALBEDO *= 0.94 + 0.12 * mix(lc_hash(vec3(vec2(bi), 11.0)), lc_hash(vec3(vec2(bi + ivec2(1, 0)), 11.0)), smoothstep(0.8, 1.0, fract(band))); // (each stroke a shade apart)
		}
	} else if (smoothstep(detail_far.x, detail_far.y, distance(world_pos, CAMERA_POSITION_WORLD)) > bayer4(FRAGCOORD.xy + 1.0)) {
		// far: the bark's average colour (the texture's smallest mip), flat
		ALBEDO = (far_color.r >= 0.0 ? far_color : textureLod(bark_tex, vec2(0.5), 12.0).rgb) * COLOR.rgb;
		AO = 0.75;
		AO_LIGHT_AFFECT = 0.25;
		ROUGHNESS = 0.92;
		SPECULAR = 0.25;
	} else {
		vec4 t = bark_at(UV, obj);
		// a far colour of its own (the sycamore's white): the texture, its
		// pits and its bumps going over to it with distance, flat at it by
		// the time it dithers into the far colour (or the texture's darker
		// patches and shaded pits dithered in grey over the white)
		float flat_k = far_color.r >= 0.0 ? smoothstep(20.0, detail_far.x, distance(world_pos, CAMERA_POSITION_WORLD)) : 0.0;
		float h = t.a * bump * (1.0 - flat_k);
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL), r2 = cross(NORMAL, dpdx);
		float det = dot(dpdx, r1);
		vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
		NORMAL = normalize(abs(det) * NORMAL - grad);
		ALBEDO = (flat_k > 0.0 ? mix(t.rgb, far_color, flat_k) : t.rgb) * COLOR.rgb;
		AO = mix(mix(0.45, 1.0, t.a), 0.75, flat_k);
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
	float lichen = UV2.x > 0.5 || (lichen_any_biome ? (growth.x > 1.5 ? lichen_swamp : 1.0) : growth.x) * lichen_amount <= 0.0 || fade <= 0.0 ? 0.0 : lichen_cover(lichen_uv, obj, lichen_amount * (lichen_any_biome ? (growth.x > 1.5 ? lichen_swamp : 1.0) : growth.x), fade, lc, lh);
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
	vec3 mc;
	float mh;
	float moss = 0.0;
	if (growth.y > 0.0 && moss_amount > 0.0) {
		// (round the bark: twice to a repeat of its texture, so it wraps
		// seamlessly; on a cut end, across it)
		vec2 muv = UV2.x > 0.5 ? obj.xz / 0.3 : UV * 2.0 + bark_off;
		vec4 M = near > 0.0 ? texture(moss_tex, muv) : vec4(0.0);
		// (by the surface's own lie, not its furrows' bumps: the sporophytes,
		// standing only on thick moss, go by the same)
		float geo_up = (INV_VIEW_MATRIX * vec4(geo_n, 0.0)).y;
		moss = moss_cover(obj, geo_up, near, M, mc, mh) * (UV2.x > 0.5 ? moss_end : 1.0);
	}
	if (moss > 0.0) {
		// a cushion over the bark: its shoots domed (bumps from their
		// height), shadowed down between them
		vec3 n = normalize(mix(NORMAL, geo_n, moss * 0.85));
		vec3 dpdx = dFdx(VERTEX), dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, n), r2 = cross(n, dpdx);
		float det = dot(dpdx, r1);
		NORMAL = normalize(abs(det) * n - sign(det) * (dFdx(mh) * r1 + dFdy(mh) * r2));
		ALBEDO = mix(ALBEDO, mc, moss);
		AO = mix(AO, mix(0.5, 1.0, mh / 0.006), moss);
		ROUGHNESS = mix(ROUGHNESS, 1.0, moss);
		SPECULAR = mix(SPECULAR, 0.08, moss);
	}
	if (notch.y > 0.0 && UV2.x < 0.5) {
		// how far in from the plane the cut starts at (the trunk's front),
		// and how far above or below the cut's middle line
		vec2 d = vec2(cos(notch.x), sin(notch.x));
		float q = notch.w - dot(notch_p.xz, d);
		float dy = notch_p.y - notch.z;
		float open = notch.y * 0.5 * (1.0 - q / notch.y); // the V's half-height at that depth
		if (q < notch.y && abs(dy) < open) {
			float deep = clamp(q / notch.y, 0.0, 1.0);
			// the wood cut across: its growth rings round the trunk's axis,
			// fresh
			// (the bark's point stands for the face behind it: as deep in
			// as the V's face is at that height, so the rings are the
			// face's, round the axis, not the bark's rim)
			float face_q = notch.y * (1.0 - abs(dy) / (notch.y * 0.5));
			vec2 on_face = notch_p.xz - d * max(face_q - q, 0.0);
			vec3 wood = end_grain(on_face / notch.w, true) * (0.9 + 0.2 * lc_noise(notch_p * vec3(40.0, 4.0, 40.0)));
			wood *= mix(1.0, 0.75, deep * deep);                          // darker toward the bottom of the V
			wood *= mix(0.45, 1.0, smoothstep(0.0, 0.02, open - abs(dy))); // and at its edges, the bark's
			ALBEDO = wood;
			NORMAL = normalize((VIEW_MATRIX * vec4(dy > 0.0 ? notch_up_n : notch_lo_n, 0.0)).xyz);
			ROUGHNESS = 0.8;
			SPECULAR = 0.3;
		}
	}
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
	}
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
