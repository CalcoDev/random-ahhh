shader_type canvas_item;

uniform sampler2D u_obtained_tex;

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
    vec4 data = texture(u_obtained_tex, UV);
    data = _from_norm(data);
    
    vec2 vel = data.xy * 100.0f;
    //vel = normalize(vel);
    
    COLOR = vec4(vel, 0.0, 1.0);
}