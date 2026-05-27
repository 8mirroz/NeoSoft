extends Node2D
class_name GemView

# GemTypes:
# 0 = PINK_PEARL, 1 = BLUE_FLOW, 2 = ICE_SPARK, 3 = FROST_PEARL,
# 4 = MINT_SHIVER, 5 = GOLD_AURORA, 6 = AMETHYST_HAZE, 7 = ROSE_GLOW
@export var piece_id: int = 0
@export var is_selected: bool = false
@export var custom_scale: Vector2 = Vector2.ONE
@export var reduced_motion: bool = false

var size: float = 70.0
var time_elapsed: float = 0.0
var select_pulse_time: float = 0.0
var selection_alpha: float = 0.0 # Selection fade transition (150-220ms)
var sphere_type: int = CellState.SphereType.NONE
var sphere_node: Node2D = null
const USE_SCENE_SPHERES := true

# High-contrast premium vibrant color palette (Frost Gem Design System v1.0)
const PALETTES = {
	0: Color("FF389E"),  # Pink Pearl (Rare Accent)
	1: Color("007AFF"),  # Sapphire Blue (Primary Action)
	2: Color("00E6F2"),  # Frost Aqua (Secondary Focus/Glow)
	3: Color("AD2EFF"),  # Frost Pearl (Premium Magic)
	4: Color("00E07A"),  # Mint Shiver (Success)
	5: Color("FFB300"),  # Gold Aurora (Reward)
	6: Color("D900D9"),  # Amethyst Haze (Special Power)
	7: Color("FF471A"),  # Rose Glow (Coral / Urgent)
}

func _ready() -> void:
	# Randomize starting offset so idle animations are desynchronized across gems
	time_elapsed = randf_range(0.0, 10.0)
	_sync_sphere_visual()
	queue_redraw()

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Selection fade transition (150-220ms, fully aligned with motion system)
	if is_selected:
		select_pulse_time += delta * 6.0
		selection_alpha = min(selection_alpha + delta / 0.18, 1.0)
	else:
		selection_alpha = max(selection_alpha - delta / 0.15, 0.0)
		select_pulse_time = 0.0
	
	# Slowly pulse scale for idle breathing (Gem idle: 3–6s loop, sine, scale 1 ± .035)
	var breath := 1.0
	if not reduced_motion:
		# Period: 2*PI/1.8 = 3.49s (comfortable low-frequency breathing)
		breath = 1.0 + sin(time_elapsed * 1.8) * 0.035
	
	scale = Vector2(breath, breath) * custom_scale
	
	if is_instance_valid(sphere_node):
		var sphere_wobble := 1.0
		if not reduced_motion:
			sphere_wobble = 1.0 + sin(time_elapsed * 1.1 + float(piece_id) * 0.25) * 0.02
			sphere_node.rotation = sin(time_elapsed * 0.55 + float(piece_id)) * 0.04
		else:
			sphere_node.rotation = 0.0
		
		sphere_node.scale = _get_sphere_scene_scale() * sphere_wobble
	
	# Queue redraw whenever animation is active or selected state is changing
	if not reduced_motion or is_selected or selection_alpha > 0.0:
		queue_redraw()

func set_piece(p_id: int) -> void:
	piece_id = p_id
	queue_redraw()

func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()

func set_sphere_type(type: int) -> void:
	if sphere_type == type:
		return
	sphere_type = type
	if USE_SCENE_SPHERES:
		_sync_sphere_visual()
	else:
		_clear_sphere_visual()
	queue_redraw()

func clear_sphere_type() -> void:
	if sphere_type == CellState.SphereType.NONE and not is_instance_valid(sphere_node):
		return
	sphere_type = CellState.SphereType.NONE
	_clear_sphere_visual()
	queue_redraw()

func _sync_sphere_visual() -> void:
	if not USE_SCENE_SPHERES:
		_clear_sphere_visual()
		return
	if sphere_type == CellState.SphereType.NONE:
		_clear_sphere_visual()
		return

	_clear_sphere_visual()
	var sphere := SphereFactory.create(sphere_type)
	if sphere == null:
		sphere_type = CellState.SphereType.NONE
		return

	sphere_node = sphere
	sphere_node.name = "SphereVisual"
	sphere_node.position = Vector2.ZERO
	sphere_node.scale = _get_sphere_scene_scale()
	add_child(sphere_node)

func _clear_sphere_visual() -> void:
	if is_instance_valid(sphere_node):
		sphere_node.queue_free()
	sphere_node = null

func _get_sphere_scene_scale() -> Vector2:
	var logical_size: float = max(size, 1.0)
	var texture_size: float = 1024.0
	var base_scale: float = logical_size / texture_size
	return Vector2.ONE * base_scale

