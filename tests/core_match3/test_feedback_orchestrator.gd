extends "res://addons/gut/test.gd"

# Юнит-тесты для FeedbackOrchestrator

func test_load_and_get_tier_for_combo() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	
	# Тестируем градацию Tiers (1, 5, 15)
	var t1: Dictionary = orchestrator.get_tier_for_combo(1)
	assert_eq(t1["tier_index"], 1, "Комбо 1 должно возвращать Tier 1")
	assert_eq(t1["sound_name"], "match_simple")
	
	var t5: Dictionary = orchestrator.get_tier_for_combo(5)
	assert_eq(t5["tier_index"], 5, "Комбо 5 должно возвращать Tier 5 (Fever Rush)")
	assert_eq(t5["sound_name"], "fever_triggered")
	
	var t15: Dictionary = orchestrator.get_tier_for_combo(15)
	assert_eq(t15["tier_index"], 8, "Комбо 15 должно возвращать Tier 8 (Cosmic Collapse)")
	assert_eq(t15["sound_name"], "singularity_core")

func test_particle_budget_web_profile() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	orchestrator.set_quality_profile("web_default") # Лимит 40 частиц
	
	watch_signals(orchestrator)
	
	var p1: int = orchestrator.request_particles(25)
	assert_eq(p1, 25, "В пределах бюджета должно выделяться 25 частиц")
	assert_eq(orchestrator.active_particles_count, 25)
	
	# Должно сработать ограничение бюджета
	var p2: int = orchestrator.request_particles(20)
	assert_eq(p2, 15, "Должно выделиться только 15 доступных частиц (лимит 40)")
	assert_signal_emitted(orchestrator, "budget_exhausted")
	assert_eq(orchestrator.active_particles_count, 40)

func test_particle_budget_android_profile() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	orchestrator.set_quality_profile("android_safe") # Лимит 15 частиц, размер/количество снижается на 50%
	
	watch_signals(orchestrator)
	
	# Запрашиваем 20 частиц, сработает деление пополам -> 10 частиц
	var p1: int = orchestrator.request_particles(20)
	assert_eq(p1, 10, "Должно выделиться 10 частиц (50% от 20)")
	assert_eq(orchestrator.active_particles_count, 10)
	
	# Запрашиваем еще 20 (деление пополам -> 10), должно выделиться только 5 (лимит 15)
	var p2: int = orchestrator.request_particles(20)
	assert_eq(p2, 5, "Должно выделиться только 5 доступных частиц (лимит 15)")
	assert_signal_emitted(orchestrator, "budget_exhausted")
	assert_eq(orchestrator.active_particles_count, 15)

func test_camera_shake_throttling() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	watch_signals(orchestrator)
	
	# Первая сильная тряска
	var s1: float = orchestrator.request_camera_shake(10.0, 0.0)
	assert_eq(s1, 10.0)
	
	# Вторая сильная тряска в том же 3-секундном окне
	var s2: float = orchestrator.request_camera_shake(8.0, 1.0)
	assert_eq(s2, 8.0)
	
	# Третья сильная тряска должна дросселироваться и возвращать 1.0 (микро-вибрация)
	var s3: float = orchestrator.request_camera_shake(12.0, 2.0)
	assert_eq(s3, 1.0, "Третья тряска за 3 секунды должна быть заменена на микро-вибрацию 1.0")
	assert_signal_emitted(orchestrator, "shake_throttled")
	
	# Спустя 4 секунды (окно обновилось) сильная тряска должна пройти успешно
	var s4: float = orchestrator.request_camera_shake(15.0, 5.0)
	assert_eq(s4, 15.0, "Спустя 4 секунды тряска должна успешно пройти")

func test_title_ui_spam_limiter() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	watch_signals(orchestrator)
	
	# Первый заголовок
	var r1: bool = orchestrator.request_combo_title("AWESOME", 0.0)
	assert_true(r1)
	
	# Второй заголовок слишком быстро (0.5с < 0.8с)
	var r2: bool = orchestrator.request_combo_title("RUSH", 0.5)
	assert_false(r2, "Должно быть подавлено, так как интервал меньше 0.8с")
	assert_signal_emitted(orchestrator, "title_suppressed")
	
	# Третий заголовок спустя 0.9с (0.9с > 0.8с)
	var r3: bool = orchestrator.request_combo_title("OVERDRIVE", 0.9)
	assert_true(r3, "Должно быть разрешено, так как прошло более 0.8с")

func test_orchestrate_combo_feedback() -> void:
	var orchestrator: FeedbackOrchestrator = FeedbackOrchestrator.new()
	
	# Запрашиваем оркестрацию для комбо 5 (Fever Rush)
	var feedback: Dictionary = orchestrator.orchestrate_combo_feedback(5, 0.0)
	
	assert_eq(feedback["tier_index"], 5)
	assert_eq(feedback["sound_name"], "fever_triggered")
	assert_gt(feedback["particles_spawned"], 0)
	assert_eq(feedback["shake_intensity"], 8.0)
	assert_true(feedback["show_title"])
	assert_eq(feedback["title_text"], "FEVER RUSH".to_upper())
	assert_eq(feedback["slowdown_factor"], 0.8)
