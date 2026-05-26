## Gameplay — основная игровая сцена
## Содержит LevelSession + presentation layer для HUD, поля и бустеров
extends Control

const WORLD_NAME := "Neo Soft Frost"

@onready var level_session: LevelSession = $LevelSession
@onready var board_visual: BoardView = $BoardArea/BoardFrame/BoardPadding/BoardVisual
@onready var world_title: Label = $HUD/TopBar/Layout/LevelPanel/Content/WorldTitle
@onready var level_subtitle: Label = $HUD/TopBar/Layout/LevelPanel/Content/LevelSubtitle
@onready var progress_bar: ProgressBar = $HUD/TopBar/Layout/LevelPanel/Content/ProgressBar
@onready var mission_goals: HBoxContainer = $HUD/TopBar/Layout/MissionPanel/Content/GoalItems
@onready var moves_panel: PanelContainer = $HUD/TopBar/Layout/StatsColumn/MovesPanel
@onready var score_panel: PanelContainer = $HUD/TopBar/Layout/StatsColumn/ScorePanel
@onready var moves_value: Label = $HUD/TopBar/Layout/StatsColumn/MovesPanel/Content/Value
@onready var score_value: Label = $HUD/TopBar/Layout/StatsColumn/ScorePanel/Content/Value
@onready var status_label: Label = $HUD/StatusLabel
@onready var shuffle_button: Button = $HUD/BoosterBar/Layout/ShuffleButton
@onready var hammer_button: Button = $HUD/BoosterBar/Layout/HammerButton
@onready var undo_button: Button = $HUD/BoosterBar/Layout/UndoButton

@onready var star_labels: Array[Label] = [
	$HUD/TopBar/Layout/LevelPanel/Content/Stars/Star1,
	$HUD/TopBar/Layout/LevelPanel/Content/Stars/Star2,
	$HUD/TopBar/Layout/LevelPanel/Content/Stars/Star3,
]

var current_goals: Array[Dictionary] = []
var current_stars: int = 0
var hammer_mode: bool = false
var session_finished: bool = false
var session_paused: bool = false
var soft_launch_config: Dictionary = {}
var quality_profile: Dictionary = {}
var status_tween: Tween
var star_tween: Tween
var bg_time: float = 0.0
var overlay_mode: String = ""
var overlay_payload: Dictionary = {}
var pause_button: Button
var overlay_layer: Control
var overlay_card: PanelContainer
var overlay_title: Label
var overlay_body: Label
var overlay_primary_button: Button
var overlay_secondary_button: Button
var overlay_tertiary_button: Button
var overlay_quality_button: Button
var overlay_export_button: Button
var overlay_feedback_button: Button

func _theme_tokens() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("ThemeTokensAutoload")
	return null

func _tc(path: String, legacy_key: String = "white") -> Color:
	var tokens := _theme_tokens()
	if tokens != null and tokens.has_method("color_path"):
		return tokens.color_path(path, tokens.color(legacy_key, Color.WHITE))
	return Color.WHITE

func _ti(path: String, fallback: int = 0) -> int:
	var tokens := _theme_tokens()
	if tokens != null and tokens.has_method("int_value"):
		return tokens.int_value(path, fallback)
	return fallback

func _with_alpha(base: Color, alpha: float) -> Color:
	var c := base
	c.a = alpha
	return c

func _style(path: String) -> StyleBoxFlat:
	var tokens := _theme_tokens()
	if tokens != null and tokens.has_method("make_panel_style"):
		return tokens.make_panel_style(path)
	return _make_panel_style(_with_alpha(_tc("shared.colors.glass_bg"), 0.34), _with_alpha(_tc("shared.colors.glass_border"), 0.66), _ti("shared.radius.md", 22), 2)

func _ready() -> void:
	soft_launch_config = LevelLoader.load_soft_launch_config()
	quality_profile = _get_quality_profile()
	_build_runtime_overlay()
	_apply_theme()
	_connect_events()

	board_visual.cell_pressed.connect(_on_board_cell_pressed)
	board_visual.animations_finished.connect(_on_board_visual_animations_finished)
	shuffle_button.pressed.connect(_on_shuffle_pressed)
	hammer_button.pressed.connect(_on_hammer_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	_refresh_undo_button()

	world_title.text = WORLD_NAME
	level_subtitle.text = "Level 01"
	status_label.modulate.a = 0.0

	set_process(true)
	queue_redraw()
	call_deferred("_initialize_presentation")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta: float) -> void:
	bg_time += delta
	queue_redraw()

