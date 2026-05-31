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

    float dist = Sd_heart(uv - vec2(0, -0.5));
    float heart = abs(dist);

    vec2 lightDirection = normalize(vec2(sin(u_time),cos(u_time))); 
    
    float spotlight = dot(uv, lightDirection); 

    vec3 baseColor = vec3(0.8, 0.1, 0.2); // A nice cyan/blue
    
    vec3 finalColor = baseColor * (spotlight + 1.0) * (0.09 / heart);

    // Output to the screen!
    fragColor = vec4(finalColor, 1.0);
}

