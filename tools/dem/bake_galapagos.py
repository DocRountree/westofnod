#!/usr/bin/env python3
"""Bakes the world: the Galapagos archipelago, from real elevation data.

Source: Copernicus GLO-30 DEM (1 arc-second, ~30 m), nine tiles around the
equator at 89-92 W. "Produced using Copernicus WorldDEM-30 (c) DLR e.V.
2010-2014 and (c) Airbus Defence and Space GmbH 2014-2018 provided under
COPERNICUS by the European Union and ESA; all rights reserved."

The window holds the central archipelago (Isabela, Fernandina, Santiago,
Santa Cruz, San Cristobal, Floreana, Espanola, Genovesa, Marchena, Pinta and
the small islands between); Darwin and Wolf, 150 km to the north-west, are
outside it. The DEM is projected to local metres (x east, z south, as in
Godot) around its centre: at the equator the projection is almost exact.

Outputs (data/world/):
  heights.f16.gz  half floats, little endian, row-major, gzip (SIZE^2)
  masks.png       RGBA8: bare lava, humid highlands, trees, sand
  world.json      size, cell, origin, spawn, attribution

The DEM's sea is 0 m; the sea floor is shaped from distance to the coast
(the Galapagos platform: shallow near shore, deepening over kilometres).

Masks: young lava (rough, unvegetated: from the DEM's small-scale roughness
on low and middle slopes); the humid zone (the islands' high ground, wettest
on the south-east, windward side, where garua mist feeds forest); trees
(sparse in the arid lowlands, dense in the humid zone, none on lava or the
highest bare summits); sand (gentle shores).

Usage: python bake_galapagos.py <repo_dir>   (needs numpy, scipy, rasterio, pillow)
"""
import gzip
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

COP = "/vsicurl/https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_{t}_DEM/Copernicus_DSM_COG_10_{t}_DEM.tif"
LON0, LON1 = -91.72, -89.20
LAT0, LAT1 = -1.45, 0.68
SIZE = 8192
SEED = 1337
EXAGGERATE = 1.5  # broad shape raised by this fraction of itself
BROAD = 900.0     # m: the scale of the raised shape (smaller = steeper)
SPAWN = (-0.700, -90.330)  # Santa Cruz, the southern slopes above Puerto Ayora


def read_mosaic():
    """The DEM over the window at its native 1 arc-second grid."""
    import rasterio
    from rasterio.windows import from_bounds
    res = 1.0 / 3600.0
    w = int(round((LON1 - LON0) / res))
    hgt = int(round((LAT1 - LAT0) / res))
    out = np.zeros((hgt, w), np.float32)
    for la in range(math.floor(LAT0), math.ceil(LAT1)):
        for lo in range(math.floor(LON0), math.ceil(LON1)):
            tile = "%s%02d_00_%s%03d_00" % ("N" if la >= 0 else "S", abs(la), "E" if lo >= 0 else "W", abs(lo))
            b = (max(lo, LON0), max(la, LAT0), min(lo + 1, LON1), min(la + 1, LAT1))
            try:
                with rasterio.open(COP.format(t=tile)) as src:
                    win = from_bounds(*b, src.transform)
                    a = src.read(1, window=win)
            except Exception as e:  # an all-sea tile may not exist
                print("  no tile", tile, e)
                continue
            r0 = int(round((LAT1 - b[3]) / res))
            c0 = int(round((b[0] - LON0) / res))
            out[r0:r0 + a.shape[0], c0:c0 + a.shape[1]] = a[: hgt - r0, : w - c0]
            print("  tile", tile, a.shape)
    out[out < -50] = 0.0
    return out


