extends Control

const GAMEPLAY_SCENE := "res://scenes/gameplay/gameplay.tscn"

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel

var top_bar: HBoxContainer
var subtitle_label: Label
var map_hint_label: Label
var coin_label: Label
var star_label: Label
var inbox_button: Button
var next_world_card: PanelContainer
var next_world_title: Label
var next_world_name: Label
var next_world_progress: Label
var world_map_cache: Array[Vector2] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_chrome()
	_apply_theme()
	_build_level_grid()
	_animate_entry()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _draw() -> void:
	var bg := Color(0.95, 0.93, 0.99, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), bg, true)
	draw_circle(Vector2(size.x * 0.14, size.y * 0.12), size.x * 0.34, Color(1.0, 0.85, 0.92, 0.16))
	draw_circle(Vector2(size.x * 0.82, size.y * 0.16), size.x * 0.30, Color(0.82, 0.86, 1.0, 0.18))
	draw_circle(Vector2(size.x * 0.22, size.y * 0.84), size.x * 0.24, Color(0.78, 0.93, 1.0, 0.14))
	draw_circle(Vector2(size.x * 0.88, size.y * 0.82), size.x * 0.18, Color(1.0, 0.90, 0.82, 0.10))

	_draw_path()

func _build_chrome() -> void:
	if is_instance_valid(top_bar):
		top_bar.queue_free()
	top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.layout_mode = 1
	top_bar.anchors_preset = Control.PRESET_TOP_WIDE
	top_bar.offset_left = 24.0
	top_bar.offset_top = 40.0
	top_bar.offset_right = -24.0
	top_bar.offset_bottom = 104.0
	top_bar.add_theme_constant_override("separation", 12)
	add_child(top_bar)

	var coin_pill := _make_resource_pill("🪙", str(UserData.coins), true)
	coin_label = coin_pill.get_node("HBox/Value") as Label
	top_bar.add_child(coin_pill)

	var star_count: int = int(UserData.get_retention_summary().get("completed_levels", 0))
	var star_pill := _make_resource_pill("⭐", str(star_count * 3), true)
	star_label = star_pill.get_node("HBox/Value") as Label
	top_bar.add_child(star_pill)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	inbox_button = Button.new()
	inbox_button.custom_minimum_size = Vector2(56, 56)
	inbox_button.focus_mode = Control.FOCUS_NONE
	inbox_button.text = "✉"
	inbox_button.set("theme_override_styles/normal", _make_glass_style(22, Color(1, 1, 1, 0.34), Color(1, 1, 1, 0.66)))
	inbox_button.set("theme_override_styles/hover", _make_glass_style(22, Color(1, 1, 1, 0.42), Color(0.82, 0.86, 1.0, 0.8)))
	inbox_button.set("theme_override_styles/pressed", _make_glass_style(22, Color(1, 1, 1, 0.28), Color(0.82, 0.86, 1.0, 0.8)))
	inbox_button.set("theme_override_styles/focus", StyleBoxEmpty.new())
	inbox_button.add_theme_font_size_override("font_size", 22)
	inbox_button.add_theme_color_override("font_color", Color(0.34, 0.32, 0.48))
	top_bar.add_child(inbox_button)

	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(10, 10)
	badge.position = Vector2(34, 2)
	badge.set("theme_override_styles/panel", _make_glass_style(5, Color(0.98, 0.52, 0.72, 1.0), Color(1.0, 0.92, 0.96, 1.0)))
	inbox_button.add_child(badge)

	title_label.text = "Neo Soft Frost"
	title_label.position = Vector2(0, 0)

	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.text = "Dreamy map • choose your next crystal path"
	subtitle_label.add_theme_color_override("font_color", Color(0.46, 0.42, 0.62))
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.anchors_preset = Control.PRESET_TOP_WIDE
	subtitle_label.offset_left = 20.0
	subtitle_label.offset_top = 114.0
	subtitle_label.offset_right = -20.0
	subtitle_label.offset_bottom = 140.0
	add_child(subtitle_label)

	map_hint_label = Label.new()
	map_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_hint_label.text = "Tap an orb to preview the level"
	map_hint_label.add_theme_color_override("font_color", Color(0.52, 0.48, 0.68))
	map_hint_label.add_theme_font_size_override("font_size", 13)
	map_hint_label.anchors_preset = Control.PRESET_TOP_WIDE
	map_hint_label.offset_left = 20.0
	map_hint_label.offset_top = 160.0
	map_hint_label.offset_right = -20.0
	map_hint_label.offset_bottom = 182.0
	add_child(map_hint_label)

	if is_instance_valid(next_world_card):
		next_world_card.queue_free()
	next_world_card = PanelContainer.new()
	next_world_card.name = "NextWorldCard"
	next_world_card.custom_minimum_size = Vector2(176, 210)
	next_world_card.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	next_world_card.offset_left = -196.0
	next_world_card.offset_top = -352.0
	next_world_card.offset_right = -24.0
	next_world_card.offset_bottom = -132.0
	next_world_card.set("theme_override_styles/panel", _make_panel_style(Color(1.0, 1.0, 1.0, 0.30), Color(1.0, 1.0, 1.0, 0.72), 30, 2))
	add_child(next_world_card)

	var next_margin := MarginContainer.new()
	next_margin.add_theme_constant_override("margin_left", 18)
	next_margin.add_theme_constant_override("margin_top", 18)
	next_margin.add_theme_constant_override("margin_right", 18)
	next_margin.add_theme_constant_override("margin_bottom", 18)
	next_world_card.add_child(next_margin)

	var next_vbox := VBoxContainer.new()
	next_vbox.add_theme_constant_override("separation", 10)
	next_margin.add_child(next_vbox)

	next_world_title = Label.new()
	next_world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_world_title.text = "Next World"
	next_world_title.add_theme_font_size_override("font_size", 14)
	next_world_title.add_theme_color_override("font_color", Color(0.40, 0.36, 0.56))
	next_vbox.add_child(next_world_title)

	next_world_name = Label.new()
	next_world_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_world_name.text = "Crystal Vale"
	next_world_name.add_theme_font_size_override("font_size", 24)
	next_world_name.add_theme_color_override("font_color", Color(0.28, 0.26, 0.42))
	next_vbox.add_child(next_world_name)

	var orb_preview := LevelOrb.new()
	orb_preview.custom_minimum_size = Vector2(112, 112)
	orb_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	orb_preview.level_index = 999
	orb_preview.locked = true
	next_vbox.add_child(orb_preview)

	next_world_progress = Label.new()
	next_world_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_world_progress.text = "0/36"
	next_world_progress.add_theme_font_size_override("font_size", 16)
	next_world_progress.add_theme_color_override("font_color", Color(0.44, 0.40, 0.58))
	next_vbox.add_child(next_world_progress)

