extends SceneTree

func _init() -> void:
	var config := LevelLoader.load_soft_launch_config()
	var sizes: Array = config.get("visual_validation", {}).get("readability_sizes", [64, 96])
	var checks := 0

	for size_value in sizes:
		for piece_id in range(GameConstants.DEFAULT_GEM_KINDS_FULL):
			var gem := GemView.new()
			gem.size = float(size_value)
			gem.set_piece(piece_id)
			if gem.piece_id != piece_id or gem.size != float(size_value):
				push_error("Visual validation failed for piece %d size %s" % [piece_id, str(size_value)])
				quit(1)
				return
			gem.free()
			checks += 1

	print("VISUAL VALIDATION PASSED (%d checks)." % checks)
	quit(0)
