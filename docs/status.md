# Project status

*Last updated: 1 November 2026 (powerkit 0.28.1). This page says where the
project is now; keep it short and replace old entries rather than adding
to them. What to do next is [`next.md`](next.md). History is in git,
[`engine/NEWS.md`](../engine/NEWS.md) and
[`archive/status-history.md`](archive/status-history.md), which also holds
this page as it stood on 30 October 2026.*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md). For the working rules, see
`CLAUDE.md` and [`handover.md`](handover.md).

## Where things are

- **The app** (`app/routing/`) is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud> and updates
  itself from main (Posit Connect Cloud, through
  `app/routing/manifest.json`, which a workflow keeps current);
  [`run-it-yourself.md`](run-it-yourself.md) is for running it locally.
  Parts of screens that repeat (the list of analyses, an input screen's
  groups of fields) are kept as HTML once built (`cached_html()` in
  `R/ui.R`), so a click shows the next screen in about 40 ms on a laptop.
  **44 cards calculate in the app**: E1-E9, E15, E18-E29, E31, E34, E36,
  E37, E44, E46, E47-E57, E59-E61, E64 and E66 (`forms.yaml`'s `calculates`);
  E44, the actor-partner model for pairs (with joint power for actor and partner
  effects tested together), and E46, precision planning
  (below), since 1 November 2026; E64
  and E66, the Jonckheere-Terpstra and Cochran-Armitage trend tests
  (simulated with Spower; one- or two-sided, equal or unequal groups),
  since 1 November 2026; E61, a planned
  meta-analysis (metapower's z test, or the Hartung-Knapp test by
  default, simulated with metafor), since 31 October 2026, with subgroups
  of studies, several effects per study (POMADE), a moderator that is a
  score and the test of heterogeneity (both simulated with metafor) since
  1 November. Bayes factor versions: the three t-tests
  and, since 1 November 2026, the test of one proportion (E25; bfpwr,
  JASP's prior and one-sided test by default) and the correlation (E4;
  BayesFactor, JASP's Bayes factor and prior width by default) and two proportions (E5; BayesFactor's contingency table Bayes factor, JASP's default), and since 2 November the one-way ANOVA (E18; BayesFactor's ANOVA Bayes factor with JASP's r scale of 0.5, exact). **Fourteen are simulated with a
  preview first**, then a full run in the app or an R script: E10-E14,
  E17 (a yes/no X or W), E38 (W on both links or the direct path, both
  1 November 2026) and E40 (with a yes/no X or W since 2 November)
  (mediation and moderated mediation, power4mome), E16 (mediation
  with a yes/no X), E33 (participants and items, simr; the conditions within or, since 31 October 2026, between participants), E63 (the same with three or more conditions, 31 October 2026; both with a score or, since 1 November, a yes/no answer on each trial), E68 (three levels, people in groups in larger groups, 1 November 2026), E67 (a predictor measured on each item, 1 November 2026) and E62 (a
  two-level model with predictors at each level and their cross-level
  interaction, simr; reached from the new question C1 for people within
  groups, 31 October 2026; agrees with a separately written simulation,
  published value and statistician review to come; since 1 November 2026
  also with the groups in larger groups, predictors at all three levels);
  E62 and E68 with a score or, since 1 November 2026, a yes/no outcome. No template
  is engine-only.
- **Finding an analysis:** "I know my analysis" lists every analysis in
  closed groups by family with a search box (31 October 2026), common
  starting points and status labels, and keeps the search when you come
  back from a card (1 November 2026); the input screen counts the needed
  answers still empty, in its bottom bar (1 November 2026); the methods
  map in Labs opens full screen: the families as regions, and each
  analysis in focus with the designs that lead to it, the ways to change
  it, its usual test and a "Plan this study" button (`methods-map.yaml`;
  the test labels and connections await the statistician's review;
  1 November 2026); "Help me
  choose" asks the screening questions first; the search also knows other
  names (`tree.yaml`, `search_words`); an "Explanations" switch, on by
  default, shows technical names first and hides the hints when off.
- **About and Updates** (1 November 2026): About says how powerkit
  works in three steps and lists every analysis that calculates by family,
  each opening its card; Updates (once "What's new", between Labs and
  Feedback) is a timeline of titles that open, with Full details, a search
  and the changes since your last visit marked. Every tab shares one
  column.
- **Start screen, Labs, Feedback** (1 November 2026): three short ways
  to start with "Recently opened" for returning visitors; Labs as a grid;
  Feedback in one card; About's families fold on a phone.
- **Precision, study plan and whole-study screens** (1 November 2026)
  follow the result layout: section links, one large figure, write-up
  before downloads. The study plan names analyses in plain words, puts
  the largest N first and can remove one; precision results can join it.
- **Questions and cards** (1 November 2026): each question shows its
  number and takes number keys; a card opens with how it calculates, the
  package and its checks, and lists what you'll need.
- **Results** open with the answer as one large figure and what it
  assumes, then "How sure can you be?" (the effect slider and cautious and
  hopeful guesses), then the write-up with Copy buttons and the downloads
  (1 November 2026). They state their spec hash, seed, backend, R and package
  versions; save as a project file or a study plan and reopen (a project
  saved from 0.26.0 shows its saved result without running it again); export an
  R script that reproduces them with the backend alone, citations, a
  methods paragraph and, for most designs, a simulated data set. A saved
  simulation reproduces on the number of cores it ran on (0.24.1).
- **Effect sizes researchers have:** the t-tests and the correlation take
  a published t, F, r, d or odds ratio (t and F into d by psych's `t2d()`,
  with the group sizes when given; the rest by effectsize;
  `conventions.md`, "Effect-size conversion"); between-participants
  (including three factors), repeated-measures and mixed ANOVA and the
  ANCOVAs take partial eta-squared and the chi-square tests Cohen's w, as
  G\*Power does; the two-group t-test takes a point-biserial r (G\*Power's
  point-biserial model, 0.27.0); moderation
  takes the R-squared change; safeguard power for an effect from one
  study. MANOVA (E59, one or two factors) and one-sample Hotelling's T-squared (E60) take
  means, SDs and a correlation, and their cards say why.
- **Validation.** Most designs are checked against the package each one
  calls, plus Type I error; independent checks exist for the basic tests
  (G\*Power screenshots), mediation (pwrss and simsem) and the two-group
  MANOVA (pwrss's exact F). 17 published examples are transcribed and
  pass; the rest keep `TODO_PUBLISHED_VALUE` for the maintainer. Six cards
  are marked validated; eight still say "validation in progress"
  ([`next.md`](next.md), "Waiting on the maintainer"). Validation runs per design before a PR
  merges, every night the engine changed and in full every Sunday
  (`scripts/validation-plan.R`, `nightly-validation.yaml`). The nights of
  29 and 30 October failed on two unit tests that compared runs on
  different numbers of cores; fixed in 0.24.0's conversion PR (#181).
- **The critical effect size** (the smallest observed effect that would be
  significant at the n analysed; Perugini et al., 2025) is on the results
  and in the methods paragraph for the t-tests and the correlation (1
  November 2026).
- **Minimum-effect tests** (an effect larger than a smallest effect of
  interest) are a test version on the one-sample, paired and two-group
  t-tests, by pwrss (0.27.0; Known difference 10).
- **A justified alpha** (the significance level that minimises or
  balances the weighted errors at a fixed N, JustifyAlpha's
  `optimal_alpha()` on pwr's power) is a goal on the one-sample, paired and
  two-group t-tests and the correlation (0.27.0; Known difference 11, the
  balanced version being G\*Power's compromise analysis).
- **Precision planning** (E46, 1 November 2026): the sample size for a
  confidence-interval width, or the width expected at a given n, rather
  than power. Cohen's d between two groups, d_z and a standardised mean
  by MBESS (`ss.aipe.smd()`, `ss.aipe.sm()`, with optional assurance);
  a correlation (Pearson's, Spearman's or Kendall's) and a proportion
  (Wilson's interval by default) by presize; since 1 November 2026 also a
  raw mean difference, an odds ratio and an ICC (presize) and a
  standardised regression coefficient (MBESS's `ss.aipe.reg.coef()`, which
  needs gsl). MBESS brings OpenMx with it, the heaviest new dependency.
  E33 can also plan the number of items for a fixed number of
  participants (1 November 2026).
- **Rank tests** are simulated for normal, skewed or heavy-tailed scores:
  the Wilcoxon, Mann-Whitney and Kruskal-Wallis tests, Friedman's test (E54,
  31 October 2026) and Spearman's and Kendall's correlations (E4).
- **Pairwise comparisons** after a one-way ANOVA (E18, E54): the power of a
  chosen pair, adjusted by Holm's (the default, Departure 17) or
  Bonferroni's method, simulated with Superpower (31 October 2026).
- **Experimental:** whole-study simulation on the guided plan, for a
  measured predictor or two groups, people measured once or twice (each analysis adjusted for the first measurement, including two mediators and moderated mediation of one link; power4mome; waiting for a statistician's check, `next.md`, "Waiting on the maintainer");
  joint power in a study plan when every analysis compares the same
  randomised groups on different outcomes (PUMP); Labs (pre-replication
  notes, the methods map, the effect size converter, the power
  visualiser for the two-group t-test and, since 0.27.0, the correlation
  (since 0.28.0 also the paired t-test, the one-way ANOVA, two proportions, a
  chi-square test and a regression's R-squared, and one-sided t-tests),
  and Bayesian planning for the Bayes factor t-tests from bfpwr, at a
  fixed N or, since 0.28.0, sequential: checked as the data come in,
  stopping when the evidence is strong).
- **Moderated mediation with W on both links or the direct path** (E38,
  PROCESS models 8, 58 and 59, 1 November 2026): the difference between
  the conditional indirect effects at two values of W, simulated with
  power4mome and powerkit's test (manymome's `cond_indirect_diff()`); a
  preview in the app, the full run from an R script. A yes/no X or W in
  models 7 and 14 (E17, 1 November 2026) the same way, drawn by
  power4mome's `rbinary_rs()` and checked against a separately written
  simulation; with a yes/no X and no moderation its Type I error is about
  6.7%, against 5.3% for the separate simulation, stated on the results
  screen until power4mome answers (`upstream-questions.md`).
- **Waiting on others:** Spower's faults are ready to raise upstream
  (`docs/upstream/spower-var-test.R`).

## Known gaps on cards that run

- Mixed designs with unequal groups are simulated with Spower and afex
  (1 November 2026); their validation chunk (`anova_mixed_unequal`) has
  not had a full run on GitHub yet. Every repeated-measures card takes an
  SD per cell and correlations per pair, with a sphericity correction
  where one applies.
- Simulated data sets are missing for the three-way regression
  interaction (no package generates its data from the correlations it
  takes), the meta-analysis, SEM, McNemar's test and the generic tests;
  every other card that runs has one (1 November 2026).
- MANOVA with three or more groups is simulated (no formula in a package
  or the G\*Power manual); two groups and one group against fixed values
  are exact since 31 October 2026 (Hotelling's T-squared).
- SEM has no test of close fit, nor invariance with several factors,
  groups or occasions (`next.md`, "SEM").
- Technical details (df, critical value, noncentrality) are given for
  every exact design whose package reports them, SEM and the correlation
  included since 1 November 2026; TOSTER and powertools return none
  (powertools: `upstream-questions.md`), and Bayes factor designs have
  none to give.

## Working environment

- **CI:** the engine's R CMD check on every push that changes the engine,
  `renv.lock` or the CI setup (skipped otherwise), with the engine's
  tests beside it in three parts on separate runners (test files four at
  a time in each); the app's suite on every pull request and on main, as two jobs
  side by side (`test-results.R`, and the rest); the Windows and macOS
  install test when the launcher or lockfile changes, and weekly. All run
  in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image
  and writes the shell settings R needs to `~/.powerkit-env.sh`, sourced
  from the first line of `~/.bashrc`. devtools and roxygen2 aren't in the
  image; `CLAUDE.md` gives the commands to use instead.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
