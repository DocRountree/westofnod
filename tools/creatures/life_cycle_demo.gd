extends Node3D
## The creatures' life cycles, a station each along a plain:
## godot --path . res://tools/creatures/life_cycle_demo.tscn
##
## monarch: the adult, milkweed and leaves to lay on, a caterpillar, a
##   chrysalis hanging from a twig
## hummingbird clearwing: the adult, leaves (it lays hovering), a hornworm,
##   a pupa in its cocoon in the litter
## paper wasp: the adult and its comb, grubs in some of its cells
## carpenter ants, red harvesters: a queen each, a pile of her eggs, and
##   larvae
## June bug: the adult, its white grub, curled, on the soil
## convergent lady beetle: the adult on a leaf, its larva about
## differential grasshopper: the adult (a female) and a nymph, a leaf to eat
## Carolina mantis: the adult (a female) and a nymph, a stem to lay on, a
##   fly to catch
## eastern diamondback rattlesnake, eastern milk snake (life size): an adult
##   and a young each, a mouse each to eat
## wolf spider, fishing spider (on a pond), grass spider (its funnel web
##   spun as it starts), yellow garden spider (its orb spun off a branch),
##   pill bugs in leaf litter (a female and young)
## deer mouse (life size): a female, a male, her grass nest, seeds
## (every station a male too, but the ants': the female's partner)
##
## 1 every adult lays its eggs (Brood's: the butterflies one to a leaf, the
##   wasp one to a cell, the beetles a cluster; not the ants: their queens'
##   eggs lie in piles already)
## 2 the pupae hatch: the adult out, its wings filling out; then off
## 3 new pupae
## 4 every egg hatches: the larva out, small, growing (a caterpillar eats
##   its shell first); 5 new ant eggs
## 6 the grasshopper hops   7 it flies   8 it eats at its leaf
## 9 the mantis strikes at the fly (and eats it)   0 it flies   G it grooms
## R the rattlesnake eats its mouse   M the milk snake eats its   C the
##   snakes coil up (W: off again)
## Y the young eat: the larvae, the nymphs, the young snakes (each its own
##   small meal)
## (1 also: the rattlesnake gives birth, the milk snake lays; 4: its eggs hatch)
## (1 also: the spiders spin their egg sacs, the pill bug's pouch fills;
##   4: the sacs hatch, the pill bug's young come out)
## F the spiders hunt (a fly each: on the ground, the water, the sheet, in
##   the web)   S the web spiders spin anew   O the pill bugs roll up
## P steered by the steering layer (pilot.gd), as a state machine would: the
##   grasshopper, the mantis, the snakes, the moth, a lady beetle, each
##   through a few orders, one after another as each says it's done
## K they mate, each pair its own way (the male mantis eaten, the garden
##   spider's male dead on her; the spiders' males first charging their
##   palps at a sperm web)
## E the mice eat (a seed each)   Q they wash   (1 also: the mouse gives
##   birth in her nest; Y: her young, once they're about, eat)
## Tab / Shift+Tab: the next station   Space slow motion
## drag: turn round   wheel: nearer / further

const MothScript := preload("res://scripts/creatures/hummingbird_moth.gd")
const MonarchScript := preload("res://scripts/creatures/monarch.gd")
const HarvesterScript := preload("res://scripts/creatures/harvester_ants.gd")
const JuneScript := preload("res://scripts/creatures/june_beetles.gd")
const LadyScript := preload("res://scripts/creatures/lady_beetles.gd")
const Flowers := preload("res://tools/creatures/demo_flowers.gd")
const LarvaScript := preload("res://scripts/creatures/larva.gd")
const BroodScript := preload("res://scripts/creatures/brood.gd")
const PupaScript := preload("res://scripts/creatures/pupa.gd")

const NAMES := ["monarch", "hummingbird clearwing", "paper wasp", "carpenter ant (queen)", "red harvester (queen)", "June bug", "convergent lady beetle", "differential grasshopper", "Carolina mantis", "eastern diamondback rattlesnake", "eastern milk snake",
		"Carolina wolf spider", "six-spotted fishing spider", "grass spider (funnel weaver)", "yellow garden spider", "pill bug", "deer mouse"]
const SpiderScript := preload("res://scripts/creatures/spider.gd")
const IsopodScript := preload("res://scripts/creatures/isopod.gd")
const SnakeScript := preload("res://scripts/creatures/snake.gd")
const HopperScript := preload("res://scripts/creatures/grasshopper.gd")
const MantisScript := preload("res://scripts/creatures/mantis.gd")
const MouseScript := preload("res://scripts/creatures/mouse.gd")
const GAP := 0.9 # m between stations

var cam: Camera3D
var _yaw := 0.6
var _pitch := -0.45
var _dist := 0.6
var _at := 0
var _focus := Vector3.ZERO
var _label: Label

