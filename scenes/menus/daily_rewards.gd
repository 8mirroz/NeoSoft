extends PremiumScreen

var _claim_button: Button
var _claim_state: Label
var _featured_container: Control

func _ready() -> void:
	var body := setup_screen("Daily Rewards", "Log in each day to claim your soft frost gifts", &"none")
	
	# Horizontal grid for 7-day calendar
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	
	var config_data := _config()
	var rewards: Array = config_data.get("daily_rewards", [])
	var next_index := int(UserData.daily_reward_state.get("claim_index", 0)) % maxi(rewards.size(), 1)
	var already_claimed_today := UserData.has_claimed_daily_reward_today()
	
	for index in range(rewards.size()):
		var reward: Dictionary = rewards[index]
		var day_num := int(reward.get("day", index + 1))
		
		# Claim statuses:
		# - Claimed: index < next_index OR (index == next_index AND already_claimed_today)
		# - Today: index == next_index AND not already_claimed_today
		# - Future: index > next_index OR (index == next_index AND already_claimed_today)
		var is_claimed := index < next_index or (index == next_index and already_claimed_today)
		var is_today := index == next_index and not already_claimed_today
		
		var title_suffix := ""
		var status_text := ""
		if is_claimed:
			title_suffix = " ✓"
			status_text = "Claimed"
		elif is_today:
			title_suffix = " ✦"
			status_text = "Today!"
		else:
			status_text = "Locked 🔒"
			
		var note := "%d coins" % int(reward.get("coins", 0))
		if reward.has("booster"):
			note += " + %s" % String(reward.get("booster", "")).capitalize()
			
		var card := info_card("Day %d%s" % [day_num, title_suffix], String(reward.get("label", "Reward")), note)
		
		# Stylize today's card with glowing borders
		if is_today:
			card.add_theme_stylebox_override("panel", panel_style("menu.surface.scroll"))
		elif is_claimed:
			card.modulate.a = 0.55
			
		grid.add_child(card)

	# Featured Reward Showcase (Glass podium with rotating procedural sphere!)
	var featured_lbl := Label.new()
	featured_lbl.text = "✦ Today's Highlight ✦"
	featured_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	featured_lbl.add_theme_font_size_override("font_size", 20)
	featured_lbl.add_theme_color_override("font_color", token_color("menu.text.title", Color("#2E2947")))
	body.add_child(featured_lbl)

	_featured_container = Control.new()
	_featured_container.custom_minimum_size = Vector2(200, 200)
	_featured_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(_featured_container)

	var orb_draw = OrbDrawScript.new()
	orb_draw.name = "OrbDraw"
	orb_draw.palette = {
		"pedestal": token_color("menu.visual.orb_pedestal", Color("#B8A6D642")),
		"orbit": token_color("menu.visual.orb_orbit", Color("#FFFFFF75")),
		"base": token_color("menu.visual.orb_base", Color("#FAF5FFB8")),
		"pink": token_color("menu.visual.orb_pink", Color("#FFBDD661")),
		"blue": token_color("menu.visual.orb_blue", Color("#BDD6FF5C")),
		"mint": token_color("menu.visual.orb_mint", Color("#CCFAD947")),
		"gold": token_color("menu.visual.orb_gold", Color("#FFEBC24D")),
		"gloss": token_color("menu.visual.orb_gloss", Color("#FFFFFFBF")),
		"arc": token_color("menu.visual.orb_arc", Color("#FFFFFF52")),
	}
	orb_draw.anchors_preset = Control.PRESET_FULL_RECT
	orb_draw.grow_horizontal = Control.GROW_DIRECTION_BOTH
	orb_draw.grow_vertical = Control.GROW_DIRECTION_BOTH
	_featured_container.add_child(orb_draw)

	_claim_state = Label.new()
	_claim_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_claim_state.add_theme_color_override("font_color", token_color("menu.text.muted", Color("#6D6788")))
	body.add_child(_claim_state)
	
	_claim_button = make_button("Claim Today's Reward", &"daily.claim", _claim_reward, true)
	_claim_button.custom_minimum_size = Vector2(0, 66)
	body.add_child(_claim_button)
	
	# Daily quest panel
	var quest_panel := info_card("Daily Quest", "Play one level", "Progress: %d / 1" % mini(UserData.total_sessions, 1))
	body.add_child(quest_panel)
	
	_refresh_claim_state()

