class_name SeaTurtle
extends "res://scripts/creatures/turtle.gd" # (by path: found whether or not the editor has seen the class yet)
## A green sea turtle (Chelonia mydas), drawn life size (its shell about a
## metre long), on the box turtle's make (Turtle) but its own: its shell low,
## smooth and streamlined, a teardrop, broad at the shoulders, tapering
## behind; its scutes laid edge to edge, olive brown, each streaked out from
## its growth centre in rays of yellow brown and dark; its plastron pale
## cream. Its head blunt and rounded, too big to draw in; its skin a mosaic
## of big dark scales, each outlined cream; its forelimbs long flat
## flippers, a claw on each leading edge (a male's long and curved, to hold
## her shell), its hind flippers short and round, rudders; a male's tail
## long, reaching past his shell, a female's short. A hatchling
## (SeaTurtle.new(true)): five centimetres, near black, pale edged.
##
## Its own ways (the box turtle's otherwise):
## - wander(): in the water, flying through it with its foreflippers (slow
##   beats, up and down, the hind ones steering), at one depth then another;
##   up to the surface now and then to breathe, its head out; on land (a
##   hatchling out of its nest) away down to the water
## - bask(): resting on the bottom, still, its flippers laid along its sides
## - dive(): down to the bottom, grazing the seagrass there
## - withdraw(): (its alarm: it can't hide in its shell) away fast, down
## - eat(food) (Turtle.weed_of(): seagrass, algae; a jellyfish): to it,
##   biting, tearing at it
## - mate(her): (a male's) at the surface, onto her back from behind, his
##   foreflippers' claws hooked over the front of her shell, his tail under
##   hers; floating together a long while; off
## - nest(): (a female's) up the beach out of the sea, both foreflippers
##   heaving together (a green turtle's crawl), the body pit swept with them,
##   the egg chamber dug with her hind flippers, her eggs laid (Nest), the
##   sand pushed back and thrown over it; back down to the sea

const SEA := {
	"aquatic": true, "mm": 0.001, "flipper": true,
	"shell": {"len": 1000.0, "wid": 820.0, "ht": 235.0, "rim": 62.0, "dome": [1.9, 0.62], "flare": [-80.0, 0.0],
			"notch": 12.0, "teeth": 0.0, "keels": [], "knobs": 0.0, "lip": 18.0},
	"plastron": {"hinge": false, "cross": false, "wid": 0.34, "th": 12.0, "hinge_z": 0.0},
	"col": {"shell": Color(0.34, 0.24, 0.12), "ray": Color(0.58, 0.48, 0.26), "seam": Color(0.78, 0.7, 0.52),
			"plast": Color(0.86, 0.8, 0.6), "smudge": Color(0.8, 0.72, 0.5),
			"skin": Color(0.17, 0.12, 0.07), "spot": Color(0.17, 0.12, 0.07), "spots": 0.0, "under": Color(0.82, 0.74, 0.5),
			"eye_m": Color(0.06, 0.05, 0.04), "eye_f": Color(0.06, 0.05, 0.04), "algae": 0.05, "rays": 0.7, "bumps": 0.15,
			"mosaic": 1.0, "edge": Color(0.8, 0.7, 0.4), "blots": 0.0, "seam_w": 0.012},
	"head": [[-192.0, 9.6, 24.0, -57.6], [-180.0, 38.4, 52.8, -60.0], [-153.6, 62.4, 72.0, -62.4], [-114.0, 79.2, 84.0, -66.0], [-66.0, 84.0, 84.0, -67.2], [-18.0, 76.8, 74.4, -64.8], [0.0, 69.6, 67.2, -60.0]],
	"jaw": [[-180.0, 16.8, -48.0, -69.6], [-156.0, 43.2, -50.4, -79.2], [-114.0, 62.4, -52.8, -84.0], [-60.0, 69.6, -55.2, -79.2], [-18.0, 64.8, -55.2, -72.0]],
	"jaw_at": Vector3(0.0, -43.0, -24.0),
	"eye": [Vector3(60.0, 31.0, -120.0), 19.0],
	"neck": {"root": Vector3(0.0, 92.0, -330.0), "in": Vector3(0.0, 100.0, -440.0), "out": Vector3(0.0, 108.0, -500.0), "reach": 40.0, "r": 64.0}, # (out from under the front of its shell)
	"fore": Vector3(290.0, 140.0, -270.0), "hind": Vector3(250.0, 110.0, 330.0),
	"leg_r": 50.0, "reach": 15.0, "foot": 40.0, "claws": 0, "claw": 22.0, "claw_m_fore": 50.0, "claw_m_hind": 18.0, "claw_mm": 3.0, "draw_in": 0.1, "lower_flat": 0.35,
	"flipper_fore": 400.0, "flipper_w_fore": 190.0, "flipper_hind": 180.0, "flipper_w_hind": 150.0, "foot_flat": 0.12,
	"stand": 12.0,
	"tail": {"at": Vector3(0.0, 100.0, 430.0), "len": 90.0, "len_m": 380.0, "r": 30.0, "crest": 0},
	"young_size": 0.05, "walk": 0.06, "swim": 0.35,
}

