extends Node3D
## The ecology sandbox: one scene, staged by hand, every creature not yet in
## the game and the plants and water they live by, to try them together in
## any mix: godot --path . res://tools/creatures/ecology_demo.tscn
##
## THE MOUSE
## - the list (left): a plant, a feature (a pond, sand) or an animal; then
##   left click on the ground to put one there (and again, and again: each
##   click another); right click or Esc: done. Its stage (adult, young, pupa)
##   and its sex (male) from the boxes under the list.
## - left click on a creature (not placing): it's selected (Shift: added to
##   the selection); on the ground: none selected. Delete: the selected
##   gone (and what was put down with it: its den, its nest, its comb...).
## - right drag: round it; middle drag (or the arrow keys): along the
##   ground; the wheel: nearer, further; C: to the selection.
##
## THE KEYS act on the selection (none selected: on everything): 1 lay eggs /
## give birth, 2 hatch / come out / moult / shed, 3 pupate, E eat, H hunt, U an
## unusual meal, K mate (each male with the nearest female of his kind),
## G groom, Z sleep / rest, F fly / hop / climb, X alarm (flee, roll up,
## coil, sting, play dead), D display / call, V the young play, N nurse, B
## forage (home, gather, swim, cache, wade), S spin a web, M mark, A sit, W
## back to their own ways; Space slow motion.
##
## What each needs and isn't here is put down for it, close by, the first
## time it needs it (a den, a nest, a comb, a web's moorings, a pond, a
## sapling, its food): a creature put down alone still does all it does.
## Whatever's here already is used first: a hunter goes for prey that's here
## (a fox put down by mice hunts those mice); a butterfly to the flowers
## that are here; a frog to the pond that's here.

const Flowers := preload("res://tools/creatures/demo_flowers.gd")
const MothScript := preload("res://scripts/creatures/hummingbird_moth.gd")
const MonarchScript := preload("res://scripts/creatures/monarch.gd")
const SwallowScript := preload("res://scripts/creatures/swallowtail.gd")
const LunaScript := preload("res://scripts/creatures/luna_moth.gd")
const HarvesterScript := preload("res://scripts/creatures/harvester_ants.gd")
const JuneScript := preload("res://scripts/creatures/june_beetles.gd")
const LadyScript := preload("res://scripts/creatures/lady_beetles.gd")
const LarvaScript := preload("res://scripts/creatures/larva.gd")
const BroodScript := preload("res://scripts/creatures/brood.gd")
const PupaScript := preload("res://scripts/creatures/pupa.gd")
const SpiderScript := preload("res://scripts/creatures/spider.gd")
const IsopodScript := preload("res://scripts/creatures/isopod.gd")
const SnakeScript := preload("res://scripts/creatures/snake.gd")
const HopperScript := preload("res://scripts/creatures/grasshopper.gd")
const BlueHopperScript := preload("res://scripts/creatures/blue_winged_grasshopper.gd")
const DragonflyScript := preload("res://scripts/creatures/dragonfly.gd")
const MantisScript := preload("res://scripts/creatures/mantis.gd")
const MouseScript := preload("res://scripts/creatures/mouse.gd")
const MolliesScript := preload("res://scripts/creatures/mollies.gd")
const FishScript := preload("res://scripts/creatures/fish_school.gd")
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
const ToadScript := preload("res://scripts/creatures/american_toad.gd")
const TurtleScript := preload("res://scripts/creatures/turtle.gd")
const SnapScript := preload("res://scripts/creatures/snapping_turtle.gd")
const PaintedScript := preload("res://scripts/creatures/painted_turtle.gd")
const SeaScript := preload("res://scripts/creatures/sea_turtle.gd")
const SquirrelScript := preload("res://scripts/creatures/fox_squirrel.gd")
const GreySqScript := preload("res://scripts/creatures/grey_squirrel.gd")
const BeaverScript := preload("res://scripts/creatures/beaver.gd")
const TrigScript := preload("res://scripts/creatures/trigonalid.gd")
const IchScript := preload("res://scripts/creatures/ichneumon.gd")
const MealScript := preload("res://scripts/creatures/meal.gd")
const MoltScript := preload("res://scripts/creatures/molt.gd")
const OpossumScript := preload("res://scripts/creatures/opossum.gd")
const BeeScript := preload("res://scripts/creatures/bumblebee.gd")
const CarcassScript := preload("res://scripts/creatures/carcass.gd")
const CrayScript := preload("res://scripts/creatures/crayfish.gd")
const RedCrayScript := preload("res://scripts/creatures/red_swamp_crayfish.gd")
const VirileCrayScript := preload("res://scripts/creatures/virile_crayfish.gd")
const ShrimpScript := preload("res://scripts/creatures/shrimp.gd")
const SHRIMP := {"white_shrimp": preload("res://scripts/creatures/white_shrimp.gd"), "brown_shrimp": preload("res://scripts/creatures/brown_shrimp.gd"), "pink_shrimp": preload("res://scripts/creatures/pink_shrimp.gd")}

const PersonalSpace := preload("res://scripts/creatures/personal_space.gd")
const HALF := 12.0 ## m: the plain's half width (it's square)
const POND := -0.004 ## m: a pond's surface, a little below the plain
const GRASS := Color(0.36, 0.4, 0.22)
const TILE := 4.0 # (m: the grass's tiles)

## What can be put down: [its group, its name, its key, its stages (the
## first the default)].
const CATALOGUE := [
	["Plants", "common milkweed", "milkweed", ["adult"]],
	["Plants", "swamp milkweed", "swamp_milkweed", ["adult"]],
	["Plants", "purple coneflower", "coneflower", ["adult"]],
	["Plants", "black-eyed Susan", "susan", ["adult"]],
	["Plants", "fleabane", "fleabane", ["adult"]],
	["Plants", "aster", "aster", ["adult"]],
	["Plants", "yampah", "yampah", ["adult"]],
	["Plants", "nettle", "nettle", ["adult"]],
	["Plants", "baccy (wild tobacco)", "tobacco", ["adult"]],
	["Features", "puddle (5 cm)", "puddle", ["adult"]],
	["Features", "small pond (20 cm)", "small_pond", ["adult"]],
	["Features", "pond (45 cm)", "pond", ["adult"]],
	["Features", "large pond (45 cm)", "large_pond", ["adult"]],
	["Features", "sea (1.1 m) and beach", "sea", ["adult"]],
	["Features", "sand", "sand", ["adult"]],
	["Features", "gravel", "gravel", ["adult"]],
	["Features", "dead branch (leaning)", "snag", ["adult"]],
	["Insects", "monarch", "monarch", ["adult", "young", "pupa"]],
	["Insects", "hummingbird clearwing", "moth", ["adult", "young", "pupa"]],
	["Insects", "Old World swallowtail", "swallowtail", ["adult", "young", "pupa"]],
	["Insects", "luna moth", "luna", ["adult", "young", "pupa"]],
	["Insects", "paper wasp", "wasp", ["adult", "young"]],
	["Insects", "common eastern bumble bee", "bee", ["adult", "queen"]],
	["Insects", "trigonalid wasp", "trig", ["adult"]],
	["Insects", "ichneumon wasp", "ichneumon", ["adult"]],
	["Insects", "carpenter ant (queen)", "carpenter", ["adult", "young"]],
	["Insects", "red harvester (queen)", "harvester", ["adult", "young"]],
	["Insects", "June bugs (a pair)", "june", ["adult", "young"]],
	["Insects", "convergent lady beetles (a pair)", "lady", ["adult", "young"]],
	["Insects", "differential grasshopper", "hopper", ["adult", "young"]],
	["Insects", "blue-winged grasshopper", "blue_hopper", ["adult", "young"]],
	["Insects", "Carolina mantis", "mantis", ["adult", "young"]],
	["Insects", "common green darner", "darner", ["adult", "young"]],
	["Spiders and kin", "Carolina wolf spider", "wolf_spider", ["adult", "young"]],
	["Spiders and kin", "six-spotted fishing spider", "fishing_spider", ["adult", "young"]],
	["Spiders and kin", "grass spider (funnel weaver)", "funnel_spider", ["adult", "young"]],
	["Spiders and kin", "yellow garden spider", "garden_spider", ["adult", "young"]],
	["Spiders and kin", "Arizona bark scorpion", "scorpion", ["adult", "young"]],
	["Spiders and kin", "pill bug", "pillbug", ["adult", "young"]],
	["Crustaceans", "red swamp crayfish", "red_crayfish", ["adult", "young"]],
	["Crustaceans", "virile crayfish", "virile_crayfish", ["adult", "young"]],
	["Crustaceans", "white shrimp (in the sea)", "white_shrimp", ["adult", "young"]],
	["Crustaceans", "brown shrimp (in the sea)", "brown_shrimp", ["adult", "young"]],
	["Crustaceans", "pink shrimp (in the sea)", "pink_shrimp", ["adult", "young"]],
	["Fish", "sailfin mollies (a school)", "mollies", ["adult"]],
	["Fish", "Chinook salmon, at sea (a school)", "chinook", ["adult"]],
	["Fish", "Chinook salmon, spawning (a few)", "chinook_spawning", ["adult"]],
	["Fish", "rainbow trout, in a stream (a few)", "rainbow", ["adult"]],
	["Fish", "steelhead, in a stream (a few)", "steelhead", ["adult"]],
	["Fish", "Atlantic bluefin tuna (a school)", "bluefin", ["adult"]],
	["Amphibians and reptiles", "northern leopard frog", "frog", ["adult", "young"]],
	["Amphibians and reptiles", "American toad", "toad", ["adult", "young"]],
	["Amphibians and reptiles", "green anole", "anole", ["adult", "young"]],
	["Amphibians and reptiles", "eastern diamondback rattlesnake", "rattler", ["adult", "young"]],
	["Amphibians and reptiles", "eastern milk snake", "milk", ["adult", "young"]],
	["Amphibians and reptiles", "eastern box turtle", "box_turtle", ["adult", "young"]],
	["Amphibians and reptiles", "common snapping turtle", "snapper", ["adult", "young"]],
	["Amphibians and reptiles", "western painted turtle", "painted", ["adult", "young"]],
	["Amphibians and reptiles", "green sea turtle", "sea_turtle", ["adult", "young"]],
	["Mammals", "deer mouse", "mouse", ["adult", "young"]],
	["Mammals", "snowshoe hare", "hare", ["adult", "young"]],
	["Mammals", "eastern fox squirrel", "fox_squirrel", ["adult"]],
	["Mammals", "eastern grey squirrel", "grey_squirrel", ["adult"]],
	["Mammals", "North American beaver", "beaver", ["adult", "young"]],
	["Mammals", "Virginia opossum", "opossum", ["adult", "young"]],
	["Mammals", "red fox", "fox", ["adult", "young"]],
	["Mammals", "bobcat", "bobcat", ["adult", "young"]],
	["Mammals", "coyote", "coyote", ["adult", "young"]],
	["Mammals", "grey wolf", "wolf", ["adult", "young"]],
	["Mammals", "American black bear", "black_bear", ["adult", "young"]],
	["Mammals", "brown bear (grizzly)", "brown_bear", ["adult", "young"]],
	["Mammals", "white-tailed deer (summer)", "deer", ["adult", "young"]],
	["Mammals", "white-tailed deer (winter)", "deer_winter", ["adult"]],
	["Mammals", "moose", "moose", ["adult", "young"]],
	["Mammals", "American bison", "bison", ["adult", "young"]],
	["Carcasses", "grey wolf", "carcass_wolf", ["adult"]],
	["Carcasses", "American black bear", "carcass_black_bear", ["adult"]],
	["Carcasses", "brown bear (grizzly)", "carcass_brown_bear", ["adult"]],
	["Carcasses", "white-tailed deer", "carcass_deer", ["adult"]],
	["Carcasses", "moose", "carcass_moose", ["adult"]],
	["Carcasses", "American bison", "carcass_bison", ["adult"]],
]

## Ponds by their size: [half width, half depth, deep] (m).
const PONDS := {
	"puddle": [0.32, 0.24, 0.05], "small_pond": [0.5, 0.4, 0.2], "pond": [1.2, 0.9, 0.45],
	"large_pond": [1.6, 1.0, 0.45], "sea": [3.2, 2.4, 1.1], "salmon": [3.0, 2.0, 1.4], "trout": [2.2, 0.7, 0.55], "ocean": [10.0, 6.0, 3.5], "darner": [0.6, 0.45, 0.09], "fishing": [0.42, 0.36, 0.3],
	"beaver": [1.5, 2.0, 0.3],
}

## The keys: one for each thing they all do.
const KEYS := {
	KEY_1: "lay", KEY_2: "hatch", KEY_3: "pupae", KEY_E: "eat", KEY_H: "hunt", KEY_K: "mate",
	KEY_G: "groom", KEY_Z: "sleep", KEY_F: "fly", KEY_X: "alarm", KEY_D: "display", KEY_V: "play",
	KEY_N: "nurse", KEY_B: "forage", KEY_S: "spin", KEY_M: "mark", KEY_A: "sit", KEY_W: "wander",
	KEY_U: "unusual", KEY_R: "mushroom",
}

var cam: Camera3D
var _yaw := 0.6
var _pitch := -0.55
var _dist := 3.0
var _focus := Vector3.ZERO
var _sun_dir := Vector3(0.4, 0.6, 0.6)
var _ponds: Array = [] # each {c, hw, hd, deep, kind, nodes, stems, perches, mollies, midges}
var _ground: Array = [] # (the plain's pieces round the ponds)
var _grass := {} # Vector2i -> the tile's holder
var _grass_on := true
var _clearings: Array = [] # [point, radius]: the grass kept off round small creatures
var _plants: Array = [] # (holders: meta kind, heads, florets, leaves, fruit...)
var _selected: Array = []
var _rings: Array[MeshInstance3D] = []
var _placing := "" # (the catalogue key being put down)
var _ghost: MeshInstance3D
var _ui_tree: Tree
var _ui_stage: OptionButton
var _ui_male: CheckBox
var _ui_decay: OptionButton
var _ui_info: Label
var _status := ""
var _ring_mesh: TorusMesh
var _ring_mat: StandardMaterial3D
var _worker_colonies := {} # (each queen's (or larva's kind's) workers: kind -> colony)


func _ready() -> void:
	# (the game's trees here whole wherever they stand: no levels of detail,
	# no chunks; and a butterfly's flower held still under it)
	OakTree.set_lod_fade(false)
	Lepidoptera.sway_of = _sway_of
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
	sun.directional_shadow_max_distance = 12.0
	add_child(sun)
	cam = Camera3D.new()
	cam.near = 0.002
	cam.far = 80.0
	cam.fov = 50.0
	add_child(cam)
	_ring_mesh = TorusMesh.new()
	_ring_mesh.inner_radius = 0.92
	_ring_mesh.outer_radius = 1.0
	_ring_mesh.rings = 24
	_ring_mesh.ring_segments = 4
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.albedo_color = Color(1.0, 0.85, 0.2)
	_ring_mat.no_depth_test = true
	_ghost = MeshInstance3D.new()
	_ghost.mesh = _ring_mesh
	var gm := _ring_mat.duplicate() as StandardMaterial3D
	gm.albedo_color = Color(0.4, 0.9, 1.0)
	_ghost.material_override = gm
	_ghost.visible = false
	add_child(_ghost)
	_rebuild_ground()
	for ix in int(HALF * 2.0 / TILE):
		for iz in int(HALF * 2.0 / TILE):
			_grass_tile(Vector2i(ix, iz))
	_build_ui()
	_say()


# --- the world: its ground, its ponds, its grass ---------------------------------

## The plain: a square, holes left in it for the ponds (each sunk in it).
func _rebuild_ground() -> void:
	for n in _ground:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_ground.clear()
	var rects: Array[Rect2] = [Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0)]
	for p: Dictionary in _ponds:
		var c: Vector3 = p.c
		var hole := Rect2(c.x - float(p.hw), c.z - float(p.hd), float(p.hw) * 2.0, float(p.hd) * 2.0)
		var out: Array[Rect2] = []
		for r in rects:
			out.append_array(_cut(r, hole))
		rects = out
	for r in rects:
		var b := _box_at(Vector3(r.get_center().x, -0.005, r.get_center().y), Vector3(r.size.x, 0.01, r.size.y), GRASS)
		_ground.append(b)


## (r less the hole: up to four rectangles.)
static func _cut(r: Rect2, hole: Rect2) -> Array[Rect2]:
	if not r.intersects(hole):
		return [r]
	var i := r.intersection(hole)
	var out: Array[Rect2] = []
	if i.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, i.position.y - r.position.y))
	if i.end.y < r.end.y:
		out.append(Rect2(r.position.x, i.end.y, r.size.x, r.end.y - i.end.y))
	if i.position.x > r.position.x:
		out.append(Rect2(r.position.x, i.position.y, i.position.x - r.position.x, i.size.y))
	if i.end.x < r.end.x:
		out.append(Rect2(i.end.x, i.position.y, r.end.x - i.end.x, i.size.y))
	return out.filter(func(q: Rect2) -> bool: return q.size.x > 0.001 and q.size.y > 0.001)


## The grass on tile t (the game's short grass: DemoFlowers.meadow), kept
## off the ponds and the clearings; made again when they change.
func _grass_tile(t: Vector2i) -> void:
	if _grass.has(t) and is_instance_valid(_grass[t]):
		(_grass[t] as Node).queue_free()
	var holder := Node3D.new()
	var x0 := -HALF + t.x * TILE
	var zc := -HALF + (t.y + 0.5) * TILE
	holder.position = Vector3(0.0, 0.0, zc)
	holder.visible = _grass_on
	add_child(holder)
	_grass[t] = holder
	Flowers.meadow(holder, x0, x0 + TILE, TILE * 0.5, GRASS, func(x: float, z: float) -> bool: return _grass_clear(x, z + zc), 5.0, 1 + t.x * 37 + t.y * 101)


func _grass_clear(x: float, z: float) -> bool:
	for p: Dictionary in _ponds:
		var c: Vector3 = p.c
		if absf(x - c.x) < float(p.hw) + 0.06 and absf(z - c.z) < float(p.hd) + 0.06:
			return true
	for cl: Array in _clearings:
		var c: Vector3 = cl[0]
		if Vector2(x - c.x, z - c.z).length() < float(cl[1]):
			return true
	return false


## (The grass made again on the tiles touching the rectangle.)
func _regrass(r: Rect2) -> void:
	var n := int(HALF * 2.0 / TILE)
	for ix in n:
		for iz in n:
			var tr := Rect2(-HALF + ix * TILE, -HALF + iz * TILE, TILE, TILE)
			if tr.intersects(r.grow(0.1)):
				_grass_tile(Vector2i(ix, iz))


## A clearing in the grass round p (r m): for something small to be seen.
func _clear_grass(p: Vector3, r: float) -> void:
	_clearings.append([p, r])
	_regrass(Rect2(p.x - r, p.z - r, r * 2.0, r * 2.0))


