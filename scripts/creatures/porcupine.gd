class_name Porcupine
extends "res://scripts/creatures/ursid.gd" # (by path: found whether or not the editor has seen the class yet)
## A North American porcupine (Erethizon dorsatum), life size (about 65 cm
## head and body, its tail 20 cm more; 7 kg), on the bears' make (Ursid:
## plantigrade, on its whole sole, a slow rolling waddle, a climber; the
## hunters' make under that, Carnivore): squat, round, its back humped
## highest over its rump, its legs short and bowed, pigeon toed; its head
## small and blunt, its muzzle short, its nose a big black pad, its eyes
## small and black, its ears small and round, half hidden in its fur; long
## whiskers. Its underfur dark brown black, woolly; over it its guard hairs,
## long (to 12 cm over its back), dark at their roots and pale at their
## tips, yellowish white: grizzled, shaggy; and its quills, some thirty
## thousand, among them, lying back along it: short over its shoulders and
## crown (a crest), longest and thickest over its rump and on top of its
## tail, each cream white with a dark brown tip, barbed (Strands: on its one
## skin, bending with it; raised, they stand up and fan out). Its belly and
## the underside of its tail bristly, quill-less. Its feet bare soled,
## black, pebbled (to grip bark); four long curved claws before, five
## behind. Its four front teeth chisels, their faces orange. (carnivore.
## gdshader's species 18.) The young (a porcupette, one): born with its eyes
## open and its quills soft, hardening within the hour; dark, brown,
## its guard hairs not yet grown out.
##
## Its ways (Ursid's, Carnivore's, and its own):
## - wander, waddling, swaying side to side, its nose down
## - nibble(plant): (Diet's "forbs", "sapling": a plant's leaves, never
##   anything taken off the plant itself) to it, its mouth to a leaf: a leaf
##   of it bitten off (a copy: the plant as it was), sat back on its
##   haunches, the leaf in its forepaws, eaten bite by bite; another
## - browse(bush) (berries, its lips to each), eat_at (a fallen crab apple,
##   an acorn: eaten where it lies)
## - climb(tree, r, height): up the trunk, hugging it, its claws and its
##   pebbled soles gripping, its tail braced against the bark below it; up
##   there, gnawing the bark (its inner bark, the cambium: a pale scar left
##   where it's been, the bark gone in patches); down again, rump first
## - bristle(at, secs): its threat: its quills up, its back to it, its tail
##   lashing side to side (to drive its quills into whatever touches it),
##   its teeth chattering, backing at it
## - bitten(by): a hunter's bite: its quills into its face (stuck there,
##   barbed); it backs off, pawing at its muzzle, and leaves it (unless it
##   was caught face to face, its quills down: then it's a meal)
## - whine(): its call (a male's in the autumn: a whining, moaning song)
## - mate(her): he goes to her, the two up on their hind legs facing, nose
##   to nose, whining; she curls her tail up over her back, her quills flat,
##   and he mounts her from behind
## - birth(1, den) (in its den: a hollow log, Opossum.den()): one young,
##   up and about almost at once; nursed sitting up, the young under her;
##   after her; play(): the young's: hopping, spinning, bristling at nothing
## Steering (pilot.gd): act nibble {plant}, bristle {at, seconds}, whine,
## and the bears' and the hunters' own.

