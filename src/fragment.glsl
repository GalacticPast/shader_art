#version 330
//https://www.shadertoy.com/view/wsfGWH
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
    for(int i = 0 ; i < 3 ; i++)
    {
        fbm += Value_noise(uv) * amp;
        uv *= 3.0; // freq 
        amp *= 0.5;
    }
    return fbm / 2.0; 
}

float Get_waves(vec2 p)
{
    vec2 dir = vec2(0.40, 1.0);
    float wave = 0.0; 
    float weight = 1.0;
    float speed = 2.0;
    float amp = 0.4;
    float freq = 1.0;
    float t = 0.0; 

    for(int i = 0 ; i < 12 ; i++)
    {
        float x = freq * dot(p, dir) + u_time * speed;
        float w = exp(amp * sin(x) - 1.0);
        float dx = cos(x) * w;

        wave += w * weight; 
        p += dir * -dx * weight * 0.3;
        speed *= 1.08;
        amp *= 0.68;
        freq *= 1.34;
        weight *= 0.9;
        t += 12131.198;
        dir = vec2(sin(t), cos(t));
    }
    return wave; 
}
vec3 Op_lim_rep( vec3 p, float s, vec3 l)
{
    vec3 q = p - s*clamp(round(p/s),-l,l);
    return q;
}

float Sd_round_box( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b + r;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float Map(vec3 p) 
{
    //float wave = Get_waves(p.xz);
    float wave = 0.0;
    float plane = p.y + 3.0 - wave;

    vec3 q = Op_lim_rep(p, 2.0, vec3(0.0,0.0, 1.0)); 
    float box = Sd_round_box(q, vec3(1.5, 0.1, 1.0), 0.1);

    float d = min(plane, box);

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
        if(d < MIN_DIST || t > MAX_DIST)break;
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
        else if(t > MAX_DIST)break;
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
    float spec = pow(max(dot(N, H), 0.0),256.0); 
    float light = diffuse + spec * 23.0;

    return light;
}

vec2 Ray_sph_intersect()
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

float Get_atmosphere(vec3 p, vec3 cam_pos)
{
    return 0.0;
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

    vec3 color = vec3(0.0);
    
    if(d < 100.00)
    {
        vec3 light_pos = vec3(0.0, 10.0, 20.0);
        float light = Get_light(p, r_o, light_pos);
        float shadow = Get_shadow(p, light_pos); 
        color = shadow * light * vec3(0.0, 0.2, 0.3);
    }
    else
    {
        p = normalize(p);
        color = vec3(0.0, 0.843, 1.0) - (0.4 *p.y);
    }

    color = pow( color, vec3(1.0/2.2));
    fragColor = vec4(color, 1.0);
}
