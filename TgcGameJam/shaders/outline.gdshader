shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.88, 0.45, 0.55);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float around = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (around > 0.1) {
			c = outline_color;
		}
	}
	COLOR = c;
}
