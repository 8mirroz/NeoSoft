## Gameplay — основная игровая сцена (Composition Root)
## Управляет жизненным циклом сцены и делегирует задачи специализированным подсистемам
extends Control

const WORLD_NAME := "Neo Soft Frost"
const ActionRegistry := preload("res://scripts/ui/ui_action_registry.gd")

const GameplayNodeRefsScript = preload("res://scenes/gameplay/contracts/gameplay_node_refs.gd")
const GameplaySceneContractScript = preload("res://scenes/gameplay/contracts/gameplay_scene_contract.gd")
const GameplayHUDPresenterScript = preload("res://scenes/gameplay/presenters/gameplay_hud_presenter.gd")
const GameplayOverlayControllerScript = preload("res://scenes/gameplay/presenters/gameplay_overlay_controller.gd")
const GameplayInputRouterScript = preload("res://scenes/gameplay/controllers/gameplay_input_router.gd")
const GameplayBoosterControllerScript = preload("res://scenes/gameplay/controllers/gameplay_booster_controller.gd")
const GameplayCFEControllerScript = preload("res://scenes/gameplay/controllers/gameplay_cfe_controller.gd")
const GameplayBackgroundFXScript = preload("res://scenes/gameplay/fx/gameplay_background_fx.gd")
const GameplayTelemetryAdapterScript = preload("res://scenes/gameplay/telemetry/gameplay_telemetry_adapter.gd")

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

# State variables accessible by controllers
var current_goals: Array[Dictionary] = []
var current_stars: int = 0
var hammer_mode: bool = false
var session_finished: bool = false
var session_paused: bool = false
var soft_launch_config: Dictionary = {}
var quality_profile: Dictionary = {}
var status_tween: Tween
var star_tween: Tween
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
var overlay_sound_label: Label
var overlay_sound_slider: HSlider
var overlay_music_label: Label
var overlay_music_slider: HSlider
var overlay_haptics_button: Button

# Subsystem instances
var refs: RefCounted
var scene_contract: RefCounted
var hud: RefCounted
var overlay: RefCounted
var input_router: RefCounted
var boosters: RefCounted
var cfe: RefCounted
var background_fx: Control
var telemetry: RefCounted

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
	
	# Instantiate and wire modular subsystems
	refs = GameplayNodeRefsScript.from_scene(self)
	scene_contract = GameplaySceneContractScript.new(refs)
	scene_contract.validate_or_fail()
	
	background_fx = GameplayBackgroundFXScript.new()
	background_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_fx)
	move_child(background_fx, 0)
	background_fx.setup(self)
	background_fx.apply_quality_profile(quality_profile)
	
	hud = GameplayHUDPresenterScript.new()
	hud.setup(self, refs)
	hud.initialize_hud()
	
	overlay = GameplayOverlayControllerScript.new()
	overlay.setup(self, refs)
	overlay.initialize_overlays()
	
	input_router = GameplayInputRouterScript.new()
	input_router.setup(self, level_session, board_visual)
	
	boosters = GameplayBoosterControllerScript.new()
	boosters.setup(self, level_session, board_visual, refs)
	
	cfe = GameplayCFEControllerScript.new()
	cfe.setup(self, level_session, board_visual)
	cfe.initialize_cfe()
	
	telemetry = GameplayTelemetryAdapterScript.new()
	telemetry.setup()
	
	_connect_events()
	
	# Inject premium button scale & bounce animations
	for btn in [shuffle_button, hammer_button, undo_button, pause_button]:
		_setup_button_juice(btn)

	board_visual.cell_pressed.connect(_on_board_cell_pressed)
	board_visual.animations_finished.connect(_on_board_visual_animations_finished)
	
	# Dynamic action registry binding
	ActionRegistry.bind(shuffle_button, &"game.booster", _on_shuffle_pressed)
	ActionRegistry.bind(hammer_button, &"game.booster", _on_hammer_pressed)
	ActionRegistry.bind(undo_button, &"game.booster", _on_undo_pressed)
	_refresh_undo_button()

	world_title.text = WORLD_NAME
	level_subtitle.text = "Level %02d" % level_session.level_number
	status_label.modulate.a = 0.0

	set_process(true)
	queue_redraw()
	call_deferred("_initialize_presentation")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

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
	elif level_session.board_controller != null:
		board_visual.setup(level_session.board_controller.board)
		board_visual.set_quality_profile(quality_profile)
	
	if level_session != null:
		level_session._emit_status_updates()

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
	if hud != null:
		current_stars = hud.update_score(score, stars, current_stars)

