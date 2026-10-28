# Open questions for backend packages

Technical questions about packages powerkit builds on that are not yet
answered. Each would be raised with the package's authors, for example as
an issue on the package's repository. Questions that were raised and
answered are recorded in `docs/conventions.md` (Departures 4 and 8) and
`docs/decisions.md` ("Upstream reports fixed; upstream watch").

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
3. Two earlier questions are in `docs/decisions.md` (15 October 2026,
   "Published values: InteractionPoweR notes"): whether a binary X can be
   correlated with W, and whether the Monte Carlo CI test has been checked
   with a binary X.

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
