class_name Diet
extends RefCounted
## What every creature eats, and finding it: only what's there. Nothing is
## ever made for a creature to eat: a meal is something in the world (an
## animal, a carcass, a fallen fruit, a nut, a flower, a fish), found near
## it, or nothing (and then it doesn't eat). For a state machine: Diet.find
## (the creature, how far) gives the nearest real food of its diet, and
## what to do with it (Diet.how: the creature's own call); none, null.
##
## kind_of(node) names a thing as food: the animals (their young their
## own: a fawn, a mouse_pup); "dead_<kind>" a dead one; "carcass" a big
## one's (Carcass, fresh or rotting); "fish" a school of trout or salmon,
## "mollies"; the game's items by their id (acorn, walnut, pawpaw,
## crabapple, stick, and the mushrooms: morel, fly_agaric, little_brown,
## chicken_of_the_woods); plants by their kind ("flowers": any in flower,
## "berries" a blueberry's or a raspberry's bush, "sapling" a maple's,
## "forbs" yampah, fleabane, a black-eyed Susan); "ants" an ant colony's
## nest; "wasp_comb" a paper wasp's comb; "flier" a small flying insect
## (a trigonalid, an ichneumon, a paper wasp).
## Some eat what's always under them (grass, leaves, the ground's litter,
## algae: "graze", "leaf", "litter", "algae", "blood"): no finding.

