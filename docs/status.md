# Project status

*Last updated: 22 October 2026. This page says where the project is now
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
- **More tests by formula** (pwrss): Fisher's exact test (E5's test
  version) and one-way ANCOVA (E23) are in the app; chi-square goodness of
  fit (E48, its own card) and two independent correlations (E49) are in
  the app. None is checked against G\*Power yet.
- **Generic tests**: t, F, chi-square and z from a noncentrality
  parameter, as in G\*Power, are in the app in review (E50, only from "I
  know my analysis"; no sample size). pwrss's search for the noncentrality
  needed is wrong for a t test with few degrees of freedom (3 to about 12);
  the engine now checks the answer and refuses a wrong one.
- **App** (`app/routing/`): the question tree, cards and input screens for
  every end point. E1–E9, one-way ANOVA (E18), ANCOVA (E23), multiple
  regression (E24), one proportion (E25), McNemar (E26), goodness of fit
  (E48), two correlations (E49) and the generic tests (E50, in review) calculate in
  the app; E10–E14 give a rough
  preview, then a full run in the app or an R script. Results can be saved
  as a project file and reopened. It is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud>; the
  run-it-yourself guide ([`run-it-yourself.md`](run-it-yourself.md)) is
  for running it on one's own computer. In "Plan my whole study",
  each analysis is marked as not planned, main or extra; the sample size
  will be set by the main ones (the combined N is still a placeholder).
  Changing alpha or choosing a one-sided test asks for a reason, which
  goes into the write-up. In review (19 October 2026): the direction is asked first ("Does your hypothesis predict a
  direction?", not pre-filled), a claim needing all of several tests
  raises each test's target power so all succeed together, and the
  no-correction advice notes that it depends on one's view of
  significance testing ([`decisions.md`](decisions.md), 19 October). The About tab says what powerkit
  does and doesn't do, where the numbers come from and how far along it
  is; a "What's new" tab lists dated changes in plain words, from
  `app/routing/whats-new.yaml` (both in review).
- **Feedback and the public view** (in review, 22 October 2026): a
  Feedback tab (bugs, questions, suggestions) whose Send button stores
  the message in the `powerkit_feedback` table of the goal-machine
  Supabase project (read it in Supabase's table editor), with a GitHub
  issue and copying as alternatives. The undecided settings now show only
  in the maintainer's view (`?view=maintainer`).
  Merged 22 October 2026: the banner names the analyses in plain words,
  and the guided plan's combined N and consistency check are labelled
  "Coming soon".
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
  the write-up was merged the same day.

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
   `scripts/deploy-online.R`. Running it on your own computer: the Mac
   route broke on 19 October 2026 when CRAN replaced a locked package
   (RcppArmadillo); the lockfile now has the new version.
3. Fill the core gaps: the "does this still apply?" flag on the
   effect-size source is merged (19 October 2026), and so is the smallest
   detectable effect with no effect size for two proportions and
   chi-square; the smallest detectable effect for regression
   interactions (by the fast fixed-model formula, labelled) is merged too.
4. User testing with the online link, run by the maintainer: the plan
   ([`user-testing.md`](user-testing.md)) is ready for the four screens.
5. The maintainer's judgement session
   ([`judgement-session.md`](judgement-session.md); routing from screen A
   onwards first).
6. Optional features (any time; those that help testing first): "guess first" (merged 19 October 2026),
   a plain-words version of the write-up for ethics applications (merged 19
   October 2026), a plan checker for supervisors and reviewers (merged 19
   October 2026), and a "Labs (experimental)" tab whose first tool,
   pre-replication notes (Karhulahti et al., 2025), is in review (plan:
   the "Powerkit Labs: plan" Claude Doc). Later Labs tools, such as the
   design-upgrade comparator, wait for a statistician.
7. More tests by formula from the packages powerkit already uses (the
   maintainer's direction, 18 October 2026): all are in the app or in
   review. Left for later: Wilcoxon and other rank tests (need a
   statistician's view), dependent correlations, logistic and Poisson
   regression, and contrasts. Validation later.
8. Before release: published values, independent
   checks for moderated mediation and the Monte Carlo interval with two or
   more mediators, phase 3b (binary X and W), and the methodologist
   collaboration.
