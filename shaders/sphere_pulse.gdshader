shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.74, 0.56, 0.96, 0.26);
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.8;
uniform float pulse_amplitude : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + dist * 10.0);
	float pulse_mask = smoothstep(0.6, 0.0, dist);

	vec4 base = texture(TEXTURE, UV);
	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a * pulse_mask);
	color += vec3(pulse_amplitude * pulse * pulse_mask);
	COLOR = vec4(color, base.a);
}
