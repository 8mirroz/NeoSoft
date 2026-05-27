extends PremiumScreen

# Floating tooltip for active level
var time_passed: float = 0.0
var active_node: Control = null

func _ready() -> void:
	var body := setup_screen("World Map", "Pearl Nebula - choose your next crystal path", &"world", true)
	
	# Event / Rankings top actions bar
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	
	var events := make_button("Daily Rewards", &"map.events", func() -> void: route(&"daily_rewards"))
	events.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(events)
	
	var ranking := make_button("Rankings", &"nav.rankings", func() -> void: route(&"rankings"))
	ranking.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(ranking)
	
	body.add_child(actions)

	var header := Label.new()
	header.text = "You are here - Level %d" % clampi(UserData.unlocked_level, 1, LevelLoader.get_available_level_count())
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	body.add_child(header)

	# Container for serpentine layout
	var path_container := VBoxContainer.new()
	path_container.add_theme_constant_override("separation", 24)
	path_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(path_container)

	# Serpentine layout node generator
	var levels := LevelLoader.get_available_level_ids()
	for index in range(levels.size()):
		var level_id: int = int(levels[index])
		var unlocked: bool = level_id <= int(UserData.unlocked_level)
		var stars := int(UserData.level_stars.get(level_id, 0))
		
		# Winding offset logic
		# Index shifts: 0 -> Center, 1 -> Right, 2 -> Left, 3 -> Center...
		var shift_type := index % 3
		var horizontal_alignment := BoxContainer.ALIGNMENT_CENTER
		var x_pad := 0.0
		
		match shift_type:
			0:
				horizontal_alignment = BoxContainer.ALIGNMENT_CENTER
			1:
				horizontal_alignment = BoxContainer.ALIGNMENT_END
				x_pad = -60.0
			2:
				horizontal_alignment = BoxContainer.ALIGNMENT_BEGIN
				x_pad = 60.0
				
		var row_container := HBoxContainer.new()
		row_container.alignment = horizontal_alignment
		path_container.add_child(row_container)
		
		# Spacer shift adjustment
		if shift_type == 1: # Right
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(80, 0)
			row_container.add_child(sp)
			
		var node := LevelNodeControl.new()
		node.setup_node(level_id, unlocked, stars, self)
		row_container.add_child(node)
		
		if shift_type == 2: # Left
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(80, 0)
			row_container.add_child(sp)
			
		# Reference to active unlocked level to show floating tooltip
		if level_id == UserData.unlocked_level:
			active_node = node
			
	# Bottom next world lock showcase
	body.add_child(info_card("Next World", "Crystal Vale", "Opens after the soft-launch level set is completed."))
	set_process(true)

func _process(delta: float) -> void:
	time_passed += delta
	if active_node != null and is_instance_valid(active_node):
		# Floating active pointer animation
		active_node.float_offset = sin(time_passed * 3.5) * 5.0

func _open_level_preview(level_id: int) -> void:
	SoundManager.play("open")
	UserData.set_active_level(level_id)
	route(&"level_preview", {"level_id": level_id})

# Custom Node control for glossy level circles
class LevelNodeControl extends Control:
	var level_number: int = 1
	var is_unlocked: bool = false
	var stars_count: int = 0
	var parent_ref: PremiumScreen
	var float_offset: float = 0.0
	
	var is_hovered: bool = false
	var node_button: Button
	
	func setup_node(num: int, unlocked: bool, stars: int, parent: PremiumScreen) -> void:
		level_number = num
		is_unlocked = unlocked
		stars_count = stars
		parent_ref = parent
		custom_minimum_size = Vector2(100, 120)
		
		# Overlay click target
		node_button = Button.new()
		node_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		node_button.flat = true
		node_button.focus_mode = Control.FOCUS_NONE
		node_button.disabled = not is_unlocked
		add_child(node_button)
		
		node_button.mouse_entered.connect(func(): is_hovered = true; queue_redraw())
		node_button.mouse_exited.connect(func(): is_hovered = false; queue_redraw())
		
		node_button.pressed.connect(func():
			parent_ref.call("_open_level_preview", level_number)
		)
		
	func _draw() -> void:
		var center = Vector2(50, 50)
		var base_radius := 40.0
		if is_hovered:
			base_radius = 44.0
			
		# Colors from theme tokens
		var sphere_bg := parent_ref.token_color("shared.colors.glass_bg", Color(1,1,1,0.42))
		var sphere_border := parent_ref.token_color("shared.colors.glass_border", Color(1,1,1,0.72))
		var text_color := parent_ref.token_color("menu.text.title", Color("#312D47"))
		
		if not is_unlocked:
			sphere_bg = sphere_bg.darkened(0.2)
			sphere_bg.a = 0.25
			sphere_border = Color(1,1,1,0.2)
			text_color = text_color.lightened(0.2)
		elif level_number == UserData.unlocked_level:
			# Active highlighted level sphere glows primary brand color
			sphere_bg = parent_ref.token_color("shared.colors.accent_primary", Color("#8D7AF8")).lightened(0.18)
			sphere_bg.a = 0.85
			sphere_border = parent_ref.token_color("shared.colors.accent_primary", Color("#8D7AF8")).lightened(0.35)
			text_color = Color.WHITE
			
		# Shadow under node
		draw_circle(center + Vector2(0, 5), base_radius, parent_ref.token_color("shared.colors.shadow", Color(0,0,0,0.1)))
		
		# Central sphere
		draw_circle(center, base_radius, sphere_bg)
		draw_circle_outline(center, base_radius, sphere_border, 2.0)
		
		# Specular 3D Glossy specular flares
		if is_unlocked:
			var spec_pos = center - Vector2(base_radius * 0.35, base_radius * 0.35)
			var spec_rad = base_radius * 0.22
			draw_circle(spec_pos, spec_rad, Color(1, 1, 1, 0.45))
			draw_circle(spec_pos - Vector2(1,1), spec_rad * 0.5, Color.WHITE)
			
		# Draw Level number
		var num_str := "%02d" % level_number
		var font := ThemeDB.fallback_font
		draw_string(font, center + Vector2(-12, 6), num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, text_color)
		
		# Draw Locked locks
		if not is_unlocked:
			draw_string(font, center + Vector2(-6, 26), "🔒", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, text_color)
		else:
			# Draw 3 stars rating
			var star_y := 104.0
			var star_spacing := 12.0
			var stars_row_x := 50.0 - star_spacing
			for i in range(3):
				var sx = stars_row_x + i * star_spacing
				var star_col = parent_ref.token_color("shared.colors.accent_gold", Color("#E7B446")) if i < stars_count else Color(1, 1, 1, 0.22)
				draw_string(font, Vector2(sx - 5, star_y), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, star_col)
				
		# Draw "You are here" floating pointer tooltip
		if level_number == UserData.unlocked_level:
			var pointer_y = -10.0 + float_offset
			var pts = PackedVector2Array([
				Vector2(44, pointer_y),
				Vector2(56, pointer_y),
				Vector2(50, pointer_y + 8)
			])
			draw_polygon(pts, [parent_ref.token_color("shared.colors.accent_primary", Color("#8D7AF8"))])

	func draw_circle_outline(pos: Vector2, rad: float, col: Color, width: float) -> void:
		var pts = PackedVector2Array()
		var steps = 32
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			pts.append(pos + Vector2(cos(a) * rad, sin(a) * rad))
		draw_polyline(pts, col, width)
