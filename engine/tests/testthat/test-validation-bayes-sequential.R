# Validation: sequential Bayes factor designs (the Labs tool,
# bayes_sequential()). Method: Monte Carlo simulation of the Sequential
# Bayes Factor design with a maximum sample size, as Schonbrodt and
# Wagenmakers (2018) plan it; the Bayes factor is bfpwr's tbf01().
#   1. published examples (placeholders for the maintainer)
#   2. agreement with a simulation written separately: data drawn study by
#      study, stats::t.test() at every look, and the JZS Bayes factor
#      integrated here over the noncentral t likelihood (not bfpwr), so the
#      check relies neither on bfpwr nor on the engine's thresholds in t
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

sequential_of <- function(...) engine_function("bayes_sequential")(...)

# 1. Published examples ---------------------------------------------------------

test_that("the Sequential Bayes Factor design with a maximum sample size matches a published example (published)", {
  skip_unless_full_validation()
  # Source: Schonbrodt & Wagenmakers (2018), Psychonomic Bulletin & Review
  #   25, 128-142, section "Sequential Bayes factor with maximal n:
  #   SBF+maxN". Transcribe n_min, n_max, the two thresholds (BF10 for an
  #   effect, BF01 for none), the design prior's mean and SD, and the
  #   percentages of studies stopping at the H1 threshold, at the H0
  #   threshold and at n_max, under H1 and under H0, from the paper.
  n_min <- TODO_PUBLISHED_VALUE
  n_max <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  threshold_null <- TODO_PUBLISHED_VALUE
  prior_mean <- TODO_PUBLISHED_VALUE
  prior_sd <- TODO_PUBLISHED_VALUE
  published_h1 <- TODO_PUBLISHED_VALUE # c(at H1 threshold, at H0 threshold, at n_max), as proportions
  published_h0 <- TODO_PUBLISHED_VALUE
  skip_if_todo(n_min, n_max, threshold, threshold_null, prior_mean, prior_sd, published_h1, published_h0)
  # The paper's examples are directional, with a Cauchy prior of scale
  # sqrt(2) / 2 and a look after every participant in each group.
  plan <- sequential_of(n_min, n_max, 1, effect = prior_mean, effect_sd = prior_sd, threshold = threshold,
    threshold_null = threshold_null, alternative = "greater", nsim = 10000, seed = 2018)
  o <- plan$outcomes
  expect_equal(unlist(o[o$truth == "belief", c("for_effect", "for_null", "at_max")]), published_h1,
    tolerance = 0.015, ignore_attr = TRUE)
  expect_equal(unlist(o[o$truth == "null", c("for_effect", "for_null", "at_max")]), published_h0,
    tolerance = 0.015, ignore_attr = TRUE)
})

test_that("the open-ended Sequential Bayes Factor design matches a published example (published)", {
  skip_unless_full_validation()
  # Source: Schonbrodt & Wagenmakers (2018), section "Sequential Bayes
  #   factor (SBF) design", "Expected rates of misleading evidence" and
  #   "Expected sample size". Transcribe n_min, the threshold, the design
  #   prior, the share of studies stopping at the H1 threshold under H1 and
  #   at the H1 threshold under H0, and the median sample size at the stop
  #   under H1. The design has no maximum: n_max below is set high enough
  #   for almost every simulated study to stop at a threshold.
  n_min <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  prior_mean <- TODO_PUBLISHED_VALUE
  prior_sd <- TODO_PUBLISHED_VALUE
  published_true_positive <- TODO_PUBLISHED_VALUE
  published_false_positive <- TODO_PUBLISHED_VALUE
  published_median_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(n_min, threshold, prior_mean, prior_sd, published_true_positive, published_false_positive, published_median_n)
  plan <- sequential_of(n_min, 1500, 1, effect = prior_mean, effect_sd = prior_sd, threshold = threshold,
    alternative = "greater", nsim = 10000, seed = 2018)
  o <- plan$outcomes
  expect_equal(o$for_effect[o$truth == "belief"], published_true_positive, tolerance = 0.015)
  expect_equal(o$for_effect[o$truth == "null"], published_false_positive, tolerance = 0.015)
  expect_equal(o$n_median[o$truth == "belief"], published_median_n, tolerance = 3)
})

