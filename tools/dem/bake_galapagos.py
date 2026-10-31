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


# Mountain massifs transplanted onto the islands in place of their volcanoes:
# (name, Copernicus tile, centre lat, lon, radius m). Real terrain, chosen for
# being dramatic and craggy rather than conical.
DONORS = [
    ("Madeira, Pico Ruivo", "N32_00_W017_00 N32_00_W018_00", 32.76, -16.94, 9000.0),
    ("Corsica, Monte Cinto", "N42_00_E008_00 N42_00_E009_00", 42.38, 8.95, 12000.0),
    ("Kefalonia, Mount Ainos", "N38_00_E020_00", 38.15, 20.62, 9000.0),
    ("Lofoten, Moskenesoya", "N67_00_E013_00", 67.95, 13.05, 9000.0),
    ("La Gomera", "N28_00_W018_00", 28.10, -17.23, 9000.0),
]
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache")


def cached(name, fn):
    """fn() once, then from tools/dem/.cache (so rebakes don't download again)."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name + ".npy")
    if os.path.exists(path):
        return np.load(path)
    a = fn()
    np.save(path, a)
    return a


def read_donor(tile, lat, lon, radius):
    """A donor massif as a square of heights in local metres (30 m cells), centred."""
    import rasterio
    from rasterio.windows import from_bounds
    m_lat = 110574.0
    m_lon = 111320.0 * math.cos(math.radians(lat))
    dl, dn = radius / m_lat, radius / m_lon
    a = None
    for t in tile.split():  # a massif near a tile edge spans several tiles
        with rasterio.open(COP.format(t=t)) as src:
            win = from_bounds(lon - dn, lat - dl, lon + dn, lat + dl, src.transform)
            b = src.read(1, window=win, boundless=True, fill_value=0, out_shape=(int(2 * radius / 30), int(2 * radius / 30))).astype(np.float32)
        a = b if a is None else np.maximum(a, b)
    a[a < -50] = 0.0
    n = int(2 * radius / 30.0)
    return ndimage.zoom(a, (n / a.shape[0], n / a.shape[1]), order=1)


def transplant(h, cell, land, rng):
    """Raises donor massifs on each island, keeping the real coastline: the
    original ground survives in a band along the coast and the massifs rise
    behind it. Donors are never stretched (that turns ridges into lumps);
    big islands get several of them, pushed taller the bigger the island."""
    donors = [cached("donor_%d" % k, lambda d=d: read_donor(*d[1:])) for k, d in enumerate(DONORS)]
    step = 4  # find islands on a coarse grid
    lab, nlab = ndimage.label(land[::step, ::step])
    d_coast = ndimage.distance_transform_edt(land) * cell
    dc_coarse = d_coast[::step, ::step]
    out = h.copy()
    for k, sl in enumerate(ndimage.find_objects(lab)):
        comp = lab[sl] == k + 1
        area = comp.sum() * (cell * step) ** 2
        if area < 3e6:
            continue
        # unrealistically tall on the big islands: x1 small, up to x2.3 on Isabela
        gain = 1.0 + 1.3 * float(np.clip((area - 30e6) / 3000e6, 0, 1)) ** 0.6
        z0 = max(int(sl[0].start * step) - 64, 0); z1 = min(int(sl[0].stop * step) + 64, h.shape[0])
        x0 = max(int(sl[1].start * step) - 64, 0); x1 = min(int(sl[1].stop * step) + 64, h.shape[1])
        dc = d_coast[z0:z1, x0:x1]
        mh = np.zeros_like(dc)
        # massif centres: farthest-point sampling over the interior
        zs, xs = np.nonzero(comp)
        pz = (zs + sl[0].start) * step * cell
        px = (xs + sl[1].start) * step * cell
        inner = dc_coarse[sl][comp]
        n_mass = max(1, int(round(area / 150e6)))
        score = inner.copy()
        names = []
        for m in range(n_mass):
            i = int(np.argmax(score))
            di = int(rng.integers(len(DONORS)))
            don = donors[di]
            dr = DONORS[di][4]
            scale = float(np.clip(inner[i] / (0.8 * dr), 0.45, 1.0))  # shrink only
            ang = rng.uniform(0, 2 * math.pi)
            Z, X = np.meshgrid(np.arange(z0, z1) * cell - pz[i], np.arange(x0, x1) * cell - px[i], indexing="ij")
            u = (X * math.cos(ang) - Z * math.sin(ang)) / scale
            v = (X * math.sin(ang) + Z * math.cos(ang)) / scale
            n = don.shape[0]
            dh = ndimage.map_coordinates(don, [v / 30.0 + n / 2, u / 30.0 + n / 2], order=1, mode="constant", cval=0.0)
            # round footprint: fade the donor out towards its rim so the
            # square tile edges never show as cliffs
            t = np.clip((1.0 - np.hypot(u, v) / dr) / 0.45, 0, 1)
            dh = np.maximum(dh, 0.0) * gain * (t * t * (3 - 2 * t))
            mh = np.maximum(mh, dh)
            dist = np.hypot(pz - pz[i], px - px[i])
            score = np.minimum(score, dist * 0.5)
            names.append(DONORS[di][0].split(",")[0])
        w = np.clip((dc - 120.0) / 900.0, 0, 1)
        w = w * w * (3 - 2 * w)
        orig = h[z0:z1, x0:x1]
        coast = np.minimum(orig, 15.0 + 0.04 * dc)  # the real shore, gently rising
        new = coast * (1 - w) + np.maximum(mh, coast) * w
        out[z0:z1, x0:x1] = np.where(land[z0:z1, x0:x1], new, orig)
        print("  island %.0f km2, x%.2f tall <- %s" % (area / 1e6, gain, ", ".join(names)))
    return out


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    out_dir = os.path.join(repo, "data", "world")
    os.makedirs(out_dir, exist_ok=True)
    rng = np.random.default_rng(SEED)
    print("reading DEM...")
    dem = cached("galapagos_mosaic", read_mosaic)
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
        h[r0:r0 + 512] = ndimage.map_coordinates(dem, [row, col], order=1, mode="constant", cval=0.0, prefilter=False)
    del dem
    land = h > 0.5
    print("mountains...")
    h = transplant(h, cell, land, rng).astype(np.float32)
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
