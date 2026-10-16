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

## What "validated" means

A design is marked validated (`status: runs_validated` in
`app/routing/tree.yaml`, a green "Runs in powerkit" card; "Yes" in table
2.3 of `docs/decision-tree.md`; "Working" in the README) when a full run
of its chunk, recorded in this log, shows all of the following:

1. **No failures or errors.** The only skips allowed are published-value
   tests that still have `TODO_PUBLISHED_VALUE`.
2. **Agreement with direct backend calls.** powerkit's power matches a
   direct call to the package that computes it (power4mome, Spower,
   Superpower or InteractionPoweR) within the 99.9% Monte Carlo
   tolerance, and matches analytic results where the design has them.
3. **Type I error within tolerance.** With the target effect set to zero,
   the rejection rate lies in [0.040, 0.060] at alpha = .05.

**Published-value checks can still be pending.** They are the second kind
of test in the build guide (section 6), and a design can be validated
before its published values are transcribed. Its card then says so
("published values still to be transcribed"), and no card says a design
matches published results until those tests have passed.

**Validated means validated as tested.** If the tests cover only part of
what the spec allows (for example two mediators, where the spec allows
more), the card says what was tested and what wasn't.

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
the others run 4 tests at a time. Measured on GitHub (15–16 October
2026): basic, 6 minutes; process_6, 1 h 52 m; process_4, 4 h 23 m;
process_7 and process_14, about 4 h 47 m each. Every chunk fits, but
process_7 and process_14 finish only about 45 minutes before the script's
5 h 30 m stop, so a slower machine could push them over. (anova and
interactions haven't run on GitHub yet; on the maintainer's laptop they
take about an hour and a few minutes.) If a chunk reaches the limit, the run stops at about
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

## 2026-10-15 · basic (GitHub Actions)

