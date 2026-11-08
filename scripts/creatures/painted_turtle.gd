class_name PaintedTurtle
extends "res://scripts/creatures/turtle.gd" # (by path: found whether or not the editor has seen the class yet)
## A western painted turtle (Chrysemys picta bellii), drawn at twice life
## size (modelled at life size: a female's shell about 16 cm long, a male's
## smaller), on the box turtle's make and ways (Turtle) but its own: its
## shell low, smooth, oval, no keel, no hinge; olive black, each seam
## edged pale yellow-olive, a fine net of pale lines over its scutes; its
## marginals barred and edged red, red beneath; its plastron orange red, a
## dark figure down its middle, fingered out along its seams. Its skin
## black, striped yellow down its head, neck, legs and tail, some of the
## stripes red (more on its legs); a yellow spot behind each eye; its head
## smooth, pointed, its jaw notched; its feet broad and webbed; a male's
## foreclaws long (to court with), his tail longer and thicker. A
## hatchling (PaintedTurtle.new(true)): a coin of a turtle, brighter.
##
## Its own ways (the box turtle's otherwise):
## - wander(): swimming in the pond, near the surface or down, foraging
##   along the bottom, up to breathe; on land, back to the water
## - bask(at): out onto a log (or a bank) in the sun: up it, its legs
##   stretched out behind, its neck up, a long while; then back into the
##   water. (They pile up on a log: Turtle._touch_ok.) at.y the log's top
## - dive(): down to the bottom, still a while
## - withdraw(): its alarm: off its log with a plop into the water and
##   down to the bottom, its head drawn in; in the water, down
## - eat(food): (weed, insects, snails, carrion) to it, bites torn off
## - mate(her): (a male's) his courtship in the water: in front of her,
##   facing her, his long foreclaws reached out to her face and fluttered
##   against it, again and again; then onto her back from above, his claws
##   hooked over her shell's rim, both sinking; off
## - nest(): (a female's) out to the bank, a hole dug with her hind feet,
##   her eggs laid, covered; back to the water
## - sleep(): on the bottom, under the water

const PAINT := {
	"aquatic": true,
	"shell": {"len": 160.0, "wid": 112.0, "ht": 48.0, "rim": 10.0, "dome": [1.8, 0.85], "flare": [2.0, 1.0],
			"notch": 2.5, "teeth": 0.0, "keels": [[0.0, 0.0]], "knobs": 0.0, "lip": 3.0},
	"plastron": {"hinge": true, "rigid": true, "cross": false, "wid": 0.45, "th": 5.0, "hinge_z": -14.0},
	"col": {"shell": Color(0.15, 0.15, 0.09), "ray": Color(0.6, 0.55, 0.25), "seam": Color(0.05, 0.05, 0.035),
			"plast": Color(0.82, 0.32, 0.1), "smudge": Color(0.12, 0.08, 0.05),
			"skin": Color(0.05, 0.05, 0.035), "spot": Color(0.9, 0.78, 0.2), "spots": 0.0, "under": Color(0.75, 0.62, 0.22),
			"eye_m": Color(0.5, 0.42, 0.14), "eye_f": Color(0.5, 0.42, 0.14), "algae": 0.06, "rays": 0.0, "blots": 0.0, "bumps": 0.12,
			"edge_c": Color(0.52, 0.48, 0.22), "edge_w": 0.035, "net_c": Color(0.55, 0.5, 0.25), "net": 0.55,
			"marg_c": Color(0.78, 0.22, 0.09), "marg": 0.85, "fig": 1.0,
			"stripes": 9.0, "stripe_c": Color(0.92, 0.8, 0.22), "stripe_red": Color(0.8, 0.2, 0.08), "red_share": 0.22},
	# its head: smooth, pointed, the snout short
	"head": [[-31.0, 1.6, 2.4, -3.8], [-29.0, 4.2, 5.2, -4.0], [-24.0, 7.2, 7.6, -4.6], [-16.0, 9.6, 9.0, -5.6], [-7.0, 10.2, 9.2, -6.2], [0.0, 9.0, 8.0, -6.0]],
	"jaw": [[-28.0, 2.4, -4.0, -6.2], [-23.0, 6.2, -4.2, -7.6], [-14.0, 8.8, -4.8, -8.2], [-5.0, 9.0, -5.0, -7.2]],
	"jaw_at": Vector3(0.0, -1.0, -4.0),
	"eye": [Vector3(7.4, 4.0, -19.0), 3.1],
	"neck": {"root": Vector3(0.0, 17.0, -48.0), "in": Vector3(0.0, 14.0, -38.0), "out": Vector3(0.0, 19.0, -76.0), "reach": 28.0, "r": 8.0},
	"fore": Vector3(38.0, 13.0, -44.0), "hind": Vector3(36.0, 11.0, 46.0),
	"leg_r": 7.5, "reach": 11.0, "foot": 12.0, "claws": 5, "claw": 4.5, "claw_m_hind": 4.5, "claw_m_fore": 16.0, "draw_in": 0.9,
	"foot_flat": 0.3,
	"stand": 5.0,
	"tail": {"at": Vector3(0.0, 10.0, 70.0), "len": 18.0, "len_m": 32.0, "r": 5.0, "crest": 0},
	"young_size": 0.16, "walk": 0.025, "swim": 0.07,
}

