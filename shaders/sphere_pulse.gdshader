shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.74, 0.56, 0.96, 0.26);
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.8;
uniform float pulse_amplitude : hint_range(0.0, 1.0) = 0.18;
uniform float brightness_threshold : hint_range(0.0, 0.3) = 0.06;
uniform float transition_softness : hint_range(0.01, 0.4) = 0.22;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + dist * 10.0);
	float pulse_mask = smoothstep(0.6, 0.0, dist);

	vec4 base = texture(TEXTURE, UV);

	// Circular boundary mask
	float circular_mask = 1.0 - smoothstep(0.44, 0.50, dist);

	// Luminance-based black removal (Screen blend)
	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float luma_alpha = smoothstep(brightness_threshold, brightness_threshold + transition_softness, luma);

	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a * pulse_mask);
	color += vec3(pulse_amplitude * pulse * pulse_mask);
	COLOR = vec4(color, luma_alpha * circular_mask);
}
