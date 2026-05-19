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
#define PI 3.14159
void main() 
{
    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    float aspect_ratio = u_resolution.x / u_resolution.y;

    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio; // 1 unit of X == 1 Unit of y
    vec3 final_color = vec3(0);
    vec2 uv0 = uv;

    for(float i = 0.0 ; i < 2.0 ; i++)
    {
        uv0 = fract(uv0 * 2.0) -0.5;
        vec3 color  = Color_palette(length(uv) + u_time);
        float r1 = sin(20 * length(uv0) + u_time);

        float d = Donut(uv0, vec2(0), r1, 0.4,0.1);
        final_color += color * d;
    }
    fragColor = vec4(final_color, 1);
}

