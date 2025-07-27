shader_type canvas_item;

uniform sampler2D u_temp_velocity_tex;
uniform sampler2D u_prev_velocity_tex; // pre blit

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
    vec4 prev = _from_norm(texture(u_prev_velocity_tex, UV));
    vec4 temp = _from_norm(texture(u_temp_velocity_tex, UV));

    //if (temp.a > 0.0)
    {
        if (abs(temp.x) > 0.0f) {
            prev.x = temp.x;
        }
        if (abs(temp.y) > 0.0f) {
            prev.y = temp.y;
        }
    }

    //COLOR = _to_norm(vec4(prev.x, prev.y, -1.0f, 1.0f));
    COLOR = _to_norm(vec4(prev.x, prev.y, prev.z, prev.w));
}