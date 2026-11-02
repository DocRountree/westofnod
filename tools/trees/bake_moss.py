"""Bakes data/population/textures/moss.png: moss on bark (the stumps and
logs), tileable, 0.3 m across (half a repeat of the bark texture round a
trunk: TreeBuilder.bark_tile, so it wraps round seamlessly), for the bark
shader (lichen.gdshaderinc: moss_cover), one texture read.

Drawn as a haircap moss cushion grows, seen from above:
- an understory of little leafy shoots, each a star of narrow leaves a few
  mm long, packed close: the low ones dark, the tall ones lighter and
  yellower, some with pale hair-points at their leaf tips;
- a sparse canopy over it of sporophytes: thin red-orange stalks leaning
  every way, each with a purple-brown capsule at its end; in a texture of
  their own (moss_canopy.png: RGB the colour, A where they are), so the
  shader can sway them over the shoots.
moss.png's channels:
  RGB  the colour (sRGB)
  A    how high it stands: 0.04 the gaps down to the bark .. 1 the
       capsules (never 0: an importer may drop the colour of clear pixels).
       The shader shows the moss where it's taller than a threshold, so
       thin moss is a few tufts and the capsules, not a green wash.

python3 tools/trees/bake_moss.py
"""

import os

import numpy as np
from PIL import Image

W = 512                   # the texture (0.3 x 0.3 m)
SS = 2                    # drawn at twice that, then reduced
N = W * SS
PX_MM = N / 300.0         # drawing pixels per mm
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "population", "textures", "moss.png")
OUT_CANOPY = os.path.join(os.path.dirname(__file__), "..", "..", "data", "population", "textures", "moss_canopy.png")

rng = np.random.default_rng(31)


def srgb(*c):
    return np.array(c, dtype=np.float32)


GAP = srgb(0.08, 0.08, 0.04)
DEEP = srgb(0.11, 0.2, 0.06)
MID = srgb(0.22, 0.34, 0.09)
LIGHT = srgb(0.4, 0.48, 0.13)
HAIR = srgb(0.66, 0.66, 0.5)
STALK = srgb(0.6, 0.2, 0.09)
STALK_DARK = srgb(0.36, 0.1, 0.06)
CAPSULE = srgb(0.3, 0.15, 0.3)
CAPSULE_LIGHT = srgb(0.52, 0.38, 0.56)


class Canvas:
    """Colour and height; a stamp shows where it's at least as high as what's
    there (later stamps at the same height win). Wraps round (tiles)."""

    def __init__(self):
        self.xs, self.ys, self.hs, self.cs = [], [], [], []

    def stamp(self, x, y, h, c):
        self.xs.append(np.asarray(x, np.float32).ravel())
        self.ys.append(np.asarray(y, np.float32).ravel())
        self.hs.append(np.asarray(h, np.float32).ravel())
        self.cs.append(np.asarray(c, np.float32).reshape(-1, 3))

    def render(self, bg=GAP):
        x = np.concatenate(self.xs)
        y = np.concatenate(self.ys)
        h = np.concatenate(self.hs)
        c = np.concatenate(self.cs)
        order = np.argsort(h, kind="stable")
        xi = np.floor(x[order]).astype(np.int64) % N
        yi = np.floor(y[order]).astype(np.int64) % N
        rgb = np.empty((N, N, 3), np.float32)
        rgb[:] = bg
        hh = np.zeros((N, N), np.float32)
        flat = yi * N + xi
        # (numpy: of repeated indices the last assignment stands; sorted by
        # height, that's the highest)
        rgb.reshape(-1, 3)[flat] = c[order]
        hh.reshape(-1)[flat] = h[order]
        return rgb, hh


