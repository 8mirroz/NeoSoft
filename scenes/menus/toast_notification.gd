extends Control
class_name ToastNotification

@onready var panel := $PanelContainer
@onready var label := $PanelContainer/MarginContainer/Label

func _ready() -> void:
	modulate.a = 0.0

func show_message(text: String) -> void:
	if not is_node_ready():
		await ready
	
	label.text = text
	
	# Set pivot to center for nice pop scale animation
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.9, 0.9)
	
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25)
	
	# Non-parallel sequence for hold and fade-out
	var seq_tween := create_tween()
	seq_tween.tween_interval(1.8)
	var fade_out := seq_tween.tween_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fade_out.tween_property(self, "modulate:a", 0.0, 0.38)
	fade_out.tween_property(panel, "scale", Vector2(0.92, 0.92), 0.38)
	seq_tween.tween_callback(queue_free)
