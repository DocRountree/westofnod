shader_type spatial;
render_mode cull_disabled;

// A bird (Bird; the wild turkey its first): one mesh, posed by
// bird_rig.gdshaderinc (its joints from its motor, its wings and its tail's
// fan worked out here), feathered here.
//
// CUSTOM0: its part, and where on it (x the part; y, z: along and round a
// skin (round: 0 under its middle, 0.5 over its back), or along (0 root ..
// 1 tip) and across (-1 .. 1) a feather; w: a feather's own number, or the
// skin's region). The parts: 0 the feathered skin (w: 0 the body, 1 the
// neck); 1 bare skin (the head, the upper neck); 2 the bill; 3 an eye; 4
// the snood; 5 wattle and caruncles; 6 the beard; 7 a feathered leg; 8 a
// bare leg, the toes; 9 claws, spurs; 10 a wing's own surface (its
// coverts); 11 primaries; 12 secondaries; 13 tertials; 14 tail feathers;
// 15 tail coverts (w: -1 the lower row .. the upper).

#include "res://shaders/render/bird_rig.gdshaderinc"

// Which plumage: 0 a turkey's (metal-banded body feathers, bare head); 1 a
// raptor's (feathered head with its cap, cheeks, moustache; the back
// scaled with pale edges; the underparts barred, spotted, rufous-barred or
// streaked; barred flight feathers, banded tail; yellow cere, legs).
uniform int plumage = 0;
uniform vec3 eye_at;          // the right eye's centre (rest, m)
uniform vec3 back_color : source_color = vec3(0.2, 0.22, 0.26);
uniform vec3 back_edge : source_color = vec3(0.42, 0.45, 0.5);
uniform vec3 back_bar : source_color = vec3(0.1, 0.11, 0.13);
uniform float back_bars = 0.4;
uniform float back_from = 0.3;   // round its ring, where its back's colour begins (0.5 its spine)
uniform float back_from_hi = -1.0; // (over its shoulders, if lower: the back's colour down its sides to its folded wing)   // dark bars across the back's feathers
uniform vec3 cap_color : source_color = vec3(0.08, 0.09, 0.11);
uniform vec3 cheek_color : source_color = vec3(0.95, 0.93, 0.88);
uniform float cheek = 0.0;       // the cheeks their own colour (a Cooper's hawk's rosy grey)
uniform float hood_low = 0.002;  // m below the eye the cap reaches
uniform float hood_nape = 1.0;   // the cap down the nape (a falcon's hood: 1)
uniform float malar = 0.0;       // the moustache (a falcon's)
uniform vec3 under_color : source_color = vec3(0.93, 0.9, 0.84);
uniform vec3 under_mark : source_color = vec3(0.1, 0.1, 0.11);
uniform vec3 breast_wash : source_color = vec3(0.95, 0.88, 0.76);
uniform int under_pattern = 1;   // 0 plain, 1 bars and spots (falcon), 2 rufous bars (adult hawk), 3 streaks (juvenile)
uniform float throat_clean = 0.78; // above this along it, the throat unmarked
uniform vec3 fl_top : source_color = vec3(0.16, 0.17, 0.2);
uniform vec3 fl_pale : source_color = vec3(0.86, 0.85, 0.82);
uniform vec3 fl_dark : source_color = vec3(0.2, 0.2, 0.22);
uniform float fl_bars = 12.0;
uniform float fl_top_bars = 0.25;
uniform float tail_under = 0.55;   // (its tail from below: this much paler, as its flight feathers; a white tail none)
uniform float hood_u = -1.0;       // (an eagle's) from here along it up, all its head and neck the cap's colour (a bald eagle's white), its edge ragged
uniform vec3 nape_color : source_color = vec3(0.7, 0.5, 0.25);
uniform float nape_u = -1.0;       // from here along it up, its nape and hind neck this colour (a golden eagle's hackles)
uniform vec4 tail_cov = vec4(0.0); // its tail coverts' own colour (w: how much; a bald eagle's white)
uniform float fl_patch = 0.0;      // a pale patch at the flight feathers' bases, this far along them (a juvenile golden eagle's)
uniform vec3 fl_patch_color : source_color = vec3(0.95, 0.94, 0.9);
uniform vec4 trouser = vec4(0.0);  // its feathered legs' own colour (w: how much)
uniform float under_blotch = 0.0;        // (under pattern 6, a juvenile bald eagle's: white blotched through the brown) how much // (how dark its bars from above: an owl's plain to see)
uniform vec3 tail_color : source_color = vec3(0.3, 0.32, 0.36);
uniform vec3 tail_band : source_color = vec3(0.07, 0.07, 0.08);
uniform float tail_bands = 7.0;
uniform float tail_band_w = 0.35;
uniform vec3 tail_tip_r : source_color = vec3(0.92, 0.9, 0.86);
uniform float tail_tip_w = 0.04;
uniform vec3 cere_color : source_color = vec3(0.95, 0.75, 0.1);
uniform vec3 bill_tip : source_color = vec3(0.08, 0.08, 0.1);
uniform vec3 iris : source_color = vec3(0.12, 0.07, 0.04);
uniform vec3 down_white : source_color = vec3(0.95, 0.94, 0.9); // an eyas's down
uniform vec3 eye_dir = vec3(0.62, 0.06, -0.78); // where the right eye looks (an owl's: forward)
uniform vec3 lid_color : source_color = vec3(0.5, 0.48, 0.45);
uniform float under_bar_n = 2.0;   // (pattern 2: bars to a feather, how wide)
uniform float under_bar_w = 0.62;
uniform float mottle = 0.0;        // an owl's back: vermiculated, blotched pale
uniform float back_streak = 0.0;   // a dark streak down each back feather's shaft
uniform float back_spot = 0.0;     // a white spot, black above it, at each back feather's tip (a barn owl's)
uniform float disc = 0.0;          // an owl's facial disc
uniform float disc_r = 0.03;       // m, round each eye
uniform float disc_heart = 0.0;    // (a barn owl's: drawn down to a point at its chin)
uniform vec3 disc_color : source_color = vec3(0.6, 0.45, 0.3);
uniform vec3 disc_rim : source_color = vec3(0.05, 0.04, 0.03);
uniform vec3 disc_mid : source_color = vec3(0.9, 0.88, 0.82); // the brows, the bristles between its eyes
uniform float disc_mid_a = 1.0;
uniform vec3 disc_eye : source_color = vec3(0.3, 0.2, 0.12);   // (shading in toward the eye)
uniform float disc_rim_w = 0.12;
uniform float disc_low = 1.0;      // (below its eyes, how far less it reaches: the less, the further down)
uniform float disc_brow = 0.0;     // pale brows over its eyes, rising outward (a horned owl's V)   // the rim's width (of the disc's reach)
uniform float disc_rim_sides = 0.0; // the rim only down its outer sides (a great horned owl's brackets)
uniform vec3 tuft_dark : source_color = vec3(0.08, 0.06, 0.05); // an ear tuft's dark outer edge and tip
uniform vec3 tuft_pale : source_color = vec3(0.75, 0.66, 0.52); // and its pale inner edge
uniform float eye_lid = 0.0;       // the upper lid down over the eye (a horned owl's stare): 0 open .. 1 shut

