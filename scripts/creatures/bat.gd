class_name Bat
extends Node3D
## A big brown bat (Eptesicus fuscus), life size: nose to rump 68 mm, its
## tail 40 more, its forearm 47 mm, 33 cm across its spread wings, 18 g. Its
## model in mm (its body: -z its nose, +y its back, +x its right).
##
## How it's made: its body, its head and its jaw one skin (MammalSkin): the
## body deep and broad at its chest, narrow at its hips; the head sculpted
## (SculptHead: a broad round braincase, a short blunt muzzle swollen either
## side between eye and nostril, its glands; small eye sockets). Over the
## skin its fur, in shells (bat_fur.gdshader: the skin drawn again, shell on
## shell, each keeping the hairs that reach it): long, soft, lying back,
## each hair dark at its root, glossy brown at its tip (buff beneath);
## shorter on its crown, short and dark down its face, none on its muzzle,
## lips and round its eyes: black, bare skin. Its nose a bare pad, a round
## nostril either side; its eyes small black beads; its ears broad, rounded,
## thick and leathery, funnelled at their base, a short blunt tragus in
## each; its mouth pink inside, its tongue, its teeth behind its lips till
## it opens (incisors, the long canines, premolars, sharp-cusped molars).
## Its wings and tail membrane bare skin (bat_skin.gdshader: dark, finely
## wrinkled, crumpled where it's folded; opaque) stretched between its
## bones, rebuilt as they move: the arm (humerus, forearm), the thumb with
## its claw at the wrist, the four long fingers (the second along the
## leading edge, the third to the tip, the fourth and fifth fanned behind),
## the membrane before the arm (propatagium), between the fingers
## (dactylopatagium), from the fifth finger to its side and ankle
## (plagiopatagium), and between its legs round its tail (uropatagium), the
## calcar along its edge; each membrane's free edge scalloped in between
## the bones; the bones under their own skin, swollen at each joint; its
## hind legs turned, knees back, its feet's five toes clawed and curled.
##
## Its ways:
## - hanging (its roost: set_roost(point): the world's to give it): head
##   down from its hind feet, its claws hooked over; its wings folded along
##   its sides; looking about, its ears turning; yawning; stretching a wing
## - torpor / sleep(secs): hanging still, wings wrapped close, eyes shut,
##   breathing slow
## - groom(): hanging by one foot, the other combing its fur; its head round
##   to lick a wing held out
## - crawl (on the ground): low, on its wrists and feet, wings folded
## - take-off: dropping from its roost, wings opening, away; off the
##   ground, a spring with a downstroke
## - flight: its wings beating (folding partway on each upstroke), banking,
##   its legs and tail membrane trailing; calling as it goes, its mouth
##   opening on each call, faster as it closes on prey (the feeding buzz)
## - forage(): at dusk and by night, flying beats round its patch, hawking:
##   hunt(prey): a flying insect run down, scooped into its tail membrane
##   (curled forward under it) and taken from there in its mouth; or one on
##   the ground gleaned: down beside it, its mouth to it; chewed on the
##   wing, swallowed. Only what its pouch or mouth reaches is taken. Its
##   diet (Diet): beetles (June bugs), moths, small flying wasps
## - drink(at): skimming low over the water, its lower jaw dipped in
## - alarm(): its mouth wide, its teeth bared, buzzing, its wings half out;
##   then, if it can, off
## - land: back to its roost, up under it, flipping over at the last to
##   hook its feet on
## - mating (a male's: mate(her)): to her at the roost, on her back from
##   behind, his teeth in her nape, his wings round her
## - birth(n) (a female's, gravid): turned head up, hanging by her thumbs,
##   her tail membrane cupped; each pup born into it, licked, crawling up to
##   her nipple; then head down again. Twins, often, in the east
## - its pups (Bat.new(true)): born pink and naked, eyes shut, clinging to
##   her breast at her nipple; left hanging at the roost while she forages,
##   found again and nursed; furred, eyes open, growing; flapping where they
##   hang; flying at last (juveniles: grown)
##
## Steering (pilot.gd): act hunt {prey}, forage {seconds}, drink {at},
## sleep {seconds}, groom {seconds}, alarm, roost, mate {partner}, birth {n}.

signal action_finished(name: String, ok: bool)

const PilotScript := preload("res://scripts/creatures/pilot.gd")
const SkinScript := preload("res://scripts/creatures/mammal_skin.gd")
const SculptScript := preload("res://scripts/creatures/sculpt_head.gd")
const MealScript := preload("res://scripts/creatures/meal.gd")

# its bones, mm
const SHOULDER := Vector3(8.0, 3.5, -13.0)
const HIP := Vector3(4.5, -1.0, 19.0)
const TAIL_ROOT := Vector3(0.0, -0.8, 24.0)
const HEAD_AT := Vector3(0.0, 2.2, -22.0) # (its skull's base: where its head turns)
const JAW_AT := Vector3(0.0, -2.4, -4.5) # (its jaw's hinge, the head's space)
const MOUTH := Vector3(0.0, -2.7, -15.0) # (its mouth, the head's space: between its jaws' tips)
const SHELLS := 24 # (its fur's)
const L := {"hum": 24.0, "fore": 47.0, "d2": 40.0, "d3a": 44.0, "d3b": 36.0, "d4a": 42.0, "d4b": 24.0, "d5a": 40.0, "d5b": 16.0, "thumb": 8.0,
		"femur": 15.0, "tibia": 19.0, "foot": 9.0, "calcar": 15.0}
const TAIL_N := 8
const TAIL_SEG := 5.0
# (each bone's way, the right side's: [folded, spread])
const DIRS := {
	"hum": [Vector3(0.3, -0.35, 0.89), Vector3(0.8, 0.05, 0.6)],
	"fore": [Vector3(0.12, -0.15, -0.98), Vector3(0.75, 0.0, -0.66)],
	"d2": [Vector3(0.08, -0.12, 0.99), Vector3(0.55, 0.02, -0.83)],
	"d3a": [Vector3(0.1, -0.2, 0.97), Vector3(0.93, 0.02, -0.35)],
	"d3b": [Vector3(0.05, -0.28, -0.96), Vector3(0.99, -0.02, 0.1)],
	"d4a": [Vector3(0.13, -0.24, 0.96), Vector3(0.75, 0.0, 0.45)],
	"d4b": [Vector3(0.06, -0.3, -0.95), Vector3(0.5, -0.03, 0.85)],
	"d5a": [Vector3(0.16, -0.28, 0.94), Vector3(0.25, 0.0, 0.97)],
	"d5b": [Vector3(0.08, -0.33, -0.94), Vector3(0.05, -0.03, 1.0)],
	"thumb": [Vector3(0.25, 0.25, -0.93), Vector3(0.2, 0.3, -0.93)],
}
# (its legs' ways, the right's: flying (trailing); hanging (up to its feet); crawling)
const LEGS := {
	"fly": [Vector3(0.45, -0.15, 0.88), Vector3(0.3, -0.12, 0.95), Vector3(0.1, 0.2, 0.98)],
	"hang": [Vector3(0.22, 0.05, 0.97), Vector3(0.08, 0.12, 0.99), Vector3(0.0, 0.65, 0.76)],
	"crawl": [Vector3(0.8, 0.25, 0.55), Vector3(0.3, -0.9, 0.3), Vector3(0.25, -0.05, 0.97)], # (splayed, knees up and out, feet down)
}

var young := false ## (a pup: clinging, growing)
var juvenile := false
var male := false
var dead := false
var gravid := false
var size := 1.0
var height: Callable ## (x, z) -> the ground's y there (none: 0)
var roost_at := Vector3.INF ## (where it hangs: the world's to give it; its claws there)
var roost_face := Vector3.BACK ## (the way its back faces, hanging)
var pups: Array = []
var hunger := 0.5
var grow_secs := 240.0

var _pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _ori := Basis() # (its body's, now)
var _yaw := 0.0
var _mode := "hang"
var _sub := ""
var _st := 0.0
var _mt := 0.0
var _secs := -1.0
var _age := 0.0
var _mother: Node3D
var _partner: Node3D
var _prey: Node3D
var _held: Node3D # (what it's caught: in its tail pouch, then its mouth)
var _held_in := "" # "pouch", "mouth"
var _fly_to := Vector3.INF
var _patch := Vector3.ZERO # (its foraging beat's middle)
var _drink_at := Vector3.INF
var _phase := 0.0 # (the wingbeat's)
var _call_t := 0.0
var _pilot: PilotScript
var _piloted := false
var _rng := RandomNumberGenerator.new()
var _last_pouch := Vector3.INF
var _then := "forage" # (what it's off to do, once it's dropped from its roost)
var _then_sub := ""

# the pose (each frame)
var spread := [0.0, 0.0] # (each wing: 0 folded .. 1 spread; left, right)
var stroke := [0.0, 0.0] # (rad: each wing raised (+) or lowered at the shoulder)
var _legs_w := {"fly": 0.0, "hang": 1.0, "crawl": 0.0}
var _tail_curl := 0.0 # (0 trailing straight back .. 1 curled forward under it: a pouch)
var _head_yp := Vector2.ZERO # (the head turned: yaw, pitch)
var _head_off := Vector3.ZERO # (its neck bent: the head moved, mm)
var _jaw := 0.0 # (its mouth open, rad)
var _ears := 0.0 # (0 up .. 1 laid back)
var _eyes_shut := 0.0
var _breath := 0.0
var _one_foot := 0.0 # (its left foot let go: grooming with it)
var _pose_sig := PackedFloat32Array()

var _body: Node3D
var _head: Node3D
var _jawn: Node3D
var _skin: SkinScript
var _sb := {}
var _fur: ShaderMaterial
var _membrane: ShaderMaterial
var _limb: ShaderMaterial
var _ear_mat: ShaderMaterial
var _mem: MeshInstance3D
var _bones: MeshInstance3D
var _shells: Array[MeshInstance3D] = []
var _teeth: Array[Node3D] = []
var _eye_mi: Array[MeshInstance3D] = []
var _lid_mi: Array[MeshInstance3D] = []
var _ear_n: Array[Node3D] = []
var _mouth_in: MeshInstance3D
var _foot_n: Array[Node3D] = []
var _thumb_n: Array[Node3D] = []


func _init(young_ := false) -> void:
	young = young_
	_rng.randomize()
	male = _rng.randf() < 0.5


func _ready() -> void:
	_build()
	if young:
		size = 0.42
		_mode = "cling"
	_apply_size()


func _apply_size() -> void:
	if _body:
		_body.scale = Vector3.ONE * size * 0.001
	if _fur:
		var g := clampf((size - 0.45) / 0.35, 0.0, 1.0) if young else 1.0
		_fur.set_shader_parameter("fur", g)
		for m: ShaderMaterial in [_membrane, _limb, _ear_mat]:
			m.set_shader_parameter("pup", (1.0 - g) * 0.7)
		for sh in _shells: # (naked: no fur to draw)
			sh.visible = g > 0.02
	for l in _lid_mi:
		l.visible = young and size < 0.6
	for e in _eye_mi:
		e.visible = not (young and size < 0.6)


