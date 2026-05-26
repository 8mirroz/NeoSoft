# /Users/user/3-line/scripts/contracts/telemetry_event.gd
class_name TelemetryEvent
extends RefCounted

## Контракт события телеметрии одного совершенного игроком хода.
## Используется в BalanceTelemetryLayer и в MCTS симуляциях.

var timestamp: int = 0
var turn_index: int = 0
var move_type: String = "manual" # manual, combo_window, replay
var score_gained: int = 0
var cascade_depth: int = 0
var special_created_count: int = 0
var fever_active: bool = false
var elapsed_time_sec: float = 0.0

func _init() -> void:
	timestamp = Time.get_ticks_msec()

func serialize() -> Dictionary:
	return {
		"timestamp": timestamp,
		"turn_index": turn_index,
		"move_type": move_type,
		"score_gained": score_gained,
		"cascade_depth": cascade_depth,
		"special_created_count": special_created_count,
		"fever_active": fever_active,
		"elapsed_time_sec": elapsed_time_sec
	}

func deserialize(data: Dictionary) -> void:
	timestamp = data.get("timestamp", 0)
	turn_index = data.get("turn_index", 0)
	move_type = data.get("move_type", "manual")
	score_gained = data.get("score_gained", 0)
	cascade_depth = data.get("cascade_depth", 0)
	special_created_count = data.get("special_created_count", 0)
	fever_active = data.get("fever_active", false)
	elapsed_time_sec = data.get("elapsed_time_sec", 0.0)
