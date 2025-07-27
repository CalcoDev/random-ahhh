shader_type canvas_item;

uniform sampler2D u_tex;

void fragment() {
	COLOR = texture(u_tex, UV);
}