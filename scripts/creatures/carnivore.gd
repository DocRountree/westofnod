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
##   spring); caught in its jaws, eaten (crouched, tearing at it, piece
##   by piece, each torn off and into its mouth, the carcass raw and bloody
##   where it's torn, blood run out under it: Meal); missed, stalking again
## - eat(food): at it, tearing, chewing
## - eat_at(at, seconds): eating at a point, the food left as it is (fruit
##   on a bush, ants at their nest, wasp grubs in a comb: whatever's drawn
##   by the hundred, or anyone's to pick): to it, its snout to it (down, or
##   up), licking and snapping, nosing about, a while
## - groom(): sitting, licking a forepaw, washing its face, licking its
##   flank
## - sit(seconds), sleep(seconds): lying down, curled, its nose under its
##   tail, its sides rising and falling; then up, a stretch (a species with
##   a home to sleep in, _sleep_home(): a bear's den, a beaver's lodge, to
##   it and in, out of sight, the while; then out, a stretch)
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

const SkinScript := preload("res://scripts/creatures/mammal_skin.gd")
const SculptScript := preload("res://scripts/creatures/sculpt_head.gd")
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
var _meal: Node3D # (its kill, eaten piece by piece: Meal)
const MealScript := preload("res://scripts/creatures/meal.gd")
var _lay := Vector3.ZERO # (where its kill's laid, to eat: the world's)
var _carry_to := Vector3.ZERO
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
var _skin: SkinScript # (its one skin: body, neck, head, jaw, legs, tail)
var _sb := {} # (its bones: name -> index)
var _joints: Array = [] # (each leg's joints now: hip, knee, wrist or hock, ball, toe; the body's mm)