const OpossumScript := preload("res://scripts/creatures/opossum.gd")
const SPEC := {
	"species": 18, "plantigrade": true, "climbs": true, "sole_hind": 1.0, "boxy": 2.1, "belly": 0.95,
	"body": [[-250.0, 15.0, 72.0, 80.0], [-200.0, 12.0, 102.0, 108.0], [-90.0, 18.0, 130.0, 128.0], [50.0, 35.0, 146.0, 140.0],
			[170.0, 42.0, 136.0, 132.0], [250.0, 30.0, 98.0, 98.0], [295.0, 12.0, 50.0, 52.0]],
	"body_h": 178.0, "body_len": 545.0, "body_w": 146.0,
	"neck_at": Vector3(0.0, 25.0, -225.0), "neck": [[30.0, 0.0, 86.0, 92.0], [-20.0, 0.0, 74.0, 78.0], [-48.0, 0.0, 62.0, 66.0]], "neck_pitch": 0.05,
	"head_at": Vector3(0.0, -4.0, -62.0),
	"head": [[30.0, 0.0, 44.0, 44.0], [0.0, 4.0, 52.0, 52.0], [-40.0, -2.0, 40.0, 38.0], [-80.0, -6.0, 24.0, 22.0], [-104.0, -8.0, 14.0, 13.0]],
	"jaw_at": Vector3(0.0, -28.0, -38.0), "jaw": [[0.0, 0.0, 22.0, 10.0], [-30.0, -1.0, 17.0, 8.0], [-56.0, 0.0, 10.0, 6.0]], "mouth": 0.5,
	"mouth_z": -400.0, "muzzle_z": -70.0,
	"eye": {"at": Vector3(33.0, 20.0, -36.0), "size": Vector3(9.0, 9.0, 9.0), "color": Color(0.02, 0.018, 0.016), "slit": 1.0},
	"nose": {"at": Vector3(0.0, -6.0, -106.0), "size": Vector3(30.0, 24.0, 16.0), "color": Color(0.05, 0.045, 0.045)},
	"whisker": 75.0,
	"ear": {"at": Vector3(42.0, 34.0, 10.0), "len": 22.0, "width": 26.0, "point": 0.0, "tilt_back": 0.35, "spread": 0.7},
	"tail": {"base": Vector3(0.0, 28.0, 285.0), "n": 4, "seg": 48.0, "radii": [58.0, 52.0, 42.0, 28.0], "carry": [0.75, 0.12], "wrap": 0.2, "flat": 0.78, "twitch": 0.0},
	"fore": {"hip": Vector3(78.0, -70.0, -150.0), "a": 80.0, "b": 70.0, "m": 36.0, "p": 30.0, "home": Vector2(98.0, -178.0), "r": 17.0},
	"hind": {"hip": Vector3(88.0, -48.0, 185.0), "a": 90.0, "b": 80.0, "m": 58.0, "p": 38.0, "home": Vector2(104.0, 160.0), "r": 21.0},
	"claw": 30.0, "fur": 45.0, "tail_fur": 30.0,
	"walk": 0.28, "trot": 0.55, "run": 0.9,
	"stalk_from": 0.6, "spring": 0.3, "stalk_crouch": 0.1, "stalk_neck": -0.3, "eat_crouch": 0.3,
	"sit_drop": 85.0, "sit_pitch": 0.95, "lie_h": 110.0,
	"mate_secs": 14.0,
	# its head sculpted (SculptHead), from photographs: small and blunt,
	# round crowned, its muzzle short and deep, its nose pad big and black;
	# its eyes small, black, set a little forward
	"sculpt": {
		"z": [30.0, 15.0, 0.0, -15.0, -30.0, -45.0, -60.0, -72.0, -84.0, -96.0, -106.0],
		"top": [44.0, 54.0, 58.0, 57.0, 53.0, 46.0, 38.0, 33.0, 28.0, 22.0, 15.0],
		"bot": [-42.0, -46.0, -48.0, -47.0, -44.0, -40.0, -36.0, -32.0, -28.0, -23.0, -15.0],
		"w": [40.0, 48.0, 52.0, 50.0, 45.0, 39.0, 33.0, 29.0, 25.0, 20.0, 14.0],
		"wl": [44.0, 53.0, 57.0, 55.0, 48.0, 41.0, 35.0, 30.0, 26.0, 21.0, 14.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.5, 2.5, 2.4, 2.2],
		"eye": Vector3(33.0, 22.0, -36.0), "eye_r": 5.0, "socket": 0.6, "lid": 0.7,
		"brow": 1.2, "cheek": 2.0, "stop": 1.0, "pads": 1.6, "flews": 0.7, "nose_r": 14.0,
		"almond": 0.85, "slant": 0.0, "look_fwd": 0.6, "pupil": Vector2(0.8, 0.8),
	},
}

var _quills: MeshInstance3D # (its quills and guard hairs: Strands, the "erect" blend shape their bristling)
var _bristle := 0.0
var _bristle_to := 0.0
var _threat := Vector3.ZERO
var _plant: Node3D # (nibble's)
var _leaf: MeshInstance3D # (the leaf it's eating, in its mouth, then its forepaws)
var _leaf_left := 0.0
var _leaves := 0
var _scars: Array[Node3D] = [] # (the bark it's gnawed: its scars)
var _incisors: Array[MeshInstance3D] = []
var _hurt_secs := 0.0
var _gnaw_t := 0.0
static var _leaf_mat: StandardMaterial3D


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.18 if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.08


# --- its own parts --------------------------------------------------------------------

