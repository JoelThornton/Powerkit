# Phase 5: running the simulation-heavy end points

*Last updated: 17 October 2026. Decided by the maintainer on 17 October 2026 (see "Decided" below) and built in phase 5, part 2.*

Phase 5, part 1 wires calculations into the app for the end points that
run in seconds (E1–E8). This page is about the rest:
- regression interactions (E9, InteractionPoweR);
- simple, parallel and serial mediation (E10–E12, power4mome);
- moderated mediation (E13, E14, power4mome).

It sets out how long they take and the ways they could run, with what each
way means for precision and for users. The maintainer's decision is in
"Decided" at the end.

## How long they take

All figures are for the example values on each input screen
(`app/routing/tests/testthat/helper-forms.R`), with powerkit's defaults:
1,000 replications, and for mediation 1,000 Monte Carlo draws per
confidence interval.

**Measured in this session** (17 October 2026, one core, the build
container; a laptop may differ by a factor of about 2):

| End point | Goal | Time | Result |
| --- | --- | --- | --- |
| E1–E8 (wired) | power at a fixed N | 0.6–8 s | — |
| E1–E8 (wired) | required N | 3.7–18.5 s | — |
| E9 interaction | power at N = 120 | 5 s | power 0.161 |
| E9 interaction | required N (80% power) | 80 s | N = 1,055 |
| E10 simple mediation | power at N = 120 | 734 s (12 min) | power 0.851 |

E11–E14 weren't timed here; the validation timings below show they are at
least as slow as E10.

**From the full validation runs** (GitHub, 4 cores; 10,000 replications
per simulation, 10 times the app's default; `validation-log.md`):

| Chunk | Time | Per-replication cost |
| --- | --- | --- |
| process_4 (simple and parallel mediation) | 4 h 22 m | about 0.4 s per replication per core (`full-validation.yaml`) |
| process_6 (serial mediation) | 1 h 50 m | similar to process_4 |
| process_7, process_14 (moderated mediation) | about 4 h 16 m each | about 1.4 s per replication per core |
| interactions | about an hour on the maintainer's laptop | — |

**What that means at the app's defaults** (1,000 replications, one
core; estimates from the figures above, not measured):
- **Power at a fixed N:**
  - simple, parallel or serial mediation, 7 to 12 minutes;
  - moderated mediation, about 25 minutes.
- **A required N:** several sample sizes are simulated, typically 5 to 8,
  so mediation takes about **1 to 3 hours**.
- **Interactions:** seconds for power, and about a minute or more for a
  required N.

## Options for running them

The options can be combined. For each: what the user sees, what it means
for precision, and the cost.

### A. In the session, with a progress bar

The calculation runs while the user waits, as for E1–E8, with a progress
bar showing the replications done.

- **Users:** simple. But a mediation sample size could keep the browser
  tab busy for an hour or more, and closing the tab loses the work.
- **Precision:** full (1,000 replications, or whatever the spec asks).
- **Cost:** a Shiny session is busy for the whole run. On a shared server,
  one long run per user ties up a process. Needs progress reporting from
  the engine, which `run_spec()` doesn't offer yet; batches could report
  as they finish.
- **Fits:** interactions (seconds to a minute or two). Fits mediation
  power at a fixed N only if users accept a wait of about 10 minutes.

### B. A quick, low-precision preview first

The app first runs a small number of replications (for example 100, and
for mediation 100 draws per interval), clearly labelled as a rough
preview. It then offers the full run (A or C).

- **Users:** see a number within about a minute; it can help them see
  whether their effect is in a sensible range before committing to a long
  run.
- **Precision:**
  - At 100 replications, the Monte Carlo standard error of a power near
    .8 is about .04: the preview could say 72% or 88% when the truth is
    80%.
  - A required N from a preview could be off by 10–20% (estimate; not
    measured).
  - With 100 draws per interval, power4mome may switch on Boos and Zhang's
    extrapolation for supported R values (Departure 8 turns it off). This
    needs care so the preview matches powerkit's own test.
- **Cost:** a second code path to test. The preview must never be reported
  or exported as the result. The R script and citations would come from
  the full run only.
- **Risk:** users may stop at the preview. The screen would need to make
  clear that it isn't a result to report.

### C. Background jobs

The calculation runs outside the user's session (a job queue, a separate
R process or a server). The user can close the tab and come back to the
result, via a link or an email.

- **Users:** no waiting at the screen. A result that takes hours is
  practical. Coming back later means the result needs storing and an
  address to return to.
- **Precision:** full, or higher (10,000 replications become practical).
- **Cost:** the most to build and run.
  - It needs a queue, storage and a way back to the result.
  - It needs a limit on jobs per user.
  - On a hosted app, it needs computing time to pay for.
  - Results must keep the same provenance (seed, versions, spec hash), so
    the R script still reproduces them.
- **Fits:** mediation and moderated mediation, especially required N.

### D. Run it yourself: the R script instead of a result

For these end points, the app gives the R script (`export_script()`) and
the user runs it on their own computer. The script needs a result to
export today, so this means exporting before running.

- **Users:** no waiting on the app. Needs R and the packages installed,
  which many users won't have.
- **Precision:** full; the user can raise replications or cores.
- **Cost:** `export_script()` would need a mode that writes the script
  from the spec alone. Results the user produces never come back to
  powerkit.
