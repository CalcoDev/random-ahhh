shader_type canvas_item;

//vec4 _sample(vec2 uv, float off_x, float off_y) {
    //return _from_norm(texture(u_prev_velocity_tex, uv + vec2(off_x, off_y)));
//}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);



    COLOR = vec4(UV, 0.0, tex.a);
}