const { test, expect } = require('@playwright/test');

test('common goals stay visible and related choices keep their saved values', async ({ page }) => {
  await page.goto('/?card=E1', { waitUntil: 'domcontentloaded' });
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  const goals = page.locator('#f_goal_buttons');
  const main = goals.getByRole('radiogroup', { name: 'What do you want to find out?' });
  await expect(main.getByRole('radio')).toHaveCount(3);
  await expect(goals.getByRole('button', { name: /Balanced significance level/ })).toBeHidden();

  await main.getByRole('radio', { name: /Smallest detectable effect/ }).click();
  const sizes = goals.getByRole('radiogroup', { name: 'Which sample sizes?' });
  await expect(sizes.getByRole('radio', { name: 'One sample size' })).toHaveAttribute('aria-checked', 'true');
  await sizes.getByRole('radio', { name: 'Compare several sample sizes' }).click();
  await expect(page.locator('#f_goal')).toHaveValue('sensitivity_curve');
  await expect(main.getByRole('radio', { name: /Smallest detectable effect/ })).toHaveAttribute('aria-checked', 'true');

  await goals.getByText('Advanced goals', { exact: true }).click();
  await goals.getByRole('button', { name: /Balanced significance level/ }).click();
  await expect(page.locator('#f_goal')).toHaveValue('justified_alpha');
  await expect(goals.getByRole('button', { name: /Balanced significance level/ })).toHaveAttribute('aria-pressed', 'true');
});
