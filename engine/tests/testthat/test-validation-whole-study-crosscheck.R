# Validation: the whole-study simulation (experimental; docs/conventions.md,
# Departure 13), cross-checked against powerkit's own calculation of each
# analysis and against Type I error. There is no published benchmark for a
# whole-study simulation, so these are agreement checks, not published
# values.
#
#   1. Each analysis's power agrees with its separate calculation from the
#      values the population implies for it: the correlation with pwr's
#      formula (Fisher's z; within .004 of the exact power at these sizes,
#      Departure 10), the interaction with powerkit's InteractionPoweR
#      simulation (E9), simple mediation with powerkit's power4mome run
#      (E10). Where the population and the analysis's own model are the
#      same (study A), only the Monte Carlo error is allowed; where the
#      population has terms an analysis leaves out (the correlation in
#      study B, whose outcome depends on the interaction), the
#      cross-check allowance is added (crosscheck_allowance(), 0.02).
#   2. The size of the departure: the joint power counted in the same
#      replications against the product of the separate powers, which is
#      what treating the analyses as unrelated gives (the plan's rule of
#      thumb for "every result must be significant").
#   3. Type I error with every path 0.
#
# Run as its own chunk: scripts/run-validation.R --only whole_study.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

whole_study_validation_spec <- function(variables, paths, analyses, n, seed, claim = "all",
                                        correlations = NULL) {
  spec <- list(
    spec_version = "0.1", kind = "whole_study",
    variables = lapply(stats::setNames(variables, variables), function(v) list(type = "continuous", label = v)),
    population = c(list(paths = paths), if (!is.null(correlations)) list(correlations = correlations)),
    analyses = analyses,
    claim = claim, alpha = 0.05,
    effect_justification = list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)"),
    goal = list(type = "power", n = n),
    options = list(nrep = validation_nrep(), ci_draws = validation_ci_draws(), seed = seed)
  )
  validate_whole_study(spec)
}

analysis_estimate <- function(result, id) {
  row <- result$analyses[result$analyses$id == id, ]
  list(power = row$power, mcse = row$mcse)
}

# Study A: simple mediation, X -> M -> Y, with the correlation of X and Y.
# The population is exactly the mediation model, and X and Y are
# bivariate normal with correlation c' + ab = .19.
study_a <- function() {
  whole_study_validation_spec(
    c("X", "M", "Y"),
    paths = list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1),
    analyses = list(
      list(id = "compare", label = "Correlation", test = "x_y", role = "main"),
      list(id = "mediation", label = "Mediation", test = "indirect", path = "X->M->Y", role = "main")
    ),
    n = 100, seed = 81001
  )
}

# Study B: a two-way interaction, with the correlation of X and Y.
study_b <- function() {
  whole_study_validation_spec(
    c("X", "W", "Y"),
    paths = list("X->Y" = 0.2, "W->Y" = -0.1, "XW->Y" = -0.15),
    correlations = list("X<->W" = -0.2),
    analyses = list(
      list(id = "compare", label = "Correlation", test = "x_y", role = "main"),
      list(id = "moderation", label = "Moderation", test = "interaction", role = "main")
    ),
    n = 150, seed = 82001
  )
}

test_that("whole study A: the correlation and the indirect effect agree with their separate calculations, and departure 13's size", {
  skip_unless_full_validation()
  result <- run_whole_study(study_a())
  # The correlation, against pwr's formula with the population's r.
  expect_equal(result$implied$compare$values[["r"]], 0.19, tolerance = 0.02)
  reference <- pwr::pwr.r.test(n = 100, r = 0.19, sig.level = 0.05)$power
  expect_power_near(analysis_estimate(result, "compare"), reference)

  # The indirect effect, against powerkit's simple mediation (E10).
  spec <- mediation_spec("process_4", "M", paths = list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1),
    path = "X->M->Y", n = 100, seed = 81002)
  reference <- engine_power(spec)
  expect_power_near(analysis_estimate(result, "mediation"), reference$power, reference_nrep = validation_nrep())

  # Departure 13: the joint power counted in the same replications, against
  # the product of the separate powers. Both analyses depend on the same
  # X -> M -> Y relationship, so they succeed together more often than
  # unrelated analyses would. The size is recorded in docs/conventions.md.
  product <- prod(result$analyses$power)
  expect_gt(result$joint$power - product, stats::qnorm(0.999) * result$joint$mcse)
  expect_lte(result$joint$power, min(result$analyses$power))
})