# --- its make ---------------------------------------------------------------------------

static func _mat(c: Color, rough := 0.6, back := Color(0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if back != Color(0, 0, 0):
		m.backlight_enabled = true
		m.backlight = back
	return m


func _ell(at: Vector3, s: Vector3, m: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.scale = s
	mi.position = at
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cone(base: Vector3, tip: Vector3, r: float, m: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = base.distance_to(tip)
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	parent.add_child(mi)
	mi.transform = Transform3D(SkinScript.along(base, tip).basis, (base + tip) * 0.5)
	return mi


# its body under its fur (the skin): [z, y, half width, half height]: deep and
# broad at its chest (its flight muscles), narrow at its hips
const BODY_KEYS := [[26.0, -0.7, 2.2, 2.0], [21.5, -0.5, 4.4, 3.9], [15.0, -0.2, 6.4, 5.7], [7.0, 0.2, 8.0, 7.0], [-3.0, 0.6, 9.0, 7.9],
		[-12.0, 1.0, 9.2, 8.2], [-18.5, 1.8, 8.6, 7.9], [-24.0, 2.4, 7.0, 6.6]]
# its head, sculpted (SculptHead: the head's mm, its skull's base its
# origin): a broad, rounded braincase, a short broad muzzle, swollen either
# side between eye and nostril (its glands); its eyes small, on its sides
const HEAD := {
	"z": [3.0, 0.0, -4.0, -7.5, -10.0, -12.0, -14.0, -15.6, -16.6],
	"top": [5.4, 8.2, 9.0, 8.5, 7.1, 5.6, 4.4, 3.5, 2.4],
	"bot": [-1.6, -3.0, -3.6, -3.6, -3.3, -3.0, -2.7, -2.3, -1.0],
	"w": [4.8, 7.2, 7.9, 7.6, 6.5, 5.4, 4.6, 3.8, 2.5],
	"wl": [4.8, 6.9, 7.6, 7.4, 6.6, 5.7, 5.0, 4.1, 2.5],
	"pw": [2.0, 2.0, 2.1, 2.1, 2.1, 2.15, 2.2, 2.15, 2.0],
	"eye": Vector3(5.9, 3.4, -9.9), "eye_r": 1.5, "socket": 0.25, "lid": 0.3, "brow": 0.5, "cheek": 0.7, "stop": 0.6, "pads": 0.6,
	"flews": 0.45, "almond": 0.85, "slant": 0.0, "look_fwd": 0.35,
}
const HEAD_NZ := 30
const HEAD_NA := 28


## Its head's surface at z, round it by phi (SculptHead's, and its own: the
## glands either side of its muzzle, its jaw's muscle).
static func _head_pt(z: float, phi: float) -> Vector3:
	var p: Vector3 = SculptScript.point(HEAD, z, phi)
	var side := signf(p.x) if absf(p.x) > 1e-4 else 1.0
	var out := Vector3(p.x, p.y - 1.0, 0.0)
	out = out.normalized() if out.length() > 1e-3 else Vector3.UP
	var gl := Vector3(3.9 * side, 2.2, -13.0)
	p += out * 1.25 * exp(-2.6 * pow(p.distance_to(gl) / 2.5, 2.0))
	var ms := Vector3(6.8 * side, -0.4, -5.5)
	p += out * 0.7 * exp(-2.6 * pow(p.distance_to(ms) / 4.0, 2.0))
	return p


func _skin_mat(kind: int, c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/bat_skin.gdshader")
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("skin_color", Vector3(c.r, c.g, c.b))
	return m


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	_fur = ShaderMaterial.new()
	_fur.shader = preload("res://shaders/render/bat_fur.gdshader")
	_membrane = _skin_mat(0, Color(0.135, 0.108, 0.097)) # (plain, opaque dark skin)
	_limb = _skin_mat(1, Color(0.15, 0.115, 0.1))
	_ear_mat = _skin_mat(2, Color(0.115, 0.09, 0.08))
	var dark := _mat(Color(0.012, 0.009, 0.008), 0.38) # (its nose's leather, its lids)
	var claw := _mat(Color(0.03, 0.022, 0.018), 0.25)
	_head = Node3D.new()
	_head.position = HEAD_AT
	_body.add_child(_head)
	_jawn = Node3D.new()
	_jawn.position = JAW_AT
	_head.add_child(_jawn)
	# its skin: its body; its head, sculpted, its back in its shoulders' fur; its jaw
	var K: SkinScript = SkinScript.new()
	var torso := K.bone("torso", Transform3D())
	var hrest := _head.transform
	var hb := K.bone("head", hrest)
	var jrest := hrest * _jawn.transform
	var jb := K.bone("jaw", jrest)
	_sb = {"head": hb, "jaw": jb}
	var rings := []
	var z0 := float(BODY_KEYS[0][0])
	var z1 := float(BODY_KEYS[BODY_KEYS.size() - 1][0])
	for k: Array in BODY_KEYS:
		rings.append(SkinScript.ring(Vector3(0.0, k[1], k[0]), Vector3.RIGHT, Vector3.UP, k[2], k[3], float(k[3]) * 1.05, {torso: 1.0}, 0, 0.6 * (z0 - float(k[0])) / (z0 - z1), 0.0, 2.2))
	K.tube(SkinScript.smooth(rings, 4), 20, hb)
	var hz: Array = HEAD.z
	var rows := []
	var ws := []
	var faces := []
	var alongs := []
	for i in HEAD_NZ + 1:
		var t := float(i) / HEAD_NZ
		var z := lerpf(float(hz[0]), float(hz[hz.size() - 1]), t * t * 0.25 + t * 0.75)
		var row := []
		for k in HEAD_NA:
			row.append(hrest * _head_pt(z, TAU * float(k) / HEAD_NA))
		rows.append(row)
		ws.append({torso: 0.5, hb: 0.5} if z > 1.5 else ({torso: 0.2, hb: 0.8} if z > -0.5 else {hb: 1.0}))
		faces.append(1.0)
		alongs.append(0.75 + 0.25 * t)
	K.surface(rows, ws, faces, alongs, hb, 0, 0.8)
	K.jaw_tube(hb, jb, jrest, [[1.5, 0.4, 5.2, 1.5], [-3.5, 0.0, 5.1, 1.7], [-8.0, 0.0, 4.0, 1.55], [-10.4, 0.25, 2.9, 1.2], [-11.3, 0.45, 1.8, 0.8]])
	_skin = K
	var base := K.finish(_body, _fur)
	for k in range(1, SHELLS + 1): # (its fur: the skin again, shell on shell; the nearer, the more of them drawn)
		var sh := MeshInstance3D.new()
		sh.mesh = base.mesh
		sh.skin = base.skin
		sh.material_override = _fur
		K.skel.add_child(sh)
		sh.skeleton = sh.get_path_to(K.skel)
		sh.custom_aabb = base.custom_aabb
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sh.set_instance_shader_parameter("shell", float(k) / SHELLS)
		sh.visibility_range_end = 30.0 if k % 4 == 0 else (5.0 if k % 2 == 0 else 1.6)
		_shells.append(sh)
	var e: Vector3 = HEAD.eye
	_fur.set_shader_parameter("eye_a", Vector3(-e.x, e.y, e.z))
	_fur.set_shader_parameter("eye_b", e)
	_fur.set_shader_parameter("eye_r", float(HEAD.eye_r))
	_fur.set_shader_parameter("muzzle_z", -12.2)
	_fur.set_shader_parameter("ear_at", Vector3(5.5, 5.4, -2.8))
	# its eyes: small, black, glossy, each in its socket (a newborn's shut)
	var eye := _mat(Color(0.012, 0.01, 0.01), 0.04)
	eye.clearcoat_enabled = true
	eye.clearcoat = 1.0
	eye.clearcoat_roughness = 0.05
	var ec := e - Vector3(0.75, 0.0, -0.15) # (set in its socket, bulging a little)
	for side: float in [-1.0, 1.0]:
		_eye_mi.append(_ell(Vector3(ec.x * side, ec.y, ec.z), Vector3(2.6, 2.6, 2.6), eye, _head))
		_lid_mi.append(_ell(Vector3((ec.x + 0.15) * side, ec.y, ec.z), Vector3(2.4, 2.2, 2.6), dark, _head))
	# its nose: a bare black pad, its nostrils a round swelling each, opening forward and out, a groove between
	_ell(Vector3(0.0, 1.0, -16.5), Vector3(3.2, 2.4, 2.0), dark, _head)
	var hole := _mat(Color(0.0, 0.0, 0.0), 0.9)
	for side: float in [-1.0, 1.0]:
		_ell(Vector3(1.15 * side, 1.3, -16.85), Vector3(1.9, 1.7, 1.5), dark, _head)
		var nh := _ell(Vector3(1.55 * side, 1.3, -17.38), Vector3(0.85, 0.95, 0.5), hole, _head)
		nh.rotation = Vector3(0.0, -0.6 * side, 0.0)
	# its mouth: pink inside, its palate, its tongue; its teeth (as it's open)
	var pink := _mat(Color(0.72, 0.36, 0.38), 0.3)
	_mouth_in = _ell(Vector3(0.0, -2.0, -10.6), Vector3(7.4, 2.4, 10.6), pink, _head)
	var tooth := _mat(Color(0.93, 0.91, 0.84), 0.22)
	var up := Node3D.new()
	_head.add_child(up)
	var lo := Node3D.new()
	_jawn.add_child(lo)
	_teeth = [up, lo]
	_ell(Vector3(0.0, 1.2, -5.8), Vector3(4.6, 1.6, 9.6), _mat(Color(0.82, 0.42, 0.44), 0.22), lo) # (its tongue)
	for side: float in [-1.0, 1.0]:
		# (its upper teeth, inside its lip: two incisors, the long canine, a premolar, three sharp-cusped molars)
		_cone(Vector3(0.7 * side, -1.4, -15.9), Vector3(0.65 * side, -2.6, -16.0), 0.32, tooth, up)
		_cone(Vector3(1.3 * side, -1.6, -15.6), Vector3(1.3 * side, -2.4, -15.65), 0.24, tooth, up)
		_cone(Vector3(2.3 * side, -1.8, -14.4), Vector3(2.4 * side, -4.5, -14.8), 0.55, tooth, up)
		_cone(Vector3(2.75 * side, -2.2, -13.1), Vector3(2.75 * side, -3.2, -13.1), 0.36, tooth, up)
		for m in 3:
			var mz := -11.9 + 1.4 * m
			var mx := 2.85 + 0.35 * m
			_cone(Vector3(mx * side, -2.5, mz), Vector3((mx + 0.15) * side, -3.45 + 0.1 * m, mz - 0.25), 0.48, tooth, up)
			_cone(Vector3((mx - 0.45) * side, -2.5, mz + 0.5), Vector3((mx - 0.5) * side, -3.25 + 0.1 * m, mz + 0.5), 0.38, tooth, up)
		# (its lower: three small incisors, the canine before the upper one, two premolars, three molars)
		for k in 3:
			_cone(Vector3((0.3 + 0.42 * k) * side, 1.1, -11.2 + 0.15 * k), Vector3((0.3 + 0.42 * k) * side, 1.75, -11.3 + 0.15 * k), 0.19, tooth, lo)
		_cone(Vector3(1.75 * side, 1.1, -10.7), Vector3(1.9 * side, 3.3, -10.7), 0.45, tooth, lo)
		for k in 2:
			_cone(Vector3((2.2 + 0.3 * k) * side, 1.25, -9.6 + 0.9 * k), Vector3((2.2 + 0.3 * k) * side, 2.05 + 0.15 * k, -9.6 + 0.9 * k), 0.32, tooth, lo)
		for m in 3:
			var mz2 := -7.6 + 1.3 * m
			var mx2 := 2.75 + 0.25 * m
			_cone(Vector3(mx2 * side, 1.35, mz2), Vector3(mx2 * side, 2.25 - 0.08 * m, mz2 - 0.2), 0.44, tooth, lo)
			_cone(Vector3((mx2 - 0.3) * side, 1.35, mz2 + 0.5), Vector3((mx2 - 0.3) * side, 2.05 - 0.08 * m, mz2 + 0.5), 0.36, tooth, lo)
	# its ears: broad, rounded, thick, black, cupped forward and out; the short blunt tragus in each
	for side: float in [-1.0, 1.0]:
		var en := Node3D.new()
		en.position = Vector3(5.5 * side, 5.4, -2.8) # (on its head's side, behind and above its eye)
		_head.add_child(en)
		en.set_meta("side", side)
		var mi := MeshInstance3D.new()
		mi.mesh = _ear_mesh(side, 11.5, 4.4, 2.9, 0.45)
		mi.material_override = _ear_mat
		en.add_child(mi)
		var tr := MeshInstance3D.new()
		tr.mesh = _ear_mesh(side, 5.6, 1.2, 0.35, 0.0)
		tr.material_override = _ear_mat
		tr.position = Vector3(-1.2 * side, 0.2, -2.3)
		tr.rotation = Vector3(-0.12, 0.25 * side, 0.12 * side)
		en.add_child(tr)
		_ear_n.append(en)
	# its feet (five toes, their claws curled), its thumbs' claws: hung on its bones each frame
	for side: float in [-1.0, 1.0]:
		var f := Node3D.new()
		_body.add_child(f)
		for k in 5:
			var a := deg_to_rad(-18.0 + 9.0 * k)
			var d := Vector3(sin(a), 0.0, cos(a))
			var c1 := d * 4.6
			_cone(-d * 1.5, c1 * 1.25, 0.5, _limb, f)
			_cone(c1 * 0.95, c1 + d * 1.6 + Vector3(0.0, 1.5, 0.0), 0.42, claw, f) # (the claw: out, then hooked up)
			_cone(c1 + d * 1.3 + Vector3(0.0, 1.1, 0.0), c1 + d * 0.9 + Vector3(0.0, 3.1, 0.0), 0.3, claw, f)
		_foot_n.append(f)
		var t := Node3D.new()
		_body.add_child(t)
		_cone(Vector3(0.0, 0.0, 0.8), Vector3(0.0, 0.0, -4.6), 0.85, _limb, t)
		_cone(Vector3(0.0, 0.0, -3.8), Vector3(0.0, -1.3, -6.2), 0.5, claw, t)
		_cone(Vector3(0.0, -1.0, -5.9), Vector3(0.0, -3.0, -6.0), 0.32, claw, t)
		_thumb_n.append(t)
	# its membranes, and the bones in them: rebuilt as they move
	_mem = MeshInstance3D.new()
	_mem.material_override = _membrane
	_body.add_child(_mem)
	_mem.custom_aabb = AABB(Vector3(-220, -150, -220), Vector3(440, 300, 440))
	_bones = MeshInstance3D.new()
	_bones.material_override = _limb
	_body.add_child(_bones)
	_bones.custom_aabb = _mem.custom_aabb


## An ear (or a tragus): its base at its origin, up its y, its hollow facing
## forward (-z), `side` its outer edge's; h tall, w its half width, cupped;
## a rounded top, narrower at its base; thick, its rim rounded; lobe: its
## outer edge's base carried down and forward (toward its mouth's corner).
static func _ear_mesh(side: float, h: float, w: float, cup: float, lobe: float) -> ArrayMesh:
	var nu := 14
	var nv := 10
	var th := minf(0.5, w * 0.25)
	var P := []
	for i in nu + 1:
		var u := sin(PI * 0.5 * float(i) / nu) # (closer together round its top)
		var row := []
		var wd := w * (0.55 + 0.45 * sin(PI * 0.5 * minf(u / 0.42, 1.0))) if u < 0.42 else w * pow(maxf(cos(PI * 0.5 * (u - 0.42) / 0.58), 0.0), 0.5)
		for j in nv + 1:
			var v := float(j) / nv * 2.0 - 1.0 # (-1 its inner edge .. 1 its outer)
			var x := (v * wd * (1.12 if v > 0.0 else 0.8) + 1.6 * u * (h / 14.0)) * side # (its outer edge the fuller)
			var y := u * h
			var z := 1.3 * u * u * (h / 14.0) - cup * v * v * (1.0 - 0.55 * u) - cup * 0.35 * pow(absf(v), 5.0) # (its rim rolled forward)
			z -= cup * 1.1 * v * v * pow(maxf(1.0 - u / 0.35, 0.0), 2.0) # (a funnel at its base)
			if v > 0.0: # (its outer edge rolled forward toward its base)
				z -= cup * 0.9 * v * v * (1.0 - u) * (1.0 - u)
				var lb := lobe * smoothstep(0.35, 1.0, v) * (1.0 - smoothstep(0.0, 0.3, u))
				y -= 3.0 * lb
				z -= 2.2 * lb
			row.append(Vector3(x, y, z))
		P.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var N := []
	for i in nu + 1:
		var row := []
		for j in nv + 1:
			var du: Vector3 = (P[mini(i + 1, nu)][j] as Vector3) - (P[maxi(i - 1, 0)][j] as Vector3)
			var dv: Vector3 = (P[i][mini(j + 1, nv)] as Vector3) - (P[i][maxi(j - 1, 0)] as Vector3)
			var n := du.cross(dv) * side
			if n.length() < 1e-6:
				n = Vector3.FORWARD
			n = n.normalized()
			if n.z > 0.0:
				n = -n # (its hollow's: forward)
			row.append(n)
		N.append(row)
	for face in 2: # (its hollow; its back, the ear's thickness behind it, thinning to its rim)
		for i in nu:
			for j in nv:
				var idx := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]
				if (face == 0) != (side > 0.0):
					idx.reverse()
				for q: Array in idx:
					var pp: Vector3 = P[q[0]][q[1]]
					var nn: Vector3 = N[q[0]][q[1]]
					var vv := float(q[1]) / nv * 2.0 - 1.0
					var uu := sin(PI * 0.5 * float(q[0]) / nu)
					var edge := maxf(absf(vv), uu) # (1 at its rim)
					var t := th * sqrt(maxf(1.0 - pow(edge, 2.5), 0.0))
					st.set_uv(Vector2(vv, uu))
					st.set_color(Color(0.0, 1.0 if face == 0 else 0.0, 0.0))
					st.set_normal(nn if face == 0 else -nn)
					st.add_vertex(pp if face == 0 else pp - nn * t)
	st.index()
	return st.commit()


# --- the pose: its bones from its pose's numbers; the skin; the membranes ---------------

## Its bones, this frame (the body's mm): {"S", "E", "W", "d2", "d3j", "d3",
## "d4j", "d4", "d5j", "d5", "th", "H", "K", "A", "T", "C"} for one side
## (1 right, -1 left).
func _wing(side: float) -> Dictionary:
	var i := 0 if side < 0.0 else 1
	var s: float = spread[i]
	var rot := Basis(Vector3(0.0, 0.0, -1.0) * side, float(stroke[i])) # (raised at the shoulder: about its body's long axis)
	var d := func(k: String) -> Vector3:
		var pr: Array = DIRS[k]
		var v: Vector3 = (pr[0] as Vector3).slerp(pr[1] as Vector3, s)
		v.x *= side
		return (rot * v) if s > 0.05 else v
	var S := Vector3(SHOULDER.x * side, SHOULDER.y, SHOULDER.z)
	var E: Vector3 = S + d.call("hum") * L.hum
	var W: Vector3 = E + d.call("fore") * L.fore
	var o := {"S": S, "E": E, "W": W}
	o["d2"] = W + d.call("d2") * L.d2
	o["d3j"] = W + d.call("d3a") * L.d3a
	o["d3"] = (o["d3j"] as Vector3) + d.call("d3b") * L.d3b
	o["d4j"] = W + d.call("d4a") * L.d4a
	o["d4"] = (o["d4j"] as Vector3) + d.call("d4b") * L.d4b
	o["d5j"] = W + d.call("d5a") * L.d5a
	o["d5"] = (o["d5j"] as Vector3) + d.call("d5b") * L.d5b
	o["th"] = W + d.call("thumb") * L.thumb
	# its hind leg: hip, knee, ankle, toes; the calcar from its ankle along the tail membrane's edge
	var H := Vector3(HIP.x * side, HIP.y, HIP.z)
	var dirs := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var tw := 0.0
	for k: String in LEGS:
		var w: float = _legs_w[k]
		if w <= 0.0:
			continue
		tw += w
		for q in 3:
			var v: Vector3 = (LEGS[k] as Array)[q]
			dirs[q] += Vector3(v.x * side, v.y, v.z) * w
	for q in 3:
		dirs[q] = (dirs[q] as Vector3).normalized() if tw > 0.0 else Vector3.BACK
	if side < 0.0 and _one_foot > 0.0: # (its left foot let go: combing its fur)
		var sw := sin(_mt * 9.0)
		dirs[0] = (dirs[0] as Vector3).slerp(Vector3(-0.6, -0.5 + 0.2 * sw, -0.4).normalized(), _one_foot)
		dirs[1] = (dirs[1] as Vector3).slerp(Vector3(-0.2, -0.3, -0.93 + 0.1 * sw).normalized(), _one_foot)
	var K: Vector3 = H + (dirs[0] as Vector3) * L.femur
	var A: Vector3 = K + (dirs[1] as Vector3) * L.tibia
	o["H"] = H
	o["K"] = K
	o["A"] = A
	o["F"] = A + (dirs[2] as Vector3) * L.foot
	var tail := _tail_pts()
	var tip: Vector3 = tail[tail.size() - 1]
	o["C"] = A + ((tip - A).normalized() * 0.6 + Vector3(-side * 0.6, 0.0, 0.4).normalized() * 0.4).normalized() * L.calcar
	return o


## Its tail's joints (the body's mm): trailing back, or curled forward
## under it (_tail_curl: the pouch).
func _tail_pts() -> Array:
	var pts := [TAIL_ROOT]
	var p := TAIL_ROOT
	var a := 0.0
	var follow: float = _legs_w.hang
	for k in TAIL_N:
		a += (_tail_curl * 0.42 + 0.03) # (bent down, round under, a joint at a time)
		var dir := Vector3(0.0, -sin(a), cos(a))
		dir = dir.slerp(Vector3(0.0, 0.25, 0.97).normalized(), follow * 0.5 * (1.0 - _tail_curl)) # (hanging: along its legs)
		p += dir * TAIL_SEG
		pts.append(p)
	return pts


## Its tail pouch: the middle of its tail membrane (the body's mm).
func _pouch_body() -> Vector3:
	var t := _tail_pts()
	return ((t[3] as Vector3) + (t[5] as Vector3)) * 0.5 + Vector3(0.0, -2.0, 0.0)


func _pose_skin() -> void:
	if _skin == null:
		return
	var ht := Transform3D(Basis.from_euler(Vector3(-_head_yp.y, _head_yp.x, 0.0)), HEAD_AT + _head_off)
	_head.transform = ht
	_jawn.rotation = Vector3(-_jaw, 0.0, 0.0) # (its lower jaw dropped open)
	_skin.pose(_sb.head, ht)
	_skin.pose(_sb.jaw, ht * _jawn.transform)
	_mouth_in.visible = _jaw > 0.05
	for tn in _teeth: # (its teeth behind its lips, shut)
		tn.visible = _jaw > 0.05
	for en in _ear_n:
		var sd: float = en.get_meta("side")
		en.rotation = Vector3(-0.1 + 0.95 * _ears, -0.6 * sd + 0.12 * sd * sin(_mt * 1.3 + sd), -0.5 * sd - 0.25 * sd * _ears) # (up and out, turning; laid back)
	var lid := _eyes_shut > 0.5 or (young and size < 0.6)
	for k in _lid_mi.size():
		_lid_mi[k].visible = lid
		_eye_mi[k].visible = not lid
	_body.position = Vector3(_shiver * size * 0.001, 0.0, 0.0)
	_body.scale = Vector3.ONE * size * 0.001 * (1.0 + 0.02 * sin(_breath))


## Its membranes, the bones in them, its feet and thumbs: rebuilt (only when
## its pose has moved).
func _pose_membranes() -> void:
	var sig := PackedFloat32Array([spread[0], spread[1], stroke[0], stroke[1], _legs_w.fly, _legs_w.hang, _legs_w.crawl, _tail_curl, _one_foot * (1.0 + sin(_mt * 9.0))])
	if sig == _pose_sig:
		return
	var moved := _pose_sig.size() != sig.size()
	if not moved:
		for k in sig.size():
			if absf(sig[k] - _pose_sig[k]) > 0.002:
				moved = true
				break
	if not moved:
		return
	_pose_sig = sig
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sb := SurfaceTool.new()
	sb.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tail := _tail_pts()
	var sides := {}
	for side: float in [-1.0, 1.0]:
		var o := _wing(side)
		sides[side] = o
		var S: Vector3 = o.S
		var E: Vector3 = o.E
		var W: Vector3 = o.W
		var fold := 1.0 - float(spread[0 if side < 0.0 else 1])
		var bulge := Vector3(0.0, 0.0, -1.0) * 4.0 * (1.0 - fold)
		# propatagium: before the arm, shoulder to wrist
		_panel(st, [S, E, W], [S, S.lerp(W, 0.5) + bulge, W], 6, 3, 0.0, fold)
		# between the fingers, and from the fifth to its side and ankle
		_panel(st, [W, o.d3j, o.d3], [W, o.d4j, o.d4], 8, 6, 0.13, fold)
		_panel(st, [W, o.d4j, o.d4], [W, o.d5j, o.d5], 8, 6, 0.13, fold)
		_panel(st, [W, o.d2], [W, (o.d3j as Vector3)], 4, 2, 0.0, fold)
		_panel(st, [S, E, W, o.d5j, o.d5], [S + Vector3(0.0, -2.5, 2.0), Vector3(8.3 * side, -1.5, -4.0), Vector3(7.0 * side, -1.5, 10.0), o.K, o.A], 12, 7, 0.16, fold)
		# the tail membrane, its half: leg and calcar to the tail
		_panel(st, [o.H + Vector3(-2.0 * side, -1.0, 0.0), o.K, o.A, o.C], tail.slice(0, 4) + [tail[tail.size() - 1]], 7, 4, 0.12, _tail_curl * 0.5)
		# the bones in it, their joints
		for b: Array in [[S, E, 1.6, 1.3], [E, W, 1.25, 0.95], [W, o.d2, 0.55, 0.3], [W, o.d3j, 0.6, 0.45], [o.d3j, o.d3, 0.42, 0.18], [W, o.d4j, 0.6, 0.45],
				[o.d4j, o.d4, 0.4, 0.18], [W, o.d5j, 0.62, 0.48], [o.d5j, o.d5, 0.42, 0.2], [o.H, o.K, 1.5, 1.0], [o.K, o.A, 0.95, 0.7], [o.A, o.F, 0.95, 0.8], [o.A, o.C, 0.4, 0.15]]:
			_tube(sb, b[0], b[1], b[2], b[3])
		if side > 0.0:
			for k in TAIL_N:
				_tube(sb, tail[k], tail[k + 1], lerpf(1.0, 0.35, float(k) / TAIL_N), lerpf(1.0, 0.35, float(k + 1) / TAIL_N))
		# its foot, its thumb: their claws
		var fi := 0 if side < 0.0 else 1
		var A: Vector3 = o.A
		var fwd: Vector3 = ((o.F as Vector3) - A).normalized()
		var up := (Vector3(0.0, 1.0, 0.0) - fwd * fwd.y).normalized()
		if up.length() < 0.1:
			up = Vector3.BACK
		_foot_n[fi].transform = Transform3D(Basis(up.cross(fwd).normalized(), up, fwd), A)
		var td: Vector3 = ((o.th as Vector3) - W).normalized()
		var tup := (Vector3.UP - td * td.y).normalized()
		_thumb_n[fi].transform = Transform3D(Basis(tup.cross(-td).normalized(), tup, -td), W)
	st.index()
	st.generate_normals()
	_mem.mesh = st.commit()
	_bones.mesh = sb.commit()


## A membrane between two lines of points (resampled to nu across, nv
## between them); its far end free, its edge sagging in (sag of its span).
func _panel(st: SurfaceTool, a: Array, b: Array, nu: int, nv: int, sag: float, fold := 0.0) -> void:
	var ra := _resample(a, nu)
	var rb := _resample(b, nu)
	var rows := []
	var la := 0.0
	var span := 0.0
	for i in nu + 1:
		var row := []
		for j in nv + 1:
			var v := float(j) / nv
			var p: Vector3 = (ra[i] as Vector3).lerp(rb[i], v)
			row.append(p)
		rows.append(row)
		span += (ra[i] as Vector3).distance_to(rb[i]) / (nu + 1)
		if i > 0:
			la += ((ra[i] as Vector3).distance_to(ra[i - 1]) + (rb[i] as Vector3).distance_to(rb[i - 1])) * 0.5
	if sag > 0.0: # (its free edge scalloped: drawn in toward the bones' joint)
		var last: Array = rows[nu]
		var inward: Vector3 = ((ra[0] as Vector3) + (rb[0] as Vector3)) * 0.5
		for j in range(1, nv):
			var v := float(j) / nv
			var k := 4.0 * v * (1.0 - v)
			for i2 in range(nu, maxi(nu - 3, 0), -1):
				var fall := float(3 - (nu - i2)) / 3.0
				var q: Vector3 = rows[i2][j]
				rows[i2][j] = q.lerp(inward, sag * k * fall * fall)
		var _l := last
	# (its skin's grain: cm along it, across it; as it lay spread)
	var us := maxf(la, 20.0) * 0.1
	var vs := maxf(span, 12.0) * 0.1 * lerpf(1.0, 2.2, fold)
	var seed_ := float(nu * 7 + nv * 3) + sag * 40.0
	st.set_color(Color(fold, 0.0, 0.0))
	for i in nu:
		for j in nv:
			for e: Array in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				st.set_uv(Vector2(float(e[0]) / nu * us + seed_, float(e[1]) / nv * vs))
				st.add_vertex(rows[e[0]][e[1]])


static func _resample(pts: Array, n: int) -> Array:
	var lens := [0.0]
	for k in range(1, pts.size()):
		lens.append(float(lens[k - 1]) + (pts[k] as Vector3).distance_to(pts[k - 1]))
	var total: float = lens[lens.size() - 1]
	var out := []
	var seg := 0
	for i in n + 1:
		var t := total * float(i) / n
		while seg < pts.size() - 2 and float(lens[seg + 1]) < t:
			seg += 1
		var span := float(lens[seg + 1]) - float(lens[seg])
		var f := (t - float(lens[seg])) / span if span > 1e-5 else 0.0
		out.append((pts[seg] as Vector3).lerp(pts[seg + 1], clampf(f, 0.0, 1.0)))
	return out


## A bone under its skin, a to b (r0, r1 its radius at each), swollen at its joints.
static func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1 := -1.0) -> void:
	var d := b - a
	if d.length() < 1e-4:
		return
	if r1 < 0.0:
		r1 = r0 * 0.8
	var y := d.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var n := 8
	var prof := [[-0.02, 0.6, 1.0], [0.0, 1.3, 1.0], [0.05, 1.32, 1.0], [0.12, 1.0, 0.0], [0.88, 1.0, 0.0], [0.95, 1.32, 1.0], [1.0, 1.3, 1.0], [1.02, 0.6, 1.0]]
	for i in prof.size() - 1:
		var t0: float = prof[i][0]
		var t1: float = prof[i + 1][0]
		var ra := lerpf(r0, r1, clampf(t0, 0.0, 1.0)) * float(prof[i][1])
		var rb := lerpf(r0, r1, clampf(t1, 0.0, 1.0)) * float(prof[i + 1][1])
		for k in n:
			var a0 := TAU * k / n
			var a1 := TAU * (k + 1) / n
			var o0 := x * cos(a0) + z * sin(a0)
			var o1 := x * cos(a1) + z * sin(a1)
			for e: Array in [[t0, ra, o0, i], [t1, rb, o0, i + 1], [t1, rb, o1, i + 1], [t0, ra, o0, i], [t1, rb, o1, i + 1], [t0, ra, o1, i]]:
				st.set_uv(Vector2(float(e[0]) * d.length() * 0.1, float(prof[e[3]][2])))
				st.set_normal(e[2])
				st.add_vertex(a + d * float(e[0]) + (e[2] as Vector3) * float(e[1]))


# --- where it is ---------------------------------------------------------------------------

func _ground(x: float, z: float) -> float:
	return float(height.call(x, z)) if height.is_valid() else 0.0


func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	_yaw = yaw
	_ori = Basis(Vector3.UP, yaw)
	transform = Transform3D(_ori, _pos)


## Where it hangs (its parent's space: a point under a branch, a beam, a
## bat box's roof; its claws hooked there), its back to `face`; hung there now.
func set_roost(point: Vector3, face := Vector3.INF) -> void:
	roost_at = point
	if face != Vector3.INF:
		roost_face = Vector3(face.x, 0.0, face.z).normalized()
	if not young:
		_hang_now()


func _hang_basis() -> Basis:
	var back := roost_face if roost_face.length() > 0.1 else Vector3.BACK
	var z := Vector3.UP # (its rump up)
	var y := back # (its back facing out)
	var x := y.cross(z).normalized()
	return Basis(x, y, z)


## Hung under its roost, its body hanging below its feet.
func _hang_now() -> void:
	_mode = "hang"
	_ori = _hang_basis()
	_legs_w = {"fly": 0.0, "hang": 1.0, "crawl": 0.0}
	spread = [0.0, 0.0]
	stroke = [0.0, 0.0]
	_vel = Vector3.ZERO
	var feet := _feet_body()
	_pos = roost_at - _ori * (feet * size * 0.001)
	_to("hang")


## Its feet's grip, the body's mm (hanging).
func _feet_body() -> Vector3:
	var o := _wing(1.0)
	var p: Vector3 = o.F
	return Vector3(0.0, p.y, p.z)


func _mouth_world() -> Vector3:
	return _body.global_transform * (_head.transform * MOUTH)


func _pouch_world() -> Vector3:
	return _body.global_transform * _pouch_body()


# --- its ways ----------------------------------------------------------------------------

func _to(mode: String, sub := "") -> void:
	_mode = mode
	_sub = sub
	_st = 0.0
	_mt = 0.0 if mode != "hang" else _mt
	_secs = -1.0
	_one_foot = 0.0
	_eyes_shut = 0.0


func is_flying() -> bool:
	return _mode in ["fly", "forage", "hunt", "drink", "land", "drop"]


## Out foraging: off its roost (or up off the ground), beating round its
## patch, hawking what it finds.
func forage(secs := 60.0) -> void:
	if young or dead:
		return
	_patch = _pos if roost_at == Vector3.INF else roost_at
	_patch.y = _ground(_patch.x, _patch.z)
	_fly_to = Vector3.INF
	_go("forage")
	_secs = secs


## (Into the air for `mode`: off its roost (a drop) or the ground (a
## spring) first, if it's not flying.)
func _go(mode: String, sub := "") -> void:
	if is_flying():
		_mode = mode
		_sub = sub
		_st = 0.0
		return
	_then = mode
	_then_sub = sub
	_take_off()


func wander(_c := Vector3.INF, _r := -1.0) -> void:
	_piloted = false
	if is_flying():
		return
	if roost_at != Vector3.INF:
		_back_to_roost()


func _take_off() -> void:
	if _mode in ["hang", "groom", "sleep", "cling", "alarm", "nurse"] and roost_at != Vector3.INF:
		_to("drop") # (letting go: a drop, its wings opening)
		_vel = Vector3(0.0, -1.0, 0.0) + roost_face * 0.6
	elif not is_flying():
		_to("drop")
		_vel = _ori * Vector3(0.0, 0.0, -1.5) + Vector3(0.0, 2.2, 0.0) # (a spring off the ground)
	_legs_w = {"fly": 1.0, "hang": 0.0, "crawl": 0.0}


## Its prey (a flying insect, a beetle: Diet), run down.
func hunt(prey: Node3D) -> void:
	if young or dead or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	prey.set_meta("hunted", self)
	_go("hunt", "chase")


## Drinking at `at` (its parent's space: on the water's surface): skimming
## low over it, its lower jaw dipped in.
func drink(at: Vector3) -> void:
	if young or dead:
		return
	_drink_at = at
	_go("drink", "in")


func sleep(secs := 30.0) -> void:
	if young or dead:
		return
	if is_flying():
		_back_to_roost()
		return
	_to("sleep")
	_secs = secs


func groom(secs := 10.0) -> void:
	if young or dead or is_flying():
		return
	_to("groom")
	_secs = secs


func alarm(secs := 3.0) -> void:
	if young or dead:
		return
	if is_flying():
		_flee()
		return
	_to("alarm")
	_secs = secs


func _flee() -> void:
	var a := _rng.randf() * TAU
	_patch = _pos + Vector3(cos(a), 0.0, sin(a)) * 15.0
	_patch.y = _ground(_patch.x, _patch.z)
	_fly_to = Vector3.INF
	_go("forage")
	_secs = 20.0


func roost() -> void:
	_back_to_roost()


func _back_to_roost() -> void:
	if roost_at == Vector3.INF or dead:
		return
	if not is_flying():
		_hang_now()
		return
	_mode = "land"
	_sub = "in"
	_st = 0.0


## (A male's.) To her at her roost, on her back. False if they can't.
func mate(her: Node3D, secs := 12.0) -> bool:
	if not male or young or juvenile or dead or her == null or not is_instance_valid(her) or her == self:
		return false
	if her.get("male") or her.get("young") or her.get("dead") or her.get("gravid"):
		return false
	_partner = her
	her.set("_partner", self)
	_secs = secs
	if is_flying() or _pos.distance_to(her.get("_pos")) > 0.3:
		_go("fly", "to_mate")
	else:
		_to("mount")
		_secs = secs
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and _mode in ["mount"]


## (A female's, gravid.) Turned head up, her pups born into her tail
## membrane one by one, licked, crawling up to her nipple.
func birth(n := 2) -> void:
	if male or young or dead:
		return
	if is_flying():
		_back_to_roost()
	_to("birth", "turn")
	_secs = float(n)


func nurse(secs := 20.0) -> void:
	if young or dead or pups.is_empty():
		return
	if is_flying():
		_back_to_roost()
		return
	_to("nurse")
	_secs = secs


func die() -> void:
	if dead:
		return
	dead = true
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_to("dead", "fall" if not _on_ground() else "")


func _on_ground() -> bool:
	return _pos.y <= _ground(_pos.x, _pos.z) + 0.03


# --- each frame ---------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	dt = minf(dt, 0.05)
	_st += dt
	_mt += dt
	_breath += dt * (TAU * (0.6 if _mode in ["sleep"] else 2.5))
	if _pilot:
		_pilot.tick(dt)
	if young:
		_grow(dt)
	if not dead:
		hunger = minf(hunger + dt / 300.0, 1.0)
	match _mode:
		"hang":
			_hang(dt)
		"sleep":
			_sleep(dt)
		"groom":
			_groom(dt)
		"alarm":
			_alarm(dt)
		"crawl":
			_crawl(dt)
		"drop", "fly", "forage", "hunt", "drink", "land":
			_fly(dt)
		"glean":
			_glean(dt)
		"mount":
			_mount(dt)
		"courted":
			_hang(dt)
		"birth":
			_birth(dt)
		"nurse":
			_nurse(dt)
		"cling":
			_cling(dt)
		"dead":
			_dead(dt)
	_hold()
	transform = Transform3D(_ori.orthonormalized(), _pos)
	_pose_skin()
	_pose_membranes()
	for p in pups:
		if is_instance_valid(p) and p.get("_mode") == "cling" and p.get("_mother") == self:
			p.call("_ride", self)


func _ease(cur: float, to: float, rate: float, dt: float) -> float:
	return lerpf(cur, to, 1.0 - exp(-rate * dt))


func _fold(dt: float, rate := 6.0) -> void:
	for i in 2:
		spread[i] = _ease(spread[i], 0.0, rate, dt)
		stroke[i] = _ease(stroke[i], 0.0, rate, dt)


func _legs_to(k: String, dt: float, rate := 5.0) -> void:
	for n: String in _legs_w:
		_legs_w[n] = _ease(_legs_w[n], 1.0 if n == k else 0.0, rate, dt)


# hanging: looking about, its ears turning; now and then a yawn, a wing
# stretched, a call; at dusk (or night) away to forage
func _hang(dt: float) -> void:
	_fold(dt)
	_legs_to("hang", dt)
	_tail_curl = _ease(_tail_curl, 0.0, 4.0, dt)
	if roost_at != Vector3.INF:
		_ori = _ori.slerp(_hang_basis(), 1.0 - exp(-6.0 * dt))
		_pos = _pos.lerp(roost_at - _ori * (_feet_body() * size * 0.001), 1.0 - exp(-10.0 * dt))
	var look := floorf(_mt / 2.2)
	_head_yp = _head_yp.lerp(Vector2(0.5 * sin(look * 2.1), -0.3 + 0.25 * sin(look * 1.3)), 1.0 - exp(-4.0 * dt)) # (looking about, its head lifted a little from its breast)
	_head_off = _head_off.lerp(Vector3.ZERO, 1.0 - exp(-4.0 * dt))
	_ears = _ease(_ears, 0.0, 3.0, dt)
	var yawn := fmod(_mt, 23.0)
	_jaw = _ease(_jaw, 0.7 if yawn > 21.5 else 0.0, 8.0, dt)
	if fmod(_mt, 31.0) > 29.0: # (a wing stretched out, and folded again)
		var i := int(_mt / 31.0) % 2
		spread[i] = _ease(spread[i], 0.75, 4.0, dt)
	if _piloted or young or dead or _mode != "hang":
		return
	if _st > 5.0:
		_st = 0.0
		var night: float = OakTree._night
		var r := _rng.randf()
		if night > 0.4 and r < 0.4 + 0.3 * hunger:
			forage(_rng.randf_range(40.0, 90.0))
		elif not pups.is_empty() and r < 0.6:
			nurse(_rng.randf_range(10.0, 20.0))
		elif r < 0.2:
			groom(_rng.randf_range(6.0, 12.0))
		elif night < 0.2 and r < 0.35:
			sleep(_rng.randf_range(20.0, 40.0))


func _sleep(dt: float) -> void:
	# torpor: still, its wings wrapped close, eyes shut, breathing slow, its ears laid back
	_fold(dt, 3.0)
	_legs_to("hang", dt)
	if roost_at != Vector3.INF:
		_ori = _ori.slerp(_hang_basis(), 1.0 - exp(-6.0 * dt))
		_pos = _pos.lerp(roost_at - _ori * (_feet_body() * size * 0.001), 1.0 - exp(-10.0 * dt))
	_head_yp = _head_yp.lerp(Vector2(0.0, 0.25), 1.0 - exp(-2.0 * dt)) # (its head tucked toward its breast)
	_ears = _ease(_ears, 0.8, 2.0, dt)
	_eyes_shut = 1.0
	_jaw = _ease(_jaw, 0.0, 6.0, dt)
	if _secs > 0.0 and _st > _secs:
		_to("hang")


func _groom(dt: float) -> void:
	# hanging by its right foot, its left combing its fur; its head round to
	# lick its left wing, held out
	_legs_to("hang", dt)
	if roost_at != Vector3.INF:
		_pos = _pos.lerp(roost_at - _ori * (_feet_body() * size * 0.001), 1.0 - exp(-10.0 * dt))
	var ph := fmod(_st, 8.0)
	if ph < 4.0:
		_one_foot = _ease(_one_foot, 1.0, 5.0, dt)
		_head_yp = _head_yp.lerp(Vector2(-0.3, 0.1), 1.0 - exp(-4.0 * dt))
		_fold(dt)
	else:
		_one_foot = _ease(_one_foot, 0.0, 5.0, dt)
		spread[0] = _ease(spread[0], 0.45, 4.0, dt)
		_head_yp = _head_yp.lerp(Vector2(-1.1, 0.3), 1.0 - exp(-4.0 * dt)) # (round to its wing)
		_jaw = 0.12 + 0.1 * sin(_mt * 16.0) # (licking)
	if _secs > 0.0 and _st > _secs:
		_jaw = 0.0
		_to("hang")


func _alarm(dt: float) -> void:
	# mouth wide, teeth bared, buzzing, wings half out; then off
	if roost_at == Vector3.INF or not _legs_w.hang > 0.5: # (on the ground: propped on its wrists, as crawling)
		_legs_to("crawl", dt)
		var gy := _ground(_pos.x, _pos.z)
		_pos.y = _ease(_pos.y, gy + 0.02 * size, 8.0, dt)
		_ori = _ori.slerp(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, 0.25), 1.0 - exp(-6.0 * dt))
		for i in 2:
			stroke[i] = _ease(stroke[i], -0.5, 8.0, dt)
	_jaw = _ease(_jaw, 0.85, 12.0, dt)
	_head_yp = _head_yp.lerp(Vector2(0.0, -0.4), 1.0 - exp(-8.0 * dt))
	_ears = 0.0
	for i in 2:
		spread[i] = _ease(spread[i], 0.35 + 0.05 * sin(_mt * 40.0), 10.0, dt)
	_shiver = 0.4 * sin(_mt * 50.0) # (shivering)
	if _st > _secs:
		_jaw = 0.0
		_shiver = 0.0
		if roost_at != Vector3.INF and _rng.randf() < 0.6:
			_flee()
		else:
			_to("hang" if roost_at != Vector3.INF else "crawl")


func _crawl(dt: float) -> void:
	# on the ground: low, propped on its wrists (the folded wings its forelegs) and feet; shuffling a little
	for i in 2:
		spread[i] = _ease(spread[i], 0.2, 6.0, dt)
	_legs_to("crawl", dt)
	var gy := _ground(_pos.x, _pos.z)
	_pos.y = _ease(_pos.y, gy + 0.02 * size, 8.0, dt)
	var want := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, 0.15) # (its front end up on its wrists)
	_ori = _ori.slerp(want, 1.0 - exp(-6.0 * dt))
	_head_yp = _head_yp.lerp(Vector2(0.4 * sin(_mt * 0.7), -0.2), 1.0 - exp(-3.0 * dt))
	var step := sin(_mt * 6.0)
	stroke[0] = -0.55 + 0.15 * maxf(step, 0.0) # (pressed down on its wrists, each lifted and set down in turn)
	stroke[1] = -0.55 + 0.15 * maxf(-step, 0.0)
	if not _piloted and not young and not dead and _st > 4.0:
		_st = 0.0
		if _rng.randf() < 0.5:
			forage(40.0)
		else:
			_yaw += _rng.randf_range(-1.0, 1.0)
	if _st < 4.0:
		_pos += _ori * Vector3(0.0, 0.0, -0.03) * dt


# --- flight ---------------------------------------------------------------------------------

func _fly(dt: float) -> void:
	var gy := _ground(_pos.x, _pos.z)
	var cruise := 5.0
	var aim := _pos + (_vel if _vel.length() > 0.1 else _ori * Vector3.FORWARD) # (onward)
	var hz := 9.0
	var amp := 1.05
	var calls := 8.0 # (calls a second)
	_legs_to("fly", dt, 8.0)
	match _mode:
		"drop": # (falling from its roost, wings opening, then away)
			_vel.y -= 9.8 * dt
			hz = 7.0
			amp = 0.6 * clampf(_st / 0.3, 0.0, 1.0)
			aim = _pos + Vector3(_vel.x, 0.0, _vel.z).normalized() * 2.0 + Vector3(0.0, -0.5, 0.0)
			if _st > 0.35:
				_mode = _then
				_sub = _then_sub
				_st = 0.0
		"forage": # (beats round its patch, high and low, jinking)
			if _fly_to == Vector3.INF or _pos.distance_to(_fly_to) < 1.2:
				var a := _rng.randf() * TAU
				var r := _rng.randf_range(3.0, 9.0)
				_fly_to = _patch + Vector3(cos(a) * r, _rng.randf_range(2.0, 6.0), sin(a) * r)
			aim = _fly_to + Vector3(sin(_mt * 3.1), 0.5 * sin(_mt * 2.3), cos(_mt * 2.7)) * 0.8
			if not _piloted and hunger > 0.15 and fmod(_mt, 1.0) < dt: # (what it eats, near: gone after)
				var f := Diet.find_one(self, 12.0, Diet.prey_of(self))
				if f and f != self:
					hunt(f)
					return
			if _secs > 0.0 and _mt > _secs and not _piloted:
				_back_to_roost()
		"hunt":
			_hunt(dt)
			if _mode != "hunt":
				return
			aim = _hunt_aim
			cruise = _hunt_speed
			calls = _hunt_calls
		"drink":
			if _drink_at == Vector3.INF:
				_mode = "forage"
				return
			var to := _drink_at - _pos
			var hd := Vector2(to.x, to.z).length()
			match _sub:
				"in": # (down to the water's surface, a run at it)
					aim = _drink_at + Vector3(0.0, 0.03, 0.0) - Vector3(to.x, 0.0, to.z).normalized() * clampf(hd - 0.6, 0.0, 3.0)
					cruise = 3.0
					amp = 0.6 # (shallow beats, low over the water)
					if hd < 0.25:
						_sub = "dip"
						_st = 0.0
				"dip": # (gliding just over it, its head down, its lower jaw in)
					var mw: Vector3 = get_parent().to_local(_mouth_world()) if get_parent() else _mouth_world()
					aim = Vector3(_pos.x, _pos.y + (_drink_at.y - 0.004 - mw.y) * 4.0, _pos.z) + Vector3(_vel.x, 0.0, _vel.z).normalized() * 1.0 # (held so its mouth is just under the surface)
					cruise = 2.0
					amp = 0.25
					_head_yp = _head_yp.lerp(Vector2(0.0, 0.8), 1.0 - exp(-12.0 * dt))
					_jaw = 0.45
					if _mouth_world().y <= _drink_at.y + 0.002:
						_drank += dt
					if _st > 0.7:
						_sub = "up"
						_st = 0.0
						_jaw = 0.0
				"up":
					aim = _pos + Vector3(_vel.x, 0.0, _vel.z).normalized() * 3.0 + Vector3(0.0, 2.0, 0.0)
					if _st > 1.0:
						_drink_at = Vector3.INF
						_mode = "forage"
		"land": # (back under its roost: up to it from below, flipping over at the last)
			var to := roost_at - _pos
			match _sub:
				"in":
					aim = roost_at + Vector3(0.0, -0.35, 0.0) + roost_face * 0.5
					cruise = clampf(to.length(), 1.5, 5.0)
					if to.length() < 0.7:
						_sub = "flip"
						_st = 0.0
				"flip":
					var k := clampf(_st / 0.35, 0.0, 1.0)
					_pos = _pos.lerp(roost_at - _hang_basis() * (_feet_body() * size * 0.001), 1.0 - exp(-12.0 * dt))
					_ori = _ori.slerp(_hang_basis(), k)
					_legs_to("hang", dt, 14.0)
					spread[0] = 1.0 - k
					spread[1] = 1.0 - k
					stroke[0] = 0.6 * (1.0 - k)
					stroke[1] = 0.6 * (1.0 - k)
					_phase += TAU * 6.0 * dt
					if k >= 1.0:
						_vel = Vector3.ZERO
						if _partner != null and is_instance_valid(_partner) and _sub == "flip" and male and _partner.get("_partner") == self:
							_to("mount")
							_secs = 12.0
						else:
							_hang_now()
					return
		"fly":
			if _sub == "to_mate" and _partner != null and is_instance_valid(_partner):
				var her: Vector3 = _partner.get("_pos")
				aim = her + Vector3(0.0, -0.3, 0.0)
				if _pos.distance_to(her) < 0.6:
					roost_at = _partner.get("roost_at")
					roost_face = _partner.get("roost_face")
					_mode = "land"
					_sub = "flip"
					_st = 0.0
					return
			elif _fly_to != Vector3.INF:
				aim = _fly_to
				if _pos.distance_to(_fly_to) < 0.5:
					_fly_to = Vector3.INF
					_mode = "forage"
	# steering: toward its aim, quick to turn, its speed its own
	if _mode != "drop":
		var want_v := (aim - _pos).normalized() * cruise
		_vel = _vel.move_toward(want_v, (9.0 + cruise) * dt)
	if _pos.y < gy + 0.25 and _mode not in ["drink", "drop"] and not (_mode == "hunt" and _sub in ["glean_in"]):
		_vel.y = maxf(_vel.y, 1.5)
	_pos += _vel * dt
	_pos.y = maxf(_pos.y, gy + 0.01)
	# its body along its flight, banked into its turns, pitching with its beats
	var hs := Vector2(_vel.x, _vel.z).length()
	if hs > 0.2:
		var fwd := _vel.normalized()
		var side_acc := (_vel - _vel_prev) / dt
		_vel_prev = _vel
		var right := fwd.cross(Vector3.UP).normalized()
		var bank := clampf(side_acc.dot(right) / 9.8, -1.1, 1.1)
		var up := Vector3.UP.rotated(fwd, -bank)
		var z := -fwd
		var x := up.cross(z).normalized()
		var y := z.cross(x)
		_ori = _ori.slerp(Basis(x, y, z) * Basis(Vector3.RIGHT, 0.08 * sin(_phase)), 1.0 - exp(-10.0 * dt))
		_yaw = atan2(-fwd.x, -fwd.z)
	# the wingbeat: down, and up again folding partway
	_phase += TAU * hz * dt
	var c := cos(_phase)
	var up_s := maxf(0.0, -sin(_phase)) # (on the upstroke)
	for i in 2:
		stroke[i] = amp * c * (0.55 + 0.45 * clampf(spread[i], 0.0, 1.0)) - 0.15
		spread[i] = _ease(spread[i], 1.0 - 0.45 * up_s, 18.0, dt)
	if _mode not in ["hunt"]:
		_tail_curl = _ease(_tail_curl, 0.0, 6.0, dt)
	# calling as it goes: its mouth open on each call
	_call_t += calls * dt
	if _mode != "drink" or _sub != "dip":
		_jaw = 0.35 if fmod(_call_t, 1.0) < 0.35 else _ease(_jaw, 0.0, 30.0, dt)
		if _mode != "hunt":
			_head_yp = _head_yp.lerp(Vector2(0.15 * sin(_mt * 1.7), 0.0), 1.0 - exp(-4.0 * dt))
	_ears = 0.0
	_head_off = _head_off.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * dt)) if _mode != "hunt" else _head_off


