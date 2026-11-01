"""Bakes the ground cover's textures (data/population/textures/):

- fern_frond.png: RGBA, 256 x 1024, one frond of a bracken-like fern, base
  at the bottom: a pale rachis giving off pinnae in near-opposite pairs,
  longest a third of the way up and shrinking to the tip, gaps between
  them; each pinna the same plan again (a pale midrib, pinnules in pairs,
  shrinking to its tip), each pinnule shallowly lobed in its turn, darker
  along its vein and lighter toward its tip: three levels of the same shape,
  each pinna its own shade.
  Transparent pixels carry the nearest frond colour (no dark fringes).
- leaf_litter.png: RGB, 1024 x 1024, about 1.6 m square, tileable every
  way (each tile may be turned any quarter turn: the terrain turns them at
  random, so the repeat doesn't show): fallen
  oak leaves (lobed) and maple leaves (five-pointed), dun, russet, tan and
  dark, overlapping in layers, the lower ones shaded by those on top. The
  terrain multiplies its own litter colour by this over its mean, so the
  colour seen from afar doesn't change as the detail fades in.

python3 tools/ground/bake_ground_textures.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "population", "textures")
rng = np.random.default_rng(13)


# ---- fern -------------------------------------------------------------------

def frond(w=256, h=1024, ss=3):
    W, H = w * ss, h * ss
    mask = Image.new("L", (W, H), 0)
    dm = ImageDraw.Draw(mask)
    col = Image.new("RGB", (W, H), (0, 0, 0))
    dc = ImageDraw.Draw(col)
    base = np.array([W * 0.5, H * 0.995])
    tip = np.array([W * 0.5, H * 0.01])
    n_pinnae = 16
    leaf = np.array([44.0, 78.0, 22.0])     # a pinnule's green
    light = np.array([92.0, 128.0, 44.0])   # its tip, catching the light
    rib = np.array([120.0, 140.0, 64.0])    # the ribs, paler
    vein = np.array([30.0, 56.0, 16.0])

    def c(v):
        return tuple(int(x) for x in np.clip(v, 0, 255))

    def outline(p0, direction, side, length, width, lobes, t0=0.0):
        pts = []
        k = 20
        for sgn, ph in ((1, 0.0), (-1, 1.0)):
            rng_t = range(k + 1) if sgn == 1 else range(k, -1, -1)
            for i in rng_t:
                t = t0 + (1 - t0) * i / k
                half = width * 0.5 * math.sin(math.pi * t) ** 0.7 * (1.0 - 0.28 * (0.5 + 0.5 * math.cos(2 * math.pi * t * lobes + ph)))
                pts.append(tuple(p0 + direction * length * t + side * half * sgn))
        return pts

    def pinnule(p0, direction, length, width, shade):
        direction = direction / np.linalg.norm(direction)
        side = np.array([-direction[1], direction[0]])
        pts = outline(p0, direction, side, length, width, 3.5)
        dm.polygon(pts, fill=255)
        dc.polygon(pts, fill=c(leaf * shade))
        # the outer part lighter, the vein down its middle darker
        dc.polygon(outline(p0, direction, side, length, width * 0.9, 3.5, 0.5), fill=c((leaf * 0.4 + light * 0.6) * shade))
        dc.line([tuple(p0), tuple(p0 + direction * length * 0.85)], fill=c(vein * shade), width=max(int(width * 0.12), 1))

    def pinna(p0, direction, length, n):
        direction = direction / np.linalg.norm(direction)
        side = np.array([-direction[1], direction[0]])
        tone = rng.uniform(0.85, 1.15)  # each pinna a little its own shade
        for i in range(n):
            t = (i + 0.6) / n
            at = p0 + direction * length * t * 0.95
            sz = length * 0.2 * (1.0 - t * 0.65)
            for sgn in (-1, 1):
                dd = direction * 0.6 + side * sgn  # swept toward the pinna's tip
                pinnule(at, dd, sz, sz * 0.48, tone * rng.uniform(0.9, 1.1))
        dm.line([tuple(p0), tuple(p0 + direction * length)], fill=255, width=max(int(W * 0.006), 1))
        dc.line([tuple(p0), tuple(p0 + direction * length)], fill=c(rib * tone), width=max(int(W * 0.006), 1))

    for i in range(n_pinnae):
        t = 0.2 + 0.78 * (i + 0.5) / n_pinnae
        at = base + (tip - base) * t
        env = math.sin(math.pi * min((t - 0.12) / 0.95, 1.0)) ** 0.9  # longest a third of the way up
        length = W * 0.5 * env * (1.0 - 0.15 * t)
        for sgn in (-1, 1):
            p0 = at + np.array([0.0, sgn * H * 0.012])  # (alternate, not quite opposite)
            dd = np.array([sgn * 1.0, -0.3 - 0.35 * t])  # angled up toward the tip
            pinna(p0, dd, length, 11 if length > W * 0.2 else 6)
    # rachis on top: bare for the lowest fifth (the stipe)
    dm.line([tuple(base), tuple(tip)], fill=255, width=int(W * 0.014))
    dc.line([tuple(base), tuple(tip)], fill=c(rib * 0.9), width=int(W * 0.014))
    m = np.asarray(mask.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0
    # (the colour averaged over covered pixels only)
    cw = np.asarray(col, np.float32) * (np.asarray(mask, np.float32)[..., None] / 255)
    cw = np.asarray(Image.fromarray(cw.clip(0, 255).astype(np.uint8)).resize((w, h), Image.LANCZOS), np.float32)
    rgb = cw / np.maximum(m, 1e-3)[..., None]
    return _bleed(np.clip(rgb, 0, 255), m)


def _bleed(rgb, mask):
    """Spread the colour into the transparent pixels (no dark fringes)."""
    filled = mask > 0.02
    col = rgb * filled[..., None]
    for _ in range(40):
        acc = np.zeros_like(col)
        n = np.zeros(filled.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            acc += np.roll(col * filled[..., None], (dy, dx), (0, 1))
            n += np.roll(filled, (dy, dx), (0, 1))
        grow = (~filled) & (n > 0)
        col[grow] = acc[grow] / n[grow][:, None]
        filled = filled | grow
    return np.dstack([col, mask * 255]).clip(0, 255).astype(np.uint8)


# ---- leaf litter ------------------------------------------------------------

def oak_outline(n=80):
    pts = []
    lobes = rng.uniform(3.6, 4.6)
    for side in (1, -1):
        ts = np.linspace(0, 1, n) if side == 1 else np.linspace(1, 0, n)
        ph = rng.uniform(0, 0.4)
        for s in ts:
            env = 0.3 * max(math.sin(math.pi * s ** 0.8), 0.0) ** 0.7 * (0.45 + 0.75 * s)
            u = ((s - 0.1) / 0.88 * lobes + ph) % 1.0
            dip = (0.5 + 0.5 * math.cos(2 * math.pi * u)) ** 2.5
            wd = env * (1.0 - 0.6 * dip * min(max((s - 0.06) / 0.1, 0), 1))
            pts.append((s - 0.5, side * wd))
    return pts


def maple_outline(n=160):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        # five pointed lobes (the base one missing: a notch for the stalk)
        lobe = abs(math.cos(a * 2.5)) ** 0.55
        teeth = 0.04 * math.sin(a * 25.0)
        r = 0.22 + 0.28 * lobe + teeth
        notch = math.exp(-((math.atan2(math.sin(a - math.pi), math.cos(a - math.pi))) ** 2) / 0.06)
        r *= 1.0 - 0.6 * notch
        pts.append((math.cos(a) * r * 0.95, math.sin(a) * r))
    return pts


def _leaf(S, layer, ss):
    """One fallen leaf, oak or maple, drawn into its own square patch:
    (colour, coverage, shadow), each (P, P[, 3]). The shadow is soft and
    straight under it (no direction: the tile is turned every way)."""
    maple = rng.random() < 0.4
    length = S * (rng.uniform(0.05, 0.08) if maple else rng.uniform(0.055, 0.095))
    outline = maple_outline() if maple else oak_outline()
    ang = rng.uniform(0, 2 * math.pi)
    c = np.array(LITTER_PALETTE[rng.integers(len(LITTER_PALETTE))], dtype=np.float32) * rng.uniform(0.85, 1.12)
    c *= 0.78 + 0.28 * layer  # the top layers a little brighter
    ca, sa = math.cos(ang), math.sin(ang)
    r = int(length * 0.75) + 8
    P = 2 * r
    cx, cy = r, r
    pts = [(cx + (x * ca - y * sa) * length, cy + (x * sa + y * ca) * length) for x, y in outline]
    sh = Image.new("L", (P, P), 0)
    ImageDraw.Draw(sh).polygon(pts, fill=255)
    sh = np.asarray(sh.filter(ImageFilter.GaussianBlur(length * 0.05)), np.float32) / 255 * 0.45
    lf = Image.new("L", (P, P), 0)
    ImageDraw.Draw(lf).polygon(pts, fill=255)
    lf = np.asarray(lf, np.float32) / 255
    vn = Image.new("L", (P, P), 0)
    dv = ImageDraw.Draw(vn)
    if maple:
        for k in range(5):
            a = ang + math.pi + (k - 2) * 0.75
            dv.line([(cx, cy), (cx + math.cos(a) * length * 0.42, cy + math.sin(a) * length * 0.42)], fill=255, width=ss)
    else:
        dv.line([(cx - ca * length * 0.5, cy - sa * length * 0.5), (cx + ca * length * 0.5, cy + sa * length * 0.5)], fill=255, width=ss)
        for k in range(4):
            t = -0.3 + 0.18 * k
            bx, by = cx + ca * length * t, cy + sa * length * t
            for sgn in (-1, 1):
                a = ang + sgn * 0.9
                dv.line([(bx, by), (bx + math.cos(a) * length * 0.13, by + math.sin(a) * length * 0.13)], fill=255, width=max(ss // 2, 1))
    vn = np.asarray(vn, np.float32) / 255 * lf * 0.5
    spot = np.asarray(Image.fromarray((rng.uniform(0.85, 1.12, (8, 8)) * 120).astype(np.uint8)).resize((P, P), Image.BICUBIC), np.float32) / 120
    col = c[None, None, :] * spot[..., None] * (1 - vn[..., None] * 0.45)
    return col, lf, sh


def _paste(canvas, leaf, x0, y0, k):
    """Paints a leaf patch, turned k quarter turns (np.rot90), its top left
    corner at (x0, y0), clipped to the canvas (no wrapping)."""
    col, lf, sh = (np.rot90(a, k) for a in leaf)
    S = canvas.shape[0]
    P = lf.shape[0]
    xa, ya = max(x0, 0), max(y0, 0)
    xb, yb = min(x0 + P, S), min(y0 + P, S)
    if xa >= xb or ya >= yb:
        return
    reg = canvas[ya:yb, xa:xb]
    m = sh[ya - y0:yb - y0, xa - x0:xb - x0][..., None]
    reg = reg * (1 - m) + np.array([24, 18, 12], np.float32) * m
    m = lf[ya - y0:yb - y0, xa - x0:xb - x0][..., None]
    canvas[ya:yb, xa:xb] = reg * (1 - m) + col[ya - y0:yb - y0, xa - x0:xb - x0] * m


def _turn(x0, y0, P, S, k):
    """Where a patch at (x0, y0) goes when the tile turns k quarter turns
    (as np.rot90 turns an array: x' = y, y' = S - x)."""
    for _ in range(k % 4):
        x0, y0 = y0, S - x0 - P
    return x0, y0


LITTER_PALETTE = [(112, 82, 48), (128, 76, 40), (96, 70, 44), (140, 104, 62), (82, 58, 36), (118, 92, 52), (104, 64, 36)]


def litter(size=1024, ss=2):
    """Tileable every way: any tile can be turned any quarter turn next to any
    other. The leaves inside stay inside; the leaves across an edge are the
    same along all four edges, in pairs turned half round the edge's middle
    (so the half in this tile and the half in the next, however that one is
    turned, make whole leaves); the leaves across a corner are the same at
    all four, in fours turned round it."""
    S = size * ss
    canvas = np.array([62, 48, 32], np.float32)[None, None, :] * rng.uniform(0.8, 1.15, (S, S))[..., None]
    # first the leaves across the corners and the edges, the lowest layer,
    # then the leaves inside over them, right up to (not across) the edges:
    # all that's alike from edge to edge is what crosses them
    for n in range(30):  # across the corners
        leaf = _leaf(S, rng.uniform(0.2, 1.0), ss)
        P = leaf[1].shape[0]
        x0, y0 = int(rng.uniform(-P * 0.45, P * 0.45)) - P // 2, int(rng.uniform(-P * 0.45, P * 0.45)) - P // 2
        four = []
        for q in range(4):  # (turned round the corner: x' = y, y' = -x)
            four.append((x0, y0, q))
            x0, y0 = y0, -x0 - P
        for k in range(4):
            for fx, fy, q in four:
                tx, ty = _turn(fx, fy, P, S, k)
                _paste(canvas, leaf, tx, ty, q + k)
    for n in range(150):  # across the edges
        leaf = _leaf(S, rng.uniform(0.2, 1.0), ss)
        P = leaf[1].shape[0]
        cx, cy = rng.uniform(P * 0.5 + 2, S / 2), rng.uniform(-P * 0.3, P * 0.3)
        pair = [(int(cx) - P // 2, int(cy) - P // 2, 0)]
        pair.append((S - pair[0][0] - P, -pair[0][1] - P, 2))  # (turned half round the edge's middle)
        for k in range(4):
            for x0, y0, kk in pair:
                tx, ty = _turn(x0, y0, P, S, k)
                _paste(canvas, leaf, tx, ty, kk + k)
    count = 1100
    for n in range(count):  # inside
        leaf = _leaf(S, 0.2 + 0.8 * n / count, ss)
        P = leaf[1].shape[0]
        # anywhere the leaf itself (not its patch) stays inside the tile
        ys, xs = np.nonzero(leaf[1] > 0.01)
        x0 = int(rng.uniform(1 - xs.min(), S - 1 - xs.max()))
        y0 = int(rng.uniform(1 - ys.min(), S - 1 - ys.max()))
        _paste(canvas, leaf, x0, y0, 0)
    return Image.fromarray(canvas.clip(0, 255).astype(np.uint8)).reduce(ss)


def main():
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(frond(), "RGBA").save(os.path.join(OUT, "fern_frond.png"))
    print("fern_frond.png")
    litter().save(os.path.join(OUT, "leaf_litter.png"))
    print("leaf_litter.png")


if __name__ == "__main__":
    main()
