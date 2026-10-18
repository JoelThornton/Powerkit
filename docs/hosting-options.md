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
