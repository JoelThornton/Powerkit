# Validation: the Bayes factor test of a correlation (BayesFactor's
# correlationBF(), JASP's prior width by default).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation: bivariate normal scores drawn for each
#      simulated study (the correlation itself drawn from the stretched
#      beta design prior when there is uncertainty), each study's Bayes
#      factor computed without BayesFactor (two-sided: JASP's exact
#      formula; one-sided: the definition, integrated numerically), and the
#      share passing the threshold compared with powerkit's exact chance
#   3. the no-effect side, simulated the same way at rho = 0
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

cor_validation_spec <- function(n, r, alternative = "two_sided", r_sd = NULL, threshold = 10, width = 1) {
  spec <- example_spec("correlation")
  spec$population$r <- r
  spec$population$r_sd <- r_sd
  spec$target_test <- list(effect = "correlation", method = "bayes_factor", alternative = alternative,
    evidence_threshold = threshold, prior_width = width)
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the Bayes factor test of a correlation with a stretched beta
  #   prior (for example, a worked example of Bayes factor design analysis
  #   for a correlation). Transcribe the expected correlation, the prior
  #   width, the threshold, the hypotheses (two-sided or one-sided), n and
  #   the published chance of reaching the threshold.
  r <- TODO_PUBLISHED_VALUE
  width <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  alternative <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(r, width, threshold, alternative, n, published_power)
  result <- engine_function("run_spec")(cor_validation_spec(n, r, alternative, threshold = threshold, width = width))
  expect_equal(result$curve$power, published_power, tolerance = 0.005)
})

# Two-sided BF10: JASP's exact formula (bstats' bf10CorExact(); Ly,
# Marsman and Wagenmakers, 2018). One-sided (rho > 0 against rho = 0): the
# definition, integrated numerically.
validation_bf10 <- function(n, r, kappa, side) {
  if (identical(side, "two_sided")) {
    return(exp(lbeta(1 / kappa + (n - 1) / 2, 1 / 2) - lbeta(1 / kappa, 1 / 2) + (1 / kappa + 1 - n / 2) * log(1 - r^2) +
      log(Re(hypergeo::hypergeo(1 / kappa + 1 / 2, 1 / kappa + 1 / 2, 1 / kappa + n / 2, r^2)))))
  }
  if (identical(side, "less")) r <- -r
  mass <- stats::pbeta(0.5, 1 / kappa, 1 / kappa, lower.tail = FALSE)
  f <- function(rho) vapply(rho, function(p) SuppDists::dPearson(r, n, p), numeric(1)) *
    stats::dbeta((rho + 1) / 2, 1 / kappa, 1 / kappa) / 2 / mass
  stats::integrate(f, 0, 1, rel.tol = 1e-8)$value / SuppDists::dPearson(r, n, 0)
}

simulate_cor <- function(nsim, n, rho, rho_sd, kappa, threshold, side, seed) {
  set.seed(seed)
  rhos <- if (is.null(rho_sd)) rep(rho, nsim) else {
    m <- (rho + 1) / 2
    size <- m * (1 - m) / (rho_sd / 2)^2 - 1
    2 * stats::rbeta(nsim, m * size, (1 - m) * size) - 1
  }
  r <- vapply(rhos, function(p) {
    x <- stats::rnorm(n)
    stats::cor(x, p * x + sqrt(1 - p^2) * stats::rnorm(n))
  }, numeric(1))
  bf10 <- vapply(r, function(x) validation_bf10(n, x, kappa, side), numeric(1))
  c(for_effect = mean(bf10 >= threshold), for_null = mean(1 / bf10 > threshold))
}

check_cor_case <- function(n, r, r_sd = NULL, alternative = "two_sided", width = 1, nsim = 4000, seed) {
  skip_if_not_installed("hypergeo")
  result <- engine_function("run_spec")(cor_validation_spec(n, r, alternative, r_sd = r_sd, width = width))
  sim <- simulate_cor(nsim, n, r, r_sd, width, 10, alternative, seed)
  se <- sqrt(sim[["for_effect"]] * (1 - sim[["for_effect"]]) / nsim)
  expect_lt(abs(result$curve$power - sim[["for_effect"]]), 4 * se + 1e-3)
  null <- simulate_cor(nsim, n, 0, NULL, width, 10, alternative, seed + 1)
  se_null <- sqrt(null[["for_null"]] * (1 - null[["for_null"]]) / nsim)
  expect_lt(abs(result$bayes$evidence_for_null - null[["for_null"]]), 4 * se_null + 1e-3)
  se_mis <- sqrt(max(null[["for_effect"]], 1e-3) / nsim)
  expect_lt(abs(result$bayes$misleading_evidence - null[["for_effect"]]), 4 * se_mis + 1e-3)
}

test_that("two-sided, exactly r: agrees with simulated Bayes factors", {
  skip_unless_full_validation()
  check_cor_case(100, 0.3, seed = 61)
})

test_that("two-sided at BayesFactor's default width (1/3): agrees with simulation", {
  skip_unless_full_validation()
  check_cor_case(80, 0.35, width = 1 / 3, seed = 62)
})

test_that("one-sided, with uncertainty about r: agrees with simulation", {
  skip_unless_full_validation()
  check_cor_case(70, 0.3, r_sd = 0.1, alternative = "greater", nsim = 2000, seed = 63)
})

test_that("one-sided in the negative direction: agrees with simulation", {
  skip_unless_full_validation()
  check_cor_case(60, -0.35, alternative = "less", nsim = 2000, seed = 64)
})
