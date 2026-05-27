extends Control

const ActionRegistry = preload("res://scripts/ui/ui_action_registry.gd")

signal retry_requested
signal add_moves_requested
signal home_requested

@onready var glass_panel: PanelContainer = $GlassPanel
@onready var title_label: Label = $GlassPanel/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $GlassPanel/VBoxContainer/SubtitleLabel
@onready var sad_star_icon: Label = $GlassPanel/VBoxContainer/SadStarIcon
@onready var targets_container: VBoxContainer = $GlassPanel/VBoxContainer/TargetsContainer

@onready var retry_button: Button = $GlassPanel/VBoxContainer/RetryButton
@onready var add_moves_button: Button = $GlassPanel/VBoxContainer/AddMovesButton
@onready var home_button: Button = $GlassPanel/VBoxContainer/HomeButton

var COLOR_TEXT_PRIMARY := Color("#312D47")
var COLOR_TEXT_MUTED := Color("#6D678A")
var COLOR_GLASS_BG := Color(1.0, 1.0, 1.0, 0.45)
var COLOR_GLASS_BORDER := Color(1.0, 1.0, 1.0, 0.72)
var COLOR_ACCENT_PRIMARY := Color("#8D7AF8")
var COLOR_ACCENT_SECONDARY := Color("#73CDBA")
var COLOR_ACCENT_GOLD := Color("#E7B446")

var cost_for_moves: int = 900
var float_time: float = 0.0

func setup_data(goals: Array[Dictionary], extra_moves_cost: int) -> void:
	cost_for_moves = extra_moves_cost
	add_moves_button.text = "Add 5 Moves (🪙 %d)" % cost_for_moves
	
	# Clear previous targets
	for child in targets_container.get_children():
		child.queue_free()
		
	# Populate target rows with checkboxes
	for goal in goals:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		
		var icon := Label.new()
		var type_idx: int = int(goal.get("type", 0))
		icon.text = _sphere_icon_for_type(type_idx)
		icon.add_theme_font_size_override("font_size", 18)
		row.add_child(icon)
		
		var label := Label.new()
		var remaining: int = int(goal.get("remaining", 0))
		if remaining <= 0:
			label.text = "Collected!"
			label.add_theme_color_override("font_color", Color("#73CDBA")) # Mint green
			
			var check := Label.new()
			check.text = "✓"
			check.add_theme_color_override("font_color", Color("#73CDBA"))
			check.add_theme_font_size_override("font_size", 16)
			row.add_child(check)
		else:
			label.text = "Need: %d more" % remaining
			label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
			
			var count_lbl := Label.new()
			count_lbl.text = "⏳"
			count_lbl.add_theme_font_size_override("font_size", 14)
			row.add_child(count_lbl)
			
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)
		targets_container.add_child(row)

func _ready() -> void:
	_refresh_theme()
	_apply_styles()
	_setup_button_juice()
	_animate_entrance()

	# Action bindings
	ActionRegistry.bind(retry_button, &"game.restart", func(): retry_requested.emit())
	ActionRegistry.bind(add_moves_button, &"game.add_moves", func(): add_moves_requested.emit())
	ActionRegistry.bind(home_button, &"game.home", func(): home_requested.emit())

func _process(delta: float) -> void:
	# Keep the sad star floating gently
	float_time += delta * 2.2
	sad_star_icon.position.y = 80.0 + sin(float_time) * 6.0

func _theme_tokens() -> Node:
	return get_tree().root.get_node_or_null("ThemeTokensAutoload")

func _refresh_theme() -> void:
	var tokens := _theme_tokens()
	if tokens != null:
		COLOR_TEXT_PRIMARY = tokens.color_path("shared.colors.text_primary", COLOR_TEXT_PRIMARY)
		COLOR_TEXT_MUTED = tokens.color_path("shared.colors.text_muted", COLOR_TEXT_MUTED)
		COLOR_GLASS_BG = tokens.color_path("shared.colors.glass_bg", COLOR_GLASS_BG)
		COLOR_GLASS_BORDER = tokens.color_path("shared.colors.glass_border", COLOR_GLASS_BORDER)
		COLOR_ACCENT_PRIMARY = tokens.color_path("shared.colors.accent_primary", COLOR_ACCENT_PRIMARY)
		COLOR_ACCENT_SECONDARY = tokens.color_path("shared.colors.accent_secondary", COLOR_ACCENT_SECONDARY)
		COLOR_ACCENT_GOLD = tokens.color_path("shared.colors.accent_gold", COLOR_ACCENT_GOLD)

