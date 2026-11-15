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
## }
## Times are the sandbox's (quick to watch); Fauna.life_rate scales them.
## Only what's here has a brain: add a line for another (its script's
## _init(young), `male`, `height`, place(at, yaw), as the walkers have).

const DIR := "res://scripts/creatures/"
const DEFAULTS := {"kind": "", "young_kind": "", "len": 1.0, "walk": 0.6, "run": 2.5, "active": "any", "range": 8.0, "wary": 6.0, "sense": 12.0,
		"meal": 25.0, "fast": 150.0, "awake": 300.0, "nap": 40.0, "herd": false}
const TABLE := {
	"deer": {"script": "deer.gd", "kind": "deer", "young_kind": "fawn", "len": 1.8, "walk": 0.9, "run": 4.5, "range": 10.0, "wary": 8.0, "fast": 90.0, "herd": true},
	"moose": {"script": "moose.gd", "young_kind": "moose_calf", "len": 2.8, "walk": 1.0, "run": 4.0, "range": 10.0, "wary": 5.0, "fast": 90.0},
	"bison": {"script": "bison.gd", "young_kind": "bison_calf", "len": 3.0, "walk": 0.75, "run": 4.0, "range": 10.0, "wary": 4.0, "fast": 80.0, "herd": true},
	"wolf": {"script": "grey_wolf.gd", "young_kind": "wolf_pup", "len": 1.5, "walk": 0.8, "run": 5.0, "range": 11.0, "sense": 16.0, "fast": 240.0, "active": "night", "herd": true},
	"coyote": {"script": "coyote.gd", "kind": "coyote", "len": 1.1, "walk": 0.7, "run": 4.5, "range": 10.0, "fast": 200.0, "active": "night"},
	"fox": {"script": "red_fox.gd", "kind": "fox", "young_kind": "fox_kit", "len": 0.9, "walk": 0.6, "run": 4.0, "range": 9.0, "fast": 180.0, "active": "night"},
	"bobcat": {"script": "bobcat.gd", "young_kind": "bobcat_kit", "len": 0.9, "walk": 0.55, "run": 4.5, "range": 9.0, "fast": 220.0, "active": "night"},
	"black_bear": {"script": "black_bear.gd", "young_kind": "black_cub", "len": 1.7, "walk": 0.75, "run": 3.5, "range": 10.0, "fast": 160.0, "active": "day"},
	"brown_bear": {"script": "brown_bear.gd", "len": 2.2, "walk": 0.8, "run": 3.5, "range": 10.0, "fast": 160.0, "active": "day"},
	"hare": {"script": "hare.gd", "kind": "hare", "young_kind": "leveret", "len": 0.5, "walk": 0.9, "run": 5.0, "range": 7.0, "wary": 7.0, "fast": 80.0, "active": "night"},
	"mouse": {"script": "mouse.gd", "kind": "mouse", "young_kind": "mouse_pup", "len": 0.09, "walk": 0.14, "run": 0.6, "range": 2.0, "wary": 2.5, "fast": 60.0, "active": "night"},
	"fox_squirrel": {"script": "fox_squirrel.gd", "kind": "squirrel", "len": 0.3, "walk": 0.85, "run": 2.5, "range": 6.0, "wary": 5.0, "fast": 80.0, "active": "day"},
	"grey_squirrel": {"script": "grey_squirrel.gd", "kind": "squirrel", "len": 0.28, "walk": 0.9, "run": 2.5, "range": 6.0, "wary": 5.0, "fast": 80.0, "active": "day"},
	"opossum": {"script": "opossum.gd", "len": 0.5, "walk": 0.24, "run": 1.0, "range": 6.0, "fast": 140.0, "active": "night"},
	"porcupine": {"script": "porcupine.gd", "kind": "porcupine", "young_kind": "porcupette", "len": 0.7, "walk": 0.19, "run": 0.6, "range": 5.0, "wary": 2.0, "fast": 120.0, "active": "night"},
	"armadillo": {"script": "armadillo.gd", "kind": "armadillo", "young_kind": "armadillo_pup", "len": 0.5, "walk": 0.22, "run": 1.5, "range": 6.0, "wary": 3.0, "fast": 100.0, "active": "night"},
	"turkey": {"script": "wild_turkey.gd", "kind": "turkey", "young_kind": "poult", "len": 1.0, "walk": 0.7, "run": 3.0, "range": 8.0, "wary": 7.0, "fast": 90.0, "active": "day", "herd": true},
}
## A brain's verbs, each by the names the animals have for it (the first
## its body has, Creature.behaviours()).
const VERBS := {
	"eat": ["graze", "browse", "forage", "nibble", "eat"],
	"hunt": ["hunt"],
	"sleep": ["sleep", "bed", "ruminate", "sit"],
	"groom": ["groom", "preen", "wallow", "dust"],
	"alert": ["alert", "freeze", "stand", "flick"],
	"flee": ["flee"],
	"social": ["mark", "howl", "strut", "gobble", "thump", "rub"],
}

static var _full := {} # key -> its entry, filled in
static var _by_file := {} # a script's file -> key
static var _hunts := {} # "a>b" -> bool


## Its entry (the defaults filled in; its diet: Diet.EATS's), or {} (none here).
static func of(key: String) -> Dictionary:
	if _full.has(key):
		return _full[key]
	if not TABLE.has(key):
		return {}
	var e: Dictionary = DEFAULTS.duplicate()
	e.merge(TABLE[key], true)
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


## The key of a creature's kind (by its script, or one it's made from), or "".
static func key_of(c: Node) -> String:
	if _by_file.is_empty():
		for k: String in TABLE:
			_by_file[String((TABLE[k] as Dictionary).script)] = k
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
