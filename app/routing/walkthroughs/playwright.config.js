const { defineConfig } = require('@playwright/test');
const path = require('node:path');
const baseURL = process.env.PROTOTYPE_URL || 'http://127.0.0.1:8765/';
if (!['127.0.0.1', 'localhost'].includes(new URL(baseURL).hostname)) {
  throw new Error('Browser regression checks must target an isolated local development app.');
}
module.exports = defineConfig({
  testDir: './browser-tests', timeout: 120000, workers: 1, retries: 0,
  expect: { timeout: 20000 }, reporter: [['list'], ['html', { open: 'never' }]],
  webServer: {
    command: 'Rscript --vanilla app/routing/walkthroughs/browser-server.R',
    cwd: path.resolve(__dirname, '../../..'), url: baseURL, timeout: 120000,
    reuseExistingServer: !process.env.CI,
  },
  use: { baseURL, browserName: 'chromium', headless: true, viewport: { width: 1100, height: 900 },
    trace: 'retain-on-failure', screenshot: 'only-on-failure', actionTimeout: 20000 },
});
