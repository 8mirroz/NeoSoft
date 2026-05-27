extends PremiumScreen

func _ready() -> void:
	var body := setup_screen("Friends", "Invite someone to the soft-launch build", &"friends")
	body.add_child(info_card("Private Invite", "Neo Soft Frost", "Local build: no online friends list is shown."))
	var invite := make_button("Copy Invite Link", &"friends.invite", _copy_invite, true)
	invite.custom_minimum_size = Vector2(0, 68)
	body.add_child(invite)
	body.add_child(info_card("Share Text", "A quiet match-3 journey", "Join my Neo Soft Frost soft-launch session."))

func _copy_invite() -> void:
	DisplayServer.clipboard_set("Join me in Neo Soft Frost (soft-launch build): neosoftfrost://invite/local")
	UserData.record_notification("invite", {
		"title": "Invite copied",
		"body": "Your local invite text is ready to share.",
	})
	show_toast("Invite copied to clipboard.")