var _vel_prev := Vector3.ZERO
var _shiver := 0.0
var _drank := 0.0
var _hunt_aim := Vector3.ZERO
var _hunt_speed := 5.0
var _hunt_calls := 10.0


func _prey_at() -> Vector3:
	if _prey == null or not is_instance_valid(_prey):
		return _pos
	if _prey is Node3D and (_prey as Node3D).is_inside_tree():
		return get_parent().to_local((_prey as Node3D).global_position) if get_parent() else (_prey as Node3D).global_position
	return Diet._at(_prey)


# hunting: closing on it, calling faster (the buzz); one in the air scooped
# into its tail membrane, curled forward, its mouth then down into the
# pouch for it; one on the ground gleaned, its mouth to it
func _hunt(dt: float) -> void:
	if _held == null and (_prey == null or not is_instance_valid(_prey)):
		_prey = null
		_mode = "forage"
		_tail_curl = 0.0
		return
	var pp := _prey_at() if _prey and is_instance_valid(_prey) else _pos
	var gy := _ground(pp.x, pp.z)
	var on_ground := pp.y < gy + 0.12
	var to := pp - _pos
	match _sub:
		"chase":
			_hunt_speed = clampf(to.length() * 2.5, 2.2, 6.0)
			_hunt_calls = 10.0 if to.length() > 2.0 else 40.0 # (the feeding buzz)
			if on_ground:
				_hunt_aim = pp + Vector3(0.0, 0.5, 0.0) - Vector3(to.x, 0.0, to.z).normalized() * 0.3
				if Vector2(to.x, to.z).length() < 0.4:
					_sub = "glean_in"
					_st = 0.0
			else:
				_hunt_aim = pp + Vector3(0.0, 0.03, 0.0)
				_tail_curl = _ease(_tail_curl, clampf(1.0 - to.length() / 0.8, 0.0, 1.0), 10.0, dt) # (its tail membrane curled forward: a pouch)
				var pouch := _pouch_world()
				var pw: Vector3 = (_prey as Node3D).global_position
				var near := _seg_dist(pw, _last_pouch if _last_pouch != Vector3.INF else pouch, pouch)
				_last_pouch = pouch
				if near < 0.015 * maxf(size, 0.6): # (in the pouch)
					_take(_prey, "pouch")
					_sub = "pouch"
					_st = 0.0
			if _st > 15.0:
				_lose()
		"glean_in": # (down onto it, a hover, its mouth to it)
			_hunt_speed = 1.5
			_hunt_calls = 40.0
			_hunt_aim = pp + Vector3(0.0, 0.06, 0.0) - Vector3(to.x, 0.0, to.z).normalized() * 0.05
			_head_yp = _head_yp.lerp(Vector2(0.0, 1.0), 1.0 - exp(-10.0 * dt))
			var mw := _mouth_world()
			var pw: Vector3 = (_prey as Node3D).global_position + Vector3(0.0, Thrush._mid_y(_prey), 0.0)
			if mw.distance_to(pw) < 0.012 * maxf(size, 0.6):
				_take(_prey, "mouth")
				_sub = "chew"
				_st = 0.0
			elif to.length() < 0.15 and _st > 1.0:
				_sub = "land_glean"
				_st = 0.0
			elif _st > 4.0:
				_lose()
		"land_glean": # (down on the ground beside it, its mouth to it)
			_mode = "glean"
			_sub = "to"
			_st = 0.0
		"pouch": # (its head down into its curled tail membrane, the insect taken in its mouth)
			_hunt_speed = 4.0
			_hunt_calls = 0.0
			_hunt_aim = _pos + Vector3(_vel.x, 0.0, _vel.z).normalized() * 3.0 + Vector3(0.0, 0.3, 0.0)
			_tail_curl = 1.0
			_reach_mouth_to(_pouch_body(), dt)
			if _held and _mouth_world().distance_to(_pouch_world()) < 0.012 * maxf(size, 0.6):
				_held_in = "mouth"
				_sub = "chew"
				_st = 0.0
			elif _st > 1.5: # (it couldn't: dropped)
				_drop_held()
				_sub = "chase"
				_mode = "forage"
		"chew": # (chewing on the wing, the bits falling; swallowed)
			_hunt_speed = 4.0
			_hunt_calls = 0.0
			_hunt_aim = _pos + Vector3(_vel.x, 0.0, _vel.z).normalized() * 3.0
			_tail_curl = _ease(_tail_curl, 0.0, 6.0, dt)
			_head_off = _head_off.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * dt))
			_head_yp = _head_yp.lerp(Vector2(0.0, 0.0), 1.0 - exp(-6.0 * dt))
			_jaw = 0.25 * maxf(0.0, sin(_st * 22.0))
			if _st > 1.6:
				if _held and is_instance_valid(_held):
					_held.queue_free()
				_held = null
				_jaw = 0.0
				hunger = maxf(0.0, hunger - 0.25)
				_prey = null
				_mode = "forage"


