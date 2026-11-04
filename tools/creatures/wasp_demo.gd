extends Node3D
## A plain to watch the wasp (Wasp) on, each of its animations on a key:
## godot --path . res://tools/creatures/wasp_demo.tscn
##
## 1 seek food (flying about)   2 feed on the flower   3 catch and eat the
## caterpillar (R puts a fresh one back on its leaf)   4 land on the plank
## (walk about, settle)   5 sting the red ball   Space slow motion
## Mouse: drag to turn round it, wheel to come nearer or go off; the camera
## follows the wasp (F: or not). The flower's a clump of the game's own
## purple coneflowers, swaying (key 2: off to them, and once near a head
## feeding at it in flight: the CPU only knows where the head stands
## still; the wasp's own shaders sway it with the head, as the flowers'
## shader sways the head). For the scale, things from the game: the
## player's figure with its axe, and on the plank a pawpaw, a black-eyed
## Susan, a yampah and a cattail.
##
## And the other creatures beside it, each with its own place:
## 6 the hummingbird moth searching (darting about the flowers)   7 it feeding
## at the milkweed   8 the monarch flying   9 it basking on the stone   0 it
## feeding at the swamp milkweed   A the ants: wandering, or at their crumb
## H the red harvesters: wandering, or at their seeds
## B the June bugs: walking about, or eating at their leaves   L the
## lady beetles: walking about, or hunting their leaves over   J the June
## bugs flying (B again brings them down)   K the lady beetles flying (L)
## Tab: the camera follows the next of them (wasp, moth, monarch, ants,
## June bugs, lady beetles).

var wasp: Wasp
# (by path, not by class name: found whether or not the editor has seen these yet)
const MothScript := preload("res://scripts/creatures/hummingbird_moth.gd")
const MonarchScript := preload("res://scripts/creatures/monarch.gd")
const Flowers := preload("res://tools/creatures/demo_flowers.gd")

var moth: MothScript
var monarch: MonarchScript
var ants: AntColony
const HarvesterScript := preload("res://scripts/creatures/harvester_ants.gd")
var harvesters: AntColony
var _harvest_feeding := false
const JuneScript := preload("res://scripts/creatures/june_beetles.gd")
const LadyScript := preload("res://scripts/creatures/lady_beetles.gd")
var beetles: JuneScript
var ladies: LadyScript
var _ants_feeding := false
var _beetles_feeding := false
var _ladies_feeding := false
var _following := 0 # wasp, moth, monarch, ants, June bugs, lady beetles, harvesters
var _flowers := {} # the patch's clumps' florets (points), by kind (DemoFlowers.patch)
var _milkweed: Array = [] # the first milkweed's
var _swamp: Array = [] # the swamp milkweed's
const MOTHS_AT := Vector3(2.4, 0.0, -0.6) # (the flower patch's middle)
const STONE := Vector3(2.7, 0.04, 0.55) # (by the flower patch)
const ANTS_AT := Vector3(0.45, 0.0, 0.0)
const CRUMB := Vector3(0.5, 0.0, 0.05)
const BEETLES_AT := Vector3(-0.55, 0.0, -0.25)
const BEETLE_LEAVES := [Vector3(-0.5, 0.0, -0.3), Vector3(-0.62, 0.0, -0.18)]
const ANT_COUNT := 14
const HARVEST_AT := Vector3(0.6, 0.0, 0.75)
const SEEDS := Vector3(0.64, 0.0, 0.78)
const HARVEST_COUNT := 12
const BEETLE_COUNT := 4
const LADIES_AT := Vector3(-0.55, 0.0, 0.4)
const LADY_LEAVES := [Vector3(-0.5, 0.0, 0.38), Vector3(-0.62, 0.0, 0.5)]
const LADY_COUNT := 8
const SWARM_R := 0.13 # m: the ants' and beetles' wandering round their places
var cam: Camera3D
var prey: Node3D
var avatar: Avatar
var _axe_held := false
var _yaw := 0.6
var _pitch := -0.35
var _dist := 0.12
var _follow := true
var _focus := Vector3.ZERO
var _label: Label

