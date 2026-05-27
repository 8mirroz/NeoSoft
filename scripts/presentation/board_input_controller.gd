extends RefCounted
class_name BoardInputController

var _board_view: Control # Dynamic BoardView
var _mouse_inside: bool = false
var drag_start_position: Vector2 = Vector2.ZERO

func setup(board_view: Control) -> void:
	_board_view = board_view

func on_mouse_entered() -> void:
	_mouse_inside = true
	set_cursor_state(false)

func on_mouse_exited() -> void:
	_mouse_inside = false
	_board_view.set("hovered_cell", Vector2i(-1, -1))
	Input.set_custom_mouse_cursor(null)
	_board_view.queue_redraw()

func set_cursor_state(closed: bool) -> void:
	if not _mouse_inside:
		return
	
	var cursor_open: Texture2D = _board_view.get("cursor_open")
	var cursor_closed: Texture2D = _board_view.get("cursor_closed")
	
	if closed:
		if cursor_closed != null:
			Input.set_custom_mouse_cursor(cursor_closed, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		if cursor_open != null:
			Input.set_custom_mouse_cursor(cursor_open, Input.CURSOR_ARROW, Vector2(16, 16))

func process_gui_input(event: InputEvent) -> void:
	var model: RefCounted = _board_view.get("board_model")
	if model == null:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var cell: Vector2i = _board_view.call("_cell_from_local", mouse_event.position)
				if cell != Vector2i(-1, -1):
					_board_view.set("drag_start_cell", cell)
					drag_start_position = mouse_event.position
					_board_view.set("is_dragging", true)
					set_cursor_state(true) # Closed fist cursor
					_board_view.emit_signal("cell_pressed", cell)
					_board_view.accept_event()
			else:
				if _board_view.get("is_dragging"):
					_board_view.set("is_dragging", false)
					_board_view.set("drag_start_cell", Vector2i(-1, -1))
					set_cursor_state(false) # Open hand cursor
					_board_view.accept_event()

	elif event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		
		# Prevent stuck drag state when mouse is released outside or during animation
		if _board_view.get("is_dragging") and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_board_view.set("is_dragging", false)
			_board_view.set("drag_start_cell", Vector2i(-1, -1))
			set_cursor_state(false)
			
		var cell: Vector2i = _board_view.call("_cell_from_local", motion_event.position)
		var hovered: Vector2i = _board_view.get("hovered_cell")
		if cell != hovered:
			_board_view.set("hovered_cell", cell)
			_board_view.queue_redraw()
		
		var drag_start_cell: Vector2i = _board_view.get("drag_start_cell")
		if _board_view.get("is_dragging") and drag_start_cell != Vector2i(-1, -1):
			var difference: Vector2 = motion_event.position - drag_start_position
			if difference.length() > 32.0:
				var dir := Vector2i.ZERO
				if abs(difference.x) > abs(difference.y):
					dir.x = 1 if difference.x > 0 else -1
				else:
					dir.y = 1 if difference.y > 0 else -1
				
				var target_cell: Vector2i = drag_start_cell + dir
				if model.call("is_in_bounds", target_cell):
					_board_view.emit_signal("cell_pressed", target_cell)
				
				# Finish drag transaction to prevent cascading swipes
				_board_view.set("is_dragging", false)
				_board_view.set("drag_start_cell", Vector2i(-1, -1))
				set_cursor_state(false)
				_board_view.accept_event()

	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			var cell: Vector2i = _board_view.call("_cell_from_local", touch_event.position)
			if cell != Vector2i(-1, -1):
				_board_view.set("drag_start_cell", cell)
				drag_start_position = touch_event.position
				_board_view.set("is_dragging", true)
				_board_view.emit_signal("cell_pressed", cell)
				_board_view.accept_event()
		else:
			_board_view.set("is_dragging", false)
			_board_view.set("drag_start_cell", Vector2i(-1, -1))
			_board_view.accept_event()

	elif event is InputEventScreenDrag and _board_view.get("is_dragging"):
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		var drag_start_cell: Vector2i = _board_view.get("drag_start_cell")
		if drag_start_cell != Vector2i(-1, -1):
			var difference: Vector2 = drag_event.position - drag_start_position
			if difference.length() > 32.0:
				var dir := Vector2i.ZERO
				if abs(difference.x) > abs(difference.y):
					dir.x = 1 if difference.x > 0 else -1
				else:
					dir.y = 1 if difference.y > 0 else -1
				
				var target_cell: Vector2i = drag_start_cell + dir
				if model.call("is_in_bounds", target_cell):
					_board_view.emit_signal("cell_pressed", target_cell)
				
				_board_view.set("is_dragging", false)
				_board_view.set("drag_start_cell", Vector2i(-1, -1))
				_board_view.accept_event()
