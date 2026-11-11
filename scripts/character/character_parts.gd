class_name CharacterParts
extends RefCounted
## The figure itself, built from its look (CharacterLook) onto its bones
## (Avatar's: hips, chest, head, the limbs' two bones each, the feet): its
## body (a torso and a pelvis lofted up their spine; arms and legs lofted
## down their bones, a shoulder's roundness, a biceps, a calf's swell, each
## bone's ends rounded into its joint; hands with fingers and a thumb,
## open, and closed round what they hold; a head with its jaw, nose, lips,
## lidded eyes, brows and ears), its hair (a sheet of strands from the
## crown down over the scalp and hanging from the hairline; tails, braids, a
## bun, a crest; a beard on the jaw's own surface; all thicker, shorter and
## wavier the more it curls), and what it wears (a shirt and its sleeves,
## pants, boots, a hat, glasses), in cloth that carries the shirt's pattern
## (character_cloth.gdshader).
##
## Everything is in the bones' own spaces: the torso's and the head's y up,
## their fronts toward -z; a limb's down -z from its joint, +y the way it
## bends (a knee's front; an elbow's back). Sizes in metres: a figure
## 1.76 m tall.
##
## To add an option to a look's field: its case here (hair: STYLES and
## _hair's extras; a hat: _hat; a pattern: the cloth's shader).

const M := preload("res://scripts/character/character_mesh.gd")

# The keys: [along, across', through' (the outline's middle), half width,
# its front's depth (a limb's -y side), its back's (+y), squareness].
const TORSO := [
	[-0.07, 0.0, 0.0, 0.150, 0.100, 0.100, 2.6], [0.02, 0.0, 0.0, 0.148, 0.102, 0.098, 2.6],
	[0.14, 0.0, 0.0, 0.162, 0.118, 0.106, 2.5], [0.25, 0.0, 0.0, 0.180, 0.132, 0.116, 2.5],
	[0.335, 0.0, 0.004, 0.192, 0.120, 0.118, 2.6], [0.374, 0.0, 0.006, 0.192, 0.104, 0.110, 2.8],
	[0.402, 0.0, 0.010, 0.150, 0.084, 0.098, 2.5], [0.426, 0.0, 0.012, 0.090, 0.066, 0.078, 2.2],
	[0.445, 0.0, 0.012, 0.058, 0.055, 0.060, 2.0],
]
const NECK := [[0.40, 0.0, 0.014, 0.054, 0.052, 0.056, 2.0], [0.45, 0.0, 0.010, 0.049, 0.048, 0.052, 2.0], [0.52, 0.0, 0.004, 0.048, 0.046, 0.052, 2.0]]
const PELVIS := [
	[0.13, 0.0, 0.0, 0.146, 0.100, 0.098, 2.6], [0.06, 0.0, 0.0, 0.158, 0.104, 0.108, 2.6],
	[-0.02, 0.0, 0.004, 0.168, 0.100, 0.122, 2.6], [-0.09, 0.0, 0.004, 0.150, 0.085, 0.108, 2.6],
	[-0.135, 0.0, 0.0, 0.085, 0.060, 0.070, 2.3],
]
const THIGH := [
	[-0.07, 0.0, 0.0, 0.045, 0.045, 0.045], [-0.02, 0.0, 0.0, 0.082, 0.086, 0.082], [0.10, 0.0, 0.004, 0.080, 0.082, 0.084],
	[0.28, 0.0, 0.004, 0.064, 0.064, 0.068], [0.40, 0.0, 0.0, 0.054, 0.054, 0.056], [0.44, 0.0, 0.0, 0.052, 0.052, 0.056],
	[0.475, 0.0, 0.0, 0.030, 0.030, 0.030],
]
const SHIN := [
	[-0.04, 0.0, 0.004, 0.030, 0.030, 0.034], [0.0, 0.0, 0.004, 0.052, 0.050, 0.058], [0.10, 0.0, -0.004, 0.052, 0.062, 0.046],
	[0.20, 0.0, -0.002, 0.046, 0.054, 0.042], [0.34, 0.0, 0.0, 0.034, 0.036, 0.034], [0.42, 0.0, 0.0, 0.031, 0.033, 0.031],
	[0.445, 0.0, 0.0, 0.018, 0.018, 0.018],
]
const UPPER_ARM := [
	[-0.050, 0.0, 0.0, 0.003, 0.003, 0.003], [-0.040, 0.0, 0.0, 0.026, 0.026, 0.026], [-0.022, 0.0, 0.0, 0.043, 0.043, 0.043], [0.01, 0.0, 0.0, 0.050, 0.050, 0.050],
	[0.10, 0.0, -0.002, 0.046, 0.049, 0.045], [0.22, 0.0, 0.0, 0.040, 0.041, 0.041], [0.30, 0.0, 0.0, 0.037, 0.036, 0.040],
	[0.33, 0.0, 0.0, 0.020, 0.020, 0.020],
]
const FOREARM := [
	[-0.03, 0.0, 0.0, 0.020, 0.020, 0.020], [0.0, 0.0, 0.0, 0.038, 0.036, 0.040], [0.07, 0.0, 0.0, 0.042, 0.041, 0.040],
	[0.18, 0.0, 0.0, 0.031, 0.032, 0.032], [0.265, 0.0, 0.0, 0.021, 0.027, 0.027], [0.285, 0.0, 0.0, 0.014, 0.018, 0.018],
]
const HEAD := [
	[0.000, 0.0, -0.050, 0.024, 0.026, 0.030, 2.2], [0.022, 0.0, -0.022, 0.052, 0.052, 0.050, 2.3],
	[0.050, 0.0, -0.008, 0.066, 0.070, 0.070, 2.3], [0.085, 0.0, 0.000, 0.073, 0.082, 0.084, 2.3],
	[0.125, 0.0, 0.004, 0.076, 0.084, 0.094, 2.2], [0.160, 0.0, 0.006, 0.077, 0.090, 0.098, 2.2],
	[0.195, 0.0, 0.008, 0.072, 0.084, 0.094, 2.1], [0.222, 0.0, 0.010, 0.055, 0.062, 0.072, 2.0],
	[0.238, 0.0, 0.012, 0.025, 0.028, 0.034, 2.0],
]
const HEAD_MID := Vector3(0.0, 0.135, 0.006) ## (the head's middle: its hair's out from here)

