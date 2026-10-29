# Project status

*Last updated: 29 October 2026. This page says where the project is now
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
  mediation (pwrss and simsem). Published values (27 October 2026): 17
  published examples are transcribed in full and pass locally (the
  independent and paired t-tests, both dependent-correlation tests, the
  three planned contrasts, the four generic tests, logistic regression
  with a normal and with a yes/no predictor, the Poisson swimmers example and the three
  variance tests). Two InteractionPoweR tutorial examples are complete
  and run in the interactions chunk. The rest keep
  `TODO_PUBLISHED_VALUE` placeholders, partly filled where a value is
  still to be checked. Six cards are now marked validated on the
  strength of these runs (planned contrasts, logistic regression, the
  generic tests, two dependent correlations and the two variance tests);
  eight still say "validation in progress" (`next.md`, item 4). Wave 2 (one-way
  ANOVA, R², one proportion, McNemar, Welch by formula) matches G\*Power
  in the engine's tests; it isn't in the full validation run yet.
- **Batch 1: designs the engine computes, being wired into the app**
  ([`next.md`](next.md), batch 1; version 0.6.0). Each runs by
  formula through pwrss unless stated, has validation placeholders for the
  G\*Power manual's examples, and reaches the app in its own PR:
  - **Logistic regression** (E27; pwrss's Wald z test of one predictor, a
    score or a yes/no group, with other predictors through an R-squared):
    **in the app** (26 October 2026). Above an R-squared of 0 the result
    screen states Known difference 3, which G\*Power itself has to settle.
  - **Poisson regression** (E28; one predictor of a count outcome, over a
    mean exposure): card and input screen **in review** (26 October 2026).
    It reproduces every number in the manual's section 30 that powerkit
    can compute. Count outcomes now pass the screening questions first:
    only a count measured once per person reaches it.
  - **Planned comparisons (contrasts)** (E19; pwrss's t test of a weighted
    combination of one factor's means, trend tests included): card and
    input screen **in review** (26 October 2026). Superpower's emmeans
    route agrees with it (a unit test).
  - **Two dependent correlations** (one group, with or without a shared
    variable; pwrss's Steiger test, unpooled as G\*Power, Departure 12):
    their own card (E51) and input screen **in review** (26 October 2026).
  - **The two variance tests** (one group's variance against a value, two
    groups' variances; simulated with Spower's `p_var.test()`, Known
    difference 4; an allocation ratio is refused while Spower can't draw
    unequal groups, [`upstream-questions.md`](upstream-questions.md)):
    their own cards (E52, E53), input screens and a design-finder
    question ("Whose spread of scores are you comparing?") **in review**
    (26 October 2026).
- **More tests by formula already in the app** (pwrss): Fisher's exact
  test (E5's test version), ANCOVA with one factor or, from 0.17.0
  (28 October 2026), two crossed factors (E23), chi-square goodness of
  fit (E48, its own card), two independent correlations (E49) and the
  generic t, F, chi-square and z tests (E50, only from "I know my
  analysis"; no sample size). pwrss's search for the noncentrality is
  wrong for a t test with few degrees of freedom (3 to about 12); the
  engine checks the answer and refuses a wrong one.
- **G\*Power manual checks:** two independent correlations (A6, section
  27) and the generic t test (A47, section 25) reproduce the manual. The
  G\*Power entries in [`conventions.md`](conventions.md) are filled in for
  the manual's sections 3 to 6, 10, 11, 13, 14 and 19 to 21; the manual has
  no section on repeated-measures ANOVA, the two-proportions z test, the
  chi-square test of independence, ANCOVA or mediation, so those need
  G\*Power itself. Next there: the pwrss column, from the installed
  sources.
- **Clustered designs (27 October 2026, 0.12.0):** cluster-randomised
  trials (whole groups assigned to two conditions) and multisite trials
  (people randomised within each group), with a score outcome
  (powertools' `crt.parallel.cont()` and `multisite.cont()`, with the
  design effect and the effective sample size on the result screen) or,
  from 0.16.0 (28 October 2026), a yes/no outcome (`crt.parallel.bin()`
  and `multisite.bin()`, groups of equal size, no smallest detectable
  effect), all by formula on the "People nested in groups" card (E34).
  Also in 0.16.0, group treatment trials (people randomised one by one,
  only one condition delivered in groups: powertools' `irgtt.cont()` and
  `irgtt.bin()`; the smallest detectable d is found from the t-based
  power, not powertools' normal approximation, `conventions.md`), and an
  optional baseline score (one covariate) for a score outcome in the
  first two designs. Validation in progress (published examples to
  choose and transcribe); three questions for powertools in
  `upstream-questions.md`. Next: simulated multilevel models wait for a
  package decision (`next.md`, item 2).
- **Structural equation models (27 to 29 October 2026, 0.13.0 and
  0.21.0):** on the latent variables card (E37), by formula with
  semPower: model fit (the chi-square test of exact fit by RMSEA, for a
  CFA described by its items and factors or any model by its df) and,
  from 0.21.0, measurement invariance of one factor across two groups
  (metric or scalar, `semPower.powerMI()`; over two occasions from
  0.22.0, `semPower.powerLI()`), the correlation between two
  factors (`semPower.powerCFA()`) and a latent slope
  (`semPower.powerRegression()`), each by the chi-square difference test.
  Validation in progress (published examples to choose and transcribe).
  Not yet: invariance with several factors, groups or occasions, and the
  test of close fit (left out for now, 29 October 2026).
- **Repeated measures and larger factorial designs (27 to 28 October
  2026, 0.14.0 to 0.19.0):** the one-way repeated-measures ANOVA (the same
  people in three or more conditions, E54), the mixed ANOVA beyond 2 x 2
  (groups of different people each measured at three or more timepoints
  or in several conditions, E55), the two-factor within-participants
  ANOVA (everyone in every combination, 2 x 2 or larger, E20) and the
  two-factor between-participants ANOVA beyond 2 x 2 (E21) and, from
  0.19.0, the three-factor ANOVA with any mix of between and within
  factors (E56) run in the app by Superpower's exact data set, with one SD and, for repeated measures,
  one correlation, so sphericity holds; from 0.21.0 the MANOVA approach's
  power (Pillai's trace, no sphericity assumed) is shown beside the
  univariate F when the effect involves a within factor with three or
  more levels. Validation in progress (published examples to choose and
  transcribe). Next: sphericity corrections and unequal SDs or
  correlations (`next.md`, item 6); four or more factors go to the safety
  net. Welch's F (unequal SDs) is a test version on the one-way ANOVA
  card from 0.21.0, simulated with Spower.
- **Rank correlations and the Pitman-Morgan test (29 October 2026,
  0.22.0):** Spearman's rho and Kendall's tau are a test version on the
  correlation card (Spower's `p_r(method =)`, normal scores), and the
  Pitman-Morgan test of two paired variances has its own card (E57),
  simulated with Spower's `p_r()` on the sum and difference of the paired
  scores. Validation in progress.
- **Rank tests (28 October 2026, 0.18.0):** the Wilcoxon signed-rank
  test (one sample, or pairs), the Mann-Whitney test and the
  Kruskal-Wallis test are a test version on the one-sample, paired,
  two-group and one-way ANOVA cards, simulated with Spower for the shape
  of scores the user expects (normal, skewed or heavy-tailed; the
  signed-rank test, which assumes symmetry, offers normal and
  heavy-tailed). Known difference 5: G\*Power adjusts the t-test by an
  efficiency factor instead; its values are still to transcribe
  (`test-validation-rank-tests.R`). Friedman's test still carries the
  "only approximates" note (`next.md`, item 9).
- **Bayes factor t-tests (28 October 2026, 0.20.0):** the one-sample,
  paired and two-group t-test cards offer a Bayes factor t-test as a test
  version, by bfpwr's closed form (Pawel & Held, 2025): the chance the
  Bayes factor passes a threshold (BF10 = 10 by default, Cauchy prior
  scale 0.707), and, with no effect, the chance of strong evidence for
  none and of misleading evidence. Fixed N, equal groups. Awaiting the
  maintainer: Departure 15 (plan for exactly the effect entered, not
  bfpwr's spread-out default). Known difference 6: bfpwr is slightly low
  in small samples. Sequential designs (BFDA) and other designs later.
- **Housekeeping (29 October 2026, 0.20.1):** the README, the package
  description and `CITATION.cff` name every backend and design family
  that runs; `_dependencies.R` declares every package the engine imports
  (a test now checks it); the app says how to get the engine when it is
  missing; names of variables and levels are optional, with neutral
  defaults. No change to any result.
- **Safeguard power (27 October 2026, 0.9.0):** for an effect size from
  one previous study or pilot, the one-sample, paired and independent
  t-tests and the correlation can plan with the lower bound of a 60% (or
  90%) confidence interval around it, worked out by psych (Perugini,
  Gallucci & Costantini, 2014). Not yet for other designs.
- **Equivalence tests (27 and 29 October 2026, 0.10.0 and 0.21.0):** the
  two one-sided tests (TOST) for two groups, paired data and one sample
  run in the app through TOSTER's exact `power_t_TOST()` (E36), with the
  bound and the expected difference as Cohen's d or in the measure's own
  units; from 0.21.0 also a correlation (`power_z_cor()`) and two
  proportions (`power_twoprop()`, equal groups); from 0.22.0
  non-inferiority for two groups, paired data, one sample and two
  proportions (pwrss's one-sided tests against a margin). Validation in
  progress: published examples are placeholders.
- **Whole-study simulation (27 October 2026, 0.10.0, experimental):** on
  the guided plan, one population model for the whole study, entered
  once as standardised paths; every planned analysis (correlation,
  interaction, mediation with one or two mediators, moderated mediation)
  is run on the same power4mome simulations, giving each analysis's power
  and the joint power for the claim, and the values each analysis's own
  screen would need (Departure 13). The app runs a quick look (200
  simulated studies); the full run and the sample size search (0.11.0)
  run on the user's computer from an R script
  (`export_whole_study_script()`). Waiting for a
  statistician's check (`next.md`, item 1); the method note for it is
  `docs/whole-study-method.md`. Since 0.10.1 it is the plan's first
  step when it covers the plan, with the separate calculations folded
  below. Next: a quick run in the app, an R script for the full run, and
  a search for the sample size.
- **App** (`app/routing/`): the question tree, cards and input screens for
  every end point. E1–E9, one-way ANOVA (E18), one-way repeated measures (E54), mixed designs beyond 2 x 2 (E55), two-factor within and larger between designs (E20, E21), ANCOVA (E23), multiple
  regression (E24), one proportion (E25), McNemar (E26), goodness of fit
  (E48), two correlations (E49), the generic tests (E50) and
  clustered designs (E34) and model fit for CFA and SEM (E37) calculate in
  the app; E10–E14 give a rough preview, then a full run in the app or an
  R script. Results save as a project file and reopen. It is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud> and updates
  itself from main; [`run-it-yourself.md`](run-it-yourself.md) is for
  running it on one's own computer. Each tab has its own link
  (`?page=labs` and so on); Connect Cloud's frame keeps the address bar
  from showing it, so the top bar has a "Share this page" button. What the app
  now does, all merged:
  - larger text on large screens with no sideways scrolling when zoomed,
    the page moving to the result after "Check my answers", and a result
    screen ordered answer, exploring, save and share, then how it was
    calculated, with a shorter write-up for the paper;
  - the input screen in sections (goal first, fields only for the goals
    that need them, default settings folded into one line), four progress
    steps, shorter cards and labels, and problems shown next to their
    fields;
  - the direction asked first and not pre-filled; a claim needing several
    tests raises each one's target power; changing alpha or choosing a
    one-sided test asks for a reason, which goes into the write-up;
  - help with the effect size (honest routes to a defensible number and an
    "I don't know" button; entering the difference in raw units is
    queued in [`next.md`](next.md));
  - "I know my analysis" can skip the four screening questions and show
    every end point, as G\*Power's menu does, with the questions offered as
    a filter ([`decisions.md`](decisions.md), 26 October 2026);
  - the first screen asks only how to start; whether the sample size is
    fixed and how the conclusion rests on several tests are asked on the
    input screen (26 October 2026);
  - browser Back and Forward move between screens;
  - a card-based layout: Back and Start again at the top of each screen,
    the next step pinned to the bottom of the window, choices and results
    as cards (26 October 2026);
  - About and "What's new" tabs (`app/routing/whats-new.yaml`); a Feedback
    tab whose Send button stores the message in the `powerkit_feedback`
    table of the goal-machine Supabase project (read it in Supabase's table
    editor), with a GitHub issue and copying as alternatives; undecided settings only in the maintainer's
    view (`?view=maintainer`);
  - in "Plan my whole study", each analysis on the plan that powerkit
    calculates opens its input screen, carrying the plan's claim and its
    number of main analyses; the combined sample size and the consistency
    check between analyses are still "Coming soon" and queued in
    [`next.md`](next.md);
  - Labs (experimental): a list of tools, and pre-replication notes that
    can feed a plan without losing work;
  - at most two long calculations at once across all visitors
    (`forms.yaml`, `background_limit`), and the shared tabs built once at
    start-up.
- **Decisions recorded 22 October 2026:** eleven settings that were marked
  undecided but already built now record their value; four more change the
  app: observed power allowed with a warning (spec type
  `own_study_result`), the rank-test label, named tools on "not covered"
  cards, and two parallel mediators only ([`decisions.md`](decisions.md)).
- **Candidates recorded (25 October 2026):** powerMediation for B14,
  semPower for B17 and DescTools for B27's test, all **not checked**
  against their own help files (CRAN wasn't reachable when they were
  recorded); nothing is built on them.
- **CI (26 October 2026):** the test workflows run in a prebuilt image
  with R and the locked packages installed (rebuilt only when `renv.lock`
  changes), and set `NOT_CRAN` themselves, so the app's calculation tests
  run in CI ([`decisions.md`](decisions.md)).
- **Whole-study plan (26 October 2026, 0.7.0):** the plan gives the
  combined sample size (the largest N among the main analyses, named,
  from the calculations made from the plan) and asks for shared values
  once: an input two analyses both ask for fills the second's input
  screen. Whole-study simulation is queued ([`next.md`](next.md), item 1)
  and needs a statistician's check.
- **Effect in the measure's own units (27 October 2026, 0.8.0):** the
  three t-tests take the means and SD instead of Cohen's d (or d_z); the
  engine works out the standardised effect, the result and write-up show
  it, and a smallest detectable effect is also given in the measure's
  units.
- **Three effects side by side (27 October 2026, 0.9.0):** on the
  result screen for the t-tests and the correlation, a conservative and an
  optimistic effect the user enters are drawn with the plan's effect, with
  the N each needs.
- **Labs map of the methods (27 October 2026, 0.9.0):** an interactive
  "cosmos" (stars for research questions, planets for analyses) generated from the design finder's questions (Cytoscape.js,
  bundled), with filters, search, two views and each analysis's
  card. Charts on each analysis's page and a
  sourced reading list are not built yet.
- **Repository checks:** `test-repo-consistency.R` holds the docs, scripts
  and workflows together: every validation file in a chunk of
  run-validation.R with a time estimate and a place in the full-validation
  workflow, every test conventions.md names existing, coverage-roadmap.md's
  summary counts matching its rows and its wired statuses matching
  forms.yaml, the version agreeing across `engine/DESCRIPTION`,
  `CITATION.cff` and the About page, and every engine template named by a
  card or listed in forms.yaml's `engine_only`.
- **How tests get added:** [`adding-a-test.md`](adding-a-test.md) is the one
  page: what "added" means (engine, validation placeholders, card, input
  screen, "What's new" entry, version bump, status, in one PR), how a
  backend package is chosen with the maintainer, and every file a design
  touches. powerkit's version is `engine/DESCRIPTION`'s, major.minor.patch:
  fixes raise the last number, each batch of features the middle one (by
  one, however many pull requests), a big shift the first.
- **Nightly validation:** fixed on 25 October 2026 (testthat's JUnit
  reporter needed xml2, missing from `renv.lock`, and the report's path
  was relative); it had failed on every run since 12 October.
- **R in cloud sessions:** `scripts/setup-cloud-session.sh`, run as the
  cloud environment's setup script, copies R and every locked package out
  of the CI image (about a minute; the environment then caches it) when
  the network allows `pkg-containers.githubusercontent.com`. Otherwise it
  exits without installing, and a session builds R 4.3 from source with
  `--build-from-source` (20-30 minutes, too long for a setup script).
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
  the write-up was merged the same day. The plain reading counts out of
  100 unless the power is a whole number of tenths (0.14.1), so 95% is
  never shown as "10 in 10". Analyses are named by their standard names,
  not PROCESS model numbers, in the list and the methods paragraph.
  Screens trimmed (0.14.2): the goal of showing there's no meaningful
  effect is asked once, on the aim screen; repeated wording is gone from
  cards and input screens; G\*Power is named only where its answer
  differs, with departures that don't change the answer folded under
  "How it was calculated" (`decisions.md`, 28 October 2026).

## What's next

**The ordered queue is [`next.md`](next.md)** — about twenty items, Ready ones
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
   `scripts/deploy-online.R`. A new app process now shows its first page
   in about 2 seconds instead of about 4.5 (measured on a cloud machine;
   0.16.1); hosting stays on Connect Cloud for now (browser-only hosting is ruled out: several backends have no WebAssembly build).
   Running it on your own computer: the Mac
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
   pre-replication notes (Karhulahti et al., 2025), is merged (plan:
   the "Powerkit Labs: plan" Claude Doc). Later Labs tools, such as the
   design-upgrade comparator, wait for a statistician.
7. More tests by formula from the packages powerkit already uses (the
   maintainer's direction, 18 October 2026): the last five are batch 1
   above. Left for later:
   Wilcoxon and other rank tests (need a statistician's view).
   Validation later.
8. Before release: published values, independent
   checks for moderated mediation and the Monte Carlo interval with two or
   more mediators, phase 3b (binary X and W), and the methodologist
   collaboration.
