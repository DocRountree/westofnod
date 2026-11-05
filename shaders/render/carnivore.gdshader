shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

// The coats of the four-legged mammals on Carnivore's make (RedFox, Bobcat,
// Coyote, GreyWolf, BlackBear, BrownBear, Bison, Deer): painted, not
// shelled. Broad soft colour, countershaded (darker above, paler below), its
// species' marks laid over it in gentle gradients; a fine grain of fur
// running the way its hair lies, and a softer mottling; wrapped diffuse and
// a velvet rim for its fur's softness; the bison's front wool curled.
//
// Its skin (MammalSkin: skin on) carries in each vertex where it is: its
// part (0 the body, neck and head; 2 a foreleg; 3 a hind leg; 6 the tail),
// how far along it (the body: 0 the rump .. 1 the nose; a leg: 0 its
// shoulder or haunch .. 1 its toes; the tail: 0 its root .. 1 its tip), its
// share of the face, where it was at rest (the body's mm) and in the head's
// own space, its normal at rest. Its other parts (skin off: ears, paws,
// horns, claws, the hump and beard, a lid) say it by uniforms: part (1 the
// face, 4 a paw or hoof, 5 an ear (up its y: ear_len; its back +z), 7 a horn,
// antler, claw or tuft), along; and where by their own object space.
//
// species 0 a red fox, 1 a bobcat, 2 a coyote, 3 a grey wolf, 4 a black bear
// (phase: 0 black, 1 cinnamon, 2 brown, 3 blond; blaze), 5 a brown bear
// (phase: 0 brown, 1 grizzled, 2 blond), 6 an American bison (front_z: its
// shaggy front's hind edge), 7 a white-tailed deer (phase: 0 summer, 1
// winter; muzzle_z: the white band behind its nose; bare_a, bare_b, bare_r:
// its eyes, ringed white).

uniform int species = 0;
uniform int part = 0;
uniform bool skin = false;
uniform bool young = false;
uniform float along = 0.0;
uniform float ear_len = 80.0;
uniform int phase = 0;
uniform float muzzle_z = -120.0;
uniform bool blaze = false;
uniform float fur_front = 0.0;
uniform float front_z = -400.0;
uniform vec3 bare_a = vec3(0.0, -1e6, 0.0);
uniform vec3 bare_b = vec3(0.0, -1e6, 0.0);
uniform float bare_r = 0.0;
uniform float to_cream = 0.0; // (a part gone to cream: a hare's eye ring)
uniform float fur = 1.0; // (a mouse pup's: 0 bare pink skin .. 1 furred)
uniform vec3 mouse_back : source_color = vec3(0.46, 0.33, 0.21); // (a deer mouse's)
uniform float line_y = -0.28; // (its belly's edge: the normal's y there)
uniform bool male = false; // (a grown male: where the sexes differ, a moose's)
uniform bool sculpt = false; // (its head sculpted: SculptHead; its nose leather painted here)
uniform vec3 nose_c = vec3(0.0, 0.0, -1e5);
uniform float nose_r = 1.0;
uniform vec3 nose_col = vec3(0.045, 0.038, 0.036); // (its nose leather: black, or a cat's pink)
uniform float almond = 0.72; // (its eye's opening: height to length)
uniform float slant = 0.0; // (its outer corner raised)
uniform float hair = 20.0; // (its coat's length, mm: the grain's size)


varying vec4 c0;
varying vec3 rp;
varying vec3 rn;
varying vec3 hp;

void vertex() {
	if (skin) {
		c0 = CUSTOM0;
		rp = CUSTOM1.xyz;
		rn = CUSTOM2.xyz;
		hp = CUSTOM3.xyz;
	} else {
		c0 = vec4(float(part), along, part == 1 ? 1.0 : 0.0, 0.0);
		rp = VERTEX;
		rn = NORMAL;
		hp = VERTEX;
	}
}

float h31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// (spots: 1 where a cell's own point is near, each its own size)
float spots(vec3 p, float cell, float r) {
	vec3 c = floor(p / cell);
	float best = 9.0;
	for (int x = -1; x <= 1; x++)
		for (int y = -1; y <= 1; y++)
			for (int z = -1; z <= 1; z++) {
				vec3 q = c + vec3(float(x), float(y), float(z));
				vec3 at = (q + vec3(h31(q), h31(q + 7.1), h31(q + 3.3))) * cell;
				best = min(best, length(p - at) / (cell * (0.6 + 0.6 * h31(q + 1.9))));
			}
	return 1.0 - smoothstep(r * 0.7, r, best);
}

vec3 countershade(vec3 back, vec3 side, vec3 belly, float ny, float belly_from) {
	vec3 c = mix(side, back, smoothstep(0.25, 0.95, ny));
	return mix(c, belly, 1.0 - smoothstep(belly_from - 0.25, belly_from + 0.1, ny));
}

