extends PremiumScreen

func _ready() -> void:
	var body := setup_screen("Rankings", "Your local records - no online leaderboard", &"rankings")
	var rows := UserData.get_local_ranking_rows()
	var total_stars := 0
	for stars in UserData.level_stars.values():
		total_stars += int(stars)
	body.add_child(info_card("Personal Progress", "%d stars" % total_stars, "%d levels completed" % UserData.get_completed_level_count()))
	if rows.is_empty():
		body.add_child(info_card("No results yet", "Play a level", "Your best scores appear here."))
		return
	for index in range(mini(rows.size(), 10)):
		var result: Dictionary = rows[index]
		body.add_child(info_card("#%d  Level %02d" % [index + 1, int(result.get("level_id", 0))], "%d" % int(result.get("score", 0)), "%d stars" % int(result.get("stars", 0))))