func _build_extra() -> void:
	# its claws: four long curved ones on each forefoot, five on each hind
	var claw := _coat(7)
	for i in 4:
		var paw := _legx[i][1] as MeshInstance3D
		var n := 4 if i < 2 else 5
		for k in n:
			var x := (float(k) - (n - 1) * 0.5) * 0.2
			var l := (0.42 if i < 2 else 0.3)
			_stick(Vector3(x, -0.12, 0.4), Vector3(x * 1.1, -0.42, 0.4 + l), 0.04, claw, paw)
	# its incisors: chisels, their faces orange, the lower pair longer; just
	# showing under its lip
	var orange := _mat(Color(0.82, 0.42, 0.1), 0.35)
	var sc: Dictionary = S.sculpt
	for side: float in [-1.0, 1.0]:
		var z := -100.0
		var y := SculptScript._key(sc, "bot", z)
		_incisors.append(_stick(Vector3(2.4 * side, y + 3.0, z), Vector3(2.4 * side, y - 5.0, z - 1.0), 1.7, orange, _head))
		_incisors.append(_stick(Vector3(2.2 * side, 6.0, -52.0), Vector3(2.2 * side, 12.0, -56.0), 1.6, orange, _jaw))
	# its quills and guard hairs
	_grow_quills()


## Its quills and guard hairs, on its skin (Strands): the quills cream,
## dark tipped, short over its shoulders and its crown, long and thick over
## its rump and the top of its tail; its guard hairs long, dark rooted,
## pale tipped, over its back and sides, drooping; none on its face, its
## legs, its belly.
func _grow_quills() -> void:
	if _torso == null:
		return
	var yk := young
	var eye_z := float((S.sculpt as Dictionary).eye.z)
	var cream := Color(0.9, 0.86, 0.74) if not yk else Color(0.62, 0.56, 0.48)
	var dark := Color(0.09, 0.075, 0.06)
	var pick_quill := func(p: Vector3, n: Vector3, c0: Color, h: Vector3) -> Dictionary:
		var part := int(roundf(c0.r))
		var fw := c0.b
		var back := Vector3.BACK - n * n.dot(Vector3.BACK)
		if back.length() < 0.1:
			back = Vector3.DOWN - n * n.dot(Vector3.DOWN)
		back = back.normalized()
		if part == 6: # (the top of its tail: thick with them)
			if n.y < -0.15:
				return {}
			return {"w": 1.0, "len": 42.0, "r": 1.2, "lie": back * 0.96 + n * 0.25, "up": n * 0.8 + back * 0.6, "root": cream, "tip": dark, "tip_from": 0.72}
		if part != 0:
			return {}
		if fw > 0.3: # (its crown, behind its eyes: a crest)
			if h.z < eye_z + 14.0 or n.y < 0.15:
				return {}
			return {"w": 0.9, "len": 30.0, "r": 0.9, "lie": back * 0.95 + n * 0.3, "up": n + back * 0.25, "root": cream, "tip": dark, "tip_from": 0.7}
		if n.y < -0.25: # (not its belly)
			return {}
		var rump := smoothstep(-200.0, 200.0, p.z) # (the further back, the longer and the more)
		var side_k := smoothstep(-0.25, 0.25, n.y)
		return {"w": (0.35 + 0.65 * rump) * side_k, "len": lerpf(32.0, 72.0, rump), "r": lerpf(0.9, 1.4, rump), "lie": back * 0.97 + n * 0.2,
				"up": n * 0.85 + back * 0.45, "root": cream, "tip": dark, "tip_from": 0.74}
	var guard_root := Color(0.13, 0.1, 0.08)
	var guard_tip := Color(0.82, 0.78, 0.64) if not yk else Color(0.5, 0.42, 0.33)
	var pick_hair := func(p: Vector3, n: Vector3, c0: Color, h: Vector3) -> Dictionary:
		var part := int(roundf(c0.r))
		var fw := c0.b
		var back := Vector3.BACK - n * n.dot(Vector3.BACK)
		back = back.normalized() if back.length() > 0.1 else Vector3.DOWN
		if part == 6: # (its tail: long hairs over it, stiff bristles under it)
			return {"w": 0.8, "len": 60.0 if n.y > -0.2 else 30.0, "r": 0.6, "lie": back + n * 0.25, "up": n + back * 0.5, "root": guard_root, "tip": guard_tip if n.y > -0.2 else guard_root * 1.6, "tip_from": 0.45, "droop": 0.3, "sides": 3}
		if part != 0 or n.y < -0.45:
			return {}
		if fw > 0.3: # (its cheeks and crown: shorter)
			if h.z < eye_z + 4.0:
				return {}
			return {"w": 0.5, "len": 40.0, "r": 0.4, "lie": back + n * 0.3, "up": n + back * 0.5, "root": guard_root, "tip": guard_tip, "tip_from": 0.55, "droop": 0.3, "sides": 3}
		var mid := 1.0 - smoothstep(150.0, 280.0, p.z) * 0.5 # (its rump more quills than hair)
		return {"w": mid, "len": (135.0 if not yk else 62.0) * lerpf(0.65, 1.0, smoothstep(-0.3, 0.6, n.y)), "r": 0.6, "lie": back + n * 0.32,
				"up": n + back * 0.55, "root": guard_root, "tip": guard_tip, "tip_from": 0.38, "droop": 0.55, "sides": 3}
	var all := func(p: Vector3, n: Vector3, c0: Color, h: Vector3) -> Dictionary:
		# (half quills, half hairs, each where its own kind grows)
		var d: Dictionary = pick_quill.call(p, n, c0, h) if (int(absf(p.x * 7.3 + p.y * 3.1 + p.z * 1.7)) % 5) < 2 else pick_hair.call(p, n, c0, h)
		return d
	_quills = Strands.grow(_torso, 6500 if not yk else 4500, all, 7 + int(male))


