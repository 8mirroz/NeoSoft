extends Control

const ActionRegistry := preload("res://scripts/ui/ui_action_registry.gd")

# Core UI Nodes
@onready var play_button: Button = $PlayButton
@onready var title_label: Label = $TitleLabel
@onready var orb_container: Control = $OrbContainer
@onready var top_bar: HBoxContainer = $TopBar
@onready var quick_actions: HBoxContainer = $QuickActions
@onready var bottom_nav: HBoxContainer = $BottomNav
@onready var background_gems_container: Control = $BackgroundGems
@onready var foreground_gems_container: Control = $ForegroundGems

# Settings Overlay
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var sound_button: Button = $SettingsOverlay/GlassPanel/VBoxContainer/SoundButton
@onready var music_button: Button = $SettingsOverlay/GlassPanel/VBoxContainer/MusicButton
@onready var close_button: Button = $SettingsOverlay/GlassPanel/VBoxContainer/CloseButton
var quality_button: Button
var export_button: Button
var haptics_button: Button
var sound_slider: HSlider
var music_slider: HSlider

# Dynamic Progress Labels & Pills
var coin_label: Label
var star_label: Label
var subtitle_label: Label

var COLOR_BG_START: Color = Color.WHITE
var COLOR_BG_END: Color = Color.WHITE
var COLOR_TEXT_PRIMARY: Color = Color.WHITE
var COLOR_TEXT_MUTED: Color = Color.WHITE
var COLOR_GLASS_BG: Color = Color.WHITE
var COLOR_GLASS_BORDER: Color = Color.WHITE
var COLOR_GLASS_SHADOW: Color = Color.WHITE
var COLOR_ACCENT_COIN: Color = Color.WHITE
var COLOR_ACCENT_STAR: Color = Color.WHITE
var COLOR_ACCENT_PLAY: Color = Color.WHITE
const ENABLE_AMBIENT_GEMS := true

# Floating Gems properties
class FloatingGem:
	var node: GemView
	var velocity: Vector2
	var spin_speed: float
	var base_pos: Vector2
	var depth: float
	var size_px: float

var floating_gems: Array = []
var cursor_offset: Vector2 = Vector2.ZERO

# Background animation variables
var bg_time: float = 0.0
var hanging_diamonds: Array = []

func _ready() -> void:
	randomize()
	
	# Connect main actions
	ActionRegistry.bind(play_button, &"menu.play", _on_play_pressed)
	ActionRegistry.bind(close_button, &"settings.close", _on_close_pressed)
	ActionRegistry.bind(sound_button, &"settings.sound", _on_sound_toggled)
	ActionRegistry.bind(music_button, &"settings.music", _on_music_toggled)
	
	# Dynamic settings configuration
	var settings_box := $SettingsOverlay/GlassPanel/VBoxContainer
	quality_button = Button.new()
	quality_button.name = "QualityButton"
	quality_button.custom_minimum_size = Vector2(0, 56)
	settings_box.add_child(quality_button)
	settings_box.move_child(quality_button, close_button.get_index())
	ActionRegistry.bind(quality_button, &"settings.quality", _on_quality_toggled)
	
	export_button = Button.new()
	export_button.name = "ExportButton"
	export_button.custom_minimum_size = Vector2(0, 56)
	settings_box.add_child(export_button)
	settings_box.move_child(export_button, close_button.get_index())
	ActionRegistry.bind(export_button, &"settings.export", _on_export_pressed)

	sound_slider = _create_volume_slider("Sound Volume", UserData.sound_volume, &"settings.sound_volume", _on_sound_volume_changed)
	settings_box.add_child(sound_slider)
	settings_box.move_child(sound_slider, close_button.get_index())
	music_slider = _create_volume_slider("Music Volume", UserData.music_volume, &"settings.music_volume", _on_music_volume_changed)
	settings_box.add_child(music_slider)
	settings_box.move_child(music_slider, close_button.get_index())

	haptics_button = Button.new()
	haptics_button.name = "HapticsButton"
	haptics_button.custom_minimum_size = Vector2(0, 54)
	settings_box.add_child(haptics_button)
	settings_box.move_child(haptics_button, close_button.get_index())
	ActionRegistry.bind(haptics_button, &"settings.haptics", _on_haptics_toggled)
	
	# Expand settings panel vertical layout sizes
	$SettingsOverlay/GlassPanel.offset_top = -362.0
	$SettingsOverlay/GlassPanel.offset_bottom = 362.0
	$SettingsOverlay/GlassPanel.pivot_offset = Vector2(220, 362)
	
	# Initialize hanging diamonds configurations
	# {x_ratio, length, size, phase, speed}
	hanging_diamonds = [
		{"x_ratio": 0.08, "length": 250.0, "size": 18.0, "phase": 0.0, "speed": 1.2},
		{"x_ratio": 0.14, "length": 180.0, "size": 14.0, "phase": 1.5, "speed": 1.5},
		{"x_ratio": 0.86, "length": 200.0, "size": 16.0, "phase": 0.7, "speed": 1.3},
		{"x_ratio": 0.92, "length": 280.0, "size": 20.0, "phase": 2.2, "speed": 1.0}
	]
	
	# Prime theme palette before dynamic UI construction.
	_refresh_theme_palette()

	# Setup custom components
	_setup_top_bar()
	_setup_subtitle_label()
	_setup_orb_container()
	_setup_quick_actions()
	_setup_bottom_nav()
	
	# Apply visual styling and tokens
	_apply_theme()
	_refresh_progress_summary()
	_update_settings_labels()
	
	# Floating Ambient Gems Setup
	_spawn_ambient_gems()
	_setup_button_animations()
	_animate_menu_entry()
	
	# Safe hide any GUT test runner logo overlay to prevent overlapping bottom-left navigation bar
	var gut_logo = get_tree().root.find_child("GutLogo", true, false)
	if gut_logo:
		gut_logo.visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _theme_color(key: String, fallback: Color) -> Color:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tokens = (loop as SceneTree).root.get_node_or_null("ThemeTokensAutoload")
		if tokens != null:
			var value = tokens.color(key, fallback)
			if value is Color:
				return value
			if value is String:
				return Color(String(value))
	return fallback

