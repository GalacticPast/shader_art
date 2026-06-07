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
    float plane = p.y + 0.5;
    return min(sph, plane);
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

vec3 Get_normal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0); // A tiny offset

    // partial derivatives. Gradients see multivariable calculus for this  
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Get_shadow(vec3 p, vec3 light_dir)
{
    float t = 0.05; 
    
    // How far we care to check (roughly the distance to the light)
    float max_dist = 20.0; 

    for(int i = 0; i < 50; i++) {
        // March forward from the surface toward the light
        float d = Map(p + light_dir * t); 
        
        // If we hit something, we are in shadow!
        if(d < 0.001) {
            return 0.1; // Return 0.1 instead of 0.0 so shadows aren't pitch black
        }
        
        t += d;
        
        // If we marched past our light distance, we didn't hit anything.
        if(t > max_dist) break;
    }
    
    return 1.0; // Fully lit
}

float Get_light(vec3 pos, vec3 r_o)
{
    vec3 light_pos = vec3(2 + sin(u_time), 5 , 2 + cos(u_time));

    vec3 N = Get_normal(pos); 
    vec3 light_dir = normalize(light_pos - pos); 
    float diffuse = max(dot(light_dir, N), 0.0);

    vec3 camera_dir = normalize(r_o - pos);
    //vec3 perfect_spec = reflect(-light_dir, N); // phill model
    //float spec_amount = max(dot(camera_dir, half_vec), 0.0);

    vec3 half_vec = normalize(light_dir + camera_dir); // blinn model
    float spec_amount = max(dot(N, half_vec), 0.0);
    float specular = pow(spec_amount, 100.0); 

    float light = diffuse + specular + 0.1;
    float shadow = Get_shadow(pos, light_dir);
    light *= shadow;
    return light; 
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
    vec3 p = r_o + r_d * d;

    float l = Get_light(p, r_o);
    vec3 color = l * vec3(1, 1, 1); 

    frag_color = vec4(color, 1);
} 