test_that("whole study B: the interaction and the correlation agree with their separate calculations", {
  skip_unless_full_validation()
  skip_if_not_installed("InteractionPoweR")
  result <- run_whole_study(study_b())
  # The interaction, against powerkit's InteractionPoweR simulation (E9)
  # from the implied correlations.
  v <- result$implied$moderation$values
  spec <- validation_spec(
    design = "regression_interaction", template = "two_way",
    variables = list(X = validation_variable("continuous", "Predictor"), W = validation_variable("continuous", "Moderator"),
      Y = validation_variable("continuous", "Outcome")),
    population = list(metric = "correlation", r_X_Y = round(v[["r_X_Y"]], 3), r_W_Y = round(v[["r_W_Y"]], 3),
      r_XW_Y = round(v[["r_XW_Y"]], 3), r_X_W = round(v[["r_X_W"]], 3)),
    target_test = list(effect = "interaction", method = "ols_t", alpha = 0.05),
    seed = 82002, n = 150
  )
  reference <- engine_power(spec)
  expect_power_near(analysis_estimate(result, "moderation"), reference$power, reference_nrep = validation_nrep())

  # The correlation, against pwr's formula, within the cross-check
  # allowance: the outcome also depends on the interaction, which the
  # regression of Y on X leaves out. r = .2 + (-.1)(-.2) = .22.
  # The population's r (the implied value, from one sample of 100,000,
  # is within about .003 of it).
  expect_equal(result$implied$compare$values[["r"]], 0.22, tolerance = 0.05)
  reference <- pwr::pwr.r.test(n = 150, r = 0.22, sig.level = 0.05)$power
  estimate <- analysis_estimate(result, "compare")
  expect_lte(abs(estimate$power - reference), z_for(0.999) * estimate$mcse + crosscheck_allowance(150))
})

test_that("whole study: Type I error with every path 0", {
  skip_unless_full_validation()
  spec <- whole_study_validation_spec(
    c("X", "W", "M", "Y"),
    paths = list("X->M" = 0, "M->Y" = 0, "X->Y" = 0, "W->Y" = 0, "XW->Y" = 0),
    correlations = list("X<->W" = 0),
    analyses = list(
      list(id = "compare", label = "Correlation", test = "x_y", role = "main"),
      list(id = "mediation", label = "Mediation", test = "indirect", path = "X->M->Y", role = "main"),
      list(id = "moderation", label = "Moderation", test = "interaction", role = "main")
    ),
    n = 100, seed = 83001, claim = "any"
  )
  result <- run_whole_study(spec)
  # Under "any", each of the three main tests is at .05 / 3.
  expect_type1_near(analysis_estimate(result, "compare"), 0.05 / 3)
  expect_type1_near(analysis_estimate(result, "moderation"), 0.05 / 3)
  # With both of its paths 0, the product a x b is rarely far from 0, so
  # the test of an indirect effect rejects less often than alpha; it must
  # not exceed it.
  expect_lte(analysis_estimate(result, "mediation")$power, 1.2 * 0.05 / 3)
  # The chance of at least one false positive stays at about alpha or below.
  expect_lte(result$joint$power, 1.2 * 0.05)
})

# Study C: X as two groups (next.md item 1), with a moderator: the group
# comparison is the t test of the groups (Student's, as lm() fits it),
# checked against pwr's t test at the d the population implies, with the
# cross-check allowance because the outcome also depends on the
# interaction; and the Type I error of both tests with every path 0.
study_c <- function(paths = list("X->Y" = 0.25, "W->Y" = 0.2, "XW->Y" = 0.15), seed = 83001) {
  spec <- list(
    spec_version = "0.1", kind = "whole_study",
    variables = list(X = list(type = "binary", label = "Condition"), W = list(type = "continuous", label = "Moderator"),
      Y = list(type = "continuous", label = "Outcome")),
    population = list(paths = paths, correlations = list("X<->W" = 0)),
    analyses = list(
      list(id = "groups", label = "Group difference", test = "x_y", role = "main"),
      list(id = "moderation", label = "Moderation", test = "interaction", role = "main")
    ),
    claim = "all", alpha = 0.05,
    effect_justification = list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)"),
    goal = list(type = "power", n = 120),
    options = list(nrep = validation_nrep(), seed = seed)
  )
  validate_whole_study(spec)
}

test_that("whole study C: a two-group X's comparison agrees with the t test at the implied d", {
  skip_unless_full_validation()
  result <- run_whole_study(study_c())
  d <- result$implied$groups$values[["d"]]
  reference <- pwr::pwr.t.test(n = 60, d = d, sig.level = 0.05)$power
  estimate <- analysis_estimate(result, "groups")
  expect_lte(abs(estimate$power - reference), z_for(0.999) * estimate$mcse + crosscheck_allowance(120))
})

test_that("whole study C: with every path 0, both tests keep the Type I error near alpha", {
  skip_unless_full_validation()
  result <- run_whole_study(study_c(paths = list("X->Y" = 0, "W->Y" = 0, "XW->Y" = 0), seed = 83002))
  for (id in c("groups", "moderation")) {
    expect_lt(abs(analysis_estimate(result, id)$power - 0.05), 0.015, label = id)
  }
})
