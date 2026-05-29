#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

float Circle(vec2 uv, vec2 pos, float radius,float blur)
{
    uv -= pos;
    float dist = length(uv); // magnitude of how far it is from the origin 
    float c_step = smoothstep(radius, radius - blur, dist); 
         
    return c_step;
}

float Donut(vec2 uv, vec2 pos, float radius,  float width, float blur){
    float inner_circle = Circle(uv, pos, radius, blur);        
    float outer_circle = Circle(uv, pos, radius + width, blur);        

    return outer_circle - inner_circle;
}

float Glow(vec2 uv, vec2 p){
    float dist = length(p - uv);
    float glow = 0.05 / dist; 
    return glow;
}

vec3 Color_palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);

    return a + b*cos( 6.28318*(c*t+d) );
}

void main() 
{
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    float aspect_ratio = u_resolution.x / u_resolution.y;
    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio;
    
    float radius = 0.2;
    
    vec3 color = vec3(0);

    for(int i = 1 ; i <= 30 ; i++){
        vec2 pos = vec2(radius * cos(u_time / i), radius * sin(u_time / i));
        float dist = 0.02 / length(uv - pos); 
        dist *= 0.1;
        dist = pow(dist , 0.8);
        color += dist * vec3(1.0, 0.5, 0.25);

    }

    color = tanh(color); 

    fragColor = vec4(color, 1);
}