var monarch: MonarchScript
var moth: MothScript
var wasp: Wasp
var queens: Array = [] # (the carpenter, the harvester)
var june: JuneScript
var lady: LadyScript
var _monarch_leaves: Array = [] # [spot, normal]
var _moth_leaves: Array = []
var _cells: Array = [] # the comb's cells' mouths (the plain's)
var _pupae: Array = []
var _ant_eggs: Array = []
var _sun_dir := Vector3(0.4, 0.6, 0.6) # (toward the sun: the water's)
var hopper: HopperScript
var mantis: MantisScript
var _hopper_leaf := Vector3.ZERO
var _stem_foot := Vector3.ZERO # (where the mantis builds its egg case)
var _prey: Node3D
var rattler: SnakeScript
var milk: SnakeScript
var _mice := [null, null]
var spiders: Array = [] # wolf, fishing, funnel, garden
var pillbug: IsopodScript
var males := {} ## each station's male (by its female's name: "monarch", "moth", ...; "spider0".., "rattler", "milk")
var mouse_f: MouseScript
var mouse_m: MouseScript
var _nest: Node3D
var _seeds: Array = []
const POND := -0.004 # m: the pond's surface, a little below the plain's
const POND_W := 0.42 # (its half width, x)
const POND_D := 0.36 # (its half depth, z)
const MOTH_PUPA := Vector3(0.2, 0.002, -0.2) # (off the clearwing's station)
const MOTH_PUPA_TURN := 0.6
var _moth_perch := Vector3.ZERO # (a stem by its pupa, to climb and hang from)
var _moth_perch_n := Vector3.BACK


func _station(i: int) -> Vector3:
	# (the snakes, life size, given more room)
	return Vector3(i * GAP + (1.2 if i >= 9 else 0.0) + (1.8 if i >= 10 else 0.0) + (1.6 if i >= 11 else 0.0), 0.0, 0.0)


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
	_sun_dir = Basis.from_euler(sun.rotation).z
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 4.0
	add_child(sun)
	# the plain, a hole left in it for the fishing spider's pond
	var x0 := -0.95
	var x1 := GAP * 17.0 + 5.0
	var pc := _station(12)
	var grass := Color(0.36, 0.4, 0.22)
	_box(Vector3((x0 + pc.x - POND_W) * 0.5, -0.005, 0.0), Vector3(pc.x - POND_W - x0, 0.01, 3.0), grass)
	_box(Vector3((pc.x + POND_W + x1) * 0.5, -0.005, 0.0), Vector3(x1 - pc.x - POND_W, 0.01, 3.0), grass)
	for sgn: float in [-1.0, 1.0]:
		_box(Vector3(pc.x, -0.005, sgn * (POND_D + 1.5) * 0.5), Vector3(POND_W * 2.0, 0.01, 1.5 - POND_D), grass)
	cam = Camera3D.new()
	cam.near = 0.002
	cam.far = 60.0
	cam.fov = 50.0
	add_child(cam)
	_label = Label.new()
	_label.position = Vector2(12, 8)
	add_child(_label)
	_monarch_station()
	_moth_station()
	_wasp_station()
	_ant_stations()
	_beetle_stations()
	_hopper_station()
	_mantis_station()
	_snake_stations()
	_spider_stations()
	_isopod_station()
	_mouse_station()
	_male_partners()
	_new_pupae()
	_focus = _station(0) + Vector3(0.0, 0.08, 0.0)
	_say()


# --- the stations ------------------------------------------------------------------

## Leaves on stalks (spots to lay on: their tops, facing up), about c.
func _leaves(c: Vector3, spots: Array, into: Array) -> void:
	for s: Vector3 in spots:
		var at := c + s
		var leaf := Beetles.leaf()
		leaf.position = at
		leaf.scale = Vector3(0.7, 1.0, 0.7)
		add_child(leaf)
		if at.y > 0.01:
			_box(at - Vector3(0.0, at.y * 0.5, 0.0), Vector3(0.004, at.y, 0.004), Color(0.3, 0.42, 0.18))
		into.append([at + Vector3(0.0, 0.002, 0.0), Vector3.UP])


func _monarch_station() -> void:
	var c := _station(0)
	Flowers.clump(self, "milkweed", Vector2(c.x - 0.15, c.z - 0.2), 1.0, Color(0.42, 0.38, 0.28))
	_leaves(c, [Vector3(0.1, 0.22, -0.05), Vector3(-0.05, 0.3, 0.12), Vector3(0.15, 0.16, 0.15)], _monarch_leaves)
	monarch = MonarchScript.new()
	add_child(monarch)
	monarch.place(c + Vector3(0.0, 0.5, 0.0))
	monarch.fly(c, 0.4)
	var cat := LarvaScript.new("monarch")
	add_child(cat)
	cat.place(c + Vector3(-0.15, 0.0, 0.25), Vector3.LEFT)
	cat.wander(c + Vector3(-0.15, 0.0, 0.25), 0.08)
	# the twig the chrysalis hangs from
	_box(c + Vector3(0.25, 0.32, -0.15), Vector3(0.3, 0.008, 0.008), Color(0.35, 0.27, 0.18))
	_box(c + Vector3(0.38, 0.16, -0.15), Vector3(0.008, 0.32, 0.008), Color(0.35, 0.27, 0.18))


