# Population content

What grows and lives on the land. `scripts/population/population.gd`
(`Population`, a child of Main) streams it in 64 m chunks round the player,
generated on worker threads from a per-chunk seed, so the same things are
always in the same places and nothing needs saving.

- `props/*.tres`: `PropKind` (trees, rocks, grass). Mesh, material, density
  per biome (per hectare; `"*"` = any other biome), scale range, ground
  alignment, slope and height limits, view distance, and `radius` (solid:
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

`props/oak.tres`: the English oak, eleven models (`variants = 11`, grown by
`scripts/population/oak_tree.gd` on `TreeBuilder` when the game loads):
four standing oaks (open-grown, young, leaning, forest-grown), two
saplings, a broken stump, a dead standing oak and three fallen logs (one
like the old, a long slender one, a short heavy one). Shares
(`OakTree.PROPS`): stump, dead oak and each sapling half as common as each
standing tree, the three logs together three quarters; the logs snapped at
both ends, cast no shadow and can be walked over; dead oaks also stand in
the swamp, as many as all the standing oaks (live, saplings, dead; not
logs or stumps) on the prairie (`density_like`, `like_group`), into its
shallows, and don't sway.

- Growth: a stout trunk with flared roots that runs on into the crown as a
  leader, giving off limbs one by one in a spiral (the lowest longest and
  flattest); every branch leaves its parent nearly along it and bends out
  over its first metres; side branches turn up, twigs carry sprigs;
  branches stop at the crown's envelope (a dome) and leaf out there. Radii
  by the pipe model (exponent 2.4), smoothed into a continuous taper.
- Leaves: alpha-cut cards from `textures/oak_leaves.png`, sprigs of English
  oak leaves (lobed, ~11 cm) near, clumps further off; lit as one crown,
  light through them from behind; flutter in the wind.
- Wind: the twigs and their leaves sway together in slow gusts
  (`shaders/render/wind.gdshaderinc`), the leaves flutter on top.
- Bark: `textures/oak_bark.png` (furrowed, alpha = height for the bumps;
  past 60-90 m only its average colour, dissolving between the two);
  cut and broken ends show growth rings. Textures: `python3
  tools/trees/bake_oak_textures.py`.
- Level of detail: full (16-30k triangles a tree) within 40 m, 3-6k to
  120 m, ~1k to 300 m, 200-400 (the stem and a few big clumps) to 600 m,
  cross-fading stippled tree by tree over 12 m at each switch (and out at
  600 m) in `shaders/render/lod_fade.gdshaderinc` (each level's materials
  hold its span; Population only keeps the levels' nodes drawn a chunk
  wider than that); on
  top of that the leaf cards thin out with distance in the shader (the rest
  grow to keep the cover), each dissolving rather than popping.
- Shadows: every standing oak casts the same stand-in, a lumpy dome on a
  stalk (`shadow_mesh`); the trees and their leaves cast none and take
  shadows only part way. The dead wood casts its own.

`xvfb-run godot --path . --script res://tools/trees/preview.gd -- <out_dir>
[side | close | leaves | dead | snag | lod]` renders them on a plain.

PropKind for models from a script: `mesh_script` (`build(variant)`,
`build_lods(variant)`, `build_shadow(variant)`, `variant_props(variant)`),
`variants` (per-variant weight, settings and `density_like` from
`variant_props`), `lods` / `lod_distances` / `shadow_distance`, `shadow_mesh`.
