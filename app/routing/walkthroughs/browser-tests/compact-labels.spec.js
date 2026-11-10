const { test, expect } = require('@playwright/test');

test('explanations off shows concise analysis and family names without duplicate subtitles', async ({ page }, info) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'I know my analysis', exact: false }).click();
  await page.locator('#known_search').fill('Welch');
  const choice = page.locator('.known-choice[data-ep="E2"]');
  await expect(choice.locator('.name-plain')).toBeVisible();
  await page.locator('#explanations_on').uncheck();
  await expect(choice.locator('.name-tech')).toBeVisible();
  await expect(choice.locator('.name-tech')).toHaveText('Independent-samples t-test');
  await expect(choice.locator('.choice-help')).toBeHidden();
  await expect(page.locator('[data-family="means"] .known-family-label .name-tech')).toHaveText('t-tests');
  await expect(page.locator('[data-family="means"] .known-family-label .name-plain')).toBeHidden();
  await expect(page.locator('.badge-proto').first()).toBeVisible();
  await page.screenshot({ path: info.outputPath('compact-analysis-list.png'), fullPage: true });
  await choice.click();
  await expect(page.locator('.card-title .name-tech')).toHaveText('Independent-samples t-test');
  await expect(page.getByRole('heading', { name: 'Independent-samples t-test', exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  await expect(page.locator('#screen h2 .name-tech')).toHaveText('Independent-samples t-test');
  await expect(page.locator('#f_method')).toHaveValue('welch_t');
  await expect(page.locator('#f_method option[value="welch_t"]')).toHaveText("Welch's t-test");
  await expect(page.locator('#f_method option[value="student_t"]')).toHaveText("Student's t-test");
  const before = await page.locator('#f_method').inputValue();
  await page.locator('#explanations_on').check();
  await expect(page.locator('#screen h2 .name-plain')).toBeVisible();
  await expect(page.locator('#f_method')).toHaveValue(before);
  await page.locator('#explanations_on').uncheck();
  await page.reload();
  await expect(page.locator('#explanations_on')).not.toBeChecked();
  await expect(page.locator('.card-title .name-tech')).toBeVisible();
});

test('compact labels fit a narrow screen and keep a legacy recent entry concise', async ({ page }, info) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await page.evaluate(() => {
    localStorage.setItem('powerkit-terms-mode', '1');
    localStorage.setItem('powerkit-recent', JSON.stringify([{ id: 'E2', name: 'Compare two separate groups on an average' }]));
  });
  await page.reload();
  await expect(page.locator('.start-recent-chip .name-tech')).toHaveText('Independent-samples t-test');
  await page.getByRole('button', { name: 'I know my analysis', exact: false }).click();
  await page.locator('#known_search').fill('RI-CLPM');
  await expect(page.locator('.known-choice[data-ep="E74"] .name-tech')).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1)).toBe(true);
  await page.screenshot({ path: info.outputPath('compact-mobile.png'), fullPage: true });
});

test('compact mode keeps the crossover scope warning visible', async ({ page }) => {
  await page.goto('/?card=E3');
  await page.locator('#explanations_on').uncheck();
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  await expect(page.locator('.analysis-scope-note')).toBeVisible();
  await expect(page.locator('.analysis-scope-note')).toContainText('does not plan an adjusted crossover analysis');
  await expect(page.getByRole('heading', { name: 'Paired-samples t-test', exact: true })).toBeVisible();
});
