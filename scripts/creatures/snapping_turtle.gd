class_name SnappingTurtle
extends "res://scripts/creatures/turtle.gd" # (by path: found whether or not the editor has seen the class yet)
## A common snapping turtle (Chelydra serpentina), drawn at twice life size
## (modelled at life size, its shell about 30 cm long), on the box turtle's
## make and ways (Turtle) but its own: its shell low and broad, rough, three
## keels of knobs down it, its rear rim toothed like a saw; dark olive brown,
## its growth rings plain, algae on it in patches; its plastron small, a
## cross, pale: too small to hide in. Its head huge, broad, its upper beak
## hooked; two barbels under its chin; its eyes small, high and forward;
## its neck long (it reaches half its shell's length); its skin grey olive,
## knobbed with tubercles, paler beneath; its legs thick, big clawed, the
## feet webbed; its tail as long as its shell, a saw of plates down its top.
## A hatchling (SnappingTurtle.new(true)): a coin of a turtle, black, rough.
##
## Its own ways (the box turtle's otherwise):
## - wander(): in the water walking slowly along the bottom, up to the
##   surface now and then to breathe (only its nostrils out, its neck
##   stretched), down again; on land, back to the water
## - bask(): (ambush) still on the bottom, half buried, its mouth a little
##   open, waiting
## - dive(): down to the bottom, still a while
## - withdraw(): (its alarm) on land it can't hide: up on its legs, its
##   mouth open, hissing, lunging and snapping, again and again; in the
##   water down to the bottom, still
## - eat(food): (fish, weed, carrion) up close, still, then its neck shot out
##   and its jaws snapped shut, in a flash; gulped
## - mate(her): (a male's) in the water, onto her back from above, his claws
##   hooked over the rim of her shell, both sinking to the bottom; he bites
##   at her head now and then; off

const SNAP := {
	"aquatic": true,
	"shell": {"len": 300.0, "wid": 250.0, "ht": 100.0, "rim": 28.0, "dome": [1.7, 0.85], "flare": [4.0, 2.0],
			"notch": 7.0, "teeth": 14.0, "keels": [[0.0, 9.0], [0.5, 7.0]], "knobs": 8.0, "lip": 9.0},
	"plastron": {"hinge": false, "cross": true, "wid": 0.26, "th": 9.0, "hinge_z": 0.0},
	"col": {"shell": Color(0.22, 0.19, 0.12), "ray": Color(0.3, 0.26, 0.16), "seam": Color(0.1, 0.085, 0.06),
			"plast": Color(0.66, 0.6, 0.42), "smudge": Color(0.42, 0.36, 0.24),
			"skin": Color(0.21, 0.2, 0.15), "spot": Color(0.3, 0.28, 0.21), "spots": 0.06, "under": Color(0.62, 0.57, 0.44),
			"eye_m": Color(0.56, 0.45, 0.2), "eye_f": Color(0.56, 0.45, 0.2), "algae": 0.22, "rays": 0.0, "bumps": 0.55},
	"head": [[-96.0, 2.5, 6.0, -17.0], [-92.0, 8.0, 15.0, -15.0], [-82.0, 17.0, 25.0, -17.0], [-64.0, 26.0, 35.0, -22.0], [-40.0, 33.0, 41.0, -27.0], [-14.0, 34.0, 40.0, -28.0], [0.0, 30.0, 33.0, -25.0]],
	"jaw": [[-89.0, 4.0, -13.0, -19.0], [-80.0, 13.0, -14.0, -26.0], [-58.0, 25.0, -16.0, -32.0], [-28.0, 31.0, -16.0, -31.0], [-8.0, 30.0, -16.0, -26.0]],
	"jaw_at": Vector3(0.0, -10.0, -12.0),
	"eye": [Vector3(22.0, 20.0, -66.0), 6.0],
	"neck": {"root": Vector3(0.0, 52.0, -110.0), "in": Vector3(0.0, 46.0, -150.0), "out": Vector3(0.0, 52.0, -200.0), "reach": 95.0, "r": 34.0},
	"fore": Vector3(98.0, 38.0, -92.0), "hind": Vector3(92.0, 32.0, 104.0),
	"leg_r": 19.0, "reach": 11.0, "foot": 22.0, "claws": 5, "claw": 13.0, "claw_m_hind": 13.0, "claw_m_fore": 13.0, "draw_in": 0.35,
	"stand": 26.0,
	"tail": {"at": Vector3(0.0, 34.0, 145.0), "len": 250.0, "len_m": 280.0, "r": 19.0, "crest": 13},
	"young_size": 0.12, "walk": 0.025, "swim": 0.05,
}

var _breathe := 0.0 # (s till it goes up to breathe)


func _spec() -> Dictionary:
	return SNAP


func _build_head_extra() -> void:
	for side: float in [-1.0, 1.0]: # (the barbels under its chin)
		var b := _limb(_skin, _jaw_n, 0.7)
		var a := Vector3(9.0 * side, -30.0, -60.0) - (S.jaw_at as Vector3)
		_seg_to(b, a, a + Vector3(1.5 * side, -9.0, 2.0), 2.6)


func _go_mode(m: String) -> void:
	super(m)
	if m == "wander" or m == "dive" or m == "bask":
		_depth_to = maxf(water_y - floor_y, 0.0) # (down on the bottom)


