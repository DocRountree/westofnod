#!/usr/bin/env python3
"""Lowers the mesas of Isabela's southern lobe (bake_galapagos.py: mesas):
everything there above LOW squashed down to SCALE of its height over it, so
the caprocks come down from ~1100 m to ~410 m (a climb, not an expedition),
the walls from ~250 m to ~75 m (still sheer: cliffs, not slopes). Faded in
over the lobe's edge (erode.mesa_lobe), so there's no seam.

The biome map is baked from the heights before this (the plateau biome is
where the mesas stood tall, render_map.biome_layer: the same ground keeps
its colours once lower): bake_galapagos.py runs this after bake_biomes.py.

On its own, on the baked world (once: world.json records it):

    python3 tools/dem/lower_mesas.py [repo] [--force]
"""
import gzip
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import erode

LOW = 120.0    # m: left as is below this
SCALE = 0.3    # what's above it squashed to this


def lower_mesas(h):
    lobe = erode.mesa_lobe(h)
    low = LOW + (h - LOW) * SCALE
    return np.where(h > LOW, h + (low - h) * lobe, h).astype(np.float32)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    repo = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    d = os.path.join(repo, "data", "world")
    meta = json.load(open(os.path.join(d, "world.json")))
    if meta.get("mesas_lowered") and "--force" not in sys.argv:
        sys.exit("already lowered (world.json: mesas_lowered); --force to lower again")
    n = meta["size"]
    h = np.frombuffer(gzip.open(os.path.join(d, "heights.f16.gz")).read(), "<f2").reshape(n, n).astype(np.float32)
    out = lower_mesas(h)
    lobe = erode.mesa_lobe(h) > 0.5
    print("mesa lobe: highest %.0f m -> %.0f m" % (h[lobe].max(), out[lobe].max()))
    with gzip.open(os.path.join(d, "heights.f16.gz"), "wb", compresslevel=6) as f:
        f.write(out.astype("<f2").tobytes())
    meta["mesas_lowered"] = {"from_m": LOW, "scale": SCALE}
    json.dump(meta, open(os.path.join(d, "world.json"), "w"), indent=1)
    print("written")


if __name__ == "__main__":
    main()
