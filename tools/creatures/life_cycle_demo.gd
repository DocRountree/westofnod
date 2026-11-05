extends Node3D
## The creatures' life cycles, a station each along a plain:
## godot --path . res://tools/creatures/life_cycle_demo.tscn
##
## monarch: the adult, milkweed and leaves to lay on, a caterpillar, a
##   chrysalis hanging from a twig
## hummingbird clearwing: the adult, coneflowers and asters (its nectar), leaves (it lays hovering), a hornworm,
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
## wolf spider, fishing spider (on a pond, a little school of sailfin
##   mollies in it), grass spider (its funnel web
##   spun as it starts), yellow garden spider (its orb spun off a branch),
##   pill bugs in leaf litter (a female and young)
## deer mouse (life size): a female, a male, her grass nest, seeds
## green anole (life size): a female, a male (his dewlap), flies to catch
## Arizona bark scorpion: a female, a male, crickets, on sand
## snowshoe hare (life size, its summer coat): a female, a male, clover, a
##   willow shoot
## red fox (life size): a vixen, a dog fox, her den, deer mice to hunt
## bobcat (life size): a female, a male, her rock den, a hare to hunt
## coyote, grey wolf (life size): a female and a male each, her den, prey
##   (mice and a hare; a hare)
## black bear, brown bear (life size): a female, a male and another (their
##   colour phases: black, cinnamon, brown; brown, grizzled, blond), her
##   den, berry bushes, a tree to rub on
## American bison (life size): two bulls, two cows, a calf, a dust wallow
## white-tailed deer (life size): a doe with twin fawns and a buck in velvet
##   (summer); two bucks and a doe (winter); a shrub, a sapling to rub
## trigonalid wasp: a female and a male, fleabane for nectar, leaves to lay
##   along (no nest)
## eastern fox squirrel: a female and a male, their tree (her drey in it),
##   nuts to eat (E) and cache (B); F up the tree, D its tail flicked
## eastern grey squirrel: the same (after the beavers)
## blue-winged grasshopper: a female, a male and a nymph, gravel to lay in,
##   a leaf; F its flight (the hindwings blue, black banded)
## common green darner: a male and a female over a little pond, reeds in it
##   (perches, and stems to lay in and climb out on), midges; two nymphs on
##   the pond's floor (E hunt / strike, Z perch, 1 lay, K mate: tandem, the
##   wheel, laying in tandem; F a nymph out of the water and emerging, the
##   adults patrolling; 2 the eggs hatching)
## moose: a bull (in velvet), a cow and her calf, willows and a pond (B wade
##   out, feeding under the water)
## northern leopard frog: a female and a male on the bank of a little pond,
##   reeds in it, tadpoles (E hunt: a fly; D his call; K amplexus, 1 her egg
##   mass; F a hop, a tadpole changing; X into the water; 2 the eggs hatching)
## painted turtle: a female and a male, a pond with a log to bask on, a bank
##   to nest in, a hatchling (Z / A bask, F dive, X into its shell, E eat,
##   K his claws fluttered at her face, 1 her nest dug and laid, 2 it hatching)
## North American beaver: a female and a male, a bank with aspens and sticks
##   (E eat bark, H fell an aspen and take it to the lodge), a pond and their
##   lodge (B swim, X tail slap and dive, M mud on the lodge)
## (every station a male too, but the ants': the female's partner)
##
## THE KEYS (the same for every creature, acting only on those at the
## station in view; Tab / Shift+Tab: the next): 1 lay eggs / give birth,
## 2 hatch / come out, 3 new pupae, E eat, H hunt, K mate, G groom, Z sleep /
## rest, F fly / hop, X alarm (flee, roll up, coil, sting, scatter), D display
## / call (a dewlap, a thump, a howl, standing up), V the young play, N nurse,
## B forage, S spin a web, M mark (a bear: rubbing on its tree), A sit, W back
## to their own ways, P steered (pilot.gd: the grasshopper, the mantis, the
## snakes, the moth, a lady beetle, the male mouse through a few orders).
## Each does it its own way: E the larvae chew, the hunters' prey is set
## before them (the fishing spider's a molly up from the pond), the bears
## strip berries; K each pair its own (the male mantis eaten, the garden
## spider's male dead on her; the spiders' males first charging their palps
## at a sperm web); X the snakes coil, the pill bugs roll, the hares flee, the
## scorpions sting, the mollies scatter; D the anoles' dewlap, the hares'
## thump, the dogs' howl, the bears standing up.
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
		"Carolina wolf spider", "six-spotted fishing spider", "grass spider (funnel weaver)", "yellow garden spider", "pill bug", "deer mouse",
		"green anole", "Arizona bark scorpion", "snowshoe hare", "red fox", "bobcat", "coyote", "grey wolf", "American black bear", "brown bear (grizzly)", "American bison", "white-tailed deer", "trigonalid wasp", "eastern fox squirrel", "North American beaver", "eastern grey squirrel", "blue-winged grasshopper", "common green darner", "moose", "northern leopard frog", "painted turtle"]
const SpiderScript := preload("res://scripts/creatures/spider.gd")
const IsopodScript := preload("res://scripts/creatures/isopod.gd")
const SnakeScript := preload("res://scripts/creatures/snake.gd")
const HopperScript := preload("res://scripts/creatures/grasshopper.gd")
const BlueHopperScript := preload("res://scripts/creatures/blue_winged_grasshopper.gd")
const DragonflyScript := preload("res://scripts/creatures/dragonfly.gd")
const MantisScript := preload("res://scripts/creatures/mantis.gd")
const MouseScript := preload("res://scripts/creatures/mouse.gd")
const MolliesScript := preload("res://scripts/creatures/mollies.gd")
const HareScript := preload("res://scripts/creatures/hare.gd")
const FoxScript := preload("res://scripts/creatures/red_fox.gd")
const BobcatScript := preload("res://scripts/creatures/bobcat.gd")
const CanidScript := preload("res://scripts/creatures/canid.gd")
const CoyoteScript := preload("res://scripts/creatures/coyote.gd")
const WolfScript := preload("res://scripts/creatures/grey_wolf.gd")
const UrsidScript := preload("res://scripts/creatures/ursid.gd")
const BlackBearScript := preload("res://scripts/creatures/black_bear.gd")
const BrownBearScript := preload("res://scripts/creatures/brown_bear.gd")
const AnoleScript := preload("res://scripts/creatures/anole.gd")
const ScorpionScript := preload("res://scripts/creatures/scorpion.gd")
const BisonScript := preload("res://scripts/creatures/bison.gd")
const DeerScript := preload("res://scripts/creatures/deer.gd")
const MooseScript := preload("res://scripts/creatures/moose.gd")
const FrogScript := preload("res://scripts/creatures/frog.gd")
const TurtleScript := preload("res://scripts/creatures/turtle.gd")
const SquirrelScript := preload("res://scripts/creatures/fox_squirrel.gd")
const GreySqScript := preload("res://scripts/creatures/grey_squirrel.gd")
const BeaverScript := preload("res://scripts/creatures/beaver.gd")
const TrigScript := preload("res://scripts/creatures/trigonalid.gd")
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
var _moth_flowers: Array = [] # the clearwing's flowers' heads (its nectar)
var _sq_nuts: Array = [] # (the squirrels' nuts, on the ground)
var _sq_tree := Vector3.ZERO
var _df_midges: Array = [] # (the darners' prey)
var _df_centre := Vector3.ZERO
var _bv_saplings: Array = [] # (the beavers': to fell)
var _bv_sticks: Array = [] # (to eat)
var _bv_bank := 0.0 # (where the bank ends, x)
var _trig_heads: Array = [] # the trigonalid's flowers' heads
var _trig_leaves: Array = [] # its leaves' tops [point, normal]
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
var anole_f: AnoleScript
var anole_m: AnoleScript
var scorp_f: ScorpionScript
var scorp_m: ScorpionScript
var hare_f: HareScript
var hare_m: HareScript
var _hare_food: Array = []
var fox_f: Node3D
var fox_m: Node3D
var cat_f: Node3D
var cat_m: Node3D
var _fox_den: Node3D
var _cat_den: Node3D
var _fox_mice: Array = []
var _cat_hare: Node3D
var coy_f: Node3D
var coy_m: Node3D
var wolf_f: Node3D
var wolf_m: Node3D
var _coy_den: Node3D
var _wolf_den: Node3D
var _moose_sapling := Vector3.ZERO # (the bull moose's, to rub)
var _deer_shrub := Vector3.ZERO # (the deer's: to browse)
var _deer_sapling := Vector3.ZERO # (to rub)
var _hares := {} # station -> its hare (to be hunted)
var _pond_mollies: Node3D
var bears: Array = [] # [female, male, another] each kind: black, brown
var _bear_dens: Array = []
var _bushes: Array = [] # each kind's
var _rub_trees: Array = []
const POND := -0.004 # m: the pond's surface, a little below the plain's
const POND_W := 0.42 # (its half width, x)
const POND_D := 0.36 # (its half depth, z)
const PLAIN_D := 3.0 # (the plain's half depth, z)
const MOOSE_PW := 1.6 # (the moose's pond: half width, half depth, deep)
const MOOSE_PD := 1.0
const MOOSE_DEEP := 0.45
const FROG_PW := 0.5 # (the frogs')
const FROG_PD := 0.4
const FROG_DEEP := 0.2
const TURTLE_PW := 0.7 # (the turtles')
const TURTLE_PD := 0.5
const TURTLE_DEEP := 0.3
const MOTH_PUPA := Vector3(0.2, 0.002, -0.2) # (off the clearwing's station)
const MOTH_PUPA_TURN := 0.6
var _moth_perch := Vector3.ZERO # (a stem by its pupa, to climb and hang from)
var _moth_perch_n := Vector3.BACK


