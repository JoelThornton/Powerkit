# The Bayes factor test of a contingency table (BayesFactor's
# contingencyTableBF(), JASP's defaults), simulated with Spower.

table_bf_spec <- function(n = 120, probs = list(list(0.25, 0.10), list(0.15, 0.15), list(0.10, 0.25)), plan = NULL, nrep = 200L) {
  spec <- example_spec("chi_square_independence")
  spec$population <- list(metric = "proportion", probabilities = probs)
  spec$target_test <- Filter(Negate(is.null), list(effect = "association", method = "bayes_factor", evidence_threshold = 10, sampling_plan = plan))
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 3L, nrep = nrep)
  spec
}

test_that("each simulated study is scored by contingencyTableBF() with JASP's sampling plan by default", {
  inputs <- bftable_inputs(table_bf_spec())
  expect_identical(inputs$plan, "rows_fixed")
  expect_equal(inputs$a, 1)
  table <- matrix(c(30, 10, 18, 20, 9, 33), 3, byrow = TRUE)
  direct <- BayesFactor::extractBF(BayesFactor::contingencyTableBF(table, sampleType = "indepMulti", fixedMargin = "rows", priorConcentration = 1), logbf = TRUE)$bf
  expect_equal(bftable_log_bf10(table, 1, "rows_fixed"), direct)
  joint <- BayesFactor::extractBF(BayesFactor::contingencyTableBF(table, sampleType = "jointMulti", priorConcentration = 1), logbf = TRUE)$bf
  expect_equal(bftable_log_bf10(table, 1, "joint_multinomial"), joint)
  # The experiment's draw: the same table the seed gives directly.
  set.seed(5)
  drawn <- matrix(stats::rmultinom(1, 120, as.vector(t(inputs$probs))), 3, byrow = TRUE)
  set.seed(5)
  expect_identical(p_bayes_table(120, inputs$probs, 10, 1, "rows_fixed"), bftable_log_bf10(drawn, 1, "rows_fixed") >= log(10))
})

test_that("power, the no-association side and the check run are reported, and the run is reproducible", {
  spec <- table_bf_spec()
  result <- run_spec(spec)
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_identical(result$provenance$method, "simulation")
  expect_gt(result$curve$power, 0.3)
  expect_lt(result$curve$power, 0.95)
  expect_true(all(result$check_run$ok))
  expect_identical(result$bayes$sampling_plan, "rows_fixed")
  expect_gt(result$bayes$evidence_for_null, 0)
  expect_lt(result$bayes$misleading_evidence, 0.05)
  expect_identical(run_spec(spec)$curve$power, result$curve$power)
})

test_that("the exported script reproduces the simulated power", {
  skip_unless_scripts_can_run()
  spec <- table_bf_spec(nrep = 100L)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "contingencyTableBF", fixed = TRUE)
})

test_that("the Bayes factor table test is refused where it doesn't apply", {
  spec <- table_bf_spec()
  spec$population <- list(metric = "w", w = 0.3)
  expect_spec_problem(spec, "not Cohen's w")
  spec <- table_bf_spec()
  spec$target_test$prior_scale <- 0.5
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- example_spec("chi_square_independence")
  spec$target_test$sampling_plan <- "poisson"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})
