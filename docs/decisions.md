# Decisions log

Short records of decisions that are not obvious from the code. Newest last.
Full validation runs are recorded in `docs/validation-log.md`.

## Before 1 November 2026

Decisions from 12 to 31 October 2026 are in
[`archive/decisions-2026-10.md`](archive/decisions-2026-10.md), unchanged.
Search there for a design, package or date; a reference elsewhere to
`decisions.md` with a date in October 2026 means that file. Its entries:

- 2026-10-12 · Phases 0–1 (set-up, specification and tests)
- 2026-10-12 · Published values for the 2x2 validation tests
- 2026-10-12 · Phase 2: answers to open questions
- 2026-10-12 · Phase 2: 2x2 designs via Superpower
- 2026-10-12 · Phase 2 follow-up: maintainer decisions
- 2026-10-13 · Phase 3: basic tests, regression interactions, mediation
- 2026-10-13 · Phase 3: maintainer decisions
- 2026-10-13 · Regression interactions: analytic method, before any switch
- 2026-10-13 · Regression interactions: grid results; simulation stays the default
- 2026-10-13 · Bug in scripts/run-validation.R: loop-generated tests (fixed)
- 2026-10-13 · Housekeeping: published ranges, rerunning skipped tests, sources
- 2026-10-15 · Upstream reports fixed; upstream watch; validation log
- 2026-10-15 · Running power4mome simulations in batches
- 2026-10-15 · full-validation workflow: first run failed in setup (fixed)
- 2026-10-15 · Maintainer decisions: binary X and W phase
- 2026-10-15 · Published values: InteractionPoweR notes (comments only)
- 2026-10-15 · The prototype app (PR #4) stays a draft
- 2026-10-15 · Project goal and coverage matrix
- 2026-10-16 · Phase 4, part 1: script and citation exports
- 2026-10-16 · Maintainer follow-up on PR #20: seeding, validation status, citation rule
- 2026-10-16 · Why power4mome for mediation and moderated mediation
- 2026-10-16 · Routing prototype: maintainer decisions from PRs #21 and #22
- 2026-10-17 · Routing prototype: the two contradictions from PR #24
- 2026-10-17 · Validation reruns, and refs.bib entries verified at their DOI
- 2026-10-17 · CI installs packages from renv.lock
- 2026-10-17 · Who merges PRs
- 2026-10-17 · Spower 0.7: Departure 4 retired
- 2026-10-17 · Basic tests (E1–E6): pwr's exact formula by default
- 2026-10-17 · The maintainer's decisions on G4–G6 and the Spower flag
- 2026-10-17 · E5: G\*Power's z test by `power.prop.test()` (waits for the maintainer's yes)
- 2026-10-17 · E5: unequal groups by pwrss (waits for the maintainer's yes)
- 2026-10-17 · Phase 5, part 2: E10–E14
- 2026-10-17 · Attrition: the number to recruit
- 2026-10-17 · Sources the maintainer checked in full text
- 2026-10-18 · Wave 2: smallest N for exact tests of counts
- 2026-10-18 · The new design
- 2026-10-18 · What the methods paragraph reports (judgement call G4)
- 2026-10-18 · Hosting for testing: Posit Connect Cloud
- 2026-10-19 · Chi-square goodness of fit gets its own card (judgement call 3.7)
- 2026-10-19 · Test direction and "all of several" claims (waits for the maintainer's yes)
- 2026-10-22 · Plain-words banner and "Coming soon" labels (judgement call B14, update)
- 2026-10-22 · Settings that record what is already built
- 2026-10-22 · Observed power, rank-based tests, named tools and parallel mediators
- 2026-10-22 · The input screen: less effort on the mechanics, more on the effect size
- 2026-10-22 · Progress steps and shorter cards
- 2026-10-22 · Shorter labels, help on request, problems in place
- 2026-10-22 · Labs: a list of tools, and planning from the notes without losing work
- 2026-10-22 · Help for people unsure of their effect size
- 2026-10-25 · Two dependent correlations: engine
- 2026-10-25 · Logistic regression: engine
- 2026-10-25 · Poisson regression: engine
- 2026-10-25 · Conventions: the G\*Power entries filled in from the manual
- 2026-10-25 · Planned comparisons (contrasts): engine
- 2026-10-25 · Three candidate packages recorded for rows that had none
- 2026-10-25 · Two of the eight unchecked rows checked against the manual
- 2026-10-25 · The roadmap said six designs weren't wired; they were
- 2026-10-25 · Four consistency tests for the parts no test was watching
- 2026-10-26 · Every design is reachable from the design finder
- 2026-10-26 · The toolbox doesn't decide the method
- 2026-10-26 · Three product ideas from an outside review, recorded not adopted
- 2026-10-26 · "I know my analysis" can skip the screening
- 2026-10-26 · Consistency between analyses in the whole-study plan (open question 12)
- 2026-10-26 · CI runs in a prebuilt image
- 2026-10-26 · The short write-up leaves out the departures pointer
- 2026-10-27 · The Labs methods map: an interactive node graph
- 2026-10-27 · Safeguard power: psych works out the interval
- 2026-10-27 · What each part of the version number means
- 2026-10-27 · Equivalence tests: TOSTER's exact power, three comparisons first
- 2026-10-27 · Whole-study simulation: built as an experimental option, for a statistician's check
- 2026-10-27 · Clustered designs: formulas first (powertools), simulation later
- 2026-10-27 · Structural equation models: semPower, model fit first
- 2026-10-27 · Repeated measures: Superpower's exact route, sphericity assumed
- 2026-10-28 · Mentioning other tools: where the answer differs, and in the details
- 2026-10-28 · Group treatment trials: the smallest detectable d from the t-based power
- 2026-10-28 · Clustered designs: a baseline score asked for at both levels
- 2026-10-28 · Two-factor designs: the same route as the repeated-measures designs
- 2026-10-28 · Two-way ANCOVA: Shieh's method, the effect chosen by pwrss's own contrasts
- 2026-10-28 · Rank tests: simulated with Spower, for a chosen shape of scores
- 2026-10-28 · Three-factor ANOVA: Superpower's exact data set, any mix of factors
- 2026-10-28 · Bayes factor t-tests: bfpwr, in closed form, as a test version
- 2026-10-29 · SEM: measurement invariance, factor correlations and latent slopes on one screen
- 2026-10-29 · Welch's ANOVA, equivalence for correlations and proportions, and the MANOVA approach
- 2026-10-29 · Non-inferiority by pwrss, and invariance over time by semPower
- 2026-10-29 · Unequal group sizes in a 2 x 2 between-participants ANOVA (E22)
- 2026-10-29 · Binary X and W (phase 3b) and E15
- 2026-10-29 · E16: mediation with a yes/no X
- 2026-10-30 · Mixed models: the first design (E33), via simr
- 2026-10-30 · When the validation runs
- 2026-10-30 · Effect-size conversion
- 2026-10-30 · ANOVA from its effect size
- 2026-10-30 · Repeated-measures and mixed ANOVA from its effect size, and the study plan
- 2026-10-30 · Joint power in the study plan, and MANOVA's convention
- 2026-10-31 · Converting t and F by n, MANOVA's inputs, and reproducing on the saved cores
- 2026-10-31 · Ten queue items decided
- 2026-10-31 · Sphericity corrections, and effect sizes as G\*Power takes them
- 2026-10-31 · The meta-analysis card (E61)
- 2026-10-31 · Fixes from a review of 0.25.0, and clearer names (0.26.0)
- 2026-10-31 · Published formulas where no package has one, and better methods by default
- 2026-10-31 · Point-biserial r and minimum-effect tests
- 2026-10-31 · Justified alpha

## 2026-11-01 · Trend tests (E64, E66)

- **Backends:** both simulated with Spower by powerkit's own experiments,
  as decided on 31 October 2026: the Cochran-Armitage test with
  `stats::prop.trend.test()` (new template `proportion_trend`) and the
  Jonckheere-Terpstra test with PMCMRplus's `jonckheereTest()` (a method
  on the one-way between-participants template, beside Kruskal-Wallis).
- **Variants built:** one- and two-sided tests and unequal groups
  (`options > group_ratio`), since dose-response hypotheses are usually
  directional and dose groups are often unequal. A one-sided
  Cochran-Armitage test halves the two-sided p-value of
  `prop.trend.test()` when the observed trend goes the way predicted: its
  statistic is the square of the Cochran-Armitage z, so this is z's
  one-sided p-value, and a test checks it against z written out.
- **Reached from the design finder:** F2a (a steady rise or fall across
  groups in order) leads to the Jonckheere-Terpstra card; Q3's yes/no
  branch (three or more groups in order) to the Cochran-Armitage card.
- **Not built:** an exact (permutation) Jonckheere-Terpstra p-value, which
  matters only for very small groups; PMCMRplus's normal approximation is
  its default.

## 2026-11-01 · Unequal SDs and correlations in the mixed and within designs (E8, E55, E20)

- **Route:** Superpower, as for the one-way repeated-measures card (E54):
  `ANOVA_design()` with an SD per cell and the upper triangle of the whole
  correlation matrix, `ANOVA_exact(correction =)` and
  `ANOVA_power(correction =)`. No new maths in powerkit.
- **What is asked:** the 2 x 2 mixed design, an SD per cell and a
  correlation per group (its one pair of measurements); the larger mixed
  design, an SD per cell and a correlation per pair of the within
  factor's levels, the same in every group (the usual pattern over time;
  a different pattern per group would mean a table of correlations most
  researchers can't supply); the two-factor within design, a correlation
  per pair of cells, as E54 asks per pair of conditions.
- **Correction:** none by default (Superpower's and G\*Power's epsilon of
  1), Greenhouse-Geisser or Huynh-Feldt on request, only where a within
  factor has three or more levels; not a departure. Replaced on 11
  November 2026: Greenhouse-Geisser by default ("Sphericity correction by
  default", Departure 26).
- **Not built:** mixed designs with unequal groups, which Superpower's
  simulation refuses (`next.md`); built since, see "Mixed designs with
  unequal groups" below.


## 2026-11-01 · Bayesian planning in Labs (fixed N)

The first step of `bayes-planning.md`: a Labs tool for the Bayes factor
t-tests at a fixed sample size, `bayes_planning()`, every number from
bfpwr (`ptbf01()`, `powertbf01()`, `tbf01()`; Pawel and Held, 2025).

- **Two priors, chosen apart.** The analysis prior is the Cauchy prior
  the Bayes factor uses (scale 0.707 by default, bfpwr's); the design
  prior is the planner's belief, normal with an SD for uncertainty. The
  tool's default design prior is d = 0.5 give or take 0.15, so that a
  first look shows what uncertainty costs; an SD of 0 gives the card's
  "exactly the effect entered" (Departure 15, unchanged here).
- **No single power figure.** The three outcomes (strong evidence for an
  effect, for no effect, neither) are shown under the belief and with no
  effect, the misleading ones labelled, with the sample size for a chosen
  chance of strong evidence for an effect, the largest BF01 the study can
  give (two-sided only: a one-sided BF01 has no largest value), and the
  chances against the sample size.
- **Small samples.** Below 50 degrees of freedom the tool says that
  bfpwr's normal approximation gives a chance of strong evidence a few
  points lower than simulation (the same difference the Bayes factor
  cards carry, `test-validation-bayes-factor.R` section 4).
- **Sources.** Only bfpwr's own citation is used. The tool avoids the
  term "assurance" and does not cover sequential designs, so no new
  reference was needed; adding Schönbrodt and Wagenmakers (2018) and an
  assurance source to `refs.bib` comes with those steps.

## 2026-11-01 · Precision planning (E46)

Planning for the width of a confidence interval rather than power, as
`next.md` set out on 31 October 2026: a new design, `precision`, with a
goal of a target width (find n) or a given n (find the width).

- **Packages.** MBESS for Cohen's d between two equal groups
  (`ss.aipe.smd()`), d_z and a standardised mean (`ss.aipe.sm()`, the
  paired case on the differences), the noncentral t interval that
  `ci.smd()` and `ci.sm()` compute; presize for a correlation
  (`prec_cor()`, Fisher's z, with its corrections for Spearman's and
  Kendall's coefficients) and a proportion (`prec_prop()`). Each is cited
  from the package's own `citation()` (Kelley, 2007; Haynes et al., 2021).
- **Assurance.** For d and standardised means, an optional chance that the
  interval is no wider than the target (MBESS's `assurance`); without it
  the plan is for the expected width, which about half of studies exceed.
  The result says so in words. presize has no assurance option, so the
  correlation and proportion plan for the expected width only.
- **Proportion interval.** Wilson's by default, presize's own default;
  Agresti-Coull, Clopper-Pearson (exact) and Wald are options, Wald only
  with at least 5 expected in each outcome. There is no G\*Power
  convention to follow for precision, so nothing here is a departure.
- **Confidence level** is entered as such (0.95 by default) and stored as
  `target_test > alpha` = 1 - level, so the spec keeps one place for it.
- **Validation.** The engine's tests match each package called directly;
  `test-validation-precision.R` simulates studies at the planned n and
  checks the average width, and with assurance the share narrow enough,
  against intervals computed independently (a noncentral t inversion,
  Fisher's z and Wilson's formula). A published example for d and for a
  proportion is left as `TODO_PUBLISHED_VALUE`.

## 2026-11-01 · Simulated data sets for the remaining designs

`next.md` set the choices on 31 October 2026: simple ones, each stated in
the data set's note (`simulated_data_note()`).

- **Regression.** The R-squared tests draw independent standard normal
  predictors with equal weights within each set (the predictors already
  in the model, then those tested). Logistic and Poisson regression with
  other predictors get one column carrying their overlap with X (pwrss's
  `r.squared.predictor`) and no effect of its own on the outcome.
- **Cluster trials** follow the model each powertools formula assumes:
  site means and site effects with `multisite.cont()`'s ICCs (the effect's
  variance 4 times its ICC, the conditions coded -1/2 and +1/2); a random
  intercept on the log odds with SD `sigma_u` (`crt.parallel.bin()`); a
  log odds ratio varying between sites with SD `sigma_u`
  (`multisite.bin()`); and, for a group treatment trial's yes/no outcome,
  group proportions from a beta distribution with the ICC, under which
  `irgtt.bin()`'s design effect holds. A baseline score has the outcome's
  ICC and explains the two R-squared values the spec gives. Groups are all
  of the planned size.
- **Paired precision plans** draw the two measurements with correlation
  0.5, so that the difference has SD 1 and mean d_z.
- **Left without:** the three-way regression interaction (its data would
  need the regression weights worked out from the correlations it takes,
  which no package does), the meta-analysis, SEM, McNemar's test and the
  generic tests.

## 2026-11-01 · Sequential Bayes factor designs and assurance (Labs)

Step 4 of `bayes-planning.md` (sequential designs by powerkit's own
simulation with bfpwr, decided 31 October 2026), with the sources the plan
needed first.

- **Sources.** O'Hagan, Stevens and Campbell (2005) for assurance;
  Schönbrodt, Wagenmakers, Zehetleitner and Perugini (2017) and Schönbrodt
  and Wagenmakers (2018) for the Sequential Bayes Factor design and its
  planning by simulation. Each was checked against the full text and
  Crossref and added to `refs.bib`. The binomial Bayes factor preprint
  (Kelter and Pawel, arXiv 2502.02914) asks on its first page not to be
  cited without the authors' permission, so it is not added; the binomial
  card can cite bfpwr's own citation.
- **Method.** The 2018 paper's procedure: a first look at `n_min`, then a
  look after every `step` participants (in each group), stopping at a BF10
  threshold for an effect, a BF01 threshold for no effect (they may
  differ, as in the paper's SBF+maxN example) or at `n_max`; the true
  effect drawn from the normal design prior for each simulated study, and
  the same with no effect. The paper's outputs are reported: the chance of
  each ending, the studies at the maximum split by BF10 above 3, below 1/3
  or between, and the mean, median and 80th percentile of N at the stop.
  A maximum N is required: an open-ended design is a large maximum, with
  the share reaching it shown.
- **Computation.** The Bayes factor is bfpwr's `tbf01()` (the JZS Bayes
  factor, exact numerical integration). It depends on the data only
  through t and grows with t (|t| two-sided), so at each look the two
  thresholds are found once as values of t (`uniroot()`), and each
  simulated study's t is compared with them. The decisions are the same as
  computing `tbf01()` at every look (tested at every look, both ways, for
  each test type and direction), and a run takes about a second for 61
  looks and 2,000 studies under each truth, instead of minutes. At most
  2,000 looks.
- **Checks.** With the paper's settings the simulation reproduces its two
  sequential examples to within about a percentage point (for example
  70.4% / 1.8% / 27.8% under H1 against 70.6% / 1.6% / 27.8%); those
  values are placeholders for the maintainer in
  `test-validation-bayes-sequential.R`. A simulation written separately
  (data drawn study by study, `t.test()` at every look, the Bayes factor
  integrated over the noncentral t likelihood, not bfpwr) agrees for two
  groups one-sided with asymmetric thresholds, two groups two-sided with a
  look every 10, and paired data one-sided towards a negative effect.
- **Words.** No "power": the tool reports chances of each ending. On
  optional stopping it says only what the 2018 paper says (more looks
  raise the rate of misleading evidence a little; most of it happens at
  early looks). Where the design prior has an SD, the chance of strong
  evidence is called assurance, on the Bayes factor cards and in Labs.

## 2026-11-01 · Three method choices from the 0.27.0 round, confirmed

- **Yes/no trials, three or more conditions (E63):** the likelihood-ratio
  test stays the default, and the Wald test is offered; with two
  conditions the Wald z test stays the default. With no difference, the
  Wald chi-square test rejected 6.2% of 2,000 simulated studies at alpha
  .05 and the likelihood ratio 5.65%. The likelihood ratio is also simr's
  default for a factor, so it is not a departure.
- **Three levels, few sites (E68):** the Satterthwaite t test stays,
  though it is conservative when few sites are assigned (3.1% at alpha
  .05, against 3.65% in a simulation written without simr). The test
  causes this, not powerkit, so the validation checks that the Type I
  error is at most alpha and agrees with that simulation.
- **POMADE (several effects per study, `next.md` item 5):** its own pull
  request in the next round. It needs a new dependency, and so a rebuilt
  CI image.

## 2026-11-01 · A yes/no outcome in the two- and three-level models (E62, E68)

- **Inputs on the log-odds scale.** As for the participants-and-items
  cards (E33, E63, E67): the chance of 'yes' for a typical group (E62) or
  each condition's chance for a typical site and group (E68), and every
  effect and SD on the log-odds scale. E68's score version takes shares of
  variance (intraclass correlations); for a yes/no outcome it takes SDs
  instead, since turning a latent-scale ICC into an SD needs a formula
  with a published source, and none is in `refs.bib` yet.
- **The test:** glmer's Wald z test by default, simr's default for a
  numeric or two-condition predictor and the p-value glmer's summary
  reports, with the likelihood ratio offered, as on E33 and E67.

## 2026-11-01 · Predictors at all three levels (E62)

- **One card, not a new one.** "Predictors at every level of a
  three-level design" (`next.md` item 2) extends E62, the card for
  predictors at each level, with an optional third level, rather than
  E68, which is about conditions assigned at a level. The form asks
  whether the groups are in larger groups.
- **The model.** A site predictor Z, its effect and its interaction with
  X (the cross-level interactions researchers usually test), the sites'
  random intercepts and, optionally, X slopes: `y ~ x + w + z + x:w + x:z
  + (1 + x | site) + (1 + x | site:group)`. W's interaction with Z, and
  the W slopes across sites, are left out: they are rarely the planned
  effect and would need many more sites to estimate.
- **The design.** W is spread across each site's groups and Z across the
  sites, so the predictors are uncorrelated, as X and W are at two
  levels.

## 2026-11-01 · A predictor measured on each trial (E67)

- **On E67, as a choice of where X is measured.** A trial-level predictor
  (a stimulus duration, a trial's position) is the item-predictor model
  with X varying within items, so it is the same card with one question
  more, not a new one.
- **The design.** Each participant meets every value of X once, in an
  order rotated across participants (a Latin-square rotation), so X is
  centred within every participant, varies within every item, and is
  balanced across items when the number of participants is a multiple of
  the number of items. The items' slopes on X can then be estimated, and
  are in the model when their SD is above 0.
## 2026-11-01 · Moderated mediation decisions, and the shape of the queue

- **W on both links or the direct path (E38, PROCESS models 8, 58 and
  59):** powerkit powers the difference between the conditional indirect
  effects at two values of W the user chooses (by default the mean minus
  and plus one SD), tested by its Monte Carlo confidence interval. Models
  58 and 59 have no single index of moderated mediation (the indirect
  effect is quadratic in W), and manymome's `index_of_mome()` refuses
  model 8, so one comparison serves all three: the one reported when no
  single index exists.
- **A yes/no X or W in moderated mediation (E17, models 7 and 14):**
  built with power4mome and checked against a simulation written
  separately, for how a binary W is standardised in a model with a
  product term and for the Monte Carlo CI's coverage with a binary X. If
  they agree, it ships with the check recorded here; this replaces the
  question for power4mome's author (judgement call E4, now archived).
- **POMADE** moves into this round (0.28.0) rather than the next.
- **The queue holds only work a thread can do.** The statistician's check
  of the whole-study simulation and the published values for the eight
  cards still marked "validation in progress" move from the queue to
  "Waiting on the maintainer, not a PR" in `next.md`.

## 2026-11-01 · Moderated mediation with W on both links or the direct path (E38)

- **The effect tested:** the difference between the conditional indirect
  effects at two values of W, by default one SD below and above its mean,
  for models 8, 58 and 59 alike (decided 1 November 2026, this page,
  "Moderated mediation decisions"). For model 8 it is the index of
  moderated mediation times the distance between the two values.
- **Its test:** manymome's `cond_indirect_effects()` and
  `cond_indirect_diff()` with power4mome's Monte Carlo draws, through a
  powerkit test function in the shape power4mome's own take; the
  confidence-interval rule, as for the other moderated mediation cards
  (Departure 8).
- **One mediator:** models 8, 58 and 59 with parallel mediators are left
  for later; nobody has asked for them.
- **The fitted model for 58 and 59** leaves out power4mome's residual
  covariance of M with W, which lavaan can't estimate when W predicts M
  (`upstream-questions.md`, power4mome).

## 2026-11-01 · Moderated mediation with a yes/no X or W (E17)

- **Answered by checking, not by asking power4mome's author:** the
  separately written simulation standardises a yes/no variable by its
  population mean and SD and forms the product from the standardised
  variables; powerkit's power agrees with it (the standardisation). The
  Monte Carlo interval with a yes/no X is slightly liberal: with no
  moderation it rejected in about 6.7% of 3,000 simulated studies at
  alpha .05, against 5.3% for the separate simulation
  (`upstream-questions.md`, power4mome, question 6).
- **Released with the excess stated** (maintainer, 1 November 2026): the
  card stays "validation in progress" and the results screen says, for a
  yes/no X, that the test was found slightly liberal and the power shown
  may be a little high, until power4mome answers. The power checks agree,
  and the excess is small.
- **A yes/no W is tested as the difference between its two groups'
  conditional indirect effects**, because manymome's `index_of_mome()`
  treats a two-valued moderator as categorical; for models 7 and 14 that
  is the index times a constant, so the decision is the same.
- **A yes/no X or W must be uncorrelated with the other predictor**, as
  the card already said: `rbinary_rs()` draws it on its own.

## 2026-11-01 · Several effects per study in a meta-analysis (E61, POMADE)

- **POMADE's defaults:** the correlated and hierarchical effects (CHE)
  working model, with the average effect tested by robust variance
  estimation on J - 1 degrees of freedom, as POMADE recommends.
- **Balanced studies,** as for E61's other questions: every study the
  same size with the same number of effects, each effect's sampling
  variance that of a typical study computed as metapower computes it, so
  a researcher moving between E61's questions gives the same inputs.
  POMADE's notice that balanced assumptions can mislead is noted on the
  form's help for rho (try several values); drawing study sizes from a
  distribution is left for later.
- **Heterogeneity as SDs (tau, omega),** POMADE's own inputs, not
  I-squared, which has no single meaning with two levels of variation.

## 2026-11-01 · A score moderator and the test of heterogeneity (E61)

- **Simulated with metafor in Spower,** as the Hartung-Knapp tests are:
  no package computes a meta-regression's power, and metapower's
  `homogen_power()` disagrees with simulated Q tests
  (`upstream-questions.md`), so powerkit doesn't wait for it.
- **The moderator** is standardised across the studies and spread
  evenly (normal quantiles), a fixed design as in simr's models, so the
  slope is per SD of the moderator and the average effect is at its
  mean. The moderator's test defaults to Hartung-Knapp, as the average
  effect's does (Departure 18, sized for the moderator).
- **Heterogeneity** is Cochran's Q from the fixed-effect fit, the test
  meta-analyses report; the row in `next.md` is done.

## 2026-11-01 · A score moderator and the test of heterogeneity (E61)

- **Simulated with metafor in Spower,** as the Hartung-Knapp tests are:
  no package computes a meta-regression's power, and metapower's
  `homogen_power()` disagrees with simulated Q tests
  (`upstream-questions.md`), so powerkit doesn't wait for it.
- **The moderator** is standardised across the studies and spread
  evenly (normal quantiles), a fixed design as in simr's models, so the
  slope is per SD of the moderator and the average effect is at its
  mean. The moderator's test defaults to Hartung-Knapp, as the average
  effect's does (Departure 18, sized for the moderator).
- **Heterogeneity** is Cochran's Q from the fixed-effect fit, the test
  meta-analyses report. With the score moderator and POMADE, the
  meta-analysis row in `next.md` is done; study-level power (metameta)
  moves to the Labs row.
## 2026-11-01 · Precision for more estimates (E46)

- **Packages, as for the first estimates:** presize for a raw mean
  difference (two equal groups, equal variances), an odds ratio and an
  ICC; MBESS for a standardised regression coefficient (with assurance).
- **The odds ratio's direction:** the second group's odds over the
  first's, as powerkit's other two-group results run; presize's own is
  the other way, so the groups are passed to `prec_or()` reversed. Its
  interval defaults to presize's own default, the independence-smoothed
  logit interval, with Gart's and Woolf's offered.
- **The regression coefficient at a given n:** MBESS gives the sample
  size for a width, not the width at a size, so powerkit reports the
  narrowest width for which `ss.aipe.reg.coef()` needs no more than n,
  rather than computing a standard error itself.
- **gsl** is a new dependency (MBESS needs it for this function), with
  the system library in the CI image and the online app's build.

## 2026-11-01 · The number of items as the sample size (E33)

- **The same simulation, counted the other way:** the participants are
  fixed and the search varies the number of items; the power at a given
  number of items is the same as the power with those items and
  participants planned the usual way (tested). With each item in one
  condition the number of items is even. Attrition isn't offered here:
  the participants given are those analysed.
## 2026-11-01 · Bayes factor test of one proportion (E25)

Item 3 of `next.md`: the other Bayes factor cards, giving researchers who
analyse in JASP answers that match JASP's.

- **What JASP does.** Read from its source (jaspFrequencies,
  `R/binomialtestbayesian.R` and `inst/qml/BinomialTestBayesian.qml`): a
  Beta(a, b) prior, Beta(1, 1) by default; two-sided, p = p0 against p !=
  p0; one-sided, p = p0 against p > p0 (or < p0) with the prior truncated
  to that side. Two-sided, this is bfpwr's `binbf01(type = "point")`
  exactly. bfpwr's one-sided test (`type = "direction"`) is a different
  hypothesis: p <= p0 against p > p0.
- **Decision.** JASP's tests by default: two-sided from bfpwr's
  `pbinbf01()`, one-sided against a point null computed as bfpwr's
  two-sided Bayes factor times the ratio of the posterior to the prior
  probability of the side (which follows from the Bayes factor's
  definition, checked against that definition integrated numerically),
  summed over the outcomes 0 to n. bfpwr's directional test is an option
  (`one_sided_null` "directional"), labelled on the card. No new package.
- **Design prior.** The expected proportion exactly, or a beta design
  prior with its mean and an SD, as the t-tests' SD (Departure 15 extended:
  bfpwr's default is the analysis prior, which for p = 0.65 against 0.5
  needs 229 people where exactly 0.65 needs 161).
- **Sample size.** Power goes up and down with n, as for the exact
  binomial test: the smallest n that reaches the target, every n below the
  bisection's answer checked (`sawtooth`).
- **Not used.** Kelter and Pawel's preprint on these Bayes factors (arXiv
  2502.02914) asks not to be cited without the authors' permission, so it
  is not in `refs.bib`; bfpwr's own citation is cited.
- **Correlations next.** JASP's correlation Bayes factor (jaspRegression,
  `R/correlationbayesian.R`) calls `bstats::bcor.test()` with a stretched
  beta prior of width 1 (`inst/qml/CorrelationBayesian.qml`); bstats is on
  GitHub only and bfpwr computes a z-test Bayes factor on Fisher's z
  instead. Whether CRAN's BayesFactor matches JASP is to be checked once
  CRAN is reachable from the cloud environment.

## 2026-11-01 · Bayes factor test of a correlation (E4)

Item 3 of `next.md`, giving researchers who analyse in JASP answers that
match JASP's.

- **What JASP does.** Read from its source (jaspRegression,
  `R/correlationbayesian.R`, which calls the GitHub package bstats): a
  stretched beta prior on rho, width 1 (uniform) by default, and the exact
  Bayes factor of Ly, Marsman and Wagenmakers (2018), bstats'
  `bf10CorExact()`; one-sided, rho = 0 against one side with the prior
  truncated to it.
- **Package.** CRAN's BayesFactor `correlationBF(rscale = w)` gives the
  same two-sided Bayes factor at the same width (equal to eight digits
  against JASP's formula, and to the Bayes factor integrated from the
  exact density of r); its one-sided interval Bayes factor is within 0.1%
  of the exact one. So BayesFactor is the backend; bstats isn't on CRAN.
- **Default width.** JASP's 1, not BayesFactor's 1/3 ("medium"): JASP is
  where psychologists run this test. Recorded as Known difference 12 (162
  people against 146 for r = .3, BF10 of at least 10, 80%).
- **Power.** No package computes it. The Bayes factor depends on the data
  only through n and r, and rises with r (or |r|), so strong evidence is a
  sample correlation past a critical value, found by root-finding on
  `correlationBF()`; its chance is from SuppDists' exact distribution of r
  for bivariate normal scores (`pPearson()`, lower tail, which is the more
  accurate). No new maths beyond the root-finding; no simulation.
- **Design prior.** The expected correlation exactly, or a stretched beta
  design prior with its mean and an SD (Departure 15 extended: a design
  prior equal to the uniform analysis prior gives 76.4% at 162 people,
  where exactly r = .3 gives 80%).
- **Not built.** bfpwr's z-test Bayes factor on Fisher's z as a second
  version: it needs a normal analysis prior on z that no common tool uses
  for correlations, and researchers who analyse in R with BayesFactor get
  their answer by setting the width to 1/3.

## 2026-11-01 · Bayes factor test of two proportions (E5)

Item 3 of `next.md`, with answers matching JASP's by default.

- **What JASP does.** Read from its source (jaspFrequencies,
  `inst/qml/ContingencyTablesBayesian.qml` and
  `R/contingencytablesbayesian.R`): BayesFactor's `contingencyTableBF()`,
  with "Indep. multinomial, rows fixed" and prior concentration 1 by
  default; one-sided ("Group one > Group two"), BF10 times the share of
  10,000 posterior draws in that direction, over 0.5.
- **Package.** BayesFactor is the backend: JASP calls it, so the two-sided
  Bayes factor is the same by construction.
- **Power.** No package computes it. Power is the chance of the tables
  whose BF10 reaches the threshold, summed exactly over every possible
  table (each group's count binomial). `contingencyTableBF()` scores one
  table at a time (about 5 ms each), too slow for every table at every n
  of a sample size search, so powerkit uses its closed form for a 2 x 2
  table with rows fixed (each group's proportion Beta(a, a) under the
  alternative, one shared Beta(2a - 1, 2a - 1) under the null, as
  BayesFactor's internal `contingencyIndepMultinomial()` computes it;
  Gunel and Dickey, 1974, the reference in BayesFactor's help). It equals
  `contingencyTableBF()` to ten digits (tested on several tables and
  concentrations, and in every run's check run), and power by brute force
  with `contingencyTableBF()` on every table matches to ten digits at
  n = 30.
- **One-sided.** JASP's rule, with the posterior probability calculated
  exactly instead of estimated from draws (for a whole-number
  concentration, a beta-binomial tail sum: P(p2 > x) is a binomial lower
  tail when p2's Beta parameters are whole numbers; otherwise numerical
  integration; both tested against each other and against posterior
  draws): Known difference 13 (JASP's
  estimate varies by about 0.1%). "greater" means group 2's proportion is
  the higher, as on the z test.
- **No effect.** Both groups at group 1's proportion, as the z test's
  smallest detectable effect keeps group 1's.
- **Design prior.** Each group's expected proportion exactly, or a beta
  design prior on each with the same SD (beta-binomial counts; Departure
  15 extended: uniform design priors give 75.3% at 354 people, where
  exactly .4 and .6 give 80%).
- **Not built.** JASP's other sampling plans (Poisson, joint multinomial,
  columns fixed, hypergeometric): for two groups compared on a yes/no
  outcome the group sizes are fixed by the design, which is JASP's
  default; tables larger than 2 x 2 (the chi-square card, E6) are left
  for later.

## 2026-11-02 · SEM: the tests of close and not-close fit (E37)

Part of item 3 of `next.md`; the method was decided on 1 November 2026
(MacCallum, Browne and Sugawara, 1996).

- **Package.** semPower tests exact fit only. WebPower's `wp.sem.rmsea()`
  computes both of MacCallum and colleagues' tests (its help cites them),
  so powerkit calls it rather than writing the formula. Its noncentrality,
  (N − 1) × df × RMSEA², is semPower's, so at a null RMSEA of 0 its test
  of close fit equals semPower's test of exact fit (checked to 1e-8).
- **Choices.** The card asks which test: exact fit (the default, the test
  SEM software reports), close fit (H0: RMSEA at most 0.05, to detect
  misfit beyond it) or not-close fit (H0: RMSEA at least 0.05; a
  significant result supports close fit). The null value 0.05 is the one
  commonly used with these tests and can be changed. Exact fit stays the
  default because it is the test researchers report; the card explains
  why close and not-close fit are often more useful.
- **Validation.** No published example is transcribed yet (a placeholder
  is left for the maintainer in `test-validation-sem-model-fit.R`).

## 2026-11-02 · SEM: invariance with more groups, occasions and factors (E37)

The rest of the SEM queue item, decided on 1 November 2026 (semPower).

- **Package.** semPower's `semPower.powerMI()` (groups) and
  `semPower.powerLI()` (occasions) take any number of groups, occasions
  and factors, so powerkit passes them on (`population > n_groups`,
  `n_occasions`, `factors`, `factor_correlation`). Power at each n is
  still semPower's F0 through `semPower.postHoc()`, as before; the tests
  check it against the functions called directly with the arguments
  written out, and the restriction's df against (units − 1) × factors ×
  (items − 1).
- **What differs.** The first factor's last items differ in the last
  group or on the last occasion; every other group, occasion and factor
  is invariant. This is the smallest departure from invariance a study
  would want to detect, and the one the two-group card already used.
- **Correlations.** Across groups, the factors correlate by
  `factor_correlation`. Over occasions, a factor correlates `stability`
  with itself between any two occasions, and two factors on different
  occasions correlate by the product (the Kronecker product of the
  occasions' and the factors' correlation matrices, which is always a
  valid matrix and needs no extra inputs). A model with stabilities that
  fall with the lag between occasions isn't offered yet.
- **Group sizes.** Three or more groups are equal in size; the
  allocation ratio stays for two groups.

## 2026-11-02 · Bayes factor test of a contingency table (E6)

Part of item 2 of `next.md` (larger contingency tables), with answers
matching JASP's by default.

- **What JASP does.** Its Bayesian contingency tables call BayesFactor's
  `contingencyTableBF()` with "Indep. multinomial, rows fixed" and prior
  concentration 1 by default (jaspFrequencies'
  `ContingencyTablesBayesian.qml`, read for the two-proportion test on
  1 November). Poisson, joint multinomial and columns fixed are offered for
  any table; hypergeometric for 2 x 2 tables only, so it is not offered
  here.
- **Power.** No package computes it, and the exact sum over every table is
  out of reach beyond very small samples (a 3 x 2 table of 200 people has
  billions of tables), unlike the 2 x 2 table with fixed group sizes. So
  it is simulated: each study's table is drawn from the multinomial with
  the cell probabilities and the total n, the design the chi-square card
  assumes, scored by `contingencyTableBF()` itself (about 3 ms a table),
  with Spower running the replications. The no-association side (the same
  margins, cells their products) is simulated with the same number of
  studies.
- **Validation.** `test-validation-bayes-table.R` (chunk `bayes`) sums the
  exact power and both no-association outcomes over every table at small
  n (a 2 x 2 table of 40 with rows fixed, a 3 x 2 table of 20 with the
  joint multinomial plan) and compares the simulation with them (passed
  at 1,000 studies).
- **Not built.** A design prior on the cell probabilities, and the
  hypergeometric plan.

## 2026-11-02 · Joint power for multisite trials

Part of item 1 of `next.md` (nested designs).

- **Package.** PUMP's `pump_power()`, design `d2.1_m2fr` (people
  randomised within each group, the effect varying at random across
  groups, tested with J - 1 degrees of freedom), the model powertools'
  `multisite.cont()` assumes for the card.
- **Mapping.** powertools' ICCs are shares of the total variance with the
  condition coded -1/2 and 1/2; PUMP's are shares of the variance without
  the effect's. So `ICC.2 = icc / (1 - icc_effect)`, `omega.2 = 4
  icc_effect / icc`, and the effect size is `d / sqrt(1 - icc_effect)`,
  which gives exactly `multisite.cont()`'s noncentrality (tested). A
  baseline score divides d by `sqrt(1 - R-squared)`, as `multisite.cont()`
  does. With no variation in the group means, `ICC.2` is set just above 0
  with `omega.2` scaled to keep the effect's variance.
- **Known difference 14.** PUMP's test statistics are a shifted central t
  (as PowerUp!'s), the card's the noncentral t: about 3 points lower with
  10 groups, under 1 point from 20. Recorded, shown with the joint power
  and tested; PUMP is the only package that gives joint power for these
  designs.
- **Fixed alongside.** A cluster-randomised trial with a baseline score was
  passed to PUMP without it, so its joint power ignored the baseline; it
  is now refused in plain words until PUMP's covariate model is matched to
  powertools' design effect. Group sizes given with an SD of 0 (the form's
  default) were refused as unequal; they are accepted now.
- **Still open in item 1.** Dyadic designs have joint power for several
  actor and partner effects on their own card (E44); a whole-study
  simulation that mixes designs with nested or dyadic data, three or more
  groups and three or more occasions are not built.

## 2026-11-02 · Bayes factor one-way ANOVA (E18)

Part of item 2 of `next.md`, with answers matching JASP's by default.

- **What JASP does.** Read from its source (jaspAnova,
  `inst/qml/common/bayesian/AdditionalOptions.qml`): the Bayesian ANOVA
  calls BayesFactor with "r scale fixed effects" 0.5 by default, which is
  also BayesFactor's own default (`rscaleFixed = "medium"`, 1/2).
- **Package.** BayesFactor is the backend, as JASP's is. For a balanced
  one-way design the Bayes factor depends on the data only through F, the
  group size and the number of groups, and `oneWayAOV.Fstat()` computes it
  from them; it equals `anovaBF()` on the data (tested to eight digits, and
  in every run's check run).
- **Power.** No package computes it. BF10 rises with F, so power is the
  chance that F passes the F at which BF10 reaches the threshold (found by
  root-finding), from the noncentral F with noncentrality f^2 n, the
  distribution pwr and G\*Power use for the F test. Exact, with no random
  numbers; checked against `anovaBF()` on simulated data
  (`test-validation-bayes-anova.R`, chunk `bayes`), for power and for the
  two outcomes with no effect.
- **Not built.** Unequal groups (no F-only form of the Bayes factor), a
  design prior on the means, and Bayes factor versions of the factorial
  and repeated-measures ANOVAs: left for later.

## 2026-11-01 · The critical effect size (t-tests and correlation)

- **Shown, as an observed value** (maintainer, 1 November 2026, with
  Perugini et al., 2025, and Lakens, 2022, added to `refs.bib`): the
  smallest observed effect that would be significant at the n analysed,
  on the results screen and in the methods paragraph, worded as what the
  data can show rather than an assumed population effect.
- **Scope:** the one-sample, paired and two-group t-tests (Student's) and
  Pearson's correlation, the designs Perugini et al.'s Table 1 covers and
  pwr computes. Welch's t is left out: its critical d depends on the
  sample variances (Perugini et al., p. 5), so it has no single value
  before the data are in.
- **The closed form, not a package:** criticalESvalue, the authors'
  package, is on GitHub only, so the engine uses Table 1's formulas with
  `stats::qt()`, checked against simulated studies (each study
  significant exactly when its observed effect is beyond the critical
  value).
- **One worked example to check before transcribing:** for 42 and 15
  participants, t(55), the article reports a critical d of 0.62, where
  Table 1's formula for Student's t gives 0.603; its other examples (r =
  .44 at n = 20, d = 0.75 with 15 per group, r = .03 at N = 5,000) match.

## 2026-11-01 · Technical details for the remaining designs

- **Read from the package where it reports them:** semPower's
  `semPower.postHoc()` returns the chi-square test's df, critical value
  and noncentrality, so SEM shows them; they reproduce its power.
- **The correlation from a published closed form:** pwr's `pwr.r.test()`
  computes the t test's critical t and critical r but doesn't return
  them; Perugini et al.'s (2025) formula gives the same values, so they
  are shown, with no noncentrality (pwr's power comes from Fisher's z).
- **Not rebuilt where a package hides them:** powertools computes df,
  noncentrality and the critical value internally; rewriting its formulas
  in the engine would duplicate a package's maths, so the question goes to
  its authors instead. TOSTER returns none. A Bayes factor design has no
  critical value in this sense, and says so.
## 2026-11-01 · Mixed designs with unequal groups (E8, E55)

**Decided (maintainer, 1 November 2026):** simulate with Spower and afex,
for every mixed design, rather than an exact formula for the 2 x 2 case
only.

- **Why simulation:** Superpower's `ANOVA_exact()`, `ANOVA_exact2()` and
  `ANOVA_power()` all stop for unequal groups when a factor is within
  participants (`conventions.md`, "Superpower and unequal group sizes").
  A closed form exists only for some effects of the 2 x 2 design (below),
  and none covers the within factor or larger designs.
- **How:** `options > group_ratio` gives each group's relative size; the
  total n is split in that ratio and must give whole groups. Spower runs
  powerkit's experiment `p_mixed_anova()`: every group's scores drawn at
  its own size from `ANOVA_design()`'s means and covariances, and the
  effect's p-value from `afex::aov_car()` with Type III sums of squares
  and the sphericity correction asked for, the analysis Superpower runs on
  its own simulated data. The exact method and the smallest detectable
  effect are refused with a plain message; the form hides the method when
  the groups are unequal.
- **Validation** (`test-validation-anova-mixed-unequal.R`, chunk
  `anova_mixed_unequal`): in a 2 x 2 mixed design the between factor's
  and the interaction's F tests are two-sample t-tests (on each person's
  mean, and on each person's difference), so pwr's `pwr.t2n.test()` gives
  their power with unequal groups exactly; at a 1 : 1 ratio the same
  simulation is checked against `ANOVA_exact()` for a 2 x 3 design; and
  the Type I error is checked with unequal groups for the interaction
  (3 x 3) and the between factor (2 x 2).
- **Not a departure:** G\*Power's repeated-measures analysis takes equal
  groups only, so there is no convention to differ from.


## 2026-11-02 · Negative binomial regression (E28's model choice)

- **What:** the count card offers negative binomial regression beside
  Poisson regression, for counts that vary more between people than a
  Poisson distribution allows. Spower simulates it with an experiment of
  powerkit's own, `p_negative_binomial()`: the predictor (a score or a
  yes/no group), any other predictor, then each count with the
  overdispersion k given, fitted by MASS's `glm.nb()` and tested by the
  Wald z test of the predictor. Goals: power and sample size.
- **Why:** overdispersed counts (visits, symptoms, errors) are common in
  psychology, and planning them with Poisson regression's formula
  overstates power. No package powerkit uses has a power function for
  negative binomial regression with a score predictor: MKpower's
  `power.nb.test()` covers two groups only and brings many dependencies;
  MASS is already one of powerkit's. Simulation covers a score and a
  group alike.
- **Inputs:** those of Poisson regression and the overdispersion k
  (variance mu + k mu^2), which the form explains how to estimate from
  earlier data; `conventions.md`, "Not departures, but worth stating".
- **Validation** (`test-validation-negative-binomial.R`, chunk
  `negative_binomial`): agreement with counts drawn as a gamma-Poisson
  mixture and fitted separately; with almost no overdispersion, Poisson
  regression's power by pwrss's formula (within 0.02); the rejection rate
  with no effect. A published worked example is a placeholder for the
  maintainer.

## 2026-11-02 · The aligned rank transform ANOVA (E7, E21 and E22's test version)

- **What:** the two-factor between-participants cards (2 x 2 with equal
  or unequal cells, and larger designs) offer the aligned rank transform
  ANOVA as a test version, simulated by Spower with an experiment of
  powerkit's own, `p_art()`: each cell's scores in the chosen shape
  (normal, skewed or heavy-tailed), with the cell means, SDs and sizes
  entered, then ARTool's `art()` and `artlm()` and car's
  `Anova(type = 3)` for the effect tested. Goals: power and sample size.
- **Why:** the aligned rank transform (Wobbrock, Findlater, Gergle and
  Higgins, 2011, cited by ARTool's `citation()`) is the rank-based test
  researchers use for interactions in factorial designs, which the
  Kruskal-Wallis test cannot test. ARTool is its reference
  implementation on CRAN. No package has a power formula for it, so it is
  simulated like the other rank tests. Reading the one effect through
  `artlm()` takes about a third of the time of the full `anova()` table
  and gives the same p-value.
- **Scope:** between-participants factors only. Designs with a
  within-participants factor need correlated scores of a chosen shape;
  they are left for a later step (`next.md`).
- **Validation** (`test-validation-art.R`, chunk `aligned_rank`): the
  procedure written out from its published definition (subtract the cell
  means, add back the estimated effect, rank, and read that effect's F
  test in the full factorial ANOVA of the ranks) matches ARTool's
  p-values on balanced data, and powerkit's power agrees with a plain loop
  of it; the interaction's rejection rate stays near alpha with skewed
  scores and both main effects present. A published worked example is a
  placeholder for the maintainer.

## 2026-11-02 · The Brunner-Munzel test (E2's test version)

- **What:** the two-group card's test version offers the Brunner-Munzel
  test, simulated by Spower with an experiment of powerkit's own,
  `p_brunner_munzel()`, which draws both groups in the chosen shape
  (normal, skewed or heavy-tailed) and calls brunnermunzel's
  `brunnermunzel.test()`. Goals: power and sample size, as for the
  other rank tests.
- **Why:** the Mann-Whitney test assumes the groups differ only in level;
  when their spreads differ too its Type I error rate drifts from alpha,
  most with unequal groups. The Brunner-Munzel test tests the same
  quantity (the chance a score in one group exceeds one in the other)
  without that assumption. No package has a power formula for it, so it
  is simulated, like the other rank tests. brunnermunzel is on CRAN and
  needs no other package.
- **Inputs:** Cohen's d over the average of the two variances, the SD
  ratio (default 1) and the shape; `conventions.md`, "Not departures, but
  worth stating".
- **Validation** (`test-validation-brunner-munzel.R`, chunk `rank`): the
  statistic written out from its published definition matches the
  package's p-values; Spower's power agrees with a plain loop of the same
  experiment; with no effect the rejection rate stays near alpha with
  unequal spreads and group sizes. A published worked example is a
  placeholder for the maintainer.

## 2026-11-02 · Time to event: the log-rank test and Cox regression (E43)

- **What:** E43 now runs, as design `survival` with two templates. Two
  groups compared on how soon an event happens (`log_rank`): Hmisc's
  `cpower()`. A measured score's hazard ratio in a Cox regression
  (`cox_predictor`): powerSurvEpi's `powerEpiCont.default()`. Goals:
  power and sample size; the smallest detectable effect is not offered
  (neither package solves for it).
- **Why these packages:** both are closed forms from published sources,
  named in their help: `cpower()` uses Schoenfeld's expected events and
  George and Desu's variance; `powerEpiCont.default()` is Hsieh and
  Lavori's (2000) formula for a Cox model with other predictors (through
  the R-squared of the score on them). powerSurvEpi's `ssizeCT()` for two
  groups needs the survival curves, more than researchers planning a
  psychology study usually know; `cpower()` takes each group's proportion
  with the event by one time, the recruitment period and the shortest
  follow-up, which they can estimate from earlier studies.
- **Inputs and conventions:** both two-sided. `cpower()` assumes
  exponential times, so the two proportions fix one hazard ratio, which
  the results screen shows. `powerEpiCont.default()` takes the hazard
  ratio per SD, so the score's variance is 1. Unequal groups for the
  log-rank test through `options > allocation_ratio`. Recorded in
  `conventions.md`, "Not departures, but worth stating".
- **Validation** (`test-validation-survival.R`, chunk `survival`): the
  formulas against log-rank tests (`survival::survdiff()`) and Cox models
  (`survival::coxph()`) simulated separately from the model each formula
  assumes, with recruitment and censoring, within 0.02: both are
  large-sample approximations, so they are not expected to agree to the
  Monte Carlo error alone. Equal and 2 : 1 groups, with and without other
  predictors. The rejection rate with no effect is checked too. Published
  worked examples are placeholders for the maintainer.

## 2026-11-02 · Reliability and agreement: the ICC, Cronbach's alpha and kappa (E69)

- **What:** a new card, E69, reached from the aim screen ("Show that a
  measure is reliable, or that raters agree"), as design `reliability`
  with three templates: `icc` (ICC.Sample.Size's `calculateIccPower()`),
  `cronbach_alpha` (Bonett and Wright's test, statpsych's
  `size.test.cronbach()`) and `kappa` (kappaSize's `PowerBinary()` to
  `Power5Cats()`). Goals: power and sample size.
- **Why these:** each is a published closed form in a package, and each
  tests the value against a null value the researcher names (an ICC above
  0.6, an alpha above 0.7), the usual planning question; testing against
  zero is rarely of interest. Where a package gives only a sample size
  (statpsych, kappaSize), power at a given n is obtained without new
  statistics: for alpha the published formula solved for power (checked
  against statpsych's sample size in every combination tested), for
  kappa by root-finding on kappaSize's own `power` argument.
- **Not yet:** McDonald's omega (no package or published sample-size
  formula found for a test of omega), Krippendorff's alpha (later), and
  two-way ICCs (ICC.Sample.Size and statpsych cover the one-way model).
  The precision card (E46) already plans an ICC's confidence interval.
- **Validation** (`test-validation-reliability.R`, chunk
  `reliability`): each formula against studies simulated without the
  packages and tested by the test the formula approximates: the exact F
  test of a one-way random-effects ANOVA for the ICC, the test of
  ln(1 - alpha) for parallel items, and Donner and Eliasziw's
  goodness-of-fit test of two raters' agreement patterns for kappa
  (prevalence estimated, 1 df), within 0.03 beyond the Monte Carlo
  error. Published worked examples are placeholders.

## 2026-11-02 · One regression coefficient: robust standard errors and quantile regression (E24)

- **What:** a third multiple regression template, `single_coefficient`,
  on the E24 card ("Whether one predictor's coefficient differs from 0,
  controlling for the others"). The effect is the predictor's partial
  R-squared with the number of predictors, as G*Power's single
  regression coefficient test asks. The usual test is pwrss's
  `power.f.regression(k.tested = 1)`, the square of the t test, so it
  equals the R-squared increase of one predictor exactly.
- **Test versions, simulated with Spower** (powerkit's experiment
  `p_coefficient()`): least squares with HC3 or HC4 standard errors
  (car's `linearHypothesis(white.adjust = )`, which uses car's
  `hccm()`), and quantile regression (quantreg's `rq()`, tested by
  `summary.rq(se = "nid")`, the standard error that allows the spread to
  change with the predictor and gives a p-value; quantreg's default for
  small samples, rank inversion, gives intervals only). No package powerkit
  uses has a power function for these tests.
- **Data model:** the tested predictor and the others are independent
  standard normal scores (only the part of the predictor the others don't
  share affects its test, which the partial R-squared describes); the
  slope is sqrt(partial R² / (1 − partial R²)) error SDs; the error
  variance is exp(g x − g²/2), averaging 1, with g = log(variance ratio)
  / 2, where the variance ratio compares 1 SD above the predictor's mean
  with 1 SD below; errors are normal, skewed (standardised chi-square, 10
  df) or heavy-tailed (t, 3 df), the shapes the rank tests use. For
  quantile regression the error's quantile is moved to 0, so the
  outcome's quantile rises by the slope.
- **Default:** the usual t test stays the default, as in G*Power, with
  robust standard errors one choice away. Whether HC3 should become the
  default for every regression coefficient is a method question for the
  maintainer; not changed here.
- **Two-sided only**, as the card's other tests.
- **Validation** (`test-validation-robust-regression.R`, chunk
  `robust_regression`): HC3 and HC4 against the usual test's formula when
  errors are normal with a constant spread (within 0.02 beyond the
  Monte Carlo error), quantile regression against a simulation that draws
  the outcome from its quantile function and calls `rq()` directly, and
  the Type I error with a changing spread. A published example is a
  placeholder.
- **Open question for the maintainer:** quantreg's "nid" test rejects
  too often when errors are skewed and their spread changes: 9.4% at
  alpha 0.05 (n = 150, three predictors, variance ratio 4), while
  `se = "ker"` gave 0.7%. Power for quantile regression is then
  optimistic. The card says so, and a validation test records the size.
  Alternatives are the bootstrap (`se = "boot"`, much slower) or rank
  inversion (intervals only); a statistician's view is wanted.

## 2026-11-04 · Multinomial logistic regression (E70)

- **What:** a new card and template, `logistic_regression / multinomial`,
  for an outcome in three or more unordered categories predicted by one
  score or yes/no group, other predictors entering through the predictor's
  R-squared with them (as on the logistic and Poisson cards). Spower
  simulates powerkit's experiment `p_multinomial()`, which fits nnet's
  `multinom()`. Goals: power and sample size.
- **Why:** `next.md` item 6 (decided 1 November 2026: by simulation with
  Spower). Multinomial logistic regression is how psychologists analyse a
  choice among several options or a category membership predicted by a
  score, and the design finder had no card for it (the guided route sent
  a categorical outcome with a score predictor to the safety net). No
  package powerkit uses has a power function for it and G\*Power has no
  such test; nnet ships with R as a recommended package, so the only new
  import adds no installation.
- **Inputs:** the share in each category at the starting point (X's mean,
  or X's first group) and the effect as the shares at a second point (one
  SD higher, or X's second group) or as each category's odds ratio against
  the first, the form papers report (SPSS's Exp(B)). Both fix the model
  exactly: intercept_k = log(p_k / p_1) at the start, slope_k = log of the
  odds ratio.
- **Tests:** the likelihood-ratio test of the predictor (K − 1 df) by
  default, the omnibus test researchers report for a predictor; the Wald z
  test of one category against the first as an option, for a hypothesis
  about one category. Two-sided only, since the omnibus test has no
  direction.
- **Empty categories:** a simulated study with nobody in some category
  can't be fitted and counts as not significant. The minimum n is ten per
  coefficient (2(K − 1)).
- **Validation** (`test-validation-multinomial.R`, chunk `multinomial`):
  with a yes/no predictor the likelihood-ratio test is exactly the G test
  of the 2 x K table, which an independent simulation computes from
  `rmultinom()` counts; with a score, an independent simulation draws the
  categories by the Gumbel-maximum rule and fits the same model as a
  Poisson log-linear model in `glm()`; pwr's chi-square formula within
  0.02; Type I error. A published worked example is a placeholder for the
  maintainer.

## 2026-11-04 · Zero-inflated count regression (E28's model choice)

- **What:** the count card offers zero-inflated Poisson and negative
  binomial regression beside Poisson and negative binomial regression.
  Spower simulates powerkit's experiment `p_zero_inflated()`, which fits
  pscl's `zeroinfl()`. Goals: power and sample size.
- **Why:** `next.md` item 6 (decided 1 November 2026: by simulation with
  Spower). Counts in psychology often include people who could not have
  had an event (non-drinkers when counting drinks, people without a
  symptom), and planning them with a model that ignores the extra zeros
  misstates power. pscl (CRAN, GPL-2, depending only on MASS and base R)
  is the reference implementation of these models in R; no package
  powerkit uses has a power function for them.
- **Inputs:** those of the Poisson or negative binomial model, which now
  describe the count part, plus the share of extra zeros at the starting
  point and the predictor's odds ratio for being an extra zero (1 by
  default). The analysis model has the predictor in both parts, pscl's
  default for one formula, whatever the true effect on the zeros.
- **Tests:** the Wald z test of the predictor in the count part (the
  default, the rate ratio the card asks for first) or the zero part, or
  the likelihood-ratio test of both parts (2 df, two-sided).
- **Failed fits:** a simulated study with no zeros or no counts above 0,
  or whose fit fails, counts as not significant. The minimum n is 30.
- **Validation** (`test-validation-zero-inflated.R`, chunk
  `zero_inflated`): an independent simulation draws the counts as a
  mixture (with a gamma frailty for negative binomial counts) and
  maximises the zero-inflated likelihood written out with `optim()`; each
  part's test keeps its Type I error when the predictor changes only the
  other part. A published worked example is a placeholder for the
  maintainer.
- **Not covered:** hurdle models (pscl's `hurdle()`), in which every zero
  comes from the binary part; a candidate for a later step if researchers
  ask for it.
- **The zero part's Wald test (decided 4 November 2026: keep it):** with
  negative binomial counts the Wald test of the predictor in the zero part, which `summary()` of
  `zeroinfl()` reports, is conservative: 3.9% of 10,000 studies with no
  zero effect rejected at alpha 0.05 (n = 400, base rate 2, 30% extra
  zeros, k = 0.5), against 5.6% for the likelihood-ratio test of the same
  coefficient (3,000 studies); with Poisson counts the Wald test holds its
  level. powerkit computes power for the Wald test researchers will
  report, so that power is conservative; the input screen says so, and a
  validation test records the size. The maintainer kept the Wald test,
  because it is the test researchers report from `summary()`; the
  likelihood-ratio test of the zero part remains a possible option.

## 2026-11-04 · The aligned rank transform with a within-participants factor (E8, E55 and E20)

- **What:** the 2 x 2 mixed (E8), larger mixed (E55) and two-factor
  within-participants (E20) cards offer the aligned rank transform ANOVA
  as a test version, simulated by Spower with powerkit's experiment
  `p_art_within()`. Goals: power and sample size.
- **Why:** `next.md` item 5, Ready for this part since 31 October 2026.
  Researchers use the aligned rank transform for factorial designs with
  repeated measures as well as between-participants ones (ARTool's help
  shows a split-plot example), and the between-participants version left
  group-by-time designs without one.
- **Data model:** correlated scores of a chosen shape, as Friedman's test
  draws them (the queue item's wording): each score the cell's mean plus
  its SD times (sqrt(r) times the person's own level plus sqrt(1 - r)
  times a deviation of the chosen shape). So one correlation holds between
  any two of a person's scores, one per group in the 2 x 2 mixed design;
  the spec checks refuse different correlations per pair and a
  correlation below 0, and a sphericity correction (which has nothing to
  correct).
- **Analysis:** ARTool's documented model for repeated measures is a random
  intercept per person; with equal groups powerkit fits its error-term
  equivalent (`Error(id)`), which gives identical p-values in a balanced
  design and is several times faster; with unequal groups, the random
  intercept model with car's Type III Kenward-Roger F tests, because
  `aov()`'s sequential sums of squares would differ from Type III for the
  within factor's main effect.
- **Validation** (`test-validation-art-within.R`, chunk
  `aligned_rank_within`): the procedure written out from its published
  definition with an error term matches ARTool's p-values; powerkit agrees
  with a plain loop of it for a 2 x 2 and a 2 x 3 mixed design and two
  within-participants factors; the interaction's rejection rate stays near
  alpha with skewed scores and both main effects present. A published
  example is a placeholder for the maintainer.

## 2026-11-04 · Decisions for the rest of the queue (`next.md` items 2 to 6)

Recommendations made with the 0.31.0 work and accepted by the maintainer.

- **Item 2, the Bayes factor of an effect in factorial and repeated
  measures ANOVAs:** JASP's inclusion Bayes factor across all models, with
  uniform model priors and the principle of marginality, as its Bayesian
  ANOVA's Effects table gives it (jaspAnova's
  `inst/qml/common/bayesian/DefaultOptions.qml`: `effectsType` "allModels",
  checked by default; `AdditionalOptions.qml`: `modelPrior` "uniform", r
  scale 0.5 for fixed and 1 for random effects), by default; the
  comparison across matched models as an option. Between-participants
  designs (about 0.1 s per simulated study with BayesFactor) run in the
  app; repeated measures (about 0.8 s) take the preview and R script route.
- **Item 3, three or more occasions:** growth curves first, by longpower's
  closed form (CRAN 1.0.27), checked against a simr simulation; then the
  random-intercept cross-lagged panel model with powRICLPM (CRAN 0.2.1).
  Experience sampling waits: PowerAnalysisIL is not on CRAN.
- **Item 4, designs that need a custom simulation:** one PR per design,
  starting with a moderator with three or more groups (E30) and moderation
  with a yes/no outcome (E32); then interrupted time series (E42).
- **Item 5, the rest of the non-parametric comparisons:** PERMANOVA by
  simulation with vegan's `adonis2()` (CRAN 2.7-6). Quade's non-parametric
  ANCOVA is not covered: no package implements it, and base R's
  `quade.test()` is a different test (Quade's test for unreplicated
  blocks).
- **Item 6, psychometric models:** IRT and DIF with irtpwr (CRAN 1.0.3)
  first; Krippendorff's alpha and two-way ICCs once a package with a
  sample-size or power method is found; EFA, latent profiles and signal
  detection each scoped in its own PR.

## 2026-11-04 · PERMANOVA (E59's test version)

- **What:** the MANOVA card offers PERMANOVA (permutational MANOVA) as a
  test version, for one or two factors, simulated by Spower with
  powerkit's experiment `p_permanova()` around vegan's `adonis2()`. Goals:
  power and sample size. This finishes `next.md` item 5 (decided 4
  November 2026, this page).
- **Why:** PERMANOVA is the distance-based alternative researchers use when
  several outcomes are not multivariate normal; no package powerkit uses
  has a power function for it, and vegan is its reference implementation
  (CRAN 2.7-6, GPL-2; it brings permute, the only new dependency besides
  itself, and needs a Fortran compiler to build from source).
- **Distance:** Euclidean distances between the outcomes standardised in
  each data set, not vegan's default Bray-Curtis, which is for ecological
  abundance data and needs values of 0 or more (`conventions.md`).
  Permutations: vegan's default 999.
- **Data:** normal scores as for MANOVA; scores of another shape as each
  person's common level plus a deviation of that shape, so the correlation
  must be at least 0.
- **Validation** (`test-validation-permanova.R`, chunk `permanova`): the
  pseudo-F written out from its definition equals `adonis2()`'s F; powerkit
  agrees with a separate permutation test of that pseudo-F, without vegan;
  Type I error with skewed scores. A published example is a placeholder.

## 2026-11-04 · Moderation of a yes/no outcome (E32)

- **What:** E32 calculates moderation of a yes/no outcome: a new template,
  `logistic_regression / interaction`, simulated by Spower with powerkit's
  experiment `p_logistic_interaction()` around `glm(family = binomial())`.
  Goals: power and sample size. A count or categorical outcome, and
  mediation with an outcome that isn't a score, stay on the card as
  designs with no ready-made tool.
- **Why:** `next.md` item 4 (decided 4 November 2026: one PR per design,
  starting with E30 and E32). Moderation of a yes/no outcome is the most
  common of E32's designs; no package powerkit uses has its power, and
  G\*Power's logistic regression has no product term.
- **Data model:** X and W scores (standard normal, correlated as given) or
  yes/no groups (coded 0 and 1, drawn on their own); the outcome logistic
  in X, W and X x W with the base proportion and three odds ratios.
- **Test:** the Wald z test of the product's coefficient, the test
  `summary()` of a logistic regression reports; one-sided on request.
- **Validation** (`test-validation-logistic-interaction.R`, chunk
  `logistic_interaction`): the large-sample power of the Wald test from
  the model's expected Fisher information (within 0.02); a separately
  written simulation; Type I error with both main effects present. A
  published example is a placeholder.

## 2026-11-05 · Moderation by a factor with three or more groups (E30)

- **What:** E30 calculates: a new template, `regression_interaction /
  group_moderator`, simulated by Spower with powerkit's experiment
  `p_group_moderator()` around `lm()`. Goals: power and sample size.
- **Why:** `next.md` item 4 (decided 4 November 2026: E30 and E32 first).
  Comparing a relationship across three or more groups (age groups,
  conditions, sites) is common, and the design finder's moderation route
  sent it to a custom simulation.
- **Inputs:** the correlation of X and Y in each group, the effect size
  researchers usually have for each group, and optionally the groups'
  means; equal or unequal groups (`options > group_ratio`).
- **Data model and test:** in each group X standard normal and Y = m_g +
  r_g X + sqrt(1 - r_g^2) e; the F test of the X x group terms (k - 1 df),
  comparing `lm(y ~ x * a)` with `lm(y ~ x + a)`. When the correlations
  differ, so do the groups' residual variances, which the F test assumes
  equal; the simulation reports the power of the test as researchers run
  it.
- **Validation** (`test-validation-group-moderator.R`, chunk
  `group_moderator`): pwr's F test formula with f^2 from the population
  (within 0.02), a separately written simulation, and Type I error when the
  groups differ only in their means.

## 2026-11-05 · Growth curves (E35)

- **What:** E35 calculates growth curves: a new template, `mixed_model /
  growth_curve`, by longpower's `diggle.linear.power()` (Diggle, Heagerty,
  Liang and Zeger, 2002). Goals: power and sample size. Cross-lagged panels
  and experience sampling stay on the card as designs not calculated yet.
- **Why:** `next.md` item 3 (decided 4 November 2026: growth curves first,
  longpower's closed form checked against a simulation).
- **Which formula:** longpower offers several. Diggle and colleagues'
  textbook formula fits the model researchers usually fit, with its own
  starting level for each group, for equal groups and complete data.
  `edland.linear.power()` adds attrition and unequal allocation but cites
  work "in process"; Hu, Mackey and Thomas (2021,
  `hu.mackey.thomas.linear.power()`) adds them in a published method that
  assumes both groups start at the same level, as in a randomised trial.
  Diggle's first; Hu, Mackey and Thomas's is the candidate for attrition
  and unequal groups.
- **A package fault worked around:** `diggle.linear.power()` given n finds
  the power by root-finding that fails for small groups and returns about 0
  for large ones; powerkit solves the package's sample size for the power
  instead (`upstream-questions.md`, longpower).
- **Validation** (`test-validation-growth.R`, chunk `growth`): lme4 fits to
  simulated studies, the group x time coefficient tested by its Wald z test
  (within 0.03, since the formula takes the covariance as known); Diggle and
  colleagues' published table is a placeholder for the maintainer.

## 2026-11-05 · Differential item functioning in a 2PL IRT model (E71)

- **What:** a new card, E71, and template, `irt / dif`: whether some items
  of a test with yes/no or right/wrong answers work differently in two
  groups, by irtpwr's analytical method (`irtpwr()`, Zimmer and Debelak,
  2023, the package's citation()) with its `"DIF2PL"` preset. Goals: power
  and sample size. Reached from Q1 ("That a test's items work the same way
  in two groups") and the latent-variables family in "I know my analysis".
- **Why:** `next.md` item 5 (decided 4 November 2026: IRT and DIF with
  irtpwr first). Of the IRT designs, DIF between two groups (for example
  two language versions of a test) is the one psychologists most often
  plan for; irtpwr's other presets (1PL against 2PL, a partial credit
  model against the generalised one) can follow if researchers ask.
- **Inputs:** each item's discrimination a and difficulty b, as calibrations
  report them (irtpwr's intercept is d = -a b); the DIF items, each one's
  change in difficulty and, optionally, in discrimination; the statistic
  (likelihood ratio by default, or Wald, score or gradient). Two groups of
  equal size with standard normal abilities and the other items as
  anchors, as the preset assumes; the spec checks require an anchor item
  and an even n.
- **Which parameters are tested (judgement call B19, decided 5 November
  2026: both, explained to users):** both of each DIF item's parameters by default (2 df per item),
  the omnibus test in mirt's `DIF()` help; irtpwr's preset tests only the
  parameters that differ, offered as `target_test > free_parameters =
  "differing"`. Departure 20 records the difference (53.6% against 64.1%
  in the example at 600 people).
- **Package faults worked around:** the preset stops when one parameter
  differs (`upstream-questions.md`, irtpwr), and it builds its hypothesis
  from the differences only; powerkit passes the preset with its `res()`
  and `unres()` replaced through `setup.hypothesis(type = <list>)`, the
  package's documented way to give a custom preset, and checks that it
  gives the package's own power where both run.
- **Validation** (`test-validation-irt.R`, chunk `irt`): mirt's
  `multipleGroup()` fitted to simulated studies with every item equal and
  with the DIF item's parameters free, compared by their likelihood ratio,
  for a change in difficulty and in discrimination and both choices of
  parameters (within 0.04 plus the simulation's error, since irtpwr's
  method is large-sample), and the Type I error with no DIF. The method
  paper's example is a placeholder for the maintainer.

## 2026-11-05 · Whole-study simulation: non-randomised groups

- **What:** in the whole-study simulation, X as two groups may correlate
  with the moderator W and the first measurement B, as for groups people
  aren't randomised to (gender with a personality score, for example).
  Before, the correlation had to be 0. The input screen asks for it, 0 if
  people are randomised to the groups.
- **Why:** `next.md` item 1 (decided 31 October 2026: extend the
  whole-study simulation one design at a time); the first design its row
  listed as not yet covered.
- **How:** power4mome draws a two-group X on its own (`rbinary_rs()`), so
  it can't be given a covariance with W. W is regressed on X in the
  population, and B on X and W, with the standardised coefficients that
  give the correlations entered; W is normal within each group, with the
  groups' means apart. The analyses' own models are unchanged.
- **Moments:** a product of a two-group X with W doesn't have the moments
  of a product of jointly normal variables (for equal groups its variance
  is 1 - r^2, not 1 + r^2), which power4mome's standardisation and
  powerkit's `implied_r_squared()` assume. Each residual variance is
  computed from the exact moments (`whole_study_moments()`, the polynomial
  method of Departure 19 generalised to the whole-study model), supplied
  explicitly, and power4mome's standardisation is switched off. Randomised
  groups keep the existing path, so their results don't change.
- **Validation** (`test-validation-whole-study-groups.R`, chunk
  `whole_study`): a simulation written separately (Y's residual SD found
  numerically from a million draws, each analysis fitted by `lm()`), for
  equal and unequal groups and with a first measurement; each analysis's
  power and the joint power agree within Monte Carlo error. A question for
  the statistician (`whole-study-method.md`, question 8): whether a
  correlation is the right input for a group, or the groups' standardised
  difference.

## 2026-11-05 · The About tab is built on first opening, for a faster first visit

- **What:** the About tab's content (the capability table above all) is
  built the first time a visitor opens it and kept for the rest of that R
  process, instead of when the app starts.
- **Why:** visitors reported that the site often sat on "loading" until
  they refreshed. Posit Connect Cloud starts a new R process for a visit
  after a quiet spell, so that first visit waits for the whole app start;
  a refresh reaches the process that is by then running. Of the 3.1
  seconds the app spent before it could answer, building the About tab
  took 1.9 (the capability table, added on 5 November 2026, 1.7 of them);
  the app now starts in 0.5. The time Connect Cloud takes to start a
  process and load R is outside the app.
- **Trade-off:** the About tab's first opening in a new process takes
  about 2 seconds; later openings are instant. Search engines read the
  static guide (`www/guide.html`), not the About tab.
## 2026-11-05 · Dyadic data: a pair-level moderator of the actor effects (E44)

- **What:** the actor-partner card (E44) takes an optional pair-level
  moderator W (one value per pair, such as relationship length) that
  predicts each member's outcome and moderates each member's actor effect.
  The moderation can be tested alone or jointly with the actor effects,
  counted in the same simulated studies.
- **Why:** `next.md` item 1 (decided 31 October 2026: extend joint power
  one design at a time). For independent people the whole-study
  simulation covers a comparison, a moderation and a mediation on the
  same data; for pairs the joint claim so far was the actor and partner
  effects together. Whether the actor effect depends on something about
  the pair is the moderation dyadic studies most often add, and power4mome
  fits it with no new engine.
- **Model:** Y1 ~ X1 + X2 + W + X1:W and Y2 ~ X2 + X1 + W + X2:W, W
  correlated r_xw with each member's X; for indistinguishable members W's
  path and the moderation are constrained equal across members, as the
  actor and partner paths already are. W moderating the partner effects
  is not offered yet.
- **Moments:** the two products correlate (r_x + r_xw^2 for jointly normal
  variables), so each Y's residual variance is computed from the exact
  moments and supplied explicitly, with power4mome's standardisation off
  (as for PROCESS models 58 and 59, Departure 19).
- **Validation** (`test-validation-apim-moderation.R`, chunk `dyadic`): a
  simulation written separately (the data drawn with MASS, the products
  formed by hand, each Y's residual variance found numerically from a
  million draws, lavaan fitted directly) for the moderation alone, with
  the actor effect, and both members' moderations; Type I error with no
  moderation. lavaan's Wald z test of the moderation is liberal with few
  pairs: with no moderation it rejected 7.2% of 4,000 studies at 60 pairs,
  5.1% at 200 and 800 (the independent simulation, lavaan alone).
  powerkit reports the power of the test lavaan prints, as for the other
  tests it simulates; a test records the size, and the input screen says
  so.
## 2026-11-05 · powerkit is not only for psychology

- **What:** the page title, search description and footer of the app,
  the static guide, the README, the engine's DESCRIPTION title and
  description, and CITATION.cff no longer describe powerkit as a tool for
  psychology; they describe it as power analysis and sample size planning
  for research studies.
- **Why:** the maintainer's direction: powerkit serves researchers beyond
  psychology. The wording had been removed before but came back with the
  search-engine text added on 4 November 2026, which took its phrasing
  from the project's own self-descriptions (CLAUDE.md's first line, the
  README, DESCRIPTION, CITATION.cff), all of which still said psychology.
- **How it stays out:** those self-descriptions now say research studies,
  CLAUDE.md says never to describe powerkit to users as a psychology tool,
  and `app/routing/tests/testthat/test-wording.R` fails if the title,
  description, footer, guide, DESCRIPTION, CITATION.cff or the README's
  opening call it one. Psychology examples on the cards and citations of
  psychology journals are unaffected.

## 2026-11-05 · The Bayes factor of an effect in a two-factor between-participants ANOVA (E7, E21, E22)

- **What:** the 2 x 2 (E7), unequal-groups 2 x 2 (E22) and two-factor
  (E21) between-participants ANOVA cards offer the Bayes factor of the
  chosen effect (either main effect or the interaction) as a test version:
  the chance that the study gives strong evidence, an inclusion Bayes
  factor past the threshold, and the no-effect side. Simulated with Spower.
- **Why:** `next.md` item 2, decided 4 November 2026: JASP's inclusion
  Bayes factor across all models, with uniform model priors and the
  principle of marginality, by default; the comparison across matched
  models as an option; between-participants designs in the app first.
- **How:** each simulated study draws normal scores in each cell (the
  cells' means, one SD, each cell's share of n); BayesFactor's `anovaBF()`
  fits every model that respects marginality (`whichModels = "withmain"`)
  with JASP's r scale of 0.5, and bayestestR's `bayesfactor_inclusion()`
  gives the effect's inclusion Bayes factor (posterior over prior inclusion
  odds), across all models or matched models. The no-effect side removes
  only the tested effect from the cell means. About 0.1 s per simulated
  study.
- **Validation** (`test-validation-bayes-factorial.R`, chunk
  `bayes_factorial`): a simulation written separately, with the inclusion
  Bayes factor across all models computed by hand from the models' Bayes
  factors, for an interaction and a main effect, equal and unequal cells;
  the matched-models option against the same loop. A published example is
  a placeholder for the maintainer.
- **Next:** the repeated-measures designs, by the preview and R script
  route (about 0.8 s per simulated study).

## 2026-11-05 · Keeping the visitor's place, and showing that the app is working

- **What:** the app (1) shows "Starting powerkit" while a new server
  process wakes up, instead of a blank page; (2) shows a bar with
  "Working…" whenever it is busy for more than a quarter of a second;
  (3) keeps an open page's connection from being closed for being quiet
  (a small message every 20 seconds) and reloads a page by itself when the
  visitor comes back to it after its connection was lost, leaving the
  host's own lost-connection message and Reload button as they are, so
  there is only ever one; (4) asks Shiny to reconnect to the same
  session when the connection drops while its process is still running;
  (5) saves the answers on an input screen in the visitor's own browser
  (localStorage, in the draft format "Save a draft" already uses) and, on
  a new visit, offers to continue where they left off; and (6) builds the
  About tab in the background a few seconds after the app starts, with a
  loading message if it is opened before then.
- **Why:** visitors reported losing their progress when they came back to
  the page after a while (the server ends idle sessions, and the app's
  state lived only in the session), and pages that seemed broken while they
  loaded, with nothing to say they were loading.
- **What is not kept:** the position in the design finder before an input
  screen (a few clicks to redo), and results (the answers are kept, so
  checking them again recalculates).
## 2026-11-05 · The Bayes factor of an effect in repeated-measures ANOVAs (E8, E54, E55, E20)

- **What:** the one-way repeated-measures (E54), two-factor
  within-participants (E20), 2 x 2 mixed (E8) and larger mixed (E55)
  ANOVA cards offer the Bayes factor of an effect as a test version, the
  inclusion Bayes factor of JASP's Bayesian repeated-measures ANOVA.
- **Why:** `next.md` item 2, decided 4 November 2026: repeated measures by
  the preview and R script route, as mediation does.
- **How:** the same experiment as the between-participants designs
  (`p_bayes_factorial()`), with each person's scores sharing their own
  level (the spec's one correlation r between any two of their scores, a
  random intercept, as JASP's model assumes) and `anovaBF()` taking the
  participants as a random factor with JASP's r scale of 1 for random
  effects. One correlation of at least 0 and equal groups are required.
  About 0.8 s per simulated study, so in the app this test version gives a
  rough preview (100 simulated studies, about four minutes with the
  no-effect side) and an R script for the full analysis; the F test on
  the same cards still calculates at once (`forms.yaml`, simulations >
  method_routes, the route chosen by test version).
- **Validation** (`test-validation-bayes-repeated.R`, chunk
  `bayes_factorial`): a simulation written separately (each person's
  scores from a multivariate normal, the inclusion Bayes factor computed by
  hand) for a two-factor within-participants design and a 2 x 2 mixed
  design. A published example is a placeholder for the maintainer.

## 2026-11-05 · Growth curves with drop-out and unequal groups (E35)

- **What:** the growth-curve screen asks whether anyone drops out before
  the last occasion and, if so, the share still in the study at each
  occasion (`population > retention`, the same in both groups), and the
  second group's size relative to the first (`options >
  allocation_ratio`). With either, the engine uses longpower's
  `hu.mackey.thomas.linear.power()` (Hu, Mackey and Thomas, 2021,
  Biometrical Journal, the reference in longpower's help), which keeps
  everyone's measurements up to the occasion they leave after (monotone
  drop-out) and takes unequal allocation. Without them it keeps Diggle and
  colleagues' formula, as decided on 5 November 2026.
- **Why:** `next.md` item 3 named attrition and unequal groups as the next
  step for growth curves. Recruiting more to make up for people who leave
  (`options > attrition`) wastes their earlier measurements, which a
  mixed model uses; the two can't be combined, and the spec checks say so.
- **The model it assumes:** both groups start at the same level, as in a
  randomised trial (no group main effect), where Diggle's formula lets each
  group have its own. The card and the screen say so. With complete data
  and equal groups the two formulas differ (192 against 228 for the
  example spec), which is why Diggle's stays the default there.
- **Validation** (`test-validation-growth-dropout.R`, chunk `growth`):
  lme4 fits of the formula's model to simulated studies with monotone
  drop-out drawn with the given shares, the group x time term tested by its
  Wald z test, agree within a point (79.2% against 79.6%; 93.0% against
  93.7%; 63.9% against 63.4%; 1,000 studies each), inside the 0.03
  allowance the complete-data formula has. A published example from Hu,
  Mackey and Thomas is a placeholder for the maintainer.
## 2026-11-05 · Groups by number or by name

A variable's groups, conditions or categories (every `levels` field of a
variable) may be given as how many there are instead of their names:
"3" stands for "Group 1, Group 2, Group 3" (or Condition, Category, Time
or Level, from the field's wording). G\*Power asks only for the number of
groups; powerkit uses names to label the means, the results and the
write-up, and they stay available for anyone who wants them. A count is
written out as names before the screen's checks and the spec
(`expand_level_counts()`), so the engine sees names as before.
## 2026-11-05 · How Bayes factors fit powerkit: a four-part plan

Open question 8 (where Bayes factors enter) and the rest of `next.md`
item 2, decided together. powerkit plans a Bayes factor test for fifteen
designs, but the only way in was each card's test version, and the
"Bayes factor design" page still said "not in powerkit yet".

- **No extra question for everyone.** Asking "p-values or Bayes factors?"
  at the start adds a question for every user, most of whom plan with
  p-values. Bayes factors are found from "I know my analysis" and its
  search instead, and offered on the results of the designs that have
  them.
- **Part 1 (this change): a page of every design with a Bayes factor
  version.** E-bayes becomes a guide (`guide: bayes` in `tree.yaml`): a
  short explanation, the designs with a Bayes factor test version (found
  from `forms.yaml`, so the list stays complete as designs are added),
  each opening its input screen with the Bayes factor chosen, and a link
  to Bayesian planning in Labs. Searching "Bayes" lists those designs.
- **Part 2: what a Bayes factor would add, on frequentist results.** At
  the sample size planned for the p-value, the chance of strong evidence
  for the effect if it is real, and of strong evidence for no effect if
  there is none, with JASP's default priors. A non-significant p-value
  cannot show that an effect is absent; a Bayes factor or an equivalence
  test can (Lakens, McLatchie, Isager, Scheel and Dienes, 2020).
- **Part 3: planning for both tests.** Many researchers report a p-value
  and a Bayes factor for the same test. That is sound when one is named
  as primary before the data are collected; choosing afterwards the one
  that reads better is not. A study meant to be judged both ways needs a
  sample size that serves both, since they can disagree (in a large
  study, p just under .05 can come with a Bayes factor favouring no
  effect). "Plan for both" finds the sample size meeting both targets,
  shows how often the two would agree, and writes the plan's wording
  with the primary test named.
- **Part 4: a full Bayesian planner on the cards.** The Labs tool's
  separate design and analysis priors, a design prior entered as a
  plausible range, informed analysis priors (bfpwr's prior location,
  scale and degrees of freedom), sequential designs, and a check of how
  the plan changes with the prior's width.

Sources for parts 2 to 4 are added to `refs.bib`, checked against the
full text, in the PRs that cite them; Schonbrodt and Wagenmakers (2018)
and O'Hagan, Stevens and Campbell (2005) are there already.

## 2026-11-05 · What a Bayes factor would add, and planning for both (parts 2 and 3)

Parts 2 and 3 of the plan above, on the designs whose Bayes factor
version is calculated exactly: the three t-tests, the correlation, one
proportion, two proportions and the one-way ANOVA. The tables and the
two-factor and repeated-measures ANOVAs are simulated (seconds to minutes
a study), so they are left out.

- **Engine.** `bayes_companion(spec, n, thresholds, target)` runs the
  plan's Bayes factor test version (the same function the card's Bayes
  factor version uses, with its default priors, JASP's) at the planned
  sample size, and, with the target power, finds the sample size giving
  the Bayes factor the same chance. A plan with no counterpart says why
  (Welch's t-test or Welch's F with SDs that differ).
- **Two thresholds, 3 and 10.** At ordinary sample sizes a Bayes factor
  of 10 for no effect is often out of reach (90 people in a one-sample
  test can't give it, however the data fall), so one threshold would
  show 0% where 3 shows most studies finding evidence of no effect.
- **Agreement (t-tests).** The p-value and the JZS Bayes factor both
  depend on the data only through t, so each test's decision is a
  region of t: the Bayes factor's bounds from bfpwr's `tbf01()` (as in
  `bayes_sequential()`), the p-value's from the t distribution; the
  chance of each pair of decisions is a probability of t between two
  values, from the noncentral t (as for the t-test's power). With no
  effect the p-value's share is exactly alpha, with the effect it is
  pwr's power, and a simulation written separately (`t.test()` and
  BayesFactor's `ttestBF()`) agrees cell by cell
  (`test-validation-bayes-companion.R`, `validation-log.md`). The table
  is exact; bfpwr's closed form, which the chances above it use so that
  they match the card's Bayes factor version, is slightly low (Known
  difference 6), so the two can differ by a few tenths of a point. The
  p-value side of the table is Student's t-test also when the plan uses
  Welch's with equal SDs and equal groups, where the two agree closely.
- **In the app.** "Add a Bayes factor?" sits under the answer on those
  designs' p-value results, with one button: the numbers take one to four
  seconds, so they are worked out when asked for. It shows the chances at
  both thresholds, the sample size for both, how often the two agree,
  advice on reporting both (name the main test in advance), wording for
  the plan with the p-value test as the main one, and a button switching
  the plan to the Bayes factor test.

## 2026-11-05 · The Bayesian planner on the cards, first part: priors (part 4)

- **Does the prior matter?** A Bayes factor t-test result now shows the
  same study's chances under its own analysis prior and JASP's three
  named widths of the default Cauchy prior (medium 1/sqrt(2), wide 1,
  ultrawide sqrt(2)), each the card's own bfpwr calculation with only the
  scale changed (`bayes_robustness()`). A wider prior finds small effects
  less often and shows there is no effect more easily; at sizes where the
  default prior can't give strong evidence for no effect at all, a wider
  one often can. The JASP reporting guidelines ask for this kind of
  robustness check.
- **The design prior in words.** Under "How unsure you are about the
  effect", the screen reads the SD as a range: about 95% sure the true
  effect is within 1.96 SDs of the effect entered (the normal design
  prior), so the number means something to someone who has not met a
  design prior before.
- **Informed analysis priors: not offered yet.** bfpwr's Bayes factor
  with an informed t prior (`tbf01()` with `plocation` away from 0) is
  exact, matching a numerical integration, but `powertbf01()` gives wrong
  power at small samples (1 where simulation gives about 0 at n = 3 and
  5; 0 against 5% at n = 10), agreeing only from about n = 30. A sample
  size search starting at the smallest n would stop at 3. The question is
  with the package (`upstream-questions.md`, bfpwr question 2). An exact
  calculation in the engine (the Bayes factor's thresholds on t, from
  `tbf01()`, and the noncentral t over the design prior, checked against
  simulation) is possible, but it is new maths for the maintainer to
  decide on.

## 2026-11-05 · Sequential designs on the Bayes factor t-test cards (part 4)

A Bayes factor t-test result offers "Check as you go?": the same plan as
a sequential design with the planned sample size as the largest, Schonbrodt
and Wagenmakers's design with a maximum N, from the engine's
`bayes_sequential()` (the Labs tool's, so the same validation:
`test-validation-bayes-sequential.R`). The researcher sets the first look,
the number between looks and the threshold for stopping for no effect;
the effect, its uncertainty, the prior, the threshold for an effect and
the direction come from the plan. It shows how often the study stops each
way, its size when it stops, and a single test at the maximum beside it.
Worked out on request (2,000 simulated studies each way, about a second).
The planned sample size stays the plan's: a sequential design is offered
as a way to run that study, not as a different answer to it.
## 2026-11-05 · Input screens: no empty boxes, and no SD for means in SD units

- **Empty boxes.** A box of fields whose fields are all shown only for
  some choices now hides with them (`group_shown_js()`), so choosing
  partial eta-squared, for example, no longer leaves an empty "The SD"
  heading on the screen.
- **Means in SD units.** Their SD is 1 by definition, so choosing "SD
  units" for the means fills in an SD of 1 and hides the question
  (`with_sd_units()`, on every screen with that choice and one common
  SD). Separate SDs for Welch's F are still asked, in the same units as
  the means.

## 2026-11-05 · Signal detection: d' in two conditions or groups (E72)

- **What:** a new card, E72, and design, `signal_detection / dprime`:
  whether sensitivity (d') differs between two conditions done by the same
  people, or between two groups, as in recognition memory or perception
  studies. Reached from Q1 ("That people tell a signal from noise better in
  one condition or group than another") and the "Other" family.
- **Why:** `next.md` item 5 (decided 4 November 2026, and the order on 5
  November 2026: signal detection first). No package plans this: sensR's
  `d.primePwr()` tests one d' against chance in sensory discrimination
  protocols, not a difference between conditions as psychologists analyse
  it.
- **Method (the maintainer's choice of a simulation, 5 November 2026):**
  powerkit's Spower experiment `p_dprime()`. People's hits and false alarms
  come from the equal-variance Gaussian signal detection model (yes on a
  signal trial with probability pnorm(d / 2 - c), on a noise trial
  pnorm(-d / 2 - c)), with each person's true d' drawn around the
  condition's average (correlated across conditions for the same people)
  and their criterion around its average. Each person's d' is estimated as
  researchers usually do, with the log-linear correction (Hautus, 1995,
  which found it less biased than the 1/(2N) rule), and the conditions are
  compared with the paired t-test or Student's t-test, the analysis most
  studies report. No new statistics: the model's definition, the published
  correction and the t-test.
- **Inputs:** the average d' in each condition, signal and noise trials per
  person, the SD of people's true d' (and for the same people, its
  correlation across conditions), and the average criterion and its SD (0
  by default: unbiased observers).
- **Validation** (`test-validation-signal-detection.R`, chunk
  `signal_detection`): a simulation written separately, drawing every trial
  as an evidence value against the person's criterion, agrees within Monte
  Carlo error in three cases, including one near ceiling where the
  correction matters most (88.7% against 88.1%, 88.0% against 88.7%, 59.5%
  against 58.5%). A published example is a placeholder for the maintainer.
- **Not covered yet:** rating-scale (confidence) designs, unequal-variance
  models, and d' fitted in a hierarchical model of the trials.
## 2026-11-05 · The About page, fetched before it is opened

The About page is about 1.5 MB of HTML (its table of every capability has
over 1,000 rows). It was built once per R process, but turning it into
text took 1.2 seconds at every opening, and the whole page then went
through the Shiny connection. Now the server builds it once as text,
just after the first visitor's first screen has gone out, and writes it
to a file (`about-cache/about.html`); the browser fetches that file in the
background once its first screen is up and puts it in the tab. Opening
About then takes about a third of a second. If someone opens the tab
before the file arrives, the server sends its finished copy as before.
Building it straight after start had delayed the first visitor's first
screen by about five seconds, so it waits for that screen.

## 2026-11-05 · Latent profile analysis: the chance of finding the right number of profiles (E58)

- **What:** E58 calculates. A new design, `mixture / lpa`: the chance that
  a study finds the right number of profiles (class enumeration), which is
  what sample size planning for a latent profile analysis is about (no
  significance test is involved). Its published guidance (Tein, Coxe and
  Cham, 2013; Nylund, Asparouhov and Muthén, 2007; Nylund-Gibson and Choi,
  2018; Spurk and colleagues, 2020) stays on the card.
- **Why:** `next.md` item 5, the second of its designs in the order the
  maintainer chose on 5 November 2026. No package plans it.
- **Method (the maintainer's choice of a simulation, 5 November 2026):**
  powerkit's Spower experiment `p_lpa()`. People are drawn into k profiles
  with the given shares (sizes vary from study to study, as in the
  published simulations) and their indicators are independent normal
  scores with SD 1, profile j's mean being (j - 1) times the separation on
  every indicator, as in Tein, Coxe and Cham's design. mclust (a new
  dependency, CRAN, base R only) fits its EEI models, the usual latent
  profile model with equal variances and local independence, with 1 to
  k + 1 profiles, and the BIC chooses. The share of studies choosing k is
  the "power"; the experiment returns 0 or 1, so Spower counts it. The BIC
  is used because it did best, with the bootstrap likelihood ratio test,
  in those simulations; the bootstrap test fits every model many times
  per study and is too slow to simulate here.
- **No alpha:** forms take `no_alpha` (the alpha questions are left out
  and "Target power" is relabelled), the spec has no `target_test >
  alpha` (method `bic`, like a Bayes factor), and the result reads as the
  chance of finding the profiles, not power to detect an effect.
- **Validation** (`test-validation-lpa.R`, chunk `lpa`): the same model
  fitted by an expectation-maximisation algorithm written separately
  (started from k-means, BIC by hand) on studies drawn separately; a
  published table from Tein, Coxe and Cham is a placeholder for the
  maintainer.
- **Not covered yet:** yes/no indicators (latent class analysis), profiles
  that differ in other patterns or in their spread, and correlated
  indicators within a profile.

## 2026-11-05 · Exploratory factor analysis: recovering the factors (E73)

- **What:** a new card, E73, and design, `factor_analysis / efa`: the
  chance that an exploratory factor analysis recovers every factor's
  loadings. Reached from Q1 ("That a questionnaire's items form the
  factors you expect, found by exploratory factor analysis") and the
  latent-variables family.
- **Why:** `next.md` item 5, the last of its three designs in the order
  the maintainer chose on 5 November 2026. An EFA has no significance test
  to power; the sample-size literature asks whether the loadings are
  recovered, which depends on the communalities and the items per factor
  more than on any people-per-item rule (MacCallum, Widaman, Zhang and
  Hong, 1999). No package plans it.
- **Method (the maintainer's choice of a simulation, 5 November 2026):**
  powerkit's Spower experiment `p_efa()`. Data come from the common factor
  model with simple structure (each item loads the same amount on one
  factor), the factors correlating as given. psych's `fa()` is fitted with
  its defaults (minimum residual, oblimin rotation), following the package
  most researchers in R use; each true factor is matched one-to-one to an
  estimated factor (the matching that makes the congruences largest in
  total, sign ignored); a study succeeds when every factor's Tucker
  congruence reaches the level asked, .95 by default, the level at which
  Lorenzo-Seva and ten Berge (2006) treat factors as equal. Both sources
  are in `refs.bib`.
- **No alpha:** as for latent profiles (`no_alpha`, method `congruence`).
- **Validation** (`test-validation-efa.R`, chunk `efa`): fits by base R's
  `factanal()` (maximum likelihood, oblimin from GPArotation) on data drawn
  separately, with matching and congruence computed separately, agree
  within 0.03 (89.2% against 86.6%, 87.7% against 84.6%, 99.9% against
  99.8%): minimum residual recovers the loadings about three points more
  often than maximum likelihood at these sizes, so a plan for an ML
  analysis would be slightly optimistic (not offered as a choice yet); a
  published table from MacCallum and colleagues is a placeholder for the
  maintainer.
- **Not covered yet:** choosing the number of factors (parallel analysis,
  for example), cross-loadings, and items with different loadings.


## 2026-11-06 · Random-intercept cross-lagged panel model (E74)

- **What:** a new card, E74, and design, `panel / riclpm`: power for one
  lagged effect in a random-intercept cross-lagged panel model (Hamaker,
  Kuiper and Grasman, 2015), two scores measured at three or more waves.
  Reached from T1 ("Two scores measured over time, to see whether each
  predicts later changes in the other") and the multilevel and
  longitudinal family; E35's card now points to it.
- **Why:** `next.md` item 3, the step after growth curves in the order the
  maintainer decided on 4 November 2026 (powRICLPM, CRAN 0.2.1).
- **Method:** powerkit's Spower experiment `p_riclpm()` calls
  `powRICLPM::powRICLPM()` with one replication for each simulated study,
  so powRICLPM generates the data and fits the model (lavaan's maximum
  likelihood), and the experiment returns the Wald z test's p-value of the
  lagged effect from that fit's estimate and standard error. Wrapping
  powRICLPM in Spower, rather than calling it once for many replications,
  gives the design powerkit's own sample-size search, seeds, check run and
  R script; it costs about twice as long per study (0.13 s against 0.06 s
  at 200 people and four waves).
- **powRICLPM's conventions, kept:** the lagged effects are standardised
  (powRICLPM sets the within-person residual variances so every
  within-person part has variance 1); `constraints = "none"` by default,
  with the effect from the first wave to the second tested, as in
  powRICLPM's documentation, and the lagged effects held equal over time
  as an option; reliability 1 by default. powRICLPM has no default for the
  correlation between the random intercepts or the within-person
  correlation, so the screen asks for both rather than supplying one.
- **Route:** about 0.13 s per simulated study, so a preview (100 studies,
  about 15 s), a full run of power in the app (1,000 studies, about two
  and a half minutes), and a sample size by R script, as for mediation.
- **Checks:** a spec check refuses lagged effects that aren't stationary
  (powRICLPM's own condition) or that leave no valid residual covariance
  with the within-person correlation given; the check run fits one study
  of 20,000 people and compares the four lagged effects with the
  population values.
- **Validation** (`test-validation-riclpm.R`, chunk `riclpm`): a
  simulation written separately (data drawn in base R, the model written
  out in lavaan syntax) agrees with no allowance beyond Monte Carlo error;
  Mulder's (2023) illustration is a placeholder for the maintainer.
- **Not covered yet:** more than two scores, measurement error estimated
  in the model (the STARTS model), and the traditional cross-lagged panel
  model without random intercepts.

## 2026-11-06 · The online app: published daily, quiet tabs allowed to close, public pages on GitHub Pages

The online app runs on Posit Connect Cloud, which charges usage credits
for each hour an app runs (Basic, $19 a month: 100 credits). Between 1
and 5 November 2026 the app used 63 credits. The causes were in the
repository: Connect Cloud republished on every change to main (179 in
those days, as each merge was followed by a manifest commit), search
crawlers were invited to the app's address from 4 November, and from 5
November the page kept its connection open for as long as any tab stayed
open. Decided by the maintainer on 6 November 2026, on the condition that
the site stays findable by search engines.

- **Publishing:** the `online-app-manifest` workflow publishes to the
  `connect-cloud` branch Connect Cloud watches (5 November) once a day
  (04:23 UTC) instead of after every merge, and only when something the
  app runs (the app, the engine or `renv.lock`, tests aside) differs
  between main and `connect-cloud`; "Run workflow" publishes at once.
- **Keep-open message:** sent every 20 seconds only while the page is in
  view and has been used in the last 20 minutes, or while a calculation
  reports progress. A page left alone may lose its connection; its answers
  on an input screen come back from the browser's copy (5 November).
- **Search engines:** the pages they index (a new landing page, the guide
  and the sitemap) are static files in `site/`, published to GitHub Pages
  by the `site` workflow, and link to the app. The app's `robots.txt`
  disallows crawling, so crawlers no longer start the app.
- **Not changed:** the host. With these changes the credits measure real
  use; whether real use outgrows the plan, and what to move to then (a
  fixed-price server, `hosting-options.md`), is for when there are usage
  figures.

## 2026-11-06 · Interrupted time series (E45)

- **Decided by the maintainer** (`judgement-calls` E8, now archived): the
  recommendation. PITS 0.1.0's own test (nlme's `gls()` by maximum
  likelihood) rejects too often with no effect in short series
  (`upstream-questions.md`, PITS question 1), so powerkit simulates each
  series with PITS's `simulate_its_data()` and fits the same segmented
  regression with AR(1) errors by REML by default, reports the Type I
  error at the planned length beside the power, and offers PITS's own
  test as an option.
- **What:** E45 now calculates: design `time_series / its`, powerkit's
  Spower experiment `p_its()`. The level change and the slope change are
  tested by their t tests and both together by the F test of the two
  coefficients (PITS's likelihood-ratio test under maximum likelihood).
  n is the number of time points after the intervention, as in PITS
  ("the primary design lever"); the number before is an input.
- **The Type I error:** `its_type1()` simulates the same series with no
  change, as many as the power used, under the run's seed, and the
  result screen says how often the test finds a change that isn't there,
  and that part of the power is false positives when it exceeds alpha.
- **The search's limit:** a change is judged against the trend before the
  intervention, so with the points before fixed the power can level off
  below the target however many points come after (with 24 points before,
  the slope change's standard error stayed at the earlier trend's, 0.10,
  with 240 after). The search stops at 240 points after the intervention,
  where gls() still takes under a second (its time grows with the cube of
  the series' length), and explains the ceiling in plain words.
  `bracket_n()` takes the backend's limit and message for this.
- **Validation** (`test-validation-its.R`, chunk `its`): series drawn and
  fitted separately in the test agree with powerkit's REML route, and
  powerkit's maximum-likelihood route agrees with PITS's
  `calculate_power()`, with no allowance beyond Monte Carlo error; a
  published power table is a placeholder for the maintainer.
- **Not covered yet:** a breakpoint estimated from the data, several
  series, a control series, and other error structures than AR(1).

## 2026-11-06 · The smallest detectable effect for every ANOVA layout and for regression

- **What:** the sensitivity goal, decided first-class in judgement call G9,
  now reaches the one-way, mixed, factorial and three-factor ANOVAs
  (E18, E20, E21, E54, E55, E56) and multiple regression (E24).
- **ANOVAs:** the rule the 2x2 designs already used: keep the pattern of
  means entered and scale its deviations from the grand mean until the
  effect tested reaches the target power by Superpower's exact
  calculation. A code comment had left the one-way designs out ("which
  pattern to scale is not settled yet"); scaling the researcher's own
  pattern is the only choice that needs no pattern powerkit would have to
  invent. The result gives Cohen's f and the largest difference between
  the scaled means. Unequal cells and pairwise tests, which are simulated,
  still have no sensitivity goal.
- **Regression:** pwrss's `power.f.regression()` searched over the partial
  R-squared (no new formula); for R-squared against 0 it agrees with
  pwr's `pwr.f2.test()`. No effect size is needed, so the screen offers
  "I don't know my effect size"; an empty R-squared with all the
  predictors means no increase.
- **Why now:** a first-time-user pass (status.md) found the "I don't know
  my effect size" route only on the basic tests, while the ANOVAs and
  regression are among the commonest analyses.

## 2026-11-06 · Whole-study simulation: experiments analysed with a factorial ANOVA

- **Why:** the whole-study simulation covered a measured predictor or two
  groups (power4mome), so the commonest experiment in psychology, two
  conditions crossed with a second factor and analysed with a two-way or
  mixed ANOVA, could only be planned card by card, and the chance that
  both the main effect and the interaction come out significant was the
  guided plan's rule of thumb (as if the tests were unrelated). The
  maintainer's priority (6 November 2026): planning a whole study in one
  go for most psychology studies (`next.md` item 1).
- **What:** a whole-study spec can now give an `experiment` instead of
  `variables` and `population`: a factorial ANOVA design spec (one or two
  factors, between or within participants: templates oneway_between,
  oneway_within, 2x2_between, 2x2_mixed, factorial_between,
  factorial_within, mixed), whose cell means, SD and correlation are the
  population. Each analysis is one of its F tests (`test: anova_effect`,
  with `effect` main_effect_A, main_effect_B or interaction).
  `run_whole_study()` runs Superpower's `ANOVA_power()` once per batch and
  reads every F test's p-value for every simulated data set from its
  `sim_data`, so each test's power and the joint power come from the same
  replications. No new statistics: Superpower builds the data and afex
  fits the ANOVA; powerkit counts. The sample size search is powerkit's
  `search_n()`, as for the other whole studies.
- **On the guided plan:** a condition with three or more groups, or two
  or three groups of a moderator crossed with a condition, measured once,
  and two conditions within participants crossed with groups of a
  moderator (or none), with a score outcome and no covariates or
  mediators, go to the experiment route. "The effect of X" is then the
  ANOVA's main effect of X, and the moderation its X x W interaction, as a
  researcher analysing a factorial experiment would test them; the card
  the plan opens for the effect of X alone (the t test, E2) ignores W.
  The screen asks for the levels, a grid of cell means, one SD and, with a
  within factor, one correlation. Two groups and no moderator stay on the
  power4mome route, as before.
- **Checks** (`test-whole-study-experiment.R`; 4,000 replications, the
  2 x 2 between example, N = 160): the main effect 35.6% and the
  interaction 35.0% against Superpower's exact 34.9% each; both
  significant together 12.7% against 12.3% from a simulation written
  separately with `stats::aov()` (and 12.2% if the tests were unrelated);
  Type I error 5.1% and 5.0% with equal means.
- **Not covered yet:** within factors with three or more levels on the
  guided plan (the plan's screening sends three or more conditions per
  person elsewhere), three factors, unequal groups in a design with a
  within factor, pairwise comparisons and contrasts as analyses.

## 2026-11-07 · What exports say: prototype status, methods only, one meaning of "validated"

- **Why:** the project review of 7 November 2026 found the methods
  paragraph carrying the evidence registry's codes, exports that did not
  say powerkit is a prototype, the whole-study paragraph without its
  effect sizes, references in user text that were not in `refs.bib`, and
  two meanings of "validated". The maintainer agreed the fixes.
- **Exports:** every exported sentence that names powerkit says "a
  prototype in development whose results are not yet fully validated"
  until version 1.0 (`powerkit_cited()`), since text copied out of the
  app loses its banner. The evidence record moves out of the methods
  paragraph into a worded "Validation evidence" section of the planning
  document.
- **Departures:** Departure 9 (the basic tests' formula) is retired, as
  it departs from no established tool, only from powerkit's own earlier
  default; its comparison stays under "Not departures, but worth stating"
  in `docs/conventions.md`. Departure 3 (about 1e-15) stays on the result
  screen and leaves the methods paragraph, which names only departures
  that can change a number.
- **References:** each author-year reference shown to users is either in
  `refs.bib`, opened by its DOI, or a package's `citation()`, or is taken
  out of user text. Seven were added; Anderson (2003), a textbook with no
  DOI, is cited in the engine's source comments only. A test in the app
  suite (`test-user-references.R`) keeps it that way.
- **"Validated":** one meaning, the validation log's ("What 'validated'
  means"), in CLAUDE.md, the README and status.md.
- **Assurance:** power averaged over a design prior is called "the
  average power over your uncertainty"; "assurance" in precision planning
  keeps its meaning (the chance the interval is narrow enough).


## 2026-11-07 · Design-finder routes: ANCOVA for randomised trials, moderation before and after, no one-answer questions

- **Why:** the project review of 7 November 2026 followed researchers'
  descriptions through "Help me choose" and found routes that ask
  questions with one answer, a two-group before/after study sent away
  when its groups are unequal, no recommendation between ANCOVA and the
  group by time interaction for a randomised trial, no route for a
  treatment effect moderated by a measured score in a before/after
  trial, and goals offered that the chosen test cannot answer.
- **Randomised before/after trials:** ANCOVA on the after score,
  adjusting for the before score, is marked recommended; the mixed
  interaction stays an option. With randomisation the groups are equal
  at baseline in expectation, so ANCOVA is unbiased and has more power;
  without randomisation the two answer different questions (Lord's
  paradox) and powerkit still asks rather than recommends.
- **Moderation in a before/after trial:** routed to the multiple
  regression card (E24), the standard adjusted analysis: the after score
  on the before score, the treatment, the moderator and their product,
  testing the product (one of four predictors). "Plan my whole study"
  uses the same card.
- **Crossover (AB/BA) designs:** guidance on the paired and mixed ANOVA
  cards (plan with the paired card's difference-score effect size;
  adding order as a factor uses the same differences with one fewer
  degree of freedom) until a dedicated card is built (`next.md`).
- **One-answer questions:** a question whose answers, given the answers
  before it, leave only one choice is skipped by an automatic node, and
  a test walks every route of the design finder to keep it so.
- **Goals:** a choice can be offered only with other answers
  (`choices_shown_if`); the justified significance level is hidden with
  a Bayes factor test version and refused in words if chosen anyway.

## 2026-11-07 · Effect sizes from one study: pilots like published studies, safeguard power read as repeated sampling

- **Why:** the project review of 7 November 2026 found that a pilot
  study's effect size met less scrutiny than a published one, although
  pilot estimates are the least precise source, and that a safeguard
  result's headline named the effect entered rather than the smaller one
  the calculation used.
- **Pilots:** "How you adjusted it" is shown and needed for a pilot as
  for a previous study (unless safeguard power is used), and the effect
  guidance says a pilot is for feasibility, citing Albers and Lakens
  (2018) on the bias of planning from pilot effects. The meta-analysis
  guidance prefers bias-adjusted estimates (Carter et al., 2019).
- **Safeguard wording:** the bound is described by repeated sampling
  (across studies like the original, a bound found this way falls below
  the true effect at the protection rate), following Perugini, Gallucci
  and Costantini (2014), not as a probability that the true effect
  exceeds it.
- **Converter checks:** a t's degrees of freedom must match the study's
  size, since the conversion uses one and the safeguard value the other.

## 2026-11-08 · Speed: sample-size searches and the About page leave the app's own process

- **Why:** the project review of 7 November 2026 measured that a
  sample-size search on the common ANOVA, Welch and trend cards took 2 to
  20 seconds in the app's single R process, during which nobody else's
  screen moved; that the About page, built there after a restart, froze
  the first visitor's first click for about 7 seconds; and that rendering
  the fixed tabs for every visit made twenty people arriving together
  wait 13 to 16 seconds.
- **Searches:** every sample-size goal runs in a separate process (with
  the comparison line's two searches), while the background limit allows;
  at the limit it runs in the app's process rather than refusing, since a
  search is seconds, not minutes. A spare process with the engine and
  common backends loaded is kept ready, because starting R and loading
  Superpower takes two to three seconds; each process serves one
  calculation and is closed, so no state passes between visitors.
- **Pages:** About is built in a separate process at start-up (built in
  the app's process only if that fails); Labs, Updates and Feedback are
  rendered once with the app's theme; the methods map's library loads when
  the map is shown.
- **Hosting:** the measurements are in `hosting-options.md`; a host that
  runs two or more app processes is preferred (queue item 8).

## 2026-11-08 · Whole-study planning: the manipulation check, and a baseline in a study measured twice

- **Why:** the project review of 7 November 2026 found that a mediation's
  manipulation check (the effect of X on the mediator), a very common
  companion analysis that often sets the minimum sample, couldn't be
  planned beside it, and that answering "a baseline measure" for a study
  measured twice switched the whole-study simulation off although it is
  the same study as answering "None".
- **Manipulation check:** a new guided analysis, X on the mediator alone,
  on the card for a score outcome (the two-group comparison, the paired
  comparison, the one-way ANOVA or the correlation). The whole-study
  simulation fits it as M on X by OLS, tested by power4mome's
  `test_parameters()` (`x_m`), with one mediator; not adjusted for the
  outcome's first measurement, which is not the mediator's. Its power
  agrees with the two-sample t test's in a test.
- **Baseline:** measured twice, "a baseline measure" is the first
  measurement, which every analysis already adjusts for; other covariates
  are still outside the simulation.
- **Order of the whole-study simulation's next designs:** covariates;
  fully within-people designs; yes/no and other outcomes; nested data;
  pairs (`next.md`, item 1).

## 2026-11-08 · Whole-study planning: saving the plan, a rough curve, Cohen's d, one study plan

- **Why:** the project review of 7 November 2026 found that the guided
  plan and the whole-study inputs couldn't be saved; that the simulation
  couldn't say how many people a study needs without leaving the app;
  that a two-group predictor had to be entered as a standardised path;
  that the guided plan and the study plan were two separate plans on one
  screen; and that analyses of the same people on different cards never
  shared a sample size.
- **Saving:** "Save this plan" writes a `powerkit-guided-plan` file
  (answers, analyses, claim, the values entered for each analysis and the
  whole-study inputs). Like a draft it holds inputs, not results: card
  sample sizes are kept as a summary and calculations are run again from
  the same values and seed.
- **Rough curve:** `whole_study_curve()` simulates the whole study at five
  sample sizes (0.5 to 2 times the N entered, 200 replications each) for
  experiments and regressions, read by the claim's criterion. It is
  labelled rough (each power within about 7 points); the sample size to
  report comes from the script's search. Mediation is left to the script,
  since its intervals make even a rough curve take minutes.
- **Cohen's d for two groups:** `population > group_d` gives d for the
  outcome or the mediator; the engine finds the path whose large
  simulated sample (100,000 people, the spec's seed) gives that d, with
  `uniroot()`. This uses the engine's own implied-value routine rather
  than a conversion formula, since no sourced conversion is in
  `refs.bib`. The mediator's path is found first, as the outcome's d
  depends on it.
- **One study plan:** an analysis calculated from the guided plan joins
  the study plan itself, replacing its own earlier result.
- **Shared sample size:** the compatibility key keeps the sample unit,
  the design family, the grouping variables (with their names and
  levels), the allocation, attrition and fixed structure, and drops the
  outcome and the template. An independent t-test and two proportions on
  the same two groups therefore share one sample size; the plan still
  says that a shared count also needs the same population and schedule.

## 2026-11-08 · Input screens: target power, test versions, moderation's input, benchmarks

- **Why:** the project review of 7 November 2026 found target power
  pre-filled at 0.8 on two cards and empty on the rest; the test version
  in view on some cards and folded into Settings on others (hiding
  Fisher's exact test and Spearman's rho); moderation starting at four
  correlations most researchers don't have; and Cohen's small/medium/
  large labels in the help while that question was open.
- **Target power:** empty on every card, whatever the package's own
  default, because the target is the researcher's choice to justify; the
  result compares 80%, 90% and 95% power. Not a departure: no result
  changes for a given target.
- **Test version:** "Which test you'll run" is in section 2 on every card
  with more than one version.
- **Moderation:** asks "What do you have for the interaction?" and starts
  at the R-squared change, as papers report it and G*Power takes it; the
  correlations (InteractionPoweR's inputs) remain the other choice. The
  R-squared route's difference from InteractionPoweR is already shown and
  recorded (Known difference 7).
- **Benchmarks:** no small/medium/large labels are shown (`tree.yaml`,
  `effect_size_benchmarks: hide`); whether to offer bias-corrected
  planning stays a separate question.

## 2026-11-08 · Labs: one chart style, one frame per tool, links from results

- **Why:** the project review of 7 November 2026 found the Labs charts in
  R's default look beside the result page's (small keys over the lines,
  sideways axis numbers), the visualiser's curves cut off without saying
  so, two pairs of near-identical colours on the methods map, three ways
  of labelling a Labs tool, and the two teaching tools reachable only
  through Labs.
- **Charts:** one style in `app/routing/R/results.R` (`chart_start()`,
  `chart_axes()`, `chart_key()`), used by the result page and every Labs
  chart. A density has no axis numbers, since its height means little to
  a reader. The Type I error area is hatched so the overlap with power
  reads in greyscale; a cut-off curve and the rise at 0 with one degree of
  freedom are explained under the chart.
- **Methods map:** each test has a colour and a shape (`methods-map.yaml`),
  the colours kept apart (a test checks the distance), and "Any of these"
  joins "Other". Long family names have a short name for the map region
  (`tree.yaml`, `short`).
- **Labs tools:** each opens with its name and one notice: what it is for
  and how far it is checked (`labs_tools`, `labs_tool_head()`). Labs stays
  a home for research and teaching aids, as decided with the review.
- **Links from results:** the t-tests, the correlation and two
  proportions link to the power visualiser at the result's n, effect and
  alpha; two-group results also to "1,000 studies". The link says the
  picture is the textbook version of the test, so its power can differ
  slightly from the result's (Welch's test, unequal groups).

## 2026-11-08 · Labs' Bayesian planning and converter share the cards' code; the uncertain effect on Bayes factor results

- **Why:** the project review of 7 November 2026 found that Bayesian
  planning and the effect size converter repeated the main cards with
  their own code and words, and that the design prior (planning over an
  uncertain effect) was easy to miss on the cards.
- **Decided with the review:** both tools stay in Labs as stand-alone
  tools, sharing the main app's engine code and wording.
- **Shared code:** `bfpwr_chance()` (backend-bfpwr.R) is the one bfpwr
  call for the chance of strong evidence. The cards, `bayes_planning()`
  and `bayes_sequential()`'s fixed comparison all use it, and a test
  checks that Labs and the card give the same numbers for the same
  study. No number changed (checked against the previous code before
  the change). The converter already used `convert_effect()` and
  `safeguard_effect()`; it now also gives the cards' safeguard sentence.
- **Uncertain effect on the cards:** a Bayes factor t-test planned for
  exactly one effect (design prior SD 0, powerkit's default, Departure
  15) offers "Not sure of the effect?": the user gives an SD and sees the
  chance of strong evidence averaged over it (assurance; O'Hagan, Stevens
  and Campbell, 2005) and the sample size for the target on average, from
  `run_spec()` with `population.effect_sd` set. The plan doesn't change,
  and powerkit suggests no SD, since the size of one's uncertainty is the
  researcher's to defend.

## 2026-11-08 · Docs and start-up reading: rules in one place, current-state pages, one precision rule

- **Why:** the project review of 7 November 2026 found that a new thread
  read about 70 KB before starting, that `status.md` and `next.md` had
  become histories, that the working rules disagreed between `CLAUDE.md`
  and `handover.md`, that the docs map missed six pages, that the
  dependency counts were old, and that the app worked out simulation
  precision by a different rule from the engine.
- **Decided with the review (7 November 2026):** locally, run the tests
  for the changed files plus `test-repo-consistency.R`, and let the
  required checks be the gate; "work from `next.md`" replaces "one build
  phase at a time"; single-card packages move to Suggests card by card
  when a PR touches them; very large files are split only when a PR
  touches them; a short visual style section in `accessibility-review.md`.
  All are now in `CLAUDE.md`, with the file layout in
  `routing-prototype.md`, "Splitting the large files".
- **Pages:** `status.md` is one short paragraph per area (under 8 KB; the
  old page is in `archive/status-history.md`); `next.md` rows say only
  what is left; `handover.md` points to `CLAUDE.md` for the rules and
  keeps only where things live; `docs/README.md` lists every page, with a
  group for the statistician, and a test checks it stays complete.
- **Dependencies:** `docs/dependency-footprint.md` is written by
  `scripts/dependency-footprint.R` from `renv.lock` and `DESCRIPTION`
  (58 Imports, 304 locked packages), and a test checks the page matches.
- **Precision:** `simulation_margin()` in the engine is the one formula,
  1.96 times the binomial standard error, stated at 50% power (the widest
  margin) unless a power is given. The app calls it rather than computing
  its own.
- **Manifest:** `app/routing/manifest.json` is removed from main and
  ignored there; the publishing workflow writes it on `connect-cloud`,
  and `prepare-publish-branch.py` works with or without a tracked copy
  (its test covers both).

## 2026-11-08 · Change notes in files of their own; the version set when a batch closes

- **Why:** the project review of 7 November 2026 found that since 1
  November 26 of 32 pull requests needed a catch-up merge from main,
  almost all over the tops of `engine/NEWS.md`, `whats-new.yaml`,
  `DESCRIPTION` and `CITATION.cff`, each costing a conflict read and
  another round of checks.
- **Decided with the review (7 November 2026):** one small change-note
  file per pull request, joined by a script and checked by the tests, with
  the version and NEWS heading set once when a batch closes.
- **How:** engine notes go in `engine/news.d/<topic>.md` (left out of the
  built package) and Updates entries in `app/routing/whats-new.d/<topic>.yaml`,
  which the app shows at once. The pull request that finishes a batch runs
  `scripts/close-batch.R minor` (or `patch`, or a chosen number), which
  sets `DESCRIPTION` and `CITATION.cff`, writes the notes under one NEWS
  heading, moves the Updates entries into `whats-new.yaml` and deletes the
  files. Every note waiting on main joins that version.
- **Releases:** from 0.45.0 a version's tag goes on the commit that set it
  (`scripts/tag-releases.sh`); earlier versions keep the last-commit rule
  they were made under.
- **Trade-off:** between closes, main's code is newer than its number, so
  a result computed then records the previous version (with its spec hash
  and seed). Batches are therefore closed as soon as their last pull
  request is ready. Recording the engine's commit beside the version
  would remove the ambiguity; it is a question for the maintainer.


## 2026-11-08 · Welch's t-test by default on the two-group card

- **Decided with the review (7 November 2026):** the two-group t-test
  plans for Welch's t-test by default, worked out by formula, with
  Student's as a choice, recorded as a departure from G\*Power
  (`conventions.md`, Departure 21) and cited to Delacre, Lakens and Leys
  (2017, `Delacre2017_welch`), who recommend Welch's test by default
  because it keeps the false-positive rate when the groups' spreads differ
  and loses almost nothing when they don't.
- **The formula by default:** pwrss's `power.t.welch()`, which the
  `welch_spreads` validation chunk checks against simulated studies, now
  answers unless simulation is asked for; Spower's simulation stays a
  choice. With equal spreads and equal groups it gives Student's answer
  exactly (its df are n - 2); with unequal groups Welch's needs a few
  more people (147 rather than 144 for d = 0.5 with group 2 twice the
  size of group 1, `test-welch-default.R`).
- **Nothing lost by the default:** the smallest detectable effect (d
  searched with pwrss's own power, as for regression) and a justified
  alpha (JustifyAlpha on `power.t.welch()`) now cover Welch's test, with
  scripts that reproduce both. Two things stay with Student's test only:
  the critical effect size, which for Welch's test depends on the sample
  variances (1 November 2026), and joint power for several outcomes,
  which uses PUMP's pooled-variance t-test (the study plan now says to
  choose Student's test for it).
- **The one-way ANOVA:** Welch's F becomes its default too (maintainer,
  8 November 2026: follow best practice), in the next pull request of
  this batch (`next.md`, R12b).

## 2026-11-08 · Welch's F by default on the one-way ANOVA card

- **Decided by the maintainer (8 November 2026: follow best practice):**
  the one-way ANOVA card plans for Welch's F by default, with the
  classical F test as a choice, recorded as a departure from G\*Power and
  Superpower (`conventions.md`, Departure 22) and cited to Delacre, Leys,
  Mora and Lakens (2019, `Delacre2019_welch_f`), who recommend Welch's F
  over the classical F test by default.
- **Simulated, because no package has a formula:** Welch's F's power is
  simulated with Spower (`p_anova.test(var.equal = FALSE)`), as it was as
  a choice. No R package gives it in closed form, and the published
  approximations are not implemented in one, so none is written into the
  engine. With one SD of 6 and means 10, 11 and 13 it needs 231 people
  for 80% power against the F test's 228 (`test-welch-anova-default.R`).
- **Nothing lost by the default:** the smallest detectable effect, which
  the F test has exactly, is now simulated for Welch's F
  (`welch_f_sensitivity()`): the pattern of means is scaled, starting
  from the F test's exact answer, and read from a probit curve of the
  simulated rejections, as the simulated sample size is, with a 95%
  interval and a script that reproduces it. Means in SD units now work
  with one SD for every group; the card asks whether the spreads are
  expected to differ, and only then for an SD per group.
- **When to choose the classical F test:** the card's note names a direct
  replication or preregistration that fixes it, or an ANOVA inside a
  larger equal-variance model, and suggests reporting Welch's F beside
  it, as the two-group card does for Student's test.
- **Still the classical F test:** the experimental whole-study plan's
  factorial experiments, which simulate every effect of one Superpower
  design together; Welch's F has no factorial form there.

## 2026-11-08 · Small telescopes for replications

- **Decided with the review (7 November 2026):** offer Simonsohn's (2015)
  small-telescopes plan beside safeguard power on the t-test and
  correlation cards (`next.md`, R13), and in the Labs pre-replication
  notes.
- **How, without new maths:** no R package plans a small-telescopes
  replication (RSmallTelescopes 1.0.4 analyses one that is finished), so
  powerkit composes it from pwr (d33: the effect the original study had
  33% power to detect) and pwrss (the replication's one-sided test of
  whether the effect is smaller than d33, for a true effect of 0, as a
  test against a margin). The answers match Simonsohn's rule of thumb of
  about 2.5 times the original sample (`conventions.md`, "Small
  telescopes for replications").
- **Student's test:** the replication's test is Student's t-test, as in
  the method and the original studies it is usually applied to, whatever
  version the card has selected; the card's note says to report Welch's
  test beside it. The Labs panel says to run the test the original used.
- **What it doesn't do:** it plans the test of d33 only. Power to detect
  the original effect, if it is real, is a separate plan, and the result
  says so.
- **The original's own significance level (0.47.2):** d33 is worked out
  at the level the original study used (0.05 unless the user gives
  another), and only the replication's test uses the card's alpha, as in
  Simonsohn's definition of d33 as the effect the original study had 33%
  power to detect. One alpha for both had made a stricter replication
  smaller (38 rather than 96 per group at .005 for an original of 20 per
  group).
- **What a result claims (0.47.2):** the result, the choice note and the
  Labs sentence say that a result below d33 means a study the size of the
  original could not reliably have detected an effect that small, not
  that the original was a false positive (Simonsohn, 2015, p. 567), and
  that it bears on the original only as far as the replication recreated
  its conditions (manipulation, its strength, measurement, sample). "How
  sure can you be?" shows the power if the true effect is a quarter, half
  or three quarters of d33, since the plan assumes exactly 0. The "about
  2.5 times" rule of thumb is named once, as Simonsohn's, beside the
  computed ratio.


## 2026-11-08 · The review's checks, kept for releases

- **Decided with the review (7 November 2026):** keep the review's
  property checks over every example spec and its run of every card in a
  browser, so they can be rerun before each release (`next.md`, R14).
- **Where:** `scripts/release-checks/` (the property checks, in R) and
  `app/routing/walkthroughs/every-card.js` with
  `every-card-list.R` (the browser run, beside the other Playwright
  scripts). Both exit with status 1 on any problem; how to run them is
  in `repository-protection.md`, "Checks before a release".
- **Not in CI:** each takes one to two hours, and the full validation run
  already covers the published values. A test in the app suite runs the
  property checks on one formula design and writes the card list, so
  neither script falls out of step with the engine or the forms
  unnoticed.
- **Changed from the review's versions:** the browser run opens folded
  sections before filling a field and doesn't count the Bayes factor
  box, which stays empty until asked for, as a blank output; its
  thirteen "blank" findings in the review were that box.


## 2026-11-08 · Labs: a replication planner

- **Decided (8 November 2026):** build a replication planner, with its
  Bayesian goals, as its own Labs tool rather than a design card: a
  replication is a set of decisions (what counts as success, how far to
  trust the original's effect, how the new study differs), not one test.
  It comes after the pre-replication notes (Karhulahti et al., 2025),
  which stay their own tool and decide whether to replicate at all; the
  planner reads their study and smallest effect and includes the notes in
  its write-up, and is not offered when the notes end at "not worth
  replicating". It is in four sections that can be filled in any order
  and saved to a file, since a replication is rarely planned in one sitting.
- **Ways in:** "Replicate a published finding" on the start screen's aim
  question, the notes' "go ahead" and "redesign" outcomes, and the main
  route's signpost beside a previous study as the effect's source.
- **Goals:** Anderson and Maxwell's (2016) goals beyond significance, each
  planned with BayesRepDesign (Pawel, Consonni & Held, 2026): a
  significant result in the original's direction, a significant pooled
  estimate, agreement with the original, the replication and sceptical
  Bayes factors, and showing the effect is too small to matter (TOST,
  planned for no effect); small telescopes is the card's own calculation.
  ReplicationSuccess (Held and colleagues) was the other candidate; it
  adds the sceptical p-value, which BayesRepDesign also has (`ssdPs()`),
  so one package covers every goal. The sceptical p-value is left out
  for now: it is rarely used in psychology, and each goal shown needs
  words that explain it.
- **Three beliefs, side by side:** every goal is shown under the original
  estimate as reported, with its uncertainty, and shrunk towards zero
  (BayesRepDesign's conditional, predictive and empirical Bayes design
  priors), so the table shows how much the answer rests on trusting the
  original. The write-up's default belief is "with its uncertainty",
  following the paper's argument that ignoring the original's uncertainty
  makes replications too small; "as reported" stays for comparison with
  the usual power analysis.
- **Variation between studies:** none, or Kenny and Judd's (2019)
  representative 0.05, 0.125 and 0.20 in d, for the uncertain and shrunk
  beliefs. None stays the starting value here, so the planner's first
  table matches the usual analysis; the note under the field gives Kenny
  and Judd's argument that zero should not be the default. Whether to
  start at a non-zero value is the maintainer's call (the heterogeneity
  option for the t-test cards is the next queue item).
- **The normal approximation:** BayesRepDesign's model is normal, so the
  significance goal under "as reported" asks for slightly fewer people
  than the t-test cards (66 against 68 for d = 0.7); stated in
  `conventions.md`, "Replication planner (Labs)", on the result and in
  the methods paragraph.

## 2026-11-08 · Effects that vary between studies, on the t-test cards

- **Decided (8 November 2026):** the one-sample, two-group and paired
  t-test cards take an optional "how much might the true effect vary
  between studies", an SD in d (d_z for pairs), following Kenny and Judd
  (2019): a power analysis that assumes the new study's true effect is
  exactly the planned one ignores the variation between labs, samples
  and procedures, and Kenny and Judd show it changes the sample size
  needed (352 in total for 80% power at d = 0.3 with none, 830 with
  their "large" 0.20).
- **Method:** Kenny and Judd's published formula, not a simulation: no
  package computes power averaged over a normal distribution of true
  effects for a t-test (BayesRepDesign does it on a normal model for a
  replication of a given original, which is the Labs planner's job, not a
  new study's). Their paper notes that a conventional power program gives
  their answer when given the effective significance level and the
  adjusted effect, so powerkit calls pwr that way and writes no
  noncentral-t maths of its own. Checked against their worked example,
  their appendix function and an independent simulation
  (`conventions.md`, "Effects that vary between studies").
- **Scope:** Student's t-test, or Welch's with equal SDs (whose power then
  equals Student's on the card's own backend), for power, the sample size
  and the smallest detectable effect. Refused in plain words with rank
  tests, Bayes factors, simulation, unequal SDs and small telescopes
  (which plans for no effect). The other cards follow if it is useful.
- **Starting value (the maintainer's decision, 8 November 2026):** 0.05,
  Kenny and Judd's small variation, following their argument that zero
  should not be the default; emptying the field gives the usual analysis.
  It is Departure 23 (`conventions.md`), shown on the result whenever the
  variation is above 0 and stated in the methods paragraph: 376 people
  against 352 for d = 0.3 at 80% power. The field is hidden where the
  formula doesn't apply (rank tests, Bayes factors, minimum-effect tests,
  simulation, small telescopes, a justified alpha, the power curve), so
  those plans are unchanged; Welch's test with unequal SDs is refused in
  plain words, asking the user to empty the field.


## 2026-11-08 · Correlations that vary between studies, and the range on the result

- **Decided (8 November 2026):** the correlation card (E4) takes an
  optional "how much might the true correlation vary between studies",
  an SD on Fisher's z, following McShane and Böckenholt (2014), whose
  Appendix B gives power when the estimate's variance is its sampling
  variance plus the between-study variance. On Fisher's z the sampling
  variance is 1 / (n - 3), and powerkit gives pwr's `pwr.r.test()` the
  significance level and correlation that scale both its critical z and
  its z for r by q = se0 / sqrt(se0^2 + tau^2), the analogue of Kenny and
  Judd's effective alpha and adjusted effect, so no new maths beyond the
  scaling is written. Checked against the model written out directly and
  an independent simulation (`conventions.md`, "Correlations that vary
  between studies").
- **Starting value (the maintainer's decision, 8 November 2026):** 0.025,
  Kenny and Judd's rule for small variation (25% of a small effect,
  based on past meta-analyses and replication projects) applied to
  r = .1, for the same reasons as the t-tests' 0.05. It is Departure 24.
- **The range (the maintainer's decision, 8 November 2026):** a single
  starting value risks becoming a number copied without thought, as a
  "medium" effect has. So the t-test and correlation results also show
  the goal's answer with no, small, medium and large variation and with
  the value entered, and the field's help says that a meta-analysis's
  estimate of tau for the effect is better evidence than any of them.
- **Not yet on other cards:** two proportions, regression and ANOVA have
  no published power formula of this kind that a backend package can be
  given in the same way. McShane and Böckenholt (2014) define the
  variation per condition, not on the effect, and their 2016
  power-calibrated effect size plans for uncertainty about the effect
  rather than variation between studies. Each needs its own method
  choice, so they are not added here.

## 2026-11-08 · Bayes mode: an opt-in switch, Bayes factor versions first, a design prior by default

- **Decided (8 November 2026):** an opt-in "Bayes mode" switch on the start
  screen, for researchers who will analyse with Bayes factors. It keeps the
  5 November 2026 decision not to ask everyone "p-values or Bayes factors?":
  the switch is off unless chosen, and is kept for the browser tab only.
- **What it does:** every card with a Bayes factor version opens its input
  screen with that version chosen (the test version's note says why, and
  any other version can still be picked); a card without one says so
  before the input screen. Results already lead with the chance of strong
  evidence for an effect, strong evidence for none and misleading
  evidence, so they are unchanged.
- **A design prior by default (the maintainer's decision):** in Bayes mode
  every "how unsure you are" field starts empty, so the plan waits for the
  user's own SD and averages over the effects they think plausible
  (assurance; O'Hagan, Stevens & Campbell, 2005). powerkit suggests no
  value, as on the results screen, because any default SD would be one
  more convention; 0 still plans for exactly the value entered. Recorded
  under Departure 15 in `conventions.md`.
- **Still to come (`next.md`):** goals without a threshold (a posterior
  interval's width, or a region of practical equivalence), once a package
  that plans them has been checked, and Bayesian wording in methods
  paragraphs and scripts. Bayesian replication goals are in the Labs
  replication planner.

## 2026-11-08 · Bayesian write-ups, and a write-up for plans that report both

- **Decided (8 November 2026):** the methods paragraph and plain-words
  version of every Bayes factor result are worded as a Bayes factor
  design analysis (Schönbrodt & Wagenmakers, 2018), not as a power
  analysis with words swapped. The paragraph names the analysis prior
  (the prior the Bayes factor is computed with) and the design prior (the
  belief about the true effect the plan averages over) separately; says
  whether the design prior is a point or spread, and that a spread one
  gives assurance (O'Hagan, Stevens & Campbell, 2005); gives the
  probability of strong evidence for the effect, and, if there were no
  effect, of strong evidence for its absence and of misleading evidence;
  and speaks in the third person, as a paper does.
- **Both together:** a p-value plan with "Add a Bayes factor?" opened now
  gets a "Write-up for both": the card's own methods paragraph, then the
  Bayes factor as the pre-stated secondary analysis (its test and prior,
  the evidence thresholds, which analysis decides if they disagree, the
  probabilities at the planned size, how often both find the effect for
  the t-tests, and the size needed for both), with a full and a
  plain-words version. It uses the companion's numbers only; nothing new
  is computed.
- **Left for now:** goals without a Bayes factor threshold (next.md item
  20), at the maintainer's request.


## 2026-11-08 · Precision planning with assurance, and mediation's planned interval

- **Decided (8 November 2026):** on MBESS's routes of the precision card
  (d, a standardised mean, a standardised regression coefficient), the
  target width carries an assurance by default: the chance that the
  interval is no wider than the target. Its value starts empty, as target
  power does, with an optional reason. "Only on average", MBESS's
  expected width, stays as a choice. The result compares 80%, 90% and
  95%. Recorded as Departure 25 (`conventions.md`). Built 9 November 2026.
- **Mediation:** the planned test stays the Monte Carlo interval, because
  a bootstrap in every simulated study is too slow to plan with. Every
  mediation result and methods paragraph says that PROCESS reports a
  percentile bootstrap interval by default (Known difference 14). The
  `mediation_crosscheck` validation chunk measures the difference for
  simple mediation.
- **Why:** an expected width is an average, so about half of the studies
  planned for it get a wider interval. And a plan that never says its
  test differs from the usual analysis diverges silently (CLAUDE.md).

## 2026-11-08 · Conventional values start empty

- **Decided (8 November 2026):** the significance level (0.05 on every
  card) and the Bayes factor threshold (10 on 15 cards) start empty, as
  target power does. A button beside each fills in the usual value in one
  click, and an optional reason goes into the methods paragraph. With no
  reason, the paragraph states the value alone ("α = .05"). It never says
  that no reason was given. The analysis priors keep their software's
  defaults (JASP's and bfpwr's), with a short question beside each on
  whether the default fits the field. Built 9 November 2026.
- **Why:** a filled-in convention is chosen without anyone choosing it.
  One click keeps the work small, while the choice stays the user's.

## 2026-11-09 · Whole-study planning: a planning document

- **What:** the whole-study result offers a planning document as the
  cards do (PDF by the browser's print, Word, Markdown), from the same
  Markdown: every analysis with its role, power and interval, the claim
  and its joint power, the population assumed, the values it implies for
  each analysis's own screen, Departure 13 in words, the full methods
  paragraph, the reproducibility record (seed, number of simulated
  studies, spec hash, check run, R and package versions) and, in full,
  the script `export_whole_study_script()` writes for the spec that was
  run, so the document alone reproduces its numbers.
- **Before the statistician's check:** offered now, because the document
  only gathers what the result already shows, and the result is already
  marked experimental. Its first page says the method has not been
  checked and that the numbers come from the quick look, with their
  Monte Carlo margin, and points to the full-run script for numbers to
  report.
- **Code in documents:** the printed page escapes every "<" before
  commonmark runs, so text a user typed can't become markup; inside code,
  commonmark escaped the "&" again and an R script's `<-` read as
  `&lt;-`. That second escape is undone inside `<code>` only, which keeps
  the text escaped. Word keeps a code block's lines apart with line breaks.

## 2026-11-09 · Preparing the engine for CRAN

- **Decided (9 November 2026):** prepare the engine for a CRAN release,
  and move every backend that only some designs use from Imports to
  Suggests in one pull request. This replaces the rule of 7 November 2026
  that a backend moves only when a pull request next touches its card
  (`dependency-footprint.md`), which would have taken months. The
  maintainer address in `DESCRIPTION` is one the maintainer reads, since
  CRAN writes to it when a change in another package breaks powerkit.
- **Why:** every package the engine uses is already on CRAN, so nothing
  blocks a release, but `R CMD check --as-cran` reported "Imports includes
  55 non-default packages" and asks for as many as possible to be used
  conditionally: if any package in Imports leaves CRAN, so does powerkit.
  A CRAN release lets researchers install powerkit with one line and cite
  a fixed version, and gets it checked on every R version CRAN tests.
- **How:** 30 packages moved (25 non-base Imports remain). Each run
  checks the packages its backend lists before calling any of them
  (`need_packages()`), because a simulation that counted a failed call as
  a failed replication would give a wrong power rather than an error; a
  missing package stops the run with a plain message naming what to
  install. The online app's manifest includes every Suggests package
  through `app/routing/optional-packages.R`, checked against
  `DESCRIPTION` by `test-repo-consistency.R`. On CRAN, `tests/testthat.R`
  runs a quick set of test files, since the full suite takes hours of
  simulation; GitHub's checks run every file. With the moved packages
  uninstalled, every example spec that could use one either ran or
  stopped with the missing-package message, and `R CMD check --as-cran`
  (with the examples in `\donttest{}` and the CRAN test set) passed, apart
  from the notes a first submission always gets.
- **When to submit** is a queue item (`next.md`); the recommendation is
  the 1.0.0 release.

## 2026-11-10 · Broad first-release scope and evidence

Aim for more than 99% of primary quantitative analyses in a defined,
representative psychology benchmark, including complex challenge cases.
Powerkit remains a general research tool. This is a target, not measured
coverage or a reason to narrow the benchmark after failures. Implementation,
case-specific evidence, whole-study claims and usable completion are
separate assessments. Source choices are generated for discovery; the
existing evidence registry remains authoritative. The benchmark and release
gates are in [v1-support-plan.md](v1-support-plan.md); P0 audits and
investigation of the two recurring failures lead next.md.


## 2026-11-10 · Explicit variation scenarios, usual power first

The maintainer approved starting new ordinary t-test and Pearson correlation
plans with between-study variation empty. The earlier nonzero defaults
(Departures 23 and 24) changed the meaning of the reported power without an
intentional choice. Variation remains supported and important to examine;
zero is not asserted to be universally realistic. Nonzero entries average
significance across differing true effects and can raise or lower the answer.
They are not automatic protection against underpowering at the entered effect.
Saved values and the existing engine calculations are retained.

The smaller/larger-effect comparison stays prominent and now displays power
at the actual analysed sample size for each assumption, using the existing
engine, without interpolating from the plotted grid. No variation magnitude
or alternative effect is selected on the researcher's behalf.


## 2026-11-10 · Match mediation planning to the intended analysis

The maintainer asked for both ordinary mediation and PROCESS-style
planning. The forms expose estimator and interval together: existing ML
Monte Carlo (default), existing ML percentile bootstrap, and explicit OLS
casewise percentile bootstrap. PROCESS is a mediation workflow rather than
a different design. Use power4mome's documented lm route, not a new power
formula. Keep selected settings in the result, methods, saved plan and
standalone script. OLS bootstrap starts at 5,000 resamples unless the user
provides a count; existing method defaults and saved specifications retain
their meaning. The scope is complete independent observations in the
displayed supported models, not every PROCESS option or direct software
equivalence. Paired independent regression checks, null calibration and
an archived PROCESS reference are separate evidence requirements; no
whole-card validation status is promoted by implementation alone.

## 10 November 2026 — conventional names in compact mode

With Explanations off, analysis and family headings use curated conventional
names without instructional suffixes or duplicate plain-language subtitles.
Explicit technical_name/technical_label metadata preserves the detailed
documentation and search aliases. Cards, forms and recent entries share
the same display names; old recent entries resolve names from the current
catalogue. Common method choices use short test names, with assumptions
and implementation details in guidance rather than the label. Selected
method identifiers, stored studies, calculations, status and scientific
warning visibility are unchanged. Explanations remain on by default.

## 10 November 2026 — restrict crossover guidance to the actual model

The ordinary paired card does not estimate period, sequence or carry-over
terms. Remove the claim that an adjusted crossover costs just one df and
is therefore a close approximation. State the restriction on both the
paired and mixed cards and input screens, and in the paired methods text.
No new crossover capability or numeric adjustment is introduced. A
dedicated model remains queued. Dwan et al. (2019), verified in refs.bib,
distinguish the simple paired analysis's assumptions from other crossover
analyses.

### Planning safeguards, 10 November 2026

Use the existing sufficient unknown-dependence target for new all-required-test
plans; independent significance decisions require an explicit choice. Preserve
historical saved calculations. Surface selected-setting evidence before
calculation and known corrected-ANOVA limitations throughout the workflow.
Offer matched fixed-N checks for approximate interaction sensitivity,
exact-data corrected ANOVA and simulated corrected-count sample sizes.
The four independent fitted-N count checks are archived, including shortfalls:
a fitted search and its interval must not imply a guaranteed attained power.

### Pre-sharing input and result clarity, 10 November 2026

Known numerical-method limitations must appear when the affected method/type
is selected, even while effect or sample-size inputs are incomplete, and
precede the result headline. Preserve the same limitations in exported text.
An explicit 80% target-power shortcut does not prefill the target or choose
an effect assumption. Explain the existing paired change-score-SD route when
the correlation is unavailable. This round changes no statistical formula
or analysis default and does not close the scientific validation requirements.

### Pre-tester review fixes, 11 November 2026

Group sizes given as a decimal ratio are planned as the simplest whole
split that rounds to the ratio as typed when the exact split would move the
total in steps above 50 (0.67 as 2:3); the result and write-up state the
split used. This replaces "always honour the typed ratio exactly", which
returned up to a full step too many people. A search over rounded group
sizes at every total is queued in `next.md`. Non-inferiority t-tests are
planned as the one-sided t-test of the difference against the margin (a
central-t null), the test researchers run, not pwrss's noncentral-null
`margin`; minimum-effect tests keep pwrss's form (Known difference 10; changed 12 November 2026, see below)
until that is decided separately. A search that cannot reach the target
because power does not rise with n says so.

Saving, the R script and the write-up no longer require a written reason
for the effect size: a required text box produces filler, and a blocked
export stops a plan being shared for criticism. The write-up states "No
justification for the effect size was recorded." instead. Explanations
stay on by default once the basic screens are cut to about 450 words. The
alpha box stays empty by default and the result is to show what another
level would cost. A Bonferroni option for related tests is to be offered
under separate claims. Prototype warnings stay, with one line for testers
on the start screen. Between-study variation stays, folded. The claim
setting stays folded for this round.

An effect size taken from a convention can be recorded as one
(`effect_justification.type = "convention"`), with advice that it is not
evidence about the effect: without it, a researcher using Cohen's
benchmarks had to record the value as a smallest effect of interest.
Finding the smallest detectable effect asks for no effect-size source.


### Sphericity correction by default, 11 November 2026

When a repeated-measures design's SDs or correlations are entered as
different, the app plans for the Greenhouse-Geisser corrected F test
unless the user chooses Huynh-Feldt or none (Departure 26 in
`conventions.md`). The earlier default, no correction, followed
Superpower's argument default, but the uncorrected test is not valid once
sphericity fails: in the review's example it rejected a true null 6.7% of
the time at alpha = .05, and its power (80.5%) was shown beside no warning.
"None" stays as a choice and carries a warning. The corrected power from
Superpower's exact data set is itself an approximation (a few points off
in either direction in the two recorded checks), which the result states
and the simulation route checks; the open mixed-design discrepancy in
`validation-log.md` is unchanged by this.

### Exact method for the correlation, 12 November 2026

A Pearson correlation is planned from the exact distribution of r (pwrss's
`power.exact.onecor()`), G\*Power's default, with pwr's Fisher's z as an
option (`options > correlation_formula`). This reverses the decision of 17
October 2026 to keep Fisher's z (Departure 10, now retired). That decision
rested on the two methods agreeing within 0.004 in power for r = .3 to .5;
outside that range they do not (r = .9, N = 6: 77.2% against 81.6%), the
exact method is in a package powerkit already calls, and a researcher
comparing powerkit with G\*Power met the difference on the first
correlation tried (85 against 84 for r = .3). A correlation that varies
between studies stays on Fisher's z, where McShane and Bockenholt's method
is defined, and its comparisons with no variation are made on the same
scale. The Labs power picture still draws Fisher's z curves.


### Significance level: the usual level labelled, two stricter ones beside it, 12 November 2026

The significance level stays empty on every card, with 0.05 one click
away and labelled as the usual level, as most studies in the behavioural and social sciences and their
readers use it. 0.01 and 0.005 sit beside it, with one line on when they
fit (many tests, or a surprising claim that needs stronger evidence), and
formula-based results show the sample size at all three. Three equal
buttons were considered and not adopted: they would suggest the three are
equally common, which would confuse more than it informs.

### Minimum-effect tests planned as the shifted t-test, 12 November 2026

The minimum-effect test versions of the one-sample, paired and two-group
t-test cards are planned as the test researchers run: a t-test of the
difference against the smallest effect of interest held fixed in the
outcome's own units (`t.test(mu = margin)`, TOSTER's
`t_TOST(hypothesis = "MET")`), a central t shifted by the margin. pwrss
computes its power when given the effect minus the margin, as for
non-inferiority since 11 November 2026. pwrss's own `margin` argument,
used until now, tests a margin held fixed in SD units and has slightly
less power (Known difference 10, now retired): for d = 0.5, a margin of
0.2 and 80% power it asked for 282 people where 278 are enough. A
two-sided test adds the small far tail from pwr's one-sided t-test, which
pwrss's one-sided test cannot give.

### The claim in view, with a correction for related tests, 12 November 2026

The claim question ("How many tests does your conclusion rest on?") moves
from Settings into the study section of every input screen, starting at
one test. It carries powerkit's position on multiple testing, which the
usual tools never ask about, and folded away it was rarely seen. A fifth
choice, several claims from a related group of tests corrected as a group
(Bonferroni), lets a researcher who holds the error-statistical view
(Mayo, 2018) act on it; the default for separate claims stays
uncorrected (Rubin, 2021), and both views are stated on the screen.
Screens opened from a study plan say the plan sets the claim.

### Simple mediation: a quick estimate first, the simulation for the report, 12 November 2026

The simple mediation screens (one mediator, X a score or two groups) start
on a quick estimate: the joint-significance test (both paths significant),
with power from pwrss's `power.z.mediation(method = "joint")` formula. It
is instant and gives a sample size, where the simulated Monte Carlo
interval needs about 12 minutes for power at one N and an R script for a
sample size. A researcher planning a study could otherwise get no number
in the app at all. The result says at the top that it is an estimate for
planning, how optimistic it is (with paths of .3 and N = 100: 75.0%,
against 72.4% for a simulation of the joint test with regressions and
71.1% for the simulated Monte Carlo interval), and how to get the number
to report: choose a simulated method. pwrss's default test, Sobel's, was
not used: it is much further from the simulated interval (58.3% at the
same settings). powerkit passes R-squared of Y with the 2 a b c'
term that pwrss's default leaves out (docs/upstream-questions.md).
Parallel, serial and moderated mediation keep the simulated methods only.

### Bayes factors: a switch where analyses are chosen, not a mode on the start screen, 12 November 2026

The "Bayes mode" switch on the start screen never showed which analyses
have a Bayes factor version (15 of 77), so a researcher found out card by
card. The switch, now "I'll analyse with Bayes factors", sits at the top
of "I know my analysis", where turning it on lists only those 15 designs
with the count, and on the first question of "Help me choose", whose end
card says whether the design has a Bayes factor version. What it does to
a card is unchanged: the input screen opens on the Bayes factor version
and asks how unsure the user is about the effect. A filter alone was
considered and not adopted: it would leave cards opening on the p-value
version and give "Help me choose" no way to plan with Bayes factors.

### Replication: a plan around the design's own card, and the original's design asked first, 12 November 2026

"Replicate a published finding" in the design finder went straight to the
Labs replication planner, which covers four designs (two groups, one
sample, pairs and a correlation). A researcher replicating any of the
other designs, such as a factorial ANOVA, a regression, a mediation or a
mixed model, reached a dead end. A replication needs two things: the
power analysis for the original's design, which only that design's card
can do, and a replication layer (scepticism about the published effect,
a goal, how the replication differs, and a write-up). The replication
planner is therefore to become a replication plan that wraps the card,
in the way the study plan does:

- The replication plan replaces the Labs planner as the way in; Labs
  keeps no separate replication tool once the plan exists.
- The goals table (BayesRepDesign; Pawel, Consonni & Held, 2026) is
  extended to any design whose focal effect is one number, from its
  estimate and standard error. The replication's standard error is the
  original's scaled by the square root of the ratio of sample sizes,
  which assumes the replication copies the original's design; for the
  four designs with an exact entry it must reproduce the existing table.
  A source for the scaling is to be checked in the package documentation
  before one is cited.
- All three beliefs about the true effect stay in view, with the shrunk
  belief first, because a published effect has been through selection.
- An original analysed with a Bayes factor is entered as the Bayes factor
  and the sample size, and converted to t with BayesFactor; a posterior
  is used as the estimate only when the original's prior was vague or a
  default.

The first step ships now: the finder's replicate aim asks the original's
design like any other aim. The four designs the planner covers are offered
it from their card, on the same design; every other card says it plans
the replication for a significant result again, and the input screen
starts with the effect's source as an earlier study. The other steps are
queue items in `next.md`.

### Welch's t-test: a critical effect size with equal groups, 12 November 2026

Perugini et al.'s (2025) critical effect size is defined for Student's
t-test. With equal groups, Welch's t equals Student's t whenever the two
groups' observed SDs are equal, and Satterthwaite's degrees of freedom
then equal n1 + n2 - 2, so the critical observed d is Student's exactly
under that condition. powerkit now reports it for Welch's test with equal
groups, stated as holding at equal observed SDs (with unequal observed
SDs it is a little different); a test checks that `t.test()`'s Welch
p-value at that observed d is alpha. With unequal groups Satterthwaite's
df differs from Student's even at equal SDs, so none is reported. The
smallest-effect result now gives the critical effect beside it, because
"the smallest effect you could detect" is often read as the smallest
result that would be significant.

### ANCOVA: Shieh's method shown as a difference from G*Power, 12 November 2026

The ANCOVA card plans with Shieh's (2020) method, which treats the
covariate as random; G*Power treats it as fixed and gives a slightly
smaller sample size. This was recorded in conventions.md but not shown on
the result. It is now Known difference 15, shown on every ANCOVA result
and in the methods paragraph. Shieh's method stays the default: in most
studies the covariate (such as a before score) is measured on people as
they come, not fixed by design.

### Routes say what their card can't do, 12 November 2026

A route through the design finder carries the user's answers (the aim,
the outcome, the number of measurements) to a card. Where the card can't
hold an answer, it now says so at the top, names the answer, and says
where to go, and is headed "The closest analysis powerkit has" rather
than "The analysis that fits your answers". This covers the equivalence
aim on cards without an equivalence test, the equivalence card for
designs it doesn't cover, non-score outcomes on score-only cards, and
Bayes factors on "Plan my whole study". Counts and ordered categories over
many trials now reach the repeated counts and ratings card (E75), whose
design they are. Building equivalence or other outcomes into those cards
is separate work; the note is the minimum so that no route drops an
answer silently.

### Tables of means entered in a labelled grid, 12 November 2026

Cards whose effect is a pattern of means, SDs or proportions across
groups and outcomes, conditions or factor levels asked for it as text,
one line per row and one number per column, with the order of rows set
out in the label. That is hard to follow and easy to get wrong in the
order. Each such table is now a grid: its rows and columns are named
from the levels the user has already typed (a count such as 3 gives
Group 1 to Group 3, as elsewhere), combinations of two factors are rows
named "first × second", and each box takes one number. An example shows
a filled grid, and one line says why powerkit asks for means: they can be
justified from earlier studies or from the difference that would matter,
and powerkit works out the effect size from them, where a single effect
size such as f or Pillai's V hides which differences it assumes. The
grid writes into the same text value as before, so checks, saved work,
drafts and exports are unchanged, and "Type it as text instead" shows the
text box for pasting. Means stay the default. Where a card already
takes one overall effect size (Cohen's w on the chi-square card, partial
eta-squared on the ANOVA and ANCOVA cards), a link beside the grid
switches to it; until now it was a choice under "Units of the means".
Cards without one (MANOVA, the within-participants factorial and the
logistic factorial) are separate work.

### MANOVA: Pillai's V as an alternative to the means, 12 November 2026

The MANOVA card asked only for each group's means on each outcome, with
the outcomes' SDs and correlation, because its power for three or more
groups was simulated and a simulation needs a population. Researchers
coming from G\*Power have a single effect size, Pillai's V, and no way to
use it. The card now offers "As an effect size: Pillai's V, as in
G\*Power" beside the means (and as a link beside the grid). Power is then
computed by the published formula G\*Power uses (Faul, Erdfelder, Lang &
Buchner, 2007, Table 5: Pillai's V with the O'Brien and Shieh algorithm
that paper recommends over Muller and Peterson's, f^2(V) = V / (s - V),
noncentrality N s f^2(V)), under CLAUDE.md's rule on published
closed-form results. It agrees with Spower's simulation of the same
MANOVA from means whose population V is known, and with two groups it
equals the exact Hotelling's T-squared. Means stay the default: they
show which outcomes are expected to differ and can be justified from
earlier studies, where one V hides the pattern it assumes and a
published V is a biased estimate, as the field's help says. The
smallest detectable V is available in the engine; the card doesn't offer
that goal yet, because the means route has none.


### Choosing an analysis: fewer screens and calmer cards, 12 November 2026

A design review found that "Help me choose" took seven screens to reach
the independent-samples t-test, the commonest design, and that "I know my
analysis" read as a long ladder of groups. Five changes, none of which
changes where any answer leads:

- For people measured once, "How many things did you vary or compare?"
  (F1) now also asks how many groups, under "One thing", and offers the
  several-outcomes designs (E59, E60) under "Several outcomes at once".
  F2 is no longer a screen of its own for them, so the t-test, one-way
  ANOVA and MANOVA routes take one question fewer. People measured twice
  or more still answer "One" and go on as before (F2 is answered by S3).
- On the aim screen, "Test a prediction" is one wide card at the top and
  the other aims sit under "Or, if your study aims to…". The line
  warning that four screening questions come first is gone. A "Question
  N of M" count was tried and left out: the questions still to come
  range from one to eleven at the start and from one to four even at F1,
  so no honest total could be given.
- Question cards align their words at the top, a card under the pointer
  when a screen opens doesn't light up until the pointer moves (it read
  as already chosen), and the answers trail shows the answers only, with
  each question in the chip's tooltip and accessible name.
- The analysis list shows its groups in two columns on a wide screen,
  and its two dashed boxes ("None of these fit", "Not sure which?") are
  one closing line with both links.
- The search matches the names researchers use: "Cohen's f" and
  "cohens f" match each other, and the ANOVA cards, the regression card
  (f squared, R squared change, hierarchical regression), the chi-square
  card and the two comparisons of correlations carry those words. The
  mediation cards say "mediator", not "go-between".

### The input form: the goal as buttons, named answers still needed, one card style, 12 November 2026

The same design review found that the form's deciding question ("What
do you want to find out?") was a "Choose one" menu of long sentences,
that the bar counted the answers still needed without naming them, that
the effect section used four box styles, and that with explanations off
some info buttons stood on lines of their own. Changes:

- The goal and the test's direction are rows of buttons, each with a
  short title ("Sample size", "Power", "Smallest detectable effect";
  "Positive only", "Negative only", "Either direction") over the
  choice's full wording (R/choice-buttons.R). The menu stays underneath
  as the value the server reads, so drafts, checks and exports are
  unchanged, and a choice hidden by another answer leaves the buttons
  too. Every goal is shown; the review's "More goals" fold was not
  needed with five short buttons.
- The bar names the first answers still needed ("Still needed: your
  goal, significance level and 3 more") and its link goes to the first
  one.
- The effect and its source are white cards like every other group;
  blue borders are kept for focus and the chosen answer. "Don't know
  what effect to expect?" and "Not sure what number to put here?" are
  quiet lines rather than coloured panels.
- With explanations off, an info button that is not beside a field's
  label is a small link naming what it explains ("Hypothesis",
  "What this planning goal means"), not a bare button on its own line.
- The settings line uses short names ("Group 2 / group 1: 1 · Dropout:
  none · Seed: 1 · Change").

The review's other form findings (one line of help per field, D-11;
f-squared for regression, C-07) are separate changes.

### Multiple regression given by Cohen's f-squared, 12 November 2026

G*Power's multiple regression asks for Cohen's f-squared; the regression
card asked for R-squared values only (R-squared, R-squared with and
without the tested predictors, or a predictor's partial R-squared), so a
researcher with f-squared had to work them out. The card now offers "As
Cohen's f-squared, as in G*Power" for the sample size and the power. The
engine converts it, as it converts the other effect sizes given in
another form, with the effectsize package's f2_to_eta2() (f^2 / (1 +
f^2)): R-squared against 0, the partial R-squared of one predictor, and
for a tested set the R-squared with all the predictors given the
R-squared without them, R2_full = R2_reduced + partial (1 - R2_reduced),
so that (R2_full - R2_reduced) / (1 - R2_full) is the f-squared given.
The result and the write-up show the conversion. The power is the same
as for the R-squared values that give that f-squared, and equals the
noncentral F power with lambda = f^2 N
(engine/tests/testthat/test-effect-conversion-f2.R).

### The result said once, 12 November 2026

The result's answer card repeated the answer three or four times (the
figure, the headline, an "In plain words" paragraph, the comparison
sentences and the power at the whole sample size), in alternating dark
and grey text. It now shows the figure, then one sentence with its
plain reading ("If the true effect is the one you entered, about 8 in
10 studies like this would get a significant result"), then the sample
size at 80%, 90% and 95% power and at alpha .05, .01 and .005 as two
small tables with the level used marked, then one smaller "Details"
paragraph (the usual tool's answer, the power reached, the effect
size's source, how the number was found), then the notes. The plain
reading is part of the answer and is shown whether explanations are on
or off. "How it was calculated" keeps the checks and the differences
from the usual tools in view, as the conventions rule requires, and
puts the values and seed, the technical details, the versions and the
spec file under one "Technical records" fold. The R script is the
main download; the planning document, project file and citations are
equal buttons beside it, each explained in one line. After calculating,
focus moves to the "Your result" heading, so a screen reader starts at
the answer.

### One line of help per field, 12 November 2026

A field carried up to four layers of help, all in view: a prompt, a
paragraph of help, a "What this means and where to find it" fold, a line
on its starting value, and an optional reason box with its own help. Each
field now shows its label, its input and one line: its prompt where it
has one, otherwise the first sentence of its help. Everything else (the
rest of the help, the input guide, the starting value's source) opens
from an info button beside the label, closed to start with whether
explanations are on or off; with explanations off the line folds too.
The optional reasons for the write-up ("Why this significance level",
"Why this target power" and the like) are one closed "Add a reason for
the write-up" line. The effect size's own reason stays in view, because
the write-up and saved files say when it is missing.

### The replication planner's simple answer first, 12 November 2026

The planner asked for a goal, three beliefs about the true effect and
several settings before showing any number, and its result was a table
of six goals by three beliefs. Most people planning a replication first
want the sample size for a significant result again, the goal the
planner's other goals (Anderson & Maxwell, 2016) are compared with.
Section 1 now ends with a button that plans straight from the original
study, using section 2's settings, and the result opens with one
sentence: the sample size for a significant result again in the
original's direction if the true effect is as large as reported, and if
it is shrunk towards zero. Both beliefs are given, not only the
reported one, because planning on a published effect as reported
usually underpowers a replication. The numbers are the table's own;
the table and the other goals follow, so nothing is hidden.

### Results sooner: a warmed process, and the answer before its comparison, 12 November 2026

Colleague testing timed formula answers at 6 to 12 seconds online and
ANOVA designs at about 35. Timing the app locally showed where the time
went. Each calculation runs in a fresh R process, and that process's
first spec check compiles the JSON schema in V8: 1.3 of the 1.4
seconds of a t-test's sample size. The ANOVA cards' sample-size search
was followed by two more (80%, 90% and 95% power, for the comparison
table), tripling the wait. The spare process now runs one small example
while idle, so the checker and Superpower are ready. A search that takes
more than a second shows its answer at once, and the comparison's
searches follow and fill in the table. Nothing in the numbers changes.
Welch's ANOVA, the default for one-way ANOVA, is simulated (about 11
seconds here for a sample size) because no package has a formula for its
power. A published approximation could make it instant, but that is a
method choice and is queued, not made here.

### Welch's ANOVA by Levy's approximation, 13 November 2026

Welch's F, the one-way ANOVA card's default test (Departure 22), was
simulated with Spower because no package powerkit uses gives its power
by formula: about 11 seconds for a sample size locally and several times
that online, with Monte Carlo error. Delacre, Leys, Mora and Lakens
(2019) give Welch's statistic and degrees of freedom but study power by
simulation only. Jan and Shieh (2014) compare two published
approximations to Welch's F's distribution under the alternative, Levy's
(1978) noncentral F and Luh and Guo's (2011), across mean patterns,
variance patterns and group sizes, find Levy's within .01 of simulated
power in every case, and recommend it for power and sample size, with
R code in their appendices. powerkit now uses it by default
(`backend-welch-anova.R`), under CLAUDE.md's rule for a closed-form
result from a published source where no package has one. It reproduces
the paper's Levy powers (Tables 1 and 2) to four decimals and the
paper's equal-group sample sizes, and agrees with Spower's simulation
and with separately generated `stats::oneway.test()` studies within .01
plus Monte Carlo error. The simulation stays available as "How power is
worked out: Simulation" on the card (`options > method`), for anyone who
wants the answer from repeated studies. The test planned for is the
same, so this is not a departure from the established tools (G*Power and
Superpower have no Welch's F).