## In the water along the bottom, up to breathe now and then; on land, back
## to the water.
func _wander_think(dt: float) -> void:
	if not _in_water(_pos):
		_depth_to = 0.0
		if _wait <= 0.0:
			_target = pond[0]
			_speed = float(S.walk)
			_wait = 6.0
		return
	_breathe -= dt
	if _breathe <= 0.0: # (up: only its nostrils out, its neck stretched up)
		_depth_to = 0.04 * size
		_neck_to = 1.4
		_speed = 0.0
		if _breathe < -6.0:
			_breathe = rng.randf_range(20.0, 40.0)
		return
	_depth_to = maxf(water_y - floor_y, 0.0)
	_neck_to = 0.9
	if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.04:
		var c: Vector3 = pond[0]
		var e: Vector2 = pond[1]
		var a := rng.randf() * TAU
		_target = c + Vector3(cos(a) * e.x, 0.0, sin(a) * e.y) * 0.7 * rng.randf()
		_speed = float(S.walk)
		_wait = rng.randf_range(6.0, 12.0)
		if rng.randf() < 0.4:
			_target = _pos


func _think(dt: float) -> void:
	match _mode:
		"bask": # (ambush: still on the bottom, half sunk in the mud, its mouth a little open)
			_speed = 0.0
			_depth_to = maxf(water_y - floor_y, 0.0)
			_neck_to = 0.75
			_limbs_to = 0.7
			_jaw_to = 0.18 if fmod(_st, 9.0) < 4.0 else 0.0
			if _st > 30.0:
				wander(pond[0], 0.4)
			return
		"dive":
			_speed = 0.0
			_depth_to = maxf(water_y - floor_y, 0.0)
			_neck_to = 0.6
			if _st > 14.0:
				wander(pond[0], 0.4)
			return
	super(dt)


## Its alarm. On land: up on its legs, facing it, its mouth open, hissing,
## lunging and snapping; in the water: down, still.
func _hide_think(_dt: float) -> void:
	_speed = 0.0
	if _in_water(_pos):
		_depth_to = maxf(water_y - floor_y, 0.0)
		_neck_to = 0.3
		_limbs_to = 0.6
	else:
		_rear = 1.0
		var ph := fmod(_st, 2.6)
		if ph < 0.18: # (the lunge: its neck shot out, its jaws snapped shut)
			_neck_rate = 14.0
			_neck_to = 1.6
			_jaw_to = 0.0 if ph > 0.12 else 0.9
		else:
			_neck_rate = 3.0
			_neck_to = 0.85
			_jaw_to = 0.7 # (gaping, hissing)
	if _st > 12.0:
		_rear = 0.0
		wander(pond[0], 0.4)


## Up close; still; its neck shot out and its jaws snapped shut, in a flash.
func _eat_think(_dt: float) -> void:
	if not is_instance_valid(_food):
		wander(pond[0], 0.4)
		return
	var fp := _food.global_position if _food.is_inside_tree() else _food.position
	var d := Vector3(fp.x - _pos.x, 0.0, fp.z - _pos.z)
	var reach := (absf(float((S.neck.out as Vector3).z)) + 90.0) * MM * size
	match _stage:
		0:
			_go_to(fp - d.normalized() * reach * 0.8, float(S.walk))
			_neck_to = 0.8
			if d.length() < reach * 1.05:
				_stage = 1
				_st = 0.0
		1: # (still, its head drawn back a little, aiming)
			_speed = 0.0
			_face(d)
			_neck_to = 0.75
			if _st > 1.5:
				_stage = 2
				_st = 0.0
		2: # (the strike)
			_neck_rate = 16.0
			_neck_to = 1.6
			_jaw_to = 0.9 if _st < 0.08 else 0.0
			if _st > 0.12 and is_instance_valid(_food):
				_food.queue_free()
				_food = null
			if _st > 0.5:
				_neck_rate = 2.0
				wander(pond[0], 0.4)


## In the water, onto her from above, his claws over her shell's rim; both
## sinking; biting at her head; off.
func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	if not _in_water(her._pos):
		her._go_to(pond[0], float(S.walk))
	var hb := Basis(Vector3.UP, her._yaw)
	match _stage:
		0: # (to her)
			_depth_to = her._depth
			var over := her._pos + hb * Vector3(0.0, 0.0, float(S.shell.len) * 0.2 * MM * size)
			_go_to(over, float(S.swim))
			if Vector2(_pos.x - over.x, _pos.z - over.z).length() < 0.05:
				_stage = 1
				_st = 0.0
		1, 2: # (on her back, gripping her shell; both down to the bottom)
			_stage = 2
			her._depth_to = maxf(water_y - floor_y, 0.0)
			var on := her._pos + hb * Vector3(0.0, 0.0, float(S.shell.len) * 0.12 * MM * size)
			on.y = her._pos.y + float(S.shell.ht) * 0.85 * MM * her.size
			_pos = _pos.lerp(on, 0.1)
			_yaw = lerp_angle(_yaw, her._yaw, 0.1)
			_pitch = lerpf(_pitch, -0.08, 0.1)
			_speed = 0.0
			var bite := fmod(_st, 4.0)
			_neck_to = 1.3 if bite < 0.8 else 1.0 # (biting at her head)
			_jaw_to = 0.6 if bite < 0.4 else 0.0
			if _st > _mate_len:
				_pitch = 0.0
				_end_mate()


func _end_mate() -> void:
	super()
	wander(pond[0], 0.4)


func _pose_leg_extra(L: Array, out: Vector3, foot: Vector3) -> Array:
	if _role == "male" and _stage == 2: # (his claws hooked over her shell's rim)
		var side: float = L[5]
		var fore: bool = L[4]
		var k := float(S.shell.len) / 140.0
		var hip: Vector3 = (L[0] as Node3D).position
		out = hip + Vector3(16.0 * k * side, -6.0 * k, (-6.0 if fore else 6.0) * k)
		foot = out + Vector3(6.0 * k * side, -16.0 * k, (-4.0 if fore else 4.0) * k)
	return [out, foot]