def erosion_filter(h, cell, land):
    """A single-pass erosion filter after clayjohn's "Eroded Terrain Noise": per
    octave, gaussian-windowed cosines on a jittered grid oscillating across the
    slope, so their troughs line up into gullies running downhill; each octave
    is bent by the gullies already carved, which makes them branch. Gully depth
    scales with slope x wavelength. Returns the change in height (carving only)."""
    n = h.shape[0]
    hs = ndimage.gaussian_filter(h, 2.0)
    gz, gx = np.gradient(hs, cell)
    slope = np.hypot(gx, gz)
    out = np.zeros_like(h)
    eg_x = np.zeros_like(h)
    eg_z = np.zeros_like(h)
    rng = np.random.default_rng(SEED + 7)
    wl = 640.0
    amp = 0.22
    g = np.arange(n) * cell
    for octave in range(5):
        jit = rng.random((4096, 4096, 2)).astype(np.float32)
        for r0 in range(0, n, 512):
            sl = slice(r0, r0 + 512)
            Z, X = np.meshgrid(g[sl] / wl, g / wl, indexing="ij")
            bx = gx[sl] + eg_x[sl] * 0.7
            bz = gz[sl] + eg_z[sl] * 0.7
            L = np.maximum(np.hypot(bx, bz), 1e-5)
            dx, dz = bz / L, -bx / L  # across the slope
            ix, iz = np.floor(X), np.floor(Z)
            fx, fz = X - ix, Z - iz
            va = np.zeros(X.shape, np.float32); vx = np.zeros_like(va); vz = np.zeros_like(va); wt = np.zeros_like(va)
            for i in range(-2, 2):
                for j in range(-2, 2):
                    cx = (ix - i).astype(np.int64) % 4096
                    cz = (iz - j).astype(np.int64) % 4096
                    px = fx + i - (jit[cz, cx, 0] - 0.5)
                    pz = fz + j - (jit[cz, cx, 1] - 0.5)
                    w = np.exp(-(px * px + pz * pz) * 2.0)
                    mag = (px * dx + pz * dz) * 2 * np.pi
                    va += np.cos(mag) * w
                    s_ = -np.sin(mag) * 2 * np.pi * w
                    vx += s_ * dx
                    vz += s_ * dz
                    wt += w
            a = amp * wl * np.minimum(slope[sl], 1.0)
            out[sl] += a * (va / wt - 1.0) * 0.5
            eg_x[sl] += a * 0.5 * vx / wt / wl
            eg_z[sl] += a * 0.5 * vz / wt / wl
        wl *= 0.5
        amp *= 0.9
        print("  octave", octave)
    # fade out at the coast
    return out * np.clip(h / 15.0, 0, 1) * land


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    out_dir = os.path.join(repo, "data", "world")
    os.makedirs(out_dir, exist_ok=True)
    rng = np.random.default_rng(SEED)
    print("reading DEM...")
    dem = read_mosaic()
    lat_c = 0.5 * (LAT0 + LAT1)
    lon_c = 0.5 * (LON0 + LON1)
    m_lat = 110574.0
    m_lon = 111320.0 * math.cos(math.radians(lat_c))
    width_m = (LON1 - LON0) * m_lon
    height_m = (LAT1 - LAT0) * m_lat
    domain = max(width_m, height_m)
    cell = domain / (SIZE - 1)
    print("domain %.0f km, cell %.1f m" % (domain / 1000, cell))
    print("resampling...")
    g = np.arange(SIZE) * cell - domain / 2
    h = np.empty((SIZE, SIZE), np.float32)
    for r0 in range(0, SIZE, 512):
        Z, X = np.meshgrid(g[r0:r0 + 512], g, indexing="ij")
        lon = lon_c + X / m_lon
        lat = lat_c - Z / m_lat
        row = (LAT1 - lat) * 3600.0 - 0.5
        col = (lon - LON0) * 3600.0 - 0.5
        h[r0:r0 + 512] = ndimage.map_coordinates(dem, [row, col], order=1, mode="constant", cval=0.0)
    del dem
    land = h > 0.5
    # Height exaggeration that adds no cliffs: only the broad shape is raised
    # (the land blurred over ~1.5 km), so the volcanoes stand taller while
    # every local slope steepens only by the gentle slope of that broad
    # shape; coasts stay at sea level.
    broad = ndimage.gaussian_filter(np.maximum(h, 0.0), BROAD / cell)
    h = np.where(land, h + EXAGGERATE * broad * np.clip(h / 20.0, 0, 1), h).astype(np.float32)
    print("erosion filter...")
    h = np.where(land, h + erosion_filter(h, cell, land), h).astype(np.float32)
    print("sea floor...")
    d_sea = ndimage.distance_transform_edt(~land) * cell
    floor = -(2.0 + 0.012 * d_sea + 180.0 * (1 - np.exp(-d_sea / 2500.0)))
    h = np.where(land, h, np.minimum(h, floor))
    # The sea floor is synthetic and smooth: whole metres are plenty, and they
    # compress far better.
    h = np.where(h < -2.0, np.round(h), h).astype(np.float32)
    print("masks...")
    gz, gx = np.gradient(h, cell)
    slope = np.hypot(gx, gz)
    # Young lava: rough at the scale of a few cells, unvegetated.
    hp = h - ndimage.gaussian_filter(h, 2.0)
    rough = ndimage.gaussian_filter(np.abs(hp), 3.0)
    patch = sum(a * ndimage.zoom(rng.standard_normal((SIZE // s + 3,) * 2), s, order=1)[:SIZE, :SIZE]
                for s, a in [(256, 1.0), (64, 0.5), (16, 0.25)]).astype(np.float32)
    lava = np.clip((rough - 1.2) / 2.5, 0, 1) * (h < 1500) * land
    # The humid zone: high ground, wetter facing the south-east trade winds.
    aspect_se = np.clip((gx * -0.6 + gz * -0.8) / np.maximum(slope, 1e-3), -1, 1)  # downslope toward the SE
    humid = np.clip((h - 300.0 - 200.0 * aspect_se * (slope > 0.03)) / 550.0, 0, 1) * land
    humid *= np.clip((2600.0 - h) / 450.0, 0, 1)
    trees = np.clip(0.08 + 0.12 * patch + 0.85 * humid - lava * 1.5, 0, 1) * (h > 3.0)
    trees *= np.clip((2000.0 - h) / 300.0, 0, 1)  # the summits are bare
    near_sea = ndimage.distance_transform_edt(h > 0.0) * cell < 70.0
    sand = ndimage.gaussian_filter(((h > -1.5) & (h < 3.0) & (slope < 0.2) & near_sea).astype(np.float32), 1.0)
    m = np.stack([lava, humid, trees, sand], -1)
    m = (np.clip(m, 0, 1) * 255 + 0.5).astype(np.uint8)
    print("writing...")
    with gzip.open(os.path.join(out_dir, "heights.f16.gz"), "wb", compresslevel=6) as f:
        f.write(h.astype("<f2").tobytes())
    Image.fromarray(m, "RGBA").save(os.path.join(out_dir, "masks.png"))
    sx = (SPAWN[1] - lon_c) * m_lon
    sz = -(SPAWN[0] - lat_c) * m_lat
    with open(os.path.join(out_dir, "world.json"), "w") as f:
        json.dump({
            "name": "Galapagos Islands",
            "size": SIZE, "cell": cell, "origin": [-domain / 2, -domain / 2], "format": "f16gz",
            "spawn": [sx, sz],
            "centre_lat_lon": [lat_c, lon_c],
            "source": "Copernicus GLO-30 DEM: produced using Copernicus WorldDEM-30 (c) DLR e.V. 2010-2014 "
                      "and (c) Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the "
                      "European Union and ESA; all rights reserved",
        }, f, indent=1)
    print("max height %.0f m" % h.max())


if __name__ == "__main__":
    main()
