extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A four-legged hunter, life size (its model in mm, size 0.5 of the
## walker's doubled scale), the make the red fox and the bobcat share
## (RedFox, Bobcat: each its shape, coat and ways, S). Its legs digitigrade:
## the shoulder or hip, the upper leg, the lower, the long metapodial (the
## hock high behind, the wrist low before), the paw, standing on its toes;
## the elbows back, the stifles forward (or, S.plantigrade, a bear's: on its
## whole sole, the heel down: Ursid). Its gaits by its speed: walking
## (each foot in turn, a hind then the fore on its side), trotting (the
## diagonals together), galloping (the hinds, a moment's flight, the fores;
## the back flexing, the body rising and pitching); each foot planted where
## it's set down. Its head on its neck, turning to look, the ears turning,
## pricked, laid back; the jaw; its tail a chain, carried as it goes (low
## walking, out behind running, low stalking, curled round it sitting or
## asleep). Coats: shaders/render/carnivore.gdshader.
##
## - wander(centre, radius): walking, now and then trotting, stopping to
##   sniff the ground, to look, to sit; marking its ground
## - hunt(prey) (a Node3D; a creature with die(): killed): stalking (low,
##   slow, ears forward, freezing), then its species' attack (the fox's
##   pounce, high, diving nose first onto it; the bobcat's rush and
##   spring); caught in its jaws, eaten (crouched, tearing at it, it
##   shrinking away); missed, stalking again
## - eat(food): at it, tearing, chewing
## - groom(): sitting, licking a forepaw, washing its face, licking its
##   flank
## - sit(seconds), sleep(seconds): lying down, curled, its nose under its
##   tail, its sides rising and falling; then up, a stretch
## - mark(): its scent left (the fox squatting, the bobcat scraping)
## - birth(n, den): (a female's) in her den (Den: its species'), lying on her
##   side, the young born one by one, licked; nursing them; nurse(): back,
##   and nursing again. The young: born blind, helpless, wriggling to her;
##   growing, eyes open, up and about, playing (stalking, pouncing on one
##   another), following her
## - mate(her): its species' (the dogs' tie: Canid; the bobcat's nape bite)
## Steering (pilot.gd): act hunt {prey}, eat {food}, groom, sit {seconds},
## sleep {seconds}, mark, birth {n, den} (a female's), nurse, play (the
## young's), mate {partner}.

var S: Dictionary = {} ## the species' (its subclass's): shape, gaits, ways
var young := false
var home_den: Node3D ## her den (a female's)
var young_ones: Array[Node3D] = [] ## her young
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 1.0
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _prey: Node3D
var _prey_s := Vector3.ONE
var _held := false
var _born_left := 0
var _mother: Node3D # (a young one's)
var _sib: Node3D # (a young one at play: the one it's after)
# the gait
var _gphase := 0.0
var _gait_now := "stand"
var _planted: Array[bool] = []
var _lift_from: Array[Vector3] = []
var _accel := 3.0
# the pose
var _sit := 0.0
var _sit_to := 0.0
var _lie := 0.0
var _lie_to := 0.0
var _curl := 0.0 # (lying: curled up asleep)
var _side := 0.0 # (lying on her side, nursing)
var _stretch := 0.0
var _ears := 0.0
var _ears_to := 0.0
var _ear_turn := Vector2.ZERO
var _neck_to := Vector2.ZERO # (pitch, yaw)
var _neck_now := Vector2.ZERO
var _look_to := Vector2.ZERO
var _look_now := Vector2.ZERO
var _jaw_to := 0.0
var _chew := 0.0
var _lick := 0.0
var _sniff := 0.0
var _wiggle := 0.0
var _tail_k := [] # each joint now: [down, round]
var _tail_mode := "carry"
# the parts
var _torso: MeshInstance3D
var _neck: Node3D
var _head: Node3D
var _jaw: Node3D
var _ear_nodes: Array[Node3D] = []
var _tail: Array[Node3D] = []
var _legx: Array = [] # each leg: [metapodial, paw]
var _eyes: Array[MeshInstance3D] = []
var _lids: Array[MeshInstance3D] = []


## (The species calls it, S set.)
func _setup() -> void:
	var F: Dictionary = S.fore
	var H: Dictionary = S.hind
	legs = [
		{"hip": F.hip, "f": F.a, "t": F.b, "s": F.m, "p": F.p, "home": F.home, "dangle": F.hip + Vector3(0.0, -float(F.a) - float(F.b) * 0.6, -90.0), "pole": Vector3(0.1, 0.0, 1.0), "r": F.r, "femur_r": 1.7},
		{"hip": H.hip, "f": H.a, "t": H.b, "s": H.m, "p": H.p, "home": H.home, "dangle": H.hip + Vector3(0.0, -float(H.a) * 0.8, float(H.b) * 0.7), "pole": Vector3(0.1, 0.0, -1.0), "r": H.r, "femur_r": 1.9},
	]
	tripod = [[0, 3], [1, 2]]
	body_h = S.body_h
	walk_speed = S.walk
	stride = 200.0
	step_time = 0.2
	mate_secs = float(S.get("mate_secs", 20.0))
	for i in 4:
		_planted.append(true)
		_lift_from.append(Vector3.ZERO)
	for k in int((S.tail as Dictionary).n):
		_tail_k.append([0.0, 0.0])


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/carnivore.gdshader")
	m.set_shader_parameter("species", int(S.species))
	m.set_shader_parameter("part", part)
	m.set_shader_parameter("young", young)
	m.set_shader_parameter("along", along)
	m.set_shader_parameter("ear_len", float((S.ear as Dictionary).len))
	return m


func _mesh(m: Mesh, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _build() -> void:
	var body := _coat(0)
	var face := _coat(1)
	var sp := int(S.species)
	var fl := float(S.get("fur", [22.0, 20.0, 25.0, 40.0, 45.0, 55.0, 60.0][sp])) # (its coat's length, mm)
	var tl := float(S.get("tail_fur", [55.0, 25.0, 55.0, 70.0, 40.0, 45.0, 45.0][sp]))
	if young:
		fl *= 0.6
		tl *= 0.5
	_torso = _mesh(_loft(S.body, 2.0), body, _body)
	_fur_shells(_torso, fl, 10)
	# the muscle over its shoulder blades and its haunches
	var F: Dictionary = S.fore
	var H: Dictionary = S.hind
	for side: float in [-1.0, 1.0]:
		var fh: Vector3 = F.hip
		var hh: Vector3 = H.hip
		var sh := _part(Vector3(fh.x * side * 0.85, fh.y + float(F.a) * 0.3, fh.z + 10.0), Vector3(float(F.r) * 3.4, float(F.a) * 0.85, float(F.r) * 4.6), body)
		_fur_shells(sh, fl * 0.9, 8)
		var ha := _part(Vector3(hh.x * side * 0.9, hh.y + float(H.a) * 0.15, hh.z + 15.0), Vector3(float(H.r) * 3.8, float(H.a) * 0.9, float(H.r) * 5.0), body)
		_fur_shells(ha, fl * 0.9, 8)
	# the neck, rising from the chest; the head on it
	_neck = Node3D.new()
	_neck.position = S.neck_at
	_body.add_child(_neck)
	_fur_shells(_mesh(_loft(S.neck, 2.0), body, _neck), fl * 1.15, 10)
	_head = Node3D.new()
	_head.position = S.head_at
	_neck.add_child(_head)
	_fur_shells(_mesh(_loft(S.head, 2.0), face, _head), fl * 0.4, 6)
	_jaw = Node3D.new()
	_jaw.position = S.jaw_at
	_head.add_child(_jaw)
	_fur_shells(_mesh(_loft(S.jaw, 2.0), face, _jaw), fl * 0.35, 5)
	var jk: Array = S.jaw
	for side: float in [-1.0, 1.0]: # (the lips' dark line)
		var j0: Array = jk[0]
		var j1: Array = jk[jk.size() - 1]
		_stick(Vector3(float(j0[2]) * 0.85 * side, float(j0[1]) + float(j0[3]) * 0.7, float(j0[0])), Vector3(float(j1[2]) * 0.8 * side, float(j1[1]) + float(j1[3]) * 0.6, float(j1[0])), 1.6, _mat(Color(0.08, 0.06, 0.05), 0.5), _jaw)
	_part(Vector3(0.0, 4.0, -20.0), Vector3(30.0, 4.0, 60.0) * float(S.get("mouth", 1.0)), _mat(Color(0.55, 0.3, 0.3), 0.5), _jaw)
	var E: Dictionary = S.eye
	# (each eye set on the head's surface, bulging from it; the fur bare
	# round it)
	var es: Vector3 = E.size
	var eat: Vector3 = E.at
	eat.x = _surface_x(S.head, eat.z, eat.y) - es.x * 0.12
	face.set_shader_parameter("bare_a", Vector3(-eat.x, eat.y, eat.z))
	face.set_shader_parameter("bare_b", Vector3(eat.x, eat.y, eat.z))
	face.set_shader_parameter("bare_r", es.y * 0.85)
	for side: float in [-1.0, 1.0]:
		var at: Vector3 = eat
		var em := _mat(E.color, 0.04)
		em.clearcoat_enabled = true # (the cornea's wet gloss)
		em.clearcoat = 1.0
		var e := _part(Vector3(at.x * side, at.y, at.z), E.size, em, _head)
		_eyes.append(e)
		_part(Vector3((at.x - es.x * 0.2) * side, at.y, at.z), es * Vector3(1.0, 1.16, 1.16), _mat(Color(0.06, 0.05, 0.04), 0.6), _head) # (its rim, dark, just behind it)
		var pu := _part(Vector3((at.x + float((E.size as Vector3).x) * 0.42) * side, at.y, at.z - 1.0), Vector3(2.0, float((E.size as Vector3).y) * float(E.get("slit", 0.4)), float((E.size as Vector3).z) * 0.35), _mat(Color(0.02, 0.02, 0.02), 0.02), _head)
		pu.rotation.y = 0.0
		var lid := _part(Vector3(at.x * side, at.y, at.z) * 1.0, (E.size as Vector3) * 1.08, face, _head)
		lid.visible = false
		_lids.append(lid)
	var N: Dictionary = S.nose
	var nose := _mat(N.color, 0.25)
	nose.clearcoat_enabled = true # (the leather moist)
	nose.clearcoat = 0.7
	_part(N.at, N.size, nose, _head)
	var ns: Vector3 = N.size
	for side: float in [-1.0, 1.0]: # (the nostrils)
		_part((N.at as Vector3) + Vector3(ns.x * 0.22 * side, ns.y * 0.02, -ns.z * 0.4), Vector3(ns.x * 0.22, ns.y * 0.3, ns.z * 0.25), _mat(Color(0.01, 0.01, 0.01), 0.6), _head)
	_stick(Vector3(0.0, float((N.at as Vector3).y) - 12.0, float((N.at as Vector3).z) + 8.0), Vector3(0.0, float((N.at as Vector3).y) - 20.0, float((N.at as Vector3).z) + 12.0), 2.0, _mat(Color(0.12, 0.08, 0.06), 0.4), _head) # (the philtrum)
	# whiskers
	var wd := _mat(Color(0.9, 0.9, 0.88), 0.5)
	for side: float in [-1.0, 1.0]:
		var wp: Vector3 = N.at
		for k in 5:
			var a := deg_to_rad(-18.0 + 9.0 * k)
			var d := Vector3(side * cos(a), sin(a) * 0.4, 0.45).normalized()
			_stick(wp + Vector3(12.0 * side, -12.0, 20.0), wp + Vector3(12.0 * side, -12.0, 20.0) + d * float(S.get("whisker", 70.0)), 0.6, wd, _head)
	# the ears
	var R: Dictionary = S.ear
	var ear_m := _coat(5)
	for side: float in [-1.0, 1.0]:
		var en := Node3D.new()
		var at: Vector3 = R.at
		en.position = Vector3(at.x * side, at.y, at.z)
		_head.add_child(en)
		en.set_meta("side", side)
		_fur_shells(_mesh(_ear_mesh(float(R.len), float(R.width), float(R.get("point", 1.0))), ear_m, en), fl * 0.2, 4)
		if R.get("tuft", 0.0) > 0.0:
			_stick(Vector3(0.0, float(R.len) * 0.95, 0.0), Vector3(-3.0 * side, float(R.len) + float(R.tuft), 2.0), 2.2, _coat(7), en)
		_ear_nodes.append(en)
	# the face's own (a bobcat's ruff)
	for r: Array in S.get("ruff", []):
		for side: float in [-1.0, 1.0]:
			var at: Vector3 = r[0]
			_fur_shells(_part(Vector3(at.x * side, at.y, at.z), r[1], face, _head), fl * 1.3, 8)
	# the tail: a chain from the rump
	var T: Dictionary = S.tail
	var prev: Node3D = _body
	var radii: Array = T.radii
	for k in int(T.n):
		var n := Node3D.new()
		n.position = T.base if k == 0 else Vector3(0.0, 0.0, float(T.seg))
		prev.add_child(n)
		var r: float = radii[k]
		_fur_shells(_part(Vector3(0.0, 0.0, float(T.seg) * 0.5), Vector3(r * 2.0, r * 1.9, float(T.seg) * 1.5), _coat(6, (k + 0.5) / float(T.n)), n), tl, 10)
		_tail.append(n)
		prev = n
	# the legs: upper, lower, metapodial, the paw
	_build_legs(_coat(2), _coat(3))
	var paw := _coat(4)
	for i in 4:
		var mm := MeshInstance3D.new()
		mm.mesh = _cyl
		mm.material_override = _coat(3)
		_body.add_child(mm)
		mm.mesh = _sphere # (rounded, not a rod)
		var pw := _part(Vector3.ZERO, Vector3.ONE, paw)
		for k in 4: # (its toes' pads, and their claws)
			var x := (float(k) - 1.5) * 0.24
			_part(Vector3(x, -0.15, 0.36 - absf(x) * 0.3), Vector3(0.26, 0.6, 0.32), paw, pw)
			if not bool(S.get("plantigrade", false)):
				_stick(Vector3(x, -0.2, 0.5 - absf(x) * 0.3), Vector3(x * 1.05, -0.45, 0.62 - absf(x) * 0.3), 0.025, _mat(Color(0.12, 0.1, 0.08), 0.3), pw)
		_legx.append([mm, pw])
		(_leg_mesh[i][2] as MeshInstance3D).visible = false # (the walker's tarsus: the paw here)
		(_leg_mesh[i][1] as MeshInstance3D).mesh = _sphere # (the lower leg rounded, tapering)
	_build_extra()


## (The species' own parts, if any.)
func _build_extra() -> void:
	pass


## An ear (mm: up its own y, len long, width across its base; point: how
## pointed), open forward (-z), its back +z.
static func _ear_mesh(len_: float, width: float, point: float) -> ArrayMesh:
	const RINGS := 7
	const ROUND := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := func(i: int, k: int) -> Array:
		var t := float(i) / RINGS
		var hw := width * 0.5 * pow(1.0 - t, point) + 1.0
		var a := TAU * float(k % ROUND) / ROUND
		var x := sin(a) * hw
		var z := cos(a) * maxf(hw * 0.22, 2.0)
		z -= absf(sin(a)) * hw * 0.35 * (1.0 - absf(cos(a))) # (cupped)
		return [Vector3(x, t * len_, z), Vector3(sin(a), 0.2, cos(a)).normalized()]
	for i in RINGS:
		for k in ROUND:
			var q := [ring.call(i, k), ring.call(i + 1, k), ring.call(i + 1, k + 1), ring.call(i, k + 1)]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for c: int in tri:
					var v: Array = q[c]
					st.set_normal(v[1])
					st.add_vertex(v[0])
	return st.commit()


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_pace = -1.0
	_sit_to = 0.0
	_lie_to = 0.0


func hunt(prey: Node3D) -> void:
	if prey == null or not is_instance_valid(prey):
		return
	_mode = "hunt"
	_prey = prey
	_prey_s = prey.scale
	_held = false
	_stage = 0
	_st = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func eat(food: Node3D) -> void:
	if food == null or not is_instance_valid(food):
		return
	_mode = "hunt"
	_prey = food
	_prey_s = food.scale
	_held = false
	_stage = 5 # (straight to it, to eat)
	_st = 0.0


func groom() -> void:
	_mode = "groom"
	_st = 0.0


func sit(secs := 8.0) -> void:
	_mode = "sit"
	_st = 0.0
	_wait = secs


func sleep(secs := 20.0) -> void:
	_mode = "sleep"
	_st = 0.0
	_wait = secs


func mark() -> void:
	_mode = "mark"
	_st = 0.0


## (A female's.) The young born in her den (or where she is): n.
func birth(n := 4, den_: Node3D = null) -> void:
	if young or male:
		return
	if den_ != null:
		home_den = den_
	_mode = "birth"
	_born_left = n
	_stage = 0
	_st = 0.0


## (A female's.) Back to her young, lying on her side, nursing them.
func nurse() -> void:
	if young_ones.is_empty():
		return
	_mode = "nurse"
	_stage = 0
	_st = 0.0


## (A young one's.) After one of the others, a stalk and a pounce.
func play() -> void:
	if not young:
		return
	var best: Node3D = null
	for c in get_parent().get_children():
		if c != self and c.get_script() == get_script() and bool(c.get("young")) and float(c.get("size")) >= 0.2:
			if best == null or (c as Node3D).position.distance_to(position) < best.position.distance_to(position):
				best = c
	if best == null:
		return
	_mode = "play"
	_sib = best
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_lick = move_toward(_lick, 0.0, dt * 2.0)
	_sniff = move_toward(_sniff, 0.0, dt * 2.0)
	_wiggle = move_toward(_wiggle, 0.0, dt * 3.0)
	_stretch = move_toward(_stretch, 0.0, dt * 0.8)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_tail_mode = "carry"
	if _pace > 0.0 and _mode not in ["hunt", "play", "nurse"]:
		_pace = -1.0
	if young and size < 0.2:
		_helpless(dt)
		return
	match _mode:
		"wander":
			if _wait <= 0.0:
				var r := rng.randf()
				if r < 0.2: # (stopping, nose down, sniffing)
					_target = _pos
					_wait = rng.randf_range(2.0, 4.0)
					_stage = 1
				elif r < 0.3 and not young:
					sit(rng.randf_range(4.0, 9.0))
					return
				elif r < 0.36 and not young:
					mark()
					return
				elif r < 0.45 and young:
					play()
					return
				else:
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_pace = float(S.trot) * lerpf(0.35, 1.0, size) if rng.randf() < 0.3 else -1.0
					_wait = rng.randf_range(3.0, 7.0)
					_stage = 0
					_look_to = Vector2(0.0, rng.randf_range(-0.4, 0.4))
			if _stage == 1:
				_neck_to = Vector2(-0.7, 0.0)
				_sniff = 1.0
			elif _speed < 0.05 and rng.randf() < dt * 0.3:
				_look_to = Vector2(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.8, 0.8))
		"hunt":
			_hunt(dt)
		"groom":
			_target = _pos
			_sit_to = 1.0
			var ph := fmod(_st, 9.0)
			if ph < 3.0: # (a forepaw licked)
				_lick = 1.0
				_neck_to = Vector2(-0.35, 0.0)
			elif ph < 6.0: # (the face washed)
				_lick = 0.6
				_neck_to = Vector2(-0.1, 0.2 * sin(_st * 2.0))
			else: # (a flank licked, the head round)
				_lick = 1.0
				_neck_to = Vector2(-0.4, 1.4)
			if _st > 9.0:
				_sit_to = 0.0
				wander(_home_spot(), _radius)
		"sit":
			_target = _pos
			_sit_to = 1.0
			_tail_mode = "wrap"
			if rng.randf() < dt * 0.4:
				_look_to = Vector2(rng.randf_range(-0.2, 0.25), rng.randf_range(-0.9, 0.9))
			if _wait <= 0.0:
				_sit_to = 0.0
				wander(_home_spot(), _radius)
		"sleep":
			_target = _pos
			_lie_to = 1.0
			_curl = move_toward(_curl, 1.0, dt * 0.5)
			_tail_mode = "curl"
			_ears_to = -0.3
			if _wait <= 0.0:
				_curl = move_toward(_curl, 0.0, dt)
				_lie_to = 0.0
				if _lie < 0.05:
					_stretch = 1.0
					wander(_home_spot(), _radius)
		"mark":
			_target = _pos
			_mark(dt)
			if _st > 3.0:
				wander(_home_spot(), _radius)
		"birth":
			_birth(dt)
		"nurse":
			_nurse(dt)
		"play":
			_play(dt)
		"nursing": # (a young one's: at her belly, lying, suckling)
			if is_instance_valid(_mother):
				var belly: Vector3 = _mother.call("_out", Vector3(-float(S.body_w) * 0.9, -float(_mother.get("body_h")), rng.randf_range(-40.0, 60.0) if _stage == 0 else 0.0))
				_stage = 1
				if _pos.distance_to(belly) > 0.08:
					_target = belly
				else:
					_target = _pos
					_lie_to = 1.0
					_neck_to = Vector2(-0.2, 0.0)
					_jaw_to = 0.1 * maxf(sin(_t * 5.0), 0.0)
				if _mother.get("_mode") != "nurse":
					_mode = "follow"
			else:
				_mode = "wander"
		"follow":
			if is_instance_valid(_mother):
				var mp: Vector3 = _mother.get("_pos")
				if _pos.distance_to(mp) > 0.4:
					_target = mp
			else:
				wander(_pos, 0.5)
	if _mode != "sleep":
		_curl = move_toward(_curl, 0.0, dt)
	if _mode not in ["sleep", "nurse", "birth", "nursing"]:
		_lie_to = 0.0
		_side = move_toward(_side, 0.0, dt)


## (Where it's at home: its den's mouth, or round its centre.)
func _home_spot() -> Vector3:
	return _centre if _centre != Vector3.ZERO else _pos


## (The species: its way of marking, posed.)
func _mark(_dt: float) -> void:
	pass


## The hunt: to it, stalking it, its species' attack; caught, eaten.
func _hunt(dt: float) -> void:
	if not is_instance_valid(_prey):
		_held = false
		wander(_home_spot(), _radius)
		return
	var p := _prey.global_position
	var to := p - _pos
	to.y = 0.0
	var d := to.length()
	var stalk_from := float(S.stalk_from) * size / 0.5
	var spring := float(S.spring) * size / 0.5
	match _stage:
		0: # to it, walking
			_target = p - to.normalized() * stalk_from * 0.9
			_ears_to = 1.0
			_look_to = Vector2(-0.1, 0.0)
			if d < stalk_from:
				_stage = 1
				_st = 0.0
		1: # stalking: low, slow, ears forward, its eyes on it
			_crouch = move_toward(_crouch, float(S.stalk_crouch), dt * 2.0)
			_target = p - to.normalized() * spring * 0.95
			_pace = float(S.walk) * 0.25 * lerpf(0.35, 1.0, size)
			_ears_to = 1.0
			_tail_mode = "low"
			_neck_to = Vector2(float(S.get("stalk_neck", -0.3)), 0.0)
			if d < spring * 1.05:
				_stage = 2
				_st = 0.0
				_pace = -1.0
		2: # still: watching (the fox listening, its head on one side; the
			# bobcat's hindquarters treading)
			_target = _pos
			_turn_to = atan2(-to.x, -to.z)
			_crouch = move_toward(_crouch, float(S.stalk_crouch) * 1.1, dt * 2.0)
			_ears_to = 1.0
			_tail_mode = "low"
			_neck_to = Vector2(float(S.get("stalk_neck", -0.3)), 0.0)
			_attack_ready(dt)
			if _st > 2.0 and _turn_to == INF:
				_stage = 3
				_st = 0.0
		3: # its attack (the species')
			_tail_mode = "out"
			_ears_to = 1.0
			if _attack(dt, p, d):
				_stage = 4
				_st = 0.0
		4: # landed: caught it, or missed
			if not airborne and _st > 0.1:
				var nose := _out(Vector3(0.0, -body_h, float(S.mouth_z)))
				if Vector2(nose.x - p.x, nose.z - p.z).length() < 0.35 * size / 0.5 + 0.05:
					if _prey.has_method("die"):
						_prey.call("die")
					_prey.set_process(false)
					_held = true
					_stage = 5
					_st = 0.0
				else:
					_stage = 1 # (missed: after it again)
					_st = 0.0
		5: # to its food, then eating: crouched over it, tearing, chewing
			_crouch = move_toward(_crouch, float(S.eat_crouch), dt)
			if not _held:
				_target = p - to.normalized() * float(S.mouth_z) * -MM * size * 0.9
				if d < -float(S.mouth_z) * MM * size * 1.1 and _speed < 0.05:
					_target = _pos
					_turn_to = atan2(-to.x, -to.z)
					_stage = 6
					_st = 0.0
			else:
				_held = false
				var lay := _out(Vector3(0.0, -body_h, float(S.mouth_z) - 40.0))
				_prey.global_position = Vector3(lay.x, _ground(lay.x, lay.z), lay.z)
				_stage = 6
				_st = 0.0
		6:
			_target = _pos
			_neck_to = Vector2(-0.95, 0.0)
			_look_to = Vector2(-0.3 + 0.25 * maxf(sin(_st * 2.3), 0.0), 0.25 * sin(_st * 1.7)) # (tearing: pulling up and to the side)
			_chew = 1.0
			_jaw_to = 0.3 * maxf(sin(_st * 6.0), 0.0)
			_prey.scale = _prey_s * maxf(1.0 - _st / 15.0, 0.05)
			if _st > 15.0:
				_prey.queue_free()
				_prey = null
				groom()


## (The species: getting ready to spring, still; and its attack, each frame:
## true once it's away, in the air.)
func _attack_ready(_dt: float) -> void:
	pass


func _attack(_dt: float, p: Vector3, _d: float) -> bool:
	_leap(p, 0.6)
	return true


func _on_landed() -> void:
	_crouch = 0.0


func _birth(dt: float) -> void:
	var at := home_den.position if is_instance_valid(home_den) else _pos
	match _stage:
		0: # to her den
			_target = at
			if _pos.distance_to(at) < 0.15 and _speed < 0.05:
				_stage = 1
				_st = 0.0
		1: # lying on her side in it, labouring; each born, licked
			_target = _pos
			_lie_to = 1.0
			_side = move_toward(_side, 1.0, dt * 0.6)
			_neck_to = Vector2(-0.4, 1.5)
			_lick = 0.7
			if _st > 3.5 and _born_left > 0:
				_born_left -= 1
				_st = 0.0
				_young_one()
			if _born_left <= 0 and _st > 3.0:
				_mode = "nurse"
				_stage = 1
				_st = 0.0


func _young_one() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	parent.add_child(y)
	var k := young_ones.size()
	var belly := _out(Vector3(-float(S.body_w) * 0.9, -body_h, -60.0 + 70.0 * k))
	y.call("place", Vector3(belly.x, _pos.y, belly.z), _yaw + PI * 0.5 + rng.randf_range(-0.5, 0.5))
	y.set("height", height)
	y.set("_mother", self)
	y.call("grow", 0.5, 400.0)
	young_ones.append(y)


func _nurse(dt: float) -> void:
	var at := home_den.position if is_instance_valid(home_den) else _pos
	match _stage:
		0:
			_target = at
			if _pos.distance_to(at) < 0.15:
				_stage = 1
				_st = 0.0
		1: # (on her side, her young at her belly)
			_target = _pos
			_lie_to = 1.0
			_side = move_toward(_side, 1.0, dt * 0.6)
			_neck_to = Vector2(-0.3, 0.6 * sin(_st * 0.2))
			for y in young_ones:
				if is_instance_valid(y) and float(y.get("size")) >= 0.2 and y.get("_mode") not in ["nursing"]:
					y.set("_mode", "nursing")
			if _st > 25.0:
				for y in young_ones:
					if is_instance_valid(y) and float(y.get("size")) >= 0.2:
						y.call("wander", at, 0.6)
				_lie_to = 0.0
				wander(at + Vector3(0.8, 0.0, 0.5), 1.2)


## (A newborn: blind, helpless, wriggling to its mother's belly; lying.)
func _helpless(dt: float) -> void:
	_lie_to = 1.0
	_ears_to = -0.6
	for l in _lids:
		l.visible = size < 0.17 # (its eyes opening as it grows)
	_pace = float(S.walk) * 0.05
	if is_instance_valid(_mother):
		var belly: Vector3 = _mother.call("_out", Vector3(-float(S.body_w) * 0.8, -float(_mother.get("body_h")), 0.0))
		_target = belly if _pos.distance_to(belly) > 0.05 else _pos
	else:
		_target = _pos
	_neck_to = Vector2(-0.2 + 0.2 * sin(_t * 3.0), 0.4 * sin(_t * 1.3))
	_tail_mode = "low"
	_side = move_toward(_side, 0.0, dt)
	if size >= 0.2:
		_lie_to = 0.0
		_pace = -1.0
		for l in _lids:
			l.visible = false
		_mode = "follow" if is_instance_valid(_mother) else "wander"
		_centre = _pos


func _play(dt: float) -> void:
	if not is_instance_valid(_sib):
		wander(_pos, 0.6)
		return
	var p: Vector3 = _sib.get("_pos")
	var to := p - _pos
	to.y = 0.0
	match _stage:
		0: # (low, eyes on it, creeping)
			_crouch = move_toward(_crouch, 0.5, dt * 2.0)
			_target = p - to.normalized() * 0.18
			_pace = float(S.walk) * 0.3
			_ears_to = 1.0
			if to.length() < 0.25:
				_stage = 1
				_st = 0.0
		1: # (a wiggle, a pounce)
			_target = _pos
			_wiggle = 1.0
			if _st > 0.8 and not airborne:
				_crouch = 0.0
				_leap(p, 0.7)
				_stage = 2
				_st = 0.0
		2: # (tumbling: rolled over, back up)
			if not airborne:
				_roll = lerpf(_roll, PI * 0.6 * sin(_st * 4.0), 1.0 - exp(-6.0 * dt)) if _st < 1.5 else lerpf(_roll, 0.0, 1.0 - exp(-6.0 * dt))
				_target = _pos
				if _st > 2.2:
					_roll = 0.0
					_pace = -1.0
					_mode = "follow" if is_instance_valid(_mother) else "wander"


# --- the motor: its walk (its gaits' pace), its gait ------------------------------

func _walk(dt: float) -> void:
	var to := _target - _pos
	to.y = 0.0
	var d := to.length()
	var want := 0.0
	if _turn_to != INF:
		var tt := wrapf(_turn_to - _yaw, -PI, PI)
		_yaw += clampf(tt, -3.0 * dt, 3.0 * dt)
		if absf(tt) < 0.02:
			_turn_to = INF
	elif d > 0.02 * size:
		var a := atan2(-to.x, -to.z)
		var turn := wrapf(a - _yaw, -PI, PI)
		_yaw += clampf(turn, -3.0 * dt, 3.0 * dt)
		var pace := _pace if _pace > 0.0 else walk_speed * lerpf(0.35, 1.0, size)
		want = minf(pace, d * 2.0) * clampf(1.0 - absf(turn) / 1.6, 0.0, 1.0)
	if _sit > 0.2 or _lie > 0.2:
		want = 0.0
	_speed = move_toward(_speed, want, dt * (_accel if want > _speed else _accel * 1.5))
	_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed * dt
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y


const GAITS := {
	# each foot's phase (left fore, right fore, left hind, right hind), the
	# share of a stride each is down, strides a second (slowest, fastest)
	"walk": [[0.25, 0.75, 0.0, 0.5], 0.62, Vector2(0.8, 1.5)],
	"trot": [[0.0, 0.5, 0.5, 0.0], 0.42, Vector2(1.8, 2.8)],
	"gallop": [[0.5, 0.6, 0.0, 0.1], 0.3, Vector2(2.6, 3.4)],
}


func _gait_of(speed: float) -> String:
	var k := lerpf(0.35, 1.0, size)
	if speed < 0.04:
		return "stand"
	if speed < float(S.walk) * k * 1.15:
		return "walk"
	if speed < float(S.trot) * k * 1.2:
		return "trot"
	return "gallop"


func _gait(dt: float) -> void:
	var g := _gait_of(_speed)
	var vel := Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed
	if g == "stand" or _sit > 0.1 or _lie > 0.1:
		# (standing: each foot set down under it, one at a time, if it's far)
		_gait_now = "stand"
		for i in 4:
			var h := _home(i)
			if _feet[i].distance_to(h) > 40.0 * MM * size:
				_feet[i] = _feet[i].lerp(h, 1.0 - exp(-8.0 * dt)) + Vector3.UP * 0.0
			_planted[i] = true
		return
	_gait_now = g
	var G: Array = GAITS[g]
	var offs: Array = G[0]
	var duty: float = G[1]
	var fr: Vector2 = G[2]
	var lo := 0.0
	var hi := 1.0
	match g:
		"walk":
			hi = float(S.walk)
		"trot":
			lo = float(S.walk)
			hi = float(S.trot)
		"gallop":
			lo = float(S.trot)
			hi = float(S.run)
	var k := lerpf(0.35, 1.0, size)
	var freq := lerpf(fr.x, fr.y, clampf((_speed / k - lo) / maxf(hi - lo, 0.01), 0.0, 1.0)) / sqrt(maxf(size / 0.5, 0.2))
	_gphase = fmod(_gphase + dt * freq, 1.0)
	var T := 1.0 / freq
	for i in 4:
		var q := fmod(_gphase + float(offs[i]), 1.0)
		if q < duty:
			if not _planted[i]: # (down: where it was reaching)
				_planted[i] = true
				_feet[i].y = _ground(_feet[i].x, _feet[i].z)
		else:
			if _planted[i]:
				_planted[i] = false
				_lift_from[i] = _feet[i]
			var s := (q - duty) / (1.0 - duty)
			var land := _home(i) + vel * (T * (1.0 - q) + T * duty * 0.5)
			land.y = _ground(land.x, land.z)
			var e := s * s * (3.0 - 2.0 * s)
			var arc := sin(PI * s) * (60.0 if g == "gallop" else 45.0) * MM * size
			_feet[i] = _lift_from[i].lerp(land, e) + Vector3.UP * arc


## Its legs: from each shoulder and hip, the upper leg, the lower, the long
## metapodial (the hock up behind; the wrist low before), the paw on its
## toes; a lifted paw curled back; sitting, the hocks down flat; lying, the
## forelegs out before it, the hind folded under.
func _pose_legs() -> void:
	var inv := (transform * _body.transform).affine_inverse()
	var up := (inv.basis * Vector3.UP).normalized()
	var fwd := inv.basis * (transform.basis * Vector3.FORWARD)
	fwd = (fwd - up * fwd.dot(up)).normalized()
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var hind := i >= 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var hip := Vector3(hp.x * side, hp.y, hp.z)
		var foot: Vector3
		if _pose_foot[i] != null:
			foot = _pose_foot[i]
		elif airborne:
			var dg: Vector3 = L.dangle
			foot = Vector3(dg.x * side, dg.y, dg.z)
		else:
			foot = inv * _feet[i]
		var p: float = L.p
		var m: float = L.s
		# (how far it's lifted: the paw curled back)
		var gy := -(body_h * (1.0 - 0.45 * _crouch) + _lift) # (the ground, near enough, under it)
		var lifted := clampf((foot.y - gy) / 50.0, 0.0, 1.0) if not airborne else 1.0
		var ball := foot + (-fwd * lerpf(0.95, 0.45, lifted) + up * lerpf(0.3, 0.9, lifted)).normalized() * p
		var mdir: Vector3
		if bool(S.get("plantigrade", false)):
			# (a bear's: flat on its sole, heel down; the heel lifting first
			# as the foot comes up; the forefoot's wrist a little raised)
			ball = foot + (-fwd * 0.97 + up * lerpf(0.05, 0.5, lifted)).normalized() * p
			mdir = (-fwd + up * lerpf(0.06 if hind else 0.22, 1.2, lifted)).normalized()
			mdir = mdir.lerp(-fwd, maxf(_sit, _lie) * (1.0 if hind else 0.5)).normalized()
		elif hind:
			mdir = (-fwd * lerpf(0.35, 0.7, lifted) + up).normalized()
			mdir = mdir.lerp(-fwd, maxf(_sit, _lie)).normalized() # (sitting, lying: the hock down)
		else:
			mdir = (-fwd * lerpf(0.1, 0.8, lifted) + up).normalized()
			mdir = mdir.lerp((-fwd * 0.2 + up * 0.15).normalized(), _lie).normalized() # (lying: the forearm down)
		var top := ball + mdir * m
		var pl: Vector3 = L.pole
		var knee := _knee(hip, top, L.f, L.t, Vector3(pl.x * side, pl.y, pl.z))
		var r: float = L.r
		var mesh: Array = _leg_mesh[i]
		(mesh[0] as MeshInstance3D).transform = _seg(hip, knee, r * float(L.femur_r))
		(mesh[1] as MeshInstance3D).transform = _seg(knee, top, r * (1.0 if hind else 0.85))
		(mesh[3] as MeshInstance3D).transform = Transform3D(Basis().scaled(Vector3.ONE * r * 1.6), knee)
		var x: Array = _legx[i]
		(x[0] as MeshInstance3D).transform = _seg(top, ball, r * (1.0 if bool(S.get("plantigrade", false)) else 0.7))
		var along := foot - ball
		var l := maxf(along.length(), 1.0)
		var z := along / l
		var xx := z.cross(up).normalized() if absf(z.dot(up)) < 0.95 else Vector3.RIGHT
		var yy := xx.cross(z).normalized()
		(x[1] as MeshInstance3D).transform = Transform3D(Basis(xx * r * 2.2, yy * r * 1.3, z * l * 1.5), (ball + foot) * 0.5)


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	var mounted := _mate_role == "male" and _mate_stage in ["mount", "joined", "part"]
	_sit = move_toward(_sit, _sit_to, dt * 1.8)
	_lie = move_toward(_lie, _lie_to, dt * 1.0)
	var s := _sit * _sit * (3.0 - 2.0 * _sit)
	var l := _lie * _lie * (3.0 - 2.0 * _lie)
	if not mounted and not airborne:
		# the gait's own: a trot's bob, a gallop's rise and pitch, a walk's sway
		var g := _gait_now
		var bob := 0.0
		var pitch := 0.0
		if g == "trot":
			bob = 8.0 * cos(_gphase * TAU * 2.0)
		elif g == "gallop":
			bob = 30.0 * sin(_gphase * TAU)
			pitch = 0.1 * sin(_gphase * TAU + 1.2)
		elif g == "walk":
			bob = 4.0 * cos(_gphase * TAU * 2.0)
		var sit_lift := -float(S.sit_drop) * s
		var lie_lift := (float(S.lie_h) - body_h * (1.0 - 0.45 * _crouch)) * l
		_lift = bob * (1.0 - maxf(s, l)) + sit_lift * (1.0 - l) + lie_lift
		_pitch = pitch + float(S.sit_pitch) * s * (1.0 - l) - 0.25 * _stretch * sin(PI * minf(_stretch * 1.5, 1.0))
		_roll = lerpf(_roll, 1.15 * _side * l + 0.25 * _curl * l, 1.0 - exp(-3.0 * dt)) if _mode not in ["play", "roll_over"] else _roll
		# (its feet, sitting: the forefeet straight down before it, the
		# hind folded; lying: the forelegs out before it, the hind under it)
		for i in 4:
			if not (s > 0.02 or l > 0.02):
				if _pose_foot[i] != null and _mode not in ["groom", "mark"]:
					_pose_foot[i] = null
				continue
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			var hm: Vector2 = L.home
			var gy := -(body_h * (1.0 - 0.45 * _crouch) + _lift)
			var sitp: Vector3
			var liep: Vector3
			if i < 2:
				sitp = _ground_at(Vector3(hm.x * side * 0.8, 0.0, hm.y - 20.0))
				liep = Vector3(hp.x * side * 0.8, gy + 15.0, hp.z - float(L.f) - 60.0)
			else:
				sitp = _ground_at(Vector3(hm.x * side * 1.2, 0.0, hp.z - float(L.s) * 0.6))
				liep = Vector3(hp.x * side * 1.4, gy + 20.0, hp.z - float(L.f) * 0.8)
			var curl_in := Vector3(-side * 40.0, 0.0, 60.0) * _curl if i < 2 else Vector3(0.0, 0.0, -40.0) * _curl
			_pose_foot[i] = sitp.lerp(liep + curl_in, l)
	elif airborne and not mounted:
		# in the air: diving nose first coming down, stretched out going up
		var climb := atan2(_vel.y, maxf(Vector2(_vel.x, _vel.z).length(), 0.01))
		_pitch = lerpf(_pitch, clampf(climb * 0.9, -1.0, 0.5), 1.0 - exp(-6.0 * dt))
		for i in 4:
			_pose_foot[i] = null
	# the neck and head: looking, sniffing, down to eat; turned back asleep
	var nt := _neck_to
	if l > 0.3 and _mode == "sleep":
		nt = Vector2(-0.4, 1.9 * _curl)
	nt.x -= float(S.sit_pitch) * s * 0.6 # (kept level, sitting)
	_neck_now = _neck_now.lerp(nt, 1.0 - exp(-4.0 * dt))
	_neck.rotation = Vector3(float(S.neck_pitch) + _neck_now.x * 0.6 - 0.35 * _stretch, _neck_now.y * 0.55, 0.0)
	_look_now = _look_now.lerp(_look_to, 1.0 - exp(-6.0 * dt))
	var sniff := 0.04 * _sniff * sin(_t * 18.0)
	var lick := 0.25 * _lick * maxf(sin(_t * 6.0), 0.0)
	var tilt := float(S.get("tilt", 0.0)) * (1.0 if _mode == "hunt" and _stage == 2 else 0.0)
	_head.rotation = Vector3(-float(S.neck_pitch) * 0.85 + _neck_now.x * 0.5 + _look_now.x + sniff - lick, _neck_now.y * 0.45 + _look_now.y, tilt * sin(_t * 0.7))
	_jaw.rotation.x = maxf(_jaw_to, 0.25 * _lick * maxf(sin(_t * 6.0), 0.0)) + 0.1 * _chew * maxf(sin(_t * 9.0), 0.0)
	# its forepaw licked, its face washed (sitting)
	if _mode == "groom" and s > 0.6:
		var ph := fmod(_st, 9.0)
		var mouth := _neck.transform * (_head.transform * Vector3(0.0, -40.0, float(S.mouth_z) * 0.3))
		if ph < 6.0:
			var wash := Vector3(25.0 * cos(_t * 5.0), 20.0 * sin(_t * 5.0), 0.0) * (1.0 if ph >= 3.0 else 0.0)
			_pose_foot[1] = mouth + Vector3(10.0, -25.0, 20.0) + wash
	# the ears
	_ears = move_toward(_ears, _ears_to, dt * 3.0)
	if rng.randf() < dt * 0.5:
		_ear_turn = Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
	for e in _ear_nodes:
		var side: float = e.get_meta("side")
		var turn := (_ear_turn.x if side < 0.0 else _ear_turn.y) * (1.0 - absf(_ears))
		var back := float((S.ear as Dictionary).get("tilt_back", 0.1)) - 0.25 * maxf(_ears, 0.0) + 1.0 * maxf(-_ears, 0.0)
		e.rotation = Vector3(back, turn - side * 0.6 * maxf(-_ears, 0.0), side * -float((S.ear as Dictionary).get("spread", 0.25)) * (1.0 + 0.8 * maxf(-_ears, 0.0)))
	# the tail
	_pose_tail(dt)
	# its prey in its jaws
	if _held and is_instance_valid(_prey):
		var jt := _jaw.global_transform
		var b := jt.basis.orthonormalized()
		_prey.global_transform = Transform3D(b * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(_prey_s), jt * Vector3(0.0, -10.0, float(S.mouth_z) * 0.4))


## A point in the body's mm on the ground under (x, z) (the body's).
func _ground_at(p: Vector3) -> Vector3:
	var to_world := transform * _body.transform
	var w := to_world * Vector3(p.x, 0.0, p.z)
	w.y = _ground(w.x, w.z)
	return to_world.affine_inverse() * w


func _pose_tail(dt: float) -> void:
	var n := _tail.size()
	var T: Dictionary = S.tail
	var carry: Array = T.carry # [down at its root, down along it]
	var g := _gait_now
	for k in n:
		var u := float(k) / maxf(n - 1, 1)
		var down: float
		var roll_r := 0.0
		match _tail_mode:
			"low":
				down = float(carry[0]) + 0.35 if k == 0 else float(carry[1]) * 0.5
				roll_r = 0.15 * sin(_t * 6.0 + k) * u * float(T.get("twitch", 0.0)) # (its tip twitching)
			"out":
				down = float(carry[0]) * 0.4 if k == 0 else 0.0
			"wag": # (wagging: held up a little, swept side to side)
				down = float(carry[0]) * 0.5 if k == 0 else float(carry[1]) * 0.3
				roll_r = 0.45 * sin(_t * 13.0) * (0.3 + 0.7 * u)
			"wrap": # (round its feet, sitting)
				down = 0.9 if k == 0 else 0.15
				roll_r = 0.45 * float(T.get("wrap", 1.0))
			"curl": # (round its nose, asleep)
				down = 0.6 if k == 0 else 0.05
				roll_r = 0.55 * float(T.get("wrap", 1.0))
			_:
				down = float(carry[0]) if k == 0 else float(carry[1])
				if g == "gallop":
					down *= 0.3
				roll_r = 0.12 * sin(_t * (3.0 if _speed > 0.05 else 0.8) - k * 0.6) * u
		if _wiggle > 0.0:
			roll_r += 0.25 * _wiggle * sin(_t * 12.0) * u
		var now: Array = _tail_k[k]
		var a := lerpf(float(now[0]), down, 1.0 - exp(-4.0 * dt))
		var r := lerpf(float(now[1]), roll_r, 1.0 - exp(-4.0 * dt))
		_tail_k[k] = [a, r]
		_tail[k].rotation = Vector3(a, r, 0.0)


# --- mating (the species say how; these its own) ---------------------------------

func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, float(S.body_len) * 1.2)


