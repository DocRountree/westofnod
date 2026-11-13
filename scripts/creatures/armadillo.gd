class_name Armadillo
extends "res://scripts/creatures/ursid.gd" # (by path: found whether or not the editor has seen the class yet)
## A nine-banded armadillo (Dasypus novemcinctus), life size (about 40 cm
## head and body, its tail 33 cm more; 20 cm high at its back; 5 kg), on
## the bears' make (Ursid: on its soles, standing up on its hind legs; the
## hunters' make under that, Carnivore). Its carapace (Armadillo._shell:
## over its back and down its sides nearly to its elbows and knees, its edge
## flared a little): its shoulder shield before and its hip shield behind,
## each a mosaic of small rounded scutes; between them its nine bands, each
## a row of long scutes pointed behind, each band's rear edge over the next,
## the skin between them pale and pinkish, a few bristles out of it
## (armadillo_shell.gdshader). Its head long and narrow, its snout a
## tapering tube to a small pink nose; a shield of scutes over its crown
## and down its snout; its eyes small and dark; its ears big, upright,
## naked, leathery. Its tail long and tapering, ringed with scutes. Its legs
## short, scaly; four toes before (the middle two longest, their claws long,
## for digging), five behind. Its belly soft, skin, pale pinkish grey,
## with long sparse yellowish hairs (Strands), on its chest and legs too.
## (carnivore.gdshader's species 19.) The young (four, identical, the same
## sex: from the one egg): born with their eyes open, their shells soft and
## leathery, pinkish, hardening as they grow.
##
## Its ways (Ursid's, Carnivore's, and its own):
## - forage(centre, radius): ambling, its nose down, rooting through the
##   litter in zigzags, sniffing, its snout pushed in here and there; where
##   it smells something it eats (Diet: a grub, a beetle, a caterpillar, a
##   pillbug, a snail, a spider: only what's there) it digs at it, its
##   forefeet raking, a pit dug, its snout in; its long sticky tongue out
##   to it, licked up (hunt(prey): the same, to one); an ants' nest licked
##   at (eat_at), the nest left as it is; a fallen fruit eaten where it lies
## - leap(): startled: straight up, a hop of half a metre or more; then off
##   at a run (to its burrow, and in)
## - hunker(secs): drawn down under its shell, its legs and head tucked
##   under, pressed to the ground, still
## - stand(secs): up on its hind legs, its tail a prop behind, its nose up,
##   sniffing the air, its forefeet hanging (Ursid's)
## - dig(at): a burrow: its forefeet raking, the earth thrown back under it
##   and out behind by its hind feet; a hole and a fan of loose earth
##   (Armadillo.burrow()), its home; in, to sleep (sleep()), out again
## - mate(her): he follows her, sniffing; she rolls onto her back, and he
##   mates with her belly to belly, over her
## - birth(4, burrow): in her burrow, four young; nursed lying on her side;
##   after her in a line
## Steering (pilot.gd): act leap, hunker {seconds}, dig {at}, and the
## bears' and the hunters' own.

