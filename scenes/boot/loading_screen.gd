extends PremiumScreen

var _progress: ProgressBar
var _start_button: Button

# Atmospheric sway and parallax configurations
var bg_time: float = 0.0
var cursor_offset: Vector2 = Vector2.ZERO
var hanging_diamonds: Array = []
var _bubbles: Array = []
var _orb_rect: TextureRect
var _pedestal: Control

func _ready() -> void:
	queue_redraw()
	
	# Initialise hanging crystal configurations
	hanging_diamonds = [
		{"x_ratio": 0.08, "length": 250.0, "size": 18.0, "phase": 0.0, "speed": 1.2},
		{"x_ratio": 0.14, "length": 180.0, "size": 14.0, "phase": 1.5, "speed": 1.5},
		{"x_ratio": 0.86, "length": 200.0, "size": 16.0, "phase": 0.7, "speed": 1.3},
		{"x_ratio": 0.92, "length": 280.0, "size": 20.0, "phase": 2.2, "speed": 1.0}
	]
	
	# 1. Background Smooth Gradient (GPU-accelerated, zero-banding)
	var bg_rect := TextureRect.new()
	bg_rect.name = "BackgroundGradient"
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.anchors_preset = Control.PRESET_FULL_RECT
	bg_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var gradient := Gradient.new()
	var top_color := token_color("shared.colors.bg_top", Color("#F3ECFB"))
	var bottom_color := token_color("shared.colors.bg_bottom", Color("#EAF1FF"))
	gradient.colors = PackedColorArray([top_color, bottom_color])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	bg_rect.texture = grad_tex
	add_child(bg_rect)
	
	# 2. Background Atmosphere Container (for floating bubbles)
	var atmosphere := Control.new()
	atmosphere.name = "BackgroundAtmosphere"
	atmosphere.anchors_preset = Control.PRESET_FULL_RECT
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)
	
	# Dynamic floating background bubbles with refraction shader
	var bubble_data := [
		{"pos_ratio": Vector2(0.18, 0.28), "scale": 0.32, "alpha": 0.60, "sway_speed": 0.7, "sway_amount": 22.0},
		{"pos_ratio": Vector2(0.82, 0.64), "scale": 0.28, "alpha": 0.52, "sway_speed": 0.9, "sway_amount": 16.0},
		{"pos_ratio": Vector2(0.12, 0.76), "scale": 0.16, "alpha": 0.45, "sway_speed": 1.3, "sway_amount": 10.0},
		{"pos_ratio": Vector2(0.78, 0.22), "scale": 0.22, "alpha": 0.50, "sway_speed": 0.8, "sway_amount": 14.0},
		{"pos_ratio": Vector2(0.88, 0.42), "scale": 0.14, "alpha": 0.40, "sway_speed": 1.1, "sway_amount": 12.0},
	]
	
	var bubble_texture = load("res://assets/spheres/02_clear_glass/02_clear_glass_base.png")
	var bubble_shader = load("res://shaders/black_cutout.gdshader")
	
	for b in bubble_data:
		var sprite := Sprite2D.new()
		sprite.texture = bubble_texture
		sprite.scale = Vector2(b["scale"], b["scale"])
		sprite.modulate = Color(1, 1, 1, b["alpha"])
		
		# Black removal + rim glow material
		var s_mat := ShaderMaterial.new()
		s_mat.shader = bubble_shader
		s_mat.set_shader_parameter("tint_color", Color(0.95, 0.98, 1.0, 0.0))
		s_mat.set_shader_parameter("brightness_threshold", 0.04)
		s_mat.set_shader_parameter("transition_softness", 0.28)
		s_mat.set_shader_parameter("rim_boost", 1.6)
		sprite.material = s_mat
		
		atmosphere.add_child(sprite)
		_bubbles.append({
			"sprite": sprite,
			"pos_ratio": b["pos_ratio"],
			"base_scale": b["scale"],
			"sway_speed": b["sway_speed"],
			"sway_amount": b["sway_amount"],
			"phase": randf() * TAU
		})
	
	# Main layout container
	var center := VBoxContainer.new()
	center.anchor_left = 0.12
	center.anchor_top = 0.10
	center.anchor_right = 0.88
	center.anchor_bottom = 0.92
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	# 3. Premium Beveled Header Title with Soft Outline & Dropshadow
	var title_container := VBoxContainer.new()
	title_container.add_theme_constant_override("separation", 4)
	center.add_child(title_container)

	var title := Label.new()
	title.text = "Neo\nSoft Frost"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color("#FAF6FF")) # Crisp off-white glow
	title.add_theme_color_override("font_outline_color", Color("#A395F7")) # Deep soft lavender
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_shadow_color", Color("#7E6AF255")) # Transparent violet shadow
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title_container.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "Match the magic. Restore the light."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("#BDB0FC")) # Lavender text
	subtitle.add_theme_color_override("font_shadow_color", Color("#7E6AF226"))
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	title_container.add_child(subtitle)
	
	# Spacer
	var sp_sep = Control.new()
	sp_sep.custom_minimum_size = Vector2(0, 8)
	center.add_child(sp_sep)

	# 4. Centerpiece Orb Container & Pedestal
	var orb_container = Control.new()
	orb_container.custom_minimum_size = Vector2(280, 280)
	orb_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(orb_container)

	# Transparent glass concentric rings pedestal
	_pedestal = PedestalDraw.new()
	_pedestal.name = "Pedestal"
	_pedestal.anchors_preset = Control.PRESET_FULL_RECT
	orb_container.add_child(_pedestal)

	# High-fidelity Iridescent centerpiece sphere TextureRect
	_orb_rect = TextureRect.new()
	_orb_rect.name = "CenterpieceOrb"
	_orb_rect.texture = load("res://assets/spheres/01_iridescent_frost/01_iridescent_frost_base.png")
	_orb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_orb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Position in center
	_orb_rect.custom_minimum_size = Vector2(230, 230)
	_orb_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_orb_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_orb_rect.anchors_preset = Control.PRESET_CENTER
	_orb_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_orb_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Apply black_cutout shader with HIGH rim_boost — removes black, keeps chromatic glass ring
	var orb_material := ShaderMaterial.new()
	orb_material.shader = load("res://shaders/black_cutout.gdshader")
	orb_material.set_shader_parameter("tint_color", Color(0.96, 0.92, 1.0, 0.0)) # no forced tint
	orb_material.set_shader_parameter("brightness_threshold", 0.03)
	orb_material.set_shader_parameter("transition_softness", 0.28)
	orb_material.set_shader_parameter("rim_boost", 1.8) # Boost the chromatic iridescent rim
	_orb_rect.material = orb_material
	orb_container.add_child(_orb_rect)

	# 5. Frosted Glassmorphism Panel ("card")
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0, 0.07) # Frosted translucent body
	card_style.border_color = Color(1.0, 1.0, 1.0, 0.28) # Crisp white glass boundary
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 32
	card_style.corner_radius_top_right = 32
	card_style.corner_radius_bottom_left = 32
	card_style.corner_radius_bottom_right = 32
	card_style.shadow_color = Color(0.44, 0.38, 0.69, 0.12) # Soft ambient glow
	card_style.shadow_size = 22
	card_style.shadow_offset = Vector2(0, 5)
	card_style.content_margin_left = 24
	card_style.content_margin_top = 20
	card_style.content_margin_right = 24
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(400, 130)
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	
	var message := Label.new()
	message.text = "Preparing glass spheres"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", Color("#B0A6D6")) # Soft lavender text
	message.add_theme_font_size_override("font_size", 14)
	content.add_child(message)
	
	# Glass capsule progress bar with Horizontal Gradient Filling
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.max_value = 100
	_progress.custom_minimum_size = Vector2(0, 16)
	
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	pb_bg.border_color = Color(1.0, 1.0, 1.0, 0.14)
	pb_bg.border_width_left = 1
	pb_bg.border_width_top = 1
	pb_bg.border_width_right = 1
	pb_bg.border_width_bottom = 1
	pb_bg.corner_radius_top_left = 8
	pb_bg.corner_radius_top_right = 8
	pb_bg.corner_radius_bottom_left = 8
	pb_bg.corner_radius_bottom_right = 8
	_progress.add_theme_stylebox_override("bg", pb_bg)
	
	var pb_fg := StyleBoxTexture.new()
	var pb_grad := Gradient.new()
	pb_grad.colors = PackedColorArray([
		Color("#5CE1E6"), # Cyan
		Color("#8D7AF8"), # Purple
		Color("#FF7BEA"), # Pink
		Color("#FFBD59")  # Yellow
	])
	pb_grad.offsets = PackedFloat32Array([0.0, 0.35, 0.70, 1.0])
	
	var pb_grad_tex := GradientTexture2D.new()
	pb_grad_tex.gradient = pb_grad
	pb_grad_tex.fill_from = Vector2(0.0, 0.5)
	pb_grad_tex.fill_to = Vector2(1.0, 0.5)
	
	pb_fg.texture = pb_grad_tex
	_progress.add_theme_stylebox_override("fill", pb_fg)
	content.add_child(_progress)
	
	# Sleek floating pulsing start text button
	_start_button = make_button("✦ Tap to Start ✦", &"loading.start", _on_start_pressed, true)
	_start_button.disabled = true
	
	var btn_style_normal := StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(1, 1, 1, 0)
	var btn_style_hover := StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(1, 1, 1, 0.05)
	btn_style_hover.corner_radius_top_left = 12
	btn_style_hover.corner_radius_top_right = 12
	btn_style_hover.corner_radius_bottom_left = 12
	btn_style_hover.corner_radius_bottom_right = 12
	
	_start_button.add_theme_stylebox_override("normal", btn_style_normal)
	_start_button.add_theme_stylebox_override("hover", btn_style_hover)
	_start_button.add_theme_stylebox_override("pressed", btn_style_normal)
	_start_button.add_theme_stylebox_override("disabled", btn_style_normal)
	
	_start_button.add_theme_color_override("font_color", Color("#B6A7FE"))
	_start_button.add_theme_color_override("font_hover_color", Color("#FAF6FF"))
	_start_button.add_theme_color_override("font_pressed_color", Color("#8D7AF8"))
	_start_button.add_theme_color_override("font_disabled_color", Color("#6D6788"))
	_start_button.add_theme_font_size_override("font_size", 18)
	
	content.add_child(_start_button)
	
	_load_manifest()
	set_process(true)

