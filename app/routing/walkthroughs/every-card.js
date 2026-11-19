// Opens every card in the running app, fills the app suite's example
// values, calculates, and fetches every download and the printable
// planning document, recording timings and anything that went wrong: R
// error text, NA or NaN in a result, blank outputs, failed or tiny
// downloads, browser console errors. Rerun before each release
// (docs/repository-protection.md, "Checks before a release"); all cards
// take about an hour.
//
// From the repository root:
//   Rscript app/routing/walkthroughs/every-card-list.R cards.json
//   Rscript app/routing/walkthroughs/browser-server.R &   (port 8765)
//   node app/routing/walkthroughs/every-card.js cards.json every-card.json [power]
// The optional last argument sets every card's goal (e.g. power, with
// n = 100 where the example gives none). ONLY=E2,E7 limits the cards,
// SHOTS=dir saves a screenshot of each result, SAVE=dir keeps the R
// scripts. It exits with status 1 when any card has a problem.
const { chromium } = require('playwright');
const fs = require('fs');
const URL = process.env.PROTOTYPE_URL || 'http://127.0.0.1:8765/';
const cards = JSON.parse(fs.readFileSync(process.argv[2] || 'cards.json', 'utf8'));
const OUT = process.argv[3] || 'every-card.json';
const launch = process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {};
const GOAL = process.argv[4] || null; // e.g. "power"
const ONLY = process.env.ONLY ? process.env.ONLY.split(',') : null;
const SHOTS = process.env.SHOTS || null;

