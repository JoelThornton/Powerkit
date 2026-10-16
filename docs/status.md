# Project status

*Last updated: 16 October 2026. Update this page with every PR.*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md).

## Where things are

- **Build phases 0–3 are done** ([build guide](build-guide.md), section 8):
  the design spec format and its checks, and an engine that runs every MVP
  design through its backend package.
- **Validated (full validation run passed):** 2 x 2 between and 2 x 2 mixed
  ANOVA (via Superpower); basic tests (via Spower) against analytic
  results, direct Spower calls and Type I error; simple, parallel (two
  mediators) and serial mediation and moderated mediation, PROCESS models
  4, 6, 7 and 14 (via power4mome), against direct power4mome calls and
  Type I error. The mediation chunks ran on GitHub on 15–16 October 2026
  ([validation log](validation-log.md)); their published-value tests are
  still TODO.
- **Run, not yet marked validated:** regression interactions (via
  InteractionPoweR). Its chunk passed on 13 October 2026 ([validation
  log](validation-log.md), "Before this log"), but per-test counts and
  package versions weren't recorded, and the README and routing prototype
  (E9) still list it as in progress.
- **Waiting on published values:** several validation tests still have
  `TODO_PUBLISHED_VALUE` placeholders (including the G*Power published
  examples for basic tests), to be transcribed by the maintainer.
- **Upstream:** two issues found while wrapping Spower and power4mome were
  reported and fixed upstream on GitHub; powerkit keeps its workarounds
  until the fixes reach CRAN ([conventions](conventions.md), Departures 4
  and 8).
- **Routing prototype (draft PR):** a clickable Shiny prototype of
  [`decision-tree.md`](decision-tree.md), in `app/routing/`. Routing only:
  no engine calls and no calculations. It covers the three routes (I know
  my analysis; help me choose; plan my whole study), end-point cards, and
  placeholders for the undecided judgement calls, which are settings in
  `app/routing/tree.yaml`. A test keeps that file in step with
  `decision-tree.md`. How to run it: [`routing-prototype.md`](routing-prototype.md).
  Changes before merging (16 October 2026):
  - Regression interactions (E9) shows "Runs, validation in progress",
    styled apart from validated designs. The mediation designs (E10–E14)
    were flipped to validated on 16 October 2026, once their runs were
    recorded. Flipping one to validated is a one-line change in
    `tree.yaml`, plus the matching cell in `decision-tree.md`.
  - Analyses that no tool offers (E30, E32, E39, the new E42, and
    Cochran's Q in E26) say so plainly. The options are a custom
    simulation in R (for example with Spower) or advice from a
    statistician.
  - E22 (2 x 2 with unequal groups) now cites where Superpower documents
    unequal group sizes: the `ANOVA_design()` help, for `ANOVA_power()`
    and between designs only.
  - `decision-tree.md` and `tree.yaml` gained T1 and MO2 rows in table
    2.2, and the mediators questions on the mediation path with a yes/no
    X. Mediation with three or more conditions now has its own end
    point (E42, not covered by the five tools).
  - Four more undecided settings, recorded as open questions: storing
    PP1/F6, guided-route covariates (15), where Bayes factors enter
    (8), and the guided route's scope (14).
  - shiny and the packages it needs are now in `renv.lock`, and the
    prototype's tests run on GitHub on every pull request
    (`routing-prototype-tests.yaml`).
- **App:** a prototype Shiny app for the 2 x 2 designs is in a draft PR
  (#4). It stays an open draft, kept as a starting point for phase 5
  ([decisions](decisions.md), 15 October 2026). The `validate_spec()` bug
  it reported (a null SD crashed with "non-character argument") is fixed.
- **Goal and coverage:** the maintainer's goal is stated in the
  [build guide](build-guide.md) overview. [`coverage.md`](coverage.md)
  lists every user-facing capability of Superpower, Spower, power4mome,
  InteractionPoweR and G*Power, with powerkit's status and proposed tiers.
  The tiers are for the maintainer to confirm, and the G*Power rows still
  need checking against the G*Power manual.
  A section on needs the five tools don't cover (crossed participants and
  stimuli, multilevel, longitudinal, SEM, sequential and Bayesian designs,
  equivalence, precision, bias-corrected and replication planning, several
  outcomes, ordinal outcomes) lists candidate tools for each, checked
  against their own package sources.
- **Decision tree (draft):** [`decision-tree.md`](decision-tree.md) is a
  draft spec of how an app user gets from their study to a power analysis,
  for phase 5. It covers how G*Power, Superpower, Spower, power4mome,
  InteractionPoweR and PAMLj route users; a question tree mapped to the
  spec schema, with end points E1 to E42; the judgement calls where
  methodologists disagree, left undecided; and open questions. All of it
  is a proposal for the maintainer to confirm. It builds on
  [`design-finder.md`](design-finder.md), whose status labels are now up
  to date. The flowcharts, including a single full chart for
  presentations, are rendered in
  [`figures/decision-tree/`](figures/decision-tree/).
  Section 4 proposes how to handle studies with several hypotheses: an
  optional guided "plan my whole study" route (variables defined once,
  one card per analysis, the combined N for the primary analyses, and
  warnings when effect sizes contradict each other), two approaches to
  consistency (per hypothesis, or whole-study simulation) left
  undecided, and a worked example.
- **Coverage:** [`coverage.md`](coverage.md) now also has rows for ANCOVA
  (including pre–post), covariates in mediation, mediation with a
  multi-category X, moderation with a 3+ group X or W, and several
  hypotheses in one study.
- **Validation on GitHub:** the `full-validation` workflow works: after a
  setup fix (PR #11), the basic chunk passed there on 15 October 2026
  (20 PASS, 4 SKIP for TODO published values), matching the earlier
  Windows runs ([validation log](validation-log.md)).
- **Memory:** mediation and moderated-mediation simulations run in batches
  of at most 200 replications, so they no longer need more memory than an
  ordinary laptop has (an unbatched 10,000-replication run did). The
  validation can also run on GitHub, one chunk at a time
  ([validation log](validation-log.md), "Running the full validation on
  GitHub").

## What's next

1. Decide whether the 13 October interactions run counts as E9's full
   validation (or rerun the interactions chunk on GitHub), and flip E9 in
   `app/routing/tree.yaml` ([how](routing-prototype.md)). Then the
   remaining published values for every design.
2. Simulation versions of the 2 x 2 ANOVA Type I error tests (build guide,
   section 6, open items).
3. Binary X and W in regression interactions and mediation (phase 3b,
   build guide section 8). It comes next after phase 3 closes, before
   phase 4. The maintainer has decided its effect-size convention, group
   split and handling of correlated predictors.
4. Confirm the proposed tiers in [`coverage.md`](coverage.md), and check
   its G*Power and MorePower rows against the G*Power manual and the
   MorePower paper.
5. Phase 4: script export, methods paragraph, citations and
   preregistration text.
6. Phase 5: the Shiny app, starting from the routing prototype's
   `app/routing/tree.yaml` and guided by [`decision-tree.md`](decision-tree.md)
   and [`design-finder.md`](design-finder.md), once the maintainer has
   answered their open questions.
