# What to work on next

*29 October 2026. The ordered answer to "work on the next thing". One
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
| 1 | **Whole-study simulation: the statistician's check** | Built on 27 October 2026 and in the app as an experimental option on the guided plan (power4mome; correlation, interaction, mediation and moderated mediation; a quick look in the app, and the full run and the sample size search from an R script). Before it is offered as more than experimental, a statistician goes through the method note and the cross-checks; then the other designs on the plan | M | Needs the maintainer: the statistician's check |
| 2 | **Multilevel: simulated models** | Predictors measured at both levels, cross-level interactions, and many trials per participant with items as random effects (E33, E41). mlmpower, simr or mixpower, as an R script to run | L | Needs a decision: which package, checked by a statistician |
| 3 | **Download a synthetic data set with the R script** | Registered reports: write and pre-register the analysis code against simulated data before recruiting. The engine already generates one data set per run for its check run | M | Needs a decision: how it is labelled as simulated, and the wording that stops it reading as a substitute for the analysis plan |
| 4 | **Validation catch-up, the rest** | Six cards moved to validated on 27 October 2026. Eight still say "validation in progress": the one-way ANOVA, multiple regression R², one proportion and McNemar (in the engine's tests, not yet in the full run), ANCOVA, Poisson regression, goodness of fit and two independent correlations. Each needs a published example in its validation file and a full run | M | Needs the maintainer: the published values are theirs |
| 5 | **SEM: the test of close fit, and invariance with several factors** | Model fit, measurement invariance across two groups or two occasions, factor correlations and latent slopes are in the app (semPower). Still missing: invariance with several factors, more than two groups or more than two occasions, and the test of close fit (RMSEA no more than 0.05), which semPower doesn't compute | M | Needs a decision: which comes next; for close fit, a method and a package that computes it (left out for now, 29 October 2026) |
| 6 | **Repeated measures: sphericity corrections, unequal SDs and correlations** | The repeated-measures designs assume one SD and one correlation for every pair of conditions, so sphericity holds; the MANOVA approach is shown beside them (29 October 2026). Real data rarely look like that: a Greenhouse-Geisser or Huynh-Feldt correction, or a covariance matrix per condition, would let users plan for it | M | Needs a decision: which (Superpower takes a correlation matrix; the corrections need a method and package) |
| 7 | **Bayes factors beyond the t-tests** | The Bayes factor t-tests are in the app (bfpwr, fixed N). Sequential designs (BFDA, on GitHub only) and Bayes factors for other designs are not | M | Needs a decision: the package for sequential designs, and which designs next |
| 8 | **Point-biserial r and minimum-effect tests** | Two gaps users meet on existing cards: a point-biserial correlation (G\*Power A2, the two-group t-test with r given instead of d) and minimum-effect tests (showing an effect is larger than a smallest effect of interest, the counterpart of equivalence) | S | Needs a decision: whether point-biserial r is an effect-size option on the two-group card or its own card, and the method for minimum-effect tests |
| 9 | **Rank tests for repeated measures, and score shapes for the rank correlations** | Friedman's test (the rank-based one-way repeated-measures ANOVA, roadmap B26) is not computed: its card says the ANOVA figure only approximates it. And Spearman's and Kendall's correlations are simulated on normal scores only (29 October 2026), where their advantage over Pearson's r is in skewed or heavy-tailed data | M | Needs a decision: a package or simulation route for Friedman's test, and how to draw correlated non-normal scores |
| 10 | **Cronbach's alpha against a benchmark** | Scale-development studies plan for a minimum internal consistency (for example, alpha above .70); the roadmap's candidate list names it and nothing in powerkit covers it (roadmap B50 covers ICC and kappa, not alpha) | M | Needs a decision: the method (Bonett and Wright's approach is the candidate the roadmap names, unverified) and a package that computes it |
| 11 | **Trend tests: Cochran-Armitage and Jonckheere-Terpstra** | A linear trend in proportions across ordered groups (dose, age band), and its rank-based equivalent for scores; both on the roadmap's candidate list and asked for in dose-response and developmental designs | M | Needs a decision: package or simulation route for each |

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
