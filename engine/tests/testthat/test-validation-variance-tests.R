# Validation: variance tests (one group against a fixed variance; two
# independent groups).
# Backend: since 31 October 2026, the exact chi-square and F
# distributions the G*Power 3.1 manual gives (sections 26.5 and 15.5;
# backend-variance.R), as G*Power computes them. Spower's simulation
# (`p_var.test()`, which runs EnvStats::varTest() for one variance and
# stats::var.test() for two) stays available as an option, so section 2
# now compares the formula with an independent simulation.
# Build guide section 6:
#   1. published-example agreement with G*Power 3.1
#   2. agreement with a direct Spower simulation of the same test
#   3. Type I error
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
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

# 4. Levene's test and the Brown-Forsythe test (simulated) ----------------------
#
# Backend: Spower simulation of powerkit's experiment p_levene(), which calls
# car::leveneTest(). Checked against an independent simulation: the same
# scores drawn and tested by the statistic written out from its definition
# (a one-way ANOVA F test of the absolute deviations from each group's mean,
# for Levene's test, or median, for the Brown-Forsythe test), without car.

levene_validation_spec <- function(method, var1, var2, n, shape, ratio = 1, seed = 401) {
  spec <- example_spec("two_variances")
  spec$population$var1 <- var1
  spec$population$var2 <- var2
  spec$population$score_shape <- shape
  spec$target_test$method <- method
  spec$target_test$alternative <- "two_sided"
  spec$goal <- list(type = "power", n = n)
  spec$options <- c(list(nrep = validation_nrep(), seed = seed), if (ratio != 1) list(allocation_ratio = ratio))
  spec <- validate_spec(spec)
  skip_if_no_backend(spec)
  spec
}

levene_p_by_hand <- function(x, y, center) {
  middle <- if (center == "mean") mean else stats::median
  z <- c(abs(x - middle(x)), abs(y - middle(y)))
  group <- factor(rep(1:2, c(length(x), length(y))))
  stats::oneway.test(z ~ group, var.equal = TRUE)$p.value
}

levene_draw <- function(shape) {
  switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
}

levene_by_hand <- function(var1, var2, shape, center, n1, n2, nrep, seed) {
  draw <- levene_draw(shape)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    levene_p_by_hand(sqrt(var1) * draw(n1), sqrt(var2) * draw(n2), center) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Levene and Brown-Forsythe: powerkit agrees with the test written out (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("car")
  # The statistic written out gives car's p-values.
  for (seed in 1:3) {
    x <- with_seed(seed, stats::rt(25, 3))
    y <- with_seed(seed + 10, 2 * stats::rt(40, 3))
    group <- factor(rep(1:2, c(25, 40)))
    for (center in c("mean", "median")) {
      expect_equal(levene_p_by_hand(x, y, center),
        car::leveneTest(c(x, y), group, center = center)[["Pr(>F)"]][1], tolerance = 1e-8)
    }
  }
  cases <- list(
    list(method = "levene", var1 = 1.5, var2 = 1, shape = "normal", n = 200, ratio = 1),
    list(method = "brown_forsythe", var1 = 1, var2 = 2, shape = "heavy_tailed", n = 150, ratio = 2),
    list(method = "brown_forsythe", var1 = 2, var2 = 1, shape = "skewed", n = 120, ratio = 1)
  )
  for (case in cases) {
    spec <- levene_validation_spec(case$method, case$var1, case$var2, case$n, case$shape, case$ratio)
    n1 <- floor(case$n / (1 + case$ratio) + 0.5)
    center <- if (case$method == "levene") "mean" else "median"
    reference <- levene_by_hand(case$var1, case$var2, case$shape, center, n1, case$n - n1, 4000L, 402)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("Levene and Brown-Forsythe: Type I error is near alpha (simulation)", {
  skip_unless_full_validation()
  # Normal scores, unequal groups; and the Brown-Forsythe test with
  # skewed scores, which it was proposed for.
  expect_type1_near(engine_power(levene_validation_spec("levene", 1, 1, 120, "normal", ratio = 2, seed = 403)), alpha = 0.05)
  expect_type1_near(engine_power(levene_validation_spec("brown_forsythe", 1, 1, 120, "skewed", seed = 404)), alpha = 0.05)
})
