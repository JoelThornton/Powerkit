# Validation: the repeated-measures (within-person) correlation.
# Backend: pwrss's power.exact.onecor() at the effective sample size
# N(k - 1) + 1 (backend-rmcorr.R), the degrees of freedom rmcorr's test
# uses (Bakdash and Marusich, 2017).
# Build guide section 6:
#   1. published-example agreement
#   2. agreement with a direct pwrss call, and with simulated studies
#      analysed by the repeated-measures correlation's own model (lm()
#      with an intercept for each person and one common slope, the model
#      rmcorr::rmcorr() fits)
#   3. Type I error, from simulated studies
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

rmcorr_validation_spec <- function(r, measurements, seed, n = NULL, target_power = NULL,
                                   alpha = 0.05, alternative = "two_sided") {
  v <- validation_variable
  validation_spec(
    design = "basic_test",
    template = "repeated_measures_correlation",
    variables = list(X = v("continuous", "X"), Y = v("continuous", "Y")),
    population = list(metric = "correlation", r = r, measurements = measurements),
    target_test = list(effect = "correlation", method = "rmcorr", alpha = alpha, alternative = alternative),
    seed = seed, n = n, target_power = target_power
  )
}

# Simulated studies, written separately from the engine: N people measured
# k times, each with their own averages on X and Y and a common
# within-person slope giving the correlation r, analysed by the t test of
# X in lm(Y ~ person + X). Returns the share of studies with p < alpha.
rmcorr_simulated_power <- function(n, k, r, alpha = 0.05, nrep = validation_nrep(), seed = 1) {
  withr::local_seed(seed)
  person <- factor(rep(seq_len(n), each = k))
  hits <- vapply(seq_len(nrep), function(i) {
    x <- rep(stats::rnorm(n, sd = 2), each = k) + stats::rnorm(n * k)
    within_x <- x - stats::ave(x, person)
    y <- rep(stats::rnorm(n, sd = 2), each = k) + r * within_x + sqrt(1 - r^2) * stats::rnorm(n * k)
    fit <- stats::lm(y ~ person + x)
    summary(fit)$coefficients["x", "Pr(>|t|)"] < alpha
  }, logical(1))
  binomial_estimate(mean(hits), nrep)
}

# 1. Published examples --------------------------------------------------------

test_that("repeated-measures correlation: matches Bakdash and Marusich's power example (published)", {
  skip_unless_full_validation()
  # Source: Bakdash, J. Z., & Marusich, L. R. (2017). Repeated measures
  #   correlation. Frontiers in Psychology, 8, 456, the section on power;
  #   the same example is in the rmcorr package's documentation ("How to
  #   Calculate Power"). Its power uses Fisher's z, so the published value
  #   may differ from powerkit's exact distribution of r in the third
  #   decimal place; record which the source reports.
  people <- TODO_PUBLISHED_VALUE # N, the number of participants
  measurements <- TODO_PUBLISHED_VALUE # k, repeated measures per participant
  r_rm <- TODO_PUBLISHED_VALUE # effect size r_rm
  alpha <- TODO_PUBLISHED_VALUE # significance level
  published_power <- TODO_PUBLISHED_VALUE # the power the source reports
  skip_if_todo(people, measurements, r_rm, alpha, published_power)

  spec <- rmcorr_validation_spec(r_rm, measurements, seed = 101, n = people, alpha = alpha)
  expect_power_exact(engine_power(spec), published_power)
})

# 2. Direct-call agreement -----------------------------------------------------

test_that("repeated-measures correlation: powerkit matches a direct pwrss call at the effective n", {
  skip_unless_full_validation()
  spec <- rmcorr_validation_spec(0.25, 4, seed = 201, n = 40)
  direct <- pwrss::power.exact.onecor(rho = 0.25, null.rho = 0, n = 40 * (4 - 1) + 1, alpha = 0.05,
    alternative = "two.sided", verbose = 0)$power
  expect_power_exact(engine_power(spec), direct)
})

test_that("repeated-measures correlation: powerkit agrees with simulated studies analysed by lm()", {
  skip_unless_full_validation()
  # Power near .5 and near .8, with few and many measurements per person.
  for (setting in list(list(n = 30, k = 3, r = 0.2), list(n = 25, k = 8, r = 0.2), list(n = 96, k = 3, r = 0.2))) {
    spec <- rmcorr_validation_spec(setting$r, setting$k, seed = 202, n = setting$n)
    simulated <- rmcorr_simulated_power(setting$n, setting$k, setting$r, seed = 202)
    expect_power_near(engine_power(spec), simulated$power, reference_nrep = validation_nrep())
  }
})

# 3. Type I error ---------------------------------------------------------------

test_that("repeated-measures correlation: simulated studies keep the Type I error at alpha", {
  skip_unless_full_validation()
  spec <- rmcorr_validation_spec(0, 3, seed = 301, n = 50)
  expect_power_exact(engine_power(spec), 0.05)
  expect_type1_near(rmcorr_simulated_power(50, 3, 0, seed = 301), alpha = 0.05)
})
