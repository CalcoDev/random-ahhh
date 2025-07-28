shader_type canvas_item;

uniform sampler2D u_tex: repeat_enable, filter_nearest;
uniform float u_aspect_ratio;
uniform vec2 u_tiling;
uniform vec2 u_offset;

void fragment() {
    float scaledTime = TIME * 3.14f * 2.0f;
    float timestep1 = step(-0.7f, sin(scaledTime));
    float timestep2 = step(0.7f, sin(scaledTime));

    vec2 uv = UV * u_tiling + u_offset;
    uv.x *= u_aspect_ratio;
    vec4 middle = texture(u_tex, uv);

    vec2 pixelstep = TEXTURE_PIXEL_SIZE;

    // -- inner cross
    vec2 uvTop = vec2(uv.x, uv.y + pixelstep.y);
    vec2 uvBot = vec2(uv.x, uv.y - pixelstep.y);
    vec2 uvLeft = vec2(uv.x - pixelstep.x, uv.y);
    vec2 uvRight = vec2(uv.x + pixelstep.x, uv.y);

    vec4 cTop = texture(u_tex, uvTop);
    vec4 cBot = texture(u_tex, uvBot);
    vec4 cLeft = texture(u_tex, uvLeft);
    vec4 cRight = texture(u_tex, uvRight);

    vec4 ccrrooss = cTop + cBot + cLeft + cRight;

    // -- outer diamond
    vec2 uvTop2 = vec2(uv.x, uv.y + pixelstep.y * 2.0);
    vec2 uvBot2 = vec2(uv.x, uv.y - pixelstep.y * 2.0);
    vec2 uvLeft2 = vec2(uv.x - pixelstep.x * 2.0, uv.y);
    vec2 uvRight2 = vec2(uv.x + pixelstep.x * 2.0, uv.y);
    vec2 uvTopRight = vec2(uv.x + pixelstep.x, uv.y + pixelstep.y);
    vec2 uvTopLeft = vec2(uv.x - pixelstep.x, uv.y + pixelstep.y);
    vec2 uvBottomRight = vec2(uv.x + pixelstep.x, uv.y - pixelstep.y);
    vec2 uvBottomLeft = vec2(uv.x - pixelstep.x, uv.y - pixelstep.y);

    vec4 cTop2 = texture(u_tex, uvTop2);
    vec4 cBot2 = texture(u_tex, uvBot2);
    vec4 cLeft2 = texture(u_tex, uvLeft2);
    vec4 cRight2 = texture(u_tex, uvRight2);
    vec4 cTopRight = texture(u_tex, uvTopRight);
    vec4 cTopLeft = texture(u_tex, uvTopLeft);
    vec4 cBottomRight = texture(u_tex, uvBottomRight);
    vec4 cBottomLeft = texture(u_tex, uvBottomLeft);

    vec4 diamond = cTop2 + cBot2 + cLeft2 + cRight2 + cTopRight + cTopLeft + cBottomRight + cBottomLeft;
    vec4 diamondOnly = clamp(diamond - middle, -1.0, 1.0);

    COLOR = middle + timestep1 * ccrrooss + timestep2 * diamondOnly;
}