func _on_moves_updated(remaining: int, _used: int) -> void:
	if hud != null:
		hud.update_moves(remaining)

func _on_goals_updated(goals: Array[Dictionary]) -> void:
	current_goals = goals.duplicate(true)
	if hud != null:
		hud.update_goals(goals)
		hud.update_progress(goals)

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
	if board_visual != null and board_visual._has_active_effects():
		return
	if input_router != null:
		input_router.on_cell_pressed(cell)

func _on_board_cell_pressed_hammer_fallback(cell: Vector2i) -> void:
	if boosters != null:
		boosters.apply_hammer_booster(cell)

func _on_shuffle_pressed() -> void:
	if boosters != null:
		boosters.request_shuffle()

func _on_hammer_pressed() -> void:
	if boosters != null:
		boosters.toggle_hammer_mode()

func _on_undo_pressed() -> void:
	if boosters != null:
		boosters.request_undo()

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

func _show_status(message: String, is_error: bool = false, alpha: float = 0.9) -> void:
	if hud != null:
		hud.show_status(message, is_error, alpha)

func _apply_theme() -> void:
	var glass_style := _style("gameplay.surface.hud")
	var board_style := _style("gameplay.surface.board")

	$HUD/TopBar/Layout/LevelPanel.set("theme_override_styles/panel", glass_style)
	$HUD/TopBar/Layout/MissionPanel.set("theme_override_styles/panel", glass_style)
	$BoardArea/BoardFrame.set("theme_override_styles/panel", board_style)
	$HUD/BoosterBar.set("theme_override_styles/panel", glass_style)
	
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
		_style_booster_button(overlay_haptics_button, _tc("shared.colors.accent_secondary", "accent"), false)

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

func _set_label_style(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)

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
	pause_button.custom_minimum_size = Vector2(100, 52)
	pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ActionRegistry.bind(pause_button, &"game.pause", _on_pause_pressed)
	$HUD/TopBar/Layout.add_child(pause_button)

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
		"Home"
	)

func _resume_session() -> void:
	session_paused = false
	if not session_finished:
		board_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.game_resumed.emit()
	_hide_overlay()

func _show_result_overlay(result: Dictionary) -> void:
	overlay_payload = result.duplicate(true)
	var body := ""
	if result.get("won", false):
		body = "Score %s • %d stars.\n%s" % [
			_format_int(int(result.get("score", 0))),
			int(result.get("stars", 0)),
			_build_retention_line(),
		]
		var primary_label := "Next Level" if LevelLoader.level_exists(level_session.level_number + 1) else "World Map"
		_open_overlay("win", "Level Complete", body, primary_label, "Share", "Home")
	else:
		body = "No moves left.\n%s" % _build_retention_line()
		_open_overlay("lose", "Out of Moves", body, "Retry", "Add 5 Moves - %d coins" % UserData.get_extra_moves_cost(), "Home")

func _open_overlay(mode: String, title: String, body: String, primary_text: String, secondary_text: String, tertiary_text: String) -> void:
	if overlay != null:
		overlay.open_overlay(mode, title, body, primary_text, secondary_text, tertiary_text)

func _hide_overlay() -> void:
	if overlay != null:
		overlay.hide_overlay()

func _on_overlay_primary_pressed() -> void:
	match overlay_mode:
		"pause":
			_resume_session()
		"win":
			if LevelLoader.level_exists(level_session.level_number + 1):
				UserData.set_active_level(level_session.level_number + 1)
				UIScreenManager.navigate(&"level_preview", {"level_id": level_session.level_number + 1})
			else:
				_go_to_level_select()
		"lose":
			_retry_level()

func _on_overlay_secondary_pressed() -> void:
	match overlay_mode:
		"pause":
			_retry_level()
		"win":
			_share_result()
		"lose":
			_continue_with_extra_moves()

func _on_overlay_tertiary_pressed() -> void:
	if overlay_mode == "pause" or overlay_mode == "win" or overlay_mode == "lose":
		UIScreenManager.navigate(&"main_menu")

