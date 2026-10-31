"""Biome assignments for the islands (for the map only, for now: nothing in
the game or the bake uses them yet). Drawn by hand from a sketch, as rules in
the planet's latitude and longitude (degrees; see main.gd: x is longitude,
z latitude, the map's top edge 90 N).

Each island is matched by where its middle lies; within an island a few
lines split it. Islands not listed (the three northern ones, Baltra and the
Seymours, the islets) have no biome yet.
"""
FOREST, MESA, PLAINS, MOUNTAINS = "forest", "mesa", "plains", "mountains"
COLOURS = {FOREST: (90, 255, 0), MESA: (255, 240, 0), PLAINS: (255, 0, 140), MOUNTAINS: (150, 95, 60)}
# Mountains are their own biome, wherever the ground (smoothed over a few
# hundred metres) stands this high, whatever the island's biome around them.
MOUNTAIN_HEIGHT = 400.0

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


# island: (longitude, latitude of its middle), and a rule (lon, lat) -> biome
def _isabela(lon, lat):
    if lat + fractal(lon, lat, 1.0) > -14.0:
        return MESA                                  # the long northern arm
    coast = -37.0 + (lon + 150.0) * 0.178            # (along the southern lobe's north shore: plains above)
    return PLAINS if lat + fractal(lon, lat, 2.0) > coast else FOREST


def _santiago(lon, lat):
    return PLAINS if lon + fractal(lon, lat, 3.0) > -33.0 else FOREST


def _santa_cruz(lon, lat):
    if lon + fractal(lon, lat, 4.0) > 13.0:
        return PLAINS                                # the east end
    if math.hypot(lon - 12.5, lat + 26.0) + fractal(lon, lat, 5.0) * 0.6 < 3.5:
        return PLAINS                                # a patch on the south shore
    return FOREST


ISLANDS = {
    "Isabela": ((-110.0, -10.0), _isabela),
    "Fernandina": ((-150.0, 2.0), lambda lon, lat: FOREST),
    "Santiago": ((-30.0, 8.0), _santiago),
    "Rabida": ((-36.0, -2.0), lambda lon, lat: FOREST),
    "Pinzon": ((-28.0, -16.0), lambda lon, lat: FOREST),
    "Santa Cruz": ((10.0, -16.0), _santa_cruz),
    "Santa Fe": ((52.0, -30.0), lambda lon, lat: FOREST),
    "San Cristobal": ((145.0, -31.0), lambda lon, lat: FOREST),
    "Floreana": ((2.0, -63.0), lambda lon, lat: FOREST),
    "Espanola": ((110.0, -70.0), lambda lon, lat: FOREST),
}
MATCH_DEG = 12.0     # how near an island's middle must be to its entry
