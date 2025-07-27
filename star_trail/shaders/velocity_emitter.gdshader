shader_type canvas_item;

uniform vec2 u_position_delta = vec2(0.0f); // -1 and 1

vec4 _to_norm(vec4 v) {
    return vec4(
        (v.x + 1.0f) * 0.5f,
        (v.y + 1.0f) * 0.5f,
        (v.z + 1.0f) * 0.5f,
        (v.w + 1.0f) * 0.5f
    );
}

vec4 _from_norm(vec4 v) {
    return vec4(
        v.x * 2.0f - 1.0f,
        v.y * 2.0f - 1.0f,
        v.z * 2.0f - 1.0f,
        v.w * 2.0f - 1.0f
    );
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    if (col.a < 0.1) {
        discard;
    }
    COLOR = _to_norm(vec4(u_position_delta, -1.0f, 1.0f));
}