## Each creature's diet, by its script's file: the kinds it eats, each with
## its affinity for it (0..1): 1 its staple, what it takes first; ~0.6 a
## regular meal; ~0.3 now and then; ~0.1 rare, taken only by chance (as
## the biology has it: the most of its diet by bulk or by how often it's
## seen eating it, and how readily it goes for it when there's a choice).
const EATS := {
	"red_fox.gd": {"armadillo_pup": 0.2, "gosling": 0.4, "mouse": 1.0, "mouse_pup": 0.9, "hare": 0.6, "leveret": 0.7, "squirrel": 0.5, "grasshopper": 0.5, "grub": 0.4, "berries": 0.6, "pawpaw": 0.5,
			"crabapple": 0.4, "carcass": 0.5, "dead_mouse": 0.6, "frog": 0.3, "toad": 0.1, "fawn": 0.15, "beaver_kit": 0.15, "bobcat_kit": 0.1, "snake_young": 0.2,
			"ants": 0.2, "wasp_comb": 0.2},
	"bobcat.gd": {"porcupine": 0.05, "porcupette": 0.2, "armadillo": 0.15, "armadillo_pup": 0.3, "hare": 1.0, "leveret": 0.9, "squirrel": 0.7, "mouse": 0.7, "poult": 0.5, "fawn": 0.4, "deer": 0.2, "fox": 0.1, "fox_kit": 0.2, "beaver_kit": 0.2,
			"grasshopper": 0.15, "snake": 0.2, "carcass": 0.25},
	"coyote.gd": {"porcupine": 0.05, "porcupette": 0.15, "armadillo": 0.2, "armadillo_pup": 0.3, "gosling": 0.4, "goose": 0.1, "mouse": 1.0, "mouse_pup": 0.8, "hare": 0.8, "leveret": 0.8, "squirrel": 0.5, "fawn": 0.6, "carcass": 0.7, "dead_mouse": 0.6, "berries": 0.5,
			"pawpaw": 0.5, "crabapple": 0.5, "grasshopper": 0.4, "grub": 0.3, "poult": 0.4, "frog": 0.2, "toad": 0.1, "snake": 0.2, "beaver": 0.2, "otter_pup": 0.1,
			"fox": 0.1, "fox_kit": 0.2, "bobcat_kit": 0.1},
	"grey_wolf.gd": {"porcupine": 0.05, "deer": 1.0, "fawn": 0.9, "moose_calf": 0.8, "bison_calf": 0.6, "beaver": 0.6, "carcass": 0.6, "hare": 0.4, "mouse": 0.2, "otter_pup": 0.1,
			"coyote": 0.1, "fox": 0.1},
	"german_shepherd.gd": {"hare": 0.4, "leveret": 0.4, "mouse": 0.3, "squirrel": 0.3, "carcass": 0.6, "dead_mouse": 0.5},
	"labrador_retriever.gd": {"hare": 0.3, "leveret": 0.3, "mouse": 0.2, "squirrel": 0.2, "carcass": 0.8, "dead_mouse": 0.7},
	"beagle.gd": {"hare": 0.6, "leveret": 0.6, "mouse": 0.3, "squirrel": 0.3, "carcass": 0.7, "dead_mouse": 0.6},
	"black_bear.gd": {"armadillo": 0.05, "armadillo_pup": 0.1, "berries": 1.0, "acorn": 0.9, "walnut": 0.7, "grub": 0.7, "ants": 0.7, "pawpaw": 0.7, "crabapple": 0.6, "carcass": 0.6, "fawn": 0.4,
			"fish": 0.3, "chicken_of_the_woods": 0.3, "morel": 0.3, "mouse_pup": 0.2, "squirrel": 0.1, "hare": 0.1, "mouse": 0.1, "moose_calf": 0.15, "beaver": 0.1,
			"bobcat_kit": 0.05},
	"brown_bear.gd": {"fish": 1.0, "berries": 1.0, "carcass": 0.8, "moose_calf": 0.6, "bison_calf": 0.4, "fawn": 0.5, "deer": 0.3, "grub": 0.5, "ants": 0.5,
			"acorn": 0.4, "walnut": 0.4, "pawpaw": 0.4, "crabapple": 0.4, "beaver": 0.2, "squirrel": 0.2, "mouse": 0.15, "hare": 0.15, "morel": 0.2,
			"chicken_of_the_woods": 0.2, "black_cub": 0.05, "wolf_pup": 0.05},
	"opossum.gd": {"carcass": 0.9, "dead_mouse": 0.8, "grub": 0.8, "snails": 0.8, "pawpaw": 0.8, "crabapple": 0.7, "berries": 0.7, "grasshopper": 0.6, "nymph": 0.6,
			"caterpillar": 0.6, "mouse": 0.4, "mouse_pup": 0.5, "frog": 0.4, "toad": 0.3, "anole": 0.2, "snake": 0.2, "snake_young": 0.3, "morel": 0.2,
			"chicken_of_the_woods": 0.2, "nestling": 0.2},
	"porcupine.gd": {"sapling": 1.0, "forbs": 0.8, "flowers": 0.5, "crabapple": 0.6, "acorn": 0.6, "berries": 0.4}, # (leaves, buds, a tree's bark (climbing it, Porcupine.climb: not food set out), fruit, mast)
	"armadillo.gd": {"grub": 1.0, "beetle": 0.8, "ants": 0.8, "caterpillar": 0.7, "pillbug": 0.6, "snails": 0.5, "spider": 0.5, "nymph": 0.5, "grasshopper": 0.4,
			"pawpaw": 0.2, "crabapple": 0.15, "frog": 0.1, "anole": 0.1, "mouse_pup": 0.05},
	"deer.gd": {"graze": 1.0, "morel": 0.3, "chicken_of_the_woods": 0.3, "fly_agaric": 0.1, "mouse_pup": 0.05},
	"moose.gd": {"graze": 1.0, "morel": 0.2, "fly_agaric": 0.1},
	"bison.gd": {"graze": 1.0},
	"mouse.gd": {"acorn": 1.0, "walnut": 0.8, "berries": 0.8, "caterpillar": 0.6, "grub": 0.5, "nymph": 0.5, "snails": 0.3, "pillbug": 0.3, "mantis_nymph": 0.2,
			"little_brown": 0.3, "morel": 0.2},
	"fox_squirrel.gd": {"walnut": 1.0, "acorn": 1.0, "caterpillar": 0.2, "grub": 0.2, "morel": 0.3, "chicken_of_the_woods": 0.3, "fly_agaric": 0.15, "mouse_pup": 0.05},
	"grey_squirrel.gd": {"acorn": 1.0, "walnut": 0.9, "caterpillar": 0.2, "grub": 0.2, "morel": 0.3, "chicken_of_the_woods": 0.3, "fly_agaric": 0.15, "mouse_pup": 0.05},
	"hare.gd": {"forbs": 1.0, "sapling": 0.7, "dead_mouse": 0.05, "carcass": 0.05},
	"beaver.gd": {"sapling": 1.0, "stick": 0.6},
	"river_otter.gd": {"fish": 1.0, "crayfish": 0.8, "frog": 0.4, "toad": 0.1},
	"sea_otter.gd": {"urchin": 1.0, "clam": 0.9}, # (on the bottom: SeaOtter.clam(), urchin(), meta "shellfish")
	"wild_turkey.gd": {"acorn": 1.0, "walnut": 0.5, "berries": 0.7, "grasshopper": 0.7, "nymph": 0.6, "grub": 0.5, "caterpillar": 0.5},
	"peregrine_falcon.gd": {"pigeon": 1.0, "blackbird": 0.6, "robin": 0.5, "bluebird": 0.3, "finch": 0.2, "poult": 0.5, "squirrel": 0.2, "mouse": 0.2},
	"coopers_hawk.gd": {"robin": 0.9, "pigeon": 0.8, "blackbird": 0.8, "bluebird": 0.7, "finch": 0.7, "nestling": 0.5, "poult": 0.7, "squirrel": 0.6, "mouse": 0.4},
	"barn_owl.gd": {"mouse": 1.0, "grasshopper": 0.15, "nymph": 0.1, "grub": 0.1, "spider": 0.05},
	"eastern_screech_owl.gd": {"mouse": 1.0, "mouse_pup": 0.8, "grasshopper": 0.7, "nymph": 0.6, "caterpillar": 0.5, "grub": 0.4, "crayfish": 0.4, "frog": 0.4,
			"snails": 0.2, "anole": 0.2, "fish": 0.15, "bluebird": 0.15, "blackbird": 0.1, "finch": 0.2, "hummingbird": 0.05, "nestling": 0.15, "bat": 0.15},
	"great_horned_owl.gd": {"porcupette": 0.05, "armadillo_pup": 0.1, "gosling": 0.2, "hare": 1.0, "leveret": 0.9, "mouse": 0.8, "squirrel": 0.6, "poult": 0.4, "pigeon": 0.3, "blackbird": 0.1, "bat": 0.1},
	"bald_eagle.gd": {"fish": 1.0, "carcass": 0.8, "poult": 0.2, "hare": 0.2, "leveret": 0.2, "gosling": 0.3, "goose": 0.1},
	"golden_eagle.gd": {"hare": 1.0, "leveret": 0.9, "squirrel": 0.7, "poult": 0.4, "carcass": 0.5},
	"anole.gd": {"nymph": 0.8, "grasshopper": 0.7, "spider": 0.8, "caterpillar": 0.6, "grub": 0.3},
	"scorpion.gd": {"nymph": 0.8, "grasshopper": 0.6, "spider": 0.6, "grub": 0.4},
	"gila_monster.gd": {"mouse_pup": 1.0, "poult": 0.6, "leveret": 0.6, "mouse": 0.3, "hare": 0.1},
	"snake.gd": {"mouse": 1.0, "mouse_pup": 0.9, "frog": 0.5, "toad": 0.4, "anole": 0.4, "snake_young": 0.2, "nestling": 0.4},
	"snapping_turtle.gd": {"gosling": 0.4, "fish": 0.8, "carcass": 0.8, "dead_fish": 0.9, "crayfish": 0.7, "frog": 0.6, "toad": 0.2, "grass_snail": 0.5, "tigersnail": 0.5, "nymph": 0.5},
	"painted_turtle.gd": {"nymph": 0.9, "crayfish": 0.5, "grass_snail": 0.6, "tigersnail": 0.6, "dead_fish": 0.6, "carcass": 0.4, "fish": 0.2, "grasshopper": 0.3},
	"american_robin.gd": {"grub": 1.0, "caterpillar": 0.8, "beetle": 0.7, "spider": 0.5, "snails": 0.4, "ants": 0.3},
	"eastern_bluebird.gd": {"caterpillar": 1.0, "beetle": 0.9, "grub": 0.6, "spider": 0.6, "ants": 0.4, "snails": 0.3},
	"passenger_pigeon.gd": {"acorn": 1.0, "grub": 0.3, "caterpillar": 0.3, "snails": 0.25},
	"red_winged_blackbird.gd": {"caterpillar": 1.0, "nymph": 0.9, "grasshopper": 0.8, "beetle": 0.7, "grub": 0.6, "spider": 0.6, "snails": 0.3},
	"ruby_throated_hummingbird.gd": {"flowers": 1.0, "forbs": 0.8, "flier": 0.3}, # (nectar, its tongue in the flower; small insects caught in the air)
	"great_blue_heron.gd": {"mollies": 1.0, "fish": 0.9, "frog": 0.7, "crayfish": 0.6, "mouse": 0.4, "toad": 0.2, "snake_young": 0.2, "grasshopper": 0.15},
	"canada_goose.gd": {"graze": 1.0, "algae": 0.5}, # (grass, the water's weeds: its goslings' too)
	"american_goldfinch.gd": {"forbs": 1.0, "flowers": 0.9}, # (seeds only, its young's too: Finch)
	"house_finch.gd": {"forbs": 1.0, "flowers": 0.9, "berries": 0.6},
	"bat.gd": {"beetle": 1.0, "moth": 0.7, "flier": 0.5},
	"american_toad.gd": {"ants": 1.0, "grub": 0.6, "spider": 0.7, "caterpillar": 0.6, "nymph": 0.6, "grasshopper": 0.4, "snails": 0.5},
	"frog.gd": {"nymph": 0.8, "grasshopper": 1.0, "spider": 0.7, "caterpillar": 0.6, "grub": 0.4, "snails": 0.4},
	"turtle.gd": {"snails": 1.0, "grub": 0.8, "berries": 0.9, "crabapple": 0.8, "pawpaw": 0.8, "morel": 0.7, "little_brown": 0.6, "fly_agaric": 0.4, "pillbug": 0.6,
			"nymph": 0.5, "grasshopper": 0.4},
	"crayfish.gd": {"dead_fish": 1.0, "dead_mouse": 0.7, "snails": 0.6, "nymph": 0.6, "grub": 0.4},
	"shrimp.gd": {"algae": 1.0, "litter": 0.8, "dead_fish": 0.5},
	"spider.gd": {"grasshopper": 1.0, "nymph": 1.0, "flier": 0.8, "caterpillar": 0.6, "grub": 0.3, "bee": 0.5, "firefly": 0.3, "monarch": 0.2, "mollies": 0.1},
	"mantis.gd": {"hummingbird": 0.05, "grasshopper": 1.0, "nymph": 0.9, "caterpillar": 0.6, "spider": 0.4, "grub": 0.2},
	"dragonfly.gd": {"flier": 1.0, "mollies": 0.2, "monarch": 0.15, "swallowtail": 0.15},
	"wasp.gd": {"caterpillar": 1.0, "flowers": 0.8, "grub": 0.4, "nymph": 0.3, "grasshopper": 0.2, "spider": 0.2},
	"trigonalid.gd": {"flowers": 1.0},
	"ichneumon.gd": {"flowers": 1.0},
	"bumblebee.gd": {"flowers": 1.0},
	"monarch.gd": {"flowers": 1.0},
	"swallowtail.gd": {"flowers": 1.0},
	"hummingbird_moth.gd": {"flowers": 1.0},
	"mourning_cloak.gd": {"crabapple": 1.0, "pawpaw": 0.9},
	"harvester_ants.gd": {"acorn": 0.4, "walnut": 0.3, "nymph": 0.6, "grasshopper": 0.5},
	"ant_colony.gd": {"carcass": 0.8, "grub": 0.8, "caterpillar": 0.9, "nymph": 0.8, "grasshopper": 0.6},
	"luna_moth.gd": {}, # (the grown moths don't eat)
	"cecropia_moth.gd": {},
	"polyphemus_moth.gd": {},
	"sea_turtle.gd": {}, # (its seagrass isn't in the game)
	"larva.gd": {"leaf": 1.0},
	"grasshopper.gd": {"graze": 1.0},
	"isopod.gd": {"litter": 1.0},
	"snails.gd": {"leaf": 1.0},
	"fireflies.gd": {"snails": 1.0}, # (the glowworm larvae's)
	"ticks.gd": {"blood": 1.0},
	"mollies.gd": {"algae": 1.0},
	"fish_school.gd": {"nymph": 1.0, "grasshopper": 0.8, "crayfish": 0.6, "mollies": 0.5, "fish": 0.3},
}

