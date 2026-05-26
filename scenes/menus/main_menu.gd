extends Control

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

# Dynamic Progress Labels & Pills
var coin_label: Label
var star_label: Label
var subtitle_label: Label

# Design Tokens (Pastel Glassmorphism)
const COLOR_BG_START = Color(0.92, 0.88, 0.98)
const COLOR_BG_END = Color(0.96, 0.90, 0.95)
const COLOR_TEXT_PRIMARY = Color(0.45, 0.38, 0.55)
const COLOR_TEXT_MUTED = Color(0.60, 0.55, 0.70)
const COLOR_GLASS_BG = Color(1.0, 1.0, 1.0, 0.35)
const COLOR_GLASS_BORDER = Color(1.0, 1.0, 1.0, 0.65)
const COLOR_GLASS_SHADOW = Color(0.60, 0.50, 0.70, 0.12)
const COLOR_ACCENT_COIN = Color(0.98, 0.72, 0.28)
const COLOR_ACCENT_STAR = Color(0.28, 0.65, 0.92)
const COLOR_ACCENT_PLAY = Color(0.78, 0.60, 0.90)

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
	play_button.pressed.connect(_on_play_pressed)
	close_button.pressed.connect(_on_close_pressed)
	sound_button.pressed.connect(_on_sound_toggled)
	music_button.pressed.connect(_on_music_toggled)
	
	# Dynamic settings configuration
	var settings_box := $SettingsOverlay/GlassPanel/VBoxContainer
	quality_button = Button.new()
	quality_button.name = "QualityButton"
	quality_button.custom_minimum_size = Vector2(0, 56)
	settings_box.add_child(quality_button)
	settings_box.move_child(quality_button, close_button.get_index())
	quality_button.pressed.connect(_on_quality_toggled)
	
	export_button = Button.new()
	export_button.name = "ExportButton"
	export_button.custom_minimum_size = Vector2(0, 56)
	settings_box.add_child(export_button)
	settings_box.move_child(export_button, close_button.get_index())
	export_button.pressed.connect(_on_export_pressed)
	
	# Expand settings panel vertical layout sizes
	$SettingsOverlay/GlassPanel.offset_top = -275.0
	$SettingsOverlay/GlassPanel.offset_bottom = 275.0
	$SettingsOverlay/GlassPanel.pivot_offset = Vector2(220, 275)
	
	# Initialize hanging diamonds configurations
	# {x_ratio, length, size, phase, speed}
	hanging_diamonds = [
		{"x_ratio": 0.08, "length": 250.0, "size": 18.0, "phase": 0.0, "speed": 1.2},
		{"x_ratio": 0.14, "length": 180.0, "size": 14.0, "phase": 1.5, "speed": 1.5},
		{"x_ratio": 0.86, "length": 200.0, "size": 16.0, "phase": 0.7, "speed": 1.3},
		{"x_ratio": 0.92, "length": 280.0, "size": 20.0, "phase": 2.2, "speed": 1.0}
	]
	
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

# --- CUSTOM COMPONENTS SETUP ---

