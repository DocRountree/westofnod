class_name Grasshopper
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A differential grasshopper (Melanoplus differentialis), drawn at twice
## life size (an adult female about 80 mm long): olive yellow, glossy; a
## big blunt head, its face upright, big eyes, short thick antennae,
## mandibles and palps working as it eats; the pronotum a saddle over the
## thorax; long narrow leathery forewings folded over the back like a roof,
## the hindwings pleated away under them (smoky yellow, fanned out to
## fly); the hind legs its own: the femur huge, yellow, marked with black
## chevrons (a herringbone), folded with the knee up behind, the tibia
## yellow, spined. A nymph (Grasshopper.new(true, size)): paler, greener,
## its head bigger for its body, only little wing pads; growing.
## Not yet in the game (tools/creatures/life_cycle_demo.tscn).
##
## - wander(centre, radius): walking about, stopping, now and then a hop
## - feed(at): to a plant (a point), head down, chewing
## - hop(to): crouching, then a leap (ballistic: the hind legs flung out
##   straight behind)
## - fly(to): a leap, and the forewings up, the hindwings fanned out and
##   whirring, off over to `to`, down there (the adult's)
## - lay(at): to the spot, the abdomen pushed down into the soil, working,
##   and an egg pod left there (pods: Pod), hatching later into nymphs
##   that pop up out of the ground (Pod.hatch)

const LEGS := [
	{"hip": Vector3(1.4, -1.8, -6.0), "f": 5.5, "t": 5.0, "s": 3.0, "home": Vector2(5.5, -11.0), "dangle": Vector3(2.5, -4.0, -6.5), "pole": Vector3(0.4, 1.0, -0.3), "r": 0.45},
	{"hip": Vector3(1.8, -2.0, -3.0), "f": 6.0, "t": 5.5, "s": 3.2, "home": Vector2(7.5, -2.5), "dangle": Vector3(3.0, -4.5, -1.0), "pole": Vector3(0.5, 1.0, 0.0), "r": 0.45},
	# (the hind leg: its knee held up behind as it walks, the femur still:
	# only in the air reaching, flung out behind)
	{"hip": Vector3(2.2, -1.5, 0.8), "f": 18.0, "t": 17.0, "s": 4.5, "home": Vector2(5.5, 1.5), "dangle": Vector3(3.0, -2.0, 24.0), "pole": Vector3(0.15, 0.35, 1.0), "r": 0.7, "femur_r": 2.6, "knee": Vector3(4.3, 4.4, 16.5)},
]

var pods: Array[Node3D] = [] ## the egg pods it's laid (in its parent)
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.2
var _wait := 0.0
var _at := Vector3.ZERO
var _stage := 0
var _st := 0.0
var _after_mode := "idle"
var _head: Node3D
var _mands: Array[Node3D] = []
var _palps: Array[Node3D] = []
var _antennae: Array[Node3D] = []
var _abdomen: Node3D
var _teg: Array[Node3D] = [] # the forewings' hinges (left, right)
var _hind: Array[Node3D] = [] # the hindwings'
var _chew := 0.0
var _head_down := 0.0
var _wings := 0.0 # 0 folded .. 1 open, beating
var _probe := 0.0 # 0 .. 1: the abdomen pushed down into the soil


func _init(nymph_ := false, size_ := 1.0) -> void:
	super(nymph_, size_)
	legs = LEGS
	body_h = 5.2
	walk_speed = 0.035
	stride = 7.0
	step_time = 0.13