void fragment() {
	float pt = floor(c0.x + 0.5);
	float a = c0.y; // (along its part)
	float fw = c0.z; // (its share of the face)
	float ny = normalize(rn).y;
	bool leg = pt == 2.0 || pt == 3.0;
	bool hind = pt == 3.0;
	vec3 white = vec3(0.9, 0.88, 0.83);
	vec3 c;
	// (the face: how far forward on the muzzle; under the chin)
	float snout = fw * smoothstep(-0.2, -0.75, hp.z / max(abs(muzzle_z) * 2.6, 1.0));
	float chin = fw * (1.0 - smoothstep(-0.45, 0.0, ny));
	if (species == 0) {
		// a red fox: rufous orange, the back a little deeper; white chin,
		// cheeks, throat, chest and belly; black stockings; its brush rufous,
		// darker through it, its tip white; ears black backed. A kit's dark
		// grey brown, a paler muzzle.
		vec3 red = young ? vec3(0.34, 0.29, 0.25) : vec3(0.78, 0.38, 0.14);
		vec3 deep = young ? vec3(0.27, 0.23, 0.2) : vec3(0.62, 0.27, 0.1);
		c = countershade(deep, red, young ? vec3(0.5, 0.45, 0.4) : white, ny, -0.25);
		c = mix(c, white, chin * (young ? 0.4 : 1.0));
		c = mix(c, white, fw * smoothstep(0.1, -0.35, ny) * 0.9);
		if (leg) {
			c = mix(red * 0.95, vec3(0.07, 0.05, 0.045), smoothstep(hind ? 0.5 : 0.38, hind ? 0.68 : 0.55, a));
			c = mix(c, white, (1.0 - smoothstep(-0.5, 0.0, ny)) * (1.0 - smoothstep(0.1, 0.3, a)) * 0.6);
		}
		if (pt == 6.0) {
			c = mix(red * 0.92, vec3(0.3, 0.15, 0.08), 0.35 * smoothstep(0.3, 0.7, a));
			c = mix(c, white, smoothstep(0.84, 0.92, a));
		}
		if (pt == 5.0)
			c = rn.z < 0.0 ? /*(its back: away from its cup)*/ vec3(0.07, 0.05, 0.045) : mix(mix(vec3(0.88, 0.84, 0.76), red, smoothstep(0.35, 0.95, abs(rp.x) / max(ear_len * 0.3, 1.0))), vec3(0.08, 0.06, 0.05), smoothstep(ear_len * 0.75, ear_len, rp.y));
		if (sculpt && fw > 0.5 && !young) {
			float side = smoothstep(0.2, 0.55, abs(normalize(rn).x));
			// (its upper lips and cheeks white, below a line from its nose back to under its eye)
			float liny = mix(nose_c.y - nose_r * 0.9, bare_b.y - bare_r * 1.6, clamp((hp.z - nose_c.z) / max(bare_b.z - nose_c.z, 1.0), 0.0, 1.6));
			c = mix(c, white, (1.0 - smoothstep(liny - 2.5, liny + 2.5, hp.y)) * side);
			// (its tear line: dark, from the eye's front corner down the muzzle's side)
			vec2 e0 = vec2(bare_b.z - bare_r * 0.9, bare_b.y - bare_r * 0.25);
			vec2 e1 = vec2(nose_c.z + nose_r * 2.6, nose_c.y - nose_r * 0.4);
			vec2 pz = vec2(hp.z, hp.y);
			float tt = clamp(dot(pz - e0, e1 - e0) / dot(e1 - e0, e1 - e0), 0.0, 1.0);
			float dl = length(pz - (e0 + (e1 - e0) * tt));
			c = mix(c, vec3(0.18, 0.08, 0.035), (1.0 - smoothstep(1.2, 3.2, dl)) * side * 0.75 * (1.0 - tt * 0.5));
			// (the black patch round its whiskers' roots)
			float wp = length((vec2(hp.z, hp.y) - vec2(nose_c.z + nose_r * 2.2, nose_c.y - nose_r * 0.9)) / vec2(1.6, 1.0));
			c = mix(c, vec3(0.07, 0.05, 0.045), (1.0 - smoothstep(nose_r * 0.55, nose_r * 0.95, wp)) * side * 0.8);
		}
	} else if (species == 1) {
		// a bobcat: tawny buff to grey brown, spotted dark down its sides and
		// legs, barred on its legs; white beneath, spotted black; white
		// round its muzzle, black bars on its cheeks; ears black backed with
		// a white spot, tufted; its bobbed tail barred, its tip black above.
		vec3 buff = young ? vec3(0.52, 0.46, 0.4) : vec3(0.62, 0.47, 0.31);
		vec3 grey = young ? vec3(0.44, 0.4, 0.36) : vec3(0.44, 0.38, 0.3);
		vec3 dark = vec3(0.13, 0.1, 0.08);
		c = countershade(grey, buff, mix(white, buff, sculpt ? fw : 0.0), ny, -0.3);
		float sp = spots(rp * vec3(1.0, 1.0, 0.75), young ? 22.0 : 24.0, 0.36);
		c = mix(c, dark, sp * (1.0 - smoothstep(0.75, 0.98, ny)) * (1.0 - fw) * (young ? 0.85 : 0.7));
		c = mix(c, mix(white, dark, spots(rp, 40.0, 0.3) * 0.8), (1.0 - smoothstep(-0.55, -0.2, ny)) * (1.0 - fw));
		if (!sculpt) {
			c = mix(c, white, chin);
			c = mix(c, white, snout * 0.8);
		}
		float bars = fw * smoothstep(0.6, 0.9, sin(hp.y * 0.35 + hp.z * 0.12)) * (1.0 - snout) * smoothstep(-0.6, 0.2, ny) * (1.0 - smoothstep(0.5, 0.9, ny));
		if (!sculpt)
			c = mix(c, dark, bars * 0.3 * smoothstep(25.0, 45.0, abs(hp.x)));
		if (sculpt && fw > 0.5 && !young) {
			vec3 hq = vec3(abs(hp.x), hp.y, hp.z);
			// (its forehead: fine dark lines back over its crown)
			float fs = smoothstep(0.75, 0.95, sin(hq.x * 0.42 + 0.6)) * smoothstep(0.45, 0.85, ny) * smoothstep(bare_b.z - bare_r * 0.5, bare_b.z + bare_r * 1.5, hp.z);
			c = mix(c, dark, fs * 0.55);
			// (white round its eyes)
			float ed = length((hq - bare_b) / vec3(1.0, 0.75, 1.0));
			c = mix(c, white, (1.0 - smoothstep(bare_r * 1.0, bare_r * 1.45, ed)) * 0.55);
			// (its muzzle, lips, chin and the ruff under its cheeks white, below a line from its nose back under its eye)
			float liny = mix(nose_c.y - nose_r * 0.5, bare_b.y - bare_r * 1.3, clamp((hp.z - nose_c.z) / max(bare_b.z - nose_c.z, 1.0), 0.0, 1.8));
			float low = 1.0 - smoothstep(liny - 3.0, liny + 3.0, hp.y);
			c = mix(c, white, low * 0.9);
			c = mix(c, white, (1.0 - smoothstep(-0.7, -0.35, ny)));
			// (the black bars, two, sweeping back and down across its ruff from its eye's back corner)
			for (int k = 0; k < 2; k++) {
				vec2 b0 = vec2(bare_b.z + bare_r * (1.1 + 0.2 * float(k)), bare_b.y - bare_r * (0.2 + 1.3 * float(k)));
				vec2 bd = normalize(vec2(1.0, -0.55));
				vec2 pq = vec2(hp.z, hp.y) - b0;
				float tb = clamp(dot(pq, bd), 0.0, bare_r * 3.6);
				float db = length(pq - bd * tb);
				c = mix(c, dark, (1.0 - smoothstep(bare_r * 0.1, bare_r * 0.22, db)) * smoothstep(0.3, 0.7, abs(normalize(rn).x)) * 0.85);
			}
			// (its whisker pads: rows of dark spots, the whiskers' roots)
			float pad = smoothstep(bare_b.z - bare_r * 1.6, bare_b.z - bare_r * 2.6, hp.z) * smoothstep(0.3, 0.6, abs(normalize(rn).x));
			c = mix(c, dark, spots(vec3(hp.x * 0.5, hp.y * 1.6, hp.z), 3.5, 0.3) * pad * low * 0.7);
		}
		if (leg) {
			c = mix(buff, grey, 0.3);
			c = mix(c, dark, smoothstep(0.55, 0.85, sin(a * 40.0)) * (1.0 - smoothstep(0.6, 0.9, a)) * 0.55);
			c = mix(c, white * 0.95, (1.0 - smoothstep(-0.3, 0.2, ny)) * 0.4);
		}
		if (pt == 6.0) {
			c = mix(buff, dark, smoothstep(0.6, 0.9, sin(a * 18.0)) * 0.6);
			c = mix(c, mix(dark, white, 1.0 - smoothstep(-0.2, 0.2, ny)), smoothstep(0.78, 0.86, a));
		}
		if (pt == 5.0)
			c = rn.z < 0.0 ? /*(its back: away from its cup)*/ mix(vec3(0.08, 0.07, 0.06), white, (1.0 - smoothstep(ear_len * 0.12, ear_len * 0.2, length(rp.xy - vec2(0.0, ear_len * 0.45))))) : mix(mix(white * 0.8, buff, 0.45), vec3(0.1, 0.08, 0.06), smoothstep(0.75, 1.0, abs(rp.x) / max(ear_len * 0.36 * (1.0 - rp.y / max(ear_len, 1.0)) + 1.0, 1.0)));
	} else if (species == 2 || species == 3) {
		// 2 a coyote: grizzled grey brown above, black tipped down its back,
		// tawny on its sides, legs, ears and muzzle; its throat and belly
		// cream; its tail grizzled, black tipped. 3 a grey wolf: grizzled
		// grey, a darker saddle, pale buff legs and flanks, its underside
		// and the mask of its face pale; the tail dark tipped.
		bool wolf = species == 3;
		vec3 back = wolf ? vec3(0.3, 0.29, 0.27) : vec3(0.42, 0.36, 0.29);
		vec3 side = wolf ? vec3(0.52, 0.48, 0.42) : vec3(0.64, 0.47, 0.3);
		vec3 pale = wolf ? vec3(0.84, 0.81, 0.74) : vec3(0.86, 0.8, 0.68);
		if (young) {
			back = wolf ? vec3(0.17, 0.16, 0.15) : vec3(0.32, 0.27, 0.23);
			side = wolf ? vec3(0.25, 0.23, 0.21) : vec3(0.42, 0.35, 0.28);
			pale = side * 1.3;
		}
		c = countershade(back, side, mix(pale, side, sculpt ? fw : 0.0), ny, -0.3); // (a sculpted face: its pale painted below)
		c = mix(c, back * 0.55, smoothstep(0.8, 0.98, ny) * (1.0 - fw) * (wolf ? 0.5 : 0.35) * (0.6 + 0.4 * vn(rp * 0.02)));
		if (!sculpt)
			c = mix(c, wolf ? pale : side * 1.05, fw * smoothstep(0.2, -0.3, ny));
		c = mix(c, pale, sculpt ? fw * (1.0 - smoothstep(-0.85, -0.5, ny)) : chin);
		if (leg)
			c = mix(side * 1.04, pale, (wolf ? 0.4 : 0.15) + 0.3 * smoothstep(0.4, 0.9, a));
		if (pt == 6.0) {
			c = mix(side, back, 0.55);
			c = mix(c, pale, (1.0 - smoothstep(-0.4, 0.1, ny)) * 0.6);
			c = mix(c, vec3(0.07, 0.06, 0.055), smoothstep(0.8, 0.92, a));
		}
		if (!young && !leg && pt != 5.0) { // (grizzled: the guard hairs' black tips and pale bands, in locks)
			float up = smoothstep(-0.1, 0.7, ny) * (1.0 - fw * 0.5);
			c = mix(c, back * 0.35, smoothstep(0.5, 0.9, vn(rp * vec3(0.16, 0.16, 0.04) + vec3(0.0, 0.0, vn(rp * 0.05) * 3.0))) * (wolf ? 0.5 : 0.4) * up);
			c = mix(c, pale, smoothstep(0.55, 0.9, vn(rp * vec3(0.2, 0.2, 0.05) + 5.0)) * 0.22 * up);
		}
		if (sculpt && fw > 0.5 && !young) {
			vec3 hq = vec3(abs(hp.x), hp.y, hp.z);
			float sd = smoothstep(0.2, 0.55, abs(normalize(rn).x));
			float fore = smoothstep(bare_b.z - bare_r * 0.5, bare_b.z - bare_r * 3.0, hp.z); // (ahead of its eyes: its muzzle)
			vec3 tawny = wolf ? vec3(0.52, 0.45, 0.36) : vec3(0.6, 0.43, 0.27);
			// (its muzzle's top and round its eyes: tawny; its forehead grizzled)
			c = mix(c, tawny, fore * smoothstep(-0.1, 0.5, ny) * (wolf ? 0.6 : 0.7));
			c = mix(c, tawny, (1.0 - smoothstep(bare_r * 1.1, bare_r * 2.2, length(hq - bare_b))) * (wolf ? 0.3 : 0.7));
			// (its upper lips, cheeks and throat pale, below a line from its nose back under its eye)
			float liny = mix(nose_c.y - nose_r * (wolf ? 1.2 : 1.5), bare_b.y - bare_r * (wolf ? 2.6 : 3.2), clamp((hp.z - nose_c.z) / max(bare_b.z - nose_c.z, 1.0), 0.0, 1.6));
			c = mix(c, wolf ? vec3(0.86, 0.84, 0.8) : vec3(0.88, 0.84, 0.76), (1.0 - smoothstep(liny - 4.0, liny + 4.0, hp.y)) * sd);
			if (wolf) { // (its mask: a pale spot over each eye, its cheeks' ruff buff)
				float brow = 1.0 - smoothstep(bare_r * 0.6, bare_r * 1.4, length((hq - bare_b - vec3(-bare_r * 0.1, bare_r * 1.3, bare_r * 0.3)) / vec3(1.0, 0.5, 1.6)));
				c = mix(c, pale, brow * 0.7);
				c = mix(c, vec3(0.74, 0.68, 0.58), smoothstep(bare_b.z + bare_r, bare_b.z + bare_r * 3.5, hp.z) * smoothstep(0.4, 0.8, abs(normalize(rn).x)) * (1.0 - smoothstep(0.2, 0.6, ny)) * 0.7);
			}
			// (the dark line along its upper lid, out to its eye's back corner)
			vec3 qe = (hq - bare_b - vec3(0.0, bare_r * 0.45, bare_r * 0.5)) / vec3(1.0, 0.35, 1.5);
			c = mix(c, vec3(0.08, 0.06, 0.05), (1.0 - smoothstep(bare_r * 0.7, bare_r * 1.0, length(qe))) * 0.6);
		}
		if (pt == 5.0)
			c = rn.z < 0.0 ? /*(its back: away from its cup)*/ (wolf ? mix(side, back, 0.4) : vec3(0.6, 0.38, 0.2)) : mix(pale * 0.8, side, 0.55);
	} else if (species == 4 || species == 5) {
		// 4 a black bear: glossy black (or cinnamon, brown, blond), its
		// muzzle tan, now and then a white blaze on its chest. 5 a brown
		// bear: brown, darker down its legs and beneath (grizzled: the hairs'
		// tips silvered over its back and shoulders; or blond), its muzzle
		// paler.
		vec3 base;
		if (species == 4)
			base = phase == 0 ? vec3(0.13, 0.11, 0.1) : (phase == 1 ? vec3(0.45, 0.26, 0.13) : (phase == 2 ? vec3(0.28, 0.19, 0.11) : vec3(0.68, 0.54, 0.34)));
		else
			base = phase == 2 ? vec3(0.62, 0.48, 0.3) : vec3(0.35, 0.24, 0.14);
		c = base;
		if (species == 5) {
			c = mix(c, c * 0.62, 1.0 - smoothstep(-0.6, 0.2, ny));
			if (phase == 1)
				c = mix(c, vec3(0.74, 0.67, 0.56), smoothstep(0.1, 0.85, ny) * (0.35 + 0.4 * vn(rp * 0.03)) * (1.0 - fw * 0.5));
		} else {
			c = mix(c, c * 0.8, 1.0 - smoothstep(-0.6, 0.0, ny));
		}
		if (!young && !leg && pt < 4.0) { // (the coat in locks: darker roots between, lighter tips (a grizzly's silvered))
			vec3 lq = rp * vec3(0.06, 0.06, 0.014) + vec3(0.0, 0.0, vn(rp * 0.02) * 2.0);
			c = mix(c, c * 0.7, smoothstep(0.4, 0.9, vn(lq)) * 0.4);
			c = mix(c, species == 5 ? vec3(0.62, 0.52, 0.38) : c * 1.5 + vec3(0.02), smoothstep(0.55, 0.95, vn(lq * 1.3 + 7.0)) * (species == 5 ? 0.22 : 0.15) * smoothstep(-0.3, 0.6, ny));
		}
		if (leg)
			c *= mix(1.0, species == 5 ? 0.6 : 0.85, smoothstep(0.3, 0.8, a));
		vec3 tan = species == 4 ? vec3(0.58, 0.44, 0.29) : base * 1.35 + vec3(0.05);
		c = mix(c, tan, fw * (1.0 - smoothstep(muzzle_z - 30.0, muzzle_z + 10.0, hp.z)));
		if (blaze && pt == 0.0 && fw < 0.1) // (a white V on its chest)
			c = mix(c, white, (1.0 - smoothstep(0.03, 0.06, abs(rp.x) / 400.0 + abs(a - 0.56) * 0.6)) * (1.0 - smoothstep(-0.5, -0.1, ny)));
		if (pt == 7.0)
			c = species == 5 ? vec3(0.72, 0.66, 0.56) : vec3(0.1, 0.09, 0.08);
		if (pt == 5.0)
			c *= 0.9;
	} else if (species == 6) {
		// an American bison: its head, beard, hump, shoulders and forelegs
		// dark chocolate brown, the wool there long and curled; behind its
		// shoulders lighter, browner, short; its belly no paler; a calf red
		// orange (a "red dog")
		// (from photographs: its head, beard and legs near black brown; the
		// cape over its hump and shoulders paler, a golden tawny; behind it
		// darker brown again)
		vec3 fore = young ? vec3(0.56, 0.31, 0.14) : vec3(0.15, 0.1, 0.065);
		vec3 cape = young ? vec3(0.58, 0.33, 0.15) : vec3(0.46, 0.31, 0.16);
		vec3 hindc = young ? vec3(0.6, 0.35, 0.17) : vec3(0.27, 0.18, 0.11);
		float front = 1.0 - smoothstep(front_z - 250.0, front_z + 250.0, rp.z);
		c = mix(hindc, cape, front * smoothstep(-0.5, 0.1, ny));
		c = mix(c, fore, front * (1.0 - smoothstep(-0.7, -0.3, ny)));
		if (pt == 1.0 || pt == 5.0 || fw > 0.3)
			c = fore;
		else if (a > 0.55 && pt == 0.0) // (its neck: the cape over, dark under)
			c = mix(fore, cape, smoothstep(-0.2, 0.5, ny) * 0.85);
		if (!young && !leg) { // (the wool in locks, the tips paler)
			vec3 lq = rp * vec3(0.05, 0.05, 0.03);
			c = mix(c, c * 0.6, smoothstep(0.4, 0.9, vn(lq)) * 0.5);
			c = mix(c, c * 1.5 + vec3(0.03), smoothstep(0.6, 0.95, vn(lq * 1.4 + 3.0)) * 0.35);
		}
		if (leg)
			c = mix(fore, hindc * 0.8, hind ? 0.4 : 0.0) * mix(1.0, 0.8, smoothstep(0.4, 0.9, a));
		if (pt == 4.0)
			c = vec3(0.05, 0.045, 0.04);
		if (pt == 7.0)
			c = vec3(0.04, 0.035, 0.03);
		if (pt == 6.0)
			c = mix(hindc, fore, smoothstep(0.6, 0.9, a));
	} else if (species == 8) {
		// a snowshoe hare in its summer coat: brown, grizzled, darker along
		// its back; white beneath and its chin; its big hind feet paler; its
		// ears brown backed, black tipped, buff within; its tail white
		// beneath, dark above
		// (from photographs: grey brown, grizzled, its face and crown warmer, rufous; its chin and lips pale; its feet and lower legs white)
		vec3 brown = vec3(0.44, 0.36, 0.27);
		vec3 dark = vec3(0.3, 0.25, 0.19);
		c = countershade(dark, brown, mix(white, brown * 1.1, fw), ny, -0.45);
		c = mix(c, vec3(0.52, 0.34, 0.18), fw * smoothstep(-0.3, 0.4, ny) * 0.6);
		c *= 0.86 + 0.28 * vn(rp * 0.35) * vn(rp * 0.09 + 4.0); // (the hairs' bands: grizzled)
		c = mix(c, white, fw * (1.0 - smoothstep(-0.85, -0.55, ny)));
		if (leg) {
			c = mix(brown * 1.05, white * 0.97, hind ? smoothstep(0.5, 0.68, a) : smoothstep(0.45, 0.65, a));
			c = mix(c, white * 0.95, (1.0 - smoothstep(-0.4, 0.0, ny)) * (1.0 - smoothstep(0.2, 0.5, a)) * 0.6);
		}
		if (pt == 6.0)
			c = mix(white, dark * 1.1, smoothstep(0.0, 0.5, ny));
		if (pt == 5.0) {
			c = mix(brown * 0.95, vec3(0.78, 0.64, 0.55), rn.z > 0.0 ? 0.55 : 0.0);
			c = mix(c, vec3(0.05, 0.045, 0.04), smoothstep(ear_len * 0.78, ear_len * 0.86, rp.y));
		}
	} else if (species == 9) {
		// a deer mouse: rich brown above (back), sharply white beneath and
		// on its feet; its tail two-toned, dark above, white below; a pup
		// pink (fur: 0) as it's born, then grey, then brown
		vec3 top = mouse_back;
		c = mix(top, white, 1.0 - smoothstep(line_y - 0.06, line_y + 0.06, ny));
		c *= 0.9 + 0.2 * vn(rp * 0.6);
		if (leg)
			c = mix(c, white * 0.96, smoothstep(0.3, 0.5, a));
		if (pt == 6.0)
			c = mix(white * 0.92, top * 0.75, smoothstep(-0.05, 0.15, ny)) * (0.92 + 0.08 * step(0.5, fract(a * 60.0)));
		c = mix(vec3(0.9, 0.6, 0.56), c, fur);
	} else if (species == 10) {
		// an eastern fox squirrel: grizzled grey brown above washed orange;
		// its belly, cheeks, feet and its tail beneath rusty orange; its
		// tail's long hairs banded black, orange at their tips round its
		// edge; its ears orange buff; a kit pink and naked (fur: 0)
		vec3 grizzle = vec3(0.5, 0.37, 0.24);
		vec3 rust = vec3(0.82, 0.45, 0.18);
		c = countershade(mix(grizzle, rust, 0.15) * 0.85, mix(grizzle, rust, 0.55), rust, ny, 0.05);
		c *= 0.84 + 0.32 * vn(rp * 0.4) * vn(rp * 0.1 + 6.0); // (the hairs' bands)
		c = mix(c, rust * 1.05, fw * smoothstep(0.35, -0.2, ny));
		c = mix(c, rust * 1.12, chin * 0.6);
		if (leg)
			c = mix(rust * 0.92, rust * 1.05, smoothstep(0.4, 0.9, a)) * (0.9 + 0.15 * vn(rp * 0.3));
		if (pt == 6.0) {
			float band = smoothstep(0.4, 0.7, vn(rp * 0.12)) * smoothstep(0.3, 0.7, vn(rp * 0.45 + 3.0));
			vec3 top = mix(vec3(0.7, 0.4, 0.17), vec3(0.16, 0.11, 0.07), band * 0.55);
			c = mix(top, rust * 1.1, smoothstep(0.55, 0.95, abs(normalize(rn).x)) * 0.8); // (its orange fringe)
			c = mix(c, rust, 1.0 - smoothstep(-0.5, -0.1, ny));
		}
		if (pt == 5.0)
			c = rn.z > 0.0 ? rust * 1.15 : mix(grizzle, rust, 0.6);
		c = mix(vec3(0.88, 0.6, 0.55), c, fur);
	} else if (species == 12) {
		// an eastern grey squirrel: grizzled silver grey, washed brown along
		// its back, over its head and down its legs; its belly, throat and
		// eye rings white; its ears grey, white behind; its tail grey, the
		// hairs banded black and tipped white, a silvery fringe; a kit pink
		// and naked (fur: 0)
		vec3 grey = vec3(0.52, 0.51, 0.49);
		vec3 brown = vec3(0.5, 0.39, 0.27);
		vec3 belly = vec3(0.9, 0.89, 0.86);
		c = countershade(mix(grey, brown, 0.45) * 0.85, grey, belly, ny, -0.1);
		c *= 0.8 + 0.4 * vn(rp * 0.4) * vn(rp * 0.1 + 6.0); // (the hairs' bands: grizzled)
		c = mix(c, brown * 1.05, fw * smoothstep(-0.1, 0.6, ny) * 0.28); // (its head's brown wash)
		c = mix(c, belly, chin);
		if (leg)
			c = mix(mix(grey, brown, 0.5), grey * 0.95, smoothstep(0.5, 0.9, a)) * (0.88 + 0.18 * vn(rp * 0.3));
		if (pt == 6.0) {
			float band = smoothstep(0.4, 0.7, vn(rp * 0.12)) * smoothstep(0.3, 0.7, vn(rp * 0.45 + 3.0));
			vec3 core = mix(grey * 0.95, vec3(0.12, 0.11, 0.1), band * 0.6);
			c = mix(core, vec3(0.92, 0.91, 0.88), smoothstep(0.75, 0.98, abs(normalize(rn).x)) * 0.75); // (its white fringe)
			c = mix(c, mix(grey, belly, 0.3), (1.0 - smoothstep(-0.7, -0.3, ny)) * 0.7);
		}
		if (pt == 5.0)
			c = rn.z > 0.0 ? mix(grey, belly, 0.5) : grey * 0.9;
		c = mix(vec3(0.88, 0.6, 0.55), c, fur);
	} else if (species == 11) {
		// a beaver: rich dark brown, glossy, its sides warmer, its belly a
		// little paler; its feet bare, black; its tail a scaled black paddle
		// (furred only at its root); its ears small, dark
		vec3 back = vec3(0.16, 0.098, 0.058);
		vec3 side = vec3(0.26, 0.16, 0.09);
		vec3 belly = vec3(0.34, 0.24, 0.16);
		c = countershade(back, side, belly, ny, -0.35);
		c = mix(c, side * 1.15, fw * smoothstep(0.3, -0.3, ny));
		if (leg)
			c = mix(side * 0.85, vec3(0.1, 0.09, 0.085), smoothstep(0.6, 0.78, a));
		if (pt == 6.0) {
			float cell = max(abs(fract(rp.x / 9.0) - 0.5), abs(fract(rp.z / 9.0 + 0.5 * floor(rp.x / 9.0)) - 0.5));
			vec3 scale_c = vec3(0.15, 0.14, 0.14) * (0.8 + 0.35 * smoothstep(0.38, 0.48, cell));
			c = mix(back, scale_c, smoothstep(0.06, 0.14, a));
		}
		if (pt == 5.0)
			c = back * 0.85;
	} else if (species == 13) {
		// a moose: dark brown, near black above, its legs pale grey brown
		// below (its stockings), its muzzle browner; the bell its body's; a
		// calf red brown, unspotted. Its antlers (part 7) in velvet in summer
		// (brown felt) or hard and pale; its hooves black (part 4)
		// (a bull near black, his face dark; a cow browner, her face paler, grey
		// brown, a pale patch under her tail)
		vec3 body = young ? vec3(0.5, 0.3, 0.16) : (male ? vec3(0.12, 0.09, 0.07) : vec3(0.27, 0.2, 0.14));
		c = countershade(body * 0.82, body, body * 1.15, ny, -0.6);
		c *= 0.85 + 0.3 * vn(rp * vec3(0.03, 0.03, 0.01)); // (its long coarse hair in locks)
		if (fw > 0.0) {
			vec3 face = young ? body * 1.1 : (male ? vec3(0.2, 0.15, 0.11) : vec3(0.36, 0.29, 0.21));
			c = mix(c, face, fw * (male ? 1.0 - smoothstep(muzzle_z - 60.0, muzzle_z + 60.0, hp.z) : 0.7));
		}
		if (!male && !young && pt == 0.0)
			c = mix(c, vec3(0.7, 0.63, 0.52), smoothstep(0.05, 0.0, a) * (1.0 - smoothstep(-0.2, 0.3, ny)) * 0.9);
		if (leg)
			c = mix(c, young ? body * 1.15 : vec3(0.42, 0.37, 0.3), smoothstep(0.45, 0.7, a));
		if (pt == 5.0)
			c = rn.z > 0.0 ? mix(body, vec3(0.4, 0.34, 0.28), 0.5) : body;
		if (pt == 4.0)
			c = vec3(0.05, 0.045, 0.04);
		if (pt == 7.0)
			c = phase == 0 ? vec3(0.27, 0.19, 0.13) * (0.9 + 0.2 * vn(rp * 0.05)) : mix(vec3(0.74, 0.68, 0.57), vec3(0.45, 0.38, 0.3), vn(rp * 0.02) * 0.6);
	} else {
		// a white-tailed deer: summer red brown, darker down its spine;
		// winter grey brown; white beneath and inside its legs, its chin, a
		// band behind its nose, a ring round each eye and the patch on its
		// throat; its nose and the top of its muzzle dark; its ears edged
		// dark, white within; its tail brown above, white beneath. A fawn
		// red, white spotted in rows down its back and sides. Its hooves
		// black; a buck's antlers in velvet (summer) or hard and pale.
		bool winter = phase == 1 && !young;
		vec3 coat = winter ? vec3(0.44, 0.38, 0.31) : vec3(0.6, 0.4, 0.25);
		vec3 spine = winter ? vec3(0.32, 0.27, 0.22) : vec3(0.46, 0.29, 0.17);
		c = countershade(spine, coat, white, ny, -0.55);
		if (pt == 0.0 && fw < 0.5) {
			c = mix(c, white, smoothstep(0.03, 0.0, a) * (1.0 - smoothstep(-0.3, 0.3, ny))); // (under its tail)
			if (young) { // (a fawn's spots)
				float sp = spots(rp * vec3(1.0, 1.0, 0.8), 70.0, 0.34);
				c = mix(c, white * 0.97, sp * smoothstep(0.05, 0.4, ny) * (1.0 - smoothstep(0.93, 0.99, ny)) * (1.0 - smoothstep(0.62, 0.7, a)));
			}
			// (the throat patch: just below the jaw)
			c = mix(c, white, smoothstep(0.66, 0.7, a) * (1.0 - smoothstep(0.76, 0.8, a)) * (1.0 - smoothstep(-0.6, -0.25, ny)));
		}
		if (fw > 0.0) {
			vec3 face = mix(coat, spine, smoothstep(0.4, 0.95, ny));
			float ring = max(1.0 - smoothstep(bare_r * 1.2, bare_r * 1.42, length(hp - bare_a)), 1.0 - smoothstep(bare_r * 1.2, bare_r * 1.42, length(hp - bare_b)));
			face = mix(face, white, ring * 0.45);
			float band = smoothstep(muzzle_z - 30.0, muzzle_z - 12.0, hp.z) * (1.0 - smoothstep(muzzle_z + 10.0, muzzle_z + 30.0, hp.z));
			face = mix(face, white, band * 0.9);
			face = mix(face, vec3(0.13, 0.085, 0.06), (1.0 - smoothstep(muzzle_z - 40.0, muzzle_z - 25.0, hp.z)) * smoothstep(-0.2, 0.4, ny));
			face = mix(face, white, 1.0 - smoothstep(-0.6, -0.25, ny));
			c = mix(c, face, fw);
		}
		if (leg) {
			c = mix(coat * 1.06, spine, 0.15);
			c = mix(c, white * 0.95, (1.0 - smoothstep(-0.2, 0.2, ny)) * 0.5 + 0.2 * smoothstep(0.6, 0.9, a));
		}
		if (pt == 4.0)
			c = vec3(0.07, 0.065, 0.06);
		if (pt == 5.0)
			c = rn.z < 0.0 ? /*(its back: away from its cup)*/ mix(coat * 0.9, vec3(0.1, 0.08, 0.06), smoothstep(ear_len * 0.85, ear_len, rp.y)) : mix(mix(white * 0.82, coat, 0.2), vec3(0.1, 0.08, 0.06), smoothstep(ear_len * 0.9, ear_len, rp.y));
		if (pt == 6.0)
			c = mix(white, mix(coat, spine * 0.8, 0.6), smoothstep(0.1, 0.55, ny));
		if (pt == 7.0) {
			if (phase == 0)
				c = vec3(0.36, 0.27, 0.2) * (0.9 + 0.2 * vn(rp * 0.3));
			else
				c = mix(vec3(0.5, 0.42, 0.32), vec3(0.85, 0.8, 0.7), 0.4 + 0.4 * vn(rp * 0.08));
		}
	}
	if (pt == 4.0 && species < 6) // (paws: the toes' fur, darker)
		c *= 0.7;
	c = mix(c, vec3(0.8, 0.72, 0.6), to_cream);
	// the face's finer marks (its skin's; every species): the lids' dark rims
	// round its eyes, almond shaped; the lip line along its jaw's edge and
	// into the corner of its mouth; the rows of whisker spots on its muzzle;
	// its muzzle darker toward its nose
	float leather = 0.0;
	if (skin && fw > 0.0 && bare_r > 0.0) {
		vec3 ea = bare_a;
		vec3 eb = bare_b;
		vec3 qa = hp - ea;
		vec3 qb = hp - eb;
		qa.y -= slant * qa.z;
		qb.y -= slant * qb.z;
		vec3 dva = qa / vec3(1.0, sculpt ? almond : 0.72, 1.25); // (almond: long, narrow)
		vec3 dvb = qb / vec3(1.0, sculpt ? almond : 0.72, 1.25);
		float da = min(length(dva), length(dvb)) / bare_r;
		float lid = sculpt ? (1.0 - smoothstep(0.98, 1.1, da)) * smoothstep(0.84, 0.95, da) : (1.0 - smoothstep(1.02, 1.22, da)) * smoothstep(0.7, 0.9, da);
		vec3 rim_c = species == 8 || species == 10 || species == 12 ? c * 0.45 : vec3(0.05, 0.04, 0.035);
		c = mix(c, rim_c, lid * fw * 0.85);
		// (ahead of its eyes: its muzzle)
		float ahead = fw * smoothstep(ea.z - bare_r * 1.2, ea.z - bare_r * 3.5, hp.z);
		bool rodent = species == 8 || species == 9 || species == 10 || species == 11 || species == 12;
		if (pt == 1.0 && !rodent && !sculpt) // (its lower lip's edge: dark)
			c = mix(c, vec3(0.06, 0.045, 0.04), smoothstep(0.15, 0.55, ny) * ahead * 0.9);
		if (pt == 1.0 && sculpt) // (its lower lip: only the thinnest dark edge, hidden under the upper)
			c = mix(c, vec3(0.1, 0.07, 0.06), smoothstep(0.85, 0.97, ny) * ahead * 0.5);
		if (pt == 0.0 && !rodent && !sculpt) // (and the upper's, along the head's underside to its mouth's corner)
			c = mix(c, vec3(0.07, 0.05, 0.045), (1.0 - smoothstep(-0.9, -0.62, ny)) * smoothstep(0.2, 0.6, ahead) * 0.7);
		if (species < 4 || rodent) { // (the whisker spots, in rows along its muzzle's sides)
			float side = smoothstep(0.25, 0.6, abs(normalize(rn).x));
			float wsp = spots(vec3(hp.x * 0.5, hp.y * 1.7, hp.z), bare_r * 0.42, 0.28);
			c = mix(c, c * 0.45, wsp * side * smoothstep(0.4, 0.8, ahead) * (1.0 - smoothstep(-0.2, 0.25, ny)) * 0.8);
		}
		c = mix(c, c * 0.78, smoothstep(0.6, 1.0, ahead) * smoothstep(0.1, 0.6, ny) * 0.6); // (its nose's bridge)
		if (sculpt) { // (its nose pad: black leather, moist, pebbled; its nostrils, commas, either side)
			vec3 nd = (hp - nose_c) / vec3(1.0, 0.82, 0.7);
			leather = 1.0 - smoothstep(nose_r * 0.88, nose_r * 1.04, length(nd));
			vec3 leath = nose_col * (0.85 + 0.3 * vn(hp * 1.6));
			c = mix(c, leath, leather);
			for (int k = 0; k < 2; k++) {
				float sd = k == 0 ? -1.0 : 1.0;
				vec3 nc = nose_c + vec3(sd * nose_r * 0.42, -nose_r * 0.08, -nose_r * 0.55);
				float nostril = 1.0 - smoothstep(nose_r * 0.14, nose_r * 0.24, length((hp - nc) / vec3(1.0, 0.7, 1.0)));
				c = mix(c, vec3(0.008, 0.006, 0.006), nostril * leather);
			}
		}
	}
	// the fur: fine strands lying the way its hair lies (back along the body
	// and head, down the legs, out along the tail), each a little lighter at
	// its tip, darker at its root; the strands gathered in locks; a soft
	// mottling. Its grain in the light, too: the surface bumped by the
	// strands and the locks (fading out where they'd shimmer, far off).
	bool bare = pt == 4.0 || pt == 7.0 || (species == 11 && ((pt == 6.0 && a > 0.12) || (leg && a > 0.7))) || leather > 0.5;
	float s = clamp(hair * 0.06, 0.3, 4.0); // (a strand's width, mm)
	vec3 stretch = leg ? vec3(1.0, 4.0, 1.0) : vec3(1.0, 1.0, 4.0);
	vec3 q = rp / (s * stretch);
	vec3 qc = rp / (s * 6.0 * stretch * 0.6);
	float fine_vis = 1.0 - smoothstep(0.35, 1.2, length(fwidth(q)));
	float lock_vis = 1.0 - smoothstep(0.35, 1.2, length(fwidth(qc)));
	float strand = vn(q) * 0.6 + vn(q * 2.2 + 11.0) * 0.4;
	float locks = vn(qc) * 0.7 + vn(qc * 1.9 + 4.0) * 0.3;
	float mott = vn(rp * 0.012 + 3.0);
	float wool = 0.0;
	if (species == 6 && !young) {
		float front = (1.0 - smoothstep(front_z - 250.0, front_z + 250.0, rp.z));
		if (fw > 0.0 || a > 0.55 || (leg && !hind && a < 0.6) || pt == 1.0)
			front = 1.0;
		wool = front * (pt == 0.0 || leg || pt == 1.0 ? 1.0 : 0.0);
		float curl = vn(rp * 0.06) * 0.5 + vn(rp * 0.13 + 5.0) * 0.5;
		c *= mix(1.0, 0.62 + 0.55 * curl, wool);
	}
	float h = mix(0.5, strand, fine_vis) * 0.55 + mix(0.5, locks, lock_vis) * 0.45;
	if (!bare) {
		c *= mix(0.82, 1.14, h); // (tips lighter, roots darker)
		c *= 0.92 + 0.16 * mott;
		c = mix(c, c * vec3(1.06, 1.03, 0.98), smoothstep(0.7, 0.9, strand) * fine_vis * 0.5); // (a few paler hairs)
	}
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2)); // (its colours are written as seen, sRGB: to linear)
	if (!bare) {
		// (bump: the height h's slope across the screen, onto the surface)
		vec3 dpdx = dFdx(VERTEX);
		vec3 dpdy = dFdy(VERTEX);
		float dhdx = dFdx(h);
		float dhdy = dFdy(h);
		vec3 n = normalize(NORMAL);
		vec3 r1 = cross(dpdy, n);
		vec3 r2 = cross(n, dpdx);
		float det = dot(dpdx, r1);
		float k = s * 0.0007 * (1.0 + 3.5 * wool) * clamp(hair / 20.0, 0.5, 2.0);
		vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
		NORMAL = normalize(abs(det) * n - grad * k);
	}
	if (pt == 7.0) { // (horn, antler, claw: hard, a sheen)
		ROUGHNESS = (species == 7 || species == 13) && phase == 0 ? 0.85 : 0.4;
		SPECULAR = 0.5;
	} else if (pt == 4.0 && (species == 6 || species == 7 || species == 13)) {
		ROUGHNESS = 0.45;
		SPECULAR = 0.45;
	} else {
		// (fur: matte, a soft sheen on its guard hairs; a velvet rim where
		// it turns from the light, its hairs' fuzz against the sky)
		ROUGHNESS = (species == 4 && phase == 0) || species == 11 ? 0.78 : 0.95;
		SPECULAR = 0.14;
		if (bare) {
			ROUGHNESS = 0.55;
			SPECULAR = 0.3;
		}
		RIM = bare ? 0.05 : 0.18;
		RIM_TINT = 0.55;
		if (leather > 0.0) {
			ROUGHNESS = mix(ROUGHNESS, 0.32, leather);
			SPECULAR = mix(SPECULAR, 0.5, leather);
		}
	}
	if (pt == 5.0) { // (its ears: thin, a little light through them; no rim to wash them out)
		BACKLIGHT = vec3(0.1, 0.05, 0.035);
		RIM = 0.08;
		ALBEDO *= 0.82;
	}
}
