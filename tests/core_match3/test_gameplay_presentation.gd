extends "res://addons/gut/test.gd"

const GameplayNodeRefsScript = preload("res://scenes/gameplay/contracts/gameplay_node_refs.gd")
const GameplaySceneContractScript = preload("res://scenes/gameplay/contracts/gameplay_scene_contract.gd")
const GameplayHUDPresenterScript = preload("res://scenes/gameplay/presenters/gameplay_hud_presenter.gd")
const GameplayOverlayControllerScript = preload("res://scenes/gameplay/presenters/gameplay_overlay_controller.gd")
const GameplayInputRouterScript = preload("res://scenes/gameplay/controllers/gameplay_input_router.gd")
const GameplayBoosterControllerScript = preload("res://scenes/gameplay/controllers/gameplay_booster_controller.gd")
const GameplayCFEControllerScript = preload("res://scenes/gameplay/controllers/gameplay_cfe_controller.gd")

func test_scene_contract_validation() -> void:
	var refs := GameplayNodeRefsScript.new()
	var contract := GameplaySceneContractScript.new(refs)
	var missing := refs.collect_missing()
	assert_gt(missing.size(), 0, "Missing list should not be empty for clean NodeRefs")

func test_booster_purchase_and_pricing() -> void:
	var controller := GameplayBoosterControllerScript.new()
	assert_eq(controller.BOOSTER_PRICES["shuffle"], 150)
	assert_eq(controller.BOOSTER_PRICES["hammer"], 250)
	assert_eq(controller.BOOSTER_PRICES["undo"], 200)

func test_input_router_modes_and_locking() -> void:
	var scene := Control.new()
	scene.set("session_finished", false)
	scene.set("session_paused", false)
	scene.set("hammer_mode", false)
	
	var router := GameplayInputRouterScript.new()
	router.setup(scene, null, null)
	
	router.set("mode", 3) # HARD_LOCK enum
	watch_signals(EventBus)
	
	router.on_cell_pressed(Vector2i.ZERO)
	assert_eq(get_signal_emit_count(EventBus, "gem_tapped"), 0, "No gem_tapped signals should be emitted")

func test_live_combo_queues_move() -> void:
	var scene := Control.new()
	scene.set("session_finished", false)
	scene.set("session_paused", false)
	scene.set("hammer_mode", false)
	
	var router := GameplayInputRouterScript.new()
	router.setup(scene, null, null)
	
	router.set("mode", 2) # LIVE_COMBO enum
	router.on_cell_pressed(Vector2i(1, 1))
	
	var pending: Array = router.get("pending_moves")
	assert_eq(pending.size(), 1, "Should queue one pending cell move during active combo window")
	assert_eq(pending[0], Vector2i(1, 1))

func test_live_combo_queue_full_rejection() -> void:
	var scene := Control.new()
	scene.set("session_finished", false)
	scene.set("session_paused", false)
	scene.set("hammer_mode", false)
	
	var router := GameplayInputRouterScript.new()
	router.setup(scene, null, null)
	
	router.set("mode", 2) # LIVE_COMBO enum
	router.set("max_pending_moves", 1)
	
	router.on_cell_pressed(Vector2i(1, 1))
	router.on_cell_pressed(Vector2i(2, 2))
	
	var pending: Array = router.get("pending_moves")
	assert_eq(pending.size(), 1, "Should reject subsequent moves if queue is at capacity")

func test_cfe_combo_intensity_resolution() -> void:
	var controller := GameplayCFEControllerScript.new()
	var resolved_base := controller.call("_resolve_intensity_tier", 1)
	var resolved_boosted := controller.call("_resolve_intensity_tier", 4)
	var resolved_epic := controller.call("_resolve_intensity_tier", 9)
	var resolved_mythic := controller.call("_resolve_intensity_tier", 14)
	
	assert_eq(resolved_base, "BASE")
	assert_eq(resolved_boosted, "BOOSTED")
	assert_eq(resolved_epic, "EPIC")
	assert_eq(resolved_mythic, "MYTHIC")
