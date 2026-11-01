"""Bakes the oak's textures (data/population/textures/):

- oak_leaves.png: an RGBA atlas of 4 x 2 tiles, 512 px each. Tiles 0-3 are
  sprigs (0.5 m across): a twig with shoots, the leaves crowded at the shoot
  tips as on a real oak, each leaf an English oak (Quercus robur) leaf about
  11 cm long: obovate, 4-6 rounded lobes a side with deep narrow sinuses,
  little ears at the base and almost no stalk, veins running out to the
  lobes. Tiles 4-7 are clumps (1 m across: many sprigs at half the scale),
  for the simpler versions further off. Transparent pixels carry the colour
  of the nearest leaf, so filtering doesn't darken the edges.
- oak_bark.png: RGBA, tileable, 0.6 m square: grey-brown ridges broken by
  deep vertical furrows; alpha is the height (the shader derives the bump).

python3 tools/trees/bake_oak_textures.py [--bark]  (--bark: only the bark)
"""
import math
import os

import numpy as np
from PIL import Image, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "population", "textures")
TILE = 512
SS = 2  # supersampling
rng = np.random.default_rng(7)


# ---- leaves -----------------------------------------------------------------

def leaf_halfwidth(s, lobes, phase, depth):
    """Half-width (in leaf lengths) at s (0 base .. 1 tip) of one side."""
    s = np.clip(s, 0.0, 1.0)
    env = 0.3 * np.maximum(np.sin(np.pi * s ** 0.8), 0.0) ** 0.7 * (0.45 + 0.75 * s)  # obovate: widest beyond the middle
    u = np.mod((s - 0.1) / 0.88 * lobes + phase, 1.0)
    dip = (0.5 + 0.5 * np.cos(2 * np.pi * u)) ** 2.5  # deep, rounded sinuses
    w = env * (1.0 - depth * dip * np.clip((s - 0.06) / 0.1, 0, 1))
    ear = 0.06 * np.maximum(np.sin(np.pi * np.clip(s / 0.09, 0, 1)), 0.0) ** 0.6  # auricles at the base
    return np.maximum(w, np.where(s < 0.09, ear, 0.0))


