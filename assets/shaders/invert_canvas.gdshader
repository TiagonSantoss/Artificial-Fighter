shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture, filter_nearest;


void fragment() {
	vec3 bg_color = texture(screen_tex, SCREEN_UV).rgb;
	
	COLOR.rgb = vec3(1.0) - bg_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
