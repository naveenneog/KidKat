// Imports the user-provided 3D logo images into KidKat branding assets:
//  - source/kidkat_icon.png (cat on gradient card) -> app_icon.png (full-bleed)
//  - source/kidkat_cat.png  (cat on white)         -> transparent cat for the
//    Android adaptive foreground + native splash (background flood-filled away,
//    interior whites like the eyes preserved).
const sharp = require('sharp');
const path = require('path');

const brand = path.resolve(__dirname, '..', '..', 'assets', 'branding');
const src = path.join(brand, 'source');

async function cropIcon() {
  // Trim the uniform outer background, leaving the rounded gradient card.
  const trimmed = await sharp(path.join(src, 'kidkat_icon.png'))
    .trim({ threshold: 25 })
    .toBuffer();
  const meta = await sharp(trimmed).metadata();
  const side = Math.min(meta.width, meta.height);
  const left = Math.round((meta.width - side) / 2);
  const top = Math.round((meta.height - side) / 2);
  await sharp(trimmed)
    .extract({ left, top, width: side, height: side })
    .resize(1024, 1024)
    .png()
    .toFile(path.join(brand, 'app_icon.png'));
  console.log('wrote app_icon.png');
}

async function transparentCat() {
  const { data, info } = await sharp(path.join(src, 'kidkat_cat.png'))
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const { width, height, channels } = info;

  const isBg = (i) => {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const mn = Math.min(r, g, b), mx = Math.max(r, g, b);
    return mn > 224 && mx - mn < 22;
  };

  const visited = new Uint8Array(width * height);
  const stack = [];
  const seed = (x, y) => {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    const p = y * width + x;
    if (visited[p]) return;
    visited[p] = 1;
    if (isBg(p * channels)) stack.push(p);
  };
  for (let x = 0; x < width; x++) { seed(x, 0); seed(x, height - 1); }
  for (let y = 0; y < height; y++) { seed(0, y); seed(width - 1, y); }
  while (stack.length) {
    const p = stack.pop();
    data[p * channels + 3] = 0; // make transparent
    const x = p % width, y = (p / width) | 0;
    seed(x + 1, y); seed(x - 1, y); seed(x, y + 1); seed(x, y - 1);
  }

  const catBuf = await sharp(data, { raw: { width, height, channels } })
    .png()
    .toBuffer();
  const cat = await sharp(catBuf).trim().toBuffer(); // tight crop

  const pad = (size, scale, out) => {
    const inner = Math.round(size * scale);
    const off = Math.round((size - inner) / 2);
    return sharp(cat)
      .resize(inner, inner, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .extend({
        top: off, bottom: size - inner - off,
        left: off, right: size - inner - off,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .png()
      .toFile(path.join(brand, out));
  };

  await pad(1024, 0.78, 'app_icon_foreground.png'); // adaptive safe zone
  await pad(1152, 0.62, 'splash_logo.png');
  console.log('wrote app_icon_foreground.png + splash_logo.png');
}

(async () => {
  await cropIcon();
  await transparentCat();
  console.log('IMPORT_DONE');
})().catch((e) => { console.error(e); process.exit(1); });
