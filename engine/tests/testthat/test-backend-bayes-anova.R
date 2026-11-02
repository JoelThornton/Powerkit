# The Bayes factor one-way ANOVA (BayesFactor's oneWayAOV.Fstat(), JASP's
# r scale of 0.5), by exact calculation from the noncentral F.

anova_bf_spec <- function(n = NULL, means = list(0, 0.3, 0.5), sd = 1, threshold = NULL, scale = NULL, power = 0.8) {
  spec <- example_spec("anova_oneway_between")
  spec$population <- list(metric = "raw", means = means, sd = sd)
  spec$variables$A$levels <- as.list(paste0("g", seq_along(means)))
  spec$target_test <- list(effect = "main_effect_A", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  spec$target_test <- Filter(Negate(is.null), spec$target_test)
  spec$goal <- if (is.null(n)) list(type = "sample_size", power = power) else list(type = "power", n = n)
  spec$options <- NULL
  spec
}

test_that("oneWayAOV.Fstat() gives anovaBF()'s Bayes factor, with JASP's r scale of 0.5 by default", {
  inputs <- bfanova_inputs(anova_bf_spec(90))
  expect_equal(inputs$prior_scale, 0.5)
  set.seed(4)
  data <- data.frame(g = factor(rep(1:3, each = 30)), y = stats::rnorm(90) + rep(c(0, 0.3, 0.5), each = 30))
  f_stat <- stats::anova(stats::lm(y ~ g, data))[["F value"]][1]
  bf <- BayesFactor::extractBF(BayesFactor::anovaBF(y ~ g, data = data, rscaleFixed = 0.5, progress = FALSE), logbf = TRUE)$bf
  expect_equal(bfanova_log_bf10(f_stat, 30, inputs), bf, tolerance = 1e-8)
})

test_that("power is the chance of an F beyond the one where BF10 reaches the threshold", {
  spec <- anova_bf_spec(150)
  inputs <- bfanova_inputs(spec)
  f_star <- bfanova_f_at(log(10), 50, inputs)
  expect_equal(exp(bfanova_log_bf10(f_star, 50, inputs)), 10, tolerance = 1e-6)
  result <- run_spec(spec)
  expect_equal(result$curve$power, stats::pf(f_star, 2, 147, ncp = inputs$f^2 * 150, lower.tail = FALSE))
  expect_true(all(result$check_run$ok))
  expect_equal(result$bayes$misleading_evidence, stats::pf(f_star, 2, 147, lower.tail = FALSE))
  expect_gt(result$bayes$evidence_for_null, 0)
  # A wider prior and a higher threshold both need more evidence here.
  expect_lt(run_spec(anova_bf_spec(150, threshold = 30))$curve$power, result$curve$power)
})

test_that("the sample size is in whole groups and the script reproduces it", {
  spec <- anova_bf_spec()
  result <- run_spec(spec)
  expect_equal(result$n_required$n %% 3, 0)
  expect_gte(bfanova_power(bfanova_inputs(spec), result$n_required$n), 0.8)
  expect_lt(bfanova_power(bfanova_inputs(spec), result$n_required$n - 3), 0.8)
})

test_that("the exported script reproduces the Bayes factor ANOVA", {
  skip_unless_scripts_can_run()
  spec <- anova_bf_spec(150)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "oneWayAOV.Fstat", fixed = TRUE)
})

test_that("the Bayes factor ANOVA is refused where it doesn't apply", {
  spec <- anova_bf_spec(90)
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "two_sided")
  spec <- anova_bf_spec(90)
  spec$target_test$alpha <- 0.05
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})
