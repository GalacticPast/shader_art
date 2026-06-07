#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 frag_color;

#define PI 3.1459

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
    for(int i = 0 ; i < 19 ; i++)
    {
        fbm += Value_noise(uv) * amp;
        uv *= 3.0; // freq 
        amp *= 0.5;
    }
    return fbm / 2; 
}

mat2 Rot2D(float angle){
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle));
}

vec3 Tonemap_rh(vec3 color) {
    return color / (color + vec3(1.0));
}

vec3 ACES(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 Get_col(float t)
{
    float rand = N21(vec2(t));
    return vec3(sin(rand), cos(rand), sin(rand * rand));
}
void main()
{
    vec2 res = u_resolution.xy;
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    vec2 uv = (frag_coord * 2.0)/ u_resolution;  
    uv -= 1.0;  
    uv.x *= u_resolution.x / u_resolution.y; 
    uv *= 0.03;
    vec3 color = vec3(0); 

    vec3 base_color = vec3(0);     

    float t = u_time;
    float fract_scale = 0.5;

    for(int i = 0 ; i < 19 ; i++)
    {
        fract_scale += 0.03; 
        float local_t = t + i; // Offset time per iteration

        // 2. Rotate the space (You had this right!)
        uv *= Rot2D(i + 0.02 * local_t);

        // 3. The FULL Space Distortion (Micro + Macro)
        vec2 tanhTerm = tanh(40.0 * dot(uv, uv) * cos(100.0 * uv.yx + local_t)) / 200.0;
        vec2 scaleTerm = 0.2 * fract_scale * uv;
        // Notice how the color variable itself feeds back into distorting the space!
        float cosTerm = cos(4.0 / exp(dot(color, color) / 100.0) + local_t) / 300.0; 

        uv += tanhTerm + scaleTerm + cosTerm;

        // 4. The Chaotic Shape (The Magnifying Glass)
        // The division by (0.5 - dot(uv,uv)) is what makes the tiny ripples explode
        vec2 crazy_shape = 1.5 * uv / (0.5 - dot(uv, uv)) - 9.0 * uv.yx + local_t;
        float light = 1.0 / length(sin(crazy_shape));

        // 5. Shifting Colors
        // Instead of flat red, we use cos() to cycle through RGB colors over time
        vec3 phase_color = vec3(1.0) + cos(vec3(1.0, 2.0, 3.0) + local_t);
        color += (light * 0.05) * phase_color;
        //vec2 gv = fract(uv);
        // if(gv.y > 0.98) color += vec3(0.0, 1.0, 0.0);
        // if(gv.x > 0.98) color += vec3(1.0, 0.0, 0.0);
    }
     
    color = Tonemap_rh(color - 0.8);
    frag_color = vec4(color, 1);
} 
