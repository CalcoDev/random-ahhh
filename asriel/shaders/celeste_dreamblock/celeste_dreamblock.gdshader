shader_type canvas_item;

uniform sampler2D u_tex: repeat_enable, filter_nearest;
uniform float u_aspect_ratio;
uniform vec2 u_tiling;
uniform vec2 u_offset;

void fragment() {
    vec2 uv = UV * u_tiling + u_offset;
    uv.x *= u_aspect_ratio;
    COLOR = texture(u_tex, uv);
}