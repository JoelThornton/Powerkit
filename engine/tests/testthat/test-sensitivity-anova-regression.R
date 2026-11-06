# The smallest detectable effect for every equal-groups ANOVA layout (the
# pattern of means kept and scaled, as for the 2x2 designs) and for
# multiple regression (the smallest R-squared pwrss's F test detects),
# added 6 November 2026.

test_that("each ANOVA layout scales the pattern entered until the effect tested reaches the target power", {
  for (name in c("anova_oneway_between", "anova_oneway_within", "anova_factorial_between",
                 "anova_factorial_within", "anova_mixed", "anova_factorial_three")) {
    spec <- example_spec(name)
    spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
    spec$options$method <- NULL
    result <- suppressWarnings(run_quietly(spec))
    s <- result$sensitivity
    expect_equal(s$power, 0.8, tolerance = 1e-6, label = name)
    expect_gt(s$cohen_f, 0)
    # The scaled means keep the entered pattern: their deviations from the
    # grand mean are proportional to the entered ones.
    mu <- unlist(spec$population$mu %||% spec$population$means)
    if (!is.null(mu) && length(mu) == length(s$means)) {
      expect_equal(s$means - mean(s$means), s$scale * (mu - mean(mu)), tolerance = 1e-8, label = name)
    }
    expect_equal(s$effect, max(s$means) - min(s$means), label = name)
  }
})

test_that("multiple regression finds the smallest R-squared, matching pwr's formula for the same F test", {
  spec <- example_spec("regression_r2_zero")
  spec$goal <- list(type = "sensitivity", n = 100L, power = 0.8)
  result <- suppressWarnings(run_quietly(spec))
  k <- spec$population$predictors
  f2 <- pwr::pwr.f2.test(u = k, v = 100 - k - 1, power = 0.8, sig.level = spec$target_test$alpha)$f2
  # pwr solves with a coarser tolerance than powerkit's uniroot.
  expect_equal(result$sensitivity$effect / (1 - result$sensitivity$effect), f2, tolerance = 1e-3)
  expect_equal(result$sensitivity$effect_name, "r2")
  # No effect size is needed: an R-squared of 0 is fine for this goal.
  spec$population$r2 <- 0
  expect_silent(validate_spec(spec))
  inc <- example_spec("regression_r2_increase")
  inc$goal <- list(type = "sensitivity", n = 100L, power = 0.8)
  inc$population$r2_full <- inc$population$r2_reduced
  expect_equal(suppressWarnings(run_quietly(inc))$sensitivity$power, 0.8, tolerance = 1e-6)
})
