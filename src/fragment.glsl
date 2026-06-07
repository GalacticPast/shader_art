#version 330

// ep : 08 from cem yuskel Lights and shading
uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 frag_color;

#define PI 3.1459

float Sd_sph(vec3 ray_pos, vec3 sph_pos, float radius)
{
    return length(ray_pos - sph_pos) - radius;
}

float Map(vec3 p)
{
    vec3 sph_pos = vec3(0.0);
    float sph = Sd_sph(p, sph_pos, 1.0);
    return sph;
}

float Render(vec3 r_o, vec3 r_d)
{
    float t = 0.0;
    
    for(int i = 0 ; i < 100 ; i++)
    {
        vec3 p = r_o + r_d * t;
        float d = Map(p);
        t += d;
        if(d < 0.001 || d > 100.00)break;
    }
    return t;
}


void main()
{
    vec2 res = u_resolution.xy;
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    vec2 uv = (frag_coord * 2.0)/ u_resolution;  
    uv -= 1.0;  
    uv.x *= u_resolution.x / u_resolution.y; 
    
    vec3 r_o = vec3(0, 0, -3);
    vec3 r_d = normalize(vec3(uv, 1.0)); 

    float d = Render(r_o, r_d); 
    vec3 color = vec3(0.0); 
    if (d < 100.0) {
        vec3 p = r_o + r_d * d; 
        
        // 'p' will have values from -1.0 to 1.0 (since the radius is 1.0).
        // Colors need to be between 0.0 and 1.0.
        // Multiplying by 0.5 and adding 0.5 shifts the range perfectly.
        color = p * 0.5 + 0.5;
    }

    frag_color = vec4(color, 1);
} 
