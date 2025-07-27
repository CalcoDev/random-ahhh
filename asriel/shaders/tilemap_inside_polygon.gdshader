shader_type canvas_item;

uniform sampler2D u_polygon_tex;
uniform sampler2D u_tilemap_tex;
uniform sampler2D u_csg_tex;

void fragment() {
	vec4 poly_data = texture(u_polygon_tex, UV);
    vec4 tile_data = texture(u_tilemap_tex, UV);
    vec4 csg_data = texture(u_csg_tex, UV);

    if (csg_data.a == 0.0 || tile_data.a == 0.0) {
        discard;
    }

    COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}