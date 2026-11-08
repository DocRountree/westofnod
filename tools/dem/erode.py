#!/usr/bin/env python3
"""Hydraulic erosion of the world's mountains (rain droplets running down
them, picking up and dropping sediment: Hans Beyer, "Implementation of a
method for hydraulic erosion", 2015; as in Sebastian Lague's Hydraulic-
Erosion), so they come out carved: gullies down the fall line, sharp spurs
and ridges between them, fans of what was washed out at their feet.

The donor massifs (bake_galapagos.py: transplant) are real mountains, but
shrunk (heights x0.4, footprints x0.65) and on 34 m cells their gullies are
a cell or two wide: the B-spline the game draws them with (height_map.
gdshaderinc) smooths that away into lumps. The droplets cut at the scale
the map can hold (a few cells): what's left is mountains.

Only the high ground is worked (from ~120 m up, fully from ~350 m; the
coasts, the lowlands, the mesas of Isabela's south (their walls are their
own, bake_galapagos.py: mesas) and the swamps left as they were); the
change is smoothed a little (the droplets leave pocks a cell across) and
capped.

As a step of the world's bake (bake_galapagos.py calls erode()), or on its
own on the baked world (once: world.json records it, and a second run is
refused unless --force):

    python3 tools/dem/erode.py [repo] [--force] [--preview out.png]

(needs numpy, scipy, numba)
"""
import gzip
import json
import math
import os
import sys

import numpy as np
from scipy import ndimage

try:
    from numba import njit
except ImportError:  # (slow without, but works)
    def njit(*a, **k):
        return (lambda f: f) if not (a and callable(a[0])) else a[0]

SEED = 7
DROPS_PER_CELL = 1.5      # droplets per worked cell
LIFETIME = 48             # steps (cells) a droplet runs at most
INERTIA = 0.08            # how much a droplet keeps its direction
CAPACITY = 0.9            # sediment it can carry: x slope x speed x water
MIN_CAPACITY = 0.002
ERODE = 0.03              # share of its spare capacity it picks up a step
DEPOSIT = 0.3             # share of its excess it drops a step
EVAPORATE = 0.025
GRAVITY = 4.0
RADIUS = 1                # cells: the brush it erodes with
MAX_CUT = 70.0            # m: the most taken from a cell
MAX_FILL = 20.0           # m: and added to one
CELL = 34.24735281057963  # m (world.json: cell)
LOW, HIGH = 120.0, 350.0  # m: worked from LOW up, fully from HIGH


@njit(cache=True)
def _height_grad(H, x, y):
    n = H.shape[0]
    ix = int(x)
    iy = int(y)
    fx = x - ix
    fy = y - iy
    a = H[iy, ix]
    b = H[iy, ix + 1]
    c = H[iy + 1, ix]
    d = H[iy + 1, ix + 1]
    gx = (b - a) * (1 - fy) + (d - c) * fy
    gy = (c - a) * (1 - fx) + (d - b) * fx
    h = a * (1 - fx) * (1 - fy) + b * fx * (1 - fy) + c * (1 - fx) * fy + d * fx * fy
    return h, gx, gy


