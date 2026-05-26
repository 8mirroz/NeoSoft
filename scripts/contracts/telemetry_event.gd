# /Users/user/3-line/scripts/contracts/telemetry_event.gd
extends RefCounted
class_name TelemetryEvent

## Контракт события аналитики/телеметрии (Telemetry Event DTO).

var event_name: String = ""
var timestamp: float = 0.0
var payload: Dictionary = {}

func _init(p_name: String, p_payload: Dictionary = {}) -> void:
	event_name = p_name
	payload = p_payload
	timestamp = Time.get_ticks_msec() / 1000.0

func to_dict() -> Dictionary:
	return {
		"event_name": event_name,
		"timestamp": timestamp,
		"payload": payload
	}
