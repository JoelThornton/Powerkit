# The correction for publication bias and uncertainty on the ANOVA screens
# (bias-correction.R): BUCSS's own sample sizes, through
# replication_bucss(), from a design spec whose effect is one earlier
# study's F. These tests check the mapping onto BUCSS's arguments; BUCSS's
# numbers are checked in test-replication-bucss.R.

skip_if_not_installed("BUCSS")

from_f <- function(file, f, df, df_error, n, ...) {
  spec <- jsonlite::read_json(system.file("specs", file, package = "powerkit"))
  spec$population <- c(list(metric = "eta_squared"), list(...))
  spec$effect_justification <- list(type = "prior_study", source = "An earlier study",
    conversion = list(from = "F", value = f, df = df, df_error = df_error), bias_correction = list(n = n))
  spec$goal <- list(type = "sample_size", power = 0.8)
  spec
}

test_that("a one-way ANOVA's correction is BUCSS's one-way plan for the earlier F", {
  result <- run_spec(from_f("anova_oneway_between.json", 6.2, 2, 57, 60))
  direct <- replication_bucss("anova_between", 6.2, 60, levels_a = 3, effect = "factor_a", power = 0.8, assurance = c(0.5, 0.8))
  expect_equal(result$bias_correction$sizes, direct$sizes)
  expect_match(result$bias_correction$function_used, "ss_buc_one_way_anova", fixed = TRUE)
  # The plan's own result still uses the estimate as published.
  expect_lt(result$n_required$n, result$bias_correction$sizes$n[1])
  expect_true("BUCSS" %in% names(result$provenance$packages))
})

test_that("a mixed design maps its between factor and its within factor, and the interaction", {
  spec <- from_f("anova_2x2_mixed.json", 15.38, 1, 118, 120, eta_source = "published")
  args <- bias_correction_args(validate_spec(spec))
  expect_identical(args$design, "anova_mixed")
  expect_identical(args$effect, "interaction")
  expect_identical(c(args$levels_a, args$levels_b), c(2L, 2L))
  expect_identical(args$epsilon, 1)
})

test_that("the correction is refused where it can't be made, in plain words", {
  wrong_df <- from_f("anova_oneway_between.json", 6.2, 1, 57, 60)
  expect_error(validate_spec(wrong_df), "same design")
  # Another goal (a curve worked out from the same plan) runs without it.
  power_goal <- from_f("anova_oneway_between.json", 6.2, 2, 57, 60)
  power_goal$goal <- list(type = "power", n = 60)
  expect_null(run_spec(power_goal)$bias_correction)
  ancova <- from_f("anova_oneway_ancova.json", 6.2, 2, 56, 60, covariates = 1L)
  expect_error(validate_spec(ancova), "without covariates")
})
