# /Users/user/3-line/scripts/core_match3/drop_rng_controller.gd
class_name DropRngController
extends RefCounted

## Детерминированный RNG-контроллер для каскадов (Layer 2).
## Совместим с MCTS симулятором и воспроизводимостью ходов.

var _rng: RandomNumberGenerator
var _initial_seed: int

func _init(seed_val: int) -> void:
	_rng = RandomNumberGenerator.new()
	_initial_seed = seed_val
	_rng.seed = seed_val

func reset() -> void:
	_rng.seed = _initial_seed

func roll_gem_type(weights: Dictionary) -> String:
	var total_weight: float = 0.0
	for w in weights.values():
		total_weight += w
		
	var roll = _rng.randf_range(0.0, total_weight)
	var current_sum: float = 0.0
	
	for key in weights.keys():
		current_sum += weights[key]
		if roll <= current_sum:
			return key
			
	return weights.keys()[0] # Fallback