const SPEC := {
	"species": 19, "plantigrade": true, "sole_hind": 1.2, "boxy": 2.2, "belly": 0.9, "chest_gap": 0.6,
	"body": [[-175.0, 5.0, 52.0, 58.0], [-140.0, 10.0, 72.0, 78.0], [-70.0, 16.0, 86.0, 90.0], [20.0, 18.0, 90.0, 94.0],
			[110.0, 18.0, 88.0, 92.0], [170.0, 10.0, 74.0, 78.0], [205.0, 0.0, 44.0, 50.0]],
	"body_h": 132.0, "body_len": 400.0, "body_w": 90.0,
	"neck_at": Vector3(0.0, 6.0, -178.0), "neck": [[22.0, 0.0, 46.0, 50.0], [-12.0, 0.0, 38.0, 42.0], [-32.0, 0.0, 32.0, 35.0]], "neck_pitch": -0.12,
	"head_at": Vector3(0.0, 0.0, -42.0),
	"head": [[25.0, 0.0, 30.0, 32.0], [-10.0, 3.0, 32.0, 34.0], [-50.0, -2.0, 18.0, 22.0], [-90.0, -6.0, 10.0, 13.0], [-118.0, -8.0, 8.0, 9.0]],
	"jaw_at": Vector3(0.0, -15.0, -22.0), "jaw": [[0.0, 0.0, 13.0, 5.0], [-45.0, 2.0, 8.0, 4.0], [-84.0, 4.5, 5.0, 3.0]], "mouth": 0.35,
	"mouth_z": -330.0, "muzzle_z": -70.0,
	"eye": {"at": Vector3(23.0, 14.0, -12.0), "size": Vector3(7.0, 7.0, 7.0), "color": Color(0.03, 0.025, 0.02), "slit": 1.0},
	"nose": {"at": Vector3(0.0, -8.0, -118.0), "size": Vector3(16.0, 14.0, 8.0), "color": Color(0.7, 0.5, 0.48)},
	"whisker": 0.0,
	"ear": {"at": Vector3(20.0, 26.0, 16.0), "len": 46.0, "width": 30.0, "point": 0.15, "tilt_back": 0.22, "spread": 0.3},
	"tail": {"base": Vector3(0.0, 0.0, 205.0), "n": 8, "seg": 42.0, "radii": [32.0, 27.0, 22.0, 17.5, 13.5, 10.0, 7.0, 4.5], "carry": [0.32, 0.03], "wrap": 0.4, "twitch": 0.0},
	"fore": {"hip": Vector3(52.0, -55.0, -112.0), "a": 52.0, "b": 48.0, "m": 24.0, "p": 30.0, "home": Vector2(60.0, -128.0), "r": 15.0},
	"hind": {"hip": Vector3(56.0, -42.0, 140.0), "a": 66.0, "b": 58.0, "m": 44.0, "p": 40.0, "home": Vector2(64.0, 122.0), "r": 19.0},
	"claw": 22.0, "fur": 6.0, "tail_fur": 0.0,
	"walk": 0.32, "trot": 0.8, "run": 2.2,
	"stalk_from": 0.25, "spring": 0.12, "stalk_crouch": 0.0, "stalk_neck": -0.8, "eat_crouch": 0.2,
	"sit_drop": 60.0, "sit_pitch": 0.6, "lie_h": 70.0,
	"mate_secs": 16.0,
	# its head sculpted (SculptHead), from photographs: long and narrow, its
	# crown flat, no stop, its snout a long tapering tube; its eyes small,
	# set high, a little forward
	"sculpt": {
		"z": [25.0, 10.0, -5.0, -20.0, -35.0, -50.0, -65.0, -80.0, -95.0, -108.0, -118.0],
		"top": [33.0, 37.0, 37.0, 34.0, 28.0, 21.0, 16.0, 13.0, 11.0, 9.5, 8.0],
		"bot": [-28.0, -30.0, -30.0, -27.0, -22.0, -17.0, -14.0, -12.0, -10.5, -9.0, -7.5],
		"w": [29.0, 32.0, 31.0, 26.0, 19.0, 14.0, 11.0, 9.5, 8.5, 7.5, 6.5],
		"wl": [31.0, 34.0, 32.0, 26.0, 19.0, 14.0, 11.0, 9.5, 8.5, 7.5, 6.5],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.3, 2.3, 2.2, 2.2, 2.1, 2.0],
		"eye": Vector3(22.0, 16.0, -13.0), "eye_r": 3.6, "socket": 0.4, "lid": 0.6,
		"brow": 0.6, "cheek": 0.8, "stop": 0.2, "pads": 0.3, "flews": 0.3, "nose_r": 8.5,
		"almond": 0.8, "slant": 0.0, "look_fwd": 0.45, "pupil": Vector2(0.8, 0.8),
	},
}

const BAND_FROM := -35.0 ## (its first band's front, the body's mm)
const BAND_W := 14.4
var _shell: MeshInstance3D
var _shell_mat: ShaderMaterial
var _hairs: MeshInstance3D
var _tongue_: MeshInstance3D
var _tongue_out := 0.0
var _hunker := 0.0
var _hunker_to := 0.0
var _jumped := false
var _dig_at := Vector3.ZERO
var _mound: Node3D
var _on_back := 0.0 # (a female mating: rolled onto her back, 0..1)
var _sniff_spot := Vector3.ZERO


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.2 if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.05


