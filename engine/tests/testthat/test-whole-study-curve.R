# A rough power curve for a whole study (whole_study_curve()).

curve_regression_spec <- function() {
  spec <- jsonlite::read_json(system.file("whole-study", "example.json", package = "powerkit"), simplifyVector = FALSE)
  spec$analyses <- spec$analyses[c(1, 3)]
  spec$analyses[[2]]$role <- "main"
  spec$variables$M <- NULL
  spec$population$paths <- list(`X->Y` = 0.25, `W->Y` = 0.1, `XW->Y` = 0.15)
  spec$options$ci_draws <- NULL
  spec
}

test_that("a regression's rough curve rises with n and reads power by the claim", {
  skip_on_cran()
  spec <- curve_regression_spec()
  curve <- whole_study_curve(spec, multipliers = c(0.5, 1, 2), nrep = 100L)
  expect_s3_class(curve, "powerkit_whole_study_curve")
  expect_identical(curve$curve$n, c(100, 200, 400))
  expect_identical(curve$rule, "all")
  expect_true(curve$curve$power[3] > curve$curve$power[1])
  # Under "all", the joint power is at most each main analysis's power.
  each <- curve$analyses
  for (n in curve$curve$n) {
    expect_lte(curve$curve$power[curve$curve$n == n], min(each$power[each$n == n]) + 1e-12)
  }
  # The same seed gives the same curve; the middle matches a full run at n.
  again <- whole_study_curve(spec, multipliers = c(0.5, 1, 2), nrep = 100L)
  expect_identical(again$curve, curve$curve)
  spec$options$nrep <- 100L
  full <- run_whole_study(spec)
  expect_equal(full$joint$power, curve$curve$power[2])
  expect_identical(curve$provenance$backend, "power4mome")
  expect_output(print(curve), "Rough power curve")
})

test_that("an experiment's curve keeps equal groups, and a mediation is refused plainly", {
  skip_on_cran()
  exp <- unclass(read_spec(system.file("specs", "anova_2x2_between.json", package = "powerkit")))
  exp$goal <- NULL; exp$options <- NULL; exp$effect_justification <- NULL
  spec <- list(spec_version = "0.1", kind = "whole_study", experiment = exp,
    analyses = list(list(id = "t1", label = "A", test = "anova_effect", effect = "main_effect_A", role = "main")),
    claim = "each", alpha = 0.05, effect_justification = list(type = "none"),
    goal = list(type = "power", n = 92L), options = list(nrep = 100L, seed = 11L))
  curve <- whole_study_curve(spec, multipliers = c(0.5, 1), nrep = 50L)
  expect_identical(curve$curve$n, c(48, 92))
  expect_identical(curve$provenance$backend, "Superpower")
  mediation <- jsonlite::read_json(system.file("whole-study", "example.json", package = "powerkit"), simplifyVector = FALSE)
  expect_error(whole_study_curve(mediation), "mediation")
  mediation$goal <- list(type = "sample_size", power = 0.8)
  expect_error(whole_study_curve(mediation), "goal")
})
