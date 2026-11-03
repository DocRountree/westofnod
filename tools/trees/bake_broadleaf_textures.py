"""Bakes the maple's and the sycamore's textures (data/population/textures/),
laid out as the oak's (bake_oak_textures.py; TreeBuilder reads them the same):

- maple_leaves.png, sycamore_leaves.png: RGBA atlases of 4 x 2 tiles, 512 px
  each. Tiles 0-3 are sprigs, tiles 4-7 clumps (many leaves at the same
  scale, for the simpler versions further off). Transparent pixels carry the
  colour of the nearest leaf.
  - Sugar maple (Acer saccharum): a sprig 0.5 m across, a twig with leaves in
    opposite pairs on long stalks, a pair and one more at its tip; the leaves
    8-13 cm, palmate, five-lobed (the two at the base small), the sinuses
    rounded, a few big blunt-pointed teeth, the veins running out from the
    stalk to each lobe. Clumps 1 m across.
  - American sycamore (Platanus occidentalis): a sprig 0.65 m across, a
    zigzag twig with big leaves one by one on stout stalks, and now and then
    a seed ball hanging on its long thread; the leaves 14-20 cm, broader than
    long, shallowly three- to five-lobed, coarsely and unevenly toothed, the
    base cut nearly straight across, a lighter yellow-green. Clumps 1.3 m.
- maple_bark.png: tileable, 0.6 m square: grey, in long, narrow vertical
  plates loosening at their edges, shallow furrows between. Alpha the height.
- sycamore_bark.png: tileable: smooth, peeling in thin plates into a
  patchwork of cream-white, pale grey-green, tan and light brown, each
  layer a little lower than the one over it. Alpha the height.

python3 tools/trees/bake_broadleaf_textures.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from bake_oak_textures import OUT, TILE, SS, bleed, draw_line, periodic_noise  # noqa: E402

rng = np.random.default_rng(17)


# ---- leaves -----------------------------------------------------------------

# a species' leaf: lobes (angle off the midrib, length, half-width in rad),
# the body's radius between them, the teeth (count round, depth), the
# base's radius at the stalk
MAPLE = {
    "lobes": [(0.0, 1.0, 0.52), (1.0, 0.88, 0.5), (-1.0, 0.88, 0.5), (1.95, 0.45, 0.42), (-1.95, 0.45, 0.42)],
    "body": 0.36, "teeth": 20, "tooth": 0.1, "base": 0.17, "lobe_power": 0.75,
    "green": [0.19, 0.34, 0.1], "vein": [0.55, 0.66, 0.3],
}
SYCAMORE = {
    "lobes": [(0.0, 1.0, 0.55), (1.1, 0.9, 0.55), (-1.1, 0.9, 0.55), (2.05, 0.55, 0.5), (-2.05, 0.55, 0.5)],
    "body": 0.52, "teeth": 28, "tooth": 0.09, "base": 0.42, "lobe_power": 1.3,
    "green": [0.3, 0.44, 0.15], "vein": [0.66, 0.72, 0.42],
}


def outline(phi, sp, wob):
    """The leaf's radius (in leaf lengths) the way phi points (0: the tip)."""
    r = np.full_like(phi, sp["body"])
    # the base, round the stalk (phi near +-pi)
    back = np.abs(phi) > 2.3
    r = np.where(back, np.minimum(r, sp["base"] + (sp["body"] - sp["base"]) * np.clip((math.pi - np.abs(phi)) / (math.pi - 2.3), 0, 1)), r)
    for a, l, w in sp["lobes"]:
        x = (phi - a) / w
        bump = np.clip(np.cos(np.clip(x, -1, 1) * math.pi / 2), 0, 1) ** sp["lobe_power"]
        r = np.maximum(r, sp["body"] + (l - sp["body"]) * bump)
    # teeth: a sawtooth round the margin (uneven), not in the sinuses' depths
    t = np.mod(phi * sp["teeth"] / (2 * math.pi) + wob * np.sin(phi * 3.1 + 1.0), 1.0)
    saw = (1.0 - t) ** 2.2
    deep = np.clip((r - sp["body"] * 0.95) / max(1.0 - sp["body"], 1e-3), 0, 1)
    return r * (1.0 + sp["tooth"] * saw * (0.35 + 0.65 * deep) - sp["tooth"] * 0.3)


