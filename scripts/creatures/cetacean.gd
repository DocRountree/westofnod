class_name Cetacean
extends Node3D
## The whales and dolphins, life size, each one mesh (build) posed in
## shaders/render/cetacean.gdshader: a blue whale (BlueWhale), an orca
## (Orca), a common bottlenose dolphin (BottlenoseDolphin); species picks
## its own (SPECIES).
##
## A mammal of the sea: it swims by its flukes beating up and down (its body
## still before the tail, the beat all in the tail stock and flukes), and it
## breathes air: it must come up. Its air (o2) runs down under water; low,
## it rises, its blowhole out of the water, and blows: the spout (a blue
## whale's a column of mist nine metres up, an orca's a bushy few metres, a
## dolphin's a puff and a chuff), a few breaths, rolling at the surface, then
## down again (a blue whale's last before a deep dive, its flukes sometimes
## lifted clear). Its ways:
## - travelling (wander): about its water, now deep, now near the top; an
##   orca, a dolphin with its pod (the others of its kind near), keeping
##   together
## - feeding (feed / hunt): a blue whale lunging through a swarm of krill:
##   faster, rolled on its side, its jaws dropped open near a right angle,
##   its throat ballooning out (the pleats under its chin spread, the pouch
##   the size of its body) with the water and the krill in it, the jaws shut,
##   the water strained out through the baleen as the pouch goes down; an
##   orca after a tuna, a salmon, a seal-sized thing, a shark (rammed, held,
##   its liver; the shark left), a dolphin; a dolphin after fish, seized
## - breaching (breach): up from below, fast, out of the water, twisting
##   onto its side or back, falling back in a crash of spray
## - lobtailing (tail_slap): its head down, its flukes lifted out of the
##   water and slammed down on it, again and again
## - slapping its flipper (flipper_slap): rolled on its side at the
##   surface, the flipper up, brought down on the water
## - spyhopping (spyhop): its head up out of the water, looking about
## - porpoising (play: a dolphin's, an orca's): leaping clear as it goes, low
##   arcs, one after another
## - resting (sleep): logging at the surface, still, its back awash,
##   breathing slow
## - mating (mate): he beside her, then the two rolled belly to belly
## - calving (give_birth): her calf born tail first, then taken up to the
##   surface for its first breath; it keeps at her side after (echelon,
##   beside her flank, in her slipstream), up when she goes up and more
##   often, under her belly to nurse (nurse)
## - its calf (.new(true)): small, darker, its fins soft; it grows
## - dying (die): sinking slowly, rolled over

const SHADER := preload("res://shaders/render/cetacean.gdshader")

## Each species: its mesh's length (m: a grown one's, the larger sex's), and
## its parts as shares of that length; its body as rings: [s (0 the snout
## .. 1 the flukes' notch), its middle's height, half width, height above its
## middle, below]. gape_s: its mouth's corner along it; gape_a: its gape's
## line round it (rad from its back's middle); jaw: how far its lower jaw
## drops (rad).
const SPECIES := {
	"blue": {
		"name": "blue whale", "len": 24.0, "male_k": 0.94, "female_k": 1.0, "calf_k": 0.3,
		"body": [[0.0, 0.0, 0.0, 0.0, 0.0], [0.012, -0.003, 0.02, 0.006, 0.013], [0.04, -0.004, 0.035, 0.012, 0.024], [0.09, -0.004, 0.046, 0.019, 0.036],
			[0.16, -0.003, 0.053, 0.027, 0.046], [0.23, -0.001, 0.057, 0.035, 0.052], [0.32, 0.0, 0.06, 0.043, 0.057], [0.42, 0.0, 0.062, 0.047, 0.06],
			[0.52, 0.0, 0.06, 0.047, 0.058], [0.6, 0.0, 0.055, 0.045, 0.052], [0.7, 0.001, 0.045, 0.041, 0.042], [0.8, 0.002, 0.031, 0.034, 0.03],
			[0.88, 0.002, 0.018, 0.026, 0.019], [0.95, 0.002, 0.01, 0.014, 0.011], [1.0, 0.002, 0.006, 0.006, 0.005]],
		"gape_s": 0.215, "gape_a": 1.95, "jaw": 1.3, "eye_s": 0.225, "eye_a": 1.62, "eye_r": 0.0045, "blow_s": 0.19,
		"flipper": [0.3, 0.1, 0.022, 0.75], # (s, length, chord, how far down its side)
		"dorsal": [0.75, 0.013, 0.032, 0.65], # (s, height, base, falcate)
		"dorsal_m": [0.75, 0.013, 0.032, 0.65],
		"fluke": [0.25, 0.055], # (span, chord)
		"teeth": 0, "baleen": true, "pouch": true, "amp": 0.03, "cruise": 2.2, "air": 110.0, "breaths": 4, "spout": 9.0, "spout_spread": 6.0,
	},
	"orca": {
		"name": "orca", "len": 7.6, "male_k": 1.0, "female_k": 0.86, "calf_k": 0.33,
		"body": [[0.0, -0.006, 0.0, 0.0, 0.0], [0.015, -0.008, 0.03, 0.022, 0.028], [0.05, -0.006, 0.066, 0.056, 0.058], [0.1, -0.004, 0.09, 0.083, 0.084],
			[0.17, -0.002, 0.108, 0.1, 0.1], [0.26, 0.0, 0.12, 0.112, 0.113], [0.36, 0.0, 0.125, 0.118, 0.12], [0.46, 0.0, 0.121, 0.114, 0.116],
			[0.56, 0.0, 0.109, 0.103, 0.103], [0.66, 0.002, 0.088, 0.087, 0.083], [0.76, 0.004, 0.058, 0.071, 0.058], [0.85, 0.004, 0.03, 0.053, 0.033],
			[0.93, 0.003, 0.016, 0.03, 0.017], [1.0, 0.002, 0.008, 0.01, 0.008]],
		"gape_s": 0.11, "gape_a": 1.85, "jaw": 0.6, "eye_s": 0.125, "eye_a": 1.55, "eye_r": 0.006, "blow_s": 0.155,
		"flipper": [0.24, 0.13, 0.068, 0.7],
		"dorsal": [0.4, 0.12, 0.12, 0.75],
		"dorsal_m": [0.4, 0.24, 0.12, 0.08],
		"flipper_m": [0.24, 0.17, 0.085, 0.7],
		"fluke": [0.28, 0.075],
		"teeth": 12, "tooth": 0.009, "baleen": false, "pouch": false, "amp": 0.045, "cruise": 2.6, "air": 50.0, "breaths": 3, "spout": 3.5, "spout_spread": 12.0,
	},
	"dolphin": {
		"name": "bottlenose dolphin", "len": 2.6, "male_k": 1.0, "female_k": 0.95, "calf_k": 0.42,
		"body": [[0.0, -0.012, 0.007, 0.005, 0.006], [0.025, -0.013, 0.017, 0.012, 0.015], [0.055, -0.011, 0.024, 0.018, 0.021], [0.075, -0.012, 0.036, 0.046, 0.031],
			[0.11, -0.008, 0.054, 0.07, 0.05], [0.17, -0.004, 0.074, 0.084, 0.07], [0.25, 0.0, 0.087, 0.094, 0.085], [0.35, 0.0, 0.094, 0.099, 0.094],
			[0.45, 0.0, 0.091, 0.097, 0.091], [0.55, 0.0, 0.081, 0.089, 0.08], [0.65, 0.002, 0.063, 0.077, 0.06], [0.75, 0.003, 0.042, 0.062, 0.04],
			[0.84, 0.003, 0.024, 0.046, 0.024], [0.92, 0.002, 0.013, 0.026, 0.013], [1.0, 0.002, 0.006, 0.008, 0.006]],
		"gape_s": 0.1, "gape_a": 1.75, "jaw": 0.55, "eye_s": 0.118, "eye_a": 1.55, "eye_r": 0.008, "blow_s": 0.15,
		"flipper": [0.2, 0.15, 0.05, 0.65],
		"dorsal": [0.45, 0.1, 0.12, 0.7],
		"dorsal_m": [0.45, 0.1, 0.12, 0.7],
		"fluke": [0.26, 0.07],
		"teeth": 22, "tooth": 0.004, "baleen": false, "pouch": false, "amp": 0.055, "cruise": 2.2, "air": 28.0, "breaths": 1, "spout": 0.7, "spout_spread": 30.0,
	},
}

