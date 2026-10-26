# Project status

*Last updated: 26 October 2026. This page says where the project is now
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
- **Planned comparisons (contrasts)** (pwrss's t test of a weighted
  combination of one factor's means, with trend tests as a special case):
  in the engine only, in review (25 October 2026), with validation
  placeholders for the G\*Power manual's three contrasts. Superpower's
  emmeans route agrees with it, which is a unit test.
- **More tests by formula** (pwrss): Fisher's exact test (E5's test
  version) and one-way ANCOVA (E23) are in the app; chi-square goodness of
  fit (E48, its own card) and two independent correlations (E49) are in
  the app. None is checked against G\*Power yet. Two dependent
  correlations (one group, with or without a shared variable) have their
  own card (E51) and input screen, in review (26 October 2026): pwrss's Steiger test,
  unpooled as G\*Power (Departure 12, decided 25 October 2026),
  with validation placeholders for the G\*Power manual's examples 28.3.1
  and 28.3.2.
- **Logistic regression** (pwrss's Wald z test of one predictor, a score or
  a yes/no group, with other predictors through an R-squared): in the
  engine only, in review (25 October 2026), with validation placeholders
  for the G\*Power manual's examples.
- **Poisson regression** (pwrss's Wald z test of one predictor of a count
  outcome, over a mean exposure): in the engine only, in review (25
  October 2026), with validation placeholders for the G\*Power manual's
  examples. It reproduces every number in the manual's section 30 that
  powerkit can compute (docs/decisions.md).
- **Conventions against the G\*Power manual**: the G\*Power entries in
  docs/conventions.md are being filled in from the manual the maintainer
  supplied. Sections 3 to 6, 10, 11, 13, 14 and 19 to 21 are done (in
  review, 25 October 2026); the manual has no section on
  repeated-measures ANOVA, the two-proportions z test, the chi-square test
  of independence, ANCOVA or mediation, so those entries need G\*Power
  itself. No new judgement call came out of it: the one the first draft
  raised, powerkit's Fisher z against G\*Power's exact correlation test,
  was already settled on 17 October 2026 and written up as Known
  difference 10. Next: the pwrss column, from the installed sources.
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
- **Merged 22 October 2026:** a Feedback tab whose Send button stores
  the message in the `powerkit_feedback` table of the goal-machine
  Supabase project (read it in Supabase's table editor), with a GitHub
  issue and copying as alternatives; the undecided settings show only in
  the maintainer's view (`?view=maintainer`); the banner names the
  analyses in plain words, and the guided plan's combined N and
  consistency check are labelled "Coming soon"; at most two long
  calculations run at once across all visitors (`forms.yaml`,
  `background_limit`), so a busy room can't use up the online server's
  memory.
- **Decisions recorded 22 October 2026:** eleven settings that were
  marked undecided but already built now record their value
  ([`decisions.md`](decisions.md)); so are four that change the app:
  observed power allowed with a warning (a new spec type,
  `own_study_result`), the rank-test label, named tools on "not covered"
  cards, and two parallel mediators only.
- **Candidates recorded (25 October 2026):** three of the five roadmap rows
  with no ready-made tool now name one (powerMediation for B14,
  semPower for B17, DescTools for B27's test). All three are marked
  **not checked** against their own help files, because CRAN wasn't
  reachable from the build environment; nothing is built on them.
- **G\*Power checks (25 October 2026, in review):** of the eight rows
  marked "wired, not yet checked against G\*Power", the manual settles
  two, and both reproduce it: two independent correlations (A6, section
  27) and the generic t test (A47, section 25). The other six have no
  section in the manual (ANCOVA, goodness of fit, the generic F,
  chi-square and z tests) or an empty Examples subsection (Fisher's exact
  test), so they need G\*Power itself.
- **Consistency tests (25 October 2026, in review):** four tests for
  places where a document, a script and a workflow have to agree and
  nothing checked it: every validation file in a chunk of
  run-validation.R, every chunk with a time estimate and a place in the
  full-validation workflow, every test conventions.md names existing, and
  coverage-roadmap.md's summary counts matching its rows
  (`app/routing/tests/testthat/test-repo-consistency.R`).
- **Fix (25 October 2026):** coverage-roadmap.md said six designs (E9 to
  E14) weren't wired into the app. They were, and five more rows (E18,
  E24, E25, E26) were stale the same way. The statuses are corrected, the
  summary counts are recounted from the rows, and a test now holds the
  page to forms.yaml's record of what calculates. No code changed: there
  was nothing to wire.
- **How tests get added (26 October 2026):**
  [`adding-a-test.md`](adding-a-test.md) is now the one page for it: what
  "added" means (engine, validation placeholders, card, input screen,
  "What's new" entry, version bump, status, all in one PR), how a backend
  package is chosen with the maintainer, every file a design touches, and
  the queue of what to add next. powerkit has a version number too:
  `engine/DESCRIPTION`, 0.x.y while it is a prototype, 1.0.0 at release.
  **Batch 1 is the five designs the engine already computes but the app
  can't reach** (logistic and Poisson regression, planned contrasts, two
  dependent correlations, the two variance tests); three of them have
  cards that tell users powerkit can't do what it can.