func _setup_top_bar() -> void:
	# Clean top bar
	for child in top_bar.get_children():
		child.queue_free()
		
	# Coin Pill
	var coin_pill = PanelContainer.new()
	coin_pill.name = "CoinPill"
	coin_pill.custom_minimum_size = Vector2(110, 42)
	coin_pill.set("theme_override_styles/panel", _make_glass_style(21, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	
	var coin_hb = HBoxContainer.new()
	coin_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_hb.add_theme_constant_override("separation", 6)
	
	var coin_icon = Label.new()
	coin_icon.text = "🪙"
	coin_icon.add_theme_font_size_override("font_size", 16)
	coin_hb.add_child(coin_icon)
	
	coin_label = Label.new()
	coin_label.text = "0"
	coin_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	coin_label.add_theme_font_size_override("font_size", 15)
	coin_hb.add_child(coin_label)
	
	coin_pill.add_child(coin_hb)
	top_bar.add_child(coin_pill)
	
	# Star Pill
	var star_pill = PanelContainer.new()
	star_pill.name = "StarPill"
	star_pill.custom_minimum_size = Vector2(95, 42)
	star_pill.set("theme_override_styles/panel", _make_glass_style(21, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
	
	var star_hb = HBoxContainer.new()
	star_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hb.add_theme_constant_override("separation", 6)
	
	var star_icon = Label.new()
	star_icon.text = "⭐"
	star_icon.add_theme_font_size_override("font_size", 15)
	star_hb.add_child(star_icon)
	
	star_label = Label.new()
	star_label.text = "0"
	star_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	star_label.add_theme_font_size_override("font_size", 15)
	star_hb.add_child(star_label)
	
	star_pill.add_child(star_hb)
	top_bar.add_child(star_pill)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	
	# Inbox Button (Mail icon)
	var inbox_btn = Button.new()
	inbox_btn.name = "InboxBtn"
	inbox_btn.custom_minimum_size = Vector2(44, 44)
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
	
	inbox_btn.pressed.connect(func():
		SoundManager.play("tap")
		_spawn_toast("Inbox: No new messages")
	)
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
	orb_draw.anchors_preset = Control.PRESET_FULL_RECT
	orb_draw.grow_horizontal = Control.GROW_DIRECTION_BOTH
	orb_draw.grow_vertical = Control.GROW_DIRECTION_BOTH
	orb_container.add_child(orb_draw)

func _setup_quick_actions() -> void:
	# Clean quick actions
	for child in quick_actions.get_children():
		child.queue_free()
		
	var actions = [
		{"name": "Levels", "icon_type": "levels"},
		{"name": "Events", "icon_type": "events"},
		{"name": "Shop", "icon_type": "shop"},
		{"name": "Settings", "icon_type": "settings"}
	]
	
	for action in actions:
		var btn = Button.new()
		btn.name = action["name"] + "Button"
		btn.custom_minimum_size = Vector2(70, 70)
		btn.set("theme_override_styles/normal", _make_glass_style(20, COLOR_GLASS_BG, COLOR_GLASS_BORDER))
		btn.set("theme_override_styles/hover", _make_glass_style(20, COLOR_GLASS_BG.lightened(0.15), COLOR_ACCENT_PLAY))
		btn.set("theme_override_styles/pressed", _make_glass_style(20, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_PLAY))
		btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
		
		# Prototyping procedural icon drawer
		var icon_drawer = IconDrawerScript.new()
		icon_drawer.name = "IconDrawer"
		icon_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_drawer.anchors_preset = Control.PRESET_FULL_RECT
		icon_drawer.grow_horizontal = Control.GROW_DIRECTION_BOTH
		icon_drawer.grow_vertical = Control.GROW_DIRECTION_BOTH
		icon_drawer.icon_type = action["icon_type"]
		icon_drawer.color = COLOR_TEXT_PRIMARY
		btn.add_child(icon_drawer)
		
		# Label for tooltip/description
		var lbl = Label.new()
		lbl.text = action["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.position = Vector2(0, 50)
		lbl.size = Vector2(70, 20)
		btn.add_child(lbl)
		
		# Setup button connection
		if action["name"] == "Levels":
			btn.pressed.connect(func():
				SoundManager.play("tap")
				get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")
			)
		elif action["name"] == "Settings":
			btn.pressed.connect(_on_settings_pressed)
		else:
			btn.pressed.connect(func():
				SoundManager.play("tap")
				_spawn_toast("%s Coming Soon!" % action["name"])
			)
			
		quick_actions.add_child(btn)

func _setup_bottom_nav() -> void:
	# Clean bottom nav
	for child in bottom_nav.get_children():
		child.queue_free()
		
	var tabs = [
		{"name": "Home", "icon": "🏠", "active": true},
		{"name": "Rankings", "icon": "🏆", "active": false},
		{"name": "Collection", "icon": "💎", "active": false},
		{"name": "Friends", "icon": "👥", "active": false},
		{"name": "Inbox", "icon": "✉", "active": false}
	]
	
	for tab in tabs:
		var tab_btn = Button.new()
		tab_btn.name = tab["name"] + "Tab"
		tab_btn.custom_minimum_size = Vector2(64, 76)
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var active_color = COLOR_ACCENT_PLAY if tab["active"] else COLOR_GLASS_BG
		var border_color = COLOR_ACCENT_PLAY.lightened(0.2) if tab["active"] else COLOR_GLASS_BORDER
		
		tab_btn.set("theme_override_styles/normal", _make_glass_style(16, active_color, border_color))
		tab_btn.set("theme_override_styles/hover", _make_glass_style(16, COLOR_GLASS_BG.lightened(0.2), COLOR_ACCENT_PLAY))
		tab_btn.set("theme_override_styles/pressed", _make_glass_style(16, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_PLAY))
		tab_btn.set("theme_override_styles/focus", StyleBoxEmpty.new())
		
		var vbox = VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		
		var icon_lbl = Label.new()
		icon_lbl.text = tab["icon"]
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_lbl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY if tab["active"] else COLOR_TEXT_MUTED)
		vbox.add_child(icon_lbl)
		
		var text_lbl = Label.new()
		text_lbl.text = tab["name"]
		text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_lbl.add_theme_font_size_override("font_size", 9)
		text_lbl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY if tab["active"] else COLOR_TEXT_MUTED)
		vbox.add_child(text_lbl)
		
		tab_btn.add_child(vbox)
		
		# Connection logic
		if tab["name"] == "Home":
			tab_btn.pressed.connect(func():
				SoundManager.play("tap")
				_spawn_toast("You are already Home!")
			)
		else:
			tab_btn.pressed.connect(func():
				SoundManager.play("tap")
				_spawn_toast("%s section is locked." % tab["name"])
			)
			
		bottom_nav.add_child(tab_btn)

# --- THEME & STYLING ---

func _apply_theme() -> void:
	# Main Title
	_set_label_style(title_label, 42, COLOR_TEXT_PRIMARY)
	title_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.9))
	title_label.add_theme_constant_override("outline_size", 8)
	
	# Main Play Button (Accent style)
	var play_normal = _make_glass_style(26, COLOR_ACCENT_PLAY.lightened(0.1), COLOR_GLASS_BORDER)
	var play_hover = _make_glass_style(26, COLOR_ACCENT_PLAY.lightened(0.25), COLOR_ACCENT_PLAY)
	var play_press = _make_glass_style(26, COLOR_ACCENT_PLAY.darkened(0.1), COLOR_ACCENT_PLAY)
	
	play_button.set("theme_override_styles/normal", play_normal)
	play_button.set("theme_override_styles/hover", play_hover)
	play_button.set("theme_override_styles/pressed", play_press)
	play_button.set("theme_override_styles/focus", StyleBoxEmpty.new())
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color.WHITE)
	play_button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	# Settings Overlay Custom Glass styling
	var settings_glass = _make_glass_style(32, Color(1.0, 1.0, 1.0, 0.55), COLOR_GLASS_BORDER)
	$SettingsOverlay/GlassPanel.set("theme_override_styles/panel", settings_glass)
	$SettingsOverlay.color = Color(0.92, 0.88, 0.98, 0.65) # Pastel tint
	
	_set_label_style($SettingsOverlay/GlassPanel/TitleLabel, 30, COLOR_TEXT_PRIMARY)
	
	# Style buttons inside Settings Panel
	var btn_normal = _make_glass_style(22, COLOR_GLASS_BG, COLOR_GLASS_BORDER)
	var btn_hover = _make_glass_style(22, COLOR_GLASS_BG.lightened(0.15), COLOR_ACCENT_PLAY)
	var btn_press = _make_glass_style(22, COLOR_GLASS_BG.darkened(0.1), COLOR_ACCENT_PLAY)
	
	var settings_buttons = [sound_button, music_button, close_button]
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
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = COLOR_GLASS_SHADOW
	style.shadow_size = 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