func _station(i: int) -> Vector3:
	# (the snakes, life size, given more room)
	return Vector3(i * GAP + (1.2 if i >= 9 else 0.0) + (1.8 if i >= 10 else 0.0) + (1.6 if i >= 11 else 0.0) + (3.0 if i >= 19 else 0.0) + (4.0 if i >= 20 else 0.0) + (4.0 if i >= 21 else 0.0) + (4.0 if i >= 22 else 0.0) + (5.0 if i >= 23 else 0.0) + (6.0 if i >= 24 else 0.0) + (7.0 if i >= 25 else 0.0) + (9.0 if i >= 26 else 0.0) + (9.0 if i >= 27 else 0.0) + (4.5 if i >= 28 else 0.0) + (3.0 if i >= 29 else 0.0) + (5.0 if i >= 30 else 0.0) + (5.0 if i >= 31 else 0.0) + (2.0 if i >= 32 else 0.0) + (4.0 if i >= 33 else 0.0) + (6.0 if i >= 34 else 0.0) + (6.0 if i >= 35 else 0.0) + (3.0 if i >= 36 else 0.0), 0.0, 0.0)


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
	# the plain, holes left in it for the ponds (PONDS: the fishing spider's,
	# the moose's, the frogs', the turtles')
	var x0 := -0.95
	var x1 := _station(NAMES.size() - 1).x + 6.0
	var grass := Color(0.36, 0.4, 0.22)
	var at := x0
	for hole: Array in _ponds():
		var hc: Vector3 = hole[0]
		var hw: float = hole[1]
		var hd: float = hole[2]
		if hc.x - hw > x1: # (a station not made yet)
			continue
		_box(Vector3((at + hc.x - hw) * 0.5, -0.005, 0.0), Vector3(hc.x - hw - at, 0.01, PLAIN_D * 2.0), grass)
		for sgn: float in [-1.0, 1.0]:
			_box(Vector3(hc.x, -0.005, sgn * (hd + PLAIN_D) * 0.5), Vector3(hw * 2.0, 0.01, PLAIN_D - hd), grass)
		at = hc.x + hw
	_box(Vector3((at + x1) * 0.5, -0.005, 0.0), Vector3(x1 - at, 0.01, PLAIN_D * 2.0), grass)
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
	_anole_station()
	_scorpion_station()
	_hare_station()
	_fox_station()
	_bobcat_station()
	_coyote_station()
	_wolf_station()
	_bear_station(0)
	_bear_station(1)
	_bison_station()
	_deer_station()
	_trig_station()
	_squirrel_station()
	_beaver_station()
	_squirrel_station(31, GreySqScript)
	_blue_hopper_station()
	_dragonfly_station()
	_moose_station()
	_frog_station()
	_turtle_station()
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
	# its flowers: purple coneflowers and asters, for its nectar
	_moth_flowers = Flowers.clump(self, "coneflower", Vector2(c.x - 0.22, c.z - 0.18), 0.6, Color(0.42, 0.38, 0.28))
	_moth_flowers.append_array(Flowers.clump(self, "aster", Vector2(c.x + 0.24, c.z + 0.22), 0.5, Color(0.42, 0.38, 0.28)))
	moth = MothScript.new()
	add_child(moth)
	moth.place(c + Vector3(0.0, 0.4, 0.2))
	moth.feed(_moth_flowers)
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


## The blue-winged grasshoppers: a female, a male and a nymph on gravel
## (bare ground to lay in), a leaf.
func _blue_hopper_station() -> void:
	var c := _station(32)
	_box(c + Vector3(0.0, 0.0005, 0.0), Vector3(0.5, 0.002, 0.45), Color(0.55, 0.5, 0.42)) # (gravel)
	for k in 14: # (pebbles)
		_box(c + Vector3(randf_range(-0.22, 0.22), 0.002, randf_range(-0.2, 0.2)), Vector3.ONE * randf_range(0.004, 0.009), Color(0.5, 0.45, 0.38).lerp(Color(0.62, 0.58, 0.52), randf()))
	var leaf := Beetles.leaf()
	leaf.position = c + Vector3(0.16, 0.0, 0.12)
	leaf.scale = Vector3(1.2, 1.0, 1.2)
	add_child(leaf)
	for m in 2:
		var g: Node3D = BlueHopperScript.new()
		g.set("male", m == 1)
		add_child(g)
		g.call("place", c + Vector3(-0.08 + 0.16 * m, 0.0, 0.02), randf() * TAU)
		g.call("wander", c, 0.18)
	var ny: Node3D = BlueHopperScript.new(true, 0.3)
	add_child(ny)
	ny.call("place", c + Vector3(-0.1, 0.0, 0.12), 2.0)
	ny.call("wander", c + Vector3(-0.1, 0.0, 0.12), 0.1)


## The green darners: a little pond (its banks low, its water 9 cm deep),
## reeds standing in it (their tips perches; their stems to lay in and
## climb out on), a swarm of midges over it; a male and a female; two
## nymphs on its floor.
const DF_WATER := 0.09
func _dragonfly_station() -> void:
	var c := _station(33)
	_df_centre = c
	var half := Vector2(0.6, 0.45)
	_box(c + Vector3(0.0, 0.002, 0.0), Vector3(half.x * 2.0, 0.004, half.y * 2.0), Color(0.18, 0.15, 0.1)) # (its mud floor)
	for sgn: float in [-1.0, 1.0]: # (its banks)
		_box(c + Vector3(sgn * (half.x + 0.06), DF_WATER * 0.6, 0.0), Vector3(0.12, DF_WATER * 1.2, half.y * 2.0 + 0.24), Color(0.36, 0.38, 0.22))
		_box(c + Vector3(0.0, DF_WATER * 0.6, sgn * (half.y + 0.06)), Vector3(half.x * 2.0, DF_WATER * 1.2, 0.12), Color(0.36, 0.38, 0.22))
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = half * 2.0
	w.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.16, 0.28, 0.26, 0.6)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.06
	wm.metallic_specular = 0.8
	w.material_override = wm
	w.position = c + Vector3(0.0, DF_WATER, 0.0)
	add_child(w)
	var stems := []
	var perches := []
	for k in 7: # (reeds)
		var a := float(k) / 7.0 * TAU + randf_range(-0.3, 0.3)
		var foot := c + Vector3(cos(a) * half.x * randf_range(0.3, 0.8), 0.0, sin(a) * half.y * randf_range(0.3, 0.8))
		var top := randf_range(0.28, 0.45)
		_box(foot + Vector3(0.0, top * 0.5, 0.0), Vector3(0.006, top, 0.006), Color(0.34, 0.46, 0.18))
		stems.append([foot, foot + Vector3(0.0, top, 0.0)])
		perches.append(foot + Vector3(0.0, top + 0.003, 0.0))
	_df_new_midges(8)
	var land := func(_x: float, _z: float) -> float: return 0.0
	for m in 4:
		var d: Node3D = DragonflyScript.new(m >= 2)
		if m == 1:
			d.set("male", true)
		d.set("water_y", c.y + DF_WATER)
		d.set("floor_y", c.y + 0.004)
		d.set("pond", [c, half])
		d.set("stems", stems)
		d.set("perches", perches)
		d.set("height", land)
		add_child(d)
		if m < 2:
			d.call("place", c + Vector3(-0.3 + 0.6 * m, 0.4, 0.0), randf() * TAU)
			d.call("patrol", c, 0.9)
		else:
			d.call("place", c + Vector3(-0.2 + 0.4 * (m - 2), 0.0, 0.1), randf() * TAU)


func _df_new_midges(n: int) -> void:
	for mg: Node3D in DragonflyScript.midges(n, _df_centre, 0.6):
		add_child(mg)
		_df_midges.append(mg)


## (A darner, adult or nymph: what each key has it do.)
func _dragonfly_do(c: Node, act: String, young: bool) -> void:
	var p := _where(c)
	match act:
		"eat", "hunt":
			if young:
				var a := randf() * TAU
				c.call("strike", p + Vector3(cos(a), 0.0, sin(a)) * 0.02)
			else:
				var live := _df_midges.filter(func(m) -> bool: return is_instance_valid(m) and not m.get("caught"))
				if live.size() < 3:
					_df_new_midges(6)
					live = _df_midges.filter(func(m) -> bool: return is_instance_valid(m) and not m.get("caught"))
				live.sort_custom(func(m1, m2) -> bool: return (m1 as Node3D).position.distance_to(p) < (m2 as Node3D).position.distance_to(p))
				c.call("hunt", live[0])
		"lay":
			if not young and not _flag(c, "male"):
				c.call("lay")
		"fly":
			if young:
				c.call("emerge")
			else:
				c.call("patrol", _df_centre, 0.9)
		"sleep", "sit":
			if not young:
				c.call("perch")
		"alarm":
			c.call("flee", _df_centre + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)))
		"wander":
			if young:
				c.call("crawl", _df_centre, 0.35)
			else:
				c.call("patrol", _df_centre, 0.9)