func _moth_station() -> void:
	var c := _station(1)
	_leaves(c, [Vector3(0.12, 0.2, 0.0), Vector3(-0.1, 0.26, -0.08), Vector3(0.02, 0.14, 0.16)], _moth_leaves)
	moth = MothScript.new()
	add_child(moth)
	moth.place(c + Vector3(0.0, 0.4, 0.2))
	moth.search(c, 0.4, [])
	var worm := LarvaScript.new("hemaris")
	add_child(worm)
	worm.place(c + Vector3(-0.2, 0.0, 0.25), Vector3.RIGHT)
	worm.wander(c + Vector3(-0.2, 0.0, 0.25), 0.08)
	# a stem by where its pupa lies, for the moth to climb out of the
	# litter and hang from to dry
	var fwd := Vector3.FORWARD.rotated(Vector3.UP, MOTH_PUPA_TURN)
	var stem := c + MOTH_PUPA + fwd * 0.05
	_box(Vector3(stem.x, 0.08, stem.z), Vector3(0.004, 0.16, 0.004), Color(0.38, 0.33, 0.2))
	_moth_perch = Vector3(stem.x, 0.075, stem.z) - fwd * 0.002
	_moth_perch_n = -fwd
	# the litter the pupa lies in
	for k in 9:
		var leaf := Beetles.leaf()
		leaf.position = c + Vector3(0.2 + randf_range(-0.07, 0.07), 0.0002 * k, -0.2 + randf_range(-0.07, 0.07))
		leaf.rotation.y = randf() * TAU
		leaf.scale = Vector3(0.6, 1.0, 0.6)
		(leaf.get_child(0) as MeshInstance3D).material_override = _plain(Color(0.42, 0.3, 0.16).lerp(Color(0.3, 0.22, 0.12), randf()))
		add_child(leaf)


func _wasp_station() -> void:
	var c := _station(2)
	var made := Wasp.comb()
	var comb: Node3D = made[0]
	comb.position = c
	add_child(comb)
	for m: Vector3 in made[1]:
		_cells.append(c + m)
	# grubs in the last three cells
	for k in [4, 5, 6]:
		var g := LarvaScript.new("wasp")
		add_child(g)
		var cell: Vector3 = _cells[k]
		g.place(cell - Vector3(0.0, 0.012, 0.0) + Vector3(0.002, 0.0, 0.0), Vector3.FORWARD.rotated(Vector3.UP, k))
	wasp = Wasp.new()
	add_child(wasp)
	wasp.place(c + Vector3(0.1, 0.25, 0.1))
	wasp.land(c + Vector3(0.1, 0.0, 0.08))


func _ant_stations() -> void:
	for k in 2:
		var c := _station(3 + k)
		var q: AntColony
		if k == 1:
			q = HarvesterScript.new()
		else:
			q = AntColony.new()
		q.position = c
		q.scale = Vector3.ONE * 1.35 # (a queen: bigger)
		add_child(q)
		q.setup(1, Vector3.ZERO, 0.03)
		queens.append(q)
		_ant_pile(k)
		for j in 5:
			var l := LarvaScript.new("harvester" if k == 1 else "carpenter")
			add_child(l)
			l.place(c + Vector3(0.05 + randf_range(-0.012, 0.012), 0.0, 0.06 + randf_range(-0.012, 0.012)), Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU))


func _beetle_stations() -> void:
	var c := _station(5)
	_box(c + Vector3(0.0, 0.0005, 0.0), Vector3(0.35, 0.002, 0.35), Color(0.3, 0.22, 0.14)) # (soil)
	june = JuneScript.new()
	june.position = c
	add_child(june)
	june.setup(2, Vector3.ZERO, 0.06) # (0 a female, 1 a male)
	var grub := LarvaScript.new("june")
	add_child(grub)
	grub.place(c + Vector3(0.1, 0.0, 0.1), Vector3.LEFT)
	var c2 := _station(6)
	var leaf := Beetles.leaf()
	leaf.position = c2
	leaf.scale = Vector3(2.0, 1.0, 2.0)
	add_child(leaf)
	lady = LadyScript.new()
	lady.position = c2
	add_child(lady)
	lady.setup(2, Vector3.ZERO, 0.04)
	var ll := LarvaScript.new("lady")
	add_child(ll)
	ll.place(c2 + Vector3(0.0, 0.0045, 0.06), Vector3.RIGHT)
	ll.wander(c2 + Vector3(0.0, 0.0045, 0.06), 0.05)


## A pile of the queen's eggs, by her.
func _ant_pile(k: int) -> void:
	var c := _station(3 + k)
	for j in 10:
		var e := BroodScript.egg("harvester" if k == 1 else "carpenter")
		e.position = c + Vector3(-0.05 + randf_range(-0.01, 0.01), 0.0, 0.05 + randf_range(-0.01, 0.01))
		e.rotation.y = randf() * TAU
		add_child(e)
		_ant_eggs.append(e)


func _hopper_station() -> void:
	var c := _station(7)
	_box(c + Vector3(0.0, 0.0005, 0.0), Vector3(0.4, 0.002, 0.4), Color(0.4, 0.32, 0.2)) # (bare soil, to lay in)
	Flowers.clump(self, "susan", Vector2(c.x - 0.25, c.z - 0.2), 0.7, Color(0.42, 0.38, 0.28))
	var leaf := Beetles.leaf()
	_hopper_leaf = c + Vector3(0.15, 0.0, 0.1)
	leaf.position = _hopper_leaf
	leaf.scale = Vector3(1.5, 1.0, 1.5)
	add_child(leaf)
	hopper = HopperScript.new()
	add_child(hopper)
	hopper.place(c, 0.5)
	hopper.wander(c, 0.2)
	var ny := HopperScript.new(true, 0.3)
	add_child(ny)
	ny.place(c + Vector3(-0.1, 0.0, 0.12), 2.0)
	ny.wander(c + Vector3(-0.1, 0.0, 0.12), 0.1)