## A pond sunk in the plain at c (half width hw, half depth hd, deep): mud
## round its floor and walls, the game's own water over it (ocean.gdshader,
## calm), reeds standing in it.
func _dig_pond(c: Vector3, hw: float, hd: float, deep: float, kind := "") -> Dictionary:
	c.y = 0.0
	var p := {"c": c, "hw": hw, "hd": hd, "deep": deep, "kind": kind, "nodes": [], "stems": [], "perches": [], "mollies": null, "midges": []}
	var mud := Color(0.16, 0.13, 0.09)
	var nodes: Array = p.nodes
	nodes.append(_box_at(c + Vector3(0.0, -deep, 0.0), Vector3(hw * 2.0, 0.02, hd * 2.0), mud))
	# (its banks: steep all round but one, a sloping bank of mud on its +x side,
	# to walk in and out by: p.ramp, its foot and its top, rw its half width)
	var ramp := kind not in ["sea", "puddle", "ocean"] and deep >= 0.08
	var rw := hd * 0.45
	var rl := deep * 2.2
	for sgn: float in [-1.0, 1.0]:
		if sgn > 0.0 and ramp:
			for zs: float in [-1.0, 1.0]:
				nodes.append(_box_at(c + Vector3(hw, -deep * 0.5, zs * (rw + (hd - rw) * 0.5)), Vector3(0.01, deep, hd - rw), mud))
		else:
			nodes.append(_box_at(c + Vector3(sgn * hw, -deep * 0.5, 0.0), Vector3(0.01, deep, hd * 2.0), mud))
		nodes.append(_box_at(c + Vector3(0.0, -deep * 0.5, sgn * hd), Vector3(hw * 2.0, deep, 0.01), mud))
	if ramp:
		var foot := c + Vector3(hw - rl, -deep + 0.02, 0.0)
		var top := c + Vector3(hw, 0.0, 0.0)
		var slope := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(foot.distance_to(top), 0.012, rw * 2.0)
		slope.mesh = bm
		var sm := StandardMaterial3D.new()
		sm.albedo_color = mud
		sm.roughness = 1.0
		slope.material_override = sm
		slope.position = (foot + top) * 0.5 - Vector3(0.0, 0.006, 0.0)
		slope.rotation.z = atan2(top.y - foot.y, top.x - foot.x)
		add_child(slope)
		nodes.append(slope)
		p["ramp"] = [foot, top, rw]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/ocean.gdshader")
	var img := Image.create(4, 4, false, Image.FORMAT_RF)
	img.fill(Color(POND - deep, 0.0, 0.0, 1.0))
	m.set_shader_parameter("height_tex", ImageTexture.create_from_image(img))
	m.set_shader_parameter("map_size", 4.0)
	m.set_shader_parameter("map_domain", 400.0)
	m.set_shader_parameter("map_origin", Vector2(-200.0, -200.0))
	m.set_shader_parameter("sun_direction", _sun_dir)
	m.set_shader_parameter("sea_state", 0.02 if kind != "sea" else 0.08)
	m.set_shader_parameter("swell_height", 0.0)
	m.set_shader_parameter("peak_length", 2.0)
	m.set_shader_parameter("choppiness", 0.3)
	if kind != "sea":
		m.set_shader_parameter("absorption", Vector3(1.2, 0.6, 0.5)) # (a pond's water: brown green)
		m.set_shader_parameter("scatter_color", Vector3(0.02, 0.035, 0.02))
		m.set_shader_parameter("crest_color", Vector3(0.1, 0.18, 0.1))
	var cell := maxf(0.01, hw * 2.0 / 100.0)
	var nx := int(hw * 2.0 / cell)
	var nz := int(hd * 2.0 / cell)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var q := [Vector2(ix, iz), Vector2(ix + 1, iz), Vector2(ix + 1, iz + 1), Vector2(ix, iz + 1)]
			for e in [0, 2, 1, 0, 3, 2]:
				var g: Vector2 = q[e]
				st.set_uv(Vector2(cell, 0.0))
				st.add_vertex(Vector3(-hw + g.x * cell, 0.0, -hd + g.y * cell))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.position = Vector3(c.x, POND, c.z)
	add_child(mi)
	nodes.append(mi)
	if kind not in ["sea", "ocean"] and deep >= 0.08: # (reeds: their tips perches, their stems to lay in and climb out on)
		for k in clampi(int(hw * hd * 30.0), 4, 9):
			var a := float(k) / 7.0 * TAU + randf_range(-0.3, 0.3)
			var foot := c + Vector3(cos(a) * hw * randf_range(0.3, 0.8), -deep, sin(a) * hd * randf_range(0.3, 0.8))
			var top := randf_range(0.25, 0.42)
			nodes.append(_box_at(foot + Vector3(0.0, (top + deep) * 0.5, 0.0), Vector3(0.006, top + deep, 0.006), Color(0.34, 0.46, 0.18)))
			(p.stems as Array).append([foot, Vector3(foot.x, top, foot.z)])
			(p.perches as Array).append(Vector3(foot.x, top + 0.003, foot.z))
	if kind == "sea": # (its beach, to nest on)
		var beach := c + Vector3(-hw - 1.0, 0.0, 0.0)
		nodes.append(_box_at(beach + Vector3(0.0, 0.0008, 0.0), Vector3(1.9, 0.002, hd * 2.0), Color(0.78, 0.7, 0.52)))
		p["bank"] = beach
	_ponds.append(p)
	_rebuild_ground()
	_regrass(Rect2(c.x - hw, c.z - hd, hw * 2.0, hd * 2.0))
	return p


## The pond at or near p (within reach of its edge), or none ({}).
func _pond_near(p: Vector3, reach := 1.0) -> Dictionary:
	var best := {}
	var bd := INF
	for q: Dictionary in _ponds:
		var c: Vector3 = q.c
		var dx := maxf(absf(p.x - c.x) - float(q.hw), 0.0)
		var dz := maxf(absf(p.z - c.z) - float(q.hd), 0.0)
		var d := Vector2(dx, dz).length()
		if d <= reach and d < bd:
			bd = d
			best = q
	return best


## A pond of this kind for a creature at p: the one there, or one dug beside
## p (so p's on its bank) if there's none.
func _pond_for(p: Vector3, kind: String) -> Dictionary:
	var q := _pond_near(p, 1.0)
	if not q.is_empty():
		return q
	var d: Array = PONDS[kind]
	var c := p + Vector3(float(d[0]) + 0.25, 0.0, 0.0)
	return _dig_pond(c, d[0], d[1], d[2], kind)


func _in_pond(q: Dictionary, x: float, z: float, margin := 0.0) -> bool:
	var c: Vector3 = q.c
	return absf(x - c.x) < float(q.hw) - margin and absf(z - c.z) < float(q.hd) - margin


## The ground's height at (x, z): the plain's, a pond's floor, or its
## sloping bank.
func _height(x: float, z: float) -> float:
	for q: Dictionary in _ponds:
		if q.has("ramp"):
			var rp: Array = q.ramp
			var f: Vector3 = rp[0]
			var t: Vector3 = rp[1]
			if absf(z - f.z) < float(rp[2]) and x >= f.x and x <= t.x + 0.005:
				return lerpf(f.y, t.y, clampf((x - f.x) / (t.x - f.x), 0.0, 1.0))
		if _in_pond(q, x, z, 0.0): # (its floor right up to its walls: nothing walks along its rim over the water)
			return -float(q.deep) + 0.02
	return 0.0


# --- putting things down ---------------------------------------------------------

## The thing of catalogue key `key` put down at `at` (stage: adult, young,
## pupa; male). The organism (or the plant, the feature) it is.
func spawn(key: String, at: Vector3, stage := "adult", male := false) -> Node:
	at.y = 0.0
	var young := stage == "young"
	var n: Node = null
	match key:
		"milkweed", "swamp_milkweed", "coneflower", "susan", "fleabane", "aster", "yampah", "nettle", "tobacco":
			n = _plant_flowers(key, at)
		"puddle", "small_pond", "pond", "large_pond", "sea":
			var d: Array = PONDS[key]
			var q := _dig_pond(at, d[0], d[1], d[2], key)
			n = (q.nodes as Array)[(q.nodes as Array).size() - 1]
			n.set_meta("pond", true)
		"sand", "gravel":
			n = _box_at(at + Vector3(0.0, 0.0008, 0.0), Vector3(0.8, 0.002, 0.8), Color(0.72, 0.62, 0.46) if key == "sand" else Color(0.55, 0.5, 0.42))
			if key == "gravel":
				for k in 14:
					_kit_box(n, at + Vector3(randf_range(-0.36, 0.36), 0.002, randf_range(-0.36, 0.36)), Vector3.ONE * randf_range(0.004, 0.009), Color(0.5, 0.45, 0.38).lerp(Color(0.62, 0.58, 0.52), randf()))
		"snag":
			n = OpossumScript.snag(at, at + Vector3(-0.45, 0.85, -0.5))
			n.set_meta("snag", [at, at + Vector3(-0.45, 0.85, -0.5), 0.035])
			add_child(n)
		"carcass_wolf", "carcass_black_bear", "carcass_brown_bear", "carcass_deer", "carcass_moose", "carcass_bison":
			var k := key.substr(8)
			var sc: Script = {"wolf": WolfScript, "black_bear": BlackBearScript, "brown_bear": BrownBearScript, "deer": DeerScript, "moose": MooseScript, "bison": BisonScript}[k]
			var args: Array = {"black_bear": ["black"], "brown_bear": [["brown", "grizzled", "blond"][randi() % 3]], "deer": ["summer" if randf() < 0.5 else "winter"]}.get(k, [])
			n = CarcassScript.make(self, sc, at, randf() * TAU, (_ui_decay.selected + 1) if _ui_decay else 1, male, args)
		_:
			if key.begins_with("g_") or key.begins_with("s_"):
				n = _plant_game(key.substr(2), at, key.begins_with("s_") or young)
			elif key.begins_with("item_"):
				n = _laid(key.substr(5), at, randf() * TAU)
			else:
				n = _spawn_animal(key, at, stage, male, young)
	if n == null:
		return null
	n.set_meta("placed", key)
	if n is Node3D and not n.has_meta("home"):
		n.set_meta("home", at)
	return n


func _plant_flowers(kind: String, at: Vector3) -> Node3D:
	var tall := {"milkweed": 1.0, "swamp_milkweed": 0.95, "coneflower": 0.7, "susan": 0.7, "fleabane": 0.5, "aster": 0.6, "yampah": 0.6, "nettle": 0.8, "tobacco": 0.9}
	var holder := Node3D.new()
	add_child(holder)
	# swaying in the wind as the game's do (the ground cover's grass_sway *
	# its size); not the milkweeds (stout, stiff, eggs and caterpillars on
	# their leaves, which don't sway with them)
	var sway_k: float = 0.0 if kind in ["milkweed", "swamp_milkweed"] else FLOWER_SWAY * float(tall[kind])
	var made: Dictionary = Flowers.build(holder, kind, Vector2(at.x, at.z), tall[kind], GRASS, sway_k)
	holder.set_meta("plant", kind)
	holder.set_meta("sway_k", sway_k)
	# (each head's share of its sway, for the insects to sway with it: its
	# height's share * the square root of the clump's (they square it))
	holder.set_meta("heads", (made.heads as Array).map(func(h: Array) -> Array: return [h[0], h[1], float(h[2]) * sqrt(sway_k)]))
	holder.set_meta("florets", (made.heads as Array).map(func(h: Array) -> Vector3: return h[0]))
	holder.set_meta("leaves", made.get("leaves", []))
	holder.set_meta("home", at)
	_plants.append(holder)
	return holder


## One of the game's trees or bushes (id: _game_trees()), grown, or a
## sapling (young): its own mesh, swaying in the wind as it does in the
## game, its fruit hanging where it bears it (Items' models, each named
## berry_n: a bear eats copies of them, Ursid.browse, the bush keeping its own). Its origin at its foot.
func _plant_game(id: String, at: Vector3, young: bool) -> Node3D:
	var gt := _game_trees()
	if not gt.has(id):
		return null
	var sc: Script = gt[id][1]
	var bush: bool = id in ["blueberry", "raspberry"]
	var v := 1 if id == "oak" else 0 # (the oak's straight, slim one: a squirrel's)
	if id == "prickly_pear": # (the fruiting one, its tunas to pick; young: the small one)
		v = 1 if young else 2
	elif id == "joshua_tree": # (any of its grown ones, tall or short, few branches or many; young: a single stem)
		v = ([2, 9] if young else [0, 1, 3, 4, 5, 6, 7, 8])[randi() % (2 if young else 8)]
	elif id == "san_pedro": # (young: the single young stem)
		v = 2 if young else 0
	elif young and not bush:
		v = 8 if id == "black_cherry" else 9 # (its sapling)
	var holder := Node3D.new()
	holder.position = at
	add_child(holder)
	var mi := MeshInstance3D.new()
	mi.mesh = sc.call("build", v)
	holder.add_child(mi)
	var fruit := String(sc.call("fruit_of", v)) if sc.has_method("fruit_of") else ""
	if fruit != "" and Items.exists(fruit):
		var spots: PackedVector3Array = sc.call("fruit_spots", v)
		for i in mini(spots.size(), 24):
			var f := Items.model(fruit)
			f.name = "berry_%d" % i
			f.position = spots[i]
			holder.add_child(f)
	var key := ("s_" if young and not bush else "g_") + id
	holder.set_meta("plant", key)
	holder.set_meta("game_tree", [id, v])
	holder.set_meta("home", at)
	_plants.append(holder)
	return holder


## Item id laid on the ground at at (as it lies dropped in the game:
## Drops: turned onto its longest side, its bottom on the ground).
func _laid(id: String, at: Vector3, yaw: float) -> Node3D:
	if not Items.exists(id):
		return null
	var m := Items.model(id)
	var box := Drops._aabb(m, Transform3D())
	var lie := Basis()
	if box.size.y > maxf(box.size.x, box.size.z) * 1.3:
		lie = Basis(Vector3.RIGHT, PI * 0.5)
	var turned := Drops._aabb(m, Transform3D(lie, Vector3.ZERO))
	var root := Node3D.new()
	var holder := Node3D.new()
	holder.transform = Transform3D(lie, Vector3(0.0, -turned.position.y, 0.0))
	holder.add_child(m)
	root.add_child(holder)
	root.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	add_child(root)
	root.set_meta("item", id)
	root.set_meta("home", at)
	return root


## The plants of kind (or any kind, kinds empty) nearest p within r.
func _plants_near(p: Vector3, r: float, kinds: Array = []) -> Array:
	var out := []
	for n in _plants:
		if not is_instance_valid(n):
			continue
		var k: String = (n as Node).get_meta("plant", "")
		if not kinds.is_empty() and not kinds.has(k):
			continue
		var h: Vector3 = (n as Node).get_meta("home", Vector3.ZERO)
		if Vector2(h.x - p.x, h.z - p.z).length() <= r:
			out.append(n)
	out.sort_custom(func(a: Node, b: Node) -> bool:
		var ha: Vector3 = a.get_meta("home")
		var hb: Vector3 = b.get_meta("home")
		return ha.distance_to(p) < hb.distance_to(p))
	return out


## The nearest plant of kind to p within r; planted by it if there's none.
func _plant_near(p: Vector3, kinds: Array, r := 3.0, offset := Vector3(0.35, 0.0, -0.3)) -> Node:
	var near := _plants_near(p, r, kinds)
	if not near.is_empty():
		return near[0]
	return spawn(kinds[0], p + offset)


const FLOWER_KINDS := ["milkweed", "swamp_milkweed", "coneflower", "susan", "fleabane", "aster", "yampah", "tobacco"]
const FLOWER_SWAY := 0.3 ## (the ground cover's grass_sway: a flower's tip's, in its heights a metre of the wind)


## The flowers' heads within r of p ([top, facing, sway share] each); a
## clump planted if there are none (default: a coneflower).
func _heads_near(p: Vector3, r := 3.0, plant := "coneflower") -> Array:
	var out := []
	var ps := _plants_near(p, r, FLOWER_KINDS)
	if ps.is_empty():
		ps = [_plant_near(p, [plant], r)]
	for n: Node in ps:
		out.append_array(n.get_meta("heads", []))
	return out


## Each clump's florets within r of p (an Array of points each).
func _clumps_near(p: Vector3, r := 3.0) -> Array:
	var ps := _plants_near(p, r, FLOWER_KINDS)
	if ps.is_empty():
		ps = [_plant_near(p, ["coneflower"], r)]
	return ps.map(func(n: Node) -> Array: return n.get_meta("florets", []))


