const { chromium } = require('playwright-core');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const page = await browser.newPage({
    viewport: { width: 1500, height: 1200 },
    deviceScaleFactor: 2,
  });
  const file =
    'file://' +
    path.resolve(__dirname, '..', '..', 'docs', 'index.html').replace(/\\/g, '/');
  await page.goto(file, { waitUntil: 'load', timeout: 60000 });
  await page.waitForTimeout(1800);

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