func _lose() -> void:
	if _prey and is_instance_valid(_prey):
		_prey.remove_meta("hunted")
	_prey = null
	_tail_curl = 0.0
	_mode = "forage"


## (The head brought down to `p` (the body's mm): its neck bent, its head
## pitched; its mouth there.)
func _reach_mouth_to(p: Vector3, dt: float) -> void:
	var piv := HEAD_AT
	var want_dir := (p - piv)
	var pitch := clampf(atan2(-want_dir.y, -want_dir.z) - atan2(-MOUTH.y, -MOUTH.z), -0.6, 2.4)
	_head_yp = _head_yp.lerp(Vector2(0.0, pitch), 1.0 - exp(-14.0 * dt))
	var ht := Transform3D(Basis.from_euler(Vector3(-_head_yp.y, _head_yp.x, 0.0)), HEAD_AT)
	var off := p - ht * MOUTH
	_head_off = _head_off.lerp(off.limit_length(60.0), 1.0 - exp(-14.0 * dt)) # (its body curled: its head down to it)


func _take(prey: Node3D, where: String) -> void:
	MealScript.subdue(prey)
	_held = prey
	_held_in = where
	_prey = null


func _drop_held() -> void:
	if _held and is_instance_valid(_held):
		_held.remove_meta("hunted")
		if _held.has_method("set_process"):
			_held.set_process(true)
	_held = null


