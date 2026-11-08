shader_type spatial;
render_mode cull_disabled, depth_draw_always;

// A snake's cast skin (Snake.shed): its body's skin left where it was,
// pale, papery, see-through (snake_body.gdshaderinc, SHED).

#define SHED
#include "res://shaders/render/snake_body.gdshaderinc"
