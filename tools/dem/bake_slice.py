#!/usr/bin/env python3
"""Bakes the vertical slice from real elevation data.

Source: USGS 3DEP 1/3 arc-second (~10 m) DEM, tile n23w160 (Kauai), public
domain. Window: Hanalei Bay and valley, 8.2 x 8.2 km.

Outputs (data/slice/):
  heights.png  2048^2, 4 m spacing, 16 bits as (high, low) bytes in LA8;
               h = H_MIN + v * H_SCALE
  masks.png    RGBA8, 2048^2: rock, wetness, forest density, sand
  rivers.json  river centrelines: points [x, z], water level, width, depth
  slice.json   domain, origin, height encoding, attribution

Steps: read the window from the cloud-optimised GeoTIFF (no full download);
project to local metres (north = -z, as in Godot); upsample to 4 m (cubic) and
add fine fractal detail the 10 m data can't hold, scaled by slope; build a sea
floor shelf from distance to the coast; route drainage (priority flood + D8 on
an 8 m grid) and extract rivers by drainage area; smooth them, give them
hydraulic-geometry widths and monotone water levels, and carve their channels
into the heights; derive the material masks.

Usage: python bake_slice.py <repo_dir>   (needs numpy, scipy, rasterio, pillow)
"""
import heapq
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

URL = "/vsicurl/https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/13/TIFF/current/n23w160/USGS_13_n23w160.tif"
LAT0, LON0 = 22.196, -159.495   # centre of the slice
SIZE = 2048                      # samples per side
CELL = 4.0                       # metres
DOMAIN = (SIZE - 1) * CELL
H_MIN, H_SCALE = -60.0, 0.025    # 16-bit encoding: -60 .. 1578 m
RIVER_AREA = 0.25e6              # m^2 of drainage before a channel shows
SEED = 1337


def read_dem():
    import rasterio
    from rasterio.windows import from_bounds
    m_lat = 110574.0
    m_lon = 111320.0 * math.cos(math.radians(LAT0))
    half = DOMAIN / 2 + 200.0
    with rasterio.open(URL) as src:
        w = from_bounds(LON0 - half / m_lon, LAT0 - half / m_lat, LON0 + half / m_lon, LAT0 + half / m_lat,
                        src.transform)
        a = src.read(1, window=w).astype(np.float64)
        t = src.window_transform(w)
    a[a < -100] = 0.0
    # Resample onto the local metric grid: x east, z south.
    xs = (np.arange(SIZE) * CELL - DOMAIN / 2)
    zs = (np.arange(SIZE) * CELL - DOMAIN / 2)
    X, Z = np.meshgrid(xs, zs)
    lon = LON0 + X / m_lon
    lat = LAT0 - Z / m_lat
    col = (lon - t.c) / t.a - 0.5
    row = (lat - t.f) / t.e - 0.5
    return ndimage.map_coordinates(a, [row, col], order=3, mode="nearest")


