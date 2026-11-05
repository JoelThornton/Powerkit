# Negative binomial regression of a count on one predictor, simulated with
# Spower by powerkit's experiment p_negative_binomial(), which fits MASS's
# glm.nb(). Translation, direction, check run, refusals and the exported
# script; accuracy is checked by test-validation-negative-binomial.R.

nb_spec <- function(n = 300, nrep = 100, dispersion = 0.5, binary = FALSE, r2 = 0, alternative = NULL) {
  spec <- example_spec("poisson_regression")
  spec$target_test$method <- "negative_binomial"
  spec$target_test$alternative <- alternative
  spec$population$dispersion <- dispersion
  spec$population$r2_other_predictors <- if (r2 > 0) r2
  if (binary) {
    spec$variables$X <- list(type = "binary", label = "Group", levels = list("Control", "Treatment"))
    spec$population$x_prob <- 0.4
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("negative binomial regression runs on Spower with MASS, and passes its check run", {
  for (binary in c(FALSE, TRUE)) {
    result <- run_quietly(nb_spec(binary = binary, r2 = 0.2))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_negative_binomial", fixed = TRUE)
    expect_true("MASS" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok), info = binary)
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_negative_binomial(n = 200, rate_ratio = 0.8, base_rate = 3, dispersion = 0.5, exposure = 1,
    binary = FALSE, x_prob = 0.5, r2_other = 0), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(nb_spec(n = 200))$curve$power, direct$power)
})

test_that("the data have the spec's rate ratio, dispersion and group sizes, and one-sided tests point the right way", {
  d <- with_seed(1, negative_binomial_data(1000, 2, 3, 0.5, 2, TRUE, 0.3, 0))
  expect_equal(sum(d$x), 300)
  big <- with_seed(2, negative_binomial_data(2e5, 2, 3, 0.5, 2, TRUE, 0.5, 0))
  first <- big$y[big$x == 0]
  expect_equal(mean(first), 6, tolerance = 0.01)
  expect_equal(stats::var(first), 6 + 0.5 * 36, tolerance = 0.02)
  expect_equal(mean(big$y[big$x == 1]) / mean(first), 2, tolerance = 0.01)
  # The rate ratio is 0.8, so "less" is the direction of the effect.
  one_sided <- run_quietly(nb_spec(n = 150, nrep = 200, alternative = "less"))$curve$power
  two_sided <- run_quietly(nb_spec(n = 150, nrep = 200))$curve$power
  expect_gt(one_sided, two_sided)
  spec <- nb_spec(alternative = "greater")
  expect_spec_problem(spec, "one-sided")
})

test_that("the dispersion belongs to negative binomial regression, which needs it", {
  spec <- nb_spec()
  spec$population$dispersion <- NULL
  expect_spec_problem(spec, "Negative binomial regression needs 'population > dispersion'")
  spec <- nb_spec()
  spec$target_test$method <- "wald_z"
  expect_spec_problem(spec, "'population > dispersion' is only used by the negative binomial models")
})

test_that("the R script reproduces the run, and the simulated data are negative binomial", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- nb_spec(n = 120, nrep = 100, binary = TRUE, r2 = 0.1, alternative = "less")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  expect_true(any(grepl("MASS::glm.nb(formula, data = data)", out$script, fixed = TRUE)))
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 200)
  expect_equal(nrow(data), 200)
})
