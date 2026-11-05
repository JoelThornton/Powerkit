# Hosting options for the powerkit app

Options only: this page does not recommend one. It is for the maintainer's
decision on how people other than the maintainer will use the app
(judgement call, hosting).

**About the figures.** The providers' pricing pages could not be opened
from the environment this was written in (they were blocked). Every price
and limit below comes from search-engine summaries on 18 October 2026,
not from the providers' own pages, and is marked "(search result)". Check
each one on the provider's site before deciding. Nothing here has been
bought or tried, except the webR test, which was run (see "In the
browser").

## What the app needs

These come from the app and engine as they are now, not from a provider.

- **R 4.4 or later** with powerkit's packages (about 150 including
  dependencies; `renv.lock` pins them).
- **Memory.** The app plus the backend packages loaded uses several
  hundred MB per R process (not measured precisely; to measure before
  choosing a plan size).
- **Long calculations.** The full-model simulations (mediation,
  moderated mediation, regression interactions) take minutes per run on
  one core. While one runs, the R process is busy; on a single-process
  host, other users wait.
- **No stored data.** The app keeps nothing between sessions and sends
  nothing anywhere. Hosting changes that: the host sees the inputs people
  type in (their study designs), and its logs may keep IP addresses.
- **UK GDPR.** If the app is hosted for others, whoever runs it is the
  controller for any personal data the host collects (IP addresses in
  logs at least). A host outside the UK means a restricted transfer that
  needs a lawful basis (for example an adequacy decision or standard
  contractual clauses). This is general information, not legal advice;
  the university's data protection officer would be the person to ask.

## The options

### shinyapps.io (Posit's hosted Shiny service)

- **What it is.** Upload the app from R (`rsconnect`); Posit runs it.
- **Cost (search result).** Plans have been priced by active hours per
  month. Figures found (dated 2019 in the source, so likely out of date):
  Free 25 hours, Starter $9 for 100 hours, Basic $39 for 500 hours,
  Standard $99 for 2,000 hours, Professional $299 for 10,000 hours.
- **Compute (search result).** Instance memory from 256 MB to 8 GB
  depending on plan (1 GB default). One R process per instance unless the
  plan allows more workers; long simulations block other users of the
  same process.
- **Privacy.** Data is processed by Posit, in its cloud regions (to check
  which). A restricted transfer for UK users if outside the UK.
- **Maintenance.** Low: redeploy from R when the app changes. Package
  versions come from the deploying machine (renv works with it).

- **Closing to new apps.** shinyapps.io closes to new apps at the end of
  2026 and its users move to Posit Connect Cloud (18 October 2026), so
  powerkit deploys to Connect Cloud instead (`decisions.md`).

### Posit Connect (self-hosted) or Posit Connect Cloud

- **What it is.** Connect is Posit's server product, installed on your
  own server (often bought by universities). Connect Cloud is Posit's
  hosted version.
- **Cost (search result).** Connect Cloud: Free tier with 4 GB, 2 CPUs and
  20 hours (December 2024, beta); Basic $19 a month (8 GB, 2 CPUs);
  Enhanced $59 a month (16 GB, 4 CPUs); Advanced from $249 a month for 5
  seats (2026). Self-hosted Connect is licensed per organisation (price
  on request; not found).
- **Compute.** Self-hosted: whatever the server has; Connect can run
  several R processes per app and scale them. Connect Cloud: the plan's
  memory and CPUs.
- **Privacy.** Self-hosted on a university server: data stays with the
  university. Connect Cloud: Posit processes it (as shinyapps.io).
- **Maintenance.** Self-hosted: someone runs the server (updates, R
  versions, packages). Connect Cloud: low.
- **How to deploy (Connect Cloud).** Connect Cloud publishes the app
  straight from this GitHub repository’s `connect-cloud` branch. A successful
  publishing workflow carries checked main source there after a merge
  (one-time migration: `repository-protection.md`).
  It installs the packages listed in `app/routing/manifest.json`, which
  the `online-app-manifest` workflow rewrites and commits to `connect-cloud` after
  every merge that changes the app, the engine or `renv.lock` (the
  manifest pins powerkit's engine to one commit, so it must be rewritten
  for an engine change to reach the online app). The free plan needs the
  repository to be public (Connect Cloud docs, via search, 18 October
  2026). `scripts/deploy-online.R` is the fallback: it deploys from R on
  the maintainer's computer (steps at the top of that file).

