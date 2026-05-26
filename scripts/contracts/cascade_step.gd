# /Users/user/3-line/scripts/contracts/cascade_step.gd
class_name CascadeStep
extends RefCounted

## Контракт одиночного шага каскадного опускания гемов.
## Передается по EventBus в FeedbackDirector для эскалации VFX/SFX.

var depth_level: int = 1
var generated_gems: Array = [] # Массив Dictionary вида {"position": Vector2i, "gem_type": String, "is_assisted": bool}
var drop_mode: int = 0 # ControlledCascadeEngine.DropMode (NATURAL, ASSISTED, CINEMATIC)

func _init(p_depth: int = 1, p_gems: Array = [], p_mode: int = 0) -> void:
	depth_level = p_depth
	generated_gems = p_gems
	drop_mode = p_mode

func serialize() -> Dictionary:
	var gems_data = []
	for gem in generated_gems:
		gems_data.append({
			"x": gem.position.x,
			"y": gem.position.y,
			"gem_type": gem.gem_type,
			"is_assisted": gem.get("is_assisted", false)
		})
	return {
		"depth_level": depth_level,
		"generated_gems": gems_data,
		"drop_mode": drop_mode
	}

func deserialize(data: Dictionary) -> void:
	depth_level = data.get("depth_level", 1)
	drop_mode = data.get("drop_mode", 0)
	generated_gems.clear()
	var gems_data = data.get("generated_gems", [])
	for g in gems_data:
		generated_gems.append({
			"position": Vector2i(g.get("x", 0), g.get("y", 0)),
			"gem_type": g.get("gem_type", ""),
			"is_assisted": g.get("is_assisted", false)
		})
