"""Telescopic stars for the night sky: every star in the HYG database (built
on Hipparcos, Yale and Gliese; complete to about magnitude 9) fainter than the
naked-eye catalogue (V > 6.5, which data/bright_stars.tres already has) down
to V 10.5. Real positions, so magnified clusters and nebulae show their real
stars.

    python tools/build_faint_stars.py [hygdata.csv] [repo]

Writes data/faint_stars.f32: little-endian float32 quads (ra rad, dec rad,
V magnitude, B-V colour index). HYG: (c) David Nash / astronexus, CC BY-SA 4.0,
https://github.com/astronexus/HYG-Database
"""
import csv, math, os, struct, sys, urllib.request

URL = "https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/CURRENT/hygdata_v41.csv"


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else None
    repo = sys.argv[2] if len(sys.argv) > 2 else "."
    if src is None:
        src = os.path.join(repo, "tools", ".cache_hyg.csv")
        if not os.path.exists(src):
            urllib.request.urlretrieve(URL, src)
    out = []
    for r in csv.DictReader(open(src, newline="")):
        m = float(r["mag"])
        if not 6.5 < m <= 10.5 or r["id"] == "0":
            continue
        ci = float(r["ci"]) if r["ci"] else 0.6
        out.append((math.radians(float(r["ra"]) * 15.0), math.radians(float(r["dec"])), m, ci))
    with open(os.path.join(repo, "data", "faint_stars.f32"), "wb") as f:
        for q in out:
            f.write(struct.pack("<4f", *q))
    print("%d stars" % len(out))


if __name__ == "__main__":
    main()