func _spawn_animal(key: String, at: Vector3, stage: String, male: bool, young: bool) -> Node:
	var c: Node = null
	match key:
		"monarch":
			if stage == "pupa":
				var tw := _twig_near(at) # (hanging under a tree's lowest branch)
				var ch := PupaScript.new("monarch")
				ch.position = (tw[2] as Vector3).lerp(tw[3], randf() * 0.6)
				return _org(ch, at, false)
			if young: # (a caterpillar: on a milkweed leaf, if there's one by it; feeding)
				var cat := LarvaScript.new("monarch")
				var mw := _plants_near(at, 1.5, ["milkweed", "swamp_milkweed"])
				var leaves: Array = (mw[0] as Node).get_meta("leaves", []) if not mw.is_empty() else []
				leaves = leaves.filter(func(l: Array) -> bool: return (l[0] as Vector3).y < 0.8)
				_org(cat, at, true)
				if not leaves.is_empty():
					var l: Array = leaves[randi() % leaves.size()]
					cat.place((l[0] as Vector3) + (l[2] as Vector3) * 0.03 + (l[1] as Vector3) * 0.004, l[2])
				else:
					cat.place(at, Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU))
				cat.eat()
				return cat
			var m := MonarchScript.new()
			m.male = male
			_org(m, at, false)
			m.place(at + Vector3(0.0, 0.5, 0.0))
			m.fly(at, 0.4)
			return m
		"swallowtail", "luna":
			if stage == "pupa": # (the swallowtail's girdled to a stem, here the ground; the luna's cocoon in the litter)
				var sp := PupaScript.new(key)
				sp.position = at
				sp.rotation.y = randf() * TAU
				if key == "luna": # (in the litter)
					var perch := _moth_perch(at, sp.rotation.y)
					sp.perch_at = perch[0]
					sp.perch_normal = perch[1]
				else: # (girdled to a tree's trunk, head up it, leaning out from it: its own +y out from the bark, -z up)
					var tw := _twig_near(at)
					var y: Vector3 = tw[4]
					sp.position = (tw[1] as Vector3) - Vector3.UP * randf_range(0.05, 0.2)
					sp.basis = Basis(y.cross(Vector3.DOWN), y, Vector3.DOWN)
					sp.perch_at = (tw[1] as Vector3) + Vector3.UP * 0.02
					sp.perch_normal = y
					return _org(sp, sp.position, true)
				return _org(sp, at, true)
			if young: # (a caterpillar: the swallowtail's on a yampah, if there's one by it; feeding)
				var cat := LarvaScript.new(key)
				_org(cat, at, true)
				var host := _plants_near(at, 1.5, ["yampah"]) if key == "swallowtail" else []
				var leaves: Array = (host[0] as Node).get_meta("leaves", []) if not host.is_empty() else []
				leaves = leaves.filter(func(l: Array) -> bool: return (l[0] as Vector3).y < 0.8)
				if not leaves.is_empty():
					var l: Array = leaves[randi() % leaves.size()]
					cat.place((l[0] as Vector3) + (l[2] as Vector3) * 0.03 + (l[1] as Vector3) * 0.004, l[2])
				else:
					cat.place(at, Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU))
				cat.eat()
				return cat
			var b: Node3D = (SwallowScript if key == "swallowtail" else LunaScript).new()
			b.set("male", male)
			_org(b, at, false)
			b.call("place", at + Vector3(0.0, 0.5, 0.0))
			b.call("fly", at, 0.4)
			return b
		"moth":
			if stage == "pupa":
				var mp := PupaScript.new("hemaris")
				mp.position = at
				mp.rotation.y = randf() * TAU
				var perch := _moth_perch(at, mp.rotation.y)
				mp.perch_at = perch[0]
				mp.perch_normal = perch[1]
				return _org(mp, at, true)
			if young:
				var worm := LarvaScript.new("hemaris")
				_org(worm, at, true)
				worm.place(at, Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU))
				worm.wander(at, 0.08)
				return worm
			var mo := MothScript.new()
			mo.male = male
			_org(mo, at, false)
			mo.place(at + Vector3(0.0, 0.4, 0.0))
			mo.feed(_flat(_clumps_near(at)))
			return mo
		"wasp":
			var comb := _comb_near(at)
			if young: # (a grub in an empty cell of the comb)
				var cells := _empty_cells(comb)
				if cells.is_empty():
					return null
				var g := LarvaScript.new("wasp")
				_org(g, at, false)
				g.place((cells[0] as Vector3) - Vector3(0.0, 0.012, 0.0) + Vector3(0.002, 0.0, 0.0), Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU))
				return g
			var w := Wasp.new()
			w.male = male
			_org(w, at, true)
			w.place(at + Vector3(0.1, 0.25, 0.1))
			w.set_meta("comb", comb)
			w.land(at + Vector3(0.1, 0.0, 0.08))
			return w
		"bee": # (a worker, or a drone (male); queen: a new queen, to mate)
			var b: Node3D = BeeScript.new(stage == "queen" and not male)
			b.set("male", male)
			_org(b, at, false)
			var nest: Node3D = _kit(b, "nest", func() -> Node3D:
				var ns: Node3D = BeeScript.nest()
				ns.position = at + Vector3(0.3, 0.0, 0.3)
				return ns)
			b.call("place", at + Vector3(0.0, 0.4, 0.0))
			if male:
				b.call("seek_food", at, 0.5)
			else:
				b.call("forage", _heads_near(at), nest.position)
			return b
		"trig", "ichneumon":
			var t: Node3D = (IchScript if key == "ichneumon" else TrigScript).new()
			t.set("male", male)
			_org(t, at, false)
			t.call("place", at + Vector3(0.0, 0.35, 0.0))
			t.call("visit_flowers", _heads_near(at, 3.0, "fleabane"), 1.0)
			return t
		"carpenter", "harvester":
			if young:
				var l := LarvaScript.new(key)
				_org(l, at, true)
				l.place(at, Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU))
				return l
			var q: AntColony = HarvesterScript.new() if key == "harvester" else AntColony.new()
			q.position = at
			q.scale = Vector3.ONE * 1.35 # (a queen: bigger)
			_org(q, at, true)
			q.setup(1, Vector3.ZERO, 0.03)
			q.set_meta("ant", key)
			return q
		"june", "lady":
			if young:
				var l := LarvaScript.new(key)
				_org(l, at, true)
				l.place(at + (Vector3(0.0, 0.0045, 0.0) if key == "lady" else Vector3.ZERO), Vector3.LEFT.rotated(Vector3.UP, randf() * TAU))
				if key == "lady":
					l.wander(at, 0.05)
				return l
			var bc: Beetles = JuneScript.new() if key == "june" else LadyScript.new()
			bc.position = at
			_org(bc, at, true)
			if key == "june":
				_kit_box(bc, at + Vector3(0.0, 0.0005, 0.0), Vector3(0.35, 0.002, 0.35), Color(0.3, 0.22, 0.14)) # (soil)
			else:
				var lf := Beetles.leaf()
				lf.position = at
				lf.scale = Vector3(2.0, 1.0, 2.0)
				_kit_add(bc, lf)
			bc.setup(2, Vector3.ZERO, 0.06 if key == "june" else 0.04) # (0 a female, 1 a male)
			return bc
		"hopper", "blue_hopper":
			var sc: Script = HopperScript if key == "hopper" else BlueHopperScript
			var g: Node3D = sc.new(true, 0.3) if young else sc.new()
			g.set("male", male and not young)
			_org(g, at, true)
			g.call("place", at, randf() * TAU)
			g.call("wander", at, 0.1 if young else 0.2)
			return g
		"mantis":
			var mt := MantisScript.new(true, 0.3) if young else MantisScript.new()
			mt.male = male and not young
			_org(mt, at, true)
			mt.place(at, randf() * TAU)
			mt.stalk(at, 0.08 if young else 0.15)
			return mt
		"darner":
			var q := _pond_for(at, "darner")
			var d: Node3D = DragonflyScript.new(young)
			d.set("male", male and not young)
			_water_set(d, q)
			d.set("perches", q.perches)
			d.set("height", func(_x: float, _z: float) -> float: return 0.0)
			_org(d, q.c, false)
			if young:
				d.call("place", (q.c as Vector3) + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.15, 0.15)), randf() * TAU)
			else:
				d.call("place", (q.c as Vector3) + Vector3(0.0, 0.4, 0.0), randf() * TAU)
				d.call("patrol", q.c, 0.9)
			return d
		"wolf_spider", "fishing_spider", "funnel_spider", "garden_spider":
			var kind: String = {"wolf_spider": "wolf", "fishing_spider": "fishing", "funnel_spider": "funnel", "garden_spider": "argiope"}[key]
			var sp := SpiderScript.new(kind, young)
			sp.male = male and not young
			if kind == "fishing": # (on the water of a pond)
				var q := _pond_for(at, "fishing")
				var c0: Vector3 = q.c
				_org(sp, c0, false)
				sp.place(c0 + Vector3(randf_range(-0.1, 0.1), POND, randf_range(-0.1, 0.1)), 0.5)
				sp.shore = c0 + Vector3(float(q.hw) * 0.8, POND, 0.1)
				sp.height = func(_x: float, _z: float) -> float: return POND
				sp.wander(c0 + Vector3(0.0, POND, 0.0), 0.2 if not young else 0.08)
				return sp
			_org(sp, at, true)
			sp.place(at, randf() * TAU)
			if young or male:
				sp.wander(at, 0.08)
			elif kind == "funnel":
				sp.spin_funnel(at, 0.14)
			elif kind == "argiope":
				get_tree().create_timer(0.3).timeout.connect(_spin_orb.bind(sp, 0))
			else:
				sp.wander(at, 0.25)
			return sp
		"red_crayfish", "virile_crayfish": # (in a pond: the one here, or one dug by it; on its bottom)
			var csc: Script = RedCrayScript if key == "red_crayfish" else VirileCrayScript
			var cq := _pond_for(at, "small_pond")
			var cr: Node3D = csc.new(young)
			cr.set("male", male and not young)
			cr.set("water_y", POND)
			cr.set("height", _height)
			var cc: Vector3 = cq.c
			var inside := at # (on the bank where it's put; in the pond, on its floor clear of its walls)
			if absf(at.x - cc.x) < float(cq.hw) and absf(at.z - cc.z) < float(cq.hd):
				inside = Vector3(clampf(at.x, cc.x - float(cq.hw) + 0.12, cc.x + float(cq.hw) - 0.12), 0.0, clampf(at.z, cc.z - float(cq.hd) + 0.12, cc.z + float(cq.hd) - 0.12))
			inside.y = _height(inside.x, inside.z)
			_org(cr, inside, false)
			cr.set_meta("pond", cc)
			cr.set("pond", Rect2(cc.x - float(cq.hw), cc.z - float(cq.hd), float(cq.hw) * 2.0, float(cq.hd) * 2.0))
			cr.set("ramp", cq.get("ramp", []))
			cr.call("place", inside, randf() * TAU)
			cr.call("wander", inside, 0.2)
			return cr
		"white_shrimp", "brown_shrimp", "pink_shrimp": # (in the sea: on its floor, clear of its walls)
			var sq := _pond_for(at, "sea")
			var sh: Node3D = (SHRIMP[key] as Script).new(young)
			sh.set("male", male and not young)
			sh.set("water_y", POND)
			sh.set("height", _height)
			var sc0: Vector3 = sq.c
			var inn := Vector3(clampf(at.x, sc0.x - float(sq.hw) + 0.25, sc0.x + float(sq.hw) - 0.25), 0.0, clampf(at.z, sc0.z - float(sq.hd) + 0.25, sc0.z + float(sq.hd) - 0.25))
			inn.y = _height(inn.x, inn.z)
			_org(sh, inn, false)
			sh.set_meta("pond", sc0)
			sh.set("pond", Rect2(sc0.x - float(sq.hw), sc0.z - float(sq.hd), float(sq.hw) * 2.0, float(sq.hd) * 2.0))
			sh.call("place", inn, randf() * TAU)
			sh.call("wander", inn, 0.6)
			return sh
		"scorpion":
			var s := ScorpionScript.new(young) if young else ScorpionScript.new()
			s.male = male and not young
			_org(s, at, true)
			if young:
				s.set("_mother", null)
			s.place(at, randf() * TAU)
			s.wander(at, 0.15)
			return s
		"pillbug":
			var pb := IsopodScript.new(young)
			pb.male = male and not young
			_org(pb, at, true)
			pb.place(at, randf() * TAU)
			if young:
				pb.grow(0.5, 60.0)
			pb.wander(at, 0.1)
			return pb
		"chinook", "chinook_spawning", "rainbow", "steelhead", "bluefin": # (each in its own water, dug by it: a deep pool; a stream, flowing; the open sea)
			var fk: String = {"chinook": "chinook", "chinook_spawning": "chinook", "rainbow": "rainbow", "steelhead": "rainbow", "bluefin": "bluefin"}[key]
			var fv: String = {"chinook": "ocean", "chinook_spawning": "spawning", "rainbow": "", "steelhead": "steelhead", "bluefin": ""}[key]
			var water: String = {"chinook": "salmon", "rainbow": "trout", "bluefin": "ocean"}[fk]
			var fq := _pond_near(at, 0.2)
			if fq.is_empty() or String(fq.kind) != water:
				var d: Array = PONDS[water]
				var dc := at + Vector3(float(d[0]) + 0.3, 0.0, 0.0)
				dc.x = clampf(dc.x, -HALF + float(d[0]) + 0.2, HALF - float(d[0]) - 0.2) # (all of it on the plain)
				dc.z = clampf(dc.z, -HALF + float(d[1]) + 0.2, HALF - float(d[1]) - 0.2)
				fq = _dig_pond(dc, d[0], d[1], d[2], water)
			var fs: Node3D = FishScript.new(fk, fv)
			var fc: Vector3 = fq.c
			var fd := float(fq.deep)
			fs.set("tank_min", fc + Vector3(-float(fq.hw) + 0.1, POND - fd + 0.02, -float(fq.hd) + 0.1))
			fs.set("tank_max", fc + Vector3(float(fq.hw) - 0.1, POND - 0.03, float(fq.hd) - 0.1))
			if water == "trout": # (a stream: its water flowing, the trout holding facing up it)
				fs.set("current", Vector3(0.3, 0.0, 0.0))
			_org(fs, fc, false)
			var n: int = {"chinook": 8 if fv == "ocean" else 4, "rainbow": 5, "bluefin": 10}[fk]
			fs.call("setup", n, fc + Vector3(0.0, POND - fd * 0.5, 0.0), minf(float(fq.hw), float(fq.hd)) * 0.4)
			fs.set_meta("pond", fc)
			return fs
		"mollies":
			var q := _pond_near(at, 0.2)
			if q.is_empty():
				q = _dig_pond(at, PONDS.fishing[0], PONDS.fishing[1], PONDS.fishing[2], "fishing")
			if is_instance_valid(q.mollies):
				return q.mollies
			var mol := MolliesScript.new()
			var c0: Vector3 = q.c
			var dp := float(q.deep)
			mol.tank_min = c0 + Vector3(-float(q.hw) + 0.03, POND - dp + 0.01, -float(q.hd) + 0.03)
			mol.tank_max = c0 + Vector3(float(q.hw) - 0.03, POND - 0.02, float(q.hd) - 0.03)
			_org(mol, c0, false)
			mol.setup(14, c0 + Vector3(0.0, POND - minf(0.12, dp * 0.5), 0.0), 0.08)
			q.mollies = mol
			return mol
		"frog", "toad":
			var q := _pond_for(at, "small_pond")
			var fr: Node3D = (FrogScript if key == "frog" else ToadScript).new(young)
			fr.set("male", male and not young)
			_water_set(fr, q)
			fr.set("height", func(_x: float, _z: float) -> float: return 0.0)
			_org(fr, at, false)
			if young: # (a tadpole, in the water)
				fr.call("place", (q.c as Vector3) + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.15, 0.15)), randf() * TAU)
			else:
				var bank := _bank_of(q, at)
				fr.call("place", bank, randf() * TAU)
				fr.call("wander", bank, 0.12)
			return fr
		"box_turtle", "snapper", "sea_turtle", "painted":
			var sc: Script = TurtleScript if key == "box_turtle" else (SnapScript if key == "snapper" else (PaintedScript if key == "painted" else SeaScript))
			var q := _pond_for(at, "puddle" if key == "box_turtle" else ("pond" if key == "snapper" or key == "painted" else "sea"))
			var t: Node3D = sc.new(young)
			t.set("male", male and not young)
			_water_set(t, q)
			t.set("height", func(_x: float, _z: float) -> float: return 0.0)
			var bank: Vector3 = q.get("bank", _bank_of(q, at) + (_bank_of(q, at) - (q.c as Vector3)).normalized() * 0.4)
			t.set("bank", bank)
			if key == "box_turtle":
				t.set("basks", [at + Vector3(0.4, 0.0, -0.3), at + Vector3(0.3, 0.0, 0.4)])
			if key == "painted": # (a log to bask on, from the bank down into the water)
				t.set("basks", _basking_log(q, at))
			_org(t, at, false)
			t.call("place", _bank_of(q, at) if key != "sea_turtle" or not young else bank, randf() * TAU)
			t.call("wander", q.c, 0.6 if key != "sea_turtle" else 1.5)
			return t
		"anole":
			var an := AnoleScript.new(young) if young else AnoleScript.new()
			an.male = male and not young
			_org(an, at, true)
			an.place(at, randf() * TAU)
			an.wander(at, 0.2)
			return an
		"rattler", "milk":
			var sn := SnakeScript.new(key, young)
			sn.male = male and not young
			_org(sn, at, false)
			sn.place(at, Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU))
			sn.wander(at, 0.3 if young else 0.6)
			return sn
		"mouse":
			var mo := MouseScript.new(young)
			mo.male = male and not young
			_sinks(mo)
			_org(mo, at, true)
			mo.place(at, randf() * TAU)
			if young:
				mo.grow(0.3, 120.0)
			mo.wander(at, 0.25)
			return mo
		"hare":
			var h := HareScript.new(young)
			h.male = male and not young
			_sinks(h)
			_org(h, at, false)
			h.place(at, randf() * TAU)
			h.wander(at, 0.6)
			return h
		"fox_squirrel", "grey_squirrel":
			var q: Node3D = (SquirrelScript if key == "fox_squirrel" else GreySqScript).new()
			q.set("male", male)
			_sinks(q)
			_org(q, at, false)
			var tree: Node3D = _plant_near(at, ["g_oak"], 4.0, Vector3(0.6, 0.0, -0.6))
			_drey_in(tree)
			q.set("tree_at", tree.position)
			q.set("tree_r", OakTree.trunk_radius_at(int((tree.get_meta("game_tree") as Array)[1]), 1.0))
			q.set("drey", tree.position + (tree.get_meta("drey") as Vector3)) # (its home: to sleep in; a female's to bear her kits in)
			q.call("place", at, randf() * TAU)
			q.call("wander", at, 0.8)
			return q
		"beaver":
			var q := _pond_for(at, "beaver")
			var bv: Node3D = BeaverScript.new(young)
			bv.set("male", male and not young)
			bv.set("wet", func(x: float, z: float) -> bool: return _in_pond(q, x, z))
			bv.set("water_y", POND)
			bv.set("height", _height)
			var lodge: Node3D = q.get("lodge")
			if not is_instance_valid(lodge):
				lodge = BeaverScript.lodge_of()
				lodge.position = (q.c as Vector3) + Vector3(float(q.hw) * 0.4, -float(q.deep), -float(q.hd) * 0.4)
				lodge.scale = Vector3.ONE * 0.8
				add_child(lodge)
				(q.nodes as Array).append(lodge)
				q["lodge"] = lodge
			bv.set("lodge", lodge)
			_org(bv, at, false)
			var bank := _bank_of(q, at)
			bv.call("place", bank, randf() * TAU)
			bv.call("wander", bank, 0.7)
			return bv
		"opossum":
			var op: Node3D = OpossumScript.new(young)
			op.set("male", male and not young)
			_org(op, at, false)
			op.call("place", at, randf() * TAU)
			if young:
				op.set("size", 0.13)
			op.call("wander", at, 0.7)
			return op
		"fox", "bobcat", "coyote", "wolf":
			var sc: Script = {"fox": FoxScript, "bobcat": BobcatScript, "coyote": CoyoteScript, "wolf": WolfScript}[key]
			var hn: Node3D = sc.new(young)
			hn.set("male", male and not young)
			_org(hn, at, false)
			hn.call("place", at, randf() * TAU)
			if young:
				hn.call("grow", 0.25, 1.0) # (a cub up and about)
			hn.call("wander", at, 1.0)
			return hn
		"black_bear", "brown_bear":
			var phases := ["black", "black", "cinnamon"] if key == "black_bear" else ["brown", "grizzled", "blond"]
			var br: Node3D = (BlackBearScript if key == "black_bear" else BrownBearScript).new(young, phases[randi() % 3])
			br.set("male", male and not young)
			_org(br, at, false)
			br.call("place", at, randf() * TAU)
			if young:
				br.call("grow", 0.25, 1.0)
			br.call("forage", at, 2.5)
			return br
		"deer", "deer_winter":
			var season := "winter" if key == "deer_winter" else "summer"
			var d: Node3D = DeerScript.new(young, season)
			d.set("male", male and not young)
			_org(d, at, false)
			d.call("place", at, randf() * TAU)
			if not _adopt(d, young):
				d.call("graze", at, 1.5)
			return d
		"moose":
			var q := _pond_for(at + Vector3(2.0, 0.0, 0.0), "large_pond")
			var mo: Node3D = MooseScript.new(young)
			mo.set("male", male and not young)
			mo.set("wet", func(x: float, z: float) -> bool: return _in_pond(q, x, z))
			mo.set("water_y", POND)
			mo.set("height", _height)
			_org(mo, at, false)
			mo.call("place", at, randf() * TAU)
			if not _adopt(mo, young):
				mo.call("graze", at, 0.8)
			return mo
		"bison":
			var bs: Node3D = BisonScript.new(young)
			bs.set("male", male and not young)
			_org(bs, at, false)
			bs.call("place", at, randf() * TAU)
			if not _adopt(bs, young):
				bs.call("graze", at, 2.0)
			return bs
	return c


