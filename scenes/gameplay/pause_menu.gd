extends Control

const ActionRegistry = preload("res://scripts/ui/ui_action_registry.gd")

signal resume_requested
signal restart_requested
signal home_requested

@onready var glass_panel: PanelContainer = $GlassPanel
@onready var title_label: Label = $GlassPanel/VBoxContainer/TitleLabel
@onready var close_button: Button = $GlassPanel/VBoxContainer/CloseButton
@onready var resume_button: Button = $GlassPanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $GlassPanel/VBoxContainer/RestartButton
@onready var home_button: Button = $GlassPanel/VBoxContainer/HomeButton

@onready var sound_slider: HSlider = $GlassPanel/VBoxContainer/VolumeSection/SoundSlider
@onready var music_slider: HSlider = $GlassPanel/VBoxContainer/VolumeSection/MusicSlider
@onready var haptics_button: Button = $GlassPanel/VBoxContainer/VolumeSection/HapticsButton

var COLOR_TEXT_PRIMARY := Color("#312D47")
var COLOR_TEXT_MUTED := Color("#6D678A")
var COLOR_GLASS_BG := Color(1.0, 1.0, 1.0, 0.45)
var COLOR_GLASS_BORDER := Color(1.0, 1.0, 1.0, 0.72)
var COLOR_ACCENT_PRIMARY := Color("#8D7AF8")
var COLOR_ACCENT_SECONDARY := Color("#73CDBA")
var COLOR_ACCENT_GOLD := Color("#E7B446")

func _ready() -> void:
	_refresh_theme()
	_apply_styles()
	_load_user_settings()
	_setup_button_juice()
	_animate_entrance()

	# Action bindings
	ActionRegistry.bind(resume_button, &"game.resume", func(): resume_requested.emit())
	ActionRegistry.bind(close_button, &"game.resume", func(): resume_requested.emit())
	ActionRegistry.bind(restart_button, &"game.restart", func(): restart_requested.emit())
	ActionRegistry.bind(home_button, &"game.home", func(): home_requested.emit())
	ActionRegistry.bind(haptics_button, &"settings.haptics", _on_haptics_toggled)

	sound_slider.value_changed.connect(_on_sound_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)

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
	# Style the modal panel using ThemeTokens styles
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
		panel_style.content_margin_left = 24
		panel_style.content_margin_top = 24
		panel_style.content_margin_right = 24
		panel_style.content_margin_bottom = 24

	glass_panel.set("theme_override_styles/panel", panel_style)
	
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	
	# Style CTA and Secondary buttons
	_style_button(resume_button, COLOR_ACCENT_PRIMARY)
	_style_button(restart_button, COLOR_ACCENT_SECONDARY)
	_style_button(home_button, COLOR_ACCENT_GOLD)
	_style_button(haptics_button, COLOR_ACCENT_PRIMARY)
	
	# Polish close button
	close_button.set("theme_override_styles/normal", _make_circle_style(COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	close_button.set("theme_override_styles/hover", _make_circle_style(COLOR_GLASS_BG.lightened(0.18), COLOR_ACCENT_PRIMARY))
	close_button.set("theme_override_styles/pressed", _make_circle_style(COLOR_GLASS_BG.darkened(0.08), COLOR_ACCENT_PRIMARY))
	close_button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

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
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)

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
	return s

func _make_circle_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := _make_pill_style(99, bg, border)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s

func _load_user_settings() -> void:
	sound_slider.value = UserData.sound_volume
	music_slider.value = UserData.music_volume
	_update_haptics_label()

func _on_sound_volume_changed(value: float) -> void:
	UserData.sound_volume = value
	UserData.sound_enabled = value > 0.0
	UserData.save_data()

func _on_music_volume_changed(value: float) -> void:
	UserData.music_volume = value
	UserData.music_enabled = value > 0.0
	UserData.save_data()

func _on_haptics_toggled() -> void:
	SoundManager.play("tap")
	UserData.haptics_enabled = not UserData.haptics_enabled
	UserData.save_data()
	_update_haptics_label()

func _update_haptics_label() -> void:
	haptics_button.text = "Haptics: ON" if UserData.haptics_enabled else "Haptics: OFF"

func _setup_button_juice() -> void:
	var buttons: Array[Button] = [resume_button, restart_button, home_button, haptics_button, close_button]
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
	glass_panel.pivot_offset = Vector2(210, 380) # Center of the panel
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glass_panel, "scale", Vector2.ONE, 0.28)
	tween.tween_property(glass_panel, "modulate:a", 1.0, 0.22)

func _draw() -> void:
	# Horizontal soft-highlight divider line
	var sep_y := 240.0
	draw_line(Vector2(24, sep_y), Vector2(size.x - 24, sep_y), COLOR_GLASS_BORDER, 1.5)
