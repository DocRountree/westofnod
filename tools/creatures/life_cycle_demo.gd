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
## P steered by the steering layer (pilot.gd), as a state machine would: the
##   grasshopper, the mantis, the snakes, the moth, a lady beetle, each
##   through a few orders, one after another as each says it's done
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

const NAMES := ["monarch", "hummingbird clearwing", "paper wasp", "carpenter ant (queen)", "red harvester (queen)", "June bug", "convergent lady beetle", "differential grasshopper", "Carolina mantis", "eastern diamondback rattlesnake", "eastern milk snake"]
const SnakeScript := preload("res://scripts/creatures/snake.gd")
const HopperScript := preload("res://scripts/creatures/grasshopper.gd")
const MantisScript := preload("res://scripts/creatures/mantis.gd")
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
var hopper: HopperScript
var mantis: MantisScript
var _hopper_leaf := Vector3.ZERO
var _stem_foot := Vector3.ZERO # (where the mantis builds its egg case)
var _prey: Node3D
var rattler: SnakeScript
var milk: SnakeScript
var _mice := [null, null]
const MOTH_PUPA := Vector3(0.2, 0.002, -0.2) # (off the clearwing's station)
const MOTH_PUPA_TURN := 0.6
var _moth_perch := Vector3.ZERO # (a stem by its pupa, to climb and hang from)
var _moth_perch_n := Vector3.BACK


func _station(i: int) -> Vector3:
	# (the snakes, life size, given more room)
	return Vector3(i * GAP + (1.2 if i >= 9 else 0.0) + (1.8 if i >= 10 else 0.0), 0.0, 0.0)


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
	sun.directional_shadow_max_distance = 4.0
	add_child(sun)
	_box(Vector3(GAP * 5.0 + 1.5, -0.005, 0.0), Vector3(GAP * 11.0 + 5.0, 0.01, 3.0), Color(0.36, 0.4, 0.22))
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
	june.setup(1, Vector3.ZERO, 0.06)
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
	lady.setup(1, Vector3.ZERO, 0.04)
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
	_dist = 2.2 if i >= 9 else minf(_dist, 0.8)
	_say()


func _say() -> void:
	_label.text = "%s   (Tab / Shift+Tab: the next)\n1 all lay eggs   2 the pupae hatch   3 new pupae   4 the eggs hatch   5 new ant eggs\n6 grasshopper hops   7 flies   8 eats   9 mantis strikes the fly   0 flies   G grooms\nR rattlesnake eats   M milk snake eats   C snakes coil   W off again   Y the young eat   P steered   Space slow motion   drag: turn round   wheel: nearer / further" % NAMES[_at]


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
