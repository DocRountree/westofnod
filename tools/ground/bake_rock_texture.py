#!/usr/bin/env python3
"""Bakes the mountains' bare rock (data/population/textures/rock.png): RGBA,
1024 x 1024, tileable, about 6 m square, laid on the terrain's rock from
three sides (terrain.gdshader: triplanar, at two scales):

  R, G  the surface's slope across the texture (its normal's x and y,
        0.5 level), for the light to pick out
  B     cavity: 0 deep in a crack, ~0.5 on a face, 1 on an edge
  A     brightness, 0.5 the mean (the terrain's rock colour is multiplied by
        twice this)

The rock: fractured into blocks (cells of a tiling Voronoi pattern), each
block a facet tilted its own way, broken at its edges, with cracks between
them; roughened over all at a few scales; darker down in the cracks, paler
on the edges, blotched (weathering).

    python3 tools/ground/bake_rock_texture.py
"""
import os

import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree

N = 1024
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "data", "population", "textures", "rock.png")
rng = np.random.default_rng(29)


def fbm(beta, lo=1.0):
    """Tiling noise with a power spectrum ~ 1/f^beta (FFT: periodic)."""
    f = np.fft.fftfreq(N)[:, None] ** 2 + np.fft.fftfreq(N)[None, :] ** 2
    f = np.sqrt(f) * N
    amp = np.where(f >= lo, 1.0 / np.maximum(f, 1e-6) ** (beta / 2.0), 0.0)
    ph = np.fft.fft2(rng.standard_normal((N, N)))
    a = np.real(np.fft.ifft2(ph * amp))
    return (a - a.mean()) / a.std()


def voronoi(n_sites):
    """Per pixel: the nearest site's index, F2 - F1 (in pixels) and where it
    is from that site (its nearest copy: so a block across the tile's edge
    is one block), tiling."""
    sites = rng.random((n_sites, 2)) * N
    tiled = np.concatenate([sites + np.array([dx, dy]) * N for dx in (-1, 0, 1) for dy in (-1, 0, 1)])
    idx = np.tile(np.arange(n_sites), 9)
    yy, xx = np.mgrid[0:N, 0:N]
    pts = np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1)
    # (warped a little, so the cracks wander)
    warp = np.stack([fbm(3.0, 4.0).ravel(), fbm(3.0, 4.0).ravel()], 1) * 9.0
    d, i = cKDTree(tiled).query(pts + warp, k=2)
    return idx[i[:, 0]].reshape(N, N), (d[:, 1] - d[:, 0]).reshape(N, N), (pts + warp - tiled[i[:, 0]])


def main():
    cell, gap, pts = voronoi(110)
    # each block a facet: a tilted plane of its own, its height its own
    tilt = rng.normal(0.0, 0.5, (cell.max() + 1, 2))
    lift = rng.normal(0.0, 6.0, cell.max() + 1)
    p = pts.reshape(N, N, 2)
    h = p[..., 0] * tilt[cell, 0] + p[..., 1] * tilt[cell, 1] + lift[cell]
    # the edges broken off: lower toward the crack, rounded
    edge = np.clip(gap / 14.0, 0.0, 1.0)
    h = h * 0.6 - (1.0 - edge) ** 2 * 10.0
    # a second, finer fracture inside the blocks
    c2, g2, _ = voronoi(700)
    h -= (1.0 - np.clip(g2 / 4.0, 0.0, 1.0)) ** 2 * 2.5 * edge
    # roughness at a few scales
    h += fbm(2.6, 2.0) * 3.0 + fbm(1.6, 16.0) * 0.6
    # the slopes, wrapping
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    k = 0.11
    n = np.stack([-gx * k, -gy * k, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    # cavity: the height against its neighbourhood's, wrapping
    blur = ndimage.gaussian_filter(h, 6.0, mode="wrap")
    cav = np.clip(0.5 + (h - blur) / 12.0, 0.0, 1.0)
    # brightness: weathered blotches, darker in the cracks, paler on edges
    bright = 1.0 + 0.16 * fbm(2.2, 2.0) + 0.06 * fbm(1.0, 30.0) + (lift[cell] / 6.0) * 0.06
    bright *= 0.72 + 0.28 * np.clip(gap / 6.0, 0.0, 1.0)
    bright *= 0.85 + 0.3 * cav
    bright /= bright.mean()
    img = np.stack([n[..., 0] * 0.5 + 0.5, n[..., 1] * 0.5 + 0.5, cav, np.clip(bright * 0.5, 0.0, 1.0)], -1)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT)
    print("rock.png: brightness mean %.3f, normal z min %.2f" % (img[..., 3].mean(), n[..., 2].min()))


if __name__ == "__main__":
    main()
