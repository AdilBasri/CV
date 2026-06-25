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
uniform int colorblind_mode = 0; // 0 = None, 1 = Protanopia, 2 = Deuteranopia, 3 = Tritanopia
uniform float shader_intensity : hint_range(0.0, 1.0) = 1.0;     // Real-time slider scaling intensity


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
		uv = uv + dist * r2 * (barrel_distortion * shader_intensity);
		
		// Crop pixels that warp outside the physical screen bounds (creates curved CRT borders)
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			// Fetch native color (drawn at 640x480 resolution)
			vec3 color = texture(screen_texture, uv).rgb;
			vec3 original_color = color;
			
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
			color += (dither_val - 0.5) * (dither_strength * shader_intensity);
			
			// Color Posterization (interpolated by intensity)
			vec3 post_color = floor(color * color_depth) / color_depth;
			color = mix(color, post_color, shader_intensity);
			
			// Color Grading & Contrast Stretch (Clinical cold horror tint, with milder stretch)
			vec3 graded_color = color * horror_tint;
			graded_color = (graded_color - 0.4) * 1.02 + 0.4; // Balanced contrast stretch
			graded_color = clamp(graded_color, 0.0, 1.0);
			color = mix(color, graded_color, shader_intensity);
			
			// CRT Phosphor Shadow Mask
			float shadow_factor = sin(FRAGCOORD.x * 2.0) * 0.05;
			float shadow_mask = shadow_factor * shader_intensity + (1.0 - 0.05 * shader_intensity);
			color *= shadow_mask;
			
			// Animated Analog TV Noise
			float noise = (random(uv + vec2(TIME * 0.05)) - 0.5) * (noise_strength * shader_intensity);
			color += vec3(noise);
			
			// CRT Horizontal Scanlines
			float scan_str = scanline_strength * shader_intensity;
			float scanline = sin(SCREEN_UV.y * 480.0 * 3.14159) * scan_str + (1.0 - scan_str);
			color *= scanline;
			
			// Dark Vignette
			vec2 d = abs(SCREEN_UV - 0.5) * 2.0;
			float vignette = 1.0 - dot(d, d) * (vignette_strength * shader_intensity);
			color *= clamp(vignette, 0.0, 1.0);
			
			// Colorblind Simulation/Correction
			if (colorblind_mode == 1) {
				// Protanopia
				color = vec3(
					color.r * 0.567 + color.g * 0.433,
					color.r * 0.558 + color.g * 0.442,
					color.b * 0.242 + color.g * 0.758
				);
			} else if (colorblind_mode == 2) {
				// Deuteranopia
				color = vec3(
					color.r * 0.625 + color.g * 0.375,
					color.r * 0.700 + color.g * 0.300,
					color.b * 0.300 + color.g * 0.700
				);
			} else if (colorblind_mode == 3) {
				// Tritanopia
				color = vec3(
					color.r * 0.950 + color.g * 0.050,
					color.r * 0.433 + color.g * 0.567,
					color.b * 0.475 + color.g * 0.525
				);
			}
			
			COLOR = vec4(color, 1.0);
		}
	}
}
