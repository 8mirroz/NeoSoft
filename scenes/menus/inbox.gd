extends PremiumScreen

func _ready() -> void:
	var messages := UserData.inbox_messages.duplicate(true)
	var body := setup_screen("Inbox", "Rewards, unlocks and purchase confirmations", &"inbox")
	if messages.is_empty():
		body.add_child(info_card("No messages", "All clear", "Rewards and progress updates appear here."))
	else:
		for message in messages:
			var date_text := String(message.get("created_on", ""))
			body.add_child(info_card(String(message.get("title", "Notification")), String(message.get("body", "")), date_text))
	var read := make_button("Mark All Read", &"inbox.mark_read", _mark_read)
	read.disabled = UserData.get_unread_count() == 0
	body.add_child(read)
	UserData.mark_inbox_read()

func _mark_read() -> void:
	UserData.mark_inbox_read()
	show_toast("Inbox marked as read.")
