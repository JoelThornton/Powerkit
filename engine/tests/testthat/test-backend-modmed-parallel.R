# Moderated mediation (PROCESS models 7 and 14) with parallel mediators:
# the index of moderated mediation for one chosen mediator, via power4mome.

parallel_modmed <- function(template = "process_7", path = "X->M1->Y", goal = NULL) {
  spec <- example_spec("process_7_parallel")
  spec$template <- template
  if (template == "process_14") {
    spec$population$paths <- list(
      "X->M1" = 0.3, "X->M2" = 0.2, "M1->Y" = 0.3, "M2->Y" = 0.2,
      "W->Y" = -0.1, "M1W->Y" = 0.15, "M2W->Y" = 0.1, "X->Y" = 0.05
    )
  }
  spec$target_test$path <- path
  spec$options$nrep <- 100
  spec$options$ci_draws <- 200
  if (!is.null(goal)) spec$goal <- goal
  spec
}

lines_of <- function(x) strsplit(x, "\n", fixed = TRUE)[[1]]

test_that("each mediator gets its own equation, and the chosen one is tested", {
  inputs <- power4mome_inputs(validate_quietly(parallel_modmed()))
  expect_equal(lines_of(inputs$model), c("M1 ~ X + W + X:W", "M2 ~ X + W + X:W", "Y ~ X + M1 + M2", "M1 ~~ M2"))
  expect_true(all(c("M1 ~ X:W: -0.15", "M2 ~ X:W: -0.1", "X ~~ W: 0") %in% lines_of(inputs$pop_es)))
  expect_equal(inputs$test_name, "test_index_of_mome")
  expect_equal(inputs$test_args[c("x", "m", "y", "w")], list(x = "X", m = "M1", y = "Y", w = "W"))

  inputs <- power4mome_inputs(validate_quietly(parallel_modmed("process_14", "X->M2->Y")))
  expect_equal(lines_of(inputs$model), c("M1 ~ X", "M2 ~ X", "Y ~ X + M1 + M2 + W + M1:W + M2:W", "M1 ~~ M2"))
  expect_true("Y ~ M2:W: 0.1" %in% lines_of(inputs$pop_es))
  expect_equal(inputs$test_args$m, "M2")
})

test_that("with a product term, the residual correlation is passed as it is", {
  # power4mome reads 'M1 ~~ M2' as the residual correlation when the model
  # has a product term (checked by simulation; see power4mome_inputs()).
  inputs <- power4mome_inputs(validate_quietly(parallel_modmed()))
  expect_true("M1 ~~ M2: 0.3" %in% lines_of(inputs$pop_es))
})

test_that("the mediator to test must be named, and must be in the model", {
  spec <- parallel_modmed()
  spec$target_test$path <- NULL
  expect_spec_problem(spec, "say which mediator's index of moderated mediation")
  expect_spec_problem(parallel_modmed(path = "X->M3->Y"), "isn't an indirect path in this model")
  spec <- example_spec("process_7")
  spec$population$residual_correlations <- list("M1<->M2" = 0.2)
  expect_spec_problem(spec, "only used when there are two or more mediators")
  spec <- parallel_modmed()
  spec$variables$M3 <- spec$variables$M2
  spec$variables$M2 <- NULL
  expect_spec_problem(spec, "with no gaps")
})

test_that("a zero first-stage interaction for the chosen mediator can't be the basis of a sample size search", {
  spec <- parallel_modmed(goal = list(type = "sample_size", power = 0.8))
  spec$population$paths[["XW->M1"]] <- 0
  expect_spec_problem(spec, "zero", fixed = TRUE)
  # The other mediator's interaction doesn't matter for this index.
  spec$population$paths[["XW->M1"]] <- -0.15
  spec$population$paths[["XW->M2"]] <- 0
  expect_s3_class(validate_quietly(spec), "powerkit_spec")
})

test_that("both models pass their check run, recovering every path and the residual correlation", {
  skip_on_cran()
  for (template in c("process_7", "process_14")) {
    spec <- validate_quietly(parallel_modmed(template, goal = list(type = "power", n = 200)))
    check <- route_spec(spec, seed = 3)$check_run()
    expect_true(all(check$ok), label = template)
    expect_true("residual M1<->M2" %in% check$parameter, label = template)
  }
})

test_that("the exported script reproduces powerkit for parallel mediators", {
  skip_unless_scripts_can_run()
  spec <- validate_quietly(parallel_modmed("process_14", "X->M2->Y", goal = list(type = "power", n = 200)))
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_true(any(grepl("index of moderated mediation through M2", run$script, fixed = TRUE)))
})