## Leg i's joints, its foot at foot (the body's mm; up, fwd its up and
## forward there; lifted: how far the foot's off the ground, 0..1; folded:
## sitting or lying; lying): [hip, knee, wrist or hock, ball, foot].
func _leg_chain(i: int, foot: Vector3, up: Vector3, fwd: Vector3, lifted: float, folded := 0.0, lying := 0.0) -> Array:
	var L: Dictionary = legs[i / 2]
	var hind := i >= 2
	var side := 1.0 if i % 2 == 1 else -1.0
	var hp: Vector3 = L.hip
	var hip := Vector3(hp.x * side, hp.y, hp.z)
	var p: float = L.p
	var m: float = L.s
	var ball := foot + (-fwd * lerpf(0.95, 0.45, lifted) + up * lerpf(0.3, 0.9, lifted)).normalized() * p
	var mdir: Vector3
	if bool(S.get("plantigrade", false)):
		# (a bear's: flat on its sole, heel down; the heel lifting first
		# as the foot comes up; the forefoot's wrist a little raised)
		ball = foot + (-fwd * 0.97 + up * lerpf(0.05, 0.5, lifted)).normalized() * p
		mdir = (-fwd + up * lerpf(0.06 if hind else 0.22, 1.2, lifted)).normalized()
		mdir = mdir.lerp(-fwd, folded * (1.0 if hind else 0.5)).normalized()
	elif hind:
		mdir = (-fwd * lerpf(0.35, 0.7, lifted) + up).normalized()
		mdir = mdir.lerp(-fwd, folded).normalized() # (sitting, lying: the hock down)
	else:
		mdir = (-fwd * lerpf(0.1, 0.8, lifted) + up).normalized()
		mdir = mdir.lerp((-fwd * 0.2 + up * 0.15).normalized(), lying).normalized() # (lying: the forearm down)
	var top := ball + mdir * m
	var pl: Vector3 = L.pole
	var knee := _knee(hip, top, L.f, L.t, Vector3(pl.x * side, pl.y, pl.z))
	return [hip, knee, top, ball, foot]


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
	m.set_shader_parameter("hair", float(S.get("fur", 25.0)))
	m.set_shader_parameter("male", male and not young)
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
	var fl: float = float(S.fur) if S.has("fur") else [22.0, 20.0, 25.0, 40.0, 45.0, 55.0][sp] # (its coat's length, mm)
	var tl: float = float(S.tail_fur) if S.has("tail_fur") else [55.0, 25.0, 55.0, 70.0, 40.0, 45.0][sp]
	if young:
		fl *= 0.6
		tl *= 0.5
	# its body, neck, head, jaw, legs and tail: one skin (_build_skin, at
	# the end); here the joints its motor moves
	_neck = Node3D.new()
	_neck.position = S.neck_at
	_body.add_child(_neck)
	_head = Node3D.new()
	_head.position = S.head_at
	_neck.add_child(_head)
	var head_m := face
	_jaw = Node3D.new()
	_jaw.position = S.jaw_at
	_head.add_child(_jaw)
	var tl_ := minf(60.0 * float(S.get("mouth", 1.0)), absf(float((S.jaw as Array)[(S.jaw as Array).size() - 1][0])) * 0.85) # (its tongue no longer than its jaw)
	_part(Vector3(0.0, 4.0, -tl_ * 0.4), Vector3(30.0 * float(S.get("mouth", 1.0)), 4.0, tl_), _mat(Color(0.5, 0.28, 0.28), 0.5), _jaw) # (its tongue, the mouth's floor)
	var E: Dictionary = S.eye
	# (each eye set on the head's surface, bulging from it; the fur bare
	# round it)
	var es: Vector3 = E.size
	var eat: Vector3 = E.at
	eat.x = _surface_x(S.head, eat.z, eat.y) - es.x * 0.22
	var sculpt: Dictionary = S.get("sculpt", {})
	var look := Vector3(1.0, 0.0, -0.3).normalized()
	if not sculpt.is_empty(): # (seated in its socket, set back into it)
		var seat := SculptScript.eye_seat(sculpt, es.y * 0.5)
		eat = seat[0]
		look = seat[1]
	face.set_shader_parameter("bare_a", Vector3(-eat.x, eat.y, eat.z))
	face.set_shader_parameter("bare_b", Vector3(eat.x, eat.y, eat.z))
	face.set_shader_parameter("bare_r", es.y * 0.85)
	for m: ShaderMaterial in [head_m, body]: # (the skin's too: its face's coords the head's)
		m.set_shader_parameter("bare_a", Vector3(-eat.x, eat.y, eat.z))
		m.set_shader_parameter("bare_b", Vector3(eat.x, eat.y, eat.z))
		m.set_shader_parameter("bare_r", es.y * 0.85 if sculpt.is_empty() else float(sculpt.eye_r) * 0.95)
		if not sculpt.is_empty():
			var zt := float((sculpt.z as Array)[(sculpt.z as Array).size() - 1])
			m.set_shader_parameter("sculpt", true)
			m.set_shader_parameter("bare_a", (sculpt.eye as Vector3) * Vector3(-1.0, 1.0, 1.0))
			m.set_shader_parameter("bare_b", sculpt.eye)
			m.set_shader_parameter("nose_c", Vector3(0.0, (SculptScript._key(sculpt, "top", zt) + SculptScript._key(sculpt, "bot", zt)) * 0.5 + float(sculpt.nose_r) * 0.25, zt + float(sculpt.nose_r) * 0.4))
			m.set_shader_parameter("nose_r", sculpt.nose_r)
			var nc: Color = (S.nose as Dictionary).color
			m.set_shader_parameter("nose_col", Vector3(nc.r, nc.g, nc.b))
			m.set_shader_parameter("almond", float(sculpt.get("almond", 0.72)))
			m.set_shader_parameter("slant", float(sculpt.get("slant", 0.0)))
	for side: float in [-1.0, 1.0]:
		if not sculpt.is_empty():
			# (its eyeball: the iris's colour all its front, the pupil a slit
			# at its middle, the cornea glossy over it; set in its socket)
			var em2 := _mat(E.color, 0.04)
			em2.clearcoat_enabled = true
			em2.clearcoat = 0.8
			em2.clearcoat_roughness = 0.1
			# (an almond: long along its slant, narrow, just proud of its lids)
			var lk := Vector3(look.x * side, look.y, look.z)
			var er_ := float(sculpt.eye_r)
			var al := float(sculpt.get("almond", 0.6))
			var sl := float(sculpt.get("slant", 0.0))
			var surf := Vector3((sculpt.eye as Vector3).x * side, (sculpt.eye as Vector3).y, (sculpt.eye as Vector3).z)
			surf = SculptScript.point(sculpt, surf.z, atan2(surf.x, surf.y - (SculptScript._key(sculpt, "top", surf.z) + SculptScript._key(sculpt, "bot", surf.z)) * 0.5))
			var ec := surf - lk * er_ * 0.16
			var long_ := Vector3(0.0, sl, 1.0).normalized() # (its long axis: back and a little up)
			long_ = (long_ - lk * long_.dot(lk)).normalized()
			var upv := lk.cross(long_).normalized() * side
			var eb := MeshInstance3D.new()
			eb.mesh = _sphere
			eb.material_override = em2
			_head.add_child(eb)
			eb.transform = Transform3D(Basis(upv * er_ * 2.1 * al, lk * er_ * 0.75, long_ * er_ * 2.2), ec)
			if side > 0.0: # (its lids' line drawn round where it actually sits)
				for m: ShaderMaterial in [face, body]:
					m.set_shader_parameter("bare_b", surf)
					m.set_shader_parameter("bare_a", surf * Vector3(-1.0, 1.0, 1.0))
			_eyes.append(eb)
			var pu2 := MeshInstance3D.new()
			pu2.mesh = _sphere
			pu2.material_override = _mat(Color(0.01, 0.008, 0.006), 0.05)
			_head.add_child(pu2)
			var pup: Vector2 = sculpt.get("pupil", Vector2(1.8 * al, 0.26)) # (its height and length, of its eye's radius: a fox's slit, a dog's round, a deer's bar)
			pu2.transform = Transform3D(Basis(upv * er_ * pup.x, lk * er_ * 0.2, long_ * er_ * pup.y), ec + lk * er_ * 0.3)
			var lid2 := _part(ec, Vector3.ONE * er_ * 1.9, face, _head)
			lid2.visible = false
			_lids.append(lid2)
			continue
		var at: Vector3 = eat
		var em := _mat(E.color, 0.04)
		em.clearcoat_enabled = true # (the cornea's wet gloss)
		em.clearcoat = 0.55
		em.clearcoat_roughness = 0.25
		var e := _part(Vector3(at.x * side, at.y, at.z), E.size * Vector3(0.72, 0.8, 1.05), em, _head) # (almond: the lids over its top and bottom)
		_eyes.append(e)
		_part(Vector3((at.x - es.x * 0.12) * side, at.y, at.z), es * Vector3(0.72, 0.9, 1.2), _mat(Color(0.05, 0.04, 0.035), 0.55), _head) # (its lids' dark rim)
		var pu := _part(Vector3((at.x + es.x * 0.34) * side, at.y, at.z - 1.0), Vector3(1.5, es.y * float(E.get("slit", 0.4)), es.z * 0.32), _mat(Color(0.015, 0.012, 0.01), 0.02), _head)
		pu.rotation.y = 0.0
		var lid := _part(Vector3(at.x * side, at.y, at.z) * 1.0, (E.size as Vector3) * 1.08, face, _head)
		lid.visible = false
		_lids.append(lid)
	var N: Dictionary = S.nose
	if sculpt.is_empty():
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
	if not sculpt.is_empty(): # (a few, fine, from its whisker pads, curving back)
		var zt := float((sculpt.z as Array)[(sculpt.z as Array).size() - 1])
		var zw := zt + float(sculpt.eye_r) * 3.0
		var wdk := _mat(Color(0.14, 0.12, 0.1), 0.5)
		for side: float in [-1.0, 1.0]:
			for k in 6:
				var pz := zw + float(k % 3) * 4.0
				var phi := PI * (0.55 + 0.05 * float(k / 3)) * side
				var p0 := SculptScript.point(sculpt, pz, phi)
				var d := Vector3(side, -0.12 + 0.1 * float(k % 3), 0.55).normalized()
				var l := float(S.get("whisker", 70.0)) * (0.75 + 0.1 * float(k % 3))
				var p1 := p0 + d * l * 0.5
				var p2 := p1 + (d + Vector3(0.0, -0.18, 0.25)).normalized() * l * 0.5
				_stick(p0, p1, 0.16, wdk if k % 2 == 0 else wd, _head)
				_stick(p1, p2, 0.11, wdk if k % 2 == 0 else wd, _head)
	for side: float in ([] if not sculpt.is_empty() else [-1.0, 1.0]):
		var wp: Vector3 = N.at
		for k in 5:
			var a := deg_to_rad(-18.0 + 9.0 * k)
			var d := Vector3(side * cos(a), sin(a) * 0.4, 0.45).normalized()
			if float(S.get("whisker", 70.0)) > 0.0:
				_stick(wp + Vector3(12.0 * side, -12.0, 20.0), wp + Vector3(12.0 * side, -12.0, 20.0) + d * float(S.get("whisker", 70.0)), 0.22, wd, _head)
	# the ears
	var R: Dictionary = S.ear
	var ear_m := _coat(5)
	for side: float in [-1.0, 1.0]:
		var en := Node3D.new()
		var at: Vector3 = R.at
		en.position = Vector3(at.x * side, at.y - (5.0 if not sculpt.is_empty() else 0.0), at.z)
		_head.add_child(en)
		en.set_meta("side", side)
		_fur_shells(_mesh(_ear_mesh(float(R.len), float(R.width), float(R.get("point", 1.0)), 0.22 if sculpt.is_empty() else 0.34, 0.35 if sculpt.is_empty() else 0.6), ear_m, en), fl * 0.2, 4)
		if R.get("tuft", 0.0) > 0.0:
			_stick(Vector3(0.0, float(R.len) * 0.95, 0.0), Vector3(-3.0 * side, float(R.len) + float(R.tuft), 2.0), 1.5, _mat(Color(0.06, 0.05, 0.045), 0.6), en) # (its tufts black)
		_ear_nodes.append(en)
	# the face's own (a bobcat's ruff)
	for r: Array in []: # (a bobcat's ruff: painted on its face now, not blobs)
		for side: float in [-1.0, 1.0]:
			var at: Vector3 = r[0]
			_fur_shells(_part(Vector3(at.x * side, at.y, at.z), r[1], face, _head), fl * 1.3, 8)
	# the tail: a chain from the rump
	var T: Dictionary = S.tail
	var prev: Node3D = _body
	for k in int(T.n):
		var n := Node3D.new()
		n.position = T.base if k == 0 else Vector3(0.0, 0.0, float(T.seg))
		prev.add_child(n)
		_tail.append(n)
		prev = n
	# the legs: upper, lower, metapodial, the paw
	_build_legs(_coat(2), _coat(3))
	var paw := _coat(4)
	_joints.resize(4)
	for i in 4:
		var mm := MeshInstance3D.new()
		mm.mesh = _cyl
		mm.material_override = _coat(3)
		_body.add_child(mm)
		mm.mesh = null # (the skin's: these carry only what's on them)
		var pw := _part(Vector3.ZERO, Vector3.ONE, paw)
		pw.mesh = null
		if not bool(S.get("plantigrade", false)) and not bool(S.get("hooves", false)):
			for k in 4: # (its claws, at its toes' tips)
				var x := (float(k) - 1.5) * 0.22
				_stick(Vector3(x, -0.18, 0.42 - absf(x) * 0.3), Vector3(x * 1.05, -0.34, 0.56 - absf(x) * 0.3), 0.03, _mat(Color(0.1, 0.085, 0.07), 0.35), pw)
		_legx.append([mm, pw])
		for q in 4:
			(_leg_mesh[i][q] as MeshInstance3D).mesh = null
	_build_skin(body)
	_build_male()
	_build_extra()


## A grown male's external genitals (S.male_parts: the species' own), as
## seen on him standing: the prepuce (its sheath) along his belly, furred
## as the belly is (a bison's and a buck's with the tuft of long hair at its
## tip); the scrotum between and behind his thighs (a cat's high, tucked
## under his tail; a bull's hanging). Rigid, on the body.
func _build_male() -> void:
	var mp: Dictionary = S.get("male_parts", {})
	if not male or young or mp.is_empty():
		return
	var coat := _coat(0)
	if mp.has("sheath"):
		var sh: Array = mp.sheath # [z from, z to, radius]
		var z0 := float(sh[0])
		var z1 := float(sh[1])
		var r := float(sh[2])
		var zm := (z0 + z1) * 0.5
		var mid := Vector3(0.0, _belly_y(zm) - r * 0.45, zm)
		var front := Vector3(0.0, _belly_y(z0) - r * 0.75, z0 + r * 0.6)
		var p := _part(mid, Vector3(r * 2.0, r * 1.9, z1 - z0), coat)
		p.look_at_from_position(mid, mid + (mid - front), Vector3.UP) # (its front end a little lower: the orifice forward)
		p.scale = Vector3(r * 2.0, r * 1.9, z1 - z0)
		if float(mp.get("tuft", 0.0)) > 0.0: # (the hair at its tip, long, hanging)
			var tl := float(mp.tuft)
			var tc := _coat(1)
			for k in 5:
				var a := float(k) / 5.0 * TAU
				var o := Vector3(cos(a) * r * 0.35, 0.0, sin(a) * r * 0.35)
				_stick(front + o, front + o * 1.6 + Vector3(0.0, -tl, tl * 0.15), r * 0.22, tc, _body)
	if mp.has("scrotum"):
		var sc: Array = mp.scrotum # [z, radius, drop (how far below the belly line, of its radius)]
		var z := float(sc[0])
		var r := float(sc[1])
		var c := Vector3(0.0, _belly_y(z) - r * float(sc[2]), z)
		for side: float in [-1.0, 1.0]:
			_part(c + Vector3(r * 0.42 * side, 0.0, 0.0), Vector3(r * 1.15, r * 1.6, r * 1.35), coat)