## (What it's caught: in its pouch, or its mouth.)
func _hold() -> void:
	if _held == null or not is_instance_valid(_held):
		_held = null
		return
	_held.global_position = _pouch_world() if _held_in == "pouch" else _mouth_world()


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# gleaning: down on the ground by it, crawling to it, its mouth to it
func _glean(dt: float) -> void:
	_fold(dt, 10.0)
	_legs_to("crawl", dt, 10.0)
	var gy := _ground(_pos.x, _pos.z)
	_pos.y = _ease(_pos.y, gy + 0.012 * size, 12.0, dt)
	if _prey == null or not is_instance_valid(_prey):
		if _held == null:
			_go("forage")
		elif _st > 1.6:
			_held.queue_free()
			_held = null
			hunger = maxf(0.0, hunger - 0.25)
			_go("forage")
		else:
			_jaw = 0.25 * maxf(0.0, sin(_st * 22.0))
		return
	var pp := _prey_at()
	var to := Vector3(pp.x - _pos.x, 0.0, pp.z - _pos.z)
	_yaw = atan2(-to.x, -to.z)
	_ori = _ori.slerp(Basis(Vector3.UP, _yaw), 1.0 - exp(-10.0 * dt))
	var mw := _mouth_world()
	var pw: Vector3 = (_prey as Node3D).global_position + Vector3(0.0, Thrush._mid_y(_prey), 0.0)
	if to.length() > 0.035 * size:
		_pos += to.normalized() * minf(0.06 * dt, to.length() - 0.035 * size)
	_reach_mouth_to(_body.global_transform.affine_inverse() * pw, dt)
	_jaw = 0.4
	if mw.distance_to(pw) < 0.01 * maxf(size, 0.6):
		_take(_prey, "mouth")
		_st = 0.0
		_jaw = 0.0
	elif _st > 6.0:
		_lose()
		_go("forage")


