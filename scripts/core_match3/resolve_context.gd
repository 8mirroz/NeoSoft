extends RefCounted
class_name ResolveContext

enum State {
	IDLE,
	SWAP_REQUESTED,
	SWAP_VALIDATING,
	MATCH_SCANNING,
	SPECIAL_SPAWNING,
	EFFECT_RESOLVING,
	GRAVITY_APPLYING,
	CASCADE_CHECKING,
	COMBO_UPDATING,
	STABILIZING,
	FAILED_RECOVERY
}

var board: BoardStateEngine
var combo_controller: ComboFeverController
var input_buffer: InputBufferController
var shape_detector: MatchShapeDetector
var sphere_factory: SpecialSphereFactory
var target_priority: TargetPrioritySystem

var current_cascade_depth: int = 0
var max_cascade_depth: int = 50
var state: int = State.IDLE

var active_swap_from: Vector2i = Vector2i(-1, -1)
var active_swap_to: Vector2i = Vector2i(-1, -1)
var pending_matches: Array[MatchShapeResult] = []
var pending_specials: Array[Dictionary] = []
var is_special_swap: bool = false


func _init(p_board: BoardStateEngine, p_combo: ComboFeverController, p_input: InputBufferController, p_shape: MatchShapeDetector, p_sphere: SpecialSphereFactory, p_target: TargetPrioritySystem) -> void:
	board = p_board
	combo_controller = p_combo
	input_buffer = p_input
	shape_detector = p_shape
	sphere_factory = p_sphere
	target_priority = p_target