## (Its body's underside, mm: the body's keys, at z.)
func _belly_y(z: float) -> float:
	var bk: Array = (S.body as Array).duplicate()
	bk.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var bf := float(S.get("belly", 1.0))
	var lo: Array = bk[0]
	for k: Array in bk:
		if float(k[0]) <= z:
			lo = k
	var hi: Array = lo
	for k: Array in bk:
		if float(k[0]) >= z:
			hi = k
			break
	var f := 0.0 if float(hi[0]) == float(lo[0]) else (z - float(lo[0])) / (float(hi[0]) - float(lo[0]))
	return lerpf(float(lo[1]) - float(lo[3]) * bf, float(hi[1]) - float(hi[3]) * bf, f)


## Its skin: one tube through its body (rump to chest), one up its neck
## into its head to its nose, its lower jaw, each leg from inside its
## shoulder or haunch down to its toes, its tail; each ring weighted to the
## bones there, blended where they meet. Rest: the head and neck as it most
## often holds them, its legs standing, its tail carried.
func _build_skin(mat: ShaderMaterial) -> void:
	var K: SkinScript = SkinScript.new()
	var torso := K.bone("torso", Transform3D())
	var nrest := Transform3D(Basis.from_euler(Vector3(float(S.neck_pitch), 0.0, 0.0)), S.neck_at)
	var hrest := nrest * Transform3D(Basis.from_euler(Vector3(-float(S.neck_pitch) * 0.85, 0.0, 0.0)), S.head_at)
	var jrest := hrest * Transform3D(Basis(), S.jaw_at)
	var neck := K.bone("neck", nrest)
	var head := K.bone("head", hrest)
	var jaw := K.bone("jaw", jrest)
	_sb = {"torso": torso, "neck": neck, "head": head, "jaw": jaw}
	var pw := float(S.get("boxy", 2.3))
	# the body, rump to chest, and on up its neck into its head to its nose:
	# one tube (its chest rounding up into its throat)
	var bk: Array = (S.body as Array).duplicate()
	bk.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var z0 := float(bk[0][0])
	var z1 := float(bk[bk.size() - 1][0])
	var nk: Array = S.neck
	var n0: Array = nk[0]
	var nz := (nrest * Vector3(0.0, n0[1], n0[0])).z # (the neck's root, along the body)
	var rings := []
	for k: Array in bk:
		if float(k[0]) < nz + float(n0[3]) * float(S.get("chest_gap", 0.9)):
			continue
		var a := 0.6 * (z0 - float(k[0])) / maxf(z0 - z1, 1.0)
		rings.append(SkinScript.ring(Vector3(0.0, k[1], k[0]), Vector3.RIGHT, Vector3.UP, k[2], k[3], float(k[3]) * float(S.get("belly", 1.0)), {torso: 1.0}, 0, a, 0.0, pw))
	for j in nk.size():
		var k: Array = nk[j]
		var w := {torso: 0.5, neck: 0.5} if j == 0 else ({neck: 1.0} if j < nk.size() - 1 else {neck: 0.75, head: 0.25})
		rings.append(SkinScript.ring(nrest * Vector3(0.0, k[1], k[0]), nrest.basis.x, nrest.basis.y, k[2], k[3], k[3], w, 0, 0.6 + 0.12 * j / maxf(nk.size() - 1, 1), 0.0, lerpf(pw, 2.0, float(j) / nk.size())))
	var sculpt: Dictionary = S.get("sculpt", {})
	if sculpt.is_empty():
		var hk: Array = S.head
		for j in hk.size():
			var k: Array = hk[j]
			var w := {neck: 0.35, head: 0.65} if j == 0 else {head: 1.0}
			rings.append(SkinScript.ring(hrest * Vector3(0.0, k[1], k[0]), hrest.basis.x, hrest.basis.y, k[2], k[3], k[3], w, 0, 0.75 + 0.25 * j / maxf(hk.size() - 1, 1), 0.35 if j == 0 else 1.0))
		K.tube(SkinScript.smooth(rings, 4), 24, head)
	else:
		# (the neck on into the back of its skull, closed there inside it;
		# then the head sculpted: SculptHead)
		var zb := float((sculpt.z as Array)[0])
		var hb := (SculptScript._key(sculpt, "top", zb - 20.0) - SculptScript._key(sculpt, "bot", zb - 20.0)) * 0.5
		rings.append(SkinScript.ring(hrest * Vector3(0.0, 0.0, zb - 20.0), hrest.basis.x, hrest.basis.y, hb * 0.8, hb * 0.8, hb * 0.8, {neck: 0.4, head: 0.6}, 0, 0.75, 0.2))
		K.tube(SkinScript.smooth(rings, 4), 24, head)
		var rows := SculptScript.rows(sculpt, hrest)
		var ws := []
		var faces := []
		var alongs := []
		for i in rows.size():
			var z := SculptScript.row_z(sculpt, i)
			var f := smoothstep(zb, zb - 30.0, z)
			ws.append({neck: 0.35 * (1.0 - f), head: 1.0 - 0.35 * (1.0 - f)})
			faces.append(lerpf(0.3, 1.0, f))
			alongs.append(lerpf(0.75, 1.0, float(i) / (rows.size() - 1)))
		K.surface(rows, ws, faces, alongs, head, 0, float(sculpt.nose_r) * 0.3)
	# (its chest's front, under its throat: the body's foremost rings, apart)
	var chest := []
	for k: Array in bk:
		if float(k[0]) < nz + float(n0[3]) * float(S.get("chest_gap", 0.9)) + float(n0[3]) * 1.5:
			var a := 0.6 * (z0 - float(k[0])) / maxf(z0 - z1, 1.0)
			chest.append(SkinScript.ring(Vector3(0.0, float(k[1]) - float(k[3]) * 0.12, k[0]), Vector3.RIGHT, Vector3.UP, float(k[2]) * 0.92, float(k[3]) * 0.8, float(k[3]) * 0.95, {torso: 1.0}, 0, a, 0.0, pw))
	if chest.size() >= 2:
		K.tube(SkinScript.smooth(chest, 3), 22, head)
	# the lower jaw
	rings = []
	var jk: Array = S.jaw
	for j in jk.size():
		var k: Array = jk[j]
		rings.append(SkinScript.ring(jrest * Vector3(0.0, k[1], k[0]), jrest.basis.x, jrest.basis.y, k[2], k[3], k[3], {head: 0.5, jaw: 0.5} if j == 0 else {jaw: 1.0}, 1, 0.9, 1.0)) # (part 1: its jaw, its lip's edge dark)
	K.tube(SkinScript.smooth(rings, 3), 14, head)
	# the tail
	var T: Dictionary = S.tail
	var radii: Array = T.radii
	var carry: Array = T.carry
	var trest := []
	var prev := Transform3D()
	for k in int(T.n):
		var xf := prev * Transform3D(Basis.from_euler(Vector3(float(carry[0]) if k == 0 else float(carry[1]), 0.0, 0.0)), T.base if k == 0 else Vector3(0.0, 0.0, float(T.seg)))
		trest.append(xf)
		_sb["tail%d" % k] = K.bone("tail%d" % k, xf)
		prev = xf
	rings = []
	var t0: Transform3D = trest[0]
	rings.append(SkinScript.ring(t0 * Vector3(0.0, 0.0, -float(radii[0]) * 1.2), t0.basis.x, t0.basis.y, float(radii[0]) * 1.1, float(radii[0]) * 1.1, float(radii[0]) * 1.1, {torso: 1.0}, 6, 0.0))
	var n := int(T.n)
	var flat := float(T.get("flat", 1.0)) # (its depth's share of its width: a beaver's paddle, thin)
	for k in n:
		var xf: Transform3D = trest[k]
		var rk := float(radii[k])
		var fk := lerpf(1.0, flat, clampf(k / 1.5, 0.0, 1.0))
		var wj := {torso: 0.5, _sb["tail0"]: 0.5} if k == 0 else {_sb["tail%d" % (k - 1)]: 0.5, _sb["tail%d" % k]: 0.5}
		rings.append(SkinScript.ring(xf.origin, xf.basis.x, xf.basis.y, rk, rk * fk, rk * fk, wj, 6, float(k) / n))
		var rn := float(radii[mini(k + 1, n - 1)])
		var fm := lerpf(1.0, flat, clampf((k + 0.5) / 1.5, 0.0, 1.0))
		rings.append(SkinScript.ring(xf * Vector3(0.0, 0.0, float(T.seg) * 0.5), xf.basis.x, xf.basis.y, (rk + rn) * 0.5, (rk + rn) * 0.5 * fm, (rk + rn) * 0.5 * fm, {_sb["tail%d" % k]: 1.0}, 6, (k + 0.5) / n))
	var last: Transform3D = trest[n - 1]
	var rl := float(radii[n - 1]) * 0.75
	rings.append(SkinScript.ring(last * Vector3(0.0, 0.0, float(T.seg)), last.basis.x, last.basis.y, rl, rl * flat, rl * flat, {_sb["tail%d" % (n - 1)]: 1.0}, 6, 1.0))
	K.tube(SkinScript.smooth(rings, 2), 12)
	# the legs: standing
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var J := _leg_chain(i, Vector3(hm.x * side, -body_h, hm.y), Vector3.UP, Vector3.FORWARD, 0.0)
		var bones := []
		for q in 4:
			bones.append(K.bone("leg%d_%d" % [i, q], SkinScript.along(J[q], J[q + 1])))
		_sb["leg%d" % i] = bones
		K.tube(SkinScript.smooth(_leg_rings(i, J, torso, bones), 2), 16)
	_skin = K
	mat.set_shader_parameter("skin", true)
	_torso = K.finish(_body, mat)


