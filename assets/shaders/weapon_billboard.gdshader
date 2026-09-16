shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, unshaded; 

uniform sampler2D main_texture : filter_nearest, source_color;
uniform float sprite_rotation = 0.0;  // Use this for aiming/idle rotation
uniform float swing_angle = 0.0;      // NEW: Use this strictly for the attack swing
uniform bool use_bend = true;         // NEW: Toggle the top-heavy bending effect
uniform vec2 gun_offset = vec2(0.0);
uniform bool flip_gun = false;

void vertex() {
    vec3 scale = vec3(
        length(MODEL_MATRIX[0].xyz),
        length(MODEL_MATRIX[1].xyz),
        length(MODEL_MATRIX[2].xyz)
    );
    
    // Calculate how much to bend based on the UV.y (1.0 at top, 0.0 at bottom)
    float bend_weight = use_bend ? (1.0 - UV.y) : 1.0;
    
    // Combine your base rotation with the attack swing
    float total_rotation = sprite_rotation + swing_angle;
    
    float cos_r = cos(total_rotation);
    float sin_r = sin(total_rotation);
    mat2 rot_matrix = mat2(vec2(cos_r, -sin_r), vec2(sin_r, cos_r));
    
    vec2 local_pos = VERTEX.xy * scale.xy;
    vec2 final_offset = gun_offset;
    
    if (flip_gun) {
        local_pos.y = -local_pos.y;
        final_offset.y = -final_offset.y;
        final_offset.x = -final_offset.x;
    }
    
    vec2 rotated_vertex = rot_matrix * local_pos;
    vec2 rotated_offset = rot_matrix * final_offset;
    
    VERTEX.xy = rotated_vertex + rotated_offset;
    
    // Your billboarding math
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            MAIN_CAM_INV_VIEW_MATRIX[0],
            MAIN_CAM_INV_VIEW_MATRIX[1],
            MAIN_CAM_INV_VIEW_MATRIX[2],
            MODEL_MATRIX[3]);
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
    
    VERTEX.z -= 0.1;
    VERTEX.y += 1.5;
}

void fragment() {
    vec4 tex_color = texture(main_texture, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
}