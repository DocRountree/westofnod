# Population content

What grows and lives on the land. `scripts/population/population.gd`
(`Population`, a child of Main) streams it in 64 m chunks round the player,
generated on worker threads from a per-chunk seed, so the same things are
always in the same places and nothing needs saving.

- `props/*.tres`: `PropKind` (trees, rocks, grass). Mesh, material, density
  per biome (per hectare; `"*"` = any other biome), scale range, ground
  alignment, slope and height limits, view distance (and `far_distance`, for a far card past it), and `radius` (solid:
  the player and actors walk round it; 0 = walk through, e.g. grass).
  Each kind in a chunk is one MultiMesh (one per level of detail: `lods`
  are simpler meshes drawn from `lod_distances` on).
- `actors/*.tres`: `ActorKind` (NPCs, animals). A scene whose root extends
  `Actor`, density per biome (groups per km²), group size and spread, and
  `persistent` (named NPCs: not freed when the player leaves). Actors spawn
  within `Population.actor_radius` (160 m) and are freed beyond it.
  Override `Actor.think()` for behaviour; movement over the terrain (and
  round props) is done for you.

Biomes: forest, mesa, prairie, swamp, tundra, taiga, plateau, volcano,
mountains, island, coast (`""` = land with no biome).

Runtime hooks: `Population.prop_at(pos, r)` / `remove_prop(uid)` (felling,
picking up; removals are kept for the session), `push_out(pos, r)`,
`register_prop()` / `register_actor()`, `stats()` (and `/pop` in the chat).

## Oak

`props/oak.tres`: the English oak, thirteen models (`variants = 13`, grown by
`scripts/population/oak_tree.gd` on `TreeBuilder` when the game loads):
four standing oaks (open-grown, young, leaning, forest-grown), two
saplings, a broken stump, three dead standing oaks (after the open-grown,
the young and the forest-grown) and three fallen logs (one
like the old, a long slender one, a short heavy one). Shares
(`OakTree.PROPS`): stump, the dead oaks together and each sapling half as
common as each standing tree, the three logs together three quarters; the logs snapped at
both ends, cast no shadow, can be stood on (none in the swamp: `not_in_swamp`), the stumps jumped onto (`walk`: the player steps up 0.7
m, higher is a wall until jumped onto); dead oaks also stand in
the swamp, as many as all the standing oaks (live, saplings, dead; not
logs or stumps) on the prairie (`density_like`, `like_group`), into its
shallows, and don't sway.

- Growth: a stout trunk with flared roots that runs on into the crown as a
  leader, giving off limbs one by one in a spiral (the lowest longest and
  flattest); every branch leaves its parent nearly along it and bends out
  over its first metres; side branches turn up, twigs carry sprigs;
  branches stop at the crown's envelope (a dome) and leaf out there. Radii
  by the pipe model (exponent 2.4), smoothed into a continuous taper; a
  branch never starts thicker than its parent there (a side branch at most
  0.8 of it), and one leaving its parent's very end carries it on as one
  (`TreeBuilder.fit_radii`).
- Leaves: alpha-cut cards from `textures/oak_leaves.png`, sprigs of English
  oak leaves (lobed, ~11 cm) near, clumps further off; lit as one crown,
  light through them from behind; flutter in the wind.
- Wind: the twigs and their leaves sway together in slow gusts
  (`shaders/render/wind.gdshaderinc`), the leaves flutter on top. A branch
  sways as its parent where it leaves it (its base stays put on it), more
  toward its tip (`TreeBuilder.sway`). The leaves dim at night.
- Bark: `textures/oak_bark.png` (furrowed, alpha = height for the bumps;
  read twice, the second mirrored and stretched, patch by patch, and from
  a different place on each branch and tree, so it doesn't show repeating;
  past 60-90 m only its average colour, dissolving between the two);
  cut and broken ends show growth rings. Textures: `python3
  tools/trees/bake_oak_textures.py`.