# --- DRAW PROCESSES (Procedural Background & Hanging Diamonds) ---

func _draw() -> void:
	# Layer 0: Pastel lavendar background gradient
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG_START, true)
	
	# Subtle color variation gradient bottom
	var rect_bottom = Rect2(0, size.y * 0.5, size.x, size.y * 0.5)
	draw_rect(rect_bottom, Color(COLOR_BG_END.r, COLOR_BG_END.g, COLOR_BG_END.b, 0.45), true)
	
	# Layer 1: Ambient glowing pastel glass orbs (bubbles)
	var time_val = bg_time * 0.25
	var bubble_offset = cursor_offset * 0.35
	
	# Violet Bubble
	var v_pos = Vector2(
		size.x * 0.2 + sin(time_val) * 40.0,
		size.y * 0.3 + cos(time_val) * 45.0
	) + bubble_offset
	draw_circle(v_pos, size.x * 0.38, Color(0.85, 0.78, 0.95, 0.22))
	
	# Rose Pink Bubble
	var r_pos = Vector2(
		size.x * 0.8 + cos(time_val * 1.2) * 50.0,
		size.y * 0.45 + sin(time_val * 0.8) * 35.0
	) + bubble_offset
	draw_circle(r_pos, size.x * 0.35, Color(0.96, 0.76, 0.88, 0.18))
	
	# Soft Blue Bubble
	var b_pos = Vector2(
		size.x * 0.35 + sin(time_val * 0.9 + 1.0) * 35.0,
		size.y * 0.8 + cos(time_val * 1.1) * 60.0
	) + bubble_offset
	draw_circle(b_pos, size.x * 0.3, Color(0.78, 0.88, 0.96, 0.15))
	
	# Layer 2: Hanging decorative diamonds on thin threads (REQ-MENU-012)
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
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")

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

