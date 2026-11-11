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

Debug mode's ecology tools (F9, or `/sandbox`; `scripts/ecology_sandbox.gd`): the ecology sandbox's toolkit
(`tools/creatures/ecology_demo.gd`) in the game itself, which goes on under it. A list (right): a plant, a tree or
bush, an item, a carcass or an animal, as an adult, young or a pupa, female or male; then left click the ground to
put one there, where the view meets the land (again and again; right click or Esc: done). Left click a creature to
select it (Shift: more). What the selected do (none selected: everything put down): the panel's buttons, or Alt with
the sandbox's own key (Alt + E eat, Alt + H hunt, Alt + K mate, ...). Delete takes the selected away. The right
button held looks round, and the keys move you, as ever. What's put down stays and lives there with the tools away
(creatures over the land as it lies; the game's trees with their levels of detail), until the game is left: none of
it is saved. Their places are drawn ones, so the floating origin is held where it is while anything put down is
there; 3 km from it, all of it is taken away. Not there yet: ponds, the sea and what lives in or by them (the
dragonfly, the fishing spider, crayfish, shrimp, krill, the fish, frogs and toads, the turtles, the beaver, the
moose): those are in the sandbox's own scene still.

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
| E | the knapsack: 10 slots and a hand each (click to pick up and put down, right-click half or one, shift-click to or from the hands); what the hands hold shows in them. `/give <item> [count]` puts items in it (stick, stone, acorn, oak leaf, pawpaw, crabapple, walnut, black_cherry, raspberry, blueberry, susan, fleabane, coneflower, aster, yampah, milkweed, swamp_milkweed, nettle, cattail, clay_pot, pot_of_sap) |
| X | take the knapsack off and set it down on the ground before you (on a log or stump if you're on one), or, back beside it (within about 2.2 m), pick it up and put it on again. It's a hide bag, made by hand, nothing on it but hide and twine (`scripts/items/pack.gd`: a soft buckskin sack, its seams laced with a thong; a flap over its mouth, its edge ragged as the skin was cut, fringed; twine wound twice round it over the flap and knotted at its front, the ends hanging; a twine loop on top to carry it by; twisted twine cords down its back for the shoulders), worn on the figure's back (seen in third person). Set down, E doesn't open it: right-click it (looking at it, beside it) to open it there; away from it you have only what's in your hands. Where it is and whether it's worn are saved with the game (rebindable: Settings, Keybindings) |
| Q | drop what's in your right hand (else your left), the whole stack, on the ground just before you (on a log or stump if you're on one): it lies there as it's held, turned onto its longest side, a stack's few spread a little. Left-click it (within about 2.4 m of your eye) with a hand free (or holding the same, with room) to take it up again, as much as the hands hold. Saved with the game (`scripts/items/drops.gd`) |
| Left mouse | with a hand free: pick the fruit you're looking at (a pawpaw, crabapple, walnut, wild black cherry, raspberry, blueberry or acorn hanging in a grown tree's crown, within about 2.8 m of your eye: climb a tall tree for those up in it), that one, into the left hand (else the right); or, looking at one within about 2.6 m, a flower (black-eyed Susan, fleabane, purple coneflower, yampah, swamp aster, common or swamp milkweed), a stinging nettle (the forest's, here and there; it doesn't sting) or a cattail, a clump a click, into a hand empty or holding that kind (16 a hand), the clump gone till the next day. The fruit hang on the trees as real things, as many as are left: some trees bear none, the rest up to six (an oak up to eighteen acorns, two or three together on their long stalks, 10 to a hand); what's picked is gone till the next day (saved with the game; `scripts/items/foraging.gd`) |
| Left or right mouse | with a clay pot in that hand, looking at the notch an axe has left in a living maple (it drips sap: a drop gathers at its lip and falls): sets the pot on the ground under the drip; it fills as the game's day goes (a whole day while the notch is there), the sap rising in it. With a hand empty (or holding pots), looking at a pot: takes it up, a pot of maple sap if it's full, else the pot again, empty. Notches, part-cut notches and pots are saved with the game (`scripts/items/tapping.gd`) |
| Left mouse | with the axe in a hand (a stone axe: a stick with a sharp stone lashed to it with twine; a new game starts with one in the right): swing it (held down, it swings again and again until the tree is down); at a tree's trunk (an oak or a pawpaw: live, dead or a sapling), each blow cuts a notch deeper and wider on your side of the trunk, at the height you aim the first blow at (where your view meets the trunk: from about 12 cm up to about 1.9 m, never above two fifths of the tree), and the tree breaks there, leaving a stump that tall, and enough (more the thicker it is) fell it: the axe swings sideways, from its hand's side across, aimed at the notch (in third person the figure turns to it, both hands on the handle, the arms following it round); the notch is a real hollow cut in the trunk, showing the wood's rings, on the side the axe swings in from (square to your view); the blade stops in it, no follow-through; the tree falls toward the notch's side (square to your view), its foot (cut off clean at the notch: the tree's meshes themselves cut across there, every level of detail, and closed by a face of fresh end grain through the very outline the cut leaves, so nothing of it below the cut can show, from any side or distance: `scripts/items/mesh_cut.gd`) landing a little beyond the stump (its trunk lying along the ground, pressed in only a few cm, pitched up from its foot where it would otherwise sink further; its crown and limbs go into the ground as they will; trees felled before this are laid again so when the game loads) (its top chopped flat in strokes square to the notch, as is the felled trunk's foot, fresh pale wood, no moss), and lies there, to stand on and climb as a log and a tree are, its stump too (saved with the game; `scripts/items/felling.gd`) |
| Right mouse | at a felled tree lying in reach (within about 2.4 m of your eye): forage sticks from it, the limb you're looking at a click: it comes away, gone from the tree as it lies (its twigs and leaves with it, and no longer there to stand on), and its sticks (one for each metre or so of it, up to 8) go into a free hand, the left first, the rest into the other; until only the trunk is left. The limbs taken are saved with the tree (every corner of a tree's mesh knows its limb: `TreeBuilder`, CUSTOM2; `scripts/items/felling.gd`) |
| Esc | pause: resume, save, settings, main menu, quit (the mouse is freed) |

The keys above are the defaults: every one but Esc and the mouse can be rebound (Settings, Keybindings).

