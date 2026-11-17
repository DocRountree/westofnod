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
##   class: "mammal" (as most), "bird", "reptile", "amphibian", "fish", "arthropod", "mollusk", "echinoderm": how long she carries her
##   young (a state only: nothing of it shows), how long they're young, how long before she'll breed again
##   (CLASS_DAYS: a mammal's 2 days, 4, 2; an arthropod's 1, 1, 1; gest_days, wean_days, gap_days: its own);
##   days are the game's (Fauna.day_secs: the sandbox's 75 s; the game's its sky's)
##   litter: [fewest, most] born; crowd: with this many of her kind about her she won't; mate: s a mating takes
##   medium: "land", "sea", "fresh", "shore" (land by water, and the water); depth, max_depth: m of water it
##   needs; floor: it keeps to the bottom; flies: its ways aren't the ground's
##   site: what it lives on: "perch", "roost", "flower", "web" (FaunaSim.sites)
##   ctor: its _init's arguments ("young": whether it's young); school: a FishSchool's (SchoolBody);
##   swarm: [script, how many, how far about] (SwarmBody: a colony, a band, a pool: one record, not steered);
##   larva: a butterfly's or a moth's young: an egg, then its caterpillar (Larva's kind), then its chrysalis
##   plankton: its young's first part, adrift (Plankton's kind: "octopus", "sea_star", "pluteus"): a cloud of
##   them till plankton_frac of their youth, laid and left (no mother); then settled, a young one's body
##   broods: she keeps to her den while she carries them (an octopus's eggs: brooded, never left, never fed)
##   semelparous: she dies when they hatch; he a gap_days after he's mated
##   sessile: it stays where it is (a clam in its burrow): it spawns with those near, not going to them
##   plant: no brain but to grow (Brain): spreads its young about it each gap_days, as its crowd allows; a
##   giant kelp grazed to death by urchins crowding its holdfast (grazers: how many it bears)
##   far: drawn far off with no body (FarFauna; not the small ones)
##   density: {a biome's name (WorldData.biome_names): how many to the square kilometre; "*": any not named}:
##   what FaunaSim seeds the land with
## }
## Times are the sandbox's (quick to watch); Fauna.life_rate scales them.
## Only what's here has a brain: add a line for another (its script's
## _init(young), `male`, `height`, place(at, yaw), as the walkers have).

const DIR := "res://scripts/creatures/"
const DEFAULTS := {"class": "mammal", "medium": "land", "site": "", "flies": false, "floor": false, "depth": 0.2, "max_depth": 1e9, "ctor": ["young"],
		"kind": "", "young_kind": "", "len": 1.0, "walk": 0.6, "run": 2.5, "active": "any", "range": 8.0, "wary": 6.0, "sense": 12.0,
		"meal": 25.0, "fast": 600.0, "awake": 300.0, "nap": 40.0, "herd": false,
		"litter": [1, 2], "crowd": 8, "mate": 14.0, "density": {}}
