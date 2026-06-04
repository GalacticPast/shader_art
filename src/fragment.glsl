#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

#define MAX_DIST 100.0
#define MIN_DIST 0.0
#define EPS 0.001
#define GRID_SIZE 3.0
#define PI 3.1459

float N21(vec2 p){
    p = fract(p * vec2(289.31231, 381.12312));
    p += dot(p, p+20.3124);
    return fract(p.x * p.y);
}
vec2 N22(vec2 p){
    float n = N21(p);
    return vec2(n, N21(p + n));
}

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

float Sd_sphere(vec3 sphere_pos, float r)
{
    return length(sphere_pos) - r;
}
// p -> pos , a -> begin, b -> end , r -> radius
// https://iquilezles.org/articles/distfunctions/ Thank you iq!!! Thank you iq!!! Thank you iq!!! :)
float Sd_capsule(vec3 p, vec3 a, vec3 b, float r) 
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

vec2 Get_id(vec3 p){
    vec2 id = floor(p.xz / GRID_SIZE);
    return id;
}

vec2 Get_pos(vec2 id)
{
    //vec2 ran = N22(id); 
    vec2 p = vec2(id.x * GRID_SIZE + GRID_SIZE / 2, id.y * GRID_SIZE + GRID_SIZE / 2); 
    return p;
}

float Map(vec3 p) 
{

    vec3 q = p; 
    vec2 id = Get_id(p);
    float sphere_height = 2.0; 
    //float sphere_height = 2.0; 

    float min_line = 99999.0;

    vec2 current_pos_2d = Get_pos(id);
    vec3 current_center = vec3(current_pos_2d.x, sphere_height, current_pos_2d.y);

    // float dx[8] = float[8](-1.0, 0.0, 1.0, -1.0, 1.0, -1.0, 0.0, 1.0);
    // float dy[8] = float[8]( 1.0, 1.0, 1.0, 0.0, 0.0, -1.0, -1.0, -1.0);
    // float dx[4] = float[4](0.0, 1.0, 0.0, -1.0);
    // float dy[4] = float[4]( 1.0 , 0.0, -1.0, 0.0);
    // for(int i = 0 ; i < 4 ; i++)
    // {
    //     vec2 n_id = vec2(id.x + dx[i], id.y + dy[i]);
    //     vec2 n_pos = Get_pos(n_id);  
    //     float n_sph_h = 2.0 + sin(u_time + n_id.x + n_id.y); 
    //
    //     float line = Sd_capsule(p, current_center, vec3(n_pos.x, n_sph_h, n_pos.y),0.2);
    //     min_line = min(min_line, line);
    // } 

    // folded space
    vec2 rand = (N22(id) - 0.5) * 2.0;
    q.x = mod(p.x, GRID_SIZE) - (GRID_SIZE / 2.0);
    q.x += rand.x;
    q.y = p.y - (rand.x + rand.y + 1.0);
    q.z = mod(p.z, GRID_SIZE) - (GRID_SIZE / 2.0);
    q.z += rand.y;

    float sph = Sd_sphere(q, 0.5);  
    float plane = p.y;

    float d =  min(sph, plane);
    d = min(min_line, d);
    return d; 
}

float Raymarch(vec3 ray_origin, vec3 ray_dir) 
{
    float t = 0.0;

    for(int i = 0; i < MAX_DIST; i++) {
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

    vec3 rO = vec3(0.0, 2, -8.0); 
    vec3 rD = normalize(vec3(uv, 1.0));
     
    float rad = PI / 2;
    rO.yz *= rot2D(rad); 
    rD.yz *= rot2D(rad);
    rO.xz *= rot2D(rad);
    rD.xz *= rot2D(rad);

    float d = Raymarch(rO, rD); 
    vec3 pos = rO + rD * d;
    
    float random = N21(uv);

    float light = Get_light(pos);
    vec3 f_color = vec3(1) * light; 
    if(d > 45) f_color = vec3(0);
    float grid_size = 3.0;

    if(mod(pos.x, grid_size) > grid_size - 0.1){
        f_color = vec3(0);
    } 
    if(mod(pos.z, grid_size) > grid_size - 0.1){
        f_color = vec3(0);
    } 
     

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

