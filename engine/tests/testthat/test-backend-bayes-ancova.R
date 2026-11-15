# The Bayes factor of an ANCOVA effect (E23): JASP's Bayesian ANCOVA, the
# effect's inclusion Bayes factor from BayesFactor's generalTestBF(),
# simulated with Spower.

bfancova_spec <- function(two = FALSE, n = 120, nrep = 100, ...) {
  file <- if (two) "anova_factorial_ancova.json" else "anova_oneway_ancova.json"
  spec <- read_spec(system.file("specs", file, package = "powerkit"))
  spec$target_test <- utils::modifyList(list(effect = if (two) "interaction" else "main_effect_A", method = "bayes_factor",
    evidence_threshold = 10), list(...))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  spec
}

test_that("the inputs read the adjusted means, the covariates and JASP's default priors", {
  inputs <- bfancova_inputs(validate_quietly(bfancova_spec()))
  expect_equal(inputs$means, matrix(c(20, 18, 16), ncol = 1))
  expect_identical(c(inputs$r2, inputs$covariates), c(0.36, 1))
  expect_identical(inputs$term, "A")
  expect_identical(c(inputs$prior_scale, inputs$prior_scale_covariates), c(0.5, 0.354))
  expect_identical(inputs$inclusion, "all_models")
  two <- bfancova_inputs(validate_quietly(bfancova_spec(two = TRUE, prior_scale_covariates = 0.5, inclusion = "matched_models")))
  expect_identical(dim(two$means), c(2L, 3L))
  expect_identical(two$term, "A:B")
  expect_identical(two$prior_scale_covariates, 0.5)
  expect_identical(two$inclusion, "matched_models")
})

test_that("the simulated data have equal cells, the adjusted means and the covariates' R-squared", {
  set.seed(4)
  means <- matrix(c(20, 18, 16), ncol = 1)
  data <- bfancova_data(60000, means, 6, 0.36, 2)
  expect_identical(as.vector(table(data$A)), rep(20000L, 3))
  fit <- stats::lm(y ~ A + cov1 + cov2, data = data)
  expect_lt(max(abs(stats::coef(fit)[c("A2", "A3")] - c(-2, -4))), 0.1)
  centred <- data$y - stats::ave(data$y, data$A)
  expect_equal(stats::sd(centred), 6, tolerance = 0.01)
  expect_equal(summary(stats::lm(centred ~ data$cov1 + data$cov2))$r.squared, 0.36, tolerance = 0.02)
})

test_that("the effect's Bayes factor is generalTestBF()'s inclusion Bayes factor with JASP's priors", {
  set.seed(5)
  data <- bfancova_data(90, matrix(c(20, 18, 16), ncol = 1), 6, 0.36, 1)
  set.seed(6)
  ours <- bfancova_log_bf(data, "A", 0.5, 0.354, "all_models")
  set.seed(6)
  bf <- BayesFactor::generalTestBF(y ~ A + cov1, data = data, whichModels = "withmain", rscaleFixed = 0.5, rscaleCont = 0.354,
    progress = FALSE)
  direct <- bayestestR::bayesfactor_inclusion(bf)
  expect_equal(ours, direct$log_BF[rownames(direct) == "A"])
  # With one factor and one covariate there are three models besides the
  # null: A, the covariate, and both.
  expect_length(bf, 3)
})

test_that("a run gives power, the no-effect side and a check run that recovers the inputs, for one factor and two", {
  result <- run_quietly(bfancova_spec())
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_true(result$curve$power > 0.3 && result$curve$power < 1)
  expect_true(all(result$check_run$ok))
  expect_identical(result$bayes$prior_scale_covariates, 0.354)
  expect_lte(result$bayes$misleading_evidence, 0.1)
  two <- run_quietly(bfancova_spec(two = TRUE, n = 180, evidence_threshold = 3))
  expect_true(all(two$check_run$ok))
  expect_true(two$curve$power >= 0 && two$curve$power < 1)
})

test_that("a sample size search uses equal cells", {
  spec <- bfancova_spec(two = TRUE)
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(bfancova_backend(validate_quietly(spec))$n_step, 6L)
  expect_identical(bfancova_backend(validate_quietly(bfancova_spec()))$n_step, 3L)
})

test_that("problems are named in plain words", {
  spec <- bfancova_spec()
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06, covariates = 1)
  expect_spec_problem(spec, "give them instead of 'population > eta_squared'")
  spec <- bfancova_spec(prior_width = 1)
  expect_spec_problem(spec, "remove the other prior settings")
  # The covariates' prior belongs to the Bayes factor.
  spec <- bfancova_spec()
  spec$target_test <- list(effect = "main_effect_A", method = "ancova_f", alpha = 0.05, prior_scale_covariates = 0.354)
  expect_error(validate_quietly(spec))
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- bfancova_spec(n = 60)
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("generalTestBF(", run$script, fixed = TRUE)))
})
