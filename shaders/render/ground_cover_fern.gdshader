shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

// Ferns (GroundCover): their frond texture cut out (alpha scissor), and
// stippled as they come and go (ground_cover_draw.gdshaderinc).

#define FERN
#include "res://shaders/render/ground_cover_draw.gdshaderinc"