func _retry_level() -> void:
	UserData.record_retry(level_session.level_number)
	EventBus.analytics_event_requested.emit("level_retry_requested", {
		"level_id": level_session.level_number,
	})
	UIScreenManager.navigate(&"gameplay", {"level_id": level_session.level_number})

func _go_to_level_select() -> void:
	EventBus.analytics_event_requested.emit("return_to_level_select", {
		"level_id": level_session.level_number,
	})
	UIScreenManager.navigate(&"world_map")

func _continue_with_extra_moves() -> void:
	if not UserData.buy_extra_moves(level_session.level_number):
		_spawn_toast("Not enough coins for five extra moves.")
		return
	if not level_session.continue_with_extra_moves(5):
		UserData.add_coins(UserData.get_extra_moves_cost())
		_spawn_toast("Unable to resume this level.")
		return
	session_finished = false
	session_paused = false
	board_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	_hide_overlay()
	_refresh_undo_button()
	_show_status("Five moves restored.", false, 1.0)

func _share_result() -> void:
	var message := "Neo Soft Frost - Level %02d: %s points, %d stars." % [
		level_session.level_number,
		_format_int(int(overlay_payload.get("score", 0))),
		int(overlay_payload.get("stars", current_stars)),
	]
	DisplayServer.clipboard_set(message)
	_spawn_toast("Result copied to clipboard.")

func _build_retention_line() -> String:
	if overlay != null:
		return overlay.build_retention_line()
	return ""

func _on_overlay_quality_toggled() -> void:
	SoundManager.play("tap")
	if UserData.quality_profile == "web_default":
		UserData.quality_profile = "android_safe"
	else:
		UserData.quality_profile = "web_default"
	UserData.save_data()
	
	quality_profile = _get_quality_profile()
	board_visual.set_quality_profile(quality_profile)
	if background_fx != null:
		background_fx.apply_quality_profile(quality_profile)
	queue_redraw()
	
	_update_overlay_quality_label()

func _update_overlay_quality_label() -> void:
	if overlay_quality_button:
		overlay_quality_button.text = "Quality: Web High (Glow)" if UserData.quality_profile == "web_default" else "Quality: Mobile Safe (72% Glow)"

func _on_pause_sound_volume_changed(value: float) -> void:
	UserData.sound_volume = value
	UserData.sound_enabled = value > 0.0
	UserData.save_data()

func _on_pause_music_volume_changed(value: float) -> void:
	UserData.music_volume = value
	UserData.music_enabled = value > 0.0
	UserData.save_data()

func _on_pause_haptics_toggled() -> void:
	UserData.haptics_enabled = not UserData.haptics_enabled
	UserData.save_data()
	overlay_haptics_button.text = "Haptics: ON" if UserData.haptics_enabled else "Haptics: OFF"

func _on_overlay_export_pressed() -> void:
	SoundManager.play("tap")
	if overlay_mode == "win":
		_share_result()
		return
	var json_logs := UserData.get_formatted_test_logs()
	DisplayServer.clipboard_set(json_logs)
	_spawn_toast("Logs copied to clipboard!")

func _show_feedback_modal() -> void:
	SoundManager.play("open")
	var modal_instance: Node = load("res://scenes/menus/feedback_modal.tscn").instantiate()
	add_child(modal_instance)
	modal_instance.setup(level_session.level_number)

func _spawn_toast(msg: String) -> void:
	var toast_scene: Resource = load("res://scenes/menus/toast_notification.tscn")
	if toast_scene:
		var toast: Node = toast_scene.instantiate()
		add_child(toast)
		if toast.has_method("show_message"):
			toast.show_message(msg)

func _on_board_visual_animations_finished() -> void:
	if input_router != null:
		input_router.process_pending_queue()
		
	if level_session.fever_mode_enabled:
		level_session.notify_visual_pipeline_ready()

func _setup_button_juice(btn: Button) -> void:
	if btn == null:
		return
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	if not btn.is_node_ready():
		btn.ready.connect(func(): btn.pivot_offset = btn.size * 0.5)
	else:
		btn.pivot_offset = btn.size * 0.5
		
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	
	btn.mouse_entered.connect(func():
		var tween := btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.15)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tween := btn.create_tween()
		tween.tween_property(btn, "scale", Vector2.ONE, 0.15)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		var tween := btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.1)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		var tween := btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
