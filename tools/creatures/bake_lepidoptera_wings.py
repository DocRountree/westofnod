"""Bakes the butterflies' and moths' wings (Lepidoptera, scripts/creatures/):

- data/creatures/lepidoptera_wings.png: an RGBA atlas of 4 x 7 cells, 512 px
  each, a wing to a cell (the right one; the left is drawn mirrored):
    0 monarch forewing, above   1 the same, beneath
    2 monarch hindwing, above   3 the same, beneath
    4 hummingbird clearwing forewing (the same both sides: clear)
    5 its hindwing
    6 swallowtail forewing, above   7 the same, beneath
    8 swallowtail hindwing, above   9 the same, beneath
    10 luna moth forewing, above   11 the same, beneath
    12 luna moth hindwing, above   13 the same, beneath
    14 mourning cloak forewing, above   15 the same, beneath
    16 mourning cloak hindwing, above   17 the same, beneath
    18 cecropia forewing, above   19 the same, beneath
    20 cecropia hindwing, above   21 the same, beneath
    22 polyphemus forewing, above   23 the same, beneath
    24 polyphemus hindwing, above   25 the same, beneath
  A wing with tails (the swallowtail's, the luna's) is cut by its alpha:
  its mesh is the outline's convex hull (fanned from its middle), its
  true outline painted.
  Alpha is how opaque: 1 scaled, ~0.1 the clearwing's glassy cells, 0
  outside the wing (the colour there bled from the nearest wing, for the
  mipmaps).
- scripts/creatures/lepidoptera_wings.gd: each wing's outline (mm, its
  hinge at the origin, x out along it, z back), a little grown so the
  mesh holds the texture's soft edge, and how a point (mm) maps to the
  atlas (uv = uv_origin + p * uv_per_mm; beneath: + under).

The wings are drawn from their outlines and their veins, in mm: the
monarch's (Danaus plexippus) after a female's (heavier veins; no scent
patch): above, tawny orange, the veins black, a black costa, a black apex
crossed by a band of orange and white spots, a black border carrying two
rows of white dots, the inner margin black; beneath, paler, the forewing's
apex buff, the hindwing a pale buff orange, its veins black edged with
white. The clearwing's (Hemaris thysbe): glassy cells, a reddish brown
border toothed inward along the veins, a dark bar closing the cell, the
base olive and furred, the hindwing's inner margin red-brown (a dark
moth: its browns near black, its olive deep).

python3 tools/creatures/bake_lepidoptera_wings.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(__file__)
ROOT = os.path.join(HERE, "..", "..")
OUT_PNG = os.path.join(ROOT, "data", "creatures", "lepidoptera_wings.png")
OUT_GD = os.path.join(ROOT, "scripts", "creatures", "lepidoptera_wings.gd")
CELL = 512
COLS, ROWS = 4, 7
SS = 2  # supersampling
PAD = 1.5  # mm round the outline, in the cell
GROW = 0.5  # mm the mesh's outline is grown by

rng = np.random.default_rng(71)


def c(hexs):
    return np.array([int(hexs[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], np.float32)


BLACK = c("120e0d")
WHITE = c("f3efe4")
ORANGE = c("d9701a")  # above: tawny
ORANGE_BASE = c("a24d12")
SPOT_ORANGE = c("eb9a3a")
UNDER_ORANGE = c("e3913a")
BUFF = c("dcae62")
HIND_BUFF = c("e0b468")
VEIN_HALO = c("f4dfb2")
BROWN = c("3a160b")  # the clearwing's border
VEIN_BROWN = c("2c1209")
OLIVE = c("4a4520")
GLASS = c("b9b6a6")

# ---- the outlines (mm; right wing; the hinge at 0; x out, z back) -----------
# each walks from the base out along the costa (the leading edge), round the
# apex and the outer margin, and back along the inner margin: clockwise seen
# from above (x right, z down), as the meshes' front faces are.

MONARCH_FORE = [(0, -1.5), (6, -3.5), (14, -5.2), (24, -6.4), (34, -6.8), (41, -6.2), (45.5, -4.6), (48, -2.2),
                (49, 0.5), (48.6, 3.5), (46.6, 7.8), (43.6, 12.4), (40, 17), (36.4, 21), (33, 23.8), (30, 25.1),
                (27, 25.3), (21, 22.6), (14.5, 17.6), (9, 12.6), (4.5, 7.3), (1.5, 3.2), (0, 1)]
MF_COSTA = (0, 7)  # (outline indices: from, to)
MF_OUTER = (7, 16)
MF_INNER = (16, 23)

MONARCH_HIND = [(0, -1), (9, -1.5), (19, 0), (27, 3.5), (33, 8.5), (36, 14), (35.5, 19.5), (32.5, 24.5),
                (27.5, 28.5), (21, 30.5), (14.5, 30), (8.5, 27), (4, 22), (1.2, 15), (0, 7)]
MH_COSTA = (0, 3)
MH_OUTER = (3, 11)
MH_INNER = (11, 15)

HEMARIS_FORE = [(0, -0.6), (5, -1.6), (11, -2.4), (17, -2.6), (21, -2.0), (23.2, -0.8), (22.8, 0.6), (21, 2.8),
                (18.5, 5.2), (15.5, 7.2), (12.5, 8.6), (9.5, 8.7), (6, 7.4), (3, 5.2), (1, 2.8), (0, 0.8)]
HF_COSTA = (0, 5)
HF_OUTER = (5, 11)
HF_INNER = (11, 16)

HEMARIS_HIND = [(0, -0.5), (4.5, -0.6), (8.5, 0.3), (11.5, 2.3), (12.8, 5), (12, 7.8), (9.5, 9.8), (6.5, 10.5),
                (3.5, 9.8), (1.3, 7.4), (0.2, 4), (0, 1.5)]
HH_COSTA = (0, 3)
HH_OUTER = (3, 8)
HH_INNER = (8, 12)


def run(poly, span):
    """The outline's points from span[0] to span[1] (wrapping)."""
    a, b = span
    n = len(poly)
    return [poly[i % n] for i in range(a, b + 1)]


