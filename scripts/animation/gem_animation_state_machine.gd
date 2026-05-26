# /Users/user/3-line/scripts/animation/gem_animation_state_machine.gd
class_name GemAnimationStateMachine
extends RefCounted

## Конечный автомат (FSM) анимаций гемов.
## Гарантирует атомарную смену состояний и исключает зависание спрайтов в воздухе.

enum AnimationState {
	IDLE,
	HOVER,
	SELECTED,
	SWAP_START,
	SWAP_LAND,
	FALL,
	LAND,
	SPECIAL_SPAWN,
	DISSOLVE
}

var current_state: int = AnimationState.IDLE
var target_node: Node2D = null

func _init(p_node: Node2D) -> void:
	target_node = p_node

func transition_to(new_state: int) -> bool:
	if current_state == new_state:
		return true
		
	if not _is_transition_valid(current_state, new_state):
		printerr("GemAnimationFSM: Invalid transition from ", current_state, " to ", new_state)
		return false
		
	var old_state = current_state
	current_state = new_state
	_apply_state_visuals(old_state, new_state)
	return true

func _is_transition_valid(from: int, to: int) -> bool:
	match from:
		AnimationState.IDLE:
			return to in [AnimationState.HOVER, AnimationState.SELECTED, AnimationState.SWAP_START, AnimationState.FALL, AnimationState.DISSOLVE]
		AnimationState.HOVER:
			return to in [AnimationState.IDLE, AnimationState.SELECTED, AnimationState.SWAP_START]
		AnimationState.SELECTED:
			return to in [AnimationState.IDLE, AnimationState.SWAP_START]
		AnimationState.SWAP_START:
			return to in [AnimationState.SWAP_LAND, AnimationState.IDLE]
		AnimationState.SWAP_LAND:
			return to in [AnimationState.IDLE, AnimationState.FALL, AnimationState.DISSOLVE]
		AnimationState.FALL:
			return to in [AnimationState.LAND, AnimationState.DISSOLVE]
		AnimationState.LAND:
			return to in [AnimationState.IDLE, AnimationState.FALL, AnimationState.DISSOLVE]
		AnimationState.SPECIAL_SPAWN:
			return to in [AnimationState.IDLE]
		AnimationState.DISSOLVE:
			return to in [AnimationState.IDLE] # После взрыва ресетится в дефолт
	return false

func _apply_state_visuals(old_state: int, new_state: int) -> void:
	if target_node == null:
		return
		
	match new_state:
		AnimationState.SELECTED:
			# Легкое покачивание/зум выбранной сферы
			target_node.scale = Vector2(1.1, 1.1)
		AnimationState.IDLE:
			target_node.scale = Vector2(1.0, 1.0)
		AnimationState.FALL:
			# Симуляция падения
			pass
		AnimationState.LAND:
			# Мягкое bounce приземление гема
			target_node.scale = Vector2(1.0, 0.9)
			# Сброс скейла через tween