- **Run:** the first run of the `full-validation` workflow on GitHub
  ([run 38799579835](https://github.com/JoelThornton/Powerkit/actions/runs/38799579835)),
  after PR #11 fixed its setup. **Commit:** 260b943 (main). **Cores:** 4,
  one per test.
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **basic:** 20 PASS, 0 FAIL, 0 ERROR, 4 SKIP (of 24). All analytic,
  direct-call and Type I error tests pass; Type I error rates .048 to
  .052. The 4 published-value tests skip (TODO values), as expected. Same
  outcome as the 13 October runs on Windows.

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-15 20:15   Commit: 260b943   Cores: 4
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 20 PASS, 0 FAIL, 0 ERROR, 4 SKIP, 0 NOT RUN (of 24)

PASS    basic / independent t-test: power matches pwr (analytic) (11s)
          success: Reference power 0.8015; must lie in [0.7899, 0.8161] around powerkit's estimate 0.8030 (MCSE 0.0040, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / independent t-test, one-sided: power matches pwr (analytic) (10s)
          success: Reference power 0.8090; must lie in [0.7980, 0.8238] around powerkit's estimate 0.8109 (MCSE 0.0039, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / independent t-test, unequal groups: power matches pwr (analytic) (11s)
          success: Reference power 0.7328; must lie in [0.7285, 0.7573] around powerkit's estimate 0.7429 (MCSE 0.0044, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / one-sample t-test: power matches pwr (analytic) (10s)
          success: Reference power 0.8038; must lie in [0.7843, 0.8107] around powerkit's estimate 0.7975 (MCSE 0.0040, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / paired t-test: power matches pwr (analytic) (10s)
          success: Reference power 0.8078; must lie in [0.7958, 0.8216] around powerkit's estimate 0.8087 (MCSE 0.0039, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / correlation at alpha = .01: power matches pwr (analytic) (18s)
          success: Reference power 0.8818; must lie in [0.8749, 0.8959] around powerkit's estimate 0.8854 (MCSE 0.0032, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / two proportions: power matches pwr (analytic) (11s)
          success: Reference power 0.8021; must lie in [0.8006, 0.8262] around powerkit's estimate 0.8134 (MCSE 0.0039, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    basic / chi-square test of independence: power matches pwr (analytic) (9s)
          success: Reference power 0.6204; must lie in [0.6018, 0.6338] around powerkit's estimate 0.6178 (MCSE 0.0049, 99.9% Monte Carlo interval plus rounding of the reference).
SKIP    basic / independent t-test: matches the Faul et al. (2007) G*Power example (published) (4s)
SKIP    basic / paired t-test: matches G*Power 3.1 manual example (published) (4s)
SKIP    basic / correlation: matches the Faul et al. (2007) exact bivariate-normal example (published) (4s)
SKIP    basic / two proportions: matches a published example (published) (3s)
PASS    basic / independent t-test: powerkit matches a direct Spower call (16s)
          success: powerkit's estimate 0.6948 vs the direct backend call 0.6912: difference 0.0036; the 99.9% Monte Carlo tolerance is 0.0215.
PASS    basic / paired t-test: powerkit matches a direct Spower call (16s)
          success: powerkit's estimate 0.6976 vs the direct backend call 0.6957: difference 0.0019; the 99.9% Monte Carlo tolerance is 0.0214.
PASS    basic / correlation: powerkit matches a direct Spower call (33s)
          success: powerkit's estimate 0.7160 vs the direct backend call 0.7160: difference 0.0000; the 99.9% Monte Carlo tolerance is 0.0210.
PASS    basic / two proportions: powerkit matches a direct Spower call (17s)
          success: powerkit's estimate 0.7758 vs the direct backend call 0.7758: difference 0.0000; the 99.9% Monte Carlo tolerance is 0.0194.
PASS    basic / chi-square test of independence: powerkit matches a direct Spower call (14s)
          success: powerkit's estimate 0.4947 vs the direct backend call 0.4947: difference 0.0000; the 99.9% Monte Carlo tolerance is 0.0233.
PASS    basic / independent t-test: Type I error is near alpha (9s)
          success: Type I error rate 0.0518; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / independent t-test, unequal groups (Welch): Type I error is near alpha (10s)
          success: Type I error rate 0.0498; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / one-sample t-test: Type I error is near alpha (10s)
          success: Type I error rate 0.0479; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / paired t-test: Type I error is near alpha (9s)
          success: Type I error rate 0.0519; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / correlation: Type I error is near alpha (15s)
          success: Type I error rate 0.0502; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / two proportions: Type I error is near alpha (9s)
          success: Type I error rate 0.0482; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    basic / chi-square test of independence: Type I error is near alpha (7s)
          success: Type I error rate 0.0511; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-15 · process_6 (GitHub Actions)

- **Run:** [run 38802624184](https://github.com/JoelThornton/Powerkit/actions/runs/38802624184) of the `full-validation` workflow.
  **Commit:** 315de0e (main). **Cores:** 4, all on one test at a time;
  power4mome simulations in batches (PR #10).
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **process_6:** 2 PASS, 0 FAIL, 0 ERROR, 1 SKIP (of 3). powerkit matches a
  direct power4mome call (0.9946 vs 0.9950, tolerance 0.0033), and the
  Type I error rate with the M1->M2 link at 0 is 0.0526. The published
  serial example skips (TODO value), as expected.
- **Time:** 1 h 50 m of tests (1 h 52 m for the whole run).

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-15 22:22   Commit: 315de0e   Cores: 4 (4 per test)
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 2 PASS, 0 FAIL, 0 ERROR, 1 SKIP, 0 NOT RUN (of 3)

SKIP    process_6 / serial mediation: matches a published serial example (published) (3s)
PASS    process_6 / serial mediation: powerkit matches a direct power4mome call (1h 13m)
          success: powerkit's estimate 0.9946 vs the direct backend call 0.9950: difference -0.0004; the 99.9% Monte Carlo tolerance is 0.0033.
PASS    process_6 / serial mediation: Type I error is near alpha when the M1->M2 link is 0 (0h 37m)
          success: Type I error rate 0.0526; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-16 · process_7 (GitHub Actions)

- **Run:** [run 38817441311](https://github.com/JoelThornton/Powerkit/actions/runs/38817441311) of the `full-validation` workflow.
  **Commit:** 3d30d38 (main). **Cores:** 4, all on one test at a time;
  power4mome simulations in batches (PR #10).
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **process_7:** 2 PASS, 0 FAIL, 0 ERROR, 3 SKIP (of 5). powerkit matches a
  direct power4mome call (0.9092 vs 0.9097, tolerance 0.0134), and the
  Type I error rate with the XW->M path at 0 is 0.0508. The three
  published-value tests skip (TODO values), as expected.
- **Time:** 4 h 45 m of tests (4 h 46 m for the whole run). Run at the
  same time as process_14, on a separate GitHub machine.

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-16 03:15   Commit: 3d30d38   Cores: 4 (4 per test)
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 2 PASS, 0 FAIL, 0 ERROR, 3 SKIP, 0 NOT RUN (of 5)

SKIP    process_7 / PROCESS model 7: matches the power4mome vignette example (published) (3s)
SKIP    process_7 / PROCESS model 7: matches Donnelly, Jorgensen & Rudolph (2023) (published) (3s)
SKIP    process_7 / PROCESS model 7: required n matches the power4mome vignette (published) (3s)
PASS    process_7 / PROCESS model 7: powerkit matches a direct power4mome call (3h 09m)
          success: powerkit's estimate 0.9092 vs the direct backend call 0.9097: difference -0.0005; the 99.9% Monte Carlo tolerance is 0.0134.
PASS    process_7 / PROCESS model 7: Type I error is near alpha when the XW->M path is 0 (1h 36m)
          success: Type I error rate 0.0508; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-16 · process_14 (GitHub Actions)

- **Run:** [run 38817510781](https://github.com/JoelThornton/Powerkit/actions/runs/38817510781) of the `full-validation` workflow.
  **Commit:** 3d30d38 (main). **Cores:** 4, all on one test at a time;
  power4mome simulations in batches (PR #10).
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **process_14:** 2 PASS, 0 FAIL, 0 ERROR, 2 SKIP (of 4). powerkit matches
  a direct power4mome call (0.9093 vs 0.9105, tolerance 0.0133), and the
  Type I error rate with the MW->Y path at 0 is 0.0485. The two
  published-value tests skip (TODO values), as expected.
- **Time:** 4 h 45 m of tests (4 h 47 m for the whole run).

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-16 03:16   Commit: 3d30d38   Cores: 4 (4 per test)
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 2 PASS, 0 FAIL, 0 ERROR, 2 SKIP, 0 NOT RUN (of 4)

SKIP    process_14 / PROCESS model 14: matches a power4mome vignette example (published) (3s)
SKIP    process_14 / PROCESS model 14: matches Donnelly, Jorgensen & Rudolph (2023) (published) (3s)
PASS    process_14 / PROCESS model 14: powerkit matches a direct power4mome call (3h 11m)
          success: powerkit's estimate 0.9093 vs the direct backend call 0.9105: difference -0.0012; the 99.9% Monte Carlo tolerance is 0.0133.
PASS    process_14 / PROCESS model 14: Type I error is near alpha when the MW->Y path is 0 (1h 34m)
          success: Type I error rate 0.0485; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-16 · process_4 (GitHub Actions)

- **Run:** [run 38868946986](https://github.com/JoelThornton/Powerkit/actions/runs/38868946986) of the `full-validation` workflow.
  **Commit:** 1d18372 (main). **Cores:** 4, all on one test at a time;
  power4mome simulations in batches (PR #10).
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **process_4:** 5 PASS, 0 FAIL, 0 ERROR, 2 SKIP (of 7). Simple mediation,
  parallel mediation and parallel mediation with correlated residuals all
  match a direct power4mome call (differences 0.0026, -0.0017 and
  -0.0002; tolerances 0.0175, 0.0185 and 0.0120). Type I error rates are
  0.0489 (simple, a = 0 with b large) and 0.0486 (parallel, a null
  specific indirect effect). The two published-value tests skip (TODO
  values), as expected. The parallel tests use two mediators.
- **Time:** 4 h 22 m of tests (4 h 23 m for the whole run).
- **Commits (all four mediation runs).** The runs used three commits of
  main (315de0e, 3d30d38, 1d18372). Between them, and up to 64c03c6, the
  changes were a validation error message, comments in the test files and
  packages for the app; nothing the mediation designs use. So these
  results stand for main as of 16 October 2026.

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-16 12:05   Commit: 1d18372   Cores: 4 (4 per test)
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 5 PASS, 0 FAIL, 0 ERROR, 2 SKIP, 0 NOT RUN (of 7)

SKIP    process_4 / simple mediation: matches the power4mome Quick Template (published) (2s)
PASS    process_4 / simple mediation: powerkit matches a direct power4mome call (1h 04m)
          success: powerkit's estimate 0.8299 vs the direct backend call 0.8273: difference 0.0026; the 99.9% Monte Carlo tolerance is 0.0175.
PASS    process_4 / simple mediation: Type I error is near alpha when a = 0 and b is large (0h 33m)
          success: Type I error rate 0.0489; must lie in [0.040, 0.060] for alpha = 0.05.
SKIP    process_4 / parallel mediation: matches a published parallel example (published) (3s)
PASS    process_4 / parallel mediation: powerkit matches a direct power4mome call (1h 05m)
          success: powerkit's estimate 0.8025 vs the direct backend call 0.8042: difference -0.0017; the 99.9% Monte Carlo tolerance is 0.0185.
PASS    process_4 / parallel mediation with correlated residuals: powerkit matches a direct power4mome call (1h 07m)
          success: powerkit's estimate 0.9277 vs the direct backend call 0.9279: difference -0.0002; the 99.9% Monte Carlo tolerance is 0.0120.
PASS    process_4 / parallel mediation: Type I error is near alpha for a null specific indirect effect (0h 33m)
          success: Type I error rate 0.0486; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-16 · interactions (GitHub Actions)

- **Run:** [run 38919436842](https://github.com/JoelThornton/Powerkit/actions/runs/38919436842) of the `full-validation` workflow.
  **Commit:** 2678f37 (main). **Cores:** 4, one per test.
- **Platform:** GitHub's Ubuntu runner, R 4.5.3, packages from
  `renv.lock` (versions in the summary below).
- **interactions:** 5 PASS, 0 FAIL, 0 ERROR, 3 SKIP (of 8). Both analytic
  tests agree with simulation (0.6343 vs 0.6363 perfectly measured; 0.5483
  vs 0.5544 with unreliable measures, the same values as the 13 October
  run); powerkit matches a direct `InteractionPoweR::power_interaction()`
  call (0.5286 vs 0.5286); Type I error rates 0.0509 and 0.0516. The three
  published-value tests (InteractionPoweR tutorial) skip (TODO values), as
  expected. This run supersedes the 13 October entry, which didn't record
  per-test counts or versions.
- **Warning in the log:** "executing %dopar% sequentially: no parallel
  backend registered", from the direct `power_interaction()` call. It
  means that call ran on one core; it doesn't change the result.
- **Time:** 3 m 28 s for the whole run (4 tests at a time).

```
===== powerkit validation summary (copy from here) =====
Date: 2026-10-16 14:56   Commit: 2678f37   Cores: 4
R: R version 4.5.3 (2026-03-11)   Platform: x86_64-pc-linux-gnu
Packages: powerkit 0.0.0.9000, Superpower 0.2.4.1, Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1, manymome 0.3.7, lavaan 0.7.3, testthat 3.3.2
Totals: 5 PASS, 0 FAIL, 0 ERROR, 3 SKIP, 0 NOT RUN (of 8)

PASS    interactions / interaction, perfectly measured: power matches power_interaction_r2 (analytic) (0h 01m)
          success: Reference power 0.6343; must lie in [0.6205, 0.6521] around powerkit's estimate 0.6363 (MCSE 0.0048, 99.9% Monte Carlo interval plus rounding of the reference).
PASS    interactions / interaction with unreliable measures: power matches power_interaction_r2 (analytic) (0h 01m)
          success: Reference power 0.5483; must lie in [0.5380, 0.5708] around powerkit's estimate 0.5544 (MCSE 0.0050, 99.9% Monte Carlo interval plus rounding of the reference).
SKIP    interactions / interaction: matches the InteractionPoweR tutorial example (published) (4s)
SKIP    interactions / interaction with measurement error: matches the InteractionPoweR tutorial (published) (4s)
SKIP    interactions / interaction: required N matches the InteractionPoweR tutorial (published) (4s)
PASS    interactions / interaction: powerkit matches a direct InteractionPoweR::power_interaction call (0h 02m)
          warning: executing %dopar% sequentially: no parallel backend registered
          success: powerkit's estimate 0.5286 vs the direct backend call 0.5286: difference 0.0000; the 99.9% Monte Carlo tolerance is 0.0232.
PASS    interactions / interaction: Type I error is near alpha when main effects exist (52s)
          success: Type I error rate 0.0509; must lie in [0.040, 0.060] for alpha = 0.05.
PASS    interactions / interaction with unreliable measures: Type I error is near alpha (37s)
          success: Type I error rate 0.0516; must lie in [0.040, 0.060] for alpha = 0.05.
===== end of summary =====
```

## 2026-10-16 · process_7 and process_14 need a rerun (no run; a note)

The process_7 and process_14 runs above (16 October 2026, commit 3d30d38)
no longer validate the current code, so PROCESS models 7 and 14 (E13 and
E14) are back to "Runs, validation in progress".

**Why.** PR #20 fixed how power4mome calls are seeded. For a model with a
product term, `power4test()` standardises the population by Monte Carlo
(100,000 draws) before its `iseed` takes effect, using whatever state R's
random-number generator is in. powerkit now runs each call under
`set.seed(seed)` as well as `iseed = seed` (`docs/decisions.md`,
16 October 2026). The simulated data sets are the same, but the
standardisation uses different draws, so results for models 7 and 14
differ slightly from the runs above with the same seeds. The method is
unchanged, and the earlier runs are expected to be statistically
equivalent. But "validated" means a recorded full run of the current code,
so both chunks are rerun after PR #20 is merged.

**Not affected.** Models without a product term (simple, parallel and
serial mediation; process_4 and process_6) are standardised analytically,
so their results are identical. E10–E12 stay validated.

**To do after merge:** run the process_7 and process_14 chunks of the
`full-validation` workflow and record them here; then set E13 and E14 back
to `runs_validated` (tree.yaml, decision-tree.md table 2.3, coverage.md,
README).