func _update_settings_labels() -> void:
	sound_button.text = "Sound: ON" if UserData.sound_enabled else "Sound: OFF"
	music_button.text = "Music: ON" if UserData.music_enabled else "Music: OFF"
	if quality_button:
		quality_button.text = "Quality: High (Glow)" if UserData.quality_profile == "web_default" else "Quality: Mobile (72% Glow)"
	if export_button:
		export_button.text = "Export Test Logs"
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
	var summary := UserData.get_retention_summary()
	if subtitle_label:
		subtitle_label.text = "🔥 Streak: %d days • %d/%d Level Cleared" % [
			int(summary.get("daily_streak", 0)),
			int(summary.get("completed_levels", 0)),
			maxi(LevelLoader.get_available_level_count(), 1)
		]

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
	
	func _ready() -> void:
		set_process(true)
		
	func _process(delta: float) -> void:
		rot_angle += delta * 0.35
		pulse_timer += delta * 1.5
		queue_redraw()
		
	func _draw() -> void:
		var center = size * 0.5
		var pulse = 1.0 + sin(pulse_timer) * 0.024
		var base_radius = 115.0 * pulse
		
		# 1. Shadow Pedestal under Sphere
		var ped_center = center + Vector2(0, 115)
		var ped_size = Vector2(140, 20)
		var ped_pts = PackedVector2Array()
		var steps = 36
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			ped_pts.append(ped_center + Vector2(cos(a) * ped_size.x, sin(a) * ped_size.y))
		draw_polygon(ped_pts, [Color(0.72, 0.65, 0.82, 0.28)])
		
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
		draw_polyline(orbit_pts, Color(1.0, 1.0, 1.0, 0.4), 1.6)
		
		# Orbit Sparkle
		var sp_pt = orbit_pts[int(steps * 0.28)]
		draw_circle(sp_pt, 4.0, Color.WHITE)
		draw_line(sp_pt - Vector2(8, 0), sp_pt + Vector2(8, 0), Color.WHITE, 1.0)
		draw_line(sp_pt - Vector2(0, 8), sp_pt + Vector2(0, 8), Color.WHITE, 1.0)
		
		# 3. Orb Base sphere
		draw_circle(center, base_radius, Color(0.96, 0.94, 1.0, 0.65))
		
		# 4. Multi-layered moving Pastel aurora gradients
		var aurora_layers = [
			{"color": Color(1.0, 0.74, 0.84, 0.36), "speed": 1.0, "scale": 0.85, "phase": 0.0}, # Pink
			{"color": Color(0.74, 0.84, 1.0, 0.34), "speed": -0.8, "scale": 0.80, "phase": 2.1}, # Blue
			{"color": Color(0.80, 0.98, 0.85, 0.26), "speed": 1.2, "scale": 0.75, "phase": 1.2}, # Mint
			{"color": Color(1.0, 0.92, 0.76, 0.28), "speed": -0.6, "scale": 0.90, "phase": 3.4} # Gold
		]
		
		for layer in aurora_layers:
			var ang = rot_angle * layer["speed"] + layer["phase"]
			var offset = Vector2(cos(ang), sin(ang)) * (base_radius * 0.16)
			draw_circle(center + offset, base_radius * layer["scale"], layer["color"])
			
		# 5. Glossy 3D Highlight specular flare (top-left)
		var specular_pos = center - Vector2(base_radius * 0.34, base_radius * 0.34)
		draw_circle(specular_pos, base_radius * 0.26, Color(1.0, 1.0, 1.0, 0.75))
		draw_circle(specular_pos - Vector2(base_radius * 0.05, base_radius * 0.05), base_radius * 0.12, Color.WHITE)

