#version 330

// ep : 08 from cem yuskel Lights and shading
uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

#define PI 3.14159

float Sd_sphere(vec3 p, vec3 sph_pos, float radius)
{
    float sph = length(p - sph_pos) - radius;
    return sph;
}

float Sd_torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float Sd_capsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
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
    return fbm / 2.0; 
}

float Map(vec3 p)
{
    float plane = p.y + 1.0;
    float noise = Fbm(p.zz - 0.05 * u_time);

    //float d = min(sph, plane);
    // p.xy *= Rot2D(PI / 2.0);
    // p.xz *= Rot2D(PI / 2.0);
    p.z += 1 / sin(20 * u_time);
    float radius = 0.1 + 0.1 * sin(2 *  p.z - u_time);
    float capsule = Sd_capsule(p,vec3(0.0), vec3(0.0,0.0,10.0), 1);
    
    float d = min(capsule, plane);
    // //float d = capsule;
    // d = min(d, capsule_1);
    // d = min(d, capsule_2);
    // d = min(d, capsule_3);
    
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
    vec3 light_pos = vec3(0.0, 10.0, -10.0);
    vec3 N = Get_normal(p);

    vec3 light_dir = normalize(light_pos - p);

    float light = dot(N, light_dir);
    return max(light, 0.0);
}
float Get_glow(float dist, float radius, float intensity)
{
	return pow(radius / max(dist, 1e-6), intensity);	
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
    vec2 uv = (gl_FragCoord.xy * 2.0)/ u_resolution.xy;
    uv -= 1; 
    uv.x *= u_resolution.x / u_resolution.y;

    vec3 r_o = ray_origin;
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0);


    float t = 0.0;
    float glow = 0.0;

    bool hit = false;
    for(int i = 0 ; i < 100 ; i++)
    {
        vec3 pos = r_o + r_d * t;
        float d = Map(pos);
        t += d * 0.5;
        float glow_mask = sin(-pos.z + 3 * u_time);
        glow += Get_glow(d, 0.01, 0.8) * glow_mask;
        if(d < 0.001)
        {
            hit = true;
            break;
        } 
        if(d > 100.0)break;
    }

    vec3 hit_pos = r_o + r_d * t;
    float light = Get_light(hit_pos);
    vec3 color = light * vec3(1.0);
    // vec3 color = vec3(0.0);
    // color += glow * vec3(1.0, 0.0, 0.0);
        
    if(hit)
    {
        vec3 normal = normalize(hit_pos);

        float u = atan(normal.z, normal.x); 
        float v = asin(normal.y);           

        float densityU = 10.0;
        float densityV = 10.0;
        
        
        // float line_thickness = 0.95; 
        // if(g.x > line_thickness || g.y > line_thickness)

        // {
        //     color = vec3(0.0); 
        // }

    }
    fragColor = vec4(color, 1.0);
}

