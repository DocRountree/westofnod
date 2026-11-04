class_name Scorpion
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## An Arizona bark scorpion (Centruroides sculpturatus), drawn at twice life
## size as the insects and spiders are (about 6 cm long, the tail nearly
## half of it): slender, straw yellow, glossy; the carapace with its two
## median eyes on their mound and three lateral eyes at each front corner;
## the mesosoma's seven tergites; the tail (the metasoma) five long thin
## segments, the fifth darker, the telson's bulb and its curved dark sting
## (a little tooth under it); the pedipalps long and slender, their
## chelae's fingers long, reddish; small chelicerae; four pairs of legs
## (hexapod.gd's eight-legged gait). Young (Scorpion.new(true)): the
## scorplings, born white, soft; growing, yellowing. The two sexes the same
## to see. Not yet in the game (tools/creatures/life_cycle_demo.tscn).
##
## - wander(centre, radius): still a long while (its tail coiled round to
##   its side), then walking slowly a little way, its tail up in a loose
##   arch over its back
## - hunt(prey): still, waiting, then creeping to it, the chelae shot out
##   and closed on it, the tail arched over and the sting driven in, again;
##   then held to its mouth, the chelicerae tearing at it till it's gone
## - birth(n): (a female's) up on her legs, her forelegs cupped under her
##   (the birth basket), the scorplings born one by one into it and
##   climbing up her legs onto her back; carried there a while, then down
##   and away, small, growing
## - mate(her): the promenade a deux: he comes before her, shudders
##   (juddering), takes her chelae in his, and they walk to and fro
##   together, he leading, backing; a sting into her pedipalp's joint; he
##   lays his spermatophore on the ground, a slender stalk, and draws her
##   over it, then lets go and hurries off
## Steering (pilot.gd): act hunt {prey}, sting {at}, birth {n} (a
## female's), mate {partner}.

const STRAW := Color(0.8, 0.64, 0.33)
const SEGS := [4.6, 5.0, 5.3, 5.6, 6.2] # mm, the tail's segments (the fifth the longest)
const TAIL_REST := [[-0.08, 0.55], [-0.04, 0.62], [-0.04, 0.62], [-0.06, 0.58], [-0.25, 0.45], [-0.6, 0.2]] # (coiled round to its side on the ground: [arch, round] each joint, the last the telson's)
const TAIL_WALK := [[-0.55, 0.05], [-0.55, 0.0], [-0.5, 0.0], [-0.5, 0.0], [-0.45, 0.0], [-0.7, 0.0]] # (up in an arch over its back)
const TAIL_STING := [[-0.75, 0.0], [-0.7, 0.0], [-0.7, 0.0], [-0.65, 0.0], [-0.3, 0.0], [-0.2, 0.0]] # (over and forward, the sting out ahead)
const OPERCULUM := Vector3(0.0, -2.0, 1.6) # mm: the genital opening, under the mesosoma's front
const PALP_REST := [-1.0, 1.75, 0.35] # (each pedipalp: the femur out from forward, the patella back in, the chela; a right one's: mirrored)
const PALP_REACH := [-0.42, 0.55, 0.05]
const PALP_HOLD := [-1.25, 2.45, 0.9] # (drawn in to its mouth)

