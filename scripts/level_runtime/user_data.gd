extends Node

const SAVE_PATH = "user://save_data.cfg"
const ECONOMY_CONFIG_PATH = "res://data/economy/reward_profiles.json"
const EXTRA_MOVES_COST_FALLBACK := 900

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
var sound_volume: float = 0.8
var music_volume: float = 0.8
var haptics_enabled: bool = true

# Local-only meta state
var daily_reward_state: Dictionary = {"last_claim_date": "", "claim_index": 0}
var quest_progress: Dictionary = {}
var inbox_messages: Array = []
var selected_boosters: Array = []
var collection_unlocks: Dictionary = {}
var best_result_flags: Dictionary = {}

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
	config.set_value("settings", "sound_volume", sound_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "haptics_enabled", haptics_enabled)
	config.set_value("meta", "daily_reward_state", daily_reward_state)
	config.set_value("meta", "quest_progress", quest_progress)
	config.set_value("meta", "inbox_messages", inbox_messages)
	config.set_value("meta", "selected_boosters", selected_boosters)
	config.set_value("meta", "collection_unlocks", collection_unlocks)
	config.set_value("meta", "best_result_flags", best_result_flags)
	
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
	sound_volume = float(config.get_value("settings", "sound_volume", 0.8))
	music_volume = float(config.get_value("settings", "music_volume", 0.8))
	haptics_enabled = bool(config.get_value("settings", "haptics_enabled", true))
	daily_reward_state = config.get_value("meta", "daily_reward_state", {"last_claim_date": "", "claim_index": 0})
	quest_progress = config.get_value("meta", "quest_progress", {})
	inbox_messages = config.get_value("meta", "inbox_messages", [])
	selected_boosters = config.get_value("meta", "selected_boosters", [])
	collection_unlocks = config.get_value("meta", "collection_unlocks", {})
	best_result_flags = config.get_value("meta", "best_result_flags", {})

func complete_level(level_num: int, score: int, stars: int) -> void:
	# Update score if higher
	var old_score = level_scores.get(level_num, 0)
	var was_unlocked := unlocked_level
	if score > old_score:
		level_scores[level_num] = score
		best_result_flags[level_num] = true
		
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
	record_notification("level_complete", {
		"title": "Level %d complete" % level_num,
		"body": "+%d coins earned" % reward_amount,
		"level_id": level_num,
	}, false)
	if unlocked_level > was_unlocked:
		record_notification("unlock", {
			"title": "New level unlocked",
			"body": "Level %d is ready to preview." % unlocked_level,
			"level_id": unlocked_level,
		}, false)
		
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
		booster_inventory[type_name] = get_booster_count(type_name) + 1
		save_data()
		return true
	return false

func set_selected_boosters(boosters: Array) -> void:
	selected_boosters = boosters.duplicate()
	save_data()

func claim_daily_reward() -> Dictionary:
	var today := Time.get_date_string_from_system()
	if String(daily_reward_state.get("last_claim_date", "")) == today:
		return {"claimed": false, "reason": "already_claimed"}
	var config := _get_economy_config()
	var rewards: Array = config.get("daily_rewards", [])
	if rewards.is_empty():
		return {"claimed": false, "reason": "configuration_missing"}
	var claim_index := int(daily_reward_state.get("claim_index", 0))
	var reward: Dictionary = rewards[claim_index % rewards.size()].duplicate(true)
	var coin_reward := int(reward.get("coins", 0))
	coins += coin_reward
	var booster := String(reward.get("booster", ""))
	if not booster.is_empty():
		booster_inventory[booster] = get_booster_count(booster) + int(reward.get("quantity", 1))
	daily_reward_state = {
		"last_claim_date": today,
		"claim_index": claim_index + 1,
	}
	reward["claimed"] = true
	record_notification("daily_reward", {
		"title": "Daily reward claimed",
		"body": "+%d coins%s" % [coin_reward, " and " + booster if not booster.is_empty() else ""],
	}, false)
	save_data()
	EventBus.reward_claimed.emit(reward)
	return reward

func has_claimed_daily_reward_today() -> bool:
	return String(daily_reward_state.get("last_claim_date", "")) == Time.get_date_string_from_system()

func purchase_shop_item(item_id: String) -> Dictionary:
	for item in _get_economy_config().get("shop_items", []):
		if String(item.get("id", "")) != item_id:
			continue
		var cost := int(item.get("cost", 0))
		if coins < cost:
			return {"purchased": false, "reason": "insufficient_coins", "cost": cost}
		coins -= cost
		booster_inventory[item_id] = get_booster_count(item_id) + 1
		record_notification("purchase", {
			"title": "%s purchased" % String(item.get("title", item_id)),
			"body": "Spent %d coins." % cost,
		}, false)
		save_data()
		return {"purchased": true, "item_id": item_id, "cost": cost}
	return {"purchased": false, "reason": "unknown_item"}

func buy_extra_moves(level_id: int) -> bool:
	var cost := get_extra_moves_cost()
	if coins < cost:
		return false
	coins -= cost
	record_notification("purchase", {
		"title": "Moves restored",
		"body": "Added 5 moves on Level %d." % level_id,
	}, false)
	save_data()
	return true

func get_extra_moves_cost() -> int:
	return int(_get_economy_config().get("extra_moves_cost", EXTRA_MOVES_COST_FALLBACK))

func record_notification(type_name: String, payload: Dictionary, persist: bool = true) -> void:
	var message := payload.duplicate(true)
	message["type"] = type_name
	message["created_on"] = Time.get_datetime_string_from_system()
	message["read"] = false
	inbox_messages.push_front(message)
	if inbox_messages.size() > 40:
		inbox_messages.resize(40)
	if persist:
		save_data()

func mark_inbox_read() -> void:
	for index in range(inbox_messages.size()):
		var message: Dictionary = inbox_messages[index]
		message["read"] = true
		inbox_messages[index] = message
	save_data()

func get_unread_count() -> int:
	var unread := 0
	for message in inbox_messages:
		if not bool(message.get("read", false)):
			unread += 1
	return unread

func get_local_ranking_rows() -> Array:
	var rows: Array = []
	for level_id in level_scores.keys():
		rows.append({
			"level_id": int(level_id),
			"score": int(level_scores[level_id]),
			"stars": int(level_stars.get(level_id, 0)),
		})
	rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return int(first.get("score", 0)) > int(second.get("score", 0))
	)
	return rows

func get_collection_state() -> Array:
	var catalog := [
		{"id": "pearl", "title": "Pearl Sphere", "level": 1},
		{"id": "aqua", "title": "Aqua Sphere", "level": 1},
		{"id": "mint", "title": "Mint Sphere", "level": 2},
		{"id": "beam", "title": "Beam Sphere", "level": 3},
		{"id": "blast", "title": "Blast Sphere", "level": 5},
		{"id": "pulse", "title": "Pulse Sphere", "level": 7},
		{"id": "prism", "title": "Prism Sphere", "level": 9},
		{"id": "singularity", "title": "Singularity", "level": 10},
	]
	var state: Array = []
	for item in catalog:
		var entry: Dictionary = item.duplicate()
		entry["unlocked"] = unlocked_level >= int(item["level"])
		state.append(entry)
	return state

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

func _get_economy_config() -> Dictionary:
	if not FileAccess.file_exists(ECONOMY_CONFIG_PATH):
		return {"extra_moves_cost": EXTRA_MOVES_COST_FALLBACK}
	var file := FileAccess.open(ECONOMY_CONFIG_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {"extra_moves_cost": EXTRA_MOVES_COST_FALLBACK}

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
