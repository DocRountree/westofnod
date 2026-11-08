"""Bakes the lodgepole pine's and the bald cypress's textures
(data/population/textures/), laid out as the oak's (bake_oak_textures.py;
TreeBuilder reads them the same):

- lodgepole_needles.png, cypress_needles.png: RGBA atlases of 4 x 2 tiles,
  512 px each; tiles 0-3 sprigs (0.5 m across), 4-7 clumps (1 m). Transparent
  pixels carry the colour of the nearest needle.
  - Lodgepole: a shoot (and a side shoot or two) clothed toward its end in
    yellow-green needles, in pairs, 4-7 cm, angled forward, a bottlebrush
    (no cones).
  - Bald cypress: a twig with feathery branchlets one by one along it, each
    with flat, soft, light green needles, 1-2 cm, in two rows (flat sprays).
- lodgepole_bark.png: tileable, 0.6 m square: thin, small scales, orange-
  brown to grey-brown, fine dark cracks between them. Alpha the height.
- cypress_bark.png: tileable: fibrous, in long, narrow, stringy vertical
  strips, reddish brown to grey. Alpha the height.
- spruce_needles.png: as the others: a spruce's spray, a shoot with side
  shoots off it in two ranks (flattish, the way they grow out along a
  branch), each densely clothed all round in short, stiff needles, 1.5-2.5
  cm, dark blue-green, the newest at the tips a fresher, lighter green.
- spruce_bark.png: tileable: thin, small, roundish scales, grey-brown with
  a purplish cast, flaking. Alpha the height.

python3 tools/trees/bake_conifer_textures.py [--spruce]  (--spruce: only the spruce's)
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, TILE, SS, bleed, draw_line, periodic_noise  # noqa: E402
from bake_broadleaf_textures import band_noise  # noqa: E402

rng = np.random.default_rng(29)


def jitter(c, k):
    g = rng.uniform(0.85, 1.12)
    return [c[0] * g * rng.uniform(1 - k, 1 + k), c[1] * g, c[2] * g * rng.uniform(1 - k, 1 + k)]


# ---- lodgepole ----------------------------------------------------------------

PINE = [0.27, 0.35, 0.12]


def needle_tuft(rgba, cover, p0, p1, size, start=0.35):
    """Needles along the shoot p0 -> p1 from `start` of the way on, angled
    forward, both sides and across (seen at all angles), denser at the end."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    a = math.atan2(dy, dx)
    n = int(L / size / 0.004)  # (a pair every 4 mm or so)
    for i in range(n):
        t = start + (1 - start) * (i / max(n - 1, 1)) ** 0.8
        bx, by = p0[0] + dx * t, p0[1] + dy * t
        for _ in range(2):
            spread = rng.uniform(0.35, 1.25) * (1.0 - 0.45 * t)  # (closer in at the tip)
            b = a + rng.choice([-1, 1]) * spread + rng.uniform(-0.1, 0.1)
            l = rng.uniform(0.04, 0.07) * size
            e = (bx + math.cos(b) * l, by + math.sin(b) * l)
            draw_line(rgba, cover, (bx, by), e, 0.0011 * size, 0.0004 * size, jitter(PINE, 0.08))


def pine_sprig(rgba, cover, ox, oy, size, ang0):
    twig_c = [0.42, 0.32, 0.2]
    L = rng.uniform(0.3, 0.38) * size
    a = ang0 + rng.uniform(-0.08, 0.08)
    mid = (ox + math.cos(a) * L * 0.5, oy + math.sin(a) * L * 0.5)
    a2 = a + rng.uniform(-0.12, 0.12)
    end = (mid[0] + math.cos(a2) * L * 0.5, mid[1] + math.sin(a2) * L * 0.5)
    shoots = [((ox, oy), mid, end)]
    for side in rng.permutation([-1, 1])[: rng.integers(1, 3)]:
        t = rng.uniform(0.3, 0.5)
        base = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        b = a + side * rng.uniform(0.5, 0.8)
        l = rng.uniform(0.14, 0.2) * size
        e = (base[0] + math.cos(b) * l, base[1] + math.sin(b) * l)
        shoots.append((base, base, e))
    for s0, s1, s2 in shoots:
        draw_line(rgba, cover, s0, s1, 0.004 * size, 0.0035 * size, twig_c)
        draw_line(rgba, cover, s1, s2, 0.0035 * size, 0.0025 * size, twig_c)
    for s0, s1, s2 in shoots:
        needle_tuft(rgba, cover, s0, s2, size)