func _mantis_station() -> void:
	var c := _station(8)
	# a stem, to build the egg case on
	_stem_foot = c + Vector3(0.12, 0.0, -0.12)
	_box(_stem_foot + Vector3(0.0, 0.1, 0.0), Vector3(0.005, 0.2, 0.005), Color(0.4, 0.34, 0.2))
	var leaf := Beetles.leaf()
	leaf.position = c + Vector3(-0.12, 0.0, 0.1)
	add_child(leaf)
	mantis = MantisScript.new()
	add_child(mantis)
	mantis.place(c, 0.3)
	mantis.stalk(c, 0.15)
	var ny := MantisScript.new(true, 0.3)
	add_child(ny)
	ny.place(c + Vector3(0.1, 0.0, 0.15), 1.0)
	ny.stalk(c + Vector3(0.1, 0.0, 0.15), 0.08)
	_new_prey()


func _snake_stations() -> void:
	for k in 2:
		var c := _station(9 + k)
		var kind := "rattler" if k == 0 else "milk"
		var sn := SnakeScript.new(kind)
		add_child(sn)
		sn.place(c + Vector3(0.3, 0.0, 0.0), Vector3.LEFT)
		sn.wander(c, 0.7 if k == 0 else 0.55)
		var yg := SnakeScript.new(kind, true)
		add_child(yg)
		yg.place(c + Vector3(-0.3, 0.0, 0.5), Vector3.RIGHT)
		yg.wander(c + Vector3(-0.3, 0.0, 0.5), 0.3)
		if k == 0:
			rattler = sn
		else:
			milk = sn
		_new_mouse(k)


## A mouse at a snake's station, for it to eat.
func _new_mouse(k: int) -> Node3D:
	if is_instance_valid(_mice[k]):
		return _mice[k]
	var m := SnakeScript.mouse()
	m.position = _station(9 + k) + Vector3(-0.35, 0.0, -0.45)
	m.rotation.y = randf() * TAU
	add_child(m)
	_mice[k] = m
	return m


func _spider_stations() -> void:
	var kinds := ["wolf", "fishing", "funnel", "argiope"]
	for k in 4:
		var c := _station(11 + k)
		var sp := SpiderScript.new(kinds[k])
		add_child(sp)
		spiders.append(sp)
		match kinds[k]:
			"fishing": # (a pond: it runs on the water)
				_pond(c)
				sp.place(c + Vector3(0.0, POND, 0.0), 0.5)
				sp.height = func(_x: float, _z: float) -> float: return POND
				sp.wander(c + Vector3(0.0, POND, 0.0), 0.2)
			"funnel": # (its web spun as it starts)
				sp.place(c + Vector3(0.12, 0.0, 0.0), 0.0)
				sp.spin_funnel(c, 0.14)
			"argiope": # (a tree's trunk and a branch over the plain, stems and a post round below: solid, for it to find and moor its orb to)
				var wood := Color(0.35, 0.27, 0.18)
				var stem := Color(0.36, 0.42, 0.2)
				_solid(c + Vector3(-0.38, 0.35, -0.05), Vector3(0.04, 0.7, 0.04), wood)
				_solid(c + Vector3(-0.08, 0.6, -0.05), Vector3(0.62, 0.025, 0.025), wood)
				var twig := _solid(c + Vector3(0.14, 0.52, -0.05), Vector3(0.012, 0.16, 0.012), wood) # (a twig down off it)
				twig.rotation.z = 0.6
				for st: Vector3 in [Vector3(-0.22, 0.11, -0.05), Vector3(0.24, 0.1, -0.04), Vector3(0.05, 0.07, -0.06), Vector3(0.33, 0.14, -0.05)]:
					_solid(c + st, Vector3(0.006, st.y * 2.0, 0.006), stem)
				_solid(c + Vector3(0.36, 0.2, -0.05), Vector3(0.03, 0.4, 0.03), Color(0.45, 0.4, 0.33)) # (a post)
				sp.place(c, 0.0)
				# (the colliders in the world from the next physics step: spun then)
				get_tree().create_timer(0.3).timeout.connect(_spin_orb.bind(sp, 0))
			_:
				sp.place(c, 0.0)
				sp.wander(c, 0.25)
		var yg := SpiderScript.new(kinds[k], true)
		add_child(yg)
		var yc := c + Vector3(-0.2, POND if kinds[k] == "fishing" else 0.0, 0.25)
		yg.place(yc, 1.0)
		if kinds[k] == "fishing":
			yg.height = func(_x: float, _z: float) -> float: return POND
		yg.wander(yc, 0.08)


