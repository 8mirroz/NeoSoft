# /Users/user/3-line/scripts/feedback/camera_feedback_router.gd
class_name CameraFeedbackRouter
extends RefCounted

## Управляет эффектами движения камеры (shake, zoom, tilt) при сочных взрывах гемов.

var max_shake_amplitude: float = 20.0
var camera_node: Camera2D = null

func _init(p_camera: Camera2D = null) -> void:
	camera_node = p_camera

func apply_shake(amplitude: float, duration: float) -> void:
	var final_amp = min(amplitude, max_shake_amplitude)
	print("CameraFeedbackRouter: Applied camera shake. Amp: ", final_amp, ", Duration: ", duration)
	if camera_node != null:
		# Накладываем офсет на камеру через таймер/tween
		pass

func apply_zoom(zoom_factor: Vector2, duration: float) -> void:
	print("CameraFeedbackRouter: Zooming camera. Scale: ", zoom_factor, ", Duration: ", duration)
