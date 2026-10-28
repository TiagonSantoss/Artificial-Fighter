// Pixelated noise transition effect based on https://godotshaders.com/shader/warped-fractal-noise/
//
// Copyright Gerardo Montaño 2025
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of 
// this software and associated documentation files (the “Software”), to deal in 
// the Software without restriction, including without limitation the rights to 
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do 
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all 
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
// SOFTWARE.

shader_type canvas_item;

uniform float progress = 0.0;
uniform float speed = 0.1; 

uniform vec2 pixelation = vec2(2.0, 2.0);
uniform float zoom = 2.0;

uniform float background_threshold : hint_range(-2.0, 1.0) = 0.0;
uniform float color_threshold : hint_range(0.0, 1.0)  = 0.24;

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0); 

uniform float seed = 0.0;

#define iTime (TIME * speed - seed)

const mat2 mtx = mat2( vec2(0.80, -0.60), vec2(0.60, 0.80) );

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898 + seed, 4.1414 - seed))) * (43758.5453 + seed * 1000.0));
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);
        
    return res * res;
}

float fbm( vec2 p )
{
    float f = 0.0;
    
    f += 0.500000 * noise( p + iTime ); p = mtx * p * 2.02;
    f += 0.031250 * noise( p ); p = mtx * p * 2.01;
    f += 0.250000 * noise( p ); p = mtx * p * 2.03;
    f += 0.125000 * noise( p ); p = mtx * p * 2.01;
    f += 0.062500 * noise( p ); p = mtx * p * 2.04;
    f += 0.015625 * noise( p + sin(iTime) );

    return f / 0.96875;
}

float pattern( in vec2 p )
{
	return fbm( p + fbm( p + fbm( p ) ) );
}

vec4 colormap(float x, vec2 uv) {
	
	x *= max(0.0, min(-abs(progress * 4.0 - uv.x - uv.y - 1.0) + 1.0, 1.0) * 2.0);
    
    if (x < background_threshold) { 
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    else if (x < color_threshold) { 
        return mix(
			vec4(0.0, 0.0, 0.0, 0.0),
			color,
			round((x - background_threshold) / (color_threshold - background_threshold))
		);
    }
	else {
		return color;
	}
}

void fragment()
{
	vec2 modifier = 1.0/(SCREEN_PIXEL_SIZE * pixelation);
	vec2 uv = floor(UV * modifier) / modifier;
	float shade = pattern(uv * zoom);
	COLOR = colormap(shade, uv);
}