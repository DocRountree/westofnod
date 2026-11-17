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

## What's in `Species.TABLE` (102 kinds, each a record with a body or without)

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
- The sea's floor: the common octopus and the giant Pacific octopus (out at night, back to a den by their
  home by day: the den a hollow under rock, made by its body where its record's home is, `set_home`), the
  ochre sea star, the eccentric sand dollar (in beds: `herd`), the purple urchin, the Pacific littleneck clam (in
  beds, dug in: `sessile`, spawning with those near where it is), and the giant kelp: a plant (`plant`), its height
  the water's, no brain but to grow: its young sporophytes coming up about it (as its `crowd` allows), and killed by
  urchins crowding its holdfast past what it bears (`grazers`: an urchin barren where nothing eats them down).

- The rest with bodies of their own: the three dogs (no density: put there, not seeded), the box turtle, the
  blue-winged grasshopper, the fishing and grass spiders, the ichneumon and trigonalid wasps, the cecropia
  and polyphemus moths, the white, brown and pink shrimp.
- The swarms, each one record, its body a `SwarmBody` (the colony, the band, the pool itself under it, made
  when it's near as any body is, freed when it's far): carpenter and harvester ant colonies (left to find
  their own food: `auto_forage`), June and lady beetles, fireflies, grass snails and tigersnails, deer and
  lone star ticks, krill, mollies. A swarm isn't steered and has no brain to speak of: it does as it does.
  It doesn't breed and isn't hunted as a record (what eats of it does so from its body, as in the sandbox).

`Species.register(key, entry)` adds another, or changes one's figures (its `density` by biome, above all).

## Young

- A mammal's, a bird's, a reptile's, a fish's: records by their mother, her kind's young body by hers.
- A spider's, a grasshopper's, a mantis's, a scorpion's, a pill bug's, a dragonfly's: laid and left, on their
  own from the first (not at her side, so she may breed again after her gap), their kind's own young body.
- A butterfly's or a moth's (`larva`): laid and left; near the player, its egg for the first fifth of its
  youth, then its caterpillar (a `Larva`, going about and feeding as it does), then, from seven tenths, its
  chrysalis or cocoon, then the grown one in its place (`FaunaSim.stage_of`, `restage`).
- The sea floor's (`plankton`): laid and left; near the player, a cloud of them adrift above the bottom (a
  `Plankton`: an octopus's paralarvae, a sea star's bipinnaria, an urchin's or a sand dollar's plutei) for
  the first two fifths of their youth, then settled where the current took them (within twice their range),
  their kind's young body. The echinoderms spawn: his mating is the two of them spawning near each other
  (each a plume), her carrying a quarter of a day. A clam's veligers, the same; its spat dig themselves in.
- An octopus's (`broods`, `semelparous`): she carries them in her den, brooding the eggs hung from its roof
  (she goes home to it and stays: she neither eats nor runs, and puts on her startling display at what comes
  near); when they hatch she dies, and he dies a `gap_days` after he's mated (`Agent.dies_at`, kept in a save).
- A wasp's, a bee's: records with nothing to show (their grubs are in a comb, and there's no comb).

## Known limits

- An octopus's den is made fresh with its body (the rocks aren't the world's); a clam it eats is left an empty
  shell (meta `empty_shell`), its record not kept. Nothing hunts a sea star or a sand dollar.

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
- An egg and a chrysalis are put on the ground where they were laid, not on a leaf or a stem; a bird's eggs
  and its nest aren't made (its young are by her from the first); a frog's young is its tadpole only where
  there's water for it.
- A swarm's numbers don't change (no founding of colonies, no dying out), and its members aren't kept
  between one making of its body and the next (a colony's ants start again about their nest).
- The densities are first guesses, to be tuned in play.