const CONE_NEAR := Vector2(0.3, -0.2) ## m: the coneflowers here
const CONE_H := 1.4 ## m: the clump's height (in the game 1.2-1.6 on the prairie)
var _heads: Array = [] # the coneflowers' heads, still: [the disc's top, the way it faces, how far up its clump (its sway's share)]
var _cone_size := 1.0
var _to_flower := false # key 2: feeding at a head once it's near one
const LEAF := Vector3(-0.3, 0.2, 0.0)
const PLANK := Vector3(0.0, 0.06, 0.4)
const BALL := Vector3(-0.35, 0.025, 0.35)


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 7.0
	add_child(sun)
	_box(Vector3(0.8, -0.005, 0), Vector3(7, 0.01, 5), Color(0.33, 0.4, 0.2))
	# the flower: a clump of the game's own purple coneflowers
	_coneflower()
	# the leaf the caterpillar's on, on a stalk
	_box(LEAF + Vector3(0, -0.1, 0), Vector3(0.004, 0.2, 0.004), Color(0.3, 0.42, 0.15))
	_box(LEAF + Vector3(0, 0.001, 0), Vector3(0.12, 0.002, 0.07), Color(0.25, 0.45, 0.15))
	# a plank to land on, and a ball to sting
	_box(PLANK, Vector3(0.3, 0.02, 0.1), Color(0.55, 0.42, 0.28))
	var ball := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.025
	s.height = 0.05
	ball.mesh = s
	ball.position = BALL
	ball.material_override = _mat(Color(0.7, 0.12, 0.1))
	add_child(ball)
	_new_prey()
	_scale_things()
	_others()
	wasp = Wasp.new()
	add_child(wasp)
	wasp.place(Vector3(0.0, 0.3, 0.0))
	cam = Camera3D.new()
	cam.near = 0.001
	cam.far = 100.0
	cam.fov = 50.0
	add_child(cam)
	_focus = wasp.global_position
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.text = "Wasp: 1 seek food   2 feed on the flower   3 catch the caterpillar (R: a new one)   4 land on the plank   5 sting the ball\nMoth: 6 search   7 feed at the milkweed   Monarch: 8 fly   9 bask on the stone   0 feed at the swamp milkweed\nA ants: wander / feed   H harvesters: wander / at the seeds   B June bugs: walk / eat   L lady beetles: walk / hunt   J / K June bugs / lady beetles fly   Tab follow the next   F follow on/off   Space slow motion   drag: turn round   wheel: nearer / further"
	add_child(_label)
	wasp.seek_food(Vector3.ZERO, 0.6)


## The other creatures, each at its own place on the plain: the
## hummingbird moth and the monarch round a patch of the game's flowers
## (DemoFlowers.patch: three clumps of common milkweed, one of swamp
## milkweed, coneflowers, Susans, fleabane, asters, yampah), a stone for the
## monarch to bask on;
## ants round a crumb; red harvesters round a pile of seeds; June bugs round two leaves, lady beetles round two
## more.
func _others() -> void:
	_flowers = Flowers.patch(self, Vector2(MOTHS_AT.x, MOTHS_AT.z), Color(0.42, 0.38, 0.28))
	_milkweed = _flowers.milkweed
	_swamp = _flowers.swamp_milkweed
	var stone := _box(STONE - Vector3(0, 0.02, 0), Vector3(0.25, 0.04, 0.18), Color(0.5, 0.48, 0.44))
	stone.rotation.y = 0.4
	moth = MothScript.new()
	add_child(moth)
	moth.place(MOTHS_AT + Vector3(0.0, 0.6, 0.3))
	moth.search(MOTHS_AT, 1.0, _all_heads())
	monarch = MonarchScript.new()
	add_child(monarch)
	monarch.place(MOTHS_AT + Vector3(-0.3, 1.0, 0.2))
	monarch.fly(MOTHS_AT, 1.3)
	var crumb := AntColony.crumb()
	crumb.position = CRUMB
	add_child(crumb)
	ants = AntColony.new()
	add_child(ants)
	ants.setup(ANT_COUNT, ANTS_AT, SWARM_R)
	var pile := HarvesterScript.seeds()
	pile.position = SEEDS
	add_child(pile)
	harvesters = HarvesterScript.new()
	add_child(harvesters)
	harvesters.setup(HARVEST_COUNT, HARVEST_AT, SWARM_R)
	for c in BEETLE_LEAVES:
		var leaf := Beetles.leaf()
		leaf.position = c
		add_child(leaf)
	beetles = JuneScript.new()
	add_child(beetles)
	beetles.setup(BEETLE_COUNT, BEETLES_AT, SWARM_R)
	for c in LADY_LEAVES:
		var leaf := Beetles.leaf()
		leaf.position = c
		add_child(leaf)
	ladies = LadyScript.new()
	add_child(ladies)
	ladies.setup(LADY_COUNT, LADIES_AT, SWARM_R)


