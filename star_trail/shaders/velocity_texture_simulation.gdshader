shader_type canvas_item;

uniform sampler2D u_prev_velocity_tex; // post blip
uniform vec4 u_sim_params;
uniform vec2 u_prev_velocity_tex_texel_size;

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

vec4 _sample_previous_velocity(vec2 uv, float off_x, float off_y) {
    return _from_norm(texture(u_prev_velocity_tex, uv + vec2(off_x, off_y)));
}

const float VEL_SCALE_FACTOR = 100.0f;
const float DIST_SCALE_FACTOR = 100.0f;

vec4 _simulate_velocity(vec2 uv) {
   	vec4 prev_data = _sample_previous_velocity(uv, 0.0f, 0.0f);
    vec2 off = u_prev_velocity_tex_texel_size;

    vec4 neighbour_data = _sample_previous_velocity(uv, off.x, 0.0f);
    neighbour_data += _sample_previous_velocity(uv, -off.x, 0.0f);
    neighbour_data += _sample_previous_velocity(uv, 0.0f, off.y);
    neighbour_data += _sample_previous_velocity(uv, 0.0f, -off.y);
    neighbour_data *= 0.25f;
    prev_data = mix(prev_data, neighbour_data, u_sim_params.z);

    vec2 vel = prev_data.xy * VEL_SCALE_FACTOR;
    vec2 dist = prev_data.zw * DIST_SCALE_FACTOR;

    // bordering
    if (uv.x < off.x || uv.x > 1.0 - off.x || uv.y < off.y || uv.y > 1.0 - off.y) {
        vel = vec2(0.0f);
    }
    
    float dt = u_sim_params.w;
    vec2 accel = -dist * u_sim_params.x - vel * u_sim_params.y;
    //vel += accel * dt;
    //dist += vel * dt;
    
    vel /= VEL_SCALE_FACTOR;
    dist /= DIST_SCALE_FACTOR;

    return _to_norm(vec4(vel, -1.0f, 1.0f));
}

void fragment() {
    COLOR = _simulate_velocity(UV);
}