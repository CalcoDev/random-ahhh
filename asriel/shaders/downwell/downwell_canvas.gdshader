shader_type canvas_item;

float random(vec2 seed) {
    return fract(sin(dot(seed, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    float x = SCREEN_UV.x / SCREEN_PIXEL_SIZE.x;
    if (mod(floor(x), 2.0) == 1.0) {
        discard;
    }
    
    float seed = floor(TIME / 0.05);
    float r1 = random(UV.x + vec2(seed, seed));
    if (r1 < 0.2) {
        discard;
    }
    
    //COLOR = vec4(vec3(randValue), 1.0);
    COLOR = vec4(1.0);
}