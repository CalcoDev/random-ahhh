shader_type canvas_item;

//uniform vec4 u_debug_col;

varying vec4 v_color;

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

void vertex() {
    v_color = _from_norm(COLOR);
    //VERTEX = VERTEX + v_color.xy * 5.0 + -v_color.zw * 10.0;
    VERTEX += v_color.xy * 5.0;
    VERTEX += -v_color.zw * 5.0;
}

void fragment() {
	COLOR = vec4(v_color.xy, 0.0, 1.0 / 255.0);
    //COLOR = vec4(v_color.xy, 0.0, 1.0);
}