const { chromium } = require('playwright');
const fs = require('fs'); const path = require('path');
(async () => {
  const dir = __dirname;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.html')).sort()) {
    await page.goto('file://' + path.join(dir, f));
    await page.waitForTimeout(150);
    await page.screenshot({ path: path.join(dir, f.replace('.html', '.png')) });
    console.log('ok', f);
  }
  await browser.close();
})();
