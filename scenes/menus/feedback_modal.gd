extends Control

@onready var stars_hbox := $GlassPanel/MarginContainer/VBoxContainer/StarsHBox
@onready var comment_edit := $GlassPanel/MarginContainer/VBoxContainer/CommentEdit
@onready var submit_btn := $GlassPanel/MarginContainer/VBoxContainer/ButtonsHBox/SubmitButton
@onready var close_btn := $GlassPanel/MarginContainer/VBoxContainer/ButtonsHBox/CloseButton

var current_rating: int = 0
var target_level_id: int = 1

func _ready() -> void:
	# Connect signals
	close_btn.pressed.connect(_close_modal)
	submit_btn.pressed.connect(_on_submit_pressed)
	
	for i in range(5):
		var btn: Button = stars_hbox.get_child(i)
		btn.pressed.connect(_on_star_pressed.bind(i + 1))
	
	_update_star_highlight()

func setup(level_id: int) -> void:
	target_level_id = level_id
	_update_star_highlight()

func _on_star_pressed(rating: int) -> void:
	SoundManager.play("tap")
	current_rating = rating
	_update_star_highlight()

func _update_star_highlight() -> void:
	for i in range(5):
		var btn: Button = stars_hbox.get_child(i)
		btn.text = "★"
		btn.self_modulate = Color(1.0, 0.85, 0.2) if (i < current_rating) else Color(1.0, 1.0, 1.0, 0.3)

func _on_submit_pressed() -> void:
	SoundManager.play("confirm_star")
	var comment := comment_edit.text.strip_edges()
	UserData.save_feedback(target_level_id, current_rating, comment)
	_close_modal()

func _close_modal() -> void:
	SoundManager.play("close")
	queue_free()