func _set_bristle(k: float) -> void:
	if _quills:
		_quills.set_blend_shape_value(0, k)


# --- its den ------------------------------------------------------------------------------

## Its den: a hollow log (Opossum.den()), big enough for it.
static func den(scale_ := 1.7) -> Node3D:
	var d := OpossumScript.den()
	d.scale = Vector3.ONE * scale_
	return d


func _home_door(h: Node3D) -> Vector3:
	return h.global_position # (the log's open end)


# --- what it does ---------------------------------------------------------------------------

## A plant's leaves (Diet's "forbs", "sapling"): one bitten off (a copy; the
## plant left as it was), held in its forepaws, eaten sitting up.
func nibble(plant: Node3D) -> void:
	if plant == null or not is_instance_valid(plant) or dead:
		return
	_mode = "nibble"
	_plant = plant
	_stage = 0
	_st = 0.0
	_leaves = 0


## Its threat: quills up, its back to `at`, its tail lashing, its teeth
## chattering; secs.
func bristle(at: Vector3, secs := 8.0) -> void:
	if dead or _mode == "climb":
		return
	if _mode != "bristle":
		_stage = 0
		_st = 0.0
	_mode = "bristle"
	_threat = at
	_wait = secs
	_drop_leaf()


## Its call: whining, moaning (a male's song in the autumn).
func whine(secs := 5.0) -> void:
	_mode = "whine"
	_st = 0.0
	_wait = secs


## A hunter's bite (by: its jaws on it): its quills into the hunter's face,
## and the hunter backs off; true if so. False: caught (its quills down, the
## hunter at its face).
func bitten(by: Node3D) -> bool:
	if dead or by == null:
		return false
	var face_on := _bristle < 0.4 and is_instance_valid(by) and (_out(Vector3(0.0, 0.0, -300.0)) - by.global_position).length() < (_out(Vector3(0.0, 0.0, 300.0)) - by.global_position).length()
	if face_on and rng.randf() < 0.5:
		return false
	_bristle = 1.0
	_set_bristle(1.0)
	_quill(by)
	bristle(by.global_position, 6.0)
	return true


## (Its quills left in the hunter's muzzle, barbed: a dozen or so, cream,
## dark tipped, every way; and the hunter off, pawing at them.)
func _quill(by: Node3D) -> void:
	var head: Node3D = by.get("_head")
	if head == null:
		return
	var cream := _mat(Color(0.9, 0.86, 0.74), 0.5)
	var dark := _mat(Color(0.09, 0.075, 0.06), 0.5)
	var bs := maxf(float(by.get("size")), 0.05)
	var sc := (MM * size) / (MM * bs) # (its quills in the hunter's mm)
	var mz := float((by.get("S") as Dictionary).get("mouth_z", -300.0))
	var tip := minf(mz * 0.25, -60.0)
	var r := RandomNumberGenerator.new()
	r.seed = get_instance_id()
	var held := Node3D.new()
	held.name = "quills"
	head.add_child(held)
	for k in 14:
		var at := Vector3(r.randf_range(-1.0, 1.0) * 25.0, r.randf_range(-20.0, 25.0), tip * r.randf_range(0.35, 1.0))
		var d := Vector3(r.randf_range(-1.0, 1.0), r.randf_range(-0.2, 1.0), r.randf_range(-1.0, 0.3)).normalized()
		var L := r.randf_range(35.0, 65.0) * sc
		_stick(at - d * L * 0.15, at + d * L * 0.7, 1.1 * sc, cream, held)
		_stick(at + d * L * 0.7, at + d * L * 0.85, 0.8 * sc, dark, held)
	var tw := held.create_tween() # (worked out at last, in time)
	tw.tween_interval(240.0)
	tw.tween_callback(held.queue_free)
	if by.has_method("hurt_face"):
		by.call("hurt_face", _pos, 5.0)