## (A kind that stands for several: "snails", any snail.)
const ALIASES := {"snails": ["snails", "grass_snail", "tigersnail"]}

## Kinds that live as colonies, eaten one at a time (one_of: the nearest
## taken out of its colony, a body of its own to be eaten).
const ONE_AT_A_TIME := ["snails", "grass_snail", "tigersnail", "firefly", "beetle"]

## Colonies some eat a member of without touching the colony (a toad's
## ant: its tongue flicked at one at the nest's edge): copy_of, a single
## copy of one of them, eaten; the colony as it was. By the eater's script.
const COPIES_FOR := {"american_toad.gd": ["ants"], "american_robin.gd": ["ants"], "eastern_bluebird.gd": ["ants"]}

## What isn't hunted (no animal to run down: carrion, plants, the game's
## items, a colony eaten whole where it is, what's always under it).
const NOT_PREY := ["carcass", "dead_mouse", "dead_fish", "berries", "forbs", "flowers", "sapling", "stick", "ants", "wasp_comb",
		"fish", "mollies", "clam", "urchin", "acorn", "walnut", "pawpaw", "crabapple", "morel", "fly_agaric", "chicken_of_the_woods",
		"little_brown", "graze", "leaf", "litter", "algae", "blood"]

## (A plant's: eaten from where it grows, nothing taken off it (a bush's
## berries left hanging, a flower's nectar); never one creature's alone.)
const SHARED := ["berries", "flowers", "forbs", "sapling"]

