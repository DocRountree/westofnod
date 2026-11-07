"""Bakes the turtles' skin scales (data/creatures/turtle_scales.png): a
tileable 512 x 512 tile of CELLS x CELLS scales (one scale about a unit
across: turtle.gd's skin shader lays it on in its own units, cell or 3.6
of them a scale), drawn on each part of its skin triplanar in that part's
own frame (so it's painted on: a flipper's scales go with the flipper):

- R: how far into its scale from the seam round it (the nearest point's
  distance less the next nearest's, 0 at the seam .. 1 at 0.6 of a scale
  in): the pale outline (a sea turtle's mosaic) and each scale's darker
  middle from it.
- G: each scale's own tone (0..1).
- B: each scale a rounded dome (its height: 1 its top, 0 the creases
  between): the skin's bumps.
- A: 255.

python3 tools/creatures/bake_turtle_scales.py
"""
import os

import numpy as np
from PIL import Image

N = 512
CELLS = 8  # scales a tile across
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "creatures", "turtle_scales.png")
rng = np.random.default_rng(17)

# a scale's centre jittered in each of the grid's cells (in scale units)
pts = (np.stack(np.meshgrid(np.arange(CELLS), np.arange(CELLS), indexing="ij"), -1).reshape(-1, 2)
       + rng.uniform(0.1, 0.9, (CELLS * CELLS, 2)))
tones = rng.uniform(0.0, 1.0, CELLS * CELLS)

u = (np.arange(N) + 0.5) / N * CELLS
X, Y = np.meshgrid(u, u, indexing="ij")
d1 = np.full((N, N), 1e9)
d2 = np.full((N, N), 1e9)
own = np.zeros((N, N), int)
for k, (px, py) in enumerate(pts):
    for ox in (-CELLS, 0, CELLS):  # (wrapped: it tiles)
        for oy in (-CELLS, 0, CELLS):
            d = np.hypot(X - (px + ox), Y - (py + oy))
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            own = np.where(closer, k, own)
            d1 = np.where(closer, d, d1)

edge = np.clip((d2 - d1) / 0.6, 0.0, 1.0)
tone = tones[own]
dome = 1.0 - np.clip(d1 / 0.62, 0.0, 1.0)
dome = dome * dome * (3.0 - 2.0 * dome)
dome = np.minimum(dome, np.clip(edge * 3.0, 0.0, 1.0))  # (creased at the seams)

img = np.stack([edge, tone, dome, np.ones_like(edge)], -1)
img = (np.clip(img, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)
# (x along the image's width)
Image.fromarray(img.transpose(1, 0, 2), "RGBA").save(OUT)
print("wrote", os.path.normpath(OUT))
