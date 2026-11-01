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
| Z | magnify (a telescope, for now a key); mouse wheel sets the power, 2x-8x |
| [ / ] | run time backward / forward |
| Enter / `/` | chat / commands (`/help`: `/tp`, `/time`, `/spawn`, `/fly`, `/zoom`, `/aurora`, `/pos`, `/pop`, `/trees`, `/clear`) |
| T | trees: raymarched / meshes (A/B, the same trees) |
| F6 | debug: an aurora every night |
| Space ×2 | toggle fly mode (Space / Shift to go up / down) |
| F5 | toggle third-person camera |
| C | climb rock too steep to walk (WASD over the rock, Space lets go) |
| Esc | release the mouse |

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
- **No trees** for now. Props would go in a `ScatterField` (`scripts/world/scatter_field.gd`):
  placed on the GPU, one per world cell around the camera, by a mask; the baked tree
  mask is still in `masks.png` (blue), unused.
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
pools, moss and lichen with snow, conifer floor, banded red sandstone walls on
scrubby caprock, black basalt and ash, beach and dunes), blending across the
borders. `/pos` names the biome you're in.
