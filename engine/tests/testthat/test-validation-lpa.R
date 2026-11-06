# Validation: latent profile analysis (the chance the BIC finds the right
# number of profiles), powerkit's Spower experiment p_lpa() around mclust.
#   1. agreement with a fit written separately: the same model (equal
#      diagonal covariance across profiles, mclust's EEI) fitted by an
#      expectation-maximisation algorithm written here, started from
#      k-means, with the BIC computed by hand (2 log-likelihood minus the
#      number of parameters times log n, mclust's sign convention), on
#      studies drawn here; three cases from a clear to a hard enumeration
#   2. published example: Tein, Coxe and Cham (2013), placeholder for the
#      maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

lpa_spec <- function(k, m, separation, shares, n, seed) {
  validation_spec(
    design = "mixture",
    template = "lpa",
    variables = list(Y = validation_variable("continuous", "Indicators")),
    population = list(metric = "sd_units", profiles = k, indicators = m, separation = separation, shares = as.list(shares)),
    target_test = list(effect = "profiles", method = "bic"),
    seed = seed,
    n = n
  )
}

# The EEI model: means per profile, one diagonal covariance for all.
eei_bic <- function(x, g) {
  n <- nrow(x)
  m <- ncol(x)
  if (g == 1) {
    v <- colMeans(sweep(x, 2, colMeans(x))^2)
    ll <- sum(vapply(seq_len(m), function(j) sum(stats::dnorm(x[, j], mean(x[, j]), sqrt(v[j]), log = TRUE)), numeric(1)))
    return(2 * ll - (2 * m) * log(n))
  }
  start <- stats::kmeans(x, g, nstart = 10)$cluster
  z <- outer(start, seq_len(g), "==") * 1
  ll_old <- -Inf
  for (iter in 1:1000) {
    w <- colMeans(z)
    mu <- t(z) %*% x / colSums(z)
    v <- colSums(Reduce(`+`, lapply(seq_len(g), function(k) z[, k] * sweep(x, 2, mu[k, ])^2))) / n
    logd <- vapply(seq_len(g), function(k) {
      log(w[k]) + rowSums(stats::dnorm(x, rep(mu[k, ], each = n), rep(sqrt(v), each = n), log = TRUE))
    }, numeric(n))
    top <- apply(logd, 1, max)
    ll <- sum(top + log(rowSums(exp(logd - top))))
    z <- exp(logd - top - log(rowSums(exp(logd - top))))
    if (abs(ll - ll_old) < 1e-8 * abs(ll)) break
    ll_old <- ll
  }
  npar <- g * m + (g - 1) + m
  2 * ll - npar * log(n)
}

lpa_by_hand <- function(k, m, separation, shares, n, nrep, seed) {
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    g <- sample.int(k, n, replace = TRUE, prob = shares)
    x <- matrix(stats::rnorm(n * m), n) + (g - 1) * separation
    which.max(vapply(seq_len(k + 1), function(G) eei_bic(x, G), numeric(1))) == k
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("latent profiles: a fit written separately finds the right number as often (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(k = 3, m = 8, separation = 0.9, shares = c(0.4, 0.4, 0.2), n = 300),
    list(k = 2, m = 6, separation = 1, shares = c(0.5, 0.5), n = 150),
    list(k = 4, m = 10, separation = 1, shares = c(0.25, 0.25, 0.25, 0.25), n = 400)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- lpa_spec(case$k, case$m, case$separation, case$shares, case$n, 7400L + i)
    spec$options$nrep <- 2000L
    reference <- lpa_by_hand(case$k, case$m, case$separation, case$shares, case$n, 1000L, 7410L + i)
    expect_power_agrees(engine_power(spec), reference)
  }
})

test_that("latent profiles: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: Tein, Coxe and Cham, 2013, Structural Equation
  # Modeling 20(4), the BIC's rate of correct enumeration for a given number
  # of indicators, separation and sample size; table, page).
  n <- TODO_PUBLISHED_VALUE
  published_rate <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_rate)
  spec <- lpa_spec(3, 10, 0.8, c(1, 1, 1) / 3, n, 7420L)
  expect_power_near(engine_power(spec), published_rate)
})