- **Straight to the list (26 October 2026):** "I know my
  analysis" can skip the four screening questions and show every end point,
  as G\*Power's menu does; the questions are offered on the list as a
  filter instead. The other two routes still screen first, because they
  need the answers to route at all. The screening's protection is lost on
  that path by design, so the list says nothing was screened out and each
  card still states what its test assumes
  ([`decisions.md`](decisions.md), 26 October 2026).
- **Variance tests (engine only, 25 October 2026):** the two tests
  G\*Power computes in its sections 26 and 15 — one group's variance
  against a fixed value (chi-square) and two groups' variances (F) — run
  through Spower's `p_var.test()`. They are simulated, because no package
  powerkit builds on has a formula for them
  ([`conventions.md`](conventions.md), Known difference 4), so there is no
  exact method for them. An allocation ratio is refused for the two-group
  test while Spower can't draw unequal groups
  ([`upstream-questions.md`](upstream-questions.md), which also reports
  two more faults found in `p_var.test()`). Not wired into the app, and
  the published values in the validation file are still to be
  transcribed; whether these two reach the app is part of the open scope
  question G1 ([`judgement-calls.md`](judgement-calls.md)).
- **Fix (25 October 2026):** the nightly validation job runs again. It had
  failed on every run since it was set up on 12 October (13 runs), before
  a single test ran: testthat's JUnit reporter needs xml2, which
  `renv.lock` has never carried. Fixing that uncovered a second fault in
  the same step, which would have failed the job at the *end* of a full
  run: the report's path was relative, and `test_local()` runs from
  `engine/tests/testthat`. So there is no nightly result yet for any
  commit; the first one will come from the next scheduled run.
- **Fix (22 October 2026):** the shared tabs are built once at start-up,
  not per visitor (a regression from the maintainer's view in #87).
- **Input screen in sections** (in review, 22 October 2026): goal first,
  fields shown only for the goals that need them, the effect size with
  its source, default settings folded into one line that shows their
  values ([`decisions.md`](decisions.md)).
- **Progress steps and shorter cards** (in review, 22 October 2026).
- **Shorter labels and problems next to their fields** (in review,
  22 October 2026).
- **Labs menu and planning from the notes** (in review, 22 October 2026).
- **Help with the effect size** (in review, 22 October 2026): honest
  routes to a defensible number and an "I don't know" button; still to
  come, entering the difference in raw units (an engine change) and
  worked examples.
- **Browser Back and Forward** (in review, 22 October 2026): each screen
  or tab change is a browser history entry.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
  What to work on is [`next.md`](next.md).

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

**The ordered queue is [`next.md`](next.md)** — twenty items, Ready ones
first. What follows is the direction those items serve.


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
   review. Dependent correlations, logistic and Poisson regression and
   contrasts: engine in review (25 October 2026). Left for later:
   Wilcoxon and other rank tests (need a statistician's view).
   Validation later.
8. Before release: published values, independent
   checks for moderated mediation and the Monte Carlo interval with two or
   more mediators, phase 3b (binary X and W), and the methodologist
   collaboration.
