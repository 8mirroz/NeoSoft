extends "res://addons/gut/test.gd"

# Юнит-тесты для ComboFeverController

func test_combo_window_opens_and_decays() -> void:
	var controller := ComboFeverController.new()
	watch_signals(controller)
	
	var power := controller.on_match_detected("LINE_3")
	
	assert_gt(power, 0.0, "ComboPower должна быть больше 0")
	assert_gt(controller.combo_window_remaining, 0.0, "Окно должно открыться")
	assert_signal_emitted(controller, "combo_window_opened")
	
	# Имитируем прохождение времени
	controller.update(2.0)
	
	assert_eq(controller.combo_window_remaining, 0.0, "Окно должно закрыться по истечении времени")
	assert_eq(controller.chain_index, 0, "Цепочка должна сброситься")
	assert_signal_emitted(controller, "combo_expired")

func test_combo_refresh_and_fever_activation() -> void:
	var controller := ComboFeverController.new()
	watch_signals(controller)
	
	# Делаем серию быстрых матчей
	controller.on_match_detected("LINE_3")
	controller.on_match_detected("LINE_3")
	controller.on_match_detected("LINE_4")
	controller.on_match_detected("LINE_3")
	
	assert_eq(controller.chain_index, 4)
	assert_false(controller.is_fever_active, "Fever не должен активироваться до 5 комбо")
	
	# 5-й матч активирует Fever Mode
	controller.on_match_detected("LINE_5")
	
	assert_eq(controller.chain_index, 5)
	assert_true(controller.is_fever_active, "Fever должен быть активен при Combo >= 5")
	assert_signal_emitted(controller, "fever_activated")

func test_invalid_move_penalty() -> void:
	var controller := ComboFeverController.new()
	
	controller.on_match_detected("LINE_3")
	var initial_remaining := controller.combo_window_remaining
	
	# Делаем невалидный ход
	controller.on_invalid_move()
	
	assert_lt(controller.combo_window_remaining, initial_remaining, "Окно должно уменьшиться из-за штрафа")

func test_combo_power_clamping() -> void:
	var controller := ComboFeverController.new()
	
	# Очень высокие параметры должны зажиматься максимальным порогом (max_power = 1500)
	var power_extreme := controller.on_match_detected("COMPLEX_7_PLUS", 500.0, true, true)
	
	assert_eq(power_extreme, controller.max_power, "Мощность должна быть жестко зажата до max_power")
	
	# Очень низкие должны быть не менее min_power = 100
	var power_low := controller.sigmoid_curve(10.0)
	assert_gte(power_low, controller.min_power, "Мощность должна быть не менее min_power")