# --- mating, birth, the young -----------------------------------------------------------------

func _mount(dt: float) -> void:
	# on her back from behind, his teeth in her nape, his wings round her
	var her := _partner
	if her == null or not is_instance_valid(her):
		_to("hang")
		return
	her.set("_mode", "courted")
	var hb: Basis = her.get("_ori")
	var hp: Vector3 = her.get("_pos")
	_ori = _ori.slerp(hb, 1.0 - exp(-8.0 * dt))
	_pos = _pos.lerp(hp + hb * (Vector3(0.0, 13.0, 6.0) * 0.001 * size), 1.0 - exp(-8.0 * dt)) # (over her back)
	_legs_to("hang", dt)
	for i in 2:
		spread[i] = _ease(spread[i], 0.3, 4.0, dt)
		stroke[i] = _ease(stroke[i], -0.5, 4.0, dt) # (wrapped round her)
	_head_yp = _head_yp.lerp(Vector2(0.0, 0.5), 1.0 - exp(-5.0 * dt)) # (down to her nape)
	_jaw = 0.25
	_head_off = Vector3(0.0, -4.0 + 1.5 * sin(_mt * 6.0), 0.0)
	if _st > _secs:
		her.set("gravid", true)
		her.set("_partner", null)
		her.call("_to", "hang")
		_partner = null
		_jaw = 0.0
		_head_off = Vector3.ZERO
		_to("hang")
		if roost_at != Vector3.INF: # (off her, hung beside her)
			roost_at += Vector3(0.05, 0.0, 0.0)
			_hang_now()


