extends PremiumScreen

var _catalog: VBoxContainer
var _tab_label: Label
var _active_tab: String = "Coins"
var tab_buttons: Dictionary = {}

func _ready() -> void:
	_active_tab = String(UIScreenManager.payload().get("shop_tab", "Coins"))
	var body := setup_screen("Crystal Shop", "Spend earned coins on playable boosters", &"none")
	
	# Segmented tab header bar
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	
	for tab in ["Coins", "Boosters", "Specials"]:
		# Active tab starts styled with pressed style box
		var is_active := tab == _active_tab
		var button := make_button(tab, &"shop.tab", _select_tab.bind(tab), is_active)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		tab_buttons[tab] = button
		
	body.add_child(tabs)
	
	_tab_label = Label.new()
	_tab_label.add_theme_font_size_override("font_size", 20)
	_tab_label.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	body.add_child(_tab_label)
	
	_catalog = VBoxContainer.new()
	_catalog.add_theme_constant_override("separation", 12)
	body.add_child(_catalog)
	
	_render_catalog()

func _select_tab(tab: String) -> void:
	SoundManager.play("tap")
	_active_tab = tab
	
	# Update active tab button styles
	for tab_name in tab_buttons.keys():
		var btn: Button = tab_buttons[tab_name]
		if tab_name == _active_tab:
			btn.add_theme_stylebox_override("normal", button_style("gameplay.button", "pressed"))
			btn.add_theme_stylebox_override("hover", button_style("gameplay.button", "pressed"))
		else:
			btn.add_theme_stylebox_override("normal", button_style("gameplay.button", "normal"))
			btn.add_theme_stylebox_override("hover", button_style("gameplay.button", "hover"))
			
	_render_catalog()

func _render_catalog() -> void:
	for child in _catalog.get_children():
		child.queue_free()
	_tab_label.text = _active_tab
	
	var config := _config()
	match _active_tab:
		"Coins":
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			_catalog.add_child(grid)
			
			for pack in config.get("coin_packs", []):
				var card = info_card("🪙 " + String(pack.get("title", "Pack")), "%d coins" % int(pack.get("coins", 0)), "Unavailable in this build")
				grid.add_child(card)
				
		"Boosters":
			for item in config.get("shop_items", []):
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 10)
				row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				var card = info_card("⚒ " + String(item.get("title", "Booster")), "%d coins" % int(item.get("cost", 0)), String(item.get("description", "")))
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(card)
				
				var purchase := make_button("Buy", &"shop.purchase_booster", _purchase.bind(String(item.get("id", ""))), true)
				purchase.custom_minimum_size = Vector2(126, 60)
				purchase.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(purchase)
				_catalog.add_child(row)
				
		_:
			_catalog.add_child(info_card("🌌 Special Spheres", "Discover in gameplay", "Special sphere purchases are not available in this build."))

func _purchase(item_id: String) -> void:
	var result := UserData.purchase_shop_item(item_id)
	if bool(result.get("purchased", false)):
		show_toast("Purchased %s." % item_id.capitalize())
		SoundManager.play("win")
		# Navigate back to shop to redraw coin top-bar
		route(&"shop", {"shop_tab": _active_tab})
	else:
		show_toast("Not enough coins.")
		SoundManager.play("error_muted")

func _config() -> Dictionary:
	var file := FileAccess.open("res://data/economy/reward_profiles.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else {}
	if file != null:
		file.close()
	return parsed if parsed is Dictionary else {}
