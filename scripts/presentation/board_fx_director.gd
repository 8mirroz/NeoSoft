extends RefCounted
class_name BoardFxDirector

var _board_view: Control # Dynamic BoardView
var _visual_generation: int = 0

func setup(board_view: Control) -> void:
	_board_view = board_view

func cancel_previous_sequences() -> void:
	_visual_generation += 1
	_board_view.set("_visual_generation", _visual_generation)

func start_processing_queue() -> void:
	if _board_view.get("is_processing_queue"):
		return
	_board_view.set("is_processing_queue", true)
	process_next_visual_event()

func process_next_visual_event() -> void:
	var queue: Array = _board_view.get("visual_queue")
	if queue.is_empty():
		_board_view.set("is_processing_queue", false)
		_board_view.set("combo_index", 0) # Reset combo index when the cascade terminates
		return

	var current_gen: int = _visual_generation
	var event: Dictionary = queue.pop_front()
	
	match event.get("type", ""):
		"match":
			var combo: int = _board_view.get("combo_index") + 1
			_board_view.set("combo_index", combo)
			
			# Play cascade pop sound exactly once per match step with combo pitch shift
			SoundManager.play_cascade(combo)
			
			# 1. Combo Screen Shake
			apply_screen_shake(combo)
			
			# 2. Combo Floating Neon Label
			if combo >= 2:
				_spawn_combo_label(combo)
			
			# 3. Populate match_pop_fx and spawn particles
			var matches: Array = event.get("data", [])
			var metrics: Dictionary = _board_view.call("_get_board_metrics")
			var cell_size_val: float = metrics["cell_size"]
			var board_model: RefCounted = _board_view.get("board_model")
			
			var match_pop_fx: Array = _board_view.get("match_pop_fx")
			var active_connection_threads: Array = _board_view.get("active_connection_threads")
			
			# Collect all matched cells to mark in visual snapshot BEFORE animation
			var all_matched_cells: Array = []
			
			for match_data in matches:
				var piece_id: int = int(match_data.get("piece_id", 0))
				var cells: Array = match_data.get("cells", [])
				var palette_data: Dictionary = _board_view.call("_get_palette", piece_id)
				var match_color: Color = palette_data["accent"]
				
				# Generate glowing threads connecting adjacent matched cells
				for idx in range(cells.size() - 1):
					active_connection_threads.append({
						"from": _board_view.call("_get_cell_center", cells[idx]),
						"to": _board_view.call("_get_cell_center", cells[idx + 1]),
						"age": 0.0,
						"color": match_color
					})
				
				for cell_variant in cells:
					var cell: Vector2i = cell_variant
					if board_model != null and not board_model.call("is_in_bounds", cell):
						continue
					
					all_matched_cells.append(cell)
					
					match_pop_fx.append({
						"cell": cell,
						"piece_id": piece_id,
						"age": 0.0,
					})
					
					# Spawn a temporary GemView to animate premium scene-based matched gems dissolving
					var temp_gem := GemView.new()
					temp_gem.size = cell_size_val
					temp_gem.set_piece(piece_id)
					temp_gem.set_sphere_type(SphereFactory.get_sphere_type_for_piece(piece_id))
					temp_gem.position = _board_view.call("_get_cell_center", cell)
					_board_view.add_child(temp_gem)
					
					var t_tween: Tween = _board_view.create_tween().set_parallel(true)
					t_tween.tween_property(temp_gem, "custom_scale", Vector2.ZERO, _board_view.get("MATCH_POP_DURATION"))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					t_tween.tween_property(temp_gem, "modulate:a", 0.0, _board_view.get("MATCH_POP_DURATION") * 0.8)\
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					t_tween.tween_property(temp_gem, "rotation", randf_range(-PI * 0.8, PI * 0.8), _board_view.get("MATCH_POP_DURATION"))\
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					t_tween.chain().tween_callback(temp_gem.queue_free)
					
					# Spawn procedural stylized VFX particles for this gem type
					_spawn_unique_vfx(_board_view.call("_get_cell_center", cell), piece_id)
			
			# Mark matched cells in visual snapshot — hides pool gems, temp gems handle dissolve
			_board_view.call("apply_visual_clear", all_matched_cells)
			
			_board_view.queue_redraw()
			# Wait for match pop duration (0.38s) + cascade pause phase (0.25s)
			if _board_view.is_inside_tree():
				await _board_view.get_tree().create_timer(_board_view.get("MATCH_POP_DURATION") + 0.25).timeout
			
			# After clear animation finishes, commit removal to visual snapshot
			_board_view.call("commit_visual_removal")
			
		"collapse":
			var movements: Array = event.get("data", [])
			var collapse_fx: Array = _board_view.get("collapse_fx")
			var gem_offsets: Dictionary = _board_view.get("gem_offsets")
			
			# Update visual snapshot: move gems from old to new positions
			# This updates GemPool so it shows gems at their new logical positions,
			# while gem_offsets create the visual "falling from above" effect.
			_board_view.call("apply_visual_collapse", movements)
			
			for movement in movements:
				var from: Vector2i = movement.get("from", Vector2i.ZERO)
				var to_cell: Vector2i = movement.get("to", Vector2i.ZERO)
				var pos_from: Vector2 = _board_view.call("_get_cell_center", from)
				var pos_to: Vector2 = _board_view.call("_get_cell_center", to_cell)
				
				# Offset the falling gem back to its visual starting cell
				gem_offsets[to_cell] = pos_from - pos_to
				
				var piece_id: int = 0
				if movement.has("piece_id"):
					piece_id = int(movement["piece_id"])
				else:
					# Read from visual snapshot (already updated by apply_visual_collapse)
					piece_id = _board_view.call("get_visual_piece", to_cell)
					if piece_id < 0:
						piece_id = 0
				
				collapse_fx.append({
					"piece_id": piece_id,
					"from": from,
					"to": to_cell,
					"age": 0.0,
				})
			
			_board_view.queue_redraw()
			# Wait for collapse duration (0.28s)
			if _board_view.is_inside_tree():
				await _board_view.get_tree().create_timer(_board_view.get("FALL_TRAIL_DURATION")).timeout
			
		"spawn":
			var spawns: Array = event.get("data", [])
			var metrics: Dictionary = _board_view.call("_get_board_metrics")
			var cell_size: float = metrics["cell_size"]
			
			var gem_scales: Dictionary = _board_view.get("gem_scales")
			var gem_scale_velocities: Dictionary = _board_view.get("gem_scale_velocities")
			var gem_alphas: Dictionary = _board_view.get("gem_alphas")
			var gem_offsets: Dictionary = _board_view.get("gem_offsets")
			var spawn_fx: Array = _board_view.get("spawn_fx")
			
			# Update visual snapshot with new spawned gems
			# Gems will appear in GemPool but start with alpha=0 and scale=0 for smooth reveal
			_board_view.call("apply_visual_spawn", spawns)
			
			for spawn in spawns:
				var cell: Vector2i = spawn.get("to", spawn.get("position", Vector2i.ZERO))
				gem_scales[cell] = Vector2.ZERO
				gem_scale_velocities[cell] = Vector2.ZERO
				gem_alphas[cell] = 0.0
				gem_offsets[cell] = Vector2(0, -cell_size * 1.5)
				
				var piece_id: int = 0
				if spawn.has("piece_id"):
					piece_id = int(spawn["piece_id"])
				elif spawn.has("gem_type"):
					var gem_str = spawn["gem_type"]
					match gem_str:
						"red": piece_id = 0
						"blue": piece_id = 1
						"green": piece_id = 2
						"yellow": piece_id = 3
						"purple": piece_id = 4
						"white": piece_id = 5
						_:
							if gem_str.is_valid_int():
								piece_id = gem_str.to_int()
				
				spawn_fx.append({
					"piece_id": piece_id,
					"cell": cell,
					"age": 0.0,
				})
			
			_board_view.queue_redraw()
			# Wait for spawn duration (0.34s) + refill pause phase (0.15s)
			if _board_view.is_inside_tree():
				await _board_view.get_tree().create_timer(_board_view.get("SPAWN_REVEAL_DURATION") + 0.15).timeout

	# Check cancellation token before proceeding to the next event
	if current_gen != _visual_generation:
		return

	# Proceed to the next visual event in the queue
	process_next_visual_event()

