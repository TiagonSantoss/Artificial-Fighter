shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 gradient_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float gradient_angle : hint_range(0.0, 360.0) = 45.0; 
// 1.0 perfectly pins the gradient to the corners. 
// Higher numbers push it off-screen, lower numbers compress it into a stripe.
uniform float gradient_scale : hint_range(0.1, 3.0) = 1.0;   

// Dot Pattern
uniform vec4 dot_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float spacing : hint_range(10.0, 100.0) = 40.0;
uniform float dot_size : hint_range(1.0, 20.0) = 3.0;
uniform vec2 scroll_speed = vec2(15.0, 15.0); 
uniform float edge_shrink_intensity : hint_range(0.0, 3.0) = 1.5;

// Vignette
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float vignette_multiplier : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    float dist_from_center = distance(UV, vec2(0.5));
    
    // 1. CORNER-TO-CORNER DIRECTIONAL GRADIENT
    float rad = radians(gradient_angle);
    vec2 dir = vec2(cos(rad), sin(rad));
    
    // Calculates the exact maximum distance to the screen corners for the current angle
    float max_dist = abs(dir.x) * 0.5 + abs(dir.y) * 0.5;
    
    // Divides the gradient math by that max distance to pin the colors to the absolute edges
    float grad_mix = (dot(UV - vec2(0.5), dir) / (max_dist * 2.0 * gradient_scale)) + 0.5;
    
    grad_mix = clamp(grad_mix, 0.0, 1.0);
    vec4 current_bg = mix(bg_color, gradient_color, grad_mix);
    
    // 2. Dots
    float shrink_factor = max(1.0 - (dist_from_center * edge_shrink_intensity), 0.0);
    float current_dot_size = dot_size * shrink_factor;
    
    vec2 pos = mod(FRAGCOORD.xy + (TIME * scroll_speed), spacing);
    vec2 center = vec2(spacing / 2.0);
    float dist_to_dot_center = length(pos - center);
    float alpha = 1.0 - smoothstep(current_dot_size - 1.0, current_dot_size + 1.0, dist_to_dot_center);
    vec4 pattern_color = mix(current_bg, dot_color, alpha);
    
    // 3. Vignette
    float vignette_mask = clamp((dist_from_center * dist_from_center) * vignette_multiplier, 0.0, 1.0);
    COLOR = mix(pattern_color, vignette_color, vignette_mask);
}