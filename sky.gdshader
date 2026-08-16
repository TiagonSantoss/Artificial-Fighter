shader_type sky;

//uniform vec3 edge_color : source_color = vec3(0.0);
//uniform vec3 center_color : source_color = vec3(0.0);
//
//uniform vec3 center_position = vec3(0.0); 
//uniform float circle_size : hint_range(0.1, 1.0) = 0.5;

uniform float rotation_speed: hint_range(0.0, 1.0) = 0.1;

uniform sampler2D gradient_texture: hint_default_black;

void sky() {
	vec2 uv = SKY_COORDS;
	
	//uv.y += TIME;
	uv.x = TIME * rotation_speed; 
	
	vec3 gradient_color = texture(gradient_texture, uv).rgb;
	
	COLOR = gradient_color;
	
	
}
