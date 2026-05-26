extends Node2D
class_name GemView

# GemTypes:
# 0 = PINK_PEARL, 1 = BLUE_FLOW, 2 = ICE_SPARK, 3 = FROST_PEARL,
# 4 = MINT_SHIVER, 5 = GOLD_AURORA, 6 = AMETHYST_HAZE, 7 = ROSE_GLOW
@export var piece_id: int = 0
@export var is_selected: bool = false

var size: float = 70.0
var time_elapsed: float = 0.0
var select_pulse_time: float = 0.0

# Opal pearlescent palette v3 (soft translucent tones with iridescent luminosity)
const PALETTES = {
	0: Color(0.96, 0.72, 0.82), # Opal Rose (Pink Pearl)
	1: Color(0.55, 0.78, 0.96), # Sapphire Opal (Blue Flow)
	2: Color(0.48, 0.90, 0.94), # Aqua Pearl (Ice Spark)
	3: Color(0.82, 0.72, 0.96), # Lavender Opal (Frost Pearl)
	4: Color(0.48, 0.88, 0.76), # Seafoam Pearl (Mint Shiver)
	5: Color(0.98, 0.85, 0.52), # Amber Opal (Gold Aurora)
	6: Color(0.72, 0.55, 0.94), # Violet Pearl (Amethyst Haze)
	7: Color(0.96, 0.55, 0.65), # Coral Opal (Rose Glow)
}

func _ready() -> void:
	# Randomize starting offset so idle animations are desynchronized across gems
	time_elapsed = randf_range(0.0, 10.0)
	queue_redraw()

func _process(delta: float) -> void:
	time_elapsed += delta
	if is_selected:
		select_pulse_time += delta * 6.0
	
	# Slowly pulse scale for idle breathing (RULE-003: idle cycle 3.0s to 6.0s)
	# Frequency: 0.3Hz (approx 3.3s cycle)
	var breath := 1.0 + sin(time_elapsed * 1.8) * 0.035
	scale = Vector2(breath, breath)
	
	queue_redraw()

func set_piece(p_id: int) -> void:
	piece_id = p_id
	queue_redraw()

func set_selected(selected: bool) -> void:
	is_selected = selected
	if not is_selected:
		select_pulse_time = 0.0
	queue_redraw()

