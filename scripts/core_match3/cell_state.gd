extends RefCounted
class_name CellState

enum State {
	STABLE,      # Ячейка полностью неподвижна, готова к свайпу
	LOCKED,      # Участвует во взрыве / активации эффекта
	FALLING,     # Находится в движении вниз (осыпание)
	SPAWNING,    # Новая сфера генерируется сверху
	RESOLVING,   # Обрабатывается матч-системой
	RESERVED,    # Зарезервирована queued-ходом
	BLOCKED,     # Препятствие (пустая плитка)
	TARGET       # Является активной целью уровня (лед, камень)
}

enum SphereType {
	NONE = 0,
	FROST = 1,           # 01_iridescent_frost
	GLASS = 2,           # 02_clear_glass
	AQUA = 3,            # 03_aqua_wave
	VIOLET = 4,          # 04_violet_pulse
	WARM = 8,            # 08_warm_glow
	BLUE_RIBBON = 9,     # 09_blue_ribbon
	PURPLE_RIBBON = 10,  # 10_purple_ribbon
	CROSS_WAVE = 99,     # P2_cross_wave (special)
}
