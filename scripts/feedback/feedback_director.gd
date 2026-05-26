# /Users/user/3-line/scripts/feedback/feedback_director.gd
class_name FeedbackDirector
extends RefCounted

## Оркестрирует аудиовизуальную отдачу по каскад-лестнице (Nice -> Fever Spark).
## Накладывает строгие ограничения производительности и Performance Budgets.

var config_path: String = "res://data/combo_vfx_tiers.json"
var tiers: Dictionary = {}
var active_particles_count: int = 0
var max_particles_limit: int = 40
var is_safe_mode: bool = false

func _get_game_event_bus() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("GameEventBus")
	return null

func _init() -> void:
	_load_config()
	# Подписываемся на события шины
	var bus := _get_game_event_bus()
	if bus != null:
		if bus.has_signal("cascade_step_resolved"):
			bus.connect("cascade_step_resolved", _on_cascade_step_resolved)
		if bus.has_signal("special_activated"):
			bus.connect("special_activated", _on_special_activated)

func _load_config() -> void:
	var fallback_tiers := {
		"1": {"name": "Nice", "particle_count": 8, "shake_intensity": 0.0, "sfx": "nice_ping"},
		"2": {"name": "Combo", "particle_count": 15, "shake_intensity": 2.0, "sfx": "combo_chime"},
		"3": {"name": "Chain Reaction", "particle_count": 25, "shake_intensity": 5.0, "sfx": "rising_arpeggio"},
		"4": {"name": "Cascade Surge", "particle_count": 40, "shake_intensity": 10.0, "sfx": "bass_impact"},
		"5": {"name": "Fever Spark", "particle_count": 60, "shake_intensity": 15.0, "sfx": "epic_choir_blast"}
	}
	
	if not FileAccess.file_exists(config_path):
		tiers = fallback_tiers
		return
		
	var file = FileAccess.open(config_path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) == OK:
		tiers = json.data.get("feedback_tiers", fallback_tiers)
	else:
		tiers = fallback_tiers

func configure_safe_mode(safe: bool) -> void:
	is_safe_mode = safe
	if safe:
		max_particles_limit = 15
	else:
		max_particles_limit = 40

func _on_cascade_step_resolved(step: CascadeStep) -> void:
	var tier_key = str(clamp(step.depth_level, 1, 5))
	var tier = tiers.get(tier_key, tiers["1"])
	
	# Воспроизводим звук через роутер в зависимости от тира
	var sfx_name = tier.get("sfx", "nice_ping")
	# Эмуляция вызова звукового роутера
	print("FeedbackDirector: Playing SFX ", sfx_name)
	
	# Запуск тряски камеры с учетом бюджетов
	var shake_intensity = float(tier.get("shake_intensity", 0.0))
	if shake_intensity > 0.0 and not is_safe_mode:
		print("FeedbackDirector: Shaking camera with intensity ", shake_intensity)
		
	# Спавн частиц с жестким контролем бюджета
	var particles_requested = int(tier.get("particle_count", 8))
	if is_safe_mode:
		particles_requested = int(particles_requested * 0.5)
		
	var allowed_particles = min(particles_requested, max_particles_limit - active_particles_count)
	active_particles_count += allowed_particles
	print("FeedbackDirector: Spawning particles. Active: ", active_particles_count, "/", max_particles_limit)

func _on_special_activated(event: SpecialActivationEvent) -> void:
	# При активации спец-сфер запускаем яркий VFX взрыв
	print("FeedbackDirector: Detonated special type ", event.special_type, " at position ", event.position)

func release_particles(count: int) -> void:
	active_particles_count = max(0, active_particles_count - count)