var species := "dolphin"
var male := false
var young := false
var size := 1.0 ## (the node's scale: 1 its species' mesh)
var tank_min := Vector3(-40.0, -20.0, -25.0) ## the water (its parent's space): the bottom's corner
var tank_max := Vector3(40.0, -0.004, 25.0) ## and the surface's
var hunger := 0.5
var dead := false
var mother: Node3D
var calves: Array[Node3D] = []
var grow_secs := 1200.0 ## (a calf's: to a juvenile's size)
var o2 := 1.0 ## (its air: 1 full)
var weaned := true ## (a calf's: off on its own once it's weaned)
var juvenile := false

## (A calf's time to grow up, here; each weaned at about half grown, grown
## and able to breed at full size.)
const GROW := {"blue": 1500.0, "orca": 1800.0, "dolphin": 1200.0}



var _pos := Vector3.ZERO
var _fwd := Vector3.FORWARD
var _spd := 1.0
var _want := 1.0
var _roll := 0.0
var _roll_to := 0.0
var _phase := 0.0
var _bend := 0.0
var _mode := "travel"
var _t := 0.0
var _goal := Vector3.ZERO
var _goal_t := 0.0
var _vel := Vector3.ZERO
var _air := false
var _prey: Node3D
var _prey_i := -1
var _held: Node3D
var _partner: Node3D
var _then := ""
var _secs := 0.0
var _n := 0
var _age := 0.0
var _pod_t := 0.0
var _pod_at := Vector3.INF
var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _pose := {"jaw": 0.0, "pouch": 0.0, "flip": 0.0, "slam": 0.0, "arch": 0.0}
var _pose_to := {}
var rng := RandomNumberGenerator.new()
static var _built := {}


func _init(young_ := false) -> void:
	young = young_
	rng.randomize()


func S() -> Dictionary:
	return SPECIES[species]


func _ready() -> void:
	var sp: Dictionary = S()
	grow_secs = float(GROW[species])
	if young:
		size = float(sp.calf_k)
		weaned = false
		if juvenile: # (weaned, on its own, about half grown)
			size = lerpf(float(sp.calf_k), _adult_k(), rng.randf_range(0.45, 0.65))
			weaned = true
		elif mother == null:
			size *= rng.randf_range(1.0, 1.4)
	else:
		size = float(sp.male_k) if male else float(sp.female_k)
	_mi = MeshInstance3D.new()
	_mat = ShaderMaterial.new()
	_set_mesh()
	_mat.shader = SHADER
	_mat.set_shader_parameter("species", ["blue", "orca", "dolphin"].find(species))
	_mat.set_shader_parameter("tl", float(sp.len))
	_mat.set_shader_parameter("amp", float(sp.amp) * float(sp.len))
	_mat.set_shader_parameter("jaw_max", float(sp.jaw))
	_mat.set_shader_parameter("calf", 1.0 - _grown() if young else 0.0)
	_mat.set_shader_parameter("seed", rng.randf())
	_mat.set_shader_parameter("scars", 0.0 if young else rng.randf_range(0.2, 1.0))
	_mi.material_override = _mat
	var L := float(sp.len)
	_mi.custom_aabb = AABB(Vector3(-L * 0.35, -L * 0.3, -L * 0.6), Vector3(L * 0.7, L * 0.6, L * 1.2))
	add_child(_mi)
	scale = Vector3.ONE * size
	_pos = position
	_goal = _pos
	_pose_to = _pose.duplicate()
	_spd = _cruise()
	o2 = rng.randf_range(0.5, 1.0)


## (Its mesh: its kind's and sex's; a calf's its mother's sort till grown: a
## young male orca's fin grows tall only as he comes of age.)
func _set_mesh() -> void:
	var key := species + ("_m" if male and not young else "_f")
	if not _built.has(key):
		_built[key] = build(species, male and not young)
	var B: Array = _built[key]
	_mi.mesh = B[0]
	_mat.set_shader_parameter("jaw_pivot", B[1])
	_mat.set_shader_parameter("flip_root", B[2])


func _adult_k() -> float:
	return float(S().male_k) if male else float(S().female_k)


## (A calf's: how grown, 0 born .. 1 its full size.)
func _grown() -> float:
	var sp: Dictionary = S()
	return clampf((size - float(sp.calf_k)) / maxf(_adult_k() - float(sp.calf_k), 0.01), 0.0, 1.0)


## (A calf come of age: grown, able to breed; its own sex's fins.)
func _mature() -> void:
	young = false
	juvenile = false
	weaned = true
	mother = null
	size = _adult_k()
	_set_mesh()
	_mat.set_shader_parameter("calf", 0.0)
	_mat.set_shader_parameter("scars", rng.randf_range(0.1, 0.4))


func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	position = at
	_fwd = Vector3(-sin(yaw), 0.0, -cos(yaw))
	_goal = at


func set_water(lo: Vector3, hi: Vector3) -> void:
	tank_min = lo
	tank_max = hi


func _len() -> float:
	return float(S().len) * size


func _cruise() -> float:
	return float(S().cruise) * (0.7 if young else 1.0) * clampf(sqrt(size), 0.6, 1.1)


## (A point of its mesh, where it is now: its parent's space.)
func _at(local: Vector3) -> Vector3:
	return _pos + basis * local


## Its mouth's middle, its blowhole's (the mesh's).
func _mouth_local() -> Vector3:
	var sp: Dictionary = S()
	return _skin(sp, float(sp.gape_s) * 0.35, PI) * Vector3(0.0, 0.6, 1.0)


func _blow_local() -> Vector3:
	var sp: Dictionary = S()
	return _skin(sp, float(sp.blow_s), 0.0)


func mouth() -> Vector3:
	return _at(_mouth_local())


## Its top above its middle at its blowhole (m: its own size's).
func _top() -> float:
	var sp: Dictionary = S()
	var k := _key(sp, float(sp.blow_s))
	return (k.x + k.z) * float(sp.len) * size


# --- its ways -------------------------------------------------------------------------------

func _to(mode: String) -> void:
	_mode = mode
	_t = 0.0
	_roll_to = 0.0
	_pose_to.flip = 0.0
	_pose_to.slam = 0.0
	_pose_to.arch = 0.0
	if mode not in ["lunge", "filter"]:
		_pose_to.jaw = 0.0
		_pose_to.pouch = 0.0


func wander() -> void:
	if dead or _air:
		return
	_prey = null
	if young and mother != null and is_instance_valid(mother) and not mother.get("dead"):
		_to("follow")
		return
	_to("travel")
	_goal_t = 0.0


func travel() -> void:
	wander()


## To feed: a blue whale on the krill swarm given; a hunter on its prey (a
## school: the fish of it nearest; a creature).
func feed(prey: Node3D) -> void:
	hunt(prey)


func hunt(prey: Node3D) -> void:
	if dead or _air or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	_prey_i = -1
	if species == "blue":
		_to("lunge_to")
		return
	if prey.has_method("nearest") and prey.get("count") == null: # (a school of fish: one of it)
		var k: Variant = prey.call("nearest", _pos)
		if typeof(k) == TYPE_INT:
			_prey_i = int(k)
			if _prey_i < 0:
				_prey = null
				return
	if prey.has_method("flee") and _prey_i < 0: # (it knows: off, fast)
		prey.call("flee", _pos)
	_to("chase")


func breach() -> void:
	if dead or _air:
		return
	_prey = null
	_to("breach_down")


