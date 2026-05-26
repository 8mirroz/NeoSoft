# Sphere Assets — Handoff Document

Полный список созданных артефактов для интеграции в игру.

## 📦 Созданные артефакты

### 1. Ассеты сфер (8 типов)

```
assets/spheres/
├── sphere_mapping.json                    # Маппинг исходников → типы сфер
├── README.md                              # Документация набора
│
├── 01_iridescent_frost/
│   ├── info.json                          # Мета: anchor, blend_mode, usage
│   └── 01_iridescent_frost_base.png       # 1024×1024 PNG
│
├── 02_clear_glass/
│   ├── info.json
│   └── 02_clear_glass_base.png
│
├── 03_aqua_wave/
│   ├── info.json
│   └── 03_aqua_wave_base.png
│
├── 04_violet_pulse/
│   ├── info.json
│   └── 04_violet_pulse_base.png
│
├── 08_warm_glow/
│   ├── info.json
│   └── 08_warm_glow_base.png
│
├── 09_blue_ribbon/
│   ├── info.json
│   └── 09_blue_ribbon_base.png
│
├── 10_purple_ribbon/
│   ├── info.json
│   └── 10_purple_ribbon_base.png
│
└── P2_cross_wave/
    ├── info.json
    └── P2_cross_wave_base.png
```

### 2. Godot сцены (8 файлов)

```
scenes/spheres/
├── 01_iridescent_frost.tscn    # Blend: Add, AnimatedSprite2D
├── 02_clear_glass.tscn         # Blend: Screen, ShaderMaterial
├── 03_aqua_wave.tscn           # Blend: Blend, Shader + Particles
├── 04_violet_pulse.tscn        # Blend: Blend, ShaderMaterial
├── 08_warm_glow.tscn           # Blend: Add, GPUParticles2D
├── 09_blue_ribbon.tscn         # Blend: Blend, AnimatedSprite2D
├── 10_purple_ribbon.tscn       # Blend: Blend, AnimatedSprite2D
└── p2_cross_wave.tscn          # Blend: Screen, GPUParticles2D
```

### 3. Скрипты сфер (8 файлов)

```
scripts/spheres/
├── 01_iridescent_frost.gd
├── 02_clear_glass.gd
├── 03_aqua_wave.gd
├── 04_violet_pulse.gd
├── 08_warm_glow.gd
├── 09_blue_ribbon.gd
├── 10_purple_ribbon.gd
└── p2_cross_wave.gd
```

### 4. Утилиты обработки

```
scripts/
├── process_all_spheres.js      # Node.js: обработка всех сфер
├── create_godot_scenes.js      # Node.js: генерация .tscn файлов
├── create_spritesheet.js       # Node.js: создание спрайтшитов
└── process_sphere_frames.py    # Python: резервный скрипт
```

### 5. Тестовая сфера из видео

```
assets/spheres/test_sphere/
├── sphere_idle_spritesheet.png    # 512×4736, 145 кадров
├── sphere_idle_info.json          # Мета-информация
├── README.md                      # Документация
└── frame_*.png                    # 145 исходных кадров (можно удалить)
```

## 🎯 Как использовать

### Вариант 1: Прямая загрузка сцены

```gdscript
# В gem_view.gd или sphere_factory.gd
const SPHERE_SCENES = {
    SphereType.FROST: preload("res://scenes/spheres/01_iridescent_frost.tscn"),
    SphereType.GLASS: preload("res://scenes/spheres/02_clear_glass.tscn"),
    SphereType.AQUA: preload("res://scenes/spheres/03_aqua_wave.tscn"),
    SphereType.VIOLET: preload("res://scenes/spheres/04_violet_pulse.tscn"),
    SphereType.WARM: preload("res://scenes/spheres/08_warm_glow.tscn"),
    SphereType.BLUE_RIBBON: preload("res://scenes/spheres/09_blue_ribbon.tscn"),
    SphereType.PURPLE_RIBBON: preload("res://scenes/spheres/10_purple_ribbon.tscn"),
    SphereType.CROSS_WAVE: preload("res://scenes/spheres/p2_cross_wave.tscn"),
}

func create_sphere(type: SphereType) -> Node2D:
    var scene = SPHERE_SCENES[type]
    return scene.instantiate()
```

### Вариант 2: Динамическая загрузка

```gdscript
func load_sphere(sphere_id: String) -> Node2D:
    var path = "res://scenes/spheres/%s.tscn" % sphere_id.to_lower()
    var scene = load(path)
    return scene.instantiate()

# Использование
var frost_sphere = load_sphere("01_iridescent_frost")
add_child(frost_sphere)
```

### Вариант 3: Через info.json

```gdscript
func load_sphere_from_info(sphere_id: String) -> Node2D:
    var info_path = "res://assets/spheres/%s/info.json" % sphere_id
    var info = JSON.parse_string(FileAccess.get_file_as_string(info_path))
    
    var scene_path = "res://scenes/spheres/%s.tscn" % sphere_id.to_lower()
    var scene = load(scene_path)
    var sphere = scene.instantiate()
    
    # Применить настройки из info
    sphere.set_meta("blend_mode", info.blend_mode)
    sphere.set_meta("anchor", info.anchor)
    
    return sphere
```

