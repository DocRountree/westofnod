extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## The dogs' ways (RedFox, Coyote, GreyWolf), on the hunters' make
## (Carnivore):
## - hunting: small prey (a mouse) by sound (stalking, still, its head
##   cocked one way then the other, listening; then the pounce, high,
##   arcing, diving nose and forefeet first onto it); bigger (a hare) run
##   down, galloping after it, and a lunge
## - marking: a squat
## - howl(secs) (S.howl: the coyote's, the wolf's): sitting, its head
##   thrown back, its muzzle up, its mouth rounded, its ears back a little;
##   (a coyote's yips between)
## - greeting, courting: its tail wagging
## - mating: he mounts her, then turns round off her, and they're tied,
##   standing tail to tail, a long while

## A den: a mound of dug earth, its mouth a dark hole at one side (-z),
## its spoil fanned out before it (a fox's; scale: a coyote's, a wolf's,
## bigger). Its origin on the ground at its middle.
static func den(scale_ := 1.0) -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.42, 0.32, 0.22)
	earth.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.04, 0.03)
	dark.roughness = 1.0
	for p in [[Vector3(0.0, 0.0, 0.0), Vector3(1.2, 0.5, 1.0), earth], [Vector3(0.0, 0.0, -0.55), Vector3(0.9, 0.12, 0.6), earth],
			[Vector3(0.0, 0.1, -0.47), Vector3(0.24, 0.22, 0.1), dark]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = (p[0] as Vector3) * scale_
		mi.scale = (p[1] as Vector3) * scale_
		mi.material_override = p[2]
		root.add_child(mi)
	return root


# --- its own ways --------------------------------------------------------------------

## Its attack: on a small one, the pounce (up high, arcing, coming down
## nose and forefeet first on it); a bigger one run down, and a lunge.
func _attack(_dt: float, p: Vector3, d: float) -> bool:
	_crouch = 0.0
	if _small_prey():
		_leap(p, 1.1)
		return true
	var reach := 0.45 * size / 0.5
	if d > reach:
		_target = p
		_pace = float(S.run) * 0.75 * lerpf(0.35, 1.0, size)
		_tail_mode = "out"
		_ears_to = -0.3
		return false
	_pace = -1.0
	_leap(p, 0.3)
	return true


func _small_prey() -> bool:
	return is_instance_valid(_prey) and float(_prey.get("body_h") if _prey.get("body_h") != null else 0.0) * float(_prey.get("size") if _prey.get("size") != null else 1.0) < 25.0


## (Listening for it, still: the head cocked; or eyeing it, low, a bigger one.)
func _attack_ready(dt: float) -> void:
	if not _small_prey():
		_tail_mode = "low"
		_look_to = Vector2(0.0, 0.0)
		_st += dt * 0.5 # (a shorter wait: off after it sooner)
		return
	_look_to = Vector2(-0.25, 0.0)
	_tail_mode = "low"


func _mark(_dt: float) -> void:
	_sit_to = 0.4 if _st < 2.2 else 0.0 # (a squat)
	_tail_mode = "out"
	_neck_to = Vector2(-0.2, 0.0)


func _mount() -> Dictionary:
	# on her from behind, his forelegs clasping her; then off her, turned
	# round, tied, standing tail to tail
	var k := 0.0
	if _mate_stage == "joined":
		k = clampf((_mate_t - mate_secs * 0.18) / 1.6, 0.0, 1.0)
	elif _mate_stage == "part":
		k = 1.0
	var f := float(S.body_len) / 560.0 # (the fox's measures, scaled to its own)
	var fw := float(S.body_w) / 72.0
	var on_at := Vector3(0.0, 120.0 * fw, 235.0 * f)
	var on_b := Basis(Vector3.RIGHT, 0.4)
	var tie_at := Vector3(0.0, 0.0, float(S.body_len) + 20.0)
	var tie_b := Basis(Vector3.UP, PI)
	var e := k * k * (3.0 - 2.0 * k)
	var b := Basis(on_b.get_rotation_quaternion().slerp(tie_b.get_rotation_quaternion(), e))
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	var grips := {}
	for i in 4:
		var side := 1.0 if i % 2 == 1 else -1.0
		if i < 2 and e < 0.5:
			grips[i] = Vector3(72.0 * fw * side, 15.0 * fw, 110.0 * f)
		elif i >= 2 and e < 0.5:
			var w: Vector3 = _mate.call("_out", Vector3(55.0 * fw * side, -body_h, 340.0 * f))
			w.y = _ground(w.x, w.z)
			free[i] = inv * w
		else:
			free[i] = inv * _home(i)
	_tail_mode = "out"
	return {"at": on_at.lerp(tie_at, e), "basis": b, "grips": grips, "free": free, "thrust": e < 0.02} # (thrusting only before the tie)


func _after_mate() -> void:
	_tail_mode = "carry"
	wander(_home_spot(), _radius)


# --- howling, wagging ----------------------------------------------------------------

## (The coyote's, the wolf's.) Sitting, its head thrown back, howling.
func howl(secs := 6.0) -> void:
	if not bool(S.get("howl", false)):
		return
	_mode = "howl"
	_st = 0.0
	_wait = secs


func _think(dt: float) -> void:
	if _mode == "howl":
		_st += dt
		_wait -= dt
		_target = _pos
		_sit_to = 1.0
		_tail_mode = "wrap"
		_ears_to = -0.25
		var yip := bool(S.get("yips", false)) and fmod(_st, 2.6) > 2.0 # (a coyote's yips between)
		var breath := fmod(_st, 2.6) < 0.25 # (a breath between)
		_neck_to = Vector2(1.1, 0.0) if not breath else Vector2(0.7, 0.0)
		_look_to = Vector2(0.55, 0.0)
		_jaw_to = (0.25 + 0.2 * maxf(sin(_st * 22.0), 0.0)) if yip else (0.0 if breath else 0.32)
		if _wait <= 0.0:
			_sit_to = 0.0
			wander(_home_spot(), _radius)
		return
	super(dt)


func _mating(dt: float) -> void:
	super(dt)
	if _mate_stage in ["court", "seek", "wait"]:
		_tail_mode = "wag"


func _p_behaviours() -> PackedStringArray:
	var b := super()
	if bool(S.get("howl", false)):
		b.append("howl")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	if name == "howl":
		howl(float(args.get("seconds", 6.0)))
		return bool(S.get("howl", false))
	return super(name, args)


func _p_act_done(name: String) -> bool:
	if name == "howl":
		return _mode != "howl"
	return super(name)