func tail_slap() -> void:
	if dead or _air:
		return
	_to("lobtail")


func flipper_slap() -> void:
	if dead or _air:
		return
	_to("pecslap")


func spyhop() -> void:
	if dead or _air:
		return
	_to("spyhop")


func play() -> void:
	if dead or _air:
		return
	if species == "blue":
		breach()
		return
	_n = rng.randi_range(3, 6)
	_to("porpoise")


func sleep(secs := 40.0) -> void:
	if dead or _air:
		return
	_secs = secs
	_to("log")


func rest(secs := 40.0) -> void:
	sleep(secs)


## (A male's.) Beside her, then rolled under her, belly to belly.
func mate(female: Node3D) -> bool:
	if not male and female != null and is_instance_valid(female) and female.get("male"): # (hers: him to court her)
		return bool(female.call("mate", self))
	if not male or young or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead") or female.get("species") != species:
		return false
	_partner = female
	o2 = 1.0 # (a breath first: the two of them, the courtship long)
	female.set("o2", 1.0)
	female.set("_partner", self)
	female.call("_to", "courted")
	_to("court")
	return true


## (A female's.) Her calf, born tail first; then up with it for its first breath.
func give_birth(_n_ := 1) -> void:
	if male or young or dead or _air:
		return
	_to("birth")


## (A calf's.) Under her belly, to nurse a while.
func nurse() -> void:
	if not young or weaned or mother == null or not is_instance_valid(mother):
		return
	_to("nurse")


func die() -> void:
	if dead:
		return
	dead = true
	_to("dead")


func flee(from: Vector3) -> void:
	if dead or _air:
		return
	var away := _pos - from
	away.y = 0.0
	_goal = _inside(_pos + (away.normalized() if away.length() > 0.1 else _fwd) * _len() * 6.0)
	_to("flee")


func behaviours() -> PackedStringArray:
	return PackedStringArray(["wander", "feed", "breach", "tail_slap", "flipper_slap", "spyhop", "play", "sleep", "mate", "give_birth", "nurse"])


func is_busy() -> bool:
	return _mode not in ["travel", "follow"]


func _p_here() -> Vector3:
	return _pos


# --- the motor --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	if _mi == null:
		return
	_t += dt
	_age += dt
	var sp: Dictionary = S()
	if young and not dead: # (a calf growing: weaned at about half grown, off on its own; grown, of age)
		size = minf(size + dt * (_adult_k() - float(sp.calf_k)) / grow_secs, _adult_k())
		_mat.set_shader_parameter("calf", 1.0 - _grown())
		if not weaned and _grown() > 0.45:
			weaned = true
			juvenile = true
			if _mode in ["follow", "nurse"]:
				mother = null
				_to("travel")
			mother = null
		if _grown() >= 0.999:
			_mature()

	hunger = minf(hunger + dt / 500.0, 1.0)
	# its air: running down below, back at the surface
	if not dead:
		var at_top := _pos.y > tank_max.y - _top() * 1.15
		if at_top and _mode in ["blow", "log", "spyhop", "lobtail", "pecslap", "first_breath"]:
			o2 = minf(o2 + dt / (3.0 if young else 6.0), 1.0)
		elif not _air:
			o2 = maxf(o2 - dt / (float(sp.air) * (0.55 if young else 1.0)), 0.0)
	if _air:
		_fly(dt)
	else:
		_think(dt)
		_swim(dt)
	_pose_step(dt)
	var f := _fwd.normalized()
	var up := Vector3.UP if absf(f.y) < 0.97 else Vector3.BACK
	var b := Basis.looking_at(f, up)
	_roll = move_toward(_roll, _roll_to, dt * 1.2)
	b = Basis(f, -_roll) * b
	transform = Transform3D(b.scaled(Vector3.ONE * size), _pos)
	# the beat: slower in a bigger body, faster and deeper the faster it swims
	var spn := clampf(_spd / maxf(_cruise() * 3.0, 0.1), 0.0, 1.0)
	_phase += dt * TAU * (0.35 + 1.4 * spn) / pow(maxf(_len() / 2.6, 0.3), 0.45) * (1.0 if not _air else 0.3)
	_mat.set_shader_parameter("phase", _phase)
	_mat.set_shader_parameter("amp", float(sp.amp) * float(sp.len) * (0.6 + 0.8 * spn) * (0.2 if _mode in ["log", "dead", "spyhop"] else 1.0))
	_mat.set_shader_parameter("bend", _bend)
	for k: String in _pose:
		_mat.set_shader_parameter(k, _pose[k])


func _pose_step(dt: float) -> void:
	for key: String in _pose:
		var r := 2.5
		if key == "slam":
			r = 9.0
		elif key == "pouch" and float(_pose_to.pouch) < float(_pose[key]):
			r = 0.35 # (the pouch going down slowly: the water strained out)
		elif key == "jaw":
			r = 1.8
		_pose[key] = lerpf(float(_pose[key]), float(_pose_to.get(key, _pose[key])), 1.0 - exp(-r * dt))


func _depth_goal(f: float) -> float:
	return lerpf(tank_min.y + _len() * 0.12, tank_max.y - _top() * 2.0, f)


