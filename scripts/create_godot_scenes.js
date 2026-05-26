const fs = require('fs');
const path = require('path');

const mapping = JSON.parse(fs.readFileSync('/Users/user/3-line/assets/spheres/sphere_mapping.json', 'utf8'));
const basePath = '/Users/user/3-line';

const blendModeMap = {
  'Add': '2',
  'Blend': '0',
  'Screen': '1',
  'Subtract': '3',
  'Multiply': '4'
};

function createScene(sphereName, config) {
  const blendMode = blendModeMap[config.blend_mode] || '0';
  const texturePath = `res://assets/spheres/${sphereName}/${sphereName}_base.png`;
  
  let sceneContent = `[gd_scene load_steps=2 format=3 uid="uid://${sphereName.toLowerCase()}"]

[ext_resource type="Texture2D" uid="uid://${sphereName.toLowerCase()}_tex" path="${texturePath}" id="1_${sphereName.toLowerCase()}"]

[node name="${sphereName}" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("1_${sphereName.toLowerCase()}")
centered = true
offset = Vector2(-64, -64)
modulate = Color(1, 1, 1, 1)
`;

  // Добавляем специфичные настройки в зависимости от типа
  if (config.usage.includes('AnimatedSprite2D')) {
    sceneContent += `hframes = 4
vframes = 1
frame = 0
playing = false
`;
  }
  
  // Добавляем material если нужен шейдер
  if (config.usage.includes('ShaderMaterial')) {
    sceneContent += `
[node name="Sprite2D" parent="." index="0"]
material = SubResource("ShaderMaterial_${sphereName}")
`;
  }
  
  // Добавляем particles если нужно
  if (config.usage.includes('GPUParticles2D')) {
    sceneContent += `
[node name="GPUParticles2D" type="GPUParticles2D" parent="."]
position = Vector2(0, 0)
amount = 32
lifetime = 1.0
process_material = SubResource("ParticleMaterial_${sphereName}")
texture = ExtResource("1_${sphereName.toLowerCase()}")
`;
  }
  
  return sceneContent;
}

function createSphereScript(sphereName, config) {
  return `extends Node2D

## ${config.description}
## Anchor: ${config.anchor}
## Blend Mode: ${config.blend_mode}
## Usage: ${config.usage}

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
`;
}

async function main() {
  const spheres = Object.keys(mapping);
  
  for (const sphereName of spheres) {
    const config = mapping[sphereName];
    
    // Создаем сцену
    const sceneContent = createScene(sphereName, config);
    const scenePath = path.join(basePath, 'scenes/spheres', `${sphereName.toLowerCase()}.tscn`);
    
    // Создаем папку если не существует
    const sceneDir = path.dirname(scenePath);
    if (!fs.existsSync(sceneDir)) {
      fs.mkdirSync(sceneDir, { recursive: true });
    }
    
    fs.writeFileSync(scenePath, sceneContent);
    console.log(`✓ Created: ${scenePath}`);
    
    // Создаем скрипт
    const scriptContent = createSphereScript(sphereName, config);
    const scriptPath = path.join(basePath, 'scripts/spheres', `${sphereName.toLowerCase()}.gd`);
    
    const scriptDir = path.dirname(scriptPath);
    if (!fs.existsSync(scriptDir)) {
      fs.mkdirSync(scriptDir, { recursive: true });
    }
    
    fs.writeFileSync(scriptPath, scriptContent);
    console.log(`✓ Created: ${scriptPath}`);
  }
  
  console.log('\n✓ All scenes and scripts created!');
}

main().catch(console.error);
