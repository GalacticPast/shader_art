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

    // 2. THE SHAPE: A basic circle
    // length(p) is distance from center. Subtracting 0.5 makes a circle of radius 0.5.
    float dist = Sd_heart(uv - vec2(0, -0.5));
    
    // Taking the absolute value turns a solid circle into an outline (a ring)
    float heart = abs(dist);

    // 3. THE LIGHT: A single, stationary spotlight
    // This vector points to the top-right. 
    vec2 lightDirection = normalize(vec2(sin(u_time),cos(u_time))); 
    
    // The dot product calculates how much each pixel's position aligns with the light
    float spotlight = dot(uv, lightDirection); 

    // 4. THE COLOR & GLOW
    vec3 baseColor = vec3(0.2, 0.8, 1.0); // A nice cyan/blue
    
    // Here is the magic formula broken down:
    // (0.05 / heart) creates the glow. As 'heart' gets closer to 0, the brightness shoots up.
    // (spotlight + 0.5) applies the light. The +0.5 ensures the dark side isn't pitch black.
    vec3 finalColor = baseColor * (spotlight + 0.8) * (0.02 / heart);

    // Output to the screen!
    fragColor = vec4(finalColor, 1.0);
}