func _think(dt: float) -> void:
	var L := _len()
	var lo := tank_min
	var hi := tank_max
	var surf_y := hi.y - _top() * 0.75 # (its middle, its blowhole just out)
	# its air low: up (from all but what can't be left)
	if o2 < 0.22 and not dead and _mode in ["travel", "follow", "chase", "lunge_to", "court", "courted", "flee", "nurse"]:
		_then = _mode if _mode in ["chase", "lunge_to"] else ""
		_to("rise")
	match _mode:
		"travel":
			_want = _cruise()
			for k: Node3D in calves:
				if is_instance_valid(k) and String(k.get("_mode")) == "nurse": # (slow for her calf, nursing)
					_want = _cruise() * 0.45
			_goal_t -= dt
			if _goal_t <= 0.0 or _pos.distance_to(_goal) < L * 0.8:
				_goal_t = rng.randf_range(10.0, 25.0)
				_goal = _inside(Vector3(rng.randf_range(lo.x, hi.x), _depth_goal(rng.randf_range(0.25, 0.95)), rng.randf_range(lo.z, hi.z)))
			if species != "blue": # (with its pod)
				_pod_t -= dt
				if _pod_t <= 0.0:
					_pod_t = 2.0
					_pod_at = _pod_middle()
				if _pod_at != Vector3.INF and _pod_at.distance_to(_pos) > L * 2.5:
					_goal = _goal.lerp(_pod_at, 0.5)
		"follow": # (a calf at its mother's side: beside her flank, in her slipstream; up when she's up)
			if mother == null or not is_instance_valid(mother) or mother.get("dead"):
				mother = null
				_to("travel")
				return
			var ms: float = float(mother.get("size"))
			var ml := float(S().len) * ms
			var side := 1.0 if (get_instance_id() % 2) == 0 else -1.0
			_goal = mother.call("_at", Vector3(side * ml * 0.11, ml * 0.035, ml * 0.02))
			var mspd: float = float(mother.get("_spd"))
			_want = clampf(mspd + (_pos.distance_to(_goal) - L * 0.1) * 0.8, 0.2, _cruise() * 2.5)
			if String(mother.get("_mode")) in ["blow", "log"] and o2 < 0.7: # (up when she's up)
				_to("rise")
			elif _t > 20.0 and rng.randf() < dt / (15.0 + 40.0 * _grown()): # (nursing: often while small)
				nurse()
		"nurse": # (under her belly, at her mammary slits, a few seconds)
			if mother == null or not is_instance_valid(mother):
				_to("travel")
				return
			var ml := float(S().len) * float(mother.get("size"))
			_goal = mother.call("_at", Vector3(0.0, -ml * 0.09, ml * 0.17))
			_want = clampf(float(mother.get("_spd")) + (_pos.distance_to(_goal) - L * 0.05), 0.2, _cruise() * 2.0)
			_roll_to = 0.4
			if _t > 9.0:
				_to("follow")
		"rise": # (up to breathe)
			_goal = Vector3(_pos.x + _fwd.x * L * 2.0, surf_y, _pos.z + _fwd.z * L * 2.0)
			_goal = _inside(_goal)
			_goal.y = surf_y
			_want = _cruise() * 1.2
			if absf(_pos.y - surf_y) < L * 0.03 + 0.05:
				_n = int(S().breaths) if not young else 2
				_to("blow")
				_blow()
		"blow": # (at the surface: a breath, a few seconds' roll along it, the next)
			_goal = Vector3(_pos.x + _fwd.x * L * 3.0, surf_y, _pos.z + _fwd.z * L * 3.0)
			_goal = _inside(_goal)
			_goal.y = surf_y
			_want = _cruise() * 0.7
			var gap := 5.0 if species == "blue" else (2.5 if species == "orca" else 1.5)
			if _t > gap:
				_n -= 1
				if _n > 0:
					_t = 0.0
					_blow()
				else:
					o2 = 1.0
					_to("sound")
		"sound": # (down again: a blue whale's flukes, now and then, lifted clear)
			_want = _cruise()
			var down := _depth_goal(rng.randf_range(0.1, 0.5)) if _t < 0.1 else _goal.y
			if _t < 0.1:
				_goal = _inside(Vector3(_pos.x + _fwd.x * L * 4.0, down, _pos.z + _fwd.z * L * 4.0))
				_secs = 1.0 if (species == "blue" and rng.randf() < 0.35) else 0.0
			_pose_to.arch = _secs * (smoothstep(0.0, 1.5, _t) - smoothstep(4.0, 6.0, _t))
			if _t > 6.0 or _pos.y < hi.y - L * 0.35:
				if _then != "":
					var th := _then
					_then = ""
					_to(th)
				else:
					wander()
		"log": # (resting at the surface: still, its back awash, breathing slow)
			_goal = _pos + _fwd * 0.5
			_goal.y = hi.y - _top() * 0.55
			_want = 0.05
			if fmod(_t, 12.0 if species == "blue" else 7.0) < dt:
				_blow()
			if _t > _secs:
				wander()
		"chase": # (after it, fast; seized)
			var pp := _prey_pos()
			if pp == Vector3.INF:
				wander()
				return
			_goal = pp
			_want = _cruise() * (3.2 if species == "dolphin" else 3.0)
			if mouth().distance_to(pp) < L * 0.18 + 0.15:
				_seize()
				_to("eat")
			elif _t > 25.0:
				wander()
		"eat": # (its prey held, shaken, torn, swallowed; a shark let go, dead)
			_want = _cruise() * 0.5
			_pose_to.jaw = 0.35 + 0.25 * sin(_t * 6.0)
			_bend = 0.5 * sin(_t * 7.0) * (1.0 - smoothstep(2.0, 3.0, _t))
			if _t > 5.0:
				if _held and is_instance_valid(_held):
					if _held is GreatWhiteShark: # (its liver: the rest let go, sinking)
						_held.remove_meta("taken")
						_held = null
					else:
						_held.queue_free()
				_held = null
				hunger = maxf(hunger - 0.5, 0.0)
				wander()
		"lunge_to": # (a blue whale to the swarm: from below and beside it)
			var c := _swarm_at()
			if c == Vector3.INF:
				wander()
				return
			var d := c - _pos
			_goal = c - d.normalized() * L * 0.3
			_want = _cruise() * 1.2
			if d.length() < L * 0.9:
				_to("lunge")
		"lunge": # (faster; rolled on its side; the jaws dropped wide, the throat ballooning: krill and water in; shut)
			var c := _swarm_at()
			if c != Vector3.INF:
				_goal = c + _fwd * L * 0.5
			_want = _cruise() * 2.2
			_roll_to = 1.3
			if _t > 0.6:
				_pose_to.jaw = 1.0
			if _t > 1.2:
				_pose_to.pouch = 1.0
			if _t > 1.2 and _t < 3.0 and _prey and is_instance_valid(_prey) and _prey.has_method("engulf"):
				var got := int(_prey.call("engulf", _prey.to_local(get_parent().to_global(mouth())), L * 0.18))
				if got > 0:
					hunger = maxf(hunger - got / 3000.0, 0.0)
			if _t > 3.0:
				_pose_to.jaw = 0.0
				_want = _cruise() * 0.4
			if _t > 4.5:
				_to("filter")
		"filter": # (the jaws shut, the pouch going down: the water strained out through the baleen; the krill swallowed)
			_want = _cruise() * 0.4
			_pose_to.pouch = 0.0
			_pose_to.jaw = 0.04
			_roll_to = 0.0
			_goal = _inside(_pos + _fwd * L * 2.0)
			if _t > 9.0:
				_pose_to.jaw = 0.0
				wander()
		"breach_down": # (down, to come up fast)
			_goal = _inside(Vector3(_pos.x + _fwd.x * L, lo.y + L * 0.15, _pos.z + _fwd.z * L))
			_want = _cruise() * 1.2
			if _pos.y < lerpf(lo.y, hi.y, 0.4) or _t > 10.0:
				_to("breach_up")
		"breach_up":
			_goal = Vector3(_pos.x + _fwd.x * L * 0.3, hi.y + L, _pos.z + _fwd.z * L * 0.3)
			_want = _cruise() * (3.5 if species != "blue" else 3.0)
			if _pos.y > hi.y - L * 0.3 and _fwd.y > 0.5:
				_launch(1.0)
			elif _t > 12.0:
				wander()
		"porpoise": # (leaping clear as it goes, low arcs)
			_goal = _inside(_pos + _fwd * L * 4.0 + Vector3(0.0, 0.0, 0.0))
			_goal.y = hi.y - _top() * 1.3
			_want = _cruise() * 2.6
			if _pos.y > hi.y - _top() * 2.0 and _t > 1.0:
				_n -= 1
				_launch(0.45)
				if _n <= 0:
					_then = "travel"
		"lobtail": # (its head down, its flukes up out of the water, slammed down, again)
			var tilt := minf(_t / 2.0, 1.0)
			var flat := Vector3(_fwd.x, 0.0, _fwd.z).normalized() if Vector2(_fwd.x, _fwd.z).length() > 0.05 else Vector3.FORWARD
			_fwd = flat * lerpf(1.0, 0.45, tilt) + Vector3(0.0, -lerpf(0.0, 0.9, tilt), 0.0)
			_fwd = _fwd.normalized()
			_pos.y = move_toward(_pos.y, hi.y - L * 0.22, dt * L * 0.15)
			_goal = _pos + _fwd
			_want = 0.0
			if _t > 2.0:
				var beat := fmod(_t - 2.0, 2.2)
				_pose_to.slam = 1.0 if beat < 1.2 else -0.3
				if beat > 1.2 and beat - dt <= 1.2:
					_splash(_at(Vector3(0.0, 0.0, float(S().len) * 0.48)), clampf(L / 8.0, 0.5, 2.2))
			if _t > 11.0:
				_fwd = flat
				wander()
		"pecslap": # (rolled on its side, its flipper up out of the water, brought down)
			_goal = _inside(_pos + _fwd * L)
			_goal.y = hi.y - _top() * 0.5
			_want = _cruise() * 0.3
			_roll_to = 1.45
			if _t > 2.5:
				var beat := fmod(_t - 2.5, 1.8)
				_pose_to.flip = 1.0 if beat < 1.0 else -0.4
				if beat > 1.0 and beat - dt <= 1.0:
					_splash(_at(Vector3(float(S().flipper[1]) * float(S().len) * 0.7, 0.0, -float(S().len) * 0.2)), clampf(L / 12.0, 0.3, 1.2))
			if _t > 12.0:
				wander()
		"spyhop": # (its head up out of the water, looking about)
			var top := hi.y
			if _t < 5.0 and _pos.y < top - L * 0.6:
				_goal = Vector3(_pos.x + _fwd.x * 0.2, top + 1.0, _pos.z + _fwd.z * 0.2)
				_want = _cruise() * 0.8
			else:
				_fwd = _fwd.slerp(Vector3(_fwd.x * 0.05, 1.0, _fwd.z * 0.05).normalized(), minf(dt * 1.2, 1.0))
				_pos.y = move_toward(_pos.y, top - L * 0.22 + 0.06 * L * sin(_t * 0.8), dt * L * 0.12)
				_want = 0.0
				_goal = _pos + _fwd
				_fwd = _fwd.rotated(Vector3.UP, dt * 0.3 * sin(_t * 0.5))
				if _t > 12.0:
					_fwd = Vector3(_fwd.x, -0.4, _fwd.z).normalized()
					wander()
		"flee":
			_want = _cruise() * 3.0
			if _pos.distance_to(_goal) < L or _t > 10.0:
				wander()
		"court": # (courting her, his kind's way; then under her, belly to belly)
			if _partner == null or not is_instance_valid(_partner):
				wander()
				return
			var pl := float(S().len) * float(_partner.get("size"))
			var pf: Vector3 = _partner.get("_fwd")
			if _t < 16.0:
				match species:
					"dolphin": # (beside her, close, in step; rubbing along her, his flipper on her side, rolled to her)
						var near := 0.08 + 0.06 * (0.5 + 0.5 * sin(_t * 0.8))
						_goal = _partner.call("_at", Vector3(pl * near * 2.0, pl * 0.01, pl * 0.02))
						_want = float(_partner.get("_spd")) + (_pos.distance_to(_goal) - L * 0.05) * 0.8
						_fwd = _fwd.slerp(pf, minf(dt * 1.0, 1.0)).normalized()
						_roll_to = -0.75
						_pose_to.flip = 0.35 + 0.25 * sin(_t * 2.0)
					"orca": # (at the surface with her, rolling, his flipper raised, slapped down)
						_goal = _partner.call("_at", Vector3(pl * 0.2, 0.0, -pl * 0.05))
						_goal.y = hi.y - _top() * 0.6
						_want = float(_partner.get("_spd")) + (_pos.distance_to(_goal) - L * 0.2) * 0.5
						_roll_to = 1.3 * (0.5 + 0.5 * sin(_t * 0.7))
						_pose_to.flip = 1.0 if fmod(_t, 4.0) < 2.0 else -0.4
						if fmod(_t, 4.0) > 2.0 and fmod(_t, 4.0) - dt <= 2.0:
							_splash(_at(Vector3(float(S().flipper[1]) * float(S().len) * 0.7, 0.0, -float(S().len) * 0.2)), 0.6)
					_: # (a blue whale: following her close, behind and below, for a long while)
						_goal = _partner.call("_at", Vector3(0.0, -pl * 0.05, pl * 0.65))
						_want = float(_partner.get("_spd")) + (_pos.distance_to(_goal) - L * 0.1) * 0.3
			else: # (rolled under her, belly to belly)
				var under: Vector3 = _partner.call("_at", Vector3(0.0, -pl * 0.13, pl * 0.06))
				_pos = _pos.lerp(under, minf(dt * 1.0, 1.0))
				_fwd = _fwd.slerp(pf, minf(dt * 2.0, 1.0)).normalized()
				_goal = _pos + _fwd * 3.0
				_want = float(_partner.get("_spd"))
				_roll_to = PI
				_pose_to.flip = 0.0
			if _t > 32.0:
				_partner.call("wander")
				_partner.set("_partner", null)
				_partner = null
				wander()
		"courted": # (hers: slow; an orca's at the surface rolling, a dolphin's rolled to him)
			_goal_t -= dt
			if _goal_t <= 0.0 or _pos.distance_to(_goal) < L:
				_goal_t = 8.0
				_goal = _inside(_pos + _fwd * L * 3.0 + Vector3(rng.randf_range(-L, L), 0.0, rng.randf_range(-L, L)))
				_goal.y = _depth_goal(0.8)
			_want = _cruise() * 0.6
			var mt := float(_partner.get("_t")) if _partner and is_instance_valid(_partner) else 0.0
			if species == "orca" and mt < 16.0:
				_goal.y = hi.y - _top() * 0.6
				_roll_to = PI * 0.8 * (0.5 + 0.5 * sin(_t * 0.5)) # (over on her back, and back again)
				_pose_to.flip = 0.6 * sin(_t * 1.3)
			elif species == "dolphin" and mt < 16.0:
				_roll_to = 0.75
			if _t > 45.0 or _partner == null or not is_instance_valid(_partner):
				wander()
		"birth": # (slow, near the top; her calf out tail first)
			_goal = _inside(_pos + _fwd * L * 2.0)
			_goal.y = _depth_goal(0.85)
			_want = _cruise() * 0.4
			if _t > 6.0:
				var c := _bear_one()
				_secs = 0.0
				_prey = c
				_to("escort")
		"escort": # (her calf up to the surface for its first breath, her beside it, under it)
			var c: Node3D = _prey
			if c == null or not is_instance_valid(c):
				wander()
				return
			_goal = c.call("_at", Vector3(0.0, -float(S().len) * float(c.get("size")) * 0.15, 0.0))
			_want = maxf(float(c.get("_spd")), _cruise() * 0.4)
			if String(c.get("_mode")) == "follow" or _t > 30.0:
				_prey = null
				wander()
		"first_breath": # (a newborn: straight up, its first breath)
			_goal = Vector3(_pos.x + _fwd.x, surf_y, _pos.z + _fwd.z)
			_want = _cruise() * 0.9
			if absf(_pos.y - surf_y) < L * 0.05 + 0.05:
				_blow()
				o2 = 1.0
				_to("follow")
		"dead": # (sinking, rolled over)
			_want = 0.0
			_goal = _pos + _fwd
			_roll_to = PI
			_pose_to.jaw = 0.25
			_pos.y = maxf(_pos.y - dt * 0.12, lo.y + _top() * 0.8)


