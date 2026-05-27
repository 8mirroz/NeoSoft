extends PremiumScreen

func _ready() -> void:
	var body := setup_screen("Collection", "Glass spheres discovered on your journey", &"collection")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	for sphere in UserData.get_collection_state():
		var unlocked := bool(sphere.get("unlocked", false))
		var status := "Discovered" if unlocked else "Unlock at level %d" % int(sphere.get("level", 1))
		grid.add_child(info_card(String(sphere.get("title", "Sphere")), "O" if unlocked else "?", status))
