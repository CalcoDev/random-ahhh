shader_type canvas_item;

uniform sampler2D u_input_tex;

void fragment() {
	vec4 scene_col = texture(u_input_tex, UV);
	COLOR = vec4(UV.x * scene_col.a, UV.y * scene_col.a, 0.0, 1.0);
}