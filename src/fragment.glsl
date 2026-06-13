#version 330

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 ray_origin;
uniform vec3 look_at_dir;

out vec4 fragColor;

#define MAX_DIST 100.0
#define MIN_DIST 0.001
#define DRAG_MULT 0.38

// 1. Gerstner Wave Derivative Function
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x); // The derivative for horizontal shifting
    return vec2(wave, -dx);
}

// 2. Fractional Brownian Motion for Waves
float Get_waves(vec2 position) {
    float iter = 0.0;
    float frequency = 1.0;
    float timeMultiplier = 2.0;
    float weight = 1.0;
    float sumOfValues = 0.0;
    float sumOfWeights = 0.0;
    
    // Shift position to break up uniformity
    float wavePhaseShift = length(position) * 0.1; 
    
    for(int i = 0; i < 5; i++) { // 5 iterations for balance of detail and performance
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, frequency, u_time * timeMultiplier + wavePhaseShift);
        
        // Horizontal displacement (the core of the choppy water look!)
        position += p * res.y * weight * DRAG_MULT;
        
        sumOfValues += res.x * weight;
        sumOfWeights += weight;
        
        weight = mix(weight, 0.0, 0.2);
        frequency *= 1.18;
        timeMultiplier *= 1.07;
        iter += 1232.399963;
    }
    return sumOfValues / sumOfWeights;
}

// 3. Updated Map Function (Heightmap evaluation)
float Map(vec3 p) {
    float plane_height = -1.0; // Base water level
    float wave_height = Get_waves(p.xz);
    // Distance to the displaced plane
    return p.y - (plane_height + wave_height); 
}

// 4. Finite Difference Normals (Kept your exact logic!)
vec3 Get_normal(vec3 p) {
    vec2 e = vec2(0.01, 0.0); // Slightly larger epsilon for procedural waves
    float dx = Map(p + e.xyy) - Map(p - e.xyy);
    float dy = Map(p + e.yxy) - Map(p - e.yxy);
    float dz = Map(p + e.yyx) - Map(p - e.yyx);
    return normalize(vec3(dx, dy, dz));
}

// 5. Environmental Lighting (Sky & Sun)
vec3 getSunDirection() {
    return normalize(vec3(-0.1, 0.4, 0.6));
}

vec3 getAtmosphere(vec3 dir) {
    // A simplified atmospheric gradient based on the original
    float t = max(0.0, dir.y);
    vec3 skyColor = mix(vec3(0.5, 0.7, 0.9), vec3(0.1, 0.3, 0.6), t);
    vec3 sunColor = vec3(1.0, 0.9, 0.7) * pow(max(0.0, dot(dir, getSunDirection())), 120.0);
    return skyColor + sunColor;
}

// 6. Camera setup (Kept your logic)
vec3 Get_camera_rd(vec2 uv, vec3 ro, vec3 ta, float zoom) {
    vec3 f = normalize(ta - ro);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 r = normalize(cross(worldUp, f));
    vec3 u = cross(f, r);
    return normalize(uv.x * r + uv.y * u + f * zoom);
}

// 7. ACES Tonemapping for photorealism
vec3 aces_tonemap(vec3 color) {  
    mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
    );
    vec3 v = m1 * color;  
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));  
}

void main() {
    vec2 frag_coord = gl_FragCoord.xy;
    vec2 uv = (frag_coord.xy * 2.0 ) / u_resolution.xy;
    uv -= 1.0;
    uv *= u_resolution.x / u_resolution.y;

    vec3 r_o = ray_origin;     
    vec3 r_d = Get_camera_rd(uv, r_o, look_at_dir, 1.0);
    
    // Quick Sky Check: If we are looking up, render sky immediately
    if(r_d.y >= 0.0 && r_o.y > -1.0) {
        vec3 sky = getAtmosphere(r_d);
        fragColor = vec4(aces_tonemap(sky * 2.0), 1.0);
        return;
    }

    // Raymarching
    float t = 0.0;
    for(int i = 0 ; i < 128 ; i++) { // Increased iterations for the safety step
        vec3 pos = r_o + r_d * t; 
        float d = Map(pos);
        
        // SAFETY MULTIPLIER: Because horizontal displacement breaks the SDF bound, 
        // we only step 40% of the calculated distance to avoid clipping through peaks.
        t += d * 0.4; 
        
        if(d < MIN_DIST || t > MAX_DIST) break;
    }

    vec3 color = vec3(0.0);

    if(t < MAX_DIST) {
        vec3 p = r_o + r_d * t; 
        vec3 N = Get_normal(p);
        vec3 V = -r_d;
        
        // Fresnel Reflectance
        float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - max(0.0, dot(N, V)), 5.0);
        
        // Reflect the camera ray off the water normal
        vec3 R = normalize(reflect(r_d, N));
        
        // Water base color + Sky reflection
        vec3 scattering = vec3(0.029, 0.070, 0.171) * 0.5; // Deep water color
        vec3 reflection = getAtmosphere(R);
        
        color = mix(scattering, reflection, fresnel);
    } else {
        color = getAtmosphere(r_d);
    }

    // Apply Tonemapping
    fragColor = vec4(aces_tonemap(color * 2.0), 1.0);
}
