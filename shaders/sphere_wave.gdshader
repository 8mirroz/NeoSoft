shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.54, 0.91, 0.98, 0.24);
uniform float wave_strength : hint_range(0.0, 0.12) = 0.04;
uniform float wave_speed : hint_range(0.0, 8.0) = 2.2;
uniform float wave_density : hint_range(0.0, 40.0) = 18.0;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	vec2 normal = centered_uv / max(dist, 0.001);
	float wave = sin((UV.y * wave_density + TIME * wave_speed) * 6.28318) * 0.5;
	vec2 offset = normal * wave_strength * wave * (1.0 - smoothstep(0.0, 0.7, dist));

	vec4 base = texture(TEXTURE, UV + offset);
	float foam = smoothstep(0.45, 0.08, dist);
	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a);
	color += vec3(0.06, 0.12, 0.14) * foam;
	COLOR = vec4(color, base.a);
}
