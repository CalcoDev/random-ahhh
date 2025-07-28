shader_type canvas_item;

uniform sampler2D u_tex: repeat_enable, filter_nearest;
uniform float u_aspect_ratio;
uniform vec2 u_tiling;
uniform vec2 u_offset;

void fragment() {
    float timestep = step(0.0f, sin(TIME * PI * 4.0f));

    vec2 uv = UV * u_tiling + u_offset;
    uv.x *= u_aspect_ratio;
    vec4 colour = texture(u_tex, uv);

    vec2 pixelstep = TEXTURE_PIXEL_SIZE;
    vec2 uv_top = vec2(uv.x, uv.y + pixelstep.y);
    vec2 uv_bottom = vec2(uv.x, uv.y - pixelstep.y);
    vec2 uv_left = vec2(uv.x - pixelstep.x, uv.y);
    vec2 uv_right = vec2(uv.x + pixelstep.x, uv.y);

    vec4 c_top = texture(u_tex, uv_top);
    vec4 c_bottom = texture(u_tex, uv_bottom);
    vec4 c_left = texture(u_tex, uv_left);
    vec4 c_right = texture(u_tex, uv_right);

    vec4 circle = c_top + c_bottom + c_left + c_right;
    vec4 outer_only = clamp(circle, 0.0, 1.0);

    COLOR = (colour + timestep * outer_only) * .6;
}
