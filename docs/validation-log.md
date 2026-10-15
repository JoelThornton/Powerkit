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
