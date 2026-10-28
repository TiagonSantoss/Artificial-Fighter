shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float size : hint_range(0.01, 1.0) = 0.2;
uniform float aspect_ratio = 1.777; 
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV - center;
    uv.x *= aspect_ratio;

    float star_dist = length(uv) * 1.5 + abs(uv.x) + abs(uv.y);
    float mask = 1.0 - smoothstep(size * 0.8, size, star_dist);
   
    float cross_mask = (0.002 / abs(uv.x)) + (0.002 / abs(uv.y));
    cross_mask *= smoothstep(size * 2.0, 0.0, length(uv)); 
    
    float final_cutout = clamp(mask + cross_mask, 0.0, 1.0);
    
    COLOR = vec4(bg_color.rgb, bg_color.a * (1.0 - final_cutout));
}