# ---- bald cypress -------------------------------------------------------------

CYPRESS = [0.33, 0.47, 0.17]


def cypress_spray(rgba, cover, x, y, ang, length, size):
    """A branchlet from (x, y): flat needles in two rows, shorter at its ends."""
    e = (x + math.cos(ang) * length, y + math.sin(ang) * length)
    draw_line(rgba, cover, (x, y), e, 0.0009 * size, 0.0005 * size, [0.4, 0.42, 0.2])
    n = int(length / size / 0.0035)
    col = jitter(CYPRESS, 0.06)
    for i in range(1, n):
        t = i / n
        bx, by = x + (e[0] - x) * t, y + (e[1] - y) * t
        nl = (0.01 + 0.009 * math.sin(math.pi * min(t * 1.15, 1.0))) * size
        for side in (-1, 1):
            b = ang + side * rng.uniform(1.15, 1.4)  # (nearly square to it, a little forward)
            p = (bx + math.cos(b) * nl, by + math.sin(b) * nl)
            draw_line(rgba, cover, (bx, by), p, 0.0008 * size, 0.0005 * size, col)


def cypress_sprig(rgba, cover, ox, oy, size, ang0):
    twig_c = [0.45, 0.33, 0.22]
    L = rng.uniform(0.3, 0.36) * size
    a = ang0 + rng.uniform(-0.08, 0.08)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    draw_line(rgba, cover, (ox, oy), end, 0.0025 * size, 0.0014 * size, twig_c)
    side = rng.choice([-1, 1])
    k = 0
    t = 0.15
    while t < 0.97:
        bx, by = ox + (end[0] - ox) * t, oy + (end[1] - oy) * t
        b = a + side * rng.uniform(0.75, 1.05)
        cypress_spray(rgba, cover, bx, by, b, rng.uniform(0.08, 0.12) * size * (1.0 - 0.3 * t), size)
        side = -side
        t += rng.uniform(0.07, 0.11)
        k += 1
    cypress_spray(rgba, cover, end[0], end[1], a, 0.1 * size, size)


# ---- spruce -------------------------------------------------------------------

SPRUCE = [0.13, 0.23, 0.13]       # (dark, a little blue)
SPRUCE_NEW = [0.26, 0.38, 0.15]   # (this year's growth, at the tips)


