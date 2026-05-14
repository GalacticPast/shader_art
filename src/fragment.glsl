#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

vec3 circle(vec2 uv, vec2 pos, float radius, vec3 ret_color)
{
    uv -= pos;
    float dist = length(uv); // magnitude of how far it is from the origin 
    vec3 color = vec3(0); 
    if (dist < radius)color = ret_color;
    else color = vec3(0);

    return vec3(color);
}

void main() 
{
    float aspect_ratio = u_resolution.x / u_resolution.y;

    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);

    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio; // 1 unit of X == 1 Unit of y
    
    vec3 color = circle(uv,vec2(-0.5, 0), 0.1, vec3(1,0,1));
    color += circle(uv,vec2(0.5,0), 0.1, vec3(0,0,1));

    fragColor = vec4(color, 1.0);
}

