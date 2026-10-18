// Time E2 and E10's exported scripts in webR under Node.
import { WebR } from "webr";
import fs from "node:fs";

const t0 = Date.now();
const webR = new WebR();
await webR.init();
const tInit = (Date.now() - t0) / 1000;
const result = { init_seconds: tInit, runs: {} };
for (const [name, pkgs] of [["e2", ["pwr"]], ["e10", ["power4mome", "lavaan", "manymome"]]]) {
  const ti = Date.now();
  let installErr = null;
  try { await webR.installPackages(pkgs, { quiet: true }); } catch (e) { installErr = String(e); }
  const install = (Date.now() - ti) / 1000;
  const code = fs.readFileSync(`out/${name}.R`, "utf8");
  await webR.FS.writeFile(`/home/web_user/${name}.R`, new TextEncoder().encode(code));
  const tr = Date.now();
  let err = null;
  try {
    await webR.evalRVoid(`source("/home/web_user/${name}.R", local = new.env())`);
  } catch (e) { err = String(e).slice(0, 500); }
  const run = (Date.now() - tr) / 1000;
  result.runs[name] = { install_seconds: install, run_seconds: run, error: err, install_error: installErr };
  console.log("NODE", name, JSON.stringify(result.runs[name]));
}
webR.close();
fs.writeFileSync("out/node.json", JSON.stringify(result, null, 2));