## Where the bones are set (Avatar): the chest on the hips, the head on the
## chest, the shoulders, the hips' joints.
const CHEST_AT := Vector3(0.0, 0.12, 0.0)
const HEAD_AT := Vector3(0.0, 0.455, -0.004)
const SHOULDER := Vector3(0.188, 0.345, 0.0)
const HIP := Vector3(0.092, -0.03, 0.0)

## The hairstyles: thick (m, on the scalp), and how far it hangs from the
## hairline at the brow, the sides, the back (m); its extras by name (_hair).
const STYLES := {
	"bald": {}, "buzz": {"thick": 0.003},
	"short": {"thick": 0.012, "fringe": 0.012, "side": 0.006, "back": 0.014},
	"medium": {"thick": 0.016, "fringe": 0.028, "side": 0.10, "back": 0.12},
	"long": {"thick": 0.016, "fringe": 0.02, "side": 0.15, "back": 0.36},
	"ponytail": {"thick": 0.008}, "braids": {"thick": 0.007}, "bun": {"thick": 0.007}, "mohawk": {"thick": 0.002},
}
const CURLS := ["straight", "wavy", "curly", "coily"]
const CURL_THICK := [1.0, 1.2, 1.7, 2.4] ## (hair thicker the more it curls)
const CURL_LENGTH := [1.0, 0.95, 0.8, 0.6] ## (and shorter)
const BUILDS := {"slender": Vector2(0.92, 0.94), "average": Vector2(1.0, 1.0), "stocky": Vector2(1.1, 1.12)} ## width, depth

static var _shaders := {}


## Builds the look onto the bones. rig: {hips, chest, head: Node3D; limbs:
## name ("l_arm", "r_leg", ...) -> {a, b: its two bones}; boots: "l"/"r" ->
## Node3D}. What was built before is taken away first. Gives back {hands:
## "l"/"r" -> [open, closed] (the hands' two meshes)}.
static func build(rig: Dictionary, look: CharacterLook) -> Dictionary:
	_clear(rig)
	var wd: Vector2 = BUILDS.get(look.option("build"), Vector2.ONE)
	var skin_c := look.color("skin")
	var skin := _plain(skin_c, 0.62)
	skin.rim_enabled = true
	skin.rim = 0.25
	var hair_c := look.color("hair")
	var curl := maxi(CURLS.find(look.option("curl")), 0)
	var hair := _hair_material(hair_c, float(curl))
	var shirt := look.option("shirt")
	var hips: Node3D = rig.hips
	var chest: Node3D = rig.chest
	var head: Node3D = rig.head

	# the body
	var body := M.new()
	body.tube(_wide(NECK, wd, 0.0), 14, 2)
	if shirt == "none":
		body.tube(_wide(TORSO, wd, 0.0), 20, 3)
	body.put(chest, skin, "torso")
	var out := {"hands": {}}
	for side: int in [-1, 1]:
		var s := "l" if side < 0 else "r"
		var arm: Dictionary = rig.limbs[s + "_arm"]
		var leg: Dictionary = rig.limbs[s + "_leg"]
		var ua := M.new()
		ua.tube(_wide(UPPER_ARM, wd, 0.0), 12, 3, "z")
		ua.put(arm.a, skin)
		var fa := M.new()
		fa.tube(_wide(FOREARM, wd, 0.0), 12, 3, "z")
		fa.put(arm.b, skin)
		out.hands[s] = [_hand(float(side), 1.0).put(arm.b, skin), _hand(float(side), 3.3).put(arm.b, skin)]
		(out.hands[s][1] as Node3D).visible = false
		if look.option("pants") == "shorts": # (bare below them)
			var sh := M.new()
			sh.tube(_wide(SHIN, wd, 0.0), 12, 3, "z")
			sh.put(leg.b, skin)
			var th := M.new()
			th.tube(_wide(THIGH, wd, 0.0), 12, 3, "z")
			th.put(leg.a, skin)
		_boot(rig.boots[s], float(side))
	_face(head, look, skin, skin_c, hair)
	_hair(head, look, hair, curl)
	_beard(head, look, hair, curl, skin_c, hair_c)
	_hat(head, look)
	_glasses(head, look)

	# what it wears
	var accent := look.color("pattern_color")
	var accent2 := look.color("pattern_color2")
	if shirt != "none":
		var tunic := shirt == "tunic"
		var keys := _wide(TORSO, wd, 0.008)
		# (tucked in at the belt; a tunic's skirt out over the hips)
		keys[0] = [(-0.205 if tunic else -0.035), 0.0, 0.0, (0.198 if tunic else 0.156) * wd.x, (0.136 if tunic else 0.108) * wd.y, (0.144 if tunic else 0.106) * wd.y, 2.6]
		if tunic:
			keys.insert(1, [-0.09, 0.0, 0.0, 0.184 * wd.x, 0.124 * wd.y, 0.136 * wd.y, 2.6])
		keys[keys.size() - 1][0] = 0.432 # (its neck: round the neck's foot)
		var cloth := _cloth(look.color("shirt_color"), accent, accent2, int(CharacterLook.PATTERN_IDS.get(look.option("pattern"), 0)), 1.03 * wd.x, Vector2(0.255, 8.0))
		var sm := M.new()
		sm.tube(keys, 28, 3)
		sm.put(chest, cloth, "shirt")
		if tunic: # (belted)
			var belt := M.new()
			belt.tube([[-0.015, 0.0, 0.0, 0.158 * wd.x, 0.112 * wd.y, 0.108 * wd.y, 2.6], [0.02, 0.0, 0.0, 0.158 * wd.x, 0.113 * wd.y, 0.109 * wd.y, 2.6]], 24, 1)
			belt.put(chest, _plain(Color(0.25, 0.17, 0.11), 0.7))
		if shirt != "vest":
			var long := shirt in ["long_sleeves", "tunic"]
			for side: int in [-1, 1]:
				var arm: Dictionary = rig.limbs[("l" if side < 0 else "r") + "_arm"]
				var up := M.new()
				var uk := _wide(UPPER_ARM, wd, 0.009)
				if not long: # (to above the elbow, open)
					uk = uk.slice(0, 5)
					uk.append([0.17, 0.0, 0.0, 0.052 * wd.x, 0.053 * wd.y, 0.053 * wd.y])
				up.tube(uk, 12, 3, "z")
				up.put(arm.a, _cloth(look.color("shirt_color"), accent, accent2, 0 if long else 100, 0.3, Vector2(0.15, 0.0)))
				if long:
					var lo := M.new()
					var fk := _wide(FOREARM, wd, 0.009).slice(0, 4)
					fk.append([0.255, 0.0, 0.0, 0.036 * wd.x, 0.036 * wd.y, 0.036 * wd.y])
					lo.tube(fk, 12, 3, "z")
					lo.put(arm.b, _cloth(look.color("shirt_color"), accent, accent2, 100, 0.3, Vector2(0.235, 0.0)))
	var pants := look.option("pants")
	var pc := look.color("pants_color")
	var pcloth := _cloth(pc, pc, pc, 0, 1.0, Vector2.ZERO)
	var grow := 0.005 if pants == "fringed_leggings" else 0.009
	var pm := M.new()
	pm.tube(_wide(PELVIS, wd, 0.007), 24, 3)
	pm.put(hips, pcloth, "pants")
	var bm := M.new() # (its belt)
	bm.tube([[0.092, 0.0, 0.0, 0.162 * wd.x, 0.112 * wd.y, 0.114 * wd.y, 2.6], [0.128, 0.0, 0.0, 0.156 * wd.x, 0.110 * wd.y, 0.108 * wd.y, 2.6]], 24, 1)
	bm.put(hips, _plain(Color(0.25, 0.17, 0.11), 0.7))
	for side: int in [-1, 1]:
		var leg: Dictionary = rig.limbs[("l" if side < 0 else "r") + "_leg"]
		var tk := _wide(THIGH, wd, grow)
		if pants == "shorts":
			tk = tk.slice(0, 3)
			tk.append([0.26, 0.0, 0.004, 0.078 * wd.x, 0.078 * wd.y, 0.080 * wd.y])
		var tm := M.new()
		tm.tube(tk, 14, 3, "z")
		tm.put(leg.a, pcloth)
		if pants != "shorts":
			var sk := _wide(SHIN, wd, grow).slice(0, 5)
			sk.append([0.405, 0.0, 0.0, 0.046, 0.048, 0.046] if pants == "trousers" else [0.40, 0.0, 0.0, 0.037, 0.039, 0.037])
			var lm := M.new()
			lm.tube(sk, 14, 3, "z")
			lm.put(leg.b, pcloth)
			if pants == "fringed_leggings": # (a fringe down each leg's outside)
				_fringe(leg.a, tk, 0.02, 0.42, float(side), pcloth)
				_fringe(leg.b, sk, 0.02, 0.38, float(side), pcloth)
	return out