## A creature put down: its home there; small ones get a clearing in the
## grass, to see them.
func _org(n: Node, at: Vector3, small: bool) -> Node:
	add_child(n)
	n.set_meta("home", at)
	if small:
		_clear_grass(at, 0.3)
	return n


## (A land animal: the ground as it is here, ponds and all, and their
## water, which it sinks in: Hexapod.sink_water.)
func _sinks(n: Node) -> void:
	n.set("height", _height)
	n.set("sink_water", POND)


## (A water creature's pond: its water, its floor, its reeds.)
func _water_set(n: Node, q: Dictionary) -> void:
	n.set("water_y", POND)
	n.set("floor_y", -float(q.deep) + 0.01)
	n.set("pond", [q.c, Vector2(q.hw, q.hd)])
	n.set("stems", q.stems)


## (The point on a pond's bank nearest p, a little out from its edge.)
func _bank_of(q: Dictionary, p: Vector3) -> Vector3:
	var c: Vector3 = q.c
	var d := Vector3(p.x - c.x, 0.0, p.z - c.z)
	if d.length() < 0.01:
		d = Vector3.RIGHT
	var hw := float(q.hw) + 0.15
	var hd := float(q.hd) + 0.15
	var k := minf(hw / maxf(absf(d.x), 1e-4), hd / maxf(absf(d.z), 1e-4))
	return c + d * k


## A young one by its mother (the nearest grown female of its kind, close
## by): following her. Whether there was one.
func _adopt(y: Node3D, young: bool) -> bool:
	if not young:
		return false
	var mom: Node3D = null
	for o in get_children():
		if o != y and o.get_script() == y.get_script() and not _flag(o, "young") and not _flag(o, "male") and not _flag(o, "dead"):
			if (o as Node3D).position.distance_to(y.position) < 4.0 and (mom == null or (o as Node3D).position.distance_to(y.position) < mom.position.distance_to(y.position)):
				mom = o
	if mom == null:
		if y.has_method("graze"):
			y.call("graze", _where(y), 1.0)
		return true
	y.set("_mother", mom)
	y.set("_mode", "follow")
	(mom.get("young_ones") as Array).append(y)
	return true


# --- kits: what's put down for a creature, kept with it ---------------------------

## n's kit thing called name: made (make: a Callable giving a Node3D, placed)
## the first time it's asked for, added to the scene and kept with n (gone
## with it).
func _kit(n: Node, name: String, make: Callable) -> Node3D:
	var kit: Dictionary = n.get_meta("kit", {})
	if kit.has(name) and is_instance_valid(kit[name]):
		return kit[name]
	var t: Node3D = make.call()
	if t.get_parent() == null:
		add_child(t)
	t.set_meta("prop", true)
	kit[name] = t
	n.set_meta("kit", kit)
	return t


func _kit_add(n: Node, t: Node3D) -> Node3D:
	if t.get_parent() == null:
		add_child(t)
	t.set_meta("prop", true)
	var kit: Dictionary = n.get_meta("kit", {})
	var extra: Array = kit.get("_extra", [])
	extra.append(t)
	kit["_extra"] = extra
	n.set_meta("kit", kit)
	return t


func _kit_box(n: Node, at: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	return _kit_add(n, _box_at(at, size, col)) as MeshInstance3D


## Her den (a female hunter's, a bear's, an opossum's): its kind's, put
## down by her the first time she needs it (to give birth, to bed down in,
## to carry leaves to).
func _den_of(n: Node3D, at: Vector3) -> Node3D:
	return _kit(n, "den", func() -> Node3D:
		var d: Node3D
		var sc: Script = n.get_script()
		if sc == BobcatScript:
			d = BobcatScript.den()
		elif sc == OpossumScript:
			d = OpossumScript.den()
			d.rotation.y = randf() * TAU
		elif sc == BlackBearScript or sc == BrownBearScript:
			d = UrsidScript.den(1.0 if sc == BlackBearScript else 1.3)
		else:
			d = CanidScript.den(1.0 if sc == FoxScript else (1.3 if sc == CoyoteScript else 1.7))
		d.position = at + Vector3(-0.9, 0.0, -0.8) * (1.0 if sc != BlackBearScript and sc != BrownBearScript else 2.2)
		n.set("home_den", d)
		return d)


## A wasp comb near p (one that's there, or a new one at p).
func _comb_near(p: Vector3) -> Node3D:
	for n in get_children():
		if n.has_meta("comb_cells") and (n as Node3D).position.distance_to(p) < 1.0:
			return n
	var made := Wasp.comb()
	var comb: Node3D = made[0]
	comb.position = p
	add_child(comb)
	comb.set_meta("prop", true)
	comb.set_meta("comb_cells", (made[1] as Array).map(func(m: Vector3) -> Vector3: return p + m))
	_clear_grass(p, 0.3)
	return comb


## The comb's cells with nothing in them yet (no egg, no grub), the middle
## first.
func _empty_cells(comb: Node3D) -> Array:
	var out := []
	for cell: Vector3 in comb.get_meta("comb_cells", []):
		var full := false
		for n in get_children():
			if not (n is Node3D) or n.get_script() == null or n is Wasp:
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


## Where a chrysalis hangs or is girdled, on the nearest of the game's trees
## (a sapling planted by p if there's none): [the trunk's foot, on the side
## toward its lowest branch; up the trunk below that branch; under the
## branch a little way out; further out under it; the way out along it
## (level)], world. (A monarch's hangs under the branch; a swallowtail's is
## girdled to the trunk: Pupa.)
func _twig_near(p: Vector3) -> Array:
	var tree := _tree_near(p, 6.0)
	if tree == null:
		tree = _plant_game("maple", p + Vector3(0.45, 0.0, -0.3), true)
	var an := _web_anchors(tree, 0)
	if an.is_empty():
		tree = _plant_game("maple", p + Vector3(-0.45, 0.0, 0.35), true)
		an = _web_anchors(tree, 0)
	var pts: Array = an[0]
	var under: Vector3 = pts[0]
	var out: Vector3 = pts[1]
	var tr: Vector3 = pts[2]
	var dir := Vector3(under.x - tr.x, 0.0, under.z - tr.z)
	dir = dir.normalized() if dir.length() > 1e-3 else Vector3.RIGHT
	return [Vector3(tr.x, 0.0, tr.z), tr, under, out, dir]

## A stem by a clearwing's pupa, to climb out of the litter and hang from:
## [its point, the way it faces].
func _moth_perch(at: Vector3, turn: float) -> Array:
	var fwd := Vector3.FORWARD.rotated(Vector3.UP, turn)
	var stem := at + fwd * 0.05
	var b := _box_at(Vector3(stem.x, 0.08, stem.z), Vector3(0.004, 0.16, 0.004), Color(0.38, 0.33, 0.2))
	b.set_meta("prop", true)
	for k in 9: # (the litter it lies in)
		var leaf := Beetles.leaf()
		leaf.position = at + Vector3(randf_range(-0.07, 0.07), 0.0002 * k, randf_range(-0.07, 0.07))
		leaf.rotation.y = randf() * TAU
		leaf.scale = Vector3(0.6, 1.0, 0.6)
		(leaf.get_child(0) as MeshInstance3D).material_override = _plain(Color(0.42, 0.3, 0.16).lerp(Color(0.3, 0.22, 0.12), randf()))
		add_child(leaf)
		leaf.set_meta("prop", true)
	_clear_grass(at, 0.25)
	return [Vector3(stem.x, 0.075, stem.z) - fwd * 0.002, -fwd]


## Leaves on stalks round p (a moth's, a trigonalid's to lay on): [top, up]
## each.
func _leaves_round(n: Node, p: Vector3) -> Array:
	var kit: Dictionary = n.get_meta("kit", {})
	if kit.has("leaves"):
		return kit.leaves
	var out := []
	for s: Vector3 in [Vector3(0.15, 0.14, 0.05), Vector3(0.05, 0.2, 0.18), Vector3(-0.12, 0.1, 0.16)]:
		var at := p + s
		var leaf := Beetles.leaf()
		leaf.position = at
		leaf.scale = Vector3(0.7, 1.0, 0.7)
		_kit_add(n, leaf)
		_kit_box(n, at - Vector3(0.0, at.y * 0.5, 0.0), Vector3(0.004, at.y, 0.004), Color(0.3, 0.42, 0.18))
		out.append([at + Vector3(0.0, 0.002, 0.0), Vector3.UP])
	kit["leaves"] = out
	n.set_meta("kit", kit)
	return out


## The garden spider's moorings at p: a trunk and a branch over the ground,
## stems and a post round below: solid, for its orb.
## The garden spider's web, in the nearest tree (or a maple sapling put down
## by it, if there's none near): hung under its lowest branch, moored to the
## trunk below the branch and to the branch out along it (and to the next
## lowest branch, if that's by it); the web in the upright plane of trunk and
## branch, its frame through those points (no posts: the tree's own wood).
func _spin_orb(sp: Node, k: int) -> void:
	if not is_instance_valid(sp):
		return
	var at := _where(sp)
	var tree := _tree_near(at, 6.0)
	if tree == null:
		tree = _plant_game("maple", at + Vector3(0.45, 0.0, 0.3), true)
	var anchors := _web_anchors(tree, k)
	if anchors.size() < 2:
		return
	if not sp.call("spin_orb_at", anchors[0], anchors[1]):
		sp.call("wander", at, 0.1)


## The nearest of the game's trees and saplings within r of p (planted here).
func _tree_near(p: Vector3, r: float) -> Node3D:
	var best: Node3D = null
	var bd := r
	for n in _plants:
		if is_instance_valid(n) and (n as Node).has_meta("game_tree"):
			var gt: Array = (n as Node).get_meta("game_tree")
			if String(gt[0]) in ["blueberry", "raspberry", "prickly_pear", "joshua_tree", "san_pedro"]:
				continue
			var d := Vector2((n as Node3D).position.x - p.x, (n as Node3D).position.z - p.z).length()
			if d < bd:
				bd = d
				best = n
	return best


## [anchor points (world), the web's normal] for an orb web under tree's
## lowest branch (k: which of the lowest few, and how far out); [] if it
## has no branch low enough.
func _web_anchors(tree: Node3D, k: int) -> Array:
	var gt: Array = tree.get_meta("game_tree")
	var sc: Script = _game_trees()[gt[0]][1]
	var tb: TreeBuilder = sc.call("grow", gt[1]) if gt[0] == "oak" else (sc.call("species") as Object).call("grow", gt[1])
	if tb == null:
		return []
	# its branches off the trunk (level 1), lowest first
	var low: Array = [] # [height of its base, branch index]
	for bi in tb.branches.size():
		var b: PackedInt32Array = tb.branches[bi]
		if b.size() < 3 or tb.level[b[1]] != 1:
			continue
		low.append([tb.pos[b[0]].y, bi])
	if low.is_empty():
		return []
	low.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var pick: Array = low[mini(posmod(k, 2), low.size() - 1)]
	var br: PackedInt32Array = tb.branches[int(pick[1])]
	var base := tb.pos[br[0]]
	var rad := func(i: int) -> float: return tb.radius[i] if i < tb.radius.size() else 0.03
	# along the branch: points a third and two thirds of the way to 0.6 m out
	var along := func(dist: float) -> Vector3:
		var acc := 0.0
		for j in range(1, br.size()):
			var a := tb.pos[br[j - 1]]
			var c := tb.pos[br[j]]
			var l := a.distance_to(c)
			if acc + l >= dist:
				return a.lerp(c, (dist - acc) / maxf(l, 1e-4))
			acc += l
		return tb.pos[br[br.size() - 1]]
	var b1: Vector3 = along.call(0.22)
	var b2: Vector3 = along.call(0.55)
	var dir := Vector3(b2.x - base.x, 0.0, b2.z - base.z)
	dir = dir.normalized() if dir.length() > 1e-3 else Vector3.RIGHT
	var normal := dir.cross(Vector3.UP).normalized()
	# the trunk below it, on its side toward the branch (its bark's)
	var tr: Vector3 = base - Vector3.UP * minf(0.45, base.y * 0.7)
	var trunk_r: float = sc.call("trunk_radius_at", gt[1], tr.y)
	tr += dir * trunk_r
	var pts := [b1 - Vector3.UP * float(rad.call(br[1])) * 0.8, b2 - Vector3.UP * float(rad.call(br[mini(3, br.size() - 1)])) * 0.8, tr]
	# the next lowest branch, if it's near this one's plane, just below or above
	if low.size() > 1:
		var other: PackedInt32Array = tb.branches[int((low[1] if pick == low[0] else low[0])[1])]
		var o := tb.pos[other[mini(3, other.size() - 1)]]
		if absf((o - base).dot(normal)) < 0.15 and absf(o.y - base.y) < 0.6:
			pts.append(o)
	var out: Array = []
	for q: Vector3 in pts:
		out.append(tree.global_transform * q)
	return [out, normal]


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
	return body


# --- food: what's here, or set out ---------------------------------------------

## Prey for an insect eater, a real one: a differential grasshopper nymph
## (sz: 0.3 just hatched .. 1 grown) set down at `at`, feeding there; stuck
## (in a web, fallen on the water): caught there already.
func _insect_at(at: Vector3, sz := 0.4, stuck := false) -> Node3D:
	var g: Node3D = HopperScript.new(true, sz)
	add_child(g)
	g.call("place", at, randf() * TAU)
	if stuck:
		MealScript.subdue(g)
	else:
		g.call("feed", at)
	return g


## A deer mouse for a snake: grown, nibbling a seed at `at`; or a pup.
func _mouse_at(at: Vector3, pup: bool) -> Node3D:
	var m: Node3D = MouseScript.new(pup)
	add_child(m)
	m.call("place", at, randf() * TAU)
	if pup:
		m.call("wander", at, 0.03)
	else:
		var sd := MouseScript.sunflower_seed()
		sd.position = at
		add_child(sd)
		sd.set_meta("prop", true)
		m.call("eat", sd)
	return m


## What kind of prey n is, as the diets say it (or "").
func _kind_of(n: Node) -> String:
	if not is_instance_valid(n) or _flag(n, "dead"):
		return ""
	var sc: Script = n.get_script()
	var young := _flag(n, "young")
	match sc:
		MouseScript:
			return "mouse_pup" if young else "mouse"
		SquirrelScript, GreySqScript:
			return "squirrel"
		HareScript:
			return "leveret" if young else "hare"
		DeerScript:
			return "fawn" if young else "deer"
		MooseScript:
			return "moose_calf" if young else ""
		BisonScript:
			return "bison_calf" if young else ""
		BeaverScript:
			return "beaver_kit" if young else "beaver"
		FoxScript:
			return "fox_kit" if young else "fox"
		CoyoteScript:
			return "" if young else "coyote"
		BobcatScript:
			return "bobcat_kit" if young else ""
		BlackBearScript:
			return "black_cub" if young else ""
		WolfScript:
			return "wolf_pup" if young else ""
		LarvaScript:
			var k: String = n.get("kind")
			return "grub" if k == "june" else ("caterpillar" if k in ["monarch", "hemaris"] else "")
		HopperScript, BlueHopperScript:
			return "nymph" if _flag(n, "nymph") else "grasshopper"
		IsopodScript:
			return "pillbug"
		MantisScript:
			return "mantis_nymph" if _flag(n, "nymph") else ""
		FrogScript:
			return "frog" if float(n.get("dev")) >= 1.0 or not young else ""
		ToadScript:
			return "toad" if float(n.get("dev")) >= 1.0 or not young else ""
		AnoleScript:
			return "anole"
		SnakeScript:
			return "snake_young" if young else "snake"
	return ""


## Prey of one of kinds for hunter c: the nearest that's here (within r),
## or one set out for it (at d m off), a real one.
func _prey(c: Node, kinds: Array, d := 1.8, r := 8.0) -> Node3D:
	var p := _where(c)
	var best := _prey_here(c, kinds, r)
	if best == null:
		var a := randf() * TAU
		best = _real_prey(kinds[randi() % kinds.size()], p + Vector3(cos(a), 0.0, sin(a)) * d)
	best.set_meta("hunted", c)
	return best


## The nearest prey of one of kinds for c that's here, within r (or null).
func _prey_here(c: Node, kinds: Array, r: float) -> Node3D:
	var p := _where(c)
	var best: Node3D = null
	for o in get_children():
		if o == c or not (o is Node3D):
			continue
		var k := _kind_of(o)
		if k == "" or not kinds.has(k):
			continue
		if o.has_meta("hunted") and is_instance_valid(o.get_meta("hunted")) and o.get_meta("hunted") != c:
			continue
		var q := _where(o)
		if q.distance_to(p) <= r and (best == null or q.distance_to(p) < _where(best).distance_to(p)):
			best = o
	if best:
		best.set_meta("hunted", c)
	return best


## One of the animals living here, made for a meal, at `at`, going about
## its own ways there (a grub curled, a dead mouse on its back).
func _real_prey(kind: String, at: Vector3) -> Node3D:
	at.y = 0.0
	var n: Node3D
	match kind:
		"fawn":
			n = DeerScript.new(true, "summer")
		"deer":
			n = DeerScript.new(false, "summer")
		"moose_calf":
			n = MooseScript.new(true)
		"bison_calf":
			n = BisonScript.new(true)
		"beaver":
			n = BeaverScript.new()
		"beaver_kit":
			n = BeaverScript.new(true)
		"fox":
			n = FoxScript.new()
		"fox_kit":
			n = FoxScript.new(true)
		"coyote":
			n = CoyoteScript.new()
		"bobcat_kit":
			n = BobcatScript.new(true)
		"black_cub":
			n = BlackBearScript.new(true)
		"wolf_pup":
			n = WolfScript.new(true)
		"squirrel":
			n = GreySqScript.new()
		"hare":
			n = HareScript.new()
		"leveret":
			n = HareScript.new(true)
		"mouse", "mouse_pup", "dead_mouse":
			n = MouseScript.new(kind == "mouse_pup")
		"grub":
			n = LarvaScript.new("june")
		"caterpillar":
			n = LarvaScript.new("monarch" if randf() < 0.5 else "hemaris")
		"grasshopper":
			n = HopperScript.new(false, 1.0)
		"pillbug":
			n = IsopodScript.new()
		"mantis_nymph":
			n = MantisScript.new(true, 0.4)
		"frog":
			n = FrogScript.new()
		"toad":
			n = ToadScript.new()
		"anole":
			n = AnoleScript.new()
		"snake", "snake_young":
			var sn: Node3D = SnakeScript.new("rattler" if kind == "snake_young" or randf() < 0.5 else "milk", kind == "snake_young")
			add_child(sn)
			sn.call("place", at, Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU))
			sn.call("wander", at, 0.2)
			return sn
		_: # "nymph"
			return _insect_at(at, 0.35)
	add_child(n)
	if n is LarvaScript:
		n.call("place", at, Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)))
		if kind == "caterpillar":
			n.call("eat")
		return n
	n.call("place", at, randf() * TAU)
	match kind:
		"deer":
			n.call("graze", at, 0.6)
		"grasshopper":
			n.call("feed", at)
		"pillbug":
			n.call("eat", at)
		"mantis_nymph":
			n.call("stalk", at, 0.02)
		"frog", "toad":
			n.call("sit")
		"dead_mouse":
			n.call("die")
		_:
			if n.has_method("wander"):
				n.call("wander", at, 0.05 if kind in ["mouse_pup", "leveret"] else 0.3)
	return n