## Leg i's rings, its joints J (at rest), from inside the body (the bone
## `torso`) through its four bones.
func _leg_rings(i: int, J: Array, torso: int, b: Array) -> Array:
	var L: Dictionary = legs[i / 2]
	var hind := i >= 2
	var r: float = L.r
	var a: float = L.f
	var hip: Vector3 = J[0]
	var knee: Vector3 = J[1]
	var top: Vector3 = J[2]
	var ball: Vector3 = J[3]
	var toe: Vector3 = J[4]
	var hooved := bool(S.get("hooves", false))
	var flat := bool(S.get("plantigrade", false))
	var part := 3 if hind else 2
	var thick := float(S.get("limb", 1.0))
	# each: [where, half width, half depth behind, before, bones, how far down the leg]
	var spec := []
	if hind:
		spec = [[hip * Vector3(0.45, 1.0, 1.0) + Vector3(0.0, a * 0.42, a * 0.12), 1.5, 2.8, 2.1, {torso: 1.0}],
			[hip * Vector3(0.72, 1.0, 1.0), 1.95, 3.2, 2.4, {torso: 0.55, b[0]: 0.45}],
			[(hip * Vector3(0.85, 1.0, 1.0)).lerp(knee, 0.45), 1.85, 2.8, 2.0, {b[0]: 0.85, torso: 0.15}],
			[knee, 1.5, 1.8, 1.45, {b[0]: 0.5, b[1]: 0.5}],
			[knee.lerp(top, 0.3), 1.3, 1.85, 1.05, {b[1]: 1.0}],
			[knee.lerp(top, 0.82), 0.78, 0.9, 0.72, {b[1]: 1.0}],
			[top, 0.78, 1.1, 0.78, {b[1]: 0.5, b[2]: 0.5}],
			[top.lerp(ball, 0.5), 0.68, 0.68, 0.68, {b[2]: 1.0}]]
	else:
		spec = [[hip * Vector3(0.5, 1.0, 1.0) + Vector3(0.0, a * 0.55, a * 0.08), 1.35, 2.4, 2.4, {torso: 1.0}],
			[hip * Vector3(0.75, 1.0, 1.0), 1.7, 2.2, 2.5, {torso: 0.55, b[0]: 0.45}],
			[(hip * Vector3(0.88, 1.0, 1.0)).lerp(knee, 0.5), 1.55, 1.85, 1.95, {b[0]: 0.85, torso: 0.15}],
			[knee, 1.4, 1.85, 1.35, {b[0]: 0.5, b[1]: 0.5}],
			[knee.lerp(top, 0.3), 1.25, 1.15, 1.45, {b[1]: 1.0}],
			[knee.lerp(top, 0.82), 0.82, 0.78, 0.88, {b[1]: 1.0}],
			[top, 0.82, 0.86, 0.82, {b[1]: 0.5, b[2]: 0.5}],
			[top.lerp(ball, 0.55), 0.7, 0.68, 0.7, {b[2]: 1.0}]]
	if hooved: # (the pastern, down into the hoof)
		spec.append([ball, 0.82, 0.8, 0.85, {b[2]: 0.5, b[3]: 0.5}])
		spec.append([ball.lerp(toe, 0.35), 0.8, 0.75, 0.8, {b[3]: 1.0}])
	elif flat: # (the bear's broad sole; a beaver's hind, webbed, broader)
		var sw := float(S.get("sole_hind", 1.0)) if hind else 1.0
		spec.append([ball, 1.25 * sqrt(sw), 0.9, 1.0, {b[2]: 0.5, b[3]: 0.5}])
		spec.append([ball.lerp(toe, 0.55), 1.55 * sw, 0.6, 0.7, {b[3]: 1.0}])
		spec.append([ball.lerp(toe, 0.95), 1.3 * sw, 0.42, 0.45, {b[3]: 1.0}])
	else: # (the paw)
		spec.append([ball, 0.95, 0.85, 0.9, {b[2]: 0.5, b[3]: 0.5}])
		spec.append([ball.lerp(toe, 0.55), 1.22, 0.62, 0.72, {b[3]: 1.0}])
		spec.append([ball.lerp(toe, 0.92), 1.0, 0.45, 0.5, {b[3]: 1.0}])
	var pts := []
	for sp: Array in spec:
		pts.append(sp[0])
	var total := 0.0
	for k in range(1, pts.size()):
		total += (pts[k] as Vector3).distance_to(pts[k - 1])
	var dirs := []
	for k in spec.size():
		dirs.append(((pts[mini(k + 1, pts.size() - 1)] as Vector3) - (pts[maxi(k - 1, 0)] as Vector3)).normalized())
	var fr := SkinScript.frames(dirs) # (turned along it, untwisted)
	var out := []
	var run := 0.0
	for k in spec.size():
		var sp: Array = spec[k]
		var c: Vector3 = sp[0]
		if k > 0:
			run += c.distance_to(pts[k - 1])
		var ax: Vector3 = fr[k][0]
		var ay: Vector3 = fr[k][1] # (behind it, for a leg standing)
		out.append(SkinScript.ring(c, ax, ay, float(sp[1]) * r * thick, float(sp[2]) * r * thick, float(sp[3]) * r * thick, sp[4], part, run / maxf(total, 1.0), 0.0, 2.0))
	return out


## The skin's bones where the motor has its parts now.
func _skin_pose() -> void:
	if _skin == null:
		return
	var nt := _neck.transform
	var ht := nt * _head.transform
	_skin.pose(_sb.neck, nt)
	_skin.pose(_sb.head, ht)
	_skin.pose(_sb.jaw, ht * _jaw.transform)
	var prev := Transform3D()
	for k in _tail.size():
		prev = prev * _tail[k].transform
		_skin.pose(_sb["tail%d" % k], prev)
	for i in 4:
		var J: Array = _joints[i]
		if J == null or J.is_empty():
			continue
		var bones: Array = _sb["leg%d" % i]
		for q in 4:
			_skin.pose(bones[q], SkinScript.along(J[q], J[q + 1]))


## (No shells: its coat is painted, carnivore.gdshader's.)
func _fur_shells(_mi: MeshInstance3D, _len_mm: float, _shells := 8, _spacing := -1.0) -> void:
	pass


## (The species' own material for a part, "neck" or "head", if any: given
## the one it would have. Set here, before the part's fur is grown: a
## material changed after would leave its instance uniforms orphaned.)
func _part_coat(_name: String, m: ShaderMaterial) -> ShaderMaterial:
	return m


static var _claw_meshes := {}