# --- its thinking ------------------------------------------------------------------------

func _think(dt: float) -> void:
	_hurt_secs -= dt
	_bristle_to = 0.0
	# (a hunter after it, near: its quills up at it)
	if not young or size > 0.25:
		if _mode not in ["bristle", "climb"] and int(_t * 2.0) % 2 == 0 and fmod(_t, 0.5) < dt:
			for o in get_parent().get_children():
				if o != self and o is Node3D and o.get("_prey") == self and o.get("_mode") == "hunt" and (o as Node3D).position.distance_to(position) < 3.0:
					bristle((o as Node3D).position, 8.0)
					break
	match _mode:
		"nibble":
			_common(dt)
			_nibble(dt)
			_after(dt)
			return
		"bristle":
			_common(dt)
			_bristling(dt)
			_after(dt)
			return
		"whine":
			_common(dt)
			_target = _pos
			_neck_to = Vector2(0.35, 0.0)
			_jaw_to = 0.3 * maxf(sin(_st * 3.2), 0.0) + 0.05
			_sit_to = 0.6
			if _wait <= 0.0:
				_sit_to = 0.0
				wander(_home_spot(), _radius)
			_after(dt)
			return
	if _mode != "nibble":
		_drop_leaf()
	super(dt)
	if _mode == "climb" and _stage == 2: # (up there: gnawing the bark)
		_gnaw(dt)
	_after(dt)


func _after(dt: float) -> void:
	if _mate_role == "female" and _mate_stage == "joined":
		_bristle_to = 0.0
	_bristle = move_toward(_bristle, _bristle_to, dt * (3.0 if _bristle_to > _bristle else 0.6))
	_set_bristle(_bristle)


func _bristling(dt: float) -> void:
	var to := _threat - _pos
	to.y = 0.0
	_bristle_to = 1.0
	_ears_to = -0.6
	_target = _pos
	var away := atan2(to.x, to.z) # (its back to it)
	if absf(wrapf(away - _yaw, -PI, PI)) > 0.35:
		_turn_to = away
	else:
		_turn_to = INF
		# (backing at it, a step at a time)
		if to.length() > 0.45 and fmod(_st, 2.5) < 0.6:
			_pos += to.normalized() * dt * 0.12
			_target = _pos
	_tail_mode = "lash"
	_jaw_to = 0.12 * maxf(sin(_st * 26.0), 0.0) # (its teeth chattering)
	_neck_to = Vector2(-0.45, 0.4 * sin(_st * 0.8))
	_crouch = move_toward(_crouch, 0.25, dt)
	if _wait <= 0.0:
		_crouch = 0.0
		wander(_home_spot(), _radius)