#### Search discovery after deployment

The app serves `www/robots.txt`, `www/sitemap.xml` and `www/guide.html` as
public paths. The robots file allows public crawling and advertises the
sitemap; the guide provides useful text without a Shiny WebSocket session.
Only stable public pages belong in the sitemap, never session URLs, saved
plans or invented routes.

Connect Cloud blocks general crawlers by default. At deployment it probes
`/robots.txt`; the app must answer HTTP 200 for its custom policy to be used.
After merging, wait for the manifest workflow and automatic redeployment,
then check the **public** `/robots.txt`, `/sitemap.xml` and `/guide.html`.
The robots response must contain `Allow: /`, not the platform's default
`Disallow: /`. If the old policy remains, redeploy through Connect Cloud and
check its publishing logs. Reference: [Posit's robots guidance](https://docs.posit.co/connect-cloud/user/share/robots.html).

Once these public checks pass, submit `sitemap.xml` in Google Search Console
and request indexing of the home and guide pages using URL inspection.
Crawling permission and a sitemap help discovery; they do not guarantee
indexing or ranking. Reference: [Google's recrawl guidance](https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl).

#### Publishing from GitHub (once, on the Connect Cloud website)

Button names are from Connect Cloud's documentation (found by search,
18 October 2026), not checked against the live site.

1. Wait for a successful publishing run and verify `app/routing/manifest.json`
   on `connect-cloud`. For an existing app, follow `repository-protection.md`
   to change its source branch without creating or deleting the app.
2. Go to https://connect.posit.cloud and sign in.
3. Click **Publish**, then choose **Shiny** and **GitHub** as the source.
4. If asked, install the Posit Connect Cloud GitHub App and give it access
   to the JoelThornton/Powerkit repository.
5. Choose the repository **JoelThornton/Powerkit**, the branch **connect-cloud**,
   and the primary file **app/routing/app.R**.
6. Leave **Automatically publish on push** switched on (the default).
7. Click **Publish** and wait while it installs the packages (several
   minutes the first time). Keep the old copy for now: it stays online
   while the new one is set up.
8. Open the new copy from the link it shows and check it loads.
9. Only then delete the old copy (the one published from RStudio): open
   it in the content list and delete it from its settings or "..." menu.
   This can't be undone, so do it last.
10. If the new copy's web address differs from the old one, the links in
    the README, `status.md` and `user-testing.md` need updating to it.

After the source-branch migration, each successful publishing run following a merge to main updates the app. Main is not modified by the publishing bot.

#### Google Search Console verification

`app/routing/www/google47b320cdc6781b0a.html` is the HTML file Google
Search Console uses to confirm ownership of the online app's address.
Shiny serves files in `www/` from the site root, so Google finds it at
`/google47b320cdc6781b0a.html`. Keep the file: Google checks it again
from time to time, and removing it ends the verification.

### A university server (Shiny Server, open source)

- **What it is.** The free, open-source Shiny Server on a university
  virtual machine, maintained by IT or the maintainer.
- **Cost.** Software free. The server itself depends on the university
  (often free to staff, or a charge for a virtual machine).
- **Compute (search result).** The open-source edition runs one R process
  per app, so a long simulation for one user makes the others wait.
  Running several copies behind a load balancer, or using
  ShinyProxy (one container per user), works around this at the cost of
  more setup.
- **Privacy.** Strongest: data stays on university systems, under the
  university's own data protection arrangements.
- **Maintenance.** Highest: operating system updates, R and package
  updates, security, backups. Depends on IT's willingness to host R.

### A container service (for example Google Cloud Run)

- **What it is.** The app is packaged as a Docker container (R, packages,
  app) and the service runs copies on demand, scaling to zero when idle.
- **Cost (search result), Cloud Run.** Free tier of 180,000 vCPU-seconds,
  360,000 GiB-seconds and 2 million requests a month; then about
  $0.000024 per vCPU-second and $0.0000025 per GiB-second. A light
  prototype might stay within the free tier; heavy simulation use would
  not (not estimated).
- **Compute.** Each copy gets the memory and CPUs configured; requests can
  be spread over copies, so one long simulation need not block others.
  Shiny needs a sticky session (one user stays on one copy), which these
  services support with settings to check. A cold start after idle means
  a wait while R loads.
- **Privacy.** The cloud provider processes the data; UK or EU regions
  can usually be chosen.
- **Maintenance.** Medium: maintain the Dockerfile and rebuild when
  packages change; the provider runs the servers.

### In the browser (webR / Shinylive)

- **What it is.** webR is R compiled to WebAssembly; Shinylive runs a
  Shiny app entirely in the user's browser. The app becomes static files
  that any web server (or GitHub Pages) can serve. Nothing is sent to a
  server: the calculations run on the user's computer.
- **Cost.** Static hosting: free (GitHub Pages) or near free.
- **Compute.** The user's own computer, in one browser thread. WebAssembly
  in the browser has no parallel processing (search result: Futureverse
  demo page), so simulations run on one core and slower than native R
  (measured below: E10 took 3.5 times as long as native R). The first
  visit downloads R and every package.
- **Privacy.** Strongest for users: inputs never leave their browser. The
  host only serves files (its logs may still record IP addresses).
- **Maintenance.** Medium: every package must be available as a webR
  build; a package that isn't blocks the cards that use it (in the test,
  Spower and SimDesign weren't available).
- **Feasibility test (18 October 2026).** See "webR test results" below.

### A bundled desktop app (Electron with portable R)

- **What it is.** A downloadable app that contains R, the packages and
  the Shiny app, and opens in its own window (Electron). Tools found
  (search result; none tried): shinyelectron (a prototype; its first
  version used webR inside Electron), electricShine, Photon (portable R),
  RInno (Windows installers), DesktopDeployR.
- **Cost.** Free to distribute (GitHub Releases); code signing
  certificates cost money if installers are to open without warnings on
  Windows and macOS (prices not checked).
- **Compute.** The user's computer, native R, all cores: the fastest
  option for simulations.
- **Privacy.** Nothing leaves the user's computer.
- **Maintenance.** High: separate builds for Windows and macOS (Intel and
  Apple silicon), each a large download (R plus packages, likely several
  hundred MB; not measured), rebuilt for every update, and signing and
  notarisation on macOS. The run-it-yourself guide
  ([run-it-yourself.md](run-it-yourself.md)) already gives users native
  R without a bundle, at the cost of installing R.

## Side by side

| | Cost | Long simulations | Where the inputs go | Maintenance |
| --- | --- | --- | --- | --- |
| shinyapps.io | by hours used (search result) | block one process; bigger plans add workers | Posit's cloud | low |
| Connect Cloud | monthly plan (search result) | plan's CPUs | Posit's cloud | low |
| Connect, self-hosted | licence plus server | server's CPUs, several processes | the university | medium to high |
| University server (Shiny Server) | server only | one process per app unless extra setup | the university | high |
| Container service | pay per use, free tier (search result) | spread over copies | cloud provider, region chosen | medium |
| webR / Shinylive | free static hosting | user's browser, one core, slower | stays in the browser | medium |
| Desktop bundle | free, plus signing | user's computer, all cores | stays on the computer | high |
| Run it yourself (now) | free | user's computer, all cores | stays on the computer | low (guide and CI check) |

## When a database becomes useful

The prototype does not need a database now: it stores nothing between
sessions, and a saved project can be a file the user keeps (see
[saving-projects.md](saving-projects.md)). A database such as Supabase
(hosted Postgres with sign-in) becomes useful when one of these is wanted:

- **Saved analyses** kept for the user on the server, so they can come
  back from another computer.
- **Share links** that point to a stored analysis, rather than carrying
  every input in the link itself.
- **A job queue** for long simulations: the app records the job, a
  worker runs it, and the user collects the result later from a private
  link instead of keeping the page open.

Supabase (search result): a free tier with a 500 MB database, 50,000
monthly active users and 2 projects, paused after a week of inactivity;
paid plans from $25 a month. A database means storing personal data
(email addresses for sign-in, and the analyses), so it brings UK GDPR
duties: a privacy notice, a lawful basis, retention and deletion, and a
transfer assessment if the data is held outside the UK.

## webR test results

The test is a throwaway branch (`claude/project-thread-uqcark-webr-spike`,
never merged; the app was not changed). It ran on GitHub Actions, because
webR's servers were blocked from the environment this page was written in.

Run: [webr-spike run 3](https://github.com/JoelThornton/Powerkit/actions/runs/39082703228)
(18 October 2026), webR 0.6.0 (R 4.6.0), against native R 4.5.3 on the
same GitHub runner.

**1. Do the packages install?** Each was installed into a fresh webR from
webR's own repository (repo.r-wasm.org), then loaded. Those that failed
were tried again from r-universe's CRAN builds.

| Package | Role in powerkit | webR repository | r-universe |
| --- | --- | --- | --- |
| pwr 1.3.0 | E1–E6 by formula | installs | — |
| pwrss 1.3.1 | E5 unequal groups; wave 2 | installs (an older version than powerkit's) | — |
| **Spower** | Welch's t-test (E2's default when Welch is chosen); simulation on request for E1–E6 | **fails**: needs qs2, which isn't there | **fails**: needs quadprog |
| **SimDesign** | Spower's simulation engine | **fails**: needs qs2 | **fails**: a dependency download failed |
| Superpower 0.2.4.1, afex, emmeans | E7, E8 | install | — |
| InteractionPoweR 0.2.4 | E9 | installs | — |
| power4mome 0.2.1, lavaan, manymome | E10–E14 | install | — |
| MASS, digest, jsonlite, jsonvalidate, V8, yaml | engine | install | — |
| shiny, bslib | the app | install | — |
| callr, processx | the app's background runs | install (whether they can start a second R process in the browser was not tested; very likely not) | — |
| simsem, testthat | validation only | install | — |

So everything installs **except Spower and SimDesign**. Without them, a
browser version would lose Welch's t-test and the simulation option for
E1–E6, unless Spower's missing dependency is built for webR.

**2. E2 and E10 in the browser.** A throwaway page ran powerkit's
exported R scripts in headless Chromium (the scripts call the backend
packages directly, so the powerkit engine itself wasn't loaded in webR).

| | Native R (runner) | webR in Chromium | webR in Node |
| --- | --- | --- | --- |
| Start webR | — | 1.4 s | 1.1 s |
| Install E2's packages (pwr) | — | 1.3 s | 1.6 s |
| E2 power at N = 200 (Student's t, pwr) | 0.007 s; 0.8036 | 0.08 s; 0.8036, reproduced exactly | 0.06 s |
| Install E10's packages (power4mome and its dependencies) | — | 8.5 s | 23 s |
| E10 power at N = 200, 100 simulations | 83 s; 0.95 | 293 s (3.5 times native); 0.94 | 311 s |

- E2 by formula is instant in the browser and gives the same number.
- E10's simulation took about 3.5 times as long as native R on the same
  machine, on one core. Its power differed by one simulated data set in
  100 (0.94 against 0.95; Monte Carlo SE about 0.02), so the browser's
  random numbers or a package version differ somewhere; the exported
  script reported "These numbers differ from powerkit's result". Why was
  not investigated.
- **Download size: not measured.** The byte counter saw only the page's
  own requests (70 KB in 5 requests), not the packages webR's worker
  downloaded, so the figure is wrong and isn't reported. Timings on a
  fast data-centre connection understate a first visit on home or
  campus broadband.
- Install times include downloading from webR's servers, which may have
  been cached during the run (the availability check installed the same
  packages earlier).

**What this suggests (not a recommendation).** A browser version looks
possible for the formula cards (E1–E8), and slow
but possible for E10–E14 at small numbers of simulations. The blockers
are Spower (Welch's t-test and simulation on request) and the app's
separate-process runs, which would need another approach in the
browser. The spike's code stays on its branch.

## Long calculations: durable jobs assessment (5 November 2026)

This is an architecture proposal, not an implemented service or a hosting
purchase. The current app starts a `callr` process in
`app/routing/R/results.R`; `app.R` cancels it on session end or when leaving
the calculation screen. Progress is an estimate of elapsed time, not a
persisted count of completed simulations. A local R script/launcher remains
the supported way to complete a long search independently of a browser.
Saving a project or unfinished draft does not checkpoint the running job.

### Recommended route

Keep instant formulas in the existing app. For long simulations, separate the
worker from the Shiny session and persist the job outside the app process.
A queue and durable result/checkpoint store must survive a worker restart and
an app redeployment; the host's ephemeral filesystem is insufficient. Which
provider supplies these is undecided. First measure memory, CPU time, queue
length and storage for representative mediation, mixed-model and adaptive
sample-size searches, with a fixed budget and concurrency cap.

The browser submits a validated specification and receives an unguessable,
expiring retrieval ticket. The ticket is a bearer secret: do not put it in
public analytics, logs or a shareable page link. Store only its hash; separate
read and cancellation capabilities. An optional account can follow later.
Show the retention date and allow deletion. A returning visitor can open the
job with their ticket and download the result or a project file. Do not
promise completion if the queue rejects a job or the retention window ends.
No email service or collection of participant data is needed.

### Statistical and operational contract

- A job records the canonical spec hash, package/engine versions, lockfile and
  worker-image digest, seed scheme, goal, requested accuracy, allocation and
  target statistic. Results from another version are a new run, not a resume.
- Immutable checkpoint keys include job, sample-size point, batch index and
  deterministic random-stream identity. A committed batch is counted once,
  even if a worker retries after losing its acknowledgement. Use independent
  reproducible streams; do not repeat the same seed for every batch or make
  results depend on the number of workers that happen to be available.
- Persist attempted, valid, failed and successful decisions with their
  denominator convention. Do not pool rounded powers, average confidence
  intervals or silently discard failed fits. Preserve convergence/error
  diagnostics and the interval method. A partially completed run is labelled
  incomplete and is never presented as its requested final accuracy.
- Adaptive sample-size searches must persist the evaluated grid, allocation
  rounding, bounds, target, stopping rule, remaining budget and seed-stream
  positions. Restarting a bracket is not resuming it. Parallel batches must
  not change the stopping rule or accidentally count exploratory draws twice.
- Several current backends expose whole-run calls rather than resumable
  batch statistics. Initially checkpoint completed N points and rerun only
  an interrupted point with its original stream. Within-point resume needs a
  backend-specific adapter and fresh validation before enabling it; a queue
  alone cannot provide that guarantee.
- A lease/heartbeat detects abandoned workers. Enforce per-job CPU/memory/time
  limits and a global fair queue. Cancellation is idempotent, releases the
  worker and prevents later publication of a stale success. The user can
  still download explicitly labelled completed checkpoints before deletion.
- Publication is atomic: commit a finished result, its diagnostics and its
  provenance together. The browser only renders that committed record.
  Input changes create a separate job; they cannot relabel an old result.

### Staged delivery and acceptance

1. Measure current runs and add structured diagnostics; keep current scripts
   available. Prototype a single worker and external durable state using
   synthetic specifications only, with spending and retention limits.
2. Add queueing and ticket recovery for whole jobs. Test browser disconnect,
   app restart, worker termination, time limit, duplicate submission, expired
   ticket, cancellation race, full disk and unavailable storage. No job is
   reported complete until its result is durably committed.
3. Add completed-point resume, then validated within-point batching per
   backend. For a fixed image/spec/stream plan, uninterrupted and deliberately
   interrupted runs must produce the same decisions and denominators.
   Distributional checks against independent runs must also pass when the
   backend cannot promise byte-for-byte equivalence. Test mixed worker counts,
   failures, duplicated messages and adaptive searches near the power target.
4. Trial bounded real usage, measure completion and cost, and review retention
   and abuse controls before increasing limits. Publish the supported
   checkpoint granularity and reproducibility limits in the interface.

The useful first milestone is recovering a finished long job after closing the
browser. Within-point resumption is a separate statistical engineering task.
Current Connect Cloud deployment is not evidence that an external queue or
persistent worker is available; confirm the chosen host's supported deployment
model before selecting infrastructure. This proposal makes no current vendor
price, persistence or background-execution guarantee.
