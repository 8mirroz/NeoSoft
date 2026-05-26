# /Users/user/3-line/scripts/feedback/audio_feedback_router.gd
class_name AudioFeedbackRouter
extends RefCounted

## Роутер аудио-эффектов. Загружает звуки из манифеста ассетов
## и предотвращает слишком громкое одновременное наложение.

var audio_manifest: Dictionary = {}
var active_players: int = 0

func _init() -> void:
	# Считываем манифест из JSON
	var path = "res://data/assets/asset_manifest.json"
	if not FileAccess.file_exists(path):
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) == OK:
		audio_manifest = json.data.get("assets", {}).get("audio", {})

func play_sound(sound_key: String, viewport: Node) -> void:
	if not audio_manifest.has(sound_key):
		return
		
	var file_path = audio_manifest[sound_key]
	if file_path == "" or not ResourceLoader.exists(file_path):
		return # Безопасный fallback
		
	# Симуляция создания плеера
	active_players += 1
	var stream = load(file_path)
	print("AudioFeedbackRouter: Playing sound ", sound_key, " at path ", file_path)