## The moose: a pond sunk in the plain (45 cm deep: they wade in to feed),
## willows (shrubs to browse; a sapling for the bull to rub), a bull in
## velvet, a cow and her calf.
func _moose_station() -> void:
	var c := _station(34)
	_pond(c, MOOSE_PW, MOOSE_PD, MOOSE_DEEP)
	for k in 3:
		var sh := UrsidScript.berry_bush()
		sh.position = c + Vector3(-2.4 + 4.6 * float(k % 2), 0.0, -1.0 + 0.9 * k)
		sh.scale = Vector3.ONE * 1.3
		add_child(sh)
	_moose_sapling = c + Vector3(2.6, 0.0, 1.1)
	_box(_moose_sapling + Vector3(0.0, 1.0, 0.0), Vector3(0.06, 2.0, 0.06), Color(0.36, 0.3, 0.22))
	var pc := c
	var wet := func(x: float, z: float) -> bool: return absf(x - pc.x) < MOOSE_PW and absf(z - pc.z) < MOOSE_PD
	var ground := func(x: float, z: float) -> float: return -MOOSE_DEEP + 0.02 if absf(x - pc.x) < MOOSE_PW - 0.05 and absf(z - pc.z) < MOOSE_PD - 0.05 else 0.0
	var herd := [[true, Vector3(2.9, 0.0, -0.3)], [false, Vector3(-2.8, 0.0, 0.2)]]
	for h: Array in herd:
		var m: Node3D = MooseScript.new()
		m.set("male", h[0])
		m.set("wet", wet)
		m.set("water_y", POND)
		m.set("height", ground)
		add_child(m)
		var at: Vector3 = c + (h[1] as Vector3)
		m.call("place", at, randf() * TAU)
		m.call("graze", at, 0.8)
		if not h[0]: # (her calf)
			var y: Node3D = MooseScript.new(true)
			y.set("height", ground)
			add_child(y)
			y.call("place", at + Vector3(-0.7, 0.0, 0.6), randf() * TAU)
			y.set("_mother", m)
			y.set("_mode", "follow")
			(m.get("young_ones") as Array).append(y)


## The leopard frogs: a little pond (20 cm deep), reeds standing in it, a
## female and a male on its bank, three tadpoles in it.
func _frog_station() -> void:
	var c := _station(35)
	_pond(c, FROG_PW, FROG_PD, FROG_DEEP)
	var stems := []
	for k in 5:
		var foot := c + Vector3(randf_range(-0.7, 0.7) * FROG_PW, -FROG_DEEP, randf_range(-0.7, 0.7) * FROG_PD)
		var top := randf_range(0.25, 0.4)
		_box(foot + Vector3(0.0, (top + FROG_DEEP) * 0.5, 0.0), Vector3(0.006, top + FROG_DEEP, 0.006), Color(0.34, 0.46, 0.18))
		stems.append([foot, Vector3(foot.x, top, foot.z)])
	var land := func(_x: float, _z: float) -> float: return 0.0
	for m in 5:
		var fr: Node3D = FrogScript.new(m >= 2)
		if m == 1:
			fr.set("male", true)
		fr.set("water_y", POND)
		fr.set("floor_y", -FROG_DEEP + 0.01)
		fr.set("pond", [c, Vector2(FROG_PW, FROG_PD)])
		fr.set("stems", stems)
		fr.set("height", land)
		add_child(fr)
		if m < 2:
			var at := c + Vector3(FROG_PW + 0.12, 0.0, -0.1 + 0.25 * m)
			fr.call("place", at, PI * 0.5)
			fr.call("wander", at, 0.12)
		else:
			fr.call("place", c + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.2, 0.2)), randf() * TAU)


## (A frog, or a tadpole: what each key has it do.)
func _frog_do(c: Node, act: String, young: bool) -> void:
	var p := _where(c)
	var tad := young and float(c.get("dev")) < 1.0
	match act:
		"eat", "hunt":
			if not tad:
				var a := randf() * TAU
				var at := p + Vector3(cos(a), 0.0, sin(a)) * 0.12
				at.y = 0.0 if absf(at.x - _station(35).x) > FROG_PW or absf(at.z) > FROG_PD else POND
				var fl := FrogScript.fly_of(at)
				add_child(fl)
				c.call("hunt", fl)
		"lay":
			if not tad and not _flag(c, "male"):
				c.call("lay")
		"fly":
			if tad:
				c.call("metamorphose")
			else:
				var a := randf() * TAU
				c.call("hop", p + Vector3(cos(a), 0.0, sin(a)) * 0.2)
		"display":
			if _flag(c, "male") and not young:
				c.call("croak")
		"alarm":
			if not tad:
				c.call("flee", p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)) * 0.1)
		"forage":
			if not tad:
				c.call("swim", _station(35) + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.2, 0.2)))
		"wander":
			if not tad:
				c.call("wander", p, 0.2)


## The painted turtles: a pond (30 cm deep) with a log in it to bask on, a
## sandy bank beside it to nest in, a female and a male, a hatchling.
func _turtle_station() -> void:
	var c := _station(36)
	_pond(c, TURTLE_PW, TURTLE_PD, TURTLE_DEEP)
	var log := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.07
	cm.height = 0.9
	log.mesh = cm
	log.material_override = _plain(Color(0.36, 0.3, 0.22))
	log.position = c + Vector3(0.1, POND - 0.01, -0.1)
	log.rotation = Vector3(0.0, 0.4, PI * 0.5)
	add_child(log)
	var basks := [log.position + Vector3(-0.15, 0.065, -0.07), log.position + Vector3(0.18, 0.065, 0.08)]
	var bank := c + Vector3(-TURTLE_PW - 0.35, 0.0, 0.1)
	_box(bank + Vector3(0.0, 0.0008, 0.0), Vector3(0.5, 0.002, 0.5), Color(0.62, 0.52, 0.36)) # (the sandy bank)
	var land := func(_x: float, _z: float) -> float: return 0.0
	for m in 3:
		var t: Node3D = TurtleScript.new(m == 2)
		if m == 1:
			t.set("male", true)
		t.set("water_y", POND)
		t.set("floor_y", -TURTLE_DEEP + 0.01)
		t.set("pond", [c, Vector2(TURTLE_PW, TURTLE_PD)])
		t.set("height", land)
		t.set("bank", bank)
		t.set("basks", basks)
		add_child(t)
		var at := c + Vector3(-0.25 + 0.35 * m, 0.0, 0.15)
		t.call("place", at, randf() * TAU)
		t.call("wander", c, 0.45)


## (A turtle: what each key has it do.)
func _turtle_do(c: Node, act: String, young: bool) -> void:
	var p := _where(c)
	match act:
		"eat", "hunt":
			var a := randf() * TAU
			var at := p + Vector3(cos(a), 0.0, sin(a)) * 0.2
			at.y = POND
			var f: Node3D = TurtleScript.weed_of(at) if act == "eat" else FrogScript.fly_of(at)
			add_child(f)
			c.call("eat", f)
		"lay":
			if not young and not _flag(c, "male"):
				c.call("nest")
		"sleep", "sit":
			c.call("bask")
		"fly":
			c.call("dive")
		"alarm":
			c.call("withdraw")
		"wander", "forage":
			c.call("wander", _station(36), 0.45)


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
				var mollies := MolliesScript.new() # (a little school of sailfin mollies in it)
				mollies.tank_min = c + Vector3(-POND_W + 0.03, POND - 0.29, -POND_D + 0.03)
				mollies.tank_max = c + Vector3(POND_W - 0.03, POND - 0.02, POND_D - 0.03)
				add_child(mollies)
				mollies.setup(14, c + Vector3(0.0, POND - 0.12, 0.0), 0.08)
				_pond_mollies = mollies
				sp.place(c + Vector3(0.0, POND, 0.0), 0.5)
				sp.shore = c + Vector3(POND_W * 0.8, POND, 0.1) # (where it takes a fish to eat)
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
## The ponds sunk in the plain: [centre, half width (x), half depth (z), deep] each, by x.
func _ponds() -> Array:
	return [[_station(12), POND_W, POND_D, 0.3], [_station(34), MOOSE_PW, MOOSE_PD, MOOSE_DEEP], [_station(35), FROG_PW, FROG_PD, FROG_DEEP], [_station(36), TURTLE_PW, TURTLE_PD, TURTLE_DEEP]]


