const { test, expect } = require('@playwright/test');
const axePath = require.resolve('axe-core/axe.min.js');

// Audit a settled page: Shiny dims outputs while it recalculates and the
// screens fade in, and an audit taken mid-transition reports the dimmed or
// fading text (colour contrast) and overlapping targets of the screen being
// left rather than the one under test. Outputs on hidden tabs stay marked
// as recalculating (Shiny suspends them), as do empty message slots that
// have never been filled, so only visible outputs with content count.
async function settle(page) {
  await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy') &&
    ![...document.querySelectorAll('.recalculating')].some(e => e.offsetParent && e.textContent.trim()) &&
    document.getAnimations().every(a => a.playState !== 'running'), null, { timeout: 30000 });
  await page.waitForTimeout(300);
}

async function audit(page, name, info) {
  await settle(page);
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
  // Inspect semantics exposed to assistive technology, without claiming a
  // human screen-reader session or a WCAG compliance certification.
  expect(await page.locator('#screen').ariaSnapshot()).toContain('alert');
  for (const [id, value] of Object.entries({goal:'power', method:'student_t', alternative:'two_sided',
    d:'0.4', n:'120', just_type:'smallest_effect_of_interest', just_source:'Fictional accessibility test scenario.'})) {
    const el = page.locator('#f_' + id);
    if (await el.evaluate(x => x.tagName === 'SELECT')) await el.selectOption(value);
    else await el.fill(value);
    await el.blur();
  }
  await page.locator('#form_check').click();
  await expect(page.locator('#form_result .result-panel')).toBeVisible();
  await page.getByText('Read the exploration values as a table', {exact:true}).click();
  await expect(page.locator('#explore_table table')).toBeVisible();
  await expect(page.locator('#explore_plot img')).toHaveAttribute('alt', /same values/);
  await audit(page, 'calculated-result-and-data-table', info);
  if (width === 1100) {
    await page.addStyleTag({content:'html {font-size:200% !important;}'});
    await audit(page, 'double-root-text-size', info);
  }

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