func _draw() -> void:
	var background_alpha := float(quality_profile.get("background_effect_alpha", 1.0))
	
	# === Layer 0: Premium Opal Pearlescent Base Gradient ===
	# Vertical gradient: top rose-lavender → bottom aqua-opal
	var grad_steps := 16
	var step_h := size.y / float(grad_steps)
	for i in range(grad_steps):
		var t := float(i) / float(grad_steps)
		var top_col := Color(0.96, 0.93, 0.98, 1.0) # Lavender pearl top
		var bot_col := Color(0.92, 0.95, 1.0, 1.0)  # Aqua opal bottom
		var col := top_col.lerp(bot_col, t)
		draw_rect(Rect2(0, i * step_h, size.x, step_h + 1.0), col, true)
	
	# === Layer 1: Slow-drifting atmospheric opal nebulae ===
	var drift1 := Vector2(sin(bg_time * 0.15) * 18.0, cos(bg_time * 0.12) * 12.0)
	var drift2 := Vector2(cos(bg_time * 0.1) * 14.0, sin(bg_time * 0.13) * 16.0)
	var drift3 := Vector2(sin(bg_time * 0.08 + 2.0) * 20.0, cos(bg_time * 0.11 + 1.0) * 10.0)
	var drift4 := Vector2(cos(bg_time * 0.09 + 3.0) * 12.0, sin(bg_time * 0.14) * 14.0)
	
	# Rose glow — top left
	var neb_alpha1 := 0.12 + sin(bg_time * 0.3) * 0.04
	draw_circle(Vector2(size.x * 0.14, size.y * 0.1) + drift1, size.x * 0.48, Color(1.0, 0.82, 0.88, neb_alpha1 * background_alpha))
	# Lavender glow — top right
	var neb_alpha2 := 0.14 + cos(bg_time * 0.25) * 0.04
	draw_circle(Vector2(size.x * 0.82, size.y * 0.14) + drift2, size.x * 0.40, Color(0.88, 0.82, 1.0, neb_alpha2 * background_alpha))
	# Aqua glow — bottom left
	var neb_alpha3 := 0.10 + sin(bg_time * 0.22 + 1.0) * 0.03
	draw_circle(Vector2(size.x * 0.22, size.y * 0.86) + drift3, size.x * 0.36, Color(0.80, 0.94, 1.0, neb_alpha3 * background_alpha))
	# Pink glow — bottom right
	var neb_alpha4 := 0.09 + cos(bg_time * 0.28 + 2.0) * 0.03
	draw_circle(Vector2(size.x * 0.88, size.y * 0.78) + drift4, size.x * 0.28, Color(1.0, 0.86, 0.92, neb_alpha4 * background_alpha))
	# Subtle center pearl shimmer
	var center_alpha := 0.06 + sin(bg_time * 0.4) * 0.02
	draw_circle(Vector2(size.x * 0.5, size.y * 0.45), size.x * 0.32, Color(1.0, 0.96, 1.0, center_alpha * background_alpha))
	
	# === Layer 2: Sparkling cross-star diamonds ===
	var star_positions := [
		Vector2(0.08, 0.06), Vector2(0.92, 0.04), Vector2(0.04, 0.38),
		Vector2(0.96, 0.42), Vector2(0.06, 0.76), Vector2(0.94, 0.78),
		Vector2(0.14, 0.94), Vector2(0.86, 0.96), Vector2(0.50, 0.02),
		Vector2(0.48, 0.98), Vector2(0.02, 0.56), Vector2(0.98, 0.18),
		Vector2(0.30, 0.03), Vector2(0.70, 0.97), Vector2(0.18, 0.68)
	]
	for i in range(star_positions.size()):
		var spos: Vector2 = star_positions[i] * size
		var pulse := 0.5 + sin(bg_time * 2.2 + float(i) * 1.7) * 0.5
		var star_alpha := 0.35 + pulse * 0.45
		# Diamond cross pattern
		var arm_len := 4.0 + pulse * 3.5
		draw_line(spos - Vector2(arm_len, 0), spos + Vector2(arm_len, 0), Color(1.0, 1.0, 1.0, star_alpha * background_alpha), 1.0)
		draw_line(spos - Vector2(0, arm_len), spos + Vector2(0, arm_len), Color(1.0, 1.0, 1.0, star_alpha * background_alpha), 1.0)
		# Bright core dot
		draw_circle(spos, 1.4 + pulse * 0.8, Color(1.0, 0.98, 0.94, (0.7 + pulse * 0.3) * background_alpha))
	
	# === Layer 3: Chromatic edge vignette (subtle rainbow rim on screen borders) ===
	var edge_w := 3.0
	draw_rect(Rect2(0, 0, size.x, edge_w), Color(0.82, 0.72, 1.0, 0.12 * background_alpha), true) # Top lavender
	draw_rect(Rect2(0, size.y - edge_w, size.x, edge_w), Color(0.72, 0.92, 1.0, 0.10 * background_alpha), true) # Bottom aqua
	draw_rect(Rect2(0, 0, edge_w, size.y), Color(1.0, 0.82, 0.88, 0.08 * background_alpha), true) # Left rose
	draw_rect(Rect2(size.x - edge_w, 0, edge_w, size.y), Color(0.88, 1.0, 0.82, 0.08 * background_alpha), true) # Right mint