## (Those that eat from what's always under them: no finding.)
const EVERYWHERE := ["graze", "leaf", "litter", "algae", "blood"]
const FORBS := ["yampah", "fleabane", "susan"]
const BERRIES := ["g_blueberry", "g_raspberry"]


## Its diet (by its script; a subclass's, its parent script's): the kinds.
static func of(c: Node) -> Array:
	return _table(c).keys()


## How much c likes kind (0..1, Diet.EATS: 1 its staple, ~0.1 a rare meal):
## 0 if it doesn't eat it. A snail of any kind counts as "snails".
static func affinity(c: Node, kind: String) -> float:
	var t := _table(c)
	if t.has(kind):
		return float(t[kind])
	if kind.begins_with("dead_") and t.has(kind.substr(5)): # (a dead one of what it hunts: as its live one)
		return float(t[kind.substr(5)])
	for k: String in ALIASES:
		if kind in (ALIASES[k] as Array) and t.has(k):
			return float(t[k])
	return 0.0


static func _table(c: Node) -> Dictionary:
	var sc: Script = c.get_script() if c else null
	while sc:
		var f := sc.resource_path.get_file()
		if EATS.has(f):
			return EATS[f]
		sc = sc.get_base_script()
	return {}


## What c hunts (its diet's animals, run down, caught).
static func prey_of(c: Node) -> Array:
	var copies := copies_for(c)
	return of(c).filter(func(k: String) -> bool: return k not in NOT_PREY or k in copies)


