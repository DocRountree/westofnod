class_name Isopod
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A pill bug (Armadillidium vulgare), drawn at twice life size (about 30
## mm long): an oval, high domed, its tail end round, a light slate grey,
## glossy, mottled with pale
## spots; its back plates overlapping, head to tail: the head (its eyes,
## its long bent antennae feeling the ground ahead), seven big plates over
## the body, five small ones narrowing round to its tail, the telson's half
## disc and its little
## uropods; seven pairs of short legs under it, walked in two alternating
## sets down the body. Young (mancae: Isopod.new(true)): small, pale, only
## six pairs of legs; growing. Not yet in the game
## (tools/creatures/ecology_demo.tscn).
##
## - wander(centre, radius): trundling about, its antennae tapping
## - eat(at): at the leaf litter there, head down, its mouthparts working
## - roll(seconds): rolled up into a ball (its plates curling down and
##   under from its middle, the legs and head tucked in), then open again
## - lay(): the female's brood pouch under her front filling, swelling with
##   eggs (pill bugs carry their eggs: no laying them out)
## - hatch(): the young out of the pouch, walking out from under her
## - mate(her) (a male's: male set before it's added; as she is, but no
##   pouch): he climbs onto her back from behind, then leans over to one
##   side of her, his tail bent down under her edge, then to the other;
##   and off again
## Steering (pilot.gd): act eat {at, seconds}, roll {seconds}, lay, mate.

const SEGS := 14 # head, 7 pereon plates, 5 pleon plates, the telson
const LEN := 15.0 # mm, head to tail

var young := false
var mancae: Array[Node3D] = [] ## its young, out of its pouch
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.1
var _wait := 0.0
var _st := 0.0
var _at := Vector3.ZERO
var _ball := 0.0 # 0 open .. 1 rolled up into a ball
var _ball_to := 0.0
var _chew := 0.0
var _brood := 0.0 # 0 .. 1: the pouch's eggs
var _plates: Array[Node3D] = [] # the chain's joints (front ones, then back)
var _seg_z: Array[float] = []
var _head: Node3D
var _antennae: Array[Node3D] = []
var _pouch: MeshInstance3D
var _eggs: Array[MeshInstance3D] = []
var _hatching := 0


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.16 if young_ else 1.0)
	body_h = 2.1
	walk_speed = 0.02
	stride = 3.0
	step_time = 0.12
	var pairs := 6 if young_ else 7
	var L := []
	var gr := [[], []]
	for p in pairs:
		var z := -4.2 + p * 1.25
		L.append({"hip": Vector3(2.3, -1.0, z), "f": 1.9, "t": 2.0, "s": 1.3, "home": Vector2(4.3, z + 0.2),
				"dangle": Vector3(1.6, -1.6, z), "pole": Vector3(0.7, 1.0, 0.0), "r": 0.22})
		gr[p % 2].append(p * 2)
		gr[(p + 1) % 2].append(p * 2 + 1)
	legs = L
	tripod = gr


