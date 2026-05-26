extends Control
class_name GlassProgressBar

@export var value: float = 0.0 : set = _set_value
@export var target_score: int = 1500

var _stars: int = 0
const TRACK_HEIGHT: float = 14.0

func _set_value(val: float) -> void:
	value = clamp(val, 0.0, 1.0)
	queue_redraw()

func set_stars(stars: int) -> void:
	_stars = stars
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var center_y := h / 2.0
	
	# Draw glass track background
	var track_rect := Rect2(0.0, center_y - TRACK_HEIGHT / 2.0, w, TRACK_HEIGHT)
	draw_rect(track_rect, Color(1, 1, 1, 0.05), true, 0.0) # Transparent inner fill
	draw_rect(track_rect, Color(1, 1, 1, 0.12), false, 1.5) # Soft white contour
	
	# Draw filled gradient progress
	if value > 0.05:
		# Draw segment by segment or horizontal color interpolation
		var fill_w := w * value
		# Draw gradient fill using vertical and horizontal subdivisions or three-point interpolation
		# For simplicity and efficiency, draw a set of polygons or lines interpolating Cyan (0.0) -> Violet (0.6) -> Gold (1.0)
		for x in range(int(fill_w)):
			var t := float(x) / w
			var col: Color
			if t < 0.6:
				col = Color(0.62, 0.92, 0.94).lerp(Color(0.72, 0.65, 0.95), t / 0.6)
			else:
				col = Color(0.72, 0.65, 0.95).lerp(Color(0.96, 0.85, 0.50), (t - 0.6) / 0.4)
			
			draw_line(Vector2(x, center_y - TRACK_HEIGHT / 2.0 + 1.0), Vector2(x, center_y + TRACK_HEIGHT / 2.0 - 1.0), col, 1.0)

	# Star ratios: 40%, 70%, 100%
	var star_points := [0.4, 0.7, 1.0]
	for i in range(star_points.size()):
		var ratio := star_points[i]
		var star_pos := Vector2(w * ratio, center_y)
		
		# Star active state check
		var active := (value >= ratio)
		var star_color := Color(0.96, 0.85, 0.50) if active else Color(1, 1, 1, 0.25)
		
		# Draw glowing outer ring if active
		if active:
			draw_circle(star_pos, 8.0, Color(star_color.r, star_color.g, star_color.b, 0.18))
			
		# Draw simple golden vector star shape
		var star_vertices := PackedVector2Array()
		for j in range(10):
			var r := 7.0 if j % 2 == 0 else 3.0
			var angle := j * PI / 5.0 - PI / 2.0
			star_vertices.append(star_pos + Vector2(cos(angle) * r, sin(angle) * r))
		
		draw_colored_polygon(star_vertices, star_color)
		draw_polyline(star_vertices, Color(1, 1, 1, 0.35), 1.0)