var young := false
var brood: Array[Node3D] = [] ## its young, born
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.1
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _prey: Node3D
var _prey_s := Vector3.ONE
var _held := false
var _chew := 0.0
var _tail_k := [] # each joint now: [arch, round]
var _tail_ask := TAIL_REST
var _tail_rate := 4.0
var _palp_ask := [PALP_REST, PALP_REST]
var _palp_now := [PALP_REST, PALP_REST]
var _palp_rate := 6.0
var _grip := 0.0 # the chelae's fingers: 0 open .. 1 shut
var _judder := 0.0
var _born_left := 0
var _carry_t := 0.0
# riding on its mother (a scorpling)
var _mother: Node3D
var _ride_at := Vector3.ZERO
var _ride_t := 0.0
var _climb := 1.0 # 0 just born, under her .. 1 up on her back
# the promenade
var _dance_at := Vector3.ZERO
var _dance_h := Vector3.FORWARD
var _gap := 0.0
var _spermatophore: Node3D
# the parts
var _tail: Array[Node3D] = []
var _palps: Array = [] # each side: [femur, patella, chela, finger]
var _chel: Array[Node3D] = []
var _mats: Array = [] # [material, its colour grown]


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.17 if young_ else 1.0)
	body_h = 3.6
	walk_speed = 0.05
	stride = 8.0
	step_time = 0.1
	mate_secs = 25.0
	tripod = [[0, 3, 4, 7], [1, 2, 5, 6]]
	var L := []
	var lens := [[4.5, 5.0, 4.0], [5.0, 5.5, 4.5], [5.5, 6.0, 5.0], [6.5, 7.2, 6.0]]
	var homes := [Vector2(9.0, -10.5), Vector2(11.5, -4.5), Vector2(12.0, 2.5), Vector2(11.0, 10.0)]
	for p in 4:
		var l: Array = lens[p]
		L.append({"hip": Vector3(1.6 + 0.25 * p, -1.3, -6.6 + 1.9 * p), "f": l[0], "t": l[1], "s": l[2], "home": homes[p],
				"dangle": Vector3(5.0, -3.0, -6.0 + 4.0 * p), "pole": Vector3(0.5, 1.0, -0.3 + 0.2 * p), "r": 0.5, "femur_r": 1.4})
	legs = L
	for k in TAIL_REST.size():
		_tail_k.append(TAIL_REST[k])


func _paint(c: Color, rough := 0.35) -> Material:
	var m := _mat(Color(0.93, 0.92, 0.86) if young else c, rough)
	_mats.append([m, c])
	return m


