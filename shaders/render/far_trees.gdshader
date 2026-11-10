shader_type spatial;
render_mode cull_disabled;

// The standing trees far off (FarTrees: from where each one's last level of
// detail ends, 250 m, out to the tree render distance): each a card, a cell
// of the map's (512 m) all drawn at once whatever their species, each
// tree's photograph a layer of one album (its number the instance's custom
// data; where its card stands and how far it's drawn, that layer's texel
// of cards). The card itself: impostor.gdshaderinc.

#define FAR_TREES
#include "res://shaders/render/impostor.gdshaderinc"
