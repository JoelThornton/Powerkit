# Independent normal-data Welch decisions, with fixed raw means and SDs.
# No published expected values are supplied or substituted here.
independent_welch_rate <- function(spec, nrep, seed) {
  raw <- spec$population$raw
  n1 <- round(spec$goal$n / (1 + spec$options$allocation_ratio))
  n2 <- spec$goal$n - n1
  alternative <- if (identical(spec$target_test$alternative, "greater")) "greater" else "two.sided"
  with_seed(seed, mean(replicate(nrep, {
    first <- stats::rnorm(n1, raw$mean_1, raw$sd1)
    second <- stats::rnorm(n2, raw$mean_2, raw$sd2)
    stats::t.test(second, first, alternative = alternative, var.equal = FALSE)$p.value < spec$target_test$alpha
  })))
}

test_that("Welch formulas agree with independent unequal-SD studies across allocations", {
  skip_unless_full_validation()
  reps <- validation_nrep()
  for (ratio in c(0.5, 2)) {
    spec <- welch_spread_spec()
    spec$options$allocation_ratio <- ratio
    spec <- validate_spec(spec)
    result <- run_spec(spec)
    reference <- independent_welch_rate(spec, reps, 981 + ratio * 2)
    # pwrss uses a Welch-Satterthwaite approximation, not an exact power
    # integral. Allow 0.01 beyond four Monte Carlo standard errors.
    expect_equal(result$curve$power, reference,
      tolerance = 0.01 + 4 * sqrt(reference * (1 - reference) / reps))
  }
})

test_that("Welch simulation agrees with separately generated and analysed raw data", {
  skip_unless_full_validation()
  spec <- welch_spread_spec("simulation")
  spec$options$nrep <- validation_nrep()
  result <- run_spec(spec)
  reference <- independent_welch_rate(spec, validation_nrep(), 17821)
  expect_power_near(binomial_estimate(result$curve$power, validation_nrep()), reference,
    reference_nrep = validation_nrep())
})

test_that("Welch simulation holds alpha with unequal SDs and unequal groups", {
  skip_unless_full_validation()
  spec <- welch_spread_spec("simulation")
  spec$population$raw$mean_2 <- spec$population$raw$mean_1
  spec$target_test$alternative <- "greater"
  spec$options$nrep <- validation_nrep()
  spec <- validate_spec(spec)
  result <- run_spec(spec)
  expect_type1_near(binomial_estimate(result$curve$power, validation_nrep()), spec$target_test$alpha)
})

# Welch's one-way ANOVA (the one-way card's default since November 2026):
# stats::oneway.test() on separately generated groups with each group's SD.
welch_anova_validation_spec <- function(goal, means = list(10, 11, 13), sds = list(4, 6, 9)) {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- "welch_f"
  spec$population$means <- means
  spec$population$sds <- sds
  spec$goal <- goal
  spec$options <- list(seed = 2611L, nrep = validation_nrep())
  validate_spec(spec)
}

independent_welch_anova_rate <- function(means, sds, n_per_group, nrep, seed, alpha = 0.05) {
  group <- factor(rep(seq_along(means), each = n_per_group))
  with_seed(seed, mean(replicate(nrep, {
    y <- stats::rnorm(length(group), rep(means, each = n_per_group), rep(sds, each = n_per_group))
    stats::oneway.test(y ~ group, var.equal = FALSE)$p.value < alpha
  })))
}

test_that("Welch's F simulation agrees with separately generated and analysed groups", {
  skip_unless_full_validation()
  spec <- welch_anova_validation_spec(list(type = "power", n = 90))
  result <- run_spec(spec)
  reference <- independent_welch_anova_rate(c(10, 11, 13), c(4, 6, 9), 30, validation_nrep(), 4127)
  expect_power_near(binomial_estimate(result$curve$power, validation_nrep()), reference,
    reference_nrep = validation_nrep())
})

test_that("Welch's F simulation holds alpha with unequal SDs", {
  skip_unless_full_validation()
  spec <- welch_anova_validation_spec(list(type = "power", n = 60), means = list(10, 10, 10))
  result <- run_spec(spec)
  expect_type1_near(binomial_estimate(result$curve$power, validation_nrep()), spec$target_test$alpha)
})

test_that("at Welch's F's smallest detectable effect, separately simulated studies reach the target power", {
  skip_unless_full_validation()
  spec <- welch_anova_validation_spec(list(type = "sensitivity", n = 90, power = 0.8))
  spec$options$nrep <- 2000L
  s <- run_spec(spec)$sensitivity
  reference <- independent_welch_anova_rate(s$means, c(4, 6, 9), 30, validation_nrep(), 5113)
  # The scale is read from a fitted curve, so the reference is compared
  # with the target, allowing the curve's own 95% interval as well.
  power_at <- function(scale) {
    means <- mean(c(10, 11, 13)) + scale * (c(10, 11, 13) - mean(c(10, 11, 13)))
    independent_welch_anova_rate(means, c(4, 6, 9), 30, 2000L, 5113)
  }
  expect_power_near(binomial_estimate(0.8, validation_nrep()), reference, reference_nrep = validation_nrep())
  expect_lte(power_at(s$scale_lower), 0.8 + 0.03)
  expect_gte(power_at(s$scale_upper), 0.8 - 0.03)
})