## (An acorn for a mouse near p: one of its kit's, a new one if they're gone.)
func _seed_for(c: Node, p: Vector3) -> Node3D:
	var kit: Dictionary = c.get_meta("kit", {})
	var seeds: Array = kit.get("seeds", [])
	var best: Node3D = null
	for sd in seeds:
		if is_instance_valid(sd) and not sd.has_meta("taken") and (best == null or (sd as Node3D).position.distance_to(p) < best.position.distance_to(p)):
			best = sd
	if best == null:
		best = _laid("acorn", Vector3.ZERO, randf() * TAU) # (the game's)
		remove_child(best)
		var home: Vector3 = c.get_meta("home", p)
		best.position = home + Vector3(randf_range(-0.22, 0.22), 0.0, randf_range(-0.2, 0.2))
		best.rotation.y = randf() * TAU
		_kit_add(c, best)
		seeds.append(best)
		kit["seeds"] = seeds
		c.set_meta("kit", kit)
	best.set_meta("taken", true)
	return best


## (A hare's food near p: the game's forbs, a yampah or a fleabane; high,
## a black-eyed Susan, sat up to: here, or set out. Eaten away.)
func _hare_food(c: Node, p: Vector3, high: bool) -> Node3D:
	var kinds := ["susan"] if high else ["yampah", "fleabane"]
	var near := _plants_near(p, 3.0, kinds).filter(func(n: Node) -> bool: return not n.has_meta("taken"))
	var f: Node
	if not near.is_empty():
		f = near[0]
	else:
		var a := randf() * TAU
		f = spawn(kinds[randi() % kinds.size()], p + Vector3(cos(a), 0.0, sin(a)) * 0.5)
	f.set_meta("taken", true)
	return f


## (A walnut for a squirrel at p: on the ground near, or a new one by it.)
func _nut_for(c: Node, p: Vector3) -> Node3D:
	var kit: Dictionary = c.get_meta("kit", {})
	var nuts: Array = kit.get("nuts", [])
	var best: Node3D = null
	for n in nuts:
		if is_instance_valid(n) and (n as Node3D).visible and (n as Node3D).get_parent() == self and (best == null or (n as Node3D).position.distance_to(p) < best.position.distance_to(p)):
			best = n
	if best == null or best.position.distance_to(p) > 1.2:
		var a := randf() * TAU
		best = _laid("walnut", Vector3.ZERO, randf() * TAU) # (the game's)
		remove_child(best)
		var at := p + Vector3(cos(a), 0.0, sin(a)) * 0.4
		best.position = Vector3(at.x, 0.0, at.z)
		_kit_add(c, best)
		nuts.append(best)
		kit["nuts"] = nuts
		c.set_meta("kit", kit)
	return best


## (Fallen fruit near p, an opossum's: the game's pawpaws, lying under it
## (a few, set out once, nothing taken): their points.)
func _windfall_near(p: Vector3) -> Array:
	for n in get_children():
		if n.has_meta("windfall") and (n as Node3D).position.distance_to(p) < 3.0:
			return n.get_meta("windfall")
	var at := p + Vector3(0.5, 0.0, 0.5)
	var pts: Array = []
	for k in 5:
		var a := randf() * TAU
		var q := at + Vector3(cos(a), 0.0, sin(a)) * randf_range(0.03, 0.18)
		var f := _laid("pawpaw", q, randf() * TAU)
		pts.append(q + Vector3(0.0, 0.03, 0.0))
		if k == 0:
			f.set_meta("windfall", pts)
	return pts


## (A beaver's stick to eat near p (the game's), or one set out for it.)
func _stick_for(c: Node, p: Vector3) -> Node3D:
	for n in get_children():
		if n.has_meta("stick") and (n as Node3D).position.distance_to(p) < 3.0 and (n as Node3D).get_parent() == self:
			return n
	var a := randf() * TAU
	var st := _laid("stick", p + Vector3(cos(a), 0.0, sin(a)) * 0.4, randf() * TAU)
	remove_child(st)
	st.set_meta("stick", true)
	return _kit_add(c, st)


## (A bush to browse near p: a blueberry bush here, or one planted.)
func _bush_near(p: Vector3, offset := Vector3(1.0, 0.0, -0.6)) -> Node3D:
	return _plant_near(p, ["g_blueberry", "g_raspberry"], 4.0, offset) as Node3D


## (A sapling to rub or fell near p: a maple's here, or one planted.)
func _sapling_near(p: Vector3, offset := Vector3(1.2, 0.0, 0.6)) -> Node3D:
	return _plant_near(p, ["s_maple"], 4.0, offset) as Node3D


## A squirrel's drey in the game oak tree (once): in its trunk's first fork,
## against the trunk (its trunk's line, OakTree's climbing one).
func _drey_in(tree: Node3D) -> void:
	if tree.has_meta("drey"):
		return
	var v := int((tree.get_meta("game_tree") as Array)[1])
	var line: PackedFloat32Array = OakTree._climb_lines(v)[0]
	var at := Vector3(line[0], line[1], line[2])
	var r := 0.2
	var want := float(OakTree.VARIANTS[v].get("trunk_h", 3.0)) * 0.9
	for k in range(0, line.size(), 4):
		at = Vector3(line[k], line[k + 1], line[k + 2])
		r = line[k + 3]
		if at.y >= want:
			break
	var d := SquirrelScript.drey_nest()
	var place := at + Vector3(r * 0.9, 0.0, 0.0)
	d.position = place
	tree.add_child(d)
	tree.set_meta("drey", place)


## A school of salmon or trout (not mollies) whose pond is within r of p.
func _fish_school_near(p: Vector3, r: float) -> Node3D:
	var best: Node3D = null
	var bd := r
	for n in get_children():
		if n.get_script() == FishScript and n.has_meta("pond"):
			var d := Vector2((n.get_meta("pond") as Vector3).x - p.x, (n.get_meta("pond") as Vector3).z - p.z).length()
			if d < bd:
				bd = d
				best = n
	return best


## The fishing spider's catch: a molly of its pond's school, up near the
## surface by it; then its rush and its lunge.
func _spider_fish(sp: Node3D) -> void:
	var q := _pond_near(_where(sp), 0.3)
	if q.is_empty():
		return
	if not is_instance_valid(q.mollies):
		spawn("mollies", q.c)
	var mol: Node3D = q.mollies
	var i: int = mol.call("nearest", sp.get("_pos"))
	if i < 0:
		return
	var fish: Node3D = mol.call("take", i)
	var a := randf() * TAU
	var at: Vector3 = (sp.get("_pos") as Vector3) + Vector3(cos(a), 0.0, sin(a)) * 0.14
	at.y = POND - 0.008
	var tw := create_tween()
	tw.tween_property(fish, "position", at, 2.0)
	tw.tween_callback(Callable(sp, "hunt").bind(fish))


## (A spider's prey: on its funnel weaver's sheet, caught in its garden
## spider's orb, fallen on the water by the fishing spider, on the ground
## before the wolf spider.)
func _spider_prey(sp: Node, p: Vector3, near: Vector3, young: bool) -> Node3D:
	var sz := 0.15 if young else 0.35
	var w: Node3D = sp.get("web")
	match sp.get("kind"):
		"funnel":
			if young or not is_instance_valid(w):
				return _insect_at(p + near * 0.04, sz)
			var at := w.position + near * 0.07
			at.y = w.call("surface_y", at.x, at.z)
			return _insect_at(at, sz)
		"argiope":
			if young or not is_instance_valid(w):
				return _insect_at(p + near * 0.04, sz)
			var n: int = w.call("count")
			var f := _insect_at(w.call("point", int(n * randf_range(0.45, 0.85))), sz, true)
			f.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			return f
		"fishing":
			var at := p + near * (0.04 if young else 0.15)
			at.y = POND
			return _insect_at(at, sz, not young)
	return _insect_at(p + near * (0.04 if young else 0.15), sz)


## The caterpillar (a monarch's or a clearwing's, going about, not yet
## stung) nearest p; one put down there if there's none.
func _caterpillar_near(p: Vector3) -> Node3D:
	var best: Node3D = null
	var bd := INF
	for n in get_children():
		if n.get_script() == LarvaScript and String(n.get("kind")) in ["monarch", "hemaris", "swallowtail", "luna"] and not bool(n.get("parasitized")) and String(n.get("_mode")) != "pupate":
			var d := (n.get("_pos") as Vector3).distance_to(p)
			if d < bd:
				bd = d
				best = n
	if best == null:
		best = spawn("monarch", p + Vector3(0.15, 0.0, 0.1), "young", false) as Node3D
	return best


## The darners' prey: trigonalid wasps flying over their pond.
func _midges(q: Dictionary, n: int) -> Array:
	var live: Array = (q.midges as Array).filter(func(m) -> bool: return is_instance_valid(m) and (m as Node).get_parent() == self)
	while live.size() < n:
		var w: Node3D = TrigScript.new()
		add_child(w)
		var a := randf() * TAU
		w.call("place", (q.c as Vector3) + Vector3(cos(a) * 0.4, randf_range(0.2, 0.6), sin(a) * 0.4))
		w.call("seek_food", q.c, 0.6)
		live.append(w)
	q.midges = live
	return live


# --- the keys ------------------------------------------------------------------

## What the keys act on: the selection, or (none selected) everything.
func _targets() -> Array:
	_selected = _selected.filter(func(n) -> bool: return is_instance_valid(n))
	if not _selected.is_empty():
		return _selected.duplicate()
	return _creatures()


## Every creature here (its eggs, its young, its colonies too).
func _creatures() -> Array:
	var out := []
	for c in get_children():
		if c.get_script() == null or not (c is Node3D) or c.has_meta("prop") or c.has_meta("plant"):
			continue
		if c is Camera3D or c is DirectionalLight3D or c is WorldEnvironment:
			continue
		out.append(c)
	return out


func act(what: String) -> void:
	var all := _targets()
	match what:
		"pupae":
			_pupate(all)
			return
		"mate":
			_mate(all)
			return
	for c in all:
		if is_instance_valid(c):
			_do(c, what)


## Each male of all with the nearest grown female of his kind (of all, or
## any here).
func _mate(all: Array) -> void:
	for c in all:
		if not is_instance_valid(c):
			continue
		if c is Beetles:
			(c as Beetles).mate(1, 0)
			continue
		if not _flag(c, "male") or _young(c) or not c.has_method("mate"):
			continue
		var best: Node = null
		for pool: Array in [all, _creatures()]:
			for o in pool:
				if o != c and is_instance_valid(o) and o.get_script() == c.get_script() and not _flag(o, "male") and not _young(o) and not _flag(o, "dead") and (o.get_script() != BeeScript or _flag(o, "queen")):
					if best == null or _where(o).distance_to(_where(c)) < _where(best).distance_to(_where(c)):
						best = o
			if best:
				break
		if best:
			c.call("mate", best)


## Each grown caterpillar (and grub, and larva) of all pupating: the
## monarch's to the nearest tree (down its milkweed if it's up on a leaf,
## over to the trunk, up it and out under its lowest branch, to hang and
## shed its skin); the swallowtail's up a tree's trunk, girdled there; the
## clearwing's and the luna's into the litter by a stem; the lady beetle larva
## glued down a little way on; the grubs where they lie, each pupa's adult
## to its colony.
func _pupate(all: Array) -> void:
	for c in all:
		if not is_instance_valid(c) or c.get_script() != LarvaScript or c.get("_mode") == "pupate":
			continue
		var kind: String = c.get("kind")
		var p: Vector3 = c.get("_pos")
		if kind in ["lady", "june", "wasp", "carpenter", "harvester"]:
			var d: Vector3 = c.get("_dir")
			var at := p + d * 0.015 if kind == "lady" else (p + Vector3.UP * 0.012 if kind == "wasp" else p)
			var col: Node = null
			if kind in ["lady", "june"]:
				col = _colony_near(kind, p)
			elif kind in ["carpenter", "harvester"]:
				col = _workers(kind, p)
			c.call("pupate", at, [], func(pu: Node3D) -> void: pu.set("colony", col))
		elif kind == "monarch": # (to a tree, up its trunk, out under its lowest branch, to hang there)
			var tw := _twig_near(p)
			var y: Vector3 = tw[4]
			var via := []
			if p.y > 0.02: # (down the milkweed's stem)
				via.append([Vector3(p.x, 0.0, p.z), Vector3.BACK])
			via.append([tw[0], Vector3.UP]) # (to the trunk's foot)
			via.append([tw[1], y]) # (up it)
			via.append([(tw[2] as Vector3) - y * 0.03, Vector3.DOWN]) # (onto the branch's underside)
			var at: Vector3 = (tw[2] as Vector3).lerp(tw[3], 0.25 * float(_hung % 3))
			_hung += 1
			c.call("pupate", at, via)
		elif kind == "swallowtail": # (to a tree, up its trunk a way, and girdled there)
			var tw := _twig_near(p)
			var y: Vector3 = tw[4]
			var via := []
			if p.y > 0.02:
				via.append([Vector3(p.x, 0.0, p.z), Vector3.BACK])
			via.append([tw[0], Vector3.UP])
			var at: Vector3 = (tw[1] as Vector3) - Vector3.UP * (0.08 + 0.06 * float(_hung % 3))
			_hung += 1
			c.call("pupate", at, via + [[at, y]])
		elif kind in ["hemaris", "luna"]: # (in the litter, on the ground)
			var turn := randf() * TAU
			var at := p + Vector3(0.05, 0.0, 0.05)
			var perch := _moth_perch(at, turn)
			c.call("pupate", at, [], func(pu: Node3D) -> void:
				pu.set("perch_at", perch[0])
				pu.set("perch_normal", perch[1]))


var _hung := 0


## The lady beetles' or June bugs' colony nearest p (a new one, if none).
func _colony_near(kind: String, p: Vector3) -> Node:
	var sc: Script = LadyScript if kind == "lady" else JuneScript
	var best: Node3D = null
	for n in get_children():
		if n.get_script() == sc and (best == null or (n as Node3D).position.distance_to(p) < best.position.distance_to(p)):
			best = n
	if best:
		return best
	var bc: Beetles = sc.new()
	bc.position = Vector3(p.x, 0.0, p.z)
	add_child(bc)
	bc.setup(0, Vector3.ZERO, 0.05)
	return bc


## The ants' workers of kind (a colony for each kind, made the first time
## one's out of its pupa, by the queen of its kind if there's one).
func _workers(kind: String, p: Vector3) -> Node:
	if _worker_colonies.has(kind) and is_instance_valid(_worker_colonies[kind]):
		return _worker_colonies[kind]
	var at := Vector3(p.x, 0.0, p.z)
	for n in get_children():
		if n.get_meta("ant", "") == kind:
			at = (n as Node3D).position
			break
	var w: AntColony = HarvesterScript.new() if kind == "harvester" else AntColony.new()
	w.position = at
	add_child(w)
	w.setup(0, Vector3.ZERO, 0.08)
	_worker_colonies[kind] = w
	return w


