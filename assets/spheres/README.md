# Spheres Asset Pack

Тестовый набор из 8 сфер для match-3 игры.

## Список сфер

| ID | Name | Anchor | Blend Mode | Usage |
|----|------|--------|------------|-------|
| 01 | iridescent_frost | Плотный, матовый белый шар. Максимальная масса. | Add | AnimatedSprite2D |
| 02 | clear_glass | Тонкий, абсолютно прозрачный контур. | Screen | ShaderMaterial (преломление) |
| 03 | aqua_wave | Внутренняя жидкость, пузырек, четкий синий якорь. | Blend | ShaderMaterial (волна) + Particles |
| 04 | violet_pulse | Сложная внутренняя фасетка, фиолетово-синий якорь. | Blend | ShaderMaterial (пульсация) |
| 08 | warm_glow | Розовое/персиковое ядро, максимальное свечение. | Add | GPUParticles2D (сияние) |
| 09 | blue_ribbon | Голубая диагональная лента. | Blend | AnimatedSprite2D |
| 10 | purple_ribbon | Фиолетовая диагональная лента. | Blend | AnimatedSprite2D |
| P2 | cross_wave | Фасетчатая геометрия, спец-гем для креста. | Screen | GPUParticles2D |

## Структура

```
assets/spheres/
├── sphere_mapping.json          # Маппинг файлов
├── 01_iridescent_frost/
│   ├── info.json                # Мета-информация
│   └── 01_iridescent_frost_base.png
├── 02_clear_glass/
│   ├── info.json
│   └── 02_clear_glass_base.png
├── 03_aqua_wave/
│   ├── info.json
│   └── 03_aqua_wave_base.png
├── 04_violet_pulse/
│   ├── info.json
│   └── 04_violet_pulse_base.png
├── 08_warm_glow/
│   ├── info.json
│   └── 08_warm_glow_base.png
├── 09_blue_ribbon/
│   ├── info.json
│   └── 09_blue_ribbon_base.png
├── 10_purple_ribbon/
│   ├── info.json
│   └── 10_purple_ribbon_base.png
└── P2_cross_wave/
    ├── info.json
    └── P2_cross_wave_base.png
```

## Godot сцены

```
scenes/spheres/
├── 01_iridescent_frost.tscn
├── 02_clear_glass.tscn
├── 03_aqua_wave.tscn
├── 04_violet_pulse.tscn
├── 08_warm_glow.tscn
├── 09_blue_ribbon.tscn
├── 10_purple_ribbon.tscn
└── p2_cross_wave.tscn
```

## Использование

```gdscript
# Загрузка сферы
var sphere_scene = load("res://scenes/spheres/01_iridescent_frost.tscn")
var sphere = sphere_scene.instantiate()
add_child(sphere)

# Или через префаб
var gem = Gem.new(Gem.Type.FROST)
```

## Blend Modes

- **Add (2)**: Для светящихся объектов, добавляет яркость
- **Blend (0)**: Стандартное смешивание
- **Screen (1)**: Для прозрачных/стеклянных эффектов

## TODO

- [ ] Добавить анимации idle для каждой сферы
- [ ] Создать шейдеры для ShaderMaterial сфер
- [ ] Настроить GPUParticles2D для эффектных сфер
- [ ] Добавить 2 недостающие сферы (05, 06)
