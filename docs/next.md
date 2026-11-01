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
| 1 | **Joint power for study plans that mix designs: nested, repeated and dyadic studies** | The whole-study simulation gives joint power for independent people measured once or (since 31 October 2026) twice, with every analysis adjusted for the first measurement as an ANCOVA is; X a measured score or two groups: a group comparison with a moderation or mediation on the same people. Dyadic data have their own card since 1 November 2026 (E44, the actor-partner model, power4mome), which a dyadic whole study can build on. Not yet: a group variable correlated with the moderator (power4mome draws a two-group X on its own), three or more groups, studies measured three times or more, moderated mediation and two mediators measured twice, nested and dyadic designs | L | Ready (decided 31 October 2026): extend the whole-study simulation one design at a time (done: two groups, measured twice); marked Experimental, and checked with item 9 by a statistician later, not before |
| 2 | **Multilevel: more simulated models** | Participants responding to many items in two conditions (E33) calculate since 30 October 2026 (with the conditions between participants too since 31 October, and three or more conditions within participants as E63, with pairwise comparisons), and predictors at both levels with their cross-level interaction (E62, a two-level model) since 31 October 2026, both with simr. Not yet: other crossed designs (three or more conditions between participants, a predictor measured on each trial, a yes/no outcome per trial), three levels, and a yes/no outcome in a two-level model | L | Ready (decided 31 October 2026): simulated with simr as E33 and E62 are; marked not yet checked until a statistician looks at them |
| 3 | **Bayes factors beyond the t-tests** | The Bayes factor t-tests are in the app (bfpwr, fixed N), and since 1 November 2026 Labs has Bayesian planning for them at a fixed N (analysis and design priors set apart; the three outcomes under the belief and with no effect; `bayes_planning()`). Not yet: Bayes factors for proportions and correlations on the cards, and sequential designs (BFDA, on GitHub only) | M | Ready (decided 31 October 2026): the order in `bayes-planning.md` — next the other cards (bfpwr's binomial and z-test Bayes factors, with the three-outcome display), sequential designs last, by powerkit's own simulation with bfpwr; sources into `refs.bib` first |
| 4 | **The number of trials or items for E33, and precision for more estimates** | Precision planning (E46) runs since 1 November 2026: the sample size for a confidence-interval width, or the width at a given n, for Cohen's d (two groups), d_z, a standardised mean (MBESS, with optional assurance), a correlation and a proportion (presize). Not yet: the number of trials or items for participants responding to many items (E33), and precision for other estimates presize and MBESS cover (a mean difference in raw units, an odds ratio, a regression coefficient, an ICC) | M | Ready for the other estimates; the number of items for E33 follows the open changes to E33 (decided 31 October 2026 as a later goal)
| 5 | **Meta-analysis: heterogeneity, moderators and several effects per study** | The test of the average effect runs since 31 October 2026 (E61, metapower's `mpower()`), and the test that kinds of study differ (subgroups) since 1 November 2026 (metapower's `mod_power()`, checked against simulation, or the Hartung-Knapp test by default). Not yet: power for the test of heterogeneity (metapower's `homogen_power()` disagrees with simulation; `upstream-questions.md`, metapower), for a moderator that is a score, and for several effects per study (POMADE `power_MADE()`, roadmap B68). Also open: study-level power (metameta) as a Labs tool | M | Ready for POMADE (decided 31 October 2026); subgroups done (1 November 2026); heterogeneity waits for metapower's answer or another package |
| 6 | **Labs: the picture of power for more designs** | The picture of power for the two-group t-test is in Labs since 31 October 2026 (sliders for N and d, buttons for alpha; the central and noncentral t drawn with power and the Type I error shaded; power, beta, df, the noncentrality, the critical t and the smallest significant d, all from the engine's `power_picture()`: pwr for power, R's t densities for the curves), and for a correlation since 31 October 2026 (`power_picture_r()`: pwr.r.test()'s power, drawn as the two normal curves on Fisher's z scale that its formula uses, with the smallest significant r). Next: other designs | M | Ready (decided 31 October 2026): Labs only; which design next is open |
| 7 | **Simulated data sets for the remaining designs** | The CSV download and the R script's data section cover the basic tests, the rank tests, equivalence and non-inferiority, the Superpower ANOVA designs, Welch's ANOVA, planned contrasts, regression interactions, mediation, logistic and Poisson regression with one predictor, factorial logistic regression, ordinal outcomes and cluster trials with a score outcome (29 October 2026), and MANOVA, one-sample Hotelling's T-squared and one-way ANCOVA, with one covariate standing for all of them (31 October 2026). Not yet: R² (other predictors), logistic and Poisson regression with other predictors, the two-way ANCOVA, the three-way interaction (no package generator), multisite trials, yes/no cluster outcomes and a baseline covariate in cluster trials; SEM and McNemar's test stay without | M | Ready (decided 31 October 2026): simple choices, each stated in the CSV's note: ANCOVA's and other predictors' R-squared carried by one normal covariate or predictor, multisite and yes/no cluster outcomes from the model powertools assumes; SEM and McNemar left without |
| 8 | **Moderated mediation with W on both links or the direct link (E38, PROCESS models 8, 58 and 59)** | Model 8 (W on X -> M and the direct path) has an index of moderated mediation, but manymome's `index_of_mome()`, which power4mome's test calls, refuses it (`upstream-questions.md`, power4mome, question 3). Models 58 and 59 (W on both links) have no single index: the indirect effect is quadratic in W | M | Needs a decision: for models 58 and 59, what to power (conditional indirect effects at chosen values of W, or their difference); for model 8, the answer to the upstream question
| 9 | **Whole-study simulation: the statistician's check** | Built on 27 October 2026 and in the app as an experimental option on the guided plan (power4mome; correlation, interaction, mediation and moderated mediation; a quick look in the app, and the full run and the sample size search from an R script). Before it is offered as more than experimental, a statistician goes through the method note and the cross-checks; then the other designs on the plan | M | Needs the maintainer: the statistician's check |
| 10 | **Moderated mediation with a yes/no X or W (E17)** | Moderation (E15) and mediation (E16, and E11 and E12 for two or more mediators) with a yes/no variable calculate since 29 October 2026. Still coming soon: moderated mediation with a yes/no X or W (PROCESS models 7 and 14), with power4mome (`x_fun` with `rbinary_rs()`; roadmap B22) | M | Needs the maintainer: how power4mome standardises a binary W in a model with a product term, and whether its Monte Carlo CI has been checked with a binary X (`judgement-calls.md`, E4; questions for power4mome's author, which could go in the package-maintainer email) |
| 11 | **Validation catch-up, the rest** | Six cards moved to validated on 27 October 2026. Eight still say "validation in progress": the one-way ANOVA, multiple regression R², one proportion and McNemar (in the engine's tests, not yet in the full run), ANCOVA, Poisson regression, goodness of fit and two independent correlations. Each needs a published example in its validation file and a full run | M | Needs the maintainer: the published values are theirs |
| 12 | **SEM: the test of close fit, and invariance with several factors** | Model fit, measurement invariance across two groups or two occasions, factor correlations and latent slopes are in the app (semPower). Still missing: invariance with several factors, more than two groups or more than two occasions, and the test of close fit (RMSEA no more than 0.05), which semPower doesn't compute | M | Needs a decision: which comes next; for close fit, a method and a package that computes it (left out for now, 29 October 2026) |
| 13 | **Repeated measures: mixed designs with unequal groups** | The one-way repeated-measures card (E54, since 31 October 2026) and the mixed and two-factor within designs (E8, E55 and E20, since 1 November 2026) take an SD per cell and correlations per pair (per group for the 2 x 2 mixed design), with a Greenhouse-Geisser or Huynh-Feldt correction and the MANOVA approach beside it. Not yet: mixed designs with unequal groups (Superpower's `ANOVA_power()` stops for them; the 2 x 2 between design takes unequal cells since 29 October 2026) | M | Needs a decision: a route for unequal groups in a mixed design, since Superpower's simulation refuses them |
| 14 | **Reliability and agreement: Cronbach's alpha, McDonald's omega, kappa, Krippendorff's alpha and ICC** | Scale development plans for a minimum internal consistency (alpha or omega above .70), and rating studies for agreement: Cohen's and Fleiss' kappa, Krippendorff's alpha and the ICC (roadmap B50: ICC.Sample.Size, presize, kappaSize). Nothing in powerkit covers any of them, and no card points to them | M | Needs a decision: the method (Bonett and Wright's approach is the candidate the roadmap names, unverified) and a package that computes it |
| 15 | **Time-to-event outcome (E43)** | Relapse, dropout and disengagement timing; the card names Hmisc (`cpower()` for the log-rank or Cox test, `spower()` by simulation), the roadmap powerSurvEpi and npsurvSS too (B67) | M | Needs a decision: the test (log-rank or Cox) and the package
| 16 | **Longitudinal: three or more occasions (E35)** | Growth curves, random-intercept cross-lagged panels and experience sampling; the card names longpower, powRICLPM and PowerAnalysisIL (GitHub only) (roadmap B41-B43) | L | Needs a decision: which models first and which package for each, checked by a statistician
| 17 | **Designs that need a custom simulation (E30, E32, E39, E42, E45, E65)** | A moderator with three or more groups, non-score outcomes or mediators in moderation and mediation, a condition with three or more groups in mediation, dyadic designs other than actor and partner effects (E65; the APIM itself, E44, calculates since 1 November 2026) and interrupted time series. Each card points to Spower with a model the user writes | L | Needs a decision: per design, the data-generating model and the analysis (one PR each)
| 18 | **Robust and non-parametric group comparisons not yet covered** | From a review of the tests psychologists report: the Brunner-Munzel test (two groups, unequal variances), the aligned rank transform for factorial designs, Quade's non-parametric ANCOVA and PERMANOVA. None is on the roadmap yet; whether each has a power function or needs simulation is unchecked | M | Needs a decision: which are worth covering, and the package or simulation route for each
| 19 | **Regression variants: robust and quantile regression, multinomial and zero-inflated outcomes** | Regression with HC3 or HC4 standard errors, quantile regression, multinomial logistic regression and negative binomial or zero-inflated counts (roadmap B30 and the candidate list); likely by simulation with Spower's `p_glm()` or a user-written experiment, unchecked | M | Needs a decision: which first, and the route
| 20 | **Psychometric and cognitive models: EFA, latent profiles and classes, IRT and signal detection** | Exploratory factor analysis sample size (B52), latent profile and class analysis (B49), IRT and DIF (B51: irtpwr, irtsim) and signal detection sensitivity (d') in memory and perception tasks, which no row covers yet | L | Needs a decision: scope (which are planning questions powerkit should answer) and a package for each
| 21 | **Critical effect size, and technical details for the remaining designs** | The technical details section (29 October 2026) gives df, critical value and noncentrality where pwrss, pwr (through pwrss) or Superpower's exact ANOVA report them. Not yet: semPower, powertools, TOSTER and bfpwr designs, and the correlation test (pwr's has no identical pwrss version). The critical effect size (the smallest observed effect that would be significant, d_crit or r_crit) is asked for by researchers who report it with a power analysis | S | Needs the maintainer: a reference for the critical effect size in `refs.bib` and the decision to show it (t-tests and correlations first, labelled as an observed value) |
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
- **Which batch comes after 6**, if the order above is wrong.
