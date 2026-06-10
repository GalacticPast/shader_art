#version 330

// ep : 08 from cem yuskel Lights and shading
uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

#define PI 3.14159

float Sd_sphere(vec3 p, vec3 sph_pos, float radius)
{
    float sph = length(p - sph_pos) - radius;
    return sph;
}

float N21(vec2 p)
{
    float rand = fract(sin(p.x * 191.123 + p.y * 234.342) * 8324.84353); 
    return rand;
}

mat2 Rot2D(float angle){
    float a = cos(angle);
    float b = sin(angle);
    return mat2(a, -b,
                b,  a);
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
    for(int i = 0 ; i < 3 ; i++)
    {
        fbm += Value_noise(uv) * amp;
        uv *= 3.0; // freq 
        amp *= 0.5;
    }
    return fbm / 2; 
}

float Map(vec3 p)
{
    float plane = p.y + 1;
    float noise = Fbm(p.xz + 0.05 * u_time);
    float radius = 2.5 +  noise * 0.5;
    //float radius = 2.5;
    float sph = Sd_sphere(p, vec3(0.0, 0.0, 0.0), radius);
    //float d = min(sph, plane);
    float d = sph;
    return d;
}
vec3 Get_normal(vec3 p) 
{
    vec2 e = vec2(0.001, 0.0); // A tiny offset
    
    // Sample the scene slightly to the left/right on each axis
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Get_light(vec3 p)
{
    vec3 light_pos = vec3(0, 0, -10);
    vec3 N = Get_normal(p);

    vec3 light_dir = normalize(light_pos - p);

    float light = dot(N, light_dir);
    return max(light, 0.0);
}


void main()
{
    vec2 uv = (gl_FragCoord.xy * 2)/ u_resolution.xy;
    uv -= 1; 
    uv.x *= u_resolution.x / u_resolution.y;
    //zoomed in
    vec3 r_o = vec3(0,1.8,-2.3);
    vec3 r_d = normalize(vec3(vec2(uv), 1.0));

    r_o.xz *= Rot2D(PI);
    r_d.xz *= Rot2D(PI);
    //vec3 r_o = vec3(0,1.0,-3);
    //vec3 r_o = vec3(0.0,0.0,-5);

    float t = 0.0;
    float glow = 0.0;

    bool hit = false;
    for(int i = 0 ; i < 100 ; i++)
    {
        vec3 pos = r_o + r_d * t;
        float d = Map(pos);
        t += d;
        if(d < 0.001)
        {
            hit = true;
            break;
        } 
        if(d > 100.0)break;
    }

    vec3 hit_pos = r_o + r_d * t;
    float light =  Get_light(hit_pos);
    vec3 color = vec3(0.0);
        
    if(hit)
    {
        vec3 normal = normalize(hit_pos);

        float u = atan(normal.z, normal.x); 
        float v = asin(normal.y);           

        float densityU = 10.0;
        float densityV = 10.0;
        
        vec2 g = fract(vec2(u * densityU, v * densityV));
        color += 0.05 / length(g) * vec3(1.0);
        
        // float line_thickness = 0.95; 
        // if(g.x > line_thickness || g.y > line_thickness)
        // {
        //     color = vec3(0.0); 
        // }

    }

    fragColor = vec4(color, 1.0);
}
