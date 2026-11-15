# Animals in the game: what's ready, and how to turn it on

Nothing here is switched on in the game yet. This is what's in place for when it is.

## Turning it on (main.gd, about ten lines)

```gdscript
var fauna_holder := Node3D.new()            # under Origin.root, unmoved: its space is the map's
Origin.root.add_child(fauna_holder)
fauna = FaunaSim.for_world(world, fauna_holder, population.world_seed)
add_child(fauna)
fauna.focus = player.position               # the map's
fauna.prime()                               # behind the loading screen: the land round the player seeded now
# each frame:
fauna.focus = player.position
fauna.daylight = 1.0 - night                # the sky's own figure
# saving / loading (Session's dictionary):
d["fauna"] = fauna.to_dict()
fauna.from_dict(d["fauna"])
```

- `FaunaSim.for_world` sets the ground (`WorldData.height_at`), keeps walkers off the sea and off cliffs
  (`walkable`: above 0.3 m, its normal's y over 0.6), and seeds by each kind's `density` per biome
  (`Species.TABLE`, animals to the square kilometre).
- Seeding: each 128 m cell once, the first time it lies between 150 m and 420 m of the focus (so nothing
  is seen to appear); the same animals in the same places for the same seed; never twice (`seeded` is kept
  by `to_dict()`). Cells never come near are never touched: nothing's simulated where the player hasn't been.
- Bodies: a record gets its body inside its ring (45 m for each metre of its length, 18 to 260 m), one a
  frame at the most, and loses it past 1.35 rings. `Fauna.pace()` is called for you: far bodies' frames
  come every 2nd or 6th frame, unseen walkers' legs aren't posed.
- Time: every figure in `Species.TABLE` is the sandbox's (a deer hungry again in 6 minutes, carrying
  for 2.5). `Fauna.life_rate` scales all of them at once (0.02: a fiftieth as fast).

## What each kind needs to be in `Species.TABLE`

A script with `_init(young)`, `male`, `height`, `place(at, yaw)`, and the steering every `Creature` has. In it
now, with brains (tested with bodies in the sandbox and without): deer, moose, bison, wolf, coyote, fox,
bobcat, black and brown bear, hare, mouse, fox and grey squirrel, opossum, porcupine, armadillo, turkey,
robin, blackbird, cardinal, blue jay, passenger pigeon, Canada goose. `Species.register(key, entry)` adds
another, or changes one's figures (its `density` by biome, above all).

## Not in the table, and why

- Whatever needs water to live in: the fish, the crayfish and shrimp, the frogs and turtles, the otters and
  beaver, the whales, the shark, the krill, the urchins. The game has no ponds or sea floor for them yet
  (`EcologyDemo.WET`); they're steerable (`go_to`, `act`), so a `Species` entry and a `walkable` of their
  own (water, not land) is what's left once there is.
- Whatever lives on something: the raptors and owls (a perch, a nest in a tree: `TreeNest.site`), the bats
  (a roost), the spiders (a web between stems), the butterflies and moths (flowers, host plants), the wasps
  and bees (a comb, flowers). Their bodies run, steered or left alone; a brain for them wants those
  things found in `Population` first (`trees_near`, `climbs_near`).
- The swarms (ants, beetles, snails, ticks, fireflies, fish schools, krill): not records at all, one node
  each. An ant colony left to itself: `auto_forage = true` (it looks for what it eats within
  `forage_range` of its nest and works it, what it can take kept count of on the thing, out of sight).
  They're paced with everything else (`Fauna.swarm_dt`).

## Known limits

- With no body an animal isn't drawn (there is no far, instanced tier yet): the rings are as far as
  anything's seen.
- With no body, food isn't kept count of (a forager finds a meal about every other time it looks; a
  grazer always); a hunt is a chase and a throw of the dice weighted by how much the hunter likes that prey.
- A body's places are the map's, as single floats: tens of kilometres from the map's middle a small
  animal's steps are a few millimetres coarse. (The swarms are in their own node's space, so they're not.)
- Nothing checks a body's way for trees or rocks beyond what each walker already does (personal space
  with other bodies; `Population.push_out` isn't asked).
- Brains don't yet: migrate, den, cache, defend a territory, or care for young beyond keeping them by
  their mother.
