#version 330

// ep : 08 from cem yuskel Lights and shading
uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 frag_color;

#define PI 3.1459
#define MAX_DIST 16 
#define MIN_DIST 0.001 

float Sd_sph(vec3 ray_pos, vec3 sph_pos, float radius)
{
    return length(ray_pos - sph_pos) - radius;
}

mat2 Rot2d(float rad)
{
    float a = cos(rad);
    float b = sin(rad);
    return mat2(a, -b, b, a);
}

float Map(vec3 p)
{
    float plane_bottom = p.y;
    float plane_top    = 6 - p.y;
    
    return  min(plane_bottom, plane_top);
}

float Render(vec3 r_o, vec3 r_d)
{
    float t = 0.0;
    
    for(int i = 0 ; i < MAX_DIST ; i++)
    {
        vec3 p = r_o + r_d * t;
        float d = Map(p);
        t += d;
        if(d < MIN_DIST || d > MAX_DIST)break;
    }
    return t;
}

vec3 Get_normal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0); // A tiny offset

    // partial derivatives. Gradients see multivariable calculus for this  
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Get_AO(vec3 p, vec3 n) 
{
    float occ = 0.0;
    float weight = 1.0;
    for(int i = 0; i < 5; i++) {
        float len = 0.01 + 0.05 * float(i);
        float dist = Map(p + n * len);
        
        // If the distance to the nearest object is less than how far 
        // we stepped, we are inside a crevice.
        occ += (len - dist) * weight;
        weight *= 0.85; // Less impact the further away we step
    }
    return 1.0 - clamp(0.5 * occ, 0.0, 1.0);
}

float Get_shadow(vec3 p, vec3 light_dir)
{
    float t = 0.05; 
    
    float max_dist = 20.0; 

    for(int i = 0; i < 50; i++) {
        float d = Map(p + light_dir * t); 
        
        if(d < 0.001) {
            return 0.1; 
        }
        
        t += d;
        if(t > max_dist) break;
    }
    
    return 1.0; 
}

float Get_light(vec3 pos, vec3 r_o)
{
    vec3 light_pos = vec3(0.0, 20.0, 0.0);

    vec3 N = Get_normal(pos); 
    vec3 light_dir = normalize(light_pos - pos); 
    float diffuse = max(dot(light_dir, N), 0.0);

    vec3 camera_dir = normalize(r_o - pos);
    vec3 perfect_spec = reflect(-light_dir, N); // phill model

    vec3 half_vec = normalize(light_dir + camera_dir); // blinn model
    float spec_amount = max(dot(camera_dir, half_vec), 0.0);
    float specular = pow(spec_amount, 100.0); 

    //4 + 4*smoothstep(0,0.7,sin(x+t))
    vec2 falloff = fract(pos.xz / 3); 
    falloff -= 0.5;
    float light = 0.0;
    light = 0.05 / length(falloff);
    //float light = diffuse;
    float shadow = Get_shadow(pos, light_dir);
    float ao = Get_AO(pos, N);

    // light *= shadow;
    // light *= ao;

    return light; 
}

void main()
{
    vec2 res = u_resolution.xy;
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    vec2 uv = (frag_coord * 2.0)/ u_resolution;  
    uv -= 1.0;  
    uv.x *= u_resolution.x / u_resolution.y; 

    vec3 r_o = vec3(0, 2, -5);
    vec3 r_d = normalize(vec3(uv, 1.0)); 

    float rad = PI / 6;
    mat2 rot = Rot2d(rad);
    // r_o.yz *= rot; 
    // r_d.yz *= rot; 

    float hit_dist = Render(r_o, r_d);
    vec3 final_color = vec3(0.0);

    // 1. Surface Lighting
    if(hit_dist < MAX_DIST) 
    {
        vec3 p = r_o + r_d * hit_dist;

        float surface_light = Get_light(p, r_o); 
        final_color = vec3(abs(sin(p.x * 0.2)), abs(sin(p.y * 0.3)), abs(sin(p.z * 0.2))) * surface_light; 
        vec2 gv = fract(p.xz);
        //float grid_line = smoothstep(0.92, 0.97, max(gv.x, gv.y));
        //final_color += vec3(1) * grid_line;
    }

    frag_color = vec4(final_color, 1.0); 
}
