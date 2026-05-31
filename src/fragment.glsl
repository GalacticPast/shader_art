#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

// thank you iq: https://www.shadertoy.com/view/3tyBzV

float dot2(vec2 p){
    return dot(p,p);
}

float Sd_heart( in vec2 p )
{
    p.x = abs(p.x);

    if( p.y+p.x>1.0 )
        return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
    return sqrt(min(dot2(p-vec2(0.00,1.00)),
                    dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
}

void main() 
{
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);

    vec2 uv =  (frag_coord * 2) / u_resolution ;
    uv -= 1;
    uv.x *= u_resolution.x / u_resolution.y; 
    
    uv *= sin(2 * 3.1459 * u_time + uv.y/2) * 0.5 + 1.0;

    float dist = Sd_heart(uv - vec2(0, -0.5));
    float heart = abs(dist);

    vec2 lightDirection = normalize(vec2(sin(u_time),cos(u_time))); 
    
    float spotlight = dot(uv, lightDirection); 

    vec3 baseColor = vec3(0.8, 0.1, 0.2); 
    
    vec3 finalColor = baseColor * (spotlight + 1.0) * (0.09 / heart);

    fragColor = vec4(finalColor, 1.0);
}

