#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

#define MAX_DIST 100.0
#define MIN_DIST 0.0
#define EPS 0.001


vec3 Inf_rep( vec3 p, vec3 spacing)
{
    vec3 q = p - spacing * round(p / spacing);
    return q;
}

vec3 Lim_rep(vec3 p, float s, vec3 l)
{
    vec3 q = p - s*clamp(round(p/s),-l,l);
    return q;
}

float Sd_sphere(vec3 uv, vec3 sphere_pos, float r)
{
    return length(uv - sphere_pos) - r;
}

float Map(vec3 p) 
{
    vec3 sphere_pos = vec3(p.x, 0, 0);
    float sph = Sd_sphere(p,sphere_pos, 0.5); 
    
    float plane = p.y;

    return min(sph, plane); 
}

float Raymarch(vec3 ray_origin, vec3 ray_dir) 
{
    float t = 0.0;

    for(int i = 0; i < 100; i++) {
        vec3 pos = ray_origin + ray_dir * t;     
        
        float d = Map(pos); 
        t += d;

        if(d < EPS || t > MAX_DIST) {
            break;
        }
    }
    return t;
}
mat2 rot2D(float angle) 
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

vec3 Get_normal(vec3 pos){
    float h = 0.001;
    vec2  gradient = vec2(h, 0);
    
    float dx = Map(pos + gradient.xyy) - Map(pos - gradient.xyy); // x dist
    float dy = Map(pos + gradient.yxy) - Map(pos - gradient.yxy); // y dist
    float dz = Map(pos + gradient.yyx) - Map(pos - gradient.yyx); // z dist

    vec3 normal = normalize(vec3(dx, dy, dz));

    return normal;
}

float Get_light(vec3 pos)
{
    vec3 light_pos = vec3(10, 20, 0);
    vec3 norm = Get_normal(pos);

    vec3 light_dir = normalize(light_pos - pos); 
    
    float l = max(dot(norm, light_dir), 0.0);
    

    return l ;
}

void main() 
{
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);

    vec2 uv = (frag_coord * 2)/ u_resolution;
    uv -= 1.0;
    uv.x *= u_resolution.x / u_resolution.y; 
    

    vec3 rO = vec3(0.0, 0.2, -3.0); 
    vec3 rD = normalize(vec3(uv, 1.0));
    
    float rad = 0.25;
    rO.yz *= rot2D(rad); 
    rD.yz *= rot2D(rad);

    float d = Raymarch(rO, rD); 
    vec3 pos = rO + rD * d;

    float light = Get_light(pos);

    vec3 f_color = vec3(1) * light; 

    fragColor = vec4(f_color, 1.0);
}
//uv *= 10;

    // vec2 gv = fract(uv);
    // vec2 grid = step(0.95, gv); 
    //
    // vec2 pos = floor(uv) + 0.5;   
    //
    //
    // vec3 color = vec3(0);
    // color += grid.x * vec3(0.3,0,0.3); 
    // color += grid.y * vec3(0,0.3,0.3); 
    //
    //
    // float circle = Circle(uv,pos, 0.1);
    //
    // float center = Circle(uv, vec2(0), 0.1);
    //