## The fishing spider's pond: the game's own water (ocean.gdshader), calm,
## 30 cm deep over a muddy basin sunk in the plain.
func _pond(c: Vector3) -> void:
	var mud := Color(0.16, 0.13, 0.09)
	const DEEP := 0.3
	_box(c + Vector3(0.0, -DEEP, 0.0), Vector3(POND_W * 2.0, 0.02, POND_D * 2.0), mud)
	for sgn: float in [-1.0, 1.0]:
		_box(c + Vector3(sgn * POND_W, -DEEP * 0.5, 0.0), Vector3(0.01, DEEP, POND_D * 2.0), mud)
		_box(c + Vector3(0.0, -DEEP * 0.5, sgn * POND_D), Vector3(POND_W * 2.0, DEEP, 0.01), mud)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ocean.gdshader")
	# its depth (the shader's map: the floor DEEP down everywhere round here)
	var img := Image.create(4, 4, false, Image.FORMAT_RF)
	img.fill(Color(POND - DEEP, 0.0, 0.0, 1.0))
	m.set_shader_parameter("height_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter("map_size", 4.0)
	m.set_shader_parameter("map_domain", 400.0)
	m.set_shader_parameter("map_origin", Vector2(-200.0, -200.0))
	m.set_shader_parameter("sun_direction", _sun_dir)
	# calm: a breath of wind over a pond, no swell
	m.set_shader_parameter("sea_state", 0.02)
	m.set_shader_parameter("swell_height", 0.0)
	m.set_shader_parameter("peak_length", 2.0)
	m.set_shader_parameter("choppiness", 0.3)
	m.set_shader_parameter("absorption", Vector3(1.2, 0.6, 0.5)) # (a pond's water: brown green, not the clear sea's)
	m.set_shader_parameter("scatter_color", Vector3(0.02, 0.035, 0.02))
	m.set_shader_parameter("crest_color", Vector3(0.1, 0.18, 0.1))
	# the surface: a grid of 1 cm cells (its spacing in UV.x, as the sea's)
	const CELL := 0.01
	var nx := int(POND_W * 2.0 / CELL)
	var nz := int(POND_D * 2.0 / CELL)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var q := [Vector2(ix, iz), Vector2(ix + 1, iz), Vector2(ix + 1, iz + 1), Vector2(ix, iz + 1)]
			for e in [0, 2, 1, 0, 3, 2]:
				var g: Vector2 = q[e]
				st.set_uv(Vector2(CELL, 0.0))
				st.add_vertex(Vector3(-POND_W + g.x * CELL, 0.0, -POND_D + g.y * CELL))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.position = Vector3(c.x, POND, c.z)
	add_child(mi)


func _isopod_station() -> void:
	var c := _station(15)
	for k in 10:
		var leaf := Beetles.leaf()
		leaf.position = c + Vector3(randf_range(-0.12, 0.12), 0.0002 * k, randf_range(-0.12, 0.12))
		leaf.rotation.y = randf() * TAU
		leaf.scale = Vector3(0.7, 1.0, 0.7)
		(leaf.get_child(0) as MeshInstance3D).material_override = _plain(Color(0.42, 0.3, 0.16).lerp(Color(0.28, 0.2, 0.11), randf()))
		add_child(leaf)
	pillbug = IsopodScript.new()
	add_child(pillbug)
	pillbug.place(c, 0.3)
	pillbug.wander(c, 0.12)
	for k in 2:
		var y := IsopodScript.new(true)
		add_child(y)
		y.place(c + Vector3(0.06 * (k * 2 - 1), 0.0, 0.08), randf() * TAU)
		y.grow(0.5, 60.0)
		y.wander(c + Vector3(0.0, 0.0, 0.08), 0.06)


## The deer mice: a female and a male, her nest (a ball of grass), seeds
## about.
func _mouse_station() -> void:
	var c := _station(16)
	_nest = MouseScript.nest()
	_nest.position = c + Vector3(0.15, 0.0, -0.1)
	add_child(_nest)
	mouse_f = MouseScript.new()
	add_child(mouse_f)
	mouse_f.place(c, 0.4)
	mouse_f.home_nest = _nest
	mouse_f.wander(c, 0.25)
	mouse_m = MouseScript.new()
	mouse_m.male = true
	add_child(mouse_m)
	mouse_m.place(c + Vector3(-0.15, 0.0, 0.12), 2.0)
	mouse_m.wander(c, 0.3)
	for k in 4:
		_new_seed()


func _new_seed() -> Node3D:
	var c := _station(16)
	var sd := MouseScript.sunflower_seed()
	sd.position = c + Vector3(randf_range(-0.22, 0.22), 0.0, randf_range(-0.15, 0.22))
	sd.rotation.y = randf() * TAU
	add_child(sd)
	_seeds.append(sd)
	return sd


## The nearest seed to p (a new one, if there are none left).
func _seed_near(p: Vector3) -> Node3D:
	var best: Node3D = null
	for sd in _seeds:
		if is_instance_valid(sd) and not sd.has_meta("taken") and (best == null or (sd as Node3D).position.distance_to(p) < best.position.distance_to(p)):
			best = sd
	if best == null:
		best = _new_seed()
	best.set_meta("taken", true)
	return best


## A male for each female (not the ants': their queens').
func _male_partners() -> void:
	var m := MonarchScript.new()
	m.male = true
	add_child(m)
	m.place(_station(0) + Vector3(0.2, 0.6, 0.1))
	m.fly(_station(0), 0.4)
	males["monarch"] = m
	var mo := MothScript.new()
	mo.male = true
	add_child(mo)
	mo.place(_station(1) + Vector3(-0.2, 0.35, 0.1))
	mo.search(_station(1), 0.4, [])
	males["moth"] = mo
	var w := Wasp.new()
	w.male = true
	add_child(w)
	w.place(_station(2) + Vector3(-0.15, 0.3, 0.1))
	w.seek_food(_station(2), 0.5)
	males["wasp"] = w
	var h := HopperScript.new()
	h.male = true
	add_child(h)
	h.place(_station(7) + Vector3(-0.15, 0.0, -0.1), 2.5)
	h.wander(_station(7), 0.2)
	males["hopper"] = h
	_new_mantis_male()
	for k in 2:
		var kind := "rattler" if k == 0 else "milk"
		var sn := SnakeScript.new(kind)
		sn.male = true
		add_child(sn)
		sn.place(_station(9 + k) + Vector3(-0.3, 0.0, -0.4), Vector3.RIGHT)
		sn.wander(_station(9 + k), 0.6)
		males[kind] = sn
	var kinds := ["wolf", "fishing", "funnel", "argiope"]
	for k in 4:
		var c := _station(11 + k)
		var sp := SpiderScript.new(kinds[k])
		sp.male = true
		add_child(sp)
		var at := c + Vector3(0.15, 0.0, 0.2)
		if kinds[k] == "fishing": # (on the water too)
			at = c + Vector3(0.15, POND, 0.15)
			sp.height = func(_x: float, _z: float) -> float: return POND
		elif kinds[k] == "argiope": # (in the grass below her web)
			at = c + Vector3(0.2, 0.0, 0.15)
		sp.place(at, 1.0)
		sp.wander(at, 0.08)
		males["spider%d" % k] = sp
	var pb := IsopodScript.new()
	pb.male = true
	add_child(pb)
	pb.place(_station(15) + Vector3(-0.08, 0.0, -0.05), 1.0)
	pb.wander(_station(15), 0.12)
	males["pillbug"] = pb


func _new_mantis_male() -> void:
	var mm := MantisScript.new()
	mm.male = true
	add_child(mm)
	mm.place(_station(8) + Vector3(-0.15, 0.0, 0.25), 2.6)
	mm.stalk(_station(8) + Vector3(-0.1, 0.0, 0.2), 0.08)
	males["mantis"] = mm


## Every pair mates (each its own way).
func _mate_all() -> void:
	var m = males.get("mantis")
	if not is_instance_valid(m) or m.dead: # (the last one eaten: another)
		_new_mantis_male()
	var pairs := [[males.monarch, monarch], [males.moth, moth], [males.wasp, wasp], [males.hopper, hopper], [males.mantis, mantis],
			[males.rattler, rattler], [males.milk, milk], [males.pillbug, pillbug], [mouse_m, mouse_f]]
	for k in 4:
		var sm = males["spider%d" % k]
		if is_instance_valid(sm) and sm.dead: # (the garden spider's, dead on her: another)
			sm = SpiderScript.new(spiders[k].kind)
			sm.male = true
			add_child(sm)
			sm.place(_station(11 + k) + Vector3(0.2, 0.0, 0.15), 1.0)
			males["spider%d" % k] = sm
		pairs.append([sm, spiders[k]])
	for pr: Array in pairs:
		if is_instance_valid(pr[0]) and is_instance_valid(pr[1]):
			pr[0].call("mate", pr[1])
	june.mate(1, 0)
	lady.mate(1, 0)


## The garden spider's orb: round a spot among the branch, the stems and
## the post (a little off each time, its plane a little turned: so another
## set of contact points each time), moored to what's found there; three
## fixed points, if not enough is.
func _spin_orb(sp: Node, k: int) -> void:
	var c := _station(14)
	var r := RandomNumberGenerator.new()
	r.seed = k
	var centre := c + Vector3(r.randf_range(-0.08, 0.08), r.randf_range(0.28, 0.38), -0.05)
	var n := Vector3.BACK.rotated(Vector3.UP, r.randf_range(-0.3, 0.3))
	if not sp.call("spin_orb_auto", centre, n, 0.5):
		sp.call("spin_orb", c + Vector3(0.0, 0.59, -0.05), c + Vector3(-0.22, 0.2, -0.05), c + Vector3(0.24, 0.18, -0.05))


## A box that's solid (a collider: something a web can be moored to).
func _solid(at: Vector3, size: Vector3, col: Color) -> Node3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _plain(col)
	body.add_child(mi)
	add_child(body)
	return body


## A fly for each spider to hunt: on the ground before the wolf spider, on
## the water before the fishing spider, landed on the grass spider's sheet,
## caught in the garden spider's web.
func _spiders_hunt() -> void:
	for sp in spiders:
		var f := MantisScript.fly_prey()
		add_child(f)
		var p: Vector3 = sp.get("_pos")
		match sp.kind:
			"funnel":
				var w: Node3D = sp.web
				if not is_instance_valid(w):
					f.queue_free()
					continue
				var a := randf() * TAU
				var at := w.position + Vector3(cos(a), 0.0, sin(a)) * 0.07
				at.y = w.call("surface_y", at.x, at.z)
				f.position = at
			"argiope":
				var w: Node3D = sp.web
				if not is_instance_valid(w):
					f.queue_free()
					continue
				var n: int = w.call("count")
				f.position = w.call("point", int(n * randf_range(0.45, 0.85)))
				f.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			_:
				var a := randf() * TAU
				f.position = p + Vector3(cos(a), 0.0, sin(a)) * 0.15
		sp.hunt(f)


## The young eat: the larvae where they are; the grasshopper nymphs at a
## leaf; the mantis nymphs at a small fly; the young snakes a small mouse.
func _young_eat() -> void:
	for c in get_children():
		var sc: Script = c.get_script()
		if sc == LarvaScript:
			c.call("eat")
		elif sc == HopperScript and c.get("nymph"):
			var at: Vector3 = (c as Node3D).position + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03))
			var leaf := Beetles.leaf()
			leaf.position = Vector3(at.x, 0.0, at.z)
			leaf.scale = Vector3(0.5, 1.0, 0.5)
			add_child(leaf)
			c.call("feed", Vector3(at.x, 0.001, at.z))
		elif sc == MantisScript and c.get("nymph"):
			var f := MantisScript.fly_prey()
			f.scale = Vector3.ONE * 0.4
			f.position = (c as Node3D).position + Vector3(randf_range(-0.03, 0.03), 0.001, randf_range(0.02, 0.04))
			add_child(f)
			c.call("strike", f.position + Vector3(0.0, 0.003, 0.0), f)
		elif sc == SpiderScript and c.get("young") and c.get("_mother") == null:
			var f := MantisScript.fly_prey()
			f.scale = Vector3.ONE * 0.35
			f.position = (c as Node3D).get("_pos") + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(0.02, 0.04))
			add_child(f)
			c.call("hunt", f)
		elif sc == IsopodScript and c.get("young"):
			c.call("eat", (c as Node3D).get("_pos") + Vector3(randf_range(-0.01, 0.01), 0.0, randf_range(-0.01, 0.01)))
		elif sc == MouseScript and c.get("young") and float(c.get("size")) >= 0.25:
			c.call("eat", _seed_near((c as Node3D).get("_pos")))
		elif sc == SnakeScript and c.get("young"):
			var m := SnakeScript.mouse(0.35)
			var a := randf() * TAU
			m.position = (c as Node3D).get("_pos") + Vector3(cos(a), 0.0, sin(a)) * 0.15
			add_child(m)
			c.call("eat", m)