func _build() -> void:
	var olive := Color(0.5, 0.48, 0.2) if not nymph else Color(0.42, 0.55, 0.22)
	var olive_dk := olive.darkened(0.25)
	var body := _mat(olive, 0.45)
	var dark := _mat(Color(0.08, 0.06, 0.04), 0.4)
	var eye := _mat(Color(0.32, 0.22, 0.1), 0.15)
	# the head, its face upright, big; a nymph's bigger for its body
	_head = Node3D.new()
	_head.position = Vector3(0.0, 1.5, -8.5)
	_body.add_child(_head)
	var hs := 1.25 if nymph else 1.0
	_part(Vector3(0.0, 1.2, -2.0) * hs, Vector3(5.6, 7.0, 5.2) * hs, body, _head)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(2.3 * side, 2.4, -2.2) * hs, Vector3(1.8, 3.0, 2.3) * hs, eye, _head)
		var m := Node3D.new()
		m.position = Vector3(0.9 * side, -2.4, -3.4) * hs
		_head.add_child(m)
		_part(Vector3(0.0, -0.6, -0.3), Vector3(1.4, 1.6, 1.1) * hs, dark, m)
		m.set_meta("side", side)
		_mands.append(m)
		var pp := Node3D.new()
		pp.position = Vector3(1.3 * side, -2.0, -3.6) * hs
		_head.add_child(pp)
		_stick(Vector3.ZERO, Vector3(0.3 * side, -2.0, -0.8), 0.25, body, pp)
		_palps.append(pp)
		# an antenna: short, thick, in beads, up, out and forward
		var an := Node3D.new()
		an.position = Vector3(1.0 * side, 3.4, -3.4) * hs
		_head.add_child(an)
		var p := Vector3.ZERO
		var d := Vector3(0.3 * side, 0.55, -0.78).normalized()
		for k in 12:
			var q := p + d * (1.15 if not nymph else 0.8)
			_stick(p, q, 0.28 - 0.01 * k, _mat(Color(0.42, 0.3, 0.12), 0.5), an)
			p = q
			d = (d + Vector3(0.02 * side, 0.0, 0.04)).normalized()
		_antennae.append(an)
	# the pronotum, a saddle; the thorax under it
	_body.add_child(_mesh(_loft([[-9.0, 1.6, 0.6, 0.6], [-8.4, 1.6, 2.4, 2.6], [-7.0, 1.7, 3.0, 3.1], [-4.8, 1.6, 3.2, 3.3], [-2.5, 1.4, 3.4, 3.4], [-1.6, 1.3, 2.6, 2.6], [-1.2, 1.3, 0.6, 0.6]], 2.5), body))
	_part(Vector3(0.0, -0.8, -3.6), Vector3(5.0, 4.0, 9.0), _mat(olive.lightened(0.15), 0.5))
	# the abdomen (its joint: it pushes down into the soil to lay), a pair
	# of short dark valves at its tip
	_abdomen = Node3D.new()
	_abdomen.position = Vector3(0.0, 0.2, -0.5)
	_body.add_child(_abdomen)
	var ab := _loft([[0.0, 0.0, 0.6, 0.6], [0.6, 0.0, 2.6, 2.8], [4.0, 0.0, 2.9, 3.1], [9.0, -0.2, 2.6, 2.8], [14.0, -0.4, 2.0, 2.2], [18.0, -0.5, 1.1, 1.2], [19.2, -0.5, 0.3, 0.3]])
	_abdomen.add_child(_mesh(ab, _banded(olive_dk.lerp(olive, 0.6), 2.6, 0.8, 0.1, 0.55)))
	_part(Vector3(0.0, -0.3, 19.6), Vector3(1.1, 0.9, 1.8), dark, _abdomen)
	# the wings: the adult's long leathery forewings, roofed over its back,
	# the hindwings pleated away under them; a nymph's only little pads
	for side: float in [-1.0, 1.0]:
		var h := Node3D.new()
		h.position = Vector3(1.3 * side, 3.4, -1.6)
		_body.add_child(h)
		h.set_meta("side", side)
		if nymph:
			_part(Vector3(0.6 * side, 0.0, 2.5), Vector3(2.8, 0.5, 5.0), _mat(olive.darkened(0.1), 0.5), h)
		else:
			_part(Vector3(0.4 * side, 0.0, 13.5), Vector3(3.8, 0.4, 27.0), _mat(Color(0.47, 0.44, 0.24), 0.55), h)
			var hw := Node3D.new()
			hw.position = Vector3(1.3 * side, 2.9, -0.4)
			_body.add_child(hw)
			hw.set_meta("side", side)
			var mem := _mat(Color(0.78, 0.72, 0.45, 0.5), 0.3)
			mem.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mem.cull_mode = BaseMaterial3D.CULL_DISABLED
			_part(Vector3(12.0 * side, 0.0, 7.0), Vector3(24.0, 0.15, 17.0), mem, hw)
			_hind.append(hw)
		_teg.append(h)
	# the legs: the hind femur huge, yellow, black chevrons; the tibiae yellow
	var femur := ShaderMaterial.new()
	femur.shader = _chevrons()
	femur.set_shader_parameter("base", Color(0.78, 0.68, 0.28) if not nymph else Color(0.55, 0.62, 0.28))
	femur.set_shader_parameter("mark", Color(0.06, 0.05, 0.03))
	var legs_c := _mat(olive.lightened(0.1), 0.5)
	var hind_tibia := _mat(Color(0.82, 0.7, 0.3), 0.45)
	legs = LEGS.duplicate(true)
	legs[2]["femur_mat"] = femur
	legs[2]["tibia_mat"] = hind_tibia
	_build_legs(legs_c, legs_c)


static var _chev: Shader