func _build_level_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var available_levels: int = LevelLoader.get_available_level_count()
	var total_slots: int = maxi(12, available_levels)
	var summary: Dictionary = UserData.get_retention_summary()
	title_label.text = "Select Level"
	subtitle_label.text = "World progress • %d/%d cleared • streak %d" % [
		int(summary.get("completed_levels", 0)),
		available_levels,
		int(summary.get("daily_streak", 0)),
	]
	if next_world_progress:
		next_world_progress.text = "%d/%d" % [
			int(summary.get("completed_levels", 0)),
			maxi(available_levels, 1),
		]

	world_map_cache.clear()

	for i in range(1, total_slots + 1):
		var level_exists: bool = LevelLoader.level_exists(i)
		var unlocked: bool = level_exists and (i <= UserData.unlocked_level)
		var stars: int = int(UserData.level_stars.get(i, 0))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(144, 144)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_level_button(btn, unlocked, level_exists)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 7)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)

		var orb := LevelOrb.new()
		orb.custom_minimum_size = Vector2(82, 82)
		orb.level_index = i
		orb.locked = not unlocked
		orb.is_boss_node = i % 6 == 0
		orb.set_level_state(unlocked, stars)
		vbox.add_child(orb)

		var num_label := Label.new()
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.add_theme_font_size_override("font_size", 28)
		num_label.text = str(i) if level_exists else "Soon"
		num_label.add_theme_color_override("font_color", Color(0.30, 0.28, 0.44) if unlocked else Color(0.56, 0.54, 0.68))
		vbox.add_child(num_label)

		if unlocked:
			var star_hbox := HBoxContainer.new()
			star_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			star_hbox.add_theme_constant_override("separation", 2)
			vbox.add_child(star_hbox)

			for s in range(3):
				var star_label := Label.new()
				star_label.add_theme_font_size_override("font_size", 14)
				star_label.text = "★" if s < stars else "☆"
				star_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.44) if s < stars else Color(0.74, 0.72, 0.84, 0.60))
				star_hbox.add_child(star_label)

			btn.pressed.connect(_start_level.bind(i))
		else:
			var lock_label := Label.new()
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.text = "🔒"
			lock_label.add_theme_font_size_override("font_size", 18)
			lock_label.add_theme_color_override("font_color", Color(0.58, 0.58, 0.72))
			vbox.add_child(lock_label)
			btn.disabled = true

		grid_container.add_child(btn)
		world_map_cache.append(_grid_center_for_index(i - 1))

	queue_redraw()

