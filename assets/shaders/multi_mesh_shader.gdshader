shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_disabled;

uniform sampler2D atlas : filter_nearest, source_color;
uniform vec2 frame_size;
uniform vec2 atlas_size;

void vertex() {
	// 1. Calculate scale from the model matrix before we overwrite it
	vec3 scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	
	// 2. Retrieve individual instance rotation angle from custom data buffer
	float sprite_rotation = INSTANCE_CUSTOM.z;
	
	float cos_r = cos(sprite_rotation);
	float sin_r = sin(sprite_rotation);
	mat2 rot_matrix = mat2(vec2(cos_r, -sin_r), vec2(sin_r, cos_r));
	
	// Apply scale and 2D rotation to the local vertex positions
	VERTEX.xy = rot_matrix * (VERTEX.xy * scale.xy);
	
	// 3. Apply the billboard matrix (retaining position, stripping 3D rotation)
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	
	// 4. UV handling
	float col_coord = round(INSTANCE_CUSTOM.x * 255.0);
	float row_coord = round(INSTANCE_CUSTOM.y * 255.0);
	
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