def fractal(shape, rng, scales):
    out = np.zeros(shape)
    for s, amp in scales:
        n = rng.standard_normal((shape[0] // s + 3, shape[1] // s + 3))
        up = ndimage.zoom(n, s, order=3)[: shape[0], : shape[1]]
        out += amp * up
    return out


def sea_floor(h):
    land = h > 0.05
    dist = ndimage.distance_transform_edt(~land) * CELL
    shelf = -(1.0 + 0.012 * dist + 25.0 * (1 - np.exp(-dist / 600.0)))
    return np.where(land, h, np.minimum(h, shelf))


def priority_flood(h, sea):
    """Filled surface (epsilon rise) and the order cells were reached."""
    n0, n1 = h.shape
    w = h.copy()
    closed = sea.copy()
    heap = []
    for i, j in zip(*np.nonzero(ndimage.binary_dilation(sea) & ~sea)):
        heapq.heappush(heap, (w[i, j], i, j))
        closed[i, j] = True
    nb = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    while heap:
        v, i, j = heapq.heappop(heap)
        for di, dj in nb:
            a, b = i + di, j + dj
            if 0 <= a < n0 and 0 <= b < n1 and not closed[a, b]:
                closed[a, b] = True
                w[a, b] = max(w[a, b], v + 1e-3)
                heapq.heappush(heap, (w[a, b], a, b))
    return w


def drainage(w, sea, cell):
    n0, n1 = w.shape
    pad = np.pad(w, 1, mode="edge")
    best = np.zeros(w.shape)
    rcv = -np.ones(w.shape, dtype=np.int64)
    idx = np.arange(n0 * n1).reshape(n0, n1)
    for di, dj in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]:
        nbh = pad[1 + di: 1 + di + n0, 1 + dj: 1 + dj + n1]
        s = (w - nbh) / (cell * math.hypot(di, dj))
        ni = np.clip(np.arange(n0)[:, None] + di, 0, n0 - 1)
        nj = np.clip(np.arange(n1)[None, :] + dj, 0, n1 - 1)
        better = s > best
        best = np.where(better, s, best)
        rcv = np.where(better, idx[ni, nj], rcv)
    rcv[sea] = -1
    order = np.argsort(-w, axis=None)  # high to low: donors before receivers
    area = np.where(sea, 0.0, cell * cell).ravel()
    r = rcv.ravel()
    for k in order:
        if r[k] >= 0:
            area[r[k]] += area[k]
    return rcv.ravel(), area.reshape(w.shape)


def rivers_from(w, rcv, area, sea, cell, rng):
    n0, n1 = w.shape
    river = (area >= RIVER_AREA) & ~sea
    flat = river.ravel()
    donors = {}
    for k in np.nonzero(flat)[0]:
        r = rcv[k]
        if r >= 0 and flat[r]:
            donors.setdefault(r, []).append(k)
    a = area.ravel()
    main = {r: max(ds, key=lambda d: a[d]) for r, ds in donors.items()}
    bottoms = [k for k in np.nonzero(flat)[0] if rcv[k] < 0 or not flat[rcv[k]] or main.get(rcv[k]) != k]
    bottoms.sort(key=lambda k: -a[k])
    out = []
    for b in bottoms:
        cells = [rcv[b]] if rcv[b] >= 0 else []
        k = b
        while k is not None:
            cells.append(k)
            k = main.get(k)
        if len(cells) < 6:
            continue
        pts = np.array([[(c % n1) * cell, (c // n1) * cell] for c in cells], dtype=np.float64)
        lev = np.array([w.ravel()[c] for c in cells])
        wid = np.array([1.5 + 4.0 * math.sqrt(a[c] / 1e6) for c in cells])
        if len(cells) > 1 and rcv[b] >= 0 and not sea.ravel()[rcv[b]]:
            wid[0] = wid[1]
        # Smooth off the eight directions: a few passes of [1 2 1], ends fixed.
        for _ in range(4):
            pts[1:-1] = 0.25 * pts[:-2] + 0.5 * pts[1:-1] + 0.25 * pts[2:]
        lev = np.maximum.accumulate(lev)  # downstream first: never flows uphill
        if sea.ravel()[cells[0]]:
            lev[0] = min(lev[0], -0.3)
        out.append({"pts": pts, "level": lev, "width": wid})
    return out


def resample(r, step):
    pts, lev, wid = r["pts"], r["level"], r["width"]
    seg = np.linalg.norm(np.diff(pts, axis=0), axis=1)
    cum = np.concatenate([[0], np.cumsum(seg)])
    n = max(2, int(cum[-1] / step) + 1)
    s = np.linspace(0, cum[-1], n)
    return {
        "pts": np.stack([np.interp(s, cum, pts[:, 0]), np.interp(s, cum, pts[:, 1])], 1),
        "level": np.interp(s, cum, lev),
        "width": np.interp(s, cum, wid),
    }


def carve(h, rivers):
    """Cuts each channel into the heights: a rounded bed under the water level,
    banks easing up to the ground."""
    out = h.copy()
    for r in rivers:
        pts, lev, wid = r["pts"], r["level"], r["width"]
        for p, e, wd in zip(pts, lev, wid):
            hw = wd * 0.5
            depth = 0.5 + 0.08 * wd
            reach = hw + 3.0 + wd
            c = (p / CELL).astype(int)
            k = int(math.ceil(reach / CELL)) + 1
            i0, i1 = max(c[1] - k, 0), min(c[1] + k + 1, SIZE)
            j0, j1 = max(c[0] - k, 0), min(c[0] + k + 1, SIZE)
            if i0 >= i1 or j0 >= j1:
                continue
            zz, xx = np.mgrid[i0:i1, j0:j1] * CELL
            d = np.hypot(xx - p[0], zz - p[1])
            bed = np.where(d < hw, e - depth * (1 - (d / hw) ** 2),
                           e + 0.3 + np.clip((d - hw) / (reach - hw), 0, 1) ** 2 * 50.0)
            out[i0:i1, j0:j1] = np.minimum(out[i0:i1, j0:j1], bed)
    return out


def masks(h, rivers_area, rng):
    gz, gx = np.gradient(h, CELL)
    slope = np.hypot(gx, gz)
    curv = ndimage.laplace(ndimage.gaussian_filter(h, 2)) / CELL ** 2
    # Bare rock only on cliffs and sharp crests: Kauai's ridges are forested
    # almost to the top.
    rock = np.clip((slope - 1.3) / 0.6, 0, 1)
    rock = np.maximum(rock, np.clip(-curv * 4.0, 0, 1) * np.clip((slope - 0.9) / 0.4, 0, 1))
    wet = np.clip(np.log10(np.maximum(rivers_area, 1.0)) / 6.0 - 0.45, 0, 1) * (slope < 0.25)
    patch = fractal(h.shape, rng, [(64, 1.0), (16, 0.5)])
    forest = np.clip(0.85 + 0.4 * patch - rock * 1.2 - np.clip((0.05 - slope) * 10, 0, 1) * 0.5, 0, 1)
    forest *= (h > 3.0)
    # Tree line: trees thin out with height (wind, cloud and thin soil on the
    # summits) and on exposed crests, which the high ground keeps bare first.
    crest = np.clip(-ndimage.laplace(ndimage.gaussian_filter(h, 6)) / CELL ** 2 * 40.0, 0, 1)
    line = 640.0 - 260.0 * crest + 60.0 * patch
    forest *= np.clip((line - h) / 120.0, 0, 1)
    near_sea = ndimage.distance_transform_edt(h > 0.0) * CELL < 80.0
    sand = ((h > -2.0) & (h < 3.0) & (slope < 0.2) & near_sea).astype(float)
    sand = ndimage.gaussian_filter(sand, 1.5)
    m = np.stack([rock, wet, forest, sand], -1)
    return (np.clip(m, 0, 1) * 255 + 0.5).astype(np.uint8)


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    out_dir = os.path.join(repo, "data", "slice")
    os.makedirs(out_dir, exist_ok=True)
    rng = np.random.default_rng(SEED)
    print("reading DEM window...")
    h = read_dem()
    gz, gx = np.gradient(h, CELL)
    slope = np.hypot(gx, gz)
    # Detail below the source's 10 m: fractal relief, rougher on steep ground.
    detail = fractal(h.shape, rng, [(4, 0.6), (2, 0.25)])
    h = h + detail * (0.3 + 1.2 * np.clip(slope, 0, 1.5)) * (h > 1.0)
    h = sea_floor(h)
    print("drainage...")
    hc = h[::2, ::2]
    sea = hc <= 0.05
    sea |= np.pad(np.zeros((hc.shape[0] - 2, hc.shape[1] - 2), bool), 1, constant_values=True)
    w = priority_flood(hc, sea)
    rcv, area = drainage(w, sea, CELL * 2)
    rivers = [resample(r, 6.0) for r in rivers_from(w, rcv, area, sea, CELL * 2, rng)]
    print(len(rivers), "rivers")
    h = carve(h, rivers)
    area_full = ndimage.zoom(area, 2, order=1)[:SIZE, :SIZE]
    m = masks(h, area_full, rng)
    v = np.clip(np.round((h - H_MIN) / H_SCALE), 0, 65535).astype(np.uint16)
    # 16 bits as two 8-bit channels (high, low): Godot loads PNGs as 8-bit.
    Image.fromarray(np.stack([(v >> 8).astype(np.uint8), (v & 255).astype(np.uint8)], -1), "LA").save(
        os.path.join(out_dir, "heights.png"))
    Image.fromarray(m, "RGBA").save(os.path.join(out_dir, "masks.png"))
    origin = -DOMAIN / 2
    rj = []
    for r in rivers:
        rj.append({
            "pts": [[round(float(x) + origin, 2), round(float(z) + origin, 2)] for x, z in r["pts"]],
            "level": [round(float(e), 3) for e in r["level"]],
            "width": [round(float(wd), 2) for wd in r["width"]],
        })
    with open(os.path.join(out_dir, "rivers.json"), "w") as f:
        json.dump(rj, f, separators=(",", ":"))
    with open(os.path.join(out_dir, "slice.json"), "w") as f:
        json.dump({
            "size": SIZE, "cell": CELL, "origin": [origin, origin], "h_min": H_MIN, "h_scale": H_SCALE,
            "source": "USGS 3DEP 1/3 arc-second DEM, tile n23w160 (public domain)",
            "centre_lat_lon": [LAT0, LON0],
        }, f, indent=1)
    print("max height %.0f m, wrote %s" % (h.max(), out_dir))


if __name__ == "__main__":
    main()
