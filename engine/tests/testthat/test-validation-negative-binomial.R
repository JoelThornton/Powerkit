# Validation: negative binomial regression of a count on one predictor.
# Backend: Spower simulation of powerkit's experiment
# p_negative_binomial(), which fits MASS's glm.nb().
#   1. agreement with an independent simulation: counts drawn as a
#      gamma-Poisson mixture (each person's rate multiplied by a gamma
#      variable with mean 1 and variance k, which gives the negative
#      binomial with variance mu + k mu^2) and the Wald test of a
#      negative binomial fit, without powerkit's code
#   2. with almost no overdispersion, the power of Poisson regression by
#      pwrss's formula (power.z.poisson())
#   3. Type I error with overdispersed counts
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

nb_validation_spec <- function(rate_ratio, base_rate, dispersion, n, binary = FALSE, x_prob = 0.5, r2 = 0) {
  validation_spec(
    design = "poisson_regression",
    template = "single_predictor_count",
    variables = list(
      X = if (binary) validation_variable("binary", "Group", levels = list("Control", "Treatment")) else validation_variable("continuous", "Score"),
      Y = validation_variable("count", "Events")
    ),
    population = c(list(metric = "rate_ratio", rate_ratio = rate_ratio, base_rate = base_rate, dispersion = dispersion),
      if (binary) list(x_prob = x_prob), if (r2 > 0) list(r2_other_predictors = r2)),
    target_test = list(effect = "rate_ratio", method = "negative_binomial", alpha = 0.05),
    seed = 6401,
    n = n
  )
}

nb_by_hand <- function(rate_ratio, base_rate, dispersion, n, binary, x_prob, nrep, seed) {
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- if (binary) c(rep(0, n - round(n * x_prob)), rep(1, round(n * x_prob))) else stats::rnorm(n)
    frailty <- stats::rgamma(n, shape = 1 / dispersion, scale = dispersion)
    y <- stats::rpois(n, base_rate * rate_ratio^x * frailty)
    fit <- suppressWarnings(MASS::glm.nb(y ~ x))
    stats::coef(summary(fit))["x", "Pr(>|z|)"] < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("negative binomial: powerkit agrees with a gamma-Poisson simulation (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(rate_ratio = 0.8, base_rate = 3, dispersion = 0.5, n = 250, binary = FALSE, x_prob = 0.5),
    list(rate_ratio = 1.5, base_rate = 1, dispersion = 1.5, n = 200, binary = TRUE, x_prob = 0.3)
  )
  for (case in cases) {
    spec <- nb_validation_spec(case$rate_ratio, case$base_rate, case$dispersion, case$n, case$binary, case$x_prob)
    reference <- nb_by_hand(case$rate_ratio, case$base_rate, case$dispersion, case$n, case$binary, case$x_prob, 4000L, 64)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("negative binomial: with almost no overdispersion it has Poisson regression's power (pwrss)", {
  skip_unless_full_validation()
  # pwrss's Wald z test of Poisson regression (Demidenko's variance), a
  # large-sample formula: allow 0.02 besides the Monte Carlo error.
  spec <- nb_validation_spec(0.85, 2, 0.001, 200)
  formula <- pwrss::power.z.poisson(base.rate = 2, rate.ratio = 0.85, n = 200, alpha = 0.05, alternative = "two.sided",
    method = "demidenko(vc)", distribution = "normal", ceil.n = FALSE, verbose = 0)$power
  expect_power_agrees_within(engine_power(spec), exact_estimate(formula), allowance = 0.02)
})

test_that("negative binomial: Type I error with overdispersed counts (simulation)", {
  skip_unless_full_validation()
  spec <- nb_validation_spec(1, 2, 1, 200, binary = TRUE)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("negative binomial: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # negative binomial regression with one predictor; source, section, page).
  rate_ratio <- TODO_PUBLISHED_VALUE
  base_rate <- TODO_PUBLISHED_VALUE
  dispersion <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(rate_ratio, base_rate, dispersion, n, published_power)
  spec <- nb_validation_spec(rate_ratio, base_rate, dispersion, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
