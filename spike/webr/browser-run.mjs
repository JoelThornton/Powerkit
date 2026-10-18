// Serve page.html, open it in headless Chromium, and record load time,
// bytes downloaded (CDP Network events) and run times. webR in the browser
// needs cross-origin isolation for its default channel, so the server sends
// COOP/COEP headers.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const server = http.createServer((req, res) => {
  const file = path.join(process.cwd(), req.url === "/" ? "page.html" : req.url.slice(1));
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
  if (!fs.existsSync(file)) { res.statusCode = 404; return res.end(); }
  res.setHeader("Content-Type", file.endsWith(".html") ? "text/html" : "text/plain");
  res.end(fs.readFileSync(file));
}).listen(8123);

const browser = await chromium.launch();
const page = await browser.newPage();
const cdp = await page.context().newCDPSession(page);
await cdp.send("Network.enable");
await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
let bytes = 0, requests = 0;
cdp.on("Network.loadingFinished", (e) => { bytes += e.encodedDataLength; requests += 1; });
page.on("console", (m) => console.log("PAGE", m.text().slice(0, 300)));
const t0 = Date.now();
await page.goto("http://localhost:8123/");
let initBytes = null;
await page.waitForFunction(() => document.getElementById("log").textContent.includes("init"), null, { timeout: 600000 });
initBytes = bytes;
await page.waitForFunction(() => window.spikeResult, null, { timeout: 3600000, polling: 1000 });
const result = await page.evaluate(() => window.spikeResult);
result.wall_seconds = (Date.now() - t0) / 1000;
result.bytes_at_init = initBytes;
result.bytes_total = bytes;
result.requests = requests;
console.log("BROWSER", JSON.stringify(result));
fs.writeFileSync("out/browser.json", JSON.stringify(result, null, 2));
await browser.close();
server.close();