## The colonies c eats one of as a copy (COPIES_FOR, by its script or a parent's).
static func copies_for(c: Node) -> Array:
	var sc: Script = c.get_script() if c else null
	while sc:
		var f := sc.resource_path.get_file()
		if COPIES_FOR.has(f):
			return COPIES_FOR[f]
		sc = sc.get_base_script()
	return []


## Its diet for an act: hunting (hunt, strike, catch) its prey; else all
## of it.
static func for_act(c: Node, act: String) -> Array:
	return prey_of(c) if act in ["hunt", "strike", "catch", "feed_on_insect"] else of(c)


## (Kinds, the aliases opened out.)
static func expand(kinds: Array) -> Array:
	var out := []
	for k: String in kinds:
		for e: String in ALIASES.get(k, [k]):
			if not out.has(e):
				out.append(e)
	return out


## A thing named as food (or "", nothing to eat).
static func kind_of(n: Node) -> String:
	if n == null or not is_instance_valid(n):
		return ""
	if n.has_meta("carcass"):
		return "carcass" if int(n.get_meta("carcass")) <= 2 else ""
	if n.has_meta("from_colony"):
		return String(n.get_meta("from_colony"))
	if n.has_meta("shellfish"):
		return String(n.get_meta("shellfish"))
	if n.has_meta("comb_cells"):
		return "wasp_comb"
	if n.has_meta("item"):
		return String(n.get_meta("item"))
	if n.has_meta("plant"):
		var k := String(n.get_meta("plant"))
		if k in BERRIES:
			return "berries"
		if k.ends_with("maple") and k.begins_with("s_"):
			return "sapling"
		if k in FORBS:
			return "forbs"
		if not (n.get_meta("heads", []) as Array).is_empty() or not (n.get_meta("florets", []) as Array).is_empty():
			return "flowers"
		return ""
	var sc: Script = n.get_script()
	if sc == null:
		return "dead_fish" if n.name == "fish" and n.get_meta("dead", false) else ""
	var f := sc.resource_path.get_file()
	var young: bool = n.get("young") == true
	var k := ""
	match f:
		"mouse.gd":
			k = "mouse_pup" if young else "mouse"
		"porcupine.gd":
			k = "porcupette" if young else "porcupine"
		"armadillo.gd":
			k = "armadillo_pup" if young else "armadillo"
		"fox_squirrel.gd", "grey_squirrel.gd":
			k = "squirrel"
		"hare.gd":
			k = "leveret" if young else "hare"
		"deer.gd":
			k = "fawn" if young else "deer"
		"wild_turkey.gd":
			k = "poult" if young else "turkey"
		"moose.gd":
			k = "moose_calf" if young else ""
		"bison.gd":
			k = "bison_calf" if young else ""
		"beaver.gd":
			k = "beaver_kit" if young else "beaver"
		"river_otter.gd":
			k = "otter_pup" if young else ""
		"red_swamp_crayfish.gd", "virile_crayfish.gd":
			k = "crayfish"
		"red_fox.gd":
			k = "fox_kit" if young else "fox"
		"coyote.gd":
			k = "" if young else "coyote"
		"bobcat.gd":
			k = "bobcat_kit" if young else ""
		"black_bear.gd":
			k = "black_cub" if young else ""
		"grey_wolf.gd":
			k = "wolf_pup" if young else ""
		"larva.gd":
			var lk := String(n.get("kind"))
			k = "grub" if lk == "june" else ("caterpillar" if lk in ["monarch", "hemaris", "swallowtail", "luna", "cloak", "cecropia", "polyphemus"] else "")
		"grasshopper.gd", "differential_grasshopper.gd", "blue_winged_grasshopper.gd":
			k = "nymph" if n.get("nymph") == true else "grasshopper"
		"isopod.gd":
			k = "pillbug"
		"mantis.gd":
			k = "mantis_nymph" if n.get("nymph") == true else ""
		"frog.gd", "american_toad.gd":
			if float(n.get("dev") if n.get("dev") != null else 1.0) >= 1.0 or not young:
				k = "toad" if f == "american_toad.gd" else "frog"
		"anole.gd":
			k = "anole"
		"snake.gd":
			k = "snake_young" if young else "snake"
		"fish_school.gd":
			k = "fish" if String(n.get("kind")) in ["rainbow", "chinook"] else ""
		"mollies.gd":
			k = "mollies"
		"trigonalid.gd", "ichneumon.gd", "wasp.gd":
			k = "flier"
		"bumblebee.gd":
			k = "bee"
		"monarch.gd":
			k = "monarch"
		"swallowtail.gd":
			k = "swallowtail"
		"spider.gd":
			k = "spider"
		"fireflies.gd":
			k = "firefly"
		"ant_colony.gd", "harvester_ants.gd":
			k = "ants"
		"bat.gd":
			k = "bat_pup" if young else "bat"
		"luna_moth.gd", "cecropia_moth.gd", "polyphemus_moth.gd":
			k = "moth"
		"passenger_pigeon.gd":
			k = "nestling" if young else "pigeon"
		"red_winged_blackbird.gd":
			k = "nestling" if young else "blackbird"
		"american_robin.gd":
			k = "nestling" if young else "robin"
		"eastern_bluebird.gd":
			k = "nestling" if young else "bluebird"
		"canada_goose.gd":
			k = "gosling" if young else "goose"
		"great_blue_heron.gd":
			k = "nestling" if young else "heron"
		"ruby_throated_hummingbird.gd":
			k = "nestling" if young else "hummingbird"
		"american_goldfinch.gd", "house_finch.gd":
			k = "nestling" if young else "finch"
		"june_beetles.gd":
			k = "beetle"
		"lady_beetles.gd":
			k = "lady_beetle"
		"grass_snails.gd":
			k = "grass_snail"
		"flamed_tigersnails.gd":
			k = "tigersnail"
		"snails.gd":
			k = "snails"
	if k != "" and n.get("dead") == true:
		return "dead_" + k
	return k


