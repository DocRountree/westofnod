shader_type spatial;

// A bat's coat and its bare face (Bat: its one skin, MammalSkin's): the skin
// itself (shell 0) and, over it, the fur in shells (shell up to 1: the
// skin's mesh drawn again, each a little further out along the hairs, each
// keeping only the hairs that reach it). Long, soft, lying back: each hair
// dark at its root, a glossy brown at its tip (its back), buff (its belly);
// shorter over its crown and cheeks, down to none on its muzzle, its lips,
// round its eyes: those black, bare skin. A newborn's naked and pink (fur: 0).

uniform float fur = 1.0;
uniform float fur_len = 5.5;      // (mm: its back's)
uniform vec3 eye_a = vec3(0.0, -1e6, 0.0); // (its eyes, the head's mm)
uniform vec3 eye_b = vec3(0.0, -1e6, 0.0);
uniform float eye_r = 1.5;
uniform vec3 ear_at = vec3(0.0, -1e6, 0.0); // (its right ear's root, the head's mm: the fur short round it)
uniform float muzzle_z = -12.5;   // (ahead of here bare: the head's mm)
uniform float dead = 0.0;
instance uniform float shell = 0.0;

varying vec4 c0;
varying vec3 rp;
varying vec3 rn;
varying vec3 hp;
varying float flen;

float h31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// How long its fur is there (mm): the body's full; the head's shorter, to
// none down its muzzle and round its eyes; its jaw's short, its lips bare.
float fur_at(float pt, float fw, vec3 h, vec3 n, vec3 r) {
	float l = fur_len * mix(0.85, 1.0, smoothstep(-0.3, 0.4, n.y));
	l *= 1.0 - 0.75 * smoothstep(17.0, 25.0, r.z); // (thinning to its rump, its tail's root)
	if (fw > 0.0) {
		float mz = muzzle_z - 4.0 * smoothstep(1.8, 4.6, h.y) * (1.0 - smoothstep(1.5, 4.5, abs(h.x))); // (down its muzzle's top, further)
		float m = smoothstep(mz - 2.5, mz + 6.5, h.z); // (0 its muzzle .. 1 behind its eyes)
		float e = smoothstep(eye_r * 1.05, eye_r * 2.6, min(length(h - eye_a), length(h - eye_b)));
		float er = smoothstep(2.0, 7.0, length(vec3(abs(h.x), h.y, h.z) - ear_at - vec3(0.0, 1.5, 0.0)));
		float head = mix(0.45, 1.0, smoothstep(-8.0, 2.0, h.z)) * m * e * mix(0.2, 1.0, er);
		l *= mix(1.0, head, fw);
	}
	if (pt == 1.0)
		l = fur_len * 0.4 * smoothstep(-15.0, -11.0, h.z) * smoothstep(0.35, -0.3, n.y);
	return l * fur;
}

void vertex() {
	c0 = CUSTOM0;
	rp = CUSTOM1.xyz;
	rn = CUSTOM2.xyz;
	hp = CUSTOM3.xyz;
	flen = fur_at(floor(CUSTOM0.x + 0.5), CUSTOM0.z, hp, normalize(rn), rp);
	if (shell > 0.0) {
		vec3 n = normalize(NORMAL);
		vec3 back = vec3(0.0, -0.12, 1.0); // (lying back along it, falling a little)
		vec3 lay = back - n * dot(n, back);
		float flat_ = CUSTOM0.z; // (its head's lying closer)
		VERTEX += (n * mix(0.72, 0.5, flat_) + lay * mix(0.62, 0.85, flat_)) * shell * flen;
	}
}