# --- its body ----------------------------------------------------------------------------

## (Its body at z (mm): its middle's y, half width, half height.)
func _body_key(z: float) -> Vector3:
	var bk: Array = (S.body as Array).duplicate()
	bk.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if z <= float(bk[0][0]):
		return Vector3(bk[0][1], bk[0][2], bk[0][3])
	for j in bk.size() - 1:
		var a: Array = bk[j]
		var b: Array = bk[j + 1]
		if z >= float(a[0]) and z <= float(b[0]):
			var f := (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-3)
			f = f * f * (3.0 - 2.0 * f)
			return Vector3(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f))
	var l: Array = bk[bk.size() - 1]
	return Vector3(l[1], l[2], l[3])


func _build_extra() -> void:
	# its claws: four before (the middle two long, for digging), five behind
	var claw := _coat(7)
	for i in 4:
		var paw := _legx[i][1] as MeshInstance3D
		var n := 4 if i < 2 else 5
		for k in n:
			var x := (float(k) - (n - 1) * 0.5) * 0.2
			var l := (0.62 if (k == 1 or k == 2) else 0.36) if i < 2 else 0.3
			_stick(Vector3(x, -0.12, 0.4), Vector3(x * 1.15, -0.4, 0.42 + l), 0.045, claw, paw)
	# its tongue: long, thin, sticky, pink; out only when it licks
	var tp := Node3D.new() # (its root, at its mouth's tip: drawn out from there)
	tp.position = Vector3(0.0, 3.0, -78.0)
	_jaw.add_child(tp)
	_tongue_ = _stick(Vector3(0.0, 0.0, 10.0), Vector3(0.0, -6.0, -75.0), 2.0, _mat(Color(0.82, 0.5, 0.52), 0.25), tp)
	_tongue_.visible = false
	_build_shell()
	# its hair: long, sparse, yellowish white, off its belly, its chest, its legs
	var pale := Color(0.86, 0.8, 0.66)
	var pick := func(p: Vector3, n: Vector3, c0: Color, _h: Vector3) -> Dictionary:
		var part := int(roundf(c0.r))
		var fw := c0.b
		if fw > 0.2:
			return {}
		if part == 0 and n.y < 0.15:
			return {"w": 0.8 if n.y < -0.3 else 0.35, "len": 28.0, "r": 0.32, "lie": (Vector3.DOWN + Vector3.BACK * 0.4 - n * 0.2).normalized(), "up": n, "root": pale * 0.8, "tip": pale, "tip_from": 0.5, "droop": 0.6, "sides": 3}
		if (part == 2 or part == 3) and c0.g < 0.6:
			return {"w": 0.6, "len": 22.0, "r": 0.3, "lie": (Vector3.DOWN + n * 0.3).normalized(), "up": n, "root": pale * 0.8, "tip": pale, "tip_from": 0.5, "droop": 0.5, "sides": 3}
		return {}
	if _torso:
		_hairs = Strands.grow(_torso, 700 if not young else 250, pick, 31)