## The best real food of c's diet (or of kinds) in its parent, within r m:
## alive (or a carcass), not another's quarry already; or null. Best: the
## nearest by its distance over c's affinity for it (affinity: a staple a
## few times as far off still before a rare meal at its feet). (For what's
## always under it, EVERYWHERE: c itself.) any_: a rarer meal: any of it
## there, at random, the less it's liked the likelier.
static func find(c: Node3D, r := 30.0, kinds: Array = [], any_ := false) -> Node:
	if c == null or c.get_parent() == null:
		return null
	var want: Array = expand(kinds if not kinds.is_empty() else of(c))
	for k: String in want:
		if k in EVERYWHERE:
			return c
	var p := _at(c)
	var best: Node = null
	var bd := INF
	var all := []
	var weights := []
	for o in c.get_parent().get_children():
		if o == c or not (o is Node3D):
			continue
		var k := kind_of(o)
		if k == "" or not want.has(k):
			continue
		if o.has_meta("hunted") and is_instance_valid(o.get_meta("hunted")) and o.get_meta("hunted") != c and k not in SHARED:
			continue
		if o.has_meta("taken") and not o.has_meta("keep"):
			continue
		var d := _at(o as Node3D).distance_to(p)
		if d >= r:
			continue
		var a := affinity(c, k)
		if a <= 0.0: # (a kind asked for that isn't in its table: middling)
			a = 0.5
		all.append(o)
		weights.append(1.05 - a)
		if d / maxf(a, 0.05) < bd:
			bd = d / maxf(a, 0.05)
			best = o
	if any_ and not all.is_empty():
		var tot := 0.0
		for w: float in weights:
			tot += w
		var x := randf() * tot
		for i in all.size():
			x -= float(weights[i])
			if x <= 0.0:
				return all[i]
		return all[all.size() - 1]
	return best


