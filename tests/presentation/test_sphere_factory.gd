extends "res://addons/gut/test.gd"

func test_piece_mapping_covers_menu_variants() -> void:
	assert_eq(SphereFactory.get_sphere_type_for_piece(0), CellState.SphereType.FROST, "piece 0 должен маппиться в FROST")
	assert_eq(SphereFactory.get_sphere_type_for_piece(3), CellState.SphereType.VIOLET, "piece 3 должен маппиться в VIOLET")
	assert_eq(SphereFactory.get_sphere_type_for_piece(7), CellState.SphereType.CROSS_WAVE, "piece 7 должен маппиться в CROSS_WAVE")
	assert_eq(SphereFactory.get_sphere_type_for_piece(99), CellState.SphereType.FROST, "неизвестный piece должен падать в безопасный fallback")

func test_create_known_sphere_returns_node2d() -> void:
	var sphere := SphereFactory.create(CellState.SphereType.GLASS)
	add_child_autofree(sphere)
	
	assert_true(sphere is Node2D, "Фабрика должна возвращать Node2D")
	assert_not_null(sphere.find_child("Sprite2D", true, false), "Сфера должна содержать Sprite2D")

func test_gem_view_can_switch_to_sphere_mode() -> void:
	var gem := GemView.new()
	add_child_autofree(gem)
	gem.size = 72.0
	gem.set_piece(3)
	gem.set_sphere_type(CellState.SphereType.AQUA)

	assert_eq(gem.sphere_type, CellState.SphereType.AQUA, "GemView должен запомнить тип сферы")
	assert_not_null(gem.find_child("Sprite2D", true, false), "GemView должен подцепить сцену сферы")
