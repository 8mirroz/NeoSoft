extends Node

# SoundManager Autoload
# Manage UI and gameplay sounds with Kenney Interface Sounds

const AUDIO_PATH = "res://kenney_interface-sounds/Audio/"

# Sound streams dictionary
var _sounds: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 16
var _pool_index: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_load_sounds()
	_create_pool()
	
	# Automatically hook up any newly added Buttons in the scene tree
	get_tree().node_added.connect(_on_node_added)
	
	# Connect existing buttons in current scene tree
	_connect_buttons_recursive(get_tree().root)

func _load_sounds() -> void:
	# UI Sounds
	_sounds["hover"] = load(AUDIO_PATH + "click_004.ogg")
	_sounds["press"] = load(AUDIO_PATH + "click_001.ogg")
	_sounds["open"] = load(AUDIO_PATH + "open_001.ogg")
	_sounds["close"] = load(AUDIO_PATH + "close_001.ogg")
	_sounds["confirm"] = load(AUDIO_PATH + "confirmation_001.ogg")
	_sounds["confirm_star"] = load(AUDIO_PATH + "confirmation_002.ogg")
	_sounds["error"] = load(AUDIO_PATH + "error_001.ogg")
	_sounds["error_muted"] = load(AUDIO_PATH + "error_002.ogg")
	
	# Gameplay Sounds
	_sounds["select"] = load(AUDIO_PATH + "tick_001.ogg")
	_sounds["swap"] = load("res://assets/sounds/tile-swap.ogg") # Juicy swap
	_sounds["drop"] = load("res://assets/sounds/tile-land.ogg") # Juicy land
	_sounds["win"] = load(AUDIO_PATH + "confirmation_003.ogg")
	_sounds["lose"] = load(AUDIO_PATH + "error_003.ogg")
	
	# Juicy Match-3 sounds from Kenney Starter Kit
	_sounds["swap_juicy"] = load("res://assets/sounds/tile-swap.ogg")
	_sounds["match_juicy"] = load("res://assets/sounds/tile-match.ogg")
	_sounds["land_juicy"] = load("res://assets/sounds/tile-land.ogg")
	
	# Boosters
	_sounds["hammer"] = load(AUDIO_PATH + "scratch_001.ogg")
	_sounds["shuffle"] = load(AUDIO_PATH + "scroll_001.ogg")
	_sounds["undo"] = load(AUDIO_PATH + "back_001.ogg")
	
	# Cascades / Pops (glass sounds)
	_sounds["glass_1"] = load(AUDIO_PATH + "glass_001.ogg")
	_sounds["glass_2"] = load(AUDIO_PATH + "glass_002.ogg")
	_sounds["glass_3"] = load(AUDIO_PATH + "glass_003.ogg")
	_sounds["glass_4"] = load(AUDIO_PATH + "glass_004.ogg")
	_sounds["glass_5"] = load(AUDIO_PATH + "glass_005.ogg")

func _create_pool() -> void:
	for i in range(_pool_size):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)

# Play a sound by name, optionally setting volume_db offset and pitch_scale
func play(sound_name: String, volume_db_offset: float = 0.0, pitch: float = 1.0) -> void:
	if not UserData.sound_enabled:
		return
		
	var stream: AudioStream = _sounds.get(sound_name)
	if not stream:
		# Fallback check for glass sounds
		if sound_name.begins_with("glass_") and not _sounds.has(sound_name):
			stream = _sounds.get("glass_1")
		
	if stream:
		var player := _get_next_player()
		player.stream = stream
		player.volume_db = volume_db_offset
		player.pitch_scale = pitch
		player.play()

# Dynamic random glass/pop cascade sound with pitch shift based on cascade depth
func play_cascade(cascade_depth: int) -> void:
	var index := randi_range(1, 5)
	var sound_name := "glass_%d" % index
	# Meditative pitch increase for cascaded matches (+0.15 per depth level for REQ-COMBO-008)
	var target_pitch := clampf(1.0 + float(cascade_depth) * 0.15, 0.9, 2.0)
	# Soften cascades slightly to prevent ear fatigue (-4dB)
	play(sound_name, -4.0, target_pitch)
	# Also play a subtle juicy match layer
	play_match_juicy(cascade_depth)

# Play land sound with row-based pitch shifting from Kenney Starter Kit
func play_land_juicy(row: int) -> void:
	if not UserData.sound_enabled:
		return
	# Pitch shift based on row: lower row (higher y) has lower pitch, higher row (lower y) has higher pitch
	var target_pitch := clampf(1.2 - float(row) * 0.05, 0.8, 1.4)
	play("land_juicy", -8.0, target_pitch)

# Play juicy match sound with combo-based pitch shifting
func play_match_juicy(combo: int = 1) -> void:
	if not UserData.sound_enabled:
		return
	var target_pitch := clampf(1.0 + float(combo) * 0.15, 0.95, 2.0)
	play("match_juicy", -6.0, target_pitch)

func _get_next_player() -> AudioStreamPlayer:
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool_size
	return player

# Auto hook helper
func _on_node_added(node: Node) -> void:
	if node is Button:
		_hook_button(node)

func _connect_buttons_recursive(node: Node) -> void:
	if node is Button:
		_hook_button(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)

func _hook_button(btn: Button) -> void:
	# Avoid duplicate connections
	if not btn.mouse_entered.is_connected(_on_button_hover):
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
	if not btn.pressed.is_connected(_on_button_pressed):
		btn.pressed.connect(_on_button_pressed.bind(btn))

func _on_button_hover(btn: Button) -> void:
	if btn.disabled:
		return
	# Play hover at a reduced volume so it is extremely subtle (-12dB)
	play("hover", -12.0, 1.05)

func _on_button_pressed() -> void:
	play("press", -2.0, 1.0)
