# What to work on next

*31 October 2026: items 1, 3 to 9, 15 to 17, 19 and 24 decided and Ready. 30 October 2026 (the maintainer's order for the next work is items 1 to 10; Ready items first; every card the app marks "not in powerkit" has an item, checked against a list of the tests psychologists most often report). The ordered answer to "work on the next thing". One
queue, newest decisions folded in; [`status.md`](status.md) says where the
project is, this says what to do.*

**How a thread uses this page**

1. Read the top of the queue. Take the **first item marked Ready**.
2. If an item says *Needs a decision*, it is not yours to start: say what
   the decision is and move to the next Ready item, or ask the maintainer.
3. Follow [`adding-a-test.md`](adding-a-test.md) for anything that adds a
   power analysis. One item, or a group of closely related ones, per PR
   (`CLAUDE.md`, "Working process").
4. When an item lands, delete its row and say so in `status.md`.
5. **Check the top item still makes sense before starting.** This page is
   dated; a queue written three weeks ago can be stale, and the
   maintainer's priorities beat it.

## The queue

| # | What | Why it matters | Size | State |
| --- | --- | --- | --- | --- |
| 1 | **Joint power for study plans that mix designs: nested, repeated and dyadic studies** | The whole-study simulation gives joint power for independent people measured once or (since 31 October 2026) twice, with every analysis adjusted for the first measurement as an ANCOVA is; X a measured score or two groups: a group comparison with a moderation or mediation on the same people. Dyadic data have their own card since 1 November 2026 (E44, the actor-partner model, power4mome), with joint power for several of its effects in the same study (the dyadic whole study's first step). Not yet: a group variable correlated with the moderator (power4mome draws a two-group X on its own), three or more groups, studies measured three times or more, nested and dyadic designs | L | Ready (decided 31 October 2026): extend the whole-study simulation one design at a time (done: two groups; measured twice, including two mediators and moderated mediation); marked Experimental, and checked by a statistician later (below the queue), not before |
| 2 | **Bayes factors beyond the t-tests** | The Bayes factor t-tests are in the app (bfpwr, fixed N), and since 1 November 2026 Labs has Bayesian planning for them at a fixed N (analysis and design priors set apart; the three outcomes under the belief and with no effect; `bayes_planning()`) and sequential (`bayes_sequential()`, Schönbrodt and Wagenmakers's design with a maximum N, simulated with bfpwr's Bayes factor), with the sources in `refs.bib`. The test of one proportion (bfpwr; JASP's Beta(1, 1) prior, and JASP's one-sided test by default) and the correlation (BayesFactor's `correlationBF()`, the same Bayes factor as JASP's, with JASP's prior width by default) and two groups' proportions (BayesFactor's `contingencyTableBF()`, JASP's default contingency table Bayes factor) have Bayes factor versions since 1 November 2026. Not yet: the sequential design on the cards themselves, and Bayes factor versions of other cards (larger contingency tables, ANOVA) | M | Ready (decided 31 October 2026), with answers matching JASP's by default wherever JASP has the test. The binomial preprint the maintainer supplied (Kelter and Pawel, arXiv 2502.02914) asks not to be cited without the authors' permission, so it stays out of `refs.bib` until it is published |
| 3 | **SEM: the test of close fit, and invariance with several factors** | Model fit, measurement invariance across two groups or two occasions, factor correlations and latent slopes are in the app (semPower). Still missing: invariance with several factors, more than two groups or more than two occasions, and the test of close fit (RMSEA no more than 0.05), which semPower doesn't compute | M | Needs a decision: which comes next; for close fit, a method and a package that computes it (left out for now, 29 October 2026) |
| 4 | **Reliability and agreement: Cronbach's alpha, McDonald's omega, kappa, Krippendorff's alpha and ICC** | Scale development plans for a minimum internal consistency (alpha or omega above .70), and rating studies for agreement: Cohen's and Fleiss' kappa, Krippendorff's alpha and the ICC (roadmap B50: ICC.Sample.Size, presize, kappaSize). Nothing in powerkit covers any of them, and no card points to them | M | Needs a decision: the method (Bonett and Wright's approach is the candidate the roadmap names, unverified) and a package that computes it |
| 5 | **Time-to-event outcome (E43)** | Relapse, dropout and disengagement timing; the card names Hmisc (`cpower()` for the log-rank or Cox test, `spower()` by simulation), the roadmap powerSurvEpi and npsurvSS too (B67) | M | Needs a decision: the test (log-rank or Cox) and the package
| 6 | **Longitudinal: three or more occasions (E35)** | Growth curves, random-intercept cross-lagged panels and experience sampling; the card names longpower, powRICLPM and PowerAnalysisIL (GitHub only) (roadmap B41-B43) | L | Needs a decision: which models first and which package for each, checked by a statistician
| 7 | **Designs that need a custom simulation (E30, E32, E39, E42, E45, E65)** | A moderator with three or more groups, non-score outcomes or mediators in moderation and mediation, a condition with three or more groups in mediation, dyadic designs other than actor and partner effects (E65; the APIM itself, E44, calculates since 1 November 2026) and interrupted time series. Each card points to Spower with a model the user writes | L | Needs a decision: per design, the data-generating model and the analysis (one PR each)
| 8 | **Robust and non-parametric group comparisons not yet covered** | From a review of the tests psychologists report: the Brunner-Munzel test (two groups, unequal variances), the aligned rank transform for factorial designs, Quade's non-parametric ANCOVA and PERMANOVA. None is on the roadmap yet; whether each has a power function or needs simulation is unchecked | M | Needs a decision: which are worth covering, and the package or simulation route for each
| 9 | **Regression variants: robust and quantile regression, multinomial and zero-inflated outcomes** | Regression with HC3 or HC4 standard errors, quantile regression, multinomial logistic regression and negative binomial or zero-inflated counts (roadmap B30 and the candidate list); likely by simulation with Spower's `p_glm()` or a user-written experiment, unchecked | M | Needs a decision: which first, and the route
| 10 | **Psychometric and cognitive models: EFA, latent profiles and classes, IRT and signal detection** | Exploratory factor analysis sample size (B52), latent profile and class analysis (B49), IRT and DIF (B51: irtpwr, irtsim) and signal detection sensitivity (d') in memory and perception tasks, which no row covers yet | L | Needs a decision: scope (which are planning questions powerkit should answer) and a package for each

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

- **Whole-study simulation: the statistician's check**: Built on 27 October 2026 and in the app as an experimental option on the guided plan (power4mome; correlation, interaction, mediation and moderated mediation; a quick look in the app, and the full run and the sample size search from an R script). Before it is offered as more than experimental, a statistician goes through the method note and the cross-checks; then the other designs on the plan *Needs the maintainer: the statistician's check*
- **Validation catch-up, the rest**: Six cards moved to validated on 27 October 2026. Eight still say "validation in progress": the one-way ANOVA, multiple regression R², one proportion and McNemar (in the engine's tests, not yet in the full run), ANCOVA, Poisson regression, goodness of fit and two independent correlations. Each needs a published example in its validation file and a full run *Needs the maintainer: the published values are theirs*
- **Published values** (`TODO_PUBLISHED_VALUE`) for every validation file,
  and the full validation run on your own machine.
- **Six roadmap rows that need G\*Power itself** (A22, A38, A42, A46, A48,
  A49): the manual has no example for them.
- **The logistic R-squared question** (Known difference 3): whether
  powerkit's reading of "R² other X" matches G\*Power's.
- **Which batch comes after 6**, if the order above is wrong.
