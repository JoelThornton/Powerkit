# Moderation with a yes/no outcome: logistic regression with X x W,
# simulated with Spower by powerkit's experiment p_logistic_interaction(),
# which fits glm(). Translation, direction, the check run, refusals and the
# exported script; accuracy is checked by
# test-validation-logistic-interaction.R.

lint_spec <- function(n = 400, nrep = 100, x_binary = FALSE, w_binary = FALSE, alternative = NULL) {
  spec <- example_spec("logistic_interaction")
  spec$target_test$alternative <- alternative
  if (x_binary) {
    spec$variables$X <- list(type = "binary", label = "Condition", levels = list("Control", "Training"))
    spec$population$x_prob <- 0.4
  }
  if (w_binary) {
    spec$variables$W <- list(type = "binary", label = "Gender", levels = list("Men", "Women"))
    spec$population$w_prob <- 0.6
  }
  if (x_binary || w_binary) spec$population$r_xw <- NULL
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("moderation of a yes/no outcome runs on Spower and passes its check run, for scores and yes/no groups", {
  for (case in list(lint_spec(), lint_spec(x_binary = TRUE), lint_spec(w_binary = TRUE), lint_spec(x_binary = TRUE, w_binary = TRUE))) {
    result <- run_quietly(case)
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_logistic_interaction", fixed = TRUE)
    expect_true(all(result$check_run$ok))
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_logistic_interaction(n = 300, base_prob = 0.25, or_x = 1.4, or_w = 1.1, or_xw = 1.25,
    x_binary = FALSE, w_binary = FALSE, x_prob = 0.5, w_prob = 0.5, r = -0.2), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(lint_spec(n = 300))$curve$power, direct$power)
})

test_that("the data have the groups and correlation asked for, and one-sided tests point the right way", {
  d <- with_seed(1, logistic_interaction_data(1000, 0.3, 1, 1, 1, TRUE, FALSE, 0.4, 0.5, 0))
  expect_equal(sum(d$x), 400)
  d <- with_seed(2, logistic_interaction_data(50000, 0.3, 1, 1, 1, FALSE, FALSE, 0.5, 0.5, 0.4))
  expect_equal(stats::cor(d$x, d$w), 0.4, tolerance = 0.03)
  one_sided <- run_quietly(lint_spec(n = 300, nrep = 200, alternative = "greater"))$curve$power
  two_sided <- run_quietly(lint_spec(n = 300, nrep = 200))$curve$power
  expect_gt(one_sided, two_sided)
  expect_spec_problem(lint_spec(alternative = "less"), "one-sided")
})

test_that("plain-English refusals for moderation of a yes/no outcome", {
  spec <- lint_spec()
  spec$population$x_prob <- 0.3
  expect_spec_problem(spec, "is a score")
  spec <- lint_spec(x_binary = TRUE)
  spec$population$r_xw <- 0.2
  expect_spec_problem(spec, "only used when both are scores")
  expect_equal(minimum_n(lint_spec()), 40)
})

test_that("the R script reproduces the run, and the simulated data have both predictors", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (spec in list(lint_spec(n = 200, alternative = "greater"), lint_spec(n = 200, x_binary = TRUE, w_binary = TRUE))) {
    out <- run_exported_script(spec, run_quietly(spec))
    expect_equal(out$reproduced, out$powerkit)
  }
  spec <- lint_spec(x_binary = TRUE)
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 300)
  expect_equal(nrow(data), 300)
  expect_setequal(unique(data[[3]]), c("Control", "Training"))
})
