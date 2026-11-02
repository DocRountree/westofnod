// The floating origin (scripts/world/origin.gd): what is drawn is drawn near
// the origin, the map's own coordinates shifted by world_origin (a whole
// number of km, x and z only). A drawn position (MODEL_MATRIX's, VERTEX in
// world space, CAMERA_POSITION_WORLD) + world_origin = its place on the map;
// anything that goes by the map (the height map, biomes, noise, hashes, wind)
// takes the map's, so nothing changes when the origin moves.

#ifndef ORIGIN_INC
#define ORIGIN_INC

global uniform vec3 world_origin;

#endif