## (Nibbling: to the plant, its mouth to a leaf; a leaf bitten off, sat back
## with it in its forepaws, eaten; two or three.)
func _nibble(dt: float) -> void:
	if not is_instance_valid(_plant):
		_drop_leaf()
		wander(_home_spot(), _radius)
		return
	var leaf_at := _leaf_on_plant()
	var to := leaf_at - _pos
	to.y = 0.0
	var reach := absf(float(S.mouth_z)) * MM * size * 0.95
	match _stage:
		0: # (to it)
			_target = leaf_at - to.normalized() * reach if to.length() > 0.01 else _pos
			_neck_to = Vector2(-0.3, 0.0)
			_sniff = 1.0
			if (to.length() < reach * 1.2 and _speed < 0.04) or _st > 15.0:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # (its mouth to the leaf: raised up to it, or down; a step in)
			_target = _pos
			var m := _mouth()
			var dy := leaf_at.y - m.y
			_berry_pitch = clampf(_berry_pitch + clampf(dy * 8.0, -1.0, 1.0) * dt * 1.5, -1.2, 0.35)
			_stand_to = move_toward(_stand_to, 0.6 if (_berry_pitch >= 0.3 and dy > 0.03) else (0.0 if _berry_pitch < 0.2 else _stand_to), dt)
			_neck_to = Vector2(_berry_pitch, 0.0)
			var off := Vector3(leaf_at.x - m.x, 0.0, leaf_at.z - m.z)
			if off.length() > 0.012:
				_pos += off.limit_length(0.08 * dt)
				_target = _pos
			_sniff = 1.0
			if m.distance_to(leaf_at) < 0.03 or (_st > 8.0 and m.distance_to(leaf_at) < 0.06):
				_bite_leaf()
				_stage = 2
				_st = 0.0
			elif _st > 12.0: # (out of its reach: given up)
				_stand_to = 0.0
				wander(_home_spot(), _radius)
		2: # (sat back on its haunches, the leaf in its forepaws at its mouth, eaten bite by bite)
			_target = _pos
			_stand_to = 0.0
			_sit_to = 1.0
			_neck_to = Vector2(-0.25, 0.0)
			_chew = 1.0
			_jaw_to = 0.12 * maxf(sin(_st * 8.0), 0.0)
			_leaf_left = maxf(_leaf_left - dt / 7.0, 0.0)
			if _leaf:
				_leaf.scale = _leaf_size() * maxf(_leaf_left, 0.05)
			if _leaf_left <= 0.0:
				_drop_leaf()
				_leaves += 1
				_sit_to = 0.0
				_stage = 1 if _leaves < 3 else 3
				_st = 0.0
		3:
			_target = _pos
			_sit_to = 0.0
			if _sit < 0.05:
				wander(_home_spot(), _radius)


## (Where on the plant its mouth goes: a leaf's place on it, the plant's,
## at a height it can reach.)
func _leaf_on_plant() -> Vector3:
	var p := _plant.position
	var reach_up := (float(S.body_h) + 300.0) * MM * size # (its mouth at its highest, up on its hind legs)
	var toward := Vector3(_pos.x - p.x, 0.0, _pos.z - p.z).normalized()
	var lv: Array = _plant.get_meta("leaves", [])
	if not lv.is_empty(): # (a forb's own leaves: one it can reach, on its near side)
		var best := Vector3.INF
		var bs := INF
		for i in lv.size():
			var e: Array = lv[(i + _leaves * 3) % lv.size()]
			var q: Vector3 = e[0]
			if q.y - p.y > reach_up:
				continue
			var sc := Vector3(q.x - p.x, 0.0, q.z - p.z).dot(-toward) + float((i * 7 + _leaves) % 5) * 0.01
			if sc < bs:
				bs = sc
				best = q
		if best != Vector3.INF:
			return best
	var top := 0.35
	for ch in _plant.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh:
			top = (ch as MeshInstance3D).get_aabb().end.y
			break
	var k := float((get_instance_id() + _leaves * 7) % 5) / 5.0
	var y := minf(top * lerpf(0.55, 0.85, k), reach_up)
	var a := float(_leaves) * 2.1 + float(get_instance_id() % 13)
	return p + toward * 0.08 + Vector3(cos(a), 0.0, sin(a)) * 0.03 + Vector3.UP * maxf(y, 0.06)


func _leaf_size() -> Vector3:
	return Vector3(0.05, 0.003, 0.035) * size / 0.5 * 1.6


## (A leaf: bitten off the plant (a copy: the plant as it was), held.)
func _bite_leaf() -> void:
	_drop_leaf()
	if _leaf_mat == null:
		_leaf_mat = StandardMaterial3D.new()
		_leaf_mat.albedo_color = Color(0.3, 0.48, 0.18)
		_leaf_mat.roughness = 0.7
		_leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 4
	_leaf = MeshInstance3D.new()
	_leaf.mesh = s
	_leaf.material_override = _leaf_mat
	get_parent().add_child(_leaf)
	_leaf_left = 1.0
	_leaf.scale = _leaf_size()


func _drop_leaf() -> void:
	if is_instance_valid(_leaf):
		_leaf.queue_free()
	_leaf = null


