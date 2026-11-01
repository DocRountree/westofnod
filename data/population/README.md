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

## Fractal trees: raymarched vs mesh

`fractal_tree` is one tree recipe (`scripts/population/fractal_tree.gd`, an
IFS: a trunk, mirrored, tilted, twisted and shrunk 7 times, a leaf cluster at
each of the 128 tips) that can be drawn two ways, the same trees in the same
places either way, to A/B them (T in game, or `/trees ray` / `/trees trad`):

- meshes (the default): ~12k triangles within 80 m, a ~700-triangle version
  to 250 m, a ~110-triangle one without shadows to 600 m
  (`FractalTree.build_lods()` folds cut branches into clusters). Every tree
  is the same shape, turned and scaled.
- raymarched, at every distance: each tree is a box in which
  `shaders/render/fractal_tree.gdshader` marches the tree's distance
  function and writes depth, normal and light position, so it sorts, lights
  and casts shadows like a mesh. Every tree differs (seeded by its
  position); far away, subtrees fold into single clusters (`/trees lod <m>`);
  costs pixels, not memory. `/trees vary 0` makes them all alike.

`/trees` goes to the nearest forest.
