extends RefCounted
class_name QueuedMove

var from_cell: Vector2i = Vector2i(-1, -1)
var to_cell: Vector2i = Vector2i(-1, -1)
var created_at: float = 0.0
var expires_at: float = 0.0
var priority: int = 0
var expected_from_gem_id: int = -1
var expected_to_gem_id: int = -1
var source: String = "manual"

func _init(p_from: Vector2i, p_to: Vector2i, p_created: float, p_expires: float, p_from_gem: int = -1, p_to_gem: int = -1, p_priority: int = 0, p_source: String = "manual") -> void:
	from_cell = p_from
	to_cell = p_to
	created_at = p_created
	expires_at = p_expires
	expected_from_gem_id = p_from_gem
	expected_to_gem_id = p_to_gem
	priority = p_priority
	source = p_source
