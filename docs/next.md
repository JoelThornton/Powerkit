# What to work on next

*27 October 2026. The ordered answer to "work on the next thing". One
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
| 2 | **Welch's one-way ANOVA** | Three or more groups with unequal variances. powerkit has Welch's t-test but only the equal-variance F for k groups, and unequal variances are the norm | M | Needs a decision: which package, and whether it is a departure from A23's omnibus F |
| 3 | **Pitman-Morgan test: variances in a paired design** | The sibling of the two variance tests just built; a pre-post design asking whether responses became more consistent has nowhere to go | M | Needs a decision: no foundation package covers it, so the method and package come first |
| 4 | **Equivalence, the rest: correlations, proportions and non-inferiority** | Equivalence for two groups, paired data and one sample is in the app (TOSTER). Correlations and proportions have TOSTER power functions (`power_z_cor()`, `power_twoprop()`); non-inferiority, a bound on one side only, has none | M | Needs a decision: which comes next, and the method for non-inferiority |
| 5 | **Repeated measures: the MANOVA approach** (A28) | The one-way design (E54, 27 October 2026) and two within factors, 2 x 2 or larger (E20, 28 October 2026), are in the app by the univariate F with sphericity assumed. Still to come: the multivariate (MANOVA) approach, which drops the sphericity assumption | M | Needs a decision: whether to report the MANOVA approach alongside the ANOVA one |
| 6 | **Spearman's rho and Kendall's tau** | Rank correlations are used constantly for skewed or ordinal measures, and powerkit offers only Pearson's r | M | Needs a decision: method (asymptotic relative efficiency, or simulation) and package |
| 7 | **Multilevel: simulated models** | Predictors measured at both levels, cross-level interactions, and many trials per participant with items as random effects (E33, E41). mlmpower, simr or mixpower, as an R script to run | L | Needs a decision: which package, checked by a statistician |
| 8 | **Download a synthetic data set with the R script** | Registered reports: write and pre-register the analysis code against simulated data before recruiting. The engine already generates one data set per run for its check run | M | Needs a decision: how it is labelled as simulated, and the wording that stops it reading as a substitute for the analysis plan |
| 9 | **SEM, CFA and measurement invariance: the next designs** | Model fit (the test of exact fit by RMSEA, for a CFA or any model) is in the app (27 October 2026, semPower). The maintainer chose this order for the rest: measurement invariance across groups (`semPower.powerMI()`, metric then scalar), the correlation between two factors (`semPower.powerCFA()`), then paths between latent variables (`semPower.powerPath()`) | L | Ready: measurement invariance next, one design per PR. Needs a decision before it is offered: whether to add the test of close fit, which semPower lacks |
| 10 | **Validation catch-up, the rest** | Six cards moved to validated on 27 October 2026. Eight still say "validation in progress": the one-way ANOVA, multiple regression R², one proportion and McNemar (in the engine's tests, not yet in the full run), ANCOVA, Poisson regression, goodness of fit and two independent correlations. Each needs a published example in its validation file and a full run | M | Needs the maintainer: the published values are theirs |

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
