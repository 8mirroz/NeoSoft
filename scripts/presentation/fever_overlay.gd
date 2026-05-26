# fever_overlay.gd
extends Control
class_name FeverOverlay

var active: bool = false
var fever_time_left: float = 0.0
var max_fever_time: float = 6.0
var pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(true)
	visible = false

func activate(duration: float) -> void:
	max_fever_time = duration
	fever_time_left = duration
	active = true
	visible = true
	pulse_time = 0.0
	queue_redraw()

func deactivate() -> void:
	active = false
	visible = false
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	pulse_time += delta
	fever_time_left -= delta
	if fever_time_left <= 0.0:
		deactivate()
	else:
		queue_redraw()

func _draw() -> void:
	if not active or size == Vector2.ZERO:
		return

	# Рисуем золотую виньетку по краям экрана
	var ratio := fever_time_left / max_fever_time
	var base_alpha := 0.26 + sin(pulse_time * 6.0) * 0.08
	# Золотое свечение по углам
	var gold_col := Color(1.0, 0.84, 0.0, base_alpha * min(ratio * 1.5, 1.0))
	
	# Рисуем стильную окантовку
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = 12
	style.border_width_top = 12
	style.border_width_right = 12
	style.border_width_bottom = 12
	style.border_color = gold_col
	style.shadow_color = Color(1.0, 0.72, 0.22, base_alpha * 0.75 * min(ratio * 1.5, 1.0))
	style.shadow_size = 32
	
	draw_style_box(style, Rect2(Vector2.ZERO, size))
