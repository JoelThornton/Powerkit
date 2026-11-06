# Validation: exploratory factor analysis (the chance every factor's
# loadings are recovered), powerkit's Spower experiment p_efa() around
# psych's fa().
#   1. agreement with a fit written separately: data drawn by MASS's
#      mvrnorm() from the model's covariance, fitted by base R's
#      factanal() (maximum likelihood, oblimin from GPArotation) rather
#      than psych's minimum residual, factors matched to the true ones and
#      Tucker's congruence computed here; the two estimators give slightly
#      different loadings, so an allowance of 0.03 beyond Monte Carlo
#      error, as for the other formula-style comparisons
#   2. published example: MacCallum, Widaman, Zhang and Hong (1999);
#      placeholder for the maintainer
# Skipped unless POWERKIT_FULL_VALIDATION=true.

efa_spec <- function(k, p, loading, phi, n, seed, congruence = 0.95) {
  validation_spec(
    design = "factor_analysis",
    template = "efa",
    variables = list(Y = validation_variable("continuous", "Items")),
    population = list(metric = "standardised", factors = k, items_per_factor = p, loading = loading, factor_correlation = phi),
    target_test = list(effect = "recovery", method = "congruence", congruence = congruence),
    seed = seed,
    n = n
  )
}

efa_by_hand <- function(k, p, loading, phi, n, congruence, nrep, seed) {
  lambda <- kronecker(diag(k), matrix(loading, p, 1))
  r <- matrix(phi, k, k); diag(r) <- 1
  sigma <- lambda %*% r %*% t(lambda); diag(sigma) <- 1
  orders <- as.matrix(expand.grid(rep(list(seq_len(k)), k)))
  orders <- orders[apply(orders, 1, function(o) length(unique(o)) == k), , drop = FALSE]
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- MASS::mvrnorm(n, rep(0, nrow(sigma)), sigma)
    fit <- tryCatch(suppressWarnings(stats::factanal(x, factors = k, rotation = "none")), error = function(e) NULL)
    if (is.null(fit)) return(FALSE)
    est <- unclass(fit$loadings)
    if (k > 1) est <- unclass(GPArotation::oblimin(est)$loadings)
    tucker <- abs(crossprod(est, lambda) / sqrt(outer(colSums(est^2), colSums(lambda^2))))
    best <- orders[which.max(apply(orders, 1, function(o) sum(tucker[cbind(o, seq_len(k))]))), ]
    all(tucker[cbind(best, seq_len(k))] >= congruence)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("exploratory factor analysis: a fit written separately recovers the loadings as often (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("GPArotation")
  cases <- list(
    list(k = 3, p = 5, loading = 0.6, phi = 0.3, n = 150),
    list(k = 2, p = 4, loading = 0.5, phi = 0, n = 200),
    list(k = 4, p = 6, loading = 0.7, phi = 0.2, n = 120)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- efa_spec(case$k, case$p, case$loading, case$phi, case$n, 7500L + i)
    spec$options$nrep <- 2000L
    reference <- efa_by_hand(case$k, case$p, case$loading, case$phi, case$n, 0.95, 1000L, 7510L + i)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("exploratory factor analysis: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: MacCallum, Widaman, Zhang and Hong, 1999,
  # Psychological Methods 4, 84-99, recovery at a given N, communality and
  # number of items per factor; table, page).
  n <- TODO_PUBLISHED_VALUE
  published_rate <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_rate)
  spec <- efa_spec(3, 7, 0.6, 0, n, 7520L)
  expect_power_near(engine_power(spec), published_rate)
})