func _draw_prism_star(r: float, rotation_angle: float, col: Color) -> void:
	var points: PackedVector2Array = []
	var num_points := 5
	for i in range(num_points * 2):
		var angle := float(i) * (PI / float(num_points)) + rotation_angle
		var curr_r := r if i % 2 == 0 else r * 0.4
		points.append(Vector2(cos(angle), sin(angle)) * curr_r)
	points.append(points[0]) # close polygon
	draw_colored_polygon(points, col)

func _draw() -> void:
	var color: Color = PALETTES.get(piece_id, Color.WHITE)
	var radius := size * 0.4
	
	# 1. UNDERLAYS (Always drawn, even for 3D sphere scenes)
	
	# Premium dynamic drop-shadow (grows and softens when selected)
	var shadow_offset := 4.0 + selection_alpha * 3.5
	var shadow_radius := radius * (1.02 + selection_alpha * 0.08)
	var shadow_alpha := 0.12 - selection_alpha * 0.04
	draw_circle(Vector2(0.0, shadow_offset), shadow_radius, Color(0.04, 0.06, 0.12, shadow_alpha))
	
	# Frost Glow underlay (vibrant radial glow, increases on selection)
	var glow_alpha := 0.16 + selection_alpha * 0.24
	var glow_radius := radius * (1.1 + selection_alpha * 0.2)
	var glow_color := Color(color.r, color.g, color.b, glow_alpha)
	# Multilayer draw for smooth gradient-like soft edge glow
	draw_circle(Vector2.ZERO, glow_radius, glow_color)
	draw_circle(Vector2.ZERO, glow_radius * 0.7, Color(color.r, color.g, color.b, glow_alpha * 0.5))
	
	# 2. SPHERE 3D SCENE EXIT
	# If 3D sphere scene is used and valid, it handles drawing the main body.
	# We just draw the underlays and then overlay the selection focus rings.
	if USE_SCENE_SPHERES and sphere_type != CellState.SphereType.NONE and is_instance_valid(sphere_node):
		_draw_selection_overlay(radius)
		return
	
	# 3. 2D FALLBACK BODY DRAW (if 3D scene is not active)
	_draw_2d_fallback_body(radius, color)
	
	# 4. OVERLAYS (Focus rings)
	_draw_selection_overlay(radius)

func _draw_selection_overlay(radius: float) -> void:
	if selection_alpha <= 0.0:
		return
	
	# focus/ring: #00E6F2 (Frost Aqua)
	var focus_color := Color("00E6F2")
	
	# Outer animated breathing/pulsing aura ring
	var pulse_scale := 1.0
	if not reduced_motion:
		pulse_scale = 1.0 + sin(select_pulse_time) * 0.06
	
	var outer_radius := radius * (1.12 + pulse_scale * 0.06)
	var outer_color := focus_color
	outer_color.a = selection_alpha * 0.65
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 40, outer_color, 2.2)
	
	# Inner sharp premium high-contrast focus ring (3px target targets)
	var inner_color := focus_color
	inner_color.a = selection_alpha * 0.90
	draw_arc(Vector2.ZERO, radius * 1.08, 0.0, TAU, 40, inner_color, 1.6)

