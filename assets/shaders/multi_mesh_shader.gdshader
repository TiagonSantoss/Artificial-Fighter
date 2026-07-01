shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_disabled;

uniform sampler2D atlas : filter_nearest, source_color;

uniform vec2 frame_size;
uniform vec2 atlas_size;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
        vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
        vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
        vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
        MODEL_MATRIX[3]
    );
    // 1. Decode the compressed color data back to integers
    float frame = INSTANCE_CUSTOM.x * 255.0;
    float row = INSTANCE_CUSTOM.y * 255.0;

    int f = int(round(frame));
    int y = int(round(row));

    // 2. Calculate horizontal columns based on pixel sizes
    int cols = int(atlas_size.x / frame_size.x);
    int x = f % cols;

    // 3. Shift and scale the UV coordinates to isolate the single frame
    vec2 uv_offset = vec2(float(x), float(y)) * frame_size / atlas_size;
    vec2 uv_scale = frame_size / atlas_size;

    UV = UV * uv_scale + uv_offset;
}

void fragment() {
    vec4 tex_color = texture(atlas, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
    
    // Alpha scissor ensures crisp edges on transparent pixel-art frames
    ALPHA_SCISSOR_THRESHOLD = 0.5; 
}