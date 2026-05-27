extends RefCounted
class_name BoardThemeAdapter

var _board_view: Control

func setup(board_view: Control) -> void:
	_board_view = board_view

func _theme_tokens() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		var tree: SceneTree = loop as SceneTree
		return tree.root.get_node_or_null("ThemeTokensAutoload")
	return null

func tc(path: String, fallback: Color) -> Color:
	var tokens: Node = _theme_tokens()
	if tokens != null and tokens.has_method("color_path"):
		return tokens.color_path(path, fallback)
	return fallback
