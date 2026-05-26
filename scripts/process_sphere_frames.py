#!/usr/bin/env python3
import os, sys, math
from PIL import Image
import json

frames_dir = "/Users/user/3-line/assets/spheres/test_sphere"
frames = sorted([f for f in os.listdir(frames_dir) if f.startswith("frame_") and f.endswith(".png")])
print(f"✓ Найдено {len(frames)} кадров")

target_frame_size = 128
cols = 4
rows = math.ceil(len(frames) / cols)
spritesheet = Image.new('RGBA', (cols * target_frame_size, rows * target_frame_size), (0, 0, 0, 0))

for idx, frame_file in enumerate(frames):
    frame = Image.open(os.path.join(frames_dir, frame_file)).convert('RGBA')
    frame_resized = frame.resize((target_frame_size, target_frame_size), Image.Resampling.LANCZOS)
    col, row = idx % cols, idx // cols
    spritesheet.paste(frame_resized, (col * target_frame_size, row * target_frame_size), frame_resized)
    if (idx + 1) % 30 == 0:
        print(f"  {idx + 1}/{len(frames)}")

spritesheet.save(os.path.join(frames_dir, "sphere_idle_spritesheet.png"), 'PNG', optimize=True)
print(f"✓ Спрайтшит: {cols * target_frame_size}x{rows * target_frame_size}")

info = {
    "name": "sphere_idle",
    "spritesheet": "sphere_idle_spritesheet.png",
    "frame_width": target_frame_size,
    "frame_height": target_frame_size,
    "cols": cols,
    "rows": rows,
    "total_frames": len(frames),
    "fps": 24
}
with open(os.path.join(frames_dir, "sphere_idle_info.json"), 'w') as f:
    json.dump(info, f, indent=2)
print("✓ Готово!")
