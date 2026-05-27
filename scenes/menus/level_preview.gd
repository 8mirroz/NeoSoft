extends PremiumScreen

var _level_id: int
var _selected: Array = []
var _selection_label: Label
var booster_buttons: Dictionary = {}

func _ready() -> void:
	var payload := UIScreenManager.payload()
	_level_id = int(payload.get("level_id", UserData.active_level))
	var config := LevelLoader.load_level(_level_id)
	if config.is_empty():
		route(&"world_map")
		return
		
	var body := setup_screen("Level %02d" % _level_id, String(config.get("title", "Crystal Path")), &"world", true)
	
	# Difficulty and rewards section
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	var difficulty := String(config.get("modifiers", {}).get("difficulty_band", "standard")).capitalize()
	details.add_child(info_card("Difficulty", difficulty, "%d moves" % int(config.get("moves", 20))))
	details.add_child(info_card("Reward", "Up to 250 coins", "Stars increase rewards"))
	body.add_child(details)

	# Targets Section
	var goals_header := Label.new()
	goals_header.text = "Mission Targets"
	goals_header.add_theme_font_size_override("font_size", 21)
	goals_header.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	body.add_child(goals_header)
	
	# Targets list with beautiful spherical icon decorators
	for goal in config.get("goals", []):
		var target := int(goal.get("target", 0))
		var gem_type := int(goal.get("gem_type", 0))
		var goal_type := int(goal.get("type", 0))
		
		var icon_lbl := "🎯"
		var label_text := "Score target"
		if goal_type != 0:
			icon_lbl = _sphere_icon_for_type(gem_type)
			label_text = "Collect sphere type %d" % gem_type
			
		body.add_child(info_card(icon_lbl + " " + label_text, str(target)))

	# Select Boosters Section
	var boosters_header := Label.new()
	boosters_header.text = "Select Boosters"
	boosters_header.add_theme_font_size_override("font_size", 21)
	boosters_header.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	body.add_child(boosters_header)
	
	var booster_row := HBoxContainer.new()
	booster_row.add_theme_constant_override("separation", 10)
	body.add_child(booster_row)
	
	for booster_id in ["shuffle", "hammer", "undo"]:
		var count := UserData.get_booster_count(booster_id)
		# Start buttons as unselected (normal)
		var button := make_button("%s (%d)" % [booster_id.capitalize(), count], &"preview.booster", _toggle_booster.bind(booster_id))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = count <= 0
		booster_row.add_child(button)
		booster_buttons[booster_id] = button
		
	_selection_label = Label.new()
	_selection_label.text = "No boosters selected"
	_selection_label.add_theme_color_override("font_color", token_color("menu.text.muted", Color("#6D6788")))
	body.add_child(_selection_label)
	
	var start := make_button("Start Level", &"preview.start", _start_level, true)
	start.custom_minimum_size = Vector2(0, 68)
	body.add_child(start)

func _toggle_booster(booster_id: String) -> void:
	SoundManager.play("tap")
	var button: Button = booster_buttons.get(booster_id)
	
	if _selected.has(booster_id):
		_selected.erase(booster_id)
		# Reset to normal style
		button.add_theme_stylebox_override("normal", button_style("gameplay.button", "normal"))
		button.add_theme_stylebox_override("hover", button_style("gameplay.button", "hover"))
	else:
		_selected.append(booster_id)
		# Highlighting with pressed style
		button.add_theme_stylebox_override("normal", button_style("gameplay.button", "pressed"))
		button.add_theme_stylebox_override("hover", button_style("gameplay.button", "pressed"))
		
	_selection_label.text = "Selected: %s" % ", ".join(_selected) if not _selected.is_empty() else "No boosters selected"

func _start_level() -> void:
	SoundManager.play("tap")
	UserData.set_active_level(_level_id)
	UserData.set_selected_boosters(_selected)
	route(&"gameplay", {"level_id": _level_id, "selected_boosters": _selected})

func _sphere_icon_for_type(type: int) -> String:
	return {
		0: "🔵", # Frost
		1: "⚪", # Glass
		2: "🔵", # Aqua
		3: "🟣", # Violet
		4: "🟡", # Warm
	}.get(type, "🔮")
