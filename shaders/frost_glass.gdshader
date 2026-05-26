shader_type canvas_item;

// Шейдер матового морозного стекла (Frosted Glassmorphism Shader)
// С поддержкой динамического размытия заднего фона и морозных текстур.

uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.8, 0.9, 1.0, 0.3);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Размытие SCREEN_TEXTURE
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	
	// Наложение мягкого морозного цвета
	color.rgb = mix(color.rgb, tint_color.rgb, tint_color.a);
	
	COLOR = color;
}