def spruce_shoot(rgba, cover, p0, p1, size):
    """A shoot p0 -> p1 clothed all round in short needles (seen side on: out
    both sides and, foreshortened, across it), the last third fresher."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    a = math.atan2(dy, dx)
    draw_line(rgba, cover, p0, p1, 0.0022 * size, 0.0012 * size, [0.4, 0.3, 0.2])
    n = int(L / size / 0.0016)
    for i in range(n):
        t = i / max(n - 1, 1)
        bx, by = p0[0] + dx * t, p0[1] + dy * t
        new = t > 0.68
        col = jitter(SPRUCE_NEW if new else SPRUCE, 0.1)
        for _ in range(2):
            spread = rng.uniform(0.5, 1.35)  # (out from the shoot, forward)
            b = a + rng.choice([-1, 1]) * spread + rng.uniform(-0.15, 0.15)
            fore = abs(math.cos(spread))  # (the across ones look shorter)
            l = rng.uniform(0.015, 0.024) * size * (0.55 + 0.45 * (1 - fore * 0.5)) * (0.8 if t > 0.92 else 1.0)
            e = (bx + math.cos(b) * l, by + math.sin(b) * l)
            draw_line(rgba, cover, (bx, by), e, 0.0011 * size, 0.0005 * size, col)


def spruce_sprig(rgba, cover, ox, oy, size, ang0):
    L = rng.uniform(0.34, 0.4) * size
    a = ang0 + rng.uniform(-0.06, 0.06)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    shoots = [((ox, oy), end)]
    t = rng.uniform(0.12, 0.2)
    side = rng.choice([-1, 1])
    while t < 0.85:
        base = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        b = a + side * rng.uniform(0.6, 0.85)
        l = rng.uniform(0.12, 0.17) * size * (1.0 - 0.55 * t)
        e = (base[0] + math.cos(b) * l, base[1] + math.sin(b) * l)
        shoots.append((base, e))
        # (a second order on the longer ones)
        if l > 0.1 * size and rng.random() < 0.6:
            tb = rng.uniform(0.35, 0.6)
            b2 = (base[0] + (e[0] - base[0]) * tb, base[1] + (e[1] - base[1]) * tb)
            c = b + side * rng.uniform(0.6, 0.8) * rng.choice([-1, 1])
            shoots.append((b2, (b2[0] + math.cos(c) * l * 0.4, b2[1] + math.sin(c) * l * 0.4)))
        side = -side
        t += rng.uniform(0.09, 0.14)
    for s0, s1 in shoots:
        spruce_shoot(rgba, cover, s0, s1, size)


def spruce_clump(tile, cover, S, size):
    for k in range(70):
        r = math.sqrt(rng.uniform(0, 1)) * 0.34
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        b = rng.uniform(0, 2 * math.pi)
        l = rng.uniform(0.1, 0.17) * size
        spruce_shoot(tile, cover, (x, y), (x + math.cos(b) * l, y + math.sin(b) * l), size)


def spruce_bark():
    n = 512
    edge, ids = cells(n, 30, 81)
    plate = np.clip(edge / 0.16, 0, 1) ** 0.5
    rnd = (np.sin(ids * 12.9898) * 43758.5453) % 1.0
    fine = periodic_noise(n, 0.7, (1, 1.5), 82)
    tone = band_noise(n, 3.0, 83)
    h = plate * (0.7 + 0.3 * rnd) + 0.05 * fine
    h = (h - h.min()) / (h.max() - h.min())
    grey = np.array([0.4, 0.36, 0.35])
    purple = np.array([0.38, 0.29, 0.28])
    mix = np.clip(0.5 + 0.35 * tone + 0.3 * (rnd - 0.5), 0, 1)[..., None]
    col = grey * (1 - mix) + purple * mix
    col = col * (0.82 + 0.22 * plate[..., None]) * (1.0 + 0.06 * fine[..., None])
    col = np.where((plate < 0.3)[..., None], np.array([0.13, 0.1, 0.09]) + col * 0.2, col)
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "spruce_bark.png"), optimize=True)


# ---- atlases -----------------------------------------------------------------

def atlas(name, sprig, clump_fn):
    S = TILE * SS
    out = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cover = np.zeros((S, S), bool)
        if t < 4:
            sprig(tile, cover, S * 0.5, S * 0.98, S / 0.5, -math.pi / 2)
        else:
            clump_fn(tile, cover, S, S / 1.0)
        y, x = divmod(t, 4)
        out[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(out)
    rgba = np.concatenate([col, out[..., 3:4]], -1)
    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, name), optimize=True)


def pine_clump(tile, cover, S, size):
    for k in range(50):
        r = math.sqrt(rng.uniform(0, 1)) * 0.34
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        b = rng.uniform(0, 2 * math.pi)
        l = rng.uniform(0.12, 0.2) * size
        e = (x + math.cos(b) * l, y + math.sin(b) * l)
        draw_line(tile, cover, (x, y), e, 0.003 * size, 0.002 * size, [0.42, 0.32, 0.2])
        needle_tuft(tile, cover, (x, y), e, size, 0.2)


def cypress_clump(tile, cover, S, size):
    for k in range(150):
        r = math.sqrt(rng.uniform(0, 1)) * 0.34
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        cypress_spray(tile, cover, x, y, rng.uniform(0, 2 * math.pi), rng.uniform(0.1, 0.15) * size, size)


# ---- bark --------------------------------------------------------------------

def cells(n, grid, seed):
    """Tileable cells: for each pixel the distance to the nearest cell edge
    (F2 - F1 of a jittered grid of points, wrapping) and the cell's id."""
    r = np.random.default_rng(seed)
    jit = r.uniform(0.1, 0.9, (grid, grid, 2))  # each cell's point within it [gy, gx, (y, x)]
    yy, xx = np.mgrid[0:n, 0:n] / n
    gy, gx = (yy * grid).astype(int), (xx * grid).astype(int)
    f1 = np.full((n, n), 9.0)
    f2 = np.full((n, n), 9.0)
    ids = np.zeros((n, n), int)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            uy, ux = gy + oy, gx + ox  # (unwrapped: the point where it is next to this pixel)
            cy, cx = uy % grid, ux % grid  # (wrapped: whose point it is)
            py = (uy + jit[cy, cx, 0]) / grid
            px = (ux + jit[cy, cx, 1]) / grid
            d = np.hypot(px - xx, (py - yy) * 0.7)  # (scales a little taller than wide)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            ids = np.where(closer, cy * grid + cx, ids)
            f1 = np.where(closer, d, f1)
    return (f2 - f1) * grid, ids