func _build() -> void:
	var body := _paint(STRAW, 0.3)
	var dark := _paint(STRAW.darkened(0.25), 0.3)
	var red := _paint(Color(0.5, 0.25, 0.12), 0.25)
	var black := _mat(Color(0.03, 0.03, 0.03), 0.1)
	# the carapace: low, squarish, its front notched
	var cara := MeshInstance3D.new()
	cara.mesh = _loft([[-8.6, 0.0, 2.6, 1.0], [-7.8, 0.3, 3.3, 1.5], [-4.5, 0.6, 3.7, 1.9], [-1.0, 0.6, 3.9, 2.0], [0.3, 0.5, 3.6, 1.8]], 2.6)
	cara.material_override = body
	_body.add_child(cara)
	_part(Vector3(0.0, 2.3, -5.4), Vector3(1.8, 0.8, 1.6), body) # (the eyes' mound)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(0.55 * side, 2.6, -5.4), Vector3.ONE * 0.75, black) # (a median eye)
		for k in 3:
			_part(Vector3((2.8 - 0.25 * k) * side, 1.05, -7.9 + 0.5 * k), Vector3.ONE * 0.4, black) # (the lateral eyes)
	# the mesosoma: seven tergites (the bands), broad and flat
	var meso := MeshInstance3D.new()
	meso.mesh = _loft([[0.0, 0.4, 3.6, 1.9], [3.0, 0.5, 4.1, 2.1], [9.0, 0.5, 4.4, 2.2], [14.0, 0.4, 3.9, 2.0], [17.0, 0.3, 2.8, 1.7], [18.6, 0.3, 1.8, 1.4]], 2.5)
	meso.material_override = _band(STRAW, 2.65)
	_body.add_child(meso)
	# the pectines under it: two little combs
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(0.6 * side, -1.6, 2.6), Vector3(2.6 * side, -1.8, 3.6), 0.35, body)
	# the tail: five long segments, keeled, the fifth darker; the telson
	var prev: Node3D = _body
	for k in SEGS.size():
		var n := Node3D.new()
		n.position = Vector3(0.0, 0.3, 18.2) if k == 0 else Vector3(0.0, 0.0, SEGS[k - 1])
		prev.add_child(n)
		var l: float = SEGS[k]
		var w := 1.95 - 0.08 * k
		var seg := MeshInstance3D.new()
		seg.mesh = _loft([[0.0, 0.0, w * 0.8, w * 0.75], [0.5, 0.0, w, w * 0.9], [l - 0.7, 0.0, w * 0.97, w * 0.88], [l, 0.0, w * 0.78, w * 0.72]], 2.4)
		seg.material_override = dark if k == 4 else body
		n.add_child(seg)
		_tail.append(n)
		prev = n
	var tel := Node3D.new()
	tel.position = Vector3(0.0, 0.0, SEGS[4])
	prev.add_child(tel)
	_part(Vector3(0.0, -0.2, 1.8), Vector3(2.4, 2.2, 3.8), body, tel) # (the bulb)
	_part(Vector3(0.0, -0.9, 2.3), Vector3(0.8, 0.8, 0.9), dark, tel) # (the tooth under it)
	var tip := Vector3(0.0, -0.4, 3.6)
	var mid := Vector3(0.0, -1.3, 5.0)
	_stick(tip, mid, 0.42, red, tel) # (the sting, curved down)
	_stick(mid, Vector3(0.0, -2.7, 5.4), 0.25, red, tel)
	_tail.append(tel)
	# the chelicerae
	for side: float in [-1.0, 1.0]:
		var ch := Node3D.new()
		ch.position = Vector3(0.7 * side, 0.0, -8.6)
		_body.add_child(ch)
		_part(Vector3(0.0, 0.0, -0.6), Vector3(1.0, 0.9, 1.6), body, ch)
		_stick(Vector3(0.0, 0.0, -1.2), Vector3(-0.2 * side, -0.1, -2.0), 0.18, red, ch)
		ch.set_meta("side", side)
		_chel.append(ch)
	# the pedipalps: long, slender; the chela's hand and its long fingers
	for side: float in [-1.0, 1.0]:
		var fm := Node3D.new()
		fm.position = Vector3(2.4 * side, -0.2, -7.6)
		_body.add_child(fm)
		_stick(Vector3.ZERO, Vector3(0.0, 0.0, -7.0), 0.55, body, fm)
		var pt := Node3D.new()
		pt.position = Vector3(0.0, 0.0, -7.0)
		fm.add_child(pt)
		_part(Vector3.ZERO, Vector3.ONE * 1.1, body, pt)
		_stick(Vector3.ZERO, Vector3(0.0, 0.0, -7.2), 0.65, body, pt)
		var cl := Node3D.new()
		cl.position = Vector3(0.0, 0.0, -7.2)
		pt.add_child(cl)
		_part(Vector3(0.0, 0.0, -2.4), Vector3(1.9, 1.7, 5.0), body, cl) # (the hand)
		_stick(Vector3(0.35 * side, 0.0, -4.6), Vector3(0.15 * side, 0.0, -10.4), 0.32, red, cl) # (the fixed finger)
		var fg := Node3D.new()
		fg.position = Vector3(-0.45 * side, 0.0, -4.6)
		cl.add_child(fg)
		_stick(Vector3.ZERO, Vector3(0.1 * side, 0.0, -6.0), 0.3, red, fg) # (the movable finger)
		_palps.append([fm, pt, cl, fg])
	_build_legs(body, body)


func _band(c: Color, seg: float) -> Material:
	var m := _banded(Color(0.93, 0.92, 0.86) if young else c, seg, 0.4, 0.06, 0.6)
	_mats.append([m, c])
	return m