uniform float puff = 0.0;      // the body's feathers raised (strutting)
uniform float puff_cm = 4.5;   // (how far, cm)
uniform float puff_head = 1.0; // (an owl's head: not, its eyes kept clear)
uniform float flush = 0.0;     // the bare head's colours up (strutting: white crown, blue face, scarlet wattles)
uniform float snood = 0.0;     // the snood let down over the bill (0: a short horn)
uniform float eye_shut = 0.0;
uniform float down = 0.0;      // a poult's down (1), not feathers
uniform float hen = 0.0;       // a hen's duller feathers, buff tipped
uniform float bare_from = 0.42; // where along the skin the bare neck begins
uniform vec3 snood_at;
uniform float feather_cm = 4.0; // a body feather's width
uniform float sway = 0.0;      // the beard's, the wattle's swing (its motor's)

uniform vec3 bronze : source_color = vec3(0.3, 0.19, 0.08);
uniform vec3 copper : source_color = vec3(0.46, 0.17, 0.07);
uniform vec3 green : source_color = vec3(0.1, 0.27, 0.16);
uniform vec3 dark : source_color = vec3(0.035, 0.03, 0.03);
uniform vec3 tip_color : source_color = vec3(0.02, 0.02, 0.02); // a body feather's edge (a hen's: buff)
uniform vec3 tail_tip : source_color = vec3(0.72, 0.5, 0.3);
uniform vec3 tail_brown : source_color = vec3(0.4, 0.22, 0.1);
uniform vec3 covert_tip : source_color = vec3(0.5, 0.22, 0.1);
uniform vec3 skin_red : source_color = vec3(0.8, 0.07, 0.09);
uniform vec3 skin_blue : source_color = vec3(0.2, 0.47, 0.85);
uniform vec3 skin_pale : source_color = vec3(0.86, 0.9, 0.9);
uniform vec3 leg_color : source_color = vec3(0.72, 0.38, 0.4);
uniform vec3 bill_color : source_color = vec3(0.62, 0.55, 0.45);
uniform vec3 down_color : source_color = vec3(0.86, 0.72, 0.42);
uniform vec3 down_dark : source_color = vec3(0.3, 0.19, 0.1);

varying flat int part;
varying vec3 fc; // (CUSTOM0.yzw)
varying vec3 rest;
varying vec3 rest_n;
varying vec2 suv;
varying float wing_open; // (a wing's: how far spread)
varying vec3 vn; // (its normal as posed, the view's: which side of a feather is seen)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	part = int(round(CUSTOM0.x));
	fc = CUSTOM0.yzw;
	rest = VERTEX;
	rest_n = NORMAL;
	suv = UV;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	if (part == 0 && int(round(CUSTOM1.x)) == 0) {
		// the body's feathers raised: fuller, most over its back and breast
		float body = 1.0 - smoothstep(bare_from - 0.25, bare_from, CUSTOM0.y);
		v += n * puff * puff_cm * 0.01 * mix(1.0, puff_head, smoothstep(0.84, 0.88, CUSTOM0.y)) * body * (0.55 + 0.45 * sin(CUSTOM0.z * 6.2832 - 1.5708));
	}
	if (part == 4) {
		// the snood: a short horn, or let down, long, over the bill and past it
		float along = CUSTOM0.y;
		vec3 d = v - snood_at;
		vec3 up_pose = snood_at + d;
		vec3 hang = snood_at + vec3(d.x, 0.0, d.z) + vec3(0.0, 0.012 - along * along * 0.085, -0.012 - along * 0.035 + along * along * 0.012);
		hang.x += 0.006 * sway * along * along;
		v = mix(up_pose, hang, snood);
	}
	if (part == 6) // (the beard swinging from its root)
		v.x += 0.03 * sway * CUSTOM0.y * CUSTOM0.y;
	if (part == 5)
		v.x += 0.006 * sway * CUSTOM0.y;
	wing_open = int(round(CUSTOM1.x)) == 1 || int(round(CUSTOM1.x)) == 2 ? clamp((CUSTOM1.z < 0.0 ? wing[0] : wing[1]).w, 0.0, 1.0) : 1.0;
	bird_pose(CUSTOM1, CUSTOM2, v, n);
	VERTEX = v;
	NORMAL = n;
	vn = (MODELVIEW_MATRIX * vec4(n, 0.0)).xyz;
}