def along(pts, f):
    """The point f (0..1) of the way along a polyline, and its direction."""
    lens = [math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
    want = f * sum(lens)
    for i, l in enumerate(lens):
        if want <= l or i == len(lens) - 1:
            t = min(want / max(l, 1e-6), 1.0)
            p = (pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t)
            d = ((pts[i + 1][0] - pts[i][0]) / l, (pts[i + 1][1] - pts[i][1]) / l)
            return p, d
        want -= l


def vein(a, b, bow=0.06, past=3.0):
    """A vein from a to b, bowed a little (a share of its length, to its
    left), carried on past b (so it surely reaches the margin)."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    l = math.hypot(dx, dz)
    m = ((a[0] + b[0]) / 2 - dz / l * bow * l, (a[1] + b[1]) / 2 + dx / l * bow * l)
    pts = []
    for k in range(9):
        t = k / 8
        pts.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * m[0] + t * t * b[0],
                    (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * m[1] + t * t * b[1]))
    ex, ez = b[0] - pts[-2][0], b[1] - pts[-2][1]
    el = math.hypot(ex, ez)
    pts.append((b[0] + ex / el * past, b[1] + ez / el * past))
    return pts


def fan(origins, margin, fracs, bow=0.05):
    """Veins from origins (a point each) out to the margin at fracs of the
    way along it."""
    return [vein(o, along(margin, f)[0], bow) for o, f in zip(origins, fracs)]


# ---- the canvas: a cell's pixels as mm --------------------------------------

class Wing:
    def __init__(self, poly):
        self.poly = poly
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        self.x0, self.z0 = min(xs) - PAD, min(zs) - PAD
        w, h = max(xs) + PAD - self.x0, max(zs) + PAD - self.z0
        self.scale = (CELL - 8) / max(w, h)  # px per mm (at 1x)
        self.off = ((CELL - w * self.scale) / 2, (CELL - h * self.scale) / 2)  # px, in the cell
        n = CELL * SS
        jj, ii = np.meshgrid(np.arange(n, dtype=np.float32), np.arange(n, dtype=np.float32))
        self.X = self.x0 + ((jj + 0.5) / SS - self.off[0]) / self.scale
        self.Z = self.z0 + ((ii + 0.5) / SS - self.off[1]) / self.scale
        img = Image.new("L", (n, n), 0)
        ImageDraw.Draw(img).polygon([self.px(p) for p in poly], fill=255)
        self.inside = np.asarray(img, np.float32) / 255.0
        noise = rng.normal(0, 1, (CELL // 8, CELL // 8)).astype(np.float32)
        noise = np.asarray(Image.fromarray(noise).resize((n, n), Image.BICUBIC), np.float32)
        fine = rng.normal(0, 1, (n, n)).astype(np.float32)
        self.noise = noise * 0.6 + fine * 0.25  # (the scales' unevenness)

    def px(self, p):
        return ((self.off[0] + (p[0] - self.x0) * self.scale) * SS, (self.off[1] + (p[1] - self.z0) * self.scale) * SS)

    def dist(self, pts):
        """Each pixel's distance (mm) to a polyline."""
        best = np.full(self.X.shape, 1e9, np.float32)
        for (ax, az), (bx, bz) in zip(pts[:-1], pts[1:]):
            dx, dz = bx - ax, bz - az
            t = np.clip(((self.X - ax) * dx + (self.Z - az) * dz) / max(dx * dx + dz * dz, 1e-9), 0, 1)
            best = np.minimum(best, np.hypot(self.X - ax - t * dx, self.Z - az - t * dz))
        return best

    def dist_all(self, lines):
        best = np.full(self.X.shape, 1e9, np.float32)
        for pts in lines:
            best = np.minimum(best, self.dist(pts))
        return best

    def disc(self, at, r, soft=0.15):
        return 1.0 - smooth(r - soft, r + soft, np.hypot(self.X - at[0], self.Z - at[1]))


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def mixa(col, other, k):
    """mix, toward another image (its own colour at each pixel)."""
    k = np.clip(k, 0, 1)[..., None]
    return col * (1 - k) + other * k


def mix(col, other, k):
    k = np.clip(k, 0, 1)[..., None]
    return col * (1 - k) + other[None, None, :] * k


def dots_along(margin, spacing, inset, lines, avoid, skip_ends=0.04):
    """Points along a margin, inset (mm) in from it, between the veins
    (none within `avoid` of one)."""
    total = sum(math.dist(margin[i], margin[i + 1]) for i in range(len(margin) - 1))
    out = []
    n = int(total / spacing)
    for k in range(n):
        f = (k + 0.5) / n
        if f < skip_ends or f > 1 - skip_ends:
            continue
        p, d = along(margin, f)
        q = (p[0] - d[1] * inset, p[1] + d[0] * inset)  # (inward: the margin runs clockwise)
        if min(point_line(q, l) for l in lines) > avoid:
            out.append(q)
    return out


def point_line(q, pts):
    best = 1e9
    for (ax, az), (bx, bz) in zip(pts[:-1], pts[1:]):
        dx, dz = bx - ax, bz - az
        t = min(max(((q[0] - ax) * dx + (q[1] - az) * dz) / max(dx * dx + dz * dz, 1e-9), 0), 1)
        best = min(best, math.hypot(q[0] - ax - t * dx, q[1] - az - t * dz))
    return best


# ---- the monarch -----------------------------------------------------------

def monarch_fore_veins():
    outer = run(MONARCH_FORE, (4, 16))  # (from the costa near the apex round to the tornus)
    top, mid, low = (23, -3.2), (22.4, 1.0), (21.2, 4.8)
    stalk = (31, -3.6)
    cell = [[(1.5, -1.6), (12, -2.8), top], [(1.5, 0.6), (12, 3.2), low], [top, (23.2, -1.0), mid, low]]
    veins = [vein((1, -2.4), (30, -6.6), 0.02)]  # Sc, into the costa
    veins += [vein(top, along(outer, 0.0)[0], 0.02), vein(top, along(outer, 0.07)[0], 0.03)]  # R1, R2
    veins += [vein(top, stalk, 0.0, 0.0)]
    veins += fan([stalk, stalk, stalk], outer, [0.13, 0.2, 0.29], 0.03)  # R3-R5
    veins += fan([(23.1, -1.2), mid, (21.9, 3.2), (17, 4.1)], outer, [0.41, 0.54, 0.68, 0.84], 0.05)  # M1-M3, Cu1
    veins += [vein((11, 2.8), along(outer, 0.985)[0], 0.07)]  # Cu2
    veins += [vein((1.5, 0.6), (26.5, 24.2), 0.05)]  # 2A
    return cell + veins


def monarch_hind_veins():
    outer = run(MONARCH_HIND, MH_OUTER)
    top, mid, low = (16, 4.5), (16.8, 7.2), (13.8, 10.6)
    cell = [[(1, 0.2), (8, 2.2), top], [(1, 1.8), (8, 7.0), low], [top, mid, (16, 9.4), low]]
    veins = [vein((0.8, -0.3), (25, 2.6), 0.03)]  # Sc+R1, along under the costa
    veins += fan([top, (16.8, 6.0), mid, (16.3, 9.0), low, (11.0, 9.4)], outer, [0.1, 0.27, 0.43, 0.58, 0.73, 0.88], 0.05)
    veins += [vein((0.8, 2.0), (8.0, 28.0), -0.04), vein((0.5, 3.5), (3.6, 22.5), -0.05)]  # 2A, 3A
    return cell + veins


def paint_monarch_fore(under):
    w = Wing(MONARCH_FORE)
    lines = monarch_fore_veins()
    costa, outer, inner = run(MONARCH_FORE, MF_COSTA), run(MONARCH_FORE, MF_OUTER), run(MONARCH_FORE, MF_INNER)
    r = np.hypot(w.X, w.Z)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = UNDER_ORANGE if under else ORANGE
    col = mix(col, ORANGE_BASE if not under else UNDER_ORANGE * 0.85, (1 - smooth(4, 16, r)) * 0.8)
    # the apex: black above, buff beneath, beyond a line across it
    n = np.array([21.0, -14.0]) / math.hypot(21, 14)
    beyond = (w.X - 31.5) * n[0] + (w.Z + 7) * n[1]
    apex = smooth(-0.6, 0.6, beyond)
    col = mix(col, BUFF if under else BLACK, apex)
    # the subapical band of spots, across the apex
    spots = 0
    for p, rr in [((36.8, -4.4), 1.05), ((38.6, -1.9), 1.15), ((40.0, 0.9), 1.05), ((41.0, 3.6), 0.85)]:
        spots = np.maximum(spots, w.disc(p, rr))
    col = mix(col, WHITE if under else SPOT_ORANGE, spots)
    wspots = 0
    for p, rr in [((42.3, -4.9), 0.75), ((44.4, -3.2), 0.7), ((45.4, -0.9), 0.65), ((45.6, 1.6), 0.6), ((44.9, 4.2), 0.55)]:
        wspots = np.maximum(wspots, w.disc(p, rr))
    col = mix(col, WHITE, wspots)
    # the veins, heavier toward the base
    dv = w.dist_all(lines)
    vw = 0.42 + 0.35 * (1 - smooth(5, 30, r))
    col = mix(col, BLACK, 1 - smooth(vw - 0.12, vw + 0.12, dv))
    # the costa black (broadening toward the apex), the inner margin black
    cw = 1.0 + 0.9 * smooth(10, 40, w.X)
    col = mix(col, BLACK, 1 - smooth(cw - 0.15, cw + 0.15, w.dist(costa)))
    col = mix(col, BLACK, 1 - smooth(1.3 if not under else 0.8, 1.6 if not under else 1.1, w.dist(inner)))
    # the border, and its two rows of white dots
    do = w.dist(outer)
    col = mix(col, BLACK, 1 - smooth(3.0, 3.35, do))
    dots = 0
    for q in dots_along(outer, 2.6, 1.0, lines, 0.55):
        dots = np.maximum(dots, w.disc(q, 0.42 if not under else 0.5))
    for q in dots_along(outer, 2.6, 2.35, lines, 0.6, 0.1):
        dots = np.maximum(dots, w.disc(q, 0.55 if not under else 0.65))
    col = mix(col, WHITE, dots * (1 - smooth(3.0, 3.3, do)))
    return w, col, np.ones(w.X.shape, np.float32)


def paint_monarch_hind(under):
    w = Wing(MONARCH_HIND)
    lines = monarch_hind_veins()
    costa, outer, inner = run(MONARCH_HIND, MH_COSTA), run(MONARCH_HIND, MH_OUTER), run(MONARCH_HIND, MH_INNER)
    r = np.hypot(w.X, w.Z)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = HIND_BUFF if under else ORANGE
    if not under:
        col = mix(col, ORANGE_BASE, (1 - smooth(3, 12, r)) * 0.8)
    dv = w.dist_all(lines)
    vw = 0.5 if not under else 0.62
    if under:  # (the veins beneath edged with white: the halo first)
        col = mix(col, VEIN_HALO, 1 - smooth(vw + 0.45, vw + 0.65, dv))
    col = mix(col, BLACK, 1 - smooth(vw - 0.12, vw + 0.12, dv))
    col = mix(col, BLACK, 1 - smooth(0.6, 0.9, w.dist(costa)))
    # the inner (anal) margin dark, the fold by the body
    col = mix(col, BLACK if not under else BLACK * 1.6, (1 - smooth(1.4, 2.4, w.dist(inner))) * (0.9 if not under else 0.6))
    do = w.dist(outer)
    col = mix(col, BLACK, 1 - smooth(3.2, 3.55, do))
    dots = 0
    for q in dots_along(outer, 2.7, 1.05, lines, 0.6):
        dots = np.maximum(dots, w.disc(q, 0.45 if not under else 0.55))
    for q in dots_along(outer, 2.7, 2.5, lines, 0.65, 0.06):
        dots = np.maximum(dots, w.disc(q, 0.55 if not under else 0.7))
    col = mix(col, WHITE, dots * (1 - smooth(3.2, 3.5, do)))
    return w, col, np.ones(w.X.shape, np.float32)


# ---- the hummingbird clearwing ---------------------------------------------------

def hemaris_fore_veins():
    outer = run(HEMARIS_FORE, (3, 11))
    top, low = (12, -1.4), (10, 2.7)
    cell = [[(1, -0.8), (6, -1.2), top], [(1, 0.6), (6, 1.8), low], [top, (11.4, 0.6), low]]
    veins = fan([top, top, (12, -0.9), (11.6, 0.0), (11.0, 1.2), (10.5, 2.2), (7, 2.1)], outer,
                [0.08, 0.3, 0.45, 0.58, 0.71, 0.84, 0.97], 0.03)
    veins += [vein((1, 1.4), (9, 8.6), 0.03)]
    inside = [vein((3, -0.2), (11.5, 0.3), 0.0, 0.0)]  # (the cell parted down its length)
    return cell + veins, inside, [top, (11.4, 0.6), low]


def hemaris_hind_veins():
    outer = run(HEMARIS_HIND, HH_OUTER)
    top, low = (6.5, 1.0), (5.5, 4.0)
    cell = [[(0.8, 0.0), top], [(0.8, 1.6), low], [top, (6.6, 2.6), low]]
    veins = fan([top, top, (6.6, 2.6), low, low], outer, [0.05, 0.3, 0.52, 0.74, 0.95], 0.03)
    veins += [vein((0.6, 1.8), (3.6, 9.8), -0.03)]
    return cell + veins, [], [top, (6.6, 2.6), low]


def paint_hemaris(poly, spans, veins_fn, border_w, inner_w, base_r):
    w = Wing(poly)
    lines, inside, bar = veins_fn()
    costa, outer, inner = (run(poly, s) for s in spans)
    r = np.hypot(w.X, w.Z)
    dv = w.dist_all(lines)
    do = w.dist(outer)
    # the border, toothed inward along the veins
    tooth = border_w + 1.1 * (1 - smooth(0.15, 0.8, dv))
    border = 1 - smooth(tooth - 0.12, tooth + 0.12, do)
    border = np.maximum(border, 1 - smooth(0.55, 0.75, w.dist(costa)))
    border = np.maximum(border, 1 - smooth(inner_w - 0.2, inner_w + 0.2, w.dist(inner)))
    base = 1 - smooth(base_r * 0.55, base_r, r + w.noise * 0.4)  # (furred, olive)
    veins = 1 - smooth(0.17, 0.3, dv)
    veins = np.maximum(veins, 1 - smooth(0.12, 0.22, w.dist_all(inside)))
    veins = np.maximum(veins, 1 - smooth(0.38, 0.55, w.dist(bar)))  # (the dark bar closing the cell)
    solid = np.clip(np.maximum(np.maximum(border, base), veins), 0, 1)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = GLASS
    col = mix(col, VEIN_BROWN, veins)
    col = mix(col, BROWN, border)
    col = mix(col, OLIVE, base)
    a = 0.1 + 0.9 * solid
    return w, col, a



# ---- the swallowtail (Papilio machaon) -------------------------------------------
# after the Old World swallowtail (in North America too, in the north and the
# west): above, pale creamy yellow, the forewing's base black dusted with
# yellow scales, three black bars down from the costa, the veins black, a
# broad black band (dusted yellow) along the outer margin, a row of yellow
# spots in it, the edge black; the hindwing yellow, its veins black, a black
# band along its scalloped margin, blue scales over its inner half, yellow
# crescents in the scallops, a black tail edged yellow, by the body a red
# eyespot ringed black with blue above it; beneath, the same, paler, the
# black greyer, the hindwing's band edged orange.

SW_YELLOW = c("f1e3a4")
SW_YELLOW_UNDER = c("f4e9bd")
SW_BLACK = c("17130f")
SW_DUST = c("8a7f52")  # (the black dusted yellow)
SW_BLUE = c("3c5fb8")
SW_RED = c("c8261a")
SW_ORANGE = c("d9862c")

SW_FORE = [(0, -1.5), (8, -3.6), (18, -5.2), (28, -5.8), (36, -5.2), (41, -3.5), (42.6, -1.6), (41.4, 2), (39, 6.8),
           (36, 11.8), (33, 16.2), (30.4, 19.2), (26.5, 20.2), (19, 17.6), (12, 13), (6, 8), (2, 4), (0, 1)]
SWF_COSTA = (0, 6)
SWF_OUTER = (6, 12)
SWF_INNER = (12, 18)

SW_HIND = [(0, -1), (10, -1.8), (20, -0.4), (27, 3), (31, 7.6), (32.2, 11), (30.4, 13.6), (31.2, 16.2), (29, 18.8),
           (29.4, 21.3), (27, 23.6), (26.2, 26.4), (26.8, 32), (25.6, 37.8), (23.6, 40), (22, 38.4), (22.2, 32), (21.4, 27.4),
           (19, 28.2), (16.8, 27.6), (14.4, 29.2), (11.8, 28.6), (9, 29.4), (6.8, 27.6), (6.2, 25), (5, 20), (3, 13), (1, 6), (0, 2)]
SWH_COSTA = (0, 4)
SWH_OUTER = (4, 24)  # (round the scallops, out along the tail and back, to the anal angle)
SWH_INNER = (24, 29)


def sw_fore_veins():
    outer = run(SW_FORE, SWF_OUTER)
    top, low = (17, -2.2), (15, 3.6)
    cell = [[(1.2, -1.3), (9, -2.4), top], [(1.2, 0.8), (8, 2.6), low], [top, (16.6, 0.8), low]]
    veins = [vein((1, -2.2), (22, -5.6), 0.02)]
    veins += [vein(top, (30, -5.6), 0.02), vein(top, (36, -5.1), 0.03)]
    veins += fan([top, (17, -1.4), (16.8, -0.4), (16.6, 0.8), (16, 2.4), low, (11, 3.2)], outer,
                 [0.0, 0.14, 0.3, 0.46, 0.62, 0.78, 0.95], 0.04)
    veins += [vein((1.2, 0.8), (24, 19.6), 0.04)]
    return cell + veins


def sw_hind_veins():
    outer = run(SW_HIND, (3, 12))
    top, low = (13.5, 5.2), (11.5, 12.5)
    cell = [[(1, 0.4), (7, 2.6), top], [(1, 2.4), (7, 8.5), low], [top, (14.2, 8.8), low]]
    veins = [vein((0.8, -0.3), (24, 1.8), 0.03)]
    veins += fan([top, (13.9, 7.0), (14.2, 8.8), (13.2, 11), low], outer, [0.05, 0.25, 0.45, 0.64, 0.86], 0.05)
    veins += [vein((24, 25), (24.2, 37.5), 0.0, 0.0)]  # (along the tail)
    veins += [vein(low, (17.4, 27.6), 0.03), vein((8, 12), (11.8, 28.4), -0.03), vein((1, 3), (6.6, 26), -0.04)]
    return cell + veins


def paint_sw_fore(under):
    w = Wing(SW_FORE)
    lines = sw_fore_veins()
    costa, outer, inner = run(SW_FORE, SWF_COSTA), run(SW_FORE, SWF_OUTER), run(SW_FORE, SWF_INNER)
    r = np.hypot(w.X, w.Z)
    black = SW_BLACK * (1.9 if under else 1.0)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = SW_YELLOW_UNDER if under else SW_YELLOW
    # the base: black dusted with yellow, out to about a third
    dust = smooth(-0.4, 1.0, w.noise)
    base = 1 - smooth(9, 13, r + 1.2 * w.noise)
    col = mixa(col, mix(np.broadcast_to(black, col.shape).copy(), SW_DUST, dust * (0.7 if under else 0.45)), base * 0.97)
    # three black bars down from the costa
    for x0, wd, dn in [(10.5, 2.6, 4.0), (16.0, 2.4, 3.2), (23.5, 3.0, 1.2)]:
        bar = (1 - smooth(wd * 0.5 - 0.15, wd * 0.5 + 0.15, np.abs(w.X - x0 - (w.Z + 5) * 0.12))) * (1 - smooth(dn - 0.3, dn + 0.3, w.Z))
        col = mix(col, black, bar)
    # the veins
    dv = w.dist_all(lines)
    col = mix(col, black, 1 - smooth(0.3, 0.45, dv))
    # the costa black
    col = mix(col, black, 1 - smooth(0.7, 0.95, w.dist(costa)))
    # the outer band: black dusted yellow, from 2.5 to 9 mm in from the margin
    do = w.dist(outer)
    band = 1 - smooth(8.0, 8.8, do + 0.6 * w.noise)
    col = mixa(col, mix(np.broadcast_to(black, col.shape).copy(), SW_DUST, dust * 0.5), band)
    # its row of yellow spots between the veins, and the edge black
    spots = 0
    for q in dots_along(outer, 3.4, 2.4, lines, 0.6, 0.02):
        spots = np.maximum(spots, w.disc(q, 1.05))
    col = mix(col, SW_YELLOW_UNDER if under else SW_YELLOW, spots * (1 - smooth(4.0, 4.5, do)))
    col = mix(col, black, 1 - smooth(0.7, 0.9, do))
    return w, col, np.ones(w.X.shape, np.float32)


def paint_sw_hind(under):
    w = Wing(SW_HIND)
    lines = sw_hind_veins()
    costa, outer, inner = run(SW_HIND, SWH_COSTA), run(SW_HIND, SWH_OUTER), run(SW_HIND, SWH_INNER)
    black = SW_BLACK * (1.9 if under else 1.0)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = SW_YELLOW_UNDER if under else SW_YELLOW
    dust = smooth(-0.4, 1.0, w.noise)
    r = np.hypot(w.X, w.Z)
    # the base and the inner (anal) fold: dark, haired
    col = mixa(col, mix(np.broadcast_to(black, col.shape).copy(), SW_DUST, dust * 0.4), (1 - smooth(4, 7, r + w.noise)) * 0.9)
    col = mixa(col, mix(np.broadcast_to(black, col.shape).copy(), SW_DUST, dust * 0.6), 1 - smooth(1.6, 2.6, w.dist(inner)))
    # the veins, and a black dash closing the cell
    dv = w.dist_all(lines)
    col = mix(col, black, 1 - smooth(0.32, 0.48, dv))
    col = mix(col, black, 1 - smooth(0.6, 0.9, w.dist([(13.5, 5.2), (14.2, 8.8), (11.5, 12.5)])))
    # the band along the scalloped margin: black, blue scaled on its inner half
    do = w.dist(outer)
    band = 1 - smooth(7.0, 7.8, do + 0.5 * w.noise)
    col = mix(col, black, band)
    if under:
        col = mix(col, SW_ORANGE, (1 - smooth(0.5, 1.2, np.abs(do - 6.9))) * band * 0.8)
    blue = smooth(3.8, 4.8, do) * band * smooth(-0.6, 0.6, w.noise + 0.2)
    col = mix(col, SW_BLUE * (1.25 if under else 1.0), blue * (0.6 if not under else 0.45))
    # the yellow crescents in the scallops, and the edge
    cres = 0
    for q in dots_along(run(SW_HIND, (5, 11)), 3.0, 1.6, lines, 0.4, 0.05) + dots_along(run(SW_HIND, (18, 24)), 2.8, 1.5, lines, 0.4, 0.05):
        cres = np.maximum(cres, w.disc(q, 1.0) * (1 - w.disc((q[0] - 0.0, q[1] - 0.6), 0.7)))
    col = mix(col, SW_YELLOW_UNDER if under else SW_YELLOW, cres * band)
    col = mix(col, black, 1 - smooth(0.5, 0.75, do))
    # the tail: black, edged yellow
    tail = smooth(25.5, 27.0, w.Z) * (1 - smooth(0.0, 0.6, (np.abs(w.X - 24.2 - (w.Z - 26) * 0.03) - 2.2)))
    col = mix(col, black, tail * smooth(0.45, 0.7, do))
    # the eyespot by the body: red, ringed black, blue above
    eye_c = (8.6, 25.6)
    d_eye = np.hypot(w.X - eye_c[0], (w.Z - eye_c[1]) * 1.15)
    col = mix(col, black, 1 - smooth(2.9, 3.2, d_eye))
    col = mix(col, SW_BLUE * 1.15, (1 - smooth(2.3, 2.6, d_eye)) * smooth(0.3, -0.6, w.Z - eye_c[1]))
    col = mix(col, SW_RED, (1 - smooth(1.6, 1.9, np.hypot(w.X - eye_c[0], (w.Z - eye_c[1] - 0.6) * 1.15))))
    return w, col, np.ones(w.X.shape, np.float32)


# ---- the luna moth (Actias luna) -------------------------------------------------
# pale green, a little yellower toward the margins, its veins faintly paler;
# the forewing's costa a broad band of purplish maroon; an eyespot on each
# wing at the end of its cell: an oval clear window, ringed yellow, black
# and, on its outer side, maroon; the margins finely edged yellow and
# pinkish; the hindwing drawn out into a long, curving tail. Beneath, paler,
# the costa pinkish brown, the eyespots fainter.

LUNA_GREEN = c("b5e08d")
LUNA_GREEN_DEEP = c("8fd16a")
LUNA_MARGIN = c("e5d76a")
LUNA_PINK = c("b98c78")
LUNA_MAROON = c("6c3341")
LUNA_YELLOW = c("f0d64a")
LUNA_WINDOW = c("e9efd8")
LUNA_BASE = c("eef0e2")

LUNA_FORE = [(0, -1.8), (9, -4.8), (20, -6.8), (32, -7.6), (43, -6.8), (50, -4.8), (54.5, -1.8), (55.5, 1.5), (52.5, 7.5),
             (48.5, 14.5), (44.5, 21), (40.5, 26.2), (36, 28.4), (27, 25.5), (18, 19.5), (10, 12.5), (4, 6), (0, 1.5)]
LF_COSTA = (0, 7)
LF_OUTER = (7, 13)
LF_INNER = (13, 18)

LUNA_HIND = [(0, -1.2), (11, -2.4), (22, -1.0), (31, 3.2), (37, 9.5), (39.2, 16.5), (37.5, 23.5), (34.2, 29),
             (31.8, 35), (30.6, 44), (30.8, 53), (32.2, 61), (34.6, 68), (35.4, 71.5), (32.8, 70.6), (29.2, 65),
             (26.2, 57), (24.2, 47), (22, 39.6), (17.5, 35.4), (12, 31.6), (7, 26.5), (3.2, 18.5), (1, 9.5), (0, 3)]
LH_COSTA = (0, 4)
LH_OUTER = (4, 18)
LH_INNER = (18, 25)


def luna_fore_veins():
    outer = run(LUNA_FORE, LF_OUTER)
    top, low = (25, -3.0), (22, 6.0)
    cell = [[(1.2, -1.5), (12, -3.0), top], [(1.2, 0.9), (11, 4.0), low], [top, (24.6, 1.5), low]]
    veins = fan([top, (25, -2.0), (24.8, -0.4), (24.6, 1.5), (23.6, 4.0), low, (16, 5.0)], outer,
                [0.0, 0.16, 0.32, 0.48, 0.64, 0.8, 0.96], 0.04)
    veins += [vein(top, (44, -6.4), 0.02), vein((1.2, 0.9), (33, 27.2), 0.04)]
    return cell + veins


def luna_hind_veins():
    outer = run(LUNA_HIND, (3, 13))
    top, low = (17, 6.0), (15, 15)
    cell = [[(1, 0.3), (9, 2.8), top], [(1, 2.4), (8, 10), low], [top, (18, 10.5), low]]
    veins = fan([top, (17.6, 8.2), (18, 10.5), (17, 13), low], outer, [0.03, 0.18, 0.34, 0.5, 0.66], 0.05)
    veins += [vein(low, (28.5, 45), 0.04, 0.0), vein((28.5, 45), (33.5, 69), -0.05)]  # (down the tail)
    veins += [vein((6, 10), (18, 34), -0.03), vein((1, 3), (8, 26), -0.04)]
    return cell + veins


def luna_eye(w, at, rx, rz, tilt, under):
    """An eyespot: an oval window (clear-ish), ringed yellow, black, and on
    its outer side maroon; its weight on the pixels (window, yellow,
    black, maroon)."""
    ca, sa = math.cos(tilt), math.sin(tilt)
    dx, dz = w.X - at[0], w.Z - at[1]
    u = (dx * ca + dz * sa) / rx
    v = (-dx * sa + dz * ca) / rz
    d = np.hypot(u, v)
    win = 1 - smooth(0.42, 0.52, d)
    yel = 1 - smooth(0.66, 0.74, d)
    blk = 1 - smooth(0.84, 0.92, d)
    mar = (1 - smooth(1.0, 1.12, d)) * smooth(-0.2, 0.4, u)  # (on its outer side)
    return win, yel, blk, mar


def paint_luna(poly, spans, veins_fn, eye_at, eye_r, tilt, fore, under):
    w = Wing(poly)
    lines = veins_fn()
    costa, outer, inner = (run(poly, s) for s in spans)
    r = np.hypot(w.X, w.Z)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = LUNA_GREEN * (1.06 if under else 1.0)
    col = mix(col, LUNA_GREEN_DEEP, (1 - smooth(8, 26, r)) * (0.35 if under else 0.6))
    # the veins, faintly paler
    dv = w.dist_all(lines)
    col = mix(col, LUNA_GREEN * 1.12, (1 - smooth(0.2, 0.4, dv)) * 0.6)
    # the base: white fur
    col = mix(col, LUNA_BASE, 1 - smooth(2.5, 5.5, r + w.noise * 0.6))
    # the margin: yellow, and a fine pinkish edge
    do = w.dist(outer)
    col = mix(col, LUNA_MARGIN, (1 - smooth(1.0, 2.4, do)) * 0.8)
    col = mix(col, LUNA_PINK, 1 - smooth(0.3, 0.55, do))
    if fore:  # the costa: broad, maroon (pinkish brown beneath)
        cw = 2.6 - 1.2 * smooth(30, 52, w.X)
        col = mix(col, LUNA_PINK * 0.85 if under else LUNA_MAROON, 1 - smooth(cw - 0.25, cw + 0.25, w.dist(costa)))
    # the eyespot
    win, yel, blk, mar = luna_eye(w, eye_at, eye_r[0], eye_r[1], tilt, under)
    k = 0.6 if under else 1.0
    col = mix(col, LUNA_MAROON, mar * k)
    col = mix(col, SW_BLACK, blk * k)
    col = mix(col, LUNA_YELLOW, yel * k)
    col = mix(col, LUNA_WINDOW, win * k)
    a = np.ones(w.X.shape, np.float32) - win * 0.35  # (the window a little see-through)
    return w, col, a


# ---- the mourning cloak (Nymphalis antiopa) -------------------------------------
# above, a deep maroon (brown at the base, furred); a broad cream border,
# speckled dark, its edge ragged; inside it a black band carrying a row of
# violet-blue spots, one between each pair of veins; two cream marks on the
# forewing's costa near its tip. Beneath, bark: near black, finely striated
# grey, the border a dull pale grey.

MC_MAROON = c("5e1712")
MC_BASE = c("3a1e18")
MC_CREAM = c("eee0aa")
MC_BLACK = c("120c0b")
MC_BLUE = c("8a90e8")
MC_BARK = c("2a2522")
MC_BARK_PALE = c("6e665e")
MC_UNDER_EDGE = c("b8b0a0")

CLOAK_FORE = [(0, -1.5), (8, -3.6), (17, -5.0), (26, -5.4), (33, -4.6), (36.6, -2.8), (38.4, -0.4), (37.0, 1.6),
              (37.8, 4.4), (36.2, 7.4), (35.0, 10.2), (33.2, 12.6), (32.0, 15.6), (29.8, 18.8), (27.0, 21.4),
              (23.8, 22.0), (17, 18.2), (10, 12.6), (4.5, 6.6), (1.2, 2.6), (0, 0.8)]
CF_COSTA = (0, 6)
CF_OUTER = (6, 15)
CF_INNER = (15, 21)

CLOAK_HIND = [(0, -1), (9, -1.6), (18, -0.3), (25, 3.0), (29.6, 7.4), (31.0, 11.8), (30.2, 15.4), (32.4, 18.6),
              (29.4, 20.6), (27.6, 23.8), (23.6, 27.2), (18.4, 29.4), (13.2, 29.4), (8.2, 26.4), (4.0, 21.0),
              (1.2, 13.5), (0, 6)]
CH_COSTA = (0, 3)
CH_OUTER = (3, 13)
CH_INNER = (13, 17)


def cloak_fore_veins():
    outer = run(CLOAK_FORE, (4, 15))
    top, mid, low = (18, -2.6), (17.6, 1.2), (16.6, 4.4)
    cell = [[(1.5, -1.4), (9, -2.4), top], [(1.5, 0.6), (9, 2.8), low], [top, mid, low]]
    veins = fan([top, top, (18.2, -1.2), mid, (17.2, 3.0), low, (12, 4.2)], outer, [0.02, 0.14, 0.3, 0.46, 0.62, 0.78, 0.94], 0.04)
    veins += [vein((1.5, 0.6), (23, 21.4), 0.05)]
    return cell + veins


def cloak_hind_veins():
    outer = run(CLOAK_HIND, CH_OUTER)
    top, low = (13, 4.0), (11, 9.0)
    cell = [[(1, 0.2), (7, 2.0), top], [(1, 1.8), (7, 6.5), low], [top, (13.5, 6.5), low]]
    veins = fan([top, (13.4, 5.6), (13.5, 6.5), (12.6, 8.0), low, (8, 8.6)], outer, [0.05, 0.22, 0.4, 0.56, 0.72, 0.9], 0.05)
    veins += [vein((0.8, 2.0), (8.0, 26.0), -0.04)]
    return cell + veins


def paint_cloak(poly, spans, veins_fn, fore, under):
    w = Wing(poly)
    lines = veins_fn()
    costa, outer, inner = (run(poly, s) for s in spans)
    r = np.hypot(w.X, w.Z)
    do = w.dist(outer)
    dv = w.dist_all(lines)
    col = np.zeros(w.X.shape + (3,), np.float32)
    rag = 0.35 * np.sin(w.X * 2.3 + w.Z * 1.7) + 0.25 * w.noise  # (the border's inner edge, uneven)
    if under:
        # bark: near black, striated across in fine wavy grey lines
        col[:] = MC_BARK
        stri = 0.5 + 0.5 * np.sin((w.X * 0.3 + w.Z) * 5.5 + 2.0 * np.sin(w.X * 0.7) + w.noise * 1.5)
        col = mix(col, MC_BARK_PALE, smooth(0.55, 0.95, stri) * 0.6)
        col = mix(col, MC_BLACK, (1 - smooth(6, 14, r)) * 0.4)
        col = mix(col, MC_UNDER_EDGE * (0.9 + 0.1 * smooth(-1, 1, w.noise))[..., None] if False else MC_UNDER_EDGE, 1 - smooth(4.0, 4.6, do + rag))
        col = mix(col, MC_BARK, (1 - smooth(0.25, 0.4, dv)) * 0.5)
        return w, col, np.ones(w.X.shape, np.float32)
    col[:] = MC_MAROON
    col = mix(col, MC_BASE, (1 - smooth(5, 16, r + w.noise)) * 0.85)  # (the base, darker, furred)
    col = mix(col, MC_MAROON * 0.75, (1 - smooth(0.2, 0.45, dv)) * 0.5)  # (the veins, faintly darker)
    # the black band inside the border, and its blue spots
    band = 1 - smooth(8.6, 9.4, do + rag * 0.6)
    col = mix(col, MC_BLACK, band)
    spots = 0
    for q in dots_along(outer, 3.3, 7.0, lines, 0.5, 0.03):
        spots = np.maximum(spots, w.disc(q, 0.95))
    col = mix(col, MC_BLUE, spots * band)
    # the cream border, speckled dark, its edge itself dark and ragged
    border = 1 - smooth(4.4, 5.0, do + rag)
    speck = smooth(1.1, 1.6, w.noise * 1.6 + np.sin(w.X * 9) * np.sin(w.Z * 8) * 0.6)
    cream = mix(np.broadcast_to(MC_CREAM, col.shape).copy(), MC_BLACK, speck * 0.6 + (1 - smooth(0.0, 0.5, do)) * 0.7)
    col = mixa(col, cream, border)
    if fore:  # (the costa: dark, speckled; two cream marks toward its tip)
        dc = w.dist(costa)
        col = mix(col, MC_BLACK * 1.6, (1 - smooth(0.9, 1.3, dc)) * (1 - border))
        for p in [(29.5, -4.0), (34.0, -2.8)]:
            col = mix(col, MC_CREAM, w.disc(p, 1.25, 0.3) * (1 - smooth(2.2, 2.6, dc)))
    col = mix(col, MC_BASE * 0.8, (1 - smooth(0.6, 0.9, w.dist(inner))) * 0.5)
    return w, col, np.ones(w.X.shape, np.float32)


# ---- the cecropia moth (Hyalophora cecropia) ----------------------------------------
# frosted: dark brown dusted grey all over; the wings' bases red; a white
# band across both wings, edged red-orange on its outer side; beyond it a
# pale tan zone to the margin, a dark wavy line through it; a white crescent
# edged red at each cell's end; the forewing's tip lilac, a black eyespot in
# it with a blue-white crescent, a white zigzag. Beneath, the same, paler.

CE_BROWN = c("4a3a33")
CE_FROST = c("a89a90")
CE_RED = c("c2442a")
CE_ORANGE = c("d8642e")
CE_WHITE = c("f2ece0")
CE_TAN = c("cbb79a")
CE_LILAC = c("b294a6")
CE_BLACK = c("17110f")
CE_BLUE = c("8fb2d8")

CEC_FORE = [(0, -2.0), (10, -5.8), (22, -8.2), (36, -9.2), (48, -8.6), (57, -6.6), (63, -3.2), (65, 0.6), (63.2, 5),
            (58.5, 11), (53, 18), (48, 24), (43, 29), (39, 31.4), (30, 28.5), (20, 22), (11, 14), (4, 6.5), (0, 1.6)]
CEF_COSTA = (0, 7)
CEF_OUTER = (7, 13)
CEF_INNER = (13, 19)

CEC_HIND = [(0, -1.2), (12, -2.6), (24, -1.0), (34, 4.0), (41, 11), (44, 19), (43, 27), (39, 34), (32, 39.5),
            (24, 41.5), (16, 39.8), (9, 34), (4, 26), (1, 15), (0, 6)]
CEH_COSTA = (0, 3)
CEH_OUTER = (3, 11)
CEH_INNER = (11, 15)


def sat_veins(poly, outer_span, top, low, fracs, inner_to):
    outer = run(poly, outer_span)
    cell = [[(1.2, -1.2), (top[0] * 0.45, top[1] * 0.8), top], [(1.2, 0.9), (low[0] * 0.45, low[1] * 0.7), low], [top, low]]
    n = len(fracs)
    origins = [(top[0] + (low[0] - top[0]) * k / max(n - 1, 1), top[1] + (low[1] - top[1]) * k / max(n - 1, 1)) for k in range(n)]
    return cell + fan(origins, outer, fracs, 0.04) + [vein((1.2, 0.9), inner_to, 0.05)]


def band_line(w, pts):
    return w.dist(pts)


def paint_cecropia(fore, under):
    poly = CEC_FORE if fore else CEC_HIND
    spans = (CEF_COSTA, CEF_OUTER, CEF_INNER) if fore else (CEH_COSTA, CEH_OUTER, CEH_INNER)
    w = Wing(poly)
    costa, outer, inner = (run(poly, s) for s in spans)
    if fore:
        lines = sat_veins(poly, (5, 13), (30, -3.5), (27, 6), [0.0, 0.18, 0.36, 0.54, 0.72, 0.9], (38, 30.5))
    else:
        lines = sat_veins(poly, CEH_OUTER, (21, 6), (17, 17), [0.06, 0.24, 0.42, 0.6, 0.78, 0.94], (12, 37))
    r = np.hypot(w.X, w.Z)
    do = w.dist(outer)
    k = 1.25 if under else 1.0
    col = np.zeros(w.X.shape + (3,), np.float32)
    frost = smooth(-0.6, 1.2, w.noise * 1.4 + np.sin(w.X * 11.0 + w.Z * 7.0) * 0.3)
    col[:] = CE_BROWN * k
    col = mix(col, CE_FROST, frost * (0.45 if not under else 0.55))
    # the base red
    col = mix(col, CE_RED * 0.9, (1 - smooth(5, 11, r + w.noise)) * (0.85 if not under else 0.5))
    # the white band, red-orange on its outer side
    if fore:
        band = [(35, -9.5), (33.5, 0), (31.5, 10), (31, 20), (32.5, 31)]
    else:
        band = [(24, -2.0), (25, 8), (23.5, 18), (19, 28), (14.5, 37), (12, 41)]
    db = w.dist(band)
    side = np.sign(w.X - np.interp(w.Z, [p[1] for p in band], [p[0] for p in band]))
    col = mix(col, CE_ORANGE, (1 - smooth(2.6, 3.2, db)) * (side > 0))
    col = mix(col, CE_WHITE, 1 - smooth(1.1, 1.5, db))
    # beyond it, the pale tan zone, a dark wavy line through it, the margin grey
    beyond = (side > 0) * smooth(3.0, 3.6, db)
    col = mix(col, CE_TAN, beyond * 0.75)
    mxz = (sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))
    ang = np.arctan2(w.Z - mxz[1], w.X - mxz[0])  # (round the wing: the line's waves along its margin)
    wave = np.abs(do - 5.8 - 1.1 * np.abs(np.sin(ang * (9.0 if fore else 7.0))))
    col = mix(col, CE_BROWN * 0.8, (1 - smooth(0.35, 0.7, wave)) * beyond)
    col = mix(col, CE_FROST * 0.85, (1 - smooth(1.5, 2.2, do)) * 0.7)
    # the cell's crescent: white, edged red
    cc, rr = ((27.5, 1.5), (2.4, 5.0)) if fore else ((18.5, 11.5), (2.6, 5.6))
    dx, dz = (w.X - cc[0]) / rr[0], (w.Z - cc[1]) / rr[1]
    d = np.hypot(dx, dz)
    cut = np.hypot(dx + 0.65, dz) > 0.75  # (a crescent: its inner side cut away)
    col = mix(col, CE_RED, (1 - smooth(1.15, 1.35, d)) * smooth(0.6, 0.8, np.hypot(dx + 0.65, dz)))
    col = mix(col, CE_WHITE, (1 - smooth(0.9, 1.05, d)) * cut)
    if fore:  # (its tip: lilac, the eyespot, the zigzag)
        tip = smooth(50, 58, w.X + w.noise)
        col = mix(col, CE_LILAC, tip * 0.85)
        e = np.hypot((w.X - 58.5) / 2.6, (w.Z - 0.6) / 2.0)
        col = mix(col, CE_BLACK, 1 - smooth(0.9, 1.05, e))
        col = mix(col, CE_BLUE, (1 - smooth(0.55, 0.7, np.hypot((w.X - 58.0) / 2.6, (w.Z - 1.2) / 2.0))) * smooth(0.25, 0.45, np.hypot((w.X - 58.6) / 2.6, (w.Z - 0.4) / 2.0)))
        zz = np.abs(w.Z - 4.5 + 1.6 * np.abs(((w.X - 50) / 2.2) % 2 - 1))
        col = mix(col, CE_WHITE, (1 - smooth(0.25, 0.5, zz)) * smooth(49, 51, w.X) * (1 - smooth(57, 59, w.X)))
        col = mix(col, CE_RED * 0.9, (1 - smooth(0.7, 1.0, w.dist(costa))) * (1 - smooth(10, 14, w.X)))
    return w, col, np.ones(w.X.shape, np.float32)


