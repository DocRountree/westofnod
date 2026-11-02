"""Bakes data/population/textures/lichen.png: lichen on bark, tileable,
0.6 m across (one repeat of the bark texture round a trunk: TreeBuilder.
bark_tile) and 2.4 m along it, so the bark shader (lichen.gdshaderinc)
needs one texture read for it, each tree reading it from its own place.

Drawn as lichen grows (after photographs of bark lichens; colours sampled
from one, set in lichen.gdshaderinc):
- leafy (foliose) rosettes, a few cm across: lobes radiating from the
  middle, each forking again and again as it goes, widening to a rounded,
  scalloped tip; later lobes lying over earlier ones (a shadowed line
  where one's margin overlaps another); the margins pale and turned up;
- crust (crustose), pale grey, cracked into small plates, with round
  fruiting discs, brown in a pale rim;
- now and then a yellow-green powdery crust.
Channels:
  R  0 bare bark; on lichen 0.52 + 0.48 x its rarity, one value for a
     whole rosette or crust patch (blurred a little at their margins): the
     shader shows those rarer than it wants (R over a threshold), whole,
     for more or less lichen; the big ones are the rarest
  G  how high it stands off the bark (0..1: margins turned up, crinkled)
  B  shade x 0.75 (overlaps, cracks darker; margins paler)
  A  kind: 1 leafy (and bare bark), 0.7 crust, 0.45 a disc, 0.2 yellow
     (never 0: an image tool or importer may drop the colour of clear pixels)

python3 tools/trees/bake_lichen.py
"""

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 512, 2048          # the texture (0.6 x 2.4 m)
SS = 2                    # drawn at twice that, then reduced
PX_M = W * SS / 0.6       # drawing pixels per metre
M = 200                   # margin drawn past the edges, folded back (tiling)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "population", "textures", "lichen.png")

rng = random.Random(7)


def fold(a, how="max"):
    """Folds the margins of a drawn array back onto the opposite edges, so
    it tiles."""
    w, h = W * SS, H * SS
    out = a[M:M + h, M:M + w].copy()
    rows = [(slice(0, M), slice(h - M, h)), (slice(M, M + h), slice(0, h)), (slice(M + h, None), slice(0, M))]
    cols = [(slice(0, M), slice(w - M, w)), (slice(M, M + w), slice(0, w)), (slice(M + w, None), slice(0, M))]
    for ri, (rs, rd) in enumerate(rows):
        for ci, (cs, cd) in enumerate(cols):
            if ri == 1 and ci == 1:
                continue
            src = a[rs, cs]
            if how == "max":
                out[rd, cd] = np.maximum(out[rd, cd], src)
            else:  # (ids: where drawn, it lies on top)
                out[rd, cd] = np.where(src > 0, src, out[rd, cd])
    return out


def blur_wrap(a, r):
    """Gaussian blur of a tiling array (wrapped round: in frequency space)."""
    h, w = a.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.rfftfreq(w)[None, :]
    g = np.exp(-2 * (math.pi * r) ** 2 * (fx * fx + fy * fy))
    return np.fft.irfft2(np.fft.rfft2(a.astype(np.float32)) * g, s=a.shape).astype(np.float32)


def _wrap(d, n):
    d = abs(d) % n
    return min(d, n - d)


def free_spot(taken, r):
    for _ in range(40):
        x = rng.uniform(0, W * SS)
        y = rng.uniform(0, H * SS)
        if all(math.hypot(_wrap(x - a, W * SS), _wrap(y - b, H * SS)) > (r + c) * 0.75 for a, b, c in taken):
            return x, y
    return None


def disc(draw, x, y, r, fill):
    draw.ellipse([x - r + M, y - r + M, x + r + M, y + r + M], fill=fill)