vec3 bump(vec3 nrm, vec3 pos, float h, float k) {
	vec3 dpx = dFdx(pos);
	vec3 dpy = dFdy(pos);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpy, nrm);
	vec3 r2 = cross(nrm, dpx);
	float det = dot(dpx, r1);
	vec3 g = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * nrm - g * k);
}

// The body's feathers, overlapping like shingles (p: across, along, in
// feathers; they point along +y): x how far from its tip (0 the edge .. 1
// its root, hidden), y its own random, z how far across it (-1 .. 1).
vec3 shingle(vec2 p) {
	float row = floor(p.y);
	for (int k = 1; k >= 0; k--) {
		float r = row - float(k);
		float x = p.x + 0.5 * mod(r, 2.0) + 0.17 * hash(vec2(r, 3.3));
		float col = floor(x);
		float fx = fract(x) * 2.0 - 1.0;
		float fy = p.y - r; // (0 its root .. past 1: its tip, over the next row)
		float reach = 1.0 + 0.85 * sqrt(max(1.0 - fx * fx, 0.0));
		if (fy < reach || k == 0)
			return vec3(clamp((reach - fy) / 0.85, 0.0, 1.0), hash(vec2(col, r)), fx);
	}
	return vec3(1.0, 0.0, 0.0);
}

// A metal sheen that turns with the light: bronze, copper, green.
vec3 sheen(float t) {
	t = fract(t);
	vec3 c = mix(bronze, copper, smoothstep(0.0, 0.35, t));
	c = mix(c, green, smoothstep(0.35, 0.7, t));
	return mix(c, bronze, smoothstep(0.7, 1.0, t));
}

// A feather's vane: its bars across (n to its length, w wide), wavering.
float bars(float u, float v, float n, float w, float seed) {
	float x = u * n + 0.25 * abs(v) + 0.06 * sin(v * 9.0 + seed * 20.0);
	return smoothstep(w, w + 0.12, abs(fract(x) - 0.5) * 2.0);
}

