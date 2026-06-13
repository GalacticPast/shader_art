#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

#define MAX_DIST 100.0
#define MIN_DIST 0.001



vec3 Get_camera_rd(vec2 uv, vec3 ro, vec3 ta, float zoom) 
{
    vec3 f = normalize(ta - ro);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 r = normalize(cross(worldUp, f));
    vec3 u = cross(f, r);
    return normalize(uv.x * r + uv.y * u + f * zoom);
}

float Map(vec3 p) 
{
    float plane = p.y + 1.0;

    float d = plane;
    
    return d;
}

vec3 Get_normal(vec3 p) 
{
    vec2 e = vec2(0.01, 0.0); 
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    return normalize(vec3(dx, dy, dz));
}

float Render(vec3 r_o, vec3 r_d)
{
    float t = 0.0;

    for(int i = 0 ; i < MAX_DIST ; i++)
    {
        vec3 pos = r_o + r_d * t;
        float d = Map(pos);
        t += d;
        if(d < MIN_DIST || d > MAX_DIST)break;
    }
    return t;
}

float Get_shadow(vec3 pos, vec3 light_pos)
{
    vec3 light_dir = normalize(light_pos - pos);
    float t = 0.02;
    for(int i = 0 ; i < 12.0 ; i++)
    {
        vec3 p = pos + light_dir * t; 
        float d = Map(p);
        t += d;
        if(d < MIN_DIST)return 0.0;
        else if(d > MAX_DIST)break;
    }
    return 1.0;
}

float Get_light(vec3 pos, vec3 cam_pos, vec3 light_pos)
{
    vec3 N = Get_normal(pos);

    vec3 light_dir = normalize(light_pos - pos); 
    vec3 cam_dir = normalize(cam_pos - pos); 
    vec3 H = normalize(light_dir + cam_dir);

    float diffuse = max(dot(light_dir, N), 0.0);
    float spec = pow(max(dot(N, H), 0.0),32.0); 
    float light = diffuse + spec * 0.3;

    return light;
}


void main() {
    vec2 frag_coord = gl_FragCoord.xy;
    vec2 uv = (frag_coord.xy * 2.0 ) / u_resolution.xy;
    uv -= 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    vec3 r_o = ray_origin;     
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0);
    
    float d = Render(r_o, r_d);
    vec3 p = r_o + r_d * d; 

    vec3 light_pos = vec3(1.0 + 10 * sin(u_time), 10.0, 1.0 + 10 * cos(u_time));
    float light = Get_light(p, r_o, light_pos);
    float shadow = Get_shadow(p, light_pos); 

    vec3 color = light * vec3(0.0, 0.895, 1.0) * shadow;

    fragColor = vec4(color, 1.0);
}