func _build() -> void:
	var grey := Color(0.6, 0.61, 0.62) if not young else Color(0.78, 0.76, 0.73) # (a slate grey, a tad darker)
	var plate := _banded(grey, 0.0, 0.0, 0.35, 0.75) # (the uropods, the face)
	var under := _mat(grey.darkened(0.3), 0.6)
	# the plates, a chain from the middle out both ways (each on the next
	# toward the middle: they curl round it to roll up)
	var mid := 5 # (the fifth plate, the body's middle: the chain's root)
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.0, _plate_z(mid))
	_body.add_child(root)
	_seg_z.resize(SEGS)
	var nodes: Array = []
	nodes.resize(SEGS)
	nodes[mid] = root
	for k in range(mid - 1, -1, -1):
		var n := Node3D.new()
		n.position = Vector3(0.0, 0.0, _plate_z(k) - _plate_z(k + 1))
		(nodes[k + 1] as Node3D).add_child(n)
		n.set_meta("dir", -1.0)
		nodes[k] = n
	for k in range(mid + 1, SEGS):
		var n := Node3D.new()
		n.position = Vector3(0.0, 0.0, _plate_z(k) - _plate_z(k - 1))
		(nodes[k - 1] as Node3D).add_child(n)
		n.set_meta("dir", 1.0)
		nodes[k] = n
	for k in SEGS:
		var nd: Node3D = nodes[k]
		var w := _plate_w(k)
		var l := _plate_len(k)
		# a plate: a band arched over the back and down the sides, its
		# edges flared, its front tucked under the one ahead, its back a
		# rim lapping the next; spotted (_band)
		var band := MeshInstance3D.new()
		# (the tail's plates sloping down to its rounded end, the last
		# curling right down over it: a smooth half dome behind)
		var u := clampf(float(k - 8) / 5.0, 0.0, 1.0)
		var hh := w * (0.5 if k > 0 else 0.42) * (1.0 - 0.3 * u * u)
		band.mesh = _arch(w * 0.5, hh, l * (1.5 if k < 13 else 1.4), lerpf(1.75, 2.05, u))
		band.material_override = _band_mat(grey, w * 0.5, l * 1.5, not young and k > 0 and k < 8)
		nd.add_child(band)
		if k > 0 and k < 8:
			_part(Vector3(0.0, -0.6, 0.0), Vector3(w * 0.8, 0.8, l * 1.2), under, nd) # (its underside)
		if k != mid:
			_plates.append(nd)
	# the head (on the first plate): its rounded front, the eyes (black,
	# clustered), the small first antennae, the long second ones bent at
	# their elbow, their flagella in two
	_head = nodes[0]
	_part(Vector3(0.0, -0.4, -1.0), Vector3(3.6, 1.8, 1.6), plate, _head)
	var eye := _mat(Color(0.04, 0.04, 0.04), 0.15)
	for side: float in [-1.0, 1.0]:
		for k in 3:
			_part(Vector3((1.45 + 0.18 * (k % 2)) * side, 0.15 + 0.22 * k, -0.6 - 0.12 * k), Vector3.ONE * 0.38, eye, _head)
		_stick(Vector3(0.5 * side, -0.6, -1.6), Vector3(0.7 * side, -0.9, -2.1), 0.09, plate, _head)
		var an := Node3D.new()
		an.position = Vector3(1.0 * side, -0.4, -1.4)
		_head.add_child(an)
		var ac := _mat(grey.lightened(0.12), 0.45)
		var pts := [Vector3.ZERO, Vector3(0.7 * side, 0.1, -0.9), Vector3(1.3 * side, -0.1, -1.7), Vector3(1.6 * side, -0.7, -2.6), Vector3(1.75 * side, -1.1, -3.3), Vector3(1.85 * side, -1.4, -3.9)]
		for j in pts.size() - 1:
			_stick(pts[j], pts[j + 1], 0.2 - 0.025 * j, ac, an)
			_part(pts[j + 1], Vector3.ONE * (0.36 - 0.04 * j), ac, an) # (its joints)
		an.set_meta("side", side)
		_antennae.append(an)
	# the tail: the telson a blunt triangle, the uropods short and flat
	# either side of it, flush with the rim
	var tail: Node3D = nodes[SEGS - 1]
	_part(Vector3(0.0, 0.45, 0.45), Vector3(2.4, 0.6, 1.5), plate, tail) # (the telson: rounded, a half disc)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.25 * side, -0.1, 0.4), Vector3(1.0, 0.55, 1.0), plate, tail) # (the uropods: round, flush)
	# the brood pouch (a female's), under her front: swelling with eggs
	if not young and not male:
		var pm := _mat(Color(0.88, 0.85, 0.75, 0.75), 0.3)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_pouch = _part(Vector3(0.0, -1.6, -1.8), Vector3(3.2, 1.2, 4.4), pm)
		_pouch.visible = false
		var em := _mat(Color(0.95, 0.93, 0.85), 0.3)
		for k in 10:
			var e := _part(Vector3(randf_range(-1.0, 1.0), -1.6, -1.8 + randf_range(-1.5, 1.5)), Vector3.ONE * 0.55, em)
			e.visible = false
			_eggs.append(e)
	var leg := Color(0.24, 0.22, 0.23) if not young else Color(0.6, 0.58, 0.56) # (its legs dark, under its pale shell)
	_build_legs(_mat(leg, 0.5), _mat(leg.lightened(0.08), 0.5))


static var _pill_shader: Shader
const ARCH_ROUND := 18 # (a band's: round it)
const ARCH_ALONG := 5 # (and along it)