func _pond(c: Vector3, pw := POND_W, pd := POND_D, deep := 0.3) -> void:
	var mud := Color(0.16, 0.13, 0.09)
	_box(c + Vector3(0.0, -deep, 0.0), Vector3(pw * 2.0, 0.02, pd * 2.0), mud)
	for sgn: float in [-1.0, 1.0]:
		_box(c + Vector3(sgn * pw, -deep * 0.5, 0.0), Vector3(0.01, deep, pd * 2.0), mud)
		_box(c + Vector3(0.0, -deep * 0.5, sgn * pd), Vector3(pw * 2.0, deep, 0.01), mud)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ocean.gdshader")
	# its depth (the shader's map: the floor deep down everywhere round here)
	var img := Image.create(4, 4, false, Image.FORMAT_RF)
	img.fill(Color(POND - deep, 0.0, 0.0, 1.0))
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
	var cell := maxf(0.01, pw * 2.0 / 100.0) # (1 cm cells, or coarser for a big pond)
	var nx := int(pw * 2.0 / cell)
	var nz := int(pd * 2.0 / cell)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var q := [Vector2(ix, iz), Vector2(ix + 1, iz), Vector2(ix + 1, iz + 1), Vector2(ix, iz + 1)]
			for e in [0, 2, 1, 0, 3, 2]:
				var g: Vector2 = q[e]
				st.set_uv(Vector2(cell, 0.0))
				st.add_vertex(Vector3(-pw + g.x * cell, 0.0, -pd + g.y * cell))
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


## The anoles: a female and a male, a little leaf litter.
func _anole_station() -> void:
	var c := _station(17)
	for k in 6:
		var leaf := Beetles.leaf()
		leaf.position = c + Vector3(randf_range(-0.15, 0.15), 0.0002 * k, randf_range(-0.15, 0.15))
		leaf.rotation.y = randf() * TAU
		leaf.scale = Vector3(0.6, 1.0, 0.6)
		(leaf.get_child(0) as MeshInstance3D).material_override = _plain(Color(0.4, 0.3, 0.16).lerp(Color(0.3, 0.24, 0.12), randf()))
		add_child(leaf)
	anole_f = AnoleScript.new()
	add_child(anole_f)
	anole_f.place(c, 0.5)
	anole_f.wander(c, 0.2)
	anole_m = AnoleScript.new()
	anole_m.male = true
	add_child(anole_m)
	anole_m.place(c + Vector3(-0.15, 0.0, 0.12), 2.2)
	anole_m.wander(c, 0.25)


## The scorpions, on sand: a female and a male.
func _scorpion_station() -> void:
	var c := _station(18)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(0.8, 0.002, 0.8), Color(0.72, 0.62, 0.46))
	scorp_f = ScorpionScript.new()
	add_child(scorp_f)
	scorp_f.place(c, 0.3)
	scorp_f.wander(c, 0.15)
	scorp_m = ScorpionScript.new()
	scorp_m.male = true
	add_child(scorp_m)
	scorp_m.place(c + Vector3(-0.12, 0.0, 0.15), 2.0)
	scorp_m.wander(c, 0.18)


## The hares: a female and a male, in their summer coats; clover about, a
## willow shoot.
func _hare_station() -> void:
	var c := _station(19)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(2.4, 0.002, 2.0), Color(0.34, 0.42, 0.2))
	for k in 5:
		_new_clover()
	var tw := HareScript.twig()
	tw.position = c + Vector3(0.5, 0.0, -0.5)
	add_child(tw)
	_hare_food.append(tw)
	hare_f = HareScript.new()
	add_child(hare_f)
	hare_f.place(c, 0.6)
	hare_f.wander(c, 0.6)
	hare_m = HareScript.new()
	hare_m.male = true
	add_child(hare_m)
	hare_m.place(c + Vector3(-0.5, 0.0, 0.4), 2.0)
	hare_m.wander(c, 0.7)


func _new_clover() -> Node3D:
	var c := _station(19)
	var cl := HareScript.clover()
	cl.position = c + Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.8, 0.8))
	add_child(cl)
	_hare_food.append(cl)
	return cl


## The nearest of the hares' food to p (the willow shoot, if high; clover
## else, a new clump if there's none left).
func _hare_food_near(p: Vector3, high: bool) -> Node3D:
	var best: Node3D = null
	for f in _hare_food:
		if not is_instance_valid(f) or f.has_meta("high") != high or f.has_meta("taken"):
			continue
		if best == null or (f as Node3D).position.distance_to(p) < best.position.distance_to(p):
			best = f
	if best == null:
		best = _new_clover()
	if not high:
		best.set_meta("taken", true)
	return best


## The red foxes: a vixen and a dog fox, her den, deer mice about.
func _fox_station() -> void:
	var c := _station(20)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(3.6, 0.002, 2.6), Color(0.38, 0.44, 0.22))
	_fox_den = CanidScript.den()
	_fox_den.position = c + Vector3(0.9, 0.0, -0.8)
	add_child(_fox_den)
	fox_f = FoxScript.new()
	add_child(fox_f)
	fox_f.call("place", c, 0.5)
	fox_f.set("home_den", _fox_den)
	fox_f.call("wander", c, 1.0)
	fox_m = FoxScript.new()
	fox_m.set("male", true)
	add_child(fox_m)
	fox_m.call("place", c + Vector3(-0.8, 0.0, 0.5), 2.0)
	fox_m.call("wander", c, 1.2)
	for k in 3:
		_fox_mouse()


## A deer mouse at the fox's station (a new one, if they're all gone).
func _fox_mouse() -> Node3D:
	for m in _fox_mice:
		if is_instance_valid(m) and not _flag(m, "dead"):
			if not m.has_meta("hunted"):
				m.set_meta("hunted", true)
				return m
	var c := _station(20)
	var mo := MouseScript.new()
	add_child(mo)
	var a := randf() * TAU
	var at := c + Vector3(cos(a), 0.0, sin(a)) * randf_range(0.6, 1.2)
	mo.place(at, randf() * TAU)
	mo.wander(at, 0.3)
	_fox_mice.append(mo)
	return mo


## The bobcats: a female and a male, her rock den; a hare to hunt.
func _bobcat_station() -> void:
	var c := _station(21)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(3.6, 0.002, 2.6), Color(0.4, 0.4, 0.26))
	_cat_den = BobcatScript.den()
	_cat_den.position = c + Vector3(-0.9, 0.0, -0.9)
	add_child(_cat_den)
	cat_f = BobcatScript.new()
	add_child(cat_f)
	cat_f.call("place", c, 0.3)
	cat_f.set("home_den", _cat_den)
	cat_f.call("wander", c, 1.0)
	cat_m = BobcatScript.new()
	cat_m.set("male", true)
	add_child(cat_m)
	cat_m.call("place", c + Vector3(0.8, 0.0, 0.5), 2.4)
	cat_m.call("wander", c, 1.2)
	_new_cat_hare()


func _new_cat_hare() -> Node3D:
	if is_instance_valid(_cat_hare) and not _flag(_cat_hare, "dead"):
		return _cat_hare
	var c := _station(21)
	var h := HareScript.new()
	add_child(h)
	h.place(c + Vector3(1.2, 0.0, 0.8), randf() * TAU)
	h.wander(c + Vector3(1.2, 0.0, 0.8), 0.4)
	_cat_hare = h
	return h


## The coyotes: a female and a male, her den; mice and a hare about.
func _coyote_station() -> void:
	var c := _station(22)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(4.4, 0.002, 3.2), Color(0.5, 0.46, 0.28))
	_coy_den = CanidScript.den(1.3)
	_coy_den.position = c + Vector3(1.2, 0.0, -1.0)
	add_child(_coy_den)
	var pair := _canid_pair(CoyoteScript, c, _coy_den)
	coy_f = pair[0]
	coy_m = pair[1]
	_station_mouse(22)
	_station_hare(22)


## The grey wolves: a female and a male, her den dug in a bank; a hare.
func _wolf_station() -> void:
	var c := _station(23)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(5.0, 0.002, 3.6), Color(0.36, 0.42, 0.24))
	_wolf_den = CanidScript.den(1.7)
	_wolf_den.position = c + Vector3(-1.4, 0.0, -1.2)
	add_child(_wolf_den)
	var pair := _canid_pair(WolfScript, c, _wolf_den)
	wolf_f = pair[0]
	wolf_m = pair[1]
	_station_hare(23)


func _canid_pair(sc: Script, c: Vector3, den: Node3D) -> Array:
	var f: Node3D = sc.new()
	add_child(f)
	f.call("place", c, 0.4)
	f.set("home_den", den)
	f.call("wander", c, 1.3)
	var m: Node3D = sc.new()
	m.set("male", true)
	add_child(m)
	m.call("place", c + Vector3(-1.0, 0.0, 0.7), 2.2)
	m.call("wander", c, 1.5)
	return [f, m]


## A deer mouse at station i, for a hunter there.
func _station_mouse(i: int) -> Node3D:
	var c := _station(i)
	var mo := MouseScript.new()
	add_child(mo)
	var a := randf() * TAU
	var at := c + Vector3(cos(a), 0.0, sin(a)) * randf_range(0.8, 1.4)
	mo.place(at, randf() * TAU)
	mo.wander(at, 0.3)
	return mo


## The hare at station i (a new one if it's been taken).
func _station_hare(i: int) -> Node3D:
	var h: Node3D = _hares.get(i)
	if is_instance_valid(h) and not _flag(h, "dead"):
		return h
	var c := _station(i)
	var hr := HareScript.new()
	add_child(hr)
	var at := c + Vector3(1.6, 0.0, 1.0)
	hr.place(at, randf() * TAU)
	hr.wander(at, 0.5)
	_hares[i] = hr
	return hr


