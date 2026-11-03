"""Bakes the black walnut's textures (data/population/textures/), laid out as
the oak's (bake_oak_textures.py; TreeBuilder reads them the same):

- walnut_leaves.png: an RGBA atlas of 4 x 2 tiles, 512 px each. Tiles 0-3
  are sprigs (0.8 m across): a stout twig and, crowded at its end, two to
  four big pinnately compound leaves, each a rachis 30-45 cm long carrying
  11-19 leaflets in nearly opposite pairs, lance-shaped, 6-11 cm, finely
  toothed, the middle ones the longest, the terminal leaflet often missing
  (as on Juglans nigra); no walnuts (Foraging hangs real ones: the item
  "walnut"). Tiles 4-7 are clumps (1.6 m
  across: many leaves at the sprigs' scale). Transparent pixels carry the
  colour of the nearest leaf.
- walnut_bark.png: tileable, 0.6 m square: dark brown to nearly black,
  deeply furrowed, the narrow ridges crossing one another in a diamond
  pattern. Alpha the height.

python3 tools/trees/bake_walnut_textures.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, TILE, SS, bleed, draw_line, periodic_noise  # noqa: E402
from bake_small_tree_textures import draw_simple  # noqa: E402

rng = np.random.default_rng(53)

GREEN = [0.23, 0.36, 0.1]  # (yellower than the oak's)
VEIN = [0.55, 0.63, 0.3]
RACHIS = [0.4, 0.42, 0.2]
TWIG = [0.36, 0.3, 0.22]


def jit(c, k=0.1):
    g = rng.uniform(0.87, 1.12)
    return [c[0] * g * rng.uniform(1 - k, 1 + k), c[1] * g, c[2] * g * rng.uniform(1 - k, 1 + k)]


def compound_leaf(rgba, cover, x, y, ang, length, size):
    """A pinnately compound leaf from (x, y) heading ang: its rachis length
    px, a little curved, leaflets in near-opposite pairs along it."""
    bend = rng.uniform(-0.25, 0.25)
    pairs = int(rng.integers(5, 10))
    terminal = rng.uniform() < 0.4
    colour = jit(GREEN, 0.08)
    # the rachis, in a few straight pieces along its curve
    pts = []
    n = 8
    for k in range(n + 1):
        t = k / n
        a = ang + bend * t
        if k == 0:
            pts.append((x, y))
        else:
            px, py = pts[-1]
            pts.append((px + math.cos(a) * length / n, py + math.sin(a) * length / n))
    leaflets = []
    for p in range(pairs):
        t = 0.14 + 0.84 * (p + 0.5) / pairs
        i = min(int(t * n), n - 1)
        f = t * n - i
        px = pts[i][0] + (pts[i + 1][0] - pts[i][0]) * f
        py = pts[i][1] + (pts[i + 1][1] - pts[i][1]) * f
        a = ang + bend * t
        # the middle leaflets longest, the last few and first few shorter
        ll = (0.065 + 0.045 * math.sin(math.pi * min(t * 1.15, 1.0))) * size * rng.uniform(0.9, 1.1)
        for side in (-1, 1):
            shift = rng.uniform(-0.012, 0.012) * length / max(size * 0.4, 1e-3)  # (subopposite)
            sx, sy = px + math.cos(a) * shift, py + math.sin(a) * shift
            leaflets.append((sx, sy, a + side * rng.uniform(1.0, 1.35), ll))
    if terminal:
        leaflets.append((pts[-1][0], pts[-1][1], ang + bend + rng.uniform(-0.1, 0.1), 0.06 * size))
    for k in range(n):
        w0 = 0.0022 * size * (1.0 - 0.6 * k / n)
        draw_line(rgba, cover, pts[k], pts[k + 1], w0, w0 * 0.85, RACHIS)
    for i in rng.permutation(len(leaflets)):
        lx, ly, la, ll = leaflets[i]
        draw_simple(rgba, cover, lx, ly, la, ll, 0.15, 0.38, 22, 0.05, jit(colour, 0.05), VEIN)


def sprig(rgba, cover, ox, oy, size, ang0):
    """size: px per metre. A stout twig, its leaves crowded at its end."""
    L = rng.uniform(0.12, 0.16) * size
    a = ang0 + rng.uniform(-0.1, 0.1)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    draw_line(rgba, cover, (ox, oy), end, 0.006 * size, 0.0045 * size, TWIG)
    n = int(rng.integers(2, 5))
    spread = 1.6
    order = rng.permutation(n)
    for k in order:
        b = a + (k / max(n - 1, 1) - 0.5) * spread + rng.uniform(-0.12, 0.12)
        # (the upright ones shorter: the tile's top quarter is cropped off)
        up = abs(math.cos(b - ang0))
        compound_leaf(rgba, cover, end[0], end[1], b, rng.uniform(0.32, 0.45) * size * (1.0 - 0.15 * up), size)


def clump(tile, cover, S, size):
    for k in range(26):
        r = math.sqrt(rng.uniform(0, 1)) * 0.3
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        for j in range(int(rng.integers(2, 4))):
            compound_leaf(tile, cover, x, y, rng.uniform(0, 2 * math.pi), rng.uniform(0.28, 0.4) * size, size)


def leaves(sprig_m=0.8, clump_m=1.6):
    S = TILE * SS
    out = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cov = np.zeros((S, S), bool)
        if t < 4:
            sprig(tile, cov, S * 0.5, S * 0.98, S / sprig_m, -math.pi / 2)
        else:
            clump(tile, cov, S, S / clump_m)
        y, x = divmod(t, 4)
        out[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(out)
    rgba = np.concatenate([col, out[..., 3:4]], -1)
    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, "walnut_leaves.png"), optimize=True)


def bark():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n] / n
    # two sets of ridges, each leaning a little off the vertical one way,
    # crossing: the furrows between them diamonds (whole numbers of turns
    # across the tile both ways, so it tiles)
    warp = periodic_noise(n, 1.8, (1.0, 5.0), 61) * 0.35 + periodic_noise(n, 1.2, (1.0, 2.0), 62) * 0.1
    ra = np.abs(np.sin(np.pi * (xx * 9 + yy * 2 + warp)))
    rb = np.abs(np.sin(np.pi * (xx * 9 - yy * 2 + warp * 0.8 + 0.37)))
    # each set narrow (its crests only), the two together a net of ridges
    # round deep diamond-shaped furrows
    ra = np.clip((ra - 0.62) / 0.38, 0, 1) ** 0.6
    rb = np.clip((rb - 0.62) / 0.38, 0, 1) ** 0.6
    ridge = np.maximum(ra, rb)
    fine = periodic_noise(n, 0.6, (1.0, 2.2), 63)
    cracks = np.clip(np.abs(np.sin(np.pi * (yy * 13 + 0.3 * periodic_noise(n, 1.0, (0.5, 3.0), 64)))) / 0.12, 0, 1) ** 0.5
    h = ridge * (0.75 + 0.25 * cracks) + 0.08 * fine * (0.3 + ridge)
    h = (h - h.min()) / (h.max() - h.min())
    tone = 0.9 + 0.1 * periodic_noise(n, 1.5, (1, 1), 65)
    top = np.array([0.36, 0.32, 0.28])   # the ridges' weathered dark grey-brown
    side = np.array([0.18, 0.14, 0.11])
    deep = np.array([0.05, 0.04, 0.03])  # nearly black in the furrows
    col = np.where(h[..., None] > 0.5,
                   side + (top - side) * ((h[..., None] - 0.5) / 0.5),
                   deep + (side - deep) * (h[..., None] / 0.5) ** 0.8)
    col *= (tone * (1.0 + 0.07 * fine))[..., None]
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "walnut_bark.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    leaves()
    bark()
    print("baked", OUT)