func _apply_styles() -> void:
	var tokens := _theme_tokens()
	var panel_style: StyleBoxFlat
	if tokens != null and tokens.has_method("make_panel_style"):
		panel_style = tokens.make_panel_style("gameplay.surface.hud")
	else:
		panel_style = StyleBoxFlat.new()
		panel_style.bg_color = COLOR_GLASS_BG
		panel_style.border_color = COLOR_GLASS_BORDER
		panel_style.border_width_left = 2
		panel_style.border_width_right = 2
		panel_style.border_width_top = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 32
		panel_style.corner_radius_top_right = 32
		panel_style.corner_radius_bottom_left = 32
		panel_style.corner_radius_bottom_right = 32
		panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
		panel_style.shadow_size = 28
		panel_style.shadow_offset = Vector2(0, 8)

	glass_panel.set("theme_override_styles/panel", panel_style)
	
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	
	sad_star_icon.add_theme_font_size_override("font_size", 54)
	sad_star_icon.add_theme_color_override("font_color", COLOR_TEXT_MUTED.lightened(0.12))

	targets_container.set("theme_override_styles/panel", _make_pill_style(20, COLOR_GLASS_BG, COLOR_GLASS_BORDER))

	# Style buttons
	_style_button(retry_button, COLOR_ACCENT_PRIMARY)
	_style_button(add_moves_button, COLOR_ACCENT_SECONDARY)
	_style_button(home_button, COLOR_ACCENT_GOLD)

func _style_button(btn: Button, accent: Color) -> void:
	var tokens := _theme_tokens()
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	
	if tokens != null and tokens.has_method("make_button_style"):
		normal = tokens.make_button_style("gameplay.button", "normal")
		hover = tokens.make_button_style("gameplay.button", "hover")
		pressed = tokens.make_button_style("gameplay.button", "pressed")
	else:
		normal = _make_pill_style(24, COLOR_GLASS_BG, COLOR_GLASS_BORDER)
		hover = _make_pill_style(24, COLOR_GLASS_BG.lightened(0.15), accent)
		pressed = _make_pill_style(24, COLOR_GLASS_BG.darkened(0.08), accent)

	normal.border_color = accent
	btn.set("theme_override_styles/normal", normal)
	btn.set("theme_override_styles/hover", hover)
	btn.set("theme_override_styles/pressed", pressed)
	btn.set("theme_override_styles/focus", pressed)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

func _make_pill_style(radius: int, bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.content_margin_left = 14
	s.content_margin_right = 14
	return s

func _sphere_icon_for_type(type: int) -> String:
	return {
		0: "🔵", # Frost
		1: "⚪", # Glass
		2: "🔵", # Aqua
		3: "🟣", # Violet
		4: "🟡", # Warm
	}.get(type, "🔮")

func _setup_button_juice() -> void:
	var buttons: Array[Button] = [retry_button, add_moves_button, home_button]
	for btn: Button in buttons:
		btn.pivot_offset = btn.custom_minimum_size * 0.5
		if not btn.is_node_ready():
			btn.ready.connect(func(): btn.pivot_offset = btn.size * 0.5)
		btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
		
		btn.mouse_entered.connect(func():
			var tween: Tween = btn.create_tween()
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			var tween: Tween = btn.create_tween()
			tween.tween_property(btn, "scale", Vector2.ONE, 0.12)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		btn.button_down.connect(func():
			var tween: Tween = btn.create_tween()
			tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		btn.button_up.connect(func():
			var tween: Tween = btn.create_tween()
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)

func _animate_entrance() -> void:
	glass_panel.scale = Vector2(0.92, 0.92)
	glass_panel.modulate.a = 0.0
	glass_panel.pivot_offset = Vector2(210, 380)
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glass_panel, "scale", Vector2.ONE, 0.28)
	tween.tween_property(glass_panel, "modulate:a", 1.0, 0.22)
