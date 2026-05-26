# /Users/user/3-line/scripts/core_match3/special_balance_guard.gd
class_name SpecialSphereBalanceGuard
extends RefCounted

## Защищает игровое поле от пересыщения спец-сферами.
## Предотвращает неконтролируемое авто-прохождение уровня.

var max_specials_per_turn: int = 3
var current_turn_specials: int = 0

func _init(p_max: int = 3) -> void:
	max_specials_per_turn = p_max

func start_new_turn() -> void:
	current_turn_specials = 0

func register_special_spawn() -> void:
	current_turn_specials += 1

func allow_more_specials() -> bool:
	return current_turn_specials < max_specials_per_turn
