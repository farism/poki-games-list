import { webkit } from "playwright"; // Or 'chromium' or 'firefox'.

const categories = [];
const defoldGames = [];

(async () => {
  const browser = await webkit.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto("https://poki.com/en/categories", { timeout: 5000 });

  await page.waitForLoadState("networkidle");

  await page.locator(".css-47sehv").click({ timeout: 5000 });

  const categoriesEls = await page.locator(".I_N3HLb877sRrr2UZJfZ").all();

  for (const c of categoriesEls) {
    const href = await c.getAttribute("href");
    categories.push(href);
  }

  for (const c of categories) {
    await page.goto("https://poki.com" + c, { timeout: 3000 });

    console.log("category: ", c, "\n");

    const gamesEls = await page.locator(".I_N3HLb877sRrr2UZJfZ").all();
    const games = [];

    for (const g of gamesEls) {
      const href = await g.getAttribute("href");
      games.push(href);
    }

    for (const g of games) {
      if (g.startsWith("/en/g/")) {

        await page.goto("https://poki.com" + g);

        const script = page
          .frameLocator("#game-element")
          .frameLocator("#gameframe")
          .locator("script#engine-loader");

        try {
          const src = await script.getAttribute("src", { timeout: 5000 });

          if (src == "dmloader.js") {
            defoldGames.push(g);
            console.log(g + " IS A DEFOLD GAME!");
          }
        } catch (e) {
          console.log(g + " is not a defold game");
        }
      }
    }

    console.log("\n");
  }

  console.log(defoldGames);

  await browser.close();
})();