## A cricket, for it to hunt (twice life size, ~30 mm): dark brown, its
## long hind legs, its antennae; its origin where it stands.
static func cricket() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.2, 0.13, 0.07)
	brown.roughness = 0.4
	for p in [[Vector3(0.0, 0.006, 0.004), Vector3(0.008, 0.007, 0.02)], [Vector3(0.0, 0.007, -0.009), Vector3(0.007, 0.007, 0.007)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = p[0]
		mi.scale = p[1]
		mi.material_override = brown
		root.add_child(mi)
	for side: float in [-1.0, 1.0]:
		for leg in [[Vector3(0.003, 0.005, 0.006), Vector3(0.008, 0.012, 0.012), Vector3(0.006, 0.0, 0.022)], [Vector3(0.003, 0.004, -0.004), Vector3(0.008, 0.004, -0.008), Vector3(0.009, 0.0, -0.01)]]:
			for k in 2:
				var a: Vector3 = leg[k]
				var b: Vector3 = leg[k + 1]
				var mi := MeshInstance3D.new()
				mi.mesh = c
				var d := Vector3(b.x * side, b.y, b.z) - Vector3(a.x * side, a.y, a.z)
				var y := d.normalized()
				var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
				mi.transform = Transform3D(Basis(x * 0.0012, d, x.cross(y) * 0.0012), (Vector3(a.x * side, a.y, a.z) + Vector3(b.x * side, b.y, b.z)) * 0.5)
				mi.material_override = brown
				root.add_child(mi)
		var an := MeshInstance3D.new()
		an.mesh = c
		var ad := Vector3(0.012 * side, 0.004, -0.03)
		var ay := ad.normalized()
		var ax := ay.cross(Vector3.RIGHT).normalized()
		an.transform = Transform3D(Basis(ax * 0.0005, ad, ax.cross(ay) * 0.0005), Vector3(0.0, 0.008, -0.013) + ad * 0.5)
		an.material_override = brown
		root.add_child(an)
	return root


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_pace = -1.0


func hunt(prey: Node3D) -> void:
	if prey == null or not is_instance_valid(prey):
		return
	_mode = "hunt"
	_prey = prey
	_prey_s = prey.scale
	_held = false
	_stage = 0
	_st = 0.0


## A sting at a point (its parent's space): turned to it, the tail over
## and the sting jabbed at it.
func sting(at: Vector3) -> void:
	_mode = "sting"
	_dance_at = at
	_stage = 0
	_st = 0.0


## (A female's.) Her young born: up on her legs, n scorplings, onto her back.
func birth(n := 12) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = n
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_palp_ask = [PALP_REST, PALP_REST]
	_palp_rate = 6.0
	_grip = move_toward(_grip, 0.0, dt * 3.0)
	var moving := _speed > 0.004
	_tail_ask = TAIL_WALK if moving else TAIL_REST
	_tail_rate = 3.0
	match _mode:
		"wander":
			if _wait <= 0.0:
				if rng.randf() < 0.5:
					_target = _pos
					_wait = rng.randf_range(4.0, 12.0) # (still: an ambusher)
				else:
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_wait = rng.randf_range(3.0, 7.0)
		"hunt":
			_hunt(dt)
		"sting":
			var to := _dance_at - _pos
			to.y = 0.0
			match _stage:
				0:
					_target = _pos
					_turn_to = atan2(-to.x, -to.z)
					if _st > 0.6:
						_stage = 1
						_st = 0.0
				1:
					_jab(_st)
					if _st > 2.5:
						wander(_pos, 0.08)
		"birth":
			_birth(dt)
		"carry": # (her young on her back: still, her tail coiled)
			_target = _pos
			_carry_t -= dt
			if _carry_t <= 0.0:
				wander(_pos, 0.08)


## The tail over and the sting driven forward, twice.
func _jab(t: float) -> void:
	_tail_ask = TAIL_STING
	_tail_rate = 10.0
	var k := fmod(t, 1.0)
	if k > 0.5 and k < 0.7: # (driven in)
		_tail_ask = [[-0.8, 0.0], [-0.8, 0.0], [-0.78, 0.0], [-0.72, 0.0], [-0.55, 0.0], [-0.5, 0.0]]
		_tail_rate = 30.0


func _hunt(dt: float) -> void:
	if not is_instance_valid(_prey):
		_held = false
		wander(_pos, 0.08)
		return
	var p := _prey.position
	var to := p - _pos
	to.y = 0.0
	var reach := 22.0 * MM * size # (its chelae's tips, out ahead)
	match _stage:
		0: # still, waiting, turning to it
			_target = _pos
			_turn_to = atan2(-to.x, -to.z)
			if _st > 1.5:
				_stage = 1
				_st = 0.0
		1: # creeping to it
			_target = p - to.normalized() * reach * 0.9
			_pace = walk_speed * 0.4
			if to.length() < reach * 1.05 or _st > 10.0:
				_pace = -1.0
				_target = _pos
				_stage = 2
				_st = 0.0
		2: # the chelae shot out, closed on it
			_palp_ask = [PALP_REACH, PALP_REACH]
			_palp_rate = 30.0
			_grip = 0.0 if _st < 0.12 else 1.0
			if _st > 0.25:
				_held = true
				_stage = 3
				_st = 0.0
		3: # stung, again
			_palp_ask = [PALP_REACH, PALP_REACH]
			_grip = 1.0
			_jab(_st)
			if _st > 2.0:
				_stage = 4
				_st = 0.0
		4: # held to its mouth, the chelicerae tearing at it
			_palp_ask = [PALP_HOLD, PALP_HOLD]
			_palp_rate = 3.0
			_grip = 1.0
			_chew = 1.0
			_prey.scale = _prey_s * maxf(1.0 - _st / 12.0, 0.05)
			if _st > 12.0:
				_prey.queue_free()
				_prey = null
				_held = false
				wander(_pos, 0.08)


func _birth(dt: float) -> void:
	match _stage:
		0: # up on her legs, her forelegs cupped under her: the basket
			_target = _pos
			_lift = move_toward(_lift, 3.0, dt * 2.0)
			for i: int in [0, 1]:
				var side := 1.0 if i % 2 == 1 else -1.0
				_pose_foot[i] = Vector3(1.6 * side, -body_h - 1.0, OPERCULUM.z + 0.5)
			if _st > 2.0:
				_stage = 1
				_st = 0.0
		1: # the scorplings born, one by one, climbing up onto her back
			_target = _pos
			if _st > 1.4 and _born_left > 0:
				_st = 0.0
				_born_left -= 1
				_scorpling()
			if _born_left <= 0 and _st > 2.0:
				for i: int in [0, 1]:
					_pose_foot[i] = null
				_lift = 0.0
				_mode = "carry"
				_carry_t = 50.0


func _scorpling() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	parent.add_child(y)
	y.call("place", _pos, _yaw + rng.randf_range(-PI, PI))
	y.set("height", height)
	y.call("ride", self, rng.randf_range(40.0, 55.0))
	brood.append(y)


func _process(dt: float) -> void:
	if _mother != null:
		_ride(dt)
		return
	super(dt)


## (A scorpling) up from under her onto her back, and carried; then down,
## and off.
func ride(mother: Node3D, secs := 45.0) -> void:
	_mother = mother
	_ride_t = secs
	_climb = 0.0
	_ride_at = Vector3(rng.randf_range(-3.2, 3.2), 2.3, rng.randf_range(1.0, 16.0))


func _ride(dt: float) -> void:
	_t += dt
	_ride_t -= dt
	if not is_instance_valid(_mother) or _ride_t <= 0.0:
		var m := _mother
		_mother = null
		for i in _pose_foot.size():
			_pose_foot[i] = null
		if is_instance_valid(m):
			var p: Vector3 = m.get("_pos")
			var a := rng.randf() * TAU
			place(p + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.03, 0.06), a)
			wander(p, 0.15)
			grow(0.6, 200.0)
		return
	_climb = minf(_climb + dt / 1.6, 1.0)
	var c := _climb * _climb * (3.0 - 2.0 * _climb)
	# (from under her, out round her side, up onto her back)
	var side := signf(_ride_at.x) if _ride_at.x != 0.0 else 1.0
	var under := OPERCULUM + Vector3(0.0, -1.0, 0.5)
	var by := Vector3(5.5 * side, -1.0, _ride_at.z)
	var at := under.lerp(by, clampf(c * 2.0, 0.0, 1.0)).lerp(_ride_at, clampf(c * 2.0 - 1.0, 0.0, 1.0))
	var g: Vector3 = _mother.call("_out", at)
	var mb: Basis = _mother.transform.basis
	transform = Transform3D(mb * Basis(Vector3.UP, _yaw * 0.2), g + mb.y * body_h * MM * size * 0.5)
	_body.scale = Vector3.ONE * MM * size
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var sd := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		_pose_foot[i] = Vector3(hm.x * sd * 0.6, -body_h * 0.7, hm.y * 0.8 + sin(_t * 9.0 + i) * (1.0 - _climb) * 1.5)
	_tail_ask = TAIL_REST
	_pose(dt)
	_pose_legs()


# --- mating: the promenade a deux --------------------------------------------------

func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, -46.0) # (before her, facing her)


