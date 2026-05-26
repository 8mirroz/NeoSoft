extends "res://addons/gut/test.gd"

# Юнит-тесты для SpecialSphereFactory

func test_load_matrix_and_mapping() -> void:
	var factory := SpecialSphereFactory.new()
	
	assert_eq(factory.get_special_sphere_type("LINE_4"), SpecialSphereType.Type.BEAM_SPHERE, "LINE_4 должна маппиться в BEAM_SPHERE")
	assert_eq(factory.get_special_sphere_type("SQUARE_2X2"), SpecialSphereType.Type.HOMING_SPHERE, "SQUARE_2X2 должна маппиться в HOMING_SPHERE")
	assert_eq(factory.get_special_sphere_type("L_SHAPE"), SpecialSphereType.Type.BLAST_SPHERE, "L_SHAPE должна маппиться в BLAST_SPHERE")
	assert_eq(factory.get_special_sphere_type("T_SHAPE"), SpecialSphereType.Type.BLAST_SPHERE_PLUS, "T_SHAPE должна маппиться в BLAST_SPHERE_PLUS")
	assert_eq(factory.get_special_sphere_type("CROSS"), SpecialSphereType.Type.BLAST_SPHERE_PLUS, "CROSS должна маппиться в BLAST_SPHERE_PLUS")
	assert_eq(factory.get_special_sphere_type("LINE_5"), SpecialSphereType.Type.PRISM_SPHERE, "LINE_5 должна маппиться в PRISM_SPHERE")

func test_create_special_sphere() -> void:
	var factory := SpecialSphereFactory.new()
	
	# Формируем фейковый результат сканирования
	var result := MatchShapeResult.new(
		"LINE_4",
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i.RIGHT,
		2.0
	)
	
	var sphere := factory.create_special_sphere(result)
	
	assert_eq(sphere["cell"], Vector2i(2, 0), "Ячейка спавна должна совпадать с центром фигуры")
	assert_eq(sphere["special_type"], SpecialSphereType.Type.BEAM_SPHERE, "Тип должен быть BEAM_SPHERE")
	assert_eq(sphere["weight"], 2.0, "Вес должен переноситься")
	assert_eq(sphere["cells_cleared"].size(), 4, "Количество ячеек должно быть 4")
