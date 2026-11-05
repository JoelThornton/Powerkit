const { test, expect } = require('@playwright/test');
const axePath = require.resolve('axe-core/axe.min.js');

async function audit(page, name, info) {
  await page.addScriptTag({ path: axePath });
  const result = await page.evaluate(async () => axe.run(document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'] }
  }));
  await info.attach(name, { body: JSON.stringify(result, null, 2), contentType: 'application/json' });
  expect(result.violations.map(v => ({ id: v.id, impact: v.impact, targets: v.nodes.map(n => n.target) }))).toEqual([]);
  expect(await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)).toBeLessThanOrEqual(1);
}

for (const width of [1100, 375, 320]) test(`accessibility and reflow at ${width}px`, async ({ page }, info) => {
  await page.setViewportSize({ width, height: 900 });
  await page.goto('/');
  await expect(page.locator('#screen')).toContainText('How do you want to start?');
  await audit(page, 'start', info);
  await page.getByRole('button', { name: 'I know my analysis', exact: false }).click();
  await page.locator('#known_search').fill('two separate groups');
  await page.locator('button[data-ep="E2"]:visible').first().click();
  await audit(page, 'analysis-card', info);
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  await expect(page.locator('#f_goal')).toBeVisible();
  await audit(page, 'input-form', info);
  await page.locator('#form_check').click();
  await expect(page.locator('#form_result [role="alert"]')).toBeVisible();
  await expect(page.locator('#form_result [role="alert"]')).toBeFocused();
  await audit(page, 'input-errors', info);
  // Inspect the accessibility tree exposed to assistive technology. This
  // is semantic coverage, not a claim about a human screen-reader session.
  expect(await page.locator('#screen').ariaSnapshot()).toContain('heading');
  expect(await page.locator('#screen').ariaSnapshot()).toContain('alert');
});

test('keyboard route focuses the new heading and keeps a visible focus indicator', async ({ page }) => {
  await page.goto('/');
  const route = page.getByRole('button', { name: 'Help me choose', exact: false });
  await expect(route).toBeVisible();
  let reached = false;
  for (let i = 0; i < 40; i++) {
    await page.keyboard.press('Tab');
    if (await route.evaluate(el => el === document.activeElement)) { reached = true; break; }
  }
  expect(reached).toBe(true);
  await page.keyboard.press('Enter');
  await expect(page.locator('#screen h2').first()).toBeFocused();
  await page.keyboard.press('Tab');
  expect(await page.evaluate(() => {
    const el = document.activeElement, s = getComputedStyle(el);
    return (s.outlineStyle !== 'none' && parseFloat(s.outlineWidth) > 0) || s.boxShadow !== 'none';
  })).toBe(true);
});
