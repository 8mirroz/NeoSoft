extends Node

const SAVE_PATH = "user://save_data.cfg"

# Save structure
var unlocked_level: int = 1
var level_stars: Dictionary = {} # Maps level_number (int) -> stars_earned (int)
var level_scores: Dictionary = {} # Maps level_number (int) -> high_score (int)
var active_level: int = 1

# Economy & Boosters (p2.md §11, RULE-007)
var coins: int = 1000
var booster_inventory: Dictionary = {
	"hammer": 3,
	"shuffle": 3,
	"undo": 3
}

# Retention-lite progression
var daily_streak: int = 0
var last_played_on: String = ""
var total_sessions: int = 0
var total_retries: int = 0
var last_failure_streak: int = 0
var quality_profile: String = "web_default"

# Settings
var sound_enabled: bool = true
var music_enabled: bool = true

func _ready() -> void:
	load_data()

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("progression", "unlocked_level", unlocked_level)
	config.set_value("progression", "level_stars", level_stars)
	config.set_value("progression", "level_scores", level_scores)
	config.set_value("progression", "active_level", active_level)
	
	config.set_value("economy", "coins", coins)
	config.set_value("economy", "booster_inventory", booster_inventory)
	
	config.set_value("retention", "daily_streak", daily_streak)
	config.set_value("retention", "last_played_on", last_played_on)
	config.set_value("retention", "total_sessions", total_sessions)
	config.set_value("retention", "total_retries", total_retries)
	config.set_value("retention", "last_failure_streak", last_failure_streak)
	config.set_value("settings", "quality_profile", quality_profile)
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "music_enabled", music_enabled)
	
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("UserData: failed to save data")

func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		# Save default settings
		save_data()
		return
		
	unlocked_level = config.get_value("progression", "unlocked_level", 1)
	level_stars = config.get_value("progression", "level_stars", {})
	level_scores = config.get_value("progression", "level_scores", {})
	active_level = config.get_value("progression", "active_level", 1)
	
	coins = config.get_value("economy", "coins", 1000)
	var loaded_inventory = config.get_value("economy", "booster_inventory", {})
	for key in booster_inventory.keys():
		if loaded_inventory.has(key):
			booster_inventory[key] = int(loaded_inventory[key])
			
	daily_streak = config.get_value("retention", "daily_streak", 0)
	last_played_on = config.get_value("retention", "last_played_on", "")
	total_sessions = config.get_value("retention", "total_sessions", 0)
	total_retries = config.get_value("retention", "total_retries", 0)
	last_failure_streak = config.get_value("retention", "last_failure_streak", 0)
	quality_profile = config.get_value("settings", "quality_profile", "web_default")
	sound_enabled = config.get_value("settings", "sound_enabled", true)
	music_enabled = config.get_value("settings", "music_enabled", true)

func complete_level(level_num: int, score: int, stars: int) -> void:
	# Update score if higher
	var old_score = level_scores.get(level_num, 0)
	if score > old_score:
		level_scores[level_num] = score
		
	# Update stars if higher
	var old_stars = level_stars.get(level_num, 0)
	if stars > old_stars:
		level_stars[level_num] = stars
		
	# Unlock next level
	if level_num == unlocked_level:
		unlocked_level = level_num + 1

	last_failure_streak = 0
	
	# Award coins ethically for level completion
	var reward_amount := 100 + stars * 50
	coins = maxi(0, coins + reward_amount)
		
	save_data()

func set_active_level(level_num: int) -> void:
	active_level = maxi(1, level_num)
	save_data()

func record_session_start(level_num: int) -> void:
	active_level = maxi(1, level_num)
	total_sessions += 1
	_update_daily_streak()
	save_data()

func record_retry(level_num: int) -> void:
	active_level = maxi(1, level_num)
	total_retries += 1
	last_failure_streak += 1
	save_data()

func record_failure(level_num: int) -> void:
	active_level = maxi(1, level_num)
	last_failure_streak += 1
	save_data()

func get_completed_level_count() -> int:
	return level_scores.size()

func get_retention_summary() -> Dictionary:
	return {
		"daily_streak": daily_streak,
		"total_sessions": total_sessions,
		"total_retries": total_retries,
		"last_failure_streak": last_failure_streak,
		"completed_levels": get_completed_level_count(),
		"unlocked_level": unlocked_level,
	}

func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	save_data()

func get_booster_count(type_name: String) -> int:
	return int(booster_inventory.get(type_name, 0))

func add_booster(type_name: String, amount: int) -> void:
	var current := get_booster_count(type_name)
	booster_inventory[type_name] = maxi(0, current + amount)
	save_data()

func use_booster(type_name: String) -> bool:
	var current := get_booster_count(type_name)
	if current > 0:
		booster_inventory[type_name] = current - 1
		save_data()
		return true
	return false

func buy_booster(type_name: String, cost: int) -> bool:
	if coins >= cost:
		coins -= cost
		add_booster(type_name, 1)
		save_data()
		return true
	return false

func _update_daily_streak() -> void:
	var today := Time.get_date_string_from_system()
	if last_played_on == today:
		return

	if last_played_on.is_empty():
		daily_streak = 1
	else:
		var today_unix := Time.get_unix_time_from_datetime_string("%sT00:00:00" % today)
		var last_unix := Time.get_unix_time_from_datetime_string("%sT00:00:00" % last_played_on)
		var days_delta := int((today_unix - last_unix) / 86400.0)
		if days_delta == 1:
			daily_streak += 1
		elif days_delta != 0:
			daily_streak = 1

	last_played_on = today

func save_feedback(level_num: int, rating: int, comment: String) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("feedback", "level_%d_rating" % level_num, rating)
	config.set_value("feedback", "level_%d_comment" % level_num, comment)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("UserData: failed to save CSAT feedback")

func get_formatted_test_logs() -> String:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var feedback_dict := {}
	if config.has_section("feedback"):
		var keys := config.get_section_keys("feedback")
		for key in keys:
			var parts := key.split("_")
			if parts.size() >= 3 and parts[0] == "level":
				var lvl := parts[1]
				var field := parts[2]
				if not feedback_dict.has(lvl):
					feedback_dict[lvl] = {"rating": 0, "comment": ""}
				feedback_dict[lvl][field] = config.get_value("feedback", key)

	var events := []
	var analytics_path := "user://analytics_events.jsonl"
	if FileAccess.file_exists(analytics_path):
		var file := FileAccess.open(analytics_path, FileAccess.READ)
		if file != null:
			while not file.eof_reached():
				var line := file.get_line().strip_edges()
				if not line.is_empty():
					var json_var = JSON.parse_string(line)
					if json_var != null:
						events.append(json_var)
			file.close()

	var log_package := {
		"device_info": {
			"os": OS.get_name(),
			"screen_size": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
			"engine_version": "Godot " + Engine.get_version_info()["string"]
		},
		"visual_settings": {
			"quality_profile": quality_profile,
			"gem_glow_multiplier": 1.0 if quality_profile == "web_default" else 0.72
		},
		"csat_feedback": feedback_dict,
		"analytics_events": events
	}
	return JSON.stringify(log_package, "  ")
