"""Bakes data/sky/moon_normal.png: the moon's near side as a tangent-space
normal map, from its real relief, for moon.gdshader to light the craters
by (their rims catching the low sun along the terminator).

Source: LRO LOLA elevation, NASA SVS CGI Moon Kit (public domain),
ldem_16_uint.tif: 16 pixels a degree, equirectangular, longitude 0 at the
middle (east to the right), north at the top; heights in half metres from
-10 km (value 20000: the mean radius, 1737.4 km).

    python3 tools/sky/bake_moon_normals.py <ldem_16_uint.tif> [out.png]

Out: the near side only (longitude -90..90, latitude 90..-90; the shader
reads no further), SIZE x SIZE, two channels (luminance, alpha): the
normal's east and north parts, each * 0.5 + 0.5 (its up part follows).
Slopes are exaggerated EXAGGERATE times (and moon.gdshader's relief more
again): on a disc a hundred pixels across, real ones barely show.
"""
import sys

import numpy as np
from PIL import Image

SIZE = 1024
R = 1737400.0  # m
EXAGGERATE = 2.0

Image.MAX_IMAGE_PIXELS = None


def main() -> None:
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "data/sky/moon_normal.png"
    a = np.array(Image.open(src)).astype(np.float32)
    h = (a - 20000.0) * 0.5  # m from the mean radius
    w = h.shape[1]
    near = h[:, w // 4: w * 3 // 4]  # longitude -90..90
    img = Image.fromarray(near, mode="F").resize((SIZE, SIZE), Image.Resampling.BOX)
    z = np.array(img, dtype=np.float64)
    step = np.pi / SIZE  # rad a pixel, both ways
    lat = (0.5 - (np.arange(SIZE) + 0.5) / SIZE) * np.pi
    dx = R * step * np.maximum(np.cos(lat), 0.05)[:, None]
    dy = R * step
    zp = np.pad(z, 1, mode="edge")
    east = (zp[1:-1, 2:] - zp[1:-1, :-2]) / (2.0 * dx)
    north = (zp[:-2, 1:-1] - zp[2:, 1:-1]) / (2.0 * dy)  # (rows run south)
    slope = np.hypot(east, north)
    print("slopes (deg): median %.2f  99%% %.2f  max %.2f" % tuple(np.degrees(np.arctan(np.percentile(slope, q))) for q in (50, 99, 100)))
    n = np.stack([-east * EXAGGERATE, -north * EXAGGERATE, np.ones_like(z)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    print("exaggerated: 99%% %.1f deg" % np.degrees(np.arccos(np.percentile(n[..., 2], 1))))
    la = np.clip(np.round((n[..., :2] * 0.5 + 0.5) * 255.0), 0, 255).astype(np.uint8)
    Image.fromarray(la, mode="LA").save(out, optimize=True)
    print("wrote", out)


if __name__ == "__main__":
    main()