func _do(c: Node, act_: String) -> void:
	var sc: Script = c.get_script()
	var p := _where(c)
	var young := _young(c)
	var st: Vector3 = c.get_meta("home", Vector3(p.x, 0.0, p.z))
	var a := randf() * TAU
	var near := Vector3(cos(a), 0.0, sin(a))
	if c.has_meta("carcass"): # (a carcass: 2 takes it a stage further on; nothing else)
		if act_ == "hatch":
			CarcassScript.set_stage(c as Node3D, int(c.get_meta("carcass")) % 3 + 1)
		return
	if c is CrayScript: # (its own: in its pond)
		_crayfish_do(c, act_, young, p)
		return
	# a mushroom: R, or E with one it eats grown or laid by it
	if act_ == "mushroom" or (act_ == "eat" and _fungus_near(p, MUSHROOM_EATERS.get(sc, []), 1.5) != null):
		_mushroom_meal(c, young, p, near)
		return
	if act_ == "hatch":
		if sc == PupaScript:
			c.call("eclose", func(ad: Node3D) -> void:
				if ad is AntColony or ad is Wasp:
					return
				var at := _where(ad)
				if ad.has_method("fly"):
					ad.call("fly", at, 0.4)
				else:
					ad.call("search", at, 0.4, _flat(_clumps_near(at))))
		elif c.has_method("hatch") and not (c is AntColony):
			c.call("hatch")
		elif sc == SnakeScript or sc == AnoleScript: # (shedding its skin)
			c.call("shed")
		elif sc == SpiderScript:
			for sac in c.get("sacs"):
				if is_instance_valid(sac):
					sac.call("hatch")
		elif (sc == HopperScript or sc == BlueHopperScript or sc == MantisScript) and young:
			MoltScript.begin(c, func(ad: Node3D) -> void:
				if ad.has_method("stalk"):
					ad.call("stalk", _where(ad), 0.15)
				elif ad.has_method("wander"):
					ad.call("wander", _where(ad), 0.15))
		elif sc == HopperScript or sc == BlueHopperScript or sc == MantisScript:
			for pod in c.get("pods" if sc != MantisScript else "oothecae"):
				if is_instance_valid(pod):
					pod.call("hatch")
		elif c is AntColony and c.has_meta("ant"):
			var kit: Dictionary = c.get_meta("kit", {})
			for e in kit.get("eggs", []):
				if is_instance_valid(e):
					e.call("hatch")
		elif c.get("eggs") is Array:
			for e in c.get("eggs"):
				if is_instance_valid(e):
					e.call("hatch")
		return
	# (each its own kind's ways)
	if sc == DragonflyScript:
		_dragonfly_do(c, act_, young, p)
		return
	if sc == FrogScript or sc == ToadScript:
		_frog_do(c, act_, young, p)
		return
	if sc == TurtleScript or sc == SnapScript or sc == SeaScript or sc == PaintedScript:
		_turtle_do(c, act_, young, p)
		return
	if c is Beetles or c is AntColony:
		var col := c as AntColony
		var n := col.pos.size()
		if act_ == "lay" and c.has_meta("ant"): # (the queen's eggs: a pile by her)
			var kit: Dictionary = c.get_meta("kit", {})
			var eggs: Array = kit.get("eggs", [])
			for j in 10:
				var e := BroodScript.egg(c.get_meta("ant"))
				e.position = (c as Node3D).position + Vector3(-0.05 + randf_range(-0.01, 0.01), 0.0, 0.05 + randf_range(-0.01, 0.01))
				e.rotation.y = randf() * TAU
				add_child(e)
				eggs.append(e)
			kit["eggs"] = eggs
			c.set_meta("kit", kit)
			return
		for i in n:
			match act_:
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
	if sc == FishScript: # (E/H: the salmon and trout rise, the tuna feed on bait; X scattered; W/B wandering about their water; F/Z: the trout hold)
		var np: int = (c.get("pos") as PackedVector3Array).size()
		var fc: Vector3 = c.get_meta("pond", p)
		var tmin: Vector3 = c.get("tank_min")
		var tmax: Vector3 = c.get("tank_max")
		match act_:
			"eat", "hunt":
				if String(c.get("kind")) == "bluefin":
					c.call("feed", (tmin + tmax) * 0.5 + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-1.5, 1.5)))
				else:
					for i in np:
						if randf() < 0.5:
							c.call("rise", i)
			"alarm":
				c.call("scatter", (tmin + tmax) * 0.5)
			"fly", "sleep", "sit":
				for i in np:
					c.call("hold", i)
			_:
				for i in np:
					c.call("rejoin", i)
				c.call("swim_to", Vector3(randf_range(tmin.x, tmax.x), lerpf(tmin.y, tmax.y, 0.5), randf_range(tmin.z, tmax.z)))
		return
	if sc == MolliesScript:
		var np: int = (c.get("pos") as PackedVector3Array).size()
		match act_:
			"eat":
				for i in np:
					c.call("graze", i)
			"display":
				for i in np:
					c.call("display", i)
			"wander":
				for i in np:
					c.call("rejoin", i)
			"alarm":
				var q := _pond_near(p, 0.5)
				c.call("scatter", (q.c as Vector3) + Vector3(0.0, POND, 0.0) if not q.is_empty() else p)
		return
	match act_:
		"wander":
			if sc == MonarchScript or sc == SwallowScript or sc == LunaScript:
				c.call("fly", st, 0.4)
			elif sc == MothScript:
				c.call("search", st, 0.4, _flat(_clumps_near(st)))
			elif sc == BeeScript:
				c.call("forage", _heads_near(st), _kit(c, "nest", func() -> Node3D:
					var ns: Node3D = BeeScript.nest()
					ns.position = st + Vector3(0.3, 0.0, 0.3)
					return ns).position)
			elif sc == Wasp or sc == TrigScript or sc == IchScript:
				c.call("seek_food", st, 0.5 if sc == Wasp else 0.35)
			elif sc == MantisScript:
				c.call("stalk", p, 0.15)
			elif sc == BeaverScript:
				if young:
					c.set("_mode", "follow")
				elif c.get("_in_water"):
					c.call("swim", p, 1.0)
				else:
					c.call("wander", st, 0.7)
			elif sc == BisonScript or sc == DeerScript or sc == MooseScript:
				if young and c.get("_mother") != null:
					c.set("_mode", "follow")
				else:
					c.call("graze", p, 3.0 if sc == BisonScript else 2.0)
			elif sc == SpiderScript and c.get("kind") in ["funnel", "argiope"] and not young and not _flag(c, "male"):
				pass # (at its web)
			elif c.has_method("forage") and sc != BeeScript:
				c.call("forage", st, 2.5)
			elif c.has_method("wander"):
				c.call("wander", st, 1.2 if sc == SnakeScript else 0.4)
		"lay":
			if young or _flag(c, "male"):
				return
			if sc == MonarchScript:
				var lv := _milkweed_leaves(st)
				c.call("lay", lv.map(func(l): return l[0]), lv.map(func(l): return l[1]), Callable(c, "fly").bind(st, 0.4))
			elif sc == MothScript:
				var lv := _leaves_round(c, st)
				c.call("lay", lv.map(func(l): return l[0]), lv.map(func(l): return l[1]), Callable(c, "search").bind(st, 0.4, _flat(_clumps_near(st))))
			elif sc == SwallowScript or sc == LunaScript: # (on leaves round it: the swallowtail's a yampah's, if there's one by it)
				var lv := _leaves_round(c, st)
				if sc == SwallowScript:
					var host := _plants_near(st, 1.5, ["yampah"])
					var hl: Array = (host[0] as Node).get_meta("leaves", []) if not host.is_empty() else []
					if not hl.is_empty():
						lv = hl.slice(0, 4).map(func(l: Array) -> Array: return [l[0], l[1]])
				c.call("lay", lv.map(func(l): return l[0]), lv.map(func(l): return l[1]), Callable(c, "fly").bind(st, 0.4))
			elif sc == Wasp:
				var comb: Node3D = c.get_meta("comb") if c.has_meta("comb") else _comb_near(st)
				c.call("lay_eggs", _empty_cells(comb).slice(0, 1), Vector3.UP, 0.0068)
			elif sc == TrigScript:
				var lv := _leaves_round(c, st)
				var lf: Array = lv[randi() % lv.size()]
				c.call("lay_on_leaf", _leaf_edge(lf[0]), Vector3.UP)
			elif sc == IchScript: # (in the nearest caterpillar going about: one put down if none)
				var cat: Node3D = _caterpillar_near(p)
				if cat:
					c.call("lay_in_caterpillar", cat)
			elif sc == HopperScript or sc == BlueHopperScript:
				c.call("lay", st + Vector3(0.05, 0.0, -0.08))
			elif sc == MantisScript:
				var stem: Node3D = _kit(c, "stem", func() -> Node3D: return _box_at(st + Vector3(0.12, 0.1, -0.12), Vector3(0.005, 0.2, 0.005), Color(0.4, 0.34, 0.2)))
				c.call("lay", Vector3(stem.position.x, 0.006, stem.position.z))
			elif sc == SnakeScript:
				c.call("lay", 5 if c.get("kind") == "rattler" else 6)
			elif sc == SpiderScript or sc == IsopodScript:
				c.call("lay")
			elif sc == AnoleScript:
				c.call("lay", st + Vector3(0.08, 0.0, -0.06))
			elif sc == MouseScript:
				c.call("birth", 4, _kit(c, "nest", func() -> Node3D:
					var ns := MouseScript.nest()
					ns.position = st + Vector3(0.15, 0.0, -0.1)
					return ns))
			elif sc == ScorpionScript:
				c.call("birth", 12)
			elif sc == DeerScript or sc == MooseScript:
				c.call("birth", 2 if sc == DeerScript else 1)
			elif sc == HareScript:
				c.call("birth", 4)
			elif sc == SquirrelScript or sc == GreySqScript:
				c.call("birth", 3)
			elif sc == BeaverScript:
				c.call("birth", 3)
			elif sc == OpossumScript:
				c.call("birth", 7, _den_of(c, st))
			elif sc == BisonScript:
				c.call("birth")
			elif c.has_method("birth"): # (the hunters, the bears: in their dens)
				c.call("birth", 4, _den_of(c, st))
		"eat", "hunt":
			_feed(c, act_, young, p, st, near)
		"unusual":
			if not young:
				_unusual(c, p)
		"groom":
			if c.has_method("groom"):
				c.call("groom")
			elif sc == Wasp or sc == BeeScript:
				c.call("land", p * Vector3(1.0, 0.0, 1.0) + near * 0.1)
			elif sc == TrigScript or sc == IchScript:
				var lv := _leaves_round(c, st)
				c.call("land", (lv[randi() % lv.size()] as Array)[0], Vector3.UP)
		"sleep":
			if sc in [OpossumScript, BlackBearScript, BrownBearScript] and not young: # (a bear in its den, out of sight)
				_den_of(c, st)
			if c.has_method("sleep"):
				c.call("sleep", 20.0)
			elif sc == HareScript or sc == SquirrelScript or sc == GreySqScript:
				c.call("freeze", 12.0)
			elif sc == SnakeScript:
				c.call("coil")
			elif sc == IsopodScript:
				c.call("roll", 8.0)
		"fly":
			if sc == BlackBearScript and not young: # (F: up the nearest tree, a black bear's)
				var tree := _tree_near(p, 8.0)
				if tree == null:
					tree = _plant_game("oak", p + Vector3(0.8, 0.0, 0.6), false)
				var gt: Array = tree.get_meta("game_tree")
				var r: float = (_game_trees()[gt[0]][1] as Script).call("trunk_radius_at", gt[1], 0.5)
				c.call("climb", tree.position, r, 1.8)
			elif sc == MonarchScript or sc == SwallowScript or sc == LunaScript:
				c.call("fly", st, 0.6)
			elif sc == MothScript:
				c.call("search", st, 0.5, _flat(_clumps_near(st)))
			elif sc == Wasp or sc == TrigScript or sc == IchScript or sc == BeeScript:
				c.call("seek_food", st, 0.6 if sc == Wasp else 0.4)
			elif sc == OpossumScript and not young: # (up a dead branch)
				var sn: Node = _snag_near(p)
				var s: Array = sn.get_meta("snag")
				c.call("climb", s[0], s[1], s[2])
			elif (sc == SquirrelScript or sc == GreySqScript) and not young:
				c.call("climb", c.get("tree_at"), randf_range(1.8, 3.0))
			elif sc == HopperScript or sc == BlueHopperScript:
				c.call("hop" if young else "fly", p + near * (0.2 if young else 0.35))
			elif sc == MantisScript and not young:
				c.call("fly", p + near * 0.3)
		"alarm":
			if sc == SnakeScript:
				c.call("coil")
			elif sc == LarvaScript and String(c.get("kind")) == "swallowtail": # (its osmeterium out)
				c.call("threat", 3.0)
			elif sc == LarvaScript:
				c.call("flinch", 1.0)
			elif sc == IsopodScript:
				c.call("roll", 5.0)
			elif sc == BeaverScript:
				c.call("slap")
			elif sc == OpossumScript:
				c.call("play_dead", randf_range(14.0, 20.0))
			elif sc == BeeScript or sc == Wasp:
				c.call("sting", p * Vector3(1.0, 0.0, 1.0) + near * 0.1 + Vector3(0.0, 0.02, 0.0))
			elif sc == HareScript or sc == SquirrelScript or sc == GreySqScript:
				c.call("flee", p + near * 0.5)
			elif sc == ScorpionScript and not young:
				c.call("sting", p + near * 0.03)
			elif sc == MouseScript:
				c.call("wander", p, 0.6)
			elif sc == DeerScript or sc == MooseScript:
				c.call("flee", p + near * 3.0)
			elif sc == BisonScript:
				c.call("stampede", p + near * 3.0)
		"display":
			if sc == AnoleScript:
				c.call("display")
			elif sc == OpossumScript:
				c.call("gape", 6.0)
			elif sc == HareScript:
				c.call("thump")
			elif sc == SquirrelScript or sc == GreySqScript:
				c.call("flick")
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
			if sc == BeeScript:
				c.call("home", _kit(c, "nest", func() -> Node3D:
					var ns: Node3D = BeeScript.nest()
					ns.position = st + Vector3(0.3, 0.0, 0.3)
					return ns).position)
			elif sc == OpossumScript and not young: # (leaves for the nest, in its tail, to its den)
				var litter: Node3D = _kit(c, "litter", func() -> Node3D:
					var h := Node3D.new()
					h.position = st + Vector3(-0.35, 0.0, 0.6)
					for k in 14:
						var lf := OpossumScript.leaf(k)
						var b := float(k) * 2.4
						lf.position = Vector3(cos(b), 0.0, sin(b)) * (0.03 + 0.012 * k) + Vector3.UP * 0.002
						h.add_child(lf)
					return h)
				c.call("gather", litter.position + near * 0.08, _den_of(c, st).position)
			elif sc == BeaverScript and not young:
				var q := _pond_near(p, 2.0)
				if not q.is_empty():
					c.call("swim", q.c, 1.0)
			elif (sc == SquirrelScript or sc == GreySqScript) and not young:
				c.call("cache", _nut_for(c, p), p + near * 0.7)
			elif sc == MooseScript and not young:
				var q := _pond_near(p, 6.0)
				if not q.is_empty():
					c.call("wade", (q.c as Vector3) + Vector3(randf_range(-0.6, 0.6) * float(q.hw), 0.0, randf_range(-0.5, 0.5) * float(q.hd)))
			elif sc == DeerScript and not young:
				c.call("browse", _bush_near(p).position, 0.6)
			elif c.has_method("forage"):
				c.call("forage", st, 2.5)
		"spin":
			if sc == SpiderScript and not young:
				var k: String = c.get("kind")
				if k == "funnel" or k == "argiope":
					if is_instance_valid(c.get("web")):
						(c.get("web") as Node).queue_free()
					if k == "funnel":
						c.call("spin_funnel", st, 0.14)
					else:
						_spin_orb(c, randi())
		"mark":
			if sc == DeerScript or sc == MooseScript:
				if _flag(c, "male") and not young:
					c.call("mark", _sapling_near(p).position)
			elif c.has_method("rub"):
				var tree: Node3D = _kit(c, "rub_tree", func() -> Node3D: return _plant_game("maple", st + Vector3(2.4, 0.0, 1.4), false))
				c.call("rub", tree.position * Vector3(1.0, 0.0, 1.0))
			elif c.has_method("mark"):
				c.call("mark")
		"sit":
			if sc == BisonScript:
				c.call("ruminate", 12.0)
			elif c.has_method("sit"):
				c.call("sit", 8.0)
			elif sc == HareScript or sc == SquirrelScript or sc == GreySqScript:
				c.call("alert")
			elif sc == MouseScript:
				c.call("groom")


## (A darner, adult or nymph.)
func _dragonfly_do(c: Node, act_: String, young: bool, p: Vector3) -> void:
	var q := _pond_near(p, 2.0)
	if q.is_empty():
		q = _pond_for(p, "darner")
	var centre: Vector3 = q.c
	match act_:
		"eat", "hunt":
			if young:
				var a := randf() * TAU
				c.call("strike", p + Vector3(cos(a), 0.0, sin(a)) * 0.02)
			else:
				var live := _midges(q, 3)
				live.sort_custom(func(m1, m2) -> bool: return (m1 as Node3D).position.distance_to(p) < (m2 as Node3D).position.distance_to(p))
				c.call("hunt", live[0])
		"lay":
			if not young and not _flag(c, "male"):
				c.call("lay")
		"fly":
			if young:
				c.call("emerge")
			else:
				c.call("patrol", centre, 0.9)
		"sleep", "sit":
			if not young:
				c.call("perch")
		"alarm":
			c.call("flee", centre + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)))
		"wander":
			if young:
				c.call("crawl", centre, 0.35)
			else:
				c.call("patrol", centre, 0.9)


## (A frog, or a tadpole.)
func _frog_do(c: Node, act_: String, young: bool, p: Vector3) -> void:
	var tad := young and float(c.get("dev")) < 1.0
	var pond: Array = c.get("pond")
	var home: Vector3 = pond[0]
	var half: Vector2 = pond[1]
	match act_:
		"eat", "hunt":
			if not tad:
				var a := randf() * TAU
				var at := p + Vector3(cos(a), 0.0, sin(a)) * 0.12
				var wet := absf(at.x - home.x) < half.x and absf(at.z - home.z) < half.y
				at.y = POND if wet else 0.0
				c.call("hunt", _insect_at(at, 0.35, wet))
		"lay":
			if not tad and not _flag(c, "male"):
				c.call("lay")
		"fly":
			if tad:
				c.call("metamorphose")
			else:
				var a := randf() * TAU
				c.call("hop", p + Vector3(cos(a), 0.0, sin(a)) * 0.2)
		"sleep", "sit":
			c.call("sleep", 30.0)
		"display":
			if _flag(c, "male") and not young:
				c.call("croak")
		"alarm":
			if not tad:
				c.call("flee", p + Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)) * 0.1)
		"forage":
			if not tad:
				c.call("swim", home + Vector3(randf_range(-0.6, 0.6) * half.x, 0.0, randf_range(-0.5, 0.5) * half.y))
		"wander":
			if not tad:
				c.call("wander", p, 0.2)


## A fallen log lying from a pond's bank (nearest p) down into its water,
## for its painted turtles to bask on (one to a pond; the next asked for
## has the same): spots along its top to bask at.
func _basking_log(q: Dictionary, p: Vector3) -> Array:
	var c: Vector3 = q.c
	if not q.has("log"):
		var bank := _bank_of(q, p)
		var into := (Vector3(c.x - bank.x, 0.0, c.z - bank.z)).normalized()
		var a := bank - into * 0.15
		var b := bank + into * 0.85
		a.y = 0.04
		b.y = POND - 0.03
		var lg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.055
		cm.bottom_radius = 0.065
		cm.height = a.distance_to(b)
		cm.radial_segments = 12
		lg.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.42, 0.38, 0.32) # (weathered grey, the bark gone)
		m.roughness = 0.95
		lg.material_override = m
		var d := (b - a).normalized()
		var x := d.cross(Vector3.UP).normalized()
		lg.transform = Transform3D(Basis(x, d, x.cross(d)), (a + b) * 0.5)
		add_child(lg)
		var spots := []
		for f: float in [0.35, 0.55, 0.75]:
			spots.append(a.lerp(b, f) + Vector3(0.0, 0.058, 0.0))
		q["log"] = spots
	return q["log"]


