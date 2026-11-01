"""Bakes the ground cover's textures (data/population/textures/):

- fern_frond.png: RGBA, 256 x 1024, one frond of a bracken-like fern, base
  at the bottom: a rachis giving off pinnae in near-opposite pairs, longest
  a third of the way up and shrinking to the tip; each pinna the same plan
  again (a midrib, pinnules in pairs, shrinking to its tip), and each
  pinnule shallowly lobed in its turn: three levels of the same shape.
  Transparent pixels carry the nearest frond colour (no dark fringes).
- leaf_litter.png: RGB, 1024 x 1024, tileable, about 1.6 m square: fallen
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
    img = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(img)
    base = np.array([W * 0.5, H * 0.995])
    tip = np.array([W * 0.5, H * 0.01])
    n_pinnae = 22

    def lobed_blade(p0, direction, length, width, lobes, depth, recurse):
        """A blade along direction from p0: pinnules (recurse > 0) or lobes."""
        direction = direction / np.linalg.norm(direction)
        side = np.array([-direction[1], direction[0]])
        # midrib
        d.line([tuple(p0), tuple(p0 + direction * length)], fill=255, width=max(int(width * 0.12), 1))
        if recurse > 0:
            n = lobes
            for i in range(n):
                t = (i + 0.5) / n
                at = p0 + direction * length * t * 0.95
                sz = length * 0.27 * (1.0 - t * 0.7)
                for sgn in (-1, 1):
                    dd = direction * 0.45 + side * sgn  # swept toward the tip
                    lobed_blade(at, dd, sz, sz * 0.6, 4, depth, recurse - 1)
        else:
            # a pinnule: a narrow oval with shallow lobes round its edge
            pts = []
            k = 24
            for i in range(k + 1):
                t = i / k
                half = width * 0.5 * math.sin(math.pi * t) ** 0.8 * (1.0 - depth * 0.5 * (0.5 + 0.5 * math.cos(2 * math.pi * t * lobes)))
                pts.append(p0 + direction * length * t + side * half)
            for i in range(k, -1, -1):
                t = i / k
                half = width * 0.5 * math.sin(math.pi * t) ** 0.8 * (1.0 - depth * 0.5 * (0.5 + 0.5 * math.cos(2 * math.pi * t * lobes + 1.0)))
                pts.append(p0 + direction * length * t - side * half)
            d.polygon([tuple(p) for p in pts], fill=255)

    # rachis: bare for the lowest fifth (the stipe), then pinnae
    d.line([tuple(base), tuple(tip)], fill=255, width=int(W * 0.013))
    for i in range(n_pinnae):
        t = 0.2 + 0.78 * (i + 0.5) / n_pinnae
        at = base + (tip - base) * t
        env = math.sin(math.pi * min((t - 0.12) / 0.95, 1.0)) ** 0.9  # longest a third of the way up
        length = W * 0.5 * env * (1.0 - 0.15 * t)
        for sgn in (-1, 1):
            jitter = rng.uniform(-0.02, 0.02) * H
            p0 = at + np.array([0.0, jitter * 0.3 + sgn * H * 0.004])
            dd = np.array([sgn * 1.0, -0.22 - 0.3 * t])  # angled up toward the tip
            lobed_blade(p0, dd, length, length * 0.28, 12 if length > W * 0.2 else 7, 0.5, 1)
    mask = np.asarray(img.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0
    yy = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    # colour: deep green, lighter toward the tips of the pinnae (the edges),
    # yellower up the frond
    rnd = rng.uniform(0.92, 1.08, (h, w))
    g = np.stack([0.17 + 0.05 * (1 - yy), 0.28 + 0.04 * (1 - yy), 0.08 + 0.0 * yy], -1) * rnd[..., None]
    rgb = np.clip(g * 255, 0, 255)
    return _bleed(rgb, mask)


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


def _over(canvas, local, x0, y0, colour):
    """Blends colour into canvas through local (a float mask, 0..1) placed
    at (x0, y0), wrapping round the edges (the tile repeats)."""
    S = canvas.shape[0]
    h, w = local.shape
    for oy in (-S, 0, S):
        for ox in (-S, 0, S):
            xa, ya = x0 + ox, y0 + oy
            xb, yb = xa + w, ya + h
            cxa, cya, cxb, cyb = max(xa, 0), max(ya, 0), min(xb, S), min(yb, S)
            if cxa >= cxb or cya >= cyb:
                continue
            m = local[cya - ya:cyb - ya, cxa - xa:cxb - xa][..., None]
            region = canvas[cya:cyb, cxa:cxb]
            canvas[cya:cyb, cxa:cxb] = region * (1 - m) + colour * m


def litter(size=1024, ss=2):
    S = size * ss
    # soil and crumbs under it all
    noise = rng.uniform(0.7, 1.15, (size // 8, size // 8))
    noise = np.asarray(Image.fromarray((noise * 120).astype(np.uint8)).resize((S, S), Image.BICUBIC), dtype=np.float32) / 120
    canvas = np.array([62, 48, 32], np.float32)[None, None, :] * noise[..., None]
    palette = [(112, 82, 48), (128, 76, 40), (96, 70, 44), (140, 104, 62), (82, 58, 36), (118, 92, 52), (104, 64, 36)]
    count = 1300
    for k in range(count):
        layer = k / count
        maple = rng.random() < 0.4
        length = S * (rng.uniform(0.05, 0.08) if maple else rng.uniform(0.055, 0.095))
        outline = maple_outline() if maple else oak_outline()
        ang = rng.uniform(0, 2 * math.pi)
        c = np.array(palette[rng.integers(len(palette))], dtype=np.float32) * rng.uniform(0.85, 1.12)
        c *= 0.78 + 0.28 * layer  # the top layers a little brighter
        ca, sa = math.cos(ang), math.sin(ang)
        r = int(length * 0.75) + 8
        cx, cy = r, r
        pts = [(cx + (x * ca - y * sa) * length, cy + (x * sa + y * ca) * length) for x, y in outline]
        # its shadow on what's below (soft, offset), the leaf, its veins
        sh = Image.new("L", (2 * r, 2 * r), 0)
        ImageDraw.Draw(sh).polygon([(x + length * 0.04, y + length * 0.05) for x, y in pts], fill=255)
        sh = np.asarray(sh.filter(ImageFilter.GaussianBlur(length * 0.035)), np.float32) / 255 * 0.45
        lf = Image.new("L", (2 * r, 2 * r), 0)
        ImageDraw.Draw(lf).polygon(pts, fill=255)
        lf = np.asarray(lf, np.float32) / 255
        vn = Image.new("L", (2 * r, 2 * r), 0)
        dv = ImageDraw.Draw(vn)
        if maple:
            for j in range(5):
                a = ang + math.pi + (j - 2) * 0.75
                dv.line([(cx, cy), (cx + math.cos(a) * length * 0.42, cy + math.sin(a) * length * 0.42)], fill=255, width=ss)
        else:
            dv.line([(cx - ca * length * 0.5, cy - sa * length * 0.5), (cx + ca * length * 0.5, cy + sa * length * 0.5)], fill=255, width=ss)
            for j in range(4):
                t = -0.3 + 0.18 * j
                bx, by = cx + ca * length * t, cy + sa * length * t
                for sgn in (-1, 1):
                    a = ang + sgn * 0.9
                    dv.line([(bx, by), (bx + math.cos(a) * length * 0.13, by + math.sin(a) * length * 0.13)], fill=255, width=max(ss // 2, 1))
        vn = np.asarray(vn, np.float32) / 255 * lf * 0.5
        x0, y0 = int(rng.uniform(0, S)) - r, int(rng.uniform(0, S)) - r
        _over(canvas, sh, x0, y0, np.array([24, 18, 12], np.float32))
        # a little mottling on each leaf
        spot = np.asarray(Image.fromarray((rng.uniform(0.85, 1.12, (8, 8)) * 120).astype(np.uint8)).resize((2 * r, 2 * r), Image.BICUBIC), np.float32) / 120
        leaf_c = c[None, None, :] * spot[..., None]
        S_ = canvas.shape[0]
        # (leaf colour varies per pixel: blend region by region)
        for oy in (-S_, 0, S_):
            for ox in (-S_, 0, S_):
                xa, ya = x0 + ox, y0 + oy
                cxa, cya, cxb, cyb = max(xa, 0), max(ya, 0), min(xa + 2 * r, S_), min(ya + 2 * r, S_)
                if cxa >= cxb or cya >= cyb:
                    continue
                m = lf[cya - ya:cyb - ya, cxa - xa:cxb - xa][..., None]
                v = vn[cya - ya:cyb - ya, cxa - xa:cxb - xa][..., None]
                col = leaf_c[cya - ya:cyb - ya, cxa - xa:cxb - xa] * (1 - v * 0.45)
                canvas[cya:cyb, cxa:cxb] = canvas[cya:cyb, cxa:cxb] * (1 - m) + col * m
    out = Image.fromarray(canvas.clip(0, 255).astype(np.uint8)).resize((size, size), Image.LANCZOS)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(frond(), "RGBA").save(os.path.join(OUT, "fern_frond.png"))
    print("fern_frond.png")
    litter().save(os.path.join(OUT, "leaf_litter.png"))
    print("leaf_litter.png")


if __name__ == "__main__":
    main()