# ---- the polyphemus moth (Antheraea polyphemus) -------------------------------------
# tawny orange-brown; the forewing's costa dusted grey, a pink-white line
# near its base edged red, a small round eyespot (a clear window ringed
# yellow, black) at its cell, a pink-white line beyond edged dark, its tip
# with a small dark mark; the hindwing's great eyespot (a clear window, a
# yellow ring, black with a blue arc above, a black blotch round it, a
# pink rim), a dark band beyond and a pink-white line, the margin tawny.

PO_TAWNY = c("c07a4a")
PO_TAWNY_D = c("9a5a34")
PO_GREY = c("8d8178")
PO_PINK = c("ecc8bd")
PO_RED = c("8c3328")
PO_YELLOW = c("e8c34a")
PO_BLACK = c("1a1310")
PO_BLUE = c("6f86b8")
PO_WINDOW = c("e4dccb")

POLY_FORE = [(0, -1.9), (9, -5.4), (20, -7.6), (33, -8.4), (44, -7.6), (52, -5.6), (57, -2.4), (58.4, 1.2), (56, 7),
             (51.5, 13.5), (46.5, 20), (42, 25.5), (37.5, 28.4), (28, 25.4), (18.5, 19), (10, 12), (3.8, 5.6), (0, 1.4)]
