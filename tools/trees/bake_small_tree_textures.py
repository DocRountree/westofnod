"""Bakes the pawpaw's and the crabapple's textures (data/population/textures/),
laid out as the oak's (bake_oak_textures.py; TreeBuilder reads them the same):

- pawpaw_leaves.png, crabapple_leaves.png: RGBA atlases of 4 x 2 tiles, 512
  px each; tiles 0-3 sprigs, 4-7 clumps. Transparent pixels carry the colour
  of the nearest leaf.
  - Pawpaw (Asimina triloba): a sprig 0.7 m across, a twig with huge leaves
    (15-30 cm) one by one in two ranks, hanging down and out from it, more
    toward its end; obovate (widest beyond the middle, wedge-shaped to the
    stalk, a short point at the tip), smooth-edged, the side veins running
    out in parallel arcs (no fruit: Foraging hangs real ones). Clumps 1.4 m.
  - Crabapple (Malus): a sprig 0.5 m across, a twig with short spurs, each a
    cluster of small oval leaves (5-8 cm), sharply toothed, and now and then a
    few little red crabapples hanging on long stalks. Clumps 1 m.
- pawpaw_bark.png: tileable, 0.6 m square: thin, smooth, grey-brown, blotched
  lighter, warty with small raised lenticels. Alpha the height.
- crabapple_bark.png: tileable: grey-brown, flaking off in small, scaly
  plates, orange-brown beneath. Alpha the height.

python3 tools/trees/bake_small_tree_textures.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, TILE, SS, bleed, draw_line, periodic_noise  # noqa: E402
from bake_broadleaf_textures import band_noise  # noqa: E402
from bake_conifer_textures import cells  # noqa: E402

rng = np.random.default_rng(41)


def draw_simple(rgba, cover, x0, y0, ang, length, width, widest, teeth, tooth, colour, vein_c):
    """A simple leaf from (x0, y0) (the stalk's end) heading ang, length px:
    half-width `width` (in lengths) at its widest, `widest` of the way
    along; `teeth` round its margin, `tooth` deep (0: smooth)."""
    h, w, _ = rgba.shape
    r = length * 1.05
    xa, xb = int(max(x0 - r, 0)), int(min(x0 + r, w))
    ya, yb = int(max(y0 - r, 0)), int(min(y0 + r, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    dx, dy = xx - x0, yy - y0
    ca, sa = math.cos(ang), math.sin(ang)
    s = (dx * ca + dy * sa) / length
    t = (-dx * sa + dy * ca) / length
    p = math.log(0.5) / math.log(widest)  # (s^p = 1/2 where it's widest)
    sc = np.clip(s, 0, 1)
    half = width * np.clip(np.sin(np.pi * sc ** p), 0, 1) ** 0.85
    half *= 1.0 - 0.35 * np.clip((sc - 0.9) / 0.1, 0, 1)  # (a short point at the tip)
    if tooth > 0:
        u = np.mod(sc * teeth, 1.0)
        half *= 1.0 + tooth * ((1.0 - u) ** 2 - 0.3) * np.clip(sc / 0.15, 0, 1)
    inside = (s >= 0) & (s <= 1) & (np.abs(t) <= half)
    if not inside.any():
        return
    c = np.array(colour, np.float32)
    edge = np.clip(np.abs(t) / np.maximum(half, 1e-3), 0, 1)
    col = c[None, None, :] * (1.0 - 0.15 * edge[..., None] ** 3)
    # the midrib, and side veins arcing out to the margin
    veins = np.abs(t) < 0.008 * (1.2 - s)
    nv = 9
    for k in range(1, nv):
        sk = k / nv * 0.92
        for side in (-1, 1):
            # a curve from (sk, 0) forward and out: t = side * a * (s - sk)^0.7
            ds = s - sk
            curve = side * 1.6 * np.maximum(ds, 0) ** 0.75 * width
            veins |= (ds > 0) & (ds < 0.3) & (np.abs(t - curve) < 0.005) & ((t * side) > 0)
    mott = 1.0 + 0.05 * np.sin(xx * 0.19 + yy * 0.11) * np.sin(yy * 0.15 - xx * 0.07)
    col = col * mott[..., None]
    vc = np.array(vein_c, np.float32)
    col = np.where((veins & inside)[..., None], col * 0.55 + vc * 0.45, col)
    sub = rgba[ya:yb, xa:xb]
    sub[inside, :3] = col[inside]
    sub[inside, 3] = 1.0
    cover[ya:yb, xa:xb] |= inside


def blob(rgba, cover, cx, cy, rx, ry, ang, colour, shine=0.0, mark=None):
    """An ellipse (a fruit), shaded round, a highlight up and left."""
    h, w, _ = rgba.shape
    r = max(rx, ry) + 2
    xa, xb = int(max(cx - r, 0)), int(min(cx + r, w))
    ya, yb = int(max(cy - r, 0)), int(min(cy + r, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    ca, sa = math.cos(ang), math.sin(ang)
    u = ((xx - cx) * ca + (yy - cy) * sa) / rx
    v = (-(xx - cx) * sa + (yy - cy) * ca) / ry
    d = u * u + v * v
    on = d <= 1.0
    shade = 1.0 - 0.4 * d
    hl = np.exp(-((xx - cx + rx * 0.35) ** 2 + (yy - cy + ry * 0.35) ** 2) / (0.08 * rx * ry)) * shine
    col = np.array(colour, np.float32)[None, None, :] * shade[..., None] + hl[..., None]
    if mark is not None:
        col = np.where((np.abs(u + 0.9) < 0.12)[..., None], np.array(mark, np.float32), col)
    sub = rgba[ya:yb, xa:xb]
    sub[on, :3] = np.clip(col, 0, 1)[on]
    sub[on, 3] = 1.0
    cover[ya:yb, xa:xb] |= on


def jit(c, k=0.1):
    g = rng.uniform(0.87, 1.12)
    return [c[0] * g * rng.uniform(1 - k, 1 + k), c[1] * g, c[2] * g * rng.uniform(1 - k, 1 + k)]


# ---- pawpaw --------------------------------------------------------------------

PAW = [0.2, 0.34, 0.11]
PAW_VEIN = [0.5, 0.6, 0.28]


def pawpaw_fruit(rgba, cover, x, y, ang, size):
    n = int(rng.integers(2, 5))
    for k in range(n):
        b = ang + (k - (n - 1) / 2) * 0.45 + rng.uniform(-0.15, 0.15)
        l = rng.uniform(0.07, 0.11) * size
        cx, cy = x + math.cos(b) * (l * 0.55 + 0.01 * size), y + math.sin(b) * (l * 0.55 + 0.01 * size)
        blob(rgba, cover, cx, cy, l * 0.5, l * 0.24, b, jit([0.42, 0.52, 0.18], 0.06), 0.25, None)


def pawpaw_sprig(rgba, cover, ox, oy, size, ang0):
    twig_c = [0.4, 0.33, 0.24]
    L = rng.uniform(0.32, 0.4) * size
    a = ang0 + rng.uniform(-0.1, 0.1)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    draw_line(rgba, cover, (ox, oy), end, 0.003 * size, 0.0018 * size, twig_c)
    leaves = []
    side = rng.choice([-1, 1])
    t = 0.12
    while t < 0.95:
        p = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        # hanging: out and down from the twig, more down further along
        b = a + side * rng.uniform(1.5, 2.3)
        leaves.append((p, b, rng.uniform(0.2, 0.3) * size * (0.75 + 0.35 * t)))
        side = -side
        t += rng.uniform(0.12, 0.17)
    leaves.append((end, a + rng.uniform(-0.3, 0.3), rng.uniform(0.18, 0.26) * size))
    # (no fruit painted on: a tree's fruit are real, Foraging hangs them, as
    # many as are left to pick)
    for p, b, l in leaves[::-1]:
        st = (p[0] + math.cos(b) * 0.008 * size, p[1] + math.sin(b) * 0.008 * size)
        draw_line(rgba, cover, p, st, 0.0015 * size, 0.0012 * size, [0.38, 0.36, 0.2])
        draw_simple(rgba, cover, st[0], st[1], b, l, 0.21, 0.66, 0, 0.0, jit(PAW), PAW_VEIN)


def pawpaw_clump(tile, cover, S, size):
    for k in range(48):
        r = math.sqrt(rng.uniform(0, 1)) * 0.3
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        b = rng.uniform(0, 2 * math.pi)
        draw_simple(tile, cover, x, y, b, rng.uniform(0.15, 0.26) * size, 0.21, 0.66, 0, 0.0, jit(PAW), PAW_VEIN)


# ---- crabapple ----------------------------------------------------------------

CRAB = [0.2, 0.33, 0.11]
CRAB_VEIN = [0.48, 0.58, 0.26]


def crabapples(rgba, cover, x, y, ang, size):
    for k in range(int(rng.integers(2, 5))):
        b = ang + rng.uniform(-0.6, 0.6)
        l = rng.uniform(0.03, 0.05) * size
        e = (x + math.cos(b) * l, y + math.sin(b) * l)
        draw_line(rgba, cover, (x, y), e, 0.0008 * size, 0.0007 * size, [0.36, 0.3, 0.16])
        r = rng.uniform(0.011, 0.014) * size
        red = rng.uniform(0, 1)
        c = [0.62 + 0.1 * red, 0.12 + 0.3 * (1 - red) ** 2, 0.08]
        blob(rgba, cover, e[0] + math.cos(b) * r * 0.8, e[1] + math.sin(b) * r * 0.8, r, r * 0.95, b, c, 0.35)


def crab_spur(rgba, cover, x, y, ang, size):
    """A spur: a cluster of 3-6 leaves fanning out from one point."""
    n = int(rng.integers(3, 7))
    for k in range(n):
        b = ang + (k - (n - 1) / 2) * rng.uniform(0.4, 0.55)
        st = 0.012 * size
        q = (x + math.cos(b) * st, y + math.sin(b) * st)
        draw_line(rgba, cover, (x, y), q, 0.0009 * size, 0.0007 * size, [0.4, 0.38, 0.2])
        draw_simple(rgba, cover, q[0], q[1], b, rng.uniform(0.05, 0.075) * size, 0.26, 0.45, 32, 0.04, jit(CRAB), CRAB_VEIN)


def crab_sprig(rgba, cover, ox, oy, size, ang0):
    twig_c = [0.36, 0.27, 0.2]
    L = rng.uniform(0.3, 0.36) * size
    pts = [(ox, oy)]
    a = ang0
    for k in range(3):  # (crooked)
        a = ang0 + rng.uniform(-0.35, 0.35)
        q = (pts[-1][0] + math.cos(a) * L / 3, pts[-1][1] + math.sin(a) * L / 3)
        draw_line(rgba, cover, pts[-1], q, 0.0028 * size * (1 - 0.2 * k), 0.0022 * size * (1 - 0.2 * k), twig_c)
        pts.append(q)
    spurs = []
    for k in range(1, 4):
        p = pts[k]
        b = ang0 + rng.choice([-1, 1]) * rng.uniform(0.6, 1.2)
        s = (p[0] + math.cos(b) * 0.02 * size, p[1] + math.sin(b) * 0.02 * size)
        draw_line(rgba, cover, p, s, 0.0018 * size, 0.0015 * size, twig_c)
        spurs.append((s, b))
    spurs.append((pts[-1], a))
    if rng.uniform() < 0.6:
        s, b = spurs[int(rng.integers(0, len(spurs) - 1))]
        crabapples(rgba, cover, s[0], s[1], b + math.pi * 0.6 * rng.choice([-1, 1]), size)
    for s, b in spurs:
        crab_spur(rgba, cover, s[0], s[1], b, size)


def crab_clump(tile, cover, S, size):
    for k in range(70):
        r = math.sqrt(rng.uniform(0, 1)) * 0.36
        a = rng.uniform(0, 2 * math.pi)
        x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
        if rng.uniform() < 0.08:
            crabapples(tile, cover, x, y, rng.uniform(0, 2 * math.pi), size)
        crab_spur(tile, cover, x, y, rng.uniform(0, 2 * math.pi), size)


# ---- atlases -------------------------------------------------------------------

def atlas(name, sprig, clump, sprig_m, clump_m):
    S = TILE * SS
    out = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cover = np.zeros((S, S), bool)
        if t < 4:
            sprig(tile, cover, S * 0.5, S * 0.98, S / sprig_m, -math.pi / 2)
        else:
            clump(tile, cover, S, S / clump_m)
        y, x = divmod(t, 4)
        out[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(out)
    rgba = np.concatenate([col, out[..., 3:4]], -1)
    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, name), optimize=True)


# ---- bark ----------------------------------------------------------------------

def pawpaw_bark():
    n = 512
    tone = band_noise(n, 3.0, 81, (1.0, 1.6))
    blotch = band_noise(n, 7.0, 82, (1.0, 1.4))
    fine = periodic_noise(n, 0.7, (1, 1.3), 83)
    base = np.array([0.4, 0.36, 0.31])
    light = np.array([0.55, 0.53, 0.49])
    m = np.clip(0.5 + 0.35 * blotch + 0.15 * tone, 0, 1)[..., None] ** 1.5
    col = base * (1 - m) + light * m
    h = 0.5 + 0.04 * fine + 0.05 * blotch
    # lenticels: small raised warts, scattered, a little wider than tall
    yy, xx = np.mgrid[0:n, 0:n]
    for k in range(260):
        cx, cy = rng.uniform(0, n), rng.uniform(0, n)
        rx, ry = rng.uniform(2.5, 5.5), rng.uniform(1.5, 3.0)
        dxw = (xx - cx + n / 2) % n - n / 2
        dyw = (yy - cy + n / 2) % n - n / 2
        d = (dxw / rx) ** 2 + (dyw / ry) ** 2
        on = d < 1.0
        h = np.where(on, h + 0.25 * (1 - d), h)
        col = np.where(on[..., None], col * 0.4 + np.array([0.66, 0.6, 0.5]) * 0.6, col)
    col *= (1.0 + 0.05 * fine)[..., None]
    h = (h - h.min()) / (h.max() - h.min())
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "pawpaw_bark.png"), optimize=True)


def crabapple_bark():
    n = 512
    edge, ids = cells(n, 22, 91)
    plate = np.clip(edge / 0.22, 0, 1) ** 0.6
    rnd = (np.sin(ids * 12.9898) * 43758.5453) % 1.0
    flaked = rnd < 0.14  # (some plates fallen away, the orange-brown under them showing)
    fine = periodic_noise(n, 0.7, (1, 1.5), 92)
    tone = band_noise(n, 3.0, 93)
    grey = np.array([0.42, 0.39, 0.35]) * (0.9 + 0.12 * tone[..., None])
    under = np.array([0.5, 0.36, 0.25])
    col = np.where(flaked[..., None], under, grey * (0.85 + 0.2 * rnd[..., None]))
    col = col * (0.75 + 0.3 * plate[..., None])
    col = np.where((plate < 0.25)[..., None], np.array([0.12, 0.1, 0.08]) + col * 0.2, col)
    col *= (1.0 + 0.06 * fine)[..., None]
    h = plate * np.where(flaked, 0.55, 0.85 + 0.15 * rnd) + 0.04 * fine
    h = (h - h.min()) / (h.max() - h.min())
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "crabapple_bark.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    atlas("pawpaw_leaves.png", pawpaw_sprig, pawpaw_clump, 0.7, 1.4)
    atlas("crabapple_leaves.png", crab_sprig, crab_clump, 0.5, 1.0)
    pawpaw_bark()
    crabapple_bark()
    print("baked", OUT)
