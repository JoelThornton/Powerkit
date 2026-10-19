# Regression interactions via InteractionPoweR: translation,
# reproducibility and check runs. Few replications; accuracy is checked by
# test-validation-regression-interaction.R.

test_that("a regression interaction runs on InteractionPoweR and passes its check run", {
  result <- run_quietly(sim_spec("regression_interaction", goal = list(type = "power", n = 300)))
  expect_equal(result$provenance$backend, "InteractionPoweR")
  expect_equal(result$provenance$backend_function, "InteractionPoweR::power_interaction")
  expect_true(all(result$check_run$ok))
  # The example has unreliable X and W, so the check also compares the
  # observed (attenuated) correlations.
  expect_equal(nrow(result$check_run), 8)
})

test_that("on one core, a run equals a direct power_interaction call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(sim_spec("regression_interaction", goal = list(type = "power", n = 300)))
  set.seed(7)
  direct <- suppressWarnings(InteractionPoweR::power_interaction(
    n.iter = 100, N = 300,
    r.x1.y = -0.3, r.x2.y = 0.2, r.x1x2.y = 0.1, r.x1.x2 = -0.1,
    rel.x1 = 0.8, rel.x2 = 0.85, rel.y = 1, alpha = 0.05
  ))
  expect_equal(result$curve$power, direct$pwr[1])
})

test_that("the check run catches X and W swapped", {
  spec <- validate_quietly(sim_spec("regression_interaction"))
  inputs <- interactionpower_inputs(spec)
  expect_true(all(interactionpower_check_run(spec, inputs, seed = 1)$ok))
  swapped <- inputs
  swapped[c("r.x1.y", "r.x2.y")] <- inputs[c("r.x2.y", "r.x1.y")]
  expect_false(all(interactionpower_check_run(spec, swapped, seed = 1)$ok))
})

test_that("a sample-size search brackets n with the analytic power", {
  spec <- sim_spec(
    "regression_interaction", nrep = 100,
    population = list(metric = "correlation", r_X_Y = 0.2, r_W_Y = 0.2, r_XW_Y = 0.2, r_X_W = 0),
    goal = list(type = "sample_size", power = 0.8)
  )
  result <- run_quietly(spec)
  est <- result$n_required
  expect_true(est$lower <= est$n && est$n <= est$upper)
  expect_true(nrow(result$curve) >= 5)
})

test_that("a binary X or W isn't available yet", {
  spec <- sim_spec("regression_interaction")
  spec$variables$W <- list(type = "binary", label = "Group", levels = list("A", "B"))
  error <- expect_error(run_quietly(spec), "binary.*aren't available yet", class = "powerkit_not_available")
  expect_match(conditionMessage(error), "'Group (W)' is yes/no", fixed = TRUE)
  expect_match(conditionMessage(error), "Treating it as continuous may give an inaccurate power estimate", fixed = TRUE)
  # A 2x2 ANOVA fits only when both X and W are binary.
  expect_no_match(conditionMessage(error), "ANOVA", fixed = TRUE)

  spec$variables$X <- list(type = "binary", label = "Condition", levels = list("Control", "Treatment"))
  error <- expect_error(run_quietly(spec), "binary.*aren't available yet", class = "powerkit_not_available")
  expect_match(conditionMessage(error), "'Condition (X)' and 'Group (W)' are yes/no", fixed = TRUE)
  expect_match(conditionMessage(error), "Treating them as continuous may give an inaccurate power estimate", fixed = TRUE)
  expect_match(conditionMessage(error), "Because both are yes/no, you can use a 2x2 ANOVA design instead.", fixed = TRUE)
})

test_that("the smallest detectable interaction comes from power_interaction_r2, the others kept", {
  result <- run_quietly(sim_spec("regression_interaction", goal = list(type = "sensitivity", n = 300, power = 0.8)))
  s <- result$sensitivity
  expect_equal(result$provenance$method, "analytic")
  expect_equal(result$provenance$backend_function, "InteractionPoweR::power_interaction_r2")
  expect_true(s$approximation)
  expect_equal(s$effect_name, "r_XW_Y")
  expect_gt(s$effect, 0)
  # Directly: InteractionPoweR's analytic power at the effect found is the target.
  direct <- suppressWarnings(InteractionPoweR::power_interaction_r2(
    N = 300, r.x1.y = -0.3, r.x2.y = 0.2, r.x1x2.y = s$effect, r.x1.x2 = -0.1,
    rel.x1 = 0.8, rel.x2 = 0.85, rel.y = 1, alpha = 0.05
  ))
  expect_equal(direct$pwr[1], 0.8, tolerance = 1e-6)
  expect_equal(s$power, direct$pwr[1])
  # A negative interaction correlation keeps its sign.
  spec <- sim_spec("regression_interaction", goal = list(type = "sensitivity", n = 300, power = 0.8))
  spec$population$r_XW_Y <- -0.1
  expect_equal(run_quietly(spec)$sensitivity$effect, -s$effect, tolerance = 1e-6)
})

test_that("the smallest detectable interaction says plainly when none is possible", {
  spec <- sim_spec("regression_interaction", goal = list(type = "sensitivity", n = 20, power = 0.99))
  expect_error(run_quietly(spec), "No correlation of the interaction with Y reaches the target power", class = "powerkit_run_error")
  spec$options$method <- "simulation"
  spec$goal$n <- 300
  expect_error(run_quietly(spec), "Sensitivity analysis uses the exact method", class = "powerkit_run_error")
})
