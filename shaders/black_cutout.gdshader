shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float brightness_threshold : hint_range(0.0, 0.3) = 0.05;
uniform float transition_softness : hint_range(0.0, 0.2) = 0.12;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	
	// Precise geometric circular cutout of black background (restores soft inner refractions)
	float dist = length(UV - vec2(0.5));
	float circular_mask = 1.0 - smoothstep(0.44, 0.48, dist);
	
	vec3 color = mix(base.rgb, tint_color.rgb, tint_color.a);
	COLOR = vec4(color, base.a * circular_mask);
}
