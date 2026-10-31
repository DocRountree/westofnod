"""Biome assignments for the islands (for the map only, for now: nothing in
the game or the bake uses them yet). Drawn by hand from a sketch, as rules in
the planet's latitude and longitude (degrees; see main.gd: x is longitude,
z latitude, the map's top edge 90 N).

Each island is matched by where its middle lies; within an island a few
lines split it. Islands not listed (the three northern ones, Baltra and the
Seymours, the islets) have no biome yet.
"""
FOREST, MESA, PLAINS, SWAMP, TUNDRA = "forest", "mesa", "plains", "swamp", "tundra"
TAIGA, PLATEAU, VOLCANO, MOUNTAINS = "taiga", "plateau", "volcano", "mountains"
COLOURS = {FOREST: (90, 255, 0), MESA: (255, 240, 0), PLAINS: (255, 0, 140), SWAMP: (30, 140, 125),
           TUNDRA: (205, 230, 240), TAIGA: (20, 95, 60), PLATEAU: (205, 120, 45), VOLCANO: (130, 20, 25),
           MOUNTAINS: (150, 95, 60)}
# Mountains take their biome from what surrounds them (the most common biome
# in a ring round each range): plains, forest or swamp make taiga; mesa, a
# plateau; tundra, a volcano. Ranges with nothing assigned round them stay
# plain mountains.
MOUNTAIN_BY_SURROUNDINGS = {PLAINS: TAIGA, FOREST: TAIGA, SWAMP: TAIGA, MESA: PLATEAU, TUNDRA: VOLCANO}
RING_KM = 2.0
# Mountains are their own biome, wherever the ground (smoothed over a few
# hundred metres) stands this high, whatever the island's biome around them.
MOUNTAIN_HEIGHT = 330.0

import math


def _hash(i, j):
    return math.modf(abs(math.sin(i * 127.1 + j * 311.7) * 43758.5453))[0]


def _vnoise(x, y):
    i, j = math.floor(x), math.floor(y)
    fx, fy = x - i, y - j
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = _hash(i, j), _hash(i + 1, j)
    c, d = _hash(i, j + 1), _hash(i + 1, j + 1)
    return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy


def fractal(lon, lat, salt=0.0):
    """Degrees to move a boundary by here: fractal noise (each octave half the
    size and half the strength of the last), so the line is ragged at every
    scale, like a coastline."""
    w, scale, amp = 0.0, 8.0, 2.5
    for k in range(6):
        w += (_vnoise(lon / scale + salt * 13.1 + k * 5.3, lat / scale - salt * 7.7 - k * 3.1) - 0.5) * 2.0 * amp
        scale *= 0.5
        amp *= 0.5
    return w


# island: (longitude, latitude of its middle), and a rule
# (lon, lat, km from the nearest mountains) -> biome
def _isabela(lon, lat, mountain_km):
    if lat + fractal(lon, lat, 1.0) > -14.0:
        return _ringed(lon, lat, mountain_km)       # the long northern arm
    return MESA                                      # the southern lobe


def _ringed(lon, lat, mountain_km):
    # a ring of forest round the mountains, plains from there to the sea
    return FOREST if mountain_km + fractal(lon, lat, 3.0) * 0.8 < 3.5 else PLAINS


def _santiago(lon, lat, mountain_km):
    return _ringed(lon, lat, mountain_km)


def _santa_cruz(lon, lat, mountain_km):
    return _ringed(lon, lat, mountain_km)


ISLANDS = {
    "Isabela": ((-110.0, -10.0), _isabela),
    "Fernandina": ((-150.0, 2.0), lambda lon, lat, mountain_km: FOREST),
    "Santiago": ((-30.0, 8.0), _santiago),
    "Rabida": ((-36.0, -2.0), lambda lon, lat, mountain_km: FOREST),
    "Pinzon": ((-28.0, -16.0), lambda lon, lat, mountain_km: FOREST),
    "Santa Cruz": ((10.0, -16.0), _santa_cruz),
    "Santa Fe": ((52.0, -30.0), lambda lon, lat, mountain_km: FOREST),
    "San Cristobal": ((145.0, -31.0), lambda lon, lat, mountain_km: FOREST),
    "Floreana": ((2.0, -63.0), lambda lon, lat, mountain_km: FOREST),
    "Espanola": ((110.0, -70.0), lambda lon, lat, mountain_km: FOREST),
}
MATCH_DEG = 12.0

# Swamps, over whatever island biome is there (mountains still win): bands
# along a line (lon, lat to lon, lat), half_width km, edges fractal.
# On Santa Cruz: where the (since dropped) river ran, from 2.5 km above the
# spawn point down through it to the nearest coast.
SWAMPS = [((17.33, -20.88), (21.16, -25.44), 2.6)]
KM_PER_DEG = (281.0 / 360.0, 281.0 / 180.0)   # longitude, latitude


TUNDRA_LAT = 45.0   # all land north of this (edge fractal) is tundra


def tundra(lon, lat):
    return lat + fractal(lon, lat, 7.0) > TUNDRA_LAT


def swamp(lon, lat):
    """Whether (lon, lat) lies in a swamp."""
    for (a, b, half) in SWAMPS:
        px, pz = (lon - a[0]) * KM_PER_DEG[0], (lat - a[1]) * KM_PER_DEG[1]
        dx, dz = (b[0] - a[0]) * KM_PER_DEG[0], (b[1] - a[1]) * KM_PER_DEG[1]
        t = max(0.0, min(1.0, (px * dx + pz * dz) / (dx * dx + dz * dz)))
        d = math.hypot(px - t * dx, pz - t * dz)
        if d + fractal(lon, lat, 6.0) * 0.8 < half:
            return True
    return False     # how near an island's middle must be to its entry
