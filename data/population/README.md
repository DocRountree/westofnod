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

`props/oak.tres`: the English oak, seven models (`variants = 7`, grown by
`scripts/population/oak_tree.gd` on `TreeBuilder` when the game loads):
four standing oaks (open-grown, young, leaning, forest-grown), a broken
stump, a fallen log and a dead standing oak; the dead wood is half as common
as each standing tree (`OakTree.PROPS`).

- Growth: a short stout trunk with flared roots, crooked near-level limbs,
  side branches turning up, twigs carrying sprigs; branches stop at the
  crown's envelope (a dome) and leaf out there. Radii by the pipe model.
- Leaves: alpha-cut cards from `textures/oak_leaves.png`, sprigs of English
  oak leaves (lobed, ~11 cm) near, clumps further off; lit as one crown,
  light through them from behind; flutter in the wind.
- Bark: `textures/oak_bark.png` (furrowed, alpha = height for the bumps);
  cut and broken ends show growth rings. Textures: `python3
  tools/trees/bake_oak_textures.py`.
- Level of detail: full (8-17k triangles a tree) within 50 m, ~2k to 180 m,
  under 1k to 600 m; on top of that the leaf cards thin out with distance in
  the shader (the rest grow to keep the cover).
- Shadows: every standing oak casts the same stand-in, a lumpy dome on a
  stalk (`shadow_mesh`); the trees and their leaves cast none and take
  shadows only part way. The dead wood casts its own.

`xvfb-run godot --path . --script res://tools/trees/preview.gd -- <out_dir>
[side | close | leaves | dead | snag | lod]` renders them on a plain.

PropKind for models from a script: `mesh_script` (`build(variant)`,
`build_lods(variant)`, `build_shadow(variant)`, `variant_props(variant)`),
`variants`, `lods` / `lod_distances` / `shadow_distance`, `shadow_mesh`.
