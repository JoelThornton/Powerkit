# Open questions for backend packages

Technical questions about packages powerkit builds on that are not yet
answered. Each would be raised with the package's authors, for example as
an issue on the package's repository. Questions that were raised and
answered are recorded in `docs/conventions.md` (Departures 4 and 8) and
`docs/decisions.md` ("Upstream reports fixed; upstream watch").

## Exposure and recheck register

*Reviewed 4 November 2026 against the adapters and the questions below.*
An open upstream question is not automatically an exposed Powerkit defect.
"Bypassed" describes the current route, not a claim that upstream fixed it.
Independent numerical evidence is named where recorded; a source inspection
alone is not an independent numerical validation. The detailed questions
below retain their reproduction information and limitations.

| Package / affected variant | Evidence to retain | Current exposure and mitigation | Recheck condition |
|---|---|---|---|
| InteractionPoweR: regression-interaction sensitivity from correlations | Known differences 1/7; formula/df inspection and recorded comparison with G*Power | Used with the disclosed fixed-model convention; not evidence of random-predictor equivalence | New version, clarified effect definition/df, or replacement method; repeat the same fixed and simulated comparisons |
| powertools: binary cluster/multisite outcome, variance multiplier 1.2 | Source inspection; source of multiplier remains unknown | Approximation retained and disclosed; provenance question remains open | Author supplies derivation or implementation changes; check representative event rates and ICCs |
| powertools: varying cluster sizes with a binary outcome | `re.clustsize.bin()` source comparison; no independent validation recorded here | Restricted: this simulated/planning combination is not enabled; equal sizes remain available | Corrected formula plus independent checks before enabling variable sizes |
| powertools: continuous cluster covariates, RsqB/RsqW | Recorded hand-calculated design effect in question 3 | Inputs interpreted as shares within their respective variance components | Documentation or formula changes; rerun the hand calculation and covariate cases |
| powertools: returned df, critical value and noncentrality | Source inspection; backend does not return these fields | Reporting limitation: no invented details are displayed | Backend starts returning details; compare each with the reported power |
| bfpwr: t-test Bayes factors at small N | Known difference 6; comparison with simulated t statistics | Normal approximation used and disclosed | Exact/t-based implementation or changed design-prior handling; repeat small-N comparisons |
| bfpwr: power with an informed prior at small N | Comparison with simulated t statistics and bfpwr's own `tbf01()` (bfpwr question 2) | Informed priors not offered | A corrected `powertbf01()`, or the maintainer's decision on an exact calculation in the engine |
| metapower: random-effects heterogeneity power | `upstream/metapower-homogeneity.R`; independent simulated Q tests | Bypassed: Powerkit simulates Q with metafor instead of `homogen_power()` | Upstream correction; retain the three discrepant cases before considering a route change |
| metapower: correlation effect rounded on Fisher's z scale | Known difference 9; recorded rounded/unrounded comparison | `mpower()` convention retained and disclosed | Rounding changes or author clarification; rerun the same correlations |
| power4mome: models 58/59 population products | `test-path-product-moments.R`; full polynomial moments and independently generated/OLS checks in the validation journal | Workaround: explicit residual variances and `standardized = FALSE`; separate fitted model | Standardisation/product-update changes; recover the population and repeat scoped simulations before removing the workaround |
| power4mome: seeded product-term standardisation | Same-seed checks with different preceding RNG states | Workaround: explicitly seed before `power4test()` | RNG/seeding changes; compare repeated calls and core settings |
| longpower: `diggle.linear.power()` power for a given n | Question below; `test-backend-growth.R` compares the solved power with the package's own where that works | Bypassed: Powerkit solves the package's sample size for the power, so the same formula gives the power | Upstream correction; rerun the small- and large-group cases before calling the power directly |
| irtpwr: DIF preset with one differing parameter | Question below; `test-backend-irt.R` compares the corrected preset with the package's own where both run | Workaround: Powerkit passes the preset with its `res()` corrected (`drop = FALSE`) through `setup.hypothesis(type = <list>)` | Upstream correction; compare the package's preset with the corrected one for one and two differing parameters before removing the workaround |
| power4mome: X with three or more categories in mediation | Backend-support question; no independent supported implementation recorded | Unsupported, rather than approximated by a continuous X | A documented generator, effect coding and target test, followed by validation |
| manymome/power4mome: model 8 moderated-mediation index | Recorded refusal of `index_of_mome()` and conditional-effect comparison | Bypassed by offering the explicitly labelled difference of conditional indirect effects; it is a different target | Index implementation changes; compare estimands and retain both target-specific tests |
| power4mome: correlated binary X and W | Backend restriction and historical questions; no validated generator recorded | Unsupported where the generator requires zero covariance | A supported joint generator and independent checks at nonzero associations |
| power4mome: binary-X Monte Carlo interval calibration | `test-validation-modmed-binary.R`, independent OLS interval comparison | Active limitation, disclosed; not treated as validated merely because the simulation runs | Recommended fitting/interval settings or a package change; repeat null and alternative checks |
| power4mome: models 58/59 fitted residual covariance | Recorded failed standard errors with `M ~~ W` | Bypassed: fitted model supplied without the non-estimable covariance | Fitted-model construction changes; compare standard errors, failures and target decisions |
| Spower: directional one-/two-variance tests | `upstream/spower-var-test.R`, manual examples 26.3/15.3 | Direction passed explicitly; analytic variance routes avoid this default issue | Changes to `alternative`/`two.tailed`; rerun both directions, including effects opposite to the prediction |
| Spower: unequal groups in simulated two-variance tests | `gen_var.test()` unequal-length reproduction | Restricted for the simulation route; analytic unequal-allocation F-test route is separate | Generator fixed; compare generated counts and null/alternative rejection before enabling it |
| Spower: explicit `alternative = NULL` in variance experiments | Reproduction in the variance-test script | Avoided by Powerkit's explicit direction handling | Argument validation changes; rerun explicit NULL and both supported directions |
| Spower: one-sided correlation test with nonzero null rho | Source inspection quoted below; no independent numerical check recorded here | Not exposed: Powerkit does not offer that nonzero-null simulated correlation target | Such a target is added, or Spower's p-value code changes; validate the actual directional test |
| Spower 0.6.4: halved two-sided p-values with a zero null | Historical reproduction `upstream/spower-one-sided-tests.R`; retired Departure 4 | Upstream resolution recorded for 0.7; this historical fault is separate from the nonzero-null question above | Direction handling changes; retain null and opposite-direction regression checks on upgrade |
| semPower: simulated configural measurement-invariance comparison | `test-validation-sem-latent.R`; recorded internal dimension error | Analytic route unaffected; independent lavaan simulation used for the cross-check | Simulation output changes; repeat configural and saturated comparisons before changing the cross-check |
| PMCMRplus: list-form Jonckheere direction/continuity | `test-backend-trend.R`; list versus score/group calls | Bypassed: scores and group labels passed separately | New version or list-method fix; retain directional and two-sided comparisons |

