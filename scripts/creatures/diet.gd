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

## Each creature's diet, by its script's file: the kinds it eats.
const EATS := {
	"red_fox.gd": ["mouse", "mouse_pup", "squirrel", "hare", "leveret", "grasshopper", "grub", "fawn", "beaver_kit", "bobcat_kit", "snake_young", "carcass", "dead_mouse", "berries", "pawpaw", "crabapple", "ants", "wasp_comb", "frog", "toad"],
	"bobcat.gd": ["hare", "leveret", "squirrel", "mouse", "fawn", "deer", "fox", "fox_kit", "beaver_kit", "grasshopper", "snake", "carcass", "poult"],
	"coyote.gd": ["mouse", "mouse_pup", "hare", "leveret", "squirrel", "fawn", "fox", "fox_kit", "bobcat_kit", "beaver", "otter_pup", "grub", "grasshopper", "snake", "carcass", "dead_mouse", "berries", "pawpaw", "crabapple", "poult", "frog", "toad"],
	"grey_wolf.gd": ["hare", "mouse", "deer", "fawn", "moose_calf", "bison_calf", "beaver", "otter_pup", "coyote", "fox", "carcass"],
	"german_shepherd.gd": ["hare", "leveret", "mouse", "squirrel", "carcass", "dead_mouse"],
	"labrador_retriever.gd": ["hare", "leveret", "mouse", "squirrel", "carcass", "dead_mouse"],
	"beagle.gd": ["hare", "leveret", "mouse", "squirrel", "carcass", "dead_mouse"],
	"black_bear.gd": ["berries", "fish", "carcass", "fawn", "moose_calf", "beaver", "grub", "mouse_pup", "squirrel", "bobcat_kit", "hare", "mouse", "chicken_of_the_woods", "morel", "acorn", "walnut", "pawpaw", "crabapple", "ants"],
	"brown_bear.gd": ["berries", "fish", "carcass", "moose_calf", "bison_calf", "fawn", "deer", "beaver", "grub", "black_cub", "wolf_pup", "hare", "mouse", "squirrel", "chicken_of_the_woods", "morel", "acorn", "walnut", "pawpaw", "crabapple", "ants"],
	"opossum.gd": ["mouse", "mouse_pup", "grasshopper", "nymph", "snake", "snake_young", "toad", "frog", "grub", "caterpillar", "anole", "pawpaw", "crabapple", "carcass", "dead_mouse", "morel", "chicken_of_the_woods", "berries", "snails"],
	"deer.gd": ["graze", "fly_agaric", "morel", "chicken_of_the_woods", "mouse_pup"],
	"moose.gd": ["graze", "fly_agaric", "morel"],
	"bison.gd": ["graze"],
	"mouse.gd": ["acorn", "walnut", "berries", "nymph", "caterpillar", "grub", "pillbug", "mantis_nymph", "snails", "little_brown", "morel"],
	"fox_squirrel.gd": ["walnut", "acorn", "caterpillar", "grub", "mouse_pup", "morel", "fly_agaric", "chicken_of_the_woods"],
	"grey_squirrel.gd": ["walnut", "acorn", "caterpillar", "grub", "mouse_pup", "morel", "fly_agaric", "chicken_of_the_woods"],
	"hare.gd": ["forbs", "dead_mouse", "sapling", "carcass"],
	"beaver.gd": ["sapling", "stick"],
	"river_otter.gd": ["crayfish", "fish", "frog", "toad"],
	"sea_otter.gd": ["clam", "urchin"], # (on the bottom: SeaOtter.clam(), urchin(), meta "shellfish")
	"wild_turkey.gd": ["acorn", "walnut", "berries", "grasshopper", "nymph", "grub", "caterpillar"],
	"peregrine_falcon.gd": ["mouse", "squirrel", "poult"],
	"coopers_hawk.gd": ["mouse", "squirrel", "poult"],
	"barn_owl.gd": ["mouse", "grasshopper", "nymph", "grub", "spider"],
	"eastern_screech_owl.gd": ["mouse", "mouse_pup", "grasshopper", "nymph", "grub", "caterpillar", "frog", "crayfish", "fish", "anole", "snails"],
	"great_horned_owl.gd": ["mouse", "squirrel", "poult", "hare", "leveret"],
	"bald_eagle.gd": ["fish", "carcass", "hare", "leveret", "poult"],
	"golden_eagle.gd": ["hare", "leveret", "squirrel", "poult", "carcass"],
	"anole.gd": ["nymph", "grasshopper", "caterpillar", "grub", "spider"],
	"scorpion.gd": ["nymph", "grasshopper", "grub", "spider"],
	"gila_monster.gd": ["mouse", "mouse_pup", "leveret", "hare", "poult"],
	"snake.gd": ["mouse", "mouse_pup", "frog", "toad", "anole", "snake_young"],
	"snapping_turtle.gd": ["fish", "frog", "toad", "crayfish", "carcass", "dead_fish", "grass_snail", "tigersnail", "nymph"],
	"painted_turtle.gd": ["crayfish", "fish", "dead_fish", "carcass", "grass_snail", "tigersnail", "nymph", "grasshopper"],
	"american_toad.gd": ["ants", "spider", "grub", "caterpillar", "nymph", "grasshopper", "snails"],
	"frog.gd": ["nymph", "grasshopper", "spider", "grub", "caterpillar", "snails"],
	"turtle.gd": ["crabapple", "pawpaw", "pillbug", "nymph", "grasshopper", "grub", "snails", "berries", "morel", "fly_agaric", "little_brown"],
	"crayfish.gd": ["dead_mouse", "dead_fish", "nymph", "snails", "grub"],
	"shrimp.gd": ["dead_fish", "litter", "algae"],
	"spider.gd": ["nymph", "grasshopper", "grub", "caterpillar", "flier", "bee", "monarch", "firefly", "mollies"],
	"mantis.gd": ["nymph", "grasshopper", "caterpillar", "grub", "spider"],
	"dragonfly.gd": ["flier", "monarch", "swallowtail", "mollies"],
	"wasp.gd": ["flowers", "caterpillar", "grub", "grasshopper", "nymph", "spider"],
	"trigonalid.gd": ["flowers"],
	"ichneumon.gd": ["flowers"],
	"bumblebee.gd": ["flowers"],
	"monarch.gd": ["flowers"],
	"swallowtail.gd": ["flowers"],
	"hummingbird_moth.gd": ["flowers"],
	"mourning_cloak.gd": ["crabapple", "pawpaw"],
	"harvester_ants.gd": ["acorn", "walnut", "nymph", "grasshopper"],
	"ant_colony.gd": ["nymph", "grasshopper", "grub", "caterpillar", "carcass"],
	"luna_moth.gd": [], # (the grown moths don't eat)
	"cecropia_moth.gd": [],
	"polyphemus_moth.gd": [],
	"sea_turtle.gd": [], # (its seagrass isn't in the game)
	"larva.gd": ["leaf"],
	"grasshopper.gd": ["graze"],
	"isopod.gd": ["litter"],
	"snails.gd": ["leaf"],
	"fireflies.gd": ["snails"], # (the glowworm larvae's)
	"ticks.gd": ["blood"],
	"mollies.gd": ["algae"],
	"fish_school.gd": ["crayfish", "fish", "nymph", "grasshopper", "mollies"],
}