func _mating(dt: float) -> void:
	_mate_t += dt
	if _mate == null or not is_instance_valid(_mate):
		_end_mate()
		return
	var her: Node3D = _mate
	if _mate_role == "female": # (still, or led: her place his to set; her chelae in his)
		_target = _pos
		if _mate.get("_mate_role") != "male":
			_end_mate()
			return
		if _mate.get("_mate_stage") in ["dance", "deposit", "draw"]:
			_palp_ask = [PALP_REACH, PALP_REACH]
			_grip = 1.0
		else:
			_palp_ask = [PALP_REST, PALP_REST]
		_tail_ask = TAIL_REST
		return
	_tail_ask = TAIL_WALK if _speed > 0.004 else TAIL_REST
	match _mate_stage:
		"seek": # (before her, facing her)
			var to: Vector3 = her.call("_out", _mate_approach())
			_target = Vector3(to.x, _pos.y, to.z)
			if Vector2(to.x - _pos.x, to.z - _pos.z).length() < 0.006:
				var at: Vector3 = her.get("_pos")
				_turn_to = atan2(-(at.x - _pos.x), -(at.z - _pos.z))
				_mate_stage = "court"
				_mate_t = 0.0
		"court": # (juddering: shuddering, his body rocked)
			_target = _pos
			_judder = 1.0 if fmod(_mate_t, 1.2) < 0.4 else 0.0
			if _mate_t > 3.0 and _turn_to == INF:
				_judder = 0.0
				_mate_stage = "dance"
				_mate_t = 0.0
				_dance_h = Vector3(-sin(_yaw), 0.0, -cos(_yaw))
				_dance_at = _pos
				var hp: Vector3 = her.get("_pos")
				_gap = Vector2(hp.x - _pos.x, hp.z - _pos.z).length()
		"dance": # (to and fro, he leading backward, she following; turning)
			_palp_ask = [PALP_REACH, PALP_REACH]
			_grip = 1.0
			_dance_h = _dance_h.rotated(Vector3.UP, 0.12 * dt * sin(_mate_t * 0.31))
			var off := -_dance_h * sin(_mate_t * 0.9) * 0.02 * size
			_lead(_dance_at + off, dt)
			if _mate_t > 7.0 and _mate_t < 9.0: # (his sting into the joint of her pedipalp)
				_tail_ask = TAIL_STING
				_tail_rate = 4.0
			if _mate_t > mate_secs:
				_mate_stage = "deposit"
				_mate_t = 0.0
		"deposit": # (his spermatophore set on the ground under him)
			_palp_ask = [PALP_REACH, PALP_REACH]
			_grip = 1.0
			_lead(_pos, dt)
			_pitch = lerpf(_pitch, -0.12, 1.0 - exp(-4.0 * dt))
			if _spermatophore == null:
				var spf := Spermatophore.new()
				get_parent().add_child(spf)
				var o := _out(OPERCULUM)
				spf.position = Vector3(o.x, _ground(o.x, o.z), o.z)
				spf.rotation.y = _yaw
				spf.scale = Vector3.ONE * size
				_spermatophore = spf
			_spermatophore.set("built", clampf(_mate_t / 3.0, 0.0, 1.0))
			if _mate_t > 3.2:
				_pitch = 0.0
				_mate_stage = "draw"
				_mate_t = 0.0
				_dance_at = _pos
		"draw": # (backing, drawing her over it, her opening onto it)
			_palp_ask = [PALP_REACH, PALP_REACH]
			_grip = 1.0
			var s := _spermatophore.position if is_instance_valid(_spermatophore) else _pos
			var hop: Vector3 = her.call("_out", OPERCULUM)
			var need := Vector3(s.x - hop.x, 0.0, s.z - hop.z)
			var k := clampf(_mate_t / 3.0, 0.0, 1.0)
			_lead(_dance_at + need * k, dt)
			if _mate_t > 4.5:
				if is_instance_valid(_spermatophore):
					_spermatophore.set("used", true)
				_spermatophore = null
				# (let go, and off fast)
				var away := -_dance_h
				var was := _mate
				_end_mate()
				if is_instance_valid(was) and was.get("_mate_role") != "":
					was.call("_end_mate")
				wander(_pos + away * 0.12, 0.05)
				_target = _pos + away * 0.12
				_pace = walk_speed * 2.0 # (hurrying: till it next stops)
				_wait = 3.0