## 🔧 Интеграция в существующий код

### 1. Обновить enum типов сфер

```gdscript
# В scripts/core_match3/cell_state.gd или sphere_type.gd
enum SphereType {
    FROST = 1,           # 01_iridescent_frost
    GLASS = 2,           # 02_clear_glass
    AQUA = 3,            # 03_aqua_wave
    VIOLET = 4,          # 04_violet_pulse
    WARM = 8,            # 08_warm_glow
    BLUE_RIBBON = 9,     # 09_blue_ribbon
    PURPLE_RIBBON = 10,  # 10_purple_ribbon
    CROSS_WAVE = 99,     # P2_cross_wave (special)
}
```

### 2. Создать фабрику сфер

```gdscript
# scripts/presentation/sphere_factory.gd
class_name SphereFactory
extends Node

const SPHERE_SCENES = {
    SphereType.FROST: preload("res://scenes/spheres/01_iridescent_frost.tscn"),
    SphereType.GLASS: preload("res://scenes/spheres/02_clear_glass.tscn"),
    SphereType.AQUA: preload("res://scenes/spheres/03_aqua_wave.tscn"),
    SphereType.VIOLET: preload("res://scenes/spheres/04_violet_pulse.tscn"),
    SphereType.WARM: preload("res://scenes/spheres/08_warm_glow.tscn"),
    SphereType.BLUE_RIBBON: preload("res://scenes/spheres/09_blue_ribbon.tscn"),
    SphereType.PURPLE_RIBBON: preload("res://scenes/spheres/10_purple_ribbon.tscn"),
    SphereType.CROSS_WAVE: preload("res://scenes/spheres/p2_cross_wave.tscn"),
}

static func create(type: SphereType) -> Node2D:
    if not SPHERE_SCENES.has(type):
        push_error("Unknown sphere type: %d" % type)
        return null
    
    var scene = SPHERE_SCENES[type]
    return scene.instantiate()
```

### 3. Использовать в gem_view.gd

```gdscript
# scripts/presentation/gem_view.gd
extends Node2D

var sphere_node: Node2D

func set_sphere_type(type: SphereType) -> void:
    # Удалить старую сферу
    if sphere_node:
        sphere_node.queue_free()
    
    # Создать новую
    sphere_node = SphereFactory.create(type)
    add_child(sphere_node)
    
    # Центрировать
    sphere_node.position = Vector2.ZERO
```

## 📋 Таблица соответствий

| ID | Name | Source File | Blend Mode | Usage | Priority |
|----|------|-------------|------------|-------|----------|
| 01 | iridescent_frost | image_7.png | Add | AnimatedSprite2D | Эталон |
| 02 | clear_glass | image_6.png | Screen | ShaderMaterial | Высокий |
| 03 | aqua_wave | image_3.png | Blend | Shader + Particles | Средний |
| 04 | violet_pulse | image_1.png | Blend | ShaderMaterial | Средний |
| 08 | warm_glow | image_4.png | Add | GPUParticles2D | Высокий |
| 09 | blue_ribbon | image_0.png | Blend | AnimatedSprite2D | Низкий |
| 10 | purple_ribbon | image_5.png | Blend | AnimatedSprite2D | Низкий |
| P2 | cross_wave | image_2.png | Screen | GPUParticles2D | Спец |

## ⚠️ Требуется доработка

### 1. Шейдеры (высокий приоритет)

Создать файлы:
- `shaders/sphere_refraction.gdshader` для 02_clear_glass
- `shaders/sphere_wave.gdshader` для 03_aqua_wave
- `shaders/sphere_pulse.gdshader` для 04_violet_pulse

### 2. Particles (средний приоритет)

Настроить ParticleMaterial:
- `08_warm_glow` — теплое сияние вокруг сферы
- `P2_cross_wave` — взрыв по кресту

### 3. Анимации (низкий приоритет)

Добавить idle анимации для:
- `01_iridescent_frost` — легкое покачивание
- `09_blue_ribbon` — вращение ленты
- `10_purple_ribbon` — вращение ленты

## 🚀 Быстрый старт

```bash
# 1. Открыть проект в Godot
godot --editor /Users/user/3-line/project.godot

# 2. Проверить импорт текстур
# Все PNG в assets/spheres/* должны импортироваться автоматически

# 3. Открыть тестовую сцену
# scenes/spheres/01_iridescent_frost.tscn

# 4. Запустить сцену (F6)
# Должна отобразиться белая матовая сфера

# 5. Интегрировать в gem_view.gd
# Использовать SphereFactory.create(type)
```

## 📝 Примечания

- Все PNG оптимизированы (1024×1024)
- Blend Mode настроен в каждой сцене
- info.json содержит anchor и usage для каждой сферы
- Скрипты содержат документацию в комментариях
- test_sphere/ — пример обработки видео в спрайтшит

## 🔗 Связанные документы

- `assets/spheres/README.md` — документация набора
- `assets/spheres/test_sphere/README.md` — пример обработки видео
- `genesis/v5/01_PRD.md` — требования к сферам
