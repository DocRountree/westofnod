class_name BlueWingedGrasshopper
extends "res://scripts/creatures/grasshopper.gd" # (by path: found whether or not the editor has seen the class yet)
## A blue-winged grasshopper (Saussure's, Leprus intermedius: one of the
## band-winged grasshoppers of the dry Southwest), on the differential
## grasshopper's model and ways (Grasshopper: walking, feeding, the hop, the
## flight, laying its pod, mating), a little smaller (0.8 of it), drawn at
## twice life size. Mottled brown, the colour of the gravel it sits on: its
## head and pronotum brown, freckled darker; its forewings (tegmina) tan,
## netted with fine veins, crossed by dark brown bands, their tips clear;
## its hindwings, fanned out as it flies, sky blue at their roots, a broad
## near-black band round them, their outer edge clear and netted; its hind
## femur brown, barred darker, its hind tibia blue. A nymph mottled brown,
## paler, only little wing pads.


func _init(nymph_ := false, size_ := 1.0) -> void:
	super(nymph_, size_ * 0.8)


func _colors() -> Dictionary:
	var brown := Color(0.46, 0.33, 0.2) if not nymph else Color(0.55, 0.43, 0.3)
	return {"body": brown, "eye": Color(0.36, 0.28, 0.17), "antenna": Color(0.4, 0.26, 0.15),
			"femur": brown.lightened(0.08), "femur_mark": Color(0.16, 0.11, 0.07),
			"tibia": Color(0.32, 0.43, 0.7) if not nymph else Color(0.5, 0.5, 0.52), "abdomen": Color(0.26, 0.22, 0.17)}


static var _fore_sh: Shader
static var _hind_sh: Shader


## Its tegmen: tan, veined, two dark crossbands, the tip clear (on the
## wing's ellipsoid: local z -0.5 its root .. 0.5 its tip).
func _forewing_mat() -> Material:
	if _fore_sh == null:
		_fore_sh = Shader.new()
		_fore_sh.code = """shader_type spatial;
render_mode cull_disabled;
varying vec3 o;
void vertex() { o = VERTEX; }
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float t = o.z + 0.5;
	vec3 tan = vec3(0.64, 0.5, 0.31);
	vec3 band = vec3(0.27, 0.17, 0.09);
	float mott = h(floor(o.xz * vec2(40.0, 160.0)));
	vec3 c = tan * (0.85 + 0.25 * mott);
	float b = smoothstep(0.26, 0.3, t) * (1.0 - smoothstep(0.38, 0.42, t)) + smoothstep(0.52, 0.56, t) * (1.0 - smoothstep(0.65, 0.69, t));
	b += 0.6 * smoothstep(0.08, 0.1, t) * (1.0 - smoothstep(0.16, 0.18, t));
	c = mix(c, band, clamp(b, 0.0, 1.0) * 0.85);
	// (veins: a fine net)
	vec2 g = fract(o.xz * vec2(26.0, 110.0));
	float vein = max(1.0 - smoothstep(0.0, 0.12, min(g.x, 1.0 - g.x)), 1.0 - smoothstep(0.0, 0.1, min(g.y, 1.0 - g.y)));
	c = mix(c, c * 0.55, vein * 0.5);
	float clear = smoothstep(0.78, 0.86, t);
	ALBEDO = mix(c, vec3(0.86, 0.84, 0.78), clear * (1.0 - vein * 0.6));
	ALPHA = mix(1.0, 0.35 + 0.5 * vein, clear);
	ROUGHNESS = 0.55;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _fore_sh
	return m


## Its hindwing (side -1 left, 1 right): out from its root in a fan, sky
## blue, a broad near-black band round it, its outer edge clear; veined,
## radiating, netted between (on the wing's ellipsoid: its root at local
## x -0.5 x side, z -0.41).
func _hindwing_mat(side: float) -> Material:
	if _hind_sh == null:
		_hind_sh = Shader.new()
		_hind_sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform float side = 1.0;
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	vec2 q = vec2((o.x * side + 0.5) * 24.0, (o.z + 0.41) * 17.0); // (mm from its root: out, back)
	float r = length(q) / 24.0;
	float a = atan(q.y, q.x);
	vec3 blue = vec3(0.56, 0.8, 0.9);
	vec3 band = vec3(0.11, 0.09, 0.07);
	vec3 c = mix(blue, blue * 0.85, smoothstep(0.1, 0.5, r));
	float in_band = smoothstep(0.5, 0.56, r) * (1.0 - smoothstep(0.8, 0.85, r));
	c = mix(c, band, in_band);
	float clear = smoothstep(0.82, 0.88, r);
	// (its veins: rays out from the root, cross veins between)
	float ray = 1.0 - smoothstep(0.0, 0.08, abs(fract(a * 9.0) - 0.5) * 2.0 - 0.9);
	float cross = 1.0 - smoothstep(0.0, 0.1, abs(fract(r * 34.0) - 0.5) * 2.0 - 0.85);
	float vein = clamp(max(ray, cross * 0.7), 0.0, 1.0);
	c = mix(c, c * 0.6 + vec3(0.02), vein * 0.45);
	ALBEDO = mix(c, vec3(0.82, 0.82, 0.8), clear * (1.0 - vein * 0.5));
	ALPHA = mix(mix(0.9, 1.0, in_band), 0.2 + 0.55 * vein, clear);
	ROUGHNESS = 0.35;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _hind_sh
	m.set_shader_parameter("side", side)
	return m