// A raptor's feathers and bare parts: c, rough, metal, spec, nrm set for
// its part.
void raptor(int pt, float u, float v, vec3 view, float ndv, vec3 vtx, vec3 nrm0, inout vec3 c, inout float rough, inout float metal, inout float spec, inout vec3 nrm) {
	metal = 0.0;
	spec = 0.4;
	bool top = dot(normalize(vn), view) > 0.0; // (the side a feather's upper face is: its upper side seen)
	if (pt == 0 || pt == 7 || pt == 10) {
		vec2 p;
		float region = 0.0;
		if (pt == 0) {
			region = smoothstep(0.62, 0.82, u);
			p = vec2(suv.x, -suv.y) / (feather_cm * 0.01 * mix(1.0, 0.45, region)) * vec2(1.0, 1.3);
		} else {
			p = suv / (feather_cm * 0.01 * 0.6) * vec2(1.0, 1.3);
		}
		vec3 f = shingle(p);
		float fade = clamp(1.0 - length(fwidth(p)) * 0.8, 0.0, 1.0);
		float edge = (1.0 - smoothstep(0.04, 0.16, f.x)) * fade;
		// the back (over its back, the wing's coverts from above): dark, each
		// feather edged pale, barred darker
		float bf = back_from_hi < 0.0 ? back_from : mix(back_from, back_from_hi, smoothstep(0.3, 0.5, u) * (1.0 - smoothstep(0.78, 0.84, u)));
		float back = pt == 0 ? smoothstep(bf, bf + 0.06, v) * (1.0 - smoothstep(1.0 - bf - 0.06, 1.0 - bf, v)) : (pt == 10 ? mix(1.0, 1.0 - step(0.5, fc.z), smoothstep(0.3, 0.7, wing_open)) : 0.0); // (a wing's coverts: its upper surface the back's colour, its under the underwing's)
		vec3 bk = back_color * (0.88 + 0.24 * f.y);
		float bbar = smoothstep(0.38, 0.44, f.x) * (1.0 - smoothstep(0.52, 0.6, f.x)) * back_bars * fade;
		bk = mix(bk, back_bar, bbar);
		bk = mix(bk, back_edge, edge * 0.8);
		if (mottle > 0.0 || back_streak > 0.0 || back_spot > 0.0) {
			float verm = smoothstep(0.42, 0.58, vnoise(vec2(p.x * 5.0, p.y * 13.0)));
			float blotch = smoothstep(0.5, 0.72, vnoise(p * 0.9 + 7.0));
			bk = mix(bk, back_bar, mottle * 0.55 * verm * fade);
			bk = mix(bk, back_edge, mottle * 0.8 * blotch);
			bk = mix(bk, back_bar, back_streak * (1.0 - smoothstep(0.05, 0.16, abs(f.z))) * smoothstep(0.05, 0.2, f.x) * fade);
			float sd = length(vec2(f.z * 0.5, f.x - 0.2));
			bk = mix(bk, vec3(0.04), back_spot * (1.0 - smoothstep(0.07, 0.11, length(vec2(f.z * 0.5, f.x - 0.34)))) * fade);
			bk = mix(bk, vec3(0.95), back_spot * (1.0 - smoothstep(0.07, 0.11, sd)) * fade);
		}
		// the underparts: their marks by the pattern; the throat clean
		vec3 un = mix(under_color, breast_wash, smoothstep(0.3, 0.6, u) * (1.0 - smoothstep(0.7, 0.85, u)));
		float mk = 0.0;
		float wc = 1.0 - abs(f.z);
		if (under_pattern == 1) {
			float chev = f.x + abs(f.z) * 0.18;
			float bar = smoothstep(0.18, 0.23, chev) * (1.0 - smoothstep(0.42, 0.48, chev)) * smoothstep(0.05, 0.3, wc);
			float spot = 1.0 - smoothstep(0.16, 0.24, length(vec2(f.z * 0.4, f.x - 0.33)));
			mk = mix(bar, spot, smoothstep(0.5, 0.6, u));
		} else if (under_pattern == 2) {
			float b2 = fract(f.x * under_bar_n + 0.1 * f.z * f.z);
			mk = smoothstep(0.02, 0.08, b2) * (1.0 - smoothstep(under_bar_w, under_bar_w + 0.08, b2)) * smoothstep(0.0, 0.25, wc) * (0.85 + 0.15 * f.y);
		} else if (under_pattern == 3) {
			mk = (1.0 - smoothstep(0.12, 0.26, abs(f.z) * (1.0 + f.x))) * smoothstep(0.1, 0.22, f.x) * (1.0 - smoothstep(0.65, 0.85, f.x));
		}
		else if (under_pattern == 4) { // (a barn owl's: small dark spots, sparse)
			mk = (1.0 - smoothstep(0.07, 0.12, length(vec2(f.z * 0.5, f.x - 0.3)))) * step(0.5, f.y);
		} else if (under_pattern == 6) { // (a juvenile bald eagle's: white in blotches through the brown, each feather's base pale)
			mk = smoothstep(0.45, 0.65, vnoise(p * 0.55 + 3.1)) * under_blotch * (0.6 + 0.4 * smoothstep(0.2, 0.6, f.x));
		} else if (under_pattern == 5) { // (a screech owl's: a dark streak down each shaft, fine bars across it)
			float st5 = (1.0 - smoothstep(0.07, 0.17, abs(f.z))) * smoothstep(0.08, 0.2, f.x) * (1.0 - smoothstep(0.75, 0.95, f.x));
			float b5 = fract(f.x * 3.5 + 0.15 * abs(f.z));
			mk = max(st5, 0.75 * smoothstep(0.0, 0.08, b5) * (1.0 - smoothstep(0.26, 0.34, b5)) * smoothstep(0.0, 0.3, wc));
		}
		mk *= fade * (1.0 - smoothstep(throat_clean - 0.03, throat_clean + 0.02, u)) * (pt == 0 ? smoothstep(0.06, 0.16, u) : 1.0);
		if (pt == 7)
			mk *= 0.8;
		un = mix(un, under_mark, mk);
		if (pt == 7)
			un = mix(un, trouser.rgb * (0.9 + 0.15 * f.y), trouser.w);
		un *= 0.94 + 0.08 * f.y;
		c = mix(un, bk, back);
		// the head: its cap (and a falcon's hood down the nape), the
		// moustache, the cheeks
		if (pt == 0 && disc > 0.0) {
			// an owl's head: the back's colour over it, a disc of fine
			// feathers round each eye, a dark rim to it, pale brows and
			// bristles down between; white under its chin
			float head = smoothstep(0.86, 0.9, u);
			vec3 r = rest;
			float ax = abs(r.x);
			float qy = r.y - eye_at.y;
			float low = clamp(-qy / disc_r, 0.0, 2.5);
			float cx = eye_at.x * (1.0 - disc_heart * 0.42 * low);
			float d = length(vec2(ax - cx, qy * (qy < 0.0 ? mix(disc_low, 0.5, disc_heart) : mix(1.0, 1.25, disc_heart)))) / disc_r;
			float front = smoothstep(-0.05, -0.35, rest_n.z) * head;
			float ang = atan(qy, ax - cx);
			float wob = 0.015 * sin(ang * 60.0);
			c = mix(c, bk, head);
			c = mix(c, under_color, front * (1.0 - smoothstep(-1.25, -1.05, qy * disc_low / disc_r)) * (1.0 - disc_heart));
			vec3 dc = disc_color * (0.9 + 0.12 * sin(ang * 46.0) * smoothstep(0.3, 0.6, d));
			dc = mix(disc_eye, dc, smoothstep(0.3, 0.75, d + 0.25 * smoothstep(0.0, 1.2, -ang + 0.6) * step(ang, 2.0)));
			c = mix(c, dc, front * (1.0 - smoothstep(0.93, 1.0, d + wob)));
			float rimw = mix(1.0, smoothstep(-0.25, 0.45, cos(ang)) * (1.0 - smoothstep(0.55, 0.95, sin(ang))), disc_rim_sides);
			c = mix(c, disc_rim, front * rimw * smoothstep(1.0 - disc_rim_w, 1.0 - disc_rim_w * 0.4, d + wob) * (1.0 - smoothstep(1.0, 1.08, d + wob)));
			float mid = (1.0 - smoothstep(0.2, 0.42, (ax + max(qy, 0.0) * -0.35 + max(-qy, 0.0) * 0.5) / eye_at.x)) * smoothstep(-1.0, -0.6, qy * disc_low / disc_r) * (1.0 - smoothstep(0.15, 0.45, qy / disc_r));
			c = mix(c, disc_mid, front * mid * disc_mid_a);
			float bl = (qy - disc_r * (0.38 + 0.3 * clamp(ax / eye_at.x, 0.0, 1.6))) / disc_r;
			c = mix(c, disc_mid, front * disc_brow * (1.0 - smoothstep(0.06, 0.16, abs(bl))) * (1.0 - smoothstep(1.2, 1.6, ax / eye_at.x)));
			if (fc.z > 1.5) { // an ear tuft: the back's colour, dark down its outer edge and to its tip, pale along its inner
				float tt = fc.z - 2.0;
				vec3 tc = mix(bk, tuft_dark, clamp(smoothstep(0.55, 0.95, v) + smoothstep(0.55, 1.0, tt) * 0.8, 0.0, 1.0));
				tc = mix(tc, tuft_pale, smoothstep(0.3, 0.05, v) * (1.0 - tt) * 0.8);
				c = tc * (0.9 + 0.2 * vnoise(vec2(v * 12.0, tt * 30.0)));
			}
		} else if (pt == 0) {
			float head = smoothstep(0.76, 0.83, u);
			vec3 r = rest;
			float ax = abs(r.x);
			float above = smoothstep(eye_at.y - hood_low - 0.003, eye_at.y - hood_low + 0.001, r.y);
			float nape = hood_nape * smoothstep(eye_at.z + 0.011, eye_at.z + 0.016, r.z) * smoothstep(0.32, 0.4, v) * (1.0 - smoothstep(0.6, 0.68, v));
			float napeb = hood_nape * smoothstep(eye_at.z + 0.018, eye_at.z + 0.024, r.z);
			float hood = head * clamp(above + nape + napeb, 0.0, 1.0);
			float mz = r.z - eye_at.z - 0.002;
			float mous = head * malar * smoothstep(eye_at.y - 0.034, eye_at.y - 0.028, r.y) * (1.0 - smoothstep(0.007, 0.012, abs(mz + (eye_at.y - r.y) * 0.18))) * smoothstep(0.004, 0.009, ax);
			c = mix(c, mix(cheek_color, c, 0.25), head * cheek * (1.0 - hood));
			c = mix(c, cap_color * (0.9 + 0.2 * f.y), max(hood, mous));
		}
		if (pt == 0 && nape_u >= 0.0) { // (the hackles: down the back of its head and neck)
			float nap = smoothstep(nape_u, nape_u + 0.1, u) * (1.0 - smoothstep(0.12, 0.24, abs(v - 0.5) + 0.04 * (vnoise(vec2(u * 40.0, v * 9.0)) - 0.5)));
			nap *= mix(1.0, smoothstep(eye_at.z + 0.006, eye_at.z + 0.02, rest.z), smoothstep(0.74, 0.8, u)); // (on its head, behind its eye: its face dark)
			c = mix(c, nape_color * (0.85 + 0.3 * f.y) * mix(0.7, 1.0, smoothstep(0.0, 0.3, f.x)), nap * smoothstep(0.0, 0.05, f.x + 0.04));
		}
		if (pt == 0 && hood_u >= 0.0) { // (all its head and neck)
			float hd = smoothstep(hood_u - 0.01, hood_u + 0.02, u + 0.03 * (vnoise(vec2(v * 30.0, u * 9.0)) - 0.5) + 0.05 * f.x * (1.0 - f.x));
			c = mix(c, cap_color * (0.93 + 0.1 * f.y), hd);
		}
		rough = 0.72;
		spec = 0.35;
		nrm = bump(nrm, vtx, smoothstep(0.0, 0.4, f.x) * feather_cm * 0.0008 * fade, 1.0);
		if (down > 0.0) { // an eyas's down: white, woolly
			float fl = vnoise(rest.xz * 1400.0) * 0.5 + vnoise(rest.xy * 2600.0) * 0.5;
			c = mix(c, down_white * (0.86 + 0.16 * fl), down);
			rough = mix(rough, 0.97, down);
			nrm = normalize(mix(nrm, nrm0, down));
		}
		return;
	}
	if (pt >= 11 && pt <= 15) {
		float seed = hash(vec2(fc.z * 17.0, float(pt)));
		float shaft = 1.0 - smoothstep(0.02, 0.07, abs(v));
		if (pt == 14) {
			// the tail: banded dark across, its tip pale; from below paler
			float b = fract(u * tail_bands + 0.04 * sin(v * 5.0 + seed * 9.0));
			float band = smoothstep(1.0 - tail_band_w - 0.05, 1.0 - tail_band_w, b) * (1.0 - smoothstep(0.96, 1.0, b));
			band *= 1.0 - smoothstep(1.0 - tail_tip_w - 0.12, 1.0 - tail_tip_w - 0.06, u) * 0.0;
			vec3 tc = top ? tail_color : mix(tail_color, fl_pale, tail_under);
			c = mix(tc, tail_band, band * (top ? 1.0 : 0.85));
			c = mix(c, tail_tip_r, smoothstep(1.0 - tail_tip_w - 0.02, 1.0 - tail_tip_w, u));
		} else if (pt == 15) {
			c = mix(back_color, tail_cov.rgb, tail_cov.w) * (0.9 + 0.2 * seed);
		} else {
			// a flight feather: from above dark, faintly barred; from below
			// pale, barred dark, its tip dusky
			float b = 1.0 - bars(u, v, fl_bars, 0.45, seed);
			if (top) {
				c = mix(fl_top, fl_top * (1.0 - 0.8 * fl_top_bars), b);
				c = mix(c, back_edge, (1.0 - smoothstep(0.0, 0.05, 1.0 - u)) * 0.5);
			} else {
				c = mix(fl_pale, fl_dark, b * 0.9);
				c = mix(c, fl_dark, smoothstep(0.82, 0.96, u) * (pt == 11 ? 0.7 : 0.3));
			}
			c = mix(c, fl_patch_color * (0.92 + 0.1 * seed), (1.0 - smoothstep(fl_patch - 0.12, fl_patch, u + 0.05 * sin(v * 3.0 + seed * 7.0))) * step(0.01, fl_patch));
		}
		c *= 0.92 + 0.08 * sin(u * 160.0 - abs(v) * 30.0);
		c = mix(c, c * 0.6 + vec3(0.3) * 0.4, shaft * 0.5);
		c = mix(c, down_white, down);
		rough = 0.6;
		spec = 0.3;
		return;
	}
	if (pt == 1) { // the cere, the ring round the eye: bare, yellow
		c = cere_color * (0.9 + 0.1 * vnoise(rest.xy * 3000.0));
		rough = 0.45;
		spec = 0.4;
		return;
	}
	if (pt == 2) { // the bill: blue grey, dark at its hooked tip
		c = mix(mix(cere_color, bill_color, smoothstep(0.0, 0.15, u)), bill_tip, smoothstep(0.35, 0.85, u));
		rough = 0.3;
		spec = 0.5;
		return;
	}
	if (pt == 3) { // the eye: its iris, its pupil, wet
		vec3 rn = normalize(rest_n * vec3(sign(rest.x), 1.0, 1.0));
		if (eye_shut > 0.5) { // (its lid down: feathered)
			c = lid_color;
			rough = 0.8;
			spec = 0.2;
			return;
		}
		float k = dot(rn, normalize(eye_dir));
		if (eye_lid > 0.0) { // (the upper lid over it, feathered, its edge dark)
			float ly = 0.55 - 0.9 * eye_lid;
			float lyy = dot(rn, normalize(cross(normalize(eye_dir), vec3(1.0, 0.0, 0.0)))) * -1.0;
			if (lyy > ly) {
				c = mix(vec3(0.03), lid_color, smoothstep(ly + 0.03, ly + 0.12, lyy));
				rough = 0.8;
				spec = 0.2;
				return;
			}
		}
		c = mix(vec3(0.0), iris, smoothstep(0.84, 0.86, -k + 1.7));
		c = mix(c, vec3(0.005), smoothstep(0.86, 0.9, k));
		c = mix(iris * 0.5, c, smoothstep(0.35, 0.45, k));
		rough = 0.04;
		spec = 0.9;
		return;
	}
	if (pt == 8) { // the legs, the toes: yellow, scaled
		float sc = fract(rest.y * 260.0 + 0.5 * step(0.5, fract(v * 5.0)));
		float line = smoothstep(0.0, 0.15, sc) * smoothstep(0.0, 0.12, fract(v * 5.0));
		c = leg_color * mix(0.7, 1.0, line);
		c = mix(c, down_white, down * 0.4);
		rough = 0.5;
		return;
	}
	if (pt == 9) {
		c = vec3(0.03);
		rough = 0.25;
		spec = 0.6;
	}
}