## What the camera follows (Tab: the next).
func _followed() -> Vector3:
	match _following:
		1:
			return moth.global_position
		2:
			return monarch.global_position
		3:
			return ANTS_AT + Vector3(0.0, 0.02, 0.0)
		4:
			return BEETLES_AT + Vector3(0.0, 0.02, 0.0)
		5:
			return LADIES_AT + Vector3(0.0, 0.01, 0.0)
		6:
			return HARVEST_AT + Vector3(0.0, 0.02, 0.0)
	return wasp.global_position


## Things from the game, for the scale: the player's figure (Avatar,
## about 1.8 m) beside the plank, the axe in its hand; and on the plank a
## pawpaw, a black-eyed Susan, a yampah and a cattail, as they're carried
## (Items).
func _scale_things() -> void:
	avatar = Avatar.new()
	add_child(avatar)
	avatar.position = Vector3(0.75, 0.0, 0.55)
	avatar.rotation.y = deg_to_rad(60.0) # (facing the plank)
	var on := PLANK + Vector3(0.0, 0.01, 0.0)
	var lay := [["pawpaw", Vector3(0.09, 0.028, -0.02), Vector3(0.0, 0.3, PI * 0.5)],
			["susan", Vector3(-0.02, 0.006, 0.025), Vector3(0.0, 0.2, PI * 0.5)],
			["yampah", Vector3(-0.05, 0.006, -0.03), Vector3(0.0, -0.25, PI * 0.5)],
			["cattail", Vector3(0.04, 0.014, 0.035), Vector3(0.0, 0.1, PI * 0.5)]]
	for t in lay:
		var m := Items.model(t[0])
		m.position = on + t[1]
		m.rotation = t[2]
		add_child(m)


## A clump of the game's purple coneflowers (DemoFlowers.build: their
## mesh and colours, placed here on the CPU), CONE_H tall at CONE_NEAR,
## swaying as the prairie's do (grass_sway 0.3 * its size * how far up,
## squared). Notes where its heads are.
func _coneflower() -> void:
	var info: Dictionary = Flowers.build(self, "coneflower", CONE_NEAR, CONE_H, Color(0.42, 0.38, 0.28), 0.3 * CONE_H)
	_heads = info.heads
	_cone_size = info.size