def draw_palmate(rgba, cover, x0, y0, ang, length, sp, colour):
    """A palmate leaf, its stalk's end at (x0, y0), pointing ang, length px
    from the stalk's end to the middle lobe's tip."""
    h, w, _ = rgba.shape
    reach = length * 1.15
    xa, xb = int(max(x0 - reach, 0)), int(min(x0 + reach, w))
    ya, yb = int(max(y0 - reach, 0)), int(min(y0 + reach, h))
    if xa >= xb or ya >= yb:
        return
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    dx, dy = xx - x0, yy - y0
    ca, sa = math.cos(ang), math.sin(ang)
    along = (dx * ca + dy * sa) / length
    across = (-dx * sa + dy * ca) / length
    rho = np.hypot(along, across)
    phi = np.arctan2(across, along)
    wob = rng.uniform(0.05, 0.15)
    r = outline(phi, sp, wob)
    inside = rho <= r
    if not inside.any():
        return
    # colour: darker toward the margin, lighter veins from the stalk out to each lobe
    c = np.array(colour, np.float32)
    col = c[None, None, :] * (1.0 - 0.16 * np.clip(rho / np.maximum(r, 1e-3), 0, 1)[..., None] ** 3)
    veins = np.zeros(inside.shape, bool)
    for a, l, _w in sp["lobes"]:
        d = np.abs(np.sin(phi - a)) * rho
        on = (np.cos(phi - a) > 0) & (rho < l * 0.92) & (d < 0.012 * (1.2 - rho / max(l, 1e-3)))
        veins |= on
        # side veins off each main one, every so often
        for k in range(1, 4):
            s = l * k / 4.2
            px, py = s * math.cos(a), s * math.sin(a)
            for side in (-1, 1):
                b = a + side * 0.75
                qx, qy = px + 0.22 * l * math.cos(b), py + 0.22 * l * math.sin(b)
                sx, sy = qx - px, qy - py
                t = np.clip(((along - px) * sx + (across - py) * sy) / (sx * sx + sy * sy), 0, 1)
                dd = np.hypot(along - px - t * sx, across - py - t * sy)
                veins |= dd < 0.005
    vein_c = np.array(sp["vein"], np.float32)
    mott = 1.0 + 0.06 * np.sin(xx * 0.21 + yy * 0.13) * np.sin(yy * 0.17 - xx * 0.07)
    col = col * mott[..., None]
    col = np.where((veins & inside)[..., None], col * 0.55 + vein_c * 0.45, col)
    sub = rgba[ya:yb, xa:xb]
    sub[inside, :3] = col[inside]
    sub[inside, 3] = 1.0
    cover[ya:yb, xa:xb] |= inside


def leaf_colour(sp):
    g = rng.uniform(0.86, 1.12)
    c = sp["green"]
    return [c[0] * g * rng.uniform(0.9, 1.12), c[1] * g, c[2] * g * rng.uniform(0.8, 1.2)]


def stalked_leaf(rgba, cover, x, y, ang, stalk, length, sp, stalk_w):
    """A leaf on its stalk from (x, y), heading ang."""
    ex, ey = x + math.cos(ang) * stalk, y + math.sin(ang) * stalk
    draw_line(rgba, cover, (x, y), (ex, ey), stalk_w, stalk_w * 0.8, [0.42, 0.38, 0.2])
    draw_palmate(rgba, cover, ex, ey, ang + rng.uniform(-0.15, 0.15), length, sp, leaf_colour(sp))


def maple_sprig(rgba, cover, ox, oy, size, ang0):
    """size: px per metre. A twig with opposite pairs of leaves on long stalks."""
    twig_c = [0.4, 0.3, 0.22]
    L = rng.uniform(0.2, 0.26) * size
    a = ang0 + rng.uniform(-0.1, 0.1)
    end = (ox + math.cos(a) * L, oy + math.sin(a) * L)
    draw_line(rgba, cover, (ox, oy), end, 0.0018 * size, 0.0011 * size, twig_c)
    leaves = []
    for t in (0.35, 0.68):
        p = (ox + (end[0] - ox) * t, oy + (end[1] - oy) * t)
        turn = rng.uniform(0.9, 1.25)
        for side in (-1, 1):
            leaves.append((p, a + side * turn, rng.uniform(0.05, 0.075) * size, rng.uniform(0.085, 0.115) * size))
    for side in (-1, 1):
        leaves.append((end, a + side * rng.uniform(0.5, 0.75), rng.uniform(0.04, 0.06) * size, rng.uniform(0.09, 0.12) * size))
    leaves.append((end, a + rng.uniform(-0.1, 0.1), rng.uniform(0.035, 0.05) * size, rng.uniform(0.1, 0.13) * size))
    for i in rng.permutation(len(leaves)):
        p, b, stalk, length = leaves[i]
        stalked_leaf(rgba, cover, p[0], p[1], b, stalk, length, MAPLE, 0.0009 * size)


