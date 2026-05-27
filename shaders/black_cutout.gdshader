shader_type canvas_item;

// Screen-blend black removal shader
// Removes the black studio background from sphere textures by treating
// pixel luminance as alpha (Screen blend mode logic).
// Dark black pixels become transparent; bright glass edges remain fully visible.

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float brightness_threshold : hint_range(0.0, 0.3) = 0.05;
uniform float transition_softness : hint_range(0.01, 0.4) = 0.20;
uniform float rim_boost : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 1. Circular boundary mask (soft edge)
	float dist = length(UV - vec2(0.5));
	float circular_mask = 1.0 - smoothstep(0.44, 0.50, dist);

	// 2. Luminance-based alpha (Screen blend: removes black studio background)
	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float luma_alpha = smoothstep(brightness_threshold, brightness_threshold + transition_softness, luma);

	// 3. Rim boost — brighten the chromatic edge ring
	float rim = smoothstep(0.30, 0.48, dist);
	vec3 rimmed = base.rgb + base.rgb * rim * rim_boost * 0.3;

	// 4. Optional tint overlay
	vec3 color = mix(rimmed, tint_color.rgb, tint_color.a);

	COLOR = vec4(color, luma_alpha * circular_mask);
}
