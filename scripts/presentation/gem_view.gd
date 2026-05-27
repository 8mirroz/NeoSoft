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

# Simple procedural mode — no 3D scene spheres
const USE_SCENE_SPHERES := false

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
	
	# Slowly pulse scale for idle breathing (Gem idle: 3–6s loop, sine, scale 1 ± .025)
	var breath := 1.0
	if not reduced_motion:
		breath = 1.0 + sin(time_elapsed * 1.8) * 0.025
	
	scale = Vector2(breath, breath) * custom_scale
	
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

# ─── DRAW ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var color: Color = PALETTES.get(piece_id, Color.WHITE)
	var radius := size * 0.4
	
	# If using 3D scenes and one is loaded, only draw selection overlay
	if USE_SCENE_SPHERES and sphere_type != CellState.SphereType.NONE and is_instance_valid(sphere_node):
		_draw_selection_overlay(radius)
		return
	
	# ── Simple procedural sphere ──
	_draw_procedural_sphere(radius, color)
	
	# ── Selection focus ring ──
	_draw_selection_overlay(radius)

func _draw_procedural_sphere(radius: float, color: Color) -> void:
	# 1. Soft shadow
	var shadow_y := 2.0 + selection_alpha * 2.0
	draw_circle(Vector2(0.0, shadow_y), radius * 1.02, Color(0.0, 0.0, 0.0, 0.08))
	
	# 2. White border ring (subtle)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, 0.85))
	
	# 3. Main color body
	var body_radius := radius * 0.92
	draw_circle(Vector2.ZERO, body_radius, color)
	
	# 4. Lighter inner hemisphere (top-left gradient feel)
	var lighter := Color(
		min(color.r + 0.2, 1.0),
		min(color.g + 0.2, 1.0),
		min(color.b + 0.2, 1.0),
		0.55
	)
	draw_circle(Vector2(-body_radius * 0.18, -body_radius * 0.18), body_radius * 0.7, lighter)
	
	# 5. Specular highlight (top-left)
	draw_circle(Vector2(-body_radius * 0.3, -body_radius * 0.3), body_radius * 0.22, Color(1.0, 1.0, 1.0, 0.6))
	draw_circle(Vector2(-body_radius * 0.36, -body_radius * 0.36), body_radius * 0.09, Color(1.0, 1.0, 1.0, 0.8))

func _draw_selection_overlay(radius: float) -> void:
	if selection_alpha <= 0.0:
		return
	
	# focus/ring: #00E6F2 (Frost Aqua)
	var focus_color := Color("00E6F2")
	
	# Outer animated pulsing ring
	var pulse_scale := 1.0
	if not reduced_motion:
		pulse_scale = 1.0 + sin(select_pulse_time) * 0.06
	
	var outer_radius := radius * (1.12 + pulse_scale * 0.06)
	var outer_color := focus_color
	outer_color.a = selection_alpha * 0.65
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 40, outer_color, 2.2)
	
	# Inner sharp focus ring
	var inner_color := focus_color
	inner_color.a = selection_alpha * 0.90
	draw_arc(Vector2.ZERO, radius * 1.08, 0.0, TAU, 40, inner_color, 1.6)
