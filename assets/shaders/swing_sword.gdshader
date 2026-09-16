shader_type spatial;
// unshaded keeps the 2D look, cull_disabled makes it visible from both sides
render_mode depth_draw_opaque, cull_disabled, unshaded;

//uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform float speed = 10.0;
uniform float max_angle = 1.2;

void vertex() {
    // 1. Calculate the bend weight (1.0 at top, 0.0 at bottom)
    float bend_weight = 1.0 - UV.y; 
    
    // 2. Calculate the angle based on TIME
    float angle = sin(TIME * speed) * max_angle * bend_weight;
    
    float s = sin(angle);
    float c = cos(angle);
    
    // 3. Apply the rotation to the local X and Y axes
    float new_x = VERTEX.x * c - VERTEX.y * s;
    float new_y = VERTEX.x * s + VERTEX.y * c;
    
    VERTEX.x = new_x;
    VERTEX.y = new_y;
}