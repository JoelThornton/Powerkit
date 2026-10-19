# Project status

*Last updated: 18 October 2026. This page says where the project is now
and what comes next; keep it short and replace old entries rather than
adding to them. History is in git, [`engine/NEWS.md`](../engine/NEWS.md)
and [`archive/status-history.md`](archive/status-history.md) (everything
up to 18 October 2026).*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md). For the working rules, see
[`handover.md`](handover.md) and `CLAUDE.md`.

## Where things are

- **Engine** (`engine/`): designs E1–E14 run through `run_spec()`. Their
  validation so far is mostly agreement with the package each one calls,
  plus Type I error; independent checks exist for the basic tests (the
  maintainer's G\*Power screenshots) and simple, parallel and serial
  mediation (pwrss and simsem). Published values are still to be
  transcribed (`TODO_PUBLISHED_VALUE` placeholders). Wave 2 (one-way
  ANOVA, R², one proportion, McNemar, Welch by formula) matches G\*Power
  in the engine's tests; it isn't in the full validation run yet.
- **More tests by formula** (pwrss): Fisher's exact test and one-way
  ANCOVA are in the app (E5's test version, E23; in review);
  chi-square goodness of fit and two independent correlations are in the
  engine only. None is checked against G\*Power yet.
- **Generic tests** (engine only): t, F, chi-square and z from a
  noncentrality parameter, as in G\*Power. Not yet in the app.
- **App** (`app/routing/`): the question tree, cards and input screens for
  every end point. E1–E9, one-way ANOVA (E18), ANCOVA (E23), multiple
  regression (E24), one proportion (E25) and McNemar (E26) calculate in
  the app; E10–E14 give a rough
  preview, then a full run in the app or an R script. Results can be saved
  as a project file and reopened. It is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud>; the
  run-it-yourself guide ([`run-it-yourself.md`](run-it-yourself.md)) is
  for running it on one's own computer. In "Plan my whole study",
  each analysis is marked as not planned, main or extra; the sample size
  will be set by the main ones (the combined N is still a placeholder).
- **Open PRs:** see [`handover.md`](handover.md).

## Priorities (the maintainer, 18 October 2026)

- **Usefulness before validation.** powerkit won't be released for a
  while. What matters now is that it is useful, logical and helpful for
  psychologists and solves the problems they have with power analysis.
  Validation and checks come afterwards, before release.
- **The new design** (approved 18 October 2026): four screens (start
  questions, design finder, inputs centred on the effect size, result
  with a plain reading and write-up). The decisions are in
  [`decisions.md`](decisions.md), "The new design". Screens A, C and D
  and the departures on the result screen were merged on 18 October 2026;
  the write-up was merged the same day. The maintainer gives the department talk
  (Friday 23 October 2026).

## What's next

In priority order (agreed direction, 18 October 2026: a working web app
first; 19 October 2026: optional features that help testing can come in
any time, and user testing is the maintainer's to run):

1. The write-up (short and full methods paragraph): merged on 18 October
   2026.
2. A working web app: **online since 18 October 2026** at
   <https://joelthornton-powerkit.share.connect.posit.cloud> (Posit Connect Cloud; the version on main).
   It updates itself: Connect Cloud publishes from GitHub on each merge
   (set up by the maintainer, 18 October 2026), using
   `app/routing/manifest.json` (kept current by a workflow). Fallback:
   `scripts/deploy-online.R`.
3. Fill the core gaps: the "does this still apply?" flag on the
   effect-size source is in review; next, the smallest
   detectable effect for two proportions, chi-square and regression
   interactions in the app.
4. User testing with the online link, run by the maintainer: the plan
   ([`user-testing.md`](user-testing.md)) is ready for the four screens.
5. The maintainer's judgement session
   ([`judgement-session.md`](judgement-session.md); routing from screen A
   onwards first).
6. Optional features (any time; those that help testing first): "guess first" (in review),
   an ethics-board version of the write-up, a plan checker for
   supervisors and reviewers, and a separate "Labs" area for experimental
   tools.
7. More tests by formula from the packages powerkit already uses (the
   maintainer's direction, 18 October 2026): wave 2 is wired in (in
   review); next, one regression coefficient's own card if needed,
   chi-square goodness of fit, Fisher's exact test, two correlations,
   ANCOVA, and the generic t, F, z, chi-square and binomial tests.
   Validation later.
8. Before release: published values, independent
   checks for moderated mediation and the Monte Carlo interval with two or
   more mediators, phase 3b (binary X and W), and the methodologist
   collaboration.
