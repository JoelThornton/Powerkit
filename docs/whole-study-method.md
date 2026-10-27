# Whole-study simulation: the method, for a statistician's check

*27 October 2026. Experimental (powerkit 0.10.0). This note sets out what
the whole-study simulation does, what it is checked against, and the
questions a statistician is asked to settle before it is offered as more
than experimental. Code: `engine/R/whole-study.R`; spec format:
`engine/inst/schema/whole-study.schema.json`; app screen:
`app/routing/R/whole-study.R`; departure record: `conventions.md`,
Departure 13.*

## The problem it addresses

A study usually has several planned analyses: for example, the effect of
X on Y, whether it runs through a mediator M, and whether it depends on a
moderator W. powerkit's guided plan sends each analysis to its own input
screen, as the established tools do. Each screen asks for its effect in
its own form (a correlation for one, paths for another), so the inputs can
describe different populations without anyone noticing, and the chance
that several analyses all succeed has to be worked out from their separate
powers, as if they were unrelated (the plan's rule of thumb: for two tests
and 80% together, about 89.4% each).

## What it does

1. **One population model.** The user gives standardised path
   coefficients for a linear model whose structure is the union of the
   planned analyses' models (`whole_study_model()`):
   - each mediator on X (and, in a chain, M2 on M1); W and X x W on the
     mediator when W moderates X -> M (PROCESS model 7);
   - Y on X and every mediator; W and X x W when an interaction of X and W
     is tested; W and M x W when W moderates M -> Y (PROCESS model 14);
   - the correlation of X and W, and with parallel mediators the
     correlation of their residuals.

   Every observed variable has variance 1; the residual variances follow
   from the paths (powerkit's existing check, `implied_r_squared()`,
   refuses paths whose R-squared reaches 1). Exogenous variables are
   normal. Product terms follow power4mome's convention (products of the
   standardised variables).
2. **Simulation.** power4mome 0.2.1 (`power4test()`) generates `nrep`
   data sets of size N from the model (default 1,000).
3. **Each analysis fitted with its own model,** to every data set, as a
   researcher would analyse it on its own (`whole_study_fit()`):

   | Analysis | Model | Test |
   | --- | --- | --- |
   | Effect of X on Y (`x_y`) | Y ~ X, OLS | t test of the slope (the test of the correlation) |
   | Interaction (`interaction`) | Y ~ X + W + X:W, OLS | t test of X:W |
   | Mediation (`indirect`) | lavaan ML: M ~ X, Y ~ M + X (two mediators: parallel with residual covariance free, or serial) | Monte Carlo CI of the indirect effect (1,000 draws) |
   | Moderated mediation (`index_of_mome`) | lavaan ML, PROCESS model 7 or 14 | Monte Carlo CI of the index of moderated mediation |

4. **Power.** Each analysis's power is its rejection rate. The joint power
   is the proportion of replications in which every main analysis is
   significant (claim "all"), or at least one (claim "any", with each main
   test at alpha divided by the number of main analyses, Bonferroni, as on
   the plan's input screens). Each rate is reported with its Monte Carlo
   SE and a 95% Clopper-Pearson interval.
5. **Check run.** One data set of 100,000 from the same model: each
   population equation refitted by OLS must recover its paths, every
   observed variable must have variance 1, and the correlations must be
   recovered (within 5 standard errors). The run stops if not.
6. **Implied values.** From the same large data set, the values each
   analysis's own input screen asks for (the correlation for X and Y; the
   four correlations InteractionPoweR uses; the paths of the mediation
   model; the index of moderated mediation, by manymome), shown beside
   what the user entered on that screen.

7. **Sample size search** (powerkit 0.11.0). With the goal `sample_size`,
   the smallest n whose power reaches a target is found by powerkit's
   existing simulation search (`search_n()`, as for its other simulated
   designs): runs of 100 replications bracket it, then runs of `nrep`
   replications at seven or more n around it are smoothed by a probit
   regression of the rejections on sqrt(n), and a full run at the n found
   gives the reported powers. The quantity that must reach the target
   follows the claim: with one main analysis, its power; under "all", the
   joint power (every main analysis significant); under "any", the chance
   that at least one is; under "each", at each simulated n, the power of
   the main analysis with the lowest power there (question 6). The app
   runs only a quick look (200 replications); the full run and the search
   run on the user's computer from an R script
   (`export_whole_study_script()`), since a search simulates every
   analysis at many sample sizes (hours, for mediation).