func _connect_events() -> void:
	EventBus.level_loaded.connect(_on_level_loaded)
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.moves_updated.connect(_on_moves_updated)
	EventBus.goals_updated.connect(_on_goals_updated)
	EventBus.level_finished.connect(_on_level_finished)
	EventBus.swap_rejected.connect(_on_swap_rejected)
	EventBus.match_resolved.connect(_on_match_resolved)
	EventBus.gem_selected.connect(_on_gem_selected)
	EventBus.gem_deselected.connect(_on_gem_deselected)
	EventBus.hint_requested.connect(_on_hint_requested)
	EventBus.board_collapsed.connect(_on_board_collapsed)
	EventBus.pieces_generated.connect(_on_pieces_generated)
	EventBus.turn_finished.connect(_on_turn_finished)
	EventBus.dead_board_detected.connect(_on_dead_board_detected)
	EventBus.auto_shuffle_applied.connect(_on_auto_shuffle_applied)
	EventBus.undo_used.connect(_on_undo_used)
	EventBus.booster_activated.connect(_on_booster_activated)
	EventBus.swap_resolved.connect(_on_swap_resolved)

func _initialize_presentation() -> void:
	if level_session.fever_mode_enabled:
		board_visual.setup(level_session.board_state_engine)
		board_visual.set_quality_profile(quality_profile)
		_initialize_cfe_ui()
	elif level_session.board_controller != null:
		board_visual.setup(level_session.board_controller.board)
		board_visual.set_quality_profile(quality_profile)

func _on_level_loaded(config: Dictionary) -> void:
	session_finished = false
	session_paused = false
	current_stars = 0
	_set_hammer_mode(false)
	_hide_overlay()

	var level_id := int(config.get("level_id", level_session.level_number))
	level_subtitle.text = "Level %02d • %s" % [level_id, config.get("title", "Soft Start")]
	
	if level_session.fever_mode_enabled:
		board_visual.setup(level_session.board_state_engine)
	else:
		board_visual.setup(level_session.board_controller.board)
		
	board_visual.set_quality_profile(quality_profile)
	board_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.visible = true
	_refresh_undo_button()
	_show_status("Match by pattern, not by color.")

func _on_score_updated(score: int, stars: int) -> void:
	score_value.text = _format_int(score)
	_update_star_row(stars)

func _on_moves_updated(remaining: int, _used: int) -> void:
	moves_value.text = str(remaining)
	var warning_color := _tc("gameplay.state.moves_ok", "dark_blur")
	if remaining <= 3:
		warning_color = _tc("gameplay.state.moves_danger", "accent")
	elif remaining <= 9:
		warning_color = _tc("gameplay.state.moves_warning", "gold")
	moves_value.add_theme_color_override("font_color", warning_color)

func _on_goals_updated(goals: Array[Dictionary]) -> void:
	current_goals = goals.duplicate(true)
	_render_goals()
	_update_progress()

func _on_level_finished(result: Dictionary) -> void:
	session_finished = true
	session_paused = false
	board_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_hammer_mode(false)
	_refresh_undo_button()

	if result.get("won", false):
		_show_status("Level complete • %s points" % _format_int(int(result.get("score", 0))), false, 1.0)
		SoundManager.play("win")
	else:
		_show_status("No moves left • try again", true, 1.0)
		SoundManager.play("lose")
	_show_result_overlay(result)

func _on_swap_rejected(_from: Vector2i, _to: Vector2i) -> void:
	_refresh_undo_button()
	_show_status("Swap needs a valid match.", true, 0.92)
	SoundManager.play("error_muted")

func _on_match_resolved(matches: Array[Dictionary]) -> void:
	board_visual.play_match_pop(matches)

func _on_gem_selected(cell: Vector2i) -> void:
	board_visual.set_selected_cell(cell)
	board_visual.clear_hints()
	SoundManager.play("select")

func _on_gem_deselected() -> void:
	board_visual.clear_selection()

func _on_hint_requested(cells: Array[Vector2i]) -> void:
	board_visual.set_hint_cells(cells)
	_show_status("Hint ready.", false, 0.8)

func _on_board_collapsed(movements: Array[Dictionary]) -> void:
	board_visual.play_collapse_fx(movements)
	board_visual.refresh()
	_refresh_undo_button()
	if not movements.is_empty():
		SoundManager.play("drop", -8.0, 1.1)

func _on_pieces_generated(spawns: Array[Dictionary]) -> void:
	board_visual.play_spawn_fx(spawns)
	board_visual.refresh()
	_refresh_undo_button()

func _on_booster_activated(booster_type: int, _cell: Vector2i) -> void:
	match booster_type:
		GameConstants.BoosterType.HAMMER:
			SoundManager.play("hammer")
		GameConstants.BoosterType.SHUFFLE:
			SoundManager.play("shuffle")
		GameConstants.BoosterType.UNDO:
			SoundManager.play("undo")

func _on_swap_resolved(_from: Vector2i, _to: Vector2i) -> void:
	SoundManager.play("swap")
	board_visual.play_swap_fx(_from, _to)

