## Game Constants — все перечисления и константы проекта
## Без зависимостей от UI. Источник истины для всех модулей.
extends RefCounted
class_name GameConstants

# ──────────────────────────────────────────────
# Gem Types (p2.md §6, p1.md palette)
# ──────────────────────────────────────────────
enum GemType {
	FROST_PEARL    = 0,   # Белая жемчужная — волнистые линии внутри
	CLEAR_GLASS    = 1,   # Прозрачная стеклянная — кольца/кружки
	BLUE_FLOW      = 2,   # Голубая текучая — жидкая волна
	VIOLET_CORE    = 3,   # Фиолетовая ядро — пульсирующий центр
	MINT_WAVE      = 4,   # Мятная волна — пузырьковое движение
	AQUA_BUBBLE    = 5,   # Аквамариновый пузырь — мерцание
	# MVP: 6 базовых типов. Ниже — расширение на v1.0:
	WARM_GLOW      = 6,   # Тёплое свечение — лента
	PURPLE_RIBBON  = 7,   # Пурпурная лента — орбитальный блик
}

# ──────────────────────────────────────────────
# Special Gems (p2.md §8, NotebookLM match-3)
# ──────────────────────────────────────────────
enum SpecialGemType {
	NONE           = 0,
	LINE_BLAST_H   = 1,   # Ракета горизонтальная (match 4 в ряд)
	LINE_BLAST_V   = 2,   # Ракета вертикальная (match 4 в столбец)
	PULSE_BOMB     = 3,   # Бомба (T/L-форма, радиус 2.5 клетки)
	PRISM          = 4,   # Призма/радужная (match 5 в ряд)
}

# ──────────────────────────────────────────────
# Match Types
# ──────────────────────────────────────────────
enum MatchType {
	MATCH_3        = 3,
	MATCH_4        = 4,
	MATCH_5        = 5,
	MATCH_T        = 10,  # T-образное пересечение
	MATCH_L        = 11,  # L-образное пересечение
}

# ──────────────────────────────────────────────
# Blockers / Obstacles (p2.md §13)
# ──────────────────────────────────────────────
enum BlockerType {
	NONE           = 0,
	ICE_LAYER_1    = 1,   # Лёд (1 удар)
	ICE_LAYER_2    = 2,   # Лёд (2 удара)
	CHAIN          = 3,   # Цепь (1 удар)
	GLASS_CASE     = 4,   # Стеклянный кожух (1 удар)
	FROZEN_CELL    = 5,   # Замороженная ячейка (непроходимая)
}

# ──────────────────────────────────────────────
# Boosters (p2.md §12)
# ──────────────────────────────────────────────
enum BoosterType {
	HAMMER         = 0,   # Удалить 1 гем
	SHUFFLE        = 1,   # Перемешать поле
	UNDO           = 2,   # Отменить ход
}

# ──────────────────────────────────────────────
# Game State Machine states (master blueprint §7.1)
# ──────────────────────────────────────────────
enum GamePhase {
	IDLE           = 0,   # Ожидание ввода
	SWAP           = 1,   # Анимация свапа
	MATCH          = 2,   # Поиск и удаление совпадений
	FALL           = 3,   # Гравитация/осыпание
	SPAWN          = 4,   # Генерация новых гемов
	CASCADE_CHECK  = 5,   # Проверка каскадов
	SPECIAL_ACTION = 6,   # Активация спецгема/бустера
	WIN            = 7,   # Победа
	LOSE           = 8,   # Поражение
	PAUSED         = 9,   # Пауза
}

# ──────────────────────────────────────────────
# Goal Types (p2.md §10)
# ──────────────────────────────────────────────
enum GoalType {
	SCORE          = 0,   # Набрать X очков
	COLLECT_GEM    = 1,   # Собрать N гемов определённого цвета
	BREAK_BLOCKER  = 2,   # Разбить N блокеров
	REACH_BOTTOM   = 3,   # Дотянуть предмет до низа (v1.0)
}

# ──────────────────────────────────────────────
# Scoring Constants (p2.md §23, NotebookLM balance)
# ──────────────────────────────────────────────
const BASE_MATCH_SCORE: int = 60           # Match 3 = 20 × 3
const EXTRA_GEM_BONUS: int = 10            # Каждая доп. фишка сверх 3
const SPECIAL_GEM_BONUS: int = 400         # Создание спецгема
const REMAINING_MOVE_BONUS: int = 1000     # Бонус за каждый оставшийся ход

# Cascade multiplier: множитель = cascade_depth + 1
# Первый матч = ×1, второй каскад = ×2, третий = ×3 и т.д.

# ──────────────────────────────────────────────
# Stars (p2.md §23)
# ──────────────────────────────────────────────
const STAR_1_THRESHOLD: float = 0.40       # 40% target score
const STAR_2_THRESHOLD: float = 0.70       # 70% target score
const STAR_3_THRESHOLD: float = 1.00       # 100% target score

# ──────────────────────────────────────────────
# Animation Timings (p1.md, visual-acceptance.md)
# ──────────────────────────────────────────────
const TIMING_IDLE_MIN: float = 3.0
const TIMING_IDLE_MAX: float = 6.0
const TIMING_SELECT_MIN: float = 0.18
const TIMING_SELECT_MAX: float = 0.35
const TIMING_SWAP_MIN: float = 0.22
const TIMING_SWAP_MAX: float = 0.35
const TIMING_DISSOLVE_MIN: float = 0.35
const TIMING_DISSOLVE_MAX: float = 0.60
const TIMING_SPAWN_MIN: float = 0.25
const TIMING_SPAWN_MAX: float = 0.45
const TIMING_CASCADE_OFFSET: float = 0.05  # 1-2 кадра задержки между каскадами

# ──────────────────────────────────────────────
# Board defaults
# ──────────────────────────────────────────────
const DEFAULT_BOARD_WIDTH: int = 8
const DEFAULT_BOARD_HEIGHT: int = 8
const DEFAULT_GEM_KINDS_MVP: int = 6       # MVP: 6 базовых типов
const DEFAULT_GEM_KINDS_FULL: int = 8      # v1.0: 8 типов

# ──────────────────────────────────────────────
# Hint system (p2.md §22)
# ──────────────────────────────────────────────
const HINT_DELAY_SECONDS: float = 5.0      # Подсказка через 5-7 сек бездействия
const HINT_PULSE_DURATION: float = 1.5     # Длительность пульсации подсказки

# ──────────────────────────────────────────────
# VFX constraints (master blueprint §6)
# ──────────────────────────────────────────────
const VFX_MAX_RADIUS_CELLS: float = 1.0    # Эффект ≤ 1 клетки от центра
const VFX_BOMB_RADIUS_CELLS: float = 2.5   # Бомба: радиус 2.5 клетки
const VFX_SMOKE_RADIUS_CELLS: float = 1.0  # Дым: радиус 1 клетка

# ──────────────────────────────────────────────
# Empty cell marker
# ──────────────────────────────────────────────
const EMPTY_CELL: int = -1
