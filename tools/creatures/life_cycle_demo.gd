extends Node3D
## The creatures' life cycles, a station each along a plain:
## godot --path . res://tools/creatures/life_cycle_demo.tscn
##
## monarch: the adult, milkweed and leaves to lay on, a caterpillar, a
##   chrysalis hanging from a twig
## hummingbird clearwing: the adult, leaves (it lays hovering), a hornworm,
##   a pupa in its cocoon in the litter
## paper wasp: the adult and its comb, grubs in some of its cells
## carpenter ants, red harvesters: a queen each, and larvae
## June bug: the adult, its white grub, curled, on the soil
## convergent lady beetle: the adult on a leaf, its larva about
##
## 1 every adult lays its eggs (Brood's: the butterflies one to a leaf, the
##   wasp one to a cell, the queens and beetles a pile or a cluster)
## 2 the pupae hatch: the adult out, its wings filling out; then off
## 3 new pupae
## Tab / Shift+Tab: the next station   Space slow motion
## drag: turn round   wheel: nearer / further

const MothScript := preload("res://scripts/creatures/hummingbird_moth.gd")
const MonarchScript := preload("res://scripts/creatures/monarch.gd")
const HarvesterScript := preload("res://scripts/creatures/harvester_ants.gd")
const JuneScript := preload("res://scripts/creatures/june_beetles.gd")
const LadyScript := preload("res://scripts/creatures/lady_beetles.gd")
const Flowers := preload("res://tools/creatures/demo_flowers.gd")
const LarvaScript := preload("res://scripts/creatures/larva.gd")
const PupaScript := preload("res://scripts/creatures/pupa.gd")

const NAMES := ["monarch", "hummingbird clearwing", "paper wasp", "carpenter ant (queen)", "red harvester (queen)", "June bug", "convergent lady beetle"]
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


func _station(i: int) -> Vector3:
	return Vector3(i * GAP, 0.0, 0.0)


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
	_box(Vector3(GAP * 3.0, -0.005, 0.0), Vector3(GAP * 7.0 + 1.0, 0.01, 2.0), Color(0.36, 0.4, 0.22))
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
	mp.position = _station(1) + Vector3(0.2, 0.002, -0.2)
	mp.rotation.y = 0.6
	add_child(mp)
	_pupae.append(mp)


# --- keys ----------------------------------------------------------------------------

func _lay_all() -> void:
	var c0 := _station(0)
	monarch.lay(_monarch_leaves.map(func(l): return l[0]), _monarch_leaves.map(func(l): return l[1]), func() -> void: monarch.fly(c0, 0.4))
	var c1 := _station(1)
	moth.lay(_moth_leaves.map(func(l): return l[0]), _moth_leaves.map(func(l): return l[1]), func() -> void: moth.search(c1, 0.4, []))
	wasp.lay_eggs(_cells.slice(0, 4), Vector3.UP)
	for q: AntColony in queens:
		q.lay(0, Vector3(0.0, 0.0, -0.02))
	june.lay(0, Vector3(-0.05, 0.0, 0.0))
	lady.lay(0, Vector3(0.02, 0.0, -0.02))


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
			KEY_TAB:
				_at = (_at + (NAMES.size() - 1 if e.shift_pressed else 1)) % NAMES.size()
				_say()
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


func _say() -> void:
	_label.text = "%s   (Tab / Shift+Tab: the next)\n1 all lay eggs   2 the pupae hatch   3 new pupae   Space slow motion   drag: turn round   wheel: nearer / further" % NAMES[_at]


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
