shader_type canvas_item;

uniform sampler2D u_polygon_tex;

void fragment() {
    vec4 poly_data = texture(u_polygon_tex, UV);
    int unscaled = int(floor(poly_data.a * 255.0)) % 2;
    COLOR = mix(vec4(0.0), vec4(0.0, 0.0, 0.0, 1.0), 1.0 - float(unscaled));
    //COLOR = mix(vec4(0.0), vec4(poly_data.xyz * 100.0, 1.0), 1.0 - float(unscaled));
}