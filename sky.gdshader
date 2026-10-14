shader_type sky;

uniform float rotation_speed: hint_range(0.0, 1.0) = 0.1;

uniform vec4 color: source_color;

uniform sampler2D gradient_texture: hint_default_black;

void sky() {
	vec2 uv = SKY_COORDS;
	
	//uv.y += TIME;
	uv.x = TIME * rotation_speed; 
	
	vec3 gradient_color = texture(gradient_texture, uv).rgb;
	
	COLOR = gradient_color;
	
	
}