# 2. A simulation written separately --------------------------------------------

# The JZS Bayes factor BF10 from the t statistic, integrated here: the
# likelihood of t is a noncentral t with noncentrality delta * sqrt(n_eff),
# averaged over the Cauchy prior on delta (truncated to one side for a
# one-sided test) and divided by the central t density.
jzs_bf10 <- function(t, n, type, alternative, scale = 1 / sqrt(2)) {
  df <- if (type == "two.sample") 2 * n - 2 else n - 1
  n_eff <- if (type == "two.sample") n / 2 else n
  range <- switch(alternative, two.sided = c(-Inf, Inf), greater = c(0, Inf), less = c(-Inf, 0))
  weight <- if (alternative == "two.sided") 1 else 2
  integrand <- function(delta) {
    suppressWarnings(stats::dt(t, df, ncp = delta * sqrt(n_eff))) * weight * stats::dcauchy(delta, 0, scale)
  }
  stats::integrate(integrand, range[1], range[2], rel.tol = 1e-8)$value / stats::dt(t, df)
}

brute_force_sequential <- function(nsim, looks, type, alternative, effect, effect_sd, threshold, threshold_null) {
  outcome <- character(nsim)
  for (i in seq_len(nsim)) {
    d <- stats::rnorm(1, effect, effect_sd)
    n_max <- max(looks)
    x <- stats::rnorm(n_max, d)
    y <- stats::rnorm(n_max)
    outcome[i] <- "max"
    for (n in looks) {
      t <- if (type == "two.sample") {
        unname(stats::t.test(x[seq_len(n)], y[seq_len(n)], var.equal = TRUE)$statistic)
      } else {
        unname(stats::t.test(x[seq_len(n)])$statistic)
      }
      bf10 <- jzs_bf10(t, n, type, alternative)
      if (bf10 >= threshold) {
        outcome[i] <- "effect"
        break
      }
      if (1 / bf10 >= threshold_null) {
        outcome[i] <- "null"
        break
      }
    }
  }
  c(for_effect = mean(outcome == "effect"), for_null = mean(outcome == "null"), at_max = mean(outcome == "max"))
}

compare_sequential <- function(type, alternative, n_min, n_max, step, effect, effect_sd, threshold, threshold_null, seed) {
  plan <- sequential_of(n_min, n_max, step, type = type, effect = effect, effect_sd = effect_sd, threshold = threshold,
    threshold_null = threshold_null, alternative = alternative, nsim = 5000, seed = seed)
  looks <- plan$looks$n
  set.seed(seed + 1)
  for (truth in c("belief", "null")) {
    brute <- if (truth == "belief") {
      brute_force_sequential(800, looks, type, alternative, effect, effect_sd, threshold, threshold_null)
    } else {
      brute_force_sequential(800, looks, type, alternative, 0, 0, threshold, threshold_null)
    }
    engine <- unlist(plan$outcomes[plan$outcomes$truth == truth, c("for_effect", "for_null", "at_max")])
    for (k in names(brute)) {
      se <- sqrt(max(brute[[k]] * (1 - brute[[k]]), 0.01 * 0.99) * (1 / 800 + 1 / 5000))
      expect_lt(abs(engine[[k]] - brute[[k]]), 4 * se, label = paste(type, alternative, truth, k))
    }
  }
}

test_that("two groups, one-sided, asymmetric thresholds: agrees with a separate simulation", {
  skip_unless_full_validation()
  compare_sequential("two.sample", "greater", 40, 100, 5, 0.5, 0.1, 30, 6, seed = 41)
})

test_that("two groups, two-sided, a look every 10: agrees with a separate simulation", {
  skip_unless_full_validation()
  compare_sequential("two.sample", "two.sided", 20, 200, 10, 0.4, 0, 10, 10, seed = 42)
})

test_that("paired data, one-sided towards a negative effect: agrees with a separate simulation", {
  skip_unless_full_validation()
  compare_sequential("paired", "less", 10, 120, 5, -0.3, 0.1, 6, 6, seed = 43)
})
