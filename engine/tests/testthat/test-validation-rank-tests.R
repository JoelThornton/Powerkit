# Validation: rank tests (the Wilcoxon signed-rank test for one sample and
# for pairs, the Mann-Whitney test for two groups, the Kruskal-Wallis test
# for three or more groups).
# Backend: Spower simulation (p_wilcox.test(), p_kruskal.test()), with the
# scores drawn from the chosen shape and the effect a shift of it.
# G*Power computes its Wilcoxon tests from the t-test, adjusted by an
# efficiency factor for a chosen parent distribution, so its figures are
# not expected to match exactly: the published comparisons below measure
# that known difference (docs/conventions.md, "Known differences", 5).
# Build guide section 6:
#   1. published-example agreement with G*Power 3.1 (values to transcribe)
#   2. direct-call agreement with Spower (simulation)
#   3. Type I error (simulation)
#   4. the size of the difference from the t-test with normal scores
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `n` is the total number of participants (pairs for a paired test).
rank_validation_spec <- function(template, population, seed, n = NULL,
                                 target_power = NULL, alpha = 0.05,
                                 alternative = "two_sided", options = list()) {
  v <- validation_variable
  variables <- switch(
    template,
    one_sample_t = list(Y = v("continuous", "Score")),
    paired_t = list(X = v("within_factor", "Time", levels = list("Before", "After")), Y = v("continuous", "Score")),
    independent_t = list(X = v("binary", "Group", levels = list("Control", "Treatment")), Y = v("continuous", "Score")),
    oneway_between = list(A = v("between_factor", "Group", levels = as.list(paste("Group", seq_along(population$means)))),
                          Y = v("continuous", "Score"))
  )
  method <- switch(template, independent_t = "mann_whitney", oneway_between = "kruskal_wallis", "wilcoxon_signed_rank")
  effect <- switch(template, one_sample_t = "mean", oneway_between = "main_effect_A", "mean_difference")
  target_test <- list(effect = effect, method = method, alpha = alpha)
  if (template != "oneway_between") target_test$alternative <- alternative
  validation_spec(
    design = if (template == "oneway_between") "factorial_anova" else "basic_test",
    template = template,
    variables = variables,
    population = c(list(metric = "standardised"), population),
    target_test = target_test,
    seed = seed,
    n = n,
    target_power = target_power,
    options = options
  )
}

# 1. Published examples (G*Power 3.1) ------------------------------------------
#
# To transcribe from G*Power 3.1 (t tests family), with "Parent
# distribution: Normal": the a priori output's total sample size and actual
# power. A difference here is the known difference, not a failure of the
# translation; record its size in docs/conventions.md.

