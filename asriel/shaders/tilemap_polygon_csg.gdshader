shader_type canvas_item;

uniform sampler2D u_polygon_tex;
uniform sampler2D u_tilemap_tex;

void fragment() {
	vec4 poly_data = texture(u_polygon_tex, UV);
    vec4 tile_data = texture(u_tilemap_tex, UV);
    
    // this keeps inside polygon
    if ((poly_data.a > 0.0f && tile_data.a > 0.0f) || tile_data.a == 0.0) {
        discard;
    }
    
    // this keeps outside polygon
    //if (poly_data.a > 0.0f && tile_data.a == 0.0f) {
        //discard;
    //}
    
    //COLOR = poly_data;
    COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}