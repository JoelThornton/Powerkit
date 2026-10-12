# Decisions log

Short records of decisions that are not obvious from the code. Newest last.

## 2026-10-12 · Phases 0–1 (set-up, specification and tests)

**Repository.** The build guide now lives at `docs/build-guide.md` (the path
CLAUDE.md uses). The engine is an R package in `engine/`; `app/` and
`assistant/` are placeholders until phases 5 and 7.

**Backend adapter files must be flat.** R packages ignore subdirectories of
`R/`, so the guide's `engine/R/backends/spower.R` layout will not load. Use
`engine/R/backend-spower.R`, `backend-power4mome.R`, etc. in phases 2–3.

**renv.** renv is initialised at the repository root (where the guide puts
`renv.lock`). renv does not read `engine/DESCRIPTION`, so `_dependencies.R`
lists the packages explicitly; keep it in step with `engine/DESCRIPTION`.
The lockfile was created in an environment without CRAN access, so it pins
R 4.3.3 and older package versions, and does not yet contain Spower,
power4mome or InteractionPoweR. It needs re-snapshotting on a machine with
CRAN access (see the phase 1 summary). CI installs packages from
`engine/DESCRIPTION`, not from the lockfile, so CI tests against current CRAN
releases; the lockfile pins versions for local work and, later, deployment.

**Backends are Suggests for now.** Nothing in the engine calls them yet, so
listing them in Imports would give an R CMD check note. Move each to Imports
when its adapter is written.

**Spec format (version 0.1).**

- JSON Schema draft-07 (supported by every jsonvalidate engine), with
  `if`/`then` branches on `design` and `template` rather than `oneOf`, which
  gives far clearer error messages.
- `goal.n` is the **total number of participants analysed**. Attrition only
  turns this into a recruitment target.
- Basic tests use one template each: `one_sample_t`, `independent_t`,
  `paired_t`, `correlation`, `two_proportions`, `chi_square_independence`.
- 2x2 designs give cell means as a 2x2 array (rows = levels of A) and an SD
  (one number or a 2x2 array). In the mixed design A is between, B within.
  Cells must be equal (as Superpower requires), so n must divide evenly.
- Regression interactions use InteractionPoweR's parametrisation
  (correlations `r_X_Y`, `r_W_Y`, `r_XW_Y`, `r_X_W`), not standardised paths,
  so the spec maps directly onto the backend.
- Mediation and moderated mediation use standardised paths keyed `From->To`.
  Product terms are named by joining the variables (`XW->M`, `MW->Y`). Every
  path in the template must be given (0 for none), so the confirmation
  screen never shows an assumed value.
- PROCESS model 4 covers simple (`M`) and parallel (`M1`, `M2`, ...)
  mediation; model 6 covers serial mediation (`M1` ... `M4`).
- Mediation names the indirect path under test in `target_test.path`.
  Moderated mediation tests the index of moderated mediation only (MVP).
- `options.ci_draws` (Monte Carlo draws per CI) and
  `options.allocation_ratio` (two-group designs) were added to the options
  in the guide's example.
- `effect_justification.type` is one of the four kinds in guide section 7;
  `prior_study` requires an `adjustment`; `pilot_study` gives a warning.

**Validator.** `validate_spec()` checks the schema first, then (only if
the structure is sound) the population. Population checks treat exogenous
variables as standardised and jointly normal, so a product of two variables
with correlation r has variance 1 + r² and is uncorrelated with the rest.
This is an assumption to confirm against power4mome's own conventions in
phase 3. If power4mome exposes its own check, prefer it.

**Validation tests.**

- All validation tests are skipped unless `POWERKIT_FULL_VALIDATION=true`,
  so per-push CI runs only the unit tests; nightly CI runs everything.
- `TODO_PUBLISHED_VALUE` is a classed `NA`; a test that still contains one
  is skipped with a message pointing to its source comment.
- The engine contract the tests assume (`run_spec()`, `result$curve`,
  `result$n_required`) and all backend API calls live in `helper-*.R`
  files, so later phases can adjust them without touching the
  maintainer-owned `test-validation-*` files.