func _new_prey() -> void:
	if prey:
		if wasp:
			wasp.release()
		prey.queue_free()
	prey = Wasp.caterpillar()
	add_child(prey)
	prey.position = LEAF + Vector3(0.02, 0.0035, 0.01)
	prey.rotation.y = 0.7


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				_following = 0
				_to_flower = false
				wasp.seek_food(Vector3.ZERO, 0.6)
			KEY_2:
				_following = 0
				# off to the flowers: seeking round them, feeding at a head once near one
				wasp.seek_food(Vector3(_heads[0][0].x, 0.0, _heads[0][0].z) + Vector3(0, 1.0, 0), 0.25)
				_to_flower = true
			KEY_3:
				_following = 0
				_to_flower = false
				wasp.feed_on_insect(prey, LEAF + Vector3(0, 0.002, 0), Vector3.UP)
			KEY_4:
				_following = 0
				_to_flower = false
				wasp.land(PLANK + Vector3(0, 0.01, 0), Vector3.UP)
			KEY_5:
				_following = 0
				_to_flower = false
				wasp.sting(BALL + Vector3(0, 0.02, 0))
			KEY_6:
				moth.search(MOTHS_AT, 1.0, _all_heads())
				_following = 1
			KEY_7:
				moth.feed(_flowers[["milkweed", "milkweed2", "milkweed3"].pick_random()])
				_following = 1
			KEY_8:
				monarch.fly(MOTHS_AT, 1.3)
				_following = 2
			KEY_9:
				monarch.bask(STONE, Vector3.UP)
				_following = 2
			KEY_0:
				monarch.feed(_swamp)
				_following = 2
			KEY_A:
				_ants_feeding = not _ants_feeding
				for i in ANT_COUNT:
					if _ants_feeding:
						ants.feed(i, CRUMB)
					else:
						ants.wander(i, ANTS_AT, SWARM_R)
				_following = 3
			KEY_B:
				_beetles_feeding = not _beetles_feeding
				for i in BEETLE_COUNT:
					if _beetles_feeding:
						var leaf: Vector3 = BEETLE_LEAVES[i % BEETLE_LEAVES.size()]
						beetles.feed(i, leaf + Vector3(randf_range(-0.02, 0.02), 0.0, randf_range(-0.035, 0.035)))
					else:
						beetles.wander(i, BEETLES_AT, SWARM_R)
				_following = 4
			KEY_L:
				_ladies_feeding = not _ladies_feeding
				for i in LADY_COUNT:
					if _ladies_feeding:
						var leaf: Vector3 = LADY_LEAVES[i % LADY_LEAVES.size()]
						ladies.feed(i, leaf + Vector3(randf_range(-0.02, 0.02), 0.0, randf_range(-0.035, 0.035)))
					else:
						ladies.wander(i, LADIES_AT, SWARM_R)
				_following = 5
			KEY_J:
				for i in BEETLE_COUNT:
					beetles.fly(i, BEETLES_AT, 0.4, 0.35)
				_beetles_feeding = true # (so B next brings them down to walk)
				_following = 4
			KEY_K:
				for i in LADY_COUNT:
					ladies.fly(i, LADIES_AT, 0.3, 0.25)
				_ladies_feeding = true
				_following = 5
			KEY_H:
				_harvest_feeding = not _harvest_feeding
				for i in HARVEST_COUNT:
					if _harvest_feeding:
						harvesters.feed(i, SEEDS)
					else:
						harvesters.wander(i, HARVEST_AT, SWARM_R)
				_following = 6
			KEY_TAB:
				_following = (_following + 1) % 7
			KEY_R:
				_new_prey()
			KEY_F:
				_follow = not _follow
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.02)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 3.0)


func _process(dt: float) -> void:
	# near a head: feeding at it (where it stands still; the wasp's shaders
	# sway it with the head, by the head's share of the wind: the grass's
	# grass_sway, 0.3, * the clump's size * how far up it, squared)
	if _to_flower:
		for h in _heads:
			if wasp.global_position.distance_to(h[0]) < 0.3:
				_to_flower = false
				wasp.feed_on_flower(h[0], h[1], 0.3 * _cone_size * h[2] * h[2])
				break
	avatar.walk(dt, 0.0, true) # (standing)
	if not _axe_held and avatar.grip("r"):
		avatar.grip("r").add_child(Items.model("axe"))
		_axe_held = true
	if _follow:
		_focus = _focus.lerp(_followed(), 1.0 - exp(-6.0 * dt / maxf(Engine.time_scale, 0.01)))
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)


## Every flower's head in the patch, for the moth to look over.
func _all_heads() -> Array:
	var out := []
	for k in _flowers:
		out += Flowers.heads(_flowers[k])
	return out


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	mi.material_override = _mat(c)
	add_child(mi)
	return mi


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m
