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
#include "res://shaders/render/origin.gdshaderinc"

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
uniform float tail_under = 0.55;
uniform float wash_from = 0.3;     // the breast's wash: from here along it (0 the vent) ...
uniform float wash_to = 0.85;      // ... to here
uniform vec4 throat_color = vec4(0.0); // its throat its own colour (w: how much), from throat_from on up to its chin
uniform float throat_from = 0.72;
uniform float throat_streak = 0.0; // (streaked with the cap's colour: a robin's)
uniform vec4 eye_arcs = vec4(0.0); // white arcs over and under the eye (a robin's broken eye ring): rgb, w its outer radius (m)
uniform vec2 under_spots = vec2(0.12, 0.5); // (pattern 4) a spot's radius (of a feather), and on which feathers (above this of each's random: 0 all)
uniform vec4 cov_spots = vec4(0.0); // a dark spot near the tip of some of the folded wing's coverts (rgb; w: how many of them: a passenger pigeon's black spots)
uniform vec4 patch_color = vec4(0.0); // a patch on its side at the bend of its folded wing (rgb; w: how much): the epaulet seen at rest, a red-winged blackbird's
uniform vec4 patch_edge = vec4(0.0); // its lower border (a blackbird's yellow)
uniform vec3 patch_at = vec3(0.0); // (its middle, the rest pose's: m; x its side's)
uniform vec2 patch_r = vec2(0.012, 0.009); // (its half length along the body, its half height: m)
uniform float cov_lead_to = 0.3; // (how far across the coverts the leading edge's colour reaches)
uniform vec4 cov_lead_edge = vec4(0.0); // a band just below the leading edge's colour (cov_lead): a red-winged blackbird's yellow border to its red epaulet
uniform vec4 supercilium = vec4(0.0); // a pale stripe over the eye, bill to nape (rgb; w: how much: a female blackbird's)
uniform vec4 nape_iris : source_color = vec4(0.4, 0.2, 0.5, 0.0); // the hackles' sheen seen glancing (iridescent: a pigeon's neck)
uniform vec4 tail_outer = vec4(0.0); // the outer tail feathers their own colour (w: how much: a passenger pigeon's white sides)
uniform float tail_count = 12.0;
uniform float eye_rm = 0.005; // the eye's radius (m)
uniform float bill_cere = 1.0; // (the bill's root the cere's colour: a raptor's; a songbird's, a pigeon's, none)
uniform vec4 chin_strap = vec4(0.0); // a pale band from under its chin up each side of its head behind the eye (rgb; w: a Canada goose's white chinstrap)
uniform vec4 strap_at = vec4(-0.02, 0.012, 0.028, 0.024); // (its middle from the eye: down, back; its half height, half length: m)
uniform float iridescence = 0.0; // its back's and crown's feathers glittering metallic, their hue turning with the light (a hummingbird's green)
uniform float gorget = 0.0; // its throat's colour iridescent: blazing where it faces you, near black glancing (a ruby-throat's gorget)
uniform vec3 plume_color : source_color = vec3(0.85, 0.86, 0.88); // its plumes (a heron's breast's, back's)
uniform vec3 plume_dark : source_color = vec3(0.04, 0.04, 0.05); // and those off its head
uniform float mark_from = 0.06; // (its underparts marked from here along it up: below, its vent, plain)
uniform vec2 wing_bar_fl = vec2(-1.0); // (the greater coverts' bar, seen on the folded wing across its flight feathers' bases: from, to along them)
uniform float cap_back = 1.0; // (m behind the eye the cap reaches: a goldfinch's black forecap, short of its crown)
uniform float cap_lore = 0.0; // the cap down in front of the eye to the bill (its lores, its chin's front: a goldfinch's black face)
uniform vec4 wing_bars = vec4(0.0); // the folded wing's coverts tipped pale in two bars across it (rgb; w: how much: a finch's wing bars)
uniform vec2 wing_bar_at = vec2(0.55, 0.86); // (where across the coverts: the median's tips, the greater's)
uniform vec4 fl_edge = vec4(0.0); // its flight feathers fringed pale from above (rgb; w: how much: the tertials the most, a goldfinch's white edges)
uniform vec4 tail_inner = vec4(0.0); // a pale patch on each tail feather's inner web, toward its end (rgb; w: a goldfinch's white tail spots)
uniform vec3 ride_at = vec3(0.0); // (riding a plant that sways: its head, where it is still)
uniform float ride_k = 0.0; // (and the wind's sway there: 0 none)
uniform float vent_to = -1.0; // m along its body (its rest pose's height): below this, its vent, its lower belly, plain (under_color: a robin's white)
uniform float cov_bar = 0.0;       // the upperwing's coverts over the arm, a pale bar: each feather fringed broad and pale, some pale through (a golden eagle's tawny bar)
uniform vec3 cov_bar_color : source_color = vec3(0.68, 0.52, 0.32);
uniform vec4 cov_lead = vec4(0.0); // the wing's leading edge, its small coverts, their own colour (w: how much; a golden eagle's golden)
uniform float under_cov_var = 0.0; // the underwing's coverts: here and there one fringed paler
uniform float fl_trail = 0.3;      // the secondaries from below: a dark band at their ends, how dark
uniform float fl_trail_from = 0.82; // (where along them it begins)
uniform float fl_bar_wave = 0.0;   // the flight feathers' bars irregular, wavering, broken
uniform float fl_bar_to = 1.2;     // and fading out this far along them (an eagle's: on their bases only)
uniform float fl_top_tip = 0.0;    // from above, their ends darker, the bars gone from them
uniform float fl_prim_dark = 0.0;  // the primaries darker than the rest (an eagle's black fingers)   // (its tail from below: this much paler, as its flight feathers; a white tail none)
uniform float hood_u = -1.0;       // (an eagle's) from here along it up, all its head and neck the cap's colour (a bald eagle's white), its edge ragged
uniform vec3 nape_color : source_color = vec3(0.7, 0.5, 0.25);
uniform float nape_u = -1.0;       // from here along it up, its nape and hind neck this colour (a golden eagle's hackles)
uniform float tail_cov_below = 1.0; // (its under tail coverts the same: 0, its belly's colour: a house finch's red rump, whitish beneath)
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
	if (ride_k > 0.0) { // (clinging to a plant's head, swaying with it: the plant's own wind, demo_flower's)
		vec3 w = ride_at + world_origin;
		float ph = dot(w.xz, vec2(0.13, 0.09)) + w.y * 0.05;
		float gust = 0.55 + 0.45 * sin(TIME * 0.31 + dot(w.xz, vec2(0.011, 0.007)));
		vec3 sw = vec3(sin(TIME * 1.3 + ph), 0.25 * sin(TIME * 1.7 + ph * 1.9), cos(TIME * 1.05 + ph * 1.3)) * gust * ride_k;
		v += inverse(mat3(MODEL_MATRIX)) * sw;
	}
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
// its root, hidden), y its own random, z how far across it (-1 .. 1). No
// two alike: the rows wander, each feather its own width, its own length,
// set a little off its place; its tip's edge loose, frayed (its barbs' ends).
vec3 shingle(vec2 p) {
	p += (vec2(vnoise(p * 0.45 + 3.7), vnoise(p * 0.45 + 31.1)) - 0.5) * 0.55; // (the tracts wandering)
	float row = floor(p.y);
	for (int k = 1; k >= 0; k--) {
		float r = row - float(k);
		float x = p.x + 0.5 * mod(r, 2.0) + 0.3 * hash(vec2(r, 3.3));
		float col = floor(x);
		float id = hash(vec2(col, r));
		float fx = (fract(x) * 2.0 - 1.0 + (id - 0.5) * 0.3) / (0.92 + 0.3 * hash(vec2(col + 5.1, r)));
		float fy = p.y - r; // (0 its root .. past 1: its tip, over the next row)
		float len = 0.62 + 0.38 * hash(vec2(col, r + 9.7));
		float fray = (vnoise(vec2(fx * 6.0 + id * 40.0, id * 17.0)) - 0.5) * 0.12 + (vnoise(vec2(fx * 19.0 + id * 9.0, id * 5.0)) - 0.5) * 0.03;
		float reach = 1.0 + (0.85 * sqrt(max(1.0 - fx * fx, 0.0)) + fray) * len;
		if (fy < reach || k == 0)
			return vec3(clamp((reach - fy) / 0.85, 0.0, 1.0), id, clamp(fx, -1.0, 1.0));
	}
	return vec3(1.0, 0.0, 0.0);
}

