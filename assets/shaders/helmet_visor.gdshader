shader_type canvas_item;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0; // Remap 0..1 → -1..1

	// Oval visor shape (wider than tall, ~16:9)
	float dist = length(vec2(uv.x * 0.62, uv.y));

	// Dark vignette: transparent at center, opaque at edges
	float vignette = smoothstep(0.48, 1.08, dist);

	// Cyan rim glow — thin bright ring at visor boundary
	float rim = smoothstep(0.80, 0.92, dist) * smoothstep(1.08, 0.92, dist);

	vec3 dark  = vec3(0.0,  0.012, 0.035);
	vec3 cyan  = vec3(0.0,  0.72,  0.88);

	vec3 col   = mix(dark, cyan, rim * 0.55);
	float a    = max(vignette * 0.90, rim * 0.45);

	COLOR = vec4(col, a);
}
