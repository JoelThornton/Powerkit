const { test, expect } = require('@playwright/test');
const axePath = require.resolve('axe-core/axe.min.js');

async function open(page) {
  await page.goto('/?card=E2');
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  await page.locator('#f_goal').selectOption('sample_size');
}
async function put(page, id, value) {
  const el = page.locator('#f_' + id);
  await el.evaluate(x => { for (let p = x.parentElement; p; p = p.parentElement) if (p.tagName === 'DETAILS') p.open = true; });
  if (await el.evaluate(x => x.tagName === 'SELECT')) await el.selectOption(value);
  else await el.fill(value);
  await el.blur();
}

for (const width of [1100, 375, 320]) test(`compact guidance is optional, accessible and preserves answers at ${width}px`, async ({ page }, info) => {
  await page.setViewportSize({ width, height: 900 });
  await open(page);
  await expect(page.locator('#f_power_help')).toBeVisible();
  await expect(page.locator('#f_power_help')).toContainText('a habit, not a rule');
  await expect(page.locator('#f_power')).toHaveValue('');
  await expect(page.locator('[data-target="f_power"]')).toHaveText(['80%', '90%', '95%']);
  await page.locator('[data-target="f_power"][data-value="0.9"]').click();
  await page.locator('#f_d').fill('0.4');
  const explainedHeight = await page.evaluate(() => document.documentElement.scrollHeight);
  await page.locator('#explanations_on').uncheck();
  await expect(page.locator('#screen .field-help:visible')).toHaveCount(0);
  await expect(page.locator('#screen .default-source:visible')).toHaveCount(0);
  await expect(page.locator('#screen .group-note:visible')).toHaveCount(0);
  await expect(page.locator('.planning-decision .explanation-content')).toBeHidden();
  await expect(page.locator('.badge-proto').first()).toBeVisible();
  await expect(page.locator('#f_power')).toHaveValue('0.9');
  await expect(page.locator('#f_d')).toHaveValue('0.4');
  expect(await page.evaluate(() => document.documentElement.scrollHeight)).toBeLessThan(explainedHeight);
  expect(await page.locator('#f_power').getAttribute('aria-describedby') || '').not.toContain('f_power_help');
  const help = page.locator('#f_power_info > summary');
  await help.focus();
  await page.keyboard.press('Enter');
  await expect(page.locator('#f_power_help')).toBeVisible();
  await expect(page.locator('#f_power_info .input-guide')).toHaveAttribute('open', '');
  await expect(page.locator('#f_power')).toHaveAttribute('aria-describedby', /f_power_help/);
  await page.keyboard.press('Enter');
  await expect(page.locator('#f_power_help')).toBeHidden();
  await page.locator('#form_check').click();
  await expect(page.locator('#form_result [role="alert"]')).toBeVisible();
  await expect(page.locator('#f_alpha')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.locator('#f_alpha')).toHaveAttribute('aria-describedby', /f_alpha_problem/);
  await help.click();
  await expect(page.locator('#f_alpha')).toHaveAttribute('aria-describedby', /f_alpha_problem/);
  await page.locator('#explanations_on').check();
  await expect(page.locator('#f_power_help')).toBeVisible();
  await expect(help).toBeHidden();
  await page.locator('#explanations_on').uncheck();
  await expect(page.locator('#f_power_help')).toBeHidden();
  await page.addScriptTag({ path: axePath });
  await page.waitForTimeout(500);
  const audit = await page.evaluate(async () => axe.run(document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'] }
  }));
  expect(audit.violations.map(v => ({ id: v.id, targets: v.nodes.map(n => n.target) }))).toEqual([]);
  expect(await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)).toBeLessThanOrEqual(1);
  await page.screenshot({ path: info.outputPath('compact-input-form.png'), fullPage: true });
});

test('compact results keep the answer, its plain reading and the analysis visible', async ({ page }) => {
  await open(page);
  for (const [id, value] of Object.entries({ power: '0.9', d: '0.4', alpha: '0.05', alternative: 'two_sided',
    just_type: 'smallest_effect_of_interest', just_source: 'Fictional compact-mode check.' })) await put(page, id, value);
  await page.locator('#explanations_on').uncheck();
  await page.locator('#form_check').click();
  await expect(page.locator('.result-panel')).toBeVisible();
  await expect(page.locator('.result-figure-value')).toBeVisible();
  await expect(page.locator('.result-analysis')).toContainText("Welch");
  // The plain reading is part of the answer's sentence (design review
  // D-22), so it stays visible when explanations are off.
  await expect(page.locator('.result-headline .result-reading')).toBeVisible();
});
