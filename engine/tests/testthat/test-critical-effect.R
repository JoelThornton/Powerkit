# The critical effect size (critical-effect.R; Perugini et al., 2025): the
# smallest observed effect that would be significant at the n analysed.

critical_spec <- function(name, goal = list(type = "power", n = 64L), ...) {
  spec <- example_spec(name)
  spec$goal <- goal
  spec$options <- list(seed = 1L)
  if (identical(name, "independent_t")) spec$target_test$method <- "student_t"
  spec$target_test <- utils::modifyList(spec$target_test, list(...))
  spec
}

test_that("each t-test and the correlation report their critical effect at the n analysed (Perugini et al.'s Table 1)", {
  two <- run_spec(critical_spec("independent_t"))$critical_effect
  expect_identical(two$effect_name, "d")
  expect_equal(two$df, 62)
  expect_equal(two$value, stats::qt(0.975, 62) * sqrt(1 / 32 + 1 / 32))
  one <- run_spec(critical_spec("one_sample_t"))$critical_effect
  expect_equal(one$value, stats::qt(0.975, 63) / sqrt(64))
  paired <- run_spec(critical_spec("paired_t"))$critical_effect
  expect_identical(paired$effect_name, "d_z")
  expect_equal(paired$value, stats::qt(0.975, 63) / sqrt(64))
  r <- run_spec(critical_spec("correlation"))$critical_effect
  expect_identical(r$effect_name, "r")
  t_c <- stats::qt(0.975, 62)
  expect_equal(r$value, t_c / sqrt(62 + t_c^2))
})

test_that("a one-sided test, unequal groups and a required n change the critical effect as they should", {
  one_sided <- run_spec(critical_spec("independent_t", alternative = "greater"))$critical_effect
  expect_equal(one_sided$value, stats::qt(0.95, 62) * sqrt(1 / 32 + 1 / 32))
  expect_identical(one_sided$alternative, "greater")
  unequal <- critical_spec("independent_t", goal = list(type = "power", n = 90L))
  unequal$options$allocation_ratio <- 2
  ce <- run_spec(unequal)$critical_effect
  expect_equal(ce$groups, c(30, 60))
  expect_equal(ce$value, stats::qt(0.975, 88) * sqrt(1 / 30 + 1 / 60))
  needed <- run_spec(critical_spec("independent_t", goal = list(type = "sample_size", power = 0.8)))
  expect_equal(needed$critical_effect$n, needed$n_required$n)
  # The critical effect is smaller than the effect powered for: at 80% power
  # the observed effect must clear a bar below the true one.
  expect_lt(needed$critical_effect$value, 0.4)
})

test_that("designs outside Perugini et al.'s formulas, and the justified alpha, give none", {
  expect_null(run_spec(critical_spec("independent_t", method = "welch_t", alternative = "two_sided"))$critical_effect)
  expect_null(critical_effect(validate_spec(critical_spec("correlation", method = "spearman")), 64))
  jalpha <- critical_spec("independent_t", goal = list(type = "justified_alpha", n = 64L))
  expect_null(run_spec(jalpha)$critical_effect)
  expect_null(critical_effect(list(template = "two_level"), 100))
})