## Its carapace: over its back from its shoulders to its rump and down its
## sides, a little off its skin; its edge flared; its bands' rear edges
## raised, each over the next. One mesh, on its body (its torso rigid under
## it): its own shader's scutes (armadillo_shell.gdshader).
func _build_shell() -> void:
	# (its outline, nose to tail: [z, half width, its top's y, where it's
	# widest (y), its edge's y] (the body's mm): high domed over its middle,
	# its sides hanging straight down nearly to its elbows and knees, its
	# ends arched down over its shoulders and its rump)
	var prof := [[-192.0, 52.0, 44.0, 8.0, -10.0], [-180.0, 70.0, 74.0, 4.0, -30.0], [-150.0, 86.0, 98.0, 0.0, -44.0], [-80.0, 97.0, 114.0, 0.0, -54.0], [20.0, 101.0, 121.0, 0.0, -58.0],
			[110.0, 99.0, 119.0, 0.0, -60.0], [175.0, 89.0, 104.0, -5.0, -64.0], [205.0, 72.0, 76.0, -10.0, -66.0], [222.0, 50.0, 42.0, -14.0, -52.0], [228.0, 34.0, 26.0, -10.0, -36.0]]
	var z0 := float(prof[0][0])
	var z1 := float(prof[prof.size() - 1][0])
	var NZ := 96
	var NA := 36 # (over the top, side to side)
	var NS := 6 # (down each side, its skirt)
	var pw := float(S.boxy)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var P := []
	var UVs := []
	var E := []
	var W := NS * 2 + NA + 1
	for i in NZ + 1:
		var z := lerpf(z0, z1, float(i) / NZ)
		var k: Array = prof[0]
		var k2: Array = prof[0]
		for q in prof.size() - 1:
			if z >= float(prof[q][0]) and z <= float(prof[q + 1][0]):
				k = prof[q]
				k2 = prof[q + 1]
		var f := (z - float(k[0])) / maxf(float(k2[0]) - float(k[0]), 1e-3)
		f = f * f * (3.0 - 2.0 * f)
		var hw := lerpf(k[1], k2[1], f)
		var top := lerpf(k[2], k2[2], f)
		var ym := lerpf(k[3], k2[3], f)
		var low := lerpf(k[4], k2[4], f)
		var t := 0.0
		if z > BAND_FROM and z < BAND_FROM + BAND_W * 9.0: # (each band's rear edge raised over the next's front)
			t = 3.4 * fmod(z - BAND_FROM, BAND_W) / BAND_W - 1.2
		var pts := []
		var er := []
		for j in W:
			var q: Vector3
			var edge: float
			if j < NS or j > NS + NA: # (a skirt: straight down its side, flared at the bottom)
				var side := -1.0 if j < NS else 1.0
				var u := float(NS - j) / NS if j < NS else float(j - NS - NA) / NS # (1 at its edge)
				var fl := 5.0 * u * u
				q = Vector3(side * (hw + t + fl), lerpf(ym, low, u), z)
				edge = 0.6 + 0.4 * u
			else:
				var a := PI * float(j - NS) / NA # (0 its right side .. PI its left)
				var cx := cos(a)
				var cy := sin(a)
				var ex := signf(cx) * pow(absf(cx), 2.0 / pw)
				var ey := pow(absf(cy), 2.0 / pw)
				q = Vector3(-ex * (hw + t), ym + ey * (top - ym + t), z)
				edge = 0.6 * absf(cx)
			pts.append(q)
			er.append(edge)
		# (round it, mm from its spine: signed)
		var mid := NS + NA / 2
		var arcs := []
		arcs.resize(W)
		arcs[mid] = 0.0
		for j in range(mid + 1, W):
			arcs[j] = float(arcs[j - 1]) + (pts[j] as Vector3).distance_to(pts[j - 1])
		for j in range(mid - 1, -1, -1):
			arcs[j] = float(arcs[j + 1]) - (pts[j] as Vector3).distance_to(pts[j + 1])
		var uvr := []
		for j in W:
			uvr.append(Vector2(z, float(arcs[j])))
		P.append(pts)
		UVs.append(uvr)
		E.append(er)
	var WN := W - 1
	for i in NZ:
		for j in WN:
			var quad := [[i, j], [i, j + 1], [i + 1, j], [i, j + 1], [i + 1, j + 1], [i + 1, j]]
			for q: Array in quad:
				var a: int = q[0]
				var b: int = q[1]
				var p: Vector3 = P[a][b]
				var t1: Vector3 = P[a][mini(b + 1, WN)] - P[a][maxi(b - 1, 0)]
				var t2: Vector3 = P[mini(a + 1, NZ)][b] - P[maxi(a - 1, 0)][b]
				var n := t2.cross(t1).normalized()
				if n.dot(p - Vector3(0.0, 0.0, p.z)) < 0.0:
					n = -n
				st.set_normal(n)
				st.set_uv(UVs[a][b])
				st.set_uv2(Vector2(E[a][b], 0.0))
				st.add_vertex(p)
	_shell_mat = ShaderMaterial.new()
	_shell_mat.shader = preload("res://shaders/render/armadillo_shell.gdshader")
	_shell_mat.set_shader_parameter("young", young)
	_shell_mat.set_shader_parameter("band_from", BAND_FROM)
	_shell_mat.set_shader_parameter("band_w", BAND_W)
	_shell = MeshInstance3D.new()
	_shell.mesh = st.commit()
	_shell.material_override = _shell_mat
	_body.add_child(_shell)
	# (bristles out of the skin between its bands, a few, pale, down its sides)
	var hair := _mat(Color(0.86, 0.8, 0.66), 0.6)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for b in 9:
		for k in 5:
			var z := BAND_FROM + BAND_W * float(b) + 1.0
			var a := (r.randf_range(0.0, 1.0) if k % 2 == 0 else r.randf_range(-1.0, 0.0)) * 1.55 + PI * 0.5
			var kk := _body_key(z)
			var cx := cos(a)
			var cy := sin(a)
			var p := Vector3(signf(cx) * pow(absf(cx), 2.0 / pw) * (kk.y + 8.0), kk.x + signf(cy) * pow(absf(cy), 2.0 / pw) * (kk.z + 8.0), z)
			var out := Vector3(p.x, p.y - kk.x, 0.0).normalized()
			_stick(p, p + (out * 0.5 + Vector3(0.0, -0.6, 0.6)).normalized() * r.randf_range(14.0, 24.0), 0.35, hair, _body)