var _breathe := 20.0 # (s till it goes up to breathe)
var _flippers: Array[Node3D] = [] # (each leg's blade, its own mesh: posed at its elbow)
var _flip_at := {} # leg index -> [elbow, wrist] (its shell's mm), as posed
var _neck_skin: ShaderMaterial

const FORE_LEN := 560.0 ## mm, a foreflipper from its elbow to its tip
const FORE_CHORD := 175.0
const HIND_LEN := 220.0
const HIND_CHORD := 150.0


func _spec() -> Dictionary:
	return SEA


## Its flippers, each a blade of its own (FORE: a long wing, swept back,
## tapering to a point, thick along its leading edge; HIND: a broad round
## paddle), in place of the legs' forearm and foot; a claw on each
## foreflipper's leading edge. Its neck its own skin: yellow olive, finely
## scaled, wrinkled.
func _build_head_extra() -> void:
	for i in _legs.size():
		var L: Array = _legs[i]
		var fore: bool = L[4]
		var side: float = L[5]
		(L[2] as Node3D).visible = false
		(L[3] as Node3D).visible = false
		var n := Node3D.new()
		_shell_n.add_child(n)
		var mi := MeshInstance3D.new()
		mi.mesh = _flipper_mesh(fore, side)
		mi.material_override = _skin
		n.add_child(mi)
		if fore:
			var claw := _limb(_mat(Color(0.3, 0.26, 0.2), 0.5), n, 0.85)
			var at := Vector3(FORE_LEN * 0.36, 2.0, -FORE_CHORD * 0.2 * side)
			_seg_to(claw, at, at + Vector3(10.0, 0.0, -(16.0 if not male else 34.0) * side), 4.0 if not male else 6.0)
		_flippers.append(n)
	_neck_skin = _skin.duplicate() as ShaderMaterial
	_neck_skin.set_shader_parameter("base", Color(0.5, 0.42, 0.22))
	_neck_skin.set_shader_parameter("edge", Color(0.72, 0.64, 0.4))
	_neck_skin.set_shader_parameter("cell", 1.3)
	_neck_skin.set_shader_parameter("seam_w", 0.12)
	_neck_skin.set_shader_parameter("bumps", 0.6)
	_neck_mi.material_override = _neck_skin
	_skins.append(_neck_skin)
	_skin.set_shader_parameter("cell", 3.0)
	_skin.set_shader_parameter("seam_w", 0.035)


