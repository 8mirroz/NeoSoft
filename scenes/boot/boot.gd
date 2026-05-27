## Boot — точка входа в игру
## Загрузка → splash → main menu или сразу gameplay (dev mode)
extends Control

@export var dev_mode: bool = false  # true = сразу в gameplay

func _ready() -> void:
	# В dev mode — сразу на gameplay сцену
	if dev_mode:
		UIScreenManager.navigate(&"gameplay", {}, &"none")
		return

	# Production: asset-aware loading screen with explicit start action.
	UIScreenManager.navigate(&"loading", {}, &"none")
