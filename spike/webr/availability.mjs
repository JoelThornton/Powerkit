// For each package: does it install and load in webR (Node), from webR's own
// repository, and failing that from r-universe's WebAssembly builds?
import { WebR } from "webr";
import { packages, repos } from "./packages.mjs";
import fs from "node:fs";

const out = { webr: null, r: null, results: {} };
for (const pkg of packages) {
  const row = {};
  for (const [label, url] of Object.entries(repos)) {
    // A fresh webR per attempt, so one package's dependencies don't help another.
    const webR = new WebR({ repoUrl: url });
    await webR.init();
    if (!out.r) {
      out.r = await webR.evalRString("R.version.string");
      out.webr = await webR.evalRString("tryCatch(as.character(utils::packageVersion('webr')), error = function(e) 'unknown')");
    }
    const t0 = Date.now();
    let ok = false, msg = "";
    try {
      await webR.installPackages([pkg], { repos: url, quiet: true });
      ok = await webR.evalRBoolean(`suppressWarnings(requireNamespace("${pkg}", quietly = TRUE))`);
      if (!ok) msg = await webR.evalRString(`tryCatch({loadNamespace("${pkg}"); "loaded"}, error = function(e) conditionMessage(e))`);
      if (ok) msg = await webR.evalRString(`as.character(utils::packageVersion("${pkg}"))`);
    } catch (e) { msg = String(e).slice(0, 300); }
    row[label] = { ok, detail: msg, seconds: (Date.now() - t0) / 1000 };
    webR.close();
    if (ok) break;
  }
  out.results[pkg] = row;
  console.log("AVAIL", pkg, JSON.stringify(row));
}
fs.mkdirSync("out", { recursive: true });
fs.writeFileSync("out/availability.json", JSON.stringify(out, null, 2));
