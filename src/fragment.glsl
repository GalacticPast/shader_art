#version 330


uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

#define PI 3.14159

float Sd_ellipsoid( vec3 p, vec3 pos, vec3 r )
{
    vec3 el_pos  = p - pos;
    float k0 = length(el_pos/r);
    float k1 = length(el_pos/(r*r));
    return k0*(k0-1.0)/k1;
}

float Sd_sphere(vec3 p, float r){
    return length(p) - r; // return a sphere centered on the origin with radius of 1. 
}

float Sd_capsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float Sd_vertical_capsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

mat2 Rotate2d(float angle){
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle));
}

float Get_model(vec3 p)
{
    float g_h_u = Sd_ellipsoid(p, vec3(0.0), vec3(0.28, 0.28, 0.3));
    float g_h_l = Sd_ellipsoid(p, vec3(0.0,-0.5, 0.0), vec3(0.28, 0.28, 0.3));
    
    float model = min(g_h_u, g_h_l);
    return model;
}

float Map(vec3 p){
    //float model = Get_model(p);
    float model = Sd_sphere(p, 1.0);
    float plane = p.y + 1;

    float map = min(plane, model);
    
    return map;
}
vec3 Get_normal(vec3 p) {
    vec2 e = vec2(0.001, 0.0); // A tiny offset
    
    // Sample the scene slightly to the left/right on each axis
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    
    return normalize(vec3(dx, dy, dz));
}

float Get_light(vec3 p, vec3 cam_pos){
    vec3 light_pos = vec3(20.0, 30.0, -30.0);

    vec3 N = Get_normal(p);
    vec3 L = normalize(light_pos - p); 
    vec3 V = normalize(cam_pos - p);  

    vec3 ref_light_vector = reflect(-L, N);  
     
    float specular = clamp(dot(ref_light_vector, V), 0.0, 1.0);
    specular = 0.2 * pow(specular, 30); 

    float diff = max(dot(L, N), 0.0);
    return diff + specular; 
}

float Raymarch(vec3 rO, vec3 rD){
    float t = 0.0;

    for(int i = 0 ; i < 100 ; i++){
         vec3 p = rO + rD * t; 
         float d = Map(p);

         t += d;
         if (d < 0.001) {
             break;
         } else if(d > 100.0){
             break;
         }
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

#define AA 2 

void main() 
{
vec3 total_col = vec3(0.0);
    
    // Loop through a grid within the single pixel
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            
            // 1. Calculate the sub-pixel offset (-0.5 to +0.5)
            vec2 offset = vec2(float(m), float(n)) / float(AA) - 0.5;
            
            // 2. Apply the offset to the pixel coordinates before calculating UVs
            vec2 uv = (gl_FragCoord.xy + offset - 0.5 * u_resolution.xy) / u_resolution.y;
            
            // 3. Set up your camera and Ray Direction (r_d) using the new offset UV
            vec3 r_o = ray_origin; // Replace with your camera origin
            vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0); // Replace with your camera math
            
            // --- YOUR ORIGINAL CODE GOES HERE ---
            float d = Raymarch(r_o, r_d);
            
            vec3 intersect_p = r_o + r_d * d;
            float l = Get_light(intersect_p, r_o);
                
            vec3 col = l * vec3(1.0);
            // ------------------------------------
            
            // 4. Accumulate the color from this sub-pixel
            total_col += col;
        }
    }
    
    // 5. Average the accumulated color by the total number of samples
    total_col /= float(AA * AA);
    
    // Output final color (with optional gamma correction)
    fragColor = vec4(total_col, 1.0);
}