## The middle of the others of its kind within its reach (its pod's), or INF.
func _pod_middle() -> Vector3:
	var m := Vector3.ZERO
	var n := 0
	for o in get_parent().get_children():
		if o is Cetacean and o != self and String(o.get("species")) == species and not o.get("dead") and (o as Node3D).position.distance_to(_pos) < _len() * 12.0:
			m += o.get("_pos")
			n += 1
	return m / n if n > 0 else Vector3.INF


func _swarm_at() -> Vector3:
	if _prey == null or not is_instance_valid(_prey) or int(_prey.get("count")) <= 0:
		return Vector3.INF
	return get_parent().to_local(_prey.to_global(_prey.call("middle")))


## Toward _goal at _want: a big body turning slow; kept in its water.
func _swim(dt: float) -> void:
	var L := _len()
	var to := _goal - _pos
	var want_dir := to.normalized() if to.length() > 0.01 else _fwd
	if _mode not in ["spyhop", "breach_up", "lobtail", "dead", "first_breath"]:
		want_dir.y = clampf(want_dir.y, -0.5, 0.5)
		want_dir = want_dir.normalized()
	var ahead := _pos + _fwd * (L * 0.6 + _spd * 1.5)
	var inner := _inside(ahead)
	if _mode in ["spyhop", "breach_up", "lobtail"]:
		inner.y = ahead.y
	if inner.distance_to(ahead) > 0.01:
		want_dir = (want_dir + (inner - ahead).normalized() * 2.0).normalized()
	var rate := (1.6 if species == "dolphin" else (1.0 if species == "orca" else 0.35)) * (1.6 if young else 1.0) / maxf(0.6 + _spd * 0.12, 0.5)
	if _mode in ["chase", "breach_up", "lunge"]:
		rate *= 1.6
	if _mode == "lobtail":
		rate = 0.0
	var ang := _fwd.angle_to(want_dir)
	var turned := _fwd
	if ang > 1e-4 and rate > 0.0:
		var axis := _fwd.cross(want_dir)
		if axis.length() < 1e-5:
			axis = Vector3.UP
		turned = _fwd.rotated(axis.normalized(), minf(ang, rate * dt))
	var side := _fwd.cross(Vector3.UP)
	var yaw_rate := (turned - _fwd).dot(side.normalized() if side.length() > 0.01 else Vector3.RIGHT) / maxf(dt, 1e-4)
	_bend = lerpf(_bend, clampf(-yaw_rate * 1.0, -1.0, 1.0), minf(dt * 3.0, 1.0))
	_fwd = turned.normalized()
	_spd = move_toward(_spd, _want, dt * (2.0 if _want > _spd else 1.0) * clampf(8.0 / L, 0.3, 2.0))
	_pos += _fwd * _spd * dt
	var m := L * 0.1
	_pos.x = clampf(_pos.x, tank_min.x + m, tank_max.x - m)
	_pos.z = clampf(_pos.z, tank_min.z + m, tank_max.z - m)
	var top_room := _top() * (0.5 if _mode in ["rise", "blow", "log", "first_breath", "pecslap", "porpoise", "breach_up"] else 1.4)
	if _mode in ["spyhop", "lobtail", "breach_up"]:
		top_room = -L
	_pos.y = clampf(_pos.y, tank_min.y + _top() * 0.9, tank_max.y - top_room)