## As find, but one of a colony (a snail of its band, a firefly of its
## swarm) taken out of it: a body of its own where it was, to be eaten.
static func find_one(c: Node3D, r := 30.0, kinds: Array = [], any_ := false) -> Node:
	var f := find(c, r, kinds, any_)
	if f != null and f != c and kind_of(f) in copies_for(c): # (one of them copied, to be eaten: the colony untouched)
		return copy_of(f as Node3D, _at(c))
	if f != null and f != c and kind_of(f) in ONE_AT_A_TIME:
		return one_of(f as Node3D, _at(c))
	return f


## A single copy of colony's member nearest p (its mesh, its look, where it
## is), a body of its own to be eaten; the colony itself as it was, none of
## it taken. Null if it has none.
static func copy_of(colony: Node3D, p: Vector3) -> Node3D:
	var mm: MultiMesh = (colony as MultiMeshInstance3D).multimesh if colony is MultiMeshInstance3D else null
	var ps: Variant = colony.get("pos")
	if mm == null or not (ps is PackedVector3Array) or (ps as PackedVector3Array).is_empty():
		return null
	var pos: PackedVector3Array = ps
	var lp := colony.to_local(colony.get_parent().to_global(p)) if colony.is_inside_tree() else p
	var best := -1
	var bd := INF
	for i in mini(pos.size(), mm.instance_count):
		var d := pos[i].distance_to(lp)
		if d < bd:
			bd = d
			best = i
	if best < 0:
		return null
	var body := MeshInstance3D.new()
	body.name = "%s_copy" % kind_of(colony)
	body.mesh = mm.mesh
	body.material_override = (colony as MultiMeshInstance3D).material_override
	colony.get_parent().add_child(body)
	body.global_transform = colony.global_transform * mm.get_instance_transform(best)
	body.set_meta("from_colony", kind_of(colony))
	body.set_meta("copy", true)
	return body