func _claim_reward() -> void:
	SoundManager.play("tap")
	var reward := UserData.claim_daily_reward()
	if bool(reward.get("claimed", false)):
		show_toast("Claimed: +%d coins!" % int(reward.get("coins", 0)))
		SoundManager.play("win")
	else:
		show_toast("Today's reward is already claimed.")
		
	# Refresh screen after claim
	UIScreenManager.navigate(&"daily_rewards")

func _refresh_claim_state() -> void:
	var claimed := UserData.has_claimed_daily_reward_today()
	_claim_button.disabled = claimed
	_claim_state.text = "Gift claimed! Come back tomorrow for the next item." if claimed else "Your daily magical gift is ready."

func _config() -> Dictionary:
	var file := FileAccess.open("res://data/economy/reward_profiles.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else {}
	if file != null:
		file.close()
	return parsed if parsed is Dictionary else {}

# Custom Nested Control for procedural rotating sphere inside showcase
class OrbDrawScript extends Control:
	var rot_angle: float = 0.0
	var pulse_timer: float = 0.0
	var palette: Dictionary = {}
	
	func _ready() -> void:
		set_process(true)
		
	func _process(delta: float) -> void:
		rot_angle += delta * 0.35
		pulse_timer += delta * 1.5
		queue_redraw()
		
	func _draw() -> void:
		var center = size * 0.5
		var pulse = 1.0 + sin(pulse_timer) * 0.02
		var base_radius = 65.0 * pulse
		
		# Pedestal
		var ped_center = center + Vector2(0, 72)
		var ped_size = Vector2(85, 14)
		var ped_pts = PackedVector2Array()
		var steps = 36
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			ped_pts.append(ped_center + Vector2(cos(a) * ped_size.x, sin(a) * ped_size.y))
		draw_polygon(ped_pts, [palette.get("pedestal", Color.WHITE)])
		
		# Orbit
		var orbit_pts = PackedVector2Array()
		var orbit_rot = sin(rot_angle * 0.3) * 0.08
		for i in range(steps + 1):
			var a = float(i) / steps * TAU
			var pt = Vector2(cos(a) * (base_radius * 1.45), sin(a) * (base_radius * 0.35))
			var rot_pt = Vector2(
				pt.x * cos(orbit_rot) - pt.y * sin(orbit_rot),
				pt.x * sin(orbit_rot) + pt.y * cos(orbit_rot)
			)
			orbit_pts.append(center + rot_pt)
		
		draw_polyline(orbit_pts, palette.get("orbit", Color.WHITE), 1.6)
		
		# Base sphere
		draw_circle(center, base_radius, palette.get("base", Color.WHITE))
		
		# Aurora layers
		var aurora_layers = [
			{"color": palette.get("pink", Color.WHITE), "speed": 1.0, "scale": 0.85, "phase": 0.0},
			{"color": palette.get("blue", Color.WHITE), "speed": -0.8, "scale": 0.80, "phase": 2.1},
			{"color": palette.get("mint", Color.WHITE), "speed": 1.2, "scale": 0.75, "phase": 1.2},
			{"color": palette.get("gold", Color.WHITE), "speed": -0.6, "scale": 0.90, "phase": 3.4}
		]
		
		for layer in aurora_layers:
			var ang = rot_angle * layer["speed"] + layer["phase"]
			var offset = Vector2(cos(ang), sin(ang)) * (base_radius * 0.16)
			draw_circle(center + offset, base_radius * layer["scale"], layer["color"])
			
		# GlossySpecular Top Flare
		var specular_pos = center - Vector2(base_radius * 0.34, base_radius * 0.34)
		draw_circle(specular_pos, base_radius * 0.26, palette.get("gloss", Color.WHITE))
		draw_circle(specular_pos - Vector2(1,1), base_radius * 0.12, Color.WHITE)
		draw_arc(center, base_radius * 0.92, -PI * 0.18, PI * 1.7, 34, palette.get("arc", Color.WHITE), 1.8)
