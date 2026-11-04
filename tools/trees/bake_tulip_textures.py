"""Bakes the tulip tree's textures (data/population/textures/), laid out as
the oak's (bake_oak_textures.py; TreeBuilder reads them the same):

- tulip_leaves.png: an RGBA atlas of 4 x 2 tiles, 512 px each. Tiles 0-3
  are sprigs (0.8 m across): a twig and, one by one up it, leaves on long
  slender stalks, each the tulip tree's own (Liriodendron tulipifera):
  four-lobed, two lobes each side, the tip cut off square across in a
  shallow notch, smooth-edged, 10-15 cm, bright green; now and then a
  flower held upright at the twig's end (a tulip-shaped cup, greenish
  yellow, a band of orange at its base) or last year's cone of seeds
  (upright, brown, narrow, its scales the samaras). Tiles 4-7 are clumps
  (1.6 m across). Transparent pixels carry the colour of the nearest leaf.
- tulip_bark.png: tileable, 0.6 m square: grey, in narrow rounded ridges
  that interlace (long diamonds), the furrows between them paler, not
  deep. Alpha the height.

python3 tools/trees/bake_tulip_textures.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, TILE, SS, bleed, draw_line, periodic_noise  # noqa: E402

rng = np.random.default_rng(97)

GREEN = [0.24, 0.42, 0.12]  # (a bright, fresh green)
VEIN = [0.6, 0.7, 0.36]
STALK = [0.45, 0.42, 0.2]
TWIG = [0.42, 0.33, 0.24]

# the leaf, about its middle (MID leaf lengths out from the stalk's end):
# lobes (angle off the midrib, reach, half-width in rad), the body between
MID = 0.45
LOBES = [(0.86, 0.68, 0.5), (-0.86, 0.68, 0.5), (2.05, 0.56, 0.52), (-2.05, 0.56, 0.52)]
BODY = 0.34


def outline(phi):
    """The leaf's radius (in leaf lengths, from its middle) the way phi
    points (0: the tip)."""
    r = np.full_like(phi, BODY)
    for a, l, w in LOBES:
        x = (phi - a) / w
        bump = np.clip(np.cos(np.clip(x, -1, 1) * math.pi / 2), 0, 1) ** 1.8 # (pointed)
        r = np.maximum(r, BODY + (l - BODY) * bump)
    # the tip cut off square across between the upper lobes, a shallow
    # notch in its middle; the base cut nearly square too, the stalk at
    # its middle
    cut = 0.47 * (1.0 - 0.1 * np.exp(-(phi / 0.14) ** 2))
    top = np.minimum(cut / np.maximum(np.cos(phi), 1e-3), 0.8) * (1.0 - np.clip((np.abs(phi) - 0.5) / 0.16, 0, 1))
    back = math.pi - np.abs(phi)
    base = np.minimum(MID / np.maximum(np.cos(back), 1e-3), 0.7) * (1.0 - np.clip((back - 0.62) / 0.2, 0, 1))
    return np.maximum(np.maximum(r, top), base)


def draw_leaf(rgba, cover, x0, y0, ang, length, colour):
    """A tulip tree's leaf, its stalk's end at (x0, y0), pointing ang,
    length px from the stalk's end to the tip."""
    h, w, _ = rgba.shape
    reach = length * 1.1
    xa, xb = int(max(x0 - reach, 0)), int(min(x0 + reach, w))
    ya, yb = int(max(y0 - reach, 0)), int(min(y0 + reach, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    dx, dy = xx - x0, yy - y0
    ca, sa = math.cos(ang), math.sin(ang)
    along = (dx * ca + dy * sa) / length
    across = (-dx * sa + dy * ca) / length
    ac = along - MID
    rho = np.hypot(ac, across)
    phi = np.arctan2(across, ac)
    r = outline(phi)
    inside = rho <= r
    if not inside.any():
        return
    c = np.array(colour, np.float32)
    col = c[None, None, :] * (1.0 - 0.14 * np.clip(rho / np.maximum(r, 1e-3), 0, 1)[..., None] ** 3)
    # the midrib, and veins out to each lobe and between
    # (from the stalk's end, out to each lobe and between)
    rs = np.hypot(along, across)
    ps = np.arctan2(across, along)
    veins = (np.abs(across) < 0.011 * (1.2 - along)) & (along > 0) & (along < 0.85)
    for a in [0.6, -0.6, 1.25, -1.25, 0.3, -0.3]:
        d = np.abs(np.sin(ps - a)) * rs
        veins |= (np.cos(ps - a) > 0) & (rs < 0.85) & (d < 0.006 * (1.2 - rs))
    mott = 1.0 + 0.05 * np.sin(xx * 0.21 + yy * 0.13) * np.sin(yy * 0.17 - xx * 0.07)
    col = col * mott[..., None]
    vein_c = np.array(VEIN, np.float32)
    col = np.where((veins & inside)[..., None], col * 0.55 + vein_c * 0.45, col)
    sub = rgba[ya:yb, xa:xb]
    sub[inside, :3] = col[inside]
    sub[inside, 3] = 1.0
    cover[ya:yb, xa:xb] |= inside


def leaf_colour():
    g = rng.uniform(0.86, 1.12)
    return [GREEN[0] * g * rng.uniform(0.9, 1.15), GREEN[1] * g, GREEN[2] * g * rng.uniform(0.8, 1.2)]


def stalked_leaf(rgba, cover, x, y, ang, stalk, length, stalk_w):
    ex, ey = x + math.cos(ang) * stalk, y + math.sin(ang) * stalk
    draw_line(rgba, cover, (x, y), (ex, ey), stalk_w, stalk_w * 0.8, STALK)
    draw_leaf(rgba, cover, ex, ey, ang + rng.uniform(-0.2, 0.2), length, leaf_colour())


def blob(rgba, cover, cx, cy, rx, ry, ang, colour, shade=0.3):
    """A filled ellipse, shaded toward its edge."""
    h, w, _ = rgba.shape
    r = max(rx, ry) + 2
    xa, xb = int(max(cx - r, 0)), int(min(cx + r, w))
    ya, yb = int(max(cy - r, 0)), int(min(cy + r, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    dx, dy = xx - cx, yy - cy
    ca, sa = math.cos(ang), math.sin(ang)
    u = (dx * ca + dy * sa) / rx
    v = (-dx * sa + dy * ca) / ry
    d = u * u + v * v
    on = d <= 1.0
    col = np.array(colour, np.float32)[None, None, :] * (1.0 - shade * d[..., None])
    sub = rgba[ya:yb, xa:xb]
    sub[on, :3] = col[on]
    sub[on, 3] = 1.0
    cover[ya:yb, xa:xb] |= on


def flower(rgba, cover, x, y, ang, size):
    """A tulip tree's flower, upright at (x, y) (its foot), facing ang (up):
    a cup of six petals, greenish yellow, a band of orange round the base."""
    s = 0.045 * size
    ca, sa = math.cos(ang), math.sin(ang)
    for k, off in enumerate([-0.55, 0.55, -0.22, 0.22, 0.0]):
        # the petals: overlapping ovals fanned in a cup
        px = x + ca * s * 0.55 + (-sa) * off * s * 0.9
        py = y + sa * s * 0.55 + ca * off * s * 0.9
        blob(rgba, cover, px, py, s * 0.62, s * 0.3, ang + off * 0.5, [0.78, 0.8, 0.4], 0.25)
        # the orange band low on each
        bx = x + ca * s * 0.3 + (-sa) * off * s * 0.8
        by = y + sa * s * 0.3 + ca * off * s * 0.8
        blob(rgba, cover, bx, by, s * 0.2, s * 0.24, ang, [0.9, 0.48, 0.12], 0.15)
    # the green sepals turned back at its foot
    for side in (-1, 1):
        blob(rgba, cover, x + (-sa) * side * s * 0.45, y + ca * side * s * 0.45, s * 0.35, s * 0.13, ang + side * 1.9, [0.4, 0.5, 0.22], 0.2)


def cone(rgba, cover, x, y, ang, size):
    """Last year's cone of seeds, upright: narrow, brown, scaly."""
    s = 0.06 * size
    ca, sa = math.cos(ang), math.sin(ang)
    n = 9
    for k in range(n):
        t = (k + 0.5) / n
        w = s * 0.2 * math.sin(math.pi * min(t * 1.2, 1.0)) + s * 0.04
        cx, cy = x + ca * s * t, y + sa * s * t
        for side in (-1, 1):
            blob(rgba, cover, cx + (-sa) * side * w * 0.5, cy + ca * side * w * 0.5, s * 0.1, w * 0.55, ang + side * 0.5,
                 [0.5 * rng.uniform(0.85, 1.1), 0.38, 0.22], 0.35)


def sprig(rgba, cover, ox, oy, size, ang0):
    """size: px per metre. A twig with alternate leaves on long stalks up
    it; now and then a flower or a cone of seeds at its end."""
    L = rng.uniform(0.2, 0.27) * size
    a = ang0 + rng.uniform(-0.1, 0.1)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    draw_line(rgba, cover, (ox, oy), end, 0.0022 * size, 0.0015 * size, TWIG)
    leaves = []
    side = rng.choice([-1, 1])
    for t in (0.3, 0.5, 0.7, 0.88):
        p = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        b = a + side * rng.uniform(0.8, 1.25)
        # (the upright ones shorter: the tile's top quarter is cropped off)
        up = abs(math.cos(b - ang0))
        leaves.append((p, b, rng.uniform(0.06, 0.09) * size * (1.0 - 0.3 * up), rng.uniform(0.09, 0.12) * size * (1.0 - 0.2 * up)))
        side = -side
    extra = rng.uniform()
    if extra < 0.3:
        flower(rgba, cover, end[0], end[1], a, size)
    elif extra < 0.5:
        cone(rgba, cover, end[0], end[1], a, size)
    else:
        leaves.append((end, a + rng.uniform(-0.2, 0.2), 0.05 * size, rng.uniform(0.08, 0.1) * size))
    for i in rng.permutation(len(leaves)):
        p, b, stalk, length = leaves[i]
        stalked_leaf(rgba, cover, p[0], p[1], b, stalk, length, 0.0009 * size)


def leaves(sprig_m=0.8, clump_m=1.6):
    S = TILE * SS
    atlas = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cov = np.zeros((S, S), bool)
        if t < 4:
            sprig(tile, cov, S * 0.5, S * 0.98, S / sprig_m, -math.pi / 2)
        else:
            size = S / clump_m
            for k in range(40):
                r = math.sqrt(rng.uniform(0, 1)) * 0.36
                a = rng.uniform(0, 2 * math.pi)
                x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
                for j in range(int(rng.integers(2, 4))):
                    stalked_leaf(tile, cov, x, y, rng.uniform(0, 2 * math.pi), 0.05 * size, rng.uniform(0.09, 0.12) * size, 0.001 * size)
        y, x = divmod(t, 4)
        atlas[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(atlas)
    out = np.concatenate([col, atlas[..., 3:4]], -1)
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, "tulip_leaves.png"), optimize=True)


def bark():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n] / n
    # narrow rounded ridges, two sets leaning a little apart, interlacing
    # into long diamonds (whole turns across the tile both ways: it tiles)
    warp = periodic_noise(n, 1.8, (1.0, 5.0), 71) * 0.3 + periodic_noise(n, 1.2, (1.0, 2.0), 72) * 0.1
    ra = np.abs(np.sin(np.pi * (xx * 11 + yy * 1 + warp)))
    rb = np.abs(np.sin(np.pi * (xx * 11 - yy * 1 + warp * 0.8 + 0.41)))
    ra = np.clip((ra - 0.55) / 0.45, 0, 1) ** 0.8
    rb = np.clip((rb - 0.55) / 0.45, 0, 1) ** 0.8
    ridge = np.maximum(ra, rb)
    fine = periodic_noise(n, 0.6, (1.0, 2.5), 73)
    h = ridge * 0.8 + 0.12 * fine * (0.4 + ridge) + 0.1
    h = (h - h.min()) / (h.max() - h.min())
    tone = 0.92 + 0.08 * periodic_noise(n, 1.5, (1, 1), 74)
    top = np.array([0.5, 0.49, 0.45])    # the ridges grey
    side = np.array([0.36, 0.35, 0.32])
    furrow = np.array([0.56, 0.54, 0.48])  # the furrows paler, not deep (the young bark's whitish streaks between)
    col = np.where(h[..., None] > 0.45,
                   side + (top - side) * ((h[..., None] - 0.45) / 0.55),
                   furrow + (side - furrow) * (h[..., None] / 0.45))
    col *= (tone * (1.0 + 0.06 * fine))[..., None]
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "tulip_bark.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    leaves()
    bark()
    print("baked", OUT)
