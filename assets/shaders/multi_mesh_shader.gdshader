shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_disabled;

uniform sampler2D atlas : filter_nearest, source_color;
uniform vec2 frame_size;
uniform vec2 atlas_size;

void vertex() {
	// 1. Extract scale mechanics from the matrix transform pipeline
	vec3 scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	
	// 2. Clear rotation matrices to run perfect Camera Billboarding
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(scale.x, 0.0, 0.0, 0.0),
		vec4(0.0, scale.y, 0.0, 0.0),
		vec4(0.0, 0.0, scale.z, 0.0),
		MODEL_MATRIX[3]
	);

	// 3. Decode direct column and row tracks from custom data layout channels
	float col_coord = round(INSTANCE_CUSTOM.x * 255.0);
	float row_coord = round(INSTANCE_CUSTOM.y * 255.0);

	// 4. Calculate direct matching UV scales and offsets without grids/loops
	vec2 uv_scale = frame_size / atlas_size;
	vec2 uv_offset = vec2(col_coord, row_coord) * frame_size / atlas_size;

	UV = UV * uv_scale + uv_offset;
}

void fragment() {
	vec4 tex_color = texture(atlas, UV);
	ALBEDO = tex_color.rgb;
	ALPHA = tex_color.a;
	
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}