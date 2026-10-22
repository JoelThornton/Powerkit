// Accessibility check for the running routing prototype (port 8765, or
// PROTOTYPE_URL): runs
// axe-core (WCAG 2.1 A and AA, plus best practice) on the main screens at
// desktop and phone width (375px), checks for sideways scrolling, and checks
// that keyboard focus moves to the new screen's heading. Needs Node,
// Playwright and axe-core (npm install axe-core@4.10.2). Exits with an error
// if any check fails. Run: node app/routing/walkthroughs/accessibility.js
const { chromium } = require('playwright');
const fs = require('fs');
const AXE = fs.readFileSync(require.resolve('axe-core/axe.min.js'), 'utf8');
const URL = process.env.PROTOTYPE_URL || 'http://127.0.0.1:8765/';
(async () => {
  const b = await chromium.launch({ ...(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {}) });
  const results = {};
  for (const width of [1000, 375]) {
    const p = await b.newPage({ viewport: { width, height: 800 } });
    const settle = () => p.waitForTimeout(500);
    const label = async t => { for (let a = 0; a < 40; a++) { const l = p.locator('#screen button .choice-label'); const n = await l.count(); for (let i = 0; i < n; i++) if ((await l.nth(i).textContent()).trim() === t) { await l.nth(i).click(); await settle(); return; } await p.waitForTimeout(250); } throw new Error(t); };
    const btn = async t => { await p.locator('button', { hasText: t }).first().click(); await settle(); };
    const audit = async (name) => {
      await p.addScriptTag({ content: AXE });
      const r = await p.evaluate(async () => await axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'] } }));
      const overflow = await p.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
      const v = r.violations.map(x => `${x.id} (${x.impact}, ${x.nodes.length}): ${x.nodes.slice(0, 2).map(n => n.target.join(' ')).join(' | ')}`);
      results[`${width} ${name}`] = { overflow, v };
      console.log(`\n[${width}px] ${name}: overflow ${overflow}px`); v.forEach(x => console.log('  ' + x));
    };
    await p.goto(URL); await settle();
    await audit('start');
    await btn('Help me choose'); await audit('screening question S1');
    await label('A score or scale'); await label('Independent people'); await label('Once'); await label('Detect an effect');
    await label('A difference between groups or conditions'); await label('One'); await label('Two, with different people in each');
    await audit('card E2 (runs)');
    // The input screen: empty, after a check with problems, and when valid.
    await btn('Enter your values'); await audit('input screen E2');
    await btn('Check my answers'); await p.waitForSelector('#form_result .form-problems', { timeout: 10000 }); await audit('input screen E2, problems');
    const fill = async (id, v) => { await p.fill('#f_' + id, v); };
    for (const [id, v] of [['X_label', 'Condition'], ['X_level1', 'Control'], ['X_level2', 'Training'], ['Y_label', 'Recall'], ['d', '0.4'], ['power', '0.8'], ['just_source', 'Example']]) await fill(id, v);
    await p.selectOption('#f_goal', 'sample_size'); await p.selectOption('#f_just_type', 'smallest_effect_of_interest');
    await btn('Check my answers'); await p.waitForSelector('#form_result .not-wired, #form_result .form-problems, #form_result .result-panel:not(.calculating)', { timeout: 60000 }); await audit('result screen E2 (required N)');
    await btn('Back to the card');
    await btn('Start again'); await btn('Help me choose'); await label('A score or scale'); await label('Independent people'); await label('Many times');
    await label('Measurements over time, to see whether a trend changes at a known point'); await audit('card E45 (not in powerkit)');
    await p.locator('details.mismatch summary').first().click(); await settle(); await audit('card E45, "Something doesn\'t fit?" open');
    await btn('Back'); await label("None of these fit / I'm not sure"); await audit('card E-unsure');
    await btn('Start again'); await btn('I know my analysis'); await label('A score or scale'); await label('Independent people'); await label('Once'); await label('Detect an effect');
    await audit('end-point list');
    await btn('Start again'); await btn('Plan my whole study'); await label('A score or scale'); await label('Independent people'); await label('Once'); await label('Detect an effect');
    await audit('guided variables');
    await btn('Next: choose the analyses'); await p.check('#tick_compare'); await settle(); await audit('guided analyses');
    await btn('Show my plan'); await audit('guided plan');
    await p.locator('a', { hasText: 'Feedback' }).first().click(); await settle(); await audit('feedback tab');
    // The maintainer's tab is only there in the maintainer's view.
    await p.goto(URL + '?view=maintainer'); await settle();
    await p.locator('a', { hasText: 'For the maintainer' }).click(); await settle(); await audit('maintainer tab');
    await p.close();
  }
  // Keyboard: Tab to the first route button, press Enter, and see where focus lands.
  const k = await b.newPage({ viewport: { width: 1000, height: 800 } });
  await k.goto(URL); await k.waitForTimeout(600);
  let found = false;
  for (let i = 0; i < 25; i++) { await k.keyboard.press('Tab'); const t = await k.evaluate(() => document.activeElement && document.activeElement.textContent.trim().slice(0, 40)); if (t && t.startsWith('Help me choose')) { found = true; break; } }
  console.log('\nkeyboard: reached "Help me choose" by Tab:', found);
  await k.keyboard.press('Enter'); await k.waitForTimeout(700);
  console.log('keyboard: after Enter, heading:', (await k.locator('#screen h2').first().textContent()).trim().slice(0, 60));
  console.log('keyboard: focus is on:', await k.evaluate(() => document.activeElement.tagName + ' ' + (document.activeElement.textContent || '').trim().slice(0, 50)));
  await k.keyboard.press('Tab'); console.log('keyboard: next Tab goes to:', await k.evaluate(() => document.activeElement.tagName + ' ' + (document.activeElement.textContent || '').trim().slice(0, 50)));
  const failed = Object.values(results).some(r => r.v.length > 0 || r.overflow > 0); if (failed) process.exitCode = 1;
  await b.close();
})().catch(e => { console.error(e); process.exit(1); });
