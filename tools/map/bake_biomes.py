"""Bakes the biome map (biomes.py's rules, as drawn by render_map.py --biomes)
for the game: data/world/biomes.png, 4096 x 4096, one byte per pixel, the
biome's index in biomes.COLOURS (255: none). The terrain shader colours each
biome from it (terrain.gdshader); WorldData.biome_at() names it.

    python tools/map/bake_biomes.py
"""
import gzip
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_map
import biomes

if __name__ == "__main__":
    d = os.path.join(render_map.REPO, "data", "world")
    m = json.load(open(os.path.join(d, "world.json")))
    n = m["size"]
    h = np.frombuffer(gzip.open(os.path.join(d, "heights.f16.gz")).read(), "<f2").reshape(n, n).astype(np.float32)
    k = n // render_map.S
    h = h.reshape(render_map.S, k, render_map.S, k).mean((1, 3))
    layer = render_map.biome_layer(h).astype(np.int16)
    out = np.where(layer < 0, 255, layer).astype(np.uint8)
    Image.fromarray(out, "L").save(os.path.join(d, "biomes.png"), optimize=True)
    m["biomes"] = {"file": "biomes.png", "size": render_map.S, "names": list(biomes.COLOURS)}
    json.dump(m, open(os.path.join(d, "world.json"), "w"), indent=1)
    print("biomes:", {nm: int((out == i).sum()) for i, nm in enumerate(biomes.COLOURS)})
