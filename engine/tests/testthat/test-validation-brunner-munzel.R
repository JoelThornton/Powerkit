# Validation: the Brunner-Munzel test for two groups.
# Backend: Spower simulation of powerkit's experiment p_brunner_munzel(),
# which calls brunnermunzel's brunnermunzel.test().
#   1. agreement with an independent simulation: the same groups drawn and
#      tested by the Brunner-Munzel statistic written out from its
#      definition (Brunner and Munzel's rank-based estimate of
#      P(X < Y) + P(X = Y) / 2 and its variance, with the
#      Welch-Satterthwaite df), without the package
#   2. Type I error with unequal spreads and unequal groups, where the
#      Mann-Whitney test does not hold its level
#   3. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bm_validation_spec <- function(d, sd_ratio, shape, n, ratio = 1, method = "brunner_munzel") {
  validation_spec(
    design = "basic_test",
    template = "independent_t",
    variables = list(
      X = validation_variable("binary", "Group", levels = list("Control", "Treatment")),
      Y = validation_variable("continuous", "Score")
    ),
    population = c(list(metric = "standardised", d = d, score_shape = shape),
      if (method == "brunner_munzel") list(sd_ratio = sd_ratio)),
    target_test = list(effect = "mean_difference", method = method, alpha = 0.05),
    seed = 6201,
    n = n,
    options = if (ratio != 1) list(allocation_ratio = ratio) else list()
  )
}

# The Brunner-Munzel test written out (two-sided p-value): the overall
# ranks' group means, each group's variance of overall minus within-group
# ranks, the statistic n1 n2 (mean rank 2 - mean rank 1) / ((n1 + n2)
# sqrt(n1 S1^2 + n2 S2^2)) and Welch-Satterthwaite df. Checked against
# brunnermunzel.test() on fixed data below.
bm_p_by_hand <- function(x, y) {
  n1 <- length(x)
  n2 <- length(y)
  r <- rank(c(x, y))
  r1 <- r[seq_len(n1)]
  r2 <- r[n1 + seq_len(n2)]
  s1 <- sum((r1 - rank(x) - mean(r1) + (n1 + 1) / 2)^2) / (n1 - 1)
  s2 <- sum((r2 - rank(y) - mean(r2) + (n2 + 1) / 2)^2) / (n2 - 1)
  stat <- n1 * n2 * (mean(r2) - mean(r1)) / ((n1 + n2) * sqrt(n1 * s1 + n2 * s2))
  df <- (n1 * s1 + n2 * s2)^2 / ((n1 * s1)^2 / (n1 - 1) + (n2 * s2)^2 / (n2 - 1))
  2 * stats::pt(-abs(stat), df)
}

bm_by_hand <- function(d, sd_ratio, shape, n1, n2, nrep, seed) {
  draw <- switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
  sd1 <- sqrt(2 / (1 + sd_ratio^2))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    bm_p_by_hand(sd1 * draw(n1), d + sd_ratio * sd1 * draw(n2)) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Brunner-Munzel: powerkit agrees with the test written out (simulation)", {
  skip_unless_full_validation()
  # The statistic written out gives brunnermunzel.test()'s p-value.
  for (seed in 1:3) {
    x <- with_seed(seed, stats::rexp(25))
    y <- with_seed(seed + 10, 0.5 + 2 * stats::rexp(40))
    expect_equal(bm_p_by_hand(x, y), brunnermunzel::brunnermunzel.test(x, y)$p.value, tolerance = 1e-8)
  }
  cases <- list(
    list(d = 0.5, sd_ratio = 2, shape = "skewed", n = 120, ratio = 1),
    list(d = 0.4, sd_ratio = 0.5, shape = "heavy_tailed", n = 150, ratio = 2)
  )
  for (case in cases) {
    spec <- bm_validation_spec(case$d, case$sd_ratio, case$shape, case$n, case$ratio)
    n1 <- round(case$n / (1 + case$ratio))
    reference <- bm_by_hand(case$d, case$sd_ratio, case$shape, n1, case$n - n1, 4000L, 61)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("Brunner-Munzel: Type I error with unequal spreads and group sizes (simulation)", {
  skip_unless_full_validation()
  # No difference in location, group 2 three times as spread and twice as
  # large. The Brunner-Munzel test is built for this case.
  spec <- bm_validation_spec(0, 3, "normal", 150, ratio = 2)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("Brunner-Munzel: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # the Brunner-Munzel test; source, section, page).
  d <- TODO_PUBLISHED_VALUE
  sd_ratio <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(d, sd_ratio, n, published_power)
  spec <- bm_validation_spec(d, sd_ratio, "normal", n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
