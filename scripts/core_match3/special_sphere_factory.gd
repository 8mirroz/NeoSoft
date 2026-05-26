# /Users/user/3-line/scripts/core_match3/special_sphere_factory.gd
extends RefCounted
class_name SpecialSphereFactory

## Дата-ориентированная фабрика для создания и спавна спец-сфер.
## Управляется конфигурациями shape_rules.json и special_spheres.json.

var shape_mappings: Dictionary = {}

func _init() -> void:
	_load_config()

func _load_config() -> void:
	var path = "res://data/shape_rules.json"
	if not FileAccess.file_exists(path):
		_load_fallback()
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) == OK:
		var data = json.data
		shape_mappings = data.get("shape_mappings", {})
	else:
		_load_fallback()

func _load_fallback() -> void:
	shape_mappings = {
		"line_4": "beam",
		"square_2x2": "homing",
		"l_5": "blast",
		"t_5": "pulse",
		"line_5": "prism",
		"cross_5": "cross",
		"hook_6": "gravity",
		"zigzag_6": "lightning",
		"rectangle_2x3": "field",
		"complex_7_plus": "dynamo",
		"rare_9_plus": "singularity"
	}

func get_special_type_str(shape_type: String) -> String:
	return shape_mappings.get(shape_type.to_lower(), "none")

func create_special_sphere(shape_result: MatchShapeResult) -> Dictionary:
	var type_str = get_special_type_str(shape_result.shape_type)
	var special_id = 0
	
	match type_str:
		"beam": special_id = 1
		"homing": special_id = 2
		"blast": special_id = 3
		"pulse": special_id = 4
		"prism": special_id = 5
		"cross": special_id = 6
		"gravity": special_id = 7
		"lightning": special_id = 8
		"field": special_id = 9
		"dynamo": special_id = 10
		"singularity": special_id = 11
		
	return {
		"cell": shape_result.center_cell,
		"special_type": special_id,
		"weight": shape_result.weight,
		"cells_cleared": shape_result.cells
	}