def shoots(cv, n, h_range, size_mm, light_share, hair_share):
    """n leafy shoots: stars of 6-8 narrow leaves."""
    S = 14                                          # points along a leaf
    K = 7                                           # leaves (some cut short)
    cx = rng.uniform(0, N, n)
    cy = rng.uniform(0, N, n)
    h0 = rng.uniform(*h_range, n)
    reach = rng.uniform(*size_mm, n) * PX_MM
    spin = rng.uniform(0, 2 * np.pi, n)
    # each shoot's green: dark to light (the taller the lighter, a little)
    tone = np.clip(rng.uniform(0, 1, n) * (1 - light_share) + light_share * (h0 - h_range[0]) / (h_range[1] - h_range[0] + 1e-6), 0, 1)
    base = np.where(tone[:, None] < 0.5, DEEP + (MID - DEEP) * (tone[:, None] * 2), MID + (LIGHT - MID) * (tone[:, None] * 2 - 1))
    base *= rng.uniform(0.85, 1.12, (n, 1))
    hairy = rng.uniform(0, 1, n) < hair_share
    k = np.arange(K)
    a = spin[:, None] + k[None, :] * (2 * np.pi / K) + rng.uniform(-0.3, 0.3, (n, K))      # (n, K)
    ln = reach[:, None] * rng.uniform(0.6, 1.0, (n, K))
    t = np.linspace(0, 1, S)
    for w in (-0.6, 0.0, 0.6):                      # (a leaf ~1.2 px wide, narrowing)
        off = w * (1.0 - 0.7 * t)                   # (S,)
        ca, sa = np.cos(a)[..., None], np.sin(a)[..., None]
        x = cx[:, None, None] + ca * ln[..., None] * t - sa * off
        y = cy[:, None, None] + sa * ln[..., None] * t + ca * off
        h = h0[:, None, None] * (1.0 - 0.4 * t) * np.ones((1, K, 1))
        shade = (0.72 + 0.28 * (1.0 - t))[None, None, :, None]                         # (darker out at the tips: they arch down)
        col = base[:, None, None, :] * shade * (1.0 + 0.15 * (w == 0.0))
        tip = (t > 0.78)[None, None, :, None] & hairy[:, None, None, None]
        col = np.where(tip, HAIR * rng.uniform(0.85, 1.05), col)
        cv.stamp(x, y, h, np.broadcast_to(col, x.shape + (3,)))
    # the shoot's middle, the highest
    cv.stamp(cx, cy, h0 + 0.01, base * 1.1)


def sporophytes(cv, n):
    """n stalks, leaning every way, a capsule at each one's end."""
    for _ in range(n):
        x0, y0 = rng.uniform(0, N, 2)
        a = rng.uniform(0, 2 * np.pi)
        ln = rng.uniform(5, 16) * PX_MM
        bend = rng.uniform(-0.25, 0.25)
        t = np.linspace(0, 1, int(ln * 2))
        ang = a + bend * t
        x = x0 + np.cumsum(np.cos(ang)) * (ln / len(t))
        y = y0 + np.cumsum(np.sin(ang)) * (ln / len(t))
        h = 0.86 + 0.08 * t
        col = STALK_DARK + (STALK - STALK_DARK) * t[:, None] * rng.uniform(0.8, 1.1)
        for w in (-0.7, 0.0, 0.7):
            cv.stamp(x + np.cos(a + 1.57) * w, y + np.sin(a + 1.57) * w, h, col)
        # the capsule: a slim oval along the stalk's last way, lit along one side
        e = ang[-1]
        L, R = rng.uniform(1.4, 2.0) * PX_MM, rng.uniform(0.6, 0.85) * PX_MM
        u, v = np.meshgrid(np.linspace(-1, 1, 31), np.linspace(-1, 1, 17))
        inside = u * u + v * v <= 1.0
        u, v = u[inside], v[inside]
        cxp, cyp = x[-1] + np.cos(e) * L, y[-1] + np.sin(e) * L
        px = cxp + np.cos(e) * u * L - np.sin(e) * v * R
        py = cyp + np.sin(e) * u * L + np.cos(e) * v * R
        lit = np.clip(0.5 - 0.5 * v - 0.2 * u, 0, 1)[:, None]
        col = CAPSULE + (CAPSULE_LIGHT - CAPSULE) * lit ** 2
        cv.stamp(px, py, 0.95 + 0.05 * (1 - u * u - v * v), col * rng.uniform(0.85, 1.1))


def main():
    cv = Canvas()
    shoots(cv, 16000, (0.12, 0.45), (1.2, 2.2), 0.3, 0.1)     # the understory, dark, low
    shoots(cv, 7000, (0.45, 0.82), (1.6, 2.8), 0.5, 0.45)     # the taller shoots
    rgb, h = cv.render()
    save(OUT, rgb, 0.04 + 0.96 * h)
    print("saved", OUT, "gaps:", round(float((h < 0.05).mean()), 3))
    # the canopy, its own layer (it sways over the shoots)
    sp = Canvas()
    sporophytes(sp, 120)
    rgb, h = sp.render(bg=STALK_DARK)
    save(OUT_CANOPY, rgb, (h > 0.0).astype(np.float32))
    print("saved", OUT_CANOPY)


def save(path, rgb, a):
    chans = [Image.fromarray((np.clip(ch, 0, 1) * 255 + 0.5).astype(np.uint8), "L").resize((W, W), Image.LANCZOS)
             for ch in (rgb[..., 0], rgb[..., 1], rgb[..., 2], a)]
    Image.merge("RGBA", chans).save(path)


if __name__ == "__main__":
    main()