## (A kind that stands for several: "snails", any snail.)
const ALIASES := {"snails": ["snails", "grass_snail", "tigersnail"]}

## Kinds that live as colonies, eaten one at a time (one_of: the nearest
## taken out of its colony, a body of its own to be eaten).
const ONE_AT_A_TIME := ["snails", "grass_snail", "tigersnail", "firefly"]

## What isn't hunted (no animal to run down: carrion, plants, the game's
## items, a colony eaten whole where it is, what's always under it).
const NOT_PREY := ["carcass", "dead_mouse", "dead_fish", "berries", "forbs", "flowers", "sapling", "stick", "ants", "wasp_comb",
		"fish", "mollies", "clam", "urchin", "acorn", "walnut", "pawpaw", "crabapple", "morel", "fly_agaric", "chicken_of_the_woods",
		"little_brown", "graze", "leaf", "litter", "algae", "blood"]

## (Those that eat from what's always under them: no finding.)
const EVERYWHERE := ["graze", "leaf", "litter", "algae", "blood"]
const FORBS := ["yampah", "fleabane", "susan"]
const BERRIES := ["g_blueberry", "g_raspberry"]


## Its diet (by its script; a subclass's, its parent script's).
static func of(c: Node) -> Array:
	var sc: Script = c.get_script() if c else null
	while sc:
		var f := sc.resource_path.get_file()
		if EATS.has(f):
			return EATS[f]
		sc = sc.get_base_script()
	return []


## What c hunts (its diet's animals, run down, caught).
static func prey_of(c: Node) -> Array:
	return of(c).filter(func(k: String) -> bool: return k not in NOT_PREY)


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
		"grass_snails.gd":
			k = "grass_snail"
		"flamed_tigersnails.gd":
			k = "tigersnail"
		"snails.gd":
			k = "snails"
	if k != "" and n.get("dead") == true:
		return "dead_" + k
	return k


## The nearest real food of c's diet (or of kinds) in its parent, within r
## m: alive (or a carcass), not another's quarry already; or null. (For
## what's always under it, EVERYWHERE: c itself.)
static func find(c: Node3D, r := 30.0, kinds: Array = []) -> Node:
	if c == null or c.get_parent() == null:
		return null
	var want: Array = expand(kinds if not kinds.is_empty() else of(c))
	for k: String in want:
		if k in EVERYWHERE:
			return c
	var p := _at(c)
	var best: Node = null
	var bd := r
	for o in c.get_parent().get_children():
		if o == c or not (o is Node3D):
			continue
		var k := kind_of(o)
		if k == "" or not want.has(k):
			continue
		if o.has_meta("hunted") and is_instance_valid(o.get_meta("hunted")) and o.get_meta("hunted") != c:
			continue
		if o.has_meta("taken") and not o.has_meta("keep"):
			continue
		var d := _at(o as Node3D).distance_to(p)
		if d < bd:
			bd = d
			best = o
	return best


## As find, but one of a colony (a snail of its band, a firefly of its
## swarm) taken out of it: a body of its own where it was, to be eaten.
static func find_one(c: Node3D, r := 30.0, kinds: Array = []) -> Node:
	var f := find(c, r, kinds)
	if f != null and f != c and kind_of(f) in ONE_AT_A_TIME:
		return one_of(f as Node3D, _at(c))
	return f


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