func _start_level(level_num: int) -> void:
	UserData.set_active_level(level_num)
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)

func _animate_entry() -> void:
	modulate.a = 0.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.42)

func _apply_theme() -> void:
	_set_label_style(title_label, 40, Color(0.28, 0.26, 0.42))
	title_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.90))
	title_label.add_theme_constant_override("outline_size", 8)
	_style_nav_button(back_button)

	var scroll_style := _make_panel_style(Color(1.0, 1.0, 1.0, 0.25), Color(0.88, 0.86, 1.0, 0.82), 42, 2)
	$ScrollContainer.set("theme_override_styles/panel", scroll_style)
	$ScrollContainer.modulate = Color(1, 1, 1, 0.98)
	grid_container.add_theme_constant_override("h_separation", 20)
	grid_container.add_theme_constant_override("v_separation", 20)

func _style_level_button(button: Button, unlocked: bool, level_exists: bool) -> void:
	var accent := Color(0.78, 0.92, 1.0) if unlocked else Color(0.86, 0.84, 0.95)
	var bg := Color(1.0, 1.0, 1.0, 0.36) if unlocked else Color(1.0, 1.0, 1.0, 0.18)
	button.set("theme_override_styles/normal", _make_panel_style(bg, accent if unlocked else Color(0.84, 0.84, 0.9, 0.36), 28, 2))
	button.set("theme_override_styles/hover", _make_panel_style(Color(1.0, 1.0, 1.0, 0.48), accent.lightened(0.08), 28, 2))
	button.set("theme_override_styles/pressed", _make_panel_style(Color(0.95, 0.96, 1.0, 0.54), accent, 28, 3))
	button.set("theme_override_styles/focus", _make_panel_style(Color(0.95, 0.96, 1.0, 0.54), accent, 28, 3))
	button.set("theme_override_styles/disabled", _make_panel_style(Color(0.96, 0.96, 0.99, 0.18), Color(0.82, 0.82, 0.88, 0.26), 28, 1))
	button.add_theme_color_override("font_color", Color(0.62, 0.60, 0.74) if not level_exists else Color(0.35, 0.33, 0.5))

func _style_nav_button(button: Button) -> void:
	var accent := Color(1.0, 0.9, 0.76)
	button.set("theme_override_styles/normal", _make_panel_style(Color(1.0, 1.0, 1.0, 0.34), Color(1.0, 1.0, 1.0, 0.56), 28, 2))
	button.set("theme_override_styles/hover", _make_panel_style(Color(1.0, 1.0, 1.0, 0.40), accent.lightened(0.08), 28, 2))
	button.set("theme_override_styles/pressed", _make_panel_style(Color(0.95, 0.96, 1.0, 0.44), accent, 28, 3))
	button.set("theme_override_styles/focus", _make_panel_style(Color(0.95, 0.96, 1.0, 0.44), accent, 28, 3))
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.35, 0.33, 0.5))

func _set_label_style(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)