def rosette(draw, cx, cy, R, next_id):
    """A leafy rosette: lobes out from the middle, forking, widening to
    scalloped tips; each lobe its own id (for the overlaps)."""
    # the middle: older lobes, crowded, overlapping
    for _ in range(rng.randint(3, 6)):
        a = rng.uniform(0, math.tau)
        rr = R * rng.uniform(0.15, 0.35)
        disc(draw, cx + math.cos(a) * rr * 0.6, cy + math.sin(a) * rr * 0.6, rr, next_id)
        next_id += 1
    n = rng.randint(6, 10)
    a0 = rng.uniform(0, math.tau)
    for i in range(n):
        a = a0 + i * math.tau / n + rng.uniform(-0.25, 0.25)
        next_id = lobe(draw, cx, cy, a, R * rng.uniform(0.7, 1.0), R * rng.uniform(0.12, 0.16), R * rng.uniform(0.22, 0.3), 0, next_id)
    return next_id


def lobe(draw, x, y, a, reach, w0, w1, depth, next_id):
    """A lobe from (x, y) heading a, `reach` long, widening from w0 to w1;
    part way it may fork into two (now and then three) narrower ones."""
    my = next_id
    next_id += 1
    fork_at = rng.uniform(0.35, 0.65) if depth < 3 and reach > w1 * 2.5 else 2.0
    steps = max(int(reach / max(w0 * 0.3, 1.0)), 4)
    for s in range(steps + 1):
        t = s / steps
        if t > fork_at:
            left = reach * (1 - fork_at)
            ws = (w0 + (w1 - w0) * fork_at) * 0.8
            spread = rng.uniform(0.3, 0.55)
            for sgn in ([-1, 1] if rng.random() > 0.15 else [-1, 0, 1]):
                next_id = lobe(draw, x, y, a + sgn * spread + rng.uniform(-0.1, 0.1), left * rng.uniform(0.85, 1.1), ws, w1 * 0.85, depth + 1, next_id)
            return next_id
        a += rng.uniform(-0.12, 0.12)
        x += math.cos(a) * reach / steps
        y += math.sin(a) * reach / steps
        disc(draw, x, y, (w0 + (w1 - w0) * t * t) * 0.5, my)
    # the tip: rounded, scalloped (small lobules round its end)
    w = w1 * 0.5
    disc(draw, x, y, w, my)
    for _ in range(rng.randint(2, 4)):
        b = a + rng.uniform(-1.1, 1.1)
        disc(draw, x + math.cos(b) * w * 0.75, y + math.sin(b) * w * 0.75, w * rng.uniform(0.4, 0.65), my)
    return next_id