On a dependency update, inspect the affected rows and run their named checks
before removing a workaround or widening a supported population. Record the
version and outcome here and in the validation journal. Do not mark a row
resolved from a green workflow whose relevant tests were skipped. Questions
may be prepared as reproducible upstream reports; this register does not
mean a report has been submitted or answered.

## InteractionPoweR

Questions about InteractionPoweR 0.2.4, from its source (opened 30 October 2026).

1. **`power_interaction_r2()`'s effect size and degrees of freedom.** It
   computes f^2 = (R2_full - R2_reduced) / (1 - R2_reduced) and lambda =
   f^2 (N - 3) on N - 3 denominator df. Cohen's f^2 for an R-squared
   increase divides by 1 - R2_full, G*Power uses lambda = f^2 N, and a model
   Y ~ X + W + XW leaves N - 4 df. The result is slightly less power than
   G*Power's for the same interaction (Known difference 7 in
   `docs/conventions.md`: 58.3% against 59.9% at N = 200). Are these
   choices intended (for example, to approximate the random-predictor
   case), and is N - 3 meant to be N - 4? powerkit uses the function as it
   is for the smallest detectable effect (Known difference 1) and states
   the difference.

## powertools

Questions about powertools 1.0.0, from its source (opened 28 October
2026).

1. **The factor 1.2 for yes/no outcomes.** `crt.parallel.bin()` and
   `multisite.bin()` multiply the variance of the log odds ratio by 1.2.
   The help pages do not say where this comes from. What is its source,
   and does it depend on the size of `sigma.u`? powerkit uses the
   functions as they are and says the method is an approximation.
