#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 frag_color;

float N21(vec2 p)
{
    float rand = fract(sin(p.x * 191.123 + p.y * 234.342) * 8324.84353); 
    return rand;
}

float Value_noise(vec2 uv)
{
    vec2 id = floor(uv);
    vec2 f = fract(uv); 
    
    f = smoothstep(0.0, 1.0, f);

    float l_b_hash = N21(id);
    float r_b_hash = N21(id + vec2(1.0, 0.0)); 
    float l_t_hash = N21(id + vec2(0.0, 1.0)); 
    float r_t_hash = N21(id + vec2(1.0, 1.0)); 
    
    float lr_b = l_b_hash + (r_b_hash - l_b_hash) * f.x;
    float lr_t = l_t_hash + (r_t_hash - l_t_hash) * f.x;
    float lr_bt = lr_b + (lr_t - lr_b) * f.y;

    return lr_bt; 
}

float Fbm(vec2 uv){
    float fbm = 0.0; 
    float amp = 1.0;
    for(int i = 0 ; i < 4 ; i++)
    {
        fbm += Value_noise(uv) * amp;
        uv *= 2.0; // freq 
        amp *= 0.5;
    }
    return fbm / 2; 
}

mat2 Rot2D(float angle){
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle));
}


void main()
{
    vec2 res = u_resolution.xy;
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    vec2 uv = (frag_coord * 2.0)/ u_resolution;  
    uv -= 1.0;  
    uv.x *= u_resolution.x / u_resolution.y; 
    uv *= 2.0; 

    vec3 color = vec3(0); 

    float rad = 0.72; 
    uv.x += Fbm(uv + 0.3 * sin(2 * u_time));  
    uv.y += Fbm(uv + 0.1 * cos(1 * u_time));  

    float theta = atan(uv.y, uv.x);
    float twist_strength = 1.0; 
    
    float r = length(uv);
    theta += (r * twist_strength) - u_time * 2.0; 


    // 3. Convert back to Cartesian Coordinates
    uv = vec2(r * cos(theta), r * sin(theta));

    // Now, anything you draw using 'uv' (like your grid or blobs) 
    // will be sucked into a swirling spiral!

    vec2 gv = fract(uv);
    if(gv.x > 0.98){
        color = vec3(0.8, 0,0);
    }
    if(gv.y > 0.98){
        color = vec3(0,0.8,0);
    }

    frag_color = vec4(color, 1);
} 
