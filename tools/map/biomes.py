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

# island: (longitude, latitude of its middle), and a rule (lon, lat) -> biome
def _isabela(lon, lat):
    if lat > -14.0:
        return MESA                                  # the long northern arm
    coast = -33.0 + (lon + 150.0) * 0.178            # (along the southern lobe's north shore)
    return PLAINS if lat > coast - 1.0 else FOREST


def _santiago(lon, lat):
    return PLAINS if lon > -33.0 else FOREST


def _santa_cruz(lon, lat):
    if lon > 13.0:
        return PLAINS                                # the east end
    if (lon - 12.5) ** 2 + (lat + 26.0) ** 2 < 12.0:
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
