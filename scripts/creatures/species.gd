class_name Species
extends RefCounted
## What the world's bookkeeping (FaunaSim) and the brains (Brain) know of
## each kind of animal, apart from its body: enough to run one with no body
## at all, and to make its body when it's wanted.
##
## TABLE: key -> {
##   script: its file (scripts/creatures/),
##   kind, young_kind: what it's called as food (Diet's names; "": nothing hunts it),
##   len: its body's length, m (how far off it must be made a body: FaunaSim's rings),
##   walk, run: m/s (with no body; a body's own pace is its own),
##   active: "day", "night", "any" (when it's about; the rest it sleeps),
##   range: m it wanders from its home,
##   wary: m at which it runs from what hunts it,
##   sense: m at which a hunter finds its prey,
##   meal: s a meal takes; fast: s from full to hungry; awake: s from rested to tired; nap: s a sleep lasts
##   herd: keeps with its own kind,
##   gest: s she carries her young (a state only: nothing of it shows); litter: [fewest, most] born;
##   wean: s a young one's young (with its mother; then grown, its own); breed_gap: s after a birth before
##   she'll mate again; crowd: with this many of her kind about her she won't; mate: s a mating takes
##   density: {a biome's name (WorldData.biome_names): how many to the square kilometre; "*": any not named}:
##   what FaunaSim seeds the land with
## }
## Times are the sandbox's (quick to watch); Fauna.life_rate scales them.
## Only what's here has a brain: add a line for another (its script's
## _init(young), `male`, `height`, place(at, yaw), as the walkers have).

const DIR := "res://scripts/creatures/"
const DEFAULTS := {"kind": "", "young_kind": "", "len": 1.0, "walk": 0.6, "run": 2.5, "active": "any", "range": 8.0, "wary": 6.0, "sense": 12.0,
		"meal": 25.0, "fast": 600.0, "awake": 300.0, "nap": 40.0, "herd": false,
		"gest": 150.0, "litter": [1, 2], "wean": 240.0, "breed_gap": 300.0, "crowd": 8, "mate": 14.0, "density": {}}
