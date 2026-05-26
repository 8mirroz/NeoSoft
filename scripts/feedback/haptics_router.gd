# /Users/user/3-line/scripts/feedback/haptics_router.gd
class_name HapticsRouter
extends RefCounted

## Роутер мобильной вибрации и тактильной отдачи (Haptic Feedback) для iOS/Android.

var haptics_enabled: bool = true

func configure(enabled: bool) -> void:
	haptics_enabled = enabled

func trigger_haptic(tier: String) -> void:
	if not haptics_enabled:
		return
		
	match tier:
		"light":
			# Вызов нативного API Android/iOS
			print("HapticsRouter: Triggered LIGHT haptics.")
		"medium":
			print("HapticsRouter: Triggered MEDIUM haptics.")
		"heavy":
			print("HapticsRouter: Triggered HEAVY haptics.")
		"extreme":
			print("HapticsRouter: Triggered EXTREME haptics.")
