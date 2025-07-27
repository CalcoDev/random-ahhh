shader_type canvas_item;

uniform sampler2D u_negative_texture;

void fragment() {
	vec4 read_col = texture(u_negative_texture, UV);
    COLOR = vec4(0.f) + read_col;
}
