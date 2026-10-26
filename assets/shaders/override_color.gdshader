shader_type canvas_item;

uniform vec4 override_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 original_col = texture(TEXTURE, UV);
	
	COLOR = vec4(override_color.rgb, original_col.a * override_color.a);
}
