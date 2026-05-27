shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.84, 0.94, 1.0, 0.22);
uniform float refraction_strength : hint_range(0.0, 0.12) = 0.035;
uniform float edge_glow : hint_range(0.0, 1.0) = 0.42;
uniform float brightness_threshold : hint_range(0.0, 0.3) = 0.06;
uniform float transition_softness : hint_range(0.01, 0.4) = 0.22;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	vec2 normal = centered_uv / max(dist, 0.001);
	float refraction_mask = 1.0 - smoothstep(0.06, 0.56, dist);
	vec2 offset = normal * refraction_strength * refraction_mask;

	vec4 base = texture(TEXTURE, UV + offset);

	// Circular boundary mask
	float circular_mask = 1.0 - smoothstep(0.44, 0.50, dist);

	// Luminance-based black removal (Screen blend)
	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float luma_alpha = smoothstep(brightness_threshold, brightness_threshold + transition_softness, luma);

	// Rim edge glow
	float rim = smoothstep(0.5, 0.2, dist);
	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a);
	color += vec3(edge_glow * 0.14) * rim;

	COLOR = vec4(color, luma_alpha * circular_mask);
}