func _on_turn_finished() -> void:
	board_visual.refresh()
	board_visual.clear_hints()
	_refresh_undo_button()

func _on_board_cell_pressed(cell: Vector2i) -> void:
	if session_finished or session_paused:
		return
	if board_visual._has_active_effects():
		return

	if hammer_mode:
		if UserData.use_booster("hammer"):
			EventBus.booster_activated.emit(GameConstants.BoosterType.HAMMER, cell)
			board_visual.refresh()
			_set_hammer_mode(false)
			_show_status("Hammer activated.", false, 0.9)
			_refresh_booster_styles()
		else:
			_set_hammer_mode(false)
			_show_status("No Hammers left!", true, 0.9)
		return

	EventBus.gem_tapped.emit(cell)

func _on_shuffle_pressed() -> void:
	if session_finished or session_paused:
		return
		
	var count := UserData.get_booster_count("shuffle")
	if count <= 0:
		if UserData.buy_booster("shuffle", 150):
			_show_status("Bought Shuffle for 150 🪙!", false, 0.9)
			_refresh_booster_styles()
		else:
			_show_status("Not enough coins! Need 150 🪙.", true, 0.9)
			return

	if UserData.use_booster("shuffle"):
		EventBus.booster_activated.emit(GameConstants.BoosterType.SHUFFLE, Vector2i(-1, -1))
		board_visual.refresh()
		_show_status("Field reshuffled.", false, 0.9)
		_refresh_booster_styles()

func _on_hammer_pressed() -> void:
	if session_finished or session_paused:
		return
		
	if hammer_mode:
		_set_hammer_mode(false)
		_show_status("Hammer cancelled.", false, 0.75)
		return

	var count := UserData.get_booster_count("hammer")
	if count <= 0:
		if UserData.buy_booster("hammer", 250):
			_show_status("Bought Hammer for 250 🪙!", false, 0.9)
			_refresh_booster_styles()
		else:
			_show_status("Not enough coins! Need 250 🪙.", true, 0.9)
			return

	_set_hammer_mode(true)
	_show_status("Select one orb to break.", false, 0.9)

func _on_undo_pressed() -> void:
	if session_finished or session_paused:
		return
	if not level_session.has_undo_available():
		_show_status("Nothing to undo yet.", true, 0.9)
		return
		
	var count := UserData.get_booster_count("undo")
	if count <= 0:
		if UserData.buy_booster("undo", 200):
			_show_status("Bought Undo for 200 🪙!", false, 0.9)
			_refresh_booster_styles()
		else:
			_show_status("Not enough coins! Need 200 🪙.", true, 0.9)
			return

	if UserData.use_booster("undo"):
		EventBus.booster_activated.emit(GameConstants.BoosterType.UNDO, Vector2i(-1, -1))
		_show_status("Previous state restored.", false, 0.92)
		_refresh_booster_styles()

func _set_hammer_mode(active: bool) -> void:
	hammer_mode = active
	board_visual.set_hammer_targeting(active)
	_refresh_booster_styles()

func _on_dead_board_detected(_payload: Dictionary) -> void:
	_show_status("No valid moves. Stabilizing board...", true, 0.96)

func _on_auto_shuffle_applied(_payload: Dictionary) -> void:
	board_visual.refresh()
	_show_status("Fresh pattern generated.", false, 0.92)

func _on_undo_used(_payload: Dictionary) -> void:
	board_visual.refresh()
	board_visual.clear_hints()
	_refresh_undo_button()

func _render_goals() -> void:
	for child in mission_goals.get_children():
		child.queue_free()

	if current_goals.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No mission loaded"
		empty_label.add_theme_font_size_override("font_size", _ti("shared.font.body", 16))
		empty_label.add_theme_color_override("font_color", _tc("gameplay.text.caption", "dark_blur"))
		mission_goals.add_child(empty_label)
		return

	for goal in current_goals:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 64)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.set("theme_override_styles/panel", _style("gameplay.surface.mission_chip"))

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", _ti("shared.spacing.sm", 8))
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
		title.add_theme_font_size_override("font_size", _ti("shared.font.caption", 13))
		title.add_theme_color_override("font_color", _tc("gameplay.text.caption", "dark_blur"))
		text_column.add_child(title)

		var count := Label.new()
		count.text = _goal_progress_text(goal)
		count.add_theme_font_size_override("font_size", _ti("shared.font.subtitle", 18))
		var goal_color := _tc("shared.colors.accent_secondary", "accent") if goal.get("completed", false) else _tc("gameplay.text.metric_primary", "dark_blur")
		count.add_theme_color_override("font_color", goal_color)
		text_column.add_child(count)

		mission_goals.add_child(chip)

