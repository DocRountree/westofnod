shader_type spatial;
render_mode cull_disabled;

// A plant far off (PlantMesh.levels: its last level of detail, to its
// view's end): its card, the photograph its material carries (atlas, frame;
// OakTree._impostor, ImpostorBaker). The card itself: impostor.gdshaderinc.

#include "res://shaders/render/impostor.gdshaderinc"
