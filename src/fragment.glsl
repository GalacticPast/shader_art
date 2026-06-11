#version 330

// ep : 08 from cem yuskel Lights and shading
uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

#define PI 3.14159
#define MAX_DIST 100 
#define MIN_DIST 0.001 

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
        uv *= 2.0; 
        amp *= 0.5;
    }
    return fbm / 2.0; 
}

float Sd_box( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}


float Map(vec3 p)
{
    float wave_weight = 0.0;  
    float freq = 1.0;
    float amp = 1.0;
    float speed = 2.0;
    

    float plane = p.y + 1.0;
    return plane + wave_weight;
}

vec3 Get_normal(vec3 p) 
{
    vec2 e = vec2(0.001, 0.0); 
    
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Get_light(vec3 p, vec3 cam_pos)
{
    vec3 light_pos = vec3(0.0, 10.0, 0.0);
    vec3 N = Get_normal(p);
    vec3 L = normalize(light_pos - p); // Points from surface to light
    vec3 V = normalize(cam_pos - p);   // Points from surface to camera

    // Invert L so it points TO the surface for the reflection formula
    vec3 ref_light_vector = reflect(-L, N);  
     
    // Both vectors now point away from the surface properly
    float specular = clamp(dot(ref_light_vector, V), 0.0, 1.0);
    specular = 0.8 * pow(specular, 30); 

    float diff = clamp(dot(L, N), 0.0, 1.0);
    
    return diff + specular; 
}

vec3 Get_camera_rd(vec2 uv, vec3 ro, vec3 ta, float zoom) 
{

    vec3 f = normalize(ta - ro);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 r = normalize(cross(worldUp, f));
    vec3 u = cross(f, r);
    
    return normalize(uv.x * r + uv.y * u + f * zoom);
}

void main() 
{
    vec2 frag_coord = gl_FragCoord.xy;

    vec2 uv = (frag_coord.xy * 2.0 )/ u_resolution.xy;
    uv -= 1.0;
    uv *= u_resolution.x / u_resolution.y;

    vec3 color = vec3(0.0);

    vec3 r_o = ray_origin;     
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0);
    
    float t = 0.0;
    for(int i = 0 ; i < MAX_DIST ; i++)
    {
        vec3 pos = r_o + r_d * t; 
        float d = Map(pos);
        t += d;
        if(d < MIN_DIST || d > MAX_DIST)break;
    }

    vec3 p = r_o + r_d * t; 

    if(t < MAX_DIST)
    {
        float light = Get_light(p, r_o); 
        color = light * vec3(0.0, 0.8,0.835);
    }
    else
    {
        color = vec3(0.3, 0.3,0.3);
    }

    fragColor = vec4(color, 1.0);
}
