shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 blood_color : source_color = vec4(0.45, 0.0, 0.0, 0.95);

// Simple pseudo-noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // Bottom of screen is UV.y = 1.0, top is UV.y = 0.0
    // Cutoff moves from 1.15 (completely off-screen at bottom) to -0.2 (fully covering)
    float cutoff = 1.15 - (progress * 1.35);
    
    // Large wave shape noise
    vec2 noise_uv1 = UV * 4.0;
    float n1 = fbm(noise_uv1);
    
    // Splatter/droplet noise
    vec2 noise_uv2 = UV * 16.0;
    float n2 = fbm(noise_uv2);
    
    // Wave distortion on the edge
    float edge = cutoff + (n1 - 0.5) * 0.35;
    
    // Main solid block rising
    float blood_mask = step(edge, UV.y);
    
    // Splatters/dots sprayed ahead of the rising front
    float spray_zone = step(edge - 0.25, UV.y) * (1.0 - blood_mask);
    float spots = step(0.68, n2) * spray_zone;
    
    // Combine solid mask and spray spots
    float final_alpha = max(blood_mask, spots * 0.9);
    
    // Darken towards the bottom for a deep, heavy blood pool aesthetic
    float depth = smoothstep(cutoff, 1.0, UV.y);
    vec3 col = mix(blood_color.rgb * 0.5, blood_color.rgb, depth);
    
    COLOR = vec4(col, final_alpha * blood_color.a);
}
