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
  const texturePath = `res://assets/spheres/${sphereName}/${sphereName}_base.png`;
  const sceneUid = `uid://${sphereName.toLowerCase()}`;
  const textureUid = `uid://${sphereName.toLowerCase()}_tex`;
  const shaderPath = {
    '02_clear_glass': 'res://shaders/sphere_refraction.gdshader',
    '03_aqua_wave': 'res://shaders/sphere_wave.gdshader',
    '04_violet_pulse': 'res://shaders/sphere_pulse.gdshader',
  }[sphereName];

  if (sphereName === '08_warm_glow' || sphereName === 'P2_cross_wave') {
    const isWarmGlow = sphereName === '08_warm_glow';
    const nodeName = isWarmGlow ? '08_warm_glow' : 'P2_cross_wave';
    const amount = isWarmGlow ? 24 : 36;
    const lifetime = isWarmGlow ? 1.1 : 0.95;
    const modulate = isWarmGlow ? '0.95' : '0.92';
    const particleParams = isWarmGlow
      ? `direction = Vector3(0, -1, 0)\nspread = 36.0\ninitial_velocity_min = 3.0\ninitial_velocity_max = 10.0\ngravity = Vector3(0, -1, 0)\nscale_min = 0.2\nscale_max = 0.48\ncolor = Color(1.0, 0.76, 0.58, 0.66)`
      : `direction = Vector3(0, -1, 0)\nspread = 72.0\ninitial_velocity_min = 8.0\ninitial_velocity_max = 22.0\ngravity = Vector3(0, 0, 0)\nscale_min = 0.18\nscale_max = 0.42\ncolor = Color(0.86, 0.94, 1.0, 0.74)`;

    return `[gd_scene load_steps=2 format=3 uid="${sceneUid}"]

[ext_resource type="Texture2D" path="${texturePath}" id="1_${sphereName.toLowerCase()}"]

[sub_resource type="ParticleProcessMaterial" id="ParticleMaterial_${sphereName}"]
${particleParams}

[node name="${nodeName}" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("1_${sphereName.toLowerCase()}")
centered = true
modulate = Color(1, 1, 1, ${modulate})

[node name="GPUParticles2D" type="GPUParticles2D" parent="."]
position = Vector2(0, 0)
amount = ${amount}
lifetime = ${lifetime}
emitting = true
local_coords = true
process_material = SubResource("ParticleMaterial_${sphereName}")
texture = ExtResource("1_${sphereName.toLowerCase()}")
`;
  }

  if (shaderPath) {
    const shaderParams = {
      '02_clear_glass': 'shader_parameter/tint_color = Color(0.84, 0.94, 1.0, 0.16)\nshader_parameter/refraction_strength = 0.018\nshader_parameter/edge_glow = 0.38',
      '03_aqua_wave': 'shader_parameter/tint_color = Color(0.48, 0.9, 0.98, 0.2)\nshader_parameter/wave_strength = 0.04\nshader_parameter/wave_speed = 2.6\nshader_parameter/wave_density = 16.0',
      '04_violet_pulse': 'shader_parameter/tint_color = Color(0.74, 0.56, 0.96, 0.24)\nshader_parameter/pulse_speed = 2.9\nshader_parameter/pulse_amplitude = 0.18',
    }[sphereName];

    return `[gd_scene load_steps=3 format=3 uid="${sceneUid}"]

[ext_resource type="Texture2D" path="${texturePath}" id="1_${sphereName.toLowerCase()}"]
[ext_resource type="Shader" path="${shaderPath}" id="2_${sphereName.toLowerCase()}_shader"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_${sphereName}"]
shader = ExtResource("2_${sphereName.toLowerCase()}_shader")
${shaderParams}

[node name="${sphereName}" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("1_${sphereName.toLowerCase()}")
centered = true
material = SubResource("ShaderMaterial_${sphereName}")
`;
  }

  const tint = sphereName === '01_iridescent_frost'
    ? 'Color(1, 1, 1, 0.98)'
    : sphereName === '09_blue_ribbon'
      ? 'Color(0.95, 0.98, 1.0, 0.96)'
      : 'Color(0.98, 0.92, 1.0, 0.96)';

  return `[gd_scene load_steps=2 format=3 uid="${sceneUid}"]

[ext_resource type="Texture2D" path="${texturePath}" id="1_${sphereName.toLowerCase()}"]

[node name="${sphereName}" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("1_${sphereName.toLowerCase()}")
centered = true
modulate = ${tint}
`;
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
