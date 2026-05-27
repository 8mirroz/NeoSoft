extends RefCounted
class_name GameplayTelemetryAdapter

func setup() -> void:
	EventBus.analytics_event_requested.connect(_on_analytics_event_requested)

func _on_analytics_event_requested(event_name: String, payload: Dictionary) -> void:
	var event_data := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"data": payload
	}
	# Output formatting to terminal
	print("[TELEMETRY] Emit event: ", JSON.stringify(event_data))
