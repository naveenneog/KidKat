const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: process.env.PUPPETEER_EXEC || undefined,
    protocolTimeout: 120000,
    args: ['--no-sandbox', '--disable-gpu', '--force-color-profile=srgb'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1500, height: 1200, deviceScaleFactor: 2 });

  const file =
    'file://' +
    path.resolve(__dirname, '..', '..', 'docs', 'index.html').replace(/\\/g, '/');
  await page.goto(file, { waitUntil: 'load', timeout: 60000 });

  await Promise.race([
    page.evaluate('document.fonts.ready'),
    new Promise((r) => setTimeout(r, 4000)),
  ]);
  await new Promise((r) => setTimeout(r, 1500));

  const cards = await page.$$('.rail > div');
  for (let i = 0; i < cards.length; i++) {
    const out = path.resolve(__dirname, '..', '..', 'docs', 'img', `screen-${i + 1}.png`);
    await cards[i].screenshot({ path: out });
    console.log('wrote', out);
  }
  await browser.close();
  console.log('SHOTS_DONE');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