## (Up the trunk: gnawing its bark, its mouth to it; a pale scar where it's
## eaten through to the wood, growing.)
func _gnaw(dt: float) -> void:
	_target = _pos
	_neck_to = Vector2(-0.2, 0.35 * sin(_st * 0.4))
	_chew = 1.0
	_jaw_to = 0.15 * maxf(sin(_st * 10.0), 0.0)
	var m := _mouth()
	var out := Vector3(m.x - _tree.x, 0.0, m.z - _tree.z)
	if out.length() < 1e-4:
		return
	var on := _tree + out.normalized() * _tree_r + Vector3(0.0, m.y - _tree.y, 0.0)
	if m.distance_to(on) > 0.08 * size / 0.5 + 0.03:
		return # (not at the bark)
	var scar: Node3D = _scars[_scars.size() - 1] if not _scars.is_empty() and (_scars[_scars.size() - 1].position).distance_to(on) < 0.06 else null
	if scar == null:
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		var mi := MeshInstance3D.new()
		mi.mesh = s
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color(0.86, 0.78, 0.6)
		wood.roughness = 0.8
		mi.material_override = wood
		get_parent().add_child(mi)
		mi.position = on
		var yaw := atan2(out.x, out.z)
		mi.rotation = Vector3(0.0, yaw, 0.0)
		mi.scale = Vector3(0.02, 0.02, 0.004)
		_scars.append(mi)
		scar = mi
	scar.scale = scar.scale.move_toward(Vector3(0.07, 0.1, 0.006), dt * 0.004)


func _climb(dt: float) -> void:
	super(dt)
	if _stage == 2: # (up there a good while, gnawing)
		_gnaw_t += dt
		if _gnaw_t < 25.0:
			_st = minf(_st, 5.0)
	elif _stage < 2:
		_gnaw_t = 0.0
	if _climb_k > 0.5:
		_tail_mode = "brace"


# --- the young ------------------------------------------------------------------------

func birth(n := 1, den_: Node3D = null) -> void:
	super(1 if n > 0 else 0, den_)


func _young_one() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	parent.add_child(y)
	var at := _out(Vector3(-float(S.body_w) * 1.2, -body_h, -40.0))
	y.call("place", Vector3(at.x, _pos.y, at.z), _yaw + rng.randf_range(-0.5, 0.5))
	y.set("height", height)
	y.set("_mother", self)
	y.set("size", 0.2)
	y.call("grow", 0.5, 600.0)
	young_ones.append(y)


## (Nursed: she sits up on her haunches; the young under her, at her belly.)
func _nurse(dt: float) -> void:
	_target = _pos
	match _stage:
		0:
			var at := home_den.position if is_instance_valid(home_den) else _pos
			_target = at if _pos.distance_to(at) > 0.4 else _pos
			if _pos.distance_to(at) <= 0.4 or _st > 12.0:
				_target = _pos
				_stage = 1
				_st = 0.0
		1:
			_sit_to = 1.0
			_neck_to = Vector2(-0.5, 0.0)
			for y in young_ones:
				if is_instance_valid(y) and y.get("_mode") != "nursing":
					y.set("_mode", "nursing")
					y.set("_stage", 0)
			if _st > 22.0:
				for y in young_ones:
					if is_instance_valid(y):
						y.set("_mode", "follow")
				_sit_to = 0.0
				wander(_home_spot(), _radius)


## (A porcupette's.) Its play: on its own (one young: no others to play
## with): a hop, a spin round, its quills up at nothing.
func play() -> void:
	if not young:
		return
	_mode = "play"
	_stage = 0
	_st = 0.0


## (A porcupette at play: a hop, a spin round, its quills up at nothing.)
func _play(dt: float) -> void:
	_target = _pos
	match _stage:
		0:
			_bristle_to = 1.0
			_turn_to = _yaw + PI * 0.9 if _st < 0.05 else _turn_to
			if _st > 1.2 and not airborne:
				var a := rng.randf() * TAU
				_leap(_pos + Vector3(cos(a), 0.0, sin(a)) * 0.12, 1.1)
				_stage = 1
				_st = 0.0
		1:
			_bristle_to = 0.7
			_tail_mode = "lash"
			if not airborne and _st > 0.6:
				_stage = 2
				_st = 0.0
				_turn_to = _yaw - PI * 0.8
		2:
			if _st > 1.6:
				_mode = "follow" if is_instance_valid(_mother) else "wander"