## The bears (kind 0 black, 1 brown): a female, a male and another (each
## its colour phase), her den, berry bushes, a tree to rub on.
func _bear_station(kind: int) -> void:
	var c := _station(24 + kind)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(7.0, 0.002, 5.0), Color(0.3, 0.38, 0.2))
	var den := UrsidScript.den(1.0 + 0.3 * kind)
	den.position = c + Vector3(-2.2, 0.0, -1.6)
	add_child(den)
	_bear_dens.append(den)
	var bushes := []
	for k in 3:
		var b := UrsidScript.berry_bush()
		b.position = c + Vector3(1.0 + 0.9 * k, 0.0, -1.5 + 0.4 * k)
		add_child(b)
		bushes.append(b)
	_bushes.append(bushes)
	var tree := _box(c + Vector3(2.4, 2.0, 1.4), Vector3(0.35, 4.0, 0.35), Color(0.35, 0.27, 0.18))
	_rub_trees.append(tree.position * Vector3(1.0, 0.0, 1.0))
	var sc: Script = BlackBearScript if kind == 0 else BrownBearScript
	var phases := ["black", "cinnamon", "brown"] if kind == 0 else ["brown", "grizzled", "blond"]
	var trio := []
	for j in 3:
		var b: Node3D = sc.new(false, phases[j])
		if j == 1:
			b.set("male", true)
		add_child(b)
		b.call("place", c + Vector3(-1.2 + 1.3 * j, 0.0, 0.8 - 0.6 * j), randf() * TAU)
		if j == 0:
			b.set("home_den", den)
		b.call("forage", c, 2.5)
		trio.append(b)
	bears.append(trio)


## The bison: two bulls (to spar), two cows, one with her calf at her side,
## on open grass, a bare patch of dust to wallow in.
func _bison_station() -> void:
	var c := _station(26)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(9.0, 0.002, 5.0), Color(0.42, 0.44, 0.24))
	_box(c + Vector3(2.6, 0.0008, -1.4), Vector3(1.8, 0.002, 1.4), Color(0.55, 0.47, 0.34)) # (the wallow)
	var spots := [Vector3(-2.5, 0.0, 1.0), Vector3(2.6, 0.0, 1.2), Vector3(-0.6, 0.0, -1.0), Vector3(0.9, 0.0, 0.4)]
	for j in 4:
		var b: Node3D = BisonScript.new()
		if j < 2:
			b.set("male", true)
		add_child(b)
		b.call("place", c + spots[j], randf() * TAU)
		b.call("graze", c + spots[j], 2.0)
		if j == 3: # (her calf)
			var y: Node3D = BisonScript.new(true)
			add_child(y)
			y.call("place", c + spots[j] + Vector3(0.9, 0.0, 0.5), randf() * TAU)
			y.set("_mother", b)
			y.set("_mode", "follow")
			var ones: Array[Node3D] = b.get("young_ones")
			ones.append(y)


## The comb's cells with nothing in them yet (no egg, no grub), the middle
## first: its wasp lays in the first of them.
func _empty_cells() -> Array:
	var out := []
	for cell: Vector3 in _cells:
		var full := false
		for n in get_children():
			if not (n is Node3D) or n.get_script() == null or n.get_script() == Wasp: # (its brood only: no comb, no wasp)
				continue
			var q := (n as Node3D).global_position
			var p: Variant = n.get("_pos")
			if p is Vector3:
				q = p
			if Vector2(q.x - cell.x, q.z - cell.z).length() < 0.0035 and q.y < cell.y + 0.002 and q.y > cell.y - 0.02:
				full = true
				break
		if not full:
			out.append(cell)
	return out


## The fox squirrels (or the grey: station 31): a female and a male, their
## tree (her drey up in it), nuts under it.
func _squirrel_station(at := 29, sc: Script = SquirrelScript) -> void:
	var c := _station(at)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(3.0, 0.002, 2.4), Color(0.36, 0.38, 0.2))
	var made: Array = SquirrelScript.tree(0.12, 4.5)
	var tree: Node3D = made[0]
	tree.position = c + Vector3(0.6, 0.0, -0.6)
	add_child(tree)
	_sq_tree = tree.position
	var drey: Vector3 = tree.position + (made[1] as Vector3)
	for k in 6:
		_sq_nut(c + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.8, 0.8)))
	for m in 2:
		var q: Node3D = sc.new()
		q.set("male", m == 1)
		add_child(q)
		q.set("tree_at", tree.position)
		q.set("tree_r", 0.12)
		if m == 0:
			q.set("drey", drey)
		q.call("place", c + Vector3(-0.4 + 0.8 * m, 0.0, 0.3), randf() * TAU)
		q.call("wander", c, 0.8)


func _sq_nut(at: Vector3) -> Node3D:
	var n: Node3D = SquirrelScript.nut()
	n.position = Vector3(at.x, 0.0, at.z)
	add_child(n)
	_sq_nuts.append(n)
	return n


## A nut for a squirrel at p: the nearest on the ground (or a new one by it).
func _sq_nut_near(p: Vector3) -> Node3D:
	var best: Node3D = null
	for n in _sq_nuts:
		if is_instance_valid(n) and (n as Node3D).visible and (best == null or (n as Node3D).position.distance_to(p) < best.position.distance_to(p)):
			best = n
	if best == null or best.position.distance_to(p) > 1.2:
		var a := randf() * TAU
		best = _sq_nut(p + Vector3(cos(a), 0.0, sin(a)) * 0.4)
	return best


## The beavers: a female and a male, a raised bank (aspen saplings on it,
## a stick or two) and beside it a pond 30 cm deep, their lodge out in it.
const BV_BANK_Y := 0.32
const BV_WATER_Y := 0.28
func _beaver_station() -> void:
	var c := _station(30)
	_bv_bank = c.x - 0.3
	_box(Vector3(c.x - 1.5, BV_BANK_Y * 0.5, c.z), Vector3(2.4, BV_BANK_Y, 4.0), Color(0.34, 0.33, 0.2)) # (the bank)
	_box(Vector3(c.x + 1.2, 0.002, c.z), Vector3(3.0, 0.004, 4.0), Color(0.2, 0.17, 0.12)) # (the pond's mud floor)
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.0, 4.0)
	w.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.16, 0.26, 0.24, 0.72)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.08
	wm.metallic_specular = 0.8
	w.material_override = wm
	w.position = Vector3(c.x + 1.2, BV_WATER_Y, c.z)
	add_child(w)
	var lodge: Node3D = BeaverScript.lodge_of()
	lodge.position = Vector3(c.x + 1.6, 0.0, c.z - 0.9)
	lodge.scale = Vector3.ONE * 0.8
	add_child(lodge)
	for k in 3:
		var sp: Node3D = BeaverScript.sapling()
		sp.position = Vector3(c.x - 1.0 - 0.6 * k, BV_BANK_Y, c.z - 1.2 + 1.1 * k)
		add_child(sp)
		_bv_saplings.append(sp)
	for k in 2:
		_bv_stick(Vector3(c.x - 1.4 + 0.5 * k, 0.0, c.z + 1.0 - 0.3 * k))
	var bank := _bv_bank
	var wet := func(x: float, z: float) -> bool: return x > bank + 0.05 and x < c.x + 2.7 and absf(z - c.z) < 1.95
	var ground := func(x: float, z: float) -> float: return BV_BANK_Y if x <= bank and absf(z - c.z) < 2.0 and x > c.x - 2.7 else 0.0
	for m in 2:
		var b: Node3D = BeaverScript.new()
		b.set("male", m == 1)
		b.set("wet", wet)
		b.set("water_y", BV_WATER_Y)
		b.set("height", ground)
		b.set("lodge", lodge)
		add_child(b)
		if m == 0:
			b.call("place", Vector3(c.x - 1.3, BV_BANK_Y, c.z + 0.3), 1.2)
			b.call("wander", Vector3(c.x - 1.4, BV_BANK_Y, c.z), 0.7)
		else:
			b.call("place", Vector3(c.x + 0.9, 0.0, c.z + 0.6), -1.0)
			b.call("swim", Vector3(c.x + 1.0, 0.0, c.z + 0.4), 1.0)


func _bv_stick(at: Vector3) -> Node3D:
	var st: Node3D = BeaverScript.stick_of()
	st.position = Vector3(at.x, BV_BANK_Y + 0.015, at.z)
	st.rotation.y = randf() * TAU
	add_child(st)
	_bv_sticks.append(st)
	return st


## The trigonalid wasp: a female and a male, about a clump of fleabane (its
## nectar), and leaves on stalks about it (hers to lay along).
func _trig_station() -> void:
	var c := _station(28)
	var info: Dictionary = Flowers.build(self, "fleabane", Vector2(c.x - 0.12, c.z - 0.15), 0.5, Color(0.42, 0.38, 0.28), 0.0)
	_trig_heads = info.heads
	_leaves(c, [Vector3(0.15, 0.14, 0.05), Vector3(0.05, 0.2, 0.18), Vector3(-0.12, 0.1, 0.16), Vector3(0.2, 0.22, -0.12)], _trig_leaves)
	var f: Node3D = TrigScript.new()
	add_child(f)
	f.call("place", c + Vector3(0.0, 0.35, 0.1))
	f.call("visit_flowers", _trig_heads, 0.0)
	var m: Node3D = TrigScript.new()
	m.set("male", true)
	add_child(m)
	m.call("place", c + Vector3(0.1, 0.3, -0.1))
	m.call("seek_food", c, 0.35)


