# Validation: the Bayes factor one-way ANOVA (BayesFactor's ANOVA Bayes
# factor, JASP's default r scale of 0.5 for fixed effects).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation: data sets drawn with the spec's group
#      means and SD, each one's Bayes factor computed by anovaBF() itself,
#      and the share passing the threshold compared with powerkit's exact
#      chance
#   3. the no-effect side, simulated the same way with equal means
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

anova_bf_validation_spec <- function(n, means, sd = 1, threshold = 10, scale = 0.5) {
  spec <- example_spec("anova_oneway_between")
  spec$population <- list(metric = "raw", means = as.list(means), sd = sd)
  spec$variables$A$levels <- as.list(paste0("g", seq_along(means)))
  spec$target_test <- list(effect = "main_effect_A", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  spec$options <- NULL
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the default Bayes factor one-way ANOVA (Rouder et al.'s
  #   Bayes factor, as BayesFactor and JASP compute it). Transcribe the
  #   group means and SD (or Cohen's f), the r scale, the threshold, the
  #   group size and the published chance of reaching the threshold.
  means <- TODO_PUBLISHED_VALUE
  sd <- TODO_PUBLISHED_VALUE
  scale <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(means, sd, scale, threshold, n, published_power)
  result <- engine_function("run_spec")(anova_bf_validation_spec(n, means, sd, threshold, scale))
  expect_equal(result$curve$power, published_power, tolerance = 0.005)
})

simulate_anova_bf <- function(nsim, n, means, sd, scale, seed) {
  set.seed(seed)
  k <- length(means)
  group <- factor(rep(seq_len(k), each = n / k))
  vapply(seq_len(nsim), function(i) {
    y <- stats::rnorm(n, rep(means, each = n / k), sd)
    BayesFactor::extractBF(BayesFactor::anovaBF(y ~ group, data = data.frame(y = y, group = group),
      rscaleFixed = scale, progress = FALSE))$bf
  }, numeric(1))
}

check_anova_bf_case <- function(n, means, sd = 1, scale = 0.5, threshold = 10, nsim = validation_nrep(), seed) {
  result <- engine_function("run_spec")(anova_bf_validation_spec(n, means, sd, threshold, scale))
  bf <- simulate_anova_bf(nsim, n, means, sd, scale, seed)
  expect_power_near(result$curve[1, ], mean(bf >= threshold), reference_nrep = nsim)
  null_bf <- simulate_anova_bf(nsim, n, rep(means[1], length(means)), sd, scale, seed + 1)
  for_null <- mean(1 / null_bf >= threshold)
  expect_lt(abs(result$bayes$evidence_for_null - for_null), 4 * sqrt(max(for_null * (1 - for_null), 1e-3) / nsim) + 2e-3)
  misleading <- mean(null_bf >= threshold)
  expect_lt(abs(result$bayes$misleading_evidence - misleading), 4 * sqrt(max(misleading, 1e-3) / nsim) + 2e-3)
}

test_that("three groups, JASP's default prior: agrees with anovaBF() on simulated data (analytic)", {
  skip_unless_full_validation()
  check_anova_bf_case(150, c(0, 0.3, 0.5), seed = 91)
})

test_that("four groups in raw units, a wider prior and threshold 3: agrees with anovaBF() on simulated data (analytic)", {
  skip_unless_full_validation()
  check_anova_bf_case(120, c(20, 22, 23, 25), sd = 6, scale = 0.707, threshold = 3, seed = 92)
})