func _draw() -> void:
	var color: Color = PALETTES.get(piece_id, Color.WHITE)
	var radius := size * 0.4
	
	# Premium soft drop-shadow
	draw_circle(Vector2(0, 4.0), radius + 2.0, Color(0, 0, 0, 0.12))
	
	# Glassmorphic glow / underlay glow (p1.md: "neon under ice")
	var glow_color := Color(color.r, color.g, color.b, 0.22)
	draw_circle(Vector2.ZERO, radius + 6.0, glow_color)
	
	# Active selection pulse ring
	if is_selected:
		var pulse_scale := 1.0 + sin(select_pulse_time) * 0.06
		var sel_color := Color(color.r + 0.1, color.g + 0.1, color.b + 0.1, 0.95)
		draw_arc(Vector2.ZERO, radius + 6.5 * pulse_scale, 0.0, TAU, 36, sel_color, 2.5)

	# Slow dynamic internal waves/refraction rotation angle
	var rotate_angle := time_elapsed * 0.35

	# Draw specific geometric shapes based on piece_id with frosted glass details
	match piece_id:
		0: # Pink Pearl: Circle with moving liquid wave
			draw_circle(Vector2.ZERO, radius, color)
			# Outer crystal rim
			draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.15))
			# Yin-yang style internal wave
			var wave_center := Vector2(cos(rotate_angle) * radius * 0.2, sin(rotate_angle) * radius * 0.2)
			draw_circle(wave_center, radius * 0.45, Color(1, 1, 1, 0.32))
			# Glare highlight
			draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.25, Color(1, 1, 1, 0.65))
			
		1: # Blue Flow: Diamond with vertical flow ribbon
			var points := PackedVector2Array([
				Vector2(0, -radius),
				Vector2(radius, 0),
				Vector2(0, radius),
				Vector2(-radius, 0)
			])
			draw_colored_polygon(points, color)
			draw_polyline(points, Color(1, 1, 1, 0.35), 1.5)
			
			# Rotating flow line
			var wave_p := Vector2(cos(rotate_angle) * radius * 0.3, 0)
			draw_line(Vector2(wave_p.x, -radius * 0.65), Vector2(-wave_p.x, radius * 0.65), Color(1, 1, 1, 0.45), 2.5)
			# Highlight
			var hl := PackedVector2Array([
				Vector2(0, -radius * 0.75),
				Vector2(radius * 0.35, -radius * 0.35),
				Vector2(-radius * 0.35, -radius * 0.35)
			])
			draw_colored_polygon(hl, Color(1, 1, 1, 0.35))
			
		2: # Ice Spark: Hexagonal star facets
			var points := PackedVector2Array()
			for i in range(6):
				var angle := i * PI / 3.0
				points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
			draw_colored_polygon(points, color)
			draw_polyline(points, Color(1, 1, 1, 0.4), 1.5)
			
			# Internal crystalline facets
			for i in range(3):
				var angle := rotate_angle + i * PI / 1.5
				draw_line(Vector2.ZERO, Vector2(cos(angle) * radius * 0.8, sin(angle) * radius * 0.8), Color(1, 1, 1, 0.28), 1.0)
			draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.22, Color(1, 1, 1, 0.55))
			
		3: # Frost Pearl: Multi-layered white sphere with gas bubbles
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius - 2.0, Color(color.r - 0.05, color.g - 0.05, color.b - 0.02, 1.0))
			
			# Micro bubbles floating slowly
			for i in range(3):
				var bubble_offset := Vector2(
					sin(time_elapsed + i * 2.0) * radius * 0.3,
					cos(time_elapsed * 0.8 + i * 3.0) * radius * 0.3
				)
				draw_circle(bubble_offset, 2.5, Color(1, 1, 1, 0.65))
			# Crescent rim reflection
			draw_arc(Vector2.ZERO, radius - 3.0, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.55), 1.5)
			
		4: # Mint Shiver: Soft triangle with wind wave
			var points := PackedVector2Array([
				Vector2(0, -radius),
				Vector2(radius * 0.9, radius * 0.75),
				Vector2(-radius * 0.9, radius * 0.75)
			])
			draw_colored_polygon(points, color)
			draw_polyline(points, Color(1, 1, 1, 0.35), 1.5)
			
			# Rotating wind arc inside
			var arc_center := Vector2(0, radius * 0.1)
			draw_arc(arc_center, radius * 0.4, rotate_angle, rotate_angle + PI * 0.8, 16, Color(1, 1, 1, 0.48), 2.0)
			draw_circle(Vector2(0, -radius * 0.3), radius * 0.18, Color(1, 1, 1, 0.5))
			
		5: # Gold Aurora: Rounded block with warm energy core
			var points := PackedVector2Array([
				Vector2(-radius * 0.75, -radius * 0.75),
				Vector2(radius * 0.75, -radius * 0.75),
				Vector2(radius * 0.75, radius * 0.75),
				Vector2(-radius * 0.75, radius * 0.75)
			])
			draw_colored_polygon(points, color)
			draw_polyline(points, Color(1, 1, 1, 0.38), 1.5)
			
			# Pulse inner core
			var pulse_val := 0.4 + sin(time_elapsed * 2.5) * 0.12
			draw_circle(Vector2.ZERO, radius * pulse_val, Color(1, 1, 1, 0.42))
			draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.18, Color(1, 1, 1, 0.55))
			
		6: # Amethyst Haze: Lavender octagon with crystal rings
			var points := PackedVector2Array()
			for i in range(8):
				var angle := i * PI / 4.0
				points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
			draw_colored_polygon(points, color)
			draw_polyline(points, Color(1, 1, 1, 0.32), 1.5)
			
			# Concentric orbital rings
			var ring_rad := radius * 0.45 + sin(time_elapsed * 1.5) * radius * 0.08
			draw_arc(Vector2.ZERO, ring_rad, 0, TAU, 24, Color(1, 1, 1, 0.38), 1.2)
			draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.2, Color(1, 1, 1, 0.5))
			
		7: # Rose Glow: Rose shape / heart with rotating core
			var points := PackedVector2Array()
			for i in range(12):
				var r := radius if i % 3 == 0 else radius * 0.62
				var angle := i * PI / 6.0
				points.append(Vector2(cos(angle) * r, sin(angle) * r))
			draw_colored_polygon(points, color)
			
			# Spiral galaxy rotation inside
			var rot_p1 := Vector2(cos(rotate_angle) * radius * 0.3, sin(rotate_angle) * radius * 0.3)
			var rot_p2 := Vector2(cos(rotate_angle + PI) * radius * 0.3, sin(rotate_angle + PI) * radius * 0.3)
			draw_line(rot_p1, rot_p2, Color(1, 1, 1, 0.45), 2.0)
			draw_circle(Vector2.ZERO, radius * 0.2, Color(1, 1, 1, 0.38))
			draw_circle(Vector2(-radius * 0.2, -radius * 0.2), radius * 0.22, Color(1, 1, 1, 0.5))
			
		_:
			draw_circle(Vector2.ZERO, radius, color)
