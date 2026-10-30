# West of Nod

A Godot 4 vertical slice: 8 × 8 km of real terrain (Hanalei Bay and valley on Kauai,
from USGS elevation data) with rivers, sea, forest, grass and atmosphere, rendered
as one continuous world with no popping. Walk, sprint, swim (as in Minecraft) and fly.

## Running

Open the folder in **Godot 4.3+** (Forward+ renderer) and press Play.

| Input | Action |
|---|---|
| WASD, Space, Ctrl | move, jump, sprint |
| Space / Shift in water | swim up / sink faster (otherwise you slowly sink) |
| Ctrl + W, head under water | sprint-swim wherever you look |
| F | toggle fly mode (Space / Shift to go up / down) |
| F5 | toggle third-person camera |
| Esc | release the mouse |

## Data (`tools/dem/bake_slice.py` → `data/slice/`)

Source: USGS 3DEP 1/3 arc-second (~10 m) DEM, tile n23w160, public domain. The baker
reads only the needed window of the cloud-optimised GeoTIFF and writes:

- `heights.png` — 2048² at 4 m (16 bits as high/low bytes): the DEM projected to local
  metres, upsampled, with slope-scaled fractal detail below 10 m, and a sea floor shelf
  built from distance to the coast.
- `rivers.json` — drainage routed on the real terrain (priority flood, D8, area): river
  centrelines with hydraulic-geometry widths and water levels that only fall downstream.
  Their channels are carved into the heights.
- `masks.png` — rock (slope, convex crests), wetness (drainage area on flat ground),
  forest density, sand (low, gentle, by the sea).

To rebake (or move the window: `LAT0, LON0`): `pip install numpy scipy rasterio pillow`,
then `python tools/dem/bake_slice.py .`

## Rendering (`scripts/world/`, `shaders/render/`)

- **Terrain**: one CDLOD quadtree over the height map; patches morph into the next
  coarser level toward the end of their range, so there are no cracks and no pops.
  Normals and materials are per pixel, from the finest mip a pixel can show.
- **Rivers**: ribbon meshes along the centrelines at their water level, edges tucked
  under the banks. Each vertex carries the downstream direction and speed; the small
  waves are carried by the current, so rivers visibly flow.
- **Sea**: Gerstner waves on a camera-centred grid; they read the sea floor from the
  height map and shrink to nothing at the shore, and the terrain hides them on land.
- **Water lighting**: refraction with depth absorption, light scattered in the water,
  Fresnel; Godot adds sky reflections and sun glints.
- **Trees and grass**: placed on the GPU, one per world cell around the camera
  (anchored, never shuffling), by the masks. Detailed trees near (with shadows),
  simple crowns farther out (no shadows), cross-faded; as the far ones dither out the
  terrain draws the canopy (lit crowns and gaps), so forests reach the horizon. Grass
  clumps shrink away within 40 m, where the terrain's own grass texture carries on.
- **Atmosphere**: aerial perspective, height fog, volumetric haze, a low sun.

## Layout

- `scripts/main.gd` builds the scene.
- `scripts/world/`: `world_data.gd` (loads the data, textures, height and water
  queries), `cdlod.gd`, `river_meshes.gd`, `scatter_field.gd`, `prop_meshes.gd`,
  `terrain_collider.gd`.
- `scripts/player.gd`, `scripts/hud.gd`.
- `tools/shot.tscn` is a scripted fly-through that saves screenshots.
