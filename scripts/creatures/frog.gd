class_name Frog
extends Node3D
## A northern leopard frog (Lithobates pipiens), drawn at twice life size
## (its parts modelled at life size, about 80 mm snout to vent: MM). Built
## from parts, posed every frame by hand (procedural: no clips).
##
## The frog: green to brown above, with rows of round dark spots each ringed
## pale; a pale fold (a dorsolateral ridge) down each side of its back; its
## belly white; its snout pointed; big bulging golden eyes, their pupils
## horizontal; the round drum of its ear (the tympanum) behind each eye; its
## hind legs long and folded in a Z under it, the feet long, webbed, its
## forelegs short; a male's thumbs swollen dark (his nuptial pads), and a
## vocal sac each side over the arm, swelling as he calls.
## Its young (Frog.new(true)): a tadpole, dev 0 .. 1 (its development):
## olive brown flecked gold, a round body and a long fin-edged tail, swimming;
## its hind legs growing out at its tail's root, then its forelegs breaking
## through, its tail shrinking away; out of the water a froglet, growing.
##
## What it does (each a method; its own ways when told none):
## - sit(), wander(centre, radius): sat, its throat pulsing (breathing),
##   hopping a little way now and then
## - hop(to): crouch, a leap (its hind legs thrown out straight behind), down
## - swim(to): in the water, its hind legs kicking together, gliding; float():
##   at the surface, only its eyes and snout out
## - hunt(prey) (an insect: a grasshopper nymph, say): turned to it, still,
##   then its tongue flicked out and back, the prey gone, gulped (its eyes
##   pulled down into its head to push it down)
## - croak(): (a male's) his vocal sacs swelling and the snore of his call, in
##   bouts, floating in the shallows
## - flee(from): a leap away and another, into the water if it can
## - mate(her): (a male's) on her back, his forelegs clasped round her
##   behind her arms (amplexus), floating; then she lays (lay()): an egg mass
##   (Eggs: a clump of black-centred jelly spheres) on a stem under the water,
##   him fertilizing it; let go
## - a tadpole: swim about, grazing, its tail beating; metamorphose(): on
##   through its change at once to a froglet
##
## Its world: water_y (the pond's surface), floor_y (its floor), pond
## (centre, half extents x, z), stems (each [foot, tip]); height (the
## ground's y at x, z, outside the pond).
## Steering (pilot.gd): go, go_to, face, stop, act (wander {centre, radius},
## hop {at}, swim {at}, hunt {prey}, call (croak()), flee {from}, mate {partner}, lay,
## metamorphose), behaviours, is_busy, action_finished.
## Its position is set every frame: put it under a node that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const PersonalSpace := preload("res://scripts/creatures/personal_space.gd")
const MM := 0.002 ## m drawn per model mm (twice life size)
const GREEN := Color(0.3, 0.42, 0.19)
const BROWN := Color(0.36, 0.3, 0.2)

var male := false
var young := false ## a tadpole (then a froglet)
var dev := 1.0 ## a tadpole's development: 0 no legs .. 0.5 its hind legs .. 0.75 its forelegs .. 1 a froglet
var size := 1.0
var height: Callable ## (x, z) -> the ground's y (outside the pond)
var water_y := 0.0
var floor_y := -0.2
var pond := [Vector3.ZERO, Vector2(0.5, 0.4)]
var stems: Array = []
var egg_masses: Array[Node3D] = []

var _pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _yaw := 0.0
var _pitch := 0.0
var _t := 0.0
var _st := 0.0
var _wait := 0.0
var _mode := "sit"
var _stage := 0
var _centre := Vector3.ZERO
var _radius := 0.3
var _target := Vector3.ZERO
var _airborne := false
var _crouch := 0.0
var _kick := 0.0 # (a hop's or a stroke's leg thrust, 0 .. 1)
var _sac := 0.0 # (a male's vocal sacs, 0 .. 1)
var _throat := 0.0
var _tongue := 0.0
var _gulp := 0.0
var _prey: Node3D
var _mate: Frog
var _role := ""
var _mate_len := 12.0 # (how long a mating lasts, s)
var _held_by: Frog
var _growing := 0.0
var _pilot: PilotScript
var _piloting := false
var _p_done := false
var rng := RandomNumberGenerator.new()
# the parts
var _body: Node3D
var _skin: ShaderMaterial
var _eyes: Array[Node3D] = []
var _sacs: Array[MeshInstance3D] = []
var _throat_mi: MeshInstance3D
var _tongue_mi: MeshInstance3D
var _hind: Array = [] # [hip node, thigh, shin, foot] each side
var _fore: Array = []
var _tail: Array[Node3D] = []
var _tadpole: Node3D
var _frog: Node3D
var _skin_mats: Array[ShaderMaterial] = []

static var _sphere: SphereMesh
static var _cyl: CylinderMesh
static var _skin_sh: Shader
static var _eye_sh: Shader
static var _limb_m: ArrayMesh
var _body_skin: ShaderMaterial
var _webs: Array[MeshInstance3D] = []
static var _web_m: ArrayMesh


func _init(young_ := false) -> void:
	young = young_
	dev = 0.0 if young_ else 1.0
	size = 0.25 if young_ else 1.0
	rng.randomize()


func _ready() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 16
		_sphere.rings = 8
		_cyl = CylinderMesh.new()
		_cyl.top_radius = 0.5
		_cyl.bottom_radius = 0.5
		_cyl.height = 1.0
		_cyl.radial_segments = 8
		_limb_m = _limb_mesh()
	_body = Node3D.new()
	add_child(_body)
	_build()
	if young:
		_mode = "tadpole"
		_centre = pond[0]


func place(p: Vector3, yaw := 0.0) -> void:
	_pos = p
	if young and dev < 1.0:
		_pos.y = lerpf(floor_y, water_y, 0.5)
	else:
		_pos.y = _ground(p.x, p.z)
	_yaw = yaw
	_place()


# --- its model ----------------------------------------------------------------

