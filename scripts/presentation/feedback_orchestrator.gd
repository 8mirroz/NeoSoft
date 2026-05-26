# /Users/user/3-line/scripts/presentation/feedback_orchestrator.gd
extends RefCounted
class_name FeedbackOrchestrator

## Аудиовизуальный микшер и оптимизатор VFX (Feedback Tier Ladder).
## Управляет выделением лимитов VFX, дросселированием тряски экрана и suppression заголовков комбо.

signal budget_exhausted
signal shake_throttled
signal title_suppressed

var active_particles_count: int = 0
var particle_limit: int = 200
var particle_scale: float = 1.0
var last_title_time: float = -1.0
var title_interval: float = 0.8

var shakes_in_window: Array[float] = []

func _init() -> void:
	pass

func set_quality_profile(profile_name: String) -> void:
	if profile_name == "web_default":
		particle_limit = 40
		particle_scale = 1.0
	elif profile_name == "android_safe":
		particle_limit = 15
		particle_scale = 0.5
	else:
		particle_limit = 200
		particle_scale = 1.0

func request_particles(count: int) -> int:
	var scaled_count: int = int(float(count) * particle_scale)
	if active_particles_count + scaled_count > particle_limit:
		var allowed: int = max(0, particle_limit - active_particles_count)
		active_particles_count = particle_limit
		emit_signal("budget_exhausted")
		return allowed
	else:
		active_particles_count += scaled_count
		return scaled_count

func request_camera_shake(intensity: float, time_sec: float) -> float:
	# Очищаем старые тряски из 3-секундного окна
	var i := 0
	while i < shakes_in_window.size():
		if time_sec - shakes_in_window[i] >= 3.0:
			shakes_in_window.remove_at(i)
		else:
			i += 1
			
	if shakes_in_window.size() >= 2:
		emit_signal("shake_throttled")
		return 1.0
	else:
		shakes_in_window.append(time_sec)
		return intensity

func request_combo_title(_title: String, time_sec: float) -> bool:
	if last_title_time >= 0.0 and time_sec - last_title_time < title_interval:
		emit_signal("title_suppressed")
		return false
	last_title_time = time_sec
	return true

func get_tier_for_combo(combo: int) -> Dictionary:
	var tier_index := 1
	var sound_name := "match_simple"
	var title_text := "GREAT"
	var shake_intensity := 2.0
	var particles_count := 10
	var slowdown_factor := 1.0
	
	if combo >= 15:
		tier_index = 8
		sound_name = "singularity_core"
		title_text = "COSMIC COLLAPSE"
		shake_intensity = 15.0
		particles_count = 100
		slowdown_factor = 0.5
	elif combo >= 12:
		tier_index = 7
		sound_name = "supernova_charge"
		title_text = "SUPERNOVA"
		shake_intensity = 12.0
		particles_count = 80
		slowdown_factor = 0.6
	elif combo >= 10:
		tier_index = 6
		sound_name = "fever_boost"
		title_text = "OVERDRIVE"
		shake_intensity = 10.0
		particles_count = 60
		slowdown_factor = 0.7
	elif combo >= 5:
		tier_index = 5
		sound_name = "fever_triggered"
		title_text = "FEVER RUSH"
		shake_intensity = 8.0
		particles_count = 40
		slowdown_factor = 0.8
	elif combo >= 4:
		tier_index = 4
		sound_name = "fever_building"
		title_text = "FEVER BUILDING"
		shake_intensity = 6.0
		particles_count = 30
		slowdown_factor = 0.9
	elif combo >= 3:
		tier_index = 3
		sound_name = "match_triple"
		title_text = "AWESOME"
		shake_intensity = 4.0
		particles_count = 20
		slowdown_factor = 1.0
	elif combo >= 2:
		tier_index = 2
		sound_name = "match_double"
		title_text = "GOOD"
		shake_intensity = 3.0
		particles_count = 15
		slowdown_factor = 1.0
		
	return {
		"tier_index": tier_index,
		"sound_name": sound_name,
		"title_text": title_text,
		"shake_intensity": shake_intensity,
		"particles_count": particles_count,
		"slowdown_factor": slowdown_factor
	}

func orchestrate_combo_feedback(combo: int, time_sec: float) -> Dictionary:
	var tier: Dictionary = get_tier_for_combo(combo)
	var show_title: bool = request_combo_title(tier["title_text"], time_sec)
	var shake: float = request_camera_shake(tier["shake_intensity"], time_sec)
	var particles: int = request_particles(tier["particles_count"])
	
	return {
		"tier_index": tier["tier_index"],
		"sound_name": tier["sound_name"],
		"particles_spawned": particles,
		"shake_intensity": shake,
		"show_title": show_title,
		"title_text": tier["title_text"],
		"slowdown_factor": tier["slowdown_factor"]
	}