## A claw's mesh (the body's mm): `len_` long along +z, hooked: curving
## down (-y) along its length till its tip has turned `curl` rad from where
## it set out; deep at its root (r, its half depth), narrower across
## (pressed from the sides), tapering to a point: a keratin hook (a bear's,
## a porcupine's), not a straight peg.
static func claw_mesh(len_: float, r: float, curl: float) -> ArrayMesh:
	var key := "%.2f:%.2f:%.3f" % [len_, r, curl]
	var m: ArrayMesh = _claw_meshes.get(key)
	if m != null:
		return m
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEG := 8
	const SIDES := 6
	var p := Vector3.ZERO
	var rows := []
	var ds := len_ / SEG
	for i in SEG + 1:
		var t := float(i) / SEG
		var a := curl * t
		var d := Vector3(0.0, -sin(a), cos(a))
		var nrm := Vector3(0.0, cos(a), sin(a)) # (its back: the outside of the curve)
		var rr := r * (1.0 - t * 0.92)
		var row := []
		for k in SIDES:
			var b := TAU * k / SIDES
			var o := nrm * cos(b) * rr + Vector3.RIGHT * sin(b) * rr * 0.55
			row.append([p + o, (nrm * cos(b) + Vector3.RIGHT * sin(b) * 1.8).normalized()])
		rows.append(row)
		p += d * ds
	for i in SEG:
		for k in SIDES:
			var k1 := (k + 1) % SIDES
			for v: Array in [rows[i][k], rows[i][k1], rows[i + 1][k], rows[i][k1], rows[i + 1][k1], rows[i + 1][k]]:
				st.set_normal(v[1])
				st.add_vertex(v[0])
	for k in SIDES: # (its point)
		var k1 := (k + 1) % SIDES
		for v: Array in [rows[SEG][k], rows[SEG][k1], [p, Vector3(0.0, -sin(curl), cos(curl))]]:
			st.set_normal(v[1])
			st.add_vertex(v[0])
	m = st.commit()
	_claw_meshes[key] = m
	return m


var _claws: Array = [[], [], [], []] # (each leg's: [mesh instance, across (of its foot's half width)])


