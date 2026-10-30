# West of Nod

A Godot 4 prototype: one island whose terrain comes from simulation, rendered as one
continuous surface with no tiles and no popping. You can walk, sprint, swim (as in
Minecraft) and fly over it.

## Running

Open the folder in **Godot 4.3+** and press Play. The island is simulated with compute
shaders, so you need a Vulkan renderer (Forward+ or Mobile); the Compatibility renderer
won't work. The first run simulates the island (about a minute on a laptop GPU, a few
seconds on a desktop one) and caches it in `user://islands/`; later runs load it. Delete
the cache after changing the generator. Compute shaders are compiled from source, so an
export needs `*.glsl` in its non-resource export filter.

| Input | Action |
|---|---|
| WASD, Space, Ctrl | move, jump, sprint |
| Space / Shift in water | swim up / sink faster (otherwise you slowly sink) |
| Ctrl + W, head under water | sprint-swim wherever you look |
| F | toggle fly mode (Space / Shift to go up / down) |
| F5 | toggle third-person camera |
| Esc | release the mouse |

## Simulation (`scripts/sim/`, `shaders/sim/`)

`IslandGenerator` runs five stages over an 8 km square domain:

1. **Landscape** (`landscape.glsl`, 256², GPU). Tectonic uplift against fluvial incision
   (the stream power law) plus hillslope diffusion, run to near steady state. Ridges,
   valleys and drainage basins come out of it. The uplift is strongest in a ridged
   mountain core set off to one side, so the other side keeps broad coastal plains.
   Below the coast: a shelf, then the drop to the ocean floor.
2. **Erosion** (`hydraulic.glsl`, 1024², GPU). A "virtual pipes" shallow-water model
   with sediment transport (Mei et al. 2007) and thermal slumping. Rain runs off,
   carves gullies and drops sediment where it slows: fans at the foot of slopes, deltas
   where rivers meet the sea (the sea is a sink at sea level).
3. **Hydrology** (`hydrology.gd`, 512², CPU). Landslide dams and glacial hollows; a
   priority flood fills every depression to its spill point, so lakes have levels and
   outlets; drainage areas; river chains with hydraulic-geometry widths.
4. **Rivers** (`rivers.gd`, `meander.gd`, CPU). Chains are smoothed and joined;
   small streams sway irregularly. The gentle, wide reaches meander by curvature-driven
   migration (after Howard & Knutson), cutting off necks into oxbows, and **the
   history is kept**: every few steps the channel's course is recorded with its time,
   and every cutoff with when it happened.
5. **Compose** (`compose.glsl`, 2048² at 4 m, GPU). From the eroded heightfield and the
   rivers: the meander belt becomes a floodplain blending into the hillsides; each
   recorded past course gives scroll bars and swales (the ground it last swept);
   oxbows are open water while young and silt up into marsh and then faint scars;
   natural levees line the active channel; channels and lakes are cut in. Out come
   the island's height, water level, material and water maps (`IslandData`).

The prototype is one island. For an infinite archipelago the same generator runs per
island: each island is a closed drainage system, so islands never depend on each other.

## Rendering (`scripts/world/`, `shaders/render/`)

- **Terrain**: CDLOD (Strugar's continuous distance-dependent LOD). A quadtree over the
  one height map picks patches each frame; each patch morphs into the next coarser
  level toward the end of its range, so there are no cracks and no pops. Normals and
  materials are per pixel, from the finest mip a pixel can show.
- **Rivers and lakes** use the same patches raised to the water level map, so the
  waterline never drifts. Where there is water comes from a mip-filtered coverage map:
  a river thinner than a pixel at its distance becomes a fine line, never blobs. Far
  away the terrain shader paints the same coverage as water.
- **Water shading** (`water_common.gdshaderinc`): refraction with depth absorption (red
  first), light scattered in the body and through crests, Schlick Fresnel; Godot adds
  the sky reflection and sun glints. Small waves are analytic and faded by pixel
  footprint (no textures, no sparkle). Rivers flow: their waves run downstream and the
  pattern is carried by the current.
- **Ocean**: Gerstner waves on a camera-centred grid, faded where too short for the
  grid. They read the real sea floor from the height map, shrink as the water shoals
  and vanish at the shore, so the sea never climbs onto land.
- **Collision**: a height map window of the same samples, following the player.

## Layout

- `scripts/main.gd` builds the scene and runs the generator on a worker thread.
- `scripts/sim/`: `island_generator.gd`, `hydrology.gd`, `rivers.gd`, `meander.gd`,
  `compute.gd`.
- `scripts/world/`: `island_data.gd` (maps, textures, queries, cache),
  `cdlod.gd`, `terrain_collider.gd`.
- `scripts/player.gd`, `scripts/hud.gd`.
- `tools/render_island.gd` renders top-down maps:
  `godot --path . -s tools/render_island.gd -- <out_dir> [full|test] [seed] [x z span]`.
- `tools/shot.tscn` is a scripted fly-through that saves screenshots.