var _breathe := 0.0 # (s till it goes up to breathe)
var _log := Vector3.INF # (where it's basking: on its log, its top)


func _spec() -> Dictionary:
	return PAINT


func _ready() -> void:
	super()
	if male and not young:
		size *= 0.75 # (the males smaller)


## Its yellow spots, one behind each eye, and the bright stripe under its
## chin.
func _build_head_extra() -> void:
	# its head's stripes yellow (the red ones on its legs and neck)
	var hs := _skin.duplicate() as ShaderMaterial
	hs.set_shader_parameter("red_share", 0.04)
	_skins.append(hs)
	for n: Node3D in [_head, _jaw_n]:
		for ch in n.get_children():
			if ch is MeshInstance3D and (ch as MeshInstance3D).material_override == _skin:
				(ch as MeshInstance3D).material_override = hs
	var yel := _mat((S.col.stripe_c as Color) * (1.2 if young else 1.0), 0.5)
	var E: Array = S.eye
	var at: Vector3 = E[0]
	for side: float in [-1.0, 1.0]:
		_part(Vector3((at.x + 1.6) * side, at.y - 0.6, at.z + 7.5), Vector3(2.6, 4.6, 6.4), yel, _head)


# --- its ways -------------------------------------------------------------------

func _go_mode(m: String) -> void:
	super(m)
	if m == "dive" or m == "sleep":
		_depth_to = maxf(water_y - floor_y, 0.0) # (down on the bottom)


## On its log (basking): the log's top, coming up onto it; elsewhere as
## the box turtle's (in the water, the surface less how deep it's gone).
func _ground_at(x: float, z: float) -> float:
	var g := super(x, z)
	if _mode == "bask" and _stage < 2 and _log != Vector3.INF:
		var d := Vector2(x - _log.x, z - _log.z).length()
		var on := 1.0 - smoothstep(0.03, 0.14 * size + 0.05, d)
		return lerpf(g, maxf(g, _log.y), on)
	return g


func bask(at := Vector3.INF) -> void:
	super(at)
	_log = _target


## Swimming in the pond: near the surface or down along the bottom,
## foraging; up to breathe; on land, back to the water.
func _wander_think(dt: float) -> void:
	if not _in_water(_pos):
		_depth_to = 0.0
		if _wait <= 0.0:
			_target = pond[0]
			_speed = float(S.walk)
			_wait = 6.0
		return
	_breathe -= dt
	if _breathe <= 0.0: # (up: its head out, breathing)
		_depth_to = 0.0
		_neck_to = 1.2
		if _breathe < -4.0:
			_breathe = rng.randf_range(15.0, 35.0)
			_depth_to = rng.randf_range(0.0, maxf(water_y - floor_y, 0.0))
	if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.04:
		var c: Vector3 = pond[0]
		var e: Vector2 = pond[1]
		var a := rng.randf() * TAU
		_target = c + Vector3(cos(a) * e.x, 0.0, sin(a) * e.y) * 0.75 * rng.randf()
		_speed = float(S.walk)
		_wait = rng.randf_range(5.0, 10.0)
		_neck_to = 1.0
		if rng.randf() < 0.3: # (down to the bottom, foraging along it)
			_depth_to = maxf(water_y - floor_y, 0.0)
		elif rng.randf() < 0.5:
			_depth_to = 0.0


