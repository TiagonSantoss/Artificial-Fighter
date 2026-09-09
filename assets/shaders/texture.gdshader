shader_type spatial;
// No special cull modes needed here, it renders the normal model.

uniform sampler2D model_texture : source_color;

void fragment() {
    vec4 tex_color = texture(model_texture, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
}