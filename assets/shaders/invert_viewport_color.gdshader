shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture, filter_nearest;

void fragment() {
	vec4 cube_mask = texture(TEXTURE, SCREEN_UV);
	
	vec3 background = texture(screen_tex, SCREEN_UV).rgb;
	
	vec3 invert_bg = vec3(1.0) - background;
	
	COLOR.rgb = invert_bg;
	COLOR.a = cube_mask.a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