# --- its burrow -------------------------------------------------------------------------

## Its burrow: a hole about 20 cm across, going down at a slant into the
## ground (its mouth facing -z), the earth it's dug fanned out in front
## of it, loose, fresh. Its origin at its mouth, on the ground.
static func burrow() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.42, 0.32, 0.22)
	earth.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.025, 0.02)
	var fan := MeshInstance3D.new() # (the loose earth thrown out, a fan before it)
	fan.mesh = s
	fan.material_override = earth
	fan.position = Vector3(0.0, 0.0, -0.22)
	fan.scale = Vector3(0.5, 0.07, 0.45)
	root.add_child(fan)
	var mound := MeshInstance3D.new() # (the bank over it)
	mound.mesh = s
	mound.material_override = earth
	mound.position = Vector3(0.0, 0.0, 0.18)
	mound.scale = Vector3(0.42, 0.18, 0.4)
	root.add_child(mound)
	var hole := MeshInstance3D.new()
	hole.mesh = s
	hole.material_override = dark
	hole.position = Vector3(0.0, 0.045, 0.0)
	hole.scale = Vector3(0.2, 0.15, 0.06)
	hole.rotation.x = -0.5
	root.add_child(hole)
	var rr := RandomNumberGenerator.new()
	rr.seed = 3
	for k in 12: # (clods)
		var c := MeshInstance3D.new()
		c.mesh = s
		c.material_override = earth
		var a := rr.randf_range(-1.2, 1.2)
		c.position = Vector3(sin(a) * rr.randf_range(0.1, 0.35), 0.01, -0.1 - cos(a) * rr.randf_range(0.05, 0.3))
		c.scale = Vector3.ONE * rr.randf_range(0.02, 0.045)
		root.add_child(c)
	return root


func _sleep_home() -> Node3D:
	return home_den


func _home_door(h: Node3D) -> Vector3:
	return h.global_position


# --- what it does --------------------------------------------------------------------------

## Rooting about (centre, radius): see the class.
func forage(centre: Vector3, radius: float) -> void:
	super(centre, radius)
	_sniff_spot = _pos


## Startled: straight up, then off at a run.
func leap() -> void:
	if dead or airborne or _carrier_mode():
		return
	_mode = "leap"
	_stage = 0
	_st = 0.0
	_jumped = false


## Drawn down under its shell, pressed to the ground, still (secs).
func hunker(secs := 10.0) -> void:
	if dead:
		return
	_mode = "hunker"
	_st = 0.0
	_wait = secs


func sit(secs := 8.0) -> void:
	hunker(secs)


## (Done eating: on rooting about, not sat grooming.)
func groom() -> void:
	forage(_pos, maxf(_radius, 1.5))


## A burrow dug at `at` (on the ground): its home.
func dig(at: Vector3) -> void:
	if young or dead:
		return
	_mode = "dig"
	_dig_at = at
	_stage = 0
	_st = 0.0