POF_COSTA = (0, 7)
POF_OUTER = (7, 13)
POF_INNER = (13, 18)

POLY_HIND = [(0, -1.2), (11, -2.4), (22, -0.8), (31, 3.6), (37, 9.6), (39.4, 17), (38.4, 25), (35, 31.5), (29, 36.2),
             (21.5, 38.2), (14, 36.6), (7.6, 31.2), (3.4, 23.6), (0.8, 13.6), (0, 5)]
POH_COSTA = (0, 3)
POH_OUTER = (3, 11)
POH_INNER = (11, 15)


def paint_polyphemus(fore, under):
    poly = POLY_FORE if fore else POLY_HIND
    spans = (POF_COSTA, POF_OUTER, POF_INNER) if fore else (POH_COSTA, POH_OUTER, POH_INNER)
    w = Wing(poly)
    costa, outer, inner = (run(poly, s) for s in spans)
    if fore:
        lines = sat_veins(poly, (5, 13), (27, -3.0), (24, 6), [0.0, 0.18, 0.36, 0.54, 0.72, 0.9], (34, 27.5))
    else:
        lines = sat_veins(poly, POH_OUTER, (19, 6), (15, 16), [0.06, 0.24, 0.42, 0.6, 0.78, 0.94], (11, 34))
    r = np.hypot(w.X, w.Z)
    do = w.dist(outer)
    col = np.zeros(w.X.shape + (3,), np.float32)
    col[:] = PO_TAWNY * (1.08 if under else 1.0)
    col = mix(col, PO_TAWNY_D, smooth(-0.5, 1.5, w.noise) * 0.35)
    col = mix(col, PO_TAWNY * 1.12, (1 - smooth(0.2, 0.45, w.dist_all(lines))) * 0.25)
    k = 0.55 if under else 1.0
    if fore:
        col = mix(col, PO_GREY, (1 - smooth(2.0, 4.0, w.dist(costa) + w.noise * 0.5)) * 0.85)  # (the costa dusted grey)
        base = [(6.5, -4.6), (8, 0), (7.5, 5), (6, 9.5)]
        dbase = w.dist(base)
        col = mix(col, PO_RED, (1 - smooth(1.3, 1.7, dbase)) * (w.X > np.interp(w.Z, [p[1] for p in base], [p[0] for p in base])) * k)
        col = mix(col, PO_PINK, (1 - smooth(0.55, 0.85, dbase)) * k)
        post = [(45, -7.5), (42.5, 0), (40, 8), (37.5, 16), (35.5, 24), (35, 28)]
        dp = w.dist(post)
        inside = w.X < np.interp(w.Z, [p[1] for p in post], [p[0] for p in post])
        col = mix(col, PO_TAWNY_D * 0.7, (1 - smooth(1.0, 1.4, dp)) * inside * k)
        col = mix(col, PO_PINK, (1 - smooth(0.5, 0.8, dp)) * (~inside) * k)
        col = mix(col, PO_GREY, smooth(4.0, 9.0, -do + 12.0) * (1 - smooth(1.5, 3.0, do)) * 0.0)
        # the eyespot: small, round
        e = np.hypot(w.X - 27.5, w.Z - 1.5)
        col = mix(col, PO_BLACK, (1 - smooth(3.0, 3.3, e)) * k)
        col = mix(col, PO_YELLOW, (1 - smooth(2.5, 2.8, e)) * k)
        col = mix(col, PO_WINDOW, (1 - smooth(1.4, 1.7, e)) * k)
        win = (1 - smooth(1.4, 1.7, e)) * k
        # its tip: a small dark mark and pink
        t = np.hypot(w.X - 54, w.Z + 2.6)
        col = mix(col, PO_PINK, (1 - smooth(2.6, 3.4, t)) * 0.6)
        col = mix(col, PO_BLACK, (1 - smooth(1.0, 1.3, np.hypot(w.X - 55, w.Z + 2.2))) * k)
    else:
        # the great eyespot: a black blotch, blue above, a yellow ring, a clear window, a pink rim
        ec = (20.5, 15.0)
        e = np.hypot((w.X - ec[0]) / 1.05, w.Z - ec[1])
        col = mix(col, PO_PINK, (1 - smooth(8.2, 8.8, e)) * smooth(7.0, 7.6, e) * 0.7 * k)
        col = mix(col, PO_BLACK, (1 - smooth(7.0, 7.6, e + w.noise * 0.3)) * k)
        blue = (1 - smooth(5.6, 6.0, e)) * smooth(4.5, 4.9, e) * smooth(1.0, -2.0, w.Z - ec[1])
        col = mix(col, PO_BLUE, blue * k)
        col = mix(col, PO_YELLOW, (1 - smooth(4.0, 4.3, e)) * k)
        col = mix(col, PO_WINDOW, (1 - smooth(2.6, 2.9, e)) * k)
        win = (1 - smooth(2.6, 2.9, e)) * k
        # the dark band beyond, and its pink line
        band = [(30.5, 1.5), (31.5, 10), (31, 19), (28, 26.5), (22, 30.5), (14, 30), (7, 26)]
        dd = w.dist(band)
        col = mix(col, PO_BLACK * 1.4, (1 - smooth(1.4, 1.9, dd)) * k)
        b2 = [(p[0] + (p[0] - 18) * 0.12, p[1] + (p[1] - 13) * 0.14) for p in band]
        col = mix(col, PO_PINK, (1 - smooth(0.7, 1.0, w.dist(b2))) * k)
    a = np.ones(w.X.shape, np.float32) - win * 0.4
    return w, col, a


