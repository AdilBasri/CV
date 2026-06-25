shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform sampler2D mask_texture : hint_default_transparent;          // Silhouette mask of the Volvo (alpha > 0)
uniform float color_depth : hint_range(2.0, 128.0) = 12.0;       // Authentic retro color banding
uniform float dither_strength : hint_range(0.0, 0.1) = 0.045;   // Visible ordered dither matrix
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.15;  // Visible CRT scanline weight
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;  // Deep vignette for horror feel
uniform float noise_strength : hint_range(0.0, 0.1) = 0.022;    // Animated TV static noise
uniform vec3 horror_tint = vec3(0.85, 0.92, 0.98);              // Colder, clinical blue-green horror tint
uniform float barrel_distortion : hint_range(0.0, 0.3) = 0.14;   // CRT screen curvature strength (increased slightly)

// Simple pseudorandom number generator for animated static noise
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 original_uv = SCREEN_UV;
	vec4 mask_color = texture(mask_texture, original_uv);
	
	if (mask_color.a > 0.05) {
		// Output the clean, high-resolution original image for the Volvo, completely bypassing shader
		COLOR = texture(screen_texture, original_uv);
	} else {
		// 1. Apply CRT Barrel Distortion (Curving UV coordinates outwards)
		vec2 uv = SCREEN_UV;
		vec2 dist = uv - 0.5;
		float r2 = dot(dist, dist);
		uv = uv + dist * r2 * barrel_distortion;
		
		// Crop pixels that warp outside the physical screen bounds (creates curved CRT borders)
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			// Fetch native color (drawn at 640x480 resolution)
			vec3 color = texture(screen_texture, uv).rgb;
			
			// Ordered Dithering (4x4 Bayer matrix)
			const float bayer_matrix[16] = float[](
				0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
			   12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
				3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
			   15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
			);
			
			ivec2 pixel_coords = ivec2(FRAGCOORD.xy);
			int x = pixel_coords.x % 4;
			int y = pixel_coords.y % 4;
			float dither_val = bayer_matrix[y * 4 + x];
			color += (dither_val - 0.5) * dither_strength;
			
			// Color Posterization
			color = floor(color * color_depth) / color_depth;
			
			// Color Grading & Contrast Stretch (Clinical cold horror tint, with milder stretch)
			color *= horror_tint;
			color = (color - 0.4) * 1.02 + 0.4; // Balanced contrast stretch
			color = clamp(color, 0.0, 1.0);
			
			// CRT Phosphor Shadow Mask
			float shadow_mask = sin(FRAGCOORD.x * 2.0) * 0.05 + 0.95;
			color *= shadow_mask;
			
			// Animated Analog TV Noise
			float noise = (random(uv + vec2(TIME * 0.05)) - 0.5) * noise_strength;
			color += vec3(noise);
			
			// CRT Horizontal Scanlines
			float scanline = sin(SCREEN_UV.y * 480.0 * 3.14159) * scanline_strength + (1.0 - scanline_strength);
			color *= scanline;
			
			// Dark Vignette
			vec2 d = abs(SCREEN_UV - 0.5) * 2.0;
			float vignette = 1.0 - dot(d, d) * vignette_strength;
			color *= clamp(vignette, 0.0, 1.0);
			
			COLOR = vec4(color, 1.0);
		}
	}
}