(async () => {
  const browser = await chromium.launch(launch);
  const ctx = await browser.newContext({ viewport: { width: 1100, height: 900 }, acceptDownloads: true });
  const page = await ctx.newPage();
  const consoleErr = []; const dialogs = [];
  page.on('dialog', async d => { dialogs.push(d.type() + ': ' + d.message().slice(0, 200)); await d.dismiss().catch(() => {}); });
  page.on('console', m => { if (m.type() === 'error') consoleErr.push(m.text().slice(0, 300)); });
  page.on('pageerror', e => consoleErr.push('pageerror: ' + String(e).slice(0, 300)));
  const idle = async (t = 60000) => {
    await page.waitForTimeout(120);
    await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: t });
  };
  const pick = async (v) => {
    const t0 = Date.now();
    await page.evaluate(v => Shiny.setInputValue('pick', v, { priority: 'event' }), v);
    await idle();
    return Date.now() - t0;
  };
  const results = [];
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#screen', { timeout: 60000 });
  await page.waitForFunction(() => window.Shiny && Shiny.setInputValue, null, { timeout: 60000 });
  await idle();
  for (const c of cards) {
    if (ONLY && !ONLY.includes(c.id)) continue;
    const r = { id: c.id, title: c.title, consoleErrors: [], problems: [], downloads: [] };
    consoleErr.length = 0;
    try {
      await pick('home');
      r.t_card = await pick('ep:' + c.id);
      const cardText = await page.locator('#screen').innerText();
      r.card_has_enter = await page.locator('#screen button', { hasText: 'Enter your values' }).count() > 0;
      if (/Error in|Traceback|subscript out of bounds|object '.*' not found/.test(cardText)) r.problems.push('card shows R error text');
      if (!c.has_form || !c.example) { r.status = 'card-only'; results.push(r); console.log(c.id, 'card-only'); continue; }
      r.t_form = await pick('form');
      const ex = Object.assign({}, c.example);
      if (GOAL) { ex.goal = GOAL; if (GOAL === 'power' && !ex.n) ex.n = '100'; }
      // Fill in example order, selects triggering redraws first; two passes.
      const missing = new Set();
      for (let pass = 0; pass < 2; pass++) {
        for (const [k, v] of Object.entries(ex)) {
          if (v === null) continue;
          const el = page.locator('#f_' + k);
          if (await el.count() === 0) { if (pass === 1) missing.add(k); continue; }
          // Open a folded section ("Optional: names for the write-up") first.
          await el.first().evaluate(x => { const d = x.closest('details'); if (d) d.open = true; });
          if (!(await el.first().isVisible())) { if (pass === 1) missing.add(k + '(hidden)'); continue; }
          const tag = await el.first().evaluate(x => x.tagName);
          try {
            if (tag === 'SELECT') {
              const cur = await el.first().inputValue();
              if (cur !== String(v)) { await el.first().selectOption(String(v)); await idle(); }
            } else {
              const cur = await el.first().inputValue();
              if (cur !== String(v)) { await el.first().fill(String(v)); await el.first().blur(); }
            }
            missing.delete(k); missing.delete(k + '(hidden)');
          } catch (e) { if (pass === 1) missing.add(k + '(' + String(e).split('\n')[0].slice(0, 80) + ')'); }
        }
        await idle();
      }
      r.unfilled = [...missing];
      if (GOAL && await page.locator('#f_goal').count()) {
        r.goal_options = await page.locator('#f_goal option').evaluateAll(os => os.map(o => o.value));
      }
      const t0 = Date.now();
      await page.locator('#form_check').click();
      // Wait for a finished result, a problem list, or time out.
      const limit = 300000;
      let state = 'timeout';
      while (Date.now() - t0 < limit) {
        await page.waitForTimeout(250);
        const done = await page.evaluate(() => {
          const fr = document.querySelector('#form_result');
          const busy = document.documentElement.classList.contains('shiny-busy');
          if (!fr) return null;
          if (fr.querySelector('.calculating')) return null;
          if (busy) return null;
          if (fr.querySelector('.form-problems')) return 'problems';
          if (fr.querySelector('.result-panel')) return 'result';
          const fp = document.querySelector('#screen .form-problems');
          if (fp) return 'problems';
          if (fr.innerText.trim().length > 20) return 'other';
          return null;
        });
        if (done) { state = done; break; }
      }
      r.t_calc = Date.now() - t0;
      r.status = state;
      const resText = await page.locator('#form_result').innerText().catch(() => '');
      r.result_len = resText.length;
      if (state !== 'result') r.message = resText.slice(0, 600) || (await page.locator('#screen .form-problems').first().innerText().catch(() => '')).slice(0, 600);
      if (/Error in|Traceback|subscript out of bounds|object '.*' not found|argument of length 0|non-numeric argument/.test(resText)) r.problems.push('result shows R error text');
      if (/NaN|\bNA\b|Inf\b|NULL/.test(resText)) r.problems.push('result text has NA/NaN/Inf/NULL: ' + (resText.match(/.{0,60}(NaN|\bNA\b|Inf\b|NULL).{0,60}/) || [''])[0]);
      r.warnings_shown = await page.locator('#form_result .alert-warning, #form_result .warning, #form_result [class*=warn]').allInnerTexts().then(a => a.map(s => s.slice(0, 200))).catch(() => []);
      await page.waitForTimeout(2000);
      // Outputs that stay empty until the visitor asks for them.
      const ON_DEMAND = ['bayes_companion'];
      const emptyOutputs = await page.evaluate(ON_DEMAND => [...document.querySelectorAll('#form_result .shiny-html-output, #form_result .shiny-image-output, #form_result .shiny-plot-output')].filter(e => e.offsetParent && e.innerHTML.trim() === '' && !ON_DEMAND.includes(e.id)).map(e => e.id), ON_DEMAND);
      if (emptyOutputs.length) r.problems.push('blank outputs: ' + emptyOutputs.join(','));
      if (SHOTS) await page.screenshot({ path: `${SHOTS}/${c.id}${GOAL ? '-' + GOAL : ''}.png`, fullPage: false });
      // Downloads.
      const links = await page.evaluate(() => [...document.querySelectorAll('a.shiny-download-link')].filter(a => a.offsetParent).map(a => ({ id: a.id, href: a.getAttribute('href'), disabled: a.getAttribute('aria-disabled'), text: a.innerText.trim() })));
      for (const l of links) {
        const d = { id: l.id, text: l.text, disabled: l.disabled };
        if (!l.href || !/download/.test(l.href)) { d.status = 'no href'; r.downloads.push(d); continue; }
        const t1 = Date.now();
        try {
          const resp = await page.request.get(new globalThis.URL(l.href, URL).toString(), { timeout: 180000 });
          d.status = resp.status(); d.ms = Date.now() - t1;
          const body = await resp.body(); d.bytes = body.length;
          d.type = resp.headers()['content-type'];
          const head = body.subarray(0, 4000).toString('utf8');
          if (process.env.SAVE && /script/.test(l.id)) { fs.mkdirSync(process.env.SAVE, { recursive: true }); fs.writeFileSync(`${process.env.SAVE}/${c.id}${GOAL ? '-' + GOAL : ''}-${l.id}.R`, body); }
          if (d.bytes < 50) r.problems.push(`download ${l.id} tiny (${d.bytes} bytes)`);
          if (d.status !== 200) r.problems.push(`download ${l.id} HTTP ${d.status}`);
          if (/Error in |Traceback/.test(head)) r.problems.push(`download ${l.id} contains R error`);
        } catch (e) { d.status = 'fail ' + String(e).slice(0, 100); r.problems.push(`download ${l.id} failed`); }
        r.downloads.push(d);
      }
      // PDF (print frame)
      if (await page.locator('#planning_document_button:visible').count()) {
        const t2 = Date.now();
        await page.locator('#planning_document_button').click();
        try {
          await page.waitForSelector('#pk-print-frame', { state: 'attached', timeout: 30000 });
          const h1 = await page.evaluate(() => { const f = document.getElementById('pk-print-frame'); const d = f && f.contentWindow.document; return d ? ((d.querySelector('h1') || {}).textContent || '') + ' | ' + d.body.innerText.length : 'nodoc'; });
          r.pdf = { ok: /\w/.test(h1), ms: Date.now() - t2, h1 };
          if (!r.pdf.ok) r.problems.push('PDF print frame empty');
        } catch (e) { r.pdf = { ok: false, dialogs: dialogs.slice() }; r.problems.push('PDF print frame did not appear ' + dialogs.join(';')); }
      }
    } catch (e) {
      r.status = 'crash'; r.message = String(e).slice(0, 400);
    }
    r.consoleErrors = [...consoleErr];
    results.push(r);
    console.log(r.id, r.status, r.t_calc, r.problems.join(' | '), (r.unfilled || []).join(','));
    fs.writeFileSync(OUT, JSON.stringify(results, null, 1));
  }
  await browser.close();
  const bad = results.filter(r => r.problems.length || r.consoleErrors.length || ['crash', 'timeout', 'other', 'problems'].includes(r.status));
  console.log(`\n${results.length} cards checked, ${bad.length} with a problem.`);
  for (const r of bad) console.log(`- ${r.id}: ${r.status}${r.problems.length ? '; ' + r.problems.join('; ') : ''}${r.consoleErrors.length ? '; console: ' + r.consoleErrors.join(' / ').slice(0, 200) : ''}`);
  if (bad.length) process.exitCode = 1;
})().catch(e => { console.error(e); process.exit(1); });
