extends RefCounted
class_name GameplayHUDPresenter

var _scene: Control # Dynamic GameplayScene
var _refs: GameplayNodeRefs
var _status_tween: Tween
var _star_tween: Tween

func setup(scene: Control, refs: GameplayNodeRefs) -> void:
	_scene = scene
	_refs = refs

func initialize_hud() -> void:
	_refs.progress_bar.show_percentage = false
	_refs.progress_bar.min_value = 0.0
	_refs.progress_bar.max_value = 100.0
	_refs.progress_bar.value = 0.0
	
	_apply_styles()

func update_score(score: int, stars: int, current_stars: int) -> int:
	_refs.score_value.text = _scene.call("_format_int", score)
	
	var _stars_changed := false
	if stars > current_stars:
		_play_star_unlock()
		SoundManager.play("confirm_star")
		_stars_changed = true
	
	for index in range(_refs.star_labels.size()):
		var label: Label = _refs.star_labels[index]
		var unlocked := index < stars
		label.add_theme_color_override("font_color", _scene.call("_tc", "shared.colors.accent_gold", "gold") if unlocked else _scene.call("_with_alpha", _scene.call("_tc", "shared.colors.text_muted", "dark_blur"), 0.70))
		label.scale = Vector2.ONE if unlocked else Vector2.ONE * 0.92
		
	return stars

func update_moves(remaining: int) -> void:
	_refs.moves_value.text = str(remaining)
	var warning_color: Color = _scene.call("_tc", "gameplay.state.moves_ok", "dark_blur")
	if remaining <= 3:
		warning_color = _scene.call("_tc", "gameplay.state.moves_danger", "accent")
	elif remaining <= 9:
		warning_color = _scene.call("_tc", "gameplay.state.moves_warning", "gold")
	_refs.moves_value.add_theme_color_override("font_color", warning_color)

func update_goals(goals: Array) -> void:
	for child in _refs.mission_goals.get_children():
		child.queue_free()

	if goals.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No mission loaded"
		empty_label.add_theme_font_size_override("font_size", _scene.call("_ti", "shared.font.body", 16))
		empty_label.add_theme_color_override("font_color", _scene.call("_tc", "gameplay.text.caption", "dark_blur"))
		_refs.mission_goals.add_child(empty_label)
		return

	for goal in goals:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 64)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var chip_style: StyleBoxFlat = _scene.call("_style", "gameplay.surface.mission_chip")
		chip.set("theme_override_styles/panel", chip_style)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", _scene.call("_ti", "shared.spacing.sm", 8))
		chip.add_child(row)

		var icon := Label.new()
		icon.text = _goal_icon(goal)
		icon.add_theme_font_size_override("font_size", 28)
		icon.add_theme_color_override("font_color", _goal_color(goal))
		row.add_child(icon)

		var text_column := VBoxContainer.new()
		text_column.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(text_column)

		var title := Label.new()
		title.text = _goal_title(goal)
		title.add_theme_font_size_override("font_size", _scene.call("_ti", "shared.font.caption", 13))
		title.add_theme_color_override("font_color", _scene.call("_tc", "gameplay.text.caption", "dark_blur"))
		text_column.add_child(title)

		var count := Label.new()
		count.text = _goal_progress_text(goal)
		count.add_theme_font_size_override("font_size", _scene.call("_ti", "shared.font.subtitle", 18))
		var goal_color: Color = _scene.call("_tc", "shared.colors.accent_secondary", "accent") if goal.get("completed", false) else _scene.call("_tc", "gameplay.text.metric_primary", "dark_blur")
		count.add_theme_color_override("font_color", goal_color)
		text_column.add_child(count)

		_refs.mission_goals.add_child(chip)

func update_progress(goals: Array) -> void:
	var relevant_goals: Array[Dictionary] = []
	for goal in goals:
		if int(goal.get("type", GameConstants.GoalType.SCORE)) != GameConstants.GoalType.SCORE:
			relevant_goals.append(goal)

	if relevant_goals.is_empty():
		relevant_goals = goals.duplicate(true)

	var total_ratio: float = 0.0
	for goal in relevant_goals:
		var target: int = max(int(goal.get("target", 0)), 1)
		var current: int = int(goal.get("current", 0))
		total_ratio += clamp(float(current) / float(target), 0.0, 1.0)

	var progress: float = 0.0
	if not relevant_goals.is_empty():
		progress = total_ratio / float(relevant_goals.size())

	_refs.progress_bar.value = progress * 100.0

func show_status(message: String, is_error: bool = false, alpha: float = 0.9) -> void:
	_refs.status_label.text = message
	_refs.status_label.add_theme_color_override("font_color", _scene.call("_tc", "gameplay.text.status_error", "accent") if is_error else _scene.call("_tc", "gameplay.text.status", "dark_blur"))
	if _status_tween != null:
		_status_tween.kill()
	_refs.status_label.modulate.a = alpha
	_status_tween = _scene.create_tween()
	_status_tween.tween_property(_refs.status_label, "modulate:a", alpha, 0.05)
	_status_tween.tween_interval(1.4)
	_status_tween.tween_property(_refs.status_label, "modulate:a", 0.0, 0.4)