def seed_ball(rgba, cover, x, y, ang, size):
    """A sycamore's seed ball on its long thread from (x, y), hanging toward ang."""
    l = rng.uniform(0.08, 0.13) * size
    ex, ey = x + math.cos(ang) * l, y + math.sin(ang) * l
    draw_line(rgba, cover, (x, y), (ex, ey), 0.0008 * size, 0.0007 * size, [0.38, 0.32, 0.22])
    r = rng.uniform(0.012, 0.015) * size
    h, w, _ = rgba.shape
    xa, xb = int(max(ex - r - 2, 0)), int(min(ex + r + 2, w))
    ya, yb = int(max(ey - r - 2, 0)), int(min(ey + r + 2, h))
    yy, xx = np.mgrid[ya:yb, xa:xb].astype(np.float32)
    d = np.hypot(xx - ex, yy - ey) / r
    on = d <= 1.0
    bumps = 0.9 + 0.1 * np.sin(xx * 1.7) * np.sin(yy * 1.9)
    shade = (1.0 - 0.35 * d ** 2) * bumps
    c = np.array([0.42, 0.36, 0.2], np.float32)
    sub = rgba[ya:yb, xa:xb]
    sub[on, :3] = (c[None, None, :] * shade[..., None])[on]
    sub[on, 3] = 1.0
    cover[ya:yb, xa:xb] |= on


def sycamore_sprig(rgba, cover, ox, oy, size, ang0):
    """A zigzag twig with big leaves one by one on stout stalks, maybe a seed ball."""
    twig_c = [0.46, 0.38, 0.26]
    a = ang0
    # a bare stretch first, so the lowest leaf's in the tile
    p = (ox + math.cos(ang0) * 0.1 * size, oy + math.sin(ang0) * 0.1 * size)
    draw_line(rgba, cover, (ox, oy), p, 0.0024 * size, 0.0022 * size, twig_c)
    side = rng.choice([-1, 1])
    n = int(rng.integers(3, 5))
    leaves = []
    for k in range(n):
        seg = rng.uniform(0.05, 0.075) * size
        a = ang0 + side * rng.uniform(0.12, 0.25)  # (zigzag: the twig bends at each leaf)
        q = (p[0] + math.cos(a) * seg, p[1] + math.sin(a) * seg)
        draw_line(rgba, cover, p, q, 0.0022 * size * (1.0 - 0.15 * k), 0.0018 * size * (1.0 - 0.15 * k), twig_c)
        last = k == n - 1
        b = a + (0.0 if last else side * rng.uniform(0.45, 0.8))
        leaves.append((q, b, rng.uniform(0.035, 0.06) * size, rng.uniform(0.13, 0.19) * size))
        side = -side
        p = q
    if rng.uniform() < 0.6:
        leaves.insert(0, ("ball", p, ang0 + math.pi + rng.uniform(-0.5, 0.5)))
    for item in leaves:
        if item[0] == "ball":
            seed_ball(rgba, cover, item[1][0], item[1][1], item[2], size)
    for item in leaves[::-1]:
        if item[0] != "ball":
            q, b, stalk, length = item
            stalked_leaf(rgba, cover, q[0], q[1], b, stalk, length, SYCAMORE, 0.0013 * size)


def leaves(name, sprig, sp, sprig_m, clump_m, clump_n):
    S = TILE * SS
    atlas = np.zeros((2 * S, 4 * S, 4), np.float32)
    for t in range(8):
        tile = np.zeros((S, S, 4), np.float32)
        cover = np.zeros((S, S), bool)
        if t < 4:
            sprig(tile, cover, S * 0.5, S * 0.98, S / sprig_m, -math.pi / 2)
        else:
            size = S / clump_m
            for k in range(clump_n):
                r = math.sqrt(rng.uniform(0, 1)) * 0.36
                a = rng.uniform(0, 2 * math.pi)
                x, y = S * (0.5 + math.cos(a) * r), S * (0.5 + math.sin(a) * r)
                for j in range(int(rng.integers(2, 4))):
                    b = rng.uniform(0, 2 * math.pi)
                    stalked_leaf(tile, cover, x, y, b, 0.03 * size, rng.uniform(0.09, 0.13 if sp is MAPLE else 0.18) * size, sp, 0.001 * size)
        y, x = divmod(t, 4)
        atlas[y * S:(y + 1) * S, x * S:(x + 1) * S] = tile
    col = bleed(atlas)
    out = np.concatenate([col, atlas[..., 3:4]], -1)
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    img = img.resize((4 * TILE, 2 * TILE), Image.LANCZOS)
    img.save(os.path.join(OUT, name), optimize=True)


# ---- bark -------------------------------------------------------------------