func _update_progress() -> void:
	var relevant_goals: Array[Dictionary] = []
	for goal in current_goals:
		if int(goal.get("type", GameConstants.GoalType.SCORE)) != GameConstants.GoalType.SCORE:
			relevant_goals.append(goal)

	if relevant_goals.is_empty():
		relevant_goals = current_goals.duplicate(true)

	var total_ratio: float = 0.0
	for goal in relevant_goals:
		var target: int = max(int(goal.get("target", 0)), 1)
		var current: int = int(goal.get("current", 0))
		total_ratio += clamp(float(current) / float(target), 0.0, 1.0)

	var progress: float = 0.0
	if not relevant_goals.is_empty():
		progress = total_ratio / float(relevant_goals.size())

	progress_bar.value = progress * 100.0

func _update_star_row(stars: int) -> void:
	if stars > current_stars:
		_play_star_unlock()
		SoundManager.play("confirm_star")
	current_stars = stars

	for index in range(star_labels.size()):
		var label := star_labels[index]
		var unlocked := index < stars
		label.add_theme_color_override("font_color", _tc("shared.colors.accent_gold", "gold") if unlocked else _with_alpha(_tc("shared.colors.text_muted", "dark_blur"), 0.70))
		label.scale = Vector2.ONE if unlocked else Vector2.ONE * 0.92

func _play_star_unlock() -> void:
	if star_tween != null:
		star_tween.kill()
	star_tween = create_tween()
	for label in star_labels:
		star_tween.tween_property(label, "scale", Vector2.ONE * 1.08, 0.12)
		star_tween.tween_property(label, "scale", Vector2.ONE, 0.16)

func _show_status(message: String, is_error: bool = false, alpha: float = 0.9) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", _tc("gameplay.text.status_error", "accent") if is_error else _tc("gameplay.text.status", "dark_blur"))
	if status_tween != null:
		status_tween.kill()
	status_label.modulate.a = alpha
	status_tween = create_tween()
	status_tween.tween_property(status_label, "modulate:a", alpha, 0.05)
	status_tween.tween_interval(1.4)
	status_tween.tween_property(status_label, "modulate:a", 0.0, 0.4)

func _apply_theme() -> void:
	var glass_style: StyleBoxFlat = _style("gameplay.surface.hud")
	var board_style: StyleBoxFlat = _style("gameplay.surface.board")
	var moves_style: StyleBoxFlat = _style("gameplay.surface.kpi_primary")
	var score_style: StyleBoxFlat = _style("gameplay.surface.kpi_secondary")
	var booster_bar_style: StyleBoxFlat = _style("gameplay.surface.hud")

	$HUD/TopBar/Layout/LevelPanel.set("theme_override_styles/panel", glass_style)
	$HUD/TopBar/Layout/MissionPanel.set("theme_override_styles/panel", glass_style)
	moves_panel.set("theme_override_styles/panel", moves_style)
	score_panel.set("theme_override_styles/panel", score_style)
	$BoardArea/BoardFrame.set("theme_override_styles/panel", board_style)
	$HUD/BoosterBar.set("theme_override_styles/panel", booster_bar_style)

	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.set("theme_override_styles/background", _style("gameplay.surface.progress_bg"))
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		_with_alpha(_tc("shared.colors.accent_secondary", "accent"), 0.92),
		_with_alpha(_tc("shared.colors.accent_primary", "accent"), 0.92),
		_with_alpha(_tc("colors.accent", "accent"), 0.92),
		_with_alpha(_tc("shared.colors.accent_gold", "gold"), 0.92)
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
	progress_bar.set("theme_override_styles/fill", fill_style)

	_set_label_style(world_title, _ti("shared.font.title", 24), _tc("gameplay.text.title", "dark_blur"))
	world_title.add_theme_color_override("font_outline_color", _with_alpha(_tc("shared.colors.accent_primary", "accent"), 0.35))
	world_title.add_theme_constant_override("outline_size", 4)
	_set_label_style(level_subtitle, _ti("shared.font.caption", 13), _tc("gameplay.text.subtitle", "dark_blur"))
	_set_label_style($HUD/TopBar/Layout/MissionPanel/Content/Title, _ti("shared.font.caption", 13), _tc("gameplay.text.caption", "dark_blur"))
	_set_label_style($HUD/TopBar/Layout/StatsColumn/MovesPanel/Content/Caption, _ti("shared.font.caption", 13), _tc("gameplay.text.caption", "dark_blur"))
	_set_label_style($HUD/TopBar/Layout/StatsColumn/ScorePanel/Content/Caption, _ti("shared.font.caption", 13), _tc("gameplay.text.caption", "dark_blur"))
	_set_label_style(moves_value, 30, _tc("gameplay.text.metric_primary", "dark_blur"))
	_set_label_style(score_value, 24, _tc("gameplay.text.metric_secondary", "dark_blur"))
	_set_label_style(status_label, _ti("shared.font.body", 16), _tc("gameplay.text.status", "dark_blur"))

	for star in star_labels:
		star.text = "★"
		star.add_theme_font_size_override("font_size", 28)

	if pause_button != null:
		_style_booster_button(pause_button, _tc("shared.colors.accent_gold", "gold"), false)
		pause_button.add_theme_font_size_override("font_size", 18)

	if overlay_card != null:
		overlay_card.set("theme_override_styles/panel", glass_style)
		_set_label_style(overlay_title, 28, _tc("gameplay.text.title", "dark_blur"))
		_set_label_style(overlay_body, 17, _tc("gameplay.text.subtitle", "dark_blur"))
		_style_booster_button(overlay_primary_button, _tc("shared.colors.accent_primary", "accent"), false)
		_style_booster_button(overlay_secondary_button, _tc("shared.colors.accent_secondary", "accent"), false)
		_style_booster_button(overlay_tertiary_button, _tc("shared.colors.accent_gold", "gold"), false)
		_style_booster_button(overlay_quality_button, _tc("shared.colors.accent_gold", "gold"), false)
		_style_booster_button(overlay_export_button, _tc("shared.colors.accent_secondary", "accent"), false)
		_style_booster_button(overlay_feedback_button, _tc("colors.accent", "accent"), false)

	_refresh_booster_styles()