func _make_resource_pill(icon_text: String, value_text: String, include_plus: bool) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(150, 54)
	pill.set("theme_override_styles/panel", _make_panel_style(Color(1.0, 1.0, 1.0, 0.34), Color(1.0, 1.0, 1.0, 0.70), 24, 2))

	var hb := HBoxContainer.new()
	hb.name = "HBox"
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	pill.add_child(hb)

	var icon := Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", Color(0.36, 0.34, 0.50))
	hb.add_child(icon)

	var value := Label.new()
	value.name = "Value"
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(0.28, 0.26, 0.42))
	hb.add_child(value)

	if include_plus:
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(32, 32)
		plus.focus_mode = Control.FOCUS_NONE
		plus.set("theme_override_styles/normal", _make_panel_style(Color(1.0, 1.0, 1.0, 0.34), Color(1.0, 1.0, 1.0, 0.56), 16, 2))
		plus.set("theme_override_styles/hover", _make_panel_style(Color(1.0, 1.0, 1.0, 0.44), Color(0.82, 0.86, 1.0, 0.80), 16, 2))
		plus.set("theme_override_styles/pressed", _make_panel_style(Color(0.96, 0.96, 1.0, 0.44), Color(0.82, 0.86, 1.0, 0.80), 16, 2))
		plus.set("theme_override_styles/focus", StyleBoxEmpty.new())
		plus.add_theme_font_size_override("font_size", 16)
		plus.add_theme_color_override("font_color", Color(0.28, 0.26, 0.42))
		hb.add_child(plus)

	return pill

func _make_glass_style(radius: int, bg_color: Color, border_color: Color) -> StyleBoxFlat:
	return _make_panel_style(bg_color, border_color, radius, 2)

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
	style.shadow_size = 14
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	return style

func _grid_center_for_index(index: int) -> Vector2:
	var columns := grid_container.columns
	if columns <= 0:
		columns = 3
	var cell_size := Vector2(144, 144)
	var separation := Vector2(20, 20)
	var row := float(index / columns)
	var column := float(index % columns)
	return Vector2(
		72.0 + column * (cell_size.x + separation.x),
		72.0 + row * (cell_size.y + separation.y)
	)

func _draw_path() -> void:
	if grid_container.get_child_count() < 2:
		return

	var centers: Array[Vector2] = []
	for i in range(grid_container.get_child_count()):
		var node := grid_container.get_child(i)
		if node is Control:
			centers.append(node.global_position + node.size * 0.5 - global_position)

	for i in range(centers.size() - 1):
		var a := centers[i]
		var b := centers[i + 1]
		draw_line(a, b, Color(1.0, 1.0, 1.0, 0.22), 4.0)
		draw_line(a, b, Color(0.78, 0.86, 1.0, 0.36), 2.0)

	for i in range(centers.size()):
		var c := centers[i]
		var pulse := 0.55 + sin(float(i) * 1.7) * 0.10
		draw_circle(c, 7.0, Color(1.0, 1.0, 1.0, 0.20))
		draw_circle(c, 2.0 + pulse, Color(1.0, 0.98, 0.95, 0.80))

class LevelOrb extends Control:
	var level_index: int = 0
	var locked: bool = false
	var is_boss_node: bool = false
	var _stars: int = 0

	func set_level_state(unlocked: bool, stars: int) -> void:
		locked = not unlocked
		_stars = stars
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius: float = min(size.x, size.y) * 0.42
		var base := Color(0.96, 0.97, 1.0, 0.70)
		var tint := Color(0.76, 0.88, 1.0, 0.42) if not locked else Color(0.90, 0.90, 0.96, 0.26)
		if is_boss_node:
			tint = Color(1.0, 0.84, 0.90, 0.44)

		draw_circle(center + Vector2(0, 4), radius + 4.0, Color(0.72, 0.66, 0.90, 0.16))
		draw_circle(center, radius + 2.0, Color(1.0, 1.0, 1.0, 0.10))
		draw_circle(center, radius, base)
		draw_circle(center + Vector2(-radius * 0.18, -radius * 0.18), radius * 0.82, tint)
		draw_circle(center + Vector2(-radius * 0.32, -radius * 0.32), radius * 0.24, Color(1.0, 1.0, 1.0, 0.72))

		if locked:
			var lock_rect := Rect2(center - Vector2(12, 10), Vector2(24, 20))
			draw_rect(lock_rect, Color(1.0, 1.0, 1.0, 0.18), true)
			draw_arc(center + Vector2(0, -8), 10.0, PI, TAU, 18, Color(1.0, 1.0, 1.0, 0.72), 2.0)