class IconDrawerScript extends Control:
	var icon_type: String = ""
	var color: Color = Color.WHITE
	
	func _draw() -> void:
		var center = size * 0.5
		draw_set_transform(center, 0.0, Vector2.ONE)
		
		match icon_type:
			"levels":
				# Render beautiful list bullet layout
				var line_w = 26
				var line_h = 3.5
				draw_rect(Rect2(-line_w/2, -10, line_w, line_h), color, true)
				draw_rect(Rect2(-line_w/2, -2, line_w, line_h), color, true)
				draw_rect(Rect2(-line_w/2, 6, line_w, line_h), color, true)
				
				# Small indicator dots
				draw_circle(Vector2(-line_w/2 - 7, -8.2), 2.5, color)
				draw_circle(Vector2(-line_w/2 - 7, -0.2), 2.5, color)
				draw_circle(Vector2(-line_w/2 - 7, 7.8), 2.5, color)
				
			"events":
				# Draw beautiful golden cup (trophy)
				var cup_poly = PackedVector2Array([
					Vector2(-12, -14), Vector2(12, -14),
					Vector2(10, 0), Vector2(-10, 0)
				])
				draw_polygon(cup_poly, [color])
				
				# Cup handles
				draw_arc(Vector2(-10, -7), 5.0, -PI/2, PI/2, 16, color, 2.0)
				draw_arc(Vector2(10, -7), 5.0, PI/2, 3*PI/2, 16, color, 2.0)
				
				# Cup stand
				draw_rect(Rect2(-3, 0, 6, 10), color, true) # stem
				draw_rect(Rect2(-12, 10, 24, 4), color, true) # base
				
			"shop":
				# Draw beautiful shopping cart
				draw_line(Vector2(-15, -12), Vector2(-10, -12), color, 2.2) # bar handle
				draw_line(Vector2(-10, -12), Vector2(-5, 6), color, 2.2) # back wall
				draw_line(Vector2(-5, 6), Vector2(12, 6), color, 2.2) # bottom
				draw_line(Vector2(12, 6), Vector2(16, -6), color, 2.2) # front wall
				draw_line(Vector2(16, -6), Vector2(-7, -6), color, 2.2) # top front wall
				
				# Wheels
				draw_circle(Vector2(-2, 11), 3.2, color)
				draw_circle(Vector2(9, 11), 3.2, color)
				
			"settings":
				# Draw beautiful cogwheel configuration
				draw_circle(Vector2.ZERO, 7.5, color)
				# Cog teeth
				var teeth = 8
				for i in range(teeth):
					var a = float(i) / teeth * TAU
					var p1 = Vector2(cos(a), sin(a)) * 7.0
					var p2 = Vector2(cos(a), sin(a)) * 12.5
					draw_line(p1, p2, color, 3.2)
				# Inner clear circle hole
				draw_circle(Vector2.ZERO, 3.8, Color(1.0, 1.0, 1.0, 0.0))