test_that("Mann-Whitney test, normal scores: compared with G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1, "Means: Wilcoxon-Mann-Whitney test (two groups)",
  #   A priori, Parent distribution Normal (maintainer to transcribe; no
  #   manual example is listed for this test in docs/coverage.md).
  d <- TODO_PUBLISHED_VALUE # Input: Effect size d
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(d, alpha, tails, total_n, actual_power)

  spec <- rank_validation_spec(
    "independent_t", list(d = d, score_shape = "normal"), n = total_n, seed = 101,
    alpha = alpha, alternative = if (tails == 1) "greater" else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("Wilcoxon signed-rank test (pairs), normal scores: compared with G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1, "Means: Wilcoxon signed-rank test (matched
  #   pairs)", A priori, Parent distribution Normal (maintainer to
  #   transcribe; docs/coverage-roadmap.md lists the manual's Example 23.3
  #   as a candidate).
  dz <- TODO_PUBLISHED_VALUE # Input: Effect size dz
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(dz, alpha, tails, total_n, actual_power)

  spec <- rank_validation_spec(
    "paired_t", list(dz = dz, score_shape = "normal"), n = total_n, seed = 102,
    alpha = alpha, alternative = if (tails == 1) "greater" else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("Wilcoxon signed-rank test (one sample), normal scores: compared with G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1, "Means: Wilcoxon signed-rank test (one sample
  #   case)", A priori, Parent distribution Normal (maintainer to
  #   transcribe; docs/coverage-roadmap.md lists the manual's Examples 22.1
  #   and 22.3 as candidates).
  d <- TODO_PUBLISHED_VALUE # Input: Effect size d
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(d, alpha, tails, total_n, actual_power)

  spec <- rank_validation_spec(
    "one_sample_t", list(d = d, score_shape = "normal"), n = total_n, seed = 103,
    alpha = alpha, alternative = if (tails == 1) "greater" else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

# 2. Direct-call agreement with Spower -----------------------------------------
#
# The same functions with the arguments and score generators written out
# by hand (helper-direct-calls.R), in Spower's orientation.

test_that("one sample, heavy-tailed: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  spec <- rank_validation_spec("one_sample_t", list(d = 0.3, score_shape = "heavy_tailed"), n = 60, seed = 201)
  direct <- direct_spower_wilcox("one.sample", n = 60, d = 0.3, shape = "heavy_tailed",
                                 alpha = 0.05, nrep = validation_nrep(), seed = 201)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("pairs, normal: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  spec <- rank_validation_spec("paired_t", list(dz = 0.4), n = 50, seed = 202)
  direct <- direct_spower_wilcox("paired", n = 50, d = -0.4, alpha = 0.05,
                                 nrep = validation_nrep(), seed = 202)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("two groups, skewed, unequal sizes: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  spec <- rank_validation_spec(
    "independent_t", list(d = 0.5, score_shape = "skewed"), n = 150, seed = 203,
    options = list(allocation_ratio = 2)
  )
  direct <- direct_spower_wilcox("two.sample", n = 50, d = -0.5, shape = "skewed", n2_n1 = 2,
                                 alpha = 0.05, nrep = validation_nrep(), seed = 203)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("three groups, heavy-tailed: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  spec <- rank_validation_spec(
    "oneway_between", list(means = list(0, 0.3, 0.6), sd = 1, score_shape = "heavy_tailed"),
    n = 90, seed = 204
  )
  direct <- direct_spower_kruskal(n = 30, means = c(0, 0.3, 0.6), shape = "heavy_tailed",
                                  alpha = 0.05, nrep = validation_nrep(), seed = 204)
  expect_power_agrees(engine_power(spec), direct)
})

# 3. Type I error ---------------------------------------------------------------

test_that("Mann-Whitney test, skewed scores: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- rank_validation_spec("independent_t", list(d = 0, score_shape = "skewed"), n = 60, seed = 301)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("signed-rank test, heavy-tailed pairs, one-sided: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- rank_validation_spec(
    "paired_t", list(dz = 0, score_shape = "heavy_tailed"), n = 40, seed = 302,
    alternative = "greater"
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("Kruskal-Wallis test, skewed scores: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- rank_validation_spec(
    "oneway_between", list(means = list(0, 0, 0, 0), sd = 1, score_shape = "skewed"),
    n = 80, seed = 303
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

# 4. The difference from the t-test ---------------------------------------------
#
# Until now powerkit showed the t-test's figure for a planned rank test.
# With normal scores the rank test has slightly less power than the t-test,
# and with heavy-tailed scores more. These pin the direction and rough size
# of that difference (docs/conventions.md, "Known differences", 5).

test_that("Mann-Whitney test, normal scores: a little less power than the t-test", {
  skip_unless_full_validation()
  spec <- rank_validation_spec("independent_t", list(d = 0.5, score_shape = "normal"), n = 128, seed = 401)
  rank <- engine_power(spec)$power
  t_power <- pwr::pwr.t.test(n = 64, d = 0.5, sig.level = 0.05)$power
  expect_lt(rank, t_power)
  expect_gt(rank, t_power - 0.05)
})

test_that("Mann-Whitney test, heavy-tailed scores: more power than the t-test", {
  skip_unless_full_validation()
  spec <- rank_validation_spec("independent_t", list(d = 0.5, score_shape = "heavy_tailed"), n = 128, seed = 402)
  rank <- engine_power(spec)$power
  t_power <- pwr::pwr.t.test(n = 64, d = 0.5, sig.level = 0.05)$power
  expect_gt(rank, t_power)
})
