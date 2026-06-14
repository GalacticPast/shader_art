#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

const float PI = 3.14159265;

const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float MIN_DIST = 0.001;
const float EARTH_RAD = 6360e3;
const float ATMOS_RAD  = 6420e3;
const float SUN_INTENSITY = 9.0;

const float G = 0.76;

const float RAYLEIGHSCALEHEIGHT = 7994.0;
const vec3 BETAR = vec3(3.8e-6, 13.5e-6, 33.1e-6);

const float MIESCALEHEIGHT = 1200.0;
const vec3 BETAM = vec3(210e-5, 210e-5, 210e-5);

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
        uv *= 3.0; 
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
    float wave = Get_waves(p.xz);
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

    for(int i = 0 ; i < MAX_STEPS ; i++)
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
    for(int i = 0 ; i < 12 ; i++)
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

float Ray_sph_intersection(vec3 r_o, vec3 r_d, vec3 sph_pos, float sph_r) 
{
    float a = dot(r_d, r_d);
    vec3 d = r_o - sph_pos;
    float b = 2.0 * dot(r_d, d);
    float c = dot(d, d) - (sph_r * sph_r);
    if (b*b - 4.0*a*c < 0.0) 
    {
        return -1.0;
    }
    return (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

vec3 scatteringAtHeight(vec3 scatteringAtSea, float height, float heightScale) {
    return scatteringAtSea * exp(-height/heightScale);
}

float height(vec3 p) {
    return (length(p) - EARTH_RAD);
}

vec3 transmittance(vec3 pa, vec3 pb, int samples, float scaleHeight, vec3 scatCoeffs) {
    float opticalDepth = 0.0;
    float segmentLength = length(pb - pa)/float(samples);
    for (int i = 0; i < samples; i++) {
        vec3 samplePoint = mix(pa, pb, (float(i)+0.5)/float(samples));
        float sampleHeight = height(samplePoint);
        opticalDepth += exp(-sampleHeight / scaleHeight) * segmentLength;
    }
    vec3 transmittance = exp(-1.0 * scatCoeffs * opticalDepth);
    return transmittance;
}

float Rayleigh_phase(float mu) {
    float phase = (3.0 / (16.0 * PI)) * (1.0 + mu * mu);
    return phase;
}

float Mie_phase(float mu) {
    float numerator = (1.0 - G * G) * (1.0 + mu * mu);
    float denominator = (2.0 + G * G) * pow(1.0 + G * G - 2.0 * G * mu, 3.0/2.0);
    return (3.0 / (8.0 * PI)) * numerator / denominator;
}

vec3 Get_atmosphere(vec3 r_o, vec3 atm_intersect_p, vec3 sun_dir)
{
    float mu = dot(normalize(atm_intersect_p - r_o), sun_dir);
    
    float phase_r = Rayleigh_phase(mu);
    float phase_m = Mie_phase(mu);
    
    vec3 sum_raye = vec3(0.0);
    vec3 sum_mie = vec3(0.0);
    
    int samples = 10;
    float seg_length = length(atm_intersect_p - r_o) / float(samples);

    for (int i = 0; i < samples; i++) 
    {
        vec3 sample_point = mix(r_o, atm_intersect_p, (float(i)+0.5)/float(samples));
        float sample_height = height(sample_point);
        float dist_to_atm = Ray_sph_intersection(sample_point, sun_dir, vec3(0.0), ATMOS_RAD);
        vec3 atm_instersect = sample_point + sun_dir * dist_to_atm;
        
        vec3 trans1R = transmittance(r_o, sample_point, 10, RAYLEIGHSCALEHEIGHT, BETAR);
        vec3 trans2R = transmittance(sample_point, atm_instersect, 10, RAYLEIGHSCALEHEIGHT, BETAR);
        sum_raye += trans1R * trans2R * scatteringAtHeight(BETAR, sample_height, RAYLEIGHSCALEHEIGHT) * seg_length;
        
        vec3 trans1M = transmittance(r_o, sample_point, 10, MIESCALEHEIGHT, BETAM);
        vec3 trans2M = transmittance(sample_point, atm_instersect, 10, MIESCALEHEIGHT, BETAM);
        sum_mie += trans1M * trans2M * scatteringAtHeight(BETAM, sample_height, MIESCALEHEIGHT) * seg_length;
        
    } 
    sum_raye = SUN_INTENSITY * phase_r * sum_raye;
    sum_mie = SUN_INTENSITY * phase_m * sum_mie;

    return sum_raye + sum_mie;
}

vec3 Get_sky_color(vec3 r_o, vec3 r_d, vec3 sun_dir)
{
    vec3 sky_ro = r_o + vec3(0.0, EARTH_RAD, 0.0);
    float dist_atm = Ray_sph_intersection(sky_ro, r_d, vec3(0.0), ATMOS_RAD); 
    vec3 atm_intersect_p = sky_ro + r_d * dist_atm;  
    
    vec3 atm = Get_atmosphere(sky_ro, atm_intersect_p, sun_dir);

    return atm;
}
// ACES Tonemapping curve
vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
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
    
    vec3 light_pos = vec3(10 + sin(0.2 * u_time),10 + cos(0.2 * u_time), 1.0);
    vec3 sun_dir = normalize(light_pos);
    
    if(d < 100.0)
    {
        float light = Get_light(p, r_o, light_pos);
        float shadow = Get_shadow(p, light_pos); 
        color = shadow * light * vec3(0.0, 0.2, 0.3);
    }
    else
    {
        color = Get_sky_color(r_o, r_d, sun_dir);
    }

    color = ACESFilm(color);
    color = pow( color, vec3(1.0/2.2));
    fragColor = vec4(color, 1.0);
}
