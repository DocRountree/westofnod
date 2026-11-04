# West of Nod

A Godot 4 exploration game set in the Galapagos archipelago, built from real elevation
data (Copernicus GLO-30), 281 km across, rendered as one continuous world with no
popping. Walk, sprint, swim (as in Minecraft), climb and fly.

## Running

Open the folder in **Godot 4.3+** (Forward+ renderer) and press Play. The start
menu (`menu.tscn`) lists your games, the one played last first: resume one, start a
new one, rename or delete one, or enter **debug mode**. A new game asks for its
**mode** and whether it **allows commands**:

- *Survival*: not defined yet (no flying, no time keys).
- *God*: fly (Space twice), move time (`[` `]`).
- *Allow commands*: every chat command, `/mode survival|god` (or `/gamemode`)
  among them; without, only `/help`, `/pos` and `/clear`, and the mode stays as chosen.

A game saves itself (where you are and look, the time and day, what has been taken
from the world, its mode) every minute, when you leave it and when you quit, to
`user://saves/` (`scripts/session.gd`). Debug mode is the sandbox: god mode, every
command, F6, the frame rate and coordinates on screen; nothing is saved. Running
`main.tscn` on its own (the editor's Run Current Scene, `tools/shot.tscn`) starts
debug mode directly.

| Input | Action |
|---|---|
| WASD, Space, Ctrl, Shift | move, jump, sprint, crouch (on foot: lower and slower) |
| Space / Shift in water | swim up / sink faster (otherwise you slowly sink) |
| Ctrl + W, head under water | sprint-swim wherever you look |
| Z | magnify (a telescope, for now a key); mouse wheel sets the power, 2x-8x |
| [ / ] | *(god mode)* run time backward / forward |
| Enter / `/` | chat / commands (`/help`, `/pos`, `/clear`; with commands allowed also `/tp`, `/time`, `/spawn`, `/fly`, `/zoom`, `/aurora`, `/pop`, `/mode`) |
| F6 | *(debug)* an aurora every night |
| Space ×2 | *(god mode)* toggle fly mode (Space / Shift to go up / down) |
| F5 | toggle third-person camera |
| L | shadows off or on again (every shadow: the sun's and the moon's), for debugging |
| C | climb a tree (next to its trunk: W/S up and down, A/D round it; where a limb leaves the trunk, move its way, or W from just under it, to go out along it; C again on top of a limb stands you on it) or rock too steep to walk (WASD over the rock); Space climbs on up as W does; C again lets go |
| E | the knapsack: 10 slots and a hand each (click to pick up and put down, right-click half or one, shift-click to or from the hands); what the hands hold shows in them. `/give <item> [count]` puts items in it (stick, stone, acorn, oak leaf, pawpaw, crabapple, walnut, susan, fleabane, coneflower, aster, yampah, milkweed, swamp_milkweed, cattail, clay_pot, pot_of_sap) |
| Left mouse | with a hand free: pick the fruit you're looking at (a pawpaw, crabapple or walnut hanging in a grown tree's crown, within about 2.8 m of your eye: climb a tall tree for those up in it), that one, into the left hand (else the right); or, looking at one within about 2.6 m, a flower (black-eyed Susan, fleabane, purple coneflower, yampah, swamp aster, common or swamp milkweed) or a cattail, a clump a click, into a hand empty or holding that kind (16 a hand), the clump gone till the next day. The fruit hang on the trees as real things, as many as are left: some trees bear none, the rest up to six; what's picked is gone till the next day (saved with the game; `scripts/items/foraging.gd`) |
| Left or right mouse | with a clay pot in that hand, looking at the notch an axe has left in a living maple (it drips sap: a drop gathers at its lip and falls): sets the pot on the ground under the drip; it fills as the game's day goes (a whole day while the notch is there), the sap rising in it. With a hand empty (or holding pots), looking at a pot: takes it up, a pot of maple sap if it's full, else the pot again, empty. Notches, part-cut notches and pots are saved with the game (`scripts/items/tapping.gd`) |
| Left mouse | with the axe in a hand (a stone axe: a stick with a sharp stone lashed to it with twine; a new game starts with one in the right): swing it (held down, it swings again and again until the tree is down); at a tree's trunk (an oak or a pawpaw: live, dead or a sapling), each blow cuts a notch deeper and wider on your side of the trunk, at the height you aim the first blow at (where your view meets the trunk: from about 12 cm up to about 1.9 m, never above two fifths of the tree), and the tree breaks there, leaving a stump that tall, and enough (more the thicker it is) fell it: the axe swings sideways, from its hand's side across, aimed at the notch (in third person the figure turns to it, both hands on the handle, the arms following it round); the notch is a real hollow cut in the trunk, showing the wood's rings, on the side the axe swings in from (square to your view); the blade stops in it, no follow-through; the tree falls toward the notch's side (square to your view), its foot (cut off clean at the notch: the tree's meshes themselves cut across there, every level of detail, and closed by a face of fresh end grain through the very outline the cut leaves, so nothing of it below the cut can show, from any side or distance: `scripts/items/mesh_cut.gd`) landing a little beyond the stump (its trunk lying along the ground, pressed in only a few cm, pitched up from its foot where it would otherwise sink further; its crown and limbs go into the ground as they will; trees felled before this are laid again so when the game loads) (its top chopped flat in strokes square to the notch, as is the felled trunk's foot, fresh pale wood, no moss), and lies there, to stand on and climb as a log and a tree are, its stump too (saved with the game; `scripts/items/felling.gd`) |
| Esc | pause: resume, save, main menu, quit (the mouse is freed) |