Settings (from the start menu and the pause menu; `scripts/settings.gd`, kept in `user://settings.cfg`,
the same for every game): mouse sensitivity and inverted look; field of view; the frame rate on screen; the
window (windowed, fullscreen, borderless), V-sync, a frame rate cap, the render scale (below 100%: FSR
upscaling); shadows (off, low, high: their reach and their maps' size); how far the trees' far cards and the
grass and flowers reach (when a world is next loaded); the volume; the keybindings (`scripts/keybindings_panel.gd`:
click an action, press its key; a key taken from another action swaps with it).

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
  them); wild black cherries in the forest (a few on the prairie), wild
  raspberry and highbush blueberry bushes in its clearings and edges (raspberries
  on the prairie too), their fruit hanging as real things to pick, never painted
  on the leaf cards (`tools/trees/bake_fruit_plant_textures.py`); every one choppable
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
  the saved games and the mode; `scripts/pause_menu.gd` the pause menu; `scripts/settings_panel.gd`
  the settings screen (both menus'), `scripts/keybindings_panel.gd` the keys'.
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
- `scripts/creatures/fish_school.gd` (`FishSchool`): fish in schools, life size, made and moved as the mollies are
  (one mesh, every fish an instance, posed by `shaders/render/fish.gdshader`: the body's wave, a tuna's beat all in its
  tail; the turns; the pectorals; the jaw opening to feed and with each breath), a school a draw call.
  `FishSchool.new(kind, variant)`: `"chinook"`, a Chinook salmon (at sea dark blue green, silver, white, black spots
  over its back and both tail lobes; `"spawning"`: dark olive and maroon, humped, the male's hooked jaws);
  `"rainbow"`, a rainbow trout (olive, spotted black over its back, fins and tail, the pink-red band, white-edged
  fins; `"steelhead"`: silver, the band faint); `"bluefin"`, an Atlantic bluefin tuna (2 m, metallic navy above,
  silver below, pale bars, the sickle second dorsal and anal fin, yellow finlets edged black, the keels, the crescent
  tail). Schooling (apart, along, together; `swim_to`, `scatter`); holding in a stream's current facing upstream
  (`current`); rising to the surface to sip, a ring spreading on the water (`rise`); the school through a bait ball,
  mouths open (`feed`); each steerable (`member(i)`). `tools/creatures/fish_demo.tscn` (a water for each; keys: Tab
  the next, 1 school, 2 rise / feed, 3 scatter, 4 the other variant, P one steered, + / - more or fewer).
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
  on a flower, catch and eat a caterpillar, land and walk about and settle, sting). Its colours are `_palette()`'s,
  so another species can wear the model: `trigonalid.gd` (`Trigonalid`, *Taeniogonalos gundlachii*, drawn at the
  paper wasp's size): black, cream marks on its face, collar, tegulae and scutellum, cream bands on the gaster's
  second and third segments only, reddish legs, a pale ring on each antenna, near clear wings. It builds no nest and
  hunts nothing: `visit_flowers(heads)` (from flower to flower, hovering, drinking nectar) and, a female's,
  `lay_on_leaf(edge)` (down on a leaf, along its margin, the gaster curled to the edge, rows of tiny dark eggs left
  there: they would hatch only inside a caterpillar that ate them, so here they don't). In the ecology sandbox, with what it uses there: a female and a male, fleabane, leaves to lay along (E nectar, 1 lay, G land, W / F fly about, K mate).
  `bumblebee.gd` (`Bumblebee`, *Bombus impatiens*, a common eastern bumble bee) makes the model over as a bee: stout
  and round, no wasp waist, its gaster short and blunt, all of it in dense short pile (`shaders/render/bee_fur.gdshader`:
  shells of hairs, darker at their roots), the thorax yellow above with a small bare black spot between the wings,
  black beneath, the gaster's first segment yellow and the rest black, its wings smoky, its legs black and stout, the
  hind tibiae broad (the pollen baskets). `forage(heads, nest)`: landing on flower after flower, its tongue out,
  crawling over each and now and then buzzing it (its body shaking, its wings still), the pollen loads on its hind legs
  growing; full, home to its nest (`Bumblebee.nest()`, a hole in the ground), down into it, a while, out unloaded and
  back to the flowers; `home(nest)`. A drone (male) drinks only, no loads. In the ecology sandbox, with what it uses there: a worker
  and a drone, their nest, coneflowers, Susans, fleabane and milkweed (E / H forage, B home, F about, G land, X sting,
  K mate).
  `tools/creatures/wasp_demo.tscn` puts one on a plain with a clump of the game's purple coneflowers, a caterpillar on a
  leaf, a plank and a ball (and for the scale the player's figure with its axe, and a pawpaw, a
  black-eyed Susan, a yampah and a cattail on the plank), each animation on a key (`godot --path . res://tools/creatures/wasp_demo.tscn`);
  and every other creature beside it, each at its own place (the hummingbird moth and the monarch round a patch of the
  game's flowers, milkweeds among coneflowers, Susans, fleabane, asters and yampah, and a stone, ants round a crumb, June bugs and lady beetles round their leaves), their animations on keys too, Tab following each in turn.
- `scripts/creatures/moose.gd` (`Moose`, *Alces alces*, on `Deer`'s make and ways): life size; a short deep body high
  over its shoulders' hump on very long legs, a short thick neck, the head long and heavy (sculpted: its muzzle broad
  and overhanging, the upper lip great), small high eyes, long ears, the bell hanging from its throat, a stub of a
  tail; dark brown near black, pale grey brown stockings (`carnivore.gdshader`'s species 13); a bull's palmate
  antlers (a broad palm a side fringed with points, a brow palm before it; in velvet or hard), a calf red brown.
  The deer's grazing, browsing, bedding, alarm, rub and scrape, sparring, calving and nursing; its own wading out
  into the water to feed under it. In the ecology sandbox: willows and a pond by it (B wade).
- `scripts/creatures/frog.gd` (`Frog`): a northern leopard frog (*Lithobates pipiens*), twice life size: its body
  and head one lofted skin (a pointed snout, a broad flat head, no neck, the sacral hump, its dorsolateral folds
  raised), painted in its own shader: green or brown, rows of dark spots ringed pale, the folds cream bronze, a pale
  upper-lip stripe, a dark line from nostril to eye, its tympanum a brown disc with a pale dot, a white belly; bulging
  golden eyes with level pupils, set into its head; its legs tapered and barred dark across, long hind legs folded
  in a Z, the hind feet webbed; a male's dark thumb pads and paired vocal sacs. Sitting, its throat pulsing; hopping (a ballistic
  leap, its legs thrown out straight); swimming in strokes (both legs kicked back together, a glide with them straight behind, then drawn up again, knees out, feet turned out; its forelegs laid back along its sides) and floating with its legs splayed behind, only its eyes out; its body deep, rising to the sacral hump over its hips, its belly round; its eyes gold, mottled, the pupil a level oval; sitting, its shins folded back beside its thighs, outside them; catching an insect (a grasshopper nymph in the demo)
  (`Frog.fly_of()`) with a flick of its tongue and gulping (its eyes pulled in); a male calling, his sacs swelling in
  bouts; fleeing in leaps for the water; amplexus (on her back, clasped behind her arms) and her egg mass laid on a
  stem under the water (`Eggs`: black eggs in clear jelly). The tadpoles hatch, swim and graze, grow their hind legs,
  then their forelegs, their tails shrinking away, and hop out onto the bank as froglets.
- `scripts/creatures/american_toad.gd` (`AmericanToad`): an American toad (*Anaxyrus americanus*), on the leopard
  frog's make (its species hooks: body sections, skin, legs, eyes, sacs, eggs): squat and rotund, its back a high
  dome, its snout short and blunt, its legs short (short hops); its skin dry and warty all over (its warts baked: `tools/creatures/bake_toad_warts.py`, a tile of them, laid on triplanar),
  brown, reddish or olive, a faint pale line down its back, big dark spots round its warts, its belly speckled; a
  kidney-shaped parotoid gland behind each eye and the bony crests between and behind them; no dorsolateral folds,
  no lip stripe; its iris copper gold; a male's long trill, one round vocal sac swelling under his chin; its eggs in
  two long strings of jelly over the bottom; its tadpoles black.
- `scripts/creatures/turtle.gd` (`Turtle`): an eastern box turtle (*Terrapene carolina carolina*), twice life size,
  on a species' make (a spec: `SnappingTurtle` has its own). Its carapace its own mesh (a high dome, a low keel, the
  rim flared behind) painted from its scutes' centres: brown, irregular yellow and orange streaks and blotches out
  from each scute's growth centre, fine growth rings, dark seams; its plastron hinged in two lobes that close the
  shell tight (head, legs and tail in) when it withdraws; a lofted head with a hooked beak and a jaw; dark skin
  spotted orange, scaled (a bumped shader); a male's red eyes (a female's brown), his hind claws thick and curved.
  Wandering slowly over the forest floor, stopping to look round; sunning; soaking in a puddle; eating a mushroom
  (`Turtle.food_of()`), `Turtle.weed_of()`, a pill bug or an insect; the male nudging and biting at her shell's rim, then up on her
  from behind leaning back near upright; the female's nest dug with her hind feet, her eggs laid and covered
  (`Nest`), the hatchlings out of it.
- `scripts/creatures/snapping_turtle.gd` (`SnappingTurtle`): a common snapping turtle (*Chelydra serpentina*), on the
  box turtle's make: a low broad rough shell, three keels, each scute rising to a pyramid's point behind its middle,
  the rear rim sharply toothed, dark brown, fine dark lines radiating over each scute, a little algae; a small
  cross-shaped plastron (it can't hide); a huge head, hooked beak, chin barbels; grey skin knobbed all over with
  rounded tubercles, and spiked: fleshy pointed tubercles along its jaw and under its chin, on its cheeks, round its
  neck and down each side of its tail; thick legs, big claws, webbed feet; a tail as long as its shell with a saw crest. Walking the pond's bottom, surfacing
  to breathe; lying in ambush on the bottom, mouth a little open; striking (its neck shot out, jaws snapped shut);
  on land its threat (up on its legs, gaping, lunging and snapping); mating in the water (he's on her back, claws
  over her shell's rim, biting at her head); nesting on the bank.
- `scripts/creatures/sea_turtle.gd` (`SeaTurtle`): a green sea turtle (*Chelonia mydas*), life size (a metre of shell),
  on the box turtle's make: its shell a low, broad, smooth teardrop, its scutes edge to edge, thin pale seams between
  them, each a soft sunburst of brown, olive and amber streaks out from its growth centre; a pale plastron; a blunt
  head too big to draw in, big dark eyes; head and flippers a mosaic of dark scales, darkest in their middles, each
  outlined in yellow cream, the neck yellow olive and finely scaled; its foreflippers long swept-back wings, tapering
  to a point, thick along their leading edge (each its own mesh), a claw there (a male's long and curved); its hind
  flippers broad round paddles; their undersides pale; a male's tail long. Flying through
  the water on its foreflippers' slow strokes (the hind ones steering), at one depth then another, up to breathe;
  resting on the bottom; grazing seagrass; away fast when alarmed (it can't hide); the male on the female's back at
  the surface, his claws over her shell's front; the female up the beach heaving on both foreflippers together, her
  nest dug and laid, back to the sea; the hatchlings down the beach to the water.
- `scripts/creatures/personal_space.gd`: personal space for every creature with a body of its own (the hexapods,
  the mammals, the turtles, the frogs, the snakes; not those a shader draws and moves: the ant colonies, beetles,
  fish schools): not collision, but each a capsule on the ground from its rump to its head as wide as its body (from
  its spec, or its drawn size), two that overlap, whatever their kinds, eased apart, each its half; off where they're
  meant to touch (mating, nursing, playing, hunting and eating, sparring, nesting, basking; the young; one in the air;
  one above the other: in a web, on a stem).
- `scripts/creatures/meal.gd` (`Meal`): every meal eaten piece by piece, nothing shrinking away: the food's meshes cut
  into pieces (a skinned body baked first in the pose it died in), each next piece the one nearest the eater's mouth,
  torn off, drawn to the mouth and taken in. A vertebrate's (a mammal's above all) bleeds: raw, wet flesh at every
  torn edge, the piece torn away red inside, blood run out under a carcass lying on the ground (not a fish's: no blood).
  A body bent by its shader (a snake's, a larva's) is cut where it's seen, its pieces bent by the same shader. A snake's swallowed
  whole instead, each part gone as its jaws come over it. Used by the carnivores, the mantis (the male after mating
  too), the anole, the scorpion, the spiders, the dragonfly, the snakes, and the squirrel's nut, the mouse's seed,
  the hare's plants.
- `scripts/creatures/dragonfly.gd` (`Dragonfly`): a common green darner (*Anax junius*), drawn at twice life size,
  its own flying motor (quick to turn and stop, hovering, banking). Its head nearly all eye, its face yellow green
  with the dark bullseye on its brow; a grass green thorax; ten abdominal segments in a chain (curling), the first
  two green, then a male's sky blue, a female's brownish violet, a black stripe down the back, a male's claspers;
  four long clear wings netted with veins (a shader), each with its pterostigma, beating fore and hind out of step,
  held out flat at rest; six legs a basket under it in flight, gripping a perch. Patrolling over the water, darting
  and hovering; perching on a reed's tip, its head turning; hunting small flying insects (in the demo, trigonalid wasps)
  swept up in its legs and chewed; the female laying her eggs into stems under the water (pale specks, `Eggs`, that
  hatch into nymphs). Mating: he seizes her by the head with his claspers (tandem), to a perch, the wheel (her abdomen
  curled forward under his to its base), then off in tandem to the water where she lays while he holds her. The
  nymph (a naiad: mottled olive, broad headed, wing pads, its hinged mask shot out at prey) walks the pond's floor and
  grows; then climbs a reed out of the water, its back splits, and the adult comes out pale, its wings crumpled,
  swelling and hardening, its colour coming, the empty skin left on the reed. In the ecology sandbox, with what it uses there: a
  little pond with reeds and trigonalid wasps flying over it, a male, a female and two nymphs.
- `scripts/creatures/hexapod.gd`: a walking insect built from parts (feet planted in a tripod gait, legs reaching
  hip to foot; leaps, flights, falls on a thread), under `grasshopper.gd` (`Grasshopper`: a differential
  grasshopper, its herringboned hind legs; walking, hopping, flying, eating; laying an egg pod in the soil, which
  hatches nymphs up out of the ground; and `blue_winged_grasshopper.gd`, `BlueWingedGrasshopper`, Saussure's
  blue-winged grasshopper on its model: mottled brown, its tegmina tan and veined with dark crossbands, its
  hindwings sky blue in a broad black band, clear at the edge, shown as it flies; its hind tibiae blue; its own
  place in the ecology sandbox) and `mantis.gd` (`Mantis`: a Carolina mantis, its raised prothorax, turning
  head and raptorial forelegs; stalking with its rocking sway, watching, striking a grasshopper nymph and eating it, grooming,
  flying; building a foam egg case on a stem, whose nymphs come out along its seam, let down on threads). Their
  nymphs small, wingless (the mantis's abdomen curled up), growing. Not yet in the game:
  the ecology sandbox (`tools/creatures/ecology_demo.tscn`).
- `scripts/creatures/snake.gd` (`Snake`): snakes, life size, not yet in the game: the eastern diamondback
  rattlesnake (broad triangular head, heat pits, slit pupils, the stripe through the eye, dark diamonds edged in
  cream, keeled scales, a banded tail and its rattle; a newborn only a button) and the eastern milk snake (narrow head,
  black-edged red-brown saddles on grey tan, a checkered belly, the pale V on its nape, glossy; a hatchling bright
  red). One skin bent along a spine (`shaders/render/snake.gdshader`), the body following its head's sinuous path
  (lateral undulation), the tongue flicking; coiling; eating a mouse (the rattler coils, rattles, strikes and lets go,
  waits, swallows; the milk snake strikes, constricts in its coils, swallows: the jaws gaping, the meal a bulge going
  down). The milk snake lays leathery eggs that hatch (a slit, the young's head out, then the young); the rattler gives
  birth, each young in a clear membrane it wriggles out of. In the ecology sandbox.
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
  (`carnivore.gdshader`'s species 9); mammal legs (the elbows back, the knees forward, the long hind feet flat heel to
  toe). Scurrying, stopping to sniff (nose, whiskers and ears going), sitting up to look; eating a seed sat up on its
  haunches, turning it in its forepaws, nibbling it away; washing its face. The female gives birth in her grass nest
  (`Mouse.nest()`), licking each pup clean, then nursing; the pups born pink, hairless, eyes shut, ears folded,
  wriggling where they lie; growing, furred grey, eyes open, up and about, brown as they grow up.
- `scripts/creatures/carnivore.gd`, the four-legged hunters' make (on `hexapod.gd`'s motor), life size, under
  `canid.gd` (the dogs': below) and `red_fox.gd` (`RedFox`: rufous, grizzled, white beneath, black stockings, a narrow white-sided muzzle, amber slit-pupilled
  eyes, big black-backed ears, a full brush tipped white) and `bobcat.gd` (`Bobcat`: tawny to grey, spotted and barred,
  a barred ruff, white about the eyes, black-backed tufted ears with a white spot, a short barred tail black-tipped
  above); coats by `shaders/render/carnivore.gdshader`. Digitigrade legs (upper, lower, the long metapodial, the paw on
  its toes; a lifted paw curled); gaits by speed, each foot planted where it's set down: a walk (each foot in turn), a
  trot (the diagonals), a gallop (the back flexing, rising and pitching); the head on its neck, looking, sniffing; the
  ears turning, pricked, laid back; the tail carried low walking, out behind running, low stalking, curled round its
  feet sitting and round its nose asleep. Wandering (sniffing, looking, sitting, marking: the fox squatting, the bobcat
  scraping); hunting (stalking low and slow, freezing; the fox listening, head cocked, then its high arcing pounce
  diving nose first; the bobcat treading, tail tip twitching, then the rush and the spring), the prey (a deer mouse,
  a snowshoe hare, a grey squirrel: anything with die()) killed, carried off in its jaws a few of its lengths, then
  eaten: every kill laid down on its side on the ground and left lying there, still, the hunter's head down to it,
  stepping round it till its mouth's on the next bite, tearing it off with a tug of its head, the carcass never
  lifted or moved (raw and bloody where it's torn, blood run out under it);
  grooming (a forepaw licked, the face washed, a flank licked); sitting; sleeping curled, then a stretch. The female gives birth in
  her den (`RedFox.den()`: a mound of dug earth; `Bobcat.den()`: a shelter of rocks), lying on her side, licking each;
  nursing them at her belly; the young born blind and helpless (a fox kit dark grey brown, a kitten spotted, greyer),
  wriggling to her, growing, eyes open, following her, playing (stalking, pouncing on one another, tumbling). Mating:
  the fox's tie (he mounts her, then turns round off her, and they stand tail to tail a long while); the bobcat's
  nape bite, brief, then she rolls on her back and he springs away.
- `scripts/creatures/canid.gd`, the dogs' ways on the hunters' make (`RedFox`, `Coyote`, `GreyWolf`): small prey
  (a mouse) by sound, the high mousing pounce; bigger (a hare) run down at a gallop, a lunge; marking with a squat;
  courting and greeting with a wagging tail; the tie; howling (`howl(secs)`: the coyote's and the wolf's, sitting,
  the head thrown back, the muzzle up, the mouth rounded; a coyote's yips between); dens of dug earth
  (`Canid.den(scale)`). `coyote.gd` (`Coyote`, *Canis latrans*: lean, long legged, a long narrow muzzle, big upright
  ears; grizzled grey brown above, black-tipped guard hairs along the back, tawny sides, legs and ears, a pale cream
  throat and belly, yellow eyes; a bushy black-tipped tail carried low) and `grey_wolf.gd` (`GreyWolf`, *Canis
  lupus*: big, deep chested, long legged, big footed, a broad head and deep muzzle, shorter rounder ears; grizzled
  grey, a darker saddle, pale buff legs and flanks, a pale underside and face mask; its tail carried low and straight,
  dark tipped); their pups born dark (a wolf's near black), blind, in the den, growing, playing.
- `scripts/creatures/ursid.gd`, the bears' ways on the hunters' make, plantigrade (on the whole sole, the heel
  down, lifting first; the claws out before the toes), heavy, the head low, an ambling walk and a lumbering gallop;
  their coats by colour phase. Foraging (nose down, sniffing; digging, the forepaws raking the earth back by turns,
  the head down in the hole, eating what's found); browsing a berry bush (`Ursid.berry_bush()`: stripping the berries
  with the lips, up on the hind legs for the higher ones); standing up on the hind legs, forepaws hanging, sniffing
  the air; rubbing its back up and down against a tree (its mark); a rush at its prey, a swipe, pinned; birth in its
  den (`Ursid.den()`: a hollow under a root mound), the cubs born tiny, near naked, blind (their mother's phase),
  growing, following her, playing (up on their hind legs together, boxing, tumbling over); mating (he follows her,
  then mounts her from behind, his forelegs round her waist, mouthing her neck now and then). `black_bear.gd`
  (`BlackBear`, *Ursus americanus*: no hump, a straight face, a long tan muzzle, tall rounded ears, short curved dark
  claws; black, cinnamon, brown or blond, now and then a white chest blaze) and `brown_bear.gd` (`BrownBear`, *Ursus
  arctos*: massive, the shoulder hump, a dished face, a broad muzzle, small round ears, long pale claws; brown,
  grizzled or blond, darker legs).
- `scripts/creatures/bison.gd` (`Bison`, *Bison bison*, on the hunters' make, a grazer's ways): life size (a bull
  3 m long, 1.8 m at the hump, a cow a little smaller); the great hump, the huge head carried low, short black horns
  curving up and in, the beard; long dark shaggy wool on the head, hump, shoulders and forelegs, the hindquarters
  browner, short (`carnivore.gdshader`'s species 6); small wide-set eyes, barred pupils; slender legs on cloven
  black hooves; a thin tufted tail. Grazing (head down, cropping, chewing, stepping on); lying chewing its cud (its
  rest); wallowing (horning the ground, down and rolling on its side and back, legs kicking, a cloud of dust, up and
  a shake); a bull's bellow and sparring (head to head, horns locked, pushing back and forth); stampeding at a
  gallop, tail up; a cow's calf born in the open (red orange, no hump or horns), licked, struggling up, suckling at
  her udder, following her, at play (a run and a buck); mating (the bull tending her, his chin on her rump, then on
  her, briefly). In the ecology sandbox, with what it uses there: two bulls, two cows, a calf.
- `scripts/creatures/deer.gd` (`Deer`, *Odocoileus virginianus*, on the hunters' make, a browser's ways): a
  white-tailed deer, life size (a doe 90 cm at the shoulder, a buck a little bigger); slender and deep chested on
  long thin legs, small cloven hooves with dewclaws; the long neck carried high, a narrow tapering head, big dark
  eyes, big mobile ears; the long broad tail, white beneath. Its coat by season (`Deer.new(young, "summer" |
  "winter")`, `carnivore.gdshader`'s species 7): summer red brown, winter grey brown; white belly, chin, muzzle band,
  eye rings and throat patch. A buck's antlers (`antlers`: points a side): the beams sweeping out, back and forward,
  the tines rising off them, the brow tines; in velvet in summer, hard and pale in winter. A fawn red and white
  spotted. Grazing and browsing (heads up now and then, chewing, looking round, the tail flicking); bedding down,
  chewing its cud, dozing; alert (head high, stamping a forefoot, the tail half up); fleeing in long bounds, the
  white flag up and waving; grooming (licking, a hind hoof scratching its neck); a buck's rub on a sapling and his
  scrape (pawing, then the licking branch), his snort wheeze and lip curl, sparring (antlers locked, twisting,
  pushing); a doe's twin fawns, licked, up on their feet, then hidden flat in the grass apart; nursing (the fawns
  come to her, butting, tails wagging), the fawns at play (running in circles, bucking); mating (the buck tending
  her, his head low, then mounting briefly). In the ecology sandbox, with what it uses there: a summer doe with twins and a buck
  in velvet; two winter bucks and a winter doe; a shrub to browse (B), a sapling to rub (M).
- `scripts/creatures/beaver.gd` (`Beaver`, *Castor canadensis*, on the hunters' make, plantigrade, waddling): a North
  American beaver, life size; one skin, heavy, humped, broadest at its hips, a broad blunt head, small eyes and
  ears, great orange incisors, clawed hands, big webbed hind feet, its tail a broad flat scaled paddle
  (`carnivore.gdshader`'s species 11: rich dark glossy brown, its feet and tail bare and black). In its water (`wet`,
  `water_y`) it floats low, head and back showing, hind feet paddling by turns, forefeet tucked, tail trailing;
  its alarm a tail slap on the water (a splash) and a dive; felling an aspen (`Beaver.sapling()`) sat up gnawing
  round it, chips flying, the tree falling, a length gnawed off and carried in its jaws out to its lodge
  (`Beaver.lodge_of()`) and laid on it; eating bark off a stick held across its forepaws, turned like a cob, left
  peeled; mud plastered on the lodge; grooming sat up; kits born furred, following her on land and swimming; mating
  in the water. In the ecology sandbox, with what it uses there: a female and a male, a bank with aspens and sticks, a pond and
  their lodge (E eat bark, H fell an aspen, B swim, X slap and dive, M mud, 1 birth).
- `scripts/creatures/opossum.gd` (`Opossum`, *Didelphis virginiana*, on the hunters' make, plantigrade): a Virginia
  opossum, life size; one skin, low and round backed, its rump high, its long head conical, white faced, the eyes
  small and black, a dark smudge round each, the pink nose overhanging the jaw; its fifty teeth (shown only with its
  mouth open); its ears black, naked, pale rimmed; short black legs, bare pink five-fingered feet, the hind foot's
  big toe an opposable thumb; its tail long, bare, scaled, black from its furred root for a third of its length,
  then white (`carnivore.gdshader`'s species 14: grizzled grey, white underfur and guard hairs, black ones among
  them). Playing possum (over on its side, stiff, mouth open, tongue out, drooling; an ear twitches, its head comes
  up, it gets up and goes); gaping and hissing, every tooth bared; climbing a leaning branch (`Opossum.snag()`),
  its feet round it, its tail coiled round it, a while up there, turned round and down head first; leaves gathered
  in its mouth, tucked back under it with its forefeet into the loop of its tail and carried to its den
  (`Opossum.den()`, a hollow log); eating anything (fallen persimmons, `Opossum.windfall()`, eaten where they lie;
  carrion; mice, grasshoppers; snakes, toads, frogs, grubs); her young born the size of bees, pink and naked, up
  her fur into her pouch, out of sight; out after a while, clinging to her back in rows, carried as she goes;
  down to play (a stalk, a pounce, a tumble) and back on, she waiting for them; nursed at her belly, she on her
  side; mating: he clicks, mounts her gripping her neck fur, and they topple over together onto their sides. In the ecology sandbox, with what it uses there: a female and a male, her den, the branch, persimmons, leaf litter (1 birth, V
  play, N nurse, X play dead, D gape, F climb, B gather, E eat, H hunt, U a snake or a toad, K mate).
- `scripts/creatures/fox_squirrel.gd` (`FoxSquirrel`, *Sciurus niger*, on the hare's motor): an eastern fox squirrel,
  life size; one skin, a long supple body, round head, short blunt muzzle, big dark eyes ringed pale, short rounded
  ears, orange incisors, sharp claws; its long bushy tail a chain of bones carried up over its back in an S,
  streaming out behind as it bounds, flicked in waves (`carnivore.gdshader`'s species 10: grizzled grey brown
  washed orange above, rusty orange beneath, the tail's hairs black banded and orange fringed). Bounding, sitting up
  to look; eating a nut (`FoxSquirrel.nut()`) picked up in its teeth, then sat up with it in its forepaws, turned
  and gnawed; caching one (dug in with its forepaws, pushed down with its nose, raked over and patted, a little
  mound left); climbing its tree (`FoxSquirrel.tree()`) in bounds, claws gripping, a look round at the top, down
  head first; fleeing up it; its tail-flicking, chattering alarm; birth up in her leaf drey, the kits pink, naked,
  blind, furred as they grow; the hare's mating chase. In the ecology sandbox, with what it uses there: a female and a male, an
  oak with her drey, nuts under it (E eat, B cache, F climb, X flee up, D flick, 1 birth in the drey).
- `scripts/creatures/grey_squirrel.gd` (`GreySquirrel`, *Sciurus carolinensis*, on `FoxSquirrel`): an eastern grey
  squirrel, its model and ways the fox squirrel's, a little larger here (size 0.33); its coat `carnivore.gdshader`'s
  species 12: grizzled silver grey washed brown along the back, over the head and down the legs, white beneath and
  round the eyes, the tail grey, its hairs black banded, a white fringe. Its own entry in the ecology sandbox
  (after the beavers'), the same keys.
- `scripts/creatures/hare.gd` (`Hare`, on `hexapod.gd`'s motor, its gait its own): a snowshoe hare (*Lepus
  americanus*), life size, in its summer coat (`carnivore.gdshader`'s species 8: brown, grizzled, darker along the back,
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
  bark scorpion (*Centruroides sculpturatus*): straw yellow, slender, its cuticle glossy and a little translucent; the
  carapace a low trapezoid, notched before, furrowed, its eyes; the mesosoma's seven tergites overlapping, keeled, the
  pale membrane between; the five-segmented tail, its segments narrow jointed and keeled at their edges (coiled to its
  side at rest, arched over its back walking), the telson's bulb, its tooth, its long curved sting; long slender
  keeled pedipalps, the chelae's long curved fingers; chelicerae, the pectines' combs, claws at its feet. Ambushing,
  creeping, seizing prey in its chelae, drawing it in and stinging it, tearing at it (a grasshopper nymph in the demo); its
  strike (`strike(at)`, `sting(at)`: up on its legs, chelae raised, the tail cocked up and back, whipped forward over
  its back, the tail's joints bent to bring the sting to its mark, driven in, held, the bulb pumping, a drop of venom
  at its tip, drawn out); live birth (up on her legs, her forelegs a basket, the white
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
  --resolution 1600x900 --script res://tools/plants/preview.gd -- <out_dir> [joshua | sanpedro | pear]`),; none of them are in the ecology sandbox.
- Mating (every species but the ants: their workers don't; `hexapod.gd`'s `mate(partner)` for the walkers, each
  species saying how): a male of each (`male`, set before it's added; told apart only where it must be: the male
  spiders smaller with the swollen bulbs of their palps, the garden spider's male a quarter her size, tan and slender;
  the male mantis smaller and slimmer, his wings over all his abdomen; the male grasshopper smaller). The
  grasshopper's rides her back, his abdomen curled down round to hers; the mantis's creeps up behind her, freezes
  swaying, leaps on; done, he slips off beside her, and she turns on him, strikes, wrenches his head off and eats it,
  then eats the rest of him. The spiders' males first charge their palps: a little sperm web spun, a drop laid on it,
  drawn up into each palp in turn; then courting (the wolf spider waving and drumming, the fishing spider tapping, the
  grass spider and the garden spider plucking); the wolf and fishing spiders up on her front facing back, leaning down
  each side in turn to put a palp in to her, its bulb swelling; the grass spider's female gone still, over on her
  side; the garden spider's male up her web to her at the hub, under her, and dead on her after his second, wrapped in
  her silk. The pill bug's male on her back leaning down one side and then the other; the beetles' riding their
  females' backs (the colony's own: `Beetles.mate(i, j)`); the butterflies and moths, the male chasing her down,
  joined end to end; the wasp's pouncing on her back, stroking her antennae; the snakes', the male crawling up along
  her back, chin rubbing, their tails twisted together; the mice's, the male following her, mounting from behind,
  thrusting in bouts, then washing. `act("mate", {partner})` for any of them (pilot.gd).
- `tools/creatures/ecology_demo.tscn`: the ecology sandbox, every creature not yet in the game and the plants and
  water they live by, staged by hand in one scene to try any mix of them together. A list down the left (plants:
  the game's flowers, a berry bush, an aspen, an oak, fallen persimmons, clover, a willow shoot, a mushroom, a leaf;
  features: a puddle, ponds, a sea with its beach, sand, gravel, a dead branch; the insects, spiders and kin, fish,
  amphibians and reptiles, mammals): pick one, then left click the ground to put one there (again and again; right
  click or Esc: done), as an adult, young or a pupa, female or male (the boxes under the list). Left click a creature
  to select it (Shift: add to the selection; the ground: none); Delete takes the selection away with whatever was
  put down with it. Right drag turns round, middle drag (or the arrow keys) moves along the ground, the wheel zooms,
  C centres on the selection; the grass can be turned off. The keys act on the selection, or on everything if
  nothing's selected: 1 lay eggs / give birth, 2 hatch / come out / moult, 3 pupate, E eat, H hunt, U an unusual
  meal, K mate (each male with the nearest female of his kind), G groom, Z sleep / rest, F fly / hop / climb, X alarm
  (flee, roll up, coil, sting, play dead, scatter), D display / call, V the young play, N nurse, B forage (home,
  gather, swim, cache, wade), S spin a web, M mark, A sit, W back to their own ways, Space slow motion. What a creature
  needs and isn't there is put down for it, close by, the first time it needs it (a den, a nest, a comb, a web's
  moorings, a pond, a sapling, its food), and what's there already is used first: a hunter goes for prey that's in
  the scene (a fox put down by mice hunts those mice), a butterfly or a bee for the flowers there, a frog to the pond
  there; a young deer, moose or bison put down by a grown female of its kind follows her. The water creatures dig
  their pond beside them if there's none (sunk in the plain, the game's own water over it, reeds in it), and the
  plain's grass is kept off it and round the small creatures. U: the mammals' rarer meals, plausible if seldom
  seen, each another of the game's own animals (one in the scene first, or set out for it): the fox a newborn
  fawn, a beaver kit, a bobcat kitten, a June grub, a grasshopper; the bobcat a fawn, a grown deer, a fox; the coyote
  a fawn, a fox, a beaver; the wolf a deer, a moose or bison calf, a beaver, a coyote; the bears a fawn, a calf, a
  beaver, grubs, the grizzly a black bear cub or a wolf pup; the deer a mouse pup; the deer mouse a grasshopper
  nymph, a caterpillar, a grub, a pill bug, a mantis nymph; the squirrels a caterpillar, a grub, a mouse pup; the
  snowshoe hare a dead mouse; the fox, the bobcat, the coyote, the opossum a snake; the snakes a leopard frog, a
  toad, an anole, the milk snake a young rattler. A kill more than half the hunter's length isn't carried off or
  lifted: it's eaten where it fell, longer. The fox's fruit, ants and wasps (a huckleberry bush, a harvester ants'
  nest, a fallen paper wasp comb), the opossum's fallen persimmons: eaten where they are (`eat_at(point, seconds)`,
  any of the four-legged make's), its snout brought to the point and kept there, licking, snapping, nosing about;
  nothing taken away or moved (fruit's anyone's to pick, ants and such are drawn by the hundred).
- `scripts/creatures/carcass.gd` (`Carcass`): the carcass of a mammal bigger than a beaver dead of something else
  (the grey wolf, both bears, the white-tailed deer, the moose, the bison), the animal's own model where it lies,
  in three stages (`Carcass.make(parent, script, at, yaw, stage)`, `Carcass.set_stage(c, stage)` to take it further
  on). 1 fresh: down on its side, its legs out stiff (rigor) and all four feet on the ground, the upper pair fallen
  across toward the lower, its head along the ground, its mouth a little open, its eyes glazed. 2 rotting
  (`carnivore.gdshader`'s `decay` 1): its skin sunk in deep between its ribs, over its flanks and belly, round its
  eyes, its legs thin; its fur slipped off in patches, the skin under it discoloured green grey and purplish; its
  flesh open and rotting at its belly and flank, its face (its eyes gone), its rump, its legs' tops, along its back,
  wet, maggots in it; rotted through here and there in small ragged holes, a broken bit of bloody rib or the meat
  inside showing in each; the grass under it dark and dead, tufts of its fur about. 3 bones (`decay` 2): its
  skeleton, built on its own frame where it lay (skull, eye sockets empty, teeth, lower jaw, the antlers or horns
  still on it; the spine, its spines tallest over the withers; ribs and breastbone; shoulder blades and pelvis; each
  leg's bones, the hooves or claws still on its feet; the tail's vertebrae), still much of it covered: its hide dried
  and shrunk onto the bones, rotting flesh dark red brown under and between it, wet in the hollows, maggots in it,
  here and there its fur still on it, torn open in ragged holes where the bones show; meat rotting on along its
  back, over its haunches and shoulders, on its upper legs and its neck, between its ribs; strips of it hanging off
  its ribs, sinews along its legs; a rib and a vertebra or two fallen from it; the ground under it bare and pale.
  Carrion: a scavenger's `eat(carcass)` (stages 1 and 2) tears it up as any kill. In the ecology sandbox: the
  Carcasses group, fresh, rotting or bones (the box under the list); 2 takes one a stage further on; E sends the
  wolves, coyotes, foxes, bobcats, bears and opossums to one near them.
- The mammals' look (`scripts/creatures/mammal_skin.gd`, `MammalSkin`): each one skin, not parts stacked. Its rings
  are swept into tubes (the body rounding up through the neck into the head to its nose, the jaw, each leg from
  inside its shoulder or haunch to its toes, the tail), every vertex weighted to the bones the animal's own motor
  already moves (torso, neck, head, jaw, each tail joint, each leg's segments), blended where they meet, framed
  without twist down each limb, and skinned on the GPU; eyes, nose, ears, horns, antlers, hooves, claws, whiskers
  stay rigid on their joints. Their coats are all `shaders/render/carnivore.gdshader`'s (species 0-7 the hunters,
  bison and deer; 8 the hare; 9 the deer mouse): painted, not shelled (no fur shells, no instance uniforms):
  broad countershaded colour, each species' marks in soft gradients; fine strands along the hair's lie (paler at
  their tips, darker at their roots), gathered in locks, the surface bump-mapped by them so the light breaks up on
  the coat (fading out far off, where they'd shimmer), matte, a velvet rim; the bison's front in curled wool. The
  faces: almond eyes set in, dark-lidded; the lip line along the jaw to the mouth's corner; whisker spots in rows;
  the muzzle darker toward the nose; the ears furred pale within, their backs the species' own. The heads of the
  fox, bobcat, coyote, wolf, both bears, bison, deer, beaver and opossum are sculpted (`scripts/creatures/sculpt_head.gd`,
  `SculptHead`: each species' `sculpt` in its SPEC, fitted to photographs): cross-sections changing along the head,
  its profile's own line, the eye sockets, lids, brows, cheeks, stop, whisker pads and lips pushed in or out; the
  lower jaw tucked under the lips; the nose leather and the face's marks painted on (`carnivore.gdshader`'s `sculpt`).
  A grown male's external genitals as seen on him standing (`Carnivore._build_male`, each species' `male_parts`): the
  prepuce along his belly, furred as the belly is (a bison bull's and a buck's tufted at the tip), and the scrotum
  between and behind his thighs (a bobcat's high under his tail, a bull's hanging).
- Steering, for a future state machine (`scripts/creatures/pilot.gd`): every creature (`Wasp`, the
  lepidopterans, `Grasshopper`, `Mantis`, `Snake`, `Larva`; one of a colony: `AntColony.member(i)`) has the same
  calls: `go(direction, speed, seconds)`, `go_to(point, speed)`, `face(direction)`, `stop()`, `act(name, args)`
  (`behaviours()` lists its own: eat, lay, hop, fly, strike, watch, groom, coil, bask, feed, land, sting, ...),
  `is_busy()`, the signal `action_finished(name, ok)`, and `height` (a Callable, the ground's y at x, z: for the
  walkers and crawlers; the ants' already had it). Driven, a creature sets aside its own wandering, and holds still
  once an order's done. (Its orders can be run one after another, each given once the last's done: `action_finished`.)
- Life cycles (not yet in the game): eggs (`scripts/creatures/brood.gd`, `Brood`; `egg.gd`: rice grains, each kind
  its size and colour) laid by the butterflies one to a leaf (the clearwing hovering), by the wasp one to each cell of
  its comb, each egg filling its cell (`Wasp.comb`, `lay_eggs`; the demo's 1 lays in the next empty cell, one a lay), by the beetles in a cluster (`AntColony.lay`, a beetle's: tipped tail down; the
  ants don't lay: their queens' eggs lie in piles); every egg hatches (`hatch`: rocking, the larva out, small,
  growing up; a caterpillar eats its shell first, bit by bit, then feeds where it is, any other's collapses and fades). Their larvae (`larva.gd`, `Larva`: one smooth skin bent along
  a spine the CPU moves, by `shaders/render/larva.gdshader`, its creases shallow; a crawler bending at most a little
  a joint; the grubs lying on their sides, legs in): the monarch's banded caterpillar (white with a fine black line,
  black, yellow, black round each segment, duskier beneath; its pale head ringed black, a black triangle down its
  face) with its filaments (the front pair longer, tapering), the clearwing's hornworm (yellowish green, granulated
  pale, a pale line along each side of its back, reddish spiracles ringed pale, its horn yellow below, blue-black
  above), each caterpillar and the lady beetle larva with its eyes (six small stemmata each side, low on the head), the lady beetle's crawling "alligator", the June bug's C-curled white grub, the wasp's and
  the ants' grubs; caterpillars rippling as they crawl, grubs curling and uncurling. The lepidopterans' pupae
  (`pupa.gd`, `Pupa`, lofted shells painted by `shaders/render/pupa.gdshader`): the monarch's jade lantern of a
  chrysalis on its black stalk, its black and gold crown, gold spots; the clearwing's glossy mahogany pupa, ringed,
  spiked, in a ragged cocoon in the litter. The life cycle closed (`Larva.pupate`): the monarch caterpillar along
  its way (down its milkweed, up a stem, along under a twig), spinning its pad, hanging from it in a J, its skin worked
  up and crumpling, the chrysalis left hanging; the hornworm writhing as it spins its cocoon in the litter; the lady
  beetle larva gluing its tail down, hunched, its pupa there (orange, spotted black, its larval skin bunched at its
  tail); the grubs curling tighter, still, then their pupae: the June bug's on its back in its cell, the wasp's under
  its cell's white silk cap, the carpenter ant's in a tan cocoon, the harvester's bare and white. Out of them
  (`Pupa.eclose`): the lady beetles and June bugs into their colony (`AntColony.add`), the ants' new workers into a
  colony of their own, the wasp up out of its cell, the lepidopterans as before. The nymphs' moult (`molt.gd`,
  `Molt.begin`: one moult to grown, not the several a real one takes): the nymph still, gripping, swelling; its skin
  splitting, the adult backing up and out of it nose first, swelling to full size as it walks off; the cast skin left
  pale and see-through (the grasshoppers', the mantis'; the darner's own climbing out of the water as before). Demo:
  3 pupates the larvae (the selected, or all), 2 hatches the pupae and moults the nymphs. They ripen (the monarch's going clear, its wings showing through),
  wriggle, split, and are left empty skins; the adult pushes out (the monarch head first, down; the clearwing out of
  its cocoon), turns or climbs to hang, its abdomen swollen, its crumpled wings hanging down and pumped out to full
  size, dried, opened and closed (`Lepidoptera.emerge`); then flies. In the ecology sandbox (`tools/creatures/ecology_demo.tscn`) the clearwing goes
  to the flowers there (a coneflower put down for it, if there are none): it hovers at them, its tongue in one floret after another (E; its
  searching flights, W and F, stop at them too).
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
  The ecology sandbox's plain is grown over with the game's own short grass (`DemoFlowers.meadow`: GroundCover's
  finest grass layer's clumps, 7 to 16 cm, coloured as `ground_cover.gdshader` colours them, swaying in the same
  wind and as much), kept off the ponds and round the small creatures.

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
copses, thinning out up the mountains. Past 250 m every standing tree is a card, its photograph from eight ways
round, out to the tree render distance (3 km unless set otherwise; `FarTrees`: the trees where `Population`
puts them, a 512 m cell of them, whatever their species, drawn at once), and the
haze is thick (6.5 km), so distant land softens and blues. The pale
grounds (prairie, coast, beaches) dim at night, as the leaves do. Marram,
half the prairie grass's height and as pale as the sand, grows in patches on
the coast and beaches: none at the water's edge, thicker and taller up the beach. `/pos`
names the biome you're in.
