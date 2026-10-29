# A yes/no outcome with two crossed factors (logistic regression with both
# factors and their interaction), simulated with Spower's p_glm().

factorial_logit_spec <- function(effect = "main_effect_A", goal = list(type = "power", n = 600), probabilities = NULL) {
  spec <- example_spec("logistic_factorial")
  spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options$nrep <- 200
  if (!is.null(probabilities)) spec$population$probabilities <- probabilities
  spec
}

test_that("the coefficients give back every cell's proportion, with effect coding", {
  spec <- validate_quietly(factorial_logit_spec())
  design <- logistic_factorial_design(spec)
  fitted <- stats::plogis(drop(stats::model.matrix(~ A * B, design$cells) %*% design$betas))
  p <- logistic_factorial_probabilities(spec)
  expect_equal(unname(fitted), p[cbind(as.integer(design$cells$A), as.integer(design$cells$B))])
  expect_equal(design$test, "A1 = 0")
  expect_equal(logistic_factorial_design(validate_quietly(factorial_logit_spec("main_effect_B")))$test, c("B1 = 0", "B2 = 0"))
  expect_equal(logistic_factorial_design(validate_quietly(factorial_logit_spec("interaction")))$test, c("A1:B1 = 0", "A1:B2 = 0"))
  # Equal cells: the design has n / 6 people in each of the six cells.
  expect_equal(as.vector(table(design$X(60)$A, design$X(60)$B)), rep(10, 6))
})

test_that("it runs on Spower's p_glm(), passes its check run, and equals a direct Spower call", {
  spec <- validate_quietly(factorial_logit_spec())
  result <- suppressWarnings(run_spec(spec))
  expect_equal(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "p_glm", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  design <- logistic_factorial_design(spec)
  X <- design$X(600)
  betas <- design$betas
  direct <- with_seed(spec$options$seed, quietly(Spower::Spower(
    Spower::p_glm(y ~ A * B, X = X, betas = betas, test = "A1 = 0", family = stats::binomial()),
    replications = 200, parallel = FALSE, verbose = FALSE
  )))
  expect_equal(result$curve$power, direct$power)
})

test_that("a table that doesn't fit the factors, and no effect, are refused", {
  expect_spec_problem(factorial_logit_spec(probabilities = list(list(0.3, 0.4), list(0.4, 0.45))), "needs 2 rows")
  # Equal log-odds on average across B in both rows of A: no main effect of A.
  p <- list(list(0.3, 0.4, 0.25), list(0.3, 0.4, 0.25))
  expect_spec_problem(factorial_logit_spec(goal = list(type = "sample_size", power = 0.8), probabilities = p), "zero", fixed = TRUE)
})

test_that("sample sizes are whole numbers of people per cell", {
  spec <- validate_quietly(factorial_logit_spec())
  expect_equal(route_spec(spec)$n_step, 6)
  spec$goal <- list(type = "power", n = 601)
  expect_error(validate_quietly(spec), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result", {
  skip_on_cran()
  spec <- validate_quietly(factorial_logit_spec("interaction"))
  result <- suppressWarnings(run_spec(spec))
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
})
