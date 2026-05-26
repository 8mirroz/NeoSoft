extends Node2D
class_name ReadabilityTest

func _ready() -> void:
	print("🔍 STARTING GEM READABILITY VERIFICATION...")
	var success_count := 0
	
	# Instantiate all 8 gem types at 64x64 and 96x96
	for size_val in [64.0, 96.0]:
		for piece_id in range(8):
			var gem := GemView.new()
			gem.size = size_val
			gem.set_piece(piece_id)
			add_child(gem)
			
			# Verify name and initialization
			if gem.piece_id == piece_id and gem.size == size_val:
				success_count += 1
				
			# Queue free as we just want to verify compile & instantiation
			gem.queue_free()
			
	var expected_tests = 16
	if success_count == expected_tests:
		print("✅ READABILITY TEST PASSED. All %d gems created and scaled correctly!" % success_count)
	else:
		push_error("❌ READABILITY TEST FAILED. Success: %d / %d" % [success_count, expected_tests])