func _birth(dt: float) -> void:
	# head up, hanging by her thumbs; her tail membrane cupped; a pup into it,
	# licked, crawling up to her nipple; then head down again
	var up_b := _hang_basis() * Basis(Vector3.RIGHT, PI) # (head up)
	match _sub:
		"turn":
			_ori = _ori.slerp(up_b, 1.0 - exp(-3.0 * dt))
			_tail_curl = _ease(_tail_curl, 0.9, 3.0, dt)
			_legs_to("crawl", dt)
			if _st > 2.0:
				_sub = "born"
				_st = 0.0
		"born":
			_tail_curl = 0.9
			if _st > 2.0 and _secs > 0.0:
				_secs -= 1.0
				_st = 0.0
				var p: Bat = (get_script() as GDScript).new(true)
				p.height = height
				p.male = _rng.randf() < 0.5
				get_parent().add_child(p)
				p.set("_mother", self)
				p.call("place", _pouch_world(), _yaw)
				pups.append(p)
				_head_yp = Vector2(0.0, 1.2) # (licking it)
			_reach_mouth_to(_pouch_body() + Vector3(0.0, 4.0, 0.0), dt)
			_jaw = 0.1 + 0.1 * sin(_mt * 14.0)
			if _secs <= 0.0 and _st > 3.0:
				_sub = "back"
				_st = 0.0
				gravid = false
		"back":
			_ori = _ori.slerp(_hang_basis(), 1.0 - exp(-3.0 * dt))
			_tail_curl = _ease(_tail_curl, 0.0, 3.0, dt)
			_head_off = _head_off.lerp(Vector3.ZERO, 1.0 - exp(-4.0 * dt))
			_jaw = 0.0
			if _st > 2.0:
				_hang_now()
	if roost_at != Vector3.INF and _sub != "back":
		_pos = _pos.lerp(roost_at - _ori * (Vector3(0.0, -10.0, -40.0) * size * 0.001), 1.0 - exp(-5.0 * dt)) # (from her thumbs)


