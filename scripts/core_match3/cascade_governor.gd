# /Users/user/3-line/scripts/core_match3/cascade_governor.gd
class_name CascadeGovernor
extends RefCounted

## Защитный ограничитель глубины каскадного взрыва гемов.
## Предотвращает бесконечные циклы ("игра играет сама").

var current_depth: int = 0
var max_depth_limit: int = 5
var is_fever_active: bool = false
var default_settings: Dictionary = {}

func _init(settings: Dictionary) -> void:
	default_settings = settings
	max_depth_limit = settings.get("max_cascade_depth_default", 5)

func configure_fever(active: bool) -> void:
	is_fever_active = active
	if active:
		max_depth_limit = default_settings.get("max_cascade_depth_fever", 8)
	else:
		max_depth_limit = default_settings.get("max_cascade_depth_default", 5)

func reset() -> void:
	current_depth = 0

func increment_depth() -> void:
	current_depth += 1

func allow_next_step() -> bool:
	# Абсолютный лимит 10 для полной защиты от зависаний
	if current_depth >= 10:
		return false
	return current_depth < max_depth_limit
