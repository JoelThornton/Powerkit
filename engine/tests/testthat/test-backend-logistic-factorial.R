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
  # On one core, as the direct call is: spread over cores (POWERKIT_CORES),
  # the replications draw from other random streams.
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
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

# The likelihood-ratio test -------------------------------------------------------

test_that("each simulated likelihood-ratio test equals car::Anova()'s type III test", {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    spec <- validate_quietly(factorial_logit_spec(effect))
    design <- logistic_factorial_design(spec)
    X <- design$X(120)
    fit <- with_seed(7, Spower::p_glm(y ~ A * B, X = X, betas = design$betas, test = NULL,
      family = stats::binomial(), return_analysis = TRUE))
    term <- switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
    expected <- car::Anova(fit, type = 3, test.statistic = "LR")[term, "Pr(>Chisq)"]
    p <- with_seed(7, p_logistic_factorial_lr(y ~ A * B, X = X, betas = design$betas, tested = design$tested))
    expect_equal(p, expected, tolerance = 1e-8, label = effect)
  }
})

test_that("the likelihood-ratio test runs, passes its check run, and its script reproduces it", {
  skip_on_cran()
  spec <- factorial_logit_spec("interaction")
  spec$target_test$method <- "likelihood_ratio"
  spec <- validate_quietly(spec)
  result <- suppressWarnings(run_spec(spec))
  expect_match(result$provenance$backend_function, "p_logistic_factorial_lr", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
})

test_that("with sparse cells the likelihood-ratio test keeps power the Wald test loses", {
  # Proportions near 0 with 20 people per cell: the Wald test's standard
  # errors grow with a large estimate, so it
  # rejects far less often than the likelihood-ratio test on the same data.
  at <- function(method) {
    spec <- factorial_logit_spec("interaction", goal = list(type = "power", n = 80),
      probabilities = list(list(0.05, 0.1), list(0.1, 0.7)))
    spec$variables$B$levels <- list("b1", "b2")
    spec$target_test$method <- method
    spec$options$nrep <- 1000
    suppressWarnings(run_spec(validate_quietly(spec)))$curve$power
  }
  expect_gt(at("likelihood_ratio") - at("wald_chi_square"), 0.08)
})

# Firth's penalised likelihood-ratio test ------------------------------------------

test_that("each simulated Firth test equals logistf's logistftest() on the same data", {
  skip_if_not_installed("logistf")
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    spec <- validate_quietly(factorial_logit_spec(effect))
    design <- logistic_factorial_design(spec)
    X <- design$X(120)
    fit <- with_seed(7, Spower::p_glm(y ~ A * B, X = X, betas = design$betas, test = NULL,
      family = stats::binomial(), return_analysis = TRUE))
    firth <- logistf::logistf(y ~ A * B, data = fit$data, pl = FALSE)
    columns <- which(names(stats::coef(firth)) %in% design$tested)
    expected <- logistf::logistftest(firth, test = columns)$prob[[1]]
    p <- with_seed(7, p_logistic_factorial_firth(y ~ A * B, X = X, betas = design$betas, tested = design$tested))
    expect_equal(p, expected, tolerance = 1e-8, label = effect)
    expect_length(columns, length(design$tested))
  }
})

test_that("Firth's test runs, passes its check run, and its script reproduces it", {
  skip_on_cran()
  skip_if_not_installed("logistf")
  spec <- factorial_logit_spec("interaction")
  spec$target_test$method <- "firth_likelihood_ratio"
  spec <- validate_quietly(spec)
  result <- suppressWarnings(run_spec(spec))
  expect_match(result$provenance$backend_function, "p_logistic_factorial_firth", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
})