func _process(delta: float) -> void:
	bg_time += delta
	
	# Gentle cursor-parallax movement
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := size
	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2(720, 1280)
	var screen_center := screen_size * 0.5
	var target_offset := (mouse_pos - screen_center) * -0.04
	cursor_offset = cursor_offset.lerp(target_offset, delta * 3.0)
	
	# Animate background floating bubbles
	for b in _bubbles:
		var spr: Sprite2D = b["sprite"]
		var phase: float = b["phase"] + bg_time * b["sway_speed"]
		var offset := Vector2(
			sin(phase) * b["sway_amount"],
			cos(phase * 1.4) * b["sway_amount"]
		)
		var base_pos := Vector2(b["pos_ratio"].x * screen_size.x, b["pos_ratio"].y * screen_size.y)
		spr.position = base_pos + offset + cursor_offset * 0.40
		
		# Bubble scale breathing
		var pulse_scale = b["base_scale"] * (1.0 + sin(phase * 1.8) * 0.04)
		spr.scale = Vector2(pulse_scale, pulse_scale)
		
	# Animate central sphere breathing and rotation
	if is_instance_valid(_orb_rect):
		var orb_pulse = 1.0 + sin(bg_time * 1.8) * 0.018
		_orb_rect.scale = Vector2(orb_pulse, orb_pulse)
		# Slow rotation
		_orb_rect.rotation = bg_time * 0.03
		
	queue_redraw()

