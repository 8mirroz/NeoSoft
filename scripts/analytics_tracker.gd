extends Node

const DEFAULT_LOG_PATH := "user://analytics_events.jsonl"

var _soft_launch_config: Dictionary = {}
var _analytics_config: Dictionary = {}

func _ready() -> void:
	_soft_launch_config = LevelLoader.load_soft_launch_config()
	_analytics_config = _soft_launch_config.get("analytics", {})
	EventBus.analytics_event_requested.connect(_on_analytics_event_requested)

func _on_analytics_event_requested(event_name: String, payload: Dictionary) -> void:
	if not bool(_analytics_config.get("enabled", true)):
		return

	var event := payload.duplicate(true)
	event["event_name"] = event_name
	event["timestamp_unix"] = Time.get_unix_time_from_system()
	event["iso_datetime"] = Time.get_datetime_string_from_system(true, true)

	var log_path: String = _analytics_config.get("log_path", DEFAULT_LOG_PATH)
	var file: FileAccess
	if FileAccess.file_exists(log_path):
		file = FileAccess.open(log_path, FileAccess.READ_WRITE)
	else:
		file = FileAccess.open(log_path, FileAccess.WRITE)

	if file == null:
		push_warning("AnalyticsTracker: failed to open analytics log at: " + log_path)
		return

	file.seek_end()
	file.store_line(JSON.stringify(event))
	file.close()