def value_noise(shape, cells, seed):
    """Tiling value noise over `shape`, `cells` (across, along) lattice cells."""
    g = np.random.default_rng(seed).random((cells[1], cells[0]))
    h, w = shape
    y = np.arange(h) / h * cells[1]
    x = np.arange(w) / w * cells[0]
    iy, ix = np.floor(y).astype(int), np.floor(x).astype(int)
    fy, fx = y - iy, x - ix
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    a = g[np.ix_(iy % cells[1], ix % cells[0])]
    b = g[np.ix_(iy % cells[1], (ix + 1) % cells[0])]
    c = g[np.ix_((iy + 1) % cells[1], ix % cells[0])]
    d = g[np.ix_((iy + 1) % cells[1], (ix + 1) % cells[0])]
    fx, fy = fx[None, :], fy[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def main():
    w, h = W * SS, H * SS
    # leafy rosettes
    ids_im = Image.new("I", (w + 2 * M, h + 2 * M), 0)
    draw = ImageDraw.Draw(ids_im)
    taken = []
    next_id = 1
    rarity = [0.0]
    for _ in range(320):
        big = rng.random() ** 2.5  # (mostly small)
        R = (0.012 + 0.055 * big) * PX_M
        spot = free_spot(taken, R)
        if spot is None:
            continue
        taken.append((spot[0], spot[1], R))
        first = next_id
        next_id = rosette(draw, spot[0], spot[1], R, next_id)
        rarity += [rng.random() * (1.0 - 0.75 * big)] * (next_id - first)
    ids = fold(np.asarray(ids_im, dtype=np.int64), "id")
    leafy = (ids > 0).astype(np.float32)
    leafy_rar = np.asarray(rarity, np.float32)[ids]
    # overlaps: where one lobe meets another
    meet = np.zeros_like(leafy)
    for dy, dx in ((1, 0), (0, 1), (1, 1), (-1, 1)):
        o = np.roll(np.roll(ids, dy, 0), dx, 1)
        meet = np.maximum(meet, ((o != ids) & (o > 0) & (ids > 0)).astype(np.float32))
    overlap = np.clip(blur_wrap(meet, 1.5) * 2.5, 0, 1)

    # crust: blobs where no rosette is, cracked into plates, with discs
    blobs = value_noise((h, w), (12, 48), 3) * 0.7 + value_noise((h, w), (30, 120), 4) * 0.3
    crust = np.clip((blobs - 0.64) / 0.03, 0, 1) * (1 - np.clip(blur_wrap(leafy, 6) * 3, 0, 1))
    n1 = value_noise((h, w), (40, 160), 5)
    n2 = value_noise((h, w), (64, 256), 6)
    crack = np.clip(1 - np.minimum(np.abs(n1 - 0.5), np.abs(n2 - 0.5)) / 0.025, 0, 1) * crust
    dim = Image.new("L", (w + 2 * M, h + 2 * M), 0)
    rim_im = Image.new("L", (w + 2 * M, h + 2 * M), 0)
    dd, rd = ImageDraw.Draw(dim), ImageDraw.Draw(rim_im)
    for _ in range(6000):
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        if crust[int(y), int(x)] < 0.9:
            continue
        r = rng.uniform(0.0008, 0.0022) * PX_M
        disc(rd, x, y, r * 1.4, 255)
        disc(dd, x, y, r, 255)
    fruit = fold(np.asarray(dim, dtype=np.float32) / 255)
    rim = np.clip(fold(np.asarray(rim_im, dtype=np.float32) / 255) - fruit, 0, 1)

    # yellow-green powdery crust, here and there
    yel_n = value_noise((h, w), (5, 20), 8)
    grain = value_noise((h, w), (150, 600), 9)
    yellow = np.clip((yel_n - 0.78) / 0.03, 0, 1) * np.clip((grain - 0.3) / 0.1, 0, 1) * (1 - np.clip(leafy + crust, 0, 1))

    lichen = np.clip(leafy + crust + yellow + rim, 0, 1)
    # inside: a softened mask, 0.5 at the margin
    # rarity: a rosette's own; a crust patch's from a noise as big as the
    # patches (crust patches rarer: they're the big ones)
    crust_rar = value_noise((h, w), (12, 48), 12) * 0.55
    rar = np.where(leafy > 0.5, leafy_rar, crust_rar)
    r_ch = blur_wrap(np.where(lichen > 0.5, 0.52 + 0.48 * rar, 0.0), 1.2)
    # height: leafy margins turned up and crinkled, crust low
    margin = np.clip(1 - blur_wrap(leafy, 5.0) * 1.6, 0, 1) * leafy
    crinkle = value_noise((h, w), (90, 360), 10)
    height = leafy * (0.3 + 0.7 * margin * (0.5 + crinkle)) + overlap * leafy * 0.4 + crust * 0.15 + rim * 0.3 + yellow * 0.1
    shade = (1.0 + 0.25 * margin - 0.22 * overlap * leafy - 0.5 * crack + 0.12 * rim) * (0.9 + 0.1 * crinkle)
    kind = np.where(yellow > 0.5, 0.2, np.where(fruit > 0.5, 0.45, np.where(crust + rim > 0.5, 0.7, 1.0)))

    img = np.stack([r_ch, np.clip(height, 0, 1), np.clip(shade * 0.75, 0, 1), kind], -1)
    chans = [Image.fromarray((img[..., i] * 255 + 0.5).astype(np.uint8), "L").resize((W, H), Image.LANCZOS) for i in range(4)]
    Image.merge("RGBA", chans).save(OUT)
    print("saved", OUT, "lichen share:", round(float(lichen.mean()), 3))


if __name__ == "__main__":
    main()
