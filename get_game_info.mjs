import { webkit } from "playwright"; // Or 'chromium' or 'firefox'.
import fs from "node:fs";
import allGames from "./games.json" with { type: "json" };
import gameinfos from "./gameinfos.json" with { type: "json" };

const existingUrls = gameinfos.map((g) => g.url);

function isDefold(page) {
  return new Promise(async (resolve, reject) => {
    try {
      const script = page
        .frameLocator("#game-element")
        .frameLocator("#gameframe")
        .locator("script#engine-loader");

      const src = await script.getAttribute("src", { timeout: 10000 });

      resolve(src.includes("dmloader"));
    } catch (e) {
      resolve(false);
    }
  });
}

function checkGamePage(context, url) {
  return new Promise(async (resolve, reject) => {
    const page = await context.newPage();

    try {
      console.log("loading page - https://poki.com" + url);

      await page.goto("https://poki.com" + url);

      const defold = await isDefold(page);

      const name = await page.locator(".L7rv0e7LkdrpUjPZq3gH").textContent();

      const author = (
        await page.locator(".pyOBngxafEnwWKrr93IQ").textContent()
      ).replace("by ", "");

      const upvote = await page
        .locator("#vote-up .L6WSODmebiIqJJOEi46E.Vlw13G6cUIC6W9LiGC_X")
        .textContent();

      const downvote = await page
        .locator("#vote-down .L6WSODmebiIqJJOEi46E.Vlw13G6cUIC6W9LiGC_X")
        .textContent();

      const tagEls = await page.locator(".LgL008mUK57BTn8KGGP4").all();
      const tags = [];
      for (const t of tagEls) {
        const tag = await t.textContent();
        tags.push(tag);
      }

      resolve({ url, name, author, tags, upvote, downvote, defold });
    } catch (e) {
      console.log(e);
    } finally {
      await page.close();
    }

    resolve(null);
  });
}

(async () => {
  const browser = await webkit.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  const chunkSize = 10;
  const chunks = [];
  const remainingGames = allGames
    // .slice(0, 30)
    .filter((g) => !existingUrls.includes(g));

  await page.goto("https://poki.com/");

  await page.waitForLoadState("networkidle");

  await page.locator(".css-47sehv").click();

  for (let i = 0; i < remainingGames.length; i += chunkSize) {
    const chunk = remainingGames.slice(i, i + chunkSize);
    chunks.push(chunk);
  }

  for (const chunk of chunks) {
    const result = await Promise.all(
      chunk.map((g) => checkGamePage(context, g))
    );

    result.filter((x) => x).forEach((g) => gameinfos.push(g));

    fs.writeFileSync("gameinfos.json", JSON.stringify(gameinfos, null, 2));

    fs.writeFileSync(
      "gameinfos_defold.json",
      JSON.stringify(
        gameinfos.filter((gi) => gi.defold),
        null,
        2
      )
    );
  }

  await browser.close();
})();
