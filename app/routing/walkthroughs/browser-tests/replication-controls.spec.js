const { test, expect } = require('@playwright/test');

test('replication criteria display their own settings and threshold labels fit', async ({ page }) => {
  await page.goto('?page=plans');
  await expect(page.locator('#pk-starting')).toHaveCount(0, { timeout: 30000 });
  await page.locator('#plans_new_replication').click();
  await page.locator('input[name=rep_section][value=goals]').click();
  await expect(page.locator('#rep_alpha')).toBeVisible();
  await expect(page.locator('#rep_threshold')).toBeHidden();

  await page.locator('#rep_goal').selectOption('bf_repeat');
  await expect(page.locator('#rep_alpha')).toBeHidden();
  const thresholds = page.locator('#rep_threshold');
  await expect(thresholds).toBeVisible();
  await expect(thresholds.getByRole('radio')).toHaveCount(4);
  await thresholds.getByRole('radio', { name: '6', exact: true }).check();
  await expect(thresholds.getByRole('radio', { name: '6', exact: true })).toBeChecked();

  for (const [width, columns] of [[1280, 4], [375, 2]]) {
    await page.setViewportSize({ width, height: 900 });
    await expect.poll(() => thresholds.locator('.shiny-options-group').evaluate(group => ({
      columns: getComputedStyle(group).gridTemplateColumns.split(' ').length,
      clear: [...group.querySelectorAll('label')].every(label => {
        const radio = label.querySelector('input').getBoundingClientRect();
        const text = label.querySelector('span').getBoundingClientRect();
        return radio.right < text.left && text.right <= label.getBoundingClientRect().right;
      }),
    }))).toEqual({ columns, clear: true });
  }

  await page.locator('#explanations_on').uncheck();
  const variation = page.locator('.replication-workspace fieldset').filter({ has: page.locator('#rep_tau') });
  await expect(variation.locator('summary:visible')).toHaveCount(1);
  await expect(variation.locator('summary:visible')).toHaveText('How to interpret the between-study SD');
});