func _mate_leave() -> Vector3:
	return Vector3(float(S.body_w) * 3.0, -body_h, float(S.body_len) * 0.8)


func _court_secs() -> float:
	return 5.0


func _mating(dt: float) -> void:
	super(dt)
	_sit_to = 0.0
	_lie_to = 0.0
	if _mate_role == "male" and _mate_stage == "court":
		var nose: Vector3 = _mate.call("_out", Vector3(0.0, -body_h, float(S.body_len) * 0.65)) # (nose to her)
		_target = Vector3(nose.x, _pos.y, nose.z)
		_neck_to = Vector2(-0.4, 0.0)
		_sniff = 1.0
		_tail_mode = "out"


func _after_mate() -> void:
	wander(_home_spot(), _radius)


# --- steering (pilot.gd): its behaviours ----------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["hunt", "eat", "groom", "sit", "sleep"])
	if young:
		b.append("play")
		return b
	b.append_array(PackedStringArray(["mark", "mate"]))
	if not male:
		b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var p: Node3D = args.get("prey")
			if p == null:
				return false
			hunt(p)
		"eat":
			var f: Node3D = args.get("food")
			if f == null:
				return false
			eat(f)
		"groom":
			groom()
		"sit":
			sit(float(args.get("seconds", 8.0)))
		"sleep":
			sleep(float(args.get("seconds", 20.0)))
		"mark":
			mark()
		"play":
			play()
		"birth":
			if young or male:
				return false
			birth(int(args.get("n", 4)), args.get("den"))
		"nurse":
			if young_ones.is_empty():
				return false
			nurse()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"eat":
			return _mode != "hunt"
		"hunt", "groom", "sit", "sleep", "mark", "play", "birth", "nurse":
			return _mode != name
	return false


func _p_speed() -> float:
	return walk_speed * lerpf(0.35, 1.0, size)


func _p_reach() -> float:
	return 0.15 * size / 0.5 + 0.03


func _p_mobile() -> bool:
	return not (young and size < 0.2)


func _piloted() -> void:
	if _mode in ["wander", "idle", "sit", "follow"]:
		_mode = "piloted"
	_sit_to = 0.0
	_lie_to = 0.0
