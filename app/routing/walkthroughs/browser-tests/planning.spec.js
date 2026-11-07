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

test('a link straight to a Labs tool opens it, not the starting screen', async ({ page }) => {
  await page.goto('?page=labs&tool=prereplication');
  await expect(page.locator('#pk-starting')).toHaveCount(0);
  await page.locator('#labs_study').fill('Smith (2019)');
  await expect(page.locator('#labs_study')).toHaveValue('Smith (2019)');
});
