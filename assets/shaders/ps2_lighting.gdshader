shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float bloom_intensity : hint_range(0.0, 5.0) = 2.5;
uniform float bloom_blur : hint_range(0.0, 10.0) = 2.5;

void fragment() {
    vec4 base_color = texture(screen_texture, SCREEN_UV);
    
    // PS2 retro look relies on low-res mipmap textures to fake cheap blur
    vec2 ps = SCREEN_PIXEL_SIZE * bloom_blur;
    
    // 4-tap box blur sampling with high offset to replicate the rough look
    vec4 blur = texture(screen_texture, SCREEN_UV + vec2(-ps.x, -ps.y)) * 0.25;
    blur += texture(screen_texture, SCREEN_UV + vec2(ps.x, -ps.y)) * 0.25;
    blur += texture(screen_texture, SCREEN_UV + vec2(-ps.x, ps.y)) * 0.25;
    blur += texture(screen_texture, SCREEN_UV + vec2(ps.x, ps.y)) * 0.25;
    
    // Calculate perceived brightness (Luma)
    float luma = dot(blur.rgb, vec3(0.299, 0.587, 0.114));
    
    // Cut off pixels below threshold to isolate highlights
    vec4 bloom_pass = max(blur - bloom_threshold, 0.0);
    
    // Additive blending (how the PS2 GS mapped framebuffer accumulation)
    COLOR = base_color + (bloom_pass * bloom_intensity);
}