func _theme_path(path: String, fallback: Color = Color.WHITE) -> Color:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tokens = (loop as SceneTree).root.get_node_or_null("ThemeTokensAutoload")
		if tokens != null and tokens.has_method("color_path"):
			return tokens.color_path(path, fallback)
	return fallback

func _theme_int(path: String, fallback: int) -> int:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tokens = (loop as SceneTree).root.get_node_or_null("ThemeTokensAutoload")
		if tokens != null and tokens.has_method("int_value"):
			return tokens.int_value(path, fallback)
	return fallback

# --- CUSTOM COMPONENTS SETUP ---

func _setup_top_bar() -> void:
	# Clean top bar
	for child in top_bar.get_children():
		child.queue_free()
		
	# Coin Pill
	var coin_pill = PanelContainer.new()
	coin_pill.name = "CoinPill"
	coin_pill.custom_minimum_size = Vector2(150, 54)
	coin_pill.set("theme_override_styles/panel", _make_glass_style(21, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	
	var coin_hb = HBoxContainer.new()
	coin_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_hb.add_theme_constant_override("separation", 10)
	
	var coin_icon = Label.new()
	coin_icon.text = "🪙"
	coin_icon.add_theme_font_size_override("font_size", 16)
	coin_hb.add_child(coin_icon)
	
	coin_label = Label.new()
	coin_label.text = "0"
	coin_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	coin_label.add_theme_font_size_override("font_size", 18)
	coin_hb.add_child(coin_label)

	var coin_plus_btn = Button.new()
	coin_plus_btn.text = "+"
	coin_plus_btn.custom_minimum_size = Vector2(32, 32)
	coin_plus_btn.focus_mode = Control.FOCUS_NONE
	coin_plus_btn.set("theme_override_styles/normal", _make_glass_style(16, COLOR_GLASS_BG.lightened(0.06), COLOR_GLASS_BORDER))
	coin_plus_btn.set("theme_override_styles/hover", _make_glass_style(16, COLOR_GLASS_BG.lightened(0.18), COLOR_ACCENT_PLAY))
	coin_plus_btn.set("theme_override_styles/pressed", _make_glass_style(16, COLOR_GLASS_BG.darkened(0.06), COLOR_ACCENT_PLAY))
	coin_plus_btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
	coin_plus_btn.add_theme_font_size_override("font_size", 16)
	coin_plus_btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	ActionRegistry.bind(coin_plus_btn, &"menu.coins_add", func() -> void:
		UIScreenManager.navigate(&"shop", {"shop_tab": "Coins"})
	)
	coin_hb.add_child(coin_plus_btn)
	
	coin_pill.add_child(coin_hb)
	top_bar.add_child(coin_pill)
	
	# Star Pill
	var star_pill = PanelContainer.new()
	star_pill.name = "StarPill"
	star_pill.custom_minimum_size = Vector2(150, 54)
	star_pill.set("theme_override_styles/panel", _make_glass_style(21, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	
	var star_hb = HBoxContainer.new()
	star_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hb.add_theme_constant_override("separation", 10)
	
	var star_icon = Label.new()
	star_icon.text = "⭐"
	star_icon.add_theme_font_size_override("font_size", 15)
	star_hb.add_child(star_icon)
	
	star_label = Label.new()
	star_label.text = "0"
	star_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	star_label.add_theme_font_size_override("font_size", 18)
	star_hb.add_child(star_label)

	var star_plus_btn = Button.new()
	star_plus_btn.text = "+"
	star_plus_btn.custom_minimum_size = Vector2(32, 32)
	star_plus_btn.focus_mode = Control.FOCUS_NONE
	star_plus_btn.set("theme_override_styles/normal", _make_glass_style(16, COLOR_GLASS_BG.lightened(0.06), COLOR_GLASS_BORDER))
	star_plus_btn.set("theme_override_styles/hover", _make_glass_style(16, COLOR_GLASS_BG.lightened(0.18), COLOR_ACCENT_PLAY))
	star_plus_btn.set("theme_override_styles/pressed", _make_glass_style(16, COLOR_GLASS_BG.darkened(0.06), COLOR_ACCENT_PLAY))
	star_plus_btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
	star_plus_btn.add_theme_font_size_override("font_size", 16)
	star_plus_btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	ActionRegistry.bind(star_plus_btn, &"menu.stars_add", func() -> void:
		UIScreenManager.navigate(&"daily_rewards")
	)
	star_hb.add_child(star_plus_btn)
	
	star_pill.add_child(star_hb)
	top_bar.add_child(star_pill)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	
	# Inbox Button (Mail icon)
	var inbox_btn = Button.new()
	inbox_btn.name = "InboxBtn"
	inbox_btn.custom_minimum_size = Vector2(56, 56)
	inbox_btn.set("theme_override_styles/normal", _make_glass_style(22, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	inbox_btn.set("theme_override_styles/hover", _make_glass_style(22, COLOR_GLASS_BG.lightened(0.2), COLOR_ACCENT_STAR))
	inbox_btn.set("theme_override_styles/pressed", _make_glass_style(22, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_STAR))
	inbox_btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
	
	var inbox_lbl = Label.new()
	inbox_lbl.text = "✉"
	inbox_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inbox_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inbox_lbl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	inbox_lbl.add_theme_font_size_override("font_size", 22)
	inbox_lbl.anchors_preset = Control.PRESET_FULL_RECT
	inbox_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inbox_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	inbox_btn.add_child(inbox_lbl)
	
	ActionRegistry.bind(inbox_btn, &"nav.inbox", func() -> void:
		SoundManager.play("tap")
		UIScreenManager.navigate(&"inbox")
	)

	var inbox_badge = Panel.new()
	inbox_badge.custom_minimum_size = Vector2(10, 10)
	inbox_badge.position = Vector2(34, 2)
	inbox_badge.size = Vector2(10, 10)
	inbox_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inbox_badge.set("theme_override_styles/panel", _make_glass_style(5, COLOR_ACCENT_COIN, COLOR_ACCENT_STAR.lightened(0.18)))
	inbox_btn.add_child(inbox_badge)
	top_bar.add_child(inbox_btn)

func _setup_subtitle_label() -> void:
	# Add dynamic SubtitleLabel under TitleLabel to display streak and stats
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	
	# Setup position perfectly under TitleLabel
	add_child(subtitle_label)
	
	# Simple layout binding
	title_label.resized.connect(_reposition_subtitle)
	_reposition_subtitle()

func _reposition_subtitle() -> void:
	if subtitle_label and title_label:
		subtitle_label.position = Vector2(
			title_label.position.x,
			title_label.position.y + title_label.size.y - 12
		)
		subtitle_label.size = Vector2(title_label.size.x, 24)

func _setup_orb_container() -> void:
	# Clean orb container
	for child in orb_container.get_children():
		child.queue_free()
		
	# Create custom drawing Control for Sphere
	var orb_draw = OrbDrawScript.new()
	orb_draw.name = "OrbDraw"
	orb_draw.palette = {
		"pedestal": _theme_path("menu.visual.orb_pedestal"),
		"orbit": _theme_path("menu.visual.orb_orbit"),
		"base": _theme_path("menu.visual.orb_base"),
		"pink": _theme_path("menu.visual.orb_pink"),
		"blue": _theme_path("menu.visual.orb_blue"),
		"mint": _theme_path("menu.visual.orb_mint"),
		"gold": _theme_path("menu.visual.orb_gold"),
		"gloss": _theme_path("menu.visual.orb_gloss"),
		"arc": _theme_path("menu.visual.orb_arc"),
	}
	orb_draw.anchors_preset = Control.PRESET_FULL_RECT
	orb_draw.grow_horizontal = Control.GROW_DIRECTION_BOTH
	orb_draw.grow_vertical = Control.GROW_DIRECTION_BOTH
	orb_container.add_child(orb_draw)

func _setup_quick_actions() -> void:
	# Clean quick actions
	for child in quick_actions.get_children():
		child.queue_free()
		
	var actions = [
		{"name": "Levels", "icon": "◉"},
		{"name": "Events", "icon": "✦"},
		{"name": "Shop", "icon": "🛍"},
		{"name": "Settings", "icon": "⚙"}
	]
	
	for action in actions:
		var btn = Button.new()
		btn.name = action["name"] + "Button"
		btn.custom_minimum_size = Vector2(92, 116)
		btn.set("theme_override_styles/normal", _make_glass_style(20, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
		btn.set("theme_override_styles/hover", _make_glass_style(20, COLOR_GLASS_BG.lightened(0.15), COLOR_ACCENT_PLAY))
		btn.set("theme_override_styles/pressed", _make_glass_style(20, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_PLAY))
		btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		
		var vb := VBoxContainer.new()
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 8)
		btn.add_child(vb)

		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(40, 40)
		icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(icon_container)

		var icon_drawer = IconDrawerScript.new()
		icon_drawer.name = "Icon"
		icon_drawer.icon_type = action["name"].to_lower()
		icon_drawer.color = COLOR_TEXT_PRIMARY
		icon_drawer.anchors_preset = Control.PRESET_FULL_RECT
		icon_drawer.grow_horizontal = Control.GROW_DIRECTION_BOTH
		icon_drawer.grow_vertical = Control.GROW_DIRECTION_BOTH
		icon_container.add_child(icon_drawer)

		var lbl = Label.new()
		lbl.text = action["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		lbl.add_theme_font_size_override("font_size", 14)
		vb.add_child(lbl)
		
		# Setup button connection
		match String(action["name"]):
			"Levels":
				ActionRegistry.bind(btn, &"menu.levels", func() -> void:
					SoundManager.play("tap")
					UIScreenManager.navigate(&"world_map")
				)
			"Events":
				ActionRegistry.bind(btn, &"menu.events", func() -> void:
					SoundManager.play("tap")
					UIScreenManager.navigate(&"daily_rewards")
				)
			"Shop":
				ActionRegistry.bind(btn, &"menu.shop", func() -> void:
					SoundManager.play("tap")
					UIScreenManager.navigate(&"shop", {"shop_tab": "Coins"})
				)
			"Settings":
				ActionRegistry.bind(btn, &"menu.settings", _on_settings_pressed)
			
		quick_actions.add_child(btn)

func _setup_bottom_nav() -> void:
	# Clean bottom nav
	for child in bottom_nav.get_children():
		child.queue_free()
	bottom_nav.add_theme_constant_override("separation", 0)
		
	var tabs = [
		{"name": "Home", "icon": "🏠", "active": true},
		{"name": "Rankings", "icon": "🏆", "active": false},
		{"name": "Collection", "icon": "💎", "active": false},
		{"name": "Friends", "icon": "👥", "active": false},
		{"name": "Inbox", "icon": "✉", "active": false}
	]
	
	for tab in tabs:
		var tab_index := tabs.find(tab)
		var is_first := tab_index == 0
		var is_last := tab_index == tabs.size() - 1

		var tab_btn = Button.new()
		tab_btn.name = tab["name"] + "Tab"
		tab_btn.custom_minimum_size = Vector2(88, 104)
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var active_color = Color(COLOR_ACCENT_PLAY, 0.28) if tab["active"] else COLOR_GLASS_BG
		var border_color = COLOR_ACCENT_PLAY.lightened(0.12) if tab["active"] else COLOR_GLASS_BORDER
		tab_btn.set("theme_override_styles/normal", _make_segment_style(active_color, border_color, is_first, is_last, tab["active"]))
		tab_btn.set("theme_override_styles/hover", _make_segment_style(COLOR_GLASS_BG.lightened(0.2), COLOR_ACCENT_PLAY, is_first, is_last, tab["active"]))
		tab_btn.set("theme_override_styles/pressed", _make_segment_style(COLOR_GLASS_BG.darkened(0.06), COLOR_ACCENT_PLAY, is_first, is_last, tab["active"]))
		tab_btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
		
		var vbox = VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(36, 36)
		icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(icon_container)

		var icon_color = COLOR_ACCENT_PLAY.lightened(0.15) if tab["active"] else COLOR_TEXT_MUTED
		var icon_drawer = IconDrawerScript.new()
		icon_drawer.name = "Icon"
		icon_drawer.icon_type = tab["name"].to_lower()
		icon_drawer.color = icon_color
		icon_drawer.anchors_preset = Control.PRESET_FULL_RECT
		icon_drawer.grow_horizontal = Control.GROW_DIRECTION_BOTH
		icon_drawer.grow_vertical = Control.GROW_DIRECTION_BOTH
		icon_container.add_child(icon_drawer)
		
		var text_lbl = Label.new()
		text_lbl.text = tab["name"]
		text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_lbl.add_theme_font_size_override("font_size", 11)
		text_lbl.add_theme_color_override("font_color", COLOR_ACCENT_PLAY.lightened(0.15) if tab["active"] else COLOR_TEXT_MUTED)
		vbox.add_child(text_lbl)
		
		tab_btn.add_child(vbox)
		
		# Connection logic
		var tab_route: StringName = {
			"Home": &"main_menu",
			"Rankings": &"rankings",
			"Collection": &"collection",
			"Friends": &"friends",
			"Inbox": &"inbox",
		}.get(String(tab["name"]), &"main_menu")
		var action_id := StringName("nav." + String(tab["name"]).to_lower())
		ActionRegistry.bind(tab_btn, action_id, func() -> void:
			SoundManager.play("tap")
			UIScreenManager.navigate(tab_route)
		)
			
		bottom_nav.add_child(tab_btn)

# --- THEME & STYLING ---

func _apply_theme() -> void:
	_refresh_theme_palette()
	title_label.text = "Neo\nSoft Frost"

	# Main Title
	_set_label_style(title_label, _theme_int("shared.font.hero", 48) + 16, _theme_path("shared.colors.text_inverse"))
	title_label.add_theme_color_override("font_outline_color", _theme_path("shared.colors.accent_primary", COLOR_TEXT_PRIMARY).lightened(0.2))
	title_label.add_theme_constant_override("outline_size", 10)
	title_label.add_theme_color_override("font_shadow_color", _theme_path("shared.colors.accent_secondary", COLOR_TEXT_PRIMARY).darkened(0.4))
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 6)
	title_label.add_theme_constant_override("shadow_outline_size", 4)
	
	# Main Play Button (Accent style with frosted glassmorphism)
	var hero_radius := _theme_int("menu.surface.hero_button.radius", _theme_int("shared.radius.lg", 30))
	var play_bg = COLOR_ACCENT_PLAY
	play_bg.a = 0.72
	var play_normal = _make_glass_style(hero_radius, play_bg, Color(1.0, 1.0, 1.0, 0.85))
	var play_hover = _make_glass_style(hero_radius, play_bg.lightened(0.12), Color(1.0, 1.0, 1.0, 0.95))
	var play_press = _make_glass_style(hero_radius, play_bg.darkened(0.08), Color(1.0, 1.0, 1.0, 0.75))
	
	play_button.set("theme_override_styles/normal", play_normal)
	play_button.set("theme_override_styles/hover", play_hover)
	play_button.set("theme_override_styles/pressed", play_press)
	play_button.set("theme_override_styles/focus", StyleBoxEmpty.new())
	play_button.add_theme_font_size_override("font_size", 56)
	play_button.add_theme_color_override("font_color", _theme_path("shared.colors.text_inverse"))
	play_button.add_theme_color_override("font_hover_color", _theme_path("shared.colors.text_inverse"))
	play_button.add_theme_color_override("font_shadow_color", _theme_path("shared.colors.shadow"))
	play_button.add_theme_constant_override("shadow_offset_x", 0)
	play_button.add_theme_constant_override("shadow_offset_y", 3)
	
	# Settings Overlay Custom Glass styling
	var settings_glass = _make_glass_style(_theme_int("shared.radius.xl", 40), COLOR_GLASS_BG.lightened(0.18), COLOR_GLASS_BORDER)
	$SettingsOverlay/GlassPanel.set("theme_override_styles/panel", settings_glass)
	var overlay_color := COLOR_BG_START
	overlay_color.a = 0.72
	$SettingsOverlay.color = overlay_color
	
	_set_label_style($SettingsOverlay/GlassPanel/TitleLabel, 30, COLOR_TEXT_PRIMARY)
	
	# Style buttons inside Settings Panel
	var btn_normal = _make_glass_style(22, COLOR_GLASS_BG, COLOR_GLASS_BORDER)
	var btn_hover = _make_glass_style(22, COLOR_GLASS_BG.lightened(0.15), COLOR_ACCENT_PLAY)
	var btn_press = _make_glass_style(22, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_PLAY)
	
	var settings_buttons = [sound_button, music_button, close_button, haptics_button]
	for btn in settings_buttons:
		btn.set("theme_override_styles/normal", btn_normal)
		btn.set("theme_override_styles/hover", btn_hover)
		btn.set("theme_override_styles/pressed", btn_press)
		btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		btn.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
		
	if quality_button:
		quality_button.set("theme_override_styles/normal", btn_normal)
		quality_button.set("theme_override_styles/hover", btn_hover)
		quality_button.set("theme_override_styles/pressed", btn_press)
		quality_button.set("theme_override_styles/focus", StyleBoxEmpty.new())
		quality_button.add_theme_font_size_override("font_size", 18)
		quality_button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		quality_button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
		
	if export_button:
		export_button.set("theme_override_styles/normal", btn_normal)
		export_button.set("theme_override_styles/hover", btn_hover)
		export_button.set("theme_override_styles/pressed", btn_press)
		export_button.set("theme_override_styles/focus", StyleBoxEmpty.new())
		export_button.add_theme_font_size_override("font_size", 18)
		export_button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		export_button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)

func _refresh_theme_palette() -> void:
	COLOR_BG_START = _theme_path("shared.colors.bg_top")
	COLOR_BG_END = _theme_path("shared.colors.bg_bottom")
	COLOR_TEXT_PRIMARY = _theme_path("menu.text.title")
	COLOR_TEXT_MUTED = _theme_path("menu.text.muted")
	COLOR_ACCENT_COIN = _theme_path("shared.colors.accent_gold")
	COLOR_ACCENT_STAR = _theme_path("shared.colors.accent_primary")
	COLOR_ACCENT_PLAY = _theme_path("colors.accent")
	COLOR_GLASS_BG = _theme_path("shared.colors.glass_bg")
	COLOR_GLASS_BORDER = _theme_path("shared.colors.glass_border")
	COLOR_GLASS_SHADOW = _theme_path("shared.colors.shadow")

func _set_label_style(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)

func _make_glass_style(radius: int, bg_col: Color, border_col: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_blend = true # Softer, more premium glass border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = COLOR_GLASS_SHADOW
	style.shadow_size = 20 # Increased for softer shadow
	style.shadow_offset = Vector2(0, 8) # Drop shadow
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.5
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _make_segment_style(bg_col: Color, border_col: Color, is_left: bool, is_right: bool, is_active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.border_width_left = 1
	style.border_width_top = 2
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.border_blend = true
	var radius_l := 28 if is_left else 0
	var radius_r := 28 if is_right else 0
	style.corner_radius_top_left = radius_l
	style.corner_radius_bottom_left = radius_l
	style.corner_radius_top_right = radius_r
	style.corner_radius_bottom_right = radius_r
	style.shadow_color = COLOR_GLASS_SHADOW
	style.shadow_size = 18 if is_active else 12
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

# --- DRAW PROCESSES (Procedural Background & Hanging Diamonds) ---

func _draw() -> void:
	# Layer 0: tuned vertical gradient
	var steps := 24
	var stripe_h := size.y / float(steps)
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		var col := COLOR_BG_START.lerp(COLOR_BG_END, t)
		draw_rect(Rect2(0, i * stripe_h, size.x, stripe_h + 1.0), col, true)

	# Layer 1: atmospheric highlights
	var time_val = bg_time * 0.25
	var bubble_offset = cursor_offset * 0.35
	
	var v_pos = Vector2(
		size.x * 0.2 + sin(time_val) * 40.0,
		size.y * 0.3 + cos(time_val) * 45.0
	) + bubble_offset
	draw_circle(v_pos, size.x * 0.38, _theme_path("shared.colors.accent_primary", COLOR_ACCENT_STAR).lightened(0.25))
	
	var r_pos = Vector2(
		size.x * 0.8 + cos(time_val * 1.2) * 50.0,
		size.y * 0.45 + sin(time_val * 0.8) * 35.0
	) + bubble_offset
	draw_circle(r_pos, size.x * 0.35, COLOR_ACCENT_PLAY.lightened(0.28))
	
	var b_pos = Vector2(
		size.x * 0.35 + sin(time_val * 0.9 + 1.0) * 35.0,
		size.y * 0.8 + cos(time_val * 1.1) * 60.0
	) + bubble_offset
	draw_circle(b_pos, size.x * 0.3, _theme_path("shared.colors.accent_secondary", COLOR_ACCENT_STAR).lightened(0.2))

	# Layer 1.5: hero glow + title separator + arch frame
	var hero_center := Vector2(size.x * 0.5, size.y * 0.47)
	draw_circle(hero_center, size.x * 0.28, _theme_path("shared.colors.accent_primary", COLOR_ACCENT_PLAY).lightened(0.35))
	draw_circle(hero_center + Vector2(0, size.y * 0.02), size.x * 0.2, _theme_path("shared.colors.accent_secondary", COLOR_ACCENT_STAR).lightened(0.42))

	var sep_y := size.y * 0.33
	draw_line(Vector2(size.x * 0.26, sep_y), Vector2(size.x * 0.74, sep_y), _theme_path("shared.colors.glass_border", COLOR_GLASS_BORDER), 2.0)
	draw_circle(Vector2(size.x * 0.5, sep_y), 7.0, _theme_path("shared.colors.accent_primary", COLOR_ACCENT_PLAY))
	draw_circle(Vector2(size.x * 0.34, sep_y), 3.0, _theme_path("shared.colors.text_inverse", COLOR_TEXT_PRIMARY))
	draw_circle(Vector2(size.x * 0.66, sep_y), 3.0, _theme_path("shared.colors.text_inverse", COLOR_TEXT_PRIMARY))

	var arch_col := _theme_path("shared.colors.glass_border", COLOR_GLASS_BORDER)
	arch_col.a = 0.62
	draw_arc(hero_center + Vector2(0, size.y * 0.08), size.x * 0.27, PI * 1.08, PI * 1.92, 56, arch_col, 2.2, true)
	draw_arc(hero_center + Vector2(0, size.y * 0.08), size.x * 0.24, PI * 1.1, PI * 1.9, 56, _theme_path("shared.colors.text_inverse", Color.WHITE), 1.0, true)
	
	# Layer 2: hanging accents
	for dia in hanging_diamonds:
		var x_pos = dia["x_ratio"] * size.x + cursor_offset.x * 0.6
		var length = dia["length"]
		var phase = dia["phase"] + bg_time * dia["speed"]
		
		# Gentle sway rotation math
		var sway_angle = sin(phase) * 0.045
		
		var line_start = Vector2(x_pos, 0.0)
		var line_end = Vector2(
			x_pos + sin(sway_angle) * length,
			cos(sway_angle) * length
		)
		
		# Draw elegant thin line (thread)
		draw_line(line_start, line_end, COLOR_TEXT_MUTED, 1.0)
		
		# Draw Diamond at the end of the line
		var dia_size = dia["size"]
		var pts = [
			line_end + Vector2(0, -dia_size),
			line_end + Vector2(dia_size * 0.7, 0),
			line_end + Vector2(0, dia_size),
			line_end + Vector2(-dia_size * 0.7, 0)
		]
		
		# Multi-colored semi-transparent fill
		var pulse_color = COLOR_GLASS_BG
		pulse_color.a = 0.5 + sin(phase * 2.0) * 0.15
		
		draw_polygon(pts, [pulse_color])
		draw_polyline(pts, COLOR_GLASS_BORDER, 1.2)
		
		# Elegant inner sparkle highlight
		draw_line(line_end - Vector2(3, 0), line_end + Vector2(3, 0), COLOR_TEXT_PRIMARY, 1.0)
		draw_line(line_end - Vector2(0, 3), line_end + Vector2(0, 3), COLOR_TEXT_PRIMARY, 1.0)

# --- PROCESS LOOPS ---

func _process(delta: float) -> void:
	bg_time += delta
	
	# Parallax calculations based on viewport mouse cursor position
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_center := size * 0.5
	# Dynamic target parallax factor
	var target_offset := (mouse_pos - screen_center) * -0.05
	cursor_offset = cursor_offset.lerp(target_offset, delta * 3.0)
	
	# Update positions of ambient floating crystals (gems)
	for gem in floating_gems:
		gem.base_pos += gem.velocity * delta
		
		# Keep crystals bouncing realistically off viewport boundaries
		var radius = gem.size_px * 0.5
		if gem.base_pos.x < -radius:
			gem.base_pos.x = -radius
			gem.velocity.x *= -1.0
		elif gem.base_pos.x > size.x + radius:
			gem.base_pos.x = size.x + radius
			gem.velocity.x *= -1.0
			
		if gem.base_pos.y < -radius:
			gem.base_pos.y = -radius
			gem.velocity.y *= -1.0
		elif gem.base_pos.y > size.y + radius:
			gem.base_pos.y = size.y + radius
			gem.velocity.y *= -1.0
		
		gem.node.rotation += gem.spin_speed * delta
		gem.node.position = gem.base_pos + cursor_offset * gem.depth
		
	# Redraw procedural background
	queue_redraw()

# --- AMBIENT FLOATING CRYSTALS (Gems) ---

func _spawn_ambient_gems() -> void:
	# Clean existing gems
	for child in background_gems_container.get_children():
		child.queue_free()
	for child in foreground_gems_container.get_children():
		child.queue_free()
		
	floating_gems.clear()
	if not ENABLE_AMBIENT_GEMS:
		return
	
	# 8 spheres total for luxurious multi-layered parallax depth
	var gem_configs := [
		{"type": 0, "depth": 0.35, "pos": Vector2(0.12, 0.22)}, # Frost
		{"type": 1, "depth": 0.45, "pos": Vector2(0.88, 0.18)}, # Glass
		{"type": 2, "depth": 0.38, "pos": Vector2(0.15, 0.72)}, # Aqua
		{"type": 3, "depth": 0.50, "pos": Vector2(0.82, 0.85)}, # Violet
		{"type": 4, "depth": 0.80, "pos": Vector2(0.10, 0.46)}, # Warm
		{"type": 5, "depth": 0.85, "pos": Vector2(0.90, 0.52)}, # Blue ribbon
		{"type": 6, "depth": 1.00, "pos": Vector2(0.30, 0.90)}, # Purple ribbon
		{"type": 7, "depth": 1.08, "pos": Vector2(0.54, 0.16)}, # Cross wave
	]
	
	for cfg in gem_configs:
		var gem := GemView.new()
		var depth: float = cfg["depth"]
		
		# Sizing configuration
		var base_size: float = 55.0 if depth < 0.7 else 70.0
		gem.size = base_size * depth
		gem.set_piece(cfg["type"])
		gem.set_sphere_type(SphereFactory.get_sphere_type_for_piece(cfg["type"]))
		
		# Place in background/foreground containers based on depth
		if depth < 0.7:
			background_gems_container.add_child(gem)
			# Reduce opacity to stay subtle and elegant on bright canvas
			gem.modulate.a = 0.32
		else:
			foreground_gems_container.add_child(gem)
			gem.modulate.a = 0.55
			
		var screen_size = size
		if screen_size.x <= 0 or screen_size.y <= 0:
			screen_size = Vector2(720, 1280)
			
		var init_pos := Vector2(cfg["pos"].x * screen_size.x, cfg["pos"].y * screen_size.y)
		gem.position = init_pos
		
		# Soft random initial motions
		var angle := randf_range(0, TAX_TAU() if has_method("TAX_TAU") else TAU)
		var speed := randf_range(10.0, 22.0) * (depth + 0.35)
		var velocity := Vector2(cos(angle), sin(angle)) * speed
		var spin := randf_range(-0.12, 0.12)
		
		var data = FloatingGem.new()
		data.node = gem
		data.velocity = velocity
		data.spin_speed = spin
		data.base_pos = init_pos
		data.depth = depth
		data.size_px = gem.size
		floating_gems.append(data)

# Helper method in case TAU was typed
func TAX_TAU() -> float:
	return 6.283185

# --- INTERACTIVE ANIMATIONS ---

func _setup_button_animations() -> void:
	var buttons = [play_button, close_button, sound_button, music_button]
	
	# Connect to all action quick action and nav buttons dynamically
	for btn in buttons:
		if not btn: continue
		btn.pivot_offset = btn.size * 0.5
		btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
		
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.button_down.connect(_on_button_down.bind(btn))
		btn.button_up.connect(_on_button_up.bind(btn))

func _on_button_hover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.20)
	tween.parallel().tween_property(btn, "modulate", Color(1.08, 1.08, 1.08, 1.0), 0.20)

func _on_button_unhover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.18)

func _on_button_down(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.08)

func _on_button_up(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if btn.get_global_rect().has_point(get_global_mouse_position()):
		tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12)
	else:
		tween.tween_property(btn, "scale", Vector2.ONE, 0.12)

# --- SIGNALS & ACTIONS ---

func _on_play_pressed() -> void:
	SoundManager.play("play")
	UIScreenManager.navigate(&"world_map")

func _on_settings_pressed() -> void:
	SoundManager.play("open")
	settings_overlay.visible = true
	_animate_overlay(settings_overlay)

func _on_close_pressed() -> void:
	SoundManager.play("close")
	settings_overlay.visible = false

func _on_sound_toggled() -> void:
	UserData.sound_enabled = not UserData.sound_enabled
	UserData.save_data()
	_update_settings_labels()

func _on_music_toggled() -> void:
	UserData.music_enabled = not UserData.music_enabled
	UserData.save_data()
	_update_settings_labels()

func _on_sound_volume_changed(value: float) -> void:
	UserData.sound_volume = value
	UserData.sound_enabled = value > 0.0
	UserData.save_data()
	_update_settings_labels()

func _on_music_volume_changed(value: float) -> void:
	UserData.music_volume = value
	UserData.music_enabled = value > 0.0
	UserData.save_data()
	_update_settings_labels()

func _on_haptics_toggled() -> void:
	UserData.haptics_enabled = not UserData.haptics_enabled
	UserData.save_data()
	_update_settings_labels()

func _on_quality_toggled() -> void:
	SoundManager.play("tap")
	if UserData.quality_profile == "web_default":
		UserData.quality_profile = "android_safe"
	else:
		UserData.quality_profile = "web_default"
	UserData.save_data()
	_update_settings_labels()

func _on_export_pressed() -> void:
	SoundManager.play("tap")
	var json_logs := UserData.get_formatted_test_logs()
	DisplayServer.clipboard_set(json_logs)
	_spawn_toast("Logs copied to clipboard!")

func _spawn_toast(msg: String) -> void:
	var toast_scene = load("res://scenes/menus/toast_notification.tscn")
	if toast_scene:
		var toast = toast_scene.instantiate()
		add_child(toast)
		if toast.has_method("show_message"):
			toast.show_message(msg)

func _create_volume_slider(label_text: String, initial_value: float, action_id: StringName, handler: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.name = label_text.replace(" ", "")
	slider.custom_minimum_size = Vector2(0, 42)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.tooltip_text = label_text
	slider.set_meta(&"ui_action_id", String(action_id))
	slider.value_changed.connect(handler)
	return slider

func _update_settings_labels() -> void:
	sound_button.text = "Sound: ON" if UserData.sound_enabled else "Sound: OFF"
	music_button.text = "Music: ON" if UserData.music_enabled else "Music: OFF"
	if quality_button:
		quality_button.text = "Quality: High (Glow)" if UserData.quality_profile == "web_default" else "Quality: Mobile (72% Glow)"
	if export_button:
		export_button.text = "Export Test Logs"
	if haptics_button:
		haptics_button.text = "Haptics: ON" if UserData.haptics_enabled else "Haptics: OFF"
	play_button.text = "Play"

func _refresh_progress_summary() -> void:
	# Coins & Stars update in Top Bar
	if coin_label:
		coin_label.text = str(UserData.coins)
	if star_label:
		# Estimate stars from user completed levels count
		var completed = UserData.get_retention_summary().get("completed_levels", 0)
		star_label.text = str(completed * 3) # 3 stars per completed level
		
	# Update Subtitle labels under main title
	if subtitle_label:
		subtitle_label.text = "✧  Dreamy Crystal Journey  ✧"

func _animate_menu_entry() -> void:
	modulate.a = 0.0
	
	# Entry animations
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.55)
	
	# Small slide-ins
	play_button.scale = Vector2(0.9, 0.9)
	var play_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	play_tween.tween_property(play_button, "scale", Vector2.ONE, 0.6)

func _animate_overlay(overlay: ColorRect) -> void:
	var panel := overlay.get_node("GlassPanel")
	if panel:
		panel.scale = Vector2(0.86, 0.86)
		panel.modulate.a = 0.0
		var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.32)
		tween.tween_property(panel, "modulate:a", 1.0, 0.32)

# --- NESTED CLASSES FOR CUSTOM PROCEDURAL DRAWING ---

class OrbDrawScript extends Control:
	var rot_angle: float = 0.0
	var pulse_timer: float = 0.0
	var palette: Dictionary = {}
	
	func _ready() -> void:
		set_process(true)
		
	func _process(delta: float) -> void:
		rot_angle += delta * 0.35
		pulse_timer += delta * 1.5
		queue_redraw()
		
	func _draw() -> void:
		var center = size * 0.5
		var pulse = 1.0 + sin(pulse_timer) * 0.024
		var base_radius = 128.0 * pulse
		
		# 1. Shadow Pedestal under Sphere
		var ped_center = center + Vector2(0, 130)
		var ped_size = Vector2(158, 24)
		var ped_pts = PackedVector2Array()
		var steps = 36
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			ped_pts.append(ped_center + Vector2(cos(a) * ped_size.x, sin(a) * ped_size.y))
		draw_polygon(ped_pts, [palette.get("pedestal", Color.WHITE)])
		
		# 2. Glowing Elliptic Orbit (Arc)
		var orbit_pts = PackedVector2Array()
		# Slight angle rotation for the orbit ring
		var orbit_rot = sin(rot_angle * 0.3) * 0.08
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			var pt = Vector2(cos(a) * (base_radius * 1.45), sin(a) * (base_radius * 0.35))
			# Rotate point
			var rot_pt = Vector2(
				pt.x * cos(orbit_rot) - pt.y * sin(orbit_rot),
				pt.x * sin(orbit_rot) + pt.y * cos(orbit_rot)
			)
			orbit_pts.append(center + rot_pt)
		
		# Render orbit line with clean semi-transparent white
		draw_polyline(orbit_pts, palette.get("orbit", Color.WHITE), 1.8)
		
		# Orbit Sparkle
		var sp_pt = orbit_pts[int(steps * 0.28)]
		draw_circle(sp_pt, 4.4, Color.WHITE)
		draw_line(sp_pt - Vector2(8, 0), sp_pt + Vector2(8, 0), Color.WHITE, 1.0)
		draw_line(sp_pt - Vector2(0, 8), sp_pt + Vector2(0, 8), Color.WHITE, 1.0)
		
		# 3. Orb Base sphere
		draw_circle(center, base_radius, palette.get("base", Color.WHITE))
		
		# 4. Multi-layered moving Pastel aurora gradients
		var aurora_layers = [
			{"color": palette.get("pink", Color.WHITE), "speed": 1.0, "scale": 0.85, "phase": 0.0},
			{"color": palette.get("blue", Color.WHITE), "speed": -0.8, "scale": 0.80, "phase": 2.1},
			{"color": palette.get("mint", Color.WHITE), "speed": 1.2, "scale": 0.75, "phase": 1.2},
			{"color": palette.get("gold", Color.WHITE), "speed": -0.6, "scale": 0.90, "phase": 3.4}
		]
		
		for layer in aurora_layers:
			var ang = rot_angle * layer["speed"] + layer["phase"]
			var offset = Vector2(cos(ang), sin(ang)) * (base_radius * 0.16)
			draw_circle(center + offset, base_radius * layer["scale"], layer["color"])
			
		# 5. Glossy 3D Highlight specular flare (top-left)
		var specular_pos = center - Vector2(base_radius * 0.34, base_radius * 0.34)
		draw_circle(specular_pos, base_radius * 0.26, palette.get("gloss", Color.WHITE))
		draw_circle(specular_pos - Vector2(base_radius * 0.05, base_radius * 0.05), base_radius * 0.12, Color.WHITE)
		draw_arc(center, base_radius * 0.92, -PI * 0.18, PI * 1.7, 34, palette.get("arc", Color.WHITE), 2.1)

class IconDrawerScript extends Control:
	var icon_type: String = ""
	var color: Color = Color.WHITE
	
	func _draw() -> void:
		var center = size * 0.5
		draw_set_transform(center, 0.0, Vector2.ONE)
		
		match icon_type:
			"levels":
				# Render beautiful list bullet layout
				var line_w = 26.0
				var line_h = 3.5
				draw_rect(Rect2(-line_w/2, -10, line_w, line_h), color, true)
				draw_rect(Rect2(-line_w/2, -2, line_w, line_h), color, true)
				draw_rect(Rect2(-line_w/2, 6, line_w, line_h), color, true)
				
				# Small indicator dots
				draw_circle(Vector2(-line_w/2 - 7, -8.2), 2.5, color)
				draw_circle(Vector2(-line_w/2 - 7, -0.2), 2.5, color)
				draw_circle(Vector2(-line_w/2 - 7, 7.8), 2.5, color)
				
			"events":
				# Sparkle 4-point star
				var star_pts = PackedVector2Array([
					Vector2(0, -15),
					Vector2(4, -4),
					Vector2(15, 0),
					Vector2(4, 4),
					Vector2(0, 15),
					Vector2(-4, 4),
					Vector2(-15, 0),
					Vector2(-4, -4),
					Vector2(0, -15)
				])
				draw_polyline(star_pts, color, 2.0)
				draw_circle(Vector2.ZERO, 2.5, color)
				
			"shop":
				# Shopping bag silhouette conforming to ref
				var bag_pts = PackedVector2Array([
					Vector2(-11, -6),
					Vector2(11, -6),
					Vector2(13, 12),
					Vector2(-13, 12),
					Vector2(-11, -6)
				])
				draw_polyline(bag_pts, color, 2.0)
				draw_arc(Vector2(0, -6), 6.0, PI, TAU, 16, color, 2.0)
				
			"settings":
				# Beautiful clean vector cogwheel
				draw_arc(Vector2.ZERO, 7.5, 0, TAU, 32, color, 2.0)
				draw_arc(Vector2.ZERO, 4.0, 0, TAU, 32, color, 1.2)
				var teeth = 8
				for i in range(teeth):
					var a = float(i) / teeth * TAU
					var p1 = Vector2(cos(a), sin(a)) * 7.5
					var p2 = Vector2(cos(a), sin(a)) * 13.0
					draw_line(p1, p2, color, 2.5)

			"home":
				# Outline house structure
				var roof_pts = PackedVector2Array([
					Vector2(0, -14),
					Vector2(-16, 0),
					Vector2(16, 0),
					Vector2(0, -14)
				])
				draw_polyline(roof_pts, color, 2.0)
				
				var wall_pts = PackedVector2Array([
					Vector2(-12, 0),
					Vector2(-12, 14),
					Vector2(12, 14),
					Vector2(12, 0)
				])
				draw_polyline(wall_pts, color, 2.0)
				draw_rect(Rect2(-3.5, 6, 7, 8), color, false, 1.8)

			"rankings":
				# Outline cup trophy
				var cup_poly = PackedVector2Array([
					Vector2(-12, -14), Vector2(12, -14),
					Vector2(10, 0), Vector2(-10, 0),
					Vector2(-12, -14)
				])
				draw_polyline(cup_poly, color, 2.0)
				
				# Cup handles
				draw_arc(Vector2(-10, -7), 5.0, -PI/2, PI/2, 16, color, 2.0)
				draw_arc(Vector2(10, -7), 5.0, PI/2, 3*PI/2, 16, color, 2.0)
				
				# Stand
				draw_line(Vector2(0, 0), Vector2(0, 10), color, 2.5)
				draw_line(Vector2(-10, 10), Vector2(10, 10), color, 2.5)

			"collection":
				# Multi-faceted diamond outline
				var top_left = Vector2(-14, -6)
				var top_right = Vector2(14, -6)
				var top_mid_left = Vector2(-7, -13)
				var top_mid_right = Vector2(7, -13)
				var bottom = Vector2(0, 13)
				
				var border_pts = PackedVector2Array([
					top_mid_left, top_mid_right, top_right, bottom, top_left, top_mid_left
				])
				draw_polyline(border_pts, color, 2.0)
				
				# Inner facets
				draw_line(top_mid_left, bottom, color, 1.2)
				draw_line(top_mid_right, bottom, color, 1.2)
				draw_line(top_mid_left, top_left, color, 1.2)
				draw_line(top_mid_right, top_right, color, 1.2)
				draw_line(top_left, top_right, color, 1.2)
				draw_line(top_mid_left, top_mid_right, color, 1.2)

			"friends":
				# Silhouettes of two people side-by-side (overlapping nicely)
				var c_left = Vector2(-6, -4)
				draw_arc(c_left, 4.5, 0, TAU, 24, color, 1.8)
				draw_arc(Vector2(-6, 8), 7.5, PI, TAU, 16, color, 1.8)
				draw_line(Vector2(-13.5, 8), Vector2(1.5, 8), color, 1.8)
				
				var c_right = Vector2(6, 0)
				draw_arc(c_right, 5.0, 0, TAU, 24, color, 2.0)
				draw_arc(Vector2(6, 13), 8.5, PI, TAU, 16, color, 2.0)
				draw_line(Vector2(-2.5, 13), Vector2(14.5, 13), color, 2.0)

			"inbox":
				# Beautiful vector envelope outline
				var mail_rect = Rect2(-14, -9, 28, 18)
				draw_rect(mail_rect, color, false, 2.0)
				draw_line(Vector2(-14, -9), Vector2(0, 1), color, 1.5)
				draw_line(Vector2(14, -9), Vector2(0, 1), color, 1.5)