func _carrier_mode() -> bool:
	return _mate_role != ""


# --- its thinking -------------------------------------------------------------------------

func _think(dt: float) -> void:
	_hunker_to = 0.0
	if _mode in ["leap", "hunker", "dig", "forage"]:
		_stand_to = 0.0
	_tongue_out = move_toward(_tongue_out, 0.0, dt * 4.0)
	match _mode:
		"leap":
			_common(dt)
			_leap_step(dt)
			return
		"hunker":
			_common(dt)
			_target = _pos
			_hunker_to = 1.0
			_neck_to = Vector2(-0.9, 0.0)
			_ears_to = -1.0
			_tail_mode = "low"
			if _wait <= 0.0:
				wander(_home_spot(), _radius)
			return
		"dig":
			_common(dt)
			_dig_step(dt)
			return
		"forage":
			_common(dt)
			_root(dt)
			return
	super(dt)
	if young and _mode == "follow" and is_instance_valid(_mother): # (after her in a line, nose to tail: not under her)
		var k := maxi((_mother.get("young_ones") as Array).find(self), 0)
		var spot: Vector3 = _mother.call("_out", Vector3(0.0, 0.0, float(S.body_len) * 0.75 + float(S.tail.seg) * 3.0 + 260.0 * float(k)))
		_target = Vector3(spot.x, _pos.y, spot.z) if Vector2(spot.x - _pos.x, spot.z - _pos.z).length() > 0.06 else _pos
	if _mode == "stand": # (its head held out level, nose up a little, sniffing: not its snout to the sky)
		_neck_to = Vector2(-1.35, 0.0)
		_look_to = Vector2(-0.25 + 0.08 * sin(_st * 0.9), 0.4 * sin(_st * 0.5))
	# (licking: its tongue out at what it's eating, an insect, ants)
	var licking := (_mode == "eat_at" and _stage == 1) or (_mode == "hunt" and _stage == 6 and is_instance_valid(_prey) and not MealScript.is_vertebrate(_prey))
	if licking:
		_tongue_out = 0.5 + 0.5 * maxf(sin(_st * 9.0), 0.0)
		_jaw_to = maxf(_jaw_to, 0.12)
	if _mode == "hunt" and _stage in [1, 2]: # (its nose down to it, sniffing, its forefeet raking at it)
		_sniff = 1.0
		_dig = 1.0


## Rooting: ambling in zigzags, its nose in the litter; where it smells what
## it eats, digging to it, and its tongue to it.
func _root(dt: float) -> void:
	_neck_to = Vector2(-0.85, 0.25 * sin(_st * 2.3))
	_sniff = 1.0
	_pace = float(S.walk) * 0.55 * lerpf(0.35, 1.0, size)
	_ears_to = 0.4
	if _wait <= 0.0:
		_wait = rng.randf_range(1.5, 3.0)
		var a := _yaw + rng.randf_range(-0.9, 0.9) # (zigzagging on)
		var to := _pos + Vector3(-sin(a), 0.0, -cos(a)) * rng.randf_range(0.2, 0.45)
		if to.distance_to(_centre) > _radius:
			to = _centre + (to - _centre).limit_length(_radius * 0.7)
		_target = to
		if rng.randf() < 0.35: # (its snout pushed into the litter here, a moment)
			_stage = 1
			_st = 0.0
			_target = _pos
	if _stage == 1:
		_target = _pos
		_pace = -1.0
		_neck_to = Vector2(-1.1, 0.0)
		_dig = 1.0
		if _st > 1.6:
			_stage = 0
	# (something it eats, near its nose: smelled, dug for)
	if fmod(_st, 0.7) < dt:
		var m := _mouth()
		var f := Diet.find_one(self, 0.9, Diet.prey_of(self).filter(func(k: String) -> bool: return k not in ["frog", "toad", "anole", "mouse_pup"]))
		if f != null and f != self and is_instance_valid(f) and (f as Node3D).global_position.distance_to(m) < 0.9:
			f.set_meta("hunted", self)
			hunt(f as Node3D)