func _inside(p: Vector3) -> Vector3:
	var L := _len()
	var mx := minf(L * 0.7, (tank_max.x - tank_min.x) * 0.4)
	var mz := minf(L * 0.7, (tank_max.z - tank_min.z) * 0.4)
	return Vector3(clampf(p.x, tank_min.x + mx, tank_max.x - mx), clampf(p.y, tank_min.y + _top() * 1.2, tank_max.y - _top() * 0.5), clampf(p.z, tank_min.z + mz, tank_max.z - mz))


# --- its prey -----------------------------------------------------------------------------

func _prey_pos() -> Vector3:
	if _prey == null or not is_instance_valid(_prey):
		return Vector3.INF
	if _prey_i >= 0:
		var ps: PackedVector3Array = _prey.get("pos")
		var tk: PackedInt32Array = _prey.get("task")
		if _prey_i >= ps.size() or tk[_prey_i] == 6:
			return Vector3.INF
		return get_parent().to_local(_prey.to_global(ps[_prey_i]))
	return Diet._at(_prey)


func _seize() -> void:
	if _prey_i >= 0 and _prey.has_method("take"):
		_held = _prey.call("take", _prey_i)
		_prey_i = -1
	elif _prey and is_instance_valid(_prey):
		if _prey.has_method("die"):
			_prey.call("die")
		_held = _prey
	_prey = null
	if _held:
		_held.set_meta("taken", true)


func _physics_process(_dt: float) -> void:
	if _held and is_instance_valid(_held):
		var m: Vector3 = get_parent().to_global(mouth())
		_held.global_position = m
		if _held is GreatWhiteShark:
			_held.set("_pos", _held.get_parent().to_local(m))
			_held.set("_fwd", _fwd.cross(Vector3.UP).normalized() if _fwd.cross(Vector3.UP).length() > 0.1 else Vector3.RIGHT)


# --- the air: breaching, porpoising -----------------------------------------------------------

func _launch(k: float) -> void:
	_air = true
	_vel = _fwd * maxf(_spd, _cruise() * 2.5)
	var lift := sqrt(2.0 * 9.8 * clampf(_len() * 0.55 * k, 0.4, 9.0)) # (enough to clear the water: most of its length, a whale's; a low arc, porpoising)
	_vel.y = maxf(_vel.y, lift)
	_splash(_at(Vector3(0.0, 0.0, -float(S().len) * 0.4)), clampf(_len() / 10.0, 0.3, 2.0) * k)
	_secs = k
	_then = _mode
	_mode = "air"
	_t = 0.0
	_roll_to = (rng.randf_range(1.2, 2.2) * (1.0 if rng.randf() < 0.5 else -1.0)) if k > 0.7 else 0.0


func _fly(dt: float) -> void:
	_t += dt
	_vel.y -= 9.8 * dt
	_pos += _vel * dt
	_fwd = _fwd.slerp(_vel.normalized(), minf(dt * 2.0, 1.0)).normalized()
	if _vel.y < 0.0 and _pos.y < tank_max.y - _top() * 0.5:
		_air = false
		_splash(_pos + Vector3(0.0, tank_max.y - _pos.y, 0.0), clampf(_len() / 7.0, 0.4, 3.0) * (_secs if _secs < 0.7 else 1.5))
		_spd = _vel.length() * 0.6
		_fwd = Vector3(_fwd.x, clampf(_fwd.y, -0.6, -0.1), _fwd.z).normalized()
		_roll_to = 0.0
		var th := _then
		_then = ""
		if th == "porpoise" and _n > 0:
			_mode = "porpoise"
			_t = 0.0
		else:
			wander()


## Its breath: the spout from its blowhole, a column of mist (its kind's).
func _blow() -> void:
	var sp: Dictionary = S()
	var h := float(sp.spout) * clampf(size / (float(sp.male_k) if male else float(sp.female_k)), 0.35, 1.2)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(clampf(h * 30.0, 30.0, 260.0))
	p.lifetime = clampf(sqrt(h) * 0.9, 0.8, 3.2)
	p.explosiveness = 0.75
	p.direction = Vector3.UP
	p.spread = float(sp.spout_spread)
	# (up fast, slowing to a stop at its height as the air takes it: rising half its life, then hanging, drifting, thinning)
	var t_up := p.lifetime * 0.45
	var d := 2.0 * h / (t_up * t_up)
	var v := d * t_up
	p.initial_velocity_min = v * 0.8
	p.initial_velocity_max = v * 1.0
	p.damping_min = d * 0.9
	p.damping_max = d * 1.1
	p.gravity = Vector3(0.5, -0.4, 0.2) # (the breeze taking it, the mist settling)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.3))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.55))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2.ONE * clampf(h * 0.12, 0.08, 1.1)
	var blob := GradientTexture2D.new()
	blob.fill = GradientTexture2D.FILL_RADIAL
	blob.fill_from = Vector2(0.5, 0.5)
	blob.fill_to = Vector2(0.5, 0.0)
	blob.gradient = Gradient.new()
	blob.gradient.set_color(0, Color(1, 1, 1, 1))
	blob.gradient.set_color(1, Color(1, 1, 1, 0))
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = blob
	m.albedo_color = Color(0.96, 0.97, 0.98, 0.8)
	q.material = m
	p.mesh = q
	get_parent().add_child(p)
	p.position = _at(_blow_local())
	p.emitting = true
	var tree := get_tree()
	await tree.create_timer(p.lifetime + 1.0).timeout
	if is_instance_valid(p):
		p.queue_free()


