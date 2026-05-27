extends Control
class_name PremiumScreen

const ToastScene := preload("res://scenes/menus/toast_notification.tscn")
const ActionRegistry := preload("res://scripts/ui/ui_action_registry.gd")

var _body: VBoxContainer
var _root: VBoxContainer

func setup_screen(title: String, subtitle: String, active_tab: StringName = &"", world_nav: bool = false) -> VBoxContainer:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_top", 34)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_bottom", 24)
	add_child(margins)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 18)
	margins.add_child(_root)
	_root.add_child(build_top_bar())

	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", token_int("shared.font.title", 28) + 8)
	title_label.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	heading.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", token_int("shared.font.body", 16))
	sub_label.add_theme_color_override("font_color", token_color("menu.text.muted", Color("#6D6788")))
	heading.add_child(sub_label)
	_root.add_child(heading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", panel_style("menu.surface.scroll"))
	scroll.add_child(card)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", token_int("shared.spacing.lg", 18))
	card.add_child(_body)

	if active_tab != &"":
		_root.add_child(build_bottom_nav(active_tab, world_nav))
	return _body

func build_top_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 58)
	bar.add_theme_constant_override("separation", 12)
	bar.add_child(_currency_pill("coin", "O", str(UserData.coins), &"menu.coins_add", func() -> void:
		route(&"shop", {"shop_tab": "Coins"})
	))
	bar.add_child(_currency_pill("stars", "*", str(_total_stars()), &"menu.stars_add", func() -> void:
		route(&"daily_rewards")
	))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var inbox := make_button("Mail", &"nav.inbox", func() -> void: route(&"inbox"), false)
	inbox.custom_minimum_size = Vector2(76, 54)
	if UserData.get_unread_count() > 0:
		inbox.text = "Mail %d" % UserData.get_unread_count()
	bar.add_child(inbox)
	return bar

func build_bottom_nav(active_tab: StringName, world_nav: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 84)
	panel.add_theme_stylebox_override("panel", panel_style("menu.surface.card"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	panel.add_child(row)
	var tabs: Array[Dictionary] = [
		{"id": &"home", "label": "Home", "route": &"main_menu"},
		{"id": &"rankings", "label": "Rankings", "route": &"rankings"},
		{"id": &"collection", "label": "Collection", "route": &"collection"},
		{"id": &"friends", "label": "Friends", "route": &"friends"},
		{"id": &"inbox", "label": "Inbox", "route": &"inbox"},
	]
	if world_nav:
		tabs[3] = {"id": &"world", "label": "World", "route": &"world_map"}
	for tab in tabs:
		var tab_route: StringName = tab["route"]
		var button := make_button(String(tab["label"]), StringName("nav." + String(tab["id"])), func() -> void:
			route(tab_route)
		, tab["id"] == active_tab)
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	return panel

func make_button(text: String, action_id: StringName, handler: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.focus_mode = Control.FOCUS_ALL
	var prefix := "menu.surface.hero_button" if primary else "gameplay.button"
	if primary:
		button.add_theme_stylebox_override("normal", panel_style(prefix))
		button.add_theme_stylebox_override("hover", panel_style(prefix))
		button.add_theme_stylebox_override("pressed", panel_style(prefix))
	else:
		button.add_theme_stylebox_override("normal", button_style(prefix, "normal"))
		button.add_theme_stylebox_override("hover", button_style(prefix, "hover"))
		button.add_theme_stylebox_override("pressed", button_style(prefix, "pressed"))
		button.add_theme_stylebox_override("disabled", button_style(prefix, "disabled"))
	button.add_theme_color_override("font_color", token_color("shared.colors.text_primary", Color("#312D47")))
	button.add_theme_font_size_override("font_size", 16)
	ActionRegistry.bind(button, action_id, handler)
	return button

func info_card(title: String, value: String, note: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style("menu.surface.card"))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", token_color("menu.text.muted", Color("#6D6788")))
	content.add_child(head)
	var amount := Label.new()
	amount.text = value
	amount.add_theme_font_size_override("font_size", 25)
	amount.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	content.add_child(amount)
	if not note.is_empty():
		var description := Label.new()
		description.text = note
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 13)
		description.add_theme_color_override("font_color", token_color("menu.text.muted", Color("#6D6788")))
		content.add_child(description)
	return panel

func panel_style(path: String) -> StyleBoxFlat:
	var tokens := _tokens()
	if tokens != null:
		return tokens.make_panel_style(path)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.5)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	return style

func button_style(path: String, state: String) -> StyleBoxFlat:
	var tokens := _tokens()
	if tokens != null:
		return tokens.make_button_style(path, state)
	return panel_style("menu.surface.card")

func token_color(path: String, fallback: Color) -> Color:
	var tokens := _tokens()
	return tokens.color_path(path, fallback) if tokens != null else fallback

func token_int(path: String, fallback: int) -> int:
	var tokens := _tokens()
	return tokens.int_value(path, fallback) if tokens != null else fallback

func route(screen_id: StringName, payload: Dictionary = {}) -> void:
	UIScreenManager.navigate(screen_id, payload)

func show_toast(message: String) -> void:
	var toast := ToastScene.instantiate()
	add_child(toast)
	toast.show_message(message)

func _currency_pill(_id: String, icon: String, amount: String, action_id: StringName, handler: Callable) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(142, 54)
	pill.add_theme_stylebox_override("panel", panel_style("menu.surface.card"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_color_override("font_color", token_color("shared.colors.accent_gold", Color("#E7B446")))
	icon_label.add_theme_font_size_override("font_size", 20)
	row.add_child(icon_label)
	var value := Label.new()
	value.text = amount
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", token_color("shared.colors.text_primary", Color("#312D47")))
	row.add_child(value)
	var add := make_button("+", action_id, handler, false)
	add.custom_minimum_size = Vector2(34, 34)
	row.add_child(add)
	return pill

func _total_stars() -> int:
	var value := 0
	for stars in UserData.level_stars.values():
		value += int(stars)
	return value

func _tokens() -> Node:
	return get_tree().root.get_node_or_null("ThemeTokensAutoload")

func _draw() -> void:
	var top := token_color("shared.colors.bg_top", Color("#F3ECFB"))
	var bottom := token_color("shared.colors.bg_bottom", Color("#EAF1FF"))
	var sections := 24
	for index in range(sections):
		var factor := float(index) / float(sections - 1)
		draw_rect(Rect2(0, size.y * factor, size.x, size.y / sections + 1.0), top.lerp(bottom, factor))
	var accent := token_color("shared.colors.accent_primary", Color("#8D7AF8"))
	accent.a = 0.10
	draw_circle(Vector2(size.x * 0.18, size.y * 0.28), size.x * 0.34, accent)
	var mint := token_color("shared.colors.accent_secondary", Color("#73CDBA"))
	mint.a = 0.08
	draw_circle(Vector2(size.x * 0.82, size.y * 0.64), size.x * 0.32, mint)