void fragment() {
	float pt = floor(c0.x + 0.5);
	float fw = c0.z;
	vec3 nr = normalize(rn);
	float ny = nr.y;
	// its colours: a hair's root, its tip (its back's, its belly's)
	float belly = 1.0 - smoothstep(-0.5, 0.15, ny);
	if (pt == 1.0)
		belly = 1.0;
	vec3 tip = mix(vec3(0.43, 0.275, 0.15), vec3(0.62, 0.5, 0.36), belly);
	tip *= 0.84 + 0.3 * vn(rp * 0.35 + 2.0);
	tip = mix(tip, tip * vec3(0.8, 0.74, 0.7), fw * 0.35 * (1.0 - belly)); // (its crown a little darker)
	tip = mix(tip, vec3(0.2, 0.14, 0.1), 1.0 - smoothstep(0.8, 3.2, flen / max(fur, 0.05))); // (the short hairs of its face: dark)
	vec3 root = mix(vec3(0.1, 0.07, 0.055), vec3(0.17, 0.14, 0.12), belly);
	vec3 bare = vec3(0.12, 0.092, 0.082); // (its face, its lips: black brown skin)
	vec3 pink = vec3(0.62, 0.42, 0.4);
	vec3 c;
	float rough = 0.6;
	float spec = 0.2;
	float rim = 0.0;
	if (shell <= 0.0) {
		// the skin: under its fur dark (the hairs' roots); bare, its own
		float furred = smoothstep(0.15, 1.2, flen);
		vec3 sk = bare * (0.85 + 0.3 * vn(rp * 2.5));
		// (its lips' edge, its nose: a little paler, worn)
		c = mix(sk, root * 1.15, furred);
		c = mix(pink * (0.9 + 0.15 * vn(rp * 1.3)), c, clamp(fur * 1.4, 0.0, 1.0));
		rough = mix(0.62, 0.9, furred);
		spec = mix(0.25, 0.1, furred);
		// (its bare skin's fine wrinkles)
		float w = vn(rp * vec3(2.0, 5.0, 2.0)) * (1.0 - furred);
		vec3 dpx = dFdx(VERTEX);
		vec3 dpy = dFdy(VERTEX);
		vec3 n = normalize(NORMAL);
		vec3 r1 = cross(dpy, n);
		vec3 r2 = cross(n, dpx);
		float det = dot(dpx, r1);
		NORMAL = normalize(abs(det) * n - sign(det) * (dFdx(w) * r1 + dFdy(w) * r2) * 0.00003);
	} else {
		if (flen < 0.12)
			discard;
		// the hairs: cells over its skin, each a hair, its own length,
		// thinning to its tip; too far to see a hair, its locks (the same,
		// coarser); further, the coat solid, a little short of its tips
		float lock = vn(rp * 0.42) * 0.65 + vn(rp * 1.1 + 7.0) * 0.35;
		float lockl = mix(0.72, 1.0, smoothstep(0.25, 0.7, lock));
		vec3 q = rp * 6.5; // (hairs to a mm)
		vec3 q2 = rp * vec3(3.2, 3.2, 2.2); // (locks)
		float fa = smoothstep(0.45, 1.1, length(fwidth(q)));
		float fb = smoothstep(0.45, 1.1, length(fwidth(q2)));
		vec3 ci = floor(q);
		float r = h31(ci);
		bool coarse = h31(ci + 21.3) < fa;
		if (coarse) {
			ci = floor(q2);
			q = q2;
			r = h31(ci);
		}
		vec3 f = fract(q) - 0.5;
		vec3 off = (vec3(h31(ci + 1.7), h31(ci + 5.3), h31(ci + 9.1)) - 0.5) * 0.45;
		float hl = (coarse ? 0.8 + 0.2 * r : 0.62 + 0.38 * r) * lockl;
		float far = coarse ? fb : 0.0;
		hl = mix(hl, 0.74 * mix(lockl, 0.94, 0.7), far);
		float t = shell / hl;
		if (t > 1.0)
			discard;
		float rad = mix((coarse ? 0.8 : 0.66) * (1.0 - (coarse ? 0.45 : 0.6) * t * t), 2.0, far);
		if (length(f - off) > rad)
			discard;
		tip *= 0.86 + 0.28 * (vn(rp * vec3(1.6, 1.6, 0.45) + 3.0) * 0.6 + vn(rp * vec3(4.0, 4.0, 1.2)) * 0.4); // (streaked along it, lock by lock)
		c = mix(root, tip * (0.9 + 0.2 * r), smoothstep(0.1, 0.7, shell));
		c *= mix(0.5, 1.0, smoothstep(0.0, 0.9, t) * 0.5 + shell * 0.5); // (deep in the coat: dark)
		c = mix(c, c * 1.3 + vec3(0.03, 0.02, 0.0), smoothstep(0.75, 1.0, t) * step(0.6, r) * (1.0 - belly) * 0.5); // (its glossy tips)
		rough = mix(0.8, 0.5, shell);
		spec = mix(0.1, 0.32, shell * (1.0 - belly * 0.5));
		rim = 0.25 * shell;
	}
	c = mix(c, c * vec3(0.6, 0.62, 0.6), dead * 0.5);
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	ROUGHNESS = rough;
	SPECULAR = spec;
	RIM = rim;
	RIM_TINT = 0.6;
}
