shader_type spatial;
render_mode cull_disabled; // Removed unshaded so light sources (flashlight, moonlight) can illuminate the walls

// Color parameters for a dark horror sky gradient
uniform vec3 sky_top : source_color = vec3(0.004, 0.006, 0.015);      // Eerie pitch black-indigo
uniform vec3 sky_mid : source_color = vec3(0.035, 0.031, 0.047);      // Dark foggy violet-gray
uniform vec3 sky_bot : source_color = vec3(0.094, 0.090, 0.106);      // Cold misty charcoal horizon

void fragment() {
	float y = UV.y;
	
	// Eerie dark multi-stop gradient transition
	vec3 color;
	if (y < 0.5) {
		color = mix(sky_top, sky_mid, smoothstep(0.0, 0.5, y));
	} else {
		color = mix(sky_mid, sky_bot, smoothstep(0.5, 1.0, y));
	}
	
	ALBEDO = color;
}
