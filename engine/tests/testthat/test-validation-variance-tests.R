# Validation: variance tests (one group against a fixed variance; two
# independent groups).
# Backend: Spower simulation. `p_var.test()` runs EnvStats::varTest() for
# one variance (the chi-square test of section 26) and stats::var.test()
# for two (the F test of section 15), which are the tests G*Power computes
# by formula. No package powerkit builds on has a formula for either, so
# powerkit simulates them (docs/conventions.md) and the published
# comparisons allow for Monte Carlo error.
# Build guide section 6:
#   1. published-example agreement with G*Power 3.1
#   2. direct-call agreement with Spower (simulation)
#   3. Type I error (simulation)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `population` holds the variance fields (var and var0, or var1 and var2).
# `n` is the total number of participants.
variance_spec <- function(template, population, seed, n = NULL,
                          target_power = NULL, alpha = 0.05,
                          alternative = "two_sided", options = list()) {
  v <- validation_variable
  variables <- if (template == "one_variance") {
    list(Y = v("continuous", "Score"))
  } else {
    list(G = v("binary", "Group"), Y = v("continuous", "Score"))
  }
  validation_spec(
    design = "basic_test",
    template = template,
    variables = variables,
    population = c(list(metric = "variance"), population),
    target_test = list(
      effect = "variance_ratio",
      method = if (template == "one_variance") "chi_square_var" else "f_var",
      alpha = alpha, alternative = alternative
    ),
    seed = seed,
    n = n,
    target_power = target_power,
    options = options
  )
}

# 1. Published examples (G*Power 3.1) ------------------------------------------

test_that("one variance, one-sided: matches G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 26.3
  #   ("chi-square test: Variance - difference from constant (one sample
  #   case)"), p. 64: the a priori analysis, whose output gives "Total
  #   sample size" and "Actual power". The effect size is the ratio
  #   var1/var0; the example's effect size drawer uses variance V0 = 1.5
  #   (the value tested against) and variance V1 = 1 (the variance assumed
  #   in H1), so `var` is V1 and `var0` is V0.
  var <- 1 # Effect size drawer: variance V1
  var0 <- 1.5 # Effect size drawer: variance V0
  alpha <- 0.05
  tails <- 1 # Tail(s): 1 or 2
  total_n <- 81 # Output: Total sample size
  actual_power <- 0.803686 # Output: Actual power
  skip_if_todo(var, var0, alpha, tails, total_n, actual_power)

  spec <- variance_spec(
    "one_variance", list(var = var, var0 = var0), n = total_n, seed = 101,
    alpha = alpha,
    alternative = if (tails == 1) (if (var < var0) "less" else "greater") else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

test_that("one variance, two-sided: matches the required N in the G*Power 3.1 manual (published)", {
  skip_unless_full_validation()
  # Source: as the test above (manual section 26.3, p. 64), the closing
  #   paragraph: the same example with "Tail(s) = Two" requires N = 103.
  #   Only the sample size is given there, so this is a required-N test.
  var <- 1 # Effect size drawer: variance V1
  var0 <- 1.5 # Effect size drawer: variance V0
  alpha <- 0.05
  target_power <- 0.80 # Input: Power (1-beta err prob)
  published_n <- 103 # Text: total sample size for two tails
  skip_if_todo(var, var0, alpha, target_power, published_n)

  spec <- variance_spec(
    "one_variance", list(var = var, var0 = var0), target_power = target_power,
    seed = 102, alpha = alpha
  )
  expect_n_near(engine_n_required(spec), published_n)
})

# The manual's section 15.3 also reports the same example with
# "Allocation ratio N2/N1 = 2" (N = 443: 148 and 295). powerkit refuses an
# allocation ratio for this test, because Spower's generator can't draw
# unequal groups (docs/upstream-questions.md), so there is no test for it
# here; `test-backend-spower.R` checks that the refusal fires.

test_that("two variances: matches G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 15.3
  #   ("F test: Inequality of two Variances"), p. 39: the a priori
  #   analysis with "Allocation ratio N2/N1: 1", whose output gives
  #   "Sample size group 1", "Sample size group 2" and "Actual power".
  # The example gives the effect size as the ratio var1/var0 rather than
  #   two variances. Power depends on the ratio alone (the F statistic is
  #   scale-free), so the spec uses var1 = ratio and var2 = 1: group 1
  #   carries the numerator variance var1, as in G*Power.
  variance_ratio <- 1.5 # Input: Ratio var1/var0
  alpha <- 0.05
  tails <- 2 # Tail(s): 1 or 2
  total_n <- 386 # Output: group 1 + group 2 sample sizes
  actual_power <- 0.800105 # Output: Actual power
  skip_if_todo(variance_ratio, alpha, tails, total_n, actual_power)

  spec <- variance_spec(
    "two_variances", list(var1 = variance_ratio, var2 = 1), n = total_n,
    seed = 103, alpha = alpha,
    alternative = if (tails == 1) (if (variance_ratio > 1) "greater" else "less") else "two_sided"
  )
  expect_power_near(engine_power(spec), actual_power)
})

# 2. Direct-call agreement with Spower -----------------------------------------
#
# These check powerkit's translation of the spec: the same function with
# the arguments written out by hand. Which test `p_var.test()` then runs
# (it chooses between EnvStats::varTest(), stats::var.test() and the
# Levene, Bartlett and Fligner tests) is not pinned here, since both sides
# would change together; the published comparisons above are what pin it.

test_that("one variance: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  skip_if_not_installed("EnvStats")
  spec <- variance_spec(
    "one_variance", list(var = 1, var0 = 1.5), n = 81, seed = 201,
    alternative = "less"
  )
  direct <- direct_spower_var_test(
    n = 81, vars = 1, sigma2 = 1.5, alternative = "less",
    alpha = 0.05, nrep = validation_nrep(), seed = 201
  )
  expect_power_agrees(engine_power(spec), direct)
})

test_that("two variances: powerkit matches a direct Spower call", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- variance_spec(
    "two_variances", list(var1 = 1.5, var2 = 1), n = 386, seed = 202
  )
  direct <- direct_spower_var_test(
    n = 193, vars = c(1.5, 1), alpha = 0.05,
    nrep = validation_nrep(), seed = 202
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 3. Type I error ---------------------------------------------------------------

test_that("one variance: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- variance_spec(
    "one_variance", list(var = 1, var0 = 1), n = 60, seed = 301
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("one variance, one-sided: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- variance_spec(
    "one_variance", list(var = 1, var0 = 1), n = 60, seed = 302,
    alternative = "less"
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("two variances: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- variance_spec(
    "two_variances", list(var1 = 1, var2 = 1), n = 120, seed = 303
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
