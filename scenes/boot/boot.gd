## Boot — точка входа в игру
## Загрузка → splash → main menu или сразу gameplay (dev mode)
extends Control

@export var dev_mode: bool = false  # true = сразу в gameplay

func _ready() -> void:
	# В dev mode — сразу на gameplay сцену
	if dev_mode:
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/gameplay/gameplay.tscn")
		return

	# Production: splash → menu
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