2. **Varying group sizes for a yes/no outcome.** In `re.clustsize.bin()`,
   the denominator uses `lamc^2 * (1 - lamt)`, where the matching
   numerator term and the continuous-outcome version suggest
   `(1 - lamc)`. If this is a typo, the adjustment is wrong whenever
   group sizes vary. Until this is answered, powerkit offers yes/no
   outcomes for groups of the same size only (`cluster_size_sd` 0).
3. **What `RsqB` and `RsqW` are shares of.** `crt.parallel.cont()`'s help
   page describes `RsqB` and `RsqW` as the "proportion of total variance
   explained" by cluster-level and individual-level covariates. Its
   design effect, 1 + (m (1 - RsqB) - 1) ICC - m RsqW (1 - 2 ICC) /
   (m - 1), multiplies `RsqB` by the ICC, which is what a share of the
   between-cluster variance (not of the total) would need; worked by hand,
   reading `RsqB` and `RsqW` as shares of the between- and within-cluster
   variance gives the expected design effect (for m = 20, ICC 0.05 and
   RsqW 0.5, 1.476 against 1.475). Is that the intended reading? powerkit
   asks for them that way.
4. **Returning the test's details.** `crt.parallel.cont()`,
   `multisite.cont()` and the other functions powerkit calls compute the
   test's degrees of freedom, critical value and noncentrality (for
   example `df <- J - 2 - ncov`, `ncp <- d/sqrt(detot/N/RE)` and
   `crit <- stats::qt(1 - alpha, df)` in `crt.parallel.cont()`), but
   return only power and the inputs. Could they be returned, as pwrss
   does? Researchers checking a result against another tool ask for them,
   and powerkit shows them only where a package reports them.

## bfpwr

Questions about bfpwr 0.1.6, from its source (opened 28 October 2026).

1. **The normal approximation for t-test Bayes factors.** `ptbf01()`
   finds the critical effect estimates with `tbf01()` and then takes their
   probability from a normal distribution with SD sqrt(1 / effective n +
   `dpsd`^2), so the t statistic's degrees of freedom don't enter. Against
   Bayes factors computed on simulated t statistics this gives slightly
   lower power at small samples (Known difference 6 in
   `docs/conventions.md`). Is an exact version (the noncentral t, or a
   t-based design prior) planned, or is the approximation the intended
   method? powerkit uses the function as it is and states the difference.
2. **Power with an informed prior at small samples.** With `plocation`
   away from 0 (for example `plocation = 0.3, pscale = 0.15, pdf = 1`,
   one-sample, two-sided, design prior N(0.4, 0.1)), `powertbf01()` gives
   power 1 at n = 3 and 5 and 0 at n = 10, where Bayes factors computed
   with bfpwr's own `tbf01()` on simulated t statistics give about 0, 0.7%
   and 5%; from about n = 30 the two agree (36.5% against 38%, 78.1%
   against 77.7% at n = 80). `tbf01()` itself matches a numerical
   integration of the t likelihood over the t prior to every digit shown,
   so the difference is in the power calculation: at small n the
   threshold can't be reached on one side (an informed prior's Bayes
   factor is not symmetric in t), and the critical values seem to be
   taken as if it could. Found 5 November 2026; powerkit doesn't offer
   informed priors until this is resolved (`decisions.md`, 5 November
   2026).

