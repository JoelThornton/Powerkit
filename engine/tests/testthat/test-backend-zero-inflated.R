# Zero-inflated Poisson and negative binomial regression of a count on one
# predictor, simulated with Spower by powerkit's experiment
# p_zero_inflated(), which fits pscl's zeroinfl(). Translation, direction,
# check run, refusals and the exported script; accuracy is checked by
# test-validation-zero-inflated.R.

zi_spec <- function(n = 300, nrep = 100, method = "zero_inflated_poisson", zero_prob = 0.3, zero_odds_ratio = NULL,
                    dispersion = NULL, effect = "rate_ratio", binary = FALSE, r2 = 0, alternative = NULL) {
  spec <- example_spec("poisson_regression")
  spec$target_test$method <- method
  spec$target_test$effect <- effect
  spec$target_test$alternative <- alternative
  spec$population$zero_prob <- zero_prob
  spec$population$zero_odds_ratio <- zero_odds_ratio
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

test_that("zero-inflated regression runs on Spower with pscl, and passes its check run", {
  for (binary in c(FALSE, TRUE)) {
    result <- run_quietly(zi_spec(method = "zero_inflated_negative_binomial", dispersion = 0.5, zero_odds_ratio = 1.4, binary = binary, r2 = 0.2))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_zero_inflated", fixed = TRUE)
    expect_true("pscl" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok), info = binary)
    expect_equal(nrow(result$check_run), 6)
  }
  poisson <- run_quietly(zi_spec(effect = "rate_and_zero", zero_odds_ratio = 1.5))
  expect_match(poisson$provenance$backend_function, "dist = \"poisson\"", fixed = TRUE)
  expect_match(poisson$provenance$backend_function, "both parts", fixed = TRUE)
  expect_equal(nrow(poisson$check_run), 4)
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_zero_inflated(n = 200, rate_ratio = 0.8, base_rate = 3, zero_prob = 0.3, zero_odds_ratio = 1,
    dispersion = 0, exposure = 1, binary = FALSE, x_prob = 0.5, r2_other = 0, part = "rate_ratio"), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(zi_spec(n = 200))$curve$power, direct$power)
})

test_that("the data have the spec's extra zeros, rate ratio and group sizes, and one-sided tests point the right way", {
  d <- with_seed(1, zero_inflated_data(1000, 2, 3, 0.2, 1, 0, 1, TRUE, 0.3, 0))
  expect_equal(sum(d$x), 300)
  big <- with_seed(2, zero_inflated_data(2e5, 1.5, 4, 0.25, 2, 0, 1, TRUE, 0.5, 0))
  first <- big$y[big$x == 0]
  # Zeros in the first group: the extra zeros plus the Poisson zeros of
  # everyone else.
  expect_equal(mean(first == 0), 0.25 + 0.75 * exp(-4), tolerance = 0.01)
  expect_equal(mean(first), 0.75 * 4, tolerance = 0.01)
  second_extra <- stats::plogis(stats::qlogis(0.25) + log(2))
  expect_equal(mean(big$y[big$x == 1]), (1 - second_extra) * 6, tolerance = 0.01)
  # The rate ratio is 0.8, so "less" is the direction of the count effect;
  # the zero odds ratio is 1.5, so "greater" is the direction of the zero
  # effect.
  one_sided <- run_quietly(zi_spec(n = 150, nrep = 200, alternative = "less"))$curve$power
  two_sided <- run_quietly(zi_spec(n = 150, nrep = 200))$curve$power
  expect_gt(one_sided, two_sided)
  expect_spec_problem(zi_spec(alternative = "greater"), "one-sided")
  expect_spec_problem(zi_spec(effect = "zero_odds_ratio", zero_odds_ratio = 1.5, alternative = "less"), "one-sided")
  expect_valid_spec(zi_spec(nrep = 1000, effect = "zero_odds_ratio", zero_odds_ratio = 1.5, alternative = "greater"))
})

test_that("the zero-inflated inputs belong to the zero-inflated models, which need them", {
  expect_spec_problem(zi_spec(zero_prob = NULL), "need 'population > zero_prob'")
  expect_spec_problem(zi_spec(method = "zero_inflated_negative_binomial"), "Zero-inflated negative binomial regression needs 'population > dispersion'")
  expect_spec_problem(zi_spec(dispersion = 0.5), "only used by the negative binomial models")
  expect_spec_problem(zi_spec(method = "wald_z"), "'population > zero_prob' is only used by the zero-inflated models")
  expect_spec_problem(zi_spec(method = "wald_z", zero_prob = NULL, effect = "zero_odds_ratio"), "Only the zero-inflated models have a zero part")
  expect_spec_problem(zi_spec(effect = "rate_and_zero", alternative = "less"), "has no direction")
  # No effect on the part tested is refused for a sample size.
  spec <- zi_spec(effect = "zero_odds_ratio")
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(spec, "The effect you want to detect is zero")
  expect_equal(minimum_n(zi_spec()), 30)
})

test_that("a data set with no zeros, or only zeros, counts as not significant", {
  expect_equal(with_seed(1, p_zero_inflated(30, 1, 50, 0.001, 1, 0, 1, FALSE, 0.5, 0)), 1)
  expect_equal(with_seed(1, p_zero_inflated(30, 1, 0.0001, 0.5, 1, 0, 1, FALSE, 0.5, 0)), 1)
})

test_that("the R script reproduces the run, and the simulated data have extra zeros", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- zi_spec(n = 150, nrep = 100, binary = TRUE, r2 = 0.1, zero_odds_ratio = 1.5, effect = "zero_odds_ratio", alternative = "greater")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  expect_true(any(grepl("pscl::zeroinfl(", out$script, fixed = TRUE)))
  spec <- zi_spec(n = 150, nrep = 100, method = "zero_inflated_negative_binomial", dispersion = 0.5, effect = "rate_and_zero")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 2000)
  expect_gt(mean(data[[ncol(data)]] == 0), 0.3)
})
