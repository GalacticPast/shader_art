#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;
const float PI = 3.1415929;
const float MAX_DIST = 100.0;
const float MIN_DIST = 0.0001;

const float ATM_RAD = 6420e3;
const float ETH_RAD = 6360e3;
const float HEIGHT_RAY = 7994.0;
const float HEIGHT_MIE = 1200.0;

// Removed the 'f' suffix for standard GLSL compatibility
const vec3 BETA_RAY = vec3(3.8e-6, 13.5e-6, 33.1e-6);
const vec3 BETA_MIE = vec3(21e-6);

float Sd_sphere(vec3 p, vec3 sph_pos, float rad)
{
    return length(p - sph_pos) - rad;
}

float Get_waves(vec2 p)
{
    vec2 dir = vec2(1.0, 0.0);
    float freq = 1.0;
    float speed = 2.0;
    float weight = 1.0;

    float sum_wave  = 0.0;
    float sum_weight = 0.0;
    
    float t = 0.0;

    for(int i = 0 ; i < 32 ; i++)
    {
        float x = freq * dot(p, dir) + speed * u_time;
        float wave = exp(sin(x) - 1.0);
        float dx = wave * cos(x); 
        
        p += -dx * dir * weight * 0.3;

        sum_wave += wave * weight;
        sum_weight += weight;

        freq *= 1.12;
        speed *= 1.04; 
        weight = mix(weight, 0.0, 0.2);

        t += 781.892;
        dir = vec2(sin(t), cos(t));
    }

    return sum_wave / sum_weight;
}

float Map(vec3 p)
{
    float wave = Get_waves(p.xz);
    float plane = p.y - wave * 2.0;
    float d = plane;
    return d;
}