# ---- the atlas -----------------------------------------------------------------

def bleed_outside(rgb, cover):
    """Fills outside the wing with the nearest wing colour (for mipmaps)."""
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    mask = Image.fromarray((cover > 0.5).astype(np.uint8) * 255)
    filled = np.asarray(img, np.float32)
    have = cover > 0.5
    for r in (2, 5, 11, 23, 47):
        blur = np.asarray(img.filter(ImageFilter.GaussianBlur(r)), np.float32)
        m = np.asarray(mask.filter(ImageFilter.GaussianBlur(r)), np.float32)
        b = blur * 255.0 / np.maximum(m[..., None], 1e-3)
        known = m > 8
        filled = np.where((~have & known)[..., None], np.clip(b, 0, 255), filled)
        have = have | known
        img = Image.fromarray(filled.astype(np.uint8))
        mask = Image.fromarray(have.astype(np.uint8) * 255)
    return filled / 255.0


def hull(pts):
    """The convex hull, walking as the outlines do (clockwise seen from
    above: x right, z down)."""
    p = sorted(set(pts))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, hi = [], []
    for q in p:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], q) <= 0:
            lo.pop()
        lo.append(q)
    for q in reversed(p):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], q) <= 0:
            hi.pop()
        hi.append(q)
    h = lo[:-1] + hi[:-1]
    # (the outlines' way round: the fan's cross products positive)
    mx = sum(q[0] for q in h) / len(h)
    mz = sum(q[1] for q in h) / len(h)
    a0, b0 = h[0], h[1]
    if (a0[0] - mx) * (b0[1] - mz) - (a0[1] - mz) * (b0[0] - mx) < 0:
        h.reverse()
    return h


