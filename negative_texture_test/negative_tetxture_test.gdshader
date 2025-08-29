shader_type canvas_item;

uniform sampler2D scr_tex: hint_screen_texture;

void fragment() {
	//COLOR = texture(TEXTURE, UV) * COLOR;
    COLOR = texture(scr_tex, SCREEN_UV);
}
