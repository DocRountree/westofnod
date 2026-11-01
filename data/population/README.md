# Population content

What grows and lives on the land. `scripts/population/population.gd`
(`Population`, a child of Main) streams it in 64 m chunks round the player,
generated on worker threads from a per-chunk seed, so the same things are
always in the same places and nothing needs saving.

- `props/*.tres`: `PropKind` (trees, rocks, grass). Mesh, material, density
  per biome (per hectare; `"*"` = any other biome), scale range, ground
  alignment, slope and height limits, view distance, and `radius` (solid:
  the player and actors walk round it; 0 = walk through, e.g. grass).
  Each kind in a chunk is one MultiMesh.
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

Two prop kinds draw the same tree (`scripts/population/fractal_tree.gd`, an
IFS: a trunk, mirrored, tilted, twisted and shrunk 7 times, a leaf cluster at
each of the 128 tips) so the techniques can be compared side by side:

- `fractal_tree_sdf`: the mesh is a box; `shaders/render/fractal_tree.gdshader`
  raymarches the tree's distance function in it and writes depth, normal and
  light position, so it sorts, lights and casts shadows like a mesh. Every
  instance differs (seeded by its position); far away, subtrees fold into
  single clusters (`lod_distance`); costs pixels, not memory.
- `fractal_tree_mesh`: the same recipe as ~12k triangles with LODs, built
  when it loads (`mesh_script`: `FractalTree.build()`). Every instance is
  the same tree, turned and scaled.

In game: `/trees` goes to the nearest forest; `/trees sdf`, `/trees mesh`,
`/trees both` choose which are drawn (watch the fps); `/trees vary 0` makes
the raymarched ones identical (as the meshes); `/trees lod <m>` sets the
distance at which they start to simplify.