## Each through its orders, one after another: each a Callable giving the
## order; the next given once the creature says the last's done (or not).
func _sequence(c: Object, orders: Array) -> void:
	var left := orders.duplicate() # (shared with the lambda: it's an Array)
	var next := func(_name := "", _ok := true) -> void:
		if not left.is_empty():
			(left.pop_front() as Callable).call()
	c.connect("action_finished", next)
	next.call()


## The steering layer, as a state machine would use it.
func _pilot_demo() -> void:
	var c7 := _station(7)
	_sequence(hopper, [
		func() -> void: hopper.go(Vector3.LEFT, -1.0, 2.5),
		func() -> void: hopper.face(Vector3.BACK),
		func() -> void: hopper.act("hop", {"at": hopper.position + Vector3.BACK * 0.2}),
		func() -> void: hopper.go_to(_hopper_leaf + Vector3(0.0, 0.0, 0.03)),
		func() -> void: hopper.act("feed", {"at": _hopper_leaf, "seconds": 3.0}),
	])
	_sequence(mantis, [
		func() -> void: mantis.go(Vector3.RIGHT, -1.0, 3.0),
		func() -> void: mantis.act("watch", {"at": _station(8) + Vector3(0.0, 0.05, 0.2), "seconds": 2.5}),
		func() -> void: mantis.act("groom", {"seconds": 4.0}),
		func() -> void: mantis.go_to(_station(8)),
	])
	_sequence(rattler, [
		func() -> void: rattler.go(Vector3.FORWARD, -1.0, 4.0),
		func() -> void: rattler.act("coil", {"seconds": 5.0}),
		func() -> void: rattler.go_to(_station(9) + Vector3(0.4, 0.0, 0.3)),
	])
	_sequence(milk, [
		func() -> void: milk.go_to(_station(10) + Vector3(0.5, 0.0, -0.4)),
		func() -> void: milk.go(Vector3.BACK, 0.3, 3.0),
		func() -> void: milk.act("coil", {"seconds": 4.0}),
	])
	_sequence(moth, [
		func() -> void: moth.go(Vector3.RIGHT, -1.0, 2.0),
		func() -> void: moth.go_to(_station(1) + Vector3(0.0, 0.3, 0.0)),
		func() -> void: moth.act("lay", {"spots": _moth_leaves.map(func(l): return l[0]), "normals": _moth_leaves.map(func(l): return l[1])}),
	])
	_sequence(mouse_m, [
		func() -> void: mouse_m.go(Vector3.RIGHT, -1.0, 1.5),
		func() -> void: mouse_m.act("eat", {"seed": _seed_near(mouse_m.get("_pos"))}),
		func() -> void: mouse_m.act("groom", {"seconds": 3.0}),
	])
	var lb: Object = lady.member(0)
	_sequence(lb, [
		func() -> void: lb.go(Vector3.FORWARD, -1.0, 2.0),
		func() -> void: lb.act("fly", {"seconds": 3.0}),
		func() -> void: lb.go_to(Vector3(0.03, 0.0, 0.03)),
	])


