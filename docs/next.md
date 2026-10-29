# What to work on next

*29 October 2026 (Ready items first; every card the app marks "not in powerkit" has an item, checked against a list of the tests psychologists most often report). The ordered answer to "work on the next thing". One
queue, newest decisions folded in; [`status.md`](status.md) says where the
project is, this says what to do.*

**How a thread uses this page**

1. Read the top of the queue. Take the **first item marked Ready**.
2. If an item says *Needs a decision*, it is not yours to start: say what
   the decision is and move to the next Ready item, or ask the maintainer.
3. Follow [`adding-a-test.md`](adding-a-test.md) for anything that adds a
   power analysis. One item per PR.
4. When an item lands, delete its row and say so in `status.md`.
5. **Check the top item still makes sense before starting.** This page is
   dated; a queue written three weeks ago can be stale, and the
   maintainer's priorities beat it.

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Simulated data sets for the remaining designs** | The CSV download and the R script's data section cover the basic tests, the rank tests, equivalence and non-inferiority, the Superpower ANOVA designs, Welch's ANOVA, planned contrasts, regression interactions, mediation, logistic and Poisson regression with one predictor, factorial logistic regression, ordinal outcomes and cluster trials with a score outcome (29 October 2026). Not yet, because the spec leaves part of the data's shape open: ANCOVA and R² (what the covariates or other predictors are), logistic and Poisson regression with other predictors, the three-way interaction (no package generator), multisite trials, yes/no cluster outcomes, a baseline covariate in cluster trials, SEM and McNemar's test (whose spec gives only the discordant proportions) | M | Needs a decision: for each, the data-generating choices (for example, one covariate carrying all of ANCOVA's R-squared), or leave them without a data set |
| 2 | **Moderated mediation with W on both links or the direct link (E38, PROCESS models 8, 58 and 59)** | Model 8 (W on X -> M and the direct path) has an index of moderated mediation, but manymome's `index_of_mome()`, which power4mome's test calls, refuses it (`upstream-questions.md`, power4mome, question 3). Models 58 and 59 (W on both links) have no single index: the indirect effect is quadratic in W | M | Needs a decision: for models 58 and 59, what to power (conditional indirect effects at chosen values of W, or their difference); for model 8, the answer to the upstream question
| 3 | **Whole-study simulation: the statistician's check** | Built on 27 October 2026 and in the app as an experimental option on the guided plan (power4mome; correlation, interaction, mediation and moderated mediation; a quick look in the app, and the full run and the sample size search from an R script). Before it is offered as more than experimental, a statistician goes through the method note and the cross-checks; then the other designs on the plan | M | Needs the maintainer: the statistician's check |
| 4 | **Multilevel: simulated models** | Predictors measured at both levels, cross-level interactions, and many trials per participant with items as random effects (E33, E41). mlmpower, simr or mixpower, as an R script to run | L | Needs a decision: which package, checked by a statistician |
| 5 | **Yes/no X in mediation and moderated mediation (E16, E17)** | Moderation with a yes/no X or W (E15) calculates since 29 October 2026. Still coming soon: mediation with a yes/no condition (E16) and moderated mediation with a yes/no X or W (E17), with power4mome (`x_fun` with `rbinary_rs()`; roadmap B12, B22). Decided 29 October 2026: standardised paths with the implied group difference shown, and the group split asked (50/50 by default) | M | Ready: E16 first; E17 also needs the answers on how power4mome standardises a binary W (`judgement-calls.md`, E4) |
| 6 | **Validation catch-up, the rest** | Six cards moved to validated on 27 October 2026. Eight still say "validation in progress": the one-way ANOVA, multiple regression R², one proportion and McNemar (in the engine's tests, not yet in the full run), ANCOVA, Poisson regression, goodness of fit and two independent correlations. Each needs a published example in its validation file and a full run | M | Needs the maintainer: the published values are theirs |
| 7 | **SEM: the test of close fit, and invariance with several factors** | Model fit, measurement invariance across two groups or two occasions, factor correlations and latent slopes are in the app (semPower). Still missing: invariance with several factors, more than two groups or more than two occasions, and the test of close fit (RMSEA no more than 0.05), which semPower doesn't compute | M | Needs a decision: which comes next; for close fit, a method and a package that computes it (left out for now, 29 October 2026) |
| 8 | **Repeated measures: sphericity corrections, unequal SDs and correlations** | The repeated-measures designs assume one SD and one correlation for every pair of conditions, so sphericity holds; the MANOVA approach is shown beside them (29 October 2026). Real data rarely look like that: a Greenhouse-Geisser or Huynh-Feldt correction, or a covariance matrix per condition, would let users plan for it. Mixed designs with unequal groups aren't covered either (Superpower's `ANOVA_power()` stops for them; the 2 x 2 between design takes unequal cells since 29 October 2026) | M | Needs a decision: which (Superpower takes a correlation matrix; the corrections need a method and package) |
| 9 | **Bayes factors beyond the t-tests** | The Bayes factor t-tests are in the app (bfpwr, fixed N). Sequential designs (BFDA, on GitHub only) and Bayes factors for other designs are not | M | Needs a decision: the package for sequential designs, and which designs next |
| 10 | **Point-biserial r and minimum-effect tests** | Two gaps users meet on existing cards: a point-biserial correlation (G\*Power A2, the two-group t-test with r given instead of d) and minimum-effect tests (showing an effect is larger than a smallest effect of interest, the counterpart of equivalence) | S | Needs a decision: whether point-biserial r is an effect-size option on the two-group card or its own card, and the method for minimum-effect tests |
| 11 | **Rank tests for repeated measures, and score shapes for the rank correlations** | Friedman's test (the rank-based one-way repeated-measures ANOVA, roadmap B26) is not computed: its card says the ANOVA figure only approximates it. And Spearman's and Kendall's correlations are simulated on normal scores only (29 October 2026), where their advantage over Pearson's r is in skewed or heavy-tailed data | M | Needs a decision: a package or simulation route for Friedman's test, and how to draw correlated non-normal scores |
| 12 | **Reliability and agreement: Cronbach's alpha, McDonald's omega, kappa, Krippendorff's alpha and ICC** | Scale development plans for a minimum internal consistency (alpha or omega above .70), and rating studies for agreement: Cohen's and Fleiss' kappa, Krippendorff's alpha and the ICC (roadmap B50: ICC.Sample.Size, presize, kappaSize). Nothing in powerkit covers any of them, and no card points to them | M | Needs a decision: the method (Bonett and Wright's approach is the candidate the roadmap names, unverified) and a package that computes it |
| 13 | **Trend tests: Cochran-Armitage and Jonckheere-Terpstra** | A linear trend in proportions across ordered groups (dose, age band), and its rank-based equivalent for scores; both on the roadmap's candidate list and asked for in dose-response and developmental designs | M | Needs a decision: package or simulation route for each |
| 14 | **Time-to-event outcome (E43)** | Relapse, dropout and disengagement timing; the card names Hmisc (`cpower()` for the log-rank or Cox test, `spower()` by simulation), the roadmap powerSurvEpi and npsurvSS too (B67) | M | Needs a decision: the test (log-rank or Cox) and the package
| 15 | **Precision planning (E46)** | Planning for a confidence-interval width rather than power, increasingly asked for by journals; MBESS's `ss.aipe.*()`, presize and Spower's precision criterion are candidates (roadmap B56) | M | Needs a decision: the package, and which estimates first (d, r, a proportion)
| 16 | **Longitudinal: three or more occasions (E35)** | Growth curves, random-intercept cross-lagged panels and experience sampling; the card names longpower, powRICLPM and PowerAnalysisIL (GitHub only) (roadmap B41-B43) | L | Needs a decision: which models first and which package for each, checked by a statistician
| 17 | **Designs that need a custom simulation (E30, E32, E39, E42, E44, E45)** | A moderator with three or more groups, non-score outcomes or mediators in moderation and mediation, a condition with three or more groups in mediation, dyadic data (APIM; the card's tool is a web app powerkit can't call) and interrupted time series. Each card points to Spower with a model the user writes | L | Needs a decision: per design, the data-generating model and the analysis (one PR each)
| 18 | **Robust and non-parametric group comparisons not yet covered** | From a review of the tests psychologists report: the Brunner-Munzel test (two groups, unequal variances), the aligned rank transform for factorial designs, Quade's non-parametric ANCOVA and PERMANOVA. None is on the roadmap yet; whether each has a power function or needs simulation is unchecked | M | Needs a decision: which are worth covering, and the package or simulation route for each
| 19 | **Pairwise and follow-up comparisons after an ANOVA** | Tukey's HSD, Games-Howell, Dunnett's test against one control, Holm or Bonferroni, and simple effects behind an interaction: studies are often powered for the omnibus F and analysed by these. Superpower simulates pairwise comparisons with a p-value adjustment (`ANOVA_power(p_adjust = )`; roadmap C1, unchecked) | M | Needs a decision: an option on the ANOVA cards or a card of its own, and which corrections
| 20 | **Regression variants: robust and quantile regression, multinomial and zero-inflated outcomes** | Regression with HC3 or HC4 standard errors, quantile regression, multinomial logistic regression and negative binomial or zero-inflated counts (roadmap B30 and the candidate list); likely by simulation with Spower's `p_glm()` or a user-written experiment, unchecked | M | Needs a decision: which first, and the route
| 21 | **Psychometric and cognitive models: EFA, latent profiles and classes, IRT and signal detection** | Exploratory factor analysis sample size (B52), latent profile and class analysis (B49), IRT and DIF (B51: irtpwr, irtsim) and signal detection sensitivity (d') in memory and perception tasks, which no row covers yet | L | Needs a decision: scope (which are planning questions powerkit should answer) and a package for each
| 22 | **Effect-size formats** | Users arrive with d_rm or d_av for repeated measures, omega squared or generalised eta squared from a published ANOVA, and powerkit takes one format per card (roadmap C9). Converting needs the correlation or the design, so each conversion must be checked against its source | M | Needs a decision: which formats, and where conversions are shown
| 23 | **Meta-analysis** | Power for a planned meta-analysis (fixed and random effects, moderator tests; metapower, roadmap B68), the one family on the list outside powerkit's single-study focus | M | Needs a decision: in scope or not
| 24 | **Critical effect size, and technical details for the remaining designs** | The technical details section (29 October 2026) gives df, critical value and noncentrality where pwrss, pwr (through pwrss) or Superpower's exact ANOVA report them. Not yet: semPower, powertools, TOSTER and bfpwr designs, and the correlation test (pwr's has no identical pwrss version). The critical effect size (the smallest observed effect that would be significant, d_crit or r_crit) is asked for by researchers who report it with a power analysis | S | Needs the maintainer: a reference for the critical effect size in `refs.bib` and the decision to show it (t-tests and correlations first, labelled as an observed value) |

## The direction behind the methods map

The map is the first step towards something larger the maintainer wants:
showing researchers the different ways a question could be answered, not
only the test that fits the design they have already chosen. Later nodes
need not compute anything. Row D1 (qualitative sample size) is marked out
of scope today because there is "no statistical test or estimate to plan
for", which is right for a calculator and wrong for a map: Malterud,
Siersma and Guassora's information power (Qualitative Health Research,
2016) justifies a qualitative sample size at the design stage through five
dimensions and explicitly is not a formula — exactly the kind of framework
powerkit could present honestly without inventing any maths. **D1 is
therefore a question for the maintainer again, not a settled no.** Its
reference has to go through `refs.bib` before it is quoted anywhere.

The first version (a pan-and-zoom diagram, `decisions.md`, 27 October
2026) is in Labs. Still to come there: charts on each analysis's page,
whether to add a sourced reading list per analysis (the maintainer's
call), and nodes for approaches powerkit doesn't compute.

## Fold into whichever PR touches the area

- Delete a design's row from `forms.yaml`'s `engine_only` when its card and
  input screen land (a test will fail if you forget).
- [`build-guide.md`](build-guide.md) section 8's phase table still reads as
  though phases 0-2 are the frontier; refresh it when next in that file.
- Raise the Spower faults upstream: the reproducible example is ready at
  `docs/upstream/spower-var-test.R`
  ([`upstream-questions.md`](upstream-questions.md)).

## Waiting on the maintainer, not a PR

- **Published values** (`TODO_PUBLISHED_VALUE`) for every validation file,
  and the full validation run on your own machine.
- **Six roadmap rows that need G\*Power itself** (A22, A38, A42, A46, A48,
  A49): the manual has no example for them.
- **The logistic R-squared question** (Known difference 3): whether
  powerkit's reading of "R² other X" matches G\*Power's.
- **Which batch comes after 1**, if the order above is wrong.
