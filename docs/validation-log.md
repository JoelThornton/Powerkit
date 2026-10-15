# Validation log

Every full validation run of the powerkit engine, newest last. A full run is
`scripts/run-validation.R` (or an earlier equivalent) with
`POWERKIT_FULL_VALIDATION=true` and 10,000 replications per test (build
guide, section 6). After a run, paste the summary the script prints (also
saved to `validation-results/summary.txt`) as a new entry, with any notes.

Each entry gives the date, commit, platform, versions and the result of
each chunk run. Published-value tests that still have a
`TODO_PUBLISHED_VALUE` skip; a SKIP for that reason is expected. Decisions
that follow from a run go in `docs/decisions.md`.

Chunks: basic, anova, interactions, process_4 (simple and parallel
mediation), process_6 (serial mediation), process_7, process_14; plus the
on-demand interaction_grid.

## Running the full validation on GitHub

The validation can run on GitHub's computers instead of yours: the
repository is public, so GitHub Actions is free, and its standard Linux
machine has 4 cores and about 16 GB of memory. Each run does one chunk and
can take at most 6 hours. Nothing runs on its own; you start each run.

**Start a run**

1. Go to the repository on GitHub and click the **Actions** tab (at the
   top, between Pull requests and Projects).
2. In the list of workflows on the left, click **full-validation**.
3. A blue band says "This workflow has a workflow_dispatch event trigger".
   On its right, click **Run workflow**. Leave the branch as `main` (or
   pick the branch you want to validate), choose the **chunk** from the
   list, and click the green **Run workflow** button.
4. After a few seconds the run appears in the list (refresh if not), with
   a yellow dot while it runs. You can close the page; it keeps running.
   Click it, then click the job, to watch its progress: the step "Run the
   ... chunk" prints the same progress lines as on your own machine.

**Download the results**

1. When the run ends, its dot becomes a green tick (every test ran and
   none failed) or a red cross (a test failed or errored, or the chunk hit
   the time limit). If the chunk ran, its results are uploaded either
   way. If the run stopped before the chunk started (installing or
   loading packages failed), there are no results: click the step with
   the red cross to see why.
2. Open the run. At the bottom of its **Summary** page, under
   **Artifacts**, click **validation-results-*chunk*-run-*number***. This
   downloads a zip file (you must be signed in to GitHub).
3. Unzip it. `summary.txt` is the summary to paste into this file as a new
   entry; each test also has a `.rds` file (its saved result) and a `.log`
   file (everything it printed). Artifacts are kept for 30 days.

**Time.** The mediation chunks run one test at a time with all 4 cores;
the others run 4 tests at a time. Rough times, from timings on the
maintainer's laptop: basic and interactions, minutes; anova and
process_6, about an hour; process_4, about 2.5 hours; process_7 and
process_14, about 3 hours each. A GitHub machine may be slower than the
laptop; if it is twice as slow, **process_7 and process_14 might not fit
in 6 hours**. If a chunk reaches the limit, the run stops at about
5 h 30 m, the tests that finished are still in the artifact, and the
summary lists the rest as NOT RUN; run those on your own machine (copy
the downloaded `.rds` files into `validation-results/` first, and the
script carries on from them). The first run also spends about 10 minutes
installing packages; later runs reuse them.

**Versions.** The run uses R and the package versions in `renv.lock`, as
on your machine, so its results can be compared with local ones.

## Before this log

Runs recorded in `docs/decisions.md` before this file existed. The loop bug
fixed in PR #7 affected only the anova chunk; PR #7 confirmed the basic and
interactions results below were unaffected, so they stand. The anova
results reported before PR #7 (the phase 3 run and an earlier anova chunk
run reporting 10 PASS) are invalid and are superseded by the 14 October
2026 run below.

### 2026-10-13 · basic (phase 3)

- **Recorded in:** `docs/decisions.md`, "Phase 3: basic tests, regression
  interactions, mediation" (validation run for this phase). Commit not
  recorded.
- **Platform:** Windows, R 4.5.3; 10,000 replications.
- **basic:** all 20 analytic, direct-call and Type I error tests pass,
  including the one-sided t-test; Type I error rates .048 to .052. The 4
  G*Power published tests skip (TODO values).
- A later run of the basic chunk with `scripts/run-validation.R` ("Phase
  3: maintainer decisions", decision 11): 24 tests in 4 minutes on 2
  cores, identical results to this run.

### 2026-10-13 · interactions

- **Recorded in:** `docs/decisions.md`, "Regression interactions: analytic
  method, before any switch".
- **Commit:** 97cc736 (maintainer's run).
- **interactions:** passed. Both analytic tests agree with simulation:
  0.6343 vs 0.6363 perfectly measured; 0.5483 vs 0.5544 with unreliable
  measures. The three published-value tests skip (TODO values). Per-test
  counts and package versions were not recorded.

### 2026-10-13 · interaction_grid (on demand, not part of a full run)

- **Recorded in:** `docs/decisions.md`, "Regression interactions: grid
  results; simulation stays the default".
- **Commit:** 3b136fe; 2 cores, 28 minutes; R 4.5.3, InteractionPoweR
  0.2.4.
- **Result:** 69 of 72 cells within the 99.9% Monte Carlo interval;
  simulation lower than analytic in 51 of 72 cells (details in that entry).

## 2026-10-14 · anova

- **Commit:** 2035111 (main, after PR #7). **Cores:** 2.
- **Platform:** Windows, R 4.5.3.
- **Packages:** powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4,
  InteractionPoweR 0.2.4, power4mome 0.2.1, lavaan 0.7.3, testthat 3.3.2.
- **anova:** 30 PASS, 0 FAIL, 0 ERROR, 0 SKIP (of 30: 16 in the 2 x 2
  between file, 14 in the 2 x 2 mixed file). The first run with every test
  recorded under its own name (after PR #7).
- **Note on the Type I error tests.** The chunk's four Type I error tests
  (two between, two mixed) use the exact method (`ANOVA_exact()`), so
  they give exactly 0.0500 by construction. They confirm that powerkit
  translates "no effect" correctly, but they are not an empirical check of
  the simulation's Type I error rate. Simulation versions of these tests
  are an open item (`docs/build-guide.md`, section 6).