@njit(cache=True)
def _run(H, work, starts, rx, ry, seed, brush_dx, brush_dy, brush_w,
         lifetime, inertia, capacity, min_cap, erode, deposit, evaporate, gravity):
    """Droplets over H (heights in cells: metres / cell, so slopes are plain
    numbers); work: 0..1, how much a cell may be eroded."""
    np.random.seed(seed)
    n = H.shape[0]
    for k in range(starts.shape[0]):
        s = starts[k]
        x = (s % n) + np.random.random()
        y = (s // n) + np.random.random()
        dx = 0.0
        dy = 0.0
        speed = 1.0
        water = 1.0
        sed = 0.0
        for _ in range(lifetime):
            ix = int(x)
            iy = int(y)
            if ix < RADIUS + 1 or iy < RADIUS + 1 or ix >= n - RADIUS - 2 or iy >= n - RADIUS - 2:
                break
            fx = x - ix
            fy = y - iy
            h, gx, gy = _height_grad(H, x, y)
            dx = dx * inertia - gx * (1 - inertia)
            dy = dy * inertia - gy * (1 - inertia)
            l = math.sqrt(dx * dx + dy * dy)
            if l < 1e-9:
                break
            dx /= l
            dy /= l
            x += dx
            y += dy
            if x < 1 or y < 1 or x >= n - 2 or y >= n - 2:
                break
            nh, _, _ = _height_grad(H, x, y)
            dh = nh - h
            cap = max(-dh * speed * water * capacity, min_cap)
            if sed > cap or dh > 0:
                amt = min(dh, sed) if dh > 0 else (sed - cap) * deposit
                sed -= amt
                H[iy, ix] += amt * (1 - fx) * (1 - fy)
                H[iy, ix + 1] += amt * fx * (1 - fy)
                H[iy + 1, ix] += amt * (1 - fx) * fy
                H[iy + 1, ix + 1] += amt * fx * fy
            else:
                amt = min((cap - sed) * erode, -dh)
                for b in range(brush_w.shape[0]):
                    cx = ix + brush_dx[b]
                    cy = iy + brush_dy[b]
                    take = amt * brush_w[b] * work[cy, cx]
                    H[cy, cx] -= take
                    sed += take
            speed = math.sqrt(max(speed * speed - dh * gravity, 0.0))
            water *= 1 - evaporate
            if water < 0.01:
                break


def _brush(r):
    dx, dy, w = [], [], []
    for j in range(-r, r + 1):
        for i in range(-r, r + 1):
            d = math.hypot(i, j)
            if d <= r:
                dx.append(i)
                dy.append(j)
                w.append(1 - d / (r + 0.5))
    w = np.array(w, np.float64)
    return np.array(dx, np.int64), np.array(dy, np.int64), w / w.sum()


def mesa_lobe(h):
    """Isabela's southern lobe (bake_galapagos.py: mesas), whose walls are left alone."""
    big = ndimage.label(h[::4, ::4] > 0.0)[0]
    isa = big == np.argmax(np.bincount(big.ravel())[1:]) + 1
    z = np.arange(isa.shape[0])[:, None]
    lat = 90.0 - z / (isa.shape[0] - 1) * 180.0
    lobe = (isa & (lat < -14.0)).astype(np.float32)
    lobe = ndimage.zoom(ndimage.gaussian_filter(lobe, 4.0), 4, order=1)[: h.shape[0], : h.shape[1]]
    return np.clip(lobe * 2.0, 0.0, 1.0)


def work_mask(h, lobe=True):
    """0..1: how much each cell may be eroded (lobe: the whole map, so
    Isabela's southern lobe can be found and left alone)."""
    hs = ndimage.gaussian_filter(h, 3.0)
    t = np.clip((hs - LOW) / (HIGH - LOW), 0.0, 1.0)
    w = t * t * (3 - 2 * t)
    # (and only the mountains' slopes: not the gentle land round them)
    gz, gx = np.gradient(hs, CELL)
    s = np.clip((np.hypot(gx, gz) - 0.08) / 0.17, 0.0, 1.0)
    w = w * s * s * (3 - 2 * s)
    if lobe:
        w = w * (1.0 - mesa_lobe(h))
    return w.astype(np.float32)


def erode(h, cell, seed=SEED, window=None):
    """h eroded (float32, metres). window: (z0, z1, x0, x1) to work only there."""
    global CELL
    CELL = cell
    out = h.astype(np.float32).copy()
    sl = (slice(None), slice(None)) if window is None else (slice(window[0], window[1]), slice(window[2], window[3]))
    sub = out[sl].astype(np.float64)
    work = work_mask(out)[sl] if window is None else work_mask(sub.astype(np.float32), False)
    H = sub / cell
    cells = np.flatnonzero(work.ravel() > 0.02)
    if cells.size == 0:
        return out
    rng = np.random.default_rng(seed)
    n_drops = int(cells.size * DROPS_PER_CELL)
    # (droplets fall more where it's worked more: weighted by the mask)
    wv = work.ravel()[cells].astype(np.float64)
    starts = rng.choice(cells, n_drops, p=wv / wv.sum()).astype(np.int64)
    bx, by, bw = _brush(RADIUS)
    print("  eroding: %d droplets over %.0f km2" % (n_drops, cells.size * cell * cell / 1e6))
    H0 = H.copy()
    # (in batches, so it reports)
    for b0 in range(0, n_drops, 2_000_000):
        _run(H, work.astype(np.float64), starts[b0:b0 + 2_000_000], 0, 0, seed + b0, bx, by, bw,
             LIFETIME, INERTIA, CAPACITY, MIN_CAPACITY, ERODE, DEPOSIT, EVAPORATE, GRAVITY)
        print("   %d / %d" % (min(b0 + 2_000_000, n_drops), n_drops))
    d = (H - H0) * cell
    # the droplets' pocks smoothed out; capped; nothing new above the sea
    # that wasn't, nothing sunk below it that wasn't
    d = ndimage.gaussian_filter(d, 0.7)
    # (the fills spread wider: aprons, not a bank along the mountains' foot)
    d = np.minimum(d, 0.0) + ndimage.gaussian_filter(np.maximum(d, 0.0), 2.0)
    # (what's washed down settles past the worked ground's edge too, thinning
    # out, so the fans meet the land round them without a lip)
    spread = np.clip(ndimage.gaussian_filter(work, 6.0) * 4.0, 0.0, 1.0)
    d = np.clip(d, -MAX_CUT, MAX_FILL) * np.where(d < 0.0, np.clip(work * 3.0, 0.0, 1.0), spread)
    new = sub + d
    new = np.where(sub > 0.5, np.maximum(new, np.minimum(sub, 1.0)), sub)
    out[sl] = new.astype(np.float32)
    print("  eroded: mean change %.1f m, cut up to %.0f m, filled up to %.0f m" % (np.abs(d[work > 0.5]).mean() if (work > 0.5).any() else 0.0, -d.min(), d.max()))
    return out


def hillshade(h, cell):
    gz, gx = np.gradient(h, cell)
    n = np.dstack([-gx, np.ones_like(h), -gz])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    sun = np.array([-0.5, 0.6, -0.6])
    sun /= np.linalg.norm(sun)
    return np.clip(n @ sun, 0, 1)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv
    preview = sys.argv[sys.argv.index("--preview") + 1] if "--preview" in sys.argv else None
    if preview in args:
        args.remove(preview)
    repo = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    d = os.path.join(repo, "data", "world")
    meta = json.load(open(os.path.join(d, "world.json")))
    if meta.get("eroded") and not force:
        sys.exit("already eroded (world.json: eroded); --force to erode again")
    n = meta["size"]
    cell = meta["cell"]
    h = np.frombuffer(gzip.open(os.path.join(d, "heights.f16.gz")).read(), "<f2").reshape(n, n).astype(np.float32)
    out = erode(h, cell)
    if preview:
        from PIL import Image
        i = int(np.argmax(ndimage.uniform_filter(h[::8, ::8], 40)))
        cz, cx = (i // (n // 8)) * 8, (i % (n // 8)) * 8
        r = 700
        z0, x0 = max(cz - r, 0), max(cx - r, 0)
        a = hillshade(h[z0:z0 + 2 * r, x0:x0 + 2 * r], cell)
        b = hillshade(out[z0:z0 + 2 * r, x0:x0 + 2 * r], cell)
        Image.fromarray((np.hstack([a, b]) * 255).astype(np.uint8)).save(preview)
    with gzip.open(os.path.join(d, "heights.f16.gz"), "wb", compresslevel=6) as f:
        f.write(out.astype("<f2").tobytes())
    meta["eroded"] = {"droplets_per_cell": DROPS_PER_CELL, "seed": SEED, "from_m": LOW}
    json.dump(meta, open(os.path.join(d, "world.json"), "w"), indent=1)
    print("written")


if __name__ == "__main__":
    main()