## Points along a demo leaf's margin (its top at top: Beetles.leaf, as
## _leaves sets it, 35 by 60 mm), one side, end to end.
func _leaf_edge(top: Vector3) -> Array:
	var out := []
	for k in 6:
		var z := lerpf(-0.022, 0.022, k / 5.0)
		var x := 0.0175 * sqrt(maxf(1.0 - pow(z / 0.02975, 2.0), 0.0)) * 0.92
		out.append(top + Vector3(x, 0.0, z))
	return out


## The deer: in summer, a doe with her twin fawns (spotted) and a buck in
## velvet; in winter coats, two bucks (hard antlers, to spar) and a doe; a
## shrub to browse, a sapling to rub.
func _deer_station() -> void:
	var c := _station(27)
	_box(c + Vector3(0.0, 0.0006, 0.0), Vector3(7.0, 0.002, 4.6), Color(0.38, 0.44, 0.22))
	var shrub := UrsidScript.berry_bush()
	shrub.position = c + Vector3(-1.6, 0.0, -1.5)
	add_child(shrub)
	_deer_shrub = shrub.position
	_deer_sapling = c + Vector3(2.3, 0.0, -1.6)
	_box(_deer_sapling + Vector3(0.0, 0.8, 0.0), Vector3(0.05, 1.6, 0.05), Color(0.36, 0.28, 0.2))
	var herd := [[false, "summer", Vector3(-1.8, 0.0, 0.8)], [true, "summer", Vector3(0.6, 0.0, 1.4)],
			[true, "winter", Vector3(-0.4, 0.0, -0.8)], [true, "winter", Vector3(2.4, 0.0, -0.2)], [false, "winter", Vector3(1.2, 0.0, 0.3)]]
	for h: Array in herd:
		var d: Node3D = DeerScript.new(false, h[1])
		d.set("male", h[0])
		add_child(d)
		var at: Vector3 = c + (h[2] as Vector3)
		d.call("place", at, randf() * TAU)
		d.call("graze", at, 1.5)
		if not h[0] and h[1] == "summer": # (her twins)
			var ones: Array[Node3D] = d.get("young_ones")
			for k in 2:
				var y: Node3D = DeerScript.new(true, "summer")
				add_child(y)
				y.call("place", at + Vector3(0.6 + 0.5 * k, 0.0, 0.5 - 0.9 * k), randf() * TAU)
				y.set("_mother", d)
				y.set("_mode", "follow")
				ones.append(y)


## The fishing spider's catch: a molly of the pond's school, come up near
## the surface by the spider; then its rush and its lunge.
func _spider_fish() -> void:
	var sp: Node3D = spiders[1]
	if not is_instance_valid(_pond_mollies):
		return
	var i: int = _pond_mollies.call("nearest", sp.get("_pos"))
	if i < 0:
		return
	var fish: Node3D = _pond_mollies.call("take", i)
	var a := randf() * TAU
	var at: Vector3 = (sp.get("_pos") as Vector3) + Vector3(cos(a), 0.0, sin(a)) * 0.14
	at.y = POND - 0.008
	var tw := create_tween()
	tw.tween_property(fish, "position", at, 2.0)
	tw.tween_callback(Callable(sp, "hunt").bind(fish))


## The anoles and the scorpions hunt: a fly on the ground before each
## anole, a cricket before each scorpion (the young: small ones).
func _lizards_hunt(young_only := false) -> void:
	for c in get_children():
		var sc: Script = c.get_script()
		if sc != AnoleScript and sc != ScorpionScript:
			continue
		var young := _flag(c, "young")
		if young_only != young or _flag(c, "dead") or c.get("_mother") != null:
			continue
		var p: Vector3 = c.get("_pos")
		var a := randf() * TAU
		var f: Node3D
		if sc == AnoleScript:
			f = MantisScript.fly_prey()
			f.scale = Vector3.ONE * (0.5 if not young else 0.25) # (life size)
			f.position = p + Vector3(cos(a), 0.0, sin(a)) * (0.12 if not young else 0.05)
		else:
			f = ScorpionScript.cricket()
			f.scale = Vector3.ONE * (1.0 if not young else 0.3)
			f.position = p + Vector3(cos(a), 0.0, sin(a)) * (0.1 if not young else 0.04)
		add_child(f)
		c.call("hunt", f)


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
	mo.search(_station(1), 0.4, _moth_flowers)
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
	pairs.append([anole_m, anole_f])
	pairs.append([scorp_m, scorp_f])
	pairs.append([hare_m, hare_f])
	pairs.append([fox_m, fox_f])
	pairs.append([cat_m, cat_f])
	pairs.append([coy_m, coy_f])
	pairs.append([wolf_m, wolf_f])
	for b: Array in bears:
		pairs.append([b[1], b[0]])
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
		elif (sc == HopperScript or sc == BlueHopperScript) and c.get("nymph"):
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
		elif sc == HareScript and c.get("young"):
			c.call("eat", _hare_food_near((c as Node3D).get("_pos"), false))
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
	moth.lay(_moth_leaves.map(func(l): return l[0]), _moth_leaves.map(func(l): return l[1]), func() -> void: moth.search(c1, 0.4, _moth_flowers))
	wasp.lay_eggs(_empty_cells().slice(0, 1), Vector3.UP, 0.0068)
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
	anole_f.lay(_station(17) + Vector3(0.08, 0.0, -0.06))
	scorp_f.birth(12)
	hare_f.birth(4)
	fox_f.call("birth", 4, _fox_den)
	cat_f.call("birth", 3, _cat_den)
	coy_f.call("birth", 5, _coy_den)
	wolf_f.call("birth", 5, _wolf_den)
	for k in bears.size():
		bears[k][0].call("birth", 2 + k, _bear_dens[k])


func _hatch_eggs() -> void:
	var all: Array = []
	for list: Array in [_ant_eggs, monarch.eggs, moth.eggs, wasp.eggs, june.eggs, lady.eggs, milk.eggs, anole_f.eggs]:
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
				a.call("search", c, 0.4, _moth_flowers if k == 1 else []))


## The keys: one for each thing they all do, for those at the station in
## view only (Tab: the next).
const KEYS := {
	KEY_1: "lay", KEY_2: "hatch", KEY_3: "pupae", KEY_E: "eat", KEY_H: "hunt", KEY_K: "mate",
	KEY_G: "groom", KEY_Z: "sleep", KEY_F: "fly", KEY_X: "alarm", KEY_D: "display", KEY_V: "play",
	KEY_N: "nurse", KEY_B: "forage", KEY_S: "spin", KEY_M: "mark", KEY_A: "sit", KEY_W: "wander",
}


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if KEYS.has(e.keycode):
			_act_here(KEYS[e.keycode])
			return
		match e.keycode:
			KEY_P:
				_pilot_demo()
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
			_dist = minf(_dist / 0.85, 40.0)


## Whether n's young: a larva (the butterflies', the moth's, the wasp's,
## the ants', the beetles' young: Larva), a pupa, a nymph (the grasshopper's,
## the mantis's), or a young one of the rest (a spiderling, a leveret, a
## cub: young).
func _young(n: Object) -> bool:
	var sc: Variant = n.get_script() if n != null else null
	return sc == LarvaScript or sc == PupaScript or _flag(n, "young") or _flag(n, "nymph")


## Whether n's flag (a property) is set: false if it hasn't that one (each
## kind keeps its young its own way: a Larva is one, a nymph flags itself
## nymph, the others young).
func _flag(n: Object, name: String) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	var v: Variant = n.get(name)
	return v is bool and v


## Where a creature (or a colony, an egg) is: its own place, its parent's space.
func _where(n: Node) -> Vector3:
	if n is MultiMeshInstance3D:
		var mm := n as MultiMeshInstance3D
		return mm.global_transform * mm.custom_aabb.get_center()
	var p: Variant = n.get("_pos")
	if p is Vector3:
		return p
	return (n as Node3D).global_position if n is Node3D else Vector3.INF


## Which station a point's at (the nearest).
func _station_of(p: Vector3) -> int:
	var best := 0
	var bd := INF
	for i in NAMES.size():
		var d := absf(_station(i).x - p.x)
		if d < bd:
			bd = d
			best = i
	return best


## Everything at the station in view (the creatures, their colonies, their
## eggs and pupae).
func _here() -> Array:
	var out := []
	for c in get_children():
		if c.get_script() == null or not (c is Node3D):
			continue
		var p := _where(c)
		if p != Vector3.INF and _station_of(p) == _at:
			out.append(c)
	return out


## The thing done, by everything at the station in view that does it.
func _act_here(act: String) -> void:
	var all := _here()
	match act:
		"pupae":
			if _at <= 1:
				_new_pupae()
			return
		"lay":
			if _at == 3 or _at == 4: # (the queens' eggs: a new pile)
				_ant_pile(_at - 3)
		"alarm":
			if _at == 12 and is_instance_valid(_pond_mollies):
				_pond_mollies.call("scatter", _station(12) + Vector3(0.0, POND, 0.0))
	for c in all:
		_do(c, act, all)


