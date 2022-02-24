const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: false
  });
  const context = await browser.newContext();

  // Open new page
  const page = await context.newPage();

  // Go to https://testingbot.com/
  await page.goto('https://testingbot.com/');

  // Click :nth-match(div:has-text("Trusted by some of the world's most innovative companies"), 2)
  await page.click(':nth-match(div:has-text("Trusted by some of the world\'s most innovative companies"), 2)');

  // Click text=Remote app testing on any device
  await page.click('text=Remote app testing on any device');
  // assert.equal(page.url(), 'https://testingbot.com/features/manual-mobile-testing');

  // Click text=Pricing
  await page.click('text=Pricing');
  // assert.equal(page.url(), 'https://testingbot.com/pricing');

  // Close page
  await page.close();

  // ---------------------
  await context.close();
  await browser.close();
})();