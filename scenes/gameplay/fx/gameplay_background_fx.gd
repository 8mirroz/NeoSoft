extends Control
class_name GameplayBackgroundFX

var _scene: Control
var bg_time: float = 0.0
var background_alpha: float = 1.0
var redraw_hz: float = 30.0
var redraw_accum: float = 0.0

func setup(scene: Control) -> void:
	_scene = scene
	set_process(true)

func apply_quality_profile(profile: Dictionary) -> void:
	background_alpha = float(profile.get("background_effect_alpha", 1.0))
	# Dynamic target redraw frequency (Android safe optimization)
	redraw_hz = float(profile.get("background_redraw_hz", 30.0))
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta: float) -> void:
	bg_time += delta
	redraw_accum += delta
	
	if redraw_accum >= (1.0 / redraw_hz):
		redraw_accum = 0.0
		queue_redraw()

func _draw() -> void:
	if _scene == null:
		return

	# === Layer 0: Premium Opal Pearlescent Base Gradient ===
	var grad_steps := 16
	var step_h := size.y / float(grad_steps)
	for i in range(grad_steps):
		var t := float(i) / float(grad_steps)
		var top_col: Color = _scene.call("_tc", "gameplay.visual.bg_top", "white")
		var bot_col: Color = _scene.call("_tc", "gameplay.visual.bg_bottom", "white")
		var col := top_col.lerp(bot_col, t)
		draw_rect(Rect2(0, i * step_h, size.x, step_h + 1.0), col, true)
	
	# Skip heavy FX overlay layers if the alpha threshold is extremely low (Android ultra battery saver)
	if background_alpha > 0.15:
		# === Layer 1: Slow-drifting atmospheric opal nebulae ===
		var drift1 := Vector2(sin(bg_time * 0.15) * 18.0, cos(bg_time * 0.12) * 12.0)
		var drift2 := Vector2(cos(bg_time * 0.1) * 14.0, sin(bg_time * 0.13) * 16.0)
		var drift3 := Vector2(sin(bg_time * 0.08 + 2.0) * 20.0, cos(bg_time * 0.11 + 1.0) * 10.0)
		var drift4 := Vector2(cos(bg_time * 0.09 + 3.0) * 12.0, sin(bg_time * 0.14) * 14.0)
		
		var neb_alpha1 := 0.12 + sin(bg_time * 0.3) * 0.04
		draw_circle(Vector2(size.x * 0.14, size.y * 0.1) + drift1, size.x * 0.48, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.nebula_rose", "accent"), neb_alpha1 * background_alpha))
		
		var neb_alpha2 := 0.14 + cos(bg_time * 0.25) * 0.04
		draw_circle(Vector2(size.x * 0.82, size.y * 0.14) + drift2, size.x * 0.40, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.nebula_lavender", "secondary"), neb_alpha2 * background_alpha))
		
		var neb_alpha3 := 0.10 + sin(bg_time * 0.22 + 1.0) * 0.03
		draw_circle(Vector2(size.x * 0.22, size.y * 0.86) + drift3, size.x * 0.36, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.nebula_aqua", "primary"), neb_alpha3 * background_alpha))
		
		var neb_alpha4 := 0.09 + cos(bg_time * 0.28 + 2.0) * 0.03
		draw_circle(Vector2(size.x * 0.88, size.y * 0.78) + drift4, size.x * 0.28, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.nebula_pink", "accent"), neb_alpha4 * background_alpha))
		
		var center_alpha := 0.06 + sin(bg_time * 0.4) * 0.02
		draw_circle(Vector2(size.x * 0.5, size.y * 0.45), size.x * 0.32, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.pearl_shimmer", "white"), center_alpha * background_alpha))
	
	# Skip sparkles on high degradation mobile profile
	if background_alpha > 0.45:
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
			var arm_len := 4.0 + pulse * 3.5
			draw_line(spos - Vector2(arm_len, 0), spos + Vector2(arm_len, 0), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.sparkle", "white"), star_alpha * background_alpha), 1.0)
			draw_line(spos - Vector2(0, arm_len), spos + Vector2(0, arm_len), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.sparkle", "white"), star_alpha * background_alpha), 1.0)
			draw_circle(spos, 1.4 + pulse * 0.8, _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.sparkle_warm", "white"), (0.7 + pulse * 0.3) * background_alpha))
	
	# === Layer 3: Chromatic edge vignette ===
	var edge_w := 3.0
	draw_rect(Rect2(0, 0, size.x, edge_w), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.edge_top", "secondary"), 0.12 * background_alpha), true)
	draw_rect(Rect2(0, size.y - edge_w, size.x, edge_w), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.edge_bottom", "primary"), 0.10 * background_alpha), true)
	draw_rect(Rect2(0, 0, edge_w, size.y), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.edge_left", "accent"), 0.08 * background_alpha), true)
	draw_rect(Rect2(size.x - edge_w, 0, edge_w, size.y), _scene.call("_with_alpha", _scene.call("_tc", "gameplay.visual.edge_right", "primary"), 0.08 * background_alpha), true)
