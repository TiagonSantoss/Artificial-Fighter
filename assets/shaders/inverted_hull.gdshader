shader_type spatial;
render_mode unshaded, cull_front; // cull_front is what makes it an outline

uniform float weight = 0.02
;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
    // Note: * COLOR.r only works if your 3D mesh has vertex colors painted on it. 
    // If your outline doesn't show up, change this to: VERTEX += NORMAL * weight;
    VERTEX += NORMAL * weight * COLOR.r; 
}

void fragment() {
    ALBEDO = color.rgb;
}