## Leg i's claws: one at each toe's tip, across its foot (xs: each one's
## place across, -1..1 of its foot's half width), each len_ long (mm), r its
## root's half depth, hooked curl rad; posed at its toes each frame
## (_pose_legs), in the body's own space: their shape their own, not
## stretched with the foot's.
func _add_claws(i: int, xs: Array, len_: float, r: float, curl: float, mat: Material, lens: Array = []) -> void:
	for k in xs.size():
		var l := len_ * (float(lens[k]) if k < lens.size() else 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = claw_mesh(l, r, curl)
		mi.material_override = mat
		_body.add_child(mi)
		(_claws[i] as Array).append([mi, float(xs[k]), l])


## (The species' own parts, if any.)
func _build_extra() -> void:
	pass


## An ear (mm: up its own y, len long, width across its base; point: how
## pointed), open forward (-z), its back +z.
static func _ear_mesh(len_: float, width: float, point: float, thick := 0.22, cup := 0.35) -> ArrayMesh:
	const RINGS := 7
	const ROUND := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := func(i: int, k: int) -> Array:
		var t := float(i) / RINGS
		var hw := width * 0.5 * pow(1.0 - t, point) * (0.82 + 0.45 * sin(PI * minf(t * 1.25, 1.0))) * (1.0 - smoothstep(0.82, 1.0, t) * 0.6) + 1.0
		if point < 0.5: # (a bear's: round, a half disc on a short stalk)
			var u := clampf((t - 0.4) / 0.6, 0.0, 1.0)
			hw = width * 0.5 * (0.8 + 0.2 * minf(t / 0.4, 1.0)) * sqrt(maxf(1.0 - u * u, 0.0)) + 1.0
		var a := TAU * float(k % ROUND) / ROUND
		var x := sin(a) * hw
		var z := cos(a) * maxf(hw * thick * (1.0 - 0.6 * t), 2.0)
		z -= absf(sin(a)) * hw * cup * (1.0 - absf(cos(a))) # (cupped)
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
	_meal = null
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
	_meal = null
	_held = false
	_stage = 5 # (straight to it, to eat)
	_st = 0.0


func eat_at(at: Vector3, seconds := 10.0) -> void:
	_mode = "eat_at"
	_eat_p = at
	_eat_for = seconds
	_bite_pitch = -0.6
	_reach_crouch = 0.0
	_reach_tilt = 0.0
	_stage = 0
	_st = 0.0


var _eat_p := Vector3.ZERO # (eat_at's: where)
var _eat_for := 10.0


## Eating at a point (eat_at): its mouth brought to it, and kept there,
## the food not touched (it's drawn by the hundred, or it's anyone's): its
## head lowered or raised till its mouth's on it, crouched to it if it's low,
## the jaws working, licking and snapping, nosing about; a while, then off.
func _eat_at(dt: float) -> void:
	var to := _eat_p - _pos
	to.y = 0.0
	var reach := absf(float(S.mouth_z)) * MM * size # (its middle to its mouth)
	match _stage:
		0: # to it, its mouth over it
			_target = _eat_p - to.normalized() * reach * 0.95 if to.length() > 0.01 else _pos
			_neck_to = Vector2(-0.4, 0.0)
			_sniff = 1.0
			if (to.length() < reach * 1.15 and _speed < 0.05) or _st > 15.0:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # its snout on it, eating
			_target = _pos
			_mouth_down_to(_eat_p.y, dt, 0.8)
			# (its mouth kept over it: its neck lowered swings it back toward
			# its chest; a step on after it)
			var m := _mouth()
			var off := Vector3(_eat_p.x - m.x, 0.0, _eat_p.z - m.z)
			if off.length() > 0.015:
				_pos += off.limit_length(0.12 * size / 0.5 * dt)
				_target = _pos
			_neck_to = Vector2(_bite_pitch, 0.0)
			_look_to = Vector2(0.06 * sin(_st * 5.0), 0.14 * sin(_st * 1.3)) # (nosing about it)
			_jaw_to = 0.25 * maxf(sin(_st * 9.0), 0.0) # (licking, snapping)
			_chew = 1.0
			_ears_to = 0.3
			var low := _eat_p.y < _pos.y + float(body_h) * MM * size * 0.5
			_crouch = move_toward(_crouch, (float(S.eat_crouch) if low else 0.0) + _reach_crouch, dt)
			if _st > _eat_for:
				wander(_home_spot(), _radius)


func groom() -> void:
	_mode = "groom"
	_st = 0.0


## Hurt in the face (a porcupine's quills in its muzzle): its hunt given up;
## sat, pawing at its muzzle, shaking its head, a while (secs); then off,
## away from where it was hurt (from).
func hurt_face(from: Vector3, secs := 5.0) -> void:
	if _prey and is_instance_valid(_prey) and _prey.has_meta("hunted") and _prey.get_meta("hunted") == self:
		_prey.remove_meta("hunted")
	_prey = null
	_meal = null
	_held = false
	_mode = "hurt"
	_st = 0.0
	_wait = secs
	_hurt_from = from


var _hurt_from := Vector3.ZERO


func sit(secs := 8.0) -> void:
	_mode = "sit"
	_st = 0.0
	_wait = secs


func sleep(secs := 20.0) -> void:
	_mode = "sleep"
	_st = 0.0
	_wait = secs
	_stage = 0 if is_instance_valid(_sleep_home()) else 2


## Where it sleeps, if anywhere but where it is: its species' (a bear's
## den, a beaver's lodge); null: curled up where it is.
func _sleep_home() -> Node3D:
	return null


## (Its home's way in, world: where it goes in to sleep, and comes out.)
func _home_door(h: Node3D) -> Vector3:
	return h.global_position


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
		"eat_at":
			_eat_at(dt)
		"hurt": # (pawing at its muzzle, its head shaking; then off, away)
			_target = _pos
			_sit_to = 0.8
			_crouch = 0.0
			_neck_to = Vector2(-0.35 + 0.15 * sin(_st * 4.0), 0.5 * sin(_st * 11.0) * (1.0 if fmod(_st, 2.0) < 1.0 else 0.2))
			_jaw_to = 0.25
			_ears_to = -0.8
			_tail_mode = "low"
			if _wait <= 0.0:
				_sit_to = 0.0
				var away := Vector3(_pos.x - _hurt_from.x, 0.0, _pos.z - _hurt_from.z)
				away = away.normalized() if away.length() > 0.01 else Vector3.BACK
				wander(_pos + away * 4.0, 1.5)
				_target = _pos + away * 4.0
				_wait = 4.0
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
		"sleep" when _stage < 2: # (to its home's way in; in, out of sight, asleep; out again)
			var home := _sleep_home()
			if not is_instance_valid(home):
				_stage = 2
				return
			var door := _home_door(home)
			match _stage:
				0:
					_target = Vector3(door.x, _pos.y, door.z)
					_wait = maxf(_wait, 2.0)
					if Vector2(_pos.x - door.x, _pos.z - door.z).length() < 0.25 * size + 0.1:
						_stage = 1
						_st = 0.0
						visible = false
				1:
					_target = _pos
					if _wait <= 0.0:
						visible = true
						_stretch = 1.0
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
		0: # to it, walking (trotting, a way off)
			_target = p - to.normalized() * stalk_from * 0.9
			_pace = float(S.get("trot", S.walk)) * lerpf(0.35, 1.0, size) if d > stalk_from * 2.5 else -1.0
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
			var face := atan2(-to.x, -to.z)
			var facing := absf(wrapf(face - _yaw, -PI, PI)) < 0.2
			_turn_to = INF if facing else face # (turned to it; set every frame, it'd never read as done)
			_crouch = move_toward(_crouch, float(S.stalk_crouch) * 1.1, dt * 2.0)
			_ears_to = 1.0
			_tail_mode = "low"
			_neck_to = Vector2(float(S.get("stalk_neck", -0.3)), 0.0)
			_attack_ready(dt)
			if _st > 2.0 and facing:
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
					if _prey.has_method("bitten") and bool(_prey.call("bitten", self)): # (its defence: a porcupine's quills in its face)
						return
					MealScript.subdue(_prey)
					_held = false # (every kill eaten where it fell: not carried off in its jaws)
					_stage = 5
					_st = 0.0
				else:
					_stage = 1 # (missed: after it again)
					_st = 0.0
		5: # to its food (left lying: carrion, a kill set before it); or its kill
			# in its jaws, carried off a few lengths to eat
			_crouch = move_toward(_crouch, float(S.eat_crouch), dt)
			if not _held:
				_target = p - to.normalized() * float(S.mouth_z) * -MM * size * 0.9
				if d < -float(S.mouth_z) * MM * size * 1.1 and _speed < 0.05:
					_target = _pos
					_turn_to = atan2(-to.x, -to.z)
					_lay = Vector3(p.x, _ground(p.x, p.z), p.z)
					MealScript.subdue(_prey) # (food still alive, set before it: killed)
					_lay_down(_prey, _lay)
					_stage = 6
					_st = 0.0
			else:
				if _st < dt * 1.5: # (where to: on ahead, a few of its lengths)
					var ahead := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
					_carry_to = _pos + ahead * float(S.body_len) * MM * size * 3.0
				_target = _carry_to
				_pace = float(S.walk) * 1.6
				_tail_mode = "carry"
				_neck_to = Vector2(0.15, 0.0) # (its head up, the prey hanging from its jaws)
				if _st > 5.0 or Vector2(_pos.x - _carry_to.x, _pos.z - _carry_to.z).length() < 0.15:
					_target = _pos
					_pace = -1.0
					var lay := _out(Vector3(0.0, -body_h, float(S.mouth_z) - 40.0))
					_lay = Vector3(lay.x, _ground(lay.x, lay.z), lay.z)
					_held = false # (laid down, every kill: eaten off the ground, where it lies)
					_lay_down(_prey, _lay)
					_stage = 6
					_st = 0.0
		6: # (its kill on the ground, lying where it was laid, still: its head down
			# to it, its mouth on the next bite, tearing it off; a tug at it now and
			# then, its head pulled up and back, the bite in its teeth, the carcass
			# left where it lies; a step or two round it, its mouth to the next)
			_target = _pos
			_chew = 1.0
			_held = false
			if _meal == null: # (torn up piece by piece, its blood run out on the ground)
				var big := _too_big()
				# (an insect, a grub: one bite, gone; anything bigger torn up)
				var across := 1 if not MealScript.is_vertebrate(_prey) else (4 if _small_prey() else (9 if big else 6))
				_meal = MealScript.of(_prey, across, -1, _ground(_lay.x, _lay.z))
				_bite_pitch = -0.95
				_reach_crouch = 0.0
				# (how long at it: a bigger kill longer, a tug a piece)
				_eat_secs = clampf(15.0 * _prey_len() / 0.4, 15.0, 45.0) if not _small_prey() else (9.0 if across > 1 else 3.5)
			var ph := fmod(_st, 2.4)
			var tugging := ph > 1.2 and ph < 2.1
			var mouth := _mouth()
			if _meal:
				var na: Vector3 = _meal.call("next_at")
				if not tugging: # (its head lowered, or raised, till its mouth's on the next bite)
					_mouth_down_to(na.y, dt, -0.25)
				# (its mouth over the next bite: shuffling round it, facing it)
				var off := Vector3(na.x - mouth.x, 0.0, na.z - mouth.z)
				var to_bite := Vector3(na.x - _pos.x, 0.0, na.z - _pos.z)
				if to_bite.length() > 0.01:
					_yaw = lerp_angle(_yaw, atan2(-to_bite.x, -to_bite.z), 1.0 - exp(-1.5 * dt))
				if off.length() > 0.015:
					_pos += off.limit_length(0.12 * size / 0.5 * dt)
					_target = _pos
				# (a piece torn away at the top of each tug; the last of it at the end)
				var pulls := maxf(roundf((_eat_secs - 1.0) / 2.4), 1.0)
				_meal.call("tear", 1.0 if _st > _eat_secs - 1.0 else clampf(floorf((_st + 0.65) / 2.4) / pulls, 0.0, 1.0), mouth)
			_neck_to = Vector2(_bite_pitch + (0.25 if tugging else 0.0), 0.0)
			_crouch = move_toward(_crouch, float(S.eat_crouch) + _reach_crouch, dt)
			_look_to = Vector2(-0.3 + (0.3 if tugging else 0.0), 0.2 * sin(_st * 1.7)) # (tugging: up and to the side)
			_jaw_to = 0.06 if tugging else 0.3 * maxf(sin(_st * 6.0), 0.0)
			if _st > _eat_secs:
				_prey.queue_free()
				_prey = null
				groom()


## Its kill laid on the ground at `at`, still: on its side, level, as it
## lay; not to move again till it's eaten.
func _lay_down(prey: Node3D, at: Vector3) -> void:
	if not is_instance_valid(prey):
		return
	var f := -prey.global_basis.z
	f.y = 0.0
	if f.length() < 0.01:
		f = Vector3.FORWARD
	f = f.normalized()
	var lie := 0.0 # (how high its middle is, lying on its side: half its width)
	var bh: Variant = prey.get("body_h")
	var sz: Variant = prey.get("size")
	var bw: Variant = (prey.get("S") as Dictionary).get("body_w") if prey.get("S") is Dictionary else null
	if bw != null and sz is float:
		lie = float(bw) * MM * float(sz)
	elif bh is float and sz is float:
		lie = float(bh) * MM * float(sz) * 0.5
	var yaw := atan2(-f.x, -f.z)
	if not (bh is float): # (a snake, a grub, a caterpillar: lying as it is, along the ground)
		prey.global_position = Vector3(prey.global_position.x, at.y + maxf(prey.global_position.y - _ground(prey.global_position.x, prey.global_position.z), 0.0), prey.global_position.z) if prey.global_position.distance_to(at) < 0.3 else at
		return
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(prey.global_basis.get_scale())
	prey.global_transform = Transform3D(b, at + Vector3.UP * lie)


var _bite_pitch := -0.95 # (its neck's, eating off the ground: down till its mouth's on it)
var _reach_crouch := 0.0 # (crouched further, its neck as low as it goes and its mouth not there yet)
var _reach_k := 0.0 # (0..1: eating off the ground, its neck taking the more of its pitch, its head the less)
var _reach_tilt := 0.0 # (rad: its forequarters tipped down, crouched as far as it goes and its mouth not there yet)
const BITE_PITCH_LO := -2.1 ## its neck's lowest, eating
const REACH_CROUCH := 0.6 ## crouched further at most to get its mouth down to its food
const REACH_TILT := 0.35 ## rad its forequarters tipped down at most besides (a moose's: its neck too short for its legs)
const BITE_INTO := 0.04 ## of its head's reach, its mouth past the bite (on it, a little in: not hovering over it)


## Its mouth brought down (or up) to y, what it's eating's: its neck
## lowered till its mouth's a little into it, never just over it; once its
## neck goes no lower, crouched further (a deer's, a moose's, a bison's
## forelegs bent: no crouch of their own), easing up again only once its
## neck has room (not bobbing). hi: its neck's highest.
func _mouth_down_to(y: float, dt: float, hi: float) -> void:
	var into := absf(float(S.mouth_z)) * MM * size * BITE_INTO
	var mouth := _mouth()
	var err := (y - into) - mouth.y
	# (never its head curled back under its chest: past straight down, its
	# neck lowered the further only draws its mouth back, and up; its mouth
	# kept before its chest, crouching and tipping forward instead)
	var ahead := (mouth - _pos).dot(Vector3(-sin(_yaw), 0.0, -cos(_yaw)))
	var under := ahead < float(S.body_len) * 0.5 * MM * size * 0.85
	var rate := clampf(err * 10.0, -1.2, 1.2)
	if under:
		rate = maxf(rate, 0.3) # (back up a little: its mouth out before it again)
	_bite_pitch = clampf(_bite_pitch + rate * dt, BITE_PITCH_LO, hi)
	if (_bite_pitch <= BITE_PITCH_LO + 0.05 or under) and err < -0.004:
		if _reach_crouch < REACH_CROUCH:
			_reach_crouch = move_toward(_reach_crouch, REACH_CROUCH, dt * 0.5)
		else: # (and then its forequarters tipped down: its forelegs bent the more)
			_reach_tilt = move_toward(_reach_tilt, REACH_TILT, dt * 0.25)
	elif err > 0.01 or _bite_pitch > BITE_PITCH_LO + 0.35:
		# (its mouth down past it, or its neck with room again: up a little,
		# the tip forward first, then the crouch)
		if _reach_tilt > 0.0:
			_reach_tilt = move_toward(_reach_tilt, 0.0, dt * 0.15)
		else:
			_reach_crouch = move_toward(_reach_crouch, 0.0, dt * 0.3)


## Whether it eats its kill from its jaws, head up (a small one, for a
## smaller hunter: a fox's mouse, a bobcat's). (Not now: every kill is laid
## down and eaten off the ground, where it lies.)
func _from_jaws() -> bool:
	return false


## A spring at its prey at p: aimed for its mouth to come down on it (not
## its middle), and where it'll be by then, if it's moving.
func _spring_at(p: Vector3, angle: float) -> void:
	var at := p
	if is_instance_valid(_prey):
		var sp = _prey.get("_speed")
		var yw = _prey.get("_yaw")
		if (sp is float) and (yw is float):
			var d0 := maxf(Vector2(p.x - _pos.x, p.z - _pos.z).length(), 0.05)
			var t := sqrt(2.0 * d0 * tan(angle) / G) # (its time in the air)
			at += Vector3(-sin(yw), 0.0, -cos(yw)) * float(sp) * t
	var to := Vector3(at.x - _pos.x, 0.0, at.z - _pos.z)
	var reach := absf(float(S.mouth_z)) * MM * size # (its middle to its mouth)
	if to.length() > 0.01:
		at -= to.normalized() * minf(reach, to.length() * 0.9)
	_leap(at, angle)


## (Its mouth: where what it eats goes in (the world's): at its lips, just
## behind its muzzle's tip, as its head and jaw are built.)
func _mouth() -> Vector3:
	if is_nan(_tip_z):
		_tip_z = _muzzle_tip()
	return _jaw.global_transform * Vector3(0.0, 0.0, _tip_z * 0.92)


var _tip_z := NAN # (its muzzle's tip, in its jaw's own space: _muzzle_tip)


## How far forward of its jaw's hinge its muzzle reaches (its jaw's own
## units, -z): the furthest of its head's and jaw's parts that way. (Its
## make's mouth_z, its middle to its mouth, was taken for this before, and
## put the mouth ahead of its muzzle: eating off the ground its snout
## stopped short, over the food.)
func _muzzle_tip() -> float:
	var tip := 0.0
	var inv := _jaw.global_transform.affine_inverse()
	for n: Node3D in [_head, _jaw]:
		if n == null:
			continue
		for ch in n.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			if mi.mesh == null:
				continue
			var bb: AABB = (inv * mi.global_transform) * mi.get_aabb()
			tip = minf(tip, bb.position.z)
	return tip if tip < -1.0 else float(S.mouth_z) * 0.3


## Whether its prey is small enough to eat from its jaws (about a quarter of
## its own length or less: a mouse for any of them, a squirrel for a coyote,
## a wolf or a bear); bigger it's laid down and torn at.
func _small_prey() -> bool:
	if not is_instance_valid(_prey):
		return false
	return _prey_len() < float(S.body_len) * MM * size * 0.27


var _eat_secs := 15.0 # (how long it's at a kill laid down)


## Its prey's length (m, nose to rump): the mice, squirrels and hares by
## their kind; anything else by how big it's drawn (a fawn, a calf, a
## beaver, a kit, a grub...).
func _prey_len() -> float:
	if not is_instance_valid(_prey):
		return 0.0
	var path := (_prey.get_script() as Script).resource_path if _prey.get_script() else ""
	var ps := float(_prey.get("size")) / 0.5 if _prey.get("size") is float else 1.0
	if "mouse" in path:
		return 0.09 * ps
	if "squirrel" in path:
		return 0.26 * ps
	if "hare" in path:
		return 0.45 * ps
	if "snake" in path and _prey.get("K") is Dictionary: # (its length, m, at its size)
		return float((_prey.get("K") as Dictionary).len) * float(_prey.get("size"))
	var d := PersonalSpace._dims(_prey).x if _prey is Node3D else 0.0
	return d if d > 0.0 else 0.3


## Whether its kill's too big to carry off or lift (more than half its own
## length: a deer, a calf, a beaver, for most of them).
func _too_big() -> bool:
	return _prey_len() > float(S.body_len) * MM * size * 0.55


## (The species: getting ready to spring, still; and its attack, each frame:
## true once it's away, in the air.)
func _attack_ready(_dt: float) -> void:
	pass


func _attack(_dt: float, p: Vector3, _d: float) -> bool:
	_leap(p, 0.6)
	return true


func _on_landed() -> void:
	_crouch = 0.0
	_reach_crouch = 0.0


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
	if _mate_role == "male" and _mate_stage in ["seek", "court"] and is_instance_valid(_mate):
		_target = _around_her(_target) # (round her, never through her)
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
	_keep_apart()
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y


# --- personal space ------------------------------------------------------------
# (PersonalSpace: a capsule on the ground, from its rump to its muzzle, as
# wide as its body, kept off every other creature's. Off when they're meant
# to touch: mating, nursing, suckling, playing, sparring; the young; the
# airborne, the dead. Hunting and eating, only it and its _prey: the rest
# it still goes round.)

const TOUCHING := ["nurse", "suckle", "play", "spar", "follow", "newborn", "birth", "carry", "piloted"]


func _space_r() -> float:
	return float(S.body_w) * MM * size


## (Its capsule's spine on the ground: [rump, muzzle], world xz.)
func _space_spine() -> Array:
	var f := Vector2(-sin(_yaw), -cos(_yaw))
	var c := Vector2(_pos.x, _pos.z)
	var r := _space_r()
	return [c - f * maxf(float(S.body_len) * 0.5 * MM * size - r, 0.0), c + f * maxf(absf(float(S.mouth_z)) * 0.85 * MM * size - r, 0.0)]


func _touch_ok() -> bool:
	return young or dead or airborne or _mate_role != "" or _mode in TOUCHING


func _keep_apart() -> void:
	PersonalSpace.keep_apart(self) # (its capsule its own: _space_spine, _space_r; the others whatever they are)


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
		var gy := -(body_h * (1.0 - 0.45 * _crouch) + _lift) # (the ground, near enough, under it)
		var lifted := clampf((foot.y - gy) / 50.0, 0.0, 1.0) if not airborne else 1.0
		var ch := _leg_chain(i, foot, up, fwd, lifted, maxf(_sit, _lie), _lie)
		var knee: Vector3 = ch[1]
		var top: Vector3 = ch[2]
		var ball: Vector3 = ch[3]
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
		for c: Array in _claws[i]: # (its claws: out of its toes' tips, hooked down to the ground before them)
			var cl := c[2] as float
			var across := float(c[1])
			var at := foot + xx * (across * r * 0.95) + yy * (r * 0.42) + z * (r * 0.22 - absf(across) * r * 0.3) - z * cl * 0.12
			(c[0] as MeshInstance3D).transform = Transform3D(Basis(xx, yy, z) * Basis(Vector3.UP, -across * 0.18) * Basis(Vector3.RIGHT, 0.12), at)
		_joints[i] = [hip, knee, top, ball, foot]
	_skin_pose()


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
		if not ((_mode == "eat_at" and _stage == 1) or (_mode == "hunt" and _stage == 6)):
			_reach_tilt = move_toward(_reach_tilt, 0.0, dt * 0.5) # (up again, done eating)
		_pitch = pitch + float(S.sit_pitch) * s * (1.0 - l) - 0.25 * _stretch * sin(PI * minf(_stretch * 1.5, 1.0)) - _reach_tilt
		_roll = lerpf(_roll, 1.15 * _side * l + 0.25 * _curl * l, 1.0 - exp(-3.0 * dt)) if _mode not in ["play", "roll_over", "wallow"] else _roll
		# (its feet, sitting: the forefeet straight down before it, the
		# hind folded; lying: the forelegs out before it, the hind under it)
		for i in 4:
			if not (s > 0.02 or l > 0.02):
				if _pose_foot[i] != null and _mode not in ["groom", "mark", "alert"]:
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
	# (eating off the ground, the neck reaching down and the head held to
	# it, the muzzle to the ground: not the head curled back under a neck
	# that hardly bends)
	var eating_low := (_mode == "eat_at" and _stage == 1) or (_mode == "hunt" and _stage == 6)
	_reach_k = move_toward(_reach_k, 1.0 if eating_low else 0.0, dt * 1.5)
	_neck.rotation = Vector3(float(S.neck_pitch) + _neck_now.x * lerpf(0.6, 0.95, _reach_k) - 0.35 * _stretch, _neck_now.y * 0.55, 0.0)
	_look_now = _look_now.lerp(_look_to, 1.0 - exp(-6.0 * dt))
	var sniff := 0.04 * _sniff * sin(_t * 18.0)
	var lick := 0.25 * _lick * maxf(sin(_t * 6.0), 0.0)
	var tilt := float(S.get("tilt", 0.0)) * (1.0 if _mode == "hunt" and _stage == 2 else 0.0)
	_head.rotation = Vector3(-float(S.neck_pitch) * 0.85 + _neck_now.x * lerpf(0.5, 0.2, _reach_k) + _look_now.x + sniff - lick, _neck_now.y * 0.45 + _look_now.y, tilt * sin(_t * 0.7))
	_jaw.rotation.x = -(maxf(_jaw_to, 0.25 * _lick * maxf(sin(_t * 6.0), 0.0)) + 0.1 * _chew * maxf(sin(_t * 9.0), 0.0)) # (open: its jaw's tip down, away from its upper teeth)
	if _mode == "hurt" and s > 0.4: # (a forepaw swiped down its muzzle, again and again)
		var muz := _neck.transform * (_head.transform * Vector3(0.0, -30.0, float(S.mouth_z) * 0.25))
		_pose_foot[0] = muz + Vector3(-12.0, -20.0 + 30.0 * sin(_t * 7.0), 25.0)
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
		var drop := float((S.ear as Dictionary).get("drop", 0.0)) # (a hound's, a retriever's: hanging down beside its head, lifted a little alert, swinging as it moves)
		if drop > 0.0:
			# (hanging flat against its cheek: its length down, its inside to its head, its width fore and aft;
			# lifted at its root, alert; swinging as it goes)
			var lift := 0.35 * maxf(_ears, 0.0) - 0.15 * maxf(-_ears, 0.0)
			var swing := 0.15 * sin(_t * 9.0 + side) * clampf(_speed * 3.0, 0.0, 1.0)
			var yy := Vector3(0.18 * side, -1.0, -0.12).normalized()
			var zz := (Vector3(-side, 0.0, 0.0) - yy * yy.dot(Vector3(-side, 0.0, 0.0))).normalized()
			var hang := Basis(yy.cross(zz), yy, zz)
			e.basis = Basis(Vector3.FORWARD, -side * lift) * Basis(Vector3.RIGHT, swing + 0.1 * turn) * hang
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


## (Courting, behind her: where his body's middle is (her body mm) when his
## head reaches to her tail's root; k, how far it reaches on (1 his nose
## just touching her, less his chin up on her rump).)
func _behind_her(k := 1.0) -> Vector3:
	var hs := maxf(float(_mate.get("size")), 0.01)
	return Vector3(0.0, -body_h, float(S.body_len) * 0.5 + absf(float(S.mouth_z)) * k * size / hs)


## (His way to a point near her, not through her: if the straight line from
## him crosses her body, first to her side, beside her flank, then behind.)
func _around_her(p: Vector3) -> Vector3:
	var hs := float(_mate.get("size")) * MM
	var hc: Vector3 = _mate.call("_out", Vector3(0.0, 0.0, 0.0))
	var tail: Vector3 = _mate.call("_out", Vector3(0.0, 0.0, 100.0))
	var back := Vector2(tail.x - hc.x, tail.z - hc.z).normalized()
	var r := float(S.body_len) * 0.5 * hs + _space_r()
	var a := Vector2(_pos.x - hc.x, _pos.z - hc.z)
	var b := Vector2(p.x - hc.x, p.z - hc.z)
	var ab := b - a
	var t := clampf(-a.dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	if (a + ab * t).length() > r * 0.9 or a.dot(back) > r * 0.8:
		return p # (clear of her, or already behind her)
	var side := Vector2(-back.y, back.x)
	if a.dot(side) < 0.0:
		side = -side
	var w := side * r * 1.25 + back * r * 0.6
	return Vector3(hc.x + w.x, p.y, hc.z + w.y)


func _mate_leave() -> Vector3:
	return Vector3(float(S.body_w) * 3.0, -body_h, float(S.body_len) * 0.8)


func _court_secs() -> float:
	return 5.0


func _mating(dt: float) -> void:
	super(dt)
	_sit_to = 0.0
	_lie_to = 0.0
	if _mate_role == "male" and _mate_stage == "court":
		var nose: Vector3 = _mate.call("_out", _behind_her(0.95)) # (his nose to her)
		_target = Vector3(nose.x, _pos.y, nose.z)
		_neck_to = Vector2(-0.4, 0.0)
		_sniff = 1.0
		_tail_mode = "out"


func _after_mate() -> void:
	wander(_home_spot(), _radius)


## Joined, on her: his pelvis thrusting, in bouts (his body driven forward
## and back on her, a little tilt with it); his hind legs braced, bent,
## his feet planted on the ground under his rump.
## (A dict's "thrust": false, the species' own: a canid's tie.)
func _mount_thrust(m: Dictionary, her_t: Transform3D, hs: float) -> Dictionary:
	if not bool(m.get("thrust", true)):
		return m
	var mb: Basis = m.get("basis", Basis())
	var at: Vector3 = m.at
	# (his hind feet: where the species put them, pushed back along the
	# ground until each leg, hip to toe, is near its full length)
	var cur := transform * _body.transform
	var t0 := Transform3D(her_t.basis * mb, her_t * (at * hs)) * _body.transform
	var back := (her_t.basis * Vector3.BACK).normalized()
	back.y = 0.0
	back = back.normalized()
	var free: Dictionary = (m.get("free", {}) as Dictionary).duplicate()
	var feet_w := {}
	for i: int in [2, 3]:
		if not free.has(i):
			continue
		var L: Dictionary = legs[1]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var hip_w := t0 * Vector3(hp.x * side, hp.y, hp.z)
		var fw: Vector3 = cur * (free[i] as Vector3)
		var reach := (float(L.f) + float(L.t) + float(L.s)) * MM * size * float(S.get("brace", 0.74)) # (braced under his rump, bent, not locked straight: the species' own)
		# |fw + back * u - hip_w| = reach, for u >= 0
		var d := fw - hip_w
		var bq := 2.0 * d.dot(back)
		var cq := d.length_squared() - reach * reach
		var disc := bq * bq - 4.0 * cq
		if disc > 0.0:
			fw += back * (-bq + sqrt(disc)) * 0.5 # (back if his leg's too bent, forward if it's stretched)
		fw.y = _ground(fw.x, fw.z)
		feet_w[i] = fw
	# (the thrusts: quick, in bouts, a pause between; quicker the smaller he is)
	var rate := 2.6 / sqrt(maxf(float(S.body_len) / 560.0, 0.2))
	var bout := fmod(_mate_t, 4.5)
	var on := smoothstep(0.0, 0.3, bout) * (1.0 - smoothstep(3.0, 3.4, bout))
	var th := sin(_mate_t * TAU * rate) * on
	at += Vector3(0.0, -0.01, -1.0) * float(S.body_len) * 0.045 * th
	mb = mb * Basis(Vector3.RIGHT, 0.05 * th)
	var tn := Transform3D(her_t.basis * mb, her_t * (at * hs)) * _body.transform
	var inv := tn.affine_inverse()
	for i: int in feet_w:
		free[i] = inv * (feet_w[i] as Vector3)
	var out := m.duplicate()
	out["at"] = at
	out["basis"] = mb
	out["free"] = free
	return out


# --- steering (pilot.gd): its behaviours ----------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["hunt", "eat", "eat_at", "groom", "sit", "sleep"])
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
		"eat_at":
			if not (args.get("at") is Vector3):
				return false
			eat_at(args.at, float(args.get("seconds", 10.0)))
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
		"hunt", "groom", "sit", "sleep", "mark", "play", "birth", "nurse", "eat_at":
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