## (The promenade's step.) Him to `at`, facing his way; her kept facing him
## at her distance, her chelae in his.
func _lead(at: Vector3, dt: float) -> void:
	var her: Node3D = _mate
	var me := _pos.lerp(Vector3(at.x, _pos.y, at.z), 1.0 - exp(-3.0 * dt))
	_pos = Vector3(me.x, _ground(me.x, me.z), me.z)
	_target = _pos
	_speed = 0.0
	_yaw = atan2(-_dance_h.x, -_dance_h.z)
	var hp := _pos + _dance_h * _gap
	her.set("_pos", Vector3(hp.x, float(her.call("_ground", hp.x, hp.z)), hp.z))
	her.set("_target", her.get("_pos"))
	her.set("_yaw", _yaw + PI)


func _after_mate() -> void:
	_judder = 0.0
	_grip = 0.0
	if not male:
		wander(_pos, 0.08)


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	# its colour: a scorpling's white, yellowing as it grows
	if young:
		var k := clampf((size - 0.17) / 0.4, 0.0, 1.0)
		for e: Array in _mats:
			var c: Color = Color(0.93, 0.92, 0.86).lerp(e[1], k)
			if e[0] is StandardMaterial3D:
				(e[0] as StandardMaterial3D).albedo_color = c
			else:
				(e[0] as ShaderMaterial).set_shader_parameter("base", c)
	# the tail, easing to what's asked
	for j in _tail.size():
		var now: Array = _tail_k[j]
		var ask: Array = _tail_ask[j]
		var a := lerpf(float(now[0]), float(ask[0]), 1.0 - exp(-_tail_rate * dt))
		var r := lerpf(float(now[1]), float(ask[1]), 1.0 - exp(-_tail_rate * dt))
		_tail_k[j] = [a, r]
		_tail[j].rotation = Vector3(a, r, 0.0)
	# the pedipalps
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		var now: Array = _palp_now[s]
		var ask: Array = _palp_ask[s]
		var n := []
		for j in 3:
			n.append(lerpf(float(now[j]), float(ask[j]), 1.0 - exp(-_palp_rate * dt)))
		_palp_now[s] = n
		var parts: Array = _palps[s]
		(parts[0] as Node3D).rotation = Vector3(0.12, float(n[0]) * side, 0.0)
		(parts[1] as Node3D).rotation = Vector3(0.0, float(n[1]) * side, 0.0)
		(parts[2] as Node3D).rotation = Vector3(-0.05, float(n[2]) * side, 0.0)
		(parts[3] as Node3D).rotation = Vector3(0.0, -side * 0.45 * (1.0 - _grip), 0.0)
	# the chelicerae tearing
	for c in _chel:
		var sd: float = c.get_meta("side")
		c.rotation = Vector3(0.0, sd * 0.3 * _chew * sin(_t * 8.0 + sd), 0.0)
		c.position.z = -8.6 - 0.5 * _chew * maxf(sin(_t * 8.0 + sd), 0.0)
	# juddering
	if _judder > 0.0 or absf(_roll) > 0.001:
		_roll = 0.06 * _judder * sin(_t * 40.0)
	# the prey in its chelae (or at its mouth)
	if _held and is_instance_valid(_prey):
		var c0 := (_palps[0] as Array)[2] as Node3D
		var c1 := (_palps[1] as Array)[2] as Node3D
		_prey.global_position = (c0.global_transform * Vector3(0.0, 0.0, -7.0)).lerp(c1.global_transform * Vector3(0.0, 0.0, -7.0), 0.5) + Vector3.DOWN * 0.004 * size


