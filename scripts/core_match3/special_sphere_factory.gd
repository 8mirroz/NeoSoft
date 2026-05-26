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
	var s_lower = shape_type.to_lower()
	if s_lower == "l_shape":
		s_lower = "l_5"
	elif s_lower == "t_shape":
		s_lower = "t_5"
	elif s_lower == "cross":
		s_lower = "cross_5"
	return shape_mappings.get(s_lower, "none")

func get_special_sphere_type(shape_type: String) -> int:
	var type_str = get_special_type_str(shape_type)
	match type_str:
		"beam": return SpecialSphereType.Type.BEAM_SPHERE
		"homing": return SpecialSphereType.Type.HOMING_SPHERE
		"blast": return SpecialSphereType.Type.BLAST_SPHERE
		"pulse", "cross": return SpecialSphereType.Type.BLAST_SPHERE_PLUS
		"prism": return SpecialSphereType.Type.PRISM_SPHERE
		"gravity", "lightning", "field", "dynamo": return SpecialSphereType.Type.DYNAMO_SPHERE
		"singularity": return SpecialSphereType.Type.SINGULARITY_CORE
	return SpecialSphereType.Type.NONE

func create_special_sphere(shape_result: MatchShapeResult) -> Dictionary:
	var special_id = get_special_sphere_type(shape_result.shape_type)
	return {
		"cell": shape_result.center_cell,
		"special_type": special_id,
		"weight": shape_result.weight,
		"cells_cleared": shape_result.cells
	}