## A flipper's blade (mm; along +x from its elbow, its chord back along +z
## (on the left, side -1, mirrored), flat across y): its planform, its
## thickness, a section rounded at its leading edge, thinning to its
## trailing edge; the fore one swept back to a point.
static func _flipper_mesh(fore: bool, side: float) -> ArrayMesh:
	const N := 18
	const M := 9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := FORE_LEN if fore else HIND_LEN
	var chord := FORE_CHORD if fore else HIND_CHORD
	var rows: Array = []
	for i in N + 1:
		var t := float(i) / N
		var c: float
		var sweep: float
		var th: float
		if fore: # (a wing: broad at its wrist, swept back, tapering to a point)
			c = chord * (0.62 + 0.55 * sin(PI * minf(t / 0.45, 1.0) * 0.5)) * (1.0 - smoothstep(0.3, 1.0, t) * 0.94)
			sweep = length * 0.32 * t * t
			th = lerpf(42.0, 7.0, pow(t, 0.7))
		else: # (a paddle: broad, round ended)
			c = chord * sqrt(maxf(1.0 - pow((t - 0.45) / 0.58, 2.0), 0.02))
			sweep = length * 0.25 * t * t
			th = lerpf(30.0, 8.0, t)
		var row: Array = []
		for j in M + 1:
			var u := float(j) / M # (0 its leading edge .. 1 its trailing)
			var thick := th * 0.5 * sqrt(maxf(u, 0.0)) * (1.0 - u) * 2.3 + 0.6 # (round in front, thin behind)
			row.append([Vector3(t * length, thick, (sweep + (u - 0.12) * c) * side), Vector3(t * length, -thick * 0.7, (sweep + (u - 0.12) * c) * side)])
		rows.append(row)
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool) -> void:
		if flip:
			st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
			st.add_vertex(a); st.add_vertex(d); st.add_vertex(c)
		else:
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
			st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)
	var mir := side < 0.0
	for i in N:
		for j in M:
			for k in 2: # (its top, its underside)
				var a: Vector3 = rows[i][j][k]
				var b: Vector3 = rows[i + 1][j][k]
				var c: Vector3 = rows[i + 1][j + 1][k]
				var d: Vector3 = rows[i][j + 1][k]
				quad.call(a, b, c, d, (k == 1) != mir)
	for i in N: # (its edges, closed)
		for j: int in [0, M]:
			quad.call(rows[i][j][0], rows[i + 1][j][0], rows[i + 1][j][1], rows[i][j][1], (j == 0) == mir)
	st.generate_normals()
	return st.commit()


## (m: deep as it goes, its shell's back on the bottom)
func _deepest() -> float:
	return maxf(water_y - floor_y - float(S.shell.ht) * _mm * size, 0.0)


## Where its plastron is at x, z: in the water, under the surface (its back
## just awash at it) by how deep it's gone, no lower than the bottom.
func _ground_at(x: float, z: float) -> float:
	if _in_water(Vector3(x, 0.0, z)):
		return maxf(water_y - float(S.shell.ht) * 0.85 * _mm * size - _depth, floor_y)
	return float(height.call(x, z)) if height.is_valid() else 0.0


func _move(dt: float) -> void:
	_depth = move_toward(_depth, _depth_to, dt * 0.25 * maxf(size, 0.3)) # (it swims up and down; not sinks)
	var keep := _speed
	if not _in_water(_pos) and _speed > 0.0: # (on land: heaved on in lunges, a beat of its foreflippers each)
		_speed *= 0.2 + 1.4 * maxf(sin(_t * 1.4), 0.0)
	var d := _depth
	super(dt)
	_depth = d
	_speed = keep


## In the water: flying through it, now at one depth, now another; up to
## breathe now and then; on land, down to the water.
func _wander_think(dt: float) -> void:
	if not _in_water(_pos):
		_depth_to = 0.0
		_go_to(pond[0], float(S.walk))
		return
	_breathe -= dt
	if _breathe <= 0.0: # (up: its head out, a breath, two)
		_depth_to = 0.0
		_neck_to = 1.25
		if _depth < 0.03 and _breathe < -6.0:
			_breathe = rng.randf_range(40.0, 90.0)
		return
	_neck_to = 1.0
	if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.2:
		var c: Vector3 = pond[0]
		var e: Vector2 = pond[1]
		var a := rng.randf() * TAU
		_target = c + Vector3(cos(a) * e.x, 0.0, sin(a) * e.y) * rng.randf_range(0.2, 0.75)
		_speed = float(S.walk)
		_depth_to = _deepest() * rng.randf_range(0.25, 1.0)
		_wait = rng.randf_range(8.0, 15.0)


