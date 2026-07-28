shader_type canvas_item;

// Screen texture for distortion
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Shader controls driven by Tween in GDScript
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fire_color : source_color = vec4(1.0, 0.35, 0.0, 1.0);

// Simple pseudo-random noise generator
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;

    // 1. Calculate distance from screen edges for vignette fire
    float dist_from_center = length(uv - vec2(0.5)) * 1.5;
    
    // 2. Animate noise over time
    vec2 noise_uv = uv * 4.0 + vec2(0.0, -TIME * 1.5);
    float n = noise(noise_uv);

    // 3. Screen distortion effect
    vec2 distortion = vec2(n - 0.5) * 0.02 * intensity;
    vec4 screen_color = texture(screen_texture, SCREEN_UV + distortion);

    // 4. Combine noise and edge vignette to create fire mask
    float fire_mask = smoothstep(0.3, 0.9, dist_from_center + (n * 0.3)) * intensity;

    // 5. Blend original screen with fire color overlay
    vec3 final_rgb = mix(screen_color.rgb, fire_color.rgb, fire_mask * fire_color.a);

    COLOR = vec4(final_rgb, screen_color.a);
}