shader_type spatial;

uniform float inactive_amount : hint_range(0.0, 1.0) = 0.0;

float bayer4x4(int x, int y) {
	int index = x + y * 4;
	
	float[16] matrix = float[](
		0.0,    0.5,    0.125,  0.625,
		0.75,   0.25,   0.875,  0.375,
		0.1875, 0.6875, 0.0625, 0.5625,
		0.9375, 0.4375, 0.8125, 0.3125
	);
	
	return matrix[index];
}

void fragment() {
	vec3 gray = vec3(dot(ALBEDO, vec3(0.299, 0.587, 0.114)));
	
	vec3 final_color = mix(
		ALBEDO,
		gray,
		inactive_amount
	);
	
	final_color *= mix(
		1.0,
		0.45,
		inactive_amount
	);
	
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	
	float threshold = bayer4x4(x, y);
	
	float brightness = dot(
		final_color,
		vec3(0.333)
	);
	
	if (brightness < threshold * inactive_amount) {discard;}
	
	ALBEDO = final_color;
}