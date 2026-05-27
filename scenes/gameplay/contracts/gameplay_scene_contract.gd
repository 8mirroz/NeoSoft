extends RefCounted
class_name GameplaySceneContract

var _refs: GameplayNodeRefs

func _init(refs: GameplayNodeRefs) -> void:
	_refs = refs

func validate_or_fail() -> void:
	if _refs == null:
		push_error("Gameplay scene contract validator initialized with null references.")
		assert(false, "Null references")
		return

	var missing: Array[String] = _refs.collect_missing()
	if not missing.is_empty():
		push_error("Gameplay scene contract failed. Missing nodes: %s" % str(missing))
		assert(false, "Gameplay scene contract failed. Missing nodes: %s" % str(missing))