void fragment() {
	vec3 nrm = NORMAL;
	vec3 view = normalize(VIEW);
	if (dot(nrm, view) < 0.0)
		nrm = -nrm;
	float ndv = clamp(dot(nrm, view), 0.0, 1.0);
	vec3 c = dark;
	float rough = 0.6;
	float metal = 0.0;
	float spec = 0.5;
	float u = fc.x;
	float v = fc.y;
	if (part == 0 || part == 7 || part == 10) {
		// feathers: each a dark vane, a band of metal near its end that
		// turns bronze to copper to green with the light, its edge black
		// (a tom's) or buff (a hen's)
		vec2 p;
		float size = 1.0;
		float region = 0.0; // (0 the body .. 1 the breast and neck: smaller)
		if (part == 0) {
			region = smoothstep(0.0, 0.1, u);
			size = mix(1.0, 0.42, region);
			p = vec2(suv.x, -suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		} else if (part == 7) {
			size = 0.45;
			p = vec2(suv.x, suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		} else {
			size = 0.55;
			p = vec2(suv.x, suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		}
		vec3 f = shingle(p);
		float edge = 1.0 - smoothstep(0.03, 0.1, f.x);
		float band = smoothstep(0.05, 0.14, f.x) * (1.0 - 0.75 * smoothstep(0.55, 0.95, f.x));
		float patch = vnoise(suv * 9.0 + rest.x * 5.0);
		float hue = 0.05 + ndv * 0.7 + f.y * 0.25 + (part == 10 ? 0.15 + v * 0.3 : 0.0) + patch * 0.5;
		vec3 metalc = sheen(hue) * (0.45 + 0.75 * f.y * f.y + 0.3 * patch);
		c = mix(dark, metalc, band * (1.0 - 0.45 * hen));
		c = mix(c, mix(tip_color, vec3(0.6, 0.5, 0.36), hen * (0.4 + 0.6 * region)), edge);
		c *= 0.75 + 0.25 * (1.0 - f.z * f.z); // (its vane darker to its sides)
		metal = band * 0.75 * (1.0 - edge);
		rough = mix(0.62, 0.34, band);
		spec = 0.55;
		float fade = clamp(1.0 - length(fwidth(p)) * 0.9, 0.0, 1.0);
		nrm = bump(nrm, VERTEX, (smoothstep(0.0, 0.5, f.x) * 0.5 + (1.0 - abs(f.z)) * 0.15) * feather_cm * 0.0012 * size * fade * (1.0 + puff), 1.0);
		if (part == 10) {
			// (the greater coverts, the row over the flight feathers: a coppery bar)
			float bar = smoothstep(0.62, 0.72, v);
			c = mix(c, mix(copper, bronze, 0.4) * (0.55 + 0.5 * f.y), bar * band);
		}
		if (down > 0.0) {
			// a poult's down: buff, a dark stripe over its crown and down its back, mottled
			float fluff = vnoise(rest.xz * 900.0) * 0.5 + vnoise(rest.xy * 1700.0) * 0.5;
			float stripe = part == 0 ? (1.0 - smoothstep(0.035, 0.08, abs(v - 0.5))) + 0.8 * (1.0 - smoothstep(0.025, 0.06, abs(abs(v - 0.5) - 0.15))) : 0.0;
			stripe *= part == 0 ? 0.55 + 0.45 * smoothstep(0.6, 1.0, u) + 0.4 * (1.0 - smoothstep(0.0, 0.5, u)) : 1.0;
			stripe = max(stripe, part == 10 ? 0.5 * vnoise(suv * 300.0) : 0.0); // (the wing stubs mottled)
			vec3 dc = mix(down_color * (0.8 + 0.3 * fluff), down_dark, clamp(stripe, 0.0, 1.0) * (0.6 + 0.4 * fluff));
			dc = mix(dc, down_color * 1.12, part == 0 ? 1.0 - smoothstep(0.0, 0.25, v < 0.5 ? v : 1.0 - v) : 0.0);
			c = mix(c, dc, down);
			metal *= 1.0 - down;
			rough = mix(rough, 0.95, down);
			nrm = normalize(mix(nrm, NORMAL, down));
		}
	}
	if (part == 1 || part == 4 || part == 5 || (part == 0 && u > bare_from - 0.04)) {
		// bare skin: warty, wrinkled; red, blue about the face, pale over
		// the crown; its colours up, strutting. Bristles thin on it.
		vec2 q = rest.zy * 520.0 + rest.xx * 300.0;
		vec2 i = floor(q);
		vec2 f2 = fract(q);
		float d1 = 9.0;
		float id = 0.0;
		for (int y = -1; y <= 1; y++)
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 7.7));
			float d = length(g + o - f2);
			if (d < d1) { d1 = d; id = hash(i + g + 2.2); }
		}
		float wart = 1.0 - smoothstep(0.2, 0.62, d1);
		float crown = smoothstep(0.3, 0.9, rest_n.y) * smoothstep(0.84, 0.92, u);
		float face = smoothstep(0.84, 0.92, u) * (1.0 - crown) * smoothstep(-0.7, 0.0, rest_n.y);
		vec3 red = skin_red * (0.75 + 0.35 * id);
		vec3 dull = mix(vec3(0.66, 0.24, 0.27), vec3(0.45, 0.36, 0.55), id * 0.6);
		vec3 skin = mix(dull, red, 0.55 + 0.45 * flush);
		skin = mix(skin, mix(mix(skin_blue, dull, 0.45), skin_blue, flush), face * (0.55 + 0.45 * flush));
		skin = mix(skin, mix(mix(skin_pale, skin_blue, 0.5), skin_pale, flush) , crown * (0.35 + 0.65 * flush));
		// (the neck's caruncles: beads of red on blue-grey)
		float neck = 1.0 - smoothstep(0.6, 0.85, u);
		skin = mix(skin, mix(vec3(0.3, 0.36, 0.5), skin_pale * vec3(0.8, 0.9, 1.0), flush) , neck * (1.0 - wart) * 0.6 * float(part == 0));
		if (part == 5 || part == 4)
			skin = mix(red, mix(red, skin_pale, 0.25), wart * 0.3) * (part == 4 ? mix(0.75, 1.0, flush) : 1.0);
		skin = mix(skin, skin * vec3(0.6, 0.65, 0.75), hen * 0.6);
		float bare = part == 0 ? smoothstep(bare_from - 0.04, bare_from + 0.03, u + 0.03 * (vnoise(rest.xy * 300.0) - 0.5)) : 1.0;
		c = mix(c, skin * (0.8 + 0.25 * wart), bare);
		rough = mix(rough, 0.5, bare);
		metal *= 1.0 - bare;
		nrm = normalize(mix(nrm, bump(normalize(NORMAL * (dot(NORMAL, view) < 0.0 ? -1.0 : 1.0)), VERTEX, wart * 0.0009, 1.0), bare));
		SSS_STRENGTH = 0.3 * bare;
	}
	if (part == 2) {
		c = mix(bill_color * 0.55, bill_color, smoothstep(0.1, 0.8, u));
		rough = 0.35;
	}
	if (part == 3) {
		c = mix(vec3(0.16, 0.08, 0.04), vec3(0.01), smoothstep(0.35, 0.6, ndv));
		rough = 0.06;
		spec = 0.8;
		if (eye_shut > 0.5)
			c = vec3(0.45, 0.42, 0.5);
	}
	if (part == 6) {
		c = mix(vec3(0.02), vec3(0.12, 0.1, 0.07), smoothstep(0.75, 1.0, u) + 0.2 * hash(vec2(fc.z * 31.0, 1.0)));
		rough = 0.45;
	}
	if (part == 8) {
		// scaled legs: plates down the front, pink red
		float sc = fract(rest.y * 85.0 + 0.5 * step(0.5, fract(v * 4.0)));
		float line = smoothstep(0.0, 0.12, sc) * smoothstep(0.0, 0.1, fract(v * 4.0));
		c = leg_color * mix(0.55, 1.0, line) * (0.85 + 0.15 * vnoise(rest.xy * 900.0));
		c = mix(c, down_color * vec3(1.0, 0.8, 0.7), down * 0.6);
		rough = 0.45;
		nrm = bump(nrm, VERTEX, line * 0.0004, 1.0);
	}
	if (part == 9) {
		c = vec3(0.1, 0.08, 0.07);
		rough = 0.3;
	}
	if (part >= 11 && part <= 15) {
		// a flight feather or a tail feather: its shaft, its barbs, its bars
		float seed = hash(vec2(fc.z * 17.0, float(part)));
		float shaft = 1.0 - smoothstep(0.02, 0.07, abs(v));
		float barbs = 0.9 + 0.1 * sin((u * 160.0 - abs(v) * 30.0));
		if (part == 11 || part == 12) {
			// black, barred white (a primary's bars clean; a secondary's
			// browner, its outer edge bronzed)
			float b = bars(u, v, part == 11 ? 11.0 : 9.0, 0.5, seed);
			c = mix(vec3(0.86, 0.84, 0.78), vec3(0.05, 0.045, 0.04), b);
			if (part == 12)
				c = mix(c, mix(bronze, copper, 0.5) * 0.7, smoothstep(0.55, 1.0, u) * 0.6 + smoothstep(0.3, 0.9, -v) * 0.35);
			c = mix(c, vec3(0.35, 0.28, 0.2), hen * 0.25);
		} else if (part == 13) {
			c = mix(dark, sheen(0.3 + ndv + seed * 0.3), 0.6 * smoothstep(0.3, 0.9, u));
			metal = 0.4;
		} else {
			// a tail feather: brown, finely barred dark, a broad black
			// band below its tip, the tip buff (a covert's chestnut)
			float fine = bars(u, v, part == 14 ? 26.0 : 18.0, 0.42, seed);
			vec3 base = tail_brown * (0.8 + 0.4 * vnoise(vec2(u * 30.0, v * 4.0 + seed * 9.0)));
			c = mix(base, vec3(0.05, 0.035, 0.03), (1.0 - fine) * 0.9);
			float wav = 0.012 * sin(v * 7.0 + seed * 6.0);
			float blackb = smoothstep(0.76, 0.8, u + wav) * (1.0 - smoothstep(0.9, 0.925, u + wav));
			c = mix(c, vec3(0.025, 0.02, 0.02), blackb);
			vec3 tipc = part == 14 ? tail_tip : covert_tip;
			c = mix(c, tipc * (0.85 + 0.25 * vnoise(vec2(v * 12.0, seed * 30.0))), smoothstep(0.9, 0.93, u + wav));
			if (part == 15) // (a covert: a sheen of copper below its band)
				c = mix(c, sheen(0.2 + ndv * 0.6) * 0.9, 0.5 * smoothstep(0.45, 0.75, u) * (1.0 - smoothstep(0.76, 0.8, u)));
		}
		c *= barbs;
		c = mix(c, c * 0.5 + vec3(0.25, 0.22, 0.18) * 0.5, shaft * 0.6);
		c = mix(c, down_color, down);
		rough = 0.5;
		spec = 0.4;
		// (cupped across its shaft)
		nrm = normalize(nrm + cross(nrm, vec3(0.0, 0.0, 1.0)) * v * 0.0);
	}
	if (plumage == 1)
		raptor(part, u, v, view, ndv, VERTEX, NORMAL, c, rough, metal, spec, nrm);
	NORMAL = nrm;
	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = spec;
}
