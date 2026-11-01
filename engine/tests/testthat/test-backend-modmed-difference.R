# W on both links or the direct path (PROCESS models 8, 58 and 59, E38):
# power4mome with powerkit's test of the difference between conditional
# indirect effects.

difference_example <- function(name, ...) {
  spec <- example_spec(name)
  spec$options$nrep <- 100L
  spec$options$ci_draws <- 200L
  # Replaced, not merged: modifyList() would merge an unnamed list such as
  # w_values into the old one.
  changes <- list(...)
  spec$target_test[names(changes)] <- changes
  spec
}

test_that("each model's equations, and model 58's fitted model leaves out the residual covariance of M with W", {
  inputs <- power4mome_inputs(validate_spec(difference_example("process_58")))
  expect_identical(inputs$test_name, "test_cond_indirect_diff")
  expect_equal(unlist(inputs$test_args[c("w_from", "w_to")]), c(w_from = -1, w_to = 1))
  lines <- strsplit(inputs$fit_model, "\n", fixed = TRUE)[[1]]
  expect_false("M ~~ W" %in% lines)
  expect_true("M ~~ M:W" %in% lines)
  expect_null(power4mome_inputs(validate_spec(difference_example("process_8")))$fit_model)
  model_59 <- path_model(validate_spec(difference_example("process_59")))
  expect_setequal(model_59$equations$Y, c("X", "M", "W", "XW", "MW"))
})

test_that("models 8, 58 and 59 run, and the check run recovers every path", {
  for (name in c("process_8", "process_58", "process_59")) {
    result <- suppressWarnings(run_spec(difference_example(name)))
    expect_true(all(result$check_run$ok), label = name)
    expect_match(result$provenance$backend_function, "test_cond_indirect_diff", fixed = TRUE)
  }
})

test_that("the difference's population value, and the effect each model must test", {
  spec <- validate_spec(difference_example("process_58"))
  # (a1 + a3 w)(b1 + b3 w) at w = 1 minus at w = -1.
  expect_equal(cond_indirect_difference_value(spec), (0.3 + 0.15) * (0.3 + 0.1) - (0.3 - 0.15) * (0.3 - 0.1))
  wrong <- difference_example("process_58")
  wrong$target_test$effect <- "index_of_moderated_mediation"
  expect_spec_problem(wrong, "no single index")
  same <- difference_example("process_8", w_values = list(1, 1))
  expect_spec_problem(same, "two different values")
})

test_that("the exported script reproduces the result with power4mome and manymome alone", {
  spec <- difference_example("process_58")
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
})
