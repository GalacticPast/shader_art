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

void main() 
{

    vec2 frag_coord = vec2(gl_FragCoord.x, gl_FragCoord.y);
    float aspect_ratio = u_resolution.x / u_resolution.y;

    vec2 uv = frag_coord / u_resolution;  
    uv -= 0.5; 
    uv.x *= aspect_ratio; // 1 unit of X == 1 Unit of y
    
    
    float x = uv.x;
    float amplitude = 10;
    float m = 0.2 * sin(u_time + (x * amplitude));
    float y = uv.y - m;

    float donut_radius = 0.2;
    float donut = Donut(uv, vec2(0), donut_radius,0.005, 0.002);
    
    float delta = 1;
    float t = 0.25;
    float c_pos_x = cos(3.14159 * t * delta) * donut_radius;
    float c_pos_y = sin(3.14159 * t * delta) * donut_radius;
    float point = Circle(vec2(c_pos_x,c_pos_y),uv,0.01,0.002);

    float left_x = c_pos_x;
    float right_x = c_pos_x;
    if(c_pos_x > 0) left_x = 0;
    else right_x = 0;

    float left_y = c_pos_y;
    float right_y = c_pos_y;
    if(c_pos_y > 0) left_y = 0;
    else right_y = 0;

    float cos_point =  Rect(uv, vec2(0),left_x,right_x, 0.004, -0.004, 0.005);
    float sin_point =  Rect(vec2(uv.y, uv.x),vec2(0, c_pos_x),left_y,right_y, 0.004, -0.004, 0.005); // reflecting so that it will become flipped
    
    left_x = donut_radius;
    right_x = donut_radius;
    if(c_pos_x > 0) left_x = 0;
    else right_x = 0;

    float hyp_point =  0; 
     

    vec3 color = vec3(0,0,0);
    color += hyp_point * vec3(1,1,1);
    color += sin_point * vec3(0,1,0); 
    color += cos_point * vec3(1,0,1); 
    color += donut * vec3(1,1,0.8); 
    color += point * vec3(1,1,1); 

    fragColor = vec4(color, 1);
}

