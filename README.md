# West of Nod

A Godot 4 exploration game set in the Galapagos archipelago, built from real elevation
data (Copernicus GLO-30), 281 km across, rendered as one continuous world with no
popping. Walk, sprint, swim (as in Minecraft), climb and fly.

## Running

Open the folder in **Godot 4.3+** (Forward+ renderer) and press Play.

| Input | Action |
|---|---|
| WASD, Space, Ctrl | move, jump, sprint |
| Space / Shift in water | swim up / sink faster (otherwise you slowly sink) |
| Ctrl + W, head under water | sprint-swim wherever you look |
| F | toggle fly mode (Space / Shift to go up / down) |
| F5 | toggle third-person camera |
| C | climb rock too steep to walk (WASD over the rock, Space lets go) |
| Esc | release the mouse |

## Data (`tools/dem/bake_galapagos.py` → `data/world/`)

Source: Copernicus GLO-30 DEM, nine 1° tiles around 89–92° W on the equator ("produced
using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH
2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved").
The baker reads only the window it needs and writes:

- `heights.f16.gz`: 8192² half floats at 34 m, projected to local metres. The broad
  shape (land blurred over ~0.9 km) is raised by 150%, so volcanoes stand much
  taller and steeper without turning into cliff walls. Then a single-pass erosion
  filter after clayjohn's "Eroded Terrain Noise" (five octaves, 640 m down to 40 m)
  carves branching gullies down every slope, deeper where it's steeper. The sea floor is synthetic, from
  distance to the coast.
- `masks.png`: young lava (rough, bare), humid highlands (wetter on the south-east,
  windward side), trees (sparse grey scrub low, green Scalesia forest high, none on
  lava or the summits), sand.

The ground drawn and collided with is a cubic B-spline through the samples plus
procedural relief below 34 m (`terrain_height` in `height_map.gdshaderinc`, mirrored
by `WorldData.height_at`).

To rebake: `pip install numpy scipy rasterio pillow`, then
`python tools/dem/bake_galapagos.py .`

## Rendering (`scripts/world/`, `shaders/render/`)

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
- **Trees**: placed on the GPU, one per world cell around the camera (anchored, never
  shuffling), by the forest mask. Detailed trees near (with shadows), simple crowns
  farther out (no shadows), cross-faded. As each far tree dithers out, the terrain
  draws that same tree as a flat, sun-shaded crown with its shadow, in exactly its
  place: it reruns the placement hash (`scatter_hash.gdshaderinc`). So forests reach
  the horizon without changing as they go flat.
- **Grass** is a terrain texture (blade streaks and tufts).
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

- `scripts/main.gd` builds the scene.
- `scripts/world/`: `world_data.gd` (loads the data, textures, height and water
  queries), `cdlod.gd`, `scatter_field.gd`, `prop_meshes.gd`,
  `terrain_collider.gd`.
- `scripts/player.gd`, `scripts/hud.gd`.
- `tools/shot.tscn` is a scripted fly-through that saves screenshots.
