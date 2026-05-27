shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.84, 0.94, 1.0, 0.22);
uniform float refraction_strength : hint_range(0.0, 0.12) = 0.035;
uniform float edge_glow : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	vec2 normal = centered_uv / max(dist, 0.001);
	float refraction_mask = 1.0 - smoothstep(0.06, 0.56, dist);
	vec2 offset = normal * refraction_strength * refraction_mask;

	vec4 base = texture(TEXTURE, UV + offset);
	
	// Precise geometric circular cutout of black background (restores soft inner refractions)
	float circular_mask = 1.0 - smoothstep(0.44, 0.48, dist);
	
	float rim = smoothstep(0.5, 0.2, dist);
	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a);
	color += vec3(edge_glow * 0.12) * rim;
	COLOR = vec4(color, base.a * circular_mask);
}
