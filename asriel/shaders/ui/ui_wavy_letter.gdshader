shader_type canvas_item;

uniform float sine_amplitude : hint_range(0.0, 0.1) = 0.05;
uniform float sine_frequency : hint_range(0.0, 10.0) = 2.0;
uniform float sine_speed : hint_range(0.0, 5.0) = 1.0;
uniform float random_amplitude : hint_range(0.0, 0.1) = 0.05;
uniform float update_interval : hint_range(0.1, 10.0) = 3.0;

// Simple 1D noise function
float random(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
    // Calculate time step for periodic random updates
    float time_step = floor(TIME / update_interval);

    // Generate pseudo-random offset per row based on UV.y and time step
    float random_offset = random_amplitude * random(UV.y * 100.0 + time_step);

    // Calculate sine offset based on Y position and time
    float sine_offset = sine_amplitude * sin(UV.y * sine_frequency + TIME * sine_speed);

    // Combine offsets
    float total_offset = random_offset + sine_offset;

    // Apply offset to UV coordinates
    vec2 offset_uv = vec2(UV.x + total_offset, UV.y);

    // Sample texture with offset UVs
    COLOR = texture(TEXTURE, offset_uv);
}