## A fly on the mantis's leaf, for it to catch.
func _new_prey() -> void:
	if is_instance_valid(_prey):
		return
	_prey = MantisScript.fly_prey()
	_prey.position = _station(8) + Vector3(-0.12, 0.002, 0.1)
	add_child(_prey)


func _new_pupae() -> void:
	for p in _pupae:
		if is_instance_valid(p):
			p.queue_free()
	_pupae.clear()
	var ch := PupaScript.new("monarch")
	ch.position = _station(0) + Vector3(0.25, 0.316, -0.15) # (hanging under the twig)
	add_child(ch)
	_pupae.append(ch)
	var mp := PupaScript.new("hemaris")
	mp.position = _station(1) + MOTH_PUPA
	mp.rotation.y = MOTH_PUPA_TURN
	mp.perch_at = _moth_perch
	mp.perch_normal = _moth_perch_n
	add_child(mp)
	_pupae.append(mp)


# --- keys ----------------------------------------------------------------------------

func _lay_all() -> void:
	var c0 := _station(0)
	monarch.lay(_monarch_leaves.map(func(l): return l[0]), _monarch_leaves.map(func(l): return l[1]), func() -> void: monarch.fly(c0, 0.4))
	var c1 := _station(1)
	moth.lay(_moth_leaves.map(func(l): return l[0]), _moth_leaves.map(func(l): return l[1]), func() -> void: moth.search(c1, 0.4, []))
	wasp.lay_eggs(_cells.slice(0, 4), Vector3.UP)
	june.lay(0, Vector3(-0.05, 0.0, 0.0))
	lady.lay(0, Vector3(0.02, 0.0, -0.02))
	hopper.lay(_station(7) + Vector3(0.05, 0.0, -0.08))
	mantis.lay(_stem_foot + Vector3(0.0, 0.006, 0.0))
	rattler.lay(5) # (born, each in its membrane)
	milk.lay(6)
	for sp in spiders:
		sp.lay()
	pillbug.lay()
	mouse_f.birth(4, _nest)