# --- steering (pilot.gd): its behaviours ----------------------------------------

## hunt {prey}, sting {at}, birth {n} (a female's), mate {partner}.
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["hunt"])
	return PackedStringArray(["hunt", "sting", "mate"]) if male else PackedStringArray(["hunt", "sting", "birth", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var prey: Node3D = args.get("prey")
			if prey == null:
				return false
			hunt(prey)
		"sting":
			sting(args.get("at", _pos + _p_heading() * 0.03))
		"birth":
			if young or male:
				return false
			birth(int(args.get("n", 12)))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"hunt", "sting", "birth":
			return _mode != name
	return false


func _p_mobile() -> bool:
	return _mother == null and _mode != "birth"


func _piloted() -> void:
	if _mode in ["wander", "idle", "carry"]:
		_mode = "piloted"


## A scorpion's spermatophore (laid by the male in the promenade): a slender
## pale stalk standing up off the ground, leaning forward, its capsule at
## the top (built: how far out, 0..1); used, emptied, left; gone a while
## later.
class Spermatophore extends Node3D:
	var built := 0.0
	var used := false
	var _stalk: MeshInstance3D
	var _cap: MeshInstance3D
	var _gone := 0.0

	func _ready() -> void:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.92, 0.85, 0.65, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.2
		var c := CylinderMesh.new()
		c.top_radius = 0.25
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = 6
		_stalk = MeshInstance3D.new()
		_stalk.mesh = c
		_stalk.material_override = m
		add_child(_stalk)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 8
		s.rings = 5
		_cap = MeshInstance3D.new()
		_cap.mesh = s
		_cap.material_override = m
		add_child(_cap)

	func _process(dt: float) -> void:
		var h := 0.01 * built
		_stalk.scale = Vector3(0.0018, maxf(h, 1e-5), 0.0018)
		_stalk.position = Vector3(0.0, h * 0.5, -h * 0.15)
		_stalk.rotation.x = -0.3
		_cap.scale = Vector3(0.0022, 0.002, 0.003) * (0.4 if used else 1.0) * built
		_cap.position = Vector3(0.0, h * 0.95, -h * 0.3)
		visible = built > 0.01
		if used:
			_gone += dt
			if _gone > 40.0:
				queue_free()