## metapower

Questions about metapower 0.2.2, from its source (opened 31 October
2026); reproducible example in `docs/upstream/metapower-homogeneity.R`.

1. **Power for the test of heterogeneity.** `homogen_power()`'s
   random-effects power disagrees with simulated Q tests in both
   directions (58.2% against 48.5%, 19.6% against 25.8%, 27.5% against
   31.3%). In `compute_homogen_power()` the variance of Q uses one study's
   weight where the line before it sums over the studies, and its second
   term is always 0. powerkit doesn't use `homogen_power()`: since 1
   November 2026 it simulates the Q test with metafor instead.
2. **Fisher's z rounded to two decimals.** `mpower()` with `es_type = "r"`
   rounds z before computing power, which moves power by up to about 1.3
   points (Known difference 9 in `docs/conventions.md`). Is the rounding
   intended? powerkit uses `mpower()` as it is and states the difference.

## power4mome

**Population standardisation with a mediator in a later product (0.2.1).**
`psi_std_monte_carlo()` calls `update_p_terms()` before replacing the
mediator's error values with its generated values. In models 58 and 59,
the following outcome equation can therefore use an outdated MW during
standardisation. Powerkit now supplies residual variances from the full
product moments and uses `standardized = FALSE` for these models, with a
separate fitted model. The actual generator updates products after each
equation. See Departure 19 and `test-path-product-moments.R`. Recheck this
workaround when updating power4mome; no upstream resolution is assumed.

1. **Reproducibility with a product term.** For a model with a product
   term (for example `m ~ x + w + x:w`), the population standardisation
   (`psi_std_monte_carlo()`, with `n_std` draws) appears to use the
   random-number state from before `iseed` is applied. Two calls with the
   same `iseed` can then give slightly different results, depending on
   what ran before them in the session. powerkit calls `set.seed()` with
   the same seed just before each `power4test()` call. Is there an
   intended way to get reproducible results?
2. **Multi-category X.** Does power4mome support an X with three or more
   groups in mediation and moderated mediation? If so, how should it be
   specified (`model`, `pop_es` and `x_fun`), and which test function
   applies?