static func _clear(rig: Dictionary) -> void:
	var nodes: Array = [rig.hips, rig.chest, rig.head]
	for name in rig.limbs:
		nodes.append(rig.limbs[name].a)
		nodes.append(rig.limbs[name].b)
	for s in rig.boots:
		nodes.append(rig.boots[s])
	for n: Node in nodes:
		for c in n.get_children():
			if c.has_meta("dress"):
				n.remove_child(c)
				c.queue_free()


## keys, wider and deeper by the build (wd), and grown all round by grow m
## (what's worn over them).
static func _wide(keys: Array, wd: Vector2, grow: float) -> Array:
	var out := []
	for k: Array in keys:
		var q := k.duplicate()
		var g := grow * smoothstep(0.004, 0.03, float(k[3])) # (a rounded end stays closed)
		q[3] = float(k[3]) * wd.x + g
		q[4] = float(k[4]) * wd.y + g
		q[5] = float(k[5]) * wd.y + g
		out.append(q)
	return out


# ---- materials

static func _plain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func _shader(path: String) -> Shader:
	if not _shaders.has(path):
		_shaders[path] = load(path)
	return _shaders[path]


static func _cloth(base: Color, accent: Color, accent2: Color, pattern: int, girth: float, band: Vector2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/render/character_cloth.gdshader")
	m.set_shader_parameter("base", base)
	m.set_shader_parameter("accent", accent)
	m.set_shader_parameter("accent2", accent2)
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("girth", girth)
	m.set_shader_parameter("band", band)
	return m


static func _hair_material(c: Color, curl: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/render/character_hair.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("curl", curl)
	return m


# ---- the body's parts

## A hand at a forearm's end (side: -1 the left, 1 the right; its palm
## toward the body): the palm, four fingers of three joints each, a thumb.
## curl: 1 hanging open, the fingers a little bent; 3.3 closed round a
## handle.
static func _hand(side: float, curl: float) -> M:
	var m := M.new()
	var p := side # (the palm's way: +x the right's)
	m.tube([[0.262, 0.0, 0.0, 0.014, 0.024, 0.024, 3.0], [0.30, 0.0, -0.001, 0.0155, 0.037, 0.034, 3.2],
			[0.345, p * 0.002, -0.001, 0.0135, 0.040, 0.037, 3.2], [0.368, p * 0.004, 0.0, 0.010, 0.037, 0.035, 3.0]], 12, 2, "z")
	var lens := [0.074, 0.082, 0.076, 0.060]
	for f in 4:
		var at := Vector3(p * 0.003, -0.028 + 0.0185 * f, -0.362)
		var a := 0.0
		var r := 0.0098 - 0.0006 * absf(f - 1.0)
		for j in 3:
			a += [0.30, 0.45, 0.35][j] * curl
			var seg: float = lens[f] * [0.45, 0.31, 0.26][j]
			var d := Vector3(sin(a) * p, 0.0, -cos(a))
			var b := Basis(Vector3(cos(a), 0.0, sin(a) * p), Vector3.UP, -d).orthonormalized() # (its long way: -z, down the finger)
			m.blob(at + d * seg * 0.5, Vector3(r, r * 1.05, seg * 0.62), b, 8, 6)
			at += d * seg
			r *= 0.9
	# the thumb: off the palm's front edge, forward and in
	var open := Vector3(p * 0.45, -0.62, -0.64).normalized()
	var shut := Vector3(p * 0.85, 0.12, -0.5).normalized()
	var td := open.lerp(shut, clampf((curl - 1.0) / 2.3, 0.0, 1.0)).normalized()
	var ta := Vector3(p * 0.006, -0.032, -0.300)
	for j in 2:
		var seg: float = [0.042, 0.030][j]
		var up := td.cross(Vector3(p, 0.0, 0.0)).normalized()
		var b := Basis(up.cross(td).normalized(), up, -td).orthonormalized()
		m.blob(ta + td * seg * 0.5, Vector3(0.0115 - 0.0015 * j, 0.012 - 0.0015 * j, seg * 0.64), b, 8, 6)
		ta += td * seg
		td = td.lerp(Vector3(p * 0.3 * curl, 0.0, -1.0).normalized(), 0.35).normalized()
	return m


## A boot on a foot's bone (its origin on the ground under the ankle, its
## toe toward -z): a sole and heel, the upper over the toes and instep, a
## shaft up the ankle.
static func _boot(foot: Node3D, _side: float) -> void:
	var leather := _plain(Color(0.27, 0.19, 0.12), 0.75)
	var up := M.new()
	up.tube([[-0.082, 0.0, 0.055, 0.020, 0.028, 0.030, 2.6], [-0.06, 0.0, 0.062, 0.036, 0.040, 0.052, 2.6], [-0.015, 0.0, 0.074, 0.043, 0.052, 0.068, 2.6],
			[0.05, 0.0, 0.056, 0.045, 0.034, 0.044, 2.6], [0.12, 0.0, 0.046, 0.047, 0.025, 0.028, 2.8], [0.168, 0.0, 0.042, 0.040, 0.021, 0.022, 2.8],
			[0.192, 0.0, 0.038, 0.018, 0.014, 0.014, 2.4]], 14, 3, "z")
	up.tube([[0.10, 0.0, 0.012, 0.038, 0.042, 0.040, 2.2], [0.15, 0.0, 0.006, 0.036, 0.038, 0.037, 2.2], [0.20, 0.0, 0.002, 0.036, 0.037, 0.037, 2.2]], 14, 2)
	up.put(foot, leather)
	var sole := M.new()
	sole.tube([[-0.088, 0.0, 0.013, 0.020, 0.013, 0.013, 4.0], [-0.066, 0.0, 0.013, 0.040, 0.013, 0.013, 4.0], [0.0, 0.0, 0.013, 0.044, 0.013, 0.013, 4.0],
			[0.11, 0.0, 0.011, 0.050, 0.011, 0.011, 4.0], [0.172, 0.0, 0.011, 0.043, 0.011, 0.011, 4.0], [0.198, 0.0, 0.011, 0.020, 0.011, 0.011, 4.0]], 14, 2, "z")
	sole.tube([[-0.088, 0.0, 0.030, 0.020, 0.012, 0.012, 4.0], [-0.066, 0.0, 0.030, 0.039, 0.012, 0.012, 4.0], [-0.02, 0.0, 0.030, 0.041, 0.012, 0.012, 4.0],
			[-0.012, 0.0, 0.030, 0.020, 0.012, 0.012, 4.0]], 12, 1, "z") # (the heel)
	sole.put(foot, _plain(Color(0.1, 0.08, 0.07), 0.9))


## A fringe down a leg's outside (side): thongs out from the legging's skin
## (keys: its, from s0 to s1 down the bone), hanging.
static func _fringe(bone: Node3D, keys: Array, s0: float, s1: float, side: float, cloth: Material) -> void:
	var rk := M.refine(keys, 3)
	var m := M.new()
	var th := 0.0 if side > 0.0 else PI # (the leg's outside: its +x the right's)
	var s := s0
	var i := 0
	while s < s1:
		var p := M.surface(rk, s, th, "z")
		var tip := p + Vector3(side * (0.028 + 0.012 * sin(i * 2.4)), 0.004 * sin(i * 1.7), -0.022)
		var rows: Array[PackedVector3Array] = [PackedVector3Array([p + Vector3(0.0, 0.0, 0.0045), p - Vector3(0.0, 0.0, 0.0045)]),
				PackedVector3Array([tip + Vector3(0.0, 0.0, 0.002), tip - Vector3(0.0, 0.0, 0.002)])]
		# (a thong seen from either side: laid twice, one facing each way)
		m.grid(rows, false, PackedFloat32Array(), false, p + Vector3(0.0, -1.0, 0.0))
		m.grid(rows, false, PackedFloat32Array(), false, p + Vector3(0.0, 1.0, 0.0))
		s += 0.011
		i += 1
	var mi := m.put(bone, cloth)
	if mi:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _g(x: float, s: float) -> float:
	return exp(-0.5 * x * x / (s * s))


## How far the face stands out from the head's plain shape (m) at y up it,
## a round it from its front's middle: the sockets sunk for the eyes, the
## brow's ridge over them, the lids, the nose from its bridge to its tip
## and its wings, the lips and the furrow between them, the chin, the
## cheekbones.
static func _features(y: float, a: float) -> float:
	var d := 0.0
	var aa := absf(a)
	d -= 0.0080 * _g(y - 0.1275, 0.0100) * _g(aa - 0.40, 0.17) # sockets
	d += 0.0042 * _g(y - 0.1515, 0.0075) * _g(a, 0.62) # brow
	d += 0.0034 * _g(y - 0.1395, 0.0036) * _g(aa - 0.40, 0.14) # upper lids
	d += 0.0014 * _g(y - 0.1165, 0.0040) * _g(aa - 0.40, 0.13) # lower lids
	if y < 0.156 and y > 0.074: # the nose
		var t := (0.150 - y) / 0.060 # (0 at its bridge .. 1 at its tip)
		var tc := clampf(t, 0.0, 1.0)
		var h := (0.0035 + 0.0195 * pow(tc, 1.25)) * (1.0 - smoothstep(1.0, 1.2, t)) * smoothstep(-0.1, 0.05, t)
		d += h * _g(a, lerpf(0.075, 0.125, tc))
	d += 0.0068 * _g(y - 0.0890, 0.0060) * _g(aa - 0.165, 0.055) # its wings
	d += 0.0036 * _g(y - 0.0600, 0.0034) * _g(a, 0.21) # lips
	d += 0.0042 * _g(y - 0.0495, 0.0040) * _g(a, 0.18)
	d -= 0.0022 * _g(y - 0.0548, 0.0013) * _g(a, 0.24)
	d -= 0.0015 * _g(y - 0.070, 0.0045) * _g(a, 0.07) # (the hollow under the nose)
	d += 0.0045 * _g(y - 0.020, 0.011) * _g(a, 0.30) # chin
	d -= 0.0018 * _g(y - 0.037, 0.005) * _g(a, 0.28) # (and the hollow over it)
	d += 0.0030 * _g(y - 0.102, 0.014) * _g(aa - 0.78, 0.22) # cheekbones
	return d


## A point on the head's skin, y up it, a round it from its front's middle
## (radians, toward its left), lifted out off it.
static func _on_head(rk: Array, y: float, a: float, out: float) -> Vector3:
	var p := M.surface(rk, y, a - PI * 0.5)
	var d := (p - Vector3(0.0, clampf(y, 0.03, 0.2), 0.006)).normalized()
	return p + d * (out + _features(y, a))


## The head: its skull, jaw and face one skin (_features), the ears, the
## eyes in their sockets, the lips, the brows.
static func _face(head: Node3D, look: CharacterLook, skin: Material, skin_c: Color, hair: Material) -> void:
	var rk := M.refine(HEAD, 4)
	var m := M.new()
	var rows: Array[PackedVector3Array] = []
	var ny := 60
	var na := 80
	for i in ny + 1:
		var y := 0.238 * float(i) / ny
		var row := PackedVector3Array()
		for j in na:
			var u := 2.0 * float(j) / na - 1.0 # (closer together at the face: its features' detail)
			row.append(_on_head(rk, y, PI * signf(u) * pow(absf(u), 1.7), 0.0))
		rows.append(row)
	m.grid(rows, true, PackedFloat32Array(), true)
	for side: float in [-1.0, 1.0]: # the ears, their rims a little out from the head
		m.blob(Vector3(side * 0.0775, 0.112, 0.014), Vector3(0.0070, 0.029, 0.0180), Basis(Vector3.UP, -side * 0.42) * Basis(Vector3.RIGHT, -0.15), 10, 8)
	m.put(head, skin, "head")
	var dark := M.new() # (the ears' hollows, the mouth's line, the nostrils)
	for side: float in [-1.0, 1.0]:
		dark.blob(Vector3(side * 0.0810, 0.112, 0.012), Vector3(0.0032, 0.018, 0.0095), Basis(Vector3.UP, -side * 0.42), 8, 6)
		dark.blob(_on_head(rk, 0.0815, side * 0.085, -0.0015), Vector3(0.0034, 0.0022, 0.0040), Basis(), 6, 4)
	dark.blob(_on_head(rk, 0.0548, 0.0, -0.0006), Vector3(0.0200, 0.0011, 0.0030), Basis(), 10, 4)
	dark.put(head, _plain(skin_c.darkened(0.55).lerp(Color(0.25, 0.08, 0.07), 0.35), 0.8))
	var lips := M.new() # (a skin of their colour over them)
	_patch(lips, rk, 0.0435, 0.0660, 0.27, func(y: float, a: float) -> float:
		var e := pow(a / 0.25, 2.0) + pow((y - 0.0548) / 0.0100, 2.0)
		return 0.0023 * smoothstep(1.0, 0.55, e), NAN, NAN, false, 28)
	lips.put(head, _plain(skin_c.lerp(Color(0.62, 0.22, 0.2), 0.42).darkened(0.08), 0.5))
	# the eyes: the white, the iris, the pupil, looking ahead
	var white := M.new()
	var iris := M.new()
	var pupil := M.new()
	for side: float in [-1.0, 1.0]:
		var at := _on_head(rk, 0.1275, side * 0.40, 0.0)
		var c := at + Vector3(0.0, 0.0, 0.0130 - 0.0046)
		white.blob(c, Vector3.ONE * 0.0130, Basis(), 14, 10)
		iris.blob(c + Vector3(0.0, 0.0, -0.0102), Vector3(0.0066, 0.0066, 0.0034), Basis(), 12, 6)
		pupil.blob(c + Vector3(0.0, 0.0, -0.0121), Vector3(0.0030, 0.0030, 0.0018), Basis(), 10, 4)
	white.put(head, _plain(Color(0.93, 0.92, 0.9), 0.25))
	iris.put(head, _plain(look.color("eyes"), 0.2))
	pupil.put(head, _plain(Color(0.02, 0.02, 0.02), 0.1))
	var brows := M.new() # (a bald head keeps its brows)
	for side: float in [-1.0, 1.0]:
		_patch(brows, rk, 0.1445, 0.1595, 0.0, func(y: float, a: float) -> float:
			var aa := absf(a)
			var mid := 0.1512 + 0.0022 * sin(PI * clampf((aa - 0.16) / 0.5, 0.0, 1.0)) # (arched)
			var half := lerpf(0.0040, 0.0018, smoothstep(0.2, 0.66, aa)) # (thinner to its outer end)
			return 0.0036 * maxf(1.0 - pow((y - mid) / half, 2.0), 0.0) * smoothstep(0.14, 0.2, aa) * smoothstep(0.68, 0.6, aa),
			0.12 * side if side > 0.0 else -0.7, 0.7 if side > 0.0 else -0.12, false, 12)
	brows.put(head, hair)


## How high the hairline is (the head's y) a round the head from its
## front's middle (0 .. PI: either side alike).
static func _hairline(a: float) -> float:
	var pts := [[0.0, 0.198], [0.6, 0.192], [1.0, 0.172], [1.35, 0.150], [1.62, 0.132], [1.95, 0.098], [2.5, 0.074], [PI, 0.066]]
	for i in pts.size() - 1:
		if a <= float(pts[i + 1][0]):
			var t := smoothstep(float(pts[i][0]), float(pts[i + 1][0]), a)
			return lerpf(float(pts[i][1]), float(pts[i + 1][1]), t)
	return 0.066


## The hair: a sheet of strands from the crown down over the scalp to the
## hairline, hanging on from there as far as its style says (at the brow,
## the sides, the back), thicker, shorter and wavier the more it curls;
## kept flat under a hat. Then its style's own: a tail, braids, a bun, a
## crest.
static func _hair(head: Node3D, look: CharacterLook, hair: Material, curl: int) -> void:
	var style: Dictionary = STYLES.get(look.option("hair_style"), {})
	if style.is_empty():
		return
	var name := look.option("hair_style")
	var hatted := look.option("hat") in ["wide_brim", "straw", "knit_cap", "cap"]
	var full: bool = float(style.get("thick", 0.0)) >= 0.01
	var thick: float = float(style.thick) * (CURL_THICK[curl] if full else 1.0 + 0.25 * curl)
	var lenk: float = CURL_LENGTH[curl]
	var rk := M.refine(HEAD, 4)
	var m := M.new()
	var cols := 64
	var scalp := 12
	var rows: Array[PackedVector3Array] = []
	var most := maxf(float(style.get("back", 0.0)), float(style.get("side", 0.0))) * lenk
	var hang := ceili(most / 0.016) if most > 0.0 else 1
	for i in scalp + hang + 1:
		rows.append(PackedVector3Array())
	for j in cols:
		var a := TAU * j / cols # (round from the front's middle)
		var fa := absf(wrapf(a, -PI, PI))
		var line := _hairline(fa)
		# how far this strand hangs: the brow's, the side's, the back's
		var l := lerpf(float(style.get("fringe", 0.0)) * maxf(1.0 - 0.5 * curl, 0.0), float(style.get("side", 0.0)), smoothstep(0.5, 1.2, fa)) # (curls stand off the brow: none hanging over it)
		l = lerpf(l, float(style.get("back", 0.0)), smoothstep(1.75, 2.3, fa)) * lenk
		var wave := 0.0
		for i in scalp + 1:
			var s := float(i) / scalp
			var y := lerpf(0.2375, line, s)
			var t := thick * (0.75 + 0.25 * sin(PI * s))
			if l <= 0.001:
				t *= 1.0 - 0.8 * smoothstep(0.75, 1.0, s) # (thinning to the hairline, where it ends there)
			if hatted and y > 0.158:
				t = minf(t, 0.004)
			if curl > 0 and full:
				t += thick * 0.12 * curl * (0.5 + 0.5 * sin(a * (7.0 + 4.0 * curl) + s * (5.0 + 3.0 * curl))) * (0.4 if hatted else 1.0)
			var p := _on_head(rk, y, a, t)
			if i == 0:
				p = Vector3(0.0, 0.2385 + (minf(thick, 0.004) if hatted else thick) * 0.9, 0.012)
			rows[i].append(p)
		# hanging on from the hairline: down, and out clear of the neck and
		# the shoulders' back
		var from := rows[scalp][j]
		var outw := Vector3(from.x, 0.0, from.z - 0.006).normalized()
		for h in range(1, hang + 1):
			var d := minf(l, most * float(h) / hang)
			var flare := 0.03 * smoothstep(0.0, 0.08, d) + 0.05 * smoothstep(0.08, 0.26, d) * smoothstep(1.6, 2.4, fa)
			if curl > 0: # (waves, out from the head: never in through the brow)
				wave = 0.004 * curl * (1.0 + sin(d * (40.0 + 25.0 * curl) + a * 9.0)) + thick * 0.15 * curl * smoothstep(0.0, 0.05, d)
			flare += 0.004 + thick * 0.35 * smoothstep(1.2, 0.4, fa)
			var tip := 1.0 - 0.5 * smoothstep(l * 0.7, l, d) # (thinning to its ends)
			rows[scalp + h].append(from + Vector3.DOWN * d + outw * (flare + wave) * tip - outw * thick * 0.5 * (1.0 - tip))
	m.grid(rows, true, PackedFloat32Array(), false, HEAD_MID)
	match name:
		"ponytail":
			_strand(m, [Vector3(0.0, 0.165, 0.092), Vector3(0.0, 0.168, 0.128), Vector3(0.0, 0.10, 0.150), Vector3(0.0, -0.02, 0.150), Vector3(0.0, -0.13 * lenk - 0.03, 0.142)],
					[0.016, 0.022, 0.026 + 0.006 * curl, 0.022 + 0.006 * curl, 0.006], 10, curl * 0.004)
			m.blob(Vector3(0.0, 0.166, 0.110), Vector3(0.019, 0.019, 0.012), Basis(), 10, 6) # (its tie)
		"braids":
			for side: float in [-1.0, 1.0]:
				_strand(m, [Vector3(side * 0.072, 0.105, 0.030), Vector3(side * 0.086, 0.050, 0.004), Vector3(side * 0.092, -0.010, -0.050),
						Vector3(side * 0.088, -0.10, -0.122), Vector3(side * 0.084, -0.20, -0.146), Vector3(side * 0.082, -0.275, -0.143)],
						[0.013, 0.015, 0.015, 0.014, 0.013, 0.006], 8, 0.0, 0.0038)
		"bun":
			var r := 0.034 + 0.006 * curl
			m.blob(Vector3(0.0, 0.178, 0.098 + r * 0.45), Vector3(r, r * 0.92, r * 0.85), Basis(Vector3.RIGHT, 0.4), 14, 10)
		"mohawk":
			var crest: Array[PackedVector3Array] = []
			var high := 0.05 + 0.012 * curl
			for i in 20:
				var f := float(i) / 19.0
				# over the top: from the brow's hairline back to the nape
				var a := 0.0 if f < 0.5 else PI
				var y := lerpf(0.2, 0.2385, f / 0.5) if f < 0.5 else lerpf(0.2385, 0.09, (f - 0.5) / 0.5)
				var base := _on_head(rk, y, a, 0.0)
				var up := (base - HEAD_MID).normalized()
				var h := high * smoothstep(0.0, 0.14, f) * smoothstep(1.0, 0.78, f) + 0.004
				var row := PackedVector3Array()
				for w: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
					row.append(base + Vector3(w * 0.017, 0.0, 0.0) + up * h * (1.0 - absf(w)) * (1.0 + 0.12 * sin(i * 2.1 + w * 3.0) * curl))
				crest.append(row)
			m.grid(crest, false, PackedFloat32Array(), false, HEAD_MID)
	m.put(head, hair, "hair")


## A rope of hair through points, each its radius, round; wave: its curl,
## m; bumps: a braid's plaits (m).
static func _strand(m: M, path: Array, radii: Array, segs: int, wave := 0.0, bumps := 0.0) -> void:
	var rows: Array[PackedVector3Array] = []
	var n := (path.size() - 1) * 6
	for i in n + 1:
		var f := float(i) / n * (path.size() - 1)
		var k := mini(int(f), path.size() - 2)
		var t := f - k
		var p0: Vector3 = path[maxi(k - 1, 0)]
		var p1: Vector3 = path[k]
		var p2: Vector3 = path[k + 1]
		var p3: Vector3 = path[mini(k + 2, path.size() - 1)]
		var c := Vector3(M._cr(p0.x, p1.x, p2.x, p3.x, t), M._cr(p0.y, p1.y, p2.y, p3.y, t), M._cr(p0.z, p1.z, p2.z, p3.z, t))
		var along := (p2 - p1).normalized()
		var side := along.cross(Vector3.RIGHT if absf(along.x) < 0.9 else Vector3.UP).normalized()
		var up := side.cross(along)
		var r := lerpf(float(radii[k]), float(radii[k + 1]), t) + wave * sin(i * 1.3) + bumps * absf(sin(i * 0.9))
		var row := PackedVector3Array()
		for j in segs:
			var a := TAU * j / segs
			row.append(c + (side * cos(a) + up * sin(a)) * maxf(r, 0.001))
		rows.append(row)
	m.grid(rows, true, PackedFloat32Array(), true)


## The beard: hair on the jaw's own skin (a patch of it, as thick there as
## its style says, none over the lips), a moustache over the lip, a long
## beard's fall.
static func _beard(head: Node3D, look: CharacterLook, hair: Material, curl: int, skin_c: Color, hair_c: Color) -> void:
	var kind := look.option("facial_hair")
	if kind == "none":
		return
	var rk := M.refine(HEAD, 4)
	var m := M.new()
	var k := 1.0 + 0.35 * curl
	var mat := hair
	if kind == "stubble": # (a shadow on the jaw: the skin's colour, darkened toward the hair's)
		mat = _hair_material(skin_c.lerp(hair_c, 0.5), float(curl))
		_patch(m, rk, -0.004, 0.082, 1.32, func(y: float, a: float) -> float:
			return 0.0013 * (1.0 - smoothstep(0.055, 0.082, y) * smoothstep(0.2, 0.9, 1.3 - absf(a))))
	if kind in ["beard", "long_beard"]:
		_patch(m, rk, -0.012, 0.098, 1.36, func(y: float, a: float) -> float:
			var cheek := smoothstep(0.098, 0.062, y + 0.035 * smoothstep(1.0, 0.2, absf(a))) # (lower on the cheeks than by the ears)
			return 0.012 * k * cheek * (0.6 + 0.4 * smoothstep(0.07, 0.0, y)))
	if kind == "goatee":
		_patch(m, rk, -0.010, 0.046, 0.5, func(y: float, a: float) -> float:
			return 0.010 * k * smoothstep(0.5, 0.3, absf(a)) * smoothstep(0.046, 0.03, y))
	if kind == "sideburns":
		for side: float in [-1.0, 1.0]:
			_patch(m, rk, 0.045, 0.135, 1.42, func(y: float, a: float) -> float:
				return 0.005 * k * smoothstep(1.0, 1.15, a * side) * smoothstep(0.045, 0.06, y), 0.95 * side if side > 0.0 else -1.42, 1.42 if side > 0.0 else -0.95)
	if kind in ["moustache", "goatee", "beard", "long_beard"]:
		# (over the lip, drooping to the mouth's corners, thinner toward its ends)
		_patch(m, rk, 0.050, 0.078, 0.56, func(y: float, a: float) -> float:
			var f := clampf(absf(a) / 0.52, 0.0, 1.0)
			var mid := 0.0690 - 0.0125 * f * f
			var half := lerpf(0.0062, 0.0030, f)
			return (0.0060 + 0.002 * curl) * maxf(1.0 - pow((y - mid) / half, 2.0), 0.0) * smoothstep(1.0, 0.85, f) * (0.75 + 0.25 * smoothstep(0.0, 0.12, absf(a))),
			-0.56, 0.56, false, 22)
	if kind == "long_beard":
		_strand(m, [Vector3(0.0, 0.012, -0.062), Vector3(0.0, -0.05, -0.085), Vector3(0.0, -0.12, -0.095), Vector3(0.0, -0.17 * CURL_LENGTH[curl], -0.092)],
				[0.040, 0.038 + 0.004 * curl, 0.026 + 0.004 * curl, 0.006], 12, 0.003 * curl)
	m.put(head, mat, "beard")


## A patch of hair on the head's skin: from y0 up to y1, a_max either side
## of the front's middle (or a0 .. a1), as thick at each point as thick(y,
## a) says (m; 0: none there). lips: left bare round the mouth.
static func _patch(m: M, rk: Array, y0: float, y1: float, a_max: float, thick: Callable, a0 := NAN, a1 := NAN, lips := true, ny := 14) -> void:
	var lo := -a_max if is_nan(a0) else a0
	var hi := a_max if is_nan(a1) else a1
	var rows: Array[PackedVector3Array] = []
	var na := maxi(int((hi - lo) / 0.035), 6)
	for i in ny + 1:
		var y := lerpf(y0, y1, float(i) / ny)
		var row := PackedVector3Array()
		for j in na + 1:
			var a := lerpf(lo, hi, float(j) / na)
			var t: float = thick.call(y, a)
			var edge := sin(PI * float(i) / ny) * sin(PI * float(j) / na)
			if lips:
				t *= smoothstep(0.0, 0.25, edge) # (a beard: down to the skin at its edges)
			if lips and absf(a) < 0.36 and y > 0.040 and y < 0.068:
				t = 0.0
			row.append(_on_head(rk, maxf(y, 0.0), a, t - 0.0015) + Vector3.DOWN * maxf(-y, 0.0) * 1.2)
		rows.append(row)
	m.grid(rows, false, PackedFloat32Array(), false, HEAD_MID)


# ---- what it wears on its head

## The hats: each its own shapes, sat on the head a little back.
static func _hat(head: Node3D, look: CharacterLook) -> void:
	var kind := look.option("hat")
	if kind == "none":
		return
	var c := look.color("hat_color")
	var cloth := _cloth(c, c, c, 0, 0.6, Vector2.ZERO)
	var felt := _plain(c, 0.95)
	var band := _plain(c.darkened(0.55), 0.7)
	var sit := Transform3D(Basis(Vector3.RIGHT, -0.13), Vector3(0.0, 0.004, 0.022)) # (tipped back off the brow)
	var m := M.new()
	var trim := M.new()
	match kind:
		"wide_brim":
			m.tube([[0.172, 0.0, 0.007, 0.089, 0.101, 0.109], [0.215, 0.0, 0.007, 0.086, 0.098, 0.104], [0.258, 0.0, 0.007, 0.078, 0.089, 0.094],
					[0.276, 0.0, 0.007, 0.058, 0.066, 0.070], [0.282, 0.0, 0.007, 0.020, 0.024, 0.026]], 24, 3, "y", sit)
			m.tube([[0.165, 0.0, 0.007, 0.090, 0.102, 0.110], [0.1675, 0.0, 0.007, 0.166, 0.180, 0.184], [0.1705, 0.0, 0.007, 0.171, 0.185, 0.189],
					[0.1735, 0.0, 0.007, 0.166, 0.180, 0.184], [0.177, 0.0, 0.007, 0.090, 0.102, 0.110]], 32, 1, "y", sit)
			trim.tube([[0.176, 0.0, 0.007, 0.0915, 0.1035, 0.1115], [0.198, 0.0, 0.007, 0.0895, 0.1015, 0.1085]], 24, 1, "y", sit)
			m.put(head, felt, "hat")
		"straw":
			m.tube([[0.158, 0.0, 0.007, 0.090, 0.100, 0.108], [0.160, 0.0, 0.007, 0.190, 0.200, 0.204], [0.166, 0.0, 0.007, 0.188, 0.198, 0.202],
					[0.200, 0.0, 0.007, 0.112, 0.124, 0.130], [0.246, 0.0, 0.007, 0.072, 0.082, 0.086], [0.266, 0.0, 0.007, 0.024, 0.028, 0.030]], 32, 2, "y", sit)
			m.put(head, cloth, "hat")
		"knit_cap":
			m.tube([[0.160, 0.0, 0.007, 0.0835, 0.096, 0.1045], [0.205, 0.0, 0.007, 0.081, 0.094, 0.102], [0.246, 0.0, 0.009, 0.062, 0.072, 0.080],
					[0.266, 0.0, 0.011, 0.024, 0.028, 0.032]], 24, 3, "y", sit)
			trim.tube([[0.156, 0.0, 0.007, 0.0865, 0.099, 0.1075], [0.184, 0.0, 0.007, 0.0865, 0.099, 0.1075]], 24, 1, "y", sit)
			m.put(head, cloth, "hat")
		"headband":
			var over := 0.004 + minf(float(STYLES.get(look.option("hair_style"), {}).get("thick", 0.0)), 0.014) # (over the hair)
			m.tube([[0.170, 0.0, 0.007, 0.0785 + over, 0.091 + over, 0.0995 + over], [0.192, 0.0, 0.007, 0.0765 + over, 0.089 + over, 0.0975 + over]], 24, 1, "y", sit)
			m.put(head, cloth, "hat")
		"cap":
			m.tube([[0.170, 0.0, 0.007, 0.0835, 0.096, 0.1045], [0.212, 0.0, 0.007, 0.081, 0.094, 0.101], [0.248, 0.0, 0.009, 0.060, 0.070, 0.078],
					[0.262, 0.0, 0.011, 0.022, 0.026, 0.030]], 24, 3, "y", sit)
			m.blob(sit * Vector3(0.0, 0.176, -0.128), Vector3(0.068, 0.0055, 0.060), sit.basis * Basis(Vector3.RIGHT, 0.1), 14, 6)
			m.put(head, cloth, "hat")
	if kind == "knit_cap":
		trim.put(head, cloth)
	else:
		trim.put(head, band)


## Glasses: two rims, a bridge, arms back to the ears, their glass.
static func _glasses(head: Node3D, look: CharacterLook) -> void:
	var kind := look.option("glasses")
	if kind == "none":
		return
	var frame := M.new()
	var glass := M.new()
	var z := -0.0885
	var r := 0.0205
	for side: float in [-1.0, 1.0]:
		var c := Vector3(side * 0.0325, 0.1265, z)
		var rim: Array = []
		var radii: Array = []
		var n := 16
		for i in n + 1:
			var a := TAU * i / n
			var p := Vector2(cos(a), sin(a))
			if kind != "round": # (squarer: its corners out)
				var e := 0.55 if kind == "square" else 0.7
				p = Vector2(signf(p.x) * pow(absf(p.x), e), signf(p.y) * pow(absf(p.y), e)) * Vector2(1.08, 0.8)
			rim.append(c + Vector3(p.x, p.y, 0.0) * r)
			radii.append(0.0016)
		_strand(frame, rim, radii, 6)
		glass.blob(c, Vector3(r * (1.0 if kind == "round" else 1.06), r * (1.0 if kind == "round" else 0.8), 0.0009), Basis(), 14, 4)
		_strand(frame, [c + Vector3(side * r * 1.05, 0.004, 0.0), Vector3(side * 0.079, 0.130, -0.03), Vector3(side * 0.0815, 0.128, 0.022)], [0.0015, 0.0015, 0.0013], 6)
	_strand(frame, [Vector3(-0.0325 + r, 0.131, z), Vector3(0.0, 0.134, z - 0.002), Vector3(0.0325 - r, 0.131, z)], [0.0015, 0.0015, 0.0015], 6)
	frame.put(head, _plain(Color(0.08, 0.07, 0.07) if kind != "round" else Color(0.45, 0.36, 0.2), 0.35), "glasses")
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.03, 0.035, 0.04, 0.93) if kind == "sunglasses" else Color(0.8, 0.9, 0.95, 0.16)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.05
	gm.metallic_specular = 0.9
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.put(head, gm)
