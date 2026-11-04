test_that("studies use the same data for their tests and estimates, with a reproducible seed", {
  set.seed(8)
  before <- .Random.seed
  out <- study_variation(64, 0.3, seed = 123, replications = 10)
  expect_identical(.Random.seed, before)
  again <- study_variation(64, 0.3, seed = 123, replications = 10)
  expect_identical(out, again)
  set.seed(123)
  x <- rnorm(32)
  y <- rnorm(32, 0.3)
  reference <- t.test(y, x, var.equal = TRUE)
  expect_equal(out$studies$p_value[1], reference$p.value)
  expect_equal(out$studies$estimate[1], (mean(y) - mean(x)) / sqrt((var(x) + var(y)) / 2))
  expect_equal(out$settings$n_per_group, 32)
  expect_equal(out$summary$valid, 10)
  expect_equal(out$summary$failed, 0)
  expect_named(out$provenance$packages, c("powerkit", "stats", "effectsize"))
  expect_match(out$provenance$spec_hash, "^[a-f0-9]{64}$")
})

test_that("null studies have approximately uniform p-values, with no zero-effect ratio", {
  out <- study_variation(64, 0, seed = 7)
  expect_lt(abs(mean(out$studies$p_value) - 0.5), 0.04)
  expect_lt(abs(out$summary$proportion_significant - 0.05), 0.025)
  expect_true(is.na(out$summary$selected_magnitude_ratio))
  expect_true(all(is.na(out$studies$wrong_direction)))
})

test_that("selection at low power exaggerates magnitude; a signed estimate is retained", {
  out <- study_variation(24, 0.3, seed = 20261104)
  expect_gt(out$summary$selected_magnitude_ratio, 1)
  expect_gt(out$summary$overestimated_significant / out$summary$significant, 0.8)
  expect_equal(out$summary$significant, sum(out$studies$p_value < 0.05))
  expect_equal(out$studies$wrong_direction, out$studies$estimate < 0)
  negative <- study_variation(24, -0.3, seed = 15, replications = 10)
  expect_equal(negative$studies$wrong_direction, negative$studies$estimate > 0)
})

test_that("estimated rejection frequency agrees with the established power calculation", {
  out <- study_variation(100, 0.5, seed = 28)
  p <- pwr::pwr.t.test(n = 50, d = 0.5, sig.level = 0.05, type = "two.sample")$power
  expect_lt(abs(out$summary$proportion_significant - p), 5 * sqrt(p * (1 - p) / 1000))
  expect_error(study_variation(63), "even total sample size", class = "powerkit_run_error")
  expect_error(study_variation(d = NA), "population effect", class = "powerkit_run_error")
  expect_error(study_variation(seed = 0), "seed", class = "powerkit_run_error")
  expect_error(study_variation(replications = 1), "whole studies", class = "powerkit_run_error")
})
