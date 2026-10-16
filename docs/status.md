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
  results, direct Spower calls and Type I error; simple, parallel and
  serial mediation (with two mediators; three or more not yet tested) and
  moderated mediation, PROCESS models 4, 6, 7 and 14 (via power4mome),
  against direct power4mome calls and Type I error; regression
  interactions (via InteractionPoweR), against analytic results, direct
  InteractionPoweR calls and Type I error. The mediation and interactions
  chunks ran on GitHub on 15–16 October 2026; their published-value tests
  are still TODO. What "validated" means is defined at the top of the
  [validation log](validation-log.md).
- **Waiting on published values:** several validation tests still have
  `TODO_PUBLISHED_VALUE` placeholders (including the G*Power published
  examples for basic tests), to be transcribed by the maintainer.
- **Upstream:** two issues found while wrapping Spower and power4mome were
  reported and fixed upstream on GitHub; powerkit keeps its workarounds
  until the fixes reach CRAN ([conventions](conventions.md), Departures 4
  and 8).
- **Routing prototype (merged in PR #15):** a clickable Shiny prototype of
  [`decision-tree.md`](decision-tree.md), in `app/routing/`. Routing only:
  no engine calls and no calculations. It covers the three routes (I know
  my analysis; help me choose; plan my whole study), end-point cards, and
  placeholders for the undecided judgement calls, which are settings in
  `app/routing/tree.yaml`. A test keeps that file in step with
  `decision-tree.md`, and the prototype's tests run on GitHub on every
  pull request. How to run it: [`routing-prototype.md`](routing-prototype.md).
- **Recognising designs powerkit doesn't cover (draft PR, 16 October
  2026):** a tester's segmented regression was routed to a paired t-test,
  and on another path to a t-test.
  - [`routing-audit.md`](routing-audit.md) traces 29 designs through all
    three routes. It found misroutes for nested, crossed,
    cluster-randomised and dyadic data, time series and segmented
    regression, time-to-event outcomes, precision planning, equivalence
    in the guided route, and SEM with latent variables.
  - Every route now starts with four screening questions (outcome,
    grouping, times measured, goal). Designs outside powerkit's scope
    leave at an honest card before any test is suggested. Every question
    offers "None of these fit / I'm not sure", which suggests a
    statistician.
  - There are new cards:
    - E45 (segmented regression and interrupted time series; no
      ready-made tool);
    - generic cards for time-to-event outcomes (E43), dyadic data (E44)
      and precision (E46);
    - the safety net (E-unsure).
  - Each fixed misroute has a test (`test-misroutes.R`).
  - The audit is cross-checked against UCLA OARC's test-selection table
    (adapted from Leeper), with one row per analysis. That found one more
    misroute, now fixed: factorial logistic regression reaches E27. It
    also found chi-square goodness-of-fit, which has no end point and is
    left for the maintainer. The table doesn't cover nested, clustered or
    time-series data, so the earlier list still applies. The UCLA page
    was blocked in this session, so the maintainer should check the list
    of analyses against it.
  - Still misrouting, left for the maintainer because each needs a
    statistical judgement: curvilinear effects, reliability/ICC,
    non-parametric tests, sequential designs, MANOVA, non-baseline
    covariates and latent-variable mediation entered as mediation (audit,
    "What's left").
  - New undecided settings: the screening wording (open question 16),
    whether E45 and E35 share an end point (17), and whether "not
    covered" cards name other tools (18). Matched pairs versus dyads is
    open question 19.
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
- **Known risk, time limit:** process_7 and process_14 finish about 45
  minutes inside the GitHub time limit (4 h 47 m against the script's
  5 h 30 m stop). If either ever runs out of time, the fix is to split
  that chunk (for example, the direct-call and Type I error tests as
  separate chunks).
- **Memory:** mediation and moderated-mediation simulations run in batches
  of at most 200 replications, so they no longer need more memory than an
  ordinary laptop has (an unbatched 10,000-replication run did). The
  validation can also run on GitHub, one chunk at a time
  ([validation log](validation-log.md), "Running the full validation on
  GitHub").

## What's next

1. The remaining published values for every design (the maintainer
   transcribes them), and validation with three or more mediators for
   parallel and serial mediation (open question 10 in
   [`decision-tree.md`](decision-tree.md)).
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
6. Decide the routing audit's open items: the screening wording and
   open questions 16–19 in [`decision-tree.md`](decision-tree.md), and the
   remaining misroutes listed in [`routing-audit.md`](routing-audit.md).
7. Phase 5: the Shiny app, starting from the routing prototype's
   `app/routing/tree.yaml` and guided by [`decision-tree.md`](decision-tree.md)
   and [`design-finder.md`](design-finder.md), once the maintainer has
   answered their open questions.
