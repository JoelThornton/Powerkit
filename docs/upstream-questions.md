# Open questions for backend packages

Technical questions about packages powerkit builds on that are not yet
answered. Each would be raised with the package's authors, for example as
an issue on the package's repository. Questions that were raised and
answered are recorded in `docs/conventions.md` (Departures 4 and 8) and
`docs/decisions.md` ("Upstream reports fixed; upstream watch").

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
      powerkit refuses an allocation ratio for its two-variance test
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