## (A turtle.)
func _turtle_do(c: Node, act_: String, young: bool, p: Vector3) -> void:
	var sc: Script = c.get_script()
	var snap := sc == SnapScript or sc == SeaScript or sc == PaintedScript
	var pond: Array = c.get("pond")
	var a := randf() * TAU
	match act_:
		"eat", "hunt":
			var f: Node3D
			var at := p + Vector3(cos(a), 0.0, sin(a)) * (0.3 if snap else 0.2)
			if sc == SeaScript: # (its seagrass isn't in the game: nothing for it)
				return
			if snap: # (a grasshopper nymph fallen on the water: its weed isn't in the game)
				at = p + Vector3(cos(a), 0.0, sin(a)) * 0.3
				at.y = POND
				f = _insect_at(at, 0.5, true)
			else: # (a fallen crabapple (the game's); or a pill bug at it)
				at.y = 0.0
				if act_ == "eat":
					f = _laid("crabapple", at, randf() * TAU)
				else:
					f = IsopodScript.new()
					add_child(f)
					f.call("place", at, randf() * TAU)
					f.call("eat", at)
			c.call("eat", f)
		"lay":
			if not young and not _flag(c, "male"):
				c.call("nest")
		"sleep":
			c.call("sleep", 30.0)
		"sit":
			c.call("bask")
		"fly":
			c.call("dive")
		"alarm":
			c.call("withdraw")
		"wander", "forage":
			c.call("wander", pond[0], 1.5 if sc == SeaScript else 0.6)


## A crayfish's ways, in its pond: E a dead deer mouse on the bottom eaten
## where it lies, H a grasshopper nymph fallen in hunted, X the tail flip,
## D the threat, B foraging over the bottom, F / Z a burrow at the pond's
## edge (the red swamp's chimney), 1 in berry, 2 her young hatched (or else
## a moult), W wandering again.
func _crayfish_do(c: Node, act_: String, young: bool, p: Vector3) -> void:
	var pc: Vector3 = c.get_meta("pond", p)
	var q := _pond_near(pc, 0.5)
	var a := randf() * TAU
	var near := Vector3(cos(a), 0.0, sin(a))
	var fwd := Vector3(-sin(float(c.get("_yaw"))), 0.0, -cos(float(c.get("_yaw"))))
	var inside := func(v: Vector3) -> Vector3: # (on the ground there, in the water or out; not over a drop from it)
		v.y = _height(v.x, v.z)
		if absf(v.y - p.y) > 0.03: # (over the pond's steep bank from it: nearer, its side)
			v = p + (v - p).normalized() * 0.06
			v.y = _height(v.x, v.z)
			if absf(v.y - p.y) > 0.03:
				v = Vector3(p.x, p.y, p.z)
		return v
	match act_:
		"eat": # (carrion: a dead deer mouse on the bottom)
			var at: Vector3 = inside.call(p + (fwd * 0.6 + near * 0.4).normalized() * 0.12)
			c.call("eat", _real_prey("dead_mouse", at))
		"hunt":
			var at: Vector3 = inside.call(p + (fwd * 0.6 + near * 0.4).normalized() * 0.16)
			c.call("hunt", _insect_at(at, 0.5, true))
		"alarm":
			c.call("flee", p + fwd * 0.2)
		"display":
			if c is ShrimpScript: # (no threat display: off, swimming)
				c.call("flee", p + fwd * 0.2)
			else:
				c.call("threat", p + fwd * 0.2)
		"forage":
			c.call("forage", p, 0.2)
		"fly", "sleep", "sit" when c is ShrimpScript: # (buried in the sand where it is; F: off swimming)
			if act_ == "fly":
				c.call("wander", p, 0.8)
			else:
				c.call("burrow", p)
		"fly", "sleep", "sit": # (a burrow on the bank, by the water: up its sloping bank, to one side)
			var at := p + near * 0.15
			if not q.is_empty() and q.has("ramp"):
				var top: Vector3 = (q.ramp as Array)[1]
				at = top + Vector3(0.07, 0.0, (0.1 if randf() < 0.5 else -0.1))
			at.y = _height(at.x, at.z)
			c.call("burrow", at)
		"lay":
			if not young:
				c.call("lay")
		"hatch":
			if bool(c.get("berried")):
				c.call("hatch")
			else:
				c.call("moult")
		_:
			# (about its pond and its banks: in the water and out, by the sloping bank)
			c.call("wander", p if q.is_empty() else (q.c as Vector3), 0.3 if q.is_empty() else maxf(float(q.hw), float(q.hd)) + 0.3)


## Something to eat (or hunt), its own kind of food: what's here, or set
## out for it.
func _feed(c: Node, act_: String, young: bool, p: Vector3, st: Vector3, near: Vector3) -> void:
	var sc: Script = c.get_script()
	if act_ == "hunt" and not young and sc in [BlackBearScript, BrownBearScript]: # (H, by a pond with fish in it: fishing)
		var fs := _fish_school_near(p, 9.0) # (its pond's middle: the pond a few metres across)
		if fs:
			var q := _pond_near(fs.get_meta("pond"), 0.1)
			if not q.is_empty():
				var c0: Vector3 = q.c
				var hw := float(q.hw)
				var hd := float(q.hd)
				# (the edge nearest it, and the way out over the water from there)
				var ex := clampf(p.x, c0.x - hw, c0.x + hw)
				var ez := clampf(p.z, c0.z - hd, c0.z + hd)
				var dx := minf(absf(p.x - (c0.x - hw)), absf(p.x - (c0.x + hw)))
				var dz := minf(absf(p.z - (c0.z - hd)), absf(p.z - (c0.z + hd)))
				var edge: Vector3
				var into: Vector3
				if dx < dz or absf(p.z - c0.z) <= hd and absf(p.x - c0.x) > hw:
					edge = Vector3(c0.x - hw if p.x < c0.x else c0.x + hw, 0.0, ez)
					into = Vector3(1.0 if p.x < c0.x else -1.0, 0.0, 0.0)
				else:
					edge = Vector3(ex, 0.0, c0.z - hd if p.z < c0.z else c0.z + hd)
					into = Vector3(0.0, 0.0, 1.0 if p.z < c0.z else -1.0)
				edge.y = POND
				c.call("fish", fs, edge, into)
				return
	if act_ == "eat" and not young and sc in [WolfScript, CoyoteScript, FoxScript, BobcatScript, BlackBearScript, BrownBearScript, OpossumScript]:
		var carrion := _carrion_near(p, 8.0) # (a carcass, fresh or rotting: scavenged)
		if carrion:
			carrion.set_meta("hunted", c)
			c.call("eat", carrion)
			return
	if sc == LarvaScript:
		c.call("eat")
	elif (sc == MonarchScript or sc == SwallowScript) and not young:
		var cl := _clumps_near(p)
		c.call("feed", cl[randi() % cl.size()])
	elif sc == LunaScript: # (it never eats: down to rest, its wings spread)
		c.call("rest", p * Vector3(1.0, 0.0, 1.0) + near * 0.1, Vector3.UP)
	elif sc == HopperScript or sc == BlueHopperScript: # (the grass: chewing it where it stands)
		c.call("feed", Vector3(p.x, 0.0, p.z) + near * (0.03 if young else 0.12) + Vector3.UP * (0.001 if young else 0.002))
	elif sc == MantisScript:
		var f := _insect_at(p + near * (0.03 if young else 0.06), 0.2 if young else 0.45)
		c.call("strike", f.position + Vector3(0.0, 0.004, 0.0), f)
	elif sc == SnakeScript:
		c.call("eat", _prey(c, ["mouse_pup"] if young else ["mouse"], 0.4, 3.0) if young or randf() < 0.6 else _mouse_at(p + near * 0.4, false))
	elif sc == SpiderScript:
		if c.get("kind") == "fishing" and not young and act_ == "eat":
			_spider_fish(c)
			return
		var f := _spider_prey(c, p, near, young)
		if f:
			c.call("hunt", f)
	elif sc == IsopodScript:
		c.call("eat", p + near * 0.01)
	elif sc == MouseScript:
		if not young or float(c.get("size")) >= 0.25:
			c.call("eat", _seed_for(c, p))
	elif sc == AnoleScript or sc == ScorpionScript:
		if c.get("_mother") != null:
			return
		var hunted: Node3D = _prey_here(c, ["nymph"], 0.6)
		if hunted == null:
			hunted = _insect_at(p + near * ((0.05 if young else 0.12) if sc == AnoleScript else (0.04 if young else 0.1)), (0.18 if young else 0.4) if sc == AnoleScript else (0.22 if young else 0.6))
		c.call("hunt", hunted)
	elif sc == HareScript:
		c.call("eat", _hare_food(c, p, act_ == "hunt" and not young))
	elif sc == SquirrelScript or sc == GreySqScript:
		if not young:
			c.call("eat", _nut_for(c, p))
	elif sc == BeaverScript:
		if young:
			return
		if act_ == "hunt": # (H: a sapling felled, a length of it to the lodge)
			for t in _plants_near(p, 6.0, ["s_maple"]):
				if (t as Node3D).transform.basis.y.y > 0.9 and not t.has_meta("felling"):
					t.set_meta("felling", true)
					c.call("fell", t)
					return
			var sp: Node3D = spawn("s_maple", p + near * 0.8)
			sp.set_meta("felling", true)
			c.call("fell", sp)
			return
		c.call("eat", _stick_for(c, p))
	elif sc == MothScript:
		if not young:
			c.call("feed", _flat(_clumps_near(p)))
	elif sc == TrigScript or sc == IchScript:
		c.call("visit_flowers", _heads_near(p, 3.0, "fleabane"), 1.0)
	elif sc == BeeScript:
		c.call("forage", _heads_near(p), _kit(c, "nest", func() -> Node3D:
			var ns: Node3D = BeeScript.nest()
			ns.position = st + Vector3(0.3, 0.0, 0.3)
			return ns).position)
	elif sc == Wasp:
		var cats := []
		for o in get_children():
			if o.get_script() == LarvaScript and o.get("kind") in ["monarch", "hemaris"] and _where(o).distance_to(p) < 2.0 and not o.has_meta("hunted"):
				cats.append(o)
		var cat: Node3D
		if not cats.is_empty():
			cat = cats[0]
		else:
			cat = LarvaScript.new("monarch" if randf() < 0.5 else "hemaris")
			add_child(cat)
			cat.call("place", p * Vector3(1.0, 0.0, 1.0) + near * 0.15, Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)))
			cat.call("eat")
		cat.set_meta("hunted", c)
		var at: Vector3 = cat.get("_pos")
		c.call("feed_on_insect", cat, Vector3(at.x, maxf(at.y, 0.0), at.z), Vector3.UP)
	elif sc == BisonScript or sc == DeerScript or sc == MooseScript:
		if act_ == "eat":
			if not young:
				c.call("graze", p, 3.0 if sc == BisonScript else 2.0)
		elif _flag(c, "male") and not young: # (H: a bull, a buck, sparring with another)
			for o in _creatures():
				if o != c and o.get_script() == sc and _flag(o, "male") and not _young(o) and (sc == BisonScript or o.get("season") == c.get("season")):
					c.call("spar", o)
					break
	elif c.has_method("browse") and act_ == "eat": # (a bear: berries)
		c.call("browse", _bush_near(p))
	elif sc == OpossumScript:
		if young:
			return
		if act_ == "hunt": # (H: a mouse, a grasshopper)
			c.call("hunt", _prey(c, ["mouse", "grasshopper", "nymph"], 0.8))
		elif randf() < 0.55: # (E: fallen fruit, eaten where it lies; or carrion)
			var fruit: Array = _windfall_near(p)
			c.call("eat_at", fruit[randi() % fruit.size()], 12.0)
		else:
			c.call("eat", _real_prey("dead_mouse", p + near * 0.4))
	elif c.has_method("hunt") and not young: # (the hunters: their prey here)
		var diet: Array = {FoxScript: ["mouse", "squirrel", "hare"], BobcatScript: ["hare", "squirrel", "mouse"],
				CoyoteScript: ["mouse", "hare", "squirrel"], WolfScript: ["hare", "mouse", "deer", "fawn"]}.get(sc, ["hare", "mouse", "squirrel"])
		c.call("hunt", _prey(c, diet, 1.4))


## Who eats which mushrooms (Fungus): the box turtle all but the chicken of
## the woods (fly agarics too: it isn't harmed by them), the squirrels
## morels, fly agarics (they eat them, and dry them) and chicken of the
## woods, the deer and moose fly agarics, morels and (deer) chicken of the
## woods, the deer mouse little brown caps and morels, the opossum and the
## bears morels and chicken of the woods. (No insect here eats them: the
## little brown caps' psilocybin keeps the insects off theirs.)
const MUSHROOM_EATERS := {
	TurtleScript: ["morel", "fly_agaric", "little_brown"],
	SquirrelScript: ["morel", "fly_agaric", "chicken_of_the_woods"],
	GreySqScript: ["morel", "fly_agaric", "chicken_of_the_woods"],
	DeerScript: ["fly_agaric", "morel", "chicken_of_the_woods"],
	MooseScript: ["fly_agaric", "morel"],
	MouseScript: ["little_brown", "morel"],
	OpossumScript: ["morel", "chicken_of_the_woods"],
	BlackBearScript: ["chicken_of_the_woods", "morel"],
	BrownBearScript: ["chicken_of_the_woods", "morel"],
}


## R: a mushroom eaten, one of those it eats (MUSHROOM_EATERS): one grown or
## laid near it, else one put down before it (the chicken of the woods on a
## stump), and eaten as its own food is (bitten at where it stands, or
## (a squirrel, a mouse) held in its forepaws).
func _mushroom_meal(c: Node, young: bool, p: Vector3, near: Vector3) -> void:
	var sc: Script = c.get_script()
	var kinds: Array = MUSHROOM_EATERS.get(sc, [])
	if kinds.is_empty() or (young and sc != TurtleScript):
		return
	var f := _fungus_near(p, kinds, 3.0)
	if f == null:
		var id: String = kinds[randi() % kinds.size()]
		var d: float = {TurtleScript: 0.22, MouseScript: 0.08, SquirrelScript: 0.25, GreySqScript: 0.25, OpossumScript: 0.4, DeerScript: 0.75, MooseScript: 1.1}.get(sc, 0.9)
		f = _mushroom(id, Vector3(p.x, 0.0, p.z) + near * d)
	# (not used up, as a bush's berries aren't: bitten at where it grows, and
	# left; the hunters' make (the deer, the moose, the bears, the opossum)
	# their mouths brought down onto its cap, the rest nibbling at it)
	f.set_meta("keep", true)
	if c.has_method("eat_at"):
		c.call("eat_at", MealScript.bite_at(f), 8.0)
	else:
		c.call("eat", f)


## A mushroom of id grown here (one of it: Fungus.held), upright; a chicken
## of the woods on the side of a stump, a shelf.
func _mushroom(id: String, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "fungus_" + id
	var mi := MeshInstance3D.new()
	mi.mesh = Fungus.held(id)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF # (as in the game: no shadows)
	root.add_child(mi)
	if id == "chicken_of_the_woods":
		var stump := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.16
		cm.bottom_radius = 0.2
		cm.height = 0.45
		stump.mesh = cm
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.36, 0.29, 0.21)
		bm.roughness = 0.95
		stump.material_override = bm
		stump.position = at + Vector3(0.0, 0.225, -0.17)
		add_child(stump)
		mi.position = Vector3(0.0, 0.3, 0.0)
	root.position = at
	add_child(root)
	root.set_meta("item", id)
	root.set_meta("fungus", id)
	root.set_meta("bite_y", {"morel": 0.07, "fly_agaric": 0.15, "little_brown": 0.05, "chicken_of_the_woods": 0.31}.get(id, 0.05)) # (its cap: where it's bitten)
	return root


## The nearest mushroom (grown here, _mushroom; or laid: its item) of the
## kinds within r of p, not already being eaten.
func _fungus_near(p: Vector3, kinds: Array, r: float) -> Node3D:
	if kinds.is_empty():
		return null
	var best: Node3D = null
	var bd := r
	for o in get_children():
		if not o is Node3D or not o.has_meta("item") or not String(o.get_meta("item")) in kinds:
			continue
		var d := Vector2((o as Node3D).position.x - p.x, (o as Node3D).position.z - p.z).length()
		if d < bd:
			bd = d
			best = o
	return best


## The nearest carcass (fresh or rotting, not yet anyone's) within r of p.
func _carrion_near(p: Vector3, r: float) -> Node3D:
	var best: Node3D = null
	for o in get_children():
		if not o.has_meta("carcass") or int(o.get_meta("carcass")) > 2 or o.has_meta("hunted"):
			continue
		var q: Vector3 = (o as Node3D).get("_pos")
		if q.distance_to(p) <= r and (best == null or q.distance_to(p) < (best.get("_pos") as Vector3).distance_to(p)):
			best = o
	return best


## The mammals' (and the snakes') rarer meals (U), each plausible, if
## seldom seen: one of the animals here (one that's here first), or set
## out for it. The fox's fruit, ants, wasps; the opossum's fruit: eaten
## where they are, its snout to them, nothing taken away.
const UNUSUAL := {
	"fox": ["fawn", "beaver_kit", "bobcat_kit", "grub", "grasshopper", "mouse_pup", "leveret", "snake_young", "fruit", "ants", "wasps"],
	"bobcat": ["fawn", "deer", "fox", "fox_kit", "beaver_kit", "grasshopper", "snake"],
	"coyote": ["fawn", "fox", "fox_kit", "bobcat_kit", "beaver", "grub", "grasshopper", "snake"],
	"rattler": ["frog", "toad", "anole"],
	"milk": ["frog", "toad", "anole", "snake_young"],
	"wolf": ["deer", "fawn", "moose_calf", "bison_calf", "beaver", "coyote", "fox"],
	"black_bear": ["fawn", "moose_calf", "beaver", "grub", "mouse_pup", "squirrel", "bobcat_kit"],
	"brown_bear": ["moose_calf", "bison_calf", "fawn", "deer", "beaver", "grub", "black_cub", "wolf_pup"],
	"deer": ["mouse_pup"],
	"mouse": ["nymph", "caterpillar", "grub", "pillbug", "mantis_nymph"],
	"squirrel": ["caterpillar", "grub", "mouse_pup"],
	"hare": ["dead_mouse"],
	"opossum": ["snake", "snake_young", "toad", "frog", "grub", "caterpillar", "mouse_pup", "anole", "fruit"],
}


func _unusual(c: Node, p: Vector3) -> void:
	var sc: Script = c.get_script()
	var who: String = {FoxScript: "fox", BobcatScript: "bobcat", CoyoteScript: "coyote", WolfScript: "wolf", BlackBearScript: "black_bear",
			BrownBearScript: "brown_bear", DeerScript: "deer", MouseScript: "mouse", SquirrelScript: "squirrel", GreySqScript: "squirrel",
			HareScript: "hare", OpossumScript: "opossum"}.get(sc, "")
	if sc == SnakeScript:
		who = String(c.get("kind"))
	if who == "" or not UNUSUAL.has(who):
		return
	var kinds: Array = UNUSUAL[who]
	var kind: String = kinds[randi() % kinds.size()]
	var a := randf() * TAU
	var dir := Vector3(cos(a), 0.0, sin(a))
	if kind == "fruit" and who == "opossum":
		var fruit: Array = _windfall_near(p)
		c.call("eat_at", fruit[randi() % fruit.size()], 12.0)
	elif kind in ["fruit", "ants", "wasps"]: # (the fox's: eaten where it is, nothing taken)
		c.call("eat_at", _fox_spot(c, kind, p), 10.0)
	elif sc == SnakeScript:
		c.call("eat", _prey(c, [kind], 0.35, 3.0))
	elif c.has_method("hunt") and who != "deer":
		var here := _prey(c, [kind], randf_range(0.6, 0.9) if who == "opossum" else randf_range(1.6, 2.4))
		c.call("hunt", here)
	else: # (set before it, close)
		var d := 0.08 if who == "mouse" else (0.25 if who == "squirrel" else 0.6)
		c.call("eat", _real_prey(kind, p + dir * d))