## (The hunt's end, its own: rooting at it, its snout to it, digging; no
## pounce.)
func _attack(dt: float, p: Vector3, d: float) -> bool:
	var reach := absf(float(S.mouth_z)) * MM * size
	var to := Vector3(p.x - _pos.x, 0.0, p.z - _pos.z)
	_target = p - to.normalized() * reach * 0.9 if d > reach * 0.95 else _pos
	_pace = float(S.walk) * 0.5
	_neck_to = Vector2(-1.0, 0.0)
	_sniff = 1.0
	_dig = 1.0
	return d <= reach * 1.1 and _st > 1.2


func _leap_step(dt: float) -> void:
	match _stage:
		0: # (straight up)
			if not _jumped:
				_jumped = true
				var h := 0.55 * size / 0.5
				_vel = Vector3(-sin(_yaw) * 0.15, sqrt(2.0 * G * h), -cos(_yaw) * 0.15)
				airborne = true
				_steer = Vector3.INF
				_alt = 0.001
				_ears_to = -0.5
			if not airborne and _st > 0.2:
				_stage = 1
				_st = 0.0
		1: # (off at a run: to its burrow, and in; or away)
			_pace = float(S.run) * lerpf(0.5, 1.0, size)
			_ears_to = -0.6
			_tail_mode = "out"
			if is_instance_valid(home_den):
				var door := _home_door(home_den)
				_target = Vector3(door.x, _pos.y, door.z)
				if Vector2(_pos.x - door.x, _pos.z - door.z).length() < 0.2:
					_pace = -1.0
					sleep(15.0)
			else:
				if _st < 0.05:
					var a := _yaw + rng.randf_range(-0.6, 0.6)
					_target = _pos + Vector3(-sin(a), 0.0, -cos(a)) * 4.0
				if _st > 4.0:
					_pace = -1.0
					hunker(6.0)


## (Digging its burrow: to the place, digging, the earth thrown back; the
## burrow there, its home; in.)
func _dig_step(dt: float) -> void:
	match _stage:
		0:
			_target = Vector3(_dig_at.x, _pos.y, _dig_at.z) + Vector3(sin(_yaw), 0.0, cos(_yaw)) * 0.1
			_neck_to = Vector2(-0.6, 0.0)
			if Vector2(_pos.x - _dig_at.x, _pos.z - _dig_at.z).length() < 0.2 or _st > 15.0:
				_target = _pos
				_stage = 1
				_st = 0.0
				_mound = burrow()
				get_parent().add_child(_mound)
				var g := Vector3(_dig_at.x, _ground(_dig_at.x, _dig_at.z), _dig_at.z)
				_mound.position = g
				_mound.rotation.y = _yaw + PI
				_mound.scale = Vector3.ONE * 0.05
		1: # (its forefeet raking, its head down in it; the burrow growing)
			_target = _pos
			_neck_to = Vector2(-1.05, 0.15 * sin(_st * 3.0))
			_dig = 1.0
			_crouch = 0.25
			if is_instance_valid(_mound):
				_mound.scale = Vector3.ONE * lerpf(0.05, 1.0, clampf(_st / 14.0, 0.0, 1.0)) * size / 0.5
			if _st > 14.0:
				_crouch = 0.0
				home_den = _mound
				sleep(12.0)


# --- the young --------------------------------------------------------------------------

func birth(n := 4, den_: Node3D = null) -> void:
	super(4 if n > 0 else 0, den_)


func _young_one() -> void:
	super()
	var y := young_ones[young_ones.size() - 1]
	if not is_instance_valid(y):
		return
	# (identical, all four: the one egg's; the same sex)
	if young_ones.size() == 1:
		set_meta("litter_male", rng.randf() < 0.5)
	y.set("male", bool(get_meta("litter_male", false)))
	y.set("size", 0.21) # (eyes open, up and about soon)
	y.call("grow", 0.5, 500.0)