func _draw_2d_fallback_body(radius: float, color: Color) -> void:
	# Check if it's a special sphere (BLUE_RIBBON, PURPLE_RIBBON, CROSS_WAVE)
	if sphere_type == CellState.SphereType.BLUE_RIBBON or sphere_type == CellState.SphereType.PURPLE_RIBBON or sphere_type == CellState.SphereType.CROSS_WAVE:
		# Draw a glowing dark backing to make special spheres stand out
		draw_circle(Vector2.ZERO, radius * 1.15, Color(0, 0, 0, 0.35))
		
		# Draw main body
		draw_circle(Vector2.ZERO, radius, Color.WHITE)
		draw_circle(Vector2.ZERO, radius * 0.95, color)
		
		# Glass shine overlay
		draw_arc(Vector2.ZERO, radius * 0.94, -0.15 * PI, 1.72 * PI, 30, Color(1.0, 1.0, 1.0, 0.45), 2.0)
		draw_circle(Vector2(-radius * 0.34, -radius * 0.34), radius * 0.24, Color(1.0, 1.0, 1.0, 0.68))
		draw_circle(Vector2(-radius * 0.42, -radius * 0.42), radius * 0.10, Color(1.0, 1.0, 1.0, 0.85))

		match sphere_type:
			CellState.SphereType.BLUE_RIBBON: # Beam / Line laser Ribbon
				var line_color := Color.WHITE
				draw_line(Vector2(-radius * 0.85, 0), Vector2(radius * 0.85, 0), line_color, 3.8)
				draw_line(Vector2(0, -radius * 0.85), Vector2(0, radius * 0.85), line_color, 3.8)
				# Double rotating outer ring
				var ring_rot := time_elapsed * 2.8
				draw_arc(Vector2.ZERO, radius * 1.15, ring_rot, ring_rot + PI * 0.6, 24, color.lightened(0.2), 3.0)
				draw_arc(Vector2.ZERO, radius * 1.15, ring_rot + PI, ring_rot + PI * 1.6, 24, color.lightened(0.2), 3.0)
				
			CellState.SphereType.PURPLE_RIBBON: # Blast / Bomb area Sphere
				var ring_rot := -time_elapsed * 2.4
				for i in range(6):
					var angle := ring_rot + float(i) * (TAU / 6.0)
					draw_arc(Vector2.ZERO, radius * 1.22, angle, angle + (TAU / 12.0), 10, color.lightened(0.3), 3.8)
				# Radiant spikes
				for i in range(8):
					var angle := float(i) * (TAU / 8.0) + time_elapsed * 0.5
					var dir := Vector2(cos(angle), sin(angle))
					draw_line(dir * radius * 0.4, dir * radius * 0.88, Color.WHITE, 2.5)
				
			CellState.SphereType.CROSS_WAVE: # Color Bomb / Rainbow Prism Star
				var rot1 := time_elapsed * 1.6
				var rot2 := -time_elapsed * 1.3
				_draw_prism_star(radius * 0.88, rot1, Color(1.0, 0.2, 0.2, 0.8))
				_draw_prism_star(radius * 0.72, rot2, Color(0.2, 1.0, 0.2, 0.8))
				_draw_prism_star(radius * 0.56, rot1 + PI * 0.25, Color(0.2, 0.5, 1.0, 0.9))
				# Central pulsing diamond core
				var pulse := 0.22 + sin(time_elapsed * 4.0) * 0.05
				draw_rect(Rect2(-radius * pulse, -radius * pulse, radius * pulse * 2.0, radius * pulse * 2.0), Color.WHITE)
	else:
		# Uniform round gems: cleaner board readability, no square artifacts.
		draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, 0.92))
		draw_circle(Vector2.ZERO, radius * 0.9, color)
		
		# Glassmorphic inner gradient approximation
		draw_circle(Vector2(-radius * 0.15, -radius * 0.15), radius * 0.75, Color(color.r + 0.15, color.g + 0.15, color.b + 0.15, 0.5))
		
		# Outer shine arcs
		draw_arc(Vector2.ZERO, radius * 0.94, -0.15 * PI, 1.72 * PI, 30, Color(1.0, 1.0, 1.0, 0.45), 2.0)
		draw_arc(Vector2(radius * 0.04, radius * 0.08), radius * 0.7, 0.18 * PI, 1.35 * PI, 24, Color(1.0, 1.0, 1.0, 0.32), 1.4)
		
		# Top-left hot highlights
		draw_circle(Vector2(-radius * 0.34, -radius * 0.34), radius * 0.24, Color(1.0, 1.0, 1.0, 0.65))
		draw_circle(Vector2(-radius * 0.42, -radius * 0.42), radius * 0.10, Color(1.0, 1.0, 1.0, 0.82))

		var rotate_angle := time_elapsed * 0.35
		var accent_phase := rotate_angle + float(wrapi(piece_id, 0, 8)) * 0.6
		var accent_alpha := 0.42
		match wrapi(piece_id, 0, 8):
			0:
				draw_circle(Vector2(cos(accent_phase) * radius * 0.2, sin(accent_phase) * radius * 0.2), radius * 0.34, Color(1.0, 1.0, 1.0, accent_alpha))
			1:
				draw_arc(Vector2.ZERO, radius * 0.48, accent_phase, accent_phase + PI * 0.86, 18, Color(1.0, 1.0, 1.0, accent_alpha), 2.4)
			2:
				draw_line(Vector2(-radius * 0.54, sin(accent_phase) * radius * 0.08), Vector2(radius * 0.54, -sin(accent_phase) * radius * 0.08), Color(1.0, 1.0, 1.0, accent_alpha), 2.0)
			3:
				draw_arc(Vector2.ZERO, radius * 0.34, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, accent_alpha), 1.8)
			4:
				draw_arc(Vector2.ZERO, radius * 0.48, PI * 0.2 + accent_phase * 0.3, PI * 1.05 + accent_phase * 0.3, 18, Color(1.0, 1.0, 1.0, accent_alpha), 2.0)
			5, 6, 7:
				draw_circle(Vector2.ZERO, radius * (0.24 + sin(time_elapsed * 2.2) * 0.05), Color(1.0, 1.0, 1.0, accent_alpha))
