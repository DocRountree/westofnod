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
			c = rn.z > 0.0 ? vec3(0.07, 0.05, 0.045) : mix(white * 0.92, vec3(0.1, 0.07, 0.05), smoothstep(ear_len * 0.8, ear_len, rp.y));
	} else if (species == 1) {
		// a bobcat: tawny buff to grey brown, spotted dark down its sides and
		// legs, barred on its legs; white beneath, spotted black; white
		// round its muzzle, black bars on its cheeks; ears black backed with
		// a white spot, tufted; its bobbed tail barred, its tip black above.
		vec3 buff = young ? vec3(0.52, 0.46, 0.4) : vec3(0.62, 0.47, 0.31);
		vec3 grey = young ? vec3(0.44, 0.4, 0.36) : vec3(0.44, 0.38, 0.3);
		vec3 dark = vec3(0.13, 0.1, 0.08);
		c = countershade(grey, buff, white, ny, -0.3);
		float sp = spots(rp, young ? 26.0 : 34.0, 0.4);
		c = mix(c, dark, sp * (1.0 - smoothstep(0.75, 0.98, ny)) * (1.0 - fw) * (young ? 0.85 : 0.7));
		c = mix(c, mix(white, dark, spots(rp, 40.0, 0.3) * 0.8), (1.0 - smoothstep(-0.55, -0.2, ny)) * (1.0 - fw));
		c = mix(c, white, chin);
		c = mix(c, white, snout * 0.8);
		float bars = fw * smoothstep(0.6, 0.9, sin(hp.y * 0.35 + hp.z * 0.12)) * (1.0 - snout) * smoothstep(-0.6, 0.2, ny) * (1.0 - smoothstep(0.5, 0.9, ny));
		c = mix(c, dark, bars * 0.3 * smoothstep(25.0, 45.0, abs(hp.x)));
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
			c = rn.z > 0.0 ? mix(vec3(0.08, 0.07, 0.06), white, (1.0 - smoothstep(ear_len * 0.12, ear_len * 0.2, length(rp.xy - vec2(0.0, ear_len * 0.45))))) : white * 0.85;
	} else if (species == 2 || species == 3) {
		// 2 a coyote: grizzled grey brown above, black tipped down its back,
		// tawny on its sides, legs, ears and muzzle; its throat and belly
		// cream; its tail grizzled, black tipped. 3 a grey wolf: grizzled
		// grey, a darker saddle, pale buff legs and flanks, its underside
		// and the mask of its face pale; the tail dark tipped.
		bool wolf = species == 3;
		vec3 back = wolf ? vec3(0.24, 0.23, 0.215) : vec3(0.36, 0.29, 0.21);
		vec3 side = wolf ? vec3(0.44, 0.41, 0.36) : vec3(0.58, 0.43, 0.27);
		vec3 pale = wolf ? vec3(0.8, 0.78, 0.72) : vec3(0.84, 0.77, 0.64);
		if (young) {
			back = wolf ? vec3(0.17, 0.16, 0.15) : vec3(0.32, 0.27, 0.23);
			side = wolf ? vec3(0.25, 0.23, 0.21) : vec3(0.42, 0.35, 0.28);
			pale = side * 1.3;
		}
		c = countershade(back, side, pale, ny, -0.3);
		c = mix(c, back * 0.55, smoothstep(0.8, 0.98, ny) * (1.0 - fw) * (wolf ? 0.5 : 0.35) * (0.6 + 0.4 * vn(rp * 0.02)));
		c = mix(c, wolf ? pale : side * 1.05, fw * smoothstep(0.2, -0.3, ny));
		c = mix(c, pale, chin);
		if (leg)
			c = mix(side * 1.04, pale, (wolf ? 0.4 : 0.15) + 0.3 * smoothstep(0.4, 0.9, a));
		if (pt == 6.0) {
			c = mix(side, back, 0.55);
			c = mix(c, pale, (1.0 - smoothstep(-0.4, 0.1, ny)) * 0.6);
			c = mix(c, vec3(0.07, 0.06, 0.055), smoothstep(0.8, 0.92, a));
		}
		if (pt == 5.0)
			c = rn.z > 0.0 ? side * (wolf ? 0.8 : 1.0) : pale * 0.9;
	} else if (species == 4 || species == 5) {
		// 4 a black bear: glossy black (or cinnamon, brown, blond), its
		// muzzle tan, now and then a white blaze on its chest. 5 a brown
		// bear: brown, darker down its legs and beneath (grizzled: the hairs'
		// tips silvered over its back and shoulders; or blond), its muzzle
		// paler.
		vec3 base;
		if (species == 4)
			base = phase == 0 ? vec3(0.055, 0.048, 0.043) : (phase == 1 ? vec3(0.45, 0.26, 0.13) : (phase == 2 ? vec3(0.28, 0.19, 0.11) : vec3(0.68, 0.54, 0.34)));
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
		vec3 fore = young ? vec3(0.56, 0.31, 0.14) : vec3(0.11, 0.075, 0.05);
		vec3 hindc = young ? vec3(0.6, 0.35, 0.17) : vec3(0.4, 0.28, 0.17);
		float front = 1.0 - smoothstep(front_z - 250.0, front_z + 250.0, rp.z);
		if (pt == 1.0 || pt == 5.0 || fw > 0.0 || a > 0.55)
			front = 1.0;
		c = mix(hindc, fore, front);
		if (leg)
			c = mix(fore, hindc * 0.7, hind ? 0.5 : 0.0) * mix(1.0, 0.75, smoothstep(0.4, 0.9, a));
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
		vec3 brown = vec3(0.45, 0.34, 0.22);
		vec3 dark = vec3(0.29, 0.22, 0.15);
		c = countershade(dark, brown, white, ny, -0.45);
		c *= 0.86 + 0.28 * vn(rp * 0.35) * vn(rp * 0.09 + 4.0); // (the hairs' bands: grizzled)
		c = mix(c, white, chin);
		if (leg) {
			c = mix(brown * 1.05, vec3(0.8, 0.72, 0.6), hind ? smoothstep(0.55, 0.75, a) : 0.25 * smoothstep(0.5, 0.9, a));
			c = mix(c, white * 0.95, (1.0 - smoothstep(-0.4, 0.0, ny)) * (1.0 - smoothstep(0.2, 0.5, a)) * 0.6);
		}
		if (pt == 6.0)
			c = mix(white, dark * 1.1, smoothstep(0.0, 0.5, ny));
		if (pt == 5.0) {
			c = mix(brown * 0.95, vec3(0.78, 0.64, 0.55), rn.z < 0.0 ? 0.55 : 0.0);
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
			c = rn.z < 0.0 ? rust * 1.15 : mix(grizzle, rust, 0.6);
		c = mix(vec3(0.88, 0.6, 0.55), c, fur);
	} else {
		// a white-tailed deer: summer red brown, darker down its spine;
		// winter grey brown; white beneath and inside its legs, its chin, a
		// band behind its nose, a ring round each eye and the patch on its
		// throat; its nose and the top of its muzzle dark; its ears edged
		// dark, white within; its tail brown above, white beneath. A fawn
		// red, white spotted in rows down its back and sides. Its hooves
		// black; a buck's antlers in velvet (summer) or hard and pale.
		bool winter = phase == 1 && !young;
		vec3 coat = winter ? vec3(0.44, 0.38, 0.31) : vec3(0.64, 0.36, 0.17);
		vec3 spine = winter ? vec3(0.32, 0.27, 0.22) : vec3(0.48, 0.26, 0.12);
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
			float ring = max(1.0 - smoothstep(bare_r * 0.9, bare_r * 1.08, length(hp - bare_a)), 1.0 - smoothstep(bare_r * 0.9, bare_r * 1.08, length(hp - bare_b)));
			face = mix(face, white, ring * 0.75);
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
			c = rn.z > 0.0 ? mix(coat * 0.9, vec3(0.1, 0.08, 0.06), smoothstep(ear_len * 0.85, ear_len, rp.y)) : mix(white * 0.88, vec3(0.1, 0.08, 0.06), smoothstep(ear_len * 0.9, ear_len, rp.y));
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
	// the fur's grain (strands lying back along the body, down the legs) and
	// a soft mottling; the bison's front curled in wool
	bool bare = pt == 4.0 || pt == 7.0;
	float s = clamp(hair * 0.1, 0.6, 6.0);
	vec3 q = leg ? vec3(rp.x / s, rp.y / (s * 5.0), rp.z / s) : vec3(rp.x / s, rp.y / s, rp.z / (s * 5.0));
	float grain = vn(q) * 0.6 + vn(q * 2.3 + 11.0) * 0.4;
	float mott = vn(rp * 0.012 + 3.0);
	float wool = 0.0;
	if (species == 6 && !young) {
		float front = (1.0 - smoothstep(front_z - 250.0, front_z + 250.0, rp.z));
		if (fw > 0.0 || a > 0.55 || (leg && !hind && a < 0.6) || pt == 1.0)
			front = 1.0;
		wool = front * (pt == 0.0 || leg || pt == 1.0 ? 1.0 : 0.0);
		float curl = vn(rp * 0.06) * 0.5 + vn(rp * 0.13 + 5.0) * 0.5;
		c *= mix(1.0, 0.68 + 0.45 * curl, wool);
	}
	if (!bare)
		c *= (0.88 + 0.24 * grain) * (0.93 + 0.14 * mott);
	ALBEDO = clamp(c, 0.0, 1.0);
	// (its grain in the light: the normal stirred a little; more in wool)
	if (!bare) {
		float amp = 0.07 + 0.18 * wool;
		vec3 g = vec3(vn(q * 1.7 + 2.0), vn(q * 1.7 + 9.0), 0.0) - vec3(0.5, 0.5, 0.0);
		NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(g * amp, 0.0)).xyz);
	}
	if (pt == 7.0) { // (horn, antler, claw: hard, a sheen)
		ROUGHNESS = species == 7 && phase == 0 ? 0.85 : 0.4;
		SPECULAR = 0.5;
	} else if (pt == 4.0 && (species == 6 || species == 7)) {
		ROUGHNESS = 0.45;
		SPECULAR = 0.45;
	} else {
		ROUGHNESS = species == 4 && phase == 0 ? 0.62 : 0.86; // (a black bear's coat glossy)
		SPECULAR = 0.28;
		RIM = 0.25;
		RIM_TINT = 0.7;
	}
	if (pt == 5.0) // (light through its ears)
		BACKLIGHT = vec3(0.12, 0.06, 0.04);
}
