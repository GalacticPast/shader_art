#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

float circle(vec2 uv, vec2 pos, float radius,float blur)
{
    uv -= pos;
    float dist = length(uv); // magnitude of how far it is from the origin 
    float c_step = smoothstep(radius, radius - blur, dist); 
         
    return c_step;
}

float smiley(vec2 uv, vec2 pos, vec2 size)
{
    uv -= pos; 
    uv *= size;

    float face = circle(uv, vec2(0,0), 0.2, 0.01);
    float l_eye = circle(uv,vec2(-0.1, 0.05), 0.05,0.01);
    float r_eye = circle(uv,vec2(0.1,0.05), 0.05,0.01);
    float mouth_u = circle(uv, vec2(0,-0.075), 0.08,0.01);
    float mouth_l = circle(uv, vec2(0,-0.065), 0.08,0.01);
     
    float mask = face - l_eye - r_eye - (mouth_u - mouth_l);

    return mask;
}

void main() 
{
    float aspect_ratio = u_resolution.x / u_resolution.y;

    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);

    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio; // 1 unit of X == 1 Unit of y
    
    //float smile = smiley(uv, vec2(0, 0), vec2(2));
    
    //vec3 color = vec3(1,0,1) * smile;

    fragColor = vec4(vec3(1), 1.0);
}

