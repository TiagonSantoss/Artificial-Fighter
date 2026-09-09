shader_type canvas_item;

uniform vec4 outline_color : source_color;
uniform float outline_width = 1.0;
uniform int type : hint_range(0, 2) = 2;
uniform int active : hint_range(0,1) = 1;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

const vec2[8] DIRECTIONS = {
    vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0),
    vec2(1.0, 1.0), vec2(-1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0)
};

float gtz(float input) { return max(0.0, sign(input)); }

// (Kept for compatibility, though it is currently unused in the main logic)
float compute_color_power(vec4 color) {
    return 1000.*color.r + gtz(color.r)*100.
         + 100.*color.g + gtz(color.g)*10.
         + 10.*color.b + gtz(color.b)
         + color.a;
}

float check_color(sampler2D tex, vec2 from, vec2 size) {
    float result = 0.0;
    vec4 ref_color = texture(tex, from);
    float ref_val_color = ref_color.r + ref_color.g + ref_color.b;
    
    for (int i = 0; i < 4 * type; i++) {
        vec4 color = texture(tex, from + DIRECTIONS[i] * size * outline_width);
        float diff_color = abs(color.r - ref_color.r)
                         + abs(color.g - ref_color.g)
                         + abs(color.b - ref_color.b)
                         + abs(color.a - ref_color.a);
                         
        float val_color = color.r + color.g + color.b;
        float diff = ref_val_color - val_color;
        float abs_diff = abs(diff);
        
        result += gtz(diff_color) * gtz(abs_diff - diff);
    }
    return result; 
}

void fragment() {
    if (active > 0) {
        COLOR.rgb = outline_color.rgb;
        vec2 screen_pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
        COLOR.a = check_color(screen_texture, SCREEN_UV, screen_pixel_size);
    } else {
        COLOR.a = 0.0; 
    }
}