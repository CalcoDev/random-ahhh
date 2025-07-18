shader_type canvas_item;

uniform sampler2D u_prev_tex;
uniform vec2 u_pos = vec2(0.0); // UV
uniform float u_size = 10.0;
	uniform vec4 u_draw_col: source_color = vec4(1.0, 0.0, 0.0, 1.0); // red

void fragment() {
    vec4 old_color = texture(u_prev_tex, UV);

    float dist = distance(UV, u_pos);
	if (dist < u_size / 240.0) {
		COLOR = u_draw_col;
	} else {
		COLOR = old_color;
	}
}
