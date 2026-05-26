# combo_window_ring.gd
extends Control
class_name ComboWindowRing

var remaining_time: float = 0.0
var max_time: float = 1.5
var current_chain: int = 0
var active: bool = false
var glow_color: Color = Color(0.42, 0.84, 1.0, 1.0) # Cyan/blue

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(true)
	visible = false

func setup_combo(duration: float) -> void:
	max_time = duration
	remaining_time = duration
	active = true
	visible = true
	queue_redraw()

func update_combo(remaining: float, chain: int) -> void:
	remaining_time = remaining
	current_chain = chain
	active = remaining > 0.0
	if not active:
		visible = false
	# С ростом комбо меняем цвет свечения на золотой
	if chain >= 5:
		glow_color = Color(1.0, 0.82, 0.32, 1.0) # Gold
	elif chain >= 3:
		glow_color = Color(0.78, 0.58, 1.0, 1.0) # Purple
	else:
		glow_color = Color(0.42, 0.84, 1.0, 1.0) # Cyan
	queue_redraw()

func expire() -> void:
	active = false
	visible = false
	queue_redraw()

func _draw() -> void:
	if not active or remaining_time <= 0.0 or size == Vector2.ZERO:
		return

	var ratio := remaining_time / max_time
	var border_margin := 8.0
	var rect := Rect2(Vector2.ZERO, size).grow(border_margin)

	# Рисуем роскошное неоновое кольцо/рамку вокруг поля
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(glow_color.r, glow_color.g, glow_color.b, ratio * 0.8)
	style.corner_radius_top_left = 44
	style.corner_radius_top_right = 44
	style.corner_radius_bottom_right = 44
	style.corner_radius_bottom_left = 44
	style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, ratio * 0.45)
	style.shadow_size = 18

	draw_style_box(style, rect)