## The hind femur's herringbone: black chevrons down its outer face.
static func _chevrons() -> Shader:
	if _chev == null:
		_chev = Shader.new()
		_chev.code = """shader_type spatial;
uniform vec3 base : source_color;
uniform vec3 mark : source_color;
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	float v = fract(o.y * 7.0 + abs(o.z) * 2.2);
	float ch = step(v, 0.32) * step(-0.38, o.y) * step(o.y, 0.36) * smoothstep(-0.1, 0.2, o.x * sign(o.x));
	ALBEDO = mix(base, mark, ch * 0.9);
	ROUGHNESS = 0.5;
}
"""
	return _chev


func _mesh(m: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	return mi


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0


func feed(at: Vector3) -> void:
	_mode = "feed"
	_at = at
	_stage = 0


func hop(to: Vector3) -> void:
	_after_mode = _mode if _mode in ["wander", "feed"] else "wander"
	_mode = "hop"
	_at = to
	_stage = 0
	_st = 0.0


## (The adult's: a nymph only hops.)
func fly(to: Vector3) -> void:
	if nymph:
		hop(to)
		return
	_after_mode = _mode if _mode in ["wander", "feed"] else "wander"
	_mode = "fly"
	_at = to
	_stage = 0
	_st = 0.0


func lay(at: Vector3) -> void:
	if nymph:
		return
	_mode = "lay"
	_at = at
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = 0.0
	_head_down = move_toward(_head_down, 0.0, dt * 2.0)
	match _mode:
		"wander":
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				var p := _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
				if rng.randf() < 0.18:
					hop(p)
					return
				_target = p if rng.randf() < 0.7 else _pos
				_wait = rng.randf_range(2.0, 6.0)
		"feed":
			var away := _pos - _at
			away.y = 0.0
			away = away.normalized() if away.length() > 1e-4 else Vector3.BACK
			_target = _at + away * 11.0 * MM * size
			if _pos.distance_to(_target) < 0.003 and _speed < 0.004:
				if _stage == 0:
					_turn_to = atan2(away.x, away.z)
					_stage = 1
				_head_down = minf(_head_down + dt * 3.0, 1.0)
				_chew = 1.0
		"hop":
			if _stage == 0:
				_target = _pos
				_crouch = minf(_crouch + dt * 6.0, 1.0)
				if _st > 0.22:
					_crouch = 0.0
					_leap(_at, 0.8)
					_stage = 1
		"fly":
			if _stage == 0:
				_target = _pos
				_crouch = minf(_crouch + dt * 6.0, 1.0)
				if _st > 0.22:
					_crouch = 0.0
					_leap(_at, 0.9)
					_stage = 1
					_st = 0.0
			elif _stage == 1:
				# the wings out at once, off over toward it (up, then down to
				# it), the wings whirring; then down onto it
				_wings = minf(_wings + dt * 12.0, 1.0)
				var d := Vector2(_at.x - _pos.x, _at.z - _pos.z).length()
				if _st > 0.1:
					_steer = Vector3(_at.x, ground_y + clampf(d * 0.5, 0.06, 0.3), _at.z)
					_steer_speed = 1.0
				if d < 0.06:
					_steer = Vector3.INF # (down)
					_stage = 2
		"lay":
			match _stage:
				0:
					_target = _at
					if _pos.distance_to(_at) < 0.004 and _speed < 0.004:
						_stage = 1
						_st = 0.0
				1: # the abdomen down into the soil, working
					_probe = minf(_probe + dt * 0.8, 1.0)
					_pitch = 0.12 * _probe # (its front up)
					if _st > 5.0:
						_drop_pod()
						_stage = 2
						_st = 0.0
				2:
					_probe = maxf(_probe - dt * 0.8, 0.0)
					_pitch = 0.12 * _probe
					if _probe <= 0.0:
						wander(_at, 0.15)
	_crouch = move_toward(_crouch, 0.0, dt * 2.0) if _mode not in ["hop", "fly"] or _stage > 0 else _crouch


func _on_landed() -> void:
	_steer = Vector3.INF
	_wings = 0.0
	if _mode in ["hop", "fly"]:
		_mode = _after_mode
		_wait = rng.randf_range(0.5, 2.0)


## The egg pod: where the abdomen's tip went down, in the soil.
func _drop_pod() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var tip := _out(_abdomen.position + Vector3(0.0, -0.5, 19.0))
	var pod := Pod.new()
	pod.maker = get_script()
	parent.add_child(pod)
	pod.position = Vector3(tip.x, ground_y, tip.z)
	pods.append(pod)


func _pose(dt: float) -> void:
	# the head down to eat, the mandibles working, the palps tapping
	_head.rotation.x = -0.35 * _head_down
	for m in _mands:
		var side: float = m.get_meta("side")
		m.rotation.y = side * (0.1 + 0.35 * _chew * (0.5 + 0.5 * sin(_t * 14.0)))
	for k in _palps.size():
		_palps[k].rotation.x = 0.3 * _chew * sin(_t * 9.0 + k)
	for k in _antennae.size():
		_antennae[k].rotation = Vector3(0.12 * sin(_t * 1.3 + k * 2.0), 0.1 * sin(_t * 0.9 + k), 0.0)
	# the abdomen: pushed down into the soil (and stretched: its joints
	# telescope), drawn up a little as it leaps
	_abdomen.rotation.x = 0.75 * _probe + (0.1 if airborne else 0.0)
	_abdomen.scale = Vector3(1.0, 1.0, 1.0 + 0.4 * _probe)
	# the wings: roofed over the back, or up and out, the hindwings fanned
	# and whirring
	# (folded: the forewings roofed over the back along it; flying: swung
	# out square to the sides, beating, the hindwings fanned out from their
	# pleats behind them, beating harder, a little after)
	var ph := _t * TAU * 18.0
	for h in _teg:
		var side: float = h.get_meta("side")
		if nymph:
			h.transform.basis = Basis(Vector3.BACK, -0.3 * side)
			continue
		var flap := (0.12 + 0.35 * sin(ph + 0.9)) * _wings
		h.transform.basis = Basis(Vector3.BACK, side * flap) * Basis(Vector3.UP, side * 1.25 * _wings) * Basis(Vector3.BACK, -0.28 * side * (1.0 - _wings))
	for h in _hind:
		var side: float = h.get_meta("side")
		var flap := (0.1 + 0.85 * sin(ph)) * _wings
		h.transform.basis = Basis(Vector3.BACK, side * flap) * Basis(Vector3.UP, -0.15 * side * _wings) * Basis.from_scale(Vector3(lerpf(0.06, 1.0, _wings), 1.0, lerpf(0.5, 1.0, _wings)))
		h.visible = _wings > 0.02
	# in the air, nose up rising and down falling; on the ground, level
	# (but laying)
	if airborne:
		var climb := atan2(_vel.y, maxf(Vector2(_vel.x, _vel.z).length(), 0.01))
		_pitch = lerpf(_pitch, clampf(climb * 0.4, -0.4, 0.4), 1.0 - exp(-6.0 * dt))
	elif _mode != "lay":
		_pitch = lerpf(_pitch, 0.0, 1.0 - exp(-6.0 * dt))


## A grasshopper's egg pod (laid by lay()): in the soil, a plug of
## dried froth at its top, the tips of its eggs (rice grains, tan) showing
## round it. hatch(): it stirs, and the nymphs come up out of it one after
## another, each popping up and hopping off, small, to wander and grow.
class Pod extends Node3D:
	const MM := 0.002
	const BroodScript := preload("res://scripts/creatures/brood.gd")
	var maker: Script # (the grasshopper's script: its nymphs)
	var nymphs: Array[Node3D] = []
	var _left := 0
	var _t := 0.0
	var _plug: MeshInstance3D

	func _ready() -> void:
		var froth := StandardMaterial3D.new()
		froth.albedo_color = Color(0.62, 0.52, 0.36)
		froth.roughness = 0.95
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 10
		s.rings = 6
		_plug = MeshInstance3D.new()
		_plug.mesh = s
		_plug.scale = Vector3(6.0, 2.0, 6.0) * MM
		_plug.material_override = froth
		add_child(_plug)
		for k in 5:
			var e := BroodScript.egg("grasshopper")
			var a := TAU * k / 5.0
			e.position = Vector3(cos(a) * 2.2, -3.0, sin(a) * 2.2) * MM
			e.rotation = Vector3(0.25 * sin(a), 0.0, 0.25 * cos(a))
			add_child(e)

	## Hatching: n nymphs up out of it, one by one.
	func hatch(n := 5) -> void:
		if _left > 0 or maker == null:
			return
		_left = n
		_t = 0.0

	func _process(dt: float) -> void:
		if _left <= 0:
			return
		_t += dt
		_plug.position.y = sin(_t * 12.0) * 0.4 * MM # (stirring)
		if _t > 0.8:
			_t = 0.0
			_left -= 1
			var parent := get_parent() as Node3D
			var ny: Node3D = maker.new(true, 0.22)
			parent.add_child(ny)
			ny.call("place", position, randf() * TAU)
			ny.call("wander", position, 0.12)
			var a := randf() * TAU
			ny.call("hop", position + Vector3(cos(a), 0.0, sin(a)) * randf_range(0.03, 0.07))
			ny.call("grow", 0.6, 90.0)
			nymphs.append(ny)
			if _left == 0:
				for c in get_children():
					if c != _plug:
						c.queue_free()
				_plug.scale *= 0.6
