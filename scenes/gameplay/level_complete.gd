extends Control

const ActionRegistry = preload("res://scripts/ui/ui_action_registry.gd")

signal next_level_requested
signal share_requested
signal home_requested

@onready var glass_panel: PanelContainer = $GlassPanel
@onready var title_label: Label = $GlassPanel/VBoxContainer/TitleLabel
@onready var stars_container: HBoxContainer = $GlassPanel/VBoxContainer/StarsContainer
@onready var star1: Label = $GlassPanel/VBoxContainer/StarsContainer/Star1
@onready var star2: Label = $GlassPanel/VBoxContainer/StarsContainer/Star2
@onready var star3: Label = $GlassPanel/VBoxContainer/StarsContainer/Star3

@onready var score_value: Label = $GlassPanel/VBoxContainer/ScoreSection/ScoreValue
@onready var best_value: Label = $GlassPanel/VBoxContainer/ScoreSection/BestValue
@onready var new_best_badge: PanelContainer = $GlassPanel/VBoxContainer/ScoreSection/NewBestBadge

@onready var coins_amount: Label = $GlassPanel/VBoxContainer/RewardsSection/CoinsPill/CoinsAmount
@onready var stars_amount: Label = $GlassPanel/VBoxContainer/RewardsSection/StarsPill/StarsAmount

@onready var next_button: Button = $GlassPanel/VBoxContainer/NextButton
@onready var share_button: Button = $GlassPanel/VBoxContainer/ShareButton
@onready var home_button: Button = $GlassPanel/VBoxContainer/HomeButton

var COLOR_TEXT_PRIMARY := Color("#312D47")
var COLOR_TEXT_MUTED := Color("#6D678A")
var COLOR_GLASS_BG := Color(1.0, 1.0, 1.0, 0.45)
var COLOR_GLASS_BORDER := Color(1.0, 1.0, 1.0, 0.72)
var COLOR_ACCENT_PRIMARY := Color("#8D7AF8")
var COLOR_ACCENT_SECONDARY := Color("#73CDBA")
var COLOR_ACCENT_GOLD := Color("#E7B446")

var target_score: int = 0
var current_anim_score: float = 0.0
var score_counting: bool = false

func setup_data(result: Dictionary) -> void:
	target_score = int(result.get("score", 0))
	var stars: int = int(result.get("stars", 0))
	var level_id: int = int(result.get("level_id", 0))
	var is_new_best: bool = bool(result.get("is_new_best", false))
	var coins_won: int = int(result.get("coins_won", 250))
	var stars_won: int = int(result.get("stars_won", 3))

	best_value.text = "Best Score: %s" % _format_int(int(result.get("best_score", target_score)))
	new_best_badge.visible = is_new_best
	
	coins_amount.text = str(coins_won)
	stars_amount.text = str(stars_won)
	
	# Clean star states
	star1.modulate = Color(1, 1, 1, 0.22)
	star2.modulate = Color(1, 1, 1, 0.22)
	star3.modulate = Color(1, 1, 1, 0.22)

	_animate_stars(stars)
	_start_score_rollup()

func _ready() -> void:
	_refresh_theme()
	_apply_styles()
	_setup_button_juice()
	_animate_entrance()

	# Action bindings
	ActionRegistry.bind(next_button, &"game.next_level", func(): next_level_requested.emit())
	ActionRegistry.bind(share_button, &"game.share", func(): share_requested.emit())
	ActionRegistry.bind(home_button, &"game.home", func(): home_requested.emit())

func _process(delta: float) -> void:
	if score_counting:
		current_anim_score = move_toward(current_anim_score, target_score, maxf(1.0, float(target_score) * 2.5 * delta))
		score_value.text = _format_int(int(current_anim_score))
		if int(current_anim_score) == target_score:
			score_counting = false
			SoundManager.play("win")

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
	
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	
	score_value.add_theme_font_size_override("font_size", 48)
	score_value.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	
	best_value.add_theme_font_size_override("font_size", 16)
	best_value.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

	$GlassPanel/VBoxContainer/RewardsSection/CoinsPill.set("theme_override_styles/panel", _make_pill_style(18, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	$GlassPanel/VBoxContainer/RewardsSection/StarsPill.set("theme_override_styles/panel", _make_pill_style(18, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	
	new_best_badge.set("theme_override_styles/panel", _make_pill_style(12, COLOR_ACCENT_PRIMARY.lightened(0.1), COLOR_GLASS_BORDER))
	$GlassPanel/VBoxContainer/ScoreSection/NewBestBadge/Label.add_theme_color_override("font_color", Color.WHITE)

	# Style buttons
	_style_button(next_button, COLOR_ACCENT_PRIMARY)
	_style_button(share_button, COLOR_ACCENT_SECONDARY)
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
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s

func _animate_stars(count: int) -> void:
	var stars: Array[Label] = [star1, star2, star3]
	for index in range(count):
		var star = stars[index]
		var star_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		star_tween.tween_interval(0.35 + float(index) * 0.28)
		star_tween.tween_property(star, "modulate", COLOR_ACCENT_GOLD, 0.42)
		star_tween.parallel().tween_property(star, "scale", Vector2(1.35, 1.35), 0.2)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.18)

func _start_score_rollup() -> void:
	current_anim_score = 0.0
	score_counting = true

func _setup_button_juice() -> void:
	var buttons: Array[Button] = [next_button, share_button, home_button]
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