## Spray, thrown up at `at` (its parent's space), falling back.
func _splash(at: Vector3, k: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(80 * k) + 20
	p.lifetime = 1.4 + 0.5 * k
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 50.0
	p.initial_velocity_min = 2.0 * sqrt(k)
	p.initial_velocity_max = 6.0 * sqrt(k)
	p.gravity = Vector3(0.0, -9.8, 0.0)
	p.scale_amount_min = 0.06 * k
	p.scale_amount_max = 0.2 * k
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.95, 0.97, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	sm.material = mat
	p.mesh = sm
	get_parent().add_child(p)
	p.position = Vector3(at.x, tank_max.y + 0.03, at.z)
	p.emitting = true
	var tree := get_tree()
	await tree.create_timer(4.0).timeout
	if is_instance_valid(p):
		p.queue_free()


# --- her calf ----------------------------------------------------------------------------------

func _bear_one() -> Node3D:
	var c := (get_script() as Script).new(true) as Node3D
	c.set("species", species)
	c.set("male", rng.randf() < 0.5)
	c.set("mother", self)
	c.set("tank_min", tank_min)
	c.set("tank_max", tank_max)
	get_parent().add_child(c)
	var at := _at(Vector3(0.0, -float(S().len) * 0.05, float(S().len) * 0.22))
	c.call("place", at, atan2(-_fwd.x, -_fwd.z))
	c.set("o2", 0.0)
	c.call("_to", "first_breath")
	calves.append(c)
	return c


# --- the mesh --------------------------------------------------------------------------------

## The body at s: [its middle's height, half width, above, below] (shares of its length).
static func _key(sp: Dictionary, s: float) -> Vector4:
	var K: Array = sp.body
	if s <= float(K[0][0]):
		return Vector4(K[0][1], K[0][2], K[0][3], K[0][4])
	for i in K.size() - 1:
		var a: Array = K[i]
		var b: Array = K[i + 1]
		if s <= float(b[0]):
			var f := (s - float(a[0])) / (float(b[0]) - float(a[0]))
			var a0: Array = K[maxi(i - 1, 0)]
			var b1: Array = K[mini(i + 2, K.size() - 1)]
			var r := Vector4.ZERO
			for c in 4:
				var v := 0.5 * (2.0 * float(a[c + 1]) + (-float(a0[c + 1]) + float(b[c + 1])) * f + (2.0 * float(a0[c + 1]) - 5.0 * float(a[c + 1]) + 4.0 * float(b[c + 1]) - float(b1[c + 1])) * f * f + (-float(a0[c + 1]) + 3.0 * float(a[c + 1]) - 3.0 * float(b[c + 1]) + float(b1[c + 1])) * f * f * f)
				r[c] = v if c == 0 else maxf(v, 0.0)
			return r
	var l: Array = K[K.size() - 1]
	return Vector4(l[1], l[2], l[3], l[4])


const Z0 := -0.5 ## (the snout's z, a share of the length; the notch at Z0 + ZS)
const ZS := 0.96


## A point on its skin (m): at s, a round it (0 its back's middle, PI its belly's).
static func _skin(sp: Dictionary, s: float, a: float) -> Vector3:
	var k := _key(sp, s)
	var c := cos(a)
	var y := k.x + (k.z * c if c > 0.0 else k.w * -pow(-c, 0.9))
	return Vector3(k.y * sin(a), y, Z0 + s * ZS) * float(sp.len)


static func _v(st: SurfaceTool, p: Vector3, n: Vector3, c0: Color, c1: Color) -> void:
	st.set_custom(0, c0)
	st.set_custom(1, c1)
	st.set_normal(n)
	st.add_vertex(p)


## [mesh, its jaw's pivot, its flippers' root] (m). CUSTOM0: x its part (0
## body, 1 eye, 2 dorsal, 3 flipper, 4 flukes, 5 a tooth, 6 baleen), y its s
## (0 snout .. 1 the flukes' notch, on past it for the flukes), z out along
## a fin (0 root .. 1 tip), w across it (0 leading .. 1 trailing). CUSTOM1:
## x with its lower jaw, y its pouch (a blue whale's throat), z its side,
## w round it (0 back .. 1 belly).
static func build(sp_name: String, is_male: bool) -> Array:
	var sp: Dictionary = SPECIES[sp_name]
	var L := float(sp.len)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var gs := float(sp.gape_s)
	var ga := float(sp.gape_a)
	var NZ := 90
	var NR := 36
	var grid := []
	var ss := []
	for i in NZ + 1:
		var t := float(i) / NZ
		var s := pow(t, 1.35) # (finer at the head)
		ss.append(s)
		var row := []
		for r in NR + 1:
			row.append(_skin(sp, s, TAU * r / NR))
		grid.append(row)
	var nrm := []
	for i in NZ + 1:
		var row := []
		for r in NR + 1:
			var pa: Vector3 = grid[mini(i + 1, NZ)][r]
			var pb: Vector3 = grid[maxi(i - 1, 0)][r]
			var qa: Vector3 = grid[i][(r + 1) % NR]
			var qb: Vector3 = grid[i][(r + NR - 1) % NR]
			var n := (qa - qb).cross(pa - pb)
			if n.length() < 1e-9 or i == 0:
				n = Vector3(0.0, 0.0, -1.0)
			n = n.normalized()
			var mid := Vector3(0.0, _key(sp, float(ss[i])).x * L, (grid[i][r] as Vector3).z)
			if n.dot((grid[i][r] as Vector3) - mid) < 0.0 and i > 0:
				n = -n
			row.append(n)
		nrm.append(row)
	var pouch_on := bool(sp.pouch)
	for i in NZ:
		for r in NR:
			var q := [[i, r], [i + 1, r], [i + 1, r + 1], [i, r + 1]]
			var ac := TAU * (float(r) + 0.5) / NR
			var low := absf(ac - PI) < PI - ga
			var sc := (float(ss[i]) + float(ss[i + 1])) * 0.5
			var jaw_tri := 1.0 if (low and sc < gs) else 0.0
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for j: int in [tri[0], tri[2], tri[1]]:
					var gi: int = q[j][0]
					var gr: int = q[j][1]
					var p: Vector3 = grid[gi][gr]
					var s: float = ss[gi]
					var av := absf(TAU * float(gr) / NR - PI) # (0 the belly's middle .. PI the back's)
					var jw := jaw_tri
					if jaw_tri == 0.0 and s >= gs: # (behind its mouth's corners: the throat going with the jaw, smoothly)
						jw = (1.0 - smoothstep(gs, gs + 0.07, s)) * (1.0 - smoothstep(PI - ga - 0.4, PI - ga + 0.05, av))
					var pw := 0.0
					if pouch_on: # (its throat's pleated pouch: from its chin to its navel, under it)
						pw = smoothstep(0.0, 0.06, s) * (1.0 - smoothstep(0.42, 0.56, s)) * (1.0 - smoothstep(1.0, 1.45, av))
					_v(st, p, nrm[gi][gr], Color(0.0, s, 0.0, 0.0), Color(jw, pw, 0.0, 1.0 - av / PI))
	# its eyes
	for side: float in [-1.0, 1.0]:
		var es := float(sp.eye_s)
		var ea := float(sp.eye_a)
		var ec := _skin(sp, es, ea if side > 0.0 else TAU - ea)
		var en := Vector3(side, 0.15, -0.1).normalized()
		var er := float(sp.eye_r) * L
		_ball(st, ec - en * er * 0.4, er, en, 1.0, es)
	# its dorsal fin
	var dfin: Array = sp.dorsal_m if is_male else sp.dorsal
	var ds := float(dfin[0])
	var dh := float(dfin[1]) * L
	var db := float(dfin[2]) * L
	var dfalc := float(dfin[3])
	var zf := (Z0 + (ds - float(dfin[2]) * 0.5 / ZS) * ZS) * L
	var zb := (Z0 + (ds + float(dfin[2]) * 0.5 / ZS) * ZS) * L
	var topf := _skin(sp, (zf / L - Z0) / ZS, 0.0)
	var topb := _skin(sp, (zb / L - Z0) / ZS, 0.0)
	var tip := Vector3(0.0, (topf.y + topb.y) * 0.5 + dh, zb + db * (0.15 + 0.55 * dfalc))
	_foil(st, topf - Vector3(0.0, 0.01 * L, 0.0), topb - Vector3(0.0, 0.01 * L, 0.0), tip, Vector3(0.0, dh * 0.08, -db * 0.25 * (1.0 + dfalc)), Vector3(0.0, -dh * 0.1, -db * 0.4 * dfalc), Vector3.RIGHT, db * 0.12, 2.0, 0.0, ds, sp_name == "orca" and is_male)
	# its flippers
	var fl: Array = sp.get("flipper_m", sp.flipper) if is_male else sp.flipper
	var fs := float(fl[0])
	var flen := float(fl[1]) * L
	var fch := float(fl[2]) * L
	var fdown := float(fl[3])
	var froot := Vector3.ZERO
	for side: float in [-1.0, 1.0]:
		var a_side := PI * (0.5 + 0.5 * fdown) # (round from its back: down its side)
		var aa := a_side if side > 0.0 else TAU - a_side
		var rf := _skin(sp, fs - float(fl[2]) * 0.45, aa) * Vector3(0.92, 1.0, 1.0)
		var rb := _skin(sp, fs + float(fl[2]) * 0.45, aa) * Vector3(0.92, 1.0, 1.0)
		var out := Vector3(side, -0.55, 0.45).normalized()
		var ftip := (rf + rb) * 0.5 + out * flen
		var nn := Vector3(0.0, 1.0, 0.0).rotated(Vector3.FORWARD, side * 0.5)
		var rounded := sp_name == "orca"
		_foil(st, rf, rb, ftip, out.cross(Vector3.UP).normalized() * 0.0 + Vector3(0.0, 0.0, -fch * (0.5 if rounded else 0.15)), Vector3(0.0, 0.0, fch * (0.6 if rounded else 0.25)), nn, fch * 0.18, 3.0, side, fs, false)
		froot = Vector3(absf(rf.x), (rf.y + rb.y) * 0.5, (rf.z + rb.z) * 0.5)
	# its flukes: each side from its tail stock out, the notch between
	var fk: Array = sp.fluke
	var span := float(fk[0]) * L * 0.5
	var fch2 := float(fk[1]) * L
	var zn := (Z0 + ZS) * L
	var yc := _key(sp, 1.0).x * L
	for side: float in [-1.0, 1.0]:
		var rf := Vector3(0.0, yc, zn - fch2 * 0.9)
		var rb := Vector3(0.0, yc, zn)
		var ft := Vector3(side * span, yc - (0.01 * L if is_male and sp_name == "orca" else 0.0), zn + fch2 * 0.35)
		_foil(st, rf, rb, ft, Vector3(side * span * 0.15, 0.0, -fch2 * 0.25), Vector3(-side * span * 0.06, 0.0, -fch2 * 0.12), Vector3.UP, fch2 * 0.13, 4.0, side, 1.0, false)
	# its teeth (an orca's, a dolphin's), its baleen (a blue whale's)
	var nt := int(sp.teeth)
	if nt > 0:
		var tsz := float(sp.tooth) * L
		for side: float in [-1.0, 1.0]:
			for k in nt:
				var s := lerpf(0.012, gs * 0.88, (float(k) + 0.5) / nt)
				for upper: bool in [true, false]:
					var aa := (ga - 0.08) if upper else (ga + 0.1)
					aa = aa if side > 0.0 else TAU - aa
					var base := _skin(sp, s, aa) * Vector3(0.9, 1.0, 1.0)
					var dir := Vector3(0.0, -1.0 if upper else 1.0, 0.0)
					_cone(st, base, dir, tsz, tsz * 0.32, 5.0, 0.0 if upper else 1.0, s)
	if bool(sp.baleen):
		for side: float in [-1.0, 1.0]:
			var n := 70
			for k in n:
				var s := lerpf(0.03, gs * 0.95, (float(k) + 0.5) / n)
				var aa := ga - 0.12
				aa = aa if side > 0.0 else TAU - aa
				var top := _skin(sp, s, aa) * Vector3(0.8, 1.0, 1.0)
				var s2 := lerpf(0.03, gs * 0.95, (float(k) + 1.5) / n)
				var top2 := _skin(sp, s2, aa) * Vector3(0.8, 1.0, 1.0)
				var hang := L * 0.022 * sin(PI * clampf((s - 0.02) / gs, 0.0, 1.0)) + L * 0.003
				var inward := Vector3(-side * 0.7, -1.0, 0.0).normalized()
				var nn := Vector3(side, 0.0, 0.0)
				var c := Color(6.0, s, 0.0, 0.0)
				for pv: Vector3 in [top, top2, top2 + inward * hang, top, top2 + inward * hang, top + inward * hang]:
					_v(st, pv, nn, Color(6.0, s, clampf((pv - top).length() / maxf(hang, 1e-4), 0.0, 1.0), float(k % 2)), Color(0.0, 0.0, side, 0.5))
	st.index()
	var mesh := st.commit()
	var jaw_pivot := _skin(sp, gs, PI * 0.5) * Vector3(0.0, 1.0, 1.0) + Vector3(0.0, -_key(sp, gs).z * L * 0.15, 0.0)
	return [mesh, jaw_pivot, froot]


## A fin: from its root (front rf, back rb) out to its tip, its leading
## edge bowed by lead, its trailing by trail; thick through n (its plane's
## normal), thinning to its edges and tip.
static func _foil(st: SurfaceTool, rf: Vector3, rb: Vector3, tip: Vector3, lead: Vector3, trail: Vector3, n: Vector3, thick: float, part: float, side: float, s_at: float, straight: bool) -> void:
	var NS := 12
	var NC := 8
	var cl := (rf + tip) * 0.5 + lead
	var ct := (rb + tip) * 0.5 + trail
	if straight: # (a male orca's: a tall straight blade)
		cl = (rf + tip) * 0.5 + lead * 0.2
		ct = (rb + tip) * 0.5 + trail * 0.3
	n = n.normalized()
	var rows := []
	for i in NS + 1:
		var t := float(i) / NS
		var Lp := rf.lerp(cl, t).lerp(cl.lerp(tip, t), t)
		var Tp := rb.lerp(ct, t).lerp(ct.lerp(tip, t), t)
		var row := []
		for c in NC + 1:
			var f := float(c) / NC
			var th := thick * (1.0 - 0.75 * t) * 2.6 * sqrt(f) * (1.0 - f) * (1.0 - pow(t, 6.0))
			row.append([Lp.lerp(Tp, f), th, t, f])
		rows.append(row)
	for sgn: float in [1.0, -1.0]:
		for i in NS:
			for c in NC:
				var q := [rows[i][c], rows[i + 1][c], rows[i + 1][c + 1], rows[i][c + 1]]
				var order := [0, 1, 2, 0, 2, 3] if sgn > 0.0 else [0, 2, 1, 0, 3, 2]
				for k: int in order:
					var e: Array = q[k]
					var p: Vector3 = (e[0] as Vector3) + n * float(e[1]) * sgn
					var nn := (n * sgn + (Vector3.ZERO)).normalized()
					_v(st, p, nn, Color(part, s_at, e[2], e[3]), Color(0.0, 0.0, side, 0.0 if sgn > 0.0 else 1.0))


static func _ball(st: SurfaceTool, c: Vector3, r: float, out: Vector3, part: float, s: float) -> void:
	var U := 10
	var V := 6
	for i in V:
		for j in U:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var th := PI * float(e.x) / V
				var ph := TAU * float(e.y) / U
				var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				q.append(d)
			for k: int in [0, 1, 2, 0, 2, 3]:
				var d: Vector3 = q[k]
				_v(st, c + d * r, d, Color(part, s, 0.0, d.dot(out)), Color(0.0, 0.0, 0.0, 0.0))


static func _cone(st: SurfaceTool, base: Vector3, dir: Vector3, h: float, r: float, part: float, jaw: float, s: float) -> void:
	var a := dir.cross(Vector3.FORWARD).normalized()
	var b := dir.cross(a)
	var NS := 5
	for k in NS:
		var a0 := TAU * float(k) / NS
		var a1 := TAU * float(k + 1) / NS
		var p0 := base + (a * cos(a0) + b * sin(a0)) * r
		var p1 := base + (a * cos(a1) + b * sin(a1)) * r
		var tp := base + dir * h
		var nn := ((p0 + p1) * 0.5 - base).normalized()
		for pv: Vector3 in [p0, tp, p1]:
			_v(st, pv, nn, Color(part, s, (pv - base).dot(dir) / h, 0.0), Color(jaw, 0.0, 0.0, 0.0))
