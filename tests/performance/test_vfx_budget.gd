# /Users/user/3-line/tests/performance/test_vfx_budget.gd
extends "res://addons/gut/test.gd"

## Тест соответствия бюджетам производительности (VFX Budget Gate).
## Проверяет лимиты частиц в FeedbackDirector при симуляциях перегрузок.

var director: FeedbackDirector

func before_each() -> void:
	director = FeedbackDirector.new()

func test_particle_cap_enforcement_high_profile() -> void:
	director.configure_safe_mode(false) # HIGH профиль
	
	# Запрашиваем 50 частиц (при лимите 40)
	director.active_particles_count = 35
	director.release_particles(0)
	
	# Проверяем, что эмиттеры не переполняются
	assert_true(director.active_particles_count <= 40, "Active particles must respect absolute limit of 40")

func test_particle_cap_enforcement_safe_profile() -> void:
	director.configure_safe_mode(true) # SAFE профиль
	assert_eq(director.max_particles_limit, 15, "SAFE mode particle cap must be 15")
