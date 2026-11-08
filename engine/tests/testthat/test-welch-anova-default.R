# Welch's F is the one-way ANOVA card's default (Departure 22,
# docs/conventions.md): G*Power and Superpower plan for the classical F
# test. These tests show the size of the difference, from Superpower's
# exact power and Spower's simulation of stats::oneway.test(). The means
# are the example's (10, 11, 13; SD 6) and the target power is 80%.

anova_default_spec <- function(method, goal, sds = NULL, sd = 6, nrep = 2000L) {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- method
  spec$population$sd <- sd
  spec$population$sds <- sds
  spec$goal <- goal
  spec$options <- if (method == "welch_f") list(seed = 11L, nrep = nrep) else list(seed = 11L)
  spec
}

test_that("with equal SDs, Welch's F needs about the same N as the F test", {
  goal <- list(type = "sample_size", power = 0.8)
  f_test <- run_quietly(anova_default_spec("anova_f", goal))$n_required$n
  expect_equal(f_test, 228)
  welch <- run_quietly(anova_default_spec("welch_f", goal))$n_required
  # 231 (95% interval 228 to 234) with 10,000 replications per point:
  # a few more people at most, for estimating each group's spread.
  expect_lte(welch$lower, f_test + 6)
  expect_gte(welch$upper, f_test)
})

test_that("with unequal SDs, Welch's F plans for the spreads entered", {
  goal <- list(type = "sample_size", power = 0.8)
  # SDs 4, 6 and 9: 300 (297 to 303) with 10,000 replications per point.
  # The F test, given one SD, can't use them; with their root mean square
  # (6.66) it plans 279.
  welch <- run_quietly(anova_default_spec("welch_f", goal, sds = list(4, 6, 9)))$n_required
  f_test <- run_quietly(anova_default_spec("anova_f", goal, sd = sqrt(mean(c(4, 6, 9)^2))))$n_required$n
  expect_equal(f_test, 279)
  expect_gt(welch$lower, f_test)
  expect_equal(welch$n, 300, tolerance = 0.05)
})