func _hatch_eggs() -> void:
	var all: Array = []
	for list: Array in [_ant_eggs, monarch.eggs, moth.eggs, wasp.eggs, june.eggs, lady.eggs, milk.eggs]:
		all.append_array(list)
	for e in all:
		if is_instance_valid(e):
			e.call("hatch")
	_ant_eggs.clear()
	# the grasshopper's pods and the mantis's egg cases: their nymphs out
	for p in hopper.pods + mantis.oothecae:
		if is_instance_valid(p):
			p.call("hatch")
	for sp in spiders: # (the spiders' sacs, carried or left)
		for sac in sp.sacs:
			if is_instance_valid(sac):
				sac.call("hatch")
	pillbug.hatch()


func _hatch_all() -> void:
	for k in _pupae.size():
		var p: PupaScript = _pupae[k]
		if not is_instance_valid(p):
			continue
		var c := _station(k)
		p.eclose(func(a: Node3D) -> void:
			if a.has_method("fly"):
				a.call("fly", c, 0.4)
			else:
				a.call("search", c, 0.4, []))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				_lay_all()
			KEY_2:
				_hatch_all()
			KEY_3:
				_new_pupae()
			KEY_4:
				_hatch_eggs()
			KEY_6:
				var a := randf() * TAU
				hopper.hop(_station(7) + Vector3(cos(a), 0.0, sin(a)) * 0.2)
				_at = 7
				_say()
			KEY_7:
				var a := randf() * TAU
				hopper.fly(_station(7) + Vector3(cos(a), 0.0, sin(a)) * 0.35)
				_at = 7
				_say()
			KEY_8:
				hopper.feed(_hopper_leaf + Vector3(0.0, 0.002, 0.0))
				_at = 7
				_say()
			KEY_9:
				_new_prey()
				mantis.strike(_prey.position + Vector3(0.0, 0.006, 0.0), _prey)
				_at = 8
				_say()
			KEY_0:
				var a := randf() * TAU
				mantis.fly(_station(8) + Vector3(cos(a), 0.0, sin(a)) * 0.3)
				_at = 8
				_say()
			KEY_G:
				mantis.groom()
				_at = 8
				_say()
			KEY_R:
				rattler.eat(_new_mouse(0))
				_go(9)
			KEY_M:
				milk.eat(_new_mouse(1))
				_go(10)
			KEY_C:
				rattler.coil()
				milk.coil()
			KEY_W:
				rattler.wander(_station(9), 0.7)
				milk.wander(_station(10), 0.55)
			KEY_Y:
				_young_eat()
			KEY_P:
				_pilot_demo()
			KEY_F:
				_spiders_hunt()
			KEY_S:
				for k in [2, 3]:
					var sp = spiders[k] # (a Spider: its web, its kind)
					var c := _station(11 + k)
					if is_instance_valid(sp.web):
						sp.web.queue_free()
					if sp.kind == "funnel":
						sp.spin_funnel(c, 0.14)
					else:
						_spin_orb(sp, randi())
			KEY_K:
				_mate_all()
			KEY_E:
				for mo: MouseScript in [mouse_f, mouse_m]:
					mo.eat(_seed_near(mo.get("_pos")))
				_go(16)
			KEY_Q:
				mouse_f.groom()
				mouse_m.groom()
				_go(16)
			KEY_O:
				for c in get_children():
					if c.get_script() == IsopodScript:
						c.call("roll", 5.0)
			KEY_5:
				for k in 2:
					_ant_pile(k)
			KEY_TAB:
				_go((_at + (NAMES.size() - 1 if e.shift_pressed else 1)) % NAMES.size())
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.03)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 6.0)


## To station i (the camera further off for the snakes).
func _go(i: int) -> void:
	_at = i
	_dist = 2.2 if i == 9 or i == 10 else minf(_dist, 0.8)
	_say()


func _say() -> void:
	_label.text = "%s   (Tab / Shift+Tab: the next)\n1 all lay eggs   2 the pupae hatch   3 new pupae   4 the eggs hatch   5 new ant eggs\n6 grasshopper hops   7 flies   8 eats   9 mantis strikes the fly   0 flies   G grooms\nR rattlesnake eats   M milk snake eats   C snakes coil   W off again   Y the young eat   P steered\nF the spiders hunt   S the web spiders spin anew   O the pill bugs roll up   K they mate   E the mice eat   Q they wash\nSpace slow motion   drag: turn round   wheel: nearer / further" % NAMES[_at]


func _process(dt: float) -> void:
	var want := _station(_at) + Vector3(0.0, 0.08, 0.0)
	_focus = _focus.lerp(want, 1.0 - exp(-4.0 * dt / maxf(Engine.time_scale, 0.01)))
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	mi.material_override = _plain(c)
	add_child(mi)
	return mi


func _plain(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m
