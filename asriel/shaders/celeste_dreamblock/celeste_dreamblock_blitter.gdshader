shader_type canvas_item;

uniform sampler2D u_dreamblock_tex: filter_nearest;
uniform sampler2D u_mask: filter_nearest;

void fragment() {
    vec4 block = texture(u_dreamblock_tex, UV);
    vec4 mask = texture(u_mask, UV);
    COLOR = vec4(block.rgb, mask.a);
}