func _refresh_booster_styles() -> void:
	var shuffles := UserData.get_booster_count("shuffle")
	var hammers := UserData.get_booster_count("hammer")
	var undos := UserData.get_booster_count("undo")

	shuffle_button.text = "✦ Shuffle (%d)" % shuffles if shuffles > 0 else "✦ Shuffle\n(150 🪙)"
	hammer_button.text = "⚒ Hammer (%d)" % hammers if hammers > 0 else "⚒ Hammer\n(250 🪙)"
	undo_button.text = "↺ Undo (%d)" % undos if undos > 0 else "↺ Undo\n(200 🪙)"

	_style_booster_button(shuffle_button, _tc("shared.colors.accent_primary", "accent"), false)
	_style_booster_button(hammer_button, _tc("shared.colors.accent_secondary", "accent"), hammer_mode)
	_style_booster_button(undo_button, _tc("colors.accent", "accent"), false)

func _refresh_undo_button() -> void:
	var available := level_session != null and level_session.has_undo_available() and not session_finished
	undo_button.disabled = not available
	undo_button.tooltip_text = "Restore the previous board state." if available else "Make one move or use one booster first."
	if is_node_ready():
		_refresh_booster_styles()

func _style_booster_button(button: Button, accent: Color, active: bool) -> void:
	var normal := _style("gameplay.button.normal").duplicate() as StyleBoxFlat
	var hover := _style("gameplay.button.hover").duplicate() as StyleBoxFlat
	var pressed := _style("gameplay.button.pressed").duplicate() as StyleBoxFlat
	var disabled := _style("gameplay.button.disabled").duplicate() as StyleBoxFlat

	normal.border_color = accent.lightened(0.12 if active else 0.0)
	hover.border_color = accent.lightened(0.2)
	pressed.border_color = accent
	disabled.border_color = _with_alpha(_tc("shared.colors.text_muted", "dark_blur"), 0.35)
	if active:
		normal.bg_color = _with_alpha(normal.bg_color, min(normal.bg_color.a + 0.12, 1.0))

	button.set("theme_override_styles/normal", normal)
	button.set("theme_override_styles/hover", hover)
	button.set("theme_override_styles/pressed", pressed)
	button.set("theme_override_styles/disabled", disabled)
	button.set("theme_override_styles/focus", pressed)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", _with_alpha(_tc("shared.colors.text_muted", "dark_blur"), 0.8) if button.disabled else _tc("shared.colors.text_primary", "dark_blur"))
	button.add_theme_color_override("font_hover_color", _tc("shared.colors.text_primary", "dark_blur"))
	button.add_theme_color_override("font_pressed_color", _tc("shared.colors.text_primary", "dark_blur"))

# Legacy panel style (for overlays and backward compatibility)
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
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = _with_alpha(_tc("shared.colors.shadow", "dark_blur"), 0.8)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	return style

# Premium Opal Glass panel style — frosted translucent white with iridescent chromatic shadow
func _make_opal_panel(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	
	style.shadow_color = _tc("shared.colors.shadow", "dark_blur")
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 6)
	
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	return style


func _set_label_style(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)

func _goal_icon(goal: Dictionary) -> String:
	match int(goal.get("type", GameConstants.GoalType.SCORE)):
		GameConstants.GoalType.SCORE:
			return "★"
		GameConstants.GoalType.COLLECT_GEM:
			match int(goal.get("gem_type", 0)):
				0:
					return "✦"
				1:
					return "◎"
				2:
					return "≈"
				3:
					return "◉"
				4:
					return "≋"
				_:
					return "◌"
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
		0:
			return _tc("colors.accent", "accent")
		1:
			return _with_alpha(_tc("shared.colors.accent_primary", "accent"), 0.75)
		2:
			return _tc("shared.colors.accent_primary", "accent")
		3:
			return _tc("colors.accent", "accent")
		4:
			return _tc("shared.colors.accent_secondary", "accent")
		5:
			return _with_alpha(_tc("shared.colors.accent_secondary", "accent"), 0.7)
		_:
			return _tc("shared.colors.accent_gold", "gold")