## A partner for c (its kind, the other sex, grown, at the station).
func _partner(c: Node, all: Array) -> Node:
	for o in all:
		if o != c and o.get_script() == c.get_script() and _flag(o, "male") != _flag(c, "male") and not _young(o) and not _flag(o, "dead"):
			return o
	return null


func _do(c: Node, act: String, all: Array) -> void:
	var sc: Script = c.get_script()
	var p := _where(c)
	var young := _young(c)
	var st := _station(_at)
	# hatching: an egg, a pod, an egg case, a sac, a pupa
	if act == "hatch":
		if sc == PupaScript:
			var k := _at
			c.call("eclose", func(a: Node3D) -> void:
				if a.has_method("fly"):
					a.call("fly", _station(k), 0.4)
				else:
					a.call("search", _station(k), 0.4, _moth_flowers if k == 1 else []))
		elif c.has_method("hatch") and not (c is AntColony):
			c.call("hatch")
		elif sc == SpiderScript: # (its sacs, carried or left)
			for sac in c.get("sacs"):
				if is_instance_valid(sac):
					sac.call("hatch")
		elif (sc == HopperScript or sc == BlueHopperScript) or sc == MantisScript: # (its pods, its egg cases)
			for pod in c.get("pods" if (sc == HopperScript or sc == BlueHopperScript) else "oothecae"):
				if is_instance_valid(pod):
					pod.call("hatch")
		return
	if act == "mate":
		if c is Beetles:
			c.call("mate", 1, 0)
		elif _flag(c, "male") and not young and c.has_method("mate"):
			var q := _partner(c, all)
			if q:
				c.call("mate", q)
		return
	# the colonies
	if sc == DragonflyScript:
		_dragonfly_do(c, act, young)
		return
	if sc == FrogScript:
		_frog_do(c, act, young)
		return
	if sc == TurtleScript:
		_turtle_do(c, act, young)
		return
	if c is Beetles or c is AntColony:
		var col := c as AntColony
		var n := col.pos.size()
		for i in n:
			match act:
				"eat":
					col.feed(i, Vector3(0.02 * i, 0.0, 0.03))
				"lay":
					if col.lays:
						col.lay(i, Vector3(-0.03, 0.0, 0.01 * i))
				"fly":
					if c is Beetles:
						(c as Beetles).fly(i, Vector3.ZERO, 0.3, 0.25)
				"wander":
					col.wander(i, Vector3.ZERO, 0.06)
		return
	if sc == MolliesScript:
		if act == "eat":
			for i in (c.get("pos") as PackedVector3Array).size():
				c.call("graze", i)
		elif act == "display":
			for i in (c.get("pos") as PackedVector3Array).size():
				c.call("display", i)
		elif act == "wander":
			for i in (c.get("pos") as PackedVector3Array).size():
				c.call("rejoin", i)
		return
	match act:
		"wander":
			if sc == MonarchScript:
				c.call("fly", st, 0.4)
			elif sc == MothScript:
				c.call("search", st, 0.4, _moth_flowers)
			elif sc == Wasp or sc == TrigScript:
				c.call("seek_food", st, 0.5 if sc == Wasp else 0.35)
			elif sc == MantisScript:
				c.call("stalk", p, 0.15)
			elif sc == BeaverScript:
				if young:
					c.set("_mode", "follow")
				elif c.get("_in_water"):
					c.call("swim", p, 1.0)
				else:
					c.call("wander", Vector3(_bv_bank - 1.1, BV_BANK_Y, st.z), 0.7)
			elif sc == BisonScript or sc == DeerScript or sc == MooseScript:
				if young:
					c.set("_mode", "follow")
				else:
					c.call("graze", p, 3.0 if sc == BisonScript else 2.0)
			elif sc == SpiderScript and c.get("kind") in ["funnel", "argiope"] and not young:
				pass # (at its web)
			elif c.has_method("wander"):
				c.call("wander", st if not c.has_method("forage") else st, 0.25 if not (c.has_method("forage") or sc == SnakeScript) else 1.2)
		"lay":
			if young or _flag(c, "male"):
				return
			if sc == MonarchScript:
				c.call("lay", _monarch_leaves.map(func(l): return l[0]), _monarch_leaves.map(func(l): return l[1]), Callable(c, "fly").bind(st, 0.4))
			elif sc == MothScript:
				c.call("lay", _moth_leaves.map(func(l): return l[0]), _moth_leaves.map(func(l): return l[1]), Callable(c, "search").bind(st, 0.4, _moth_flowers))
			elif sc == Wasp:
				c.call("lay_eggs", _empty_cells().slice(0, 1), Vector3.UP, 0.0068) # (one cell a lay: the next empty one)
			elif sc == TrigScript:
				var lf: Array = _trig_leaves[randi() % _trig_leaves.size()]
				c.call("lay_on_leaf", _leaf_edge(lf[0]), Vector3.UP)
			elif (sc == HopperScript or sc == BlueHopperScript):
				c.call("lay", st + Vector3(0.05, 0.0, -0.08))
			elif sc == MantisScript:
				c.call("lay", _stem_foot + Vector3(0.0, 0.006, 0.0))
			elif sc == SnakeScript:
				c.call("lay", 5 if c.get("kind") == "rattler" else 6)
			elif sc == SpiderScript or sc == IsopodScript:
				c.call("lay")
			elif sc == AnoleScript:
				c.call("lay", st + Vector3(0.08, 0.0, -0.06))
			elif sc == MouseScript:
				c.call("birth", 4, _nest)
			elif sc == ScorpionScript:
				c.call("birth", 12)
			elif sc == DeerScript or sc == MooseScript:
				c.call("birth", 2 if sc == DeerScript else 1)
			elif sc == HareScript:
				c.call("birth", 4)
			elif (sc == SquirrelScript or sc == GreySqScript):
				c.call("birth", 3) # (up in her drey)
			elif sc == BeaverScript:
				c.call("birth", 3)
			elif c.has_method("birth"): # (the hunters: in their dens)
				c.call("birth", 4, c.get("home_den"))
		"eat", "hunt":
			_feed(c, act, young, p, st)
		"groom":
			if c.has_method("groom"):
				c.call("groom")
			elif sc == Wasp:
				c.call("land", st + Vector3(0.1, 0.0, 0.08))
			elif sc == TrigScript: # (down on a leaf, cleaning its antennae)
				var lf: Array = _trig_leaves[randi() % _trig_leaves.size()]
				c.call("land", lf[0], Vector3.UP)
		"sleep":
			if c.has_method("sleep"):
				c.call("sleep", 20.0)
			elif sc == HareScript or (sc == SquirrelScript or sc == GreySqScript):
				c.call("freeze", 12.0) # (still in its form)
			elif sc == SnakeScript:
				c.call("coil")
			elif sc == IsopodScript:
				c.call("roll", 8.0)
		"fly":
			if sc == MonarchScript:
				c.call("fly", st, 0.6)
			elif sc == MothScript:
				c.call("search", st, 0.5, _moth_flowers)
			elif sc == Wasp or sc == TrigScript:
				c.call("seek_food", st, 0.6 if sc == Wasp else 0.4)
			elif (sc == SquirrelScript or sc == GreySqScript) and not young: # (F: up its tree)
				c.call("climb", c.get("tree_at"), randf_range(1.8, 3.0))
			elif (sc == HopperScript or sc == BlueHopperScript):
				var a := randf() * TAU
				c.call("hop" if young else "fly", st + Vector3(cos(a), 0.0, sin(a)) * (0.2 if young else 0.35))
			elif sc == MantisScript and not young:
				var a := randf() * TAU
				c.call("fly", st + Vector3(cos(a), 0.0, sin(a)) * 0.3)
		"alarm":
			if sc == SnakeScript:
				c.call("coil")
			elif sc == IsopodScript:
				c.call("roll", 5.0)
			elif sc == BeaverScript: # (its tail slapped on the water, and under)
				c.call("slap")
			elif sc == HareScript or (sc == SquirrelScript or sc == GreySqScript): # (a squirrel: up its tree)
				c.call("flee", p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * 0.5)
			elif sc == ScorpionScript and not young:
				var a := randf() * TAU
				c.call("sting", p + Vector3(cos(a), 0.0, sin(a)) * 0.03)
			elif sc == MouseScript:
				c.call("wander", p, 0.6)
			elif sc == DeerScript or sc == MooseScript:
				c.call("flee", p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * 3.0)
			elif sc == BisonScript:
				c.call("stampede", p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * 3.0)
		"display":
			if sc == AnoleScript:
				c.call("display")
			elif sc == HareScript:
				c.call("thump")
			elif (sc == SquirrelScript or sc == GreySqScript):
				c.call("flick") # (its tail flicked, chattering)
			elif sc == BisonScript:
				if _flag(c, "male") and not young:
					c.call("bellow")
			elif sc == DeerScript or sc == MooseScript:
				c.call("snort" if _flag(c, "male") and not young else "alert")
			elif c.has_method("howl"):
				c.call("howl", randf_range(5.0, 8.0))
			elif c.has_method("stand"):
				c.call("stand", randf_range(4.0, 7.0))
			elif sc == MantisScript:
				c.call("watch", p + Vector3(0.0, 0.05, 0.2))
		"play":
			if c.has_method("play"):
				c.call("play")
		"nurse":
			if c.has_method("nurse"):
				c.call("nurse")
		"forage":
			if sc == BeaverScript and not young: # (B: off for a swim)
				c.call("swim", Vector3(_bv_bank + 1.4, 0.0, st.z), 1.0)
			elif (sc == SquirrelScript or sc == GreySqScript) and not young: # (B: a nut cached)
				var a := randf() * TAU
				c.call("cache", _sq_nut_near(p), p + Vector3(cos(a), 0.0, sin(a)) * 0.7)
			elif sc == MooseScript and not young: # (B: out into the pond, feeding under the water)
				c.call("wade", _station(34) + Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.5, 0.5)))
			elif sc == DeerScript and not young:
				c.call("browse", _deer_shrub, 0.6)
			elif c.has_method("forage"):
				c.call("forage", st, 2.5)
		"spin":
			if sc == SpiderScript and not young:
				var k := spiders.find(c)
				if k == 2 or k == 3:
					if is_instance_valid(c.get("web")):
						(c.get("web") as Node).queue_free()
					if k == 2:
						c.call("spin_funnel", _station(13), 0.14)
					else:
						_spin_orb(c, randi())
		"mark":
			if sc == DeerScript or sc == MooseScript:
				if _flag(c, "male") and not young:
					c.call("mark", _deer_sapling if sc == DeerScript else _moose_sapling)
			elif c.has_method("rub"):
				var k := bears.find(_bear_trio_of(c))
				if k >= 0:
					c.call("rub", _rub_trees[k])
			elif c.has_method("mark"):
				c.call("mark")
		"sit":
			if sc == BisonScript:
				c.call("ruminate", 12.0) # (lying, chewing its cud)
			elif c.has_method("sit"):
				c.call("sit", 8.0)
			elif sc == HareScript or (sc == SquirrelScript or sc == GreySqScript):
				c.call("alert")
			elif sc == MouseScript:
				c.call("groom")


