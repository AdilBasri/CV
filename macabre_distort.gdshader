shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float brightness : hint_range(0.0, 2.0) = 0.22; // Low brightness to reduce highlight
uniform float red_tint : hint_range(0.0, 1.0) = 0.25; // Macabre blood-like tint
uniform float wave_strength : hint_range(0.0, 0.1) = 0.006;
uniform float speed : hint_range(0.0, 10.0) = 1.6;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.08;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Distort UVs using sine/cosine waves for a creepy organic/macabre moving texture look
    vec2 uv = UV;
    uv.x += sin(uv.y * 14.0 + TIME * speed) * wave_strength;
    uv.y += cos(uv.x * 12.0 + TIME * speed * 0.95) * wave_strength * 1.4;
    
    // Sample texture
    vec4 tex_color = texture(albedo_texture, uv);
    
    // Dim the color (kısılması)
    vec3 color = tex_color.rgb * brightness;
    
    // Crimson blood tint
    vec3 crimson = vec3(0.5, 0.04, 0.04);
    color = mix(color, color * crimson * 2.8, red_tint);
    
    // Scanlines
    float scanline = sin(uv.y * 220.0) * 0.15 + 0.85;
    color *= scanline;
    
    // Random static noise
    float noise = (random(uv + vec2(TIME * 0.02)) - 0.5) * noise_strength;
    color += vec3(noise);
    
    // Dark vignette edges
    vec2 d = abs(UV - 0.5) * 2.0;
    float vignette = 1.0 - dot(d, d) * 0.45;
    color *= clamp(vignette, 0.0, 1.0);
    
    ALBEDO = color;
    ALPHA = tex_color.a;
}