func _gem_name(gem_type: int) -> String:
	match gem_type:
		0:
			return "Star Dust"
		1:
			return "Pearl Ring"
		2:
			return "Cyan Flow"
		3:
			return "Pulse Core"
		4:
			return "Mint Lines"
		5:
			return "Bubble Spark"
		_:
			return "Collect"

func _format_int(value: int) -> String:
	var negative := value < 0
	var digits := str(abs(value))
	var chunks: Array[String] = []
	while digits.length() > 3:
		chunks.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	chunks.push_front(digits)
	var result := ",".join(chunks)
	return "-" + result if negative else result

func _get_quality_profile() -> Dictionary:
	var profile_name := UserData.quality_profile
	var profiles: Dictionary = soft_launch_config.get("quality_profiles", {})
	if profiles.has(profile_name):
		return profiles[profile_name]
	var fallback_name := String(soft_launch_config.get("default_quality_profile", "web_default"))
	return profiles.get(fallback_name, {})

func _build_runtime_overlay() -> void:
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(120, 52)
	pause_button.anchor_left = 1.0
	pause_button.anchor_top = 0.05
	pause_button.anchor_right = 1.0
	pause_button.anchor_bottom = 0.05
	pause_button.offset_left = -150.0
	pause_button.offset_top = 0.0
	pause_button.offset_right = -30.0
	pause_button.offset_bottom = 52.0
	pause_button.pressed.connect(_on_pause_pressed)
	$HUD.add_child(pause_button)

	overlay_layer = Control.new()
	overlay_layer.visible = false
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay_layer)

	var overlay_dim := ColorRect.new()
	overlay_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_dim.color = Color(0.07, 0.08, 0.12, 0.58)
	overlay_layer.add_child(overlay_dim)

	overlay_card = PanelContainer.new()
	overlay_card.custom_minimum_size = Vector2(420, 0)
	overlay_card.anchor_left = 0.5
	overlay_card.anchor_top = 0.5
	overlay_card.anchor_right = 0.5
	overlay_card.anchor_bottom = 0.5
	overlay_card.offset_left = -210.0
	overlay_card.offset_top = -320.0
	overlay_card.offset_right = 210.0
	overlay_card.offset_bottom = 320.0
	overlay_layer.add_child(overlay_card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	overlay_card.add_child(content)

	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(overlay_title)

	overlay_body = Label.new()
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(overlay_body)

	overlay_primary_button = Button.new()
	overlay_secondary_button = Button.new()
	overlay_tertiary_button = Button.new()
	overlay_quality_button = Button.new()
	overlay_export_button = Button.new()
	overlay_feedback_button = Button.new()
	
	for button in [overlay_primary_button, overlay_secondary_button, overlay_tertiary_button, overlay_quality_button, overlay_export_button, overlay_feedback_button]:
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(button)

	overlay_primary_button.pressed.connect(_on_overlay_primary_pressed)
	overlay_secondary_button.pressed.connect(_on_overlay_secondary_pressed)
	overlay_tertiary_button.pressed.connect(_on_overlay_tertiary_pressed)
	overlay_quality_button.pressed.connect(_on_overlay_quality_toggled)
	overlay_export_button.pressed.connect(_on_overlay_export_pressed)
	overlay_feedback_button.pressed.connect(_show_feedback_modal)

func _on_pause_pressed() -> void:
	if session_finished:
		return
	if session_paused:
		_resume_session()
	else:
		_pause_session()

func _pause_session() -> void:
	session_paused = true
	board_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.game_paused.emit()
	_open_overlay(
		"pause",
		"Paused",
		"Progress is safe. %s" % _build_retention_line(),
		"Resume",
		"Retry",
		"Level Select"
	)

func _resume_session() -> void:
	session_paused = false
	if not session_finished:
		board_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.game_resumed.emit()
	_hide_overlay()

func _show_result_overlay(result: Dictionary) -> void:
	var body := ""
	if result.get("won", false):
		body = "Score %s • %d stars.\n%s" % [
			_format_int(int(result.get("score", 0))),
			int(result.get("stars", 0)),
			_build_retention_line(),
		]
		var primary_label := "Next Level" if LevelLoader.level_exists(level_session.level_number + 1) else "Level Select"
		_open_overlay("win", "Level Complete", body, primary_label, "Replay", "Level Select")
	else:
		body = "No moves left.\n%s" % _build_retention_line()
		_open_overlay("lose", "Try Again", body, "Retry", "Level Select", "")

func _open_overlay(mode: String, title: String, body: String, primary_text: String, secondary_text: String, tertiary_text: String) -> void:
	overlay_mode = mode
	overlay_title.text = title
	overlay_body.text = body
	overlay_primary_button.text = primary_text
	overlay_secondary_button.text = secondary_text
	overlay_tertiary_button.text = tertiary_text
	overlay_tertiary_button.visible = not tertiary_text.is_empty()
	
	overlay_feedback_button.visible = (mode == "win" or mode == "lose")
	overlay_quality_button.visible = (mode == "pause")
	overlay_export_button.visible = (mode == "pause")
	if mode == "pause":
		_update_overlay_quality_label()
		
	overlay_layer.visible = true
	pause_button.text = "Resume" if mode == "pause" else "Pause"

func _hide_overlay() -> void:
	overlay_mode = ""
	overlay_layer.visible = false
	pause_button.text = "Pause"

func _on_overlay_primary_pressed() -> void:
	match overlay_mode:
		"pause":
			_resume_session()
		"win":
			if LevelLoader.level_exists(level_session.level_number + 1):
				UserData.set_active_level(level_session.level_number + 1)
				get_tree().change_scene_to_file("res://scenes/gameplay/gameplay.tscn")
			else:
				_go_to_level_select()
		"lose":
			_retry_level()

func _on_overlay_secondary_pressed() -> void:
	match overlay_mode:
		"pause":
			_retry_level()
		"win":
			_retry_level()
		"lose":
			_go_to_level_select()

func _on_overlay_tertiary_pressed() -> void:
	if overlay_mode == "pause" or overlay_mode == "win":
		_go_to_level_select()

func _retry_level() -> void:
	UserData.record_retry(level_session.level_number)
	EventBus.analytics_event_requested.emit("level_retry_requested", {
		"level_id": level_session.level_number,
	})
	get_tree().change_scene_to_file("res://scenes/gameplay/gameplay.tscn")

func _go_to_level_select() -> void:
	EventBus.analytics_event_requested.emit("return_to_level_select", {
		"level_id": level_session.level_number,
	})
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")

func _build_retention_line() -> String:
	var summary := UserData.get_retention_summary()
	return "Streak %d day(s) • %d levels cleared • %d 🪙" % [
		int(summary.get("daily_streak", 0)),
		int(summary.get("completed_levels", 0)),
		UserData.coins
	]

func _on_overlay_quality_toggled() -> void:
	SoundManager.play("tap")
	if UserData.quality_profile == "web_default":
		UserData.quality_profile = "android_safe"
	else:
		UserData.quality_profile = "web_default"
	UserData.save_data()
	
	quality_profile = _get_quality_profile()
	board_visual.set_quality_profile(quality_profile)
	queue_redraw()
	
	_update_overlay_quality_label()

func _update_overlay_quality_label() -> void:
	if overlay_quality_button:
		overlay_quality_button.text = "Quality: Web High (Glow)" if UserData.quality_profile == "web_default" else "Quality: Mobile Safe (72% Glow)"

func _on_overlay_export_pressed() -> void:
	SoundManager.play("tap")
	var json_logs := UserData.get_formatted_test_logs()
	DisplayServer.clipboard_set(json_logs)
	_spawn_toast("Logs copied to clipboard!")

func _show_feedback_modal() -> void:
	SoundManager.play("open")
	var modal_instance = load("res://scenes/menus/feedback_modal.tscn").instantiate()
	add_child(modal_instance)
	modal_instance.setup(level_session.level_number)

func _spawn_toast(msg: String) -> void:
	var toast_scene = load("res://scenes/menus/toast_notification.tscn")
	if toast_scene:
		var toast = toast_scene.instantiate()
		add_child(toast)
		if toast.has_method("show_message"):
			toast.show_message(msg)

# ──────────────────────────────────────────────
# CFE Dynamic UI and Event handlers
# ──────────────────────────────────────────────
var combo_ring: ComboWindowRing
var fever_overlay: FeverOverlay

func _initialize_cfe_ui() -> void:
	if not level_session.fever_mode_enabled:
		return
		
	# Создаем кольцо комбо
	combo_ring = ComboWindowRing.new()
	var parent_node: Node = null
	if has_node("BoardContainer"):
		parent_node = get_node("BoardContainer")
	else:
		parent_node = board_visual
		
	if parent_node:
		parent_node.add_child(combo_ring)
	combo_ring.size = board_visual.size # синхронизируем размер
	
	# Создаем полноэкранный Fever Overlay
	fever_overlay = FeverOverlay.new()
	add_child(fever_overlay)
	fever_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Подключаем сигналы EventBus
	EventBus.combo_window_opened.connect(func(duration: float): combo_ring.setup_combo(duration))
	EventBus.combo_window_updated.connect(func(rem: float, chain: int): combo_ring.update_combo(rem, chain))
	EventBus.combo_expired.connect(func(): combo_ring.expire())
	EventBus.fever_activated.connect(func(dur: float, mult: float): fever_overlay.activate(dur))
	EventBus.fever_expired.connect(func(): fever_overlay.deactivate())

func _on_board_visual_animations_finished() -> void:
	if level_session.fever_mode_enabled:
		level_session._advance_cfe_pipeline()