3. **The index of moderated mediation for PROCESS model 8.** In model 8,
   W moderates X -> M and the direct path X -> Y; the indirect effect
   (a1 + a3 W) b is linear in W, so its index a3 b is defined, as for
   model 7. `manymome::index_of_mome()` (0.3.7), which
   `test_index_of_mome()` calls, refuses it ("The index cannot be computed
   when there are more than one moderators"), for a lavaan fit and for
   `lm2list()` alike, while `cond_indirect_effects()` on the same fit
   gives the right formula, (b.M~X + b.X:W W) b.Y~M. Is the refusal
   intended when X:W also appears in Y's equation? powerkit offers model 8
   (E38) by testing the difference between the conditional indirect
   effects at two values of W instead (`cond_indirect_diff()`).
4. Two earlier questions are in `docs/decisions.md` (15 October 2026,
   "Published values: InteractionPoweR notes"): whether a binary X can be
   correlated with W, and whether the Monte Carlo CI test has been checked
   with a binary X.
5. **A residual covariance that can't be estimated, with W on the M -> Y
   link.** For a model with M ~ X + W + X:W and Y ~ ... + M:W (PROCESS
   model 58 or 59), power4test()'s fitted model adds `M ~~ W`, a residual
   covariance of M with one of its own predictors, which lavaan cannot
   estimate ("Could not compute standard errors"), so every test fails.
   powerkit gives the fitted model through `fit_model_args`, without that
   line (1 November 2026). Is `M ~~ W` added on purpose for some models?
6. **The Monte Carlo interval's Type I error with a yes/no X.** In PROCESS
   model 7 with X drawn by `rbinary_rs()` (p = 0.5), W continuous, n = 250
   and no moderation (X:W -> M = 0, M -> Y = 0.35), `test_index_of_mome()`
   rejected in 7.5% of 1,000 and 6.3% of 2,000 simulated studies (about
   6.7% together), against 4.9% and 5.8% (about 5.3%) for an interval
   computed separately from OLS fits of the same model
   (`test-validation-modmed-binary.R`). Is a slightly liberal test
   expected here, for example from the normal-theory standard errors of
   the lavaan fit when X is binary, and is there a recommended setting?

## Spower

1. **`p_var.test()`: one-sided tests, unequal groups, and
   `alternative = NULL`.** Three points about the variance tests, found
   while reproducing the G*Power 3.1 manual's examples 26.3 and 15.3.
   Reproducible example: `docs/upstream/spower-var-test.R`.
   1. `two.tailed = FALSE` becomes `alternative <- "greater"` whichever way
      the variances point. The manual's example 26.3 tests whether a
      variance is *lower* than the fixed value, so "greater" has no power,
      and the version of that example in Spower's own vignette
      (`vignettes/gpower_examples.Rmd`) cannot reach the manual's N = 81.
      powerkit always passes `alternative` and is unaffected.
   2. `gen_var.test()` fails for unequal groups: `sapply()` over groups of
      different sizes returns a list, so the data frame is built from
      columns of different lengths ("arguments imply differing number of
      rows"). `unlist(Map(...))` would fix it. Until then the allocation
      ratio in example 15.3 (N = 443, 148 and 295) can't be simulated, and
      powerkit refuses unequal allocation for its simulated two-variance test
      (`docs/conventions.md`, variance tests).
   3. Passing `alternative = NULL` explicitly, which is `p_var.test()`'s own
      default, stops `Spower()` with "Exactly *one* argument must be set to
      'NA'", so a caller that always supplies the argument has to drop it
      when it is NULL.
2. **`p_r()`: one-sided tests when `rho` isn't 0.** In Spower 0.7, when
   `rho != 0` the p-value is replaced with the Fisher's z test against
   `rho`:

   ```r
   out$p.value <- pnorm(abs(t), lower.tail=FALSE)*2
   ```

   (`R/p_r.R`, line 75). This appears to be two-sided whatever
   `two.tailed` or `alternative` says, so `p_r(50, .5, rho = .3,
   two.tailed = FALSE)` would give the two-sided p-value. With `rho = 0`
   the p-value comes from `cor.test()` and follows `alternative`. A
   possible fix is `pnorm(t, lower.tail = FALSE)` for "greater" and
   `pnorm(t)` for "less". powerkit doesn't use a non-zero null
   correlation, so nothing in powerkit is affected today. Recorded in
   `docs/decisions.md` (17 October 2026, "Spower: one-sided tests against
   a non-zero null correlation") and `docs/coverage-roadmap.md` (flags).

## semPower

1. **Simulated power for a multigroup comparison with the configural
   model.** `semPower.powerMI(type = "post-hoc", comparison =
   "configural", nullEffect = "metric", ..., simulatedPower = TRUE)`
   (semPower 2.2.0) stops with "length of 'dimnames' [2] not equal to
   array extent" in its internal `simulate()`, where the column names for
   the fitted H0 and difference statistics are set (`c("fmin", "chisq",
   "df", "p", paste0("fminGroup", seq(length(N))))`), whether `N` is a
   list or a vector. The same call with `comparison = "saturated"` runs.
   powerkit's analytic route is unaffected; the validation cross-check for
   measurement invariance simulates the same chi-square difference test
   with lavaan directly instead (`test-validation-sem-latent.R`).

## PMCMRplus

Questions about PMCMRplus 1.9.12, from its source (opened 1 November
2026).

1. **`jonckheereTest()` given a list of groups ignores `alternative`.**
   With `x` a list, the default method reads the direction from
   `x$alternative` (an element of the list) rather than from its
   `alternative` argument, so `jonckheereTest(groups, alternative =
   "greater")` returns the two-sided p-value; `continuity` is read the same
   way. Given the scores and their groups (`jonckheereTest(x, g,
   alternative = )`), the argument is used. powerkit's experiment
   (`p_jonckheere()`) passes the scores and groups, and a test checks that
   the list form is still two-sided (`test-backend-trend.R`). Is reading
   these from the list intended?

## longpower

Questions about longpower 1.0.27, from running it (5 November 2026).

1. **`diggle.linear.power()` given `n` returns a wrong power, or fails.**
   With `n` given and `power = NULL`, the function finds the power by root
   finding; for small groups it stops with "no sign change found in 1000
   iterations" (n = 2, 4 and 10 per group with times 0 to 3, random
   intercept SD 6, slope SD 2, correlation -0.2, residual SD 4, delta 1),
   and for large ones it returns about 0 (5.6e-17 at n = 2,000 per group,
   where the power is about 1). With `power` given it returns the sample
   size by the formula itself, correctly. powerkit's adapter
   (`backend-longpower.R`, `growth_power()`) finds the power as the one
   whose required group size is the n asked about, and
   `test-backend-growth.R` checks that it equals the package's own power
   where that works (n = 100 per group). Is the root-finding's interval or
   tolerance the cause?

## irtpwr

Questions about irtpwr 1.0.3, from running it (5 November 2026).

1. **The `"DIF2PL"` preset stops when only one parameter differs.** With
   one item whose difficulty differs between the groups (one row in the
   hypothesis matrix), `setup.hypothesis(type = "DIF2PL", altpars = ...)`
   followed by `irtpwr()` stops with "'x' must be an array of at least
   two dimensions" (4 items, the first 0.4 harder): the preset's `res()`
   computes `colSums(Amat[, 1:(2 * n.items)])`, and with one row the
   subset drops to a vector, so `colSums()` fails. With two or more
   differing parameters it runs. A single item with uniform DIF is the
   most common planning case. powerkit's adapter (`backend-irtpwr.R`,
   `irt_preset()`) passes the preset with `drop = FALSE` added, and
   `test-backend-irt.R` checks that it gives the package's own power
   where both run (two differing parameters). Is `drop = FALSE` the
   intended fix?
2. **Which parameters the DIF preset tests.** The preset's hypothesis
   names the parameters that differ in the population given, so a change
   in difficulty alone is tested with 1 df. mirt's `DIF()` help calls the
   test of both parameters (`which.par = c('a1', 'd')`) the omnibus test,
   with tests of one parameter as follow-ups. powerkit tests both of each
   DIF item's parameters by default and offers the preset's choice
   (docs/conventions.md). Would an argument naming the parameters to test
   suit the package?

## PITS

Questions about PITS 0.1.0, from running it (6 November 2026).

1. **The test rejects too often when there is no effect, in short
   series.** `calculate_power()` fits `nlme::gls()` with AR(1) errors by
   maximum likelihood (`fit_its_model()`) and counts p < alpha. With no
   intervention effect (`level_change = 0`, `slope_change = 0`, baseline
   10, sigma 2, 1,000 simulations, alpha .05), the share of significant
   results was 15.5% for the level change and 18.2% for the slope change
   with 12 points before and 12 after and rho 0.4; 11.5% and 12.6% with
   24 and 24; 6.1% and 8.5% with 48 and 48; and 8.4% and 9.0% with 24 and
   24 and rho 0. Its power for short series therefore includes false
   positives. Fitting the same model by REML (nlme's default) gave 9.3%
   and 11.1% (12 and 12, rho 0.4), 6.3% and 7.4% (24 and 24) and 6.0% and
   5.9% (24 and 24, rho 0). Would REML, or a small-sample correction to the
   test's degrees of freedom, suit the package, or a note on the Type I
   error at the planned length?