func _bear_trio_of(c: Node) -> Array:
	for t: Array in bears:
		if t.has(c):
			return t
	return []


## Something to eat (or hunt), its own kind of food, set before it.
func _feed(c: Node, act: String, young: bool, p: Vector3, st: Vector3) -> void:
	var sc: Script = c.get_script()
	var a := randf() * TAU
	var near := Vector3(cos(a), 0.0, sin(a))
	if sc == LarvaScript:
		c.call("eat")
	elif (sc == HopperScript or sc == BlueHopperScript):
		if young:
			var leaf := Beetles.leaf()
			leaf.position = Vector3(p.x, 0.0, p.z) + near * 0.03
			leaf.scale = Vector3(0.5, 1.0, 0.5)
			add_child(leaf)
			c.call("feed", leaf.position + Vector3.UP * 0.001)
		else:
			c.call("feed", _hopper_leaf + Vector3(0.0, 0.002, 0.0))
	elif sc == MantisScript:
		var f := MantisScript.fly_prey()
		f.scale = Vector3.ONE * (0.4 if young else 1.0)
		f.position = p + near * (0.03 if young else 0.06) + Vector3.UP * 0.002
		add_child(f)
		c.call("strike", f.position + Vector3(0.0, 0.004, 0.0), f)
	elif sc == SnakeScript:
		var m := SnakeScript.mouse(0.35 if young else 1.0)
		m.position = p + near * (0.15 if young else 0.4)
		add_child(m)
		c.call("eat", m)
	elif sc == SpiderScript:
		if c == spiders[1] and not young:
			_spider_fish()
			return
		var f := MantisScript.fly_prey()
		add_child(f)
		match c.get("kind"):
			"funnel":
				var w: Node3D = c.get("web")
				if young or not is_instance_valid(w):
					f.position = p + near * 0.04
				else:
					var at := w.position + near * 0.07
					at.y = w.call("surface_y", at.x, at.z)
					f.position = at
			"argiope":
				var w: Node3D = c.get("web")
				if young or not is_instance_valid(w):
					f.position = p + near * 0.04
				else:
					var n: int = w.call("count")
					f.position = w.call("point", int(n * randf_range(0.45, 0.85)))
					f.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			_:
				f.position = p + near * (0.04 if young else 0.15)
		if young:
			f.scale = Vector3.ONE * 0.35
		c.call("hunt", f)
	elif sc == IsopodScript:
		c.call("eat", p + near * 0.01)
	elif sc == MouseScript:
		if not young or float(c.get("size")) >= 0.25:
			c.call("eat", _seed_near(p))
	elif sc == AnoleScript or sc == ScorpionScript:
		if c.get("_mother") != null:
			return
		var f: Node3D
		if sc == AnoleScript:
			f = MantisScript.fly_prey()
			f.scale = Vector3.ONE * (0.25 if young else 0.5)
			f.position = p + near * (0.05 if young else 0.12)
		else:
			f = ScorpionScript.cricket()
			f.scale = Vector3.ONE * (0.3 if young else 1.0)
			f.position = p + near * (0.04 if young else 0.1)
		add_child(f)
		c.call("hunt", f)
	elif sc == HareScript:
		c.call("eat", _hare_food_near(p, act == "hunt" and not young)) # (H: the willow shoot, sitting up)
	elif (sc == SquirrelScript or sc == GreySqScript):
		if not young:
			c.call("eat", _sq_nut_near(p))
	elif sc == BeaverScript:
		if young:
			return
		if act == "hunt": # (H: a sapling felled, a length of it to the lodge)
			for t in _bv_saplings:
				if is_instance_valid(t) and (t as Node3D).transform.basis.y.y > 0.9 and not t.has_meta("felling"):
					t.set_meta("felling", true) # (each its own)
					c.call("fell", t)
					return
		var best: Node3D = null
		for t in _bv_sticks:
			if is_instance_valid(t) and t.get_parent() == self and (best == null or (t as Node3D).position.distance_to(p) < best.position.distance_to(p)):
				best = t
		if best == null:
			best = _bv_stick(Vector3(_bv_bank - 0.6 - randf() * 0.8, 0.0, st.z + randf_range(-1.0, 1.0)))
		c.call("eat", best)
	elif sc == MothScript: # (nectar: hovering at its flowers, one floret after another)
		if not young:
			c.call("feed", _moth_flowers)
	elif sc == TrigScript: # (nectar: from flower to flower)
		c.call("visit_flowers", _trig_heads, 0.0)
	elif sc == Wasp:
		var cat := Wasp.caterpillar()
		var at := st + Vector3(-0.12, 0.004, 0.1)
		cat.position = at
		add_child(cat)
		c.call("feed_on_insect", cat, at, Vector3.UP)
	elif sc == BisonScript or sc == DeerScript or sc == MooseScript:
		if act == "eat":
			if not young:
				c.call("graze", p, 3.0 if sc == BisonScript else 2.0)
		elif _flag(c, "male") and not young: # (H: a bull, a buck, sparring with another)
			for o in _here():
				if o != c and o.get_script() == sc and _flag(o, "male") and not _young(o) and (sc == BisonScript or o.get("season") == c.get("season")):
					c.call("spar", o)
					break
	elif c.has_method("browse") and act == "eat": # (a bear: berries)
		var k := bears.find(_bear_trio_of(c))
		if k >= 0:
			c.call("browse", _bushes[k][randi() % (_bushes[k] as Array).size()])
	elif c.has_method("hunt") and not young: # (the hunters: their prey here)
		if sc == FoxScript:
			c.call("hunt", _fox_mouse())
		elif sc == BobcatScript:
			c.call("hunt", _new_cat_hare())
		elif sc == CoyoteScript:
			c.call("hunt", _station_mouse(22) if randf() < 0.5 else _station_hare(22))
		elif sc == WolfScript:
			c.call("hunt", _station_hare(23))
		else: # (a bear, hunting: the hare here, or a new one)
			c.call("hunt", _station_hare(_at))


## To station i (the camera further off for the snakes).
func _go(i: int) -> void:
	_at = i
	_dist = 1.6 if i == 35 or i == 36 else 9.0 if i == 34 else 2.2 if i == 33 else 0.8 if i == 32 else 2.4 if i == 31 else 4.2 if i == 30 else 2.4 if i == 29 else 0.8 if i == 28 else 2.2 if i == 9 or i == 10 else (2.4 if i == 19 else ((6.0 if i >= 27 else (9.0 if i >= 26 else (7.5 if i >= 24 else (5.0 if i >= 22 else 3.6)))) if i >= 20 else minf(_dist, 0.8)))
	_say()


func _say() -> void:
	_label.text = "%s   (Tab / Shift+Tab: the next station; the keys act on those here)\n1 lay eggs / give birth   2 hatch / come out   3 new pupae   E eat   H hunt   K mate   G groom   Z sleep / rest\nF fly / hop   X alarm (flee, roll up, coil, sting)   D display / call   V the young play   N nurse   B forage\nS spin a web   M mark   A sit   W back to their own ways   P steered   Space slow motion   drag: turn round   wheel: nearer / further" % NAMES[_at]


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
