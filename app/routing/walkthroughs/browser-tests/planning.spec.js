const { test, expect } = require('@playwright/test');
const fs = require('node:fs/promises');

async function openAnalysis(page, id, search) {
  await page.getByRole('button', { name: 'I know my analysis', exact: false }).click();
  await page.locator('#known_search').fill(search);
  await page.locator(`button[data-ep="${id}"]:visible`).first().click();
  await page.getByRole('button', { name: 'Enter your values', exact: false }).click();
  await expect(page.locator('#f_goal')).toBeVisible();
}
async function setValue(page, id, value) {
  const el = page.locator('#f_' + id);
  // Optional fields sit in folded sections: open the one holding this field.
  await el.evaluate(x => { const d = x.closest('details'); if (d) d.open = true; });
  if (await el.evaluate(x => x.tagName === 'SELECT')) await el.selectOption(value);
  else await el.fill(value);
  await el.blur();
}
async function tPlan(page) {
  await openAnalysis(page, 'E2', 'two separate groups');
  await setValue(page, 'goal', 'power');
  await setValue(page, 'method', 'student_t');
  await setValue(page, 'alternative', 'two_sided');
  await setValue(page, 'd', '0.4');
  await setValue(page, 'n', '120');
  // The significance level starts empty; one click gives the usual level.
  const usual = page.locator('#f_alpha_usual');
  await usual.evaluate(x => { const d = x.closest('details'); if (d) d.open = true; });
  await expect(page.locator('#f_alpha')).toHaveValue('');
  await usual.click();
  await expect(page.locator('#f_alpha')).toHaveValue('0.05');
  await setValue(page, 'just_type', 'smallest_effect_of_interest');
  await setValue(page, 'just_source', 'A justified planning scenario for browser regression checks.');
  await setValue(page, 'research_question', 'Does training improve recall?');
}
async function calculate(page) {
  await page.locator('#form_check').click();
  await expect(page.locator('#form_result .result-panel')).toBeVisible();
  await expect(page.locator('#form_result')).not.toContainText("didn't finish");
}
async function download(page, id, output) {
  await expect(page.locator('#' + id)).toHaveAttribute('href', /\/download\//);
  // Word and Markdown sit in the format menu beside the PDF button.
  const menu = page.locator('.doc-menu').filter({ has: page.locator('#' + id) }).locator('.dropdown-toggle');
  if (await menu.count() && !(await page.locator('#' + id).isVisible())) await menu.click();
  const pending = page.waitForEvent('download');
  await page.locator('#' + id).click();
  const file = await pending;
  await file.saveAs(output);
  expect(await file.failure()).toBeNull();
  return output;
}
test.beforeEach(async ({ page }) => {
  // Shiny keeps a socket open. Document readiness plus visible controls is
  // the relevant condition; waiting for network idle would be incorrect.
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await expect(page.locator('#screen')).toContainText('How do you want to start?');
});

test('calculate, edit, save and reopen an actual project', async ({ page }, info) => {
  await tPlan(page);
  await calculate(page);
  await expect(page.locator('#form_result')).toContainText('120');
  await expect(page.locator('#explore_plot img')).toBeVisible();
  const project = info.outputPath('plan.powerkit.json');
  await download(page, 'download_project', project);
  const document = info.outputPath('study-planning.md');
  await download(page, 'download_planning_document', document);
  expect(await fs.readFile(document, 'utf8')).toContain('Does training improve recall?');
  // The Word version is a real .docx (a zip holding word/document.xml).
  const docx = info.outputPath('study-planning.docx');
  await download(page, 'download_planning_docx', docx);
  const bytes = await fs.readFile(docx);
  expect(bytes.subarray(0, 2).toString()).toBe('PK');
  expect(bytes.includes(Buffer.from('word/document.xml'))).toBe(true);
  // The PDF button prints a typeset document from a hidden frame: the plan,
  // without powerkit's screens.
  await page.locator('#planning_document_button').click();
  const frame = page.frameLocator('#pk-print-frame');
  await expect(frame.locator('h1')).toHaveText('Study planning decision document');
  await expect(frame.locator('body')).toContainText('Does training improve recall?');
  await expect(frame.locator('.topbar, .nav-tabs, #form_result')).toHaveCount(0);
  await expect(page.locator('#planning_document_button')).toBeEnabled();
  await setValue(page, 'd', '0.6');
  await expect(page.locator('#form_result')).toContainText('These answers need recalculating');
  await expect(page.locator('#download_project')).toHaveAttribute('aria-disabled', 'true');
  await expect(page.locator('#download_planning_document')).toHaveAttribute('aria-disabled', 'true');
  await expect(page.locator('#planning_document_button')).toBeDisabled();
  await expect(page.locator('#download_planning_docx')).toHaveAttribute('aria-disabled', 'true');
  await page.getByRole('button', { name: 'Start again', exact: true }).first().click();
  await page.locator('#open_project').setInputFiles(project);
  await expect(page.locator('#f_d')).toHaveValue('0.4');
  await expect(page.locator('#form_result .result-panel')).toBeVisible();
  await expect(page.locator('#form_result')).not.toContainText('These answers need recalculating');
});

test('an unfinished draft preserves blanks and named alternatives', async ({ page }, info) => {
  await tPlan(page);
  await page.getByText('Assumptions, sources and named alternatives (optional)', { exact: true }).click();
  await page.locator('#scenario_field').selectOption('d');
  await page.locator('#scenario_status').selectOption('assumed');
  await page.locator('#scenario_source').fill('Conservative theory-based assumption.');
  await page.getByRole('button', { name: 'Record input status/source', exact: true }).click();
  await page.locator('#scenario_name').fill('Equal groups');
  await page.getByRole('button', { name: 'Save these answers as a named alternative', exact: true }).click();
  await expect(page.locator('#scenario_message')).toContainText('Alternative saved');
  await page.locator('#scenario_status').selectOption('unknown');
  await page.getByRole('button', { name: 'Record input status/source', exact: true }).click();
  await expect(page.locator('#f_d')).toHaveValue('');
  const draft = info.outputPath('unfinished.powerkit.json');
  await download(page, 'download_draft', draft);
  await page.getByRole('button', { name: 'Start again', exact: true }).first().click();
  await page.locator('#open_project').setInputFiles(draft);
  await expect(page.locator('#f_d')).toHaveValue('');
  await expect(page.locator('#form_result')).toContainText('Unfinished draft opened');
  await page.getByText('Assumptions, sources and named alternatives (optional)', { exact: true }).click();
  await page.getByRole('button', { name: 'Show saved alternatives and sources', exact: true }).click();
  await expect(page.locator('#scenario_list')).toContainText('Equal groups');
  await page.getByRole('button', { name: 'Load answers', exact: true }).click();
  await expect(page.locator('#f_d')).toHaveValue('0.4');
  await expect(page.locator('#scenario_message')).toContainText('Recalculate');
});

test('precision produces width rather than a power result', async ({ page }, info) => {
  await openAnalysis(page, 'E46', 'precision');
  await setValue(page, 'estimate', 'proportion');
  await setValue(page, 'goal', 'precision_width');
  await setValue(page, 'p', '0.3');
  await setValue(page, 'n', '120');
  await setValue(page, 'just_type', 'prior_study');
  await setValue(page, 'just_adjustment', 'Kept the reference prevalence as an explicit planning assumption.');
  await setValue(page, 'just_source', 'Comparable prevalence of 30%.');
  await calculate(page);
  await expect(page.locator('#form_result')).toContainText('width');
  const project = info.outputPath('precision.powerkit.json');
  await download(page, 'download_project', project);
  const saved = JSON.parse(await fs.readFile(project, 'utf8'));
  expect(saved.result.precision).toBeTruthy();
  const document = info.outputPath('precision-planning.md');
  await download(page, 'download_planning_document', document);
  expect(await fs.readFile(document, 'utf8')).toContain('Precision planning, not a significance decision');
});

test('a real background simulation can be cancelled', async ({ page }) => {
  await tPlan(page);
  await setValue(page, 'method', 'welch_t');
  // Welch's test is worked out by formula unless simulation is chosen.
  await setValue(page, 'welch_method', 'simulation');
  await setValue(page, 'simulation_accuracy', 'precise');
  await setValue(page, 'n', '1000');
  await page.locator('#form_check').click();
  await expect(page.locator('#calc_cancel')).toBeVisible();
  await page.locator('#calc_cancel').click();
  await expect(page.locator('#form_result')).toContainText('Calculation cancelled');
  await expect(page.locator('#calc_cancel')).toHaveCount(0);
});

test('Labs tool history returns to the tool/menu, then forwards again', async ({ page }) => {
  await page.getByRole('tab', { name: 'Labs (experimental)', exact: true }).click();
  await page.locator('button[data-labs-tool="variation"]').click();
  await expect(page.locator('.labs-back:visible')).toBeVisible();
  await page.goBack({ waitUntil: 'domcontentloaded' });
  await expect(page.locator('button[data-labs-tool="variation"]')).toBeVisible();
  await expect(page.getByRole('tab', { name: 'Labs (experimental)', exact: true })).toHaveAttribute('aria-selected', 'true');
  await page.goForward({ waitUntil: 'domcontentloaded' });
  await expect(page.locator('.labs-back:visible')).toBeVisible();
  await page.locator('.labs-back:visible').click();
  await expect(page.locator('button[data-labs-tool="variation"]')).toBeVisible();
});


test('reported-statistic import fills supported fields and refuses unsupported summaries without edits', async ({ page }) => {
  await tPlan(page);
  await page.getByText('I have published results, raw scores, or missing information', {exact:true}).click();
  const entry = page.locator('#reported_statistic');
  const use = page.getByRole('button', {name:'Use this reported statistic', exact:true});
  await entry.fill('t(58) = -2.5'); await use.click();
  await expect(page.locator('#f_conv_from')).toHaveValue('t');
  await expect(page.locator('#f_conv_df')).toHaveValue('58');
  await expect(page.locator('#f_conv_value')).toHaveValue('-2.5');
  await entry.fill('t(31.8) = 2.5'); await use.click();
  await expect(page.locator('#reported_statistic_message')).toContainText('must not be rounded');
  await expect(page.locator('#f_conv_value')).toHaveValue('-2.5');
  await entry.fill('F(2, 58) = 6.25'); await use.click();
  await expect(page.locator('#reported_statistic_message')).toContainText('only one numerator');
  await expect(page.locator('#f_conv_from')).toHaveValue('t');
  await entry.fill('F(1, 58) = 6.25'); await use.click();
  await expect(page.locator('#f_conv_from')).toHaveValue('F');
  await expect(page.locator('#f_conv_value')).toHaveValue('6.25');
  await expect(page.locator('#reported_statistic_message')).toContainText('does not supply an effect direction');
});

for (const page_ of ['labs', 'about', 'updates']) test(`a link straight to ${page_} is not covered by the starting screen`, async ({ page }) => {
  await page.goto(`/?page=${page_}`);
  await expect(page.locator('#pk-starting')).toHaveCount(0, { timeout: 30000 });
});

test('a link to a card opens that card, and the address names the open card', async ({ page }) => {
  await page.goto('?card=E8');
  await expect(page.locator('#pk-starting')).toHaveCount(0, { timeout: 30000 });
  await expect(page.locator('#screen [data-recent-id="E8"]')).toHaveCount(1);
  await expect(page).toHaveURL(/card=E8/);
});

test('a link straight to a Labs tool opens it, not the starting screen', async ({ page }) => {
  await page.goto('?page=labs&tool=prereplication');
  await expect(page.locator('#pk-starting')).toHaveCount(0);
  await page.locator('#labs_study').fill('Smith (2019)');
  await expect(page.locator('#labs_study')).toHaveValue('Smith (2019)');
});

test('named study plans: add, rename, keep after a reload, save, reopen and update', async ({ page }, info) => {
  await tPlan(page);
  await calculate(page);
  await page.locator('#plan_add').click();
  await expect(page.locator('#study_plan_bar')).toContainText('Added to “Study plan,');
  await expect(page.locator('#study_plan_bar')).toContainText('only in this browser until you save it');
  await expect(page.locator('.study-plan-chip')).toContainText('Study plans (1)');
  await expect(page.locator('.study-plan-chip .plan-unsaved-dot')).toHaveCount(1);

  // The Study plans page, from the top bar; then the plan's own page.
  await page.locator('.study-plan-chip').click();
  await expect(page.locator('#plans_page h2')).toHaveText('Study plans');
  await page.locator('.plans-row-name').first().click();
  await page.locator('.plan-rename summary').click();
  await page.locator('#plan_name').fill('Thesis study 2');
  await page.locator('#plan_name_save').click();
  await expect(page.locator('#plans_page h2.plan-title')).toHaveText('Thesis study 2');
  await expect(page.locator('#plans_page')).toContainText('Only in this browser');

  // Kept in the browser across a reload.
  await page.reload({ waitUntil: 'domcontentloaded' });
  await expect(page.locator('.study-plan-chip')).toContainText('Study plans (1)');
  await page.locator('.study-plan-chip').click();
  await expect(page.locator('.plans-row-name')).toHaveText('Thesis study 2');
  await page.locator('.plans-row-name').click();

  // Saving to a file.
  const file = info.outputPath('thesis.powerkit.json');
  await expect(page.locator('#download_study_plan')).toHaveAttribute('href', /\/download\//);
  const pending = page.waitForEvent('download');
  await page.locator('#download_study_plan').click();
  const saved = await pending;
  expect(saved.suggestedFilename()).toBe('powerkit-thesis-study-2.powerkit.json');
  await saved.saveAs(file);
  await expect(page.locator('#plans_page')).toContainText('Saved to a file');
  const text = await fs.readFile(file, 'utf8');
  expect(JSON.parse(text).name).toBe('Thesis study 2');

  // Opening the analysis again, changing it and updating it in the plan.
  await page.locator('.plan-item-controls button', { hasText: 'Open' }).click();
  await expect(page.locator('#form_result .result-panel')).toBeVisible();
  await expect(page.locator('#study_plan_bar')).toContainText('From your plan “Thesis study 2”');
  await setValue(page, 'd', '0.5');
  await calculate(page);
  await expect(page.locator('#study_plan_bar')).toContainText('changed it');
  await page.locator('#plan_entry_update').click();
  await expect(page.locator('#study_plan_bar')).toContainText('Updated in “Thesis study 2”');
  await page.locator('.study-plan-chip').click();
  await page.locator('.plans-row-name').click();
  await expect(page.locator('.plan-item')).toHaveCount(1);
  await expect(page.locator('#plans_page')).toContainText('Only in this browser');

  // The saved file opened again: a different version, so both are kept.
  await page.locator('#plans_back').click();
  await page.locator('#plans_open_file').setInputFiles(file);
  await expect(page.locator('.shiny-notification', { hasText: 'both are kept' })).toBeVisible();
  await expect(page.locator('#plans_page h2.plan-title')).toContainText('Thesis study 2 (opened');
  await page.locator('#plans_back').click();
  await expect(page.locator('.plans-row-name')).toHaveCount(2);
});

async function planWithOneAnalysis(page) {
  await tPlan(page);
  await calculate(page);
  await page.locator('#plan_add').click();
  await expect(page.locator('#study_plan_bar')).toContainText('Added to');
  await page.locator('.study-plan-chip').click();
  await page.locator('.plans-row-name').first().click();
  await expect(page.locator('#plans_page h2.plan-title')).toBeVisible();
}
const planKeys = page => page.evaluate(() => Object.keys(localStorage).filter(k => k.startsWith('powerkit-study-plan') && k !== 'powerkit-study-plans'));
const storedKeys = page => page.evaluate(() => Object.keys(localStorage).filter(k => k.startsWith('powerkit-study-plan')));

test('a plan that no longer fits in the browser keeps its last copy and says so', async ({ page }) => {
  await planWithOneAnalysis(page);
  await expect.poll(async () => (await planKeys(page)).length).toBe(1);
  const [key] = await planKeys(page);
  const before = await page.evaluate(k => localStorage.getItem(k), key);
  // Another plan's copy fills the shared budget, so the next write can't fit.
  await page.evaluate(() => localStorage.setItem('powerkit-study-plan:00000000000000ff', 'x'.repeat(2999000)));
  await page.locator('.plan-rename summary').click();
  await page.locator('#plan_name').fill('Renamed while full');
  await page.locator('#plan_name_save').click();
  await expect(page.locator('#plans_page')).toContainText('too large to keep in this browser');
  expect(await page.evaluate(k => localStorage.getItem(k), key)).toBe(before);
  await page.evaluate(() => localStorage.removeItem('powerkit-study-plan:00000000000000ff'));
});

test('copying a link to a plan shows the link and only then counts the plan as kept', async ({ page, context }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await planWithOneAnalysis(page);
  await expect(page.locator('#plan_status')).toContainText('Only in this browser');
  await page.locator('#share_study_plan').click();
  await expect(page.locator('#share_study_plan_box')).toHaveValue(/#shared=1\./);
  await expect(page.locator('#plan_status')).toContainText('Copied as a link');
  await expect(page.locator('#share_study_plan_box')).toBeVisible();
});

test('a file that is not a plan, opened on the plans page, says so there', async ({ page }, info) => {
  await page.locator('.study-plan-chip').click();
  const bad = info.outputPath('not-a-plan.powerkit.json');
  await fs.writeFile(bad, '{"format": "something else"}');
  await page.locator('#plans_open_file').setInputFiles(bad);
  await expect(page.locator('#plans_open_message .alert')).toBeVisible();
  await expect(page.getByRole('tab', { name: 'Plan a power analysis' })).not.toHaveAttribute('aria-selected', 'true');
});

test('removing every plan clears this browser, the old single plan too', async ({ page }) => {
  await planWithOneAnalysis(page);
  await page.evaluate(() => localStorage.setItem('powerkit-study-plan', 'an old plan this version could not read'));
  await page.locator('#plans_back').click();
  page.once('dialog', d => d.accept());
  await page.locator('#plans_forget_link').click();
  await expect(page.locator('#plans_page')).toContainText('You have no study plans yet.');
  await expect.poll(() => storedKeys(page)).toEqual([]);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await expect(page.locator('.study-plan-chip')).toHaveText('Study plans');
});

test('a plan has an overview, downloads everything as a zip, and the zip opens as the plan in another browser', async ({ page, browser }, info) => {
  await planWithOneAnalysis(page);
  await expect(page.locator('.plan-overview')).toContainText('1 analysis: 1 primary');
  await expect(page.locator('#download_plan_bundle')).toHaveAttribute('href', /\/download\//);
  const pending = page.waitForEvent('download');
  await page.locator('#download_plan_bundle').click();
  const saved = await pending;
  expect(saved.suggestedFilename()).toMatch(/^powerkit-study-plan-.*-everything\.zip$/);
  const file = info.outputPath('plan.zip');
  await saved.saveAs(file);
  await expect(page.locator('#plans_page')).toContainText('Saved to a file');
  // Another browser, with nothing stored: the zip opens as the plan.
  const other = await browser.newPage();
  await other.goto('/?page=plans', { waitUntil: 'domcontentloaded' });
  await expect(other.locator('#plans_page')).toContainText('You have no study plans yet.');
  await other.locator('#plans_open_file').setInputFiles(file);
  await expect(other.locator('#plans_page h2.plan-title')).toContainText('Study plan,');
  await expect(other.locator('.plan-item')).toHaveCount(1);
  await other.close();
});
