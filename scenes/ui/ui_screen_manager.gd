# /Users/user/3-line/scenes/ui/ui_screen_manager.gd
class_name UIScreenManager
extends CanvasLayer

## Управляет переходами между экранами и профилями качества шейдеров (HIGH/MID/SAFE).

var current_quality: String = "HIGH"

func _ready() -> void:
	# Считываем настройки качества из ThemeTokens
	if "shader_quality" in ThemeTokens.performance:
		current_quality = ThemeTokens.performance.shader_quality
	
	apply_quality_profile(current_quality)

func apply_quality_profile(profile: String) -> void:
	current_quality = profile
	match profile:
		"HIGH":
			print("UIScreenManager: High quality profile active. Blurs enabled.")
		"SAFE":
			print("UIScreenManager: Safe performance profile active. Blurs disabled.")

func load_screen(screen_path: String) -> void:
	var screen_res = load(screen_path)
	if not screen_res:
		printerr("UIScreenManager: Failed to load screen at ", screen_path)
		return
		
	var screen = screen_res.instantiate()
	# Очищаем старые экраны
	for child in get_children():
		child.queue_free()
		
	add_child(screen)
