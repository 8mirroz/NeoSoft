extends RefCounted
class_name SphereFactory

const BASE_TEXTURE := preload("res://assets/spheres/01_iridescent_frost/01_iridescent_frost_base.png")

const SPHERE_SCENES := {
	CellState.SphereType.FROST: preload("res://scenes/spheres/01_iridescent_frost.tscn"),
	CellState.SphereType.GLASS: preload("res://scenes/spheres/02_clear_glass.tscn"),
	CellState.SphereType.AQUA: preload("res://scenes/spheres/03_aqua_wave.tscn"),
	CellState.SphereType.VIOLET: preload("res://scenes/spheres/04_violet_pulse.tscn"),
	CellState.SphereType.WARM: preload("res://scenes/spheres/08_warm_glow.tscn"),
	CellState.SphereType.BLUE_RIBBON: preload("res://scenes/spheres/09_blue_ribbon.tscn"),
	CellState.SphereType.PURPLE_RIBBON: preload("res://scenes/spheres/10_purple_ribbon.tscn"),
	CellState.SphereType.CROSS_WAVE: preload("res://scenes/spheres/p2_cross_wave.tscn"),
}

const PIECE_TO_SPHERE := {
	0: CellState.SphereType.FROST,
	1: CellState.SphereType.GLASS,
	2: CellState.SphereType.AQUA,
	3: CellState.SphereType.VIOLET,
	4: CellState.SphereType.WARM,
	5: CellState.SphereType.BLUE_RIBBON,
	6: CellState.SphereType.PURPLE_RIBBON,
	7: CellState.SphereType.CROSS_WAVE,
}

static func get_sphere_type_for_piece(piece_id: int) -> int:
	return int(PIECE_TO_SPHERE.get(piece_id, CellState.SphereType.FROST))

static func create(type: int) -> Node2D:
	var scene: PackedScene = SPHERE_SCENES.get(type, null)
	if scene != null:
		var instance := scene.instantiate()
		if instance is Node2D:
			return instance
		push_error("SphereFactory: scene for type %d is not a Node2D" % type)

	push_error("SphereFactory: unknown sphere type %d, using fallback sprite" % type)
	return _create_fallback()

static func create_for_piece(piece_id: int) -> Node2D:
	return create(get_sphere_type_for_piece(piece_id))

static func _create_fallback() -> Node2D:
	var root := Node2D.new()
	root.name = "FallbackSphere"

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = BASE_TEXTURE
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	# Apply black cutout shader to remove black studio background
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/black_cutout.gdshader")
	mat.set_shader_parameter("brightness_threshold", 0.04)
	mat.set_shader_parameter("transition_softness", 0.24)
	mat.set_shader_parameter("rim_boost", 1.4)
	sprite.material = mat

	root.add_child(sprite)

	return root