func _nurse(dt: float) -> void:
	# her pups at her breast, a wing wrapped round them; licking them
	_hang(dt)
	_mode = "nurse"
	for i in 2:
		spread[i] = _ease(spread[i], 0.25, 3.0, dt)
		stroke[i] = _ease(stroke[i], -0.45, 3.0, dt)
	_head_yp = _head_yp.lerp(Vector2(0.0, 0.7), 1.0 - exp(-3.0 * dt))
	for p in pups:
		if is_instance_valid(p) and p.get("young"):
			p.set("_mode", "cling")
			p.set("_age", float(p.get("_age")) + dt * 0.6) # (her milk: they grow the faster)
	if _st > _secs:
		_to("hang")


## (A pup's.) Its place on her: at her breast, her nipple in its mouth; or,
## while she's out, left hanging at the roost.
func _ride(mom: Node3D) -> void:
	var mb: Basis = mom.get("_ori")
	var mp: Vector3 = mom.get("_pos")
	var k := pups_index_of(mom)
	_ori = mb * Basis(Vector3.UP, PI) # (facing her, belly to belly)
	_pos = mp + mb * (Vector3(5.0 * (1.0 if k == 0 else -1.0), -10.0, -7.0) * 0.001)
	transform = Transform3D(_ori.orthonormalized(), _pos)


func pups_index_of(mom: Node3D) -> int:
	var ps: Array = mom.get("pups")
	return maxi(ps.find(self), 0)


func _cling(dt: float) -> void:
	# a pup: at her breast while she's here; left hanging while she's out
	_fold(dt)
	_head_yp = _head_yp.lerp(Vector2(0.0, -0.3), 1.0 - exp(-3.0 * dt))
	var mom := _mother
	if mom == null or not is_instance_valid(mom) or mom.get("dead"):
		_mother = null
		_legs_to("hang", dt)
		if roost_at == Vector3.INF:
			roost_at = _pos + _ori * (_feet_body() * size * 0.001)
		_pos = _pos.lerp(roost_at - _hang_basis() * (_feet_body() * size * 0.001), 1.0 - exp(-6.0 * dt))
		_ori = _ori.slerp(_hang_basis(), 1.0 - exp(-6.0 * dt))
		return
	if mom.call("is_flying"): # (left behind, hanging at the roost)
		_legs_to("hang", dt)
		if roost_at == Vector3.INF:
			var mr: Vector3 = mom.get("roost_at")
			roost_at = mr + Vector3(0.04 * (pups_index_of(mom) + 1), 0.0, 0.0) if mr != Vector3.INF else _pos
			roost_face = mom.get("roost_face")
		_pos = _pos.lerp(roost_at - _hang_basis() * (_feet_body() * size * 0.001), 1.0 - exp(-6.0 * dt))
		_ori = _ori.slerp(_hang_basis(), 1.0 - exp(-6.0 * dt))
		if size > 0.75 and fmod(_mt, 6.0) < 1.2: # (exercising its wings where it hangs)
			_phase += TAU * 8.0 * dt
			for i in 2:
				spread[i] = 0.8
				stroke[i] = 0.6 * cos(_phase)
		return
	roost_at = Vector3.INF
	_legs_to("hang", dt)
	_jaw = 0.1 # (her nipple in its mouth)


func _grow(dt: float) -> void:
	_age += dt
	var g := clampf(_age / grow_secs, 0.0, 1.0)
	size = lerpf(0.42, 1.0, g)
	_apply_size()
	if g >= 1.0 and young: # (grown: flying, a juvenile)
		young = false
		juvenile = true
		if _mother and is_instance_valid(_mother):
			(_mother.get("pups") as Array).erase(self)
		_mother = null
		forage(40.0)


func _dead(dt: float) -> void:
	_jaw = _ease(_jaw, 0.3, 3.0, dt)
	_eyes_shut = 1.0
	var gy := _ground(_pos.x, _pos.z)
	if _pos.y > gy + 0.02:
		_vel.y -= 9.8 * dt
		_vel.x *= 1.0 - dt
		_vel.z *= 1.0 - dt
		_pos += _vel * dt
		_pos.y = maxf(_pos.y, gy + 0.008)
	else:
		_pos.y = gy + 0.008
		_vel = Vector3.ZERO
		_ori = _ori.slerp(Basis(Vector3.UP, _yaw) * Basis(Vector3.FORWARD, 2.8), 1.0 - exp(-4.0 * dt)) # (on its back)
		for i in 2:
			spread[i] = _ease(spread[i], 0.55, 2.0, dt)
			stroke[i] = _ease(stroke[i], 0.2, 2.0, dt)
		_legs_to("crawl", dt, 2.0)


# --- its roost, for the world to give it -----------------------------------------------------

## A dead snag (a tree's stand-in), its loose bark, a branch out from it to
## hang under; meta "roost": the point under the branch (its claws there),
## "roost_face": the way a bat hung there has its back.
static func roost_snag(h := 2.6) -> Node3D:
	var n := Node3D.new()
	n.set_meta("prop", true)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.35, 0.29)
	wood.roughness = 0.95
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.12
	cm.height = h
	trunk.mesh = cm
	trunk.material_override = wood
	trunk.position = Vector3(0.0, h * 0.5, 0.0)
	n.add_child(trunk)
	var br := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.025
	bc.bottom_radius = 0.035
	bc.height = 0.6
	br.mesh = bc
	br.material_override = wood
	br.rotation = Vector3(0.0, 0.0, PI * 0.5 - 0.08)
	br.position = Vector3(0.32, h - 0.25, 0.0)
	n.add_child(br)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.3, 0.25, 0.2)
	bark.roughness = 1.0
	bark.cull_mode = BaseMaterial3D.CULL_DISABLED
	for k in 3: # (loose bark, lifting off it)
		var pl := MeshInstance3D.new()
		var pm := QuadMesh.new()
		pm.size = Vector2(0.12, 0.35)
		pl.mesh = pm
		pl.material_override = bark
		var a := 1.2 + k * 2.1
		pl.position = Vector3(cos(a) * 0.1, h * (0.45 + 0.15 * k), sin(a) * 0.1)
		pl.rotation = Vector3(0.1, -a + PI * 0.5, 0.0)
		n.add_child(pl)
	n.set_meta("roost", Vector3(0.42, h - 0.25 - 0.03, 0.0))
	n.set_meta("roost_face", Vector3(0.0, 0.0, 1.0))
	return n


# --- steering (pilot.gd) ----------------------------------------------------------------

func _pl() -> PilotScript:
	if _pilot == null:
		_pilot = PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return _ori * Vector3.FORWARD


func _p_steer(point: Vector3, _speed: float) -> void:
	_piloted = true
	_go("fly")
	_fly_to = point + Vector3(0.0, 1.5, 0.0) if point.y <= _ground(point.x, point.z) + 0.1 else point


func _p_hold() -> void:
	_piloted = true
	if is_flying():
		_fly_to = _pos


func _p_mobile() -> bool:
	return not dead and not young


func _p_speed() -> float:
	return 5.0


func _p_reach() -> float:
	return 0.6


func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["hunt", "forage", "drink", "sleep", "groom", "alarm", "roost", "mate"])
	if not male:
		b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var p: Variant = args.get("prey")
			if not (p is Node3D):
				p = Diet.find_one(self, 30.0, Diet.prey_of(self))
			if p == null or p == self:
				return false
			hunt(p)
		"forage":
			forage(float(args.get("seconds", 60.0)))
		"drink":
			if not args.has("at"):
				return false
			drink(args.at)
		"sleep":
			sleep(float(args.get("seconds", 30.0)))
		"groom":
			groom(float(args.get("seconds", 10.0)))
		"alarm":
			alarm()
		"roost":
			roost()
		"mate":
			return mate(args.get("partner"), float(args.get("seconds", 12.0)))
		"birth":
			birth(int(args.get("n", 2)))
		"nurse":
			nurse(float(args.get("seconds", 20.0)))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"hunt":
			return _mode != "hunt" and _mode != "glean"
		"drink":
			return _mode != "drink"
		"roost":
			return _mode == "hang"
		"sleep", "groom", "alarm", "nurse":
			return _mode != name
		"mate":
			return _mode != "mount"
		"birth":
			return _mode != "birth"
	return true


func _p_act_secs(_name: String) -> float:
	return -1.0


func test_mode(mode: String) -> void:
	if mode.contains("pose"): # (held still, mid-downstroke)
		_mode = "posed"
		spread = [1.0, 1.0]
		stroke = [0.2, 0.2]
		_legs_w = {"fly": 1.0, "hang": 0.0, "crawl": 0.0}
		_jaw = 0.4
	elif mode.contains("fly"):
		forage(600.0)
	elif mode.contains("groom"):
		groom(600.0)
	elif mode.contains("sleep"):
		sleep(600.0)
	elif mode.contains("alarm"):
		alarm(600.0)
	elif mode.contains("crawl"):
		_to("crawl")
		_piloted = true