func _think(dt: float) -> void:
	match _mode:
		"bask":
			_depth_to = 0.0
			match _stage:
				0: # (to the log, up onto it)
					_go_to(_target, float(S.walk) * 1.4)
					if Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.04:
						_stage = 1
						_st = 0.0
				1: # (in the sun: its legs stretched out behind, its neck up; a long while)
					_speed = 0.0
					_neck_to = 1.35
					if _st > 40.0:
						_stage = 2
						_st = 0.0
				2: # (back down into the water)
					_go_to(pond[0], float(S.walk) * 1.4)
					if _in_water(_pos) and _st > 1.0:
						wander(pond[0], 0.4)
			for l in _shut:
				l.visible = false
			return
		"dive":
			_speed = 0.0
			_neck_to = 0.6
			if _st > 15.0:
				wander(pond[0], 0.4)
			return
		"sleep": # (on the bottom, under the water)
			if _in_water(_pos):
				_depth_to = maxf(water_y - floor_y, 0.0)
	super(dt)


## Its alarm: off its log, a plop into the water, down to the bottom, its
## head drawn in; out again a while after.
func _hide_think(_dt: float) -> void:
	if not _in_water(_pos):
		var c: Vector3 = pond[0]
		_go_to(c + (Vector3(_pos.x - c.x, 0.0, _pos.z - c.z)).normalized() * 0.05, float(S.walk) * 3.0)
		_neck_to = 0.6
		_st = 0.0
		return
	_speed = 0.0
	_depth_to = maxf(water_y - floor_y, 0.0)
	_neck_to = 0.2 if _st < 8.0 else 0.6
	_limbs_to = 0.6 if _st < 8.0 else 1.0
	if _st > 12.0:
		wander(pond[0], 0.4)


## His courtship, in the water: in front of her, facing her, his long
## foreclaws reached out to her face and fluttered against it, again and
## again (she still); then onto her back from above, his claws over her
## shell's rim, both sinking to the bottom; off.
func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	if not _in_water(her._pos):
		her._go_to(pond[0], float(S.walk))
	var hb := Basis(Vector3.UP, her._yaw)
	var L := float(S.shell.len) * _mm
	match _stage:
		0: # (round to in front of her, turning to face her)
			_depth_to = her._depth
			var front := her._pos + hb * Vector3(0.0, 0.0, -(L * her.size * 0.5 + L * size * 0.55 + 0.02))
			_go_to(front, float(S.walk) * 1.5)
			if Vector2(_pos.x - front.x, _pos.z - front.z).length() < 0.04:
				_stage = 1
				_st = 0.0
		1: # (facing her, backing away a little as she comes, his claws fluttered at her face)
			_speed = 0.0
			_face(her._pos - _pos)
			_depth_to = her._depth
			_neck_to = 1.0
			var front := her._pos + hb * Vector3(0.0, 0.0, -(L * her.size * 0.5 + L * size * 0.55))
			_pos.x = lerpf(_pos.x, front.x, 0.05)
			_pos.z = lerpf(_pos.z, front.z, 0.05)
			if _st > _mate_len * 0.55:
				_stage = 2
				_st = 0.0
		2: # (on her back from above, gripping her shell; both down to the bottom)
			her._depth_to = maxf(water_y - floor_y, 0.0)
			var on := her._pos + hb * Vector3(0.0, 0.0, L * her.size * 0.1)
			on.y = her._pos.y + float(S.shell.ht) * 0.9 * _mm * her.size
			_pos = _pos.lerp(on, 0.1)
			_yaw = lerp_angle(_yaw, her._yaw, 0.1)
			_speed = 0.0
			_neck_to = 1.1
			if _st > _mate_len * 0.45:
				_end_mate()


func _end_mate() -> void:
	super()
	wander(pond[0], 0.4)


func _pose_leg_extra(L: Array, out: Vector3, foot: Vector3) -> Array:
	if _role != "male" or young:
		return [out, foot]
	var side: float = L[5]
	var fore: bool = L[4]
	var k := float(S.shell.len) / 140.0
	var hip: Vector3 = (L[0] as Node3D).position
	if _stage == 1 and fore: # (reached out ahead to her face, palms out, the claws fluttering)
		var flutter := sin(_t * 26.0 + (0.0 if side > 0.0 else 1.7)) * 2.5 * k
		out = hip + Vector3(4.0 * k * side, 4.0 * k, -16.0 * k)
		foot = out + Vector3(-5.0 * k * side, 6.0 * k + flutter, -12.0 * k)
	elif _stage == 2: # (his claws hooked over her shell's rim)
		out = hip + Vector3(16.0 * k * side, -6.0 * k, (-6.0 if fore else 6.0) * k)
		foot = out + Vector3(6.0 * k * side, -16.0 * k, (-4.0 if fore else 4.0) * k)
	return [out, foot]


