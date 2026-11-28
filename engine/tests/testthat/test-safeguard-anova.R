# Safeguard power for an ANOVA or ANCOVA given by one earlier study's F
# (safeguard.R): the lower end of the two-sided interval around its partial
# eta-squared (effectsize's F_to_eta2()), planned for in its place.

from_f <- function(file, f, df, df_error, protection = 0.8, ...) {
  spec <- jsonlite::read_json(system.file("specs", file, package = "powerkit"))
  spec$population <- c(list(metric = "eta_squared"), list(...))
  spec$effect_justification <- list(type = "prior_study", source = "An earlier study",
    conversion = list(from = "F", value = f, df = df, df_error = df_error), safeguard = list(protection = protection))
  spec
}

test_that("the plan uses the lower end of the interval around the earlier partial eta-squared", {
  spec <- validate_spec(from_f("anova_oneway_between.json", 6.2, 2, 57))
  ci <- effectsize::F_to_eta2(6.2, 2, 57, ci = 0.6, alternative = "two.sided")
  expect_equal(spec$population$eta_squared, ci$CI_low[[1]])
  expect_equal(spec$effect_justification$safeguard$estimate, ci$Eta2_partial[[1]])
  # The same plan as giving that lower end directly.
  result <- run_spec(spec)
  direct <- jsonlite::read_json(system.file("specs", "anova_oneway_between.json", package = "powerkit"))
  direct$population <- list(metric = "eta_squared", eta_squared = ci$CI_low[[1]])
  direct$effect_justification <- list(type = "smallest_effect_of_interest")
  expect_identical(result$n_required$n, run_spec(direct)$n_required$n)
  expect_identical(result$safeguard$effect_name, "partial eta-squared")
  # 95% protection uses the 90% interval, and needs more people.
  more <- run_spec(from_f("anova_oneway_between.json", 6.2, 2, 57, protection = 0.95))
  expect_gt(more$n_required$n, result$n_required$n)
})

test_that("a mixed ANOVA's published F works too, and an interval reaching zero is refused", {
  mixed <- validate_spec(from_f("anova_2x2_mixed.json", 15.38, 1, 118, eta_source = "published"))
  expect_lt(mixed$population$eta_squared, effectsize::F_to_eta2(15.38, 1, 118)$Eta2_partial[[1]])
  expect_error(validate_spec(from_f("anova_oneway_between.json", 1.1, 2, 57)), "reaches zero")
})