func apply_screen_shake(combo: float) -> void:
	if combo < 2.0:
		_board_view.set("screen_shake_amplitude", 0.0)
		return
	
	var max_shake: float = _board_view.get("max_screen_shake_amplitude")
	var shake: float = min(4.0 + combo * 2.5, max_shake)
	_board_view.set("screen_shake_amplitude", shake)

func _spawn_combo_label(combo: int) -> void:
	if not _board_view.is_inside_tree():
		return
	var label := Label.new()
	label.name = "ComboLabel_%d" % combo
	var text_val := ""
	var color_val := Color(0.78, 0.58, 1.0) # Purple fallback
	
	match combo:
		2:
			text_val = "★ NICE COMBO x2 ★"
			color_val = Color(0.45, 0.88, 1.0) # Radiant Cyan
		3:
			text_val = "✦ SPECTACULAR x3 ✦"
			color_val = Color(0.85, 0.62, 1.0) # Luminous Amethyst
		4:
			text_val = "🔥 CASCADE SURGE x4 🔥"
			color_val = Color(0.98, 0.52, 0.65) # Electric Pink
		_:
			text_val = "👑 UNSTOPPABLE x" + str(combo) + " 👑"
			color_val = Color(1.0, 0.84, 0.32) # Gold Aurora
			
	label.text = text_val
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(200, 30) # Center pivot for scale tween bounce
	label.custom_minimum_size = Vector2(400, 60)
	
	# Center it horizontally on the board frame and offset upwards
	label.position = (_board_view.size - Vector2(400, 60)) * 0.5 + Vector2(0, -90.0)
	
	# Ultra premium glassmorphic frosted style box
	var glass_style := StyleBoxFlat.new()
	glass_style.bg_color = Color(0.08, 0.06, 0.14, 0.86)
	glass_style.border_color = color_val.lightened(0.18)
	glass_style.border_width_left = 2
	glass_style.border_width_top = 2
	glass_style.border_width_right = 2
	glass_style.border_width_bottom = 2
	glass_style.corner_radius_top_left = 30
	glass_style.corner_radius_top_right = 30
	glass_style.corner_radius_bottom_right = 30
	glass_style.corner_radius_bottom_left = 30
	glass_style.shadow_color = Color(color_val.r, color_val.g, color_val.b, 0.46)
	glass_style.shadow_size = 20
	glass_style.shadow_offset = Vector2(0, 4)
	glass_style.content_margin_left = 24
	glass_style.content_margin_right = 24
	
	label.set("theme_override_styles/normal", glass_style)
	
	# High-contrast glowing text styling
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", color_val)
	label.add_theme_constant_override("outline_size", 8)
	
	_board_view.add_child(label)
	
	# Sparkle particle burst at the combo popup location
	var particles := CPUParticles2D.new()
	particles.position = label.position + Vector2(200, 30)
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.90
	particles.lifetime = 0.65
	
	var budget: RefCounted = _board_view.get("_power_profile")
	var base_amount: int = 14
	if budget != null and budget.has_method("get_particle_amount"):
		particles.amount = budget.call("get_particle_amount", base_amount)
	else:
		particles.amount = base_amount
		
	particles.spread = 180.0
	particles.gravity = Vector2(0, 80.0)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.5
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, color_val, Color(color_val.r, color_val.g, color_val.b, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	particles.color_ramp = grad
	_board_view.add_child(particles)
	
	# Animated Spring pop up and slow rise Tween
	label.scale = Vector2.ZERO
	var tween: Tween = _board_view.create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var fade_tween: Tween = _board_view.create_tween()
	fade_tween.tween_interval(0.85)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.3)
	
	tween.finished.connect(label.queue_free)
	_board_view.get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