def draw_leaf(rgba, cover, x0, y0, ang, length, colour):
    """Paints one leaf into rgba over what's there."""
    h, w, _ = rgba.shape
    r = length * 0.62
    xa, xb = int(max(x0 - r - length, 0)), int(min(x0 + r + length, w))
    ya, yb = int(max(y0 - r - length, 0)), int(min(y0 + r + length, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    dx, dy = xx - x0, yy - y0
    ca, sa = math.cos(ang), math.sin(ang)
    along = (dx * ca + dy * sa) / length  # 0 at the base, 1 at the tip
    across = (-dx * sa + dy * ca) / length
    lobes = rng.uniform(3.8, 4.8)
    sides = [(-1, lobes, rng.uniform(0.0, 0.2), rng.uniform(0.55, 0.66)),
             (1, lobes + rng.uniform(-0.3, 0.3), rng.uniform(0.3, 0.5), rng.uniform(0.55, 0.66))]
    wl = leaf_halfwidth(along, *sides[0][1:])
    wr = leaf_halfwidth(along, *sides[1][1:])
    half = np.where(across < 0, wl, wr)
    inside = (along >= 0) & (along <= 1) & (np.abs(across) <= half)
    stalk = (along < 0) & (along > -0.05) & (np.abs(across) < 0.012)
    if not inside.any() and not stalk.any():
        return
    # colour: darker at the margin, lighter midrib and veins out to each lobe
    edge = np.clip(np.abs(across) / np.maximum(half, 1e-3), 0, 1)
    c = np.array(colour, np.float32)
    col = c[None, None, :] * (1.0 - 0.18 * edge[..., None] ** 3)
    vein_c = np.array([0.62, 0.7, 0.34], np.float32)
    midrib = np.abs(across) < 0.011 * (1.15 - along)
    veins = np.zeros_like(midrib)
    for side, lb, ph, dp in sides:
        for k in range(-1, int(lb) + 2):
            sk = 0.1 + (k + 0.5 - ph) / lb * 0.88  # a lobe's middle (u = 0.5)
            if sk <= 0.14 or sk >= 0.95:
                continue
            tip = np.array([sk + 0.02, side * 0.8 * float(leaf_halfwidth(np.array(sk), lb, ph, dp))])
            base = np.array([sk - 0.12, 0.0])
            seg = tip - base
            t = np.clip(((along - base[0]) * seg[0] + (across - base[1]) * seg[1]) / (seg @ seg), 0, 1)
            d = np.hypot(along - base[0] - t * seg[0], across - base[1] - t * seg[1])
            veins |= (d < 0.006) & ((across < 0) == (side < 0))
    mott = 1.0 + 0.06 * np.sin(xx * 0.21 + yy * 0.13) * np.sin(yy * 0.17 - xx * 0.07)
    col = col * mott[..., None]
    col = np.where((midrib | veins)[..., None] & inside[..., None], col * 0.55 + vein_c * 0.45, col)
    stalk_c = np.array([0.42, 0.4, 0.2], np.float32)
    paint = inside | stalk
    col = np.where(stalk[..., None], stalk_c, col)
    sub = rgba[ya:yb, xa:xb]
    sub[paint, :3] = col[paint]
    sub[paint, 3] = 1.0
    cover[ya:yb, xa:xb] |= paint


def draw_line(rgba, cover, p0, p1, w0, w1, colour):
    h, w, _ = rgba.shape
    xa = int(max(min(p0[0], p1[0]) - w0 - 2, 0)); xb = int(min(max(p0[0], p1[0]) + w0 + 2, w))
    ya = int(max(min(p0[1], p1[1]) - w0 - 2, 0)); yb = int(min(max(p0[1], p1[1]) + w0 + 2, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    seg = np.array(p1, np.float32) - np.array(p0, np.float32)
    t = np.clip(((xx - p0[0]) * seg[0] + (yy - p0[1]) * seg[1]) / max(seg @ seg, 1e-6), 0, 1)
    d = np.hypot(xx - p0[0] - t * seg[0], yy - p0[1] - t * seg[1])
    on = d < (w0 + (w1 - w0) * t)
    sub = rgba[ya:yb, xa:xb]
    shade = 1.0 - 0.35 * (d / np.maximum(w0 + (w1 - w0) * t, 1e-3))[..., None]
    sub[on, :3] = (np.array(colour, np.float32)[None, None, :] * shade)[on]
    sub[on, 3] = 1.0
    cover[ya:yb, xa:xb] |= on


def leaf_colour():
    g = rng.uniform(0.85, 1.12)
    return [0.2 * g * rng.uniform(0.9, 1.15), 0.33 * g, 0.11 * g * rng.uniform(0.8, 1.2)]


def cluster(rgba, cover, x, y, ang, spread, n, size):
    """Leaves radiating from a shoot tip at (x, y) round heading ang."""
    for i in rng.permutation(n):
        la = ang + (i / max(n - 1, 1) - 0.5) * spread + rng.uniform(-0.15, 0.15)
        draw_leaf(rgba, cover, x, y, la, rng.uniform(0.095, 0.125) * size, leaf_colour())


def sprig(rgba, cover, ox, oy, size, ang0):
    """A sprig: a twig from (ox, oy) heading ang0, 2-3 shoots, a cluster of
    leaves at each shoot's tip and a few along it. size: px per metre."""
    twig_c = [0.36, 0.28, 0.2]
    main_len = rng.uniform(0.15, 0.19) * size
    a = ang0 + rng.uniform(-0.12, 0.12)
    end = (ox + math.cos(a) * main_len, oy + math.sin(a) * main_len)
    draw_line(rgba, cover, (ox, oy), end, 0.006 * size, 0.0035 * size, twig_c)
    tips = [(end, a)]
    for k, side in enumerate(rng.permutation([-1, 1])[: rng.integers(1, 3)]):
        t = rng.uniform(0.3, 0.6)
        base = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        b = a + side * rng.uniform(0.6, 1.0)
        l = rng.uniform(0.08, 0.12) * size
        e = (base[0] + math.cos(b) * l, base[1] + math.sin(b) * l)
        draw_line(rgba, cover, base, e, 0.0035 * size, 0.0025 * size, twig_c)
        tips.append((e, b))
    for k in range(rng.integers(1, 3)):
        t = rng.uniform(0.2, 0.5)
        p = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        draw_leaf(rgba, cover, p[0], p[1], a + rng.choice([-1, 1]) * rng.uniform(0.7, 1.2), rng.uniform(0.08, 0.1) * size, leaf_colour())
    for (e, b) in tips:
        cluster(rgba, cover, e[0], e[1], b, rng.uniform(2.0, 2.6), int(rng.integers(5, 8)), size)


def bleed(rgba):
    """Fills transparent pixels with the colour of the nearest opaque one."""
    img = Image.fromarray((np.clip(rgba[..., :3], 0, 1) * 255).astype(np.uint8))
    mask = Image.fromarray((rgba[..., 3] > 0.5).astype(np.uint8) * 255)
    filled = img.copy()
    for r in (3, 7, 15, 31, 63):
        blur = img.filter(ImageFilter.GaussianBlur(r))
        m = mask.filter(ImageFilter.GaussianBlur(r))
        b = np.asarray(blur, np.float32) / np.maximum(np.asarray(m, np.float32)[..., None] / 255.0, 1e-3)
        cur = np.asarray(filled, np.float32)
        have = np.asarray(mask) > 0
        known = np.asarray(m) > 8
        cur = np.where((~have & known)[..., None], np.clip(b, 0, 255), cur)
        filled = Image.fromarray(cur.astype(np.uint8))
        mask = Image.fromarray(((have | known) * 255).astype(np.uint8))
    return np.asarray(filled, np.float32) / 255.0


def leaves():
    S = TILE * SS
    atlas = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cover = np.zeros((S, S), bool)
        if t < 4:
            # one sprig over 0.5 m: it enters at the bottom middle, heading up
            sprig(tile, cover, S * 0.5, S * 0.98, S / 0.5, -math.pi / 2)
        else:
            # a clump over 1 m: shoot tips' clusters all over a disc, the
            # leaves at the same size as on the sprigs
            for k in range(46):
                r = math.sqrt(rng.uniform(0, 1)) * 0.36
                a = rng.uniform(0, 2 * math.pi)
                x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
                cluster(tile, cover, x, y, rng.uniform(0, 2 * math.pi), rng.uniform(2.6, 4.0), int(rng.integers(5, 8)), S / 1.0)
        y, x = divmod(t, 4)
        atlas[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(atlas)
    out = np.concatenate([col, atlas[..., 3:4]], -1)
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, "oak_leaves.png"), optimize=True)


# ---- bark -------------------------------------------------------------------

def periodic_noise(n, beta, stretch=(1.0, 1.0), seed=0):
    """Tileable noise: white noise shaped in frequency (1/f^beta), anisotropic."""
    r = np.random.default_rng(seed)
    f = np.fft.fft2(r.standard_normal((n, n)))
    ky = np.fft.fftfreq(n)[:, None] * stretch[1]
    kx = np.fft.fftfreq(n)[None, :] * stretch[0]
    k = np.sqrt(kx * kx + ky * ky)
    k[0, 0] = 1.0
    g = np.real(np.fft.ifft2(f / k ** beta))
    g -= g.mean()
    return g / g.std()


def bark():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n] / n
    # vertical ridges (11 round the tile) that wander and fork, cut by deep
    # furrows; each ridge broken across into blocky plates
    warp = periodic_noise(n, 1.8, (1.0, 5.0), 3) * 0.45 + periodic_noise(n, 1.2, (1.0, 2.0), 4) * 0.12
    phase = xx * 11 + warp
    ridge = np.abs(np.sin(np.pi * phase))  # 1 on a ridge, 0 in a furrow
    ridge = np.clip((ridge - 0.18) / 0.82, 0, 1) ** 0.45
    cell = np.floor(phase).astype(int)
    breaks = periodic_noise(n, 1.0, (0.4, 3.0), 9)  # varies along y, per column of ridges
    jitter = np.sin(cell * 12.9898) * 43758.5453 % 1.0
    plate = np.abs(np.sin(np.pi * (yy * 7 + jitter + 0.15 * breaks)))
    plate = np.clip(plate / 0.25, 0, 1) ** 0.5  # thin dark cracks between the plates
    fine = periodic_noise(n, 0.6, (1.0, 2.0), 11)
    h = ridge * (0.55 + 0.45 * plate) * (0.85 + 0.15 * np.tanh(periodic_noise(n, 1.4, (1, 1), 5)))
    h = np.clip(h + 0.04 * fine, 0, None)
    h = (h - h.min()) / (h.max() - h.min())
    tone = 0.9 + 0.1 * periodic_noise(n, 1.5, (1, 1), 13)
    top = np.array([0.47, 0.44, 0.4])   # weathered grey on the ridges
    side = np.array([0.3, 0.26, 0.22])  # browner down the sides
    deep = np.array([0.08, 0.065, 0.05])
    col = np.where(h[..., None] > 0.5,
                   side + (top - side) * ((h[..., None] - 0.5) / 0.5),
                   deep + (side - deep) * (h[..., None] / 0.5) ** 0.8)
    col *= (tone * (1.0 + 0.08 * fine))[..., None]
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "oak_bark.png"), optimize=True)


if __name__ == "__main__":
    import sys
    os.makedirs(OUT, exist_ok=True)
    if "--bark" not in sys.argv:
        leaves()
    bark()
    print("baked", OUT)
