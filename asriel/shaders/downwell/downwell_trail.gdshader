shader_type canvas_item;

uniform float u_angle: hint_range(-3.14159, 3.14159, 0.01) = 0.0;

vec2 rotate_point(vec2 point, vec2 pivot, float angle) {
    float cos_a = cos(angle);
    float sin_a = sin(angle);
    mat2 rotation = mat2(vec2(cos_a, -sin_a), vec2(sin_a, cos_a));
    return rotation * (point - pivot) + pivot;
}

float random(vec2 seed) {
    return fract(sin(dot(seed, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec4 color_data = texture(TEXTURE, UV);
    if (color_data.a < 1.0) {
        discard;
    }

    vec2 resolution = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);
    vec2 center = resolution * 0.5;

    float ang = -u_angle + (PI / 2.0);
    float cos_a = cos(-ang);
    float sin_a = sin(-ang);
    mat2 inverse_rotation = mat2(vec2(cos_a, -sin_a), vec2(sin_a, cos_a));
    vec2 original_coord = inverse_rotation * (FRAGCOORD.xy - center) + center;

    float x = original_coord.x;
    if (mod(floor(x), 2.0) == 1.0) {
        discard;
    }

    float seed = floor(TIME / 0.09);
    float r1 = random(vec2(floor(original_coord.x) / 240.0 + seed));
    if (r1 < 0.3) {
        discard;
    }

    vec2 rotated_coord = rotate_point(FRAGCOORD.xy, center, u_angle);

    COLOR = vec4(1.0, 0.0, 0.0, 1.0);
}