func _think(dt: float) -> void:
	match _mode:
		"sleep": # (asleep on the bottom, wedged still, its eyes shut; it can't draw its head in)
			_depth_to = _deepest()
			super(dt)
			_neck_to = 0.6
		"bask": # (resting on the bottom, still, its flippers along its sides)
			_speed = 0.0
			_depth_to = _deepest()
			_neck_to = 0.6
			if _st > 30.0:
				wander(pond[0], 0.5)
		"dive": # (down to the bottom, grazing the seagrass there, its head down)
			_depth_to = _deepest()
			_speed = float(S.walk) * 0.25 if fmod(_st, 6.0) < 1.5 else 0.0
			_neck_to = 1.1
			_look = -0.6
			_jaw_to = 0.35 * maxf(sin(_st * 4.0), 0.0)
			if _st > 25.0:
				_look = 0.0
				wander(pond[0], 0.5)
		_:
			super(dt)
	# (swimming: its nose up as it rises, down as it dives)
	if _in_water(_pos) and not (_role == "male" and _stage >= 1):
		_pitch = lerpf(_pitch, clampf((_depth - _depth_to) * 2.5, -0.4, 0.4), 0.03)


## Its alarm (it can't hide in its shell): away fast, and down.
func _hide_think(_dt: float) -> void:
	if _stage == 0:
		var c: Vector3 = pond[0]
		var e: Vector2 = pond[1]
		var away := _p_heading()
		_target = _pos + away * 3.0
		_target.x = clampf(_target.x, c.x - e.x * 0.85, c.x + e.x * 0.85)
		_target.z = clampf(_target.z, c.z - e.y * 0.85, c.z + e.y * 0.85)
		_stage = 1
	_speed = float(S.walk) * 2.2
	_depth_to = _deepest()
	_limbs_to = 1.0
	_neck_to = 0.8
	if _st > 6.0:
		wander(pond[0], 0.5)


func _eat_think(dt: float) -> void:
	super(dt)
	if is_instance_valid(_food) and _in_water(_pos): # (down, or up, to it)
		var fp := _food.global_position if _food.is_inside_tree() else _food.position
		_depth_to = clampf(water_y - fp.y - float(S.shell.ht) * 0.5 * _mm * size, 0.0, _deepest())


## At the surface, onto her back from behind, his claws hooked over the
## front of her shell; floating together; off.
func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	var hb := Basis(Vector3.UP, her._yaw)
	var L := float(S.shell.len) * _mm * size
	her._depth_to = 0.0
	her._speed = 0.0
	match _stage:
		0: # (after her, to just behind her)
			_depth_to = 0.0
			var behind := her._pos + hb * Vector3(0.0, 0.0, L * 0.9)
			_go_to(behind, float(S.walk) * 1.5)
			if Vector2(_pos.x - behind.x, _pos.z - behind.z).length() < 0.25:
				_stage = 2 # (mounted: Turtle._move leaves his height to this)
				_st = 0.0
		1, 2: # (on her back, gripping her shell's front; floating, a long while)
			_stage = 2
			var on := her._pos + hb * Vector3(0.0, 0.0, L * 0.22)
			on.y = her._pos.y + float(S.shell.ht) * 0.7 * _mm * her.size
			_pos = _pos.lerp(on, 0.06)
			_yaw = lerp_angle(_yaw, her._yaw, 0.08)
			_pitch = lerpf(_pitch, -0.12, 0.05)
			_speed = 0.0
			_neck_to = 1.1
			if _st > _mate_len:
				_end_mate()