func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(at: Vector3, sz: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = sz
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _bone(mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _limb_m # (limbs: rounded, tapering)
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## A limb segment from a to b (its parent's mm), r thick.
static func _seg_to(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	var l := maxf(d.length(), 0.01)
	var z := d / l
	var x := z.cross(Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := z.cross(x)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * r * 1.6, z * (l + r)), (a + b) * 0.5)


## Its skin: green or brown above, its rows of round dark spots each ringed
## pale (in loose rows down its back between the folds, more on its sides,
## fewer on its head); the dorsolateral folds raised, cream bronze, down each
## side of its back; a pale stripe along its upper lip; its ear's drum (the
## tympanum) a brown disc, a pale dot in it; its legs barred dark across,
## yellowish beneath; its belly white, the change soft at its sides; moist
## (a soft sheen, its skin a little granular). (body: its own mesh, painted
## in its mm (VERTEX); a limb's: its bars along its UV.y (bars, the
## MeshInstance's), spots in its frog's space.)
static func _skin_shader() -> Shader:
	if _skin_sh == null:
		_skin_sh = Shader.new()
		_skin_sh.code = """shader_type spatial;
uniform vec3 back : source_color = vec3(0.38, 0.5, 0.24);
uniform vec3 spot : source_color = vec3(0.075, 0.065, 0.04);
uniform vec3 halo : source_color = vec3(0.62, 0.62, 0.4);
uniform vec3 belly : source_color = vec3(0.9, 0.88, 0.8);
uniform float spots = 1.0;
uniform float folds = 1.0; // (its dorsolateral folds: a leopard frog's; none a toad's)
uniform float lip = 1.0; // (its upper lip's pale stripe)
uniform float warts = 0.0; // (its skin warty: a toad's; the warts a little paler, rusty at their tips)
uniform float stripe = 0.0; // (a pale line down the middle of its back)
uniform float belly_spots = 0.0; // (its belly speckled dark: a toad's)
uniform float spot_size = 1.0; // (its spots' size: a toad's bigger, fewer)
uniform sampler2D wart_tex : filter_linear_mipmap, repeat_enable; // (its warts, baked: tools/creatures/bake_toad_warts.py; R height, G the big ones' tips, B each one's tone)
uniform float wart_tile = 24.0; // (mm of its skin a tile)
uniform bool body_space = false; // (its body's own mesh: painted in its mm)
uniform bool tadpole = false;
uniform float seed = 0.0;
uniform mat4 frog_inv; // (its own space: the spots stay on its skin)
instance uniform float bars = 0.0; // (a limb's dark bars across, along it)
varying vec3 wp;
varying vec3 bp;
varying vec3 on;
varying vec3 fn; // (its normal in its own space: the limbs')
float h3(vec3 p) { return fract(sin(dot(p + seed, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	wp = (frog_inv * (MODEL_MATRIX * vec4(VERTEX, 1.0))).xyz;
	bp = VERTEX;
	on = NORMAL;
	fn = mat3(frog_inv * MODEL_MATRIX) * NORMAL;
}
// (nearest and next of scattered points: its warts)
vec2 cells2(vec3 p) {
	vec3 i = floor(p);
	float d1 = 9.0;
	float d2 = 9.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 k = i + vec3(float(x), float(y), float(z));
		float d = length(p - k - vec3(h3(k), h3(k + 1.3), h3(k + 2.7)));
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return vec2(d1, d2);
}
// (its spots on a plane (u, v): in loose rows, oval along v; [spot, halo])
vec2 spotted(vec2 q, vec2 cellsz, float keep) {
	vec2 g = q / cellsz;
	vec2 cell = floor(g);
	float best = 9.0;
	float kept = 0.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) {
		vec2 k = cell + vec2(float(x), float(y));
		float r = h3(vec3(k, 1.7));
		if (r > keep) continue;
		vec2 at = k + vec2(0.3 + 0.4 * h3(vec3(k, 2.3)), 0.25 + 0.5 * h3(vec3(k, 3.1)));
		float d = length((g - at) * cellsz / vec2(1.0, 1.35)) / (0.27 * cellsz.x * (0.75 + 0.5 * h3(vec3(k, 4.4))));
		d += 0.12 * (vn(vec3(q * 1.3, 0.0)) - 0.5); // (their edges not quite round)
		best = min(best, d);
	}
	return vec2(1.0 - smoothstep(0.88, 1.0, best), smoothstep(0.95, 1.03, best) * (1.0 - smoothstep(1.1, 1.2, best)));
}
void fragment() {
	vec3 c = back * (0.9 + 0.2 * vn(bp * 0.25)); // (its ground mottled a little)
	float up;
	float pale = 0.0;
	if (body_space) {
		vec3 n = normalize(on);
		up = n.y;
		vec3 p = bp;
		float ax = abs(p.x);
		// the folds: raised, cream bronze, down each side of its back
		float rx = 9.0 + 1.6 * smoothstep(-14.0, 10.0, p.z) - 0.8 * smoothstep(14.0, 28.0, p.z);
		float fold = (1.0 - smoothstep(0.45, 0.95, abs(ax - rx))) * smoothstep(-15.0, -11.0, p.z) * (1.0 - smoothstep(25.0, 29.0, p.z)) * smoothstep(0.2, 0.5, n.y) * folds;
		// its spots: on its back (from above), on its sides (from the side)
		vec2 top = spotted(vec2(p.x + 50.0, p.z), vec2(6.6, 8.0) * spot_size, p.z < -20.0 ? 0.25 : 0.62);
		vec2 sid = spotted(vec2(p.z + 50.0, p.y + (p.x > 0.0 ? 0.0 : 31.0)), vec2(7.0, 5.6) * spot_size, 0.55);
		float sw = smoothstep(0.35, 0.75, abs(n.x));
		vec2 sp = mix(top, sid, sw) * spots * (1.0 - fold);
		sp *= smoothstep(-0.25, 0.15, n.y); // (none on its belly)
		c = mix(c, mix(c, halo, 0.45), sp.y);
		c = mix(c, spot, sp.x);
		c = mix(c, mix(c, halo * 1.1, 0.7), fold);
		// its upper lip's pale stripe; the dark line from its nostril to its eye
		float lip_s = (1.0 - smoothstep(0.6, 1.2, abs(p.y - 6.4))) * (1.0 - smoothstep(-8.0, -4.0, p.z)) * smoothstep(-35.0, -31.0, p.z) * sw * lip;
		c = mix(c, vec3(0.85, 0.84, 0.7), lip_s * 0.9);
		// (a pale line down the middle of its back)
		c = mix(c, halo * 1.15, stripe * (1.0 - smoothstep(0.5, 1.1, ax)) * smoothstep(-22.0, -16.0, p.z) * (1.0 - smoothstep(24.0, 30.0, p.z)) * smoothstep(0.4, 0.7, n.y));
		float can = (1.0 - smoothstep(0.4, 0.9, abs(p.y - (11.4 + 0.13 * (p.z + 34.0))))) * smoothstep(-35.0, -32.0, p.z) * (1.0 - smoothstep(-24.0, -21.0, p.z)) * sw;
		c = mix(c, spot, can * 0.8);
		// its tympanum: a brown disc behind its eye, a pale dot in it
		float td = length(vec2(p.y - 12.4, p.z + 11.0));
		float tym = (1.0 - smoothstep(3.0, 3.5, td)) * smoothstep(0.6, 0.85, abs(n.x)) * (1.0 - warts * 0.6);
		c = mix(c, mix(vec3(0.34, 0.28, 0.17), vec3(0.62, 0.56, 0.4), 1.0 - smoothstep(0.5, 0.9, td)), tym);
	} else {
		vec3 n = (inverse(VIEW_MATRIX) * vec4(NORMAL, 0.0)).xyz;
		up = n.y;
		if (tadpole) { // (olive brown, flecked gold)
			float fl = step(0.82, vn(wp * 260.0));
			c = mix(c, spot, fl * spots);
		} else if (bars > 0.0) { // (a leg: dark bars across it, pale edged; yellowish beneath)
			float b = abs(fract(UV.y * bars + 0.25) - 0.5);
			float wob = 0.06 * (vn(vec3(UV.x * 6.0, UV.y * 3.0, bars)) - 0.5);
			float bar = (1.0 - smoothstep(0.16, 0.2, b + wob)) * smoothstep(-0.3, 0.2, up); // (across its top, fading beneath)
			c = mix(c, spot * 1.3, bar * spots * 0.9);
			pale = 0.25;
		}
	}
	vec3 bel = mix(belly, vec3(0.86, 0.8, 0.5), pale);
	bel = mix(bel, spot * 2.2, belly_spots * smoothstep(0.62, 0.7, vn(wp * 520.0))); // (speckled)
	c = mix(bel, c, smoothstep(-0.4, 0.05, up));
	// (its warts: rounded, scattered, the big ones on its back; a little paler, rusty at their tips)
	float wh = 0.0;
	if (warts > 0.0) {
		// (the baked tile, laid on its skin from three sides as its surface faces)
		vec3 pm = body_space ? bp : wp * 250.0; // (mm of its own)
		vec3 nm = normalize(body_space ? on : fn);
		vec3 w3 = pow(abs(nm), vec3(4.0));
		w3 /= (w3.x + w3.y + w3.z);
		vec4 t = texture(wart_tex, pm.zy / wart_tile) * w3.x + texture(wart_tex, pm.xz / wart_tile) * w3.y + texture(wart_tex, pm.xy / wart_tile) * w3.z;
		wh = t.r * warts;
		float lit = smoothstep(-0.2, 0.3, up);
		c *= mix(1.0, 0.8 + 0.4 * t.b, warts); // (each wart its own tone)
		c *= mix(1.0, 0.72 + 0.28 * smoothstep(0.02, 0.3, t.r), warts); // (the skin between them darker, creased)
		c = mix(c, c * vec3(1.25, 1.05, 0.8) + vec3(0.05, 0.02, 0.0), wh * lit * 0.5);
		c = mix(c, vec3(0.62, 0.38, 0.2), t.g * warts * lit * 0.6); // (the big ones' tips rusty)
		vec3 dpx = dFdx(VERTEX);
		vec3 dpy = dFdy(VERTEX);
		vec3 r1 = cross(dpy, NORMAL);
		vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		vec3 grad = sign(det) * (dFdx(wh) * r1 + dFdy(wh) * r2);
		float near = 1.0 - smoothstep(0.4, 1.4, length(VERTEX));
		NORMAL = normalize(abs(det) * NORMAL - grad * 1.0 * near);
	}
	ALBEDO = c;
	// (moist: a soft sheen; granular)
	ROUGHNESS = 0.68 - 0.1 * vn(bp * 1.4) + 0.2 * warts; // (moist, not glossy; a toad's skin dry)
	SPECULAR = 0.28;
	CLEARCOAT = 0.04;
	CLEARCOAT_ROUGHNESS = 0.5;
}
"""
	return _skin_sh


## Its body and head: one skin lofted through sections from its snout's tip
## to its vent (mm, x right, y up, z back): the snout pointed, the head
## broad and flat, no neck, widest at its shoulders, the sacral hump over
## its hips, its back sloping down to the vent; each section domed above,
## flat below; the dorsolateral folds raised along its back.
const LEOPARD_BODY := [[-36.0, 0.6, 8.29, 6.4], [-34.5, 3.2, 9.36, 5.4], [-31.0, 6.6, 11.28, 4.4], [-26.0, 10.0, 13.52, 3.2], [-19.0, 12.8, 15.44, 2.2], [-11.0, 14.0, 16.51, 1.2], [-2.0, 14.4, 17.74, 0.2], [7.0, 14.6, 19.41, -0.2], [15.0, 14.0, 21.07, 0.6], [21.0, 12.2, 20.58, 2.0], [26.0, 9.0, 18.28, 4.0], [30.0, 4.6, 15.17, 6.4], [31.6, 0.6, 12.90, 8.6]] # (its back rising from its head to the sacral hump over its hips; its belly round, sagging a little)
static var _body_ms := {} # (sections -> its mesh)


## Its body and head: one skin lofted through sections S [z, half width,
## top, bottom] from its snout's tip to its vent (mm, x right, y up, z
## back); each section domed above, flat below; its dorsolateral folds
## raised along its back (folds).
static func _body_mesh(S: Array = LEOPARD_BODY, folds := true) -> ArrayMesh:
	var key := str(S) + str(folds)
	if _body_ms.has(key):
		return _body_ms[key]
	const AROUND := 40
	const ALONG := 48
	var at := func(z: float) -> Array:
		var j := 0
		while j < S.size() - 2 and z > float(S[j + 1][0]):
			j += 1
		var f := clampf((z - float(S[j][0])) / (float(S[j + 1][0]) - float(S[j][0])), 0.0, 1.0)
		f = f * f * (3.0 - 2.0 * f) * 0.5 + f * 0.5
		var out := []
		for k in 4:
			out.append(lerpf(float(S[j][k]), float(S[j + 1][k]), f))
		return out
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z0 := float(S[0][0])
	var z1 := float(S[S.size() - 1][0])
	for i in ALONG + 1:
		var t := float(i) / ALONG
		var z := lerpf(z0, z1, t)
		var sc: Array = at.call(z)
		var hw: float = sc[1]
		var mid: float = float(sc[3]) + (float(sc[2]) - float(sc[3])) * 0.34 # (widest low: its back domed, its belly flat)
		for k in AROUND:
			var ph := TAU * float(k) / AROUND
			var sn := sin(ph)
			var cs := cos(ph)
			var pw := 2.1 if cs > 0.0 else 2.6 # (its back domed, its belly round under it)
			var x := signf(sn) * pow(absf(sn), 2.0 / pw) * hw
			var hh := (float(sc[2]) - mid) if cs > 0.0 else (mid - float(sc[3]))
			var y := mid + signf(cs) * pow(absf(cs), 2.0 / pw) * hh
			if cs > 0.0 and folds: # (its folds, raised)
				var rx := 9.0 + 1.6 * smoothstep(-14.0, 10.0, z) - 0.8 * smoothstep(14.0, 28.0, z)
				y += 0.9 * exp(-pow((absf(x) - rx) / 1.1, 2.0)) * smoothstep(-15.0, -11.0, z) * (1.0 - smoothstep(25.0, 29.0, z))
			st.set_uv(Vector2(float(k) / AROUND, t))
			st.add_vertex(Vector3(x, y, z))
	for i in ALONG:
		for k in AROUND:
			var a := i * AROUND + k
			var b := i * AROUND + (k + 1) % AROUND
			var c := (i + 1) * AROUND + (k + 1) % AROUND
			var d := (i + 1) * AROUND + k
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(a); st.add_index(c); st.add_index(d)
	st.generate_normals()
	var m := st.commit()
	_body_ms[key] = m
	return m


## The web between a hind foot's toes (its foot's frame: z along it, the
## toes fanned as _pose fans them): most of the way out, its edge scalloped.
static func _web_mesh() -> ArrayMesh:
	if _web_m != null:
		return _web_m
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tips: Array[Vector3] = []
	for k in 5:
		var fan := (float(k) - 2.0) * 0.22
		tips.append(Basis(Vector3.UP, fan) * Vector3(0.0, 0.0, 10.0 + 3.0 * float(2 - absi(k - 2)) + (4.0 if k == 3 else 0.0)))
	for k in 4:
		var a := tips[k] * 0.8
		var b := tips[k + 1] * 0.8
		var m := (tips[k] + tips[k + 1]) * 0.5 * 0.55
		for v: Vector3 in [Vector3.ZERO, a, m, Vector3.ZERO, m, b]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	_web_m = st.commit()
	return _web_m


## A limb's segment (unit: along z from -0.5 to 0.5, 0.5 round): a rounded
## cylinder, a little thicker at its near end (a thigh's muscle), its ends
## closed round; UV.y along it.
static func _limb_mesh() -> ArrayMesh:
	const AROUND := 14
	const ALONG := 14
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ALONG + 1:
		var t := float(i) / ALONG
		var u := t * 2.0 - 1.0
		var r := 0.5 * pow(maxf(1.0 - pow(absf(u), 3.0), 0.0), 1.0 / 3.0) * (1.12 - 0.24 * t)
		for k in AROUND + 1:
			var ph := TAU * float(k) / AROUND
			var n := Vector3(cos(ph), sin(ph), 0.0)
			st.set_uv(Vector2(float(k) / AROUND, t))
			st.add_vertex(Vector3(n.x * r, n.y * r, t - 0.5))
	for i in ALONG:
		for k in AROUND:
			var a := i * (AROUND + 1) + k
			var b := a + 1
			var c := a + AROUND + 2
			var d := a + AROUND + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(a); st.add_index(d); st.add_index(c)
	st.generate_normals()
	return st.commit()


# --- the species' make (a leopard frog's; AmericanToad its own) -----------------

func _sections() -> Array:
	return LEOPARD_BODY


func _has_folds() -> bool:
	return true


## Its skin: its ground (picked from these), spots, halos, and the shader's
## switches (folds, lip, warts, stripe, belly_spots, spot_size).
func _skin_opts() -> Dictionary:
	return {"backs": [GREEN, GREEN, Color(0.36, 0.44, 0.2), BROWN, Color(0.34, 0.36, 0.2)], "folds": 1.0, "lip": 1.0,
		"spot": Color(0.035, 0.03, 0.02), "halo": Color(0.7, 0.66, 0.42)}


func _eye_y() -> float: ## (mm up: its eyes, high on its head)
	return 14.4


func _leg_k() -> float: ## (its legs' length, of a leopard frog's)
	return 1.0


func _leap_max() -> float: ## (m, its longest hop: drawn)
	return 0.45


func _iris() -> Color:
	return Color(0.78, 0.62, 0.24)


func _single_sac() -> bool: ## (a toad's: one, under its chin; a leopard frog's paired, over its arms)
	return false


func _web_k() -> float: ## (how far its hind toes are webbed: a toad's only at their bases)
	return 1.0


func _egg_strings() -> bool: ## (a toad's eggs in long strings; a leopard frog's a clump)
	return false


func _tad_cols() -> Array: ## (its tadpoles': ground, flecks, belly)
	return [Color(0.3, 0.28, 0.16), Color(0.62, 0.55, 0.3), Color(0.78, 0.76, 0.66)]


## (The species' own parts, once it's built: a toad's glands and crests.)
func _build_extra() -> void:
	pass


## Its eye: the iris gold, mottled dark, brighter in a ring round the pupil;
## the pupil a level oval, black, on the side it looks out of.
func _eye_mat(side: float) -> ShaderMaterial:
	if _eye_sh == null:
		_eye_sh = Shader.new()
		_eye_sh.code = """shader_type spatial;
uniform vec3 iris : source_color = vec3(0.78, 0.62, 0.24);
uniform vec3 look = vec3(0.85, 0.25, -0.45);
varying vec3 o;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { o = VERTEX; }
void fragment() {
	vec3 d = normalize(o);
	vec3 l = normalize(look);
	vec3 u = normalize(cross(vec3(0.0, 1.0, 0.0), l)); // (across, level)
	vec3 v = cross(l, u); // (up)
	float fu = dot(d, u);
	float fv = dot(d, v);
	float front = dot(d, l);
	float pupil = (1.0 - smoothstep(0.9, 1.0, length(vec2(fu / 0.36, fv / 0.19)))) * step(0.0, front);
	float r = length(vec2(fu, fv * 1.4));
	vec3 c = iris * (0.75 + 0.4 * vn(o * 40.0)); // (mottled)
	c = mix(c, iris * 0.35, smoothstep(0.55, 0.8, vn(o * 22.0 + 3.0)) * 0.6); // (dark reticulation)
	c = mix(c, iris * 1.35, (1.0 - smoothstep(0.42, 0.52, r)) * step(0.0, front) * 0.6); // (bright round the pupil)
	c *= mix(0.45, 1.0, smoothstep(-0.2, 0.5, front)); // (darker round the back, under its lids)
	c = mix(c, vec3(0.01), pupil);
	ALBEDO = c;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	CLEARCOAT = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _eye_sh
	m.set_shader_parameter("iris", _iris())
	m.set_shader_parameter("look", Vector3(0.85 * side, 0.3, -0.45))
	return m


func _build() -> void:
	_skin = ShaderMaterial.new()
	_skin.shader = _skin_shader()
	_skin_mats.append(_skin)
	var O := _skin_opts()
	var backs: Array = O.backs
	var col: Color = backs[rng.randi() % backs.size()]
	_skin.set_shader_parameter("back", col)
	_body_skin = ShaderMaterial.new()
	_body_skin.shader = _skin_shader()
	_body_skin.set_shader_parameter("back", col)
	_body_skin.set_shader_parameter("body_space", true)
	_body_skin.set_shader_parameter("seed", rng.randf() * 100.0)
	for m: ShaderMaterial in [_skin, _body_skin]:
		for k: String in ["folds", "lip", "warts", "stripe", "belly_spots", "spot_size", "spot", "halo", "belly", "wart_tex", "wart_tile"]:
			if O.has(k):
				m.set_shader_parameter(k, O[k])
	var eye := _mat(Color(0.72, 0.58, 0.22), 0.1)
	eye.clearcoat_enabled = true
	eye.clearcoat = 1.0
	var dark := _mat(Color(0.04, 0.04, 0.03), 0.2)
	# the frog (a tadpole's hidden till it's changed)
	_frog = Node3D.new()
	_body.add_child(_frog)
	var bm := MeshInstance3D.new() # (its body and head: one skin)
	bm.mesh = _body_mesh(_sections(), _has_folds())
	bm.material_override = _body_skin
	_frog.add_child(bm)
	_throat_mi = _part(Vector3(0.0, 2.6, -18.0), Vector3(20.0, 4.0, 16.0), _mat(Color(0.88, 0.86, 0.78), 0.45), _frog)
	for side: float in [-1.0, 1.0]:
		var e := Node3D.new()
		e.position = Vector3(8.6 * side, _eye_y(), -19.0) # (set into its head, bulging from it)
		_frog.add_child(e)
		_part(Vector3.ZERO, Vector3(8.5, 8.0, 9.0), _eye_mat(side), e) # (its iris gold, its pupil level: _eye_mat)
		_part(Vector3(0.2 * side, 2.0, 0.6), Vector3(8.6, 3.0, 8.6), _skin, e) # (its lid, over the eye's top)
		_eyes.append(e)
		if male and not _single_sac():
			var sc := _part(Vector3(14.5 * side, 6.0, -8.0), Vector3(8.0, 8.0, 9.0), _mat(Color(0.5, 0.52, 0.38, 0.85), 0.25), _frog) # (his vocal sac)
			sc.visible = false
			_sacs.append(sc)
	if male and _single_sac(): # (one, under his chin, round as it fills)
		var sc := _part(Vector3(0.0, 2.0, -22.0), Vector3(14.0, 14.0, 14.0), _mat(Color(0.82, 0.8, 0.7, 0.9), 0.2), _frog)
		sc.visible = false
		_sacs.append(sc)
	_tongue_mi = _part(Vector3(0.0, 6.0, -30.0), Vector3(4.0, 2.0, 1.0), _mat(Color(0.85, 0.45, 0.45), 0.3), _frog)
	_tongue_mi.visible = false
	_build_extra()
	# its legs: the hind long, folded in a Z; the fore short
	var foot := _skin
	for side: float in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(11.0 * side, 6.0, 22.0 * lerpf(1.0, _leg_k(), 0.3))
		_frog.add_child(hip)
		var toes: Array = []
		var tm := _mat(col.lerp(Color(0.6, 0.55, 0.4), 0.25), 0.5) # (its toes its own colour, a little paler)
		for k in 5:
			toes.append(_bone(tm, _frog))
		var thigh := _bone(_skin, _frog)
		var shin := _bone(_skin, _frog)
		var ft := _bone(foot, _frog)
		thigh.set_instance_shader_parameter("bars", 3.0) # (its legs barred dark across)
		shin.set_instance_shader_parameter("bars", 3.0)
		ft.set_instance_shader_parameter("bars", 1.0)
		_hind.append([hip, thigh, shin, ft, side, toes])
		var wmi := MeshInstance3D.new() # (the webs between its toes)
		wmi.mesh = _web_mesh()
		var wc := col.lerp(Color(0.6, 0.55, 0.4), 0.2)
		var wm := _mat(Color(wc.r, wc.g, wc.b, 0.8), 0.5)
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		wmi.material_override = wm
		_frog.add_child(wmi)
		wmi.scale = Vector3.ONE * _web_k()
		_webs.append(wmi)
		var sh := Node3D.new()
		sh.position = Vector3(10.0 * side, 4.0, -8.0)
		_frog.add_child(sh)
		var thumb := _bone(_mat(Color(0.12, 0.1, 0.08), 0.5) if male else _skin, _frog)
		var up_ := _bone(_skin, _frog)
		_fore.append([sh, up_, _bone(_skin, _frog), side, thumb])
	# the tadpole
	_tadpole = Node3D.new()
	_body.add_child(_tadpole)
	var tad := ShaderMaterial.new()
	tad.shader = _skin_shader()
	_skin_mats.append(tad)
	var tc := _tad_cols()
	tad.set_shader_parameter("back", tc[0])
	tad.set_shader_parameter("spot", tc[1]) # (gold flecks)
	tad.set_shader_parameter("belly", tc[2])
	tad.set_shader_parameter("spots", 0.6)
	tad.set_shader_parameter("tadpole", true)
	_part(Vector3(0.0, 6.0, -2.0), Vector3(22.0, 17.0, 30.0), tad, _tadpole)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(7.0 * side, 9.0, -12.0), Vector3(4.0, 4.0, 4.0), dark, _tadpole)
	var fin := _mat(Color(0.45, 0.42, 0.3, 0.55), 0.4)
	fin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var prev: Node3D = _tadpole
	var at := Vector3(0.0, 6.0, 11.0)
	for k in 6:
		var n := Node3D.new()
		n.position = at
		prev.add_child(n)
		_tail.append(n)
		var w := 6.0 * (1.0 - float(k) / 7.0) + 1.0
		var mu := _bone(tad, n) # (its muscle: smooth, tapering, each piece overlapping the next)
		mu.transform = Transform3D(Basis.from_scale(Vector3(w * 0.6, w * 0.9, 11.0)), Vector3(0.0, 0.0, 4.0))
		var fi := _bone(fin, n) # (its fins, above and below, one sheet)
		fi.transform = Transform3D(Basis.from_scale(Vector3(0.5, w * 2.6, 11.5)), Vector3(0.0, 0.0, 4.0))
		prev = n
		at = Vector3(0.0, 0.0, 8.0)
	_show_stage()


## (Which body shows: the tadpole's, the frog's, or both as it changes.)
func _show_stage() -> void:
	_tadpole.visible = dev < 0.95
	_frog.visible = dev >= 0.45
	if dev < 0.95:
		var tail_k := clampf((0.95 - dev) / 0.25, 0.0, 1.0) # (its tail shrinking away)
		for n in _tail:
			n.scale = Vector3.ONE * lerpf(0.55, 1.0, tail_k) if dev >= 0.7 else Vector3.ONE
		_tail[0].scale = Vector3(1.0, 1.0, tail_k if dev >= 0.7 else 1.0)
	_frog.scale = Vector3.ONE * clampf((dev - 0.4) / 0.6, 0.2, 1.0)


# --- what it does ---------------------------------------------------------------

func sit() -> void:
	_go_mode("sit")


func wander(centre: Vector3, radius := 0.3) -> void:
	_go_mode("wander")
	_centre = centre
	_radius = radius


func hop(to: Vector3) -> void:
	_go_mode("hop")
	_target = to


func swim(to: Vector3) -> void:
	_go_mode("swim")
	_target = to


func float_up() -> void:
	_go_mode("float")


func hunt(prey: Node3D) -> void:
	if prey == null:
		return
	_go_mode("hunt")
	_prey = prey


func croak() -> void:
	if not male or young:
		return
	_go_mode("call")


func flee(from: Vector3) -> void:
	_go_mode("flee")
	_target = from


## (A tadpole's) on through its change at once: its legs, its tail gone, out.
func metamorphose() -> void:
	if not young or dev >= 1.0:
		return
	_growing = 1.0


func lay() -> void:
	if male or young:
		return
	_go_mode("lay")


func _go_mode(m: String) -> void:
	if young and dev < 1.0 and m not in ["tadpole", "lay"]:
		m = "tadpole"
	_mode = m
	_stage = 0
	_st = 0.0
	_wait = 0.0


func mate(partner: Node3D, secs := 14.0) -> bool:
	if partner == null or not (partner is Frog) or not male or young or _role != "":
		return false
	var her := partner as Frog
	if her.male or her.young or her._role != "":
		return false
	_mate = her
	_role = "male"
	her._mate = self
	her._role = "female"
	her._go_mode("courted")
	_go_mode("mate")
	_mate_len = secs
	return true


func _end_mate() -> void:
	var her := _mate
	_mate = null
	_role = ""
	_held_by = null
	if is_instance_valid(her):
		her._mate = null
		her._role = ""
		her._held_by = null
		her.wander(her._pos, 0.3)
	_airborne = false
	_pos.y = _ground(_pos.x, _pos.z)
	wander(_pos, 0.3)


# --- the motor -------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	_st += dt
	_wait -= dt
	if _pilot:
		_pilot.tick(dt)
	if young and dev < 1.0:
		_grow(dt)
	if is_instance_valid(_held_by):
		_carried()
	elif not _piloting:
		_think(dt)
	_move(dt)
	_place()
	_pose(dt)


## A tadpole growing: its legs coming, its tail going; then out of the water.
func _grow(dt: float) -> void:
	var rate := 1.0 / 150.0 + _growing * 0.25
	dev = minf(dev + rate * dt, 1.0)
	size = lerpf(0.25, 0.45, dev)
	_show_stage()
	if dev >= 1.0:
		_growing = 0.0
		_tadpole.visible = false
		# (out onto the bank: a froglet, growing on)
		var c: Vector3 = pond[0]
		var e: Vector2 = pond[1]
		var a := atan2(_pos.z - c.z, _pos.x - c.x)
		_target = c + Vector3(cos(a) * (e.x + 0.12), 0.0, sin(a) * (e.y + 0.12))
		_mode = "hop"
		_stage = 0


func _in_water(p: Vector3) -> bool:
	var c: Vector3 = pond[0]
	var e: Vector2 = pond[1]
	return absf(p.x - c.x) < e.x and absf(p.z - c.z) < e.y


func _ground(x: float, z: float) -> float:
	if _in_water(Vector3(x, 0.0, z)):
		return water_y - 0.004 # (floating: its back at the surface)
	return float(height.call(x, z)) if height.is_valid() else 0.0


func _think(dt: float) -> void:
	match _mode:
		"tadpole":
			# (swimming about under the water, grazing; its tail beating)
			if _wait <= 0.0 or _pos.distance_to(_target) < 0.02:
				var c: Vector3 = pond[0]
				var e: Vector2 = pond[1]
				_target = Vector3(c.x + rng.randf_range(-e.x, e.x) * 0.85, lerpf(floor_y + 0.01, water_y - 0.02, rng.randf()), c.z + rng.randf_range(-e.y, e.y) * 0.85)
				_wait = rng.randf_range(2.0, 5.0)
				if rng.randf() < 0.3: # (still a while, grazing at the bottom)
					_target = Vector3(_pos.x, floor_y + 0.006, _pos.z)
		"sit", "wander":
			_throat = 0.5 + 0.5 * sin(_t * 9.0)
			if _mode == "wander" and _wait <= 0.0 and not _airborne:
				_wait = rng.randf_range(2.5, 6.0)
				if rng.randf() < 0.55:
					var a := rng.randf() * TAU
					var to := _centre + Vector3(cos(a), 0.0, sin(a)) * _radius * rng.randf()
					_leap(to)
		"hop":
			if _stage == 0 and not _airborne:
				_leap(_target)
				_stage = 1
			elif _stage == 1 and not _airborne:
				wander(_pos, 0.25)
		"swim":
			if _pos.distance_to(Vector3(_target.x, _pos.y, _target.z)) < 0.02:
				float_up()
		"float":
			_throat = 0.5 + 0.5 * sin(_t * 7.0)
			if _st > 10.0:
				wander(_pos, 0.25)
		"hunt":
			if not is_instance_valid(_prey):
				wander(_pos, 0.25)
				return
			var d := Vector3(_prey.position.x - _pos.x, 0.0, _prey.position.z - _pos.z)
			_face(d)
			var reach := 0.06 * size
			if d.length() > reach * 1.6 and _stage == 0 and not _airborne:
				_leap(_prey.position - d.normalized() * reach) # (nearer)
			elif d.length() <= reach * 1.6 and _stage == 0 and not _airborne:
				_stage = 1
				_st = 0.0
			elif _stage == 1: # (the tongue out and back)
				_tongue = sin(clampf(_st / 0.18, 0.0, 1.0) * PI)
				if _st > 0.09 and is_instance_valid(_prey):
					_prey.queue_free()
					_prey = null
					_stage = 2
					_st = 0.0
		"call":
			_float_at(_pos)
			var bout := fmod(_st, 5.0)
			_sac = (0.5 + 0.5 * sin(_t * 26.0)) if bout < 2.2 else move_toward(_sac, 0.0, dt * 4.0)
			if _st > 20.0:
				_sac = 0.0
				wander(_pos, 0.25)
		"flee":
			if not _airborne:
				if _stage < 2:
					var away := Vector3(_pos.x - _target.x, 0.0, _pos.z - _target.z).normalized()
					var to := _pos + away * 0.25 * size
					if not _in_water(_pos): # (for the water, if it's near)
						var c: Vector3 = pond[0]
						if c.distance_to(_pos) < 1.0:
							to = _pos + (c - _pos).normalized() * 0.3
					_leap(to)
					_stage += 1
				else:
					wander(_pos, 0.3)
		"courted":
			_float_at(_pos)
		"mate":
			_mate_think(dt)
		"lay":
			_lay_think(dt)
	if _mode == "hunt" and _stage == 2:
		_gulp = sin(clampf(_st / 0.4, 0.0, 1.0) * PI)
		if _st > 0.6:
			_gulp = 0.0
			wander(_pos, 0.25)


func _float_at(_p: Vector3) -> void:
	if not _in_water(_pos):
		var c: Vector3 = pond[0]
		_target = c + (_pos - c) * 0.5
		if not _airborne:
			_leap(Vector3(_target.x, water_y, _target.z))


func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	match _stage:
		0: # (to her: hops and strokes)
			if not _airborne:
				var d := her._pos - _pos
				d.y = 0.0
				if d.length() < 0.05 * size:
					_held_by_set(her)
					_stage = 1
					_st = 0.0
				else:
					_leap(her._pos - d.normalized() * 0.03 * size)
		1: # (amplexus: on her back, clasped; she swims on, then lays)
			if _st > 4.0 and her._mode != "lay":
				her.lay()
			if _st > _mate_len and her._mode != "lay":
				_end_mate()


func _held_by_set(her: Frog) -> void:
	_airborne = false
	_role = "male"
	her._role = "female"
	her._mode = "courted"
	_mode = "mate"
	_held_by = her # (he's carried on her: her back, his forelegs round her)


## (His) carried on her back, clasped behind her arms.
func _carried() -> void:
	var her := _held_by
	var hb := Basis.from_euler(Vector3(her._pitch, her._yaw, 0.0))
	_yaw = her._yaw
	_pitch = her._pitch + 0.15
	_pos = her._pos + hb * (Vector3(0.0, 13.0, 4.0) * MM * her.size)
	_crouch = 0.6
	if _role == "male":
		_mate_think(0.0)


func _lay_think(_dt: float) -> void:
	match _stage:
		0: # (into the water, to a stem)
			var foot: Vector3 = stems[rng.randi() % stems.size()][0] if not stems.is_empty() else pond[0]
			_target = Vector3(foot.x, water_y, foot.z)
			_stage = 1
		1:
			if not _in_water(_pos) and not _airborne:
				_leap(Vector3(_target.x, water_y, _target.z))
			elif _in_water(_pos):
				var d := Vector3(_target.x - _pos.x, 0.0, _target.z - _pos.z)
				if d.length() < 0.03:
					_stage = 2
					_st = 0.0
		2: # (still, her body pumping; the mass coming out, him over her)
			_throat = 0.5 + 0.5 * sin(_t * 4.0)
			if _st > 4.0:
				var e := Eggs.new()
				e.strings = _egg_strings()
				e.maker = get_script()
				e.at = Vector3(_pos.x, lerpf(water_y, floor_y, 0.35), _pos.z + 0.03)
				e.frog = self
				get_parent().add_child(e)
				egg_masses.append(e)
				_stage = 3
				_st = 0.0
		3:
			if _st > 1.0:
				if is_instance_valid(_mate):
					_mate._end_mate()
				wander(_pos, 0.3)


## A leap to `to` (its ballistic arc): crouched first, then thrown out.
func _leap(to: Vector3) -> void:
	var d := Vector3(to.x - _pos.x, 0.0, to.z - _pos.z)
	if d.length() < 0.005:
		return
	var dist := minf(d.length(), _leap_max() * size + 0.05) # (as far as it can)
	d = d.normalized()
	# (coming down clear of the others: not on a snake's back, a turtle's shell)
	var land := PersonalSpace.clear_spot(self, _pos + d * dist)
	var dl := Vector3(land.x - _pos.x, 0.0, land.z - _pos.z)
	if dl.length() > 0.005:
		dist = minf(dl.length(), _leap_max() * size + 0.05)
		d = dl.normalized()
	_face(d * 10.0)
	var t := 0.18 + dist * 0.6
	_vel = d * dist / t + Vector3.UP * 9.8 * t * 0.5
	_airborne = true
	_kick = 1.0


func _face(d: Vector3) -> void:
	if Vector2(d.x, d.z).length() > 0.002:
		_yaw = atan2(-d.x, -d.z)


func _move(dt: float) -> void:
	if young and dev < 1.0: # (a tadpole: swimming, its tail driving it)
		var to := _target - _pos
		var want := to.normalized() * 0.06 * clampf(to.length() / 0.04, 0.0, 1.0)
		_vel = _vel.lerp(want, 1.0 - exp(-2.0 * dt))
		_pos += _vel * dt
		_pos.y = clampf(_pos.y, floor_y + 0.005, water_y - 0.006)
		if Vector2(_vel.x, _vel.z).length() > 0.005:
			var y := atan2(-_vel.x, -_vel.z)
			_yaw += clampf(wrapf(y - _yaw, -PI, PI), -3.0 * dt, 3.0 * dt)
		return
	if _airborne:
		_vel.y -= 9.8 * dt
		_pos += _vel * dt
		var g := _ground(_pos.x, _pos.z)
		if _pos.y <= g and _vel.y < 0.0:
			_pos.y = g
			_vel = Vector3.ZERO
			_airborne = false
			_kick = 0.0
		_pitch = clampf(-_vel.y * 0.15, -0.5, 0.5)
		return
	_pitch = lerpf(_pitch, 0.0, 1.0 - exp(-6.0 * dt))
	if _mode == "swim" and _in_water(_pos):
		var to := Vector3(_target.x - _pos.x, 0.0, _target.z - _pos.z)
		var stroke := fmod(_st, 0.8) < 0.25
		_kick = 1.0 if stroke else move_toward(_kick, 0.0, dt * 3.0)
		_face(to)
		_pos += to.normalized() * (0.18 if stroke else 0.05) * dt * size * 2.0
	PersonalSpace.keep_apart(self)
	_pos.y = _ground(_pos.x, _pos.z)


func _enter_tree() -> void:
	PersonalSpace.join(self)


func _exit_tree() -> void:
	PersonalSpace.leave(self)


## (May it touch another: a tadpole, in the air, in amplexus, laying; a
## male calling, floating among the others.)
func _touch_ok() -> bool:
	return young or _airborne or _role != "" or is_instance_valid(_held_by) or _mode in ["courted", "mate", "lay", "call", "float"] # (hunting: only it and its _prey: PersonalSpace)


# --- the pose -------------------------------------------------------------------

func _place() -> void:
	transform = Transform3D(Basis.from_euler(Vector3(_pitch, _yaw, 0.0)), _pos)
	if _body:
		_body.scale = Vector3.ONE * MM * size
		var inv := (global_transform if is_inside_tree() else transform).affine_inverse()
		inv = Transform3D(inv.basis / (size * 0.5), inv.origin / (size * 0.5)) # (its size grown out of it: the spots keep theirs)
		for m: ShaderMaterial in _skin_mats:
			m.set_shader_parameter("frog_inv", Projection(inv))


func _pose(dt: float) -> void:
	# (the tadpole's tail beating)
	if _tadpole.visible:
		var spd := clampf(_vel.length() / 0.04, 0.2, 1.0)
		for k in _tail.size():
			_tail[k].rotation.y = sin(_t * 12.0 - k * 0.9) * 0.35 * spd * (0.4 + k * 0.12)
	if not _frog.visible:
		return
	_crouch = move_toward(_crouch, 1.0 if _airborne else (0.6 if _mode == "float" or _mode == "call" else 0.0), dt * 6.0)
	var ext := _kick if _airborne else 0.0 # (its hind legs thrown out straight)
	_kick = move_toward(_kick, 0.0, dt * 2.0)
	var lk := _leg_k()
	var wet := _in_water(_pos) and not _airborne and not (young and dev < 1.0)
	var swimming := wet and _mode == "swim"
	var floating := wet and not swimming and _role != "male"
	# (swimming: the stroke, as _move drives it: a kick, both legs thrust back
	# together; a glide, legs straight behind, together; then drawn up again,
	# knees out, feet turned out, ready)
	var sp := fmod(_st, 0.8) / 0.8
	var stroke := smoothstep(0.0, 0.3, sp) * (1.0 - smoothstep(0.62, 1.0, sp))
	# its hind legs: folded in a Z under it, out straight behind, or swimming
	for L: Array in _hind:
		var side: float = L[4]
		var hip: Vector3 = (L[0] as Node3D).position
		# (sitting: the thigh forward and out along its side, the shin folded
		# back outside it and lower, beside it, not inside it; the foot forward
		# again under the shin, outside both)
		var sit_k := Vector3(11.0 * side, -3.5, -9.0)
		var sit_a := Vector3(20.0 * side, -5.5, 11.0)
		var sit_t := Vector3(17.0 * side, -6.5, -13.0)
		var out_k := Vector3(10.0 * side, -2.0, 18.0)
		var out_a := Vector3(12.0 * side, -3.0, 44.0)
		var out_t := Vector3(14.0 * side, -4.0, 72.0)
		var k_: Vector3 = out_k.lerp(sit_k, 1.0 - ext)
		var a_: Vector3 = out_a.lerp(sit_a, 1.0 - ext)
		var t_: Vector3 = out_t.lerp(sit_t, 1.0 - ext)
		if swimming:
			var rec_k := Vector3(18.0 * side, -1.0, 4.0) # (drawn up: knees out wide, feet out)
			var rec_a := Vector3(12.0 * side, -1.0, 22.0)
			var rec_t := Vector3(26.0 * side, -1.5, 16.0)
			var glide := Vector3(-3.0 * side, -1.0, 0.0) * stroke # (together, behind)
			k_ = rec_k.lerp(out_k * Vector3(0.8, 1.0, 1.0), stroke)
			a_ = rec_a.lerp(out_a * Vector3(0.45, 1.0, 1.04), stroke) + glide
			t_ = rec_t.lerp(out_t * Vector3(0.25, 1.0, 1.06), stroke) + glide
		elif floating: # (at rest in the water: legs spread out behind, splayed, a little bent)
			k_ = Vector3(16.0 * side, -3.0, 10.0)
			a_ = Vector3(20.0 * side, -5.0, 30.0)
			t_ = Vector3(28.0 * side, -6.0, 46.0)
		var knee := hip + k_ * lk
		var ankle := hip + a_ * lk
		var toe := hip + t_ * lk
		_seg_to(L[1], hip, knee, 5.3)
		_seg_to(L[2], knee, ankle, 3.6)
		_seg_to(L[3], ankle, toe, 2.4)
		var toes: Array = L[5]
		for k in toes.size(): # (long toes, webbed: fanned out from the foot's end)
			var fan := (float(k) - 2.0) * 0.22
			var dirv := (toe - ankle).normalized()
			var t2 := toe + Basis(Vector3.UP, fan) * dirv * (10.0 + 3.0 * float(2 - absi(k - 2)) + (4.0 if k == 3 else 0.0))
			_seg_to(toes[k], toe, t2, 1.1)
		var fz := (toe - ankle).normalized() # (its web: along the foot, fanned with its toes)
		var fx := Vector3.UP.cross(fz).normalized() if absf(fz.y) < 0.98 else Vector3.RIGHT
		_webs[_hind.find(L)].transform = Transform3D(Basis(fx, fz.cross(fx), fz).scaled(Vector3.ONE * _web_k()), toe)
	for L: Array in _fore:
		var side: float = L[3]
		var sh: Vector3 = (L[0] as Node3D).position
		var clasp := _role == "male" and is_instance_valid(_held_by)
		var elbow := sh + (Vector3(8.0 * side, -4.0, 4.0) if not clasp else Vector3(6.0 * side, -6.0, -6.0))
		var hand := elbow + (Vector3(-1.0 * side, -6.0, -8.0) if not clasp else Vector3(-8.0 * side, -6.0, -8.0))
		if swimming: # (laid back along its sides, out of the way)
			elbow = sh + Vector3(5.0 * side, -1.5, 6.0)
			hand = elbow + Vector3(1.0 * side, -1.0, 10.0)
		elif floating and not clasp: # (out a little before it, holding it level)
			elbow = sh + Vector3(9.0 * side, -3.0, -2.0)
			hand = elbow + Vector3(4.0 * side, -3.0, -6.0)
		_seg_to(L[1], sh, elbow, 2.3)
		_seg_to(L[2], elbow, hand, 2.4)
		_seg_to(L[4], hand, hand + Vector3(-2.0 * side, -1.0, -3.0), 1.6)
	_body.rotation.x = lerpf(0.25, -0.1, _crouch) * (0.0 if wet else 1.0) # (sat up on its forelegs, or flat in the water)
	_throat_mi.scale = Vector3(22.0, 6.0 + 2.5 * _throat, 18.0)
	for e in _eyes:
		e.position.y = _eye_y() - 4.0 * _gulp # (pulled down to push its prey down)
	for k in _sacs.size():
		_sacs[k].visible = _sac > 0.02
		_sacs[k].scale = (Vector3(14.0, 11.0, 14.0) * lerpf(0.3, 1.9, _sac)) if _single_sac() else (Vector3(8.0, 8.0, 9.0) * lerpf(0.3, 1.25, _sac))
	if not (_mode == "hunt" and _stage == 1):
		_tongue = move_toward(_tongue, 0.0, dt * 8.0) # (back in)
	_tongue_mi.visible = _tongue > 0.02
	_tongue_mi.scale = Vector3(4.0, 2.0, 1.0 + 110.0 * _tongue)
	_tongue_mi.position = Vector3(0.0, 6.0, -30.0 - 55.0 * _tongue)


# --- steering (pilot.gd) -------------------------------------------------------

func _pl() -> PilotScript:
	if _pilot == null:
		_pilot = PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _p_steer(point: Vector3, _speed: float) -> void:
	_piloting = true
	if young and dev < 1.0:
		_target = point
		return
	if not _airborne:
		_leap(point)


func _p_hold() -> void:
	_piloting = true


func _p_mobile() -> bool:
	return _role != "male" or not is_instance_valid(_held_by)


func _p_speed() -> float:
	return 0.3


func _p_reach() -> float:
	return 0.04


func _p_behaviours() -> PackedStringArray:
	if young and dev < 1.0:
		return PackedStringArray(["metamorphose"])
	var b := PackedStringArray(["wander", "hop", "swim", "hunt", "flee"])
	if male:
		b.append_array(PackedStringArray(["call", "mate"]))
	else:
		b.append("lay")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	_piloting = false
	match name:
		"wander":
			wander(args.get("centre", _pos), float(args.get("radius", 0.3)))
		"hop":
			hop(args.get("at", _pos + _p_heading() * 0.2))
		"swim":
			swim(args.get("at", pond[0]))
		"hunt":
			if args.get("prey") == null:
				return false
			hunt(args.prey)
		"call":
			croak()
		"flee":
			flee(args.get("from", _pos + Vector3.FORWARD))
		"mate":
			return mate(args.get("partner"), float(args.get("seconds", 14.0)))
		"lay":
			lay()
		"metamorphose":
			metamorphose()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"hop", "flee":
			return not _airborne and _mode == "wander"
		"hunt":
			return _mode != "hunt"
		"mate":
			return _role == ""
		"lay":
			return _mode != "lay"
		"metamorphose":
			return dev >= 1.0
	return false


func _p_act_secs(name: String) -> float:
	match name:
		"wander", "call":
			return 15.0
	return -1.0


# --- props -------------------------------------------------------------------------

## An egg mass: a clump of jelly, each egg black above and pale below in its
## own clear sphere, on a stem under the water; hatch() (or a while after)
## the tadpoles out of it.
class Eggs extends Node3D:
	var maker: Script
	var frog: Node3D
	var at := Vector3.ZERO
	var strings := false ## (a toad's: two long strings, tangled in the weed, not a clump)
	var left := 60.0
	var _done := false

	func _ready() -> void:
		position = at # (where it is: its parts about it)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		var jm := StandardMaterial3D.new()
		jm.albedo_color = Color(0.75, 0.82, 0.72, 0.35)
		jm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		jm.roughness = 0.05
		var em := StandardMaterial3D.new()
		em.albedo_color = Color(0.06, 0.05, 0.04)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		if strings: # (two strands of jelly, each a row of black eggs, wandering over the bottom)
			for sd: float in [-1.0, 1.0]:
				var p := Vector3(sd * 0.006, 0.0, 0.0)
				var a := rng.randf() * TAU
				for k in 70:
					a += rng.randf_range(-0.35, 0.35)
					var q := p + Vector3(cos(a), 0.0, sin(a)) * 0.006 + Vector3(0.0, rng.randf_range(-0.001, 0.001), 0.0)
					var tube := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.0035
					cm.bottom_radius = 0.0035
					cm.height = 0.0065
					cm.radial_segments = 6
					tube.mesh = cm
					tube.material_override = jm
					tube.position = (p + q) * 0.5
					tube.basis = Basis.looking_at(q - p, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
					add_child(tube)
					var e := MeshInstance3D.new()
					e.mesh = s
					e.material_override = em
					e.scale = Vector3.ONE * 0.0026
					e.position = q
					add_child(e)
					p = q
			return
		for k in 60:
			var p := at + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.7, 0.7), rng.randf_range(-1, 1)).limit_length(1.0) * 0.03
			var j := MeshInstance3D.new()
			j.mesh = s
			j.material_override = jm
			j.scale = Vector3.ONE * 0.008
			j.position = p - at
			add_child(j)
			var e := MeshInstance3D.new()
			e.mesh = s
			e.material_override = em
			e.scale = Vector3.ONE * 0.0032
			e.position = p - at
			add_child(e)

	func _process(dt: float) -> void:
		left -= dt
		if left <= 0.0 and not _done:
			hatch()

	func hatch(n := 5) -> void:
		if _done or maker == null:
			return
		_done = true
		var f := frog as Frog
		for k in n:
			var ny: Node3D = maker.new(true)
			if is_instance_valid(f):
				for p in ["water_y", "floor_y", "pond", "stems", "height"]:
					ny.set(p, f.get(p))
			get_parent().add_child(ny)
			ny.call("place", at + Vector3(randf_range(-0.04, 0.04), 0.0, randf_range(-0.04, 0.04)), randf() * TAU)
		queue_free()