// A feather's vane seen close: its barbs, fine, slanting out from its shaft
// to its edge (0 .. 1: a soft streaking, no lines).
float barbs_of(vec3 f) {
	vec2 q = vec2((abs(f.z) + f.x * 0.9) * 26.0 + f.y * 50.0, f.x * 2.0 + f.z * 1.5 + f.y * 9.0);
	return vnoise(q) * 0.65 + vnoise(q * vec2(2.3, 1.0) + 5.0) * 0.35;
}

// The feathers' soft shading (c dimmed, nrm turned): each a little shadowed
// toward its root, where the one over it lies; its vane faintly streaked by
// its barbs; its surface a low pillow. Nothing drawn at its edge: the next
// feather's tone is its outline. k: how strong (a feather's size, m).
void feather_shade(vec3 f, float fade, float k, vec3 vtx, inout vec3 c, inout vec3 nrm) {
	c *= 1.0 - 0.14 * smoothstep(0.45, 1.0, f.x) * fade;
	c *= 1.0 + (barbs_of(f) - 0.5) * 0.14 * fade * fade;
	c *= 1.0 - 0.05 * (1.0 - smoothstep(0.0, 0.12, abs(f.z))) * smoothstep(0.1, 0.4, f.x) * fade; // (its shaft, barely)
	float h = smoothstep(0.0, 0.7, f.x) * 0.6 + (1.0 - f.z * f.z) * 0.25;
	float inside = 1.0 - smoothstep(0.03, 0.12, fwidth(f.x) + fwidth(f.z) * 0.5 + fwidth(f.y) * 2.0); // (not across an edge: no ridge there)
	nrm = bump(nrm, vtx, h * k * fade * inside * 0.22, 1.0);
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
		float edge = (1.0 - smoothstep(0.0, 0.34, f.x + 0.1 * (vnoise(p * 4.0 + f.y * 9.0) - 0.5))) * fade * (0.35 + 0.4 * f.y); // (its fringe: soft, broad, more on some than others)
		// the back (over its back, the wing's coverts from above): dark, each
		// feather edged pale, barred darker
		float bf = back_from_hi < 0.0 ? back_from : mix(back_from, back_from_hi, smoothstep(0.3, 0.5, u) * (1.0 - smoothstep(0.78, 0.84, u)));
		float back = pt == 0 ? smoothstep(bf, bf + 0.06, v) * (1.0 - smoothstep(1.0 - bf - 0.06, 1.0 - bf, v)) : (pt == 10 ? mix(1.0, 1.0 - step(0.5, fc.z), smoothstep(0.3, 0.7, wing_open)) : 0.0); // (a wing's coverts: its upper surface the back's colour, its under the underwing's)
		vec3 bk = back_color * (0.88 + 0.24 * f.y);
		float bbar = smoothstep(0.38, 0.44, f.x) * (1.0 - smoothstep(0.52, 0.6, f.x)) * back_bars * fade;
		bk = mix(bk, back_bar, bbar);
		bk = mix(bk, back_edge, edge);
		if (pt == 10 && (cov_bar > 0.0 || cov_lead.w > 0.0)) {
			// the upperwing's coverts: over the arm, short of the wrist, a
			// bar of feathers dark centred, fringed broad and pale, a few
			// pale through; its leading edge its own colour
			float bar = smoothstep(0.04, 0.2, v) * (1.0 - smoothstep(0.62, 0.86, v)) * (1.0 - smoothstep(0.5, 0.72, u)) * cov_bar;
			float fringe = (1.0 - smoothstep(0.08, 0.42, f.x + 0.12 * vnoise(p * 3.0 + f.y * 9.0))) * fade;
			float pale = max(fringe, 0.75 * step(0.66, f.y) * smoothstep(0.0, 0.3, f.x) * (1.0 - smoothstep(0.65, 0.9, f.x)));
			bk *= mix(1.0, 0.72, bar * (1.0 - fringe));
			bk = mix(bk, cov_bar_color * (0.82 + 0.3 * f.y), bar * pale);
			bk = mix(bk, cov_lead.rgb * (0.85 + 0.25 * f.y), cov_lead.w * (1.0 - smoothstep(cov_lead_to - 0.25, cov_lead_to, v + 0.1 * f.y)) * (1.0 - smoothstep(0.7, 0.9, u)));
			bk = mix(bk, cov_lead_edge.rgb * (0.88 + 0.2 * f.y), cov_lead_edge.w * smoothstep(cov_lead_to - 0.08, cov_lead_to, v + 0.1 * f.y) * (1.0 - smoothstep(cov_lead_to + 0.12, cov_lead_to + 0.2, v + 0.1 * f.y)) * (1.0 - smoothstep(0.7, 0.9, u)));
		}
		if (pt == 10 && wing_bars.w > 0.0) { // (two bars: a row of coverts tipped pale, each feather's tip)
			float tipz = smoothstep(0.32, 0.0, f.x + 0.06 * (vnoise(p * 3.0 + f.y * 7.0) - 0.5));
			float rows = max(1.0 - smoothstep(0.05, 0.1, abs(v - wing_bar_at.x)), 1.0 - smoothstep(0.06, 0.11, abs(v - wing_bar_at.y)));
			bk = mix(bk, wing_bars.rgb * (0.92 + 0.12 * f.y), wing_bars.w * max(rows * tipz, rows * 0.35) * (1.0 - smoothstep(0.75, 0.9, u)));
		}
		if (pt == 10 && cov_spots.w > 0.0) { // (a dark spot near a covert's tip, on some of them)
			float sd = length(vec2(f.z * 0.6, f.x - 0.22));
			bk = mix(bk, cov_spots.rgb, step(1.0 - cov_spots.w, f.y) * (1.0 - smoothstep(0.1, 0.15, sd)) * fade * (1.0 - smoothstep(0.75, 0.9, u)));
		}
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
		vec3 un = mix(under_color, breast_wash, smoothstep(wash_from, wash_from + 0.3, u + 0.04 * (vnoise(vec2(v * 12.0, u * 6.0)) - 0.5)) * (1.0 - smoothstep(wash_to - 0.15, wash_to, u)));
		if (vent_to > 0.0)
			un = mix(un, under_color, 1.0 - smoothstep(vent_to - 0.012, vent_to + 0.008, rest.y + 0.006 * (vnoise(rest.xz * 300.0) - 0.5)));
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
			mk = (1.0 - smoothstep(under_spots.x * 0.6, under_spots.x, length(vec2(f.z * 0.5, f.x - 0.3)))) * step(under_spots.y, f.y);
		} else if (under_pattern == 6) { // (a juvenile bald eagle's: white in blotches through the brown, each feather's base pale)
			mk = smoothstep(0.45, 0.65, vnoise(p * 0.55 + 3.1)) * under_blotch * (0.6 + 0.4 * smoothstep(0.2, 0.6, f.x));
		} else if (under_pattern == 5) { // (a screech owl's: a dark streak down each shaft, fine bars across it)
			float st5 = (1.0 - smoothstep(0.07, 0.17, abs(f.z))) * smoothstep(0.08, 0.2, f.x) * (1.0 - smoothstep(0.75, 0.95, f.x));
			float b5 = fract(f.x * 3.5 + 0.15 * abs(f.z));
			mk = max(st5, 0.75 * smoothstep(0.0, 0.08, b5) * (1.0 - smoothstep(0.26, 0.34, b5)) * smoothstep(0.0, 0.3, wc));
		}
		mk *= fade * (1.0 - smoothstep(throat_clean - 0.03, throat_clean + 0.02, u)) * (pt == 0 ? smoothstep(mark_from, mark_from + 0.1, u) : 1.0);
		if (pt == 7)
			mk *= 0.8;
		un = mix(un, under_mark, mk);
		if (pt == 10 && under_cov_var > 0.0) // (the underwing's coverts, here and there one fringed paler)
			un = mix(un, cov_bar_color * 0.8, under_cov_var * step(0.62, f.y) * (1.0 - smoothstep(0.1, 0.4, f.x)) * fade);
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
			float lore = cap_lore * smoothstep(eye_at.z - eye_rm * 0.2, eye_at.z - eye_rm * 1.4, r.z) * smoothstep(eye_at.y - eye_rm * 3.2, eye_at.y - eye_rm * 2.2, r.y);
			float hood = head * clamp(max(above, lore) * (1.0 - smoothstep(eye_at.z + cap_back - 0.002, eye_at.z + cap_back + 0.002, r.z + 0.0015 * (vnoise(vec2(r.x * 900.0, r.y * 900.0)) - 0.5))) + nape + napeb, 0.0, 1.0);
			float mz = r.z - eye_at.z - 0.002;
			float mous = head * malar * smoothstep(eye_at.y - 0.034, eye_at.y - 0.028, r.y) * (1.0 - smoothstep(0.007, 0.012, abs(mz + (eye_at.y - r.y) * 0.18))) * smoothstep(0.004, 0.009, ax);
			c = mix(c, mix(cheek_color, c, 0.25), head * cheek * (1.0 - hood));
			c = mix(c, cap_color * (0.9 + 0.2 * f.y), max(hood, mous));
		}
		if (pt == 0 && nape_u >= 0.0) { // (the hackles: down the back of its head and neck)
			float nap = smoothstep(nape_u, nape_u + 0.1, u) * (1.0 - smoothstep(0.12, 0.24, abs(v - 0.5) + 0.04 * (vnoise(vec2(u * 40.0, v * 9.0)) - 0.5)));
			nap *= mix(1.0, smoothstep(eye_at.z + 0.006, eye_at.z + 0.02, rest.z), smoothstep(0.74, 0.8, u)); // (on its head, behind its eye: its face dark)
			vec3 nc = mix(nape_color, nape_iris.rgb, nape_iris.a * smoothstep(0.75, 0.25, ndv)); // (its sheen: the other colour seen glancing)
			c = mix(c, nc * (0.85 + 0.3 * f.y) * mix(0.7, 1.0, smoothstep(0.0, 0.3, f.x)), nap * smoothstep(0.0, 0.05, f.x + 0.04));
		}
		if (pt == 0 && hood_u >= 0.0) { // (all its head and neck)
			float hd = smoothstep(hood_u - 0.01, hood_u + 0.02, u + 0.03 * (vnoise(vec2(v * 30.0, u * 9.0)) - 0.5) + 0.05 * f.x * (1.0 - f.x));
			c = mix(c, cap_color * (0.93 + 0.1 * f.y), hd);
		}
		if (pt == 0 && throat_color.w > 0.0) { // (its throat, its own: a robin's white, streaked black; a bluebird's rust)
			float frontv = 1.0 - smoothstep(0.12, 0.24, min(v, 1.0 - v));
			float below = u > 0.84 ? 1.0 - smoothstep(eye_at.y - 0.009, eye_at.y - 0.004, rest.y) : 1.0;
			float th = throat_color.w * smoothstep(throat_from, throat_from + 0.03, u) * frontv * below;
			float stripe = throat_streak * (1.0 - smoothstep(0.18, 0.4, abs(fract(v * 34.0 + 0.3 * f.y) - 0.5) * 2.0)) * smoothstep(0.1, 0.3, f.x);
			c = mix(c, mix(throat_color.rgb * (0.94 + 0.1 * f.y), cap_color, stripe), th);
		}
		if (pt == 0 && patch_color.w > 0.0) { // (the epaulet at rest: on its side at the bend of the wing, its lower edge bordered; gone as the wings open)
			vec2 q = vec2((rest.y - patch_at.y) / patch_r.x, (rest.z - patch_at.z) / patch_r.y);
			float side = smoothstep(patch_at.x * 0.55, patch_at.x * 0.8, abs(rest.x));
			float d = length(q) + 0.15 * (vnoise(rest.yz * 600.0) - 0.5);
			float inside = (1.0 - smoothstep(0.85, 1.0, d)) * side * (1.0 - smoothstep(0.08, 0.3, max(wing[0].w, wing[1].w))) * smoothstep(0.0, 0.05, f.x + 0.04);
			float lower = smoothstep(0.15, 0.55, -q.x); // (its lower part: the border)
			c = mix(c, mix(patch_color.rgb, patch_edge.rgb, patch_edge.w * lower) * (0.88 + 0.2 * f.y), patch_color.w * inside);
		}
		if (pt == 0 && supercilium.w > 0.0) { // (a pale stripe over its eye, from its bill back toward its nape)
			vec3 q = rest - vec3(sign(rest.x) * eye_at.x, eye_at.y, eye_at.z);
			float er = eye_rm;
			float line = q.y - er * (1.5 + 0.12 * max(q.z, 0.0) / er); // (a little rising behind the eye)
			float sc = (1.0 - smoothstep(er * 0.3, er * 0.6, abs(line))) * (1.0 - smoothstep(er * 3.0, er * 6.0, q.z)) * smoothstep(-er * 4.5, -er * 3.0, q.z);
			c = mix(c, supercilium.rgb * (0.9 + 0.15 * f.y), supercilium.w * sc * smoothstep(0.78, 0.84, u) * step(0.0, rest_n.x * sign(rest.x) + 0.3));
		}
		if (pt == 0 && eye_arcs.w > 0.0) { // (its broken eye ring: arcs above and below, none fore and aft)
			vec3 q = rest - vec3(sign(rest.x) * eye_at.x, eye_at.y, eye_at.z);
			float r = length(q.yz);
			float ring = smoothstep(eye_arcs.w * 0.55, eye_arcs.w * 0.62, r) * (1.0 - smoothstep(eye_arcs.w * 0.9, eye_arcs.w, r));
			float arc = smoothstep(0.45, 0.7, abs(q.y) / max(r, 1e-5));
			c = mix(c, eye_arcs.rgb, ring * arc * step(abs(eye_at.x) * 0.4, abs(rest.x)) * step(0.0, rest_n.x * sign(rest.x)));
		}
		if (pt == 0 && chin_strap.w > 0.0) { // (the chinstrap: under the chin and up its cheeks behind the eye, never over the crown or the nape)
			vec3 q = rest - eye_at;
			vec2 e = vec2((q.y - strap_at.x) / strap_at.z, (q.z - strap_at.y) / strap_at.w);
			float strap = 1.0 - smoothstep(0.85, 1.05, length(e) + 0.05 * (vnoise(rest.yz * 400.0) - 0.5));
			strap *= smoothstep(0.84, 0.88, u) * (1.0 - smoothstep(eye_at.y - eye_rm * 0.5, eye_at.y + eye_rm * 0.5, rest.y));
			c = mix(c, chin_strap.rgb * (0.95 + 0.06 * f.y), chin_strap.w * strap);
		}
		if (pt == 0 && gorget > 0.0 && throat_color.w > 0.0) { // (its gorget: each feather a tiny mirror, red where it faces you, black aside)
			float frontv = 1.0 - smoothstep(0.26, 0.38, min(v, 1.0 - v)); // (its throat and up its sides)
			float th = smoothstep(throat_from, throat_from + 0.03, u) * frontv * (1.0 - smoothstep(eye_at.y - eye_rm * 2.2, eye_at.y - eye_rm * 1.2, rest.y));
			float glint = smoothstep(0.35, 0.9, ndv) * (0.75 + 0.5 * f.y);
			c = mix(c, mix(vec3(0.03, 0.015, 0.012), throat_color.rgb * 1.25, glint), gorget * th * smoothstep(0.0, 0.25, f.x + 0.1));
			metal = max(metal, 0.5 * gorget * th);
		}
		if (pt == 0 && iridescence > 0.0) { // (its back, its crown: metallic green, golden where the light's caught, blue glancing)
			float back_ = smoothstep(back_from, back_from + 0.06, v) * (1.0 - smoothstep(1.0 - back_from - 0.06, 1.0 - back_from, v));
			float crown = smoothstep(0.78, 0.84, u) * smoothstep(eye_at.y - eye_rm, eye_at.y + eye_rm, rest.y);
			float ir = iridescence * max(back_, crown);
			vec3 hue = mix(vec3(0.1, 0.55, 0.42), vec3(0.62, 0.62, 0.2), smoothstep(0.55, 0.95, ndv));
			hue = mix(vec3(0.05, 0.28, 0.4), hue, smoothstep(0.1, 0.4, ndv));
			c = mix(c, c * 0.5 + hue * (0.55 + 0.35 * f.y), ir * 0.8);
			metal = max(metal, 0.65 * ir);
		}
		rough = 0.72 - 0.35 * max(iridescence, gorget);
		spec = 0.35;
		feather_shade(f, fade, feather_cm * 0.0008, vtx, c, nrm);
		if (down > 0.0) { // an eyas's down: white, woolly
			float fl = vnoise(rest.xz * 1400.0) * 0.4 + vnoise(rest.xy * 2600.0) * 0.35 + vnoise(rest.yz * 5200.0 + vec2(rest.x * 900.0, 0.0)) * 0.25;
			float tuft = vnoise(rest.xy * 260.0 + rest.z * 180.0); // (its down in tufts, wisps between)
			float rim = pow(1.0 - ndv, 2.0); // (fuzz at its edges: lit through)
			c = mix(c, down_white * (0.72 + 0.38 * fl) * mix(0.85, 1.08, tuft) + down_white * rim * 0.28, down);
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
			float tt = abs(fc.z / max(tail_count - 1.0, 1.0) * 2.0 - 1.0);
			tc = mix(tc, tail_outer.rgb, tail_outer.w * smoothstep(0.3, 0.55, tt));
			float side_ = fc.z / max(tail_count - 1.0, 1.0) * 2.0 - 1.0;
			float inner = smoothstep(0.1, 0.3, -v * sign(side_ + 1e-3)) * smoothstep(0.42, 0.55, u) * (1.0 - smoothstep(0.84, 0.92, u)) * smoothstep(0.15, 0.4, abs(side_));
			tc = mix(tc, tail_inner.rgb, tail_inner.w * inner);
			c = mix(tc, tail_band, band * (top ? 1.0 : 0.85));
			c = mix(c, tail_tip_r, smoothstep(1.0 - tail_tip_w - 0.02, 1.0 - tail_tip_w, u));
		} else if (pt == 15) {
			c = (top ? mix(back_color, tail_cov.rgb, tail_cov.w) : mix(under_color, tail_cov.rgb, tail_cov.w * tail_cov_below)) * (0.9 + 0.2 * seed);
		} else {
			// a flight feather: from above dark, faintly barred; from below
			// pale, barred dark, its tip dusky
			float uw = u + fl_bar_wave * (vnoise(vec2(v * 1.5 + seed * 13.0, u * 2.5)) - 0.5) * 0.22;
			float b = 1.0 - bars(uw, v, fl_bars, 0.45 + 0.3 * fl_bar_wave * (vnoise(vec2(u * 3.0, seed * 5.0 + v * 0.6)) - 0.5), seed);
			b *= 1.0 - smoothstep(fl_bar_to - 0.12, fl_bar_to, u + 0.06 * sin(v * 4.0 + seed * 11.0));
			if (top) {
				b *= 1.0 - smoothstep(0.55, 0.75, u) * fl_top_tip;
				c = mix(fl_top, fl_top * (1.0 - 0.8 * fl_top_bars), b);
				c = mix(c, fl_top * 0.55, smoothstep(0.65, 0.9, u) * fl_top_tip);
				c = mix(c, back_edge, (1.0 - smoothstep(0.0, 0.05, 1.0 - u)) * 0.5 * (1.0 - fl_top_tip));
			} else {
				c = mix(fl_pale, fl_dark, b * 0.9);
				c = mix(c, fl_dark, smoothstep(fl_trail_from, fl_trail_from + 0.12, u + 0.03 * sin(v * 5.0 + seed * 9.0)) * (pt == 11 ? 0.7 : fl_trail));
			}
			if (pt == 11)
				c = mix(c, fl_dark * 0.7, fl_prim_dark * smoothstep(0.45, 0.75, u));
			c = mix(c, fl_patch_color * (0.92 + 0.1 * seed), (1.0 - smoothstep(fl_patch - 0.12, fl_patch, u + 0.05 * sin(v * 3.0 + seed * 7.0))) * step(0.01, fl_patch));
			if (top && wing_bars.w > 0.0 && wing_bar_fl.y > 0.0 && pt != 11) { // (the greater coverts' pale tips, lying across them)
				float wv = 0.03 * sin(v * 6.0 + seed * 9.0);
				float wb = smoothstep(wing_bar_fl.x - 0.02, wing_bar_fl.x + 0.01, u + wv) * (1.0 - smoothstep(wing_bar_fl.y - 0.01, wing_bar_fl.y + 0.02, u + wv));
				c = mix(c, wing_bars.rgb * (0.92 + 0.1 * seed), wing_bars.w * wb);
			}
			if (top && fl_edge.w > 0.0) { // (fringed pale: its outer web's edge and round its tip; a tertial's broad)
				float bw = pt == 13 ? 0.42 : (pt == 12 ? 0.22 : 0.12);
				float fr = max(smoothstep(1.0 - bw, 1.0 - bw * 0.5, abs(v)) * step(0.0, v * (pt == 11 ? 1.0 : -1.0) + 0.3), smoothstep(1.0 - bw * 0.25, 1.0, u));
				c = mix(c, fl_edge.rgb * (0.92 + 0.1 * seed), fl_edge.w * fr * (pt == 11 ? 0.6 : 1.0));
			}
		}
		float ff = clamp(1.0 - length(fwidth(vec2(u * 8.0, v * 3.0))) * 0.8, 0.0, 1.0);
		c *= 1.0 + 0.16 * (vnoise(vec2((u * 3.0 - abs(v)) * 60.0 + seed * 30.0, v * 3.0 + seed * 7.0)) - 0.5) * ff; // (its barbs: a soft grain)
		c *= 1.0 + 0.1 * (seed - 0.5); // (no two the same tone)
		c *= mix(0.8, 1.0, smoothstep(-1.0, 0.1, v + 0.25 * (vnoise(vec2(u * 9.0, seed * 20.0)) - 0.5))); // (one vane in its neighbour's shade)
		c = mix(c, c * 1.22 + vec3(0.025), (1.0 - smoothstep(0.0, 0.14, 1.0 - abs(v))) * 0.5 * ff); // (its edge: a fine pale fringe)
		c = mix(c, c * 0.7 + vec3(0.3) * 0.3, shaft * 0.35 * ff);
		c = mix(c, down_white, down);
		rough = 0.82;
		spec = 0.16;
		return;
	}
	if (pt == 6) { // plumes (a heron's): pale, fine; those off the back of its head black
		bool head_ = rest.y > eye_at.y - eye_rm * 3.0;
		c = (head_ ? plume_dark : plume_color) * (0.85 + 0.25 * hash(vec2(fc.z * 13.0, floor(u * 3.0))));
		rough = 0.75;
		spec = 0.25;
		return;
	}
	if (pt == 1) { // the cere, the ring round the eye: bare, yellow
		c = cere_color * (0.9 + 0.1 * vnoise(rest.xy * 3000.0));
		rough = 0.45;
		spec = 0.4;
		return;
	}
	if (pt == 2) { // the bill: blue grey, dark at its hooked tip
		c = mix(mix(mix(bill_color, cere_color, bill_cere), bill_color, smoothstep(0.0, 0.15, u)), bill_tip, smoothstep(0.35, 0.85, u));
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
		float edge = 1.0 - smoothstep(0.0, 0.14, f.x + 0.04 * (vnoise(p * 5.0 + f.y * 9.0) - 0.5));
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
		feather_shade(f, fade, feather_cm * 0.0012 * size * (1.0 + puff), VERTEX, c, nrm);
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
		float barbs = 0.95 + 0.1 * (vnoise(vec2((u * 3.0 - abs(v)) * 60.0 + seed * 30.0, v * 3.0 + seed * 7.0)) - 0.5);
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
