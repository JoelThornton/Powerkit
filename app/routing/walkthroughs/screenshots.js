// Drives the running routing prototype through every walkthrough scenario
// in scenarios.json, in all three routes, checks the end point each route
// reaches against `reaches`, and saves one screenshot per end card to
// docs/figures/walkthroughs/. Routing only: nothing is calculated.
//
// Start the prototype on port 8765 first, then run with Node and
// Playwright, e.g.:  node app/routing/walkthroughs/screenshots.js
// (set PW_CHROMIUM to a Chromium executable if Playwright can't find one).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..', '..', '..');
const scenarios = JSON.parse(fs.readFileSync(path.join(__dirname, 'scenarios.json'), 'utf8'));
const OUT = path.join(root, 'docs', 'figures', 'walkthroughs');
const URL = process.env.PROTOTYPE_URL || 'http://127.0.0.1:8765/';
const SAFETY = "None of these fit / I'm not sure";

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const launch = process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {};
  const browser = await chromium.launch(launch);
  const page = await browser.newPage({ viewport: { width: 1000, height: 900 } });
  const settle = () => page.waitForTimeout(350);
  const label = async (text) => {
    const target = page.locator('#screen button .choice-label').filter({ hasText: text });
    const n = await target.count();
    let clicked = false;
    for (let i = 0; i < n; i++) {
      if ((await target.nth(i).textContent()).trim() === text) { await target.nth(i).click(); clicked = true; break; }
    }
    if (!clicked) throw new Error(`No button labelled "${text}"`);
    await settle();
  };
  const button = async (text) => { await page.locator('#screen button', { hasText: text }).first().click(); await settle(); };
  const home = async () => { await page.goto(URL); await page.waitForSelector('.prototype-banner'); await settle(); };
  const cardId = async () => (await page.locator('#screen .endpoint-card .card-eid').first().textContent()).trim();
  const answer = async (labels) => { for (const l of labels) await label(l); };
  const onCard = async () => (await page.locator('#screen .endpoint-card').count()) > 0;
  const results = [];

  for (const s of scenarios) {
    const got = {};
    // Help me choose
    await home(); await button('Help me choose'); await answer(s.choose); got.choose = await cardId();
    // I know my analysis
    await home(); await button('I know my analysis'); await answer(s.known.answers);
    if (!(await onCard())) await label(s.known.pick === 'safety' ? SAFETY : s.known.pick);
    got.known = await cardId();
    // Plan my whole study
    await home(); await button('Plan my whole study'); await answer(s.guided.answers);
    if (await onCard()) {
      got.guided = await cardId();
    } else if (s.guided.continue) {
      await button("Continue in 'Help me choose'"); await answer(s.guided.continue); got.guided = await cardId();
    } else {
      for (const [k, v] of Object.entries(s.guided.vars)) await page.check(`input[name="g_${k}"][value="${v}"]`);
      await settle(); await button('Next: choose the analyses');
      await page.check(`#tick_${s.guided.analysis}`); await settle();
      if (s.guided.ask) { await page.check(`input[name="ask_${s.guided.analysis}"][value="${s.guided.ask}"]`); await settle(); }
      await button('Show my plan');
      got.guided = (await page.locator('#screen .plan-item .card-eid').first().textContent()).trim();
    }
    const ok = ['choose', 'known', 'guided'].every(r => got[r] === s.reaches[r]);
    results.push({ id: s.id, got, ok });
    console.log(`${ok ? 'ok  ' : 'DIFF'} ${s.id}: ${got.choose} / ${got.known} / ${got.guided}`);
  }

  // One screenshot per end card reached. Each card is opened by replaying a
  // scenario's "Help me choose" or "I know my analysis" answers (the card is
  // the same whichever route reaches it; the list is filtered by the
  // screening answers, so it can't be used for every card).
  const reached = [...new Set(scenarios.flatMap(s => Object.values(s.reaches)))];
  for (const id of reached) {
    const viaChoose = scenarios.find(s => s.reaches.choose === id);
    const viaKnown = scenarios.find(s => s.reaches.known === id);
    await home();
    if (viaChoose) {
      await button('Help me choose'); await answer(viaChoose.choose);
    } else if (viaKnown) {
      await button('I know my analysis'); await answer(viaKnown.known.answers);
      if (!(await onCard())) await label(viaKnown.known.pick === 'safety' ? SAFETY : viaKnown.known.pick);
    } else {
      console.log('skip (reached only in the guided route)', id); continue;
    }
    if ((await cardId()) !== id) throw new Error(`Opened ${await cardId()} instead of ${id}`);
    await page.mouse.move(5, 5);
    await page.locator('#screen .endpoint-card').first().screenshot({ path: path.join(OUT, `${id}.png`) });
    console.log('shot', id);
  }
  fs.writeFileSync(path.join(require('os').tmpdir(), 'walkthroughs-last-run.json'), JSON.stringify(results, null, 1));
  await browser.close();
  if (results.some(r => !r.ok)) { console.error('Some routes reached a different end point.'); process.exit(1); }
})().catch(e => { console.error(e); process.exit(1); });
