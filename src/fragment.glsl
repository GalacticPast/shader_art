#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

// Rainbow Travel
// By Noztol
// Based on https://fragcoord.xyz/s/fx196wc1 
// but using XorDev's color scheme 


void main() 
{
    vec2 frag_cord = vec2(gl_FragCoord.x, gl_FragCoord.y);

    vec2 uv = frag_cord/u_resolution;

    float d = length(uv);
         
    float c = d;

    fragColor = vec4(vec3(c),1.0);
}