## The fox's foraging spots (made the first time): a berry bush, a harvester
## ants' nest, a paper wasp comb fallen in the grass; a point to eat at.
func _fox_spot(c: Node, kind: String, from: Vector3) -> Vector3:
	var st: Vector3 = c.get_meta("home", from)
	var at: Vector3
	match kind:
		"fruit":
			at = _bush_near(st, Vector3(1.5, 0.0, 0.9)).position
		"ants":
			at = _kit(c, "ants", func() -> Node3D:
				var ants: Node3D = HarvesterScript.new()
				ants.position = st + Vector3(-1.4, 0.0, -0.5)
				add_child(ants)
				ants.call("setup", 40, Vector3.ZERO, 0.12)
				return ants).position
		_:
			at = _kit(c, "fallen_comb", func() -> Node3D:
				var made := Wasp.comb()
				var comb: Node3D = made[0]
				comb.position = st + Vector3(-0.5, 0.0, 1.3)
				comb.rotation.z = 1.2
				return comb).position
	var a := randf() * TAU
	match kind:
		"fruit":
			var toward := Vector3(from.x - at.x, 0.0, from.z - at.z).normalized()
			return at + toward * 0.18 + Vector3(cos(a), 0.0, sin(a)) * 0.05 + Vector3.UP * randf_range(0.22, 0.4)
		"ants":
			return at + Vector3(cos(a), 0.0, sin(a)) * randf_range(0.0, 0.08) + Vector3.UP * 0.004
	return at + Vector3.UP * 0.012


## A milkweed's lower and middle leaves near p (planted if there's none):
## [spot, normal] each, four, each its own leaf.
func _milkweed_leaves(p: Vector3) -> Array:
	var mw: Node = _plant_near(p, ["milkweed", "swamp_milkweed"], 3.0)
	var leaves: Array = (mw.get_meta("leaves", []) as Array).filter(func(l: Array) -> bool: return (l[0] as Vector3).y < 0.8)
	leaves.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector3).y < (b[0] as Vector3).y)
	var out := []
	for l: Array in leaves:
		if out.size() >= 4:
			break
		var at: Vector3 = (l[0] as Vector3) + (l[1] as Vector3) * 0.002
		if out.all(func(m: Array) -> bool: return (m[0] as Vector3).distance_to(at) > 0.02):
			out.append([at, l[1]])
	return out


## A dead branch to climb near p (one put down, or one leaning there now).
func _snag_near(p: Vector3) -> Node:
	for n in get_children():
		if n.has_meta("snag") and (n as Node3D).position.distance_to(p) < 4.0:
			return n
	return spawn("snag", p + Vector3(0.7, 0.0, 0.3))


## Points along a demo leaf's margin (its top at top: Beetles.leaf, 35 by
## 60 mm), one side, end to end.
func _leaf_edge(top: Vector3) -> Array:
	var out := []
	for k in 6:
		var z := lerpf(-0.022, 0.022, k / 5.0)
		var x := 0.0175 * sqrt(maxf(1.0 - pow(z / 0.02975, 2.0), 0.0)) * 0.92
		out.append(top + Vector3(x, 0.0, z))
	return out


static func _flat(arrays: Array) -> Array:
	var out := []
	for a: Array in arrays:
		out.append_array(a)
	return out


# --- selection, placing, the camera ------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if KEYS.has(e.keycode):
			act(KEYS[e.keycode])
			_status = "%s: %d" % [KEYS[e.keycode], _targets().size()]
			_say()
			return
		match e.keycode:
			KEY_ESCAPE:
				_stop_placing()
			KEY_DELETE, KEY_BACKSPACE:
				_delete_selected()
			KEY_C:
				_center()
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
		return
	if e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT and _left_down != Vector2.INF and mm.position.distance_to(_left_down) > 6.0:
			_left_dragged = true # (a left drag turns the view too; a click without one picks or puts down)
		if mm.button_mask & MOUSE_BUTTON_MASK_RIGHT or (mm.button_mask & MOUSE_BUTTON_MASK_LEFT and _left_dragged):
			_yaw -= mm.relative.x * 0.008
			_pitch = clampf(_pitch - mm.relative.y * 0.008, -1.45, 0.2)
		elif mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			var right := cam.global_basis.x
			var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
			_focus += (-right * mm.relative.x + fwd * mm.relative.y) * _dist * 0.002
		return
	if e is InputEventMouseButton and e.pressed:
		var mb := e as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_dist = maxf(_dist * 0.88, 0.05)
			MOUSE_BUTTON_WHEEL_DOWN:
				_dist = minf(_dist / 0.88, 40.0)
			MOUSE_BUTTON_RIGHT:
				_right_down = mb.position
			MOUSE_BUTTON_LEFT:
				_left_down = mb.position
				_left_dragged = false
		return
	if e is InputEventMouseButton and not e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		var dragged := _left_dragged or _left_down == Vector2.INF
		_left_down = Vector2.INF
		_left_dragged = false
		if not dragged:
			var g := _ground_at(mb.position)
			if _placing != "":
				if g != Vector3.INF:
					var n := spawn(_placing, g, _stage(), _ui_male.button_pressed)
					_status = ("put down: %s" % _name_of(_placing)) if n else ("nothing put down (%s)" % _name_of(_placing))
					_say()
			else:
				_pick(mb.position, mb.shift_pressed)
	elif e is InputEventMouseButton and not e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		if _placing != "" and (e as InputEventMouseButton).position.distance_to(_right_down) < 4.0:
			_stop_placing()


var _right_down := Vector2.ZERO
var _left_down := Vector2.INF # (where the left button went down over the view; INF: not)
var _left_dragged := false


## The ground under a point on the screen (or INF).
func _ground_at(sp: Vector2) -> Vector3:
	var from := cam.project_ray_origin(sp)
	var dir := cam.project_ray_normal(sp)
	if dir.y > -1e-4:
		return Vector3.INF
	var t := -from.y / dir.y
	var p := from + dir * t
	if absf(p.x) > HALF or absf(p.z) > HALF:
		return Vector3.INF
	return p


## The creature (or plant) nearest the click on the screen: selected.
func _pick(sp: Vector2, add: bool) -> void:
	var best: Node = null
	var bd := 36.0
	var pool := _creatures()
	for n in _plants:
		if is_instance_valid(n):
			pool.append(n)
	for n in get_children():
		if n.has_meta("placed") and not pool.has(n):
			pool.append(n)
	for n in pool:
		# (its body, where it's drawn, or the ground under it: the nearer)
		for p: Vector3 in [_where(n), (n as Node3D).global_position if n is Node3D else Vector3.INF]:
			if p == Vector3.INF or cam.is_position_behind(p):
				continue
			var d := cam.unproject_position(p).distance_to(sp)
			if d < bd:
				bd = d
				best = n
	if not add:
		_selected.clear()
	if best:
		if _selected.has(best):
			_selected.erase(best)
		else:
			_selected.append(best)
	_status = "%d selected" % _selected.size()
	_say()


func _delete_selected() -> void:
	for n in _selected:
		if is_instance_valid(n):
			_remove(n)
	_selected.clear()
	_say()


## n gone (and its kit; a pond, its water and the ground made whole).
func _remove(n: Node) -> void:
	var kit: Dictionary = n.get_meta("kit", {})
	for k in kit:
		var v: Variant = kit[k]
		if v is Node and is_instance_valid(v):
			(v as Node).queue_free()
		elif v is Array:
			for t in v:
				if t is Node and is_instance_valid(t):
					(t as Node).queue_free()
	if n.has_meta("pond"):
		for q: Dictionary in _ponds.duplicate():
			if (q.nodes as Array).has(n):
				for t in q.nodes:
					if is_instance_valid(t):
						(t as Node).queue_free()
				_ponds.erase(q)
				_rebuild_ground()
				_regrass(Rect2((q.c as Vector3).x - float(q.hw), (q.c as Vector3).z - float(q.hd), float(q.hw) * 2.0, float(q.hd) * 2.0))
				return
	_plants.erase(n)
	n.queue_free()


func clear_all() -> void:
	for n in get_children():
		if n == cam or n is WorldEnvironment or n is DirectionalLight3D or n == _ghost or _ground.has(n) or n is CanvasLayer or (n is MeshInstance3D and _rings.has(n as MeshInstance3D)):
			continue
		if _grass.values().has(n):
			continue
		n.queue_free()
	_ponds.clear()
	_plants.clear()
	_selected.clear()
	_clearings.clear()
	_worker_colonies.clear()
	_rebuild_ground()
	for t in _grass.keys():
		_grass_tile(t)
	_status = "cleared"
	_say()


func _center() -> void:
	_selected = _selected.filter(func(n) -> bool: return is_instance_valid(n))
	if _selected.is_empty():
		return
	var s := Vector3.ZERO
	for n in _selected:
		s += _where(n)
	_focus = s / _selected.size()


func _stop_placing() -> void:
	_placing = ""
	_ghost.visible = false
	if _ui_tree:
		_ui_tree.deselect_all()
	_say()


func _stage() -> String:
	return ["adult", "young", "pupa"][_ui_stage.selected] if _ui_stage else "adult"


## The game's own trees and bushes (their meshes, their fruit), by key:
## [its name here, its script].
static func _game_trees() -> Dictionary:
	return {"oak": ["oak", OakTree], "maple": ["maple", MapleTree], "walnut": ["walnut", WalnutTree], "tulip": ["tulip tree", TulipTree],
		"sycamore": ["sycamore", SycamoreTree], "black_cherry": ["cherry", BlackCherryTree], "crabapple": ["crabapple", CrabappleTree],
		"pawpaw": ["pawpaw", PawpawTree], "lodgepole": ["lodgepole pine", LodgepolePine], "spruce": ["spruce", SpruceTree], "cypress": ["bald cypress", BaldCypress],
		"blueberry": ["blueberry bush", BlueberryBush], "raspberry": ["raspberry bush", RaspberryBush],
		"prickly_pear": ["prickly pear", PricklyPear], "joshua_tree": ["Joshua tree", JoshuaTree], "san_pedro": ["San Pedro cactus", SanPedroCactus]}


## What can be put down: CATALOGUE, and everything else that's in the game:
## its trees and bushes (young: a sapling), and its items (laid on the
## ground, as dropped: Drops).
func _catalogue() -> Array:
	var out: Array = []
	for e: Array in CATALOGUE:
		out.append(e)
		if e[2] == "tobacco": # (after the plants: the trees and bushes)
			var gt := _game_trees()
			for id: String in gt:
				var bush: bool = id in ["blueberry", "raspberry"]
				out.append(["Trees and bushes", gt[id][0], "g_" + id, ["adult"] if bush else ["adult", "young"]])
	for id: String in Items.KINDS:
		out.append(["Items", Items.name_of(id), "item_" + id, ["adult"]])
	return out


func _name_of(key: String) -> String:
	for e: Array in _catalogue():
		if e[2] == key:
			return e[1]
	return key


func _exit_tree() -> void:
	Lepidoptera.sway_of = Callable()


## (How much the flower's floret at `at` sways, for a butterfly or a moth
## on it or at it to sway with it: its head's share, squared, as the
## flower's shader sways it; 0 for anything else.)
func _sway_of(at: Vector3) -> float:
	for n: Node in _plants_near(at, 1.0, FLOWER_KINDS):
		for h: Array in n.get_meta("heads", []):
			if (h[0] as Vector3).distance_to(at) < 0.03:
				return float(h[2]) * float(h[2])
	return 0.0


func _process(dt: float) -> void:
	# the camera, round its focus
	var k := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if k != Vector2.ZERO and Input.is_key_pressed(KEY_SHIFT): # (Shift + arrows: turning the view round, tilting it)
		_yaw -= k.x * 1.6 * dt
		_pitch = clampf(_pitch + k.y * 1.0 * dt, -1.45, 0.2)
		k = Vector2.ZERO
	if k != Vector2.ZERO and not (get_viewport().gui_get_focus_owner() is LineEdit):
		var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
		var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
		_focus += (right * k.x - fwd * k.y) * _dist * dt
	_focus.x = clampf(_focus.x, -HALF, HALF)
	_focus.z = clampf(_focus.z, -HALF, HALF)
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)
	# the ghost under the mouse, placing
	if _placing != "":
		var g := _ground_at(get_viewport().get_mouse_position())
		_ghost.visible = g != Vector3.INF
		if _ghost.visible:
			var r := clampf(_dist * 0.03, 0.02, 1.0)
			_ghost.transform = Transform3D(Basis.from_scale(Vector3(r, r * 0.3, r)), g + Vector3.UP * 0.003)
	# the selection's rings
	_selected = _selected.filter(func(n) -> bool: return is_instance_valid(n))
	while _rings.size() < _selected.size():
		var ring := MeshInstance3D.new()
		ring.mesh = _ring_mesh
		ring.material_override = _ring_mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
	for i in _rings.size():
		var ring := _rings[i]
		ring.visible = i < _selected.size()
		if ring.visible:
			var n: Node = _selected[i]
			var p := _where(n)
			var r := 0.08
			if n is Node3D:
				var d: Vector2 = PersonalSpace._dims(n as Node3D) if n.get_script() != null else Vector2.ZERO
				r = clampf(d.x * 0.6, 0.02, 2.0) if d.x > 0.0 else 0.08
			ring.transform = Transform3D(Basis.from_scale(Vector3(r, r * 0.2, r)), Vector3(p.x, maxf(p.y, 0.0) + 0.004, p.z))


# --- the panel --------------------------------------------------------------------

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var panel := PanelContainer.new()
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_bottom = -8.0
	panel.offset_right = 290.0
	cl.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Add: a kind, then click the ground\n(right click or Esc: done)"
	box.add_child(title)
	_ui_tree = Tree.new()
	_ui_tree.hide_root = true
	_ui_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ui_tree.focus_mode = Control.FOCUS_NONE
	box.add_child(_ui_tree)
	var root := _ui_tree.create_item()
	var groups := {}
	for e: Array in _catalogue():
		if not groups.has(e[0]):
			var g := _ui_tree.create_item(root)
			g.set_text(0, e[0])
			g.set_selectable(0, false)
			g.collapsed = e[0] != "Mammals" and e[0] != "Insects"
			groups[e[0]] = g
		var it := _ui_tree.create_item(groups[e[0]])
		it.set_text(0, e[1])
		it.set_metadata(0, e[2])
		it.set_tooltip_text(0, "stages: " + ", ".join(e[3]))
	_ui_tree.item_selected.connect(func() -> void:
		var it := _ui_tree.get_selected()
		if it and it.get_metadata(0) != null:
			_placing = it.get_metadata(0)
			_status = "placing: %s" % it.get_text(0)
			_say())
	var row := HBoxContainer.new()
	box.add_child(row)
	_ui_stage = OptionButton.new()
	_ui_stage.focus_mode = Control.FOCUS_NONE
	for s in ["adult", "young", "pupa"]:
		_ui_stage.add_item(s)
	row.add_child(_ui_stage)
	_ui_male = CheckBox.new()
	_ui_male.text = "male"
	_ui_male.focus_mode = Control.FOCUS_NONE
	row.add_child(_ui_male)
	_ui_decay = OptionButton.new()
	_ui_decay.focus_mode = Control.FOCUS_NONE
	for s_ in ["fresh", "rotting", "bones"]:
		_ui_decay.add_item(s_)
	_ui_decay.tooltip_text = "a carcass's decay"
	row.add_child(_ui_decay)
	var grass := CheckBox.new()
	grass.text = "grass"
	grass.button_pressed = true
	grass.focus_mode = Control.FOCUS_NONE
	grass.toggled.connect(func(on: bool) -> void:
		_grass_on = on
		for t in _grass.values():
			if is_instance_valid(t):
				(t as Node3D).visible = on)
	row.add_child(grass)
	var row2 := HBoxContainer.new()
	box.add_child(row2)
	var del := Button.new()
	del.text = "Delete selected"
	del.focus_mode = Control.FOCUS_NONE
	del.pressed.connect(_delete_selected)
	row2.add_child(del)
	var clr := Button.new()
	clr.text = "Clear all"
	clr.focus_mode = Control.FOCUS_NONE
	clr.pressed.connect(clear_all)
	row2.add_child(clr)
	_ui_info = Label.new()
	_ui_info.position = Vector2(300, 8)
	cl.add_child(_ui_info)


func _say() -> void:
	if _ui_info == null:
		return
	var sel := _selected.filter(func(n) -> bool: return is_instance_valid(n))
	var who := "everything here (%d)" % _creatures().size() if sel.is_empty() else ", ".join(sel.slice(0, 4).map(func(n: Node) -> String: return _label_of(n))) + (" ..." if sel.size() > 4 else "")
	_ui_info.text = "Keys act on: %s     %s\n1 lay / birth   2 hatch / moult / decay on   3 pupate   E eat   H hunt   U an unusual meal   R a mushroom   K mate   G groom   Z sleep\nF fly / hop / climb   X alarm   D display / call   V play   N nurse   B forage / home   S spin   M mark   A sit   W own ways\nclick: select (Shift: add)   Del: delete   C: centre   left or right drag, Shift + arrows: turn   middle drag / arrows: move   wheel: zoom   Space: slow" % [who, _status]


func _label_of(n: Node) -> String:
	var k: String = n.get_meta("placed", "")
	if k != "":
		return _name_of(k) + (" (young)" if _young(n) else "") + (" (male)" if _flag(n, "male") else "")
	var sc: Script = n.get_script()
	return sc.resource_path.get_file().get_basename() if sc else n.name


# --- helpers --------------------------------------------------------------------------

func _young(n: Object) -> bool:
	var sc: Variant = n.get_script() if n != null else null
	return sc == LarvaScript or sc == PupaScript or _flag(n, "young") or _flag(n, "nymph")


func _flag(n: Object, name: String) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	var v: Variant = n.get(name)
	return v is bool and v


## Where a creature (or a colony, an egg, a plant) is.
func _where(n: Node) -> Vector3:
	if n is MultiMeshInstance3D:
		var mm := n as MultiMeshInstance3D
		return mm.global_transform * mm.custom_aabb.get_center()
	var p: Variant = n.get("_pos")
	if p is Vector3:
		return p
	if n.has_meta("home") and not (n is Node3D and (n as Node3D).position != Vector3.ZERO):
		return n.get_meta("home")
	return (n as Node3D).global_position if n is Node3D else Vector3.INF


func _box_at(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
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
