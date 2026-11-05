"""Bakes the wild black cherry's, the wild raspberry's and the highbush
blueberry's textures (data/population/textures/), laid out as the oak's
(bake_oak_textures.py; TreeBuilder reads them the same):

- black_cherry_leaves.png, raspberry_leaves.png, blueberry_leaves.png: RGBA
  atlases of 4 x 2 tiles; 0-3 sprigs, 4-7 clumps (no fruit: Foraging hangs
  real ones).
  - Black cherry (Prunus serotina): a sprig 0.6 m across, a twig with its
    leaves one by one, alternate, lance-shaped (6-12 cm), finely toothed,
    glossy dark green, a paler midrib. Clumps 1.2 m.
  - Raspberry (Rubus idaeus / strigosus): an arching cane's end 0.5 m across,
    its leaves compound: three leaflets (a long-stalked one at the end, two
    either side), ovate, coarsely double-toothed, wrinkled with veins, mid
    green. Clumps 0.9 m.
  - Highbush blueberry (Vaccinium corymbosum): a sprig 0.4 m across, zigzag
    twigs crowded with small elliptic leaves (2-5 cm), smooth edged, blue
    green, a few going red. Clumps 0.8 m.
- black_cherry_bark.png: tileable: near black, broken into small, thin,
  scaly plates curling up at their edges (the "burnt potato chips"), red
  brown showing between. Alpha the height.
- raspberry_bark.png: a cane's: purplish red brown under a whitish bloom in
  streaks along it, fine prickles (small pale points). Alpha the height.
- blueberry_bark.png: twigs and old stems: grey brown, finely furrowed and
  shredding in strips, warm red brown under. Alpha the height.

python3 tools/trees/bake_fruit_plant_textures.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, periodic_noise, draw_line  # noqa: E402
from bake_broadleaf_textures import band_noise  # noqa: E402
from bake_conifer_textures import cells  # noqa: E402
import bake_small_tree_textures as small  # noqa: E402
from bake_small_tree_textures import draw_simple, jit, atlas  # noqa: E402

rng = np.random.default_rng(57)
small.rng = rng

# ---- black cherry ------------------------------------------------------------

CHERRY = [0.11, 0.24, 0.07]
CHERRY_VEIN = [0.4, 0.52, 0.2]


def cherry_leaf(rgba, cover, x, y, ang, size):
    st = 0.012 * size
    q = (x + math.cos(ang) * st, y + math.sin(ang) * st)
    draw_line(rgba, cover, (x, y), q, 0.0011 * size, 0.0008 * size, [0.32, 0.3, 0.14])
    draw_simple(rgba, cover, q[0], q[1], ang, rng.uniform(0.07, 0.11) * size, 0.17, 0.38, 46, 0.025, jit(CHERRY, 0.12), CHERRY_VEIN)


def cherry_sprig(rgba, cover, ox, oy, size, ang0):
    twig_c = [0.3, 0.18, 0.13]
    L = rng.uniform(0.24, 0.28) * size
    pts = [(ox, oy)]
    for k in range(4):
        a = ang0 + rng.uniform(-0.2, 0.2)
        q = (pts[-1][0] + math.cos(a) * L / 4, pts[-1][1] + math.sin(a) * L / 4)
        draw_line(rgba, cover, pts[-1], q, 0.0024 * size * (1 - 0.15 * k), 0.002 * size * (1 - 0.15 * k), twig_c)
        pts.append(q)
    for k in range(1, 5):  # (alternate, one by one, drooping out from it)
        side = 1 if k % 2 else -1
        cherry_leaf(rgba, cover, pts[k][0], pts[k][1], ang0 + side * rng.uniform(0.6, 1.1), size)
    cherry_leaf(rgba, cover, pts[-1][0], pts[-1][1], ang0, size)


def cherry_clump(tile, cover, S, size):
    for k in range(110):
        r = math.sqrt(rng.uniform(0, 1)) * 0.38
        a = rng.uniform(0, 2 * math.pi)
        cherry_leaf(tile, cover, S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r), rng.uniform(0, 2 * math.pi), size)


# ---- raspberry ----------------------------------------------------------------

RASP = [0.19, 0.34, 0.11]
RASP_VEIN = [0.36, 0.48, 0.2]


def rasp_leaf(rgba, cover, x, y, ang, size):
    """A compound leaf: its stalk, then three leaflets (the end one on its own stalk)."""
    st = 0.035 * size
    q = (x + math.cos(ang) * st, y + math.sin(ang) * st)
    draw_line(rgba, cover, (x, y), q, 0.0012 * size, 0.001 * size, [0.32, 0.3, 0.16])
    for side in (-1, 1):
        b = ang + side * rng.uniform(0.9, 1.2)
        draw_simple(rgba, cover, q[0], q[1], b, rng.uniform(0.055, 0.07) * size, 0.3, 0.42, 14, 0.09, jit(RASP), RASP_VEIN)
    e = (q[0] + math.cos(ang) * 0.012 * size, q[1] + math.sin(ang) * 0.012 * size)
    draw_line(rgba, cover, q, e, 0.0009 * size, 0.0008 * size, [0.32, 0.3, 0.16])
    draw_simple(rgba, cover, e[0], e[1], ang, rng.uniform(0.07, 0.09) * size, 0.32, 0.4, 16, 0.09, jit(RASP), RASP_VEIN)


def rasp_sprig(rgba, cover, ox, oy, size, ang0):
    cane = [0.42, 0.22, 0.18]
    L = rng.uniform(0.22, 0.26) * size
    pts = [(ox, oy)]
    a = ang0
    for k in range(4):  # (the cane arching over)
        a += 0.12
        q = (pts[-1][0] + math.cos(a) * L / 4, pts[-1][1] + math.sin(a) * L / 4)
        draw_line(rgba, cover, pts[-1], q, 0.003 * size, 0.0026 * size, cane)
        pts.append(q)
    for k in range(1, 5):
        side = 1 if k % 2 else -1
        rasp_leaf(rgba, cover, pts[k][0], pts[k][1], a + side * rng.uniform(0.7, 1.1), size)


def rasp_clump(tile, cover, S, size):
    for k in range(45):
        r = math.sqrt(rng.uniform(0, 1)) * 0.34
        b = rng.uniform(0, 2 * math.pi)
        rasp_leaf(tile, cover, S * (0.5 + math.cos(b) * r), S * (0.5 + math.sin(b) * r), rng.uniform(0, 2 * math.pi), size)


# ---- blueberry ----------------------------------------------------------------

BLUE = [0.2, 0.33, 0.21]
BLUE_RED = [0.48, 0.16, 0.1]
BLUE_VEIN = [0.4, 0.5, 0.34]


def blue_leaf(rgba, cover, x, y, ang, size):
    c = BLUE_RED if rng.uniform() < 0.07 else BLUE
    draw_simple(rgba, cover, x, y, ang, rng.uniform(0.03, 0.05) * size, 0.3, 0.5, 0, 0.0, jit(c, 0.12), BLUE_VEIN)


def blue_sprig(rgba, cover, ox, oy, size, ang0):
    twig = [0.48, 0.26, 0.2]
    L = rng.uniform(0.2, 0.24) * size
    pts = [(ox, oy)]
    for k in range(6):  # (zigzag)
        a = ang0 + (0.25 if k % 2 else -0.25)
        q = (pts[-1][0] + math.cos(a) * L / 6, pts[-1][1] + math.sin(a) * L / 6)
        draw_line(rgba, cover, pts[-1], q, 0.0016 * size, 0.0013 * size, twig)
        pts.append(q)
    for k in range(1, 7):
        for side in (-1, 1):
            blue_leaf(rgba, cover, pts[k][0], pts[k][1], ang0 + side * rng.uniform(0.6, 1.2), size)


def blue_clump(tile, cover, S, size):
    for k in range(200):
        r = math.sqrt(rng.uniform(0, 1)) * 0.38
        b = rng.uniform(0, 2 * math.pi)
        blue_leaf(tile, cover, S * (0.5 + math.cos(b) * r), S * (0.5 + math.sin(b) * r), rng.uniform(0, 2 * math.pi), size)


# ---- bark ----------------------------------------------------------------------

def save_bark(name, col, h, along=False):
    if along:  # (its streaks up and down: along the stem)
        col = np.transpose(col, (1, 0, 2))
        h = h.T
    h = (h - h.min()) / (h.max() - h.min())
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name), optimize=True)


def black_cherry_bark():
    n = 512
    edge, ids = cells(n, 30, 141)  # (small plates)
    plate = np.clip(edge / 0.25, 0, 1)
    rnd = (np.sin(ids * 12.9898) * 43758.5453) % 1.0
    curl = np.clip(1.0 - edge / 0.12, 0, 1) * (plate > 0.0)  # (their edges curling up)
    fine = periodic_noise(n, 0.7, (1, 1.4), 142)
    dark = np.array([0.14, 0.12, 0.11]) * (0.85 + 0.3 * rnd[..., None])
    under = np.array([0.42, 0.24, 0.17])
    col = np.where((plate < 0.18)[..., None], under * (0.8 + 0.3 * fine[..., None]), dark)
    col = col + curl[..., None] * np.array([0.08, 0.07, 0.06])  # (the curled rims catching the light)
    h = plate * (0.8 + 0.2 * rnd) + 0.25 * curl + 0.04 * fine
    save_bark("black_cherry_bark.png", col, h)


def raspberry_bark():
    n = 512
    fine = periodic_noise(n, 0.7, (1, 4.0), 151)  # (streaks along)
    tone = band_noise(n, 4.0, 152, (1.0, 4.0))
    base = np.array([0.44, 0.22, 0.19]) * (0.85 + 0.25 * tone[..., None])
    bloom = np.array([0.72, 0.7, 0.72])
    m = np.clip((fine - 0.2) * 1.5, 0, 1)[..., None] * 0.45
    col = base * (1 - m) + bloom * m
    h = 0.5 + 0.05 * fine
    yy, xx = np.mgrid[0:n, 0:n]
    for k in range(180):  # (prickles: small pale points)
        cx, cy = rng.uniform(0, n), rng.uniform(0, n)
        dxw = (xx - cx + n / 2) % n - n / 2
        dyw = (yy - cy + n / 2) % n - n / 2
        d = (dxw / 2.2) ** 2 + (dyw / 2.2) ** 2
        on = d < 1.0
        h = np.where(on, h + 0.45 * (1 - d), h)
        col = np.where(on[..., None], np.array([0.78, 0.66, 0.6]), col)
    save_bark("raspberry_bark.png", col, h, True)


def blueberry_bark():
    n = 512
    strip = periodic_noise(n, 0.7, (1, 6.0), 161)  # (shredding strips, along)
    tone = band_noise(n, 3.0, 162, (1.0, 3.0))
    grey = np.array([0.4, 0.35, 0.3]) * (0.85 + 0.25 * tone[..., None])
    under = np.array([0.5, 0.3, 0.22])
    col = np.where((strip < -0.25)[..., None], under, grey * (0.9 + 0.2 * strip[..., None]))
    h = 0.5 + 0.3 * strip
    save_bark("blueberry_bark.png", col, h, True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    atlas("black_cherry_leaves.png", cherry_sprig, cherry_clump, 0.6, 1.2)
    atlas("raspberry_leaves.png", rasp_sprig, rasp_clump, 0.5, 0.9)
    atlas("blueberry_leaves.png", blue_sprig, blue_clump, 0.4, 0.8)
    black_cherry_bark()
    raspberry_bark()
    blueberry_bark()
    print("baked", OUT)
