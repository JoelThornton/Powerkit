# Validation: the whole-study simulation measured twice (experimental;
# docs/conventions.md, Departure 13), for two mediators and for moderated
# mediation. There is no published benchmark for a whole-study simulation,
# so these are agreement checks against powerkit's own cards.
#
# Each analysis adjusts Y for the first measurement B. With B unrelated to
# X, W and the mediators, adjusting for B leaves every path to Y as it is
# in raw units and removes B's share of Y's variance (p_BY^2), so each
# standardised path to Y in the model without B is the whole-study path
# divided by sqrt(1 - p_BY^2). The serial mediation card (E12) and the
# moderated mediation card (E14), run at those paths, then estimate the
# same power, up to the one degree of freedom B takes.
#
# Run as part of the whole-study chunk: scripts/run-validation.R --only
# whole_study. Skipped unless POWERKIT_FULL_VALIDATION=true.

twice_spec <- function(variables, paths, correlations, analyses, n, seed, mediators = NULL) {
  spec <- list(
    spec_version = "0.1", kind = "whole_study",
    variables = lapply(stats::setNames(variables, variables), function(v) list(type = "continuous", label = v)),
    population = list(paths = paths, correlations = correlations),
    analyses = analyses,
    claim = "all", alpha = 0.05,
    effect_justification = list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)"),
    goal = list(type = "power", n = n),
    options = list(nrep = validation_nrep(), ci_draws = validation_ci_draws(), seed = seed)
  )
  if (!is.null(mediators)) spec$mediators <- mediators
  validate_whole_study(spec)
}

twice_estimate <- function(result, id) {
  row <- result$analyses[result$analyses$id == id, ]
  list(power = row$power, mcse = row$mcse)
}

# The paths to Y in the model without B: divided by sqrt(1 - p_BY^2).
without_baseline <- function(paths, p_by) {
  to_y <- grepl("->Y$", names(paths)) & names(paths) != "B->Y"
  paths[to_y] <- lapply(paths[to_y], function(p) p / sqrt(1 - p_by^2))
  paths[names(paths) != "B->Y"]
}

test_that("measured twice, two mediators in a chain: the indirect effect agrees with the serial mediation card", {
  skip_unless_full_validation()
  paths <- list("X->M1" = 0.35, "X->M2" = 0, "M1->M2" = 0.35, "X->Y" = 0.05, "M1->Y" = 0.05, "M2->Y" = 0.3, "B->Y" = 0.6)
  result <- run_whole_study(twice_spec(
    c("X", "M1", "M2", "B", "Y"), paths,
    correlations = list("X<->B" = 0),
    analyses = list(list(id = "mediation", label = "Serial mediation", test = "indirect", path = "X->M1->M2->Y", role = "main")),
    n = 150, seed = 85001, mediators = "serial"
  ))
  expect_true(all(result$check_run$ok))
  reference <- engine_power(mediation_spec("process_6", c("M1", "M2"), paths = without_baseline(paths, 0.6),
    path = "X->M1->M2->Y", n = 150, seed = 85002))
  expect_power_near(twice_estimate(result, "mediation"), reference$power, reference_nrep = validation_nrep())
})

test_that("measured twice, moderated mediation (the mediator to the outcome): the index agrees with the moderated mediation card", {
  skip_unless_full_validation()
  paths <- list("X->M" = 0.35, "M->Y" = 0.25, "W->Y" = 0.15, "MW->Y" = 0.15, "X->Y" = 0.05, "B->Y" = 0.6)
  result <- run_whole_study(twice_spec(
    c("X", "W", "M", "B", "Y"), paths,
    correlations = list("X<->W" = 0.1, "X<->B" = 0, "W<->B" = 0),
    analyses = list(list(id = "modmed", label = "Moderated mediation", test = "index_of_mome", moderated_link = "m_y", role = "main")),
    n = 200, seed = 85003
  ))
  expect_true(all(result$check_run$ok))
  card <- example_spec("process_14")
  card$population$paths <- without_baseline(paths, 0.6)
  card$population$correlations <- list("X<->W" = 0.1)
  card$goal <- list(type = "power", n = 200L)
  card$options <- list(nrep = validation_nrep(), ci_draws = validation_ci_draws(), seed = 85004)
  reference <- engine_power(card)
  expect_power_near(twice_estimate(result, "modmed"), reference$power, reference_nrep = validation_nrep())
})