- Level of detail: full (16-30k triangles a tree) within 40 m, 3-6k to
  120 m, ~1k to 250 m, then (standing oaks, live and dead) one card to
  3 km: the tree photographed from eight ways round at load
  (`ImpostorBaker`), the cards drawn by `FarTrees` (`far_trees.gd`,
  `shaders/render/far_trees.gdshader`, turned to face you, lit as a crown):
  not by the chunks but a 512 m cell at a time, every species' standing
  trees in it one MultiMesh, placed by `Population._scatter`, the same trees
  in the same places as the chunks', each a layer of one `Texture2DArray`
  (`PropKind.far_card`, `far_distance`; the tree render distance setting
  scales it, 500 m to 5 km, thinning out over the last fifth); stumps, logs
  and saplings their 200-400 triangle mesh (the stem and a few big clumps)
  there instead, to 300 m,
  cross-fading stippled tree by tree over 12 m at each switch (the card's
  too: `shaders/render/lod_fade.gdshaderinc`, each level's materials
  hold its span). Each level's MultiMesh holds only a chunk's trees near
  enough its span to show in it, sorted on the CPU as the camera moves
  (`Population._bucket`: its fade and 6 m to spare either side, a few
  chunks a frame), so no tree's full mesh is worked out only to be
  collapsed; in the shadow maps each tree casts from the one level it's in
  from the main camera (`lod_shadow_pick`). Trees notched by an axe are drawn
  apart (`Population._Group`: the cut meshes for them alone; a blow changes
  only their notch's data); on
  top of that the leaf cards thin out with distance in the shader (the rest
  grow to keep the cover), each dissolving rather than popping.
- Shadows: every standing oak casts the same stand-in, a lumpy dome on a
  stalk (`shadow_mesh`); the trees and their leaves cast none and take
  shadows only part way. The dead wood casts its own. In the swamp none of
  them (standing, dead, saplings, stumps) casts a shadow (`shadowless_in`).
  The stand-ins are drawn one MultiMesh a stand-in mesh for a whole chunk,
  every kind and variant sharing it together (`Population._build_proxies`).

`xvfb-run godot --path . --script res://tools/trees/preview.gd -- <out_dir>
[side | close | leaves | dead | snag | lod]` renders them on a plain.

PropKind for models from a script: `mesh_script` (`build(variant)`,
`build_lods(variant)`, `build_shadow(variant)`, `variant_props(variant)`),
`variants` (per-variant weight, settings and `density_like` from
`variant_props`), `lods` / `lod_distances` / `shadow_distance`, `shadow_mesh`.

## Maple, sycamore, lodgepole pine, bald cypress, pawpaw, crabapple

`scripts/population/maple_tree.gd` (sugar maple, *Acer saccharum*) and
`sycamore_tree.gd` (American sycamore, *Platanus occidentalis*): each the
oak's thirteen variants (four standing trees: open-grown, young, leaning,
forest-grown; a stump; three logs; three dead trees; two saplings), grown by
`species_tree.gd` (the oak's rules, generalised: each species' own
segment lengths, crookedness, turn toward the light, branching angles,
opposite or alternate branching, how lumpy its crown) and handed on through
the same static calls `OakTree` answers (`build`, `build_lods`,
`build_shadow`, `build_walk`, `build_climb`, `variant_props`), so either can
become a prop's `mesh_script` later. Textures: `python3
tools/trees/bake_broadleaf_textures.py` (`maple_leaves.png`,
`maple_bark.png`, `sycamore_leaves.png`, `sycamore_bark.png`). To look at
them: `xvfb-run godot --path . --script res://tools/trees/preview.gd -- <out>
maple` (or `sycamore`; `pair`, `pair2` for the standing trees nearer).

- Sugar maple: a straight trunk, limbs in opposite pairs climbing steeply, a
  dense rounded to oval crown; leaves in opposite pairs on long stalks,
  palmate, five-lobed, rounded sinuses, a few big teeth; grey bark in long,
  loosening vertical plates.
- Lodgepole pine (`lodgepole_pine.gd`, *Pinus contorta*), a conifer
  (`whorls`: one leader to the top, whorls of short, level branches up it,
  each as long as the crown's `profile` there): in a stand a tall, ramrod
  bare pole with snapped branch `stubs` and a short narrow crown on top; in
  the open a narrow cone; yellow-green needles in pairs, bottlebrush tufts
  (no cones); thin orange-brown to grey scaly bark; the dead ones
  silver-grey snags.
- Bald cypress (`bald_cypress.gd`, *Taxodium distichum*), a conifer of the
  swamp: a swollen, buttressed foot (`flare`), `knees` of root standing up
  round it; young a neat cone, old a broad, flat top (`profile: flat`) on a
  tall trunk; feathery flat sprays of soft, light green needles in two
  rows; fibrous, stringy, reddish-brown to grey bark.
  Their textures: `python3 tools/trees/bake_conifer_textures.py`
  (`lodgepole_needles.png`, `lodgepole_bark.png`, `cypress_needles.png`,
  `cypress_bark.png`); `preview.gd ... lodgepole` / `cypress`.
- Pawpaw (`pawpaw_tree.gd`, *Asimina triloba*), in the game: `props/pawpaw.tres`,
  the forest's understory (8 a hectare; the standing ones, saplings and dead
  gathered in thickets, `clump`; no logs or stumps of their own, only those
  an axe leaves; drawn to 300 m; felled as the oaks are; the grown ones bear
  fruit, real and picked one by one: `Foraging`): a small understory tree,
  4-9 m, often a clump of stems from one root (`forks`); a slender trunk,
  level, slightly drooping branches, a narrowish crown; huge (15-30 cm),
  smooth-edged, obovate leaves hanging in ranks from the twigs; stubby green
  fruit hanging under the twigs (`fruit_spots`: Foraging hangs as many as are left); thin, smooth grey-brown bark, blotched, warty with
  lenticels.
- Crabapple (`crabapple_tree.gd`, a wild *Malus*): a small tree, 5-8 m, a
  short trunk or several stems, crooked, gnarled limbs spreading into a
  broad, dense, twiggy dome; small oval, sharply toothed leaves clustered
  on spurs; little red to yellow-green crabapples on long stalks;
  grey-brown bark flaking in small scaly plates, orange-brown beneath.
  Their textures: `python3 tools/trees/bake_small_tree_textures.py`
  (`pawpaw_leaves.png`, `pawpaw_bark.png`, `crabapple_leaves.png`,
  `crabapple_bark.png`); `preview.gd ... pawpaw` / `crabapple`. Their fruit
  are items (`Items`: `pawpaw`, `crabapple`), picked from the trees.
- American sycamore: a massive trunk dividing low into two or three leaders
  (`forks`), long crooked limbs at wide angles, an open, lumpy crown
  (`irregular`); bark peeling into a cream, grey-green and tan patchwork,
  white up the limbs, the old foot dark and scaly (`TreeBuilder.tint_low`);
  big, broad, shallowly lobed, coarsely toothed leaves one by one on stout
  stalks, now and then a seed ball on its thread; no lichen on its bark
  (`SpeciesTree.lichen`: false; its logs and stumps still mossy).
- Black walnut (`walnut_tree.gd`, *Juglans nigra*), in the game:
  `props/walnut.tres`: a tall, straight trunk (in a stand a long clean bole under
  a small crown), a few stout alternate limbs ascending then spreading into
  an open, uneven, rather thin crown; stout twigs; big pinnately compound
  leaves of 11-19 narrow, finely toothed leaflets, crowded toward the twigs'
  ends; round green walnuts in their husks, hanging under the twigs of the
  grown trees (the item `walnut`, 5 a hand, picked as the pawpaw's:
  `fruit_spots`, Foraging); dark, nearly black bark, deeply furrowed, its narrow ridges
  interlacing in diamonds. Its textures: `python3
  tools/trees/bake_walnut_textures.py` (`walnut_leaves.png`,
  `walnut_bark.png`); `preview.gd ... walnut`.
- Tulip tree (`tulip_tree.gd`, *Liriodendron tulipifera*), in the game:
  `props/tulip.tres`: the tallest of the broadleaves, a dead straight trunk
  running up through the crown (in a stand a very long clean bole, a small
  crown high up; in the open a tall narrow oval, a spire when young); short
  alternate limbs ascending then spreading; leaves on long slender stalks,
  four-lobed, the tip cut off square in a shallow notch, bright green; now
  and then a tulip-shaped flower, greenish yellow banded orange, or an
  upright brown cone of seeds at a twig's end; grey bark in narrow
  interlacing ridges, the furrows paler. Its textures: `python3
  tools/trees/bake_tulip_textures.py` (`tulip_leaves.png`,
  `tulip_bark.png`); `preview.gd ... tulip`.

All in the game (`props/*.tres`), choppable as the oak (their cut
variants), with the oak's far-off cards (`FarTrees`; the bushes have none); not yet the
moss's sporophytes on their logs and stumps. Where they grow (whole kinds,
per hectare, shared among their variants as the oak's):

- `maple.tres`: the forest 5, the prairie 0.12 (a very few); none in the
  taiga or the swamp (`strict`: straying across a border only into a biome
  it grows in; `not_in_swamp`).
- `crabapple.tres`: the forest 1.5, the prairie 0.8; none in the taiga or
  the swamp. Its fruit hang on the grown trees and are picked as the
  pawpaw's (`Foraging`).
- `walnut.tres`: the forest 3, the prairie 0.25 (sparse); none in the
  taiga or the swamp (`strict`, `not_in_swamp`); no dead walnuts standing
  and no fallen logs of their own (weight 0: only the trees an axe fells). Its walnuts hang on the
  grown trees and are picked as the pawpaw's (`Foraging`).
- `tulip.tres`: the forest 3, the prairie 0.25 (sparse), nowhere else: not
  in the swamp nor on its mud, and none where the ground has any share of
  another biome (`strict`, `not_in_swamp`, `never_in`).
- `lodgepole.tres` and `bald_cypress.tres`: the taiga 17 and 9 (together
  as thick as the oaks in the forest), thinning out up the mountains to
  none past 1350 m; the forest 0.6 and 0.4; none on the prairie or in the
  swamp; the bald cypress not even at the prairie's blended edges
  (`PropKind.never_in`: none where the ground has any share of it).
- `sycamore.tres`: the swamp's only, 5 (sparse; not straying out of it): the
  living and saplings more at its edges, fewer in its middle (x1.8 to
  x0.35), the dead the other way (x0.3 to x3: `PropKind.swamp_depth`, by
  `WorldData.swamp_depth`, the swamp's share on rings 300 and 700 m round).

The oaks and pawpaws are placed first, as before the others came
(`Population.FIRST_KINDS`: a kind's index seeds its placing and is in its
props' ids).