# --- the pose ---------------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	# (its waddle: rolling side to side as it goes)
	if not airborne and _climb_k < 0.05 and _gait_now != "stand":
		_roll += 0.07 * sin(_gphase * TAU) * clampf(_speed * 6.0, 0.0, 1.0)
	# (its incisors: the lower's tips showing, the upper's)
	# the leaf held: in its mouth as it's bitten, then in its forepaws, at its mouth
	if is_instance_valid(_leaf):
		var m := _mouth()
		var held := _mode == "nibble" and _stage == 2 and _sit > 0.6
		if held:
			var inv := (transform * _body.transform).affine_inverse()
			var mb: Vector3 = inv * m
			for i in 2:
				var side := 1.0 if i % 2 == 1 else -1.0
				_pose_foot[i] = mb + Vector3(side * 16.0, -26.0, 14.0)
			var fwd := -(transform * _body.transform).basis.z
			fwd.y = 0.0
			fwd = fwd.normalized()
			var right := fwd.cross(Vector3.UP).normalized()
			var k := size / 0.5
			var ls := _leaf_size() * maxf(_leaf_left, 0.05)
			_leaf.global_transform = Transform3D(Basis(right * ls.x, fwd * ls.y, Vector3.UP * ls.z), m + fwd * 0.012 * k + Vector3.DOWN * 0.015 * k)
		else:
			_leaf.global_position = m
	elif _mode == "nibble" and _sit < 0.05:
		for i in 2:
			if _stand <= 0.001:
				_pose_foot[i] = null


func _pose_tail(dt: float) -> void:
	if _tail_mode not in ["lash", "brace", "up"]:
		super(dt)
		return
	for k in _tail.size():
		var down := 0.0
		var swing := 0.0
		match _tail_mode:
			"lash": # (swung hard side to side: to drive its quills into whatever's at it)
				down = 0.35 if k == 0 else 0.05
				swing = (0.55 if k == 0 else 0.15) * sin(_t * 7.0) * (1.0 if fmod(_st, 1.6) < 0.9 else 0.3)
			"brace": # (pressed against the trunk below it, a prop)
				down = 1.1 if k == 0 else 0.1
			"up": # (curled up over her back)
				down = -0.9 if k == 0 else -0.35
		var now: Array = _tail_k[k]
		var a := lerpf(float(now[0]), down, 1.0 - exp(-8.0 * dt))
		var r := lerpf(float(now[1]), swing, 1.0 - exp(-10.0 * dt))
		_tail_k[k] = [a, r]
		_tail[k].rotation = Vector3(a, r, 0.0)


# --- mating -----------------------------------------------------------------------------

func _court_secs() -> float:
	return 7.0


func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, -float(S.body_len) * 0.85) # (before her, face to face)


func _mating(dt: float) -> void:
	super(dt)
	if _mate_stage in ["court", "wait"] and is_instance_valid(_mate):
		# (up on their hind legs, the two of them, facing, nose to nose, whining)
		var other: Node3D = _mate
		var to: Vector3 = (other.get("_pos") as Vector3) - _pos
		to.y = 0.0
		if to.length() < 1.2:
			_stand_to = 1.0
			_turn_to = INF
			_yaw = lerp_angle(_yaw, atan2(-to.x, -to.z), 1.0 - exp(-3.0 * dt)) # (turned to face the other)
			_neck_to = Vector2(-0.95, 0.0) # (leant in, nose to nose)
			_jaw_to = 0.2 * maxf(sin(_t * 3.0), 0.0)
		if _mate_role == "male":
			_target = Vector3(_pos.x, _pos.y, _pos.z)
	else:
		_stand_to = 0.0
	if _mate_role == "female" and _mate_stage == "joined": # (her tail curled up over her back, her quills flat)
		_stand_to = 0.0
		_tail_mode = "up"


func _mount() -> Dictionary:
	_neck_to = Vector2(-0.3, 0.0)
	return {"at": Vector3(0.0, float(S.body_h) * 0.75, float(S.body_len) * 0.5), "basis": Basis(Vector3.RIGHT, 0.45), "grips": {
		0: Vector3(-float(S.body_w) * 0.9, -20.0, 120.0), 1: Vector3(float(S.body_w) * 0.9, -20.0, 120.0)}}


func _on_mate_start() -> void:
	if _mode in ["bristle", "nibble", "whine"]:
		_mode = "idle"
	_drop_leaf()


# --- steering (pilot.gd) ------------------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["nibble", "bristle", "whine"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"nibble":
			var pl: Node3D = args.get("plant")
			if pl == null:
				return false
			nibble(pl)
		"bristle":
			bristle(args.get("at", _pos + _p_heading()), float(args.get("seconds", 8.0)))
		"whine":
			whine(float(args.get("seconds", 5.0)))
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["nibble", "bristle", "whine"]:
		return _mode != name
	return super(name)


func _exit_tree() -> void:
	_drop_leaf()
