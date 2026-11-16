# Animals in the game: what's ready, and how to turn it on

Nothing here is switched on in the game yet. This is what's in place for when it is.

## Turning it on (main.gd, about a dozen lines)

```gdscript
var fauna_holder := Node3D.new()            # under Origin.root, unmoved: its space is the map's
Origin.root.add_child(fauna_holder)
Fauna.day_secs = (clock.day_minutes + clock.night_minutes) * 60.0   # the game's day: what lives are counted in
fauna = FaunaSim.for_world(world, fauna_holder, population.world_seed, population)
add_child(fauna)
fauna.focus = player.position               # the map's
fauna.prime()                               # behind the loading screen: the land and sea round the player seeded now
# each frame:
fauna.focus = player.position
fauna.daylight = 1.0 - night                # the sky's own figure
# saving / loading (Session's dictionary):
d["fauna"] = fauna.to_dict()
fauna.from_dict(d["fauna"])
```

- `FaunaSim.for_world` sets:
  - the ground (`WorldData.height_at`: under the sea too, where it's the sea's floor, shelving from the shore
    down to the flat at 80 m);
  - the water: wherever the ground is under sea level (surface 0, depth to the ground): the swamps' fresh,
    the rest salt;
  - each kind kept to its own (`Species`' `medium`): the land's off the sea and off cliffs, the sea's in
    water between its `depth` and `max_depth`, fresh water's in the swamps' pools, the shore's on land within
    a dozen metres of water or in its shallows; a body in water is told its surface, its floor and its reach
    (`water_y`, `floor_y`, `pond`, `set_water`, as each kind has them);
  - what they live on (`sites`): perches and roosts in the trees there (`Population.climbs_near`, where its
    trees are made, near the player; a tree's height up in the wooded biomes till then; on the rock
    elsewhere), flowers and webs anywhere on the land;
  - the seeding, by each kind's `density` per biome (`"sea"` the sea), and the far drawing (`FarFauna`).
- Seeding: each 128 m cell once, the first time it lies between 150 m and 420 m of the focus (so nothing
  is seen to appear); the same animals in the same places for the same seed; never twice (`seeded` is kept
  by `to_dict()`). Cells never come near are never touched: nothing's simulated where the player hasn't been.
- Bodies: a record gets its body inside its ring (45 m for each metre of its length, 18 to 260 m), one a
  frame at the most, and loses it past 1.35 rings. `Fauna.pace()` is called for you: far bodies' frames
  come every 2nd or 6th frame, unseen walkers' legs aren't posed.
- Far off: a record with no body is drawn all the same within its reach (220 m for each metre of its
  length, 120 to 1200 m; a bird three times that): one MultiMesh a kind, its shape its own body's as it
  stands (taken once, with its own materials); a bird going any way is on the wing (a body and two beating
  wings in its kind's `tone`). Not the small: nothing under 20 cm, no arthropod (`far`).
- Lives: counted in the game's days (`Fauna.day_secs`). A mammal carries her young 2 days and they're young
  4; a bird 2 and 3; a reptile or a fish 2 and 3; a frog 1 and 2; an arthropod 1 and 1 (`Species.CLASS_DAYS`;
  a kind's own: `gest_days`, `wean_days`, `gap_days`). With the game's three-hour day a deer carries six
  hours. `Fauna.life_rate` scales them all, and hunger and tiredness with them. (Hunger, sleep and the rest
  are still in seconds: a deer hungry again in six minutes.)

## What's in `Species.TABLE` (71 kinds, each with a brain, with a body or without)

- The land's: deer, moose, bison, wolf, coyote, fox, bobcat, both bears, hare, mouse, both squirrels, opossum,
  porcupine, armadillo; turkey, robin, blackbird, cardinal, jay, pigeon, goose; rattlesnake, milk snake, anole,
  gila monster, toad; wolf spider, mantis, grasshopper, scorpion, pill bug.
- Those that live on something: on a perch, the owls (horned, barn, screech), Cooper's hawk, peregrine, both
  eagles, bluebird, goldfinch, house finch, hummingbird; at a roost, the bat; at flowers, the monarch, the
  swallowtail, the hawk moth, the bumblebee, the wasp (the mourning cloak and the luna moth with them, at
  none); in a web, the garden spider. Each is given its place when it's made (the nearest of its kind), rests
  there, and goes back to it; one that flies is flown there (its body's own `fly`).
- The water's: in the sea, the dolphin, the orca, the blue whale, the great white shark, the sea turtle, the
  sea otter and the urchin (those two in the shallows only), schools of salmon and tuna; in fresh water, the
  crayfish, schools of trout; by it, the frog, the painted and snapping turtles, the river otter, the beaver,
  the heron, the dragonfly. A school is one record, its body a `SchoolBody` (a `FishSchool` steered as one
  animal: `go_to`, `feed`, `flee`); what hunts it takes a fish of it, not it.

`Species.register(key, entry)` adds another, or changes one's figures (its `density` by biome, above all).

## Not in the table, and why

- The swarms (ants, beetles, snails, ticks, fireflies, krill, mollies, shrimp): not records, one node each. An
  ant colony left to itself: `auto_forage = true`. They're paced with everything else (`Fauna.swarm_dt`);
  nothing seeds them yet.
- The dogs, the box turtle, the differential and blue-winged grasshoppers, the fishing and grass spiders, the
  ichneumon and trigonalid wasps, the cecropia and polyphemus moths, the sea's shrimp: bodies that would take
  an entry as they are (`Species.register`); not given one.
- Young as their own things: an insect's eggs, larvae and pupae, a frog's tadpoles, a bird's eggs in its nest
  aren't made by a brain (a brain's young are records by their mother, with her kind's young body where it
  has one; an insect's have none till they're grown).

## Known limits

- The sea's floor is the world's own ground under the water: a shelf by the shore, then flat at 80 m. Nothing
  grows on it (no kelp seeded, no reefs), and the debug tools still can't put the water's animals down in the
  game (`EcologyDemo.WET`: their own scene only).
- Fresh water is only where a swamp's ground dips under sea level: there are no ponds, lakes or rivers in
  the world to live in, so the pond's kinds are scarce.
- A body in the sea is told a box of water (its range about where it was made, the floor's depth there): it
  doesn't follow the floor's slope, and turns back at its box's sides till it's made again.
- Far off, an animal stands as it stood when its shape was taken: its legs don't move as it goes; a body and
  its far shape change places at its ring with no fading between.
- With no body, food isn't kept count of (a forager finds a meal about every other time it looks; a
  grazer, a flower-feeder at its flowers, always); a hunt is a chase and a throw of the dice weighted by how
  much the hunter likes that prey; a web catches nothing you'd see.
- A body's places are the map's, as single floats: tens of kilometres from the map's middle a small
  animal's steps are a few millimetres coarse. (The swarms are in their own node's space, so they're not.)
- Nothing checks a body's way for trees or rocks beyond what each walker already does.
- Brains don't yet: migrate, den, cache, defend a territory, build (a nest, a web, a lodge), or care for
  young beyond keeping them by their mother.
- The densities are first guesses, to be tuned in play.
