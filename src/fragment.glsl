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


float Get_waves(vec3 p)
{
    vec2 dir = vec2(0.0, 1.0);
    float freq = 1.0;
    float amp = 1.0;
    float speed = 1.0;
    float weight = 1.0; 

    float sum_wave = 0.0;
    float iter = 8921.3475;

    for(int i = 0 ; i < 12 ; i++)
    {
        vec2 pos = vec2(p.x, p.z);
        float x = freq * dot(pos, dir) + speed * u_time;
        sum_wave += weight * exp(amp * sin(x) - 1.0); 
        freq *= 1.3;
        amp *= 0.3;
        speed *= 2.0;
        weight *= 0.9;
        dir = vec2(sin(iter), cos(iter));
        iter += 9234.57324;
    }

    return sum_wave; 
}

float Map(vec3 p)
{
    float wave = Get_waves(p);
    float plane = p.y - wave + 3.0;

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
    float step = MIN_DIST;
    for (int i = 0; i < 8; i++) {
        step *= 0.5;
        float d = Map(r_o + r_d * t);
        t += (d > 0.0) ? step : -step;
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

    vec3 n = Get_normal(p);
    vec3 h = normalize(cam_pos + light_pos);  

    float light = dot(n, h);

    return light; 
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
    
    vec3 light_pos = vec3(10.0, 100.0, 10.0);
    float light = Get_light(p, r_o, light_pos);
    
    vec3 color = vec3(0.0);
    if(t < MAX_DIST)
    {
        color = light * vec3(0.0, 0.032, 1.0);
    }
    else
    {
        vec3 white = vec3(1.0, 1.0, 1.0);
        vec3 sky_blue = vec3(0.4, 0.7, 1.0); 
        float sky_blend = clamp(r_d.y, 0.0, 1.0);
        color = mix(white, sky_blue, sky_blend);
    }
    
    fragColor = vec4(color, 1.0);
}
