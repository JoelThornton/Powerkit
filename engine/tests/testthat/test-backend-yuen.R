# Yuen's trimmed-means tests (two groups, and paired measurements),
# simulated with Spower by powerkit's experiments p_yuen() and p_yuend(),
# which call WRS2's yuen() and yuend(). Translation, direction, check run,
# refusals and the exported script; accuracy is checked by
# test-validation-yuen.R.

yuen_spec <- function(n = 100, nrep = 100, sd_ratio = NULL, shape = "heavy_tailed", ratio = NULL,
                      alternative = NULL, trim = NULL) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "yuen"
  spec$target_test$alternative <- alternative
  spec$target_test$trim <- trim
  spec$population$score_shape <- shape
  spec$population$sd_ratio <- sd_ratio
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  if (!is.null(ratio)) spec$options$allocation_ratio <- ratio
  spec
}

yuend_spec <- function(n = 60, nrep = 100, r = 0.5, shape = "heavy_tailed", alternative = NULL, trim = NULL) {
  spec <- example_spec("paired_t")
  spec$target_test$method <- "yuen"
  spec$target_test$alternative <- alternative
  spec$target_test$trim <- trim
  spec$population$score_shape <- shape
  spec$population$r <- r
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("Yuen's tests run on Spower with WRS2, and pass their check runs", {
  for (spec in list(yuen_spec(sd_ratio = 1.5), yuend_spec())) {
    result <- run_quietly(spec)
    expect_equal(result$provenance$backend, "Spower")
    expect_equal(result$provenance$method, "simulation")
    expect_match(result$provenance$backend_function, "20% trimmed means", fixed = TRUE)
    expect_true("WRS2" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok))
  }
  expect_match(run_quietly(yuend_spec(trim = 0.1))$provenance$backend_function, "yuend(tr = 0.1)", fixed = TRUE)
})

test_that("on one core, they equal direct Spower calls of the experiments", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  # example_spec()'s d is 0.4 and d_z 0.35 (Spower evaluates the call in
  # its own frame, so the values are written in).
  set.seed(7)
  direct <- Spower::Spower(p_yuen(n = 30, n2_n1 = 2, d = 0.4, sd_ratio = 1, shape = "heavy_tailed", trim = 0.2),
    replications = 100, verbose = FALSE)
  expect_equal(run_quietly(yuen_spec(n = 90, ratio = 2))$curve$power, direct$power)
  set.seed(7)
  direct <- Spower::Spower(p_yuend(n = 60, dz = 0.35, r = 0.5, shape = "heavy_tailed", trim = 0.2),
    replications = 100, verbose = FALSE)
  expect_equal(run_quietly(yuend_spec())$curve$power, direct$power)
})

test_that("the paired measurements have the spec's d_z and correlation", {
  g <- with_seed(1, yuen_paired_scores(2e5, 0.4, 0.6, "normal"))
  differences <- g$second - g$first
  expect_equal(mean(differences) / stats::sd(differences), 0.4, tolerance = 0.02)
  expect_equal(stats::cor(g$first, g$second), 0.6, tolerance = 0.01)
  expect_equal(stats::sd(g$first), 1, tolerance = 0.01)
})

test_that("one-sided tests point the right way", {
  # yuen() reports |t| and diff = group 1 minus group 2; yuend()'s t is
  # first minus second. Second higher: "less", spower_alternative()'s
  # translation of "greater".
  set.seed(2)
  x <- stats::rnorm(50)
  y <- stats::rnorm(50, 1)
  data <- data.frame(y = c(x, y), group = factor(rep(1:2, each = 50)))
  expect_lt(yuen_p_value(WRS2::yuen(y ~ group, data = data), "less"), 0.01)
  expect_gt(yuen_p_value(WRS2::yuen(y ~ group, data = data), "greater"), 0.99)
  expect_lt(yuen_p_value(WRS2::yuend(x, y), "less"), 0.01)
  expect_gt(yuen_p_value(WRS2::yuend(x, y), "greater"), 0.99)
  expect_match(spower_inputs(validate_quietly(yuen_spec(alternative = "greater")))$description, "alternative = \"less\"", fixed = TRUE)
  for (make in list(yuen_spec, yuend_spec)) {
    greater <- run_quietly(make(nrep = 200, alternative = "greater"))$curve$power
    less <- run_quietly(make(nrep = 200, alternative = "less"))$curve$power
    expect_gt(greater, 0.3)
    expect_lt(less, 0.05)
  }
})

test_that("the trimming and the correlation are refused where they don't apply", {
  spec <- yuend_spec()
  spec$population$r <- NULL
  expect_spec_problem(spec, "Yuen's paired test needs the correlation between the two measurements")
  spec <- yuend_spec()
  spec$target_test$method <- "t_test"
  expect_spec_problem(spec, "'population > r' is only used by Yuen's paired test")
  spec <- yuen_spec(trim = 0.1)
  spec$target_test$method <- "mann_whitney"
  expect_spec_problem(spec, "'target_test > trim' is only used by Yuen's trimmed-means test")
  spec <- yuen_spec(trim = 0.5)
  expect_error(validate_quietly(spec))
  # A skewed shape is Yuen's alone on paired measurements: the signed-rank
  # test assumes symmetric differences.
  expect_no_error(validate_quietly(yuend_spec(shape = "skewed")))
  spec <- yuend_spec(shape = "skewed", r = NULL)
  spec$target_test$method <- "wilcoxon_signed_rank"
  expect_spec_problem(spec, "'skewed' is only available for Yuen's paired test")
  # Means and an SD in the measure's own units hold a correlation in
  # population > raw > r, which is not population > r.
  spec <- example_spec("paired_t")
  spec$population <- list(metric = "raw", raw = list(mean_1 = 10, mean_2 = 12, sd = 5, r = 0.5))
  expect_no_error(validate_quietly(spec))
})

test_that("the R script reproduces the run", {
  spec <- yuen_spec(n = 60, ratio = 2, sd_ratio = 1.5, alternative = "greater", trim = 0.1)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- yuend_spec(n = 40, alternative = "less")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})

test_that("the simulated data sets have the spec's effect, spread and correlation", {
  data <- suppressWarnings(simulated_data(yuend_spec(r = 0.7, shape = "normal"), 20000))
  expect_equal(stats::cor(data[[3]], data[[4]]), 0.7, tolerance = 0.02)
  differences <- data[[4]] - data[[3]]
  expect_equal(mean(differences) / stats::sd(differences), 0.35, tolerance = 0.05)
  data <- suppressWarnings(simulated_data(yuen_spec(sd_ratio = 2, shape = "normal"), 20000))
  scores <- split(data[[4]], factor(data[[3]], levels = unique(data[[3]])))
  expect_equal(stats::sd(scores[[2]]) / stats::sd(scores[[1]]), 2, tolerance = 0.03)
})