func _load_manifest() -> void:
	var progress := 10.0
	var manifest_path := "res://data/assets/asset_manifest.json"
	if FileAccess.file_exists(manifest_path):
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			for category in parsed.get("assets", {}).values():
				for path in category.values():
					if String(path).is_empty() or ResourceLoader.exists(String(path)):
						progress += 8.0
	_progress.value = min(progress, 100.0)
	await get_tree().create_timer(0.42).timeout
	_progress.value = 100.0
	_start_button.disabled = false
	
	# Pulse animation for start text when ready
	var tween := _start_button.create_tween().set_loops()
	tween.tween_property(_start_button, "modulate:a", 0.45, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_start_button, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_start_pressed() -> void:
	route(&"main_menu")

func _draw() -> void:
	# Note: Vertical gradient and bubbles are drawn via TextureRect/Sprite2D nodes for zero-banding and refraction.
	
	# Draw hanging crystals sway threads and 3D beveled diamond meshes
	for dia in hanging_diamonds:
		var x_pos = dia["x_ratio"] * size.x + cursor_offset.x * 0.5
		var length = dia["length"]
		var phase = dia["phase"] + bg_time * dia["speed"]
		var sway_angle = sin(phase) * 0.04
		
		var line_start = Vector2(x_pos, 0.0)
		var line_end = Vector2(
			x_pos + sin(sway_angle) * length,
			cos(sway_angle) * length
		)
		
		# Draw the thin hanging cord
		draw_line(line_start, line_end, Color("#A395F777"), 1.0)
		
		var dia_size = dia["size"]
		var pts = [
			line_end + Vector2(0, -dia_size),
			line_end + Vector2(dia_size * 0.7, 0),
			line_end + Vector2(0, dia_size),
			line_end + Vector2(-dia_size * 0.7, 0)
		]
		
		var pulse_color = Color(1.0, 1.0, 1.0, 0.28)
		pulse_color.a = 0.28 + sin(phase * 1.5) * 0.08
		
		# Flat translucent base shape
		draw_polygon(pts, [pulse_color])
		
		# Glowing outer boundary
		draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.52), 1.2)
		
		# Craft elegant inner facet lines to make the diamond look premium and faceted (3D look)
		var facet_color := Color(1.0, 1.0, 1.0, 0.38)
		draw_line(line_end + Vector2(0, -dia_size), line_end + Vector2(0, dia_size), facet_color, 1.0)
		draw_line(line_end + Vector2(-dia_size * 0.7, 0), line_end + Vector2(dia_size * 0.7, 0), facet_color, 0.8)

# Custom nested control for procedural glass concentric pedestal
class PedestalDraw extends Control:
	func _draw() -> void:
		var center = size * 0.5 + Vector2(0, 115) # Offset to bottom of orb
		var steps = 40
		var boundary_color := Color(1.0, 1.0, 1.0, 0.38)
		var fill_color := Color(1.0, 1.0, 1.0, 0.07)
		
		# Draw three concentric ellipses
		for scale_fac in [1.0, 0.82, 0.64]:
			var rx = 120.0 * scale_fac
			var ry = 18.0 * scale_fac
			var pts = PackedVector2Array()
			for i in range(steps + 1):
				var a = float(i) / steps * TAU
				pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
			
			draw_polygon(pts, [fill_color])
			draw_polyline(pts, boundary_color, 1.5)