def down(a):
    n = a.shape[0] // SS
    return a.reshape(n, SS, n, SS, *a.shape[2:]).mean(axis=(1, 3))


def main():
    atlas = np.zeros((ROWS * CELL, COLS * CELL, 4), np.float32)
    jobs = [  # (cell, painting, name, under cell or None)
        (0, lambda: paint_monarch_fore(False), "monarch_fore", 1),
        (1, lambda: paint_monarch_fore(True), None, None),
        (2, lambda: paint_monarch_hind(False), "monarch_hind", 3),
        (3, lambda: paint_monarch_hind(True), None, None),
        (4, lambda: paint_hemaris(HEMARIS_FORE, (HF_COSTA, HF_OUTER, HF_INNER), hemaris_fore_veins, 1.35, 0.7, 5.5), "hemaris_fore", None),
        (5, lambda: paint_hemaris(HEMARIS_HIND, (HH_COSTA, HH_OUTER, HH_INNER), hemaris_hind_veins, 1.1, 1.6, 3.2), "hemaris_hind", None),
        (6, lambda: paint_sw_fore(False), "swallowtail_fore", 7),
        (7, lambda: paint_sw_fore(True), None, None),
        (8, lambda: paint_sw_hind(False), "swallowtail_hind", 9),
        (9, lambda: paint_sw_hind(True), None, None),
        (10, lambda: paint_luna(LUNA_FORE, (LF_COSTA, LF_OUTER, LF_INNER), luna_fore_veins, (25.5, 1.4), (4.4, 6.2), -0.35, True, False), "luna_fore", 11),
        (11, lambda: paint_luna(LUNA_FORE, (LF_COSTA, LF_OUTER, LF_INNER), luna_fore_veins, (25.5, 1.4), (4.4, 6.2), -0.35, True, True), None, None),
        (12, lambda: paint_luna(LUNA_HIND, (LH_COSTA, LH_OUTER, LH_INNER), luna_hind_veins, (18.6, 11.2), (5.2, 6.6), 0.2, False, False), "luna_hind", 13),
        (13, lambda: paint_luna(LUNA_HIND, (LH_COSTA, LH_OUTER, LH_INNER), luna_hind_veins, (18.6, 11.2), (5.2, 6.6), 0.2, False, True), None, None),
        (14, lambda: paint_cloak(CLOAK_FORE, (CF_COSTA, CF_OUTER, CF_INNER), cloak_fore_veins, True, False), "cloak_fore", 15),
        (15, lambda: paint_cloak(CLOAK_FORE, (CF_COSTA, CF_OUTER, CF_INNER), cloak_fore_veins, True, True), None, None),
        (16, lambda: paint_cloak(CLOAK_HIND, (CH_COSTA, CH_OUTER, CH_INNER), cloak_hind_veins, False, False), "cloak_hind", 17),
        (17, lambda: paint_cloak(CLOAK_HIND, (CH_COSTA, CH_OUTER, CH_INNER), cloak_hind_veins, False, True), None, None),
        (18, lambda: paint_cecropia(True, False), "cecropia_fore", 19),
        (19, lambda: paint_cecropia(True, True), None, None),
        (20, lambda: paint_cecropia(False, False), "cecropia_hind", 21),
        (21, lambda: paint_cecropia(False, True), None, None),
        (22, lambda: paint_polyphemus(True, False), "polyphemus_fore", 23),
        (23, lambda: paint_polyphemus(True, True), None, None),
        (24, lambda: paint_polyphemus(False, False), "polyphemus_hind", 25),
        (25, lambda: paint_polyphemus(False, True), None, None),
    ]
    HULL = {"swallowtail_fore", "swallowtail_hind", "luna_fore", "luna_hind", "cloak_fore", "cloak_hind"}  # (their meshes the outline's hull: the texture cuts the rest)
    wings = {}
    for cell, paint, name, under in jobs:
        w, col, a = paint()
        col = col * (1.0 + 0.045 * w.noise[..., None])  # (the scales' sheen, uneven)
        cover = down(w.inside)
        alpha = down(w.inside * a) / np.maximum(cover, 1e-4) * cover
        rgb = down(col * w.inside[..., None]) / np.maximum(cover[..., None], 1e-4)
        rgb = bleed_outside(rgb, cover)
        cx, cy = cell % COLS, cell // COLS
        atlas[cy * CELL:(cy + 1) * CELL, cx * CELL:(cx + 1) * CELL, :3] = rgb
        atlas[cy * CELL:(cy + 1) * CELL, cx * CELL:(cx + 1) * CELL, 3] = alpha
        if name:
            # the mesh's outline, grown from its middle a little (the
            # texture's soft edge inside it); uv from mm
            poly = hull(w.poly) if name in HULL else w.poly
            mx = sum(p[0] for p in poly) / len(poly)
            mz = sum(p[1] for p in poly) / len(poly)
            grown = []
            for p in poly:
                d = math.hypot(p[0] - mx, p[1] - mz)
                grown.append((p[0] + (p[0] - mx) / d * GROW, p[1] + (p[1] - mz) / d * GROW))
            # (a fan from the middle: each triangle must turn clockwise)
            for i in range(len(grown)):
                a0, b0 = grown[i], grown[(i + 1) % len(grown)]
                cr = (a0[0] - mx) * (b0[1] - mz) - (a0[1] - mz) * (b0[0] - mx)
                assert cr > 0, (name, i, cr)
            ox = cx * CELL + w.off[0] - w.x0 * w.scale
            oy = cy * CELL + w.off[1] - w.z0 * w.scale
            wings[name] = {
                "outline": grown, "middle": (mx, mz),
                "uv_origin": (ox / (COLS * CELL), oy / (ROWS * CELL)),
                "uv_per_mm": (w.scale / (COLS * CELL), w.scale / (ROWS * CELL)),
                "under": ((under - cell) * CELL / (COLS * CELL), 0.0) if under is not None else (0.0, 0.0),
            }
    os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
    Image.fromarray((np.clip(atlas, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT_PNG, optimize=True)
    with open(OUT_GD, "w") as f:
        f.write("extends RefCounted\n")
        f.write("## The butterflies' and moths' wings (Lepidoptera): each one's outline (mm,\n")
        f.write("## its hinge at the origin, x out along it, z back; the right wing; walking\n")
        f.write("## clockwise seen from above, a fan from `middle`), and where a point (mm)\n")
        f.write("## is on data/creatures/lepidoptera_wings.png: uv_origin + p * uv_per_mm\n")
        f.write("## (its underside's: + under). Written by\n")
        f.write("## tools/creatures/bake_lepidoptera_wings.py: don't edit it by hand.\n\n")
        f.write("const WINGS := {\n")
        for name, d in wings.items():
            pts = ", ".join(f"Vector2({p[0]:.3f}, {p[1]:.3f})" for p in d["outline"])
            f.write(f'\t"{name}": {{\n')
            f.write(f'\t\t"outline": [{pts}],\n')
            f.write(f'\t\t"middle": Vector2({d["middle"][0]:.4f}, {d["middle"][1]:.4f}),\n')
            f.write(f'\t\t"uv_origin": Vector2({d["uv_origin"][0]:.6f}, {d["uv_origin"][1]:.6f}),\n')
            f.write(f'\t\t"uv_per_mm": Vector2({d["uv_per_mm"][0]:.7f}, {d["uv_per_mm"][1]:.7f}),\n')
            f.write(f'\t\t"under": Vector2({d["under"][0]:.4f}, {d["under"][1]:.4f}),\n')
            f.write("\t},\n")
        f.write("}\n")
    print("wrote", OUT_PNG, OUT_GD)


if __name__ == "__main__":
    main()
