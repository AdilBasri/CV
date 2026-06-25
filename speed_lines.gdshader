shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float speed : hint_range(0.0, 20.0) = 5.0;
uniform float line_density : hint_range(0.0, 1.0) = 0.4;
uniform float line_falloff : hint_range(0.0, 2.0) = 0.75;
uniform vec4 line_color : source_color = vec4(1.0, 0.95, 0.6, 0.12); // Slightly warm yellow/white retro hue
uniform vec2 center = vec2(0.35, 0.45); // Focal point matching the road horizon

// Simple noise function
float noise(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 color = texture(screen_texture, uv).rgb;
	
	// Vector from focal center
	vec2 dir = uv - center;
	float dist = length(dir);
	
	// Radial angle for lines
	float angle = atan(dir.y, dir.x);
	
	// Create animated radial line noise pattern
	float line_noise = noise(vec2(floor(angle * 120.0 * line_density), TIME * 12.0 * speed));
	
	// Mask out center of screen so speed lines are only at the screen edges
	float edge_mask = smoothstep(0.18, line_falloff, dist);
	
	// Draw lines
	if (line_noise > 0.88) {
		float intensity = ((line_noise - 0.88) / 0.12) * edge_mask * line_color.a;
		// Blend screen color towards the speed lines color
		color = mix(color, line_color.rgb, intensity);
	}
	
	COLOR = vec4(color, 1.0);
}
