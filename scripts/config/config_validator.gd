# /Users/user/3-line/scripts/config/config_validator.gd
class_name ConfigValidator
extends RefCounted

## Проверяет валидность загруженных конфигурационных данных.
## Препятствует крашам при повреждении файлов баланса.

static func validate_cascade_rules(data: Dictionary) -> bool:
	if not data.has("system_id") or data.get("system_id") != "controlled-cascade-engine":
		printerr("ConfigValidator: Invalid system_id in cascade rules.")
		return false
	if not data.has("default_settings"):
		printerr("ConfigValidator: Missing default_settings in cascade rules.")
		return false
		
	var settings = data.get("default_settings", {})
	if not settings.has("max_cascade_depth_default") or not settings.has("max_cascade_depth_fever"):
		printerr("ConfigValidator: Missing critical limit settings.")
		return false
		
	return true

static func validate_shape_rules(data: Dictionary) -> bool:
	if not data.has("system_id") or data.get("system_id") != "shape-detector":
		return false
	if not data.has("shape_mappings"):
		return false
	return true

static func validate_level_balance(data: Dictionary) -> bool:
	if not data.has("difficulty_profiles"):
		return false
	return true