## The member of colony nearest p taken out of it: dead to it (Snails.die;
## moved off, out of sight), and a body of its own in its place (its mesh,
## its look, where it was), to be eaten. Null if none's left.
static func one_of(colony: Node3D, p: Vector3) -> Node3D:
	var mm: MultiMesh = (colony as MultiMeshInstance3D).multimesh if colony is MultiMeshInstance3D else null
	var ps: Variant = colony.get("pos")
	if mm == null or not (ps is PackedVector3Array):
		return null
	var pos: PackedVector3Array = ps
	var lp := colony.to_local(colony.get_parent().to_global(p)) if colony.is_inside_tree() else p
	var best := -1
	var bd := INF
	for i in pos.size():
		if colony.has_method("is_dead") and bool(colony.call("is_dead", i)):
			continue
		if pos[i].y < -100.0:
			continue
		var d := pos[i].distance_to(lp)
		if d < bd:
			bd = d
			best = i
	if best < 0:
		return null
	var body := MeshInstance3D.new()
	body.name = "%s_one" % kind_of(colony)
	body.mesh = mm.mesh
	body.material_override = (colony as MultiMeshInstance3D).material_override
	colony.get_parent().add_child(body)
	body.global_transform = colony.global_transform * mm.get_instance_transform(best)
	body.set_meta("from_colony", kind_of(colony))
	if colony.has_method("die"):
		colony.call("die", best)
	pos[best] = Vector3(pos[best].x, -500.0, pos[best].z) # (out of its colony: gone from it)
	colony.set("pos", pos)
	if colony.get("target") is PackedVector3Array:
		var t: PackedVector3Array = colony.get("target")
		t[best] = pos[best]
		colony.set("target", t)
	return body


static func _at(n: Node3D) -> Vector3:
	var q: Variant = n.get("_pos")
	if q is Vector3:
		return q
	var h: Variant = n.get_meta("home", null) if n.has_meta("home") else null
	return h if h is Vector3 else n.position
