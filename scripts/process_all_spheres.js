const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const mapping = JSON.parse(fs.readFileSync('/Users/user/3-line/assets/spheres/sphere_mapping.json', 'utf8'));
const basePath = '/Users/user/3-line';

async function processSphere(sphereName, config) {
  console.log(`\n=== Processing ${sphereName} ===`);
  
  const sourcePath = path.join(basePath, config.source);
  const targetDir = path.join(basePath, 'assets/spheres', sphereName);
  
  if (!fs.existsSync(sourcePath)) {
    console.log(`✗ Source not found: ${config.source}`);
    return false;
  }
  
  // Копируем исходное изображение
  const targetPath = path.join(targetDir, `${sphereName}_base.png`);
  await sharp(sourcePath).toFile(targetPath);
  console.log(`✓ Copied to ${sphereName}_base.png`);
  
  // Создаем информацию о сфере
  const info = {
    name: sphereName,
    anchor: config.anchor,
    blend_mode: config.blend_mode,
    usage: config.usage,
    description: config.description,
    base_image: `${sphereName}_base.png`,
    animations: {
      idle: {
        spritesheet: `${sphereName}_idle.png`,
        frame_width: 128,
        frame_height: 128,
        cols: 4,
        rows: 1,
        total_frames: 4,
        fps: 8
      }
    }
  };
  
  fs.writeFileSync(path.join(targetDir, 'info.json'), JSON.stringify(info, null, 2));
  console.log(`✓ Info saved`);
  
  return true;
}

async function main() {
  const spheres = Object.keys(mapping);
  console.log(`Processing ${spheres.length} spheres...`);
  
  for (const sphereName of spheres) {
    await processSphere(sphereName, mapping[sphereName]);
  }
  
  console.log('\n✓ Done!');
}

main().catch(console.error);