func _end_mate() -> void:
	super()
	wander(pond[0], 0.5)


## Its flippers' pose (its shell's mm): in the water, the foreflippers
## beating, up and down (a wing's stroke, sweeping back on the down beat),
## the hind ones trailing, steering; on the bottom laid along its sides; on
## land both foreflippers heaving together; digging, its hind flippers
## (Turtle's); mounted, his foreflippers over her shell's front.
func _pose_leg_extra(L: Array, out: Vector3, foot: Vector3) -> Array:
	var r := _pose_flipper(L, out, foot)
	_flip_at[_legs.find(L)] = r
	return r


## Its blades on its elbows, turned along the forearm, flat (their tops
## up, as near as the way they point lets them).
func _pose(dt: float) -> void:
	super(dt)
	for i in _flippers.size():
		if not _flip_at.has(i):
			continue
		var e: Vector3 = _flip_at[i][0]
		var w: Vector3 = _flip_at[i][1]
		var x := (w - e).normalized()
		var up := Vector3.UP - x * x.dot(Vector3.UP)
		var y := up.normalized() if up.length() > 0.05 else Vector3.BACK
		_flippers[i].transform = Transform3D(Basis(x, y, x.cross(y)), e)


func _pose_flipper(L: Array, out: Vector3, foot: Vector3) -> Array:
	var side: float = L[5]
	var fore: bool = L[4]
	var hip: Vector3 = (L[0] as Node3D).position
	var ground := -_shell_n.position.y
	var wet := _in_water(_pos)
	if _role == "male" and _stage >= 1 and _mode == "mate":
		if fore:
			out = hip + Vector3(150.0 * side, 70.0, -40.0)
			foot = out + Vector3(-20.0 * side, -60.0, -110.0)
		else:
			out = hip + Vector3(60.0 * side, -30.0, 50.0)
			foot = out + Vector3(30.0 * side, -40.0, 80.0)
		return [out, foot]
	if _dig > 0.0 and not fore:
		return [out, foot]
	if wet:
		var resting := _speed < 0.002 and _depth > _deepest() * 0.9
		if resting: # (on the bottom, its flippers laid along its sides)
			if fore:
				out = hip + Vector3(130.0 * side, -40.0, 0.0)
				foot = out + Vector3(110.0 * side, -30.0, 70.0)
			else:
				out = hip + Vector3(60.0 * side, -20.0, 50.0)
				foot = out + Vector3(40.0 * side, -20.0, 80.0)
			return [out, foot]
		var beat := 0.35 if _speed < 0.002 else 1.0 # (hovering: slow sculls)
		var ph := _t * 2.4 * beat
		if fore: # (the stroke: up and down, sweeping back as it comes down)
			var a := 0.1 + sin(ph) * 0.75
			var b := cos(ph)
			var dir := Vector3(side * cos(a), sin(a), -0.3 + 0.25 * b).normalized()
			out = hip + dir * 110.0
			foot = out + (dir + Vector3(0.0, 0.0, 0.5 + 0.25 * b)).normalized() * 140.0 # (the blade trailing back)
		else: # (trailing, steering, a little stroke)
			out = hip + Vector3(70.0 * side, -10.0, 60.0)
			foot = out + Vector3(45.0 * side, 14.0 * sin(ph * 0.5), 85.0)
		return [out, foot]
	# on land: both foreflippers together, planted forward and heaving back
	var push := sin(_t * 1.4)
	if fore:
		out = hip + Vector3(150.0 * side, (ground - hip.y) * 0.45, -40.0 - 50.0 * push)
		foot = Vector3(out.x + 100.0 * side, ground + 15.0, out.z + 30.0 + 70.0 * push)
	else:
		out = hip + Vector3(80.0 * side, (ground - hip.y) * 0.5, 50.0)
		foot = Vector3(out.x + 50.0 * side, ground + 8.0, out.z + 80.0)
	return [out, foot]
