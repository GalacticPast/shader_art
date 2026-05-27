#version 330


uniform vec2 u_resolution;    // viewport size in pixels (width, height)
uniform float u_time;         // seconds since playback started

uniform sampler2D u_main;

out vec4 fragColor;

float Circle(vec2 uv, vec2 pos, float radius,float blur)
{
    uv -= pos;
    float dist = length(uv); // magnitude of how far it is from the origin 
    float c_step = smoothstep(radius, radius - blur, dist); 
         
    return c_step;
}

float Donut(vec2 uv, vec2 pos, float radius,  float width, float blur){
    float inner_circle = Circle(uv, pos, radius, blur);        
    float outer_circle = Circle(uv, pos, radius + width, blur);        

    return outer_circle - inner_circle;
}

float Smiley(vec2 uv, vec2 pos, vec2 size)
{
    uv -= pos; 
    uv *= size;

    float face = Circle(uv, vec2(0,0), 0.2, 0.01);
    float l_eye = Circle(uv,vec2(-0.1, 0.05), 0.05,0.01);
    float r_eye = Circle(uv,vec2(0.1,0.05), 0.05,0.01);
    float mouth_u = Circle(uv, vec2(0,-0.075), 0.08,0.01);
    float mouth_l = Circle(uv, vec2(0,-0.065), 0.08,0.01);
     
    float mask = face - l_eye - r_eye - (mouth_u - mouth_l);
    return mask;
}

float Band(float t, float start, float end, float blur)
{
    float band_a = smoothstep(start - blur, start + blur, t);
    float band_b = smoothstep(end - blur,end + blur, t);
    return band_a - band_b;
}

float Rect(vec2 uv, vec2 pos, float left, float right, float top, float bottom, float blur)
{
    uv -= pos;
    float band_1 = Band(uv.x, left, right, blur);
    float band_2 = Band(uv.y, bottom, top, blur);
return band_1 * band_2;
}
#define PI 3.14159


float Line_segment(vec2 uv, vec2 A, vec2 B){

    float h = clamp(dot(uv, B) / dot(B, B), 0.0, 1.0);
    float dist = length(uv - B * h);
    
    return smoothstep(0.01, 0, dist);
}

// I still need to understand this. 
vec3 Color_palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);

    return a + b*cos( 6.28318*(c*t+d) );
}
// vec3 Color_palette(float x)
// {
//     vec3 A = vec3(1);
//     vec3 B = vec3(1);
//     vec3 C = vec3(0.1);
//     vec3 D = vec3(1,0.2,0);
//     vec3 color = A + B * cos(2 * PI * ((C * x) + D));
//     return color;
// }

float Sawtooth(float x){
    float y = 2.0 * fract(x * 0.2) - 1.0;
    return y;
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

float Map(vec3 p){
    vec3 sphere_pos = vec3(0,0,1);
    float sphere = Sd_sphere(p - sphere_pos, 1);
    float plane = p.y + 1;

    float angle = PI / 2; 

    vec3 line_pos_a = vec3(0.0, 0.0,0.0);
    vec3 line_pos_b = vec3(1.0, 1.0,0.0);
    vec3 line_dir = line_pos_b - line_pos_a;
    line_pos_b *= 0.2; // scale
    line_pos_a.xy += 1; // translation
    line_pos_b.xy += 1; // translation 

    float line = Sd_capsule(p, line_pos_a,line_pos_b,0.01);

    float map = min(sphere, plane);
    map = min(map, line);
    
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

vec3 Raymarch(vec3 rO, vec3 rD){
    float t = 0.0;
    vec3 col = vec3(0);
    bool hit = false;
    for(int i = 0 ; i < 100 ; i++){
         vec3 p = rO + rD * t; 
         float d = Map(p);

         t += d;
         if (d < 0.001) {
              vec3 N = Get_normal(p);
             
              // 2. Define a light position (e.g., floating above and to the left)
              vec3 lightPos = vec3(2.0, 5.0, 1.0);
             
              // 3. Calculate the light direction vector (Target - Source) and normalize it
              vec3 L = normalize(lightPos - p);
             
              // 4. Calculate diffuse intensity using the dot product
              float diffuse = max(dot(N, L), 0.0);
             
              // 5. Combine with a base color and a tiny bit of ambient light so shadows aren't pitch black
              vec3 objectColor = vec3(0.0, 0.0, 1.0); // A nice blue sphere
              vec3 ambient = vec3(0.1);               // Soft background light
             
             col = objectColor * (diffuse + ambient);

             break;
         } else if(d > 100.0){
             break;
         }
    }
    //col = vec3(t * 0.1);
    return col;
}

#define PI 3.14159
void main() 
{
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    float aspect_ratio = u_resolution.x / u_resolution.y;

    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio; // 1 unit of X == 1 Unit of y
    
    vec3 rO = vec3(0,0,-3);
    vec3 rD = normalize(vec3(uv, 1.0)); 

    vec3 col = Raymarch(rO, rD);
     

    fragColor = vec4(col, 1);
}

