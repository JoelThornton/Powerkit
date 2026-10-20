# Open questions for backend packages

Technical questions about packages powerkit builds on that are not yet
answered. Each would be raised with the package's authors, for example as
an issue on the package's repository. Questions that were raised and
answered are recorded in `docs/conventions.md` (Departures 4 and 8) and
`docs/decisions.md` ("Upstream reports fixed; upstream watch").

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

1. **`p_r()`: one-sided tests when `rho` isn't 0.** In Spower 0.7, when
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
