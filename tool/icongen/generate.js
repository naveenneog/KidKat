// Rasterizes KidKat brand SVGs to PNGs used for app icons, adaptive icons and splash.
// Run: node generate.js   (from tool/icongen)
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const brand = path.resolve(__dirname, '..', '..', 'assets', 'branding');

async function render(svg, out, w, h) {
  const buf = fs.readFileSync(path.join(brand, svg));
  await sharp(buf, { density: 384 })
    .resize(w, h, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(path.join(brand, out));
  console.log('wrote', out, `${w}x${h}`);
}

(async () => {
  await render('app_icon.svg', 'app_icon.png', 1024, 1024);
  await render('app_icon_foreground.svg', 'app_icon_foreground.png', 1024, 1024);
  await render('app_icon_background.svg', 'app_icon_background.png', 1024, 1024);
  await render('app_icon_foreground.svg', 'splash_logo.png', 1152, 1152);
  await render('logo_wordmark.svg', 'logo_wordmark.png', 1500, 460);
  console.log('ALL_ICONS_DONE');
})().catch((e) => { console.error(e); process.exit(1); });
