# Validation: minimum-effect tests on the t-tests (target_test > method
# "minimum_effect"). Backend: pwrss's power.t.student() with the margin on
# the effect's side, by formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-minimum-effect.R)
#      check powerkit against pwrss called directly and against the
#      noncentral t written out in base R
#   2. published examples: below, for the maintainer to choose and
#      transcribe
#   3. simulation: below; power from simulated t-tests against the margin
#      agrees with pwrss's formula
#   4. Type I error: below; with the true effect at the margin, the
#      rejection rate is alpha
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

met_validation_spec <- function(d, margin, n, template = "independent_t", alternative = "greater") {
  spec <- example_spec(template)
  spec$target_test$method <- "minimum_effect"
  spec$target_test$alternative <- alternative
  spec$population <- list(metric = "standardised", margin = margin)
  spec$population[[if (template == "paired_t") "dz" else "d"]] <- d
  spec$goal <- list(type = "power", n = n)
  spec$options <- NULL
  spec
}

# Simulated two-group studies: the t statistic of the mean difference
# against the 1 - alpha quantile of the noncentral t at the margin.
simulated_met_power <- function(d, margin, n_per_group, nrep, seed, alpha = 0.05) {
  set.seed(seed)
  df <- 2 * n_per_group - 2
  critical <- stats::qt(1 - alpha, df, ncp = margin / sqrt(2 / n_per_group))
  t <- replicate(nrep, {
    y1 <- stats::rnorm(n_per_group)
    y2 <- stats::rnorm(n_per_group, mean = d)
    stats::t.test(y2, y1, var.equal = TRUE)$statistic
  })
  mean(t > critical)
}

test_that("minimum-effect test, two groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample-size
  # calculation for a minimum-effect test of two independent groups, for
  # the maintainer to choose. Note whether the smallest effect of interest
  # is in SD units or the outcome's own units (Known difference 10).
  d <- TODO_PUBLISHED_VALUE # expected true difference, as Cohen's d
  margin <- TODO_PUBLISHED_VALUE # smallest effect of interest, as Cohen's d
  alpha <- TODO_PUBLISHED_VALUE # one-sided alpha
  target_power <- TODO_PUBLISHED_VALUE # the power the example plans for
  n_per_group <- TODO_PUBLISHED_VALUE # Output: sample size per group
  skip_if_todo(d, margin, alpha, target_power, n_per_group)

  spec <- met_validation_spec(d, margin, n = 100)
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "sample_size", power = target_power)
  expect_n_near(engine_n_required(spec), 2 * n_per_group)
})

test_that("minimum-effect test: simulated t-tests against the margin agree with pwrss", {
  skip_unless_full_validation()
  power <- run_spec(met_validation_spec(0.6, 0.2, n = 120))$curve$power
  simulated <- simulated_met_power(0.6, 0.2, 60, nrep = 20000, seed = 501)
  expect_equal(simulated, power, tolerance = 4 * sqrt(power * (1 - power) / 20000), scale = 1)
})

test_that("minimum-effect test: at the margin the rejection rate is alpha (Type I error)", {
  skip_unless_full_validation()
  rate <- simulated_met_power(0.2, 0.2, 60, nrep = 20000, seed = 502)
  expect_equal(rate, 0.05, tolerance = 4 * sqrt(0.05 * 0.95 / 20000), scale = 1)
  expect_equal(run_spec(met_validation_spec(0.2 + 1e-9, 0.2, n = 120))$curve$power, 0.05, tolerance = 1e-6)
})
