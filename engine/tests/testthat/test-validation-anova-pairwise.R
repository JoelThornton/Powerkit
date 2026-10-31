# Validation: pairwise comparisons after a one-way ANOVA, adjusted for their
# number. Backend: Superpower's ANOVA_power(p_adjust =), simulated (its
# exact route doesn't adjust p-values). Build guide section 6:
#   1. published-example agreement (a worked example of power for
#      Bonferroni- or Holm-adjusted pairwise comparisons, to choose)
#   2. agreement with an exact calculation: with Bonferroni's adjustment
#      across m comparisons, a pair's power is the two-group t-test's power
#      at alpha / m (stats::power.t.test(), independent of Superpower); and
#      without adjustment, Superpower's own exact pairwise power
#   3. the error rate for a pair with equal means stays at or below alpha
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

pairwise_validation_spec <- function(means, sd, comparison, p_adjust, seed, n, alpha = 0.05) {
  v <- validation_variable
  validation_spec(
    design = "factorial_anova",
    template = "oneway_between",
    variables = list(A = v("between_factor", "Group", levels = paste("Group", seq_along(means))), Y = v("continuous", "Score")),
    population = list(metric = "raw", means = as.list(means), sd = sd),
    target_test = list(effect = "pairwise", method = "t_test", comparison = paste("Group", comparison),
      p_adjust = p_adjust, alpha = alpha),
    seed = seed,
    n = n
  )
}

# 1. Published example -----------------------------------------------------------

test_that("pairwise comparisons: match a published example (published)", {
  skip_unless_full_validation()
  # Source to choose and transcribe: a published power analysis for
  #   pairwise comparisons after a one-way ANOVA with a Holm or Bonferroni
  #   adjustment (for example from Superpower's documentation or book),
  #   giving the means, the SD, the group size, the adjustment, alpha and
  #   the power of one named comparison.
  means <- TODO_PUBLISHED_VALUE # the group means, in order
  sd <- TODO_PUBLISHED_VALUE # the SD in every group
  comparison <- TODO_PUBLISHED_VALUE # the two groups compared, by position (e.g. c(1, 3))
  p_adjust <- TODO_PUBLISHED_VALUE # "holm" or "bonferroni"
  total_n <- TODO_PUBLISHED_VALUE # total sample size
  alpha <- TODO_PUBLISHED_VALUE # alpha
  published_power <- TODO_PUBLISHED_VALUE # the comparison's power (0 to 1)
  skip_if_todo(means, sd, comparison, p_adjust, total_n, alpha, published_power)

  spec <- pairwise_validation_spec(means, sd, comparison, p_adjust, seed = 501, n = total_n, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with exact calculations --------------------------------------------

test_that("pairwise comparisons, Bonferroni: power is the two-group t-test's at alpha / m", {
  skip_unless_full_validation()
  # Three groups, so m = 3 comparisons; groups of 30, means 10, 11, 13, SD 6.
  exact <- stats::power.t.test(n = 30, delta = 3, sd = 6, sig.level = 0.05 / 3)$power
  spec <- pairwise_validation_spec(c(10, 11, 13), 6, c(1, 3), "bonferroni", seed = 502, n = 90)
  expect_power_near(engine_power(spec), exact)
})

test_that("pairwise comparisons, no adjustment: power is Superpower's exact pairwise power", {
  skip_unless_full_validation()
  design <- Superpower::ANOVA_design("3b", n = 30, mu = c(10, 11, 13), sd = 6, plot = FALSE)
  exact <- Superpower::ANOVA_exact(design, verbose = FALSE)$pc_results["p_a_a2_a_a3", "power"] / 100
  spec <- pairwise_validation_spec(c(10, 11, 13), 6, c(2, 3), "none", seed = 503, n = 90)
  expect_power_near(engine_power(spec), exact)
})

# 3. Error rate for a pair with no difference --------------------------------------

test_that("pairwise comparisons, Holm: a pair with equal means is rejected no more often than alpha", {
  skip_unless_full_validation()
  spec <- pairwise_validation_spec(c(10, 13, 10), 6, c(1, 3), "holm", seed = 504, n = 90)
  estimate <- engine_power(spec)
  expect_lte(estimate$power, 0.05 + 3 * estimate$mcse)
})
