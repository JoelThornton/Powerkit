# Validation: Friedman's test (one-way repeated measures, rank-based) and
# the rank correlations on scores of a chosen shape. Backend: Spower
# simulation of powerkit's p_friedman() experiment and of p_r() with
# powerkit's shaped_pair_scores() generator. No package powerkit builds on
# has a formula for either. Build guide section 6:
#   1. published-example agreement (to choose: a published power analysis
#      for Friedman's test)
#   2. agreement with a simulation written out separately: for normal
#      deviations powerkit's scores are multivariate normal with every
#      correlation r, drawn here with MASS::mvrnorm() and tested with
#      stats::friedman.test(); and Spearman's rho on skewed scores drawn and
#      tested by hand with stats::cor.test()
#   3. Type I error for every shape
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

friedman_validation_spec <- function(means, r, shape, seed, n, alpha = 0.05) {
  v <- validation_variable
  validation_spec(
    design = "factorial_anova",
    template = "oneway_within",
    variables = list(A = v("within_factor", "Condition", levels = paste("Condition", seq_along(means))), Y = v("continuous", "Score")),
    population = list(metric = "standardised", means = as.list(means), sd = 1, r = r, score_shape = shape),
    target_test = list(effect = "main_effect_A", method = "friedman", alpha = alpha),
    seed = seed,
    n = n
  )
}

shaped_correlation_validation_spec <- function(r, shape, method, seed, n, alpha = 0.05) {
  v <- validation_variable
  validation_spec(
    design = "basic_test",
    template = "correlation",
    variables = list(X = v("continuous", "First score"), Y = v("continuous", "Second score")),
    population = list(metric = "correlation", r = r, score_shape = shape),
    target_test = list(effect = "correlation", method = method, alpha = alpha),
    seed = seed,
    n = n
  )
}

# 1. Published example -----------------------------------------------------------

test_that("Friedman's test: matches a published example (published)", {
  skip_unless_full_validation()
  # Source to choose and transcribe: a published power analysis for
  #   Friedman's test giving the condition means in SD units, the
  #   correlation between conditions, the shape of the scores, the number of
  #   participants, alpha and the power.
  means <- TODO_PUBLISHED_VALUE # condition means in SD units
  r <- TODO_PUBLISHED_VALUE # correlation between conditions
  shape <- TODO_PUBLISHED_VALUE # "normal", "skewed" or "heavy_tailed"
  n <- TODO_PUBLISHED_VALUE # number of participants
  alpha <- TODO_PUBLISHED_VALUE # alpha
  published_power <- TODO_PUBLISHED_VALUE # power (0 to 1)
  skip_if_todo(means, r, shape, n, alpha, published_power)

  spec <- friedman_validation_spec(means, r, shape, seed = 601, n = n, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with simulations written out separately ------------------------------

test_that("Friedman's test, normal scores: powerkit matches a simulation written out separately", {
  skip_unless_full_validation()
  skip_if_not_installed("MASS")
  means <- c(0, 0.3, 0.5)
  sigma <- matrix(0.6, 3, 3) + diag(0.4, 3)
  friedman_by_hand <- function(n) stats::friedman.test(MASS::mvrnorm(n, means, sigma))$p.value
  direct <- run_spower(quote(friedman_by_hand(n = 30)), 0.05, validation_nrep(), 602,
    data = list(friedman_by_hand = friedman_by_hand))
  spec <- friedman_validation_spec(means, 0.6, "normal", seed = 603, n = 30)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("Spearman's rho, skewed scores: powerkit matches a simulation written out separately", {
  skip_unless_full_validation()
  spearman_by_hand <- function(n) {
    x <- (stats::rchisq(n, df = 10) - 10) / sqrt(20)
    e <- (stats::rchisq(n, df = 10) - 10) / sqrt(20)
    stats::cor.test(x, 0.3 * x + sqrt(1 - 0.09) * e, method = "spearman", exact = FALSE)$p.value
  }
  direct <- run_spower(quote(spearman_by_hand(n = 80)), 0.05, validation_nrep(), 604,
    data = list(spearman_by_hand = spearman_by_hand))
  spec <- shaped_correlation_validation_spec(0.3, "skewed", "spearman", seed = 605, n = 80)
  expect_power_agrees(engine_power(spec), direct)
})

# 3. Type I error ------------------------------------------------------------------

test_that("Friedman's test: Type I error is near alpha for every shape", {
  skip_unless_full_validation()
  for (shape in c("normal", "skewed", "heavy_tailed")) {
    spec <- friedman_validation_spec(c(0, 0, 0), 0.6, shape, seed = 606, n = 30)
    expect_type1_near(engine_power(spec), alpha = 0.05)
  }
})

test_that("Spearman's rho and Kendall's tau on shaped scores: Type I error is near alpha", {
  skip_unless_full_validation()
  for (method in c("spearman", "kendall")) {
    spec <- shaped_correlation_validation_spec(0, "heavy_tailed", method, seed = 607, n = 60)
    expect_type1_near(engine_power(spec), alpha = 0.05)
  }
})
