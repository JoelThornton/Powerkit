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