vec3 Get_normal(vec3 p) 
{
    vec2 e = vec2(0.0005, 0.0); 
    
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Ray_sph_intersect(vec3 p, vec3 dir, vec3 sph_pos, float sph_rad)
{
    vec3 p_s = sph_pos - p;

    float ang = dot(p_s, dir);

    float len_sq = dot(p_s, p_s);
    float H_sq = len_sq - (ang * ang); 
    if (H_sq > (sph_rad * sph_rad)) return 0.0;
    
    float p_len = sqrt((sph_rad * sph_rad) - H_sq); 
    float t_0 = ang - p_len;
    float t_1 = ang + p_len;

    if (t_0 > 0.0) return t_0;
    if (t_1 > 0.0) return t_1;

    return 0.0;
}

float Render(vec3 r_o, vec3 r_d)
{
    float t = 0.0;
    for(int i = 0 ; i < 128 ; i++)
    {
        vec3 p = r_o + r_d * t;
        float d = Map(p);
        t += d;
        if(d < MIN_DIST || t > MAX_DIST)break;
    }
    return t;
}

vec3 Get_camera_rd(vec2 uv, vec3 ro, vec3 ta, float zoom) 
{
    vec3 f = normalize(ta - ro);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 r = normalize(cross(worldUp, f));
    vec3 u = cross(f, r);
    return normalize(uv.x * r + uv.y * u + f * zoom);
}

float Get_shadow(vec3 p, vec3 light_pos)
{
    vec3 light_dir = normalize(light_pos - p);
    float t = 0.02;

    for(int i = 0 ; i < 32 ; i++)
    {
        vec3 pos = p + light_dir * t;
        float d = Map(pos);
        t += d;
        if(d < MIN_DIST)return 0.0;
        else if(t > MAX_DIST)break;
    }
    return 1.0;
}

vec3 Get_atmosphere(vec3 p, vec3 dir, vec3 sun_dir)
{
    float atm_intersect = Ray_sph_intersect(p, dir, vec3(0.0), ATM_RAD); 
    
     
    float ray_samples = 12.0;
    float light_samples = 8.0;
    
    float seg_length = atm_intersect / ray_samples; 
    
    vec3 sum_mie = vec3(0.0);
    vec3 sum_ray = vec3(0.0);
    
    float optical_depth_ray = 0.0;
    float optical_depth_mie = 0.0;
    
    float g = 0.76;
    float mu = dot(dir, sun_dir);
    
    float phase_ray = 3.0 / (16.0 * PI) * (1.0 + mu * mu); 
    float phase_mie = 3.0 / (8.0 * PI) * ((1.0 - g * g) * (1.0 + mu * mu)) / ((2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * mu, 1.5));
    
    float curr_sample_dist = 0.0;
    
    for(int i = 0; i < int(ray_samples); i++)
    {
        vec3 sam_p = p + dir * (curr_sample_dist + seg_length * 0.5);
        float height = length(sam_p) - ETH_RAD; 

        float opd_ray = exp(-height / HEIGHT_RAY) * seg_length; 
        float opd_mie = exp(-height / HEIGHT_MIE) * seg_length;

        optical_depth_ray += opd_ray;
        optical_depth_mie += opd_mie;

        float light_intersect_dist = Ray_sph_intersect(sam_p, sun_dir, vec3(0.0), ATM_RAD);
        float light_seg_length = light_intersect_dist / light_samples;

        float optical_light_depth_ray = 0.0;
        float optical_light_depth_mie = 0.0;
        float current_light_dist = 0.0; 

        for(int j = 0; j < int(light_samples); j++)
        {
            vec3 light_sam_p = sam_p + sun_dir * (current_light_dist + light_seg_length * 0.5);

            float height_light = length(light_sam_p) - ETH_RAD;
            if(height_light < 0.0) break; // Terminate if in Earth's shadow

            optical_light_depth_ray  += exp(-height_light / HEIGHT_RAY) * light_seg_length; 
            optical_light_depth_mie += exp(-height_light / HEIGHT_MIE) * light_seg_length; 

            current_light_dist += light_seg_length;
        }

        vec3 tau = BETA_RAY * (optical_depth_ray + optical_light_depth_ray) + 
                   BETA_MIE * 1.1 * (optical_depth_mie + optical_light_depth_mie);
                   
        vec3 attenuation = exp(-tau);
        
        sum_ray += attenuation * opd_ray;
        sum_mie += attenuation * opd_mie;

        curr_sample_dist += seg_length;
    }

    return (sum_ray * BETA_RAY * phase_ray + sum_mie * BETA_MIE * phase_mie) * 20.0; 
}

float Get_light(vec3 p, vec3 cam_pos, vec3 light_pos)
{
    vec3 light_dir = normalize(light_pos - p); 
    vec3 view_dir = normalize(cam_pos - p);

    vec3 n = Get_normal(p);
    vec3 h = normalize(view_dir + light_dir);  
     
    float diffuse = max(dot(light_dir, n),0.0);
    float spec = pow(max(dot(n, h), 0.0), 128);
    
    float light = diffuse + spec;
    return light; 
}

void main()
{
    vec2 uv = gl_FragCoord.xy * 2.0 / u_resolution.xy;
    uv -= 1.0; 
    uv.x *= u_resolution.x / u_resolution.y;
    
    vec3 r_o = ray_origin;
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0); 
    
    float t = Render(r_o, r_d);
    vec3 p = r_o + r_d * t;
    
    vec3 sun_pos = vec3(0.0, 100.0, 100.0);
    float light = Get_light(p, r_o, sun_pos);
    
    vec3 fog_color = vec3(0.5, 0.6, 0.7);             

    vec3 color = vec3(0.0);
    if(t < MAX_DIST)
    {
        color = light * fog_color;
    }
    else
    {
        vec3 planet_surface_origin = vec3(0.0, ETH_RAD, 0.0);
        
        vec3 sun_dir = normalize(sun_pos); 
        
        color = Get_atmosphere(planet_surface_origin, r_d, sun_dir);
        
        color = 1.0 - exp(-color * 1.5); 
    } 
    
    fragColor = vec4(color, 1.0);
}