func _play_star_unlock() -> void:
	if _star_tween != null:
		_star_tween.kill()
	_star_tween = _scene.create_tween()
	for label in _refs.star_labels:
		_star_tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.12)
		_star_tween.tween_property(label, "scale", Vector2.ONE, 0.16)

func _apply_styles() -> void:
	var glass_style: StyleBoxFlat = _scene.call("_style", "gameplay.surface.hud")
	var moves_style: StyleBoxFlat = _scene.call("_style", "gameplay.surface.kpi_primary")
	var score_style: StyleBoxFlat = _scene.call("_style", "gameplay.surface.kpi_secondary")

	_refs.moves_panel.set("theme_override_styles/panel", moves_style)
	_refs.score_panel.set("theme_override_styles/panel", score_style)
	
	_refs.progress_bar.set("theme_override_styles/background", _scene.call("_style", "gameplay.surface.progress_bg"))
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		_scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_secondary", "accent"), 0.92),
		_scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_primary", "accent"), 0.92),
		_scene.call("_with_alpha", _scene.call("_tc", "colors.accent", "accent"), 0.92),
		_scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_gold", "gold"), 0.92)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	
	var fill_style := StyleBoxTexture.new()
	fill_style.texture = grad_tex
	fill_style.texture_margin_left = 6
	fill_style.texture_margin_right = 6
	fill_style.texture_margin_top = 4
	fill_style.texture_margin_bottom = 4
	_refs.progress_bar.set("theme_override_styles/fill", fill_style)

	_scene.call("_set_label_style", _refs.world_title, _scene.call("_ti", "shared.font.title", 24) + 2, _scene.call("_tc", "gameplay.text.title", "dark_blur"))
	_refs.world_title.add_theme_color_override("font_outline_color", _scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_primary", "accent"), 0.35))
	_refs.world_title.add_theme_constant_override("outline_size", 4)
	
	_scene.call("_set_label_style", _refs.level_subtitle, _scene.call("_ti", "shared.font.caption", 13), _scene.call("_tc", "gameplay.text.subtitle", "dark_blur"))
	_scene.call("_set_label_style", _refs.moves_value, 36, _scene.call("_tc", "gameplay.state.moves_ok", "dark_blur"))
	_scene.call("_set_label_style", _refs.score_value, 28, _scene.call("_tc", "gameplay.text.metric_secondary", "dark_blur"))
	_scene.call("_set_label_style", _refs.status_label, _scene.call("_ti", "shared.font.body", 16), _scene.call("_tc", "gameplay.text.status", "dark_blur"))

	for star in _refs.star_labels:
		star.text = "★"
		star.add_theme_font_size_override("font_size", 28)

func _goal_icon(goal: Dictionary) -> String:
	match int(goal.get("type", GameConstants.GoalType.SCORE)):
		GameConstants.GoalType.SCORE:
			return "★"
		GameConstants.GoalType.COLLECT_GEM:
			match int(goal.get("gem_type", 0)):
				0: return "✦"
				1: return "◎"
				2: return "≈"
				3: return "◉"
				4: return "≋"
				_: return "◌"
		GameConstants.GoalType.BREAK_BLOCKER:
			return "❖"
		_:
			return "◌"

func _goal_title(goal: Dictionary) -> String:
	match int(goal.get("type", GameConstants.GoalType.SCORE)):
		GameConstants.GoalType.SCORE:
			return "Score target"
		GameConstants.GoalType.COLLECT_GEM:
			return _gem_name(int(goal.get("gem_type", -1)))
		GameConstants.GoalType.BREAK_BLOCKER:
			return "Break blockers"
		_:
			return "Mission"

func _goal_progress_text(goal: Dictionary) -> String:
	if goal.get("completed", false):
		return "Done"
	return "%d / %d" % [int(goal.get("current", 0)), int(goal.get("target", 0))]

func _goal_color(goal: Dictionary) -> Color:
	match int(goal.get("gem_type", -1)):
		0: return _scene.call("_tc", "colors.accent", "accent")
		1: return _scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_primary", "accent"), 0.75)
		2: return _scene.call("_tc", "shared.colors.accent_primary", "accent")
		3: return _scene.call("_tc", "colors.accent", "accent")
		4: return _scene.call("_tc", "shared.colors.accent_secondary", "accent")
		5: return _scene.call("_with_alpha", _scene.call("_tc", "shared.colors.accent_secondary", "accent"), 0.7)
		_: return _scene.call("_tc", "shared.colors.accent_gold", "gold")

func _gem_name(gem_type: int) -> String:
	match gem_type:
		0: return "Star Dust"
		1: return "Pearl Ring"
		2: return "Cyan Flow"
		3: return "Pulse Core"
		4: return "Mint Lines"
		5: return "Bubble Spark"
		_: return "Collect"
