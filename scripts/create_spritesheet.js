const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const framesDir = '/Users/user/3-line/assets/spheres/test_sphere';
const outputDir = framesDir;

async function createSpritesheet() {
  const files = fs.readdirSync(framesDir)
    .filter(f => f.startsWith('frame_') && f.endsWith('.png'))
    .sort((a, b) => parseInt(a.replace('frame_', '').replace('.png', '')) - parseInt(b.replace('frame_', '').replace('.png', '')));
  
  console.log(`✓ Найдено ${files.length} кадров`);
  
  const targetSize = 128;
  const cols = 4;
  const rows = Math.ceil(files.length / cols);
  const width = cols * targetSize;
  const height = rows * targetSize;
  
  console.log(`✓ Спрайтшит: ${width}x${height} (${cols}x${rows})`);
  
  const canvas = Buffer.alloc(width * height * 4);
  const canvasImage = await sharp(canvas, { raw: { width, height, channels: 4 } }).toBuffer();
  
  for (let i = 0; i < files.length; i++) {
    const framePath = path.join(framesDir, files[i]);
    const frameBuffer = await sharp(framePath).resize(targetSize, targetSize, { fit: 'fill' }).toBuffer();
    const frameImage = await sharp(frameBuffer).raw().toBuffer();
    
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = col * targetSize;
    const y = row * targetSize;
    
    for (let py = 0; py < targetSize; py++) {
      const srcOffset = py * targetSize * 4;
      const dstOffset = (y + py) * width * 4 + x * 4;
      frameImage.copy(canvasImage, dstOffset, 0, srcOffset, targetSize * 4);
    }
    
    if ((i + 1) % 30 === 0) console.log(`  ${i + 1}/${files.length}`);
  }
  
  await sharp(canvasImage, { raw: { width, height, channels: 4 } })
    .png()
    .toFile(path.join(outputDir, 'sphere_idle_spritesheet.png'));
  
  console.log('✓ Спрайтшит сохранен');
  
  const info = {
    name: 'sphere_idle',
    spritesheet: 'sphere_idle_spritesheet.png',
    frame_width: targetSize,
    frame_height: targetSize,
    cols,
    rows,
    total_frames: files.length,
    fps: 24,
    duration_seconds: files.length / 24
  };
  
  fs.writeFileSync(path.join(outputDir, 'sphere_idle_info.json'), JSON.stringify(info, null, 2));
  console.log('✓ Информация сохранена');
}

createSpritesheet().catch(console.error);
