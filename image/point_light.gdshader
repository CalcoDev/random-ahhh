shader_type canvas_item;

uniform sampler2D u_distance_field_tex;

uniform vec2 u_pos;
uniform float u_intensity: hint_range(0.0, 1.0);
uniform float u_radial_falloff: hint_range(0.0, 1.0);
uniform int u_radial_falloff_steps: hint_range(0, 10);
uniform vec3 u_light_tint: source_color;

uniform int u_max_raymarch_steps = 128;

//uniform sampler2D u_radial_steps_curve;
//uniform float u_angle_rotation: hint_range(-3.14159, 3.14159) = 0.0;
//uniform float u_angle_min: hint_range(-3.14159, 3.14159) = 0.0;
//uniform float u_angle_max: hint_range(-3.14159, 3.14159) = 0.0;

bool raymarch(vec2 origin, vec2 dir, vec2 target, out vec2 hit_pos) {
	float current_dist = 0.0;
	
	vec2 og_sign = normalize(target - origin);
	
	for (int i = 0; i < u_max_raymarch_steps; i++) {
		vec2 sample_point = origin + (dir * current_dist);
		
		if (sample_point.x >= 1.0 || sample_point.x <= 0.0 || sample_point.y >= 1.0 || sample_point.y <= 0.0) {
			return false;
		}
		
		vec2 curr_sign = normalize(sample_point - target);
		if ( distance(og_sign, curr_sign) < 0.01 ) {
			return false;
		}
		
		float dist_to_surface = texture(u_distance_field_tex, sample_point).r;
		
		if (dist_to_surface < 0.005f) {
			hit_pos = sample_point;
			return true;
		}
		
		current_dist += dist_to_surface;
	}
	
	return false;
}

void fragment() {
	vec2 center = vec2(0.0);
	vec2 uv = UV - 0.5 - u_pos;

	float dist = distance(center, uv);
	float radial_falloff = pow(1.0 - clamp(dist * (1.0 / u_radial_falloff), 0.0, 1.0), 2.0);

	if (u_radial_falloff_steps > 0) {
		float step_size = 1.0 / float(u_radial_falloff_steps + 1);
		radial_falloff = floor(radial_falloff / step_size) * step_size;
	}
	
	float dv = texture(u_distance_field_tex, UV).r;
	
	vec2 dir = normalize(u_pos + 0.5 - UV);

	vec2 hit_pos = vec2(0.0);
	bool hit = raymarch(UV, dir, u_pos + 0.5, hit_pos);
	
	float final_intensity = u_intensity * radial_falloff * float(!hit);
	vec3 light_color = final_intensity * u_light_tint;
	
	COLOR = vec4(light_color, pow(final_intensity, 2.0));
}