## Data (`tools/dem/bake_galapagos.py` → `data/world/`)

Source: Copernicus GLO-30 DEM, nine 1° tiles around 89–92° W on the equator ("produced
using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH
2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved").
The baker reads only the window it needs and writes:

- `heights.f16.gz`: 8192² half floats at 34 m, projected to local metres. The real
  coastlines stay, but the volcanoes are replaced by full-resolution GLO-30
  mountains from elsewhere (Madeira, Corsica, Kefalonia, Lofoten, La Gomera),
  rotated, scaled to 0.4× height on a 0.65× footprint (so they stay steep),
  faded out at a ragged rim, and chained into ranges with open lowland
  between. Bigger islands get more of them, a little taller (~2.5 km on
  Isabela). The humid cover stops by ~2000 m. The ranges on Isabela's southern
  lobe (the "plateau" biome) are remade as mesas: cut flat at ~45% of their
  height, a cliff wall up to 250 m round the rim, the flanks below lowered less
  and less down to the lowland (`mesas` in the baker).
  The sea floor is real bathymetry (AWS Terrain Tiles: ETOPO1 and NOAA, ~150 m),
  made shallower for diving: depth compressed smoothly to 80 m x tanh(depth / 400 m),
  so a 100 m shelf is ~20 m and the open ocean ~80 m, shapes kept; near the shore
  no deeper than a gentle ramp from the coast. Downloaded tiles are
  cached in `tools/dem/.cache/`, so a rebake takes about two minutes.
- `masks.png`: young lava (rough, bare), humid highlands (wetter on the south-east,
  windward side), trees (sparse grey scrub low, green Scalesia forest high, none on
  lava or the summits), sand.

The ground drawn and collided with is a cubic B-spline through the samples plus
procedural relief below 34 m (`terrain_height` in `height_map.gdshaderinc`, mirrored
by `WorldData.height_at`).

To rebake: `pip install numpy scipy rasterio pillow`, then
`python tools/dem/bake_galapagos.py .`

## Rendering (`scripts/world/`, `shaders/render/`)

- **Floating origin** (`scripts/world/origin.gd`, `origin.gdshaderinc`): the map is
  ~280 km across, and a 32-bit float only resolves a few mm tens of km out, so drawn
  at map coordinates everything shimmered as the view turned. Everything in the world
  (terrain, sea, trees, grass, the player) hangs from one node, `Origin.root`, moved
  by -`Origin.offset`, which follows the player in whole 1024 m steps: what's drawn
  is always within ~1.5 km of the origin. The game works in map coordinates (a world
  node's `position`); global positions are drawn ones (`Origin.map()` /
  `Origin.render()`); shaders add the global shader parameter `world_origin` to a
  drawn position wherever they go by the map (heights, biomes, noise, hashes, wind).
- **Terrain**: one CDLOD quadtree over the height map; patches morph into the next
  coarser level toward the end of their range, so there are no cracks and no pops.
  Normals and materials are per pixel, from the finest mip a pixel can show.
- **Sea**: Gerstner waves on a camera-centred grid; they read the sea floor from the
  height map and shrink to nothing at the shore, and the terrain hides them on land.
- **Water lighting** is ported from DocRountree/game (`water_core.gdshaderinc`, its river
  shader's optics and "Adrift" flowing ripples in `water_ripples.gdshaderinc`):
  refraction never pulling in what's in front of the water, Beer-Lambert absorption,
  the body's own colour (clear high up, silty low down, sea water at the mouth),
  Fresnel, a capped GGX sun highlight, and gloss falling away with distance. With MSAA
  the depth buffer can't be read, so the water's thickness falls back to the channel
  depth (rivers) or the sea floor (sea) and the view angle.
- **Trees**: English oaks, sugar maples, black walnuts and crabapples in the
  forest (a few of each on the prairie), pawpaws in its understory (only there), lodgepole pines and bald
  cypresses thick in the taiga (a few in the forest), sycamores in the swamp
  (sparse; the living more at its edges, the dead in its middle; no lichen on
  them); every one choppable
  (`data/population/README.md`), streamed by `Population`.
  Their bark carries lichen (leafy rosettes, cracked crust with fruiting discs, a
  powdery yellow-green crust: `data/population/textures/lichen.png`, drawn lobe by lobe
  by `tools/trees/bake_lichen.py`, each tree reading it from its own place, in drifts,
  within 30 m only), and the stumps and logs moss (a cushion of little leafy shoots,
  `moss.png` from `tools/trees/bake_moss.py`, thinning to tufts at its edges; over
  it, within 4 m of you, red stalks a couple of cm tall with purple capsules,
  standing straight up, only on the green moss: `sporophytes.gdshader`, a MultiMesh per log or stump drawn
  only for those near you (`Population._update_near`; which of a log's stand on its
  moss worked out once on a worker thread as you come near, only those drawn); a stump's top almost covered and
  spilling over, patches up from the ground); on the prairie the standing trees
  only a little lichen (the logs and stumps their moss and lichen as anywhere),
  in the swamp the most; none on saplings
  (`lichen.gdshaderinc`).
- **Grass and ferns** (`scripts/population/ground_cover.gd`, `ground_cover.gdshader`):
  grids of cells follow the camera in tiles (a tile where its layer can't grow, by the
  biomes reaching it, isn't drawn: the reeds' off the swamp, the ferns' off the forest). When a grid moves, a SubViewport works out
  every cell once (`ground_cover_bake.gdshader`: what grows, how tall, its height on the
  ground, the ground's colour) into a small texture, and each vertex just reads it. In
  the forest: dense short grass the ground's own colour, and drifts of knee-high ferns
  (a recursive frond texture), none on the leaf litter or the mud; on the prairie,
  grass about up to head-high (1.5-2.0 m), green to blonde, out to 125 m; across a border the one turns into
  the other. Among the prairie's grass, wildflowers in drifts: black-eyed Susans
  (golden rays drooping round a dark brown dome) and fleabane (a few small heads a stem, fine rays
  pure white to light purple, a little lower) and purple coneflowers (pink-purple rays hanging
  from a raised orange-brown cone) and yampah (white umbels, knee-high in the forest too), their heads up among the grass's tips; to 38 m. In the swamp, broad-bladed reeds 1.8-2.3 m tall in clumps here and there,
  standing in the water too, and a few swamp asters (branching, violet heads round yellow discs), sparse, and swamp milkweed (branched, narrow-leaved, flat clusters of deep pink flowers). On the prairie, common milkweed in loose colonies (a stout stem, broad paired leaves, drooping balls of mauve-pink flowers). Nothing grows under a log or stump, or in a trunk or boulder
  (`Population.walk_near`). Clumps dissolve in and out (stippled) with distance, by which point their
  colour is exactly the ground's (`ground.gdshaderinc`, shared with the terrain). The
  forest floor also has patches of damp, matte mud, and its brown patches carry a
  texture of fallen oak and maple leaves near the eye; the taiga's floor, rusty grey-brown
  needle duff in mottles between dark feather moss, a texture of fallen pine needles (and the
  odd cone and twig) the same way. Textures:
  `tools/ground/bake_ground_textures.py`.
- **Player** (`scripts/avatar.gd`): a stylised figure animated procedurally with two-bone
  IK. Walking: feet step in turn, arms swing. Climbing: hands and feet hold points on
  the rock surface (projected onto the terrain along its normal) and move one at a
  time to new holds ahead. Climbing switches to third
  person; the camera's spring arm is a sphere and it is kept above the terrain.
- **Atmosphere** (`aerial.gdshaderinc`): aerial perspective written to each shader's
  FOG, after lighting: skylight scattered into the view (blue fills in first, as in
  Rayleigh scattering), thinner with height, warmer toward the sun. Distant greens
  desaturate and turn blue (blue scatters ~3x more than red, so middle distance goes
  blue before far distance fades to the horizon colour).

## Layout

- `scripts/menu.gd` (`menu.tscn`, the main scene) is the start menu; `scripts/session.gd`
  the saved games and the mode; `scripts/pause_menu.gd` the pause menu.
- `scripts/main.gd` builds the scene.
- `scripts/world/`: `world_data.gd` (loads the data, textures, height and water
  queries), `cdlod.gd`, `scatter_field.gd`, `prop_meshes.gd`,
  `terrain_collider.gd`.
- `scripts/player.gd`, `scripts/hud.gd`.
- `tools/shot.tscn` is a scripted fly-through that saves screenshots.
- `scripts/creatures/ant_colony.gd`: ants (`AntColony`, black carpenter ants at twice
  life size; `harvester_ants.gd`, `HarvesterAnts`: red harvesters, rust red, a big squarish ridged head, toothed
  mandibles, the beard of hairs under it, propodeal spines, a two-noded waist, a glossy gaster), not yet in the game:
  their bodies smooth shells lofted along them (the gaster's segments lapping), one mesh, every ant an instance of it, posed by its
  shader (`shaders/render/ant.gdshader`: a tripod gait, the antennae sweeping, the
  head, mandibles and gaster) from the clock and each ant's speed and feeding, so a
  colony is one draw call; the CPU only moves them along (wandering, or to food and
  feeding, keeping apart). `tools/creatures/ant_demo.tscn` (keys: 1 wander, 2 feed on
  the crumbs, 3 half and half, + / - more or fewer, 4 the other kind).
- `scripts/creatures/mollies.gd` (`Mollies`): sailfin mollies (*Poecilia latipinna*), life size, in schools, made
  and moved as the ants are: one mesh, every fish an instance of it, posed by `shaders/render/molly.gdshader` (the
  body's wave down to the tail, faster and wider swimming fast; curved into its turns; the pectorals sculling as it
  hovers; grazing's pecks; the male's great spotted, orange-edged sail half folded swimming, raised and quivering to
  display), so a school of hundreds is a draw call. Olive above, silvery sides, a net of scales with rows of dark
  spots; the males iridescent, orange throated, their gonopodium; the females' small dorsal and fan of an anal fin.
  The CPU side schools them (keeping apart, going their neighbours' way, staying together; the school wandering the
  water it's given, `swim_to`, `scatter`), sends one down to graze now and then, a male to display beside a female;
  each steerable (`member(i)`, pilot.gd). `tools/creatures/molly_demo.tscn` (a tank of them; keys: 1 school, 2 graze,
  3 the males display, S scatter, M move the school, P one steered, + / - more or fewer); a few in the life cycle
  demo's pond.
- `scripts/creatures/beetles.gd` (`Beetles`): beetles at twice life size, not yet in the game, the make they
  share: made and moved as the ants are (one mesh, the same shader, the same CPU side), each species its own shape,
  markings, colours and pace, walking, eating at a leaf and flying (the elytra, one
  unbroken shell at rest, parting and rising, the hind wings unfolding and beating, nose up). `june_beetles.gd` (`JuneBeetles`, *Phyllophaga*: glossy
  reddish brown, ridged wing cases, a fan of plates on each antenna, spurred legs) and `lady_beetles.gd`
  (`LadyBeetles`, *Hippodamia convergens*: orange-red, thirteen black spots, the black pronotum edged white with its
  two converging white dashes). `tools/creatures/beetle_demo.tscn` (both kinds; keys: 1 walk
  about, 2 eat at the leaves, 3 half and half, 4 fly, 5 half fly, + / - more or fewer).
- `scripts/creatures/wasp.gd`: a paper wasp (`Wasp`, drawn at twice life size), not yet in the game: its model
  built from parts, posed by hand every frame, its animations methods (seek food, feed
  on a flower, catch and eat a caterpillar, land and walk about and settle, sting).
  `tools/creatures/wasp_demo.tscn` puts one on a plain with a clump of the game's purple coneflowers, a caterpillar on a
  leaf, a plank and a ball (and for the scale the player's figure with its axe, and a pawpaw, a
  black-eyed Susan, a yampah and a cattail on the plank), each animation on a key (`godot --path . res://tools/creatures/wasp_demo.tscn`);
  and every other creature beside it, each at its own place (the hummingbird moth and the monarch round a patch of the
  game's flowers, milkweeds among coneflowers, Susans, fleabane, asters and yampah, and a stone, ants round a crumb, June bugs and lady beetles round their leaves), their animations on keys too, Tab following each in turn.
- `scripts/creatures/hexapod.gd`: a walking insect built from parts (feet planted in a tripod gait, legs reaching
  hip to foot; leaps, flights, falls on a thread), under `grasshopper.gd` (`Grasshopper`: a differential
  grasshopper, its herringboned hind legs; walking, hopping, flying, eating; laying an egg pod in the soil, which
  hatches nymphs up out of the ground) and `mantis.gd` (`Mantis`: a Carolina mantis, its raised prothorax, turning
  head and raptorial forelegs; stalking with its rocking sway, watching, striking a fly and eating it, grooming,
  flying; building a foam egg case on a stem, whose nymphs come out along its seam, let down on threads). Their
  nymphs small, wingless (the mantis's abdomen curled up), growing. Not yet in the game:
  `tools/creatures/life_cycle_demo.tscn`'s last two stations (keys 6-0, G).
- `scripts/creatures/snake.gd` (`Snake`): snakes, life size, not yet in the game: the eastern diamondback
  rattlesnake (broad triangular head, heat pits, slit pupils, the stripe through the eye, dark diamonds edged in
  cream, keeled scales, a banded tail and its rattle; a newborn only a button) and the eastern milk snake (narrow head,
  black-edged red-brown saddles on grey tan, a checkered belly, the pale V on its nape, glossy; a hatchling bright
  red). One skin bent along a spine (`shaders/render/snake.gdshader`), the body following its head's sinuous path
  (lateral undulation), the tongue flicking; coiling; eating a mouse (the rattler coils, rattles, strikes and lets go,
  waits, swallows; the milk snake strikes, constricts in its coils, swallows: the jaws gaping, the meal a bulge going
  down). The milk snake lays leathery eggs that hatch (a slit, the young's head out, then the young); the rattler gives
  birth, each young in a clear membrane it wriggles out of. In the life cycle demo (keys R, M, C, W; Y: every
  young creature eats: the larvae, the nymphs, the young snakes).
- `scripts/creatures/spider.gd` (`Spider`, on `hexapod.gd`'s eight-legged gait): a Carolina wolf spider (its egg sac
  carried on its spinnerets, its spiderlings riding on its back), a six-spotted fishing spider (running on water, its
  sac carried in its jaws, a nursery web spun over it to hatch in), a grass spider (a funnel weaver: its sheet web laid
  in sweeps out from its funnel, waiting at the mouth, rushing out at prey and dragging it in) and a yellow garden
  spider (its orb spun off a branch thread by thread, frame, radii, spiral, the zigzag stabilimentum; at its hub head
  down; prey wrapped in silk; its brown papery sac hung). Lofted bodies with their marks
  (`shaders/render/spider.gdshader`), eyes in their families' patterns, chelicerae, palps, spinnerets; silk
  (`shaders/render/silk.gdshader`) drawn as far as it's spun. Hunting, eating, laying, hatching, spiderlings.
- `scripts/creatures/isopod.gd` (`Isopod`): a pill bug, overlapping plates over seven pairs of legs; walking, eating
  leaf litter, rolling into a ball; its eggs carried in a brood pouch that swells, its young (six pairs of legs) walking
  out from under it.
- `scripts/creatures/mouse.gd` (`Mouse`, on `hexapod.gd`'s motor with four legs, trotting): a deer mouse
  (*Peromyscus maniculatus*), life size: brown above, grizzled, white beneath with the sharp line between, white feet,
  big black eyes, big round ears pink inside, whiskers, orange incisors, its long tail dark above and white below
  (`shaders/render/mouse.gdshader`); mammal legs (the elbows back, the knees forward, the long hind feet flat heel to
  toe). Scurrying, stopping to sniff (nose, whiskers and ears going), sitting up to look; eating a seed sat up on its
  haunches, turning it in its forepaws, nibbling it away; washing its face. The female gives birth in her grass nest
  (`Mouse.nest()`), licking each pup clean, then nursing; the pups born pink, hairless, eyes shut, ears folded,
  wriggling where they lie; growing, furred grey, eyes open, up and about, brown as they grow up.
- `scripts/creatures/carnivore.gd`, the four-legged hunters' make (on `hexapod.gd`'s motor), life size, under
  `red_fox.gd` (`RedFox`: rufous, grizzled, white beneath, black stockings, a narrow white-sided muzzle, amber slit-pupilled
  eyes, big black-backed ears, a full brush tipped white) and `bobcat.gd` (`Bobcat`: tawny to grey, spotted and barred,
  a barred ruff, white about the eyes, black-backed tufted ears with a white spot, a short barred tail black-tipped
  above); coats by `shaders/render/carnivore.gdshader`. Digitigrade legs (upper, lower, the long metapodial, the paw on
  its toes; a lifted paw curled); gaits by speed, each foot planted where it's set down: a walk (each foot in turn), a
  trot (the diagonals), a gallop (the back flexing, rising and pitching); the head on its neck, looking, sniffing; the
  ears turning, pricked, laid back; the tail carried low walking, out behind running, low stalking, curled round its
  feet sitting and round its nose asleep. Wandering (sniffing, looking, sitting, marking: the fox squatting, the bobcat
  scraping); hunting (stalking low and slow, freezing; the fox listening, head cocked, then its high arcing pounce
  diving nose first; the bobcat treading, tail tip twitching, then the rush and the spring), the prey (a deer mouse,
  a snowshoe hare: anything with die()) killed, carried, eaten (tearing, chewing, it shrinking away); grooming (a
  forepaw licked, the face washed, a flank licked); sitting; sleeping curled, then a stretch. The female gives birth in
  her den (`RedFox.den()`: a mound of dug earth; `Bobcat.den()`: a shelter of rocks), lying on her side, licking each;
  nursing them at her belly; the young born blind and helpless (a fox kit dark grey brown, a kitten spotted, greyer),
  wriggling to her, growing, eyes open, following her, playing (stalking, pouncing on one another, tumbling). Mating:
  the fox's tie (he mounts her, then turns round off her, and they stand tail to tail a long while); the bobcat's
  nape bite, brief, then she rolls on her back and he springs away.
- `scripts/creatures/hare.gd` (`Hare`, on `hexapod.gd`'s motor, its gait its own): a snowshoe hare (*Lepus
  americanus*), life size, in its summer coat (`shaders/render/hare.gdshader`: brown, grizzled, darker along the back,
  white beneath, the hind feet paler, the ears black tipped); long spoon ears turning, laid back, pricked; big eyes
  high on its sides, the split lip and twitching nose, whiskers, a powder-puff tail; slender forelegs, the huge flat
  furred hind feet. Hopping (the hind feet pushing off together, a moment in the air, the forefeet down one then the
  other, the hind feet swung past them to land ahead; slow or bounding, quick to get going); still, hunched in its
  form. Browsing clover (`Hare.clover()`) or sitting up to a willow shoot (`Hare.twig()`), the jaw grinding side to
  side; grooming (licking its paws, washing its face, drawing an ear down); sitting up alert; thumping; freezing flat,
  ears back; fleeing in zigzag bounds. The female gives birth in her form, licks each leveret, nurses them standing
  over them, leaves them hidden and still (`nurse()`: back to nurse); the leverets born furred, eyes open, hopping soon,
  growing. Mating: he chases her round, she leaping up; on her from behind, briefly; she leaps away.
- `scripts/creatures/anole.gd` (`Anole`): a green anole (*Anolis carolinensis*), life size: leaf green above,
  white beneath, finely pebbled, turning brown (still a long while) and green again (`shaders/render/anole.gdshader`:
  its body and tail one skin bent along a spine, the trunk swinging side to side with its stride, the tail waving
  after it along the ground); a long pointed head, eyes in turrets, a hinged jaw; four sprawling legs, long splayed
  toes; the male's pink dewlap flared to display (only his). Darting and stopping, head bobs and push-ups; hunting
  (watching, creeping, a dash and a snap, chewing); the female digging a hole with her snout and laying one leathery
  egg in it, covered over (`Anole.AnoleEgg`: a slit, the hatchling out); mating (his display, then on her, his jaws
  on her nape, his tail twisted under hers).
- `scripts/creatures/scorpion.gd` (`Scorpion`, on `hexapod.gd`'s eight-legged gait, twice life size): an Arizona
  bark scorpion (*Centruroides sculpturatus*): straw yellow, slender; carapace and eyes, the mesosoma's tergites,
  the five-segmented tail (coiled to its side at rest, arched over its back walking) and the telson's curved sting,
  long slender pedipalps and chelae, chelicerae, pectines. Ambushing, creeping, seizing prey in its chelae and
  stinging it, tearing at it (`Scorpion.cricket()`); live birth (up on her legs, her forelegs a basket, the white
  scorplings climbing onto her back and carried, then down and away, yellowing as they grow); mating, the promenade a
  deux (juddering, his chelae holding hers, to and fro, a sting at her pedipalp, his spermatophore laid and her drawn
  over it, then he's off).
- The desert's plants, built whole, not in the game yet (`scripts/population/plant_mesh.gd`, `PlantMesh`: swept and
  ribbed tubes, tapering blades, spines, ellipsoids, painted per vertex): `joshua_tree.gd` (`JoshuaTree`: the trunk
  corky low, every branch shaggy with its dead leaves, forking crooked into an open crown, a ball of stiff blue-green
  dagger leaves at each tip; old, younger, young with its skirt to the ground, in flower), `san_pedro_cactus.gd`
  (`SanPedroCactus`: blue-green columns rising from the base, broad rounded ribs, felted areoles with a few short
  spines along the crests, pinched at each year's growth, domed paler tips, corky at the foot; huge white flowers on
  dark tubes) and `prickly_pear.gd` (`PricklyPear`: obovate pads off one another's rims, glochid tufts and pale spines
  in diagonal rows, the oldest pads woody; wine-red tunas, yellow flowers). Four variants each, three levels of
  detail (`build(v)`, `build_lods(v)`); `tools/plants/preview.gd` renders them (`xvfb-run godot --path .
  --resolution 1600x900 --script res://tools/plants/preview.gd -- <out_dir> [joshua | sanpedro | pear]`), and the
  life cycle demo's last station has them all.
- Mating (every species but the ants: their workers don't; `hexapod.gd`'s `mate(partner)` for the walkers, each
  species saying how): a male of each (`male`, set before it's added; told apart only where it must be: the male
  spiders smaller with the swollen bulbs of their palps, the garden spider's male a quarter her size, tan and slender;
  the male mantis smaller and slimmer, his wings over all his abdomen; the male grasshopper smaller). The
  grasshopper's rides her back, his abdomen curled down round to hers; the mantis's creeps up behind her, freezes
  swaying, leaps on, and she twists round and eats his head; headless he goes on, then falls off her dead. The
  spiders' males first charge their palps: a little sperm web spun, a drop laid on it, drawn up into each palp in
  turn; then courting (the wolf spider waving and drumming, the fishing spider tapping, the grass spider and the
  garden spider plucking); the wolf and fishing spiders up on her front facing back, leaning down each side in turn
  to put a palp in to her, its bulb swelling; the grass spider's female gone still, over on her side; the garden
  spider's male up her web to her at the hub, under her, and dead on her after his second, wrapped in her silk. The
  pill bug's male on her back leaning down one side and then the other; the beetles' riding their females' backs (the
  colony's own: `Beetles.mate(i, j)`); the butterflies and moths, the male chasing her down, joined end to end; the
  wasp's pouncing on her back, stroking her antennae; the snakes', the male crawling up along her back, chin rubbing,
  their tails twisted together; the mice's, the male following her, mounting from behind, thrusting in bouts, then
  washing. `act("mate", {partner})` for any of them (pilot.gd).
- Not yet in the game: `tools/creatures/life_cycle_demo.tscn`'s last twelve stations (F the spiders hunt, S the web
  spiders spin, O the pill bugs roll; E the mice eat, Q wash; H the anoles and scorpions hunt, D the anoles display; B the hares browse, U sit up, T thump,
  X flee, N nurse; J the fox and bobcat hunt, L sleep, I groom, Z mark, A sit, V their young play;
  K every pair mates; 1 lay and give birth, 4 hatch, Y the young eat; the last, the desert's plants).
- Steering, for a future state machine (`scripts/creatures/pilot.gd`): every creature (`Wasp`, the
  lepidopterans, `Grasshopper`, `Mantis`, `Snake`, `Larva`; one of a colony: `AntColony.member(i)`) has the same
  calls: `go(direction, speed, seconds)`, `go_to(point, speed)`, `face(direction)`, `stop()`, `act(name, args)`
  (`behaviours()` lists its own: eat, lay, hop, fly, strike, watch, groom, coil, bask, feed, land, sting, ...),
  `is_busy()`, the signal `action_finished(name, ok)`, and `height` (a Callable, the ground's y at x, z: for the
  walkers and crawlers; the ants' already had it). Driven, a creature sets aside its own wandering, and holds still
  once an order's done. The life cycle demo's P runs a few creatures through orders one after another this way.
- Life cycles (not yet in the game): eggs (`scripts/creatures/brood.gd`, `Brood`; `egg.gd`: rice grains, each kind
  its size and colour) laid by the butterflies one to a leaf (the clearwing hovering), by the wasp one to each cell of
  its comb (`Wasp.comb`, `lay_eggs`), by the beetles in a cluster (`AntColony.lay`, a beetle's: tipped tail down; the
  ants don't lay: their queens' eggs lie in piles); every egg hatches (`hatch`: rocking, the larva out, small,
  growing up; a caterpillar eats its shell first, any other's collapses and fades). Their larvae (`larva.gd`, `Larva`: one smooth skin bent along
  a spine the CPU moves, by `shaders/render/larva.gdshader`, its creases shallow; a crawler bending at most a little
  a joint; the grubs lying on their sides, legs in): the monarch's banded caterpillar with its filaments, the
  clearwing's hornworm, the lady beetle's crawling "alligator", the June bug's C-curled white grub, the wasp's and
  the ants' grubs; caterpillars rippling as they crawl, grubs curling and uncurling. The lepidopterans' pupae
  (`pupa.gd`, `Pupa`, lofted shells painted by `shaders/render/pupa.gdshader`): the monarch's jade lantern of a
  chrysalis on its black stalk, its black and gold crown, gold spots; the clearwing's glossy mahogany pupa, ringed,
  spiked, in a ragged cocoon in the litter. They ripen (the monarch's going clear, its wings showing through),
  wriggle, split, and are left empty skins; the adult pushes out (the monarch head first, down; the clearwing out of
  its cocoon), turns or climbs to hang, its abdomen swollen, its crumpled wings hanging down and pumped out to full
  size, dried, opened and closed (`Lepidoptera.emerge`); then flies. `tools/creatures/life_cycle_demo.tscn`, a station each (keys: 1 all lay, 2 the pupae hatch, 3 new
  pupae, 4 the eggs hatch, 5 new ant eggs, Tab the next).
- `scripts/creatures/lepidoptera.gd` (`Lepidoptera`): a butterfly or moth at twice life size, not yet in the game: built
  from parts (furred where the species is), its wings cut to their real outlines and painted, veins, borders and
  spots, above and beneath (`tools/creatures/bake_lepidoptera_wings.py` bakes `data/creatures/lepidoptera_wings.png`
  and the outlines, `scripts/creatures/lepidoptera_wings.gd`; drawn by `shaders/render/lepidoptera_wing.gdshader`), flying (beating, gliding, a blur
  past the eye's speed), perching, its proboscis uncoiling to a point. `hummingbird_moth.gd` (`HummingbirdMoth`,
  *Hemaris thysbe*: search, darting from hover to hover and looking in at flowers; feed, hovering at a flower's florets,
  its proboscis in each) and `monarch.gd` (`Monarch`, *Danaus plexippus*: fly, flap and glide; bask on a stone, its
  wings spread; feed on a flower, its wings closed over its back). `tools/creatures/lepidoptera_demo.tscn` shows them
  in a patch of the game's flowers (`DemoFlowers.patch`: three clumps of common milkweed, one of swamp milkweed,
  coneflowers, Susans, fleabane, asters, yampah) and a stone, each animation on a key.

## The planet and the sky

The map wraps like a sphere but is drawn flat: x is longitude (crossing the
map east to west is once round the planet) and z is latitude, with the north
and south edges as the poles. Off the east or west edge you come back on the
other (that seam is the date line); over a pole you come back down the same
edge half a world along, facing the other way. The edges are all deep ocean,
so the seams don't show, and the waves carry on across them (`_wrap` in
`scripts/main.gd`). The HUD shows your latitude and longitude.

The sky, clock, sun, moon, planets, stars, meteors and aurora are ported from
DocRountree/game (`scripts/sky/`, `shaders/sky/`): a single-scattering
atmosphere with a sun that reddens through the same air, a fixed calendar day
(the 2026 winter solstice) with a 15-minute day and a 10-minute night, real
star, moon and planet positions for your latitude, and the clock keeps your
local time as you travel east or west. One night in three has an
aurora, seen only north of 45°N (`AURORA_LATITUDE` in `scripts/main.gd`);
the farther north, the higher it stands. The haze is applied to land, sea and
props only, never to the sky.

## Magnifying

Z magnifies the view (2x to 8x, mouse wheel). Detail is chosen as if
everything were that many times nearer: terrain patches, relief, props,
shadows. Only the wedge you see gets
the extra detail (`ScatterField.magnify`, `Cdlod.magnify`). Stars stay points
but gather light like a telescope (magnification squared), so fainter ones
appear: about 104,000 real stars from V 6.5 to 10.5 out of the HYG database
(`data/faint_stars.f32`, built by `tools/build_faint_stars.py`; HYG (c) David
Nash / astronexus, CC BY-SA 4.0). Open clusters split into their real stars
as their glow fades; nebulae show the real stars inside them; galaxies show a
bright nucleus, and their satellites (M32 and M110 by M31) come up. Globular
clusters stay glows, as they do at this power.

## The Milky Way

Stars only, no colour, no dust, no painted glow (`shaders/sky/milky_way.gdshader`):
every star from V 10.5 (where the real catalogues stop) to 17.5, generated on
the sky from a hash, in counts per magnitude and per patch of sky from a
star-count model of the Galaxy (a disc concentrated toward the plane, brighter
toward the centre, and the bulge in Sagittarius). Stars a pixel can separate
are drawn as points; where they're packed tighter, a pixel shows the summed
light of the stars that fall in it, as grain fixed to the sky, lifted for the
dark-adapted eye. Magnifying resolves that grain into stars. On the game's
fixed date (the December solstice) the galactic centre is up by day, behind
the sun, as it is in reality; at night the band runs through Carina, Crux,
Monoceros and Auriga.

## Biomes

`tools/map/biomes.py` assigns them (forest, mesa, prairie, swamp, tundra,
island, coast; mountains become taiga, plateau or volcano by what surrounds
them); `tools/map/render_map.py --biomes` draws the biome map, and
`tools/map/bake_biomes.py` (run by the baker) writes `data/world/biomes.png` for
the game. The terrain shader colours each biome its own way (`biome_ground` in
`terrain.gdshader`: leaf litter, red sand and scrub, golden grass, mud and
pools, moss and lichen with snow, needle duff and moss, banded red sandstone walls on
scrubby caprock, black basalt and ash, beach and dunes), blending across the
borders over about 200 m (the sixteen nearest texels of the biome map by a cubic
B-spline, the borders wandering, so each biome reaches into the next in tongues
and islands; a pixel works out the two biomes with most of it, `biome_top`; `biome_ground` lives in `ground.gdshaderinc`, which the grass shares);
the borders also wander in kilometre-wide tongues and islands; the trees are
picked by the same shares (`WorldData.biome_blend_at`), each read a few hundred
metres off at random, so they thin out across a border into scattered oaks and
copses, thinning out up the mountains. Past 600 m, where the trees stop being drawn, their canopy is painted on
the terrain (crowns and shadow, as much as the trees there would cover), and the
haze is thicker (6.5 km), so distant land softens and blues. The pale
grounds (prairie, coast, beaches) dim at night, as the leaves do. Marram,
half the prairie grass's height and as pale as the sand, grows in patches on
the coast and beaches: none at the water's edge, thicker and taller up the beach. `/pos`
names the biome you're in.
