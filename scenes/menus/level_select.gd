extends Control

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_apply_theme()
	_build_level_grid()
	_animate_entry()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.97, 0.97, 1.0, 1.0), true)
	draw_circle(Vector2(size.x * 0.15, size.y * 0.1), size.x * 0.32, Color(1.0, 0.88, 0.86, 0.16))
	draw_circle(Vector2(size.x * 0.82, size.y * 0.16), size.x * 0.28, Color(0.83, 0.82, 1.0, 0.18))
	draw_circle(Vector2(size.x * 0.26, size.y * 0.86), size.x * 0.24, Color(0.78, 0.93, 1.0, 0.14))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _build_level_grid() -> void:
	# Clear old children if any
	for child in grid_container.get_children():
		child.queue_free()

	var available_levels := LevelLoader.get_available_level_count()
	var total_slots := maxi(12, available_levels)
	var summary := UserData.get_retention_summary()
	title_label.text = "Select Level • %d/%d cleared • streak %d" % [
		int(summary.get("completed_levels", 0)),
		available_levels,
		int(summary.get("daily_streak", 0)),
	]
		
	for i in range(1, total_slots + 1):
		var level_exists := LevelLoader.level_exists(i)
		var unlocked := level_exists and (i <= UserData.unlocked_level)
		var stars: int = int(UserData.level_stars.get(i, 0))
		
		# Create button container
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130.0, 130.0)
		btn.focus_mode = Control.FOCUS_NONE
		_style_level_button(btn, unlocked, level_exists)
		
		# Layout inside button
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		# Anchors
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)
		
		# Level text/icon
		var num_label := Label.new()
		num_label.add_theme_font_size_override("font_size", 28)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if unlocked:
			num_label.text = str(i)
			num_label.add_theme_color_override("font_color", Color(0.31, 0.28, 0.46))
			
			# Star row
			var star_hbox := HBoxContainer.new()
			star_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			star_hbox.add_theme_constant_override("separation", 2)
			vbox.add_child(star_hbox)
			
			for s in range(3):
				var star_label := Label.new()
				star_label.add_theme_font_size_override("font_size", 14)
				if s < stars:
					star_label.text = "★"
					star_label.add_theme_color_override("font_color", Color(0.96, 0.85, 0.50))
				else:
					star_label.text = "☆"
					star_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.84, 0.56))
				star_hbox.add_child(star_label)
				
			# Press action
			btn.pressed.connect(func(): _start_level(i))
		elif level_exists:
			num_label.text = str(i)
			num_label.add_theme_color_override("font_color", Color(0.56, 0.56, 0.68))
			btn.disabled = true
		else:
			num_label.text = "Soon"
			num_label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.72))
			btn.disabled = true
			
		vbox.add_child(num_label)
		vbox.move_child(num_label, 0) # Place number above stars
		grid_container.add_child(btn)

func _start_level(level_num: int) -> void:
	UserData.set_active_level(level_num)
	get_tree().change_scene_to_file("res://scenes/gameplay/gameplay_soft_frost.tscn")

func _animate_entry() -> void:
	modulate.a = 0.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _apply_theme() -> void:
	_set_label_style(title_label, 36, Color(0.27, 0.27, 0.44))
	title_label.text = "Select Level"
	_style_nav_button(back_button)

	var scroll_style := _make_panel_style(Color(0.98, 0.99, 1.0, 0.28), Color(0.86, 0.84, 1.0, 0.84), 40, 2)
	$ScrollContainer.set("theme_override_styles/panel", scroll_style)

func _style_level_button(button: Button, unlocked: bool, level_exists: bool) -> void:
	var accent := Color(0.78, 0.92, 1.0) if unlocked else Color(0.86, 0.84, 0.95)
	var normal := _make_panel_style(
		Color(0.98, 0.99, 1.0, 0.36) if unlocked else Color(0.98, 0.98, 1.0, 0.16),
		accent if unlocked else Color(0.84, 0.84, 0.9, 0.36),
		24,
		2
	)
	var hover := _make_panel_style(
		Color(1.0, 1.0, 1.0, 0.44) if unlocked else Color(0.98, 0.98, 1.0, 0.18),
		accent.lightened(0.08) if unlocked else Color(0.84, 0.84, 0.9, 0.38),
		24,
		2
	)
	var pressed := _make_panel_style(
		Color(0.95, 0.96, 1.0, 0.48) if unlocked else Color(0.96, 0.96, 1.0, 0.2),
		accent if unlocked else Color(0.84, 0.84, 0.9, 0.4),
		24,
		3
	)
	var disabled := _make_panel_style(
		Color(0.96, 0.96, 0.99, 0.18),
		Color(0.82, 0.82, 0.88, 0.26),
		24,
		1
	)
	button.set("theme_override_styles/normal", normal)
	button.set("theme_override_styles/hover", hover)
	button.set("theme_override_styles/pressed", pressed)
	button.set("theme_override_styles/focus", pressed)
	button.set("theme_override_styles/disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.62, 0.6, 0.74) if not level_exists else Color(0.35, 0.33, 0.5))

func _style_nav_button(button: Button) -> void:
	var accent := Color(1.0, 0.9, 0.76)
	button.set("theme_override_styles/normal", _make_panel_style(Color(0.98, 0.98, 1.0, 0.3), Color(1.0, 1.0, 1.0, 0.56), 28, 2))
	button.set("theme_override_styles/hover", _make_panel_style(Color(1.0, 1.0, 1.0, 0.36), accent.lightened(0.08), 28, 2))
	button.set("theme_override_styles/pressed", _make_panel_style(Color(0.95, 0.96, 1.0, 0.4), accent, 28, 3))
	button.set("theme_override_styles/focus", _make_panel_style(Color(0.95, 0.96, 1.0, 0.4), accent, 28, 3))
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.35, 0.33, 0.5))

func _set_label_style(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)

func _make_panel_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.68, 0.58, 0.92, 0.16)
	style.shadow_size = 12
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	return style