func _spawn_unique_vfx(vfx_center: Vector2, piece_id: int) -> void:
	if not _board_view.is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.position = vfx_center
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.lifetime = 0.55
	
	var gem_type: int = wrapi(piece_id, 0, 8)
	var palette: Dictionary = _board_view.call("_get_palette", gem_type)
	var accent: Color = palette["accent"]
	var glow: Color = palette["glow"]
	
	# Base configuration
	var base_amount: int = 16
	var budget: RefCounted = _board_view.get("_power_profile")
	if budget != null and budget.has_method("get_particle_amount"):
		particles.amount = budget.call("get_particle_amount", base_amount)
	else:
		particles.amount = base_amount
		
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 3.5
	particles.scale_amount_max = 7.0
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color.WHITE,
		accent,
		Color(glow.r, glow.g, glow.b, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	particles.color_ramp = grad
	
	# Sphere-specific particle physics (REQ-VFX-009)
	match gem_type:
		0: # Pink Pearl: Star dust (expanding stars)
			particles.amount = particles.amount + 4
			particles.direction = Vector2.DOWN
			particles.initial_velocity_min = 40.0
			particles.radial_accel_min = 20.0
			particles.radial_accel_max = 40.0
			
		1: # Blue Flow: Splash drops (water drops with gravity)
			particles.gravity = Vector2(0, 150.0)
			particles.initial_velocity_min = 80.0
			particles.initial_velocity_max = 180.0
			particles.damping_min = 30.0
			particles.damping_max = 60.0
			
		2: # Ice Spark: Sharp ice splinters (high speed shards)
			particles.amount = particles.amount - 2
			particles.initial_velocity_min = 120.0
			particles.initial_velocity_max = 220.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 5.0
			particles.damping_min = 120.0
			
		3: # Frost Pearl: Rising bubbles
			particles.gravity = Vector2(0, -90.0)
			particles.spread = 120.0
			particles.initial_velocity_min = 30.0
			particles.initial_velocity_max = 80.0
			particles.scale_amount_min = 4.0
			particles.scale_amount_max = 8.0
			
		4: # Mint Shiver: Energy rays (fast horizontal spikes)
			particles.spread = 60.0
			particles.initial_velocity_min = 110.0
			particles.initial_velocity_max = 190.0
			particles.damping_min = 90.0
			
		5: # Gold Aurora: Warm sparks (heavy circular expansion)
			particles.amount = particles.amount + 6
			particles.initial_velocity_min = 50.0
			particles.initial_velocity_max = 100.0
			particles.linear_accel_min = -20.0
			
		6: # Amethyst Haze: Expansion rings (spin particles)
			particles.angular_velocity_min = 180.0
			particles.angular_velocity_max = 360.0
			particles.damping_min = 40.0
			
		7: # Rose Glow: Spiral rose vortex
			particles.amount = particles.amount + 2
			particles.radial_accel_min = -40.0
			particles.radial_accel_max = -20.0
			particles.angular_velocity_min = 90.0
			particles.angular_velocity_max = 180.0

	_board_view.add_child(particles)
	
	var timer: SceneTreeTimer = _board_view.get_tree().create_timer(particles.lifetime + 0.1)
	timer.timeout.connect(particles.queue_free)

func clear_visual_transients() -> void:
	var gem_offsets: Dictionary = _board_view.get("gem_offsets")
	var gem_scales: Dictionary = _board_view.get("gem_scales")
	var gem_scale_velocities: Dictionary = _board_view.get("gem_scale_velocities")
	var gem_alphas: Dictionary = _board_view.get("gem_alphas")
	
	gem_offsets.clear()
	gem_scales.clear()
	gem_scale_velocities.clear()
	gem_alphas.clear()

	for child in _board_view.get_children():
		if child is CPUParticles2D or child.name.begins_with("ComboLabel"):
			child.queue_free()