powerkit writes no statistical computation of its own here: the data, the
fits, the tests and the joint rates are power4mome's (and lavaan's,
lmhelprs's and manymome's).

## What it is checked against

`engine/tests/testthat/test-whole-study.R` (every CI run):

- the bookkeeping of the joint power is exact: with two main tests at the
  same alpha, (both significant) + (at least one) equals the sum of the two
  tests' significant results in every batch;
- joint "all" is at most the smallest single power, and joint "any" at
  least the largest; the same seed gives the same result; the check run
  catches a path put in the wrong place; plain-words refusals of
  inconsistent specs.

`engine/tests/testthat/test-validation-whole-study-crosscheck.R` (full
validation, 10,000 replications, chunk `whole_study`), with results from
a local run of fewer replications below:

| Study | Analysis | Whole-study power | Separate calculation | Note |
| --- | --- | --- | --- | --- |
| A: X -> M -> Y (a = b = .3, c' = .1), N = 100, 2,000 replications | Correlation of X and Y | 48.4% (SE 1.1) | 47.7% (pwr, r = .19) | agree |
| | Indirect effect | 71.8% (SE 1.0) | 72.0% (SE 1.0; powerkit's E10, power4mome) | agree |
| | Both significant | 38.1% (SE 1.1) | 34.8% (product of the two) | Departure 13: 3.3 points higher |
| B: Y on X, W and XW (.2, -.1, -.15; r(X, W) = -.2), N = 150, 4,000 replications | Interaction | 47.5% (SE 0.8) | 49.2% (SE 0.8; powerkit's E9, InteractionPoweR, from the implied correlations) | about 1.5 SE apart |
| | Correlation of X and Y | 76.5% (SE 0.7) | 77.6% (pwr, r = .22) | about 1.6 SE apart; Y also depends on XW, which this analysis leaves out |
| | Both significant | 36.5% | 36.4% (product) | unrelated tests |
| C: every path 0, N = 100, claim "any" (each test at .05/3), 2,000 replications | Correlation | 1.7% | 1.67% | Type I error as intended |
| | Interaction | 1.8% | 1.67% | as intended |
| | Indirect effect | 0.1% | below 1.67% | conservative when both paths are 0 |
| | At least one | 3.5% | at most 5% | as intended |

Study B's two small gaps (both about 1.5 Monte Carlo SEs, the whole-study
power the lower) are the first thing to look at: they may be chance, or a
real effect of the terms an analysis leaves out (question 1 below) and of
how InteractionPoweR generates its data compared with power4mome.

## Questions for the statistician

1. **Each analysis's own model.** The analyses are fitted as a researcher
   would fit them on their own, so the regression of Y on X leaves out the
   mediator, the moderator and the product terms that the population
   contains. Is that the right thing to simulate (we think so: it is what
   will be run), and are the resulting non-normal, heteroscedastic
   residuals a concern for the t tests at the sample sizes planned?
2. **"Any one result supports the claim".** Bonferroni, as the plan's
   input screens use, or a less conservative correction (Holm, or one that
   uses the correlation between the tests, which the simulation knows)?
3. **Product terms.** power4mome builds X x W from the standardised X and
   W, so its variance is 1 + r(X, W)^2 for normal X and W. Is that the
   scaling users expect when they give a standardised path for the
   interaction?
4. **Precision.** Is 1,000 replications (Monte Carlo SE at most about
   1.6 points) enough for a joint power, or should the default be higher?
   And is 200 (about 7 points either way) a fair quick look in the app?
5. **Scope.** Measured predictor, score outcome, no covariates. Which
   extension matters most next: a two-group X, or covariates?
6. **The sample size under "each".** At each simulated n the search takes
   the rejections of the main analysis with the lowest power there. Where
   two analyses have similar power, the lower of two noisy estimates is
   biased down, so the n found is slightly larger than the largest of the
   analyses' own required n. Is that acceptable, or should each main
   analysis be searched on its own and the largest n taken? The probit
   curve behind the search assumes power is close to
   pnorm(a + b sqrt(n)); is that still a fair smoother for a joint power?
