# Sphere Idle Animation Asset

## Источник
- **Video:** `grok-video-3b152e1f-9500-47ef-9ed3-58dde32fb5fd 2.mp4`
- **Duration:** 6.04 seconds
- **Original size:** 544×544
- **FPS:** 24

## Результат

### Spritesheet
- **File:** `sphere_idle_spritesheet.png`
- **Size:** 512×4736 (4×37 grid)
- **Frame size:** 128×128
- **Total frames:** 145
- **Optimized size:** 181 KB (vs 24 MB raw frames)

### Animation Info
```json
{
  "name": "sphere_idle",
  "frame_width": 128,
  "frame_height": 128,
  "cols": 4,
  "rows": 37,
  "total_frames": 145,
  "fps": 24,
  "duration_seconds": 6.04
}
```

## Использование в Godot

### Вариант 1: AnimatedSprite2D
```gdscript
var sprite = AnimatedSprite2D.new()
sprite.sprite_frames = SpriteFrames.new()
sprite.sprite_frames.add_animation("idle")

# Добавить кадры из спрайтшита
for i in range(145):
    var frame = AtlasTexture.new()
    frame.atlas = load("res://assets/spheres/test_sphere/sphere_idle_spritesheet.png")
    frame.region = Rect2((i % 4) * 128, (i / 4) * 128, 128, 128)
    sprite.sprite_frames.add_frame("idle", frame)

sprite.play("idle")
```

### Вариант 2: Sprite с шейдером
Использовать шейдер для анимации UV-координат по спрайтшиту.

## Файлы
- `sphere_idle_spritesheet.png` — основной спрайтшит
- `sphere_idle_info.json` — мета-информация
- `frame_*.png` — исходные кадры (можно удалить для экономии места)
- `README.md` — этот файл

## Оптимизация
Для production удалите исходные кадры:
```bash
rm /Users/user/3-line/assets/spheres/test_sphere/frame_*.png
```
Экономия: ~24 MB
