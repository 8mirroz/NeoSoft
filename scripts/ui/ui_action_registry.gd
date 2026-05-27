extends RefCounted
class_name UIActionRegistry

## Auditable action vocabulary for visible, clickable UI controls.

const ACTION_TARGETS: Dictionary = {
	&"loading.start": &"main_menu",
	&"menu.play": &"world_map",
	&"menu.levels": &"world_map",
	&"menu.events": &"daily_rewards",
	&"menu.shop": &"shop",
	&"menu.coins_add": &"shop",
	&"menu.stars_add": &"daily_rewards",
	&"menu.settings": &"local",
	&"settings.close": &"local",
	&"settings.sound": &"local",
	&"settings.music": &"local",
	&"settings.haptics": &"local",
	&"settings.sound_volume": &"local",
	&"settings.music_volume": &"local",
	&"settings.quality": &"local",
	&"settings.export": &"local",
	&"nav.home": &"main_menu",
	&"nav.rankings": &"rankings",
	&"nav.collection": &"collection",
	&"nav.friends": &"friends",
	&"nav.inbox": &"inbox",
	&"nav.world": &"world_map",
	&"map.level": &"level_preview",
	&"map.events": &"daily_rewards",
	&"preview.start": &"gameplay",
	&"preview.booster": &"local",
	&"daily.claim": &"local",
	&"shop.tab": &"local",
	&"shop.purchase_booster": &"local",
	&"friends.invite": &"local",
	&"inbox.mark_read": &"local",
	&"game.pause": &"local",
	&"game.booster": &"local",
	&"game.feedback": &"local",
	&"game.export": &"local",
	&"game.resume": &"local",
	&"game.restart": &"gameplay",
	&"game.home": &"main_menu",
	&"game.next_level": &"level_preview",
	&"game.share": &"local",
	&"game.add_moves": &"local",
}

static func bind(button: BaseButton, action_id: StringName, handler: Callable) -> void:
	if not ACTION_TARGETS.has(action_id):
		push_error("UIActionRegistry: unregistered action '%s'" % String(action_id))
	button.set_meta(&"ui_action_id", String(action_id))
	button.pressed.connect(handler)

static func target_for(action_id: StringName) -> StringName:
	return ACTION_TARGETS.get(action_id, &"")

static func actions() -> Dictionary:
	return ACTION_TARGETS.duplicate(true)
