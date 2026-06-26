#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

const float MAX_DIST = 100.0;
const float MIN_DIST = 0.0001;


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
    float sph = Sd_sphere(p, vec3(0.0, 2.0, 0.0),1.0);
    float d = plane;
    d = min(d, sph);
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

vec3 Get_atp(vec3 p, vec3 dir, vec3 sun_dir)
{
    //sundir.y = max(sundir.y, -0.07);
    float special_trick = 1.0 / (dir.y * 1.0 + 0.1);
    float special_trick2 = 1.0 / (sun_dir.y * 11.0 + 1.0);
    float raysundt = pow(abs(dot(sun_dir, dir)), 2.0);
    float sundt = pow(max(0.0, dot(sun_dir, dir)), 8.0);
    float mymie = sundt * special_trick * 0.2;
    vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - vec3(5.5, 13.0, 22.4) / 22.4), special_trick2);
    vec3 bluesky= vec3(5.5, 13.0, 22.4) / 22.4 * suncolor;
    vec3 bluesky2 = max(vec3(0.0), bluesky - vec3(5.5, 13.0, 22.4) * 0.002 * (special_trick + -6.0 * sun_dir.y * sun_dir.y));
    bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
    return bluesky2 * (1.0 + 1.0 * pow(1.0 - dir.y, 3.0)); 
}

void main()
{
    vec2 uv = gl_FragCoord.xy * 2.0/ u_resolution.xy;
    uv -= 1.0; 
    uv.x *= u_resolution.x / u_resolution.y;
    
    vec3 r_o = ray_origin;
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0); 
    
    float t = Render(r_o, r_d);
    vec3 p = r_o + r_d * t;
    
    vec3 light_pos = vec3(0.0, 100.0, 100.0);
    float light = Get_light(p, r_o, light_pos);
    
    vec3 fog_color = vec3(0.5, 0.6, 0.7); 
    float fog_density = 0.01;             

    vec3 color = vec3(0.0);
    if(t < MAX_DIST)
    {
        vec3 N = Get_normal(p);
        N = mix(N, vec3(0.0, 1.0, 0.0), 0.8 * min(1.0, sqrt(t * 0.01) * 1.1));

        vec3 R = normalize(reflect(r_d, N));
        R.y = abs(R.y); 
        vec3 reflection = Get_atp(p, R, light_pos);

        color = light * fog_color;
        float fog_factor = exp(-fog_density * t);

        color = mix(fog_color, color, fog_factor);
    }
    else
    {
        color = Get_atp(p, r_d, normalize(light_pos)) * 0.5;
    } 
    fragColor = vec4(color, 1.0);
}
