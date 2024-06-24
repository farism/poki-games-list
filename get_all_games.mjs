import { webkit } from "playwright"; // Or 'chromium' or 'firefox'.
import fs from "node:fs";

(async () => {
  const browser = await webkit.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  const categories = [];
  const games = [];

  await page.goto("https://poki.com/en/categories", { timeout: 5000 });

  await page.waitForLoadState("networkidle");

  await page.locator(".css-47sehv").click({ timeout: 5000 });

  const categoriesEls = await page.locator(".I_N3HLb877sRrr2UZJfZ").all();

  for (const c of categoriesEls) {
    const href = await c.getAttribute("href");
    categories.push(href);
  }

  categories.sort();

  for (const c of categories) {
    try {
      await page.goto("https://poki.com" + c);

      const gamesEls = await page.locator(".I_N3HLb877sRrr2UZJfZ").all();

      for (const g of gamesEls) {
        const href = await g.getAttribute("href");

        if (href.startsWith("/en/g/")) {
          games.push(href);
        }
      }
    } catch (e) {}
  }

  games.sort();

  const gamesUnique = [];

  games.forEach((g) => {
    if (!gamesUnique.includes(g)) {
      gamesUnique.push(g);
    }
  });

  console.log(gamesUnique);

  fs.writeFileSync("games.json", JSON.stringify(gamesUnique));

  await browser.close();
})();