## A back plate's band (mm): arched over (half width hw, high hh) and down
## the sides to `reach` (rad from the top), length l along z; its edges
## flared out a little, its front tucked in (under the one ahead), its back
## a little proud (lapping the next).
static func _arch(hw: float, hh: float, l: float, reach: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y0 := -hh * 0.42
	var pt := func(i: int, j: int) -> Array:
		var th := lerpf(-reach, reach, float(i) / ARCH_ROUND)
		var t := float(j) / ARCH_ALONG # (0 front .. 1 back)
		var flare := 1.0 + 0.08 * smoothstep(1.1, reach, absf(th))
		var tuck := lerpf(0.93, 1.03, smoothstep(0.0, 1.0, t))
		var p := Vector3(sin(th) * hw * flare * tuck, y0 + cos(th) * hh * tuck, (t - 0.5) * l)
		var n := Vector3(sin(th) / hw, cos(th) / hh, 0.0).normalized()
		return [p, n]
	for i in ARCH_ROUND:
		for j in ARCH_ALONG:
			var q := [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			for e in [0, 1, 2, 0, 2, 3]: # (wound to face out: its outside the front face, lit as it should be)
				var v: Array = q[e]
				st.set_normal(v[1])
				st.add_vertex(v[0])
	return st.commit()


## A band's look: glossy slate grey, a pale spot on each side in two rows
## down the body (spots: a female's), a faint pale line down the middle,
## its back rim darker; its underside darker still.
static func _band_mat(base: Color, hw: float, l: float, spots: bool) -> ShaderMaterial:
	if _pill_shader == null:
		_pill_shader = Shader.new()
		_pill_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 base : source_color;
uniform vec3 spot : source_color = vec3(0.74, 0.7, 0.52);
uniform float hw = 3.6;
uniform float len = 2.0;
uniform bool spots = true;
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	vec3 c = base;
	float ax = abs(o.x) / hw;
	if (spots) {
		float d1 = length(vec2((ax - 0.45) * hw, o.z * 1.3));
		float d2 = length(vec2((ax - 0.8) * hw, o.z * 1.3));
		c = mix(c, spot, (1.0 - smoothstep(0.32, 0.5, d1)) * 0.75);
		c = mix(c, spot, (1.0 - smoothstep(0.26, 0.42, d2)) * 0.55);
		c = mix(c, spot, (1.0 - smoothstep(0.06, 0.14, ax)) * 0.2);
	}
	c *= 1.0 - 0.22 * smoothstep(len * 0.28, len * 0.46, o.z); // (the back rim)
	c *= 0.96 + 0.04 * sin(o.x * 23.0 + o.z * 11.0); // (its fine texture)
	if (!FRONT_FACING) // (seen from within: its underside, a little darker)
		c *= 0.8;
	ALBEDO = c;
	ROUGHNESS = 0.3;
	SPECULAR = 0.6;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _pill_shader
	m.set_shader_parameter("base", base)
	m.set_shader_parameter("hw", hw)
	m.set_shader_parameter("len", l)
	m.set_shader_parameter("spots", spots)
	return m


func _plate_z(k: int) -> float:
	# (the head small, the pereon's seven plates long, the pleon's short)
	var z := -LEN * 0.5
	for j in k:
		z += _plate_len(j)
	return z + _plate_len(k) * 0.5


func _plate_len(k: int) -> float:
	if k == 0:
		return 1.4
	if k <= 7:
		return 1.45
	return 0.65 if k < 13 else 0.9


func _plate_w(k: int) -> float:
	var t := float(k) / (SEGS - 1)
	var w := 7.2 * (0.62 + 0.38 * sin(PI * clampf(t * 1.05 + 0.08, 0.0, 1.0))) * (0.85 if k == 0 else 1.0)
	if k > 8: # (its tail end round, seen from above: a half circle)
		var u := float(k - 8) / 6.0
		w = maxf(w, 7.2 * 0.62) * sqrt(maxf(1.0 - u * u, 0.0)) * 1.04
	return w


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_ball_to = 0.0


func eat(at: Vector3) -> void:
	_mode = "eat"
	_at = at
	_ball_to = 0.0


func roll(seconds := 5.0) -> void:
	_mode = "roll"
	_ball_to = 1.0
	_st = 0.0
	_wait = seconds
	_target = _pos


func lay() -> void:
	if young or _pouch == null:
		return
	_mode = "lay"
	_st = 0.0
	_target = _pos


## The young out of the pouch, walking out from under her.
func hatch() -> void:
	if _pouch == null or _brood < 0.5:
		return
	_hatching = 10
	_st = 0.0
	_mode = "hatch"
	_target = _pos


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	match _mode:
		"wander":
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius if rng.randf() < 0.75 else _pos
				_wait = rng.randf_range(2.0, 6.0)
		"eat":
			var away := _pos - _at
			away.y = 0.0
			away = away.normalized() if away.length() > 1e-4 else Vector3.BACK
			_target = _at + away * 8.0 * MM * size
			if _pos.distance_to(_target) < 0.003 and _speed < 0.003:
				_chew = 1.0
		"roll":
			_target = _pos
			if _wait <= 0.0 and _ball_to > 0.0:
				_ball_to = 0.0
				_st = 0.0
			elif _ball_to == 0.0 and _ball < 0.05:
				_mode = "idle"
		"lay": # (the eggs into her pouch: it swells)
			_brood = clampf(_st / 6.0, 0.0, 1.0)
			if _st > 6.0:
				_mode = "idle"
		"hatch":
			if _hatching > 0 and fmod(_st, 0.5) < dt and _st > 0.5:
				_hatching -= 1
				var parent := get_parent() as Node3D
				var y: Node3D = (get_script() as Script).new(true)
				parent.add_child(y)
				var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
				y.call("place", _pos + fwd * 0.004, _yaw + rng.randf_range(-1.2, 1.2))
				var a := rng.randf() * TAU
				y.call("wander", _pos + Vector3(cos(a), 0.0, sin(a)) * 0.05, 0.05)
				y.call("grow", 0.6, 120.0)
				mancae.append(y)
				_brood = float(_hatching) / 10.0
			if _hatching == 0:
				_brood = 0.0
				_mode = "idle"


func _pose(dt: float) -> void:
	_ball = move_toward(_ball, _ball_to, dt * 1.6)
	var k := _ball * _ball * (3.0 - 2.0 * _ball)
	# rolled: every joint bent down, so the plates close round into a ball
	for n in _plates:
		var d: float = n.get_meta("dir")
		n.rotation.x = d * 0.47 * k # (the front ones head down and under, the back ones tail down and under)
	_pose_mate()
	# (a ball: up off its legs a little, settled on its round)
	_lift = -body_h * 0.2 * k
	# the legs tucked in, hidden, rolled
	for i in _leg_mesh.size():
		for m: MeshInstance3D in _leg_mesh[i]:
			m.visible = k < 0.6
	# the head down to eat, the antennae tapping the ground ahead
	_head.rotation.x = -0.47 * k - 0.2 * _chew * (0.5 + 0.5 * sin(_t * 7.0))
	for an in _antennae:
		var side: float = an.get_meta("side")
		an.rotation = Vector3(0.25 * sin(_t * 3.0 + side) - 0.6 * k, 0.2 * sin(_t * 1.7 + side * 2.0) * (1.0 - k), 0.0)
		an.visible = k < 0.8
	# the pouch, swelling with eggs
	if _pouch:
		_pouch.visible = _brood > 0.02 and k < 0.6
		_pouch.scale = Vector3(3.2, 0.4 + 1.0 * _brood, 4.4) * maxf(_brood, 0.3)
		for e in _eggs.size():
			_eggs[e].visible = _pouch.visible and float(e) / _eggs.size() < _brood


# --- mating ------------------------------------------------------------------------

func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, 14.0)


func _mate_leave() -> Vector3:
	return Vector3(7.0, -body_h, 10.0)


func _court_secs() -> float:
	return 1.5 # (his antennae tapping her)


func _mount() -> Dictionary:
	# on her back, then leaning right over to one side of her, his tail bent
	# down under her edge; halfway, to the other side
	var t := _mate_t / maxf(mate_secs, 0.01) if _mate_stage == "joined" else (0.0 if _mate_stage == "mount" else 1.0)
	var side := -1.0 if t < 0.5 else 1.0
	var lean := clampf(minf(t, 1.0 - t) * 10.0 if t < 0.5 else minf(t - 0.5, 1.0 - t) * 10.0, 0.0, 1.0)
	var b := Basis(Vector3.BACK, -side * 0.55 * lean) * Basis(Vector3.RIGHT, -0.08)
	var feet := {}
	for p in legs.size():
		var z := -4.2 + p * 1.25
		feet[p * 2] = Vector3(-3.2, -0.2, z * 0.9 - 1.0)
		feet[p * 2 + 1] = Vector3(3.2, -0.2, z * 0.9 - 1.0)
	return {"at": Vector3(1.0 * side * lean, 3.6 - 0.6 * lean, 1.2), "basis": b, "grips": feet}


func _pose_mate() -> void:
	# (his tail bent down under her edge, joined)
	if _mate_role != "male" or _mate_stage != "joined":
		return
	var n := _plates.size()
	for j in range(n - 4, n):
		var nd := _plates[j]
		if float(nd.get_meta("dir")) > 0.0:
			nd.rotation.x += 0.2


func _after_mate() -> void:
	wander(_pos, 0.06)


# --- steering (pilot.gd): its behaviours -------------------------------------------

## eat {at, seconds}, roll {seconds}, lay (the female's).
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["eat", "roll"])
	return PackedStringArray(["eat", "roll", "mate"]) if male else PackedStringArray(["eat", "roll", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			eat(args.get("at", _pos + _p_heading() * 0.012))
		"roll":
			roll(float(args.get("seconds", 5.0)))
		"lay":
			if young:
				return false
			lay()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"roll", "lay":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 8.0 if name == "eat" else -1.0


func _p_mobile() -> bool:
	return _ball < 0.1


func _piloted() -> void:
	if _mode in ["wander", "idle", "eat"]:
		_mode = "piloted"
