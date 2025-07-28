shader_type canvas_item;

varying vec2 vert;

void vertex() {
    vert = VERTEX;
    //VERTEX.x += sin(TIME * 20.0) * 20.0;
    //VERTEX.y += sin(TIME * 20.0) * 20.0;
}

void fragment() {
    COLOR = vec4(vert, 0.0, 1.0);
}