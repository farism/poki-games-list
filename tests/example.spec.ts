import { test, expect } from '@playwright/test';

test('categories', async ({ page }) => {
  await page.goto('https://poki.com/en/categories');

  const categories = await page.locator('.I_N3HLb877sRrr2UZJfZ').all()

  for(const c of categories) {
    const href = await c.getAttribute("href")

    await page.goto('https://poki.com' + href);
  }

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/ALL CATEGORIES/);
});