def maple_bark():
    n = 512
    yy, xx = np.mgrid[0:n, 0:n] / n
    # long, narrow vertical plates (8 round the tile), wandering, broken
    # across now and then; shallow furrows; the plates' edges loosening
    warp = periodic_noise(n, 1.8, (1.0, 6.0), 21) * 0.4 + periodic_noise(n, 1.2, (1.0, 2.0), 22) * 0.1
    phase = xx * 8 + warp
    ridge = np.abs(np.sin(np.pi * phase))
    ridge = np.clip((ridge - 0.28) / 0.72, 0, 1) ** 0.4  # (flat plates, furrows between)
    cell = np.floor(phase).astype(int)
    jitter = np.sin(cell * 12.9898) * 43758.5453 % 1.0
    breaks = periodic_noise(n, 1.0, (0.4, 3.0), 23)
    plate = np.abs(np.sin(np.pi * (yy * 3 + jitter + 0.2 * breaks)))
    plate = np.clip(plate / 0.12, 0, 1) ** 0.5
    edge = np.clip(1.0 - np.abs(np.sin(np.pi * phase)) / 0.35, 0, 1)  # (the plate's edges lifting)
    fine = periodic_noise(n, 0.6, (1.0, 2.5), 24)
    h = ridge * (0.7 + 0.3 * plate) + 0.12 * edge * ridge + 0.04 * fine
    h = (h - h.min()) / (h.max() - h.min())
    tone = 0.9 + 0.1 * periodic_noise(n, 1.5, (1, 1), 25)
    top = np.array([0.56, 0.55, 0.52])   # grey plates
    side = np.array([0.38, 0.36, 0.33])
    deep = np.array([0.13, 0.12, 0.1])
    col = np.where(h[..., None] > 0.45,
                   side + (top - side) * ((h[..., None] - 0.45) / 0.55),
                   deep + (side - deep) * (h[..., None] / 0.45) ** 0.8)
    col *= (tone * (1.0 + 0.07 * fine))[..., None]
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "maple_bark.png"), optimize=True)


def band_noise(n, cycles, seed, stretch=(1.0, 1.0)):
    """Tileable noise of one scale: about `cycles` blobs round the tile;
    stretch (x, y) > 1 that many times more of them that way (narrower)."""
    r = np.random.default_rng(seed)
    f = np.fft.fft2(r.standard_normal((n, n)))
    ky = np.fft.fftfreq(n)[:, None] * n / stretch[1]
    kx = np.fft.fftfreq(n)[None, :] * n / stretch[0]
    k = np.sqrt(kx * kx + ky * ky)
    g = np.real(np.fft.ifft2(f * np.exp(-((k - cycles) / (cycles * 0.75)) ** 2)))
    g -= g.mean()
    return g / g.std()


def sycamore_bark():
    n = 512
    # layers of bark, each peeled away in patches showing the one under it:
    # the outer brown-grey, then tan, grey-green, and the newest cream-white
    colours = [np.array(c) for c in ([0.5, 0.43, 0.34], [0.66, 0.56, 0.42], [0.64, 0.66, 0.56], [0.86, 0.85, 0.77])]
    col = np.zeros((n, n, 3)) + colours[0]
    h = np.full((n, n), 0.75)
    for i, c in enumerate(colours[1:]):
        # plates a few cm to 15 cm across, smooth-edged, a little taller than wide
        f = band_noise(n, [4.0, 6.0, 8.0][i], 31 + i, (1.3, 1.0)) + 0.22 * band_noise(n, 22.0, 41 + i)
        thr = [0.2, 0.0, -0.35][i]  # (more of each newer layer showing)
        peeled = f > thr
        soft = np.clip((f - thr) / 0.06, 0, 1)
        col = col * (1 - soft[..., None]) + c * soft[..., None]
        h = np.where(peeled, h - 0.12, h)
        # a thin, darker rim round each peeled patch (the edge of the plate over it)
        rim = np.clip(1.0 - np.abs(f - thr) / 0.05, 0, 1)
        col *= (1.0 - 0.18 * rim)[..., None]
        h += 0.05 * rim
    fine = periodic_noise(n, 0.7, (1, 1.5), 51)
    tone = 0.93 + 0.07 * periodic_noise(n, 1.4, (1, 1), 52)
    col *= (tone * (1.0 + 0.04 * fine))[..., None]
    h = h + 0.03 * fine
    h = (h - h.min()) / (h.max() - h.min())
    out = np.concatenate([np.clip(col, 0, 1), h[..., None]], -1)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "sycamore_bark.png"), optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    leaves("maple_leaves.png", maple_sprig, MAPLE, 0.5, 1.0, 40)
    leaves("sycamore_leaves.png", sycamore_sprig, SYCAMORE, 0.65, 1.3, 30)
    maple_bark()
    sycamore_bark()
    print("baked", OUT)
