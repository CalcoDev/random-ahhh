shader_type canvas_item;

uniform sampler2D u_room_color_tex;
uniform sampler2D u_room_lightmask_tex;

uniform sampler2D u_preview_lightmask_tex;

void fragment() {
	vec4 color = texture(u_room_color_tex, UV) * COLOR;
    vec4 preview_lightmask = texture(u_preview_lightmask_tex, UV);
    if (preview_lightmask.r + preview_lightmask.g + preview_lightmask.b < 0.01) {
        discard;
    }
    COLOR = color;
}