def lodgepole_bark():
    n = 512
    edge, ids = cells(n, 22, 61)
    plate = np.clip(edge / 0.18, 0, 1) ** 0.6  # 0 in the cracks
    rnd = (np.sin(ids * 12.9898) * 43758.5453) % 1.0
    fine = periodic_noise(n, 0.7, (1, 1.5), 62)
    tone = band_noise(n, 3.0, 63)
    h = plate * (0.75 + 0.25 * rnd) + 0.04 * fine
    h = (h - h.min()) / (h.max() - h.min())
    orange = np.array([0.5, 0.33, 0.2])
    grey = np.array([0.4, 0.36, 0.32])
    mix = np.clip(0.5 + 0.35 * tone + 0.3 * (rnd - 0.5), 0, 1)[..., None]
    col = orange * (1 - mix) + grey * mix
    col = col * (0.8 + 0.25 * plate[..., None]) * (1.0 + 0.06 * fine[..., None])
    col = np.where((plate < 0.3)[..., None], np.array([0.12, 0.09, 0.07]) + col * 0.2, col)
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "lodgepole_bark.png"), optimize=True)


def cypress_bark():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n] / n
    # many narrow fibrous strips (27 round the tile), long, wandering, frayed
    warp = periodic_noise(n, 1.9, (1.0, 8.0), 71) * 0.5 + periodic_noise(n, 1.2, (1.0, 4.0), 72) * 0.15
    phase = xx * 27 + warp
    ridge = np.abs(np.sin(np.pi * phase))
    ridge = np.clip((ridge - 0.15) / 0.85, 0, 1) ** 0.6
    fibre = periodic_noise(n, 0.8, (1.0, 12.0), 73)  # (stringy along its length)
    h = ridge * (0.8 + 0.2 * np.tanh(fibre)) + 0.05 * periodic_noise(n, 0.6, (1, 3), 74)
    h = (h - h.min()) / (h.max() - h.min())
    tone = band_noise(n, 2.5, 75, (3.0, 1.0)) # (long, up and down)
    red = np.array([0.46, 0.3, 0.22])
    grey = np.array([0.46, 0.43, 0.39])
    mix = np.clip(0.45 + 0.4 * tone, 0, 1)[..., None]
    top = red * (1 - mix) + grey * mix
    deep = np.array([0.12, 0.08, 0.06])
    col = deep + (top - deep) * (h[..., None] ** 0.7)
    col *= (1.0 + 0.08 * np.tanh(fibre))[..., None]
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "cypress_bark.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    if "--spruce" not in sys.argv:
        atlas("lodgepole_needles.png", pine_sprig, pine_clump)
        atlas("cypress_needles.png", cypress_sprig, cypress_clump)
        lodgepole_bark()
        cypress_bark()
    atlas("spruce_needles.png", spruce_sprig, spruce_clump)
    spruce_bark()
    print("baked", OUT)
