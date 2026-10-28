shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 0.0); 

uniform float spacing : hint_range(5.0, 50.0) = 20.0;
uniform float max_dot_size : hint_range(1.0, 25.0) = 12.0;
uniform float vignette_multiplier : hint_range(0.1, 5.0) = 2.0;

uniform float opacity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float dist_from_center = distance(UV, vec2(0.5));

    float vignette_mask = clamp((dist_from_center * dist_from_center) * vignette_multiplier, 0.0, 1.0);

    vec2 pos = mod(FRAGCOORD.xy, spacing);
    vec2 center = vec2(spacing / 2.0);
    float dist_to_dot_center = length(pos - center);

    float current_dot_size = max_dot_size * vignette_mask;

    float dot_alpha = 1.0 - smoothstep(current_dot_size - 1.0, current_dot_size + 1.0, dist_to_dot_center);
   
    vec4 final_color = mix(bg_color, vignette_color, dot_alpha);
    final_color.a *= opacity;
    COLOR = final_color;
}