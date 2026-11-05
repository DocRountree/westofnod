"""Bakes the American toad's warts (data/creatures/toad_warts.png): a
tileable 512 x 512 tile (one tile = TILE mm of skin, AmericanToad's
wart_tile), drawn on its skin triplanar (frog.gd's skin shader, warts):

- R: the skin's height: warts, each a dome a little lopsided, the big ones
  (1.6-2.8 mm across) scattered, small ones (0.6-1.5 mm) among them, bare granular skin between, the skin
  between them finely granular; 0 the lowest, 1 a big wart's top.
- G: the big warts' tips (rusty, paler: the toad's own): 1 at their tops.
- B: each wart's own tone (some darker, some paler), 0.5 the skin's.
- A: 255.

python3 tools/creatures/bake_toad_warts.py
"""
import os

import numpy as np
from PIL import Image

N = 512
TILE = 24.0  # mm of skin a tile (frog.gd: wart_tile)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "creatures", "toad_warts.png")
rng = np.random.default_rng(31)
px = TILE / N  # mm a pixel

yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
height = np.zeros((N, N), np.float32)
tip = np.zeros((N, N), np.float32)
tone = np.full((N, N), 0.5, np.float32)


def wart(cx, cy, r_mm, h, lop, tone_v, big):
    """A dome at (cx, cy) px, r_mm across its radius, h high, lopsided by lop
    (its top off its middle); only the pixels about it touched, wrapped round
    the tile's edges (it tiles)."""
    r = r_mm / px
    m = int(np.ceil(r * 1.3)) + 1
    ix = np.arange(int(cx) - m, int(cx) + m + 1)
    iy = np.arange(int(cy) - m, int(cy) + m + 1)
    dx = (ix - cx)[None, :]
    dy = (iy - cy)[:, None]
    d = np.sqrt((dx - lop[0] * r) ** 2 + (dy - lop[1] * r) ** 2 * 1.1) / r
    inside = d < 1.0
    dome = np.where(inside, h * np.sqrt(np.clip(1.0 - d * d, 0.0, 1.0)) ** 0.8, 0.0)
    wy, wx = np.ix_(iy % N, ix % N)
    cur = height[wy, wx]
    top = inside & (dome >= cur)
    height[wy, wx] = np.maximum(cur, dome)
    t = tone[wy, wx]
    tone[wy, wx] = np.where(top, tone_v, t)
    if big:
        tip[wy, wx] = np.maximum(tip[wy, wx], np.clip((0.45 - d) / 0.45, 0.0, 1.0) * inside)


# the big warts, scattered, kept a little apart
bigs = []
while len(bigs) < 38:
    c = rng.uniform(0, N, 2)
    if all(np.linalg.norm(((c - b + N / 2) % N) - N / 2) > 3.0 / px for b in bigs):
        bigs.append(c)
for c in bigs:
    wart(c[0], c[1], rng.uniform(0.8, 1.4), rng.uniform(0.75, 1.0), rng.uniform(-0.25, 0.25, 2), rng.uniform(0.35, 0.65), True)
# the small ones, many, among them
for k in range(350):
    c = rng.uniform(0, N, 2)
    wart(c[0], c[1], rng.uniform(0.3, 0.75), rng.uniform(0.25, 0.5), rng.uniform(-0.2, 0.2, 2), rng.uniform(0.4, 0.6), False)

# the skin between them: finely granular (a periodic noise)
f = np.fft.fft2(rng.normal(size=(N, N)))
fy = np.fft.fftfreq(N)[:, None]
fx = np.fft.fftfreq(N)[None, :]
k = np.sqrt(fx * fx + fy * fy)
grain = np.real(np.fft.ifft2(f * np.exp(-((k - 0.18) / 0.06) ** 2)))
grain = (grain - grain.min()) / (grain.max() - grain.min())
height = np.clip(height + 0.035 * grain, 0.0, 1.0)

img = np.stack([height, tip, tone, np.ones_like(height)], -1)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
Image.fromarray((img * 255).round().astype(np.uint8), "RGBA").save(OUT, optimize=True)
print("baked", os.path.abspath(OUT))