# --- the pose ---------------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	_hunker = move_toward(_hunker, _hunker_to, dt * 2.5)
	if _tongue_:
		_tongue_.visible = _tongue_out > 0.05
		(_tongue_.get_parent() as Node3D).scale = Vector3(1.0, 1.0, maxf(_tongue_out, 0.05))
	if _dig > 0.0 and not airborne and _stand < 0.05: # (its forefeet raking at the ground, by turns, fast)
		for i in 2:
			var side := 1.0 if i % 2 == 1 else -1.0
			var hm: Vector2 = legs[0].home
			var ph := _t * 14.0 + (PI if i == 1 else 0.0)
			var g := _ground_at(Vector3(hm.x * side * 0.7, 0.0, hm.y - 30.0 + 35.0 * sin(ph)))
			_pose_foot[i] = g + Vector3(0.0, maxf(cos(ph), 0.0) * 22.0, 0.0)
	elif _mode in ["forage", "hunt", "dig"] and _stand < 0.05:
		for i in 2:
			_pose_foot[i] = null
	_dig = move_toward(_dig, 0.0, dt * 2.0)
	if _hunker > 0.01 and not airborne: # (down under its shell, its legs drawn in, its belly to the ground)
		var k := _hunker * _hunker * (3.0 - 2.0 * _hunker)
		_lift = lerpf(_lift, -(body_h - float((S.body as Array)[3][3]) * 0.92), k)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			_pose_foot[i] = _ground_at(Vector3(hp.x * side * 0.75, 0.0, hp.z + (15.0 if i < 2 else -15.0)))
	if _on_back > 0.01: # (on her back: her shell to the ground, her legs up)
		var k := _on_back * _on_back * (3.0 - 2.0 * _on_back)
		_roll = lerpf(_roll, PI, k)
		var top := float((S.body as Array)[3][1]) + float((S.body as Array)[3][3]) + 9.0
		_lift = lerpf(_lift, top - body_h, k)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			_pose_foot[i] = Vector3(hp.x * side * 1.1, hp.y - float(L.f) * 0.9, hp.z + (-20.0 if i < 2 else 20.0))
	if _stand > 0.05: # (standing: its tail down, a prop)
		_tail_mode = "prop"


func _pose_tail(dt: float) -> void:
	if _tail_mode != "prop":
		super(dt)
		return
	for k in _tail.size():
		var down := 0.0 if k > 0 else -0.9 * _stand # (its root down behind it, the rest along the ground)
		var now: Array = _tail_k[k]
		var a := lerpf(float(now[0]), down, 1.0 - exp(-5.0 * dt))
		_tail_k[k] = [a, lerpf(float(now[1]), 0.0, 1.0 - exp(-5.0 * dt))]
		_tail[k].rotation = Vector3(a, float(_tail_k[k][1]), 0.0)


# --- mating -------------------------------------------------------------------------------

func _court_secs() -> float:
	return 6.0


func _mating(dt: float) -> void:
	super(dt)
	if _mate_role == "female":
		var on: bool = _mate_stage == "joined" or (is_instance_valid(_mate) and _mate.get("_mate_stage") in ["mount", "joined"])
		_on_back = move_toward(_on_back, 1.0 if on else 0.0, dt * 1.2)


func _after_mate() -> void:
	super()


## (Over her, she on her back: belly to belly, his forefeet either side of
## her; his hind feet on the ground behind.)
func _mount() -> Dictionary:
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	for i: int in [0, 1, 2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var z := -60.0 if i < 2 else 200.0
		var w: Vector3 = _mate.call("_out", Vector3(-float(S.body_w) * 1.1 * side, 0.0, z))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	_neck_to = Vector2(-0.5, 0.0)
	var depth := float((S.body as Array)[3][3]) * 2.0 + 20.0
	return {"at": Vector3(0.0, -depth, 30.0), "basis": Basis(Vector3.BACK, PI), "grips": {}, "free": free, "thrust": false}


func _on_mate_start() -> void:
	if _mode in ["hunker", "leap", "dig", "forage"]:
		_mode = "idle"


func _process(dt: float) -> void:
	super(dt)
	if _mate_role == "" and _on_back > 0.0:
		_on_back = move_toward(_on_back, 0.0, dt)


# --- steering (pilot.gd) ------------------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["leap", "hunker", "dig"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"leap":
			leap()
		"hunker":
			hunker(float(args.get("seconds", 10.0)))
		"dig":
			dig(args.get("at", _pos + _p_heading() * 0.4))
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["leap", "hunker", "dig"]:
		return _mode != name
	return super(name)