- **Related:** E2 in `judgement-calls.md` (scripts for designs powerkit
  doesn't run).

### E. Fewer replications by default

Lower the default (for example to 500) for these designs only.

- **Users:** about half the wait.
- **Precision:** the Monte Carlo standard error grows by about 40%. For a
  power near .8 it goes from about .013 to .018. Required N intervals
  widen.
- **Cost:** a departure from powerkit's own default. It would need
  recording in `conventions.md`, showing to users and a test.

## Combinations to consider

- **Interactions (E9):** A alone may do: seconds for power, about a
  minute or more for a required N. Measured above.
- **Mediation power at a fixed N:** A, or B then A.
- **Mediation required N, and moderated mediation:** B then C, or D.

## Questions for the maintainer

1. Which option, or combination, for each group (E9; E10–E12; E13–E14)?
2. Is a wait of about 10 minutes in the browser acceptable for mediation
   power at a fixed N?
3. If B: what preview size, and how should it be labelled?
4. If C: where would jobs run (the user's machine, a server, a hosted
   service), and who pays for computing time?
5. Should E9 be wired now with option A? It was measured at 5 seconds
   for power and 80 seconds for a required N. It was left unwired in
   part 1, as instructed. **Decided 17 October 2026:** yes, option A
   with a progress indicator and a Cancel button (wired in phase 5,
   part 2). Questions 1–4 remain open for E10–E14.

## Decided (maintainer, 17 October 2026)

| End points and goal | What the app does | Options |
| --- | --- | --- |
| E10–E12 (mediation), power at a fixed N | A rough preview, then the full run in the app | B then A |
| E10–E12, required N | An R script to run the full analysis on the user's computer (no preview; see below) | D (the plan was B, then D) |
| E13–E14 (moderated mediation), power at a fixed N | A rough preview, then the R script | B, then D |
| E13–E14, required N | The R script (no preview) | D (the plan was B, then D) |

- **The preview (B):** the same spec and seed with 100 replications
  (`forms.yaml`, `simulations > preview_nrep`), everything else as the
  user set it (including 1,000 Monte Carlo draws per interval, so the
  preview runs the same test as the full analysis and Departure 8 still
  holds). It runs in a separate R process with a progress bar and
  Cancel, with the expected wait stated first. It is shown as a range,
  never a single number, with the label the maintainer asked for: "Rough
  preview from 100 simulations: power is likely between X% and Y%. Don't
  report this; run the full analysis." The range for power is the exact
  binomial (Clopper–Pearson) 95% interval from the preview's rejections,
  by base R's `binom.test()` (the engine's `power_interval()`). The preview has no R
  script and no citations, so it can't be exported as a result.
  - **Why a range:** at 100 replications the Monte Carlo standard error
    of a power near .8 is about .04, so a single number would look more
    precise than it is.
- **The full run (A):** E10–E12 power at a fixed N, at the app's defaults
  (1,000 replications), in a separate R process with a progress bar and
  Cancel, as for E9. The expected wait is stated on the button before it
  starts ("Run the full analysis (about 12 minutes)"). Its result screen,
  R script and citations are the same as for E1–E9.
- **The R script (D):** for everything else, "Download R script to run
  the full analysis on your computer", with the expected run time and
  what to install (R at the version power4mome needs, and powerkit from
  GitHub, which installs power4mome). The script (the engine's
  `export_run_script()`) holds the spec and its seed and calls
  `run_spec()`, so it gives the result powerkit would; it then saves the
  result and writes the backend-only reproduction script
  (`export_script()`) and the citations. No full in-browser run for these
  yet.
  - **Why not in the browser:** a required N simulates 5 to 8 sample
    sizes (1 to 3 hours for mediation), and moderated mediation takes
    about 25 minutes even for power at a fixed N.
- **Background jobs (C):** not built. Deferred until hosting and who pays
  for the computing time are decided.
- **Fewer replications (E):** not a default.
- **Seeds:** the preview and the full run use the seed recorded in the
  spec (the app's default is 1, changeable on the input screen), so the
  preview, the full run and the script can all be reproduced.
- **Tests (kept fast, with few replications and draws):** the preview
  uses the recorded seed and equals `run_spec()` on the preview spec; the
  full run in the background equals `run_spec()` with the same spec and
  seed, and its export script reproduces it; the downloaded run script
  gives the same result as `run_spec()` (engine and app tests).

### Preview times

Measured in the build container (17 October 2026, one core, the example
values, 100 replications and 1,000 draws per interval; power at N = 120,
and a required N for 80% power). These are the waits the app states.

| End point | Power at N = 120 (100 replications) | Required N (100 replications per sample size) |
| --- | --- | --- |
| E10 simple mediation | 47 s | Stopped after 1,003 s: "could not pin down the required n" |
| E11 parallel mediation | 50 s | Not run (expected as E10 or longer) |
| E12 serial mediation | 57 s | Not run (expected as E10 or longer) |
| E13 moderated mediation (model 7) | 163 s | Stopped by hand after about 9 minutes (expected over 30 minutes) |
| E14 moderated mediation (model 14) | 167 s | Not run (expected as E13) |

The E10 required-N run shared the container's 4 cores with 3 other R
processes, so alone it would be faster, but still well over 5 minutes.

### A required N has no preview (17 October 2026; for the maintainer's yes)

The plan was a preview for every goal. For a required N it doesn't work:
the engine's search simulates a bracketing pass and then 7 or more sample
sizes, so with 100 replications each it takes over 15 minutes for simple
mediation (hours for moderated mediation), and at that precision the
curve is often too noisy to pin the N down (the E10 run above stopped
with "could not pin down the required n"). So a required N for E10–E14
goes straight to the R script, with one sentence saying why. Power at a
fixed N keeps its preview. Alternatives the maintainer could choose
instead: a preview of power at an N the user enters on the sample-size
form; or a preview from the engine's bracketing pass alone (about 100
replications at a few sample sizes, giving a rough N without an
interval).

