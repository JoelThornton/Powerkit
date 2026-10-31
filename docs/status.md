# Project status

*Last updated: 31 October 2026 (powerkit 0.26.0). This page says where the
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
  **40 cards calculate in the app**: E1-E9, E15, E18-E29, E31, E34, E36,
  E37, E47-E57 and E59-E61 (`forms.yaml`'s `calculates`); E61, a planned
  meta-analysis (metapower's z test, or the Hartung-Knapp test by
  default, simulated with metafor), since 31 October 2026. **Nine are simulated with a
  preview first**, then a full run in the app or an R script: E10-E14 and
  E40 (mediation and moderated mediation, power4mome), E16 (mediation
  with a yes/no X), E33 (participants and items, simr) and E62 (a
  two-level model with predictors at each level and their cross-level
  interaction, simr; reached from the new question C1 for people within
  groups, 31 October 2026; agrees with a separately written simulation,
  published value and statistician review to come). No template
  is engine-only.
- **Finding an analysis:** "I know my analysis" lists every analysis in
  closed groups by family with a search box (31 October 2026); "Help me
  choose" asks the screening questions first; the search also knows other
  names (`tree.yaml`, `search_words`); an "Explanations" switch, on by
  default, shows technical names first and hides the hints when off.
- **Results** state their spec hash, seed, backend, R and package
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
  G\*Power does; moderation
  takes the R-squared change; safeguard power for an effect from one
  study. MANOVA (E59, one or two factors) and one-sample Hotelling's T-squared (E60) take
  means, SDs and a correlation, and their cards say why.
- **Validation.** Most designs are checked against the package each one
  calls, plus Type I error; independent checks exist for the basic tests
  (G\*Power screenshots), mediation (pwrss and simsem) and the two-group
  MANOVA (pwrss's exact F). 17 published examples are transcribed and
  pass; the rest keep `TODO_PUBLISHED_VALUE` for the maintainer. Six cards
  are marked validated; eight still say "validation in progress"
  ([`next.md`](next.md), item 13). Validation runs per design before a PR
  merges, every night the engine changed and in full every Sunday
  (`scripts/validation-plan.R`, `nightly-validation.yaml`). The nights of
  29 and 30 October failed on two unit tests that compared runs on
  different numbers of cores; fixed in 0.24.0's conversion PR (#181).
- **Rank tests** are simulated for normal, skewed or heavy-tailed scores:
  the Wilcoxon, Mann-Whitney and Kruskal-Wallis tests, Friedman's test (E54,
  31 October 2026) and Spearman's and Kendall's correlations (E4).
- **Pairwise comparisons** after a one-way ANOVA (E18, E54): the power of a
  chosen pair, adjusted by Holm's (the default, Departure 17) or
  Bonferroni's method, simulated with Superpower (31 October 2026).
- **Experimental:** whole-study simulation on the guided plan, for a
  measured predictor or two groups (power4mome; waiting for a statistician's check, `next.md`, item 11);
  joint power in a study plan when every analysis compares the same
  randomised groups on different outcomes (PUMP); Labs (pre-replication
  notes, the methods map, the effect size converter and the power
  visualiser for the two-group t-test).
- **Waiting on others:** moderated mediation with W on the direct path
  (E38, model 8) on an upstream question to manymome (`next.md`,
  item 10); E17 on questions for power4mome (item 12); Spower's faults
  are ready to raise upstream (`docs/upstream/spower-var-test.R`).

## Known gaps on cards that run

- The mixed and two-factor within designs assume one SD and one
  correlation (sphericity), and mixed designs with unequal groups reach
  the safety net (`next.md`, item 15); the one-way repeated-measures card
  takes unequal ones and a correction.
- Simulated data sets are missing for R², logistic and Poisson regression
  with other predictors, the two-way ANCOVA, the three-way interaction,
  multisite and yes/no cluster outcomes, SEM and McNemar's test (item 9).
- MANOVA with three or more groups is simulated (no formula in a package
  or the G\*Power manual); two groups and one group against fixed values
  are exact since 31 October 2026 (Hotelling's T-squared).
- SEM has no test of close fit, nor invariance with several factors,
  groups or occasions (item 14).
- Technical details (df, critical value, noncentrality) are missing for
  semPower, powertools, TOSTER and bfpwr designs (item 25).

## Working environment

- **CI:** the engine's R CMD check (test files four at a time) on every
  push; the app's suite on every pull request and on main, as two jobs
  side by side (`test-results.R`, and the rest); the Windows and macOS
  install test when the launcher or lockfile changes, and weekly. All run
  in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image
  and writes the shell settings R needs to `~/.powerkit-env.sh`, sourced
  from the first line of `~/.bashrc`. devtools and roxygen2 aren't in the
  image; `CLAUDE.md` gives the commands to use instead.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