## How long each class carries (or broods) its young, how long they're young, and how long after before she'll breed again: days.
const CLASS_DAYS := {"mammal": [2.0, 4.0, 2.0], "bird": [2.0, 3.0, 1.0], "reptile": [2.0, 3.0, 1.0], "amphibian": [1.0, 2.0, 1.0], "fish": [2.0, 3.0, 1.0],
		"arthropod": [1.0, 1.0, 1.0], "mollusk": [1.5, 3.0, 1.0], "echinoderm": [0.25, 2.0, 1.0], "alga": [0.0, 3.0, 2.0]}
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
	"turkey": {"class": "bird", "far_wing": false, "density": {"forest": 5.0, "prairie": 2.0}, "litter": [6, 10], "crowd": 14, "script": "wild_turkey.gd", "kind": "turkey", "young_kind": "poult", "len": 1.0, "walk": 0.7, "run": 3.0, "range": 8.0, "wary": 7.0, "fast": 360.0, "active": "day", "herd": true},
	"robin": {"class": "bird", "tone": Color(0.33, 0.27, 0.22), "density": {"forest": 10.0, "prairie": 6.0, "coast": 3.0}, "litter": [3, 4], "script": "american_robin.gd", "kind": "robin", "young_kind": "nestling", "len": 0.25, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"blackbird": {"class": "bird", "tone": Color(0.05, 0.05, 0.05), "density": {"swamp": 12.0, "prairie": 6.0}, "litter": [3, 4], "script": "red_winged_blackbird.gd", "kind": "blackbird", "young_kind": "nestling", "len": 0.22, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day", "herd": true},
	"cardinal": {"class": "bird", "tone": Color(0.7, 0.12, 0.1), "density": {"forest": 6.0}, "litter": [2, 4], "script": "northern_cardinal.gd", "kind": "cardinal", "young_kind": "nestling", "len": 0.22, "walk": 0.7, "run": 6.0, "range": 8.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"jay": {"class": "bird", "tone": Color(0.25, 0.4, 0.7), "density": {"forest": 5.0}, "litter": [3, 5], "script": "blue_jay.gd", "kind": "jay", "young_kind": "nestling", "len": 0.28, "walk": 0.7, "run": 6.0, "range": 9.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"pigeon": {"class": "bird", "tone": Color(0.36, 0.4, 0.48), "density": {"forest": 8.0}, "litter": [1, 1], "crowd": 30, "script": "passenger_pigeon.gd", "kind": "pigeon", "young_kind": "nestling", "len": 0.4, "walk": 0.7, "run": 7.0, "range": 10.0, "wary": 7.0, "fast": 300.0, "active": "day", "herd": true},
	"goose": {"class": "bird", "tone": Color(0.36, 0.31, 0.26), "density": {"swamp": 3.0, "coast": 3.0, "prairie": 1.0}, "litter": [3, 6], "crowd": 14, "script": "canada_goose.gd", "kind": "goose", "young_kind": "gosling", "len": 1.0, "walk": 0.7, "run": 5.0, "range": 9.0, "wary": 7.0, "fast": 320.0, "active": "day", "herd": true},
	# those that live on something: a perch (a tree's top, a snag), a roost, flowers, a web
	"horned_owl": {"class": "bird", "site": "perch", "flies": true, "density": {"forest": 0.3, "taiga": 0.2, "mesa": 0.1}, "script": "great_horned_owl.gd", "len": 0.55, "walk": 6.0, "run": 12.0, "range": 40.0, "sense": 30.0, "fast": 900.0, "active": "night"},
	"barn_owl": {"class": "bird", "site": "perch", "flies": true, "density": {"prairie": 0.3, "forest": 0.1}, "script": "barn_owl.gd", "len": 0.35, "walk": 6.0, "run": 11.0, "range": 40.0, "sense": 30.0, "fast": 800.0, "active": "night"},
	"screech_owl": {"class": "bird", "site": "perch", "flies": true, "density": {"forest": 0.6}, "script": "eastern_screech_owl.gd", "len": 0.2, "walk": 5.0, "run": 9.0, "range": 25.0, "sense": 20.0, "fast": 600.0, "active": "night"},
	"hawk": {"class": "bird", "site": "perch", "flies": true, "density": {"forest": 0.3}, "script": "coopers_hawk.gd", "len": 0.45, "walk": 7.0, "run": 15.0, "range": 45.0, "sense": 35.0, "fast": 800.0, "active": "day"},
	"falcon": {"class": "bird", "site": "perch", "flies": true, "density": {"coast": 0.1, "mountains": 0.1, "mesa": 0.1}, "script": "peregrine_falcon.gd", "len": 0.45, "walk": 9.0, "run": 30.0, "range": 60.0, "sense": 45.0, "fast": 800.0, "active": "day"},
	"bald_eagle": {"class": "bird", "tone": Color(0.2, 0.15, 0.11), "site": "perch", "flies": true, "density": {"coast": 0.1, "swamp": 0.1, "taiga": 0.05}, "script": "bald_eagle.gd", "len": 0.9, "walk": 8.0, "run": 15.0, "range": 60.0, "sense": 45.0, "fast": 1000.0, "active": "day"},
	"golden_eagle": {"class": "bird", "site": "perch", "flies": true, "density": {"mountains": 0.08, "plateau": 0.08, "mesa": 0.05}, "script": "golden_eagle.gd", "len": 0.85, "walk": 8.0, "run": 18.0, "range": 60.0, "sense": 45.0, "fast": 1000.0, "active": "day"},
	"bluebird": {"class": "bird", "site": "perch", "flies": true, "density": {"prairie": 5.0, "forest": 2.0}, "litter": [3, 5], "script": "eastern_bluebird.gd", "kind": "bluebird", "young_kind": "nestling", "len": 0.18, "walk": 5.0, "run": 9.0, "range": 15.0, "wary": 6.0, "fast": 300.0, "active": "day"},
	"goldfinch": {"class": "bird", "tone": Color(0.8, 0.7, 0.15), "site": "perch", "flies": true, "density": {"prairie": 6.0, "forest": 3.0}, "litter": [3, 5], "script": "american_goldfinch.gd", "kind": "finch", "young_kind": "nestling", "len": 0.12, "walk": 5.0, "run": 9.0, "range": 15.0, "wary": 6.0, "fast": 300.0, "active": "day", "herd": true},
	"house_finch": {"class": "bird", "site": "perch", "flies": true, "density": {"mesa": 5.0, "prairie": 3.0, "forest": 2.0}, "litter": [3, 5], "script": "house_finch.gd", "kind": "finch", "young_kind": "nestling", "len": 0.14, "walk": 5.0, "run": 9.0, "range": 15.0, "wary": 6.0, "fast": 300.0, "active": "day", "herd": true},
	"hummingbird": {"class": "bird", "site": "perch", "flies": true, "density": {"forest": 3.0}, "litter": [2, 2], "script": "ruby_throated_hummingbird.gd", "kind": "hummingbird", "young_kind": "nestling", "len": 0.09, "walk": 6.0, "run": 12.0, "range": 12.0, "wary": 4.0, "fast": 200.0, "active": "day", "far": false},
	"heron": {"class": "bird", "tone": Color(0.45, 0.5, 0.56), "medium": "shore", "flies": true, "density": {"swamp": 1.0, "coast": 0.5}, "litter": [2, 4], "script": "great_blue_heron.gd", "kind": "heron", "young_kind": "nestling", "len": 1.1, "walk": 0.7, "run": 9.0, "range": 20.0, "wary": 12.0, "fast": 500.0, "active": "day"},
	"bat": {"site": "roost", "flies": true, "density": {"forest": 6.0, "swamp": 6.0, "mesa": 3.0}, "litter": [1, 2], "crowd": 30, "script": "bat.gd", "kind": "bat", "young_kind": "bat_pup", "len": 0.12, "walk": 5.0, "run": 8.0, "range": 30.0, "wary": 5.0, "fast": 300.0, "active": "night", "herd": true, "far": false},
	"monarch": {"class": "arthropod", "larva": "monarch", "site": "flower", "flies": true, "ctor": [], "density": {"prairie": 20.0, "forest": 6.0}, "litter": [4, 8], "crowd": 20, "script": "monarch.gd", "kind": "monarch", "len": 0.1, "walk": 0.8, "run": 2.0, "range": 12.0, "wary": 2.0, "fast": 200.0, "active": "day"},
	"swallowtail": {"class": "arthropod", "larva": "swallowtail", "site": "flower", "flies": true, "ctor": [], "density": {"forest": 10.0, "prairie": 8.0}, "litter": [4, 8], "crowd": 20, "script": "swallowtail.gd", "kind": "swallowtail", "len": 0.1, "walk": 0.9, "run": 2.0, "range": 12.0, "wary": 2.0, "fast": 200.0, "active": "day"},
	"cloak": {"class": "arthropod", "larva": "cloak", "flies": true, "ctor": [], "density": {"forest": 8.0, "taiga": 4.0}, "litter": [4, 8], "crowd": 20, "script": "mourning_cloak.gd", "len": 0.08, "walk": 0.9, "run": 2.0, "range": 12.0, "wary": 2.0, "fast": 200.0, "active": "day"},
	"luna": {"class": "arthropod", "larva": "luna", "flies": true, "ctor": [], "density": {"forest": 4.0}, "litter": [4, 8], "crowd": 20, "script": "luna_moth.gd", "kind": "moth", "len": 0.11, "walk": 0.5, "run": 1.5, "range": 12.0, "wary": 2.0, "fast": 1e9, "active": "night"},
	"hawk_moth": {"class": "arthropod", "larva": "hemaris", "site": "flower", "flies": true, "ctor": [], "density": {"prairie": 8.0, "forest": 4.0}, "litter": [4, 8], "crowd": 20, "script": "hummingbird_moth.gd", "len": 0.05, "walk": 1.3, "run": 3.0, "range": 12.0, "wary": 2.0, "fast": 150.0, "active": "day"},
	"bumblebee": {"class": "arthropod", "site": "flower", "flies": true, "ctor": [false], "density": {"prairie": 30.0, "forest": 10.0, "tundra": 5.0}, "litter": [3, 6], "crowd": 30, "script": "bumblebee.gd", "kind": "bee", "len": 0.02, "walk": 0.8, "run": 2.0, "range": 15.0, "wary": 1.0, "fast": 150.0, "active": "day"},
	"wasp": {"class": "arthropod", "site": "flower", "flies": true, "ctor": [], "density": {"forest": 15.0, "prairie": 10.0}, "litter": [3, 6], "crowd": 30, "script": "wasp.gd", "kind": "flier", "len": 0.02, "walk": 0.8, "run": 2.0, "range": 15.0, "wary": 1.0, "fast": 150.0, "active": "day"},
	"wolf_spider": {"class": "arthropod", "ctor": ["wolf", "young"], "density": {"forest": 40.0, "prairie": 40.0, "*": 10.0}, "litter": [6, 12], "crowd": 30, "script": "spider.gd", "kind": "spider", "len": 0.03, "walk": 0.09, "run": 0.3, "range": 2.0, "wary": 1.0, "sense": 1.5, "fast": 400.0, "active": "night"},
	"garden_spider": {"class": "arthropod", "site": "web", "ctor": ["argiope", "young"], "density": {"prairie": 30.0, "forest": 15.0}, "litter": [6, 12], "crowd": 30, "script": "spider.gd", "kind": "spider", "len": 0.03, "walk": 0.07, "run": 0.2, "range": 0.5, "wary": 0.5, "sense": 1.0, "fast": 500.0},
	"dragonfly": {"class": "arthropod", "medium": "shore", "flies": true, "density": {"swamp": 30.0, "coast": 5.0}, "litter": [4, 8], "crowd": 20, "script": "dragonfly.gd", "len": 0.08, "walk": 1.0, "run": 4.0, "range": 12.0, "wary": 2.0, "sense": 5.0, "fast": 200.0, "active": "day"},
	"mantis": {"class": "arthropod", "density": {"prairie": 10.0, "forest": 5.0}, "litter": [6, 12], "crowd": 20, "script": "mantis.gd", "young_kind": "mantis_nymph", "len": 0.08, "walk": 0.02, "run": 0.1, "range": 1.5, "wary": 1.0, "sense": 1.0, "fast": 500.0, "active": "day"},
	"grasshopper": {"class": "arthropod", "density": {"prairie": 80.0, "mesa": 30.0, "forest": 20.0}, "litter": [6, 12], "crowd": 40, "script": "grasshopper.gd", "kind": "grasshopper", "young_kind": "nymph", "len": 0.05, "walk": 0.035, "run": 1.5, "range": 3.0, "wary": 1.5, "fast": 150.0, "active": "day"},
	"scorpion": {"class": "arthropod", "density": {"mesa": 20.0, "plateau": 8.0}, "litter": [6, 12], "crowd": 20, "script": "scorpion.gd", "len": 0.06, "walk": 0.05, "run": 0.2, "range": 2.0, "wary": 1.0, "sense": 1.0, "fast": 600.0, "active": "night"},
	"pillbug": {"class": "arthropod", "density": {"forest": 60.0, "swamp": 30.0}, "litter": [6, 12], "crowd": 40, "script": "isopod.gd", "kind": "pillbug", "len": 0.015, "walk": 0.02, "run": 0.04, "range": 1.0, "wary": 0.5, "fast": 300.0, "active": "night"},
	# the reptiles, the frogs
	"milk_snake": {"class": "reptile", "ctor": ["milk", "young"], "density": {"forest": 4.0, "prairie": 4.0, "swamp": 4.0}, "litter": [4, 8], "script": "snake.gd", "kind": "snake", "young_kind": "snake_young", "len": 0.7, "walk": 0.14, "run": 0.6, "range": 6.0, "wary": 3.0, "sense": 4.0, "fast": 1200.0, "active": "day"},
	"rattler": {"class": "reptile", "ctor": ["rattler", "young"], "density": {"mesa": 2.0, "prairie": 1.0, "plateau": 1.0}, "litter": [4, 8], "script": "snake.gd", "kind": "snake", "young_kind": "snake_young", "len": 1.1, "walk": 0.14, "run": 0.5, "range": 6.0, "wary": 2.0, "sense": 4.0, "fast": 1500.0, "active": "night"},
	"anole": {"class": "reptile", "density": {"forest": 10.0, "swamp": 10.0}, "litter": [1, 2], "crowd": 20, "script": "anole.gd", "kind": "anole", "len": 0.15, "walk": 0.15, "run": 0.8, "range": 3.0, "wary": 2.0, "sense": 2.0, "fast": 400.0, "active": "day", "far": false},
	"gila": {"class": "reptile", "density": {"mesa": 0.6}, "litter": [3, 6], "script": "gila_monster.gd", "len": 0.5, "walk": 0.09, "run": 0.3, "range": 5.0, "wary": 1.5, "sense": 3.0, "fast": 2000.0, "active": "night"},
	"frog": {"class": "amphibian", "medium": "shore", "density": {"swamp": 60.0}, "litter": [6, 12], "crowd": 40, "script": "frog.gd", "kind": "frog", "len": 0.09, "walk": 0.3, "run": 1.2, "range": 4.0, "wary": 2.0, "sense": 1.5, "fast": 400.0, "active": "night", "far": false},
	"toad": {"class": "amphibian", "density": {"forest": 10.0, "prairie": 6.0, "swamp": 10.0}, "litter": [6, 12], "crowd": 30, "script": "american_toad.gd", "kind": "toad", "len": 0.08, "walk": 0.3, "run": 0.8, "range": 4.0, "wary": 1.5, "sense": 1.5, "fast": 400.0, "active": "night", "far": false},
	"painted_turtle": {"class": "reptile", "medium": "shore", "density": {"swamp": 15.0}, "litter": [4, 8], "script": "painted_turtle.gd", "len": 0.18, "walk": 0.03, "run": 0.06, "range": 5.0, "wary": 3.0, "fast": 1500.0, "active": "day", "far": false},
	"snapper": {"class": "reptile", "medium": "shore", "density": {"swamp": 4.0}, "litter": [6, 12], "script": "snapping_turtle.gd", "len": 0.4, "walk": 0.03, "run": 0.06, "range": 5.0, "wary": 1.0, "fast": 2000.0},
	# the water's
	"river_otter": {"medium": "shore", "density": {"swamp": 1.5}, "litter": [2, 3], "script": "river_otter.gd", "young_kind": "otter_pup", "len": 1.0, "walk": 0.3, "run": 1.5, "range": 15.0, "sense": 10.0, "fast": 500.0},
	"beaver": {"medium": "shore", "density": {"swamp": 2.0}, "litter": [2, 4], "script": "beaver.gd", "kind": "beaver", "young_kind": "beaver_kit", "len": 0.9, "walk": 0.37, "run": 1.2, "range": 12.0, "wary": 8.0, "fast": 500.0, "active": "night"},
	"crayfish": {"class": "arthropod", "medium": "fresh", "floor": true, "density": {"swamp": 80.0}, "litter": [6, 12], "crowd": 40, "script": "red_swamp_crayfish.gd", "kind": "crayfish", "len": 0.1, "walk": 0.05, "run": 0.3, "range": 3.0, "wary": 1.5, "fast": 400.0, "active": "night"},
	"sea_otter": {"medium": "sea", "depth": 0.5, "max_depth": 30.0, "density": {"sea": 4.0}, "litter": [1, 1], "script": "sea_otter.gd", "len": 1.2, "walk": 0.5, "run": 2.0, "range": 20.0, "sense": 10.0, "fast": 400.0, "herd": true},
	"sea_turtle": {"class": "reptile", "medium": "sea", "depth": 1.0, "density": {"sea": 0.2}, "litter": [6, 12], "script": "sea_turtle.gd", "len": 1.0, "walk": 0.5, "run": 1.5, "range": 40.0, "wary": 5.0, "fast": 2000.0},
	"urchin": {"class": "echinoderm", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 30.0, "density": {"sea": 300.0}, "litter": [4, 8], "crowd": 40, "script": "sea_urchin.gd", "kind": "urchin", "len": 0.08, "walk": 0.012, "run": 0.012, "range": 2.0, "wary": 0.5, "fast": 300.0, "plankton": "pluteus", "far": false},
	"clam": {"class": "mollusk", "medium": "sea", "floor": true, "depth": 0.2, "max_depth": 30.0, "density": {"sea": 600.0}, "litter": [6, 12], "crowd": 60, "script": "clam.gd", "kind": "clam", "young_kind": "clam", "len": 0.055, "walk": 0.0015, "run": 0.0015, "range": 0.3, "wary": 0.0, "sense": 2.0, "fast": 300.0, "mate": 15.0, "herd": true, "sessile": true, "plankton": "veliger", "far": false, "gest_days": 0.25, "wean_days": 2.0},
	"giant_kelp": {"class": "alga", "plant": true, "sessile": true, "medium": "sea", "floor": true, "depth": 2.0, "max_depth": 30.0, "density": {"sea": 150.0}, "litter": [1, 3], "crowd": 12, "grazers": 3, "script": "giant_kelp.gd", "kind": "kelp", "len": 6.0, "walk": 0.0, "run": 0.0, "range": 6.0, "wary": 0.0, "far": false},
	"common_octopus": {"class": "mollusk", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 100.0, "density": {"sea": 20.0}, "litter": [3, 6], "crowd": 6, "script": "common_octopus.gd", "kind": "octopus", "young_kind": "octopus_young", "len": 0.9, "walk": 0.08, "run": 1.5, "range": 6.0, "wary": 3.0, "sense": 4.0, "meal": 40.0, "fast": 500.0, "active": "night", "mate": 30.0, "broods": true, "semelparous": true, "plankton": "octopus", "far": false},
	"giant_pacific_octopus": {"class": "mollusk", "medium": "sea", "floor": true, "depth": 1.0, "max_depth": 200.0, "density": {"sea": 2.0}, "litter": [4, 8], "crowd": 4, "script": "giant_pacific_octopus.gd", "kind": "octopus", "young_kind": "octopus_young", "len": 3.0, "walk": 0.14, "run": 2.2, "range": 12.0, "wary": 5.0, "sense": 6.0, "meal": 60.0, "fast": 700.0, "active": "night", "mate": 40.0, "broods": true, "semelparous": true, "plankton": "octopus", "far": false, "gest_days": 2.5, "wean_days": 4.0},
	"ochre_sea_star": {"class": "echinoderm", "medium": "sea", "floor": true, "depth": 0.2, "max_depth": 90.0, "density": {"sea": 120.0}, "litter": [4, 8], "crowd": 30, "script": "ochre_sea_star.gd", "kind": "sea_star", "len": 0.25, "walk": 0.01, "run": 0.01, "range": 2.0, "wary": 0.0, "meal": 120.0, "fast": 900.0, "mate": 20.0, "plankton": "sea_star", "far": false},
	"sand_dollar": {"class": "echinoderm", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 40.0, "density": {"sea": 400.0}, "litter": [6, 10], "crowd": 80, "script": "sand_dollar.gd", "kind": "sand_dollar", "len": 0.08, "walk": 0.004, "run": 0.004, "range": 1.0, "wary": 0.0, "fast": 400.0, "mate": 15.0, "herd": true, "plankton": "pluteus", "far": false},
	"dolphin": {"medium": "sea", "depth": 4.0, "density": {"sea": 0.4}, "litter": [1, 1], "script": "bottlenose_dolphin.gd", "kind": "dolphin", "young_kind": "dolphin_calf", "len": 3.0, "walk": 2.2, "run": 8.0, "range": 80.0, "wary": 30.0, "sense": 40.0, "fast": 600.0, "herd": true},
	"orca": {"medium": "sea", "depth": 8.0, "density": {"sea": 0.06}, "litter": [1, 1], "script": "orca.gd", "len": 7.0, "walk": 2.6, "run": 10.0, "range": 120.0, "sense": 60.0, "fast": 900.0, "herd": true},
	"blue_whale": {"medium": "sea", "depth": 30.0, "density": {"sea": 0.02}, "litter": [1, 1], "script": "blue_whale.gd", "young_kind": "whale_calf", "len": 25.0, "walk": 2.2, "run": 6.0, "range": 200.0, "wary": 40.0, "fast": 600.0},
	"shark": {"class": "fish", "medium": "sea", "depth": 5.0, "density": {"sea": 0.05}, "litter": [2, 6], "script": "great_white_shark.gd", "kind": "shark", "young_kind": "shark_pup", "len": 4.5, "walk": 1.2, "run": 8.0, "range": 120.0, "wary": 40.0, "sense": 50.0, "fast": 900.0},
	"salmon": {"class": "fish", "medium": "sea", "depth": 3.0, "school": ["chinook", "ocean", 30], "density": {"sea": 0.5}, "litter": [1, 1], "script": "school_body.gd", "kind": "fish", "len": 6.0, "walk": 1.0, "run": 4.0, "range": 80.0, "wary": 25.0, "fast": 300.0},
	"tuna": {"class": "fish", "medium": "sea", "depth": 20.0, "school": ["bluefin", "ocean", 16], "density": {"sea": 0.15}, "litter": [1, 1], "script": "school_body.gd", "kind": "tuna", "len": 10.0, "walk": 2.0, "run": 8.0, "range": 150.0, "wary": 30.0, "fast": 300.0},
	"trout": {"class": "fish", "medium": "fresh", "depth": 0.3, "school": ["rainbow", "rainbow", 10], "density": {"swamp": 6.0}, "litter": [1, 1], "script": "school_body.gd", "kind": "fish", "len": 2.0, "walk": 0.5, "run": 2.0, "range": 10.0, "wary": 5.0, "fast": 300.0},
	# the rest of those with bodies of their own
	"dog_gsd": {"script": "german_shepherd.gd", "len": 1.1, "walk": 0.8, "run": 5.0, "range": 10.0, "sense": 14.0, "fast": 800.0, "active": "day"},
	"dog_lab": {"script": "labrador_retriever.gd", "len": 1.0, "walk": 0.8, "run": 4.5, "range": 10.0, "sense": 14.0, "fast": 700.0, "active": "day"},
	"dog_beagle": {"script": "beagle.gd", "len": 0.7, "walk": 0.7, "run": 4.0, "range": 10.0, "sense": 16.0, "fast": 700.0, "active": "day"},
	"box_turtle": {"class": "reptile", "density": {"forest": 3.0, "prairie": 1.0}, "litter": [3, 6], "script": "turtle.gd", "len": 0.15, "walk": 0.03, "run": 0.05, "range": 4.0, "wary": 1.0, "fast": 2000.0, "active": "day", "far": false},
	"blue_hopper": {"class": "arthropod", "density": {"mesa": 30.0, "prairie": 20.0}, "litter": [6, 12], "crowd": 40, "script": "blue_winged_grasshopper.gd", "kind": "grasshopper", "young_kind": "nymph", "len": 0.04, "walk": 0.035, "run": 1.5, "range": 3.0, "wary": 1.5, "fast": 150.0, "active": "day"},
	"fishing_spider": {"class": "arthropod", "medium": "shore", "ctor": ["fishing", "young"], "density": {"swamp": 20.0}, "litter": [6, 12], "crowd": 30, "script": "spider.gd", "kind": "spider", "len": 0.04, "walk": 0.09, "run": 0.3, "range": 2.0, "wary": 1.0, "sense": 1.5, "fast": 500.0, "active": "night"},
	"grass_spider": {"class": "arthropod", "site": "web", "ctor": ["funnel", "young"], "density": {"prairie": 40.0, "forest": 20.0}, "litter": [6, 12], "crowd": 30, "script": "spider.gd", "kind": "spider", "len": 0.02, "walk": 0.08, "run": 0.3, "range": 0.5, "wary": 0.5, "sense": 1.0, "fast": 500.0},
	"ichneumon": {"class": "arthropod", "flies": true, "ctor": [], "density": {"forest": 6.0}, "litter": [3, 6], "crowd": 20, "script": "ichneumon.gd", "kind": "flier", "len": 0.04, "walk": 0.8, "run": 2.0, "range": 12.0, "wary": 1.0, "fast": 300.0, "active": "day"},
	"trigonalid": {"class": "arthropod", "flies": true, "ctor": [], "density": {"forest": 4.0}, "litter": [3, 6], "crowd": 20, "script": "trigonalid.gd", "kind": "flier", "len": 0.012, "walk": 0.8, "run": 2.0, "range": 10.0, "wary": 1.0, "fast": 300.0, "active": "day"},
	"cecropia": {"class": "arthropod", "larva": "cecropia", "flies": true, "ctor": [], "density": {"forest": 2.0}, "litter": [4, 8], "crowd": 20, "script": "cecropia_moth.gd", "kind": "moth", "len": 0.14, "walk": 0.5, "run": 1.5, "range": 12.0, "wary": 2.0, "fast": 1e9, "active": "night"},
	"polyphemus": {"class": "arthropod", "larva": "polyphemus", "flies": true, "ctor": [], "density": {"forest": 2.0}, "litter": [4, 8], "crowd": 20, "script": "polyphemus_moth.gd", "kind": "moth", "len": 0.13, "walk": 0.5, "run": 1.5, "range": 12.0, "wary": 2.0, "fast": 1e9, "active": "night"},
	"white_shrimp": {"class": "arthropod", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 30.0, "density": {"sea": 150.0}, "litter": [6, 12], "crowd": 40, "script": "white_shrimp.gd", "kind": "shrimp", "len": 0.18, "walk": 0.05, "run": 0.4, "range": 4.0, "wary": 1.5, "fast": 300.0, "active": "night"},
	"brown_shrimp": {"class": "arthropod", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 30.0, "density": {"sea": 150.0}, "litter": [6, 12], "crowd": 40, "script": "brown_shrimp.gd", "kind": "shrimp", "len": 0.18, "walk": 0.05, "run": 0.4, "range": 4.0, "wary": 1.5, "fast": 300.0, "active": "night"},
	"pink_shrimp": {"class": "arthropod", "medium": "sea", "floor": true, "depth": 0.5, "max_depth": 30.0, "density": {"sea": 150.0}, "litter": [6, 12], "crowd": 40, "script": "pink_shrimp.gd", "kind": "shrimp", "len": 0.18, "walk": 0.05, "run": 0.4, "range": 4.0, "wary": 1.5, "fast": 300.0, "active": "night"},
	# the swarms: each one record, its body a SwarmBody (the colony, the band, the pool itself under it)
	"carpenter_ants": {"class": "arthropod", "swarm": ["ant_colony.gd", 160, 0.4], "density": {"forest": 25.0, "taiga": 10.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"harvester_ants": {"class": "arthropod", "swarm": ["harvester_ants.gd", 160, 0.5], "density": {"mesa": 25.0, "prairie": 20.0, "plateau": 10.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"june_beetles": {"class": "arthropod", "swarm": ["june_beetles.gd", 12, 0.6], "density": {"forest": 20.0, "prairie": 15.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"lady_beetles": {"class": "arthropod", "swarm": ["lady_beetles.gd", 20, 0.5], "density": {"prairie": 25.0, "forest": 15.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"fireflies": {"class": "arthropod", "swarm": ["fireflies.gd", 30, 2.0], "density": {"forest": 15.0, "swamp": 20.0, "prairie": 8.0}, "script": "swarm_body.gd", "len": 1.2, "range": 0.0, "far": false, "active": "night"},
	"grass_snails": {"class": "arthropod", "swarm": ["grass_snails.gd", 12, 0.4], "density": {"prairie": 20.0, "forest": 15.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"tigersnails": {"class": "arthropod", "swarm": ["flamed_tigersnails.gd", 6, 0.4], "density": {"forest": 10.0, "swamp": 10.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"deer_ticks": {"class": "arthropod", "swarm": ["blacklegged_ticks.gd", 20, 0.3], "density": {"forest": 20.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"lone_star_ticks": {"class": "arthropod", "swarm": ["lone_star_ticks.gd", 20, 0.3], "density": {"forest": 10.0, "prairie": 10.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.0, "far": false},
	"krill": {"class": "arthropod", "medium": "sea", "depth": 15.0, "swarm": ["krill.gd", 1500, 1.5], "density": {"sea": 0.3}, "script": "swarm_body.gd", "len": 3.0, "range": 12.0, "far": false},
	"mollies": {"class": "fish", "medium": "fresh", "depth": 0.2, "swarm": ["mollies.gd", 30, 0.3], "density": {"swamp": 20.0}, "script": "swarm_body.gd", "len": 0.5, "range": 0.6, "far": false},
}
## A brain's verbs, each by the names the animals have for it (the first
## its body has, Creature.behaviours()).
const VERBS := {
	"eat": ["graze", "browse", "forage", "nibble", "eat", "feed", "feed_on_flower", "seek_food", "search", "fish", "hunt", "strike", "patrol"],
	"hunt": ["hunt", "strike", "catch", "fish"],
	"sleep": ["sleep", "roost", "bed", "ruminate", "rest", "coil", "hide", "bask", "sit", "perch", "burrow", "land", "home"],
	"groom": ["groom", "preen", "wallow", "dust", "rouse", "bask"],
	"alert": ["alert", "freeze", "stand", "flick", "watch", "periscope", "threat", "display", "spyhop"],
	"flee": ["flee", "fly", "startle", "dive", "alarm", "roll", "hop", "take_off"],
	"social": ["mark", "howl", "strut", "gobble", "thump", "rub", "call", "display", "slap", "breach", "tail_slap", "play"],
	"mate": ["mate"],
	"brood": ["brood"],
	"birth": ["birth", "give_birth"],
}

static var _full := {} # key -> its entry, filled in
static var _more := {} # key -> an entry registered (register())
static var _by_file := {} # a script's file -> key
static var _hunts := {} # "a>b" -> bool
static var _place_args := {} # a script -> how its place() is called


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
	var days: Array = CLASS_DAYS.get(String(e["class"]), CLASS_DAYS.mammal)
	for q: Array in [["gest_days", 0], ["wean_days", 1], ["gap_days", 2]]:
		if not e.has(q[0]):
			e[q[0]] = days[q[1]]
	if not e.has("far"): # (drawn far off, with no body: not the small ones)
		e["far"] = float(e.len) >= 0.2 and String(e["class"]) != "arthropod"
	if not e.has("young_body"): # (its young have a body: its kind's own young one; or a butterfly's or a moth's egg, caterpillar and chrysalis in turn, "larva"; not a wasp's, a bee's: in their comb)
		e["young_body"] = String(e["class"]) != "arthropod" or (e.ctor as Array).has("young") or e.has("larva") or e.has("plankton")
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


## The key of a creature's kind (by its script, or one it's made from; of
## several made from the one script, the one of its own `kind`), or "".
static func key_of(c: Node) -> String:
	if _by_file.is_empty():
		for k: String in keys():
			var f := String((TABLE[k] if TABLE.has(k) else _more[k]).script)
			if not _by_file.has(f):
				_by_file[f] = []
			(_by_file[f] as Array).append(k)
	var sc: Script = c.get_script() if c else null
	while sc:
		var ks: Variant = _by_file.get(sc.resource_path.get_file())
		if ks != null:
			var own: Variant = c.get("kind")
			if own is String and (ks as Array).size() > 1:
				for k: String in ks:
					var ctor: Array = of(k).ctor
					if not ctor.is_empty() and ctor[0] is String and ctor[0] == own:
						return k
			return ks[0]
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


## Days to seconds: the game's day (Fauna.day_secs), at the pace lives run (Fauna.life_rate).
static func days(n: float) -> float:
	return n * Fauna.day_secs / maxf(Fauna.life_rate, 0.001)


## Its body: made, put under parent at `at` facing yaw. env: what the place
## gives it ({} : level ground, no water): height: Callable (x, z) -> the
## ground's y; water: Callable (x, z) -> Vector3 (the surface's y, its
## depth there, 1 fresh / 0 salt), depth 0 none; site: Vector3 (its perch,
## its roost, its web: INF none).
static func make(key: String, parent: Node, at: Vector3, yaw := 0.0, male := false, young := false, env_: Variant = null) -> Creature:
	var e := of(key)
	if e.is_empty():
		return null
	var env: Dictionary = env_ if env_ is Dictionary else ({"height": env_} if env_ is Callable else {}) # (a Callable: as it was, just the ground)
	var sc: GDScript = load(DIR + String(e.script))
	var args := []
	for a: Variant in e.ctor:
		args.append(young if (a is String and a == "young") else a)
	var c: Creature = sc.callv("new", args)
	if "male" in c:
		c.set("male", male and not young)
	var height: Callable = env.get("height", Callable())
	if height.is_valid() and "height" in c:
		c.set("height", height)
	if e.has("school"):
		c.set("spec", e.school)
	if e.has("swarm"):
		c.set("spec", e.swarm)
	var water: Callable = env.get("water", Callable())
	var w := Vector3.ZERO
	if water.is_valid():
		w = water.call(at.x, at.z)
	if w.y > 0.0: # (water here: its surface, its floor, how far it reaches, told)
		var r := float(e.range)
		var floor_y := w.x - w.y
		if "water_y" in c:
			c.set("water_y", w.x)
		if "floor_y" in c:
			c.set("floor_y", floor_y)
		if "pond" in c:
			c.set("pond", [Vector3(at.x, w.x, at.z), Vector2(r, r)])
		if "wet" in c:
			c.set("wet", func(x: float, z: float) -> bool: return (water.call(x, z) as Vector3).y > 0.0)
		if c.has_method("set_water"):
			c.call("set_water", Vector3(at.x - r, floor_y, at.z - r), Vector3(at.x + r, w.x, at.z + r))
	parent.add_child(c)
	c.set_meta("home", at)
	var site: Vector3 = env.get("site", Vector3.INF)
	if site != Vector3.INF and c.has_method("set_perch"):
		c.call("set_perch", site)
	elif site != Vector3.INF and c.has_method("set_roost"):
		_place(c, site, yaw)
		c.call("set_roost", site)
	elif c.has_method("place"):
		_place(c, at, yaw)
	else:
		c.position = at
	return c


## (Each kind's own place(): at a point alone; or with the way it faces, a
## yaw or a direction.)
static func _place(c: Creature, at: Vector3, yaw: float) -> void:
	var sc: Script = c.get_script()
	var n: Variant = _place_args.get(sc)
	if n == null:
		n = 2
		for m: Dictionary in c.get_method_list():
			if m.name == "place":
				var args: Array = m.args
				n = 1 if args.size() < 2 else (3 if int((args[1] as Dictionary).type) == TYPE_VECTOR3 else 2)
				break
		_place_args[sc] = n
	match int(n):
		1:
			c.call("place", at)
		3:
			c.call("place", at, Vector3(-sin(yaw), 0.0, -cos(yaw)))
		_:
			c.call("place", at, yaw)


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