const TABLE := {
	"deer": {"density": {"forest": 8.0, "prairie": 4.0, "swamp": 3.0, "taiga": 2.0}, "litter": [1, 2], "crowd": 10, "script": "deer.gd", "kind": "deer", "young_kind": "fawn", "len": 1.8, "walk": 0.9, "run": 4.5, "range": 10.0, "wary": 8.0, "fast": 360.0, "herd": true},
	"moose": {"density": {"taiga": 1.5, "swamp": 1.0, "tundra": 0.5}, "litter": [1, 1], "script": "moose.gd", "young_kind": "moose_calf", "len": 2.8, "walk": 1.0, "run": 4.0, "range": 10.0, "wary": 5.0, "fast": 360.0},
	"bison": {"density": {"prairie": 6.0, "plateau": 2.0}, "litter": [1, 1], "script": "bison.gd", "young_kind": "bison_calf", "len": 3.0, "walk": 0.75, "run": 4.0, "range": 10.0, "wary": 4.0, "fast": 320.0, "herd": true},
	"wolf": {"density": {"forest": 0.3, "taiga": 0.4, "tundra": 0.3, "prairie": 0.2, "mountains": 0.2}, "litter": [3, 5], "crowd": 8, "script": "grey_wolf.gd", "young_kind": "wolf_pup", "len": 1.5, "walk": 0.8, "run": 5.0, "range": 11.0, "sense": 16.0, "fast": 960.0, "active": "night", "herd": true},
	"coyote": {"density": {"prairie": 0.8, "mesa": 0.8, "plateau": 0.5, "forest": 0.3}, "litter": [3, 5], "script": "coyote.gd", "kind": "coyote", "len": 1.1, "walk": 0.7, "run": 4.5, "range": 10.0, "fast": 800.0, "active": "night"},
	"fox": {"density": {"forest": 1.0, "prairie": 0.8, "coast": 0.5}, "litter": [3, 5], "script": "red_fox.gd", "kind": "fox", "young_kind": "fox_kit", "len": 0.9, "walk": 0.6, "run": 4.0, "range": 9.0, "fast": 720.0, "active": "night"},
	"bobcat": {"density": {"forest": 0.4, "mesa": 0.4, "swamp": 0.4, "mountains": 0.3}, "litter": [2, 3], "script": "bobcat.gd", "young_kind": "bobcat_kit", "len": 0.9, "walk": 0.55, "run": 4.5, "range": 9.0, "fast": 880.0, "active": "night"},
	"black_bear": {"density": {"forest": 0.4, "taiga": 0.3, "mountains": 0.3, "swamp": 0.2}, "litter": [1, 3], "script": "black_bear.gd", "young_kind": "black_cub", "len": 1.7, "walk": 0.75, "run": 3.5, "range": 10.0, "fast": 640.0, "active": "day"},
	"brown_bear": {"density": {"mountains": 0.15, "tundra": 0.15, "taiga": 0.15}, "litter": [1, 3], "script": "brown_bear.gd", "len": 2.2, "walk": 0.8, "run": 3.5, "range": 10.0, "fast": 640.0, "active": "day"},
	"hare": {"density": {"forest": 10.0, "prairie": 12.0, "tundra": 6.0, "taiga": 8.0, "mesa": 5.0}, "litter": [2, 4], "crowd": 10, "script": "hare.gd", "kind": "hare", "young_kind": "leveret", "len": 0.5, "walk": 0.9, "run": 5.0, "range": 7.0, "wary": 7.0, "fast": 320.0, "active": "night"},
	"mouse": {"density": {"forest": 30.0, "prairie": 30.0, "*": 8.0}, "litter": [3, 6], "crowd": 14, "script": "mouse.gd", "kind": "mouse", "young_kind": "mouse_pup", "len": 0.09, "walk": 0.14, "run": 0.6, "range": 2.0, "wary": 2.5, "fast": 240.0, "active": "night"},
	"fox_squirrel": {"density": {"forest": 12.0}, "litter": [2, 4], "script": "fox_squirrel.gd", "kind": "squirrel", "len": 0.3, "walk": 0.85, "run": 2.5, "range": 6.0, "wary": 5.0, "fast": 320.0, "active": "day"},
	"grey_squirrel": {"density": {"forest": 12.0}, "litter": [2, 4], "script": "grey_squirrel.gd", "kind": "squirrel", "len": 0.28, "walk": 0.9, "run": 2.5, "range": 6.0, "wary": 5.0, "fast": 320.0, "active": "day"},
	"opossum": {"density": {"forest": 2.0, "swamp": 3.0}, "litter": [5, 8], "script": "opossum.gd", "len": 0.5, "walk": 0.24, "run": 1.0, "range": 6.0, "fast": 560.0, "active": "night"},
	"porcupine": {"density": {"forest": 1.5, "taiga": 2.0}, "litter": [1, 1], "script": "porcupine.gd", "kind": "porcupine", "young_kind": "porcupette", "len": 0.7, "walk": 0.19, "run": 0.6, "range": 5.0, "wary": 2.0, "fast": 480.0, "active": "night"},
	"armadillo": {"density": {"mesa": 2.0, "prairie": 1.0, "swamp": 1.0}, "litter": [4, 4], "script": "armadillo.gd", "kind": "armadillo", "young_kind": "armadillo_pup", "len": 0.5, "walk": 0.22, "run": 1.5, "range": 6.0, "wary": 3.0, "fast": 400.0, "active": "night"},
	"turkey": {"density": {"forest": 5.0, "prairie": 2.0}, "litter": [6, 10], "crowd": 14, "script": "wild_turkey.gd", "kind": "turkey", "young_kind": "poult", "len": 1.0, "walk": 0.7, "run": 3.0, "range": 8.0, "wary": 7.0, "fast": 360.0, "active": "day", "herd": true},
	"robin": {"density": {"forest": 10.0, "prairie": 6.0, "coast": 3.0}, "litter": [3, 4], "script": "american_robin.gd", "kind": "robin", "young_kind": "nestling", "len": 0.25, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"blackbird": {"density": {"swamp": 12.0, "prairie": 6.0}, "litter": [3, 4], "script": "red_winged_blackbird.gd", "kind": "blackbird", "young_kind": "nestling", "len": 0.22, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day", "herd": true},
	"cardinal": {"density": {"forest": 6.0}, "litter": [2, 4], "script": "northern_cardinal.gd", "kind": "cardinal", "young_kind": "nestling", "len": 0.22, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"jay": {"density": {"forest": 5.0}, "litter": [3, 5], "script": "blue_jay.gd", "kind": "jay", "young_kind": "nestling", "len": 0.28, "walk": 0.7, "run": 6.0, "range": 9.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"pigeon": {"density": {"forest": 8.0}, "litter": [1, 1], "crowd": 30, "script": "passenger_pigeon.gd", "kind": "pigeon", "young_kind": "nestling", "len": 0.4, "walk": 0.7, "run": 7.0, "range": 10.0, "wary": 7.0, "fast": 300.0, "active": "day", "herd": true},
	"goose": {"density": {"swamp": 3.0, "coast": 3.0, "prairie": 1.0}, "litter": [3, 6], "crowd": 14, "script": "canada_goose.gd", "kind": "goose", "young_kind": "gosling", "len": 1.0, "walk": 0.7, "run": 5.0, "range": 9.0, "wary": 7.0, "fast": 320.0, "active": "day", "herd": true},
}
## A brain's verbs, each by the names the animals have for it (the first
## its body has, Creature.behaviours()).
const VERBS := {
	"eat": ["graze", "browse", "forage", "nibble", "eat", "hunt"],
	"hunt": ["hunt"],
	"sleep": ["sleep", "bed", "ruminate", "sit", "perch"],
	"groom": ["groom", "preen", "wallow", "dust", "rouse"],
	"alert": ["alert", "freeze", "stand", "flick"],
	"flee": ["flee", "fly"],
	"social": ["mark", "howl", "strut", "gobble", "thump", "rub", "call"],
	"mate": ["mate"],
	"birth": ["birth"],
}

static var _full := {} # key -> its entry, filled in
static var _more := {} # key -> an entry registered (register())
static var _by_file := {} # a script's file -> key
static var _hunts := {} # "a>b" -> bool


## Its entry (the defaults filled in; its diet: Diet.EATS's), or {} (none here).
static func of(key: String) -> Dictionary:
	if _full.has(key):
		return _full[key]
	if not TABLE.has(key) and not _more.has(key):
		return {}
	var e: Dictionary = DEFAULTS.duplicate()
	e.merge(TABLE[key] if TABLE.has(key) else _more[key], true)
	e["key"] = key
	var diet := {}
	var sc: Script = load(DIR + String(e.script))
	while sc and diet.is_empty():
		diet = Diet.EATS.get(sc.resource_path.get_file(), {})
		sc = sc.get_base_script()
	e["diet"] = diet
	var anywhere := false
	var prey := []
	for k: String in diet:
		if k in Diet.EVERYWHERE:
			anywhere = true
		elif k not in Diet.NOT_PREY and not k.begins_with("dead_"):
			prey.append(k)
	e["anywhere"] = anywhere # (eats what's always under it: grass, leaves, litter)
	e["prey"] = prey
	_full[key] = e
	return e


## Every kind's key.
static func keys() -> Array:
	return TABLE.keys() + _more.keys()


## Another kind, or one of TABLE's again with its figures changed (its
## entry as TABLE's: at the least its script).
static func register(key: String, entry: Dictionary) -> void:
	_more[key] = entry
	_full.erase(key)
	_by_file.clear()
	_hunts.clear()


## How many of a kind to the square kilometre in a biome (its name).
static func density_in(key: String, biome: String) -> float:
	var d: Dictionary = of(key).get("density", {})
	return float(d.get(biome, d.get("*", 0.0)))


## The key of a creature's kind (by its script, or one it's made from), or "".
static func key_of(c: Node) -> String:
	if _by_file.is_empty():
		for k: String in keys():
			_by_file[String((TABLE[k] if TABLE.has(k) else _more[k]).script)] = k
	var sc: Script = c.get_script() if c else null
	while sc:
		var k: Variant = _by_file.get(sc.resource_path.get_file())
		if k != null:
			return k
		sc = sc.get_base_script()
	return ""


## What b is called as food.
static func kind(key: String, young: bool) -> String:
	var e := of(key)
	return String(e.get("young_kind" if young else "kind", ""))


## Whether a hunts b (grown, or its young), and how much it likes it (0: no).
static func hunts(a: String, b: String, b_young := false) -> float:
	var id := "%s>%s%s" % [a, b, "y" if b_young else ""]
	if _hunts.has(id):
		return _hunts[id]
	var k := kind(b, b_young)
	var ea := of(a)
	var out := 0.0
	if k != "" and not ea.is_empty() and (ea.prey as Array).has(k):
		out = float((ea.diet as Dictionary)[k])
	_hunts[id] = out
	return out


## Its body: made, put under parent at `at` facing yaw, on the ground
## `height` gives ((x, z) -> y; none: level).
static func make(key: String, parent: Node, at: Vector3, yaw := 0.0, male := false, young := false, height := Callable()) -> Creature:
	var e := of(key)
	if e.is_empty():
		return null
	var sc: GDScript = load(DIR + String(e.script))
	var c: Creature = sc.new(young)
	c.set("male", male and not young)
	if height.is_valid() and "height" in c:
		c.set("height", height)
	parent.add_child(c)
	c.set_meta("home", at)
	if c.has_method("place"):
		c.call("place", at, yaw)
	else:
		c.position = at
	return c


## The name a body has for a verb ("": it has none).
static func verb(c: Creature, canon: String) -> String:
	var has := c.behaviours()
	for n: String in VERBS.get(canon, []):
		if has.has(n):
			return n
	return ""


## A young one's body made its mother's: hers to follow, among her young
## (each kind's own names for them).
static func link(mom: Creature, y: Creature) -> void:
	for f: String in ["_mother", "mother"]:
		if f in y:
			y.set(f, mom)
			break
	for f: String in ["young_ones", "leverets", "pups", "kits"]:
		if f in mom:
			var l: Array = mom.get(f)
			if not l.has(y):
				l.append(y)
			break
	if y.get("_mode") is String and y.get("_mode") in ["idle", "wander", ""]:
		y.set("_mode", "follow")
