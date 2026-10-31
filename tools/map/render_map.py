"""The world map, from the baked data: shaded relief in the game's ground
colours, the sea by depth, the planet's latitude/longitude grid, the spawn
point and the aurora line.

    python tools/map/render_map.py [--biomes] [out.png]

--biomes: the biome assignments (biomes.py) over the shaded relief instead
of the ground colours, with a legend.
"""
import gzip
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import biomes

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
S = 4096
AURORA_LAT = 45.0   # = AURORA_LATITUDE in scripts/main.gd
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def lonlat(x, y):  # map pixel -> planet degrees
    return x / (S - 1) * 360.0 - 180.0, 90.0 - y / (S - 1) * 180.0


def biome_layer(h):
    """Per pixel: a biome name index into biomes.COLOURS order, or -1."""
    names = list(biomes.COLOURS)
    out = np.full(h.shape, -1, np.int8)
    lab, n = ndimage.label(h > 0.0)
    Y, X = np.mgrid[0:S, 0:S]
    lon, lat = lonlat(X, Y)
    for k, sl in enumerate(ndimage.find_objects(lab)):
        comp = lab[sl] == k + 1
        cy, cx = ndimage.center_of_mass(comp)
        clon, clat = lonlat(cx + sl[1].start, cy + sl[0].start)
        best, rule = biomes.MATCH_DEG, None
        for name, ((ilon, ilat), r) in biomes.ISLANDS.items():
            d = ((clon - ilon) ** 2 + (clat - ilat) ** 2) ** 0.5
            if d < best:
                best, rule = d, r
        if rule is None:
            continue
        sub = out[sl]
        for yy, xx in zip(*np.nonzero(comp)):
            lo, la = lon[sl][yy, xx], lat[sl][yy, xx]
            sub[yy, xx] = names.index(biomes.SWAMP if biomes.swamp(lo, la) else rule(lo, la))
    high = (ndimage.gaussian_filter(h, 3.0) > biomes.MOUNTAIN_HEIGHT) & (h > 0.0)
    out[high] = names.index(biomes.MOUNTAINS)
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    mode_biomes = "--biomes" in sys.argv
    out_path = args[0] if args else os.path.join(REPO, "docs", "biome_map.png" if mode_biomes else "world_map.png")
    d = os.path.join(REPO, "data", "world")
    m = json.load(open(os.path.join(d, "world.json")))
    n, cell = m["size"], m["cell"]
    h = np.frombuffer(gzip.open(os.path.join(d, "heights.f16.gz")).read(), "<f2").reshape(n, n).astype(np.float32)
    mk = np.asarray(Image.open(os.path.join(d, "masks.png"))).astype(np.float32) / 255
    k = n // S
    h = h.reshape(S, k, S, k).mean((1, 3))
    mk = mk.reshape(S, k, S, k, 4).mean((1, 3))
    c = cell * k
    gz, gx = np.gradient(h, c)
    L = np.array([-0.6, -0.5, 0.62]); L /= np.linalg.norm(L)
    nrm = np.dstack([-gx, -gz, np.ones_like(h)]); nrm /= np.linalg.norm(nrm, axis=2, keepdims=True)
    shade = np.clip(nrm @ L, 0, 1) * 0.85 + 0.25
    if mode_biomes:
        layer = biome_layer(h)
        col = np.full(h.shape + (3,), 0.55)
        for i, rgb in enumerate(biomes.COLOURS.values()):
            col[layer == i] = np.array(rgb) / 255.0
        land = col * (0.45 + 0.55 * shade[..., None])
    else:
        lava, humid, trees, sand = [mk[..., i, None] for i in range(4)]
        col = np.array([0.62, 0.56, 0.42]) * (1 - humid) + np.array([0.20, 0.34, 0.13]) * humid
        col = col * (1 - trees * 0.5) + np.array([0.16, 0.28, 0.12]) * trees * 0.5
        col = col * (1 - lava) + np.array([0.17, 0.14, 0.13]) * lava
        steep = np.clip((0.62 - nrm[..., 2:3]) / 0.25, 0, 1)
        col = col * (1 - steep) + np.array([0.42, 0.39, 0.35]) * steep
        col = col * (1 - sand) + np.array([0.88, 0.84, 0.72]) * sand
        land = col * shade[..., None]
    dep = np.clip(-h, 0, None)[..., None]
    sea = np.array([0.55, 0.85, 0.85]) * np.exp(-dep / 12) + np.array([0.05, 0.18, 0.38]) * (1 - np.exp(-dep / 12))
    sea = sea * (0.9 + 0.1 * np.exp(-dep / 400)) - 0.05 * np.clip(dep / 1400, 0, 1)
    img = np.where((h > 0)[..., None], land, np.clip(sea, 0, 1))
    im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
    dr = ImageDraw.Draw(im, "RGBA")
    f = ImageFont.truetype(FONT, 34)
    fs = ImageFont.truetype(FONT, 26)
    for lon in range(-180, 181, 30):
        x = (lon + 180) / 360 * (S - 1)
        dr.line([(x, 0), (x, S)], fill=(255, 255, 255, 70), width=2)
        if -180 < lon < 180:
            dr.text((x + 6, 8), "%d°%s" % (abs(lon), "E" if lon > 0 else ("W" if lon < 0 else "")), font=fs, fill=(255, 255, 255, 200))
    for lat in range(-90, 91, 15):
        y = (90 - lat) / 180 * (S - 1)
        if lat != AURORA_LAT:
            dr.line([(0, y), (S, y)], fill=(255, 255, 255, 70 if lat else 140), width=2)
        if -90 < lat < 90:
            dr.text((8, y + 4), "%d°%s" % (abs(lat), "N" if lat > 0 else ("S" if lat < 0 else "")), font=fs, fill=(255, 255, 255, 200))
    ty = (90 - AURORA_LAT) / 180 * (S - 1)
    dr.line([(0, ty), (S, ty)], fill=(140, 255, 170, 200), width=4)
    dr.text((S - 560, ty - 44), "auroras north of %d°N" % AURORA_LAT, font=fs, fill=(170, 255, 190, 255))
    ox, oz = m["origin"]
    dom = cell * (n - 1)
    sx, sz = m["spawn"]
    px, pz = (sx - ox) / dom * (S - 1), (sz - oz) / dom * (S - 1)
    dr.ellipse([px - 14, pz - 14, px + 14, pz + 14], outline=(255, 40, 40, 255), width=5)
    dr.text((px + 20, pz - 18), "spawn", font=f, fill=(255, 80, 80, 255))
    if mode_biomes:
        y = S - 460
        dr.rectangle([20, y - 16, 330, y + 250], fill=(0, 0, 0, 140))
        for i, (name, rgb) in enumerate(list(biomes.COLOURS.items()) + [("unassigned", (140, 140, 140))]):
            dr.rectangle([40, y + i * 40, 76, y + i * 40 + 30], fill=rgb + (255,))
            dr.text((92, y + i * 40 - 2), name, font=f, fill=(255, 255, 255, 240))
    title = "West of Nod — biomes" if mode_biomes else "West of Nod — the Galapagos, wrapped as a planet: east/west edges meet; top and bottom are the poles"
    dr.text((24, S - 130), title, font=f, fill=(255, 255, 255, 230))
    dr.text((24, S - 80), "%.0f km square, %.0f m per pixel. Copernicus GLO-30 DEM (c) DLR / Airbus, with transplanted mountains" % (dom / 1000, c), font=fs, fill=(255, 255, 255, 200))
    im.save(out_path, optimize=True)
    print(out_path)


if __name__ == "__main__":
    main()
